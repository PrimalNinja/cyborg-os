' KEYMAN - Pluto's key service. It hosts the keys (KEYS/NAME.KEY) and encodes / decodes on request
' over the port KEYMAN, so other slots never handle the keys (a monitor can still look - not the
' point). A request names 1-3 layers and WHERE the data is in the caller's own memory; the bulk
' never crosses the 128-byte port - KEYMAN pulls the bytes from the caller's slot through the
' kernel (op 10) into its buffer, encodes / decodes, and writes the result back into the caller's
' slot. Keys and plaintext stay on the CPC.
'   RUN 2 KEYMAN                 opens the port KEYMAN (Q at its keyboard ends it)
' The port's messages (the three numbers in HEX):
'   E layer[s] nbytes src dst    encode nbytes (hex) at src (hex, in the caller's memory) through
'                                the layers; the result to dst. Reply "ok len" (len hex bytes at
'                                dst) or "? reason"
'   D layer[s] nbytes src dst    decode (the layers in the SAME order - undone last first)
'   K                            the keys loaded (names, space separated)
'   R                            the key cache cleared (KEYS/ read again on the next request)
' A layer is method:keyname - method z u b (16-bit) or mz mu mb (8-bit, for key exchange, the inner
' layer). The outer u / b layer sizes its suffix so an encoded result is a multiple of 128 bytes.
' Build for cpm with Zc.cls and CybSys.cls. A .CYB.
Option Explicit

Const INMAX = 2048                             ' a request's plaintext: bytes at most
Const OUTMAX = 8192                            ' its result (it grows through the layers)
Const KEYMAXB = 8192                           ' a key: bytes at most
Const POOLSZ = 16384                           ' the loaded keys together
Const NLAYERS = 3
Const ALIGN = 128

Dim ba(8191) As Byte, bb(8191) As Byte         ' two work buffers (ping-pong through the layers)
Dim pool(16383) As Byte                        ' the loaded keys
Dim pnm(7) As String Max 12, poff(7) As Integer, plen(7) As Integer
Dim nk As Integer, ptop As Integer
Dim mth(2) As Integer, knm(2) As String Max 12, nl As Integer
Dim parts(7) As String Max 24, np As Integer   ' Split's result
Dim m_src As Integer                           ' Chain's final buffer (0 ba, 1 bb)
Dim pt As String Max 8, msg As String Max 128, rp As String Max 128
Dim r As Integer, ch As Integer, nq As Integer

Randomize CybSys.Clock()
nk = 0 : ptop = 0
pt = "KEYMAN"
r = CybSys.PortOpen(pt)
If r <> 0 Then Print "The port KEYMAN is taken (another KEYMAN?)" : End
Print "KEYMAN: the key service on port KEYMAN (Q ends it)"
Do
  r = CybSys.PortGet(pt)
  If r = 0 Then
    msg = CybSys.PortMessage()
    rp = Answer(msg, CybSys.PortCaller())
    r = CybSys.PortReply(pt, rp)
    nq = nq + 1
  Else
    ch = Inkey
    If ch = 81 Or ch = 113 Then Exit Do
  End If
Loop
r = CybSys.PortClose(pt)
Print "KEYMAN:"; nq; "requests"
End

