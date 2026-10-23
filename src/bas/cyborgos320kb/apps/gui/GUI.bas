' GUI - CyborgOS's GUI service (GUISVC): windows, buttons, check boxes, labels, text fields and
' gauges that programs in other slots create and read through the port GUI, drawn on the screen
' while GUI's slot is in front, worked with the mouse (and the keyboard).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'
'   RUN 2 GUI [MP | MP2 | SF | AMX | KEYS]     the CPC's mouse: MultiPlay port A / B, the
'                                              SYMBiFACE's PS/2, an AMX-style mouse (or the PS2Mouse
'                                              adapter) on the joystick port; KEYS none (the keys only).
'                                              The default: MP2. The Next: the Kempston mouse (KEYS: none)
'   RUN 2 GUI ... R=host[:port]/path           CPC: a remote head too (RGUI) - the model on a VDU
'                                              screen (tools/vdu's vdu.php, NET M4 first): GUI
'                                              prints rgui.html's address; any number of browsers
'                                              show it and work it
'   then Control + 2 for the screen. A program in another slot makes its window: GuiCli.cls.
'
' X Windows' split: GUI holds the model (every object and its value) and draws it - a head; the
' programs only say what they want and read values back, like RAT's callers. A value is a state,
' not an event: a button counts its clicks, a check box is 0 / 1, a field holds its text - so a
' busy program loses nothing, it reads the state when it can (Q: the ids changed since it last
' asked). A remote head (RGUI: a browser on another monitor) reads the same model.
'
' The port's messages (128 characters at most; numbers in cells: 80 x 25 on the CPC's screen):
'   W x y w h title     a window          -> its id          (h: rows, the title bar one of them)
'   B win x y text      a button          -> id   value: clicks
'   C win x y text      a check box       -> id   value: 0 / 1
'   L win x y text      a label           -> id
'   T win x y w text    a text field      -> id   value: Return pressed in it (count); text: its text
'   G win x y w n       a gauge (0-100)   -> id
'   R win x y a|b|c     a cycle           -> id   value: the choice shown (0 ...); text: all of them
'   P win x y w max n   a slider          -> id   value: 0-max
'   V win x y w h       a list, h rows    -> id   value: the row picked (-1 none); text: its item
'   I list text         an item at the list's end -> its id
'   S id text           its text set; V id n its value set (V on a control: not a list) -> 0
'                       (the same text / value again: nothing drawn, nothing sent)
'   ? id                -> "value text"
'   Q                   -> the ids of this program's objects changed by the user since its last Q
'   X id                a window closed (with what is in it), or one object -> 0
'   (a window's own value: 1 when its close gadget was clicked - the program decides: X it)
' Children are placed in their window's inside (x, y from its top left under the title bar).
' An object's owner is the slot that made it; a slot whose program has gone loses its objects.
Option Explicit
Option Turbo

Const MAXO = 63
Const KW = 1, KB = 2, KC = 3, KL = 4, KT = 5, KG = 6     ' the kinds
Const KR = 7, KP = 8, KV = 9, KI = 10                    ' cycle, slider, list, a list's item
Dim ty(MAXO) As Integer, pw(MAXO) As Integer, ox(MAXO) As Integer, oy(MAXO) As Integer
Dim ow(MAXO) As Integer, oh(MAXO) As Integer, va(MAXO) As Integer, cg(MAXO) As Integer
Dim own(MAXO) As Integer, tx(MAXO) As String Max 40
Dim ex(MAXO) As Integer                            ' a slider's top value, a list's first row shown
#If HEADZXN Then
#Else
' RGUI, the remote head (the CPC's, over the M4: tools/vdu's server, rgui.html in a browser)
Dim rg As Integer, rb As String Max 80, rid As String Max 16, rkey As String Max 16
Dim ob As String Max 200, tfl As Integer, tev As Integer, evc As Integer, evp As Integer
Dim hb(1023) As Byte, hl As String Max 255
#End If
Dim zo(15) As Integer, nz As Integer               ' the windows, back to front
Dim msg As String Max 128, rp As String Max 128, a As String Max 120, mo As String Max 8
Dim i As Integer, j As Integer, k As Integer, r As Integer, me As Integer, fr As Integer, shown As Integer
Dim px As Integer, py As Integer, pon As Integer, bt As Integer, lb As Integer, fo As Integer
Dim mp As Integer, ps As Integer, tpurge As Integer, dx As Integer, dy As Integer, drag As Integer
Dim gx As Integer, gy As Integer, quit As Integer, amx As Integer, dsl As Integer

#If HEADZXN Then
If CybSys.Host() <> 1 Then Print "GUI: this build is the Next's" : End
#Else
If CybSys.Host() <> 0 Then Print "GUI: this build is the CPC's" : End
#End If
me = MySlot()
a = Trim$(CybSys.Tail()) + " "                    ' the words: the mouse, R=server/path (RGUI)
mo = ""
Do While a <> " " And a <> ""
  i = InStr(a, " ")
#If HEADZXN Then
  mo = UCase$(Left$(a, i - 1))
#Else
  If UCase$(Left$(a, 2)) = "R=" Then rb = "http://" + Mid$(a, 3, i - 3) Else mo = UCase$(Left$(a, i - 1))
#End If
  a = Trim$(Mid$(a, i + 1)) + " "
