' City - THE LITTLE SEOUL ENGINE: everything that is the city and not a game, for the ZX Spectrum
' Next in NTC BASIC. 192 screens of Seoul (its districts, landmarks, the Han and its bridges, the
' subway), shops and their insides, lifts and stairs, the hundred people at their addresses living
' their days, strangers, cars, talking (faces, the scene player), the map, hyperspace (T), and the
' frame loop that walks you round it all. The city's data is in the Next's other RAM (Data.cls,
' Town.cls, World.cls; tools/ makes it), its pictures in GfxData.cls (gfx/).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'
' A NEW GAME: copy the engine, leave this file alone and write your own Game.bas (LITTLE SEOUL's,
' the postie game, is the example). The game owns the program's start (it calls CityStart first,
' then plays rounds of the city with Round) and its rules. docs/NEWGAME.md says it step by step.
'
' What this file calls in Game.bas - a game must have each of these (they may be empty):
'   Clockwork            once a frame, from Round: the game's clock (mins goes on), hunger ...
'   Hud                  the status line (after a talk, going in somewhere, a market stall)
'   Stat s, v / Feel v   a scene's !STAT and +N / -N lines (Play)
'   BagScreen 0          the M key, from Round (the postie's bag; its Space shows MapScreen)
'   Knock s, fl, u       a door: a house's (Door) or a flat's (Act)
'   Mailbox, Counter     Space on an apartment's mailboxes, on a shop's counter (Act)
'   AfterShop            after a shop's own scene (TalkTo, Counter)
'   BagFor, ItemWords, Delivered   the postie's bag - used on the lines marked ' GAME: here
' Lines marked ' GAME: below are a game's rules inside the city's routines (the postie's deliveries
' in TalkTo, the arrow to the next one, the bag on the map, money for the subway, a car knocking
' your energy): change or drop them for another game. Everything else is the city.
'
' What the city keeps that a game uses: day, mins (the clock: minutes from midnight), room / inShop /
' floor / px / py (where you are), stun, energy and speedT (how you walk), money (hundreds of won), cst / cLook (who's
' talking), aff / met (how the hundred feel about you), quit (Round ends when it is set).
Option Explicit

' text colours (tilemap palette rows)
Public Const C_WHITE = 0, C_GOLD = 1, C_PINK = 2, C_MINT = 3, C_GREY = 4, C_HI = 5, C_DIM = 6, C_BLACK = 7
' the cast: you, them (whoever you're talking to), the Postmaster, your colleague
Public Const K_YOU = 0, K_THEM = 1, K_BOSS = 2, K_X = 3
Public Const DAYS = 20, NN = 10, NCAR = 2
' the clock: minutes from midnight
Public Const T_END = 1080
' sprite slots
Public Const SP_YOU = 0, SP_NPC = 2, SP_NICON = 12, SP_KEEP = 22, SP_STALL = 23, SP_CAR = 27, SP_ARROW = 36, SP_MARK = 37
Public Const SL_FX = 111, NFX = 8

Public txt As String Max 80, pName As String Max 8, themName As String Max 12, lab0 As String Max 32, lab1 As String Max 32, lab2 As String Max 32
Public placeS As String Max 20, distS As String Max 16, itemS As String Max 8, tokT As String Max 16, tokH As String Max 20
' a person's record (fetched from Data when needed): 0 girl, 1 age, ... 8-16 the look, 24-31 the name
Public rec(31) As Byte, recOf As Integer, broke As Integer, hatV As Integer, slotWas As Integer, schedPg As Integer
' the scene being played, a line of it, a directory entry, a word from a table
Public sb(447) As Byte, lb(63) As Byte, de8(7) As Byte, tb(23) As Byte
' the cast's faces (9 bytes each), who they are (-1: nobody in particular), how the town feels
Public cLook(35) As Byte, cst(3) As Integer, aff(99) As Byte, met(99) As Byte
Public themP As Integer
' the city: this room's record, a shop's, a type's; block attributes and map colours
Public rc(255) As Byte, sh(7) As Byte, ty(63) As Byte, battr(255) As Byte
' the hundred's homes: the building (a shop), floor, flat, its street, its district
' where you are: a street (room 0-191) or inside a shop (inShop, on floor) whose door is in streetRoom
Public room As Integer, inShop As Integer, floor As Integer, floors As Integer, sType As Integer, streetRoom As Integer, doorCell As Integer
Public px As Integer, py As Integer, pdir As Integer, pstep As Integer, stun As Integer, pPal As Integer
' the bag: whose (a person, or -1 a shop's), the building, floor, flat, letter 0 / parcel 1, done, from
Public bP(11) As Integer, bShop(11) As Integer, bKind(11) As Byte, bDone(11) As Byte
Public nBag As Integer
' people about: their room (-1 none: a street 0-191, a shop 256 +), place, where they're going, what
' they're doing, for how long, their sprite, colours, who (-1 a stranger), facing
Public nRoom(9) As Integer, npx(9) As Integer, npy(9) As Integer, ntx(9) As Integer, nty(9) As Integer, nst(9) As Byte
Public ntm(9) As Integer, nkind(9) As Byte, npal(9) As Byte, nwho(9) As Integer, ndir(9) As Byte, nicon(9) As Byte, nyf(9) As Byte
' cars: x (-99 none), lane (0 going left, 1 right), speed, kind (0 car, 1 taxi, 2 bus, 3 scooter), colour
Public cx(1) As Integer, crm(1) As Integer, cl(1) As Byte, cv(1) As Byte, ck(1) As Byte, cpal(1) As Byte
Public day As Integer, mins As Integer, money As Integer, energy As Integer, speedT As Integer, boss As Integer
Public lookup As Integer, hasApp As Integer, flowers As Integer
Public shownName As Integer, hitToday As Integer, fxBase As Integer, fxFl As Integer, talking As Integer, quit As Integer
Public fxX(7) As Integer, fxY(7) As Integer, fxT(7) As Integer, fxP(7) As Integer
Public keyT As Integer, firWas As Integer, frames As Integer, beat As Integer, tune As Integer, fast As Integer
Public spk As Integer, pa As Integer, pb As Integer, pg As Integer, pick As Integer, mood As Integer, faceOn As Integer
Public i As Integer, k As Integer, n As Integer, f As Integer

' ---------------------------------------------------------------- as a CyborgOS task (docs/TASK.md)
#If NTC_ZXN Then
#Else
' The city's data: LSCITY.DAT (tools/cosnext.sh makes it), next to LSGAME.CYB - Nx.LoadCity has
' the details
' TaskStart: the console's screen registers noted (Nx.ConSave), the data loaded (Nx.LoadCity: the store taken, LSCITY.DAT read into it, the page table at
' #BF00 - a data page as the NEX has it -> the 8K page it is in now), the task's own page in slot 7
' noted, bank 5's first page in slot 6; then it waits to be in front (RUN 7 LSGAME, then Caps
' Shift + 7) - a game draws only while it's in front
Sub TaskStart()
  Dim r As Integer
  Print "LITTLE SEOUL: loading the city ..."
  r = Nx.LoadCity()                             ' (first: it asks CyborgOS which machine this is before
  If r = 6 Then Print "For the ZX Spectrum Next" : End   ' any port is touched - on a CPC #243B is the PPI)
  If r = 1 Then Print "Not enough free memory" : End
  If r = 2 Then Print "The store's pages not found" : End
  If r = 3 Then Print "LSCITY.DAT not found" : End
  If r = 4 Then Print "LSCITY.DAT too short, or not the city" : End
  If r = 5 Then Print "No three 16K pages in a row for Layer 2" : End
  Nx.Snap                                       ' (the console's screen registers, before the game
  Nx.ConSave                                    ' has touched them: put back whenever it's away)
  Nx.TaskInit
  Print "LITTLE SEOUL: ready - Caps Shift + its slot's number to play"
  Do
    Nx.Yield
  Loop Until Nx.Front()
End Sub

#End If

' ---------------------------------------------------------------- the city's start-up
' CityStart: the Next's hardware, the graphics, the city's tables - call it once, first thing (Game.bas does)
Sub CityStart()
#If NTC_ZXN Then
#Else
  TaskStart                                     ' (a CyborgOS task: its pages, the data's banks)
#End If
  Nx.Border 0
  Tiles.Init
  Spr.Init
  GfxData.Load
  schedPg = Data.W_SCHED
  Sfx.Init
  Board.Init
  L2.Init
  Data.Init
  World.Init Data.W_BLOCKS
  Nx.Layers Nx.OrderSUL
  Nx.Reg &H4A, 0
  Colours
  recOf = -1
  Data.Copy Data.W_ATTR, 0, 256, VarPtr(battr)
  fxBase = GfxData.S_ICON : fxFl = Spr.Pal * 15
End Sub


Sub Colours()
  Dim r As Integer
  For r = 0 To 6
    Board.Pal r, "00" & Mid$("FFF8F27EB6FF6A", r * 2 + 1, 2) & "F7EA8641D721F87E77B649E561E3"
  Next
  Board.Pal 5, "00FFF7EA86EAD721F87E77B649E5A1E3"
  Board.Pal 7, "00FFF7EA8600D721F87E77B649E500E3"
End Sub


Sub Panel(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer)
  Board.Rect x + 1, y + 1, w - 2, h - 2, GfxData.T_BOX, 0
  Board.Rect x + 1, y, w - 2, 1, GfxData.T_FT, 0
  Board.Rect x + 1, y + h - 1, w - 2, 1, GfxData.T_FB, 0
  Board.Rect x, y + 1, 1, h - 2, GfxData.T_FL, 0
  Board.Rect x + w - 1, y + 1, 1, h - 2, GfxData.T_FR, 0
  Board.Put x, y, GfxData.T_FTL, 0 : Board.Put x + w - 1, y, GfxData.T_FTR, 0
  Board.Put x, y + h - 1, GfxData.T_FBL, 0 : Board.Put x + w - 1, y + h - 1, GfxData.T_FBR, 0
End Sub


Sub Mid1(ByVal y As Integer, ByVal s As String, ByVal c As Integer)
  Board.Text 20 - Len(s) \ 2, y, s, c
End Sub


Sub Bar(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal v As Integer, ByVal mint As Integer)
  Dim p As Integer, t As Integer, b As Integer
  If v < 0 Then v = 0
  If v > 100 Then v = 100
  p = (v * w * 8) \ 100
  b = GfxData.T_BARP
  If mint Then b = GfxData.T_BARM
  For t = 0 To w - 1
    If p >= 8 Then
      Board.Put x + t, y, b + 8, 0 : p = p - 8
    Else
      Board.Put x + t, y, b + p, 0 : p = 0
    End If
  Next
End Sub


Function Key() As Integer
  Dim j As Integer, v As Integer, f2 As Integer
  j = Keys.Joystick(0)
  v = 0
  If Keys.Down(Keys.KeyQ) Or (j And Keys.JoyUp) Then v = 1
  If Keys.Down(Keys.KeyA) Or (j And Keys.JoyDown) Then v = 2
  If Keys.Down(Keys.KeyO) Or (j And Keys.JoyLeft) Then v = 3
  If Keys.Down(Keys.KeyP) Or (j And Keys.JoyRight) Then v = 4
  f2 = 0
  If Keys.Down(Keys.KeySpace) Or (j And Keys.JoyFire1) Then f2 = 5
  If Keys.Down(Keys.KeyM) Or (j And Keys.JoyFire2) Then f2 = 6
  If f2 Then
    If firWas = 0 Then firWas = f2 : Key = f2 : Exit Function
    Key = 0 : Exit Function
  End If
  firWas = 0
  If v = 0 Then keyT = 0 : Key = 0 : Exit Function
  If keyT = 0 Then
    keyT = 14 : Key = v
  Else
    keyT = keyT - 1
    If keyT = 0 Then keyT = 6 : Key = v Else Key = 0
  End If
End Function


