' Game - LITTLE SEOUL, on THE LITTLE SEOUL ENGINE (City.bas). You're Seoul's newest postie. Every
' working day for four weeks you leave the Central Post Office in Myeongdong with a bag of letters and
' parcels and walk them round the city: the hundred people of the town at their addresses, shops,
' flats up in the lifts, strangers who ignore you. Crazy Taxi on foot: the clock runs from 9:00 to 18:00.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'
' Keys: Q A O P (or a joystick) walk, Space talks / picks / goes on, M the bag and the map (and back),
' T hyperspace.
'
' THIS FILE IS THE GAME - everything the city doesn't decide. For a new game replace it (docs/NEWGAME.md):
'   1. the start: CityStart (the city's start-up), then your own loop - here the title, a new
'      postie, then a season of days (Season -> OneDay -> Round, City.bas's frame loop)
'   2. the subs City.bas calls (City.bas's header has the list): Clockwork, Hud, HudTime, Stat,
'      Feel, BagScreen, Knock, Mailbox, Counter, AfterShop, BagFor, ItemWords, Delivered
'   3. your state: Public variables here; the city's (where you are, the clock) are City.bas's
'   4. your story: scripts/POST.txt and DELIVER.txt are this game's; CHAT, SHOPS, STRANGERS and
'      THINGS are the city's voices (tools/storyc.py makes them all into Data.cls's scenes)
Option Explicit
Option Turbo

' the stats (the script's !STAT numbers)
Public Const S_ENERGY = 0, S_SPEED = 1, S_BOSS = 2, S_REP = 3, S_TIME = 4, S_LOOKUP = 5, S_APP = 6, S_HAIR = 7, S_LOOK = 8
Public Const S_HANBOK = 9, S_FLOWERS = 10, S_ASK = 11
Public Const BAGMAX = 12
' the clock: minutes from midnight
Public Const T_START = 540
' the cast's faces (9 bytes each), who they are (-1: nobody in particular), how the town feels
Public myLook(8) As Byte
Public male As Integer, me As Integer
' the bag: whose (a person, or -1 a shop's), the building, floor, flat, letter 0 / parcel 1, done, from
Public bFloor(11) As Byte, bUnit(11) As Byte, bFrom(11) As Byte
Public nDone As Integer
Public tickM As Integer, rep As Integer
Public strikes As Integer, total As Integer, totalDone As Integer, hanbok As Integer
Public wantHair As Integer, hungry As Integer

' ---------------------------------------------------------------- the game starts here
CityStart
Do
  TitleScr
  NewMe
  Season
Loop

' ---------------------------------------------------------------- your stats
Sub Stat(ByVal s As Integer, ByVal v As Integer)
  Select Case s
    Case S_ENERGY
      energy = Clamp(energy + v)
      If v > 0 Then Fx 200, 120, 7
    Case S_SPEED
      speedT = speedT + v
    Case S_BOSS
      boss = Clamp(boss + v)
      If v > 0 Then Fx 200, 120, 1 Else Fx 200, 120, 9
    Case S_REP
      rep = Clamp(rep + v)
    Case S_TIME
      mins = mins + v
    Case S_LOOKUP, S_ASK
      lookup = 1
    Case S_APP
      hasApp = 1
    Case S_HAIR
      wantHair = 1
    Case S_LOOK
      pPal = 1 + (pPal Mod 10)
    Case S_HANBOK
      hanbok = 1
    Case S_FLOWERS
      flowers = flowers + 1
  End Select
End Sub

Sub Feel(ByVal v As Integer)
  If themP < 0 Then Exit Sub
  v = aff(themP) + v
  If v < 0 Then v = 0
  If v > 100 Then v = 100
  aff(themP) = v
End Sub

