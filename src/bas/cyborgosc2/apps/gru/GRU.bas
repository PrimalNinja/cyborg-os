' GRU: the terminal for a generative model served on a port (CyborgOS) - it talks to a MIND (the
' model server) a character at a time. You type; the model carries on from what you typed; its
' hidden state - the whole conversation so far - is kept on the server, so typing more carries on
' from where it left off. Named for the gated recurrent unit it drives (and, plausibly, the one
' from the films). Not a chatbot: a completer that has read only NTC's and CyborgOS's own sources.
'   GRU model [n] [noise]      talk to the MIND on port <model>; n characters a turn (200),
'                              noise 0-20 (2: a little variety; 0: the same answer every time)
' At the "you> " prompt:
'   a line of text   it is fed, then the model carries on from it (and the newline after it)
'   (empty)          it just carries on
'   /r [text]        the model reset (a new conversation), then fed text if any
'   /s n             the noise reseeded to n (a different wander, same noise level)
'   /n amp           the noise level changed to amp (0-20)
'   Q (or /q)        quit (the MIND keeps serving - KILL its slot, or Q there, to end it)
' A key pressed while it writes stops that turn. Start the server first: RUN 2 MIND model.
' (c) 2026 Cyborg Unicorn Pty Ltd
Option Explicit
Dim port As String Max 8, a As String Max 120, w As String Max 40, ln As String Max 128
Dim cnt As Integer, amp As Integer, i As Integer, code As Integer, k As Integer
Dim rp As String Max 128, info As String Max 128, cmd As String Max 4

a = Trim$(CybSys.Tail())
If a = "" Then Print "GRU model [n] [noise]: talk to the MIND serving <model> (RUN 2 MIND model)" : End
port = UCase$(Word(a, 0))
cnt = 200 : amp = 2
w = Word(a, 1) : If w <> "" Then cnt = Val(w)
w = Word(a, 2) : If w <> "" Then amp = Val(w)
If cnt < 1 Then cnt = 1
If amp < 0 Then amp = 0
If amp > 20 Then amp = 20

info = CybSys.PortCall(port, "?")
If CybSys.PortStatus() <> 0 Then Print "GRU: no MIND on port "; port; " (RUN 2 MIND "; port; ")" : End
Print "GRU: "; port; " ("; Trim$(info); ": vocab hidden layers). Type and it carries on. Q quits."
rp = CybSys.PortCall(port, "R")
Do
  ln = ""
  Input "you> ", ln
  ln = Trim$(ln)
  cmd = UCase$(Left$(ln, 2))
  If UCase$(ln) = "Q" Or cmd = "/Q" Then Exit Do
  If cmd = "/R" Then
    rp = CybSys.PortCall(port, "R") : ln = Trim$(Mid$(ln, 3))
  ElseIf cmd = "/S" Then
    rp = CybSys.PortCall(port, "S " + Trim$(Mid$(ln, 3))) : ln = ""
  ElseIf cmd = "/N" Then
    amp = Val(Trim$(Mid$(ln, 3)))
    If amp < 0 Then amp = 0
    If amp > 20 Then amp = 20
    ln = ""
  End If
  code = -1
  For i = 1 To Len(ln)                            ' feed what you typed (no noise - it is yours)
    rp = CybSys.PortCall(port, "F " + Trim$(Str$(Asc(Mid$(ln, i, 1)))))
    If CybSys.PortStatus() <> 0 Then Print : Print "GRU: lost "; port : Exit Do
    code = Val(rp)
  Next
  If ln <> "" Then
    rp = CybSys.PortCall(port, "F 10")            ' the newline after it
    If CybSys.PortStatus() = 0 Then code = Val(rp)
    Print
  End If
  If code >= 0 Then                               ' carry on: its choice printed, then fed back
    For k = 1 To cnt
      If code = 12 Then Exit For                  ' (a form feed: the end of a program)
      If code = 10 Then Print Else Print Chr$(code);
      rp = CybSys.PortCall(port, "G " + Trim$(Str$(code)) + " " + Trim$(Str$(amp)))
      If CybSys.PortStatus() <> 0 Then Print : Print "GRU: lost "; port : Exit Do
      code = Val(rp)
      If Inkey <> 0 Then Exit For
    Next
    Print
  End If
Loop
Print "GRU: done"
End

' word n (0 on) of s ("" none)
Function Word(ByVal s As String, ByVal n As Integer) As String
  Dim k As Integer
  s = Trim$(s)
  Do While n > 0 And s <> ""
    k = InStr(s, " ")
    If k = 0 Then s = "" Else s = Trim$(Mid$(s, k + 1))
    n = n - 1
  Loop
  k = InStr(s, " ")
  If k > 0 Then s = Left$(s, k - 1)
  Word = s
End Function
