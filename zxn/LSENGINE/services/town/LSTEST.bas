' LSTEST: stands in for the game (CyborgOS) - drives the TOWN service through one day of LITTLE SEOUL
' the way a game would: the clock 10 minutes a step, the town's numbers each hour, five people at noon,
' and at 13:00 aliens land on the post office's street (70) and frighten everyone within 2 streets.
'   RUN 2 LSMODEL SUIT : RUN 3 LSMODEL KEEPER : RUN 4 LSMODEL STAR : RUN 5 RAT : RUN 6 TOWN : LSTEST [day]
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Dim m As Integer, d As Integer, n As Integer, p As Integer, t As Integer
Dim rp As String Max 128

d = Val(CybSys.Tail())
Print "LSTEST: waiting for TOWN";
Do
  rp = CybSys.PortCall("TOWN", "S")
  If CybSys.PortStatus() = 0 Then Exit Do
Loop
Print
For m = 540 To 1080 Step 10
  rp = CybSys.PortCall("TOWN", "T " + Trim$(Str$(d)) + " " + Trim$(Str$(m)))
  n = 0
  Do                                          ' (the town catches up: everyone due has decided)
    rp = CybSys.PortCall("TOWN", "P")
    n = n + 1
  Loop Until Val(rp) = 0 Or n > 400
  If m Mod 60 = 0 Then Print Clock(m); " "; CybSys.PortCall("TOWN", "S")
  If m = 720 Then
    For p = 0 To 4
      Print "  "; p; ": "; CybSys.PortCall("TOWN", "W " + Trim$(Str$(p)))
    Next
  End If
  If m = 780 Then
    Print "  street 70 before: "; CybSys.PortCall("TOWN", "R 70")
    Print "  ALIENS LAND ON STREET 70: "; CybSys.PortCall("TOWN", "F 70 90 2")
  End If
  If m = 790 Or m = 820 Then
    Print Clock(m); " "; CybSys.PortCall("TOWN", "S")
    Print "  street 70 now: "; CybSys.PortCall("TOWN", "R 70")
  End If
Next
Print "LSTEST: the day is over"
End

Function Clock(ByVal m As Integer) As String
  Dim s As String Max 6
  s = Trim$(Str$(m Mod 60))
  If Len(s) < 2 Then s = "0" + s
  Clock = Trim$(Str$(m \ 60)) + ":" + s
End Function
