' SlotFrame: a stopped slot's registers in a form any CyborgOS machine can rebuild - for DUMP / REVIVE,
' RMOVE / RCOPY and SLOTD, so a slot moves between a CPC and a vCPC (either way) as between two of a
' kind. A stopped slot keeps its registers on its own stack, the stack pointer at #FFFE; each machine
' lays that frame out its own way:
'   CPC (its bank's stubs) - top word sb_rest: an interrupt - IY IX HL' DE' BC' AF' HL DE BC AF, then
'     the PC; top word sb_far: waiting for a BDOS answer - HL' DE' BC' AF' IY IX, then the call's
'     return (A / HL: the answer, given back by the kernel). C0's op 42 says where sb_rest / sb_far are
'   vCPC - interrupt flags, IR, HL' DE' BC' AF' IY IX HL DE BC AF, PC (always all of them); a call
'     waiting: its byte at #EF48 (1), the call's return under the frame
' Canon(slot, hd): the frame read into the header (hd 52 the kind: 1 an interrupt, 2 a call; 53 the
'   PC or the call's return; 55 the program's own stack pointer; 57 AF BC DE HL AF' BC' DE' HL' IX
'   IY) - 0 when it can't be (stopped some other way: a key's wait being tried again - try again)
' Native(slot, hd): that frame built the way this machine keeps it, #FFFE set - 0 done
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit

Const FR_KIND = 52
Const FR_PC = 53
Const FR_SP = 55
Const FR_REG = 57                       ' AF BC DE HL AF' BC' DE' HL' IX IY: 2 bytes each

Dim m_byW(3) As Byte
Dim m_lngRest As Long, m_lngFar As Long

' ---- the frame read

Public Function Canon(ByVal intS_a As Integer, byHd_a() As Byte) As Integer
  Dim lngSp As Long, lngTop As Long, intKind As Integer, lngAfter As Long
  intKind = 0
  lngSp = RW(intS_a, &HFFFE&)
  If lngSp < &H100& Or lngSp > &HFFE0& Then                   ' (a frame lies in the slot's own RAM, under
    byHd_a(FR_KIND) = 0 : Canon = 0 : Exit Function           ' #FFFE: anything else isn't one - 2026-11-01)
  End If
  If CybSys.Host() = 4 Then                                   ' the vCPC's
    lngAfter = lngSp + 26                                     ' (flags +0, IR +2, then:)
    PutReg byHd_a, 9, RW(intS_a, lngSp + 12)                  ' IY
    PutReg byHd_a, 8, RW(intS_a, lngSp + 14)                  ' IX
    PutReg byHd_a, 0, RW(intS_a, lngSp + 22)                  ' AF
    PutReg byHd_a, 1, RW(intS_a, lngSp + 20)                  ' BC
    PutReg byHd_a, 2, RW(intS_a, lngSp + 18)                  ' DE
    PutReg byHd_a, 3, RW(intS_a, lngSp + 16)                  ' HL
    PutReg byHd_a, 4, RW(intS_a, lngSp + 10)                  ' AF'
    PutReg byHd_a, 5, RW(intS_a, lngSp + 8)                   ' BC'
    PutReg byHd_a, 6, RW(intS_a, lngSp + 6)                   ' DE'
    PutReg byHd_a, 7, RW(intS_a, lngSp + 4)                   ' HL'
    If RB(intS_a, &HEF48&) = 0 Then                           ' running: an interrupt's frame
      intKind = 1
      PutW byHd_a, FR_PC, RW(intS_a, lngSp + 24)
      PutW byHd_a, FR_SP, lngAfter
    ElseIf RB(intS_a, &HEF48&) = 1 Then                       ' a call waiting for its answer
      intKind = 2
      PutW byHd_a, FR_PC, RW(intS_a, lngAfter)                ' (the call's return, under the frame)
      PutW byHd_a, FR_SP, lngAfter + 2
    End If
  Else                                                        ' the CPC's (its stubs)
    Points
    lngTop = RW(intS_a, lngSp)
    If lngTop = m_lngRest And m_lngRest <> 0 Then
      intKind = 1
      PutReg byHd_a, 9, RW(intS_a, lngSp + 2)                 ' IY
      PutReg byHd_a, 8, RW(intS_a, lngSp + 4)                 ' IX
      PutReg byHd_a, 7, RW(intS_a, lngSp + 6)                 ' HL'
      PutReg byHd_a, 6, RW(intS_a, lngSp + 8)                 ' DE'
      PutReg byHd_a, 5, RW(intS_a, lngSp + 10)                ' BC'
      PutReg byHd_a, 4, RW(intS_a, lngSp + 12)                ' AF'
      PutReg byHd_a, 3, RW(intS_a, lngSp + 14)                ' HL
      PutReg byHd_a, 2, RW(intS_a, lngSp + 16)                ' DE
      PutReg byHd_a, 1, RW(intS_a, lngSp + 18)                ' BC
      PutReg byHd_a, 0, RW(intS_a, lngSp + 20)                ' AF
      PutW byHd_a, FR_PC, RW(intS_a, lngSp + 22)
      PutW byHd_a, FR_SP, lngSp + 24
    ElseIf lngTop = m_lngFar And m_lngFar <> 0 Then
      intKind = 2
      PutReg byHd_a, 7, RW(intS_a, lngSp + 2)                 ' HL'
      PutReg byHd_a, 6, RW(intS_a, lngSp + 4)                 ' DE'
      PutReg byHd_a, 5, RW(intS_a, lngSp + 6)                 ' BC'
      PutReg byHd_a, 4, RW(intS_a, lngSp + 8)                 ' AF'
      PutReg byHd_a, 9, RW(intS_a, lngSp + 10)                ' IY
      PutReg byHd_a, 8, RW(intS_a, lngSp + 12)                ' IX
      PutReg byHd_a, 0, 0 : PutReg byHd_a, 1, 0 : PutReg byHd_a, 2, 0 : PutReg byHd_a, 3, 0   ' (the answer: the kernel's)
      PutW byHd_a, FR_PC, RW(intS_a, lngSp + 14)
      PutW byHd_a, FR_SP, lngSp + 16
    End If
  End If
  byHd_a(FR_KIND) = intKind
  Canon = intKind
