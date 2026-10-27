' RTCTEST: the DS12887 real time clock (SYMBiFACE II, Cyboard, X-MEM's) - its date and time, read
' from the chip (CyborgOS, build for cpm, with CybSys.cls; the CPC)
'   RTCTEST                          the date and time, the chip's mode (BCD / binary, 12 / 24 h)
'   RTCTEST SET yyyy-mm-dd hh:mm:ss  set it (claims RTC 0 while it does)
' The chip: &FD15 the register (written), &FD14 its value (read / written). Registers 0 seconds,
' 2 minutes, 4 hours, 6 the day of the week, 7 the day, 8 the month, 9 the year (0-99), 10 A (bit
' 7: an update going on), 11 B (bit 7 SET: the clock stopped while it is set, bit 2 binary, bit 1
' 24 hour), 13 D (bit 7: the time is valid - the battery good), 50 the century (on most boards).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Const RSEL = &HFD15
Const RDAT = &HFD14
Dim a As String Max 72, regb As Integer, bin As Integer, h24 As Integer, r As Integer
Dim yy As Integer, mo As Integer, dd As Integer, hh As Integer, mi As Integer, ss As Integer
Dim cen As Integer, wd As Integer, pm As Integer, n As Integer

If Not Found() Then Print "No DS12887 clock at &FD14 / &FD15 (register D: "; Hex2(Rg(13)); ")" : End
regb = Rg(11)
bin = (regb And 4) <> 0
h24 = (regb And 2) <> 0
a = UCase$(Trim$(CybSys.Tail()))
If Left$(a, 4) = "SET " Then
  a = Trim$(Mid$(a, 5))
  If Len(a) < 19 Then Print "RTCTEST SET yyyy-mm-dd hh:mm:ss" : End
  r = CybSys.Claim("RTC", 0)
  If r <> 0 And r <> 255 Then Print "The clock is claimed by slot "; Trim$(Str$(r)); " (CLAIMS)" : End
  yy = Val(Mid$(a, 1, 4)) : mo = Val(Mid$(a, 6, 2)) : dd = Val(Mid$(a, 9, 2))
  hh = Val(Mid$(a, 12, 2)) : mi = Val(Mid$(a, 15, 2)) : ss = Val(Mid$(a, 18, 2))
  WrReg 11, regb Or 128                         ' SET: the clock held while it is written
  WrReg 0, Fm(ss) : WrReg 2, Fm(mi) : WrReg 4, Fm(hh)
  WrReg 7, Fm(dd) : WrReg 8, Fm(mo) : WrReg 9, Fm(yy Mod 100) : WrReg 50, Fm(yy \ 100)
  WrReg 11, (regb And 127) Or 2                 ' running again, 24 hours
  regb = Rg(11)
  h24 = 1
  r = CybSys.Release("RTC", 0)
  Print "Set."
ElseIf a <> "" Then
  Print "RTCTEST                          the date and time"
  Print "RTCTEST SET yyyy-mm-dd hh:mm:ss  set it"
  End
End If
n = 0
Do While (Rg(10) And 128) <> 0                  ' an update going on: wait for it to end (under 2 ms)
  n = n + 1
  If n > 1000 Then Print "The clock stays in its update (register A: "; Hex2(Rg(10)); ")" : End
Loop
ss = Dc(Rg(0)) : mi = Dc(Rg(2)) : r = Rg(4) : wd = Dc(Rg(6))
dd = Dc(Rg(7)) : mo = Dc(Rg(8)) : yy = Dc(Rg(9)) : cen = Rg(50)
pm = 0
If Not h24 Then
  pm = (r And 128) <> 0
  hh = Dc(r And 127)
  If hh = 12 Then hh = 0
  If pm Then hh = hh + 12
Else
  hh = Dc(r)
End If
cen = Dc(cen)
If cen < 19 Or cen > 21 Then cen = 20                ' (no century register: 20)
Print "DS12887 at &FD14: "; Trim$(Str$(cen)); Two(yy); "-"; Two(mo); "-"; Two(dd); " "; Two(hh); ":"; Two(mi); ":"; Two(ss); "  ("; Day(wd); ")"
a = "BCD"
If bin Then a = "binary"
If h24 Then a = a + ", 24 hour" Else a = a + ", 12 hour"
Print "Mode: "; a; "  A="; Hex2(Rg(10)); " B="; Hex2(regb); " D="; Hex2(Rg(13))
End

' register i's value
Function Rg(ByVal i As Integer) As Integer
  Out RSEL, i
  Rg = Inp(RDAT) And 255
End Function
Sub WrReg(ByVal i As Integer, ByVal v As Integer)
  Out RSEL, i
  Out RDAT, v
End Sub
' a DS12887: register A's divider bits 010 (the oscillator on), D's bits 0-6 always 0
Function Found() As Integer
  Found = ((Rg(10) And &H70) = &H20) And ((Rg(13) And 127) = 0)
End Function
' the chip's number to ours (BCD or binary as register B says), and back
Function Dc(ByVal v As Integer) As Integer
  If bin Then Dc = v Else Dc = (v \ 16) * 10 + (v And 15)
End Function
Function Fm(ByVal v As Integer) As Integer
  If bin Then Fm = v Else Fm = (v \ 10) * 16 + (v Mod 10)
End Function
Function Two(ByVal v As Integer) As String
  Two = Right$("0" + Trim$(Str$(v)), 2)
End Function
Function Hex2(ByVal v As Integer) As String
  Hex2 = "&" + Right$("0" + Hex$(v), 2)
End Function
' the day of the week: 1 Sunday ... 7 Saturday (the datasheet's; some boards count 7 as Sunday)
Function Day(ByVal w As Integer) As String
  If w < 1 Or w > 7 Then Day = "?" : Exit Function
  Day = Mid$("SunMonTueWedThuFriSat", 1 + 3 * ((w - 1) Mod 7), 3)
End Function
