' Chain - the Pluto file encode / decode: ENC and DEC are this, one with mode 0, the other 1.
' A command line of 1-3 layers then the input and output file:
'   ENC z:mykey mu:inner in.txt out.pcb
'   DEC mu:inner z:mykey out.pcb back.txt       (the layers in the SAME order - DEC undoes last first)
' A layer is method:keyname. method: z u b (16-bit) or mz mu mb (8-bit, nibbles - key exchange,
' usually the inner layer). The key is KEYS/keyname.KEY (the ROM's bytes: its size says the kind -
' 128 bytes a microROM, more a full ROM). Encoding applies the layers left to right; decoding undoes
' them right to left. The whole input and the growing output are held in RAM, so this is for small
' files (messages, keys): INMAX in, OUTMAX out. Keys up to KEYMAX. The engine (Zc) is the one
' checked byte for byte against the PC (tools/pluto/pluto.py, and Julian's C# / protocol creator).
Option Explicit

Const INMAX = 1024                             ' the input file: bytes at most
Const OUTMAX = 4096                            ' the output (it grows through the layers)
Const KEYMAX = 8192                           ' a key: bytes at most
Const NLAYERS = 3                                   ' layers at most

Private ba(4095) As Byte                       ' two work buffers (ping-pong through the layers)
Private bb(4095) As Byte
Private kb(8191) As Byte                      ' the current layer's key
Private mth(2) As Integer                      ' each layer's method 0-5
Private knm(2) As String Max 12                ' and key name
Private nl As Integer

' No private header: a Pluto file is a plain UNSIGNAL / BRICS file (the same format the PC tools
' make and read). Fixed 128-byte records are no problem - the outer u / b layer sizes its random
' suffix (an indirected length in the spec's header) so the whole file is a multiple of 128; decode
' strips exactly that suffix, so the record padding IS the suffix and vanishes. The decode chain
' recovers the exact plaintext length itself (the data address count), so nothing extra is stored.
' (A z / mz outer layer has no suffix to pad with - wrap it in a u / b layer, or store on UniDOS
' where the length is exact.)
Const ALIGN = 128

' Run(mode): 0 encode, 1 decode. Prints what it did, or an error
Public Sub Run(ByVal mode As Integer)
  Dim tail As String Max 72, inf As String Max 16, outf As String Max 16
  Dim i As Integer, h As Integer, inlen As Integer, outlen As Integer, src As Integer, pad As Integer
  tail = Trim$(CybSys.Tail())
  If tail = "" Then
    Print "ENC / DEC layer[s] infile outfile  (layer: z|u|b|mz|mu|mb:keyname; keys in KEYS/)"
    Exit Sub
  End If
  If Parse(tail, inf, outf) = 0 Then Print "Need 1-3 layers then infile outfile" : Exit Sub
  If inf = "" Or outf = "" Then Print "Need infile and outfile" : Exit Sub
  h = FileSystem.Open(inf, FileSystem.ForReadRaw)
  If h < 0 Then Print "No such file: "; inf : Exit Sub
  inlen = FileSystem.Read(h, VarPtr(ba(0)), INMAX)
  FileSystem.Close h
  If inlen < 0 Then Print "Could not read "; inf : Exit Sub
  If inlen >= INMAX Then Print inf; " is too big (max"; INMAX; "bytes)" : Exit Sub
  src = 0 : outlen = inlen
  For i = 0 To nl - 1
    pad = 0
    If mode = 0 And i = nl - 1 And (mth(i) = 1 Or mth(i) = 2) Then pad = ALIGN   ' a 16-bit outer layer (u / b) aligns the file to 128; a micro suffix can't
    If DoLayer(mode, i, src, outlen, outlen, pad) = 0 Then Exit Sub
    src = 1 - src
  Next
  h = FileSystem.Open(outf, FileSystem.ForWrite)
  If h < 0 Then Print "Could not make "; outf : Exit Sub
  i = WriteBuf(h, src, outlen)
  FileSystem.Close h
  If mode = 0 Then Print inf; " ("; inlen; ") -> "; outf; " ("; outlen; ") encoded" Else Print inf; " -> "; outf; " ("; outlen; ") decoded"
