' Zc - the Pluto encode / decode engine, the six layers as the protocol creator and the C# do them
' (tools/pluto/pluto.py is the reference its output is checked against; the PC end decodes it).
'   z  ZOSCII        16-bit addresses into the key's bytes
'   u  UNSIGNAL      16-bit, a header (offset, prefix, suffix) and random prefix / suffix
'   b  BRICS         16-bit, UNSIGNAL's header and a block header before each block
'   mz microZOSCII   8-bit addresses into the key's nibbles (its first 128 bytes: 256 nibbles,
'                    each byte high nibble first)
'   mu microUNSIGNAL, mb microBRICS: the same with 8-bit addresses and nibbles
' The key is a byte array the caller gives (KEYMAN loads it from its store first); Open sets it
' and the method. Encode / Decode take an input array and a length, fill an output array, give the
' output length (or -1: the key lacks a value the message needs, or the input is malformed).
' One element is a message byte (16-bit) or two nibbles (micro: high then low); header values are
' low part first; offsets fold by the regime (the specs' / C#'s EffectiveSize, SlidingWindow).
Option Explicit

Const Z_Z = 0                                  ' the kinds
Const Z_U = 1
Const Z_B = 2
Const BMIN = 128                               ' a block's size, message bytes
Const Z_ERR = -1

Private m_arrKey As Integer                    ' VarPtr of the key's bytes
Private m_intKeyLen As Integer                 ' how many (a byte count; micro: nibbles = 2 * bytes, first 128 bytes)
Private m_intX As Integer                      ' elements: bytes (16-bit) or nibbles (micro)
Private m_intKind As Integer                   ' Z_Z / Z_U / Z_B
Private m_intMicro As Integer                  ' 1: nibbles, 8-bit addresses
Private m_intCap As Integer                    ' 65536 (as 0: a full 16-bit span) or 256
Private m_intAB As Integer                     ' address bytes: 2 or 1
Private m_intVB As Integer                     ' value bits: 8 or 4
Private m_intUnit As Integer                   ' elements a message byte: 1 or 2
Private m_intPMax As Integer                   ' prefix / suffix max: 255 or 15
Private m_intBMax As Integer                   ' block max: 512 or 255
Private m_intPad As Integer                    ' 0, or pad the encoded output (u / b) to a multiple of this via the suffix length

Private hd(255) As Integer                     ' header window: for each value, one chosen position (reservoir), count
Private hc(255) As Integer
Private oc(255) As Integer                     ' data window: occurrences of each value so far (reservoir counts)
Private dpos(255) As Integer                   ' and the chosen position

' Open(keyptr, keylen, method): the key and the layer. keylen is the key's byte count. method is
' 0 z, 1 u, 2 b, 3 mz, 4 mu, 5 mb. Returns 0, or Z_ERR for an empty key / bad method
Public Function Open(ByVal keyptr As Integer, ByVal keylen As Integer, ByVal method As Integer) As Integer
  Open = Z_ERR
  If keylen <= 0 Or method < 0 Or method > 5 Then Exit Function
  m_arrKey = keyptr
  m_intMicro = 0 : If method >= 3 Then m_intMicro = 1
  m_intKind = method : If method >= 3 Then m_intKind = method - 3
  If m_intMicro = 1 Then
    m_intKeyLen = keylen : If m_intKeyLen > 128 Then m_intKeyLen = 128     ' first 128 bytes = 256 nibbles
    m_intX = m_intKeyLen * 2
    m_intCap = 256 : m_intAB = 1 : m_intVB = 4 : m_intUnit = 2 : m_intPMax = 15 : m_intBMax = 255
  Else
    m_intKeyLen = keylen
    m_intX = keylen                                                        ' (0 means 65536 as a span: see Eff)
    m_intCap = 0 : m_intAB = 2 : m_intVB = 8 : m_intUnit = 1 : m_intPMax = 255 : m_intBMax = 512
  End If
  Open = 0
End Function

' Pad(n): make the next u / b Encode's output a multiple of n bytes, by choosing the suffix length
' (the suffix is random padding stripped on decode - the file stays standard UNSIGNAL / BRICS). 0 off.
' Set it before Encode; it lasts until changed. Micro suffixes (one nibble, max 15) can't align, so
' pad the outer 16-bit layer, not a micro inner one
Public Sub Pad(ByVal n As Integer)
  m_intPad = n
End Sub

' choose prefix and suffix lengths: when m_intPad > 0, sl aligns the total (baseNoPfxSfx + pl + sl) to
' m_intPad; both must be present in the header window. Returns 0 if none fits
Private Function PickPS(ByVal baseNoPfxSfx As Integer, ByVal hw As Integer, ByRef pl As Integer, ByRef sl As Integer) As Integer
  Dim p As Integer, need As Integer, b As Integer
  PickPS = 0
  If m_intPad <= 0 Then
    pl = RandVal(10, m_intPMax, 1, hw)
    sl = RandVal(10, m_intPMax, 1, hw)
    If pl >= 0 And sl >= 0 Then PickPS = 1
    Exit Function
  End If
  For p = 10 To m_intPMax
    If Present(0, hw, p) = 1 Then
      b = baseNoPfxSfx + p
      need = (m_intPad - (b Mod m_intPad)) Mod m_intPad
      Do While need < 10
        need = need + m_intPad
      Loop
      If need <= m_intPMax Then
        If Present(0, hw, need) = 1 Then
          pl = p : sl = need : PickPS = 1 : Exit Function
        End If
      End If
    End If
  Next
End Function

' the element value at position p (a key byte, or a nibble - high nibble of byte p\2 first)
Private Function El(ByVal p As Integer) As Integer
  Dim b As Integer
  If m_intMicro = 0 Then
    El = Peek(m_arrKey + p)
  Else
    b = Peek(m_arrKey + p \ 2)
    If (p And 1) = 0 Then El = (b \ 16) And 15 Else El = b And 15
  End If
End Function

' the effective span and window for this key size (the specs' regime). Cap is 65536 (m_intCap 0)
' or 256. Returns the window in w; the function result is the effective size
Private Function Eff(ByRef w As Integer) As Integer
  Dim x As Long, cap As Long, pct As Long, t1 As Long, es As Long, win As Long
  If m_intCap = 0 Then cap = 65536 Else cap = m_intCap
  x = m_intX : If m_intMicro = 0 And m_intX = 0 Then x = 65536
  If m_intMicro = 0 Then x = m_intKeyLen
  pct = (x * 2) \ 100
  t1 = cap + (cap * 2) \ 100
  es = cap : win = cap
  If x < t1 Then
    es = x - pct : win = pct
  ElseIf x < cap * 2 Then
    es = cap : win = cap * 2 - x - pct
  End If
  If win < 0 Then win = 0
  w = win And &HFFFF
  Eff = es And &HFFFF