Sub WaitF(ByVal t As Integer)
  Dim j As Integer
  For j = 1 To t
    Tick
  Next
End Sub


Function AnyKey() As Integer
  Dim v As Integer
  Do
    Tick
    v = Key()
  Loop Until v >= 5
  AnyKey = v
End Function


Sub FxMove()
  Dim j As Integer
  For j = 0 To NFX - 1
    If fxT(j) Then
      fxT(j) = fxT(j) - 1
      fxY(j) = fxY(j) - 1
      If (fxT(j) And 4) Then fxX(j) = fxX(j) + 1 Else fxX(j) = fxX(j) - 1
      If fxT(j) = 0 Or fxY(j) < 8 Then
        fxT(j) = 0 : Spr.Hide SL_FX + j
      Else
        Spr.Put SL_FX + j, fxX(j), fxY(j), fxBase + fxP(j), fxFl
      End If
    End If
  Next
End Sub


Sub FxClear()
  For k = 0 To NFX - 1
    fxT(k) = 0
  Next
  Spr.HideRange SL_FX, NFX
End Sub


Sub Ring()
  Dim j As Integer
  For j = 1 To 2
    Sfx.Play 1, 45, 0, 14, 14, 0
    WaitF 18
  Next
End Sub


Sub Blip()
  Sfx.Play 0, 120, -2, 12, 6, 0
End Sub


Sub Kerching()
  Sfx.Play 0, 60, -1, 14, 10, 0
  WaitF 6
  Sfx.Play 1, 40, -1, 14, 16, 0
End Sub


Sub LoadRec(ByVal p As Integer)
  If recOf = p Then Exit Sub
  Data.Copy Data.PPAGE, Data.POFF + p * 32, 32, VarPtr(rec)
  recOf = p
End Sub


Function PNameOf(ByVal p As Integer) As String
  Dim s As String, c As Integer
  LoadRec p
  s = ""
  For c = 24 To 31
    If rec(c) <> 32 Then s = s & Chr$(rec(c))
  Next
  PNameOf = s
End Function


Function Word(ByVal t As Integer, ByVal w As Integer, ByVal k As Integer) As String
  Dim s As String, c As Integer
  Data.Copy Data.PPAGE, Data.POFF + t + k * w, w, VarPtr(tb)
  s = ""
  For c = 0 To w - 1
    s = s & Chr$(tb(c))
  Next
  Word = RTrim$(s)
End Function


Function Count(ByVal n As Integer, ByVal one As String, ByVal more As String) As String
  If n = 1 Then Count = "1 " & one Else Count = CStr(n) & " " & more
End Function


Function Clamp(ByVal v As Integer) As Integer
  If v < 0 Then v = 0
  If v > 100 Then v = 100
  Clamp = v
End Function


Sub TextBox(ByVal nm As String)
  Panel 1, 22, 38, 9
  If Len(nm) Then Board.Text 3, 22, " " & nm & " ", C_GOLD
End Sub


Sub PrintLB(ByVal y As Integer, ByVal c As Integer)
  Dim x As Integer, j As Integer, b As Integer, s As String, m As Integer, q As Integer
  x = 3 : j = 0
  Do
    b = lb(j)
    If b = 0 Then Exit Do
    If b < 32 Then
      s = TokName(b)
      For m = 1 To Len(s)
        Board.Put x, y, Asc(Mid$(s, m, 1)), c : x = x + 1
      Next
    Else
      Board.Put x, y, b, c : x = x + 1
    End If
    j = j + 1
    If fast = 0 Then
      q = q + 1
      If (q And 1) = 0 Then
        Tick
        If Key() >= 5 Then fast = 1
      End If
    End If
  Loop
End Sub


Function LBStr() As String
  Dim s As String, j As Integer
  s = "" : j = 0
  Do While lb(j)
    If lb(j) < 32 Then s = s & TokName(lb(j)) Else s = s & Chr$(lb(j))
    j = j + 1
  Loop
  LBStr = s
End Function


Sub WaitGo()
  Dim v As Integer
  Do
    Tick
    If (frames And 16) Then Board.Put 36, 29, GfxData.T_STAR, C_GOLD Else Board.Put 36, 29, GfxData.T_BOX, 0
    v = Key()
  Loop Until v >= 5
  Blip
End Sub


Function Choose(ByVal nopt As Integer) As Integer
  Dim sel As Integer, v As Integer, t As Integer, c As Integer
  TextBox "YOU"
  Board.Text 3, 23, "WHAT DO YOU DO?", C_GOLD
  sel = 0
  Do
    For t = 0 To nopt - 1
      If t = sel Then c = C_HI Else c = C_WHITE
      If t = sel Then Board.Text 3, 25 + t * 2, ">", C_PINK Else Board.Text 3, 25 + t * 2, " ", C_WHITE
      If t = 0 Then Board.Text 5, 25, lab0, c
      If t = 1 Then Board.Text 5, 27, lab1, c
      If t = 2 Then Board.Text 5, 29, lab2, c
    Next
    v = NextKey()
    If v = 1 And sel > 0 Then sel = sel - 1 : Blip
    If v = 2 And sel < nopt - 1 Then sel = sel + 1 : Blip
  Loop Until v = 5
  Sfx.Play 0, 90, -2, 13, 10, 0
  Choose = sel
End Function


Sub Note(ByVal s As String)
  TextBox ""
  Board.Text 3, 24, s, C_MINT
  WaitGo
  Board.Rect 0, 22, 40, 9, 0, 0
End Sub


Sub Note2(ByVal s As String, ByVal s2 As String)
  TextBox ""
  Board.Text 3, 24, s, C_MINT
  Board.Text 3, 25, s2, C_MINT
  WaitGo
  Board.Rect 0, 22, 40, 9, 0, 0
End Sub


Function YesNo(ByVal q As String, ByVal a As String, ByVal b As String) As Integer
  TextBox ""
  lab0 = a : lab1 = b
  Board.Text 3, 23, q, C_GOLD
  YesNo = (Choose(2) = 0)
  Board.Rect 0, 22, 40, 9, 0, 0
End Function




' Step4(v, a, dn, up, hi): a moved by key v (dn: one less, up: one more), kept in 0 - hi
Function Step4(ByVal v As Integer, ByVal a As Integer, ByVal dn As Integer, ByVal up As Integer, ByVal hi As Integer) As Integer
  If v = dn And a > 0 Then a = a - 1
  If v = up And a < hi Then a = a + 1
  Step4 = a
End Function

' NextKey(): waits for a key (the world going on)
Function NextKey() As Integer
  Do
    Tick
    NextKey = Key()
  Loop Until NextKey
End Function

Sub NameEntry()
  Dim v As Integer, cx As Integer, cy As Integer, t As Integer, c As Integer, s As String
  Panel 4, 6, 32, 14
  Board.Text 6, 7, "YOUR NAME:", C_GOLD
  cx = 0 : cy = 0
  Do
    Board.Rect 17, 7, 10, 1, GfxData.T_BOX, 0
    Board.Text 17, 7, pName, C_WHITE
    For t = 0 To 29
      s = Mid$("ABCDEFGHIJKLMNOPQRSTUVWXYZ-<O.", t + 1, 1)
      If t = 27 Then s = "<-"
      If t = 28 Then s = "OK"
      If (t Mod 8) = cx And (t \ 8) = cy Then c = C_HI Else c = C_WHITE
      Board.Text 6 + (t Mod 8) * 3, 9 + (t \ 8) * 2, Left$(s & "   ", 3), c
    Next
    v = NextKey()
    cx = Step4(v, cx, 3, 4, 7) : cy = Step4(v, cy, 1, 2, 3)
    If cy * 8 + cx > 29 Then cx = 29 - cy * 8
    If v = 5 Then
      t = cy * 8 + cx
      Blip
      If (t < 27 Or t = 29) And Len(pName) < 8 Then pName = pName & Mid$("ABCDEFGHIJKLMNOPQRSTUVWXYZ-<O.", t + 1, 1)
      If t = 27 And Len(pName) > 0 Then pName = Left$(pName, Len(pName) - 1)
      If t = 28 And Len(pName) > 0 Then Exit Do
    End If
    If v = 6 And Len(pName) > 0 Then Exit Do
  Loop
  Board.Rect 4, 6, 32, 14, 0, 0
End Sub


Function PickFace(ByVal girl As Integer) As Integer
  Dim v As Integer, j As Integer, p As Integer
  j = Rnd(50)
  Do
    p = girl * 50 + j
    Blank
    Backdrop
    Panel 1, 1, 18, 21
    LoadRec p
    Face.Put 0, VarPtr(rec) + 8, 16, 32, 4, 0, 0
    Panel 20, 1, 19, 21
    Board.Text 22, 3, "SEOUL'S NEW", C_GOLD
    Board.Text 22, 4, "POSTIE:", C_GOLD
    Board.Text 22, 6, PNameOf(p), C_PINK
    LoadRec p
    Board.Text 22, 8, "AGE " & CStr(rec(1) + 1), C_WHITE
    Board.Text 22, 9, "WAS: " & Left$(Word(Data.T_JOB, 16, rec(20)), 11), C_WHITE
    LoadRec p
    Board.Text 22, 10, Word(Data.T_TRAIT, 12, rec(4)), C_MINT
    Board.Text 22, 12, CStr(j + 1) & " OF 50", C_GREY
    Board.Text 22, 15, "O P: LOOK", C_GREY
    Board.Text 22, 16, "SPACE: THIS ONE", C_GREY
    v = NextKey()
    If v = 3 Or v = 1 Then j = (j + 49) Mod 50 : Blip
    If v = 4 Or v = 2 Then j = (j + 1) Mod 50 : Blip
  Loop Until v = 5
  Sfx.Play 0, 90, -2, 13, 10, 0
  PickFace = p
End Function






' ---------------------------------------------------------------- frames
Sub Tick()
#If NTC_ZXN Then
  Frame
#Else
  Nx.WaitFrame                                  ' (a task: the frame, the hypervisor's turns while waiting,
                                                ' the screen's registers back after another slot had it)
#End If
  Spr.Show
  Sfx.Update
  frames = (frames + 1) And &H7FFF
  FxMove
  If tune Then Music
End Sub

Sub Blank()
  Board.Clear
  Spr.HideRange 0, 128
  faceOn = -2
End Sub

' a plain backdrop for the menus: the Central Post Office's floor
Sub Backdrop()
  LoadRoom 192 + Town.TP_POST
  World.Draw VarPtr(rc)
End Sub

' ---------------------------------------------------------------- floating icons
' street icons (GfxData, palette 15): 0 letter, 1 parcel, 2 speech, 3 heart, 4 !, 5 ?, 6 stars,
' 7 coffee, 8 food, 9 arrow, 10 coin, 11 note, 12 bag, 13 ..., 14 sparkle, 15 broken heart; in a
' talk (FaceSet): 0 heart, 1 star, 2 note, 7 sparkle, 9 broken heart
Sub Fx(ByVal x As Integer, ByVal y As Integer, ByVal p As Integer)
  Dim j As Integer
  For j = 0 To NFX - 1
    If fxT(j) = 0 Then
      fxX(j) = x : fxY(j) = y : fxT(j) = 50 : fxP(j) = p
      Exit Sub
    End If
  Next
End Sub

Sub Burst(ByVal p As Integer)
  Dim j As Integer
  For j = 0 To 3
    Fx 170 + Rnd(90), 120 + Rnd(40), p
  Next
End Sub

' ---------------------------------------------------------------- sounds
Sub Music()
  Dim t As Integer, p As Integer
  If frames Mod 12 Then Exit Sub
  t = beat Mod 16
  beat = beat + 1
  p = Val(Mid$("119134150119134159179159119134150119106119134159", t * 3 + 1, 3))
  Sfx.Play 0, p, 0, 11, 10, 0
  If t Mod 4 = 0 Then Sfx.Play 1, p * 2, 0, 12, 20, 0
End Sub