Loop
If System.CommandLine() = "?" Then mo = ""          ' (CybSys.Tail needs it linked)
#If HEADZXN Then
If mo = "" Then mo = "KEMP"
#Else
If mo = "" Then mo = "MP2"
#End If
r = CybSys.PortOpen("GUI")
If r <> 0 Then Print "GUI: the port GUI is taken (another GUI?)" : End
If GuiScr.Init() = 0 Then Print "GUI: this slot's RAM setting not found" : End
For i = 0 To MAXO : ty(i) = 0 : Next
nz = 0 : fo = -1 : px = 320 : py = 100 : pon = 0 : shown = 0 : drag = -1 : dsl = -1
Print "GUI: the port GUI is open - Control +"; me; "for the screen. Mouse: "; mo; ". Q in the menu strip quits"
tpurge = CybSys.Clock()
#If HEADZXN Then
#Else
If rb <> "" Then RNew
#End If

Do
  r = CybSys.PortGet("GUI")
  If r = 0 Then
    msg = CybSys.PortMessage()
    rp = Handle(msg, CybSys.PortCaller())
    r = CybSys.PortReply("GUI", rp)
  End If
  fr = Front()
  If fr Then
    If shown = 0 Then
      GuiScr.Enter
      Locate 80, 25                                ' (the console's cursor to its last cell: it
      DrawAll                                      ' flashes there, out of the way)
      shown = 1
    End If
    Mouse
    Keys
  ElseIf shown Then
    GuiScr.Leave : shown = 0 : pon = 0
  End If
  If CybSys.Clock() - tpurge > 600 Then Purge : tpurge = CybSys.Clock()
#If HEADZXN Then
#Else
  If rg Then
    If ob <> "" And CybSys.Clock() - tfl > 60 Then Flush         ' (the changes: 0.2 s's at a time)
    If CybSys.Clock() - tev > 300 Then Events                     ' (the browsers' clicks: every 1 s)
  End If
#End If
Loop Until quit

If shown Then GuiScr.Leave
GuiScr.Done
r = CybSys.PortClose("GUI")
Print "GUI: closed"
End

' ---- the port's messages
Function Handle(ByVal m As String, ByVal c As Integer) As String
  Dim cmd As String Max 1, w As Integer, n As Integer, k As Integer, t As String Max 40
  Handle = "?"
  ps = 2
  cmd = UCase$(Left$(m, 1))
  If cmd = "Q" Then
    Handle = ""
    For n = 0 To MAXO
      If ty(n) <> 0 And own(n) = c And cg(n) <> 0 Then
        cg(n) = 0
        If Len(Handle) < 120 Then Handle = Handle + Str$(n)
      End If
    Next
    Handle = Trim$(Handle)
    Exit Function
  End If
  If cmd = "W" Then
    n = Free()
    If n < 0 Or nz > 15 Then Exit Function
    ty(n) = KW : pw(n) = -1 : own(n) = c : va(n) = 0 : cg(n) = 0
    ox(n) = Num(m) : oy(n) = Num(m) : ow(n) = Num(m) : oh(n) = Num(m) : tx(n) = Rest(m)
    If ow(n) < 6 Then ow(n) = 6
    If oh(n) < 2 Then oh(n) = 2
    If ox(n) + ow(n) > 80 Then ox(n) = 80 - ow(n)
    If oy(n) < 1 Then oy(n) = 1
    If oy(n) + oh(n) > 25 Then oy(n) = 25 - oh(n)
    zo(nz) = n : nz = nz + 1
    Sync n : Order
    If shown Then PtrOff : DrawWins : PtrOn
    Handle = Str$(n) : Handle = Trim$(Handle)
    Exit Function
  End If
  If cmd = "I" Then                                 ' a list's item
    w = Num(m)
    If w < 0 Or w > MAXO Then Exit Function
    If ty(w) <> KV Then Exit Function
    n = Free()
    If n < 0 Then Exit Function
    ty(n) = KI : pw(n) = w : own(n) = c : cg(n) = 0 : tx(n) = Rest(m)
    va(n) = 0                                       ' (its place: after the others)
    For k = 0 To MAXO
      If ty(k) = KI And pw(k) = w And k <> n Then va(n) = va(n) + 1
    Next
    Sync n
    Redraw w
    Handle = Trim$(Str$(n))
    Exit Function
  End If
  If cmd = "V" Then                                 ' V id n on a control (not a window): its value
    w = Num(m) : ps = 2
    If w >= 0 And w <= MAXO Then
      If ty(w) <> 0 And ty(w) <> KW Then cmd = "="
    End If
  End If
  If InStr("RPV", cmd) > 0 Then
    w = Num(m)
    If w < 0 Or w > MAXO Then Exit Function
    If ty(w) <> KW Then Exit Function
    n = Free()
    If n < 0 Then Exit Function
    ty(n) = InStr("RPV", cmd) + 6 : pw(n) = w : own(n) = c : va(n) = 0 : cg(n) = 0 : ex(n) = 0
    ox(n) = Num(m) : oy(n) = Num(m) : oh(n) = 1 : tx(n) = ""
    If cmd = "R" Then
      tx(n) = Rest(m) : ow(n) = 0
      For k = 0 To Count(tx(n)) - 1
        If Len(Opt(tx(n), k)) > ow(n) Then ow(n) = Len(Opt(tx(n), k))
      Next
      ow(n) = ow(n) + 4
    ElseIf cmd = "P" Then
      ow(n) = Num(m) : ex(n) = Num(m) : va(n) = Num(m)
      If ex(n) < 1 Then ex(n) = 1
      If ow(n) < 3 Then ow(n) = 3
    Else
      ow(n) = Num(m) : oh(n) = Num(m) : va(n) = -1
      If oh(n) < 1 Then oh(n) = 1
    End If
    Sync n
    If shown Then PtrOff : DrawObj n : PtrOn
    Handle = Trim$(Str$(n))
    Exit Function
  End If
  If InStr("BCLTG", cmd) > 0 Then
    w = Num(m)
    If w < 0 Or w > MAXO Then Exit Function
    If ty(w) <> KW Then Exit Function
    n = Free()
    If n < 0 Then Exit Function
    ty(n) = InStr("BCLTG", cmd) + 1 : pw(n) = w : own(n) = c : va(n) = 0 : cg(n) = 0
    ox(n) = Num(m) : oy(n) = Num(m) : ow(n) = 0 : oh(n) = 1
    If cmd = "T" Or cmd = "G" Then ow(n) = Num(m)
    If cmd = "G" Then va(n) = Num(m) : tx(n) = "" Else tx(n) = Rest(m)
    If cmd = "B" Then ow(n) = Len(tx(n)) + 2
    If cmd = "C" Then ow(n) = Len(tx(n)) + 2
    If cmd = "L" Then ow(n) = Len(tx(n))
    Sync n
    If shown Then PtrOff : DrawObj n : PtrOn
    Handle = Str$(n) : Handle = Trim$(Handle)
    Exit Function
  End If
  n = Num(m)
  If n < 0 Or n > MAXO Then Exit Function
  If ty(n) = 0 Then Exit Function
  If cmd = "S" Then                                 ' (the same text again: nothing to draw or send)
    t = Rest(m)
    If t <> tx(n) Then
      tx(n) = t
      If ty(n) = KL And Len(tx(n)) > ow(n) Then ow(n) = Len(tx(n))
      Redraw n
    End If
    Handle = "0"
  ElseIf cmd = "=" Then
    k = Num(m)
    If k <> va(n) Then va(n) = k : Redraw n
    Handle = "0"
  ElseIf cmd = "?" Then
    If ty(n) = KR Then
      Handle = Trim$(Str$(va(n))) + " " + Opt(tx(n), va(n))   ' (a cycle: the choice shown)
    Else
      Handle = Trim$(Str$(va(n))) + " " + tx(n)
    End If
  ElseIf cmd = "X" Then
    Close n : Handle = "0"
  End If
