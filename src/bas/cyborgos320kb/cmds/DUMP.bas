' DUMP / REVIVE: a slot's program to a file, whole and where it is (DUMP), and back from the file into
' a slot, where it was (REVIVE). One source, two commands: what it does is its own name (DUMP.CYB,
' REVIVE.CYB - the name the kernel put in its bank). Build for cyborgos with CybSys.cls, CybVol.cls.
'   DUMP slot FILE      the program (#0100 to the top of the TPA, trailing zeros trimmed) and its
'                       state to FILE - a running one is paused for it and goes on after
'   REVIVE slot FILE [-f]   FILE back into that slot (closed, or at its command line): the program at
'                       #0100, the rest of the TPA cleared, paused - UNPAUSE slot and it goes on from
'                       where it was dumped. Another slot number is fine
' DUMP refuses a slot with a file open, a claim, a port or a socket (they can't go with it). REVIVE
' refuses a dump from another platform (the build's stamp: C0's bank image) unless -f forces it - but
' a vCPC takes any dump (its TPA is the largest, its model universal). The zero page (#0000-#00FF: C0's
' stubs) and everything above the TPA (C0 itself) are the receiving machine's, never the dump's. Its
' scrollback and store aren't kept. The file: 128 bytes (CYBDUMP1, the state - with the TPA top and the
' trimmed length -, its name, its drive's path), then the program (the trimmed length)
Option Explicit
Dim a As String Max 72, nm As String Max 12, fl As String Max 64, why As String Max 40, pt As String Max 64
Dim s As Integer, r As Integer, i As Integer, j As Integer, h As Integer, k As Integer, ran As Integer, force As Integer
Dim tpa As Long, blen As Long, off As Long, n As Long
Dim hd(127) As Byte, buf(2047) As Byte, tb(159) As Byte, sb(11) As Byte, nb(15) As Byte, b0(1) As Byte

nm = ""
For i = 1 To Peek(&HF6D8)                        ' (this program's name, in its bank)
  If i > 12 Then Exit For
  nm = nm + Chr$(Peek(&HF6D8 + i))
