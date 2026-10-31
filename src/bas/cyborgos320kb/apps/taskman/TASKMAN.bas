' TASKMAN: CyborgOS's task manager - every slot, its state, its program, its share of the machine
' (CPU%: its turns in the last second out of everyone's) as a bar, what it did in that second
' (turns, BDOS calls, characters), the memory; live, once a second. A slot picked and worked on:
' kill it, pause it / let it go on, bring it to the front, reset it.
' The screen is described once in VDU terms (tools/vdu: MODE, INK, LOCATE, PRINT, FILL, ZONE) and
' shown two ways: on this slot's console as a green phosphor screen (black paper, bright green
' pen), and - with VDU id key - on that VDU screen too (a browser: the same green, the bars drawn
' solid, its rows and buttons tapped working it as the keys do). The VDU server is RVDU's
' (RVDU.CFG: RVDU SERVER url). Build for cpm with cmds/Http.cls and cmds/CybSys.cls; a .CYB.
'   TASKMAN               on this console
'   TASKMAN VDU id key    and on VDU screen id too (its key writes to it: RVDU NEW makes one)
' Keys: Up / Down or 1-9 (0: 10) pick a slot, K kill, P pause / go on, F to the front, R reset,
' Q or ESC quit
Option Explicit
Option Terminal VT52
Const BUF = &H9000                          ' 2K: the VDU server's answer
Const BMAX = 2048
Const BODY = &H9800                         ' 3K: the lines sent to the VDU screen (a POST)
Const BODYMAX = 3000
Const BARW = 16                             ' a slot's bar: 16 cells
Const MEMW = 30                             ' the memory's bar: 30 cells

Dim g_strSrv As String Max 120, g_strId As String Max 8, g_strKey As String Max 16
Dim g_strArgs As String Max 72, g_strRow As String Max 80, g_strLn As String Max 255
Dim g_intRemote As Integer, g_intSel As Integer, g_intNs As Integer, g_intMe As Integer
Dim g_intCols As Integer, g_intRows As Integer, g_intOldMode As Integer, g_intHost As Integer
Dim g_intQuit As Integer, g_intKey As Integer, g_intBody As Integer, g_intAns As Integer
Dim g_intLp As Integer, g_intT0 As Integer, g_intR As Integer, g_intZoned As Integer
Dim g_intTop As Integer, g_intVis As Integer         ' the first slot shown; how many fit
Dim g_lngTurns As Long, g_lngGot As Long, g_lngEv As Long
Dim g_intMemTot As Integer, g_intMemFree As Integer
Dim g_arrIntSt(20) As Integer, g_arrIntFr(20) As Integer
Dim g_arrLngT(20) As Long, g_arrLngB(20) As Long, g_arrLngC(20) As Long
Dim g_arrStrNm(20) As String Max 12
Dim g_arrStrLoc(25) As String Max 80        ' the console's rows as last drawn
Dim g_arrStrRem(25) As String Max 80        ' the VDU screen's rows as last sent
Dim g_arrIntBarL(25) As Integer, g_arrIntBarR(25) As Integer   ' the bars on each row (VDU)
Dim g_arrByW(7) As Byte

Main
End

Sub Main()
  Dim intI As Integer, intS As Integer
  g_intHost = CybSys.Host()
  g_intMe = MySlot()
  g_strArgs = Trim$(CybSys.Tail())
  g_intRemote = 0
  If UCase$(WordOf(g_strArgs, 0)) = "VDU" Then
    g_strId = WordOf(g_strArgs, 1)
    g_strKey = WordOf(g_strArgs, 2)
    g_strSrv = Server()
    If g_strSrv = "" Or g_strId = "" Or g_strKey = "" Then
      Print "TASKMAN VDU id key - the server from RVDU.CFG (RVDU SERVER url first)"
      g_intQuit = 1
    Else
      g_intRemote = 1
    End If
  End If
  If g_intQuit = 0 Then
    Screen 1
    For intI = 1 To 25
      g_arrStrLoc(intI) = "?" : g_arrStrRem(intI) = "?"
    Next
    g_intSel = 1 : g_intTop = 1
    If g_intRemote Then RemoteStart
    g_intT0 = CybSys.Clock() - 400
    Do
      If Elapsed(g_intT0) >= 300 Then
        g_intT0 = CybSys.Clock()
        Gather
        Draw
        If g_intRemote Then RemoteEvents
      End If
      g_intKey = Inkey
      If g_intKey <> 0 Then
        DoKey g_intKey
        g_intT0 = CybSys.Clock() - 400
      Else
        g_intR = CybSys.Nap(g_intMe, 20)          ' (a short sleep - a key ends it: the keys looked at again)
      End If
    Loop Until g_intQuit
    If g_intRemote Then
      g_intR = Send("z:l1,25:t" + Chr$(34) + Pad(" TASKMAN has ended.", 79) + Chr$(34))
    End If
    Screen 0
    Print "TASKMAN ended"
  End If
End Sub

' ---- the slots

' every slot's state, program and last second; the memory
Sub Gather()
  Dim intS As Integer, intGo As Integer
  g_lngTurns = 0
  g_intNs = 0
  intS = 1
  intGo = 1
  Do While intGo
    If intS > 20 Then
      intGo = 0
    ElseIf CybSys.Ask(0, intS) = 255 Then
      intGo = 0
    Else
      g_intNs = intS
      g_arrIntSt(intS) = CybSys.ByteAt(2)
      g_arrIntFr(intS) = CybSys.ByteAt(3)
      g_arrStrNm(intS) = CybSys.TextAt(4)
      g_arrLngT(intS) = 0 : g_arrLngB(intS) = 0 : g_arrLngC(intS) = 0
      If CybSys.Stats(intS, VarPtr(g_arrByW)) = 0 Then
        g_arrLngT(intS) = CLng(g_arrByW(0)) + CLng(g_arrByW(1)) * 256&
        g_arrLngB(intS) = CLng(g_arrByW(2)) + CLng(g_arrByW(3)) * 256&
        g_arrLngC(intS) = CLng(g_arrByW(4)) + CLng(g_arrByW(5)) * 256&
      End If
      g_lngTurns = g_lngTurns + g_arrLngT(intS)
      intS = intS + 1
    End If
  Loop
  If g_intSel > g_intNs Then g_intSel = g_intNs
  If g_intSel < 1 Then g_intSel = 1
  g_intR = CybSys.Ask(7, 0)
  g_strLn = CybSys.TextAt(8)                     ' "Total memory: n KB   Free memory: n KB"
  g_intMemTot = ValAfter(g_strLn, "Total memory:")
  g_intMemFree = ValAfter(g_strLn, "Free memory:")
End Sub

' a key, from the keyboard or a VDU viewer
Sub DoKey(ByVal intK_a As Integer)
  If intK_a = 240 Or intK_a = 11 Then
    If g_intSel > 1 Then g_intSel = g_intSel - 1
  ElseIf intK_a = 241 Or intK_a = 10 Then
    If g_intSel < g_intNs Then g_intSel = g_intSel + 1
  ElseIf intK_a = 75 Or intK_a = 107 Then          ' K: kill (not this slot)
    If g_intSel <> g_intMe Then g_intR = CybSys.Ask(1, g_intSel)
  ElseIf intK_a = 80 Or intK_a = 112 Then          ' P: pause / go on
    If g_intSel <> g_intMe Then
      If g_arrIntSt(g_intSel) = 3 Then g_intR = CybSys.Pause(g_intSel, 0) Else g_intR = CybSys.Pause(g_intSel, 1)
    End If
  ElseIf intK_a = 70 Or intK_a = 102 Then          ' F: to the front
    If g_intSel <> g_intMe Then g_intR = CybSys.Ask(3, g_intSel)
  ElseIf intK_a = 82 Or intK_a = 114 Then          ' R: reset (not this slot)
    If g_intSel <> g_intMe Then g_intR = CybSys.Ask(2, g_intSel)
  ElseIf intK_a = 81 Or intK_a = 113 Or intK_a = 27 Then
    g_intQuit = 1
  ElseIf intK_a >= 49 And intK_a <= 57 Then          ' 1-9: that slot picked
    If intK_a - 48 <= g_intNs Then g_intSel = intK_a - 48
  ElseIf intK_a = 48 Then                            ' 0: slot 10
    If g_intNs >= 10 Then g_intSel = 10
  End If
End Sub

' ---- the screen, described once (25 rows of text, each row's bar)

