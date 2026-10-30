' RMOVE / RCOPY: a running slot sent whole to another machine (its SLOTD puts it in a slot there and
' it goes on from where it was), or a program file sent to run there fresh. RMOVE: the slot is
' closed here once the other end has it (it goes on here if that fails); RCOPY: it goes on here
' too - two copies from that moment. One source, two commands: what it does is its own name
' (RMOVE.CYB, RCOPY.CYB). Build for cyborgos with CybSys.cls, CybVol.cls.
'   RMOVE slot address[:port] [word] [-o target]     RCOPY slot address[:port] [word] [-o target]
'   RCOPY NAME.CYB address[:port] [word] [-o target]   a program: copied, run fresh there
' address: a name or 192.168.1.20; the port SLOTD's (6464) unless given. word: the one SLOTD asks
' for. -o target: that slot there killed and taken over (only one SLOTD allows). A slot with a file
' open, a claim, a port or a socket can't go (as DUMP); a slot goes only to the same build
Option Explicit
Dim a As String Max 72, nm As String Max 12, wh As String Max 20, ad As String Max 64, w As String Max 16
Dim tk As String Max 64, why As String Max 60, pt As String Max 64
Dim s As Integer, tg As Integer, r As Integer, i As Integer, j As Integer, k As Integer, sk As Integer
Dim port As Integer, ran As Integer, mv As Integer, h As Integer, got As Integer, t0 As Integer, t1 As Integer
Dim n As Long, sz As Long, tpa As Long, blen As Long, off As Long
Dim rq(63) As Byte, hd(127) As Byte, buf(2047) As Byte, sb(11) As Byte, nb(15) As Byte, tb(159) As Byte
Dim ip(3) As Byte, e(15) As Byte, b0(1) As Byte

nm = ""
For i = 1 To Peek(&HF6D8)                        ' (this program's name, in its bank)
  If i > 12 Then Exit For
  nm = nm + Chr$(Peek(&HF6D8 + i))
Next
mv = (Left$(nm, 5) = "RMOVE")
a = Trim$(System.CommandLine()) + " "
wh = "" : ad = "" : w = "" : tg = 0
Do While Trim$(a) <> ""
  i = InStr(a, " ")
  tk = Left$(a, i - 1) : a = Trim$(Mid$(a, i + 1)) + " "
  If UCase$(tk) = "-O" Then
    i = InStr(a, " ") : tg = Val(Left$(a, i - 1)) : a = Trim$(Mid$(a, i + 1)) + " "
  ElseIf wh = "" Then
    wh = UCase$(tk)
  ElseIf ad = "" Then
    ad = tk
  Else
    w = UCase$(tk)
  End If
Loop
If wh = "" Or ad = "" Then
  Print IIf(mv, "RMOVE", "RCOPY"); " slot address[:port] [word] [-o target]   (or a program: NAME.CYB)"
  End
End If
port = 6464
i = InStr(ad, ":")
If i > 0 Then port = Val(Mid$(ad, i + 1)) : ad = Left$(ad, i - 1)
For i = 0 To 63
  rq(i) = 0
Next
Put 0, "CYBXFER1"
rq(9) = tg
rq(10) = Len(w) : Put 11, w
If InStr("0123456789", Left$(wh, 1)) > 0 Then SendSlot Else SendProg
End