Next
a = Trim$(System.CommandLine())
force = 0
If InStr(UCase$(a), " -F") > 0 Then force = -1 : a = Trim$(Left$(a, InStr(UCase$(a), " -F") - 1)) + " " + Trim$(Mid$(a, InStr(UCase$(a), " -F") + 3))
a = Trim$(a)
i = InStr(a, " ")
If i = 0 Then
  If Left$(nm, 6) = "REVIVE" Then Print "REVIVE slot FILE [-f]" Else Print "DUMP slot FILE"
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
  hd(40) = CybSys.Host()                          ' the platform it came from (REVIVE's message)
  Mem s, 6, VarPtr(b0), 2                           ' the TPA top: the BDOS entry word at #0006
  tpa = b0(0) + b0(1) * 256&
  blen = tpa - &H100                               ' trim trailing zeros from the top down, 2K at a time
  Do While blen > 0
    off = &H100 + blen - 1
    k = CInt((off And &H7FF&) + 1)                  ' bytes back to the 2K boundary (at least 1)
    If k > blen Then k = CInt(blen)
    Mem s, W16(off - k + 1), VarPtr(buf), CInt(k)
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
  Mem s, W16(&HFFFE&), VarPtr(b0), 2               ' the saved stack pointer (the hypervisor put it at #FFFE)
  hd(50) = b0(0) : hd(51) = b0(1)
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
  off = &H100                                      ' the program: #0100 to #0100 + blen
  Do While off < &H100 + blen
    n = &H100 + blen - off
    If n > 2048 Then n = 2048
    Mem s, W16(off), VarPtr(buf), CInt(n)
    If FileSystem.Write(h, VarPtr(buf), n) <> n Then
      r = FileSystem.Close(h) : r = FileSystem.Delete(fl)
      Print "the disc is full - not dumped" : Again : End
    End If
    off = off + n
  Loop
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
  r = CybSys.SlotState(s, VarPtr(sb))             ' (this build's stamp, this host)
  If sb(8) <> hd(8) Or sb(9) <> hd(9) Then      ' another platform: a vCPC (host 4) takes it, else -f
    If CybSys.Host() <> 4 And force = 0 Then r = FileSystem.Close(h) : Print fl; " is from "; Plat(hd(40)); " (REVIVE "; Num(s); " "; fl; " -f to force)" : End
  End If
  tpa = Peek(6) + Peek(7) * 256&                   ' this machine's TPA top
  blen = hd(48) + hd(49) * 256&
  If &H100 + blen > tpa Then r = FileSystem.Close(h) : Print fl; " is too big for this machine's memory" : End
  If CybSys.ReviveBegin(s) <> 0 Then r = FileSystem.Close(h) : Print "slot "; Num(s); " isn't closed (RESET "; Num(s); " first)" : End
  off = &H100                                      ' the program back at #0100 (the trimmed length)
  Do While off < &H100 + blen
    n = &H100 + blen - off
    If n > 2048 Then n = 2048
    If FileSystem.Read(h, VarPtr(buf), CInt(n)) <> n Then
      r = FileSystem.Close(h) : r = CybSys.Ask(2, s)   ' (half read: the slot reset)
      Print fl; " is short - not revived" : End
    End If
    CybSys.SetWord 2, s : CybSys.SetWord 4, W16(off) : CybSys.SetWord 6, VarPtr(buf) : CybSys.SetWord 8, CInt(n)
    r = CybSys.Ask(10, 4)
    off = off + n
  Loop
  r = FileSystem.Close(h)
  Clear s, &H100 + blen, tpa                        ' the rest of the TPA to NOP (#00)
  b0(0) = hd(50) : b0(1) = hd(51)                   ' the saved stack pointer back at #FFFE
  CybSys.SetWord 2, s : CybSys.SetWord 4, W16(&HFFFE&) : CybSys.SetWord 6, VarPtr(b0) : CybSys.SetWord 8, 2
  r = CybSys.Ask(10, 4)
  For i = 0 To 11
    sb(i) = hd(10 + i)
  Next
  For i = 0 To 12
    nb(i) = hd(22 + i)
  Next
  CybSys.SetWord 2, s : CybSys.SetWord 4, W16(&HF6D8&) : CybSys.SetWord 6, VarPtr(nb) : CybSys.SetWord 8, 13
  r = CybSys.Ask(10, 4)                            ' the program's name back in its bank (#F6D8: PS, TOP, the kernel)
  r = CybSys.ReviveDone(s, VarPtr(sb))
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

' a 0..65535 address as the matching signed Integer (for SetWord / Mem, which take Integer)
Function W16(ByVal v As Long) As Integer
  If v > 32767 Then W16 = CInt(v - 65536&) Else W16 = CInt(v)
End Function


' slot t's memory from address lo up to (not including) hi set to 0 (NOP) - 2K at a time
Sub Clear(ByVal t As Integer, ByVal lo As Long, ByVal hi As Long)
  Dim p As Long, c As Long
  For p = 0 To 2047
    buf(p) = 0
  Next
  p = lo
  Do While p < hi
    c = hi - p
    If c > 2048 Then c = 2048
    CybSys.SetWord 2, t : CybSys.SetWord 4, W16(p) : CybSys.SetWord 6, VarPtr(buf) : CybSys.SetWord 8, CInt(c)
    r = CybSys.Ask(10, 4)
    p = p + c
  Loop
End Sub

' the platform a host number names (DUMP's hd(40))
Function Plat(ByVal hh As Integer) As String Max 16
  If hh = 0 Then Plat = "an Amstrad CPC"
  If hh = 1 Then Plat = "a ZX Spectrum Next"
  If hh = 2 Then Plat = "a CPC (C0 build)"
  If hh = 3 Then Plat = "an MSX"
  If hh = 4 Then Plat = "a vCPC"
  If Plat = "" Then Plat = "another machine"
End Function
