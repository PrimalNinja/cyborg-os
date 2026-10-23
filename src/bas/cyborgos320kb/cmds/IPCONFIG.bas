' IPCONFIG: the network's addresses (CyborgOS - an M4 on the CPC, the ESP on the Next): whether it
' is connected (and the board's own message), the IP address, netmask, gateway, DNS servers, MAC
' and the signal. BDOS 131 20/8. Build for the cyborgos platform with CybSys.cls; a .CYB.
'   IPCONFIG
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Dim d(63) As Byte, r As Integer, i As Integer, m As String Max 40

If System.CommandLine() = "?" Then Print "IPCONFIG: the network's addresses" : End
CybSys.SetWord 2, VarPtr(d)
r = CybSys.Ask(20, 8)
If r = 255 Then Print "Not CyborgOS, or it has no network" : End
If d(0) = 0 Then Print "The network is off (NET M4 on the CPC, NET ESP on the Next)" : End
m = ""
For i = 28 To 58
  If d(i) = 0 Then Exit For
  m = m + Chr$(d(i))
Next
If m <> "" Then Print m
If d(0) = 1 Then Print "Not connected to a network" : End
Print "IP address   "; Ip(2)
Print "Netmask      "; Ip(6)
Print "Gateway      "; Ip(10)
If d(14) Or d(15) Or d(16) Or d(17) Then Print "DNS          "; Ip(14); "  "; Ip(18)   ' (the Next's ESP: not asked)
Print "MAC          "; Hx(22); ":"; Hx(23); ":"; Hx(24); ":"; Hx(25); ":"; Hx(26); ":"; Hx(27)
If d(1) <> 255 Then
  If CybSys.Host() = 1 Then Print "Signal       -"; Trim$(Str$(d(1))); " dBm" Else Print "Signal       &"; Hx(1)
End If
End

' the 4 bytes from d(i) as an address: 192.168.1.2
Function Ip(ByVal i As Integer) As String
  Ip = Trim$(Str$(d(i))) + "." + Trim$(Str$(d(i + 1))) + "." + Trim$(Str$(d(i + 2))) + "." + Trim$(Str$(d(i + 3)))
End Function

Function Hx(ByVal i As Integer) As String
  Hx = Right$("0" + Hex$(d(i)), 2)
End Function
