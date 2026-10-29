' GuiScr (cpc) - GUI's screen on the Amstrad CPC: mode 2 (640 x 200, two inks - greens: GUI's slot
' sets its own colours, which CyborgOS puts in while it is in front), drawn straight into main
' RAM's #C000 screen while GUI's slot is in front.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'
' How a slot reaches the screen (BOUNCE's way - its README, part 4): a slot runs with RAM setting
' C2 (its bank in all four 16K places); C3 puts main RAM's page 3 - the #C000 screen - at #4000
' and keeps the slot's own page 7 at #C000. So the drawing routines live in page 7 (copied to
' #E000 at the start, under the stub at #EF00) and draw through #4000-#7FFF: each switches C3 in
' at its start and the slot's own setting back before it returns. While C3 is in nothing may
' touch the stack (it's main RAM's then) and interrupts stay off: GUI is an Option Turbo program.
'
' The screen is in bytes across (80: a byte is 8 pixels, a character cell's width) and pixel
' lines down (200). Every drawing call is a rectangle of bytes changed as
'     byte = (byte AND m) OR p        p: one value for the even lines, one for the odd
' (Fill: m 0; Stripe: m 0, two p's; Mask: one pixel column - m clears it, p sets it), plus Text
' (the slot's font, #F300, 8 x 8; inverted with Inv) and Ptr (the pointer, XORed: twice = gone).
' Speed: a plain fill about 21 T a byte (LDIR: the whole screen 84 ms at 4MHz, a window 40 cells
' x 10 rows 17 ms), a masked or striped one about 41 T, a character about 400 T.
Option Explicit

Const PAPER = 9, PEN = 22        ' green screen: green (9) paper, pastel green (22) ink and windows
Private own As Integer           ' the slot's own RAM setting: port (high byte), value (C2)
Private oldMode As Integer       ' the slot's console MODE before (Done puts it back)
Private hsp As Integer
Private adr As Integer
Private hl As Integer            ' headless: a vCPC (host 4) - no CPC screen, nothing drawn here; the
                                 ' desktop goes only to RGUI (R=), its clicks and fields back from it

' Init: 0 if it can't run (the RAM setting not found), else 1
Public Function Init() As Integer
  Init = 0
  oldMode = CybSys.Ask(9, 255)
  If CybSys.Host() = 4 Then hl = 1 : Init = 1 : Exit Function   ' (a vCPC: no gate array, no #C000 screen)
  Bank
  If (own \ 256) < &H78 Or (own \ 256) > &H7F Or (own And &HC7) <> &HC2 Then Exit Function
  Install
  Doke &HE000, own
  Doke &HE002, (own And &HFFF8) Or 3        ' C3: the #C000 screen at #4000
  oldMode = CybSys.Ask(9, 255)
  Init = 1
End Function

' Enter: GUI's slot came to the front - MODE 2 (80 x 25, no status strip: the CRTC as standard,
' the screen GUI's to draw on). The caller draws everything after
Public Sub Enter()
  Poke &HF6E5, PAPER + 1 : Poke &HF6E6, PEN + 1 : Poke &HF6E7, PAPER + 1   ' (the slot's own colours:
  If CybSys.Ask(9, 0) = 0 Then                                            ' CyborgOS sets them while
  End If                                                                  ' it is in front - Hyp.Inks)
End Sub

' Leave: nothing - CyborgOS sets the CRTC and #C000 back for the slot it brings to the front
Public Sub Leave()
End Sub

' Full / Reset: the Next's tile cache (the CPC has none: never full)
Public Function Full() As Integer
  Full = 0
End Function
Public Sub Reset()
End Sub

' Done: the slot's console MODE back
Public Sub Done()
  Poke &HF6E5, 0 : Poke &HF6E6, 0 : Poke &HF6E7, 0                        ' the console's colours again
  If CybSys.Ask(9, oldMode) = 0 Then
  End If
End Sub

' Bank: own = BC after a BDOS call (CyborgOS's switch into the bank loads BC with the setting)
Private Sub Bank()
#asm
            ld ({hsp}), sp
            ld sp, (ntc_csp)
            ld c, 12
            ei
            call 5
            di
            ld ({own}), bc
            ld sp, ({hsp})
#endasm
End Sub

' Joy(): the joystick port's row of the keyboard (line 9: bit 0 up, 1 down, 2 left, 3 right, 4-6 the
' fire buttons), 1 = down - an AMX-style mouse (or the PS2Mouse adapter) is read there. Only while
' GUI is in front (the keyboard is the whole machine's); interrupts are off (Option Turbo), so the
' firmware's own scan can't come between. (The PPI's ports are #F4xx-#F7xx whatever the low byte:
' it is kept clear of NTC's harness's own stand-in ports)
Public Function Joy() As Integer
#asm
            ld bc, #F40E            ; the PSG's register 14 (the keyboard)
            out (c), c
            ld bc, #F600
            ld a, #C0               ; PSG: select the register
            out (c), a
            xor a
            out (c), a
            ld bc, #F700
            ld a, #92               ; the PPI's port A in
            out (c), a
            ld bc, #F600
            ld a, #49               ; PSG: read, keyboard line 9
            out (c), a
            ld b, #F4
            in e, (c)
            ld bc, #F700
            ld a, #82               ; port A out again
            out (c), a
            ld bc, #F600
            xor a
            out (c), a
            ld a, e
            cpl
            pop hl
            ld (hl), a
            inc hl
            ld (hl), 0