Sub Draw()
  Dim intI As Integer, intS As Integer, intRow As Integer, strT As String Max 80
  g_intBody = 0
  For intI = 1 To 25
    g_arrIntBarL(intI) = 0 : g_arrIntBarR(intI) = 0
  Next
  g_intVis = g_intRows - 6                        ' (3 rows above the slots, 3 below)
  If g_intSel < g_intTop Then g_intTop = g_intSel
  If g_intSel > g_intTop + g_intVis - 1 Then g_intTop = g_intSel - g_intVis + 1
  If g_intTop < 1 Then g_intTop = 1
  Put 1, " CyborgOS Task Manager" + Space$(28) + Right$(Space$(30) + HostName() + "   " + CStr(g_intNs) + " slots ", 30)
  Put 2, " " + Rep("=", 78)
  Put 3, "SLOT STATE" + Space$(9) + "PROGRAM" + Space$(7) + "CPU%  LOAD" + Space$(15) + "TURNS/S BDOS/S CHARS/S"
  For intI = 0 To g_intVis - 1
    intRow = 4 + intI
    intS = g_intTop + intI
    If intS <= g_intNs Then
      Put intRow, SlotRow(intS)
      g_arrIntBarL(intRow) = 40
      g_arrIntBarR(intRow) = 40 + Cells(Pct(g_arrLngT(intS)), BARW)
    Else
      Put intRow, ""
    End If
  Next
  If g_intTop + g_intVis - 1 < g_intNs Then strT = " " + Rep("-", 70) + " more v " Else strT = " " + Rep("-", 78)
  Put g_intRows - 2, strT
  Put g_intRows - 1, MemRow()
  g_arrIntBarL(g_intRows - 1) = 10
  g_arrIntBarR(g_intRows - 1) = 10 + Cells(MemPct(), MEMW)
  strT = " Up/Down/1-9 pick   K kill   P pause/go   F front   R reset   Q quit"
  If g_intRemote Then strT = strT + "   VDU " + g_strId
  Put g_intRows, strT
  If g_intRemote Then RemoteFlush
