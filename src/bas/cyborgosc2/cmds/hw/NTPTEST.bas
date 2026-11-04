' NTPTEST: the time from an NTP server through a Net4CPC / Cyboard (a WIZnet W5100S at &FD20-&FD23)
' - CyborgOS, build for cpm, with CybSys.cls; the CPC. One UDP packet out of socket 3 to port 123,
' the 48 byte answer read back: the first piece of the W5100S driver (open, send, receive, close).
'   NTPTEST [a.b.c.d]     the server (an IP address: the W5100S has no DNS) - 216.239.35.0
'                         (time.google.com) if not given
' The board's own address (SIPR), its netmask and gateway are what NCFG / the board's set-up
' left: NTPTEST doesn't change them. Claims W5100 0 while it runs.
' The W5100S in its indirect mode: &FD21 / &FD22 the address (high, low), &FD23 the data; &FD20
' its mode register (left alone). Socket 3's registers at &0700 (MR +0, CR +1, IR +2, SR +3, the
' local port +4, the IP +12, the port +16, TX_FSR +32, TX_RD +34, TX_WR +36, RX_RSR +38, RX_RD
' +40); its buffers 2K each, TX at &5800, RX at &7800.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Const S = &H700                                ' socket 3's registers
Const TXB = &H5800
Const RXB = &H7800
Dim a As String Max 72, ip(3) As Integer, i As Integer, r As Integer, t As Integer, n As Integer
Dim p As Integer, hi As Long, lo As Long, u As Long, dy As Long, sc As Long
Dim yy As Long, mo As Long, dd As Long, era As Long, doe As Long, yoe As Long, doy As Long, mp As Long
Dim pk(47) As Integer

If Rd(&H80) <> &H51 Then Print "No W5100S at &FD20-&FD23 (its version register: "; Hex2(Rd(&H80)); ")" : End
a = Trim$(CybSys.Tail())
If a = "" Then a = "216.239.35.0"
If Not ParseIp(a) Then Print "NTPTEST [a.b.c.d]   (an IP address)" : End
r = CybSys.Claim("W5100", 0)
If r <> 0 And r <> 255 Then Print "The Net4CPC is claimed by slot "; Trim$(Str$(r)); " (CLAIMS)" : End
Print "Net4CPC: W5100S, IP "; IpAt(&HF); " gateway "; IpAt(1); " MAC "; Mac()
If Rd(&HF) = 0 Then Print "(no IP address set: NCFG on the real board; 1984's host sockets don't mind)"

Cmd &H10                                       ' close, in case
Wr S, 2                                        ' UDP
Wr S + 4, &H30 : Wr S + 5, &H39                ' from port 12345
Cmd 1                                          ' open
If Rd(S + 3) <> &H22 Then Print "Socket 3 didn't open as UDP (its state: "; Hex2(Rd(S + 3)); ")" : Fin
For i = 0 To 3 : Wr S + 12 + i, ip(i) : Next   ' to the server's port 123
Wr S + 16, 0 : Wr S + 17, 123

For i = 0 To 47 : pk(i) = 0 : Next             ' the request: LI 0, version 3, mode 3 (client)
pk(0) = &H1B
p = Rd(S + 36) * 256 + Rd(S + 37)              ' TX_WR: where the data goes
For i = 0 To 47
  Wr TXB + ((p + i) And &H7FF), pk(i)
Next
p = p + 48
Wr S + 36, ((p And &HFF00) \ 256) And 255 : Wr S + 37, p And 255   ' (And first: #8000 on is negative)
Wr S + 2, &HFF                                 ' (its flags cleared)
Cmd &H20                                       ' send
t = CybSys.Clock()
Do While (Rd(S + 2) And &H18) = 0              ' SEND_OK or TIMEOUT
  If CybSys.Clock() - t > 900 Then Exit Do
Loop
If (Rd(S + 2) And 8) <> 0 Then Print "Sent, but no route to "; a; " (TIMEOUT: no ARP answer)" : Fin
Print "Sent to "; a; ":123, waiting ..."
t = CybSys.Clock()
Do While Rd(S + 38) * 256 + Rd(S + 39) < 8     ' RX_RSR: a packet waiting
  If CybSys.Clock() - t > 1500 Then Print "No answer in 5 seconds" : Fin
Loop
p = Rd(S + 40) * 256 + Rd(S + 41)              ' RX_RD
n = Rx(p + 6) * 256 + Rx(p + 7)                ' the 8 byte header: its IP, port, length
Print "Answer from "; Trim$(Str$(Rx(p))); "."; Trim$(Str$(Rx(p + 1))); "."; Trim$(Str$(Rx(p + 2))); "."; Trim$(Str$(Rx(p + 3))); ", "; Trim$(Str$(n)); " bytes"
If n >= 48 Then
  For i = 0 To 47 : pk(i) = Rx(p + 8 + i) : Next
End If
p = p + 8 + n
Wr S + 40, ((p And &HFF00) \ 256) And 255 : Wr S + 41, p And 255
Cmd &H40                                       ' recv: the packet read
If n < 48 Then Print "Too short for NTP" : Fin
' the transmit time: seconds since 1900 at bytes 40-43 - less 2208988800 (&83AA7E80): since 1970
hi = pk(40) * 256& + pk(41)
lo = pk(42) * 256& + pk(43)
u = (hi - &H83AA&) * 65536& + (lo - &H7E80&)
dy = u \ 86400&
sc = u - dy * 86400&
' the civil date from the days since 1970-01-01 (Howard Hinnant's days_from_civil, turned round)
dy = dy + 719468&
era = dy \ 146097&
doe = dy - era * 146097&
yoe = (doe - doe \ 1460& + doe \ 36524& - doe \ 146096&) \ 365&
yy = yoe + era * 400&
doy = doe - (365& * yoe + yoe \ 4& - yoe \ 100&)
mp = (5& * doy + 2&) \ 153&
dd = doy - (153& * mp + 2&) \ 5& + 1&
If mp < 10 Then mo = mp + 3& Else mo = mp - 9&
If mo <= 2 Then yy = yy + 1&
Print "NTP: "; Trim$(Str$(yy)); "-"; Two(mo); "-"; Two(dd); " "; Two(sc \ 3600&); ":"; Two((sc \ 60&) Mod 60&); ":"; Two(sc Mod 60&); " UTC"
Fin

