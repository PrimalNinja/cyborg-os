' GUIDEMO - a program with a window on CyborgOS's GUI (GUI.CYB, running in another slot): a pet's
' panel - Feed and Play buttons, a TV check box, a name field, a food gauge that goes down by
' itself. It only says what it wants and reads the values back (GuiCli); GUI draws it.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'   RUN 2 GUI : RUN 3 GUIDEMO       then Control + 2 for GUI's screen. The close gadget ends it.
Option Explicit

Dim w As Integer, bf As Integer, bp As Integer, ct As Integer, ln As Integer, lf As Integer
Dim fn As Integer, gf As Integer, food As Integer, fun As Integer, t As Integer, s As String Max 128
Dim k As Integer, id As Integer, done As Integer, nm As String Max 40, cm As Integer, sp As Integer, lt As Integer

If System.CommandLine() = "?" Then Print "GUIDEMO: a window on GUI" : End   ' (CybSys needs it linked)
w = GuiCli.Win(4, 3, 56, 16, "Pet - GUIDEMO")
If w < 0 Then Print "GUIDEMO: no GUI (RUN 2 GUI first)" : End
ln = GuiCli.Label(w, 2, 1, "Name")
fn = GuiCli.Field(w, 8, 1, 16, "Rex")
lf = GuiCli.Label(w, 2, 3, "Food")
gf = GuiCli.Gauge(w, 8, 3, 20, 60)
bf = GuiCli.Button(w, 2, 6, "Feed")
bp = GuiCli.Button(w, 10, 6, "Play")
ct = GuiCli.Check(w, 18, 6, "TV on")
id = GuiCli.Label(w, 2, 13, "Rex is fine.")
k = GuiCli.Label(w, 2, 9, "Mood")
cm = GuiCli.Cycle(w, 8, 9, "happy|sleepy|grumpy")
k = GuiCli.Label(w, 2, 11, "Play")
sp = GuiCli.Slider(w, 8, 11, 20, 10, 5)
k = GuiCli.Label(w, 32, 1, "Treats")
lt = GuiCli.List(w, 32, 3, 18, 5)
k = GuiCli.AddItem(lt, "Apple")
k = GuiCli.AddItem(lt, "Carrot")
k = GuiCli.AddItem(lt, "Cheese")
k = GuiCli.AddItem(lt, "Sunflower seeds")
k = GuiCli.AddItem(lt, "Yoghurt drops")
k = GuiCli.AddItem(lt, "Peas")
k = GuiCli.AddItem(lt, "Corn")
food = 60 : fun = 0 : t = CybSys.Clock()
Print "GUIDEMO: window"; w; "on GUI"

Do
  s = GuiCli.Changed()
  Do While s <> ""
    k = InStr(s + " ", " ")
    Act Val(Left$(s, k - 1))
    s = Trim$(Mid$(s + " ", k + 1))
  Loop
  If CybSys.Clock() - t >= 600 Then                ' every 2 s: a little hungrier
    t = CybSys.Clock()
    food = food - 5
    If food < 0 Then food = 0
    GuiCli.SetVal gf, food
    If food = 0 Then GuiCli.SetText id, GuiCli.Text(fn) + " is starving!"
  End If
  If CybSys.Bdos(12, 0) = 0 Then                   ' (the CPU to the others meanwhile)
  End If
Loop Until done

GuiCli.Remove w
Print "GUIDEMO: done"
End

Sub Act(ByVal n As Integer)
  nm = GuiCli.Text(fn)
  If n = w Then done = 1
  If n = bf Then
    food = food + 20
    If food > 100 Then food = 100
    GuiCli.SetVal gf, food
    GuiCli.SetText id, nm + " eats. Fed " + Trim$(Str$(GuiCli.Value(bf))) + " times."
  End If
  If n = bp Then
    fun = fun + 1
    GuiCli.SetText id, nm + " plays (" + Trim$(Str$(fun)) + ")."
  End If
  If n = ct Then
    If GuiCli.Value(ct) Then GuiCli.SetText id, nm + " watches TV." Else GuiCli.SetText id, "TV off."
  End If
  If n = fn Then GuiCli.SetText id, "Hello, " + nm + "."
  If n = cm Then GuiCli.SetText id, nm + " is " + GuiCli.Text(cm) + "."
  If n = sp Then GuiCli.SetText id, nm + " plays at" + Str$(GuiCli.Value(sp)) + " / 10."
  If n = lt Then GuiCli.SetText id, nm + " gets " + GuiCli.Text(lt) + "."
End Sub