End Function

' v (a signed 16-bit value) as an unsigned Long 0-65535
Private Function Usg(ByVal v As Integer) As Long
  If v < 0 Then Usg = v + 65536 Else Usg = v
End Function

' offset = ptr mod (window + 1) (0 when the window is 0). ptr arrives as a signed 16-bit value
' (GetVal gives offsets > 32767 as negatives), so take it unsigned first
Private Function Offset(ByVal ptr As Integer, ByVal win As Integer) As Integer
  Dim p As Long, m As Long
  If win = 0 Then
    Offset = 0
  Else
    p = Usg(ptr) : m = Usg(win) + 1
    Offset = (p Mod m) And &HFFFF
  End If
End Function

' a key position's element, folded into the key (addr mod effective, then into the key length) -
' decode's dereference. lo is the window's start (the offset)
Private Function Deref(ByVal lo As Integer, ByVal addr As Integer, ByVal es As Integer) As Integer
  Dim a As Long, e As Long, k As Long, p As Long
  a = addr And &HFFFF
  If m_intKind <> Z_Z Then
    e = es And &HFFFF : If e > 0 Then a = a Mod e
    a = a + (lo And &HFFFF)
  End If
  k = m_intX : If m_intMicro = 0 And m_intX = 0 Then k = 65536
  If m_intMicro = 0 Then k = m_intKeyLen
  If k > 0 Then a = a Mod k
  Deref = El(a And &HFFFF)