End Function

' ---- the frame built

Public Function Native(ByVal intS_a As Integer, byHd_a() As Byte) As Integer
  Dim intKind As Integer, lngSp As Long, lngPc As Long, lngP As Long, intR As Integer
  intR = 1
  intKind = byHd_a(FR_KIND)
  lngSp = GetW(byHd_a, FR_SP)
  lngPc = GetW(byHd_a, FR_PC)
  If CybSys.Host() = 4 Then                                   ' the vCPC's: always the whole frame
    If intKind = 1 Or intKind = 2 Then
      If intKind = 2 Then
        lngSp = lngSp - 2
        WWr intS_a, lngSp, lngPc                              ' the call's return
        lngPc = &HEF00&                                       ' (its BDOS: the answer given there)
      End If
      lngP = lngSp - 26
      WWr intS_a, lngP, &H13&                                 ' interrupts on, IM 1
      WWr intS_a, lngP + 2, 0                                 ' I, R
      WWr intS_a, lngP + 4, GetReg(byHd_a, 7)                 ' HL'
      WWr intS_a, lngP + 6, GetReg(byHd_a, 6)                 ' DE'
      WWr intS_a, lngP + 8, GetReg(byHd_a, 5)                 ' BC'
      WWr intS_a, lngP + 10, GetReg(byHd_a, 4)                ' AF'
      WWr intS_a, lngP + 12, GetReg(byHd_a, 9)                ' IY
      WWr intS_a, lngP + 14, GetReg(byHd_a, 8)                ' IX
      WWr intS_a, lngP + 16, GetReg(byHd_a, 3)                ' HL
      WWr intS_a, lngP + 18, GetReg(byHd_a, 2)                ' DE
      WWr intS_a, lngP + 20, GetReg(byHd_a, 1)                ' BC
      WWr intS_a, lngP + 22, GetReg(byHd_a, 0)                ' AF
      WWr intS_a, lngP + 24, lngPc
      WBr intS_a, &HEF48&, IIf(intKind = 2, 1, 0)             ' a call waiting, or not
      WWr intS_a, &HFFFE&, lngP
      intR = 0
    End If
  Else                                                        ' the CPC's
    Points
    If intKind = 1 And m_lngRest <> 0 Then
      lngP = lngSp - 24
      WWr intS_a, lngP, m_lngRest
      WWr intS_a, lngP + 2, GetReg(byHd_a, 9)                 ' IY
      WWr intS_a, lngP + 4, GetReg(byHd_a, 8)                 ' IX
      WWr intS_a, lngP + 6, GetReg(byHd_a, 7)                 ' HL'
      WWr intS_a, lngP + 8, GetReg(byHd_a, 6)                 ' DE'
      WWr intS_a, lngP + 10, GetReg(byHd_a, 5)                ' BC'
      WWr intS_a, lngP + 12, GetReg(byHd_a, 4)                ' AF'
      WWr intS_a, lngP + 14, GetReg(byHd_a, 3)                ' HL
      WWr intS_a, lngP + 16, GetReg(byHd_a, 2)                ' DE
      WWr intS_a, lngP + 18, GetReg(byHd_a, 1)                ' BC
      WWr intS_a, lngP + 20, GetReg(byHd_a, 0)                ' AF
      WWr intS_a, lngP + 22, lngPc
      WWr intS_a, &HFFFE&, lngP
      intR = 0
    ElseIf intKind = 2 And m_lngFar <> 0 Then
      lngP = lngSp - 16
      WWr intS_a, lngP, m_lngFar
      WWr intS_a, lngP + 2, GetReg(byHd_a, 7)                 ' HL'
      WWr intS_a, lngP + 4, GetReg(byHd_a, 6)                 ' DE'
      WWr intS_a, lngP + 6, GetReg(byHd_a, 5)                 ' BC'
      WWr intS_a, lngP + 8, GetReg(byHd_a, 4)                 ' AF'
      WWr intS_a, lngP + 10, GetReg(byHd_a, 9)                ' IY
      WWr intS_a, lngP + 12, GetReg(byHd_a, 8)                ' IX
      WWr intS_a, lngP + 14, lngPc                            ' the call's return
      WWr intS_a, &HFFFE&, lngP
      intR = 0
    End If
  End If
  Native = intR