' ---- a running slot
Sub SendSlot()
  s = Val(wh)
  If CybSys.State(s) = 255 Then Print "no slot "; wh : End
  i = 0 : j = &HF68B                              ' (not its own slot)
  Do While Peek(j) >= 48 And Peek(j) <= 57
    i = i * 10 + Peek(j) - 48 : j = j + 1
  Loop
  If s = i Then Print "slot "; wh; " is this one" : End
  If CybSys.State(s) < 2 Then Print "slot "; wh; " runs no program" : End
  r = CybSys.SlotState(s, VarPtr(sb))
  why = ""
  If sb(5) Then why = "a file open"
  CybSys.SetWord 2, VarPtr(tb)
  If CybSys.Ask(15, 4) = 0 Then
    For i = 0 To 15
      If tb(i * 10) = s And why = "" Then why = "a claim"
    Next
  End If
  For i = 0 To 7
    tk = CybSys.PortName(i)
    If tk <> "" And CybSys.PortSlot() = s And why = "" Then why = "a port (" + tk + ")"
  Next
  CybSys.SetWord 2, VarPtr(tb)
  If CybSys.Ask(20, 10) <> 255 Then
    For i = 0 To 7
      If tb(i * 8) = s And tb(i * 8 + 1) <> 0 And why = "" Then why = "a socket open"
    Next
  End If
  If why <> "" Then Print "slot "; wh; " has "; why; " - it can't go" : End
  If Not Link() Then Print why : End
  ran = 0
  If CybSys.State(s) = 2 Then r = CybSys.Pause(s, -1) : ran = -1
  r = CybSys.SlotState(s, VarPtr(sb))             ' (its state now it is paused)
  For i = 0 To 127                                ' DUMP's 128 bytes: CYBDUMP1, the stamp, the state, the name
    hd(i) = 0
  Next
  tk = "CYBDUMP1"
  For i = 1 To 8
    hd(i - 1) = Asc(Mid$(tk, i, 1))
  Next
  For i = 0 To 11
    hd(10 + i) = sb(i)
  Next
  hd(8) = sb(8) : hd(9) = sb(9)
  hd(40) = CybSys.Host()                           ' the platform it came from
  Mem s, &HF6D8, VarPtr(nb), 13
  For i = 0 To 12
    hd(22 + i) = nb(i)
  Next
  Mem s, 6, VarPtr(b0), 2                          ' the TPA top (the BDOS entry word at #0006)
  tpa = b0(0) + b0(1) * 256&
  blen = tpa - &H100                              ' trim trailing zeros, 2K at a time
  Do While blen > 0
    off = &H100 + blen - 1
    k = CInt((off And &H7FF&) + 1)
    If k > blen Then k = CInt(blen)
    Mem s, W16(off - k + 1), VarPtr(buf), k
    j = k - 1
    Do While j >= 0
      If buf(j) <> 0 Then Exit Do
      j = j - 1
    Loop
    If j >= 0 Then blen = blen - (k - 1 - j) : Exit Do
    blen = blen - k
  Loop
  hd(46) = CInt(tpa And 255) : hd(47) = CInt((tpa \ 256) And 255)
  hd(48) = CInt(blen And 255) : hd(49) = CInt((blen \ 256) And 255)
  Mem s, W16(&HFFFE&), VarPtr(b0), 2               ' the saved stack pointer (at #FFFE)
  hd(50) = b0(0) : hd(51) = b0(1)
  rq(8) = 83                                      ' S: a slot
  rq(27) = nb(0)
  For i = 1 To nb(0)
    If i <= 12 Then rq(27 + i) = nb(i)
  Next
  n = 128 + blen                                  ' header + the trimmed program
  rq(40) = CInt(n And 255) : rq(41) = CInt((n \ 256) And 255) : rq(42) = CInt((n \ 65536) And 255)
  rq(44) = sb(8) : rq(45) = sb(9)                 ' (the build's stamp: SLOTD refuses another platform first)
  why = ""
  Snd VarPtr(rq), 64
  If why = "" Then Answer                         ' (SLOTD's GO, or why not)
  If why = "GO" Then why = "" Else Shut : Gone : Exit Sub
  Snd VarPtr(hd), 128
  off = &H100
  Do While off < &H100 + blen And why = ""
    n = &H100 + blen - off
    If n > 2048 Then n = 2048
    Mem s, W16(off), VarPtr(buf), CInt(n)
    Snd VarPtr(buf), CInt(n)
    off = off + n
  Loop
  If why = "" Then Answer
  Shut
  Gone
End Sub