End Function

' the next number in m (from ps), -1 if none
Function Num(ByVal m As String) As Integer
  Dim v As Integer, ngv As Integer, ch As Integer, got As Integer
  Do While ps <= Len(m)
    If Mid$(m, ps, 1) <> " " Then Exit Do
    ps = ps + 1
  Loop
  v = 0 : ngv = 0 : got = 0
  If ps <= Len(m) Then
    If Mid$(m, ps, 1) = "-" Then ngv = 1 : ps = ps + 1
  End If
  Do While ps <= Len(m)
    ch = Asc(Mid$(m, ps, 1))
    If ch < 48 Or ch > 57 Then Exit Do
    v = v * 10 + ch - 48 : got = 1 : ps = ps + 1
  Loop
  If ngv Then v = -v
  If got = 0 Then v = -1
  Num = v
End Function

' the rest of m (from ps, its first space skipped), 40 characters at most
Function Rest(ByVal m As String) As String
  If ps <= Len(m) Then
    If Mid$(m, ps, 1) = " " Then ps = ps + 1
  End If
  Rest = Left$(Mid$(m, ps), 40)
End Function

Function Free() As Integer
  Dim n As Integer
  Free = -1
  For n = 0 To MAXO
    If ty(n) = 0 Then Free = n : Exit Function
  Next
End Function

' an object (a window: with its children) gone
Sub Close(ByVal n As Integer)
  Dim k As Integer, z As Integer
  Emit "X" + Str$(n)
  If ty(n) = KW Then
    For k = 0 To MAXO
      If ty(k) <> 0 And pw(k) = n Then ty(k) = 0
    Next
    z = 0
    For k = 0 To nz - 1
      If zo(k) <> n Then zo(z) = zo(k) : z = z + 1
    Next
    nz = z
    If fo >= 0 Then
      If ty(fo) = 0 Then fo = -1
    End If
    ty(n) = 0
    If shown Then PtrOff : DrawAll : PtrOn
  Else
    z = ty(n) : ty(n) = 0
    If fo = n Then fo = -1
    If shown And z <> KI Then PtrOff : DrawWin pw(n) : PtrOn
  End If
  For k = 0 To MAXO                                  ' a list's items go with it
    If ty(k) = KI Then
      If ty(pw(k)) = 0 Then ty(k) = 0
    End If
  Next
End Sub

' Count(s): the choices in "a|b|c"; Opt(s, i): choice i
Function Count(ByVal s As String) As Integer
  Dim k As Integer
  Count = 1
  For k = 1 To Len(s)
    If Mid$(s, k, 1) = "|" Then Count = Count + 1
  Next
End Function

Function Opt(ByVal s As String, ByVal i As Integer) As String
  Dim k As Integer
  s = s + "|"
  For k = 1 To i
    s = Mid$(s, InStr(s, "|") + 1)
  Next
  Opt = Left$(s, InStr(s, "|") - 1)
End Function

' Item(l, i): the id of list l's item at place i (-1 none)
Function Item(ByVal l As Integer, ByVal i As Integer) As Integer
  Dim k As Integer
  Item = -1
  For k = 0 To MAXO
    If ty(k) = KI Then
      If pw(k) = l And va(k) = i Then Item = k : Exit Function
    End If
  Next
End Function

' the windows of slots whose program has gone
Sub Purge()
  Dim k As Integer, s As Integer
  k = 0
  Do While k < nz
    s = own(zo(k))
    If CybSys.Ask(0, s) = 0 Then
    End If
    If CybSys.ByteAt(2) <> 2 Then
      Close zo(k)
    Else
      k = k + 1
    End If
  Loop
End Sub