' socket 3 closed, the claim given back, the end
Sub Fin()
  Cmd &H10
  r = CybSys.Release("W5100", 0)
  End
End Sub

' the W5100S's byte at address ad, and a byte written there
Function Rd(ByVal ad As Integer) As Integer
  Out &HFD21, (ad \ 256) And 255
  Out &HFD22, ad And 255
  Rd = Inp(&HFD23) And 255
End Function
Sub Wr(ByVal ad As Integer, ByVal v As Integer)
  Out &HFD21, (ad \ 256) And 255
  Out &HFD22, ad And 255
  Out &HFD23, v
End Sub
' the receive buffer's byte at offset o (wrapping in its 2K)
Function Rx(ByVal o As Integer) As Integer
  Rx = Rd(RXB + (o And &H7FF))
End Function
' a socket command, and its end (the command register back to 0)
Sub Cmd(ByVal c As Integer)
  Dim k As Integer
  Wr S + 1, c
  For k = 1 To 500
    If Rd(S + 1) = 0 Then Exit For
  Next
End Sub

' "a.b.c.d" into ip(): True when it is one
Function ParseIp(ByVal s As String) As Integer
  Dim k As Integer, j As Integer, c As Integer, v As Integer
  ParseIp = 0
  j = 0 : v = -1
  For k = 1 To Len(s)
    c = Asc(Mid$(s, k, 1))
    If c = 46 Then
      If v < 0 Or v > 255 Or j > 2 Then Exit Function
      ip(j) = v : j = j + 1 : v = -1
    ElseIf c >= 48 And c <= 57 Then
      If v < 0 Then v = 0
      v = v * 10 + c - 48
    Else
      Exit Function
    End If
  Next
  If j <> 3 Or v < 0 Or v > 255 Then Exit Function
  ip(3) = v
  ParseIp = -1
End Function

Function IpAt(ByVal ad As Integer) As String
  IpAt = Trim$(Str$(Rd(ad))) + "." + Trim$(Str$(Rd(ad + 1))) + "." + Trim$(Str$(Rd(ad + 2))) + "." + Trim$(Str$(Rd(ad + 3)))
End Function
Function Mac() As String
  Dim k As Integer, m As String Max 20
  m = ""
  For k = 9 To 14
    m = m + Right$("0" + Hex$(Rd(k)), 2)
    If k < 14 Then m = m + ":"
  Next
  Mac = m
End Function
Function Two(ByVal v As Long) As String
  Two = Right$("0" + Trim$(Str$(v)), 2)
End Function
Function Hex2(ByVal v As Integer) As String
  Hex2 = "&" + Right$("0" + Hex$(v), 2)
End Function