#endasm
End Function

' the screen address (in the #4000 window) of byte column xb, pixel line y
Private Sub At(ByVal xb As Integer, ByVal y As Integer)
  adr = &H4000 + (y \ 8) * 80 + (y And 7) * 2048 + xb
End Sub

' Rect xb, y, wb, h, m, p0, p1: each byte = (byte AND m) OR p (p0 on even lines from y, p1 odd)
Public Sub Rect(ByVal xb As Integer, ByVal y As Integer, ByVal wb As Integer, ByVal h As Integer, ByVal m As Integer, ByVal p0 As Integer, ByVal p1 As Integer)
  If hl Then Exit Sub                      ' (headless: nothing to draw on)
  If wb <= 0 Or h <= 0 Then Exit Sub
  At xb, y
#asm
            ld hl, ({adr})
            ld (gp_adr), hl
            ld a, ({wb})
            ld (gp_w), a
            ld a, ({h})
            ld (gp_h), a
            ld a, ({m})
            ld (gp_and), a
            ld a, ({p0})
            ld (gp_or0), a
            ld a, ({p1})
            ld (gp_or1), a
            ld ({hsp}), sp
            ld sp, (ntc_csp)
            call gp_rect
            ld sp, ({hsp})
#endasm
End Sub

Public Sub Fill(ByVal xb As Integer, ByVal y As Integer, ByVal wb As Integer, ByVal h As Integer, ByVal v As Integer)
  If hl Then Exit Sub                      ' (headless: nothing to draw on)
  Rect xb, y, wb, h, 0, v, v
End Sub

' Text xb, y, s, inv: s's characters from the slot's font (inv &HFF: paper on ink)
Public Sub Text(ByVal xb As Integer, ByVal y As Integer, ByVal s As String, ByVal inv As Integer)
  If hl Then Exit Sub                      ' (headless: nothing to draw on)
  Dim k As Integer, n As Integer
  n = Len(s)
  If xb + n > 80 Then n = 80 - xb
  If n <= 0 Then Exit Sub
  For k = 1 To n
    Poke &HE010 + k - 1, Asc(Mid$(s, k, 1))
  Next
  At xb, y
#asm
            ld hl, ({adr})
            ld (gp_adr), hl
            ld a, ({n})
            ld (gp_n), a
            ld a, ({inv})
            ld (gp_inv), a
            ld ({hsp}), sp
            ld sp, (ntc_csp)
            call gp_text
            ld sp, ({hsp})
#endasm
End Sub

' Ptr x, y: the pointer XORed at pixel x (0-639), line y (0-199) - again in the same place: gone
Public Sub Ptr(ByVal x As Integer, ByVal y As Integer)
  If hl Then Exit Sub                      ' (headless: nothing to draw on)
  Dim n As Integer, two As Integer
  n = 200 - y
  If n > 11 Then n = 11
  If n <= 0 Then Exit Sub
  two = 1
  If x \ 8 >= 79 Then two = 0
  At x \ 8, y
#asm
            ld hl, ({adr})
            ld (gp_adr), hl
            ld a, ({n})
            ld (gp_h), a
            ld a, ({two})
            ld (gp_two), a
            ld a, ({x})
            and 7
            ld (gp_sh), a
            ld ({hsp}), sp
            ld sp, (ntc_csp)
            call gp_ptr
            ld sp, ({hsp})
#endasm
End Sub

' Install: the routines to #E000 (in the slot's page 7: seen in C2 and C3 alike)
Private Sub Install()
#asm
            ld hl, gp_src
            ld de, #E000
            ld bc, gp_after - gp_src
            ldir
            jp gp_end
@gp_src:
            DISP #E000
@gp_own:    dw 0                    ; #E000 the slot's own RAM setting (B port, C value)
@gp_win:    dw 0                    ; #E002 C3: the #C000 screen at #4000
@gp_adr:    dw 0                    ; #E004 the rectangle's / text's first byte (in the window)
@gp_w:      db 0                    ; #E006 bytes across
@gp_h:      db 0                    ; #E007 lines
@gp_and:    db 0                    ; #E008
@gp_or0:    db 0                    ; #E009 even lines
@gp_or1:    db 0                    ; #E00A odd lines
@gp_inv:    db 0                    ; #E00B text: XORed into each byte
@gp_n:      db 0                    ; #E00C characters
@gp_sh:     db 0                    ; #E00D the pointer: bits right
@gp_two:    db 0                    ; #E00E the pointer: 1 two bytes a line, 0 one (the right edge)
@gp_lin:    db 0                    ; #E00F (a line's start: the low byte here, the high in gp_buf - 1)
@gp_buf:    ds 80                   ; #E010 the text
@gp_lin2:   dw 0
@gp_shape:  db #80, #C0, #E0, #F0, #F8, #FC, #FE, #F8, #D8, #8C, #0C   ; the pointer, 11 lines
; gp_rect: gp_adr, gp_w, gp_h, gp_and, gp_or0 / gp_or1
@gp_rect:
            ld bc, (gp_win)
            out (c), c
            ld hl, (gp_adr)
            ld a, (gp_and)          ; a plain fill (m 0, the same value on every line): LDIR,
            or a                    ; about 21 T a byte instead of 41
            jr nz, gr_slow
            ld a, (gp_or1)
            ld d, a
            ld a, (gp_or0)
            cp d
            jr nz, gr_slow
