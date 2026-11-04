' GREP: the lines of text files that hold a text, in CyborgOS (build for cpm, with CybDir.cls).
'   GREP text [v:]name [/N] [/C] [/V]
'   GREP text [v:]pattern ...          * any characters, ? any one (*.BAS, T*): each file that fits
'                                      (a pattern needs a drive that lists: UniDOS's, a RAM disc)
' text: the line holds it anywhere - capitals or small, the same (CP/M makes the command line
' capitals). "two words" in quotes for spaces. In it * any characters, ? any one; ^ at its start:
' the line starts with it, $ at its end: the line ends with it.
' /N the line numbers, /C only how many lines each file has, /V the lines that don't hold it.
' More than one file: each line has its file's name in front. A page at a time (-- more --, as
' TYPE: space a page, Enter a line, Q / ESC / Control + C the end); a line is cut at the console's
' width, control characters shown as "."; the text ends at a file's end or its first ^Z.
' (c) 2026 Cyborg Unicorn Pty Ltd
Option Explicit
Dim a As String Max 72, pt As String Max 40, w As String Max 40, v As String Max 2, f As String Max 40
Dim ln As String Max 255, u As String Max 255, sn As String Max 12
Dim h As Integer, r As Integer, cw As Integer, pr As Integer, nl As Integer, hsp As Integer, pb(3) As Byte
Dim i As Integer, k As Integer, nf As Integer, many As Integer, wild As Integer, fl As Integer
Dim swn As Integer, swc As Integer, swv As Integer, tl As Integer, tf As Integer

a = UCase$(Trim$(System.CommandLine()))
If Len(a) = 72 And Peek(&H80) > 73 Then Print "GREP: the line is too long (72 characters at most)" : End
' the switches, wherever they are
swn = Sw("/N") : swc = Sw("/C") : swv = Sw("/V")
a = Trim$(a)
' the text: "in quotes" or the first word
If Left$(a, 1) = Chr$(34) Then
  k = InStr(Mid$(a, 2), Chr$(34))
  If k = 0 Then Print "GREP: no closing quote" : End
  pt = Mid$(a, 2, k - 1) : a = Trim$(Mid$(a, k + 2))
Else
  k = InStr(a + " ", " ")
  pt = Left$(a, k - 1) : a = Trim$(Mid$(a, k + 1))
End If
If pt = "" Or a = "" Or InStr(a, " ") > 0 Then
  Print "GREP text [v:]name [/N] [/C] [/V]   (HELP GREP)" : End
End If
' the text as a pattern: plain (InStr - quick), or with * ? ^ $ (CybDir.Fits on the whole line)
wild = (InStr(pt, "*") > 0) Or (InStr(pt, "?") > 0) Or (Left$(pt, 1) = "^") Or (Right$(pt, 1) = "$")
If wild Then
  If Left$(pt, 1) = "^" Then pt = Mid$(pt, 2) Else pt = "*" + pt
  If Right$(pt, 1) = "$" Then pt = Left$(pt, Len(pt) - 1) Else pt = pt + "*"
  If pt = "" Then pt = "*"
End If
' the file(s)
If Mid$(a, 2, 1) = ":" Then
  v = Left$(a, 2) : f = Mid$(a, 3)
Else
  v = FileSystem.CurrentVolume() + ":" : f = a
End If
If InStr(f, "*") = 0 And InStr(f, "?") = 0 Then  ' one file
  many = False
  If FileSystem.Exists(v + f) = 0 Then Print v; f; ": not found" : End
  One f
Else
  many = True
  If CybDir.LoadAll(v) = False Then Print v; " its files can't be listed (UniDOS's drives and RAM discs can)" : End
  For i = 0 To CybDir.Count() - 1
    If CybDir.Match(i, f) Then One CybDir.DiscName(i)
  Next
  If nf = 0 Then Print v; f; ": no file fits" : End
End If
If swc = 0 And tl = 0 Then Out1 "no line holds " + Chr$(34) + Show(pt) + Chr$(34)
If many And swc = 0 And tl > 0 Then Out1 Trim$(Str$(tl)) + " lines in " + Trim$(Str$(tf)) + " of " + Trim$(Str$(nf)) + " files"
End

' file s read: its lines that hold the text (or don't: /V) shown, or counted (/C)
Sub One(ByVal s As String)
  Dim n As Integer, c As Integer, ok As Integer
  nf = nf + 1
  h = FileSystem.Open(v + s, FileSystem.ForRead)
  If h < 0 Then Out1 v + s + ": can't be read" : Exit Sub
  n = 0 : c = 0
  Do While Not FileSystem.Eof(h)
    ln = FileSystem.ReadLine(h) : n = n + 1
    u = UCase$(ln)
    If wild Then ok = CybDir.Fits(u, pt) Else ok = (InStr(u, pt) > 0)
    If wild And u = "" Then ok = (pt = "*")      ' (Fits never fits "": an empty line fits "*", ^$)
    If swv Then ok = Not ok
    If ok Then
      c = c + 1
      If swc = 0 Then
        u = ""
        If many Then u = s + ":"
        If swn Then u = u + Trim$(Str$(n)) + ":"
        If u <> "" Then u = u + " "
        Out1 Clip(u + ln)
      End If
    End If
  Loop
  r = FileSystem.Close(h)
  If c > 0 Then tf = tf + 1
  tl = tl + c
  If swc Then
    If many Then Out1 s + ": " + Trim$(Str$(c)) Else Out1 Trim$(Str$(c))
  End If