Sub Ding()
  Sfx.Play 0, 50, 0, 13, 10, 0
  WaitF 8
  Sfx.Play 1, 64, 0, 12, 18, 0
End Sub

Sub Honk()
  Sfx.Play 2, 400, 0, 14, 12, 0
End Sub

' ---------------------------------------------------------------- talking: the faces' sprites in
Sub TalkOn()
  If talking Then Exit Sub
  talking = 1
  Spr.HideRange 0, 128
  Spr.Show
  FaceSet.Load Data.FACEPAGE
  fxBase = FaceSet.S_ICON : fxFl = 0
  FxClear
  faceOn = -2
End Sub

' out of a talk: the street's sprites back, the words over the street put back
Sub TalkOff()
  If talking = 0 Then Exit Sub
  talking = 0
  Spr.HideRange 0, 128
  Spr.Show
  GameSet.Load Data.GAMEPAGE
  SlotPal 255, 0                                  ' (the people's colours again)
  fxBase = GfxData.S_ICON : fxFl = Spr.Pal * 15
  FxClear
  RoomText
  Hud   ' GAME:
End Sub

' ---------------------------------------------------------------- the cast
Sub LookOf(ByVal c As Integer, ByVal p As Integer)
  Dim t As Integer
  LoadRec p
  For t = 0 To 8
    cLook(c * 9 + t) = rec(8 + t)
  Next
End Sub

' them: person p (one of the hundred)
Sub ThemIs(ByVal p As Integer)
  themP = p : hatV = 0
  cst(K_THEM) = p
  LookOf K_THEM, p
  If met(p) = 0 Then met(p) = 1
End Sub

' them: somebody without a name (a shopkeeper, a neighbour): a face made from seed sd; kind: 1 a
' man, 2 a woman, 3 an ajumma, 4 an old man
Sub ThemNobody(ByVal nm As String, ByVal sd As Integer, ByVal kind As Integer)
  themP = -1 : cst(K_THEM) = -1 : themName = nm
  MakeLook sd, kind
End Sub

' MakeLook sd, kind: a nameless person's look (cLook(9-17), them's) from seed sd; an ajumma wears a
' sun visor (hatV: Face.Put's hat 2), as her sprite does
Sub MakeLook(ByVal sd As Integer, ByVal kind As Integer)
  Dim girl As Integer, q As Integer
  hatV = (kind = 3) And 2
  girl = (kind = 2 Or kind = 3)
  ' part k: (s \ divisor) mod how many (01 03 05 07 11 13 17 19 / 2 3 7 4 6 3 6 1 7), s = Abs(sd * 37 + 11)
  For q = 0 To 8
    cLook(9 + q) = Part(sd, Val(Mid$("010305071113171719", q * 2 + 1, 2)), Val(Mid$("237463617", q + 1, 1)))
  Next
  If girl Then cLook(11) = Part(sd, 5, 8) Else cLook(11) = cLook(11) + 8
  cLook(13) = cLook(13) + 2
  If girl Then cLook(13) = Part(sd, 11, 2)
  If kind >= 3 Then cLook(12) = 6
  If kind = 4 Then cLook(16) = 6
End Sub

' Part(sd, d, m): ((Abs(sd * 37 + 11)) \ d) Mod m - a face part from a seed, in 24 bits (sd * 37 is
' past an Integer for most seeds, and NTC's Long arithmetic is 900 bytes of library)
Function Part(ByVal sd As Integer, ByVal d As Integer, ByVal m As Integer) As Integer
#asm
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)              ; DE = sd
            pop hl
            ld a, (hl)
            ld (pt_d + 1), a
            pop hl
            ld a, (hl)
            ld (pt_m + 1), a
            xor a
            bit 7, d
            jr z, pt_p
            ld a, e                 ; sd < 0: Abs(sd * 37 + 11) = -sd * 37 - 11
            cpl
            ld e, a
            ld a, d
            cpl
            ld d, a
            inc de
            ld a, 1
pt_p:
            ld (pt_n + 1), a
            ld h, d
            ld l, e
            ld c, 0                 ; C:HL = sd, then * 8 + sd, * 4 + sd (= * 37)
            add hl, hl
            rl c
            add hl, hl
            rl c
            add hl, hl
            rl c
            add hl, de
            ld a, c
            adc a, 0
            add hl, hl
            rla
            add hl, hl
            rla
            add hl, de
            adc a, 0
            ld de, 11
pt_n:
            ld b, 0
            inc b
            dec b
            jr nz, pt_sub
            add hl, de              ; + 11
            adc a, 0
            jr pt_ok
pt_sub:
            and a                   ; - 11
            sbc hl, de
            sbc a, 0
pt_ok:
            ld e, a                 ; E:HL = s
pt_d:
            ld c, 0
            ld b, 24
            xor a
pt_l1:
            add hl, hl              ; E:HL / C: the quotient in E:HL
            rl e
            rla
            cp c
            jr c, pt_s1
            sub c
            inc l
pt_s1:
            djnz pt_l1
pt_m:
            ld c, 0
            ld b, 24
            xor a
pt_l2:
            add hl, hl              ; E:HL mod C: the remainder in A
            rl e
            rla
            cp c
            jr c, pt_s2
            sub c
pt_s2:
            djnz pt_l2
            pop hl
            ld (hl), a
            inc hl
            ld (hl), 0
#endasm
End Function

' cast member c's face, big, on the right (mouth mo, -1 their own); c -1: none
Sub ShowFace(ByVal c As Integer, ByVal mo As Integer)
  If c < 0 Then
    Face.Hide 0
  Else
    Face.Put 0, VarPtr(cLook) + c * 9, 160, 44, 4, mo, hatV And (c = K_THEM)
  End If
  faceOn = c
End Sub

' a token's name: 1 you, 2 them, 3 the colleague, 4 the place, 5 the boss, 6 the district,
' 7 the item, 11 who it's from, 12 an address
Function TokName(ByVal b As Integer) As String
  Select Case b
    Case 1
      TokName = pName
    Case 2
      TokName = CName(K_THEM)
    Case 3
      TokName = CName(K_X)
    Case 4
      TokName = placeS
    Case 5
      TokName = CName(K_BOSS)
    Case 6
      TokName = distS
    Case 7
      TokName = itemS
    Case 11
      TokName = tokT
    Case Else
      TokName = tokH
  End Select
End Function

Function CName(ByVal c As Integer) As String
  If c < 0 Then
    CName = ""
  ElseIf c = K_YOU Then
    CName = pName
  ElseIf cst(c) < 0 Then
    CName = themName
  Else
    CName = PNameOf(cst(c))
  End If
End Function

' ---------------------------------------------------------------- playing a scene
' scene id; a: who speaks first (cast, -1 the narrator)
' the scene's byte at i, -128 to 127
Function SByte(ByVal i As Integer) As Integer
  SByte = sb(i)
  If SByte > 127 Then SByte = SByte - 256
End Function

Sub Play(ByVal id As Integer, ByVal a As Integer)
  Dim pc As Integer, op As Integer, ln As Integer, src As Integer, v As Integer, nopt As Integer, c As Integer, t As Integer
  TalkOn
  spk = a : pick = 0 : mood = -1
  ' whoever you're with is there from the start (a scene can open with the narrator)
  If a = K_THEM And faceOn <> K_THEM Then ShowFace K_THEM, -1
  ln = id * 5
  Data.Copy Data.DIRPAGE + ln \ 8192, ln And 8191, 5, VarPtr(de8)
  ln = de8(3) + de8(4) * 256
  If ln = 0 Then Exit Sub
  Data.Copy de8(0), de8(1) + de8(2) * 256, ln, VarPtr(sb)
  If faceOn <> spk Then ShowFace spk, -1
  pc = 0
  Do
    op = sb(pc)
    Select Case op
      Case Data.OP_END
        Exit Do
      Case Data.OP_SAY, Data.OP_NARR
        If op = Data.OP_SAY And spk >= 0 Then
          TextBox CName(spk) : c = C_WHITE
        Else
          TextBox "" : c = C_MINT
        End If
        src = VarPtr(sb) + pc + 1
        fast = 0 : t = 0
        Do
          src = Data.Expand(src, VarPtr(lb))
          PrintLB 24 + t, c
          t = t + 1
        Loop Until Data.Term() = 0
        pc = src - VarPtr(sb)
        WaitGo
      Case Data.OP_WHO
        v = sb(pc + 1)
        spk = -1
        If v < 4 Then spk = v            ' K_YOU, K_THEM, K_BOSS, K_X
        If faceOn <> spk Then ShowFace spk, -1
        pc = pc + 2
      Case Data.OP_MOOD
        mood = sb(pc + 1)
        If spk >= 0 Then ShowFace spk, mood
        pc = pc + 2
      Case Data.OP_ICON
        Burst sb(pc + 1)
        If sb(pc + 1) = 9 Then
          Sfx.Play 1, 300, 20, 12, 20, 0
        Else
          Sfx.Play 1, 80, -3, 12, 12, 0
        End If
        pc = pc + 2
      Case Data.OP_AFF
        v = SByte(pc + 1)
        Feel v   ' GAME:
        If themP >= 0 Then
          If v > 0 Then Fx 200, 120, 0 Else Fx 200, 120, 9
        End If
        pc = pc + 2
      Case Data.OP_STAT
        Stat sb(pc + 1), SByte(pc + 2)   ' GAME:
        pc = pc + 3
      Case Data.OP_FLAG
        pc = pc + 2
      Case Data.OP_MONEY
        v = SByte(pc + 1)
        If money + v * 10 < 0 Then broke = 1 : Exit Do   ' GAME:
        money = money + v * 10   ' GAME:
        If v < 0 Then Kerching
        pc = pc + 3
      Case Data.OP_CHOICE
        nopt = sb(pc + 1)
        src = VarPtr(sb) + pc + 2
        For t = 0 To nopt - 1
          src = Data.Expand(src, VarPtr(lb))
          txt = LBStr()
          If t = 0 Then lab0 = txt
          If t = 1 Then lab1 = txt
          If t = 2 Then lab2 = txt
        Next
        pc = src - VarPtr(sb)
        c = Choose(nopt)
        pick = c + 1
        pc = sb(pc + c * 2) + sb(pc + c * 2 + 1) * 256
      Case Data.OP_GOTO
        pc = sb(pc + 1) + sb(pc + 2) * 256
      Case Else
        Exit Do
    End Select
  Loop
  Board.Rect 0, 22, 40, 10, 0, 0
End Sub

' a scene, then back to the street
Sub Talk(ByVal id As Integer, ByVal a As Integer)
  broke = 0
  Play id, a
  If broke Then broke = 0 : Play Data.TH_NOMONEY, K_YOU
  Face.Hide 0
  TalkOff
End Sub

' ---------------------------------------------------------------- people about town
' the key for where they are: a street (0-191), the ground floor of shop s (256 + s), or -5 (here
' only while you are: the upper floors' workers)
Function HereKey() As Integer
#asm
            ld hl, ({inShop})
            bit 7, h
            jr z, hk_in
            ld hl, ({room})         ; a street
            jr hk_o
hk_in:
            ld a, ({floor})
            cp 2
            jr c, hk_g
            ld hl, -5               ; upstairs
            jr hk_o
hk_g:
            inc h                   ; 256 + the shop
hk_o:
            ex de, hl
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function

' a free slot (or one far away to take over): -1 none
Function NewNpc() As Integer
#asm
            ld hl, ({inShop})     ; HereKey: a street, 256 + the shop, -5 upstairs
            bit 7, h
            jr z, nw_in
            ld hl, ({room})
            jr nw_h
nw_in:
            ld a, ({floor})
            cp 2
            jr c, nw_g
            ld hl, -5
            jr nw_h
nw_g:
            inc h
nw_h:
            ld a, l
            ld (nw_c1 + 1), a
            ld a, h
            ld (nw_c2 + 1), a
            ld hl, {nRoom}          ; a free slot
            ld bc, #0A00
