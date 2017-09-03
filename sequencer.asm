include "ioregs.asm"
include "longcalc.asm"


SEQ_MAX_ENTRIES EQU 32


SECTION "Sequencer RAM", WRAM0


; The sequencer can hold up to SEQ_MAX_ENTRIES entries. Each entry consists of:
;   start time, channel (1-3), volume, frequency (2 bytes), length
; It's the caller's responsibility to:
;   * Not exceed SEQ_LEN_MAX
;   * Know that a new entry for the same play method will replace what's currently playing

RSRESET
seq_time rb 1
seq_channel rb 1
seq_volume rb 1
seq_freq rb 2
seq_len rb 1
SEQ_SIZE rb 0

; length-prefixed unsorted array
SequenceDataLen:
	db
SequenceData:
	ds SEQ_MAX_ENTRIES * SEQ_SIZE


; Spare memory for SequenceNotes, slow but easy way to deal with too many vars for registers
Scratch:
	ds 2


SECTION "Sequencer methods", ROM0


; Reset the sequencer, ready to set up a sequence.
InitSequencer::
	xor A
	ld [SequenceDataLen], A
	ret


; Add a series of notes stored at HL to the sequencer, at volume B, with start time offset C,
; with channel number D.
; The series of notes should be in format:
;   byte length (number of notes)
;   for each note:
;     byte start time
;     word frequency (little endian, same as dw declaration)
;     byte length
; Clobbers all.
SequenceNotes::
	; Store stuff in scratch space to free some regs
	ld A, B
	ld [Scratch], A
	ld A, D
	ld [Scratch+1], A

	; Find next free sequencer entry
	ld A, [SequenceDataLen]
	; Multiply A by SEQ_SIZE
	ld D, A
	ld B, SEQ_SIZE - 1
.mul
	add D
	dec B
	jr nz, .mul
	; A = SEQ_SIZE * [SequenceDataLen]
	LongAddToA SequenceData>>8,SequenceData&$ff, D,E ; DE = SequenceData + SEQ_SIZE * [SequenceDataLen] = &SequenceData[n]
	ld A, [HL+]
	ld B, A ; B = number of notes

	; Add number of notes to sequence data length
	ld A, [SequenceDataLen]
	add B
	ld [SequenceDataLen], A

.loop
	ld A, [HL+] ; A = note start time
	add C ; A = time offset + note start time
	ld [DE], A ; set record time start
	inc DE

	; copy channel
	ld A, [Scratch+1]
	ld [DE], A
	inc DE

	; copy volume
	ld A, [Scratch]
	ld [DE], A
	inc DE

	; copy freq
	ld A, [HL+]
	ld [DE], A
	inc DE
	ld A, [HL+]
	ld [DE], A
	inc DE

	; copy length
	ld A, [HL+]
	ld [DE], A
	inc DE

	; check if we're done
	dec B
	jr nz, .loop

	ret


; Play the enqueued sequence, blocking until it's done (all sounds have finished playing)
; Clobbers all.
PlaySequence::

	; First, we iterate over the sequence entries to find the last start time,
	; so we know when to stop.
	ld D, 0 ; D will hold last start time
	ld HL, SequenceDataLen
	ld A, [HL+]
	ld C, A

.maxloop
	ld A, [HL+]
	cp D ; set c if D > A, ie. if existing max value should NOT be replaced
	jr c, .notgreater
	ld D, A ; if greater (or equal), replace it
.notgreater
	RepointStruct HL, seq_time + 1, SEQ_SIZE ; point HL to the next entry
	dec C
	jr nz, .maxloop

	; We set up a 64Hz timer to count out the time periods
	ld A, TimerEnable | TimerFreq14
	ld [TimerControl], A
	xor A
	ld [TimerModulo], A
	ld [TimerCounter], A ; reset counter in case it was already semi-elapsed
	ld [InterruptFlags], A ; clear any pending interrupts that might have already been firing
	ld A, IntEnableTimer
	ld [InterruptsEnabled], A ; enable only timer interrupt
	ei

	ld B, 0 ; B = current time

.seqloop

	ld HL, SequenceDataLen
	ld A, [HL+] ; HL now points at SequenceData
	ld C, A ; C = number of items in SequenceData

	; for each sequence entry, check if it should be started this tick, if so start it
.findloop
	ld A, [HL+] ; A = start time
	cp B ; set z if start time = current time
	jr nz, .nomatch

	push BC
	push DE
	ld A, [HL+]
	ld C, A ; C = channel
	ld A, [HL+]
	ld B, A ; B = volume
	ld A, [HL+]
	ld E, A
	ld A, [HL+]
	ld D, A ; DE = freq
	ld A, [HL+] ; A = length. note HL now points at next entry.
	call PlayChC ; play sound!
	pop DE
	pop BC
	jr .next

.nomatch
	RepointStruct HL, seq_time+1, SEQ_SIZE ; point HL to next entry

.next
	dec C
	jr nz, .findloop

	; check if we're done
	ld A, B
	cp D ; set z if B = D
	jr z, .wait

	; increment time and wait for next loop
	inc B
	halt
	jr .seqloop

	; We're done starting new sounds, still need to wait for the old ones to finish.
	; Easiest way to do this is to check SoundControl bits
.waitloop
	halt ; wait for next 64Hz tick
.wait
	ld A, [SoundControl]
	and $07 ; set z if all bottom 3 bits (3 used sound channels) are 0
	jr nz, .waitloop

	; Ok, now we're actually done. Make sure to diable the timer and interrupts.
	di
	xor A
	ld [TimerControl], A
	ret