End Sub

' row r: on the console if it changed; queued for the VDU screen if it changed there
Sub Put(ByVal intR_a As Integer, ByVal strT_a As String)
  Dim strP As String Max 80
  strP = Pad(strT_a, g_intCols)
  If intR_a <= g_intRows Then
    If strP <> g_arrStrLoc(intR_a) Then
      g_arrStrLoc(intR_a) = strP
      If intR_a = g_intRows Then strP = Left$(strP, g_intCols - 1)   ' (the last cell: no scroll)
      Locate 1, intR_a : Print strP;
    End If
  End If
  If g_intRemote Then
    strP = Pad(strT_a, 80)
    If strP <> g_arrStrRem(intR_a) Then
      RemoteRow intR_a, strP
    End If
  End If
End Sub

' slot s's row: > for the one picked, * for the one in front
Function SlotRow(ByVal intS_a As Integer) As String Max 80
  Dim strR As String Max 80, strSt As String Max 13, intP As Integer, intN As Integer
  If g_arrIntSt(intS_a) = 0 Then
    strSt = "-"
  ElseIf g_arrIntSt(intS_a) = 1 Then
    strSt = "command line"
  ElseIf g_arrIntSt(intS_a) = 3 Then
    strSt = "paused"
  Else
    strSt = "running"
  End If
  intP = Pct(g_arrLngT(intS_a))
  intN = Cells(intP, BARW)
  If intS_a = g_intSel Then strR = ">" Else strR = " "
  strR = strR + Right$("  " + CStr(intS_a), 2) + IIf(g_arrIntFr(intS_a), "*", " ") + " "
  strR = strR + Pad(strSt, 13) + " " + Pad(g_arrStrNm(intS_a), 13) + " "
  strR = strR + Right$("   " + CStr(intP), 3) + "%  [" + Rep("#", intN) + Rep(".", BARW - intN) + "] "
  strR = strR + Right$(Space$(7) + CStr(g_arrLngT(intS_a)), 7) + " " + Right$(Space$(6) + CStr(g_arrLngB(intS_a)), 6)
  strR = strR + " " + Right$(Space$(7) + CStr(g_arrLngC(intS_a)), 7)
  If intS_a = g_intSel Then strR = Left$(strR, 79) + "<"
  SlotRow = strR
End Function

