' World - LITTLE SEOUL's screens on Layer 2: 16 x 12 blocks of 16 x 16 pixels, each block a 256-byte
' picture in the Next's other RAM (tools/blocks.py), 32 to an 8K page from Init's page on. Drawing
' puts Layer 2's page in MMU slot 6 and a block's page in slot 7, then bank 5 back (10, 11).
' Also the map: a screen drawn as 16 x 12 dots, a dot a block (its colour from a table).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit

Private bpg As Integer, rr As Integer, cc As Integer, kk As Integer, dst As Integer, dp As Integer, tb As Integer

' Init page: the blocks start at 8K page page
Public Sub Init(ByVal page As Integer)
  bpg = page
End Sub

' Draw a: the screen whose 192 block numbers are at address a (rows of 16)
Public Sub Draw(ByVal a As Integer)
#asm
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld ({dp}), de
            xor a
            ld ({rr}), a
dr_row:
            ld a, ({rr})            ; Layer 2's page for this row of blocks: 32 + row / 2
            srl a
@l2pg_c: add a, 32           ; (Layer 2's first 8K page; a CyborgOS task: its own, LoadCity patches it)
            ld e, a
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            out (c), e
            xor a
            ld ({cc}), a
dr_cell:
            ld hl, ({dp})
            ld a, (hl)
            inc hl
            ld ({dp}), hl
            ld e, a                 ; E = the block
            rlca                    ; its page: bpg + block / 32
            rlca
            rlca
            and 7
            ld d, a
            ld a, ({bpg})
            add a, d
            ld d, a
    IFNDEF NTC_ZXN
            ld h, #BF               ; (task: the block's page from the page table)
            ld l, d
            ld d, (hl)
    ENDIF
            ld bc, #243B
            ld a, #57
            out (c), a
            inc b
            out (c), d
            ld a, e                 ; HL = #E000 + (block and 31) * 256
            and 31
            add a, #E0
            ld h, a
            ld l, 0
            ld a, ({rr})            ; the place: #C000 + (row and 1) * #1000 + column * 16
            and 1
            rlca
            rlca
            rlca
            rlca
            add a, #C0
            ld ({dst} + 1), a
            ld a, ({cc})
            rlca
            rlca
            rlca
            rlca
            ld ({dst}), a
            ld a, 16
            ld ({kk}), a
dr_line:
            ld de, ({dst})
            ld bc, 16
            ldir
            ld a, ({dst} + 1)
            inc a
            ld ({dst} + 1), a
            ld a, ({kk})
            dec a
            ld ({kk}), a
            jr nz, dr_line
            ld a, ({cc})
            inc a
            ld ({cc}), a
            cp 16
            jr nz, dr_cell
            ld a, ({rr})
            inc a
            ld ({rr}), a
            cp 12
            jp nz, dr_row
            ld bc, #243B            ; bank 5 back in slots 6 and 7
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
            dec b
            ld a, #57
            out (c), a
            inc b
    IFDEF NTC_ZXN
            ld a, 11
    ELSE
            ld a, (ls_h7)           ; (task: its own page back in slot 7)
    ENDIF
            out (c), a
#endasm
End Sub

' Mini a, t, x, y: the screen whose blocks are at a as 16 x 12 dots at x, y on Layer 2 (y + 11 below
' 192), each dot the colour in table t (256 bytes: a block's colour)
Public Sub Mini(ByVal a As Integer, ByVal t As Integer, ByVal x As Integer, ByVal y As Integer)
#asm
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld ({dp}), de
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld ({tb}), de
            pop hl
            ld a, (hl)
            ld ({cc}), a            ; x
            pop hl
            ld a, (hl)
            ld ({rr}), a            ; y
            ld a, 12
            ld ({kk}), a
mi_row:
            ld a, ({rr})            ; the row's page (32 + y / 32) in slot 6
            rlca
            rlca
            rlca
            and 7
@l2pg_d: add a, 32           ; (Layer 2's first 8K page; a CyborgOS task: its own, LoadCity patches it)
            ld e, a
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            out (c), e
            ld a, ({rr})
            and 31
            add a, #C0
            ld d, a
            ld a, ({cc})
            ld e, a                 ; DE = the first dot
            ld b, 16
mi_dot:
            ld hl, ({dp})
            ld a, (hl)
            inc hl
            ld ({dp}), hl
            ld hl, ({tb})
            add a, l
            ld l, a
            ld a, 0
            adc a, h
            ld h, a
            ld a, (hl)
            ld (de), a
            inc e
            djnz mi_dot
            ld a, ({rr})
            inc a
            ld ({rr}), a
            ld a, ({kk})
            dec a
            ld ({kk}), a
            jr nz, mi_row
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
#endasm
End Sub
