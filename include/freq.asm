
; Set assembler value FREQ to desired frequency in Hz as a 16.16-bit fixed point.
; Then run this macro. It will set FVALUE to the frequency value needed for that frequency.
CalcFreq: MACRO
; Note we implicitly multiply by 4 by shifting 2 less, offsetting the smaller numerator.
; Note we round by adding 1/2 (actually 1/8 since we're working with 1/4 of actual value)
FVALUE SET 2048 - ((DIV(32768.0, (FREQ)) + 0.125) >> 14)
PRINTF FREQ
PRINTT " got calculated to value {FVALUE}\n"
ENDM
