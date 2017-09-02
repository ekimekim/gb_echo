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
	call EnableScreen

	; Wait for user to press start
	ld D, ButtonStart
	call WaitForPress

	; Pass control to level loop
	call LevelLoop

	; Loop back and return to intro screen
	jp MainLoop