End Sub

' write n bytes of the current buffer (ba if src=0 else bb)
Private Function WriteBuf(ByVal h As Integer, ByVal src As Integer, ByVal n As Integer) As Integer
  If src = 0 Then WriteBuf = FileSystem.Write(h, VarPtr(ba(0)), n) Else WriteBuf = FileSystem.Write(h, VarPtr(bb(0)), n)
End Function

' one layer: encode / decode buffer src (ba if src=0 else bb) of length inlen into the other,
' leaving the new length in outlen. The layer used is i for encode, (nl-1-i) for decode (undo
' last first). Loads the key. Returns 0 on error (message printed)
Private Function DoLayer(ByVal mode As Integer, ByVal i As Integer, ByVal src As Integer, ByRef inlen As Integer, ByRef outlen As Integer, ByVal pad As Integer) As Integer
  Dim li As Integer, kl As Integer, inp As Integer, outp As Integer, r As Integer
  DoLayer = 0
  li = i : If mode = 1 Then li = nl - 1 - i
  kl = LoadKey(knm(li))
  If kl <= 0 Then Print "No key KEYS/"; knm(li); ".KEY" : Exit Function
  If Zc.Open(VarPtr(kb(0)), kl, mth(li)) <> 0 Then Print "Bad key / method for "; knm(li) : Exit Function
  Zc.Pad pad
  If src = 0 Then inp = VarPtr(ba(0)) : outp = VarPtr(bb(0)) Else inp = VarPtr(bb(0)) : outp = VarPtr(ba(0))
  If mode = 0 Then r = Zc.Encode(inp, inlen, outp, OUTMAX) Else r = Zc.Decode(inp, inlen, outp, OUTMAX)
  If r < 0 Then
    If mode = 0 Then Print "Encode failed at layer "; knm(li); " (the key lacks a value the data needs?)" Else Print "Decode failed at layer "; knm(li)
    Exit Function
  End If
  outlen = r
  DoLayer = 1
End Function

' load KEYS/name.KEY into kb: its byte count, or 0 (none / too big)
Private Function LoadKey(ByVal name As String) As Integer
  Dim h As Integer, n As Integer
  LoadKey = 0
  h = FileSystem.Open("KEYS/" + name + ".KEY", FileSystem.ForReadRaw)
  If h < 0 Then Exit Function
  n = FileSystem.Read(h, VarPtr(kb(0)), KEYMAX)
  FileSystem.Close h
  If n >= KEYMAX Then Print name; ": key too big (max"; KEYMAX; "bytes)" : Exit Function
  LoadKey = n
End Function

' parse "m:k m:k ... infile outfile" into mth / knm / nl and the two file names. Returns 0 on error
Private Function Parse(ByVal tail As String, ByRef inf As String, ByRef outf As String) As Integer
  Dim parts(7) As String Max 24, np As Integer, i As Integer, j As Integer, tok As String Max 24
  np = 0
  Do While tail <> "" And np < 8
    j = InStr(tail, " ")
    If j = 0 Then tok = tail : tail = "" Else tok = Left$(tail, j - 1) : tail = Trim$(Mid$(tail, j + 1))
    If tok <> "" Then parts(np) = tok : np = np + 1
  Loop
  Parse = 0
  If np < 3 Then Exit Function                 ' at least one layer + in + out
  nl = np - 2
  If nl > NLAYERS Then Print "At most"; NLAYERS; "layers" : Exit Function
  For i = 0 To nl - 1
    If Layer(parts(i), i) = 0 Then Print "Bad layer: "; parts(i) : Exit Function
  Next
  inf = parts(np - 2)
  outf = parts(np - 1)
  Parse = 1
End Function

' one "method:keyname" into mth(i) / knm(i). Returns 0 on error
Private Function Layer(ByVal s As String, ByVal i As Integer) As Integer
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
