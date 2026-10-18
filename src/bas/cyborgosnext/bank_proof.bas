' CyborgOS-Next: MMU banking foundation proof. On the ZX Spectrum Next each 8K MMU slot (NextReg
' #50-#57) maps an 8K RAM page. The CPC's 16K window at #4000-#7FFF is MMU slots 2 AND 3 (NextReg
' #52 AND #53) - so a 16K bank is TWO 8K blocks, enabled together. A CyborgOS 64K slot = 4 such
' banks = 8 pages. This proves both 8K halves of a bank are there and that a slot's pages are
' isolated through the window - the base every slot stands on. Uses Banks.cls (its MapWin maps
' both window slots).
Option Explicit
Option Reserve &H4000, &H4000          ' keep the window (#4000-#7FFF = MMU slots 2, 3) free
Const W0 = &H4000                      ' the window's first 8K  (slot 2, NextReg #52)
Const W1 = &H6000                      ' the window's second 8K (slot 3, NextReg #53)
Dim i As Integer, bad As Integer

Mode 2
Ints 0
Print "CyborgOS-Next MMU banking proof"
Print

' a 16K bank is two 8K blocks, both enabled by one MapWin; write and read back both halves
Banks.MapWin 22 : Poke W0, 65 : Poke W1, 97      ' bank 22: 'A' low 8K, 'a' high 8K
Banks.MapWin 23 : Poke W0, 66 : Poke W1, 98      ' bank 23: 'B' low 8K, 'b' high 8K
Banks.MapWin 22
Print "bank 22 (both 8K): "; Chr$(Peek(W0)); Chr$(Peek(W1)); "  (want Aa)"
Banks.MapWin 23
Print "bank 23 (both 8K): "; Chr$(Peek(W0)); Chr$(Peek(W1)); "  (want Bb)"

' a 64K slot = 4 banks = 8 x 8K pages; a distinct byte in each half of each, all isolated
bad = 0
For i = 0 To 3
  Banks.MapWin Banks.SlotBank(0, i) : Poke W0, 48 + i * 2 : Poke W1, 49 + i * 2
Next
For i = 0 To 3
  Banks.MapWin Banks.SlotBank(0, i)
  If Peek(W0) <> 48 + i * 2 Then bad = bad + 1
  If Peek(W1) <> 49 + i * 2 Then bad = bad + 1
Next
Print
Print "64K slot = 4 banks x 2 x 8K = 8 pages: "; 8 - bad; " of 8 isolated"
If bad = 0 Then Print "BANKING OK" Else Print "BANKING FAIL"

Banks.MapWin 9                         ' the program's own pages (bank 9) back in the window
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
