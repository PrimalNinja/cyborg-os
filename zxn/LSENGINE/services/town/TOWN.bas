' TOWN: the LITTLE SEOUL ENGINE's town service (CyborgOS) - the hundred people of LITTLE SEOUL living
' their days in their own 64K slot, so a game in another slot only draws them. Each person is a LUN
' of a RAT model (SUIT, KEEPER, STAR: models/*.MDL, each served by MODEL); when what they are doing
' ends, TOWN asks RAT "MODEL:lun work eat:<food> home:<energy> flee:<calm> <haunts>" - what they can
' do now - and sends them there: the nearest shop of the kind RAT picks, walking street by street.
' The game owns the clock: it sends the time, TOWN catches up.
'   RUN 2 LSMODEL SUIT : RUN 3 LSMODEL KEEPER : RUN 4 LSMODEL STAR : RUN 5 RAT : RUN 6 TOWN [n]
'   (n: the first n decisions shown, RAT's call and its answer)
' TOWN.DAT (tools/towndat.py, from LITTLE SEOUL's own city) holds the shops and the people.
' The port TOWN's messages (an answer each):
'   T day mins         the game's clock (a new day: everyone home) - "ok"
'   P                  how many are waiting for a decision (0: caught up)
'   W p                person p: "name state shop room food energy fear last-decision"
'   R room             who is in that street (0-191): "p p p ..." (walking there or in a shop there)
'   F room level rad   fright (aliens, a fire ...): level 1-100 at that street and the streets within
'                      rad of it - those people decide at once (flee) - "ok n" (n frightened)
'   S                  "home a work b eat c out d walk e flee f away g dec h"
'   Q                  ends TOWN ("end")
' The table (tb, 8 bytes a person: shop 2 (65535 away, 65534 walking), street room, state, food,
' energy, fear, -) is what a game reads every frame; in a shared bank once the hypervisor has one
' (docs/ENGINE.md), here in TOWN's own RAM.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit
Const NP = 100                                ' the people
Const NT = 40                                 ' the shop types
Const S_HOME = 0, S_WORK = 1, S_EAT = 2, S_OUT = 3, S_WALK = 4, S_FLEE = 5, S_AWAY = 6
Const DAWN = 420, NIGHT = 1320                ' decisions from 7:00 to 22:00
Dim db(8191) As Byte                          ' TOWN.DAT
Dim ts(40) As Integer, so As Integer, po As Integer, nb As Integer
Dim pState(99) As Byte, pDo(99) As Byte, pRoom(99) As Byte, pFrom(99) As Byte, pTo(99) As Byte
Dim pShop(99) As Integer, pDest(99) As Integer, pT0(99) As Integer, pT1(99) As Integer
Dim pNext(99) As Integer, pDur(99) As Integer
Dim pFood(99) As Byte, pEnergy(99) As Byte, pFear(99) As Byte
Dim pLast(99) As String Max 16
Dim alert(191) As Byte, tb(799) As Byte
Dim day As Integer, mins As Integer, started As Integer, cur As Integer, ndec As Integer, tell As Integer
Dim msg As String Max 128, rp As String Max 128, a As String Max 128
Dim r As Integer, ch As Integer, i As Integer, k As Integer, h As Integer

Randomize CybSys.Clock()
tell = Val(CybSys.Tail())                     ' (TOWN n: the first n decisions shown)
h = FileSystem.Open("TOWN.DAT", FileSystem.ForRead)
For i = 0 To 15                               ' (not on this slot's drive - a new slot's is the boot
  If h >= 0 Then Exit For                     ' drive: the first of A: to P: that has it, the folder
  r = CybSys.Bdos(14, i)                      ' TOWN was run from - and that drive this slot's)
  h = FileSystem.Open("TOWN.DAT", FileSystem.ForRead)
Next
If h < 0 Then Print "TOWN: no TOWN.DAT" : End
nb = FileSystem.Read(h, VarPtr(db), 8192)
r = FileSystem.Close(h)
If db(0) <> 76 Or db(1) <> 83 Or db(2) <> 84 Or db(3) <> 68 Then Print "TOWN: TOWN.DAT is not a town" : End
For i = 0 To NT
  ts(i) = db(8 + i * 2) + db(9 + i * 2) * 256
