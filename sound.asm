include "ioregs.asm"


TONE_CHANNEL_DUTY EQU %10 << 6 ; 50% duty cycle


SECTION "Sound routines", ROM0


InitSound::
	; Enable sound card, allowing other values to be set
	ld A, %10000000
	ld [SoundControl], A

	; Set full volume on left/right channels, no Vin
	ld A, $77
	ld [SoundVolume], A

	; Set sound channels 1 -> left, 2 -> right, 3 -> both, 4 -> none
	ld A, %01010110
	ld [SoundMux], A

	; Channel 1: No sweep. Volume, frequency, length get set later.
	xor a
	ld [SoundCh1Sweep], A

	; Channel 2: Nothing to do. Volume, frequency, length get set later.

	; Channel 3: Set volume to full, since we're going to manually control
	; volume by writing different wave amplitudes. Set sound on (it still won't
	; actually start playing yet). Set all of the wave data to 0, we'll set part of it non-zero later.
	ld A, %10000000
	ld [SoundCh3OnOff], A
	ld A, %00100000
	ld [SoundCh3Volume], A
	ld C, SoundCh3Data & $ff
	xor A
REPT 15
	ld [C], A
	inc C
ENDR
	ld [C], A

	ret


; Tells channel 1 to play a note with frequency DE (0-2047) for length A (0-63)
; at volume B (0-15). Clobbers A, C.
PlayCh1::
	ld C, SoundCh1LengthDuty & $ff
	jp PlayTone

; As PlayCh1, but for channel 2.
PlayCh2::
	ld C, SoundCh2LengthDuty & $ff
	; FALL THROUGH
PlayTone:
	; A = length, B = volume, DE = freq, C = lower byte of address of length register
	or TONE_CHANNEL_DUTY ; A = duty | length, which are non-overlapping bit ranges
	ld [C], A ; set length and duty
	inc C ; C now points at volume register
	ld A, B
	swap A ; A = vvvv0000
	ld [C], A ; set volume
	inc C ; C now points at freq low register
	ld A, E
	ld [C], A ; set freq low
	inc C ; C now points at freq hi / control register
	ld A, D
	or %11000000 ; start playing, stop when length expires, plus top 3 bits of frequency
	ld [C], A
	ret


; As PlayCh1, but for channel 3. Length may be up to 255.
PlayCh3::
	ld [SoundCh3Length], A ; set length

	; Channel 3 doesn't have the fine volume control the others do. Instead, we set the volume
	; by directly setting the wave amplitude in the custom wave data.
	; We assume the half of the samples we aren't setting are already 0.
	ld C, SoundCh3Data & $ff
	ld A, B
	swap A
	or B ; A = vvvv vvvv, where vvvv is the desired volume
REPT 3
	ld [C], A
	inc C
	ld [C], A
	inc C
	ld [C], A
	inc C
	ld [C], A
	inc C
	inc C
	inc C
	inc C
	inc C
ENDR
	ld [C], A
	inc C
	ld [C], A
	inc C
	ld [C], A
	inc C
	ld [C], A

	; Load frequency
	ld A, E
	ld [SoundCh3FreqLo], A
	ld A, D
	or %11000000 ; start playing, stop when length expires, plus top 3 bits of frequency
	ld [SoundCh3Control], A
	ret


; As PlayCh1-3, but selects channel from C (1-3)
PlayChC::
	dec C ; C = 0 to 2, set z if original value was 1
	jp z, PlayCh1 ; note this is a tail call
	dec C ; C = 0 to 1, set z if original value was 2
	jp z, PlayCh2
	; if we've reached here, must be 3
	jp PlayCh3
