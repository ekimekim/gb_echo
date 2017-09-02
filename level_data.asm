

CheckSize: MACRO ; NAME SIZE WIDTH ROWS
_SIZE SET (\2)
_EXPECTED SET (\3) * (\4) + 4
IF _SIZE != _EXPECTED
FAIL "Bad level data for \1: For \2 x \3, expected {_EXPECTED} but got {_SIZE}"
ENDC
ENDM


SECTION "Level data", ROM0


LevelData::
; Level format is inefficient but simple.
; Starts with header bytes (width, height, start x, start y) then rows of data.
; Each cell is one of " " for empty, "x" for wall, "*" for target.
; All levels MUST have an outer border, or the collision detection will happily run off the end!


L1:
	db 10, 10, 8, 3
	db "xxxxxxxxxx"
	db "x        x"
	db "x        x"
	db "x        x"
	db "x        x"
	db "x     x  x"
	db "x     x  x"
	db "x     x  x"
	db "x     x  x"
	db "xxxxxxxxxx"
L1e:
L1SIZE EQU L1e - L1
	CheckSize L1, L1SIZE, 10, 10


LevelDataEnd::