' ---- drawing (cells: 8 x 8 pixels; the CPC's mode 2 - a byte is a cell's width)
Sub DrawAll()
  Dim k As Integer
  For k = 1 To 2
    GuiScr.Rect 0, 0, 80, 200, 0, 0, 0               ' the desktop: paper
    Menu
    DrawWins
    If GuiScr.Full() = 0 Then Exit For
    GuiScr.Reset                                     ' (the Next: its tiles ran out - again from none)
  Next
  pon = 0 : PtrOn
End Sub

Sub Menu()
  GuiScr.Fill 0, 0, 80, 8, &HFF
  GuiScr.Text 1, 0, "CyborgOS  GUI   Q quits", &HFF
  GuiScr.Fill 0, 8, 80, 1, 0
End Sub

Sub DrawWins()
  Dim k As Integer
  For k = 0 To nz - 1
    DrawWin zo(k)
  Next
End Sub

' window w: ink inside, the title bar striped when it is the front one
Sub DrawWin(ByVal w As Integer)
  Dim x As Integer, y As Integer, cw As Integer, ch As Integer, k As Integer, act As Integer
  If w < 0 Then Exit Sub
  If ty(w) <> KW Then Exit Sub
  x = ox(w) : y = oy(w) * 8 : cw = ow(w) : ch = oh(w) * 8
  act = 0
  If nz > 0 Then
    If zo(nz - 1) = w Then act = 1
  End If
  GuiScr.Fill x, y, cw, ch, &HFF
  If act Then GuiScr.Rect x, y + 1, cw, 6, 0, 0, &HFF
  GuiScr.Fill x, y, cw, 1, 0                          ' the top edge
  GuiScr.Fill x, y + 7, cw, 1, 0                      ' under the title bar
  GuiScr.Fill x, y + ch - 1, cw, 1, 0                 ' the bottom edge
  GuiScr.Rect x, y, 1, ch, &H7F, 0, 0                 ' the left edge
  GuiScr.Rect x + cw - 1, y, 1, ch, &HFE, 0, 0        ' the right edge
  GuiScr.Text x + 2, y, " " + Left$(tx(w), cw - 5) + " ", &HFF
  Gadget x, y, 0
  Gadget x + cw - 1, y, 1
  For k = 0 To MAXO
    If ty(k) <> 0 And ty(k) <> KW And ty(k) <> KI And pw(k) = w Then DrawObj k
  Next
End Sub

' a title bar's gadget: 0 close (a small box), 1 depth (two boxes)
Sub Gadget(ByVal x As Integer, ByVal y As Integer, ByVal g As Integer)
  GuiScr.Fill x, y + 1, 1, 6, &HFF
  If g = 0 Then
    GuiScr.Rect x, y + 2, 1, 1, &HC3, 0, 0
    GuiScr.Rect x, y + 3, 1, 2, &HDB, 0, 0
    GuiScr.Rect x, y + 5, 1, 1, &HC3, 0, 0
  Else
    GuiScr.Rect x, y + 1, 1, 1, &H87, 0, 0
    GuiScr.Rect x, y + 2, 1, 1, &HB7, 0, 0
    GuiScr.Rect x, y + 3, 1, 1, &HA1, 0, 0
    GuiScr.Rect x, y + 4, 1, 1, &H81, 0, 0
    GuiScr.Rect x, y + 5, 1, 2, &HE1, 0, 0
  End If
  GuiScr.Rect x, y, 1, 8, &H7F, 0, 0
  GuiScr.Rect x, y, 1, 8, &HFE, 0, 0
End Sub

' an object in its window: cell column cx, pixel line cy
Sub DrawObj(ByVal n As Integer)
  Dim w As Integer, cx As Integer, cy As Integer, t As Integer, s As String Max 40, inv As Integer, f As Integer
  w = pw(n)
  If w < 0 Then Exit Sub
  If ty(w) <> KW Then Exit Sub
  cx = ox(w) + ox(n) : cy = (oy(w) + 1 + oy(n)) * 8 : t = ty(n)
  If cx >= ox(w) + ow(w) - 1 Or cy >= (oy(w) + oh(w)) * 8 - 1 Then Exit Sub
  inv = &HFF
  If fo = n Then inv = 0
  If t = KL Then
    GuiScr.Fill cx, cy, ow(n), 8, &HFF
    GuiScr.Text cx, cy, tx(n), &HFF
  ElseIf t = KB Then
    GuiScr.Text cx, cy, " " + tx(n) + " ", inv
    Box cx, cy, ow(n)
  ElseIf t = KC Then
    GuiScr.Fill cx, cy, 1, 8, &HFF
    GuiScr.Rect cx, cy + 1, 1, 1, &H81, 0, 0
    If va(n) Then f = &HA5 Else f = &HBD
    GuiScr.Rect cx, cy + 2, 1, 1, &HBD, 0, 0
    GuiScr.Rect cx, cy + 3, 1, 2, f, 0, 0
    GuiScr.Rect cx, cy + 5, 1, 1, &HBD, 0, 0
    GuiScr.Rect cx, cy + 6, 1, 1, &H81, 0, 0
    GuiScr.Text cx + 1, cy, " " + tx(n), inv
  ElseIf t = KT Then
    s = Left$(tx(n), ow(n) - 1)
    GuiScr.Text cx, cy, s + Space$(ow(n) - Len(s)), &HFF
    If fo = n Then GuiScr.Text cx + Len(s), cy, " ", 0
    Box cx, cy, ow(n)
  ElseIf t = KR Then                                  ' a cycle: the choice and a ">"
    s = Opt(tx(n), va(n))
    GuiScr.Text cx, cy, " " + s + Space$(ow(n) - Len(s) - 3) + "> ", inv
    Box cx, cy, ow(n)
  ElseIf t = KP Then                                  ' a slider: a track and its knob
    GuiScr.Fill cx, cy, ow(n), 8, &HFF
    GuiScr.Fill cx, cy + 3, ow(n), 2, 0
    f = va(n)
    If f < 0 Then f = 0
    If f > ex(n) Then f = ex(n)
    f = (f * (ow(n) - 1)) \ ex(n)
    GuiScr.Fill cx + f, cy, 1, 8, 0
    If fo = n Then GuiScr.Rect cx + f, cy + 2, 1, 4, &HC3, &H18, &H18
    Box cx, cy, ow(n)
  ElseIf t = KV Then                                  ' a list: oh rows from row ex
    For f = 0 To oh(n) - 1
      inv = Item(n, ex(n) + f)
      If inv >= 0 Then s = Left$(tx(inv), ow(n)) Else s = ""
      If ex(n) + f = va(n) Then inv = 0 Else inv = &HFF
      GuiScr.Text cx, cy + f * 8, s + Space$(ow(n) - Len(s)), inv
    Next
    GuiScr.Fill cx, cy - 1, ow(n), 1, 0
    GuiScr.Fill cx, cy + oh(n) * 8, ow(n), 2, 0
    GuiScr.Rect cx, cy - 1, 1, oh(n) * 8 + 3, &H7F, 0, 0
    GuiScr.Rect cx + ow(n) - 1, cy - 1, 1, oh(n) * 8 + 3, &HFC, 0, 0
    If fo = n Then GuiScr.Rect cx + ow(n) - 1, cy, 1, oh(n) * 8, &HFE, 0, 0
  ElseIf t = KG Then
    GuiScr.Fill cx, cy, ow(n), 8, &HFF
    f = va(n)
    If f < 0 Then f = 0
    If f > 100 Then f = 100
    f = (ow(n) * 8 * f) \ 100                        ' pixels
    GuiScr.Fill cx, cy + 1, f \ 8, 6, 0
    If (f And 7) <> 0 Then
      inv = 255
      For t = 1 To (f And 7)
        inv = inv \ 2
      Next
      GuiScr.Rect cx + f \ 8, cy + 1, 1, 6, inv, 0, 0
    End If
    Box cx, cy, ow(n)
  End If
