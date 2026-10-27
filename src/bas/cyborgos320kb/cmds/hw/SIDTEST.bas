' SIDTEST: Speak&SID's SID (a MOS 6581 / 8580) - a C major chord, a note on each voice, then all
' three (CyborgOS, build for cpm, with CybSys.cls; the CPC). The SID's 25 write registers at
' &FAC0-&FAD8 (one OUT a register, no microcontroller in the way); claims SID 0.
'   SIDTEST         the notes
'   SIDTEST ON      Speak&SID put in its SID mode first (255, 4 to &FBEE) - when it isn't in it
' Registers: a voice at +0 (+7, +14): frequency low, high, pulse width low, high, control (bit 0
' gate, 4 triangle, 5 saw, 6 pulse), attack / decay, sustain / release; 24 the mode and volume.
' The frequencies are for a 1 MHz SID clock (the CPC's 4 MHz / 4): the note's Hz * 16.777.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Const SID = &HFAC0
Dim a As String Max 20, r As Integer, v As Integer, t As Integer

a = UCase$(Trim$(CybSys.Tail()))
r = CybSys.Claim("SID", 0)
If r <> 0 And r <> 255 Then Print "The SID is claimed by slot "; Trim$(Str$(r)); " (CLAIMS)" : End
If a = "ON" Then Out &HFBEE, 255 : Out &HFBEE, 4 : Print "Speak&SID: SID mode"
For v = 0 To 24 : Out SID + v, 0 : Next         ' all quiet
Out SID + 24, 15                                 ' volume 15
Note 0, 4389, "C"                                ' C4 261.6 Hz
Pause 120
Note 1, 5530, "E"                                ' E4 329.6 Hz
Pause 120
Note 2, 6577, "G"                                ' G4 392.0 Hz
Pause 300
For v = 0 To 2 : Out SID + v * 7 + 4, &H10 : Next  ' gates off: the release
Pause 150
Out SID + 24, 0
r = CybSys.Release("SID", 0)
Print "Done (heard nothing? a Speak&SID not in SID mode: SIDTEST ON)"
End

' voice n (0-2) playing frequency f (the SID's number), triangle wave
Sub Note(ByVal n As Integer, ByVal f As Integer, ByVal nm As String)
  Dim b As Integer
  b = SID + n * 7
  Out b, f And 255
  Out b + 1, ((f And &HFF00) \ 256) And 255
  Out b + 5, &H09                                ' attack 0, decay 9
  Out b + 6, &HA4                                ' sustain 10, release 4
  Out b + 4, &H11                                ' triangle, gate on
  Print "Voice "; Trim$(Str$(n + 1)); ": "; nm
End Sub

' w / 300 seconds
Sub Pause(ByVal w As Integer)
  t = CybSys.Clock()
  Do While CybSys.Clock() - t < w
  Loop
End Sub
