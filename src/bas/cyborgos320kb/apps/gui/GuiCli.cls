' GuiCli - a program's side of CyborgOS's GUI (GUI.CYB, the port GUI): windows and controls made,
' their values read. Copy it into a project (with CybSys, the cyborgos platform's own class).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'
'   w = GuiCli.Win(x, y, wide, high, "Title")      a window (cells: 80 x 25 on the CPC)
'   b = GuiCli.Button(w, x, y, "Feed")             in window w, x / y from its inside's top left
'   c = GuiCli.Check(w, x, y, "TV on")             value 0 / 1
'   l = GuiCli.Label(w, x, y, "Bowl: 3")
'   t = GuiCli.Field(w, x, y, wide, "")            text: GuiCli.Text(t); value: Returns pressed
'   g = GuiCli.Gauge(w, x, y, wide, 50)            0-100
'   r = GuiCli.Cycle(w, x, y, "Low|Mid|High")      value: the choice (0 ...)
'   p = GuiCli.Slider(w, x, y, wide, 100, 50)      value: 0-100 (max), 50 to start
'   v = GuiCli.List(w, x, y, wide, rows)           value: the row picked (-1 none); text: its item
'   GuiCli.AddItem v, "Apple"                      an item at the list's end
'   GuiCli.SetText id, "..." : GuiCli.SetVal id, n : GuiCli.Remove id
'   GuiCli.Value(id), GuiCli.Text(id)                its state now
'   s = GuiCli.Changed()                            the ids the user changed since last asked ("" none)
'   GuiCli.Ok()                                     True when the last call reached GUI
' -1 from a maker: GUI isn't running or has no room. A window's value is 1 once its close gadget
' was clicked: the program closes it (or not).
Option Explicit

Private st As Integer, rp As String Max 128

Private Function Send(ByVal m As String) As String
  rp = CybSys.PortCall("GUI", m)
  st = CybSys.PortStatus()
  Send = rp
End Function

Private Function Id(ByVal m As String) As Integer
  Dim s As String Max 128
  s = Send(m)
  If st <> 0 Or s = "?" Or s = "" Then Id = -1 Else Id = Val(s)
End Function

Public Function Ok() As Integer
  Ok = (st = 0)
End Function

Public Function Win(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer, ByVal t As String) As Integer
  Win = Id("W " + Str$(x) + Str$(y) + Str$(w) + Str$(h) + " " + t)
End Function

Public Function Button(ByVal w As Integer, ByVal x As Integer, ByVal y As Integer, ByVal t As String) As Integer
  Button = Id("B " + Str$(w) + Str$(x) + Str$(y) + " " + t)
End Function

Public Function Check(ByVal w As Integer, ByVal x As Integer, ByVal y As Integer, ByVal t As String) As Integer
  Check = Id("C " + Str$(w) + Str$(x) + Str$(y) + " " + t)
End Function

Public Function Label(ByVal w As Integer, ByVal x As Integer, ByVal y As Integer, ByVal t As String) As Integer
  Label = Id("L " + Str$(w) + Str$(x) + Str$(y) + " " + t)
End Function

Public Function Field(ByVal w As Integer, ByVal x As Integer, ByVal y As Integer, ByVal n As Integer, ByVal t As String) As Integer
  Field = Id("T " + Str$(w) + Str$(x) + Str$(y) + Str$(n) + " " + t)
End Function

Public Function Gauge(ByVal w As Integer, ByVal x As Integer, ByVal y As Integer, ByVal n As Integer, ByVal v As Integer) As Integer
  Gauge = Id("G " + Str$(w) + Str$(x) + Str$(y) + Str$(n) + Str$(v))
End Function

Public Function Cycle(ByVal w As Integer, ByVal x As Integer, ByVal y As Integer, ByVal t As String) As Integer
  Cycle = Id("R " + Str$(w) + Str$(x) + Str$(y) + " " + t)
End Function

Public Function Slider(ByVal w As Integer, ByVal x As Integer, ByVal y As Integer, ByVal n As Integer, ByVal mx As Integer, ByVal v As Integer) As Integer
  Slider = Id("P " + Str$(w) + Str$(x) + Str$(y) + Str$(n) + Str$(mx) + Str$(v))
End Function

Public Function List(ByVal w As Integer, ByVal x As Integer, ByVal y As Integer, ByVal n As Integer, ByVal h As Integer) As Integer
  List = Id("V " + Str$(w) + Str$(x) + Str$(y) + Str$(n) + Str$(h))
End Function

Public Function AddItem(ByVal l As Integer, ByVal t As String) As Integer
  AddItem = Id("I " + Str$(l) + " " + t)
End Function

Public Sub SetText(ByVal i As Integer, ByVal t As String)
  rp = Send("S " + Str$(i) + " " + t)
End Sub

Public Sub SetVal(ByVal i As Integer, ByVal v As Integer)
  rp = Send("V " + Str$(i) + Str$(v))
End Sub

Public Sub Remove(ByVal i As Integer)
  rp = Send("X " + Str$(i))
End Sub

Public Function Value(ByVal i As Integer) As Integer
  Dim s As String Max 128
  s = Send("? " + Str$(i))
  Value = Val(s)
End Function

Public Function Text(ByVal i As Integer) As String Max 40
  Dim s As String Max 128, k As Integer
  s = Send("? " + Str$(i))
  k = InStr(s, " ")
  If k = 0 Then Text = "" Else Text = Mid$(s, k + 1)
End Function

' Changed: the ids (separated by spaces) of this program's objects the user changed since the last call
Public Function Changed() As String Max 128
  Changed = Send("Q")
End Function