nw_l1:
            ld a, (hl)
            inc hl
            and (hl)
            inc hl
            inc a
            jr z, nw_hit            ; -1
            inc c
            djnz nw_l1
            ld hl, {nRoom}          ; else one somewhere else that isn't in a shop
            ld bc, #0A00
nw_l2:
            ld e, (hl)
            inc hl
            ld d, (hl)
            inc hl
            ld a, d
            or a
            jr z, nw_lt
            bit 7, a
            jr z, nw_nx             ; 256 or more: in a shop
nw_lt:
            ld a, e
nw_c1:
            cp 0
            jr nz, nw_hit
            ld a, d
nw_c2:
            cp 0
            jr nz, nw_hit
nw_nx:
            inc c
            djnz nw_l2
            ld c, 255
nw_hit:
            ld e, c
            ld d, 0
            ld a, c
            inc a
            jr nz, nw_o
            dec d
nw_o:
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function

' person j's looks: a stranger
Sub NpcLooks(ByVal j As Integer)
  nwho(j) = -1 : nicon(j) = 255
  nkind(j) = 1 + Rnd(4) : npal(j) = Rnd(256)        ' (npal: the seed of their look - ThemNobody)
  MakeLook npal(j), nkind(j)
  SlotPal j, VarPtr(cLook) + 9
End Sub

' person j is p (one of the hundred)
Sub SetWho(ByVal j As Integer, ByVal p As Integer)
  LoadRec p
  nwho(j) = p : nkind(j) = 1 + rec(0)
  SlotPal j, VarPtr(rec) + 8
End Sub

' where p is at minute t (their days: tools/city.py): the shop they're in (their own building:
' at home), -1 out of town. Their record (128 bytes, 64 to a page): 3 kinds of day ((p + day) mod 3),
' 19 half hours from 9:00, 2 bytes each
Function WhereAt(ByVal p As Integer, ByVal t As Integer) As Integer
#asm
            pop hl
            ld a, (hl)
            ld (wa_p + 1), a
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ex de, hl
            ld de, 540
            or a
            sbc hl, de
            ld b, 0
            jr c, wa_h
            ld de, 30
wa_d:
            or a
            sbc hl, de
            jr c, wa_h
            inc b
            ld a, b
            cp 18
            jr nz, wa_d
wa_h:
            ld a, ({day})
wa_p:
            add a, 0
wa_m:
            sub 3
            jr nc, wa_m
            add a, 4
            ld c, a                 ; the kind of day + 1
            ld a, b
            add a, a
wa_k:
            dec c
            jr z, wa_o
            add a, 38
            jr wa_k
wa_o:
            ld e, a                 ; where in the record
            ld a, (wa_p + 1)
            ld c, a
            and 63
            srl a                   ; (p And 63) * 128: the high byte, and its low bit in carry
            ld h, a
            ld a, 0
            rra
            or e
            ld l, a
            ld a, h
            or #C0                  ; (OR clears carry: only after the RRA)
            ld h, a
            ld a, c
            rlca
            rlca
            and 3
            ld e, a
            ld a, ({schedPg})
            add a, e
            ld e, a
    IFNDEF NTC_ZXN
            ld d, #BF               ; (task: the page from the page table)
            ld a, (de)
            ld e, a
    ENDIF
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
            out (c), e
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld a, 10
            out (c), a              ; bank 5 back in slot 6
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function

' Seen(p, h): p is at h (HereKey) already, or is you, the boss or X (they keep to the story): 1
Function Seen(ByVal p As Integer, ByVal h As Integer) As Integer
#asm
            pop hl
            ld c, (hl)
            inc hl
            ld b, (hl)              ; BC: p
            pop hl
            ld a, (hl)
            ld (se_hl + 1), a
            inc hl
            ld a, (hl)
            ld (se_hh + 1), a
            ld a, 1
            ld hl, ({cst})            ; you (you're one of the hundred)
            or a
            sbc hl, bc
            jr z, se_out
            ld hl, ({cst} + 4)
            or a
            sbc hl, bc
            jr z, se_out
            ld hl, ({cst} + 6)
            or a
            sbc hl, bc
            jr z, se_out
            ld hl, {nRoom}
            ld a, 10
se_lp:
            ld (se_n + 1), a
            ld e, (hl)
            inc hl
            ld d, (hl)
            inc hl
            ld a, e
se_hl:
            cp 0
            jr nz, se_n
            ld a, d
se_hh:
            cp 0
            jr nz, se_n
            ld (se_sv + 1), hl
            ld de, {nwho} - {nRoom} - 2
            add hl, de
            ld a, (hl)
            cp c
            jr nz, se_sv
            inc hl
            ld a, (hl)
            cp b
            ld a, 1
            jr z, se_out
se_sv:
            ld hl, 0
se_n:
            ld a, 0
            dec a
            jr nz, se_lp
se_out:
            pop hl
            ld (hl), a
            inc hl
            ld (hl), 0
#endasm
End Function

' DoorOf(s): which of this street's doors is shop s's (-1 none)
Function DoorOf(ByVal s As Integer) As Integer
#asm
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld hl, {rc} + 195
            ld b, (hl)
            ld c, 0
            inc hl
            inc hl
do_lp:
            ld a, b
            or a
            jr z, do_none
            ld a, (hl)
            cp e
            jr nz, do_nx
            inc hl
            ld a, (hl)
            dec hl
            cp d
            jr z, do_hit
do_nx:
            inc hl
            inc hl
            inc hl
            inc hl
            inc c
            dec b
            jr do_lp
do_none:
            ld c, 255
do_hit:
            ld e, c
            ld d, 0
            inc c
            jr nz, do_out
            dec d
do_out:
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function

' the ones due here now: in this shop, sitting down (walk: coming in at the door), or in the first
' ten minutes of a half hour, on their way to a door in this street; how many came
Function Gather(ByVal walk As Integer) As Integer
  Dim p As Integer, d As Integer, t As Integer, j As Integer, c As Integer
  Gather = 0
  For p = 0 To 99
    d = WhereAt(p, mins)
    t = -1
    If inShop < 0 Then
      If (mins Mod 30) < 10 And d <> WhereAt(p, mins - 30) Then t = DoorOf(d)
    ElseIf d = inShop And HomeAt(p) <> inShop Then
      t = 0
    End If
    If t >= 0 And Seen(p, HereKey()) = 0 Then
      j = NewNpc()
      If j < 0 Then Exit Function
      If inShop < 0 Then
        StreetNpc j, 1, t
      Else
        Sit j
        If walk Then npx(j) = 112 : npy(j) = 176 : nst(j) = 5
      End If
      If nRoom(j) <> -1 Then SetWho j, p : Gather = Gather + 1
    End If
  Next
End Function

' you've come into this room: who's here
Sub Arrive()
  Dim h As Integer, j As Integer, cnt As Integer, want As Integer, c As Integer, kd As Integer
  h = HereKey()
  ' the keeper's colours: their face's (Counter: the Postmaster's at the post office)
  If inShop >= 0 Then
    MakeLook inShop, ty(5)
    If sType = Town.TY_POST Then SlotPal 10, VarPtr(cLook) + 18 Else SlotPal 10, VarPtr(cLook) + 9
  End If
  shownName = -2
  slotWas = day * 64 + mins \ 30
  For j = 0 To NN - 1
    If nRoom(j) = -5 Or (nwho(j) >= 0 And nRoom(j) <> h) Then nRoom(j) = -1
  Next
  cnt = 0
  For j = 0 To NN - 1
    If nRoom(j) = h Then
      cnt = cnt + 1
      If inShop < 0 And nst(j) = 1 Then
        If RowOpen((npy(j) + 3) \ 16) = 0 Then
          c = OpenRow()
          If c >= 0 Then npy(j) = c * 16 - 3 : nty(j) = npy(j)
        End If
      End If
      If inShop >= 0 And nst(j) = 10 Then
        ' they came in before you: at the counter or sitting down
        If rc(197) < 255 And Rnd(2) = 0 Then
          PutAt j, rc(197) : nst(j) = 4 : ntm(j) = 60 + Rnd(120)
        ElseIf rc(198) < 255 Then
          PutAt j, rc(198 + Rnd(2)) : nst(j) = 6 : ntm(j) = 150 + Rnd(200)
          If rc(198 + 1) = 255 Then PutAt j, rc(198)
        Else
          nRoom(j) = -1
        End If
      End If
    End If
  Next
  If inShop < 0 Then
    Data.Copy Data.W_DISTRICTS, rc(193) * 32 + 16, 1, VarPtr(tb)
    kd = tb(0)
    want = Val(Mid$("534423224", kd + 1, 1))
    cnt = cnt + Gather(0)
    Do While cnt < want
      j = NewNpc()
      If j < 0 Then Exit Do
      StreetNpc j, 1, -1
      cnt = cnt + 1
    Loop
  ElseIf rc(198) < 255 Then
    If floor <= 1 Then cnt = cnt + Gather(0)
    want = Rnd(3)
    If floor > 1 Then want = 1 + Rnd(3)
    Do While cnt < want
      j = NewNpc()
      If j < 0 Then Exit Do
      Sit j
      If floor > 1 Then nRoom(j) = -5 : ntm(j) = 30000
      cnt = cnt + 1
    Loop
  End If
End Sub

' SlotPal j, a: the people's sprite palette row 1 + j (j 0-9 the slots, 10 the keeper) given the
' colours of the look at a (9 bytes, Face.cls's): skin, hair colour, the outfit's top and legs - so a
' walker looks like their face. j 255: every row again (after a talk: GameSet.Load put the game's back)
Sub SlotPal(ByVal j As Integer, ByVal a As Integer)
#asm
            pop hl
            ld a, (hl)
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (sp_l1 + 1), de
            ld (sp_l2 + 1), de
            ld (sp_l3 + 1), de
            cp 255
            jr nz, sp_one
            xor a
            ld e, 11
            jr sp_wr
sp_one:
            ld (sp_j + 1), a
            ld c, a
            add a, a
            add a, a
            add a, a
            sub c                   ; j * 7
            ld e, a
            ld d, 0
            ld hl, sp_tab
            add hl, de
            ex de, hl               ; DE: the row's 7 colours
sp_l1:
            ld hl, 0
            inc hl
            ld a, (hl)              ; skin 0-2
            add a, a
            ld c, a
            ld b, 0
            ld hl, sp_sk
            add hl, bc
            ldi
            ldi
sp_l2:
            ld hl, 3
            inc hl
            inc hl
            inc hl
            ld a, (hl)              ; hair colour 0-7
            and 7
            add a, a
            ld c, a
            ld b, 0
            ld hl, sp_hr
            add hl, bc
            ldi
            ldi
sp_l3:
            ld hl, 0
            ld bc, 8
            add hl, bc
            ld a, (hl)              ; outfit 0-7
            and 7
            ld c, a
            add a, a
            add a, c
            ld c, a
            ld b, 0
            ld hl, sp_of
            add hl, bc
            ldi
            ldi
            ldi
sp_j:
            ld a, 0
            ld e, 1
sp_wr:                              ; rows A .. A + E - 1 out: entries 2-8 (skin, hair, top, legs)
            ld d, a
sp_wl:
            ld a, d
            add a, a
            add a, a
            add a, a
            sub d
            ld l, a
            ld h, 0
            ld bc, sp_tab
            add hl, bc
            ld a, d
            inc a
            add a, a
            add a, a
            add a, a
            add a, a
            add a, 2
            ld (sp_ix + 1), a
            ld bc, #243B
            ld a, #43               ; the sprites' first palette (index steps on by itself)
            out (c), a
            inc b
            ld a, #20
            out (c), a
            dec b
            ld a, #40
            out (c), a
            inc b
