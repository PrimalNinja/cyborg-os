' Banks - CyborgOS-Next banking: the ZX Spectrum Next's 8K MMU pages as the CPC's 64K slots.
' Each 8K MMU slot (NextReg #50-#57) maps an 8K RAM page. The CPC window at #4000-#7FFF is MMU
' slots 2, 3 (NextReg #52, #53); a 16K bank = 2 pages, a 64K CyborgOS slot = 4 banks (8 pages).
' The free, consecutive banking region is 16K banks 22.. (8K pages 44..) - what Option NexData
' leaves above the program (banks 8-10), the screen (bank 5) and the low banks. NextReg writes go
' through ports #243B / #253B (no Z80N opcodes - any assembler, any harness).
' Probe once; then MapWin a 16K bank into the window to reach it. A 64K slot s (0..) is the four
' banks FIRSTBANK + s*4 .. +3.
Option Explicit
Public Const FIRSTBANK = 22                 ' first free 16K bank (page 44)
Private m_banks As Integer                  ' usable 16K banks from FIRSTBANK up (0 until Probe)

' MapWin bank: a 16K bank into #4000-#7FFF (both window slots). The caller holds interrupts off
' while it relies on the mapping (the interrupt handler may touch the window).
Public Sub MapWin(ByVal bank As Integer)
#asm
            ld a, ({bank})
            add a, a                        ; first 8K page = bank * 2
            ld d, a
            ld c, #3B
            ld b, #24
            ld a, #52
            out (c), a                      ; select MMU slot 2 (NextReg #52)
            ld b, #25
            out (c), d                      ; = page
            ld b, #24
            ld a, #53
            out (c), a                      ; select MMU slot 3 (NextReg #53)
            inc d
            ld b, #25
            out (c), d                      ; = page + 1
#endasm
End Sub

' Probe maxbanks: how many 16K banks from FIRSTBANK are real RAM (not absent / aliased). Writes a
' unique marker to #4000 of each and reads them back; the highest that still holds its own marker,
' contiguous from FIRSTBANK, is the usable top. Returns the count (also kept for Banks()).
Public Function Probe(ByVal maxbanks As Integer) As Integer
  Dim b As Integer, n As Integer
  For b = 0 To maxbanks - 1
    MapWin FIRSTBANK + b
    Poke &H4000, (b And 255)
  Next
  n = 0
  For b = 0 To maxbanks - 1
    MapWin FIRSTBANK + b
    If Peek(&H4000) = (b And 255) Then n = b + 1 Else b = maxbanks
  Next
  m_banks = n
  Probe = n
End Function

' Banks: usable 16K banks (0 until Probe). Slots: 64K slots = Banks \ 4.
Public Function Banks() As Integer
  Banks = m_banks
End Function
Public Function Slots() As Integer
  Slots = m_banks \ 4
End Function

' SlotBank slot, which: the 16K bank number for 16K piece `which` (0-3) of 64K slot `slot`
Public Function SlotBank(ByVal slot As Integer, ByVal which As Integer) As Integer
  SlotBank = FIRSTBANK + slot * 4 + which
End Function

' ---- a 64K-slot allocator (a free list over the probed slots) ----
Private m_used(31) As Byte                  ' 1 = slot taken (up to 32 slots tracked)
Private m_nslots As Integer

' Init: call after Probe. Marks every slot free.
Public Sub Init()
  Dim i As Integer
  m_nslots = Slots()
  If m_nslots > 32 Then m_nslots = 32
  For i = 0 To 31
    m_used(i) = 0
  Next
End Sub

' Alloc: a free 64K slot number, or -1 if none
Public Function Alloc() As Integer
  Dim i As Integer
  Alloc = -1
  For i = 0 To m_nslots - 1
    If m_used(i) = 0 Then m_used(i) = 1 : Alloc = i : i = m_nslots
  Next
End Function

' Free slot: give it back
Public Sub Free(ByVal slot As Integer)
  If slot >= 0 And slot < m_nslots Then m_used(slot) = 0
End Sub

' ---- cross-bank copy: n bytes from (fromslot, off) to (toslot, off), within the slots' first
'      16K bank, through a resident buffer (the window holds one bank at a time). Chunked at 256.
Private m_cbuf(255) As Byte

Public Sub Copy(ByVal fromslot As Integer, ByVal fromoff As Integer, ByVal toslot As Integer, ByVal tooff As Integer, ByVal n As Integer)
  Dim c As Integer, i As Integer, fb As Integer, tb As Integer
  fb = SlotBank(fromslot, 0)
  tb = SlotBank(toslot, 0)
  Do While n > 0
    c = n : If c > 256 Then c = 256
    MapWin fb                               ' source bank in the window
    For i = 0 To c - 1
      m_cbuf(i) = Peek(&H4000 + fromoff + i)
    Next
    MapWin tb                               ' dest bank in the window
    For i = 0 To c - 1
      Poke &H4000 + tooff + i, m_cbuf(i)
    Next
    fromoff = fromoff + c : tooff = tooff + c : n = n - c
  Loop
End Sub
