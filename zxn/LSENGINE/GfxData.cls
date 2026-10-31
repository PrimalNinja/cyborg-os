' (taskify.py: task lines in IFNDEF NTC_ZXN)
' GfxData - the game's graphics, made by gfxtool.js from gfx/*.png and layout.txt.
' Don't edit: change the PNGs and run  node gfxtool.js build
' Load: the tilemap palette, the sprite palettes, the tile definitions (bank 5 + #0000, seen at
' #C000: Tiles.Init points the tilemap there) and the sprite patterns (4 bit, from pattern 0).
Option Explicit

Public Const S_POSTIE = 0
Public Const S_POSTIE_N = 9
Public Const S_MAN = 9
Public Const S_MAN_N = 9
Public Const S_WOMAN = 18
Public Const S_WOMAN_N = 9
Public Const S_AJUMMA = 27
Public Const S_AJUMMA_N = 9
Public Const S_GRANDAD = 36
Public Const S_GRANDAD_N = 9
Public Const S_CAR = 45
Public Const S_CAR_N = 2
Public Const S_CAR_W = 2
Public Const S_BUS = 49
Public Const S_BUS_N = 1
Public Const S_BUS_W = 3
Public Const S_SCOOTER = 52
Public Const S_SCOOTER_N = 1
Public Const S_ICON = 53
Public Const S_ICON_N = 16
Public Const S_ICON2 = 69
Public Const S_ICON2_N = 2
Public Const T_BOX = 1
Public Const T_BOX2 = 2
Public Const T_FTL = 3
Public Const T_FT = 4
Public Const T_FTR = 5
Public Const T_FL = 6
Public Const T_FR = 7
Public Const T_FBL = 8
Public Const T_FB = 9
Public Const T_FBR = 10
Public Const T_HEART = 11
Public Const T_STAR = 12
Public Const T_BLACK = 13
Public Const T_FAN = 14
Public Const T_COIN = 15
Public Const T_BARP = 96
Public Const T_BARP_N = 9
Public Const T_BARM = 105
Public Const T_BARM_N = 9
Public Const SpritePatterns = 71
Public Const SpritePalettes = 16

Private sps As Integer

Public Sub Load()
#asm
    IFDEF NTC_ZXN
            ld ({sps}), sp          ; the real stack (calls)
            ld sp, (ntc_csp)
            ld bc, #243B
            ld a, #43               ; palette control: the tilemap's first palette
            out (c), a
            inc b
            ld a, #30
            out (c), a
            dec b
            ld hl, tpal
            ld e, 16
            call palset
            ld a, #43               ; the sprites' first palette
            out (c), a
            inc b
            ld a, #20
            out (c), a
            dec b
            ld hl, spal
            ld e, 0                ; 16 x 16 (0 = 256)
            call palset
            ld a, #43               ; back to the ULA's, first palettes in use
            out (c), a
            inc b
            xor a
            out (c), a
            ld bc, #303B            ; sprite patterns from pattern 0
            xor a
            out (c), a
            ld hl, #C000            ; 64 from bank 5 (#C000)
            ld de, 8192
            call ld_po
            ld hl, #F400            ; 7 from bank 5 (#F400)
            ld de, 896
            call ld_po
            ld bc, #243B            ; the rest from bank 47 (its first page at #E000)
            ld a, #57
            out (c), a
            inc b
            ld a, 94
            out (c), a
            ld hl, #E000
            ld de, 0
            call ld_po
            ld bc, #243B
            ld a, #57               ; the tiles: its second page at #E000
            out (c), a
            inc b
            ld a, 95
            out (c), a
            dec b
            ld hl, #C000            ; every tile transparent (colour 15) first
            ld de, #C001
            ld bc, #1FFF
            ld (hl), #FF
            ldir
            ld hl, #E000
ld_run:
            ld a, (hl)              ; a run: first tile, count (0, 0 = the end), its definitions
            inc hl
            ld c, (hl)
            inc hl
            ld b, a
            or c
            jr z, ld_spr
            ld a, b
            ld e, a                 ; DE = #C000 + first * 32
            ld d, 0
            ex de, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld a, h
            add a, #C0
            ld h, a
            ex de, hl
            ld a, c                 ; BC = count * 32 (count 1 - 255: tile 0 run of 0 not used)
            ld b, 0
            ld c, a
            push hl
            ld h, b
            ld l, c
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld b, h
            ld c, l
            pop hl
            ldir
            jr ld_run
ld_spr:
            jr ld_done
            ld bc, #303B            ; sprite patterns from pattern 0
            xor a
            out (c), a
            ld hl, pats
            ld de, 9088
            ld c, #5B
ld_pat:
            ld a, d
            or e
            jr z, ld_done
            ld a, (hl)
            out (c), a
            inc hl
            dec de
            jr ld_pat
ld_done:
            ld bc, #243B            ; bank 5 back at #E000
            ld a, #57
            out (c), a
            inc b
            ld a, 11
            out (c), a
            ld sp, ({sps})
            jp ld_end
; ld_po - DE bytes from HL to the sprite patterns
ld_po:
            ld c, #5B
ld_pol:
            ld a, d
            or e
            ret z
            ld a, (hl)
            out (c), a
            inc hl
            dec de
            jr ld_pol
; palset - E colours (0 = 256) from HL into the palette chosen, from index 0 (BC = #243B)
palset:
            ld a, #40
            out (c), a
            inc b
            xor a
            out (c), a
            dec b
ps_lp:
            ld a, #41
            out (c), a
            inc b
            ld a, (hl)
            out (c), a
            dec b
            inc hl
            dec e
            jr nz, ps_lp
            ret
tpal:
            db #00, #FF, #F7, #EA, #86, #41, #D7, #21, #F8, #7E, #77, #B6, #49, #E5, #61, #E3
spal:
            db #00, #FF, #F6, #D2, #44, #20, #E4, #A0, #02, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #0B, #06, #25, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #68, #44, #FF, #B6, #26, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #AD, #68, #EF, #CA, #DB, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #25, #00, #25, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #44, #20, #99, #51, #B2, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #D6, #8D, #D4, #AC, #4B, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #A7, #62, #A3, #62, #25, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #B6, #6E, #92, #6D, #44, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #17, #0E, #DB, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #F4, #AC, #2B, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #26, #01, #25, #25, #FF, #B6, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #FF, #B6, #25, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #FF, #B6, #25, #25, #F8, #B0, #57, #F0, #A8, #E3
            db #00, #FF, #F6, #D2, #25, #00, #FF, #B6, #25, #25, #F8, #B0, #57, #0B, #06, #E3
            db #00, #FF, #E0, #EF, #FC, #88, #14, #0F, #F0, #B6, #D6, #6D, #57, #A3, #26, #E3
ld_end:
            MMU 6 7, 10             ; bank 5 (in the NEX file): the first patterns
            ORG #C000
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #0F, #FF, #FF, #F0, #2B, #BB, #BB, #B0, #FF, #FF
            db #FF, #F0, #22, #02, #20, #20, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #7A, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #A6, #66, #67, #0F, #FF
            db #FF, #F0, #76, #6A, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #AA, #AA, #A0, #FF
            db #FF, #F0, #76, #66, #6A, #AA, #A0, #FF, #FF, #F0, #26, #66, #6A, #AA, #A0, #FF
            db #FF, #FF, #08, #80, #0B, #BB, #B0, #FF, #FF, #FF, #08, #80, #08, #80, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #0F, #FF, #FF, #F0, #2B, #BB, #BB, #B0, #FF, #FF
            db #FF, #F0, #22, #02, #20, #20, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #7A, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #A6, #66, #67, #0F, #FF
            db #FF, #F0, #76, #6A, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #AA, #AA, #A0, #FF
            db #FF, #F0, #76, #66, #6A, #AA, #A0, #FF, #FF, #F0, #26, #66, #6A, #AA, #A0, #FF
            db #FF, #FF, #08, #80, #0B, #BB, #B0, #FF, #FF, #FF, #08, #80, #08, #80, #0F, #FF
            db #FF, #FF, #09, #90, #08, #80, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #0F, #FF, #FF, #F0, #2B, #BB, #BB, #B0, #FF, #FF
            db #FF, #F0, #22, #02, #20, #20, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #7A, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #A6, #66, #67, #0F, #FF
            db #FF, #F0, #76, #6A, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #AA, #AA, #A0, #FF
            db #FF, #F0, #76, #66, #6A, #AA, #A0, #FF, #FF, #F0, #26, #66, #6A, #AA, #A0, #FF
            db #FF, #FF, #08, #80, #0B, #BB, #B0, #FF, #FF, #FF, #08, #80, #08, #80, #0F, #FF
            db #FF, #FF, #08, #80, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #A7, #0F, #FF, #FF, #F0, #76, #66, #6A, #67, #0F, #FF
            db #FF, #F0, #76, #66, #A6, #67, #0F, #FF, #FF, #0A, #AA, #AA, #66, #67, #0F, #FF
            db #FF, #0A, #AA, #A6, #66, #67, #0F, #FF, #FF, #0A, #AA, #A6, #66, #62, #0F, #FF
            db #FF, #0B, #BB, #B0, #08, #80, #FF, #FF, #FF, #F0, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #A7, #0F, #FF, #FF, #F0, #76, #66, #6A, #67, #0F, #FF
            db #FF, #F0, #76, #66, #A6, #67, #0F, #FF, #FF, #0A, #AA, #AA, #66, #67, #0F, #FF
            db #FF, #0A, #AA, #A6, #66, #67, #0F, #FF, #FF, #0A, #AA, #A6, #66, #62, #0F, #FF
            db #FF, #0B, #BB, #B0, #08, #80, #FF, #FF, #FF, #F0, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #09, #90, #08, #80, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #A7, #0F, #FF, #FF, #F0, #76, #66, #6A, #67, #0F, #FF
            db #FF, #F0, #76, #66, #A6, #67, #0F, #FF, #FF, #0A, #AA, #AA, #66, #67, #0F, #FF
            db #FF, #0A, #AA, #A6, #66, #67, #0F, #FF, #FF, #0A, #AA, #A6, #66, #62, #0F, #FF
            db #FF, #0B, #BB, #B0, #08, #80, #FF, #FF, #FF, #F0, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #00, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #BB, #0F, #FF, #F0, #22, #22, #22, #20, #00, #FF
            db #FF, #F0, #22, #22, #22, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #F0, #07, #A7, #76, #60, #FF, #FF
            db #FF, #0A, #AA, #A7, #76, #60, #FF, #FF, #FF, #0A, #AA, #A7, #76, #60, #FF, #FF
            db #FF, #0A, #AA, #A7, #76, #60, #FF, #FF, #FF, #0B, #BB, #B2, #66, #60, #FF, #FF
            db #FF, #F0, #00, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #88, #88, #0F, #FF, #FF
            db #FF, #FF, #F0, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #99, #99, #90, #FF, #FF
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #00, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #BB, #0F, #FF, #F0, #22, #22, #22, #20, #00, #FF
            db #FF, #F0, #22, #22, #22, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #F0, #07, #A6, #77, #60, #FF, #FF
            db #FF, #0A, #AA, #A6, #77, #60, #FF, #FF, #FF, #0A, #AA, #A6, #77, #60, #FF, #FF
            db #FF, #0A, #AA, #A6, #77, #60, #FF, #FF, #FF, #0B, #BB, #B6, #26, #60, #FF, #FF
            db #FF, #F0, #00, #08, #80, #0F, #FF, #FF, #FF, #FF, #FF, #08, #80, #FF, #FF, #FF
            db #FF, #FF, #FF, #08, #80, #FF, #FF, #FF, #FF, #FF, #FF, #09, #99, #0F, #FF, #FF
            db #FF, #F0, #AA, #AA, #AA, #AA, #0F, #FF, #FF, #F0, #AA, #AA, #AA, #AA, #00, #FF
            db #FF, #F0, #BB, #BB, #BB, #BB, #BB, #0F, #FF, #F0, #22, #22, #22, #20, #00, #FF
            db #FF, #F0, #22, #22, #22, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #F0, #07, #A7, #66, #60, #FF, #FF
            db #FF, #0A, #AA, #A7, #66, #60, #FF, #FF, #FF, #0A, #AA, #A7, #66, #60, #FF, #FF
            db #FF, #0A, #AA, #A7, #66, #60, #FF, #FF, #FF, #0B, #BB, #B6, #66, #60, #FF, #FF
            db #FF, #F0, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #99, #09, #99, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #42, #22, #22, #24, #0F, #FF, #FF, #F0, #22, #22, #22, #20, #FF, #FF
            db #FF, #F0, #22, #02, #20, #20, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #42, #22, #22, #24, #0F, #FF, #FF, #F0, #22, #22, #22, #20, #FF, #FF
            db #FF, #F0, #22, #02, #20, #20, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #09, #90, #08, #80, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #42, #22, #22, #24, #0F, #FF, #FF, #F0, #22, #22, #22, #20, #FF, #FF
            db #FF, #F0, #22, #02, #20, #20, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #09, #90, #08, #80, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #24, #0F, #FF, #FF, #F0, #44, #44, #44, #20, #FF, #FF
            db #FF, #F0, #22, #22, #22, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #77, #76, #60, #FF, #FF
            db #FF, #FF, #07, #77, #76, #60, #FF, #FF, #FF, #FF, #07, #77, #76, #60, #FF, #FF
            db #FF, #FF, #07, #77, #76, #60, #FF, #FF, #FF, #FF, #07, #72, #66, #60, #FF, #FF
            db #FF, #FF, #F0, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #88, #88, #0F, #FF, #FF
            db #FF, #FF, #F0, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #99, #99, #90, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #24, #0F, #FF, #FF, #F0, #44, #44, #44, #20, #FF, #FF
            db #FF, #F0, #22, #22, #22, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #76, #77, #60, #FF, #FF
            db #FF, #FF, #07, #76, #77, #60, #FF, #FF, #FF, #FF, #07, #76, #77, #60, #FF, #FF
            db #FF, #FF, #07, #76, #77, #60, #FF, #FF, #FF, #FF, #07, #76, #26, #60, #FF, #FF
            db #FF, #FF, #F0, #08, #80, #0F, #FF, #FF, #FF, #FF, #FF, #08, #80, #FF, #FF, #FF
            db #FF, #FF, #FF, #08, #80, #FF, #FF, #FF, #FF, #FF, #FF, #09, #99, #0F, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #24, #0F, #FF, #FF, #F0, #44, #44, #44, #20, #FF, #FF
            db #FF, #F0, #22, #22, #22, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #77, #66, #60, #FF, #FF
            db #FF, #FF, #07, #77, #66, #60, #FF, #FF, #FF, #FF, #07, #77, #66, #60, #FF, #FF
            db #FF, #FF, #07, #77, #66, #60, #FF, #FF, #FF, #FF, #07, #26, #66, #60, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #99, #09, #99, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #42, #22, #22, #24, #40, #FF, #FF, #04, #42, #22, #22, #24, #40, #FF
            db #FF, #04, #42, #02, #20, #24, #40, #FF, #FF, #04, #42, #22, #22, #04, #40, #FF
            db #FF, #04, #46, #22, #26, #64, #40, #FF, #FF, #04, #46, #66, #66, #64, #40, #FF
            db #FF, #05, #56, #66, #66, #65, #50, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #F0, #88, #88, #88, #88, #0F, #FF, #FF, #FF, #02, #20, #02, #20, #FF, #FF
            db #FF, #FF, #02, #20, #02, #20, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #42, #22, #22, #24, #40, #FF, #FF, #04, #42, #22, #22, #24, #40, #FF
            db #FF, #04, #42, #02, #20, #24, #40, #FF, #FF, #04, #42, #22, #22, #04, #40, #FF
            db #FF, #04, #46, #22, #26, #64, #40, #FF, #FF, #04, #46, #66, #66, #64, #40, #FF
            db #FF, #05, #56, #66, #66, #65, #50, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #F0, #88, #88, #88, #88, #0F, #FF, #FF, #FF, #02, #20, #02, #20, #FF, #FF
            db #FF, #FF, #09, #90, #02, #20, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #42, #22, #22, #24, #40, #FF, #FF, #04, #42, #22, #22, #24, #40, #FF
            db #FF, #04, #42, #02, #20, #24, #40, #FF, #FF, #04, #42, #22, #22, #04, #40, #FF
            db #FF, #04, #46, #22, #26, #64, #40, #FF, #FF, #04, #46, #66, #66, #64, #40, #FF
            db #FF, #05, #56, #66, #66, #65, #50, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #F0, #88, #88, #88, #88, #0F, #FF, #FF, #FF, #02, #20, #02, #20, #FF, #FF
            db #FF, #FF, #02, #20, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #55, #55, #55, #55, #40, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #F0, #88, #88, #88, #88, #0F, #FF, #FF, #FF, #02, #20, #02, #20, #FF, #FF
            db #FF, #FF, #02, #20, #02, #20, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #55, #55, #55, #55, #40, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #F0, #88, #88, #88, #88, #0F, #FF, #FF, #FF, #02, #20, #02, #20, #FF, #FF
            db #FF, #FF, #09, #90, #02, #20, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #55, #55, #55, #55, #40, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #F0, #88, #88, #88, #88, #0F, #FF, #FF, #FF, #02, #20, #02, #20, #FF, #FF
            db #FF, #FF, #02, #20, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #24, #40, #FF, #FF, #04, #44, #44, #44, #24, #40, #FF
            db #FF, #04, #44, #44, #44, #04, #40, #FF, #FF, #04, #44, #44, #44, #04, #40, #FF
            db #FF, #04, #44, #44, #44, #64, #40, #FF, #FF, #04, #44, #44, #44, #64, #40, #FF
            db #FF, #05, #55, #55, #54, #65, #50, #FF, #FF, #F0, #07, #77, #76, #60, #0F, #FF
            db #FF, #FF, #07, #77, #76, #60, #FF, #FF, #FF, #FF, #07, #72, #66, #60, #FF, #FF
            db #FF, #FF, #08, #88, #88, #80, #FF, #FF, #FF, #FF, #F0, #88, #88, #0F, #FF, #FF
            db #FF, #FF, #F0, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #99, #99, #90, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #24, #40, #FF, #FF, #04, #44, #44, #44, #24, #40, #FF
            db #FF, #04, #44, #44, #44, #04, #40, #FF, #FF, #04, #44, #44, #44, #04, #40, #FF
            db #FF, #04, #44, #44, #44, #64, #40, #FF, #FF, #04, #44, #44, #44, #64, #40, #FF
            db #FF, #05, #55, #55, #54, #65, #50, #FF, #FF, #F0, #07, #76, #77, #60, #0F, #FF
            db #FF, #FF, #07, #76, #77, #60, #FF, #FF, #FF, #FF, #07, #76, #26, #60, #FF, #FF
            db #FF, #FF, #08, #88, #88, #80, #FF, #FF, #FF, #FF, #F0, #08, #80, #0F, #FF, #FF
            db #FF, #FF, #FF, #08, #80, #FF, #FF, #FF, #FF, #FF, #FF, #09, #99, #0F, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #04, #44, #44, #44, #24, #40, #FF, #FF, #04, #44, #44, #44, #24, #40, #FF
            db #FF, #04, #44, #44, #44, #04, #40, #FF, #FF, #04, #44, #44, #44, #04, #40, #FF
            db #FF, #04, #44, #44, #44, #64, #40, #FF, #FF, #04, #44, #44, #44, #64, #40, #FF
            db #FF, #05, #55, #55, #54, #65, #50, #FF, #FF, #F0, #07, #77, #66, #60, #0F, #FF
            db #FF, #FF, #07, #77, #66, #60, #FF, #FF, #FF, #FF, #07, #26, #66, #60, #FF, #FF
            db #FF, #FF, #08, #88, #88, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #99, #09, #99, #0F, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #AA, #AA, #AA, #AA, #A0, #FF, #F0, #44, #42, #22, #22, #44, #40, #FF
            db #FF, #00, #22, #02, #20, #20, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #AA, #AA, #AA, #AA, #A0, #FF, #F0, #44, #42, #22, #22, #44, #40, #FF
            db #FF, #00, #22, #02, #20, #20, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #09, #90, #08, #80, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #AA, #AA, #AA, #AA, #A0, #FF, #F0, #44, #42, #22, #22, #44, #40, #FF
            db #FF, #00, #22, #02, #20, #20, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #44, #44, #44, #44, #40, #FF, #F0, #44, #44, #44, #44, #44, #40, #FF
            db #FF, #00, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #54, #54, #54, #54, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #44, #44, #44, #44, #40, #FF, #F0, #44, #44, #44, #44, #44, #40, #FF
            db #FF, #00, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #54, #54, #54, #54, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #09, #90, #08, #80, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #44, #44, #44, #44, #40, #FF, #F0, #44, #44, #44, #44, #44, #40, #FF
            db #FF, #00, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #54, #54, #54, #54, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #AA, #AA, #AA, #AA, #A0, #FF, #F0, #44, #44, #44, #42, #44, #40, #FF
            db #FF, #00, #44, #44, #42, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #77, #76, #60, #FF, #FF
            db #FF, #FF, #07, #77, #76, #60, #FF, #FF, #FF, #FF, #07, #77, #76, #60, #FF, #FF
            db #FF, #FF, #07, #77, #76, #60, #FF, #FF, #FF, #FF, #07, #72, #66, #60, #FF, #FF
            db #FF, #FF, #F0, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #88, #88, #0F, #FF, #FF
            db #FF, #FF, #F0, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #99, #99, #90, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #AA, #AA, #AA, #AA, #A0, #FF, #F0, #44, #44, #44, #42, #44, #40, #FF
            db #FF, #00, #44, #44, #42, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #76, #77, #60, #FF, #FF
            db #FF, #FF, #07, #76, #77, #60, #FF, #FF, #FF, #FF, #07, #76, #77, #60, #FF, #FF
            db #FF, #FF, #07, #76, #77, #60, #FF, #FF, #FF, #FF, #07, #76, #26, #60, #FF, #FF
            db #FF, #FF, #F0, #08, #80, #0F, #FF, #FF, #FF, #FF, #FF, #08, #80, #FF, #FF, #FF
            db #FF, #FF, #FF, #08, #80, #FF, #FF, #FF, #FF, #FF, #FF, #09, #99, #0F, #FF, #FF
            db #FF, #04, #44, #44, #44, #44, #0F, #FF, #FF, #04, #44, #44, #44, #44, #0F, #FF
            db #F0, #44, #AA, #AA, #AA, #AA, #A0, #FF, #F0, #44, #44, #44, #42, #44, #40, #FF
            db #FF, #00, #44, #44, #42, #02, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #77, #66, #60, #FF, #FF
            db #FF, #FF, #07, #77, #66, #60, #FF, #FF, #FF, #FF, #07, #77, #66, #60, #FF, #FF
            db #FF, #FF, #07, #77, #66, #60, #FF, #FF, #FF, #FF, #07, #26, #66, #60, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #99, #09, #99, #0F, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #42, #22, #22, #24, #0F, #FF, #FF, #F0, #42, #22, #22, #24, #0F, #FF
            db #FF, #F0, #40, #00, #00, #04, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #61, #16, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #42, #22, #22, #24, #0F, #FF, #FF, #F0, #42, #22, #22, #24, #0F, #FF
            db #FF, #F0, #40, #00, #00, #04, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #61, #16, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #09, #90, #08, #80, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #42, #22, #22, #24, #0F, #FF, #FF, #F0, #42, #22, #22, #24, #0F, #FF
            db #FF, #F0, #40, #00, #00, #04, #0F, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #61, #16, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #61, #16, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #90, #09, #90, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #61, #16, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #09, #90, #08, #80, #FF, #FF, #FF, #FF, #F0, #0F, #09, #90, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #F0, #76, #22, #26, #67, #0F, #FF, #FF, #F0, #76, #61, #16, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #76, #66, #66, #67, #0F, #FF
            db #FF, #F0, #76, #66, #66, #67, #0F, #FF, #FF, #F0, #26, #66, #66, #62, #0F, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #09, #90, #FF, #FF, #FF, #FF, #09, #90, #F0, #0F, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #44, #42, #22, #24, #0F, #FF, #FF, #F0, #44, #42, #22, #24, #0F, #FF
            db #FF, #F0, #44, #42, #22, #04, #0F, #FF, #FF, #F0, #44, #42, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #77, #76, #60, #FF, #FF
            db #FF, #FF, #07, #77, #76, #60, #FF, #FF, #FF, #FF, #07, #77, #76, #60, #FF, #FF
            db #FF, #FF, #07, #77, #76, #60, #FF, #FF, #FF, #FF, #07, #72, #66, #60, #FF, #FF
            db #FF, #FF, #F0, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #88, #88, #0F, #FF, #FF
            db #FF, #FF, #F0, #88, #88, #0F, #FF, #FF, #FF, #FF, #F0, #99, #99, #90, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #44, #42, #22, #24, #0F, #FF, #FF, #F0, #44, #42, #22, #24, #0F, #FF
            db #FF, #F0, #44, #42, #22, #04, #0F, #FF, #FF, #F0, #44, #42, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #76, #77, #60, #FF, #FF
            db #FF, #FF, #07, #76, #77, #60, #FF, #FF, #FF, #FF, #07, #76, #77, #60, #FF, #FF
            db #FF, #FF, #07, #76, #77, #60, #FF, #FF, #FF, #FF, #07, #76, #26, #60, #FF, #FF
            db #FF, #FF, #F0, #08, #80, #0F, #FF, #FF, #FF, #FF, #FF, #08, #80, #FF, #FF, #FF
            db #FF, #FF, #FF, #08, #80, #FF, #FF, #FF, #FF, #FF, #FF, #09, #99, #0F, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #02, #22, #22, #00, #FF, #FF
            db #FF, #F0, #44, #42, #22, #24, #0F, #FF, #FF, #F0, #44, #42, #22, #24, #0F, #FF
            db #FF, #F0, #44, #42, #22, #04, #0F, #FF, #FF, #F0, #44, #42, #22, #00, #FF, #FF
            db #FF, #FF, #07, #22, #26, #60, #FF, #FF, #FF, #FF, #07, #77, #66, #60, #FF, #FF
            db #FF, #FF, #07, #77, #66, #60, #FF, #FF, #FF, #FF, #07, #77, #66, #60, #FF, #FF
            db #FF, #FF, #07, #77, #66, #60, #FF, #FF, #FF, #FF, #07, #26, #66, #60, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #08, #80, #08, #80, #FF, #FF
            db #FF, #FF, #08, #80, #08, #80, #FF, #FF, #FF, #FF, #09, #99, #09, #99, #0F, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #00, #00, #00, #00
            db #FF, #FF, #FF, #F0, #DD, #DD, #DD, #DD, #FF, #FF, #FF, #F0, #DD, #CC, #CC, #CC
            db #FF, #FF, #FF, #F0, #DD, #CC, #CC, #CC, #F0, #00, #00, #00, #DD, #CC, #CC, #CC
            db #0D, #DD, #DD, #DD, #DD, #CC, #CC, #CC, #F0, #0D, #DD, #DD, #DD, #DD, #DD, #DD
            db #F0, #0D, #DD, #DD, #DD, #DD, #DD, #DD, #0D, #DD, #DD, #DD, #DD, #DD, #DD, #DD
            db #0D, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #0D, #DD, #DD, #00, #0D, #DD, #DD, #DD
            db #0E, #EE, #E0, #01, #00, #EE, #EE, #EE, #0E, #EE, #E0, #11, #10, #EE, #EE, #EE
            db #F0, #00, #00, #01, #00, #00, #00, #00, #FF, #FF, #FF, #00, #0F, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #00, #00, #00, #0F, #FF, #FF, #FF, #FF
            db #DD, #DD, #DD, #D0, #FF, #FF, #FF, #FF, #DC, #CC, #CC, #D0, #FF, #FF, #FF, #FF
            db #DC, #CC, #CC, #D0, #FF, #FF, #FF, #FF, #DC, #CC, #CC, #D0, #00, #00, #00, #0F
            db #DC, #CC, #CC, #DD, #DD, #DD, #DD, #D0, #DD, #DD, #DD, #DD, #DD, #DD, #11, #10
            db #DD, #DD, #DD, #DD, #DD, #DD, #11, #10, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #D0
            db #DD, #DD, #DD, #DD, #DD, #DD, #DD, #D0, #DD, #DD, #DD, #D0, #00, #DD, #DD, #D0
            db #EE, #EE, #EE, #00, #10, #0E, #EE, #E0, #EE, #EE, #EE, #01, #11, #0E, #EE, #E0
            db #00, #00, #00, #00, #10, #00, #00, #0F, #FF, #FF, #FF, #F0, #00, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #0A, #AA, #FF, #FF, #FF, #FF, #00, #00, #0A, #AA
            db #FF, #FF, #FF, #F0, #DD, #DD, #DD, #DD, #FF, #FF, #FF, #F0, #DD, #CC, #CC, #CC
            db #FF, #FF, #FF, #F0, #DD, #CC, #CC, #CC, #F0, #00, #00, #00, #DD, #CC, #CC, #CC
            db #0D, #DD, #DD, #DD, #DD, #CC, #CC, #CC, #F0, #0D, #DD, #DD, #DD, #DD, #DD, #DD
            db #F0, #0D, #DD, #DD, #DD, #DD, #DD, #DD, #0D, #DD, #DD, #DD, #DD, #DD, #DD, #DD
            db #0D, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #0D, #DD, #DD, #00, #0D, #DD, #DD, #DD
            db #0E, #EE, #E0, #01, #00, #EE, #EE, #EE, #0E, #EE, #E0, #11, #10, #EE, #EE, #EE
            db #F0, #00, #00, #01, #00, #00, #00, #00, #FF, #FF, #FF, #00, #0F, #FF, #FF, #FF
            db #AA, #0F, #FF, #FF, #FF, #FF, #FF, #FF, #AA, #00, #00, #0F, #FF, #FF, #FF, #FF
            db #DD, #DD, #DD, #D0, #FF, #FF, #FF, #FF, #DC, #CC, #CC, #D0, #FF, #FF, #FF, #FF
            db #DC, #CC, #CC, #D0, #FF, #FF, #FF, #FF, #DC, #CC, #CC, #D0, #00, #00, #00, #0F
            db #DC, #CC, #CC, #DD, #DD, #DD, #DD, #D0, #DD, #DD, #DD, #DD, #DD, #DD, #11, #10
            db #DD, #DD, #DD, #DD, #DD, #DD, #11, #10, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #D0
            db #DD, #DD, #DD, #DD, #DD, #DD, #DD, #D0, #DD, #DD, #DD, #D0, #00, #DD, #DD, #D0
            db #EE, #EE, #EE, #00, #10, #0E, #EE, #E0, #EE, #EE, #EE, #01, #11, #0E, #EE, #E0
            db #00, #00, #00, #00, #10, #00, #00, #0F, #FF, #FF, #FF, #F0, #00, #FF, #FF, #FF
            db #F0, #00, #00, #00, #00, #00, #00, #00, #0D, #DD, #DD, #DD, #DD, #DD, #DD, #DD
            db #0D, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #0D, #DD, #CC, #CC, #CC, #DC, #CC, #CC
            db #0D, #DD, #CC, #CC, #CC, #DC, #CC, #CC, #0D, #DD, #CC, #CC, #CC, #DC, #CC, #CC
            db #0D, #DD, #CC, #CC, #CC, #DC, #CC, #CC, #0D, #DD, #CC, #CC, #CC, #DC, #CC, #CC
            db #0D, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #0D, #DD, #DD, #AA, #AA, #AA, #AA, #AA
            db #0D, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #0E, #EE, #EE, #E0, #00, #EE, #EE, #EE
            db #0E, #EE, #EE, #00, #10, #0E, #EE, #EE, #0E, #EE, #EE, #01, #11, #0E, #EE, #EE
            db #F0, #00, #00, #00, #10, #00, #00, #00, #FF, #FF, #FF, #F0, #00, #FF, #FF, #FF
            db #00, #00, #00, #00, #00, #00, #00, #00, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #DD
            db #DD, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #CD, #CC, #CC, #CC, #DC, #CC, #CC, #CD
            db #CD, #CC, #CC, #CC, #DC, #CC, #CC, #CD, #CD, #CC, #CC, #CC, #DC, #CC, #CC, #CD
            db #CD, #CC, #CC, #CC, #DC, #CC, #CC, #CD, #CD, #CC, #CC, #CC, #DC, #CC, #CC, #CD
            db #DD, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #AA, #AA, #AA, #AA, #AA, #AA, #AA, #AA
            db #DD, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE
            db #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE, #EE
            db #00, #00, #00, #00, #00, #00, #00, #00, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #00, #00, #00, #00, #00, #00, #00, #0F, #DD, #DD, #DD, #DD, #DD, #DD, #DD, #D0
            db #DD, #DD, #DD, #DD, #DD, #DD, #DD, #D0, #CC, #CC, #CC, #DC, #CC, #CC, #CC, #C0
            db #CC, #CC, #CC, #DC, #CC, #CC, #CC, #C0, #CC, #CC, #CC, #DC, #CC, #CC, #CC, #C0
            db #CC, #CC, #CC, #DC, #CC, #CC, #CC, #C0, #CC, #CC, #CC, #DC, #CC, #CC, #CC, #C0
            db #DD, #DD, #DD, #DD, #DD, #DC, #CC, #C0, #AA, #AA, #AA, #AA, #AD, #DC, #CC, #C0
            db #DD, #DD, #DD, #DD, #DD, #DD, #DD, #D0, #EE, #EE, #E0, #00, #EE, #EE, #EE, #E0
            db #EE, #EE, #00, #10, #0E, #EE, #EE, #E0, #EE, #EE, #01, #11, #0E, #EE, #EE, #E0
            db #00, #00, #00, #10, #00, #00, #00, #0F, #FF, #FF, #F0, #00, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #00, #0F, #FF, #FF, #FF, #FF, #FF, #F0, #DD, #D0, #FF, #FF, #FF
            db #FF, #FF, #0D, #DD, #DD, #0F, #FF, #FF, #FF, #FF, #0D, #DD, #DD, #0F, #FF, #FF
            db #F0, #00, #00, #DD, #D0, #00, #0F, #FF, #0A, #AA, #AA, #66, #66, #00, #FF, #FF
            db #0A, #AA, #AA, #66, #66, #00, #FF, #FF, #0A, #AA, #AA, #66, #66, #00, #FF, #FF
            db #0A, #AA, #AA, #66, #66, #00, #00, #FF, #0A, #AA, #AA, #AD, #DD, #00, #DD, #0F
            db #F0, #DD, #DD, #DD, #DD, #DD, #DD, #0F, #F0, #00, #0D, #DD, #DD, #00, #00, #FF
            db #F0, #00, #00, #00, #00, #00, #00, #FF, #F0, #00, #0F, #FF, #FF, #00, #00, #FF
            db #F0, #00, #0F, #FF, #FF, #00, #00, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #00, #00, #00, #00, #00, #00, #FF
            db #F0, #99, #99, #99, #99, #99, #99, #0F, #F0, #99, #11, #11, #11, #11, #99, #0F
            db #F0, #11, #99, #11, #11, #22, #21, #0F, #F0, #11, #11, #91, #19, #22, #21, #0F
            db #F0, #11, #11, #19, #91, #22, #21, #0F, #F0, #11, #11, #11, #11, #11, #11, #0F
            db #F0, #11, #11, #11, #11, #11, #11, #0F, #F0, #11, #11, #11, #11, #11, #11, #0F
            db #F0, #11, #11, #11, #11, #11, #11, #0F, #FF, #00, #00, #00, #00, #00, #00, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #F0, #00, #00, #00, #00, #0F, #FF, #FF, #0A, #AA, #AA, #AA, #AA, #A0, #FF
            db #FF, #0A, #AA, #AA, #AA, #AA, #A0, #FF, #F0, #55, #55, #55, #55, #55, #55, #0F
            db #F0, #AA, #AA, #A5, #5A, #AA, #AA, #0F, #F0, #AA, #AA, #A5, #5A, #AA, #AA, #0F
            db #F0, #AA, #AA, #A5, #5A, #AA, #AA, #0F, #F0, #55, #55, #55, #55, #55, #55, #0F
            db #F0, #AA, #AA, #A5, #5A, #AA, #AA, #0F, #F0, #AA, #AA, #A5, #5A, #AA, #AA, #0F
            db #F0, #AA, #AA, #A5, #5A, #AA, #AA, #0F, #F0, #AA, #AA, #A5, #5A, #AA, #AA, #0F
            db #FF, #00, #00, #00, #00, #00, #00, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #F0, #00, #00, #0F, #FF, #FF, #FF, #FF, #01, #11, #11, #10, #FF, #FF
            db #FF, #F0, #11, #11, #11, #11, #0F, #FF, #FF, #01, #11, #11, #11, #11, #10, #FF
            db #FF, #01, #11, #11, #11, #11, #10, #FF, #FF, #01, #11, #11, #11, #11, #10, #FF
            db #FF, #01, #10, #11, #01, #10, #10, #FF, #FF, #01, #11, #11, #11, #11, #10, #FF
            db #FF, #01, #11, #11, #11, #11, #10, #FF, #FF, #F0, #11, #11, #11, #11, #0F, #FF
            db #FF, #F0, #11, #11, #11, #10, #FF, #FF, #FF, #01, #11, #00, #00, #0F, #FF, #FF
            db #FF, #01, #10, #FF, #FF, #FF, #FF, #FF, #FF, #01, #0F, #FF, #FF, #FF, #FF, #FF
            db #FF, #F0, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #F0, #00, #0F, #00, #00, #FF, #FF, #FF, #02, #22, #20, #22, #22, #0F, #FF
            db #F0, #22, #22, #22, #22, #22, #20, #FF, #F0, #22, #32, #22, #22, #22, #20, #FF
            db #F0, #22, #22, #22, #22, #22, #20, #FF, #F0, #22, #22, #22, #22, #22, #20, #FF
            db #FF, #02, #22, #22, #22, #22, #0F, #FF, #FF, #F0, #22, #22, #22, #20, #FF, #FF
            db #FF, #FF, #02, #22, #22, #0F, #FF, #FF, #FF, #FF, #F0, #22, #22, #0F, #FF, #FF
            db #FF, #FF, #F0, #22, #20, #FF, #FF, #FF, #FF, #FF, #FF, #02, #0F, #FF, #FF, #FF
            db #FF, #FF, #FF, #F0, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #00, #00, #FF, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #FF, #00, #00, #FF, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #FF, #00, #00, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #00, #00, #00, #00, #FF, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #FF, #00, #00, #00, #44, #0F, #FF, #FF, #FF, #FF, #FF, #F0, #44, #0F, #FF
            db #FF, #FF, #FF, #F0, #00, #44, #0F, #FF, #FF, #FF, #FF, #04, #44, #44, #0F, #FF
            db #FF, #FF, #FF, #04, #44, #40, #FF, #FF, #FF, #FF, #FF, #04, #40, #0F, #FF, #FF
            db #FF, #FF, #FF, #04, #40, #FF, #FF, #FF, #FF, #FF, #FF, #F0, #0F, #FF, #FF, #FF
            db #FF, #FF, #FF, #04, #40, #FF, #FF, #FF, #FF, #FF, #FF, #04, #40, #FF, #FF, #FF
            db #FF, #FF, #FF, #04, #40, #FF, #FF, #FF, #FF, #FF, #FF, #F0, #0F, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #F0, #FF, #FF, #FF, #F0, #FF, #FF, #FF, #04, #0F, #FF
            db #FF, #04, #0F, #FF, #F0, #04, #00, #FF, #F0, #04, #00, #FF, #04, #41, #44, #0F
            db #04, #41, #44, #0F, #F0, #04, #00, #FF, #F0, #04, #00, #FF, #FF, #04, #0F, #FF
            db #FF, #04, #0F, #FF, #FF, #F0, #FF, #FF, #FF, #F0, #FF, #F0, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #04, #0F, #FF, #FF, #FF, #FF, #FF, #F0, #04, #00, #FF, #FF, #FF
            db #FF, #FF, #04, #41, #44, #0F, #FF, #FF, #FF, #FF, #F0, #04, #00, #FF, #FF, #FF
            db #FF, #FF, #FF, #04, #0F, #FF, #FF, #FF, #FF, #FF, #FF, #F0, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #F0, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #09, #0F, #FF, #FF, #FF
            db #FF, #FF, #F0, #90, #0F, #FF, #FF, #FF, #FF, #FF, #FF, #00, #90, #FF, #FF, #FF
            db #FF, #FF, #00, #00, #00, #0F, #FF, #FF, #FF, #F0, #55, #55, #55, #50, #FF, #FF
            db #FF, #F0, #55, #55, #55, #50, #0F, #FF, #FF, #F0, #11, #11, #11, #11, #10, #FF
            db #FF, #F0, #18, #88, #88, #11, #10, #FF, #FF, #F0, #18, #88, #88, #11, #10, #FF
            db #FF, #F0, #18, #88, #88, #11, #10, #FF, #FF, #F0, #11, #11, #11, #10, #0F, #FF
            db #FF, #F0, #11, #11, #11, #10, #FF, #FF, #FF, #F0, #11, #11, #11, #10, #FF, #FF
            db #FF, #FF, #00, #00, #00, #0F, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #F0, #F0, #FF, #FF, #FF, #FF, #FF, #FF, #05, #05, #0F
            db #FF, #FF, #FF, #FF, #FF, #05, #05, #0F, #FF, #FF, #FF, #FF, #FF, #05, #05, #0F
            db #FF, #FF, #F0, #FF, #F0, #05, #05, #0F, #FF, #F0, #06, #00, #06, #05, #05, #0F
            db #FF, #04, #44, #44, #44, #45, #45, #0F, #FF, #04, #44, #44, #44, #45, #45, #0F
            db #FF, #04, #44, #44, #44, #44, #40, #FF, #F0, #22, #22, #22, #22, #22, #21, #0F
            db #F0, #22, #22, #22, #22, #22, #20, #FF, #FF, #02, #22, #22, #22, #22, #0F, #FF
            db #FF, #02, #22, #22, #22, #22, #0F, #FF, #FF, #F0, #22, #22, #22, #20, #FF, #FF
            db #FF, #FF, #00, #02, #00, #0F, #FF, #FF, #FF, #FF, #FF, #F0, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #00, #00, #FF, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #F0, #44, #44, #0F, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #00, #00, #44, #44, #00, #00, #FF
            db #F0, #44, #44, #44, #44, #44, #44, #0F, #FF, #04, #44, #44, #44, #44, #40, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #FF, #04, #44, #44, #40, #FF, #FF
            db #FF, #FF, #F0, #44, #44, #0F, #FF, #FF, #FF, #FF, #FF, #04, #40, #FF, #FF, #FF
            db #FF, #FF, #FF, #F0, #0F, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #00, #00, #FF, #FF, #FF
            db #FF, #FF, #00, #44, #44, #00, #FF, #FF, #FF, #F0, #44, #44, #44, #44, #0F, #FF
            db #FF, #04, #48, #88, #88, #84, #40, #FF, #FF, #04, #88, #88, #88, #88, #40, #FF
            db #F0, #44, #84, #44, #44, #44, #44, #0F, #F0, #44, #88, #48, #88, #48, #44, #0F
            db #F0, #44, #88, #88, #88, #88, #44, #0F, #F0, #44, #84, #44, #44, #44, #44, #0F
            db #FF, #04, #88, #88, #88, #88, #40, #FF, #FF, #04, #48, #88, #88, #84, #40, #FF
            db #FF, #F0, #44, #44, #44, #44, #0F, #FF, #FF, #FF, #00, #44, #44, #00, #FF, #FF
            db #FF, #FF, #FF, #00, #00, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            ORG #F400
            db #FF, #FF, #FF, #FF, #F0, #00, #00, #FF, #FF, #FF, #FF, #FF, #07, #77, #77, #0F
            db #FF, #FF, #FF, #FF, #07, #77, #77, #0F, #FF, #FF, #FF, #FF, #07, #77, #77, #0F
            db #FF, #FF, #FF, #FF, #07, #70, #00, #FF, #FF, #FF, #FF, #FF, #07, #70, #FF, #FF
            db #FF, #FF, #FF, #FF, #07, #70, #FF, #FF, #FF, #FF, #FF, #FF, #07, #70, #FF, #FF
            db #FF, #FF, #FF, #FF, #07, #70, #FF, #FF, #FF, #FF, #F0, #00, #07, #70, #FF, #FF
            db #FF, #FF, #07, #77, #77, #70, #FF, #FF, #FF, #FF, #07, #77, #77, #70, #FF, #FF
            db #FF, #FF, #07, #77, #70, #0F, #FF, #FF, #FF, #FF, #07, #77, #70, #FF, #FF, #FF
            db #FF, #FF, #F0, #00, #0F, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #F0, #00, #00, #0F, #FF, #FF
            db #FF, #FF, #F0, #FF, #FF, #0F, #FF, #FF, #FF, #F0, #00, #00, #00, #00, #0F, #FF
            db #FF, #0D, #D0, #DD, #DD, #0D, #D0, #FF, #FF, #0D, #DD, #DD, #DD, #DD, #D0, #FF
            db #FF, #0D, #DD, #DD, #DD, #DD, #D0, #FF, #FF, #0D, #DD, #DD, #DD, #DD, #D0, #FF
            db #FF, #0D, #DD, #DD, #DD, #DD, #D0, #FF, #FF, #0D, #DD, #DD, #DD, #DD, #D0, #FF
            db #FF, #0D, #DD, #DD, #DD, #DD, #D0, #FF, #FF, #0D, #DD, #DD, #DD, #DD, #D0, #FF
            db #FF, #0D, #DD, #DD, #DD, #DD, #D0, #FF, #FF, #F0, #00, #00, #00, #00, #0F, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #F1, #1F, #F1, #1F, #F1, #1F, #FF
            db #FF, #F1, #1F, #F1, #1F, #F1, #1F, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #F0, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #01, #0F, #FF, #FF, #FF
            db #FF, #F0, #FF, #01, #0F, #F0, #FF, #FF, #FF, #01, #0F, #04, #0F, #01, #0F, #FF
            db #FF, #F0, #40, #04, #00, #40, #FF, #FF, #FF, #FF, #04, #04, #04, #0F, #FF, #FF
            db #F0, #00, #00, #40, #40, #00, #00, #FF, #01, #14, #44, #0F, #04, #44, #11, #0F
            db #F0, #00, #00, #40, #40, #00, #00, #FF, #FF, #FF, #04, #04, #04, #0F, #FF, #FF
            db #FF, #F0, #40, #04, #00, #40, #FF, #FF, #FF, #01, #0F, #04, #0F, #01, #0F, #FF
            db #FF, #F0, #FF, #01, #0F, #F0, #FF, #FF, #FF, #FF, #FF, #01, #0F, #FF, #FF, #FF
            db #FF, #FF, #FF, #F0, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #F0, #00, #0F, #F0, #00, #FF, #FF, #FF, #0D, #DD, #D0, #0D, #DD, #0F, #FF
            db #F0, #DD, #DD, #D0, #DD, #DD, #D0, #FF, #F0, #DD, #DD, #DD, #0D, #DD, #D0, #FF
            db #F0, #DD, #DD, #D0, #DD, #DD, #D0, #FF, #F0, #DD, #DD, #DD, #0D, #DD, #D0, #FF
            db #FF, #0D, #DD, #D0, #DD, #DD, #0F, #FF, #FF, #F0, #DD, #DD, #0D, #D0, #FF, #FF
            db #FF, #FF, #0D, #D0, #DD, #0F, #FF, #FF, #FF, #FF, #F0, #DD, #0D, #0F, #FF, #FF
            db #FF, #FF, #F0, #D0, #D0, #FF, #FF, #FF, #FF, #FF, #FF, #0D, #0F, #FF, #FF, #FF
            db #FF, #FF, #FF, #F0, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #F2, #22, #22, #2F, #FF, #FF
            db #FF, #FF, #22, #22, #22, #22, #FF, #FF, #FF, #F2, #22, #FF, #FF, #22, #2F, #FF
            db #FF, #22, #FF, #FF, #FF, #FF, #22, #FF, #F2, #22, #FF, #FF, #FF, #FF, #22, #2F
            db #F2, #2F, #FF, #44, #44, #FF, #F2, #2F, #F2, #2F, #FF, #44, #44, #FF, #F2, #2F
            db #F2, #2F, #FF, #44, #44, #FF, #F2, #2F, #F2, #2F, #FF, #44, #44, #FF, #F2, #2F
            db #F2, #22, #FF, #FF, #FF, #FF, #22, #2F, #FF, #22, #FF, #FF, #FF, #FF, #22, #FF
            db #FF, #F2, #22, #FF, #FF, #22, #2F, #FF, #FF, #FF, #22, #22, #22, #22, #FF, #FF
            db #FF, #FF, #F2, #22, #22, #2F, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
            db #FF, #FF, #FF, #F0, #33, #0F, #FF, #FF, #FF, #F0, #00, #03, #33, #30, #FF, #FF
            db #FF, #03, #33, #33, #33, #30, #FF, #FF, #FF, #03, #33, #33, #33, #30, #0F, #FF
            db #FF, #03, #33, #34, #43, #33, #30, #FF, #FF, #03, #33, #44, #44, #33, #33, #0F
            db #FF, #03, #33, #44, #44, #33, #33, #0F, #FF, #03, #33, #34, #43, #33, #30, #FF
            db #FF, #03, #33, #33, #33, #30, #0F, #FF, #FF, #03, #33, #36, #63, #30, #FF, #FF
            db #FF, #F0, #00, #06, #63, #30, #FF, #FF, #FF, #FF, #FF, #06, #63, #0F, #FF, #FF
            db #FF, #FF, #FF, #06, #60, #FF, #FF, #FF, #FF, #FF, #FF, #06, #60, #FF, #FF, #FF
            db #FF, #FF, #FF, #06, #60, #FF, #FF, #FF, #FF, #FF, #FF, #06, #60, #FF, #FF, #FF
            MMU 6 7, 94             ; bank 47: the rest of the patterns, then the tiles
            ORG #C000
pats:
            ORG #E000
truns:
            db 1, 15        ; tiles 1-15
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44
            db #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44, #44
            db #66, #66, #66, #66, #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55
            db #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55
            db #66, #66, #66, #66, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #66, #66, #66, #66, #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54
            db #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54
            db #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55
            db #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55
            db #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54
            db #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54
            db #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55
            db #65, #55, #55, #55, #65, #55, #55, #55, #65, #55, #55, #55, #64, #44, #44, #44
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #44, #44, #44, #44
            db #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54
            db #55, #55, #55, #54, #55, #55, #55, #54, #55, #55, #55, #54, #44, #44, #44, #44
            db #55, #55, #55, #55, #55, #35, #53, #55, #53, #33, #33, #35, #53, #33, #33, #35
            db #55, #33, #33, #55, #55, #53, #35, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #58, #85, #55, #55, #88, #88, #55, #88, #88, #88, #88
            db #55, #88, #88, #55, #58, #85, #58, #85, #55, #55, #55, #55, #55, #55, #55, #55
            db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00
            db #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00, #00
            db #55, #55, #55, #55, #55, #11, #15, #55, #51, #11, #11, #55, #51, #11, #11, #55
            db #55, #11, #15, #55, #55, #51, #55, #55, #55, #51, #11, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #58, #88, #55, #58, #55, #55, #85, #58, #58, #88, #85
            db #58, #58, #85, #85, #55, #88, #88, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db 32, 82        ; tiles 32-113
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #51, #15, #55, #55, #11, #11, #55, #55, #11, #11, #E5, #55, #51, #1E, #E5
            db #55, #51, #1E, #55, #55, #55, #EE, #55, #55, #51, #15, #55, #55, #55, #EE, #55
            db #51, #15, #11, #55, #51, #1E, #11, #E5, #55, #EE, #5E, #E5, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #51, #15, #11, #55, #51, #1E, #11, #E5, #11, #11, #11, #15, #51, #1E, #11, #EE
            db #11, #11, #11, #15, #51, #1E, #11, #EE, #51, #1E, #11, #E5, #55, #EE, #5E, #E5
            db #55, #11, #55, #55, #51, #11, #11, #55, #11, #EE, #EE, #E5, #51, #11, #15, #55
            db #55, #EE, #11, #55, #11, #11, #1E, #E5, #5E, #11, #EE, #55, #55, #5E, #E5, #55
            db #55, #55, #55, #55, #11, #55, #51, #15, #11, #E5, #11, #EE, #5E, #E1, #1E, #E5
            db #55, #11, #EE, #55, #51, #1E, #E1, #15, #11, #EE, #51, #1E, #5E, #E5, #55, #EE
            db #55, #11, #15, #55, #51, #1E, #11, #55, #55, #11, #1E, #E5, #51, #11, #E1, #15
            db #11, #E1, #11, #EE, #11, #E5, #11, #E5, #51, #11, #51, #15, #55, #EE, #E5, #EE
            db #51, #15, #55, #55, #51, #1E, #55, #55, #11, #EE, #55, #55, #5E, #E5, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #51, #15, #55, #55, #11, #EE, #55, #51, #1E, #E5, #55, #51, #1E, #55, #55
            db #51, #1E, #55, #55, #55, #11, #55, #55, #55, #51, #15, #55, #55, #55, #EE, #55
            db #51, #15, #55, #55, #55, #11, #55, #55, #55, #51, #15, #55, #55, #51, #1E, #55
            db #55, #51, #1E, #55, #55, #11, #EE, #55, #51, #1E, #E5, #55, #55, #EE, #55, #55
            db #55, #55, #55, #55, #51, #15, #51, #15, #55, #11, #11, #EE, #11, #11, #11, #11
            db #5E, #11, #11, #EE, #51, #1E, #E1, #15, #55, #EE, #55, #EE, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #11, #55, #55, #55, #11, #E5, #55, #11, #11, #11, #55
            db #5E, #11, #EE, #E5, #55, #11, #E5, #55, #55, #5E, #E5, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #11, #55, #55, #55, #11, #E5, #55, #51, #1E, #E5, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #11, #11, #11, #55
            db #5E, #EE, #EE, #E5, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #11, #55, #55, #55, #11, #E5, #55, #55, #5E, #E5, #55
            db #55, #55, #51, #15, #55, #55, #11, #EE, #55, #51, #1E, #E5, #55, #11, #EE, #55
            db #51, #1E, #E5, #55, #11, #EE, #55, #55, #1E, #E5, #55, #55, #5E, #55, #55, #55
            db #51, #11, #11, #55, #11, #EE, #E1, #15, #11, #E5, #11, #1E, #11, #E1, #11, #1E
            db #11, #11, #E1, #1E, #11, #1E, #E1, #1E, #51, #11, #11, #EE, #55, #EE, #EE, #E5
            db #55, #11, #55, #55, #51, #11, #E5, #55, #55, #11, #E5, #55, #55, #11, #E5, #55
            db #55, #11, #E5, #55, #55, #11, #E5, #55, #11, #11, #11, #55, #5E, #EE, #EE, #E5
            db #51, #11, #15, #55, #11, #EE, #11, #55, #5E, #E5, #11, #E5, #55, #11, #1E, #E5
            db #51, #1E, #EE, #55, #11, #EE, #11, #55, #11, #11, #11, #E5, #5E, #EE, #EE, #E5
            db #51, #11, #15, #55, #11, #EE, #11, #55, #5E, #E5, #11, #E5, #55, #11, #1E, #E5
            db #55, #5E, #11, #55, #11, #55, #11, #E5, #51, #11, #1E, #E5, #55, #EE, #EE, #55
            db #55, #51, #11, #55, #55, #11, #11, #E5, #51, #1E, #11, #E5, #11, #EE, #11, #E5
            db #11, #11, #11, #15, #5E, #EE, #11, #EE, #55, #51, #11, #15, #55, #55, #EE, #EE
            db #11, #11, #11, #55, #11, #EE, #EE, #E5, #11, #11, #15, #55, #5E, #EE, #11, #55
            db #55, #55, #11, #E5, #11, #55, #11, #E5, #51, #11, #1E, #E5, #55, #EE, #EE, #55
            db #55, #11, #15, #55, #51, #1E, #EE, #55, #11, #EE, #55, #55, #11, #11, #15, #55
            db #11, #EE, #11, #55, #11, #E5, #11, #E5, #51, #11, #1E, #E5, #55, #EE, #EE, #55
            db #11, #11, #11, #55, #11, #EE, #11, #E5, #5E, #E5, #11, #E5, #55, #51, #1E, #E5
            db #55, #11, #EE, #55, #55, #11, #E5, #55, #55, #11, #E5, #55, #55, #5E, #E5, #55
            db #51, #11, #15, #55, #11, #EE, #11, #55, #11, #E5, #11, #E5, #51, #11, #1E, #E5
            db #11, #EE, #11, #55, #11, #E5, #11, #E5, #51, #11, #1E, #E5, #55, #EE, #EE, #55
            db #51, #11, #15, #55, #11, #EE, #11, #55, #11, #E5, #11, #E5, #51, #11, #11, #E5
            db #55, #EE, #11, #E5, #55, #51, #1E, #E5, #51, #11, #EE, #55, #55, #EE, #E5, #55
            db #55, #55, #55, #55, #55, #11, #55, #55, #55, #11, #E5, #55, #55, #5E, #E5, #55
            db #55, #55, #55, #55, #55, #11, #55, #55, #55, #11, #E5, #55, #55, #5E, #E5, #55
            db #55, #55, #55, #55, #55, #11, #55, #55, #55, #11, #E5, #55, #55, #5E, #E5, #55
            db #55, #55, #55, #55, #55, #11, #55, #55, #55, #11, #E5, #55, #51, #1E, #E5, #55
            db #55, #51, #15, #55, #55, #11, #EE, #55, #51, #1E, #E5, #55, #11, #EE, #55, #55
            db #51, #15, #55, #55, #55, #11, #55, #55, #55, #51, #15, #55, #55, #55, #EE, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #11, #11, #11, #55, #5E, #EE, #EE, #E5
            db #55, #55, #55, #55, #11, #11, #11, #55, #5E, #EE, #EE, #E5, #55, #55, #55, #55
            db #51, #15, #55, #55, #55, #11, #55, #55, #55, #51, #15, #55, #55, #55, #11, #55
            db #55, #51, #1E, #E5, #55, #11, #EE, #55, #51, #1E, #E5, #55, #55, #EE, #55, #55
            db #51, #11, #15, #55, #11, #EE, #11, #55, #5E, #E5, #11, #E5, #55, #51, #1E, #E5
            db #55, #11, #EE, #55, #55, #5E, #E5, #55, #55, #11, #55, #55, #55, #5E, #E5, #55
            db #51, #11, #11, #55, #11, #EE, #E1, #15, #11, #E1, #11, #1E, #11, #E1, #11, #1E
            db #11, #E1, #11, #1E, #11, #E5, #EE, #EE, #51, #11, #15, #55, #55, #EE, #EE, #55
            db #55, #11, #55, #55, #51, #11, #15, #55, #11, #EE, #11, #55, #11, #E5, #11, #E5
            db #11, #11, #11, #E5, #11, #EE, #11, #E5, #11, #E5, #11, #E5, #5E, #E5, #5E, #E5
            db #11, #11, #11, #55, #51, #1E, #E1, #15, #51, #1E, #51, #1E, #51, #11, #11, #EE
            db #51, #1E, #E1, #15, #51, #1E, #51, #1E, #11, #11, #11, #EE, #5E, #EE, #EE, #E5
            db #55, #11, #11, #55, #51, #1E, #E1, #15, #11, #EE, #55, #EE, #11, #E5, #55, #55
            db #11, #E5, #55, #55, #51, #15, #51, #15, #55, #11, #11, #EE, #55, #5E, #EE, #E5
            db #11, #11, #15, #55, #51, #1E, #11, #55, #51, #1E, #51, #15, #51, #1E, #51, #1E
            db #51, #1E, #51, #1E, #51, #1E, #11, #EE, #11, #11, #1E, #E5, #5E, #EE, #EE, #55
            db #11, #11, #11, #15, #51, #1E, #EE, #1E, #51, #1E, #15, #5E, #51, #11, #1E, #55
            db #51, #1E, #1E, #55, #51, #1E, #5E, #15, #11, #11, #11, #1E, #5E, #EE, #EE, #EE
            db #11, #11, #11, #15, #51, #1E, #EE, #1E, #51, #1E, #15, #5E, #51, #11, #1E, #55
            db #51, #1E, #1E, #55, #51, #1E, #5E, #55, #11, #11, #55, #55, #5E, #EE, #E5, #55
            db #55, #11, #11, #55, #51, #1E, #E1, #15, #11, #EE, #55, #EE, #11, #E5, #55, #55
            db #11, #E5, #11, #15, #51, #15, #51, #1E, #55, #11, #11, #1E, #55, #5E, #EE, #EE
            db #11, #55, #11, #55, #11, #E5, #11, #E5, #11, #E5, #11, #E5, #11, #11, #11, #E5
            db #11, #EE, #11, #E5, #11, #E5, #11, #E5, #11, #E5, #11, #E5, #5E, #E5, #5E, #E5
            db #51, #11, #15, #55, #55, #11, #EE, #55, #55, #11, #E5, #55, #55, #11, #E5, #55
            db #55, #11, #E5, #55, #55, #11, #E5, #55, #51, #11, #15, #55, #55, #EE, #EE, #55
            db #55, #51, #11, #15, #55, #55, #11, #EE, #55, #55, #11, #E5, #55, #55, #11, #E5
            db #11, #55, #11, #E5, #11, #E5, #11, #E5, #51, #11, #1E, #E5, #55, #EE, #EE, #55
            db #11, #15, #51, #15, #51, #1E, #51, #1E, #51, #1E, #11, #EE, #51, #11, #1E, #E5
            db #51, #1E, #11, #55, #51, #1E, #51, #15, #11, #1E, #51, #1E, #5E, #EE, #55, #EE
            db #11, #11, #55, #55, #51, #1E, #E5, #55, #51, #1E, #55, #55, #51, #1E, #55, #55
            db #51, #1E, #55, #15, #51, #1E, #51, #1E, #11, #11, #11, #1E, #5E, #EE, #EE, #EE
            db #11, #55, #51, #15, #11, #15, #11, #1E, #11, #11, #11, #1E, #11, #11, #11, #1E
            db #11, #E1, #E1, #1E, #11, #E5, #E1, #1E, #11, #E5, #51, #1E, #5E, #E5, #55, #EE
            db #11, #55, #51, #15, #11, #15, #51, #1E, #11, #11, #51, #1E, #11, #E1, #11, #1E
            db #11, #E5, #11, #1E, #11, #E5, #51, #1E, #11, #E5, #51, #1E, #5E, #E5, #55, #EE
            db #55, #11, #15, #55, #51, #1E, #11, #55, #11, #EE, #51, #15, #11, #E5, #51, #1E
            db #11, #E5, #51, #1E, #51, #15, #11, #EE, #55, #11, #1E, #E5, #55, #5E, #EE, #55
            db #11, #11, #11, #55, #51, #1E, #E1, #15, #51, #1E, #51, #1E, #51, #11, #11, #EE
            db #51, #1E, #EE, #E5, #51, #1E, #55, #55, #11, #11, #55, #55, #5E, #EE, #E5, #55
            db #51, #11, #15, #55, #11, #EE, #11, #55, #11, #E5, #11, #E5, #11, #E5, #11, #E5
            db #11, #E1, #11, #E5, #51, #11, #1E, #E5, #55, #E1, #11, #55, #55, #55, #EE, #E5
            db #11, #11, #11, #55, #51, #1E, #E1, #15, #51, #1E, #51, #1E, #51, #11, #11, #EE
            db #51, #1E, #11, #E5, #51, #1E, #51, #15, #11, #1E, #51, #1E, #5E, #EE, #55, #EE
            db #51, #11, #15, #55, #11, #EE, #11, #55, #11, #15, #5E, #E5, #51, #11, #55, #55
            db #55, #E1, #11, #55, #11, #55, #11, #E5, #51, #11, #1E, #E5, #55, #EE, #EE, #55
            db #11, #11, #11, #55, #1E, #11, #E1, #E5, #5E, #11, #E5, #E5, #55, #11, #E5, #55
            db #55, #11, #E5, #55, #55, #11, #E5, #55, #51, #11, #15, #55, #55, #EE, #EE, #55
            db #11, #55, #11, #55, #11, #E5, #11, #E5, #11, #E5, #11, #E5, #11, #E5, #11, #E5
            db #11, #E5, #11, #E5, #11, #E5, #11, #E5, #11, #11, #11, #E5, #5E, #EE, #EE, #E5
            db #11, #55, #11, #55, #11, #E5, #11, #E5, #11, #E5, #11, #E5, #11, #E5, #11, #E5
            db #11, #E5, #11, #E5, #51, #11, #1E, #E5, #55, #11, #EE, #55, #55, #5E, #E5, #55
            db #11, #55, #51, #15, #11, #E5, #51, #1E, #11, #E5, #51, #1E, #11, #E1, #51, #1E
            db #11, #11, #11, #1E, #11, #1E, #11, #1E, #11, #EE, #51, #1E, #5E, #E5, #55, #EE
            db #11, #55, #51, #15, #11, #E5, #51, #1E, #51, #15, #11, #EE, #55, #11, #1E, #E5
            db #55, #11, #1E, #55, #51, #1E, #11, #55, #11, #EE, #51, #15, #5E, #E5, #55, #EE
            db #11, #55, #11, #55, #11, #E5, #11, #E5, #11, #E5, #11, #E5, #51, #11, #1E, #E5
            db #55, #11, #EE, #55, #55, #11, #E5, #55, #51, #11, #15, #55, #55, #EE, #EE, #55
            db #11, #11, #11, #15, #11, #EE, #E1, #1E, #1E, #E5, #11, #EE, #5E, #51, #1E, #E5
            db #55, #11, #EE, #15, #51, #1E, #E1, #1E, #11, #11, #11, #1E, #5E, #EE, #EE, #EE
            db #51, #11, #15, #55, #51, #1E, #EE, #55, #51, #1E, #55, #55, #51, #1E, #55, #55
            db #51, #1E, #55, #55, #51, #1E, #55, #55, #51, #11, #15, #55, #55, #EE, #EE, #55
            db #11, #55, #55, #55, #51, #15, #55, #55, #55, #11, #55, #55, #55, #51, #15, #55
            db #55, #55, #11, #55, #55, #55, #51, #15, #55, #55, #55, #1E, #55, #55, #55, #5E
            db #51, #11, #15, #55, #55, #E1, #1E, #55, #55, #51, #1E, #55, #55, #51, #1E, #55
            db #55, #51, #1E, #55, #55, #51, #1E, #55, #51, #11, #1E, #55, #55, #EE, #EE, #55
            db #55, #51, #55, #55, #55, #11, #15, #55, #51, #1E, #11, #55, #11, #EE, #51, #15
            db #5E, #E5, #55, #EE, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55
            db #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #55, #11, #11, #11, #11
            db #77, #77, #77, #77, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC
            db #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #3C, #CC, #CC, #CC, #3C, #CC, #CC, #CC, #3C, #CC, #CC, #CC
            db #3C, #CC, #CC, #CC, #3C, #CC, #CC, #CC, #3C, #CC, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #33, #CC, #CC, #CC, #33, #CC, #CC, #CC, #33, #CC, #CC, #CC
            db #33, #CC, #CC, #CC, #33, #CC, #CC, #CC, #33, #CC, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #33, #3C, #CC, #CC, #33, #3C, #CC, #CC, #33, #3C, #CC, #CC
            db #33, #3C, #CC, #CC, #33, #3C, #CC, #CC, #33, #3C, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #33, #33, #CC, #CC, #33, #33, #CC, #CC, #33, #33, #CC, #CC
            db #33, #33, #CC, #CC, #33, #33, #CC, #CC, #33, #33, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #33, #33, #3C, #CC, #33, #33, #3C, #CC, #33, #33, #3C, #CC
            db #33, #33, #3C, #CC, #33, #33, #3C, #CC, #33, #33, #3C, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #33, #33, #33, #CC, #33, #33, #33, #CC, #33, #33, #33, #CC
            db #33, #33, #33, #CC, #33, #33, #33, #CC, #33, #33, #33, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #33, #33, #33, #3C, #33, #33, #33, #3C, #33, #33, #33, #3C
            db #33, #33, #33, #3C, #33, #33, #33, #3C, #33, #33, #33, #3C, #77, #77, #77, #77
            db #77, #77, #77, #77, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33
            db #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #33, #77, #77, #77, #77
            db #77, #77, #77, #77, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC
            db #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #9C, #CC, #CC, #CC, #9C, #CC, #CC, #CC, #9C, #CC, #CC, #CC
            db #9C, #CC, #CC, #CC, #9C, #CC, #CC, #CC, #9C, #CC, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #99, #CC, #CC, #CC, #99, #CC, #CC, #CC, #99, #CC, #CC, #CC
            db #99, #CC, #CC, #CC, #99, #CC, #CC, #CC, #99, #CC, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #99, #9C, #CC, #CC, #99, #9C, #CC, #CC, #99, #9C, #CC, #CC
            db #99, #9C, #CC, #CC, #99, #9C, #CC, #CC, #99, #9C, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #99, #99, #CC, #CC, #99, #99, #CC, #CC, #99, #99, #CC, #CC
            db #99, #99, #CC, #CC, #99, #99, #CC, #CC, #99, #99, #CC, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #99, #99, #9C, #CC, #99, #99, #9C, #CC, #99, #99, #9C, #CC
            db #99, #99, #9C, #CC, #99, #99, #9C, #CC, #99, #99, #9C, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #99, #99, #99, #CC, #99, #99, #99, #CC, #99, #99, #99, #CC
            db #99, #99, #99, #CC, #99, #99, #99, #CC, #99, #99, #99, #CC, #77, #77, #77, #77
            db #77, #77, #77, #77, #99, #99, #99, #9C, #99, #99, #99, #9C, #99, #99, #99, #9C
            db #99, #99, #99, #9C, #99, #99, #99, #9C, #99, #99, #99, #9C, #77, #77, #77, #77
            db #77, #77, #77, #77, #99, #99, #99, #99, #99, #99, #99, #99, #99, #99, #99, #99
            db #99, #99, #99, #99, #99, #99, #99, #99, #99, #99, #99, #99, #77, #77, #77, #77
            db 0, 0
            MMU 6 7, 0
            ORG ld_end
    ELSE
            ld ({sps}), sp          ; the real stack (calls)
            ld sp, (ls_stk)         ; (task: the real stack, ntc_cpmstack - slot 7 is borrowed below)
            ld bc, #243B
            ld a, #43               ; palette control: the tilemap's first palette
            out (c), a
            inc b
            ld a, #30
            out (c), a
            dec b
            ld hl, tpal
            ld e, 16
            call palset
            ld a, #43               ; the sprites' first palette
            out (c), a
            inc b
            ld a, #20
            out (c), a
            dec b
            ld hl, spal
            ld e, 0                ; 16 x 16 (0 = 256)
            call palset
            ld a, #43               ; back to the ULA's, first palettes in use
            out (c), a
            inc b
            xor a
            out (c), a
            ld bc, #303B            ; sprite patterns from pattern 0
            xor a
            out (c), a
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, (#BF00 + 120)
            out (c), a
            ld hl, #C000            ; 64 from bank 5's copy (its first page)
            ld de, 8192
            call ld_po
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, (#BF00 + 121)
            out (c), a
            ld hl, #D400            ; 7 from bank 5's copy (#F400: its second page + #1400)
            ld de, 896
            call ld_po
            ld bc, #243B            ; the rest from bank 47 (its first page at #E000)
            ld a, #57
            out (c), a
            inc b
            ld a, (#BF00 + 94)
            out (c), a
            ld hl, #E000
            ld de, 0
            call ld_po
            ld bc, #243B
            ld a, #57               ; the tiles: its second page at #E000
            out (c), a
            inc b
            ld a, (#BF00 + 95)
            out (c), a
            dec b
            ld a, #56               ; (task: slot 6 bank 5's first page: the tiles go there)
            out (c), a
            inc b
            ld a, 10
            out (c), a
            dec b
            ld hl, #CC00            ; every tile transparent (colour 15) first: 128 tiles at #0C00
            ld de, #CC01
            ld bc, #0FFF
            ld (hl), #FF
            ldir
            ld hl, #E000
ld_run:
            ld a, (hl)              ; a run: first tile, count (0, 0 = the end), its definitions
            inc hl
            ld c, (hl)
            inc hl
            ld b, a
            or c
            jr z, ld_spr
            ld a, b
            ld e, a                 ; DE = #C000 + first * 32
            ld d, 0
            ex de, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld a, h
            add a, #CC
            ld h, a
            ex de, hl
            ld a, c                 ; BC = count * 32 (count 1 - 255: tile 0 run of 0 not used)
            ld b, 0
            ld c, a
            push hl
            ld h, b
            ld l, c
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld b, h
            ld c, l
            pop hl
            ldir
            jr ld_run
ld_spr:
            jr ld_done
            ld bc, #303B            ; sprite patterns from pattern 0
            xor a
            out (c), a
            ld hl, 0                ; (task: not used - the patterns came from the data)
            ld de, 9088
            ld c, #5B
ld_pat:
            ld a, d
            or e
            jr z, ld_done
            ld a, (hl)
            out (c), a
            inc hl
            dec de
            jr ld_pat
ld_done:
            ld bc, #243B            ; bank 5 back at #E000
            ld a, #57
            out (c), a
            inc b
    IFDEF NTC_ZXN
            ld a, 11
    ELSE
            ld a, (ls_h7)           ; (task: its own page back in slot 7)
    ENDIF
            out (c), a
            ld sp, ({sps})
            jp ld_end
; ld_po - DE bytes from HL to the sprite patterns
ld_po:
            ld c, #5B
ld_pol:
            ld a, d
            or e
            ret z
            ld a, (hl)
            out (c), a
            inc hl
            dec de
            jr ld_pol
; palset - E colours (0 = 256) from HL into the palette chosen, from index 0 (BC = #243B)
palset:
            ld a, #40
            out (c), a
            inc b
            xor a
            out (c), a
            dec b
ps_lp:
            ld a, #41
            out (c), a
            inc b
            ld a, (hl)
            out (c), a
            dec b
            inc hl
            dec e
            jr nz, ps_lp
            ret
tpal:
            db #00, #FF, #F7, #EA, #86, #41, #D7, #21, #F8, #7E, #77, #B6, #49, #E5, #61, #E3
spal:
            db #00, #FF, #F6, #D2, #44, #20, #E4, #A0, #02, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #0B, #06, #25, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #68, #44, #FF, #B6, #26, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #AD, #68, #EF, #CA, #DB, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #25, #00, #25, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #44, #20, #99, #51, #B2, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #D6, #8D, #D4, #AC, #4B, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #A7, #62, #A3, #62, #25, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #B6, #6E, #92, #6D, #44, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #17, #0E, #DB, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #F4, #AC, #2B, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #26, #01, #25, #25, #FF, #B6, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #FF, #B6, #25, #25, #F8, #B0, #57, #DB, #92, #E3
            db #00, #FF, #F6, #D2, #25, #00, #FF, #B6, #25, #25, #F8, #B0, #57, #F0, #A8, #E3
            db #00, #FF, #F6, #D2, #25, #00, #FF, #B6, #25, #25, #F8, #B0, #57, #0B, #06, #E3
            db #00, #FF, #E0, #EF, #FC, #88, #14, #0F, #F0, #B6, #D6, #6D, #57, #A3, #26, #E3
ld_end:
    ENDIF
#endasm
End Sub
