' HWINFO: the hardware CyborgOS can see on this CPC - each thing looked for in a way that changes
' nothing (reads, or a write put back), with where it is (CyborgOS, build for cpm, with
' CybSys.cls; the CPC)
'   HWINFO          the list
'   HWINFO ALL      the Albireo looked for too when there is an M4 (the M4 decodes &FExx widely on
'                   some set-ups, 1984's emulation among them: a write to &FE80 reaches it)
' What it looks for: the expansion ROMs (0-31, by name), the V9990 (R#15 written and read back,
' then put back), the DS12887 clock (registers A and D), the Net4CPC's W5100S (its version
' register: &51), the Albireos' CH376 (CHECK_EXIST: a byte back inverted), the SYMBiFACE II's PS/2
' mouse port, the speech ports (SSA-1 &FBEE, dk'tronics &FBFE - LambdaSpeak, Speak&SID), the CPC
' Booster (&FF00: 170). &FF from a port: nothing there (the bus floats high).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Dim t(15) As Byte, i As Integer, v As Integer, w As Integer, m4 As Integer, a As String Max 40
Dim all As Integer, nm As String Max 16, n As Integer

all = (UCase$(Trim$(CybSys.Tail())) = "ALL")
Print "CyborgOS on ";
If CybSys.Host() = 1 Then Print "a ZX Spectrum Next" Else Print "an Amstrad CPC"
Print "ROMs:"
m4 = -1 : n = 0
For i = 0 To 31
  If Peek8(i, &HC000) Then
    a = "extension"                              ' (its type: the first byte - before Name reads on)
    If t(0) = 0 Or t(0) = &H80 Then a = "foreground"
    If t(0) = 1 Then a = "background"
    nm = Name(i)
    If nm = "M4 BOARD" Then m4 = i
    If nm <> "BASIC" Then                        ' (an empty slot reads as BASIC: ROM 0 answers)
      Print "  "; Right$(" " + Trim$(Str$(i)), 2); "  "; Left$(nm + "                ", 16); a
      n = n + 1
    End If
  End If
Next
If n = 0 Then Print "  (none but BASIC)"
Print "Devices:"
' the V9990: R#15 (the backdrop) read, written, read back, put back
Out &HFF64, &H4F                                 ' R#15, reads not moving on (RII)
v = Inp(&HFF63) And 255
Out &HFF64, &H8F                                 ' R#15, writes not moving on (WII)
Out &HFF63, (v Xor &H15) And &H3F
Out &HFF64, &H4F
w = Inp(&HFF63) And 255
Out &HFF64, &H8F
Out &HFF63, v
If (w And &H3F) = ((v Xor &H15) And &H3F) Then Row "V9990 (Powergraph / GFX9000)", "&FF60", "found" Else Row "V9990", "&FF60", "-"
' the DS12887
Out &HFD15, 10 : v = Inp(&HFD14) And 255
Out &HFD15, 13 : w = Inp(&HFD14) And 255
If (v And &H70) = &H20 And (w And 127) = 0 Then
  a = "found"
  If (w And 128) = 0 Then a = "found - its battery is flat (register D)"
  Row "DS12887 clock (RTCTEST)", "&FD14", a
Else
  Row "DS12887 clock", "&FD14", "-"
End If
' the Net4CPC's W5100S: the version register at &0080
Out &HFD21, 0 : Out &HFD22, &H80 : v = Inp(&HFD23) And 255
If v = &H51 Then Row "Net4CPC W5100S (NTPTEST)", "&FD20", "found" Else Row "Net4CPC W5100S", "&FD20", "-"
' the SYMBiFACE II's mouse: 0 when there is none, a stream when moved
v = Inp(&HFD10) And 255
If v = 255 Then a = "-" Else a = "answers (&" + Right$("0" + Hex$(v), 2) + ")"
Row "SYMBiFACE II PS/2 mouse", "&FD10", a
' the M4
If m4 >= 0 Then Row "M4 (M4TIME)", "ROM " + Trim$(Str$(m4)), "found" Else Row "M4", "", "-"
' the Albireos (CH376: CHECK_EXIST, then GET_IC_VER)
If m4 >= 0 And Not all Then
  Row "Albireo (CH376)", "&FE80", "not looked for (an M4: HWINFO ALL)"
Else
  Alb &HFE80, "Albireo 1 (CH376)"
  Alb &HFE40, "Albireo 2 (CH376)"
End If
' the speech ports: the SP0256's status (SSA-1: bit 7 standby, bit 6 load request; dk'tronics bit 7)
v = Inp(&HFBEE) And 255
If v = 255 Then a = "-" Else a = "answers (&" + Right$("0" + Hex$(v), 2) + ")"
Row "Speech SSA-1 port (SPEAK)", "&FBEE", a
v = Inp(&HFBFE) And 255
If v = 255 Then a = "-" Else a = "answers (&" + Right$("0" + Hex$(v), 2) + ")"
Row "Speech dk'tronics (SPEAK DKT)", "&FBFE", a
' the CPC Booster: &FF00 170, &FF01 85 (a Booster) or 238 (a MiniBooster)
v = Inp(&HFF00) And 255
If v = 170 Then
  w = Inp(&HFF01) And 255
  If w = 238 Then a = "MiniBooster" Else a = "CPC Booster"
  Row a, "&FF00", "found"
Else
  Row "CPC Booster", "&FF00", "-"
End If
Print "Not looked for (no safe test yet): USIfAC II, CPC-CPLink, MultiPlay,"
Print "PlayCity, Nova, Multiface II; the SID: SIDTEST."
End

Sub Row(ByVal what As String, ByVal at As String, ByVal st As String)
  Print "  "; Left$(what + "                              ", 30); Left$(at + "       ", 7); " "; st
End Sub

' a CH376 at port base p (data), p + 1 (command / status)
Sub Alb(ByVal p As Integer, ByVal what As String)
  Dim x As Integer, y As Integer
  Out p + 1, 6                                   ' CHECK_EXIST
  Out p, &H5A
  x = Inp(p) And 255
  If x <> &HA5 Then Row what, "&" + Hex$(p), "-" : Exit Sub
  Out p + 1, 1                                   ' GET_IC_VER
  y = Inp(p) And 63
  Row what, "&" + Hex$(p), "found (version " + Trim$(Str$(y)) + ")"
End Sub

' 16 bytes of ROM r at address ad into t: True when it is there (a ROM: type 0-2 or &80 BASIC)
Function Peek8(ByVal r As Integer, ByVal ad As Integer) As Integer
  CybSys.SetWord 2, r
  CybSys.SetWord 4, ad
  CybSys.SetWord 6, VarPtr(t)
  CybSys.SetWord 8, 16
  Peek8 = 0
  If CybSys.Ask(10, 1) <> 0 Then Exit Function
  Peek8 = (t(0) <= 2) Or (t(0) = &H80)
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
