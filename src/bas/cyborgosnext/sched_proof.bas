' CyborgOS-Next: round-robin proof. The hypervisor loop maps each task's bank in turn; each task's
' state lives in its own 64K slot, so it advances independently across turns - the scheduler model
' on the Next MMU. (The real register/SP context switch is asm, staged; this proves the banked
' per-task state + the round-robin loop.)
Option Explicit
Option Reserve &H4000, &H4000
Const NT = 3
Dim turn As Integer, t As Integer, c As Integer

Mode 2
Ints 0
Banks.Probe 120
For t = 0 To NT - 1                      ' each task's counter starts at 0, in its own slot
  Banks.MapWin Banks.SlotBank(t, 0) : Poke &H4000, 0
Next
Print "CyborgOS-Next round-robin: "; NT; " tasks, each in its own bank"
Print
For turn = 1 To 4                        ' four scheduler passes
  For t = 0 To NT - 1
    Banks.MapWin Banks.SlotBank(t, 0)    ' bring task t's bank in
    c = Peek(&H4000) + (t + 1)           ' task t advances by t+1 (distinct rates)
    Poke &H4000, c
  Next
Next
For t = 0 To NT - 1
  Banks.MapWin Banks.SlotBank(t, 0)
  Print "task "; t; " counter = "; Peek(&H4000); "  (want "; (t + 1) * 4; ")"
Next
Banks.MapWin 18
Ints 1
End

Sub Ints(ByVal on As Integer)
#asm
            ld a, ({on})
            or a
            jr z, is_off
            ei
            jr is_done
is_off:
            di
is_done:
#endasm
End Sub