' the slot after sending (why: SLOTD's answer) - moved: closed here; copied, or not sent: it goes on
Sub Gone()
  If Left$(why, 3) = "OK " Then
    If mv Then
      r = CybSys.Ask(1, s)                        ' (moved: closed here)
      Print "slot "; wh; " moved to "; ad; ", slot "; Mid$(why, 4)
    Else
      If ran Then r = CybSys.Pause(s, 0)
      Print "slot "; wh; " copied to "; ad; ", slot "; Mid$(why, 4); " - it goes on here too"
    End If
  Else
    If ran Then r = CybSys.Pause(s, 0)
    Print "not sent: "; IIf(Left$(why, 3) = "NO ", Mid$(why, 4), why); IIf(mv, " - it goes on here", "")
  End If
End Sub

' ---- a program file
Sub SendProg()
  h = FileSystem.Open(wh, FileSystem.ForReadRaw)
  If h < 0 Then Print "no "; wh : End
  sz = 0                                          ' (its size: read through once)
  Do
    k = FileSystem.Read(h, VarPtr(buf), 2048)
    If k <= 0 Then Exit Do
    sz = sz + k
    If k < 2048 Then Exit Do
  Loop
  r = FileSystem.Close(h)
  If sz = 0 Then Print wh; " is empty" : End
  If Not Link() Then Print why : End
  rq(8) = 70                                      ' F: a program
  i = InStr(wh, ":")                              ' (its name without a drive)
  tk = Mid$(wh, i + 1)
  rq(27) = Len(tk) : Put 28, tk
  rq(40) = sz And 255 : rq(41) = (sz \ 256) And 255 : rq(42) = (sz \ 65536) And 255
  why = ""
  Snd VarPtr(rq), 64
  If why = "" Then Answer
  If why <> "GO" Then
    Shut
    Print "not sent: "; IIf(Left$(why, 3) = "NO ", Mid$(why, 4), why)
    Exit Sub
  End If
  why = ""
  h = FileSystem.Open(wh, FileSystem.ForReadRaw)
  n = sz
  Do While n > 0 And why = ""
    k = FileSystem.Read(h, VarPtr(buf), 2048)
    If k <= 0 Then Exit Do
    Snd VarPtr(buf), k
    n = n - k
  Loop
  r = FileSystem.Close(h)
  If why = "" Then Answer
  Shut
  If Left$(why, 3) = "OK " Then
    Print wh; " copied to "; ad; " - running in slot "; Mid$(why, 4)
  Else
    Print "not sent: "; why
  End If
End Sub

' ---- the network
' Link: connected to ad:port (sk) - False with why set
Function Link() As Integer
  Link = 0
  If CybSys.Ask(20, 0) = 255 Then why = "no network (NET M4 on the CPC, NET ESP on the Next)" : Exit Function
  If Not Look() Then Exit Function
  sk = CybSys.Ask(23, 0)
  If sk = 255 Then why = "no socket free" : Exit Function
  For i = 0 To 3
    CybSys.SetWord 2 + i, ip(i)                   ' (Byte(2-5): its address, Word(6) the port)
  Next
  CybSys.SetWord 6, port
  If CybSys.Ask(24, sk) <> 0 Then why = "can't connect to " + ad : Shut : Exit Function
  t0 = CybSys.Clock()
  Do
    CybSys.SetWord 2, VarPtr(e)
    r = CybSys.Ask(22, sk)
    If r <> 1 Then Exit Do
    t1 = CybSys.Clock() - t0
    If t1 < 0 Then t1 = t1 + 32767 + 1
    If t1 > 3000 Then Exit Do
  Loop
  If r <> 0 Then why = "no SLOTD at " + ad + ":" + Trim$(Str$(port)) : Shut : Exit Function
  Link = -1
End Function