gr_fl:
            ld (gp_lin2), hl
            ld a, (gp_or0)
            ld (hl), a
            ld a, (gp_w)
            dec a
            jr z, gr_fn
            ld c, a
            ld b, 0
            ld d, h
            ld e, l
            inc de
            ldir
gr_fn:
            ld hl, (gp_lin2)
            ld a, h
            add a, 8
            ld h, a
            and #38
            jr nz, gr_fok
            ld a, l
            add a, #50
            ld l, a
            ld a, h
            adc a, #C0
            ld h, a
gr_fok:
            ld a, (gp_h)
            dec a
            ld (gp_h), a
            jr nz, gr_fl
            ld bc, (gp_own)
            out (c), c
            ret
gr_slow:
            ld a, (gp_or0)
            ld d, a
            ld a, (gp_or1)
            ld e, a
            ld a, (gp_and)
            ld c, a
gr_line:
            ld (gp_lin2), hl
            ld a, (gp_w)
            ld b, a
gr_byte:
            ld a, (hl)
            and c
            or d
            ld (hl), a
            inc hl
            djnz gr_byte
            ld a, d                 ; the other line's value next
            ld d, e
            ld e, a
            ld hl, (gp_lin2)
            ld a, h                 ; the next pixel line: #800 on; past a character row's
            add a, 8                ; 8th line back #4000 and on #50
            ld h, a
            and #38
            jr nz, gr_ok
            ld a, l
            add a, #50
            ld l, a
            ld a, h
            adc a, #C0
            ld h, a
gr_ok:
            ld a, (gp_h)
            dec a
            ld (gp_h), a
            jr nz, gr_line
            ld bc, (gp_own)
            out (c), c
            ret
; gp_text: gp_n characters from gp_buf at gp_adr, each byte XOR gp_inv
@gp_text:
            ld bc, (gp_win)
            out (c), c
            ld hl, (gp_adr)
            ld ix, gp_buf
gt_char:
            ld (gp_lin2), hl
            ld a, (ix + 0)
            sub 32
            cp 96
            jr c, gt_ok
            ld a, '?' - 32
gt_ok:
            ld e, a                 ; DE = the font: #F300 + (c - 32) * 8
            ld d, 0
            ex de, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld bc, #F300
            add hl, bc
            ex de, hl
            ld a, (gp_inv)
            ld c, a
            ld b, 8
gt_line:
            ld a, (de)
            xor c
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            and #38
            jr nz, gt_lok
            ld a, l
            add a, #50
            ld l, a
            ld a, h
            adc a, #C0
            ld h, a
gt_lok:
            djnz gt_line
            ld hl, (gp_lin2)
            inc hl
            inc ix
            ld a, (gp_n)
            dec a
            ld (gp_n), a
            jr nz, gt_char
            ld bc, (gp_own)
            out (c), c
            ret
; gp_ptr: the pointer XORed: gp_h lines from gp_adr, gp_sh bits right, gp_two
@gp_ptr:
            ld bc, (gp_win)
            out (c), c
            ld hl, (gp_adr)
            ld ix, gp_shape
gp_pl:
            ld a, (gp_sh)
            ld b, a
            ld a, (ix + 0)
            ld e, 0
            inc b
            dec b
            jr z, gp_p0
gp_ps:
            srl a
            rr e
            djnz gp_ps
gp_p0:
            xor (hl)
            ld (hl), a
            ld a, (gp_two)
            or a
            jr z, gp_p1
            inc hl
            ld a, e
            xor (hl)
            ld (hl), a
            dec hl
gp_p1:
            ld a, h
            add a, 8
            ld h, a
            and #38
            jr nz, gp_pok
            ld a, l
            add a, #50
            ld l, a
            ld a, h
            adc a, #C0
            ld h, a
gp_pok:
            inc ix
            ld a, (gp_h)
            dec a
            ld (gp_h), a
            jr nz, gp_pl
            ld bc, (gp_own)
            out (c), c
            ret
            ENT
@gp_after:
            ASSERT ntc_free <= #E000, "GUI's program and arrays must end below #E000 (the drawing code's place)"
            ASSERT gp_after - gp_src <= #EF00 - #E000, "GUI's drawing code must end below the stub (#EF00)"
@gp_end:
#endasm
End Sub
