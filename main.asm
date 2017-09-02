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

	; Initialize level number and pass control to level loop
	xor A
	ld [LevelNumber], A
	call LevelLoop

	; Disable screen to reset to initial state
	call DisableScreen

	; Loop back and return to intro screen
	jp MainLoop