End Sub

' a button's / field's frame round cells cx.. (w of them) on line cy: a line above, two below
' (a shadow), one at the left, two at the right
Sub Box(ByVal cx As Integer, ByVal cy As Integer, ByVal w As Integer)
  GuiScr.Fill cx, cy - 1, w, 1, 0
  GuiScr.Fill cx, cy + 8, w, 2, 0
  GuiScr.Rect cx, cy - 1, 1, 11, &H7F, 0, 0
  GuiScr.Rect cx + w - 1, cy - 1, 1, 11, &HFC, 0, 0
End Sub

' an object drawn again (a window: the whole window), if on the screen
Sub Redraw(ByVal n As Integer)
  Sync n                                             ' (an object drawn again has changed: the remote head too)
  If shown = 0 Then Exit Sub
  If ty(n) = KI Then n = pw(n)
  PtrOff
  If ty(n) = KW Then DrawWin n Else DrawObj n
  PtrOn
End Sub

Sub PtrOn()
  If pon = 0 Then GuiScr.Ptr px, py : pon = 1
End Sub

Sub PtrOff()
  If pon Then GuiScr.Ptr px, py : pon = 0
End Sub

' ---- the mouse: the hardware read while GUI is in front (MultiPlay: #F990 / #F991 the buttons,
' #F992-#F995 X / Y moves since the last read; SYMBiFACE: #FD10 a stream; AMX: the joystick lines)
Sub Mouse()
  Dim b As Integer, mx As Integer, my As Integer, v As Integer
  mx = 0 : my = 0 : b = lb
#If HEADZXN Then
  If mo <> "KEYS" Then
    GuiScr.Mouse
    mx = GuiScr.MX() \ 2 : my = GuiScr.MY() : b = GuiScr.MB()
  End If
#Else
  If mo = "MP2" Or mo = "MP" Then
    If mo = "MP2" Then k = 2 Else k = 0
    mx = Inp(&HF992 + k) : my = Inp(&HF993 + k)
    If mx > 127 Then mx = mx - 256
    If my > 127 Then my = my - 256
    b = Inp(&HF990 + k \ 2) And 16
  ElseIf mo = "SF" Then
    Do
      v = Inp(&HFD10)
      If (v And &HC0) = 0 Then Exit Do
      If (v And &HC0) = &H40 Then mx = mx + (v And 63) - ((v And 32) * 2)
      If (v And &HC0) = &H80 Then my = my - ((v And 63) - ((v And 32) * 2))
      If (v And &HE0) = &HC0 Then b = v And 1
    Loop
  ElseIf mo = "AMX" Then                             ' an AMX-style mouse: the joystick's lines,
    v = GuiScr.Joy()                                 ' steps that speed up while it keeps moving
    If (v And 15) <> 0 Then
      If amx < 12 Then amx = amx + 1
    Else
      amx = 0
    End If
    If v And 1 Then my = -(1 + amx \ 3)
    If v And 2 Then my = 1 + amx \ 3
    If v And 4 Then mx = -(1 + amx \ 3)
    If v And 8 Then mx = 1 + amx \ 3
    b = v And &H70
  End If
#End If
  If mx <> 0 Or my <> 0 Then
    PtrOff
    px = px + mx * 2 : py = py + my
    If px < 0 Then px = 0
    If px > 639 Then px = 639
    If py < 0 Then py = 0
    If py > 199 Then py = 199
    PtrOn
  End If
  If b <> 0 And lb <> 0 And dsl >= 0 And (mx <> 0 Or my <> 0) Then SlideTo dsl
  If b <> 0 And lb = 0 Then Press
  If b = 0 And lb <> 0 Then Release
  lb = b
