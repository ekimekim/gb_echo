include "ioregs.asm"
include "hram.asm"

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

; TEST
	ld B, 15
	ld DE, 1547
	xor A
	call PlayCh3
	xor A
;	call PlayCh1
	xor A
;	call PlayCh2
	jp HaltForever

	; Initialize tilemap
;	call LoadTiles

;	call MainLoop


MainLoop::
	; Display the intro screen
;	call DisplayIntroScreen
	ld A, %10010011 ; screen on, background map + sprites, unsigned tileset
	ld [LCDControl], A	

	; Wait for user to start
;	call WaitForStart

	; Initialize level number and pass control to level loop
	xor A
	ld [LevelNumber], A
;	call LevelLoop

	; Loop back and return to intro screen
	jp MainLoop
