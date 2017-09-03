include "freq.asm"


SECTION "Sequence note data", ROM0

; Reminder: Format is byte number of notes, then notes of
;	(byte start time in 1/64s, word frequency, byte length in 1/256s).

; Define a note (start time, frequency, length)
Note: MACRO
	db \1
	dw \2
	db \3
ENDM


; Plays when a level is completed
LevelWin::
	db 5
	Note 0, NOTE_C6, 32
	Note 8, NOTE_A5, 32
	Note 16, NOTE_B5, 32
	Note 24, NOTE_C6, 64
	Note 39, NOTE_C6, 64


; Plays when game is completed
GameWin::
	; PLACEHOLDER
	db 6
	Note 0, NOTE_C2, 64
	Note 16, NOTE_C3, 64
	Note 32, NOTE_C4, 64
	Note 48, NOTE_C5, 64
	Note 64, NOTE_C6, 64
	Note 80, NOTE_C7, 64