sp_ix:
            ld a, 0
            out (c), a
            dec b
            ld a, #41
            out (c), a
            inc b
            ld a, (hl)
            out (c), a
            inc hl
            ld a, (hl)
            out (c), a
            inc hl
            ld a, (hl)
            out (c), a
            inc hl
            ld a, (hl)
            out (c), a
            inc hl
            ld a, (hl)
            out (c), a
            inc hl
            ld a, (hl)
            out (c), a
            inc hl
            ld a, (hl)
            out (c), a
            inc d
            dec e
            jr nz, sp_wl
            jr sp_end
sp_sk:      db #FA, #D6, #F6, #D1, #D1, #AD            ; skin 0-2: colour, shade
sp_hr:      db #4A, #25, #88, #64, #D1, #AC, #FD, #F8  ; hair: black, brown, caramel, blonde,
            db #F3, #EE, #7B, #33, #DB, #B6, #C5, #A1  ; pink, blue, silver, red
sp_of:      db #00, #49, #49, #F7, #EA, #26, #FF, #26, #26, #F8, #80, #21   ; outfits 0-7: top, shade, legs
            db #FF, #7B, #26, #B3, #6E, #21, #7B, #26, #26, #E5, #80, #21
sp_tab:     equ #BE00                                   ; 11 rows x 7: kept at the foot of the stack area (it never gets that deep)
sp_end:
#endasm
End Sub

' a seat in this shop (one of its people's spots)
Function Seat() As Integer
  Seat = rc(198 + Rnd(4))
  If Seat = 255 Then Seat = rc(198)
End Function

' a stranger sitting in one of this shop's seats
Sub Sit(ByVal j As Integer)
  NpcLooks j : nRoom(j) = HereKey()
  PutAt j, Seat() : nst(j) = 6 : ntm(j) = 200 + Rnd(400) : ndir(j) = Rnd(4)
End Sub

Sub PutAt(ByVal j As Integer, ByVal c As Integer)
#asm
            pop hl
            ld a, (hl)
            add a, a
            ld e, a
            ld d, 0                 ; DE: j * 2
            pop hl
            ld c, (hl)              ; C: the cell
            ld a, c
            and #F0
            sub 3                   ; y: the cell's row * 16 - 3
            ld l, a
            ld h, 0
            jr nc, pa_1
            dec h
pa_1:
            ld (pa_y + 1), hl
            ld a, c
            and #0F
            rlca
            rlca
            rlca
            rlca                    ; x: its column * 16
            ld c, a
            ld b, 0
            ld hl, {npx}
            add hl, de
            ld (hl), c
            inc hl
            ld (hl), b
            ld hl, {ntx}
            add hl, de
            ld (hl), c
            inc hl
            ld (hl), b
pa_y:
            ld bc, 0
            ld hl, {npy}
            add hl, de
            ld (hl), c
            inc hl
            ld (hl), b
            ld hl, {nty}
            add hl, de
            ld (hl), c
            inc hl
            ld (hl), b
#endasm
End Sub

' a new person in the street: walking along a pavement, from the edge or (start: 1) already here;
' t: into door t of this street (-1: maybe one on their way)
Sub StreetNpc(ByVal j As Integer, ByVal start As Integer, ByVal t As Integer)
  Dim r As Integer, d As Integer, c As Integer
  NpcLooks j
  nRoom(j) = -1
  If t >= 0 Then
    c = rc(196 + t * 4) : r = c \ 16 + 1
    If r > 11 Then Exit Sub
    If RowOpen(r) = 0 Then Exit Sub
  Else
    r = OpenRow()
    If r < 0 Then Exit Sub
    If Rnd(3) And rc(195) > 0 Then
      t = Rnd(rc(195)) : c = rc(196 + t * 4)
      If c \ 16 <> r - 1 Then t = -1
    End If
  End If
  nRoom(j) = room
  npy(j) = r * 16 - 3
  d = Rnd(2)
  If start Then npx(j) = 16 + Rnd(224) Else npx(j) = d * 272 - 16
  nty(j) = npy(j)
  If d Then ntx(j) = -24 Else ntx(j) = 264
  nst(j) = 1
  If t >= 0 Then ntx(j) = (c Mod 16) * 16 : nty(j) = (r - 1) * 16 - 2 : nst(j) = 2 : nicon(j) = t
End Sub

' OpenRow(): a row of this street people can walk all the way along: a pavement (3 or 10) if
' it's clear, else the first clear one; -1 none
Function OpenRow() As Integer
  Dim r As Integer
  OpenRow = -1
  r = 3 + Rnd(2) * 7
  If RowOpen(r) Then OpenRow = r : Exit Function
  For r = 1 To 10
    If RowOpen(r) Then OpenRow = r : Exit Function
  Next
End Function

' RowOpen(r): no solid block all the way across row r of this street
Function RowOpen(ByVal r As Integer) As Integer
#asm
            pop hl
            ld a, (hl)
            add a, a
            add a, a
            add a, a
            add a, a
            ld e, a
            ld d, 0
            ld hl, {rc}
            add hl, de
            ld b, 16
ro_lp:
            ld de, {battr}
            ld a, (hl)
            add a, e
            ld e, a
            jr nc, ro_1
            inc d
ro_1:
            ld a, (de)
            and 1                   ; Town.A_SOLID
            jr nz, ro_no
            inc hl
            djnz ro_lp
            ld a, 1
            jr ro_out
ro_no:
            xor a
ro_out:
            pop hl
            ld (hl), a
            inc hl
            ld (hl), 0
#endasm
End Function

' everyone here moves a step
Sub People()
  Dim j As Integer, h As Integer, sp As Integer, s As Integer, c As Integer
  h = HereKey()
  For j = 0 To NN - 1
    If nRoom(j) = h Or (nRoom(j) = -5 And h = -5) Then
      If nst(j) = 4 Or nst(j) = 6 Then
        ntm(j) = ntm(j) - 1
        If ntm(j) <= 0 Then
          ' (one of the hundred whose day has them here still: another seat)
          s = -2
          If nwho(j) >= 0 Then s = WhereAt(nwho(j), mins)
          If (nst(j) = 4 Or s = inShop) And rc(198) < 255 Then
            c = Seat()
            ntx(j) = (c Mod 16) * 16 : nty(j) = (c \ 16) * 16 - 3 : nst(j) = 5
          Else
            ntx(j) = 112 : nty(j) = 176 : nst(j) = 7
            If nRoom(j) = -5 Then ntm(j) = 30000 : nst(j) = 6
          End If
        End If
      Else
        StepNpc j
        If npx(j) = ntx(j) And npy(j) = nty(j) Then ArriveNpc j
      End If
    End If
  Next
  ' sometimes someone new walks in from the side
  If inShop < 0 And (frames And 255) = 0 Then
    j = NewNpc()
    If j >= 0 Then StreetNpc j, 0, -1
  End If
  ' the half hour turns: the ones due here come
  c = day * 64 + mins \ 30
  If c <> slotWas Then
    slotWas = c
    For j = 0 To NN - 1
      If nwho(j) >= 0 Then ntm(j) = 1      ' (the hundred here look at their day again)
    Next
    If inShop < 0 Or (floor <= 1 And rc(198) < 255) Then c = Gather(1)
  End If
End Sub

' one step towards where they're going (the street: across, then up into a door; inside: along
' the aisle, column 7)
Sub StepNpc(ByVal j As Integer)
#asm
            pop hl
            ld e, (hl)
            ld d, 0                 ; DE: j
            ld hl, {nyf}
            add hl, de
            ld a, (hl)
            inc a
            and 31
            ld (hl), a              ; the walking frame on
            ld hl, {ndir}
            add hl, de
            ld (sn_d1 + 1), hl
            ld (sn_d2 + 1), hl
            sla e                   ; DE: j * 2
            ld hl, {ntx}
            add hl, de
            ld c, (hl)
            inc hl
            ld b, (hl)              ; BC: ntx(j)
            ld hl, {npx}
            add hl, de
            ld (sn_x + 1), hl
            ld (sn_xs + 1), hl
            ld hl, {nty}
            add hl, de
            ld a, (hl)
            inc hl
            ld h, (hl)
            ld l, a
            ld (sn_ty + 1), hl
            ld hl, {npy}
            add hl, de
            ld (sn_yp + 1), hl
            ld e, (hl)
            inc hl
            ld d, (hl)              ; DE: y
sn_ty:
            ld hl, 0
            or a
            sbc hl, de              ; nty - y
            ld (sn_dy + 1), hl
            ld a, h
            or l
            ld (sn_yq + 1), a       ; 0: y = nty
sn_x:
            ld hl, 0
            ld e, (hl)
            inc hl
            ld d, (hl)              ; DE: x
            ld a, ({inShop} + 1)
            rla
            jr c, sn_c2             ; in the street
            ld a, (sn_yq + 1)
            or a
            jr z, sn_c2
            ld hl, 112              ; inside, off the aisle and not on their row: to the aisle
            or a
            sbc hl, de
            jr nz, sn_mx
sn_c2:
            ld h, b
            ld l, c
            or a
            sbc hl, de              ; ntx - x
            jr z, sn_c3
            ld a, ({inShop} + 1)
            rla
            jr c, sn_mx             ; the street: across
sn_yq:
            ld a, 0
            or a
            jr z, sn_mx             ; inside on their row: across
            jr sn_my0
sn_c3:
            ld a, (sn_yq + 1)
            or a
            jr z, sn_end            ; there
sn_my0:
sn_dy:
            ld hl, 0                ; nty - y: up or down
            ld bc, 1
            xor a                   ; facing 0: down
            bit 7, h
            jr z, sn_my
            ld bc, -1
            inc a                   ; 1: up
sn_my:
sn_d2:
            ld (0), a
sn_yp:
            ld hl, 0
            jr sn_add
sn_mx:
            ld bc, 1
            ld a, 2                 ; facing 2: right
            bit 7, h
            jr z, sn_mx2
            ld bc, -1
            inc a                   ; 3: left
sn_mx2:
sn_d1:
            ld (0), a
sn_xs:
            ld hl, 0
sn_add:
            ld e, (hl)
            inc hl
            ld d, (hl)
            ex de, hl
            add hl, bc
            ex de, hl
            ld (hl), d
            dec hl
            ld (hl), e
sn_end:
#endasm
End Sub

Sub ArriveNpc(ByVal j As Integer)
  Dim s As Integer, c As Integer
  Select Case nst(j)
    Case 1
      ' off the side: on into the next street (they're still there if you follow)
      nRoom(j) = -1
      If npx(j) < 0 And room Mod 16 > 0 Then nRoom(j) = room - 1 : npx(j) = 256
      If npx(j) > 240 And room Mod 16 < 15 Then nRoom(j) = room + 1 : npx(j) = -16
    Case 2
      ' in through the door: they're inside now (you can follow them)
      c = nicon(j)
      s = rc(197 + c * 4) + rc(198 + c * 4) * 256
      nicon(j) = 255
      LoadShop s
      LoadType sh(0)
      If ty(0) = 255 Then
        nRoom(j) = -1
      Else
        nRoom(j) = 256 + s : nst(j) = 10 : ntm(j) = 10 + Rnd(30)
      End If
    Case 3, 5
      If nst(j) = 3 Then nst(j) = 4 : ntm(j) = 100 + Rnd(150) Else nst(j) = 6 : ntm(j) = 200 + Rnd(300)
      ndir(j) = 1
      nicon(j) = 2
      If sType = Town.TY_CAFE Then nicon(j) = 7
      If sType = Town.TY_NOODLE Or sType = Town.TY_BBQ Or sType = Town.TY_CHICKEN Then nicon(j) = 8
      If sType = Town.TY_NORAE Then nicon(j) = 11
      If nst(j) = 6 Then nicon(j) = 13
    Case 7
      ' out of the door: onto the street
      nicon(j) = 255
      LeaveShop j
  End Select
End Sub