Next
so = 8 + (NT + 1) * 2                         ' the shops (3 bytes each, by type)
po = so + ts(NT) * 3                          ' the people (32 bytes each)
r = CybSys.PortOpen("TOWN")
If r <> 0 Then Print "The port TOWN is taken (TOWN is running already?)" : End
Print "TOWN: the hundred of LITTLE SEOUL, port TOWN (Q ends it)"
Traits
day = -1
Do
  r = CybSys.PortGet("TOWN")
  If r = 0 Then
    msg = CybSys.PortMessage()
    rp = Answer(msg)
    r = CybSys.PortReply("TOWN", rp)
    If rp = "end" Then Exit Do
  Else
    If started Then DecideNext
    ch = Inkey
    If ch = 81 Or ch = 113 Then Exit Do
  End If
Loop
r = CybSys.PortClose("TOWN")
Print "TOWN:"; ndec; " decisions"
End

' person p's byte at offset o of their record, and a word
Function PB(ByVal p As Integer, ByVal o As Integer) As Integer
  PB = db(po + p * 32 + o)
End Function

Function PW(ByVal p As Integer, ByVal o As Integer) As Integer
  PW = db(po + p * 32 + o) + db(po + p * 32 + o + 1) * 256
End Function

Function ModelOf(ByVal p As Integer) As String
  Dim k As Integer
  k = PB(p, 0)
  If k = 0 Then ModelOf = "SUIT"
  If k = 1 Then ModelOf = "KEEPER"
  If k = 2 Then ModelOf = "STAR"
End Function

Function NameOf(ByVal p As Integer) As String
  Dim j As Integer, s As String Max 10
  s = ""
  For j = 18 To 27
    If PB(p, j) > 32 Then s = s + Chr$(PB(p, j))
  Next
  NameOf = s
End Function

' each person their own: their LUN of the model tuned to their trait (two weights)
Sub Traits()
  Dim p As Integer, t As Integer, m As String Max 8, s As String Max 40
  Print "TOWN: waiting for the models (SUIT KEEPER STAR)";
  For p = 0 To 2
    If p = 0 Then m = "SUIT"
    If p = 1 Then m = "KEEPER"
    If p = 2 Then m = "STAR"
    Do
      s = CybSys.PortCall(m, "U")
      If CybSys.PortStatus() = 0 Then Exit Do
      ch = Inkey
      If ch = 81 Or ch = 113 Then End
    Loop
    Print " "; m;
  Next
  Print
  For p = 0 To NP - 1
    m = ModelOf(p) : t = PB(p, 2)
    s = "#" + Trim$(Str$(PB(p, 1))) + " V "
    If t = 0 Then Tune m, s + "R\work\85" : Tune m, s + "N\flee\25"          ' BORN LEADER
    If t = 1 Then Tune m, s + "L\karaoke\10" : Tune m, s + "N\flee\65"       ' SHY
    If t = 2 Then Tune m, s + "L\funfair\85" : Tune m, s + "L\karaoke\70"    ' PRANKSTER
    If t = 3 Then Tune m, s + "L\club\75" : Tune m, s + "L\bar\70"           ' CHARISMATIC
    If t = 4 Then Tune m, s + "L\park\85" : Tune m, s + "L\chapel\65"        ' 4D
    If t = 5 Then Tune m, s + "N\eat\50" : Tune m, s + "L\eat\75"            ' FOODIE
    If t = 6 Then Tune m, s + "L\cafe\80" : Tune m, s + "N\flee\60"          ' SOFTIE
    If t = 7 Then Tune m, s + "R\work\95" : Tune m, s + "N\home\10"          ' HARD WORKER
    If t = 8 Then Tune m, s + "L\karaoke\80" : Tune m, s + "L\concert\75"    ' CHEERFUL
    If t = 9 Then Tune m, s + "L\boutique\85" : Tune m, s + "L\mall\75"      ' CHIC
  Next
  Print "TOWN: the hundred tuned to their traits"
End Sub

Sub Tune(ByVal m As String, ByVal s As String)
  Dim t As String Max 8
  t = CybSys.PortCall(m, s)
  If t <> "ok" Then Print "TOWN: "; m; " "; s; " -> "; t
End Sub

