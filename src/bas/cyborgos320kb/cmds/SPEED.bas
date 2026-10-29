' SPEED: how fast this slot's Z80 runs, against a 4 MHz Amstrad CPC. A loop of DJNZ (a CPC runs
' 250,000 of them a second: 4 microseconds each) for about 3 seconds of CyborgOS's clock (300 a
' second), then how many it did. The same .CYB on a CPC, a Next, an MSX and a vCPC: on the CPC
' itself it says a little under 1 (CyborgOS's own work between its slices); other programs running
' slow it (it measures its slot's share). Build for cyborgos with CybSys.cls.
'   SPEED          the test
'   SPEED n        n seconds of it (1-60)
Option Explicit
Dim n As Long, t0 As Integer, d As Integer, s As Integer, x As Long, a As String Max 20
a = Trim$(System.CommandLine())
s = 3
If a <> "" Then s = Val(a)
If s < 1 Or s > 60 Then s = 3
Print "SPEED: timing this slot's Z80 for "; Trim$(Str$(s)); IIf(s = 1, " second...", " seconds...")
t0 = CybSys.Clock()
n = 0
Do
  Spin
  n = n + 1
  d = CybSys.Clock() - t0
  If d < 0 Then d = d + 32767 + 1                ' (the clock wrapped past 32767)
Loop Until d >= s * 300
' each Spin: 25,600 DJNZ = 0.1024 s on a CPC; d ticks of 1/300 s: n * 25600 * 300 / d a second,
' against 250,000 - in hundredths: n * 3072 / d
x = n * 3072 \ d
Print "  "; Trim$(Str$(n)); " loops of 25,600 DJNZ in "; Trim$(Str$(d)); " ticks (1/300 s)"
Print "  "; Trim$(Str$(x \ 100)); "."; Right$("0" + Trim$(Str$(x Mod 100)), 2); " times a 4 MHz CPC - about "; Trim$(Str$(x * 4 \ 100)); " MHz"

' 25,600 DJNZ (100 rounds of 256): 0.1024 s on a CPC - short enough to keep CyborgOS's turns going
Sub Spin()
#asm
            ld c, 100
spd_out:
            ld b, 0
spd_in:
            djnz spd_in
            dec c
            jr nz, spd_out
#endasm
End Sub