' a request from the port (caller = the slot that asked): its answer
Function Answer(ByVal m As String, ByVal caller As Integer) As String
  Dim c As String Max 1, nb As Integer, src As Integer, dst As Integer, outlen As Integer
  Dim i As Integer
  Answer = "?"
  m = Trim$(m)
  c = UCase$(Left$(m, 1))
  If c = "K" Then
    Answer = Keys() : Exit Function
  ElseIf c = "R" Then
    nk = 0 : ptop = 0 : Answer = "ok" : Exit Function
  ElseIf c <> "E" And c <> "D" Then
    Answer = "? E D K R" : Exit Function
  End If
  Split Trim$(Mid$(m, 2))
  If np < 4 Then Answer = "? need layer[s] nbytes src dst" : Exit Function
  nl = np - 3
  If nl > NLAYERS Then Answer = "? at most 3 layers" : Exit Function
  For i = 0 To nl - 1
    If Layer(parts(i), i) = 0 Then Answer = "? bad layer " + parts(i) : Exit Function
  Next
  nb = HexV(parts(np - 3))
  src = HexV(parts(np - 2))
  dst = HexV(parts(np - 1))
  If nb <= 0 Or nb > INMAX Then Answer = "? nbytes 1.." + Hex4(INMAX) : Exit Function
  If SlotRead(caller, src, VarPtr(ba(0)), nb) <> 0 Then Answer = "? could not read the caller" : Exit Function
  outlen = Chain(c, nb)
  If outlen < 0 Then Answer = "? the key lacks a value the data needs (or bad input)" : Exit Function
  If outlen > OUTMAX Then Answer = "? result too big" : Exit Function
  If m_src = 0 Then r = SlotWrite(caller, dst, VarPtr(ba(0)), outlen) Else r = SlotWrite(caller, dst, VarPtr(bb(0)), outlen)
  If r <> 0 Then Answer = "? could not write the caller" : Exit Function
  Answer = "ok " + Hex4(outlen)
End Function

' the layer chain on ba (input, src 0): the output length, the final buffer left in m_src. -1 error
Function Chain(ByVal c As String, ByVal inlen As Integer) As Integer
  Dim i As Integer, li As Integer, src As Integer, kp As Integer, kl As Integer, inp As Integer, outp As Integer, res As Integer
  src = 0
  For i = 0 To nl - 1
    li = i : If c = "D" Then li = nl - 1 - i
    kl = LoadKey(knm(li), kp)
    If kl <= 0 Then Chain = -1 : Exit Function
    If Zc.Open(VarPtr(pool(kp)), kl, mth(li)) <> 0 Then Chain = -1 : Exit Function
    Zc.Pad 0                                    ' message mode: exact lengths in memory, no 128-alignment (that's for files)
    If src = 0 Then inp = VarPtr(ba(0)) : outp = VarPtr(bb(0)) Else inp = VarPtr(bb(0)) : outp = VarPtr(ba(0))
    If c = "E" Then res = Zc.Encode(inp, inlen, outp, OUTMAX) Else res = Zc.Decode(inp, inlen, outp, OUTMAX)
    If res < 0 Then Chain = -1 : Exit Function
    inlen = res
    src = 1 - src
  Next
  m_src = src
  Chain = inlen
End Function

' a key into the pool (cached): its length, and its pool offset in off. 0 none / too big
Function LoadKey(ByVal name As String, ByRef off As Integer) As Integer
  Dim i As Integer, h As Integer, n As Integer
  For i = 0 To nk - 1
    If pnm(i) = name Then off = poff(i) : LoadKey = plen(i) : Exit Function
  Next
  LoadKey = 0
  If nk >= 8 Then Exit Function
  h = FileSystem.Open("KEYS/" + name + ".KEY", FileSystem.ForReadRaw)
  If h < 0 Then Exit Function
  If ptop + KEYMAXB > POOLSZ Then FileSystem.Close h : Exit Function
  n = FileSystem.Read(h, VarPtr(pool(ptop)), KEYMAXB)
  FileSystem.Close h
  If n <= 0 Or n >= KEYMAXB Then Exit Function
  pnm(nk) = name : poff(nk) = ptop : plen(nk) = n
  off = ptop : ptop = ptop + n : nk = nk + 1
  LoadKey = n
End Function

Function Keys() As String
  Dim i As Integer, s As String Max 120
  s = ""
  For i = 0 To nk - 1
    If s <> "" Then s = s + " "
    s = s + pnm(i)
  Next
  If s = "" Then s = "(none loaded yet)"
  Keys = s
End Function

