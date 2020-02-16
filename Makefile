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
	$(MAKE) $(BUILD)/U_LOADER.vgc
	$(MAKE) $(BUILD)/U_LOADER.streams.vgc
	$(MAKE) $(BUILD)/SYNERG2.streams.vgc
	$(MAKE) _assemble SRC=vgcplayer_test BBC=vgc
	$(MAKE) _assemble SRC=synerg2_bank4 BBC=syn2_4
	$(MAKE) _assemble SRC=synerg2_bank5 BBC=syn2_5
	$(MAKE) _assemble SRC=synerg2_bank6 BBC=syn2_6
	$(MAKE) _assemble SRC=synerg2_bank7 BBC=syn2_7
	$(MAKE) _assemble SRC=synerg2_main BBC=syn2_m
	$(MAKE) _assemble SRC=vgcplayer_streams_test BBC=vgcstr

	$(PYTHON) $(BEEB_BIN)/ssd_create.py -o $(BUILD)/vgm_player_test.ssd $(BEEB)/@.* $(BEEB)/$$.vgmplay --build "*LOAD VGMPLAY" --build "*RUN @.VGC"

	$(PYTHON) $(BEEB_BIN)/ssd_create.py -o $(BUILD)/vgm_streams_player_test.ssd $(BEEB)/@.* $(BEEB)/$$.vgmplay --build "*SRLOAD @.syn2_4 8000 4 Q" --build "*SRLOAD @.syn2_5 8000 5 Q" --build "*SRLOAD @.syn2_6 8000 6 Q" --build "*SRLOAD @.syn2_7 8000 7 Q" --build "*LOAD @.syn2_m" --build "*LOAD VGMPLAY" --build "*RUN @.VGCSTR"

$(BUILD)/%.vgc : ./vgms/%.vgm
	$(PYTHON) submodules/vgm-packer/vgmpacker.py -o $@ $<

$(BUILD)/%.streams.vgc $(BUILD)/%.streams.0.vgc $(BUILD)/%.streams.1.vgc $(BUILD)/%.streams.2.vgc $(BUILD)/%.streams.3.vgc $(BUILD)/%.streams.4.vgc $(BUILD)/%.streams.5.vgc $(BUILD)/%.streams.6.vgc $(BUILD)/%.streams.7.vgc  : ./vgms/%.vgm
	$(PYTHON) submodules/vgm-packer/vgmpacker.py -s -o $@ $<

##########################################################################
##########################################################################

.PHONY:clean
clean:
	$(SHELLCMD) rm-tree $(BUILD)

##########################################################################
##########################################################################

.PHONY:_assemble
_assemble:
	$(TASSCMD) "$(SRC).s65" "-L$(BUILD)/$(SRC).lst" "-l$(BUILD)/$(SRC).sym" "-o$(BUILD)/$(SRC).prg"
	$(PYTHON) $(BEEB_BIN)/prg2bbc.py "$(BUILD)/$(SRC).prg" "$(BEEB)/@.$(BBC)"

##########################################################################
##########################################################################

.PHONY:test_b2
test_b2: SSD=vgm_streams_player_test
#test_b2: SSD=vgm_player_test
test_b2:
	curl -G 'http://localhost:48075/reset/b2' --data-urlencode "config=Master 128 (MOS 3.20)"
	curl -H 'Content-Type:application/binary' --upload-file '$(BUILD)/$(SSD).ssd' 'http://localhost:48075/run/b2?name=$(SSD).ssd'

##########################################################################
##########################################################################

.PHONY:tom_emacs
tom_emacs:
	$(MAKE) build
	$(MAKE) test_b2
