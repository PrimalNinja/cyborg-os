' MEM: the memory, in CyborgOS (build for cpm, with CybSys.cls): main RAM as a table, the map of
' the banks' 16K pages (32 a group, two groups a line), the totals
Option Explicit
Dim j As Integer, te As Integer, tp As Integer, pg As Integer, a As String Max 60, host As Integer
If CybSys.Ask(7, 0) = 255 Then Print "MEM: not in this CyborgOS" : End
host = CybSys.ByteAt(1)                          ' 0 the CPC, 1 the ZX Spectrum Next
te = CybSys.WordAt(2) : tp = CybSys.WordAt(4) : pg = CybSys.WordAt(6)
a = CybSys.TextAt(8)
If host = 1 Then
  Print "#0000-#003F  restarts, the interrupt (#0038), the bank switch (#0044)"
  Print "#0040-#3FFF  CyborgOS"
  Print "#4000-#7FFF  the window (the banks' 16K pages: MMU slots 2, 3); main RAM's own: kept"
  Print "#8000-#"; H4(te - 1); "  CyborgOS, its arrays, the memory tables"
  Print "#"; H4(te); "-#"; H4(tp - 1); "  free"
  Print "#"; H4(tp); "-#BFFF  the stack"
  Print "#C000-#DFFF  MMU slot 6: the boot archive A: read through it; Layer 2 drawn"
  Print "#E000-#FFFF  the text screen (tilemap #E000-#E9FF, tiles #EC00-#F3FF), the boot stub"
  Print
  Print "Banks (B slot, U the hypervisor's: disc buffers, RAM discs; - free) - the 16K banks"
  Print "above the NEX's own, Layer 2 and the boot archive:"
Else
  Print "#0000-#003F  firmware restarts"
  Print "#0040-#3FFF  CyborgOS"
  Print "#4000-#7FFF  the window (the banks' pages); main RAM's own: kept, a 2nd screen"
  Print "#8000-#"; H4(te - 1); "  CyborgOS, its arrays, the memory tables"
  Print "#"; H4(te); "-#"; H4(tp - 1); "  free"
  Print "#"; H4(tp); "-#BFFF  firmware and ROMs"
  Print "#C000-#FFFF  screen"
  Print
  Print "Banks (B slot, U the hypervisor's: disc buffers, RAM discs; - free):"
End If
For j = 2 To pg Step 64
  Print Map(j); "  "; Map(j + 32)
Next
Print
Print a

' 32 pages of the map from page p
Function Map(ByVal p As Integer) As String
  Dim r As Integer
  CybSys.SetWord 2, p
  r = CybSys.Ask(8, 0)
  Map = CybSys.TextAt(4)
End Function

' v as 4 hex digits
Function H4(ByVal v As Integer) As String
  H4 = Right$("000" + Hex$(v), 4)
End Function
