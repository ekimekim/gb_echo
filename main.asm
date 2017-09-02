include "ioregs.asm"
include "hram.asm"
include "joypad.asm"


SECTION "Stack", WRAM0

StackBase:
	ds 128
Stack:


SECTION "Main", ROM0


Start::
	; Disable LCD, audio
	xor A
	ld [SoundControl], A
	ld [LCDControl], A

	; Load stack
	ld SP, Stack

	; disable all interrupts
	xor A
	ld [InterruptsEnabled], A

	; Initialize sound settings
	call InitSound

	; Initialize tilemap
	call LoadTiles

	call MainLoop


MainLoop::
	; Display the intro screen
	call DisplayIntroScreen
	ld A, %10010011 ; screen on, background map + sprites, unsigned tileset
	ld [LCDControl], A	

	; Wait for user to press start
	ld D, ButtonStart
	call WaitForPress

	; TEST
	ld B, 15
	ld A, 0
	ld DE, 1500
	call PlayCh3
	jp HaltForever

	; Initialize level number and pass control to level loop
	xor A
	ld [LevelNumber], A
;	call LevelLoop

	; Loop back and return to intro screen
	jp MainLoop