' Won(v): v hundreds of won as W12,500
Function Won(ByVal v As Integer) As String
  Dim s As String, a As Integer
  a = Abs(v)
  If a >= 10 Then
    s = CStr(a \ 10) & "," & CStr(a Mod 10) & "00"
  ElseIf a > 0 Then
    s = CStr(a) & "00"
  Else
    s = "0"
  End If
  If v < 0 Then s = "-" & s
  Won = "W" & s
End Function

' the top and bottom lines
Sub Hud()
  Board.Rect 0, 0, 40, 3, 0, 0
  Board.Rect 0, 28, 40, 4, 0, 0
  Board.Text 2, 1, "DAY " & CStr(day), C_GOLD
  Board.Text 9, 1, Clock(), C_WHITE
  Board.Text 16, 1, Won(money), C_MINT
  Board.Text 25, 1, "BAG " & CStr(nDone) & "/" & CStr(nBag), C_PINK
  Bar 36, 1, 3, energy, energy > 25
  If inShop >= 0 Then
    If floors > 1 Then txt = placeS & " " & CStr(floor) & "F" Else txt = placeS
  Else
    txt = distS
    If rc(194) And 4 Then txt = TabStr(Data.W_BRIDGES, (room Mod 16) * 16, 16)
  End If
  Board.Text 2, 29, Left$(txt, 36), C_WHITE
End Sub

Sub HudTime()
  Board.Text 9, 1, Clock(), C_WHITE
  Bar 36, 1, 3, energy, energy > 25
End Sub

' the clock: a minute every half a second; you get hungry
Sub Clockwork()
  tickM = tickM + 1
  If tickM < 25 Then Exit Sub
  tickM = 0
  mins = mins + 1
  If speedT > 0 Then speedT = speedT - 1
  If (mins Mod 6) = 0 And energy > 0 Then energy = energy - 1
  OffStage
  HudTime
  If energy = 20 And hungry = 0 Then
    hungry = 1
    Talk Data.TH_HUNGRY, K_YOU
  End If
  If energy = 0 Then
    Talk Data.TH_TIRED, K_YOU
    mins = mins + 30 : energy = 25
    Hud
  End If
End Sub

' ---------------------------------------------------------------- the bag
' the bag's item for building s (flat f, or any: -1), not yet delivered (-1 none)
Function BagFor(ByVal s As Integer, ByVal fl As Integer) As Integer
  Dim j As Integer
  BagFor = -1
  For j = 0 To nBag - 1
    If bDone(j) = 0 And bShop(j) = s Then
      If fl < 0 Or bFloor(j) = fl Then BagFor = j : Exit Function
    End If
  Next
End Function

Function FromName(ByVal kk As Integer) As String
  Dim s As String, t As Integer, p As Integer, q As Integer, k As Integer
  k = kk
  If k < 8 Then
    s = "MUM|GRANDMA|A BANK|THE TAX OFFICE|A FAN|AN ONLINE SHOP|A SECRET ADMIRER|THE GAS COMPANY"
  Else
    s = "A COUSIN|THE UNIVERSITY|A LAWYER|AN OLD FRIEND|THE LOTTERY|A PEN PAL|THE COUNCIL|DAD"
    k = k - 8
  End If
  p = 1
  For t = 0 To k
    q = InStr(p, s & "|", "|")
    If t = k Then FromName = Mid$(s, p, q - p) : Exit Function
    p = q + 1
  Next
End Function

Sub ItemWords(ByVal j As Integer)
  If bKind(j) Then itemS = "PARCEL" Else itemS = "LETTER"
  tokT = FromName(bFrom(j))
End Sub

