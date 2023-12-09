# SPDX-FileCopyrightText: © 2023 Ryan Carsten Schmidt <https://github.com/ryandesign>
# SPDX-License-Identifier: MIT

C2D := c2d
C2T := c2t
CL65 := cl65

PROG := colorinspector
LOAD_ADDRESS := C00

all: $(PROG).dsk

aif: $(PROG).aif

dsk: $(PROG).dsk

dos: $(PROG).dos.dsk

play: $(PROG).aif
	afplay $^

run: $(PROG).dsk
	./openemulator.applescript $^

$(PROG): $(PROG).as
	applesingle decode -o $@.$$$$ $^ && touch $@.$$$$ && mv $@.$$$$ $@

$(PROG).as: $(PROG).s vaporlock.s
	$(CL65) -t apple2 -C apple2-asm.cfg --start-addr 0x$(LOAD_ADDRESS) -u __EXEHDR__ -o $@ $^

$(PROG).aif: $(PROG)
	$(C2T) -bc $^,$(LOAD_ADDRESS) $@

$(PROG).dsk: $(PROG)
	$(C2D) -b $<,$(LOAD_ADDRESS) $@

$(PROG).dos.dsk: $(PROG).as
	ac -dos140 $@
	ac -as $@ $(PROG) < $<

clean:
	rm -f $(PROG) $(PROG).as $(PROG).aif $(PROG).dsk *.o

.PHONY: all aif dsk play run clean