End Function

' LastNZ(p, n): the index of the last byte that isn't 0 in the n bytes at p, -1 none - the trim's
' scan (DUMP, RCOPY) in Z80: a byte at a time in BASIC took 20 seconds on a CPC for a mostly empty TPA
Public Function LastNZ(ByVal intP_a As Integer, ByVal intN_a As Integer) As Integer
#asm
            ld hl, ({intP_a})
            ld bc, ({intN_a})
            add hl, bc
            dec hl                  ; the last byte
ln_l:       ld a, b
            or c
            jr z, ln_none
            ld a, (hl)
            or a
            jr nz, ln_f
            dec hl
            dec bc
            jr ln_l
ln_f:       dec bc                  ; its index: BC - 1
            ld ({result}), bc
            jr ln_e
ln_none:    ld hl, -1
            ld ({result}), hl
ln_e:
#endasm
End Function

' ---- inside

' the CPC stubs' resume points (C0's op 42: 255 on a machine without stubs - the vCPC)
Private Sub Points()
  CybSys.SetWord 2, 0 : CybSys.SetWord 4, 0
  If CybSys.Ask(42, 0) = 0 Then
    m_lngRest = CLng(CybSys.WordAt(2)) And 65535
    m_lngFar = CLng(CybSys.WordAt(4)) And 65535
  Else
    m_lngRest = 0 : m_lngFar = 0
  End If
End Sub

Private Function RW(ByVal intS_a As Integer, ByVal lngA_a As Long) As Long
  CybSys.SetWord 2, intS_a : CybSys.SetWord 4, W16(lngA_a) : CybSys.SetWord 6, VarPtr(m_byW) : CybSys.SetWord 8, 2
  m_byW(0) = 0 : m_byW(1) = 0
  If CybSys.Ask(10, 3) = 0 Then RW = CLng(m_byW(0)) + CLng(m_byW(1)) * 256& Else RW = 0
End Function

Private Function RB(ByVal intS_a As Integer, ByVal lngA_a As Long) As Integer
  RB = CInt(RW(intS_a, lngA_a) And 255)
End Function

Private Sub WWr(ByVal intS_a As Integer, ByVal lngA_a As Long, ByVal lngV_a As Long)
  Dim intR As Integer
  m_byW(0) = CInt(lngV_a And 255) : m_byW(1) = CInt((lngV_a \ 256) And 255)
  CybSys.SetWord 2, intS_a : CybSys.SetWord 4, W16(lngA_a) : CybSys.SetWord 6, VarPtr(m_byW) : CybSys.SetWord 8, 2
  intR = CybSys.Ask(10, 4)
End Sub

Private Sub WBr(ByVal intS_a As Integer, ByVal lngA_a As Long, ByVal intV_a As Integer)
  Dim intR As Integer
  m_byW(0) = intV_a
  CybSys.SetWord 2, intS_a : CybSys.SetWord 4, W16(lngA_a) : CybSys.SetWord 6, VarPtr(m_byW) : CybSys.SetWord 8, 1
  intR = CybSys.Ask(10, 4)
End Sub

Private Sub PutReg(byHd_a() As Byte, ByVal intN_a As Integer, ByVal lngV_a As Long)
  PutW byHd_a, FR_REG + intN_a * 2, lngV_a
End Sub

Private Function GetReg(byHd_a() As Byte, ByVal intN_a As Integer) As Long
  GetReg = GetW(byHd_a, FR_REG + intN_a * 2)
End Function

Private Sub PutW(byHd_a() As Byte, ByVal intAt_a As Integer, ByVal lngV_a As Long)
  byHd_a(intAt_a) = CInt(lngV_a And 255) : byHd_a(intAt_a + 1) = CInt((lngV_a \ 256) And 255)
End Sub

Private Function GetW(byHd_a() As Byte, ByVal intAt_a As Integer) As Long
  Dim intL As Integer, intH As Integer
  intL = byHd_a(intAt_a) : intH = byHd_a(intAt_a + 1)       ' (into variables first: CLng(arr(i + 1)) * 256&
  GetW = CLng(intL) + CLng(intH) * 256&                    ' on an array parameter read element 0 - NTC's
                                                           ' compiler fixed 2026-11-01; kept, as clear)
End Function

Private Function W16(ByVal lngV_a As Long) As Integer
  Dim lngV As Long
  lngV = lngV_a And 65535
  If lngV > 32767 Then W16 = CInt(lngV - 65536&) Else W16 = CInt(lngV)
End Function
