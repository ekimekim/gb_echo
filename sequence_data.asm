

SECTION "Sequence note data", ROM0

; Reminder: Format is byte number of notes, then notes of
;	(byte start time in 1/64s, word frequency, byte length in 1/256s).

; Define a note (start time, frequency, length)
Note: MACRO
	db \1
	dw \2
	db \1
ENDM


; Plays when a level is completed
LevelWin::
	db 5
	Note 0, NOTE_C6, 32
	Note 8, NOTE_A5, 32
	Note 16, NOTE_B5, 32
	Note 24, NOTE_C6, 64
	Note 40, NOTE_C6, 64