End Sub

' ---- the keys while in front: Tab (or ESC - Caps Shift + Space on the Next) the next control,
' Space / Return works it, a field takes
' what is typed; the cursor keys move the pointer, Copy clicks
Sub Keys()
  Dim c As Integer
  If Peek(&HF681) = 0 Then Exit Sub
  c = Inkey
  If c = 0 Then Exit Sub
  If c = 9 Or c = 27 Then NextFocus : Exit Sub      ' Tab, or ESC / Break (the Next has no Tab)
  If fo >= 0 Then
    If ty(fo) = KT Then
      If c = 13 Then va(fo) = va(fo) + 1 : cg(fo) = 1 : Exit Sub
      If c = 8 Or c = 127 Then
        If Len(tx(fo)) > 0 Then tx(fo) = Left$(tx(fo), Len(tx(fo)) - 1) : cg(fo) = 1 : Redraw fo
        Exit Sub
      End If
      If c >= 32 And c < 127 Then
        If Len(tx(fo)) < ow(fo) - 1 Then tx(fo) = tx(fo) + Chr$(c) : cg(fo) = 1 : Redraw fo
        Exit Sub
      End If
    ElseIf ty(fo) = KP And (c = 242 Or c = 243 Or c = 44 Or c = 46 Or c = 60 Or c = 62) Then
      If c = 242 Or c = 44 Or c = 60 Then Slide fo, -1 Else Slide fo, 1     ' (left / , <, right / . >)
      Exit Sub
    ElseIf ty(fo) = KV And (c = 240 Or c = 241 Or c = 32 Or c = 13) Then
      If c = 240 Then Pick fo, va(fo) - 1
      If c = 241 Then Pick fo, va(fo) + 1
      If c = 32 Or c = 13 Then Pick fo, va(fo)
      Exit Sub
    ElseIf c = 32 Or c = 13 Then
      Activate fo : Exit Sub
    End If
  End If
  If c = 240 Or c = 241 Or c = 242 Or c = 243 Then
    PtrOff
    If c = 240 Then py = py - 8
    If c = 241 Then py = py + 8
    If c = 242 Then px = px - 8
    If c = 243 Then px = px + 8
    If px < 0 Then px = 0
    If px > 639 Then px = 639
    If py < 0 Then py = 0
    If py > 199 Then py = 199
    PtrOn
    Exit Sub
  End If
  If c = 224 Then Press : Release : Exit Sub
  If fo < 0 And (c = 81 Or c = 113) Then quit = 1
End Sub

' Slide n, d: slider n a step (its max / its width, at least 1) on, d -1 or 1
Sub Slide(ByVal n As Integer, ByVal d As Integer)
  Dim st As Integer
  st = ex(n) \ (ow(n) - 1)
  If st < 1 Then st = 1
  va(n) = va(n) + d * st
  If va(n) < 0 Then va(n) = 0
  If va(n) > ex(n) Then va(n) = ex(n)
  cg(n) = 1 : Redraw n
End Sub

' SlideTo n: slider n's value from the pointer's column
Sub SlideTo(ByVal n As Integer)
  Dim c As Integer, v As Integer
  c = px \ 8 - ox(pw(n)) - ox(n)
  If c < 0 Then c = 0
  If c > ow(n) - 1 Then c = ow(n) - 1
  v = (c * ex(n)) \ (ow(n) - 1)
  If v = va(n) Then Exit Sub
  va(n) = v : cg(n) = 1                             ' (drawn here as it moves; a remote head is told
  If shown Then PtrOff : DrawObj n : PtrOn          '  once, when the button is let go: Release)
End Sub

' Pick n, i: list n's row i picked (if there is one), shown (the list scrolls to it)
Sub Pick(ByVal n As Integer, ByVal i As Integer)
  Dim k As Integer
  If i < 0 Then Exit Sub
  k = Item(n, i)
  If k < 0 Then Exit Sub
  va(n) = i : tx(n) = tx(k) : cg(n) = 1
  If i < ex(n) Then ex(n) = i
  If i >= ex(n) + oh(n) Then ex(n) = i - oh(n) + 1
  Redraw n
End Sub

' Tab: the next button / check box / field in the front window
Sub NextFocus()
  Dim w As Integer, n As Integer, k As Integer, old As Integer
  If nz = 0 Then Exit Sub
  w = zo(nz - 1) : old = fo
  n = fo
  For k = 0 To MAXO
    n = n + 1
    If n > MAXO Then n = 0
    If ty(n) = KB Or ty(n) = KC Or ty(n) = KT Or ty(n) = KR Or ty(n) = KP Or ty(n) = KV Then
      If pw(n) = w Then fo = n : Exit For
    End If
  Next
  If old >= 0 Then Redraw old
  If fo >= 0 Then Redraw fo
End Sub

' a button pressed, a box ticked, a field chosen
Sub Activate(ByVal n As Integer)
  Dim t As Integer, k As Integer
  t = ty(n)
  If t = KB Then
    va(n) = va(n) + 1 : cg(n) = 1 : Sync n
    If shown = 0 Then Exit Sub
    PtrOff
    GuiScr.Text ox(pw(n)) + ox(n), (oy(pw(n)) + 1 + oy(n)) * 8, " " + tx(n) + " ", 0
    Box ox(pw(n)) + ox(n), (oy(pw(n)) + 1 + oy(n)) * 8, ow(n)
    t = CybSys.Clock()
    Do While CybSys.Clock() - t < 30
    Loop
    DrawObj n
    PtrOn
  ElseIf t = KC Then
    va(n) = 1 - va(n) : cg(n) = 1 : Redraw n
  ElseIf t = KR Then
    va(n) = va(n) + 1
    If va(n) >= Count(tx(n)) Then va(n) = 0
    cg(n) = 1 : Redraw n
  ElseIf t = KT Then
    k = fo : fo = n
    If k >= 0 Then Redraw k
    Redraw n
  End If
