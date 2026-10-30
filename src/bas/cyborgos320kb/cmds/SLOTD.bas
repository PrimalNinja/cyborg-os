' SLOTD: the receiving end of RMOVE and RCOPY - a daemon in a slot of its own that takes a running
' slot (sent whole, as DUMP keeps it: it goes on here from where it was) or a program (run fresh
' here) sent to it over the network, and puts it in one of the slots it is allowed. Listening is
' on only while SLOTD runs (port 6464) and off again when it ends: nothing listens otherwise.
' Build for cyborgos with CybSys.cls.
'   SLOTD [slots] [word]   SLOTD 4,5,6 SECRET: only into 4, 5 or 6, and only from a sender that
'                          gives the word (without a list: any closed slot but its own; without a
'                          word: from anyone - the word is a permission, not encryption)
'   Q (in its slot) stops it
' A sender asking for a target (-o n) has that slot killed and taken over - only one SLOTD allows.
' A slot from another build of CyborgOS (the build's stamp) is refused; a program goes anywhere.
' The request: 64 bytes (CYBXFER1, S a slot / F a program, the target, the word, a name, the size, a
' slot's build stamp); SLOTD answers "GO" (or "NO why"), then the slot (DUMP's 128 bytes and the 64K)
' or the program comes, and the answer is a line: "OK n" or "NO why"
Option Explicit
Const PORT = 6464
Dim a As String Max 72, w As String Max 16, tk As String Max 40, why As String Max 60
Dim ok(20) As Integer, any As Integer, me As Integer, ls As Integer, c As Integer, i As Integer, j As Integer
Dim r As Integer, s As Integer, k As Integer, h As Integer, n As Long, got As Integer
Dim rq(63) As Byte, hd(127) As Byte, buf(2047) As Byte, sb(11) As Byte, nb(15) As Byte, e(15) As Byte

me = 0
i = &HF68B                                        ' (this slot's number, in its bank)
Do While Peek(i) >= 48 And Peek(i) <= 57
  me = me * 10 + Peek(i) - 48 : i = i + 1
Loop
a = Trim$(System.CommandLine()) + " "
any = -1 : w = ""
Do While Trim$(a) <> ""
  i = InStr(a, " ")
  tk = Left$(a, i - 1) : a = Trim$(Mid$(a, i + 1)) + " "
  If tk <> "" And InStr("0123456789", Left$(tk, 1)) > 0 Then
    any = 0
    Do While tk <> ""                             ' 4,5,6
      j = InStr(tk, ",")
      If j = 0 Then j = Len(tk) + 1
      k = Val(Left$(tk, j - 1))
      If k >= 1 And k <= 20 Then ok(k) = -1
      tk = Mid$(tk, j + 1)
    Loop
  ElseIf tk <> "" Then
    w = UCase$(tk)
  End If
Loop
ls = CybSys.Listen(PORT)
If ls = 255 Then Print "SLOTD: can't listen on"; PORT; "- no network, or not on this machine yet" : End
Print "SLOTD: listening on port "; Trim$(Str$(PORT)); " for "; IIf(any, "any closed slot", "its slots");
If w <> "" Then Print " (a word asked)" Else Print ""
Print "Q stops it (and the listening)"
Do
  k = Bdos(6, &HFF)
  If k = 81 Or k = 113 Then Exit Do
  c = CybSys.Accept(ls)
  If c = 255 Then Print "SLOTD: the listening stopped" : Exit Do
  If c <> 254 Then
    Take
    If c = ls Then                                ' (the M4's way: the listening socket became the
      ls = CybSys.Listen(PORT)                    ' connection - listening again for the next)
      If ls = 255 Then Print "SLOTD: can't listen again" : Exit Do
    End If
  End If
Loop
Shut ls
Print "SLOTD: stopped - not listening"
End

' ---- a sender: its request, the slot or the program, the answer
Sub Take()
  why = ""
  If Rcv(VarPtr(rq), 64) <> 64 Then why = "no request"
  If why = "" Then
    a = ""
    For i = 0 To 7
      a = a + Chr$(rq(i))
    Next
    If a <> "CYBXFER1" Then why = "not a CyborgOS sender"
  End If
  If why = "" And w <> "" Then
    a = ""
    For i = 1 To rq(10)
      If i <= 16 Then a = a + Chr$(rq(10 + i))
    Next
    If UCase$(a) <> w Then why = "the word is wrong"
  End If
  If why = "" And rq(8) = 83 Then                 ' a slot: only from this build (its stamp)
    r = CybSys.SlotState(me, VarPtr(sb))
    If sb(8) <> rq(44) Or sb(9) <> rq(45) Then why = "it is from another build of CyborgOS"
  End If
  If why = "" Then s = Where(rq(9))
  If why = "" Then                                ' (all well: GO - the sender sends it only then)
    Reply "GO"
    If rq(8) = 83 Then SlotIn Else ProgIn
  End If
  If why = "" Then
    Reply "OK " + Trim$(Str$(s))
    Print "SLOTD: "; Named(); " into slot "; Trim$(Str$(s))
  Else
    Reply "NO " + why
    Print "SLOTD: refused - "; why
  End If
  Shut c
End Sub

