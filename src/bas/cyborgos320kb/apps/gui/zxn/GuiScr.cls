' GuiScr (zxn) - GUI's screen on the ZX Spectrum Next: the CPC's picture (640 x 200, 1 bit, a byte
' a cell's width) kept in GUI's own memory and shown through the tilemap, which the Next's
' console already is - 80 x 32 cells of 8 x 8, one bit a pixel (text mode).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'
' The same calls as the CPC's GuiScr (Rect, Fill, Text, Ptr) draw into a shadow picture at #8000
' (laid out as the CPC's screen: line y at #8000 + (y \ 8) * 80 + (y And 7) * #800). After each
' call the cells it touched become tiles: each cell's 8 bytes are a tile, found in a cache of the
' 256 the tilemap has (a hash table) or made a new one - a GUI's screen has a few hundred
' different cells at most (the characters, plain and inverted, the edges, the stripes). When
' the cache is full Full() says so: GUI clears it (Reset) and draws everything again.
' The tilemap and its tiles are GUI's own while it is in front, in bank 5's first page (page 10:
' the ULA screen's place - the ULA is switched off meanwhile), reached through MMU slot 6
' (#C000) for a moment; the console's are left alone in page 11, so the console's cursor and
' text don't show. Leave puts the console's registers back.
' The pointer is hardware sprite 0. The rows: the picture's 25 rows are the tilemap's 4-28.
' GUI's memory: the program to #7D00, the font #7D00-#7FFF, the picture #8000-#BFFF, (#C000-#DFFF:
' slot 6, borrowed), the tile cache #E000-#EC5F (the hash table, the tiles' copies, a flag, the
' text being drawn), the stub from #EF00.
' GUI is an Option Turbo program: interrupts are off while slot 6 is borrowed.
Option Explicit

Private hsp As Integer, adr As Integer, cx0 As Integer, cy0 As Integer, cx1 As Integer, cy1 As Integer
Private r6E As Integer, r6F As Integer, r68 As Integer, r15 As Integer, pshow As Integer
Private kx As Integer, ky As Integer, kb As Integer, c0 As Integer, c1 As Integer
Const PAPER = &H0C, PEN = &H9E    ' green screen (RRRGGGBB): green paper, pastel green ink and windows

