include "ioregs.asm"
include "macros.asm"


SECTION "Input methods", ROM0


; Get joypad input state and return it in A.
; Clobbers B.
GetState:
	ld A, JoySelectDPad
	ld [JoyIO], A
	Wait 6
	ld A, [JoyIO]
	ld B, A
	ld A, JoySelectButtons
	ld [JoyIO], A
	ld A, $0f
	and B
	swap A
	ld B, A
	; it's now been 6 cycles
	ld A, [JoyIO]
	and $0f
	or B ; A = (DPad, Buttons)
	cpl ; A = ~A, because 0s are pressed and 1s are not-pressed
	ret


; Block until a keypress from mask D is detected, then return it in B.
; Result is a bitmask of keys (down, up, left, right, start, select, B, A).
; eg. set D to a single button to simply block until it's pressed, or set D to $ff
; to capture any button press.
; Clobbers A, C
WaitForPress::
	call GetState ; A = current state
	ld C, A

	; Set up a 64Hz timer
	ld A, TimerEnable | TimerFreq14
	ld [TimerControl], A
	xor A
	ld [TimerModulo], A

	; Disable all interrupts except timer
	ld A, IntEnableTimer
	ld [InterruptsEnabled], A
	ei

	; Now when we call halt, it waits until next timer tick
.loop
	halt
	call GetState
	ld B, A ; B = new state
	ld A, C ; A = old state
	cpl
	and B ; A = new & !old, ie. bit has gone 0->1.
	and D ; combine it with the given mask, setting z if it's empty
	ld C, B ; old state = new state
	jr z, .loop ; if nothing pressed from mask (or at all), wait for next loop around

	ld B, A

	di
	xor A
	ld [TimerControl], A ; disable timer

	ret
