' V9: CyborgOS's console on a V9990 (E-VDP-III) - the CPC's Powergraph (or an MSX card through
' AMSDAP) at &FF60-&FF6F, an MSX's GFX9000 / Video9000 at #60-#6F (the MSX decodes only the low
' byte, so &FF6n is right for both). Used by the CPC's C0 (src/bas/cyborgos320kb) and the MSX's
' (src/bas/cyborgosmsx) when Probe finds one: Hyp's Con, Say, Scr and Inks draw here instead of on
' the machine's own screen (Main: V9.Probe, then V9.Init; NOV9990 on CyborgOS's command line
' leaves it alone).
'
' The screen: B3 - 512 x 212, 4 bits a pixel (palette 0 the paper, 1 the pen: Inks changes the
' palette, nothing is drawn again), 80 columns of 6 x 8 (84 in MODE S) in the middle. The text is
' a ring of 32 rows in image lines 0-255, shown from the vertical scroll (R#17, R#18: SCAY = the
' top row * 8, rolled at 256 lines) - 26.5 rows on the screen, the scroll a register write, as the
' CPC's CRTC and the MSX's R#23 do it. The font is drawn once into image lines 256-271 (64
' characters a line of 8) and each character on the screen is a block copy from there (LMMM);
' clearing is LMMV, the cursor an underline XORed in (LMMV, palette 0 <-> 1). A command's
' registers (R#32-R#52) are written after the one before has ended (P#5's CE), so the Z80 goes on
' while the chip draws.
'
' The routines Hyp calls (on the real stack; AF, BC, DE, HL used): v9_cell (A = character, H = the
' ring's row, L = column), v9_clrow (A = ring row), v9_clrall, v9_xcur (H, L as v9_cell), v9_top
' (A = the ring row at the screen's top), v9_cols (A = the screen's columns: the left margin),
' v9_pal (D = paper, E = pen: CPC firmware colours 0-26), v9_off (the chip's picture off); v9_on
' 1 while it is the console, v9_tr the top row (the CPC's Con keeps it; the MSX's uses Hyp's sco).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Private vsp As Integer

' Probe(): True when a V9990 answers - its R#15 (the backdrop) gives back what is written to it
Public Function Probe() As Integer
#asm
            ld ({vsp}), sp
            ld sp, (ntc_csp)
            ld hl, 0
            ld a, #15
            call v9_pr1
            jr nz, v9pb_no
            ld a, #2A
            call v9_pr1
            jr nz, v9pb_no
            dec hl                  ; True
v9pb_no:
            ld ({result}), hl
            xor a                   ; the backdrop 0 again
            ld e, 15
            call v9_reg
            ld sp, ({vsp})
            jr v9pb_end
v9_pr1:                             ; A to R#15 and read back: Z when it is the same
            ld d, a
            ld e, 15
            call v9_reg
            ld bc, #FF64
            ld a, 15
            out (c), a
            dec c
            in a, (c)
            cp d
            ret
v9pb_end:
#endasm
End Function

' Init(pal): the V9990 as the console - B3, the palette (CPC blue and bright yellow), lines 0-511
' cleared, the font drawn into lines 256-271 (the CPC: ntc_font6's copy in Hyp's window data,
' v9_f6, read from main RAM's own #4000-#7FFF; the MSX: the main ROM's own, through RDSLT), the
' picture on. pal 1: PAL (50 Hz), 0 NTSC
Public Sub Init(ByVal pal As Integer)
#asm
            ld ({vsp}), sp
            ld sp, (ntc_csp)
            ld a, ({pal})
            call v9_init
    IFDEF NTC_MSXDOS
            ld a, 32                ; the main ROM's font (CGTABL), a character at a time