' "method:keyname" into mth(i) / knm(i). 0 on error
Function Layer(ByVal s As String, ByVal i As Integer) As Integer
  Dim j As Integer, mm As String Max 4
  Layer = 0
  j = InStr(s, ":")
  If j = 0 Then Exit Function
  mm = LCase$(Left$(s, j - 1))
  knm(i) = UCase$(Mid$(s, j + 1))
  If knm(i) = "" Then Exit Function
  If mm = "z" Then
    mth(i) = 0
  ElseIf mm = "u" Then
    mth(i) = 1
  ElseIf mm = "b" Then
    mth(i) = 2
  ElseIf mm = "mz" Then
    mth(i) = 3
  ElseIf mm = "mu" Then
    mth(i) = 4
  ElseIf mm = "mb" Then
    mth(i) = 5
  Else
    Exit Function
  End If
  Layer = 1
End Function

' split s on spaces into the module parts() / np (8 at most)
Sub Split(ByVal s As String)
  Dim j As Integer, t As String Max 24
  np = 0
  s = Trim$(s)
  Do While s <> "" And np < 8
    j = InStr(s, " ")
    If j = 0 Then t = s : s = "" Else t = Left$(s, j - 1) : s = Trim$(Mid$(s, j + 1))
    If t <> "" Then parts(np) = t : np = np + 1
  Loop
End Sub

' SlotRead / SlotWrite - move bytes between this (KEYMAN) slot and the caller's slot through the
' kernel (BDOS 131 op 10): kind 3 reads the caller's memory into ours, kind 4 writes ours into the
' caller's. Chunked at 2K, within a 16K bank page. Via CybSys's own block (SetWord / Ask) so CybSys
' stays untouched. 0 done, else the op's status
Function SlotRead(ByVal slot As Integer, ByVal addr As Integer, ByVal dst As Integer, ByVal cnt As Integer) As Integer
  SlotRead = Copy10(3, slot, addr, dst, cnt)
End Function
Function SlotWrite(ByVal slot As Integer, ByVal addr As Integer, ByVal srcm As Integer, ByVal cnt As Integer) As Integer
  SlotWrite = Copy10(4, slot, addr, srcm, cnt)
End Function
Function Copy10(ByVal kind As Integer, ByVal slot As Integer, ByVal addr As Integer, ByVal mem As Integer, ByVal cnt As Integer) As Integer
  Dim cc As Integer, rr As Integer, lim As Integer
  Copy10 = 0
  Do While cnt > 0
    cc = cnt
    If cc > 2048 Then cc = 2048
    lim = 16384 - (addr And &H3FFF) : If cc > lim Then cc = lim
    lim = 16384 - (mem And &H3FFF) : If cc > lim Then cc = lim
    CybSys.SetWord 2, slot : CybSys.SetWord 4, addr : CybSys.SetWord 6, mem : CybSys.SetWord 8, cc
    rr = CybSys.Ask(10, kind)                    ' Ask sets Byte(1) = kind (3 read, 4 write)
    If rr <> 0 Then Copy10 = rr : Exit Function
    addr = addr + cc : mem = mem + cc : cnt = cnt - cc
  Loop
End Function

Function HexV(ByVal h As String) As Integer
  Dim q As Integer, c As Integer, v As Integer
  v = 0
  For q = 1 To Len(h)
    c = Asc(UCase$(Mid$(h, q, 1)))
    If c >= 65 Then c = c - 55 Else c = c - 48
    v = v * 16 + c
  Next
  HexV = v
End Function

' n (0-65535) as 4 hex digits
Function Hex4(ByVal n As Integer) As String
  Dim s As String Max 4, i As Integer, d As Integer, v As Long
  v = n And &HFFFF
  s = ""
  For i = 0 To 3
    d = (v \ (16 ^ (3 - i))) And 15
    s = s + Mid$("0123456789ABCDEF", d + 1, 1)
  Next
  Hex4 = s
End Function