Function MemRow() As String Max 80
  Dim intN As Integer, intUsed As Integer, intRun As Integer, intPau As Integer, intS As Integer
  intN = Cells(MemPct(), MEMW)
  intUsed = g_intMemTot - g_intMemFree
  For intS = 1 To g_intNs
    If g_arrIntSt(intS) = 2 Then intRun = intRun + 1
    If g_arrIntSt(intS) = 3 Then intPau = intPau + 1
  Next
  MemRow = " MEMORY  [" + Rep("#", intN) + Rep(".", MEMW - intN) + "] " + CStr(intUsed) + " of " + CStr(g_intMemTot) + " KB   running " + CStr(intRun) + "  paused " + CStr(intPau)
End Function

' a slot's share of the machine: its turns out of everyone's, as a percentage
Function Pct(ByVal lngT_a As Long) As Integer
  Dim lngP As Long
  lngP = 0
  If g_lngTurns > 0 And lngT_a > 0 Then lngP = (lngT_a * 100&) \ g_lngTurns
  If lngP > 100 Then lngP = 100
  Pct = CInt(lngP)
End Function

Function MemPct() As Integer
  Dim lngP As Long
  lngP = 0
  If g_intMemTot > 0 Then lngP = (CLng(g_intMemTot - g_intMemFree) * 100) \ g_intMemTot
  MemPct = CInt(lngP)
End Function

' p% of w cells, at least one for anything above 0
Function Cells(ByVal intP_a As Integer, ByVal intW_a As Integer) As Integer
  Dim intN As Integer
  intN = (intP_a * intW_a + 50) \ 100
  If intN = 0 And intP_a > 0 Then intN = 1
  If intN > intW_a Then intN = intW_a
  Cells = intN
End Function

' ---- the console: green while TASKMAN is in front (the slot's own colours), MODE 2

Sub Screen(ByVal intOn_a As Integer)
  If intOn_a Then
    g_intOldMode = CybSys.Ask(9, 255)
    Poke &HF6E5, 1 : Poke &HF6E6, 19 : Poke &HF6E7, 1   ' (paper black 0, pen bright green 18, border black)
    g_intR = CybSys.Ask(9, 2)                            ' MODE 2: 80 x 25 - the colours set with it
    g_intCols = Peek(&HF687) : g_intRows = Peek(&HF688)
    If g_intCols < 40 Or g_intCols > 80 Then g_intCols = 80
    If g_intRows < 10 Or g_intRows > 25 Then g_intRows = 25
    Cls
  Else
    Poke &HF6E5, 0 : Poke &HF6E6, 0 : Poke &HF6E7, 0    ' the console's own colours again
    g_intR = CybSys.Ask(9, g_intOldMode)
  End If
End Sub

' ---- the VDU screen: the same rows, the bars solid, the rows and buttons tapped (events)

Sub RemoteStart()
  Dim intS As Integer
  g_lngGot = -1
  g_intR = Send("-" + Chr$(34) + "vdu1" + Chr$(34) + "," + Chr$(34) + "CyborgOS Task Manager" + Chr$(34) + ":m2:i0,0:i1,18:b0:f1:a0")
  g_intZoned = 0
End Sub

' row r for the VDU screen: its text (the picked slot's row inverse), its bar filled in
Sub RemoteRow(ByVal intR_a As Integer, ByVal strT_a As String)
  Dim strL As String Max 255, intY As Integer, intX As Integer, intW As Integer
  g_arrStrRem(intR_a) = strT_a
  strL = "l1," + CStr(intR_a) + ":"
  If intR_a = 4 + g_intSel - g_intTop And intR_a <= 3 + g_intVis Then strL = strL + "a1:f0:" Else strL = strL + "a0:f1:"
  strL = strL + "t" + Chr$(34) + Esc(strT_a) + Chr$(34) + ":a0:f1"
  If g_arrIntBarR(intR_a) > g_arrIntBarL(intR_a) Then          ' (the # cells drawn solid)
    intX = g_arrIntBarL(intR_a) * 8
    intW = (g_arrIntBarR(intR_a) - g_arrIntBarL(intR_a)) * 8
    intY = 400 - intR_a * 16 + 3
    If intR_a = 4 + g_intSel - g_intTop And intR_a <= 3 + g_intVis Then strL = strL + ":g0" Else strL = strL + ":g1"
    strL = strL + ":u" + CStr(intX) + "," + CStr(intY) + "," + CStr(intW) + ",10"
  End If
  Queue strL
End Sub

