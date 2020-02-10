# -*- mode:makefile-gmake; -*-
##########################################################################
##########################################################################

TASS?=64tass
PYTHON?=python
BEEBASM?=beebasm

##########################################################################
##########################################################################

TASSCMD:=$(TASS) --m65c02 --cbm-prg -Wall -C --line-numbers

##########################################################################
##########################################################################

BEEB_BIN:=submodules/beeb/bin
SHELLCMD:=$(PYTHON) submodules/shellcmd.py/shellcmd.py
BUILD:=build
BEEB:=./beeb/1

##########################################################################
##########################################################################

.PHONY:build
build:
	$(SHELLCMD) mkdir "$(BUILD)"
	$(SHELLCMD) mkdir "$(BEEB)"

# Heath Robinson build system, as I prefer 64tass to BeebAsm!
#
# Arrange for an incbin'able version of the vgc player, and a
# 64tass-friendly include file with the addresses of its useful
# symbols.

	$(BEEBASM) -v -do $(BUILD)/vgcplayer.ssd -i ./vgcplayer_beebasm_wrapper.s65 > $(BUILD)/vgcplayer_output.txt
	cat $(BUILD)/vgcplayer_output.txt | grep -E "^output::" | sed -e "s/^output:://g" | tr '&' '$$' > $(BUILD)/vgcplayer_inc.s65
	$(PYTHON) $(BEEB_BIN)/ssd_extract.py -o $(BUILD)/ $(BUILD)/vgcplayer.ssd
	$(SHELLCMD) copy-file $(BUILD)/vgcplayer/0/\$$.vgmplay $(BEEB)/
	$(SHELLCMD) copy-file $(BUILD)/vgcplayer/0/\$$.vgmplay.inf $(BEEB)/
	$(MAKE) _assemble SRC=vgcplayer_test BBC=vgctest
	$(PYTHON) $(BEEB_BIN)/ssd_create.py -o $(BUILD)/vgm_player_test.ssd $(BEEB)/@.vgctest $(BEEB)/$$.vgmplay --build "*LOAD VGMPLAY" --build "*RUN @.VGCTEST"

##########################################################################
##########################################################################

.PHONY:_assemble
_assemble:
	$(TASSCMD) "$(SRC).s65" "-L$(BUILD)/$(SRC).lst" "-l$(BUILD)/$(SRC).sym" "-o$(BUILD)/$(SRC).prg"
	$(PYTHON) $(BEEB_BIN)/prg2bbc.py "$(BUILD)/$(SRC).prg" "$(BEEB)/@.$(BBC)"

##########################################################################
##########################################################################

.PHONY:test_b2
test_b2:
	curl -G 'http://localhost:48075/reset/b2' --data-urlencode "config=Master 128 (MOS 3.20)"
	curl -H 'Content-Type:application/binary' --upload-file '$(BUILD)/vgm_player_test.ssd' 'http://localhost:48075/run/b2?name=vgm_player_test.ssd'

##########################################################################
##########################################################################

.PHONY:tom_emacs
tom_emacs:
	$(MAKE) build
	$(MAKE) test_b2
