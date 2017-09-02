include "ioregs.asm"
include "vram.asm"
include "macros.asm"
include "longcalc.asm"


CheckScreenSize: MACRO
_SIZE SET (\2)
IF _SIZE != 360
FAIL "Bad screen definition \1: Expected 0x168 bytes, got {_SIZE}"
ENDC
ENDM


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
	CheckScreenSize IntroScreen, INTRO_SCREEN_SIZE


LevelTitleScreen:
db "                    "
db "                    "
db "                    "
db "                    "
db "                    "
db "                    "
db "                    "
db "                    "
db "      LEVEL  0      " ; 0 will be replaced with level number. Coordinate = (8,13)
db "                    "
db "                    "
db "                    "
db "                    "
db "                    "
db "                    "
db "                    "
db "    PRESS START     "
db "                    "
EndLevelTitleScreen:
LEVEL_TITLE_SCREEN_SIZE EQU EndLevelTitleScreen - LevelTitleScreen
	CheckScreenSize LevelTitleScreen, LEVEL_TITLE_SCREEN_SIZE


SECTION "Graphics routines", ROM0


; Load tile data into VRAM while screen is off
LoadTiles::
	ld BC, TILE_DATA_SIZE
	ld HL, TileData
	ld DE, BaseTileMap
	LongCopy ; Copy BC bytes from HL to DE
	ret


; Load screen at HL into VRAM while screen is off.
; Clobbers All but E.
DisplayScreen:
	ld BC, TileGrid
	ld D, 18
.loop
REPT 19
	ld A, [HL+]
	ld [BC], A
	inc BC
ENDR
	ld A, [HL+]
	ld [BC], A
	LongAdd B,C, 0,13, B,C ; BC += 15, bringing it to the start of the next row
	dec D
	jr nz, .loop
	ret


; Display game intro screen
DisplayIntroScreen::
	ld HL, IntroScreen
	call DisplayScreen
	jp ClearSprites


; Display level title screen. Draw the static screen then go back and fix the level number.
; Level number should be in E.
DisplayLevelTitle::
	ld HL, LevelTitleScreen
	call DisplayScreen
	ld HL, TileGrid + 32*8 + 13 ; coord (8,13)
	ld [HL], E
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
