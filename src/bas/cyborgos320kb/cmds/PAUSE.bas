' PAUSE / UNPAUSE: a slot's program stopped where it is - the scheduler passes it over, everything
' it had kept is kept (its screen, its files, its claims and ports, a key typed meanwhile) - and
' going on again from there. One source, two commands: what it does is its own name (PAUSE.CYB,
' UNPAUSE.CYB - the name the kernel put in its bank). Build for cyborgos with CybSys.cls.
'   PAUSE slot        that slot's program paused
'   UNPAUSE slot      going on again
'   PAUSE / UNPAUSE   the slots paused now
Option Explicit
Dim a As String Max 20, nm As String Max 12, s As Integer, r As Integer, n As Integer, i As Integer
nm = ""
For i = 1 To Peek(&HF6D8)                        ' (this program's name, in its bank)
  If i > 12 Then Exit For
  nm = nm + Chr$(Peek(&HF6D8 + i))
Next
a = Trim$(System.CommandLine())
If a = "" Then
  n = 0
  s = 1
  Do
    r = CybSys.State(s)
    If r = 255 Then Exit Do
    If r = 3 Then
      If CybSys.Ask(0, s) = 0 Then Print "slot "; Num(s); " paused: "; CybSys.TextAt(4)
      n = n + 1
    End If
    s = s + 1
  Loop
  If s = 1 Then Print "PAUSE needs CyborgOS" : End
  If n = 0 Then Print "No slot is paused"
  End
End If
s = Val(a)
If Left$(nm, 7) = "UNPAUSE" Then
  r = CybSys.Pause(s, 0)
  If r = 0 Then
    Print "slot "; Num(s); " goes on"
  ElseIf r = 1 Then
    Print "slot "; Num(s); " is not paused"
  Else
    Print "no slot "; a
  End If
Else
  r = CybSys.Pause(s, -1)
  If r = 0 Then
    Print "slot "; Num(s); " paused (UNPAUSE "; Num(s); " to go on)"
  ElseIf r = 1 Then
    If CybSys.State(s) = 3 Then
      Print "slot "; Num(s); " is paused already"
    Else
      Print "slot "; Num(s); " runs no program (or is this one)"
    End If
  Else
    Print "no slot "; a
  End If
End If

Function Num(ByVal v As Integer) As String Max 6
  Num = Trim$(Str$(v))
End Function
