' DUMP / REVIVE: a slot's program to a file, whole and where it is (DUMP), and back from the file into
' a slot, where it was (REVIVE). One source, two commands: what it does is its own name (DUMP.CYB,
' REVIVE.CYB - the name the kernel put in its bank). Build for cyborgos with CybSys.cls, CybVol.cls.
'   DUMP slot FILE      the slot's bank (its 64K: the program, its stack and registers, its screen)
'                       and its state to FILE - a running one is paused for it and goes on after
'   REVIVE slot FILE    FILE back into that slot (closed, or at its command line): paused - UNPAUSE
'                       slot and it goes on from where it was dumped. Another slot number is fine
' DUMP refuses a slot with a file open, a claim, a port or a socket (they can't go with it), and
' REVIVE a dump from another build (the build's stamp: C0's bank image). Its scrollback and store
' aren't kept (it gets fresh ones). The file: 128 bytes (CYBDUMP1, the state, its name, its drive's
' path), then the 64K
Option Explicit
Dim a As String Max 72, nm As String Max 12, fl As String Max 64, why As String Max 40, pt As String Max 64
Dim s As Integer, r As Integer, i As Integer, j As Integer, h As Integer, k As Integer, ran As Integer
Dim hd(127) As Byte, buf(2047) As Byte, tb(159) As Byte, sb(11) As Byte, nb(15) As Byte

nm = ""
For i = 1 To Peek(&HF6D8)                        ' (this program's name, in its bank)
  If i > 12 Then Exit For
  nm = nm + Chr$(Peek(&HF6D8 + i))
Next
a = Trim$(System.CommandLine())
i = InStr(a, " ")
If i = 0 Then
  If Left$(nm, 6) = "REVIVE" Then Print "REVIVE slot FILE" Else Print "DUMP slot FILE"
  End
End If
s = Val(Left$(a, i - 1))
fl = UCase$(Trim$(Mid$(a, i + 1)))
If CybSys.State(s) = 255 Then Print "no slot "; Num(s) : End
If Left$(nm, 6) = "REVIVE" Then Revive Else Dump
End

' ---- DUMP slot FILE
Sub Dump()
  If CybSys.State(s) < 2 Then Print "slot "; Num(s); " runs no program" : End
  r = CybSys.SlotState(s, VarPtr(sb))
  why = ""
  If sb(5) Then why = "a file open"
  CybSys.SetWord 2, VarPtr(tb)                   ' its claims (the claims table: 16 of 10 bytes)
  If CybSys.Ask(15, 4) = 0 Then
    For i = 0 To 15
      If tb(i * 10) = s And why = "" Then
        why = "a claim ("
        For j = 2 To 9
          If tb(i * 10 + j) > 32 Then why = why + Chr$(tb(i * 10 + j))
        Next
        why = why + ")"
      End If
    Next
  End If
  For i = 0 To 7                                 ' its ports
    a = CybSys.PortName(i)
    If a <> "" And CybSys.PortSlot() = s And why = "" Then why = "a port (" + a + ")"
  Next
  CybSys.SetWord 2, VarPtr(tb)                   ' its sockets (NETSTAT's list: 8 of 8 bytes)
  If CybSys.Ask(20, 10) <> 255 Then
    For i = 0 To 7
      If tb(i * 8 + 1) <> 0 Or tb(i * 8) <> 0 Then
        If tb(i * 8) = s And why = "" Then why = "a socket open"
      End If
    Next
  End If
  If why <> "" Then Print "slot "; Num(s); " has "; why; " - not dumped" : End
  ran = 0
  If CybSys.State(s) = 2 Then r = CybSys.Pause(s, -1) : ran = -1
  r = CybSys.SlotState(s, VarPtr(sb))             ' (its state now it is paused)
  For i = 0 To 127
    hd(i) = 0
  Next
  a = "CYBDUMP1"
  For i = 1 To 8
    hd(i - 1) = Asc(Mid$(a, i, 1))
  Next
  For i = 0 To 11
    hd(10 + i) = sb(i)
  Next
  hd(8) = sb(8) : hd(9) = sb(9)
  Mem s, &HF6D8, VarPtr(nb), 13                  ' its program's name (in its bank)
  For i = 0 To 12
    hd(22 + i) = nb(i)
  Next
  pt = ""
  If sb(4) >= 65 Then pt = CybVol.PathOf(Chr$(sb(4)))
  hd(35) = Len(pt)
  For i = 1 To Len(pt)
    hd(35 + i) = Asc(Mid$(pt, i, 1))
  Next
  h = FileSystem.Open(fl, FileSystem.ForWrite)
  If h < 0 Then Print "can't make "; fl : Again : End
  r = FileSystem.Write(h, VarPtr(hd), 128)
  For k = 0 To 31
    Mem s, k * 2048, VarPtr(buf), 2048
    If FileSystem.Write(h, VarPtr(buf), 2048) <> 2048 Then
      r = FileSystem.Close(h) : r = FileSystem.Delete(fl)
      Print "the disc is full - not dumped" : Again : End
    End If
  Next
  r = FileSystem.Close(h)
  Again
  Print "slot "; Num(s); " ("; Named(); ") dumped to "; fl; IIf(ran, " - it goes on", "")