' item j delivered: pay, tips, hearts (by hand / to them / left / in the mailbox: how 0 - 3)
Sub Delivered(ByVal j As Integer, ByVal how As Integer)
  Dim tip As Integer
  bDone(j) = 1 : nDone = nDone + 1 : totalDone = totalDone + 1
  Ding
  tip = 0
  If how <= 1 And bP(j) >= 0 Then
    If aff(bP(j)) >= 40 Then tip = 10 + (aff(bP(j)) \ 20) * 5
    Feel 2
  End If
  If how = 0 Then tip = tip + 20
  If bKind(j) Then money = money + 30 + tip Else money = money + 15 + tip
  rep = Clamp(rep + 1)
  If how <= 1 Then Fx px + 32, py + 16, 10 Else Fx px + 32, py + 16, 14
  If nDone = nBag Then Fx px + 32, py + 8, 14 : Fx px + 40, py + 12, 3
  Hud
End Sub

' knock at flat u on floor fl of building s (a house: 1, 1)
Sub Knock(ByVal s As Integer, ByVal fl As Integer, ByVal u As Integer)
  Dim j As Integer, p As Integer, home As Integer
  Sfx.Play 1, 600, 0, 13, 4, 1 : WaitF 8 : Sfx.Play 1, 600, 0, 13, 4, 1 : WaitF 20
  ' who lives here?
  p = -1
  For j = 0 To 99
    If HomeAt(j) = s And tb(2) = fl And tb(3) = u Then p = j
  Next
  j = -1
  For k = 0 To nBag - 1
    If bDone(k) = 0 And bShop(k) = s And bFloor(k) = fl And bUnit(k) = u Then j = k
  Next
  If j >= 0 Then
    ItemWords j
    If p < 0 Then
      ThemNobody "RESIDENT", s * 7 + u, 1 + (s + u) Mod 4
    Else
      ThemIs p
    End If
    If p >= 0 Then home = (WhereAt(p, mins) = s) Else home = ((day + fl + u) Mod 3) <> 0
    If home Then
      If p >= 0 And aff(p) >= 60 Then Play Data.DE_FRIEND01 + Rnd(6), K_THEM Else Play Data.DE_DLV01 + Rnd(16), K_THEM
      Face.Hide 0 : TalkOff
      Delivered j, 1
    Else
      Talk Data.DE_AWAY01 + Rnd(4), -1
      Delivered j, 2
    End If
    Exit Sub
  End If
  If p >= 0 Then
    If WhereAt(p, mins) <> s Then p = -1
  End If
  If p >= 0 Then
    ThemIs p
    If flowers > 0 Then
      flowers = flowers - 1
      Talk Data.DE_GIFT, K_THEM
    Else
      Talk Data.DE_KNOCKED, K_THEM
    End If
    Exit Sub
  End If
  ThemNobody "NEIGHBOUR", s * 3 + fl * 5 + u, 1 + (fl + u) Mod 4
  Talk Data.DE_WRONG01 + Rnd(8), K_THEM
End Sub

' the mailboxes in a lobby: every letter for this building goes in
Sub Mailbox()
  Dim j As Integer, c As Integer
  c = 0
  For j = 0 To nBag - 1
    If bDone(j) = 0 And bShop(j) = inShop And bKind(j) = 0 Then
      If c = 0 Then Talk Data.DE_MAILBOX, -1
      Delivered j, 3 : c = c + 1
    End If
  Next
  If c = 0 Then Note "NOTHING FOR " & placeS & "." : RoomText
End Sub

' the counter: whoever's behind it
Sub Counter()
  Dim j As Integer, id As Integer
  LoadType sType
  ThemNobody TabStr(Data.W_TYPES, (sType) * 64 + 32, 10), inShop, ty(5)
  If sType = Town.TY_POST Then
    cst(K_THEM) = cst(K_BOSS) : themP = -1
    For j = 0 To 8
      cLook(9 + j) = cLook(18 + j)
    Next
  End If
  ' a delivery for the shop?
  j = BagFor(inShop, -1)
  If j >= 0 And bP(j) < 0 Then
    ItemWords j
    Talk Data.DE_BIZ01 + Rnd(8), K_THEM
    Delivered j, 1
    Exit Sub
  End If
  id = Data.SH_CAFE + sType
  If sType = Town.TY_TOWER And floor > 1 Then id = Data.SH_VIEW
  Talk id, K_THEM
  AfterShop