' person j walks out of the shop they're in, onto its street
Sub LeaveShop(ByVal j As Integer)
  Dim s As Integer
  s = nRoom(j) - 256
  If s < 0 Then nRoom(j) = -1 : Exit Sub
  LoadShop s
  nRoom(j) = sh(5)
  npx(j) = (sh(6) Mod 16) * 16 : npy(j) = (sh(6) \ 16) * 16 + 13
  nty(j) = npy(j)
  If Rnd(2) Then ntx(j) = -24 Else ntx(j) = 264
  nst(j) = 1 : ntm(j) = 3
End Sub

' a minute passes for everyone somewhere else
Sub OffStage()
  Dim j As Integer, h As Integer
  h = HereKey()
  For j = 0 To NN - 1
    If nRoom(j) >= 0 And nRoom(j) <> h Then
      ntm(j) = ntm(j) - 1
      If ntm(j) <= 0 Then
        If nRoom(j) >= 256 Then LeaveShop j Else nRoom(j) = -1
      End If
    End If
  Next
End Sub

' the person next to you (-1 none)
Function NearNpc() As Integer
#asm
            ld hl, ({inShop})     ; HereKey: a street, 256 + the shop, -5 upstairs
            bit 7, h
            jr z, nr_in
            ld hl, ({room})
            jr nr_h
nr_in:
            ld a, ({floor})
            cp 2
            jr c, nr_g
            ld hl, -5
            jr nr_h
nr_g:
            inc h
nr_h:
            ld a, l
            ld (nr_c1 + 1), a
            ld a, h
            ld (nr_c2 + 1), a
            ld c, 0
nr_lp:
            ld a, c
            add a, a
            ld e, a
            ld d, 0
            ld hl, {nRoom}
            add hl, de
            ld a, (hl)
nr_c1:
            cp 0
            jr nz, nr_nx
            inc hl
            ld a, (hl)
nr_c2:
            cp 0
            jr nz, nr_nx
            ld hl, {nst}
            ld a, c
            add a, l
            ld l, a
            adc a, h
            sub l
            ld h, a
            ld a, (hl)
            cp 10
            jr z, nr_nx             ; (in a shop you're not in)
            ld hl, {npx}
            add hl, de
            ld a, (hl)
            inc hl
            ld h, (hl)
            ld l, a
            ld de, ({px})
            or a
            sbc hl, de
            ld de, 17
            add hl, de
            ld a, h
            or a
            jr nz, nr_nx
            ld a, l
            cp 35
            jr nc, nr_nx            ; across: 18 or more away
            ld a, c
            add a, a
            ld e, a
            ld d, 0
            ld hl, {npy}
            add hl, de
            ld a, (hl)
            inc hl
            ld h, (hl)
            ld l, a
            ld de, ({py})
            or a
            sbc hl, de
            ld de, 17
            add hl, de
            ld a, h
            or a
            jr nz, nr_nx
            ld a, l
            cp 35
            jr nc, nr_nx            ; up or down: 18 or more away
            ld e, c
            ld d, 0
            jr nr_out
nr_nx:
            inc c
            ld a, c
            cp 10
            jr nz, nr_lp
            ld de, -1
nr_out:
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function

' talk to person j
Sub TalkTo(ByVal j As Integer)
  Dim p As Integer, b As Integer, ds As String
  p = nwho(j)
  ' they turn to you
  If px < npx(j) - 8 Then ndir(j) = 3
  If px > npx(j) + 8 Then ndir(j) = 2
  If py < npy(j) - 8 Then ndir(j) = 1
  If py > npy(j) + 8 Then ndir(j) = 0
  If p >= 0 Then
    ThemIs p
    For b = 0 To nBag - 1   ' GAME:
      If bDone(b) = 0 And bP(b) = p Then   ' GAME:
        ItemWords b   ' GAME:
        Talk Data.DE_HAND01 + Rnd(6), K_THEM
        Delivered b, 0   ' GAME:
        Exit Sub
      End If
    Next
    If flowers > 0 Then   ' GAME:
      flowers = flowers - 1   ' GAME:
      Talk Data.DE_GIFT, K_THEM
    Else
      Talk Data.CH_CHAT01 + Rnd(30), K_THEM
    End If
    AfterShop   ' GAME:
    Exit Sub
  End If
  ' a stranger: they mostly ignore you, but some know where people live
  ds = distS
  b = -1
  If Rnd(4) = 0 Then
    For k = 0 To nBag - 1   ' GAME:
      If bDone(k) = 0 And bP(k) >= 0 Then b = k   ' GAME:
    Next
  End If
  ' a face for them: made up, the same every time for that person on that street
  ThemNobody "", npal(j), nkind(j)
  If b >= 0 Then
    tokT = PNameOf(bP(b)) : distS = DistName(HomeDist(bP(b)))   ' GAME:
    Talk Data.ST_HINT01 + Rnd(4), K_THEM
  Else
    Talk Data.ST_STR01 + Rnd(30), K_THEM
  End If
  distS = ds
  Hud   ' GAME:
End Sub

' ---------------------------------------------------------------- cars
Sub Cars()
  Dim j As Integer, y As Integer, z As Integer
  For j = 0 To NCAR - 1
    y = 64 + cl(j) * 16
    z = (px >= 100 And px <= 132 And py + 13 >= y And py + 13 < y + 16)
    If cx(j) = -99 Or crm(j) <> room Then          ' (none, or it's in another street: a new one here)
      If Rnd(80) = 0 Then
        crm(j) = room
        cl(j) = j : cpal(j) = 12 + Rnd(3) : ck(j) = (cpal(j) = 13) And 1 : cv(j) = 2 + Rnd(2)
        cx(j) = 256 - j * 292              ' (lane 1 from the left at -36: -48 was past -40, where cars are taken off)
      End If
    ElseIf z = 0 Then
      If cl(j) Then cx(j) = cx(j) + cv(j) Else cx(j) = cx(j) - cv(j)
      ' off the side: on into the next street, waiting at its edge (follow it and it's there)
      If cx(j) < -40 Then
        cx(j) = -99
        If room Mod 16 > 0 Then cx(j) = 256 : crm(j) = room - 1
      End If
      If cx(j) > 260 Then
        cx(j) = -99
        If room Mod 16 < 15 Then cx(j) = -36 : crm(j) = room + 1
      End If
      If stun = 0 And py + 13 >= y + 2 And py + 13 < y + 15 And px + 12 > cx(j) And px + 3 < cx(j) + 32 Then
        Honk
        stun = 50
        Fx px + 32, py + 24, 6
        py = 44 + j * 48
        mins = mins + 10 : energy = Clamp(energy - 5)   ' GAME:
        If hitToday = 0 Then   ' GAME:
          hitToday = 1   ' GAME:
          DrawAll
          Talk Data.TH_HIT, K_YOU
        End If
      End If
    End If
  Next
End Sub



' ---------------------------------------------------------------- drawing the sprites
' a walker's pictures: down, up, sideways (3 each); left is right turned over
Function Dir3(ByVal d As Integer) As Integer
  If d > 2 Then d = 2
  Dir3 = d * 3
End Function

Sub DrawAll()
  Dim j As Integer, p As Integer, fl As Integer, h As Integer, b As Integer, w As Integer, x As Integer, y As Integer, best As Integer
  ' you
  If pdir = 3 Then fl = Spr.MirrorX Else fl = 0
  p = Dir3(pdir)
  If pstep Then p = p + 1 + ((pstep \ 5) And 1)
  If stun And (stun And 4) Then
    Spr.Hide SP_YOU
  Else
    Spr.Put SP_YOU, px + 32, py + 32, GfxData.S_POSTIE + p, fl Or (Spr.Pal * pPal)
  End If
  ' people
  h = HereKey()
  best = -1
  For j = 0 To NN - 1
    If (nRoom(j) = h Or (nRoom(j) = -5 And h = -5)) And nst(j) <> 10 And npx(j) > -16 And npx(j) < 256 Then
      b = GfxData.S_MAN + (nkind(j) - 1) * 9
      If ndir(j) = 3 Then fl = Spr.MirrorX Else fl = 0
      p = Dir3(ndir(j))
      If nst(j) <> 4 And nst(j) <> 6 Then p = p + 1 + ((nyf(j) \ 8) And 1)
      Spr.Put SP_NPC + j, npx(j) + 32, npy(j) + 32, b + p, fl Or (Spr.Pal * (1 + j))
      If (nst(j) = 4 Or nst(j) = 6) And nicon(j) < 255 And (frames And 64) Then
        Spr.Put SP_NICON + j, npx(j) + 32, npy(j) + 18, GfxData.S_ICON + nicon(j), Spr.Pal * 15
      ElseIf nwho(j) >= 0 And aff(nwho(j)) >= 60 And (frames And 32) Then
        Spr.Put SP_NICON + j, npx(j) + 32, npy(j) + 18, GfxData.S_ICON + 3, Spr.Pal * 15
      Else
        Spr.Hide SP_NICON + j
      End If
      If nwho(j) >= 0 And Abs(npx(j) - px) < 40 And Abs(npy(j) - py) < 40 Then best = nwho(j)
    Else
      Spr.Hide SP_NPC + j : Spr.Hide SP_NICON + j
    End If
  Next
  ' a name when one of the hundred is close
  If best <> shownName Then
    shownName = best
    Board.Rect 26, 29, 14, 1, 0, 0
    If best >= 0 Then Board.Text 26, 29, "* " & PNameOf(best), C_PINK
  End If
  ' the shopkeeper, the market's ajummas
  If inShop >= 0 And rc(196) < 255 And ty(5) > 0 Then
    Spr.Put SP_KEEP, (rc(196) Mod 16) * 16 + 32, (rc(196) \ 16) * 16 + 29, GfxData.S_MAN + (ty(5) - 1) * 9, Spr.Pal * 11
  Else
    Spr.Hide SP_KEEP
  End If
  For j = 0 To 3
    x = Val(Mid$("01041013", j * 2 + 1, 2))
    If inShop < 0 And (rc(194) And 2) <> 0 And rc(80 + x) = Town.B_MARKET_AWN Then
      Spr.Put SP_STALL + j, x * 16 + 40, 93, GfxData.S_AJUMMA, Spr.Pal * (2 + j)
    Else
      Spr.Hide SP_STALL + j
    End If
  Next
  ' cars
  For j = 0 To NCAR - 1
    b = SP_CAR + j * 2
    If cx(j) = -99 Or inShop >= 0 Or crm(j) <> room Or (rc(194) And 1) = 0 Then
      Spr.HideRange b, 2
    Else
      y = 94 + cl(j) * 16 : p = GfxData.S_CAR + ck(j) * 2 : fl = Spr.Pal * cpal(j)
      If cl(j) = 0 Then fl = fl Or Spr.MirrorX
      Spr.Put b, cx(j) + 32, y, p + 1 - cl(j), fl
      Spr.Put b + 1, cx(j) + 48, y, p + cl(j), fl
    End If
  Next
  If hasApp Then Arrow Else Spr.Hide SP_ARROW   ' GAME:
End Sub

' the map app: an arrow to the next delivery's street
Sub Arrow()
  Dim j As Integer, t As Integer, dx As Integer, dy As Integer, fl As Integer, x As Integer, y As Integer
  t = -1
  For j = nBag - 1 To 0 Step -1   ' GAME:
    If bDone(j) = 0 Then t = j   ' GAME:
  Next
  If t < 0 Or inShop >= 0 Then Spr.Hide SP_ARROW : Exit Sub
  LoadShop bShop(t)   ' GAME:
  dx = (sh(5) Mod 16) - (room Mod 16) : dy = (sh(5) \ 16) - (room \ 16)
  x = px + 32 : y = py + 32
  If dx = 0 And dy = 0 Then
    x = (sh(6) Mod 16) * 16 + 32 : y = (sh(6) \ 16) * 16 + 14 + ((frames \ 8) And 3)
    fl = 0
  ElseIf Abs(dx) >= Abs(dy) Then
    If dx > 0 Then fl = Spr.Rotate Or Spr.MirrorX : x = x + 18 Else fl = Spr.Rotate : x = x - 18
  Else
    If dy > 0 Then fl = 0 : y = y + 18 Else fl = Spr.MirrorY : y = y - 18
  End If
  If (frames And 16) Or (dx = 0 And dy = 0) Then
    Spr.Put SP_ARROW, x, y, GfxData.S_ICON + 9, fl Or (Spr.Pal * 15)
  Else
    Spr.Hide SP_ARROW
  End If
