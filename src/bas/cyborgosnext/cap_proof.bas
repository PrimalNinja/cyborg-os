' CyborgOS-Next: bank capacity + isolation proof, using Banks.cls.
Option Explicit
Option Reserve &H4000, &H4000
Dim nb As Integer, ns As Integer, s As Integer, w As Integer, bad As Integer, v As Integer, b As Integer

Mode 2
Ints 0
nb = Banks.Probe(120)                       ' probe up to 120 16K banks (1920K of banking)
ns = Banks.Slots()
Print "CyborgOS-Next banking capacity"
Print
Print "usable 16K banks: "; nb
Print "64K slots       : "; ns
' isolation across the first few slots: write slot*16+piece into each 16K bank, read back
bad = 0
For s = 0 To ns - 1
  For w = 0 To 3
    Banks.MapWin Banks.SlotBank(s, w) : Poke &H4000, s * 4 + w
  Next
Next
For s = 0 To ns - 1
  For w = 0 To 3
    Banks.MapWin Banks.SlotBank(s, w)
    If Peek(&H4000) <> s * 4 + w Then bad = bad + 1
  Next
Next
Print "all "; ns * 4; " banks across "; ns; " slots: "; (ns * 4 - bad); " isolated"
If bad = 0 And ns > 0 Then Print "CAPACITY OK" Else Print "CAPACITY FAIL"
Banks.MapWin 18
Ints 1
End

Sub Ints(ByVal on As Integer)
#asm
            ld a, ({on})
            or a
            jr z, io_off
            ei
            jr io_done
io_off:
            di
io_done:
#endasm
End Sub