End Function

' a random position in [lo, hi) holding val (two passes); -1 none
Private Function ScanPick(ByVal lo As Integer, ByVal hi As Integer, ByVal val As Integer) As Integer
  Dim p As Integer, n As Integer, t As Integer
  n = 0
  For p = lo To hi - 1
    If El(p) = val Then n = n + 1
  Next
  If n = 0 Then ScanPick = -1 : Exit Function
  t = Rnd(n)
  For p = lo To hi - 1
    If El(p) = val Then
      If t = 0 Then ScanPick = p : Exit Function
      t = t - 1
    End If
  Next
  ScanPick = -1
End Function

' is val present in [lo, hi)?
Private Function Present(ByVal lo As Integer, ByVal hi As Integer, ByVal val As Integer) As Integer
  Dim p As Integer
  Present = 0
  For p = lo To hi - 1
    If El(p) = val Then Present = 1 : Exit Function
  Next
End Function

' write value as parts addresses (each a header-window position holding one vbits part, low first);
' pos on. -1 the key can't carry it
Private Function PutVal(ByVal outptr As Integer, ByVal pos As Integer, ByVal val As Integer, ByVal parts As Integer, ByVal hw As Integer) As Integer
  Dim i As Integer, part As Integer, a As Integer, mask As Integer
  mask = (1 * 2 ^ m_intVB) - 1
  For i = 0 To parts - 1
    part = (val \ (2 ^ (m_intVB * i))) And mask
    a = ScanPick(0, hw, part)
    If a < 0 Then PutVal = -1 : Exit Function
    Poke outptr + pos, a And 255
    If m_intAB = 2 Then Poke outptr + pos + 1, (a \ 256) And 255
    pos = pos + m_intAB
  Next
  PutVal = pos
End Function

' read a value: parts addresses, each dereferenced to vbits, composed low first
Private Function GetVal(ByVal inptr As Integer, ByVal pos As Integer, ByVal parts As Integer) As Integer
  Dim i As Integer, a As Integer, v As Long, k As Integer, mul As Long, ev As Long
  v = 0
  k = m_intX                                   ' element count: nibbles (micro) or bytes
  For i = 0 To parts - 1
    a = Peek(inptr + pos)
    If m_intAB = 2 Then a = a + Peek(inptr + pos + 1) * 256
    mul = 1
    If i > 0 Then mul = 2 ^ (m_intVB * i)
    ev = El((a And &HFFFF) Mod k)
    v = v + ev * mul
    pos = pos + m_intAB
  Next
  GetVal = v And &HFFFF
End Function

' put one data address (window-relative for u/b, absolute for z): low byte first
Private Sub PutAddr(ByVal outptr As Integer, ByVal pos As Integer, ByVal a As Integer)
  Poke outptr + pos, a And 255
  If m_intAB = 2 Then Poke outptr + pos + 1, (a \ 256) And 255
End Sub

' a random header value in [lo, hi] the header window can carry (parts all present)
Private Function RandVal(ByVal lo As Integer, ByVal hi As Integer, ByVal parts As Integer, ByVal hw As Integer) As Integer
  Dim v As Integer, tries As Integer, i As Integer, part As Integer, ok As Integer, mask As Integer
  mask = (1 * 2 ^ m_intVB) - 1
  For tries = 0 To 3999
    v = lo + Rnd(hi - lo + 1)
    ok = 1
    For i = 0 To parts - 1
      part = (v \ (2 ^ (m_intVB * i))) And mask
      If Present(0, hw, part) = 0 Then ok = 0
    Next
    If ok = 1 Then RandVal = v : Exit Function
  Next
  RandVal = -1
End Function