End Sub

' the button went down at the pointer
Sub Press()
  Dim w As Integer, k As Integer, cx As Integer, cy As Integer, n As Integer
  cx = px \ 8 : cy = py \ 8
  If cy = 0 And cx >= 17 And cx <= 23 Then quit = 1 : Exit Sub      ' "Q quits" in the menu strip
  w = -1
  For k = nz - 1 To 0 Step -1
    n = zo(k)
    If cx >= ox(n) And cx < ox(n) + ow(n) And cy >= oy(n) And cy < oy(n) + oh(n) Then w = n : k = -1
  Next
  If w < 0 Then Exit Sub
  If zo(nz - 1) <> w Then ToTop w
  If cy = oy(w) Then
    If cx = ox(w) Then va(w) = 1 : cg(w) = 1 : Exit Sub              ' the close gadget
    If cx = ox(w) + ow(w) - 1 Then ToBack w : Exit Sub              ' the depth gadget
    drag = w : gx = cx - ox(w) : gy = cy - oy(w)                     ' the title bar: a drag
    Exit Sub
  End If
  For k = 0 To MAXO
    If ty(k) > KW And pw(k) = w And ty(k) <> KL And ty(k) <> KG And ty(k) <> KI Then
      n = oy(w) + 1 + oy(k)                        ' (its first row)
      If cy >= n And cy < n + oh(k) And cx >= ox(w) + ox(k) And cx < ox(w) + ox(k) + ow(k) Then
        If ty(k) <> KT Then
          n = fo : fo = -1
          If n >= 0 Then Redraw n
        End If
        If ty(k) = KP Then                          ' a slider: the value where it was clicked (and
          dsl = k : SlideTo k                       ' it follows the pointer while the button is held)
        ElseIf ty(k) = KV Then                      ' a list: that row
          Pick k, ex(k) + cy - (oy(w) + 1 + oy(k))
        Else
          Activate k
        End If
        Exit Sub
      End If
    End If
  Next
End Sub

' the button went up: a drag ends - the window moved
Sub Release()
  Dim nx As Integer, ny As Integer
  If dsl >= 0 Then Sync dsl                        ' a slider let go: its value to the remote heads
  dsl = -1
  If drag < 0 Then Exit Sub
  nx = px \ 8 - gx : ny = py \ 8 - gy
  If nx < 0 Then nx = 0
  If nx + ow(drag) > 80 Then nx = 80 - ow(drag)
  If ny < 1 Then ny = 1
  If ny + oh(drag) > 25 Then ny = 25 - oh(drag)
  If nx <> ox(drag) Or ny <> oy(drag) Then
    ox(drag) = nx : oy(drag) = ny : Sync drag
    PtrOff : DrawAll
  End If
  drag = -1
End Sub

Sub ToTop(ByVal w As Integer)
  Dim k As Integer, z As Integer, old As Integer
  old = zo(nz - 1)
  z = 0
  For k = 0 To nz - 1
    If zo(k) <> w Then zo(z) = zo(k) : z = z + 1
  Next
  zo(nz - 1) = w
  If fo >= 0 Then
    k = fo : fo = -1
  End If
  Order
  If shown = 0 Then Exit Sub
  PtrOff
  DrawWin old
  DrawWin w
  PtrOn
End Sub

Sub ToBack(ByVal w As Integer)
  Dim t(15) As Integer, k As Integer, z As Integer
  t(0) = w : z = 1
  For k = 0 To nz - 1
    If zo(k) <> w Then t(z) = zo(k) : z = z + 1
  Next
  For k = 0 To nz - 1
    zo(k) = t(k)
  Next
  Order
  If shown Then PtrOff : DrawAll
End Sub

' ---- the remote head (RGUI): the model's changes as lines on a VDU screen (tools/vdu), which
' rgui.html draws in a browser and sends clicks back to as the screen's events. The lines:
'   O id kind parent x y w h value extra text    an object as it is now (made or changed)
'   X id                                         gone
'   Z id id ...                                  the windows, back to front
' The events (the browser's):  C id  clicked;  S id n  a value set (slider, list);  T id text  a
' field's text (Return);  F id  a window to the front;  K id  its close gadget;  M id x y  moved
#If HEADZXN Then
Sub Sync(ByVal n As Integer)
End Sub
Sub Order()
End Sub
Sub Emit(ByVal l As String)
End Sub
#Else
Sub Sync(ByVal n As Integer)
  If rg = 0 Then Exit Sub
  If ty(n) = 0 Then Exit Sub
  Emit "O" + Str$(n) + Str$(ty(n)) + Str$(pw(n)) + Str$(ox(n)) + Str$(oy(n)) + Str$(ow(n)) + Str$(oh(n)) + Str$(va(n)) + Str$(ex(n)) + " " + tx(n)
End Sub

Sub Order()
  Dim k As Integer, l As String Max 80
  If rg = 0 Then Exit Sub
  l = "Z"
  For k = 0 To nz - 1
    l = l + Str$(zo(k))
  Next
  Emit l
End Sub

