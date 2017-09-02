
# avoid implicit rules for clarity
.SUFFIXES: .asm .o .gb
.PHONY: bgb clean tests debug

ASMS := $(wildcard *.asm)
OBJS := $(ASMS:.asm=.o)
INCLUDES := $(wildcard include/*.asm)

all: rom.gb

%.o: %.asm $(INCLUDES)
	rgbasm -i include/ -v -o $@ $<

rom.gb: $(OBJS)
	rgblink -n rom.sym -o $@ $^
	rgbfix -v -p 0 $@

bgb: rom.gb
	bgb $<

clean:
	rm -f *.o *.sym rom.gb

debug:
	./debug
