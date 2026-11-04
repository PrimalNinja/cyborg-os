' FG: a slot to the front, in CyborgOS (build for cpm, with CybSys.cls)
'   FG slot
Option Explicit
Dim a As String Max 20, r As Integer
a = Trim$(System.CommandLine())
If Val(a) < 1 Then Print "FG slot   (a slot to the front: PS lists them)" : End
r = CybSys.Ask(3, Val(a))
If r <> 0 Then Print "no slot "; a