v9in_ch:
            push af
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            ex de, hl               ; DE = the character * 8
            ld a, (#FCC1)
            ld hl, 4
            push de
            push af
            call #000C              ; RDSLT: CGTABL's low byte
            ld e, a
            pop af
            push de
            inc hl
            call #000C              ; its high byte
            pop de
            ld d, a
            pop hl
            add hl, de              ; the character's 8 bytes there
            ld de, v9_gb
            ld b, 8
v9in_b:
            push bc
            push de
            ld a, (#FCC1)
            push hl
            call #000C              ; RDSLT
            pop hl
            pop de
            pop bc
            ld (de), a
            inc de
            inc hl
            djnz v9in_b
            di
            pop af
            push af
            ld hl, v9_gb
            call v9_glyph
            pop af
            inc a
            cp 128
            jr nz, v9in_ch
    ELSE
            ld bc, #7FC0            ; main RAM's own #4000-#7FFF: v9_f6 (window data)
            out (c), c
            ld a, 32
            ld hl, v9_f6
v9in_ch:
            push af
            push hl
            call v9_glyph
            pop hl
            ld de, 8
            add hl, de
            pop af
            inc a
            cp 127
            jr nz, v9in_ch
            ld bc, (ntc_rampt)      ; the window's page back
            out (c), c
    ENDIF
            call v9_wait
            ld a, #C2               ; R#8: the picture on (sprites off, 512K)
            ld e, 8
            call v9_reg
            ld a, 1
            ld (v9_on), a
            ld sp, ({vsp})
            jp v9_end

; ---- the routines (Hyp's Con, Say, Scr, Inks; real stack)
@v9_on:     db 0                    ; 1: the V9990 is the console
@v9_tr:     db 0                    ; the ring's row at the screen's top (the CPC's Con)
v9_x0:      dw 16                   ; the left margin, pixels (v9_cols)
v9_gb:      ds 8                    ; (Init on the MSX: a character's 8 bytes)
v9_gx:      db 0                    ; v9_glyph: its byte in the font's line, the font's line
v9_gy:      db 0
v9_cb:      ds 21                   ; a block command's R#32-R#52
v9_rs:      db 6, #95, 8, #42, 9, 0, 13, 0, 15, 0, 16, 0, 17, 0, 18, #40, 19, 0, 20, 0
            db 21, 0, 22, 0, 23, 0, 24, 0, 25, 0, 26, 0, 27, 0, 28, 0, #FF
; v9_reg - E = a register, A = its value. HL, DE kept
@v9_reg:
            ld bc, #FF64
            out (c), e
            dec c
            out (c), a
            ret
; v9_wait - until the command running has ended (P#5 bit 0: CE)
@v9_wait:
            ld bc, #FF65
v9wt_lp:
            in a, (c)
            rra
            jr c, v9wt_lp
            ret
; v9_cmd - v9_cb to R#32-R#52 (the last: the command), once the one before has ended
v9_cmd:
            call v9_wait
            ld bc, #FF64
            ld a, 32
            out (c), a
            dec c
            ld hl, v9_cb
            ld e, 21
v9cm_lp:
            ld a, (hl)
            out (c), a
            inc hl
            dec e
            jr nz, v9cm_lp
            ret
; v9_init - A = 1 PAL, 0 NTSC: the chip reset, B3, the palette, lines 0-511 cleared (the picture off)
@v9_init:
            and 1
            rlca
            rlca
            rlca
            push af                 ; R#7: bit 3 PAL
            ld bc, #FF67
            ld a, 2                 ; P#7: reset, then on (XTAL1)
            out (c), a
            xor a
            out (c), a
            ld hl, v9_rs
v9i_lp:
            ld e, (hl)
            inc hl
            ld a, e
            cp #FF
            jr z, v9i_rd
            ld a, (hl)
            inc hl
            call v9_reg
            jr v9i_lp
v9i_rd:
            pop af
            ld e, 7
            call v9_reg
            ld de, 1 * 256 + 24     ; blue paper, bright yellow pen (the CPC's)
            call v9_pal
            ld a, 80
            call v9_cols
            xor a
            ld (v9_tr), a
            call v9_top
            ld hl, 0
            ld de, 512
            jp v9_box0
; v9_glyph - A = a character (32-127), HL = its 8 bytes (the left 6 pixels: bits 7-2): into the
; font's lines (256 + its line of 64 * 8), its 6 pixels 3 bytes (palette 1 the pen, 0 the paper)
v9_glyph:
            sub 32
            ld c, a
            and 63
            ld b, a
            add a, a
            add a, b
            ld (v9_gx), a           ; its byte: (character and 63) * 3
            ld a, c
            and 64
            rrca
            rrca
            rrca
            ld (v9_gy), a           ; its line: 0 or 8 (+ 256)
            ex de, hl
            ld a, 0
v9g_lp:
            push af
            ld hl, v9_gy
            add a, (hl)
            ld h, a
            ld a, (v9_gx)
            ld l, a
            ld bc, #FF64
            xor a
            out (c), a              ; R#0 on: the address to write at (+ #10000: line 256 on)
            dec c
            out (c), l
            out (c), h
            ld a, 1
            out (c), a
            ld a, (de)
            inc de
            ld h, a
            ld bc, #FF60
            ld l, 3
v9g_b:
            xor a
            rlc h
            jr nc, v9g_b1
            ld a, #10
v9g_b1:
            rlc h
            jr nc, v9g_b2
            or #01
v9g_b2:
            out (c), a
            dec l
            jr nz, v9g_b
            pop af
            inc a
            cp 8
            jr nz, v9g_lp
            ret
; v9_cell - A = a character, H = the ring's row, L = its column: copied from the font (LMMM)
@v9_cell:
            sub 32
            cp 96
            jr c, v9c_ok
            ld a, '?' - 32
v9c_ok:
            ld c, a
            push hl
            and 63
            ld e, a
            ld d, 0
            ld h, d
            ld l, e
            add hl, hl
            add hl, de
            add hl, hl
            ld (v9_cb), hl          ; SX = (character and 63) * 6
            ld a, c
            and 64
            rrca
            rrca
            rrca
            ld l, a
            ld h, 1
            ld (v9_cb + 2), hl      ; SY = 256 + 0 / 8
            pop hl
            call v9_dxy             ; DX, DY: the cell
            ld hl, 6
            ld (v9_cb + 8), hl      ; NX
            ld l, 8
            ld (v9_cb + 10), hl     ; NY
            ld hl, #0C00            ; ARG 0, LOP: WC = SC
            ld (v9_cb + 12), hl
            ld hl, #FFFF
            ld (v9_cb + 14), hl     ; the write mask
            ld a, #40               ; LMMM
            ld (v9_cb + 20), a
            jp v9_cmd
; v9_dxy - H = ring row, L = column: DX = the margin + L * 6, DY = H * 8
v9_dxy:
            ld a, h
            add a, a
            add a, a
            add a, a
            ld (v9_cb + 6), a
            xor a
            ld (v9_cb + 7), a
            ld e, l
            ld d, 0
            ld h, d
            ld l, e
            add hl, hl
            add hl, de
            add hl, hl
            ld de, (v9_x0)
            add hl, de
            ld (v9_cb + 4), hl
            ret
; v9_xcur - H = ring row, L = column: the cell's last line XORed (palette 0 <-> 1: the cursor)
@v9_xcur:
            call v9_dxy
            ld a, (v9_cb + 6)
            add a, 7
            ld (v9_cb + 6), a
            ld hl, 6
            ld (v9_cb + 8), hl
            ld l, 1
            ld (v9_cb + 10), hl
            ld hl, #0600            ; ARG 0, LOP: WC = SC XOR DC
            ld (v9_cb + 12), hl
            ld a, #11
            jr v9_lmmv
; v9_clrow - A = a ring row: its 8 lines the paper, the whole width
@v9_clrow:
            add a, a
            add a, a
            add a, a
            ld l, a
            ld h, 0
            ld de, 8
; v9_box0 - HL = the first line, DE = lines: the paper, the whole width (512)
v9_box0:
            ld (v9_cb + 6), hl
            ld (v9_cb + 10), de
            ld hl, 0
            ld (v9_cb + 4), hl
            ld hl, 512
            ld (v9_cb + 8), hl
            ld hl, #0C00
            ld (v9_cb + 12), hl
            xor a
; v9_lmmv - A = FC's byte (the colour in both pixels): LMMV with the rest of v9_cb as set
v9_lmmv:
            ld (v9_cb + 16), a
            ld (v9_cb + 17), a
            ld hl, #FFFF
            ld (v9_cb + 14), hl
            ld a, #20               ; LMMV
            ld (v9_cb + 20), a
            jp v9_cmd
; v9_clrall - the ring (lines 0-255) the paper
@v9_clrall:
            ld hl, 0
            ld de, 256
            jr v9_box0
; v9_top - A = the ring row at the screen's top: SCAY = A * 8 (R#17, then R#18: rolled at 256)
@v9_top:
            and 31
            add a, a
            add a, a
            add a, a
            ld e, 17
            call v9_reg
            ld a, #40
            ld e, 18
            jp v9_reg
; v9_cols - A = the screen's columns: the left margin (512 - A * 6) / 2
@v9_cols:
            ld e, a
            ld d, 0
            ld h, d
            ld l, e
            add hl, hl
            add hl, de
            ex de, hl
            ld hl, 256
            or a
            sbc hl, de
            jr nc, v9co_ok
            ld hl, 0
v9co_ok:
            ld (v9_x0), hl
            ret
; v9_pal - D = the paper, E = the pen: CPC firmware colours (0-26: 9 * green + 3 * red + blue,
; each 0-2) into palette 0 and 1
@v9_pal:
            push de
            xor a
            ld e, 14
            call v9_reg             ; R#14: palette 0, its red first
            pop de
            push de
            ld a, d
            call v9_rgb
            pop de
            ld a, e
v9_rgb:                             ; A = a firmware colour: its red, green, blue to P#1
            ld d, 0
v9rg_9:
            cp 9
            jr c, v9rg_3
            sub 9
            inc d                   ; D = green
            jr v9rg_9
v9rg_3:
            ld e, 0
v9rg_3l:
            cp 3
            jr c, v9rg_b
            sub 3
            inc e                   ; E = red, A = blue
            jr v9rg_3l
v9rg_b:
            ld bc, #FF61
            push af
            ld a, e
            call v9_lvl
            out (c), a
            ld a, d
            call v9_lvl
            out (c), a
            pop af
            call v9_lvl
            out (c), a
            ret
v9_lvl:                             ; 0, 1, 2 -> 0, 15, 31 (5 bits)
            or a
            ret z
            dec a
            ld a, 15
            ret z
            ld a, 31
            ret
; v9_off - the picture off (R#8: DISP 0 - the backdrop only)
@v9_off:
            call v9_wait
            ld a, #42
            ld e, 8
            jp v9_reg
v9_end:
#endasm
End Sub