End Sub

' True when switch t is in a's words - taken out of a
Function Sw(ByVal t As String) As Integer
  Dim j As Integer
  Sw = False
  j = InStr(" " + a + " ", " " + t + " ")
  If j = 0 Then Exit Function
  a = Left$(a, j - 1) + Mid$(a, j + Len(t))
  Sw = True
End Function

' the pattern as typed back (the * added at its ends left off)
Function Show(ByVal t As String) As String
  If wild Then
    If Left$(t, 1) = "*" Then t = Mid$(t, 2) Else t = "^" + t
    If Right$(t, 1) = "*" Then t = Left$(t, Len(t) - 1) Else t = t + "$"
  End If
  Show = t
End Function

' t cut to the console's width, control characters (and 127) as "."
Function Clip(ByVal t As String) As String
  Dim j As Integer, c As Integer
  If cw = 0 Then
    pb(0) = &H1A : cw = Bdos(49, VarPtr(pb))      ' (CP/M 3's #1A: the width - 1)
    If cw < 12 Or cw > 200 Then cw = 79
  End If
  Dim o As String Max 255
  If Len(t) > cw Then t = Left$(t, cw)
  o = ""
  For j = 1 To Len(t)
    c = Asc(Mid$(t, j, 1))
    If c < 32 Or c = 127 Then o = o + "." Else o = o + Chr$(c)
  Next
  Clip = o
End Function

' a line out, a page at a time: when the console is full, "-- more --" waits for a key (space: a
' page more, Enter: a line, Q / ESC / Control + C: the end) - TYPE's
Sub Out1(ByVal t As String)
  Dim k As Integer
  If pr = 0 Then
    pb(0) = &H1C : pr = Bdos(49, VarPtr(pb))     ' (CP/M 3's #1C: the page length)
    If pr < 4 Or pr > 100 Then pr = 24
  End If
  If nl >= pr - 1 Then
    Print "-- more (space, Enter, Q) --";
    Do
      k = Bdos(6, &HFF)
    Loop While k = 0
    Print String$(28, 8); Space$(28); String$(28, 8);   ' (the prompt rubbed out: BS, spaces, BS)
    If k = 81 Or k = 113 Or k = 27 Or k = 3 Then End
    If k = 13 Then nl = pr - 2 Else nl = 0
  End If
  Print t
  nl = nl + 1
End Sub

' BDOS function fn, DE = dd: A
Function Bdos(ByVal fn As Integer, ByVal dd As Integer) As Integer
#asm
            ld ({hsp}), sp
            ld sp, (ntc_csp)
            ld a, ({fn})
            ld c, a
            ld de, ({dd})
            ei                      ; (CP/M's BDOS: interrupts on)
            call 5
            di                      ; (off before SP is the threaded code again: it comes back with them on)
            ld l, a
            ld h, 0
            ld ({result}), hl
            ld sp, ({hsp})
#endasm
End Function
