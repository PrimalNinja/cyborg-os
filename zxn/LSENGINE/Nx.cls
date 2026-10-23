' Nx - the ZX Spectrum Next's own hardware, straight on the ports: NextRegs (#243B select,
' #253B value), the layer order, the border, palettes, the CPU speed.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
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

' ---- as a CyborgOS task (not the NEX: docs/TASK.md)
' WaitFrame: wait for the next frame (the display passing line 200), handing the CPU to the
' hypervisor (Yield) while waiting - a task has no frame interrupt of its own. Then bank 5's
' first page (the tilemap) back in slot 6: the hypervisor's switch puts the task's own pages in.
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
  Reg &H56, 10
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
@ls_stk:    dw ntc_cpmstack         ; GfxData.Load's stack (slot 7 borrowed): the platform's real one, empty then
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

' LoadCity: (a CyborgOS task, once at the start) the city's data into memory: 0 done, 1 not enough
' free memory, 2 the store's pages not found, 3 LSCITY.DAT not found, 4 LSCITY.DAT too short or
' not one, 5 no three pages in a row for Layer 2, 6 not a ZX Spectrum Next (asked first, before
' any port is touched).
' LSCITY.DAT (tools/cosnext.sh): an AMSDOS header (CyborgOS reads past it), a record that says
' what's in it - "LSC1", n, m, the n NEX banks it holds, the m NEX data banks that are empty
' (all 0: not in the file) - then the n banks, 16K each: the NEX's data banks with something in
' them, gfxtool's bank 47 and a copy of the NEX's bank 5 (the first sprite patterns, named bank
' 60 here), those two last. It goes into the slot's store (BDOS 131 op 12: the hypervisor's
' 16K pages, this slot's while the game runs, their numbers at #FF00 on), n + 2 pages:
'   0 .. n - 1   the banks, as in the file
'   n            Layer 2's third page: Layer 2 is pages n - 2, n - 1, n - banks 47 and 60 are
'                read only by GfxData.Load, done before L2.Init - when they are one after the
'                other (Layer 2 is three banks in a row). Not bank 16 as in the NEX: that's
'                CyborgOS's (its console's Layer 2 is banks 12-16). L2Bank gives it
'   n + 1        all 0: the empty banks' pages map to it
' The store's pages are the hypervisor's Memory pages - 16K bank = the first free bank + page - 2
' - and the first free bank isn't known here, so the program's first 16 bytes go into the
' store's first block (op 13) and the banks it can be (this slot's own first bank less a
' multiple of 4: slots are 64K banks from it) are looked at until they turn up. The file is
' looked for on the slot's drive, else on the first of A: to P: that has it (a new slot's drive
' is the boot drive; the folder the game was run from is a letter of its own: CD's), read 128
' bytes at a time (BDOS 20) and copied into the pages through MMU slot 6. Then the page table at
' #BF00: a page as the NEX has it -> the 8K page it is in now. On the real stack the whole way
' (calls, BDOS)
Public Function LoadCity() As Integer
#asm
    IFNDEF NTC_ZXN
            ld (lc_sp), sp
            ld sp, (ntc_csp)
            ld a, 5                 ; the machine (BDOS 131 op 20, 5: 0 a CPC, 1 a ZX Spectrum Next)
            ld (lc_blk + 1), a      ; - before any port is touched
            ld a, 20
            ld (lc_blk), a
            ld c, 131
            ld de, lc_blk
            call lc_bdos
            dec a
            ld e, 6
            jp nz, lc_end6
            ld hl, #BF00            ; the page table: each page itself to start with
lc_id:
            ld (hl), l
            inc l
            jp p, lc_id
            ld c, 26                ; the DMA: lc_buf
            ld de, lc_buf
            call lc_bdos
            ld c, 15                ; LSCITY.DAT opened: this slot's drive, else A: ... P:
            ld de, lc_fcb
            call lc_bdos
            inc a
            jr nz, lc_open
            xor a
            ld (lc_d), a
lc_dr:
            ld a, (lc_d)
            ld e, a
            ld c, 14                ; (BDOS 14: the slot's drive)
            call lc_bdos
            ld c, 15
            ld de, lc_fcb
            call lc_bdos
            inc a
            jr nz, lc_open
            ld hl, lc_d
            inc (hl)
            ld a, (hl)
            cp 16
            jr nz, lc_dr
            ld e, 3
            jp lc_ret
lc_open:
            ld c, 20                ; what's in it
            ld de, lc_fcb
            call lc_bdos
            or a
            ld e, 4
            jp nz, lc_ret
            ld hl, lc_buf
            ld de, lc_hdr
            ld bc, 128
            ldir
            ld hl, (lc_hdr)
            ld de, 'L' + 'S' * 256
            or a
            sbc hl, de
            ld e, 4
            jp nz, lc_ret
            ld a, (lc_hdr + 4)      ; n + 2 pages: (n + 2) * 16 K
            add a, 2
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld (lc_blk + 2), hl
            ld a, 12                ; op 12: the store
            call lc_sys
            or a
            ld e, 1
            jp nz, lc_ret
            ld hl, 0                ; op 13: 16 bytes from #0100 into block 0
            ld (lc_blk + 2), hl
            ld hl, #0100
            ld (lc_blk + 6), hl
            ld hl, 16
            ld (lc_blk + 8), hl
            ld a, 13
            call lc_sys
            ld a, #50               ; this slot's first 16K bank
            call lc_rd
            srl a
            ld (lc_k), a
lc_scan:
            ld a, (lc_k)
            ld hl, #FF00
            add a, (hl)
            sub 2
            jr c, lc_next
            cp 112
            jr nc, lc_next
            add a, a
            call lc_map
            ld hl, #C000
            ld de, #0100
            ld b, 16
lc_cmp:
            ld a, (de)
            cp (hl)
            jr nz, lc_next
            inc hl
            inc de
            djnz lc_cmp
            jr lc_found
lc_next:
            ld a, (lc_k)
            sub 4
            ld e, 2
            jp c, lc_ret
            ld (lc_k), a
            jr lc_scan
lc_found:
            xor a
            ld (lc_i), a
lc_bank:
            ld a, (lc_i)            ; store page i's first 8K page
            call lc_pgof
            ld (lc_pg), a
            xor a
            ld (lc_r), a
lc_rec:
            ld c, 20
            ld de, lc_fcb
            call lc_bdos
            or a
            ld e, 4
            jp nz, lc_ret
            ld a, (lc_r)            ; record r: page + r / 64, #C000 + (r and 63) * 128
            rlca
            rlca
            and 1
            ld hl, lc_pg
            add a, (hl)
            call lc_map
            ld a, (lc_r)
            and 63
            ld l, 0
            srl a
            rr l
            add a, #C0
            ld h, a
            ex de, hl
            ld hl, lc_buf
            ld bc, 128
            ldir
            ld hl, lc_r
            inc (hl)
            jp p, lc_rec            ; (128 records: 16K)
            ld a, (lc_i)            ; the page table: the NEX's bank -> these two pages
            ld e, a
            ld d, 0
            ld hl, lc_hdr + 6
            add hl, de
            ld a, (hl)
            ld b, a
            ld a, (lc_pg)
            call lc_tab
            ld hl, lc_i
            inc (hl)
            ld a, (lc_hdr + 4)
            cp (hl)
            jr nz, lc_bank
            ld c, 16
            ld de, lc_fcb
            call lc_bdos
            ld a, (lc_hdr + 4)      ; page n + 1: all 0, the empty banks' pages
            inc a
            call lc_pgof
            ld (lc_pg), a
            call lc_map
            call lc_clr
            ld a, (lc_pg)
            inc a
            call lc_map
            call lc_clr
            ld a, (lc_hdr + 5)
            or a
            jr z, lc_lay
            ld b, a
            ld a, (lc_hdr + 4)
            ld e, a
            ld d, 0
            ld hl, lc_hdr + 6
            add hl, de
lc_empty:
            push bc
            push hl
            ld b, (hl)
            ld a, (lc_pg)
            call lc_tab
            pop hl
            pop bc
            inc hl
            djnz lc_empty
lc_lay:
            ld a, (lc_hdr + 4)      ; Layer 2: pages n - 2, n - 1, n in a row?
            sub 2
            ld l, a
            ld h, #FF
            ld a, (hl)
            inc a
            inc l
            cp (hl)
            ld e, 5
            jr nz, lc_ret
            inc a
            inc l
            cp (hl)
            jr nz, lc_ret
            ld a, (lc_hdr + 4)
            sub 2
            call lc_pgof
            ld (l2pg_a + 1), a      ; its first 8K page into the drawing routines
            ld (l2pg_b + 1), a
            ld (l2pg_c + 1), a
            ld (l2pg_d + 1), a
            srl a
            ld (lc_l2), a           ; its 16K bank (NextReg #12)
            ld e, 0
lc_ret:
            ld a, 10                ; bank 5's first page in slot 6 again
            call lc_map
lc_end6:
            ld sp, (lc_sp)
            pop hl
            ld (hl), e
            inc hl
            ld (hl), 0
            jp lc_end
lc_pgof:                            ; A = a store page -> A = its first 8K page
            ld l, a
            ld h, #FF
            ld a, (lc_k)
            add a, (hl)
            sub 2
            add a, a
            ret
lc_tab:                             ; NEX bank B -> 8K pages A, A + 1 in the table
            push af
            ld a, b
            add a, a
            ld l, a
            ld h, #BF
            pop af
            ld (hl), a
            inc l
            inc a
            ld (hl), a
            ret
lc_clr:                             ; #C000-#DFFF all 0
            ld hl, #C000
            ld de, #C001
            ld bc, #1FFF
            ld (hl), 0
            ldir
            ret
lc_sys:                             ; BDOS 131, op A, the block lc_blk: A back
            ld (lc_blk), a
            xor a
            ld (lc_blk + 1), a
            ld c, 131
            ld de, lc_blk
lc_bdos:                            ; BDOS C, DE: A back
            ei
            call 5
            di
            ret
lc_map:                             ; MMU slot 6 = page A
            push bc
            ld bc, #243B
            push af
            ld a, #56
            out (c), a
            inc b
            pop af
            out (c), a
            pop bc
            ret
lc_rd:                              ; NextReg A: A
            ld bc, #243B
            out (c), a
            inc b
            in a, (c)
            ret
lc_sp:      dw 0
lc_k:       db 0
lc_d:       db 0
@lc_l2:     db 16
lc_i:       db 0
lc_r:       db 0
lc_pg:      db 0
lc_fcb:     db 0, "LSCITY  DAT"
            ds 24
lc_buf:     equ #E000               ; (the slot's own top page below CyborgOS's stub at #EF00:
lc_hdr:     equ #E080               ; free while the city loads)
lc_blk:     equ #E100
lc_end:
    ENDIF
#endasm
End Function

' L2Bank: (a CyborgOS task) Layer 2's first 16K bank (LoadCity)
Public Function L2Bank() As Integer
#asm
    IFNDEF NTC_ZXN
            ld a, (lc_l2)
            pop hl
            ld (hl), a
            inc hl
            ld (hl), 0
    ENDIF
#endasm
End Function

' TaskInit: (a CyborgOS task) its own page in slot 7 noted (ls_h7: what the routines that borrow slot
' 7 put back), bank 5's first page in slot 6 (the tilemap: map and tiles)
Public Sub TaskInit()
#asm
    IFNDEF NTC_ZXN
            ld bc, #243B
            ld a, #57
            out (c), a
            inc b
            in a, (c)
            ld (ls_h7), a
            dec b
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
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
            ASSERT ntc_free <= #BF00, "a task's program and arrays must end below #BF00 (the page table)"
    ENDIF
#endasm
End Sub
