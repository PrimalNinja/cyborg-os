' NETSTAT: the network's connections (CyborgOS - an M4 on the CPC, the ESP on the Next): how the
' network is, then each socket in use - the slot that has it, its state, the address it talks to,
' the bytes waiting to be read. (CyborgOS never listens: every connection is one a program opened.)
' BDOS 131 20/8 and 20/10. Build for the cyborgos platform with CybSys.cls; a .CYB.
'   NETSTAT
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Dim d(63) As Byte, e(63) As Byte, r As Integer, i As Integer, s As Integer, n As Integer, w As Long
Dim t As String Max 40

If System.CommandLine() = "?" Then Print "NETSTAT: the network's connections" : End
CybSys.SetWord 2, VarPtr(e)
r = CybSys.Ask(20, 8)
If r = 255 Then Print "Not CyborgOS, or it has no network" : End
If e(0) = 0 Then Print "The network is off (NET M4 on the CPC, NET ESP on the Next)" : End
t = ""
For i = 28 To 58
  If e(i) = 0 Then Exit For
  t = t + Chr$(e(i))
Next
If e(0) = 2 Then
  Print "Connected: "; Trim$(Str$(e(2))); "."; Trim$(Str$(e(3))); "."; Trim$(Str$(e(4))); "."; Trim$(Str$(e(5)));
  If t <> "" Then Print " ("; t; ")" Else Print
Else
  Print "Not connected to a network";
  If t <> "" Then Print " ("; t; ")" Else Print
End If
CybSys.SetWord 2, VarPtr(d)
n = CybSys.Ask(20, 10)
If n = 0 Then Print "No connections" : End
Print "Socket Slot State          Address          Waiting"
For s = 0 To 7
  i = s * 8
  If d(i) <> 0 Then
    w = d(i + 3)
    w = w * 256 + d(i + 2)
    t = Trim$(Str$(d(i + 4))) + "." + Trim$(Str$(d(i + 5))) + "." + Trim$(Str$(d(i + 6))) + "." + Trim$(Str$(d(i + 7)))
    Print Pad(Str$(s), 7); Pad(Str$(d(i)), 5); Pad(Named(d(i + 1)), 15); Pad(t, 17); Trim$(Str$(w))
  End If
Next
End

Function Named(ByVal k As Integer) As String
  If k = 0 Then
    Named = "open"
  ElseIf k = 1 Then
    Named = "connecting"
  ElseIf k = 2 Then
    Named = "sending"
  ElseIf k = 3 Then
    Named = "closed (other)"
  ElseIf k = 5 Then
    Named = "looking up"
  Else
    Named = "error " + Trim$(Str$(k))
  End If
End Function

' t trimmed and padded with spaces to n characters
Function Pad(ByVal t As String, ByVal n As Integer) As String
  Pad = Left$(Trim$(t) + "                    ", n)
End Function