Public Function Init() As Integer
  r6E = RegGet(&H6E) : r6F = RegGet(&H6F) : r68 = RegGet(&H68) : r15 = RegGet(&H15)
  c0 = PalGet(0) : c1 = PalGet(1)                ' the console's colours (the tilemap's 0, 1)
  FontCopy
  SpriteLoad
  kx = Inp(&HFBDF) : ky = Inp(&HFFDF)
  Init = 1
End Function

' Enter: in front - GUI's tilemap and tiles shown (cleared: the caller draws everything after)
Public Sub Enter()
  Reset
  Reg &H6F, &H0A                                 ' the tiles at bank 5 + #0A00 (page 10)
  Reg &H6E, &H00                                 ' the tilemap at bank 5 + 0 (page 10)
  Reg &H68, r68 Or &H80                          ' the ULA off (its screen is our tilemap now)
  Reg &H15, r15 Or 3                             ' sprites on, over the border
  PalSet 0, PAPER : PalSet 1, PEN                ' GUI's greens
  Reg &H1C, 2                                    ' the sprites' clip window: all of it
  Reg &H19, 0 : Reg &H19, 255 : Reg &H19, 0 : Reg &H19, 255
  pshow = 0
End Sub

' Leave: the console's registers back, the pointer hidden
Public Sub Leave()
  SpriteHide
  Reg &H6E, r6E : Reg &H6F, r6F : Reg &H68, r68 : Reg &H15, r15
  PalSet 0, c0 : PalSet 1, c1
End Sub

' the tilemap's first palette, colour i (RRRGGGBB): NextReg #43 selects it (its other bits kept), #40
' the colour, #41 its value - #43 back as it was
Private Function PalGet(ByVal i As Integer) As Integer
  Dim p As Integer
  p = RegGet(&H43)
  Reg &H43, (p And &H8F) Or &H30
  Reg &H40, i
  PalGet = RegGet(&H41)
  Reg &H43, p
End Function

Private Sub PalSet(ByVal i As Integer, ByVal v As Integer)
  Dim p As Integer
  p = RegGet(&H43)
  Reg &H43, (p And &H8F) Or &H30
  Reg &H40, i
  Reg &H41, v
  Reg &H43, p
End Sub

Public Sub Done()
End Sub

' Full(): 1 when a cell found no room among the 256 tiles since Reset (GUI draws all again)
Public Function Full() As Integer
  Full = Peek(&HEC00)
End Function

' Reset: no tiles yet but the blank one (0); the tilemap all blank; the shadow cleared
Public Sub Reset()
#asm
            ld ({hsp}), sp              ; (the real stack for the calls: SP is the thread)
            ld sp, (ntc_csp)
            ld hl, #E000                ; the hash table, the tiles' copies, the full flag (#EC00)
            ld de, #E001
            ld bc, #0C00
            ld (hl), 0
            ldir
            ld a, 1
            ld (gz_nt), a
            ld hl, #8000
            ld de, #8001
            ld bc, #3FFF
            ld (hl), 0
            ldir
            call gz_map
            ld hl, #C000                ; the tilemap (80 x 32) and tile 0 blank
            ld de, #C001
            ld bc, 80 * 32 - 1
            ld (hl), 0
            ldir
            ld hl, #CA00
            ld b, 8
gz_r0:      ld (hl), 0
            inc hl
            djnz gz_r0
            call gz_unmap
            ld sp, ({hsp})
#endasm
End Sub

' the shadow's address of byte column xb, line y
Private Sub At(ByVal xb As Integer, ByVal y As Integer)
  adr = &H8000 + (y \ 8) * 80 + (y And 7) * 2048 + xb
End Sub

Public Sub Rect(ByVal xb As Integer, ByVal y As Integer, ByVal wb As Integer, ByVal h As Integer, ByVal m As Integer, ByVal p0 As Integer, ByVal p1 As Integer)
  If wb <= 0 Or h <= 0 Then Exit Sub
  If xb + wb > 80 Then wb = 80 - xb
  If y + h > 200 Then h = 200 - y
  If wb <= 0 Or h <= 0 Then Exit Sub
  At xb, y
#asm
            ld ({hsp}), sp
            ld sp, (ntc_csp)
            ld hl, ({adr})
            ld a, ({p0})
            ld d, a
            ld a, ({p1})
            ld e, a
            ld a, ({m})
            ld c, a
            ld a, ({h})
            ld (gz_h), a
gzr_line:
            push hl
            ld a, ({wb})
            ld b, a
gzr_byte:
            ld a, (hl)
            and c
            or d
            ld (hl), a
            inc hl
            djnz gzr_byte
            ld a, d
            ld d, e
            ld e, a
            pop hl
            call gz_down
            ld a, (gz_h)
            dec a
            ld (gz_h), a
            jr nz, gzr_line
            ld sp, ({hsp})
#endasm
  cx0 = xb : cx1 = xb + wb - 1 : cy0 = y \ 8 : cy1 = (y + h - 1) \ 8
  Flush
End Sub

Public Sub Fill(ByVal xb As Integer, ByVal y As Integer, ByVal wb As Integer, ByVal h As Integer, ByVal v As Integer)
  Rect xb, y, wb, h, 0, v, v
End Sub

' Text xb, y, s, inv: the console's font (copied at Init), inverted with inv &HFF
Public Sub Text(ByVal xb As Integer, ByVal y As Integer, ByVal s As String, ByVal inv As Integer)
  Dim k As Integer, n As Integer
  n = Len(s)
  If xb + n > 80 Then n = 80 - xb
  If n <= 0 Or y > 192 Then Exit Sub
  For k = 1 To n
    Poke &HEC10 + k - 1, Asc(Mid$(s, k, 1))
  Next
  At xb, y
#asm
            ld ({hsp}), sp
            ld sp, (ntc_csp)
            ld hl, ({adr})
            ld ix, #EC10
            ld a, ({n})
            ld (gz_h), a
gzt_char:
            push hl
            ld a, (ix + 0)
            sub 32
            cp 96
            jr c, gzt_ok
            ld a, '?' - 32
gzt_ok:
            ld e, a
            ld d, 0
            ex de, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld bc, #7D00
            add hl, bc
            ex de, hl
            ld a, ({inv})
            ld c, a
            ld b, 8
gzt_line:
            ld a, (de)
            xor c
            ld (hl), a
            inc de
            call gz_down
            djnz gzt_line
            pop hl
            inc hl
            inc ix
            ld a, (gz_h)
            dec a
            ld (gz_h), a
            jr nz, gzt_char
            ld sp, ({hsp})
#endasm
  cx0 = xb : cx1 = xb + n - 1 : cy0 = y \ 8 : cy1 = (y + 7) \ 8
  If cy1 > 24 Then cy1 = 24
  Flush
End Sub

' Ptr x, y: the pointer (sprite 0) shown at x (0-639), y (0-199) if hidden, hidden if shown
Public Sub Ptr(ByVal x As Integer, ByVal y As Integer)
  If pshow Then SpriteHide : pshow = 0 : Exit Sub
  SpriteAt x \ 2, y + 32
  pshow = 1
End Sub

' Mouse: the Kempston mouse moved since the last call - MX(), MY() (pixels: x in the 640's,
' y in lines), MB() 1 while the left button is down
Public Sub Mouse()
  Dim x As Integer, y As Integer
  x = Inp(&HFBDF) : y = Inp(&HFFDF) : kb = Inp(&HFADF)
  adr = x - kx
  If adr > 127 Then adr = adr - 256
  If adr < -128 Then adr = adr + 256
  cx0 = adr
  adr = y - ky
  If adr > 127 Then adr = adr - 256
  If adr < -128 Then adr = adr + 256
  cy0 = -adr
  kx = x : ky = y
End Sub
Public Function MX() As Integer
  MX = cx0 * 2
End Function
Public Function MY() As Integer
  MY = cy0
End Function
Public Function MB() As Integer
  If (kb And 2) = 0 Then MB = 1 Else MB = 0
End Function

' ---- the tiles: each cell cx0..cx1, cy0..cy1 (rows of the picture) of the shadow to a tile
Private Sub Flush()
  If cx0 < 0 Then cx0 = 0
  If cy0 < 0 Then cy0 = 0
  If cx1 > 79 Then cx1 = 79
  If cy1 > 24 Then cy1 = 24
  If cx1 < cx0 Or cy1 < cy0 Then Exit Sub
#asm
            ld ({hsp}), sp
            ld sp, (ntc_csp)
            call gz_map
            ld a, ({cy0})
            ld (gz_cy), a
gzf_row:
            ld a, ({cx0})
            ld (gz_cx), a
gzf_cell:
            ld a, (gz_cy)               ; the cell's top byte: #8000 + cy * 80 + cx
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl                  ; * 16
            ld d, h
            ld e, l
            add hl, hl
            add hl, hl                  ; * 64
            add hl, de                  ; * 80
            ld a, (gz_cx)
            ld e, a
            ld d, #80
            add hl, de
            ld de, gz_cb                ; its 8 bytes (#800 apart) to gz_cb
            ld b, 8
gzf_g:      ld a, (hl)
            ld (de), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            djnz gzf_g
            call gz_tile                ; A = its tile
            push af
            ld a, (gz_cy)               ; the tilemap: #C000 + (cy + 4) * 80 + cx
            add a, 4
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld d, h
            ld e, l
            add hl, hl
            add hl, hl
            add hl, de
            ld a, (gz_cx)
            ld e, a
            ld d, #C0
            add hl, de
            pop af
            ld (hl), a
            ld a, (gz_cx)
            ld hl, {cx1}
            cp (hl)
            inc a
            ld (gz_cx), a
            jr c, gzf_cell
            ld a, (gz_cy)
            ld hl, {cy1}
            cp (hl)
            inc a
            ld (gz_cy), a
            jr c, gzf_row
            call gz_unmap
            jp gz_end
; gz_tile: the tile for the 8 bytes at gz_cb - A. 0 for a blank cell; else the hash table's
; (#E000, 1024 places: the tile, 0 empty - under the stub, #E000-#EEFF), its copy at #E400 + tile * 8 to
; compare; a new one: the next free (gz_nt), its bytes to #E400 and to the tiles (#CA00: slot 6
; is page 10 now). None free: 0 and the full flag (#EC00)
@gz_tile:
            ld hl, gz_cb
            ld b, 8
            xor a
gzh_z:      or (hl)
            inc hl
            djnz gzh_z
            or a
            ret z                       ; (all 8 bytes 0: tile 0)
            ld hl, gz_cb
            ld b, 8
            xor a
            ld c, a
gzh_lp:     rlca
            xor (hl)
            ld e, a
            ld a, c
            add a, (hl)
            ld c, a
            ld a, e
            inc hl
            djnz gzh_lp
            ld e, a                     ; DE = the place: A + (the sum's low 2 bits) * 256
            ld a, c
            and 3
            ld d, a
gzh_probe:
            ld hl, #E000
            add hl, de
            ld a, (hl)
            or a
            jr z, gzh_new
            ld (gz_t), a                ; compare with that tile's copy
            push hl
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            ld bc, #E400
            add hl, bc
            ld bc, gz_cb
            push de
            ld e, 8
gzh_cmp:    ld a, (bc)
            cp (hl)
            jr nz, gzh_ne
            inc hl
            inc bc
            dec e
            jr nz, gzh_cmp
            pop de
            pop hl
            ld a, (gz_t)
            ret
gzh_ne:     pop de
            pop hl
            inc de
            ld a, d
            and 3
            ld d, a
            jr gzh_probe
gzh_new:
            ld a, (gz_nt)
            or a
            jr nz, gzh_room
            ld a, 1
            ld (#EC00), a
            xor a
            ret
gzh_room:
            ld (hl), a                  ; the table's place: this tile
            ld (gz_t), a
            inc a
            ld (gz_nt), a               ; (256: 0 - full from now on)
            ld a, (gz_t)
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            push hl
            ld bc, #E400
            add hl, bc
            ex de, hl
            ld hl, gz_cb
            ld bc, 8
            ldir
            pop hl
            ld bc, #CA00
            add hl, bc
            ex de, hl
            ld hl, gz_cb
            ld bc, 8
            ldir
            ld a, (gz_t)
            ret
; gz_down: HL one pixel line down in the shadow (#800 on; past a row's 8th line back #4000, on #50)
@gz_down:
            ld a, h
            add a, 8
            ld h, a
            and #38
            ret nz
            ld a, l
            add a, #50
            ld l, a
            ld a, h
            adc a, #C0
            ld h, a
            ret
; gz_map / gz_unmap: bank 5's page 10 in MMU slot 6 (#C000), GUI's own page back
@gz_map:
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            in a, (c)
            ld (gz_m6), a
            ld a, 10
            out (c), a
            ret
@gz_unmap:
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, (gz_m6)
            out (c), a
            ret
@gz_m6:      db 0
@gz_nt:      db 1                        ; the next free tile (0 after 255: none)
@gz_t:       db 0
@gz_h:       db 0
@gz_cx:      db 0
@gz_cy:      db 0
@gz_cb:      ds 8
            ASSERT ntc_free <= #7D00, "GUI (Next) must end below #7D00 (its font copy; the shadow picture at #8000, the tile cache at #E000)"
gz_end:
            ld sp, ({hsp})
#endasm
End Sub

' FontCopy: the console's font (its tiles: bank 5 page 11, #0C00 on - character n's 8 bytes at
' n * 8) for characters 32-127 to #7D00
Private Sub FontCopy()
#asm
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            in a, (c)
            ld (gz_m6b), a
            ld a, 11
            out (c), a
            ld hl, #C000 + #0C00 + 32 * 8
            ld de, #7D00
            ld bc, 96 * 8
            ldir
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, (gz_m6b)
            out (c), a
            jr gz_fend
gz_m6b:     db 0
gz_fend:
#endasm
End Sub

' the pointer: an arrow, 16 x 16 (8 bits a pixel: #E3 see-through, 0 black, #FF white) as
' sprite pattern 0; sprite 0 hidden
Private Sub SpriteLoad()
  Dim y As Integer, x As Integer, a As String Max 16
  Out &H303B, 0
  For y = 0 To 15
    a = Mid$("X...............XX..............XWX.............XWWX............XWWWX...........XWWWWX..........XWWWWWX.........XWWWWWWX........XWWWWXXXX.......XWXWWX..........XX.XWWX.........X...XWWX............XWWX.............XX.........................................", y * 16 + 1, 16)
    For x = 1 To 16
      If Mid$(a, x, 1) = "X" Then
        Out &H5B, 0
      ElseIf Mid$(a, x, 1) = "W" Then
        Out &H5B, &HFF
      Else
        Out &H5B, &HE3
      End If
    Next
  Next
  SpriteHide
End Sub

Private Sub SpriteAt(ByVal x As Integer, ByVal y As Integer)
  Out &H303B, 0
  Out &H57, x And 255
  Out &H57, y And 255
  Out &H57, (x \ 256) And 1
  Out &H57, &H80
End Sub

Private Sub SpriteHide()
  Out &H303B, 0
  Out &H57, 0
  Out &H57, 0
  Out &H57, 0
  Out &H57, 0
End Sub

Private Sub Reg(ByVal r As Integer, ByVal v As Integer)
  Out &H243B, r
  Out &H253B, v
End Sub

Private Function RegGet(ByVal r As Integer) As Integer
  Out &H243B, r
  RegGet = Inp(&H253B)
End Function