' Emit l: a line for the remote head, kept until Flush sends them (several in one request)
Sub Emit(ByVal l As String)
  Dim e As String Max 200, k As Integer, c As Integer
  If rg = 0 Then Exit Sub
  e = ""
  For k = 1 To Len(l)
    c = Asc(Mid$(l, k, 1))
    If (c >= 48 And c <= 57) Or (c >= 65 And c <= 90) Or (c >= 97 And c <= 122) Or c = 45 Or c = 46 Then
      e = e + Chr$(c)
    Else
      e = e + "%" + Right$("0" + Hex$(c), 2)
    End If
  Next
  If Len(ob) + Len(e) + 3 > 150 Then Flush
  If ob <> "" Then ob = ob + "%0A"
  ob = ob + e
End Sub

' Flush: the lines kept, put on the screen (vdu.php a=put): its answer "ok total events" - more
' events than seen: the browser clicked something (looked at straight away)
Sub Flush()
  Dim n As Integer, k As Integer
  tfl = CybSys.Clock()
  If ob = "" Then Exit Sub
  n = Http.Get(rb + "/vdu.php?a=put&s=" + rid + "&k=" + rkey + "&c=" + ob, VarPtr(hb), 1000)
  ob = ""
  If n < 4 Then Exit Sub
  k = HLine(0, n)
  k = InStr(4, hl, " ")
  If k > 0 Then
    If Val(Mid$(hl, k + 1)) > evc Then tev = tev - 1000
  End If
End Sub

' RNew: a screen of GUI's own on the server (vdu.php a=new): "ok id key"
Sub RNew()
  Dim n As Integer, k As Integer
  n = Http.Get(rb + "/vdu.php?a=new&t=CyborgOS%20GUI&p=0", VarPtr(hb), 1000)
  If n < 4 Then Print "GUI: no remote head (the server didn't answer: NET M4 first?)" : Exit Sub
  k = HLine(0, n)
  If Left$(hl, 3) <> "ok " Then Print "GUI: no remote head ("; hl; ")" : Exit Sub
  hl = Mid$(hl, 4)
  k = InStr(hl, " ")
  rid = Left$(hl, k - 1) : rkey = Mid$(hl, k + 1)
  rg = 1 : evc = 0 : evp = 0 : tfl = CybSys.Clock() : tev = tfl
  Print "GUI: the remote head - "; rb; "/rgui.html?s="; rid
  Emit "MODE 2"
  Emit "TITLE CyborgOS GUI"
  Flush
End Sub

' Events: the browser's clicks since the last look (vdu.php a=events), done as the user's own
Sub Events()
  Dim n As Integer, p As Integer, q As Integer, nx As Integer
  tev = CybSys.Clock()
  n = Http.Get(rb + "/vdu.php?a=events&s=" + rid + "&k=" + rkey + "&n=" + Trim$(Str$(evp)), VarPtr(hb), 1000)
  If n < 4 Then Exit Sub
  p = HLine(0, n)                                     ' "ok start next total"
  If Left$(hl, 3) <> "ok " Then Exit Sub
  q = InStr(4, hl, " ")
  nx = Val(Mid$(hl, q + 1))
  evc = Val(Mid$(hl, InStr(q + 1, hl, " ") + 1))
  evp = nx
  Do While p < n
    p = HLine(p, n)
    If hl <> "" Then Act hl
  Loop
End Sub

' HLine(p, n): the answer's line from byte p into hl - where the next starts
Function HLine(ByVal p As Integer, ByVal n As Integer) As Integer
  Dim c As Integer
  hl = ""
  Do While p < n
    c = hb(p) : p = p + 1
    If c = 10 Then Exit Do
    If c <> 13 And Len(hl) < 250 Then hl = hl + Chr$(c)
  Loop
  HLine = p
End Function

' Act e: a browser's event
Sub Act(ByVal e As String)
  Dim c As String Max 1, n As Integer, v As Integer
  c = UCase$(Left$(e, 1))
  ps = 2
  n = Num(e)
  If n < 0 Or n > MAXO Then Exit Sub
  If ty(n) = 0 Then Exit Sub
  If c = "C" Then
    If ty(n) = KB Or ty(n) = KC Or ty(n) = KR Then Activate n
  ElseIf c = "S" Then
    v = Num(e)
    If ty(n) = KP Then
      If v < 0 Then v = 0
      If v > ex(n) Then v = ex(n)
      va(n) = v : cg(n) = 1 : Redraw n
    ElseIf ty(n) = KV Then
      Pick n, v
    End If
  ElseIf c = "T" Then
    If ty(n) = KT Then tx(n) = Left$(Rest(e), ow(n) - 1) : va(n) = va(n) + 1 : cg(n) = 1 : Redraw n
  ElseIf c = "F" Then
    If ty(n) = KW Then ToTop n
  ElseIf c = "K" Then
    If ty(n) = KW Then va(n) = 1 : cg(n) = 1
  ElseIf c = "M" Then
    If ty(n) = KW Then
      ox(n) = Num(e) : oy(n) = Num(e)
      If ox(n) < 0 Then ox(n) = 0
      If ox(n) + ow(n) > 80 Then ox(n) = 80 - ow(n)
      If oy(n) < 1 Then oy(n) = 1
      If oy(n) + oh(n) > 25 Then oy(n) = 25 - oh(n)
      Sync n
      If shown Then PtrOff : DrawAll
    End If
  End If
End Sub
#End If

' Front: 1 while this slot is the one on the screen (BDOS 131 op 0, byte 3)
Function Front() As Integer
  If CybSys.Ask(0, me) = 0 Then
  End If
  Front = CybSys.ByteAt(3)
End Function

' MySlot: this slot's number, from its status strip text in its own bank ("[7] " at #F68A)
Function MySlot() As Integer
  Dim a As Integer, n As Integer
  n = 0
  a = &HF68B
  Do While Peek(a) >= 48 And Peek(a) <= 57
    n = n * 10 + Peek(a) - 48
    a = a + 1
  Loop
  MySlot = n
End Function
