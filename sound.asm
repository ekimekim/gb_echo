include "ioregs.asm"


SECTION "Sound routines", ROM0


InitSound::
	; Enable sound card, allowing other values to be set
	ld A, %10000000
	ld [SoundControl], A

	; TEST
	ld A, %00000111
	ld [SoundVolume], A
	ld A, $ff
	ld [SoundMux], A

	ld A, %01111111
	ld [SoundCh1Sweep], A
	ld A, %10000000
	ld [SoundCh1LengthDuty], A
	ld A, %11110000
	ld [SoundCh1Volume], A
	ld A, 240
	ld [SoundCh1FreqLo], A
	ld A, %10000111
	ld [SoundCh1Control], A
	jp HaltForever
