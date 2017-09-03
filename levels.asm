include "longcalc.asm"
include "joypad.asm"


SECTION "level methods", ROM0


; Loop through all the levels then return.
LevelLoop::

	; Disable screen, which is currently displaying the intro screen
	call DisableScreen

	ld E, 1 ; level number
	ld HL, LevelData ; Point to first level

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
	push HL
;	call GameLoop TODO
	pop HL
	pop DE

	; We finished the level.
	; Increment revevant things, check if we're done.
	inc E ; increment level number
	call SeekNextLevelData ; HL = next level data or LevelDataEnd
	ld A, H
	cp LevelDataEnd >> 8
	jr nz, .notdone
	ld A, L
	cp LevelDataEnd & $ff
	jr z, .done
.notdone

	; Not done yet, play individual level fanfare
	push DE
	push HL
	call PlayLevelWin
	pop HL
	pop DE

	; Loop back for next level
	jp .loop

.done
	; All levels beaten! Play end of game fanfare
	call PlayGameWin

	ret


; Takes existing level data at HL and points HL to next level data
SeekNextLevelData:
	ld A, [HL+]
	ld B, A ; B = width
	ld A, [HL+]
	ld C, A ; C = height
	LongAddConst HL, 2 ; Including the two increments above, HL = start of data section
	; Below loop does HL += width * height
.loop
	LongAdd H,L, 0,B, H,L ; HL += B
	dec C
	jr nz, .loop
	; HL now points to just after this level data
	ret


; Play end of level fanfare. Clobbers all.
PlayLevelWin:
	call InitSequencer
	ld HL, LevelWin
	ld B, 15
	ld C, 0
	ld D, 3
	call SequenceNotes
	jp PlaySequence


; Play end of game fanfare. Clobbers all.
PlayGameWin:
	call InitSequencer
	ld HL, GameWin
	ld B, 15
	ld C, 0
	ld D, 3
	call SequenceNotes
	jp PlaySequence
