' CyborgOS-Next: slot allocator + cross-bank copy proof.
Option Explicit
Option Reserve &H4000, &H4000
Dim a As Integer, b As Integer, cc As Integer, i As Integer, bad As Integer

Mode 2
Ints 0
Banks.Probe 120
Banks.Init
Print "CyborgOS-Next allocator + cross-bank copy"
Print
a = Banks.Alloc() : b = Banks.Alloc() : cc = Banks.Alloc()
Print "allocated slots: "; a; " "; b; " "; cc
Banks.Free b
Print "freed "; b; ", next alloc = "; Banks.Alloc(); " (should reuse "; b; ")"
' write a pattern into slot a, copy it to slot cc, verify
Banks.MapWin Banks.SlotBank(a, 0)
For i = 0 To 19
  Poke &H4000 + i, 100 + i
Next
Banks.Copy a, 0, cc, 0, 20
bad = 0
Banks.MapWin Banks.SlotBank(cc, 0)
For i = 0 To 19
  If Peek(&H4000 + i) <> 100 + i Then bad = bad + 1
Next
Print "cross-bank copy of 20 bytes: "; 20 - bad; " of 20 correct"
If bad = 0 Then Print "ALLOC+COPY OK" Else Print "ALLOC+COPY FAIL"
Banks.MapWin 18
Ints 1
End

Sub Ints(ByVal on As Integer)
#asm
            ld a, ({on})
            or a
            jr z, ip_off
            ei
            jr ip_done
ip_off:
            di
ip_done:
#endasm
End Sub
