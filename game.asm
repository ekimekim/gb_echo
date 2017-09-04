include "debug.asm"
include "longcalc.asm"
include "joypad.asm"


; Echo-related constants
BASE_DELAY EQU 20 ; Min time before any echo can happen (actually DELAY_PER_BLOCK less than that since min distance is 1)
DELAY_PER_BLOCK EQU 8 ; How much delay to add for each extra block of distance
BASE_VOLUME EQU 10 ; Max volume an echo can play at
VOLUME_PER_BLOCK EQU 1.0 ; Volume loss per block, as 16.16-bit fixed point float
VOLUME_PER_BLOCK_16 EQU VOLUME_PER_BLOCK >> 12 ; Volume loss per block, times 16.

PRINTT "Calculated VOLUME_PER_BLOCK_16 = {VOLUME_PER_BLOCK_16} from VOLUME_PER_BLOCK = "
PRINTF VOLUME_PER_BLOCK
PRINTT "\n"


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

	; Wait for input, put it in B.
	ld D, ButtonA | ButtonLeft | ButtonRight | ButtonUp
	call WaitForPress

	; To simplify logic, if we get more than one press, we only act on one.
	; Players can Deal With It.

	ld A, B
	and ButtonA ; set z unless this button is set
	jr z, .noA

	; A pressed, play tap sound.
	ld HL, SoundTap
	jp .playSound

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
	jp .playSound

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
	jp .mainloop

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
	push HL ; We'll restore HL a few times over the course of the routine

	; First, work out distance to wall
	call GetDirectionOffset ; BC = direction offset of given direction
	ld A, [PlayerPos]
	ld H, A
	ld A, [PlayerPos+1]
	ld L, A ; HL = player pos
	ld E, 0
.probeloop
	inc E
	LongAdd H,L, B,C, H,L ; HL += BC, ie. move 1 block in direction
	ld A, [HL]
	cp " " ; set z if A is empty space
	jr z, .probeloop ; keep going if empty space
	; now E holds number of blocks of empty space between us and wall,
	; and A holds the first non-empty block we hit.
	Debug "Got distance %E% hitting %A%"
	push AF ; store what block we hit for later

.noCrystal
	; Delay = BASE_DELAY + DELAY_PER_BLOCK * blocks of empty space
	; Volume = BASE_VOLUME - VOLUME_PER_BLOCK_16 * blocks of empty space / 16
	; Do the multiplication parts first
	ld C, BASE_DELAY
	ld B, 0
	ld H, DELAY_PER_BLOCK
	ld L, VOLUME_PER_BLOCK_16
.calcloop
	ld A, C
	add H
	ld C, A ; C += H
	ld A, B
	add L
	ld B, A ; B += L
	jr c, .noSound ; if B overflows, we know it's too far to hear anyway (volume < 0)
	dec E
	jr nz, .calcloop
	; Now C = delay, B = volume loss * 16

	ld A, B
	and $f0
	swap A ; A = A/16
	ld B, A
	ld A, BASE_VOLUME
	sub B ; A = volume, set carry if < 0, set z if 0

	jr c, .noSound
	jr z, .noSound ; if volume <= 0, don't play anything

	ld B, A ; B = volume
	pop AF ; restore A = block we hit
	pop HL ; restore sound value
	push HL ; this routine is going to clobber HL, we need to restore it again before returning
	; C already = delay from above
	; D already = channel from routine input

	; Special case: did we hit the crystal?
	cp "*"
	jr nz, .notCrystal
	; it is, then use alternate sound and halve volume (round up).
	ld HL, SoundCrystalEcho
	; Note that we know carry is unset right now because cp above resulted in zero
	ld A, B
	RRA ; rotate A right through carry flag, ie. add 0 to MSB and put LSB in carry
	adc 0 ; add 1 if carry is set. we've now halved the volume, but rounded up.
	ld B, A
.notCrystal

	Debug "Seq %HL% at time %C% vol %B% on ch %D%"
	call SequenceNotes
	jr .ret

.noSound
	pop AF ; balance stack
.ret
	pop HL ; restore HL one last time
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
