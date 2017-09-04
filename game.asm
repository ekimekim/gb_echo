include "debug.asm"
include "longcalc.asm"
include "joypad.asm"


SECTION "Game vars", WRAM0

; To free registers and make things simpler/easier, we store things in memory and pull
; them when we need them.
LevelWidth:
	db
LevelHeight:
	db
PlayerPos:
	dw ; big endian, address in level data
PlayerDirection:
	db ; 0-3: up, right, down, left
LevelBase:
	dw ; big endian


SECTION "Game logic", ROM0


; Main game loop. Expects level data at HL. Clobbers all.
GameLoop::

	; Set up variables.
	ld A, [HL+]
	ld [LevelWidth], A
	ld D, A ; also put in D for calculation immediately below
	ld A, [HL+]
	ld [LevelHeight], A
	ld A, [HL+]
	ld B, A ; B = player X pos
	ld A, [HL+]
	ld C, A ; C = player Y pos
	xor A
	ld [PlayerDirection], A ; always start facing up
	; Note HL now points at start of level data array proper

	; calculate player start position from X pos (B), Y pos (C), width (D) and level data array base (HL)
	; HL = HL + C*D + B
	LongAdd H,L, 0,B, H,L ; HL += B
.mul
	LongAdd H,L, 0,C, H,L ; HL += C
	dec D
	jr nz, .mul
	; store it
	ld A, H
	ld [PlayerPos], A
	ld A, L
	ld [PlayerPos+1], A

.mainloop

	; Wait for input, put it in B. TODO pause on start, cheat code?
	ld D, ButtonA | ButtonLeft | ButtonRight | ButtonUp
	call WaitForPress

	; To simplify logic, if we get more than one press, we only act on one.
	; Players can Deal With It.

	ld A, B
	and ButtonA ; set z unless this button is set
	jr z, .noA

	; A pressed, play tap sound.
	ld HL, SoundTap
	jr .playSound

.noA
	ld A, B
	and ButtonLeft | ButtonRight
	jr z, .noTurn

	; Left or right pressed, change direction -1 or +1 (mod 4) respectively and play turn sound.
	and ButtonLeft
	jr z, .turnRight
	ld C, -1
	jr .turn
.turnRight
	ld C, 1
.turn
	ld A, [PlayerDirection]
	add C
	and $03 ; mod 4
	ld [PlayerDirection], A
	ld HL, SoundTurn
	jr .playSound

.noTurn
	ld A, B
	and ButtonUp
	jr z, .noUp

	; Up pressed, try to move forward, play either step sound or bonk sound, or win.
	ld A, [PlayerPos]
	ld D, A
	ld A, [PlayerPos+1]
	ld E, A ; DE = current position in level data
	ld A, [PlayerDirection]
	call GetDirectionOffset ; BC = signed 16-bit offset that corresponds to 'forward' in player's direction
	LongAdd D,E, B,C, D,E ; DE += offset
	ld A, [DE]
	cp " " ; set z only if it's an empty space
	jr nz, .bonk_or_win
	; Update player position to DE, set step sound
	ld A, D
	ld [PlayerPos], A
	ld A, E
	ld [PlayerPos+1], A
	ld HL, SoundStep
	jr .playSound
.bonk_or_win
	cp "*" ; set z if it's the crystal
	ret z ; if so, we win! return to level loop.
	ld HL, SoundBonk ; if not, it's a wall. we bonk. play bonk sound.
	jr .playSound

.noUp
	; Nothing pressed. This shouldn't happen? Oh well, do nothing.
	Debug "WaitForPress returned but no button pressed"
	jr .mainloop

.playSound
	; We expect sound to play to be in HL.
	; We need to do a few things:
	;  * Set to play the original sound at full volume on Ch3 (both ears)
	;  * For each direction forward, left and right (relative to player direction):
	;    * Calculate distance to first block, transform into echo delay time and volume
	;    * If it's the end goal, set SoundCrystalEcho, otherwise set original sound
	;    * Set to play that sound at the given delay time and volume, on the appropriate channel
	;      (1 for left, 2 for right, 3 for forward)
	;  * Call sequencer for sounds to play

	call InitSequencer

	; Sequence original sound
	ld B, 15 ; Full volume
	ld C, 0 ; No delay
	ld D, 3 ; Channel 3 (both ears)
	push HL ; Clobbers HL, so save it first
	call SequenceNotes
	pop HL

	; For each direction, sequence echo
	ld A, [PlayerDirection]
	ld D, 3
	call SequenceEcho ; for forward
	ld A, [PlayerDirection]
	inc A
	and $03 ; mod 4
	ld D, 2
	call SequenceEcho ; for right
	ld A, [PlayerDirection]
	dec A
	and $03 ; mod 4
	ld D, 1
	call SequenceEcho ; for left

	; Play it!
	call PlaySequence

	; Done with this loop, start again
	jp .mainloop





; Sequence either sound in HL or SoundCrystalEcho (depending on what we hit) to play
; in channel D after extending a probe in direction A to calculate delay echo and volume.
; Does not clobber HL.
SequenceEcho:
	; TODO
	ret



; Calcluate offset in level data array that corresponds to 'forward' in the direction contained
; in A. For example, up becomes -width (up one block), right becomes 1 (right one block).
; Returns the value in BC as a 16-bit signed value.
GetDirectionOffset:
	ld B, A
	and $01 ; set z if even (up or down)
	jr z, .up_down
	; Left/right: we set it to +1, then if it's left we minus 2.
	ld A, B
	ld BC, 1
	cp 3 ; set z if left
	ret nz
	dec BC
	dec BC
	ret
.up_down
	; Up/down: if up (0), -width. Otherwise +width.
	ld A, B
	and A ; set z if up
	ld A, [LevelWidth] ; A = width
	ld B, 0
	ld C, A ; BC = A
	ret nz ; if down, we're done
	; BC = -A. Note B already = 0.
	ld C, A
	xor A
	sub C
	ld C, A ; C = -A
	dec B ; B = $ff, same as if we'd done BC - A properly.
	ret