' the slot it goes in: the target (killed first: only one it allows), else the first closed one it
' allows - 0 and why set when none
Function Where(ByVal tg As Integer) As Integer
  Dim q As Integer
  Where = 0
  If tg > 0 Then
    If tg = me Or tg > 20 Or (any = 0 And ok(tg) = 0) Then why = "slot " + Trim$(Str$(tg)) + " isn't one SLOTD may take" : Exit Function
    If CybSys.State(tg) = 255 Then why = "no slot " + Trim$(Str$(tg)) : Exit Function
    If CybSys.State(tg) >= 2 Then r = CybSys.Ask(1, tg)  ' (killed: taken over)
    Where = tg : Exit Function
  End If
  For q = 1 To 20                                 ' a closed slot first (op 0: ByteAt(2) the state, ByteAt(3) in front)
    If q <> me And (any Or ok(q)) Then
      If CybSys.Ask(0, q) = 255 Then Exit For
      If CybSys.ByteAt(2) = 0 Then Where = q : Exit Function
    End If
  Next
  For q = 1 To 20                                 ' else an idle command line - but never the one in
    If q <> me And (any Or ok(q)) Then            ' front (someone may be typing there)
      If CybSys.Ask(0, q) = 255 Then Exit For
      If CybSys.ByteAt(2) = 1 And CybSys.ByteAt(3) = 0 Then Where = q : Exit Function
    End If
  Next
  why = "no slot free"
End Function

' a running slot: DUMP's 128 bytes (the build's stamp checked), then its 64K into slot s, which goes on
Sub SlotIn()
  If Rcv(VarPtr(hd), 128) <> 128 Then why = "the slot didn't come" : Exit Sub
  r = CybSys.SlotState(s, VarPtr(sb))             ' (this build's stamp)
  If sb(8) <> hd(8) Or sb(9) <> hd(9) Then why = "it is from another build of CyborgOS" : Exit Sub
  If CybSys.ReviveBegin(s) <> 0 Then why = "slot " + Trim$(Str$(s)) + " isn't closed" : Exit Sub
  For k = 0 To 31
    If Rcv(VarPtr(buf), 2048) <> 2048 Then why = "the slot came short" : r = CybSys.Ask(2, s) : Exit Sub
    CybSys.SetWord 2, s : CybSys.SetWord 4, k * 2048 : CybSys.SetWord 6, VarPtr(buf) : CybSys.SetWord 8, 2048
    r = CybSys.Ask(10, 4)
  Next
  For i = 0 To 11
    sb(i) = hd(10 + i)
  Next
  r = CybSys.ReviveDone(s, VarPtr(sb))
  r = CybSys.Pause(s, 0)                          ' (it goes on, from where it was)
End Sub

' a program: saved on SLOTD's drive under its name, then run fresh in slot s
Sub ProgIn()
  a = Named()
  If a = "" Then why = "no name" : Exit Sub
  n = rq(40) + rq(41) * 256& + rq(42) * 65536&
  h = FileSystem.Open(a, FileSystem.ForWrite)
  If h < 0 Then why = "can't save " + a : Exit Sub
  Do While n > 0
    k = 2048
    If n < 2048 Then k = n
    If Rcv(VarPtr(buf), k) <> k Then why = "the program came short" : Exit Do
    If FileSystem.Write(h, VarPtr(buf), k) <> k Then why = "the disc is full" : Exit Do
    n = n - k
  Loop
  r = FileSystem.Close(h)
  If why <> "" Then r = FileSystem.Delete(a) : Exit Sub
  If CybSys.RunIn(s, a) <> 0 Then why = "it wouldn't run" : Exit Sub
End Sub

Function Named() As String Max 12
  Dim q As Integer
  Named = ""
  For q = 1 To rq(27)
    If q <= 12 Then Named = Named + Chr$(rq(27 + q))
  Next
End Function

' ---- the socket: n bytes into addr (what came: fewer when it closed or 20 seconds went by)
Function Rcv(ByVal ad As Integer, ByVal want As Integer) As Integer
  Dim t0 As Integer, t1 As Integer, m As Integer
  got = 0 : t0 = CybSys.Clock()
  Do While got < want
    CybSys.SetWord 2, ad + got : CybSys.SetWord 4, want - got : CybSys.SetWord 6, 0
    If CybSys.Ask(26, c) <> 0 Then Exit Do
    m = CybSys.WordAt(6)
    If m > 0 Then
      got = got + m : t0 = CybSys.Clock()
    Else
      CybSys.SetWord 2, VarPtr(e)
      If CybSys.Ask(22, c) = 3 Then              ' closed: what came with the close read first
        CybSys.SetWord 2, ad + got : CybSys.SetWord 4, want - got : CybSys.SetWord 6, 0
        If CybSys.Ask(26, c) = 0 Then got = got + CybSys.WordAt(6)
        If CybSys.WordAt(6) = 0 Then Exit Do
      End If
      t1 = CybSys.Clock() - t0
      If t1 < 0 Then t1 = t1 + 32767 + 1
      If t1 > 6000 Then Exit Do                   ' (20 seconds)
    End If
  Loop
  Rcv = got
End Function

Sub Reply(ByVal t As String)
  Dim q As Integer
  For q = 1 To Len(t)
    buf(q - 1) = Asc(Mid$(t, q, 1))
  Next
  buf(Len(t)) = 13
  CybSys.SetWord 2, VarPtr(buf) : CybSys.SetWord 4, Len(t) + 1
  r = CybSys.Ask(25, c)
End Sub

Sub Shut(ByVal k As Integer)
  r = CybSys.Ask(27, k)
End Sub

Function Bdos(ByVal fn As Integer, ByVal dd As Integer) As Integer
  Bdos = CybSys.Bdos(fn, dd)
End Function