End Sub

' a paused slot DUMP paused goes on
Sub Again()
  If ran Then r = CybSys.Pause(s, 0)
End Sub

' ---- REVIVE slot FILE
Sub Revive()
  h = FileSystem.Open(fl, FileSystem.ForReadRaw)
  If h < 0 Then Print "no "; fl : End
  r = FileSystem.Read(h, VarPtr(hd), 128)
  a = ""
  For i = 0 To 7
    a = a + Chr$(hd(i))
  Next
  If r <> 128 Or a <> "CYBDUMP1" Then r = FileSystem.Close(h) : Print fl; " is no dump" : End
  r = CybSys.SlotState(s, VarPtr(sb))             ' (this build's stamp)
  If sb(8) <> hd(8) Or sb(9) <> hd(9) Then r = FileSystem.Close(h) : Print fl; " is from another build" : End
  If CybSys.ReviveBegin(s) <> 0 Then r = FileSystem.Close(h) : Print "slot "; Num(s); " isn't closed (RESET "; Num(s); " first)" : End
  For k = 0 To 31
    If FileSystem.Read(h, VarPtr(buf), 2048) <> 2048 Then
      r = FileSystem.Close(h) : r = CybSys.Ask(2, s)   ' (half written: the slot reset)
      Print fl; " is short - not revived" : End
    End If
    CybSys.SetWord 2, s : CybSys.SetWord 4, k * 2048 : CybSys.SetWord 6, VarPtr(buf) : CybSys.SetWord 8, 2048
    r = CybSys.Ask(10, 4)
  Next
  r = FileSystem.Close(h)
  For i = 0 To 11
    sb(i) = hd(10 + i)
  Next
  r = CybSys.ReviveDone(s, VarPtr(sb))
  For i = 0 To 12
    nb(i) = hd(22 + i)
  Next
  Print "slot "; Num(s); " ("; Named(); ") revived, paused - UNPAUSE "; Num(s); " and it goes on"
  pt = ""
  For i = 1 To hd(35)
    pt = pt + Chr$(hd(35 + i))
  Next
  If hd(14) >= 65 Then
    If CybVol.PathOf(Chr$(hd(14))) <> pt Then Print "(its drive "; Chr$(hd(14)); ": was "; pt; " where it was dumped)"
  End If
End Sub

' n bytes of slot t's memory from address ad to the address to (BDOS 131 op 10, kind 3: 2K at most)
Sub Mem(ByVal t As Integer, ByVal ad As Integer, ByVal dst As Integer, ByVal n As Integer)
  CybSys.SetWord 2, t : CybSys.SetWord 4, ad : CybSys.SetWord 6, dst : CybSys.SetWord 8, n
  r = CybSys.Ask(10, 3)
End Sub

' the program's name in nb (a length, then its letters)
Function Named() As String Max 12
  Dim q As Integer
  Named = ""
  For q = 1 To nb(0)
    If q > 12 Then Exit For
    Named = Named + Chr$(nb(q))
  Next
End Function

Function Num(ByVal v As Integer) As String Max 6
  Num = Trim$(Str$(v))
End Function
