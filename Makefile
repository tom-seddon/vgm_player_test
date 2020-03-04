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
	$(MAKE) $(BUILD)/icepalace.vgc
	$(MAKE) $(BUILD)/VE3.vgc

	$(PYTHON) submodules/vgm-packer/vgcfit.py -o $(BUILD)/icepalace $(BUILD)/icepalace.vgc --banks 45

	$(SHELLCMD) copy-file $(BUILD)/icepalace.4.dat $(BEEB)/4.ICE
	$(SHELLCMD) copy-file $(BUILD)/icepalace.5.dat $(BEEB)/5.ICE

	$(PYTHON) submodules/vgm-packer/vgcfit.py -o $(BUILD)/ve3 $(BUILD)/ve3.vgc --banks 45

	$(SHELLCMD) copy-file $(BUILD)/VE3.4.dat $(BEEB)/4.VE3
	$(SHELLCMD) copy-file $(BUILD)/VE3.5.dat $(BEEB)/5.VE3

	$(MAKE) _assemble SRC=vgcplayer_test BBC=vgc

	$(MAKE) _assemble SRC=vgcplayer_icepalace BBC=ice

	$(MAKE) _assemble SRC=vgcplayer_VE3 BBC=ve3

	$(PYTHON) $(BEEB_BIN)/ssd_create.py -v -o $(BUILD)/vgm_player_test.ssd $(BEEB)/@.VGC $(BEEB)/$$.vgmplay --build "*LOAD VGMPLAY" --build "*RUN @.VGC"

	$(PYTHON) $(BEEB_BIN)/ssd_create.py -v -o $(BUILD)/vgcplayer_icepalace.ssd $(BEEB)/4.ICE $(BEEB)/5.ICE $(BEEB)/$$.VGMPLAY $(BEEB)/@.ICE --build "*SRLOAD 4.ICE 8000 4 Q" --build "*SRLOAD 5.ICE 8000 5 Q" --build "*LOAD VGMPLAY" --build "*RUN @.ICE"

	$(PYTHON) $(BEEB_BIN)/ssd_create.py -v -o $(BUILD)/vgcplayer_VE3.ssd $(BEEB)/4.VE3 $(BEEB)/5.VE3 $(BEEB)/$$.VGMPLAY $(BEEB)/@.VE3 --build "*SRLOAD 4.VE3 8000 4 Q" --build "*SRLOAD 5.VE3 8000 5 Q" --build "*LOAD VGMPLAY" --build "*RUN @.VE3"

$(BUILD)/%.vgc : ./vgms/%.vgm
	$(PYTHON) submodules/vgm-packer/vgmpacker.py -o $@ $<

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
test_b2: SSD=vgcplayer_VE3
#test_b2: SSD=vgcplayer_icepalace
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
