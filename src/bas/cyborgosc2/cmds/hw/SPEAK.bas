' SPEAK: allophones to an SP0256-AL2 speech card - the Amstrad SSA-1 (&FBEE) or the dk'tronics
' (&FBFE), and LambdaSpeak 3 / Speak&SID in those modes (CyborgOS, build for cpm, with CybSys.cls;
' the CPC). The same code for both: the port and the "ready for the next" bit apart (SSA-1: bit 6
' 0, dk'tronics: bit 7 0). Between allophones it waits in a loop, which gives the other slots
' their time - no interrupt needed. Claims SPEECH 0 (SSA-1) or SPEECH 1 (dk'tronics).
'   SPEAK [SSA | DKT] word ...        HELLO, TEST, CYBORG (a small table), or allophone numbers
'                                     (0-63: 0-4 are pauses) - SSA if not given
' A few allophones: 0-4 pauses PA1-PA5, 7 EH, 13 TT2, 15 AX, 16 MM, 19 IY, 24 AA, 27 HH1, 34 GG3,
' 41 KK2, 45 LL, 53 OW, 55 SS, 58 OR, 63 BB2 (the SP0256-AL2's table).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Dim a As String Max 72, w As String Max 20, port As Integer, mask As Integer, u As Integer
Dim i As Integer, r As Integer, n As Integer, k As Integer

a = UCase$(Trim$(CybSys.Tail()))
port = &HFBEE : mask = &H40 : u = 0
If Left$(a, 4) = "DKT " Then port = &HFBFE : mask = &H80 : u = 1 : a = Trim$(Mid$(a, 5))
If Left$(a, 4) = "SSA " Then a = Trim$(Mid$(a, 5))
If a = "" Then
  Print "SPEAK [SSA | DKT] word ...   HELLO, TEST, CYBORG, or allophone numbers (0-63)"
  End
End If
r = CybSys.Claim("SPEECH", u)
If r <> 0 And r <> 255 Then Print "The speech card is claimed by slot "; Trim$(Str$(r)); " (CLAIMS)" : End
n = 0
Do While a <> ""
  i = InStr(a, " ")
  If i = 0 Then w = a : a = "" Else w = Left$(a, i - 1) : a = Trim$(Mid$(a, i + 1))
  If w = "HELLO" Then
    Say "27 7 7 45 53 4"
  ElseIf w = "TEST" Then
    Say "13 7 7 55 55 13 4"
  ElseIf w = "CYBORG" Then
    Say "55 55 6 1 28 58 34 4"
  ElseIf Val(w) > 0 Or w = "0" Then
    Say w
  Else
    Print "? "; w
  End If
Loop
r = CybSys.Release("SPEECH", u)
If n > 0 Then Print Trim$(Str$(n)); " allophones to &"; Hex$(port)
End

' the allophone numbers in s (spaces between), each when the chip is ready for it
Sub Say(ByVal s As String)
  Dim j As Integer, v As String Max 8, t As Integer
  Do While s <> ""
    j = InStr(s, " ")
    If j = 0 Then v = s : s = "" Else v = Left$(s, j - 1) : s = Trim$(Mid$(s, j + 1))
    t = CybSys.Clock()
    Do While (Inp(port) And mask) <> 0              ' not ready yet (a second at most)
      If CybSys.Clock() - t > 300 Then
        Print "No speech card answering at &"; Hex$(port); " (its status: &"; Hex$(Inp(port) And 255); ")"
        r = CybSys.Release("SPEECH", u)
        End
      End If
    Loop
    Out port, Val(v) And 63
    n = n + 1
  Loop
End Sub
