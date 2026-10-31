' Nx - the ZX Spectrum Next's own hardware, straight on the ports: NextRegs (#243B select,
' #253B value), the layer order, the border, palettes, the CPU speed.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
' RATBOXN's copy of THE LITTLE SEOUL ENGINE's Nx.cls (the hardware helpers and the CyborgOS task
' routines: WaitFrame, Snap / Back, ConSave / ConIn / ConOut, Yield, Front, TaskInit) - its own
' copy, so changes to the engine's don't land here.
' No Z80N opcodes are used (plain out (c)), so any Z80 assembler builds it.
Option Explicit

' layer orders (NextReg #15 bits 4-2): first = on top. S sprites, L Layer 2, U ULA + tilemap
Public Const OrderSLU = 0
Public Const OrderLSU = 1
Public Const OrderSUL = 2
Public Const OrderLUS = 3
Public Const OrderUSL = 4
Public Const OrderULS = 5
' palettes for PalEntry / PalTable (NextReg #43 bits 6-4, the first of each pair)
Public Const PalULA = 0
Public Const PalLayer2 = 1
Public Const PalSprites = 2
Public Const PalTiles = 3

' Reg r, v: NextReg r = v
Public Sub Reg(ByVal r As Integer, ByVal v As Integer)
#asm
            pop hl
            ld a, (hl)
            pop hl
            ld e, (hl)
            ld bc, #243B
            out (c), a
            inc b
            out (c), e
#endasm
End Sub

' RegGet(r): NextReg r read back
Public Function RegGet(ByVal r As Integer) As Integer
#asm
            pop hl
            ld a, (hl)
            ld bc, #243B
            out (c), a
            inc b
            in e, (c)
            pop hl
            ld (hl), e
            inc hl
            ld (hl), 0
#endasm
End Function

' Layers order: which layer is on top (OrderSLU ...), sprites on and over the border kept
Public Sub Layers(ByVal order As Integer)
#asm
            pop hl
            ld a, (hl)
            and 7
            add a, a
            add a, a
            ld e, a
            ld bc, #243B
            ld a, #15
            out (c), a
            inc b
            in a, (c)
            and %11100011
            or e
            out (c), a
#endasm
End Sub

' Border c: the border colour (0-7, port #FE)
Public Sub Border(ByVal c As Integer)
#asm
            pop hl
            ld a, (hl)
            and 7
            out (#FE), a
#endasm
End Sub

' PalEntry which, index, colour: one colour (RRRGGGBB) of a palette (PalULA ... PalTiles, the
' first palette of each)
Public Sub PalEntry(ByVal which As Integer, ByVal index As Integer, ByVal colour As Integer)
#asm
            pop hl
            ld a, (hl)
            and 3
            rlca
            rlca
            rlca
            rlca
            ld d, a                 ; palette select, bits 6-4
            pop hl
            ld e, (hl)              ; index
            pop hl
            ld l, (hl)              ; colour
            ld bc, #243B
            ld a, #43
            out (c), a
            inc b
            out (c), d
            dec b
            ld a, #40
            out (c), a
            inc b
            out (c), e
            dec b
            ld a, #41
            out (c), a
            inc b
            out (c), l
            dec b
            ld a, #43
            out (c), a
            inc b
            xor a
            out (c), a
#endasm
End Sub

' PalTable which, first, count, address: count colours (1 byte each, RRRGGGBB) from memory
Public Sub PalTable(ByVal which As Integer, ByVal first As Integer, ByVal count As Integer, ByVal address As Integer)
#asm
            pop hl
            ld a, (hl)
            and 3
            rlca
            rlca
            rlca
            rlca
            ld d, a
            pop hl
            ld e, (hl)
            ld bc, #243B
            ld a, #43
            out (c), a
            inc b
            out (c), d
            dec b
            ld a, #40
            out (c), a
            inc b
            out (c), e
            dec b
            pop hl
            ld e, (hl)              ; count (1-256: 0 = 256)
            pop hl
            ld a, (hl)
            inc hl
            ld h, (hl)
            ld l, a
            ld a, #41
            out (c), a
            inc b
pt_lp:
            ld a, (hl)
            out (c), a
            inc hl
            dec e
            jr nz, pt_lp
            dec b
            ld a, #43
            out (c), a
            inc b
            xor a
            out (c), a
#endasm
End Sub

' Raster(): the line the display is on now (0-311; 0-191 the picture)
Public Function Raster() As Integer
#asm
            ld bc, #243B
rs_again:
            ld a, #1E
            out (c), a
            inc b
            in d, (c)
            dec b
            ld a, #1F
            out (c), a
            inc b
            in e, (c)
            dec b
            ld a, #1E
            out (c), a
            inc b
            in a, (c)
            dec b
            cp d
            jr nz, rs_again
            and 1
            ld d, a
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function

' Seed n: start Rnd's sequence from n (as Randomize n - kept here because Randomize with a
' variable doesn't link on its own in this NTC build: kw_seedv jumps into kw_seedl's section)
Public Sub Seed(ByVal n As Integer)
#asm
            pop hl
            ld a, (hl)
            inc hl
            ld h, (hl)
            ld l, a
            or h
            jr nz, sd_ok
            inc l
sd_ok:
            ld (ntc_rnd_seed), hl
#endasm
End Sub

' ---- as a CyborgOS task
' WaitFrame: wait for the next frame (the display passing line 200), handing the CPU to the
' hypervisor (Yield) while waiting - a task has no frame interrupt of its own.
' The hypervisor only ever has the CPU inside a Yield (a task in turbo mode isn't stopped), so
' the screen's registers are noted first (Snap). After each Yield the game asks whether it is
' still in front (Front): if another slot has come to the front (Caps Shift + 1, TOP ...), the
' console's screen registers go back as they were before the game started (ConIn, Back, ConOut:
' TaskInit noted them) - CyborgOS has drawn its console into bank 5's second page, which the
' console's registers show - and the game waits here, its hands off the screen, until it is in
' front again; then its own registers go back (Back) and it carries on at whatever screen it was
' at. Its pictures were never touched
Public Sub WaitFrame()
  Dim l As Integer, was As Integer
  Snap
  was = Raster()
  Do
    Yield
    If Front() = 0 Then
      ConIn
      Back
      ConOut
      Do
        Yield
      Loop Until Front()
      Back
      Exit Do
    End If
    l = Raster()
    If l >= 200 And was < 200 Then Exit Do
    was = l
  Loop
End Sub

' ConSave: (TaskInit, before the game touches the screen) the console's registers noted (Snap's,
' kept in cn_vals). ConIn: the game's noted ones put aside and the console's in their place, for
' Back. ConOut: the game's back in place
Public Sub ConSave()
#asm
    IFNDEF NTC_ZXN
            ld hl, sn_vals
            ld de, cn_vals
            ld bc, 25              ; (sn_vals, sn_pals, sn_l2)
            ldir
            jr cs_end
@cn_vals:   ds 25
@cn_tmp:    ds 25
cs_end:
    ENDIF
#endasm
End Sub

Public Sub ConIn()
#asm
    IFNDEF NTC_ZXN
            ld hl, sn_vals
            ld de, cn_tmp
            ld bc, 25              ; (sn_vals, sn_pals, sn_l2)
            ldir
            ld hl, cn_vals
            ld de, sn_vals
            ld bc, 25              ; (sn_vals, sn_pals, sn_l2)
            ldir
    ENDIF
#endasm
End Sub

Public Sub ConOut()
#asm
    IFNDEF NTC_ZXN
            ld hl, cn_tmp
            ld de, sn_vals
            ld bc, 25              ; (sn_vals, sn_pals, sn_l2)
            ldir
    ENDIF
#endasm
End Sub

' Snap: the screen registers that the game and CyborgOS's console both set noted as they are now -
' the tilemap's, the layers', the transparency, the palette control and the tilemap's first two
' colours (the console's text colours), Layer 2's bank, mode and scroll (#12, #70, #16, #17, #71)
' and its port #123B. Back: them put back
Public Sub Snap()
#asm
    IFNDEF NTC_ZXN
            ld hl, sn_regs
            ld de, sn_vals
            ld bc, #243B
sn_lp:
            ld a, (hl)
            or a
            jr z, sn_pal
            out (c), a
            inc b
            in a, (c)
            dec b
            ld (de), a
            inc hl
            inc de
            jr sn_lp
sn_pal:
            ld a, #43               ; the tilemap's first palette, for reading
            out (c), a
            inc b
            ld a, (sn_vals)
            and #0F
            or #30
            out (c), a
            dec b
            ld hl, sn_pals
            xor a                   ; colours 0 and 1: #41 (RRRGGGBB) and #44 (its 9th bit)
sn_pl:
            ld e, a
            ld a, #40
            out (c), a
            inc b
            out (c), e
            dec b
            ld a, #41
            out (c), a
            inc b
            in a, (c)
            ld (hl), a
            inc hl
            dec b
            ld a, #44
            out (c), a
            inc b
            in a, (c)
            ld (hl), a
            inc hl
            dec b
            ld a, e
            inc a
            cp 2
            jr nz, sn_pl
            ld a, #40               ; #40, #43 the game's again
            out (c), a
            inc b
            ld a, (sn_vals + 1)
            out (c), a
            dec b
            ld a, #43
            out (c), a
            inc b
            ld a, (sn_vals)
            out (c), a
            ld bc, #123B
            in a, (c)
            ld (sn_l2), a
            jr sn_end
@sn_regs:   db #43, #40, #6E, #6F, #6C, #6B, #2F, #30, #31, #15, #68, #69, #4A, #4C, #14
            db #12, #70, #16, #17, #71, 0
@sn_vals:   ds 20
@sn_pals:   ds 4
@sn_l2:     db 0
sn_end:
    ENDIF
#endasm
End Sub

Public Sub Back()
#asm
    IFNDEF NTC_ZXN
            ld hl, sn_regs + 2
            ld de, sn_vals + 2
            ld bc, #243B
bk_lp:
            ld a, (hl)
            or a
            jr z, bk_pal
            out (c), a
            inc b
            ld a, (de)
            out (c), a
            dec b
            inc hl
            inc de
            jr bk_lp
bk_pal:
            ld a, #43
            out (c), a
            inc b
            ld a, (sn_vals)
            and #0F
            or #30
            out (c), a
            dec b
            ld a, #40
            out (c), a
            inc b
            xor a
            out (c), a
            dec b
            ld a, #44               ; two writes a colour, then the next
            out (c), a
            inc b
            ld hl, sn_pals
            ld e, 4
bk_pl:
            ld a, (hl)
            out (c), a
            inc hl
            dec e
            jr nz, bk_pl
            dec b
            ld a, #40               ; #40, #43 the game's
            out (c), a
            inc b
            ld a, (sn_vals + 1)
            out (c), a
            dec b
            ld a, #43
            out (c), a
            inc b
            ld a, (sn_vals)
            out (c), a
            ld bc, #123B
            ld a, (sn_l2)
            out (c), a
    ENDIF
#endasm
End Sub

' Yield: the hypervisor's turn (BDOS 12: CP/M's version - any call below 13 ends the slot's turn):
' the other slots run, then this one again
Public Sub Yield()
#asm
    IFNDEF NTC_ZXN
            ld (ny_sp), sp
            ld sp, (ntc_csp)
            ld c, 12
            ei
            call 5
            di
            ld sp, (ny_sp)
            jr ny_end
ny_sp:      dw 0
@ls_h7:     db 0                    ; the task's own page in MMU slot 7 (TaskStart: NextReg #57)
ny_end:
    ENDIF
#endasm
End Sub

' Front: 1 if this slot is the one in front (BDOS 131 op 0: a slot's line - its state, in front,
' its program's name), 0 if not; the slot's number from its status strip ("[7] ": TaskInit)
Public Function Front() As Integer
#asm
    IFNDEF NTC_ZXN
            ld (nf_sp), sp
            ld sp, (ntc_csp)
            ld c, 131
            ld de, nf_blk
            ei
            call 5
            di
            ld sp, (nf_sp)
            ld a, (nf_blk + 3)
            pop hl
            ld (hl), a
            inc hl
            ld (hl), 0
            jr nf_end
nf_sp:      dw 0
@nf_blk:    db 0, 1
            ds 64
nf_end:
    ENDIF
#endasm
End Function

' TaskInit: (a CyborgOS task) its own page in slot 7 noted (ls_h7: what the routines that borrow slot
' 7 put back - RATBOXN's TPut, TPrint), its slot number (Front). RATBOXN's program and arrays run
' up to #DDxx, so unlike LITTLE SEOUL it keeps its own pages in slots 6 and 7 and reaches bank 5
' (the tilemap) through slot 7 only while it writes to it
Public Sub TaskInit()
#asm
    IFNDEF NTC_ZXN
            ld bc, #243B
            ld a, #57
            out (c), a
            inc b
            in a, (c)
            ld (ls_h7), a
            ld hl, #F68B            ; the slot's number: its status strip "[7] ", "[12]"
            ld a, (hl)
            sub '0'
            ld e, a
            inc hl
            ld a, (hl)
            sub '0'
            cp 10
            jr nc, ti_one
            ld d, a                 ; two digits: e * 10 + d
            ld a, e
            add a, a
            ld e, a
            add a, a
            add a, a
            add a, e
            add a, d
            ld e, a
ti_one:
            ld a, e
            ld (nf_blk + 1), a
            ASSERT ntc_free <= #EF00, "a task's program and arrays must end below #EF00 (CyborgOS's stub)"
    ENDIF
#endasm
End Sub
