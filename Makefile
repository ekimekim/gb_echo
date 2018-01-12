
# avoid implicit rules for clarity
.SUFFIXES: .asm .o .gb
.PHONY: bgb clean tests debug

ASMS := $(wildcard *.asm)
OBJS := $(ASMS:.asm=.o)
INCLUDES := $(wildcard include/*.asm)
ASSETS := $(shell find assets/ -type f)

MBC := 0
RAM_SIZE := 0
TITLE := "ECHO"

all: rom.gb

include/assets/.uptodate: $(ASSETS) tools/assets_to_asm.py
	python tools/assets_to_asm.py assets/ include/assets/
	touch $@

%.o: %.asm $(INCLUDES) include/assets/.uptodate
	rgbasm -i include/ -v -o $@ $<

rom.gb: $(OBJS)
	rgblink -n rom.sym -o $@ $^
	rgbfix -j -l 51 -m $(MBC) -r $(RAM_SIZE) -t $(TITLE) -v -p 0 $@

bgb: rom.gb
	bgb $<

clean:
	rm -f *.o *.sym rom.gb

debug:
	./debug
