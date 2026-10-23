' L2 - Layer 2 for the backdrops: 256 x 192, one byte a pixel (RRRGGGBB colours), bank 16 (pages
' 32-37, each 32 lines, put in at #C000 through MMU slot 6 while drawing, then bank 5's page 10
' back). Behind the tilemap and the sprites. As a CyborgOS task its three banks are its own, from
' the hypervisor (Nx.LoadCity, Nx.L2Bank: bank 16 is CyborgOS's), patched into the routines here
' and in World.cls (l2pg_a - l2pg_d).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit

Private sc As Integer, sw As Integer, fa As Integer

' Init: Layer 2 on, 256 x 192, no scroll, the whole of it
Public Sub Init()
  Nx.Reg &H70, 0
#If NTC_ZXN Then
  Nx.Reg &H12, 16
#Else
  Nx.Reg &H12, Nx.L2Bank()                      ' (a CyborgOS task: its own three banks - Nx.LoadCity)
#End If
  Nx.Reg &H1C, 1
  Nx.Reg &H18, 0 : Nx.Reg &H18, 255 : Nx.Reg &H18, 0 : Nx.Reg &H18, 191
  Nx.Reg &H16, 0 : Nx.Reg &H17, 0
  Out &H123B, 2
End Sub

' Span x, y, w, c: w pixels (1-256, not past the right edge) of colour c from x, y
Public Sub Span(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal c As Integer)
#asm
            pop hl
            ld e, (hl)              ; x
            pop hl
            ld d, (hl)              ; y
            pop hl
            ld c, (hl)
            inc hl
            ld b, (hl)              ; w
            ld ({sw}), bc
            pop hl
            ld a, (hl)
            ld ({sc}), a            ; colour
            ld a, d
            rlca
            rlca
            rlca
            and 7
@l2pg_a: add a, 32           ; (Layer 2's first 8K page; a CyborgOS task: its own, LoadCity patches it)
            ld h, a                 ; the page: 32 + y / 32
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, h
            out (c), a
            ld a, d
            and 31
            or #C0
            ld h, a
            ld l, e                 ; HL = #C000 + (y And 31) * 256 + x
            ld bc, ({sw})
            ld a, b
            or c
            jr z, l2_back
            ld a, ({sc})
            ld (hl), a
            dec bc
            ld a, b
            or c
            jr z, l2_back
            ld d, h
            ld e, l
            inc de
            ldir
l2_back:
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
#endasm
End Sub

' Rect x, y, w, h, c: a block
Public Sub Rect(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer, ByVal c As Integer)
  Dim j As Integer
  For j = y To y + h - 1
    Span x, j, w, c
  Next
End Sub

' Plot x, y, c: one pixel
Public Sub Plot(ByVal x As Integer, ByVal y As Integer, ByVal c As Integer)
  If x >= 0 And x < 256 And y >= 0 And y < 192 Then Span x, y, 1, c
End Sub

' Big x, y, s, z, c1, c2: text s drawn z times the size, colour c1 on top shading to c2, with a
' dark shadow (colour 0) two pixels down and right. The letters are read from the tilemap's font
' (tiles 32-95 at #C000, 4 bits a pixel: colour 1 is the letter)
Public Sub Big(ByVal x As Integer, ByVal y As Integer, ByVal s As String, ByVal z As Integer, ByVal c1 As Integer, ByVal c2 As Integer)
  Dim k As Integer, r As Integer, b As Integer, i As Integer, run As Integer, a As Integer, col As Integer, pass As Integer, sh As Integer, m As Integer, v As Integer
  For pass = 0 To 1
    sh = (1 - pass) * 2
    For k = 1 To Len(s)
      a = &HC000 + Asc(Mid$(s, k, 1)) * 32
      For r = 0 To 7
        b = 0 : m = 128
        For i = 0 To 3
          v = Peek(a + r * 4 + i)
          If (v \ 16) = 1 Then b = b Or m
          If (v And 15) = 1 Then b = b Or (m \ 2)
          m = m \ 4
        Next
        col = 0
        If pass Then
          col = c2
          If r < 4 Then col = c1
        End If
        i = 0
        Do While b
          If b And 128 Then
            run = 0
            Do While b And 128
              run = run + 1 : b = (b * 2) And 255
            Loop
            Rect x + ((k - 1) * 8 + i) * z + sh, y + r * z + sh, run * z, z, col
            i = i + run
          Else
            i = i + 1 : b = (b * 2) And 255
          End If
        Loop
      Next
    Next
  Next
End Sub

' Tint x, y, w, h: the pixels in that box a shade warmer (red and green up a step: a marked
' block), not past the screen's edges
Public Sub Tint(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer)
#asm
            pop hl
            ld a, (hl)
            ld (tn_x + 1), a
            pop hl
            ld a, (hl)
            ld ({fa}), a            ; y
            pop hl
            ld a, (hl)
            ld (tn_w + 1), a
            pop hl
            ld a, (hl)
            ld ({sw}), a            ; h
tn_row:
            ld a, ({fa})
            ld d, a
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, d
            rlca
            rlca
            rlca
            and 7
@l2pg_b: add a, 32           ; (Layer 2's first 8K page; a CyborgOS task: its own, LoadCity patches it)
            out (c), a
            ld a, d
            and 31
            or #C0
            ld h, a
tn_x:
            ld l, 0
tn_w:
            ld b, 0
tn_px:
            ld a, (hl)
            ld c, a
            and #E0
            cp #E0
            jr z, tn_g
            ld a, c
            add a, #20
            ld c, a
tn_g:
            ld a, c
            and #1C
            cp #1C
            jr z, tn_put
            ld a, c
            add a, 4
            ld c, a
tn_put:
            ld a, c
            cp #E3
            jr nz, tn_ok
            dec a
tn_ok:
            ld (hl), a
            inc l
            djnz tn_px
            ld hl, {fa}
            inc (hl)
            ld hl, {sw}
            dec (hl)
            jr nz, tn_row
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
#endasm
End Sub
