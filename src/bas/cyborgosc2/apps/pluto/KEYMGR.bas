' KEYMGR - Pluto's key manager: makes and lists the keys KEYMAN and ENC / DEC use (KEYS/NAME.KEY,
' the ROM's raw bytes - its size says the kind: 128 a microROM for key exchange, more a full ROM).
' Build for cpm with Zc is not needed - only FileSystem and CybSys. A .CYB.
'   KEYMGR LIST                        the keys in KEYS/ (name, size, kind)
'   KEYMGR JPEG name picture.jpg size  a key: the first <size> bytes of the picture (its image data
'                                      is high-entropy; 128 for a microROM, e.g. 4096 / 65536 for a ROM)
'   KEYMGR ENTROPY name size f1 f2 f3 f4 f5   a key XORed from 5 source files (any kind - the ROM
'                                      generator's way), each read from a start in a direction set
'                                      by entropy sugar (the 300Hz clock, uptime, free memory, the
'                                      R register): same sugar + same files = same key. Fewer than 5
'                                      files are cycled. size up to KEYMAX
' DH keys (4 x Diffie-Hellman -> a 256-byte microROM) are not here yet - they need the relay and
' group settled (see the todo); paste a hex microROM with JPEG-like tools meanwhile.
Option Explicit

Const KEYMAX = 8192                            ' a key: bytes at most (this utility's RAM)
Const SRCMAX = 8192                            ' a source file read at once

Dim kb(8191) As Byte                           ' the key being built
Dim sb(8191) As Byte                           ' a source file
Dim a As String Max 72, cmd As String Max 8, nm As String Max 12
Dim i As Integer, j As Integer, r As Integer, n As Integer

a = Trim$(CybSys.Tail())
If a = "" Then
  Print "KEYMGR LIST | JPEG name pic.jpg size | ENTROPY name size f1 .. f5"
  End
End If
cmd = UCase$(Word(1))
If cmd = "LIST" Then
  DoList
ElseIf cmd = "JPEG" Then
  DoJpeg
ElseIf cmd = "ENTROPY" Then
  DoEntropy
Else
  Print "KEYMGR: LIST, JPEG or ENTROPY"
End If
End

' word n (1 on) of the tail
Function Word(ByVal k As Integer) As String
  Dim s As String Max 72, p As Integer
  s = a
  Do While k > 1
    p = InStr(s, " ")
    If p = 0 Then Word = "" : Exit Function
    s = Trim$(Mid$(s, p + 1))
    k = k - 1
  Loop
  p = InStr(s, " ")
  If p = 0 Then Word = s Else Word = Left$(s, p - 1)
End Function

Sub DoList()
  Dim e As String Max 40, sz As Long, kind As String Max 10, cnt As Integer
  cnt = 0
  i = 0
  Do
    e = FileSystem.DirEntry(i)
    If e = "" Then Exit Do
    If Right$(UCase$(e), 4) = ".KEY" Then
      sz = FileSystem.Size(e)
      If sz <= 128 Then kind = "microROM" Else kind = "ROM"
      Print e; " "; sz; " bytes ("; kind; ")"
      cnt = cnt + 1
    End If
    i = i + 1
  Loop
  If cnt = 0 Then Print "No keys in KEYS/ (make one: KEYMGR JPEG / ENTROPY)"
End Sub

Sub DoJpeg()
  Dim src As String Max 16, h As Integer, want As Integer
  nm = UCase$(Word(2))
  src = Word(3)
  want = Val(Word(4))
  If nm = "" Or src = "" Or want <= 0 Then Print "KEYMGR JPEG name picture.jpg size" : Exit Sub
  If want > KEYMAX Then Print "size too big (max"; KEYMAX; ")" : Exit Sub
  h = FileSystem.Open(src, FileSystem.ForReadRaw)
  If h < 0 Then Print "No such file: "; src : Exit Sub
  n = FileSystem.Read(h, VarPtr(kb(0)), want)
  FileSystem.Close h
  If n < want Then Print src; " has only"; n; "bytes" : Exit Sub
  If Save(nm, want) = 1 Then Print "KEYS/"; nm; ".KEY made ("; want; " bytes from "; src; ")"
End Sub

Sub DoEntropy()
  Dim size As Integer, nf As Integer, fn(4) As String Max 16, ln(4) As Integer, ps(4) As Integer, fwd(4) As Integer
  Dim h As Integer, k As Integer, seed As Integer, sug As Long, o As Integer
  nm = UCase$(Word(2))
  size = Val(Word(3))
  If nm = "" Or size <= 0 Then Print "KEYMGR ENTROPY name size f1 .. f5" : Exit Sub
  If size > KEYMAX Then Print "size too big (max"; KEYMAX; ")" : Exit Sub
  nf = 0
  For k = 0 To 4
    fn(k) = Word(4 + k)
    If fn(k) <> "" Then nf = k + 1
  Next
  If nf = 0 Then Print "Name at least one source file" : Exit Sub
  ' entropy sugar: the full clock (uptime), the clock low word, free memory
  sug = CybSys.Uptime()
  For i = 0 To size - 1
    kb(i) = 0
  Next
  For k = 0 To nf - 1
    h = FileSystem.Open(fn(k), FileSystem.ForReadRaw)
    If h < 0 Then Print "No such file: "; fn(k) : Exit Sub
    ln(k) = FileSystem.Read(h, VarPtr(sb(0)), SRCMAX)
    FileSystem.Close h
    If ln(k) <= 0 Then Print fn(k); ": empty" : Exit Sub
    seed = (sug And 32767) + k * 2659 + CybSys.Clock()
    If seed < 0 Then seed = -seed
    fwd(k) = 1 - (seed And 1)
    o = seed Mod ln(k)
    ' XOR this file across the key, from o, in its direction, wrapping
    For i = 0 To size - 1
      kb(i) = kb(i) Xor sb(o)
      If fwd(k) = 1 Then
        o = o + 1 : If o >= ln(k) Then o = 0
      Else
        o = o - 1 : If o < 0 Then o = ln(k) - 1
      End If
    Next
  Next
  If Save(nm, size) = 1 Then Print "KEYS/"; nm; ".KEY made ("; size; " bytes from"; nf; "files, entropy-seeded)"
End Sub

' write kb's first n bytes to KEYS/name.KEY
Function Save(ByVal name As String, ByVal n As Integer) As Integer
  Dim h As Integer, w As Integer
  Save = 0
  h = FileSystem.Open("KEYS/" + name + ".KEY", FileSystem.ForWrite)
  If h < 0 Then Print "Could not make KEYS/"; name; ".KEY" : Exit Function
  w = FileSystem.Write(h, VarPtr(kb(0)), n)
  FileSystem.Close h
  Save = 1
End Function
