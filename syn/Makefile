# TOP := top_level
# TOP := blinky
#TOP := fifo_test
TOP := top_module

# default modulator
MOD := am
PLL := 120
#deault board
HW:= mercurial
# HW:= bk

SRC := $(wildcard ../modules/*.v)
# SRC += $(wildcard ../modules/pll/pll_$(PLL)MHz.v)
# SRC += $(filter-out $(wildcard ../modules/modulator_*/*.v) $(wildcard ../modules/pll/*.v), $(wildcard ../modules/**/*.v ../top/$(TOP).v) )

# SRC := $(wildcard ../modules/blinky/*.v)

#SRC := $(wildcard ../top/fifo-test.v)
# SRC := $(wildcard ../top/rx-8000.v)
SRC += $(wildcard ../top/serializer-v2.v)
#SRC += $(wildcard ../top/serializer-v2.v)
INC := ../inc/
BUILD = ../build

ifeq ($(HW),bk)
	PACKAGE = ct256
	HW = breakout
	PCF = breakout.pcf
else 
	PACKAGE = tq144:4k
	PCF = pf-2020.pcf
endif

all:  syn pnr pack
.phony: show, prog, load-cram, clean

syn: $(BUILD)/$(TOP).json
pnr : $(BUILD)/$(TOP).asc
pack: $(BUILD)/$(TOP).bin


show:
	@echo $(SRC)

show-defines:
	@echo $(DEFINES)

show-blocks: $(SRC)
	yosys -p "read_verilog -I$(INC) ../top/$(TOP).v; show -format svg -prefix ./show"

$(BUILD)/$(TOP).blif $(BUILD)/$(TOP).json: $(SRC)
	mkdir -p $(BUILD)
	yosys -p "read_verilog $(SRC); synth_ice40 -top $(TOP) -blif $(BUILD)/$(TOP).blif -json $(BUILD)/$(TOP).json"

$(BUILD)/$(TOP).asc: $(BUILD)/$(TOP).json $(PCF)
	nextpnr-ice40 --hx8k --package $(PACKAGE) --pcf $(PCF) --json $(BUILD)/$(TOP).json --asc $(BUILD)/$(TOP).asc

$(BUILD)/$(TOP).bin: $(BUILD)/$(TOP).asc
	icepack $(BUILD)/$(TOP).asc $(BUILD)/$(TOP).bin

prog: $(BUILD)/$(TOP).bin
	@echo "Writing $(TOP).bin into the flash memory"
	iceprog $(BUILD)/$(TOP).bin

load-cram: $(BUILD)/$(TOP).bin
	@echo "Loading $(TOP).bin into the CRAM"
	iceprog -S $(BUILD)/$(TOP).bin

clean:
	rm $(BUILD)/$(TOP).bin $(BUILD)/$(TOP).asc $(BUILD)/$(TOP).json $(BUILD)/$(TOP).blif --force