End Sub

' ---------------------------------------------------------------- the city's tables
' room r's record (a street 0-191, an inside 192 + its template)
Sub LoadRoom(ByVal r As Integer)
  Data.Copy Data.W_ROOMS + r \ 32, (r Mod 32) * 256, 256, VarPtr(rc)
End Sub

Sub LoadShop(ByVal s As Integer)
  Data.Copy Data.W_SHOPS + s \ 1024, (s Mod 1024) * 8, 8, VarPtr(sh)
End Sub

Sub LoadType(ByVal t As Integer)
  Data.Copy Data.W_TYPES, t * 64, 64, VarPtr(ty)
End Sub

' some letters of a table's record as a string (trailing spaces off)
Function TabStr(ByVal page As Integer, ByVal off As Integer, ByVal w As Integer) As String
  Dim s As String, c As Integer
  Data.Copy page, off, w, VarPtr(tb)
  s = ""
  For c = 0 To w - 1
    s = s & Chr$(tb(c))
  Next
  TabStr = RTrim$(s)
End Function

Function DistName(ByVal d As Integer) As String
  DistName = TabStr(Data.W_DISTRICTS, d * 32, 16)
End Function




' a shop's name: CHERRY CAFE, HANBIT APT 104, N SEOUL TOWER...
Function ShopName(ByVal s As Integer) As String
  Dim t As Integer, w As String
  LoadShop s
  t = sh(0)
  If sh(2) >= 128 Then
    ShopName = TabStr(Data.W_NAMES, (sh(2) - 128) * 20, 20)
    Exit Function
  End If
  w = TabStr(Data.W_WORDS, sh(2) * 8, 8)
  LoadShop s
  If t = Town.TY_APT Then
    ShopName = w & " APT " & CStr(100 + sh(3))
  ElseIf t = Town.TY_HOUSE Then
    ShopName = "HOUSE NO. " & CStr(sh(3))
  ElseIf t = Town.TY_OFFICE Then
    ShopName = w & " TOWER"
  Else
    ShopName = w & " " & TabStr(Data.W_TYPES, (t) * 64 + 16, 16)
  End If
End Function

' person p's home: tb(0-1) the building, tb(2) the floor, tb(3) the flat (read from the table
' each time: no copy of it kept in the program's memory); gives the building
Function HomeAt(ByVal p As Integer) As Integer
  Data.Copy Data.W_HOMES, p * 4, 4, VarPtr(tb)
  HomeAt = tb(0) + tb(1) * 256
End Function

Function HomeRoom(ByVal p As Integer) As Integer
  LoadShop HomeAt(p)
  HomeRoom = sh(5)
End Function

Function HomeDist(ByVal p As Integer) As Integer
  LoadShop HomeAt(p)
  HomeDist = sh(4)
End Function

' person p's address: SORA APT 112, 9F #903 (the district apart)
Function Address(ByVal s As Integer, ByVal fl As Integer, ByVal u As Integer) As String
  Dim a As String
  a = ShopName(s)
  LoadShop s
  If sh(0) = Town.TY_APT Or sh(0) = Town.TY_VILLA Then a = a & " #" & CStr(fl * 100 + u)
  Address = a
End Function

' ---------------------------------------------------------------- going places
' onto street r, standing at x, y facing d
' T: hyperspace (DEFENDER's) - out of anywhere (stuck, lost, cornered) to a free spot on a street
' somewhere in the city, at random; it costs 5 minutes
Sub Hyper()
  Dim r As Integer
  Do
    r = Rnd(192) : LoadRoom r
    px = 16 + Rnd(208) : py = 16 + Rnd(150)
  Loop Until Free(px, py)
  Sfx.Play 0, 40, 3, 13, 20, 0
  mins = mins + 5 : stun = 20
  GoStreet r, px, py, pdir
End Sub

Sub GoStreet(ByVal r As Integer, ByVal x As Integer, ByVal y As Integer, ByVal d As Integer)
  room = r : inShop = -1 : floor = 0
  px = x : py = y : pdir = d
  LoadRoom r
  distS = DistName(rc(193))
  placeS = distS
  Enter
End Sub

' into shop s (floor fl), at x, y
Sub GoInside(ByVal s As Integer, ByVal fl As Integer, ByVal x As Integer, ByVal y As Integer, ByVal d As Integer)
  Dim t As Integer
  LoadShop s
  sType = sh(0) : floors = sh(1) : streetRoom = sh(5) : doorCell = sh(6)
  inShop = s : floor = fl
  LoadType sType
  If fl <= 1 Then
    t = ty(0)
  ElseIf fl >= floors Then
    t = ty(2)
  Else
    t = ty(1)
  End If
  room = 192 + t
  px = x : py = y : pdir = d
  placeS = ShopName(s)
  LoadShop s
  distS = DistName(sh(4))
  LoadRoom room
  Enter
End Sub

' the room's picture, its words, its people
Sub Enter()
  Dim j As Integer
  FxClear
  Spr.HideRange 0, 111
  World.Draw VarPtr(rc)
  EdgeMarks
  RoomText
  Arrive
  Hud   ' GAME:
End Sub

' the street's edges you can walk off into the next street: those blocks a shade warmer
Sub EdgeMarks()
  Dim j As Integer, c As Integer
  If rc(192) <> 0 Or inShop >= 0 Then Exit Sub
  For j = 0 To 11
    If room Mod 16 > 0 Then EdgeMark j * 16
    If room Mod 16 < 15 Then EdgeMark j * 16 + 15
  Next
  For j = 0 To 15
    If room \ 16 > 0 Then EdgeMark j
    If room \ 16 < 11 Then EdgeMark 176 + j
  Next
End Sub

Sub EdgeMark(ByVal c As Integer)
  If battr(rc(c)) And (Town.A_SOLID Or Town.A_WATER) Then Exit Sub
  L2.Tint (c Mod 16) * 16, (c \ 16) * 16, 16, 16
End Sub

' the names on the signs, the flats' numbers, where you are
Sub RoomText()
  Dim j As Integer, c As Integer, s As Integer, w As Integer, x As Integer, y As Integer, t As String
  Board.Rect 0, 3, 40, 26, 0, 0
  If rc(192) = 0 Then
    For j = 0 To rc(195) - 1
      c = rc(196 + j * 4) : s = rc(197 + j * 4) + rc(198 + j * 4) * 256 : w = rc(199 + j * 4) \ 16
      If w > 0 Then
        LoadShop s
        If sh(0) = Town.TY_APT Or sh(0) = Town.TY_OFFICE Then
          t = CStr(100 + sh(3))
        ElseIf sh(0) = Town.TY_VILLA Or sh(0) = Town.TY_HOUSE Then
          t = CStr(sh(3))
        Else
          t = TabStr(Data.W_TYPES, sh(0) * 64 + 8, 6)
        End If
        If Len(t) > w * 2 Then t = Left$(t, w * 2)
        x = 4 + (rc(199 + j * 4) And 15) * 2 + (w * 2 - Len(t)) \ 2
        y = 4 + (c \ 16 - 1) * 2 + 1
        Board.Text x, y, t, C_WHITE
      End If
    Next
  Else
    For j = 0 To 3
      c = rc(203 + j)
      If c < 255 Then Board.Text 3 + (c Mod 16) * 2, 5, CStr(floor * 100 + j + 1), C_GOLD
    Next
  End If
End Sub

Function Clock() As String
  Clock = Right$("0" & CStr(mins \ 60), 2) & ":" & Right$("0" & CStr(mins Mod 60), 2)
End Function

' ---------------------------------------------------------------- the map of blocks
Function CellAt(ByVal x As Integer, ByVal y As Integer) As Integer
#asm
            pop hl
            ld c, (hl)
            inc hl
            ld b, (hl)              ; BC: x
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)              ; DE: y
            ld a, b
            or d
            jr nz, ca_no            ; off the screen (below 0, or over 255)
            ld a, e
            cp 192
            jr nc, ca_no
            and #F0
            ld e, a
            ld a, c
            rrca
            rrca
            rrca
            rrca
            and #0F
            or e
            ld e, a                 ; (y \ 16) * 16 + x \ 16
            jr ca_out
ca_no:
            ld de, -1
ca_out:
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function

Function AttrAt(ByVal x As Integer, ByVal y As Integer) As Integer
  Dim c As Integer
  c = CellAt(x, y)
  If c < 0 Then AttrAt = 0 Else AttrAt = battr(rc(c))
End Function

' can your feet (a box at the bottom of a 16 x 16 sprite at x, y) stand there?
' Free(x, y): you can stand at x, y - none of the feet's four corners on a solid block
Function Free(ByVal x As Integer, ByVal y As Integer) As Integer
#asm
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (fr_x + 1), de
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (fr_y + 1), de
            ld hl, fr_off           ; the feet's four corners
            ld b, 4
fr_lp:
            ld (fr_p + 1), hl
            ld c, (hl)
            inc hl
            ld a, (hl)
            ld (fr_dy + 1), a
fr_x:
            ld hl, 0
            ld e, c
            ld d, 0
            add hl, de
            ld a, h
            or a
            jr nz, fr_nx            ; off the screen: nothing in the way
            ld c, l
fr_y:
            ld hl, 0
fr_dy:
            ld e, 0
            add hl, de
            ld a, h
            or a
            jr nz, fr_nx
            ld a, l
            cp 192
            jr nc, fr_nx
            and #F0
            ld l, a
            ld a, c
            rrca
            rrca
            rrca
            rrca
            and #0F
            or l                    ; the cell
            ld e, a
            ld hl, {rc}
            add hl, de
            ld e, (hl)
            ld hl, {battr}
            add hl, de
            bit 0, (hl)             ; Town.A_SOLID
            jr nz, fr_no
fr_nx:
fr_p:
            ld hl, 0
            inc hl
            inc hl
            djnz fr_lp
            ld a, 1
            jr fr_out
fr_no:
            xor a
fr_out:
            pop hl
            ld (hl), a
            inc hl
            ld (hl), 0
            jr fr_end
fr_off:     db 3, 11, 12, 11, 3, 15, 12, 15
fr_end:
#endasm
End Function

' the block in front of you (a cell number, or -1)
Function Facing() As Integer
  Dim x As Integer, y As Integer
  x = px + 8 : y = py + 12
  If pdir = 0 Then y = y + 12
  If pdir = 1 Then y = y - 12
  If pdir = 2 Then x = x + 12
  If pdir = 3 Then x = x - 12
  Facing = CellAt(x, y)
End Function

' ---------------------------------------------------------------- the round: a day's walking
Sub Round()
  Dim v As Integer
  quit = 0
  Do
    Tick
    Clockwork   ' GAME:
    If stun > 0 Then
      stun = stun - 1
    Else
      Walk
    End If
    People
    If rc(194) And 1 Then Cars
    DrawAll
    v = Key()
    If v = 5 And stun = 0 Then Act
    If v = 6 Then BagScreen 0   ' GAME:
    If Keys.Down(Keys.KeyT) And stun = 0 Then Hyper
    If mins >= T_END Then quit = 1   ' GAME:
  Loop Until quit
End Sub