' a message on the port: its answer
Function Answer(ByVal m As String) As String
  Dim c As String Max 1, j As Integer, p As Integer, n As Integer, v As Integer, rd As Integer
  Answer = "?"
  m = Trim$(m)
  c = UCase$(Left$(m, 1))
  m = Trim$(Mid$(m, 2))
  If c = "T" Then                             ' T day mins
    j = InStr(m, " ")
    If j = 0 Then Exit Function
    n = Val(Left$(m, j - 1)) : v = Val(Mid$(m, j + 1))
    If n <> day Then NewDay n, v
    Catch v
    started = 1
    Answer = "ok"
  ElseIf c = "P" Then
    Answer = Trim$(Str$(Due()))
  ElseIf c = "W" Then
    p = Val(m)
    If p < 0 Or p >= NP Then Exit Function
    Answer = NameOf(p) + " " + StateName(pState(p)) + " " + Trim$(Str$(pShop(p))) + " " + Trim$(Str$(RoomOf(p))) + " " + Trim$(Str$(pFood(p))) + " " + Trim$(Str$(pEnergy(p))) + " " + Trim$(Str$(pFear(p))) + " " + pLast(p)
  ElseIf c = "R" Then
    n = Val(m) : a = ""
    For p = 0 To NP - 1
      If pState(p) <> S_AWAY Then
        If RoomOf(p) = n And Len(a) < 120 Then a = a + Trim$(Str$(p)) + " "
      End If
    Next
    Answer = Trim$(a)
  ElseIf c = "F" Then                         ' F room level radius
    j = InStr(m, " ")
    If j = 0 Then Exit Function
    rd = Val(Left$(m, j - 1)) : m = Trim$(Mid$(m, j + 1))
    j = InStr(m, " ")
    If j = 0 Then v = Val(m) : n = 0 Else v = Val(Left$(m, j - 1)) : n = Val(Mid$(m, j + 1))
    Answer = "ok " + Trim$(Str$(Fright(rd, v, n)))
  ElseIf c = "S" Then
    Answer = Stats()
  ElseIf c = "Q" Then
    Answer = "end"
  End If
End Function

Function StateName(ByVal s As Integer) As String
  StateName = Mid$("HOME WORK EAT  OUT  WALK FLEE AWAY ", s * 5 + 1, 4)
  StateName = Trim$(StateName)
End Function

Function Stats() As String
  Dim n(6) As Integer, p As Integer, s As String Max 128
  For p = 0 To NP - 1
    n(pState(p)) = n(pState(p)) + 1
  Next
  s = ""
  For p = 0 To 6
    s = s + LCase$(StateName(p)) + Str$(n(p)) + " "
  Next
  Stats = s + "dec" + Str$(ndec)
End Function

' a new day: everyone at home, fed and rested; the away ones out of town on their away day
Sub NewDay(ByVal d As Integer, ByVal m As Integer)
  Dim p As Integer
  day = d
  For p = 0 To NP - 1
    pShop(p) = PW(p, 4) : pRoom(p) = PB(p, 6) : pState(p) = S_HOME
    pFood(p) = 50 + (p * 7) Mod 30 : pEnergy(p) = 90 : pFear(p) = 0 : pLast(p) = ""
    pNext(p) = DAWN + (p * 13) Mod 90
    If PB(p, 12) = 1 And (p + day) Mod 3 = 1 Then pState(p) = S_AWAY : pShop(p) = -1
    Publish p
  Next
  For p = 0 To 191
    alert(p) = 0
  Next
  mins = m
End Sub

