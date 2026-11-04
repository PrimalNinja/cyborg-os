' MIND: a generative model served on a port (CyborgOS) - it holds the weights (a GEN.MDL: the
' ternary GRU from NTC's tools/gen) and runs the net; GRU, the client, talks to it. The port is
' the model's name, so "GRU GEN" talks to the MIND serving GEN.MDL. The state - the hidden state,
' the whole conversation so far - lives here, not in the client, so the client stays a thin
' terminal and the model can be kept, moved or shared while clients come and go. Run it in a slot
' of its own: RUN 2 MIND GEN. Q (at its slot) ends it.
'   RUN 2 MIND [v:]file        file[.MDL] loaded (from v: or this drive), the port named after it
'                              (GEN.MDL -> port GEN; a name is 8 characters at most)
' The port's messages (ASCII codes throughout - the client never sees the model's own classes):
'   ?            "vocab hidden layers" - the model's shape
'   R            the state cleared (a new text); "ok"
'   S n          the noise seed set to n; "ok"
'   F c          character code c fed, no noise; the code of the character it expects next
'   G c amp      the same with +/- amp of noise on the choice (amp 0-20); the next code
' A code the model doesn't know is fed as class 0. Code 10 is a newline, 12 the end of a program.
' Many clients may share one MIND (each should R first - the state is shared, so one at a time).
' (c) 2026 Cyborg Unicorn Pty Ltd
Option Explicit
Dim mdl(31999) As Byte
Dim f As String Max 40, v As String Max 4, port As String Max 8
Dim n As Integer, r As Integer, ch As Integer, nq As Integer, k As Integer
Dim msg As String Max 128, rp As String Max 128

f = UCase$(Trim$(CybSys.Tail()))
If f = "" Then Print "MIND [v:]file[.MDL]: a generative model served on a port named after it" : End
k = InStr(f, " ")
If k > 0 Then f = Left$(f, k - 1)                 ' (one word: the file)
v = ""
If Mid$(f, 2, 1) = ":" Then v = Left$(f, 2) : f = Mid$(f, 3)
port = f                                          ' the port: the name without a volume or extension
k = InStr(port, ".")
If k > 0 Then port = Left$(port, k - 1)
port = Left$(port, 8)
If InStr(f, ".") = 0 Then f = f + ".MDL"
n = FileSystem.Load(v + f, VarPtr(mdl(0)), 32000)
If n <= 0 Then Print "MIND: no "; v; f : End
If Net.Load(VarPtr(mdl(0)), n) = 0 Then Print "MIND: "; v; f; " isn't a model this serves" : End
Net.Reset
Net.Seed 12345

r = CybSys.PortOpen(port)
If r <> 0 Then Print "MIND: the port "; port; " is taken (a MIND for it already?)" : End
Print "MIND: "; port; " served ("; Net.Vocab(); " classes,"; Net.Hidden(); " hidden,"; Net.Layers(); " layers) - Q ends it"
Do
  r = CybSys.PortGet(port)
  If r = 0 Then
    msg = CybSys.PortMessage()
    rp = Serve(msg)
    r = CybSys.PortReply(port, rp)
    nq = nq + 1
  Else
    ch = Inkey
    If ch = 81 Or ch = 113 Then Exit Do
  End If
Loop
r = CybSys.PortClose(port)
Print "MIND: "; port; " closed,"; nq; " messages"
End

' one message, its reply (see the header)
Function Serve(ByVal m As String) As String
  Dim c As String Max 8, a As String Max 120, j As Integer, code As Integer, amp As Integer, pr As Integer
  Dim s As String Max 4
  Serve = "?"
  m = Trim$(m)
  If m = "" Then Exit Function
  j = InStr(m, " ")
  If j = 0 Then c = UCase$(m) : a = "" Else c = UCase$(Left$(m, j - 1)) : a = Trim$(Mid$(m, j + 1))
  If c = "?" Then
    Serve = Trim$(Str$(Net.Vocab())) + " " + Trim$(Str$(Net.Hidden())) + " " + Trim$(Str$(Net.Layers()))
  ElseIf c = "R" Then
    Net.Reset : Serve = "ok"
  ElseIf c = "S" Then
    Net.Seed Val(a) : Serve = "ok"
  ElseIf c = "F" Then
    code = Val(a)
    pr = Net.Feed(Net.Index(Chr$(code)))
    Serve = CodeOf(pr)
  ElseIf c = "G" Then
    j = InStr(a, " ")
    If j = 0 Then code = Val(a) : amp = 0 Else code = Val(Left$(a, j - 1)) : amp = Val(Mid$(a, j + 1))
    If amp < 0 Then amp = 0
    If amp > 20 Then amp = 20
    pr = Net.FeedNoise(Net.Index(Chr$(code)), amp)
    Serve = CodeOf(pr)
  End If
End Function

' the ASCII code (as text) of class i's character; "0" if the class has none
Function CodeOf(ByVal i As Integer) As String
  Dim s As String Max 2
  s = Net.Char(i)
  If Len(s) = 0 Then CodeOf = "0" Else CodeOf = Trim$(Str$(Asc(s)))
End Function