' ---------------------------------------------------------------- walking
Sub Walk()
  Dim j As Integer, mx As Integer, my As Integer, sp As Integer, a As Integer, nx2 As Integer, ny2 As Integer
  j = Keys.Joystick(0)
  mx = 0 : my = 0
  If Keys.Down(Keys.KeyO) Or (j And Keys.JoyLeft) Then mx = -1
  If Keys.Down(Keys.KeyP) Or (j And Keys.JoyRight) Then mx = 1
  If Keys.Down(Keys.KeyQ) Or (j And Keys.JoyUp) Then my = -1
  If Keys.Down(Keys.KeyA) Or (j And Keys.JoyDown) Then my = 1
  If mx = 0 And my = 0 Then pstep = 0 : Exit Sub
  If mx < 0 Then pdir = 3
  If mx > 0 Then pdir = 2
  If my < 0 Then pdir = 1
  If my > 0 Then pdir = 0
  sp = 2
  If speedT > 0 Then sp = 3   ' GAME:
  If energy < 10 Then sp = 1   ' GAME:
  pstep = pstep + 1
  a = Free(px, py) = 0                            ' stuck in something (a car threw you there): walk out
  nx2 = px + mx * sp
  If a Or Free(nx2, py) Then px = nx2
  ny2 = py + my * sp
  If a Or Free(px, ny2) Then py = ny2
  ' off the edge: the next street
  If rc(192) = 0 Then
    If px < -6 Then Flip -1, 0 : Exit Sub
    If px > 246 Then Flip 1, 0 : Exit Sub
    If py < -10 Then Flip 0, -1 : Exit Sub
    If py > 180 Then Flip 0, 1 : Exit Sub
  Else
    If px < 0 Then px = 0
    If px > 240 Then px = 240
    If py < 0 Then py = 0
  End If
  ' walked into a door, the stairs down, the way out
  a = AttrAt(px + 8, py + 12)
  If a And (Town.A_DOOR Or Town.A_STAIRS) Then Door CellAt(px + 8, py + 12)
End Sub

' the next street over (dx, dy), if there is one and you can stand where you'd be
Sub Flip(ByVal dx As Integer, ByVal dy As Integer)
  Dim x As Integer, y As Integer, r As Integer, ox As Integer, oy As Integer, orr As Integer
  x = room Mod 16 + dx : y = room \ 16 + dy
  ox = px : oy = py
  If x < 0 Or x > 15 Or y < 0 Or y > 11 Then Unflip : Exit Sub
  r = y * 16 + x
  If dx < 0 Then px = 240
  If dx > 0 Then px = 0
  If dy < 0 Then py = 176
  If dy > 0 Then py = -4
  orr = room
  LoadRoom r
  If Free(px, py) = 0 Then
    LoadRoom orr
    px = ox : py = oy
    Unflip
    Exit Sub
  End If
  GoStreet r, px, py, pdir
End Sub

' the edge of town (or a wall): back a step
Sub Unflip()
  If px < 0 Then px = 0
  If px > 240 Then px = 240
  If py < -4 Then py = -4
  If py > 176 Then py = 176
End Sub

' a door at cell c: the street's doors (shops, houses, the subway) and the inside's way out
Sub Door(ByVal c As Integer)
  Dim j As Integer, s As Integer
  If rc(192) Then
    ' the way out (only on the ground floor)
    If doorCell >= 176 Then
      GoStreet streetRoom, (doorCell Mod 16) * 16, 156, 1
    Else
      GoStreet streetRoom, (doorCell Mod 16) * 16, (doorCell \ 16) * 16 + 16, 0
    End If
    Exit Sub
  End If
  s = -1
  For j = 0 To rc(195) - 1
    If rc(196 + j * 4) = c Then s = rc(197 + j * 4) + rc(198 + j * 4) * 256
  Next
  If s < 0 Then py = py + 4 : Exit Sub
  LoadShop s
  If sh(0) = Town.TY_HOUSE Then
    py = (c \ 16) * 16 + 16 : pdir = 1
    Knock s, 1, 1   ' GAME:
    Exit Sub
  End If
  Sfx.Play 0, 200, -6, 10, 8, 0
  GoInside s, 1, 112, 160, 1
  If sh(0) = Town.TY_APT Then
    If BagFor(s, -1) >= 0 And Rnd(2) = 0 Then   ' GAME:
      ThemNobody "GUARD", s, 4
      Talk Data.SH_LOBBY, K_THEM
    End If
  End If
End Sub

' ---------------------------------------------------------------- Space: whatever's in front of you
Sub Act()
  Dim c As Integer, a As Integer, b As Integer, j As Integer
  ' someone to talk to?
  j = NearNpc()
  If j >= 0 Then TalkTo j : Exit Sub
  c = Facing()
  If c < 0 Then Exit Sub
  b = rc(c) : a = battr(b)
  If rc(192) = 0 Then
    If b = Town.B_MARKET_AWN Then Stall : Exit Sub
    If b = Town.B_VENDING Then Talk Data.TH_VENDING, -1 : Exit Sub
    If b = Town.B_POSTBOX Then Talk Data.TH_POSTBOX, -1 : Exit Sub
    Exit Sub
  End If
  If b = Town.B_MAILBOXES Then Mailbox : Exit Sub   ' GAME:
  If b = Town.B_TICKETS Then Subway : Exit Sub
  If b = Town.B_BINOCS Then Talk Data.TH_BINOCS, -1 : Exit Sub
  If b = Town.B_EXHIBIT Then Talk Data.TH_EXHIBIT, -1 : Exit Sub
  If b = Town.B_APTDOOR Then
    For j = 0 To 3
      If rc(203 + j) = c Then Knock inShop, floor, j + 1   ' GAME:
    Next
    Exit Sub
  End If
  If a And Town.A_LIFT Then Lift : Exit Sub
  If a And Town.A_COUNTER Then Counter : Exit Sub   ' GAME:
End Sub

' a market stall outside
Sub Stall()
  ThemNobody "AJUMMA", room * 3 + px \ 16, 3
  If distS = "NORYANGJIN" Then Talk Data.SH_STALL, K_THEM Else Talk Data.SH_MARKET, K_THEM
  Hud   ' GAME:
End Sub

' the lift (or the stairs): a floor
Sub Lift()
  Dim v As Integer, fl As Integer
  If floors <= 1 Then Exit Sub
  fl = floor
  Panel 12, 8, 16, 7
  Board.Text 14, 9, "WHICH FLOOR?", C_GOLD
  Board.Text 14, 13, "Q A  SPACE", C_GREY
  Do
    Board.Rect 14, 11, 12, 1, GfxData.T_BOX, 0
    Board.Text 17, 11, "< " & CStr(fl) & "F >", C_HI
    v = NextKey()
    If (v = 1 Or v = 4) And fl < floors Then fl = fl + 1 : Blip
    If (v = 2 Or v = 3) And fl > 1 Then fl = fl - 1 : Blip
  Loop Until v >= 5
  Board.Rect 12, 8, 16, 7, 0, 0
  If v = 6 Or fl = floor Then RoomText : Exit Sub
  ' the ride (a minute; the stairs a minute a floor)
  If rc(rc(202)) = Town.B_STAIRS_UP Then
    mins = mins + Abs(fl - floor)
    energy = Clamp(energy - Abs(fl - floor))   ' GAME:
    If Rnd(4) = 0 Then Talk Data.TH_STAIRS, K_YOU
  Else
    mins = mins + 1
    If Rnd(6) = 0 Then Talk Data.TH_LIFT, K_YOU
    Ding
  End If
  GoInside inShop, fl, (rc(202) Mod 16) * 16, 32, 0
End Sub

' ---------------------------------------------------------------- the subway
Sub Subway()
  Dim v As Integer, sel As Integer, j As Integer, here As Integer, x As Integer, y As Integer, s As Integer, d As Integer
  here = -1
  For j = 0 To Town.NSTATION - 1
    Data.Copy Data.W_STATIONS, j * 32, 4, VarPtr(tb)
    If tb(0) + tb(1) * 256 = inShop Then here = j
  Next
  Blank
  L2.Rect 0, 0, 256, 192, 0
  Board.Text 2, 0, "THE SUBWAY: WHERE TO? W1,400", C_GOLD
  For j = 0 To Town.NSTATION - 1
    Board.Text 4, j + 1, TabStr(Data.W_STATIONS, j * 32 + 16, 16), C_WHITE
    Board.Text 22, j + 1, "LINE " & TabStr(Data.W_STATIONS, j * 32 + 4, 6), C_MINT
  Next
  sel = here
  If sel < 0 Then sel = 0
  Do
    Board.Text 2, sel + 1, ">", C_PINK
    v = NextKey()
    Board.Text 2, sel + 1, " ", C_PINK
    If v = 1 And sel > 0 Then sel = sel - 1 : Blip
    If v = 2 And sel < Town.NSTATION - 1 Then sel = sel + 1 : Blip
  Loop Until v >= 5
  Board.Clear
  If v = 6 Or sel = here Then Enter : Exit Sub
  If money < 14 Then Talk Data.TH_NOMONEY, K_YOU : Enter : Exit Sub   ' GAME:
  money = money - 14   ' GAME:
  Data.Copy Data.W_STATIONS, sel * 32, 4, VarPtr(tb)
  s = tb(0) + tb(1) * 256
  LoadShop inShop
  x = sh(5)
  LoadShop s
  d = Abs(sh(5) Mod 16 - x Mod 16) + Abs(sh(5) \ 16 - x \ 16)
  mins = mins + 4 + d * 2
  placeS = TabStr(Data.W_STATIONS, sel * 32 + 16, 16)
  If Rnd(3) = 0 Then
    ThemNobody "", 0, 1
    Talk Data.TH_TRAIN, -1
  End If
  Sfx.Play 0, 90, 1, 12, 30, 0
  GoInside s, 1, 112, 48, 0
End Sub

' the map of the whole town: a dot a block; Q A O P look round
Sub MapScreen()
  Dim r As Integer, v As Integer, mx As Integer, my As Integer, d As Integer, j As Integer, sx As Integer
  Board.Clear
  Spr.HideRange 0, 128
  L2.Rect 0, 0, 256, 192, 0
  Data.Copy Data.W_MINI, 0, 256, VarPtr(sb)
  For r = 0 To 191
    LoadRoom r
    World.Mini VarPtr(rc), VarPtr(sb), (r Mod 16) * 16, 24 + (r \ 16) * 12
  Next
  Board.Text 4, 2, "SEOUL", C_GOLD
  Board.Text 4, 25, "Q A O P: LOOK ROUND   M: BACK", C_GREY
  If inShop >= 0 Then r = streetRoom Else r = room
  mx = r Mod 16 : my = r \ 16 : d = -1
  ' the bag's districts
  For j = 0 To nBag - 1   ' GAME:
    If bDone(j) = 0 Then   ' GAME:
      LoadShop bShop(j)   ' GAME:
      Data.Copy Data.W_DISTRICTS, sh(4) * 32 + 17, 4, VarPtr(tb)
      sx = tb(0) * 16 + tb(2) * 8 - 8
      If lookup Then sx = (sh(5) Mod 16) * 16 : tb(1) = sh(5) \ 16 : tb(3) = 0   ' GAME:
      Spr.Put 40 + j, sx + 32, 24 + tb(1) * 12 + tb(3) * 6 - 6 + 32, GfxData.S_ICON + bKind(j), Spr.Pal * 15   ' GAME:
    End If
  Next
  Do
    Spr.Put SP_MARK, (r Mod 16) * 16 + 32, 24 + (r \ 16) * 12 + 30, GfxData.S_ICON2, Spr.Pal * 15
    Spr.Put SP_MARK + 1, mx * 16 + 32, 24 + my * 12 + 30, GfxData.S_ICON + 9, (Spr.Pal * 15) Or Spr.MirrorY
    LoadRoom my * 16 + mx
    If rc(193) <> d Then
      d = rc(193)
      Board.Rect 12, 2, 26, 1, 0, 0
      Board.Text 12, 2, DistName(d), C_WHITE
    End If
    v = NextKey()
    mx = Step4(v, mx, 3, 4, 15) : my = Step4(v, my, 1, 2, 11)
  Loop Until v >= 5
  Spr.HideRange 0, 128
  Board.Clear
  LoadRoom room
End Sub