End Sub

' what the shop did to you
Sub AfterShop()
  If wantHair Then
    wantHair = 0
    myLook(2) = (myLook(2) + 1 + Rnd(6)) Mod 15
    cLook(2) = myLook(2)
  End If
  Hud
End Sub

' ---------------------------------------------------------------- the title
Sub TitleScr()
  Dim j As Integer, t As Integer
  Blank
  talking = 0
  GameSet.Load Data.GAMEPAGE
  fxBase = GfxData.S_ICON : fxFl = Spr.Pal * 15
  LoadRoom 4 * 16 + 6
  World.Draw VarPtr(rc)
  L2.Big 24, 18, "LITTLE", 4, &HFF, &H00
  L2.Big 56, 58, "SEOUL", 4, &HE0, &H00
  Mid1 22, "SEOUL'S NEWEST POSTIE", C_GOLD
  Mid1 24, "SPACE: START", C_WHITE
  Mid1 29, "(C) 2026 CYBORG UNICORN", C_GREY
  tune = 1 : beat = 0
  t = -40
  Do
    Tick
    t = t + 2
    If t > 300 Then t = -40
    Spr.Put SP_YOU, t + 32, 120, GfxData.S_POSTIE + 7 + ((frames \ 5) And 1), 0
  Loop Until Key() = 5
  tune = 0
  FxClear
  Sfx.Play 0, 100, -2, 14, 20, 0
End Sub

' ---------------------------------------------------------------- making you
Sub NewMe()
  Dim sel As Integer
  Blank
  Backdrop
  sel = 1 + YesNo("SEOUL'S NEW POSTIE IS...", "A MAN", "A WOMAN")
  male = 1 - sel
  TalkOn
  me = PickFace(sel)
  LoadRec me
  For k = 0 To 8
    myLook(k) = rec(8 + k)
  Next
  pName = PNameOf(me)
  Blank
  Backdrop
  Face.Put 0, VarPtr(myLook), 144, 168, 2, 0, 0
  NameEntry
  Face.Hide 0
  Cast
End Sub

' the Postmaster and your colleague; everyone's feelings
Sub Cast()
  Dim p As Integer
  For k = 0 To 99
    aff(k) = 20 : met(k) = 0
  Next
  cst(K_YOU) = me
  For k = 0 To 8
    cLook(k) = myLook(k)
  Next
  Do
    p = Rnd(100)
  Loop Until p <> me
  cst(K_BOSS) = p : LookOf K_BOSS, p
  cLook(K_BOSS * 9 + 3) = 6
  Do
    p = Rnd(100)
  Loop Until p <> me And p <> cst(K_BOSS)
  cst(K_X) = p : LookOf K_X, p
End Sub

' ---------------------------------------------------------------- four weeks
Sub Season()
  Dim r As Integer, sc As Integer, best As Integer, b As Integer
  money = 100 : boss = 50 : rep = 20 : strikes = 0 : total = 0 : totalDone = 0 : pPal = 0
  hasApp = 0 : hanbok = 0 : flowers = 0 : energy = 100
  For k = 0 To NN - 1
    nRoom(k) = -1
  Next
  For day = 1 To DAYS
    r = OneDay()
    If r < 0 Then
      Morning
      Play Data.PO_SACKED, K_BOSS
      Play Data.PO_E_SACKED, K_YOU
      Final "SACKED"
      Exit Sub
    End If
  Next
  day = DAYS
  Morning
  Play Data.PO_LASTDAY, K_BOSS
  sc = 0
  If total > 0 Then sc = (totalDone * 100) \ total
  If sc >= 90 And boss >= 60 Then
    Play Data.PO_E_TOP, K_BOSS : txt = "POSTIE OF THE YEAR"
  ElseIf sc >= 70 Then
    Play Data.PO_E_GOOD, K_BOSS : txt = "A ROUND OF YOUR OWN"
  Else
    Play Data.PO_E_OK, K_BOSS : txt = "BACK TO SORTING"
  End If
  ' and love?
  best = 0
  For b = 1 To 99
    If aff(b) > aff(best) Then best = b
  Next
  Face.Hide 0
  If aff(best) >= 60 Then
    ThemIs best
    Play Data.PO_LOVE, K_THEM
    Play Data.PO_LOVE2, K_THEM
    If pick = 1 Then txt = txt & " + " & PNameOf(best)
  Else
    Play Data.PO_NOLOVE, K_YOU
  End If
  Final txt