' Encode inlen bytes at inptr into outptr (room outmax): the output length, or Z_ERR
Public Function Encode(ByVal inptr As Integer, ByVal inlen As Integer, ByVal outptr As Integer, ByVal outmax As Integer) As Integer
  Dim pos As Integer, i As Integer, j As Integer, v As Integer, a As Integer, hw As Integer
  Dim es As Integer, win As Integer, lo As Integer, ptr As Integer, pl As Integer, sl As Integer
  Dim tries As Integer, ok As Integer, bs As Integer, bstart As Integer, ne As Integer, nb As Integer
  Encode = Z_ERR
  es = Eff(win)
  hw = m_intKeyLen * m_intUnit : If m_intCap <> 0 And hw > m_intCap Then hw = m_intCap
  If m_intCap = 0 And hw > m_intKeyLen Then hw = m_intKeyLen
  pos = 0
  If m_intKind = Z_Z Then
    For i = 0 To inlen - 1
      For j = 0 To m_intUnit - 1
        v = Elem(inptr, i, j)
        a = ScanPick(0, hw, v)
        If a < 0 Then Exit Function
        If pos + m_intAB > outmax Then Exit Function
        PutAddr outptr, pos, a
        pos = pos + m_intAB
      Next
    Next
  ElseIf m_intKind = Z_U Then
    lo = PickOffset(inptr, 0, inlen, es, win)
    If lo < 0 Then Exit Function
    ptr = m_intLastPtr
    If PickPS(4 * m_intAB + inlen * m_intUnit * m_intAB, hw, pl, sl) = 0 Then Exit Function
    pos = PutVal(outptr, pos, ptr, 2, hw)
    If pos < 0 Then Exit Function
    pos = PutVal(outptr, pos, pl, 1, hw)
    If pos < 0 Then Exit Function
    pos = PutVal(outptr, pos, sl, 1, hw)
    If pos < 0 Then Exit Function
    For i = 0 To pl - 1
      Poke outptr + pos, Rnd(256) : pos = pos + 1
    Next
    For i = 0 To inlen - 1
      For j = 0 To m_intUnit - 1
        v = Elem(inptr, i, j)
        a = ScanPick(lo, lo + es, v)
        If a < 0 Then Exit Function
        If pos + m_intAB > outmax Then Exit Function
        PutAddr outptr, pos, a - lo
        pos = pos + m_intAB
      Next
    Next
    For i = 0 To sl - 1
      Poke outptr + pos, Rnd(256) : pos = pos + 1
    Next
  Else
    pos = EncB(inptr, inlen, outptr, outmax, es, win, hw)
    If pos < 0 Then Exit Function
  End If
  Encode = pos
End Function