' the clock to m: arrivals, and food, energy and fright as the minutes go (5 at a time)
Sub Catch(ByVal m As Integer)
  Dim p As Integer, t As Integer
  If m < mins Then mins = m : Exit Sub
  Do While mins < m
    t = 5 - mins Mod 5
    If mins + t > m Then mins = m : Exit Do
    mins = mins + t
    For p = 0 To 191
      If alert(p) > 0 Then
        If alert(p) > 2 Then alert(p) = alert(p) - 2 Else alert(p) = 0
      End If
    Next
    For p = 0 To NP - 1
      If pState(p) <> S_AWAY Then
        If pState(p) = S_WALK Or pState(p) = S_FLEE Then
          If mins >= pT1(p) Then Arrive p
        End If
        If pState(p) = S_EAT Then
          pFood(p) = Least(100, pFood(p) + 12)
        ElseIf pFood(p) > 0 Then
          pFood(p) = pFood(p) - 1
        End If
        If pState(p) = S_HOME Then
          pEnergy(p) = Least(100, pEnergy(p) + 3)
        ElseIf pEnergy(p) > 0 And mins Mod 15 = 0 Then
          pEnergy(p) = pEnergy(p) - 1
        End If
        k = alert(RoomOf(p))
        If k > pFear(p) Then pFear(p) = k : pNext(p) = mins
        If pFear(p) > 0 And k = 0 Then
          If pFear(p) > 3 Then pFear(p) = pFear(p) - 3 Else pFear(p) = 0
        End If
        Publish p
      End If
    Next
  Loop
End Sub

Function Least(ByVal a As Integer, ByVal b As Integer) As Integer
  If a < b Then Least = a Else Least = b
End Function

' how many are waiting for a decision
Function Due() As Integer
  Dim p As Integer, n As Integer
  If mins < DAWN Or mins >= NIGHT Then Exit Function
  For p = 0 To NP - 1
    If IsDue(p) Then n = n + 1
  Next
  Due = n
End Function

Function IsDue(ByVal p As Integer) As Integer
  IsDue = 0
  If pState(p) = S_AWAY Or pState(p) = S_WALK Or pState(p) = S_FLEE Then Exit Function
  If pNext(p) <= mins Then IsDue = -1
End Function

' the next one due (round the hundred): ask RAT for them
Sub DecideNext()
  Dim n As Integer
  If mins < DAWN Or mins >= NIGHT Then Exit Sub
  For n = 1 To NP
    cur = cur + 1
    If cur >= NP Then cur = 0
    If IsDue(cur) Then Decide cur : Exit Sub
  Next
End Sub

' what p can do now (their senses), RAT's pick, and off they go
Sub Decide(ByVal p As Integer)
  Dim s As String Max 128, t As Integer, j As Integer, hk As Integer, ws As Integer, we As Integer, v As String Max 40
  s = ModelOf(p) + ":" + Trim$(Str$(PB(p, 1)))
  If pFear(p) > 0 Then s = s + " flee:" + Trim$(Str$(100 - pFear(p)))
  ws = 540 + PB(p, 10) * 30 : we = 540 + PB(p, 11) * 30
  If PB(p, 9) <> 255 And (PB(p, 16) And Pow2((p + day) Mod 3)) <> 0 And mins >= ws And mins < we Then s = s + " work"
  If pFood(p) < 90 Then s = s + " eat:" + Trim$(Str$(pFood(p)))
  s = s + " home:" + Trim$(Str$(pEnergy(p)))
  For j = 13 To 15
    hk = PB(p, j)
    If hk < 14 Then s = s + " " + Mid$("office  cafe    mall    boutiquegym     park    beach   cinema  bar     club    karaoke concert funfair chapel  ", hk * 8 + 1, 8)
    s = Trim$(s)
  Next
  v = CybSys.PortCall("RAT", s)
  ndec = ndec + 1
  If ndec <= tell Then Print "RAT "; s; " -> "; v
  If CybSys.PortStatus() <> 0 Or v = "?" Or v = "" Then v = "home 0"
  j = InStr(v, " ")
  If j > 0 Then v = Left$(v, j - 1)
  pLast(p) = Left$(v, 16)
  Act p, LCase$(v)
End Sub

Function Pow2(ByVal n As Integer) As Integer
  Pow2 = 1
  If n = 1 Then Pow2 = 2
  If n = 2 Then Pow2 = 4
End Function

