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
SoundLevelWin::
	db 5
	Note 0, NOTE_C6, 32
	Note 8, NOTE_A5, 32
	Note 16, NOTE_B5, 32
	Note 24, NOTE_C6, 64
	Note 39, NOTE_C6, 64


; Plays when game is completed
SoundGameWin::
	; PLACEHOLDER
	db 6
	Note 0, NOTE_C2, 64
	Note 16, NOTE_C3, 64
	Note 32, NOTE_C4, 64
	Note 48, NOTE_C5, 64
	Note 64, NOTE_C6, 64
	Note 80, NOTE_C7, 64


; Plays when player taps. Short, simple, relatively high pitch so it's the clearest.
SoundTap::
	db 1
	Note 0, NOTE_Gs4, 32


; Plays when player turns. Meant to evoke a kind of *swish*.
SoundTurn::
	db 3
	Note 0, NOTE_G4, 16
	Note 4, NOTE_D4, 16
	Note 16, NOTE_E4, 32


; Plays when player steps forward. Meant to evoke footsteps.
SoundStep::
	db 2
	Note 0, NOTE_G4, 32
	Note 12, NOTE_G4, 16


; Plays when player tries to step into a wall. A generic failure noise.
SoundBonk::
	db 2
	Note 0, NOTE_Cs3, 16
	Note 4, NOTE_Cs2, 64


; Plays when any sound echos off a crystal. Meant to evoke a shine.
SoundCrystalEcho::
	db 2
	Note 0, NOTE_D6, 64
	Note 15, NOTE_D6, 64
	Note 22, NOTE_D6, 64