' BRICS encode: blocks, each its own offset. Returns the length or -1
Private Function EncB(ByVal inptr As Integer, ByVal inlen As Integer, ByVal outptr As Integer, ByVal outmax As Integer, ByVal es As Integer, ByVal win As Integer, ByVal hw As Integer) As Integer
  Dim pos As Integer, i As Integer, j As Integer, v As Integer, a As Integer, pl As Integer, sl As Integer
  Dim bstart As Integer, bs As Integer, nb As Integer, lo As Integer
  Dim bstarts(63) As Integer, bsizes(63) As Integer, blos(63) As Integer, bptrs(63) As Integer
  pos = 0 : nb = 0 : bstart = 0
  Do While bstart < inlen Or nb = 0
    bs = BMIN + Rnd(m_intBMax - BMIN + 1)
    If bs > inlen - bstart Then bs = inlen - bstart
    lo = PickOffset(inptr, bstart, bstart + bs, es, win)
    If lo < 0 Then EncB = -1 : Exit Function
    bstarts(nb) = bstart : bsizes(nb) = bs : blos(nb) = lo : bptrs(nb) = m_intLastPtr
    bstart = bstart + bs : nb = nb + 1
    If nb > 63 Then EncB = -1 : Exit Function
  Loop
  If PickPS(6 * m_intAB + nb * 4 * m_intAB + inlen * m_intUnit * m_intAB, hw, pl, sl) = 0 Then EncB = -1 : Exit Function
  pos = PutVal(outptr, pos, bptrs(0), 2, hw)
  If pos < 0 Then EncB = -1 : Exit Function
  pos = PutVal(outptr, pos, bsizes(0), 2, hw)
  If pos < 0 Then EncB = -1 : Exit Function
  pos = PutVal(outptr, pos, pl, 1, hw)
  If pos < 0 Then EncB = -1 : Exit Function
  pos = PutVal(outptr, pos, sl, 1, hw)
  If pos < 0 Then EncB = -1 : Exit Function
  For i = 0 To pl - 1
    Poke outptr + pos, Rnd(256) : pos = pos + 1
  Next
  For i = 0 To nb - 1
    If i + 1 < nb Then
      pos = PutVal(outptr, pos, bptrs(i + 1), 2, hw)
      If pos < 0 Then EncB = -1 : Exit Function
      pos = PutVal(outptr, pos, bsizes(i + 1), 2, hw)
      If pos < 0 Then EncB = -1 : Exit Function
    Else
      pos = PutVal(outptr, pos, RandVal(0, m_intBMax, 2, hw), 2, hw)
      If pos < 0 Then EncB = -1 : Exit Function
      pos = PutVal(outptr, pos, RandVal(0, m_intBMax, 2, hw), 2, hw)
      If pos < 0 Then EncB = -1 : Exit Function
    End If
    lo = blos(i)
    For j = bstarts(i) To bstarts(i) + bsizes(i) - 1
      For v = 0 To m_intUnit - 1
        a = ScanPick(lo, lo + es, Elem(inptr, j, v))
        If a < 0 Then EncB = -1 : Exit Function
        If pos + m_intAB > outmax Then EncB = -1 : Exit Function
        PutAddr outptr, pos, a - lo
        pos = pos + m_intAB
      Next
    Next
  Next
  For i = 0 To sl - 1
    Poke outptr + pos, Rnd(256) : pos = pos + 1
  Next
  EncB = pos
End Function

Private m_intLastPtr As Integer                ' PickOffset leaves the chosen pointer here

' element j (0..unit-1) of message byte i at inptr: the byte (16-bit), or its high / low nibble
Private Function Elem(ByVal inptr As Integer, ByVal i As Integer, ByVal j As Integer) As Integer
  Dim b As Integer
  b = Peek(inptr + i)
  If m_intMicro = 0 Then
    Elem = b
  ElseIf j = 0 Then
    Elem = (b \ 16) And 15
  Else
    Elem = b And 15
  End If
End Function

' pick an offset whose window [lo, lo+es) holds every element value of message[start, end);
' leaves the pointer in m_intLastPtr. Returns lo, or -1
Private Function PickOffset(ByVal inptr As Integer, ByVal start As Integer, ByVal fin As Integer, ByVal es As Integer, ByVal win As Integer) As Integer
  Dim tries As Integer, ptr As Integer, lo As Integer, i As Integer, j As Integer, ok As Integer, hw As Integer
  hw = m_intKeyLen * m_intUnit : If m_intCap <> 0 And hw > m_intCap Then hw = m_intCap
  If m_intCap = 0 And hw > m_intKeyLen Then hw = m_intKeyLen
  For tries = 0 To 299
    ptr = RandVal(0, win, 2, hw)               ' a pointer in [0, win]: offset = ptr (ptr mod win+1), small - no 16-bit overflow
    If ptr < 0 Then PickOffset = -1 : Exit Function
    lo = Offset(ptr, win)
    ok = 1
    For i = start To fin - 1
      For j = 0 To m_intUnit - 1
        If Present(lo, lo + es, Elem(inptr, i, j)) = 0 Then ok = 0
      Next
    Next
    If ok = 1 Then m_intLastPtr = ptr : PickOffset = lo : Exit Function
  Next
  PickOffset = -1
End Function

' the cap as a value to pass to RandVal's hi (cap - 1): 65535 or 255
Private Function m_intCapV() As Integer
  If m_intCap = 0 Then m_intCapV = &HFFFF Else m_intCapV = m_intCap - 1