' RAT's pick (a path: eat.noodle) -> where: home, work, or the nearest shop of its kind
Sub Act(ByVal p As Integer, ByVal v As String)
  Dim leaf As String Max 16, j As Integer, t As Integer, we As Integer
  If v = "flee" Then
    GoTo2 p, PW(p, 4), PB(p, 6), S_HOME, 60, 1 : Exit Sub
  End If
  If v = "home" Then
    GoTo2 p, PW(p, 4), PB(p, 6), S_HOME, 60 + (p * 11) Mod 60, 0 : Exit Sub
  End If
  If v = "work" Then
    we = 540 + PB(p, 11) * 30
    GoTo2 p, PW(p, 7), PB(p, 9), S_WORK, Least(60, we - mins), 0 : Exit Sub
  End If
  leaf = v
  j = InStr(leaf, ".")
  Do While j > 0
    leaf = Mid$(leaf, j + 1) : j = InStr(leaf, ".")
  Loop
  t = TypeOf(leaf)
  If t < 0 Then GoTo2 p, PW(p, 4), PB(p, 6), S_HOME, 30, 0 : Exit Sub
  j = Nearest(t, RoomOf(p), p)
  If j < 0 Then GoTo2 p, PW(p, 4), PB(p, 6), S_HOME, 30, 0 : Exit Sub
  If Left$(v, 3) = "eat" Then
    GoTo2 p, db(so + j * 3) + db(so + j * 3 + 1) * 256, db(so + j * 3 + 2), S_EAT, 40, 0
  Else
    GoTo2 p, db(so + j * 3) + db(so + j * 3 + 1) * 256, db(so + j * 3 + 2), S_OUT, 60 + (p * 7 + mins) Mod 90, 0
  End If
End Sub