' the queued lines to the VDU screen (one POST); its touch zones the first time
Sub RemoteFlush()
  Dim intI As Integer, intS As Integer, intY As Integer, strZ As String Max 255
  If g_intZoned <> g_intTop * 100 + g_intNs Then          ' (the touch zones: again when the list scrolls)
    Queue "z"
    For intI = 0 To g_intVis - 1
      intS = g_intTop + intI
      If intS <= g_intNs Then
        Queue "z" + Chr$(34) + "s" + CStr(intS) + Chr$(34) + ",0," + CStr(400 - (4 + intI) * 16) + ",640,16"
      End If
    Next
    intY = 400 - g_intRows * 16
    strZ = "z" + Chr$(34) + "k" + Chr$(34) + ",160," + CStr(intY) + ",48,16:z" + Chr$(34) + "p" + Chr$(34) + ",232," + CStr(intY) + ",80,16:"
    strZ = strZ + "z" + Chr$(34) + "f" + Chr$(34) + ",336," + CStr(intY) + ",56,16:z" + Chr$(34) + "r" + Chr$(34) + ",416," + CStr(intY) + ",56,16:"
    strZ = strZ + "z" + Chr$(34) + "q" + Chr$(34) + ",496," + CStr(intY) + ",48,16"
    Queue strZ
    g_intZoned = g_intTop * 100 + g_intNs
  End If
  If g_intBody > 0 Then
    g_lngEv = Post()
    g_intBody = 0
  End If
End Sub

' the viewers' taps and keys since last time: worked as keys
Sub RemoteEvents()
  Dim strE As String Max 255, strH As String Max 80, strN As String Max 16
  If g_lngGot < 0 Then g_lngGot = g_lngEv                  ' (the events from before: not ours)
  If g_lngEv > g_lngGot Then
    If Ask("a=events&s=" + g_strId + "&k=" + g_strKey + "&n=" + CStr(g_lngGot)) Then
      strH = LineAt()
      Do While g_intLp < g_intAns
        strE = LineAt()
        If WordOf(strE, 0) = "TOUCH" Then
          strN = WordOf(strE, 1)
          If Left$(strN, 1) = "s" Then
            g_intSel = Val(Mid$(strN, 2))
          ElseIf strN = "k" Then
            DoKey 75
          ElseIf strN = "p" Then
            DoKey 80
          ElseIf strN = "f" Then
            DoKey 70
          ElseIf strN = "r" Then
            DoKey 82
          ElseIf strN = "q" Then
            DoKey 81
          End If
        ElseIf WordOf(strE, 0) = "KEY" Then
          DoKey Val(WordOf(strE, 1))
        End If
      Loop
      g_lngGot = Val(WordOf(strH, 2))
    End If
  End If
End Sub

' a line queued for the next POST (a newline between lines)
Sub Queue(ByVal strL_a As String)
  Dim intI As Integer
  If g_intBody + Len(strL_a) + 4 > BODYMAX Then
    g_lngEv = Post()
    g_intBody = 0
  End If
  If g_intBody = 0 Then
    Poke BODY, 99 : Poke BODY + 1, 61                       ' "c="
    g_intBody = 2
  Else
    Poke BODY + g_intBody, 10
    g_intBody = g_intBody + 1
  End If
  For intI = 1 To Len(strL_a)
    Poke BODY + g_intBody, Asc(Mid$(strL_a, intI, 1))
    g_intBody = g_intBody + 1
  Next
End Sub

' the queued lines POSTed (put): the screen's events so far, -1 if it failed
Function Post() As Long
  Dim lngE As Long, strH As String Max 80
  lngE = g_lngEv
  g_intAns = Http.Post(g_strSrv + "?a=put&s=" + g_strId + "&k=" + g_strKey, BODY, g_intBody, BUF, BMAX)
  g_intLp = 0
  If g_intAns > 0 And Http.Code() = 200 Then
    strH = LineAt()
    If Left$(strH, 2) = "ok" Then lngE = Val(WordOf(strH, 2))
  End If
  Post = lngE
End Function

' one line sent at once (a POST of its own)
Function Send(ByVal strL_a As String) As Integer
  g_intBody = 0
  Queue strL_a
  g_lngEv = Post()
  g_intBody = 0
  Send = 0
End Function

' the server asked (a GET): True when it answered "ok ..." (the answer at BUF)
Function Ask(ByVal strQ_a As String) As Integer
  Dim intOk As Integer
  intOk = 0
  g_intLp = 0
  g_intAns = Http.Get(g_strSrv + "?" + strQ_a, BUF, BMAX)
  If g_intAns > 1 And Http.Code() = 200 Then
    If Peek(BUF) = 111 And Peek(BUF + 1) = 107 Then intOk = -1
  End If
  Ask = intOk
