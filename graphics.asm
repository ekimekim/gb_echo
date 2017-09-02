include "vram.asm"
include "macros.asm"


SECTION "Tile data", ROM0

TileData:
	ds $20
	; Space is character 0x20, so by including the ascii font here it all lines up
include "assets/font.asm"

EndTileData:
TILE_DATA_SIZE EQU EndTileData - TileData


SECTION "Graphics routines", ROM0


; Load tile data into VRAM while screen is off
LoadTiles::
	ld BC, TILE_DATA_SIZE
	ld HL, TileData
	ld DE, BaseTileMap
	LongCopy ; Copy BC bytes from HL to DE
	ret