' a place's name -> its shop type (Town.cls's TY_*)
Function TypeOf(ByVal s As String) As Integer
  TypeOf = -1
  If s = "coffee" Then TypeOf = 0
  If s = "cafe" Then TypeOf = 0
  If s = "chicken" Then TypeOf = 2
  If s = "bbq" Then TypeOf = 3
  If s = "noodle" Then TypeOf = 4
  If s = "bakery" Then TypeOf = 5
  If s = "eat" Then TypeOf = 4
  If s = "cosmetics" Then TypeOf = 7
  If s = "pcbang" Then TypeOf = 8
  If s = "karaoke" Then TypeOf = 9
  If s = "salon" Then TypeOf = 10
  If s = "clothes" Then TypeOf = 11
  If s = "boutique" Then TypeOf = 11
  If s = "phone" Then TypeOf = 12
  If s = "teahouse" Then TypeOf = 15
  If s = "hanbok" Then TypeOf = 17
  If s = "gym" Then TypeOf = 18
  If s = "fish" Then TypeOf = 20
  If s = "beach" Then TypeOf = 20
  If s = "electro" Then TypeOf = 24
  If s = "mall" Then TypeOf = 33
  If s = "cinema" Then TypeOf = 25
  If s = "concert" Then TypeOf = 25
  If s = "club" Then TypeOf = 26
  If s = "bar" Then TypeOf = 26
  If s = "museum" Then TypeOf = 27
  If s = "office" Then TypeOf = 32
  If s = "dept" Then TypeOf = 33
  If s = "tower" Then TypeOf = 34
  If s = "funfair" Then TypeOf = 8
  If s = "palace" Then TypeOf = 35
  If s = "park" Then TypeOf = 35
  If s = "temple" Then TypeOf = 36
  If s = "chapel" Then TypeOf = 36
End Function

' the nearest shop of type t to street r (one of the nearest three): its place in the list, -1 none
Function Nearest(ByVal t As Integer, ByVal r0 As Integer, ByVal p As Integer) As Integer
  Dim j As Integer, d As Integer, b1 As Integer, b2 As Integer, b3 As Integer, d1 As Integer, d2 As Integer, d3 As Integer, x As Integer, y As Integer
  Nearest = -1
  If t < 0 Or t >= NT Then Exit Function
  If ts(t) = ts(t + 1) Then Exit Function
  x = r0 Mod 16 : y = r0 \ 16
  d1 = 999 : d2 = 999 : d3 = 999 : b1 = -1 : b2 = -1 : b3 = -1
  For j = ts(t) To ts(t + 1) - 1
    d = Abs(db(so + j * 3 + 2) Mod 16 - x) + Abs(db(so + j * 3 + 2) \ 16 - y)
    If d < d1 Then
      d3 = d2 : b3 = b2 : d2 = d1 : b2 = b1 : d1 = d : b1 = j
    ElseIf d < d2 Then
      d3 = d2 : b3 = b2 : d2 = d : b2 = j
    ElseIf d < d3 Then
      d3 = d : b3 = j
    End If
  Next
  Nearest = b1
  d = (p + mins) Mod 3
  If d = 1 And b2 >= 0 Then Nearest = b2
  If d = 2 And b3 >= 0 Then Nearest = b3
End Function

' p goes to shop sh (in street rm) to be in state st for dur minutes: there already, or a walk (a run:
' fleeing) street by street, 3 minutes a street (fleeing 2)
Sub GoTo2(ByVal p As Integer, ByVal sh As Integer, ByVal rm As Integer, ByVal st As Integer, ByVal dur As Integer, ByVal run As Integer)
  Dim d As Integer, r0 As Integer
  If dur < 10 Then dur = 10
  If pShop(p) = sh Then
    pState(p) = st : pNext(p) = mins + dur
  Else
    r0 = RoomOf(p)
    d = Abs(rm Mod 16 - r0 Mod 16) + Abs(rm \ 16 - r0 \ 16)
    pFrom(p) = r0 : pTo(p) = rm : pDest(p) = sh : pDo(p) = st : pDur(p) = dur
    pT0(p) = mins
    If run Then pT1(p) = mins + d * 2 + 1 : pState(p) = S_FLEE Else pT1(p) = mins + d * 3 + 2 : pState(p) = S_WALK
    pShop(p) = -2
  End If
  Publish p
End Sub

Sub Arrive(ByVal p As Integer)
  pShop(p) = pDest(p) : pRoom(p) = pTo(p) : pState(p) = pDo(p)
  pNext(p) = pT1(p) + pDur(p)
End Sub

' the street p is in now: their shop's, or on the way (along, then down)
Function RoomOf(ByVal p As Integer) As Integer
  Dim fx As Integer, fy As Integer, dx As Integer, dy As Integer, n As Integer, k2 As Integer
  If pState(p) <> S_WALK And pState(p) <> S_FLEE Then RoomOf = pRoom(p) : Exit Function
  fx = pFrom(p) Mod 16 : fy = pFrom(p) \ 16
  dx = pTo(p) Mod 16 - fx : dy = pTo(p) \ 16 - fy
  n = Abs(dx) + Abs(dy)
  If n = 0 Or pT1(p) <= pT0(p) Then RoomOf = pTo(p) : Exit Function
  k2 = ((mins - pT0(p)) * n) \ (pT1(p) - pT0(p))
  If k2 > n Then k2 = n
  If k2 <= Abs(dx) Then
    If dx < 0 Then fx = fx - k2 Else fx = fx + k2
  Else
    fx = fx + dx
    If dy < 0 Then fy = fy - (k2 - Abs(dx)) Else fy = fy + (k2 - Abs(dx))
  End If
  RoomOf = fy * 16 + fx
End Function

' fright at street rd: level v there and within n streets of it
Function Fright(ByVal rd As Integer, ByVal v As Integer, ByVal n As Integer) As Integer
  Dim x As Integer, y As Integer, j As Integer, c As Integer, p As Integer
  If rd < 0 Or rd > 191 Then Exit Function
  If v > 100 Then v = 100
  x = rd Mod 16 : y = rd \ 16
  For j = 0 To 191
    If Abs(j Mod 16 - x) + Abs(j \ 16 - y) <= n Then
      If alert(j) < v Then alert(j) = v
    End If
  Next
  For p = 0 To NP - 1
    If pState(p) <> S_AWAY Then
      j = alert(RoomOf(p))
      If j > pFear(p) Then
        pFear(p) = j : c = c + 1
        If pState(p) = S_WALK Then pState(p) = S_OUT : pRoom(p) = RoomOf(p) : pShop(p) = -2
        pNext(p) = mins
      End If
    End If
  Next
  Fright = c
End Function

' p's row of the table a game reads: shop (2), street, state, food, energy, fear
Sub Publish(ByVal p As Integer)
  Dim o As Integer
  o = p * 8
  tb(o) = pShop(p) And 255 : tb(o + 1) = (pShop(p) \ 256) And 255
  tb(o + 2) = RoomOf(p) : tb(o + 3) = pState(p)
  tb(o + 4) = pFood(p) : tb(o + 5) = pEnergy(p) : tb(o + 6) = pFear(p)
End Sub