End Function

' the answer's next line (from g_intLp; moved past it)
Function LineAt() As String Max 255
  Dim strT As String Max 255, intC As Integer, intGo As Integer
  strT = ""
  intGo = 1
  Do While intGo
    If g_intLp >= g_intAns Then
      intGo = 0
    Else
      intC = Peek(BUF + g_intLp)
      g_intLp = g_intLp + 1
      If intC = 10 Then
        intGo = 0
      ElseIf intC <> 13 And Len(strT) < 255 Then
        strT = strT + Chr$(intC)
      End If
    End If
  Loop
  LineAt = strT
End Function

' the VDU server: RVDU.CFG's first line
Function Server() As String Max 120
  Dim intN As Integer, intI As Integer, strS As String Max 120, intC As Integer
  strS = ""
  intN = FileSystem.Load("RVDU.CFG", BUF, 200)
  If intN > 0 Then
    For intI = 0 To intN - 1
      intC = Peek(BUF + intI)
      If intC = 13 Or intC = 10 Then intI = intN Else strS = strS + Chr$(intC)
    Next
  End If
  Server = Trim$(strS)
End Function

' ---- small things

' this program's slot (the number in its bank's strip text, "[n]")
Function MySlot() As Integer
  Dim intI As Integer, intN As Integer
  intN = 0
  intI = &HF68B
  Do While Peek(intI) >= 48 And Peek(intI) <= 57
    intN = intN * 10 + Peek(intI) - 48
    intI = intI + 1
  Loop
  MySlot = intN
End Function

Function HostName() As String Max 12
  Dim strH As String Max 12
  strH = "CyborgOS"
  If g_intHost = 0 Then strH = "Amstrad CPC"
  If g_intHost = 1 Then strH = "ZX Next"
  If g_intHost = 3 Then strH = "MSX"
  If g_intHost = 4 Then strH = "vCPC"
  HostName = strH
End Function

' clock ticks (300 a second) since t, the clock's wrap allowed for
Function Elapsed(ByVal intT_a As Integer) As Integer
  Dim lngD As Long
  lngD = CLng(CybSys.Clock()) - CLng(intT_a)
  If lngD < 0 Then lngD = lngD + 65536
  If lngD > 30000 Then lngD = 30000
  Elapsed = CInt(lngD)
End Function

Function Pad(ByVal strT_a As String, ByVal intW_a As Integer) As String Max 80
  Pad = Left$(strT_a + Space$(80), intW_a)
End Function

Function Rep(ByVal strC_a As String, ByVal intN_a As Integer) As String Max 80
  Dim strR As String Max 80, intI As Integer
  strR = ""
  For intI = 1 To intN_a
    strR = strR + strC_a
  Next
  Rep = strR
End Function

' the number after a label in a line ("Free memory: 304 KB" -> 304)
Function ValAfter(ByVal strL_a As String, ByVal strK_a As String) As Integer
  Dim intP As Integer, intV As Integer
  intV = 0
  intP = InStr(strL_a, strK_a)
  If intP > 0 Then intV = Val(Mid$(strL_a, intP + Len(strK_a)))
  ValAfter = intV
End Function

' word n of a line (spaces between)
Function WordOf(ByVal strL_a As String, ByVal intN_a As Integer) As String Max 72
  Dim intI As Integer, intW As Integer, strW As String Max 72, strC As String Max 1, intIn As Integer
  strW = "" : intW = -1 : intIn = 0
  For intI = 1 To Len(strL_a)
    strC = Mid$(strL_a, intI, 1)
    If strC = " " Then
      intIn = 0
    Else
      If intIn = 0 Then intW = intW + 1 : intIn = 1
      If intW = intN_a Then strW = strW + strC
    End If
  Next
  WordOf = strW
End Function

' text for the 8BML dialect: a quote or a backslash escaped
Function Esc(ByVal strT_a As String) As String Max 160
  Dim strR As String Max 160, strC As String Max 1, intI As Integer
  strR = ""
  For intI = 1 To Len(strT_a)
    strC = Mid$(strT_a, intI, 1)
    If strC = Chr$(34) Or strC = "\" Then strR = strR + "\"
    strR = strR + strC
  Next
  Esc = strR
End Function
