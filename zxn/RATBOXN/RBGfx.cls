' RBGfx - RATBOXN's graphics: made by tools/rbgfx.py (don't edit: run it again). The tiles 0-26
' (8 x 8, 4 bits) and the font as tiles 32-127, the 8 sprite patterns (16 x 16, 4 bits), the
' tilemap's and the sprites' palettes.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit

Public Const T_FLOOR = 0
Public Const T_FLOOR2 = 1
Public Const T_WALLH = 2
Public Const T_WALLV = 3
Public Const T_CORNER = 4
Public Const T_BED0 = 5
Public Const T_BED1 = 6
Public Const T_BED2 = 7
Public Const T_BED3 = 8
Public Const T_BOWL0 = 9
Public Const T_BOWL1 = 10
Public Const T_WHEEL0 = 11
Public Const T_WHEEL1 = 12
Public Const T_WHEEL2 = 13
Public Const T_WHEEL3 = 14
Public Const T_TVOFF0 = 15
Public Const T_TVOFF1 = 16
Public Const T_TVON0 = 17
Public Const T_TVON1 = 18
Public Const T_NAUGHTY0 = 19
Public Const T_NAUGHTY1 = 20
Public Const T_ROPE = 21
Public Const T_POST = 22
Public Const T_GRAVE = 23
Public Const T_FENCE = 24
Public Const T_POO = 25
Public Const T_BLACK = 26
Public Const P_WALK = 0, P_BABY = 2, P_SLEEP = 4, P_MARK = 5, P_HEART = 6, P_STAR = 7
Public Const PAL_MALE = 0, PAL_FEMALE = 1, PAL_BABY = 2, PAL_OLD = 3, PAL_FIGHT = 4, PAL_ILL = 5, PAL_MARK = 6, PAL_HEART = 7

' Load: bank 5's first page put in MMU slot 6 (#C000) for a moment - the program's own page back
' after (it holds its arrays) -, the tiles to #CC00: ours, then the font (CyborgOS-Next's
' console's: its tilemap's tiles 32-127 at bank 5 + #2C00, a bit a pixel) as tiles 32-127,
' white on black -, the patterns to the sprite RAM, both palettes (the tilemap's first, the
' sprites' first)
Public Sub Load()
#asm
            ld (rg_sp), sp
            ld sp, (ntc_csp)
            ld bc, #243B            ; slot 6: its page now noted, bank 5's first in
            ld a, #56
            out (c), a
            inc b
            in a, (c)
            ld (rg_s6), a
            ld a, 10
            out (c), a
            ld hl, rg_tiles
            ld de, #CC00
            ld bc, 864
            ldir
            ld bc, #243B            ; the font: CyborgOS's console's (its tilemap's tiles, a bit a
            ld a, #57               ; pixel, bank 5 + #2C00: the second page, put in slot 7 for
            out (c), a              ; this - the program's own page back after)
            inc b
            ld a, 11
            out (c), a
            ld de, #CC00 + 32 * 32  ; a bit a pixel -> 4 bits (1 white, 0 black)
            ld hl, #E000 + #0C00 + 32 * 8
            ld bc, 96 * 8
rg_fr:
            push bc
            ld c, (hl)
            ld b, 4
rg_fp:
            xor a
            rl c
            jr nc, rg_f0
            or #10
rg_f0:
            rl c
            jr nc, rg_f1
            or #01
rg_f1:
            ld (de), a
            inc de
            djnz rg_fp
            inc hl
            pop bc
            dec bc
            ld a, b
            or c
            jr nz, rg_fr
            ld bc, #243B            ; slot 7: the program's own page back
            ld a, #57
            out (c), a
            inc b
            ld a, (ls_h7)
            out (c), a
            ld bc, #303B            ; the patterns: from pattern slot 0
            xor a
            out (c), a
            ld hl, rg_pats
            ld de, 1024
rg_pp:
            ld a, (hl)
            out (#5B), a
            inc hl
            dec de
            ld a, d
            or e
            jr nz, rg_pp
            ld bc, #243B            ; the palettes
            ld a, #43
            out (c), a
            inc b
            ld a, #30               ; the tilemap's first
            out (c), a
            dec b
            ld hl, rg_tpal
            ld e, 16
            call rg_pal
            ld a, #43
            out (c), a
            inc b
            ld a, #20               ; the sprites' first
            out (c), a
            dec b
            ld hl, rg_spal
            ld e, 128
            call rg_pal
            ld a, #56               ; slot 6: the program's own page back
            out (c), a
            inc b
            ld a, (rg_s6)
            out (c), a
            ld sp, (rg_sp)
            jp rg_end
rg_sp:      dw 0
rg_s6:      db 0
rg_pal:                             ; (on the real stack: CyborgOS's tasks run their asm on the
            ld a, #40               ; thread, so this is jumped round - see below)
            out (c), a
            inc b
            xor a
            out (c), a
            dec b
            ld a, #41
            out (c), a
            inc b
rg_pl:
            ld a, (hl)
            out (c), a
            inc hl
            dec e
            jr nz, rg_pl
            dec b
            ret
rg_tpal:    db #00, #FF, #FC, #D5, #B1, #88, #44, #C4, #34, #2F, #92, #DB, #F2, #F8, #25, #E3
rg_spal:    db #00, #24, #AD, #88, #F2, #00, #FF, #00, #00, #00, #00, #00, #00, #00, #00, #E3
            db #00, #49, #FF, #B6, #F2, #00, #FF, #00, #00, #00, #00, #00, #00, #00, #00, #E3
            db #00, #69, #FA, #F6, #F2, #00, #FF, #00, #00, #00, #00, #00, #00, #00, #00, #E3
            db #00, #25, #92, #6D, #F2, #00, #FF, #00, #00, #00, #00, #00, #00, #00, #00, #E3
            db #00, #40, #E8, #A4, #F2, #00, #FF, #00, #00, #00, #00, #00, #00, #00, #00, #E3
            db #00, #08, #79, #50, #F2, #00, #FF, #00, #00, #00, #00, #00, #00, #00, #00, #E3
            db #00, #68, #FC, #F4, #F2, #00, #FF, #00, #00, #00, #00, #00, #00, #00, #00, #E3
            db #00, #60, #E5, #C1, #F2, #00, #FF, #00, #00, #00, #00, #00, #00, #00, #00, #E3
rg_tiles:   db #33, #33, #33, #43, #33, #33, #33, #33, #34, #33, #33, #34, #33, #33, #33, #33
            db #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #34, #43, #34
            db #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #34, #43, #33, #33, #33
            db #33, #33, #33, #34, #33, #43, #33, #34, #43, #33, #33, #33, #33, #33, #43, #33
            db #66, #66, #66, #66, #55, #65, #55, #55, #55, #55, #55, #55, #66, #66, #66, #66
            db #55, #55, #55, #55, #55, #55, #55, #65, #55, #55, #55, #55, #66, #66, #66, #66
            db #65, #56, #55, #56, #65, #56, #55, #56, #65, #56, #55, #56, #65, #56, #55, #56
            db #65, #56, #55, #56, #65, #56, #55, #56, #65, #56, #55, #56, #65, #56, #55, #56
            db #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66
            db #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66, #66
            db #43, #33, #33, #33, #33, #33, #33, #43, #34, #33, #33, #33, #33, #33, #33, #35
            db #33, #45, #55, #DD, #33, #5D, #DD, #D5, #35, #DD, #5D, #DD, #35, #DD, #DD, #DD
            db #33, #34, #33, #33, #33, #33, #33, #33, #33, #33, #43, #33, #53, #33, #33, #33
            db #DD, #55, #54, #33, #DD, #DD, #D5, #33, #DD, #DD, #DD, #53, #DD, #5D, #DD, #53
            db #55, #DD, #DD, #DD, #55, #DD, #DD, #DD, #35, #DD, #DD, #5D, #45, #5D, #DD, #DD
            db #33, #55, #5D, #DD, #34, #35, #55, #55, #33, #33, #33, #35, #33, #43, #33, #33
            db #DD, #DD, #DD, #55, #D5, #DD, #DD, #55, #DD, #D5, #DD, #53, #DD, #DD, #D5, #53
            db #DD, #D5, #55, #33, #55, #55, #53, #33, #53, #33, #33, #33, #33, #33, #34, #33
            db #43, #33, #33, #33, #33, #33, #3D, #D5, #34, #DD, #5D, #DD, #3D, #DD, #DD, #5D
            db #3B, #BB, #BB, #BB, #33, #AA, #AA, #AA, #33, #3E, #EE, #EE, #33, #33, #EE, #EE
            db #33, #34, #33, #33, #DD, #D3, #33, #33, #DD, #5D, #DD, #33, #D5, #DD, #DD, #D3
            db #BB, #BB, #BB, #B3, #AA, #AA, #AA, #33, #EE, #EE, #E3, #43, #EE, #EE, #33, #33
            db #43, #33, #3B, #BB, #33, #33, #BB, #BB, #34, #3B, #B3, #33, #33, #BB, #A3, #33
            db #3B, #B3, #3A, #33, #3B, #B3, #33, #A3, #3B, #B3, #33, #3A, #3B, #BA, #AA, #AA
            db #BB, #B4, #33, #33, #BB, #BB, #33, #33, #A3, #3B, #B3, #33, #A3, #3A, #BB, #33
            db #A3, #A3, #3B, #B3, #AA, #33, #3B, #B3, #A3, #33, #3B, #B3, #AA, #AA, #AA, #B3
            db #3B, #B3, #33, #A3, #3B, #B3, #3A, #33, #33, #BB, #A3, #33, #43, #3B, #B3, #33
            db #33, #33, #BB, #BB, #34, #33, #36, #66, #33, #33, #36, #66, #33, #43, #36, #66
            db #AA, #33, #3B, #B4, #A3, #A3, #3B, #B3, #A3, #3A, #BB, #33, #A3, #3B, #B3, #33
            db #AB, #BB, #33, #33, #66, #63, #43, #33, #66, #63, #33, #33, #66, #63, #34, #33
            db #4A, #AA, #AA, #AA, #3A, #EE, #EE, #EE, #3A, #EE, #EE, #EE, #3A, #EE, #EE, #EE
            db #3A, #EE, #EE, #EE, #3A, #EE, #EE, #EE, #3A, #AA, #AA, #AA, #33, #33, #36, #33
            db #AA, #AA, #AA, #A3, #EE, #EE, #EE, #A3, #EE, #EE, #EE, #A3, #EE, #EE, #EE, #A3
            db #EE, #EE, #EE, #A3, #EE, #EE, #EE, #A3, #AA, #AA, #AA, #A3, #34, #63, #33, #33
            db #4A, #AA, #AA, #AA, #3A, #99, #99, #99, #3A, #99, #11, #99, #3A, #99, #99, #99
            db #3A, #99, #99, #19, #3A, #99, #99, #99, #3A, #AA, #AA, #AA, #33, #33, #36, #33
            db #AA, #AA, #AA, #A3, #99, #99, #99, #A3, #99, #91, #99, #A3, #91, #99, #99, #A3
            db #99, #19, #99, #A3, #99, #99, #99, #A3, #AA, #AA, #AA, #A3, #34, #63, #33, #33
            db #43, #33, #33, #33, #3C, #CC, #CC, #CC, #37, #77, #77, #77, #37, #77, #67, #77
            db #37, #77, #77, #77, #37, #77, #77, #77, #36, #66, #66, #66, #33, #33, #33, #33
            db #33, #34, #33, #33, #CC, #CC, #CC, #C3, #77, #77, #77, #73, #77, #76, #77, #73
            db #77, #77, #77, #73, #77, #77, #77, #73, #66, #66, #66, #63, #34, #33, #33, #33
            db #33, #33, #33, #33, #33, #34, #33, #33, #33, #44, #33, #33, #77, #11, #77, #11
            db #77, #11, #77, #11, #33, #33, #33, #33, #33, #43, #33, #33, #33, #33, #33, #33
            db #33, #33, #33, #33, #33, #77, #77, #33, #33, #66, #66, #33, #33, #66, #66, #33
            db #34, #66, #66, #33, #33, #66, #66, #33, #34, #66, #66, #33, #33, #66, #66, #43
            db #33, #43, #33, #33, #33, #AA, #AA, #33, #33, #AB, #BA, #33, #43, #BB, #BB, #33
            db #33, #AB, #BA, #33, #33, #AA, #AA, #33, #33, #AA, #AA, #33, #36, #66, #66, #63
            db #36, #33, #46, #33, #36, #33, #36, #33, #56, #55, #56, #55, #36, #34, #36, #33
            db #36, #33, #36, #33, #56, #55, #56, #55, #36, #34, #46, #33, #46, #33, #46, #33
            db #33, #33, #33, #33, #43, #33, #33, #33, #33, #33, #43, #33, #33, #33, #63, #43
            db #33, #36, #63, #33, #33, #66, #66, #43, #33, #33, #43, #33, #33, #33, #33, #33
            db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00
            db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00
rg_pats:    db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #11, #FF, #FF, #FF, #FF, #FF, #FF, #F1, #44, #1F, #FF
            db #FF, #F1, #11, #11, #14, #44, #11, #FF, #FF, #12, #22, #22, #24, #44, #22, #1F
            db #F1, #22, #22, #22, #22, #22, #52, #21, #12, #22, #22, #22, #22, #22, #22, #24
            db #42, #22, #22, #22, #22, #22, #22, #21, #43, #33, #33, #33, #33, #22, #21, #1F
            db #41, #33, #33, #33, #33, #31, #1F, #FF, #F4, #11, #41, #11, #14, #1F, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #11, #FF, #FF, #FF, #FF, #FF, #FF, #F1, #44, #1F, #FF
            db #FF, #F1, #11, #11, #14, #44, #11, #FF, #FF, #12, #22, #22, #24, #44, #22, #1F
            db #F1, #22, #22, #22, #22, #22, #52, #21, #12, #22, #22, #22, #22, #22, #22, #24
            db #42, #22, #22, #22, #22, #22, #22, #21, #43, #33, #33, #33, #33, #22, #21, #1F
            db #41, #33, #33, #33, #33, #31, #1F, #FF, #F4, #11, #14, #11, #11, #4F, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #F1, #1F, #FF, #FF
            db #FF, #FF, #F1, #11, #14, #41, #FF, #FF, #FF, #FF, #12, #22, #22, #25, #1F, #FF
            db #FF, #F1, #22, #22, #22, #22, #41, #FF, #FF, #F4, #33, #33, #33, #22, #1F, #FF
            db #FF, #F4, #41, #43, #34, #11, #FF, #FF, #FF, #FF, #FF, #11, #11, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #F1, #1F, #FF, #FF
            db #FF, #FF, #F1, #11, #14, #41, #FF, #FF, #FF, #FF, #12, #22, #22, #25, #1F, #FF
            db #FF, #F1, #22, #22, #22, #22, #41, #FF, #FF, #F4, #33, #33, #33, #22, #1F, #FF
            db #FF, #F4, #41, #43, #34, #11, #FF, #FF, #FF, #FF, #FF, #11, #11, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #66, #6F, #FF, #FF, #FF, #FF, #FF, #FF, #F6, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #66, #6F, #FF, #FF, #F1, #11, #11, #1F, #FF, #FF
            db #FF, #F1, #12, #22, #22, #21, #1F, #FF, #FF, #12, #22, #22, #22, #24, #41, #FF
            db #F1, #22, #22, #22, #22, #44, #42, #1F, #F1, #22, #22, #22, #22, #24, #45, #1F
            db #F1, #22, #22, #22, #22, #22, #22, #1F, #F1, #22, #22, #22, #22, #22, #22, #1F
            db #F1, #33, #33, #33, #33, #33, #33, #1F, #FF, #13, #33, #33, #33, #33, #31, #FF
            db #FF, #F1, #43, #33, #33, #34, #1F, #FF, #FF, #FF, #F1, #41, #14, #1F, #FF, #FF
            db #FF, #FF, #F1, #22, #22, #1F, #FF, #FF, #FF, #FF, #F1, #22, #22, #1F, #FF, #FF
            db #FF, #FF, #F1, #22, #22, #1F, #FF, #FF, #FF, #FF, #11, #22, #22, #11, #FF, #FF
            db #FF, #F1, #22, #22, #22, #22, #1F, #FF, #FF, #FF, #12, #22, #22, #21, #FF, #FF
            db #FF, #FF, #F1, #22, #22, #1F, #FF, #FF, #FF, #FF, #FF, #12, #21, #FF, #FF, #FF
            db #FF, #FF, #FF, #F1, #1F, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #F1, #11, #1F, #F1, #11, #1F, #FF
            db #FF, #12, #22, #21, #12, #22, #21, #FF, #F1, #22, #22, #22, #22, #22, #22, #1F
            db #F1, #22, #22, #22, #22, #22, #22, #1F, #12, #22, #22, #22, #22, #22, #22, #21
            db #F1, #22, #22, #22, #22, #22, #22, #1F, #F1, #22, #22, #22, #22, #22, #22, #1F
            db #FF, #12, #22, #22, #22, #22, #21, #FF, #FF, #F1, #22, #22, #22, #22, #1F, #FF
            db #FF, #FF, #12, #22, #22, #21, #FF, #FF, #FF, #FF, #F1, #22, #22, #1F, #FF, #FF
            db #FF, #FF, #FF, #12, #21, #FF, #FF, #FF, #FF, #FF, #FF, #12, #21, #FF, #FF, #FF
            db #FF, #FF, #FF, #F1, #1F, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #F1, #1F, #FF, #FF, #FF
            db #FF, #FF, #FF, #12, #21, #FF, #FF, #FF, #FF, #FF, #FF, #12, #21, #FF, #FF, #FF
            db #FF, #FF, #FF, #12, #21, #FF, #FF, #FF, #FF, #11, #11, #22, #22, #11, #11, #FF
            db #F1, #22, #22, #22, #22, #22, #22, #1F, #FF, #12, #22, #22, #22, #22, #21, #FF
            db #FF, #F1, #12, #22, #22, #21, #1F, #FF, #FF, #FF, #12, #22, #22, #21, #FF, #FF
            db #FF, #FF, #12, #22, #22, #21, #FF, #FF, #FF, #F1, #22, #21, #12, #22, #1F, #FF
            db #FF, #F1, #22, #1F, #F1, #22, #1F, #FF, #FF, #FF, #11, #FF, #FF, #11, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
rg_end:
#endasm
End Sub