' Look: ad's address into ip - always through the system's lookup (op 21), dotted or a name: each
' machine keeps addresses in its own order (the M4 its own), and the lookup gives that order
Function Look() As Integer
  Dim ch As String Max 1, v As Integer, q As Integer, dots As Integer
  Look = 0
  ' a dotted IP (four numbers and three dots): used as it is, no lookup
  dots = 0 : v = 0 : q = 0 : ip(0) = 0 : ip(1) = 0 : ip(2) = 0 : ip(3) = 0
  For i = 1 To Len(ad)
    ch = Mid$(ad, i, 1)
    If ch = "." Then
      If q > 3 Then dots = -99 : Exit For
      ip(q) = v : q = q + 1 : v = 0 : dots = dots + 1
    ElseIf ch >= "0" And ch <= "9" Then
      v = v * 10 + (Asc(ch) - 48)
    Else
      dots = -99 : Exit For
    End If
  Next
  If dots = 3 And q = 3 Then
    ip(3) = v
    Look = -1
    Exit Function
  End If
  ' a name: through the system's lookup
  For i = 1 To Len(ad)
    buf(i - 1) = Asc(Mid$(ad, i, 1))
  Next
  CybSys.SetWord 2, VarPtr(buf) : CybSys.SetWord 4, Len(ad)
  If CybSys.Ask(21, 0) <> 1 Then why = "can't look up " + ad : Exit Function
  t0 = CybSys.Clock()
  Do
    CybSys.SetWord 2, VarPtr(e)
    r = CybSys.Ask(22, 255)
    If r <> 5 Then Exit Do
    t1 = CybSys.Clock() - t0
    If t1 < 0 Then t1 = t1 + 32767 + 1
    If t1 > 3000 Then Exit Do
  Loop
  If r <> 0 Then why = "no such host: " + ad : Exit Function
  For i = 0 To 3
    ip(i) = e(4 + i)
  Next
  Look = -1
End Function

' Snd: n bytes from addr (240 at a time: the network's most a call) - why set if it failed
Sub Snd(ByVal p As Integer, ByVal cnt As Integer)
  Dim m As Integer
  Do While cnt > 0
    m = cnt
    If m > 240 Then m = 240
    CybSys.SetWord 2, p : CybSys.SetWord 4, m
    If CybSys.Ask(25, sk) <> 0 Then why = "the connection broke" : Exit Sub
    p = p + m : cnt = cnt - m
  Loop
End Sub

' Answer: SLOTD's line ("OK n" / "NO why") into why (60 seconds at most)
Sub Answer()
  Dim m As Integer
  got = 0 : t0 = CybSys.Clock()
  Do
    CybSys.SetWord 2, VarPtr(buf) + got : CybSys.SetWord 4, 60 - got : CybSys.SetWord 6, 0
    If CybSys.Ask(26, sk) <> 0 Then Exit Do
    m = CybSys.WordAt(6)
    got = got + m
    If got > 0 Then
      If buf(got - 1) = 13 Then Exit Do
    End If
    If got >= 60 Then Exit Do
    If m = 0 Then
      CybSys.SetWord 2, VarPtr(e)
      If CybSys.Ask(22, sk) = 3 Then             ' closed: what came with the close read first
        CybSys.SetWord 2, VarPtr(buf) + got : CybSys.SetWord 4, 60 - got : CybSys.SetWord 6, 0
        If CybSys.Ask(26, sk) = 0 Then got = got + CybSys.WordAt(6)
        Exit Do
      End If
      t1 = CybSys.Clock() - t0
      If t1 < 0 Then t1 = t1 + 32767 + 1
      If t1 > 18000 Then Exit Do
    End If
  Loop
  why = ""
  For i = 0 To got - 1
    If buf(i) <> 13 Then why = why + Chr$(buf(i))
  Next
  If why = "" Then why = "no answer from " + ad
End Sub

Sub Shut()
  r = CybSys.Ask(27, sk)
End Sub

' the text t into rq from byte at
Sub Put(ByVal at As Integer, ByVal t As String)
  Dim q As Integer
  For q = 1 To Len(t)
    rq(at + q - 1) = Asc(Mid$(t, q, 1))
  Next
End Sub

' n bytes of slot t's memory from address am to the address dst (BDOS 131 op 10, kind 3)
Function W16(ByVal v As Long) As Integer
  If v > 32767 Then W16 = CInt(v - 65536&) Else W16 = CInt(v)
End Function

Sub Mem(ByVal t As Integer, ByVal am As Integer, ByVal dst As Integer, ByVal cnt As Integer)
  CybSys.SetWord 2, t : CybSys.SetWord 4, am : CybSys.SetWord 6, dst : CybSys.SetWord 8, cnt
  r = CybSys.Ask(10, 3)
End Sub
