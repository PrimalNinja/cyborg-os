' M4TIME: the M4 board's clock (CyborgOS, build for cpm, with CybSys.cls; the CPC) - its C_TIME,
' "hh:mm:ss yyyy-mm-dd": the M4 sets it itself from the network's time (NTP) once it is on WiFi.
' The network needn't be on (NET M4): C0 asks the M4 for this program (BDOS 131 op 20 / 11).
'   M4TIME          the M4's date and time
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Dim t(15) As Byte, k As Integer, i As Integer, r As Integer, a As String Max 40

k = -1
For i = 0 To 127                                 ' the ROMs (0-127): one named M4 BOARD
  If Peek8(i, &HC000) Then
    If Name(i) = "M4 BOARD" Then k = i : Exit For
  End If
Next
If k < 0 Then Print "No M4 board (no ROM named M4 BOARD)" : End
r = CybSys.Held("M4", 0)
If r > 0 And r < 254 Then Print "The M4 is claimed by slot "; Trim$(Str$(r)); " (CLAIMS)" : End
CybSys.SetWord 2, k
If CybSys.Ask(20, 11) <> 0 Then Print "Not CyborgOS, or this CyborgOS can't ask the M4 its time" : End
a = CybSys.TextAt(6)
If a = "" Then Print "The M4 gave no time" : End
Print "M4 (ROM "; Trim$(Str$(k)); "): "; Mid$(a, 10); " "; Left$(a, 8)
If Mid$(a, 10, 4) < "2000" Then Print "(not set yet: the M4 sets its clock once it is on the network)"
End

' 16 bytes of ROM r at address ad into t: True when it is there (a background ROM: type 0-2)
Function Peek8(ByVal r As Integer, ByVal ad As Integer) As Integer
  CybSys.SetWord 2, r
  CybSys.SetWord 4, ad
  CybSys.SetWord 6, VarPtr(t)
  CybSys.SetWord 8, 16
  Peek8 = 0
  If CybSys.Ask(10, 1) <> 0 Then Exit Function
  Peek8 = (t(0) <= 2)
End Function

' ROM r's name (its first command's: the last character + #80)
Function Name(ByVal r As Integer) As String Max 16
  Dim s As String Max 16, q As Integer
  Name = ""
  q = t(4) + t(5) * 256
  If (q And &HC000) <> &HC000 Then Exit Function
  q = Peek8(r, q)
  s = ""
  For q = 0 To 15
    If t(q) = 0 Then Exit For
    s = s + Chr$(t(q) And 127)
    If t(q) >= 128 Then Exit For
  Next
  Name = s
End Function