End Sub

' at the Central Post Office, in front of the counter
Sub Morning()
  GoInside Town.POSTSHOP, 1, 160, 64, 1
  DrawAll
End Sub

' a day: 1 fine, 0 a bad day, -1 sacked
Function OneDay() As Integer
  Dim m0 As Integer, j As Integer
  mins = T_START : tickM = 0 : speedT = 0 : lookup = 0 : hungry = 0 : hitToday = 0
  energy = 100
  MakeBag
  Morning
  If day = 1 Then
    Play Data.PO_INTRO, K_BOSS
    Play Data.PO_INTRO2, K_X
  End If
  Play Data.PO_MORN01 + day - 1, K_BOSS
  Face.Hide 0
  TalkOff
  m0 = money
  BagScreen 1
  Round
  ' the day's done
  Spr.HideRange 0, 111
  Talk Data.TH_NIGHT, -1
  Morning
  total = total + nBag
  If nDone = nBag Then
    Play Data.PO_PRAISE, K_BOSS : boss = Clamp(boss + 5) : OneDay = 1
  ElseIf nDone * 2 >= nBag Then
    Play Data.PO_FINE, K_BOSS : OneDay = 1
  Else
    strikes = strikes + 1 : boss = Clamp(boss - 5) : OneDay = 0
    If strikes = 1 Then Play Data.PO_SCOLD, K_BOSS
    If strikes = 2 Then Play Data.PO_WARN, K_BOSS
    If strikes >= 3 Then OneDay = -1 : Exit Function
  End If
  If day Mod 5 = 0 Then
    Play Data.PO_PAYDAY, K_BOSS
    money = money + 500
  End If
  Face.Hide 0
  Results m0
End Function

' the day's sums
Sub Results(ByVal m0 As Integer)
  TalkOff
  Spr.HideRange 0, 111
  Board.Rect 0, 0, 40, 32, 0, 0
  Panel 6, 4, 28, 14
  Mid1 5, "DAY " & CStr(day) & " IS DONE", C_GOLD
  Board.Text 8, 7, "DELIVERED   " & CStr(nDone) & " OF " & CStr(nBag), C_WHITE
  Board.Text 8, 9, "MONEY TODAY " & Won(money - m0), C_MINT
  Board.Text 8, 10, "IN YOUR POCKET " & Won(money), C_MINT
  Board.Text 8, 12, "THE BOSS", C_WHITE : Bar 20, 12, 10, boss, 1
  Board.Text 8, 13, "THE TOWN", C_WHITE : Bar 20, 13, 10, rep, 0
  Board.Text 8, 15, "STRIKES: " & CStr(strikes) & " OF 3", C_PINK
  k = AnyKey()
End Sub

Sub Final(ByVal s As String)
  Face.Hide 0
  TalkOff
  Board.Rect 0, 0, 40, 32, 0, 0
  Panel 4, 5, 32, 14
  Mid1 7, s, C_GOLD
  Mid1 9, CStr(totalDone) & " OF " & CStr(total) & " DELIVERED", C_WHITE
  Mid1 11, "SAVED UP: " & Won(money), C_MINT
  Mid1 13, CStr(MetCount()) & " PEOPLE KNOW YOUR NAME", C_PINK
  Mid1 16, "SPACE", C_GREY
  k = AnyKey()
