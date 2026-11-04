' HTTPTEST url: Http.cls's calls tried (build for the cyborgos platform with ../Http.cls and
' ../CybSys.cls): Get, Post (a small form), then Start - the first piece - More once, and Finish
' before the rest is read. url: a page that answers with what it was sent (test/echo.php).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Const BUF = &H8000
Dim u As String Max 200, n As Integer, k As Integer, f As String Max 40, i As Integer

u = Trim$(CybSys.Tail())                   ' (as typed: an address's small letters kept)
If u = "" Or u = "?" Then Print "HTTPTEST url" : End
Show "GET", Http.Get(u + "?q=get", BUF, 2000)
f = "name=Rex&food=10"
Poke BUF + 4000, 0
For i = 1 To Len(f)
  Poke BUF + 3999 + i, Asc(Mid$(f, i, 1))
Next
Show "POST", Http.Post(u + "?q=post", BUF + 4000, Len(f), BUF, 2000)
n = Http.Start(u + "?q=big", BUF, 1000)
Print "START:"; n; " length"; Http.Length(); " code"; Http.Code(); " "; Http.Message()
k = Http.More(BUF + n, 64)
Print "MORE:"; k
Http.Finish
Print "FINISH: the rest left"
Print "done"
End

Sub Show(ByVal w As String, ByVal r As Integer)
  Dim j As Integer, c As Integer, t As String Max 120
  Print w; ":"; r; " code"; Http.Code(); " "; Http.Message()
  t = ""
  For j = 0 To r - 1
    c = Peek(BUF + j)
    If c >= 32 And c < 127 And Len(t) < 110 Then t = t + Chr$(c)
  Next
  Print "  "; t
End Sub