End Function

' Decode inlen bytes at inptr into outptr: the message length, or Z_ERR
Public Function Decode(ByVal inptr As Integer, ByVal inlen As Integer, ByVal outptr As Integer, ByVal outmax As Integer) As Integer
  Dim pos As Integer, es As Integer, win As Integer, lo As Integer, pl As Integer, sl As Integer
  Dim fin As Integer, a As Integer, ne As Integer, nelem As Integer
  Dim sz As Integer, nptr As Integer, nsz As Integer, i As Integer, got As Integer
  Decode = Z_ERR
  es = Eff(win)
  nelem = 0
  If m_intKind = Z_Z Then
    pos = 0
    Do While pos + m_intAB <= inlen
      a = ReadAddr(inptr, pos)
      ne = Deref(0, a, es)
      If StoreElem(outptr, nelem, ne, outmax) = 0 Then Exit Function
      nelem = nelem + 1
      pos = pos + m_intAB
    Loop
  ElseIf m_intKind = Z_U Then
    If inlen < 4 * m_intAB Then Exit Function
    lo = Offset(GetVal(inptr, 0, 2), win)
    pl = GetVal(inptr, 2 * m_intAB, 1)
    sl = GetVal(inptr, 3 * m_intAB, 1)
    pos = 4 * m_intAB + pl
    fin = inlen - sl
    Do While pos + m_intAB <= fin
      a = ReadAddr(inptr, pos)
      ne = Deref(lo, a, es)
      If StoreElem(outptr, nelem, ne, outmax) = 0 Then Exit Function
      nelem = nelem + 1
      pos = pos + m_intAB
    Loop
  Else
    If inlen < 6 * m_intAB Then Exit Function
    lo = Offset(GetVal(inptr, 0, 2), win)
    sz = GetVal(inptr, 2 * m_intAB, 2)
    pl = GetVal(inptr, 4 * m_intAB, 1)
    sl = GetVal(inptr, 5 * m_intAB, 1)
    pos = 6 * m_intAB + pl
    fin = inlen - sl
    Do While pos + 4 * m_intAB <= fin
      nptr = GetVal(inptr, pos, 2)
      nsz = GetVal(inptr, pos + 2 * m_intAB, 2)
      pos = pos + 4 * m_intAB
      For i = 0 To sz * m_intUnit - 1
        If pos + m_intAB <= fin Then
          a = ReadAddr(inptr, pos)
          ne = Deref(lo, a, es)
          If StoreElem(outptr, nelem, ne, outmax) = 0 Then Exit Function
          nelem = nelem + 1
        End If
        pos = pos + m_intAB
      Next
      lo = Offset(nptr, win)
      sz = nsz
    Loop
  End If
  If m_intMicro = 1 Then Decode = nelem \ 2 Else Decode = nelem
End Function

' read a data address at pos
Private Function ReadAddr(ByVal inptr As Integer, ByVal pos As Integer) As Integer
  Dim a As Integer
  a = Peek(inptr + pos)
  If m_intAB = 2 Then a = a + Peek(inptr + pos + 1) * 256
  ReadAddr = a
End Function

' store decoded element ne as the nelem'th: micro combines two nibbles (high first) into a byte.
' Returns 0 if out of room
Private Function StoreElem(ByVal outptr As Integer, ByVal nelem As Integer, ByVal ne As Integer, ByVal outmax As Integer) As Integer
  Dim bi As Integer, prev As Integer
  StoreElem = 1
  If m_intMicro = 0 Then
    If nelem >= outmax Then StoreElem = 0 : Exit Function
    Poke outptr + nelem, ne And 255
  Else
    bi = nelem \ 2
    If bi >= outmax Then StoreElem = 0 : Exit Function
    If (nelem And 1) = 0 Then
      Poke outptr + bi, (ne And 15) * 16
    Else
      prev = Peek(outptr + bi)
      Poke outptr + bi, prev Or (ne And 15)
    End If
  End If
End Function