End Sub

Function MetCount() As Integer
  Dim c As Integer, p As Integer
  c = 0
  For p = 0 To 99
    If met(p) Then c = c + 1
  Next
  MetCount = c
End Function

' ---------------------------------------------------------------- the bag
Sub MakeBag()
  Dim j As Integer, p As Integer, t As Integer, rad As Integer, r As Integer, s As Integer, ok As Integer
  nBag = 3 + (day * 9) \ 20
  If nBag > BAGMAX Then nBag = BAGMAX
  nDone = 0
  rad = 2 + day \ 2
  For j = 0 To nBag - 1
    bDone(j) = 0 : bFrom(j) = Rnd(16) : bKind(j) = (Rnd(5) < 2) And 1
    ok = 0
    If Rnd(4) = 0 Then
      ' a shop's post
      For t = 1 To 30
        r = Rnd(192)
        If Abs(r Mod 16 - 6) + Abs(r \ 16 - 4) <= rad Then
          LoadRoom r
          If rc(195) > 0 Then
            k = Rnd(rc(195))
            s = rc(197 + k * 4) + rc(198 + k * 4) * 256
            LoadShop s
            If sh(0) < Town.TY_APT And sh(0) <> Town.TY_POST And sh(0) <> Town.TY_MUSEUM Then
              bP(j) = -1 : bShop(j) = s : bFloor(j) = 1 : bUnit(j) = 0 : ok = 1 : Exit For
            End If
          End If
        End If
      Next
    End If
    If ok = 0 Then
      For t = 1 To 60
        p = Rnd(100)
        If Abs(HomeRoom(p) Mod 16 - 6) + Abs(HomeRoom(p) \ 16 - 4) <= rad Or t > 50 Then
          ok = 1
          For k = 0 To j - 1
            If bP(k) = p Then ok = 0
          Next
          If ok Then Exit For
        End If
      Next
      bP(j) = p : bShop(j) = HomeAt(p) : bFloor(j) = tb(2) : bUnit(j) = tb(3)
    End If
  Next
End Sub

' the bag: what's in it (full: the morning, with every address); Space the map, M back
Sub BagScreen(ByVal full As Integer)
  Dim j As Integer, y As Integer, c As Integer, v As Integer, a As String
  Spr.HideRange 0, 111
  Board.Rect 0, 0, 40, 32, 0, 0
  Panel 0, 0, 40, 32
  If full Then Mid1 1, "TODAY'S ROUND: LEARN THE ADDRESSES!", C_GOLD Else Mid1 1, "THE BAG - " & Clock(), C_GOLD
  For j = 0 To nBag - 1
    y = 3 + j * 2
    If bDone(j) Then c = C_DIM Else c = C_WHITE
    If bKind(j) Then a = "P " Else a = "L "
    If bP(j) >= 0 Then a = a & PNameOf(bP(j)) Else a = a & ShopName(bShop(j))
    LoadShop bShop(j)
    a = a & " - " & DistName(sh(4))
    If bDone(j) Then a = a & " (DONE)"
    Board.Text 2, y, Left$(a, 36), c
    If bDone(j) = 0 And bP(j) >= 0 Then
      If full Or lookup Then
        Board.Text 4, y + 1, Left$(Address(bShop(j), bFloor(j), bUnit(j)), 34), C_MINT
      Else
        Board.Text 4, y + 1, "...", C_DIM
      End If
    End If
  Next
  Board.Text 2, 28, "L LETTER (MAILBOX OK)  P PARCEL (DOOR)", C_GREY
  Board.Text 2, 30, "SPACE: THE MAP   M: BACK", C_GREY
  Do
    Tick
    v = Key()
  Loop Until v >= 5
  Board.Clear
  If v = 5 Then MapScreen
  Enter
End Sub
