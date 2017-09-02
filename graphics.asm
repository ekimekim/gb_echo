include "ioregs.asm"
include "vram.asm"
include "macros.asm"
include "longcalc.asm"


SECTION "Graphics data", ROM0

TileData:
	ds $20*16
	; Space is character 0x20, so by including the ascii font here it all lines up
include "assets/font.asm"

EndTileData:
TILE_DATA_SIZE EQU EndTileData - TileData


IntroScreen:
db "                    "
db "  Welcome to ECHO   "
db "                    "
db " Navigate the maze  "
db " using your ears.   "
db "                    "
db " D-pad to turn and  "
db " step forward, A to "
db " tap.               "
db "                    "
db " Listen carefully   "
db " and try to find    "
db " the crystal to     "
db " take you to the    "
db " next level.        "
db "                    "
db "    PRESS START     "
db "                    "
EndIntroScreen:
INTRO_SCREEN_SIZE EQU EndIntroScreen - IntroScreen
IF INTRO_SCREEN_SIZE != 360
FAIL "Bad screen definition: Expected 0x168 bytes, got {INTRO_SCREEN_SIZE}"
ENDC


SECTION "Graphics routines", ROM0


; Load tile data into VRAM while screen is off
LoadTiles::
	ld BC, TILE_DATA_SIZE
	ld HL, TileData
	ld DE, BaseTileMap
	LongCopy ; Copy BC bytes from HL to DE
	ret


; Load intro screen into VRAM while screen is off
DisplayIntroScreen::
	ld HL, IntroScreen
	ld DE, TileGrid
	ld B, 18
.loop
REPT 19
	ld A, [HL+]
	ld [DE], A
	inc DE
ENDR
	ld A, [HL+]
	ld [DE], A
	LongAdd D,E, 0,13, D,E ; DE += 15, bringing it to the start of the next row
	dec B
	jr nz, .loop

	jp ClearSprites


; Clear all sprite info while screen is off
ClearSprites::
	xor A
	ld B, 40*4/8
	ld HL, SpriteTable
.loop
REPT 8
	ld [HL+], A
ENDR
	dec B
	jr nz, .loop
	ret


; Block until next vblank and then safely turn off the screen.
; Clobbers A.
DisableScreen::
	; Disable all interrupts except vblank
	ld A, IntEnableVBlank
	ld [InterruptsEnabled], A
	; Cancel any old pending interrupts
	xor A
	ld [InterruptFlags], A
	; Block until next vblank occurs
	ei
	halt
	di
	; Now it's safe to disable screen
	xor A
	ld [LCDControl], A
	ret
