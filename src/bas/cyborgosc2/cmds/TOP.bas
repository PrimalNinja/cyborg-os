' TOP: the TOP table (each open slot's state, program, and its turns, BDOS calls and characters in
' the last whole second), then the totals, printed once into this slot; TOP FULL: every slot, the
' ones not open too (as the live TOP, Control + ESC, shows them - you pick one there). In CyborgOS
' (build for cpm, with CybSys.cls)
Option Explicit
Dim r As Integer
If UCase$(Trim$(System.CommandLine())) = "FULL" Then CybSys.SetWord 2, 1
r = CybSys.Ask(6, 0)
