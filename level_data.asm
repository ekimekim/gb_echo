

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
	db 13, 15, 3, 13
	db "xxxxxxxxxxxxx"
	db "x      x  * x"
	db "x      x    x"
	db "x      x    x"
	db "x      x    x"
	db "x      x    x"
	db "xxxxxxxx    x"
	db "x           x"
	db "x           x"
	db "x     xxxxxxx"
	db "x     x     x"
	db "x     x     x"
	db "x     x     x"
	db "x     x     x"
	db "xxxxxxxxxxxxx"
L1e:
L1SIZE EQU L1e - L1
	CheckSize L1, L1SIZE, 13, 15


L2:
	db 11, 13, 1, 1
	db "xxxxxxxxxxx"
	db "x x       x"
	db "x x       x"
	db "x x       x"
	db "x x       x"
	db "x xxxxxxxxx"
	db "x         x"
	db "x         x"
	db "x         x"
	db "x   xxx   x"
	db "x   x*x   x"
	db "x         x"
	db "xxxxxxxxxxx"
L2e:
L2SIZE EQU L2e - L2
	CheckSize L2, L2SIZE, 11, 13


L3:
	db 15, 18, 12, 13
	db "xxxxxxxxxxxxxxx"
	db "x     x*      x"
	db "x     xxxxxxx x"
	db "x     x       x"
	db "x             x"
	db "x     x       x"
	db "xxxxxxx       x"
	db "x     x       x"
	db "x             x"
	db "x     x       x"
	db "x     xxxxxxxxx"
	db "x     x       x"
	db "x     x       x"
	db "xxxxx x       x"
	db "x   x         x"
	db "x   x x       x"
	db "x     x       x"
	db "xxxxxxxxxxxxxxx"
L3e:
L3SIZE EQU L3e - L3
	CheckSize L3, L3SIZE, 15, 18


L4:
	db 31, 31, 1, 1
	db "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	db "x           x     x     x     x"
	db "x           x     x     x     x"
	db "x  x  xxxx  x  x  x  xxxx  x  x"
	db "x  x  x     x  x           x  x"
	db "x  x  x     x  x           x  x"
	db "x  x  xxxxxxx  xxxx  xxxxxxxxxx"
	db "x  x        x  x     x        x"
	db "x  x        x  x     x        x"
	db "x  xxxxxxx  x  x  xxxx  xxxx  x"
	db "x  x     x  x  x        x     x"
	db "x  x     x  x  x        x     x"
	db "x  x  x  x  x  xxxxxxxxxx  xxxx"
	db "x     x  x     x     x     x  x"
	db "x     x  x     x     x     x  x"
	db "xxxxxxx  xxxxxxx  xxxx  xxxx  x"
	db "x  x     x  x           x     x"
	db "x  x     x  x           x     x"
	db "x  x  xxxx  x  xxxxxxxxxxxxx  x"
	db "x  x     x  x  x              x"
	db "x  x     x  x  x              x"
	db "x  xxxx  x  x  x  xxxxxxxxxx  x"
	db "x           x     x     x     x"
	db "x           x     x     x     x"
	db "xxxx  xxxxxxxxxxxxx  x  xxxx  x"
	db "x     x        x     x  x     x"
	db "x     x        x     x  x     x"
	db "x  xxxx  xxxx  x  xxxx  x  x  x"
	db "x        x     x     x     x  x"
	db "x        x     x     x     x *x"
	db "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
L4e:
L4SIZE EQU L4e - L4
	CheckSize L4, L4SIZE, 31, 31


L5:
	db 41, 56, 20, 54
	db "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x               xxxxxxxxx               x"
	db "x               xx     xx               x"
	db "x               x  x x  x               x"
	db "x               x x* *x x               x"
	db "x               x  x*x  x               x"
	db "x               xx xxx xx               x"
	db "x                x     x                x"
	db "x            xxx         xxx            x"
	db "x            xxx         xxx            x"
	db "x            xxx         xxx            x"
	db "x                                       x"
	db "x            xxx         xxx            x"
	db "x            xxx         xxx            x"
	db "x            xxx         xxx            x"
	db "x                                       x"
	db "x            xxx         xxx            x"
	db "x            xxx         xxx            x"
	db "x            xxx         xxx            x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x          xxx             xxx          x"
	db "x          xxx             xxx          x"
	db "x          xxx             xxx          x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x        xxx                 xxx        x"
	db "x        xxx                 xxx        x"
	db "x        xxx                 xxx        x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x      xxx                     xxx      x"
	db "x      xxx                     xxx      x"
	db "x      xxx                     xxx      x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x    xxx                         xxx    x"
	db "x    xxx                         xxx    x"
	db "x    xxx                         xxx    x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "x                                       x"
	db "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
L5e:
L5SIZE EQU L5e - L5
	CheckSize L5, L5SIZE, 41, 56


LevelDataEnd::
