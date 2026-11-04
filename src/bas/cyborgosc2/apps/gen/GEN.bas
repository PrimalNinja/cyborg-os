' GEN: a small generative model on the CPC - a ternary GRU (NTC's Net class) trained on NTC BASIC
' and Z80 assembly (NTC tools/gen), writing on from what it is given, a character at a time.
'   GEN [v:]file [n] [noise]      the file's text read in as the start, then n characters (200)
'                                 written after it; noise 0-20 (0): the model's choice jogged
'   GEN                           no file: a program's first lines as the start
' The model is GEN.MDL on this slot's drive or on A. A key ends it early. About a second a
' character on a 4 MHz CPC; the vCPC on a Pi does it a hundred times faster. Not a chatbot: a
' completer that has read only CyborgOS's and NTC's own sources.
' (c) 2026 Cyborg Unicorn Pty Ltd
Option Explicit
Dim mdl(31999) As Byte
Dim a As String Max 72, w As String Max 40, v As String Max 2, f As String Max 40, ln As String Max 120
Dim n As Integer, i As Integer, k As Integer, c As Integer, h As Integer, r As Integer, cnt As Integer, amp As Integer
Dim fed As Integer

a = Trim$(System.CommandLine())
cnt = 200 : amp = 0
' the words: [v:]file [n] [noise]
w = Word(a) : a = Rest(a)
If w <> "" Then
  f = w
  w = Word(a) : a = Rest(a)
  If w <> "" Then cnt = Val(w)
  w = Word(a)
  If w <> "" Then amp = Val(w)
End If
If cnt < 1 Then cnt = 1
If amp < 0 Then amp = 0
If amp > 20 Then amp = 20
n = FileSystem.Load("GEN.MDL", VarPtr(mdl(0)), 32000)
If n <= 0 Then n = FileSystem.Load("A:GEN.MDL", VarPtr(mdl(0)), 32000)
If n <= 0 Then Print "GEN: no GEN.MDL on this drive or A" : End
If Net.Load(VarPtr(mdl(0)), n) = 0 Then Print "GEN: GEN.MDL isn't a model this GEN reads" : End
Net.Reset
Net.Seed 12345 + cnt * 7
fed = 0
If f <> "" Then
  If Mid$(f, 2, 1) = ":" Then
    v = UCase$(Left$(f, 2)) : f = Mid$(f, 3)
  Else
    v = FileSystem.CurrentVolume() + ":"
  End If
  h = FileSystem.Open(v + UCase$(f), FileSystem.ForRead)
  If h < 0 Then Print v; UCase$(f); ": not found" : End
  Do While Not FileSystem.Eof(h)
    ln = FileSystem.ReadLine(h)
    Print ln
    For i = 1 To Len(ln)
      c = Net.FeedNoise(Net.Index(Mid$(ln, i, 1)), amp)
    Next
    c = Net.FeedNoise(Net.Index(Chr$(10)), amp)
    fed = fed + Len(ln) + 1
    If fed > 4000 Then Exit Do                    ' (the start: enough)
  Loop
  r = FileSystem.Close(h)
Else
  ln = "' a program" + Chr$(10) + "Option Explicit" + Chr$(10)
  Print "' a program"
  Print "Option Explicit"
  For i = 1 To Len(ln)
    c = Net.FeedNoise(Net.Index(Mid$(ln, i, 1)), amp)
  Next
End If
' the model writes on: its choice printed, then fed back
For i = 1 To cnt
  w = Net.Char(c)
  If w = Chr$(12) Then Exit For                   ' (a form feed: the end of a program)
  If w = Chr$(10) Then Print Else Print w;
  c = Net.FeedNoise(c, amp)
  k = Inkey
  If k <> 0 Then Exit For
Next
Print
End

' the first word of s, and s after it
Function Word(ByVal s As String) As String
  Dim j As Integer
  s = Trim$(s)
  j = InStr(s, " ")
  If j = 0 Then Word = s Else Word = Left$(s, j - 1)
End Function

Function Rest(ByVal s As String) As String
  Dim j As Integer
  s = Trim$(s)
  j = InStr(s, " ")
  If j = 0 Then Rest = "" Else Rest = Trim$(Mid$(s, j + 1))
End Function
