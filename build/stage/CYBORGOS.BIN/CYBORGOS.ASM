; the window data (; @window ... ; @endwindow in #asm): put in the window hole by its guard
			MACRO ntc_windata
; (the hypervisor's page from #5300 - #4000-#4FFF free, #5000 the font: Install copies
; these into each bank from there, FileCall 99 put them there at the start)
; v9_f6: the V9990's font (V9.cls's Init reads it from main RAM's own #4000-#7FFF at the start,
; where the file put it - not copied to the page): NTC's ntc_font6, characters 32-126 in the left
; 6 pixels - the X11 "misc-fixed" 5x8 font (public domain), a pixel in from the left
@v9_f6:
			db #00, #00, #00, #00, #00, #00, #00, #00	; 32
			db #00, #10, #10, #10, #10, #00, #10, #00	; 33 !
			db #00, #28, #28, #28, #00, #00, #00, #00	; 34 "
			db #28, #28, #7C, #28, #7C, #28, #28, #00	; 35 #
			db #10, #38, #50, #38, #14, #38, #10, #00	; 36 $
			db #00, #20, #28, #10, #28, #08, #00, #00	; 37 %
			db #20, #50, #50, #20, #50, #50, #28, #00	; 38 &
			db #00, #10, #10, #10, #00, #00, #00, #00	; 39 '
			db #00, #10, #20, #20, #20, #20, #10, #00	; 40 (
			db #00, #20, #10, #10, #10, #10, #20, #00	; 41 )
			db #00, #00, #48, #30, #78, #30, #48, #00	; 42 *
			db #00, #00, #10, #10, #7C, #10, #10, #00	; 43 +
			db #00, #00, #00, #00, #00, #18, #10, #20	; 44 ,
			db #00, #00, #00, #00, #78, #00, #00, #00	; 45 -
			db #00, #00, #00, #00, #00, #10, #38, #10	; 46 .
			db #00, #08, #08, #10, #20, #40, #40, #00	; 47 /
			db #00, #10, #28, #28, #28, #28, #10, #00	; 48 0
			db #00, #10, #30, #10, #10, #10, #38, #00	; 49 1
			db #00, #30, #48, #08, #30, #40, #78, #00	; 50 2
			db #00, #78, #10, #30, #08, #48, #30, #00	; 51 3
			db #00, #10, #30, #50, #78, #10, #10, #00	; 52 4
			db #00, #78, #40, #70, #08, #48, #30, #00	; 53 5
			db #00, #30, #40, #70, #48, #48, #30, #00	; 54 6
			db #00, #78, #08, #10, #10, #20, #20, #00	; 55 7
			db #00, #30, #48, #30, #48, #48, #30, #00	; 56 8
			db #00, #30, #48, #48, #38, #08, #30, #00	; 57 9
			db #00, #00, #30, #30, #00, #30, #30, #00	; 58 :
			db #00, #00, #18, #18, #00, #18, #10, #20	; 59 semicolon
			db #00, #08, #10, #20, #20, #10, #08, #00	; 60 <
			db #00, #00, #00, #78, #00, #78, #00, #00	; 61 =
			db #00, #20, #10, #08, #08, #10, #20, #00	; 62 >
			db #00, #10, #28, #08, #10, #00, #10, #00	; 63 ?
			db #18, #24, #4C, #54, #54, #48, #20, #18	; 64 @
			db #00, #30, #48, #48, #78, #48, #48, #00	; 65 A
			db #00, #70, #48, #70, #48, #48, #70, #00	; 66 B
			db #00, #30, #48, #40, #40, #48, #30, #00	; 67 C
			db #00, #70, #48, #48, #48, #48, #70, #00	; 68 D
			db #00, #78, #40, #70, #40, #40, #78, #00	; 69 E
			db #00, #78, #40, #70, #40, #40, #40, #00	; 70 F
			db #00, #30, #48, #40, #58, #48, #30, #00	; 71 G
			db #00, #48, #48, #78, #48, #48, #48, #00	; 72 H
			db #00, #38, #10, #10, #10, #10, #38, #00	; 73 I
			db #00, #38, #10, #10, #10, #50, #20, #00	; 74 J
			db #00, #48, #50, #60, #50, #50, #48, #00	; 75 K
			db #00, #40, #40, #40, #40, #40, #78, #00	; 76 L
			db #00, #48, #78, #78, #48, #48, #48, #00	; 77 M
			db #00, #48, #68, #78, #58, #58, #48, #00	; 78 N
			db #00, #30, #48, #48, #48, #48, #30, #00	; 79 O
			db #00, #70, #48, #48, #70, #40, #40, #00	; 80 P
			db #00, #30, #48, #48, #68, #58, #30, #08	; 81 Q
			db #00, #70, #48, #48, #70, #48, #48, #00	; 82 R
			db #00, #30, #48, #20, #10, #48, #30, #00	; 83 S
			db #00, #38, #10, #10, #10, #10, #10, #00	; 84 T
			db #00, #48, #48, #48, #48, #48, #30, #00	; 85 U
			db #00, #48, #48, #48, #48, #30, #30, #00	; 86 V
			db #00, #48, #48, #48, #78, #78, #48, #00	; 87 W
			db #00, #48, #48, #30, #30, #48, #48, #00	; 88 X
			db #00, #44, #44, #28, #10, #10, #10, #00	; 89 Y
			db #00, #78, #08, #10, #20, #40, #78, #00	; 90 Z
			db #00, #38, #20, #20, #20, #20, #38, #00	; 91 [
			db #00, #40, #40, #20, #10, #08, #08, #00	; 92 \
			db #00, #38, #08, #08, #08, #08, #38, #00	; 93 ]
			db #00, #10, #28, #00, #00, #00, #00, #00	; 94 ^
			db #00, #00, #00, #00, #00, #00, #00, #78	; 95 _
			db #00, #20, #10, #00, #00, #00, #00, #00	; 96 `
			db #00, #00, #00, #38, #48, #48, #38, #00	; 97 a
			db #00, #40, #40, #70, #48, #48, #70, #00	; 98 b
			db #00, #00, #00, #18, #20, #20, #18, #00	; 99 c
			db #00, #08, #08, #38, #48, #48, #38, #00	; 100 d
			db #00, #00, #00, #30, #58, #60, #30, #00	; 101 e
			db #00, #10, #28, #20, #70, #20, #20, #00	; 102 f
			db #00, #00, #00, #30, #48, #38, #08, #30	; 103 g
			db #00, #40, #40, #70, #48, #48, #48, #00	; 104 h
			db #00, #10, #00, #30, #10, #10, #38, #00	; 105 i
			db #00, #08, #00, #08, #08, #08, #28, #10	; 106 j
			db #00, #40, #40, #48, #70, #48, #48, #00	; 107 k
			db #00, #30, #10, #10, #10, #10, #38, #00	; 108 l
			db #00, #00, #00, #68, #54, #54, #54, #00	; 109 m
			db #00, #00, #00, #70, #48, #48, #48, #00	; 110 n
			db #00, #00, #00, #30, #48, #48, #30, #00	; 111 o
			db #00, #00, #00, #70, #48, #70, #40, #40	; 112 p
			db #00, #00, #00, #38, #48, #38, #08, #08	; 113 q
			db #00, #00, #00, #50, #68, #40, #40, #00	; 114 r
			db #00, #00, #00, #18, #30, #08, #30, #00	; 115 s
			db #00, #20, #20, #70, #20, #28, #10, #00	; 116 t
			db #00, #00, #00, #48, #48, #48, #38, #00	; 117 u
			db #00, #00, #00, #28, #28, #28, #10, #00	; 118 v
			db #00, #00, #00, #44, #54, #54, #28, #00	; 119 w
			db #00, #00, #00, #48, #30, #30, #48, #00	; 120 x
			db #00, #00, #00, #48, #48, #38, #48, #30	; 121 y
			db #00, #00, #00, #78, #10, #20, #78, #00	; 122 z
			db #18, #20, #10, #60, #10, #20, #18, #00	; 123 {
			db #00, #10, #10, #10, #10, #10, #10, #00	; 124 |
			db #60, #10, #20, #18, #20, #10, #60, #00	; 125 }
			db #00, #28, #50, #00, #00, #00, #00, #00	; 126 ~
            ds #5300 - $
; page zero (#0000-#0080)
fn_hyp_info_hi_p0:
            db #C3
            dw fn_hyp_info_sb_bwb                           ; #0000: warm boot - the BIOS's WBOOT (the task
            db 0, 0                             ; ends); (#0001) - 3: the BIOS jump table
            db #C3
            dw fn_hyp_info_sb_start                         ; #0005: BDOS (#0006: the top of the TPA)
; #0008: a far call's route (sb_call jumps here: A = C = the function, DE = its argument): the
; kernel's (0 the end, #81 a key wait, 131's ops 0-9: PS, KILL, RESET, FG, WAIT, TOP, MEM, MODE)
; to the kernel's bank (its RAM setting at #003B - Install), the rest (the files, the console's
; #80, RAMDISC, 131's memory / claims / network / ports) to main RAM (C0); HL = this bank's slot
; (#003D: 0 the kernel's own), carry set: a call (RST 1-5's bytes: CP/M leaves them unused)
            or a
            jr z, fn_hyp_info_hi_rk
            cp #81
            jr z, fn_hyp_info_hi_rk
            cp 131
            jr nz, fn_hyp_info_hi_r0
            ld a, (de)                          ; 131: its op
            cp 10
            ld a, c
            jr c, fn_hyp_info_hi_rk
fn_hyp_info_hi_r0:
            ld bc, #7FC0
            jr fn_hyp_info_hi_rg
fn_hyp_info_hi_rk:
            ld bc, (#003B)
fn_hyp_info_hi_rg:
            ld hl, (#003D)
            scf
            jp #0044
            ASSERT $ - fn_hyp_info_hi_p0 <= #38, "the route must end below #0038"
            ds #38 - ($ - fn_hyp_info_hi_p0)
            db #C3
            dw fn_hyp_info_sb_int                           ; #0038: the interrupt (to the kernel: sb_int)
            dw #7FC0                            ; #003B: the kernel's RAM setting (Install; the
            dw 0                                ; kernel's own: main RAM), #003D: this bank's slot
            ds #44 - #3F
            db #ED, #49                         ; #0044: out (c), c
            db #C3
            dw fn_hyp_info_sb_land                          ; #0046: this bank switched in
            ds #5C - #49
            db 0, "           "                 ; #005C: the default FCB
            ds #80 - #68
            db 0                                ; #0080: no command tail
fn_hyp_info_hi_p0e:
; the stubs: assembled here, run at STUB in the bank (DISP: their labels are the bank's
; addresses). The BDOS: what needs nothing of the hypervisor is answered here, with no
; switch - the console out (2, 9: collected at OBUF; the hypervisor gets them, IX = how many, at
; the next far call or interrupt, or when 128 wait), the keys (1, 6, 10, 11: from KEY, where
; the hypervisor leaves the slot's next key), the IOBYTE (7, 8), the disc's parameters (27, 31)
; and the calls with nothing to do (3, 4, 5, 28, 29, 30, 37 - 30 with #C0 on at DE is CyborgOS's
; UniDOS call), CP/M 3's 49 for the console's size (MODE); the rest is a far call. Then the
; BIOS (its jump table: (#0001) - 3) and the start-up (the default FCBs)
fn_hyp_info_sb_img:
            DISP 61184
fn_hyp_info_sb_start:
            di                                  ; BDOS: C = function, DE = argument
            ld a, c
            cp 2
            jp z, fn_hyp_info_sb_put
            cp 6
            jr z, fn_hyp_info_sb_f6
            cp 11
            jr z, fn_hyp_info_sb_stat
            cp 1
            jr z, fn_hyp_info_sb_f1
            cp 9
            jp z, fn_hyp_info_sb_str
            cp 10
            jp z, fn_hyp_info_sb_line
            cp 3
            jr z, fn_hyp_info_sb_rdr
            cp 7
            jr z, fn_hyp_info_sb_iob
            cp 8
            jr z, fn_hyp_info_sb_siob
            cp 27
            jr z, fn_hyp_info_sb_alv
            cp 31
            jr z, fn_hyp_info_sb_dpb
            cp 4
            jr z, fn_hyp_info_sb_zero
            cp 5
            jr z, fn_hyp_info_sb_zero
            cp 28
            jr z, fn_hyp_info_sb_zero
            cp 29
            jr z, fn_hyp_info_sb_zero
            cp 30
            jr z, fn_hyp_info_sb_f30
            cp 37
            jr z, fn_hyp_info_sb_zero
            cp 49
            jp z, fn_hyp_info_sb_scb
            jp fn_hyp_info_sb_call
fn_hyp_info_sb_f30:                                         ; 30: nothing - unless #C0 on at DE: CyborgOS's
            ld a, (de)                          ; UniDOS call (CD, DIR: the hypervisor's)
            cp #C0
            jp nc, fn_hyp_info_sb_call
fn_hyp_info_sb_zero:
            xor a                               ; 4, 5 (the printer: not yet), 28, 29, 30, 37
fn_hyp_info_sb_ret:
            ld l, a
            ld h, 0
            ei
            ret
fn_hyp_info_sb_rdr:
            ld a, #1A                           ; 3: the reader - the end of a file
            jr fn_hyp_info_sb_ret
fn_hyp_info_sb_iob:
            ld a, (#0003)                       ; 7: the IOBYTE
            jr fn_hyp_info_sb_ret
fn_hyp_info_sb_siob:
            ld a, e                             ; 8
            ld (#0003), a
            jr fn_hyp_info_sb_zero
fn_hyp_info_sb_alv:
            ld hl, fn_hyp_info_sb_alvec                     ; 27: the allocation vector (a CPC data disc's)
            ei
            ret
fn_hyp_info_sb_dpb:
            ld hl, fn_hyp_info_sb_dpbv                      ; 31: the disc parameter block
            ei
            ret
fn_hyp_info_sb_f6:
            ld a, e
            cp #FF
            jr z, fn_hyp_info_sb_get
            cp #FE
            jr c, fn_hyp_info_sb_put
fn_hyp_info_sb_stat:
            ld a, (63105)                       ; 6 / #FE, 11: is a key waiting (#FF / 0)
            or a
            jr z, fn_hyp_info_sb_ret
            ld a, #FF
            jr fn_hyp_info_sb_ret
fn_hyp_info_sb_get:
            ld hl, 63105                        ; 6 / #FF: the key or 0 (no wait)
            ld a, (hl)
            ld (hl), 0
            jr fn_hyp_info_sb_ret
fn_hyp_info_sb_f1:
            call fn_hyp_info_sb_key                         ; 1: a key (waited for), echoed
            push af
            ld e, a
            call fn_hyp_info_sb_putc
            pop af
            jr fn_hyp_info_sb_ret
fn_hyp_info_sb_put:
            call fn_hyp_info_sb_putc                        ; 2: E out
            ei
            ret
fn_hyp_info_sb_str:
            ld h, d                             ; 9: the string at DE, to "$"
            ld l, e
fn_hyp_info_sb_st_lp:
            ld a, (hl)
            cp '$'
            jr z, fn_hyp_info_sb_zero
            push hl
            ld e, a
            call fn_hyp_info_sb_putc
            pop hl
            inc hl
            jr fn_hyp_info_sb_st_lp
; sb_putc - E collected at OBUF (the hypervisor shown them when 128 wait). Interrupts off
fn_hyp_info_sb_putc:
            ld hl, 62976 + 128                 ; the count
            ld a, (hl)
            inc (hl)
            ld l, a
            ld h, 62976 / 256
            ld (hl), e
            cp 127
            ret c
            push bc
            push de
            ld c, #80                           ; full: function #80, only the characters
            call fn_hyp_info_sb_call
            di
            pop de
            pop bc
            ret
; sb_key - A = the next key, waited for: none at KEY - a far call (#81) that has the hypervisor
; run the others until a key comes (or the clock moves on), then look again
fn_hyp_info_sb_key:
            ld hl, 63105
            ld a, (hl)
            or a
            jr z, fn_hyp_info_sb_k_wait
            ld (hl), 0
            ret
fn_hyp_info_sb_k_wait:
            push bc
            push de
            ld c, #81
            call fn_hyp_info_sb_call
            di
            pop de
            pop bc
            jr fn_hyp_info_sb_key
; 10: a line typed into the buffer at DE (its size, then how many came, then them): BS / DEL
; rub out, Control + U / X the whole line, Control + C at its start ends the program, CR / LF
; end it (CR echoed)
fn_hyp_info_sb_line:
            ld (fn_hyp_info_sb_lbuf), de
            xor a
            ld (fn_hyp_info_sb_lcnt), a
fn_hyp_info_sb_l_lp:
            call fn_hyp_info_sb_key
            cp 13
            jr z, fn_hyp_info_sb_l_end
            cp 10
            jr z, fn_hyp_info_sb_l_end
            cp 8
            jr z, fn_hyp_info_sb_l_bs
            cp 127
            jr z, fn_hyp_info_sb_l_bs
            cp 21
            jr z, fn_hyp_info_sb_l_kill
            cp 24
            jr z, fn_hyp_info_sb_l_kill
            cp 3
            jr nz, fn_hyp_info_sb_l_ch
            ld a, (fn_hyp_info_sb_lcnt)
            or a
            jr nz, fn_hyp_info_sb_l_lp
            ld c, 0                             ; Control + C: the program ends
            jp fn_hyp_info_sb_call
fn_hyp_info_sb_l_ch:
            cp 32
            jr c, fn_hyp_info_sb_l_lp
            ld b, a
            ld hl, (fn_hyp_info_sb_lbuf)
            ld a, (fn_hyp_info_sb_lcnt)
            cp (hl)
            jr nc, fn_hyp_info_sb_l_lp                      ; full
            inc a
            ld (fn_hyp_info_sb_lcnt), a
            ld e, a
            ld d, 0
            inc hl
            add hl, de
            ld (hl), b
            ld e, b
            call fn_hyp_info_sb_putc
            jr fn_hyp_info_sb_l_lp
fn_hyp_info_sb_l_kill:
            ld a, (fn_hyp_info_sb_lcnt)
            or a
            jr z, fn_hyp_info_sb_l_lp
            call fn_hyp_info_sb_l_rub
            jr fn_hyp_info_sb_l_kill
fn_hyp_info_sb_l_bs:
            ld a, (fn_hyp_info_sb_lcnt)
            or a
            jr z, fn_hyp_info_sb_l_lp
            call fn_hyp_info_sb_l_rub
            jr fn_hyp_info_sb_l_lp
fn_hyp_info_sb_l_rub:
            dec a
            ld (fn_hyp_info_sb_lcnt), a
            ld e, 8
            call fn_hyp_info_sb_putc
            ld e, ' '
            call fn_hyp_info_sb_putc
            ld e, 8
            jp fn_hyp_info_sb_putc
fn_hyp_info_sb_l_end:
            ld hl, (fn_hyp_info_sb_lbuf)
            inc hl
            ld a, (fn_hyp_info_sb_lcnt)
            ld (hl), a
            ld e, 13
            call fn_hyp_info_sb_putc
            jp fn_hyp_info_sb_zero
fn_hyp_info_sb_lbuf:    dw 0
fn_hyp_info_sb_lcnt:    db 0
fn_hyp_info_sb_call:
            push ix                             ; a far call: IX, IY and the alternate
            push iy                             ; registers kept over it (ex af, af')
            db #08
            exx
            push af
            push bc
            push de
            push hl
            exx
            db #08
            ld a, (62976 + 128)
            ld ixl, a
            ld ixh, 0
            ld a, c
            ld hl, fn_hyp_info_sb_far
            push hl
            ld (#FFFE), sp
            jp #0008                            ; its route: the kernel or main RAM (carry: a call)
fn_hyp_info_sb_far:
            db #08                              ; the answer in A and HL; the program's
            exx                                 ; other registers back
            pop hl
            pop de
            pop bc
            pop af
            exx
            db #08
            pop iy
            pop ix
            ei
            ret
fn_hyp_info_sb_int:
            push af                             ; an interrupt: everything kept
            push bc
            push de
            push hl
            db #08                              ; ex af, af'
            exx
            push af
            push bc
            push de
            push hl
            push ix
            push iy
            ld a, (62976 + 128)
            ld ixl, a
            ld ixh, 0
            ld hl, fn_hyp_info_sb_rest
            push hl
            ld (#FFFE), sp
            ld hl, (#003D)                      ; (this slot)
            ld bc, (#003B)                      ; to the kernel: it runs the slots, counts the
            or a                                ; slices (no carry: an interrupt)
            jp #0044
fn_hyp_info_sb_rest:
            pop iy
            pop ix
            pop hl
            pop de
            pop bc
            pop af
            exx
            db #08                              ; ex af, af'
            pop hl
            pop de
            pop bc
            pop af
            ei
            ret
fn_hyp_info_sb_land:
            ld sp, (#FFFE)                      ; this bank's SP
            push af
            ld a, e                             ; E = 1: the hypervisor has the characters
            or a
            jr z, fn_hyp_info_sb_lkeep
            xor a
            ld (62976 + 128), a
fn_hyp_info_sb_lkeep:
            pop af
            ret
fn_hyp_info_sb_scb:
            ld h, d                             ; 49 (CP/M 3's system control block): the
            ld l, e                             ; console's width - 1 (#1A), its page length
            inc hl                              ; (#1C) - MODE's; other bytes 0, sets kept
            ld a, (hl)                          ; nowhere
            or a
            jp nz, fn_hyp_info_sb_zero
            ld a, (de)
            cp #1C
            ld hl, 63112
            jr z, fn_hyp_info_sb_scb_a
            cp #1A
            jp nz, fn_hyp_info_sb_zero
            ld a, (63111)
            dec a
            jp fn_hyp_info_sb_ret
fn_hyp_info_sb_scb_a:
            ld a, (hl)
            jp fn_hyp_info_sb_ret
; the BIOS: CP/M 2.2's 17 entries. The console ones as the BDOS's; the printer and punch take
; nothing yet; the disc ones (sectors) can't be had here: SELDSK gives 0 (no such drive),
; READ / WRITE 1 (an error)
fn_hyp_info_sb_bios:
            jp fn_hyp_info_sb_bboot                         ; BOOT
fn_hyp_info_sb_bwb:
            jp fn_hyp_info_sb_bboot                         ; WBOOT: (#0001)
            jp fn_hyp_info_sb_bconst                        ; CONST
            jp fn_hyp_info_sb_bconin                        ; CONIN
            jp fn_hyp_info_sb_bconout                       ; CONOUT
            jp fn_hyp_info_sb_bnone                         ; LIST
            jp fn_hyp_info_sb_bnone                         ; PUNCH
            jp fn_hyp_info_sb_brdr                          ; READER
            jp fn_hyp_info_sb_bnone                         ; HOME
            jp fn_hyp_info_sb_bseld                         ; SELDSK
            jp fn_hyp_info_sb_bnone                         ; SETTRK
            jp fn_hyp_info_sb_bnone                         ; SETSEC
            jp fn_hyp_info_sb_bdma                          ; SETDMA
            jp fn_hyp_info_sb_bfail                         ; READ
            jp fn_hyp_info_sb_bfail                         ; WRITE
            jp fn_hyp_info_sb_blstst                        ; LISTST
            jp fn_hyp_info_sb_bsectr                        ; SECTRAN
fn_hyp_info_sb_bboot:
            ld c, 0                             ; the task ends
            jp fn_hyp_info_sb_start
fn_hyp_info_sb_bconst:
            di
            ld a, (63105)
            or a
            jr z, fn_hyp_info_sb_bc_n
            ld a, #FF
fn_hyp_info_sb_bc_n:
            ei
            ret
fn_hyp_info_sb_bconin:
            di
            call fn_hyp_info_sb_key
            ei
            ret
fn_hyp_info_sb_bconout:
            di
            ld e, c
            call fn_hyp_info_sb_putc
            ei
fn_hyp_info_sb_bnone:
            ret
fn_hyp_info_sb_brdr:
            ld a, #1A
            ret
fn_hyp_info_sb_bseld:
            ld hl, 0
            ret
fn_hyp_info_sb_bdma:
            ld d, b
            ld e, c
            ld c, 26
            jp fn_hyp_info_sb_start
fn_hyp_info_sb_bfail:
            ld a, 1
            ret
fn_hyp_info_sb_blstst:
            ld a, #FF
            ret
fn_hyp_info_sb_bsectr:
            ld h, b
            ld l, c
            ret
; a CPC data format disc's parameters (31) and allocation vector (27): 180 1K blocks, 64
; directory entries in the first two
fn_hyp_info_sb_dpbv:
            dw 36                               ; SPT: 128 byte records a track
            db 3, 7, 0                          ; BSH, BLM, EXM
            dw 179, 63                          ; DSM, DRM
            db #C0, 0                           ; AL0, AL1
            dw 16, 0                            ; CKS, OFF
fn_hyp_info_sb_alvec:
            db #C0
            ds 22
; the start-up: the default FCBs (#005C, #006C) from the command tail (#0080), as the CCP
; makes them - "B:NAME.EXT", * as ?s - then the program at #0100
fn_hyp_info_sb_init:
            ld hl, #005C
            call fn_hyp_info_sb_iclr
            ld hl, #006C
            call fn_hyp_info_sb_iclr
            ld hl, #0081
            ld a, (#0080)
            ld b, a
            ld de, #005C
            call fn_hyp_info_sb_parse
            ld de, #006C
            call fn_hyp_info_sb_parse
            jp #0100
fn_hyp_info_sb_iclr:
            ld (hl), 0
            inc hl
            ld c, 11
fn_hyp_info_sb_ic_sp:
            ld (hl), ' '
            inc hl
            dec c
            jr nz, fn_hyp_info_sb_ic_sp
            ld c, 4
fn_hyp_info_sb_ic_z:
            ld (hl), 0
            inc hl
            dec c
            jr nz, fn_hyp_info_sb_ic_z
            ret
; sb_parse - HL = the tail, B = characters left; DE = an FCB: the next word into it
fn_hyp_info_sb_parse:
            ld a, b
            or a
            ret z
            ld a, (hl)
            cp ' '
            jr nz, fn_hyp_info_sb_p_word
            inc hl
            dec b
            jr fn_hyp_info_sb_parse
fn_hyp_info_sb_p_word:
            ld (fn_hyp_info_sb_pfcb), de
            ld a, b
            cp 2
            jr c, fn_hyp_info_sb_p_name
            inc hl
            ld a, (hl)
            dec hl
            cp ':'
            jr nz, fn_hyp_info_sb_p_name
            ld a, (hl)
            sub '@'
            ld (de), a                          ; its drive
            inc hl
            inc hl
            dec b
            dec b
fn_hyp_info_sb_p_name:
            inc de
            ld c, 8
            call fn_hyp_info_sb_pfield
            ld a, b
            or a
            ret z
            ld a, (hl)
            cp '.'
            jr nz, fn_hyp_info_sb_p_skip
            inc hl
            dec b
            ld de, (fn_hyp_info_sb_pfcb)
            ld a, e
            add a, 9
            ld e, a
            ld c, 3
            call fn_hyp_info_sb_pfield
fn_hyp_info_sb_p_skip:
            ld a, b                             ; the rest of the word
            or a
            ret z
            ld a, (hl)
            cp ' '
            ret z
            inc hl
            dec b
            jr fn_hyp_info_sb_p_skip
; sb_pfield - up to C characters into the field at DE, to a "." or a space; * fills it with ?
fn_hyp_info_sb_pfield:
            ld a, b
            or a
            ret z
            ld a, (hl)
            cp ' '
            ret z
            cp '.'
            ret z
            cp '*'
            jr z, fn_hyp_info_sb_pf_star
            inc c
            dec c
            jr z, fn_hyp_info_sb_pf_on                      ; (the field full: the extra left out)
            ld (de), a
            inc de
            dec c
fn_hyp_info_sb_pf_on:
            inc hl
            dec b
            jr fn_hyp_info_sb_pfield
fn_hyp_info_sb_pf_star:
            inc c
            dec c
            jr z, fn_hyp_info_sb_pf_on
            ld a, '?'
            ld (de), a
            inc de
            dec c
            jr fn_hyp_info_sb_pf_star
fn_hyp_info_sb_pfcb:    dw 0
fn_hyp_info_sb_end:
            ENT
            ASSERT fn_hyp_info_sb_end - fn_hyp_info_sb_start <= 62208 - 61184, "the bank stubs must fit below FONT"
            ASSERT fn_hyp_info_sb_end - fn_hyp_info_sb_start <= #340, "the stubs must leave a program's first stack (#F240-#F2FF) free"
; ---- the page code: in the hypervisor's page (window data), called with it in the window
asm_1_2832_n_fp_start:
            ASSERT asm_1_2832_n_fp_start >= #5300, "FileCall's page code: after the font"
asm_1_2832_n_fp_go:
            ld (asm_1_2832_n_fp_sp), sp
            ld a, (var_hyp_filecall_f)
            cp 15
            jp z, asm_1_2832_n_fl_open
            cp 16
            jp z, asm_1_2832_n_fl_close
            cp 19
            jp z, asm_1_2832_n_fl_del
            cp 23
            jp z, asm_1_2832_n_fl_ren
            cp 20
            jp z, asm_1_2832_n_fl_rdseq
            cp 33
            jp z, asm_1_2832_n_fl_rdran
            cp 21
            jp z, asm_1_2832_n_fl_write
            cp 34
            jp z, asm_1_2832_n_fl_write
            cp 22
            jp z, asm_1_2832_n_fl_make
            cp 17
            jp z, asm_1_2832_n_fl_srch1
            cp 18
            jp z, asm_1_2832_n_fl_srch
            cp 35
            jp z, asm_1_2832_n_fl_size
            cp 36
            jp z, asm_1_2832_n_fl_setran
            cp 100
            jp z, asm_1_2832_n_fl_hopen
            cp 101
            jp z, asm_1_2832_n_fl_hread
            cp 102
            jp z, asm_1_2832_n_fl_hclose
            cp 103
            jp z, asm_1_2832_n_fl_hload
            cp 30
            jp z, asm_1_2832_n_fl_unicall
            jp asm_1_2832_n_fp_done
; ---- the hypervisor's own reading (RUN, DIR, CD): 100 open the file named at fcb (dma
; characters, main RAM); 101 read dma bytes (128 at most) to buf: how many; 102 close; 103 the
; rest of it into the slot (setting) from address dma, fcb bytes at most: how many. Not while
; a slot reads a file (255)
asm_1_2832_n_fl_hopen:
            ld a, (var_hyp_fin)
            or a
            jp nz, asm_1_2832_n_fp_done
            ld de, asm_1_2832_n_fl_name_s + 1
            ld hl, (var_hyp_filecall_fcb)          ; a name with no drive: the hypervisor's drive's path first
            ld bc, (var_hyp_filecall_dma)          ; when it has one (UniDOS: CD IDE: ...)
            ld a, ':'
            cpir
            jr z, asm_1_2832_n_fl_ho_nm
            ld a, (var_hyp_hdr)
            call asm_1_2832_n_fl_pfxm
asm_1_2832_n_fl_ho_nm:
            ld hl, (var_hyp_filecall_fcb)
            ld bc, (var_hyp_filecall_dma)
            ldir
            call asm_1_2832_n_fl_nlen
            call asm_1_2832_n_fl_inopen
            jr c, asm_1_2832_n_fl_ho_ok
            ld hl, asm_1_2832_n_fl_name_s        ; NAME.CYB not there: with UniDOS NAME.COM instead (RUN - a
            ld e, (hl)              ; .COM with no entry: UniDOS reads a file with no header to
            ld d, 0                 ; its real end)
            add hl, de
            ld a, (hl)
            cp 'B'
            jp nz, asm_1_2832_n_fp_done
            ld (hl), 'M'
            dec hl
            ld a, (hl)
            cp 'Y'
            jp nz, asm_1_2832_n_fp_done
            ld (hl), 'O'
            call asm_1_2832_n_fl_uni
            jp nc, asm_1_2832_n_fp_done
            call asm_1_2832_n_fl_inopen
            jp nc, asm_1_2832_n_fp_done
            ld hl, (var_hyp_filecall_fcb)          ; (the caller's name too: NAME.COM)
            ld bc, (var_hyp_filecall_dma)
            add hl, bc
            dec hl
            ld (hl), 'M'
            dec hl
            ld (hl), 'O'
asm_1_2832_n_fl_ho_ok:
            ld a, 99                ; (99: the hypervisor's)
            ld (var_hyp_fin), a
            jp asm_1_2832_n_fl_ok
asm_1_2832_n_fl_hread:
            ld a, (var_hyp_filecall_dma)
            ld (asm_1_2832_n_fl_n), a
            call asm_1_2832_n_fl_rdrec
            ld (asm_1_2832_n_fl_res), a
            jp asm_1_2832_n_fp_done
asm_1_2832_n_fl_hclose:
            ld a, (var_hyp_fin)
            cp 99
            jp nz, asm_1_2832_n_fp_done
            call asm_1_2832_n_fl_inclose
            jp asm_1_2832_n_fl_ok
asm_1_2832_n_fl_hload:
            ld hl, 0
            ld (asm_1_2832_n_fl_cnt), hl
            ld hl, (var_hyp_filecall_dma)
            ld (asm_1_2832_n_fl_at), hl
asm_1_2832_n_fl_hl_lp:
            ld hl, (var_hyp_filecall_fcb)          ; what is left to load (fcb bytes at most)
            ld de, (asm_1_2832_n_fl_cnt)
            or a
            sbc hl, de
            jr z, asm_1_2832_n_fl_hl_end
            ld a, h
            or a
            ld a, 128
            jr nz, asm_1_2832_n_fl_hl_n
            ld a, l
            cp 128
            jr c, asm_1_2832_n_fl_hl_n
            ld a, 128
asm_1_2832_n_fl_hl_n:
            ld (asm_1_2832_n_fl_n), a
            ld (asm_1_2832_n_fl_want), a
            call asm_1_2832_n_fl_rdrec           ; a record's worth into buf
            jr z, asm_1_2832_n_fl_hl_end
            ld b, a
            ld (asm_1_2832_n_fl_want + 1), a
            ld hl, (asm_1_2832_n_fl_cnt)
            ld e, a
            ld d, 0
            add hl, de
            ld (asm_1_2832_n_fl_cnt), hl
            ld hl, (asm_1_2832_n_fl_at)
            ld c, b
            ld b, 0
            call asm_1_2832_n_fl_fits
            jr c, asm_1_2832_n_fl_hl_slow
            push bc
            ld de, (var_hyp_filecall_buf)          ; in one page: one ldir
            call asm_1_2832_n_fl_toslot
            pop bc
            ld hl, (asm_1_2832_n_fl_at)
            add hl, bc
            jr asm_1_2832_n_fl_hl_put
asm_1_2832_n_fl_hl_slow:
            ld b, c
            ld de, (var_hyp_filecall_buf)
asm_1_2832_n_fl_hl_cp:
            ld a, (de)              ; into the slot
            call asm_1_2832_n_fl_poke
            inc hl
            inc de
            djnz asm_1_2832_n_fl_hl_cp
asm_1_2832_n_fl_hl_put:
            ld (asm_1_2832_n_fl_at), hl
            ld a, (asm_1_2832_n_fl_want)
            ld b, a
            ld a, (asm_1_2832_n_fl_want + 1)
            cp b
            jr z, asm_1_2832_n_fl_hl_lp          ; a whole one: on
asm_1_2832_n_fl_hl_end:
            ld hl, (asm_1_2832_n_fl_cnt)
            ld (asm_1_2832_n_fl_res16), hl
            ld a, 1
            ld (asm_1_2832_n_fl_r16), a
            jp asm_1_2832_n_fp_done
; ---- 15: open (to read)
asm_1_2832_n_fl_open:
            ld a, (var_hyp_fin)
            or a
            jr z, asm_1_2832_n_fl_op_new
            ld b, a
            ld a, (asm_1_2832_n_fl_slot)
            cp b
            jp nz, asm_1_2832_n_fp_done          ; another slot's being read
            call asm_1_2832_n_fl_inclose         ; this slot's: CP/M needs no close after reading - this open
asm_1_2832_n_fl_op_new:                          ; replaces it (Exists opens and leaves it)
            call asm_1_2832_n_fl_name
            call asm_1_2832_n_fl_inopen
            jp nc, asm_1_2832_n_fp_done
            ld hl, asm_1_2832_n_fl_name_s        ; kept, to open it again (33 going back)
            ld de, asm_1_2832_n_fl_inname
            ld bc, asm_1_2832_n_FL_NL
            ldir
            ld a, (asm_1_2832_n_fl_slot)
            ld (var_hyp_fin), a
            ld hl, (var_hyp_filecall_fcb)
            ld (asm_1_2832_n_fl_infcb), hl
            ld a, 1
            ld (asm_1_2832_n_fl_infcb + 2), a
            ld hl, 0
            ld (asm_1_2832_n_fl_inrec), hl
            jp asm_1_2832_n_fl_ok
; ---- 22: make (a new file, to write)
asm_1_2832_n_fl_make:
            ld a, (var_hyp_fout)
            or a
            jp nz, asm_1_2832_n_fp_done
            call asm_1_2832_n_fl_name
            call asm_1_2832_n_fl_plain
            ld hl, asm_1_2832_n_fl_name_s + 1
            ld a, (asm_1_2832_n_fl_name_s)
            ld b, a
            ld de, arr_hyp_fob            ; (its 2K buffer: main RAM)
            call #BC8C              ; CAS OUT OPEN
            di
            jp nc, asm_1_2832_n_fp_done
            ld a, (asm_1_2832_n_fl_slot)
            ld (var_hyp_fout), a
            ld hl, (var_hyp_filecall_fcb)
            ld (asm_1_2832_n_fl_outfcb), hl
            ld a, 1
            ld (asm_1_2832_n_fl_outfcb + 2), a
            ld hl, 0
            ld (asm_1_2832_n_fl_outrec), hl
            jp asm_1_2832_n_fl_ok
; ---- 16: close
asm_1_2832_n_fl_close:
            call asm_1_2832_n_fl_isin
            jr nz, asm_1_2832_n_fl_cl_out
            call asm_1_2832_n_fl_inclose
            jp asm_1_2832_n_fl_ok
asm_1_2832_n_fl_cl_out:
            call asm_1_2832_n_fl_isout
            jp nz, asm_1_2832_n_fp_done
            xor a
            ld (var_hyp_fout), a
            call asm_1_2832_n_fl_plain
            call #BC8F              ; CAS OUT CLOSE
            di
            jp nc, asm_1_2832_n_fp_done
            jp asm_1_2832_n_fl_ok
; ---- 19: delete (|ERA, "name")
asm_1_2832_n_fl_del:
            call asm_1_2832_n_fl_name
            call asm_1_2832_n_fl_plain
            ld hl, asm_1_2832_n_fl_name_s + 1
            ld (asm_1_2832_n_fl_desc + 1), hl
            ld a, (asm_1_2832_n_fl_name_s)
            ld (asm_1_2832_n_fl_desc), a
            ld hl, asm_1_2832_n_fl_yes           ; (UniDOS asks before it deletes a folder - all it holds too -,
            ld a, (hl)              ; a read-only or a hidden file: KM WAIT CHAR, its text unseen,
            ld (hl), 0              ; the VDU off. KM CHAR RETURN: the answer waiting for it - N,
            or a                    ; so a CP/M program's delete never takes a folder; Y only after
            ld a, 'N'               ; BDOS 30 op 8, RMDIR's, for its empty folder)
            jr z, asm_1_2832_n_fl_del_n
            ld a, 'Y'
asm_1_2832_n_fl_del_n:
            call #BB0C
            ld hl, asm_1_2832_n_fl_era           ; KL FIND COMMAND; KM READ CHAR after
            call #BCD4              ; takes the answer back when nothing asked
            di
            jp nc, asm_1_2832_n_fp_done
            ld ix, asm_1_2832_n_fl_par
            ld a, 1                 ; one parameter: the string
            call #001B              ; KL FAR PCALL
            call #BB09              ; KM READ CHAR (interrupts: off again in fl_done)
            jp asm_1_2832_n_fl_ok
; ---- 23: rename (the disc ROM's |REN, "new", "old"): the old name at FCB 0-11, the new
; at 16-27 (its drive 0: the old one's)
asm_1_2832_n_fl_ren:
            ld hl, (var_hyp_filecall_fcb)
            call asm_1_2832_n_fl_peek
            ld (asm_1_2832_n_fl_dfl), a
            ld de, 16
            add hl, de
            call asm_1_2832_n_fl_namehl          ; the new name
            xor a
            ld (asm_1_2832_n_fl_dfl), a
            ld hl, asm_1_2832_n_fl_name_s
            ld de, asm_1_2832_n_fl_new_s
            ld bc, asm_1_2832_n_FL_NL
            ldir
            call asm_1_2832_n_fl_name            ; the old one
            call asm_1_2832_n_fl_plain
            ld hl, asm_1_2832_n_fl_name_s + 1
            ld (asm_1_2832_n_fl_desc + 1), hl
            ld a, (asm_1_2832_n_fl_name_s)
            ld (asm_1_2832_n_fl_desc), a
            ld hl, asm_1_2832_n_fl_new_s + 1
            ld (asm_1_2832_n_fl_desc2 + 1), hl
            ld a, (asm_1_2832_n_fl_new_s)
            ld (asm_1_2832_n_fl_desc2), a
            ld hl, asm_1_2832_n_fl_rencmd
            call #BCD4              ; KL FIND COMMAND
            di
            jp nc, asm_1_2832_n_fp_done
            ld ix, asm_1_2832_n_fl_par2          ; IX+0: the last parameter (the old name), IX+2: the new
            ld a, 2
            call #001B              ; KL FAR PCALL
            jp asm_1_2832_n_fl_ok              ; (interrupts: off again in fl_done)
; ---- 33: read record r0-r1: on to it (from the start again if it is behind)
asm_1_2832_n_fl_rdran:
            call asm_1_2832_n_fl_isin
            jp nz, asm_1_2832_n_fl_rdout
            ld hl, (var_hyp_filecall_fcb)
            ld de, 33
            add hl, de
            call asm_1_2832_n_fl_peek
            ld e, a
            inc hl
            call asm_1_2832_n_fl_peek
            ld d, a
            ld (asm_1_2832_n_fl_want), de
            ld hl, (asm_1_2832_n_fl_inrec)
            or a
            sbc hl, de
            jr c, asm_1_2832_n_fl_rr_on
            jr z, asm_1_2832_n_fl_rr_on
            call asm_1_2832_n_fl_inclose         ; behind: open it again
            ld hl, asm_1_2832_n_fl_inname
            ld de, asm_1_2832_n_fl_name_s
            ld bc, asm_1_2832_n_FL_NL
            ldir
            call asm_1_2832_n_fl_inopen
            jp nc, asm_1_2832_n_fp_done
            ld a, (asm_1_2832_n_fl_slot)
            ld (var_hyp_fin), a
            ld hl, 0
            ld (asm_1_2832_n_fl_inrec), hl
asm_1_2832_n_fl_rr_on:
            ld hl, (asm_1_2832_n_fl_inrec)
            ld de, (asm_1_2832_n_fl_want)
            or a
            sbc hl, de
            jr nc, asm_1_2832_n_fl_rdseq
            call asm_1_2832_n_fl_rdrec
            jp z, asm_1_2832_n_fl_eof
            ld hl, (asm_1_2832_n_fl_inrec)
            inc hl
            ld (asm_1_2832_n_fl_inrec), hl
            jr asm_1_2832_n_fl_rr_on
; ---- 20: read the next record
asm_1_2832_n_fl_rdseq:
            call asm_1_2832_n_fl_isin
            jr nz, asm_1_2832_n_fl_rdout
            call asm_1_2832_n_fl_rdrec
            jr z, asm_1_2832_n_fl_eof
            ex de, hl
            ld hl, (asm_1_2832_n_fl_inrec)
            inc hl
            ld (asm_1_2832_n_fl_inrec), hl
            ex de, hl
            ld b, a                 ; the record padded with #1A
            ld a, 128
            sub b
            jr z, asm_1_2832_n_fl_rd_put
            ld b, a
            ld a, #1A
asm_1_2832_n_fl_rd_pad:
            ld (hl), a
            inc hl
            djnz asm_1_2832_n_fl_rd_pad
asm_1_2832_n_fl_rd_put:
            ld hl, (var_hyp_filecall_dma)          ; into the slot's DMA: in one page, one ldir
            ld bc, 128
            call asm_1_2832_n_fl_fits
            jr c, asm_1_2832_n_fl_rd_slow
            ld de, (var_hyp_filecall_buf)
            call asm_1_2832_n_fl_toslot
            jp asm_1_2832_n_fl_ok
asm_1_2832_n_fl_rd_slow:                         ; (across two pages: a byte at a time)
            ld hl, (var_hyp_filecall_buf)
            ld de, (var_hyp_filecall_dma)
            ld b, 128
asm_1_2832_n_fl_rd_cp:
            ld a, (hl)
            ex de, hl
            call asm_1_2832_n_fl_poke
            ex de, hl
            inc hl
            inc de
            djnz asm_1_2832_n_fl_rd_cp
            jp asm_1_2832_n_fl_ok
asm_1_2832_n_fl_rdout:
            call asm_1_2832_n_fl_isout           ; a file being written: nothing to read back
            jp nz, asm_1_2832_n_fp_done
asm_1_2832_n_fl_eof:
            ld a, 1
            ld (asm_1_2832_n_fl_res), a
            jp asm_1_2832_n_fp_done
; ---- 21 / 34: write the next record
asm_1_2832_n_fl_write:
            call asm_1_2832_n_fl_isout
            jp nz, asm_1_2832_n_fp_done
            ld hl, (var_hyp_filecall_dma)          ; the slot's DMA into buf
            ld bc, 128
            call asm_1_2832_n_fl_fits
            jr c, asm_1_2832_n_fl_wr_slow
            ld de, (var_hyp_filecall_buf)
            call asm_1_2832_n_fl_fromslot
            jr asm_1_2832_n_fl_wr_got
asm_1_2832_n_fl_wr_slow:
            ld de, (var_hyp_filecall_buf)
            ld b, 128
asm_1_2832_n_fl_wr_cp:
            call asm_1_2832_n_fl_peek
            ld (de), a
            inc hl
            inc de
            djnz asm_1_2832_n_fl_wr_cp
asm_1_2832_n_fl_wr_got:
            call asm_1_2832_n_fl_plain
            ld hl, (var_hyp_filecall_buf)
            ld b, 128
asm_1_2832_n_fl_wr_lp:
            ld a, (hl)
            push bc
            push hl
            call #BC95              ; CAS OUT CHAR
            di
            pop hl
            pop bc
            jp nc, asm_1_2832_n_fp_done
            inc hl
            djnz asm_1_2832_n_fl_wr_lp
            ld hl, (asm_1_2832_n_fl_outrec)
            inc hl
            ld (asm_1_2832_n_fl_outrec), hl
            jp asm_1_2832_n_fl_ok
; ---- 35: the file's size in records (r0-r2): counted, reading it through. The file this slot
; is reading is opened again after, at its record; another slot's being read: 255
asm_1_2832_n_fl_size:
            ld a, (var_hyp_fin)
            or a
            jr z, asm_1_2832_n_fl_sz_free
            ld b, a
            ld a, (asm_1_2832_n_fl_slot)
            cp b
            jp nz, asm_1_2832_n_fp_done
            call asm_1_2832_n_fl_inclose
            ld a, 1
asm_1_2832_n_fl_sz_free:
            ld (asm_1_2832_n_fl_had), a
            call asm_1_2832_n_fl_name
            call asm_1_2832_n_fl_inopen
            jr nc, asm_1_2832_n_fl_sz_back
            ld hl, 0
            ld (asm_1_2832_n_fl_cnt), hl
asm_1_2832_n_fl_sz_lp:
            call asm_1_2832_n_fl_rdrec
            jr z, asm_1_2832_n_fl_sz_end
            ld hl, (asm_1_2832_n_fl_cnt)
            inc hl
            ld (asm_1_2832_n_fl_cnt), hl
            cp 128
            jr z, asm_1_2832_n_fl_sz_lp
asm_1_2832_n_fl_sz_end:
            call asm_1_2832_n_fl_inclose
            ld hl, (asm_1_2832_n_fl_cnt)
            call asm_1_2832_n_fl_ranput
            xor a
            ld (asm_1_2832_n_fl_res), a
asm_1_2832_n_fl_sz_back:
            ld a, (asm_1_2832_n_fl_had)
            or a
            jp z, asm_1_2832_n_fp_done
            ld hl, asm_1_2832_n_fl_inname        ; the slot's read file again, on to its record
            ld de, asm_1_2832_n_fl_name_s
            ld bc, asm_1_2832_n_FL_NL
            ldir
            call asm_1_2832_n_fl_inopen
            jp nc, asm_1_2832_n_fp_done
            ld a, (asm_1_2832_n_fl_slot)
            ld (var_hyp_fin), a
            ld hl, (asm_1_2832_n_fl_inrec)
asm_1_2832_n_fl_sz_skip:
            ld a, h
            or l
            jp z, asm_1_2832_n_fp_done
            push hl
            call asm_1_2832_n_fl_rdrec
            pop hl
            dec hl
            jr asm_1_2832_n_fl_sz_skip
; ---- 36: set the random record (r0-r2) from where the file is: the next record read or
; written; a file not open here: from the FCB's extent and record (ex * 128 + cr)
asm_1_2832_n_fl_setran:
            call asm_1_2832_n_fl_isin
            ld hl, (asm_1_2832_n_fl_inrec)
            jr z, asm_1_2832_n_fl_sr_put
            call asm_1_2832_n_fl_isout
            ld hl, (asm_1_2832_n_fl_outrec)
            jr z, asm_1_2832_n_fl_sr_put
            ld hl, (var_hyp_filecall_fcb)
            ld de, 32
            add hl, de
            call asm_1_2832_n_fl_peek            ; cr
            ld e, a
            ld bc, -20
            add hl, bc
            call asm_1_2832_n_fl_peek            ; ex
            ld h, a
            srl h
            ld a, e
            jr nc, asm_1_2832_n_fl_sr_lo
            or #80
asm_1_2832_n_fl_sr_lo:
            ld l, a
asm_1_2832_n_fl_sr_put:
            call asm_1_2832_n_fl_ranput
            jp asm_1_2832_n_fl_ok
; ---- 17 / 18: search the folder (UniDOS: the FCB's drive's, else the slot's) for BDOS 17's
; name ("?" any character; kept at SRCH in the bank, SRCH + 12 the entries passed - 18 goes on
; from there): the next one, as a CP/M directory entry at the DMA (its record count from its
; length, 128 at most). 17 examines the folder (Ctrl J) into the hypervisor's page (FL_CACHE-#7BFF:
; 112 entries at most), then 17 and 18 look there. No UniDOS (or an AMSDOS floppy): none (255)
asm_1_2832_n_fl_srch1:
            ld hl, (var_hyp_filecall_fcb)
            ld de, 63216
            ld b, 12
asm_1_2832_n_fl_s1_lp:
            call asm_1_2832_n_fl_peek
            ex de, hl
            call asm_1_2832_n_fl_poke
            ex de, hl
            inc hl
            inc de
            djnz asm_1_2832_n_fl_s1_lp
            ex de, hl
            xor a
            call asm_1_2832_n_fl_poke            ; none passed
            xor a
            ld (asm_1_2832_n_fl_cn), a
            ld hl, asm_1_2832_n_FL_CACHE
            ld (asm_1_2832_n_fl_at), hl
            ld de, asm_1_2832_n_fl_name_s + 1    ; "B:" (or B's path)
            ld hl, 63216
            call asm_1_2832_n_fl_peek
            or a
            jr z, asm_1_2832_n_fl_s_own
            add a, 64
            jr asm_1_2832_n_fl_s_drv
asm_1_2832_n_fl_s_own:
            ld a, (var_hyp_filecall_drive)
            or a
            jr z, asm_1_2832_n_fl_s_nod
asm_1_2832_n_fl_s_drv:
            call asm_1_2832_n_fl_pfx
asm_1_2832_n_fl_s_nod:
; UniDOS: the directory itself (Ctrl J examine), its files into the cache - no file opened (so
; not held up by another slot's reading)
            push de
            call asm_1_2832_n_fl_exdir
            pop de
            jp nz, asm_1_2832_n_fp_done          ; (none to list: no UniDOS, an AMSDOS floppy - 255)
asm_1_2832_n_fl_sx_lp:
            ld hl, (asm_1_2832_n_fl_at)
            inc hl                  ; (the name straight into the entry)
            ld ix, asm_1_2832_n_FL_DATE
            ld c, 13                ; examine next
            call asm_1_2832_n_fl_cjc
            jr nc, asm_1_2832_n_fl_sx_end
            jr nz, asm_1_2832_n_fl_sx_end
            bit 4, a
            jr nz, asm_1_2832_n_fl_sx_lp         ; (a folder: not for CP/M)
            ld hl, (asm_1_2832_n_fl_at)
            ld (hl), 1              ; in use
            ld a, b
            or c
            jr z, asm_1_2832_n_fl_sx_sz
            ld de, #FFFF            ; (64K or more)
asm_1_2832_n_fl_sx_sz:
            ld bc, 12
            add hl, bc
            ld (hl), b              ; kind, flags 0
            inc hl
            ld (hl), b
            inc hl
            ld (hl), e              ; its length
            inc hl
            ld (hl), d
            ld hl, (asm_1_2832_n_fl_at)
            ld bc, 64
            add hl, bc
            ld (asm_1_2832_n_fl_at), hl
            ld hl, asm_1_2832_n_fl_cn
            inc (hl)
            ld a, (hl)
            cp asm_1_2832_n_FL_CMAX
            jr c, asm_1_2832_n_fl_sx_lp
asm_1_2832_n_fl_sx_end:
            jp asm_1_2832_n_fl_srch
asm_1_2832_n_fl_srch:
            ld hl, 63216 + 12
            call asm_1_2832_n_fl_peek
            ld (asm_1_2832_n_fl_skip), a
            xor a
            ld (asm_1_2832_n_fl_k), a
asm_1_2832_n_fl_s_lp:
            ld a, (asm_1_2832_n_fl_cn)           ; the next entry, from the cache
            ld b, a
            ld a, (asm_1_2832_n_fl_k)
            cp b
            jp nc, asm_1_2832_n_fp_done          ; (none: 255)
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, asm_1_2832_n_FL_CACHE
            add hl, de
            ld de, (var_hyp_filecall_buf)
            ld bc, 64
            ldir
            ld hl, asm_1_2832_n_fl_k
            inc (hl)
            ld a, (asm_1_2832_n_fl_skip)
            cp (hl)
            jr nc, asm_1_2832_n_fl_s_lp          ; passed already
            ld hl, (var_hyp_filecall_buf)
            ld a, (hl)
            dec a
            jr nz, asm_1_2832_n_fl_s_lp          ; not in use (1)
            inc hl
            ld de, 63216 + 1
            ld b, 11
asm_1_2832_n_fl_s_cmp:
            ex de, hl
            call asm_1_2832_n_fl_peek
            ex de, hl
            and #7F
            cp '?'
            jr z, asm_1_2832_n_fl_s_any
            ld c, a
            ld a, (hl)
            and #7F
            cp c
            jr nz, asm_1_2832_n_fl_s_lp
asm_1_2832_n_fl_s_any:
            inc hl
            inc de
            djnz asm_1_2832_n_fl_s_cmp
            ld hl, (var_hyp_filecall_buf)          ; the entry: user 0, the name, extent 0, the records, no blocks
            ld (hl), 0
            ld de, 14
            add hl, de
            ld e, (hl)
            inc hl
            ld d, (hl)
            ex de, hl
            ld bc, 127
            add hl, bc
            jr c, asm_1_2832_n_fl_s_big
            ld a, h
            cp #40
            jr nc, asm_1_2832_n_fl_s_big
            sla l
            rla
            jr asm_1_2832_n_fl_s_rc
asm_1_2832_n_fl_s_big:
            ld a, 128
asm_1_2832_n_fl_s_rc:
            ex de, hl
            ld (hl), a
            ld b, 3
asm_1_2832_n_fl_s_z1:
            dec hl
            ld (hl), 0
            djnz asm_1_2832_n_fl_s_z1
            ld de, 4
            add hl, de
            ld b, 16
asm_1_2832_n_fl_s_z2:
            ld (hl), 0
            inc hl
            djnz asm_1_2832_n_fl_s_z2
            ld hl, (var_hyp_filecall_dma)
            ld de, (var_hyp_filecall_buf)
            ld b, 32
asm_1_2832_n_fl_s_put:
            ld a, (de)
            call asm_1_2832_n_fl_poke
            inc hl
            inc de
            djnz asm_1_2832_n_fl_s_put
            ld hl, 63216 + 12
            ld a, (asm_1_2832_n_fl_k)
            call asm_1_2832_n_fl_poke
            jp asm_1_2832_n_fl_ok
asm_1_2832_n_fl_skip:    db 0
asm_1_2832_n_fl_k:       db 0
asm_1_2832_n_fl_cn:      db 0                    ; the folder's entries in the cache (FL_CACHE)
asm_1_2832_n_fl_ranput:                          ; the FCB's r0-r2 = HL
            ex de, hl
            ld hl, (var_hyp_filecall_fcb)
            ld bc, 33
            add hl, bc
            ld a, e
            call asm_1_2832_n_fl_poke
            inc hl
            ld a, d
            call asm_1_2832_n_fl_poke
            inc hl
            xor a
            jp asm_1_2832_n_fl_poke
; ---- the parts
asm_1_2832_n_fl_inopen:                          ; open fl_name_s to read: carry = done
            call asm_1_2832_n_fl_plain
            ld hl, asm_1_2832_n_fl_name_s + 1
            ld a, (asm_1_2832_n_fl_name_s)
            ld b, a
            ld de, arr_hyp_fib            ; (its 2K buffer: main RAM)
            call #BC77              ; CAS IN OPEN
            di
            ld (asm_1_2832_n_fl_hdr), hl         ; (its header: BDOS 30 #C7)
            ret
asm_1_2832_n_fl_inclose:
            xor a
            ld (var_hyp_fin), a
            call asm_1_2832_n_fl_plain
            call #BC7A              ; CAS IN CLOSE
            di
            ret
asm_1_2832_n_fl_rdrec:                           ; read up to fl_n bytes (128) into buf: A = how many (Z
            call asm_1_2832_n_fl_plain           ; none), HL past them. A #1A is a byte (the soft end of file)
            ld hl, (var_hyp_filecall_buf)
            ld a, (asm_1_2832_n_fl_n)
            ld b, a
asm_1_2832_n_fl_rr_lp:
            push bc
            push hl
            call #BC80              ; CAS IN CHAR
            di
            pop hl
            pop bc
            jr c, asm_1_2832_n_fl_rr_b
            cp #1A
            jr nz, asm_1_2832_n_fl_rr_end
asm_1_2832_n_fl_rr_b:
            ld (hl), a
            inc hl
            djnz asm_1_2832_n_fl_rr_lp
asm_1_2832_n_fl_rr_end:
            ld a, (asm_1_2832_n_fl_n)
            sub b
            ld c, a
            ld a, 128
            ld (asm_1_2832_n_fl_n), a            ; (128 again for the next)
            ld a, c
            or a
            ret
asm_1_2832_n_fl_fits:                            ; HL = a slot address, BC = bytes: NC = all in its 16K page.
            push hl                 ; Keeps BC, DE, HL
            ld a, h
            and #3F
            ld h, a
            add hl, bc
            ld a, h
            cp #40
            jr c, asm_1_2832_n_fl_ft_ok
            jr nz, asm_1_2832_n_fl_ft_no
            ld a, l
            or a
            jr nz, asm_1_2832_n_fl_ft_no
asm_1_2832_n_fl_ft_ok:
            pop hl
            or a
            ret
asm_1_2832_n_fl_ft_no:
            pop hl
            scf
            ret
asm_1_2832_n_fl_plain:                           ; the hypervisor's page in the window (the page code)
            ld bc, (var_hyp_hps)
            out (c), c
            ret
            ASSERT (arr_hyp_fib >= #8000) && (arr_hyp_fob >= #8000), "the disc buffers must be at #8000 or above (a firmware call has the lower ROM in)"
asm_1_2832_n_fl_name:                            ; fl_name_s = the FCB's file: length, "B:NAME.EXT"
            ld hl, (var_hyp_filecall_fcb)
asm_1_2832_n_fl_namehl:                          ; (HL = an FCB in the slot)
            ld de, asm_1_2832_n_fl_name_s + 1
            call asm_1_2832_n_fl_peek            ; its drive: 0 = the slot's (or fl_dfl's)
            or a
            jr nz, asm_1_2832_n_fl_nm_d
            ld a, (asm_1_2832_n_fl_dfl)
            or a
            jr nz, asm_1_2832_n_fl_nm_d
            ld a, (var_hyp_filecall_drive)
            or a
            jr z, asm_1_2832_n_fl_nm_nod
            sub 64
asm_1_2832_n_fl_nm_d:
            add a, 64
            call asm_1_2832_n_fl_pfx             ; "B:", or B's path (UniDOS: "IDE:GAMES/")
asm_1_2832_n_fl_nm_nod:
            ld b, 11
asm_1_2832_n_fl_nm_lp:
            inc hl
            ld a, b
            cp 3
            jr nz, asm_1_2832_n_fl_nm_c
            ld a, '.'
            ld (de), a
            inc de
asm_1_2832_n_fl_nm_c:
            call asm_1_2832_n_fl_peek
            and #7F
            cp ' ' + 1
            jr c, asm_1_2832_n_fl_nm_sk
            ld (de), a
            inc de
asm_1_2832_n_fl_nm_sk:
            djnz asm_1_2832_n_fl_nm_lp
            ex de, hl
            ld de, asm_1_2832_n_fl_name_s + 1
            or a
            sbc hl, de
            ld a, l
            ld (asm_1_2832_n_fl_name_s), a
            ret
asm_1_2832_n_fl_ok:
            xor a
            ld (asm_1_2832_n_fl_res), a
asm_1_2832_n_fp_done:                            ; back to FileCall in main RAM (fp_done)
            ld sp, (asm_1_2832_n_fp_sp)
            ret
asm_1_2832_n_fl_era:     db "ER", "A" + #80
asm_1_2832_n_fl_rencmd:  db "RE", "N" + #80
asm_1_2832_n_fl_par2:    dw asm_1_2832_n_fl_desc, asm_1_2832_n_fl_desc2
asm_1_2832_n_fl_desc2:   db 0
            dw 0
asm_1_2832_n_fl_dfl:     db 0                    ; fl_name: the drive for an FCB whose own is 0 (rename)
asm_1_2832_n_fl_par:     dw asm_1_2832_n_fl_desc
asm_1_2832_n_fl_desc:    db 0
            dw 0
asm_1_2832_n_fl_n:       db 128                  ; bytes fl_rdrec reads
asm_1_2832_n_fl_cnt:     dw 0
asm_1_2832_n_fl_at:      dw 0
asm_1_2832_n_fl_infcb:   dw 0
            db 0                    ; (1: fl_infcb the open's - fl_is)
asm_1_2832_n_fl_inrec:   dw 0
asm_1_2832_n_fl_want:    dw 0
asm_1_2832_n_fl_outfcb:  dw 0
            db 0
asm_1_2832_n_fl_outrec:  dw 0                    ; the next record written (36)
asm_1_2832_n_fl_had:     db 0                    ; 35: this slot's read file closed for it
asm_1_2832_n_fp_sp:      dw 0
; ---- UniDOS: its Ctrl J BIOS command (found once, KL FIND COMMAND) - a drive letter can be a
; path (CD IDE:, CD SD:GAMES ...: any UniDOS device's folder), folders listed (examine). FL_MAP:
; letters A-P, 32 bytes each: the path's length (0 none: the letter itself, "B:"), the path
; ("IDE:GAMES/": a device or logical drive, its folders, the last "/" or ":"). Cleared when
; UniDOS is found, and only set with it: with AMSDOS no letter has a path. Up there with the
; names (48 characters: a path and NAME.EXT), BDOS 132's block, DIR's listing: the FILES.DIR
; cache is #6000-#7BFF (112 entries; the page code ends by #6000: the service page's code is
; there in the file)
asm_1_2832_n_FL_CACHE:   equ #6000               ; the cache's first entry
asm_1_2832_n_FL_CMAX:    equ 112                 ; the cache's entries
asm_1_2832_n_FL_NL:      equ 49                  ; a name: its length, then the characters
asm_1_2832_n_fl_name_s:  equ #7C00               ; length, then "B:NAME.EXT" (or "IDE:GAMES/NAME.EXT")
asm_1_2832_n_fl_inname:  equ asm_1_2832_n_fl_name_s + asm_1_2832_n_FL_NL   ; the one being read's (33 going back)
asm_1_2832_n_fl_new_s:   equ asm_1_2832_n_fl_inname + asm_1_2832_n_FL_NL   ; (23: the new name)
asm_1_2832_n_FL_UB:      equ #7D00               ; BDOS 132's block (72 bytes)
asm_1_2832_n_FL_EXK:     equ #7D48               ; the folder DIR lists (its path: length, 31 characters)
asm_1_2832_n_FL_DATE:    equ #7D68               ; a date examine gives (7), then a name (11)
asm_1_2832_n_FL_TN:      equ #7D70
asm_1_2832_n_FL_MAP:     equ #7E00
            ASSERT asm_1_2832_n_FL_CACHE + asm_1_2832_n_FL_CMAX * 64 <= asm_1_2832_n_fl_name_s, "the search's cache, below the names"
            ASSERT asm_1_2832_n_fl_new_s + asm_1_2832_n_FL_NL <= asm_1_2832_n_FL_UB, "the names, below BDOS 132's block"
            ASSERT (asm_1_2832_n_FL_MAP & 255) = 0, "asm_1_2832_n_FL_MAP: a page's start (asm_1_2832_n_fl_mapa)"
asm_1_2832_n_fl_cjf:     db 0                    ; 0: not looked for yet, 1: UniDOS, 2: none
asm_1_2832_n_fl_cjn:     db #8A                  ; (its name)
asm_1_2832_n_fl_exv:     db 0                    ; FL_EXK's listing is the one UniDOS examines now ...
asm_1_2832_n_fl_exi:     dw 0                    ; ... at this entry next
asm_1_2832_n_fl_ue:      dw 0
; carry: UniDOS here (the first time: looked for, the paths cleared)
asm_1_2832_n_fl_uni:
            ld a, (asm_1_2832_n_fl_cjf)
            cp 1
            jr z, asm_1_2832_n_fl_un_y
            or a
            ret nz                  ; (2: none - NC)
            call asm_1_2832_n_fl_fcj             ; C = its ROM, HL = its address (not KL FIND COMMAND: the M4's
            di                      ; ROM has a Ctrl J too - a restart - and is found first)
            ld a, 2
            jr nc, asm_1_2832_n_fl_un_s
            ld (asm_1_2832_n_fl_cjfa), hl        ; (in main RAM: fl_cjm calls it from there)
            ld a, c
            ld (asm_1_2832_n_fl_cjfa + 2), a
            ld hl, asm_1_2832_n_FL_MAP
            ld de, asm_1_2832_n_FL_MAP + 1
            ld bc, 511
            ld (hl), 0
            ldir
            ld a, 1
asm_1_2832_n_fl_un_s:
            ld (asm_1_2832_n_fl_cjf), a
            jr asm_1_2832_n_fl_uni
asm_1_2832_n_fl_un_y:
            scf
            ret
; Ctrl J command C (the other registers its input; its output back)
asm_1_2832_n_fl_cjc:
            jp asm_1_2832_n_fl_cjm               ; (from main RAM: UniDOS leaves C0 in, not this page)
; A = a drive letter: HL = its FL_MAP entry, A = its path's length (Z: none). Carry: not A-P,
; or no UniDOS (no paths). A, HL only
asm_1_2832_n_fl_mapa:
            sub 'A'
            cp 16
            ccf
            ret c
            ld l, a
            ld a, (asm_1_2832_n_fl_cjf)
            cp 1
            scf
            ret nz
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld a, h
            add a, asm_1_2832_n_FL_MAP / 256
            ld h, a
            ld a, (hl)
            or a
            ret
; A = a drive letter: "B:" at DE, or its path - DE past it (BC, HL kept). Without UniDOS the
; boot drive's letter is left off (the bare name: the current drive's): the M4's ROM knows no
; drive letters - "A:KERNEL.CYB" isn't found there. With UniDOS "A:" stays: it's A's own folder
; (IDE:CYBORGOS ...) there, and DIR's listings need it
asm_1_2832_n_fl_pfx:
            push af
            call asm_1_2832_n_fl_pfxm
            jr nz, asm_1_2832_n_fl_px_d
            push bc
            push de
            push hl
            call asm_1_2832_n_fl_uni             ; (carry: UniDOS - looked for the first time)
            pop hl
            pop de
            pop bc
            jr c, asm_1_2832_n_fl_px_u
            pop af
            push hl
            ld hl, var_hyp_svbd
            cp (hl)
            pop hl
            ret z
            jr asm_1_2832_n_fl_px_l
asm_1_2832_n_fl_px_u:
            pop af
asm_1_2832_n_fl_px_l:
            ld (de), a
            inc de
            ld a, ':'
            ld (de), a
            inc de
            ret
asm_1_2832_n_fl_px_d:
            pop af
            ret
; ... its path only, if it has one (NZ; Z: none, nothing put)
asm_1_2832_n_fl_pfxm:
            push hl
            call asm_1_2832_n_fl_mapa
            jr c, asm_1_2832_n_fl_pm_no
            jr z, asm_1_2832_n_fl_pm_no
            push bc
            ld c, a
            ld b, 0
            inc hl
            ldir
            pop bc
            or a
            jr asm_1_2832_n_fl_pm_r
asm_1_2832_n_fl_pm_no:
            xor a
asm_1_2832_n_fl_pm_r:
            pop hl
            ret
asm_1_2832_n_fl_nlen:                            ; fl_name_s's length: its characters end at DE
            ld hl, -(asm_1_2832_n_fl_name_s + 1)
            add hl, de
            ld a, l
            ld (asm_1_2832_n_fl_name_s), a
            ret
; the folder whose path is at fl_name_s + 1 to DE (fl_exdir2: fl_name_s, its length set)
; examined (Ctrl J 12): Z its listing ready (examine next: Ctrl J 13), NZ no UniDOS, a drive
; it can't examine (AMSDOS's floppies), not a folder
asm_1_2832_n_fl_exdir:
            call asm_1_2832_n_fl_nlen
asm_1_2832_n_fl_exdir2:
            call asm_1_2832_n_fl_uni
            jr nc, asm_1_2832_n_fl_ed_no
            xor a
            ld (asm_1_2832_n_fl_exv), a
            ld hl, asm_1_2832_n_fl_name_s
            ld b, (hl)
            inc hl
            ld ix, asm_1_2832_n_FL_DATE
            ld c, 12
            call asm_1_2832_n_fl_cjc
            ret c
asm_1_2832_n_fl_ed_no:
            ld a, 254               ; (254: no UniDOS, or a drive it can't examine)
            or a
            ret
; ---- 30: CP/M's set file attributes - not done here (255) - unless the block at DE (72 bytes)
; is CyborgOS's UniDOS call (CD, DIR): Byte(0) #C0 + the call (an FCB's drive byte is 0-16:
; never that), Byte(1) a drive letter (A-P). 255: no UniDOS (or a bad block). So Main sends it
; here with the other file calls, nothing of its own
;   0  UniDOS here: 0
;   1  the letter's path to Byte(2) (its length - 0 none -, the path)
;   2  the letter's path from Byte(2) (length, 31 at most - a "/" put at its end if it has no
;      "/" or ":" there -; 0: none, the letter itself again): it must be a folder (examined;
;      a drive UniDOS can't examine - DFA:, DFB:, AMSDOS's floppies - is taken as it is):
;      0 set, else UniDOS's error (not 0; 254 a drive it can't examine - a floppy AMSDOS has)
;   3  the devices (Ctrl J 1): 64 bytes at Byte(2) (names, the last character + #80, 255 the end)
;   4  a device (Ctrl J 2): its name at Byte(2) (the last character + #80) - 64 bytes at
;      Byte(8): the status (bit 0 there, 1 folders, 2 read only, 3 removable, 4 a stream, 5
;      the new API), -, free K (4 bytes), all K (4), the description (the last + #80)
;   5  the letter's folder's entry Word(2) (0 the first): Byte(4) its protection bits (bit 0
;      read only, 1 hidden, 2 system, 4 a folder), Byte(5-8) its size, Byte(9-15) its date (year
;      word, month, day, hours, minutes, seconds), Byte(16-26) its name (8 + 3): 0; 1 no more.
;      Byte(1) 0: the folder's path at Byte(28) (length, path) instead. One after another
;      (0, 1, 2 ...) each is the next examined, else the folder is examined again to it
;   6  a folder made: its path at Byte(2) (length, path ending "/": "IDE:GAMES/NEW/"): 0, else
;      UniDOS's error (255 also while a file is being written)
;   7  the header of the file this slot reads (the disc ROM's copy, 69 bytes - UniDOS's made-up
;      one for a file with none: its 24 bit length at 64 #800000) at Byte(2): 0; 255 none open
asm_1_2832_n_fl_unicall:
            ld hl, (var_hyp_filecall_fcb)
            ld de, asm_1_2832_n_FL_UB
            ld b, 72
asm_1_2832_n_fl_uc_in:
            call asm_1_2832_n_fl_peek
            ld (de), a
            inc hl
            inc de
            djnz asm_1_2832_n_fl_uc_in
            ld a, (asm_1_2832_n_FL_UB)
            sub #C0
            cp 9
            jp nc, asm_1_2832_n_fp_done          ; (CP/M's 30)
            ld (asm_1_2832_n_FL_UB), a
            call asm_1_2832_n_fl_uni
            jp nc, asm_1_2832_n_fp_done
            ld a, (asm_1_2832_n_FL_UB)
            or a
            jp z, asm_1_2832_n_fl_ok
            dec a
            jp z, asm_1_2832_n_fl_uc_get
            dec a
            jp z, asm_1_2832_n_fl_uc_set
            dec a
            jp z, asm_1_2832_n_fl_uc_dev
            dec a
            jp z, asm_1_2832_n_fl_uc_inf
            dec a
            jp z, asm_1_2832_n_fl_uc_dir
            dec a
            jr z, asm_1_2832_n_fl_uc_md
            cp 2
            jr z, asm_1_2832_n_fl_uc_yes
            ld a, (var_hyp_fin)           ; 7: the header of the file this slot reads (the disc ROM's,
            ld hl, asm_1_2832_n_fl_slot          ; from CAS IN OPEN: 69 bytes) to Byte(2)
            cp (hl)
            jp nz, asm_1_2832_n_fp_done
            ld hl, (asm_1_2832_n_fl_hdr)
            ld de, asm_1_2832_n_FL_UB + 2
            ld bc, 69
            ldir
            xor a
            ld b, 71
            jp asm_1_2832_n_fl_uc_back
asm_1_2832_n_fl_hdr:     dw 0
asm_1_2832_n_fl_uc_yes:                          ; 8: the next delete (19) may take a folder (RMDIR's)
            ld a, 1
            ld (asm_1_2832_n_fl_yes), a
            jp asm_1_2832_n_fl_ok
asm_1_2832_n_fl_yes:     db 0
asm_1_2832_n_fl_uc_md:                           ; 6: a folder made (CAS OUT OPEN, the path ending "/")
            ld a, (var_hyp_fout)
            or a
            jp nz, asm_1_2832_n_fp_done
            ld hl, asm_1_2832_n_FL_UB + 2
            ld a, (hl)
            or a
            jp z, asm_1_2832_n_fp_done
            ld b, a
            inc hl
            ld de, arr_hyp_fob            ; (its 2K buffer: main RAM)
            call #BC8C              ; CAS OUT OPEN
            di
            jr nc, asm_1_2832_n_fl_md_nc
            call #BC92              ; (a file: CAS OUT ABANDON - not made)
            di
            ld a, 1
            jr asm_1_2832_n_fl_md_r
asm_1_2832_n_fl_md_nc:
            and #7F
            cp #17                  ; (DSK_ERR_DIRECTORY_FOUND: made)
            jp z, asm_1_2832_n_fl_ok
            or a
            jr nz, asm_1_2832_n_fl_md_r
            inc a
asm_1_2832_n_fl_md_r:
            ld (asm_1_2832_n_fl_res), a
            jp asm_1_2832_n_fp_done
asm_1_2832_n_fl_uc_back:                         ; A the answer, the block's first B bytes back to the slot
            ld (asm_1_2832_n_fl_res), a
            ld a, (asm_1_2832_n_FL_UB)
            add a, #C0
            ld (asm_1_2832_n_FL_UB), a
            ld hl, (var_hyp_filecall_fcb)
            ld de, asm_1_2832_n_FL_UB
asm_1_2832_n_fl_uc_out:
            ld a, (de)
            call asm_1_2832_n_fl_poke
            inc hl
            inc de
            djnz asm_1_2832_n_fl_uc_out
            jp asm_1_2832_n_fp_done
asm_1_2832_n_fl_uc_get:
            ld a, (asm_1_2832_n_FL_UB + 1)
            call asm_1_2832_n_fl_mapa
            jp c, asm_1_2832_n_fp_done
            ld de, asm_1_2832_n_FL_UB + 2
            ld c, (hl)
            ld b, 0
            inc bc
            ldir
            xor a
            ld b, 34
            jr asm_1_2832_n_fl_uc_back
asm_1_2832_n_fl_uc_dev:
            ld de, asm_1_2832_n_FL_UB + 2
            ld c, 1
            call asm_1_2832_n_fl_cjc
            jp nc, asm_1_2832_n_fp_done
            xor a
            ld b, 66
            jr asm_1_2832_n_fl_uc_back
asm_1_2832_n_fl_uc_inf:
            ld hl, asm_1_2832_n_FL_UB + 2
            ld de, asm_1_2832_n_FL_UB + 8
            ld c, 2
            call asm_1_2832_n_fl_cjc
            jp nc, asm_1_2832_n_fp_done
            xor a
            ld b, 72
            jr asm_1_2832_n_fl_uc_back
asm_1_2832_n_fl_uc_set:
            ld a, (asm_1_2832_n_FL_UB + 1)
            call asm_1_2832_n_fl_mapa
            jp c, asm_1_2832_n_fp_done
            ld (asm_1_2832_n_fl_ue), hl
            xor a
            ld (asm_1_2832_n_fl_exv), a
            ld a, (asm_1_2832_n_FL_UB + 2)
            or a
            jr z, asm_1_2832_n_fl_us_put         ; none: the letter itself again
            cp 32
            jp nc, asm_1_2832_n_fp_done
            ld b, a
            ld hl, asm_1_2832_n_FL_UB + 3
asm_1_2832_n_fl_us_up:                           ; capitals
            ld a, (hl)
            cp 'a'
            jr c, asm_1_2832_n_fl_us_c
            cp 'z' + 1
            jr nc, asm_1_2832_n_fl_us_c
            sub 32
            ld (hl), a
asm_1_2832_n_fl_us_c:
            inc hl
            djnz asm_1_2832_n_fl_us_up
            dec hl
            ld a, (hl)
            cp ':'
            jr z, asm_1_2832_n_fl_us_ex
            cp '/'
            jr z, asm_1_2832_n_fl_us_ex
            ld a, (asm_1_2832_n_FL_UB + 2)
            cp 31
            jp nc, asm_1_2832_n_fp_done
            inc a
            ld (asm_1_2832_n_FL_UB + 2), a
            inc hl
            ld (hl), '/'
asm_1_2832_n_fl_us_ex:
            ld a, (hl)              ; (its last character, kept: ':' a device's top)
            push af
            ld hl, asm_1_2832_n_FL_UB + 2        ; a folder?
            ld de, asm_1_2832_n_fl_name_s
            ld bc, 32
            ldir
            call asm_1_2832_n_fl_exdir2
            pop bc                  ; (B: the last character - the flags kept)
            jr z, asm_1_2832_n_fl_us_put
            cp 254
            jr z, asm_1_2832_n_fl_us_put         ; (a floppy AMSDOS runs - DFA:, DFB: - can't be examined: taken)
            cp 18                   ; a device's top with nothing on it (UniDOS's examine: 18, no
            jr nz, asm_1_2832_n_fl_us_e18        ; entry - an empty SD: or UMS:): taken, as BASIC takes it
            ld a, b
            cp ':'
            jr z, asm_1_2832_n_fl_us_put
            ld a, 18
asm_1_2832_n_fl_us_e18:
            or a
            jr nz, asm_1_2832_n_fl_us_err
            inc a
asm_1_2832_n_fl_us_err:
            ld (asm_1_2832_n_fl_res), a
            jp asm_1_2832_n_fp_done
asm_1_2832_n_fl_us_put:
            ld hl, asm_1_2832_n_FL_UB + 2
            ld de, (asm_1_2832_n_fl_ue)
            ld bc, 32
            ldir
            jp asm_1_2832_n_fl_ok
asm_1_2832_n_fl_uc_dir:
            ld de, asm_1_2832_n_fl_name_s + 1    ; the folder's path
            ld a, (asm_1_2832_n_FL_UB + 1)
            or a
            jr z, asm_1_2832_n_fl_ud_p
            call asm_1_2832_n_fl_pfx
            jr asm_1_2832_n_fl_ud_k
asm_1_2832_n_fl_ud_p:
            ld hl, asm_1_2832_n_FL_UB + 28
            ld a, (hl)
            cp 32
            jp nc, asm_1_2832_n_fp_done
            ld c, a
            ld b, 0
            inc hl
            ldir
asm_1_2832_n_fl_ud_k:
            call asm_1_2832_n_fl_nlen
            ld hl, asm_1_2832_n_fl_name_s        ; the same folder, still the one examined, at this entry:
            ld de, asm_1_2832_n_FL_EXK           ; on from there
            ld a, (asm_1_2832_n_fl_exv)
            or a
            jr z, asm_1_2832_n_fl_ud_new
            ld a, (hl)
            inc a
            ld b, a
asm_1_2832_n_fl_ud_cmp:
            ld a, (de)
            cp (hl)
            jr nz, asm_1_2832_n_fl_ud_new
            inc hl
            inc de
            djnz asm_1_2832_n_fl_ud_cmp
            ld hl, (asm_1_2832_n_fl_exi)
            ld de, (asm_1_2832_n_FL_UB + 2)
            or a
            sbc hl, de
            jr z, asm_1_2832_n_fl_ud_next
asm_1_2832_n_fl_ud_new:
            ld hl, asm_1_2832_n_fl_name_s
            ld de, asm_1_2832_n_FL_EXK
            ld bc, 32
            ldir
            call asm_1_2832_n_fl_exdir2
            jr z, asm_1_2832_n_fl_ud_ok
            or a
            jr nz, asm_1_2832_n_fl_us_err
            inc a
            jr asm_1_2832_n_fl_us_err
asm_1_2832_n_fl_ud_ok:
            ld hl, 0
            ld (asm_1_2832_n_fl_exi), hl
            ld a, 1
            ld (asm_1_2832_n_fl_exv), a
asm_1_2832_n_fl_ud_skip:                         ; on to entry Word(2)
            ld hl, (asm_1_2832_n_fl_exi)
            ld de, (asm_1_2832_n_FL_UB + 2)
            or a
            sbc hl, de
            jr z, asm_1_2832_n_fl_ud_next
            ld hl, asm_1_2832_n_FL_TN
            ld ix, asm_1_2832_n_FL_DATE
            ld c, 13
            call asm_1_2832_n_fl_cjc
            jr nc, asm_1_2832_n_fl_ud_end
            jr nz, asm_1_2832_n_fl_ud_end
            ld hl, (asm_1_2832_n_fl_exi)
            inc hl
            ld (asm_1_2832_n_fl_exi), hl
            jr asm_1_2832_n_fl_ud_skip
asm_1_2832_n_fl_ud_next:
            ld hl, asm_1_2832_n_FL_UB + 16
            ld ix, asm_1_2832_n_FL_UB + 9
            ld c, 13
            call asm_1_2832_n_fl_cjc
            jr nc, asm_1_2832_n_fl_ud_end
            jr nz, asm_1_2832_n_fl_ud_end
            ld (asm_1_2832_n_FL_UB + 4), a
            ld (asm_1_2832_n_FL_UB + 5), de
            ld (asm_1_2832_n_FL_UB + 7), bc
            ld hl, (asm_1_2832_n_fl_exi)
            inc hl
            ld (asm_1_2832_n_fl_exi), hl
            xor a
            ld b, 28
            jp asm_1_2832_n_fl_uc_back
asm_1_2832_n_fl_ud_end:
            xor a
            ld (asm_1_2832_n_fl_exv), a
            inc a
            ld (asm_1_2832_n_fl_res), a
            jp asm_1_2832_n_fp_done
asm_1_2832_n_fp_end:
            ASSERT asm_1_2832_n_fp_end <= asm_1_2832_n_FL_CACHE, "FileCall's page code: below the search's cache (asm_1_2832_n_FL_CACHE)"
            ASSERT asm_1_2832_n_fp_end <= #6000, "FileCall's page code: below #6000 (the service page's code is there in the file: ds #6000 - $)"
; ---- the service page's code (window data from #6000, copied there by FileCall 99)
            ds #6000 - $
asm_1_4568_n_sv_go:
            ld (asm_1_4568_n_sv_sp), sp
            ld hl, (var_hyp_svc_p)            ; p 0: slot t's claims freed (Main's FilesShut)
            ld a, h
            or l
            jp z, asm_1_4568_n_sv_cfree
            ld hl, (var_hyp_svc_p)            ; the request (16 bytes) from the slot
            ld de, (var_hyp_svc_setting)
            call asm_1_4568_n_sv_sw
            push bc
            pop ix
            ld iy, (var_hyp_svp)
            ld de, asm_1_4568_n_sv_blk
            ld a, 16
            call asm_1_4568_n_sv_dx
            ld hl, (asm_1_4568_n_sv_blk + 8)     ; how many: 2K at most
            bit 7, h
            jr nz, asm_1_4568_n_sv_n2
            ld de, 2049
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_4568_n_sv_n1
asm_1_4568_n_sv_n2:
            ld hl, 2048
asm_1_4568_n_sv_n1:
            ld (asm_1_4568_n_sv_n), hl
            xor a
            ld (asm_1_4568_n_sv_stop), a
            ld a, 2                 ; (the copies to the slot: its bank)
            ld (asm_1_4568_n_sv_dk), a
            ld hl, (var_hyp_svc_setting)
            ld (asm_1_4568_n_sv_ds), hl
            ld hl, (asm_1_4568_n_sv_blk + 6)
            ld (asm_1_4568_n_sv_da), hl
            ld a, (asm_1_4568_n_sv_blk)
            cp 10
            jp z, asm_1_4568_n_sv_mem
            cp 11
            jp z, asm_1_4568_n_sv_ptr
            cp 13
            jp z, asm_1_4568_n_sv_store
            cp 14
            jp z, asm_1_4568_n_sv_store
            cp 15
            jp z, asm_1_4568_n_sv_tab
            cp 16
            jp c, asm_1_4568_n_sv_err
            cp 20
            jp c, asm_1_4568_n_sv_claim
            cp 28
            jp c, asm_1_4568_n_sv_net
            cp 34
            jp c, asm_1_4568_n_sv_port
            jp z, asm_1_4568_n_pt_list
asm_1_4568_n_sv_err:
            ld sp, (asm_1_4568_n_sv_sp)
            ld a, 255
            ret
asm_1_4568_n_sv_ok:
            ld sp, (asm_1_4568_n_sv_sp)
            xor a
            ret
; 10: memory
asm_1_4568_n_sv_mem:
            ld a, (asm_1_4568_n_sv_blk + 1)
            cp 4
            jr z, asm_1_4568_n_sv_m4             ; 4: the caller's Word(6) into slot Word(2) at Word(4)
            ld hl, (asm_1_4568_n_sv_blk + 4)
            ld (asm_1_4568_n_sv_sa), hl
            ld hl, (asm_1_4568_n_sv_blk + 2)
            or a
            jr nz, asm_1_4568_n_sv_m1
            ld de, (mem_count)      ; 0: a page (below Pages)
            push hl
            or a
            sbc hl, de
            pop hl
            jp nc, asm_1_4568_n_sv_err
            call asm_1_4568_n_sv_pgset
            ld (asm_1_4568_n_sv_ss), bc
            ld a, 1
            ld (asm_1_4568_n_sv_stop), a
            jr asm_1_4568_n_sv_mgo
asm_1_4568_n_sv_m1:
            dec a
            jr nz, asm_1_4568_n_sv_m2
            ld (asm_1_4568_n_sv_ss), hl          ; 1: a ROM
            ld a, 1
            ld (asm_1_4568_n_sv_stop), a
            ld a, 3
            jr asm_1_4568_n_sv_mgo1
asm_1_4568_n_sv_m2:
            dec a
            jr nz, asm_1_4568_n_sv_m3
            ld a, 4                 ; 2: main RAM
            jr asm_1_4568_n_sv_mgo1
asm_1_4568_n_sv_m3:
            dec a
            jp nz, asm_1_4568_n_sv_err
            call asm_1_4568_n_sv_slot            ; 3: a slot's memory (one in use)
            jp z, asm_1_4568_n_sv_err
            ld (asm_1_4568_n_sv_ss), de
            ld a, 2
            jr asm_1_4568_n_sv_mgo1
asm_1_4568_n_sv_mgo:
            ld a, 1
asm_1_4568_n_sv_mgo1:
            ld (asm_1_4568_n_sv_sk), a
            call asm_1_4568_n_sv_copy
            jr asm_1_4568_n_sv_ok
; 10 Byte(1) 4: the caller's own Word(6) written into slot Word(2) at Word(4), Word(8) bytes
asm_1_4568_n_sv_m4:
            ld hl, (asm_1_4568_n_sv_blk + 2)
            call asm_1_4568_n_sv_slot            ; the target slot (one in use): DE its RAM setting
            jp z, asm_1_4568_n_sv_err
            ld (asm_1_4568_n_sv_ds), de          ; dest: that slot's bank, at Word(4)
            ld a, 2
            ld (asm_1_4568_n_sv_dk), a
            ld hl, (asm_1_4568_n_sv_blk + 4)
            ld (asm_1_4568_n_sv_da), hl
            ld hl, (var_hyp_svc_setting)      ; source: the caller's bank, at Word(6)
            ld (asm_1_4568_n_sv_ss), hl
            ld a, 2
            ld (asm_1_4568_n_sv_sk), a
            ld hl, (asm_1_4568_n_sv_blk + 6)
            ld (asm_1_4568_n_sv_sa), hl
            xor a
            ld (asm_1_4568_n_sv_stop), a
            call asm_1_4568_n_sv_copy
            jp asm_1_4568_n_sv_ok
; HL = a slot number: Z when it isn't one in use, else DE = its RAM setting
asm_1_4568_n_sv_slot:
            ld a, h
            or a
            jr nz, asm_1_4568_n_sv_sl0
            or l
            ret z
            ld de, (var_hyp_svns)
            ld a, (de)
            cp l
            jr c, asm_1_4568_n_sv_sl0
            add hl, hl
            push hl
            ld de, (var_hyp_svst)
            add hl, de
            ld a, (hl)
            pop hl
            or a
            ret z
            ld de, (var_hyp_svsg)
            add hl, de
            ld e, (hl)
            inc hl
            ld d, (hl)
            or 1                    ; (NZ)
            ret
asm_1_4568_n_sv_sl0:
            xor a
            ret
; 13 / 14: a 2K block of the store (13 from the slot, 14 to it) - Byte(1) 1: from Word(4) bytes into
; the block (any part of its 16K page, not past the page's end: Pluto's KEYMAN reads a key a byte at a time)
asm_1_4568_n_sv_store:
            ld hl, (asm_1_4568_n_sv_blk + 2)
            ld a, h
            or a
            jp nz, asm_1_4568_n_sv_err
            ld a, l
            and 7
            add a, a
            add a, a
            add a, a
            ld (asm_1_4568_n_sv_sa + 1), a       ; the block's place in its page
            xor a
            ld (asm_1_4568_n_sv_sa), a
            srl l
            srl l
            srl l
            ld a, (asm_1_4568_n_sv_blk + 1)      ; Byte(1) 1: Word(4) bytes on from the block's start (its page's end the limit)
            or a
            jr z, asm_1_4568_n_sv_sto0
            ld a, (asm_1_4568_n_sv_blk + 4)
            ld (asm_1_4568_n_sv_sa), a
            ld a, (asm_1_4568_n_sv_blk + 5)
            ld b, a
            ld a, (asm_1_4568_n_sv_sa + 1)
            add a, b
            and #3F
            ld (asm_1_4568_n_sv_sa + 1), a
asm_1_4568_n_sv_sto0:
            ld h, #FF               ; its page: the slot's byte at #FF00 + block / 8
            ld de, (var_hyp_svc_setting)
            call asm_1_4568_n_sv_sw
            push bc
            pop ix
            ld iy, (var_hyp_svp)
            ld de, asm_1_4568_n_sv_tmp
            ld a, 1
            call asm_1_4568_n_sv_dx
            ld a, (asm_1_4568_n_sv_tmp)
            or a
            jp z, asm_1_4568_n_sv_err
            ld l, a
            ld h, 0
            call asm_1_4568_n_sv_pgset
            ld (asm_1_4568_n_sv_ss), bc
            ld a, 1
            ld (asm_1_4568_n_sv_sk), a
            ld a, (asm_1_4568_n_sv_blk)
            cp 14
            jr z, asm_1_4568_n_sv_st1
            ld hl, (asm_1_4568_n_sv_sa)          ; 13: the slot to the page
            ld (asm_1_4568_n_sv_da), hl
            ld hl, (asm_1_4568_n_sv_ss)
            ld (asm_1_4568_n_sv_ds), hl
            ld a, 1
            ld (asm_1_4568_n_sv_dk), a
            ld hl, (asm_1_4568_n_sv_blk + 6)
            ld (asm_1_4568_n_sv_sa), hl
            ld hl, (var_hyp_svc_setting)
            ld (asm_1_4568_n_sv_ss), hl
            ld a, 2
            ld (asm_1_4568_n_sv_sk), a
asm_1_4568_n_sv_st1:
            call asm_1_4568_n_sv_copy
            jp asm_1_4568_n_sv_ok
; 11: the pointer, while the slot is in front
asm_1_4568_n_sv_ptr:
            ld hl, (var_hyp_svfr)
            ld a, (hl)
            ld hl, var_hyp_svc_t
            cp (hl)
            jp nz, asm_1_4568_n_sv_ok
            ld a, (var_hyp_pon)
            or a
            call nz, asm_1_4568_n_pt_xor
            xor a
            ld (var_hyp_pon), a
            ld a, (asm_1_4568_n_sv_blk + 1)
            or a
            jp z, asm_1_4568_n_sv_ok
            ld a, (asm_1_4568_n_sv_blk + 2)
            ld hl, var_hyp_scc
            cp (hl)
            jp nc, asm_1_4568_n_sv_ok            ; (off the screen: none)
            ld (var_hyp_pox), a
            ld a, (asm_1_4568_n_sv_blk + 3)
            ld (var_hyp_poy), a
            call asm_1_4568_n_pt_xor
            ld a, 1
            ld (var_hyp_pon), a
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_pt_xor:                             ; the checkerboard XORed at pox, poy (the screen is main RAM)
            ld a, (var_hyp_poy)
            ld e, a
            ld d, 0
            ld hl, 0
            ld a, (var_hyp_scc)
            ld b, 8
asm_1_4568_n_pt_mul:
            add hl, hl
            rlca
            jr nc, asm_1_4568_n_pt_mn
            add hl, de
asm_1_4568_n_pt_mn:
            djnz asm_1_4568_n_pt_mul
            ld a, (var_hyp_pox)
            ld e, a
            add hl, de
            ld de, (var_hyp_sco)
            add hl, de
            ld a, h
            and #07
            or #C0
            ld h, a
            ld b, 4
asm_1_4568_n_pt_ln:
            ld a, (hl)
            xor #AA
            ld (hl), a
            ld a, h
            add a, 8
            ld h, a
            ld a, (hl)
            xor #55
            ld (hl), a
            ld a, h
            add a, 8
            ld h, a
            djnz asm_1_4568_n_pt_ln
            ret
; 15: a table
asm_1_4568_n_sv_tab:
            ld hl, (asm_1_4568_n_sv_blk + 2)
            ld (asm_1_4568_n_sv_da), hl
            ld a, (asm_1_4568_n_sv_blk + 1)
            or a
            jr z, asm_1_4568_n_sv_t0
            dec a
            jp z, asm_1_4568_n_sv_t1
            dec a
            jp z, asm_1_4568_n_sv_t2
            dec a
            jp z, asm_1_4568_n_sv_t3
            dec a
            jp z, asm_1_4568_n_sv_t4
            jp asm_1_4568_n_sv_err
; 4: the claims - CL_N records of 10 bytes: the slot holding it (0: a free record), the unit,
; the name (8 characters, spaces after it)
asm_1_4568_n_sv_t4:
            ld hl, asm_1_4568_n_sv_cl
            ld de, (asm_1_4568_n_sv_da)
            ld bc, asm_1_4568_n_CL_N * 10
            call asm_1_4568_n_sv_out
            jp asm_1_4568_n_sv_ok
; 0: the slots - a word how many, then from 16 a record each: state, in front, MODE, the name's
; length, the name
asm_1_4568_n_sv_t0:
            call asm_1_4568_n_sv_clr
            ld hl, (var_hyp_svns)
            ld a, (hl)
            ld (asm_1_4568_n_sv_rec), a
            ld (asm_1_4568_n_sv_tn), a
            call asm_1_4568_n_sv_out16
            ld a, 1
            ld (asm_1_4568_n_sv_tj), a
asm_1_4568_n_sv_t0lp:
            ld a, (asm_1_4568_n_sv_tn)
            ld b, a
            ld a, (asm_1_4568_n_sv_tj)
            cp b
            jr z, asm_1_4568_n_sv_t0a
            jp nc, asm_1_4568_n_sv_ok
asm_1_4568_n_sv_t0a:
            ld hl, (asm_1_4568_n_sv_da)
            ld de, 16
            add hl, de
            ld (asm_1_4568_n_sv_da), hl
            call asm_1_4568_n_sv_clr
            ld a, (asm_1_4568_n_sv_tj)
            ld l, a
            ld h, 0
            add hl, hl
            ld de, (var_hyp_svst)
            add hl, de
            ld a, (hl)
            ld (asm_1_4568_n_sv_rec), a          ; its state
            ld hl, (var_hyp_svfr)
            ld a, (asm_1_4568_n_sv_tj)
            cp (hl)
            jr nz, asm_1_4568_n_sv_t0b
            ld a, 1
            ld (asm_1_4568_n_sv_rec + 1), a      ; in front
asm_1_4568_n_sv_t0b:
            ld a, (asm_1_4568_n_sv_rec)
            or a
            jr z, asm_1_4568_n_sv_t0d
            ld a, (asm_1_4568_n_sv_tj)           ; its RAM setting
            ld l, a
            ld h, 0
            add hl, hl
            ld de, (var_hyp_svsg)
            add hl, de
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (asm_1_4568_n_sv_tsg), de
            ld hl, 63113          ; MODE
            ld a, 1
            call asm_1_4568_n_sv_from
            ld a, (asm_1_4568_n_sv_tmp)
            ld (asm_1_4568_n_sv_rec + 2), a
            ld a, (asm_1_4568_n_sv_rec)
            cp 2
            jr nz, asm_1_4568_n_sv_t0d
            ld de, (asm_1_4568_n_sv_tsg)
            ld hl, #F6D8            ; the program's name: its length, then 12
            ld a, 13
            call asm_1_4568_n_sv_from
            ld a, (asm_1_4568_n_sv_tmp)
            cp 13
            jr c, asm_1_4568_n_sv_t0c
            ld a, 12
asm_1_4568_n_sv_t0c:
            ld (asm_1_4568_n_sv_rec + 3), a
            ld hl, asm_1_4568_n_sv_tmp + 1
            ld de, asm_1_4568_n_sv_rec + 4
            ld bc, 12
            ldir
asm_1_4568_n_sv_t0d:
            ld hl, asm_1_4568_n_sv_tj
            push hl
            call asm_1_4568_n_sv_out16
            pop hl
            inc (hl)
            jp asm_1_4568_n_sv_t0lp
; 1: the memory - words: the tables' end, the top, the pages, total K, free pages; from 16 a byte a page
asm_1_4568_n_sv_t1:
            call asm_1_4568_n_sv_clr
            ld hl, (mem_tend)
            ld (asm_1_4568_n_sv_rec), hl
            call mem_top
            ld (asm_1_4568_n_sv_rec + 2), hl
            ld hl, (mem_count)
            ld (asm_1_4568_n_sv_rec + 4), hl
            call mem_ramsize
            ld (asm_1_4568_n_sv_rec + 6), hl
            call mem_freepages
            ld (asm_1_4568_n_sv_rec + 8), hl
            ld hl, asm_1_4568_n_sv_rec
            ld de, (asm_1_4568_n_sv_da)
            ld bc, 18               ; (and pages 0, 1: 0)
            call asm_1_4568_n_sv_out
            ld hl, (mem_count)      ; pages 2 on: the RAT (2030 at most)
            dec hl
            ld a, h
            or l
            jp z, asm_1_4568_n_sv_ok
            ld de, 2031
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_4568_n_sv_t1a
            ld hl, 2030
asm_1_4568_n_sv_t1a:
            ld (asm_1_4568_n_sv_n), hl
            ld hl, (mem_ttype)
            inc hl
            ld (asm_1_4568_n_sv_sa), hl
            ld hl, (asm_1_4568_n_sv_blk + 2)
            ld de, 18
            add hl, de
            ld (asm_1_4568_n_sv_da), hl
            xor a
            ld (asm_1_4568_n_sv_sk), a
            ld (asm_1_4568_n_sv_stop), a
            call asm_1_4568_n_sv_copy
            jp asm_1_4568_n_sv_ok
; 2: the upper ROMs 0-31 - 64 bytes each: the first 16, then 48 of the name table (0s if none)
asm_1_4568_n_sv_t2:
            xor a
            ld (asm_1_4568_n_sv_tj), a
asm_1_4568_n_sv_t2lp:
            call asm_1_4568_n_sv_clr
            ld a, (asm_1_4568_n_sv_tj)
            ld c, a
            call #B90F              ; KL ROM SELECT (#C000 only: this code at #6000 stays)
            di
            push bc
            ld hl, #C000
            ld de, asm_1_4568_n_sv_rec
            ld bc, 16
            ldir
            ld hl, (asm_1_4568_n_sv_rec + 4)
            ld a, h
            and #C0
            cp #C0
            jr nz, asm_1_4568_n_sv_t2a
            ld de, #FF90
            or a
            sbc hl, de
            add hl, de
            jr nc, asm_1_4568_n_sv_t2a
            ld de, asm_1_4568_n_sv_rec + 16
            ld bc, 48
            ldir
asm_1_4568_n_sv_t2a:
            pop bc
            call #B918              ; KL ROM DESELECT
            di
            ld hl, asm_1_4568_n_sv_rec
            ld de, (asm_1_4568_n_sv_da)
            ld bc, 64
            call asm_1_4568_n_sv_out
            ld hl, (asm_1_4568_n_sv_da)
            ld de, 64
            add hl, de
            ld (asm_1_4568_n_sv_da), hl
            ld hl, asm_1_4568_n_sv_tj
            inc (hl)
            ld a, (hl)
            cp 32
            jr c, asm_1_4568_n_sv_t2lp
            jp asm_1_4568_n_sv_ok
; 3: the RAM discs - the driver's table (its page, #6A00: 128 bytes), 0s if none
asm_1_4568_n_sv_t3:
            call asm_1_4568_n_sv_clr
            ld hl, (var_hyp_svdp)
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld a, d
            or e
            jr z, asm_1_4568_n_sv_t3a
            ex de, hl
            call asm_1_4568_n_sv_pgset
            ld (asm_1_4568_n_sv_ss), bc
            ld hl, #6A00
            ld (asm_1_4568_n_sv_sa), hl
            ld hl, 128
            ld (asm_1_4568_n_sv_n), hl
            ld a, 1
            ld (asm_1_4568_n_sv_sk), a
            xor a
            ld (asm_1_4568_n_sv_stop), a
            call asm_1_4568_n_sv_copy
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_sv_t3a:
            ld hl, asm_1_4568_n_sv_rec
            ld de, (asm_1_4568_n_sv_da)
            ld bc, 128
            call asm_1_4568_n_sv_out
            jp asm_1_4568_n_sv_ok
; sv_from - A bytes from slot (sv_tsg's) HL into sv_tmp
asm_1_4568_n_sv_from:
            ld de, (asm_1_4568_n_sv_tsg)
            push af
            call asm_1_4568_n_sv_sw
            push bc
            pop ix
            ld iy, (var_hyp_svp)
            ld de, asm_1_4568_n_sv_tmp
            pop af
            jp asm_1_4568_n_sv_dx
; sv_clr - sv_rec (128 bytes) 0
asm_1_4568_n_sv_clr:
            ld hl, asm_1_4568_n_sv_rec
            ld de, asm_1_4568_n_sv_rec + 1
            ld bc, 127
            ld (hl), 0
            ldir
            ret
; sv_out16 - sv_rec's first 16 to the slot at sv_da; sv_out - BC bytes from HL (here) to the slot's DE
asm_1_4568_n_sv_out16:
            ld hl, asm_1_4568_n_sv_rec
            ld de, (asm_1_4568_n_sv_da)
            ld bc, 16
asm_1_4568_n_sv_out:
            ld (asm_1_4568_n_sv_sa), hl
            ld (asm_1_4568_n_sv_da), de
            ld (asm_1_4568_n_sv_n), bc
            ld a, 1
            ld (asm_1_4568_n_sv_sk), a
            ld hl, (var_hyp_svp)
            ld (asm_1_4568_n_sv_ss), hl
            xor a
            ld (asm_1_4568_n_sv_stop), a
            ld hl, (asm_1_4568_n_sv_da)
            push hl
            call asm_1_4568_n_sv_copy
            pop hl
            ld (asm_1_4568_n_sv_da), hl          ; (where it went: kept)
            ret
; sv_copy - sv_n bytes from the source (sv_sk: 0 main RAM outside the window, 1 a page - RAM setting
; sv_ss, 2 a bank - C2 setting sv_ss, 3 ROM sv_ss, 4 main RAM anywhere) at sv_sa to the
; destination (sv_dk: 1 a page, 2 a bank; sv_ds) at sv_da, 128 at most a go, none across a 16K
; page's end; sv_stop: at the source's page end, stop
asm_1_4568_n_sv_copy:
            ld hl, (asm_1_4568_n_sv_n)
            ld a, h
            or l
            ret z
            ld bc, 128
            or a
            sbc hl, bc
            add hl, bc
            jr nc, asm_1_4568_n_sc_c1
            ld b, h
            ld c, l
asm_1_4568_n_sc_c1:
            ld (asm_1_4568_n_sv_c), bc
            ld a, (asm_1_4568_n_sv_sk)
            or a
            jr z, asm_1_4568_n_sc_dl
            ld hl, (asm_1_4568_n_sv_sa)
            call asm_1_4568_n_sc_room
asm_1_4568_n_sc_dl:
            ld hl, (asm_1_4568_n_sv_da)
            call asm_1_4568_n_sc_room
            ld a, (asm_1_4568_n_sv_sk)           ; the source: IX its RAM setting, HL where
            ld hl, (asm_1_4568_n_sv_sa)
            ld ix, 0
            or a
            jr z, asm_1_4568_n_sc_sok
            cp 1
            jr nz, asm_1_4568_n_sc_s2
            ld ix, (asm_1_4568_n_sv_ss)
            call asm_1_4568_n_sc_win
            jr asm_1_4568_n_sc_sok
asm_1_4568_n_sc_s2:
            cp 2
            jr nz, asm_1_4568_n_sc_s3
            ld de, (asm_1_4568_n_sv_ss)
            call asm_1_4568_n_sv_sw
            push bc
            pop ix
            jr asm_1_4568_n_sc_sok
asm_1_4568_n_sc_s3:
            cp 3
            jr nz, asm_1_4568_n_sc_s4
            ld a, (asm_1_4568_n_sv_ss)           ; a ROM: its bytes into buf first
            ld c, a
            call #B90F              ; KL ROM SELECT
            di
            push bc
            ld hl, (asm_1_4568_n_sv_sa)
            ld a, h
            or #C0
            ld h, a
            ld de, (var_hyp_svc_buf)
            ld bc, (asm_1_4568_n_sv_c)
            ldir
            pop bc
            call #B918              ; KL ROM DESELECT
            di
            ld hl, (var_hyp_svc_buf)
            jr asm_1_4568_n_sc_sok
asm_1_4568_n_sc_s4:
            ld a, h                 ; main RAM: its #4000-#7FFF is page 1
            and #C0
            cp #40
            jr nz, asm_1_4568_n_sc_sok
            push hl
            ld hl, 1
            call asm_1_4568_n_sv_pgset
            pop hl
            push bc
            pop ix
asm_1_4568_n_sc_sok:
            push hl
            ld a, (asm_1_4568_n_sv_dk)           ; the destination: IY, DE
            ld hl, (asm_1_4568_n_sv_da)
            cp 1
            jr nz, asm_1_4568_n_sc_d2
            ld iy, (asm_1_4568_n_sv_ds)
            call asm_1_4568_n_sc_win
            jr asm_1_4568_n_sc_dok
asm_1_4568_n_sc_d2:
            ld de, (asm_1_4568_n_sv_ds)
            call asm_1_4568_n_sv_sw
            push bc
            pop iy
asm_1_4568_n_sc_dok:
            ex de, hl
            pop hl
            ld a, (asm_1_4568_n_sv_c)
            call asm_1_4568_n_sv_dx
            ld bc, (asm_1_4568_n_sv_c)
            ld hl, (asm_1_4568_n_sv_sa)
            add hl, bc
            ld (asm_1_4568_n_sv_sa), hl
            ld hl, (asm_1_4568_n_sv_da)
            add hl, bc
            ld (asm_1_4568_n_sv_da), hl
            ld hl, (asm_1_4568_n_sv_n)
            or a
            sbc hl, bc
            ld (asm_1_4568_n_sv_n), hl
            ld a, (asm_1_4568_n_sv_stop)
            or a
            jp z, asm_1_4568_n_sv_copy
            ld a, (asm_1_4568_n_sv_sa + 1)
            and #3F
            ld b, a
            ld a, (asm_1_4568_n_sv_sa)
            or b
            jp nz, asm_1_4568_n_sv_copy
            ret
asm_1_4568_n_sc_room:                            ; sv_c no more than to HL's 16K page's end
            ld a, h
            and #3F
            ld h, a
            ex de, hl
            ld hl, 16384
            or a
            sbc hl, de
            ld de, (asm_1_4568_n_sv_c)
            or a
            sbc hl, de
            ret nc
            add hl, de
            ld (asm_1_4568_n_sv_c), hl
            ret
asm_1_4568_n_sc_win:                             ; HL: its place in the window
            ld a, h
            and #3F
            or #40
            ld h, a
            ret
; sv_sw - DE = a bank's C2 setting, HL = an address in it: BC = the setting with its page in the
; window, HL = the address there
asm_1_4568_n_sv_sw:
            ld a, h
            rlca
            rlca
            and 3
            add a, 4
            ld b, a
            ld a, e
            and #F8
            or b
            ld c, a
            ld b, d
            jr asm_1_4568_n_sc_win
; sv_pgset - HL = a page: BC = its RAM setting (the Memory class's port table; 0 main RAM)
asm_1_4568_n_sv_pgset:
            ld a, h
            or l
            ld bc, #7FC0
            ret z
            add hl, hl
            ld de, (mem_tport)
            add hl, de
            dec hl
            ld b, (hl)
            dec hl
            ld c, (hl)
            ret
; ---- 16-19: the claims - hardware a program drives itself (FDC, SOUND, MF2, NVRAM, M4 ...): a
; name (Byte(2-9): 8 characters, spaces after) and a unit (Byte(1): which of them - a LUN), held
; by one slot at a time; all a slot's freed when its program ends, is killed or reset (p 0). The
; answer: 16 claim - 0 yours (now, or already), else the slot holding it (255: CL_N in use);
; 17 release - 0 done, 1 not yours; 18 take - yours now, whoever had it: the slot that had it
; (0 nobody); 19 held - 0 yours, else the slot holding it (254 nobody)
asm_1_4568_n_CL_N:       equ 16
asm_1_4568_n_sv_claim:
            ld b, a                 ; B = the op
            call asm_1_4568_n_cl_find            ; Z: HL = its record
            ld a, (var_hyp_svc_t)
            ld c, a                 ; C = this slot
            jr nz, asm_1_4568_n_cl_none
            ld a, b
            cp 17
            jr z, asm_1_4568_n_cl_rel
            ld a, (hl)              ; who has it
            ld (asm_1_4568_n_sv_tn), a
            ld a, b
            cp 18
            jr nz, asm_1_4568_n_cl_who
            ld (hl), c              ; 18: taken
            ld a, (asm_1_4568_n_sv_tn)
            jr asm_1_4568_n_cl_ret
asm_1_4568_n_cl_who:
            ld a, (asm_1_4568_n_sv_tn)           ; 16, 19: 0 when it is this slot's
            cp c
            jp z, asm_1_4568_n_sv_ok
            jr asm_1_4568_n_cl_ret
asm_1_4568_n_cl_rel:
            ld a, (hl)
            cp c
            jr nz, asm_1_4568_n_cl_one
            ld (hl), 0
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_cl_none:
            ld a, b
            cp 17
            jr z, asm_1_4568_n_cl_one
            cp 19
            ld a, 254
            jr z, asm_1_4568_n_cl_ret
            ld hl, asm_1_4568_n_sv_cl            ; 16, 18: into a free record
            ld de, 10
            ld b, asm_1_4568_n_CL_N
asm_1_4568_n_cl_fr:
            ld a, (hl)
            or a
            jr z, asm_1_4568_n_cl_put
            add hl, de
            djnz asm_1_4568_n_cl_fr
            jp asm_1_4568_n_sv_err
asm_1_4568_n_cl_put:
            ld (hl), c
            inc hl
            ex de, hl
            ld hl, asm_1_4568_n_sv_blk + 1
            ld bc, 9
            ldir
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_cl_one:
            ld a, 1
asm_1_4568_n_cl_ret:
            ld sp, (asm_1_4568_n_sv_sp)
            ret
; cl_find - Z: HL = the record with sv_blk's unit and name, else NZ (B kept)
asm_1_4568_n_cl_find:
            ld hl, asm_1_4568_n_sv_cl
            ld c, asm_1_4568_n_CL_N
asm_1_4568_n_cl_f1:
            ld a, (hl)
            or a
            jr z, asm_1_4568_n_cl_f3             ; (a free record)
            push hl
            push bc
            inc hl
            ld de, asm_1_4568_n_sv_blk + 1
            ld b, 9
asm_1_4568_n_cl_f2:
            ld a, (de)
            cp (hl)
            jr nz, asm_1_4568_n_cl_f4
            inc hl
            inc de
            djnz asm_1_4568_n_cl_f2
asm_1_4568_n_cl_f4:
            pop bc
            pop hl
            ret z
asm_1_4568_n_cl_f3:
            ld de, 10
            add hl, de
            dec c
            jr nz, asm_1_4568_n_cl_f1
            or 1
            ret
; p 0: slot t's claims all freed
asm_1_4568_n_sv_cfree:
            ld a, (var_hyp_svc_t)
            ld c, a
            ld hl, asm_1_4568_n_sv_cl
            ld de, 10
            ld b, asm_1_4568_n_CL_N
asm_1_4568_n_cl_cf:
            ld a, (hl)
            cp c
            jr nz, asm_1_4568_n_cl_cf1
            ld (hl), 0
asm_1_4568_n_cl_cf1:
            add hl, de
            djnz asm_1_4568_n_cl_cf
            call asm_1_4568_n_pt_free            ; its ports closed, its calls forgotten (C = the slot)
            ld a, (asm_1_4568_n_nt_rom)          ; its sockets closed
            inc a
            jp z, asm_1_4568_n_sv_ok
            ld b, 0
asm_1_4568_n_cl_cs:
            ld hl, asm_1_4568_n_nt_own
            ld e, b
            ld d, 0
            add hl, de
            ld a, (hl)
            cp c
            jr nz, asm_1_4568_n_cl_cs1
            push bc
            ld a, b
            call asm_1_4568_n_nt_close
            pop bc
asm_1_4568_n_cl_cs1:
            inc b
            ld a, b
            cp 8
            jr c, asm_1_4568_n_cl_cs
            jp asm_1_4568_n_sv_ok
; ---- 20-27: the network - the M4's sockets (NET M4 turns it on: CyborgOS uses the M4, which is
; then claimed as M4 0 by CyborgOS itself - slot 255). A command to the M4: a packet (its size,
; the command - a word -, its data) out of #FE00 a byte at a time, a write to #FC00; its answer
; then in the M4's ROM, at the address its #FF02 holds (+3 the answer, +4 a word, +6 data); its
; sockets' table at #FF06's (16 bytes a socket: +0 the state - 0 ready, 1 connecting, 2 sending,
; 3 closed by the other end, 5 looking a name up -, +2 a word: bytes waiting, +4 an IP address;
; the lookup's in the first). A socket is the slot's that opened it (nt_own), closed when its
; program ends
;   20  Byte(1) 0: the M4's ROM number (255: no network); 1: on - Byte(2) the M4's ROM; 2: off;
;       3: the clock (300 a second: its low word) to the request's Word(6); 4: all 32 bits (since
;       the reset) to Word(6), Word(8) - network or not; 5: the host machine - 0 an Amstrad CPC,
;       1 a ZX Spectrum Next (a program built for the cyborgos platform runs on both); 6: the boot
;       drive's letter; 7: how many other slots are on drive letter Byte(2) (CD);
;       8: the network's details (IPCONFIG) - 64 bytes to Word(2): +0 0 off, 1 on (not connected),
;       2 connected; +1 the signal (255: none); +2 the IP, +6 the netmask, +10 the gateway, +14 DNS 1,
;       +18 DNS 2 (4 bytes each); +22 the MAC (6); +28 the board's own message (31 characters, 0 at
;       the end) - A that state; 9: the network set (NET SET: |NETSET's text at Word(2), Byte(4) its
;       length); 10: the sockets (NETSTAT) - 8 bytes each, 64 in all, to Word(2): the slot that has
;       it (0: free), its state, the bytes waiting (a word), its IP - A how many are in use;
;       11: the M4's clock (M4TIME) - Byte(2) the M4's ROM, the network on or not: its text to
;       Byte(6) (its length, then its characters)
;   21  a name looked up: Word(2) where it is, Byte(4) its length (63 at most) - 1: started
;       (22 with 255 then: the state, 0 found - its IP at +4)
;   22  socket Byte(1)'s 16 bytes to Word(2) (255: the lookup's): its state
;   23  a TCP socket: its number (255 none)
;   24  socket Byte(1) connected to IP Byte(2-5), port Word(6): 0 started (22: 1 still, 0 done)
;   25  Word(4) bytes (1-240) from Word(2) sent on socket Byte(1): 0 done
;   26  up to Word(4) bytes (2048 at most) of socket Byte(1)'s to Word(2): 0 done - how many
;       written back to the request's Word(6)
;   27  socket Byte(1) closed
asm_1_4568_n_NT_N:       equ 8                   ; sockets 0-7
asm_1_4568_n_sv_net:
            ld b, a
            cp 20
            jr z, asm_1_4568_n_nt_20
            ld a, (asm_1_4568_n_nt_rom)
            inc a
            jp z, asm_1_4568_n_sv_err            ; (no network)
            ld a, b
            cp 21
            jp z, asm_1_4568_n_nt_look
            cp 23
            jp z, asm_1_4568_n_nt_sock
            call asm_1_4568_n_nt_chk             ; (the rest: one of the slot's sockets)
            ld a, b
            cp 22
            jp z, asm_1_4568_n_nt_stat
            cp 24
            jp z, asm_1_4568_n_nt_conn
            cp 25
            jp z, asm_1_4568_n_nt_send
            cp 26
            jp z, asm_1_4568_n_nt_recv
            ld a, (asm_1_4568_n_sv_blk + 1)      ; 27
            call asm_1_4568_n_nt_close
            jp asm_1_4568_n_nt_ans
asm_1_4568_n_nt_20:
            ld a, (asm_1_4568_n_sv_blk + 1)
            or a
            jr nz, asm_1_4568_n_nt_20a
            ld a, (asm_1_4568_n_nt_rom)
            jp asm_1_4568_n_nt_ret
asm_1_4568_n_nt_20a:
            cp 11
            jp z, asm_1_4568_n_nt_m4t
            cp 10
            jp z, asm_1_4568_n_nt_list
            cp 9
            jp z, asm_1_4568_n_nt_set
            cp 8
            jp z, asm_1_4568_n_nt_info
            cp 7
            jp z, asm_1_4568_n_nt_shared
            cp 6
            jp z, asm_1_4568_n_nt_boot
            cp 5
            jp z, asm_1_4568_n_nt_host
            cp 4
            jp z, asm_1_4568_n_nt_uptime
            cp 3
            jp z, asm_1_4568_n_nt_time
            dec a
            jp nz, asm_1_4568_n_nt_off
            ld a, (asm_1_4568_n_sv_blk + 2)      ; on: the M4's ROM, where its answers and sockets are
            ld (asm_1_4568_n_nt_rom), a
            ld a, 1                 ; the network indicator: up
            ld (var_hyp_ntu), a
            ld hl, #FF02
            ld de, asm_1_4568_n_nt_rsp
            ld bc, 2
            call asm_1_4568_n_nt_rd
            ld hl, #FF06
            ld de, asm_1_4568_n_nt_skt
            ld bc, 2
            call asm_1_4568_n_nt_rd
            ld c, 255               ; M4 0: CyborgOS's
            call asm_1_4568_n_nt_m4c
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_nt_off:
            ld b, 0                 ; off: every socket closed, M4 0 given back
asm_1_4568_n_nt_of1:
            ld hl, asm_1_4568_n_nt_own
            ld e, b
            ld d, 0
            add hl, de
            ld a, (hl)
            or a
            jr z, asm_1_4568_n_nt_of2
            push bc
            ld a, b
            call asm_1_4568_n_nt_close
            pop bc
asm_1_4568_n_nt_of2:
            inc b
            ld a, b
            cp asm_1_4568_n_NT_N
            jr c, asm_1_4568_n_nt_of1
            ld c, 0
            call asm_1_4568_n_nt_m4c
            ld a, 255
            ld (asm_1_4568_n_nt_rom), a
            xor a                   ; the network indicator: off
            ld (var_hyp_ntu), a
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_nt_time:
            call #BD0D              ; 3: KL TIME PLEASE - its low word (300 a second) to Word(6)
            di
            ld (asm_1_4568_n_sv_tmp + 4), hl
            ld hl, (var_hyp_svc_p)
            ld de, 6
            add hl, de
            ex de, hl
            ld hl, asm_1_4568_n_sv_tmp + 4
            ld bc, 2
            call asm_1_4568_n_sv_out
            jp asm_1_4568_n_sv_ok
; 11: the M4's clock - C_TIME ("hh:mm:ss yyyy-mm-dd", the M4 keeps it from NTP itself) from the M4
; whose ROM is Byte(2), the network on or not (M4TIME): its length and text to the request's
; Byte(6) on (30 characters at most). nt_rom / nt_rsp are that M4's while it is asked
asm_1_4568_n_nt_m4t:
            ld hl, (asm_1_4568_n_nt_rsp)
            ld (asm_1_4568_n_nt_mrs), hl
            ld a, (asm_1_4568_n_nt_rom)
            ld (asm_1_4568_n_nt_mro), a
            ld a, (asm_1_4568_n_sv_blk + 2)
            ld (asm_1_4568_n_nt_rom), a
            ld hl, #FF02            ; (where its answers are)
            ld de, asm_1_4568_n_nt_rsp
            ld bc, 2
            call asm_1_4568_n_nt_rd
            ld a, 2
            ld hl, #4324            ; C_TIME
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            ld hl, (asm_1_4568_n_nt_rsp)
            inc hl
            inc hl
            inc hl
            ld de, asm_1_4568_n_nt_pk + 1
            ld bc, 30
            call asm_1_4568_n_nt_rd
            ld hl, asm_1_4568_n_nt_pk + 1        ; its length: to a 0 or a control character
            ld b, 0
asm_1_4568_n_nm_len:
            ld a, (hl)
            cp 32
            jr c, asm_1_4568_n_nm_end
            inc hl
            inc b
            ld a, b
            cp 30
            jr c, asm_1_4568_n_nm_len
asm_1_4568_n_nm_end:
            ld a, b
            ld (asm_1_4568_n_nt_pk), a
            ld hl, (asm_1_4568_n_nt_mrs)
            ld (asm_1_4568_n_nt_rsp), hl
            ld a, (asm_1_4568_n_nt_mro)
            ld (asm_1_4568_n_nt_rom), a
            ld hl, (var_hyp_svc_p)
            ld de, 6
            add hl, de
            ex de, hl
            ld hl, asm_1_4568_n_nt_pk
            ld c, b
            ld b, 0
            inc c
            call asm_1_4568_n_sv_out
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_nt_mrs:     dw 0
asm_1_4568_n_nt_mro:     db 0
asm_1_4568_n_nt_uptime:
            call #BD0D              ; 4: KL TIME PLEASE - all 32 bits (300 a second since the reset) to Word(6), Word(8)
            di
            ld (asm_1_4568_n_sv_tmp + 4), hl
            ld (asm_1_4568_n_sv_tmp + 6), de
            ld hl, (var_hyp_svc_p)
            ld de, 6
            add hl, de
            ex de, hl
            ld hl, asm_1_4568_n_sv_tmp + 4
            ld bc, 4
            call asm_1_4568_n_sv_out
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_nt_ans:
            ld a, (asm_1_4568_n_sv_tmp + 3)      ; the M4's answer
asm_1_4568_n_nt_ret:
            ld sp, (asm_1_4568_n_sv_sp)
            ret
asm_1_4568_n_nt_host:                            ; 5: the host machine (CybSys.Host): 0 an Amstrad CPC, 1 a ZX Spectrum Next
            xor a
            jp asm_1_4568_n_nt_ret
asm_1_4568_n_nt_boot:                            ; 6: the boot drive's letter (CybSys.BootDrive): CD on it gives the
            ld a, (var_hyp_svbd)          ; slot a free letter, as on A and B (the letter is every slot's:
            jp asm_1_4568_n_nt_ret               ; its path changed would move them all)
asm_1_4568_n_nt_shared:                          ; 7: the other slots (open) on drive letter Byte(2) - their dv(),
            ld a, (var_hyp_svc_t)             ; 0 being the boot drive's (CybSys.Shared: CD moves a letter only
            ld c, a                 ; nobody else is on - a letter's path is every slot's)
            ld b, 0                 ; B = the count
            ld hl, (var_hyp_svns)
            ld a, (hl)
            or a
            jr z, asm_1_4568_n_ns_end
            ld e, a                 ; E = the slot
asm_1_4568_n_ns_lp:
            ld a, e
            cp c
            jr z, asm_1_4568_n_ns_nx
            ld l, e
            ld h, 0
            add hl, hl
            push hl
            push de
            ld de, (var_hyp_svst)
            add hl, de
            ld a, (hl)
            pop de
            pop hl
            or a
            jr z, asm_1_4568_n_ns_nx
            push de
            ld de, (var_hyp_svdv)
            add hl, de
            pop de
            ld a, (hl)
            or a
            jr nz, asm_1_4568_n_ns_d
            ld a, (var_hyp_svbd)
asm_1_4568_n_ns_d:
            ld d, a
            ld a, (asm_1_4568_n_sv_blk + 2)
            cp d
            jr nz, asm_1_4568_n_ns_nx
            inc b
asm_1_4568_n_ns_nx:
            dec e
            jr nz, asm_1_4568_n_ns_lp
asm_1_4568_n_ns_end:
            ld a, b
            jp asm_1_4568_n_nt_ret
; 8: the network's details (IPCONFIG): the M4's NETSTAT (its message; 5 at its end: connected),
; then NETRSSI (the signal) and GETNETWORK (+112 the addresses, +190 the MAC) - as its |NETSTAT
asm_1_4568_n_nt_info:
            ld hl, asm_1_4568_n_nt_pk + 192      ; (the 64 bytes made at nt_pk + 192; the M4's answers read to nt_pk)
            ld b, 64
asm_1_4568_n_ni_clr:
            ld (hl), 0
            inc hl
            djnz asm_1_4568_n_ni_clr
            ld a, 255
            ld (asm_1_4568_n_nt_pk + 193), a     ; (the signal: none)
            ld a, (asm_1_4568_n_nt_rom)
            inc a
            jp z, asm_1_4568_n_ni_out            ; (off: 0)
            ld a, 2
            ld hl, #4323            ; C_NETSTAT
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            ld hl, (asm_1_4568_n_nt_rsp)
            ld de, asm_1_4568_n_nt_pk
            ld bc, 64
            call asm_1_4568_n_nt_rd
            ld hl, asm_1_4568_n_nt_pk + 3        ; its message, to its end or a control character
            ld de, asm_1_4568_n_nt_pk + 220
            ld b, 31
asm_1_4568_n_ni_txt:
            ld a, (hl)
            cp 32
            jr c, asm_1_4568_n_ni_t1
            ld (de), a
            inc hl
            inc de
            djnz asm_1_4568_n_ni_txt
asm_1_4568_n_ni_t1:
            ld a, 1
            ld (asm_1_4568_n_nt_pk + 192), a     ; on (not connected)
            ld a, (asm_1_4568_n_nt_pk)           ; the state: at [the answer's length]
            cp 64
            jp nc, asm_1_4568_n_ni_out
            ld e, a
            ld d, 0
            ld hl, asm_1_4568_n_nt_pk
            add hl, de
            ld a, (hl)
            cp 5
            jp nz, asm_1_4568_n_ni_out
            ld a, 2
            ld (asm_1_4568_n_nt_pk + 192), a     ; connected
            ld hl, #4337            ; C_NETRSSI
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            ld a, (asm_1_4568_n_sv_tmp + 3)
            ld (asm_1_4568_n_nt_pk + 193), a
            ld a, 2
            ld hl, #433B            ; C_GETNETWORK
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            ld hl, (asm_1_4568_n_nt_rsp)
            ld de, 115
            add hl, de
            ld de, asm_1_4568_n_nt_pk
            ld bc, 84               ; (its +115 to +198: the addresses, the MAC)
            call asm_1_4568_n_nt_rd
            ld hl, asm_1_4568_n_nt_pk
            ld de, asm_1_4568_n_nt_pk + 194
            ld bc, 20
            ldir
            ld hl, asm_1_4568_n_nt_pk + 78
            ld de, asm_1_4568_n_nt_pk + 214
            ld bc, 6
            ldir
asm_1_4568_n_ni_out:
            ld hl, asm_1_4568_n_nt_pk + 192
            ld de, (asm_1_4568_n_sv_blk + 2)
            ld bc, 64
            call asm_1_4568_n_sv_out
            ld a, (asm_1_4568_n_nt_pk + 192)
            jp asm_1_4568_n_nt_ret
; 9: the network set - the M4's SETNETWORK with the text (what |NETSET takes)
asm_1_4568_n_nt_set:
            ld a, (asm_1_4568_n_nt_rom)
            inc a
            jp z, asm_1_4568_n_sv_err
            ld a, (asm_1_4568_n_sv_blk + 4)
            cp 120
            jp nc, asm_1_4568_n_sv_err
            ld c, a
            ld b, 0
            ld hl, (asm_1_4568_n_sv_blk + 2)
            ld de, asm_1_4568_n_nt_pk + 3
            push bc
            call asm_1_4568_n_sv_in
            pop bc
            ld hl, asm_1_4568_n_nt_pk + 3
            add hl, bc
            ld (hl), 0
            ld a, c
            add a, 3
            ld hl, #4321            ; C_SETNETWORK
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            jp asm_1_4568_n_sv_ok
; 10: the sockets (NETSTAT): 8 bytes each - the slot, the state, the bytes waiting, the IP
asm_1_4568_n_nt_list:
            ld hl, asm_1_4568_n_nt_pk + 192
            ld b, 64
asm_1_4568_n_nl_clr:
            ld (hl), 0
            inc hl
            djnz asm_1_4568_n_nl_clr
            xor a
            ld (asm_1_4568_n_sv_tmp), a
            ld a, (asm_1_4568_n_nt_rom)
            inc a
            jp z, asm_1_4568_n_nl_out
            ld bc, 0                ; B the socket, C how many in use
asm_1_4568_n_nl_lp:
            push bc
            ld hl, asm_1_4568_n_nt_own
            ld e, b
            ld d, 0
            add hl, de
            ld a, (hl)
            or a
            jr z, asm_1_4568_n_nl_nx
            ld l, b
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, asm_1_4568_n_nt_pk + 192
            add hl, de
            ld (hl), a              ; the slot
            push hl
            ld a, b
            call asm_1_4568_n_nt_ent
            ld de, asm_1_4568_n_sv_tmp + 8       ; (its 16 bytes: the state, +2 the bytes waiting, +4 the IP)
            ld bc, 8
            call asm_1_4568_n_nt_rd
            pop de
            inc de
            ld hl, asm_1_4568_n_sv_tmp + 8
            ldi                     ; the state
            inc hl
            ldi                     ; the bytes waiting
            ldi
            ldi                     ; the IP
            ldi
            ldi
            ldi
            pop bc
            inc c
            push bc
asm_1_4568_n_nl_nx:
            pop bc
            inc b
            ld a, b
            cp asm_1_4568_n_NT_N
            jr c, asm_1_4568_n_nl_lp
            ld a, c
            ld (asm_1_4568_n_sv_tmp), a
asm_1_4568_n_nl_out:
            ld hl, asm_1_4568_n_nt_pk + 192
            ld de, (asm_1_4568_n_sv_blk + 2)
            ld bc, 64
            call asm_1_4568_n_sv_out
            ld a, (asm_1_4568_n_sv_tmp)
            jp asm_1_4568_n_nt_ret
; 21: a name looked up
asm_1_4568_n_nt_look:
            ld a, (asm_1_4568_n_sv_blk + 4)
            cp 64
            jp nc, asm_1_4568_n_sv_err
            ld c, a
            ld b, 0
            ld hl, (asm_1_4568_n_sv_blk + 2)
            ld de, asm_1_4568_n_nt_pk + 3
            push bc
            call asm_1_4568_n_sv_in
            pop bc
            ld hl, asm_1_4568_n_nt_pk + 3
            add hl, bc
            ld (hl), 0
            ld a, c
            add a, 3
            ld hl, #4336            ; C_NETHOSTIP
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            jp asm_1_4568_n_nt_ans
; 22: a socket's 16 bytes to the slot
asm_1_4568_n_nt_stat:
            ld a, (asm_1_4568_n_sv_blk + 1)
            call asm_1_4568_n_nt_ent
            ld de, asm_1_4568_n_sv_tmp
            ld bc, 16
            call asm_1_4568_n_nt_rd
            ld hl, asm_1_4568_n_sv_tmp
            ld de, (asm_1_4568_n_sv_blk + 2)
            ld bc, 16
            call asm_1_4568_n_sv_out
            ld a, (asm_1_4568_n_sv_tmp)
            jp asm_1_4568_n_nt_ret
; 23: a TCP socket
asm_1_4568_n_nt_sock:
            ld hl, #0600            ; (domain 0, type 0, protocol 6: TCP)
            ld (asm_1_4568_n_nt_pk + 4), hl
            xor a
            ld (asm_1_4568_n_nt_pk + 3), a
            ld a, 5
            ld hl, #4331            ; C_NETSOCKET
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            ld a, (asm_1_4568_n_sv_tmp + 3)
            cp asm_1_4568_n_NT_N
            jp nc, asm_1_4568_n_nt_sk1
            ld e, a
            ld d, 0
            ld hl, asm_1_4568_n_nt_own
            add hl, de
            ld a, (var_hyp_svc_t)
            ld (hl), a
            jp asm_1_4568_n_nt_ans
asm_1_4568_n_nt_sk1:
            cp 255
            jp z, asm_1_4568_n_nt_ret
            call asm_1_4568_n_nt_close           ; (one this can't keep: closed)
            ld a, 255
            jp asm_1_4568_n_nt_ret
; 24: connected to an IP address and port
asm_1_4568_n_nt_conn:
            ld hl, asm_1_4568_n_sv_blk + 1
            ld de, asm_1_4568_n_nt_pk + 3
            ld bc, 7
            ldir
            ld a, 9
            ld hl, #4332            ; C_NETCONNECT
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            jp asm_1_4568_n_nt_ans
; 25: bytes sent
asm_1_4568_n_nt_send:
            ld a, 4                 ; the network indicator: blink for the next ~2s (4 x 0.5s)
            ld (var_hyp_nta), a
            ld hl, (asm_1_4568_n_sv_blk + 4)
            ld a, h
            or a
            jp nz, asm_1_4568_n_sv_err
            ld a, l
            or a
            jp z, asm_1_4568_n_sv_err
            cp 241
            jp nc, asm_1_4568_n_sv_err
            ld (asm_1_4568_n_nt_pk + 4), hl
            ld a, (asm_1_4568_n_sv_blk + 1)
            ld (asm_1_4568_n_nt_pk + 3), a
            ld b, h
            ld c, l
            ld hl, (asm_1_4568_n_sv_blk + 2)
            ld de, asm_1_4568_n_nt_pk + 6
            call asm_1_4568_n_sv_in
            ld a, (asm_1_4568_n_sv_blk + 4)
            add a, 5
            ld hl, #4334            ; C_NETSEND
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            jp asm_1_4568_n_nt_ans
; 26: bytes received
asm_1_4568_n_nt_recv:
            ld a, 4                 ; the network indicator: blink for the next ~2s (4 x 0.5s)
            ld (var_hyp_nta), a
            ld hl, (asm_1_4568_n_sv_blk + 4)
            ld de, 2049
            or a
            sbc hl, de
            jp nc, asm_1_4568_n_sv_err
            ld hl, (asm_1_4568_n_sv_blk + 4)
            ld (asm_1_4568_n_nt_pk + 4), hl
            ld a, (asm_1_4568_n_sv_blk + 1)
            ld (asm_1_4568_n_nt_pk + 3), a
            ld a, 5
            ld hl, #4335            ; C_NETRECV
            call asm_1_4568_n_nt_hdr
            call asm_1_4568_n_nt_go
            ld hl, 0
            ld a, (asm_1_4568_n_sv_tmp + 3)
            or a
            jr nz, asm_1_4568_n_nt_rc1
            ld hl, (asm_1_4568_n_sv_tmp + 4)     ; how many (no more than asked for)
            ld de, (asm_1_4568_n_sv_blk + 4)
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_4568_n_nt_rc0
            ex de, hl
asm_1_4568_n_nt_rc0:
            ld (asm_1_4568_n_sv_n), hl
            push hl
            ld hl, (asm_1_4568_n_nt_rsp)         ; from the M4's ROM to the slot
            ld de, 6
            add hl, de
            ld (asm_1_4568_n_sv_sa), hl
            ld a, (asm_1_4568_n_nt_rom)
            ld (asm_1_4568_n_sv_ss), a
            ld a, 3
            ld (asm_1_4568_n_sv_sk), a
            ld hl, (asm_1_4568_n_sv_blk + 2)
            ld (asm_1_4568_n_sv_da), hl
            xor a
            ld (asm_1_4568_n_sv_stop), a
            call asm_1_4568_n_sv_copy
            pop hl
asm_1_4568_n_nt_rc1:
            ld (asm_1_4568_n_sv_tmp + 4), hl     ; how many: to the request's Word(6)
            ld hl, (var_hyp_svc_p)
            ld de, 6
            add hl, de
            ex de, hl
            ld hl, asm_1_4568_n_sv_tmp + 4
            ld bc, 2
            call asm_1_4568_n_sv_out
            jp asm_1_4568_n_nt_ans
; nt_chk - Byte(1): a socket of this slot's (else the request fails)
asm_1_4568_n_nt_chk:
            ld a, (asm_1_4568_n_sv_blk + 1)
            cp asm_1_4568_n_NT_N
            jp nc, asm_1_4568_n_nt_chk1
            ld e, a
            ld d, 0
            ld hl, asm_1_4568_n_nt_own
            add hl, de
            ld a, (var_hyp_svc_t)
            cp (hl)
            ret z
            jp asm_1_4568_n_sv_err
asm_1_4568_n_nt_chk1:
            cp 255                  ; (255: the lookup's - 22 only)
            jp nz, asm_1_4568_n_sv_err
            ld a, b
            cp 22
            ret z
            jp asm_1_4568_n_sv_err
; nt_close - socket A closed (no longer anyone's)
asm_1_4568_n_nt_close:
            ld (asm_1_4568_n_nt_pk + 3), a
            cp asm_1_4568_n_NT_N
            jr nc, asm_1_4568_n_nt_cl1
            ld e, a
            ld d, 0
            ld hl, asm_1_4568_n_nt_own
            add hl, de
            ld (hl), 0
asm_1_4568_n_nt_cl1:
            ld a, 3
            ld hl, #4333            ; C_NETCLOSE
            call asm_1_4568_n_nt_hdr
; nt_go - the packet at nt_pk to the M4 (its size first); the answer's first 8 bytes to sv_tmp
asm_1_4568_n_nt_go:
            ld hl, asm_1_4568_n_nt_pk
            ld bc, #FE00
            ld d, (hl)
            inc d
asm_1_4568_n_nt_go1:
            inc b
            outi
            dec d
            jr nz, asm_1_4568_n_nt_go1
            ld bc, #FC00
            out (c), c
            ld hl, (asm_1_4568_n_nt_rsp)
            ld de, asm_1_4568_n_sv_tmp
            ld bc, 8
; nt_rd - BC bytes of the M4's ROM from HL to DE (here)
asm_1_4568_n_nt_rd:
            push hl
            push de
            push bc
            ld a, (asm_1_4568_n_nt_rom)
            ld c, a
            call #B90F              ; KL ROM SELECT
            di
            ld (asm_1_4568_n_nt_old), bc
            pop bc
            pop de
            pop hl
            ld a, h
            or #C0
            ld h, a
            ldir
            ld bc, (asm_1_4568_n_nt_old)
            call #B918              ; KL ROM DESELECT
            di
            ret
; nt_hdr - the packet's size A, its command HL
asm_1_4568_n_nt_hdr:
            ld (asm_1_4568_n_nt_pk), a
            ld (asm_1_4568_n_nt_pk + 1), hl
            ret
; nt_ent - socket A's 16 bytes in the M4's table: HL (255: the first - the lookup's)
asm_1_4568_n_nt_ent:
            cp 255
            jr nz, asm_1_4568_n_nt_e1
            xor a
asm_1_4568_n_nt_e1:
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, (asm_1_4568_n_nt_skt)
            add hl, de
            ret
; nt_m4c - the claim on M4 0 held by C (255 CyborgOS, 0 given back)
asm_1_4568_n_nt_m4c:
            push bc
            ld hl, asm_1_4568_n_sv_blk + 1
            ld (hl), 0
            inc hl
            ld (hl), 'M'
            inc hl
            ld (hl), '4'
            ld b, 6
asm_1_4568_n_nt_m4c1:
            inc hl
            ld (hl), ' '
            djnz asm_1_4568_n_nt_m4c1
            call asm_1_4568_n_cl_find
            pop bc
            jr nz, asm_1_4568_n_nt_m4c2
            ld (hl), c              ; (CyborgOS's now - or no one's)
            ret
asm_1_4568_n_nt_m4c2:
            ld a, c
            or a
            ret z
            ld hl, asm_1_4568_n_sv_cl            ; into a free record
            ld de, 10
            ld b, asm_1_4568_n_CL_N
asm_1_4568_n_nt_m4c3:
            ld a, (hl)
            or a
            jr z, asm_1_4568_n_nt_m4c4
            add hl, de
            djnz asm_1_4568_n_nt_m4c3
            ret
asm_1_4568_n_nt_m4c4:
            ld (hl), c
            inc hl
            ex de, hl
            ld hl, asm_1_4568_n_sv_blk + 1
            ld bc, 9
            ldir
            ret
; sv_in - BC bytes from the slot's HL to DE (here, in the service page)
asm_1_4568_n_sv_in:
            ld (asm_1_4568_n_sv_sa), hl
            ld (asm_1_4568_n_sv_da), de
            ld (asm_1_4568_n_sv_n), bc
            ld a, 2
            ld (asm_1_4568_n_sv_sk), a
            ld hl, (var_hyp_svc_setting)
            ld (asm_1_4568_n_sv_ss), hl
            ld a, 1
            ld (asm_1_4568_n_sv_dk), a
            ld hl, (var_hyp_svp)
            ld (asm_1_4568_n_sv_ds), hl
            xor a
            ld (asm_1_4568_n_sv_stop), a
            call asm_1_4568_n_sv_copy
            ld a, 2                 ; (the copies to the slot again)
            ld (asm_1_4568_n_sv_dk), a
            ld hl, (var_hyp_svc_setting)
            ld (asm_1_4568_n_sv_ds), hl
            ret
; ---- 28-33: the ports - a program serving others: a service (RAT: decisions, a model: its
; weights ...) opens a port by name (8 characters); any slot calls it: its message (128 bytes at
; most) into the port's box, the server receives it, replies, the caller gets the answer. One call
; at a time a port (another caller meanwhile: 1, busy - try again). The request: Byte(2-9) the
; port's name, Word(10) where the message is / goes, Byte(12) its length; back in Byte(12) the
; length, Byte(13) the caller (32). The answers: 0 done, 1 not yet (busy, no answer, no message:
; Main lets the slot sleep a tick), 2 no such port / not this slot's, 255 no room (8 ports)
;   28  open the port (0: it is this slot's - now, or already; 2 another slot's)
;   29  close it (2: not this slot's)
;   30  call it: the message from Word(10), Byte(12) long, into its box
;   31  the answer to this slot's call: to Word(10), its length to Byte(12) (1: none yet)
;   32  the server's next message: to Word(10), its length to Byte(12), the caller to Byte(13)
;   33  the server's reply to it: from Word(10), Byte(12) long (a caller that has gone: dropped)
; A port: +0 its slot (0: free), +1 its name, +9 its state (0 free, 1 a message in, 2 received,
; 3 answered), +10 the caller, +11 the length, +12 the box (128 bytes). Freed with its slot
asm_1_4568_n_PT_N:       equ 8
asm_1_4568_n_PT_SZ:      equ 140
asm_1_4568_n_sv_port:
            ld (asm_1_4568_n_pt_op), a
            call asm_1_4568_n_pt_find            ; Z: HL = the port named Byte(2-9); pt_fr: a free record (0: none)
            ld (asm_1_4568_n_pt_rec), hl
            ld a, 0
            jr z, asm_1_4568_n_sp_f
            inc a
asm_1_4568_n_sp_f:
            ld (asm_1_4568_n_pt_has), a          ; 0 there, 1 not
            ld a, (var_hyp_svc_t)
            ld (asm_1_4568_n_pt_me), a
            ld a, (asm_1_4568_n_sv_blk + 12)     ; the length: 128 at most
            cp 129
            jr c, asm_1_4568_n_sp_l
            ld a, 128
            ld (asm_1_4568_n_sv_blk + 12), a
asm_1_4568_n_sp_l:
            ld a, (asm_1_4568_n_pt_op)
            cp 28
            jr z, asm_1_4568_n_pt_open
            ld a, (asm_1_4568_n_pt_has)
            or a
            jr nz, asm_1_4568_n_pt_two           ; (no such port)
            ld hl, (asm_1_4568_n_pt_rec)
            ld a, (asm_1_4568_n_pt_op)
            cp 29
            jr z, asm_1_4568_n_pt_close
            cp 30
            jp z, asm_1_4568_n_pt_call
            cp 31
            jp z, asm_1_4568_n_pt_poll
            cp 32
            jp z, asm_1_4568_n_pt_recv
            jp asm_1_4568_n_pt_reply
asm_1_4568_n_pt_two:
            ld a, 2
            jr asm_1_4568_n_pt_ret
asm_1_4568_n_pt_one:
            ld a, 1
asm_1_4568_n_pt_ret:
            ld sp, (asm_1_4568_n_sv_sp)
            ret
; 28: open
asm_1_4568_n_pt_open:
            ld a, (asm_1_4568_n_pt_has)
            or a
            jr nz, asm_1_4568_n_po_new
            ld hl, (asm_1_4568_n_pt_rec)
            ld a, (asm_1_4568_n_pt_me)
            cp (hl)
            jp z, asm_1_4568_n_sv_ok
            jr asm_1_4568_n_pt_two
asm_1_4568_n_po_new:
            ld hl, (asm_1_4568_n_pt_fr)
            ld a, h
            or l
            jp z, asm_1_4568_n_sv_err
            ld a, (asm_1_4568_n_pt_me)
            ld (hl), a
            inc hl
            ex de, hl
            ld hl, asm_1_4568_n_sv_blk + 2
            ld bc, 8
            ldir
            ex de, hl
            xor a
            ld (hl), a              ; free
            inc hl
            ld (hl), a              ; no caller
            jp asm_1_4568_n_sv_ok
; 29: close
asm_1_4568_n_pt_close:
            ld a, (asm_1_4568_n_pt_me)
            cp (hl)
            jr nz, asm_1_4568_n_pt_two
            ld (hl), 0
            jp asm_1_4568_n_sv_ok
; 30: call - the message into the box (the box busy: 1)
asm_1_4568_n_pt_call:
            ld de, 9
            add hl, de
            ld a, (hl)
            or a
            jr nz, asm_1_4568_n_pt_one
            inc hl
            ld a, (asm_1_4568_n_pt_me)
            ld (hl), a              ; the caller
            inc hl
            ld a, (asm_1_4568_n_sv_blk + 12)
            ld (hl), a              ; the length
            inc hl
            ex de, hl               ; DE = the box
            ld c, a
            ld b, 0
            ld a, b
            or c
            jr z, asm_1_4568_n_pc_0
            ld hl, (asm_1_4568_n_sv_blk + 10)
            call asm_1_4568_n_sv_in
asm_1_4568_n_pc_0:
            ld hl, (asm_1_4568_n_pt_rec)
            ld de, 9
            add hl, de
            ld (hl), 1              ; a message in
            jp asm_1_4568_n_sv_ok
; 31: the answer to this slot's call
asm_1_4568_n_pt_poll:
            ld de, 9
            add hl, de
            ld a, (hl)
            or a
            jp z, asm_1_4568_n_pt_two            ; (no call)
            inc hl
            ld a, (asm_1_4568_n_pt_me)
            cp (hl)
            jp nz, asm_1_4568_n_pt_two           ; (not this slot's call)
            dec hl
            ld a, (hl)
            cp 3
            jp nz, asm_1_4568_n_pt_one           ; not answered yet
            ld (hl), 0              ; the box free again
            inc hl
            ld (hl), 0
            call asm_1_4568_n_pt_give            ; the answer to the slot, its length to Byte(12)
            jp asm_1_4568_n_sv_ok
; 32: the server's next message
asm_1_4568_n_pt_recv:
            ld a, (asm_1_4568_n_pt_me)
            cp (hl)
            jp nz, asm_1_4568_n_pt_two
            ld de, 9
            add hl, de
            ld a, (hl)
            cp 1
            jp nz, asm_1_4568_n_pt_one           ; nothing in
            ld (hl), 2              ; received
            call asm_1_4568_n_pt_give
            jp asm_1_4568_n_sv_ok
; 33: the server's reply
asm_1_4568_n_pt_reply:
            ld a, (asm_1_4568_n_pt_me)
            cp (hl)
            jp nz, asm_1_4568_n_pt_two
            ld de, 9
            add hl, de
            ld a, (hl)
            cp 2
            jp nz, asm_1_4568_n_pt_two           ; (nothing received to reply to)
            inc hl
            ld a, (hl)
            dec hl
            or a
            jr nz, asm_1_4568_n_pr_1
            ld (hl), a              ; its caller gone: dropped, the box free
            jp asm_1_4568_n_sv_ok
asm_1_4568_n_pr_1:
            ld (hl), 3              ; answered
            inc hl
            inc hl
            ld a, (asm_1_4568_n_sv_blk + 12)
            ld (hl), a
            inc hl
            ex de, hl
            ld c, a
            ld b, 0
            ld a, b
            or c
            jp z, asm_1_4568_n_sv_ok
            ld hl, (asm_1_4568_n_sv_blk + 10)
            call asm_1_4568_n_sv_in
            jp asm_1_4568_n_sv_ok
; 34: port Byte(1) (0-7) - its name to the request's Byte(2-9), its slot to Byte(10) (0: free);
; 255 no such port number (PROBE lists the services with it)
asm_1_4568_n_pt_list:
            ld a, (asm_1_4568_n_sv_blk + 1)
            cp asm_1_4568_n_PT_N
            jp nc, asm_1_4568_n_sv_err
            ld hl, asm_1_4568_n_pt_tab
            ld de, asm_1_4568_n_PT_SZ
            or a
            jr z, asm_1_4568_n_pl_2
            ld b, a
asm_1_4568_n_pl_1:
            add hl, de
            djnz asm_1_4568_n_pl_1
asm_1_4568_n_pl_2:
            ld a, (hl)              ; the slot (0 free)
            inc hl
            ld de, asm_1_4568_n_sv_rec
            ld bc, 8
            ldir
            ld (de), a
            ld hl, (var_hyp_svc_p)
            ld de, 2
            add hl, de
            ex de, hl
            ld hl, asm_1_4568_n_sv_rec
            ld bc, 9
            call asm_1_4568_n_sv_out
            jp asm_1_4568_n_sv_ok
; pt_give - the port's box (pt_rec) to the slot's Word(10); its length and the caller to the
; request's Byte(12), Byte(13)
asm_1_4568_n_pt_give:
            ld hl, (asm_1_4568_n_pt_rec)
            ld de, 10
            add hl, de
            ld a, (hl)
            ld (asm_1_4568_n_pt_tmp + 1), a      ; the caller
            inc hl
            ld a, (hl)
            ld (asm_1_4568_n_pt_tmp), a          ; the length
            inc hl
            ld c, a
            ld b, 0
            or a
            jr z, asm_1_4568_n_pg_0
            ld de, (asm_1_4568_n_sv_blk + 10)
            call asm_1_4568_n_sv_out
asm_1_4568_n_pg_0:
            ld hl, (var_hyp_svc_p)
            ld de, 12
            add hl, de
            ex de, hl
            ld hl, asm_1_4568_n_pt_tmp
            ld bc, 2
            jp asm_1_4568_n_sv_out
; pt_find - Z: HL = the port named sv_blk's Byte(2-9), else NZ; pt_fr: a free record (0 none)
asm_1_4568_n_pt_find:
            ld hl, 0
            ld (asm_1_4568_n_pt_fr), hl
            ld hl, asm_1_4568_n_pt_tab
            ld b, asm_1_4568_n_PT_N
asm_1_4568_n_pf_1:
            ld a, (hl)
            or a
            jr nz, asm_1_4568_n_pf_2
            ld a, (asm_1_4568_n_pt_fr + 1)
            or a
            jr nz, asm_1_4568_n_pf_n
            ld (asm_1_4568_n_pt_fr), hl
            jr asm_1_4568_n_pf_n
asm_1_4568_n_pf_2:
            push hl
            push bc
            inc hl
            ld de, asm_1_4568_n_sv_blk + 2
            ld b, 8
asm_1_4568_n_pf_3:
            ld a, (de)
            cp (hl)
            jr nz, asm_1_4568_n_pf_4
            inc hl
            inc de
            djnz asm_1_4568_n_pf_3
asm_1_4568_n_pf_4:
            pop bc
            pop hl
            ret z
asm_1_4568_n_pf_n:
            ld de, asm_1_4568_n_PT_SZ
            add hl, de
            djnz asm_1_4568_n_pf_1
            or 1
            ret
; pt_free - slot C's ports closed; its calls forgotten (a message not received yet, an answer not
; taken: the box free; one being worked on: its reply dropped). Keeps C
asm_1_4568_n_pt_free:
            ld hl, asm_1_4568_n_pt_tab
            ld b, asm_1_4568_n_PT_N
asm_1_4568_n_pt_fr1:
            ld a, (hl)
            cp c
            jr nz, asm_1_4568_n_pt_fr2
            ld (hl), 0
asm_1_4568_n_pt_fr2:
            push hl
            ld de, 10
            add hl, de
            ld a, (hl)
            cp c
            jr nz, asm_1_4568_n_pt_fr4
            ld (hl), 0              ; no caller
            dec hl
            ld a, (hl)
            cp 2
            jr z, asm_1_4568_n_pt_fr4            ; (being worked on: its reply dropped then)
            ld (hl), 0
asm_1_4568_n_pt_fr4:
            pop hl
            ld de, asm_1_4568_n_PT_SZ
            add hl, de
            djnz asm_1_4568_n_pt_fr1
            ret
asm_1_4568_n_pt_op:      db 0
asm_1_4568_n_pt_has:     db 0
asm_1_4568_n_pt_me:      db 0
asm_1_4568_n_pt_rec:     dw 0
asm_1_4568_n_pt_fr:      dw 0
asm_1_4568_n_pt_tmp:     dw 0
asm_1_4568_n_nt_rom:     db 255
asm_1_4568_n_nt_old:     dw 0
asm_1_4568_n_nt_rsp:     dw 0
asm_1_4568_n_nt_skt:     dw 0
asm_1_4568_n_nt_own:     ds asm_1_4568_n_NT_N
asm_1_4568_n_sv_sp:      dw 0
asm_1_4568_n_sv_n:       dw 0
asm_1_4568_n_sv_c:       dw 0
asm_1_4568_n_sv_sk:      db 0
asm_1_4568_n_sv_ss:      dw 0
asm_1_4568_n_sv_sa:      dw 0
asm_1_4568_n_sv_dk:      db 0
asm_1_4568_n_sv_ds:      dw 0
asm_1_4568_n_sv_da:      dw 0
asm_1_4568_n_sv_stop:    db 0
asm_1_4568_n_sv_tj:      db 0
asm_1_4568_n_sv_tn:      db 0
asm_1_4568_n_sv_tsg:     dw 0
asm_1_4568_n_sv_blk:     ds 16
asm_1_4568_n_sv_tmp:     ds 16
asm_1_4568_n_sv_rec:     ds 128
asm_1_4568_n_sv_cl:      ds asm_1_4568_n_CL_N * 10            ; the claims (16-19; table 4)
asm_1_4568_n_nt_pk:      ds 256                  ; a packet to the M4 (21-27)
asm_1_4568_n_pt_tab:     ds asm_1_4568_n_PT_N * asm_1_4568_n_PT_SZ         ; the ports (28-33)
asm_1_4568_n_sv_end:
            ASSERT asm_1_4568_n_sv_end <= #8000, "the service page's code"
			ENDM
; ============================================================
; NTC program - generated by NTC BASIC (VB style BASIC to NTC)
; platform: cpcfw (Amstrad CPC - firmware text and keys), starts in normal mode
; ============================================================

			DEVICE AMSTRADCPC6128		; for SAVEAMSDOS at the end
			org #0040

NTC_TERM	equ 0		; Option Terminal: 0 none, 1 VT52, 2 ANSI (CP/M)
NTC_STRMAX	equ 72		; the longest string (library buffers, temps)
NTC_MEMBANKS	equ 64		; Option Memory: the most 64K banks the Memory class looks for
NTC_ROMENABLE	equ 1		; Option RomEnable (cpcfw, cpcmin): the start code starts the ROMs
NTC_ROMLIB	equ 0		; 1 = the library is the keyword ROM (Library: ROM; ntcRomAsm builds it)
NTC_WINHOLE	equ 1		; 1 = the program is built round an Option Reserve range over the window #4000-#7FFF
NTC_BUFSIZE	equ 128		; the library's buffer (ntc_buf: FileSystem, Memory.Copy): Option Buffer
NTC_CPMGFX	equ 0		; 1 = CP/M: Graphics draws on an Amstrad CPC's screen (2.2: #C000, Plus: block 1 from common memory)

ntc_start:
			jr ntc_start2
ntc_bk_sp:		dw 0			; #0042: main RAM's SP while a bank runs
ntc_bk_out:
			out (c), c		; #0044: BC = the other side's RAM setting
			jp ntc_bk_land		; #0046: main RAM switched in
ntc_bk_land:
			ld sp, (ntc_bk_sp)
			ret				; to where main RAM handed over
			ASSERT ntc_bk_out == #0044, "the bank switch must be at #0044"
ntc_start2:
			di
			ld (ntc_csp), sp
			ld a, (#BC77)		; Option RomEnable: start the ROMs again
			cp #DF			; AMSDOS has the cassette calls: they are running
			jp z, ntc_roms_on
			ei
			ld de, ntc_free		; the lowest address the ROMs may use (above the arrays)
			ld hl, #ABFF		; the highest (as usual for AMSDOS: it takes about #A700-#ABFF)
			call #BCCB		; KL ROM WALK: every background ROM
			inc hl			; the first byte the ROMs took
			ld (ntc_roms_at), hl
			ld de, #A600
			or a
			sbc hl, de
			jp nc, ntc_roms_fit	; AMSDOS alone (or no more): as usual
			ld hl, (ntc_roms_at)
			ld de, -16
			add hl, de		; the event block under the ROMs' RAM: the new top
			ld (ntc_fwblk), hl
			ld (ntc_fwtop), hl
			ld de, ntc_free
			or a
			sbc hl, de
			jp nc, ntc_roms_fit	; the program still ends below it
			ld hl, ntc_roms_msg
			call ntc_roms_puts
			ld a, (ntc_roms_at + 1)
			call ntc_roms_hex
			ld a, (ntc_roms_at)
			call ntc_roms_hex
			ld hl, ntc_roms_msg2
			call ntc_roms_puts
			call #BB06		; KM WAIT CHAR
			rst 0			; (the machine starts again)
ntc_roms_puts:
			ld a, (hl)
			or a
			ret z
			call #BB5A		; TXT OUTPUT
			inc hl
			jr ntc_roms_puts
ntc_roms_hex:
			push af
			rrca
			rrca
			rrca
			rrca
			call ntc_roms_dig
			pop af
ntc_roms_dig:
			and 15
			add a, #90
			daa
			adc a, #40
			daa
			jp #BB5A
ntc_roms_at:	dw 0
ntc_roms_msg:	db "The ROMs' RAM reaches down to #", 0
ntc_roms_msg2:	db ": no room for this program", 13, 10, "(fewer ROMs, or a smaller program)", 13, 10, "Press a key", 13, 10, 0
ntc_roms_fit:
			di
			ASSERT ntc_free <= #A600, "Option RomEnable: the program and its arrays must end below #A600 (the ROMs take their RAM from #ABFF down)"
ntc_roms_on:
			ld a, 1
			ld (ntc_nmode), a		; normal mode: waits let interrupts in
			; Option Class Interrupt: the classes' Tick subs, run at safe points (normal mode)
			ld hl, 6		; hot: every 6 interrupts
			ld (ntc_isl + 2), hl
			ld hl, 7			; the first after one period (+ the slot, so they take turns)
			ld (ntc_isl + 0), hl
			ld hl, p_hot_tick_c
			ld (ntc_isl + 6), hl
			ld a, 1
			ld (ntc_isln), a
			ld hl, ntc_isl_tick
			ld (ntc_irqv), hl		; the interrupt handler counts for them
			ld ix, ntc_go
			jp ntc_plat_irqon		; interrupt handler for normal mode
ntc_go:
			ld sp, main_thread
			ret

			IF ($ < 32768) && (ntc_rg1_e - ntc_rg1 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg1:
; ============================================================
; Main Thread
; ============================================================

main_thread:
			dw kw_bssinit, ntc_bss, ntc_bss_size		; the arrays: do they fit, clear them
			dw kw_model, 2
			dw asm_0_69_n
			dw p_hyp_vdu_c, lit_0
			dw kw_ltolptr8, 255, -16776
			dw fn_memory_banks, var_k
			dw kw_scpltvl, var_k, 4
			dw kw_goto_iffalse_n, if1_1
			dw p_hyp_vdu_c, lit_1
			dw kw_printstrvar, str0
			dw kw_printnl
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop
if1_1:
			dw kw_divvl, var_k, 2, var_ns
			dw kw_scpgtvl, var_ns, 20
			dw kw_goto_iffalse_n, if2_1
			dw kw_ltov, 20, var_ns
if2_1:
			dw p_hot_slots_c, var_ns
			dw fn_memory_allocpage, lit_85, var_i
			dw fn_memory_allocpage, lit_85, var_hp
			dw fn_memory_selectpage, var_hp, var_memory_selectpage_selectpage
			dw fn_hyp_usepage
			dw fn_hyp_fontinit
			dw fn_memory_allocpage, lit_85, var_i
			dw fn_memory_selectpage, var_i, var_memory_selectpage_selectpage
			dw fn_hyp_usesvc
			dw p_hyp_svcvars_c, vp_arr_st, vp_arr_sg, vp_var_ns, vp_var_front, vp_var_dp
			dw p_hyp_filecall_c, lit_99, lit_0, lit_0, lit_0, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_i
			dw p_hyp_svc_c, lit_0, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_i
			dw kw_ztov, var_i
			dw kw_vtov, var_ns, for3_l
			dw kw_forupv_n, var_i, for3_l, for3_e
for3_t:
			dw fn_memory_allocbank, var_memory_allocbank_allocbank
			dw kw_aset, arr_bk, var_i, var_memory_allocbank_allocbank
			dw kw_aget, arr_bk, var_i, tmp0
			dw p_memory_bankpage_c, tmp0, lit_0
			dw kw_vtov, var_memory_bankpage_bankpage, tmp0
			dw fn_memory_selectpage, tmp0, var_memory_selectpage_selectpage
			dw fn_hyp_setting, var_hyp_setting_setting
			dw kw_aset, arr_sg, var_i, var_hyp_setting_setting
			dw kw_aget, arr_sg, var_i, tmp1
			dw kw_andvl, tmp1, -8, tmp1
			dw kw_orvl, tmp1, 7, tmp1
			dw kw_aset, arr_wp, var_i, tmp1
			dw kw_ztov, var_k
for4_t:
			dw kw_4x, var_i, tmp0
			dw kw_add, tmp0, var_k, tmp0
			dw kw_aget, arr_bk, var_i, tmp1
			dw p_memory_bankpage_c, tmp1, var_k
			dw kw_aset, arr_bpg, tmp0, var_memory_bankpage_bankpage
			dw kw_next1l_n, var_k, 3, for4_t
for4_e:
			dw kw_next1v_n, var_i, for3_l, for3_t
for3_e:
			dw kw_vtov, arr_wp, var_kwp
			dw kw_strcpy, var_a, str2
			dw kw_lptrtov8, -16768, tmp0
			dw kw_cpeqvl, tmp0, 67
			dw kw_ftov, tmp0
			dw kw_lptrtov8, -16767, tmp1
			dw kw_cpeqvl, tmp1, 89
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_lptrtov8, -16766, tmp1
			dw kw_cpeqvl, tmp1, 66
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_lptrtov8, -16765, tmp1
			dw kw_cpeqvl, tmp1, 32
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if5_1
			dw kw_ltov, -16764, var_i
do6_t:
			dw kw_vptrtov8, var_i, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_ftov, tmp0
			dw kw_scpltvl, var_i, -16704
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do6_e
			dw kw_vptrtov8, var_i, tmp1
			dw kw_strchr, stmp1, tmp1
			dw kw_strcat, var_a, stmp1
			dw kw_inc, var_i
			dw do6_t_go
do6_e:
			dw kw_strucase, var_a, var_a
if5_1:
			dw kw_strinstr, lit_1, var_a, str3, var_i
			dw kw_scpgtvl, var_i, 0
			dw kw_goto_iffalse_n, if7_1
			dw kw_addl, var_i, 8, tmp1
			dw kw_strmid, stmp0, var_a, tmp1, lit_255
			dw kw_strval, stmp0, var_k
			dw kw_scpgtvl, var_k, 1
			dw kw_goto_iffalse_n, if8_1
			dw p_hyp_keyrep_c, var_k
			dw p_hot_speed_c, var_k
if8_1:
if7_1:
			dw kw_strinstr, lit_1, var_a, str4, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if9_1
			dw p_v9_probe_c
			dw kw_goto_ifzero_n, var_v9_probe_probe, if10_1
			dw p_v9_init_c, lit_1
if10_1:
if9_1:
			dw kw_ltov, 65, var_bd
			dw kw_strcmpne, var_a, str2
			dw kw_goto_iffalse_n, if11_1
			dw kw_strasc, var_a, var_bd
if11_1:
			dw kw_ztov, var_mz
			dw p_probediscs_c
			dw kw_vtov, var_probediscs_probediscs, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_ftov, tmp0
			dw fn_memory_banks, var_memory_banks_banks
			dw kw_vtov, var_memory_banks_banks, tmp1
			dw kw_scpgevl, tmp1, 8
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if12_1
			dw kw_ltov, -1, var_mz
if12_1:
			dw p_hyp_bootdrive_c, var_bd, vp_arr_dv
			dw p_hyp_drive_c, var_bd
			dw kw_vtov, var_hyp_drive_drive, var_i
			dw kw_strcpy, var_dn, str5
			dw kw_strlen, var_dn, tmp4
			dw p_hyp_filecall_c, lit_100, vp_var_dn, lit_0, lit_0, tmp4, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, if13_1
			dw p_hyp_vdu_c, lit_1
			dw kw_model, 1
			dw kw_strchr, stmp0, var_bd
			dw kw_printstrvar, str6
			dw kw_printstrvar, stmp0
			dw kw_printstrvar, str7
			dw kw_printnl
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop
if13_1:
			dw p_install_c, lit_0
			dw p_hyp_filecall_c, lit_103, lit_m4864, lit_0, arr_sg, lit_256, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_i
			dw p_hyp_filecall_c, lit_102, lit_0, lit_0, lit_0, lit_0, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_i
			dw p_launch_c, lit_0
			dw p_far_c, lit_0, lit_128
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw p_hyp_goinit_c, vp_arr_sg
			dw p_hyp_reply_c, lit_0, lit_0
			dw p_hyp_replye_c, lit_0
			dw kw_vtov, arr_sg, var_k
do14_t:
			dw p_hyp_go_c, var_k
			dw kw_vtov, var_hyp_go_go, var_k
			dw p_hyp_src_c
			dw kw_vtov, var_hyp_src_src, var_i
			dw kw_cpeqvl, var_k, 1
			dw kw_goto_iffalse_n, if15_1
			dw kw_cpeqvl, var_i, 0
			dw kw_goto_iffalse_n, if16_1
			dw p_kcall_c
			dw if15_e_go
if16_1:
			dw p_slotcall_c, var_i
if16_e:
			dw if15_e_go
if15_1:
			dw p_hyp_replye_c, lit_0
if15_e:
			dw kw_aget, arr_sg, var_i, var_k
			dw do14_t_go
do14_e:
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop

ntc_rg1_e:
			IF ($ < 32768) && (ntc_rg2_e - ntc_rg2 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg2:
; ============================================================
; sub kcall (normal mode)
; ============================================================

p_kcall:
			dw p_hyp_count_c
			dw kw_vtov, var_hyp_count_count, var_kcall_c
			dw kw_scpgtvl, var_kcall_c, 0
			dw kw_goto_iffalse_n, if17_1
			dw p_kshow_c, var_kcall_c
if17_1:
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_kcall_c
			dw p_hyp_reply_c, lit_0, lit_0
			dw p_hyp_replye_c, lit_1
			dw kw_cpeqvl, var_kcall_c, 132
			dw kw_goto_iffalse_n, if18_1
			dw p_serve_c
			dw if18_e_go
if18_1:
			dw kw_cpeqvl, var_kcall_c, 0
			dw kw_goto_iffalse_n, if18_2
			dw p_quit_c, lit_m1
			dw if18_e_go
if18_2:
			dw kw_cpnevl, var_kcall_c, 128
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_kcall_c, 129
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if18_3
			dw p_hyp_reply_c, lit_255, lit_255
if18_3:
if18_e:
			dw p_kcall_r

ntc_rg2_e:
			IF ($ < 32768) && (ntc_rg3_e - ntc_rg3 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg3:
; ============================================================
; sub slotcall (normal mode)
; ============================================================

p_slotcall:
			dw p_hyp_count_c
			dw kw_vtov, var_hyp_count_count, var_slotcall_c
			dw p_hyp_replye_c, lit_0
			dw kw_scpgtvl, var_slotcall_c, 0
			dw kw_goto_iffalse_n, if19_1
			dw kw_aget, arr_wp, var_slotcall_t, tmp0
			dw kw_cpeqvv, var_slotcall_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch20_0
			dw kw_ltov, 1, tmp3
			dw ch20_e_go
ch20_0:
			dw kw_ztov, tmp3
			dw ch20_e_go
ch20_1:
			dw kw_ztov, tmp3
ch20_e:
			dw p_hyp_con_c, tmp0, lit_0, var_slotcall_c, tmp3
			dw kw_aget, arr_cnc, var_slotcall_t, tmp1
			dw kw_add, tmp1, var_slotcall_c, tmp1
			dw kw_aset, arr_cnc, var_slotcall_t, tmp1
			dw p_hyp_replye_c, lit_1
if19_1:
			dw kw_aget, arr_cnb, var_slotcall_t, tmp1
			dw kw_inc, tmp1
			dw kw_aset, arr_cnb, var_slotcall_t, tmp1
			dw p_owncall_c, var_slotcall_t
			dw kw_cpeqvl, var_cw, 1
			dw kw_goto_iffalse_n, if21_1
			dw kw_ltov, 255, var_ca
if21_1:
			dw p_hyp_reply_c, var_ca, var_ca
			dw p_slotcall_r

ntc_rg3_e:
			IF ($ < 32768) && (ntc_rg4_e - ntc_rg4 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg4:
; ============================================================
; sub serve (normal mode)
; ============================================================

p_serve:
			dw fn_kin
			dw kw_vtov, arr_kw+2, var_serve_t
			dw kw_vtov, arr_kw, var_serve___sel22
			dw kw_cpeqvl, var_serve___sel22, 22
			dw kw_goto_iffalse_n, sel22_1
sel22_b1:
			dw p_hot_take_c
			dw kw_vtov, var_hot_take_take, arr_kw+16
			dw kw_cpeqvl, arr_kw+16, 0
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_serve_t, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, sel22_e
			dw kw_inkey, tmp0
			dw kw_vtov, tmp0, arr_kw+18
			dw p_hot_control_c
			dw kw_vtov, var_hot_control_control, arr_kw+20
			dw p_hot_held_c
			dw kw_vtov, var_hot_held_held, arr_kw+22
if23_1:
			dw sel22_e_go
sel22_1:
			dw kw_cpeqvl, var_serve___sel22, 1
			dw kw_goto_iffalse_n, sel22_2
sel22_b2:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, arr_kw+16
			dw sel22_e_go
sel22_2:
			dw kw_cpeqvl, var_serve___sel22, 2
			dw kw_goto_iffalse_n, sel22_3
sel22_b3:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, arr_kw+6
			dw sel22_e_go
sel22_3:
			dw kw_cpeqvl, var_serve___sel22, 7
			dw kw_goto_iffalse_n, sel22_4
sel22_b4:
			dw p_kdin_c, vp_arr_kd, arr_kw+4
			dw kw_aget, arr_wp, var_serve_t, tmp0
			dw p_hyp_con_c, tmp0, vp_arr_kd, arr_kw+4, arr_kw+6
			dw sel22_e_go
sel22_4:
			dw kw_cpeqvl, var_serve___sel22, 32
			dw kw_goto_iffalse_n, sel22_5
sel22_b5:
			dw kw_inkey, tmp0
			dw kw_vtov, tmp0, arr_kw+16
			dw p_hot_control_c
			dw kw_vtov, var_hot_control_control, arr_kw+18
			dw p_hot_held_c
			dw kw_vtov, var_hot_held_held, arr_kw+20
			dw sel22_e_go
sel22_5:
			dw kw_cpeqvl, var_serve___sel22, 3
			dw kw_goto_iffalse_n, sel22_6
sel22_b6:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readword, ltmp0, arr_kw+16
			dw sel22_e_go
sel22_6:
			dw kw_cpeqvl, var_serve___sel22, 4
			dw kw_goto_iffalse_n, sel22_7
sel22_b7:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, arr_kw+6
			dw sel22_e_go
sel22_7:
			dw kw_cpeqvl, var_serve___sel22, 5
			dw kw_goto_iffalse_n, sel22_8
sel22_b8:
			dw p_kdin_c, vp_arr_kd, arr_kw+6
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, arr_kw+6, var_memory_copy_copy
			dw sel22_e_go
sel22_8:
			dw kw_cpeqvl, var_serve___sel22, 6
			dw kw_goto_iffalse_n, sel22_9
sel22_b9:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, arr_kw+6, var_memory_copy_copy
			dw p_kdout_c, vp_arr_kd, arr_kw+6
			dw sel22_e_go
sel22_9:
			dw kw_cpeqvl, var_serve___sel22, 8
			dw kw_goto_iffalse_n, sel22_10
sel22_b10:
			dw kw_aget, arr_wp, var_serve_t, tmp0
			dw p_hyp_con_c, tmp0, arr_kw+4, arr_kw+6, arr_kw+8
			dw sel22_e_go
sel22_10:
			dw kw_cpeqvl, var_serve___sel22, 9
			dw kw_goto_iffalse_n, sel22_11
sel22_b11:
			dw p_hyp_scr_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_hyp_scr_scr, arr_kw+16
			dw sel22_e_go
sel22_11:
			dw kw_cpeqvl, var_serve___sel22, 13
			dw kw_goto_iffalse_n, sel22_12
sel22_b12:
			dw kw_cpeqvl, var_serve_t, 100
			dw kw_goto_iffalse_n, if24_1
			dw p_kdin_c, vp_arr_kd, arr_kw+4
			dw p_hyp_filecall_c, lit_100, vp_arr_kd, lit_0, lit_0, arr_kw+4, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16
			dw p_kdout_c, vp_arr_kd, arr_kw+4
			dw sel22_e_go
if24_1:
			dw kw_scpgevl, var_serve_t, 100
			dw kw_goto_iffalse_n, if24_2
			dw kw_aget, arr_sg, arr_kw+6, tmp3
			dw p_hyp_filecall_c, var_serve_t, arr_kw+4, arr_kw+6, tmp3, arr_kw+8, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16
			dw sel22_e_go
if24_2:
			dw kw_aget, arr_sg, arr_kw+6, tmp3
			dw kw_aget, arr_dm, arr_kw+6, tmp4
			dw kw_aget, arr_dv, arr_kw+6, tmp5
			dw p_hyp_filecall_c, var_serve_t, arr_kw+4, arr_kw+6, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16
if24_e:
			dw sel22_e_go
sel22_12:
			dw kw_cpeqvl, var_serve___sel22, 14
			dw kw_goto_iffalse_n, sel22_13
sel22_b13:
			dw p_hyp_drive_c, var_serve_t
			dw kw_vtov, var_hyp_drive_drive, arr_kw+16
			dw sel22_e_go
sel22_13:
			dw kw_cpeqvl, var_serve___sel22, 28
			dw kw_goto_iffalse_n, sel22_14
sel22_b14:
			dw kw_aget, arr_dv, var_serve_t, arr_kw+16
			dw sel22_e_go
sel22_14:
			dw kw_cpeqvl, var_serve___sel22, 29
			dw kw_goto_iffalse_n, sel22_15
sel22_b15:
			dw kw_aset, arr_dv, var_serve_t, arr_kw+4
			dw sel22_e_go
sel22_15:
			dw kw_cpeqvl, var_serve___sel22, 31
			dw kw_goto_iffalse_n, sel22_16
sel22_b16:
			dw kw_aget, arr_dv, var_serve_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if25_1
			dw kw_aset, arr_dv, var_serve_t, var_bd
if25_1:
			dw kw_aget, arr_dv, var_serve_t, tmp0
			dw p_hyp_drive_c, tmp0
			dw kw_vtov, var_hyp_drive_drive, arr_kw+16
			dw sel22_e_go
sel22_16:
			dw kw_cpeqvl, var_serve___sel22, 16
			dw kw_goto_iffalse_n, sel22_17
sel22_b17:
			dw kw_aget, arr_sg, var_serve_t, tmp2
			dw p_hyp_svc_c, var_serve_t, arr_kw+4, tmp2, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, arr_kw+16
			dw sel22_e_go
sel22_17:
			dw kw_cpeqvl, var_serve___sel22, 11
			dw kw_goto_iffalse_n, sel22_18
sel22_b18:
			dw p_kdin_c, vp_arr_kd, var_serve_t
			dw p_hyp_say_c, vp_arr_kd, var_serve_t, arr_kw+4, arr_kw+6
			dw sel22_e_go
sel22_18:
			dw kw_cpeqvl, var_serve___sel22, 10
			dw kw_goto_iffalse_n, sel22_19
sel22_b19:
			dw p_hyp_inks_c, var_serve_t, arr_kw+4, arr_kw+6
			dw sel22_e_go
sel22_19:
			dw kw_cpeqvl, var_serve___sel22, 23
			dw kw_goto_iffalse_n, sel22_20
sel22_b20:
			dw kw_frame
			dw sel22_e_go
sel22_20:
			dw kw_cpeqvl, var_serve___sel22, 24
			dw kw_goto_iffalse_n, sel22_21
sel22_b21:
			dw kw_aset, arr_st, var_serve_t, arr_kw+4
			dw sel22_e_go
sel22_21:
			dw kw_cpeqvl, var_serve___sel22, 25
			dw kw_goto_iffalse_n, sel22_22
sel22_b22:
			dw kw_vtov, var_serve_t, var_front
			dw sel22_e_go
sel22_22:
			dw kw_cpeqvl, var_serve___sel22, 19
			dw kw_goto_iffalse_n, sel22_23
sel22_b23:
			dw p_install_c, var_serve_t
			dw sel22_e_go
sel22_23:
			dw kw_cpeqvl, var_serve___sel22, 30
			dw kw_goto_iffalse_n, sel22_24
sel22_b24:
			dw p_launch_c, var_serve_t
			dw sel22_e_go
sel22_24:
			dw kw_cpeqvl, var_serve___sel22, 15
			dw kw_goto_iffalse_n, sel22_25
sel22_b25:
			dw p_hyp_fileshut_c, var_serve_t
			dw p_hyp_svc_c, var_serve_t, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_serve_c
			dw sel22_e_go
sel22_25:
			dw kw_cpeqvl, var_serve___sel22, 17
			dw kw_goto_iffalse_n, sel22_26
sel22_b26:
			dw p_ramdisc_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_ramdisc_ramdisc, arr_kw+16
			dw sel22_e_go
sel22_26:
			dw kw_cpeqvl, var_serve___sel22, 18
			dw kw_goto_iffalse_n, sel22_27
sel22_b27:
			dw p_storesize_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_storesize_storesize, arr_kw+16
			dw sel22_e_go
sel22_27:
			dw kw_cpeqvl, var_serve___sel22, 20
			dw kw_goto_iffalse_n, sel22_28
sel22_b28:
			dw fn_memory_tableend, arr_kw+16
			dw fn_memory_top, arr_kw+18
			dw fn_memory_pages, arr_kw+20
			dw fn_memory_ramsize, arr_kw+22
			dw fn_memory_freepages, arr_kw+24
			dw sel22_e_go
sel22_28:
			dw kw_cpeqvl, var_serve___sel22, 21
			dw kw_goto_iffalse_n, sel22_29
sel22_b29:
			dw fn_memory_map, var_serve_t, lit_32, var_memory_map_map
			dw kw_strcpy, var_en, var_memory_map_map
			dw kw_strlen, var_en, arr_kw+16
			dw kw_strlen, var_en, tmp1
			dw p_kdout_c, vp_var_en, tmp1
			dw sel22_e_go
sel22_29:
			dw kw_cpeqvl, var_serve___sel22, 26
			dw kw_goto_iffalse_n, sel22_30
sel22_b30:
			dw kw_vtov, var_ns, arr_kw+16
			dw kw_vtov, var_bd, arr_kw+18
			dw kw_ztov, arr_kw+20
			dw kw_vtov, var_mz, arr_kw+22
			dw kw_ltov, 70, arr_kw+24
			dw kw_ztov, arr_kw+26
			dw sel22_e_go
sel22_30:
			dw kw_cpeqvl, var_serve___sel22, 33
			dw kw_goto_iffalse_n, sel22_31
sel22_b31:
			dw p_hyp_bootdrive_c, var_bd, vp_arr_dv
			dw kw_vtov, var_bd, arr_kw+16
			dw sel22_e_go
sel22_31:
			dw kw_cpeqvl, var_serve___sel22, 35
			dw kw_goto_iffalse_n, sel22_32
sel22_b32:
			dw kw_aget, arr_wp, var_serve_t, tmp0
			dw kw_cpeqvv, var_serve_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch26_0
			dw kw_ltov, 1, tmp3
			dw ch26_e_go
ch26_0:
			dw kw_ztov, tmp3
			dw ch26_e_go
ch26_1:
			dw kw_ztov, tmp3
ch26_e:
			dw p_hyp_con_c, tmp0, lit_0, arr_kw+4, tmp3
			dw sel22_e_go
sel22_32:
			dw kw_cpeqvl, var_serve___sel22, 36
			dw kw_goto_iffalse_n, sel22_33
sel22_b33:
			dw kw_aget, arr_sg, var_serve_t, arr_kw+16
			dw sel22_e_go
sel22_33:
			dw kw_cpeqvl, var_serve___sel22, 34
			dw kw_goto_iffalse_n, sel22_34
sel22_b34:
			dw kw_aget, arr_cnb, var_serve_t, arr_kw+16
			dw kw_aget, arr_cnc, var_serve_t, arr_kw+18
			dw kw_asetl, arr_cnb, var_serve_t, 0
			dw kw_asetl, arr_cnc, var_serve_t, 0
			dw sel22_e_go
sel22_34:
			dw kw_cpeqvl, var_serve___sel22, 27
			dw kw_goto_iffalse_n, sel22_35
sel22_b35:
			dw p_quit_c, var_serve_t
sel22_35:
sel22_e:
			dw kw_ticks, tmp0
			dw kw_vtov, tmp0, arr_kw+30
			dw fn_kout
			dw p_serve_r

ntc_rg4_e:
			IF ($ < 32768) && (ntc_rg5_e - ntc_rg5 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg5:
; ============================================================
; sub kdin (normal mode)
; ============================================================

p_kdin:
			dw asm_0_362_n
			dw p_kdin_r

ntc_rg5_e:
			IF ($ < 32768) && (ntc_rg6_e - ntc_rg6 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg6:
; ============================================================
; sub kdout (normal mode)
; ============================================================

p_kdout:
			dw asm_0_382_n
			dw p_kdout_r

ntc_rg6_e:
			IF ($ < 32768) && (ntc_rg7_e - ntc_rg7 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg7:
; ============================================================
; sub kshow (normal mode)
; ============================================================

p_kshow:
			dw kw_vtov, var_front, var_kshow_t
			dw kw_cpeqvl, var_kshow_t, 0
			dw kw_goto_iffalse_n, if27_1
			dw kw_ltov, 1, var_kshow_t
if27_1:
			dw p_far_c, lit_0, lit_m2560
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_kshow_n, var_memory_copy_copy
			dw kw_aget, arr_wp, var_kshow_t, tmp0
			dw kw_cpeqvv, var_kshow_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch28_0
			dw kw_ltov, 1, tmp3
			dw ch28_e_go
ch28_0:
			dw kw_ztov, tmp3
			dw ch28_e_go
ch28_1:
			dw kw_ztov, tmp3
ch28_e:
			dw p_hyp_con_c, tmp0, vp_arr_kd, var_kshow_n, tmp3
			dw p_kshow_r

ntc_rg7_e:
			IF ($ < 32768) && (ntc_rg8_e - ntc_rg8 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg8:
; ============================================================
; sub quit (normal mode)
; ============================================================

p_quit:
			dw p_hyp_scr_c, lit_0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_i
			dw p_hyp_vdu_c, lit_1
			dw kw_model, 1
			dw kw_scpltvl, var_quit_n, 0
			dw kw_goto_iffalse_n, if29_1
			dw kw_printstrvar, str8
			dw kw_printnl
			dw if29_e_go
if29_1:
			dw kw_printstrvar, str9
			dw kw_printint, var_quit_n
			dw kw_printstrvar, str10
			dw kw_printnl
if29_e:
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop

ntc_rg8_e:
			IF ($ < 32768) && (ntc_rg9_e - ntc_rg9 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg9:
; ============================================================
; sub owncall (normal mode)
; ============================================================

p_owncall:
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_owncall_f
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, var_owncall_e
			dw kw_ztov, var_ca
			dw kw_ztov, var_cw
			dw kw_vtov, var_owncall_f, var_owncall___sel30
			dw kw_cpeqvl, var_owncall___sel30, 128
			dw kw_goto_iffalse_n, sel30_1
sel30_b1:
			dw sel30_e_go
sel30_1:
			dw kw_cpeqvl, var_owncall___sel30, 26
			dw kw_goto_iffalse_n, sel30_2
sel30_b2:
			dw kw_aset, arr_dm, var_owncall_t, var_owncall_e
			dw sel30_e_go
sel30_2:
			dw kw_cpeqvl, var_owncall___sel30, 14
			dw kw_goto_iffalse_n, sel30_3
sel30_b3:
			dw kw_andvl, var_owncall_e, 255, tmp2
			dw kw_addl, tmp2, 65, tmp1
			dw kw_aset, arr_dv, var_owncall_t, tmp1
			dw sel30_e_go
sel30_3:
			dw kw_cpeqvl, var_owncall___sel30, 25
			dw kw_goto_iffalse_n, sel30_4
sel30_b4:
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, sel30_e
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_addl, tmp0, -65, var_ca
if31_1:
			dw sel30_e_go
sel30_4:
			dw kw_cpeqvl, var_owncall___sel30, 24
			dw kw_goto_iffalse_n, sel30_5
sel30_b5:
			dw kw_ltov, 1, var_ca
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, sel30_e
			dw kw_ltov, 1, var_owncall_j
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_addl, tmp0, -65, tmp0
			dw kw_andvl, tmp0, 7, for33_l
			dw kw_forupv_n, var_owncall_j, for33_l, sel30_e
for33_t:
			dw kw_2x, var_ca, var_ca
			dw kw_next1v_n, var_owncall_j, for33_l, for33_t
for33_e:
if32_1:
			dw sel30_e_go
sel30_5:
			dw kw_cpeqvl, var_owncall___sel30, 13
			dw kw_goto_iftrue_n, sel30_e
			dw kw_cpeqvl, var_owncall___sel30, 32
			dw kw_goto_iffalse_n, sel30_6
sel30_b6:
			dw sel30_e_go
sel30_6:
			dw kw_scpltvl, var_owncall___sel30, 15
			dw kw_goto_iftrue_n, sel30_7
			dw kw_scplevl, var_owncall___sel30, 36
			dw kw_goto_iffalse_n, sel30_7
sel30_b7:
			dw kw_aget, arr_sg, var_owncall_t, tmp3
			dw kw_aget, arr_dm, var_owncall_t, tmp4
			dw kw_aget, arr_dv, var_owncall_t, tmp5
			dw p_hyp_filecall_c, var_owncall_f, var_owncall_e, var_owncall_t, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_ca
			dw sel30_e_go
sel30_7:
			dw kw_cpeqvl, var_owncall___sel30, 131
			dw kw_goto_iffalse_n, sel30_8
sel30_b8:
			dw p_far_c, var_owncall_t, var_owncall_e
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_owncall_o
			dw kw_cpeqvl, var_owncall_o, 10
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_owncall_o, 11
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_scpgevl, var_owncall_o, 13
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if34_1
			dw kw_aget, arr_sg, var_owncall_t, tmp2
			dw p_hyp_svc_c, var_owncall_t, var_owncall_e, tmp2, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_ca
			dw kw_cpeqvl, var_ca, 1
			dw kw_ftov, tmp0
			dw kw_scpgevl, var_owncall_o, 30
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, sel30_e
			dw kw_ltov, 3, var_cw
if35_1:
			dw sel30_e_go
if34_1:
			dw kw_cpeqvl, var_owncall_o, 12
			dw kw_goto_iffalse_n, if34_2
			dw kw_addl, var_owncall_e, 2, tmp2
			dw p_far_c, var_owncall_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_readword, ltmp1, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp1
			dw p_storesize_c, var_owncall_t, tmp1
			dw kw_vtov, var_storesize_storesize, var_ca
			dw sel30_e_go
if34_2:
			dw kw_ltov, 1, var_cw
if34_e:
			dw sel30_e_go
sel30_8:
			dw kw_cpeqvl, var_owncall___sel30, 12
			dw kw_goto_iffalse_n, sel30_9
sel30_b9:
			dw kw_ltov, 34, var_ca
			dw kw_ltov, 2, var_cw
			dw sel30_e_go
sel30_9:
			dw kw_cpeqvl, var_owncall___sel30, 40
			dw kw_goto_iffalse_n, sel30_10
sel30_b10:
			dw kw_aget, arr_sg, var_owncall_t, tmp3
			dw kw_aget, arr_dm, var_owncall_t, tmp4
			dw kw_aget, arr_dv, var_owncall_t, tmp5
			dw p_hyp_filecall_c, lit_34, var_owncall_e, var_owncall_t, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_ca
			dw kw_ltov, 2, var_cw
			dw sel30_e_go
sel30_10:
			dw kw_cpeqvl, var_owncall___sel30, 130
			dw kw_goto_iffalse_n, sel30_11
sel30_b11:
			dw p_ramdisc_c, var_owncall_t, var_owncall_e
			dw kw_vtov, var_ramdisc_ramdisc, var_ca
			dw kw_ltov, 2, var_cw
			dw sel30_e_go
sel30_11:
			dw kw_ltov, 1, var_cw
sel30_e:
			dw p_owncall_r

ntc_rg9_e:
			IF ($ < 32768) && (ntc_rg10_e - ntc_rg10 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg10:
; ============================================================
; function ramdisc (normal mode)
; ============================================================

p_ramdisc:
			dw p_far_c, var_ramdisc_t, var_ramdisc_p
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_ramdisc_o
			dw kw_cpeqvl, var_dp, 0
			dw kw_goto_iffalse_n, if36_1
			dw kw_ltov, 255, var_ramdisc_ramdisc
			dw kw_cpeqvl, var_ramdisc_o, 3
			dw kw_goto_iffalse_n, if37_1
			dw p_ramdisc_r
if37_1:
			dw fn_memory_allocpage, lit_85, var_dp
			dw kw_cpeqvl, var_dp, 0
			dw kw_goto_iffalse_n, if38_1
			dw kw_ltov, 2, var_ramdisc_ramdisc
			dw p_ramdisc_r
if38_1:
			dw kw_addl, var_ramdisc_p, 2, tmp2
			dw p_far_c, var_ramdisc_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_readword, ltmp1, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp1
			dw p_far_c, var_ramdisc_t, tmp1
			dw kw_l_mov, var_far_far, var_ramdisc_f
			dw fn_hyp_farptr, var_dp, lit_0, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp1
			dw kw_addl, var_ramdisc_p, 4, tmp3
			dw p_far_c, var_ramdisc_t, tmp3
			dw kw_l_mov, var_far_far, ltmp2
			dw fn_memory_readword, ltmp2, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp2
			dw fn_memory_copy, var_ramdisc_f, ltmp1, tmp2, var_memory_copy_copy
			dw fn_memory_selectpage, var_dp, var_ramdisc_g
			dw p_hyp_usedriver_c, vp_arr_rb
			dw p_hyp_filecall_c, lit_110, lit_0, lit_0, lit_0, lit_0, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_ramdisc_g
if36_1:
			dw kw_ztov, var_ramdisc_g
			dw kw_cpeqvl, var_ramdisc_o, 2
			dw kw_goto_iffalse_n, if39_1
			dw fn_memory_allocpage, lit_85, var_ramdisc_g
			dw kw_ltov, 2, var_ramdisc_ramdisc
			dw kw_cpeqvl, var_ramdisc_g, 0
			dw kw_goto_iffalse_n, if40_1
			dw p_ramdisc_r
if40_1:
			dw fn_memory_selectpage, var_ramdisc_g, var_ramdisc_ramdisc
if39_1:
			dw kw_aget, arr_sg, var_ramdisc_t, tmp3
			dw fn_hyp_setting, var_hyp_setting_setting
			dw kw_vtov, var_hyp_setting_setting, tmp5
			dw p_hyp_filecall_c, lit_116, var_ramdisc_p, var_ramdisc_t, tmp3, var_ramdisc_g, tmp5, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_ramdisc_ramdisc
			dw kw_scpltvl, var_ramdisc_ramdisc, 0
			dw kw_goto_iffalse_n, if41_1
			dw kw_andvl, var_ramdisc_ramdisc, 32767, tmp0
			dw fn_memory_freepage, tmp0, var_ramdisc_ramdisc
			dw kw_ztov, var_ramdisc_ramdisc
if41_1:
			dw kw_cpnevl, var_ramdisc_g, 0
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_ramdisc_ramdisc, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if42_1
			dw fn_memory_freepage, var_ramdisc_g, var_ramdisc_ramdisc
			dw kw_ltov, 2, var_ramdisc_ramdisc
if42_1:
			dw p_ramdisc_r

ntc_rg10_e:
			IF ($ < 32768) && (ntc_rg11_e - ntc_rg11 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg11:
; ============================================================
; function storesize (normal mode)
; ============================================================

p_storesize:
			dw kw_addl, var_storesize_kb, 15, tmp0
			dw kw_divvl, tmp0, 16, var_storesize_n
			dw kw_scpltvl, var_storesize_kb, 0
			dw kw_ftov, tmp0
			dw kw_scpgtvl, var_storesize_n, 32
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if43_1
			dw kw_ltov, 32, var_storesize_n
if43_1:
			dw kw_ztov, var_storesize_j
for44_t:
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_storesize_g
			dw kw_scpltvv, var_storesize_j, var_storesize_n
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_storesize_g, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if45_1
			dw fn_memory_allocpage, lit_85, var_storesize_g
			dw kw_cpeqvl, var_storesize_g, 0
			dw kw_goto_iffalse_n, if46_1
			dw kw_ltov, 2, var_storesize_storesize
			dw p_storesize_r
if46_1:
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_storesize_g
			dw if45_e_go
if45_1:
			dw kw_scpgevv, var_storesize_j, var_storesize_n
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_storesize_g, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if45_2
			dw fn_memory_freepage, var_storesize_g, var_memory_freepage_freepage
			dw kw_vtov, var_memory_freepage_freepage, var_storesize_g
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
if45_2:
if45_e:
			dw kw_next1l_n, var_storesize_j, 31, for44_t
for44_e:
			dw p_storesize_r

ntc_rg11_e:
			IF ($ < 32768) && (ntc_rg12_e - ntc_rg12 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg12:
; ============================================================
; function probediscs (normal mode)
; ============================================================

p_probediscs:
			dw kw_ztov, var_probediscs_probediscs
			dw kw_ltov, 2, var_probediscs_p
			dw fn_memory_pages, for47_l
			dw kw_forupv_n, var_probediscs_p, for47_l, for47_e
for47_t:
			dw fn_memory_pagetype, var_probediscs_p, var_memory_pagetype_pagetype
			dw kw_vtov, var_memory_pagetype_pagetype, tmp0
			dw kw_cpeqvl, tmp0, 45
			dw kw_goto_iffalse_n, if48_1
			dw fn_memory_selectpage, var_probediscs_p, var_probediscs_r
			dw kw_lptrtov8, 32512, tmp0
			dw kw_cpeqvl, tmp0, 67
			dw kw_ftov, tmp0
			dw kw_lptrtov8, 32513, tmp1
			dw kw_cpeqvl, tmp1, 89
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_lptrtov8, 32514, tmp1
			dw kw_cpeqvl, tmp1, 66
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_lptrtov8, 32515, tmp1
			dw kw_cpeqvl, tmp1, 68
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_lptrtov8, 32516, tmp1
			dw kw_cpeqvl, tmp1, 90
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_lptrtov8, 32517, tmp1
			dw kw_cpeqvl, tmp1, 203
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if49_1
			dw kw_ztov, var_probediscs_su
			dw kw_ltov, 21504, var_probediscs_j
for50_t:
			dw kw_vptrtov8, var_probediscs_j, tmp1
			dw kw_add, var_probediscs_su, tmp1, tmp0
			dw kw_vtov, tmp0, var_probediscs_su
			dw kw_next1l_n, var_probediscs_j, 23039, for50_t
for50_e:
			dw kw_lptrtov8, 32518, tmp1
			dw kw_lptrtov8, 32519, tmp2
			dw kw_mulvl, tmp2, 256, tmp2
			dw kw_add, tmp1, tmp2, tmp1
			dw kw_cpeqvv, var_probediscs_su, tmp1
			dw kw_goto_iffalse_n, if51_1
			dw p_hyp_claimpage_c, var_probediscs_p
			dw kw_vtov, var_hyp_claimpage_claimpage, var_dp
			dw kw_ztov, var_probediscs_j
for52_t:
			dw kw_mulvl, var_probediscs_j, 6, tmp1
			dw kw_addl, tmp1, 21504, var_probediscs_a
			dw kw_vptrtov8, var_probediscs_a, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, if53_1
			dw kw_addl, var_probediscs_a, 2, tmp0
			dw kw_vptrtov8, tmp0, tmp0
			dw kw_addl, var_probediscs_a, 3, tmp1
			dw kw_vptrtov8, tmp1, tmp1
			dw kw_mulvl, tmp1, 256, tmp1
			dw kw_add, tmp0, tmp1, var_probediscs_pg
			dw p_hyp_claimpage_c, var_probediscs_pg
			dw kw_vtov, var_hyp_claimpage_claimpage, var_probediscs_r
if53_1:
			dw kw_next1l_n, var_probediscs_j, 255, for52_t
for52_e:
			dw fn_memory_selectpage, var_dp, var_probediscs_r
			dw p_hyp_usedriver_c, vp_arr_rb
			dw kw_ltov, -1, var_probediscs_probediscs
			dw p_probediscs_r
if51_1:
if49_1:
if48_1:
			dw kw_next1v_n, var_probediscs_p, for47_l, for47_t
for47_e:
			dw p_probediscs_r

ntc_rg12_e:
			IF ($ < 32768) && (ntc_rg13_e - ntc_rg13 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg13:
; ============================================================
; function nearp (normal mode)
; ============================================================

p_nearp:
			dw kw_l_itol, var_nearp_p, var_nearp_nearp
			dw kw_scpltvl, var_nearp_p, 0
			dw kw_goto_iffalse_n, if54_1
			dw kw_l_add, var_nearp_nearp, llit_65536, var_nearp_nearp
if54_1:
			dw p_nearp_r

ntc_rg13_e:
			IF ($ < 32768) && (ntc_rg14_e - ntc_rg14 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg14:
; ============================================================
; function far (normal mode)
; ============================================================

p_far:
			dw asm_0_564_n
			dw p_far_r

ntc_rg14_e:
			IF ($ < 32768) && (ntc_rg15_e - ntc_rg15 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg15:
; ============================================================
; sub install (normal mode)
; ============================================================

p_install:
			dw fn_hyp_info, lit_0, var_install_p
			dw fn_hyp_info, lit_1, var_install_n
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_0
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy
			dw fn_hyp_info, lit_2, var_install_p
			dw fn_hyp_info, lit_3, var_install_n
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m4352
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy
			dw fn_hyp_farptr, var_hp, lit_4096, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m3328
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, lit_768, var_memory_copy_copy
			dw p_far_c, var_install_t, lit_m2432
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw p_far_c, var_install_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw kw_cpeqvl, var_install_t, 0
			dw kw_goto_iffalse_n, if55_1
			dw p_far_c, var_install_t, lit_59
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, lit_32704
			dw if55_e_go
if55_1:
			dw p_far_c, var_install_t, lit_59
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, arr_sg
if55_e:
			dw p_far_c, var_install_t, lit_61
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, var_install_t
			dw kw_ztov, var_install_n
for56_t:
			dw kw_addl, var_install_n, -256, tmp1
			dw p_far_c, var_install_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw kw_next1l_n, var_install_n, 31, for56_t
for56_e:
			dw p_install_r

ntc_rg15_e:
			IF ($ < 32768) && (ntc_rg16_e - ntc_rg16 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg16:
; ============================================================
; sub launch (normal mode)
; ============================================================

p_launch:
			dw kw_asetl, arr_dm, var_launch_s, 128
			dw p_far_c, var_launch_s, lit_m2427
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw p_far_c, var_launch_s, lit_m3332
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_hyp_info, lit_4, var_hyp_info_info
			dw kw_vtov, var_hyp_info_info, tmp1
			dw fn_memory_writeword, ltmp0, tmp1
			dw p_far_c, var_launch_s, lit_m3330
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, lit_0
			dw p_far_c, var_launch_s, lit_m2
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, lit_m3332
			dw p_launch_r

ntc_rg16_e:
			IF ($ < 32768) && (ntc_rg17_e - ntc_rg17 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg17:
; ============================================================
; sub usedriver (normal mode)
; ============================================================

p_hyp_usedriver:
			dw kw_vtov, var_hyp_usedriver_b, var_hyp_dxb
			dw asm_1_66_n
			dw p_hyp_usedriver_r

ntc_rg17_e:
			IF ($ < 32768) && (ntc_rg18_e - ntc_rg18 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg18:
; ============================================================
; function claimpage (normal mode)
; ============================================================

p_hyp_claimpage:
			dw asm_1_76_n
			dw p_hyp_claimpage_r

ntc_rg18_e:
			IF ($ < 32768) && (ntc_rg19_e - ntc_rg19 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg19:
; ============================================================
; sub con (normal mode)
; ============================================================

p_hyp_con:
			dw asm_1_289_n
			dw p_hyp_con_r

ntc_rg19_e:
			IF ($ < 32768) && (ntc_rg20_e - ntc_rg20 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg20:
; ============================================================
; sub say (normal mode)
; ============================================================

p_hyp_say:
			dw asm_1_1496_n
			dw p_hyp_say_r

ntc_rg20_e:
			IF ($ < 32768) && (ntc_rg21_e - ntc_rg21 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg21:
; ============================================================
; function scr (normal mode)
; ============================================================

p_hyp_scr:
			dw asm_1_1625_n
			dw p_hyp_scr_r

ntc_rg21_e:
			IF ($ < 32768) && (ntc_rg22_e - ntc_rg22 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg22:
; ============================================================
; sub inks (normal mode)
; ============================================================

p_hyp_inks:
			dw asm_1_1755_n
			dw p_hyp_inks_r

ntc_rg22_e:
			IF ($ < 32768) && (ntc_rg23_e - ntc_rg23 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg23:
; ============================================================
; sub keyrep (normal mode)
; ============================================================

p_hyp_keyrep:
			dw asm_1_1816_n
			dw p_hyp_keyrep_r

ntc_rg23_e:
			IF ($ < 32768) && (ntc_rg24_e - ntc_rg24 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg24:
; ============================================================
; sub reply (normal mode)
; ============================================================

p_hyp_reply:
			dw kw_vtov, var_hyp_reply_a, var_hyp_ra
			dw kw_vtov, var_hyp_reply_hl, var_hyp_rhl
			dw p_hyp_reply_r

ntc_rg24_e:
			IF ($ < 32768) && (ntc_rg25_e - ntc_rg25 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg25:
; ============================================================
; function fn (normal mode)
; ============================================================

p_hyp_fn:
			dw kw_andvl, var_hyp_rfn, 255, var_hyp_fn_fn
			dw p_hyp_fn_r

ntc_rg25_e:
			IF ($ < 32768) && (ntc_rg26_e - ntc_rg26 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg26:
; ============================================================
; function arg (normal mode)
; ============================================================

p_hyp_arg:
			dw kw_vtov, var_hyp_rde, var_hyp_arg_arg
			dw p_hyp_arg_r

ntc_rg26_e:
			IF ($ < 32768) && (ntc_rg27_e - ntc_rg27 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg27:
; ============================================================
; function count (normal mode)
; ============================================================

p_hyp_count:
			dw kw_vtov, var_hyp_rcnt, var_hyp_count_count
			dw p_hyp_count_r

ntc_rg27_e:
			IF ($ < 32768) && (ntc_rg28_e - ntc_rg28 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg28:
; ============================================================
; function go (normal mode)
; ============================================================

p_hyp_go:
			dw asm_1_1965_n
			dw p_hyp_go_r

ntc_rg28_e:
			IF ($ < 32768) && (ntc_rg29_e - ntc_rg29 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg29:
; ============================================================
; sub goinit (normal mode)
; ============================================================

p_hyp_goinit:
			dw kw_vtov, var_hyp_goinit_v, var_hyp_gsg
			dw p_hyp_goinit_r

ntc_rg29_e:
			IF ($ < 32768) && (ntc_rg30_e - ntc_rg30 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg30:
; ============================================================
; function src (normal mode)
; ============================================================

p_hyp_src:
			dw kw_vtov, var_hyp_rsrc, var_hyp_src_src
			dw p_hyp_src_r

ntc_rg30_e:
			IF ($ < 32768) && (ntc_rg31_e - ntc_rg31 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg31:
; ============================================================
; sub replye (normal mode)
; ============================================================

p_hyp_replye:
			dw kw_vtov, var_hyp_replye_e, var_hyp_rclr
			dw p_hyp_replye_r

ntc_rg31_e:
			IF ($ < 32768) && (ntc_rg32_e - ntc_rg32 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg32:
; ============================================================
; sub vdu (normal mode)
; ============================================================

p_hyp_vdu:
			dw asm_1_2796_n
			dw p_hyp_vdu_r

ntc_rg32_e:
			IF ($ < 32768) && (ntc_rg33_e - ntc_rg33 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg33:
; ============================================================
; function filecall (normal mode)
; ============================================================

p_hyp_filecall:
			dw asm_1_2832_n
			dw p_hyp_filecall_r

ntc_rg33_e:
			IF ($ < 32768) && (ntc_rg34_e - ntc_rg34 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg34:
; ============================================================
; sub fileshut (normal mode)
; ============================================================

p_hyp_fileshut:
			dw asm_1_4496_n
			dw p_hyp_fileshut_r

ntc_rg34_e:
			IF ($ < 32768) && (ntc_rg35_e - ntc_rg35 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg35:
; ============================================================
; sub svcvars (normal mode)
; ============================================================

p_hyp_svcvars:
			dw kw_vtov, var_hyp_svcvars_vst, var_hyp_svst
			dw kw_vtov, var_hyp_svcvars_vsg, var_hyp_svsg
			dw kw_vtov, var_hyp_svcvars_vns, var_hyp_svns
			dw kw_vtov, var_hyp_svcvars_vfr, var_hyp_svfr
			dw kw_vtov, var_hyp_svcvars_vdp, var_hyp_svdp
			dw p_hyp_svcvars_r

ntc_rg35_e:
			IF ($ < 32768) && (ntc_rg36_e - ntc_rg36 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg36:
; ============================================================
; sub bootdrive (normal mode)
; ============================================================

p_hyp_bootdrive:
			dw kw_vtov, var_hyp_bootdrive_d, var_hyp_svbd
			dw kw_vtov, var_hyp_bootdrive_vdv, var_hyp_svdv
			dw p_hyp_bootdrive_r

ntc_rg36_e:
			IF ($ < 32768) && (ntc_rg37_e - ntc_rg37 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg37:
; ============================================================
; function svc (normal mode)
; ============================================================

p_hyp_svc:
			dw asm_1_4568_n
			dw p_hyp_svc_r

ntc_rg37_e:
			IF ($ < 32768) && (ntc_rg38_e - ntc_rg38 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg38:
; ============================================================
; function drive (normal mode)
; ============================================================

p_hyp_drive:
			dw asm_1_6598_n
			dw p_hyp_drive_r

ntc_rg38_e:
			IF ($ < 32768) && (ntc_rg39_e - ntc_rg39 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg39:
; ============================================================
; sub speed (normal mode)
; ============================================================

p_hot_speed:
			dw kw_scpltvl, var_hot_speed_f, 1
			dw kw_goto_iffalse_n, if57_1
			dw kw_ltov, 1, var_hot_speed_f
if57_1:
			dw kw_scpgtvl, var_hot_speed_f, 40
			dw kw_goto_iffalse_n, if58_1
			dw kw_ltov, 40, var_hot_speed_f
if58_1:
			dw kw_mulvl, var_hot_speed_f, 15, var_hot_dbl
			dw p_hot_speed_r

ntc_rg39_e:
			IF ($ < 32768) && (ntc_rg40_e - ntc_rg40 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg40:
; ============================================================
; sub slots (normal mode)
; ============================================================

p_hot_slots:
			dw kw_vtov, var_hot_slots_n, var_hot_ns
			dw p_hot_slots_r

ntc_rg40_e:
			IF ($ < 32768) && (ntc_rg41_e - ntc_rg41 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg41:
; ============================================================
; sub tick (normal mode)
; ============================================================

p_hot_tick:
			dw fn_keys_down, lit_23, var_hot_ctl
			dw kw_goto_ifzero_n, var_hot_ctl, if59_1
			dw fn_keys_down, lit_64, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if60_1
			dw kw_ltov, 1, var_hot_tick_k
if60_1:
			dw fn_keys_down, lit_65, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if61_1
			dw kw_ltov, 2, var_hot_tick_k
if61_1:
			dw fn_keys_down, lit_57, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if62_1
			dw kw_ltov, 3, var_hot_tick_k
if62_1:
			dw fn_keys_down, lit_56, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if63_1
			dw kw_ltov, 4, var_hot_tick_k
if63_1:
			dw fn_keys_down, lit_49, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if64_1
			dw kw_ltov, 5, var_hot_tick_k
if64_1:
			dw fn_keys_down, lit_48, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if65_1
			dw kw_ltov, 6, var_hot_tick_k
if65_1:
			dw fn_keys_down, lit_41, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if66_1
			dw kw_ltov, 7, var_hot_tick_k
if66_1:
			dw fn_keys_down, lit_40, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if67_1
			dw kw_ltov, 8, var_hot_tick_k
if67_1:
			dw fn_keys_down, lit_33, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if68_1
			dw kw_ltov, 9, var_hot_tick_k
if68_1:
			dw fn_keys_down, lit_32, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if69_1
			dw kw_ltov, 10, var_hot_tick_k
if69_1:
			dw fn_keys_down, lit_66, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if70_1
			dw kw_ltov, 99, var_hot_tick_k
if70_1:
if59_1:
			dw kw_cpnevl, var_hot_tick_k, 0
			dw kw_ftov, tmp6
			dw kw_cpnevv, var_hot_tick_k, var_hot_last
			dw kw_ftov, tmp7
			dw kw_andvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if71_1
			dw kw_cpeqvl, var_hot_tick_k, 99
			dw kw_ftov, tmp6
			dw kw_scplevl, var_hot_ns, 10
			dw kw_ftov, tmp7
			dw kw_orvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if72_1
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if73_1
			dw kw_ztov, var_hot_one
if73_1:
			dw kw_vtov, var_hot_tick_k, var_hot_pend
			dw if72_e_go
if72_1:
			dw kw_cpeqvv, var_hot_one, var_hot_tick_k
			dw kw_goto_iffalse_n, if72_2
			dw kw_ztov, var_hot_one
			dw kw_addl, var_hot_tick_k, 10, tmp6
			dw kw_scplevv, tmp6, var_hot_ns
			dw kw_goto_iffalse_n, if74_1
			dw kw_addl, var_hot_tick_k, 10, var_hot_pend
			dw if72_e_go
if74_1:
			dw kw_vtov, var_hot_tick_k, var_hot_pend
if74_e:
			dw if72_e_go
if72_2:
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if75_1
			dw kw_vtov, var_hot_one, var_hot_pend
if75_1:
			dw kw_vtov, var_hot_tick_k, var_hot_one
			dw kw_ztov, var_hot_age
if72_e:
if71_1:
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if76_1
			dw kw_inc, var_hot_age
			dw kw_cpeqvl, var_hot_dbl, 0
			dw kw_goto_iffalse_n, if77_1
			dw kw_ltov, 15, var_hot_dbl
if77_1:
			dw kw_scpgtvv, var_hot_age, var_hot_dbl
			dw kw_ftov, tmp6
			dw kw_cpeqvl, var_hot_ctl, 0
			dw kw_ftov, tmp7
			dw kw_orvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if78_1
			dw kw_vtov, var_hot_one, var_hot_pend
			dw kw_ztov, var_hot_one
if78_1:
if76_1:
			dw kw_vtov, var_hot_tick_k, var_hot_last
			dw p_hot_tick_r

ntc_rg41_e:
			IF ($ < 32768) && (ntc_rg42_e - ntc_rg42 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg42:
; ============================================================
; function take (normal mode)
; ============================================================

p_hot_take:
			dw kw_vtov, var_hot_pend, var_hot_take_take
			dw kw_ztov, var_hot_pend
			dw p_hot_take_r

ntc_rg42_e:
			IF ($ < 32768) && (ntc_rg43_e - ntc_rg43 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg43:
; ============================================================
; function control (normal mode)
; ============================================================

p_hot_control:
			dw kw_vtov, var_hot_ctl, var_hot_control_control
			dw p_hot_control_r

ntc_rg43_e:
			IF ($ < 32768) && (ntc_rg44_e - ntc_rg44 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg44:
; ============================================================
; function held (normal mode)
; ============================================================

p_hot_held:
			dw kw_vtov, var_hot_last, var_hot_held_held
			dw p_hot_held_r

ntc_rg44_e:
			IF ($ < 32768) && (ntc_rg45_e - ntc_rg45 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg45:
; ============================================================
; function probe (normal mode)
; ============================================================

p_v9_probe:
			dw asm_4_29_n
			dw p_v9_probe_r

ntc_rg45_e:
			IF ($ < 32768) && (ntc_rg46_e - ntc_rg46 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg46:
; ============================================================
; sub init (normal mode)
; ============================================================

p_v9_init:
			dw asm_4_67_n
			dw p_v9_init_r

ntc_rg46_e:
			IF ($ < 32768) && (ntc_rg47_e - ntc_rg47 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg47:
; ============================================================
; function bankpage (normal mode)
; ============================================================

p_memory_bankpage:
			dw kw_4x, var_memory_bankpage_bank, tmp1
			dw kw_addl, tmp1, -2, tmp1
			dw kw_add, tmp1, var_memory_bankpage_n, var_memory_bankpage_bankpage
			dw p_memory_bankpage_r

; ============================================================
; Jump stubs (code, ROMable)
;   label_go: GOTO label
;   label_gs: GOSUB label, return point -> label_rs (RAM)
;   label_rt: RETURN from label
;   p_name_c: call a procedure, p_name_r: end of it
;   turbo mode ends with ret, normal mode with jp ntc_xn
; ============================================================

do6_t_go:			ld sp, do6_t
			jp ntc_xn
if15_e_go:			ld sp, if15_e
			jp ntc_xn
do14_t_go:			ld sp, do14_t
			jp ntc_xn
if18_e_go:			ld sp, if18_e
			jp ntc_xn
ch20_e_go:			ld sp, ch20_e
			jp ntc_xn
sel22_e_go:			ld sp, sel22_e
			jp ntc_xn
ch26_e_go:			ld sp, ch26_e
			jp ntc_xn
ch28_e_go:			ld sp, ch28_e
			jp ntc_xn
if29_e_go:			ld sp, if29_e
			jp ntc_xn
sel30_e_go:			ld sp, sel30_e
			jp ntc_xn
if45_e_go:			ld sp, if45_e
			jp ntc_xn
if55_e_go:			ld sp, if55_e
			jp ntc_xn
if72_e_go:			ld sp, if72_e
			jp ntc_xn

p_kcall_c:		; call kcall (normal)
			ld hl, 0
			ld (var_kcall_c), hl
			ld (p_kcall_rs), sp
			ld sp, p_kcall
			jp ntc_xn
p_kcall_r:		; end of kcall
			ld sp, (p_kcall_rs)
			jp ntc_xn
p_slotcall_c:		; call slotcall (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_slotcall_t), de
			ld hl, 0
			ld (var_slotcall_c), hl
			ld (p_slotcall_rs), sp
			ld sp, p_slotcall
			jp ntc_xn
p_slotcall_r:		; end of slotcall
			ld sp, (p_slotcall_rs)
			jp ntc_xn
p_serve_c:		; call serve (normal)
			ld hl, 0
			ld (var_serve_t), hl
			ld hl, 0
			ld (var_serve_c), hl
			ld (p_serve_rs), sp
			ld sp, p_serve
			jp ntc_xn
p_serve_r:		; end of serve
			ld sp, (p_serve_rs)
			jp ntc_xn
p_kdin_c:		; call kdin (normal)
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_kdin_p), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_kdin_n), de
			ld (p_kdin_rs), sp
			ld sp, p_kdin
			jp ntc_xn
p_kdin_r:		; end of kdin
			ld sp, (p_kdin_rs)
			jp ntc_xn
p_kdout_c:		; call kdout (normal)
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_kdout_p), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_kdout_n), de
			ld (p_kdout_rs), sp
			ld sp, p_kdout
			jp ntc_xn
p_kdout_r:		; end of kdout
			ld sp, (p_kdout_rs)
			jp ntc_xn
p_kshow_c:		; call kshow (normal)
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_kshow_n), de
			ld hl, 0
			ld (var_kshow_t), hl
			ld (p_kshow_rs), sp
			ld sp, p_kshow
			jp ntc_xn
p_kshow_r:		; end of kshow
			ld sp, (p_kshow_rs)
			jp ntc_xn
p_quit_c:		; call quit (normal)
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_quit_n), de
			ld (p_quit_rs), sp
			ld sp, p_quit
			jp ntc_xn
p_quit_r:		; end of quit
			ld sp, (p_quit_rs)
			jp ntc_xn
p_owncall_c:		; call owncall (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_owncall_t), de
			ld hl, 0
			ld (var_owncall_f), hl
			ld hl, 0
			ld (var_owncall_e), hl
			ld hl, 0
			ld (var_owncall_j), hl
			ld hl, 0
			ld (var_owncall_o), hl
			ld (p_owncall_rs), sp
			ld sp, p_owncall
			jp ntc_xn
p_owncall_r:		; end of owncall
			ld sp, (p_owncall_rs)
			jp ntc_xn
p_ramdisc_c:		; call ramdisc (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_ramdisc_t), de
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_ramdisc_p), de
			ld hl, 0
			ld (var_ramdisc_ramdisc), hl
			ld hl, 0
			ld (var_ramdisc_g), hl
			ld hl, 0
			ld (var_ramdisc_o), hl
			ld hl, 0
			ld (var_ramdisc_f), hl
			ld (var_ramdisc_f+2), hl
			ld (p_ramdisc_rs), sp
			ld sp, p_ramdisc
			jp ntc_xn
p_ramdisc_r:		; end of ramdisc
			ld sp, (p_ramdisc_rs)
			jp ntc_xn
p_storesize_c:		; call storesize (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_storesize_t), de
			pop hl			; kb
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_storesize_kb), de
			ld hl, 0
			ld (var_storesize_storesize), hl
			ld hl, 0
			ld (var_storesize_n), hl
			ld hl, 0
			ld (var_storesize_j), hl
			ld hl, 0
			ld (var_storesize_g), hl
			ld (p_storesize_rs), sp
			ld sp, p_storesize
			jp ntc_xn
p_storesize_r:		; end of storesize
			ld sp, (p_storesize_rs)
			jp ntc_xn
p_probediscs_c:		; call probediscs (normal)
			ld hl, 0
			ld (var_probediscs_probediscs), hl
			ld hl, 0
			ld (var_probediscs_p), hl
			ld hl, 0
			ld (var_probediscs_su), hl
			ld hl, 0
			ld (var_probediscs_j), hl
			ld hl, 0
			ld (var_probediscs_a), hl
			ld hl, 0
			ld (var_probediscs_pg), hl
			ld hl, 0
			ld (var_probediscs_r), hl
			ld (p_probediscs_rs), sp
			ld sp, p_probediscs
			jp ntc_xn
p_probediscs_r:		; end of probediscs
			ld sp, (p_probediscs_rs)
			jp ntc_xn
p_nearp_c:		; call nearp (normal)
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_nearp_p), de
			ld hl, 0
			ld (var_nearp_nearp), hl
			ld (var_nearp_nearp+2), hl
			ld (p_nearp_rs), sp
			ld sp, p_nearp
			jp ntc_xn
p_nearp_r:		; end of nearp
			ld sp, (p_nearp_rs)
			jp ntc_xn
p_far_c:		; call far (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_far_t), de
			pop hl			; a
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_far_a), de
			ld hl, 0
			ld (var_far_far), hl
			ld (var_far_far+2), hl
			ld (p_far_rs), sp
			ld sp, p_far
			jp ntc_xn
p_far_r:		; end of far
			ld sp, (p_far_rs)
			jp ntc_xn
p_install_c:		; call install (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_install_t), de
			ld hl, 0
			ld (var_install_p), hl
			ld hl, 0
			ld (var_install_n), hl
			ld (p_install_rs), sp
			ld sp, p_install
			jp ntc_xn
p_install_r:		; end of install
			ld sp, (p_install_rs)
			jp ntc_xn
p_launch_c:		; call launch (normal)
			pop hl			; s
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_launch_s), de
			ld (p_launch_rs), sp
			ld sp, p_launch
			jp ntc_xn
p_launch_r:		; end of launch
			ld sp, (p_launch_rs)
			jp ntc_xn
p_hyp_usedriver_c:		; call usedriver (normal)
			pop hl			; b
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_usedriver_b), de
			ld (p_hyp_usedriver_rs), sp
			ld sp, p_hyp_usedriver
			jp ntc_xn
p_hyp_usedriver_r:		; end of usedriver
			ld sp, (p_hyp_usedriver_rs)
			jp ntc_xn
p_hyp_claimpage_c:		; call claimpage (normal)
			pop hl			; page
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_claimpage_page), de
			ld hl, 0
			ld (var_hyp_claimpage_claimpage), hl
			ld (p_hyp_claimpage_rs), sp
			ld sp, p_hyp_claimpage
			jp ntc_xn
p_hyp_claimpage_r:		; end of claimpage
			ld sp, (p_hyp_claimpage_rs)
			jp ntc_xn
p_hyp_con_c:		; call con (normal)
			pop hl			; pg
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_con_pg), de
			pop hl			; src
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_con_src), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_con_n), de
			pop hl			; front
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_con_front), de
			ld (p_hyp_con_rs), sp
			ld sp, p_hyp_con
			jp ntc_xn
p_hyp_con_r:		; end of con
			ld sp, (p_hyp_con_rs)
			jp ntc_xn
p_hyp_say_c:		; call say (normal)
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_say_p), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_say_n), de
			pop hl			; col
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_say_col), de
			pop hl			; row
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_say_row), de
			ld (p_hyp_say_rs), sp
			ld sp, p_hyp_say
			jp ntc_xn
p_hyp_say_r:		; end of say
			ld sp, (p_hyp_say_rs)
			jp ntc_xn
p_hyp_scr_c:		; call scr (normal)
			pop hl			; m
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_scr_m), de
			pop hl			; k
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_scr_k), de
			ld hl, 0
			ld (var_hyp_scr_scr), hl
			ld (p_hyp_scr_rs), sp
			ld sp, p_hyp_scr
			jp ntc_xn
p_hyp_scr_r:		; end of scr
			ld sp, (p_hyp_scr_rs)
			jp ntc_xn
p_hyp_inks_c:		; call inks (normal)
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_inks_p), de
			pop hl			; q
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_inks_q), de
			pop hl			; b
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_inks_b), de
			ld (p_hyp_inks_rs), sp
			ld sp, p_hyp_inks
			jp ntc_xn
p_hyp_inks_r:		; end of inks
			ld sp, (p_hyp_inks_rs)
			jp ntc_xn
p_hyp_keyrep_c:		; call keyrep (normal)
			pop hl			; f
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_keyrep_f), de
			ld (p_hyp_keyrep_rs), sp
			ld sp, p_hyp_keyrep
			jp ntc_xn
p_hyp_keyrep_r:		; end of keyrep
			ld sp, (p_hyp_keyrep_rs)
			jp ntc_xn
p_hyp_reply_c:		; call reply (normal)
			pop hl			; a
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_reply_a), de
			pop hl			; hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_reply_hl), de
			ld (p_hyp_reply_rs), sp
			ld sp, p_hyp_reply
			jp ntc_xn
p_hyp_reply_r:		; end of reply
			ld sp, (p_hyp_reply_rs)
			jp ntc_xn
p_hyp_fn_c:		; call fn (normal)
			ld hl, 0
			ld (var_hyp_fn_fn), hl
			ld (p_hyp_fn_rs), sp
			ld sp, p_hyp_fn
			jp ntc_xn
p_hyp_fn_r:		; end of fn
			ld sp, (p_hyp_fn_rs)
			jp ntc_xn
p_hyp_arg_c:		; call arg (normal)
			ld hl, 0
			ld (var_hyp_arg_arg), hl
			ld (p_hyp_arg_rs), sp
			ld sp, p_hyp_arg
			jp ntc_xn
p_hyp_arg_r:		; end of arg
			ld sp, (p_hyp_arg_rs)
			jp ntc_xn
p_hyp_count_c:		; call count (normal)
			ld hl, 0
			ld (var_hyp_count_count), hl
			ld (p_hyp_count_rs), sp
			ld sp, p_hyp_count
			jp ntc_xn
p_hyp_count_r:		; end of count
			ld sp, (p_hyp_count_rs)
			jp ntc_xn
p_hyp_go_c:		; call go (normal)
			pop hl			; setting
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_go_setting), de
			ld hl, 0
			ld (var_hyp_go_go), hl
			ld (p_hyp_go_rs), sp
			ld sp, p_hyp_go
			jp ntc_xn
p_hyp_go_r:		; end of go
			ld sp, (p_hyp_go_rs)
			jp ntc_xn
p_hyp_goinit_c:		; call goinit (normal)
			pop hl			; v
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_goinit_v), de
			ld (p_hyp_goinit_rs), sp
			ld sp, p_hyp_goinit
			jp ntc_xn
p_hyp_goinit_r:		; end of goinit
			ld sp, (p_hyp_goinit_rs)
			jp ntc_xn
p_hyp_src_c:		; call src (normal)
			ld hl, 0
			ld (var_hyp_src_src), hl
			ld (p_hyp_src_rs), sp
			ld sp, p_hyp_src
			jp ntc_xn
p_hyp_src_r:		; end of src
			ld sp, (p_hyp_src_rs)
			jp ntc_xn
p_hyp_replye_c:		; call replye (normal)
			pop hl			; e
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_replye_e), de
			ld (p_hyp_replye_rs), sp
			ld sp, p_hyp_replye
			jp ntc_xn
p_hyp_replye_r:		; end of replye
			ld sp, (p_hyp_replye_rs)
			jp ntc_xn
p_hyp_vdu_c:		; call vdu (normal)
			pop hl			; on
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_vdu_on), de
			ld (p_hyp_vdu_rs), sp
			ld sp, p_hyp_vdu
			jp ntc_xn
p_hyp_vdu_r:		; end of vdu
			ld sp, (p_hyp_vdu_rs)
			jp ntc_xn
p_hyp_filecall_c:		; call filecall (normal)
			pop hl			; f
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_f), de
			pop hl			; fcb
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_fcb), de
			pop hl			; slot
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_slot), de
			pop hl			; setting
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_setting), de
			pop hl			; dma
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_dma), de
			pop hl			; drive
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_drive), de
			pop hl			; buf
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_buf), de
			ld hl, 0
			ld (var_hyp_filecall_filecall), hl
			ld (p_hyp_filecall_rs), sp
			ld sp, p_hyp_filecall
			jp ntc_xn
p_hyp_filecall_r:		; end of filecall
			ld sp, (p_hyp_filecall_rs)
			jp ntc_xn
p_hyp_fileshut_c:		; call fileshut (normal)
			pop hl			; slot
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_fileshut_slot), de
			ld (p_hyp_fileshut_rs), sp
			ld sp, p_hyp_fileshut
			jp ntc_xn
p_hyp_fileshut_r:		; end of fileshut
			ld sp, (p_hyp_fileshut_rs)
			jp ntc_xn
p_hyp_svcvars_c:		; call svcvars (normal)
			pop hl			; vst
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svcvars_vst), de
			pop hl			; vsg
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svcvars_vsg), de
			pop hl			; vns
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svcvars_vns), de
			pop hl			; vfr
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svcvars_vfr), de
			pop hl			; vdp
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svcvars_vdp), de
			ld (p_hyp_svcvars_rs), sp
			ld sp, p_hyp_svcvars
			jp ntc_xn
p_hyp_svcvars_r:		; end of svcvars
			ld sp, (p_hyp_svcvars_rs)
			jp ntc_xn
p_hyp_bootdrive_c:		; call bootdrive (normal)
			pop hl			; d
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_bootdrive_d), de
			pop hl			; vdv
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_bootdrive_vdv), de
			ld (p_hyp_bootdrive_rs), sp
			ld sp, p_hyp_bootdrive
			jp ntc_xn
p_hyp_bootdrive_r:		; end of bootdrive
			ld sp, (p_hyp_bootdrive_rs)
			jp ntc_xn
p_hyp_svc_c:		; call svc (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svc_t), de
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svc_p), de
			pop hl			; setting
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svc_setting), de
			pop hl			; buf
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_svc_buf), de
			ld hl, 0
			ld (var_hyp_svc_svc), hl
			ld (p_hyp_svc_rs), sp
			ld sp, p_hyp_svc
			jp ntc_xn
p_hyp_svc_r:		; end of svc
			ld sp, (p_hyp_svc_rs)
			jp ntc_xn
p_hyp_drive_c:		; call drive (normal)
			pop hl			; letter
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_drive_letter), de
			ld hl, 0
			ld (var_hyp_drive_drive), hl
			ld (p_hyp_drive_rs), sp
			ld sp, p_hyp_drive
			jp ntc_xn
p_hyp_drive_r:		; end of drive
			ld sp, (p_hyp_drive_rs)
			jp ntc_xn
p_hot_speed_c:		; call speed (normal)
			pop hl			; f
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hot_speed_f), de
			ld (p_hot_speed_rs), sp
			ld sp, p_hot_speed
			jp ntc_xn
p_hot_speed_r:		; end of speed
			ld sp, (p_hot_speed_rs)
			jp ntc_xn
p_hot_slots_c:		; call slots (normal)
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hot_slots_n), de
			ld (p_hot_slots_rs), sp
			ld sp, p_hot_slots
			jp ntc_xn
p_hot_slots_r:		; end of slots
			ld sp, (p_hot_slots_rs)
			jp ntc_xn
p_hot_tick_c:		; call tick (normal)
			ld hl, 0
			ld (var_hot_tick_k), hl
			ld (p_hot_tick_rs), sp
			ld sp, p_hot_tick
			jp ntc_xn
p_hot_tick_r:		; end of tick
			xor a			; Tick done: it may run again
			ld (ntc_isl + 4), a
			ld sp, (p_hot_tick_rs)
			jp ntc_xn
p_hot_take_c:		; call take (normal)
			ld hl, 0
			ld (var_hot_take_take), hl
			ld (p_hot_take_rs), sp
			ld sp, p_hot_take
			jp ntc_xn
p_hot_take_r:		; end of take
			ld sp, (p_hot_take_rs)
			jp ntc_xn
p_hot_control_c:		; call control (normal)
			ld hl, 0
			ld (var_hot_control_control), hl
			ld (p_hot_control_rs), sp
			ld sp, p_hot_control
			jp ntc_xn
p_hot_control_r:		; end of control
			ld sp, (p_hot_control_rs)
			jp ntc_xn
p_hot_held_c:		; call held (normal)
			ld hl, 0
			ld (var_hot_held_held), hl
			ld (p_hot_held_rs), sp
			ld sp, p_hot_held
			jp ntc_xn
p_hot_held_r:		; end of held
			ld sp, (p_hot_held_rs)
			jp ntc_xn
p_v9_probe_c:		; call probe (normal)
			ld hl, 0
			ld (var_v9_probe_probe), hl
			ld (p_v9_probe_rs), sp
			ld sp, p_v9_probe
			jp ntc_xn
p_v9_probe_r:		; end of probe
			ld sp, (p_v9_probe_rs)
			jp ntc_xn
p_v9_init_c:		; call init (normal)
			pop hl			; pal
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_v9_init_pal), de
			ld (p_v9_init_rs), sp
			ld sp, p_v9_init
			jp ntc_xn
p_v9_init_r:		; end of init
			ld sp, (p_v9_init_rs)
			jp ntc_xn
p_memory_bankpage_c:		; call bankpage (normal)
			pop hl			; bank
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_memory_bankpage_bank), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_memory_bankpage_n), de
			ld hl, 0
			ld (var_memory_bankpage_bankpage), hl
			ld (p_memory_bankpage_rs), sp
			ld sp, p_memory_bankpage
			jp ntc_xn
p_memory_bankpage_r:		; end of bankpage
			ld sp, (p_memory_bankpage_rs)
			jp ntc_xn

ntc_rg47_e:
			IF ($ < 32768) && (ntc_rg48_e - ntc_rg48 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg48:
; ============================================================
; Inline assembly (#asm ... #endasm)
; ============================================================

asm_0_69_n:		; #asm, Main.bas line 69 (normal)
            ld (ntc_ip), sp         ; the upper ROM off for good (CALLed from BASIC its ROM is on): the
            ld sp, (ntc_csp)        ; banks' top 16K must be RAM when C0 switches to them; a firmware
            call #B903              ; call into a ROM turns it on and back off itself
            di                      ; (KL U ROM DISABLE)
            ld sp, (ntc_ip)
			ret			; end of #asm

fn_kin:		; sub kin (asm keyword), Main.bas line 334
            ld bc, (var_kwp)          ; the kernel's page 3 in the window: its #EE00 at #6E00
            out (c), c
            ld hl, 60928 - #8000
            ld de, arr_kw
            ld bc, 32
            ldir
            ld bc, (ntc_rampt)      ; the page that was in the window back
            out (c), c
			ret			; end of #asm

fn_kout:		; sub kout (asm keyword), Main.bas line 348
            ld bc, (var_kwp)
            out (c), c
            ld hl, arr_kw + 16
            ld de, 60928 - #8000 + 16
            ld bc, 16
            ldir
            ld bc, (ntc_rampt)
            out (c), c
			ret			; end of #asm

asm_0_362_n:		; #asm, Main.bas line 362 (normal)
            ld bc, (var_kwp)
            out (c), c
            ld hl, 60928 - #8000 + 32
            ld de, (var_kdin_p)
            ld bc, (var_kdin_n)
            ld a, b
            or c
            jr z, asm_0_362_n_kdi_none
            ldir
asm_0_362_n_kdi_none:
            xor a
            ld (de), a
            ld bc, (ntc_rampt)
            out (c), c
			ret			; end of #asm

asm_0_382_n:		; #asm, Main.bas line 382 (normal)
            ld bc, (var_kwp)
            out (c), c
            ld hl, (var_kdout_p)
            ld de, 60928 - #8000 + 32
            ld bc, (var_kdout_n)
            ld a, b
            or c
            jr z, asm_0_382_n_kdo_none
            ldir
asm_0_382_n_kdo_none:
            ld bc, (ntc_rampt)
            out (c), c
			ret			; end of #asm

asm_0_564_n:		; #asm, Main.bas line 564 (normal)
            ld a, (var_far_t)
            add a, a
            add a, a                ; t * 4
            ld e, a
            ld a, (var_far_a + 1)
            rlca
            rlca
            and 3                   ; + the address's 16K page
            add a, e
            ld e, a
            ld d, 0
            ld hl, arr_bpg
            add hl, de
            add hl, de
            ld c, (hl)
            inc hl
            ld b, (hl)              ; BC = the page
            ld hl, (var_far_a)
            ld a, h
            and #3F
            or #40
            ld h, a                 ; HL = #4000 + the low 14 bits
            ld (var_far_far), hl
            ld (var_far_far + 2), bc
			ret			; end of #asm

fn_hyp_usepage:		; sub usepage (asm keyword), Hyp.cls line 56
            ld hl, (ntc_rampt)
            ld (var_hyp_hps), hl
			ret			; end of #asm

asm_1_66_n:		; #asm, Hyp.cls line 66 (normal)
            ld hl, (ntc_rampt)
            ld (var_hyp_drs), hl
			ret			; end of #asm

asm_1_76_n:		; #asm, Hyp.cls line 76 (normal)
            ld hl, (var_hyp_claimpage_page)
            ld a, h
            or l
            jr z, asm_1_76_n_cp_no
            ld de, (mem_count)
            ex de, hl
            or a
            sbc hl, de              ; page - count: carry means page > count
            jr c, asm_1_76_n_cp_no
            ld hl, (var_hyp_claimpage_page)         ; the RAT byte: (mem_ttype) + page - 1
            ld de, (mem_ttype)
            add hl, de
            dec hl
            ld a, (hl)
            cp "-"                  ; free?
            jr nz, asm_1_76_n_cp_no
            ld (hl), "U"            ; TypeUser
            ld hl, (var_hyp_claimpage_page)
            jr asm_1_76_n_cp_done
asm_1_76_n_cp_no:
            ld hl, 0
asm_1_76_n_cp_done:
            ld (var_hyp_claimpage_claimpage), hl
			ret			; end of #asm

fn_hyp_setting:		; function setting (asm keyword), Hyp.cls line 104
            ld de, (ntc_rampt)
            ld a, e
            and #F8
            or 2
            ld e, a
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
			ret			; end of #asm

fn_hyp_farptr:		; function farptr (asm keyword), Hyp.cls line 120
            pop hl
            ld c, (hl)
            inc hl
            ld b, (hl)              ; BC = page
            pop hl
            ld e, (hl)
            inc hl
            ld a, (hl)
            and #3F
            or #40
            ld d, a                 ; DE = #4000 + the address's low 14 bits
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
            inc hl
            ld (hl), c
            inc hl
            ld (hl), b
			ret			; end of #asm

fn_hyp_fontinit:		; sub fontinit (asm keyword), Hyp.cls line 173
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld bc, (var_hyp_hps)
            out (c), c
            ld de, 32               ; D = 0: a table, E = its first character
            ld hl, #4000 + 4096
            call #BBAB              ; TXT SET M TABLE (the matrices from 32 on, copied there)
            di
            ld de, #FF00            ; D <> 0: no table of its own any more
            call #BBAB
            di
            ld bc, (ntc_rampt)
            out (c), c
            ld sp, (var_hyp_hsp)
			ret			; end of #asm

asm_1_289_n:		; #asm, Hyp.cls line 289 (normal)
; CN_SB 1: the scrollback (Shift + Up / Down: 48 rows a slot, kept in a 16K page Main gives - #If
; SCROLLBACK in Main.bas, set the two together). Off for now: 526 bytes of main RAM (2026-10-16)
asm_1_289_n_CN_SB:      equ 0
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld bc, (var_hyp_con_pg)
            out (c), c              ; the slot's page 3 at #4000: OBUF #7600, state #7682, page #7700
            IF asm_1_289_n_CN_SB
            ld (asm_1_289_n_cn_pg), bc
            ENDIF
            xor a
            ld (asm_1_289_n_cn_pv), a
            ld a, (var_hyp_con_front)
            ld (asm_1_289_n_cn_front), a
            ld a, (#7687)           ; its columns and rows (MODE)
            ld (asm_1_289_n_cn_c), a
            ld a, (#7688)
            ld (asm_1_289_n_cn_r), a
            ld a, (var_hyp_ccu)           ; the cursor off first, whatever comes (it was on: cn_was)
            ld (asm_1_289_n_cn_was), a
            or a
            call nz, asm_1_289_n_cn_cuxor
            ld hl, (var_hyp_con_n)
            bit 7, h
            jp nz, asm_1_289_n_cn_neg
            ld (asm_1_289_n_cn_left), hl
            IF asm_1_289_n_CN_SB
            ld a, (asm_1_289_n_cn_front)        ; in front and looking back (scrollback): the page again first
            or a
            jr z, asm_1_289_n_cn_live
            ld a, (#7F26)
            or a
            jr z, asm_1_289_n_cn_live
            xor a
            ld (#7F26), a
            call asm_1_289_n_cn_cls
            call asm_1_289_n_cn_strip
            call asm_1_289_n_cn_draw
            ld hl, (asm_1_289_n_cn_left)
asm_1_289_n_cn_live:
            ENDIF
            ld hl, (var_hyp_con_src)
            ld a, h
            or l
            jr nz, asm_1_289_n_cn_src
            ld hl, #7600            ; src 0: the characters the program collected (OBUF)
asm_1_289_n_cn_src:
            ld (asm_1_289_n_cn_ptr), hl
asm_1_289_n_cn_lp:
            ld hl, (asm_1_289_n_cn_left)
            ld a, h
            or l
            jr z, asm_1_289_n_cn_done
            dec hl
            ld (asm_1_289_n_cn_left), hl
            ld hl, (asm_1_289_n_cn_ptr)
            ld a, (hl)
            inc hl
            ld (asm_1_289_n_cn_ptr), hl
            call asm_1_289_n_cn_char
            jr asm_1_289_n_cn_lp
asm_1_289_n_cn_done:
            ld bc, (ntc_rampt)      ; the window's page back
            out (c), c
            ld sp, (var_hyp_hsp)
            jp asm_1_289_n_cn_end

; n < 0: -1 the whole page to the screen (it was cleared: Show), not looking back any more; -2
; the scrollback (src: the key - #F4 Shift + Up a screen back, #F5 Shift + Down one on), drawn
asm_1_289_n_cn_neg:
            ld a, l
            cp #FD                  ; -3: the cursor flashes - on (it was off), an underline XORed
            jr nz, asm_1_289_n_cn_neg1          ; where the next character goes; off (it was on: done above)
            ld a, (asm_1_289_n_cn_front)
            or a
            jr z, asm_1_289_n_cn_done
            ld a, (var_hyp_nta)           ; the network blink: advance it (0.5s) while there's traffic
            or a
            jr z, asm_1_289_n_cn_nt1
            dec a
            ld (var_hyp_nta), a
            ld a, (var_hyp_ntb)
            xor 1
            ld (var_hyp_ntb), a
asm_1_289_n_cn_nt1:
            call asm_1_289_n_cn_net
            ld a, (asm_1_289_n_cn_was)
            or a
            jr nz, asm_1_289_n_cn_done
            ld a, (#7682)
            ld d, a
            ld a, (#7683)
            ld e, a
            call asm_1_289_n_cn_scr
            ld a, (v9_on)           ; (the V9990: the cell itself - V9.cls)
            or a
            jr nz, asm_1_289_n_cn_ca_v9
            ld a, h
            add a, #38              ; (its cell's last pixel line)
            ld h, a
asm_1_289_n_cn_ca_v9:
            ld (asm_1_289_n_cn_ca), hl
            call asm_1_289_n_cn_cuxor
            jr asm_1_289_n_cn_done
asm_1_289_n_cn_neg1:
            IF asm_1_289_n_CN_SB
            inc hl
            ld a, h
            or l
            jr nz, asm_1_289_n_cn_view
            ld (#7F26), a
            ENDIF
asm_1_289_n_cn_show:
            call asm_1_289_n_cn_strip
            call asm_1_289_n_cn_draw
            jr asm_1_289_n_cn_done
            IF asm_1_289_n_CN_SB
asm_1_289_n_cn_view:
            ld a, (#7F21)           ; (no history page: nothing)
            or a
            jr z, asm_1_289_n_cn_done
            ld a, (asm_1_289_n_cn_r)
            dec a
            ld b, a                 ; a screen: its rows - 1
            ld a, (var_hyp_con_src)
            cp #F4
            ld a, (#7F26)
            jr nz, asm_1_289_n_cn_vw_dn
            add a, b
            ld hl, #7F25
            cp (hl)
            jr c, asm_1_289_n_cn_vw_set
            ld a, (hl)              ; (not past the oldest row kept)
            jr asm_1_289_n_cn_vw_set
asm_1_289_n_cn_vw_dn:
            sub b
            jr nc, asm_1_289_n_cn_vw_set
            xor a
asm_1_289_n_cn_vw_set:
            ld hl, #7F26
            cp (hl)
            jr z, asm_1_289_n_cn_done
            ld (hl), a
            call asm_1_289_n_cn_cls
            jr asm_1_289_n_cn_show

            ENDIF

; the screen's rows: the page's - or, looking back (#FF26 rows), the history's first, then the
; page's. Row e shows line count + e - back of history + page (count the rows kept, #FF25)
asm_1_289_n_cn_draw:
            ld e, 0
            IF asm_1_289_n_CN_SB
asm_1_289_n_cn_dr_row:
            push de
            ld a, (#7F25)
            add a, e
            ld hl, #7F26
            sub (hl)                ; the line: count + e - back
            ld hl, #7F25
            sub (hl)
            jr c, asm_1_289_n_cn_dr_h
            call asm_1_289_n_cn_rowa            ; HL = row (line - count) of the page
            ld a, (asm_1_289_n_cn_c)
            jr asm_1_289_n_cn_dr_go
asm_1_289_n_cn_dr_h:
            add a, (hl)
            call asm_1_289_n_cn_hget            ; HL = the history's row (copied in), 80 characters at most
            ld a, (asm_1_289_n_cn_c)
            cp asm_1_289_n_HW
            jr c, asm_1_289_n_cn_dr_go
            ld a, asm_1_289_n_HW
asm_1_289_n_cn_dr_go:
            ld b, a
            pop de
            push de
            ld d, 0
asm_1_289_n_cn_dr_col:
            ld a, (hl)
            inc hl
            cp 33
            jr c, asm_1_289_n_cn_dr_sk
            push hl
            push de
            push bc
            call asm_1_289_n_cn_glyph
            pop bc
            pop de
            pop hl
asm_1_289_n_cn_dr_sk:
            inc d
            djnz asm_1_289_n_cn_dr_col
            pop de
            inc e
            ld a, (asm_1_289_n_cn_r)
            dec a
            cp e
            jr nc, asm_1_289_n_cn_dr_row
            ret
            ELSE
asm_1_289_n_cn_sh_row:                          ; (no scrollback: the page's rows as they are)
            push de
            ld a, e
            call asm_1_289_n_cn_rowa            ; HL = row e of the page
            pop de
            ld d, 0
asm_1_289_n_cn_sh_col:
            ld a, (hl)
            inc hl
            cp 33
            jr c, asm_1_289_n_cn_sh_skip
            push hl
            push de
            call asm_1_289_n_cn_glyph
            pop de
            pop hl
asm_1_289_n_cn_sh_skip:
            inc d
            ld a, (asm_1_289_n_cn_c)
            dec a
            cp d
            jr nc, asm_1_289_n_cn_sh_col
            inc e
            ld a, (asm_1_289_n_cn_r)
            dec a
            cp e
            jr nc, asm_1_289_n_cn_sh_row
            ret
            ENDIF

            IF asm_1_289_n_CN_SB
; the scrollback: each row that scrolls off the top of the page - its first HW characters - goes
; to the slot's history: HROWS rows (a ring) in a 16K page of its own that Main gave it (#FF20:
; its RAM setting, 0 none; #FF22 where in it; #FF24 the next row written, #FF25 how many, #FF26
; how far back the screen looks). Copied 8 bytes at a time through the stack - only the window
; changes, so no main RAM for a buffer
asm_1_289_n_HW:         equ 80
asm_1_289_n_HROWS:      equ 48
asm_1_289_n_cn_hput:                            ; HL = the row going (the page)
            ld a, (#7F21)
            or a
            ret z
            ld (asm_1_289_n_cn_hs), hl
            ld hl, (asm_1_289_n_cn_pg)
            ld (asm_1_289_n_cn_h1), hl
            ld hl, (#7F20)
            ld (asm_1_289_n_cn_h2), hl
            ld a, (#7F24)
            call asm_1_289_n_cn_haddr
            ld (asm_1_289_n_cn_hd), hl
            ld hl, #7F24            ; the next row on, one more kept
            ld a, (hl)
            inc a
            cp asm_1_289_n_HROWS
            jr c, asm_1_289_n_cn_hp_h
            xor a
asm_1_289_n_cn_hp_h:
            ld (hl), a
            inc hl
            ld a, (hl)
            cp asm_1_289_n_HROWS
            jr nc, asm_1_289_n_cn_hcp
            inc (hl)
; cn_hcp: HW bytes from cn_hs in RAM setting cn_h1 to cn_hd in cn_h2, then the slot's page back
asm_1_289_n_cn_hcp:
            ld a, asm_1_289_n_HW / 8
asm_1_289_n_cn_hc_lp:
            ld (asm_1_289_n_cn_hn), a
            ld bc, (asm_1_289_n_cn_h1)
            out (c), c
            ld hl, (asm_1_289_n_cn_hs)
            ld b, 4
asm_1_289_n_cn_hc_in:
            ld e, (hl)
            inc hl
            ld d, (hl)
            inc hl
            push de
            djnz asm_1_289_n_cn_hc_in
            ld (asm_1_289_n_cn_hs), hl
            ld bc, (asm_1_289_n_cn_h2)
            out (c), c
            ld hl, (asm_1_289_n_cn_hd)
            ld de, 8
            add hl, de
            ld (asm_1_289_n_cn_hd), hl
            ld b, 4
asm_1_289_n_cn_hc_out:
            pop de
            dec hl
            ld (hl), d
            dec hl
            ld (hl), e
            djnz asm_1_289_n_cn_hc_out
            ld a, (asm_1_289_n_cn_hn)
            dec a
            jr nz, asm_1_289_n_cn_hc_lp
            ld bc, (asm_1_289_n_cn_pg)
            out (c), c
            ret
asm_1_289_n_cn_hget:                            ; A = a line of the history (0 the oldest kept): copied to
            ld hl, #7F24            ; #FF30 in the slot's page (HL)
            add a, (hl)
            inc hl
            sub (hl)
            jr nc, asm_1_289_n_cn_hg_r
            add a, asm_1_289_n_HROWS
asm_1_289_n_cn_hg_r:
            call asm_1_289_n_cn_haddr
            ld (asm_1_289_n_cn_hs), hl
            ld hl, (#7F20)
            ld (asm_1_289_n_cn_h1), hl
            ld hl, (asm_1_289_n_cn_pg)
            ld (asm_1_289_n_cn_h2), hl
            ld hl, #7F30
            ld (asm_1_289_n_cn_hd), hl
            call asm_1_289_n_cn_hcp
            ld hl, #7F30
            ret
asm_1_289_n_cn_haddr:                           ; A = a history row: HL = its address in the history page
            ld e, a
            ld a, asm_1_289_n_HW
            call asm_1_289_n_cn_mul
            ld de, (#7F22)
            add hl, de
            ret
; cn_cls: the screen cleared (written only: the Library: ROM build's keyword ROM may be over it)
asm_1_289_n_cn_cls:
            ld hl, #C000
            ld bc, #4000
asm_1_289_n_cn_cl_lp:
            ld (hl), 0
            inc hl
            dec bc
            ld a, b
            or c
            jr nz, asm_1_289_n_cn_cl_lp
            ret
            ENDIF

; cn_char: A = one character
asm_1_289_n_cn_char:
            ld b, a
            ld a, (#7685)           ; in an escape sequence?
            or a
            jr nz, asm_1_289_n_cn_esc0
            ld a, b
            cp 32
            jp nc, asm_1_289_n_cn_print
            ld hl, asm_1_289_n_cn_pv            ; a control code: the cursor may move (the pointers redone)
            ld (hl), 0
            cp 27
            jr z, asm_1_289_n_cn_setesc
            cp 13
            jr z, asm_1_289_n_cn_cr
            cp 10
            jp z, asm_1_289_n_cn_nl
            cp 9
            jr z, asm_1_289_n_cn_tab
            cp 8
            ret nz                  ; other control codes: nothing
            ld a, (#7682)           ; BS: back one (not past the start of the row)
            or a
            ret z
            dec a
            ld (#7682), a
            ret
asm_1_289_n_cn_tab:                             ; TAB: spaces to the next column of 8
            ld b, ' '
            call asm_1_289_n_cn_print
            ld a, (#7682)
            and 7
            jr nz, asm_1_289_n_cn_tab
            ret
asm_1_289_n_cn_setesc:
            ld a, 1
            ld (#7685), a
            ret
asm_1_289_n_cn_cr:
            xor a
            ld (#7682), a
            ret
asm_1_289_n_cn_esc0:
            ld hl, asm_1_289_n_cn_pv
            ld (hl), 0
asm_1_289_n_cn_esc:
            cp 1
            jr nz, asm_1_289_n_cn_esc2
            xor a                   ; ESC x
            ld (#7685), a
            ld a, b
            cp 'E'
            jp z, asm_1_289_n_cn_clear
            cp 'H'
            jr z, asm_1_289_n_cn_home
            cp 'I'
            jp z, asm_1_289_n_cn_rev
            cp 'Y'
            jr z, asm_1_289_n_cn_sety
            cp 'A'
            jr z, asm_1_289_n_cn_up
            cp 'B'
            jr z, asm_1_289_n_cn_down
            cp 'C'
            jr z, asm_1_289_n_cn_right
            cp 'D'
            jr z, asm_1_289_n_cn_lft
            cp 'K'
            jp z, asm_1_289_n_cn_eol
            cp 'J'
            jp z, asm_1_289_n_cn_eos
            cp 'l'
            jp z, asm_1_289_n_cn_eln
            cp 'o'
            jp z, asm_1_289_n_cn_sol
            cp 'd'
            jp z, asm_1_289_n_cn_sos
            cp 'M'
            jp z, asm_1_289_n_cn_dell
            cp 'L'
            jp z, asm_1_289_n_cn_insl
            ret                     ; (the rest - e f j k p q ...: nothing)
asm_1_289_n_cn_sety:
            ld a, 2
            ld (#7685), a
            ret
asm_1_289_n_cn_up:                              ; ESC A, B, C, D: up, down, right, left (not past the edge)
            ld hl, #7683
            jr asm_1_289_n_cn_dec
asm_1_289_n_cn_lft:
            ld hl, #7682
asm_1_289_n_cn_dec:
            ld a, (hl)
            or a
            ret z
            dec (hl)
            ret
asm_1_289_n_cn_down:
            ld de, #7683
            ld hl, asm_1_289_n_cn_r
            jr asm_1_289_n_cn_inc
asm_1_289_n_cn_right:
            ld de, #7682
            ld hl, asm_1_289_n_cn_c
asm_1_289_n_cn_inc:
            ld a, (de)
            inc a
            cp (hl)
            ret nc
            ld (de), a
            ret
asm_1_289_n_cn_home:
            xor a
            ld (#7682), a
            ld (#7683), a
            ret
asm_1_289_n_cn_esc2:
            cp 2
            jr nz, asm_1_289_n_cn_esc3
            ld a, b                 ; ESC Y row
            sub 32
            ld (#7686), a
            ld a, 3
            ld (#7685), a
            ret
asm_1_289_n_cn_esc3:
            xor a                   ; ESC Y row col
            ld (#7685), a
            ld a, b
            sub 32
            ld hl, asm_1_289_n_cn_c
            cp (hl)
            jr c, asm_1_289_n_cn_e3_col
            xor a
asm_1_289_n_cn_e3_col:
            ld (#7682), a
            ld a, (#7686)
            ld hl, asm_1_289_n_cn_r
            cp (hl)
            jr c, asm_1_289_n_cn_e3_row
            xor a
asm_1_289_n_cn_e3_row:
            ld (#7683), a
            ret

; a printable character (B): into the page, on the screen if in front, the column on. The page
; and screen pointers are worked out at the first character after the cursor moved (cn_pv 0),
; then just stepped on - a run of characters costs the 8 screen bytes each, not a sum each
asm_1_289_n_cn_print:
            ld a, (asm_1_289_n_cn_pv)
            or a
            jr nz, asm_1_289_n_cn_pr_have
            ld a, (#7683)
            call asm_1_289_n_cn_rowa
            ld a, (#7682)
            ld e, a
            ld d, 0
            add hl, de
            ld (asm_1_289_n_cn_pp), hl
            ld a, (asm_1_289_n_cn_front)
            or a
            jr z, asm_1_289_n_cn_pr_set
            ld a, (#7682)
            ld d, a
            ld a, (#7683)
            ld e, a
            push bc                 ; (B: the character)
            call asm_1_289_n_cn_scr
            pop bc
            ld (asm_1_289_n_cn_sp), hl
asm_1_289_n_cn_pr_set:
            ld a, 1
            ld (asm_1_289_n_cn_pv), a
asm_1_289_n_cn_pr_have:
            ld hl, (asm_1_289_n_cn_pp)          ; the page
            ld (hl), b
            inc hl
            ld (asm_1_289_n_cn_pp), hl
            ld a, (asm_1_289_n_cn_front)
            or a
            jr z, asm_1_289_n_cn_pr_adv
            ld hl, (asm_1_289_n_cn_sp)          ; the screen
            push hl
            ld a, b
            call asm_1_289_n_cn_glyph8
            pop hl
            call asm_1_289_n_cn_next
            ld (asm_1_289_n_cn_sp), hl
asm_1_289_n_cn_pr_adv:
            ld hl, #7682
            inc (hl)
            ld a, (hl)
            ld hl, asm_1_289_n_cn_c
            cp (hl)
            ret c
            xor a                   ; past the last column: the next row
            ld (#7682), a
            ld (asm_1_289_n_cn_pv), a
; a line feed: the next row, or the page (and the screen) scroll
asm_1_289_n_cn_nl:
            ld a, (#7683)
            inc a
            ld hl, asm_1_289_n_cn_r
            cp (hl)
            jr nc, asm_1_289_n_cn_scroll
            ld (#7683), a
            ret
asm_1_289_n_cn_scroll:
            ld a, (#7684)           ; the ring's top row moves on (no copy)
            inc a
            cp (hl)
            jr c, asm_1_289_n_cn_sc_top
            xor a
asm_1_289_n_cn_sc_top:
            ld (#7684), a
            ld a, (asm_1_289_n_cn_r)
            dec a
            call asm_1_289_n_cn_rowa            ; the new last row cleared (the old top row: kept first)
            IF asm_1_289_n_CN_SB
            push hl
            call asm_1_289_n_cn_hput
            pop hl
            ENDIF
            ld a, (asm_1_289_n_cn_c)
            ld b, a
asm_1_289_n_cn_sc_cl:
            ld (hl), ' '
            inc hl
            djnz asm_1_289_n_cn_sc_cl
            ld a, (asm_1_289_n_cn_front)
            or a
            ret z
            ld a, (v9_on)           ; the V9990: its top row a row on (its scroll register)
            or a
            jr z, asm_1_289_n_cn_sc_cpc
            ld hl, v9_tr
            inc (hl)
            ld a, (hl)
            call v9_top
            ld a, (asm_1_289_n_cn_r)
            dec a
            ld e, a
            jr asm_1_289_n_cn_sc_clr
asm_1_289_n_cn_sc_cpc:
            ld hl, (var_hyp_sco)          ; the screen: its start a row on (R12, R13), the new last row
            ld de, (var_hyp_scc)          ; cleared, the status strip again (it went off the top)
            add hl, de
            ld a, h
            and #07
            ld h, a
            ld (var_hyp_sco), hl
            call asm_1_289_n_cn_crtc
            ld a, (asm_1_289_n_cn_r)
            dec a
            ld e, a
asm_1_289_n_cn_sc_clr:                          ; E = a screen row: cleared, then the status strip again
            ld a, (v9_on)
            or a
            jr z, asm_1_289_n_cn_sc_c0
            ld a, (v9_tr)           ; the V9990: that row, and those under the console to the
            add a, e                ; screen's last (26: 26.5 shown) - the ring's old rows
            call v9_clrow
            ld a, (asm_1_289_n_cn_r)
asm_1_289_n_cn_sc_v9:
            cp 27
            jp nc, asm_1_289_n_cn_strip
            push af
            ld hl, v9_tr
            add a, (hl)
            call v9_clrow
            pop af
            inc a
            jr asm_1_289_n_cn_sc_v9
asm_1_289_n_cn_sc_c0:
            ld d, 0
            call asm_1_289_n_cn_scr
            ld b, 8
asm_1_289_n_cn_sc_ln:
            push bc
            push hl
            ld a, (var_hyp_scc)
            ld b, a
asm_1_289_n_cn_sc_b:
            ld (hl), 0
            call asm_1_289_n_cn_next
            djnz asm_1_289_n_cn_sc_b
            pop hl
            ld a, h
            add a, 8
            ld h, a
            pop bc
            djnz asm_1_289_n_cn_sc_ln
            jp asm_1_289_n_cn_strip

; ESC I (reverse line feed): the row before, or on the top row the page (and the screen) scroll
; back: the ring's top row a row back, the new top row cleared; on the screen its start a row
; back (R12, R13) and the new top row cleared - the line feed's scroll the other way
asm_1_289_n_cn_rev:
            ld a, (#7683)
            or a
            jr z, asm_1_289_n_cn_rv_sc
            dec a
            ld (#7683), a
            ret
asm_1_289_n_cn_rv_sc:
            ld a, (#7684)
            or a
            jr nz, asm_1_289_n_cn_rv_top
            ld a, (asm_1_289_n_cn_r)
asm_1_289_n_cn_rv_top:
            dec a
            ld (#7684), a
            xor a
            call asm_1_289_n_cn_rowa            ; (row 0 of the page now)
            ld a, (asm_1_289_n_cn_c)
            ld b, a
asm_1_289_n_cn_rv_cl:
            ld (hl), ' '
            inc hl
            djnz asm_1_289_n_cn_rv_cl
            ld a, (asm_1_289_n_cn_front)
            or a
            ret z
            ld a, (v9_on)           ; the V9990: its top row a row back
            or a
            jr z, asm_1_289_n_cn_rv_cpc
            ld hl, v9_tr
            dec (hl)
            ld a, (hl)
            call v9_top
            ld e, 0
            jp asm_1_289_n_cn_sc_clr
asm_1_289_n_cn_rv_cpc:
            ld hl, (var_hyp_sco)
            ld de, (var_hyp_scc)
            or a
            sbc hl, de
            ld a, h
            and #07
            ld h, a
            ld (var_hyp_sco), hl
            call asm_1_289_n_cn_crtc
            ld e, 0
            jp asm_1_289_n_cn_sc_clr

; ESC K the row from the cursor on cleared, J the rest of the page too, l the whole row, o the
; row up to the cursor, d the page up to it; M the cursor's row deleted (those below up a row, a
; blank one at the end), L a blank one put in (those below down, the last gone) - the column 0.
; The page changed first, then its rows drawn again on the screen when in front
asm_1_289_n_cn_eol:
            ld a, (asm_1_289_n_cn_c)
            ld hl, #7682
            sub (hl)
            ld b, a
            ld d, (hl)
            ld a, (#7683)
            ld e, a
            jp asm_1_289_n_cn_wipen
asm_1_289_n_cn_eos:
            call asm_1_289_n_cn_eol
            ld a, (#7683)
asm_1_289_n_cn_eos_lp:
            inc a
            ld hl, asm_1_289_n_cn_r
            cp (hl)
            ret nc
            push af
            ld e, a
            call asm_1_289_n_cn_wrow
            pop af
            jr asm_1_289_n_cn_eos_lp
asm_1_289_n_cn_eln:
            ld a, (#7683)
            ld e, a
            jp asm_1_289_n_cn_wrow
asm_1_289_n_cn_sol:
            ld a, (#7682)
            inc a
            ld b, a
            ld d, 0
            ld a, (#7683)
            ld e, a
            jp asm_1_289_n_cn_wipen
asm_1_289_n_cn_sos:
            call asm_1_289_n_cn_sol
            ld a, (#7683)
asm_1_289_n_cn_sos_lp:
            or a
            ret z
            dec a
            push af
            ld e, a
            call asm_1_289_n_cn_wrow
            pop af
            jr asm_1_289_n_cn_sos_lp
asm_1_289_n_cn_dell:
            xor a
            ld (#7682), a
            ld a, (#7683)
            ld b, a                 ; B: the row filled from the one below
asm_1_289_n_cn_dl_lp:
            ld a, (asm_1_289_n_cn_r)
            dec a
            cp b
            jr z, asm_1_289_n_cn_dl_end
            ld c, b
            inc c
            ld a, b
            push bc
            call asm_1_289_n_cn_cpr
            pop bc
            inc b
            jr asm_1_289_n_cn_dl_lp
asm_1_289_n_cn_dl_end:
            ld e, b
            call asm_1_289_n_cn_wrow            ; the last row blank
            ld a, (asm_1_289_n_cn_r)
            dec a
            ld c, a
            ld a, (#7683)
            jr asm_1_289_n_cn_redr
asm_1_289_n_cn_insl:
            xor a
            ld (#7682), a
            ld a, (asm_1_289_n_cn_r)
            dec a
            ld b, a                 ; B: the row filled from the one above
asm_1_289_n_cn_il_lp:
            ld a, (#7683)
            cp b
            jr z, asm_1_289_n_cn_il_end
            ld c, b
            dec c
            ld a, b
            push bc
            call asm_1_289_n_cn_cpr
            pop bc
            dec b
            jr asm_1_289_n_cn_il_lp
asm_1_289_n_cn_il_end:
            ld e, b
            call asm_1_289_n_cn_wrow            ; the cursor's row blank
            ld a, (asm_1_289_n_cn_r)
            ld c, a
            ld a, (#7683)
            inc a
; cn_redr: rows A to C - 1 drawn again from the page
asm_1_289_n_cn_redr:
            cp c
            ret nc
            push af
            push bc
            ld e, a
            ld d, 0
            ld a, (asm_1_289_n_cn_c)
            ld b, a
            call asm_1_289_n_cn_drwn
            pop bc
            pop af
            inc a
            jr asm_1_289_n_cn_redr
; cn_cpr: the page's row C copied to its row A
asm_1_289_n_cn_cpr:
            push af
            ld a, c
            call asm_1_289_n_cn_rowa
            pop af
            push hl
            call asm_1_289_n_cn_rowa
            ex de, hl
            pop hl
            ld a, (asm_1_289_n_cn_c)
            ld c, a
            ld b, 0
            ldir
            ret
; cn_wrow: row E blank; cn_wipen: B characters of row E from column D blank (B > 0) - in the page,
; then drawn (cn_drwn: B characters of row E from column D, from the page, when in front)
asm_1_289_n_cn_wrow:
            ld d, 0
            ld a, (asm_1_289_n_cn_c)
            ld b, a
asm_1_289_n_cn_wipen:
            push de
            push bc
            ld a, e
            call asm_1_289_n_cn_rowa
            pop bc
            pop de
            push bc
            ld a, l
            add a, d
            ld l, a
            jr nc, asm_1_289_n_cn_wn_lp
            inc h
asm_1_289_n_cn_wn_lp:
            ld (hl), ' '
            inc hl
            djnz asm_1_289_n_cn_wn_lp
            pop bc
asm_1_289_n_cn_drwn:
            ld a, (asm_1_289_n_cn_front)
            or a
            ret z
            push de
            push bc
            ld a, e
            call asm_1_289_n_cn_rowa
            pop bc
            pop de
            ld a, l
            add a, d
            ld l, a
            jr nc, asm_1_289_n_cn_dw_p
            inc h
asm_1_289_n_cn_dw_p:                            ; the screen address worked out once, then stepped on (as
            push hl                 ; cn_print: a sum each character was a fifth of the time
            push bc                 ; a screen of text took - ESC K's)
            call asm_1_289_n_cn_scr
            pop bc
            pop de                  ; DE: the page's characters, HL the screen
asm_1_289_n_cn_dw_lp:
            ld a, (de)
            inc de
            push hl
            push de
            push bc
            call asm_1_289_n_cn_glyph8
            pop bc
            pop de
            pop hl
            call asm_1_289_n_cn_next
            djnz asm_1_289_n_cn_dw_lp
            ret

; ESC E: the page cleared, column, row and ring back to 0; the screen too if in front (written,
; not copied: the Library: ROM build may have the keyword ROM over it for reads)
asm_1_289_n_cn_clear:
            ld hl, #7700
            ld de, #7701
            ld (hl), ' '
            ld bc, 2047
            ldir
            xor a
            ld (#7682), a
            ld (#7683), a
            ld (#7684), a
            ld a, (asm_1_289_n_cn_front)
            or a
            ret z
            ld hl, 0
            ld (var_hyp_sco), hl
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen)
            call asm_1_289_n_cn_crtc
            ld a, (v9_on)           ; the V9990: its top row 0, its ring cleared
            or a
            jr z, asm_1_289_n_cn_cl_cpc
            xor a
            ld (v9_tr), a
            call v9_top
            call v9_clrall
            jr asm_1_289_n_cn_strip
asm_1_289_n_cn_cl_cpc:
            xor a
            ld hl, #C000
            ld c, #40
asm_1_289_n_cn_cl_l:
            ld b, 0
asm_1_289_n_cn_cl_b:
            ld (hl), a
            inc hl
            djnz asm_1_289_n_cn_cl_b
            dec c
            jr nz, asm_1_289_n_cn_cl_l
; cn_strip: MODE S (the screen wider than the console): the status strip's 4 characters (#F68A)
; at the top of the columns right of the console
asm_1_289_n_cn_strip:
            ld a, (asm_1_289_n_cn_front)
            or a
            ret z
            ld a, (asm_1_289_n_cn_c)
            ld d, a
            ld a, (var_hyp_scc)
            cp d
            ret z
            ret c
            ld e, 0
            ld hl, #768A
            ld b, 4
asm_1_289_n_cn_st_lp:
            ld a, (hl)
            push hl
            push de
            push bc
            call asm_1_289_n_cn_glyph
            pop bc
            pop de
            pop hl
            inc hl
            inc d
            djnz asm_1_289_n_cn_st_lp
            jp asm_1_289_n_cn_net                       ; then the network indicator, two rows down

; cn_net: the network indicator - the status strip's row 2 (row 1 left blank under [1]). 'N' when
; the network's up and idle; it blinks N / blank while there's traffic (nta, counted down by the
; 0.5s cursor-flash tick); '-' when the network's off. The cell is system-wide (not a slot's), so
; its state is in class vars (ntu / nta / ntb), reachable from the NET service's block too
asm_1_289_n_cn_net:
            ld a, (asm_1_289_n_cn_front)
            or a
            ret z
            ld a, (asm_1_289_n_cn_c)
            ld d, a
            ld a, (var_hyp_scc)
            cp d
            ret z
            ret c
            ld a, (var_hyp_ntu)
            or a
            jr z, asm_1_289_n_cn_net_off                ; the network's off: '-'
            ld a, (var_hyp_nta)                   ; up: steady 'N', or blank on the odd blink while busy
            or a
            ld a, 78
            jr z, asm_1_289_n_cn_net_put
            ld a, (var_hyp_ntb)
            and 1
            ld a, 78
            jr z, asm_1_289_n_cn_net_put
            ld a, 32
            jr asm_1_289_n_cn_net_put
asm_1_289_n_cn_net_off:
            ld a, 45
asm_1_289_n_cn_net_put:
            ld (asm_1_289_n_cn_nbuf + 1), a
            ld hl, asm_1_289_n_cn_nbuf
            ld a, (asm_1_289_n_cn_c)
            ld d, a                         ; the first strip column
            ld e, 2                         ; row 2 (row 1 blank, under [1] at row 0)
            ld b, 4
asm_1_289_n_cn_net_lp:
            ld a, (hl)
            push hl
            push de
            push bc
            call asm_1_289_n_cn_glyph
            pop bc
            pop de
            pop hl
            inc hl
            inc d
            djnz asm_1_289_n_cn_net_lp
            ret
asm_1_289_n_cn_nbuf:    db 91, 78, 93, 32               ; "[N] "; +1 is overwritten with N / - / blank

; cn_crtc: the screen's start (sco, bytes) to the CRTC: R12 = #30 + its words' high 2 bits, R13
; the low 8 (#C000, MA10 / MA11 clear: kept within 2K, never the carry into the next 16K)
asm_1_289_n_cn_crtc:
            ld hl, (var_hyp_sco)
            srl h
            rr l
            ld a, h
            and 3
            or #30
            ld bc, #BC0C
            out (c), c
            inc b
            out (c), a
            ld bc, #BC0D
            out (c), c
            inc b
            out (c), l
            ret

; cn_rowa: A = row of the screen -> HL = its row in the page ring (#7700 + ((top + A) mod rows)
; * columns)
asm_1_289_n_cn_rowa:
            ld hl, #7684
            add a, (hl)
            ld hl, asm_1_289_n_cn_r
            cp (hl)
            jr c, asm_1_289_n_cn_ra_in
            sub (hl)
asm_1_289_n_cn_ra_in:
            ld e, a
            ld a, (asm_1_289_n_cn_c)
            call asm_1_289_n_cn_mul
            ld de, #7700
            add hl, de
            ret

; cn_mul: HL = A * E (BC kept; D = 0 after)
asm_1_289_n_cn_mul:
            push bc
            ld hl, 0
            ld d, 0
            ld b, 8
asm_1_289_n_cn_mu_lp:
            add hl, hl
            rlca
            jr nc, asm_1_289_n_cn_mu_n
            add hl, de
asm_1_289_n_cn_mu_n:
            djnz asm_1_289_n_cn_mu_lp
            pop bc
            ret

; cn_next: HL = the next screen byte: + 1 within its 2K line block (BC kept)
asm_1_289_n_cn_next:
            ld a, (v9_on)           ; (the V9990: the next column)
            or a
            jr z, asm_1_289_n_cn_nx_cpc
            inc l
            ret
asm_1_289_n_cn_nx_cpc:
            inc l
            ret nz
            ld a, h
            inc a
            and #07
            push bc
            ld c, a
            ld a, h
            and #F8
            or c
            ld h, a
            pop bc
            ret

; cn_glyph: A = character, D = column, E = row: drawn (cn_show)
asm_1_289_n_cn_glyph:
            push af
            call asm_1_289_n_cn_scr
            pop af
; cn_glyph8: A = character, HL = its screen address: its 8 bytes into screen memory (mode 2, pen
; 1 on paper 0), one per pixel line (#800 apart; unrolled)
asm_1_289_n_cn_glyph8:
            ld e, a
            ld a, (v9_on)           ; (the V9990: H the ring's row, L the column - V9.cls)
            or a
            ld a, e
            jp nz, v9_cell
            sub 32
            cp 96
            jr c, asm_1_289_n_cn_gl_ok
            ld a, '?' - 32
asm_1_289_n_cn_gl_ok:
            push hl
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, 62208 - #8000   ; (the bank's page 3 in the window: FONT - #C000 + #4000)
            add hl, de
            ex de, hl               ; DE = its matrix
            pop hl
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            ld a, (de)
            ld (hl), a
            ret
; cn_scr: D = column, E = row -> HL = the screen address: the screen's start (sco) + row *
; columns (scc) + column, within each 2K line block, at #C000
asm_1_289_n_cn_scr:
            ld a, (v9_on)           ; the V9990: H = the ring's row (its top row on), L = the column
            or a
            jr z, asm_1_289_n_cn_scr_c
            ld a, (v9_tr)
            add a, e
            and 31
            ld h, a
            ld l, d
            ret
asm_1_289_n_cn_scr_c:
            push de
            ld a, (var_hyp_scc)
            call asm_1_289_n_cn_mul
            pop de
            ld c, d
            ld b, 0
            add hl, bc
            ld bc, (var_hyp_sco)
            add hl, bc
            ld a, h
            and #07
            or #C0
            ld h, a
            ret
asm_1_289_n_cn_cuxor:                           ; the cursor's underline XORed at cn_ca, on <-> off
            ld a, (var_hyp_ccu)
            xor 1
            ld (var_hyp_ccu), a
            ld hl, (asm_1_289_n_cn_ca)
            ld a, (v9_on)           ; (the V9990: its cell's last line XORed)
            or a
            jp nz, v9_xcur
            ld a, (hl)
            cpl
            ld (hl), a
            ret
asm_1_289_n_cn_was:     db 0
asm_1_289_n_cn_ca:      dw 0
asm_1_289_n_cn_front:   db 0
asm_1_289_n_cn_c:       db 80                   ; the slot's columns, rows
asm_1_289_n_cn_r:       db 25
asm_1_289_n_cn_pv:      db 0                    ; cn_pp / cn_sp valid (0: the cursor moved)
asm_1_289_n_cn_pp:      dw 0                    ; the page byte for the next character
asm_1_289_n_cn_sp:      dw 0                    ; its screen address
asm_1_289_n_cn_left:    dw 0
asm_1_289_n_cn_ptr:     dw 0
            IF asm_1_289_n_CN_SB
asm_1_289_n_cn_pg:      dw 0                    ; the slot's page 3 setting (pg)
asm_1_289_n_cn_h1:      dw 0                    ; cn_hcp: from (its setting, address), to, 8-byte runs left
asm_1_289_n_cn_hs:      dw 0
asm_1_289_n_cn_h2:      dw 0
asm_1_289_n_cn_hd:      dw 0
asm_1_289_n_cn_hn:      db 0
            ENDIF
asm_1_289_n_cn_end:
			ret			; end of #asm

asm_1_1496_n:		; #asm, Hyp.cls line 1496 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld a, (v9_on)           ; the V9990: a cell at a time (H the ring's row, L the column)
            or a
            jr z, asm_1_1496_n_sy_cpc
            ld a, (var_hyp_say_n)
            or a
            jr z, asm_1_1496_n_sy_v9e
            ld b, a
            ld a, (var_hyp_say_row)
            ld hl, v9_tr
            add a, (hl)
            and 31
            ld d, a
            ld a, (var_hyp_say_col)
            ld e, a
            ld hl, (var_hyp_say_p)
asm_1_1496_n_sy_v9lp:
            ld a, e
            cp 80
            jr nc, asm_1_1496_n_sy_v9e
            ld a, (hl)
            inc hl
            push hl
            push de
            push bc
            ex de, hl
            call v9_cell
            pop bc
            pop de
            pop hl
            inc e
            djnz asm_1_1496_n_sy_v9lp
asm_1_1496_n_sy_v9e:
            ld sp, (var_hyp_hsp)
            jp asm_1_1496_n_sy_end
asm_1_1496_n_sy_cpc:
            ld bc, (var_hyp_hps)          ; the hypervisor's page in the window: the font
            out (c), c
            ld hl, (var_hyp_sco)          ; the screen's start (TOP is shown in MODE 2: 80 columns)
            ld (asm_1_1496_n_sy_off), hl
            ld hl, (var_hyp_say_p)
            ld a, (var_hyp_say_n)
            ld b, a
            ld a, (var_hyp_say_col)
            ld d, a
            ld a, (var_hyp_say_row)
            ld e, a
            inc b
asm_1_1496_n_sy_lp:
            dec b
            jr z, asm_1_1496_n_sy_done
            ld a, d
            cp 80
            jr nc, asm_1_1496_n_sy_done
            ld a, (hl)
            inc hl
            push hl
            push bc
            push de
            sub 32                  ; the character's matrix
            cp 96
            jr c, asm_1_1496_n_sy_ok
            ld a, '?' - 32
asm_1_1496_n_sy_ok:
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            ld bc, #4000 + 4096  ; (the hypervisor's page in the window)
            add hl, bc
            push hl
            ld l, e                 ; its screen address: start + row * 80 + column, in 2K
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            push hl
            add hl, hl
            add hl, hl
            pop bc
            add hl, bc
            ld c, d
            ld b, 0
            add hl, bc
            ld bc, (asm_1_1496_n_sy_off)
            add hl, bc
            ld a, h
            and #07
            or #C0
            ld h, a
            pop de
            ld b, 8
asm_1_1496_n_sy_ln:
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            djnz asm_1_1496_n_sy_ln
            pop de
            pop bc
            pop hl
            inc d
            jr asm_1_1496_n_sy_lp
asm_1_1496_n_sy_done:
            ld bc, (ntc_rampt)
            out (c), c
            ld sp, (var_hyp_hsp)
            jr asm_1_1496_n_sy_end
asm_1_1496_n_sy_off:     dw 0
asm_1_1496_n_sy_end:
			ret			; end of #asm

asm_1_1625_n:		; #asm, Hyp.cls line 1625 (normal)
            ld (var_hyp_hsp), sp          ; (the real stack: SP is the thread)
            ld sp, (ntc_csp)
            xor a
            ld (var_hyp_ccu), a           ; (the screen cleared: no cursor on it)
            ld a, (var_hyp_scr_m)
            cp 6
            jr c, asm_1_1625_n_sm_ok
            xor a
asm_1_1625_n_sm_ok:
            ld l, a                 ; the mode's row of the table (6 bytes)
            add a, a
            add a, l
            add a, a
            ld e, a
            ld d, 0
            ld hl, asm_1_1625_n_sm_tab
            ld a, (v9_on)           ; (the V9990: its modes - 84 columns at most, 26 rows)
            or a
            jr z, asm_1_1625_n_sm_tc
            ld hl, asm_1_1625_n_sm_v9tab
asm_1_1625_n_sm_tc:
            add hl, de
            ld a, (var_hyp_scr_k)
            or a
            jr z, asm_1_1625_n_sm_cols
            dec a
            jr z, asm_1_1625_n_sm_rows
            push hl                 ; 2: the screen
            ld e, (hl)              ; its columns
            ld d, 0
            ld (var_hyp_scc), de
            srl e
            ld (var_hyp_scw), de
            ld hl, 0
            ld (var_hyp_sco), hl
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen)
            pop hl
            inc hl
            inc hl                  ; R1, R2, R6, R7
            di
            ld a, (v9_on)           ; the V9990: the CPC's CRTC and screen as they are (its table's
            or a                    ; R1, R2, R7 are 0s: written, the CRTC's sync stopped - no
            jr nz, asm_1_1625_n_sm_v9s           ; frame flyback, no interrupts)
            ld d, 1
            call asm_1_1625_n_sm_crtc
            ld d, 2
            call asm_1_1625_n_sm_crtc
            ld d, 6
            call asm_1_1625_n_sm_crtc
            ld d, 7
            call asm_1_1625_n_sm_crtc
            ld hl, asm_1_1625_n_sm_start         ; R12, R13: #C000
            ld d, 12
            call asm_1_1625_n_sm_crtc
            ld d, 13
            call asm_1_1625_n_sm_crtc
            xor a                   ; cleared (written, not copied: the Library: ROM build may
            ld hl, #C000            ; have the keyword ROM over it for reads)
            ld c, #40
asm_1_1625_n_sm_cl:
            ld b, 0
asm_1_1625_n_sm_cl1:
            ld (hl), a
            inc hl
            djnz asm_1_1625_n_sm_cl1
            dec c
            jr nz, asm_1_1625_n_sm_cl
            ld a, (v9_on)           ; the V9990: the text in the middle, its top row 0, cleared
            or a
            jr z, asm_1_1625_n_sm_cl_e
asm_1_1625_n_sm_v9s:
            ld a, (var_hyp_scc)
            call v9_cols
            xor a
            ld (v9_tr), a
            call v9_top
            call v9_clrall
asm_1_1625_n_sm_cl_e:
            ld hl, 0
            jr asm_1_1625_n_sm_res
asm_1_1625_n_sm_cols:
            ld a, (hl)              ; the console's: the screen's, less the status strip's 4 (S)
            inc hl
            sub (hl)
            jr asm_1_1625_n_sm_a
asm_1_1625_n_sm_rows:
            inc hl
            inc hl
            inc hl
            inc hl
            ld a, (hl)
asm_1_1625_n_sm_a:
            ld l, a
            ld h, 0
asm_1_1625_n_sm_res:
            ld (var_hyp_scr_scr), hl
            ld sp, (var_hyp_hsp)
            ret                     ; (on with the thread)
asm_1_1625_n_sm_crtc:                            ; CRTC register D = (HL), HL on
            ld bc, #BC00
            out (c), d
            ld b, #BD
            ld a, (hl)
            out (c), a
            inc hl
            ret
asm_1_1625_n_sm_start:   db #30, 0
; columns, the status strip's, R1 (words a row), R2 (horizontal sync), R6 (rows), R7 (vertical sync)
asm_1_1625_n_sm_tab:     db 80, 0, 40, 46, 25, 30
            db 84, 4, 42, 47, 24, 30
            db 88, 0, 44, 48, 23, 29
            db 96, 0, 48, 50, 21, 28
            db 64, 0, 32, 42, 32, 34
            db 84, 0, 42, 47, 24, 30
; the V9990's (V9.cls: 512 pixels, 26 rows shown): the columns, the strip's, (R1, R2 unused), rows
asm_1_1625_n_sm_v9tab:   db 80, 0, 0, 0, 25, 0   ; MODE 2
            db 84, 4, 0, 0, 24, 0   ; MODE S
            db 80, 0, 0, 0, 23, 0   ; MODE W (88 x 23 on the CPC's screen)
            db 80, 0, 0, 0, 21, 0   ; MODE UW (96 x 21)
            db 64, 0, 0, 0, 26, 0   ; MODE P (64 x 32)
            db 84, 0, 0, 0, 24, 0   ; MODE F
			ret			; end of #asm

asm_1_1755_n:		; #asm, Hyp.cls line 1755 (normal)
            ld a, (v9_on)           ; the V9990: its palette 0 and 1 too (its border is palette 0)
            or a
            jr z, asm_1_1755_n_ik_v9n
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld a, (var_hyp_inks_p)
            or a
            jr nz, asm_1_1755_n_ik_vp
            ld a, 2                 ; (blue + 1)
asm_1_1755_n_ik_vp:      dec a
            ld d, a
            ld a, (var_hyp_inks_q)
            or a
            jr nz, asm_1_1755_n_ik_vq
            ld a, 25                ; (bright yellow + 1)
asm_1_1755_n_ik_vq:      dec a
            ld e, a
            call v9_pal
            ld sp, (var_hyp_hsp)
asm_1_1755_n_ik_v9n:
    IFNDEF NTC_ZXN
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld a, (var_hyp_inks_p)
            or a
            jr nz, asm_1_1755_n_ik_p
            ld a, 2                 ; (blue + 1)
asm_1_1755_n_ik_p:       dec a
            ld b, a
            ld c, a
            xor a                   ; ink 0
            call #BC32              ; SCR SET INK
            di
            ld a, (var_hyp_inks_q)
            or a
            jr nz, asm_1_1755_n_ik_q
            ld a, 25                ; (bright yellow + 1)
asm_1_1755_n_ik_q:       dec a
            ld b, a
            ld c, a
            ld a, 1                 ; ink 1
            call #BC32
            di
            ld a, (var_hyp_inks_b)
            or a
            jr nz, asm_1_1755_n_ik_b
            ld a, 2
asm_1_1755_n_ik_b:       dec a
            ld b, a
            ld c, a
            call #BC38              ; SCR SET BORDER
            di
            ld sp, (var_hyp_hsp)
    ENDIF
			ret			; end of #asm

asm_1_1816_n:		; #asm, Hyp.cls line 1816 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            call #BB42              ; KM GET DELAY: H the start delay, L the repeat
            di
            ld a, h
            call asm_1_1816_n_kr_mul
            ld h, a
            ld a, l
            call asm_1_1816_n_kr_mul
            ld l, a
            call #BB3F              ; KM SET DELAY
            di
            ld sp, (var_hyp_hsp)
            jr asm_1_1816_n_kr_end
asm_1_1816_n_kr_mul:                             ; A = A x f, 255 at most (0: 256 to the firmware - kept)
            or a
            ret z
            push hl
            ld e, a
            ld d, 0
            ld hl, 0
            ld a, (var_hyp_keyrep_f)
            ld b, a
asm_1_1816_n_kr_lp:
            add hl, de
            djnz asm_1_1816_n_kr_lp
            ld a, h
            or a
            ld a, l
            pop hl
            ret z
            ld a, 255
            ret
asm_1_1816_n_kr_end:
			ret			; end of #asm

asm_1_1965_n:		; #asm, Hyp.cls line 1965 (normal)
            ld (var_hyp_sps), sp
            ld sp, (ntc_csp)
            di
            ld hl, (var_hyp_go_setting)
            ld (var_hyp_gset), hl
asm_1_1965_n_go_again:
            push ix
            push iy
            db #08                  ; ex af, af': the alternate registers kept - the
            exx                     ; firmware's (BC' = its ROM / mode setting)
            push af
            push bc
            push de
            push hl
            exx
            db #08
            ld hl, asm_1_1965_n_go_back
            push hl
            ld (ntc_bk_sp), sp
            ld a, (var_hyp_rclr)
            ld e, a
            ld a, (var_hyp_ra)
            ld hl, (var_hyp_rhl)
            ld bc, (var_hyp_gset)
            jp ntc_bk_out
asm_1_1965_n_go_back:
            ld (var_hyp_rcnt), ix         ; the characters it collected (a slot: IX)
            ld (var_hyp_rsrc), hl         ; who called: its slot (0: the kernel)
            db #08
            exx
            pop hl
            pop de
            pop bc
            pop af
            exx
            db #08
            pop iy
            pop ix
            push af
            push bc
            ld bc, (ntc_rampt)      ; the window's page back
            out (c), c
            pop bc
            pop af
            jr c, asm_1_1965_n_go_far
            push de                 ; a visit: the firmware's interrupt handler (the keys, the
            rst #38                 ; frame's events, the clock)
            di
            pop de
            dec d                   ; the interrupts it didn't see (the kernel counted D)
            jr z, asm_1_1965_n_go_vis
            jp m, asm_1_1965_n_go_vis
            push de
            call #BD0D              ; KL TIME PLEASE: DEHL
            di
            pop bc
            ld c, b
            ld b, 0
            add hl, bc
            jr nc, asm_1_1965_n_go_tm
            inc de
asm_1_1965_n_go_tm:
            call #BD10              ; KL TIME SET
            di
asm_1_1965_n_go_vis:
            xor a
            ld (var_hyp_rclr), a
            ld hl, (var_hyp_rsrc)         ; back to the visitor - unless an interrupt class is due (BASIC
            ld a, (ntc_isldue)      ; runs it, then Go again)
            or a
            jr nz, asm_1_1965_n_go_int
            add hl, hl
            ld de, (var_hyp_gsg)
            add hl, de
            ld a, (hl)
            inc hl
            ld h, (hl)
            ld l, a
            ld (var_hyp_gset), hl
            jp asm_1_1965_n_go_again
asm_1_1965_n_go_int:
            ld hl, 0
            jr asm_1_1965_n_go_end
asm_1_1965_n_go_far:
            ld (var_hyp_rfn), a
            ld (var_hyp_rde), de
            ld hl, 1
asm_1_1965_n_go_end:
            ld (var_hyp_go_go), hl
            di
            ld sp, (var_hyp_sps)
			ret			; end of #asm

fn_hyp_info:		; function info (asm keyword), Hyp.cls line 2080
            pop hl
            ld a, (hl)
            ld hl, fn_hyp_info_hi_p0
            or a
            jr z, fn_hyp_info_in_e
            ld hl, fn_hyp_info_hi_p0e - fn_hyp_info_hi_p0
            dec a
            jr z, fn_hyp_info_in_e
            ld hl, fn_hyp_info_sb_img
            dec a
            jr z, fn_hyp_info_in_e
            ld hl, fn_hyp_info_sb_end - fn_hyp_info_sb_start
            dec a
            jr z, fn_hyp_info_in_e
            ld hl, fn_hyp_info_sb_init
fn_hyp_info_in_e:
            ex de, hl
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
            ret

			ret			; end of #asm

asm_1_2796_n:		; #asm, Hyp.cls line 2796 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld a, (var_hyp_vdu_on)
            or a
            jr z, asm_1_2796_n_vd_off
            ld a, (v9_on)           ; (the V9990's picture off: the CPC's screen has the words now)
            or a
            call nz, v9_off
            call #BB54              ; TXT VDU ENABLE
            jr asm_1_2796_n_vd_done
asm_1_2796_n_vd_off:
            call #BB57              ; TXT VDU DISABLE
asm_1_2796_n_vd_done:
            di
            ld sp, (var_hyp_hsp)
			ret			; end of #asm

asm_1_2832_n:		; #asm, Hyp.cls line 2832 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld (asm_1_2832_n_fl_ix), ix
            ld (asm_1_2832_n_fl_iy), iy
            ld a, 255
            ld (asm_1_2832_n_fl_res), a
            ld a, (var_hyp_filecall_slot)
            ld (asm_1_2832_n_fl_slot), a
            ld a, (var_hyp_filecall_f)
            cp 99
            jp z, asm_1_2832_n_fl_inst
            IF NTC_ROMLIB = 0
; the RAM discs' driver (RAMDISC.CYB's, in a page of its own at #4000) sees the call first:
; carry - it was one of its drives' (HL the answer), else on to the disc ROM. It gets IX = the
; call (f, fcb, slot, setting, dma, drive, buf; 100-105: drive = the hypervisor's drive), at
; #4003 a jump to fl_dx (its copies: it runs in the window, so can't switch it itself), at
; #4006 its page's RAM setting
            ASSERT var_hyp_filecall_buf - var_hyp_filecall_f = 12, "FileCall's parameters, one after another"
            ld a, (var_hyp_drs + 1)
            or a
            jr z, asm_1_2832_n_fl_nodrv
            di
            ld a, (var_hyp_filecall_f)
            cp 100
            jr c, asm_1_2832_n_fl_dr_go
            cp 106
            jr nc, asm_1_2832_n_fl_dr_go
            ld hl, (var_hyp_hdr)
            ld (var_hyp_filecall_drive), hl
asm_1_2832_n_fl_dr_go:
            ld bc, (var_hyp_drs)
            out (c), c
            ld hl, asm_1_2832_n_fl_dx
            ld (#4004), hl
            ld hl, (var_hyp_drs)
            ld (#4006), hl
            ld ix, var_hyp_filecall_f
            call #4000
            jr nc, asm_1_2832_n_fl_nodrv
            ld (asm_1_2832_n_fl_res16), hl
            ld a, 1
            ld (asm_1_2832_n_fl_r16), a
            jp asm_1_2832_n_fl_done
; fl_dx - A bytes (1-128) from HL to DE through dxb: IX = HL's RAM setting, IY = DE's (0:
; main RAM, no switch); the driver's page back in the window after. HL, DE on past them
asm_1_2832_n_fl_dx:
            ld (asm_1_2832_n_fl_dxn), a
            push de
            ld de, (var_hyp_dxb)
            push ix
            pop bc
            inc b
            dec b
            jr z, asm_1_2832_n_fl_dx1
            out (c), c
asm_1_2832_n_fl_dx1:
            ld c, a
            ld b, 0
            ldir
            pop de
            push hl
            push iy
            pop bc
            inc b
            dec b
            jr z, asm_1_2832_n_fl_dx2
            out (c), c
asm_1_2832_n_fl_dx2:
            ld hl, (var_hyp_dxb)
            ld a, (asm_1_2832_n_fl_dxn)
            ld c, a
            ld b, 0
            ldir
            pop hl
            ld bc, (var_hyp_drs)
            out (c), c
            ret
asm_1_2832_n_fl_dxn:     db 0
asm_1_2832_n_fl_nodrv:
            ENDIF
            di
            ld bc, (var_hyp_hps)          ; the rest runs in the hypervisor's page (window data from
            out (c), c              ; #5300: fp_go)
            call asm_1_2832_n_fp_go
            jp asm_1_2832_n_fl_done
; 99: the window data (#5300 to fp_end: the bank image, the page code) copied from main RAM's
; own #4000-#7FFF (where the file put it) into the hypervisor's page, through buf; once, at the
; start, before anything else uses main RAM's #4000-#7FFF
asm_1_2832_n_fl_inst:
            ld hl, #5300
asm_1_2832_n_fl_in_lp:
            push hl
            ld bc, #7FC0            ; main RAM's own
            out (c), c
            ld de, (var_hyp_filecall_buf)
            ld bc, 128
            ldir
            ld bc, (var_hyp_hps)
            out (c), c
            pop de
            push de
            ld hl, (var_hyp_filecall_buf)
            ld bc, 128
            ldir
            pop hl
            ld bc, 128
            add hl, bc
            ld de, asm_1_2832_n_fp_end
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_2832_n_fl_in_lp
            xor a
            ld (asm_1_2832_n_fl_res), a
            jp asm_1_2832_n_fl_done
; ---- what the page code can't do itself (it runs in the window): switch the window to a slot's
; page and back. Each puts the hypervisor's page back in the window
asm_1_2832_n_fl_sel:                             ; the slot's page holding HL in the window: HL = there
            push de
            ld a, h
            rlca
            rlca
            and 3
            add a, 4
            ld e, a
            ld bc, (var_hyp_filecall_setting)
            ld a, c
            and #F8
            or e
            ld c, a
            out (c), c
            ld a, h
            and #3F
            or #40
            ld h, a
            pop de
            ret
asm_1_2832_n_fl_peek:                            ; A = the slot's byte at HL (BC, DE, HL kept)
            push bc
            push hl
            call asm_1_2832_n_fl_sel
            ld a, (hl)
asm_1_2832_n_fl_pk_back:
            ld bc, (var_hyp_hps)
            out (c), c
            pop hl
            pop bc
            ret
asm_1_2832_n_fl_poke:                            ; the slot's byte at HL = A (BC, DE, HL kept)
            push bc
            push hl
            push af
            call asm_1_2832_n_fl_sel
            pop af
            ld (hl), a
            jr asm_1_2832_n_fl_pk_back
asm_1_2832_n_fl_toslot:                          ; BC bytes from DE (main RAM) to the slot's HL (all in one of
            push bc                 ; its pages: fl_fits)
            call asm_1_2832_n_fl_sel
            pop bc
            ex de, hl
            ldir
            jr asm_1_2832_n_fl_blk_back
asm_1_2832_n_fl_fromslot:                        ; BC bytes from the slot's HL (in one page) to DE (main RAM)
            push bc
            call asm_1_2832_n_fl_sel
            pop bc
            ldir
asm_1_2832_n_fl_blk_back:
            ld bc, (var_hyp_hps)
            out (c), c
            ret
asm_1_2832_n_fl_done:
            di
            ld bc, (ntc_rampt)      ; the page that was in the window back
            out (c), c
            ld a, (asm_1_2832_n_fl_res)
            ld l, a
            ld h, 0
            ld a, (asm_1_2832_n_fl_r16)
            or a
            jr z, asm_1_2832_n_fl_d8
            ld hl, (asm_1_2832_n_fl_res16)
            xor a
            ld (asm_1_2832_n_fl_r16), a
asm_1_2832_n_fl_d8:
            ld (var_hyp_filecall_filecall), hl
            ld ix, (asm_1_2832_n_fl_ix)
            ld iy, (asm_1_2832_n_fl_iy)
            ld sp, (var_hyp_hsp)
            jp asm_1_2832_n_fl_exit
asm_1_2832_n_fl_ix:      dw 0
asm_1_2832_n_fl_iy:      dw 0
asm_1_2832_n_fl_res:     db 0
asm_1_2832_n_fl_r16:     db 0                    ; 1: the result is fl_res16
asm_1_2832_n_fl_res16:   dw 0
asm_1_2832_n_fl_slot:    db 0
; (main RAM: the page code calls them - no room left in the page)
asm_1_2832_n_fl_isin:                            ; Z: the file being read is this slot's, this FCB
            ld a, (var_hyp_fin)
            ld hl, asm_1_2832_n_fl_infcb
            jr asm_1_2832_n_fl_is
asm_1_2832_n_fl_isout:
            ld a, (var_hyp_fout)
            ld hl, asm_1_2832_n_fl_outfcb
asm_1_2832_n_fl_is:                              ; (its FCB: the one it was opened with - or, the first
            ld b, a                 ; call after with another, that one: a program's own copy
            ld a, (asm_1_2832_n_fl_slot)         ; of it, BBC BASIC's channels)
            cp b
            ret nz
            ld e, (hl)
            inc hl
            ld d, (hl)
            inc hl
            push hl
            call asm_1_2832_n_fl_cmpf
            pop de
            ret z
            ld a, (de)              ; (the open's FCB still: this one from now on - unless it
            xor 1                   ; is the other file's: a program reading the record it
            ret nz                  ; writes, through that file's FCB)
            push de
            ld a, (var_hyp_fin)
            ld de, (asm_1_2832_n_fl_infcb)
            call asm_1_2832_n_fl_oth
            jr z, asm_1_2832_n_fl_is_no
            ld a, (var_hyp_fout)
            ld de, (asm_1_2832_n_fl_outfcb)
            call asm_1_2832_n_fl_oth
asm_1_2832_n_fl_is_no:
            pop de
            jr nz, asm_1_2832_n_fl_is_re
            inc a                   ; (NZ: not this one)
            ret
asm_1_2832_n_fl_is_re:
            xor a
            ld (de), a
            ld hl, (var_hyp_filecall_fcb)
            ex de, hl
            dec hl
            ld (hl), d
            dec hl
            ld (hl), e
            ret
asm_1_2832_n_fl_oth:                             ; Z: the slot's file (A: fin / fout), its FCB DE the call's
            ld b, a
            ld a, (asm_1_2832_n_fl_slot)
            cp b
            ret nz
asm_1_2832_n_fl_cmpf:                            ; Z: the call's FCB is DE
            ld hl, (var_hyp_filecall_fcb)
            or a
            sbc hl, de
            ret
; fl_fcj: UniDOS's Ctrl J (the command named #8A) in the background ROMs 0-15, as KL FIND
; COMMAND looks, but a ROM named "M4 BOARD" passed over: the M4's ROM has a Ctrl J of its own
; (CALL #B906, LD HL,0, JP #0077: a restart) and, in slot 6, comes before UniDOS's in 7.
; Carry: found - C its ROM, HL its address. A, BC, DE, HL. In main RAM (not the page code: its
; page must end by #6000, where the service page's code is in the file)
asm_1_2832_n_fl_fcj:
            ld c, 0
asm_1_2832_n_fl_fj_r:
            push bc
            call #B90F              ; KL ROM SELECT: C's ROM in (B, C the old)
            di
            ld (asm_1_2832_n_fl_fj_o), bc
            pop bc
            ld a, (#C000)
            and 3
            cp 1                    ; a background ROM
            jr nz, asm_1_2832_n_fl_fj_n
            ld hl, (#C004)          ; its names
            push hl
            ld de, asm_1_2832_n_fl_m4n
            ld b, 8
asm_1_2832_n_fl_fj_m:
            ld a, (de)
            cp (hl)
            jr nz, asm_1_2832_n_fl_fj_nm
            inc hl
            inc de
            djnz asm_1_2832_n_fl_fj_m
            pop hl                  ; the M4's: passed over
            jr asm_1_2832_n_fl_fj_n
asm_1_2832_n_fl_fj_nm:
            pop hl
            ld de, #C006            ; the first name's jump
asm_1_2832_n_fl_fj_s:
            ld a, (hl)
            or a
            jr z, asm_1_2832_n_fl_fj_n           ; (the names' end)
            cp #8A
            jr z, asm_1_2832_n_fl_fj_y
asm_1_2832_n_fl_fj_k:
            ld a, (hl)              ; past this name (its last letter + #80)
            inc hl
            add a, a
            jr nc, asm_1_2832_n_fl_fj_k
            inc de
            inc de
            inc de
            jr asm_1_2832_n_fl_fj_s
asm_1_2832_n_fl_fj_y:
            push de
            push bc
            ld bc, (asm_1_2832_n_fl_fj_o)
            call #B918              ; KL ROM DESELECT
            pop bc
            pop hl
            scf
            ret
asm_1_2832_n_fl_fj_n:
            push bc
            ld bc, (asm_1_2832_n_fl_fj_o)
            call #B918
            pop bc
            inc c
            ld a, c
            cp 16
            jr c, asm_1_2832_n_fl_fj_r
            or a                    ; (NC: none)
            ret
asm_1_2832_n_fl_fj_o:    dw 0
asm_1_2832_n_fl_m4n:     db "M4 BOAR", 'D' + #80
; UniDOS's Ctrl J called from main RAM, the hypervisor's page put back in the window after it
; (fl_cjc jumps here): UniDOS switches the RAM itself - C7 for its data at #7800, then C0, not
; the setting it was called with - so the return can't be to the page code until the page is
; back. Keeps A, BC, DE, HL, IX and the flags UniDOS gives
asm_1_2832_n_fl_cjm:
            rst #18                 ; (RST 3: a far call)
            dw asm_1_2832_n_fl_cjfa
            di
            push bc
            ld bc, (var_hyp_hps)
            out (c), c
            pop bc
            ret
asm_1_2832_n_fl_cjfa:    dw 0                    ; Ctrl J's far address (fl_uni puts it here too)
            db 0
asm_1_2832_n_fl_exit:
			ret			; end of #asm

asm_1_4496_n:		; #asm, Hyp.cls line 4496 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld bc, (var_hyp_hps)          ; (the buffers: the hypervisor's page)
            out (c), c
            ld a, (var_hyp_fileshut_slot)
            ld b, a
            ld a, (var_hyp_fin)
            cp b
            jr nz, asm_1_4496_n_fs_out
            xor a
            ld (var_hyp_fin), a
            push bc
            call #BC7A              ; CAS IN CLOSE
            di
            pop bc
asm_1_4496_n_fs_out:
            ld a, (var_hyp_fout)
            cp b
            jr nz, asm_1_4496_n_fs_done
            xor a
            ld (var_hyp_fout), a
            call #BC8F              ; CAS OUT CLOSE
            di
asm_1_4496_n_fs_done:
            ld bc, (ntc_rampt)
            out (c), c
            ld sp, (var_hyp_hsp)
			ret			; end of #asm

fn_hyp_usesvc:		; sub usesvc (asm keyword), Hyp.cls line 4549
            ld hl, (ntc_rampt)
            ld (var_hyp_svp), hl
			ret			; end of #asm

asm_1_4568_n:		; #asm, Hyp.cls line 4568 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld (asm_1_4568_n_sv_ix), ix
            ld (asm_1_4568_n_sv_iy), iy
            di
            ld a, (var_hyp_svc_t)
            or a
            jr z, asm_1_4568_n_sv_inst
            ld bc, (var_hyp_svp)
            out (c), c
            call asm_1_4568_n_sv_go              ; (in the service page) A = the answer
asm_1_4568_n_sv_back:
            di
            ld l, a
            ld h, 0
            ld (var_hyp_svc_svc), hl
            ld bc, (ntc_rampt)      ; the page that was in the window back
            out (c), c
            ld ix, (asm_1_4568_n_sv_ix)
            ld iy, (asm_1_4568_n_sv_iy)
            ld sp, (var_hyp_hsp)
            jp asm_1_4568_n_sv_exit
asm_1_4568_n_sv_inst:
            ld hl, #6000
asm_1_4568_n_sv_in_lp:
            push hl
            ld bc, #7FC0            ; main RAM's own
            out (c), c
            ld de, (var_hyp_svc_buf)
            ld bc, 128
            ldir
            ld bc, (var_hyp_svp)
            out (c), c
            pop de
            push de
            ld hl, (var_hyp_svc_buf)
            ld bc, 128
            ldir
            pop hl
            ld bc, 128
            add hl, bc
            ld de, asm_1_4568_n_sv_end
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_4568_n_sv_in_lp
            xor a
            jr asm_1_4568_n_sv_back
asm_1_4568_n_sv_ix:      dw 0
asm_1_4568_n_sv_iy:      dw 0
; sv_dx - A bytes (1-128) from HL to DE through buf: IX = HL's RAM setting, IY = DE's (0: none -
; main RAM outside the window); the service page back in the window after. HL, DE on past them
asm_1_4568_n_sv_dx:
            ld (asm_1_4568_n_sv_dxn), a
            push de
            ld de, (var_hyp_svc_buf)
            push ix
            pop bc
            inc b
            dec b
            jr z, asm_1_4568_n_sv_dx1
            out (c), c
asm_1_4568_n_sv_dx1:
            ld c, a
            ld b, 0
            ldir
            pop de
            push hl
            push iy
            pop bc
            inc b
            dec b
            jr z, asm_1_4568_n_sv_dx2
            out (c), c
asm_1_4568_n_sv_dx2:
            ld hl, (var_hyp_svc_buf)
            ld a, (asm_1_4568_n_sv_dxn)
            ld c, a
            ld b, 0
            ldir
            pop hl
            ld bc, (var_hyp_svp)
            out (c), c
            ret
asm_1_4568_n_sv_dxn:     db 0
asm_1_4568_n_sv_exit:
			ret			; end of #asm

asm_1_6598_n:		; #asm, Hyp.cls line 6598 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld (asm_1_6598_n_dv_ix), ix
            ld (asm_1_6598_n_dv_iy), iy
            ld hl, 0
            ld (var_hyp_drive_drive), hl
            ld hl, (var_hyp_drive_letter)
            ld (var_hyp_hdr), hl
            IF NTC_ROMLIB = 0
            ld a, (var_hyp_drs + 1)
            or a
            jr z, asm_1_6598_n_dv_rsx
            ld (asm_1_6598_n_dv_blk + 2), hl
            di
            ld bc, (var_hyp_drs)
            out (c), c
            ld ix, asm_1_6598_n_dv_blk
            call #4000
            ld bc, (ntc_rampt)
            out (c), c
            jr nc, asm_1_6598_n_dv_rsx
            ld hl, -1
            ld (var_hyp_drive_drive), hl
            jr asm_1_6598_n_dv_done
asm_1_6598_n_dv_blk:     dw 114, 0, 0, 0, 0, 0, 0
            ENDIF
asm_1_6598_n_dv_rsx:
            ld a, (var_hyp_drive_letter)
            or #80                  ; a one letter command name: its last letter + #80
            ld (asm_1_6598_n_dv_nm), a
            ld hl, asm_1_6598_n_dv_nm
            call #BCD4              ; KL FIND COMMAND: carry = found, C = its ROM, HL = its address
            di
            jr nc, asm_1_6598_n_dv_done
            xor a                   ; no parameters
            call #001B              ; KL FAR PCALL
            di
            ld hl, -1
            ld (var_hyp_drive_drive), hl
            jr asm_1_6598_n_dv_done
asm_1_6598_n_dv_nm:      db 0
asm_1_6598_n_dv_ix:      dw 0
asm_1_6598_n_dv_iy:      dw 0
asm_1_6598_n_dv_done:
            ld ix, (asm_1_6598_n_dv_ix)
            ld iy, (asm_1_6598_n_dv_iy)
            ld sp, (var_hyp_hsp)
			ret			; end of #asm

asm_4_29_n:		; #asm, V9.cls line 29 (normal)
            ld (var_v9_vsp), sp
            ld sp, (ntc_csp)
            ld hl, 0
            ld a, #15
            call asm_4_29_n_v9_pr1
            jr nz, asm_4_29_n_v9pb_no
            ld a, #2A
            call asm_4_29_n_v9_pr1
            jr nz, asm_4_29_n_v9pb_no
            dec hl                  ; True
asm_4_29_n_v9pb_no:
            ld (var_v9_probe_probe), hl
            xor a                   ; the backdrop 0 again
            ld e, 15
            call v9_reg
            ld sp, (var_v9_vsp)
            jr asm_4_29_n_v9pb_end
asm_4_29_n_v9_pr1:                             ; A to R#15 and read back: Z when it is the same
            ld d, a
            ld e, 15
            call v9_reg
            ld bc, #FF64
            ld a, 15
            out (c), a
            dec c
            in a, (c)
            cp d
            ret
asm_4_29_n_v9pb_end:
			ret			; end of #asm

asm_4_67_n:		; #asm, V9.cls line 67 (normal)
            ld (var_v9_vsp), sp
            ld sp, (ntc_csp)
            ld a, (var_v9_init_pal)
            call v9_init
    IFDEF NTC_MSXDOS
            ld a, 32                ; the main ROM's font (CGTABL), a character at a time
asm_4_67_n_v9in_ch:
            push af
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            ex de, hl               ; DE = the character * 8
            ld a, (#FCC1)
            ld hl, 4
            push de
            push af
            call #000C              ; RDSLT: CGTABL's low byte
            ld e, a
            pop af
            push de
            inc hl
            call #000C              ; its high byte
            pop de
            ld d, a
            pop hl
            add hl, de              ; the character's 8 bytes there
            ld de, asm_4_67_n_v9_gb
            ld b, 8
asm_4_67_n_v9in_b:
            push bc
            push de
            ld a, (#FCC1)
            push hl
            call #000C              ; RDSLT
            pop hl
            pop de
            pop bc
            ld (de), a
            inc de
            inc hl
            djnz asm_4_67_n_v9in_b
            di
            pop af
            push af
            ld hl, asm_4_67_n_v9_gb
            call asm_4_67_n_v9_glyph
            pop af
            inc a
            cp 128
            jr nz, asm_4_67_n_v9in_ch
    ELSE
            ld bc, #7FC0            ; main RAM's own #4000-#7FFF: v9_f6 (window data)
            out (c), c
            ld a, 32
            ld hl, v9_f6
asm_4_67_n_v9in_ch:
            push af
            push hl
            call asm_4_67_n_v9_glyph
            pop hl
            ld de, 8
            add hl, de
            pop af
            inc a
            cp 127
            jr nz, asm_4_67_n_v9in_ch
            ld bc, (ntc_rampt)      ; the window's page back
            out (c), c
    ENDIF
            call v9_wait
            ld a, #C2               ; R#8: the picture on (sprites off, 512K)
            ld e, 8
            call v9_reg
            ld a, 1
            ld (v9_on), a
            ld sp, (var_v9_vsp)
            jp asm_4_67_n_v9_end

; ---- the routines (Hyp's Con, Say, Scr, Inks; real stack)
@v9_on:     db 0                    ; 1: the V9990 is the console
@v9_tr:     db 0                    ; the ring's row at the screen's top (the CPC's Con)
asm_4_67_n_v9_x0:      dw 16                   ; the left margin, pixels (v9_cols)
asm_4_67_n_v9_gb:      ds 8                    ; (Init on the MSX: a character's 8 bytes)
asm_4_67_n_v9_gx:      db 0                    ; v9_glyph: its byte in the font's line, the font's line
asm_4_67_n_v9_gy:      db 0
asm_4_67_n_v9_cb:      ds 21                   ; a block command's R#32-R#52
asm_4_67_n_v9_rs:      db 6, #95, 8, #42, 9, 0, 13, 0, 15, 0, 16, 0, 17, 0, 18, #40, 19, 0, 20, 0
            db 21, 0, 22, 0, 23, 0, 24, 0, 25, 0, 26, 0, 27, 0, 28, 0, #FF
; v9_reg - E = a register, A = its value. HL, DE kept
@v9_reg:
            ld bc, #FF64
            out (c), e
            dec c
            out (c), a
            ret
; v9_wait - until the command running has ended (P#5 bit 0: CE)
@v9_wait:
            ld bc, #FF65
asm_4_67_n_v9wt_lp:
            in a, (c)
            rra
            jr c, asm_4_67_n_v9wt_lp
            ret
; v9_cmd - v9_cb to R#32-R#52 (the last: the command), once the one before has ended
asm_4_67_n_v9_cmd:
            call v9_wait
            ld bc, #FF64
            ld a, 32
            out (c), a
            dec c
            ld hl, asm_4_67_n_v9_cb
            ld e, 21
asm_4_67_n_v9cm_lp:
            ld a, (hl)
            out (c), a
            inc hl
            dec e
            jr nz, asm_4_67_n_v9cm_lp
            ret
; v9_init - A = 1 PAL, 0 NTSC: the chip reset, B3, the palette, lines 0-511 cleared (the picture off)
@v9_init:
            and 1
            rlca
            rlca
            rlca
            push af                 ; R#7: bit 3 PAL
            ld bc, #FF67
            ld a, 2                 ; P#7: reset, then on (XTAL1)
            out (c), a
            xor a
            out (c), a
            ld hl, asm_4_67_n_v9_rs
asm_4_67_n_v9i_lp:
            ld e, (hl)
            inc hl
            ld a, e
            cp #FF
            jr z, asm_4_67_n_v9i_rd
            ld a, (hl)
            inc hl
            call v9_reg
            jr asm_4_67_n_v9i_lp
asm_4_67_n_v9i_rd:
            pop af
            ld e, 7
            call v9_reg
            ld de, 1 * 256 + 24     ; blue paper, bright yellow pen (the CPC's)
            call v9_pal
            ld a, 80
            call v9_cols
            xor a
            ld (v9_tr), a
            call v9_top
            ld hl, 0
            ld de, 512
            jp asm_4_67_n_v9_box0
; v9_glyph - A = a character (32-127), HL = its 8 bytes (the left 6 pixels: bits 7-2): into the
; font's lines (256 + its line of 64 * 8), its 6 pixels 3 bytes (palette 1 the pen, 0 the paper)
asm_4_67_n_v9_glyph:
            sub 32
            ld c, a
            and 63
            ld b, a
            add a, a
            add a, b
            ld (asm_4_67_n_v9_gx), a           ; its byte: (character and 63) * 3
            ld a, c
            and 64
            rrca
            rrca
            rrca
            ld (asm_4_67_n_v9_gy), a           ; its line: 0 or 8 (+ 256)
            ex de, hl
            ld a, 0
asm_4_67_n_v9g_lp:
            push af
            ld hl, asm_4_67_n_v9_gy
            add a, (hl)
            ld h, a
            ld a, (asm_4_67_n_v9_gx)
            ld l, a
            ld bc, #FF64
            xor a
            out (c), a              ; R#0 on: the address to write at (+ #10000: line 256 on)
            dec c
            out (c), l
            out (c), h
            ld a, 1
            out (c), a
            ld a, (de)
            inc de
            ld h, a
            ld bc, #FF60
            ld l, 3
asm_4_67_n_v9g_b:
            xor a
            rlc h
            jr nc, asm_4_67_n_v9g_b1
            ld a, #10
asm_4_67_n_v9g_b1:
            rlc h
            jr nc, asm_4_67_n_v9g_b2
            or #01
asm_4_67_n_v9g_b2:
            out (c), a
            dec l
            jr nz, asm_4_67_n_v9g_b
            pop af
            inc a
            cp 8
            jr nz, asm_4_67_n_v9g_lp
            ret
; v9_cell - A = a character, H = the ring's row, L = its column: copied from the font (LMMM)
@v9_cell:
            sub 32
            cp 96
            jr c, asm_4_67_n_v9c_ok
            ld a, '?' - 32
asm_4_67_n_v9c_ok:
            ld c, a
            push hl
            and 63
            ld e, a
            ld d, 0
            ld h, d
            ld l, e
            add hl, hl
            add hl, de
            add hl, hl
            ld (asm_4_67_n_v9_cb), hl          ; SX = (character and 63) * 6
            ld a, c
            and 64
            rrca
            rrca
            rrca
            ld l, a
            ld h, 1
            ld (asm_4_67_n_v9_cb + 2), hl      ; SY = 256 + 0 / 8
            pop hl
            call asm_4_67_n_v9_dxy             ; DX, DY: the cell
            ld hl, 6
            ld (asm_4_67_n_v9_cb + 8), hl      ; NX
            ld l, 8
            ld (asm_4_67_n_v9_cb + 10), hl     ; NY
            ld hl, #0C00            ; ARG 0, LOP: WC = SC
            ld (asm_4_67_n_v9_cb + 12), hl
            ld hl, #FFFF
            ld (asm_4_67_n_v9_cb + 14), hl     ; the write mask
            ld a, #40               ; LMMM
            ld (asm_4_67_n_v9_cb + 20), a
            jp asm_4_67_n_v9_cmd
; v9_dxy - H = ring row, L = column: DX = the margin + L * 6, DY = H * 8
asm_4_67_n_v9_dxy:
            ld a, h
            add a, a
            add a, a
            add a, a
            ld (asm_4_67_n_v9_cb + 6), a
            xor a
            ld (asm_4_67_n_v9_cb + 7), a
            ld e, l
            ld d, 0
            ld h, d
            ld l, e
            add hl, hl
            add hl, de
            add hl, hl
            ld de, (asm_4_67_n_v9_x0)
            add hl, de
            ld (asm_4_67_n_v9_cb + 4), hl
            ret
; v9_xcur - H = ring row, L = column: the cell's last line XORed (palette 0 <-> 1: the cursor)
@v9_xcur:
            call asm_4_67_n_v9_dxy
            ld a, (asm_4_67_n_v9_cb + 6)
            add a, 7
            ld (asm_4_67_n_v9_cb + 6), a
            ld hl, 6
            ld (asm_4_67_n_v9_cb + 8), hl
            ld l, 1
            ld (asm_4_67_n_v9_cb + 10), hl
            ld hl, #0600            ; ARG 0, LOP: WC = SC XOR DC
            ld (asm_4_67_n_v9_cb + 12), hl
            ld a, #11
            jr asm_4_67_n_v9_lmmv
; v9_clrow - A = a ring row: its 8 lines the paper, the whole width
@v9_clrow:
            add a, a
            add a, a
            add a, a
            ld l, a
            ld h, 0
            ld de, 8
; v9_box0 - HL = the first line, DE = lines: the paper, the whole width (512)
asm_4_67_n_v9_box0:
            ld (asm_4_67_n_v9_cb + 6), hl
            ld (asm_4_67_n_v9_cb + 10), de
            ld hl, 0
            ld (asm_4_67_n_v9_cb + 4), hl
            ld hl, 512
            ld (asm_4_67_n_v9_cb + 8), hl
            ld hl, #0C00
            ld (asm_4_67_n_v9_cb + 12), hl
            xor a
; v9_lmmv - A = FC's byte (the colour in both pixels): LMMV with the rest of v9_cb as set
asm_4_67_n_v9_lmmv:
            ld (asm_4_67_n_v9_cb + 16), a
            ld (asm_4_67_n_v9_cb + 17), a
            ld hl, #FFFF
            ld (asm_4_67_n_v9_cb + 14), hl
            ld a, #20               ; LMMV
            ld (asm_4_67_n_v9_cb + 20), a
            jp asm_4_67_n_v9_cmd
; v9_clrall - the ring (lines 0-255) the paper
@v9_clrall:
            ld hl, 0
            ld de, 256
            jr asm_4_67_n_v9_box0
; v9_top - A = the ring row at the screen's top: SCAY = A * 8 (R#17, then R#18: rolled at 256)
@v9_top:
            and 31
            add a, a
            add a, a
            add a, a
            ld e, 17
            call v9_reg
            ld a, #40
            ld e, 18
            jp v9_reg
; v9_cols - A = the screen's columns: the left margin (512 - A * 6) / 2
@v9_cols:
            ld e, a
            ld d, 0
            ld h, d
            ld l, e
            add hl, hl
            add hl, de
            ex de, hl
            ld hl, 256
            or a
            sbc hl, de
            jr nc, asm_4_67_n_v9co_ok
            ld hl, 0
asm_4_67_n_v9co_ok:
            ld (asm_4_67_n_v9_x0), hl
            ret
; v9_pal - D = the paper, E = the pen: CPC firmware colours (0-26: 9 * green + 3 * red + blue,
; each 0-2) into palette 0 and 1
@v9_pal:
            push de
            xor a
            ld e, 14
            call v9_reg             ; R#14: palette 0, its red first
            pop de
            push de
            ld a, d
            call asm_4_67_n_v9_rgb
            pop de
            ld a, e
asm_4_67_n_v9_rgb:                             ; A = a firmware colour: its red, green, blue to P#1
            ld d, 0
asm_4_67_n_v9rg_9:
            cp 9
            jr c, asm_4_67_n_v9rg_3
            sub 9
            inc d                   ; D = green
            jr asm_4_67_n_v9rg_9
asm_4_67_n_v9rg_3:
            ld e, 0
asm_4_67_n_v9rg_3l:
            cp 3
            jr c, asm_4_67_n_v9rg_b
            sub 3
            inc e                   ; E = red, A = blue
            jr asm_4_67_n_v9rg_3l
asm_4_67_n_v9rg_b:
            ld bc, #FF61
            push af
            ld a, e
            call asm_4_67_n_v9_lvl
            out (c), a
            ld a, d
            call asm_4_67_n_v9_lvl
            out (c), a
            pop af
            call asm_4_67_n_v9_lvl
            out (c), a
            ret
asm_4_67_n_v9_lvl:                             ; 0, 1, 2 -> 0, 15, 31 (5 bits)
            or a
            ret z
            dec a
            ld a, 15
            ret z
            ld a, 31
            ret
; v9_off - the picture off (R#8: DISP 0 - the backdrop only)
@v9_off:
            call v9_wait
            ld a, #42
            ld e, 8
            jp v9_reg
asm_4_67_n_v9_end:
			ret			; end of #asm

fn_keys_down:		; function down (asm keyword), Keys.cls line 44
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ex de, hl
            jp ntc_kdown
			ret			; end of #asm

fn_memory_pages:		; function pages (asm keyword), Memory.cls line 70
            pop hl
            ld (mem_res), hl
            ld hl, mem_pages
            jp mem_go
			ret			; end of #asm

fn_memory_freepages:		; function freepages (asm keyword), Memory.cls line 80
            pop hl
            ld (mem_res), hl
            ld hl, mem_freepages
            jp mem_go
			ret			; end of #asm

fn_memory_ramsize:		; function ramsize (asm keyword), Memory.cls line 90
            pop hl
            ld (mem_res), hl
            ld hl, mem_ramsize
            jp mem_go
			ret			; end of #asm

fn_memory_pagetype:		; function pagetype (asm keyword), Memory.cls line 110
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a1), de
            pop hl
            ld (mem_res), hl
            ld hl, mem_pagetype
            jp mem_go
			ret			; end of #asm

fn_memory_tableend:		; function tableend (asm keyword), Memory.cls line 146
            pop hl
            ld (mem_res), hl
            ld hl, mem_tableend
            jp mem_go
			ret			; end of #asm

fn_memory_top:		; function top (asm keyword), Memory.cls line 176
            pop hl
            ld (mem_res), hl
            ld hl, mem_top
            jp mem_go
			ret			; end of #asm

fn_memory_map:		; function map (asm keyword), Memory.cls line 196
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a1), de
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a2), de
            pop hl
            ld (mem_res), hl
            ld hl, mem_map
            jp mem_go0
			ret			; end of #asm

fn_memory_allocpage:		; function allocpage (asm keyword), Memory.cls line 219
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a1), de
            pop hl
            ld (mem_res), hl
            ld hl, mem_allocpage
            jp mem_go
			ret			; end of #asm

fn_memory_freepage:		; function freepage (asm keyword), Memory.cls line 235
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a1), de
            pop hl
            ld (mem_res), hl
            ld hl, mem_freepage
            jp mem_go
			ret			; end of #asm

fn_memory_selectpage:		; function selectpage (asm keyword), Memory.cls line 250
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a1), de
            pop hl
            ld (mem_res), hl
            ld hl, mem_selpage
            jp mem_go
			ret			; end of #asm

fn_memory_readbyte:		; function readbyte (asm keyword), Memory.cls line 340
            pop hl
            ld (mem_a1), hl
            pop hl
            ld (mem_res), hl
            ld hl, mem_readbyte
            jp mem_go
			ret			; end of #asm

fn_memory_readword:		; function readword (asm keyword), Memory.cls line 351
            pop hl
            ld (mem_a1), hl
            pop hl
            ld (mem_res), hl
            ld hl, mem_readword
            jp mem_go
			ret			; end of #asm

fn_memory_writebyte:		; sub writebyte (asm keyword), Memory.cls line 362
            pop hl
            ld (mem_a1), hl
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a2), de
            ld hl, mem_writebyte
            jp mem_go0
			ret			; end of #asm

fn_memory_writeword:		; sub writeword (asm keyword), Memory.cls line 376
            pop hl
            ld (mem_a1), hl
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a2), de
            ld hl, mem_writeword
            jp mem_go0
			ret			; end of #asm

fn_memory_copy:		; function copy (asm keyword), Memory.cls line 393
            pop hl
            ld (mem_a1), hl
            pop hl
            ld (mem_a2), hl
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (mem_a3), de
            pop hl
            ld (mem_res), hl
            ld hl, mem_copy
            jp mem_go
			ret			; end of #asm

fn_memory_banks:		; function banks (asm keyword), Memory.cls line 414
            pop hl
            ld (mem_res), hl
            ld hl, mem_bankcount
            jp mem_go
			ret			; end of #asm

fn_memory_allocbank:		; function allocbank (asm keyword), Memory.cls line 424
            pop hl
            ld (mem_res), hl
            ld hl, mem_allocbank
            jp mem_go
			ret			; end of #asm


ntc_rg48_e:
			IF ($ < 32768) && (ntc_rg49_e - ntc_rg49 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg49:
; ============================================================
; Variables
; ============================================================

ntc_rg49_e:
			IF ($ < 32768) && (ntc_rg50_e - ntc_rg50 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg50:
var_k:			dw 0
ntc_rg50_e:
			IF ($ < 32768) && (ntc_rg51_e - ntc_rg51 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg51:
var_ns:			dw 0
ntc_rg51_e:
			IF ($ < 32768) && (ntc_rg52_e - ntc_rg52 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg52:
var_i:			dw 0
ntc_rg52_e:
			IF ($ < 32768) && (ntc_rg53_e - ntc_rg53 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg53:
var_hp:			dw 0
ntc_rg53_e:
			IF ($ < 32768) && (ntc_rg54_e - ntc_rg54 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg54:
var_memory_selectpage_selectpage:			dw 0
ntc_rg54_e:
			IF ($ < 32768) && (ntc_rg55_e - ntc_rg55 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg55:
var_front:			dw 0
ntc_rg55_e:
			IF ($ < 32768) && (ntc_rg56_e - ntc_rg56 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg56:
var_dp:			dw 0
ntc_rg56_e:
			IF ($ < 32768) && (ntc_rg57_e - ntc_rg57 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg57:
var_hyp_filecall_filecall:			dw 0
ntc_rg57_e:
			IF ($ < 32768) && (ntc_rg58_e - ntc_rg58 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg58:
var_hyp_svc_svc:			dw 0
ntc_rg58_e:
			IF ($ < 32768) && (ntc_rg59_e - ntc_rg59 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg59:
for3_l:			dw 0
ntc_rg59_e:
			IF ($ < 32768) && (ntc_rg60_e - ntc_rg60 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg60:
var_memory_allocbank_allocbank:			dw 0
ntc_rg60_e:
			IF ($ < 32768) && (ntc_rg61_e - ntc_rg61 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg61:
var_memory_bankpage_bankpage:			dw 0
ntc_rg61_e:
			IF ($ < 32768) && (ntc_rg62_e - ntc_rg62 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg62:
var_hyp_setting_setting:			dw 0
ntc_rg62_e:
			IF ($ < 32768) && (ntc_rg63_e - ntc_rg63 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg63:
var_kwp:			dw 0
ntc_rg63_e:
			IF ($ < 32768) && (ntc_rg64_e - ntc_rg64 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg64:
			db 72			; capacity
var_a:			ds 73
ntc_rg64_e:
			IF ($ < 32768) && (ntc_rg65_e - ntc_rg65 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg65:
var_v9_probe_probe:			dw 0
ntc_rg65_e:
			IF ($ < 32768) && (ntc_rg66_e - ntc_rg66 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg66:
var_bd:			dw 0
ntc_rg66_e:
			IF ($ < 32768) && (ntc_rg67_e - ntc_rg67 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg67:
var_mz:			dw 0
ntc_rg67_e:
			IF ($ < 32768) && (ntc_rg68_e - ntc_rg68 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg68:
var_probediscs_probediscs:			dw 0
ntc_rg68_e:
			IF ($ < 32768) && (ntc_rg69_e - ntc_rg69 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg69:
var_memory_banks_banks:			dw 0
ntc_rg69_e:
			IF ($ < 32768) && (ntc_rg70_e - ntc_rg70 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg70:
var_hyp_drive_drive:			dw 0
ntc_rg70_e:
			IF ($ < 32768) && (ntc_rg71_e - ntc_rg71 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg71:
			db 16			; capacity
var_dn:			ds 17
ntc_rg71_e:
			IF ($ < 32768) && (ntc_rg72_e - ntc_rg72 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg72:
var_far_far:			dw 0, 0
ntc_rg72_e:
			IF ($ < 32768) && (ntc_rg73_e - ntc_rg73 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg73:
var_hyp_go_go:			dw 0
ntc_rg73_e:
			IF ($ < 32768) && (ntc_rg74_e - ntc_rg74 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg74:
var_hyp_src_src:			dw 0
ntc_rg74_e:
			IF ($ < 32768) && (ntc_rg75_e - ntc_rg75 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg75:
p_kcall_rs:			dw 0
ntc_rg75_e:
			IF ($ < 32768) && (ntc_rg76_e - ntc_rg76 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg76:
var_kcall_c:			dw 0
ntc_rg76_e:
			IF ($ < 32768) && (ntc_rg77_e - ntc_rg77 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg77:
var_hyp_count_count:			dw 0
ntc_rg77_e:
			IF ($ < 32768) && (ntc_rg78_e - ntc_rg78 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg78:
var_hyp_fn_fn:			dw 0
ntc_rg78_e:
			IF ($ < 32768) && (ntc_rg79_e - ntc_rg79 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg79:
p_slotcall_rs:			dw 0
ntc_rg79_e:
			IF ($ < 32768) && (ntc_rg80_e - ntc_rg80 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg80:
var_slotcall_t:			dw 0
ntc_rg80_e:
			IF ($ < 32768) && (ntc_rg81_e - ntc_rg81 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg81:
var_slotcall_c:			dw 0
ntc_rg81_e:
			IF ($ < 32768) && (ntc_rg82_e - ntc_rg82 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg82:
var_cw:			dw 0
ntc_rg82_e:
			IF ($ < 32768) && (ntc_rg83_e - ntc_rg83 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg83:
var_ca:			dw 0
ntc_rg83_e:
			IF ($ < 32768) && (ntc_rg84_e - ntc_rg84 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg84:
p_serve_rs:			dw 0
ntc_rg84_e:
			IF ($ < 32768) && (ntc_rg85_e - ntc_rg85 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg85:
var_serve_t:			dw 0
ntc_rg85_e:
			IF ($ < 32768) && (ntc_rg86_e - ntc_rg86 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg86:
var_serve_c:			dw 0
ntc_rg86_e:
			IF ($ < 32768) && (ntc_rg87_e - ntc_rg87 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg87:
var_serve___sel22:			dw 0
ntc_rg87_e:
			IF ($ < 32768) && (ntc_rg88_e - ntc_rg88 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg88:
var_hot_take_take:			dw 0
ntc_rg88_e:
			IF ($ < 32768) && (ntc_rg89_e - ntc_rg89 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg89:
var_hot_control_control:			dw 0
ntc_rg89_e:
			IF ($ < 32768) && (ntc_rg90_e - ntc_rg90 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg90:
var_hot_held_held:			dw 0
ntc_rg90_e:
			IF ($ < 32768) && (ntc_rg91_e - ntc_rg91 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg91:
var_nearp_nearp:			dw 0, 0
ntc_rg91_e:
			IF ($ < 32768) && (ntc_rg92_e - ntc_rg92 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg92:
var_memory_copy_copy:			dw 0
ntc_rg92_e:
			IF ($ < 32768) && (ntc_rg93_e - ntc_rg93 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg93:
var_hyp_scr_scr:			dw 0
ntc_rg93_e:
			IF ($ < 32768) && (ntc_rg94_e - ntc_rg94 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg94:
var_ramdisc_ramdisc:			dw 0
ntc_rg94_e:
			IF ($ < 32768) && (ntc_rg95_e - ntc_rg95 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg95:
var_storesize_storesize:			dw 0
ntc_rg95_e:
			IF ($ < 32768) && (ntc_rg96_e - ntc_rg96 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg96:
			db 60			; capacity
var_en:			ds 61
ntc_rg96_e:
			IF ($ < 32768) && (ntc_rg97_e - ntc_rg97 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg97:
			db 72			; capacity
var_memory_map_map:			ds 73
ntc_rg97_e:
			IF ($ < 32768) && (ntc_rg98_e - ntc_rg98 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg98:
p_kdin_rs:			dw 0
ntc_rg98_e:
			IF ($ < 32768) && (ntc_rg99_e - ntc_rg99 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg99:
var_kdin_p:			dw 0
ntc_rg99_e:
			IF ($ < 32768) && (ntc_rg100_e - ntc_rg100 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg100:
var_kdin_n:			dw 0
ntc_rg100_e:
			IF ($ < 32768) && (ntc_rg101_e - ntc_rg101 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg101:
p_kdout_rs:			dw 0
ntc_rg101_e:
			IF ($ < 32768) && (ntc_rg102_e - ntc_rg102 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg102:
var_kdout_p:			dw 0
ntc_rg102_e:
			IF ($ < 32768) && (ntc_rg103_e - ntc_rg103 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg103:
var_kdout_n:			dw 0
ntc_rg103_e:
			IF ($ < 32768) && (ntc_rg104_e - ntc_rg104 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg104:
p_kshow_rs:			dw 0
ntc_rg104_e:
			IF ($ < 32768) && (ntc_rg105_e - ntc_rg105 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg105:
var_kshow_n:			dw 0
ntc_rg105_e:
			IF ($ < 32768) && (ntc_rg106_e - ntc_rg106 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg106:
var_kshow_t:			dw 0
ntc_rg106_e:
			IF ($ < 32768) && (ntc_rg107_e - ntc_rg107 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg107:
p_quit_rs:			dw 0
ntc_rg107_e:
			IF ($ < 32768) && (ntc_rg108_e - ntc_rg108 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg108:
var_quit_n:			dw 0
ntc_rg108_e:
			IF ($ < 32768) && (ntc_rg109_e - ntc_rg109 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg109:
p_owncall_rs:			dw 0
ntc_rg109_e:
			IF ($ < 32768) && (ntc_rg110_e - ntc_rg110 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg110:
var_owncall_t:			dw 0
ntc_rg110_e:
			IF ($ < 32768) && (ntc_rg111_e - ntc_rg111 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg111:
var_owncall_f:			dw 0
ntc_rg111_e:
			IF ($ < 32768) && (ntc_rg112_e - ntc_rg112 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg112:
var_owncall_e:			dw 0
ntc_rg112_e:
			IF ($ < 32768) && (ntc_rg113_e - ntc_rg113 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg113:
var_owncall_j:			dw 0
ntc_rg113_e:
			IF ($ < 32768) && (ntc_rg114_e - ntc_rg114 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg114:
var_owncall_o:			dw 0
ntc_rg114_e:
			IF ($ < 32768) && (ntc_rg115_e - ntc_rg115 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg115:
var_hyp_arg_arg:			dw 0
ntc_rg115_e:
			IF ($ < 32768) && (ntc_rg116_e - ntc_rg116 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg116:
var_owncall___sel30:			dw 0
ntc_rg116_e:
			IF ($ < 32768) && (ntc_rg117_e - ntc_rg117 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg117:
for33_l:			dw 0
ntc_rg117_e:
			IF ($ < 32768) && (ntc_rg118_e - ntc_rg118 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg118:
var_memory_readword_readword:			dw 0
ntc_rg118_e:
			IF ($ < 32768) && (ntc_rg119_e - ntc_rg119 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg119:
p_ramdisc_rs:			dw 0
ntc_rg119_e:
			IF ($ < 32768) && (ntc_rg120_e - ntc_rg120 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg120:
var_ramdisc_t:			dw 0
ntc_rg120_e:
			IF ($ < 32768) && (ntc_rg121_e - ntc_rg121 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg121:
var_ramdisc_p:			dw 0
ntc_rg121_e:
			IF ($ < 32768) && (ntc_rg122_e - ntc_rg122 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg122:
var_ramdisc_g:			dw 0
ntc_rg122_e:
			IF ($ < 32768) && (ntc_rg123_e - ntc_rg123 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg123:
var_ramdisc_o:			dw 0
ntc_rg123_e:
			IF ($ < 32768) && (ntc_rg124_e - ntc_rg124 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg124:
var_ramdisc_f:			dw 0, 0
ntc_rg124_e:
			IF ($ < 32768) && (ntc_rg125_e - ntc_rg125 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg125:
var_hyp_farptr_farptr:			dw 0, 0
ntc_rg125_e:
			IF ($ < 32768) && (ntc_rg126_e - ntc_rg126 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg126:
p_storesize_rs:			dw 0
ntc_rg126_e:
			IF ($ < 32768) && (ntc_rg127_e - ntc_rg127 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg127:
var_storesize_t:			dw 0
ntc_rg127_e:
			IF ($ < 32768) && (ntc_rg128_e - ntc_rg128 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg128:
var_storesize_kb:			dw 0
ntc_rg128_e:
			IF ($ < 32768) && (ntc_rg129_e - ntc_rg129 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg129:
var_storesize_n:			dw 0
ntc_rg129_e:
			IF ($ < 32768) && (ntc_rg130_e - ntc_rg130 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg130:
var_storesize_j:			dw 0
ntc_rg130_e:
			IF ($ < 32768) && (ntc_rg131_e - ntc_rg131 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg131:
var_storesize_g:			dw 0
ntc_rg131_e:
			IF ($ < 32768) && (ntc_rg132_e - ntc_rg132 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg132:
var_memory_freepage_freepage:			dw 0
ntc_rg132_e:
			IF ($ < 32768) && (ntc_rg133_e - ntc_rg133 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg133:
p_probediscs_rs:			dw 0
ntc_rg133_e:
			IF ($ < 32768) && (ntc_rg134_e - ntc_rg134 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg134:
var_probediscs_p:			dw 0
ntc_rg134_e:
			IF ($ < 32768) && (ntc_rg135_e - ntc_rg135 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg135:
var_probediscs_su:			dw 0
ntc_rg135_e:
			IF ($ < 32768) && (ntc_rg136_e - ntc_rg136 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg136:
var_probediscs_j:			dw 0
ntc_rg136_e:
			IF ($ < 32768) && (ntc_rg137_e - ntc_rg137 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg137:
var_probediscs_a:			dw 0
ntc_rg137_e:
			IF ($ < 32768) && (ntc_rg138_e - ntc_rg138 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg138:
var_probediscs_pg:			dw 0
ntc_rg138_e:
			IF ($ < 32768) && (ntc_rg139_e - ntc_rg139 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg139:
var_probediscs_r:			dw 0
ntc_rg139_e:
			IF ($ < 32768) && (ntc_rg140_e - ntc_rg140 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg140:
for47_l:			dw 0
ntc_rg140_e:
			IF ($ < 32768) && (ntc_rg141_e - ntc_rg141 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg141:
var_memory_pagetype_pagetype:			dw 0
ntc_rg141_e:
			IF ($ < 32768) && (ntc_rg142_e - ntc_rg142 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg142:
var_hyp_claimpage_claimpage:			dw 0
ntc_rg142_e:
			IF ($ < 32768) && (ntc_rg143_e - ntc_rg143 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg143:
p_nearp_rs:			dw 0
ntc_rg143_e:
			IF ($ < 32768) && (ntc_rg144_e - ntc_rg144 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg144:
var_nearp_p:			dw 0
ntc_rg144_e:
			IF ($ < 32768) && (ntc_rg145_e - ntc_rg145 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg145:
p_far_rs:			dw 0
ntc_rg145_e:
			IF ($ < 32768) && (ntc_rg146_e - ntc_rg146 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg146:
var_far_t:			dw 0
ntc_rg146_e:
			IF ($ < 32768) && (ntc_rg147_e - ntc_rg147 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg147:
var_far_a:			dw 0
ntc_rg147_e:
			IF ($ < 32768) && (ntc_rg148_e - ntc_rg148 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg148:
p_install_rs:			dw 0
ntc_rg148_e:
			IF ($ < 32768) && (ntc_rg149_e - ntc_rg149 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg149:
var_install_t:			dw 0
ntc_rg149_e:
			IF ($ < 32768) && (ntc_rg150_e - ntc_rg150 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg150:
var_install_p:			dw 0
ntc_rg150_e:
			IF ($ < 32768) && (ntc_rg151_e - ntc_rg151 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg151:
var_install_n:			dw 0
ntc_rg151_e:
			IF ($ < 32768) && (ntc_rg152_e - ntc_rg152 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg152:
p_launch_rs:			dw 0
ntc_rg152_e:
			IF ($ < 32768) && (ntc_rg153_e - ntc_rg153 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg153:
var_launch_s:			dw 0
ntc_rg153_e:
			IF ($ < 32768) && (ntc_rg154_e - ntc_rg154 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg154:
var_hyp_info_info:			dw 0
ntc_rg154_e:
			IF ($ < 32768) && (ntc_rg155_e - ntc_rg155 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg155:
var_hyp_hps:			dw 0
ntc_rg155_e:
			IF ($ < 32768) && (ntc_rg156_e - ntc_rg156 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg156:
p_hyp_usedriver_rs:			dw 0
ntc_rg156_e:
			IF ($ < 32768) && (ntc_rg157_e - ntc_rg157 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg157:
var_hyp_usedriver_b:			dw 0
ntc_rg157_e:
			IF ($ < 32768) && (ntc_rg158_e - ntc_rg158 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg158:
var_hyp_dxb:			dw 0
ntc_rg158_e:
			IF ($ < 32768) && (ntc_rg159_e - ntc_rg159 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg159:
var_hyp_drs:			dw 0
ntc_rg159_e:
			IF ($ < 32768) && (ntc_rg160_e - ntc_rg160 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg160:
p_hyp_claimpage_rs:			dw 0
ntc_rg160_e:
			IF ($ < 32768) && (ntc_rg161_e - ntc_rg161 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg161:
var_hyp_claimpage_page:			dw 0
ntc_rg161_e:
			IF ($ < 32768) && (ntc_rg162_e - ntc_rg162 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg162:
var_hyp_hsp:			dw 0
ntc_rg162_e:
			IF ($ < 32768) && (ntc_rg163_e - ntc_rg163 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg163:
p_hyp_con_rs:			dw 0
ntc_rg163_e:
			IF ($ < 32768) && (ntc_rg164_e - ntc_rg164 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg164:
var_hyp_con_pg:			dw 0
ntc_rg164_e:
			IF ($ < 32768) && (ntc_rg165_e - ntc_rg165 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg165:
var_hyp_con_src:			dw 0
ntc_rg165_e:
			IF ($ < 32768) && (ntc_rg166_e - ntc_rg166 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg166:
var_hyp_con_n:			dw 0
ntc_rg166_e:
			IF ($ < 32768) && (ntc_rg167_e - ntc_rg167 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg167:
var_hyp_con_front:			dw 0
ntc_rg167_e:
			IF ($ < 32768) && (ntc_rg168_e - ntc_rg168 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg168:
var_hyp_ccu:			dw 0
ntc_rg168_e:
			IF ($ < 32768) && (ntc_rg169_e - ntc_rg169 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg169:
var_hyp_nta:			dw 0
ntc_rg169_e:
			IF ($ < 32768) && (ntc_rg170_e - ntc_rg170 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg170:
var_hyp_ntb:			dw 0
ntc_rg170_e:
			IF ($ < 32768) && (ntc_rg171_e - ntc_rg171 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg171:
var_hyp_sco:			dw 0
ntc_rg171_e:
			IF ($ < 32768) && (ntc_rg172_e - ntc_rg172 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg172:
var_hyp_scc:			dw 0
ntc_rg172_e:
			IF ($ < 32768) && (ntc_rg173_e - ntc_rg173 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg173:
var_hyp_pon:			dw 0
ntc_rg173_e:
			IF ($ < 32768) && (ntc_rg174_e - ntc_rg174 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg174:
var_hyp_ntu:			dw 0
ntc_rg174_e:
			IF ($ < 32768) && (ntc_rg175_e - ntc_rg175 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg175:
p_hyp_say_rs:			dw 0
ntc_rg175_e:
			IF ($ < 32768) && (ntc_rg176_e - ntc_rg176 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg176:
var_hyp_say_p:			dw 0
ntc_rg176_e:
			IF ($ < 32768) && (ntc_rg177_e - ntc_rg177 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg177:
var_hyp_say_n:			dw 0
ntc_rg177_e:
			IF ($ < 32768) && (ntc_rg178_e - ntc_rg178 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg178:
var_hyp_say_col:			dw 0
ntc_rg178_e:
			IF ($ < 32768) && (ntc_rg179_e - ntc_rg179 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg179:
var_hyp_say_row:			dw 0
ntc_rg179_e:
			IF ($ < 32768) && (ntc_rg180_e - ntc_rg180 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg180:
p_hyp_scr_rs:			dw 0
ntc_rg180_e:
			IF ($ < 32768) && (ntc_rg181_e - ntc_rg181 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg181:
var_hyp_scr_m:			dw 0
ntc_rg181_e:
			IF ($ < 32768) && (ntc_rg182_e - ntc_rg182 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg182:
var_hyp_scr_k:			dw 0
ntc_rg182_e:
			IF ($ < 32768) && (ntc_rg183_e - ntc_rg183 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg183:
var_hyp_scw:			dw 0
ntc_rg183_e:
			IF ($ < 32768) && (ntc_rg184_e - ntc_rg184 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg184:
p_hyp_inks_rs:			dw 0
ntc_rg184_e:
			IF ($ < 32768) && (ntc_rg185_e - ntc_rg185 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg185:
var_hyp_inks_p:			dw 0
ntc_rg185_e:
			IF ($ < 32768) && (ntc_rg186_e - ntc_rg186 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg186:
var_hyp_inks_q:			dw 0
ntc_rg186_e:
			IF ($ < 32768) && (ntc_rg187_e - ntc_rg187 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg187:
var_hyp_inks_b:			dw 0
ntc_rg187_e:
			IF ($ < 32768) && (ntc_rg188_e - ntc_rg188 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg188:
p_hyp_keyrep_rs:			dw 0
ntc_rg188_e:
			IF ($ < 32768) && (ntc_rg189_e - ntc_rg189 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg189:
var_hyp_keyrep_f:			dw 0
ntc_rg189_e:
			IF ($ < 32768) && (ntc_rg190_e - ntc_rg190 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg190:
p_hyp_reply_rs:			dw 0
ntc_rg190_e:
			IF ($ < 32768) && (ntc_rg191_e - ntc_rg191 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg191:
var_hyp_reply_a:			dw 0
ntc_rg191_e:
			IF ($ < 32768) && (ntc_rg192_e - ntc_rg192 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg192:
var_hyp_reply_hl:			dw 0
ntc_rg192_e:
			IF ($ < 32768) && (ntc_rg193_e - ntc_rg193 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg193:
var_hyp_ra:			dw 0
ntc_rg193_e:
			IF ($ < 32768) && (ntc_rg194_e - ntc_rg194 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg194:
var_hyp_rhl:			dw 0
ntc_rg194_e:
			IF ($ < 32768) && (ntc_rg195_e - ntc_rg195 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg195:
p_hyp_fn_rs:			dw 0
ntc_rg195_e:
			IF ($ < 32768) && (ntc_rg196_e - ntc_rg196 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg196:
var_hyp_rfn:			dw 0
ntc_rg196_e:
			IF ($ < 32768) && (ntc_rg197_e - ntc_rg197 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg197:
p_hyp_arg_rs:			dw 0
ntc_rg197_e:
			IF ($ < 32768) && (ntc_rg198_e - ntc_rg198 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg198:
var_hyp_rde:			dw 0
ntc_rg198_e:
			IF ($ < 32768) && (ntc_rg199_e - ntc_rg199 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg199:
p_hyp_count_rs:			dw 0
ntc_rg199_e:
			IF ($ < 32768) && (ntc_rg200_e - ntc_rg200 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg200:
var_hyp_rcnt:			dw 0
ntc_rg200_e:
			IF ($ < 32768) && (ntc_rg201_e - ntc_rg201 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg201:
p_hyp_go_rs:			dw 0
ntc_rg201_e:
			IF ($ < 32768) && (ntc_rg202_e - ntc_rg202 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg202:
var_hyp_go_setting:			dw 0
ntc_rg202_e:
			IF ($ < 32768) && (ntc_rg203_e - ntc_rg203 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg203:
var_hyp_sps:			dw 0
ntc_rg203_e:
			IF ($ < 32768) && (ntc_rg204_e - ntc_rg204 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg204:
var_hyp_gset:			dw 0
ntc_rg204_e:
			IF ($ < 32768) && (ntc_rg205_e - ntc_rg205 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg205:
var_hyp_rclr:			dw 0
ntc_rg205_e:
			IF ($ < 32768) && (ntc_rg206_e - ntc_rg206 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg206:
var_hyp_rsrc:			dw 0
ntc_rg206_e:
			IF ($ < 32768) && (ntc_rg207_e - ntc_rg207 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg207:
var_hyp_gsg:			dw 0
ntc_rg207_e:
			IF ($ < 32768) && (ntc_rg208_e - ntc_rg208 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg208:
p_hyp_goinit_rs:			dw 0
ntc_rg208_e:
			IF ($ < 32768) && (ntc_rg209_e - ntc_rg209 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg209:
var_hyp_goinit_v:			dw 0
ntc_rg209_e:
			IF ($ < 32768) && (ntc_rg210_e - ntc_rg210 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg210:
p_hyp_src_rs:			dw 0
ntc_rg210_e:
			IF ($ < 32768) && (ntc_rg211_e - ntc_rg211 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg211:
p_hyp_replye_rs:			dw 0
ntc_rg211_e:
			IF ($ < 32768) && (ntc_rg212_e - ntc_rg212 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg212:
var_hyp_replye_e:			dw 0
ntc_rg212_e:
			IF ($ < 32768) && (ntc_rg213_e - ntc_rg213 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg213:
p_hyp_vdu_rs:			dw 0
ntc_rg213_e:
			IF ($ < 32768) && (ntc_rg214_e - ntc_rg214 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg214:
var_hyp_vdu_on:			dw 0
ntc_rg214_e:
			IF ($ < 32768) && (ntc_rg215_e - ntc_rg215 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg215:
p_hyp_filecall_rs:			dw 0
ntc_rg215_e:
			IF ($ < 32768) && (ntc_rg216_e - ntc_rg216 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg216:
var_hyp_filecall_f:			dw 0
ntc_rg216_e:
			IF ($ < 32768) && (ntc_rg217_e - ntc_rg217 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg217:
var_hyp_filecall_fcb:			dw 0
ntc_rg217_e:
			IF ($ < 32768) && (ntc_rg218_e - ntc_rg218 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg218:
var_hyp_filecall_slot:			dw 0
ntc_rg218_e:
			IF ($ < 32768) && (ntc_rg219_e - ntc_rg219 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg219:
var_hyp_filecall_setting:			dw 0
ntc_rg219_e:
			IF ($ < 32768) && (ntc_rg220_e - ntc_rg220 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg220:
var_hyp_filecall_dma:			dw 0
ntc_rg220_e:
			IF ($ < 32768) && (ntc_rg221_e - ntc_rg221 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg221:
var_hyp_filecall_drive:			dw 0
ntc_rg221_e:
			IF ($ < 32768) && (ntc_rg222_e - ntc_rg222 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg222:
var_hyp_filecall_buf:			dw 0
ntc_rg222_e:
			IF ($ < 32768) && (ntc_rg223_e - ntc_rg223 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg223:
var_hyp_hdr:			dw 0
ntc_rg223_e:
			IF ($ < 32768) && (ntc_rg224_e - ntc_rg224 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg224:
var_hyp_fin:			dw 0
ntc_rg224_e:
			IF ($ < 32768) && (ntc_rg225_e - ntc_rg225 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg225:
var_hyp_fout:			dw 0
ntc_rg225_e:
			IF ($ < 32768) && (ntc_rg226_e - ntc_rg226 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg226:
var_hyp_svbd:			dw 0
ntc_rg226_e:
			IF ($ < 32768) && (ntc_rg227_e - ntc_rg227 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg227:
p_hyp_fileshut_rs:			dw 0
ntc_rg227_e:
			IF ($ < 32768) && (ntc_rg228_e - ntc_rg228 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg228:
var_hyp_fileshut_slot:			dw 0
ntc_rg228_e:
			IF ($ < 32768) && (ntc_rg229_e - ntc_rg229 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg229:
var_hyp_svp:			dw 0
ntc_rg229_e:
			IF ($ < 32768) && (ntc_rg230_e - ntc_rg230 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg230:
p_hyp_svcvars_rs:			dw 0
ntc_rg230_e:
			IF ($ < 32768) && (ntc_rg231_e - ntc_rg231 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg231:
var_hyp_svcvars_vst:			dw 0
ntc_rg231_e:
			IF ($ < 32768) && (ntc_rg232_e - ntc_rg232 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg232:
var_hyp_svcvars_vsg:			dw 0
ntc_rg232_e:
			IF ($ < 32768) && (ntc_rg233_e - ntc_rg233 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg233:
var_hyp_svcvars_vns:			dw 0
ntc_rg233_e:
			IF ($ < 32768) && (ntc_rg234_e - ntc_rg234 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg234:
var_hyp_svcvars_vfr:			dw 0
ntc_rg234_e:
			IF ($ < 32768) && (ntc_rg235_e - ntc_rg235 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg235:
var_hyp_svcvars_vdp:			dw 0
ntc_rg235_e:
			IF ($ < 32768) && (ntc_rg236_e - ntc_rg236 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg236:
var_hyp_svst:			dw 0
ntc_rg236_e:
			IF ($ < 32768) && (ntc_rg237_e - ntc_rg237 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg237:
var_hyp_svsg:			dw 0
ntc_rg237_e:
			IF ($ < 32768) && (ntc_rg238_e - ntc_rg238 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg238:
var_hyp_svns:			dw 0
ntc_rg238_e:
			IF ($ < 32768) && (ntc_rg239_e - ntc_rg239 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg239:
var_hyp_svfr:			dw 0
ntc_rg239_e:
			IF ($ < 32768) && (ntc_rg240_e - ntc_rg240 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg240:
var_hyp_svdp:			dw 0
ntc_rg240_e:
			IF ($ < 32768) && (ntc_rg241_e - ntc_rg241 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg241:
p_hyp_bootdrive_rs:			dw 0
ntc_rg241_e:
			IF ($ < 32768) && (ntc_rg242_e - ntc_rg242 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg242:
var_hyp_bootdrive_d:			dw 0
ntc_rg242_e:
			IF ($ < 32768) && (ntc_rg243_e - ntc_rg243 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg243:
var_hyp_bootdrive_vdv:			dw 0
ntc_rg243_e:
			IF ($ < 32768) && (ntc_rg244_e - ntc_rg244 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg244:
var_hyp_svdv:			dw 0
ntc_rg244_e:
			IF ($ < 32768) && (ntc_rg245_e - ntc_rg245 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg245:
p_hyp_svc_rs:			dw 0
ntc_rg245_e:
			IF ($ < 32768) && (ntc_rg246_e - ntc_rg246 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg246:
var_hyp_svc_t:			dw 0
ntc_rg246_e:
			IF ($ < 32768) && (ntc_rg247_e - ntc_rg247 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg247:
var_hyp_svc_p:			dw 0
ntc_rg247_e:
			IF ($ < 32768) && (ntc_rg248_e - ntc_rg248 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg248:
var_hyp_svc_setting:			dw 0
ntc_rg248_e:
			IF ($ < 32768) && (ntc_rg249_e - ntc_rg249 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg249:
var_hyp_svc_buf:			dw 0
ntc_rg249_e:
			IF ($ < 32768) && (ntc_rg250_e - ntc_rg250 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg250:
var_hyp_pox:			dw 0
ntc_rg250_e:
			IF ($ < 32768) && (ntc_rg251_e - ntc_rg251 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg251:
var_hyp_poy:			dw 0
ntc_rg251_e:
			IF ($ < 32768) && (ntc_rg252_e - ntc_rg252 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg252:
p_hyp_drive_rs:			dw 0
ntc_rg252_e:
			IF ($ < 32768) && (ntc_rg253_e - ntc_rg253 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg253:
var_hyp_drive_letter:			dw 0
ntc_rg253_e:
			IF ($ < 32768) && (ntc_rg254_e - ntc_rg254 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg254:
p_hot_speed_rs:			dw 0
ntc_rg254_e:
			IF ($ < 32768) && (ntc_rg255_e - ntc_rg255 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg255:
var_hot_speed_f:			dw 0
ntc_rg255_e:
			IF ($ < 32768) && (ntc_rg256_e - ntc_rg256 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg256:
var_hot_dbl:			dw 0
ntc_rg256_e:
			IF ($ < 32768) && (ntc_rg257_e - ntc_rg257 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg257:
p_hot_slots_rs:			dw 0
ntc_rg257_e:
			IF ($ < 32768) && (ntc_rg258_e - ntc_rg258 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg258:
var_hot_slots_n:			dw 0
ntc_rg258_e:
			IF ($ < 32768) && (ntc_rg259_e - ntc_rg259 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg259:
var_hot_ns:			dw 0
ntc_rg259_e:
			IF ($ < 32768) && (ntc_rg260_e - ntc_rg260 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg260:
p_hot_tick_rs:			dw 0
ntc_rg260_e:
			IF ($ < 32768) && (ntc_rg261_e - ntc_rg261 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg261:
var_hot_tick_k:			dw 0
ntc_rg261_e:
			IF ($ < 32768) && (ntc_rg262_e - ntc_rg262 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg262:
var_hot_ctl:			dw 0
ntc_rg262_e:
			IF ($ < 32768) && (ntc_rg263_e - ntc_rg263 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg263:
var_keys_down_down:			dw 0
ntc_rg263_e:
			IF ($ < 32768) && (ntc_rg264_e - ntc_rg264 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg264:
var_hot_last:			dw 0
ntc_rg264_e:
			IF ($ < 32768) && (ntc_rg265_e - ntc_rg265 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg265:
var_hot_one:			dw 0
ntc_rg265_e:
			IF ($ < 32768) && (ntc_rg266_e - ntc_rg266 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg266:
var_hot_pend:			dw 0
ntc_rg266_e:
			IF ($ < 32768) && (ntc_rg267_e - ntc_rg267 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg267:
var_hot_age:			dw 0
ntc_rg267_e:
			IF ($ < 32768) && (ntc_rg268_e - ntc_rg268 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg268:
p_hot_take_rs:			dw 0
ntc_rg268_e:
			IF ($ < 32768) && (ntc_rg269_e - ntc_rg269 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg269:
p_hot_control_rs:			dw 0
ntc_rg269_e:
			IF ($ < 32768) && (ntc_rg270_e - ntc_rg270 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg270:
p_hot_held_rs:			dw 0
ntc_rg270_e:
			IF ($ < 32768) && (ntc_rg271_e - ntc_rg271 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg271:
p_v9_probe_rs:			dw 0
ntc_rg271_e:
			IF ($ < 32768) && (ntc_rg272_e - ntc_rg272 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg272:
var_v9_vsp:			dw 0
ntc_rg272_e:
			IF ($ < 32768) && (ntc_rg273_e - ntc_rg273 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg273:
p_v9_init_rs:			dw 0
ntc_rg273_e:
			IF ($ < 32768) && (ntc_rg274_e - ntc_rg274 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg274:
var_v9_init_pal:			dw 0
ntc_rg274_e:
			IF ($ < 32768) && (ntc_rg275_e - ntc_rg275 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg275:
p_memory_bankpage_rs:			dw 0
ntc_rg275_e:
			IF ($ < 32768) && (ntc_rg276_e - ntc_rg276 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg276:
var_memory_bankpage_bank:			dw 0
ntc_rg276_e:
			IF ($ < 32768) && (ntc_rg277_e - ntc_rg277 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg277:
var_memory_bankpage_n:			dw 0
ntc_rg277_e:
			IF ($ < 32768) && (ntc_rg278_e - ntc_rg278 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg278:
tmp0:			dw 0
ntc_rg278_e:
			IF ($ < 32768) && (ntc_rg279_e - ntc_rg279 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg279:
tmp1:			dw 0
ntc_rg279_e:
			IF ($ < 32768) && (ntc_rg280_e - ntc_rg280 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg280:
tmp2:			dw 0
ntc_rg280_e:
			IF ($ < 32768) && (ntc_rg281_e - ntc_rg281 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg281:
tmp3:			dw 0
ntc_rg281_e:
			IF ($ < 32768) && (ntc_rg282_e - ntc_rg282 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg282:
tmp4:			dw 0
ntc_rg282_e:
			IF ($ < 32768) && (ntc_rg283_e - ntc_rg283 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg283:
tmp5:			dw 0
ntc_rg283_e:
			IF ($ < 32768) && (ntc_rg284_e - ntc_rg284 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg284:
tmp6:			dw 0
ntc_rg284_e:
			IF ($ < 32768) && (ntc_rg285_e - ntc_rg285 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg285:
tmp7:			dw 0
ntc_rg285_e:
			IF ($ < 32768) && (ntc_rg286_e - ntc_rg286 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg286:
			db 72			; capacity
stmp0:			ds 73
ntc_rg286_e:
			IF ($ < 32768) && (ntc_rg287_e - ntc_rg287 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg287:
			db 72			; capacity
stmp1:			ds 73
ntc_rg287_e:
			IF ($ < 32768) && (ntc_rg288_e - ntc_rg288 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg288:
ltmp0:			dw 0, 0
ntc_rg288_e:
			IF ($ < 32768) && (ntc_rg289_e - ntc_rg289 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg289:
ltmp1:			dw 0, 0
ntc_rg289_e:
			IF ($ < 32768) && (ntc_rg290_e - ntc_rg290 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg290:
ltmp2:			dw 0, 0

; numbers passed by address (read only)
ntc_rg290_e:
			IF ($ < 32768) && (ntc_rg291_e - ntc_rg291 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg291:
lit_0:			dw 0
ntc_rg291_e:
			IF ($ < 32768) && (ntc_rg292_e - ntc_rg292 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg292:
lit_1:			dw 1
ntc_rg292_e:
			IF ($ < 32768) && (ntc_rg293_e - ntc_rg293 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg293:
lit_85:			dw 85
ntc_rg293_e:
			IF ($ < 32768) && (ntc_rg294_e - ntc_rg294 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg294:
vp_arr_st:			dw arr_st
ntc_rg294_e:
			IF ($ < 32768) && (ntc_rg295_e - ntc_rg295 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg295:
vp_arr_sg:			dw arr_sg
ntc_rg295_e:
			IF ($ < 32768) && (ntc_rg296_e - ntc_rg296 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg296:
vp_var_ns:			dw var_ns
ntc_rg296_e:
			IF ($ < 32768) && (ntc_rg297_e - ntc_rg297 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg297:
vp_var_front:			dw var_front
ntc_rg297_e:
			IF ($ < 32768) && (ntc_rg298_e - ntc_rg298 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg298:
vp_var_dp:			dw var_dp
ntc_rg298_e:
			IF ($ < 32768) && (ntc_rg299_e - ntc_rg299 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg299:
vp_arr_rb:			dw arr_rb
ntc_rg299_e:
			IF ($ < 32768) && (ntc_rg300_e - ntc_rg300 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg300:
lit_99:			dw 99
ntc_rg300_e:
			IF ($ < 32768) && (ntc_rg301_e - ntc_rg301 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg301:
lit_255:			dw 255
ntc_rg301_e:
			IF ($ < 32768) && (ntc_rg302_e - ntc_rg302 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg302:
vp_arr_dv:			dw arr_dv
ntc_rg302_e:
			IF ($ < 32768) && (ntc_rg303_e - ntc_rg303 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg303:
vp_var_dn:			dw var_dn
ntc_rg303_e:
			IF ($ < 32768) && (ntc_rg304_e - ntc_rg304 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg304:
lit_100:			dw 100
ntc_rg304_e:
			IF ($ < 32768) && (ntc_rg305_e - ntc_rg305 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg305:
lit_103:			dw 103
ntc_rg305_e:
			IF ($ < 32768) && (ntc_rg306_e - ntc_rg306 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg306:
lit_m4864:			dw -4864
ntc_rg306_e:
			IF ($ < 32768) && (ntc_rg307_e - ntc_rg307 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg307:
lit_256:			dw 256
ntc_rg307_e:
			IF ($ < 32768) && (ntc_rg308_e - ntc_rg308 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg308:
lit_102:			dw 102
ntc_rg308_e:
			IF ($ < 32768) && (ntc_rg309_e - ntc_rg309 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg309:
lit_128:			dw 128
ntc_rg309_e:
			IF ($ < 32768) && (ntc_rg310_e - ntc_rg310 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg310:
lit_m1:			dw -1
ntc_rg310_e:
			IF ($ < 32768) && (ntc_rg311_e - ntc_rg311 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg311:
vp_arr_kd:			dw arr_kd
ntc_rg311_e:
			IF ($ < 32768) && (ntc_rg312_e - ntc_rg312 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg312:
lit_32:			dw 32
ntc_rg312_e:
			IF ($ < 32768) && (ntc_rg313_e - ntc_rg313 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg313:
vp_var_en:			dw var_en
ntc_rg313_e:
			IF ($ < 32768) && (ntc_rg314_e - ntc_rg314 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg314:
lit_m2560:			dw -2560
ntc_rg314_e:
			IF ($ < 32768) && (ntc_rg315_e - ntc_rg315 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg315:
lit_2:			dw 2
ntc_rg315_e:
			IF ($ < 32768) && (ntc_rg316_e - ntc_rg316 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg316:
lit_34:			dw 34
ntc_rg316_e:
			IF ($ < 32768) && (ntc_rg317_e - ntc_rg317 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg317:
lit_110:			dw 110
ntc_rg317_e:
			IF ($ < 32768) && (ntc_rg318_e - ntc_rg318 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg318:
lit_116:			dw 116
ntc_rg318_e:
			IF ($ < 32768) && (ntc_rg319_e - ntc_rg319 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg319:
llit_65536:			dw 0, 1
ntc_rg319_e:
			IF ($ < 32768) && (ntc_rg320_e - ntc_rg320 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg320:
lit_3:			dw 3
ntc_rg320_e:
			IF ($ < 32768) && (ntc_rg321_e - ntc_rg321 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg321:
lit_m4352:			dw -4352
ntc_rg321_e:
			IF ($ < 32768) && (ntc_rg322_e - ntc_rg322 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg322:
lit_4096:			dw 4096
ntc_rg322_e:
			IF ($ < 32768) && (ntc_rg323_e - ntc_rg323 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg323:
lit_m3328:			dw -3328
ntc_rg323_e:
			IF ($ < 32768) && (ntc_rg324_e - ntc_rg324 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg324:
lit_768:			dw 768
ntc_rg324_e:
			IF ($ < 32768) && (ntc_rg325_e - ntc_rg325 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg325:
lit_m2432:			dw -2432
ntc_rg325_e:
			IF ($ < 32768) && (ntc_rg326_e - ntc_rg326 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg326:
lit_m2431:			dw -2431
ntc_rg326_e:
			IF ($ < 32768) && (ntc_rg327_e - ntc_rg327 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg327:
lit_59:			dw 59
ntc_rg327_e:
			IF ($ < 32768) && (ntc_rg328_e - ntc_rg328 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg328:
lit_32704:			dw 32704
ntc_rg328_e:
			IF ($ < 32768) && (ntc_rg329_e - ntc_rg329 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg329:
lit_61:			dw 61
ntc_rg329_e:
			IF ($ < 32768) && (ntc_rg330_e - ntc_rg330 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg330:
lit_m2427:			dw -2427
ntc_rg330_e:
			IF ($ < 32768) && (ntc_rg331_e - ntc_rg331 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg331:
lit_m3332:			dw -3332
ntc_rg331_e:
			IF ($ < 32768) && (ntc_rg332_e - ntc_rg332 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg332:
lit_4:			dw 4
ntc_rg332_e:
			IF ($ < 32768) && (ntc_rg333_e - ntc_rg333 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg333:
lit_m3330:			dw -3330
ntc_rg333_e:
			IF ($ < 32768) && (ntc_rg334_e - ntc_rg334 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg334:
lit_m2:			dw -2
ntc_rg334_e:
			IF ($ < 32768) && (ntc_rg335_e - ntc_rg335 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg335:
lit_23:			dw 23
ntc_rg335_e:
			IF ($ < 32768) && (ntc_rg336_e - ntc_rg336 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg336:
lit_64:			dw 64
ntc_rg336_e:
			IF ($ < 32768) && (ntc_rg337_e - ntc_rg337 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg337:
lit_65:			dw 65
ntc_rg337_e:
			IF ($ < 32768) && (ntc_rg338_e - ntc_rg338 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg338:
lit_57:			dw 57
ntc_rg338_e:
			IF ($ < 32768) && (ntc_rg339_e - ntc_rg339 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg339:
lit_56:			dw 56
ntc_rg339_e:
			IF ($ < 32768) && (ntc_rg340_e - ntc_rg340 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg340:
lit_49:			dw 49
ntc_rg340_e:
			IF ($ < 32768) && (ntc_rg341_e - ntc_rg341 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg341:
lit_48:			dw 48
ntc_rg341_e:
			IF ($ < 32768) && (ntc_rg342_e - ntc_rg342 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg342:
lit_41:			dw 41
ntc_rg342_e:
			IF ($ < 32768) && (ntc_rg343_e - ntc_rg343 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg343:
lit_40:			dw 40
ntc_rg343_e:
			IF ($ < 32768) && (ntc_rg344_e - ntc_rg344 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg344:
lit_33:			dw 33
ntc_rg344_e:
			IF ($ < 32768) && (ntc_rg345_e - ntc_rg345 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg345:
lit_66:			dw 66

ntc_rg345_e:
			IF ($ < 32768) && (ntc_rg346_e - ntc_rg346 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg346:
; ============================================================
; Strings
; ============================================================

ntc_rg346_e:
			IF ($ < 32768) && (ntc_rg347_e - ntc_rg347 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg347:
str0:			db "CyborgOS needs 320K (a 256K expansion) or more", 0
ntc_rg347_e:
			IF ($ < 32768) && (ntc_rg348_e - ntc_rg348 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg348:
str1:			db "Press a key", 0
ntc_rg348_e:
			IF ($ < 32768) && (ntc_rg349_e - ntc_rg349 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg349:
str2:			db 0
ntc_rg349_e:
			IF ($ < 32768) && (ntc_rg350_e - ntc_rg350 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg350:
str3:			db " KEYREP ", 0
ntc_rg350_e:
			IF ($ < 32768) && (ntc_rg351_e - ntc_rg351 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg351:
str4:			db " NOV9990", 0
ntc_rg351_e:
			IF ($ < 32768) && (ntc_rg352_e - ntc_rg352 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg352:
str5:			db "KERNEL.CYB", 0
ntc_rg352_e:
			IF ($ < 32768) && (ntc_rg353_e - ntc_rg353 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg353:
str6:			db "CyborgOS: no KERNEL.CYB on ", 0
ntc_rg353_e:
			IF ($ < 32768) && (ntc_rg354_e - ntc_rg354 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg354:
str7:			db ":", 0
ntc_rg354_e:
			IF ($ < 32768) && (ntc_rg355_e - ntc_rg355 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg355:
str8:			db "CyborgOS: the kernel ended", 0
ntc_rg355_e:
			IF ($ < 32768) && (ntc_rg356_e - ntc_rg356 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg356:
str9:			db "CyborgOS ended, ", 0
ntc_rg356_e:
			IF ($ < 32768) && (ntc_rg357_e - ntc_rg357 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg357:
str10:			db " programs ran", 0

ntc_rg357_e:
			IF ($ < 32768) && (ntc_rg358_e - ntc_rg358 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg358:
; ============================================================
; Keyword library (used)
; ============================================================

ntc_rg358_e:
			IF ($ < 32768) && (ntc_rg359_e - ntc_rg359 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg359:
;## ntc_data @shared ntc_d_nmode
; ------------------------------------------------------------
; Scratch space: the core every program has (with ntc_d_nmode). The rest of
; the run time's variables are @data sections, each linked only when a
; linked section's code names one of its labels (no header lists them).
; They stay in this order: the keyword ROM's registry keeps each variable's
; address (a Library: ROM program has them as fixed addresses)
; ------------------------------------------------------------
ntc_next:		ret				; IX target that continues the thread
ntc_csp:		dw 0			; caller SP, for kw_stop (and the normal mode stack)
ntc_ip:			dw 0			; normal mode: thread position while out of the thread

ntc_rg359_e:
			IF ($ < 32768) && (ntc_rg360_e - ntc_rg360 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg360:
;## ntc_d_gnlo @data
ntc_gnlo:		db 0			; ntc_getn: low byte

ntc_rg360_e:
			IF ($ < 32768) && (ntc_rg361_e - ntc_rg361 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg361:
;## ntc_d_nmode @data
ntc_nmode:		db 0			; 1 = running in normal mode (waits let interrupts in)

ntc_rg361_e:
			IF ($ < 32768) && (ntc_rg362_e - ntc_rg362 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg362:
;## ntc_d_div @data
ntc_mode:		db 0			; div mode 0=quotient 1=remainder
ntc_sgnq:		db 0			; quotient sign (bit 7)
ntc_sgnr:		db 0			; remainder sign (bit 7)

ntc_rg362_e:
			IF ($ < 32768) && (ntc_rg363_e - ntc_rg363 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg363:
;## ntc_d_lead @data
ntc_lead:		db 0			; printint: digit seen

ntc_rg363_e:
			IF ($ < 32768) && (ntc_rg364_e - ntc_rg364 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg364:
;## ntc_d_sptr @data
ntc_sptr:		dw 0			; printbuf: text pointer

ntc_rg364_e:
			IF ($ < 32768) && (ntc_rg365_e - ntc_rg365 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg365:
;## ntc_d_iptr @data
ntc_iptr:		dw 0			; gets: buffer pointer
ntc_ilink:		dw 0			; gets: where to go when done

ntc_rg365_e:
			IF ($ < 32768) && (ntc_rg366_e - ntc_rg366 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg366:
;## ntc_d_ivar @data
ntc_ivar:		dw 0			; inputint / inkey: dest var

ntc_rg366_e:
			IF ($ < 32768) && (ntc_rg367_e - ntc_rg367 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg367:
;## ntc_d_aptr @data
ntc_aptr:		dw 0			; atoi: text pointer

ntc_rg367_e:
			IF ($ < 32768) && (ntc_rg368_e - ntc_rg368 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg368:
;## ntc_d_hook @data
ntc_hookon:		db 0			; 1 = the Interrupt hook may run (set, and not running now)
ntc_hookset:	db 0			; 1 = an Interrupt hook is set
ntc_hookpend:	db 0			; 1 = an interrupt came, the hook runs at the next safe point
ntc_hook:		dw 0			; the hook Sub's call stub

ntc_rg368_e:
			IF ($ < 32768) && (ntc_rg369_e - ntc_rg369 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg369:
;## ntc_d_hostix @data
ntc_hostix:		dw 0			; host platforms: IX kept over a firmware / BDOS call

ntc_rg369_e:
			IF ($ < 32768) && (ntc_rg370_e - ntc_rg370 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg370:
;## ntc_d_rampt @data
ntc_rampt:		dw #7FC0		; the gate array's RAM setting now (B = port, C = value): the
								; Memory class keeps it, Graphics puts it back after drawing

ntc_rg370_e:
			IF ($ < 32768) && (ntc_rg371_e - ntc_rg371 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg371:
;## ntc_d_numbuf @data
ntc_numbuf:		ds 14			; printint / long print: digits (+ spaces for Option VBPrint)

ntc_rg371_e:
			IF ($ < 32768) && (ntc_rg372_e - ntc_rg372 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg372:
;## ntc_d_inbuf @data
				db 40			; ntc_inbuf's capacity (as every string variable has)
ntc_inbuf:		ds 41			; inputint: typed text

ntc_rg372_e:
			IF ($ < 32768) && (ntc_rg373_e - ntc_rg373 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg373:
;## kw_stop ntc_data ntc_plat_exit @shared
kw_stop:
			ld ix, ntc_stop_back
			jp ntc_plat_exit
ntc_stop_back:
			ld sp, (ntc_csp)
			ei
			ret

ntc_rg373_e:
			IF ($ < 32768) && (ntc_rg374_e - ntc_rg374 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg374:
;## kw_waitkey ntc_data ntc_plat_key
; kw_waitkey - wait for a key (Option PressAnyKeyOnEnd, before kw_stop)
kw_waitkey:
			ld ix, ntc_next
			jp ntc_plat_getkey

ntc_rg374_e:
			IF ($ < 32768) && (ntc_rg375_e - ntc_rg375 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg375:
;## ntc_xnh ntc_data ntc_islots @shared
; ntc_xn for a program with an Interrupt hook (Interrupt MySub) or interrupt
; classes (Option Class Interrupt): the same window, then a pending hook
; runs as a call of the hook Sub from this point (its return goes back into
; the thread), else a due class's Tick (not one still running). Flags are
; kept when nothing runs. Linked instead of ntc_xn.
ntc_xn:
			ld (ntc_ip), sp
			ld sp, (ntc_csp)
			ei
			nop					; an interrupt can be taken here
			di
			push af
			ld a, (ntc_hookpend)
			or a
			jr nz, ntc_xn_hookp
			ld a, (ntc_isldue)
			or a
			jr nz, ntc_xn_isl
ntc_xn_none:
			pop af
			ld sp, (ntc_ip)
			ret
ntc_xn_isl:
			ld hl, ntc_isl + 4		; the first slot due and not running
			ld a, (ntc_isln)
			ld b, a
			ld c, 0					; due but still running: stays due
ntc_xi_lp:
			ld a, (hl)
			or a
			jr nz, ntc_xi_skip
			inc hl
			ld a, (hl)
			dec hl
			or a
			jr nz, ntc_xi_run
ntc_xi_skip:
			inc hl
			ld a, (hl)
			dec hl
			or c
			ld c, a
			ld de, 8
			add hl, de
			djnz ntc_xi_lp
			ld a, c
			ld (ntc_isldue), a
			jr ntc_xn_none
ntc_xi_run:
			ld (hl), 1				; running (its return stub clears it)
			inc hl
			ld (hl), 0				; not due
			inc hl
			ld e, (hl)				; Tick's call stub
			inc hl
			ld d, (hl)
			pop af
			ld sp, (ntc_ip)
			ex de, hl
			jp (hl)
ntc_xn_hookp:
			pop af
ntc_xn_hook:
			xor a
			ld (ntc_hookpend), a
			ld (ntc_hookon), a	; not again until the hook returns
			ld sp, (ntc_ip)
			ld hl, (ntc_hook)
			jp (hl)

ntc_rg375_e:
			IF ($ < 32768) && (ntc_rg376_e - ntc_rg376 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg376:
;## kw_goto_iffalse (normal mode copy)
;kw_goto_iffalse, <label>  - branch if NZ (false)
kw_goto_iffalse_n:
			pop hl
			jp z, ntc_xn
			ld sp, hl
			jp ntc_xn

ntc_rg376_e:
			IF ($ < 32768) && (ntc_rg377_e - ntc_rg377 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg377:
;## kw_goto_iftrue (normal mode copy)
;kw_goto_iftrue, <label>  - branch if Z (true)
kw_goto_iftrue_n:
			pop hl
			jp nz, ntc_xn
			ld sp, hl
			jp ntc_xn

ntc_rg377_e:
			IF ($ < 32768) && (ntc_rg378_e - ntc_rg378 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg378:
;## kw_goto_ifzero (normal mode copy)
;kw_goto_ifzero, <var>, <label>  - branch if var = 0
kw_goto_ifzero_n:
			pop hl
			ld a, (hl)
			inc hl
			or (hl)
			pop hl
			jp nz, ntc_xn
			ld sp, hl
			jp ntc_xn

ntc_rg378_e:
			IF ($ < 32768) && (ntc_rg379_e - ntc_rg379 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg379:
;## ntc_for_jump (normal mode copy)
; tails for the FOR / NEXT keywords. DE = var value, HL = limit,
; SP = thread at the label word. Signed compare by flipping bit 15.
; ntc_for_gt: jump to the label if var > limit, else skip it
ntc_for_gt_n:
			ld a, d
			xor #80
			ld d, a
			ld a, h
			xor #80
			ld h, a
			or a
			sbc hl, de			; limit - var, carry = var > limit
			pop hl
			jp nc, ntc_xn
			ld sp, hl
			jp ntc_xn
; ntc_for_lt: jump to the label if var < limit, else skip it
ntc_for_lt_n:
			ld a, d
			xor #80
			ld d, a
			ld a, h
			xor #80
			ld h, a
			ex de, hl
			or a
			sbc hl, de			; var - limit, carry = var < limit
			pop hl
			jp nc, ntc_xn
			ld sp, hl
			jp ntc_xn
; ntc_for_le: jump to the label if var <= limit (loop again). A not 0: the
; step took var past 32767 (or -32768): the loop ends (ntc_for_ge too)
ntc_for_le_n:
			or a
			jr nz, ntc_for_end_n
			ld a, d
			xor #80
			ld d, a
			ld a, h
			xor #80
			ld h, a
			or a
			sbc hl, de			; limit - var, no carry = var <= limit
			pop hl
			jp c, ntc_xn
			ld sp, hl
			jp ntc_xn
; ntc_for_ge: jump to the label if var >= limit (loop again)
ntc_for_ge_n:
			or a
			jr nz, ntc_for_end_n
			ld a, d
			xor #80
			ld d, a
			ld a, h
			xor #80
			ld h, a
			ex de, hl
			or a
			sbc hl, de			; var - limit, no carry = var >= limit
			pop hl
			jp c, ntc_xn
			ld sp, hl
			jp ntc_xn
ntc_for_end_n:
			pop hl
			jp ntc_xn

ntc_rg379_e:
			IF ($ < 32768) && (ntc_rg380_e - ntc_rg380 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg380:
;## kw_forupv (normal mode copy) ntc_for_jump
;kw_forupv, <var>, <limit var>, <endlabel>
kw_forupv_n:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			jp ntc_for_gt_n

ntc_rg380_e:
			IF ($ < 32768) && (ntc_rg381_e - ntc_rg381 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg381:
;## kw_next1l (normal mode copy) ntc_for_jump
;kw_next1l, <var>, <literal limit>, <toplabel>
;  NEXT for STEP 1: inc var, back to the top while var <= limit
kw_next1l_n:
			pop hl
			inc (hl)
			ld e, (hl)
			inc hl
			jr nz, ntc_n1l_nc_n
			inc (hl)
ntc_n1l_nc_n:
			ld d, (hl)
			pop hl
			ld a, d					; A = #FF when it went past 32767 (#8000)
			xor #80
			or e
			sub 1
			sbc a, a
			jp ntc_for_le_n

ntc_rg381_e:
			IF ($ < 32768) && (ntc_rg382_e - ntc_rg382 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg382:
;## kw_next1v (normal mode copy) ntc_for_jump
;kw_next1v, <var>, <limit var>, <toplabel>
kw_next1v_n:
			pop hl
			inc (hl)
			ld e, (hl)
			inc hl
			jr nz, ntc_n1v_nc_n
			inc (hl)
ntc_n1v_nc_n:
			ld d, (hl)
			pop hl
			ld c, (hl)
			inc hl
			ld h, (hl)
			ld l, c
			ld a, d					; A = #FF when it went past 32767 (#8000)
			xor #80
			or e
			sub 1
			sbc a, a
			jp ntc_for_le_n

ntc_rg382_e:
			IF ($ < 32768) && (ntc_rg383_e - ntc_rg383 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg383:
;## kw_ltov
;kw_ltov, <literal>, <destvar>
kw_ltov:
			pop de
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg383_e:
			IF ($ < 32768) && (ntc_rg384_e - ntc_rg384 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg384:
;## kw_vtov
;kw_vtov, <sourcevar>, <destvar>
kw_vtov:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg384_e:
			IF ($ < 32768) && (ntc_rg385_e - ntc_rg385 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg385:
;## kw_ztov
;kw_ztov, <destvar>
kw_ztov:
			xor a
			pop hl
			ld (hl), a
			inc hl
			ld (hl), a
			ret

ntc_rg385_e:
			IF ($ < 32768) && (ntc_rg386_e - ntc_rg386 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg386:
;## kw_ftov
;kw_ftov, <destvar>  - Z flag to var: true = -1, false = 0
kw_ftov:
			pop hl
			jr z, ntc_ftov_t
			ld (hl), 0
			inc hl
			ld (hl), 0
			ret
ntc_ftov_t:
			ld (hl), #ff
			inc hl
			ld (hl), #ff
			ret

; ============================================================
; Arithmetic
; ============================================================

ntc_rg386_e:
			IF ($ < 32768) && (ntc_rg387_e - ntc_rg387 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg387:
;## kw_inc
;kw_inc, <var>
kw_inc:
			pop hl
			inc (hl)
			ret nz
			inc hl
			inc (hl)
			ret

ntc_rg387_e:
			IF ($ < 32768) && (ntc_rg388_e - ntc_rg388 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg388:
;## kw_add
;kw_add, <var1>, <var2>, <destvar>
kw_add:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			add hl, de
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg388_e:
			IF ($ < 32768) && (ntc_rg389_e - ntc_rg389 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg389:
;## kw_addl
;kw_addl, <var>, <literal>, <destvar>
kw_addl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			add hl, de
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg389_e:
			IF ($ < 32768) && (ntc_rg390_e - ntc_rg390 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg390:
;## kw_2x
;kw_2x, <var>, <destvar>
kw_2x:
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			add hl, hl
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg390_e:
			IF ($ < 32768) && (ntc_rg391_e - ntc_rg391 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg391:
;## kw_4x
;kw_4x, <var>, <destvar>
kw_4x:
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			add hl, hl
			add hl, hl
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg391_e:
			IF ($ < 32768) && (ntc_rg392_e - ntc_rg392 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg392:
;## ntc_mul
; BC * DE -> pop destvar, store. Low 16 bits (same signed/unsigned)
ntc_mul:
			ld hl, 0
			ld a, 16
ntc_mul_loop:
			add hl, hl
			sla e
			rl d
			jr nc, ntc_mul_skip
			add hl, bc
ntc_mul_skip:
			dec a
			jr nz, ntc_mul_loop
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg392_e:
			IF ($ < 32768) && (ntc_rg393_e - ntc_rg393 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg393:
;## kw_mulvl ntc_mul
;kw_mulvl, <var>, <literal>, <destvar>
kw_mulvl:
			pop hl
			ld c, (hl)
			inc hl
			ld b, (hl)
			pop de
			jp ntc_mul

ntc_rg393_e:
			IF ($ < 32768) && (ntc_rg394_e - ntc_rg394 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg394:
;## ntc_div ntc_data
; HL / DE signed, truncating. (ntc_mode) 0 = quotient, 1 = remainder.
; Remainder takes the dividend's sign. Divide by zero gives
; quotient 0, remainder = dividend. Pops destvar and stores.
ntc_div:
			ld a, d
			or e
			jr nz, ntc_div_nz
			ld a, (ntc_mode)
			or a
			jr nz, ntc_div_store
			ld hl, 0
			jr ntc_div_store
ntc_div_nz:
			ld a, h
			ld (ntc_sgnr), a
			xor d
			ld (ntc_sgnq), a
			bit 7, h
			jr z, ntc_div_hpos
			xor a
			sub l
			ld l, a
			sbc a, a
			sub h
			ld h, a
ntc_div_hpos:
			bit 7, d
			jr z, ntc_div_dpos
			xor a
			sub e
			ld e, a
			sbc a, a
			sub d
			ld d, a
ntc_div_dpos:
			ld a, h
			ld c, l
			ld hl, 0
			ld b, 16
ntc_div_loop:
			sla c
			rla
			adc hl, hl
			sbc hl, de
			jr nc, ntc_div_one
			add hl, de
			djnz ntc_div_loop
			jr ntc_div_done
ntc_div_one:
			inc c
			djnz ntc_div_loop
ntc_div_done:
			ld b, a
			ld a, (ntc_mode)
			or a
			jr z, ntc_div_q
			ld a, (ntc_sgnr)
			jr ntc_div_sign
ntc_div_q:
			ld h, b
			ld l, c
			ld a, (ntc_sgnq)
ntc_div_sign:
			rla
			jr nc, ntc_div_store
			xor a
			sub l
			ld l, a
			sbc a, a
			sub h
			ld h, a
ntc_div_store:
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg394_e:
			IF ($ < 32768) && (ntc_rg395_e - ntc_rg395 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg395:
;## kw_divvl ntc_div
;kw_divvl, <var>, <literal>, <destvar>
kw_divvl:
			xor a
			ld (ntc_mode), a
ntc_divvl:
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			pop de
			jp ntc_div

ntc_rg395_e:
			IF ($ < 32768) && (ntc_rg396_e - ntc_rg396 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg396:
;## kw_andvv
;kw_andvv, <var1>, <var2>, <destvar>
kw_andvv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			and e
			ld e, a
			inc hl
			ld a, (hl)
			and d
			ld d, a
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg396_e:
			IF ($ < 32768) && (ntc_rg397_e - ntc_rg397 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg397:
;## kw_andvl
;kw_andvl, <var>, <literal>, <destvar>
kw_andvl:
			pop hl
			pop de
			ld a, (hl)
			and e
			ld e, a
			inc hl
			ld a, (hl)
			and d
			ld d, a
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg397_e:
			IF ($ < 32768) && (ntc_rg398_e - ntc_rg398 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg398:
;## kw_orvv
;kw_orvv, <var1>, <var2>, <destvar>
kw_orvv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			or e
			ld e, a
			inc hl
			ld a, (hl)
			or d
			ld d, a
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg398_e:
			IF ($ < 32768) && (ntc_rg399_e - ntc_rg399 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg399:
;## kw_orvl
;kw_orvl, <var>, <literal>, <destvar>
kw_orvl:
			pop hl
			pop de
			ld a, (hl)
			or e
			ld e, a
			inc hl
			ld a, (hl)
			or d
			ld d, a
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg399_e:
			IF ($ < 32768) && (ntc_rg400_e - ntc_rg400 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg400:
;## ntc_cmp
ntc_cmp_slt:
			ld a, d
			xor #80
			ld d, a
			ld a, h
			xor #80
			ld h, a
ntc_cmp_ult:
			ex de, hl
			or a
			sbc hl, de
			sbc a, a
			inc a
			ret
ntc_cmp_sge:
			ld a, d
			xor #80
			ld d, a
			ld a, h
			xor #80
			ld h, a
ntc_cmp_uge:
			ex de, hl
			or a
			sbc hl, de
			sbc a, a
			ret
ntc_cmp_sgt:
			ld a, d
			xor #80
			ld d, a
			ld a, h
			xor #80
			ld h, a
ntc_cmp_ugt:
			or a
			sbc hl, de
			sbc a, a
			inc a
			ret
ntc_cmp_sle:
			ld a, d
			xor #80
			ld d, a
			ld a, h
			xor #80
			ld h, a
ntc_cmp_ule:
			or a
			sbc hl, de
			sbc a, a
			ret
ntc_cmp_eq:
			or a
			sbc hl, de
			ret
ntc_cmp_ne:
			or a
			sbc hl, de
			jr z, ntc_cmp_ne_f
			xor a
			ret
ntc_cmp_ne_f:
			or 1
			ret

ntc_rg400_e:
			IF ($ < 32768) && (ntc_rg401_e - ntc_rg401 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg401:
;## kw_scpltvv ntc_cmp
;kw_scpltvv, <var1>, <var2>  - signed var1 < var2
kw_scpltvv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			jp ntc_cmp_slt

ntc_rg401_e:
			IF ($ < 32768) && (ntc_rg402_e - ntc_rg402 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg402:
;## kw_scpltvl ntc_cmp
;kw_scpltvl, <var>, <literal>
kw_scpltvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_slt

ntc_rg402_e:
			IF ($ < 32768) && (ntc_rg403_e - ntc_rg403 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg403:
;## kw_scplevv ntc_cmp
kw_scplevv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			jp ntc_cmp_sle

ntc_rg403_e:
			IF ($ < 32768) && (ntc_rg404_e - ntc_rg404 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg404:
;## kw_scplevl ntc_cmp
kw_scplevl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sle

ntc_rg404_e:
			IF ($ < 32768) && (ntc_rg405_e - ntc_rg405 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg405:
;## kw_scpgtvv ntc_cmp
kw_scpgtvv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			jp ntc_cmp_sgt

ntc_rg405_e:
			IF ($ < 32768) && (ntc_rg406_e - ntc_rg406 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg406:
;## kw_scpgtvl ntc_cmp
kw_scpgtvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sgt

ntc_rg406_e:
			IF ($ < 32768) && (ntc_rg407_e - ntc_rg407 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg407:
;## kw_scpgevv ntc_cmp
kw_scpgevv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			jp ntc_cmp_sge

ntc_rg407_e:
			IF ($ < 32768) && (ntc_rg408_e - ntc_rg408 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg408:
;## kw_scpgevl ntc_cmp
kw_scpgevl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sge

ntc_rg408_e:
			IF ($ < 32768) && (ntc_rg409_e - ntc_rg409 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg409:
;## kw_cpeqvv ntc_cmp
;kw_cpeqvv, <var1>, <var2>
kw_cpeqvv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			jp ntc_cmp_eq

ntc_rg409_e:
			IF ($ < 32768) && (ntc_rg410_e - ntc_rg410 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg410:
;## kw_cpeqvl ntc_cmp
kw_cpeqvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_eq

ntc_rg410_e:
			IF ($ < 32768) && (ntc_rg411_e - ntc_rg411 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg411:
;## kw_cpnevv ntc_cmp
kw_cpnevv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			jp ntc_cmp_ne

ntc_rg411_e:
			IF ($ < 32768) && (ntc_rg412_e - ntc_rg412 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg412:
;## kw_cpnevl ntc_cmp
kw_cpnevl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_ne

; ============================================================
; Memory (PEEK / POKE / DEEK / DOKE)
; ============================================================

ntc_rg412_e:
			IF ($ < 32768) && (ntc_rg413_e - ntc_rg413 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg413:
;## kw_lptrtov8
;kw_lptrtov8, <literaladdr>, <destvar>  - PEEK(literal)
kw_lptrtov8:
			pop hl
			ld a, (hl)
			pop hl
			ld (hl), a
			inc hl
			ld (hl), 0
			ret

ntc_rg413_e:
			IF ($ < 32768) && (ntc_rg414_e - ntc_rg414 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg414:
;## kw_vptrtov8
;kw_vptrtov8, <addrvar>, <destvar>  - PEEK(var)
kw_vptrtov8:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld a, (de)
			pop hl
			ld (hl), a
			inc hl
			ld (hl), 0
			ret

ntc_rg414_e:
			IF ($ < 32768) && (ntc_rg415_e - ntc_rg415 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg415:
;## kw_ltolptr8
;kw_ltolptr8, <literal>, <literaladdr>  - POKE literal, literal
kw_ltolptr8:
			pop bc
			pop hl
			ld (hl), c
			ret

ntc_rg415_e:
			IF ($ < 32768) && (ntc_rg416_e - ntc_rg416 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg416:
;## kw_aget
;kw_aget, <arraybase>, <indexvar>, <destvar>
kw_aget:
			pop de
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			add hl, hl
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg416_e:
			IF ($ < 32768) && (ntc_rg417_e - ntc_rg417 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg417:
;## kw_aset
;kw_aset, <arraybase>, <indexvar>, <sourcevar>
kw_aset:
			pop de
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			add hl, hl
			add hl, de
			ex de, hl
			pop hl
			ld c, (hl)
			inc hl
			ld b, (hl)
			ex de, hl
			ld (hl), c
			inc hl
			ld (hl), b
			ret

ntc_rg417_e:
			IF ($ < 32768) && (ntc_rg418_e - ntc_rg418 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg418:
;## kw_asetl
;kw_asetl, <arraybase>, <indexvar>, <literal>
kw_asetl:
			pop de
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			add hl, hl
			add hl, de
			pop bc
			ld (hl), c
			inc hl
			ld (hl), b
			ret

; ============================================================
; Random (16 bit xorshift 7,9,8 - period 65535)
; ============================================================

ntc_rg418_e:
			IF ($ < 32768) && (ntc_rg419_e - ntc_rg419 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg419:
;## kw_strcpy
;kw_strcpy, <destaddr>, <srcaddr>  - cut at the destination's capacity byte
kw_strcpy:
			pop de
			pop hl
			dec de
			ld a, (de)
			ld b, a
			inc de
ntc_strcpy_loop:
			ld a, (hl)
			ld (de), a
			or a
			ret z
			inc hl
			inc de
			djnz ntc_strcpy_loop
			xor a
			ld (de), a
			ret

ntc_rg419_e:
			IF ($ < 32768) && (ntc_rg420_e - ntc_rg420 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg420:
;## kw_strcat
;kw_strcat, <destaddr>, <srcaddr>  - cut at the destination's capacity byte
kw_strcat:
			pop de
			dec de
			ld a, (de)
			ld b, a
			inc de
ntc_strcat_end:
			ld a, (de)
			or a
			jr z, ntc_strcat_copy
			inc de
			djnz ntc_strcat_end
			pop hl
			ret
ntc_strcat_copy:
			pop hl
ntc_strcat_loop:
			ld a, (hl)
			ld (de), a
			or a
			ret z
			inc hl
			inc de
			djnz ntc_strcat_loop
			xor a
			ld (de), a
			ret

ntc_rg420_e:
			IF ($ < 32768) && (ntc_rg421_e - ntc_rg421 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg421:
;## kw_strlen
;kw_strlen, <straddr>, <destvar>
kw_strlen:
			pop hl
			ld bc, 0
ntc_strlen_loop:
			ld a, (hl)
			or a
			jr z, ntc_strlen_done
			inc hl
			inc c
			jr ntc_strlen_loop
ntc_strlen_done:
			pop hl
			ld (hl), c
			inc hl
			ld (hl), b
			ret

ntc_rg421_e:
			IF ($ < 32768) && (ntc_rg422_e - ntc_rg422 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg422:
;## kw_strcmpne
;kw_strcmpne, <addr1>, <addr2>  - Z if not equal
kw_strcmpne:
			pop de
			pop hl
ntc_strne_loop:
			ld a, (de)
			cp (hl)
			jr nz, ntc_strne_t
			or a
			jr z, ntc_strne_f
			inc hl
			inc de
			jr ntc_strne_loop
ntc_strne_t:
			xor a
			ret
ntc_strne_f:
			inc a
			ret

; ============================================================
; I/O - no firmware, no call, no push. SP stays in the thread.
; Shared routines are entered with jp and the return address in
; IX, and end with jp (ix). Keywords that are done use
; ld ix, ntc_next (a ret) so the routine continues the thread.
; ============================================================

ntc_rg422_e:
			IF ($ < 32768) && (ntc_rg423_e - ntc_rg423 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg423:
;## ntc_printbuf ntc_data ntc_plat_screen
; print the 0 terminated ASCII text at (ntc_sptr), then ret (thread)
ntc_printbuf:
			ld hl, (ntc_sptr)
			ld a, (hl)
			or a
			ret z
			inc hl
			ld (ntc_sptr), hl
			ld ix, ntc_printbuf
			jp ntc_plat_putc

ntc_rg423_e:
			IF ($ < 32768) && (ntc_rg424_e - ntc_rg424 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg424:
;## kw_printstrvar ntc_printbuf
;kw_printstrvar, <straddr>
kw_printstrvar:
			pop hl
			ld (ntc_sptr), hl
			jp ntc_printbuf

ntc_rg424_e:
			IF ($ < 32768) && (ntc_rg425_e - ntc_rg425 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg425:
;## ntc_itoa ntc_data
; HL = signed value, DE = buffer: writes the digits and a 0 (DE ends on
; the 0). jp (ix) back. Uses A, BC, IY.
ntc_itoa:
			bit 7, h
			jr z, ntc_ia_pos
			ld a, '-'
			ld (de), a
			inc de
			xor a
			sub l
			ld l, a
			sbc a, a
			sub h
			ld h, a
ntc_ia_pos:
			xor a
			ld (ntc_lead), a
			ld iy, ntc_pow10
ntc_ia_pow:
			ld c, (iy+0)
			ld b, (iy+1)
			ld a, b
			or c
			jr z, ntc_ia_last
			ld a, '0' - 1
ntc_ia_sub:
			inc a
			and a
			sbc hl, bc
			jr nc, ntc_ia_sub
			add hl, bc
			cp '0'
			jr nz, ntc_ia_out
			ld b, a
			ld a, (ntc_lead)
			or a
			ld a, b
			jr z, ntc_ia_skip
ntc_ia_out:
			ld (de), a
			inc de
			ld a, 1
			ld (ntc_lead), a
ntc_ia_skip:
			inc iy
			inc iy
			jr ntc_ia_pow
ntc_ia_last:
			ld a, l
			add a, '0'
			ld (de), a
			inc de
			xor a
			ld (de), a
			jp (ix)
ntc_pow10:		dw 10000, 1000, 100, 10, 0

ntc_rg425_e:
			IF ($ < 32768) && (ntc_rg426_e - ntc_rg426 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg426:
;## kw_printint ntc_printbuf ntc_itoa
;kw_printint, <var>  - signed decimal
kw_printint:
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			ld de, ntc_numbuf
			ld ix, ntc_pi_done
			jp ntc_itoa
ntc_pi_done:
			ld hl, ntc_numbuf
			ld (ntc_sptr), hl
			jp ntc_printbuf

ntc_rg426_e:
			IF ($ < 32768) && (ntc_rg427_e - ntc_rg427 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg427:
;## kw_printnl0 ntc_data ntc_plat_screen
;kw_printnl0  - new line unless the cursor is at the start of a line
kw_printnl0:
			ld a, (ntc_curx)
			or a
			ret z
			ld ix, ntc_next
			jp ntc_plat_newline

ntc_rg427_e:
			IF ($ < 32768) && (ntc_rg428_e - ntc_rg428 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg428:
;## kw_printnl ntc_data ntc_plat_screen
;kw_printnl
kw_printnl:
			ld ix, ntc_next
			jp ntc_plat_newline

ntc_rg428_e:
			IF ($ < 32768) && (ntc_rg429_e - ntc_rg429 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg429:
;## ntc_atoi ntc_data
; text to number into the var at (ntc_ivar). ntc_atoi reads ntc_inbuf,
; ntc_atoi_hl reads HL. Spaces first, then - , then digits (or &H hex).
ntc_atoi:
			ld hl, ntc_inbuf
ntc_atoi_hl:
			ld a, (hl)
			cp ' '
			jr nz, ntc_atoi_sign
			inc hl
			jr ntc_atoi_hl
ntc_atoi_sign:
			ld c, 0
			cp '-'
			jr nz, ntc_atoi_amp
			inc c
			inc hl
			ld a, (hl)
ntc_atoi_amp:
			ld de, 0
			cp '&'
			jr nz, ntc_atoi_loop
			inc hl
			ld a, (hl)
			or #20
			cp 'h'
			jr nz, ntc_atoi_done
			inc hl
ntc_atoi_hex:
			ld a, (hl)
			sub '0'
			jr c, ntc_atoi_done
			cp 10
			jr c, ntc_atoi_hd
			or #20
			sub 'a' - '0'
			jr c, ntc_atoi_done
			cp 6
			jr nc, ntc_atoi_done
			add a, 10
ntc_atoi_hd:
			ex de, hl
			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl
			or l
			ld l, a
			ex de, hl
			inc hl
			jr ntc_atoi_hex
ntc_atoi_loop:
			ld a, (hl)
			sub '0'
			jr c, ntc_atoi_done
			cp 10
			jr nc, ntc_atoi_done
			ld (ntc_aptr), hl
			ex de, hl
			ld d, h
			ld e, l
			add hl, hl
			add hl, hl
			add hl, de
			add hl, hl
			ld e, a
			ld d, 0
			add hl, de
			ex de, hl
			ld hl, (ntc_aptr)
			inc hl
			jr ntc_atoi_loop
ntc_atoi_done:
			ld a, c
			or a
			jr z, ntc_atoi_store
			xor a
			sub e
			ld e, a
			sbc a, a
			sub d
			ld d, a
ntc_atoi_store:
			ld hl, (ntc_ivar)
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg429_e:
			IF ($ < 32768) && (ntc_rg430_e - ntc_rg430 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg430:
;## kw_inkey ntc_data ntc_plat_key
;kw_inkey, <destvar>  - new key press or 0, no wait
kw_inkey:
			pop hl
			ld (ntc_ivar), hl
			ld ix, ntc_inkey_got
			jp ntc_plat_scankey
ntc_inkey_got:
			ld hl, (ntc_ivar)
			ld (hl), a
			inc hl
			ld (hl), 0
			ret

ntc_rg430_e:
			IF ($ < 32768) && (ntc_rg431_e - ntc_rg431 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg431:
;## kw_model ntc_data ntc_plat_screen
;kw_model, <literal>  - 0, 1 or 2, clears the screen
kw_model:
			pop hl
			ld a, l
			ld ix, ntc_next
			jp ntc_plat_mode

ntc_rg431_e:
			IF ($ < 32768) && (ntc_rg432_e - ntc_rg432 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg432:
;## kw_frame ntc_data ntc_plat_frame
;kw_frame  - wait for the start of the next frame flyback
kw_frame:
			ld ix, ntc_next
			jp ntc_plat_frame

ntc_rg432_e:
			IF ($ < 32768) && (ntc_rg433_e - ntc_rg433 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg433:
;## kw_ticks ntc_data ntc_plat_ticks
;kw_ticks, <destvar>  - tick count from the platform (CPC: interrupts, 300 a second,
;  only moving in normal mode)
kw_ticks:
			pop hl
			ld (ntc_ivar), hl
			ld ix, ntc_tk_got
			jp ntc_plat_ticks
ntc_tk_got:
			ex de, hl
			ld hl, (ntc_ivar)
			ld (hl), e
			inc hl
			ld (hl), d
			ret

; ============================================================
; String functions. Numbers are passed as the address of a word
; (a literal goes in as lit_n, a dw in the data). Results go to a
; string buffer (41 bytes). Dest may be the same as the source.
; ============================================================

ntc_rg433_e:
			IF ($ < 32768) && (ntc_rg434_e - ntc_rg434 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg434:
;## ntc_getn ntc_data
; BC = address of a word: A = its value limited to 0..255
; (below 0 = 0, above 255 = 255). jp (ix) back. Keeps DE, HL.
ntc_getn:
			ld a, (bc)
			ld (ntc_gnlo), a
			inc bc
			ld a, (bc)
			or a
			jp m, ntc_gn_zero
			jr nz, ntc_gn_max
			ld a, (ntc_gnlo)
			jp (ix)
ntc_gn_zero:
			xor a
			jp (ix)
ntc_gn_max:
			ld a, 255
			jp (ix)

ntc_rg434_e:
			IF ($ < 32768) && (ntc_rg435_e - ntc_rg435 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg435:
;## kw_strleft ntc_getn
;kw_strleft, <dest>, <src>, <nvar>  - Left$(src, n)
kw_strleft:
			pop de
			pop hl
			pop bc
			ld ix, ntc_sl_n
			jp ntc_getn
ntc_sl_n:
			ld b, a
; copy up to B chars from HL to DE, then the 0
ntc_strncpy:
			inc b
ntc_sn_loop:
			dec b
			jr z, ntc_sn_end
			ld a, (hl)
			or a
			jr z, ntc_sn_end
			ld (de), a
			inc hl
			inc de
			jr ntc_sn_loop
ntc_sn_end:
			xor a
			ld (de), a
			ret

ntc_rg435_e:
			IF ($ < 32768) && (ntc_rg436_e - ntc_rg436 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg436:
;## kw_strmid ntc_getn kw_strleft
;kw_strmid, <dest>, <src>, <startvar>, <lenvar>  - Mid$(src, start, len)
kw_strmid:
			pop de
			pop hl
			pop bc
			ld ix, ntc_sm_s
			jp ntc_getn
ntc_sm_s:
			or a
			jr z, ntc_sm_s1
			dec a
ntc_sm_s1:
			ld b, a
			inc b
ntc_sm_skip:
			dec b
			jr z, ntc_sm_len
			ld a, (hl)
			or a
			jr z, ntc_sm_len
			inc hl
			jr ntc_sm_skip
ntc_sm_len:
			pop bc
			ld ix, ntc_sm_n
			jp ntc_getn
ntc_sm_n:
			ld b, a
			jp ntc_strncpy

ntc_rg436_e:
			IF ($ < 32768) && (ntc_rg437_e - ntc_rg437 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg437:
;## kw_strchr
;kw_strchr, <dest>, <nvar>  - Chr$(n)
kw_strchr:
			pop de
			pop hl
			ld a, (hl)
			ld (de), a
			inc de
			xor a
			ld (de), a
			ret

ntc_rg437_e:
			IF ($ < 32768) && (ntc_rg438_e - ntc_rg438 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg438:
;## kw_strucase
;kw_strucase, <dest>, <src>  - UCase$
kw_strucase:
			pop de
			pop hl
ntc_uc_loop:
			ld a, (hl)
			cp 'a'
			jr c, ntc_uc_put
			cp 'z' + 1
			jr nc, ntc_uc_put
			sub 32
ntc_uc_put:
			ld (de), a
			or a
			ret z
			inc hl
			inc de
			jr ntc_uc_loop

ntc_rg438_e:
			IF ($ < 32768) && (ntc_rg439_e - ntc_rg439 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg439:
;## kw_strasc
;kw_strasc, <src>, <destvar>  - Asc(src), 0 if empty
kw_strasc:
			pop hl
			ld a, (hl)
			pop hl
			ld (hl), a
			inc hl
			ld (hl), 0
			ret

ntc_rg439_e:
			IF ($ < 32768) && (ntc_rg440_e - ntc_rg440 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg440:
;## kw_strval ntc_atoi
;kw_strval, <src>, <destvar>  - Val(src): decimal or &H hex
kw_strval:
			pop hl
			pop de
			ld (ntc_ivar), de
			jp ntc_atoi_hl

ntc_rg440_e:
			IF ($ < 32768) && (ntc_rg441_e - ntc_rg441 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg441:
;## kw_strinstr ntc_getn ntc_data
;kw_strinstr, <startvar>, <s1>, <s2>, <destvar>  - InStr(start, s1, s2)
kw_strinstr:
			pop bc
			ld ix, ntc_in_s
			jp ntc_getn
ntc_in_s:
			or a
			jr nz, ntc_in_s1
			inc a
ntc_in_s1:
			ld c, a
			pop hl
			ld b, a
ntc_in_adv:
			dec b
			jr z, ntc_in_try0
			ld a, (hl)
			or a
			jr z, ntc_in_nfpop
			inc hl
			jr ntc_in_adv
ntc_in_try0:
			pop de
			ld (ntc_sptr), de
ntc_in_try:
			ld (ntc_iptr), hl
			ld de, (ntc_sptr)
ntc_in_cmp:
			ld a, (de)
			or a
			jr z, ntc_in_found
			cp (hl)
			jr nz, ntc_in_next
			inc hl
			inc de
			jr ntc_in_cmp
ntc_in_next:
			ld hl, (ntc_iptr)
			ld a, (hl)
			or a
			jr z, ntc_in_nf
			inc hl
			inc c
			jr ntc_in_try
ntc_in_nfpop:
			pop de
ntc_in_nf:
			ld c, 0
ntc_in_found:
			pop hl
			ld (hl), c
			inc hl
			ld (hl), 0
			ret

ntc_rg441_e:
			IF ($ < 32768) && (ntc_rg442_e - ntc_rg442 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg442:
;## kw_l_mov
;kw_l_mov, <src>, <dest>  - dest = src (4 bytes)
kw_l_mov:
			pop hl
			pop de
			ldi
			ldi
			ldi
			ldi
			ret

ntc_rg442_e:
			IF ($ < 32768) && (ntc_rg443_e - ntc_rg443 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg443:
;## kw_l_itol
;kw_l_itol, <intvar>, <dest>  - Integer to Long (sign extended)
kw_l_itol:
			pop hl
			pop de
			ld a, (hl)
			ld (de), a
			inc hl
			inc de
			ld a, (hl)
			ld (de), a
			inc de
			rla
			sbc a, a
			ld (de), a
			inc de
			ld (de), a
			ret

ntc_rg443_e:
			IF ($ < 32768) && (ntc_rg444_e - ntc_rg444 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg444:
;## kw_l_add
;kw_l_add, <a>, <b>, <dest>  - a + b
kw_l_add:
			pop hl
			pop de
			pop ix
			ld a, (de)
			add a, (hl)
			ld (ix+0), a
			inc hl
			inc de
			ld a, (de)
			adc a, (hl)
			ld (ix+1), a
			inc hl
			inc de
			ld a, (de)
			adc a, (hl)
			ld (ix+2), a
			inc hl
			inc de
			ld a, (de)
			adc a, (hl)
			ld (ix+3), a
			ret

ntc_rg444_e:
			IF ($ < 32768) && (ntc_rg445_e - ntc_rg445 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg445:
;## ntc_buf2k
; ntc_buf - a buffer shared by the classes that need one: FileSystem's
; CAS IN / OUT OPEN buffer (CPC firmware: 2K) and Memory.Copy's page to page
; copy (that much at a time). NTC_BUFSIZE (Option Buffer): 2048 unless set
ntc_buf:		ds NTC_BUFSIZE

ntc_rg445_e:
			IF ($ < 32768) && (ntc_rg446_e - ntc_rg446 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg446:
;## ntc_memcore ntc_data ntc_mem ntc_memcore2 ntc_plat_memtop @shared
; ------------------------------------------------------------
; ntc_memcore - the Memory class, the part every scheme shares. The scheme
; (Option Memory, else the platform's default) is the section ntc_mem -
; only the one chosen is in the library (@if:): CPCExpansion (16K pages
; through the #4000 window, up to 4MB) or Small (main RAM only, no paging).
; Each class method jumps to mem_go with HL = the routine: mem_go runs it
; on the real stack (call / push are fine there), interrupts on in normal
; mode (off in turbo), and stores its HL result at mem_res (mem_go4: a Long, high
; word in mem_hi; mem_go0: no store - the routine writes the result
; itself, or there is none). A routine that fails jumps to mem_err with
; HL = the status; mem_err puts back the page that was in the window
; and unwinds to mem_go.
; Far pointer = a Long: address, page (page 0 = plain memory).
; Heap: blocks from mem_hlo to mem_hhi (a D page, or Small's main RAM),
; each with a 2 byte header: length including the header (bits 0-14),
; bit 15 = in use. Free blocks are at most #4000 (joins stop there).
; The scheme supplies: mem_start (the first call), mem_sel (HL = page
; into the window), mem_chk (HL = a page number, else BadPage).
; ------------------------------------------------------------
MEM_WIN		equ #4000
MEM_BADPAGE	equ -2

mem_a1:			dw 0
mem_a2:			dw 0
mem_a3:			dw 0
mem_res:		dw 0
mem_hi:			dw 0
mem_sp:			dw 0
mem_esp:		dw 0
mem_six:		dw 0
mem_siy:		dw 0
mem_need:		dw 0
mem_max:		dw 0
mem_srca:		dw 0
mem_dsta:		dw 0
mem_srcp:		dw 0
mem_dstp:		dw 0
mem_left:		dw 0
mem_chunk:		dw 0
mem_cur:		dw 1			; the page in the window
mem_keep:		dw 1			; the page to put back
mem_hlo:		dw MEM_WIN		; the heap region mem_fit / mem_big work in
mem_hhi:		dw #8000
mem_store:		db 0
mem_init:		db 0			; 1 = the first call has been

; mem_go / mem_go4 / mem_go0 - HL = the routine (see above)
mem_go0:
			xor a
			jr mem_gostart
mem_go4:
			ld a, 4
			jr mem_gostart
mem_go:
			ld a, 2
mem_gostart:
			ld (mem_store), a
			ld (mem_sp), sp
			ld sp, (ntc_csp)
			ld (mem_six), ix
			ld (mem_siy), iy
			ld de, 0
			ld (mem_hi), de
			push hl
			call mem_start
			pop hl
			ld de, (mem_cur)
			ld (mem_keep), de
			ld a, (ntc_nmode)		; normal mode: interrupts in during the call (Ticks keep
			or a					; counting through a long Sort or Copy); turbo: off
			jr z, mem_gocall
			ei
mem_gocall:
			ld (mem_esp), sp
			call mem_jphl
mem_back:
			di
			ld ix, (mem_six)
			ld iy, (mem_siy)
			ld a, (mem_store)
			or a
			jr z, mem_gone
			ex de, hl
			ld hl, (mem_res)
			ld (hl), e
			inc hl
			ld (hl), d
			cp 4
			jr nz, mem_gone
			ld de, (mem_hi)
			inc hl
			ld (hl), e
			inc hl
			ld (hl), d
mem_gone:
			ld sp, (mem_sp)
			ret
mem_jphl:
			jp (hl)
mem_err:
			ld sp, (mem_esp)
			push hl
			ld hl, (mem_keep)
			call mem_sel
			pop hl
			ld de, 0
			ld (mem_hi), de
			jr mem_back

mem_chk_bad:
			ld hl, MEM_BADPAGE
			jp mem_err

ntc_rg446_e:
			IF ($ < 32768) && (ntc_rg447_e - ntc_rg447 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg447:
;## ntc_memcore2 ntc_memcore @shared @far
; ntc_memcore2 - the rest of the shared part: far pointers, the heap, bytes
; and words. Runs on the real stack (through mem_go), so a keyword ROM set
; can place it in another ROM of the set (@far).

; mem_far - HL = a far pointer's address (Long: address, page): DE = the
; address, HL = the page (0 = plain memory). Page not 0: it must be a page
; this machine has and the address in the window, else mem_err BadPage.
mem_far:
			ld e, (hl)
			inc hl
			ld d, (hl)
			inc hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			or h
			ret z
			call mem_chk
			ld a, d
			and #C0
			cp #40
			jp nz, mem_chk_bad		; (jr: another part, maybe across Option Reserve)
			ret

; PageOf(ptr): a far pointer's page
mem_pageof:
			ld hl, (mem_a1)
			inc hl
			inc hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			ret

; Address(ptr): its page into the window (page 0: nothing); the address
mem_address:
			ld hl, (mem_a1)
			call mem_far
			ld a, h
			or l
			call nz, mem_sel
			ex de, hl
			ret

; HeapStart(), HeapEnd(): the heap region (CPCExpansion: the window, a D page at a time)
mem_heapstart:
			ld hl, (mem_hlo)
			ret
mem_heapend:
			ld hl, (mem_hhi)
			ret
; ProgramStart(), ProgramEnd() (the first byte after the program and its
; arrays), Top() (the platform's top of free RAM), StackTop() (the real stack)
mem_progstart:
			ld hl, ntc_start
			ret
mem_progend:
			ld hl, ntc_free
			ret
mem_top:
			jp ntc_plat_memtop
mem_stacktop:
			ld hl, (ntc_csp)
			ret

; mem_atend - Z when HL = mem_hhi (the heap region's end). Keeps BC, DE, HL.
mem_atend:
			ld a, (mem_hhi)
			cp l
			ret nz
			ld a, (mem_hhi + 1)
			cp h
			ret
; mem_cap - HL = two joined blocks' length: NC = too long (over #4000), C = fine
mem_cap:
			ld a, h
			cp #40
			ret c
			scf
			ccf
			ret nz
			ld a, l
			cp 1					; #4000 exactly: C
			ret

; mem_fit - in the heap region (mem_hlo .. mem_hhi: a D page, or Small's main RAM): the first free block of mem_need
; bytes or more (free neighbours joined on the way), split when 4 or more
; bytes are left over, marked in use. Z: HL = its data. NZ: none.
mem_fit:
			ld hl, (mem_hlo)
mem_f_lp:
			call mem_atend
			jr z, mem_f_none
			ld e, (hl)
			inc hl
			ld d, (hl)
			dec hl
			bit 7, d
			jr z, mem_f_free
			res 7, d
mem_f_next:
			add hl, de
			jr mem_f_lp
mem_f_free:
			push hl
			add hl, de				; the block after
			call mem_atend
			jr z, mem_f_last
			ld c, (hl)
			inc hl
			ld b, (hl)
			bit 7, b
			jr nz, mem_f_last
			ld h, d					; free too: join them, up to #4000
			ld l, e
			add hl, bc
			call mem_cap
			jr nc, mem_f_last
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			dec hl
			jr mem_f_free
mem_f_last:
			pop hl
			push hl
			ex de, hl				; HL = its length, DE = the block
			ld bc, (mem_need)
			or a
			sbc hl, bc				; what is left over
			jr c, mem_f_small
			ld a, h
			or a
			jr nz, mem_f_cut
			ld a, l
			cp 4
			jr nc, mem_f_cut
			add hl, bc				; all of it
			ld b, h
			ld c, l
			pop hl
			jr mem_f_take
mem_f_cut:
			ex de, hl				; DE = left over, HL = the block
			pop hl
			push hl
			add hl, bc				; the free block after it
			ld (hl), e
			inc hl
			ld (hl), d
			pop hl
mem_f_take:
			ld (hl), c
			inc hl
			ld a, b
			or #80
			ld (hl), a
			inc hl
			xor a
			ret
mem_f_small:
			add hl, bc				; HL = its length again
			ex de, hl
			pop hl
			jr mem_f_next
mem_f_none:
			or 1					; NZ
			ret

; mem_big - in the heap region: join free neighbours, mem_max =
; the biggest free block's length if bigger
mem_big:
			ld hl, (mem_hlo)
mem_b_lp:
			call mem_atend
			ret z
			ld e, (hl)
			inc hl
			ld d, (hl)
			dec hl
			bit 7, d
			jr z, mem_b_free
			res 7, d
mem_b_next:
			add hl, de
			jr mem_b_lp
mem_b_free:
			push hl
			add hl, de
			call mem_atend
			jr z, mem_b_end
			ld c, (hl)
			inc hl
			ld b, (hl)
			bit 7, b
			jr nz, mem_b_end
			ld h, d
			ld l, e
			add hl, bc
			call mem_cap
			jr nc, mem_b_end
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			dec hl
			jr mem_b_free
mem_b_end:
			pop hl
			push hl
			ld hl, (mem_max)
			or a
			sbc hl, de
			pop hl
			jr nc, mem_b_next
			ld (mem_max), de
			jr mem_b_next

; ---- single bytes and words through far pointers (the window is put back)

; mem_at - mem_a1 = a far pointer's address: its page in, HL = the address
mem_at:
			ld hl, (mem_a1)
			call mem_far
			ld a, h
			or l
			call nz, mem_sel
			ex de, hl
			ret

mem_readbyte:
			call mem_at
			ld l, (hl)
			ld h, 0
			jr mem_putback
mem_readword:
			call mem_at
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			jr mem_putback
mem_writebyte:
			call mem_at
			ld a, (mem_a2)
			ld (hl), a
			jr mem_putback
mem_writeword:
			call mem_at
			ld de, (mem_a2)
			ld (hl), e
			inc hl
			ld (hl), d
mem_putback:
			push hl
			ld hl, (mem_keep)
			call mem_sel
			pop hl
			ret

ntc_rg447_e:
			IF ($ < 32768) && (ntc_rg448_e - ntc_rg448 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg448:
;## ntc_mem ntc_memcore ntc_membank ntc_nxt_bank ntc_msx_bank @shared @far
; ------------------------------------------------------------
; ntc_mem (CPCExpansion) - 16K RAM pages in the #4000-#7FFF window (CPC gate
; array RAM setting: C0 = plain, C4-C7 + bank * 8 = page 0-3 of a 64K bank;
; the port's high byte #7F .. #78 picks the 512K block), up to a 4MB
; expansion: 64 banks, 257 pages (NTC_MEMBANKS: Option Memory's limit).
;   Page 1  = main RAM #4000-#7FFF (setting #C0)
;   Page 2+ = 4 pages for each bank the probe finds, the standard 512K
;             (port #7F) first, then the blocks on #7E .. #78
;   Page numbers are 16 bit (a far pointer's high word); 0 = plain memory.
;   No pages at all when the program (ntc_start .. ntc_free) or the
;   real stack is in the window: switching would hide them.
; Tables, made by the first call (mem_start) from ntc_free up, sized to
; what the probe finds (3 bytes a page); fewer pages when there isn't room
; below #4000 (or below the real stack):
;   the port table - 2 bytes a page: the BC that selects it (out (c), c),
;                    so selecting a page is a look-up, nothing worked out
;   the RAT        - 1 byte a page, its type: - free, C, D, I, U, B (the 4
;                    pages of a whole bank, AllocBank)
; No lists: a free page or bank is found by scanning the RAT (CPIR), a page
; is freed by writing - back. C / I / U pages come from the low block first
; (main + the #7F block), D pages from the high one (#78-#7E); each falls
; back to the other. On 576K or less every page is low.
; The page in the window is kept in mem_cur, written before the port,
; so an interrupt handler can always put the right page back.
; A new D page is one free block of #4000.
; ------------------------------------------------------------
MEM_BANKS	equ NTC_MEMBANKS	; 0 - 64
MEM_LB		equ 6			; the whole-bank kind (mem_kinds)

mem_count:		dw 0			; pages (0 = no paging)
mem_tport:		dw 0			; the port table (2 bytes a page: its BC)
mem_ttype:		dw 0			; the RAT (1 byte a page: its type)
mem_tend:		dw 0			; the first byte after them
mem_fp:			dw 0			; (making the port table: the next bank found)
mem_banks:		db 0			; 64K banks found
mem_tl:			db 0
mem_sw:			db 0			; mem_scan: 0 low, 1 high, 2 any
mem_kinds:		db "--CDIUB"		; the type character of each kind (0, 1 free)
mem_found:		ds MEM_BANKS + 1	; probe: the banks found (0-63), in order
mem_save:		ds MEM_BANKS + 1	; probe: the bytes the markers replace
mem_bksp:		dw 0			; CallBank: the real stack while bank code runs
mem_bkrmr:		db 0			; and the ROM / mode byte to put back

; mem_start - the first call: can this program page, what is fitted, the tables
mem_start:
			ld a, (mem_init)
			or a
			ret nz
			inc a
			ld (mem_init), a
			ld hl, ntc_free
			ld (mem_tend), hl
	IF NTC_WINHOLE
			jr mem_st_prog			; the program is built round the window (Option Reserve)
	ENDIF
	IF NTC_ROMLIB					; the keyword ROM: free RAM from #8000 on = built round it
			ld a, h
			cp #80
			jr nc, mem_st_prog
	ENDIF
			ld de, MEM_WIN + 1		; the program must be out of the window:
			or a					; it ends by #4000 ...
			sbc hl, de
			jr c, mem_st_prog
			ld hl, ntc_start		; ... or starts at #8000 or above
			ld de, #8000
			or a
			sbc hl, de
			ret c
mem_st_prog:
			ld hl, (ntc_csp)		; and the real stack too: at or below #4000,
			ld de, MEM_WIN + 1		; or 64 bytes or more above #8000
			or a
			sbc hl, de
			jr c, mem_probe
			ld hl, (ntc_csp)
			ld de, #8040
			or a
			sbc hl, de
			ret c
; the probe: interrupts off, nothing written until every byte is saved.
; Markers go in bank 63 down to bank 0, then main RAM, so a bank the
; hardware doesn't decode (a 6128 has one bank, a 512K expansion ignores
; the port's block bits) reads back a lower bank's marker, and a 64K
; machine (C4-C7 do nothing) reads main RAM's.
mem_probe:
		IF MEM_BANKS > 0
	IFDEF NTC_MSXDOS
			call msx_mem_probe		; MSX: the mapper's segments from MSX-DOS 2 (ntc_lib_msx.asm), sets mem_banks
	ELSE
	IFNDEF NTC_ZXN
			ld a, i					; P/V = interrupts were on
			di
			push af
			ld bc, #7FC0
			out (c), c
			ld a, (MEM_WIN)
			ld (mem_save + MEM_BANKS), a
			ld hl, mem_save
			ld e, 0
mem_pr_save:
			call mem_jbc
			out (c), c
			ld a, (MEM_WIN)
			ld (hl), a
			inc hl
			inc e
			ld a, e
			cp MEM_BANKS
			jr nz, mem_pr_save
			ld e, MEM_BANKS
mem_pr_mark:
			dec e
			call mem_jbc
			out (c), c
			ld a, e
			add a, #40
			ld (MEM_WIN), a
			ld a, e
			or a
			jr nz, mem_pr_mark
			ld bc, #7FC0
			out (c), c
			ld a, #A5
			ld (MEM_WIN), a
			ld hl, mem_found
			ld d, 0
			ld e, 0
mem_pr_read:
			call mem_jbc
			out (c), c
			ld a, e
			add a, #40
			push hl
			ld hl, MEM_WIN
			cp (hl)
			pop hl
			jr nz, mem_pr_none
			ld (hl), e				; this bank is there
			inc hl
			inc d
mem_pr_none:
			inc e
			ld a, e
			cp MEM_BANKS
			jr nz, mem_pr_read
			ld hl, mem_save + MEM_BANKS	; put the bytes back, bank 63 down to 0
			ld e, MEM_BANKS
mem_pr_back:
			dec e
			dec hl
			call mem_jbc
			out (c), c
			ld a, (hl)
			ld (MEM_WIN), a
			ld a, e
			or a
			jr nz, mem_pr_back
			ld bc, #7FC0
			out (c), c
			ld a, (mem_save + MEM_BANKS)
			ld (MEM_WIN), a
			ld a, d
			ld (mem_banks), a
			pop af
			jp po, mem_pr_di
			ei
mem_pr_di:
	ELSE
			call nxt_mem_probe		; Next: the RAM probe (ntc_lib_nxt.asm), sets mem_banks
	ENDIF
	ENDIF
		ENDIF
			ld a, (mem_banks)		; pages = 1 + 4 a bank
			ld l, a
			ld h, 0
			add hl, hl
			add hl, hl
			inc hl
			ld (mem_count), hl
	IF NTC_WINHOLE
			call ntc_plat_memtop		; built round the window: the tables go above it
			jr mem_tb_lim			; (ntc_memtab), up to the platform's top
	ENDIF
	IF NTC_ROMLIB					; the keyword ROM: a program built round the window (it has no
			ld hl, ntc_free			; NTC_WINHOLE here) has its free RAM above it - up to the top
			ld a, h
			cp #80
			jr c, mem_tb_low
			call ntc_plat_memtop
			jr mem_tb_lim
mem_tb_low:
	ENDIF
			ld de, (ntc_csp)		; the tables must end by #4000, or 128 bytes
			ld hl, MEM_WIN			; under the real stack when it is lower
			or a
			sbc hl, de
			ld hl, MEM_WIN
			jr c, mem_tb_lim
			ld hl, -128
			add hl, de
mem_tb_lim:
			ld (mem_tend), hl		; the limit, for now
mem_tb_fit:
			ld hl, (mem_count)
			ld a, h
			or l
			jr z, mem_tb_none
			ld d, h
			ld e, l
			add hl, hl
			add hl, de				; 3 bytes a page
	IF NTC_WINHOLE
			ld de, ntc_memtab
	ELSE
			ld de, ntc_free
	ENDIF
			add hl, de
			ex de, hl				; DE = their end
			ld hl, (mem_tend)
			or a
			sbc hl, de
			jr nc, mem_tb_ok
			ld hl, (mem_count)		; no room: one page fewer
			dec hl
			ld (mem_count), hl
			jr mem_tb_fit
mem_tb_none:
	IF NTC_WINHOLE
			ld hl, ntc_memtab
	ELSE
			ld hl, ntc_free
	ENDIF
			ld (mem_tend), hl
			ret
mem_tb_ok:
			ld (mem_tend), de
	IF NTC_WINHOLE
			ld hl, ntc_memtab
	ELSE
			ld hl, ntc_free
	ENDIF
			ld (mem_tport), hl
			ld de, (mem_count)
			add hl, de
			add hl, de
			ld (mem_ttype), hl
			ld bc, (mem_count)		; the RAT: every page free
			ld (hl), '-'
			dec bc
			ld a, b
			or c
			jr z, mem_tb_pl0
			ld d, h
			ld e, l
			inc de
			ldir
mem_tb_pl0:
	IFDEF NTC_PGLOADED
			ld hl, ntc_pgloaded		; Option Page ... Loaded n: those pages are taken (C), already
			ld b, (hl)				; filled - AllocPage never hands them out
			inc hl
mem_tb_pl:
			ld e, (hl)
			inc hl
			ld d, (hl)
			inc hl
			push hl
			ld hl, (mem_count)		; (past the pages there are: nothing to mark)
			or a
			sbc hl, de
			jr c, mem_tb_pl2
			ld hl, (mem_ttype)
			add hl, de
			dec hl
			ld (hl), 'C'
mem_tb_pl2:
			pop hl
			djnz mem_tb_pl
	ENDIF
mem_tb_ports:						; the port table: page 1 main RAM, then 4 a bank found
			ld hl, (mem_tport)
			ld (hl), #C0
			inc hl
			ld (hl), #7F
			inc hl
			ld de, (mem_count)
			dec de					; DE = pages left
			ld bc, mem_found
			ld (mem_fp), bc
mem_tb_bk:
			ld a, d
			or e
			ret z
			push de
			ld bc, (mem_fp)
			ld a, (bc)
			inc bc
			ld (mem_fp), bc
			ld e, a
			call mem_jbc			; BC = its page 0's port (keeps DE, HL)
			pop de
			ld a, 4
mem_tb_pg:
			ld (hl), c
			inc hl
			ld (hl), b
			inc hl
			inc c
			dec de
			push af
			ld a, d
			or e
			jr z, mem_tb_pend		; (fewer pages than found: the rest left out)
			pop af
			dec a
			jr nz, mem_tb_pg
			jr mem_tb_bk
mem_tb_pend:
			pop af
			ret

; mem_jbc - E = bank 0-63: BC = the port for its page 0 (B = #7F - E / 8,
; C = #C4 + (E and 7) * 8). Keeps DE, HL.
mem_jbc:
	IFDEF NTC_MSXDOS
			jp msx_mem_jbc			; MSX: 64K bank E -> its page 0's setting (ntc_lib_msx.asm)
	ENDIF
	IFDEF NTC_ZXN
			jp nxt_mem_jbc			; Next: 64K bank E -> its first 16K Next bank (ntc_lib_nxt.asm)
	ENDIF
			ld a, e
			rrca
			rrca
			rrca
			and 7
			ld b, a
			ld a, #7F
			sub b
			ld b, a
			ld a, e
			and 7
			add a, a
			add a, a
			add a, a
			add a, #C4
			ld c, a
			ret

; mem_sel - HL = page (valid): into the window. mem_cur first, then the
; port; nothing done when it is in already. Keeps BC, DE, HL.
mem_sel:
			push hl
			push de
			push bc
			ld de, (mem_cur)
			ld a, e
			cp l
			jr nz, mem_se_do
			ld a, d
			cp h
			jr z, mem_se_end
mem_se_do:
			ld (mem_cur), hl
			ld a, h
			or l
			ld bc, #7FC0			; (0: plain RAM)
			jr z, mem_se_out
			add hl, hl				; its port from the port table
			ld de, (mem_tport)
			add hl, de
			dec hl
			ld b, (hl)
			dec hl
			ld c, (hl)
mem_se_out:
	IFDEF NTC_MSXDOS
			jp msx_mem_se_out			; MSX: the segment into page 1 (PUT_P1: ntc_lib_msx.asm) -> mem_se_end
	ENDIF
	IFNDEF NTC_ZXN
			ld (ntc_rampt), bc
			out (c), c
	ELSE
			jp nxt_mem_se_out			; Next: window map via the MMU ports (ntc_lib_nxt.asm) -> mem_se_end
	ENDIF
mem_se_end:
			pop bc
			pop de
			pop hl
			ret

; mem_chk - HL = a page number: 1 .. mem_count, else mem_err BadPage.
; Keeps BC, DE, HL.
mem_chk:
			ld a, h
			or l
			jp z, mem_chk_bad
			push de
			push hl
			ex de, hl
			ld hl, (mem_count)
			or a
			sbc hl, de
			pop hl
			pop de
			ret nc
			jp mem_chk_bad
; ---- the tables (BC = a page)

; mem_tpb - HL = its type byte (in the RAT). Keeps A, BC, DE.
mem_tpb:
			ld hl, (mem_ttype)
			add hl, bc
			dec hl
			ret
; mem_push - A = a kind (mem_kinds: 2-6): the page is of that kind now. Keeps A, BC, DE.
mem_push:
			push af
			push de
			ld e, a
			ld d, 0
			ld hl, mem_kinds
			add hl, de
			ld a, (hl)
			call mem_tpb
			ld (hl), a
			pop de
			pop af
			ret
; mem_remove - (A = a kind) nothing to take it off: the RAT has no lists. NZ. Keeps BC, DE.
mem_remove:
			ld a, 1
			or a
			ret
; mem_lowhigh - A = the block the page is in: 0 low (main, or the #7F
; block) or 1 high. Keeps BC, DE.
mem_lowhigh:
			push de
			ld h, b
			ld l, c
			add hl, hl
			ld de, (mem_tport)
			add hl, de
			dec hl					; its port's high byte
			ld a, (hl)
			pop de
			cp #7F
			ld a, 0
			ret z
			inc a
			ret
; mem_tofree - the page free again. Keeps BC, DE.
mem_tofree:
			call mem_tpb
			ld (hl), '-'
			ret
; mem_scan - A = 0 low, 1 high, 2 either: BC = the first free page in it, NZ;
; Z = none
mem_scan:
			ld (mem_sw), a
			ld hl, (mem_ttype)
			ld bc, (mem_count)
mem_sc_lp:
			ld a, b
			or c
			ret z
			ld a, '-'
			cpir
			jr nz, mem_sc_none
			push bc
			push hl
			ld de, (mem_ttype)
			or a
			sbc hl, de				; the page: its entry is at HL - 1
			ld b, h
			ld c, l
			ld a, (mem_sw)
			cp 2
			jr z, mem_sc_hit
			call mem_lowhigh
			ld hl, mem_sw
			cp (hl)
			jr z, mem_sc_hit
			pop hl
			pop bc
			jr mem_sc_lp
mem_sc_hit:
			pop af
			pop af
			ld a, 1
			or a
			ret
mem_sc_none:
			xor a
			ret
; mem_dnext - BC = a page (0: before the first): BC = the next D page, NZ;
; Z = none
mem_dnext:
			ld hl, (mem_count)
			or a
			sbc hl, bc
			ret z
			push hl
			ld hl, (mem_ttype)
			add hl, bc
			pop bc
			ld a, 'D'
			cpir
			jr nz, mem_sc_none
			ld de, (mem_ttype)
			or a
			sbc hl, de
			ld b, h
			ld c, l
			ld a, 1
			or a
			ret
; mem_listof - A = the page's kind (2-6), or its free block (0, 1). Keeps BC, DE.
mem_listof:
			call mem_tpb
			ld a, (hl)
			push bc
			ld hl, mem_kinds + 2
			ld b, 5
			ld c, 2
mem_lo_lp:
			cp (hl)
			jr z, mem_lo_got
			inc hl
			inc c
			djnz mem_lo_lp
			pop bc
			jp mem_lowhigh
mem_lo_got:
			ld a, c
			pop bc
			ret
; mem_kindlist - A = a type character: A = its kind (2-5), NZ; Z = not one.
mem_kindlist:
			ld hl, mem_kinds + 2
			ld b, 4
			ld c, 2
mem_kl_lp:
			cp (hl)
			jr z, mem_kl_got
			inc hl
			inc c
			djnz mem_kl_lp
			xor a
			ret
mem_kl_got:
			ld a, c
			or a
			ret
; mem_take - A = a kind (2-5): a free page of that kind now - D from the
; high block first, the others from the low one - a D page made one free
; block. BC = the page, NZ; Z = none left.
mem_take:
			ld (mem_tl), a
			cp 3
			ld a, 1
			jr z, mem_tk_s
			xor a
mem_tk_s:
			call mem_scan
			jr nz, mem_tk_got
			ld a, 2
			call mem_scan
			ret z
mem_tk_got:
			ld a, (mem_tl)
			call mem_push
			cp 3
			jr nz, mem_tk_done
			ld h, b
			ld l, c
			call mem_sel
			ld hl, #4000
			ld (MEM_WIN), hl
			ld hl, (mem_keep)
			call mem_sel
mem_tk_done:
			ld a, 1
			or a
			ret

; ---- what's there

; Pages(): pages (0 = no paging, 1 = 64K, 5 = 128K ... 33 = 512K ... 257 = 4MB)
mem_pages:
			ld hl, (mem_count)
			ret

; FreePages(): the free pages (- in the RAT)
mem_freepages:
			ld hl, (mem_count)
			ld a, h
			or l
			ret z
			ld b, h
			ld c, l
			ld hl, (mem_ttype)
			ld de, 0
mem_fp_lp:
			ld a, '-'
			cpir
			jr nz, mem_fp_end
			inc de
			ld a, b
			or c
			jr nz, mem_fp_lp
mem_fp_end:
			ex de, hl
			ret

; RamSize(): K of RAM the probe found (64 + 64 a bank), 0 = not probed
mem_ramsize:
			ld hl, (mem_count)
			ld a, h
			or l
			ret z
			ld a, (mem_banks)
			ld l, a
			ld h, 0
			inc hl
			add hl, hl				; x 64
			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl
			ret

; Model(): 0 none, 1 small (1 page), 2 medium (up to 5), 3 large (up to
; 33, a 512K expansion), 4 huge (more)
mem_model:
			ld de, (mem_count)
			ld hl, 0
			ld a, d
			or a
			jr nz, mem_md_huge
			ld a, e
			or a
			ret z
			inc l
			cp 2
			ret c
			inc l
			cp 6
			ret c
			inc l
			cp 34
			ret c
mem_md_huge:
			ld l, 4
			ret

; TableEnd(): the first byte after Memory's tables (they start at the program's end)
mem_tableend:
			ld hl, (mem_tend)
			ret

; PageType(page): its type character
mem_pagetype:
			ld hl, (mem_a1)
			call mem_chk
			ld b, h
			ld c, l
			call mem_tpb
			ld l, (hl)
			ld h, 0
			ret

; Map(first, count): one character per page from first, into the string
; result (as many as fit; pages past the last are left out)
mem_map:
			ld hl, (mem_res)
			dec hl
			ld a, (hl)				; the string's capacity
			inc hl
			ld (mem_srca), hl
			ld (mem_chunk), a
			ld bc, (mem_a1)
			ld hl, (mem_a2)
			ld (mem_left), hl
mem_mp_lp:
			ld hl, (mem_left)
			bit 7, h
			jr nz, mem_mp_end
			ld a, h
			or l
			jr z, mem_mp_end
			ld a, b
			or c
			jr z, mem_mp_end
			ld hl, (mem_count)
			or a
			sbc hl, bc
			jr c, mem_mp_end
			ld a, (mem_chunk)
			or a
			jr z, mem_mp_end
			dec a
			ld (mem_chunk), a
			call mem_tpb
			ld a, (hl)
			ld hl, (mem_srca)
			ld (hl), a
			inc hl
			ld (mem_srca), hl
			inc bc
			ld hl, (mem_left)
			dec hl
			ld (mem_left), hl
			jr mem_mp_lp
mem_mp_end:
			ld hl, (mem_srca)
			ld (hl), 0
			ret

; ---- whole pages

; AllocPage(kind): a free page, now of that kind (C, D, I, U); 0 = none left
mem_allocpage:
			ld hl, (mem_count)
			ld a, h
			or l
			jr z, mem_ap_none
			ld hl, (mem_a1)
			ld a, h
			or a
			jr nz, mem_ap_none
			ld a, l
			call mem_kindlist
			jr z, mem_ap_none
			call mem_take
			jr z, mem_ap_none
			ld h, b
			ld l, c
			ret
mem_ap_none:
			ld hl, 0
			ret

; FreePage(page): back to free (a D page's blocks go with it). OK, or
; BadPage (not a page, or free already)
mem_freepage:
			ld hl, (mem_a1)
			call mem_chk
			ld b, h
			ld c, l
			call mem_listof
			cp 2
			jp c, mem_chk_bad
			call mem_remove
			call mem_tofree
			ld hl, 0
			ret

; SelectPage(page): into the window; #4000
mem_selpage:
			ld hl, (mem_a1)
			call mem_chk
			call mem_sel
			ld hl, MEM_WIN
			ret

; CurrentPage(): the page in the window (0 = no paging)
mem_curpage:
			ld hl, (mem_count)
			ld a, h
			or l
			ret z
			ld hl, (mem_cur)
			ret

; ---- whole 64K banks (page numbers 4 * bank - 2 .. 4 * bank + 1)

; Banks(): whole banks the tables cover (0 = none)
mem_bankcount:
			ld hl, (mem_count)
			ld a, h
			or l
			ret z
			dec hl
			srl h
			rr l
			srl h
			rr l
			ret

; mem_bkfirst - (mem_a1) = a bank, 1 .. Banks(): BC = its first page, else
; mem_err BadPage
mem_bkfirst:
			call mem_bankcount
			ld de, (mem_a1)
			ld a, d
			or e
			jp z, mem_chk_bad
			or a
			sbc hl, de
			jp c, mem_chk_bad
			ex de, hl
			dec hl
			add hl, hl
			add hl, hl
			inc hl
			inc hl
			ld b, h
			ld c, l
			ret

; AllocBank(): a bank whose 4 pages are all free, now type B; 0 = none
mem_allocbank:
			call mem_bankcount
			ld a, l
			or a
			jr z, mem_ab_none
			ld (mem_tl), a			; banks left to try
			ld bc, 2
mem_ab_lp:
			push bc
			ld d, 4
mem_ab_chk:
			call mem_listof
			cp 2
			jr nc, mem_ab_used
			inc bc
			dec d
			jr nz, mem_ab_chk
			pop bc					; all 4 free: onto the bank list
			push bc
			ld d, 4
mem_ab_take:
			call mem_listof
			call mem_remove
			ld a, MEM_LB
			call mem_push
			inc bc
			dec d
			jr nz, mem_ab_take
			pop hl					; bank = (first page + 2) / 4
			inc hl
			inc hl
			srl h
			rr l
			srl h
			rr l
			ret
mem_ab_used:
			pop bc
			ld hl, 4
			add hl, bc
			ld b, h
			ld c, l
			ld a, (mem_tl)
			dec a
			ld (mem_tl), a
			jr nz, mem_ab_lp
mem_ab_none:
			ld hl, 0
			ret

; FreeBank(bank): its 4 pages back to free. OK, or BadPage (not a bank,
; or not taken with AllocBank)
mem_bkstub:
			ld hl, ntc_bk_stub
			ret

mem_freebank:
			call mem_bkfirst
			push bc
			ld d, 4
mem_fb_chk:
			call mem_listof
			cp MEM_LB
			jp nz, mem_chk_bad
			inc bc
			dec d
			jr nz, mem_fb_chk
			pop bc
			ld d, 4
mem_fb_lp:
			ld a, MEM_LB
			call mem_remove
			call mem_tofree
			inc bc
			dec d
			jr nz, mem_fb_lp
			ld hl, 0
			ret

; CallBank(bank, address, value): runs the bank's code at address with the
; whole 64K being that bank (RAM setting C2), HL = value; its HL comes back.
; The bank must be taken (AllocBank). The switch code (ntc_bk_stub, about
; 20 bytes) is copied into the bank at its own address first, so those
; bytes of the bank are overwritten. Interrupts are off and both ROMs are
; off while the bank code runs; it starts with the stack at the bank's top
; (#FFFF down) and ends with ret. It must keep the alternate registers.
mem_callbank:
			call mem_bkfirst
			call mem_listof
			cp MEM_LB
			jp nz, mem_chk_bad
			ld hl, ntc_bk_stub		; copy the switch code into the bank
mem_cb_cp:
			push bc
			ld a, h					; its page in the bank: address / #4000
			rlca
			rlca
			and 3
			add a, c
			ld c, a
			jr nc, mem_cb_nc
			inc b
mem_cb_nc:
			push hl
			ld h, b
			ld l, c
			call mem_sel
			pop hl
			ld b, (hl)
			ld a, h
			and #3F
			or #40
			ld d, a
			ld e, l
			ld a, b
			ld (de), a
			pop bc
			inc hl
			ld a, l
			cp low ntc_bk_end
			jr nz, mem_cb_cp
			ld a, h
			cp high ntc_bk_end
			jr nz, mem_cb_cp
			ld hl, (mem_keep)
			call mem_sel
			call mem_bkfirst		; BC = C2 for the bank: its page 0's port
			ld h, b					; ((#C4 + bank bits) and #F8, or 2)
			ld l, c
			add hl, hl
			ld de, (mem_tport)
			add hl, de
			dec hl
			ld b, (hl)
			dec hl
			ld a, (hl)
			and #F8
			or 2
			ld c, a
			ld de, (mem_a2)
			ld hl, (mem_a3)
			jp ntc_bk_go

; ---- heap in D pages

; Alloc(size): a far pointer to size bytes in a D page, 0 = no room.
; Tries the page in the window, then the other D pages, then takes a free
; page. The window is left as it was.
mem_alloc:
			ld hl, (mem_count)
			ld a, h
			or l
			jr z, mem_al_fail
			ld hl, (mem_a1)
			ld a, h
			or l
			jr nz, mem_al_size
			inc hl
mem_al_size:
			ld de, #3FFF			; up to #3FFE: a page less its header
			or a
			push hl
			sbc hl, de
			pop hl
			jr nc, mem_al_fail
			inc hl
			inc hl
			ld (mem_need), hl
			ld bc, (mem_keep)
			call mem_tpb
			ld a, (hl)
			cp 'D'
			jr nz, mem_al_scan
			ld h, b
			ld l, c
			call mem_try
			jr z, mem_al_got
mem_al_scan:
			ld bc, 0
mem_al_lp:
			call mem_dnext
			jr z, mem_al_new
			ld hl, (mem_keep)
			or a
			sbc hl, bc
			jr z, mem_al_lp
			push bc
			ld h, b
			ld l, c
			call mem_try
			pop bc
			jr z, mem_al_got
			jr mem_al_lp
mem_al_new:
			ld a, 3
			call mem_take
			jr z, mem_al_back
			ld h, b
			ld l, c
			call mem_try
mem_al_got:
			ld de, (mem_cur)		; HL = the data, its page is in
			ld (mem_hi), de
			push hl
			ld hl, (mem_keep)
			call mem_sel
			pop hl
			ret
mem_al_back:
			ld hl, (mem_keep)
			call mem_sel
mem_al_fail:
			ld hl, 0
			ld (mem_hi), hl
			ret

; mem_try - HL = a D page: select it, then mem_fit
mem_try:
			call mem_sel
			jp mem_fit

; Free(ptr): a block Alloc gave back. A page with nothing left in use
; goes back to free. OK, or BadPage (not a block in use in a D page)
mem_free:
			ld hl, (mem_a1)
			call mem_far
			ld a, h
			or l
			jp z, mem_chk_bad
			ld b, h
			ld c, l
			call mem_tpb
			ld a, (hl)
			cp 'D'
			jp nz, mem_chk_bad
			ld h, b
			ld l, c
			call mem_sel
			ex de, hl
			dec hl
			bit 7, (hl)
			jr z, mem_err_page
			res 7, (hl)
			ld hl, #4000			; is the whole page free now?
			ld (mem_need), hl
			push bc
			call mem_fit			; only a page with every block free fits
			pop bc
			jr nz, mem_fr_done
			ld a, 3
			call mem_remove
			call mem_tofree
mem_fr_done:
			ld hl, (mem_keep)
			call mem_sel
			ld hl, 0
			ret
mem_err_page:
			ld hl, (mem_keep)
			call mem_sel
			jp mem_chk_bad

; Largest(): the biggest block Alloc could give now
mem_largest:
			ld hl, 0
			ld (mem_max), hl
			call mem_freepages		; a free page: a whole page
			ld a, h
			or l
			ld hl, #3FFE
			ret nz
			ld bc, 0
mem_lg_lp:
			call mem_dnext
			jr z, mem_lg_end
			ld h, b
			ld l, c
			call mem_sel
			push bc
			call mem_big
			pop bc
			jr mem_lg_lp
mem_lg_end:
			ld hl, (mem_keep)
			call mem_sel
			ld hl, (mem_max)
			ld a, h
			or l
			ret z
			dec hl
			dec hl
			ret

ntc_rg448_e:
			IF ($ < 32768) && (ntc_rg449_e - ntc_rg449 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg449:
;## ntc_membank ntc_plat_rmr @shared @romram
; ------------------------------------------------------------
; ntc_membank - Memory's CallBank switch (CPCExpansion). Runs from RAM
; (a keyword ROM can't be seen once both ROMs are off). BC = the C2
; setting and port for the bank, DE = the address in the bank, HL = value.
; ntc_bk_stub .. ntc_bk_end is also copied into the bank at the same
; address: each out is followed by the next byte from the other 64K.
; ------------------------------------------------------------
ntc_bk_go:
			ld a, i					; P/V = interrupts were on
			di
			push af
			ld (mem_bksp), sp
			call ntc_plat_rmr
			ld (mem_bkrmr), a
			or #0C					; both ROMs off
			push bc
			ld b, #7F
			out (c), a
			pop bc
ntc_bk_stub:
			out (c), c				; the bank is all 64K now
			ld sp, 0
			ld bc, ntc_bk_ret
			push bc
			push de
			ret						; to the bank's code, HL = value
ntc_bk_ret:
			ld bc, #7FC0
			out (c), c				; main RAM again
ntc_bk_end:
			ld sp, (mem_bksp)
			ld a, (mem_bkrmr)
			ld b, #7F
			out (c), a				; the ROMs as they were
			ld bc, (ntc_rampt)
			out (c), c				; and the window's page
			pop af
			jp po, ntc_bk_di
			ei
ntc_bk_di:
			ret

ntc_rg449_e:
			IF ($ < 32768) && (ntc_rg450_e - ntc_rg450 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg450:
;## ntc_keys ntc_data @shared
; ------------------------------------------------------------
; ntc_keys - the Keys class (CPC): the keyboard matrix read straight from the
; hardware (PSG register 14 through the PPI), all 10 lines each time, so it
; works with or without the firmware, in turbo and normal mode. Entered
; with jp from a method, with the method's result pointer still on the
; thread: the result goes there and ret carries on. No stack used.
;   ntc_kdown - HL = a key number 0-79 (the CPC's, as INKEY(n)): -1 held, 0 not
;   ntc_kjoy  - HL = joystick 0 / 1: bits up 1, down 2, left 4, right 8,
;               fire 2 16, fire 1 32 (as JOY(n))
; ------------------------------------------------------------
ntc_kmat:		ds 10			; the matrix (0 = pressed)
ntc_karg:		db 0
ntc_kwhat:		db 0

ntc_kdown:
			ld a, h
			or a
			jr nz, ntc_kd_no
			ld a, l
			cp 80
			jr nc, ntc_kd_no
			ld (ntc_karg), a
			xor a
			jr ntc_kscan
ntc_kjoy:
			ld a, l
			and 1
			ld (ntc_karg), a
			ld a, 1
ntc_kscan:
			ld (ntc_kwhat), a
			ld bc, #F40E		; PSG register 14
			out (c), c
			ld bc, #F6C0		; PSG: select register
			out (c), c
			ld bc, #F600		; PSG: inactive
			out (c), c
			ld bc, #F792		; PPI port A input
			out (c), c
			ld hl, ntc_kmat
			ld a, #40			; PSG read + line 0
ntc_ksc_line:
			ld b, #F6
			out (c), a
			ld b, #F4
			in d, (c)
			ld (hl), d
			inc hl
			inc a
			cp #4A
			jr nz, ntc_ksc_line
			ld bc, #F782		; PPI port A output
			out (c), c
			ld bc, #F600
			out (c), c
			ld a, (ntc_kwhat)
			or a
			jr nz, ntc_kj_got
			ld a, (ntc_karg)	; line = n / 8, bit = n and 7
			ld c, a
			rrca
			rrca
			rrca
			and 31
			ld e, a
			ld d, 0
			ld hl, ntc_kmat
			add hl, de
			ld a, c
			and 7
			ld b, a
			inc b
			ld a, (hl)
ntc_kd_rot:
			rrca
			djnz ntc_kd_rot
			ld de, 0
			jr c, ntc_k_set		; 1 = not pressed
			dec de
			jr ntc_k_set
ntc_kd_no:
			ld de, 0
			jr ntc_k_set
ntc_kj_got:
			ld a, (ntc_karg)	; joystick 0 = line 9, 1 = line 6
			ld hl, ntc_kmat + 9
			or a
			jr z, ntc_kj_line
			ld hl, ntc_kmat + 6
ntc_kj_line:
			ld a, (hl)
			cpl
			and #3F
			ld e, a
			ld d, 0
ntc_k_set:
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg450_e:
			IF ($ < 32768) && (ntc_rg451_e - ntc_rg451 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg451:
;## ntc_memcopy ntc_mem ntc_buf2k @shared @far
; Copy(src, dst, length): far pointer to far pointer, up to NTC_BUFSIZE at a
; time through ntc_buf (so page to page works with one window). A page's end
; (#8000) carries on at #4000 of the next page. The window is put back.
; OK, or BadPage.
mem_copy:
			ld hl, (mem_a1)
			call mem_far
			ld (mem_srca), de
			ld (mem_srcp), hl
			ld hl, (mem_a2)
			call mem_far
			ld (mem_dsta), de
			ld (mem_dstp), hl
			ld hl, (mem_a3)
			ld (mem_left), hl
mem_cp_lp:
			ld hl, (mem_left)
			ld a, h
			or l
			jr z, mem_cp_done
			ld de, NTC_BUFSIZE
			call mem_min
			ld de, (mem_srcp)
			ld a, d
			or e
			ld de, (mem_srca)
			call nz, mem_room
			ld de, (mem_dstp)
			ld a, d
			or e
			ld de, (mem_dsta)
			call nz, mem_room
			ld (mem_chunk), hl
			ld hl, (mem_srcp)
			ld a, h
			or l
			call nz, mem_cp_sel
			ld hl, (mem_srca)
			ld de, ntc_buf
			ld bc, (mem_chunk)
			ldir
			ld (mem_srca), hl
			ld hl, (mem_dstp)
			ld a, h
			or l
			call nz, mem_cp_sel
			ld hl, ntc_buf
			ld de, (mem_dsta)
			ld bc, (mem_chunk)
			ldir
			ld (mem_dsta), de
			ld hl, mem_srcp
			ld de, (mem_srca)
			call mem_cp_wrap
			ld (mem_srca), de
			ld hl, mem_dstp
			ld de, (mem_dsta)
			call mem_cp_wrap
			ld (mem_dsta), de
			ld hl, (mem_left)
			ld de, (mem_chunk)
			or a
			sbc hl, de
			ld (mem_left), hl
			jp mem_cp_lp
mem_cp_done:
			ld hl, (mem_keep)
			call mem_sel
			ld hl, 0
			ret
mem_cp_sel:
			call mem_chk			; a page past the last one: BadPage
			jp mem_sel
; HL = the smaller of HL and DE
mem_min:
			push hl
			or a
			sbc hl, de
			pop hl
			ret c
			ex de, hl
			ret
; DE = an address in the window: HL = no more than #8000 - DE
mem_room:
			push hl
			ld hl, #8000
			or a
			sbc hl, de
			ex de, hl
			pop hl
			jr mem_min
; HL = a page word, DE = the address: #8000 in a page -> #4000 of the next
mem_cp_wrap:
			ld a, (hl)
			inc hl
			or (hl)
			dec hl
			ret z
			ld a, d
			cp #80
			ret nz
			inc (hl)
			jr nz, mem_cw_hi
			inc hl
			inc (hl)
mem_cw_hi:
			ld d, #40
			ret

ntc_rg451_e:
			IF ($ < 32768) && (ntc_rg452_e - ntc_rg452 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg452:
;## ntc_islots ntc_data @shared
; ------------------------------------------------------------
; ntc_islots - interrupt classes (Option Class Interrupt rate | Frame | Share n):
; up to 16 classes whose Tick Sub runs at the next safe point after it is due
; (normal mode). Slot n, 8 bytes at ntc_isl + n * 8:
;   +0 count (dw)  +2 reload (dw: interrupts between runs, 0 = every frame,
;   #8000 + weight = a shared class)  +4 running (db: Tick started, its return
;   stub clears it)  +5 due (db)  +6 Tick's call stub (dw)
; Fixed classes (a rate, Frame) are counted every interrupt. Shared classes take
; turns in the interrupts no fixed class fell due in: the current one is marked
; due on each such interrupt until it has had its weight of turns, then the
; next shared one. The start code fills the slots and puts ntc_isl_tick in
; ntc_irqv, which the platform's interrupt handler calls. The counts start a
; slot apart so classes of the same rate take turns.
; ------------------------------------------------------------
ntc_isln:		db 0			; slots in use
ntc_isldue:		db 0			; 1 = a slot may be due
ntc_islvs:		db 0			; vertical sync at the last interrupt
ntc_islfr:		db 0			; 1 = this interrupt is the frame's (sync just started)
ntc_islph:		db 0			; interrupts since the frame's (0-5)
ntc_islfx:		db 0			; 1 = a fixed class fell due in this interrupt
ntc_islsc:		db 0			; the shared class having its turns (slot number)
ntc_islsw:		db 0			; turns it has left
ntc_islshn:		db 0			; shared classes (0 = none)
ntc_isl:		ds 128			; 16 slots

; ntc_isl_tick - from the interrupt handler (call, real stack): count each
; slot, mark the ones due. Keeps BC, DE, IX, IY.
ntc_isl_tick:
			push bc
			push de
	IFDEF NTC_ISLC
			ld a, c					; zxn, msx, sc3000: the handler's frame flag in C (1: a frame's interrupt)
			and 1
			ld e, a
			ld d, a					; 1 = this interrupt is the frame's
	ELSE
			ld b, #F5				; PPI port B bit 0: vertical sync
			in a, (c)
			and 1
			ld e, a
			ld a, (ntc_islvs)
			cpl
			and e
			ld d, a					; 1 = the sync started since the last interrupt
	ENDIF
			ld a, e
			ld (ntc_islvs), a
			ld a, (ntc_islph)		; a frame is 6 interrupts: count them, so a frame is
			inc a					; still seen when this interrupt came in after the
			cp 6					; sync had ended (taken late: a long keyword); the
			jr c, ntc_it_ph			; sync puts the count back to 0
			xor a
ntc_it_ph:
			bit 0, d
			jr z, ntc_it_ph2
			xor a
ntc_it_ph2:
			ld (ntc_islph), a
			or a
			ld a, 0
			jr nz, ntc_it_fr
			inc a
ntc_it_fr:
			ld (ntc_islfr), a
			xor a
			ld (ntc_islfx), a
			ld a, (ntc_isln)
			or a
			jp z, ntc_it_end
			ld b, a
			ld hl, ntc_isl
ntc_it_lp:
			push hl
			inc hl
			inc hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			bit 7, d				; a shared class: the turns below mark it
			jr nz, ntc_it_nx
			ld a, d
			or e
			jr nz, ntc_it_rate
			ld a, (ntc_islfr)		; every frame: when the sync starts
			or a
			jr z, ntc_it_nx
			jr ntc_it_due
ntc_it_rate:
			ld e, (hl)
			inc hl
			ld d, (hl)
			dec de
			ld (hl), d
			dec hl
			ld (hl), e
			ld a, d
			or e
			jr nz, ntc_it_nx
			push hl					; due: count again from the reload
			inc hl
			inc hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			dec hl
ntc_it_due:
			push hl
			ld de, 5
			add hl, de
			ld (hl), 1
			pop hl
			ld a, 1
			ld (ntc_isldue), a
			ld (ntc_islfx), a
ntc_it_nx:
			ld de, 8
			add hl, de
			djnz ntc_it_lp
			; shared classes: an interrupt no fixed class used is a turn
			ld a, (ntc_islfx)
			or a
			jp nz, ntc_it_end
			ld a, (ntc_islshn)
			or a
			jp z, ntc_it_end
			ld a, (ntc_islsw)
			or a
			jr nz, ntc_it_take
			ld a, (ntc_islsc)		; its turns are used: the next shared class
ntc_it_find:
			inc a
			ld hl, ntc_isln
			cp (hl)
			jr c, ntc_it_fi2
			xor a
ntc_it_fi2:
			ld l, a
			ld h, 0
			add hl, hl
			add hl, hl
			add hl, hl
			ld de, ntc_isl + 2
			add hl, de
			ld e, (hl)				; E = the weight
			inc hl
			bit 7, (hl)
			jr z, ntc_it_find		; not shared (there is one: ntc_islshn)
			ld (ntc_islsc), a
			ld a, e
ntc_it_take:
			dec a
			ld (ntc_islsw), a
			ld a, (ntc_islsc)
			ld l, a
			ld h, 0
			add hl, hl
			add hl, hl
			add hl, hl
			ld de, ntc_isl + 5
			add hl, de
			ld (hl), 1				; due
			ld a, 1
			ld (ntc_isldue), a
ntc_it_end:
			pop de
			pop bc
			ret

ntc_rg452_e:
			IF ($ < 32768) && (ntc_rg453_e - ntc_rg453 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg453:
;## kw_bssinit ntc_data ntc_plat_memtop ntc_plat_screen kw_stop @shared
;kw_bssinit, <start>, <size>  - the start of the main thread: the program's arrays live after
;  it (from ntc_end, not in its file). Check they fit under the platform's top (and 256 bytes
;  under the real stack when that is above them), then clear them. Too big: a message, the
;  program stops.
kw_bssinit:
			pop hl
			ld (ntc_bsa), hl
			pop bc
			ld (ntc_bsz), bc
			ld (ntc_bsp), sp
			ld sp, (ntc_csp)
			add hl, bc				; HL = their end
			ex de, hl
			call ntc_plat_memtop	; HL = the platform's top
			or a
			sbc hl, de
			jr c, ntc_bs_big
			ld hl, (ntc_csp)		; the real stack, when above them
			ld bc, (ntc_bsa)
			or a
			sbc hl, bc
			jr c, ntc_bs_ok
			ld hl, (ntc_csp)
			ld bc, -256
			add hl, bc
			or a
			sbc hl, de
			jr c, ntc_bs_big
ntc_bs_ok:
			ld bc, (ntc_bsz)
			ld a, b
			or c
			jr z, ntc_bs_done
			ld hl, (ntc_bsa)
			ld (hl), 0
			dec bc
			ld a, b
			or c
			jr z, ntc_bs_done
			ld d, h
			ld e, l
			inc de
			ldir
ntc_bs_done:
			ld sp, (ntc_bsp)
			ret
ntc_bs_big:
			ld hl, ntc_bstxt
ntc_bs_pl:
			ld a, (hl)
			or a
			jr z, ntc_bs_stop
			inc hl
			ld (ntc_bsa), hl
			ld ix, ntc_bs_pn
			jp ntc_plat_putc
ntc_bs_pn:
			ld hl, (ntc_bsa)
			jr ntc_bs_pl
ntc_bs_stop:
			ld ix, kw_stop
			jp ntc_plat_newline
ntc_bsa:		dw 0
ntc_bsz:		dw 0
ntc_bsp:		dw 0
ntc_bstxt:		db "GURU 001", 0

ntc_rg453_e:
			IF ($ < 32768) && (ntc_rg454_e - ntc_rg454 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg454:
;## ntc_nxt_bank ntc_mem @far
	IFDEF NTC_ZXN
; nxt_mem_probe - 16K banks from ZXN_FIRSTBANK up are free RAM. Map each into the
; window, mark it, re-read; the contiguous run that still holds its marker is
; usable. Sets mem_banks (64K banks = usable 16K banks / 4). Called from mem_probe;
; leaves interrupts off (the boot re-enables, as the CPC path does).
nxt_mem_probe:
			di
			ld c, ZXN_FIRSTBANK
zxn_pr_w:
			call zxn_pr_map			; 16K bank C into #4000-#7FFF
			ld a, c
			ld (MEM_WIN), a			; marker = the bank number
			inc c
			ld a, c
			cp ZXN_FIRSTBANK + ZXN_MAXBANK
			jr nz, zxn_pr_w
			ld b, 0					; usable 16K banks
			ld c, ZXN_FIRSTBANK
zxn_pr_r:
			call zxn_pr_map
			ld a, (MEM_WIN)
			cp c					; still its own marker (real, not absent / aliased)?
			jr nz, zxn_pr_done
			inc b
			inc c
			ld a, c
			cp ZXN_FIRSTBANK + ZXN_MAXBANK
			jr nz, zxn_pr_r
zxn_pr_done:
			ld c, 9					; the program's own window bank back
			call zxn_pr_map
			ld a, b					; 64K banks = usable 16K banks / 4
			srl a
			srl a
			ld (mem_banks), a
			or a
			jr z, zxn_pr_nf
			ld hl, mem_found		; the banks found, 0, 1, 2 ... (contiguous on the Next)
			ld b, a
			ld e, 0
zxn_pr_fl:
			ld (hl), e
			inc hl
			inc e
			djnz zxn_pr_fl
zxn_pr_nf:
			ret
; zxn_pr_map - C = a 16K bank into #4000-#7FFF (MMU slots 2, 3 = NextReg #52, #53). Keeps C.
zxn_pr_map:
			push bc
			ld a, c
			add a, a				; first 8K page = bank * 2
			ld d, a
			ld bc, #243B
			ld a, #52
			out (c), a
			inc b
			out (c), d
			dec b
			ld a, #53
			out (c), a
			inc b
			inc d
			out (c), d
			pop bc
			ret

ZXN_SETB	equ 1					; B of a Next RAM setting (see the top)

; nxt_mem_jbc - E = a 64K bank (0-63) -> BC = its page 0's RAM setting (B = ZXN_SETB,
; C = E * 8 + 4: the four 16K parts step C, as the CPC's #C4, #C5, #C6, #C7 do). Called
; from mem_jbc (jp, so its ret returns to mem_jbc's caller). Keeps DE, HL.
nxt_mem_jbc:
			ld a, e
			add a, a
			add a, a
			add a, a				; E * 8
			add a, 4				; + 4: its page 0
			ld c, a
			ld b, ZXN_SETB
			ret

; nxt_mem_bank - BC = a RAM setting -> A = its 16K Next bank: B = #7F (main RAM's own,
; #7FC0) = bank 9 (the program's own pages 18, 19); else C = ordinal * 8 + 4 + page
; -> ZXN_FIRSTBANK + ordinal * 4 + page (the whole bank's "2" and the pages 0-3
; (#C0-#C3 on the CPC: main RAM's blocks) all give its page 0). Keeps BC, DE, HL.
nxt_mem_bank:
			ld a, b
			cp #7F
			jr nz, nxt_mb_pg
			ld a, 9
			ret
nxt_mb_pg:
			ld a, c
			and 7
			sub 4
			jr nc, nxt_mb_ok
			xor a					; 0-3: page 0
nxt_mb_ok:
			push de
			ld e, a
			ld a, c
			and #F8
			srl a					; ordinal * 4
			add a, e
			add a, ZXN_FIRSTBANK
			pop de
			ret

; nxt_win - BC = a RAM setting -> its 16K Next bank into the window #4000-#7FFF (MMU
; slots 2, 3): what out (c), c does with a setting on the CPC - for a program's own asm
; (CyborgOS's hypervisor) that switches the window itself, outside the Memory class
; (ntc_rampt is not touched, as the CPC's out doesn't). Keeps every register, as the out
; does (AF too). ntc_zxsel is kept for the interrupt handler's re-select. On the real
; stack only (call: never from the thread)
nxt_win:
			push af
			push bc
			push de
			call nxt_mem_bank		; A = the 16K Next bank
			add a, a				; its first 8K page
			ld d, a
			ld bc, #243B
			ld a, #52
			ld (ntc_zxsel), a
			out (c), a
			inc b
			out (c), d				; MMU slot 2 = the page
			dec b
			ld a, #53
			ld (ntc_zxsel), a
			out (c), a
			inc b
			inc d
			out (c), d				; MMU slot 3 = page + 1
			pop de
			pop bc
			pop af
			ret

; nxt_mem_se_out - BC = the RAM setting (B = ZXN_SETB, C = the bank's ordinal * 8 + 4 +
; page: nxt_mem_bank): the Next 16K bank into the window (slots 2, 3). B = #7F (page 1 /
; plain RAM) = the program's own window bank 9. Reached by jp from mem_se_out; exits
; through mem_se_end. Called on the real stack (mem_sel pushed there).
; ntc_zxsel is kept so an interrupt handler can re-assert the window.
nxt_mem_se_out:
			ld (ntc_rampt), bc
			call nxt_mem_bank			; A = the 16K Next bank (B = #7F: main RAM's own, bank 9)
			add a, a					; first 8K page = Next 16K bank * 2
			ld d, a
			ld bc, #243B
			ld a, #52
			ld (ntc_zxsel), a
			out (c), a
			inc b
			out (c), d
			dec b
			ld a, #53
			ld (ntc_zxsel), a
			out (c), a
			inc b
			inc d
			out (c), d
			jp mem_se_end
	ENDIF

; ============================================================
; ntc_lib_msx.asm - MSX-DOS 2 / Nextor platform banking (msxdos)
; (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
; ------------------------------------------------------------
; The MSX versions of the banking primitives the CPC-modelled Memory
; manager (ntc_mem, in ntc_lib_cpc.asm) switches platform on, as the
; Next's are in ntc_lib_nxt.asm:
;   msx_mem_probe   - the mapper's segments (mem_probe's MSX branch)
;   msx_mem_jbc     - 64K bank -> its page 0's RAM setting (mem_jbc's)
;   msx_mem_se_out  - a RAM setting into the window #4000-#7FFF (mem_se_out's)
;   msx_win         - the same for a program's own asm (CyborgOS), as out (c), c
;   msx_mem_bank    - a RAM setting -> its segment
; The whole section is IFDEF NTC_MSXDOS: nothing on any other platform.
;
; The mapper's 16K segments come from MSX-DOS 2's mapper support (EXTBIO
; #FFCA, D = 4, E = 2: the jump table): ALL_SEG takes every free user segment
; of the primary mapper at the probe (MSX-DOS 2 frees them when the program
; ends), 4 a 64K "bank" in the order given (a bank's 4 needn't be next to each
; other: its segments are looked up, msx_segs). The window is page 1, changed
; with PUT_P1 so that MSX-DOS 2 knows what is in it (a BDOS call reading into
; the window reads into that segment). Main RAM's own page 1 (the setting
; #7FC0) is the segment the program started with (GET_P1).
;
; The RAM setting (BC) is shaped as the CPC's gate-array one, as on the Next,
; so that the CPC's setting arithmetic (a bank's "C2" setting = its page 0's
; and #F8 or 2; its page n in the window = and #F8 or 4 + n) works unchanged:
; B = MSX_SETB (1 - never 0, never #7F), C = the bank's ordinal * 8 + 4 + its
; page (0-3), or + 2 for the whole bank.
; ============================================================

ntc_rg454_e:
			IF ($ < 32768) && (ntc_rg455_e - ntc_rg455 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg455:
;## ntc_msx_bank ntc_mem @far
	IFDEF NTC_MSXDOS
MSX_SETB	equ 1					; B of an MSX RAM setting (see the top)
MSX_ALL		equ 0					; the jump table: ALL_SEG
MSX_FRE		equ 3					; FRE_SEG
MSX_PUT1	equ 30					; PUT_P1
MSX_GET0	equ 27					; GET_P0 (then GET_P1 30 + 3 ...: every 6)
	IF MEM_BANKS > 31
MSX_MAXSEG	equ 31 * 4				; segments taken at most: 31 banks (a setting's C = ordinal * 8 + ...: 0-31)
	ELSE
MSX_MAXSEG	equ MEM_BANKS * 4
	ENDIF

msx_mtab:		dw 0					; MSX-DOS 2's mapper support jump table (0: none)
msx_tpa:		db 0, 0, 0, 0			; the program's own segments, pages 0-3 (GET_Pn)
msx_nseg:		db 0					; segments in msx_segs
msx_segs:		ds MEM_BANKS * 4 + 4	; the segments, 4 a bank

; msx_mc - call the mapper support routine at offset E (A, B its arguments), on
; the real stack. Keeps DE; the routine's A, B, flags back
msx_mc:
			push de
			ld hl, (msx_mtab)
			ld d, 0
			add hl, de
			pop de
			jp (hl)

; msx_mem_probe - the mapper support's table (no MSX-DOS 2 / Nextor: none, no
; pages), the program's own segments, then every free user segment of the
; primary mapper, 4 a bank (up to MEM_BANKS); a part bank's are given back.
; Sets mem_banks and mem_found. Called from mem_probe on the real stack
msx_mem_probe:
			ld a, (#FB20)			; HOKVLD: bit 0 = EXTBIO is there
			and 1
			ret z
			xor a
			ld de, #0402			; mapper support: the jump table
			call #FFCA				; EXTBIO: HL = the table, A = segments (0: no mapper support)
			di
			or a
			ret z
			ld a, h
			or l
			ret z
			ld (msx_mtab), hl
			ld e, MSX_GET0			; GET_P0 .. GET_P3: the program's own
			ld hl, msx_tpa
			ld b, 4
msx_pr_own:
			push bc
			push de
			push hl
			call msx_mc
			di
			pop hl
			pop de
			pop bc
			ld (hl), a
			inc hl
			ld a, e
			add a, 6
			ld e, a
			djnz msx_pr_own
			ld hl, msx_segs
msx_pr_all:
			ld a, (msx_nseg)
			cp MSX_MAXSEG
			jr nc, msx_pr_done
			push hl
			xor a					; a user segment
			ld b, a					; of the primary mapper
			ld e, MSX_ALL
			call msx_mc
			di
			pop hl
			jr c, msx_pr_done		; (none left)
			ld (hl), a
			inc hl
			ld a, (msx_nseg)
			inc a
			ld (msx_nseg), a
			jr msx_pr_all
msx_pr_done:
			ld a, (msx_nseg)		; a part bank's segments back
			and 3
			jr z, msx_pr_banks
			ld b, a
msx_pr_fre:
			dec hl
			push bc
			push hl
			ld a, (hl)
			ld b, 0
			ld e, MSX_FRE
			call msx_mc
			di
			pop hl
			pop bc
			ld a, (msx_nseg)
			dec a
			ld (msx_nseg), a
			djnz msx_pr_fre
msx_pr_banks:
			ld a, (msx_nseg)
			srl a
			srl a					; 64K banks
			ld (mem_banks), a
			or a
			ret z
			ld hl, mem_found		; the banks found: 0, 1, 2 ...
			ld b, a
			ld e, 0
msx_pr_fl:
			ld (hl), e
			inc hl
			inc e
			djnz msx_pr_fl
			ret

; msx_mem_jbc - E = a 64K bank (0-63) -> BC = its page 0's RAM setting (B = MSX_SETB,
; C = E * 8 + 4: the four 16K parts step C, as the CPC's #C4 - #C7 do). Keeps DE, HL.
msx_mem_jbc:
			ld a, e
			add a, a
			add a, a
			add a, a
			add a, 4
			ld c, a
			ld b, MSX_SETB
			ret

; msx_mem_bank - BC = a RAM setting -> A = its segment: B = #7F (main RAM's own,
; #7FC0) = the program's own page 1; else C = ordinal * 8 + 4 + page ->
; msx_segs(ordinal * 4 + page) (the whole bank's "2" and 0-3: its page 0).
; Keeps BC, DE, HL.
msx_mem_bank:
			ld a, b
			cp #7F
			jr nz, msx_mb_pg
			ld a, (msx_tpa + 1)
			ret
msx_mb_pg:
			push hl
			push de
			ld a, c
			and 7
			sub 4
			jr nc, msx_mb_ok
			xor a					; 0-3: page 0
msx_mb_ok:
			ld e, a
			ld a, c
			and #F8
			srl a					; ordinal * 4
			add a, e
			ld e, a
			ld d, 0
			ld hl, msx_segs
			add hl, de
			ld a, (hl)
			pop de
			pop hl
			ret

; msx_win - BC = a RAM setting -> its segment into the window #4000-#7FFF (PUT_P1):
; what out (c), c does with a setting on the CPC - for a program's own asm (CyborgOS)
; that switches the window itself, outside the Memory class (ntc_rampt is not
; touched, as the CPC's out doesn't). Keeps every register, as the out does (AF too;
; interrupts as they were). On the real stack only (call: never from the thread)
msx_win:
			push af
			push bc
			push de
			push hl
			call msx_mem_bank
			ld e, MSX_PUT1
			call msx_mc
			pop hl
			pop de
			pop bc
			pop af
			ret

; msx_mem_se_out - BC = the RAM setting: its segment into the window (PUT_P1). Reached
; by jp from mem_se_out; exits through mem_se_end. On the real stack (mem_sel pushed there)
msx_mem_se_out:
			ld (ntc_rampt), bc
			call msx_mem_bank
			ld e, MSX_PUT1
			call msx_mc
			jp mem_se_end
	ENDIF

ntc_rg455_e:
			IF ($ < 32768) && (ntc_rg456_e - ntc_rg456 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg456:
;## ntc_plat_data
ntc_curx:		db 0			; cursor column (0 based) - kept here for Tab
ntc_cury:		db 0			; cursor row (0 based)
ntc_scols:		db 40			; columns in this mode
ntc_smode:		db 1			; screen mode (for the Graphics class)
ntc_fwa:		db 0			; ntc_fwcall: A on return
ntc_fwwrap:		db 0			; 1 = the last character made the firmware wrap
ntc_irqset:		db 0			; 1 = the firmware's fast ticker calls ntc_fwevt
ntc_irqv:		dw 0			; interrupt classes' counting (ntc_isl_tick), 0 = none
ntc_irqix:		dw 0
NTC_FWBLK	equ #A5F0		; the fast ticker's event block (central 32K, below the firmware)
ntc_fwtop:		dw #A600		; the top of free RAM (#A5F0 with the fast ticker's block)
ntc_fwblk:		dw NTC_FWBLK		; the fast ticker's event block: lower (and the top with it) when the ROMs
								; started take more RAM than AMSDOS's #A700-#ABFF (Option RomEnable)

ntc_rg456_e:
			IF ($ < 32768) && (ntc_rg457_e - ntc_rg457 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg457:
;## ntc_plat_fw ntc_plat_data ntc_data @shared
; ------------------------------------------------------------
; ntc_fwcall - IY = firmware address; A, BC, DE, HL go in and come
; back as the firmware leaves them (A also in ntc_fwa, carry kept).
; IX is kept. Interrupts are on during the call.
; ------------------------------------------------------------
ntc_fwcall:
			ld (ntc_hostix), ix
			ld (ntc_ip), sp
			ld sp, (ntc_csp)
			ei
			call ntc_fwjp
			di
			ld sp, (ntc_ip)
			ld (ntc_fwa), a
			ld ix, (ntc_hostix)
			jp (ix)
ntc_fwjp:
			jp (iy)

ntc_rg457_e:
			IF ($ < 32768) && (ntc_rg458_e - ntc_rg458 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg458:
;## ntc_plat_screen ntc_plat_fw ntc_plat_data ntc_data
; ntc_plat_putc - A = character: TXT OUTPUT. The firmware wraps by itself after
; the last column, so only the column is counted here; a new line straight after
; that wrap is left out (it would leave an empty line)
ntc_plat_putc:
			ld iy, #BB5A			; TXT OUTPUT
			ld (ntc_pclink), ix
			ld ix, ntc_pc_back
			jp ntc_fwcall
ntc_pc_back:
			ld ix, (ntc_pclink)
			xor a
			ld (ntc_fwwrap), a
			ld a, (ntc_scols)
			ld b, a
			ld a, (ntc_curx)
			inc a
			ld (ntc_curx), a
			cp b
			jr nz, ntc_pc_done
			xor a				; the firmware wrapped to the next line
			ld (ntc_curx), a
			inc a
			ld (ntc_fwwrap), a
ntc_pc_done:
			jp (ix)

; ntc_plat_newline - CR LF (the firmware scrolls); nothing straight after a wrap
ntc_plat_newline:
			ld a, (ntc_fwwrap)
			or a
			jr z, ntc_nl_go
			xor a
			ld (ntc_fwwrap), a
			jp (ix)
ntc_nl_go:
			ld (ntc_pclink), ix
			ld a, 13
			ld iy, #BB5A
			ld ix, ntc_nl_lf
			jp ntc_fwcall
ntc_nl_lf:
			ld a, 10
			ld iy, #BB5A
			ld ix, ntc_nl_done
			jp ntc_fwcall
ntc_nl_done:
			xor a
			ld (ntc_curx), a
			ld a, (ntc_cury)
			inc a
			cp 25
			jr c, ntc_nl_row
			ld a, 24
ntc_nl_row:
			ld (ntc_cury), a
			ld ix, (ntc_pclink)
			jp (ix)

ntc_pclink:		dw 0

ntc_rg458_e:
			IF ($ < 32768) && (ntc_rg459_e - ntc_rg459 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg459:
;## ntc_plat_mode @unit ntc_plat_screen ntc_plat_fw ntc_plat_data ntc_data
; ntc_plat_mode - A = mode 0-2 (3 = 2): SCR SET MODE (clears)
ntc_plat_mode:
			cp 3
			jr c, ntc_md_ok
			ld a, 2
ntc_md_ok:
			ld b, 20
			or a
			jr z, ntc_md_set
			ld b, 40
			cp 1
			jr z, ntc_md_set
			ld b, 80
ntc_md_set:
			ld (ntc_smode), a
			ld c, a
			ld a, b
			ld (ntc_scols), a
			xor a
			ld (ntc_fwwrap), a
			ld (ntc_curx), a
			ld (ntc_cury), a
			ld a, c
			ld iy, #BC0E			; SCR SET MODE
			jp ntc_fwcall

ntc_rg459_e:
			IF ($ < 32768) && (ntc_rg460_e - ntc_rg460 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg460:
;## ntc_plat_key ntc_plat_fw ntc_data
; ntc_plat_scankey - A = key from the firmware's buffer, or 0
ntc_plat_scankey:
			ld (ntc_kslink), ix
			ld iy, #BB09			; KM READ CHAR
			ld ix, ntc_ks_back
			jp ntc_fwcall
ntc_ks_back:
			ld ix, (ntc_kslink)
			jr c, ntc_ks_got
			xor a
			jp (ix)
ntc_ks_got:
			ld a, (ntc_fwa)
			jp (ix)

; ntc_plat_getkey - wait for a key: KM WAIT CHAR
ntc_plat_getkey:
			ld iy, #BB06			; KM WAIT CHAR
			jp ntc_fwcall
ntc_kslink:		dw 0

ntc_rg460_e:
			IF ($ < 32768) && (ntc_rg461_e - ntc_rg461 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg461:
;## ntc_plat_frame ntc_plat_fw
; ntc_plat_frame - MC WAIT FLYBACK
ntc_plat_frame:
			ld iy, #BD19
			jp ntc_fwcall

ntc_rg461_e:
			IF ($ < 32768) && (ntc_rg462_e - ntc_rg462 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg462:
;## ntc_plat_ticks ntc_plat_fw
; ntc_plat_ticks - HL = the firmware's 1/300 s clock (KL TIME PLEASE, low word)
ntc_plat_ticks:
			ld iy, #BD0D
			jp ntc_fwcall

ntc_rg462_e:
			IF ($ < 32768) && (ntc_rg463_e - ntc_rg463 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg463:
;## ntc_plat_exit ntc_plat_data ntc_plat_fw
ntc_plat_exit:
			ld bc, #7FC0		; RAM setting back to plain (a Memory page may be in #4000)
			out (c), c
			ld a, (ntc_irqset)	; the fast ticker out of the firmware's list
			or a
			jr z, ntc_ex_done
			xor a
			ld (ntc_irqset), a
			ld (ntc_irqix), ix
			ld hl, (ntc_fwblk)
			ld iy, #BCE6		; KL DEL FAST TICKER
			ld ix, ntc_ex_back
			jp ntc_fwcall
ntc_ex_back:
			ld ix, (ntc_irqix)
ntc_ex_done:
			jp (ix)

ntc_rg463_e:
			IF ($ < 32768) && (ntc_rg464_e - ntc_rg464 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg464:
;## ntc_plat_irq ntc_plat_data ntc_plat_fw ntc_data @shared
; ------------------------------------------------------------
; ntc_plat_irqon - normal mode's interrupt work under the firmware: the
; firmware keeps its own interrupt handler (keys, sound, AMSDOS), and a fast
; ticker event (KL NEW FAST TICKER, 300 a second) calls ntc_fwevt, which
; marks an Interrupt hook / interrupt classes as due - they run at the next
; safe point, as on cpc. The event block must be in the central 32K (the
; firmware reads it with the lower ROM on): #A5F0, just under the firmware's
; RAM, so the top of free RAM becomes #A5F0.
; The class is asynchronous, NOT express: the firmware (6128 ROM, KL EVENT
; at #01E2) calls an express event straight from the interrupt with the lower
; ROM on and never looks at the far address, so a routine below #4000 (this
; program starts at #0040) would run ROM code there. A plain asynchronous
; event is run at the end of the interrupt through KL FAR ICALL, which uses
; the far address: ROM select #FF = both ROMs off.
; ------------------------------------------------------------
ntc_plat_irqon:
			ld (ntc_irqix), ix
			ld hl, (ntc_fwblk)
			ld (ntc_fwtop), hl
			ld b, #80				; asynchronous, far address (not express: see above)
			ld c, #FF				; ROM select: upper and lower ROM off
			ld de, ntc_fwevt
			ld iy, #BCE0			; KL NEW FAST TICKER
			ld ix, ntc_iq_on
			jp ntc_fwcall
ntc_iq_on:
			ld a, 1
			ld (ntc_irqset), a
			ld ix, (ntc_irqix)
			jp (ix)
; the event routine: at the end of an interrupt (interrupts may be on; the
; firmware never runs it twice at once); AF, BC, DE, HL free
ntc_fwevt:
			ld a, (ntc_hookon)		; an Interrupt hook: run it at the next safe point
			or a
			jr z, ntc_fe_nohook
			ld (ntc_hookpend), a
ntc_fe_nohook:
			ld hl, (ntc_irqv)		; interrupt classes: count them
			ld a, h
			or l
			ret z
			jp (hl)
			ASSERT ntc_free <= NTC_FWBLK, "Interrupt / interrupt classes on cpcfw: the program and its arrays must end below #A5F0 (the firmware event block)"

; ============================================================
; File system (FileSystem class) - Load / Save through the firmware's
; cassette calls (CAS IN / CAS OUT DIRECT). With AMSDOS present they
; go to the disc (the drive that is selected), else to tape, exactly
; as BASIC's LOAD / SAVE do - with the firmware's own messages
; ("Press PLAY then any key", disc errors and Retry / Cancel).
;
; RUN"NAME of a binary resets the firmware (MC BOOT PROGRAM), which
; drops the background ROMs - AMSDOS too - so the cassette calls go
; back to tape. Loaded from BASIC and CALLed (MEMORY &1FFF : LOAD"NAME"
; : CALL &2000, built at org #2000), AMSDOS keeps running. Option
; RomEnable starts the ROMs again in the start code. The first file
; call checks: CAS IN OPEN (#BC77) a far call (RST 3, #DF) = AMSDOS has
; the cassette calls. AMSDOS's RAM is about #A700-#ABFF: the program
; must end below #A600 (checked when assembling). Devices: AMSDOS's own
; commands |TAPE, |DISC, |A, |B (KL FIND COMMAND, then KL FAR PCALL).
; ============================================================
; The methods are keywords: arguments into fs_a1 .. fs_a3, the
; result's address into fs_res, then fs_go with HL = the routine.
; fs_go runs it on the real stack with interrupts on and stores its
; HL result; a routine that fails jumps to fs_err with HL = status.

ntc_rg464_e:
			IF ($ < 32768) && (ntc_rg465_e - ntc_rg465 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg465:
;## ntc_plat_memtop ntc_plat_data
; ntc_plat_memtop - HL = the first byte the Memory class's Small heap must not
; use: #A600 (the firmware's and AMSDOS's RAM is above), #A5F0 when the fast
; ticker's event block is there (Interrupt, interrupt classes). Called on the
; real stack (call / ret).
ntc_plat_memtop:
			ld hl, (ntc_fwtop)
			ret

ntc_rg465_e:
			IF ($ < 32768) && (ntc_rg466_e - ntc_rg466 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg466:
;## ntc_plat_rmr ntc_plat_data
; ntc_plat_rmr - A = the gate array's ROM / mode byte now: the firmware keeps
; it in C' (B' = #7F), so Memory's CallBank can turn both ROMs off and put
; them back. Keeps BC, DE, HL.
ntc_plat_rmr:
			exx
			ld a, c
			exx
			ret


ntc_rg466_e:
ntc_end:				; the end of the program (and of its file)
			IF $ < #4000	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= #8000, "the window data (; @window) must fit in the window"
			ENDIF
ntc_fileend:			; the file ends here (the window data in it)
; arrays: after the program, not in its file - kw_bssinit checks they fit and clears them
ntc_bssfrom	equ ntc_end
			IF (ntc_bssfrom < 32768) && (ntc_bssfrom + ntc_bss_size > 16384)	; fwdref-ok
ntc_bss		equ 32768		; after Option Reserve #4000-#7FFF
			ELSE
ntc_bss		equ ntc_bssfrom
			ENDIF
arr_bk		equ ntc_bss + 0		; 42 bytes
arr_sg		equ ntc_bss + 42		; 42 bytes
arr_st		equ ntc_bss + 84		; 42 bytes
arr_wp		equ ntc_bss + 126		; 42 bytes
arr_bpg		equ ntc_bss + 168		; 168 bytes
arr_dv		equ ntc_bss + 336		; 42 bytes
arr_dm		equ ntc_bss + 378		; 42 bytes
arr_cnb		equ ntc_bss + 420		; 42 bytes
arr_cnc		equ ntc_bss + 462		; 42 bytes
arr_kw		equ ntc_bss + 504		; 32 bytes
arr_kd		equ ntc_bss + 536		; 224 bytes
arr_rb		equ ntc_bss + 760		; 128 bytes
arr_hyp_fib		equ ntc_bss + 888		; 2048 bytes
arr_hyp_fob		equ ntc_bss + 2936		; 2048 bytes
arr_ent_en		equ ntc_bss + 4984		; 12 bytes
ntc_bss_size	equ 4996
ntc_free	equ ntc_bss + ntc_bss_size	; the first free byte (heap, Memory tables)
			IF ntc_free <= 32768	; fwdref-ok
ntc_memtab	equ 32768		; the Memory class's tables: above the window (Option Reserve)
			ELSE
ntc_memtab	equ ntc_free
			ENDIF
; Option Reserve: the program and its arrays (ntc_start .. ntc_free) must stay out of these
			ASSERT (ntc_free <= 16384) || (ntc_bss >= 32768), "the program (or its arrays) reaches into Option Reserve #4000-#7FFF (Main.bas line 30)"
			SAVEAMSDOS "CYBORGOS.BIN", ntc_start, ntc_fileend - ntc_start, ntc_start