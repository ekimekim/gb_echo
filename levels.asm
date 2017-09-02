include "joypad.asm"


; TODO TEMP
NUM_LEVELS EQU 6


SECTION "level methods", ROM0


; Loop through all the levels then return.
LevelLoop::

	; Disable screen, which is currently displaying the intro screen
	call DisableScreen

	ld E, 1 ; level number
;	ld HL, LevelData ; Point to first level TODO

.loop

	; Display level title screen. Uses E. Clobbers HL so we save it.
	push HL
	call DisplayLevelTitle
	pop HL
	call EnableScreen

	; Wait until player presses start
	ld D, ButtonStart
	call WaitForPress

	; Disable screen for core gameplay
	call DisableScreen

	; Pass control to game loop. Make sure to save things.
	push DE
;	call GameLoop TODO
	pop DE

	; We finished the level.
	; Increment revevant things, check if we're done.
	inc E
	ld A, E
	cp NUM_LEVELS
	jr z, .done
	; TODO move HL to start of next level data

	; Not done yet, play individual level fanfare
;	call PlayLevelWin TODO

	; Loop back for next level
	jp .loop

.done
	; All levels beaten! Play end of game fanfare
;	call PlayGameWin TODO

	ret
