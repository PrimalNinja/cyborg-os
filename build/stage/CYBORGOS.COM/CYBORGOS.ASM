; the window data (; @window ... ; @endwindow in #asm): put in the window hole by its guard
			MACRO ntc_windata
; (the hypervisor's page from #5300 - #4000 the disc buffers, #5000 the font: Install copies
; these into each bank from there, FileCall 99 put them there at the start. zxn: the SD card's
; code from #4000 - no disc buffers, no font there)
    IFDEF NTC_MSXDOS
; ---- MSX: the files through MSX-DOS 2's (Nextor's) handle calls (BDOS #43 open, #44 create, #45
; close, #48 read, #49 write, #4A seek, #4D delete, #4E rename, #40 / #41 the search, #1B the free
; space, #19 the current drive). Here in the hypervisor's page (window data from #4000) - called
; with the page in the window, by the hooks in FileCall's code (the names it needs come as g_*
; from that block; this is Info's block, so no {name} here). Every drive letter A-H is a path
; ("A:" ...: the DOS's drives; CD, CV set a folder - "A:GAMES/"), so the hooks take every call
; (the boot archive's code, the Next's, finds nothing). MSX-DOS 2 takes its parameters in any
; page (the window's segment is PUT_P1's: it knows); its calls may turn interrupts on - di after.
; Paths: "/" goes to the DOS as "\".
fn_hyp_info_sd_fi:      db 0                    ; the file being read: its handle + 1 (0: none)
fn_hyp_info_sd_fo:      db 0                    ; the file being written: its handle + 1
fn_hyp_info_sd_hn:      db 0                    ; (spare)
fn_hyp_info_sd_par:     dw 0                    ; FileCall's parameters: f, fcb, slot, setting, dma, drive, buf (sd_h_init)
fn_hyp_info_sd_pfin:    dw 0                    ; fin's address, fout's (the slot reading / writing a file)
fn_hyp_info_sd_pfout:   dw 0
; sd_bufix - IX = buf (FileCall's); sd_fcbhl - HL = fcb
fn_hyp_info_sd_bufix:
            ld hl, (g_fl_bufa)      ; (not sd_par + 12: an open can come before sd_h_init)
            ld e, (hl)
            inc hl
            ld d, (hl)
            push de
            pop ix
            ret
fn_hyp_info_sd_fcbhl:
            ld hl, (fn_hyp_info_sd_par)
            inc hl
            inc hl
            ld a, (hl)
            inc hl
            ld h, (hl)
            ld l, a
            ret
fn_hyp_info_sd_dirs:    db 0                    ; sd_cache: 1 folders too
fn_hyp_info_sd_nm:      ds 64                   ; a name: the path and NAME.EXT, ASCIIZ
fn_hyp_info_sd_nm2:     ds 64                   ; (rename: the new one)
fn_hyp_info_sd_fib:     ds 64                   ; a file info block (the search's)
; sd_dos - the DOS's call C (its registers as it wants): A = 0 done (no carry), else its error
; (carry). B, DE, HL back as it gives them; interrupts off again
fn_hyp_info_sd_dos:
            push ix
            push iy
            call 5
            pop iy
            pop ix
            di
            or a
            ret z
            scf
            ret
; sd_hclose - the handle A + 1 (0: none) closed
fn_hyp_info_sd_hclose:
            or a
            ret z
            dec a
            ld b, a
            ld c, #45               ; _CLOSE
            jr fn_hyp_info_sd_dos
; sd_name - fl_name_s (the length, the characters) to sd_nm, ASCIIZ (the page in the window).
; sd_namehl: HL = such a name, DE = where; sd_nmz: the end
fn_hyp_info_sd_name:
            ld hl, g_fl_name_s
fn_hyp_info_sd_name1:
            ld de, fn_hyp_info_sd_nm
fn_hyp_info_sd_namehl:
            ld b, (hl)
            inc hl
            inc b
            dec b
            jr z, fn_hyp_info_sd_nmz
fn_hyp_info_sd_nmcp:
            ld a, (hl)
            cp '/'
            jr nz, fn_hyp_info_sd_nmcp1
            ld a, #5C               ; ("/" to the DOS as "\")
fn_hyp_info_sd_nmcp1:
            ld (de), a
            inc hl
            inc de
            djnz fn_hyp_info_sd_nmcp
fn_hyp_info_sd_nmz:
            xor a
            ld (de), a
            ret
; sd_folder - a path (length, characters at HL) to sd_nm as the DOS wants a folder: no "\" at
; the end ("A:GAMES/" -> "A:GAMES"; "A:" as it is: the drive's current folder). DE at its 0
fn_hyp_info_sd_folder:
            call fn_hyp_info_sd_name1
            dec de
            ld a, (de)
            cp #5C
            jr nz, fn_hyp_info_sd_fo_e
            dec de
            ld a, (de)
            inc de
            cp ':'
            jr z, fn_hyp_info_sd_fo_e           ; ("A:\": the top, kept)
            xor a
            ld (de), a
            ret
fn_hyp_info_sd_fo_e:
            inc de
            ret
; ---- fl_inopen: a path's file opened (carry: done), else the archive's open (none on the MSX)
@sd_h_inopen:
            ld a, (g_fl_sdf)
            or a
            jp z, g_fl_inopen_a
            call fn_hyp_info_sd_name
            ld de, fn_hyp_info_sd_nm
            ld a, 1                 ; no writing
            ld c, #43               ; _OPEN: B = the handle
            call fn_hyp_info_sd_dos
            jr c, fn_hyp_info_sd_io_no
            ld a, b
            inc a
            ld (fn_hyp_info_sd_fi), a
            call fn_hyp_info_sd_hdr             ; its AMSDOS header, if it has one, read past
            jr nz, fn_hyp_info_sd_io_rw
            scf
            ret
fn_hyp_info_sd_io_rw:                           ; (none: the start again - _SEEK to 0)
            ld a, (fn_hyp_info_sd_fi)
            dec a
            ld b, a
            xor a
            ld de, 0
            ld hl, 0
            ld c, #4A
            call fn_hyp_info_sd_dos
            scf
            ret
fn_hyp_info_sd_io_no:
            or a
            ret
; sd_hdr - the first record of the file just opened read into buf: Z when it is an AMSDOS header
; (the CPC's .CYB, a .BIN), which is then not part of the file - as AMSDOS's CAS IN OPEN leaves it
; out on the CPC, so a program reads "what CP/M sees" and Z: gets the program alone; NZ: a file
; without one - the caller reads from its start again
fn_hyp_info_sd_hdr:
            ld a, 128
            ld (g_fl_n), a
            ld hl, 0
            ld (g_fl_cnt), hl
            ld ix, (g_fl_bufa)      ; the record into sd_hb: the open has no buffer of the
            ld l, (ix + 0)          ; caller's (the hypervisor's own opens give none)
            ld h, (ix + 1)
            push hl
            ld hl, fn_hyp_info_sd_hb
            ld (ix + 0), l
            ld (ix + 1), h
            call g_fl_rdrec         ; (either driver: the one just opened)
            ld ix, (g_fl_bufa)
            pop hl
            ld (ix + 0), l
            ld (ix + 1), h
            jr z, fn_hyp_info_sd_hdr_no
            ld hl, fn_hyp_info_sd_hb + 128
            jp sd_amsh
fn_hyp_info_sd_hdr_no:
            inc a                   ; NZ
            ret
fn_hyp_info_sd_hb:      ds 128
; sd_h_ahdr - the archive's open: the header read past (the open's state back if there is none)
@sd_h_ahdr:
            ld hl, (g_fl_arec)
            push hl
            ld hl, (g_fl_aleft)
            push hl
            call fn_hyp_info_sd_hdr
            pop hl
            jr z, fn_hyp_info_sd_ah_yes
            ld (g_fl_aleft), hl
            pop hl
            ld (g_fl_arec), hl
            xor a
            ld (g_fl_aoff), a
            ret
fn_hyp_info_sd_ah_yes:
            pop hl
            ret
; ---- fl_rdrec: fl_n bytes (128 at most) into buf: A = how many (Z none), HL past them
@sd_h_rdrec:
            ld a, (fn_hyp_info_sd_fi)
            or a
            jp z, g_fl_rdrec_a
            dec a
            ld b, a
            call fn_hyp_info_sd_bufix
            push ix
            pop de
            push de
            ld a, (g_fl_n)
            ld l, a
            ld h, 0
            ld c, #48               ; _READ: HL = bytes read (the end of the file: an error, none)
            call fn_hyp_info_sd_dos
            jr nc, fn_hyp_info_sd_rr_ok
            ld hl, 0
fn_hyp_info_sd_rr_ok:
            ex de, hl
            pop hl
            add hl, de
            ld a, e
            or a
            ret
; ---- fl_inclose
@sd_h_inclose:
            ld a, (fn_hyp_info_sd_fi)
            or a
            jp z, g_fl_inclose_a
            call fn_hyp_info_sd_hclose
            xor a
            ld (fn_hyp_info_sd_fi), a
            ld hl, (fn_hyp_info_sd_pfin)
            ld (hl), a
            ret
; ---- 22: make - a new file to write (fout), where the name has a path (else 255: the archive)
@sd_h_make:
            ld hl, (fn_hyp_info_sd_pfout)
            ld a, (hl)
            or a
            jp nz, g_fp_done
            call g_fl_name
            ld a, (g_fl_sdf)
            or a
            jp z, g_fp_done
            call fn_hyp_info_sd_name
            ld de, fn_hyp_info_sd_nm
            xor a                   ; (reading and writing)
            ld b, a                 ; (no attributes; one there already: made anew)
            ld c, #44               ; _CREATE: B = the handle
            call fn_hyp_info_sd_dos
            jp c, g_fp_done
            ld a, b
            inc a
            ld (fn_hyp_info_sd_fo), a
            ld a, (g_fl_slot)
            ld hl, (fn_hyp_info_sd_pfout)
            ld (hl), a
            call fn_hyp_info_sd_fcbhl
            ld (g_fl_outfcb), hl
            ld a, 1
            ld (g_fl_outfcb + 2), a
            ld hl, 0
            ld (g_fl_outrec), hl
            jp g_fl_ok
; ---- 21 / 34: the record in buf written
@sd_h_write:
            ld a, (fn_hyp_info_sd_fo)
            or a
            jp z, g_fp_done
            dec a
            ld b, a
            call fn_hyp_info_sd_bufix
            push ix
            pop de
            ld hl, 128
            ld c, #49               ; _WRITE: HL = bytes written
            call fn_hyp_info_sd_dos
            jp c, g_fp_done
            ld a, l
            cp 128
            jp nz, g_fp_done        ; (fewer: the disc is full)
            ld hl, (g_fl_outrec)
            inc hl
            ld (g_fl_outrec), hl
            jp g_fl_ok
; ---- 16: close - the file being written
@sd_h_clout:
            ld a, (fn_hyp_info_sd_fo)
            call fn_hyp_info_sd_hclose
            xor a
            ld (fn_hyp_info_sd_fo), a
            jp g_fl_ok
; ---- 19: delete (a folder too: _DELETE takes an empty one)
@sd_h_del:
            ld a, (g_fl_sdf)
            or a
            jp z, g_fp_done
            call fn_hyp_info_sd_name
            call fn_hyp_info_sd_unread          ; (open to read still, as CP/M leaves it: closed first)
            xor a
            ld (g_fl_yes), a
            ld de, fn_hyp_info_sd_nm
            ld c, #4D               ; _DELETE
            call fn_hyp_info_sd_dos
            jp c, g_fp_done
            jp g_fl_ok
; ---- 23: rename - fl_name_s the old name, fl_new_s the new (the DOS wants the new name alone:
; past its last ":" or "\")
@sd_h_ren:
            ld a, (g_fl_sdf)
            or a
            jp z, g_fp_done
            call fn_hyp_info_sd_name
            call fn_hyp_info_sd_unread
            ld hl, g_fl_new_s
            ld de, fn_hyp_info_sd_nm2
            call fn_hyp_info_sd_namehl
            ld hl, fn_hyp_info_sd_nm2
            ld de, fn_hyp_info_sd_nm2
fn_hyp_info_sd_rn_lp:
            ld a, (hl)
            or a
            jr z, fn_hyp_info_sd_rn_go
            inc hl
            cp ':'
            jr z, fn_hyp_info_sd_rn_cut
            cp #5C
            jr nz, fn_hyp_info_sd_rn_lp
fn_hyp_info_sd_rn_cut:
            ld e, l
            ld d, h
            jr fn_hyp_info_sd_rn_lp
fn_hyp_info_sd_rn_go:
            ex de, hl               ; HL = the new name alone
            ld de, fn_hyp_info_sd_nm
            ld c, #4E               ; _RENAME
            call fn_hyp_info_sd_dos
            jp c, g_fp_done
            jp g_fl_ok
; ---- 17: the folder's files into the search's cache (#6000): the path's (the SD card), else
; the archive's. DE: past the path at fl_name_s + 1
@sd_h_srch1:
            ld a, (g_fl_sdf)
            or a
            jr nz, fn_hyp_info_sd_s1_sd
            call g_fl_arc_dir
            jp g_fl_srch
fn_hyp_info_sd_s1_sd:
            ld hl, -(g_fl_name_s + 1)
            add hl, de
            ld a, l
            ld (g_fl_name_s), a
            ld hl, g_fl_name_s
            xor a
            call fn_hyp_info_sd_cache
            jp g_fl_srch
; sd_cache - the folder whose path is at HL (length, characters) into the cache: A = 1 folders
; too (DIR), 0 files only (CP/M's search). An entry (64 bytes): 1, the name (8 + 3), kind (1 a
; folder), the attributes, the length as a word (#FFFF: 64K or more), the size (4), time, date
; (MS-DOS's words). fl_cn how many (FL_CMAX at most). A = 0 done, else the DOS's error
fn_hyp_info_sd_cache:
            ld (fn_hyp_info_sd_dirs), a
            call fn_hyp_info_sd_folder          ; (DE at its 0)
            dec de
            ld a, (de)
            inc de
            cp ':'
            jr z, fn_hyp_info_sd_ca_pat
            cp #5C
            jr z, fn_hyp_info_sd_ca_pat
            ld a, #5C
            ld (de), a
            inc de
fn_hyp_info_sd_ca_pat:
            ld hl, fn_hyp_info_sd_all
            ld bc, 4
            ldir                    ; "*.*", 0
            xor a
            ld (g_fl_cn), a
            ld hl, #6000
            ld (g_fl_at), hl
            ld de, fn_hyp_info_sd_nm
            ld a, (fn_hyp_info_sd_dirs)
            or a
            ld b, 0
            jr z, fn_hyp_info_sd_ca_b
            ld b, #10               ; (folders too)
fn_hyp_info_sd_ca_b:
            ld ix, fn_hyp_info_sd_fib
            ld c, #40               ; _FFIRST
            call fn_hyp_info_sd_dos
            jr nc, fn_hyp_info_sd_ca_one
            cp #D7                  ; .NOFIL: an empty folder
            ret nz
            xor a
            ret
fn_hyp_info_sd_ca_lp:
            ld ix, fn_hyp_info_sd_fib
            ld c, #41               ; _FNEXT
            call fn_hyp_info_sd_dos
            jr c, fn_hyp_info_sd_ca_end
fn_hyp_info_sd_ca_one:
            ld a, (fn_hyp_info_sd_fib + 1)
            cp '.'
            jr z, fn_hyp_info_sd_ca_lp          ; (".", "..": not entries)
            ld a, (g_fl_cn)
            cp g_FL_CMAX
            jr nc, fn_hyp_info_sd_ca_end
            ld hl, (g_fl_at)
            ld (hl), 1
            inc hl
            ex de, hl
            ld hl, fn_hyp_info_sd_fib + 1
            call fn_hyp_info_sd_n11             ; the name, DE on past it
            ld a, (fn_hyp_info_sd_fib + 14)
            bit 4, a
            ld a, 0
            jr z, fn_hyp_info_sd_ca_k
            inc a
fn_hyp_info_sd_ca_k:
            ld (de), a              ; kind
            inc de
            ld a, (fn_hyp_info_sd_fib + 14)
            ld (de), a              ; the attributes
            inc de
            ld hl, (fn_hyp_info_sd_fib + 21)    ; the size's low word (#FFFF when more)
            ld a, (fn_hyp_info_sd_fib + 23)
            ld c, a
            ld a, (fn_hyp_info_sd_fib + 24)
            or c
            jr z, fn_hyp_info_sd_ca_sz
            ld hl, #FFFF
fn_hyp_info_sd_ca_sz:
            ex de, hl
            ld (hl), e
            inc hl
            ld (hl), d
            inc hl
            ex de, hl
            ld hl, fn_hyp_info_sd_fib + 21
            ld bc, 4
            ldir                    ; the size
            ld hl, fn_hyp_info_sd_fib + 15
            ld bc, 4
            ldir                    ; time, date
            ld hl, (g_fl_at)
            ld bc, 64
            add hl, bc
            ld (g_fl_at), hl
            ld hl, g_fl_cn
            inc (hl)
            jp fn_hyp_info_sd_ca_lp
fn_hyp_info_sd_ca_end:
            xor a
            ret
fn_hyp_info_sd_all:     db "*.*", 0
; sd_unread - the file fl_name_s names closed if it is the one being read (fl_inname): CP/M
; needs no close after reading, so a program deletes or renames it still open - esxDOS says
; access denied to that
fn_hyp_info_sd_unread:
            ld a, (fn_hyp_info_sd_fi)
            or a
            ret z
            ld hl, g_fl_name_s
            ld de, g_fl_inname
            ld a, (de)
            cp (hl)
            ret nz
            ld b, a
            inc b
fn_hyp_info_sd_ur_cmp:
            ld a, (de)
            cp (hl)
            ret nz
            inc hl
            inc de
            djnz fn_hyp_info_sd_ur_cmp
            jp sd_h_inclose
; sd_amsh - A = the bytes fl_rdrec read (not 0), HL past them: Z when that record is an AMSDOS
; header (a file's first: fl_cnt = 0, 128 read, the checksum at 67 the sum of bytes 0-66, not 0); else NZ
; with A as it was. BC, DE, HL used
@sd_amsh:
            cp 128
            jr nz, fn_hyp_info_sd_am_no
            push hl
            ld hl, g_fl_cnt
            ld a, (hl)
            inc hl
            or (hl)
            pop hl
            jr nz, fn_hyp_info_sd_am_no         ; (not the first record)
            ld de, -128
            add hl, de              ; the record
            ld bc, 67
            ld de, 0
fn_hyp_info_sd_am_lp:
            ld a, (hl)
            add a, e
            ld e, a
            jr nc, fn_hyp_info_sd_am_c
            inc d
fn_hyp_info_sd_am_c:
            inc hl
            dec c
            jr nz, fn_hyp_info_sd_am_lp
            ld a, d
            or e
            jr z, fn_hyp_info_sd_am_no          ; (0: no header)
            ld a, (hl)
            cp e
            jr nz, fn_hyp_info_sd_am_no
            inc hl
            ld a, (hl)
            cp d
            jr nz, fn_hyp_info_sd_am_no
            xor a                   ; Z: a header
            ret
fn_hyp_info_sd_am_no:
            ld a, 1
            or a                    ; NZ
            ret
; sd_zcopy - the string at HL (to its 0) to DE
fn_hyp_info_sd_zcopy:
            ld a, (hl)
            ld (de), a
            inc hl
            inc de
            or a
            jr nz, fn_hyp_info_sd_zcopy
            ret
; sd_zend - HL past the 0 ending the string at HL
fn_hyp_info_sd_zend:
            ld a, (hl)
            inc hl
            or a
            jr nz, fn_hyp_info_sd_zend
            ret
; sd_n11 - the name at HL (NAME.EXT, ASCIIZ) as 8 + 3 at DE (spaces), DE on past it
fn_hyp_info_sd_n11:
            push de
            ld b, 11
            ld a, ' '
fn_hyp_info_sd_n1_sp:
            ld (de), a
            inc de
            djnz fn_hyp_info_sd_n1_sp
            pop de
            push de
            ld b, 8
fn_hyp_info_sd_n1_nm:
            ld a, (hl)
            or a
            jr z, fn_hyp_info_sd_n1_end
            cp '.'
            jr z, fn_hyp_info_sd_n1_dot
            ld (de), a
            inc hl
            inc de
            djnz fn_hyp_info_sd_n1_nm
fn_hyp_info_sd_n1_sk:                           ; (past 8: on to the dot)
            ld a, (hl)
            or a
            jr z, fn_hyp_info_sd_n1_end
            inc hl
            cp '.'
            jr nz, fn_hyp_info_sd_n1_sk
            dec hl
fn_hyp_info_sd_n1_dot:
            inc hl                  ; past the dot
            pop de
            push de
            ex de, hl
            ld bc, 8
            add hl, bc
            ex de, hl
            ld b, 3
fn_hyp_info_sd_n1_ex:
            ld a, (hl)
            or a
            jr z, fn_hyp_info_sd_n1_end
            ld (de), a
            inc hl
            inc de
            djnz fn_hyp_info_sd_n1_ex
fn_hyp_info_sd_n1_end:
            pop de
            ld hl, 11
            add hl, de
            ex de, hl
            ret
; ---- BDOS 30 (fl_unicall): the block in FL_UB, its op 0-8 at FL_UB
;   0 here: 0;  1 the letter's path (fl_uc_get);  2 the letter's path set (a folder of the SD card:
;   F_OPENDIR tries it);  3 the devices: the SD card's drive letter;  4 a device: folders, its free K
;   (F_GETFREE);  5 the folder's entry Word(2) (the cache, filled at entry 0);  6 a folder made
;   (F_MKDIR);  7 no header (255);  8 the next delete may take a folder
@sd_h_uc:
            ld a, (g_FL_UB)
            or a
            jp z, g_fl_ok
            dec a
            jp z, g_fl_uc_get
            dec a
            jp z, fn_hyp_info_sd_uc_set
            dec a
            jr z, fn_hyp_info_sd_uc_dev
            dec a
            jr z, fn_hyp_info_sd_uc_inf
            dec a
            jp z, fn_hyp_info_sd_uc_dir
            dec a
            jr z, fn_hyp_info_sd_uc_md
            dec a
            jp z, g_fp_done
            ld a, 1
            ld (g_fl_yes), a
            jp g_fl_ok
fn_hyp_info_sd_uc_dev:
            ld a, (fn_hyp_info_sd_drv)
            or #80
            ld (g_FL_UB + 2), a
            ld a, 255
            ld (g_FL_UB + 3), a
            xor a
            ld b, 66
            jp g_fl_uc_back
fn_hyp_info_sd_uc_inf:
            ld a, 3                 ; there (bit 0), folders (bit 1)
            ld (g_FL_UB + 8), a
            ld e, 0                 ; _ALLOC (the current drive): HL free clusters, A sectors a
            ld c, #1B               ; cluster: BCDE = HL * A 512 byte sectors
            call 5
            di
            ld c, a
            ex de, hl
            ld hl, 0
            ld b, 0
fn_hyp_info_sd_ui_mul:
            ld a, c
            or a
            jr z, fn_hyp_info_sd_ui_md
            add hl, de
            jr nc, fn_hyp_info_sd_ui_nc
            inc b
fn_hyp_info_sd_ui_nc:
            dec c
            jr fn_hyp_info_sd_ui_mul
fn_hyp_info_sd_ui_md:
            ld c, b
            ld b, 0
            ex de, hl               ; BCDE
            srl b                   ; K: halved
            rr c
            rr d
            rr e
            ld hl, g_FL_UB + 10
            ld (hl), e
            inc hl
            ld (hl), d
            inc hl
            ld (hl), c
            inc hl
            ld (hl), b
            inc hl
            ld b, 4
fn_hyp_info_sd_ui_z:
            ld (hl), 0              ; (all K: not known)
            inc hl
            djnz fn_hyp_info_sd_ui_z
            ex de, hl
            ld hl, fn_hyp_info_sd_desc
            ld bc, 8
            ldir
            xor a
            ld b, 72
            jp g_fl_uc_back
fn_hyp_info_sd_desc:    db "MSX-DO", "S" + #80, 255
fn_hyp_info_sd_uc_md:
            ld hl, g_FL_UB + 2
            call fn_hyp_info_sd_folder
            ld de, fn_hyp_info_sd_nm
            xor a
            ld b, #10               ; _CREATE with the folder's attribute: a folder made
            ld c, #44
            call fn_hyp_info_sd_dos
            jp nc, g_fl_ok
            ld (g_fl_res), a
            jp g_fp_done
; 2: the letter's path from Byte(2) (length, 31 at most, "/" put at its end when it has no "/" or
; ":"): 0 the letter itself again; a folder of a drive, else the DOS's error
fn_hyp_info_sd_uc_set:
            ld a, (g_FL_UB + 1)
            call g_fl_mapa
            jp c, g_fp_done
            push hl
            ld a, (g_FL_UB + 2)
            or a
            jr z, fn_hyp_info_sd_us_put
            cp 32
            jr nc, fn_hyp_info_sd_us_no
            ld b, a
            ld hl, g_FL_UB + 3
fn_hyp_info_sd_us_up:                           ; capitals
            ld a, (hl)
            cp 'a'
            jr c, fn_hyp_info_sd_us_c
            cp 'z' + 1
            jr nc, fn_hyp_info_sd_us_c
            sub 32
            ld (hl), a
fn_hyp_info_sd_us_c:
            inc hl
            djnz fn_hyp_info_sd_us_up
            dec hl
            ld a, (hl)
            cp ':'
            jr z, fn_hyp_info_sd_us_try
            cp '/'
            jr z, fn_hyp_info_sd_us_try
            ld a, (g_FL_UB + 2)
            cp 31
            jr nc, fn_hyp_info_sd_us_no
            inc a
            ld (g_FL_UB + 2), a
            inc hl
            ld (hl), '/'
fn_hyp_info_sd_us_try:
            ld hl, g_FL_UB + 2
            call fn_hyp_info_sd_folder          ; (DE at its 0)
            dec de
            ld a, (de)
            cp ':'
            jr z, fn_hyp_info_sd_us_put         ; (a drive alone: its current folder; its top)
            cp #5C
            jr z, fn_hyp_info_sd_us_put
            ld de, fn_hyp_info_sd_nm
            ld b, #10               ; _FFIRST: there, and a folder?
            ld ix, fn_hyp_info_sd_fib
            ld c, #40
            call fn_hyp_info_sd_dos
            jr c, fn_hyp_info_sd_us_err
            ld a, (fn_hyp_info_sd_fib + 14)
            and #10
            ld a, #D6               ; (.NODIR when a file)
            scf
            jr z, fn_hyp_info_sd_us_err
fn_hyp_info_sd_us_put:
            pop de
            ld hl, g_FL_UB + 2
            ld bc, 32
            ldir
            jp g_fl_ok
fn_hyp_info_sd_us_no:
            pop hl
            jp g_fp_done
fn_hyp_info_sd_us_err:
            pop hl
            or a
            jr nz, fn_hyp_info_sd_us_e1
            inc a
fn_hyp_info_sd_us_e1:
            ld (g_fl_res), a
            jp g_fp_done
; 5: the folder's entry Word(2): Byte(1) the letter (its path; none: 254 - the archive, listed
; by the search), 0 the path at Byte(28). Entry 0 fills the cache (folders too). Back: Byte(4)
; its bits (bit 4 a folder, 0 read only, 1 hidden, 2 system), Byte(5-8) its size, Byte(9-15)
; its date (the year as a word, month, day, hours, minutes, seconds), Byte(16-26) its name: 0;
; 1 no more
fn_hyp_info_sd_uc_dir:
            ld a, (g_FL_UB + 1)
            or a
            jr z, fn_hyp_info_sd_ud_p
            call g_fl_mapa
            jp c, fn_hyp_info_sd_ud_254
            jp z, fn_hyp_info_sd_ud_254
            jr fn_hyp_info_sd_ud_k
fn_hyp_info_sd_ud_p:
            ld hl, g_FL_UB + 28
            ld a, (hl)
            cp 32
            jp nc, g_fp_done
fn_hyp_info_sd_ud_k:
            ld de, (g_FL_UB + 2)
            ld a, d
            or e
            jr nz, fn_hyp_info_sd_ud_n
            ld a, 1
            call fn_hyp_info_sd_cache           ; (HL = the path)
            or a
            jr z, fn_hyp_info_sd_ud_n
            ld (g_fl_res), a
            jp g_fp_done
fn_hyp_info_sd_ud_n:
            ld a, (g_fl_cn)
            ld hl, (g_FL_UB + 2)
            ld c, a
            ld b, 0
            or a
            sbc hl, bc
            jp nc, fn_hyp_info_sd_ud_end        ; no more (1)
            ld hl, (g_FL_UB + 2)
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, #6000
            add hl, de              ; the entry
            push hl
            ld bc, 13
            add hl, bc
            ld a, (hl)
            and #17
            ld (g_FL_UB + 4), a
            inc hl
            inc hl
            inc hl
            ld de, g_FL_UB + 5
            ld bc, 4
            ldir                    ; the size
            ld e, (hl)              ; time
            inc hl
            ld d, (hl)
            inc hl
            ld c, (hl)              ; date
            inc hl
            ld b, (hl)
            push de
            ld a, b
            srl a
            ld l, a
            ld h, 0
            ld de, 1980
            add hl, de
            ld (g_FL_UB + 9), hl    ; the year
            ld a, b
            and 1
            rlca
            rlca
            rlca
            ld h, a
            ld a, c
            rlca
            rlca
            rlca
            and 7
            or h
            ld (g_FL_UB + 11), a    ; the month
            ld a, c
            and 31
            ld (g_FL_UB + 12), a    ; the day
            pop de
            ld a, d
            srl a
            srl a
            srl a
            ld (g_FL_UB + 13), a    ; hours
            ld a, d
            and 7
            rlca
            rlca
            rlca
            ld h, a
            ld a, e
            rlca
            rlca
            rlca
            and 7
            or h
            ld (g_FL_UB + 14), a    ; minutes
            ld a, e
            and 31
            add a, a
            ld (g_FL_UB + 15), a    ; seconds
            pop hl
            inc hl
            ld de, g_FL_UB + 16
            ld bc, 11
            ldir                    ; the name
            xor a
            ld b, 28
            jp g_fl_uc_back
fn_hyp_info_sd_ud_254:
            ld a, 254
            ld (g_fl_res), a
            jp g_fp_done
fn_hyp_info_sd_ud_end:
            ld a, 1
            ld (g_fl_res), a
            jp g_fp_done
; ---- at the start (FileCall 99, the page in the window): every drive letter A-H the DOS's own
; ("A:" ...: a path, so the hooks take it); FileCall 99's answer the current drive's letter
; (_CURDRV) - Main's boot drive; then fl_done
fn_hyp_info_sd_drv:     db 'A'                  ; the current drive's letter
@sd_h_init:
            ld (fn_hyp_info_sd_par), hl         ; (fl_inst: HL FileCall's parameters, DE fin, BC fout)
            ld (fn_hyp_info_sd_pfin), de
            ld (fn_hyp_info_sd_pfout), bc
            ld a, 1
            ld (g_fl_cjf), a
            ld hl, g_FL_MAP
            ld de, g_FL_MAP + 1
            ld bc, 511
            ld (hl), 0
            ldir
            ld c, #19               ; _CURDRV: L = the drive (0 A)
            call 5
            di
            ld a, l
            and 7
            add a, 'A'
            ld (fn_hyp_info_sd_drv), a
            ld hl, g_FL_MAP         ; A: - H: "A:" - "H:"
            ld b, 'A'
fn_hyp_info_sd_in_lp:
            ld (hl), 2
            inc hl
            ld (hl), b
            inc hl
            ld (hl), ':'
            ld de, 30
            add hl, de
            inc b
            ld a, b
            cp 'I'
            jr nz, fn_hyp_info_sd_in_lp
            ld a, (fn_hyp_info_sd_drv)
            ld (g_fl_res), a
            jp g_fl_done
; ---- FileShut: the slot's files closed with the rest
@sd_shut_in:
            ld a, (fn_hyp_info_sd_fi)
            call fn_hyp_info_sd_hclose
            xor a
            ld (fn_hyp_info_sd_fi), a
            ret
@sd_shut_out:
            ld a, (fn_hyp_info_sd_fo)
            call fn_hyp_info_sd_hclose
            xor a
            ld (fn_hyp_info_sd_fo), a
            ret
    ENDIF
            ds #5300 - $
; page zero (#0000-#0080)
fn_hyp_info_hi_p0:
            db #C3
            dw fn_hyp_info_sb_bwb                           ; #0000: warm boot - the BIOS's WBOOT (the task
            db 0, 0                             ; ends); (#0001) - 3: the BIOS jump table
            db #C3
            dw fn_hyp_info_sb_start                         ; #0005: BDOS (#0006: the top of the TPA)
            ds #38 - 8
            db #C3
            dw fn_hyp_info_sb_int                           ; #0038: the interrupt
            ds #44 - #3B
    IFDEF NTC_MSXDOS
            ds #5C - #44                        ; (MSX: no #0044 glue - the switch is in page 3: sb_hout / sb_hin at HISW)
    ELSE
            db #ED, #49                         ; #0044: out (c), c
            db #C3
            dw fn_hyp_info_sb_land                          ; #0046: this bank switched in
            ds #5C - #49
    ENDIF
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
            ld a, c                             ; BDOS: C = function, DE = argument
            cp 6                                ; 6 and 11 with interrupts left as they are: a key poll
            jr z, fn_hyp_info_sb_f6                         ; loop is the time a slot has them in at all, and a
            cp 11                               ; tick missed there is the Next's pulse gone (sb_get
            jr z, fn_hyp_info_sb_stat                       ; closes them for the two instructions that take the key)
            di
            cp 2
            jp z, fn_hyp_info_sb_put
            cp 1
            jp z, fn_hyp_info_sb_f1
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
            jr z, fn_hyp_info_sb_poll
            ld a, #FF
            jr fn_hyp_info_sb_ret
fn_hyp_info_sb_get:
            ld hl, 63105                        ; 6 / #FF: the key or 0 (no wait)
            di
            ld a, (hl)
            ld (hl), 0
            or a
            jr nz, fn_hyp_info_sb_ret
fn_hyp_info_sb_poll:                                        ; no key: a program polling (Inkey, Input) gives the
            ld hl, fn_hyp_info_SB_POLLC                     ; hypervisor a turn every 256th empty poll - its keys
            inc (hl)                            ; reach KEY only when it runs, and a tight poll loop
            jr nz, fn_hyp_info_sb_zero                      ; with interrupts off (NTC: on for an instruction a
            ld c, 12                            ; call) can miss the Next's INT pulse for ever
            call fn_hyp_info_sb_call                        ; (a far call ends the slot's turn, as 12 does)
            jr fn_hyp_info_sb_zero
fn_hyp_info_sb_f1:
            call fn_hyp_info_sb_key                         ; 1: a key (waited for), echoed
            push af
            ld e, a
            call fn_hyp_info_sb_putc
            pop af
            jr fn_hyp_info_sb_ret
fn_hyp_info_sb_put:
            di
            call fn_hyp_info_sb_putc                        ; 2: E out (6 / E < #FE too)
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
            ld c, #81                           ; (BC, DE: nothing after needs them)
            call fn_hyp_info_sb_call
            di
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
fn_hyp_info_sb_lbuf:    equ #F6E9                           ; (the bank's own bytes after the program's name,
fn_hyp_info_sb_lcnt:    equ #F6EB                           ; #F6D8-#F6E4, not the stub's: it is at its limit)
fn_hyp_info_SB_POLLC:   equ #F6E8
fn_hyp_info_sb_call:
            di                                  ; (a poll's turn given with them in)
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
            ld bc, #7FC0
            scf                                 ; carry: a far call
    IFDEF NTC_MSXDOS
            jp fn_hyp_info_sb_hout
    ELSE
            jp #0044
    ENDIF
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
            ld bc, #7FC0
            or a                                ; no carry: an interrupt
    IFDEF NTC_MSXDOS
            jp fn_hyp_info_sb_hout
    ELSE
            jp #0044
    ENDIF
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
    IFDEF NTC_MSXDOS
; The MSX's switch, both ways, in each bank's own page 3 below #FFFE (HISW): the mapper's pages
; change one port at a time, so the code doing it sits in the one page that changes last (hyp ->
; task) or not at all (task -> hyp). MSX-DOS 2 keeps #0038-#005B of the hypervisor's page 0 (its
; interrupt and slot code), so no #0044 glue there. Install copies this in and patches the
; immediates: the bank's own segments (pages 0-2) and the hypervisor's (msx_tpa).
; sb_hin: hyp -> task. Run maps the task's page 3 (out (#FF)), leaves ra / rclr / rhl in SWAP and
; jumps here: pages 0-2 to the task's, then sb_land.
; sb_hout: task -> hyp (the stubs' far call and interrupt): A and its carry into AF', pages 0-2
; to the hypervisor's, then its receiver msx_recv (Run's block) maps its page 3 and lands.
fn_hyp_info_hi_sw:
            DISP 65488
fn_hyp_info_sb_hin:
            ld a, 0                             ; (HISW + 1: the bank's page 0 segment)
            out (#FC), a
            ld a, 0                             ; (HISW + 5: page 1)
            out (#FD), a
            ld a, 0                             ; (HISW + 9: page 2)
            out (#FE), a
            ld a, (63185 + 2)
            ld e, a                             ; rclr -> E (for sb_land)
            ld hl, (63185 + 3)                 ; far-call result -> HL
            ld a, (63185 + 1)                  ; far-call result -> A
            jp fn_hyp_info_sb_land
fn_hyp_info_sb_hout:
            db #08                              ; ex af, af': A and the carry (far / interrupt) kept
            ld a, 0                             ; (HISW + 27: the hypervisor's page 0 segment)
            out (#FC), a
            ld a, 0                             ; (HISW + 31: page 1)
            out (#FD), a
            ld a, 0                             ; (HISW + 35: page 2)
            out (#FE), a
            jp msx_recv                         ; the hypervisor's pages 0-2: its receiver
fn_hyp_info_sb_hin_end:
            ENT
            ASSERT fn_hyp_info_sb_hout - fn_hyp_info_sb_hin == 25, "Install patches fn_hyp_info_sb_hin / fn_hyp_info_sb_hout at fixed offsets"
            ASSERT fn_hyp_info_sb_hin_end - fn_hyp_info_sb_hin <= #FFFE - 65488, "fn_hyp_info_sb_hin must fit below #FFFE"
fn_hyp_info_hi_swe:
    ENDIF
    IFDEF NTC_MSXDOS
; zxn: the SD card's code (sd_*: in FileShut's block, main RAM - this page code is full) reaches
; this block's names through these (a name with no colon is sjasmplus's, not the block's own)
@g_fl_peek: EQU asm_1_3817_n_fl_peek
@g_fl_poke: EQU asm_1_3817_n_fl_poke
@g_fl_toslot: EQU asm_1_3817_n_fl_toslot
@g_fl_fromslot: EQU asm_1_3817_n_fl_fromslot
@g_fl_ok: EQU asm_1_3817_n_fl_ok
@g_fp_done: EQU asm_1_3817_n_fp_done
@g_fp_sp: EQU asm_1_3817_n_fp_sp
@g_fl_done: EQU asm_1_3817_n_fl_done
@g_fl_srch: EQU asm_1_3817_n_fl_srch
@g_fl_uc_back: EQU asm_1_3817_n_fl_uc_back
@g_fl_uc_get: EQU asm_1_3817_n_fl_uc_get
@g_fl_inopen_a: EQU asm_1_3817_n_fl_inopen_a
@g_fl_rdrec_a: EQU asm_1_3817_n_fl_rdrec_a
@g_fl_rdrec: EQU asm_1_3817_n_fl_rdrec
@g_fl_bufa: dw var_hyp_filecall_buf                ; (where {buf} is: a dw, not an EQU - an EQU to a variable lags a pass)
@g_fl_arec: EQU asm_1_3817_n_fl_arec
@g_fl_aoff: EQU asm_1_3817_n_fl_aoff
@g_fl_aleft: EQU asm_1_3817_n_fl_aleft
@g_fl_inclose_a: EQU asm_1_3817_n_fl_inclose_a
@g_fl_arc_dir: EQU asm_1_3817_n_fl_arc_dir
@g_fl_mapa: EQU asm_1_3817_n_fl_mapa
@g_fl_name: EQU asm_1_3817_n_fl_name
@g_fl_n: EQU asm_1_3817_n_fl_n
@g_fl_cn: EQU asm_1_3817_n_fl_cn
@g_fl_cnt: EQU asm_1_3817_n_fl_cnt
@g_fl_at: EQU asm_1_3817_n_fl_at
@g_fl_res: EQU asm_1_3817_n_fl_res
@g_fl_slot: EQU asm_1_3817_n_fl_slot
@g_fl_outfcb: EQU asm_1_3817_n_fl_outfcb
@g_fl_outrec: EQU asm_1_3817_n_fl_outrec
@g_fl_yes: EQU asm_1_3817_n_fl_yes
@g_fl_sdf: EQU asm_1_3817_n_fl_sdf
@g_fl_exv: EQU asm_1_3817_n_fl_exv
@g_fl_cjf: EQU asm_1_3817_n_fl_cjf
@g_fl_name_s: EQU asm_1_3817_n_fl_name_s
@g_fl_new_s: EQU asm_1_3817_n_fl_new_s
@g_fl_inname: EQU asm_1_3817_n_fl_inname
@g_FL_UB: EQU asm_1_3817_n_FL_UB
@g_FL_MAP: EQU asm_1_3817_n_FL_MAP
@g_FL_EXK: EQU asm_1_3817_n_FL_EXK
@g_FL_CMAX: EQU asm_1_3817_n_FL_CMAX
    ENDIF
; ---- the page code: in the hypervisor's page (window data), called with it in the window
asm_1_3817_n_fp_start:
            ASSERT asm_1_3817_n_fp_start >= #5300, "FileCall's page code: after the disc buffers and the font"
asm_1_3817_n_fp_go:
            ld (asm_1_3817_n_fp_sp), sp
            ld a, (var_hyp_filecall_f)
            cp 15
            jp z, asm_1_3817_n_fl_open
            cp 16
            jp z, asm_1_3817_n_fl_close
            cp 19
            jp z, asm_1_3817_n_fl_del
            cp 23
            jp z, asm_1_3817_n_fl_ren
            cp 20
            jp z, asm_1_3817_n_fl_rdseq
            cp 33
            jp z, asm_1_3817_n_fl_rdran
            cp 21
            jp z, asm_1_3817_n_fl_write
            cp 34
            jp z, asm_1_3817_n_fl_write
            cp 22
            jp z, asm_1_3817_n_fl_make
            cp 17
            jp z, asm_1_3817_n_fl_srch1
            cp 18
            jp z, asm_1_3817_n_fl_srch
            cp 35
            jp z, asm_1_3817_n_fl_size
            cp 36
            jp z, asm_1_3817_n_fl_setran
            cp 100
            jp z, asm_1_3817_n_fl_hopen
            cp 101
            jp z, asm_1_3817_n_fl_hread
            cp 102
            jp z, asm_1_3817_n_fl_hclose
            cp 103
            jp z, asm_1_3817_n_fl_hload
            cp 30
            jp z, asm_1_3817_n_fl_unicall
            jp asm_1_3817_n_fp_done
; ---- the hypervisor's own reading (RUN, DIR, CD): 100 open the file named at fcb (dma
; characters, main RAM); 101 read dma bytes (128 at most) to buf: how many; 102 close; 103 the
; rest of it into the slot (setting) from address dma, fcb bytes at most: how many. Not while
; a slot reads a file (255)
asm_1_3817_n_fl_hopen:
            ld a, (var_hyp_fin)
            or a
            jp nz, asm_1_3817_n_fp_done
            ld de, asm_1_3817_n_fl_name_s + 1
            ld hl, (var_hyp_filecall_fcb)          ; a name with no drive: the hypervisor's drive's path first
            ld bc, (var_hyp_filecall_dma)          ; when it has one (UniDOS: CD IDE: ...)
            ld a, ':'
            cpir
            jr z, asm_1_3817_n_fl_ho_nm
            ld a, (var_hyp_hdr)
            call asm_1_3817_n_fl_pfxm
asm_1_3817_n_fl_ho_nm:
            ld hl, (var_hyp_filecall_fcb)
            ld bc, (var_hyp_filecall_dma)
            ldir
            call asm_1_3817_n_fl_nlen
            call asm_1_3817_n_fl_inopen
            jr c, asm_1_3817_n_fl_ho_ok
            ld hl, asm_1_3817_n_fl_name_s        ; NAME.CYB not there: with UniDOS NAME.COM instead (RUN - a
            ld e, (hl)              ; .COM with no entry: UniDOS reads a file with no header to
            ld d, 0                 ; its real end)
            add hl, de
            ld a, (hl)
            cp 'B'
            jp nz, asm_1_3817_n_fp_done
            ld (hl), 'M'
            dec hl
            ld a, (hl)
            cp 'Y'
            jp nz, asm_1_3817_n_fp_done
            ld (hl), 'O'
    IFNDEF NTC_MSXDOS
            call asm_1_3817_n_fl_uni
            jp nc, asm_1_3817_n_fp_done
    ENDIF
            call asm_1_3817_n_fl_inopen
            jp nc, asm_1_3817_n_fp_done
            ld hl, (var_hyp_filecall_fcb)          ; (the caller's name too: NAME.COM)
            ld bc, (var_hyp_filecall_dma)
            add hl, bc
            dec hl
            ld (hl), 'M'
            dec hl
            ld (hl), 'O'
asm_1_3817_n_fl_ho_ok:
            ld a, 99                ; (99: the hypervisor's)
            ld (var_hyp_fin), a
            jp asm_1_3817_n_fl_ok
asm_1_3817_n_fl_hread:
            ld a, (var_hyp_filecall_dma)
            ld (asm_1_3817_n_fl_n), a
            call asm_1_3817_n_fl_rdrec
            ld (asm_1_3817_n_fl_res), a
            jp asm_1_3817_n_fp_done
asm_1_3817_n_fl_hclose:
            ld a, (var_hyp_fin)
            cp 99
            jp nz, asm_1_3817_n_fp_done
            call asm_1_3817_n_fl_inclose
            jp asm_1_3817_n_fl_ok
asm_1_3817_n_fl_hload:
            ld hl, 0
            ld (asm_1_3817_n_fl_cnt), hl
            ld hl, (var_hyp_filecall_dma)
            ld (asm_1_3817_n_fl_at), hl
asm_1_3817_n_fl_hl_lp:
            ld hl, (var_hyp_filecall_fcb)          ; what is left to load (fcb bytes at most)
            ld de, (asm_1_3817_n_fl_cnt)
            or a
            sbc hl, de
            jr z, asm_1_3817_n_fl_hl_end
            ld a, h
            or a
            ld a, 128
            jr nz, asm_1_3817_n_fl_hl_n
            ld a, l
            cp 128
            jr c, asm_1_3817_n_fl_hl_n
            ld a, 128
asm_1_3817_n_fl_hl_n:
            ld (asm_1_3817_n_fl_n), a
            ld (asm_1_3817_n_fl_want), a
            call asm_1_3817_n_fl_rdrec           ; a record's worth into buf
            jr z, asm_1_3817_n_fl_hl_end
            ld b, a
            ld (asm_1_3817_n_fl_want + 1), a
            ld hl, (asm_1_3817_n_fl_cnt)
            ld e, a
            ld d, 0
            add hl, de
            ld (asm_1_3817_n_fl_cnt), hl
            ld hl, (asm_1_3817_n_fl_at)
            ld c, b
            ld b, 0
            call asm_1_3817_n_fl_fits
            jr c, asm_1_3817_n_fl_hl_slow
            push bc
            ld de, (var_hyp_filecall_buf)          ; in one page: one ldir
            call asm_1_3817_n_fl_toslot
            pop bc
            ld hl, (asm_1_3817_n_fl_at)
            add hl, bc
            jr asm_1_3817_n_fl_hl_put
asm_1_3817_n_fl_hl_slow:
            ld b, c
            ld de, (var_hyp_filecall_buf)
asm_1_3817_n_fl_hl_cp:
            ld a, (de)              ; into the slot
            call asm_1_3817_n_fl_poke
            inc hl
            inc de
            djnz asm_1_3817_n_fl_hl_cp
asm_1_3817_n_fl_hl_put:
            ld (asm_1_3817_n_fl_at), hl
            ld a, (asm_1_3817_n_fl_want)
            ld b, a
            ld a, (asm_1_3817_n_fl_want + 1)
            cp b
            jr z, asm_1_3817_n_fl_hl_lp          ; a whole one: on
asm_1_3817_n_fl_hl_end:
            ld hl, (asm_1_3817_n_fl_cnt)
            ld (asm_1_3817_n_fl_res16), hl
            ld a, 1
            ld (asm_1_3817_n_fl_r16), a
            jp asm_1_3817_n_fp_done
; ---- 15: open (to read)
asm_1_3817_n_fl_open:
            ld a, (var_hyp_fin)
            or a
            jr z, asm_1_3817_n_fl_op_new
            ld b, a
            ld a, (asm_1_3817_n_fl_slot)
            cp b
            jp nz, asm_1_3817_n_fp_done          ; another slot's being read
            call asm_1_3817_n_fl_inclose         ; this slot's: CP/M needs no close after reading - this open
asm_1_3817_n_fl_op_new:                          ; replaces it (Exists opens and leaves it)
            call asm_1_3817_n_fl_name
            call asm_1_3817_n_fl_inopen
            jp nc, asm_1_3817_n_fp_done
            ld hl, asm_1_3817_n_fl_name_s        ; kept, to open it again (33 going back)
            ld de, asm_1_3817_n_fl_inname
            ld bc, asm_1_3817_n_FL_NL
            ldir
            ld a, (asm_1_3817_n_fl_slot)
            ld (var_hyp_fin), a
            ld hl, (var_hyp_filecall_fcb)
            ld (asm_1_3817_n_fl_infcb), hl
            ld a, 1
            ld (asm_1_3817_n_fl_infcb + 2), a
            ld hl, 0
            ld (asm_1_3817_n_fl_inrec), hl
            jp asm_1_3817_n_fl_ok
; ---- 22: make (a new file, to write)
asm_1_3817_n_fl_make:
    IFDEF NTC_MSXDOS
            jp sd_h_make            ; zxn: the SD card's (the boot archive is read only: 255)
    ENDIF
            ld a, (var_hyp_fout)
            or a
            jp nz, asm_1_3817_n_fp_done
            call asm_1_3817_n_fl_name
            call asm_1_3817_n_fl_plain
            ld hl, asm_1_3817_n_fl_name_s + 1
            ld a, (asm_1_3817_n_fl_name_s)
            ld b, a
            ld de, #4800
            call #BC8C              ; CAS OUT OPEN
            di
            jp nc, asm_1_3817_n_fp_done
            ld a, (asm_1_3817_n_fl_slot)
            ld (var_hyp_fout), a
            ld hl, (var_hyp_filecall_fcb)
            ld (asm_1_3817_n_fl_outfcb), hl
            ld a, 1
            ld (asm_1_3817_n_fl_outfcb + 2), a
            ld hl, 0
            ld (asm_1_3817_n_fl_outrec), hl
            jp asm_1_3817_n_fl_ok
; ---- 16: close
asm_1_3817_n_fl_close:
            call asm_1_3817_n_fl_isin
            jr nz, asm_1_3817_n_fl_cl_out
            call asm_1_3817_n_fl_inclose
            jp asm_1_3817_n_fl_ok
asm_1_3817_n_fl_cl_out:
            call asm_1_3817_n_fl_isout
            jp nz, asm_1_3817_n_fp_done
            xor a
            ld (var_hyp_fout), a
    IFDEF NTC_MSXDOS
            jp sd_h_clout
    ELSE
            call asm_1_3817_n_fl_plain
            call #BC8F              ; CAS OUT CLOSE
            di
            jp nc, asm_1_3817_n_fp_done
    ENDIF
            jp asm_1_3817_n_fl_ok
; ---- 19: delete (|ERA, "name")
asm_1_3817_n_fl_del:
            call asm_1_3817_n_fl_name
    IFDEF NTC_MSXDOS
            jp sd_h_del             ; zxn: the SD card's (the boot archive is read only: 255)
    ENDIF
            call asm_1_3817_n_fl_plain
            ld hl, asm_1_3817_n_fl_name_s + 1
            ld (asm_1_3817_n_fl_desc + 1), hl
            ld a, (asm_1_3817_n_fl_name_s)
            ld (asm_1_3817_n_fl_desc), a
            ld hl, asm_1_3817_n_fl_yes           ; (UniDOS asks before it deletes a folder - all it holds too -,
            ld a, (hl)              ; a read-only or a hidden file: KM WAIT CHAR, its text unseen,
            ld (hl), 0              ; the VDU off. KM CHAR RETURN: the answer waiting for it - N,
            or a                    ; so a CP/M program's delete never takes a folder; Y only after
            ld a, 'N'               ; BDOS 30 op 8, RMDIR's, for its empty folder)
            jr z, asm_1_3817_n_fl_del_n
            ld a, 'Y'
asm_1_3817_n_fl_del_n:
            call #BB0C
            ld hl, asm_1_3817_n_fl_era           ; KL FIND COMMAND; KM READ CHAR after
            call #BCD4              ; takes the answer back when nothing asked
            di
            jp nc, asm_1_3817_n_fp_done
            ld ix, asm_1_3817_n_fl_par
            ld a, 1                 ; one parameter: the string
            call #001B              ; KL FAR PCALL
            call #BB09              ; KM READ CHAR (interrupts: off again in fl_done)
            jp asm_1_3817_n_fl_ok
; ---- 23: rename (the disc ROM's |REN, "new", "old"): the old name at FCB 0-11, the new
; at 16-27 (its drive 0: the old one's)
asm_1_3817_n_fl_ren:
            ld hl, (var_hyp_filecall_fcb)
            call asm_1_3817_n_fl_peek
            ld (asm_1_3817_n_fl_dfl), a
            ld de, 16
            add hl, de
            call asm_1_3817_n_fl_namehl          ; the new name
            xor a
            ld (asm_1_3817_n_fl_dfl), a
            ld hl, asm_1_3817_n_fl_name_s
            ld de, asm_1_3817_n_fl_new_s
            ld bc, asm_1_3817_n_FL_NL
            ldir
            call asm_1_3817_n_fl_name            ; the old one
    IFDEF NTC_MSXDOS
            jp sd_h_ren             ; zxn: the SD card's (the boot archive is read only: 255)
    ENDIF
            call asm_1_3817_n_fl_plain
            ld hl, asm_1_3817_n_fl_name_s + 1
            ld (asm_1_3817_n_fl_desc + 1), hl
            ld a, (asm_1_3817_n_fl_name_s)
            ld (asm_1_3817_n_fl_desc), a
            ld hl, asm_1_3817_n_fl_new_s + 1
            ld (asm_1_3817_n_fl_desc2 + 1), hl
            ld a, (asm_1_3817_n_fl_new_s)
            ld (asm_1_3817_n_fl_desc2), a
            ld hl, asm_1_3817_n_fl_rencmd
            call #BCD4              ; KL FIND COMMAND
            di
            jp nc, asm_1_3817_n_fp_done
            ld ix, asm_1_3817_n_fl_par2          ; IX+0: the last parameter (the old name), IX+2: the new
            ld a, 2
            call #001B              ; KL FAR PCALL
            jp asm_1_3817_n_fl_ok              ; (interrupts: off again in fl_done)
; ---- 33: read record r0-r1: on to it (from the start again if it is behind)
asm_1_3817_n_fl_rdran:
            call asm_1_3817_n_fl_isin
            jp nz, asm_1_3817_n_fl_rdout
            ld hl, (var_hyp_filecall_fcb)
            ld de, 33
            add hl, de
            call asm_1_3817_n_fl_peek
            ld e, a
            inc hl
            call asm_1_3817_n_fl_peek
            ld d, a
            ld (asm_1_3817_n_fl_want), de
            ld hl, (asm_1_3817_n_fl_inrec)
            or a
            sbc hl, de
            jr c, asm_1_3817_n_fl_rr_on
            jr z, asm_1_3817_n_fl_rr_on
            call asm_1_3817_n_fl_inclose         ; behind: open it again
            ld hl, asm_1_3817_n_fl_inname
            ld de, asm_1_3817_n_fl_name_s
            ld bc, asm_1_3817_n_FL_NL
            ldir
            call asm_1_3817_n_fl_inopen
            jp nc, asm_1_3817_n_fp_done
            ld a, (asm_1_3817_n_fl_slot)
            ld (var_hyp_fin), a
            ld hl, 0
            ld (asm_1_3817_n_fl_inrec), hl
asm_1_3817_n_fl_rr_on:
            ld hl, (asm_1_3817_n_fl_inrec)
            ld de, (asm_1_3817_n_fl_want)
            or a
            sbc hl, de
            jr nc, asm_1_3817_n_fl_rdseq
            call asm_1_3817_n_fl_rdrec
            jp z, asm_1_3817_n_fl_eof
            ld hl, (asm_1_3817_n_fl_inrec)
            inc hl
            ld (asm_1_3817_n_fl_inrec), hl
            jr asm_1_3817_n_fl_rr_on
; ---- 20: read the next record
asm_1_3817_n_fl_rdseq:
            call asm_1_3817_n_fl_isin
            jr nz, asm_1_3817_n_fl_rdout
            call asm_1_3817_n_fl_rdrec
            jr z, asm_1_3817_n_fl_eof
            ex de, hl
            ld hl, (asm_1_3817_n_fl_inrec)
            inc hl
            ld (asm_1_3817_n_fl_inrec), hl
            ex de, hl
            ld b, a                 ; the record padded with #1A
            ld a, 128
            sub b
            jr z, asm_1_3817_n_fl_rd_put
            ld b, a
            ld a, #1A
asm_1_3817_n_fl_rd_pad:
            ld (hl), a
            inc hl
            djnz asm_1_3817_n_fl_rd_pad
asm_1_3817_n_fl_rd_put:
            ld hl, (var_hyp_filecall_dma)          ; into the slot's DMA: in one page, one ldir
            ld bc, 128
            call asm_1_3817_n_fl_fits
            jr c, asm_1_3817_n_fl_rd_slow
            ld de, (var_hyp_filecall_buf)
            call asm_1_3817_n_fl_toslot
            jp asm_1_3817_n_fl_ok
asm_1_3817_n_fl_rd_slow:                         ; (across two pages: a byte at a time)
            ld hl, (var_hyp_filecall_buf)
            ld de, (var_hyp_filecall_dma)
            ld b, 128
asm_1_3817_n_fl_rd_cp:
            ld a, (hl)
            ex de, hl
            call asm_1_3817_n_fl_poke
            ex de, hl
            inc hl
            inc de
            djnz asm_1_3817_n_fl_rd_cp
            jp asm_1_3817_n_fl_ok
asm_1_3817_n_fl_rdout:
            call asm_1_3817_n_fl_isout           ; a file being written: nothing to read back
            jp nz, asm_1_3817_n_fp_done
asm_1_3817_n_fl_eof:
            ld a, 1
            ld (asm_1_3817_n_fl_res), a
            jp asm_1_3817_n_fp_done
; ---- 21 / 34: write the next record
asm_1_3817_n_fl_write:
            call asm_1_3817_n_fl_isout
            jp nz, asm_1_3817_n_fp_done
            ld hl, (var_hyp_filecall_dma)          ; the slot's DMA into buf
            ld bc, 128
            call asm_1_3817_n_fl_fits
            jr c, asm_1_3817_n_fl_wr_slow
            ld de, (var_hyp_filecall_buf)
            call asm_1_3817_n_fl_fromslot
            jr asm_1_3817_n_fl_wr_got
asm_1_3817_n_fl_wr_slow:
            ld de, (var_hyp_filecall_buf)
            ld b, 128
asm_1_3817_n_fl_wr_cp:
            call asm_1_3817_n_fl_peek
            ld (de), a
            inc hl
            inc de
            djnz asm_1_3817_n_fl_wr_cp
asm_1_3817_n_fl_wr_got:
    IFDEF NTC_MSXDOS
            jp sd_h_write           ; zxn: buf to the SD card's file
    ENDIF
            call asm_1_3817_n_fl_plain
            ld hl, (var_hyp_filecall_buf)
            ld b, 128
asm_1_3817_n_fl_wr_lp:
            ld a, (hl)
            push bc
            push hl
            call #BC95              ; CAS OUT CHAR
            di
            pop hl
            pop bc
            jp nc, asm_1_3817_n_fp_done
            inc hl
            djnz asm_1_3817_n_fl_wr_lp
            ld hl, (asm_1_3817_n_fl_outrec)
            inc hl
            ld (asm_1_3817_n_fl_outrec), hl
            jp asm_1_3817_n_fl_ok
; ---- 35: the file's size in records (r0-r2): counted, reading it through. The file this slot
; is reading is opened again after, at its record; another slot's being read: 255
asm_1_3817_n_fl_size:
            ld a, (var_hyp_fin)
            or a
            jr z, asm_1_3817_n_fl_sz_free
            ld b, a
            ld a, (asm_1_3817_n_fl_slot)
            cp b
            jp nz, asm_1_3817_n_fp_done
            call asm_1_3817_n_fl_inclose
            ld a, 1
asm_1_3817_n_fl_sz_free:
            ld (asm_1_3817_n_fl_had), a
            call asm_1_3817_n_fl_name
            call asm_1_3817_n_fl_inopen
            jr nc, asm_1_3817_n_fl_sz_back
            ld hl, 0
            ld (asm_1_3817_n_fl_cnt), hl
asm_1_3817_n_fl_sz_lp:
            call asm_1_3817_n_fl_rdrec
            jr z, asm_1_3817_n_fl_sz_end
            ld hl, (asm_1_3817_n_fl_cnt)
            inc hl
            ld (asm_1_3817_n_fl_cnt), hl
            cp 128
            jr z, asm_1_3817_n_fl_sz_lp
asm_1_3817_n_fl_sz_end:
            call asm_1_3817_n_fl_inclose
            ld hl, (asm_1_3817_n_fl_cnt)
            call asm_1_3817_n_fl_ranput
            xor a
            ld (asm_1_3817_n_fl_res), a
asm_1_3817_n_fl_sz_back:
            ld a, (asm_1_3817_n_fl_had)
            or a
            jp z, asm_1_3817_n_fp_done
            ld hl, asm_1_3817_n_fl_inname        ; the slot's read file again, on to its record
            ld de, asm_1_3817_n_fl_name_s
            ld bc, asm_1_3817_n_FL_NL
            ldir
            call asm_1_3817_n_fl_inopen
            jp nc, asm_1_3817_n_fp_done
            ld a, (asm_1_3817_n_fl_slot)
            ld (var_hyp_fin), a
            ld hl, (asm_1_3817_n_fl_inrec)
asm_1_3817_n_fl_sz_skip:
            ld a, h
            or l
            jp z, asm_1_3817_n_fp_done
            push hl
            call asm_1_3817_n_fl_rdrec
            pop hl
            dec hl
            jr asm_1_3817_n_fl_sz_skip
    IFDEF NTC_MSXDOS
; zxn: #5B00-#5CFF kept as scratch - the 48K ROM and the DOS keep their system variables there
; (BANKM #5B5C, BANK678 #5B67; the interrupt handler's KSTATE, LAST_K, FLAGS, FRAMES at #5C00-
; #5C7B), and this page is in the window during an esxDOS call (sd_x)
            ASSERT $ <= #5B00, "the page code up to asm_1_3817_n_fl_setran must end below #5B00 (asm_1_3817_n_fl_sysv)"
            ds #5B00 - $
asm_1_3817_n_fl_sysv:    ds #200
    ENDIF
; ---- 36: set the random record (r0-r2) from where the file is: the next record read or
; written; a file not open here: from the FCB's extent and record (ex * 128 + cr)
asm_1_3817_n_fl_setran:
            call asm_1_3817_n_fl_isin
            ld hl, (asm_1_3817_n_fl_inrec)
            jr z, asm_1_3817_n_fl_sr_put
            call asm_1_3817_n_fl_isout
            ld hl, (asm_1_3817_n_fl_outrec)
            jr z, asm_1_3817_n_fl_sr_put
            ld hl, (var_hyp_filecall_fcb)
            ld de, 32
            add hl, de
            call asm_1_3817_n_fl_peek            ; cr
            ld e, a
            ld bc, -20
            add hl, bc
            call asm_1_3817_n_fl_peek            ; ex
            ld h, a
            srl h
            ld a, e
            jr nc, asm_1_3817_n_fl_sr_lo
            or #80
asm_1_3817_n_fl_sr_lo:
            ld l, a
asm_1_3817_n_fl_sr_put:
            call asm_1_3817_n_fl_ranput
            jp asm_1_3817_n_fl_ok
; ---- 17 / 18: search the folder (UniDOS: the FCB's drive's, else the slot's) for BDOS 17's
; name ("?" any character; kept at SRCH in the bank, SRCH + 12 the entries passed - 18 goes on
; from there): the next one, as a CP/M directory entry at the DMA (its record count from its
; length, 128 at most). 17 examines the folder (Ctrl J) into the hypervisor's page (#6000-#7BFF:
; 112 entries at most), then 17 and 18 look there. No UniDOS (or an AMSDOS floppy): none (255)
asm_1_3817_n_fl_srch1:
            ld hl, (var_hyp_filecall_fcb)
            ld de, 63216
            ld b, 12
asm_1_3817_n_fl_s1_lp:
            call asm_1_3817_n_fl_peek
            ex de, hl
            call asm_1_3817_n_fl_poke
            ex de, hl
            inc hl
            inc de
            djnz asm_1_3817_n_fl_s1_lp
            ex de, hl
            xor a
            call asm_1_3817_n_fl_poke            ; none passed
            xor a
            ld (asm_1_3817_n_fl_cn), a
            ld hl, #6000
            ld (asm_1_3817_n_fl_at), hl
            ld de, asm_1_3817_n_fl_name_s + 1    ; "B:" (or B's path)
            ld hl, 63216
            call asm_1_3817_n_fl_peek
            or a
            jr z, asm_1_3817_n_fl_s_own
            add a, 64
            jr asm_1_3817_n_fl_s_drv
asm_1_3817_n_fl_s_own:
            ld a, (var_hyp_filecall_drive)
            or a
            jr z, asm_1_3817_n_fl_s_nod
asm_1_3817_n_fl_s_drv:
            call asm_1_3817_n_fl_pfx
asm_1_3817_n_fl_s_nod:
    IFDEF NTC_MSXDOS
            jp sd_h_srch1           ; zxn: the folder (the SD card's, else the boot archive's) into the cache
    ENDIF
; UniDOS: the directory itself (Ctrl J examine), its files into the cache - no file opened (so
; not held up by another slot's reading)
    IFNDEF NTC_MSXDOS
            push de
            call asm_1_3817_n_fl_exdir
            pop de
            jp nz, asm_1_3817_n_fp_done          ; (none to list: no UniDOS, an AMSDOS floppy - 255)
asm_1_3817_n_fl_sx_lp:
            ld hl, (asm_1_3817_n_fl_at)
            inc hl                  ; (the name straight into the entry)
            ld ix, asm_1_3817_n_FL_DATE
            ld c, 13                ; examine next
            call asm_1_3817_n_fl_cjc
            jr nc, asm_1_3817_n_fl_sx_end
            jr nz, asm_1_3817_n_fl_sx_end
            bit 4, a
            jr nz, asm_1_3817_n_fl_sx_lp         ; (a folder: not for CP/M)
            ld hl, (asm_1_3817_n_fl_at)
            ld (hl), 1              ; in use
            ld a, b
            or c
            jr z, asm_1_3817_n_fl_sx_sz
            ld de, #FFFF            ; (64K or more)
asm_1_3817_n_fl_sx_sz:
            ld bc, 12
            add hl, bc
            ld (hl), b              ; kind, flags 0
            inc hl
            ld (hl), b
            inc hl
            ld (hl), e              ; its length
            inc hl
            ld (hl), d
            ld hl, (asm_1_3817_n_fl_at)
            ld bc, 64
            add hl, bc
            ld (asm_1_3817_n_fl_at), hl
            ld hl, asm_1_3817_n_fl_cn
            inc (hl)
            ld a, (hl)
            cp asm_1_3817_n_FL_CMAX
            jr c, asm_1_3817_n_fl_sx_lp
asm_1_3817_n_fl_sx_end:
            jp asm_1_3817_n_fl_srch
    ENDIF
    IFDEF NTC_MSXDOS
; fl_arc_dir - the archive's entries into the search's cache (#6000: 64 bytes each - 1, the name
; 8 + 3, 0, 0, the length as a word; FL_CMAX at most): fl_cn how many, for fl_srch (17 / 18)
asm_1_3817_n_fl_arc_dir:
            xor a
            ld (asm_1_3817_n_fl_cn), a
            ld hl, #6000
            ld (asm_1_3817_n_fl_at), hl
            ld hl, 0
            call asm_1_3817_n_fl_arc_pg          ; the directory: HL = #C000
            ld de, 4
            add hl, de
            ld e, (hl)
            inc hl
            ld d, (hl)              ; DE = the entries
            ld bc, 0                ; BC = this entry
asm_1_3817_n_fl_ad_lp:
            ld a, c
            cp e
            ld a, b
            sbc a, d
            jr nc, asm_1_3817_n_fl_ad_end
            ld a, (asm_1_3817_n_fl_cn)
            cp asm_1_3817_n_FL_CMAX
            jr nc, asm_1_3817_n_fl_ad_end
            push bc
            push de
            inc bc                  ; the entry's record: (n + 1) / 8, in it ((n + 1) and 7) * 16
            ld h, b
            ld l, c
            srl h
            rr l
            srl h
            rr l
            srl h
            rr l
            call asm_1_3817_n_fl_arc_pg
            ld a, c
            and 7
            add a, a
            add a, a
            add a, a
            add a, a
            add a, l
            ld l, a
            ld de, (asm_1_3817_n_fl_at)
            ld a, 1
            ld (de), a              ; in use
            inc de
            ld bc, 11
            ldir                    ; the name
            ex de, hl
            ld (hl), 0              ; kind, flags
            inc hl
            ld (hl), 0
            inc hl
            ex de, hl
            ld a, (hl)              ; the length: a word (65535 from 64K)
            inc hl
            ld c, (hl)
            inc hl
            ld b, (hl)
            ld l, a
            ld h, c
            ld a, b
            or a
            jr z, asm_1_3817_n_fl_ad_ln
            ld hl, 65535
asm_1_3817_n_fl_ad_ln:
            ex de, hl
            ld (hl), e
            inc hl
            ld (hl), d
            ld hl, (asm_1_3817_n_fl_at)
            ld bc, 64
            add hl, bc
            ld (asm_1_3817_n_fl_at), hl
            ld hl, asm_1_3817_n_fl_cn
            inc (hl)
            pop de
            pop bc
            inc bc
            jr asm_1_3817_n_fl_ad_lp
asm_1_3817_n_fl_ad_end:
            jp asm_1_3817_n_fl_arc_off
    ENDIF
asm_1_3817_n_fl_srch:
            ld hl, 63216 + 12
            call asm_1_3817_n_fl_peek
            ld (asm_1_3817_n_fl_skip), a
            xor a
            ld (asm_1_3817_n_fl_k), a
asm_1_3817_n_fl_s_lp:
            ld a, (asm_1_3817_n_fl_cn)           ; the next entry, from the cache
            ld b, a
            ld a, (asm_1_3817_n_fl_k)
            cp b
            jp nc, asm_1_3817_n_fp_done          ; (none: 255)
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, #6000
            add hl, de
            ld de, (var_hyp_filecall_buf)
            ld bc, 64
            ldir
            ld hl, asm_1_3817_n_fl_k
            inc (hl)
            ld a, (asm_1_3817_n_fl_skip)
            cp (hl)
            jr nc, asm_1_3817_n_fl_s_lp          ; passed already
            ld hl, (var_hyp_filecall_buf)
            ld a, (hl)
            dec a
            jr nz, asm_1_3817_n_fl_s_lp          ; not in use (1)
            inc hl
            ld de, 63216 + 1
            ld b, 11
asm_1_3817_n_fl_s_cmp:
            ex de, hl
            call asm_1_3817_n_fl_peek
            ex de, hl
            and #7F
            cp '?'
            jr z, asm_1_3817_n_fl_s_any
            ld c, a
            ld a, (hl)
            and #7F
            cp c
            jr nz, asm_1_3817_n_fl_s_lp
asm_1_3817_n_fl_s_any:
            inc hl
            inc de
            djnz asm_1_3817_n_fl_s_cmp
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
            jr c, asm_1_3817_n_fl_s_big
            ld a, h
            cp #40
            jr nc, asm_1_3817_n_fl_s_big
            sla l
            rla
            jr asm_1_3817_n_fl_s_rc
asm_1_3817_n_fl_s_big:
            ld a, 128
asm_1_3817_n_fl_s_rc:
            ex de, hl
            ld (hl), a
            ld b, 3
asm_1_3817_n_fl_s_z1:
            dec hl
            ld (hl), 0
            djnz asm_1_3817_n_fl_s_z1
            ld de, 4
            add hl, de
            ld b, 16
asm_1_3817_n_fl_s_z2:
            ld (hl), 0
            inc hl
            djnz asm_1_3817_n_fl_s_z2
            ld hl, (var_hyp_filecall_dma)
            ld de, (var_hyp_filecall_buf)
            ld b, 32
asm_1_3817_n_fl_s_put:
            ld a, (de)
            call asm_1_3817_n_fl_poke
            inc hl
            inc de
            djnz asm_1_3817_n_fl_s_put
            ld hl, 63216 + 12
            ld a, (asm_1_3817_n_fl_k)
            call asm_1_3817_n_fl_poke
            jp asm_1_3817_n_fl_ok
asm_1_3817_n_fl_skip:    db 0
asm_1_3817_n_fl_k:       db 0
asm_1_3817_n_fl_cn:      db 0                    ; the folder's entries in the cache (#6000)
asm_1_3817_n_fl_ranput:                          ; the FCB's r0-r2 = HL
            ex de, hl
            ld hl, (var_hyp_filecall_fcb)
            ld bc, 33
            add hl, bc
            ld a, e
            call asm_1_3817_n_fl_poke
            inc hl
            ld a, d
            call asm_1_3817_n_fl_poke
            inc hl
            xor a
            jp asm_1_3817_n_fl_poke
; ---- the parts
    IFNDEF NTC_MSXDOS
asm_1_3817_n_fl_inopen:                          ; open fl_name_s to read: carry = done
            call asm_1_3817_n_fl_plain
            ld hl, asm_1_3817_n_fl_name_s + 1
            ld a, (asm_1_3817_n_fl_name_s)
            ld b, a
            ld de, #4000
            call #BC77              ; CAS IN OPEN
            di
            ld (asm_1_3817_n_fl_hdr), hl         ; (its header: BDOS 30 #C7)
            ret
asm_1_3817_n_fl_inclose:
            xor a
            ld (var_hyp_fin), a
            call asm_1_3817_n_fl_plain
            call #BC7A              ; CAS IN CLOSE
            di
            ret
asm_1_3817_n_fl_rdrec:                           ; read up to fl_n bytes (128) into buf: A = how many (Z
            call asm_1_3817_n_fl_plain           ; none), HL past them. A #1A is a byte (the soft end of file)
            ld hl, (var_hyp_filecall_buf)
            ld a, (asm_1_3817_n_fl_n)
            ld b, a
asm_1_3817_n_fl_rr_lp:
            push bc
            push hl
            call #BC80              ; CAS IN CHAR
            di
            pop hl
            pop bc
            jr c, asm_1_3817_n_fl_rr_b
            cp #1A
            jr nz, asm_1_3817_n_fl_rr_end
asm_1_3817_n_fl_rr_b:
            ld (hl), a
            inc hl
            djnz asm_1_3817_n_fl_rr_lp
asm_1_3817_n_fl_rr_end:
            ld a, (asm_1_3817_n_fl_n)
            sub b
            ld c, a
            ld a, 128
            ld (asm_1_3817_n_fl_n), a            ; (128 again for the next)
            ld a, c
            or a
            ret
    ENDIF
asm_1_3817_n_fl_fits:                            ; HL = a slot address, BC = bytes: NC = all in its 16K page.
            push hl                 ; Keeps BC, DE, HL
            ld a, h
            and #3F
            ld h, a
            add hl, bc
            ld a, h
            cp #40
            jr c, asm_1_3817_n_fl_ft_ok
            jr nz, asm_1_3817_n_fl_ft_no
            ld a, l
            or a
            jr nz, asm_1_3817_n_fl_ft_no
asm_1_3817_n_fl_ft_ok:
            pop hl
            or a
            ret
asm_1_3817_n_fl_ft_no:
            pop hl
            scf
            ret
asm_1_3817_n_fl_plain:                           ; the hypervisor's page in the window (the buffers)
            ld bc, (var_hyp_hps)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ret
asm_1_3817_n_fl_name:                            ; fl_name_s = the FCB's file: length, "B:NAME.EXT"
            ld hl, (var_hyp_filecall_fcb)
asm_1_3817_n_fl_namehl:                          ; (HL = an FCB in the slot)
            ld de, asm_1_3817_n_fl_name_s + 1
            call asm_1_3817_n_fl_peek            ; its drive: 0 = the slot's (or fl_dfl's)
            or a
            jr nz, asm_1_3817_n_fl_nm_d
            ld a, (asm_1_3817_n_fl_dfl)
            or a
            jr nz, asm_1_3817_n_fl_nm_d
            ld a, (var_hyp_filecall_drive)
            or a
            jr z, asm_1_3817_n_fl_nm_nod
            sub 64
asm_1_3817_n_fl_nm_d:
            add a, 64
            call asm_1_3817_n_fl_pfx             ; "B:", or B's path (UniDOS: "IDE:GAMES/")
asm_1_3817_n_fl_nm_nod:
            ld b, 11
asm_1_3817_n_fl_nm_lp:
            inc hl
            ld a, b
            cp 3
            jr nz, asm_1_3817_n_fl_nm_c
            ld a, '.'
            ld (de), a
            inc de
asm_1_3817_n_fl_nm_c:
            call asm_1_3817_n_fl_peek
            and #7F
            cp ' ' + 1
            jr c, asm_1_3817_n_fl_nm_sk
            ld (de), a
            inc de
asm_1_3817_n_fl_nm_sk:
            djnz asm_1_3817_n_fl_nm_lp
            ex de, hl
            ld de, asm_1_3817_n_fl_name_s + 1
            or a
            sbc hl, de
            ld a, l
            ld (asm_1_3817_n_fl_name_s), a
            ret
asm_1_3817_n_fl_ok:
            xor a
            ld (asm_1_3817_n_fl_res), a
asm_1_3817_n_fp_done:                            ; back to FileCall in main RAM (fp_done)
            ld sp, (asm_1_3817_n_fp_sp)
            ret
asm_1_3817_n_fl_era:     db "ER", "A" + #80
asm_1_3817_n_fl_rencmd:  db "RE", "N" + #80
asm_1_3817_n_fl_par2:    dw asm_1_3817_n_fl_desc, asm_1_3817_n_fl_desc2
asm_1_3817_n_fl_desc2:   db 0
            dw 0
asm_1_3817_n_fl_dfl:     db 0                    ; fl_name: the drive for an FCB whose own is 0 (rename)
asm_1_3817_n_fl_par:     dw asm_1_3817_n_fl_desc
asm_1_3817_n_fl_desc:    db 0
            dw 0
asm_1_3817_n_fl_n:       db 128                  ; bytes fl_rdrec reads
asm_1_3817_n_fl_cnt:     dw 0
asm_1_3817_n_fl_at:      dw 0
asm_1_3817_n_fl_infcb:   dw 0
            db 0                    ; (1: fl_infcb the open's - fl_is)
asm_1_3817_n_fl_inrec:   dw 0
asm_1_3817_n_fl_want:    dw 0
asm_1_3817_n_fl_outfcb:  dw 0
            db 0
asm_1_3817_n_fl_outrec:  dw 0                    ; the next record written (36)
asm_1_3817_n_fl_had:     db 0                    ; 35: this slot's read file closed for it
asm_1_3817_n_fp_sp:      dw 0
; ---- UniDOS: its Ctrl J BIOS command (found once, KL FIND COMMAND) - a drive letter can be a
; path (CD IDE:, CD SD:GAMES ...: any UniDOS device's folder), folders listed (examine). FL_MAP:
; letters A-P, 32 bytes each: the path's length (0 none: the letter itself, "B:"), the path
; ("IDE:GAMES/": a device or logical drive, its folders, the last "/" or ":"). Cleared when
; UniDOS is found, and only set with it: with AMSDOS no letter has a path. Up there with the
; names (48 characters: a path and NAME.EXT), BDOS 132's block, DIR's listing: the FILES.DIR
; cache is #6000-#7BFF (112 entries)
asm_1_3817_n_FL_CMAX:    equ 112                 ; the cache's entries
asm_1_3817_n_FL_NL:      equ 49                  ; a name: its length, then the characters
asm_1_3817_n_fl_name_s:  equ #7C00               ; length, then "B:NAME.EXT" (or "IDE:GAMES/NAME.EXT")
asm_1_3817_n_fl_inname:  equ asm_1_3817_n_fl_name_s + asm_1_3817_n_FL_NL   ; the one being read's (33 going back)
asm_1_3817_n_fl_new_s:   equ asm_1_3817_n_fl_inname + asm_1_3817_n_FL_NL   ; (23: the new name)
asm_1_3817_n_FL_UB:      equ #7D00               ; BDOS 132's block (72 bytes)
asm_1_3817_n_FL_EXK:     equ #7D48               ; the folder DIR lists (its path: length, 31 characters)
asm_1_3817_n_FL_DATE:    equ #7D68               ; a date examine gives (7), then a name (11)
asm_1_3817_n_FL_TN:      equ #7D70
asm_1_3817_n_FL_MAP:     equ #7E00
            ASSERT #6000 + asm_1_3817_n_FL_CMAX * 64 <= asm_1_3817_n_fl_name_s, "the search's cache, below the names"
            ASSERT asm_1_3817_n_fl_new_s + asm_1_3817_n_FL_NL <= asm_1_3817_n_FL_UB, "the names, below BDOS 132's block"
            ASSERT (asm_1_3817_n_FL_MAP & 255) = 0, "asm_1_3817_n_FL_MAP: a page's start (asm_1_3817_n_fl_mapa)"
asm_1_3817_n_fl_cjf:     db 0                    ; 0: not looked for yet, 1: UniDOS, 2: none
asm_1_3817_n_fl_cj:      dw 0                    ; Ctrl J's far address (address, ROM)
            db 0
asm_1_3817_n_fl_cjn:     db #8A                  ; (its name)
asm_1_3817_n_fl_exv:     db 0                    ; FL_EXK's listing is the one UniDOS examines now ...
asm_1_3817_n_fl_exi:     dw 0                    ; ... at this entry next
asm_1_3817_n_fl_ue:      dw 0
; carry: UniDOS here (the first time: looked for, the paths cleared)
asm_1_3817_n_fl_uni:
    IFDEF NTC_MSXDOS
            scf                     ; zxn: the SD card stands in for UniDOS (paths: FL_MAP)
            ret
    ELSE
            ld a, (asm_1_3817_n_fl_cjf)
            cp 1
            jr z, asm_1_3817_n_fl_un_y
            or a
            ret nz                  ; (2: none - NC)
            ld hl, asm_1_3817_n_fl_cjn
            call #BCD4              ; KL FIND COMMAND: C = its ROM, HL = its address
            di
            ld a, 2
            jr nc, asm_1_3817_n_fl_un_s
            ld (asm_1_3817_n_fl_cj), hl
            ld a, c
            ld (asm_1_3817_n_fl_cj + 2), a
            ld hl, asm_1_3817_n_FL_MAP
            ld de, asm_1_3817_n_FL_MAP + 1
            ld bc, 511
            ld (hl), 0
            ldir
            ld a, 1
asm_1_3817_n_fl_un_s:
            ld (asm_1_3817_n_fl_cjf), a
            jr asm_1_3817_n_fl_uni
asm_1_3817_n_fl_un_y:
            scf
            ret
; Ctrl J command C (the other registers its input; its output back)
asm_1_3817_n_fl_cjc:
            rst #18                 ; (RST 3: a far call)
            dw asm_1_3817_n_fl_cj
            di
            ret
    ENDIF
; A = a drive letter: HL = its FL_MAP entry, A = its path's length (Z: none). Carry: not A-P,
; or no UniDOS (no paths). A, HL only
asm_1_3817_n_fl_mapa:
            sub 'A'
            cp 16
            ccf
            ret c
            ld l, a
            ld a, (asm_1_3817_n_fl_cjf)
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
            add a, asm_1_3817_n_FL_MAP / 256
            ld h, a
            ld a, (hl)
            or a
            ret
; A = a drive letter: "B:" at DE, or its path - DE past it (BC, HL kept)
asm_1_3817_n_fl_pfx:
            push af
            call asm_1_3817_n_fl_pfxm
            jr nz, asm_1_3817_n_fl_px_d
            pop af
            ld (de), a
            inc de
            ld a, ':'
            ld (de), a
            inc de
            ret
asm_1_3817_n_fl_px_d:
            pop af
            ret
; ... its path only, if it has one (NZ; Z: none, nothing put)
asm_1_3817_n_fl_pfxm:
            push hl
            call asm_1_3817_n_fl_mapa
            jr c, asm_1_3817_n_fl_pm_no
            jr z, asm_1_3817_n_fl_pm_no
            push bc
            ld c, a
            ld b, 0
            inc hl
            ldir
            pop bc
            or a
            jr asm_1_3817_n_fl_pm_r
asm_1_3817_n_fl_pm_no:
            xor a
asm_1_3817_n_fl_pm_r:
    IFDEF NTC_MSXDOS
            ld (asm_1_3817_n_fl_sdf), a          ; (zxn: a path put = the SD card's file)
    ENDIF
            pop hl
            ret
    IFDEF NTC_MSXDOS
asm_1_3817_n_fl_sdf:     db 0
    ENDIF
asm_1_3817_n_fl_nlen:                            ; fl_name_s's length: its characters end at DE
            ld hl, -(asm_1_3817_n_fl_name_s + 1)
            add hl, de
            ld a, l
            ld (asm_1_3817_n_fl_name_s), a
            ret
; the folder whose path is at fl_name_s + 1 to DE (fl_exdir2: fl_name_s, its length set)
; examined (Ctrl J 12): Z its listing ready (examine next: Ctrl J 13), NZ no UniDOS, a drive
; it can't examine (AMSDOS's floppies), not a folder
    IFNDEF NTC_MSXDOS
asm_1_3817_n_fl_exdir:
            call asm_1_3817_n_fl_nlen
asm_1_3817_n_fl_exdir2:
            call asm_1_3817_n_fl_uni
            jr nc, asm_1_3817_n_fl_ed_no
            xor a
            ld (asm_1_3817_n_fl_exv), a
            ld hl, asm_1_3817_n_fl_name_s
            ld b, (hl)
            inc hl
            ld ix, asm_1_3817_n_FL_DATE
            ld c, 12
            call asm_1_3817_n_fl_cjc
            ret c
asm_1_3817_n_fl_ed_no:
            ld a, 254               ; (254: no UniDOS, or a drive it can't examine)
            or a
            ret
    ENDIF
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
asm_1_3817_n_fl_unicall:
            ld hl, (var_hyp_filecall_fcb)
            ld de, asm_1_3817_n_FL_UB
            ld b, 72
asm_1_3817_n_fl_uc_in:
            call asm_1_3817_n_fl_peek
            ld (de), a
            inc hl
            inc de
            djnz asm_1_3817_n_fl_uc_in
            ld a, (asm_1_3817_n_FL_UB)
            sub #C0
            cp 9
            jp nc, asm_1_3817_n_fp_done          ; (CP/M's 30)
            ld (asm_1_3817_n_FL_UB), a
    IFDEF NTC_MSXDOS
            jp sd_h_uc              ; zxn: the SD card's folders
    ELSE
            call asm_1_3817_n_fl_uni
            jp nc, asm_1_3817_n_fp_done
            ld a, (asm_1_3817_n_FL_UB)
            or a
            jp z, asm_1_3817_n_fl_ok
            dec a
            jp z, asm_1_3817_n_fl_uc_get
            dec a
            jp z, asm_1_3817_n_fl_uc_set
            dec a
            jp z, asm_1_3817_n_fl_uc_dev
            dec a
            jp z, asm_1_3817_n_fl_uc_inf
            dec a
            jp z, asm_1_3817_n_fl_uc_dir
            dec a
            jr z, asm_1_3817_n_fl_uc_md
            cp 2
            jr z, asm_1_3817_n_fl_uc_yes
            ld a, (var_hyp_fin)           ; 7: the header of the file this slot reads (the disc ROM's,
            ld hl, asm_1_3817_n_fl_slot          ; from CAS IN OPEN: 69 bytes) to Byte(2)
            cp (hl)
            jp nz, asm_1_3817_n_fp_done
            ld hl, (asm_1_3817_n_fl_hdr)
            ld de, asm_1_3817_n_FL_UB + 2
            ld bc, 69
            ldir
            xor a
            ld b, 71
            jp asm_1_3817_n_fl_uc_back
    ENDIF
asm_1_3817_n_fl_hdr:     dw 0
    IFNDEF NTC_MSXDOS
asm_1_3817_n_fl_uc_yes:                          ; 8: the next delete (19) may take a folder (RMDIR's)
            ld a, 1
            ld (asm_1_3817_n_fl_yes), a
            jp asm_1_3817_n_fl_ok
    ENDIF
asm_1_3817_n_fl_yes:     db 0
    IFNDEF NTC_MSXDOS
asm_1_3817_n_fl_uc_md:                           ; 6: a folder made (CAS OUT OPEN, the path ending "/")
            ld a, (var_hyp_fout)
            or a
            jp nz, asm_1_3817_n_fp_done
            ld hl, asm_1_3817_n_FL_UB + 2
            ld a, (hl)
            or a
            jp z, asm_1_3817_n_fp_done
            ld b, a
            inc hl
            ld de, #4800
            call #BC8C              ; CAS OUT OPEN
            di
            jr nc, asm_1_3817_n_fl_md_nc
            call #BC92              ; (a file: CAS OUT ABANDON - not made)
            di
            ld a, 1
            jr asm_1_3817_n_fl_md_r
asm_1_3817_n_fl_md_nc:
            and #7F
            cp #17                  ; (DSK_ERR_DIRECTORY_FOUND: made)
            jp z, asm_1_3817_n_fl_ok
            or a
            jr nz, asm_1_3817_n_fl_md_r
            inc a
asm_1_3817_n_fl_md_r:
            ld (asm_1_3817_n_fl_res), a
            jp asm_1_3817_n_fp_done
    ENDIF
asm_1_3817_n_fl_uc_back:                         ; A the answer, the block's first B bytes back to the slot
            ld (asm_1_3817_n_fl_res), a
            ld a, (asm_1_3817_n_FL_UB)
            add a, #C0
            ld (asm_1_3817_n_FL_UB), a
            ld hl, (var_hyp_filecall_fcb)
            ld de, asm_1_3817_n_FL_UB
asm_1_3817_n_fl_uc_out:
            ld a, (de)
            call asm_1_3817_n_fl_poke
            inc hl
            inc de
            djnz asm_1_3817_n_fl_uc_out
            jp asm_1_3817_n_fp_done
asm_1_3817_n_fl_uc_get:
            ld a, (asm_1_3817_n_FL_UB + 1)
            call asm_1_3817_n_fl_mapa
            jp c, asm_1_3817_n_fp_done
            ld de, asm_1_3817_n_FL_UB + 2
            ld c, (hl)
            ld b, 0
            inc bc
            ldir
            xor a
            ld b, 34
            jr asm_1_3817_n_fl_uc_back
    IFNDEF NTC_MSXDOS
asm_1_3817_n_fl_uc_dev:
            ld de, asm_1_3817_n_FL_UB + 2
            ld c, 1
            call asm_1_3817_n_fl_cjc
            jp nc, asm_1_3817_n_fp_done
            xor a
            ld b, 66
            jr asm_1_3817_n_fl_uc_back
asm_1_3817_n_fl_uc_inf:
            ld hl, asm_1_3817_n_FL_UB + 2
            ld de, asm_1_3817_n_FL_UB + 8
            ld c, 2
            call asm_1_3817_n_fl_cjc
            jp nc, asm_1_3817_n_fp_done
            xor a
            ld b, 72
            jr asm_1_3817_n_fl_uc_back
asm_1_3817_n_fl_uc_set:
            ld a, (asm_1_3817_n_FL_UB + 1)
            call asm_1_3817_n_fl_mapa
            jp c, asm_1_3817_n_fp_done
            ld (asm_1_3817_n_fl_ue), hl
            xor a
            ld (asm_1_3817_n_fl_exv), a
            ld a, (asm_1_3817_n_FL_UB + 2)
            or a
            jr z, asm_1_3817_n_fl_us_put         ; none: the letter itself again
            cp 32
            jp nc, asm_1_3817_n_fp_done
            ld b, a
            ld hl, asm_1_3817_n_FL_UB + 3
asm_1_3817_n_fl_us_up:                           ; capitals
            ld a, (hl)
            cp 'a'
            jr c, asm_1_3817_n_fl_us_c
            cp 'z' + 1
            jr nc, asm_1_3817_n_fl_us_c
            sub 32
            ld (hl), a
asm_1_3817_n_fl_us_c:
            inc hl
            djnz asm_1_3817_n_fl_us_up
            dec hl
            ld a, (hl)
            cp ':'
            jr z, asm_1_3817_n_fl_us_ex
            cp '/'
            jr z, asm_1_3817_n_fl_us_ex
            ld a, (asm_1_3817_n_FL_UB + 2)
            cp 31
            jp nc, asm_1_3817_n_fp_done
            inc a
            ld (asm_1_3817_n_FL_UB + 2), a
            inc hl
            ld (hl), '/'
asm_1_3817_n_fl_us_ex:
            ld hl, asm_1_3817_n_FL_UB + 2        ; a folder?
            ld de, asm_1_3817_n_fl_name_s
            ld bc, 32
            ldir
            call asm_1_3817_n_fl_exdir2
            jr z, asm_1_3817_n_fl_us_put
            cp 254
            jr z, asm_1_3817_n_fl_us_put         ; (a floppy AMSDOS runs - DFA:, DFB: - can't be examined: taken)
            or a
            jr nz, asm_1_3817_n_fl_us_err
            inc a
asm_1_3817_n_fl_us_err:
            ld (asm_1_3817_n_fl_res), a
            jp asm_1_3817_n_fp_done
asm_1_3817_n_fl_us_put:
            ld hl, asm_1_3817_n_FL_UB + 2
            ld de, (asm_1_3817_n_fl_ue)
            ld bc, 32
            ldir
            jp asm_1_3817_n_fl_ok
asm_1_3817_n_fl_uc_dir:
            ld de, asm_1_3817_n_fl_name_s + 1    ; the folder's path
            ld a, (asm_1_3817_n_FL_UB + 1)
            or a
            jr z, asm_1_3817_n_fl_ud_p
            call asm_1_3817_n_fl_pfx
            jr asm_1_3817_n_fl_ud_k
asm_1_3817_n_fl_ud_p:
            ld hl, asm_1_3817_n_FL_UB + 28
            ld a, (hl)
            cp 32
            jp nc, asm_1_3817_n_fp_done
            ld c, a
            ld b, 0
            inc hl
            ldir
asm_1_3817_n_fl_ud_k:
            call asm_1_3817_n_fl_nlen
            ld hl, asm_1_3817_n_fl_name_s        ; the same folder, still the one examined, at this entry:
            ld de, asm_1_3817_n_FL_EXK           ; on from there
            ld a, (asm_1_3817_n_fl_exv)
            or a
            jr z, asm_1_3817_n_fl_ud_new
            ld a, (hl)
            inc a
            ld b, a
asm_1_3817_n_fl_ud_cmp:
            ld a, (de)
            cp (hl)
            jr nz, asm_1_3817_n_fl_ud_new
            inc hl
            inc de
            djnz asm_1_3817_n_fl_ud_cmp
            ld hl, (asm_1_3817_n_fl_exi)
            ld de, (asm_1_3817_n_FL_UB + 2)
            or a
            sbc hl, de
            jr z, asm_1_3817_n_fl_ud_next
asm_1_3817_n_fl_ud_new:
            ld hl, asm_1_3817_n_fl_name_s
            ld de, asm_1_3817_n_FL_EXK
            ld bc, 32
            ldir
            call asm_1_3817_n_fl_exdir2
            jr z, asm_1_3817_n_fl_ud_ok
            or a
            jr nz, asm_1_3817_n_fl_us_err
            inc a
            jr asm_1_3817_n_fl_us_err
asm_1_3817_n_fl_ud_ok:
            ld hl, 0
            ld (asm_1_3817_n_fl_exi), hl
            ld a, 1
            ld (asm_1_3817_n_fl_exv), a
asm_1_3817_n_fl_ud_skip:                         ; on to entry Word(2)
            ld hl, (asm_1_3817_n_fl_exi)
            ld de, (asm_1_3817_n_FL_UB + 2)
            or a
            sbc hl, de
            jr z, asm_1_3817_n_fl_ud_next
            ld hl, asm_1_3817_n_FL_TN
            ld ix, asm_1_3817_n_FL_DATE
            ld c, 13
            call asm_1_3817_n_fl_cjc
            jr nc, asm_1_3817_n_fl_ud_end
            jr nz, asm_1_3817_n_fl_ud_end
            ld hl, (asm_1_3817_n_fl_exi)
            inc hl
            ld (asm_1_3817_n_fl_exi), hl
            jr asm_1_3817_n_fl_ud_skip
asm_1_3817_n_fl_ud_next:
            ld hl, asm_1_3817_n_FL_UB + 16
            ld ix, asm_1_3817_n_FL_UB + 9
            ld c, 13
            call asm_1_3817_n_fl_cjc
            jr nc, asm_1_3817_n_fl_ud_end
            jr nz, asm_1_3817_n_fl_ud_end
            ld (asm_1_3817_n_FL_UB + 4), a
            ld (asm_1_3817_n_FL_UB + 5), de
            ld (asm_1_3817_n_FL_UB + 7), bc
            ld hl, (asm_1_3817_n_fl_exi)
            inc hl
            ld (asm_1_3817_n_fl_exi), hl
            xor a
            ld b, 28
            jp asm_1_3817_n_fl_uc_back
asm_1_3817_n_fl_ud_end:
            xor a
            ld (asm_1_3817_n_fl_exv), a
            inc a
            ld (asm_1_3817_n_fl_res), a
            jp asm_1_3817_n_fp_done
    ENDIF
asm_1_3817_n_fp_end:
            ASSERT asm_1_3817_n_fp_end <= #6000, "FileCall's page code: below the search's cache (#6000)"
; ---- the service page's code (window data from #6000, copied there by FileCall 99)
            ds #6000 - $
asm_1_5940_n_sv_go:
            ld (asm_1_5940_n_sv_sp), sp
            ld hl, (var_hyp_svc_p)            ; p 0: slot t's claims freed (Main's FilesShut)
            ld a, h
            or l
            jp z, asm_1_5940_n_sv_cfree
            ld hl, (var_hyp_svc_p)            ; the request (16 bytes) from the slot
            ld de, (var_hyp_svc_setting)
            call asm_1_5940_n_sv_sw
            push bc
            pop ix
            ld iy, (var_hyp_svp)
            ld de, asm_1_5940_n_sv_blk
            ld a, 16
            call asm_1_5940_n_sv_dx
            ld hl, (asm_1_5940_n_sv_blk + 8)     ; how many: 2K at most
            bit 7, h
            jr nz, asm_1_5940_n_sv_n2
            ld de, 2049
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_5940_n_sv_n1
asm_1_5940_n_sv_n2:
            ld hl, 2048
asm_1_5940_n_sv_n1:
            ld (asm_1_5940_n_sv_n), hl
            xor a
            ld (asm_1_5940_n_sv_stop), a
            ld a, 2                 ; (the copies to the slot: its bank)
            ld (asm_1_5940_n_sv_dk), a
            ld hl, (var_hyp_svc_setting)
            ld (asm_1_5940_n_sv_ds), hl
            ld hl, (asm_1_5940_n_sv_blk + 6)
            ld (asm_1_5940_n_sv_da), hl
            ld a, (asm_1_5940_n_sv_blk)
            cp 10
            jp z, asm_1_5940_n_sv_mem
            cp 11
            jp z, asm_1_5940_n_sv_ptr
            cp 13
            jp z, asm_1_5940_n_sv_store
            cp 14
            jp z, asm_1_5940_n_sv_store
            cp 15
            jp z, asm_1_5940_n_sv_tab
            cp 16
            jp c, asm_1_5940_n_sv_err
            cp 20
            jp c, asm_1_5940_n_sv_claim
            cp 28
            jp c, asm_1_5940_n_sv_net
            cp 34
            jp c, asm_1_5940_n_sv_port
            jp z, asm_1_5940_n_pt_list
asm_1_5940_n_sv_err:
            ld sp, (asm_1_5940_n_sv_sp)
            ld a, 255
            ret
asm_1_5940_n_sv_ok:
            ld sp, (asm_1_5940_n_sv_sp)
            xor a
            ret
; 10: memory
asm_1_5940_n_sv_mem:
            ld a, (asm_1_5940_n_sv_blk + 1)
            cp 4
            jr z, asm_1_5940_n_sv_m4             ; 4: the caller's Word(6) into slot Word(2) at Word(4)
            ld hl, (asm_1_5940_n_sv_blk + 4)
            ld (asm_1_5940_n_sv_sa), hl
            ld hl, (asm_1_5940_n_sv_blk + 2)
            or a
            jr nz, asm_1_5940_n_sv_m1
            ld de, (mem_count)      ; 0: a page (below Pages)
            push hl
            or a
            sbc hl, de
            pop hl
            jp nc, asm_1_5940_n_sv_err
            call asm_1_5940_n_sv_pgset
            ld (asm_1_5940_n_sv_ss), bc
            ld a, 1
            ld (asm_1_5940_n_sv_stop), a
            jr asm_1_5940_n_sv_mgo
asm_1_5940_n_sv_m1:
            dec a
            jr nz, asm_1_5940_n_sv_m2
            ld (asm_1_5940_n_sv_ss), hl          ; 1: a ROM
            ld a, 1
            ld (asm_1_5940_n_sv_stop), a
            ld a, 3
            jr asm_1_5940_n_sv_mgo1
asm_1_5940_n_sv_m2:
            dec a
            jr nz, asm_1_5940_n_sv_m3
            ld a, 4                 ; 2: main RAM
            jr asm_1_5940_n_sv_mgo1
asm_1_5940_n_sv_m3:
            dec a
            jp nz, asm_1_5940_n_sv_err
            call asm_1_5940_n_sv_slot            ; 3: a slot's memory (one in use)
            jp z, asm_1_5940_n_sv_err
            ld (asm_1_5940_n_sv_ss), de
            ld a, 2
            jr asm_1_5940_n_sv_mgo1
asm_1_5940_n_sv_mgo:
            ld a, 1
asm_1_5940_n_sv_mgo1:
            ld (asm_1_5940_n_sv_sk), a
            call asm_1_5940_n_sv_copy
            jr asm_1_5940_n_sv_ok
; 10 Byte(1) 4: the caller's own Word(6) written into slot Word(2) at Word(4), Word(8) bytes
asm_1_5940_n_sv_m4:
            ld hl, (asm_1_5940_n_sv_blk + 2)
            call asm_1_5940_n_sv_slot            ; the target slot (one in use): DE its RAM setting
            jp z, asm_1_5940_n_sv_err
            ld (asm_1_5940_n_sv_ds), de          ; dest: that slot's bank, at Word(4)
            ld a, 2
            ld (asm_1_5940_n_sv_dk), a
            ld hl, (asm_1_5940_n_sv_blk + 4)
            ld (asm_1_5940_n_sv_da), hl
            ld hl, (var_hyp_svc_setting)      ; source: the caller's bank, at Word(6)
            ld (asm_1_5940_n_sv_ss), hl
            ld a, 2
            ld (asm_1_5940_n_sv_sk), a
            ld hl, (asm_1_5940_n_sv_blk + 6)
            ld (asm_1_5940_n_sv_sa), hl
            xor a
            ld (asm_1_5940_n_sv_stop), a
            call asm_1_5940_n_sv_copy
            jp asm_1_5940_n_sv_ok
; HL = a slot number: Z when it isn't one in use, else DE = its RAM setting
asm_1_5940_n_sv_slot:
            ld a, h
            or a
            jr nz, asm_1_5940_n_sv_sl0
            or l
            ret z
            ld de, (var_hyp_svns)
            ld a, (de)
            cp l
            jr c, asm_1_5940_n_sv_sl0
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
asm_1_5940_n_sv_sl0:
            xor a
            ret
; 13 / 14: a 2K block of the store (13 from the slot, 14 to it) - Byte(1) 1: from Word(4) bytes into
; the block (any part of its 16K page, not past the page's end: Pluto's KEYMAN reads a key a byte at a time)
asm_1_5940_n_sv_store:
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld a, h
            or a
            jp nz, asm_1_5940_n_sv_err
            ld a, l
            and 7
            add a, a
            add a, a
            add a, a
            ld (asm_1_5940_n_sv_sa + 1), a       ; the block's place in its page
            xor a
            ld (asm_1_5940_n_sv_sa), a
            srl l
            srl l
            srl l
            ld a, (asm_1_5940_n_sv_blk + 1)      ; Byte(1) 1: Word(4) bytes on from the block's start (its page's end the limit)
            or a
            jr z, asm_1_5940_n_sv_sto0
            ld a, (asm_1_5940_n_sv_blk + 4)
            ld (asm_1_5940_n_sv_sa), a
            ld a, (asm_1_5940_n_sv_blk + 5)
            ld b, a
            ld a, (asm_1_5940_n_sv_sa + 1)
            add a, b
            and #3F
            ld (asm_1_5940_n_sv_sa + 1), a
asm_1_5940_n_sv_sto0:
            ld h, #FF               ; its page: the slot's byte at #FF00 + block / 8
            ld de, (var_hyp_svc_setting)
            call asm_1_5940_n_sv_sw
            push bc
            pop ix
            ld iy, (var_hyp_svp)
            ld de, asm_1_5940_n_sv_tmp
            ld a, 1
            call asm_1_5940_n_sv_dx
            ld a, (asm_1_5940_n_sv_tmp)
            or a
            jp z, asm_1_5940_n_sv_err
            ld l, a
            ld h, 0
            call asm_1_5940_n_sv_pgset
            ld (asm_1_5940_n_sv_ss), bc
            ld a, 1
            ld (asm_1_5940_n_sv_sk), a
            ld a, (asm_1_5940_n_sv_blk)
            cp 14
            jr z, asm_1_5940_n_sv_st1
            ld hl, (asm_1_5940_n_sv_sa)          ; 13: the slot to the page
            ld (asm_1_5940_n_sv_da), hl
            ld hl, (asm_1_5940_n_sv_ss)
            ld (asm_1_5940_n_sv_ds), hl
            ld a, 1
            ld (asm_1_5940_n_sv_dk), a
            ld hl, (asm_1_5940_n_sv_blk + 6)
            ld (asm_1_5940_n_sv_sa), hl
            ld hl, (var_hyp_svc_setting)
            ld (asm_1_5940_n_sv_ss), hl
            ld a, 2
            ld (asm_1_5940_n_sv_sk), a
asm_1_5940_n_sv_st1:
            call asm_1_5940_n_sv_copy
            jp asm_1_5940_n_sv_ok
; 11: the pointer, while the slot is in front
asm_1_5940_n_sv_ptr:
            ld hl, (var_hyp_svfr)
            ld a, (hl)
            ld hl, var_hyp_svc_t
            cp (hl)
            jp nz, asm_1_5940_n_sv_ok
            ld a, (var_hyp_pon)
            or a
            call nz, asm_1_5940_n_pt_xor
            xor a
            ld (var_hyp_pon), a
            ld a, (asm_1_5940_n_sv_blk + 1)
            or a
            jp z, asm_1_5940_n_sv_ok
            ld a, (asm_1_5940_n_sv_blk + 2)
            ld hl, var_hyp_scc
            cp (hl)
            jp nc, asm_1_5940_n_sv_ok            ; (off the screen: none)
            ld (var_hyp_pox), a
            ld a, (asm_1_5940_n_sv_blk + 3)
            ld (var_hyp_poy), a
            call asm_1_5940_n_pt_xor
            ld a, 1
            ld (var_hyp_pon), a
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_pt_xor:                             ; the checkerboard XORed at pox, poy (the screen is main RAM)
            ld a, (var_hyp_poy)
            ld e, a
            ld d, 0
            ld hl, 0
            ld a, (var_hyp_scc)
            ld b, 8
asm_1_5940_n_pt_mul:
            add hl, hl
            rlca
            jr nc, asm_1_5940_n_pt_mn
            add hl, de
asm_1_5940_n_pt_mn:
            djnz asm_1_5940_n_pt_mul
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
asm_1_5940_n_pt_ln:
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
            djnz asm_1_5940_n_pt_ln
            ret
; 15: a table
asm_1_5940_n_sv_tab:
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld (asm_1_5940_n_sv_da), hl
            ld a, (asm_1_5940_n_sv_blk + 1)
            or a
            jr z, asm_1_5940_n_sv_t0
            dec a
            jp z, asm_1_5940_n_sv_t1
            dec a
            jp z, asm_1_5940_n_sv_t2
            dec a
            jp z, asm_1_5940_n_sv_t3
            dec a
            jp z, asm_1_5940_n_sv_t4
            jp asm_1_5940_n_sv_err
; 4: the claims - CL_N records of 10 bytes: the slot holding it (0: a free record), the unit,
; the name (8 characters, spaces after it)
asm_1_5940_n_sv_t4:
            ld hl, asm_1_5940_n_sv_cl
            ld de, (asm_1_5940_n_sv_da)
            ld bc, asm_1_5940_n_CL_N * 10
            call asm_1_5940_n_sv_out
            jp asm_1_5940_n_sv_ok
; 0: the slots - a word how many, then from 16 a record each: state, in front, MODE, the name's
; length, the name
asm_1_5940_n_sv_t0:
            call asm_1_5940_n_sv_clr
            ld hl, (var_hyp_svns)
            ld a, (hl)
            ld (asm_1_5940_n_sv_rec), a
            ld (asm_1_5940_n_sv_tn), a
            call asm_1_5940_n_sv_out16
            ld a, 1
            ld (asm_1_5940_n_sv_tj), a
asm_1_5940_n_sv_t0lp:
            ld a, (asm_1_5940_n_sv_tn)
            ld b, a
            ld a, (asm_1_5940_n_sv_tj)
            cp b
            jr z, asm_1_5940_n_sv_t0a
            jp nc, asm_1_5940_n_sv_ok
asm_1_5940_n_sv_t0a:
            ld hl, (asm_1_5940_n_sv_da)
            ld de, 16
            add hl, de
            ld (asm_1_5940_n_sv_da), hl
            call asm_1_5940_n_sv_clr
            ld a, (asm_1_5940_n_sv_tj)
            ld l, a
            ld h, 0
            add hl, hl
            ld de, (var_hyp_svst)
            add hl, de
            ld a, (hl)
            ld (asm_1_5940_n_sv_rec), a          ; its state
            ld hl, (var_hyp_svfr)
            ld a, (asm_1_5940_n_sv_tj)
            cp (hl)
            jr nz, asm_1_5940_n_sv_t0b
            ld a, 1
            ld (asm_1_5940_n_sv_rec + 1), a      ; in front
asm_1_5940_n_sv_t0b:
            ld a, (asm_1_5940_n_sv_rec)
            or a
            jr z, asm_1_5940_n_sv_t0d
            ld a, (asm_1_5940_n_sv_tj)           ; its RAM setting
            ld l, a
            ld h, 0
            add hl, hl
            ld de, (var_hyp_svsg)
            add hl, de
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (asm_1_5940_n_sv_tsg), de
            ld hl, 63113          ; MODE
            ld a, 1
            call asm_1_5940_n_sv_from
            ld a, (asm_1_5940_n_sv_tmp)
            ld (asm_1_5940_n_sv_rec + 2), a
            ld a, (asm_1_5940_n_sv_rec)
            cp 2
            jr nz, asm_1_5940_n_sv_t0d
            ld de, (asm_1_5940_n_sv_tsg)
            ld hl, #F6D8            ; the program's name: its length, then 12
            ld a, 13
            call asm_1_5940_n_sv_from
            ld a, (asm_1_5940_n_sv_tmp)
            cp 13
            jr c, asm_1_5940_n_sv_t0c
            ld a, 12
asm_1_5940_n_sv_t0c:
            ld (asm_1_5940_n_sv_rec + 3), a
            ld hl, asm_1_5940_n_sv_tmp + 1
            ld de, asm_1_5940_n_sv_rec + 4
            ld bc, 12
            ldir
asm_1_5940_n_sv_t0d:
            ld hl, asm_1_5940_n_sv_tj
            push hl
            call asm_1_5940_n_sv_out16
            pop hl
            inc (hl)
            jp asm_1_5940_n_sv_t0lp
; 1: the memory - words: the tables' end, the top, the pages, total K, free pages; from 16 a byte a page
asm_1_5940_n_sv_t1:
            call asm_1_5940_n_sv_clr
            ld hl, (mem_tend)
            ld (asm_1_5940_n_sv_rec), hl
            call mem_top
            ld (asm_1_5940_n_sv_rec + 2), hl
            ld hl, (mem_count)
            ld (asm_1_5940_n_sv_rec + 4), hl
            call mem_ramsize
            ld (asm_1_5940_n_sv_rec + 6), hl
            call mem_freepages
            ld (asm_1_5940_n_sv_rec + 8), hl
            ld hl, asm_1_5940_n_sv_rec
            ld de, (asm_1_5940_n_sv_da)
            ld bc, 18               ; (and pages 0, 1: 0)
            call asm_1_5940_n_sv_out
            ld hl, (mem_count)      ; pages 2 on: the RAT (2030 at most)
            dec hl
            ld a, h
            or l
            jp z, asm_1_5940_n_sv_ok
            ld de, 2031
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_5940_n_sv_t1a
            ld hl, 2030
asm_1_5940_n_sv_t1a:
            ld (asm_1_5940_n_sv_n), hl
            ld hl, (mem_ttype)
            inc hl
            ld (asm_1_5940_n_sv_sa), hl
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld de, 18
            add hl, de
            ld (asm_1_5940_n_sv_da), hl
            xor a
            ld (asm_1_5940_n_sv_sk), a
            ld (asm_1_5940_n_sv_stop), a
            call asm_1_5940_n_sv_copy
            jp asm_1_5940_n_sv_ok
; 2: the upper ROMs 0-31 - 64 bytes each: the first 16, then 48 of the name table (0s if none)
asm_1_5940_n_sv_t2:
    IFDEF NTC_MSXDOS
            jp asm_1_5940_n_sv_err               ; zxn: no upper ROMs
    ENDIF
            xor a
            ld (asm_1_5940_n_sv_tj), a
asm_1_5940_n_sv_t2lp:
            call asm_1_5940_n_sv_clr
            ld a, (asm_1_5940_n_sv_tj)
            ld c, a
            call #B90F              ; KL ROM SELECT (#C000 only: this code at #6000 stays)
            di
            push bc
            ld hl, #C000
            ld de, asm_1_5940_n_sv_rec
            ld bc, 16
            ldir
            ld hl, (asm_1_5940_n_sv_rec + 4)
            ld a, h
            and #C0
            cp #C0
            jr nz, asm_1_5940_n_sv_t2a
            ld de, #FF90
            or a
            sbc hl, de
            add hl, de
            jr nc, asm_1_5940_n_sv_t2a
            ld de, asm_1_5940_n_sv_rec + 16
            ld bc, 48
            ldir
asm_1_5940_n_sv_t2a:
            pop bc
            call #B918              ; KL ROM DESELECT
            di
            ld hl, asm_1_5940_n_sv_rec
            ld de, (asm_1_5940_n_sv_da)
            ld bc, 64
            call asm_1_5940_n_sv_out
            ld hl, (asm_1_5940_n_sv_da)
            ld de, 64
            add hl, de
            ld (asm_1_5940_n_sv_da), hl
            ld hl, asm_1_5940_n_sv_tj
            inc (hl)
            ld a, (hl)
            cp 32
            jr c, asm_1_5940_n_sv_t2lp
            jp asm_1_5940_n_sv_ok
; 3: the RAM discs - the driver's table (its page, #6A00: 128 bytes), 0s if none
asm_1_5940_n_sv_t3:
            call asm_1_5940_n_sv_clr
            ld hl, (var_hyp_svdp)
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld a, d
            or e
            jr z, asm_1_5940_n_sv_t3a
            ex de, hl
            call asm_1_5940_n_sv_pgset
            ld (asm_1_5940_n_sv_ss), bc
            ld hl, #6A00
            ld (asm_1_5940_n_sv_sa), hl
            ld hl, 128
            ld (asm_1_5940_n_sv_n), hl
            ld a, 1
            ld (asm_1_5940_n_sv_sk), a
            xor a
            ld (asm_1_5940_n_sv_stop), a
            call asm_1_5940_n_sv_copy
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_sv_t3a:
            ld hl, asm_1_5940_n_sv_rec
            ld de, (asm_1_5940_n_sv_da)
            ld bc, 128
            call asm_1_5940_n_sv_out
            jp asm_1_5940_n_sv_ok
; sv_from - A bytes from slot (sv_tsg's) HL into sv_tmp
asm_1_5940_n_sv_from:
            ld de, (asm_1_5940_n_sv_tsg)
            push af
            call asm_1_5940_n_sv_sw
            push bc
            pop ix
            ld iy, (var_hyp_svp)
            ld de, asm_1_5940_n_sv_tmp
            pop af
            jp asm_1_5940_n_sv_dx
; sv_clr - sv_rec (128 bytes) 0
asm_1_5940_n_sv_clr:
            ld hl, asm_1_5940_n_sv_rec
            ld de, asm_1_5940_n_sv_rec + 1
            ld bc, 127
            ld (hl), 0
            ldir
            ret
; sv_out16 - sv_rec's first 16 to the slot at sv_da; sv_out - BC bytes from HL (here) to the slot's DE
asm_1_5940_n_sv_out16:
            ld hl, asm_1_5940_n_sv_rec
            ld de, (asm_1_5940_n_sv_da)
            ld bc, 16
asm_1_5940_n_sv_out:
            ld (asm_1_5940_n_sv_sa), hl
            ld (asm_1_5940_n_sv_da), de
            ld (asm_1_5940_n_sv_n), bc
            ld a, 1
            ld (asm_1_5940_n_sv_sk), a
            ld hl, (var_hyp_svp)
            ld (asm_1_5940_n_sv_ss), hl
            xor a
            ld (asm_1_5940_n_sv_stop), a
            ld hl, (asm_1_5940_n_sv_da)
            push hl
            call asm_1_5940_n_sv_copy
            pop hl
            ld (asm_1_5940_n_sv_da), hl          ; (where it went: kept)
            ret
; sv_copy - sv_n bytes from the source (sv_sk: 0 main RAM outside the window, 1 a page - RAM setting
; sv_ss, 2 a bank - C2 setting sv_ss, 3 ROM sv_ss, 4 main RAM anywhere) at sv_sa to the
; destination (sv_dk: 1 a page, 2 a bank; sv_ds) at sv_da, 128 at most a go, none across a 16K
; page's end; sv_stop: at the source's page end, stop
asm_1_5940_n_sv_copy:
            ld hl, (asm_1_5940_n_sv_n)
            ld a, h
            or l
            ret z
            ld bc, 128
            or a
            sbc hl, bc
            add hl, bc
            jr nc, asm_1_5940_n_sc_c1
            ld b, h
            ld c, l
asm_1_5940_n_sc_c1:
            ld (asm_1_5940_n_sv_c), bc
            ld a, (asm_1_5940_n_sv_sk)
            or a
            jr z, asm_1_5940_n_sc_dl
            ld hl, (asm_1_5940_n_sv_sa)
            call asm_1_5940_n_sc_room
asm_1_5940_n_sc_dl:
            ld hl, (asm_1_5940_n_sv_da)
            call asm_1_5940_n_sc_room
            ld a, (asm_1_5940_n_sv_sk)           ; the source: IX its RAM setting, HL where
            ld hl, (asm_1_5940_n_sv_sa)
            ld ix, 0
            or a
            jr z, asm_1_5940_n_sc_sok
            cp 1
            jr nz, asm_1_5940_n_sc_s2
            ld ix, (asm_1_5940_n_sv_ss)
            call asm_1_5940_n_sc_win
            jr asm_1_5940_n_sc_sok
asm_1_5940_n_sc_s2:
            cp 2
            jr nz, asm_1_5940_n_sc_s3
            ld de, (asm_1_5940_n_sv_ss)
            call asm_1_5940_n_sv_sw
            push bc
            pop ix
            jr asm_1_5940_n_sc_sok
asm_1_5940_n_sc_s3:
            cp 3
            jr nz, asm_1_5940_n_sc_s4
    IFDEF NTC_MSXDOS
            jp asm_1_5940_n_sv_err               ; zxn: no upper ROMs
    ENDIF
            ld a, (asm_1_5940_n_sv_ss)           ; a ROM: its bytes into buf first
            ld c, a
            call #B90F              ; KL ROM SELECT
            di
            push bc
            ld hl, (asm_1_5940_n_sv_sa)
            ld a, h
            or #C0
            ld h, a
            ld de, (var_hyp_svc_buf)
            ld bc, (asm_1_5940_n_sv_c)
            ldir
            pop bc
            call #B918              ; KL ROM DESELECT
            di
            ld hl, (var_hyp_svc_buf)
            jr asm_1_5940_n_sc_sok
asm_1_5940_n_sc_s4:
            ld a, h                 ; main RAM: its #4000-#7FFF is page 1
            and #C0
            cp #40
            jr nz, asm_1_5940_n_sc_sok
            push hl
            ld hl, 1
            call asm_1_5940_n_sv_pgset
            pop hl
            push bc
            pop ix
asm_1_5940_n_sc_sok:
            push hl
            ld a, (asm_1_5940_n_sv_dk)           ; the destination: IY, DE
            ld hl, (asm_1_5940_n_sv_da)
            cp 1
            jr nz, asm_1_5940_n_sc_d2
            ld iy, (asm_1_5940_n_sv_ds)
            call asm_1_5940_n_sc_win
            jr asm_1_5940_n_sc_dok
asm_1_5940_n_sc_d2:
            ld de, (asm_1_5940_n_sv_ds)
            call asm_1_5940_n_sv_sw
            push bc
            pop iy
asm_1_5940_n_sc_dok:
            ex de, hl
            pop hl
            ld a, (asm_1_5940_n_sv_c)
            call asm_1_5940_n_sv_dx
            ld bc, (asm_1_5940_n_sv_c)
            ld hl, (asm_1_5940_n_sv_sa)
            add hl, bc
            ld (asm_1_5940_n_sv_sa), hl
            ld hl, (asm_1_5940_n_sv_da)
            add hl, bc
            ld (asm_1_5940_n_sv_da), hl
            ld hl, (asm_1_5940_n_sv_n)
            or a
            sbc hl, bc
            ld (asm_1_5940_n_sv_n), hl
            ld a, (asm_1_5940_n_sv_stop)
            or a
            jp z, asm_1_5940_n_sv_copy
            ld a, (asm_1_5940_n_sv_sa + 1)
            and #3F
            ld b, a
            ld a, (asm_1_5940_n_sv_sa)
            or b
            jp nz, asm_1_5940_n_sv_copy
            ret
asm_1_5940_n_sc_room:                            ; sv_c no more than to HL's 16K page's end
            ld a, h
            and #3F
            ld h, a
            ex de, hl
            ld hl, 16384
            or a
            sbc hl, de
            ld de, (asm_1_5940_n_sv_c)
            or a
            sbc hl, de
            ret nc
            add hl, de
            ld (asm_1_5940_n_sv_c), hl
            ret
asm_1_5940_n_sc_win:                             ; HL: its place in the window
            ld a, h
            and #3F
            or #40
            ld h, a
            ret
; sv_sw - DE = a bank's C2 setting, HL = an address in it: BC = the setting with its page in the
; window, HL = the address there
asm_1_5940_n_sv_sw:
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
            jr asm_1_5940_n_sc_win
; sv_pgset - HL = a page: BC = its RAM setting (the Memory class's port table; 0 main RAM)
asm_1_5940_n_sv_pgset:
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
asm_1_5940_n_CL_N:       equ 16
asm_1_5940_n_sv_claim:
            ld b, a                 ; B = the op
            call asm_1_5940_n_cl_find            ; Z: HL = its record
            ld a, (var_hyp_svc_t)
            ld c, a                 ; C = this slot
            jr nz, asm_1_5940_n_cl_none
            ld a, b
            cp 17
            jr z, asm_1_5940_n_cl_rel
            ld a, (hl)              ; who has it
            ld (asm_1_5940_n_sv_tn), a
            ld a, b
            cp 18
            jr nz, asm_1_5940_n_cl_who
            ld (hl), c              ; 18: taken
            ld a, (asm_1_5940_n_sv_tn)
            jr asm_1_5940_n_cl_ret
asm_1_5940_n_cl_who:
            ld a, (asm_1_5940_n_sv_tn)           ; 16, 19: 0 when it is this slot's
            cp c
            jp z, asm_1_5940_n_sv_ok
            jr asm_1_5940_n_cl_ret
asm_1_5940_n_cl_rel:
            ld a, (hl)
            cp c
            jr nz, asm_1_5940_n_cl_one
            ld (hl), 0
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_cl_none:
            ld a, b
            cp 17
            jr z, asm_1_5940_n_cl_one
            cp 19
            ld a, 254
            jr z, asm_1_5940_n_cl_ret
            ld hl, asm_1_5940_n_sv_cl            ; 16, 18: into a free record
            ld de, 10
            ld b, asm_1_5940_n_CL_N
asm_1_5940_n_cl_fr:
            ld a, (hl)
            or a
            jr z, asm_1_5940_n_cl_put
            add hl, de
            djnz asm_1_5940_n_cl_fr
            jp asm_1_5940_n_sv_err
asm_1_5940_n_cl_put:
            ld (hl), c
            inc hl
            ex de, hl
            ld hl, asm_1_5940_n_sv_blk + 1
            ld bc, 9
            ldir
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_cl_one:
            ld a, 1
asm_1_5940_n_cl_ret:
            ld sp, (asm_1_5940_n_sv_sp)
            ret
; cl_find - Z: HL = the record with sv_blk's unit and name, else NZ (B kept)
asm_1_5940_n_cl_find:
            ld hl, asm_1_5940_n_sv_cl
            ld c, asm_1_5940_n_CL_N
asm_1_5940_n_cl_f1:
            ld a, (hl)
            or a
            jr z, asm_1_5940_n_cl_f3             ; (a free record)
            push hl
            push bc
            inc hl
            ld de, asm_1_5940_n_sv_blk + 1
            ld b, 9
asm_1_5940_n_cl_f2:
            ld a, (de)
            cp (hl)
            jr nz, asm_1_5940_n_cl_f4
            inc hl
            inc de
            djnz asm_1_5940_n_cl_f2
asm_1_5940_n_cl_f4:
            pop bc
            pop hl
            ret z
asm_1_5940_n_cl_f3:
            ld de, 10
            add hl, de
            dec c
            jr nz, asm_1_5940_n_cl_f1
            or 1
            ret
; p 0: slot t's claims all freed
asm_1_5940_n_sv_cfree:
            ld a, (var_hyp_svc_t)
            ld c, a
            ld hl, asm_1_5940_n_sv_cl
            ld de, 10
            ld b, asm_1_5940_n_CL_N
asm_1_5940_n_cl_cf:
            ld a, (hl)
            cp c
            jr nz, asm_1_5940_n_cl_cf1
            ld (hl), 0
asm_1_5940_n_cl_cf1:
            add hl, de
            djnz asm_1_5940_n_cl_cf
            call asm_1_5940_n_pt_free            ; its ports closed, its calls forgotten (C = the slot)
            ld a, (asm_1_5940_n_nt_rom)          ; its sockets closed
            inc a
            jp z, asm_1_5940_n_sv_ok
            ld b, 0
asm_1_5940_n_cl_cs:
            ld hl, asm_1_5940_n_nt_own
            ld e, b
            ld d, 0
            add hl, de
            ld a, (hl)
            cp c
            jr nz, asm_1_5940_n_cl_cs1
            push bc
            ld a, b
            call asm_1_5940_n_nt_close
            pop bc
asm_1_5940_n_cl_cs1:
            inc b
            ld a, b
            cp 8
            jr c, asm_1_5940_n_cl_cs
            jp asm_1_5940_n_sv_ok
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
;       1 a ZX Spectrum Next (a program built for the cyborgos platform runs on both)
;   21  a name looked up: Word(2) where it is, Byte(4) its length (63 at most) - 1: started
;       (22 with 255 then: the state, 0 found - its IP at +4)
;   22  socket Byte(1)'s 16 bytes to Word(2) (255: the lookup's): its state
;   23  a TCP socket: its number (255 none)
;   24  socket Byte(1) connected to IP Byte(2-5), port Word(6): 0 started (22: 1 still, 0 done)
;   25  Word(4) bytes (1-240) from Word(2) sent on socket Byte(1): 0 done
;   26  up to Word(4) bytes (2048 at most) of socket Byte(1)'s to Word(2): 0 done - how many
;       written back to the request's Word(6)
;   27  socket Byte(1) closed
asm_1_5940_n_NT_N:       equ 8                   ; sockets 0-7
asm_1_5940_n_sv_net:
    IFDEF NTC_MSXDOS
            jp asm_1_5940_n_es_net               ; zxn: the ESP (below)
    ENDIF
            ld b, a
            cp 20
            jr z, asm_1_5940_n_nt_20
            ld a, (asm_1_5940_n_nt_rom)
            inc a
            jp z, asm_1_5940_n_sv_err            ; (no network)
            ld a, b
            cp 21
            jp z, asm_1_5940_n_nt_look
            cp 23
            jp z, asm_1_5940_n_nt_sock
            call asm_1_5940_n_nt_chk             ; (the rest: one of the slot's sockets)
            ld a, b
            cp 22
            jp z, asm_1_5940_n_nt_stat
            cp 24
            jp z, asm_1_5940_n_nt_conn
            cp 25
            jp z, asm_1_5940_n_nt_send
            cp 26
            jp z, asm_1_5940_n_nt_recv
            ld a, (asm_1_5940_n_sv_blk + 1)      ; 27
            call asm_1_5940_n_nt_close
            jp asm_1_5940_n_nt_ans
asm_1_5940_n_nt_20:
            ld a, (asm_1_5940_n_sv_blk + 1)
            or a
            jr nz, asm_1_5940_n_nt_20a
            ld a, (asm_1_5940_n_nt_rom)
            jp asm_1_5940_n_nt_ret
asm_1_5940_n_nt_20a:
            cp 7
            jp z, asm_1_5940_n_nt_shared
            cp 6
            jp z, asm_1_5940_n_nt_boot
            cp 5
            jp z, asm_1_5940_n_nt_host
            cp 4
            jr z, asm_1_5940_n_nt_uptime
            cp 3
            jr z, asm_1_5940_n_nt_time
            dec a
            jp nz, asm_1_5940_n_nt_off
    IFDEF NTC_MSXDOS
            jp asm_1_5940_n_sv_err               ; zxn: no M4 (the Next's own network is to come)
    ENDIF
            ld a, (asm_1_5940_n_sv_blk + 2)      ; on: the M4's ROM, where its answers and sockets are
            ld (asm_1_5940_n_nt_rom), a
            ld a, 1                 ; the network indicator: up
            ld (var_hyp_ntu), a
            ld hl, #FF02
            ld de, asm_1_5940_n_nt_rsp
            ld bc, 2
            call asm_1_5940_n_nt_rd
            ld hl, #FF06
            ld de, asm_1_5940_n_nt_skt
            ld bc, 2
            call asm_1_5940_n_nt_rd
            ld c, 255               ; M4 0: CyborgOS's
            call asm_1_5940_n_nt_m4c
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_nt_off:
    IFDEF NTC_MSXDOS
            jp asm_1_5940_n_sv_ok                ; zxn: nothing to close
    ENDIF
            ld b, 0                 ; off: every socket closed, M4 0 given back
asm_1_5940_n_nt_of1:
            ld hl, asm_1_5940_n_nt_own
            ld e, b
            ld d, 0
            add hl, de
            ld a, (hl)
            or a
            jr z, asm_1_5940_n_nt_of2
            push bc
            ld a, b
            call asm_1_5940_n_nt_close
            pop bc
asm_1_5940_n_nt_of2:
            inc b
            ld a, b
            cp asm_1_5940_n_NT_N
            jr c, asm_1_5940_n_nt_of1
            ld c, 0
            call asm_1_5940_n_nt_m4c
            ld a, 255
            ld (asm_1_5940_n_nt_rom), a
            xor a                   ; the network indicator: off
            ld (var_hyp_ntu), a
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_nt_time:
    IFDEF NTC_MSXDOS
            call msx_t300               ; zxn: the interrupt count (300 a second, as the CPC's)
    ELSE
            call #BD0D              ; 3: KL TIME PLEASE - its low word (300 a second) to Word(6)
            di
    ENDIF
            ld (asm_1_5940_n_sv_tmp + 4), hl
            ld hl, (var_hyp_svc_p)
            ld de, 6
            add hl, de
            ex de, hl
            ld hl, asm_1_5940_n_sv_tmp + 4
            ld bc, 2
            call asm_1_5940_n_sv_out
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_nt_uptime:
    IFDEF NTC_MSXDOS
            call msx_t300               ; zxn: the interrupt count (16 bits: wraps at 65536 / 300 s)
            ld de, 0
    ELSE
            call #BD0D              ; 4: KL TIME PLEASE - all 32 bits (300 a second since the reset) to Word(6), Word(8)
            di
    ENDIF
            ld (asm_1_5940_n_sv_tmp + 4), hl
            ld (asm_1_5940_n_sv_tmp + 6), de
            ld hl, (var_hyp_svc_p)
            ld de, 6
            add hl, de
            ex de, hl
            ld hl, asm_1_5940_n_sv_tmp + 4
            ld bc, 4
            call asm_1_5940_n_sv_out
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_nt_ans:
            ld a, (asm_1_5940_n_sv_tmp + 3)      ; the M4's answer
asm_1_5940_n_nt_ret:
            ld sp, (asm_1_5940_n_sv_sp)
            ret
asm_1_5940_n_nt_boot:                            ; 6: the boot drive's letter (CybSys.BootDrive: A, or the Next's D =
            ld a, (var_hyp_svbd)          ; C:CYBORGOS/): CD on it gives the slot a free letter, as on A and B
            jp asm_1_5940_n_nt_ret               ; (the letter is every slot's: its path changed would move them all)
asm_1_5940_n_nt_shared:                          ; 7: the other slots (open) on drive letter Byte(2) - their dv(),
            ld a, (var_hyp_svc_t)             ; 0 being the boot drive's (CybSys.Shared: CD moves a letter only
            ld c, a                 ; nobody else is on - a letter's path is every slot's)
            ld b, 0                 ; B = the count
            ld hl, (var_hyp_svns)
            ld a, (hl)
            or a
            jr z, asm_1_5940_n_ns_end
            ld e, a                 ; E = the slot
asm_1_5940_n_ns_lp:
            ld a, e
            cp c
            jr z, asm_1_5940_n_ns_nx
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
            jr z, asm_1_5940_n_ns_nx
            push de
            ld de, (var_hyp_svdv)
            add hl, de
            pop de
            ld a, (hl)
            or a
            jr nz, asm_1_5940_n_ns_d
            ld a, (var_hyp_svbd)
asm_1_5940_n_ns_d:
            ld d, a
            ld a, (asm_1_5940_n_sv_blk + 2)
            cp d
            jr nz, asm_1_5940_n_ns_nx
            inc b
asm_1_5940_n_ns_nx:
            dec e
            jr nz, asm_1_5940_n_ns_lp
asm_1_5940_n_ns_end:
            ld a, b
            jp asm_1_5940_n_nt_ret
asm_1_5940_n_nt_host:                            ; 5: the host machine (CybSys.Host): 0 an Amstrad CPC, 1 a ZX Spectrum Next
    IFDEF NTC_MSXDOS
            ld a, 1
    ELSE
            xor a
    ENDIF
            jp asm_1_5940_n_nt_ret
; 21: a name looked up
asm_1_5940_n_nt_look:
            ld a, (asm_1_5940_n_sv_blk + 4)
            cp 64
            jp nc, asm_1_5940_n_sv_err
            ld c, a
            ld b, 0
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld de, asm_1_5940_n_nt_pk + 3
            push bc
            call asm_1_5940_n_sv_in
            pop bc
            ld hl, asm_1_5940_n_nt_pk + 3
            add hl, bc
            ld (hl), 0
            ld a, c
            add a, 3
            ld hl, #4336            ; C_NETHOSTIP
            call asm_1_5940_n_nt_hdr
            call asm_1_5940_n_nt_go
            jr asm_1_5940_n_nt_ans
; 22: a socket's 16 bytes to the slot
asm_1_5940_n_nt_stat:
            ld a, (asm_1_5940_n_sv_blk + 1)
            call asm_1_5940_n_nt_ent
            ld de, asm_1_5940_n_sv_tmp
            ld bc, 16
            call asm_1_5940_n_nt_rd
            ld hl, asm_1_5940_n_sv_tmp
            ld de, (asm_1_5940_n_sv_blk + 2)
            ld bc, 16
            call asm_1_5940_n_sv_out
            ld a, (asm_1_5940_n_sv_tmp)
            jp asm_1_5940_n_nt_ret
; 23: a TCP socket
asm_1_5940_n_nt_sock:
            ld hl, #0600            ; (domain 0, type 0, protocol 6: TCP)
            ld (asm_1_5940_n_nt_pk + 4), hl
            xor a
            ld (asm_1_5940_n_nt_pk + 3), a
            ld a, 5
            ld hl, #4331            ; C_NETSOCKET
            call asm_1_5940_n_nt_hdr
            call asm_1_5940_n_nt_go
            ld a, (asm_1_5940_n_sv_tmp + 3)
            cp asm_1_5940_n_NT_N
            jp nc, asm_1_5940_n_nt_sk1
            ld e, a
            ld d, 0
            ld hl, asm_1_5940_n_nt_own
            add hl, de
            ld a, (var_hyp_svc_t)
            ld (hl), a
            jp asm_1_5940_n_nt_ans
asm_1_5940_n_nt_sk1:
            cp 255
            jp z, asm_1_5940_n_nt_ret
            call asm_1_5940_n_nt_close           ; (one this can't keep: closed)
            ld a, 255
            jp asm_1_5940_n_nt_ret
; 24: connected to an IP address and port
asm_1_5940_n_nt_conn:
            ld hl, asm_1_5940_n_sv_blk + 1
            ld de, asm_1_5940_n_nt_pk + 3
            ld bc, 7
            ldir
            ld a, 9
            ld hl, #4332            ; C_NETCONNECT
            call asm_1_5940_n_nt_hdr
            call asm_1_5940_n_nt_go
            jp asm_1_5940_n_nt_ans
; 25: bytes sent
asm_1_5940_n_nt_send:
            ld a, 4                 ; the network indicator: blink for the next ~2s (4 x 0.5s)
            ld (var_hyp_nta), a
            ld hl, (asm_1_5940_n_sv_blk + 4)
            ld a, h
            or a
            jp nz, asm_1_5940_n_sv_err
            ld a, l
            or a
            jp z, asm_1_5940_n_sv_err
            cp 241
            jp nc, asm_1_5940_n_sv_err
            ld (asm_1_5940_n_nt_pk + 4), hl
            ld a, (asm_1_5940_n_sv_blk + 1)
            ld (asm_1_5940_n_nt_pk + 3), a
            ld b, h
            ld c, l
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld de, asm_1_5940_n_nt_pk + 6
            call asm_1_5940_n_sv_in
            ld a, (asm_1_5940_n_sv_blk + 4)
            add a, 5
            ld hl, #4334            ; C_NETSEND
            call asm_1_5940_n_nt_hdr
            call asm_1_5940_n_nt_go
            jp asm_1_5940_n_nt_ans
; 26: bytes received
asm_1_5940_n_nt_recv:
            ld a, 4                 ; the network indicator: blink for the next ~2s (4 x 0.5s)
            ld (var_hyp_nta), a
            ld hl, (asm_1_5940_n_sv_blk + 4)
            ld de, 2049
            or a
            sbc hl, de
            jp nc, asm_1_5940_n_sv_err
            ld hl, (asm_1_5940_n_sv_blk + 4)
            ld (asm_1_5940_n_nt_pk + 4), hl
            ld a, (asm_1_5940_n_sv_blk + 1)
            ld (asm_1_5940_n_nt_pk + 3), a
            ld a, 5
            ld hl, #4335            ; C_NETRECV
            call asm_1_5940_n_nt_hdr
            call asm_1_5940_n_nt_go
            ld hl, 0
            ld a, (asm_1_5940_n_sv_tmp + 3)
            or a
            jr nz, asm_1_5940_n_nt_rc1
            ld hl, (asm_1_5940_n_sv_tmp + 4)     ; how many (no more than asked for)
            ld de, (asm_1_5940_n_sv_blk + 4)
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_5940_n_nt_rc0
            ex de, hl
asm_1_5940_n_nt_rc0:
            ld (asm_1_5940_n_sv_n), hl
            push hl
            ld hl, (asm_1_5940_n_nt_rsp)         ; from the M4's ROM to the slot
            ld de, 6
            add hl, de
            ld (asm_1_5940_n_sv_sa), hl
            ld a, (asm_1_5940_n_nt_rom)
            ld (asm_1_5940_n_sv_ss), a
            ld a, 3
            ld (asm_1_5940_n_sv_sk), a
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld (asm_1_5940_n_sv_da), hl
            xor a
            ld (asm_1_5940_n_sv_stop), a
            call asm_1_5940_n_sv_copy
            pop hl
asm_1_5940_n_nt_rc1:
            ld (asm_1_5940_n_sv_tmp + 4), hl     ; how many: to the request's Word(6)
            ld hl, (var_hyp_svc_p)
            ld de, 6
            add hl, de
            ex de, hl
            ld hl, asm_1_5940_n_sv_tmp + 4
            ld bc, 2
            call asm_1_5940_n_sv_out
            jp asm_1_5940_n_nt_ans
; nt_chk - Byte(1): a socket of this slot's (else the request fails)
asm_1_5940_n_nt_chk:
            ld a, (asm_1_5940_n_sv_blk + 1)
            cp asm_1_5940_n_NT_N
            jp nc, asm_1_5940_n_nt_chk1
            ld e, a
            ld d, 0
            ld hl, asm_1_5940_n_nt_own
            add hl, de
            ld a, (var_hyp_svc_t)
            cp (hl)
            ret z
            jp asm_1_5940_n_sv_err
asm_1_5940_n_nt_chk1:
            cp 255                  ; (255: the lookup's - 22 only)
            jp nz, asm_1_5940_n_sv_err
            ld a, b
            cp 22
            ret z
            jp asm_1_5940_n_sv_err
; nt_close - socket A closed (no longer anyone's)
asm_1_5940_n_nt_close:
    IFDEF NTC_MSXDOS
            jp asm_1_5940_n_es_close             ; zxn: the ESP's link
    ENDIF
            ld (asm_1_5940_n_nt_pk + 3), a
            cp asm_1_5940_n_NT_N
            jr nc, asm_1_5940_n_nt_cl1
            ld e, a
            ld d, 0
            ld hl, asm_1_5940_n_nt_own
            add hl, de
            ld (hl), 0
asm_1_5940_n_nt_cl1:
            ld a, 3
            ld hl, #4333            ; C_NETCLOSE
            call asm_1_5940_n_nt_hdr
; nt_go - the packet at nt_pk to the M4 (its size first); the answer's first 8 bytes to sv_tmp
asm_1_5940_n_nt_go:
            ld hl, asm_1_5940_n_nt_pk
            ld bc, #FE00
            ld d, (hl)
            inc d
asm_1_5940_n_nt_go1:
            inc b
            outi
            dec d
            jr nz, asm_1_5940_n_nt_go1
            ld bc, #FC00
            out (c), c
            ld hl, (asm_1_5940_n_nt_rsp)
            ld de, asm_1_5940_n_sv_tmp
            ld bc, 8
; nt_rd - BC bytes of the M4's ROM from HL to DE (here)
asm_1_5940_n_nt_rd:
            push hl
            push de
            push bc
            ld a, (asm_1_5940_n_nt_rom)
            ld c, a
            call #B90F              ; KL ROM SELECT
            di
            ld (asm_1_5940_n_nt_old), bc
            pop bc
            pop de
            pop hl
            ld a, h
            or #C0
            ld h, a
            ldir
            ld bc, (asm_1_5940_n_nt_old)
            call #B918              ; KL ROM DESELECT
            di
            ret
; nt_hdr - the packet's size A, its command HL
asm_1_5940_n_nt_hdr:
            ld (asm_1_5940_n_nt_pk), a
            ld (asm_1_5940_n_nt_pk + 1), hl
            ret
; nt_ent - socket A's 16 bytes in the M4's table: HL (255: the first - the lookup's)
asm_1_5940_n_nt_ent:
            cp 255
            jr nz, asm_1_5940_n_nt_e1
            xor a
asm_1_5940_n_nt_e1:
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, (asm_1_5940_n_nt_skt)
            add hl, de
            ret
; nt_m4c - the claim on M4 0 held by C (255 CyborgOS, 0 given back)
asm_1_5940_n_nt_m4c:
            push bc
            ld hl, asm_1_5940_n_sv_blk + 1
            ld (hl), 0
            inc hl
            ld (hl), 'M'
            inc hl
            ld (hl), '4'
            ld b, 6
asm_1_5940_n_nt_m4c1:
            inc hl
            ld (hl), ' '
            djnz asm_1_5940_n_nt_m4c1
            call asm_1_5940_n_cl_find
            pop bc
            jr nz, asm_1_5940_n_nt_m4c2
            ld (hl), c              ; (CyborgOS's now - or no one's)
            ret
asm_1_5940_n_nt_m4c2:
            ld a, c
            or a
            ret z
            ld hl, asm_1_5940_n_sv_cl            ; into a free record
            ld de, 10
            ld b, asm_1_5940_n_CL_N
asm_1_5940_n_nt_m4c3:
            ld a, (hl)
            or a
            jr z, asm_1_5940_n_nt_m4c4
            add hl, de
            djnz asm_1_5940_n_nt_m4c3
            ret
asm_1_5940_n_nt_m4c4:
            ld (hl), c
            inc hl
            ex de, hl
            ld hl, asm_1_5940_n_sv_blk + 1
            ld bc, 9
            ldir
            ret
; sv_in - BC bytes from the slot's HL to DE (here, in the service page)
asm_1_5940_n_sv_in:
            ld (asm_1_5940_n_sv_sa), hl
            ld (asm_1_5940_n_sv_da), de
            ld (asm_1_5940_n_sv_n), bc
            ld a, 2
            ld (asm_1_5940_n_sv_sk), a
            ld hl, (var_hyp_svc_setting)
            ld (asm_1_5940_n_sv_ss), hl
            ld a, 1
            ld (asm_1_5940_n_sv_dk), a
            ld hl, (var_hyp_svp)
            ld (asm_1_5940_n_sv_ds), hl
            xor a
            ld (asm_1_5940_n_sv_stop), a
            call asm_1_5940_n_sv_copy
            ld a, 2                 ; (the copies to the slot again)
            ld (asm_1_5940_n_sv_dk), a
            ld hl, (var_hyp_svc_setting)
            ld (asm_1_5940_n_sv_ds), hl
            ret
    IFDEF NTC_MSXDOS
; ---- the Next's network: its ESP8266 wifi on the UART (#133B: write a byte / read the status - bit 0
; a byte waiting, bit 1 the send buffer full; #143B: read a byte / write the speed; #153B: which
; UART - 0 the ESP). Its AT firmware does TCP/IP; CyborgOS gives programs the same ops 20-27 as on
; the CPC's M4, so Http.cls, NET, IPCONFIG, NETSTAT ... run unchanged. Passive receive
; (AT+CIPRECVMODE=1): the ESP keeps what comes in until asked (AT+CIPRECVDATA), and says only
; +IPD,n,len and n,CLOSED on its own - a few bytes, so the UART's 512 never overflow. One AT
; command at a time: the slow ones (a name looked up, a connect, a send) go on in the background -
; es_pump, run by every network op, reads what the ESP has said and moves them on (a program
; waiting on a socket's state asks often); the quick ones (a receive, the details) are waited
; for here. Links 0-4 are sockets 0-4; es_tab: 8 bytes a link and the lookup's (5) - the state
; (0 ready, 1 connecting, 2 sending, 3 closed, 5 looking up, 255 failed), the bytes waiting (a
; word), the IP. Never AT+CIPSERVER: nothing listens.
asm_1_5940_n_ES_TX:      equ #133B
asm_1_5940_n_ES_RX:      equ #143B
asm_1_5940_n_ES_SEL:     equ #153B
asm_1_5940_n_ES_NL:      equ 5                   ; links (sockets) 0-4
asm_1_5940_n_es_net:
            ld b, a                 ; MSX: no network yet (the GR8NET's TCP/IP UNAPI to come) - 20/0
            cp 20                   ; says off, the rest of 20 / 21-27 an error. The ESP's code below
            jp nz, asm_1_5940_n_sv_err           ; isn't reached
            ld a, (asm_1_5940_n_sv_blk + 1)
            or a
            jr z, asm_1_5940_n_es_n0
            jp asm_1_5940_n_sv_err
            ld a, (asm_1_5940_n_sv_blk + 1)
            cp 1
            jp z, asm_1_5940_n_es_init
            cp 2
            jp z, asm_1_5940_n_es_off
            cp 8
            jp z, asm_1_5940_n_es_info
            cp 9
            jp z, asm_1_5940_n_es_set
            cp 10
            jp z, asm_1_5940_n_es_list
            jp asm_1_5940_n_nt_20a               ; (3-7: the clock, the host ... - not the network's)
asm_1_5940_n_es_n0:
            ld a, (asm_1_5940_n_nt_rom)          ; 0: 255 off, else on
            jp asm_1_5940_n_nt_ret
asm_1_5940_n_es_n1:
            ld a, (asm_1_5940_n_nt_rom)
            inc a
            jp z, asm_1_5940_n_sv_err            ; (no network)
            call asm_1_5940_n_es_pump
            ld a, (asm_1_5940_n_sv_blk)          ; (the op again: es_pump used B)
            ld b, a
            cp 21
            jp z, asm_1_5940_n_es_look
            cp 23
            jp z, asm_1_5940_n_es_sock
            call asm_1_5940_n_nt_chk             ; (the rest: one of the slot's sockets)
            ld a, b
            cp 22
            jp z, asm_1_5940_n_es_stat
            cp 24
            jp z, asm_1_5940_n_es_conn
            cp 25
            jp z, asm_1_5940_n_es_send
            cp 26
            jp z, asm_1_5940_n_es_recv
            ld a, (asm_1_5940_n_sv_blk + 1)      ; 27
            call asm_1_5940_n_nt_close
            jp asm_1_5940_n_sv_ok

; 20/1: on - the ESP's UART chosen, 115200 from the video timing's clock, then AT, ATE0, every
; link closed, AT+CIPMUX=1, AT+CIPRECVMODE=1 (a firmware without passive receive: not on)
asm_1_5940_n_es_init:
            ld a, (asm_1_5940_n_nt_rom)
            inc a
            jp nz, asm_1_5940_n_sv_ok            ; (on already)
            ld bc, asm_1_5940_n_ES_SEL
            xor a
            out (c), a              ; the ESP's UART
            ld bc, #243B
            ld a, #11
            out (c), a
            inc b
            in a, (c)               ; the video timing: its clock
            and 7
            add a, a
            ld e, a
            ld d, 0
            ld hl, asm_1_5940_n_es_baud
            add hl, de
            ld e, (hl)
            inc hl
            ld d, (hl)              ; DE = clock / 115200
            ld bc, asm_1_5940_n_ES_RX
            ld a, e
            and #7F
            out (c), a              ; its low 7 bits
            sla e
            rl d
            ld a, d
            and #7F
            or #80
            out (c), a              ; the next 7
            call asm_1_5940_n_es_flush
            xor a
            ld (asm_1_5940_n_es_busy), a
            ld hl, asm_1_5940_n_es_tab
            ld b, 48
asm_1_5940_n_es_i0:
            ld (hl), a
            inc hl
            djnz asm_1_5940_n_es_i0
            ld hl, asm_1_5940_n_es_s_at          ; AT (twice: the first may meet half a line)
            call asm_1_5940_n_es_sync
            ld hl, asm_1_5940_n_es_s_at
            call asm_1_5940_n_es_sync
            jr nz, asm_1_5940_n_es_ifail
            ld hl, asm_1_5940_n_es_s_e0
            call asm_1_5940_n_es_sync
            ld hl, asm_1_5940_n_es_s_cl5
            call asm_1_5940_n_es_sync            ; (every link closed: an error is all right)
            ld hl, asm_1_5940_n_es_s_mux
            call asm_1_5940_n_es_sync
            jr nz, asm_1_5940_n_es_ifail
            ld hl, asm_1_5940_n_es_s_rcv
            call asm_1_5940_n_es_sync
            jr nz, asm_1_5940_n_es_ifail
            xor a
            ld (asm_1_5940_n_nt_rom), a          ; on (0: the ESP, as the M4's ROM number would be)
            inc a
            ld (var_hyp_ntu), a           ; the network indicator: up
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_es_ifail:
            ld a, 1
            jp asm_1_5940_n_nt_ret
asm_1_5940_n_es_baud:    dw 243, 248, 256, 260, 269, 278, 286, 234   ; 28.0 28.57 29.46 30 31 32 33 27 MHz / 115200

; 20/2: off - every link closed
asm_1_5940_n_es_off:
            ld a, (asm_1_5940_n_nt_rom)
            inc a
            jp z, asm_1_5940_n_sv_ok
            call asm_1_5940_n_es_idle
            ld hl, asm_1_5940_n_es_s_cl5
            call asm_1_5940_n_es_sync
            ld hl, asm_1_5940_n_nt_own
            ld b, asm_1_5940_n_NT_N
asm_1_5940_n_es_o1:
            ld (hl), 0
            inc hl
            djnz asm_1_5940_n_es_o1
            ld a, 255
            ld (asm_1_5940_n_nt_rom), a
            xor a
            ld (var_hyp_ntu), a
            jp asm_1_5940_n_sv_ok

; 21: a name looked up (Word(2), Byte(4) its length): AT+CIPDOMAIN="name" - 1: started (22 with
; 255: 5 looking, 0 found, its IP at +4; 255 not found)
asm_1_5940_n_es_look:
            ld a, (asm_1_5940_n_sv_blk + 4)
            cp 64
            jp nc, asm_1_5940_n_sv_err
            ld c, a
            ld b, 0
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld de, asm_1_5940_n_nt_pk
            push bc
            call asm_1_5940_n_sv_in
            pop bc
            ld hl, asm_1_5940_n_nt_pk
            add hl, bc
            ld (hl), 0
            call asm_1_5940_n_es_idle
            jp nz, asm_1_5940_n_sv_err
            ld hl, asm_1_5940_n_es_s_dom
            call asm_1_5940_n_es_puts
            ld hl, asm_1_5940_n_nt_pk
            call asm_1_5940_n_es_puts
            ld a, '"'
            call asm_1_5940_n_es_put
            call asm_1_5940_n_es_crlf
            ld a, 5
            ld (asm_1_5940_n_es_tab + 40), a     ; the lookup's: looking
            ld a, 5
            ld (asm_1_5940_n_es_bl), a
            ld a, 2
            call asm_1_5940_n_es_start
            ld a, 1
            jp asm_1_5940_n_nt_ret

; 22: socket Byte(1)'s 16 bytes to Word(2) (255: the lookup's) - its state
asm_1_5940_n_es_stat:
            ld a, (asm_1_5940_n_sv_blk + 1)
            call asm_1_5940_n_es_ent
            ld de, asm_1_5940_n_sv_tmp
            ld bc, 8
            ldir
            ld hl, asm_1_5940_n_sv_tmp + 8
            ld b, 8
asm_1_5940_n_es_st1:
            ld (hl), 0
            inc hl
            djnz asm_1_5940_n_es_st1
            ld hl, asm_1_5940_n_sv_tmp
            ld de, (asm_1_5940_n_sv_blk + 2)
            ld bc, 16
            call asm_1_5940_n_sv_out
            ld a, (asm_1_5940_n_sv_tmp)
            jp asm_1_5940_n_nt_ret

; 23: a socket: a free link (255 none)
asm_1_5940_n_es_sock:
            ld hl, asm_1_5940_n_nt_own
            ld b, 0
asm_1_5940_n_es_sk1:
            ld a, (hl)
            or a
            jr z, asm_1_5940_n_es_sk2
            inc hl
            inc b
            ld a, b
            cp asm_1_5940_n_ES_NL
            jr c, asm_1_5940_n_es_sk1
            ld a, 255
            jp asm_1_5940_n_nt_ret
asm_1_5940_n_es_sk2:
            ld a, (var_hyp_svc_t)
            ld (hl), a              ; the slot's now
            ld a, b
            ld (asm_1_5940_n_sv_tmp), a
            call asm_1_5940_n_es_ent
            ld b, 8
asm_1_5940_n_es_sk3:
            ld (hl), 0
            inc hl
            djnz asm_1_5940_n_es_sk3
            ld a, (asm_1_5940_n_sv_tmp)
            jp asm_1_5940_n_nt_ret

; 24: socket Byte(1) connected to IP Byte(2-5), port Word(6): AT+CIPSTART=n,"TCP","a.b.c.d",port
asm_1_5940_n_es_conn:
            call asm_1_5940_n_es_idle
            jp nz, asm_1_5940_n_sv_err
            ld a, (asm_1_5940_n_sv_blk + 1)
            call asm_1_5940_n_es_ent
            push hl
            ld (hl), 1              ; connecting
            ld de, 4
            add hl, de
            ex de, hl
            ld hl, asm_1_5940_n_sv_blk + 2       ; its IP kept (NETSTAT)
            ld bc, 4
            ldir
            pop hl
            ld hl, asm_1_5940_n_es_s_start
            call asm_1_5940_n_es_puts
            ld a, (asm_1_5940_n_sv_blk + 1)
            add a, '0'
            call asm_1_5940_n_es_put
            ld hl, asm_1_5940_n_es_s_tcp
            call asm_1_5940_n_es_puts
            ld b, 4
            ld hl, asm_1_5940_n_sv_blk + 2
asm_1_5940_n_es_c1:
            push bc
            push hl
            ld l, (hl)
            ld h, 0
            call asm_1_5940_n_es_putdec
            pop hl
            pop bc
            inc hl
            ld a, b
            cp 1
            ld a, '.'
            call nz, asm_1_5940_n_es_put
            djnz asm_1_5940_n_es_c1
            ld a, '"'
            call asm_1_5940_n_es_put
            ld a, ','
            call asm_1_5940_n_es_put
            ld hl, (asm_1_5940_n_sv_blk + 6)
            call asm_1_5940_n_es_putdec
            call asm_1_5940_n_es_crlf
            ld a, (asm_1_5940_n_sv_blk + 1)
            ld (asm_1_5940_n_es_bl), a
            ld a, 3
            call asm_1_5940_n_es_start
            jp asm_1_5940_n_sv_ok

; 25: Word(4) bytes (1-240) from Word(2) sent on socket Byte(1): AT+CIPSEND=n,len, then (es_pump)
; the data at the ESP's > and SEND OK - the state 2 meanwhile
asm_1_5940_n_es_send:
            ld hl, (asm_1_5940_n_sv_blk + 4)
            ld a, h
            or a
            jp nz, asm_1_5940_n_sv_err
            ld a, l
            or a
            jp z, asm_1_5940_n_sv_err
            cp 241
            jp nc, asm_1_5940_n_sv_err
            call asm_1_5940_n_es_idle
            jp nz, asm_1_5940_n_sv_err
            ld bc, (asm_1_5940_n_sv_blk + 4)
            ld (asm_1_5940_n_es_sl), bc
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld de, asm_1_5940_n_nt_pk
            call asm_1_5940_n_sv_in
            ld a, (asm_1_5940_n_sv_blk + 1)
            call asm_1_5940_n_es_ent
            ld (hl), 2              ; sending
            ld hl, asm_1_5940_n_es_s_send
            call asm_1_5940_n_es_puts
            ld a, (asm_1_5940_n_sv_blk + 1)
            add a, '0'
            call asm_1_5940_n_es_put
            ld a, ','
            call asm_1_5940_n_es_put
            ld hl, (asm_1_5940_n_es_sl)
            call asm_1_5940_n_es_putdec
            call asm_1_5940_n_es_crlf
            ld a, (asm_1_5940_n_sv_blk + 1)
            ld (asm_1_5940_n_es_bl), a
            ld a, 4
            call asm_1_5940_n_es_start
            jp asm_1_5940_n_sv_ok

; 26: up to Word(4) bytes of socket Byte(1)'s to Word(2) - how many to the request's Word(6). The
; ESP has them (passive): AT+CIPRECVDATA=n,len, its answer +CIPRECVDATA,len:data (or
; +CIPRECVDATA:len,data) waited for here - 160 at most a call (14 ms at 115200: within a frame)
asm_1_5940_n_es_recv:
            ld hl, 0
            ld (asm_1_5940_n_es_rn), hl
            ld a, (asm_1_5940_n_sv_blk + 1)
            call asm_1_5940_n_es_ent
            inc hl
            inc hl
            ld a, (hl)
            inc hl
            or (hl)
            jp z, asm_1_5940_n_es_r9             ; (nothing waiting)
            call asm_1_5940_n_es_idle
            jp nz, asm_1_5940_n_es_r9            ; (the ESP busy: none this time)
            ld hl, (asm_1_5940_n_sv_blk + 4)
            ld de, 161
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_5940_n_es_r1
            ld hl, 160
asm_1_5940_n_es_r1:
            ld a, h
            or l
            jp z, asm_1_5940_n_es_r9
            push hl
            ld hl, asm_1_5940_n_es_s_rdat
            call asm_1_5940_n_es_puts
            ld a, (asm_1_5940_n_sv_blk + 1)
            add a, '0'
            call asm_1_5940_n_es_put
            ld a, ','
            call asm_1_5940_n_es_put
            pop hl
            call asm_1_5940_n_es_putdec
            call asm_1_5940_n_es_crlf
            ld a, 7                 ; (7: a receive - es_line hands its data line here)
            ld (asm_1_5940_n_es_busy), a
            ld hl, 0
            ld (asm_1_5940_n_es_rn), hl
            call msx_t300
            ld (asm_1_5940_n_es_t0), hl
            call asm_1_5940_n_es_now
            ld (asm_1_5940_n_es_f0), hl
asm_1_5940_n_es_r2:
            call asm_1_5940_n_es_pump            ; until its OK (es_busy 0) - 2 s at most
            ld a, (asm_1_5940_n_es_busy)
            or a
            jr z, asm_1_5940_n_es_r3
            call asm_1_5940_n_es_since
            ld de, 100
            or a
            sbc hl, de
            jr c, asm_1_5940_n_es_r2
            xor a
            ld (asm_1_5940_n_es_busy), a
asm_1_5940_n_es_r3:
            ld hl, (asm_1_5940_n_es_rn)          ; how many came
            ld (asm_1_5940_n_es_rn), hl
            ld a, h
            or l
            jr z, asm_1_5940_n_es_r4
            push hl
            ld b, h
            ld c, l
            ld hl, asm_1_5940_n_nt_pk
            ld de, (asm_1_5940_n_sv_blk + 2)
            call asm_1_5940_n_sv_out
            pop bc
asm_1_5940_n_es_r4:
            ld a, (asm_1_5940_n_sv_blk + 1)      ; the bytes waiting less those
            call asm_1_5940_n_es_ent
            inc hl
            inc hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ex de, hl
            ld bc, (asm_1_5940_n_es_rn)
            ld a, b
            or c
            jr z, asm_1_5940_n_es_r5             ; (none came: none waiting)
            or a
            sbc hl, bc
            jr nc, asm_1_5940_n_es_r6
asm_1_5940_n_es_r5:
            ld hl, 0
asm_1_5940_n_es_r6:
            ex de, hl
            ld (hl), d
            dec hl
            ld (hl), e
asm_1_5940_n_es_r9:
            ld hl, (asm_1_5940_n_es_rn)
            ld (asm_1_5940_n_sv_tmp + 4), hl     ; how many: to the request's Word(6)
            ld hl, (var_hyp_svc_p)
            ld de, 6
            add hl, de
            ex de, hl
            ld hl, asm_1_5940_n_sv_tmp + 4
            ld bc, 2
            call asm_1_5940_n_sv_out
            jp asm_1_5940_n_sv_ok

; 20/8: the details (IPCONFIG) - 64 bytes to Word(2), as the CPC's: AT+CWJAP_CUR? (the network's
; name, the signal), AT+CIPSTA_CUR? (the IP, gateway, netmask), AT+CIPSTAMAC_CUR? (the MAC)
asm_1_5940_n_es_info:
            ld hl, asm_1_5940_n_nt_pk + 192
            ld b, 64
asm_1_5940_n_es_fz:
            ld (hl), 0
            inc hl
            djnz asm_1_5940_n_es_fz
            ld a, 255
            ld (asm_1_5940_n_nt_pk + 193), a
            ld a, (asm_1_5940_n_nt_rom)
            inc a
            jr z, asm_1_5940_n_es_f9
            ld a, 1
            ld (asm_1_5940_n_nt_pk + 192), a     ; on
            call asm_1_5940_n_es_idle
            jr nz, asm_1_5940_n_es_f9
            ld a, 1
            ld (asm_1_5940_n_es_cap), a          ; (lines starting +CWJAP / +CIPSTA: es_capl)
            ld hl, asm_1_5940_n_es_s_jap
            call asm_1_5940_n_es_sync
            ld hl, asm_1_5940_n_es_s_sta
            call asm_1_5940_n_es_sync
            ld hl, asm_1_5940_n_es_s_mac
            call asm_1_5940_n_es_sync
            xor a
            ld (asm_1_5940_n_es_cap), a
asm_1_5940_n_es_f9:
            ld hl, asm_1_5940_n_nt_pk + 192
            ld de, (asm_1_5940_n_sv_blk + 2)
            ld bc, 64
            call asm_1_5940_n_sv_out
            ld a, (asm_1_5940_n_nt_pk + 192)
            jp asm_1_5940_n_nt_ret

; 20/9: the network joined - Word(2), Byte(4): name,password -> AT+CWJAP_DEF="name","password"
; (kept by the ESP; in the background: IPCONFIG shows it when joined)
asm_1_5940_n_es_set:
            ld a, (asm_1_5940_n_sv_blk + 4)
            cp 100
            jp nc, asm_1_5940_n_sv_err
            ld c, a
            ld b, 0
            ld hl, (asm_1_5940_n_sv_blk + 2)
            ld de, asm_1_5940_n_nt_pk
            push bc
            call asm_1_5940_n_sv_in
            pop bc
            ld hl, asm_1_5940_n_nt_pk
            add hl, bc
            ld (hl), 0
            call asm_1_5940_n_es_idle
            jp nz, asm_1_5940_n_sv_err
            ld hl, asm_1_5940_n_es_s_join
            call asm_1_5940_n_es_puts
            ld hl, asm_1_5940_n_nt_pk
asm_1_5940_n_es_j1:
            ld a, (hl)
            or a
            jr z, asm_1_5940_n_es_j2
            cp ','
            jr nz, asm_1_5940_n_es_j3
            ld a, '"'
            call asm_1_5940_n_es_put
            ld a, ','
            call asm_1_5940_n_es_put
            ld a, '"'
asm_1_5940_n_es_j3:
            call asm_1_5940_n_es_put
            inc hl
            jr asm_1_5940_n_es_j1
asm_1_5940_n_es_j2:
            ld a, '"'
            call asm_1_5940_n_es_put
            call asm_1_5940_n_es_crlf
            ld a, 1
            call asm_1_5940_n_es_start
            jp asm_1_5940_n_sv_ok

; 20/10: the sockets (NETSTAT) - 8 bytes each to Word(2): the slot, the state, the bytes
; waiting, the IP - A how many in use
asm_1_5940_n_es_list:
            ld hl, asm_1_5940_n_nt_pk + 192
            ld b, 64
asm_1_5940_n_es_l0:
            ld (hl), 0
            inc hl
            djnz asm_1_5940_n_es_l0
            ld c, 0
            ld a, (asm_1_5940_n_nt_rom)
            inc a
            jr z, asm_1_5940_n_es_l9
            ld b, 0
asm_1_5940_n_es_l1:
            push bc
            ld hl, asm_1_5940_n_nt_own
            ld e, b
            ld d, 0
            add hl, de
            ld a, (hl)
            or a
            jr z, asm_1_5940_n_es_l2
            ld l, b
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, asm_1_5940_n_nt_pk + 192
            add hl, de
            ld (hl), a              ; the slot
            inc hl
            push hl
            ld a, b
            call asm_1_5940_n_es_ent
            pop de
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
asm_1_5940_n_es_l2:
            pop bc
            inc b
            ld a, b
            cp asm_1_5940_n_ES_NL
            jr c, asm_1_5940_n_es_l1
asm_1_5940_n_es_l9:
            ld a, c
            ld (asm_1_5940_n_sv_tmp), a
            ld hl, asm_1_5940_n_nt_pk + 192
            ld de, (asm_1_5940_n_sv_blk + 2)
            ld bc, 64
            call asm_1_5940_n_sv_out
            ld a, (asm_1_5940_n_sv_tmp)
            jp asm_1_5940_n_nt_ret

; es_close - link A closed (nt_close's, on the Next): no longer anyone's; AT+CIPCLOSE=n if it was
; connected (in the background)
asm_1_5940_n_es_close:
            cp asm_1_5940_n_ES_NL
            ret nc
            ld c, a
            ld e, a
            ld d, 0
            ld hl, asm_1_5940_n_nt_own
            add hl, de
            ld (hl), 0
            ld a, c
            call asm_1_5940_n_es_ent
            ld a, (hl)
            ld (hl), 0
            inc hl
            ld (hl), 0
            inc hl
            ld (hl), 0
            inc hl
            ld (hl), 0
            cp 3
            ret z                   ; (closed already)
            ld a, (asm_1_5940_n_nt_rom)
            inc a
            ret z
            push bc
            call asm_1_5940_n_es_idle
            pop bc
            ret nz
            ld hl, asm_1_5940_n_es_s_close
            call asm_1_5940_n_es_puts
            ld a, c
            add a, '0'
            call asm_1_5940_n_es_put
            call asm_1_5940_n_es_crlf
            ld a, 6
            jp asm_1_5940_n_es_start

; ---- the ESP's talk
; es_start - a command sent (kind A: 1 OK / ERROR awaited, 2 a lookup, 3 a connect, 4 a send's >,
; 6 a close): in flight from now (es_pump moves it on); its clock started
asm_1_5940_n_es_start:
            ld (asm_1_5940_n_es_busy), a
            call msx_t300
            ld (asm_1_5940_n_es_t0), hl
            ret
; es_now - HL = frames counted from the raster (a service runs with interrupts off: the clock
; stands still, so a wait here counts the raster's returns to its top - called often enough to see
; each: every wait below calls it each time round)
asm_1_5940_n_es_now:
            push bc
            push de
            ld bc, #243B
asm_1_5940_n_es_nw1:
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
            jr nz, asm_1_5940_n_es_nw1
            and 1
            ld d, a                 ; DE = the line now
            ld hl, (asm_1_5940_n_es_lln)
            ld (asm_1_5940_n_es_lln), de
            or a
            sbc hl, de
            jr c, asm_1_5940_n_es_nw2
            jr z, asm_1_5940_n_es_nw2
            ld hl, (asm_1_5940_n_es_frm)         ; (lower than before: a new frame)
            inc hl
            ld (asm_1_5940_n_es_frm), hl
asm_1_5940_n_es_nw2:
            ld hl, (asm_1_5940_n_es_frm)
            pop de
            pop bc
            ret
; es_since - HL = frames since es_f0
asm_1_5940_n_es_since:
            call asm_1_5940_n_es_now
            ld de, (asm_1_5940_n_es_f0)
            or a
            sbc hl, de
            ret
; es_idle - NZ when a command is still in flight after waiting (0.3 s) for it
asm_1_5940_n_es_idle:
            call asm_1_5940_n_es_now
            ld (asm_1_5940_n_es_f0), hl
asm_1_5940_n_es_id1:
            call asm_1_5940_n_es_pump
            ld a, (asm_1_5940_n_es_busy)
            or a
            ret z
            call asm_1_5940_n_es_since
            ld de, 15
            or a
            sbc hl, de
            jr c, asm_1_5940_n_es_id1
            or 1
            ret
; es_sync - command HL sent, its OK / ERROR waited for (1 s): Z when OK
asm_1_5940_n_es_sync:
            call asm_1_5940_n_es_puts
            call asm_1_5940_n_es_crlf
            ld a, 1
            call asm_1_5940_n_es_start
            call asm_1_5940_n_es_now
            ld (asm_1_5940_n_es_f0), hl
asm_1_5940_n_es_sy1:
            call asm_1_5940_n_es_pump
            ld a, (asm_1_5940_n_es_busy)
            or a
            jr z, asm_1_5940_n_es_sy2
            call asm_1_5940_n_es_since
            ld de, 50
            or a
            sbc hl, de
            jr c, asm_1_5940_n_es_sy1
            xor a
            ld (asm_1_5940_n_es_busy), a
            or 1
            ret
asm_1_5940_n_es_sy2:
            ld a, (asm_1_5940_n_es_res)
            or a
            ret
; es_pump - what the ESP has said read: lines (es_line); a send's > (its data sent); a
; receive's data (es_busy 7: the count after +CIPRECVDATA, then that many bytes); and a command
; that has waited 15 s given up
asm_1_5940_n_es_pump:
            ld a, (asm_1_5940_n_es_busy)
            or a
            jr z, asm_1_5940_n_es_pu1
            call msx_t300
            ld de, (asm_1_5940_n_es_t0)
            or a
            sbc hl, de
            ld de, 4500
            or a
            sbc hl, de
            jr c, asm_1_5940_n_es_pu1
            call asm_1_5940_n_es_fail            ; (15 s: no answer)
asm_1_5940_n_es_pu1:
            ld bc, asm_1_5940_n_ES_TX
            in a, (c)
            and 1
            ret z
            ld bc, asm_1_5940_n_ES_RX
            in a, (c)
            ld c, a
            ld a, (asm_1_5940_n_es_busy)
            cp 4
            jr nz, asm_1_5940_n_es_pu2
            ld a, c
            cp '>'
            jr nz, asm_1_5940_n_es_pu2
            call asm_1_5940_n_es_data            ; the send's data, now
            jr asm_1_5940_n_es_pu1
asm_1_5940_n_es_pu2:
            ld a, c
            cp 13
            jr z, asm_1_5940_n_es_pu1
            cp 10
            jr z, asm_1_5940_n_es_pu4
            ld hl, asm_1_5940_n_es_lp
            ld e, (hl)
            ld a, e
            cp 95
            jr nc, asm_1_5940_n_es_pu1
            inc (hl)
            ld d, 0
            ld hl, asm_1_5940_n_es_ln
            add hl, de
            ld (hl), c
            inc hl
            ld (hl), 0
            ld a, (asm_1_5940_n_es_busy)         ; a receive: +CIPRECVDATA,n: (or :n,) - the data follows now
            cp 7
            jr nz, asm_1_5940_n_es_pu1
            ld a, c
            cp ':'
            jr z, asm_1_5940_n_es_pu3
            cp ','
            jr nz, asm_1_5940_n_es_pu1
asm_1_5940_n_es_pu3:
            call asm_1_5940_n_es_rhead
            jr asm_1_5940_n_es_pu1
asm_1_5940_n_es_pu4:
            ld a, (asm_1_5940_n_es_lp)
            or a
            call nz, asm_1_5940_n_es_line
            xor a
            ld (asm_1_5940_n_es_lp), a
            ld (asm_1_5940_n_es_ln), a
            jr asm_1_5940_n_es_pu1
; es_rhead - in a receive, es_ln so far "+CIPRECVDATA,n:" or "+CIPRECVDATA:n," : n read, then
; that many bytes into nt_pk (es_rn)
asm_1_5940_n_es_rhead:
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_rdat
            call asm_1_5940_n_es_pfx
            ret nz
            ld a, (hl)              ; the count: after , or :
            cp ','
            jr z, asm_1_5940_n_es_rh1
            cp ':'
            ret nz
asm_1_5940_n_es_rh1:
            inc hl
            ld a, (hl)
            cp '0'
            ret c
            cp '9' + 1
            ret nc
            call asm_1_5940_n_es_num             ; DE = n, HL past it
            ld a, (hl)
            or a
            jr nz, asm_1_5940_n_es_rh2           ; (no separator yet: not all there)
            ret
asm_1_5940_n_es_rh2:
            ld a, (asm_1_5940_n_es_lp)           ; ("+CIPRECVDATA:n," ends with , ; ",n:" with : - the last character)
            dec a
            ld c, a
            ld b, 0
            push hl
            ld hl, asm_1_5940_n_es_ln
            add hl, bc
            ld a, (hl)
            pop hl
            ld b, a
            ld a, (asm_1_5940_n_es_ln + 12)      ; the character after +CIPRECVDATA
            cp ','
            jr nz, asm_1_5940_n_es_rh3
            ld a, b
            cp ':'
            ret nz
            jr asm_1_5940_n_es_rh4
asm_1_5940_n_es_rh3:
            ld a, b
            cp ','
            ret nz
asm_1_5940_n_es_rh4:
            ld hl, 160              ; (no more than asked: 160)
            or a
            sbc hl, de
            ret c
            ld (asm_1_5940_n_es_rn), de
            ld hl, asm_1_5940_n_nt_pk
asm_1_5940_n_es_rh5:
            ld a, d
            or e
            jr z, asm_1_5940_n_es_rh7
            push hl
            push de
            call asm_1_5940_n_es_now             ; (each byte waited for - 0.5 s)
            ld (asm_1_5940_n_es_f1), hl
            pop de
            pop hl
asm_1_5940_n_es_rh6:
            ld bc, asm_1_5940_n_ES_TX
            in a, (c)
            and 1
            jr nz, asm_1_5940_n_es_rh8
            push hl
            push de
            call asm_1_5940_n_es_now
            ld de, (asm_1_5940_n_es_f1)
            or a
            sbc hl, de
            ld de, 25
            or a
            sbc hl, de
            pop de
            pop hl
            jr c, asm_1_5940_n_es_rh6
            jr asm_1_5940_n_es_rh7
asm_1_5940_n_es_rh8:
            ld bc, asm_1_5940_n_ES_RX
            in a, (c)
            ld (hl), a
            inc hl
            dec de
            jr asm_1_5940_n_es_rh5
asm_1_5940_n_es_rh7:
            xor a
            ld (asm_1_5940_n_es_lp), a
            ld (asm_1_5940_n_es_ln), a
            ret
; es_data - the send's bytes (nt_pk, es_sl) to the ESP: then SEND OK awaited (5)
asm_1_5940_n_es_data:
            ld hl, asm_1_5940_n_nt_pk
            ld de, (asm_1_5940_n_es_sl)
asm_1_5940_n_es_da1:
            ld a, d
            or e
            jr z, asm_1_5940_n_es_da2
            ld a, (hl)
            call asm_1_5940_n_es_put
            inc hl
            dec de
            jr asm_1_5940_n_es_da1
asm_1_5940_n_es_da2:
            ld a, 5
            ld (asm_1_5940_n_es_busy), a
            ret
; es_line - a line the ESP said (es_ln, es_lp long)
asm_1_5940_n_es_line:
            ld a, (asm_1_5940_n_es_cap)          ; (IPCONFIG's: its lines first)
            or a
            call nz, asm_1_5940_n_es_capl
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_ok
            call asm_1_5940_n_es_pfz
            jp z, asm_1_5940_n_es_ok
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_sendok
            call asm_1_5940_n_es_pfz
            jp z, asm_1_5940_n_es_sendok
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_err
            call asm_1_5940_n_es_pfz
            jp z, asm_1_5940_n_es_err
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_fail
            call asm_1_5940_n_es_pfx
            jp z, asm_1_5940_n_es_err
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_sfail
            call asm_1_5940_n_es_pfz
            jp z, asm_1_5940_n_es_err
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_dom
            call asm_1_5940_n_es_pfx
            jp z, asm_1_5940_n_es_dom
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_ipd
            call asm_1_5940_n_es_pfx
            jp z, asm_1_5940_n_es_ipd
            ld a, (asm_1_5940_n_es_ln)           ; n,CONNECT / n,CLOSED / n,CONNECT FAIL
            sub '0'
            cp asm_1_5940_n_ES_NL
            ret nc
            ld c, a
            ld a, (asm_1_5940_n_es_ln + 1)
            cp ','
            ret nz
            ld hl, asm_1_5940_n_es_ln + 2
            ld de, asm_1_5940_n_es_k_conn
            call asm_1_5940_n_es_pfz
            jp z, asm_1_5940_n_es_lconn
            ld hl, asm_1_5940_n_es_ln + 2
            ld de, asm_1_5940_n_es_k_closed
            call asm_1_5940_n_es_pfz
            ret nz
            ld a, c                 ; closed: by the other end (or by us)
            call asm_1_5940_n_es_ent
            ld (hl), 3
            ret
asm_1_5940_n_es_lconn:
            ld a, c
            call asm_1_5940_n_es_ent
            ld (hl), 0              ; connected: ready
            ret
asm_1_5940_n_es_ok:
            ld a, (asm_1_5940_n_es_busy)
            cp 4
            ret z                   ; (a send: its > comes next)
            cp 5
            ret z                   ; (a send: SEND OK comes next)
            cp 7
            jr z, asm_1_5940_n_es_ok7
            cp 2
            jr nz, asm_1_5940_n_es_ok1
            ld a, (asm_1_5940_n_es_tab + 40)     ; a lookup ended without an address: not found
            cp 5
            jr nz, asm_1_5940_n_es_ok1
            ld a, 255
            ld (asm_1_5940_n_es_tab + 40), a
asm_1_5940_n_es_ok1:
            cp 3
            jr nz, asm_1_5940_n_es_ok2
            ld a, (asm_1_5940_n_es_bl)           ; a connect's OK: ready (its n,CONNECT may come first)
            call asm_1_5940_n_es_ent
            ld (hl), 0
asm_1_5940_n_es_ok2:
            xor a
            ld (asm_1_5940_n_es_res), a
            ld (asm_1_5940_n_es_busy), a
            ret
asm_1_5940_n_es_ok7:
            xor a
            ld (asm_1_5940_n_es_busy), a
            ret
asm_1_5940_n_es_sendok:
            ld a, (asm_1_5940_n_es_bl)
            call asm_1_5940_n_es_ent
            ld (hl), 0              ; sent: ready
            xor a
            ld (asm_1_5940_n_es_busy), a
            ret
asm_1_5940_n_es_err:
            ld a, (asm_1_5940_n_es_busy)
            or a
            ret z
asm_1_5940_n_es_fail:                            ; the command in flight failed
            ld a, (asm_1_5940_n_es_busy)
            cp 1
            jr z, asm_1_5940_n_es_e1
            cp 6
            jr z, asm_1_5940_n_es_e1
            cp 7
            jr z, asm_1_5940_n_es_e1
            ld a, (asm_1_5940_n_es_bl)
            call asm_1_5940_n_es_ent
            ld (hl), 255
asm_1_5940_n_es_e1:
            ld a, 1
            ld (asm_1_5940_n_es_res), a
            xor a
            ld (asm_1_5940_n_es_busy), a
            ret
asm_1_5940_n_es_dom:                             ; +CIPDOMAIN:a.b.c.d (or "a.b.c.d")
            ld de, asm_1_5940_n_es_tab + 44
            call asm_1_5940_n_es_ip
            xor a
            ld (asm_1_5940_n_es_tab + 40), a     ; found
            ret
asm_1_5940_n_es_ipd:                             ; +IPD,n,len: len more bytes waiting on link n
            ld a, (hl)
            sub '0'
            cp asm_1_5940_n_ES_NL
            ret nc
            ld c, a
            inc hl
            inc hl                  ; (past n,)
            call asm_1_5940_n_es_num             ; DE = len
            ld a, c
            push de
            call asm_1_5940_n_es_ent
            inc hl
            inc hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ex (sp), hl
            add hl, de
            ex de, hl
            pop hl
            ld (hl), d
            dec hl
            ld (hl), e
            ret
; es_capl - IPCONFIG's lines: +CWJAP_CUR:"name","bssid",ch,rssi - connected, its name and signal;
; +CIPSTA_CUR:ip:"a.b.c.d" (gateway:, netmask:); +CIPSTAMAC_CUR:"aa:bb:..."
asm_1_5940_n_es_capl:
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_jap
            call asm_1_5940_n_es_pfx
            jr nz, asm_1_5940_n_es_cp2
            ld a, 2
            ld (asm_1_5940_n_nt_pk + 192), a     ; connected
            ld de, asm_1_5940_n_nt_pk + 220      ; "Connected to " and the name
            push hl
            ld hl, asm_1_5940_n_es_k_conto
            ld bc, 13
            ldir
            pop hl
            inc hl                  ; (past ")
            ld b, 17
asm_1_5940_n_es_cp1:
            ld a, (hl)
            cp '"'
            jr z, asm_1_5940_n_es_cp1b
            or a
            jr z, asm_1_5940_n_es_cp1b
            ld (de), a
            inc hl
            inc de
            djnz asm_1_5940_n_es_cp1
asm_1_5940_n_es_cp1b:
            ld hl, asm_1_5940_n_es_ln            ; the signal: after the last comma, -n
            ld a, (asm_1_5940_n_es_lp)
            ld e, a
            ld d, 0
            add hl, de
asm_1_5940_n_es_cp1c:
            dec hl
            ld a, (hl)
            cp ','
            jr nz, asm_1_5940_n_es_cp1c
            inc hl
            ld a, (hl)
            cp '-'
            ret nz
            inc hl
            call asm_1_5940_n_es_num
            ld a, e
            ld (asm_1_5940_n_nt_pk + 193), a
            ret
asm_1_5940_n_es_cp2:
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_sta
            call asm_1_5940_n_es_pfx
            jr nz, asm_1_5940_n_es_cp5
            ld de, asm_1_5940_n_es_k_ip
            push hl
            call asm_1_5940_n_es_pfx
            pop bc
            jr nz, asm_1_5940_n_es_cp3
            ld de, asm_1_5940_n_nt_pk + 194
            jp asm_1_5940_n_es_ip
asm_1_5940_n_es_cp3:
            ld h, b
            ld l, c
            ld de, asm_1_5940_n_es_k_mask
            push hl
            call asm_1_5940_n_es_pfx
            pop bc
            jr nz, asm_1_5940_n_es_cp4
            ld de, asm_1_5940_n_nt_pk + 198
            jp asm_1_5940_n_es_ip
asm_1_5940_n_es_cp4:
            ld h, b
            ld l, c
            ld de, asm_1_5940_n_es_k_gw
            call asm_1_5940_n_es_pfx
            ret nz
            ld de, asm_1_5940_n_nt_pk + 202
            jp asm_1_5940_n_es_ip
asm_1_5940_n_es_cp5:
            ld hl, asm_1_5940_n_es_ln
            ld de, asm_1_5940_n_es_k_mac
            call asm_1_5940_n_es_pfx
            ret nz
            inc hl                  ; (past ")
            ld de, asm_1_5940_n_nt_pk + 214
            ld b, 6
asm_1_5940_n_es_cp6:
            call asm_1_5940_n_es_hex2
            ld (de), a
            inc de
            inc hl                  ; (past :)
            djnz asm_1_5940_n_es_cp6
            ret
; ---- the pieces
; es_pfx - Z when the text at HL starts with DE's (0 at its end); HL then past it
asm_1_5940_n_es_pfx:
            ld a, (de)
            or a
            ret z
            cp (hl)
            ret nz
            inc hl
            inc de
            jr asm_1_5940_n_es_pfx
; es_pfz - Z when the text at HL is DE's, all of it
asm_1_5940_n_es_pfz:
            call asm_1_5940_n_es_pfx
            ret nz
            ld a, (hl)
            or a
            ret
; es_num - DE = the decimal number at HL (HL past it)
asm_1_5940_n_es_num:
            ld de, 0
asm_1_5940_n_es_nu1:
            ld a, (hl)
            sub '0'
            ret c
            cp 10
            ret nc
            push hl
            ld h, d
            ld l, e
            add hl, hl
            add hl, hl
            add hl, de
            add hl, hl
            ld e, a
            ld d, 0
            add hl, de
            ex de, hl
            pop hl
            inc hl
            jr asm_1_5940_n_es_nu1
; es_ip - a.b.c.d at HL (a " before it skipped) into the 4 bytes at DE
asm_1_5940_n_es_ip:
            ld a, (hl)
            cp '"'
            jr nz, asm_1_5940_n_es_ip1
            inc hl
asm_1_5940_n_es_ip1:
            ld b, 4
asm_1_5940_n_es_ip2:
            push de
            call asm_1_5940_n_es_num
            ld a, e
            pop de
            ld (de), a
            inc de
            inc hl                  ; (past .)
            djnz asm_1_5940_n_es_ip2
            ret
; es_hex2 - A = the two hex digits at HL (HL past them)
asm_1_5940_n_es_hex2:
            call asm_1_5940_n_es_hex1
            add a, a
            add a, a
            add a, a
            add a, a
            ld c, a
            call asm_1_5940_n_es_hex1
            or c
            ret
asm_1_5940_n_es_hex1:
            ld a, (hl)
            inc hl
            or #20
            sub '0'
            cp 10
            ret c
            sub 'a' - '0' - 10
            and 15
            ret
; es_ent - HL = link A's 8 bytes in es_tab (255: the lookup's, the sixth)
asm_1_5940_n_es_ent:
            cp 255
            jr nz, asm_1_5940_n_es_en1
            ld a, 5
asm_1_5940_n_es_en1:
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            ld de, asm_1_5940_n_es_tab
            add hl, de
            ret
; es_put - A to the ESP (when its send buffer has room); es_puts - the text at HL (0 at its end)
asm_1_5940_n_es_put:
            push bc
            push af
            ld bc, asm_1_5940_n_ES_TX
asm_1_5940_n_es_pt1:
            in a, (c)
            and 2
            jr nz, asm_1_5940_n_es_pt1
            pop af
            out (c), a
            pop bc
            ret
asm_1_5940_n_es_puts:
            ld a, (hl)
            or a
            ret z
            call asm_1_5940_n_es_put
            inc hl
            jr asm_1_5940_n_es_puts
asm_1_5940_n_es_crlf:
            ld a, 13
            call asm_1_5940_n_es_put
            ld a, 10
            jr asm_1_5940_n_es_put
; es_putdec - HL in decimal to the ESP
asm_1_5940_n_es_putdec:
            ld de, 10000
            ld b, 0                 ; (B: a digit sent - the noughts after it too)
            call asm_1_5940_n_es_pd1
            ld de, 1000
            call asm_1_5940_n_es_pd1
            ld de, 100
            call asm_1_5940_n_es_pd1
            ld de, 10
            call asm_1_5940_n_es_pd1
            ld a, l
            add a, '0'
            jr asm_1_5940_n_es_put
asm_1_5940_n_es_pd1:
            ld a, '0' - 1
asm_1_5940_n_es_pd2:
            inc a
            or a
            sbc hl, de
            jr nc, asm_1_5940_n_es_pd2
            add hl, de
            cp '0'
            jr nz, asm_1_5940_n_es_pd3
            inc b
            dec b
            ret z
asm_1_5940_n_es_pd3:
            ld b, 1
            jr asm_1_5940_n_es_put
; es_flush - what the ESP has said so far thrown away
asm_1_5940_n_es_flush:
            ld bc, asm_1_5940_n_ES_TX
            in a, (c)
            and 1
            ret z
            ld bc, asm_1_5940_n_ES_RX
            in a, (c)
            jr asm_1_5940_n_es_flush
asm_1_5940_n_es_s_at:    db "AT", 0
asm_1_5940_n_es_s_e0:    db "ATE0", 0
asm_1_5940_n_es_s_cl5:   db "AT+CIPCLOSE=5", 0
asm_1_5940_n_es_s_mux:   db "AT+CIPMUX=1", 0
asm_1_5940_n_es_s_rcv:   db "AT+CIPRECVMODE=1", 0
asm_1_5940_n_es_s_dom:   db "AT+CIPDOMAIN=", 34, 0
asm_1_5940_n_es_s_start: db "AT+CIPSTART=", 0
asm_1_5940_n_es_s_tcp:   db ",", 34, "TCP", 34, ",", 34, 0
asm_1_5940_n_es_s_send:  db "AT+CIPSEND=", 0
asm_1_5940_n_es_s_rdat:  db "AT+CIPRECVDATA=", 0
asm_1_5940_n_es_s_close: db "AT+CIPCLOSE=", 0
asm_1_5940_n_es_s_jap:   db "AT+CWJAP_CUR?", 0
asm_1_5940_n_es_s_sta:   db "AT+CIPSTA_CUR?", 0
asm_1_5940_n_es_s_mac:   db "AT+CIPSTAMAC_CUR?", 0
asm_1_5940_n_es_s_join:  db "AT+CWJAP_DEF=", 34, 0
asm_1_5940_n_es_k_ok:    db "OK", 0
asm_1_5940_n_es_k_sendok: db "SEND OK", 0
asm_1_5940_n_es_k_err:   db "ERROR", 0
asm_1_5940_n_es_k_fail:  db "FAIL", 0
asm_1_5940_n_es_k_sfail: db "SEND FAIL", 0
asm_1_5940_n_es_k_dom:   db "+CIPDOMAIN:", 0
asm_1_5940_n_es_k_ipd:   db "+IPD,", 0
asm_1_5940_n_es_k_conn:  db "CONNECT", 0
asm_1_5940_n_es_k_closed: db "CLOSED", 0
asm_1_5940_n_es_k_rdat:  db "+CIPRECVDATA", 0
asm_1_5940_n_es_k_jap:   db "+CWJAP_CUR:", 0
asm_1_5940_n_es_k_sta:   db "+CIPSTA_CUR:", 0
asm_1_5940_n_es_k_ip:    db "ip:", 0
asm_1_5940_n_es_k_mask:  db "netmask:", 0
asm_1_5940_n_es_k_gw:    db "gateway:", 0
asm_1_5940_n_es_k_mac:   db "+CIPSTAMAC_CUR:", 0
asm_1_5940_n_es_k_conto: db "Connected to "
asm_1_5940_n_es_busy:    db 0                    ; the command in flight: 0 none, 1 OK awaited, 2 a lookup, 3 a connect,
asm_1_5940_n_es_bl:      db 0                    ; 4 a send's >, 5 its SEND OK, 6 a close, 7 a receive; es_bl its link
asm_1_5940_n_es_res:     db 0                    ; the last one's end: 0 OK, 1 an error
asm_1_5940_n_es_cap:     db 0                    ; 1: IPCONFIG's lines to es_capl
asm_1_5940_n_es_lp:      db 0                    ; the line so far: its length, its text
asm_1_5940_n_es_ln:      ds 96
asm_1_5940_n_es_tab:     ds 48                   ; links 0-4 and the lookup's: 8 bytes each
asm_1_5940_n_es_sl:      dw 0                    ; a send's length (its data in nt_pk)
asm_1_5940_n_es_rn:      dw 0                    ; a receive's: how many came (in nt_pk)
asm_1_5940_n_es_t0:      dw 0                    ; the clock when the command in flight was sent
asm_1_5940_n_es_f0:      dw 0                    ; frames (es_now) when a wait began
asm_1_5940_n_es_f1:      dw 0
asm_1_5940_n_es_frm:     dw 0                    ; frames counted
asm_1_5940_n_es_lln:     dw 0                    ; the raster's line last seen
    ENDIF

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
asm_1_5940_n_PT_N:       equ 8
asm_1_5940_n_PT_SZ:      equ 140
asm_1_5940_n_sv_port:
            ld (asm_1_5940_n_pt_op), a
            call asm_1_5940_n_pt_find            ; Z: HL = the port named Byte(2-9); pt_fr: a free record (0: none)
            ld (asm_1_5940_n_pt_rec), hl
            ld a, 0
            jr z, asm_1_5940_n_sp_f
            inc a
asm_1_5940_n_sp_f:
            ld (asm_1_5940_n_pt_has), a          ; 0 there, 1 not
            ld a, (var_hyp_svc_t)
            ld (asm_1_5940_n_pt_me), a
            ld a, (asm_1_5940_n_sv_blk + 12)     ; the length: 128 at most
            cp 129
            jr c, asm_1_5940_n_sp_l
            ld a, 128
            ld (asm_1_5940_n_sv_blk + 12), a
asm_1_5940_n_sp_l:
            ld a, (asm_1_5940_n_pt_op)
            cp 28
            jr z, asm_1_5940_n_pt_open
            ld a, (asm_1_5940_n_pt_has)
            or a
            jr nz, asm_1_5940_n_pt_two           ; (no such port)
            ld hl, (asm_1_5940_n_pt_rec)
            ld a, (asm_1_5940_n_pt_op)
            cp 29
            jr z, asm_1_5940_n_pt_close
            cp 30
            jp z, asm_1_5940_n_pt_call
            cp 31
            jp z, asm_1_5940_n_pt_poll
            cp 32
            jp z, asm_1_5940_n_pt_recv
            jp asm_1_5940_n_pt_reply
asm_1_5940_n_pt_two:
            ld a, 2
            jr asm_1_5940_n_pt_ret
asm_1_5940_n_pt_one:
            ld a, 1
asm_1_5940_n_pt_ret:
            ld sp, (asm_1_5940_n_sv_sp)
            ret
; 28: open
asm_1_5940_n_pt_open:
            ld a, (asm_1_5940_n_pt_has)
            or a
            jr nz, asm_1_5940_n_po_new
            ld hl, (asm_1_5940_n_pt_rec)
            ld a, (asm_1_5940_n_pt_me)
            cp (hl)
            jp z, asm_1_5940_n_sv_ok
            jr asm_1_5940_n_pt_two
asm_1_5940_n_po_new:
            ld hl, (asm_1_5940_n_pt_fr)
            ld a, h
            or l
            jp z, asm_1_5940_n_sv_err
            ld a, (asm_1_5940_n_pt_me)
            ld (hl), a
            inc hl
            ex de, hl
            ld hl, asm_1_5940_n_sv_blk + 2
            ld bc, 8
            ldir
            ex de, hl
            xor a
            ld (hl), a              ; free
            inc hl
            ld (hl), a              ; no caller
            jp asm_1_5940_n_sv_ok
; 29: close
asm_1_5940_n_pt_close:
            ld a, (asm_1_5940_n_pt_me)
            cp (hl)
            jr nz, asm_1_5940_n_pt_two
            ld (hl), 0
            jp asm_1_5940_n_sv_ok
; 30: call - the message into the box (the box busy: 1)
asm_1_5940_n_pt_call:
            ld de, 9
            add hl, de
            ld a, (hl)
            or a
            jr nz, asm_1_5940_n_pt_one
            inc hl
            ld a, (asm_1_5940_n_pt_me)
            ld (hl), a              ; the caller
            inc hl
            ld a, (asm_1_5940_n_sv_blk + 12)
            ld (hl), a              ; the length
            inc hl
            ex de, hl               ; DE = the box
            ld c, a
            ld b, 0
            ld a, b
            or c
            jr z, asm_1_5940_n_pc_0
            ld hl, (asm_1_5940_n_sv_blk + 10)
            call asm_1_5940_n_sv_in
asm_1_5940_n_pc_0:
            ld hl, (asm_1_5940_n_pt_rec)
            ld de, 9
            add hl, de
            ld (hl), 1              ; a message in
            jp asm_1_5940_n_sv_ok
; 31: the answer to this slot's call
asm_1_5940_n_pt_poll:
            ld de, 9
            add hl, de
            ld a, (hl)
            or a
            jp z, asm_1_5940_n_pt_two            ; (no call)
            inc hl
            ld a, (asm_1_5940_n_pt_me)
            cp (hl)
            jp nz, asm_1_5940_n_pt_two           ; (not this slot's call)
            dec hl
            ld a, (hl)
            cp 3
            jp nz, asm_1_5940_n_pt_one           ; not answered yet
            ld (hl), 0              ; the box free again
            inc hl
            ld (hl), 0
            call asm_1_5940_n_pt_give            ; the answer to the slot, its length to Byte(12)
            jp asm_1_5940_n_sv_ok
; 32: the server's next message
asm_1_5940_n_pt_recv:
            ld a, (asm_1_5940_n_pt_me)
            cp (hl)
            jp nz, asm_1_5940_n_pt_two
            ld de, 9
            add hl, de
            ld a, (hl)
            cp 1
            jp nz, asm_1_5940_n_pt_one           ; nothing in
            ld (hl), 2              ; received
            call asm_1_5940_n_pt_give
            jp asm_1_5940_n_sv_ok
; 33: the server's reply
asm_1_5940_n_pt_reply:
            ld a, (asm_1_5940_n_pt_me)
            cp (hl)
            jp nz, asm_1_5940_n_pt_two
            ld de, 9
            add hl, de
            ld a, (hl)
            cp 2
            jp nz, asm_1_5940_n_pt_two           ; (nothing received to reply to)
            inc hl
            ld a, (hl)
            dec hl
            or a
            jr nz, asm_1_5940_n_pr_1
            ld (hl), a              ; its caller gone: dropped, the box free
            jp asm_1_5940_n_sv_ok
asm_1_5940_n_pr_1:
            ld (hl), 3              ; answered
            inc hl
            inc hl
            ld a, (asm_1_5940_n_sv_blk + 12)
            ld (hl), a
            inc hl
            ex de, hl
            ld c, a
            ld b, 0
            ld a, b
            or c
            jp z, asm_1_5940_n_sv_ok
            ld hl, (asm_1_5940_n_sv_blk + 10)
            call asm_1_5940_n_sv_in
            jp asm_1_5940_n_sv_ok
; 34: port Byte(1) (0-7) - its name to the request's Byte(2-9), its slot to Byte(10) (0: free);
; 255 no such port number (PROBE lists the services with it)
asm_1_5940_n_pt_list:
            ld a, (asm_1_5940_n_sv_blk + 1)
            cp asm_1_5940_n_PT_N
            jp nc, asm_1_5940_n_sv_err
            ld hl, asm_1_5940_n_pt_tab
            ld de, asm_1_5940_n_PT_SZ
            or a
            jr z, asm_1_5940_n_pl_2
            ld b, a
asm_1_5940_n_pl_1:
            add hl, de
            djnz asm_1_5940_n_pl_1
asm_1_5940_n_pl_2:
            ld a, (hl)              ; the slot (0 free)
            inc hl
            ld de, asm_1_5940_n_sv_rec
            ld bc, 8
            ldir
            ld (de), a
            ld hl, (var_hyp_svc_p)
            ld de, 2
            add hl, de
            ex de, hl
            ld hl, asm_1_5940_n_sv_rec
            ld bc, 9
            call asm_1_5940_n_sv_out
            jp asm_1_5940_n_sv_ok
; pt_give - the port's box (pt_rec) to the slot's Word(10); its length and the caller to the
; request's Byte(12), Byte(13)
asm_1_5940_n_pt_give:
            ld hl, (asm_1_5940_n_pt_rec)
            ld de, 10
            add hl, de
            ld a, (hl)
            ld (asm_1_5940_n_pt_tmp + 1), a      ; the caller
            inc hl
            ld a, (hl)
            ld (asm_1_5940_n_pt_tmp), a          ; the length
            inc hl
            ld c, a
            ld b, 0
            or a
            jr z, asm_1_5940_n_pg_0
            ld de, (asm_1_5940_n_sv_blk + 10)
            call asm_1_5940_n_sv_out
asm_1_5940_n_pg_0:
            ld hl, (var_hyp_svc_p)
            ld de, 12
            add hl, de
            ex de, hl
            ld hl, asm_1_5940_n_pt_tmp
            ld bc, 2
            jp asm_1_5940_n_sv_out
; pt_find - Z: HL = the port named sv_blk's Byte(2-9), else NZ; pt_fr: a free record (0 none)
asm_1_5940_n_pt_find:
            ld hl, 0
            ld (asm_1_5940_n_pt_fr), hl
            ld hl, asm_1_5940_n_pt_tab
            ld b, asm_1_5940_n_PT_N
asm_1_5940_n_pf_1:
            ld a, (hl)
            or a
            jr nz, asm_1_5940_n_pf_2
            ld a, (asm_1_5940_n_pt_fr + 1)
            or a
            jr nz, asm_1_5940_n_pf_n
            ld (asm_1_5940_n_pt_fr), hl
            jr asm_1_5940_n_pf_n
asm_1_5940_n_pf_2:
            push hl
            push bc
            inc hl
            ld de, asm_1_5940_n_sv_blk + 2
            ld b, 8
asm_1_5940_n_pf_3:
            ld a, (de)
            cp (hl)
            jr nz, asm_1_5940_n_pf_4
            inc hl
            inc de
            djnz asm_1_5940_n_pf_3
asm_1_5940_n_pf_4:
            pop bc
            pop hl
            ret z
asm_1_5940_n_pf_n:
            ld de, asm_1_5940_n_PT_SZ
            add hl, de
            djnz asm_1_5940_n_pf_1
            or 1
            ret
; pt_free - slot C's ports closed; its calls forgotten (a message not received yet, an answer not
; taken: the box free; one being worked on: its reply dropped). Keeps C
asm_1_5940_n_pt_free:
            ld hl, asm_1_5940_n_pt_tab
            ld b, asm_1_5940_n_PT_N
asm_1_5940_n_pt_fr1:
            ld a, (hl)
            cp c
            jr nz, asm_1_5940_n_pt_fr2
            ld (hl), 0
asm_1_5940_n_pt_fr2:
            push hl
            ld de, 10
            add hl, de
            ld a, (hl)
            cp c
            jr nz, asm_1_5940_n_pt_fr4
            ld (hl), 0              ; no caller
            dec hl
            ld a, (hl)
            cp 2
            jr z, asm_1_5940_n_pt_fr4            ; (being worked on: its reply dropped then)
            ld (hl), 0
asm_1_5940_n_pt_fr4:
            pop hl
            ld de, asm_1_5940_n_PT_SZ
            add hl, de
            djnz asm_1_5940_n_pt_fr1
            ret
asm_1_5940_n_pt_op:      db 0
asm_1_5940_n_pt_has:     db 0
asm_1_5940_n_pt_me:      db 0
asm_1_5940_n_pt_rec:     dw 0
asm_1_5940_n_pt_fr:      dw 0
asm_1_5940_n_pt_tmp:     dw 0
asm_1_5940_n_nt_rom:     db 255
asm_1_5940_n_nt_old:     dw 0
asm_1_5940_n_nt_rsp:     dw 0
asm_1_5940_n_nt_skt:     dw 0
asm_1_5940_n_nt_own:     ds asm_1_5940_n_NT_N
asm_1_5940_n_sv_sp:      dw 0
asm_1_5940_n_sv_n:       dw 0
asm_1_5940_n_sv_c:       dw 0
asm_1_5940_n_sv_sk:      db 0
asm_1_5940_n_sv_ss:      dw 0
asm_1_5940_n_sv_sa:      dw 0
asm_1_5940_n_sv_dk:      db 0
asm_1_5940_n_sv_ds:      dw 0
asm_1_5940_n_sv_da:      dw 0
asm_1_5940_n_sv_stop:    db 0
asm_1_5940_n_sv_tj:      db 0
asm_1_5940_n_sv_tn:      db 0
asm_1_5940_n_sv_tsg:     dw 0
asm_1_5940_n_sv_blk:     ds 16
asm_1_5940_n_sv_tmp:     ds 16
asm_1_5940_n_sv_rec:     ds 128
asm_1_5940_n_sv_cl:      ds asm_1_5940_n_CL_N * 10            ; the claims (16-19; table 4)
asm_1_5940_n_nt_pk:      ds 256                  ; a packet to the M4 (21-27)
asm_1_5940_n_pt_tab:     ds asm_1_5940_n_PT_N * asm_1_5940_n_PT_SZ         ; the ports (28-33)
asm_1_5940_n_sv_end:
            ASSERT asm_1_5940_n_sv_end <= #8000, "the service page's code"
			ENDM
; ============================================================
; NTC program - generated by NTC BASIC (VB style BASIC to NTC)
; platform: msxdos (MSX-DOS 2 / Nextor (a .COM: the mapper, the frame interrupt)), starts in normal mode
; ============================================================

			org #0100

NTC_TERM	equ 0		; Option Terminal: 0 none, 1 VT52, 2 ANSI (CP/M)
NTC_STRMAX	equ 72		; the longest string (library buffers, temps)
NTC_MEMBANKS	equ 64		; Option Memory: the most 64K banks the Memory class looks for
NTC_ROMENABLE	equ 0		; Option RomEnable (cpcfw, cpcmin): the start code starts the ROMs
NTC_ROMLIB	equ 0		; 1 = the library is the keyword ROM (Library: ROM; ntcRomAsm builds it)
NTC_WINHOLE	equ 1		; 1 = the program is built round an Option Reserve range over the window #4000-#7FFF
NTC_BUFSIZE	equ 128		; the library's buffer (ntc_buf: FileSystem, Memory.Copy): Option Buffer
; MSX-DOS 2 / Nextor: NTC_MSXDOS defined (the Memory class's mapper: asm/ntc_lib_msx.asm)
			DEFINE NTC_MSXDOS
; the interrupt handler passes 1 in C at a frame's interrupt (ntc_isl_tick: not the CPC's vertical sync)
			DEFINE NTC_ISLC
NTC_CPMGFX	equ 0		; 1 = CP/M: Graphics draws on an Amstrad CPC's screen (2.2: #C000, Plus: block 1 from common memory)

ntc_start:
			di
			ld sp, #C000		; the platform's own real stack
			ld (ntc_csp), sp
			ld a, 1
			ld (ntc_nmode), a		; normal mode: waits let interrupts in
			; Option Class Interrupt: the classes' Tick subs, run at safe points (normal mode)
			ld hl, 1		; hot: every 1 interrupts
			ld (ntc_isl + 2), hl
			ld hl, 2			; the first after one period (+ the slot, so they take turns)
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
			dw asm_0_71_n
			dw p_hyp_vdu_c, lit_0
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
			dw kw_vtov, var_hyp_filecall_filecall, var_bz
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
			dw kw_ltov, 65, var_bd
			dw kw_vtov, var_bz, var_bd
			dw kw_strcmpne, var_a, str2
			dw kw_goto_iffalse_n, if9_1
			dw kw_strasc, var_a, var_bd
if9_1:
			dw kw_ztov, var_mz
			dw kw_ztov, var_nz
			dw p_probediscs_c
			dw kw_vtov, var_probediscs_probediscs, var_i
			dw p_hyp_drive_c, var_bd
			dw kw_vtov, var_hyp_drive_drive, var_i
			dw kw_strcpy, var_dn, str4
			dw kw_strlen, var_dn, tmp4
			dw p_hyp_filecall_c, lit_100, vp_var_dn, lit_0, lit_0, tmp4, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, if10_1
			dw p_hyp_vdu_c, lit_1
			dw kw_model, 1
			dw kw_printstrvar, str5
			dw kw_printnl
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop
if10_1:
			dw p_install_c, lit_0
			dw p_hyp_filecall_c, lit_103, lit_m4864, lit_0, arr_sg, lit_256, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_i
			dw p_hyp_filecall_c, lit_102, lit_0, lit_0, lit_0, lit_0, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_i
			dw p_launch_c, lit_0
			dw p_far_c, lit_0, lit_128
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw kw_ztov, var_kra
do11_t:
			dw p_hyp_reply_c, var_kra, var_kra
			dw p_hyp_run_c, arr_sg
			dw kw_vtov, var_hyp_run_run, var_k
			dw kw_ztov, var_kra
			dw p_hyp_count_c
			dw kw_vtov, var_hyp_count_count, var_i
			dw kw_scpgtvl, var_i, 0
			dw kw_goto_iffalse_n, if12_1
			dw p_kshow_c, var_i
if12_1:
			dw kw_cpeqvl, var_k, 1
			dw kw_goto_iffalse_n, do11_t
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_i
			dw kw_cpeqvl, var_i, 132
			dw kw_goto_iffalse_n, if14_1
			dw p_serve_c
			dw do11_t_go
if14_1:
			dw kw_cpeqvl, var_i, 0
			dw kw_goto_iffalse_n, if14_2
			dw p_quit_c, lit_m1
			dw do11_t_go
if14_2:
			dw kw_cpnevl, var_i, 128
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_i, 129
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do11_t
			dw kw_ltov, 255, var_kra
if14_3:
if14_e:
if13_1:
			dw do11_t_go
do11_e:
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
; sub serve (normal mode)
; ============================================================

p_serve:
			dw fn_kin
			dw kw_vtov, arr_kw+2, var_serve_t
			dw kw_vtov, arr_kw, var_serve___sel17
			dw kw_cpeqvl, var_serve___sel17, 12
			dw kw_goto_iffalse_n, sel17_1
sel17_b1:
			dw p_hyp_reply_c, arr_kw+4, arr_kw+4
			dw kw_ztov, arr_kw+22
			dw kw_ztov, arr_kw+26
			dw kw_ztov, arr_kw+28
			dw kw_divvl, arr_kw+8, 256, var_serve_c
do18_t:
			dw kw_aget, arr_sg, var_serve_t, tmp0
			dw p_hyp_run_c, tmp0
			dw kw_vtov, var_hyp_run_run, arr_kw+16
			dw kw_inc, arr_kw+26
			dw p_hyp_count_c
			dw kw_vtov, var_hyp_count_count, arr_kw+18
			dw kw_scpgtvl, arr_kw+18, 0
			dw kw_goto_iffalse_n, if19_1
			dw kw_aget, arr_wp, var_serve_t, tmp0
			dw kw_cpeqvv, var_serve_t, var_front
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
			dw p_hyp_con_c, tmp0, lit_0, arr_kw+18, tmp3
			dw kw_add, arr_kw+22, arr_kw+18, arr_kw+22
if19_1:
			dw kw_cpeqvl, arr_kw+16, 0
			dw kw_goto_iffalse_n, if21_1
			dw kw_inc, arr_kw+28
			dw kw_andvl, arr_kw+8, 255, tmp1
			dw kw_scpgevv, arr_kw+28, tmp1
			dw kw_goto_iffalse_n, do18_t
			dw do18_e_go
if22_1:
			dw do18_t_go
if21_1:
			dw p_owncall_c, var_serve_t
			dw kw_cpeqvl, var_cw, 1
			dw kw_goto_iffalse_n, if23_1
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, arr_kw+18
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, arr_kw+20
			dw do18_e_go
if23_1:
			dw p_hyp_reply_c, var_ca, var_ca
			dw kw_dec, var_serve_c
			dw kw_cpnevl, var_cw, 0
			dw kw_ftov, tmp0
			dw kw_scplevl, var_serve_c, 0
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do18_t
			dw kw_vtov, var_cw, arr_kw+16
			dw kw_vtov, var_ca, arr_kw+18
			dw kw_cpeqvl, var_cw, 0
			dw kw_goto_iffalse_n, do18_e
			dw kw_ltov, 2, arr_kw+16
if25_1:
			dw do18_e_go
if24_1:
if21_e:
			dw do18_t_go
do18_e:
			dw kw_cpnevl, arr_kw+6, 0
			dw kw_goto_iffalse_n, sel17_e
			dw p_far_c, var_serve_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, arr_kw+24
if26_1:
			dw sel17_e_go
sel17_1:
			dw kw_cpeqvl, var_serve___sel17, 22
			dw kw_goto_iffalse_n, sel17_2
sel17_b2:
			dw p_hot_take_c
			dw kw_vtov, var_hot_take_take, arr_kw+16
			dw kw_cpeqvl, arr_kw+16, 0
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_serve_t, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, sel17_e
			dw kw_inkey, tmp0
			dw kw_vtov, tmp0, arr_kw+18
			dw p_hot_control_c
			dw kw_vtov, var_hot_control_control, arr_kw+20
			dw p_hot_held_c
			dw kw_vtov, var_hot_held_held, arr_kw+22
if27_1:
			dw sel17_e_go
sel17_2:
			dw kw_cpeqvl, var_serve___sel17, 1
			dw kw_goto_iffalse_n, sel17_3
sel17_b3:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, arr_kw+16
			dw sel17_e_go
sel17_3:
			dw kw_cpeqvl, var_serve___sel17, 2
			dw kw_goto_iffalse_n, sel17_4
sel17_b4:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, arr_kw+6
			dw sel17_e_go
sel17_4:
			dw kw_cpeqvl, var_serve___sel17, 7
			dw kw_goto_iffalse_n, sel17_5
sel17_b5:
			dw p_kdin_c, vp_arr_kd, arr_kw+4
			dw kw_aget, arr_wp, var_serve_t, tmp0
			dw p_hyp_con_c, tmp0, vp_arr_kd, arr_kw+4, arr_kw+6
			dw sel17_e_go
sel17_5:
			dw kw_cpeqvl, var_serve___sel17, 32
			dw kw_goto_iffalse_n, sel17_6
sel17_b6:
			dw kw_inkey, tmp0
			dw kw_vtov, tmp0, arr_kw+16
			dw p_hot_control_c
			dw kw_vtov, var_hot_control_control, arr_kw+18
			dw p_hot_held_c
			dw kw_vtov, var_hot_held_held, arr_kw+20
			dw sel17_e_go
sel17_6:
			dw kw_cpeqvl, var_serve___sel17, 3
			dw kw_goto_iffalse_n, sel17_7
sel17_b7:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readword, ltmp0, arr_kw+16
			dw sel17_e_go
sel17_7:
			dw kw_cpeqvl, var_serve___sel17, 4
			dw kw_goto_iffalse_n, sel17_8
sel17_b8:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, arr_kw+6
			dw sel17_e_go
sel17_8:
			dw kw_cpeqvl, var_serve___sel17, 5
			dw kw_goto_iffalse_n, sel17_9
sel17_b9:
			dw p_kdin_c, vp_arr_kd, arr_kw+6
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, arr_kw+6, var_memory_copy_copy
			dw sel17_e_go
sel17_9:
			dw kw_cpeqvl, var_serve___sel17, 6
			dw kw_goto_iffalse_n, sel17_10
sel17_b10:
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, arr_kw+6, var_memory_copy_copy
			dw p_kdout_c, vp_arr_kd, arr_kw+6
			dw sel17_e_go
sel17_10:
			dw kw_cpeqvl, var_serve___sel17, 8
			dw kw_goto_iffalse_n, sel17_11
sel17_b11:
			dw kw_aget, arr_wp, var_serve_t, tmp0
			dw p_hyp_con_c, tmp0, arr_kw+4, arr_kw+6, arr_kw+8
			dw sel17_e_go
sel17_11:
			dw kw_cpeqvl, var_serve___sel17, 9
			dw kw_goto_iffalse_n, sel17_12
sel17_b12:
			dw p_hyp_scr_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_hyp_scr_scr, arr_kw+16
			dw sel17_e_go
sel17_12:
			dw kw_cpeqvl, var_serve___sel17, 13
			dw kw_goto_iffalse_n, sel17_13
sel17_b13:
			dw kw_cpeqvl, var_serve_t, 100
			dw kw_goto_iffalse_n, if28_1
			dw p_kdin_c, vp_arr_kd, arr_kw+4
			dw p_hyp_filecall_c, lit_100, vp_arr_kd, lit_0, lit_0, arr_kw+4, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16
			dw p_kdout_c, vp_arr_kd, arr_kw+4
			dw sel17_e_go
if28_1:
			dw kw_scpgevl, var_serve_t, 100
			dw kw_goto_iffalse_n, if28_2
			dw kw_aget, arr_sg, arr_kw+6, tmp3
			dw p_hyp_filecall_c, var_serve_t, arr_kw+4, arr_kw+6, tmp3, arr_kw+8, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16
			dw sel17_e_go
if28_2:
			dw kw_aget, arr_sg, arr_kw+6, tmp3
			dw kw_aget, arr_dm, arr_kw+6, tmp4
			dw kw_aget, arr_dv, arr_kw+6, tmp5
			dw p_hyp_filecall_c, var_serve_t, arr_kw+4, arr_kw+6, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16
if28_e:
			dw sel17_e_go
sel17_13:
			dw kw_cpeqvl, var_serve___sel17, 14
			dw kw_goto_iffalse_n, sel17_14
sel17_b14:
			dw p_hyp_drive_c, var_serve_t
			dw kw_vtov, var_hyp_drive_drive, arr_kw+16
			dw sel17_e_go
sel17_14:
			dw kw_cpeqvl, var_serve___sel17, 28
			dw kw_goto_iffalse_n, sel17_15
sel17_b15:
			dw kw_aget, arr_dv, var_serve_t, arr_kw+16
			dw sel17_e_go
sel17_15:
			dw kw_cpeqvl, var_serve___sel17, 29
			dw kw_goto_iffalse_n, sel17_16
sel17_b16:
			dw kw_aset, arr_dv, var_serve_t, arr_kw+4
			dw sel17_e_go
sel17_16:
			dw kw_cpeqvl, var_serve___sel17, 31
			dw kw_goto_iffalse_n, sel17_17
sel17_b17:
			dw kw_aget, arr_dv, var_serve_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if29_1
			dw kw_aset, arr_dv, var_serve_t, var_bd
if29_1:
			dw kw_aget, arr_dv, var_serve_t, tmp0
			dw p_hyp_drive_c, tmp0
			dw kw_vtov, var_hyp_drive_drive, arr_kw+16
			dw sel17_e_go
sel17_17:
			dw kw_cpeqvl, var_serve___sel17, 16
			dw kw_goto_iffalse_n, sel17_18
sel17_b18:
			dw kw_aget, arr_sg, var_serve_t, tmp2
			dw p_hyp_svc_c, var_serve_t, arr_kw+4, tmp2, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, arr_kw+16
			dw sel17_e_go
sel17_18:
			dw kw_cpeqvl, var_serve___sel17, 11
			dw kw_goto_iffalse_n, sel17_19
sel17_b19:
			dw p_kdin_c, vp_arr_kd, var_serve_t
			dw p_hyp_say_c, vp_arr_kd, var_serve_t, arr_kw+4, arr_kw+6
			dw sel17_e_go
sel17_19:
			dw kw_cpeqvl, var_serve___sel17, 10
			dw kw_goto_iffalse_n, sel17_20
sel17_b20:
			dw sel17_e_go
sel17_20:
			dw kw_cpeqvl, var_serve___sel17, 23
			dw kw_goto_iffalse_n, sel17_21
sel17_b21:
			dw sel17_e_go
sel17_21:
			dw kw_cpeqvl, var_serve___sel17, 24
			dw kw_goto_iffalse_n, sel17_22
sel17_b22:
			dw kw_aset, arr_st, var_serve_t, arr_kw+4
			dw sel17_e_go
sel17_22:
			dw kw_cpeqvl, var_serve___sel17, 25
			dw kw_goto_iffalse_n, sel17_23
sel17_b23:
			dw kw_vtov, var_serve_t, var_front
			dw sel17_e_go
sel17_23:
			dw kw_cpeqvl, var_serve___sel17, 19
			dw kw_goto_iffalse_n, sel17_24
sel17_b24:
			dw p_install_c, var_serve_t
			dw sel17_e_go
sel17_24:
			dw kw_cpeqvl, var_serve___sel17, 30
			dw kw_goto_iffalse_n, sel17_25
sel17_b25:
			dw p_launch_c, var_serve_t
			dw sel17_e_go
sel17_25:
			dw kw_cpeqvl, var_serve___sel17, 15
			dw kw_goto_iffalse_n, sel17_26
sel17_b26:
			dw p_hyp_fileshut_c, var_serve_t
			dw p_hyp_svc_c, var_serve_t, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_serve_c
			dw sel17_e_go
sel17_26:
			dw kw_cpeqvl, var_serve___sel17, 17
			dw kw_goto_iffalse_n, sel17_27
sel17_b27:
			dw p_ramdisc_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_ramdisc_ramdisc, arr_kw+16
			dw sel17_e_go
sel17_27:
			dw kw_cpeqvl, var_serve___sel17, 18
			dw kw_goto_iffalse_n, sel17_28
sel17_b28:
			dw p_storesize_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_storesize_storesize, arr_kw+16
			dw sel17_e_go
sel17_28:
			dw kw_cpeqvl, var_serve___sel17, 20
			dw kw_goto_iffalse_n, sel17_29
sel17_b29:
			dw fn_memory_tableend, arr_kw+16
			dw fn_memory_top, arr_kw+18
			dw fn_memory_pages, arr_kw+20
			dw fn_memory_ramsize, arr_kw+22
			dw fn_memory_freepages, arr_kw+24
			dw sel17_e_go
sel17_29:
			dw kw_cpeqvl, var_serve___sel17, 21
			dw kw_goto_iffalse_n, sel17_30
sel17_b30:
			dw fn_memory_map, var_serve_t, lit_32, var_memory_map_map
			dw kw_strcpy, var_en, var_memory_map_map
			dw kw_strlen, var_en, arr_kw+16
			dw kw_strlen, var_en, tmp1
			dw p_kdout_c, vp_var_en, tmp1
			dw sel17_e_go
sel17_30:
			dw kw_cpeqvl, var_serve___sel17, 26
			dw kw_goto_iffalse_n, sel17_31
sel17_b31:
			dw kw_vtov, var_ns, arr_kw+16
			dw kw_vtov, var_bd, arr_kw+18
			dw kw_vtov, var_mz, arr_kw+22
			dw kw_ltov, 65, arr_kw+24
			dw kw_vtov, var_nz, arr_kw+26
			dw kw_ltov, 3, arr_kw+20
			dw sel17_e_go
sel17_31:
			dw kw_cpeqvl, var_serve___sel17, 33
			dw kw_goto_iffalse_n, sel17_32
sel17_b32:
			dw p_hyp_bootdrive_c, var_bd, vp_arr_dv
			dw kw_vtov, var_bd, arr_kw+16
			dw sel17_e_go
sel17_32:
			dw kw_cpeqvl, var_serve___sel17, 27
			dw kw_goto_iffalse_n, sel17_33
sel17_b33:
			dw p_quit_c, var_serve_t
sel17_33:
sel17_e:
			dw p_hyp_t300_c
			dw kw_vtov, var_hyp_t300_t300, arr_kw+30
			dw fn_kout
			dw p_serve_r

ntc_rg2_e:
			IF ($ < 32768) && (ntc_rg3_e - ntc_rg3 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg3:
; ============================================================
; sub kdin (normal mode)
; ============================================================

p_kdin:
			dw asm_0_471_n
			dw p_kdin_r

ntc_rg3_e:
			IF ($ < 32768) && (ntc_rg4_e - ntc_rg4 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg4:
; ============================================================
; sub kdout (normal mode)
; ============================================================

p_kdout:
			dw asm_0_502_n
			dw p_kdout_r

ntc_rg4_e:
			IF ($ < 32768) && (ntc_rg5_e - ntc_rg5 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg5:
; ============================================================
; sub kshow (normal mode)
; ============================================================

p_kshow:
			dw kw_vtov, var_front, var_kshow_t
			dw kw_cpeqvl, var_kshow_t, 0
			dw kw_goto_iffalse_n, if30_1
			dw kw_ltov, 1, var_kshow_t
if30_1:
			dw p_far_c, lit_0, lit_m2560
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_kshow_n, var_memory_copy_copy
			dw kw_aget, arr_wp, var_kshow_t, tmp0
			dw kw_cpeqvv, var_kshow_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch31_0
			dw kw_ltov, 1, tmp3
			dw ch31_e_go
ch31_0:
			dw kw_ztov, tmp3
			dw ch31_e_go
ch31_1:
			dw kw_ztov, tmp3
ch31_e:
			dw p_hyp_con_c, tmp0, vp_arr_kd, var_kshow_n, tmp3
			dw p_kshow_r

ntc_rg5_e:
			IF ($ < 32768) && (ntc_rg6_e - ntc_rg6 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg6:
; ============================================================
; sub quit (normal mode)
; ============================================================

p_quit:
			dw p_hyp_scr_c, lit_0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_i
			dw p_hyp_vdu_c, lit_1
			dw kw_model, 1
			dw kw_scpltvl, var_quit_n, 0
			dw kw_goto_iffalse_n, if32_1
			dw kw_printstrvar, str6
			dw kw_printnl
			dw if32_e_go
if32_1:
			dw kw_printstrvar, str7
			dw kw_printint, var_quit_n
			dw kw_printstrvar, str8
			dw kw_printnl
if32_e:
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop

ntc_rg6_e:
			IF ($ < 32768) && (ntc_rg7_e - ntc_rg7 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg7:
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
			dw kw_vtov, var_owncall_f, var_owncall___sel33
			dw kw_cpeqvl, var_owncall___sel33, 128
			dw kw_goto_iffalse_n, sel33_1
sel33_b1:
			dw sel33_e_go
sel33_1:
			dw kw_cpeqvl, var_owncall___sel33, 26
			dw kw_goto_iffalse_n, sel33_2
sel33_b2:
			dw kw_aset, arr_dm, var_owncall_t, var_owncall_e
			dw sel33_e_go
sel33_2:
			dw kw_cpeqvl, var_owncall___sel33, 14
			dw kw_goto_iffalse_n, sel33_3
sel33_b3:
			dw kw_andvl, var_owncall_e, 255, tmp2
			dw kw_addl, tmp2, 65, tmp1
			dw kw_aset, arr_dv, var_owncall_t, tmp1
			dw sel33_e_go
sel33_3:
			dw kw_cpeqvl, var_owncall___sel33, 25
			dw kw_goto_iffalse_n, sel33_4
sel33_b4:
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, sel33_e
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_addl, tmp0, -65, var_ca
if34_1:
			dw sel33_e_go
sel33_4:
			dw kw_cpeqvl, var_owncall___sel33, 24
			dw kw_goto_iffalse_n, sel33_5
sel33_b5:
			dw kw_ltov, 1, var_ca
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, sel33_e
			dw kw_ltov, 1, var_owncall_j
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_addl, tmp0, -65, tmp0
			dw kw_andvl, tmp0, 7, for36_l
			dw kw_forupv_n, var_owncall_j, for36_l, sel33_e
for36_t:
			dw kw_2x, var_ca, var_ca
			dw kw_next1v_n, var_owncall_j, for36_l, for36_t
for36_e:
if35_1:
			dw sel33_e_go
sel33_5:
			dw kw_cpeqvl, var_owncall___sel33, 13
			dw kw_goto_iftrue_n, sel33_e
			dw kw_cpeqvl, var_owncall___sel33, 32
			dw kw_goto_iffalse_n, sel33_6
sel33_b6:
			dw sel33_e_go
sel33_6:
			dw kw_scpltvl, var_owncall___sel33, 15
			dw kw_goto_iftrue_n, sel33_7
			dw kw_scplevl, var_owncall___sel33, 36
			dw kw_goto_iffalse_n, sel33_7
sel33_b7:
			dw kw_aget, arr_sg, var_owncall_t, tmp3
			dw kw_aget, arr_dm, var_owncall_t, tmp4
			dw kw_aget, arr_dv, var_owncall_t, tmp5
			dw p_hyp_filecall_c, var_owncall_f, var_owncall_e, var_owncall_t, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_ca
			dw sel33_e_go
sel33_7:
			dw kw_cpeqvl, var_owncall___sel33, 131
			dw kw_goto_iffalse_n, sel33_8
sel33_b8:
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
			dw kw_goto_ifzero_n, tmp0, if37_1
			dw kw_aget, arr_sg, var_owncall_t, tmp2
			dw p_hyp_svc_c, var_owncall_t, var_owncall_e, tmp2, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_ca
			dw kw_cpeqvl, var_ca, 1
			dw kw_ftov, tmp0
			dw kw_scpgevl, var_owncall_o, 30
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, sel33_e
			dw kw_ltov, 3, var_cw
if38_1:
			dw sel33_e_go
if37_1:
			dw kw_cpeqvl, var_owncall_o, 12
			dw kw_goto_iffalse_n, if37_2
			dw kw_addl, var_owncall_e, 2, tmp2
			dw p_far_c, var_owncall_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_readword, ltmp1, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp1
			dw p_storesize_c, var_owncall_t, tmp1
			dw kw_vtov, var_storesize_storesize, var_ca
			dw sel33_e_go
if37_2:
			dw kw_ltov, 1, var_cw
if37_e:
			dw sel33_e_go
sel33_8:
			dw kw_cpeqvl, var_owncall___sel33, 12
			dw kw_goto_iffalse_n, sel33_9
sel33_b9:
			dw kw_ltov, 34, var_ca
			dw kw_ltov, 2, var_cw
			dw sel33_e_go
sel33_9:
			dw kw_cpeqvl, var_owncall___sel33, 40
			dw kw_goto_iffalse_n, sel33_10
sel33_b10:
			dw kw_aget, arr_sg, var_owncall_t, tmp3
			dw kw_aget, arr_dm, var_owncall_t, tmp4
			dw kw_aget, arr_dv, var_owncall_t, tmp5
			dw p_hyp_filecall_c, lit_34, var_owncall_e, var_owncall_t, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_ca
			dw kw_ltov, 2, var_cw
			dw sel33_e_go
sel33_10:
			dw kw_cpeqvl, var_owncall___sel33, 130
			dw kw_goto_iffalse_n, sel33_11
sel33_b11:
			dw p_ramdisc_c, var_owncall_t, var_owncall_e
			dw kw_vtov, var_ramdisc_ramdisc, var_ca
			dw kw_ltov, 2, var_cw
			dw sel33_e_go
sel33_11:
			dw kw_ltov, 1, var_cw
sel33_e:
			dw p_owncall_r

ntc_rg7_e:
			IF ($ < 32768) && (ntc_rg8_e - ntc_rg8 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg8:
; ============================================================
; function ramdisc (normal mode)
; ============================================================

p_ramdisc:
			dw p_far_c, var_ramdisc_t, var_ramdisc_p
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_ramdisc_o
			dw kw_cpeqvl, var_dp, 0
			dw kw_goto_iffalse_n, if39_1
			dw kw_ltov, 255, var_ramdisc_ramdisc
			dw kw_cpeqvl, var_ramdisc_o, 3
			dw kw_goto_iffalse_n, if40_1
			dw p_ramdisc_r
if40_1:
			dw fn_memory_allocpage, lit_85, var_dp
			dw kw_cpeqvl, var_dp, 0
			dw kw_goto_iffalse_n, if41_1
			dw kw_ltov, 2, var_ramdisc_ramdisc
			dw p_ramdisc_r
if41_1:
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
if39_1:
			dw kw_ztov, var_ramdisc_g
			dw kw_cpeqvl, var_ramdisc_o, 2
			dw kw_goto_iffalse_n, if42_1
			dw fn_memory_allocpage, lit_85, var_ramdisc_g
			dw kw_ltov, 2, var_ramdisc_ramdisc
			dw kw_cpeqvl, var_ramdisc_g, 0
			dw kw_goto_iffalse_n, if43_1
			dw p_ramdisc_r
if43_1:
			dw fn_memory_selectpage, var_ramdisc_g, var_ramdisc_ramdisc
if42_1:
			dw kw_aget, arr_sg, var_ramdisc_t, tmp3
			dw fn_hyp_setting, var_hyp_setting_setting
			dw kw_vtov, var_hyp_setting_setting, tmp5
			dw p_hyp_filecall_c, lit_116, var_ramdisc_p, var_ramdisc_t, tmp3, var_ramdisc_g, tmp5, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_ramdisc_ramdisc
			dw kw_scpltvl, var_ramdisc_ramdisc, 0
			dw kw_goto_iffalse_n, if44_1
			dw kw_andvl, var_ramdisc_ramdisc, 32767, tmp0
			dw fn_memory_freepage, tmp0, var_ramdisc_ramdisc
			dw kw_ztov, var_ramdisc_ramdisc
if44_1:
			dw kw_cpnevl, var_ramdisc_g, 0
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_ramdisc_ramdisc, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if45_1
			dw fn_memory_freepage, var_ramdisc_g, var_ramdisc_ramdisc
			dw kw_ltov, 2, var_ramdisc_ramdisc
if45_1:
			dw p_ramdisc_r

ntc_rg8_e:
			IF ($ < 32768) && (ntc_rg9_e - ntc_rg9 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg9:
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
			dw kw_goto_ifzero_n, tmp0, if46_1
			dw kw_ltov, 32, var_storesize_n
if46_1:
			dw kw_ztov, var_storesize_j
for47_t:
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_storesize_g
			dw kw_scpltvv, var_storesize_j, var_storesize_n
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_storesize_g, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if48_1
			dw fn_memory_allocpage, lit_85, var_storesize_g
			dw kw_cpeqvl, var_storesize_g, 0
			dw kw_goto_iffalse_n, if49_1
			dw kw_ltov, 2, var_storesize_storesize
			dw p_storesize_r
if49_1:
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_storesize_g
			dw if48_e_go
if48_1:
			dw kw_scpgevv, var_storesize_j, var_storesize_n
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_storesize_g, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if48_2
			dw fn_memory_freepage, var_storesize_g, var_memory_freepage_freepage
			dw kw_vtov, var_memory_freepage_freepage, var_storesize_g
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
if48_2:
if48_e:
			dw kw_next1l_n, var_storesize_j, 31, for47_t
for47_e:
			dw p_storesize_r

ntc_rg9_e:
			IF ($ < 32768) && (ntc_rg10_e - ntc_rg10 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg10:
; ============================================================
; function probediscs (normal mode)
; ============================================================

p_probediscs:
			dw kw_ztov, var_probediscs_probediscs
			dw kw_ltov, 2, var_probediscs_p
			dw fn_memory_pages, for50_l
			dw kw_forupv_n, var_probediscs_p, for50_l, for50_e
for50_t:
			dw fn_memory_pagetype, var_probediscs_p, var_memory_pagetype_pagetype
			dw kw_vtov, var_memory_pagetype_pagetype, tmp0
			dw kw_cpeqvl, tmp0, 45
			dw kw_goto_iffalse_n, if51_1
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
			dw kw_goto_ifzero_n, tmp0, if52_1
			dw kw_ztov, var_probediscs_su
			dw kw_ltov, 21504, var_probediscs_j
for53_t:
			dw kw_vptrtov8, var_probediscs_j, tmp1
			dw kw_add, var_probediscs_su, tmp1, tmp0
			dw kw_vtov, tmp0, var_probediscs_su
			dw kw_next1l_n, var_probediscs_j, 23039, for53_t
for53_e:
			dw kw_lptrtov8, 32518, tmp1
			dw kw_lptrtov8, 32519, tmp2
			dw kw_mulvl, tmp2, 256, tmp2
			dw kw_add, tmp1, tmp2, tmp1
			dw kw_cpeqvv, var_probediscs_su, tmp1
			dw kw_goto_iffalse_n, if54_1
			dw p_hyp_claimpage_c, var_probediscs_p
			dw kw_vtov, var_hyp_claimpage_claimpage, var_dp
			dw kw_ztov, var_probediscs_j
for55_t:
			dw kw_mulvl, var_probediscs_j, 6, tmp1
			dw kw_addl, tmp1, 21504, var_probediscs_a
			dw kw_vptrtov8, var_probediscs_a, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, if56_1
			dw kw_addl, var_probediscs_a, 2, tmp0
			dw kw_vptrtov8, tmp0, tmp0
			dw kw_addl, var_probediscs_a, 3, tmp1
			dw kw_vptrtov8, tmp1, tmp1
			dw kw_mulvl, tmp1, 256, tmp1
			dw kw_add, tmp0, tmp1, var_probediscs_pg
			dw p_hyp_claimpage_c, var_probediscs_pg
			dw kw_vtov, var_hyp_claimpage_claimpage, var_probediscs_r
if56_1:
			dw kw_next1l_n, var_probediscs_j, 255, for55_t
for55_e:
			dw fn_memory_selectpage, var_dp, var_probediscs_r
			dw p_hyp_usedriver_c, vp_arr_rb
			dw kw_ltov, -1, var_probediscs_probediscs
			dw p_probediscs_r
if54_1:
if52_1:
if51_1:
			dw kw_next1v_n, var_probediscs_p, for50_l, for50_t
for50_e:
			dw p_probediscs_r

ntc_rg10_e:
			IF ($ < 32768) && (ntc_rg11_e - ntc_rg11 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg11:
; ============================================================
; function nearp (normal mode)
; ============================================================

p_nearp:
			dw kw_l_itol, var_nearp_p, var_nearp_nearp
			dw kw_scpltvl, var_nearp_p, 0
			dw kw_goto_iffalse_n, if57_1
			dw kw_l_add, var_nearp_nearp, llit_65536, var_nearp_nearp
if57_1:
			dw p_nearp_r

ntc_rg11_e:
			IF ($ < 32768) && (ntc_rg12_e - ntc_rg12 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg12:
; ============================================================
; function far (normal mode)
; ============================================================

p_far:
			dw asm_0_695_n
			dw p_far_r

ntc_rg12_e:
			IF ($ < 32768) && (ntc_rg13_e - ntc_rg13 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg13:
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
			dw fn_hyp_info, lit_5, var_install_p
			dw fn_hyp_info, lit_6, var_install_n
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m48
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy
			dw kw_ztov, var_install_n
for58_t:
			dw kw_4x, var_install_n, tmp2
			dw kw_addl, tmp2, -47, tmp1
			dw p_far_c, var_install_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_aget, arr_sg, var_install_t, tmp1
			dw kw_andvl, tmp1, -8, tmp1
			dw kw_addl, var_install_n, 4, tmp2
			dw kw_orvv, tmp1, tmp2, tmp1
			dw fn_hyp_seg, tmp1, var_hyp_seg_seg
			dw kw_vtov, var_hyp_seg_seg, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1
			dw kw_4x, var_install_n, tmp2
			dw kw_addl, tmp2, -21, tmp1
			dw p_far_c, var_install_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_hyp_seg, var_install_n, var_hyp_seg_seg
			dw kw_vtov, var_hyp_seg_seg, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1
			dw kw_next1l_n, var_install_n, 2, for58_t
for58_e:
			dw p_far_c, var_install_t, lit_m2432
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw p_far_c, var_install_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw kw_ztov, var_install_n
for59_t:
			dw kw_addl, var_install_n, -256, tmp1
			dw p_far_c, var_install_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0
			dw kw_next1l_n, var_install_n, 31, for59_t
for59_e:
			dw p_install_r

ntc_rg13_e:
			IF ($ < 32768) && (ntc_rg14_e - ntc_rg14 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg14:
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

ntc_rg14_e:
			IF ($ < 32768) && (ntc_rg15_e - ntc_rg15 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg15:
; ============================================================
; sub usedriver (normal mode)
; ============================================================

p_hyp_usedriver:
			dw kw_vtov, var_hyp_usedriver_b, var_hyp_dxb
			dw asm_1_68_n
			dw p_hyp_usedriver_r

ntc_rg15_e:
			IF ($ < 32768) && (ntc_rg16_e - ntc_rg16 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg16:
; ============================================================
; function claimpage (normal mode)
; ============================================================

p_hyp_claimpage:
			dw asm_1_78_n
			dw p_hyp_claimpage_r

ntc_rg16_e:
			IF ($ < 32768) && (ntc_rg17_e - ntc_rg17 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg17:
; ============================================================
; sub con (normal mode)
; ============================================================

p_hyp_con:
			dw asm_1_304_n
			dw p_hyp_con_r

ntc_rg17_e:
			IF ($ < 32768) && (ntc_rg18_e - ntc_rg18 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg18:
; ============================================================
; sub say (normal mode)
; ============================================================

p_hyp_say:
			dw asm_1_1652_n
			dw p_hyp_say_r

ntc_rg18_e:
			IF ($ < 32768) && (ntc_rg19_e - ntc_rg19 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg19:
; ============================================================
; function scr (normal mode)
; ============================================================

p_hyp_scr:
			dw asm_1_1777_n
			dw p_hyp_scr_r

ntc_rg19_e:
			IF ($ < 32768) && (ntc_rg20_e - ntc_rg20 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg20:
; ============================================================
; sub keyrep (normal mode)
; ============================================================

p_hyp_keyrep:
			dw asm_1_1940_n
			dw p_hyp_keyrep_r

ntc_rg20_e:
			IF ($ < 32768) && (ntc_rg21_e - ntc_rg21 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg21:
; ============================================================
; sub reply (normal mode)
; ============================================================

p_hyp_reply:
			dw kw_vtov, var_hyp_reply_a, var_hyp_ra
			dw kw_vtov, var_hyp_reply_hl, var_hyp_rhl
			dw p_hyp_reply_r

ntc_rg21_e:
			IF ($ < 32768) && (ntc_rg22_e - ntc_rg22 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg22:
; ============================================================
; function fn (normal mode)
; ============================================================

p_hyp_fn:
			dw kw_andvl, var_hyp_rfn, 255, var_hyp_fn_fn
			dw p_hyp_fn_r

ntc_rg22_e:
			IF ($ < 32768) && (ntc_rg23_e - ntc_rg23 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg23:
; ============================================================
; function arg (normal mode)
; ============================================================

p_hyp_arg:
			dw kw_vtov, var_hyp_rde, var_hyp_arg_arg
			dw p_hyp_arg_r

ntc_rg23_e:
			IF ($ < 32768) && (ntc_rg24_e - ntc_rg24 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg24:
; ============================================================
; function count (normal mode)
; ============================================================

p_hyp_count:
			dw kw_vtov, var_hyp_rcnt, var_hyp_count_count
			dw p_hyp_count_r

ntc_rg24_e:
			IF ($ < 32768) && (ntc_rg25_e - ntc_rg25 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg25:
; ============================================================
; function run (normal mode)
; ============================================================

p_hyp_run:
			dw asm_1_2008_n
			dw p_hyp_run_r

ntc_rg25_e:
			IF ($ < 32768) && (ntc_rg26_e - ntc_rg26 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg26:
; ============================================================
; function t300 (normal mode)
; ============================================================

p_hyp_t300:
			dw asm_1_2125_n
			dw p_hyp_t300_r

ntc_rg26_e:
			IF ($ < 32768) && (ntc_rg27_e - ntc_rg27 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg27:
; ============================================================
; sub vdu (normal mode)
; ============================================================

p_hyp_vdu:
			dw asm_1_3760_n
			dw p_hyp_vdu_r

ntc_rg27_e:
			IF ($ < 32768) && (ntc_rg28_e - ntc_rg28 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg28:
; ============================================================
; function filecall (normal mode)
; ============================================================

p_hyp_filecall:
			dw asm_1_3817_n
			dw p_hyp_filecall_r

ntc_rg28_e:
			IF ($ < 32768) && (ntc_rg29_e - ntc_rg29 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg29:
; ============================================================
; sub fileshut (normal mode)
; ============================================================

p_hyp_fileshut:
			dw asm_1_5850_n
			dw p_hyp_fileshut_r

ntc_rg29_e:
			IF ($ < 32768) && (ntc_rg30_e - ntc_rg30 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg30:
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

ntc_rg30_e:
			IF ($ < 32768) && (ntc_rg31_e - ntc_rg31 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg31:
; ============================================================
; sub bootdrive (normal mode)
; ============================================================

p_hyp_bootdrive:
			dw kw_vtov, var_hyp_bootdrive_d, var_hyp_svbd
			dw kw_vtov, var_hyp_bootdrive_vdv, var_hyp_svdv
			dw p_hyp_bootdrive_r

ntc_rg31_e:
			IF ($ < 32768) && (ntc_rg32_e - ntc_rg32 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg32:
; ============================================================
; function svc (normal mode)
; ============================================================

p_hyp_svc:
			dw asm_1_5940_n
			dw p_hyp_svc_r

ntc_rg32_e:
			IF ($ < 32768) && (ntc_rg33_e - ntc_rg33 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg33:
; ============================================================
; function drive (normal mode)
; ============================================================

p_hyp_drive:
			dw asm_1_9123_n
			dw p_hyp_drive_r

ntc_rg33_e:
			IF ($ < 32768) && (ntc_rg34_e - ntc_rg34 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg34:
; ============================================================
; sub speed (normal mode)
; ============================================================

p_hot_speed:
			dw kw_scpltvl, var_hot_speed_f, 1
			dw kw_goto_iffalse_n, if60_1
			dw kw_ltov, 1, var_hot_speed_f
if60_1:
			dw kw_scpgtvl, var_hot_speed_f, 40
			dw kw_goto_iffalse_n, if61_1
			dw kw_ltov, 40, var_hot_speed_f
if61_1:
			dw kw_mulvl, var_hot_speed_f, 15, var_hot_dbl
			dw p_hot_speed_r

ntc_rg34_e:
			IF ($ < 32768) && (ntc_rg35_e - ntc_rg35 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg35:
; ============================================================
; sub slots (normal mode)
; ============================================================

p_hot_slots:
			dw kw_vtov, var_hot_slots_n, var_hot_ns
			dw p_hot_slots_r

ntc_rg35_e:
			IF ($ < 32768) && (ntc_rg36_e - ntc_rg36 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg36:
; ============================================================
; sub tick (normal mode)
; ============================================================

p_hot_tick:
			dw fn_hot_row, lit_6, var_hot_row_row
			dw kw_vtov, var_hot_row_row, tmp6
			dw kw_andvl, tmp6, 2, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_ftov, var_hot_ctl
			dw kw_goto_ifzero_n, var_hot_ctl, if62_1
			dw fn_hot_row, lit_0, var_hot_tick_i
			dw kw_ltov, 2, var_hot_tick_j
			dw kw_ltov, 1, var_hot_tick_k
for63_t:
			dw kw_andvv, var_hot_tick_i, var_hot_tick_j, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if64_1
			dw for63_e_go
if64_1:
			dw kw_2x, var_hot_tick_j, var_hot_tick_j
			dw kw_next1l_n, var_hot_tick_k, 7, for63_t
for63_e:
			dw kw_scpgtvl, var_hot_tick_k, 7
			dw kw_goto_iffalse_n, if65_1
			dw kw_ztov, var_hot_tick_k
if65_1:
			dw kw_andvl, var_hot_tick_i, 1, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if66_1
			dw kw_ltov, 10, var_hot_tick_k
if66_1:
			dw fn_hot_row, lit_1, var_hot_tick_i
			dw kw_andvl, var_hot_tick_i, 1, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if67_1
			dw kw_ltov, 8, var_hot_tick_k
if67_1:
			dw kw_andvl, var_hot_tick_i, 2, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if68_1
			dw kw_ltov, 9, var_hot_tick_k
if68_1:
			dw fn_hot_row, lit_7, var_hot_row_row
			dw kw_vtov, var_hot_row_row, tmp6
			dw kw_andvl, tmp6, 4, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if69_1
			dw kw_ltov, 99, var_hot_tick_k
if69_1:
if62_1:
			dw kw_cpnevl, var_hot_tick_k, 0
			dw kw_ftov, tmp6
			dw kw_cpnevv, var_hot_tick_k, var_hot_last
			dw kw_ftov, tmp7
			dw kw_andvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if70_1
			dw kw_cpeqvl, var_hot_tick_k, 99
			dw kw_ftov, tmp6
			dw kw_scplevl, var_hot_ns, 10
			dw kw_ftov, tmp7
			dw kw_orvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if71_1
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if72_1
			dw kw_ztov, var_hot_one
if72_1:
			dw kw_vtov, var_hot_tick_k, var_hot_pend
			dw if71_e_go
if71_1:
			dw kw_cpeqvv, var_hot_one, var_hot_tick_k
			dw kw_goto_iffalse_n, if71_2
			dw kw_ztov, var_hot_one
			dw kw_addl, var_hot_tick_k, 10, tmp6
			dw kw_scplevv, tmp6, var_hot_ns
			dw kw_goto_iffalse_n, if73_1
			dw kw_addl, var_hot_tick_k, 10, var_hot_pend
			dw if71_e_go
if73_1:
			dw kw_vtov, var_hot_tick_k, var_hot_pend
if73_e:
			dw if71_e_go
if71_2:
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if74_1
			dw kw_vtov, var_hot_one, var_hot_pend
if74_1:
			dw kw_vtov, var_hot_tick_k, var_hot_one
			dw kw_ztov, var_hot_age
if71_e:
if70_1:
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if75_1
			dw kw_inc, var_hot_age
			dw kw_cpeqvl, var_hot_dbl, 0
			dw kw_goto_iffalse_n, if76_1
			dw kw_ltov, 15, var_hot_dbl
if76_1:
			dw kw_scpgtvv, var_hot_age, var_hot_dbl
			dw kw_ftov, tmp6
			dw kw_cpeqvl, var_hot_ctl, 0
			dw kw_ftov, tmp7
			dw kw_orvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if77_1
			dw kw_vtov, var_hot_one, var_hot_pend
			dw kw_ztov, var_hot_one
if77_1:
if75_1:
			dw kw_vtov, var_hot_tick_k, var_hot_last
			dw p_hot_tick_r

ntc_rg36_e:
			IF ($ < 32768) && (ntc_rg37_e - ntc_rg37 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg37:
; ============================================================
; function take (normal mode)
; ============================================================

p_hot_take:
			dw kw_vtov, var_hot_pend, var_hot_take_take
			dw kw_ztov, var_hot_pend
			dw p_hot_take_r

ntc_rg37_e:
			IF ($ < 32768) && (ntc_rg38_e - ntc_rg38 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg38:
; ============================================================
; function control (normal mode)
; ============================================================

p_hot_control:
			dw kw_vtov, var_hot_ctl, var_hot_control_control
			dw p_hot_control_r

ntc_rg38_e:
			IF ($ < 32768) && (ntc_rg39_e - ntc_rg39 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg39:
; ============================================================
; function held (normal mode)
; ============================================================

p_hot_held:
			dw kw_vtov, var_hot_last, var_hot_held_held
			dw p_hot_held_r

ntc_rg39_e:
			IF ($ < 32768) && (ntc_rg40_e - ntc_rg40 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg40:
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
do11_t_go:			ld sp, do11_t
			jp ntc_xn
ch20_e_go:			ld sp, ch20_e
			jp ntc_xn
do18_e_go:			ld sp, do18_e
			jp ntc_xn
do18_t_go:			ld sp, do18_t
			jp ntc_xn
sel17_e_go:			ld sp, sel17_e
			jp ntc_xn
ch31_e_go:			ld sp, ch31_e
			jp ntc_xn
if32_e_go:			ld sp, if32_e
			jp ntc_xn
sel33_e_go:			ld sp, sel33_e
			jp ntc_xn
if48_e_go:			ld sp, if48_e
			jp ntc_xn
for63_e_go:			ld sp, for63_e
			jp ntc_xn
if71_e_go:			ld sp, if71_e
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
p_hyp_run_c:		; call run (normal)
			pop hl			; setting
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_run_setting), de
			ld hl, 0
			ld (var_hyp_run_run), hl
			ld (p_hyp_run_rs), sp
			ld sp, p_hyp_run
			jp ntc_xn
p_hyp_run_r:		; end of run
			ld sp, (p_hyp_run_rs)
			jp ntc_xn
p_hyp_t300_c:		; call t300 (normal)
			ld hl, 0
			ld (var_hyp_t300_t300), hl
			ld (p_hyp_t300_rs), sp
			ld sp, p_hyp_t300
			jp ntc_xn
p_hyp_t300_r:		; end of t300
			ld sp, (p_hyp_t300_rs)
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
			ld hl, 0
			ld (var_hot_tick_i), hl
			ld hl, 0
			ld (var_hot_tick_j), hl
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

ntc_rg40_e:
			IF ($ < 32768) && (ntc_rg41_e - ntc_rg41 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg41:
; ============================================================
; Inline assembly (#asm ... #endasm)
; ============================================================

asm_0_71_n:		; #asm, Main.bas line 71 (normal)
    IFDEF NTC_MSXDOS
            ; MSX: the screen TEXT 2 (80 columns) on the V9938 straight (not the BIOS's: its
            ; name table a ring of 32 rows for the vertical scroll, Hyp's msx_vrow), the font from
            ; the main ROM's (CGTABL, through RDSLT: the DOS's page 0) into its pattern table
            ld (ntc_ip), sp
            ld sp, (ntc_csp)
            di
            ld hl, asm_0_71_n_vdp_regs
asm_0_71_n_vdp_rl:     ld a, (hl)
            inc hl
            cp #FF
            jr z, asm_0_71_n_vdp_rd
            out (#99), a
            ld a, (hl)
            inc hl
            out (#99), a
            jr asm_0_71_n_vdp_rl
asm_0_71_n_vdp_rd:     ld a, (#FFE8)          ; R#9: 212 lines (26.5 rows), the PAL / NTSC bit as the BIOS had it
            and #02
            or #80
            out (#99), a
            ld a, #80 + 9
            out (#99), a
            ld hl, #0A00           ; the blink table: none
            call msx_vwa
            ld b, 0
            xor a
asm_0_71_n_vdp_bl:     out (#98), a
            djnz asm_0_71_n_vdp_bl
            call msx_vclr
            ld a, (#FCC1)          ; EXPTBL: the main ROM's slot
            ld hl, 4               ; CGTABL: where its font is
            push af
            call #000C             ; RDSLT
            ld e, a
            pop af
            push af
            inc hl
            call #000C
            ld d, a
            pop af
            ex de, hl              ; HL = the font
            push af
            push hl
            ld hl, #1000           ; the pattern table
            call msx_vwa
            pop hl
            pop af
            ld bc, #0008           ; 2048 bytes: B 0 (256), C 8
asm_0_71_n_vdp_fl:     push af
            push bc
            call #000C             ; (interrupts off after it)
            out (#98), a
            pop bc
            pop af
            inc hl
            djnz asm_0_71_n_vdp_fl
            dec c
            jr nz, asm_0_71_n_vdp_fl
            di
            ld sp, (ntc_ip)
            jr asm_0_71_n_vdp_end
; R#0 TEXT 2, R#1 on + the frame interrupt + text, R#2 the name table #0000, R#3 / R#10 the blink
; table #0A00, R#4 the patterns #1000, R#7 light yellow on dark blue (the CPC's colours), R#8 as
; the BIOS's, R#12 / R#13 no blink, R#14 0, R#23 0 (the scroll)
asm_0_71_n_vdp_regs:   db #04, #80, #70, #81, #03, #82, #2F, #83, #00, #8A, #02, #84, #B4, #87, #08, #88
            db #00, #8C, #00, #8D, #00, #8E, #00, #97, #FF
asm_0_71_n_vdp_end:
    ENDIF
			ret			; end of #asm

fn_kin:		; sub kin (asm keyword), Main.bas line 421
            ld (var_ksp), sp          ; (the real stack: the Next's window is a call)
            ld sp, (ntc_csp)
            ld bc, (var_kwp)          ; the kernel's page 3 in the window: its #EE00 at #6E00
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld hl, 60928 - #8000
            ld de, arr_kw
            ld bc, 32
            ldir
            ld bc, (ntc_rampt)      ; the page that was in the window back
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld sp, (var_ksp)
			ret			; end of #asm

fn_kout:		; sub kout (asm keyword), Main.bas line 446
            ld (var_ksp), sp
            ld sp, (ntc_csp)
            ld bc, (var_kwp)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld hl, arr_kw + 16
            ld de, 60928 - #8000 + 16
            ld bc, 16
            ldir
            ld bc, (ntc_rampt)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld sp, (var_ksp)
			ret			; end of #asm

asm_0_471_n:		; #asm, Main.bas line 471 (normal)
            ld (var_ksp), sp
            ld sp, (ntc_csp)
            ld bc, (var_kwp)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld hl, 60928 - #8000 + 32
            ld de, (var_kdin_p)
            ld bc, (var_kdin_n)
            ld a, b
            or c
            jr z, asm_0_471_n_kdi_none
            ldir
asm_0_471_n_kdi_none:
            xor a
            ld (de), a
            ld bc, (ntc_rampt)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld sp, (var_ksp)
			ret			; end of #asm

asm_0_502_n:		; #asm, Main.bas line 502 (normal)
            ld (var_ksp), sp
            ld sp, (ntc_csp)
            ld bc, (var_kwp)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld hl, (var_kdout_p)
            ld de, 60928 - #8000 + 32
            ld bc, (var_kdout_n)
            ld a, b
            or c
            jr z, asm_0_502_n_kdo_none
            ldir
asm_0_502_n_kdo_none:
            ld bc, (ntc_rampt)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld sp, (var_ksp)
			ret			; end of #asm

asm_0_695_n:		; #asm, Main.bas line 695 (normal)
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

fn_hyp_usepage:		; sub usepage (asm keyword), Hyp.cls line 58
            ld hl, (ntc_rampt)
            ld (var_hyp_hps), hl
			ret			; end of #asm

asm_1_68_n:		; #asm, Hyp.cls line 68 (normal)
            ld hl, (ntc_rampt)
            ld (var_hyp_drs), hl
			ret			; end of #asm

asm_1_78_n:		; #asm, Hyp.cls line 78 (normal)
            ld hl, (var_hyp_claimpage_page)
            ld a, h
            or l
            jr z, asm_1_78_n_cp_no
            ld de, (mem_count)
            ex de, hl
            or a
            sbc hl, de              ; page - count: carry means page > count
            jr c, asm_1_78_n_cp_no
            ld hl, (var_hyp_claimpage_page)         ; the RAT byte: (mem_ttype) + page - 1
            ld de, (mem_ttype)
            add hl, de
            dec hl
            ld a, (hl)
            cp "-"                  ; free?
            jr nz, asm_1_78_n_cp_no
            ld (hl), "U"            ; TypeUser
            ld hl, (var_hyp_claimpage_page)
            jr asm_1_78_n_cp_done
asm_1_78_n_cp_no:
            ld hl, 0
asm_1_78_n_cp_done:
            ld (var_hyp_claimpage_claimpage), hl
			ret			; end of #asm

fn_hyp_setting:		; function setting (asm keyword), Hyp.cls line 106
            ld de, (ntc_rampt)      ; (zxn: the Next's setting is shaped as the CPC's - B = ZXN_SETB, C = the
            ld a, e                 ; 64K bank's ordinal * 8 + 4 + page - so this arithmetic holds there too)
            and #F8
            or 2
            ld e, a
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
			ret			; end of #asm

fn_hyp_farptr:		; function farptr (asm keyword), Hyp.cls line 122
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

fn_hyp_fontinit:		; sub fontinit (asm keyword), Hyp.cls line 175
    IFDEF NTC_MSXDOS
            ret                     ; ZX Next: the tilemap renders char codes via its own tiles;
                                    ; no CPC font needed, and #F300 would clobber the tiles
    ELSE
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
    ENDIF
			ret			; end of #asm

asm_1_304_n:		; #asm, Hyp.cls line 304 (normal)
; CN_SB 1: the scrollback (Shift + Up / Down: 48 rows a slot, kept in a 16K page Main gives - #If
; SCROLLBACK in Main.bas, set the two together). Off for now: 526 bytes of main RAM (2026-10-16)
asm_1_304_n_CN_SB:      equ 0
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld bc, (var_hyp_con_pg)
    IFNDEF NTC_MSXDOS
            out (c), c              ; the slot's page 3 at #4000: OBUF #7600, state #7682, page #7700
    ELSE
            call msx_win            ; zxn: the slot's page 3 (its setting or 7, as the CPC's) into the window via the MMU
    ENDIF
            IF asm_1_304_n_CN_SB
            ld (asm_1_304_n_cn_pg), bc
            ENDIF
            xor a
            ld (asm_1_304_n_cn_pv), a
            ld a, (var_hyp_con_front)
            ld (asm_1_304_n_cn_front), a
            ld a, (#7687)           ; its columns and rows (MODE)
            ld (asm_1_304_n_cn_c), a
            ld a, (#7688)
            ld (asm_1_304_n_cn_r), a
            ld a, (var_hyp_ccu)           ; the cursor off first, whatever comes (it was on: cn_was)
            ld (asm_1_304_n_cn_was), a
            or a
            call nz, asm_1_304_n_cn_cuxor
            ld hl, (var_hyp_con_n)
            bit 7, h
            jp nz, asm_1_304_n_cn_neg
            ld (asm_1_304_n_cn_left), hl
            IF asm_1_304_n_CN_SB
            ld a, (asm_1_304_n_cn_front)        ; in front and looking back (scrollback): the page again first
            or a
            jr z, asm_1_304_n_cn_live
            ld a, (#7F26)
            or a
            jr z, asm_1_304_n_cn_live
            xor a
            ld (#7F26), a
            call asm_1_304_n_cn_cls
            call asm_1_304_n_cn_strip
            call asm_1_304_n_cn_draw
            ld hl, (asm_1_304_n_cn_left)
asm_1_304_n_cn_live:
            ENDIF
            ld hl, (var_hyp_con_src)
            ld a, h
            or l
            jr nz, asm_1_304_n_cn_src
            ld hl, #7600            ; src 0: the characters the program collected (OBUF)
asm_1_304_n_cn_src:
            ld (asm_1_304_n_cn_ptr), hl
asm_1_304_n_cn_lp:
            ld hl, (asm_1_304_n_cn_left)
            ld a, h
            or l
            jr z, asm_1_304_n_cn_done
            dec hl
            ld (asm_1_304_n_cn_left), hl
            ld hl, (asm_1_304_n_cn_ptr)
            ld a, (hl)
            inc hl
            ld (asm_1_304_n_cn_ptr), hl
            call asm_1_304_n_cn_char
            jr asm_1_304_n_cn_lp
asm_1_304_n_cn_done:
            ld bc, (ntc_rampt)      ; the window's page back
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld sp, (var_hyp_hsp)
            jp asm_1_304_n_cn_end

; n < 0: -1 the whole page to the screen (it was cleared: Show), not looking back any more; -2
; the scrollback (src: the key - #F4 Shift + Up a screen back, #F5 Shift + Down one on), drawn
asm_1_304_n_cn_neg:
            ld a, l
            cp #FD                  ; -3: the cursor flashes - on (it was off), an underline XORed
            jr nz, asm_1_304_n_cn_neg1          ; where the next character goes; off (it was on: done above)
            ld a, (asm_1_304_n_cn_front)
            or a
            jr z, asm_1_304_n_cn_done
            ld a, (var_hyp_nta)           ; the network blink: advance it (0.5s) while there's traffic
            or a
            jr z, asm_1_304_n_cn_nt1
            dec a
            ld (var_hyp_nta), a
            ld a, (var_hyp_ntb)
            xor 1
            ld (var_hyp_ntb), a
asm_1_304_n_cn_nt1:
            call asm_1_304_n_cn_net
            ld a, (asm_1_304_n_cn_was)
            or a
            jr nz, asm_1_304_n_cn_done
            ld a, (#7682)
            ld d, a
            ld a, (#7683)
            ld e, a
            call asm_1_304_n_cn_scr
    IFNDEF NTC_MSXDOS
            ld a, h
            add a, #38              ; (its cell's last pixel line)
            ld h, a
    ENDIF
            ld (asm_1_304_n_cn_ca), hl          ; zxn: cn_ca = the logical cell address as is
            call asm_1_304_n_cn_cuxor
            jr asm_1_304_n_cn_done
asm_1_304_n_cn_neg1:
            IF asm_1_304_n_CN_SB
            inc hl
            ld a, h
            or l
            jr nz, asm_1_304_n_cn_view
            ld (#7F26), a
            ENDIF
asm_1_304_n_cn_show:
            call asm_1_304_n_cn_strip
            call asm_1_304_n_cn_draw
            jr asm_1_304_n_cn_done
            IF asm_1_304_n_CN_SB
asm_1_304_n_cn_view:
            ld a, (#7F21)           ; (no history page: nothing)
            or a
            jr z, asm_1_304_n_cn_done
            ld a, (asm_1_304_n_cn_r)
            dec a
            ld b, a                 ; a screen: its rows - 1
            ld a, (var_hyp_con_src)
            cp #F4
            ld a, (#7F26)
            jr nz, asm_1_304_n_cn_vw_dn
            add a, b
            ld hl, #7F25
            cp (hl)
            jr c, asm_1_304_n_cn_vw_set
            ld a, (hl)              ; (not past the oldest row kept)
            jr asm_1_304_n_cn_vw_set
asm_1_304_n_cn_vw_dn:
            sub b
            jr nc, asm_1_304_n_cn_vw_set
            xor a
asm_1_304_n_cn_vw_set:
            ld hl, #7F26
            cp (hl)
            jr z, asm_1_304_n_cn_done
            ld (hl), a
            call asm_1_304_n_cn_cls
            jr asm_1_304_n_cn_show

            ENDIF

; the screen's rows: the page's - or, looking back (#FF26 rows), the history's first, then the
; page's. Row e shows line count + e - back of history + page (count the rows kept, #FF25)
asm_1_304_n_cn_draw:
            ld e, 0
            IF asm_1_304_n_CN_SB
asm_1_304_n_cn_dr_row:
            push de
            ld a, (#7F25)
            add a, e
            ld hl, #7F26
            sub (hl)                ; the line: count + e - back
            ld hl, #7F25
            sub (hl)
            jr c, asm_1_304_n_cn_dr_h
            call asm_1_304_n_cn_rowa            ; HL = row (line - count) of the page
            ld a, (asm_1_304_n_cn_c)
            jr asm_1_304_n_cn_dr_go
asm_1_304_n_cn_dr_h:
            add a, (hl)
            call asm_1_304_n_cn_hget            ; HL = the history's row (copied in), 80 characters at most
            ld a, (asm_1_304_n_cn_c)
            cp asm_1_304_n_HW
            jr c, asm_1_304_n_cn_dr_go
            ld a, asm_1_304_n_HW
asm_1_304_n_cn_dr_go:
            ld b, a
            pop de
            push de
            ld d, 0
asm_1_304_n_cn_dr_col:
            ld a, (hl)
            inc hl
            cp 33
            jr c, asm_1_304_n_cn_dr_sk
            push hl
            push de
            push bc
            call asm_1_304_n_cn_glyph
            pop bc
            pop de
            pop hl
asm_1_304_n_cn_dr_sk:
            inc d
            djnz asm_1_304_n_cn_dr_col
            pop de
            inc e
            ld a, (asm_1_304_n_cn_r)
            dec a
            cp e
            jr nc, asm_1_304_n_cn_dr_row
            ret
            ELSE
asm_1_304_n_cn_sh_row:                          ; (no scrollback: the page's rows as they are)
            push de
            ld a, e
            call asm_1_304_n_cn_rowa            ; HL = row e of the page
            pop de
            ld d, 0
asm_1_304_n_cn_sh_col:
            ld a, (hl)
            inc hl
            cp 33
            jr c, asm_1_304_n_cn_sh_skip
            push hl
            push de
            call asm_1_304_n_cn_glyph
            pop de
            pop hl
asm_1_304_n_cn_sh_skip:
            inc d
            ld a, (asm_1_304_n_cn_c)
            dec a
            cp d
            jr nc, asm_1_304_n_cn_sh_col
            inc e
            ld a, (asm_1_304_n_cn_r)
            dec a
            cp e
            jr nc, asm_1_304_n_cn_sh_row
            ret
            ENDIF

            IF asm_1_304_n_CN_SB
; the scrollback: each row that scrolls off the top of the page - its first HW characters - goes
; to the slot's history: HROWS rows (a ring) in a 16K page of its own that Main gave it (#FF20:
; its RAM setting, 0 none; #FF22 where in it; #FF24 the next row written, #FF25 how many, #FF26
; how far back the screen looks). Copied 8 bytes at a time through the stack - only the window
; changes, so no main RAM for a buffer
asm_1_304_n_HW:         equ 80
asm_1_304_n_HROWS:      equ 48
asm_1_304_n_cn_hput:                            ; HL = the row going (the page)
            ld a, (#7F21)
            or a
            ret z
            ld (asm_1_304_n_cn_hs), hl
            ld hl, (asm_1_304_n_cn_pg)
            ld (asm_1_304_n_cn_h1), hl
            ld hl, (#7F20)
            ld (asm_1_304_n_cn_h2), hl
            ld a, (#7F24)
            call asm_1_304_n_cn_haddr
            ld (asm_1_304_n_cn_hd), hl
            ld hl, #7F24            ; the next row on, one more kept
            ld a, (hl)
            inc a
            cp asm_1_304_n_HROWS
            jr c, asm_1_304_n_cn_hp_h
            xor a
asm_1_304_n_cn_hp_h:
            ld (hl), a
            inc hl
            ld a, (hl)
            cp asm_1_304_n_HROWS
            jr nc, asm_1_304_n_cn_hcp
            inc (hl)
; cn_hcp: HW bytes from cn_hs in RAM setting cn_h1 to cn_hd in cn_h2, then the slot's page back
asm_1_304_n_cn_hcp:
            ld a, asm_1_304_n_HW / 8
asm_1_304_n_cn_hc_lp:
            ld (asm_1_304_n_cn_hn), a
            ld bc, (asm_1_304_n_cn_h1)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld hl, (asm_1_304_n_cn_hs)
            ld b, 4
asm_1_304_n_cn_hc_in:
            ld e, (hl)
            inc hl
            ld d, (hl)
            inc hl
            push de
            djnz asm_1_304_n_cn_hc_in
            ld (asm_1_304_n_cn_hs), hl
            ld bc, (asm_1_304_n_cn_h2)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld hl, (asm_1_304_n_cn_hd)
            ld de, 8
            add hl, de
            ld (asm_1_304_n_cn_hd), hl
            ld b, 4
asm_1_304_n_cn_hc_out:
            pop de
            dec hl
            ld (hl), d
            dec hl
            ld (hl), e
            djnz asm_1_304_n_cn_hc_out
            ld a, (asm_1_304_n_cn_hn)
            dec a
            jr nz, asm_1_304_n_cn_hc_lp
            ld bc, (asm_1_304_n_cn_pg)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ret
asm_1_304_n_cn_hget:                            ; A = a line of the history (0 the oldest kept): copied to
            ld hl, #7F24            ; #FF30 in the slot's page (HL)
            add a, (hl)
            inc hl
            sub (hl)
            jr nc, asm_1_304_n_cn_hg_r
            add a, asm_1_304_n_HROWS
asm_1_304_n_cn_hg_r:
            call asm_1_304_n_cn_haddr
            ld (asm_1_304_n_cn_hs), hl
            ld hl, (#7F20)
            ld (asm_1_304_n_cn_h1), hl
            ld hl, (asm_1_304_n_cn_pg)
            ld (asm_1_304_n_cn_h2), hl
            ld hl, #7F30
            ld (asm_1_304_n_cn_hd), hl
            call asm_1_304_n_cn_hcp
            ld hl, #7F30
            ret
asm_1_304_n_cn_haddr:                           ; A = a history row: HL = its address in the history page
            ld e, a
            ld a, asm_1_304_n_HW
            call asm_1_304_n_cn_mul
            ld de, (#7F22)
            add hl, de
            ret
; cn_cls: the screen cleared (written only: the Library: ROM build's keyword ROM may be over it)
asm_1_304_n_cn_cls:
    IFDEF NTC_MSXDOS
            jp msx_vclr             ; MSX: the name table (32 rows) all spaces
    ENDIF
            ld hl, #C000
            ld bc, #4000
asm_1_304_n_cn_cl_lp:
            ld (hl), 0
            inc hl
            dec bc
            ld a, b
            or c
            jr nz, asm_1_304_n_cn_cl_lp
            ret
            ENDIF

; cn_char: A = one character
asm_1_304_n_cn_char:
            ld b, a
            ld a, (#7685)           ; in an escape sequence?
            or a
            jr nz, asm_1_304_n_cn_esc0
            ld a, b
            cp 32
            jp nc, asm_1_304_n_cn_print
            ld hl, asm_1_304_n_cn_pv            ; a control code: the cursor may move (the pointers redone)
            ld (hl), 0
            cp 27
            jr z, asm_1_304_n_cn_setesc
            cp 13
            jr z, asm_1_304_n_cn_cr
            cp 10
            jp z, asm_1_304_n_cn_nl
            cp 9
            jr z, asm_1_304_n_cn_tab
            cp 8
            ret nz                  ; other control codes: nothing
            ld a, (#7682)           ; BS: back one (not past the start of the row)
            or a
            ret z
            dec a
            ld (#7682), a
            ret
asm_1_304_n_cn_tab:                             ; TAB: spaces to the next column of 8
            ld b, ' '
            call asm_1_304_n_cn_print
            ld a, (#7682)
            and 7
            jr nz, asm_1_304_n_cn_tab
            ret
asm_1_304_n_cn_setesc:
            ld a, 1
            ld (#7685), a
            ret
asm_1_304_n_cn_cr:
            xor a
            ld (#7682), a
            ret
asm_1_304_n_cn_esc0:
            ld hl, asm_1_304_n_cn_pv
            ld (hl), 0
asm_1_304_n_cn_esc:
            cp 1
            jr nz, asm_1_304_n_cn_esc2
            xor a                   ; ESC x
            ld (#7685), a
            ld a, b
            cp 'E'
            jp z, asm_1_304_n_cn_clear
            cp 'H'
            jr z, asm_1_304_n_cn_home
            cp 'I'
            jp z, asm_1_304_n_cn_rev
            cp 'Y'
            jr z, asm_1_304_n_cn_sety
            cp 'A'
            jr z, asm_1_304_n_cn_up
            cp 'B'
            jr z, asm_1_304_n_cn_down
            cp 'C'
            jr z, asm_1_304_n_cn_right
            cp 'D'
            jr z, asm_1_304_n_cn_lft
            cp 'K'
            jp z, asm_1_304_n_cn_eol
            cp 'J'
            jp z, asm_1_304_n_cn_eos
            cp 'l'
            jp z, asm_1_304_n_cn_eln
            cp 'o'
            jp z, asm_1_304_n_cn_sol
            cp 'd'
            jp z, asm_1_304_n_cn_sos
            cp 'M'
            jp z, asm_1_304_n_cn_dell
            cp 'L'
            jp z, asm_1_304_n_cn_insl
            ret                     ; (the rest - e f j k p q ...: nothing)
asm_1_304_n_cn_sety:
            ld a, 2
            ld (#7685), a
            ret
asm_1_304_n_cn_up:                              ; ESC A, B, C, D: up, down, right, left (not past the edge)
            ld hl, #7683
            jr asm_1_304_n_cn_dec
asm_1_304_n_cn_lft:
            ld hl, #7682
asm_1_304_n_cn_dec:
            ld a, (hl)
            or a
            ret z
            dec (hl)
            ret
asm_1_304_n_cn_down:
            ld de, #7683
            ld hl, asm_1_304_n_cn_r
            jr asm_1_304_n_cn_inc
asm_1_304_n_cn_right:
            ld de, #7682
            ld hl, asm_1_304_n_cn_c
asm_1_304_n_cn_inc:
            ld a, (de)
            inc a
            cp (hl)
            ret nc
            ld (de), a
            ret
asm_1_304_n_cn_home:
            xor a
            ld (#7682), a
            ld (#7683), a
            ret
asm_1_304_n_cn_esc2:
            cp 2
            jr nz, asm_1_304_n_cn_esc3
            ld a, b                 ; ESC Y row
            sub 32
            ld (#7686), a
            ld a, 3
            ld (#7685), a
            ret
asm_1_304_n_cn_esc3:
            xor a                   ; ESC Y row col
            ld (#7685), a
            ld a, b
            sub 32
            ld hl, asm_1_304_n_cn_c
            cp (hl)
            jr c, asm_1_304_n_cn_e3_col
            xor a
asm_1_304_n_cn_e3_col:
            ld (#7682), a
            ld a, (#7686)
            ld hl, asm_1_304_n_cn_r
            cp (hl)
            jr c, asm_1_304_n_cn_e3_row
            xor a
asm_1_304_n_cn_e3_row:
            ld (#7683), a
            ret

; a printable character (B): into the page, on the screen if in front, the column on. The page
; and screen pointers are worked out at the first character after the cursor moved (cn_pv 0),
; then just stepped on - a run of characters costs the 8 screen bytes each, not a sum each
asm_1_304_n_cn_print:
            ld a, (asm_1_304_n_cn_pv)
            or a
            jr nz, asm_1_304_n_cn_pr_have
            ld a, (#7683)
            call asm_1_304_n_cn_rowa
            ld a, (#7682)
            ld e, a
            ld d, 0
            add hl, de
            ld (asm_1_304_n_cn_pp), hl
            ld a, (asm_1_304_n_cn_front)
            or a
            jr z, asm_1_304_n_cn_pr_set
            ld a, (#7682)
            ld d, a
            ld a, (#7683)
            ld e, a
            push bc                 ; (B: the character)
            call asm_1_304_n_cn_scr
            pop bc
            ld (asm_1_304_n_cn_sp), hl
asm_1_304_n_cn_pr_set:
            ld a, 1
            ld (asm_1_304_n_cn_pv), a
asm_1_304_n_cn_pr_have:
            ld hl, (asm_1_304_n_cn_pp)          ; the page
            ld (hl), b
            inc hl
            ld (asm_1_304_n_cn_pp), hl
            ld a, (asm_1_304_n_cn_front)
            or a
            jr z, asm_1_304_n_cn_pr_adv
            ld hl, (asm_1_304_n_cn_sp)          ; the screen
            push hl
            ld a, b
            call asm_1_304_n_cn_glyph8
            pop hl
            call asm_1_304_n_cn_next
            ld (asm_1_304_n_cn_sp), hl
asm_1_304_n_cn_pr_adv:
            ld hl, #7682
            inc (hl)
            ld a, (hl)
            ld hl, asm_1_304_n_cn_c
            cp (hl)
            ret c
            xor a                   ; past the last column: the next row
            ld (#7682), a
            ld (asm_1_304_n_cn_pv), a
; a line feed: the next row, or the page (and the screen) scroll
asm_1_304_n_cn_nl:
            ld a, (#7683)
            inc a
            ld hl, asm_1_304_n_cn_r
            cp (hl)
            jr nc, asm_1_304_n_cn_scroll
            ld (#7683), a
            ret
asm_1_304_n_cn_scroll:
            ld a, (#7684)           ; the ring's top row moves on (no copy)
            inc a
            cp (hl)
            jr c, asm_1_304_n_cn_sc_top
            xor a
asm_1_304_n_cn_sc_top:
            ld (#7684), a
            ld a, (asm_1_304_n_cn_r)
            dec a
            call asm_1_304_n_cn_rowa            ; the new last row cleared (the old top row: kept first)
            IF asm_1_304_n_CN_SB
            push hl
            call asm_1_304_n_cn_hput
            pop hl
            ENDIF
            ld a, (asm_1_304_n_cn_c)
            ld b, a
asm_1_304_n_cn_sc_cl:
            ld (hl), ' '
            inc hl
            djnz asm_1_304_n_cn_sc_cl
            ld a, (asm_1_304_n_cn_front)
            or a
            ret z
    IFDEF NTC_MSXDOS
            ld a, (var_hyp_sco)           ; MSX: the screen's top row (of the name table's 32) a row on - the
            inc a                   ; V9938's vertical scroll (R#23) -, the new last row cleared
            and 31
            ld (var_hyp_sco), a
            call asm_1_304_n_cn_crtc
            ld a, (asm_1_304_n_cn_r)
            dec a
            ld e, a
            jp asm_1_304_n_cn_sc_clr
    ENDIF
            ld hl, (var_hyp_sco)          ; the screen: its start a row on (R12, R13), the new last row
            ld de, (var_hyp_scc)          ; cleared, the status strip again (it went off the top)
            add hl, de
            ld a, h
            and #07
            ld h, a
            ld (var_hyp_sco), hl
            call asm_1_304_n_cn_crtc
            ld a, (asm_1_304_n_cn_r)
            dec a
            ld e, a
asm_1_304_n_cn_sc_clr:                          ; E = a screen row: cleared, then the status strip again
    IFDEF NTC_MSXDOS
            ld a, e                 ; MSX: that row, and the rows under the console down to the
            call msx_vclrow         ; screen's last (26: TEXT 2's 26.5) - the scroll brings old
            ld a, (asm_1_304_n_cn_r)            ; rows of the name table's ring in there
asm_1_304_n_cn_sc_ms:
            cp 27
            jp nc, asm_1_304_n_cn_strip
            push af
            call msx_vclrow
            pop af
            inc a
            jr asm_1_304_n_cn_sc_ms
    ENDIF
            ld d, 0
            call asm_1_304_n_cn_scr
            ld b, 8
asm_1_304_n_cn_sc_ln:
            push bc
            push hl
            ld a, (var_hyp_scc)
            ld b, a
asm_1_304_n_cn_sc_b:
            ld (hl), 0
            call asm_1_304_n_cn_next
            djnz asm_1_304_n_cn_sc_b
            pop hl
            ld a, h
            add a, 8
            ld h, a
            pop bc
            djnz asm_1_304_n_cn_sc_ln
            jp asm_1_304_n_cn_strip

; ESC I (reverse line feed): the row before, or on the top row the page (and the screen) scroll
; back: the ring's top row a row back, the new top row cleared; on the screen its start a row
; back (R12, R13) and the new top row cleared - the line feed's scroll the other way
asm_1_304_n_cn_rev:
            ld a, (#7683)
            or a
            jr z, asm_1_304_n_cn_rv_sc
            dec a
            ld (#7683), a
            ret
asm_1_304_n_cn_rv_sc:
            ld a, (#7684)
            or a
            jr nz, asm_1_304_n_cn_rv_top
            ld a, (asm_1_304_n_cn_r)
asm_1_304_n_cn_rv_top:
            dec a
            ld (#7684), a
            xor a
            call asm_1_304_n_cn_rowa            ; (row 0 of the page now)
            ld a, (asm_1_304_n_cn_c)
            ld b, a
asm_1_304_n_cn_rv_cl:
            ld (hl), ' '
            inc hl
            djnz asm_1_304_n_cn_rv_cl
            ld a, (asm_1_304_n_cn_front)
            or a
            ret z
    IFDEF NTC_MSXDOS
            ld a, (var_hyp_sco)           ; MSX: the top row a row back (R#23), the new top row cleared
            dec a
            and 31
            ld (var_hyp_sco), a
            call asm_1_304_n_cn_crtc
            ld e, 0
            jp asm_1_304_n_cn_sc_clr
    ENDIF
            ld hl, (var_hyp_sco)
            ld de, (var_hyp_scc)
            or a
            sbc hl, de
            ld a, h
            and #07
            ld h, a
            ld (var_hyp_sco), hl
            call asm_1_304_n_cn_crtc
            ld e, 0
            jp asm_1_304_n_cn_sc_clr

; ESC K the row from the cursor on cleared, J the rest of the page too, l the whole row, o the
; row up to the cursor, d the page up to it; M the cursor's row deleted (those below up a row, a
; blank one at the end), L a blank one put in (those below down, the last gone) - the column 0.
; The page changed first, then its rows drawn again on the screen when in front
asm_1_304_n_cn_eol:
            ld a, (asm_1_304_n_cn_c)
            ld hl, #7682
            sub (hl)
            ld b, a
            ld d, (hl)
            ld a, (#7683)
            ld e, a
            jp asm_1_304_n_cn_wipen
asm_1_304_n_cn_eos:
            call asm_1_304_n_cn_eol
            ld a, (#7683)
asm_1_304_n_cn_eos_lp:
            inc a
            ld hl, asm_1_304_n_cn_r
            cp (hl)
            ret nc
            push af
            ld e, a
            call asm_1_304_n_cn_wrow
            pop af
            jr asm_1_304_n_cn_eos_lp
asm_1_304_n_cn_eln:
            ld a, (#7683)
            ld e, a
            jp asm_1_304_n_cn_wrow
asm_1_304_n_cn_sol:
            ld a, (#7682)
            inc a
            ld b, a
            ld d, 0
            ld a, (#7683)
            ld e, a
            jp asm_1_304_n_cn_wipen
asm_1_304_n_cn_sos:
            call asm_1_304_n_cn_sol
            ld a, (#7683)
asm_1_304_n_cn_sos_lp:
            or a
            ret z
            dec a
            push af
            ld e, a
            call asm_1_304_n_cn_wrow
            pop af
            jr asm_1_304_n_cn_sos_lp
asm_1_304_n_cn_dell:
            xor a
            ld (#7682), a
            ld a, (#7683)
            ld b, a                 ; B: the row filled from the one below
asm_1_304_n_cn_dl_lp:
            ld a, (asm_1_304_n_cn_r)
            dec a
            cp b
            jr z, asm_1_304_n_cn_dl_end
            ld c, b
            inc c
            ld a, b
            push bc
            call asm_1_304_n_cn_cpr
            pop bc
            inc b
            jr asm_1_304_n_cn_dl_lp
asm_1_304_n_cn_dl_end:
            ld e, b
            call asm_1_304_n_cn_wrow            ; the last row blank
            ld a, (asm_1_304_n_cn_r)
            dec a
            ld c, a
            ld a, (#7683)
            jr asm_1_304_n_cn_redr
asm_1_304_n_cn_insl:
            xor a
            ld (#7682), a
            ld a, (asm_1_304_n_cn_r)
            dec a
            ld b, a                 ; B: the row filled from the one above
asm_1_304_n_cn_il_lp:
            ld a, (#7683)
            cp b
            jr z, asm_1_304_n_cn_il_end
            ld c, b
            dec c
            ld a, b
            push bc
            call asm_1_304_n_cn_cpr
            pop bc
            dec b
            jr asm_1_304_n_cn_il_lp
asm_1_304_n_cn_il_end:
            ld e, b
            call asm_1_304_n_cn_wrow            ; the cursor's row blank
            ld a, (asm_1_304_n_cn_r)
            ld c, a
            ld a, (#7683)
            inc a
; cn_redr: rows A to C - 1 drawn again from the page
asm_1_304_n_cn_redr:
            cp c
            ret nc
            push af
            push bc
            ld e, a
            ld d, 0
            ld a, (asm_1_304_n_cn_c)
            ld b, a
            call asm_1_304_n_cn_drwn
            pop bc
            pop af
            inc a
            jr asm_1_304_n_cn_redr
; cn_cpr: the page's row C copied to its row A
asm_1_304_n_cn_cpr:
            push af
            ld a, c
            call asm_1_304_n_cn_rowa
            pop af
            push hl
            call asm_1_304_n_cn_rowa
            ex de, hl
            pop hl
            ld a, (asm_1_304_n_cn_c)
            ld c, a
            ld b, 0
            ldir
            ret
; cn_wrow: row E blank; cn_wipen: B characters of row E from column D blank (B > 0) - in the page,
; then drawn (cn_drwn: B characters of row E from column D, from the page, when in front)
asm_1_304_n_cn_wrow:
            ld d, 0
            ld a, (asm_1_304_n_cn_c)
            ld b, a
asm_1_304_n_cn_wipen:
            push de
            push bc
            ld a, e
            call asm_1_304_n_cn_rowa
            pop bc
            pop de
            push bc
            ld a, l
            add a, d
            ld l, a
            jr nc, asm_1_304_n_cn_wn_lp
            inc h
asm_1_304_n_cn_wn_lp:
            ld (hl), ' '
            inc hl
            djnz asm_1_304_n_cn_wn_lp
            pop bc
asm_1_304_n_cn_drwn:
            ld a, (asm_1_304_n_cn_front)
            or a
            ret z
            push de
            push bc
            ld a, e
            call asm_1_304_n_cn_rowa
            pop bc
            pop de
            ld a, l
            add a, d
            ld l, a
            jr nc, asm_1_304_n_cn_dw_p
            inc h
asm_1_304_n_cn_dw_p:                            ; the screen address worked out once, then stepped on (as
            push hl                 ; cn_print: a sum each character was a fifth of the time
            push bc                 ; a screen of text took - ESC K's)
            call asm_1_304_n_cn_scr
            pop bc
            pop de                  ; DE: the page's characters, HL the screen
asm_1_304_n_cn_dw_lp:
            ld a, (de)
            inc de
            push hl
            push de
            push bc
            call asm_1_304_n_cn_glyph8
            pop bc
            pop de
            pop hl
            call asm_1_304_n_cn_next
            djnz asm_1_304_n_cn_dw_lp
            ret

; ESC E: the page cleared, column, row and ring back to 0; the screen too if in front (written,
; not copied: the Library: ROM build may have the keyword ROM over it for reads)
asm_1_304_n_cn_clear:
            ld hl, #7700
            ld de, #7701
            ld (hl), ' '
            ld bc, 2047
            ldir
            xor a
            ld (#7682), a
            ld (#7683), a
            ld (#7684), a
            ld a, (asm_1_304_n_cn_front)
            or a
            ret z
            ld hl, 0
            ld (var_hyp_sco), hl
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen)
            call asm_1_304_n_cn_crtc
    IFDEF NTC_MSXDOS
            call msx_vclr           ; MSX: the name table all spaces (sco 0, R#23 0: above)
    ELSE
            xor a
            ld hl, #C000
            ld c, #40
asm_1_304_n_cn_cl_l:
            ld b, 0
asm_1_304_n_cn_cl_b:
            ld (hl), a
            inc hl
            djnz asm_1_304_n_cn_cl_b
            dec c
            jr nz, asm_1_304_n_cn_cl_l
    ENDIF
; cn_strip: MODE S (the screen wider than the console): the status strip's 4 characters (#F68A)
; at the top of the columns right of the console
asm_1_304_n_cn_strip:
            ld a, (asm_1_304_n_cn_front)
            or a
            ret z
            ld a, (asm_1_304_n_cn_c)
            ld d, a
            ld a, (var_hyp_scc)
            cp d
            ret z
            ret c
            ld e, 0
            ld hl, #768A
            ld b, 4
asm_1_304_n_cn_st_lp:
            ld a, (hl)
            push hl
            push de
            push bc
            call asm_1_304_n_cn_glyph
            pop bc
            pop de
            pop hl
            inc hl
            inc d
            djnz asm_1_304_n_cn_st_lp
            jp asm_1_304_n_cn_net                       ; then the network indicator, two rows down

; cn_net: the network indicator - the status strip's row 2 (row 1 left blank under [1]). 'N' when
; the network's up and idle; it blinks N / blank while there's traffic (nta, counted down by the
; 0.5s cursor-flash tick); the cell is left BLANK when the network's off, so nothing shows until a
; network is turned on (the screen is unchanged from before this feature). The cell is system-wide
; (not a slot's), so its state is in class vars (ntu / nta / ntb), reachable from the NET service
asm_1_304_n_cn_net:
            ld a, (asm_1_304_n_cn_front)
            or a
            ret z
            ld a, (asm_1_304_n_cn_c)
            ld d, a
            ld a, (var_hyp_scc)
            cp d
            ret z
            ret c
            ld hl, asm_1_304_n_cn_nblk                  ; the network's off: a blank cell (nothing shown)
            ld a, (var_hyp_ntu)
            or a
            jr z, asm_1_304_n_cn_net_draw
            ld a, (var_hyp_nta)                   ; up: steady 'N', or blank on the odd blink while busy
            or a
            ld a, 78
            jr z, asm_1_304_n_cn_net_put
            ld a, (var_hyp_ntb)
            and 1
            ld a, 78
            jr z, asm_1_304_n_cn_net_put
            ld a, 32
asm_1_304_n_cn_net_put:
            ld (asm_1_304_n_cn_nbuf + 1), a
            ld hl, asm_1_304_n_cn_nbuf
asm_1_304_n_cn_net_draw:
            ld a, (asm_1_304_n_cn_c)
            ld d, a                         ; the first strip column
            ld e, 2                         ; row 2 (row 1 blank, under [1] at row 0)
            ld b, 4
asm_1_304_n_cn_net_lp:
            ld a, (hl)
            push hl
            push de
            push bc
            call asm_1_304_n_cn_glyph
            pop bc
            pop de
            pop hl
            inc hl
            inc d
            djnz asm_1_304_n_cn_net_lp
            ret
asm_1_304_n_cn_nbuf:    db 91, 78, 93, 32               ; "[N] " when up; +1 overwritten with N / blank (blink)
asm_1_304_n_cn_nblk:    db 32, 32, 32, 32               ; a blank cell (network off: nothing shown)

; cn_crtc: the screen's start (sco, bytes) to the CRTC: R12 = #30 + its words' high 2 bits, R13
; the low 8 (#C000, MA10 / MA11 clear: kept within 2K, never the carry into the next 16K)
asm_1_304_n_cn_crtc:
    IFDEF NTC_MSXDOS
            jp msx_vr23             ; MSX: R#23 = the top row * 8
    ENDIF
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
asm_1_304_n_cn_rowa:
            ld hl, #7684
            add a, (hl)
            ld hl, asm_1_304_n_cn_r
            cp (hl)
            jr c, asm_1_304_n_cn_ra_in
            sub (hl)
asm_1_304_n_cn_ra_in:
            ld e, a
            ld a, (asm_1_304_n_cn_c)
            call asm_1_304_n_cn_mul
            ld de, #7700
            add hl, de
            ret

; cn_mul: HL = A * E (BC kept; D = 0 after)
asm_1_304_n_cn_mul:
            push bc
            ld hl, 0
            ld d, 0
            ld b, 8
asm_1_304_n_cn_mu_lp:
            add hl, hl
            rlca
            jr nc, asm_1_304_n_cn_mu_n
            add hl, de
asm_1_304_n_cn_mu_n:
            djnz asm_1_304_n_cn_mu_lp
            pop bc
            ret

; cn_next: HL = the next screen byte: + 1 within its 2K line block (BC kept)
asm_1_304_n_cn_next:
    IFDEF NTC_MSXDOS
            inc l                   ; ZX Next: the tilemap is linear - plain 16-bit increment
            ret nz
            inc h
            ret
    ENDIF
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
asm_1_304_n_cn_glyph:
            push af
            call asm_1_304_n_cn_scr
            pop af
; cn_glyph8: A = character, HL = its screen address: its 8 bytes into screen memory (mode 2, pen
; 1 on paper 0), one per pixel line (#800 apart; unrolled)
asm_1_304_n_cn_glyph8:
    IFDEF NTC_MSXDOS
            ; MSX: the character into its cell of the name table (HL: cn_scr's VRAM address)
            ld c, a
            ld a, l
            out (#99), a
            ld a, h
            or #40
            out (#99), a
            ld a, c
            out (#98), a
            ret
    ENDIF
            sub 32
            cp 96
            jr c, asm_1_304_n_cn_gl_ok
            ld a, '?' - 32
asm_1_304_n_cn_gl_ok:
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
asm_1_304_n_cn_scr:
    IFDEF NTC_MSXDOS
            ld a, e                 ; MSX: the name table's row (the top row sco on, of 32) * 80 +
            push de                 ; the column (80 a row whatever the console's width)
            call msx_vrow
            pop de
            ld c, d
            ld b, 0
            add hl, bc
            ret
    ENDIF
            push de
            ld a, (var_hyp_scc)
            call asm_1_304_n_cn_mul
            pop de
            ld c, d
            ld b, 0
            add hl, bc
    IFDEF NTC_MSXDOS
            ret                     ; (MSX: not reached - cn_scr's own above)
    ENDIF
            ld bc, (var_hyp_sco)
            add hl, bc
            ld a, h
            and #07
            or #C0
            ld h, a
            ret
asm_1_304_n_cn_cuxor:                           ; the cursor's underline XORed at cn_ca, on <-> off
    IFDEF NTC_MSXDOS
            ld hl, (asm_1_304_n_cn_ca)          ; MSX: the cell - on: the character there kept (cn_cuch), an
            ld a, (var_hyp_ccu)           ; underline shown; off: the character back
            xor 1
            ld (var_hyp_ccu), a
            jr z, asm_1_304_n_cn_cuoff
            ld a, l
            out (#99), a
            ld a, h
            and #3F
            out (#99), a
            nop
            in a, (#98)
            ld (asm_1_304_n_cn_cuch), a
            ld a, '_'
            jp asm_1_304_n_cn_glyph8
asm_1_304_n_cn_cuoff:   ld a, (asm_1_304_n_cn_cuch)
            jp asm_1_304_n_cn_glyph8
asm_1_304_n_cn_cuch:    db ' '
; ---- the MSX's screen: TEXT 2 (80 columns) on the V9938, its name table at #0000 a ring of 32
; rows (2560 bytes), the screen's top row sco of them (R#23 = sco * 8: the vertical scroll), 26.5
; rows shown (the blink table at #0A00, out of the ring's way). Interrupts off throughout (the
; BIOS's handler reads the status: a half set address lost)
@msx_vrow:                          ; A = a screen row -> HL = its name table address. BC kept
            ld hl, var_hyp_sco
            add a, (hl)
            and 31
            ld l, a
            ld h, 0
            add hl, hl
            add hl, hl
            add hl, hl
            add hl, hl              ; * 16
            ld e, l
            ld d, h
            add hl, hl
            add hl, hl              ; * 64
            add hl, de              ; * 80
            ret
@msx_vwa:                           ; the VDP's address for writing = HL. A used
            ld a, l
            out (#99), a
            ld a, h
            and #3F
            or #40
            out (#99), a
            ret
@msx_vclrow:                        ; A = a screen row: all spaces. BC, DE, HL used
            call msx_vrow
            call msx_vwa
            ld b, 80
            ld a, ' '
asm_1_304_n_msx_vcr_lp:
            out (#98), a
            djnz asm_1_304_n_msx_vcr_lp
            ret
@msx_vclr:                          ; the whole name table spaces (sco, R#23 as they are)
            ld hl, 0
            call msx_vwa
            ld bc, 10               ; 2560: B 0 (256), C 10
            ld a, ' '
asm_1_304_n_msx_vcl_lp:
            out (#98), a
            djnz asm_1_304_n_msx_vcl_lp
            dec c
            jr nz, asm_1_304_n_msx_vcl_lp
            ret
; msx_t300 - HL = the clock at 300 a second, as the CPC's (the kernel's, the services'): JIFFY
; (the frames) * 6 at 50 Hz, * 5 at 60 (R#9's PAL bit, as the BIOS keeps it), + a tick for each
; look within the frame (up to its last: never past the next frame's first). DE used
@msx_t300:
            ld hl, (#FC9E)
            ld de, (asm_1_304_n_msx_tj)
            ld (asm_1_304_n_msx_tj), hl
            or a
            sbc hl, de
            add hl, de
            ld a, 0
            jr nz, asm_1_304_n_msx_t3_new       ; (a new frame: its first tick)
            ld a, (asm_1_304_n_msx_ts)
            inc a
asm_1_304_n_msx_t3_new:
            ld e, l
            ld d, h
            add hl, hl
            add hl, hl
            add hl, de              ; * 5
            ld e, a
            ld a, (#FFE8)
            and 2
            jr z, asm_1_304_n_msx_t3_60
            add hl, de              ; * 6 (50 Hz)
            ld a, e
            cp 6
            jr asm_1_304_n_msx_t3_sub
asm_1_304_n_msx_t3_60:
            ld a, e
            cp 5
asm_1_304_n_msx_t3_sub:
            jr c, asm_1_304_n_msx_t3_ok
            dec e                   ; (no further than the frame's last tick)
asm_1_304_n_msx_t3_ok:
            ld a, e
            ld (asm_1_304_n_msx_ts), a
            ld d, 0
            add hl, de              ; + the ticks seen within the frame
            ret
asm_1_304_n_msx_tj:     dw 0                    ; JIFFY when msx_t300 looked last
asm_1_304_n_msx_ts:     db 0                    ; the ticks given within that frame (0 - 5): each look moves the
                                    ; clock on one, so a slot asleep for a tick (the kernel's wk) runs
                                    ; again at its next pass, not a frame later
@msx_vr23:                          ; R#23 = sco * 8
            ld a, (var_hyp_sco)
            add a, a
            add a, a
            add a, a
            out (#99), a
            ld a, #80 + 23
            out (#99), a
            ret
    ENDIF
            ld hl, (asm_1_304_n_cn_ca)
            ld a, (hl)
            cpl
            ld (hl), a
            ld a, (var_hyp_ccu)
            xor 1
            ld (var_hyp_ccu), a
            ret
asm_1_304_n_cn_was:     db 0
asm_1_304_n_cn_ca:      dw 0
asm_1_304_n_cn_front:   db 0
asm_1_304_n_cn_c:       db 80                   ; the slot's columns, rows
asm_1_304_n_cn_r:       db 25
asm_1_304_n_cn_pv:      db 0                    ; cn_pp / cn_sp valid (0: the cursor moved)
asm_1_304_n_cn_pp:      dw 0                    ; the page byte for the next character
asm_1_304_n_cn_sp:      dw 0                    ; its screen address
asm_1_304_n_cn_left:    dw 0
asm_1_304_n_cn_ptr:     dw 0
            IF asm_1_304_n_CN_SB
asm_1_304_n_cn_pg:      dw 0                    ; the slot's page 3 setting (pg)
asm_1_304_n_cn_h1:      dw 0                    ; cn_hcp: from (its setting, address), to, 8-byte runs left
asm_1_304_n_cn_hs:      dw 0
asm_1_304_n_cn_h2:      dw 0
asm_1_304_n_cn_hd:      dw 0
asm_1_304_n_cn_hn:      db 0
            ENDIF
asm_1_304_n_cn_end:
			ret			; end of #asm

asm_1_1652_n:		; #asm, Hyp.cls line 1652 (normal)
    IFDEF NTC_MSXDOS
            ; MSX: straight into the name table, row, col on (msx_vrow: the scroll's top row)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld a, (var_hyp_say_n)
            or a
            jr z, asm_1_1652_n_sy_zdone
            ld b, a
            ld a, (var_hyp_say_row)
            call msx_vrow
            ld a, (var_hyp_say_col)
            ld e, a
            ld d, 0
            add hl, de
            call msx_vwa
            ld hl, (var_hyp_say_p)
            ld a, (var_hyp_say_col)
            ld c, a
asm_1_1652_n_sy_zlp:
            ld a, c
            cp 80
            jr nc, asm_1_1652_n_sy_zdone
            ld a, (hl)
            out (#98), a
            inc hl
            inc c
            djnz asm_1_1652_n_sy_zlp
asm_1_1652_n_sy_zdone:
            ld sp, (var_hyp_hsp)
            jp asm_1_1652_n_sy_end
    ENDIF
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld bc, (var_hyp_hps)          ; the hypervisor's page in the window: the font
            out (c), c
            ld hl, (var_hyp_sco)          ; the screen's start (TOP is shown in MODE 2: 80 columns)
            ld (asm_1_1652_n_sy_off), hl
            ld hl, (var_hyp_say_p)
            ld a, (var_hyp_say_n)
            ld b, a
            ld a, (var_hyp_say_col)
            ld d, a
            ld a, (var_hyp_say_row)
            ld e, a
            inc b
asm_1_1652_n_sy_lp:
            dec b
            jr z, asm_1_1652_n_sy_done
            ld a, d
            cp 80
            jr nc, asm_1_1652_n_sy_done
            ld a, (hl)
            inc hl
            push hl
            push bc
            push de
            sub 32                  ; the character's matrix
            cp 96
            jr c, asm_1_1652_n_sy_ok
            ld a, '?' - 32
asm_1_1652_n_sy_ok:
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
            ld bc, (asm_1_1652_n_sy_off)
            add hl, bc
            ld a, h
            and #07
            or #C0
            ld h, a
            pop de
            ld b, 8
asm_1_1652_n_sy_ln:
            ld a, (de)
            ld (hl), a
            inc de
            ld a, h
            add a, 8
            ld h, a
            djnz asm_1_1652_n_sy_ln
            pop de
            pop bc
            pop hl
            inc d
            jr asm_1_1652_n_sy_lp
asm_1_1652_n_sy_done:
            ld bc, (ntc_rampt)
            out (c), c
            ld sp, (var_hyp_hsp)
            jr asm_1_1652_n_sy_end
asm_1_1652_n_sy_off:     dw 0
asm_1_1652_n_sy_end:
			ret			; end of #asm

asm_1_1777_n:		; #asm, Hyp.cls line 1777 (normal)
            ld (var_hyp_hsp), sp          ; (the real stack: SP is the thread)
            ld sp, (ntc_csp)
            xor a
            ld (var_hyp_ccu), a           ; (the screen cleared: no cursor on it)
            ld a, (var_hyp_scr_m)
            cp 6
            jr c, asm_1_1777_n_sm_ok
            xor a
asm_1_1777_n_sm_ok:
            ld l, a                 ; the mode's row of the table (6 bytes)
            add a, a
            add a, l
            add a, a
            ld e, a
            ld d, 0
            ld hl, asm_1_1777_n_sm_tab
    IFDEF NTC_MSXDOS
            ld hl, asm_1_1777_n_zxn_sm_tab       ; MSX: TEXT 2's modes (80 columns at most)
    ENDIF
            add hl, de
            ld a, (var_hyp_scr_k)
            or a
            jr z, asm_1_1777_n_sm_cols
            dec a
            jr z, asm_1_1777_n_sm_rows
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
    IFNDEF NTC_MSXDOS
            inc hl
            inc hl                  ; R1, R2, R6, R7
            di
            ld d, 1
            call asm_1_1777_n_sm_crtc
            ld d, 2
            call asm_1_1777_n_sm_crtc
            ld d, 6
            call asm_1_1777_n_sm_crtc
            ld d, 7
            call asm_1_1777_n_sm_crtc
            ld hl, asm_1_1777_n_sm_start         ; R12, R13: #C000
            ld d, 12
            call asm_1_1777_n_sm_crtc
            ld d, 13
            call asm_1_1777_n_sm_crtc
            xor a                   ; cleared (written, not copied: the Library: ROM build may
            ld hl, #C000            ; have the keyword ROM over it for reads)
            ld c, #40
asm_1_1777_n_sm_cl:
            ld b, 0
asm_1_1777_n_sm_cl1:
            ld (hl), a
            inc hl
            djnz asm_1_1777_n_sm_cl1
            dec c
            jr nz, asm_1_1777_n_sm_cl
    ELSE                            ; MSX: no CRTC; the name table cleared, its top row 0 (R#23)
            call msx_vclr
            call msx_vr23
    ENDIF
            ld hl, 0
            jr asm_1_1777_n_sm_res
asm_1_1777_n_sm_cols:
            ld a, (hl)              ; the console's: the screen's, less the status strip's 4 (S)
            inc hl
            sub (hl)
            jr asm_1_1777_n_sm_a
asm_1_1777_n_sm_rows:
            inc hl
            inc hl
            inc hl
            inc hl
            ld a, (hl)
asm_1_1777_n_sm_a:
            ld l, a
            ld h, 0
asm_1_1777_n_sm_res:
            ld (var_hyp_scr_scr), hl
            ld sp, (var_hyp_hsp)
            ret                     ; (on with the thread)
asm_1_1777_n_sm_crtc:                            ; CRTC register D = (HL), HL on
            ld bc, #BC00
            out (c), d
            ld b, #BD
            ld a, (hl)
            out (c), a
            inc hl
            ret
asm_1_1777_n_sm_start:   db #30, 0
; columns, the status strip's, R1 (words a row), R2 (horizontal sync), R6 (rows), R7 (vertical sync)
asm_1_1777_n_sm_tab:     db 80, 0, 40, 46, 25, 30
            db 84, 4, 42, 47, 24, 30
            db 88, 0, 44, 48, 23, 29
            db 96, 0, 48, 50, 21, 28
            db 64, 0, 32, 42, 32, 34
            db 84, 0, 42, 47, 24, 30
    IFDEF NTC_MSXDOS
; MSX: TEXT 2, 80 x 26 at most (msx_vrow). cols (the status strip's in them), the strip's, (R1 R2
; unused), rows, (R7 unused). The CPC's wider modes (88, 96 columns) are 80 here
asm_1_1777_n_zxn_sm_tab: db 80, 0, 0, 0, 25, 0   ; MODE 2  80 x 25
            db 80, 4, 0, 0, 24, 0   ; MODE S  console 76 + 4 status, 24 rows
            db 80, 0, 0, 0, 23, 0   ; MODE W  (88 x 23 on the CPC)
            db 80, 0, 0, 0, 21, 0   ; MODE UW (96 x 21)
            db 64, 0, 0, 0, 26, 0   ; MODE P  64 x 26 (TEXT 2 shows 26 rows; the CPC's 64 x 32)
            db 80, 0, 0, 0, 24, 0   ; MODE F  (84 x 24)
    ENDIF
			ret			; end of #asm

asm_1_1940_n:		; #asm, Hyp.cls line 1940 (normal)
    IFDEF NTC_MSXDOS
            ret                     ; ZX Next: no CPC firmware key-repeat (platform-specific)
    ELSE
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            call #BB42              ; KM GET DELAY: H the start delay, L the repeat
            di
            ld a, h
            call asm_1_1940_n_kr_mul
            ld h, a
            ld a, l
            call asm_1_1940_n_kr_mul
            ld l, a
            call #BB3F              ; KM SET DELAY
            di
            ld sp, (var_hyp_hsp)
            jr asm_1_1940_n_kr_end
asm_1_1940_n_kr_mul:                             ; A = A x f, 255 at most (0: 256 to the firmware - kept)
            or a
            ret z
            push hl
            ld e, a
            ld d, 0
            ld hl, 0
            ld a, (var_hyp_keyrep_f)
            ld b, a
asm_1_1940_n_kr_lp:
            add hl, de
            djnz asm_1_1940_n_kr_lp
            ld a, h
            or a
            ld a, l
            pop hl
            ret z
            ld a, 255
            ret
asm_1_1940_n_kr_end:
    ENDIF
			ret			; end of #asm

asm_1_2008_n:		; #asm, Hyp.cls line 2008 (normal)
            ld (var_hyp_sps), sp
            ld sp, (ntc_csp)
    IFNDEF NTC_MSXDOS
            call #B903              ; KL U ROM DISABLE: the task's top 16K, not a ROM (Library:
    ELSE
            xor a                   ; zxn: no ROMs to disable
    ENDIF
            di                      ; ROM has the keyword ROM on), while it runs
            ld (var_hyp_rrom), a
            ld a, 6
            ld (var_hyp_slc), a
            ld a, 1                 ; from BASIC: it has taken the characters (Collected)
            ld (var_hyp_rclr), a
asm_1_2008_n_rn_again:
            push ix                 ; IX, IY and
            push iy
            db #08                  ; ex af, af': the alternate registers kept - the
            exx                     ; firmware's (BC' = its ROM / mode setting); a task
            push af                 ; may use them
            push bc
            push de
            push hl
            exx
            db #08
            ld hl, asm_1_2008_n_rn_back
            push hl                 ; where main RAM carries on
            ld (ntc_bk_sp), sp
            ld a, (var_hyp_rclr)
            ld e, a                 ; E = 1: the bank empties its characters out (BASIC has them)
            ld a, (var_hyp_ra)
            ld hl, (var_hyp_rhl)
            ld bc, (var_hyp_run_setting)
    IFDEF NTC_MSXDOS
            ; hyp -> task: the task's page 3 first (out (#FF): this code is in pages 0-2, the
            ; hypervisor's stack in page 3 is gone from here on - no push, no call), ra / rclr /
            ; rhl into the task's SWAP, then its sb_hin (HISW) maps pages 0-2 and lands it
            ld a, c
            or 7                                ; its page 3's setting (C2 + 5 = ordinal * 8 + 7)
            ld c, a
            call msx_mem_bank                   ; A = its segment
            out (#FF), a
            ld a, (var_hyp_rclr)
            ld (63185 + 2), a
            ld hl, (var_hyp_rhl)
            ld (63185 + 3), hl
            ld a, (var_hyp_ra)
            ld (63185 + 1), a
            jp 65488
; msx_recv: task -> hyp, from the bank's sb_hout (pages 0-2 already the hypervisor's, A and its
; carry in AF'): page 3 back, the hypervisor's SP, ret to rn_back. DE, HL, IX as the task left them
@msx_recv:
            ld a, (msx_tpa + 3)
            out (#FF), a
            db #08
            ld sp, (ntc_bk_sp)
            ret
@ntc_bk_sp: dw 0                                ; the hypervisor's SP while a task runs
    ELSE
            jp ntc_bk_out           ; out (c), c: the task's bank; its #0046 lands it
    ENDIF
asm_1_2008_n_rn_back:
            ld (var_hyp_rcnt), ix         ; the characters it collected (the stubs put them in IX)
            db #08                  ; ex af, af'
            exx
            pop hl                  ; the alternate registers back
            pop de
            pop bc
            pop af
            exx
            db #08
            pop iy
            pop ix
            push af                 ; carry: a BDOS call (A = C, DE = DE)
            push bc
            ld bc, (ntc_rampt)      ; the window's page back
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            pop bc
            pop af
            jr c, asm_1_2008_n_rn_far
            rst #38                 ; an interrupt stopped the task: the firmware's handler
            di
            ld hl, var_hyp_slc            ; a time slice is SLICE interrupts: until it is used up the
            dec (hl)                ; task carries on straight away (no trip through BASIC)
            jr z, asm_1_2008_n_rn_int
            ld a, (ntc_isldue)      ; ... unless an interrupt class (the system keys) is due
            or a
            jr nz, asm_1_2008_n_rn_int
            xor a                   ; its characters stay in its bank (and the count goes on)
            ld (var_hyp_rclr), a
            jp asm_1_2008_n_rn_again
asm_1_2008_n_rn_int:
            ld hl, 0
            jr asm_1_2008_n_rn_end
asm_1_2008_n_rn_far:
            ld (var_hyp_rfn), a
            ld (var_hyp_rde), de
            ld hl, 1
asm_1_2008_n_rn_end:
            ld (var_hyp_run_run), hl
            ld a, (var_hyp_rrom)
    IFNDEF NTC_MSXDOS
            call #B90C              ; KL ROM RESTORE
    ENDIF
            di
            ld sp, (var_hyp_sps)

			ret			; end of #asm

asm_1_2125_n:		; #asm, Hyp.cls line 2125 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            call msx_t300
            ld (var_hyp_t300_t300), hl
            ld sp, (var_hyp_hsp)
			ret			; end of #asm

fn_hyp_seg:		; function seg (asm keyword), Hyp.cls line 2137
            pop hl
            ld c, (hl)
            inc hl
            ld b, (hl)
            ld a, b
            or a
            jr nz, fn_hyp_seg_sg_bank
            ld a, c
            cp 4
            jr nc, fn_hyp_seg_sg_bank
            ld e, a
            ld d, 0
            ld hl, msx_tpa
            add hl, de
            ld a, (hl)
            jr fn_hyp_seg_sg_e
fn_hyp_seg_sg_bank:
            ld (var_hyp_hsp), sp          ; (the real stack for the call: SP is the thread)
            ld sp, (ntc_csp)
            call msx_mem_bank
            ld sp, (var_hyp_hsp)
fn_hyp_seg_sg_e:
            pop hl
            ld (hl), a
            inc hl
            ld (hl), 0
            ret
			ret			; end of #asm

fn_hyp_info:		; function info (asm keyword), Hyp.cls line 2174
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
    IFDEF NTC_MSXDOS
            dec a
            jr z, fn_hyp_info_in_e
            ld hl, fn_hyp_info_hi_sw                        ; 5: the switch-back receiver's source (window image)
            dec a
            jr z, fn_hyp_info_in_e
            ld hl, fn_hyp_info_hi_swe - fn_hyp_info_hi_sw               ; 6: its length (copied below #FFFE: HISW)
    ENDIF
fn_hyp_info_in_e:
            ex de, hl
            pop hl
            ld (hl), e
            inc hl
            ld (hl), d
            ret

			ret			; end of #asm

asm_1_3760_n:		; #asm, Hyp.cls line 3760 (normal)
    IFDEF NTC_MSXDOS
            ld a, (var_hyp_vdu_on)            ; MSX: Vdu 1 - the DOS's screen back (the BIOS's INITXT through
            or a                    ; CALSLT, R#23 0 first: the BIOS doesn't know of the scroll);
            jr z, asm_1_3760_n_vd_msx            ; Vdu 0 - nothing (CyborgOS's screen is set at the start)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            push ix
            push iy
            xor a
            out (#99), a
            ld a, #80 + 23
            out (#99), a
            ld a, (#FCC1)           ; EXPTBL: the main ROM's slot
            ld iyh, a
            ld ix, #006C            ; INITXT
            call #001C              ; CALSLT
            di
            ld bc, #7FC0            ; the program's own page 1 in the window again (MSX-DOS 2 frees
            call msx_win            ; the segments it gave at the end: none of them left in a page)
            pop iy
            pop ix
            ld sp, (var_hyp_hsp)
asm_1_3760_n_vd_msx:
    ELSE
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld a, (var_hyp_vdu_on)
            or a
            jr z, asm_1_3760_n_vd_off
            call #BB54              ; TXT VDU ENABLE
            jr asm_1_3760_n_vd_done
asm_1_3760_n_vd_off:
            call #BB57              ; TXT VDU DISABLE
asm_1_3760_n_vd_done:
            di
            ld sp, (var_hyp_hsp)
    ENDIF
			ret			; end of #asm

asm_1_3817_n:		; #asm, Hyp.cls line 3817 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld (asm_1_3817_n_fl_ix), ix
            ld (asm_1_3817_n_fl_iy), iy
            ld a, 255
            ld (asm_1_3817_n_fl_res), a
            ld a, (var_hyp_filecall_slot)
            ld (asm_1_3817_n_fl_slot), a
            ld a, (var_hyp_filecall_f)
            cp 99
            jp z, asm_1_3817_n_fl_inst
            IF NTC_ROMLIB = 0
; the RAM discs' driver (RAMDISC.CYB's, in a page of its own at #4000) sees the call first:
; carry - it was one of its drives' (HL the answer), else on to the disc ROM. It gets IX = the
; call (f, fcb, slot, setting, dma, drive, buf; 100-105: drive = the hypervisor's drive), at
; #4003 a jump to fl_dx (its copies: it runs in the window, so can't switch it itself), at
; #4006 its page's RAM setting
            ASSERT var_hyp_filecall_buf - var_hyp_filecall_f = 12, "FileCall's parameters, one after another"
            ld a, (var_hyp_drs + 1)
            or a
            jr z, asm_1_3817_n_fl_nodrv
            di
            ld a, (var_hyp_filecall_f)
            cp 100
            jr c, asm_1_3817_n_fl_dr_go
            cp 106
            jr nc, asm_1_3817_n_fl_dr_go
            ld hl, (var_hyp_hdr)
            ld (var_hyp_filecall_drive), hl
asm_1_3817_n_fl_dr_go:
            ld bc, (var_hyp_drs)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld hl, asm_1_3817_n_fl_dx
            ld (#4004), hl
            ld hl, (var_hyp_drs)
            ld (#4006), hl
            ld ix, var_hyp_filecall_f
            call #4000
            jr nc, asm_1_3817_n_fl_nodrv
            ld (asm_1_3817_n_fl_res16), hl
            ld a, 1
            ld (asm_1_3817_n_fl_r16), a
            jp asm_1_3817_n_fl_done
; fl_dx - A bytes (1-128) from HL to DE through dxb: IX = HL's RAM setting, IY = DE's (0:
; main RAM, no switch); the driver's page back in the window after. HL, DE on past them
asm_1_3817_n_fl_dx:
            ld (asm_1_3817_n_fl_dxn), a
            push de
            ld de, (var_hyp_dxb)
            push ix
            pop bc
            inc b
            dec b
            jr z, asm_1_3817_n_fl_dx1
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
asm_1_3817_n_fl_dx1:
            ld c, a
            ld b, 0
            ldir
            pop de
            push hl
            push iy
            pop bc
            inc b
            dec b
            jr z, asm_1_3817_n_fl_dx2
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
asm_1_3817_n_fl_dx2:
            ld hl, (var_hyp_dxb)
            ld a, (asm_1_3817_n_fl_dxn)
            ld c, a
            ld b, 0
            ldir
            pop hl
            ld bc, (var_hyp_drs)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ret
asm_1_3817_n_fl_dxn:     db 0
asm_1_3817_n_fl_nodrv:
            ENDIF
            di
            ld bc, (var_hyp_hps)          ; the rest runs in the hypervisor's page (window data from
    IFDEF NTC_MSXDOS
            call msx_win  ; #5300: fp_go)
    ELSE
            out (c), c  ; #5300: fp_go)
    ENDIF
            call asm_1_3817_n_fp_go
            jp asm_1_3817_n_fl_done
; 99: the window data (#5300 to fp_end: the bank image, the page code) copied from main RAM's
; own #4000-#7FFF (where the file put it) into the hypervisor's page, through buf; once, at the
; start, before anything else uses main RAM's #4000-#7FFF
asm_1_3817_n_fl_inst:
    IFDEF NTC_MSXDOS
            ld hl, #4000            ; (zxn: the SD card's code is there)
    ELSE
            ld hl, #5300
    ENDIF
asm_1_3817_n_fl_in_lp:
            push hl
            ld bc, #7FC0            ; main RAM's own (zxn: bank 9 = the hypervisor's own pages 18, 19, holding the loaded image)
    IFDEF NTC_MSXDOS
            call asm_1_3817_n_fl_zxn_map
    ELSE
            out (c), c
    ENDIF
            ld de, (var_hyp_filecall_buf)
            ld bc, 128
            ldir
            ld bc, (var_hyp_hps)
    IFDEF NTC_MSXDOS
            call asm_1_3817_n_fl_zxn_map
    ELSE
            out (c), c
    ENDIF
            pop de
            push de
            ld hl, (var_hyp_filecall_buf)
            ld bc, 128
            ldir
            pop hl
            ld bc, 128
            add hl, bc
            ld de, asm_1_3817_n_fp_end
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_3817_n_fl_in_lp
            xor a
            ld (asm_1_3817_n_fl_res), a
    IFDEF NTC_MSXDOS
            ld hl, var_hyp_filecall_f              ; (the SD card: its drive set up, with where these are; then fl_done)
            ld de, var_hyp_fin
            ld bc, var_hyp_fout
            jp sd_h_init
    ELSE
            jp asm_1_3817_n_fl_done
    ENDIF
    IFDEF NTC_MSXDOS
; fl_zxn_map - BC = a RAM setting -> its 16K bank into the window (slots 2, 3) via the MMU
; (msx_win), noted in ntc_rampt as the Memory class's mem_se_out notes its. Keeps every register
asm_1_3817_n_fl_zxn_map:
            ld (ntc_rampt), bc
            jp msx_win
    ENDIF
; ---- what the page code can't do itself (it runs in the window): switch the window to a slot's
; page and back. Each puts the hypervisor's page back in the window
asm_1_3817_n_fl_sel:                             ; the slot's page holding HL in the window: HL = there
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
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld a, h
            and #3F
            or #40
            ld h, a
            pop de
            ret
asm_1_3817_n_fl_peek:                            ; A = the slot's byte at HL (BC, DE, HL kept)
            push bc
            push hl
            call asm_1_3817_n_fl_sel
            ld a, (hl)
asm_1_3817_n_fl_pk_back:
            ld bc, (var_hyp_hps)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            pop hl
            pop bc
            ret
asm_1_3817_n_fl_poke:                            ; the slot's byte at HL = A (BC, DE, HL kept)
            push bc
            push hl
            push af
            call asm_1_3817_n_fl_sel
            pop af
            ld (hl), a
            jr asm_1_3817_n_fl_pk_back
asm_1_3817_n_fl_toslot:                          ; BC bytes from DE (main RAM) to the slot's HL (all in one of
            push bc                 ; its pages: fl_fits)
            call asm_1_3817_n_fl_sel
            pop bc
            ex de, hl
            ldir
            jr asm_1_3817_n_fl_blk_back
asm_1_3817_n_fl_fromslot:                        ; BC bytes from the slot's HL (in one page) to DE (main RAM)
            push bc
            call asm_1_3817_n_fl_sel
            pop bc
            ldir
asm_1_3817_n_fl_blk_back:
            ld bc, (var_hyp_hps)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ret
asm_1_3817_n_fl_done:
            di
            ld bc, (ntc_rampt)      ; the page that was in the window back
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld a, (asm_1_3817_n_fl_res)
            ld l, a
            ld h, 0
            ld a, (asm_1_3817_n_fl_r16)
            or a
            jr z, asm_1_3817_n_fl_d8
            ld hl, (asm_1_3817_n_fl_res16)
            xor a
            ld (asm_1_3817_n_fl_r16), a
asm_1_3817_n_fl_d8:
            ld (var_hyp_filecall_filecall), hl
            ld ix, (asm_1_3817_n_fl_ix)
            ld iy, (asm_1_3817_n_fl_iy)
            ld sp, (var_hyp_hsp)
            jp asm_1_3817_n_fl_exit
asm_1_3817_n_fl_ix:      dw 0
asm_1_3817_n_fl_iy:      dw 0
asm_1_3817_n_fl_res:     db 0
asm_1_3817_n_fl_r16:     db 0                    ; 1: the result is fl_res16
asm_1_3817_n_fl_res16:   dw 0
asm_1_3817_n_fl_slot:    db 0
; (main RAM: the page code calls them - no room left in the page)
asm_1_3817_n_fl_isin:                            ; Z: the file being read is this slot's, this FCB
            ld a, (var_hyp_fin)
            ld hl, asm_1_3817_n_fl_infcb
            jr asm_1_3817_n_fl_is
asm_1_3817_n_fl_isout:
            ld a, (var_hyp_fout)
            ld hl, asm_1_3817_n_fl_outfcb
asm_1_3817_n_fl_is:                              ; (its FCB: the one it was opened with - or, the first
            ld b, a                 ; call after with another, that one: a program's own copy
            ld a, (asm_1_3817_n_fl_slot)         ; of it, BBC BASIC's channels)
            cp b
            ret nz
            ld e, (hl)
            inc hl
            ld d, (hl)
            inc hl
            push hl
            call asm_1_3817_n_fl_cmpf
            pop de
            ret z
            ld a, (de)              ; (the open's FCB still: this one from now on - unless it
            xor 1                   ; is the other file's: a program reading the record it
            ret nz                  ; writes, through that file's FCB)
            push de
            ld a, (var_hyp_fin)
            ld de, (asm_1_3817_n_fl_infcb)
            call asm_1_3817_n_fl_oth
            jr z, asm_1_3817_n_fl_is_no
            ld a, (var_hyp_fout)
            ld de, (asm_1_3817_n_fl_outfcb)
            call asm_1_3817_n_fl_oth
asm_1_3817_n_fl_is_no:
            pop de
            jr nz, asm_1_3817_n_fl_is_re
            inc a                   ; (NZ: not this one)
            ret
asm_1_3817_n_fl_is_re:
            xor a
            ld (de), a
            ld hl, (var_hyp_filecall_fcb)
            ex de, hl
            dec hl
            ld (hl), d
            dec hl
            ld (hl), e
            ret
asm_1_3817_n_fl_oth:                             ; Z: the slot's file (A: fin / fout), its FCB DE the call's
            ld b, a
            ld a, (asm_1_3817_n_fl_slot)
            cp b
            ret nz
asm_1_3817_n_fl_cmpf:                            ; Z: the call's FCB is DE
            ld hl, (var_hyp_filecall_fcb)
            or a
            sbc hl, de
            ret
    IFDEF NTC_MSXDOS
; ---- zxn: the boot archive is the drive here - the NEX's data banks (Option NexData in Main.bas,
; made by tools/nexarc/nexarc.py): block 0 the directory ("CARC", the entries as a word at 4, then
; from 16 an entry of 16 bytes each: the name 8 + 3, the length 3 bytes, the first record 2 bytes -
; 128 byte records from the archive's start), then the files. Read only, as the CPC's CAS IN:
; a file opened by name, read a record at a time. A record's page is mapped into slot 6 (#C000-
; #DFFF: page 10 there otherwise, nothing of the hypervisor's) while it is copied. In main RAM (not
; the window data: the page code calls it here - room below #6000 there)
asm_1_3817_n_fl_aopen:   db 0                    ; 1: a file is open
asm_1_3817_n_fl_arec:    dw 0                    ; its record being read (from the archive's start)
asm_1_3817_n_fl_aoff:    db 0                    ; where in that record the next byte is (0-127)
asm_1_3817_n_fl_aleft:   dw 0                    ; bytes left in it (65535 at most: a file is read to its end)
asm_1_3817_n_fl_aname:   ds 11                   ; the name looked for, 8 + 3 (spaces, capitals)
; fl_arc_pg - HL = a record number: its page into slot 6, HL = the record's address there (#C000-
; #DF80). Keeps BC, DE
asm_1_3817_n_fl_arc_pg:                          ; MSX: no boot archive - an empty directory (no entries)
            ld hl, asm_1_3817_n_fl_arc_none
            ret
asm_1_3817_n_fl_arc_none: ds 8
asm_1_3817_n_fl_arc_off:
            ret
; fl_arc_nm - fl_aname = fl_name_s's NAME.EXT as 8 + 3 (a drive "X:" in front skipped; no paths)
asm_1_3817_n_fl_arc_nm:
            ld hl, asm_1_3817_n_fl_aname
            ld b, 11
asm_1_3817_n_fl_an_sp:
            ld (hl), ' '
            inc hl
            djnz asm_1_3817_n_fl_an_sp
            ld hl, asm_1_3817_n_fl_name_s
            ld a, (hl)
            or a
            ret z
            ld b, a
            inc hl
            ld a, b
            cp 2
            jr c, asm_1_3817_n_fl_an_go
            inc hl
            ld a, (hl)
            dec hl
            cp ':'
            jr nz, asm_1_3817_n_fl_an_go
            inc hl                  ; "X:" skipped
            inc hl
            dec b
            dec b
            ret z
asm_1_3817_n_fl_an_go:
            ld de, asm_1_3817_n_fl_aname
            ld c, 8                 ; characters left in this part
asm_1_3817_n_fl_an_lp:
            ld a, (hl)
            inc hl
            cp '.'
            jr nz, asm_1_3817_n_fl_an_c
            ld de, asm_1_3817_n_fl_aname + 8     ; the extension
            ld c, 3
            jr asm_1_3817_n_fl_an_nx
asm_1_3817_n_fl_an_c:                            ; (capitals already: an FCB's, or Main's command line)
            inc c
            dec c
            jr z, asm_1_3817_n_fl_an_nx          ; (a part longer than its 8 / 3: the rest dropped)
            ld (de), a
            inc de
            dec c
asm_1_3817_n_fl_an_nx:
            djnz asm_1_3817_n_fl_an_lp
            ret
; (fl_inopen, fl_rdrec, fl_inclose are the SD card's sd_h_* here, which come to these - the
; archive's - for a name with no path)
asm_1_3817_n_fl_inopen: EQU sd_h_inopen
asm_1_3817_n_fl_rdrec: EQU sd_h_rdrec
asm_1_3817_n_fl_inclose: EQU sd_h_inclose
asm_1_3817_n_fl_inopen_a:                        ; open fl_name_s to read: carry = done
            call asm_1_3817_n_fl_arc_nm
            ld hl, 0
            call asm_1_3817_n_fl_arc_pg          ; the directory: HL = #C000
            ld de, 4
            add hl, de
            ld e, (hl)
            inc hl
            ld d, (hl)              ; DE = the entries
            ld bc, 0                ; BC = this entry
asm_1_3817_n_fl_ao_lp:
            ld a, c
            cp e
            ld a, b
            sbc a, d
            jr nc, asm_1_3817_n_fl_ao_no         ; (BC = DE: all seen)
            push bc
            push de
            inc bc                  ; the entry's record: (16 + 16 * n) / 128 = (n + 1) / 8
            ld h, b
            ld l, c
            srl h
            rr l
            srl h
            rr l
            srl h
            rr l
            call asm_1_3817_n_fl_arc_pg
            ld a, c                 ; in it: ((n + 1) and 7) * 16
            and 7
            add a, a
            add a, a
            add a, a
            add a, a
            add a, l
            ld l, a
            ld de, asm_1_3817_n_fl_aname
            ld b, 11
asm_1_3817_n_fl_ao_cmp:
            ld a, (de)
            cp (hl)
            jr nz, asm_1_3817_n_fl_ao_nx
            inc hl
            inc de
            djnz asm_1_3817_n_fl_ao_cmp
            ld e, (hl)              ; found: the length (its third byte: 65535 at most here)
            inc hl
            ld d, (hl)
            inc hl
            ld a, (hl)
            inc hl
            or a
            jr z, asm_1_3817_n_fl_ao_ln
            ld de, 65535
asm_1_3817_n_fl_ao_ln:
            ld (asm_1_3817_n_fl_aleft), de
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld (asm_1_3817_n_fl_arec), de        ; its first record
            xor a
            ld (asm_1_3817_n_fl_aoff), a
            inc a
            ld (asm_1_3817_n_fl_aopen), a
            pop de
            pop bc
            call asm_1_3817_n_fl_arc_off         ; (fl_hdr not set: BDOS 30 #C7 isn't answered here)
            call sd_h_ahdr          ; an AMSDOS header read past (as AMSDOS does on the CPC)
            scf
            ret
asm_1_3817_n_fl_ao_nx:
            pop de
            pop bc
            inc bc
            jr asm_1_3817_n_fl_ao_lp
asm_1_3817_n_fl_ao_no:
            call asm_1_3817_n_fl_arc_off
            or a
            ret
asm_1_3817_n_fl_inclose_a:
            xor a
            ld (var_hyp_fin), a
            ld (asm_1_3817_n_fl_aopen), a
            ret
asm_1_3817_n_fl_rdrec_a:                         ; read up to fl_n bytes (128) into buf: A = how many (Z
            ld a, (asm_1_3817_n_fl_aopen)        ; none), HL past them
            or a
            jr z, asm_1_3817_n_fl_rr_none
            ld a, (asm_1_3817_n_fl_n)
            ld b, a                 ; B = wanted
            ld a, (asm_1_3817_n_fl_aoff)
            ld c, a
            ld a, 128
            sub c                   ; what is left of this record
            cp b
            jr nc, asm_1_3817_n_fl_rr_w1
            ld b, a                 ; (fewer: to its end)
asm_1_3817_n_fl_rr_w1:
            ld de, (asm_1_3817_n_fl_aleft)
            ld a, d
            or a
            jr nz, asm_1_3817_n_fl_rr_w2
            ld a, e
            cp b
            jr nc, asm_1_3817_n_fl_rr_w2
            ld b, e                 ; (fewer: to the file's end)
asm_1_3817_n_fl_rr_w2:
            ld a, b
            or a
            jr z, asm_1_3817_n_fl_rr_none
            ld a, e                 ; left - B
            sub b
            ld e, a
            ld a, d
            sbc a, 0
            ld d, a
            ld (asm_1_3817_n_fl_aleft), de
            push bc
            ld hl, (asm_1_3817_n_fl_arec)
            call asm_1_3817_n_fl_arc_pg          ; HL = the record in slot 6
            ld a, (asm_1_3817_n_fl_aoff)
            add a, l
            ld l, a                 ; (+ 0-127: no carry out of the record's 128)
            ld de, (var_hyp_filecall_buf)
            pop bc
            ld a, c                 ; the offset on: 128 = the next record
            add a, b
            ld c, b
            ld b, 0
            push bc
            ldir
            pop bc
            ex de, hl               ; HL = buf past the bytes (the caller pads from there)
            cp 128
            jr c, asm_1_3817_n_fl_rr_off
            push hl
            ld hl, (asm_1_3817_n_fl_arec)
            inc hl
            ld (asm_1_3817_n_fl_arec), hl
            pop hl
            xor a
asm_1_3817_n_fl_rr_off:
            ld (asm_1_3817_n_fl_aoff), a
            call asm_1_3817_n_fl_arc_off
            ld a, 128
            ld (asm_1_3817_n_fl_n), a            ; (128 again for the next)
            ld a, c
            or a
            ret
asm_1_3817_n_fl_rr_none:
            ld a, 128
            ld (asm_1_3817_n_fl_n), a
            xor a
            ret
    ENDIF
asm_1_3817_n_fl_exit:
			ret			; end of #asm

asm_1_5850_n:		; #asm, Hyp.cls line 5850 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld bc, (var_hyp_hps)          ; (the buffers: the hypervisor's page)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld a, (var_hyp_fileshut_slot)
            ld b, a
            ld a, (var_hyp_fin)
            cp b
            jr nz, asm_1_5850_n_fs_out
            xor a
            ld (var_hyp_fin), a
    IFDEF NTC_MSXDOS
            push bc
            call sd_shut_in         ; (the SD card's file, when it is one)
            pop bc
    ELSE
            push bc
            call #BC7A              ; CAS IN CLOSE
            di
            pop bc
    ENDIF
asm_1_5850_n_fs_out:
            ld a, (var_hyp_fout)
            cp b
            jr nz, asm_1_5850_n_fs_done
            xor a
            ld (var_hyp_fout), a
    IFDEF NTC_MSXDOS
            call sd_shut_out
    ELSE
            call #BC8F              ; CAS OUT CLOSE
            di
    ENDIF
asm_1_5850_n_fs_done:
            ld bc, (ntc_rampt)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld sp, (var_hyp_hsp)
			ret			; end of #asm

fn_hyp_usesvc:		; sub usesvc (asm keyword), Hyp.cls line 5921
            ld hl, (ntc_rampt)
            ld (var_hyp_svp), hl
			ret			; end of #asm

asm_1_5940_n:		; #asm, Hyp.cls line 5940 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld (asm_1_5940_n_sv_ix), ix
            ld (asm_1_5940_n_sv_iy), iy
            di
            ld a, (var_hyp_svc_t)
            or a
            jr z, asm_1_5940_n_sv_inst
            ld bc, (var_hyp_svp)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            call asm_1_5940_n_sv_go              ; (in the service page) A = the answer
asm_1_5940_n_sv_back:
            di
            ld l, a
            ld h, 0
            ld (var_hyp_svc_svc), hl
            ld bc, (ntc_rampt)      ; the page that was in the window back
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld ix, (asm_1_5940_n_sv_ix)
            ld iy, (asm_1_5940_n_sv_iy)
            ld sp, (var_hyp_hsp)
            jp asm_1_5940_n_sv_exit
asm_1_5940_n_sv_inst:
            ld hl, #6000
asm_1_5940_n_sv_in_lp:
            push hl
            ld bc, #7FC0            ; main RAM's own
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld de, (var_hyp_svc_buf)
            ld bc, 128
            ldir
            ld bc, (var_hyp_svp)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            pop de
            push de
            ld hl, (var_hyp_svc_buf)
            ld bc, 128
            ldir
            pop hl
            ld bc, 128
            add hl, bc
            ld de, asm_1_5940_n_sv_end
            or a
            sbc hl, de
            add hl, de
            jr c, asm_1_5940_n_sv_in_lp
            xor a
            jr asm_1_5940_n_sv_back
asm_1_5940_n_sv_ix:      dw 0
asm_1_5940_n_sv_iy:      dw 0
; sv_dx - A bytes (1-128) from HL to DE through buf: IX = HL's RAM setting, IY = DE's (0: none -
; main RAM outside the window); the service page back in the window after. HL, DE on past them
asm_1_5940_n_sv_dx:
            ld (asm_1_5940_n_sv_dxn), a
            push de
            ld de, (var_hyp_svc_buf)
            push ix
            pop bc
            inc b
            dec b
            jr z, asm_1_5940_n_sv_dx1
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
asm_1_5940_n_sv_dx1:
            ld c, a
            ld b, 0
            ldir
            pop de
            push hl
            push iy
            pop bc
            inc b
            dec b
            jr z, asm_1_5940_n_sv_dx2
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
asm_1_5940_n_sv_dx2:
            ld hl, (var_hyp_svc_buf)
            ld a, (asm_1_5940_n_sv_dxn)
            ld c, a
            ld b, 0
            ldir
            pop hl
            ld bc, (var_hyp_svp)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ret
asm_1_5940_n_sv_dxn:     db 0
asm_1_5940_n_sv_exit:
			ret			; end of #asm

asm_1_9123_n:		; #asm, Hyp.cls line 9123 (normal)
            ld (var_hyp_hsp), sp
            ld sp, (ntc_csp)
            ld (asm_1_9123_n_dv_ix), ix
            ld (asm_1_9123_n_dv_iy), iy
            ld hl, 0
            ld (var_hyp_drive_drive), hl
            ld hl, (var_hyp_drive_letter)
            ld (var_hyp_hdr), hl
            IF NTC_ROMLIB = 0
            ld a, (var_hyp_drs + 1)
            or a
            jr z, asm_1_9123_n_dv_rsx
            ld (asm_1_9123_n_dv_blk + 2), hl
            di
            ld bc, (var_hyp_drs)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            ld ix, asm_1_9123_n_dv_blk
            call #4000
            ld bc, (ntc_rampt)
    IFDEF NTC_MSXDOS
            call msx_win
    ELSE
            out (c), c
    ENDIF
            jr nc, asm_1_9123_n_dv_rsx
            ld hl, -1
            ld (var_hyp_drive_drive), hl
            jr asm_1_9123_n_dv_done
asm_1_9123_n_dv_blk:     dw 114, 0, 0, 0, 0, 0, 0
            ENDIF
asm_1_9123_n_dv_rsx:
    IFDEF NTC_MSXDOS
            jr asm_1_9123_n_dv_done              ; zxn: no ROM commands (KL FIND COMMAND): False
    ENDIF
            ld a, (var_hyp_drive_letter)
            or #80                  ; a one letter command name: its last letter + #80
            ld (asm_1_9123_n_dv_nm), a
            ld hl, asm_1_9123_n_dv_nm
            call #BCD4              ; KL FIND COMMAND: carry = found, C = its ROM, HL = its address
            di
            jr nc, asm_1_9123_n_dv_done
            xor a                   ; no parameters
            call #001B              ; KL FAR PCALL
            di
            ld hl, -1
            ld (var_hyp_drive_drive), hl
            jr asm_1_9123_n_dv_done
asm_1_9123_n_dv_nm:      db 0
asm_1_9123_n_dv_ix:      dw 0
asm_1_9123_n_dv_iy:      dw 0
asm_1_9123_n_dv_done:
            ld ix, (asm_1_9123_n_dv_ix)
            ld iy, (asm_1_9123_n_dv_iy)
            ld sp, (var_hyp_hsp)
			ret			; end of #asm

fn_hot_row:		; function row (asm keyword), Hot.cls line 91
            pop hl                  ; r
            ld e, (hl)
            in a, (#AA)
            and #F0
            or e
            out (#AA), a
            in a, (#A9)
            pop hl                  ; the result
            ld (hl), a
            inc hl
            ld (hl), 0
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

fn_memory_banks:		; function banks (asm keyword), Memory.cls line 415
            pop hl
            ld (mem_res), hl
            ld hl, mem_bankcount
            jp mem_go
			ret			; end of #asm

fn_memory_allocbank:		; function allocbank (asm keyword), Memory.cls line 425
            pop hl
            ld (mem_res), hl
            ld hl, mem_allocbank
            jp mem_go
			ret			; end of #asm


ntc_rg41_e:
			IF ($ < 32768) && (ntc_rg42_e - ntc_rg42 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg42:
; ============================================================
; Variables
; ============================================================

ntc_rg42_e:
			IF ($ < 32768) && (ntc_rg43_e - ntc_rg43 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg43:
var_k:			dw 0
ntc_rg43_e:
			IF ($ < 32768) && (ntc_rg44_e - ntc_rg44 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg44:
var_ns:			dw 0
ntc_rg44_e:
			IF ($ < 32768) && (ntc_rg45_e - ntc_rg45 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg45:
var_i:			dw 0
ntc_rg45_e:
			IF ($ < 32768) && (ntc_rg46_e - ntc_rg46 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg46:
var_hp:			dw 0
ntc_rg46_e:
			IF ($ < 32768) && (ntc_rg47_e - ntc_rg47 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg47:
var_memory_selectpage_selectpage:			dw 0
ntc_rg47_e:
			IF ($ < 32768) && (ntc_rg48_e - ntc_rg48 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg48:
var_front:			dw 0
ntc_rg48_e:
			IF ($ < 32768) && (ntc_rg49_e - ntc_rg49 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg49:
var_dp:			dw 0
ntc_rg49_e:
			IF ($ < 32768) && (ntc_rg50_e - ntc_rg50 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg50:
var_bz:			dw 0
ntc_rg50_e:
			IF ($ < 32768) && (ntc_rg51_e - ntc_rg51 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg51:
var_hyp_filecall_filecall:			dw 0
ntc_rg51_e:
			IF ($ < 32768) && (ntc_rg52_e - ntc_rg52 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg52:
var_hyp_svc_svc:			dw 0
ntc_rg52_e:
			IF ($ < 32768) && (ntc_rg53_e - ntc_rg53 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg53:
for3_l:			dw 0
ntc_rg53_e:
			IF ($ < 32768) && (ntc_rg54_e - ntc_rg54 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg54:
var_memory_allocbank_allocbank:			dw 0
ntc_rg54_e:
			IF ($ < 32768) && (ntc_rg55_e - ntc_rg55 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg55:
var_memory_bankpage_bankpage:			dw 0
ntc_rg55_e:
			IF ($ < 32768) && (ntc_rg56_e - ntc_rg56 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg56:
var_hyp_setting_setting:			dw 0
ntc_rg56_e:
			IF ($ < 32768) && (ntc_rg57_e - ntc_rg57 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg57:
var_kwp:			dw 0
ntc_rg57_e:
			IF ($ < 32768) && (ntc_rg58_e - ntc_rg58 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg58:
			db 72			; capacity
var_a:			ds 73
ntc_rg58_e:
			IF ($ < 32768) && (ntc_rg59_e - ntc_rg59 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg59:
var_bd:			dw 0
ntc_rg59_e:
			IF ($ < 32768) && (ntc_rg60_e - ntc_rg60 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg60:
var_mz:			dw 0
ntc_rg60_e:
			IF ($ < 32768) && (ntc_rg61_e - ntc_rg61 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg61:
var_nz:			dw 0
ntc_rg61_e:
			IF ($ < 32768) && (ntc_rg62_e - ntc_rg62 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg62:
var_probediscs_probediscs:			dw 0
ntc_rg62_e:
			IF ($ < 32768) && (ntc_rg63_e - ntc_rg63 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg63:
var_hyp_drive_drive:			dw 0
ntc_rg63_e:
			IF ($ < 32768) && (ntc_rg64_e - ntc_rg64 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg64:
			db 16			; capacity
var_dn:			ds 17
ntc_rg64_e:
			IF ($ < 32768) && (ntc_rg65_e - ntc_rg65 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg65:
var_far_far:			dw 0, 0
ntc_rg65_e:
			IF ($ < 32768) && (ntc_rg66_e - ntc_rg66 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg66:
var_kra:			dw 0
ntc_rg66_e:
			IF ($ < 32768) && (ntc_rg67_e - ntc_rg67 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg67:
var_hyp_run_run:			dw 0
ntc_rg67_e:
			IF ($ < 32768) && (ntc_rg68_e - ntc_rg68 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg68:
var_hyp_count_count:			dw 0
ntc_rg68_e:
			IF ($ < 32768) && (ntc_rg69_e - ntc_rg69 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg69:
var_hyp_fn_fn:			dw 0
ntc_rg69_e:
			IF ($ < 32768) && (ntc_rg70_e - ntc_rg70 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg70:
p_serve_rs:			dw 0
ntc_rg70_e:
			IF ($ < 32768) && (ntc_rg71_e - ntc_rg71 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg71:
var_serve_t:			dw 0
ntc_rg71_e:
			IF ($ < 32768) && (ntc_rg72_e - ntc_rg72 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg72:
var_serve_c:			dw 0
ntc_rg72_e:
			IF ($ < 32768) && (ntc_rg73_e - ntc_rg73 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg73:
var_serve___sel17:			dw 0
ntc_rg73_e:
			IF ($ < 32768) && (ntc_rg74_e - ntc_rg74 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg74:
var_cw:			dw 0
ntc_rg74_e:
			IF ($ < 32768) && (ntc_rg75_e - ntc_rg75 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg75:
var_hyp_arg_arg:			dw 0
ntc_rg75_e:
			IF ($ < 32768) && (ntc_rg76_e - ntc_rg76 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg76:
var_ca:			dw 0
ntc_rg76_e:
			IF ($ < 32768) && (ntc_rg77_e - ntc_rg77 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg77:
var_hot_take_take:			dw 0
ntc_rg77_e:
			IF ($ < 32768) && (ntc_rg78_e - ntc_rg78 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg78:
var_hot_control_control:			dw 0
ntc_rg78_e:
			IF ($ < 32768) && (ntc_rg79_e - ntc_rg79 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg79:
var_hot_held_held:			dw 0
ntc_rg79_e:
			IF ($ < 32768) && (ntc_rg80_e - ntc_rg80 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg80:
var_nearp_nearp:			dw 0, 0
ntc_rg80_e:
			IF ($ < 32768) && (ntc_rg81_e - ntc_rg81 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg81:
var_memory_copy_copy:			dw 0
ntc_rg81_e:
			IF ($ < 32768) && (ntc_rg82_e - ntc_rg82 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg82:
var_hyp_scr_scr:			dw 0
ntc_rg82_e:
			IF ($ < 32768) && (ntc_rg83_e - ntc_rg83 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg83:
var_ramdisc_ramdisc:			dw 0
ntc_rg83_e:
			IF ($ < 32768) && (ntc_rg84_e - ntc_rg84 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg84:
var_storesize_storesize:			dw 0
ntc_rg84_e:
			IF ($ < 32768) && (ntc_rg85_e - ntc_rg85 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg85:
			db 60			; capacity
var_en:			ds 61
ntc_rg85_e:
			IF ($ < 32768) && (ntc_rg86_e - ntc_rg86 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg86:
			db 72			; capacity
var_memory_map_map:			ds 73
ntc_rg86_e:
			IF ($ < 32768) && (ntc_rg87_e - ntc_rg87 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg87:
var_hyp_t300_t300:			dw 0
ntc_rg87_e:
			IF ($ < 32768) && (ntc_rg88_e - ntc_rg88 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg88:
var_ksp:			dw 0
ntc_rg88_e:
			IF ($ < 32768) && (ntc_rg89_e - ntc_rg89 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg89:
p_kdin_rs:			dw 0
ntc_rg89_e:
			IF ($ < 32768) && (ntc_rg90_e - ntc_rg90 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg90:
var_kdin_p:			dw 0
ntc_rg90_e:
			IF ($ < 32768) && (ntc_rg91_e - ntc_rg91 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg91:
var_kdin_n:			dw 0
ntc_rg91_e:
			IF ($ < 32768) && (ntc_rg92_e - ntc_rg92 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg92:
p_kdout_rs:			dw 0
ntc_rg92_e:
			IF ($ < 32768) && (ntc_rg93_e - ntc_rg93 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg93:
var_kdout_p:			dw 0
ntc_rg93_e:
			IF ($ < 32768) && (ntc_rg94_e - ntc_rg94 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg94:
var_kdout_n:			dw 0
ntc_rg94_e:
			IF ($ < 32768) && (ntc_rg95_e - ntc_rg95 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg95:
p_kshow_rs:			dw 0
ntc_rg95_e:
			IF ($ < 32768) && (ntc_rg96_e - ntc_rg96 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg96:
var_kshow_n:			dw 0
ntc_rg96_e:
			IF ($ < 32768) && (ntc_rg97_e - ntc_rg97 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg97:
var_kshow_t:			dw 0
ntc_rg97_e:
			IF ($ < 32768) && (ntc_rg98_e - ntc_rg98 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg98:
p_quit_rs:			dw 0
ntc_rg98_e:
			IF ($ < 32768) && (ntc_rg99_e - ntc_rg99 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg99:
var_quit_n:			dw 0
ntc_rg99_e:
			IF ($ < 32768) && (ntc_rg100_e - ntc_rg100 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg100:
p_owncall_rs:			dw 0
ntc_rg100_e:
			IF ($ < 32768) && (ntc_rg101_e - ntc_rg101 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg101:
var_owncall_t:			dw 0
ntc_rg101_e:
			IF ($ < 32768) && (ntc_rg102_e - ntc_rg102 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg102:
var_owncall_f:			dw 0
ntc_rg102_e:
			IF ($ < 32768) && (ntc_rg103_e - ntc_rg103 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg103:
var_owncall_e:			dw 0
ntc_rg103_e:
			IF ($ < 32768) && (ntc_rg104_e - ntc_rg104 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg104:
var_owncall_j:			dw 0
ntc_rg104_e:
			IF ($ < 32768) && (ntc_rg105_e - ntc_rg105 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg105:
var_owncall_o:			dw 0
ntc_rg105_e:
			IF ($ < 32768) && (ntc_rg106_e - ntc_rg106 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg106:
var_owncall___sel33:			dw 0
ntc_rg106_e:
			IF ($ < 32768) && (ntc_rg107_e - ntc_rg107 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg107:
for36_l:			dw 0
ntc_rg107_e:
			IF ($ < 32768) && (ntc_rg108_e - ntc_rg108 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg108:
var_memory_readword_readword:			dw 0
ntc_rg108_e:
			IF ($ < 32768) && (ntc_rg109_e - ntc_rg109 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg109:
p_ramdisc_rs:			dw 0
ntc_rg109_e:
			IF ($ < 32768) && (ntc_rg110_e - ntc_rg110 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg110:
var_ramdisc_t:			dw 0
ntc_rg110_e:
			IF ($ < 32768) && (ntc_rg111_e - ntc_rg111 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg111:
var_ramdisc_p:			dw 0
ntc_rg111_e:
			IF ($ < 32768) && (ntc_rg112_e - ntc_rg112 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg112:
var_ramdisc_g:			dw 0
ntc_rg112_e:
			IF ($ < 32768) && (ntc_rg113_e - ntc_rg113 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg113:
var_ramdisc_o:			dw 0
ntc_rg113_e:
			IF ($ < 32768) && (ntc_rg114_e - ntc_rg114 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg114:
var_ramdisc_f:			dw 0, 0
ntc_rg114_e:
			IF ($ < 32768) && (ntc_rg115_e - ntc_rg115 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg115:
var_hyp_farptr_farptr:			dw 0, 0
ntc_rg115_e:
			IF ($ < 32768) && (ntc_rg116_e - ntc_rg116 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg116:
p_storesize_rs:			dw 0
ntc_rg116_e:
			IF ($ < 32768) && (ntc_rg117_e - ntc_rg117 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg117:
var_storesize_t:			dw 0
ntc_rg117_e:
			IF ($ < 32768) && (ntc_rg118_e - ntc_rg118 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg118:
var_storesize_kb:			dw 0
ntc_rg118_e:
			IF ($ < 32768) && (ntc_rg119_e - ntc_rg119 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg119:
var_storesize_n:			dw 0
ntc_rg119_e:
			IF ($ < 32768) && (ntc_rg120_e - ntc_rg120 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg120:
var_storesize_j:			dw 0
ntc_rg120_e:
			IF ($ < 32768) && (ntc_rg121_e - ntc_rg121 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg121:
var_storesize_g:			dw 0
ntc_rg121_e:
			IF ($ < 32768) && (ntc_rg122_e - ntc_rg122 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg122:
var_memory_freepage_freepage:			dw 0
ntc_rg122_e:
			IF ($ < 32768) && (ntc_rg123_e - ntc_rg123 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg123:
p_probediscs_rs:			dw 0
ntc_rg123_e:
			IF ($ < 32768) && (ntc_rg124_e - ntc_rg124 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg124:
var_probediscs_p:			dw 0
ntc_rg124_e:
			IF ($ < 32768) && (ntc_rg125_e - ntc_rg125 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg125:
var_probediscs_su:			dw 0
ntc_rg125_e:
			IF ($ < 32768) && (ntc_rg126_e - ntc_rg126 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg126:
var_probediscs_j:			dw 0
ntc_rg126_e:
			IF ($ < 32768) && (ntc_rg127_e - ntc_rg127 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg127:
var_probediscs_a:			dw 0
ntc_rg127_e:
			IF ($ < 32768) && (ntc_rg128_e - ntc_rg128 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg128:
var_probediscs_pg:			dw 0
ntc_rg128_e:
			IF ($ < 32768) && (ntc_rg129_e - ntc_rg129 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg129:
var_probediscs_r:			dw 0
ntc_rg129_e:
			IF ($ < 32768) && (ntc_rg130_e - ntc_rg130 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg130:
for50_l:			dw 0
ntc_rg130_e:
			IF ($ < 32768) && (ntc_rg131_e - ntc_rg131 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg131:
var_memory_pagetype_pagetype:			dw 0
ntc_rg131_e:
			IF ($ < 32768) && (ntc_rg132_e - ntc_rg132 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg132:
var_hyp_claimpage_claimpage:			dw 0
ntc_rg132_e:
			IF ($ < 32768) && (ntc_rg133_e - ntc_rg133 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg133:
p_nearp_rs:			dw 0
ntc_rg133_e:
			IF ($ < 32768) && (ntc_rg134_e - ntc_rg134 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg134:
var_nearp_p:			dw 0
ntc_rg134_e:
			IF ($ < 32768) && (ntc_rg135_e - ntc_rg135 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg135:
p_far_rs:			dw 0
ntc_rg135_e:
			IF ($ < 32768) && (ntc_rg136_e - ntc_rg136 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg136:
var_far_t:			dw 0
ntc_rg136_e:
			IF ($ < 32768) && (ntc_rg137_e - ntc_rg137 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg137:
var_far_a:			dw 0
ntc_rg137_e:
			IF ($ < 32768) && (ntc_rg138_e - ntc_rg138 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg138:
p_install_rs:			dw 0
ntc_rg138_e:
			IF ($ < 32768) && (ntc_rg139_e - ntc_rg139 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg139:
var_install_t:			dw 0
ntc_rg139_e:
			IF ($ < 32768) && (ntc_rg140_e - ntc_rg140 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg140:
var_install_p:			dw 0
ntc_rg140_e:
			IF ($ < 32768) && (ntc_rg141_e - ntc_rg141 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg141:
var_install_n:			dw 0
ntc_rg141_e:
			IF ($ < 32768) && (ntc_rg142_e - ntc_rg142 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg142:
var_hyp_seg_seg:			dw 0
ntc_rg142_e:
			IF ($ < 32768) && (ntc_rg143_e - ntc_rg143 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg143:
p_launch_rs:			dw 0
ntc_rg143_e:
			IF ($ < 32768) && (ntc_rg144_e - ntc_rg144 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg144:
var_launch_s:			dw 0
ntc_rg144_e:
			IF ($ < 32768) && (ntc_rg145_e - ntc_rg145 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg145:
var_hyp_info_info:			dw 0
ntc_rg145_e:
			IF ($ < 32768) && (ntc_rg146_e - ntc_rg146 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg146:
var_hyp_hps:			dw 0
ntc_rg146_e:
			IF ($ < 32768) && (ntc_rg147_e - ntc_rg147 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg147:
p_hyp_usedriver_rs:			dw 0
ntc_rg147_e:
			IF ($ < 32768) && (ntc_rg148_e - ntc_rg148 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg148:
var_hyp_usedriver_b:			dw 0
ntc_rg148_e:
			IF ($ < 32768) && (ntc_rg149_e - ntc_rg149 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg149:
var_hyp_dxb:			dw 0
ntc_rg149_e:
			IF ($ < 32768) && (ntc_rg150_e - ntc_rg150 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg150:
var_hyp_drs:			dw 0
ntc_rg150_e:
			IF ($ < 32768) && (ntc_rg151_e - ntc_rg151 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg151:
p_hyp_claimpage_rs:			dw 0
ntc_rg151_e:
			IF ($ < 32768) && (ntc_rg152_e - ntc_rg152 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg152:
var_hyp_claimpage_page:			dw 0
ntc_rg152_e:
			IF ($ < 32768) && (ntc_rg153_e - ntc_rg153 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg153:
var_hyp_hsp:			dw 0
ntc_rg153_e:
			IF ($ < 32768) && (ntc_rg154_e - ntc_rg154 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg154:
p_hyp_con_rs:			dw 0
ntc_rg154_e:
			IF ($ < 32768) && (ntc_rg155_e - ntc_rg155 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg155:
var_hyp_con_pg:			dw 0
ntc_rg155_e:
			IF ($ < 32768) && (ntc_rg156_e - ntc_rg156 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg156:
var_hyp_con_src:			dw 0
ntc_rg156_e:
			IF ($ < 32768) && (ntc_rg157_e - ntc_rg157 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg157:
var_hyp_con_n:			dw 0
ntc_rg157_e:
			IF ($ < 32768) && (ntc_rg158_e - ntc_rg158 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg158:
var_hyp_con_front:			dw 0
ntc_rg158_e:
			IF ($ < 32768) && (ntc_rg159_e - ntc_rg159 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg159:
var_hyp_ccu:			dw 0
ntc_rg159_e:
			IF ($ < 32768) && (ntc_rg160_e - ntc_rg160 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg160:
var_hyp_nta:			dw 0
ntc_rg160_e:
			IF ($ < 32768) && (ntc_rg161_e - ntc_rg161 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg161:
var_hyp_ntb:			dw 0
ntc_rg161_e:
			IF ($ < 32768) && (ntc_rg162_e - ntc_rg162 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg162:
var_hyp_sco:			dw 0
ntc_rg162_e:
			IF ($ < 32768) && (ntc_rg163_e - ntc_rg163 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg163:
var_hyp_scc:			dw 0
ntc_rg163_e:
			IF ($ < 32768) && (ntc_rg164_e - ntc_rg164 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg164:
var_hyp_pon:			dw 0
ntc_rg164_e:
			IF ($ < 32768) && (ntc_rg165_e - ntc_rg165 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg165:
var_hyp_ntu:			dw 0
ntc_rg165_e:
			IF ($ < 32768) && (ntc_rg166_e - ntc_rg166 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg166:
p_hyp_say_rs:			dw 0
ntc_rg166_e:
			IF ($ < 32768) && (ntc_rg167_e - ntc_rg167 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg167:
var_hyp_say_p:			dw 0
ntc_rg167_e:
			IF ($ < 32768) && (ntc_rg168_e - ntc_rg168 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg168:
var_hyp_say_n:			dw 0
ntc_rg168_e:
			IF ($ < 32768) && (ntc_rg169_e - ntc_rg169 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg169:
var_hyp_say_col:			dw 0
ntc_rg169_e:
			IF ($ < 32768) && (ntc_rg170_e - ntc_rg170 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg170:
var_hyp_say_row:			dw 0
ntc_rg170_e:
			IF ($ < 32768) && (ntc_rg171_e - ntc_rg171 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg171:
p_hyp_scr_rs:			dw 0
ntc_rg171_e:
			IF ($ < 32768) && (ntc_rg172_e - ntc_rg172 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg172:
var_hyp_scr_m:			dw 0
ntc_rg172_e:
			IF ($ < 32768) && (ntc_rg173_e - ntc_rg173 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg173:
var_hyp_scr_k:			dw 0
ntc_rg173_e:
			IF ($ < 32768) && (ntc_rg174_e - ntc_rg174 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg174:
var_hyp_scw:			dw 0
ntc_rg174_e:
			IF ($ < 32768) && (ntc_rg175_e - ntc_rg175 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg175:
p_hyp_keyrep_rs:			dw 0
ntc_rg175_e:
			IF ($ < 32768) && (ntc_rg176_e - ntc_rg176 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg176:
var_hyp_keyrep_f:			dw 0
ntc_rg176_e:
			IF ($ < 32768) && (ntc_rg177_e - ntc_rg177 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg177:
p_hyp_reply_rs:			dw 0
ntc_rg177_e:
			IF ($ < 32768) && (ntc_rg178_e - ntc_rg178 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg178:
var_hyp_reply_a:			dw 0
ntc_rg178_e:
			IF ($ < 32768) && (ntc_rg179_e - ntc_rg179 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg179:
var_hyp_reply_hl:			dw 0
ntc_rg179_e:
			IF ($ < 32768) && (ntc_rg180_e - ntc_rg180 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg180:
var_hyp_ra:			dw 0
ntc_rg180_e:
			IF ($ < 32768) && (ntc_rg181_e - ntc_rg181 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg181:
var_hyp_rhl:			dw 0
ntc_rg181_e:
			IF ($ < 32768) && (ntc_rg182_e - ntc_rg182 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg182:
p_hyp_fn_rs:			dw 0
ntc_rg182_e:
			IF ($ < 32768) && (ntc_rg183_e - ntc_rg183 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg183:
var_hyp_rfn:			dw 0
ntc_rg183_e:
			IF ($ < 32768) && (ntc_rg184_e - ntc_rg184 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg184:
p_hyp_arg_rs:			dw 0
ntc_rg184_e:
			IF ($ < 32768) && (ntc_rg185_e - ntc_rg185 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg185:
var_hyp_rde:			dw 0
ntc_rg185_e:
			IF ($ < 32768) && (ntc_rg186_e - ntc_rg186 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg186:
p_hyp_count_rs:			dw 0
ntc_rg186_e:
			IF ($ < 32768) && (ntc_rg187_e - ntc_rg187 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg187:
var_hyp_rcnt:			dw 0
ntc_rg187_e:
			IF ($ < 32768) && (ntc_rg188_e - ntc_rg188 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg188:
p_hyp_run_rs:			dw 0
ntc_rg188_e:
			IF ($ < 32768) && (ntc_rg189_e - ntc_rg189 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg189:
var_hyp_run_setting:			dw 0
ntc_rg189_e:
			IF ($ < 32768) && (ntc_rg190_e - ntc_rg190 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg190:
var_hyp_sps:			dw 0
ntc_rg190_e:
			IF ($ < 32768) && (ntc_rg191_e - ntc_rg191 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg191:
var_hyp_rrom:			dw 0
ntc_rg191_e:
			IF ($ < 32768) && (ntc_rg192_e - ntc_rg192 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg192:
var_hyp_slc:			dw 0
ntc_rg192_e:
			IF ($ < 32768) && (ntc_rg193_e - ntc_rg193 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg193:
var_hyp_rclr:			dw 0
ntc_rg193_e:
			IF ($ < 32768) && (ntc_rg194_e - ntc_rg194 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg194:
p_hyp_t300_rs:			dw 0
ntc_rg194_e:
			IF ($ < 32768) && (ntc_rg195_e - ntc_rg195 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg195:
p_hyp_vdu_rs:			dw 0
ntc_rg195_e:
			IF ($ < 32768) && (ntc_rg196_e - ntc_rg196 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg196:
var_hyp_vdu_on:			dw 0
ntc_rg196_e:
			IF ($ < 32768) && (ntc_rg197_e - ntc_rg197 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg197:
p_hyp_filecall_rs:			dw 0
ntc_rg197_e:
			IF ($ < 32768) && (ntc_rg198_e - ntc_rg198 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg198:
var_hyp_filecall_f:			dw 0
ntc_rg198_e:
			IF ($ < 32768) && (ntc_rg199_e - ntc_rg199 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg199:
var_hyp_filecall_fcb:			dw 0
ntc_rg199_e:
			IF ($ < 32768) && (ntc_rg200_e - ntc_rg200 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg200:
var_hyp_filecall_slot:			dw 0
ntc_rg200_e:
			IF ($ < 32768) && (ntc_rg201_e - ntc_rg201 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg201:
var_hyp_filecall_setting:			dw 0
ntc_rg201_e:
			IF ($ < 32768) && (ntc_rg202_e - ntc_rg202 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg202:
var_hyp_filecall_dma:			dw 0
ntc_rg202_e:
			IF ($ < 32768) && (ntc_rg203_e - ntc_rg203 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg203:
var_hyp_filecall_drive:			dw 0
ntc_rg203_e:
			IF ($ < 32768) && (ntc_rg204_e - ntc_rg204 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg204:
var_hyp_filecall_buf:			dw 0
ntc_rg204_e:
			IF ($ < 32768) && (ntc_rg205_e - ntc_rg205 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg205:
var_hyp_hdr:			dw 0
ntc_rg205_e:
			IF ($ < 32768) && (ntc_rg206_e - ntc_rg206 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg206:
var_hyp_fin:			dw 0
ntc_rg206_e:
			IF ($ < 32768) && (ntc_rg207_e - ntc_rg207 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg207:
var_hyp_fout:			dw 0
ntc_rg207_e:
			IF ($ < 32768) && (ntc_rg208_e - ntc_rg208 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg208:
p_hyp_fileshut_rs:			dw 0
ntc_rg208_e:
			IF ($ < 32768) && (ntc_rg209_e - ntc_rg209 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg209:
var_hyp_fileshut_slot:			dw 0
ntc_rg209_e:
			IF ($ < 32768) && (ntc_rg210_e - ntc_rg210 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg210:
var_hyp_svp:			dw 0
ntc_rg210_e:
			IF ($ < 32768) && (ntc_rg211_e - ntc_rg211 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg211:
p_hyp_svcvars_rs:			dw 0
ntc_rg211_e:
			IF ($ < 32768) && (ntc_rg212_e - ntc_rg212 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg212:
var_hyp_svcvars_vst:			dw 0
ntc_rg212_e:
			IF ($ < 32768) && (ntc_rg213_e - ntc_rg213 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg213:
var_hyp_svcvars_vsg:			dw 0
ntc_rg213_e:
			IF ($ < 32768) && (ntc_rg214_e - ntc_rg214 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg214:
var_hyp_svcvars_vns:			dw 0
ntc_rg214_e:
			IF ($ < 32768) && (ntc_rg215_e - ntc_rg215 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg215:
var_hyp_svcvars_vfr:			dw 0
ntc_rg215_e:
			IF ($ < 32768) && (ntc_rg216_e - ntc_rg216 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg216:
var_hyp_svcvars_vdp:			dw 0
ntc_rg216_e:
			IF ($ < 32768) && (ntc_rg217_e - ntc_rg217 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg217:
var_hyp_svst:			dw 0
ntc_rg217_e:
			IF ($ < 32768) && (ntc_rg218_e - ntc_rg218 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg218:
var_hyp_svsg:			dw 0
ntc_rg218_e:
			IF ($ < 32768) && (ntc_rg219_e - ntc_rg219 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg219:
var_hyp_svns:			dw 0
ntc_rg219_e:
			IF ($ < 32768) && (ntc_rg220_e - ntc_rg220 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg220:
var_hyp_svfr:			dw 0
ntc_rg220_e:
			IF ($ < 32768) && (ntc_rg221_e - ntc_rg221 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg221:
var_hyp_svdp:			dw 0
ntc_rg221_e:
			IF ($ < 32768) && (ntc_rg222_e - ntc_rg222 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg222:
p_hyp_bootdrive_rs:			dw 0
ntc_rg222_e:
			IF ($ < 32768) && (ntc_rg223_e - ntc_rg223 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg223:
var_hyp_bootdrive_d:			dw 0
ntc_rg223_e:
			IF ($ < 32768) && (ntc_rg224_e - ntc_rg224 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg224:
var_hyp_bootdrive_vdv:			dw 0
ntc_rg224_e:
			IF ($ < 32768) && (ntc_rg225_e - ntc_rg225 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg225:
var_hyp_svbd:			dw 0
ntc_rg225_e:
			IF ($ < 32768) && (ntc_rg226_e - ntc_rg226 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg226:
var_hyp_svdv:			dw 0
ntc_rg226_e:
			IF ($ < 32768) && (ntc_rg227_e - ntc_rg227 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg227:
p_hyp_svc_rs:			dw 0
ntc_rg227_e:
			IF ($ < 32768) && (ntc_rg228_e - ntc_rg228 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg228:
var_hyp_svc_t:			dw 0
ntc_rg228_e:
			IF ($ < 32768) && (ntc_rg229_e - ntc_rg229 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg229:
var_hyp_svc_p:			dw 0
ntc_rg229_e:
			IF ($ < 32768) && (ntc_rg230_e - ntc_rg230 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg230:
var_hyp_svc_setting:			dw 0
ntc_rg230_e:
			IF ($ < 32768) && (ntc_rg231_e - ntc_rg231 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg231:
var_hyp_svc_buf:			dw 0
ntc_rg231_e:
			IF ($ < 32768) && (ntc_rg232_e - ntc_rg232 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg232:
var_hyp_pox:			dw 0
ntc_rg232_e:
			IF ($ < 32768) && (ntc_rg233_e - ntc_rg233 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg233:
var_hyp_poy:			dw 0
ntc_rg233_e:
			IF ($ < 32768) && (ntc_rg234_e - ntc_rg234 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg234:
p_hyp_drive_rs:			dw 0
ntc_rg234_e:
			IF ($ < 32768) && (ntc_rg235_e - ntc_rg235 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg235:
var_hyp_drive_letter:			dw 0
ntc_rg235_e:
			IF ($ < 32768) && (ntc_rg236_e - ntc_rg236 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg236:
p_hot_speed_rs:			dw 0
ntc_rg236_e:
			IF ($ < 32768) && (ntc_rg237_e - ntc_rg237 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg237:
var_hot_speed_f:			dw 0
ntc_rg237_e:
			IF ($ < 32768) && (ntc_rg238_e - ntc_rg238 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg238:
var_hot_dbl:			dw 0
ntc_rg238_e:
			IF ($ < 32768) && (ntc_rg239_e - ntc_rg239 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg239:
p_hot_slots_rs:			dw 0
ntc_rg239_e:
			IF ($ < 32768) && (ntc_rg240_e - ntc_rg240 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg240:
var_hot_slots_n:			dw 0
ntc_rg240_e:
			IF ($ < 32768) && (ntc_rg241_e - ntc_rg241 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg241:
var_hot_ns:			dw 0
ntc_rg241_e:
			IF ($ < 32768) && (ntc_rg242_e - ntc_rg242 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg242:
p_hot_tick_rs:			dw 0
ntc_rg242_e:
			IF ($ < 32768) && (ntc_rg243_e - ntc_rg243 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg243:
var_hot_tick_k:			dw 0
ntc_rg243_e:
			IF ($ < 32768) && (ntc_rg244_e - ntc_rg244 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg244:
var_hot_tick_i:			dw 0
ntc_rg244_e:
			IF ($ < 32768) && (ntc_rg245_e - ntc_rg245 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg245:
var_hot_tick_j:			dw 0
ntc_rg245_e:
			IF ($ < 32768) && (ntc_rg246_e - ntc_rg246 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg246:
var_hot_ctl:			dw 0
ntc_rg246_e:
			IF ($ < 32768) && (ntc_rg247_e - ntc_rg247 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg247:
var_hot_row_row:			dw 0
ntc_rg247_e:
			IF ($ < 32768) && (ntc_rg248_e - ntc_rg248 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg248:
var_hot_last:			dw 0
ntc_rg248_e:
			IF ($ < 32768) && (ntc_rg249_e - ntc_rg249 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg249:
var_hot_one:			dw 0
ntc_rg249_e:
			IF ($ < 32768) && (ntc_rg250_e - ntc_rg250 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg250:
var_hot_pend:			dw 0
ntc_rg250_e:
			IF ($ < 32768) && (ntc_rg251_e - ntc_rg251 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg251:
var_hot_age:			dw 0
ntc_rg251_e:
			IF ($ < 32768) && (ntc_rg252_e - ntc_rg252 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg252:
p_hot_take_rs:			dw 0
ntc_rg252_e:
			IF ($ < 32768) && (ntc_rg253_e - ntc_rg253 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg253:
p_hot_control_rs:			dw 0
ntc_rg253_e:
			IF ($ < 32768) && (ntc_rg254_e - ntc_rg254 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg254:
p_hot_held_rs:			dw 0
ntc_rg254_e:
			IF ($ < 32768) && (ntc_rg255_e - ntc_rg255 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg255:
p_memory_bankpage_rs:			dw 0
ntc_rg255_e:
			IF ($ < 32768) && (ntc_rg256_e - ntc_rg256 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg256:
var_memory_bankpage_bank:			dw 0
ntc_rg256_e:
			IF ($ < 32768) && (ntc_rg257_e - ntc_rg257 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg257:
var_memory_bankpage_n:			dw 0
ntc_rg257_e:
			IF ($ < 32768) && (ntc_rg258_e - ntc_rg258 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg258:
tmp0:			dw 0
ntc_rg258_e:
			IF ($ < 32768) && (ntc_rg259_e - ntc_rg259 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg259:
tmp1:			dw 0
ntc_rg259_e:
			IF ($ < 32768) && (ntc_rg260_e - ntc_rg260 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg260:
tmp2:			dw 0
ntc_rg260_e:
			IF ($ < 32768) && (ntc_rg261_e - ntc_rg261 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg261:
tmp3:			dw 0
ntc_rg261_e:
			IF ($ < 32768) && (ntc_rg262_e - ntc_rg262 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg262:
tmp4:			dw 0
ntc_rg262_e:
			IF ($ < 32768) && (ntc_rg263_e - ntc_rg263 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg263:
tmp5:			dw 0
ntc_rg263_e:
			IF ($ < 32768) && (ntc_rg264_e - ntc_rg264 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg264:
tmp6:			dw 0
ntc_rg264_e:
			IF ($ < 32768) && (ntc_rg265_e - ntc_rg265 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg265:
tmp7:			dw 0
ntc_rg265_e:
			IF ($ < 32768) && (ntc_rg266_e - ntc_rg266 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg266:
			db 72			; capacity
stmp0:			ds 73
ntc_rg266_e:
			IF ($ < 32768) && (ntc_rg267_e - ntc_rg267 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg267:
			db 72			; capacity
stmp1:			ds 73
ntc_rg267_e:
			IF ($ < 32768) && (ntc_rg268_e - ntc_rg268 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg268:
ltmp0:			dw 0, 0
ntc_rg268_e:
			IF ($ < 32768) && (ntc_rg269_e - ntc_rg269 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg269:
ltmp1:			dw 0, 0
ntc_rg269_e:
			IF ($ < 32768) && (ntc_rg270_e - ntc_rg270 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg270:
ltmp2:			dw 0, 0

; numbers passed by address (read only)
ntc_rg270_e:
			IF ($ < 32768) && (ntc_rg271_e - ntc_rg271 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg271:
lit_0:			dw 0
ntc_rg271_e:
			IF ($ < 32768) && (ntc_rg272_e - ntc_rg272 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg272:
lit_1:			dw 1
ntc_rg272_e:
			IF ($ < 32768) && (ntc_rg273_e - ntc_rg273 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg273:
lit_85:			dw 85
ntc_rg273_e:
			IF ($ < 32768) && (ntc_rg274_e - ntc_rg274 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg274:
vp_arr_st:			dw arr_st
ntc_rg274_e:
			IF ($ < 32768) && (ntc_rg275_e - ntc_rg275 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg275:
vp_arr_sg:			dw arr_sg
ntc_rg275_e:
			IF ($ < 32768) && (ntc_rg276_e - ntc_rg276 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg276:
vp_var_ns:			dw var_ns
ntc_rg276_e:
			IF ($ < 32768) && (ntc_rg277_e - ntc_rg277 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg277:
vp_var_front:			dw var_front
ntc_rg277_e:
			IF ($ < 32768) && (ntc_rg278_e - ntc_rg278 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg278:
vp_var_dp:			dw var_dp
ntc_rg278_e:
			IF ($ < 32768) && (ntc_rg279_e - ntc_rg279 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg279:
vp_arr_rb:			dw arr_rb
ntc_rg279_e:
			IF ($ < 32768) && (ntc_rg280_e - ntc_rg280 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg280:
lit_99:			dw 99
ntc_rg280_e:
			IF ($ < 32768) && (ntc_rg281_e - ntc_rg281 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg281:
lit_255:			dw 255
ntc_rg281_e:
			IF ($ < 32768) && (ntc_rg282_e - ntc_rg282 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg282:
vp_var_dn:			dw var_dn
ntc_rg282_e:
			IF ($ < 32768) && (ntc_rg283_e - ntc_rg283 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg283:
lit_100:			dw 100
ntc_rg283_e:
			IF ($ < 32768) && (ntc_rg284_e - ntc_rg284 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg284:
lit_103:			dw 103
ntc_rg284_e:
			IF ($ < 32768) && (ntc_rg285_e - ntc_rg285 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg285:
lit_m4864:			dw -4864
ntc_rg285_e:
			IF ($ < 32768) && (ntc_rg286_e - ntc_rg286 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg286:
lit_256:			dw 256
ntc_rg286_e:
			IF ($ < 32768) && (ntc_rg287_e - ntc_rg287 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg287:
lit_102:			dw 102
ntc_rg287_e:
			IF ($ < 32768) && (ntc_rg288_e - ntc_rg288 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg288:
lit_128:			dw 128
ntc_rg288_e:
			IF ($ < 32768) && (ntc_rg289_e - ntc_rg289 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg289:
lit_m1:			dw -1
ntc_rg289_e:
			IF ($ < 32768) && (ntc_rg290_e - ntc_rg290 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg290:
lit_m2431:			dw -2431
ntc_rg290_e:
			IF ($ < 32768) && (ntc_rg291_e - ntc_rg291 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg291:
vp_arr_kd:			dw arr_kd
ntc_rg291_e:
			IF ($ < 32768) && (ntc_rg292_e - ntc_rg292 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg292:
lit_32:			dw 32
ntc_rg292_e:
			IF ($ < 32768) && (ntc_rg293_e - ntc_rg293 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg293:
vp_var_en:			dw var_en
ntc_rg293_e:
			IF ($ < 32768) && (ntc_rg294_e - ntc_rg294 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg294:
vp_arr_dv:			dw arr_dv
ntc_rg294_e:
			IF ($ < 32768) && (ntc_rg295_e - ntc_rg295 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg295:
lit_m2560:			dw -2560
ntc_rg295_e:
			IF ($ < 32768) && (ntc_rg296_e - ntc_rg296 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg296:
lit_2:			dw 2
ntc_rg296_e:
			IF ($ < 32768) && (ntc_rg297_e - ntc_rg297 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg297:
lit_34:			dw 34
ntc_rg297_e:
			IF ($ < 32768) && (ntc_rg298_e - ntc_rg298 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg298:
lit_110:			dw 110
ntc_rg298_e:
			IF ($ < 32768) && (ntc_rg299_e - ntc_rg299 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg299:
lit_116:			dw 116
ntc_rg299_e:
			IF ($ < 32768) && (ntc_rg300_e - ntc_rg300 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg300:
llit_65536:			dw 0, 1
ntc_rg300_e:
			IF ($ < 32768) && (ntc_rg301_e - ntc_rg301 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg301:
lit_3:			dw 3
ntc_rg301_e:
			IF ($ < 32768) && (ntc_rg302_e - ntc_rg302 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg302:
lit_m4352:			dw -4352
ntc_rg302_e:
			IF ($ < 32768) && (ntc_rg303_e - ntc_rg303 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg303:
lit_4096:			dw 4096
ntc_rg303_e:
			IF ($ < 32768) && (ntc_rg304_e - ntc_rg304 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg304:
lit_m3328:			dw -3328
ntc_rg304_e:
			IF ($ < 32768) && (ntc_rg305_e - ntc_rg305 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg305:
lit_768:			dw 768
ntc_rg305_e:
			IF ($ < 32768) && (ntc_rg306_e - ntc_rg306 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg306:
lit_5:			dw 5
ntc_rg306_e:
			IF ($ < 32768) && (ntc_rg307_e - ntc_rg307 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg307:
lit_6:			dw 6
ntc_rg307_e:
			IF ($ < 32768) && (ntc_rg308_e - ntc_rg308 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg308:
lit_m48:			dw -48
ntc_rg308_e:
			IF ($ < 32768) && (ntc_rg309_e - ntc_rg309 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg309:
lit_m2432:			dw -2432
ntc_rg309_e:
			IF ($ < 32768) && (ntc_rg310_e - ntc_rg310 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg310:
lit_m2427:			dw -2427
ntc_rg310_e:
			IF ($ < 32768) && (ntc_rg311_e - ntc_rg311 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg311:
lit_m3332:			dw -3332
ntc_rg311_e:
			IF ($ < 32768) && (ntc_rg312_e - ntc_rg312 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg312:
lit_4:			dw 4
ntc_rg312_e:
			IF ($ < 32768) && (ntc_rg313_e - ntc_rg313 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg313:
lit_m3330:			dw -3330
ntc_rg313_e:
			IF ($ < 32768) && (ntc_rg314_e - ntc_rg314 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg314:
lit_m2:			dw -2
ntc_rg314_e:
			IF ($ < 32768) && (ntc_rg315_e - ntc_rg315 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg315:
lit_7:			dw 7

ntc_rg315_e:
			IF ($ < 32768) && (ntc_rg316_e - ntc_rg316 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg316:
; ============================================================
; Strings
; ============================================================

ntc_rg316_e:
			IF ($ < 32768) && (ntc_rg317_e - ntc_rg317 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg317:
str0:			db "CyborgOS needs 320K", 0
ntc_rg317_e:
			IF ($ < 32768) && (ntc_rg318_e - ntc_rg318 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg318:
str1:			db "Press a key", 0
ntc_rg318_e:
			IF ($ < 32768) && (ntc_rg319_e - ntc_rg319 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg319:
str2:			db 0
ntc_rg319_e:
			IF ($ < 32768) && (ntc_rg320_e - ntc_rg320 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg320:
str3:			db " KEYREP ", 0
ntc_rg320_e:
			IF ($ < 32768) && (ntc_rg321_e - ntc_rg321 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg321:
str4:			db "KERNEL.CYB", 0
ntc_rg321_e:
			IF ($ < 32768) && (ntc_rg322_e - ntc_rg322 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg322:
str5:			db "CyborgOS: no KERNEL.CYB", 0
ntc_rg322_e:
			IF ($ < 32768) && (ntc_rg323_e - ntc_rg323 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg323:
str6:			db "CyborgOS: the kernel ended", 0
ntc_rg323_e:
			IF ($ < 32768) && (ntc_rg324_e - ntc_rg324 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg324:
str7:			db "CyborgOS ended, ", 0
ntc_rg324_e:
			IF ($ < 32768) && (ntc_rg325_e - ntc_rg325 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg325:
str8:			db " programs ran", 0

ntc_rg325_e:
			IF ($ < 32768) && (ntc_rg326_e - ntc_rg326 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg326:
; ============================================================
; Keyword library (used)
; ============================================================

ntc_rg326_e:
			IF ($ < 32768) && (ntc_rg327_e - ntc_rg327 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg327:
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

ntc_rg327_e:
			IF ($ < 32768) && (ntc_rg328_e - ntc_rg328 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg328:
;## ntc_d_gnlo @data
ntc_gnlo:		db 0			; ntc_getn: low byte

ntc_rg328_e:
			IF ($ < 32768) && (ntc_rg329_e - ntc_rg329 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg329:
;## ntc_d_nmode @data
ntc_nmode:		db 0			; 1 = running in normal mode (waits let interrupts in)

ntc_rg329_e:
			IF ($ < 32768) && (ntc_rg330_e - ntc_rg330 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg330:
;## ntc_d_div @data
ntc_mode:		db 0			; div mode 0=quotient 1=remainder
ntc_sgnq:		db 0			; quotient sign (bit 7)
ntc_sgnr:		db 0			; remainder sign (bit 7)

ntc_rg330_e:
			IF ($ < 32768) && (ntc_rg331_e - ntc_rg331 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg331:
;## ntc_d_lead @data
ntc_lead:		db 0			; printint: digit seen

ntc_rg331_e:
			IF ($ < 32768) && (ntc_rg332_e - ntc_rg332 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg332:
;## ntc_d_sptr @data
ntc_sptr:		dw 0			; printbuf: text pointer

ntc_rg332_e:
			IF ($ < 32768) && (ntc_rg333_e - ntc_rg333 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg333:
;## ntc_d_iptr @data
ntc_iptr:		dw 0			; gets: buffer pointer
ntc_ilink:		dw 0			; gets: where to go when done

ntc_rg333_e:
			IF ($ < 32768) && (ntc_rg334_e - ntc_rg334 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg334:
;## ntc_d_ivar @data
ntc_ivar:		dw 0			; inputint / inkey: dest var

ntc_rg334_e:
			IF ($ < 32768) && (ntc_rg335_e - ntc_rg335 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg335:
;## ntc_d_aptr @data
ntc_aptr:		dw 0			; atoi: text pointer

ntc_rg335_e:
			IF ($ < 32768) && (ntc_rg336_e - ntc_rg336 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg336:
;## ntc_d_hook @data
ntc_hookon:		db 0			; 1 = the Interrupt hook may run (set, and not running now)
ntc_hookset:	db 0			; 1 = an Interrupt hook is set
ntc_hookpend:	db 0			; 1 = an interrupt came, the hook runs at the next safe point
ntc_hook:		dw 0			; the hook Sub's call stub

ntc_rg336_e:
			IF ($ < 32768) && (ntc_rg337_e - ntc_rg337 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg337:
;## ntc_d_hostix @data
ntc_hostix:		dw 0			; host platforms: IX kept over a firmware / BDOS call

ntc_rg337_e:
			IF ($ < 32768) && (ntc_rg338_e - ntc_rg338 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg338:
;## ntc_d_rampt @data
ntc_rampt:		dw #7FC0		; the gate array's RAM setting now (B = port, C = value): the
								; Memory class keeps it, Graphics puts it back after drawing

ntc_rg338_e:
			IF ($ < 32768) && (ntc_rg339_e - ntc_rg339 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg339:
;## ntc_d_numbuf @data
ntc_numbuf:		ds 14			; printint / long print: digits (+ spaces for Option VBPrint)

ntc_rg339_e:
			IF ($ < 32768) && (ntc_rg340_e - ntc_rg340 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg340:
;## ntc_d_inbuf @data
				db 40			; ntc_inbuf's capacity (as every string variable has)
ntc_inbuf:		ds 41			; inputint: typed text

ntc_rg340_e:
			IF ($ < 32768) && (ntc_rg341_e - ntc_rg341 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg341:
;## kw_stop ntc_data ntc_plat_exit @shared
kw_stop:
			ld ix, ntc_stop_back
			jp ntc_plat_exit
ntc_stop_back:
			ld sp, (ntc_csp)
			ei
			ret

ntc_rg341_e:
			IF ($ < 32768) && (ntc_rg342_e - ntc_rg342 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg342:
;## kw_waitkey ntc_data ntc_plat_key
; kw_waitkey - wait for a key (Option PressAnyKeyOnEnd, before kw_stop)
kw_waitkey:
			ld ix, ntc_next
			jp ntc_plat_getkey

ntc_rg342_e:
			IF ($ < 32768) && (ntc_rg343_e - ntc_rg343 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg343:
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

ntc_rg343_e:
			IF ($ < 32768) && (ntc_rg344_e - ntc_rg344 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg344:
;## kw_goto_iffalse (normal mode copy)
;kw_goto_iffalse, <label>  - branch if NZ (false)
kw_goto_iffalse_n:
			pop hl
			jp z, ntc_xn
			ld sp, hl
			jp ntc_xn

ntc_rg344_e:
			IF ($ < 32768) && (ntc_rg345_e - ntc_rg345 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg345:
;## kw_goto_iftrue (normal mode copy)
;kw_goto_iftrue, <label>  - branch if Z (true)
kw_goto_iftrue_n:
			pop hl
			jp nz, ntc_xn
			ld sp, hl
			jp ntc_xn

ntc_rg345_e:
			IF ($ < 32768) && (ntc_rg346_e - ntc_rg346 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg346:
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

ntc_rg346_e:
			IF ($ < 32768) && (ntc_rg347_e - ntc_rg347 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg347:
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

ntc_rg347_e:
			IF ($ < 32768) && (ntc_rg348_e - ntc_rg348 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg348:
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

ntc_rg348_e:
			IF ($ < 32768) && (ntc_rg349_e - ntc_rg349 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg349:
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

ntc_rg349_e:
			IF ($ < 32768) && (ntc_rg350_e - ntc_rg350 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg350:
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

ntc_rg350_e:
			IF ($ < 32768) && (ntc_rg351_e - ntc_rg351 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg351:
;## kw_ltov
;kw_ltov, <literal>, <destvar>
kw_ltov:
			pop de
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg351_e:
			IF ($ < 32768) && (ntc_rg352_e - ntc_rg352 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg352:
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

ntc_rg352_e:
			IF ($ < 32768) && (ntc_rg353_e - ntc_rg353 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg353:
;## kw_ztov
;kw_ztov, <destvar>
kw_ztov:
			xor a
			pop hl
			ld (hl), a
			inc hl
			ld (hl), a
			ret

ntc_rg353_e:
			IF ($ < 32768) && (ntc_rg354_e - ntc_rg354 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg354:
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

ntc_rg354_e:
			IF ($ < 32768) && (ntc_rg355_e - ntc_rg355 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg355:
;## kw_inc
;kw_inc, <var>
kw_inc:
			pop hl
			inc (hl)
			ret nz
			inc hl
			inc (hl)
			ret

ntc_rg355_e:
			IF ($ < 32768) && (ntc_rg356_e - ntc_rg356 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg356:
;## kw_dec
;kw_dec, <var>
kw_dec:
			pop hl
			ld a, (hl)
			dec (hl)
			or a
			ret nz
			inc hl
			dec (hl)
			ret

ntc_rg356_e:
			IF ($ < 32768) && (ntc_rg357_e - ntc_rg357 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg357:
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

ntc_rg357_e:
			IF ($ < 32768) && (ntc_rg358_e - ntc_rg358 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg358:
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

ntc_rg358_e:
			IF ($ < 32768) && (ntc_rg359_e - ntc_rg359 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg359:
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

ntc_rg359_e:
			IF ($ < 32768) && (ntc_rg360_e - ntc_rg360 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg360:
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

ntc_rg360_e:
			IF ($ < 32768) && (ntc_rg361_e - ntc_rg361 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg361:
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

ntc_rg361_e:
			IF ($ < 32768) && (ntc_rg362_e - ntc_rg362 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg362:
;## kw_mulvl ntc_mul
;kw_mulvl, <var>, <literal>, <destvar>
kw_mulvl:
			pop hl
			ld c, (hl)
			inc hl
			ld b, (hl)
			pop de
			jp ntc_mul

ntc_rg362_e:
			IF ($ < 32768) && (ntc_rg363_e - ntc_rg363 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg363:
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

ntc_rg363_e:
			IF ($ < 32768) && (ntc_rg364_e - ntc_rg364 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg364:
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

ntc_rg364_e:
			IF ($ < 32768) && (ntc_rg365_e - ntc_rg365 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg365:
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

ntc_rg365_e:
			IF ($ < 32768) && (ntc_rg366_e - ntc_rg366 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg366:
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

ntc_rg366_e:
			IF ($ < 32768) && (ntc_rg367_e - ntc_rg367 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg367:
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

ntc_rg367_e:
			IF ($ < 32768) && (ntc_rg368_e - ntc_rg368 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg368:
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

ntc_rg368_e:
			IF ($ < 32768) && (ntc_rg369_e - ntc_rg369 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg369:
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

ntc_rg369_e:
			IF ($ < 32768) && (ntc_rg370_e - ntc_rg370 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg370:
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

ntc_rg370_e:
			IF ($ < 32768) && (ntc_rg371_e - ntc_rg371 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg371:
;## kw_scpltvl ntc_cmp
;kw_scpltvl, <var>, <literal>
kw_scpltvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_slt

ntc_rg371_e:
			IF ($ < 32768) && (ntc_rg372_e - ntc_rg372 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg372:
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

ntc_rg372_e:
			IF ($ < 32768) && (ntc_rg373_e - ntc_rg373 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg373:
;## kw_scplevl ntc_cmp
kw_scplevl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sle

ntc_rg373_e:
			IF ($ < 32768) && (ntc_rg374_e - ntc_rg374 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg374:
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

ntc_rg374_e:
			IF ($ < 32768) && (ntc_rg375_e - ntc_rg375 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg375:
;## kw_scpgtvl ntc_cmp
kw_scpgtvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sgt

ntc_rg375_e:
			IF ($ < 32768) && (ntc_rg376_e - ntc_rg376 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg376:
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

ntc_rg376_e:
			IF ($ < 32768) && (ntc_rg377_e - ntc_rg377 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg377:
;## kw_scpgevl ntc_cmp
kw_scpgevl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sge

ntc_rg377_e:
			IF ($ < 32768) && (ntc_rg378_e - ntc_rg378 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg378:
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

ntc_rg378_e:
			IF ($ < 32768) && (ntc_rg379_e - ntc_rg379 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg379:
;## kw_cpeqvl ntc_cmp
kw_cpeqvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_eq

ntc_rg379_e:
			IF ($ < 32768) && (ntc_rg380_e - ntc_rg380 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg380:
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

ntc_rg380_e:
			IF ($ < 32768) && (ntc_rg381_e - ntc_rg381 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg381:
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

ntc_rg381_e:
			IF ($ < 32768) && (ntc_rg382_e - ntc_rg382 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg382:
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

ntc_rg382_e:
			IF ($ < 32768) && (ntc_rg383_e - ntc_rg383 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg383:
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

ntc_rg383_e:
			IF ($ < 32768) && (ntc_rg384_e - ntc_rg384 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg384:
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

ntc_rg384_e:
			IF ($ < 32768) && (ntc_rg385_e - ntc_rg385 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg385:
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

ntc_rg385_e:
			IF ($ < 32768) && (ntc_rg386_e - ntc_rg386 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg386:
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

ntc_rg386_e:
			IF ($ < 32768) && (ntc_rg387_e - ntc_rg387 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg387:
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

ntc_rg387_e:
			IF ($ < 32768) && (ntc_rg388_e - ntc_rg388 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg388:
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

ntc_rg388_e:
			IF ($ < 32768) && (ntc_rg389_e - ntc_rg389 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg389:
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

ntc_rg389_e:
			IF ($ < 32768) && (ntc_rg390_e - ntc_rg390 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg390:
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

ntc_rg390_e:
			IF ($ < 32768) && (ntc_rg391_e - ntc_rg391 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg391:
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

ntc_rg391_e:
			IF ($ < 32768) && (ntc_rg392_e - ntc_rg392 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg392:
;## kw_printstrvar ntc_printbuf
;kw_printstrvar, <straddr>
kw_printstrvar:
			pop hl
			ld (ntc_sptr), hl
			jp ntc_printbuf

ntc_rg392_e:
			IF ($ < 32768) && (ntc_rg393_e - ntc_rg393 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg393:
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

ntc_rg393_e:
			IF ($ < 32768) && (ntc_rg394_e - ntc_rg394 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg394:
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

ntc_rg394_e:
			IF ($ < 32768) && (ntc_rg395_e - ntc_rg395 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg395:
;## kw_printnl0 ntc_data ntc_plat_screen
;kw_printnl0  - new line unless the cursor is at the start of a line
kw_printnl0:
			ld a, (ntc_curx)
			or a
			ret z
			ld ix, ntc_next
			jp ntc_plat_newline

ntc_rg395_e:
			IF ($ < 32768) && (ntc_rg396_e - ntc_rg396 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg396:
;## kw_printnl ntc_data ntc_plat_screen
;kw_printnl
kw_printnl:
			ld ix, ntc_next
			jp ntc_plat_newline

ntc_rg396_e:
			IF ($ < 32768) && (ntc_rg397_e - ntc_rg397 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg397:
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

ntc_rg397_e:
			IF ($ < 32768) && (ntc_rg398_e - ntc_rg398 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg398:
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

ntc_rg398_e:
			IF ($ < 32768) && (ntc_rg399_e - ntc_rg399 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg399:
;## kw_model ntc_data ntc_plat_screen
;kw_model, <literal>  - 0, 1 or 2, clears the screen
kw_model:
			pop hl
			ld a, l
			ld ix, ntc_next
			jp ntc_plat_mode

ntc_rg399_e:
			IF ($ < 32768) && (ntc_rg400_e - ntc_rg400 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg400:
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

ntc_rg400_e:
			IF ($ < 32768) && (ntc_rg401_e - ntc_rg401 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg401:
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

ntc_rg401_e:
			IF ($ < 32768) && (ntc_rg402_e - ntc_rg402 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg402:
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

ntc_rg402_e:
			IF ($ < 32768) && (ntc_rg403_e - ntc_rg403 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg403:
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

ntc_rg403_e:
			IF ($ < 32768) && (ntc_rg404_e - ntc_rg404 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg404:
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

ntc_rg404_e:
			IF ($ < 32768) && (ntc_rg405_e - ntc_rg405 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg405:
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

ntc_rg405_e:
			IF ($ < 32768) && (ntc_rg406_e - ntc_rg406 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg406:
;## kw_strval ntc_atoi
;kw_strval, <src>, <destvar>  - Val(src): decimal or &H hex
kw_strval:
			pop hl
			pop de
			ld (ntc_ivar), de
			jp ntc_atoi_hl

ntc_rg406_e:
			IF ($ < 32768) && (ntc_rg407_e - ntc_rg407 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg407:
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

ntc_rg407_e:
			IF ($ < 32768) && (ntc_rg408_e - ntc_rg408 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg408:
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

ntc_rg408_e:
			IF ($ < 32768) && (ntc_rg409_e - ntc_rg409 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg409:
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

ntc_rg409_e:
			IF ($ < 32768) && (ntc_rg410_e - ntc_rg410 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg410:
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

ntc_rg410_e:
			IF ($ < 32768) && (ntc_rg411_e - ntc_rg411 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg411:
;## ntc_buf2k
; ntc_buf - a buffer shared by the classes that need one: FileSystem's
; CAS IN / OUT OPEN buffer (CPC firmware: 2K) and Memory.Copy's page to page
; copy (that much at a time). NTC_BUFSIZE (Option Buffer): 2048 unless set
ntc_buf:		ds NTC_BUFSIZE

ntc_rg411_e:
			IF ($ < 32768) && (ntc_rg412_e - ntc_rg412 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg412:
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

ntc_rg412_e:
			IF ($ < 32768) && (ntc_rg413_e - ntc_rg413 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg413:
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

ntc_rg413_e:
			IF ($ < 32768) && (ntc_rg414_e - ntc_rg414 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg414:
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

ntc_rg414_e:
			IF ($ < 32768) && (ntc_rg415_e - ntc_rg415 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg415:
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

ntc_rg415_e:
			IF ($ < 32768) && (ntc_rg416_e - ntc_rg416 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg416:
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

ntc_rg416_e:
			IF ($ < 32768) && (ntc_rg417_e - ntc_rg417 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg417:
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

ntc_rg417_e:
			IF ($ < 32768) && (ntc_rg418_e - ntc_rg418 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg418:
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
ntc_bstxt:		db "Not enough memory for the arrays", 0

ntc_rg418_e:
			IF ($ < 32768) && (ntc_rg419_e - ntc_rg419 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg419:
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

ntc_rg419_e:
			IF ($ < 32768) && (ntc_rg420_e - ntc_rg420 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg420:
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

ntc_rg420_e:
			IF ($ < 32768) && (ntc_rg421_e - ntc_rg421 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg421:
;## ntc_msx_data @shared
NTC_MSXIRQ	equ #C000		; the interrupt stub (page 3: what the BIOS can call)
ntc_irqv:		dw 0			; interrupt classes' counting (ntc_isl_tick), 0 = none
ntc_msxhk:		ds 5			; H.TIMI's 5 bytes as they were
ntc_msxiq:		db 0			; 1 = H.TIMI is normal mode's

ntc_rg421_e:
			IF ($ < 32768) && (ntc_rg422_e - ntc_rg422 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg422:
;## ntc_plat_irq ntc_msx_data ntc_plat_data ntc_data @shared
; ------------------------------------------------------------
; ntc_plat_irqon - normal mode's handler on H.TIMI (#FD9F: the BIOS calls it
; at every frame interrupt, its registers saved): an Interrupt hook is marked
; to run at the next safe point, the interrupt classes are counted (C = 1:
; every interrupt is a frame's). The BIOS is in page 0 then (MSX-DOS's #0038
; calls it there), so the handler runs from a copy in page 3 (NTC_MSXIRQ);
; the program's own code below #4000 isn't there while it runs.
; ------------------------------------------------------------
ntc_plat_irqon:
			ld hl, ntc_msx_irq
			ld de, NTC_MSXIRQ
			ld bc, ntc_msx_irqe - ntc_msx_irq
			ldir
			ld hl, ntc_hookon			; its addresses (the hook's flags, the classes' counter)
			ld (NTC_MSXIRQ + ntc_mi_on - ntc_msx_irq + 1), hl
			ld hl, ntc_hookpend
			ld (NTC_MSXIRQ + ntc_mi_pend - ntc_msx_irq + 1), hl
			ld hl, ntc_irqv
			ld (NTC_MSXIRQ + ntc_mi_v - ntc_msx_irq + 1), hl
			ld hl, #FD9F
			ld de, ntc_msxhk
			ld bc, 5
			ldir
			ld a, #C3				; jp NTC_MSXIRQ, ret, ret
			ld (#FD9F), a
			ld hl, NTC_MSXIRQ
			ld (#FDA0), hl
			ld a, #C9
			ld (#FDA2), a
			ld (#FDA3), a
			ld a, 1
			ld (ntc_msxiq), a
			jp (ix)
; the stub (copied to NTC_MSXIRQ): its three addresses patched in by irqon. The
; interrupt classes' counter (ntc_isl_tick) must not be in page 0 either: it is
; the library's, past the program's start - a program bigger than 16K has it
; above #4000 (CyborgOS); a small one keeps its interrupt classes off (none)
ntc_msx_irq:
ntc_mi_on:
			ld a, (0)				; ntc_hookon
			or a
			jr z, ntc_mi_nohook
ntc_mi_pend:
			ld (0), a				; ntc_hookpend
ntc_mi_nohook:
ntc_mi_v:
			ld hl, (0)				; ntc_irqv
			ld a, h
			or l
			ret z
			ld c, 1
			jp (hl)
ntc_msx_irqe:

ntc_rg422_e:
			IF ($ < 32768) && (ntc_rg423_e - ntc_rg423 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg423:
;## ntc_plat_exit ntc_msx_data ntc_plat_data @shared
; ------------------------------------------------------------
; ntc_plat_exit - End: H.TIMI back as it was, then back to MSX-DOS
; ------------------------------------------------------------
ntc_plat_exit:
			di
			ld a, (ntc_msxiq)
			cp 1
			jr nz, ntc_mx_done
			ld hl, ntc_msxhk
			ld de, #FD9F
			ld bc, 5
			ldir
			xor a
			ld (ntc_msxiq), a
ntc_mx_done:
			ei
			jp 0

ntc_rg423_e:
			IF ($ < 32768) && (ntc_rg424_e - ntc_rg424 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg424:
;## ntc_plat_memtop ntc_plat_data
; ntc_plat_memtop - HL = the first byte the Memory class's Small heap must not
; use: the real stack's 512 bytes under #C000. Called with call / ret
ntc_plat_memtop:
			ld hl, #C000 - 512
			ret

ntc_rg424_e:
			IF ($ < 32768) && (ntc_rg425_e - ntc_rg425 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg425:
;## ntc_plat_rmr ntc_plat_data
; ntc_plat_rmr - no CPC gate array: the Memory class's CallBank asks for its ROM / mode
; byte; 0 (CallBank's own switch is the CPC's: not for MSX programs). Keeps BC, DE, HL
ntc_plat_rmr:
			xor a
			ret

; ============================================================
; NTC Platform - CP/M 2.2 / 3 (any Z80 CP/M machine)
; (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
; ============================================================
; A .COM program at #0100. Console through BDOS function 6
; (direct console I/O: no ^C / ^S checks, no echo). The
; program has its own real stack (CP/M's CCP stack is small)
; and ends with a warm boot (jp 0).
;
; BDOS needs a real stack: SP is the thread, so each call goes
; through ntc_bdos, which switches SP to ntc_csp, lets
; interrupts in (many BIOSes scan keys on interrupts), calls
; address 5 and switches back. The thread never sees call/push.
;
; Without Option Terminal the console is a stream: no cursor
; positioning, Cls prints a new line, Locate does nothing.
; Option Terminal VT52 (Amstrad CP/M on the CPC and PCW, many
; others) or ANSI (most emulators and modern terminals) gives Cls
; and Locate with the terminal's codes (NTC_TERM, set by the
; compiler: 0 none, 1 VT52, 2 ANSI). Mode does nothing. 80
; columns are counted for Tab; the terminal does its own wrapping.
; ============================================================
; ============================================================

ntc_rg425_e:
			IF ($ < 32768) && (ntc_rg426_e - ntc_rg426 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg426:
;## ntc_plat_data
ntc_curx:		db 0			; column (0 based) - counted for Tab
ntc_cury:		db 0			; not used (a stream has no rows)
ntc_scols:		db 80			; columns
ntc_bdosa:		db 0			; ntc_bdos: A on return
ntc_smode:		db 2			; screen mode (Graphics on an Amstrad CPC: CP/M's console is mode 2)
ntc_cpmtop:		dw #FFFF		; the heap's top if lower than the BDOS (Graphics on CP/M Plus: GFH_AT)
				ds 256			; the program's real stack
ntc_cpmstack:

ntc_rg426_e:
			IF ($ < 32768) && (ntc_rg427_e - ntc_rg427 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg427:
;## ntc_plat_bdos ntc_plat_data ntc_data @shared
; ------------------------------------------------------------
; ntc_bdos - C = BDOS function, DE = argument. A (also in ntc_bdosa)
; and HL come back. IX is kept. Interrupts are on during the call.
; ------------------------------------------------------------
ntc_bdos:
			ld (ntc_hostix), ix
			ld (ntc_ip), sp
			ld sp, (ntc_csp)
			ei
			call 5
			di
			ld sp, (ntc_ip)
			ld (ntc_bdosa), a
			ld ix, (ntc_hostix)
			jp (ix)

ntc_rg427_e:
			IF ($ < 32768) && (ntc_rg428_e - ntc_rg428 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg428:
;## ntc_plat_screen ntc_plat_bdos ntc_plat_data ntc_data
; ntc_plat_putc - A = character: BDOS 6, count the column
ntc_plat_putc:
			ld e, a
			ld c, 6
			ld (ntc_pclink), ix
			ld ix, ntc_pc_back
			jp ntc_bdos
ntc_pc_back:
			ld ix, (ntc_pclink)
			ld a, (ntc_scols)
			ld b, a
			ld a, (ntc_curx)
			inc a
			cp b
			jr c, ntc_pc_col
			xor a					; the terminal wrapped
ntc_pc_col:
			ld (ntc_curx), a
			jp (ix)

; ntc_plat_newline - CR LF
ntc_plat_newline:
			ld (ntc_pclink), ix
			ld e, 13
			ld c, 6
			ld ix, ntc_nl_lf
			jp ntc_bdos
ntc_nl_lf:
			ld e, 10
			ld c, 6
			ld ix, ntc_nl_done
			jp ntc_bdos
ntc_nl_done:
			xor a
			ld (ntc_curx), a
			ld ix, (ntc_pclink)
			jp (ix)

ntc_pclink:		dw 0

ntc_rg428_e:
			IF ($ < 32768) && (ntc_rg429_e - ntc_rg429 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg429:
;## ntc_plat_mode @unit ntc_plat_screen ntc_plat_bdos ntc_plat_data ntc_data
; ntc_plat_mode - nothing on a terminal
ntc_plat_mode:
			jp (ix)

ntc_rg429_e:
			IF ($ < 32768) && (ntc_rg430_e - ntc_rg430 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg430:
;## ntc_plat_key ntc_plat_bdos ntc_data
; ntc_plat_scankey - A = key or 0 (BDOS 6, E = #FF)
ntc_plat_scankey:
			ld e, #FF
			ld c, 6
			jp ntc_bdos

; ntc_plat_getkey - wait for a key (BDOS 6 until there is one)
ntc_plat_getkey:
			ld (ntc_gklink), ix
ntc_gk_poll:
			ld e, #FF
			ld c, 6
			ld ix, ntc_gk_back
			jp ntc_bdos
ntc_gk_back:
			or a
			jr z, ntc_gk_poll
			ld ix, (ntc_gklink)
			jp (ix)
ntc_gklink:		dw 0


ntc_rg430_e:
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
arr_kw		equ ntc_bss + 420		; 32 bytes
arr_kd		equ ntc_bss + 452		; 224 bytes
arr_rb		equ ntc_bss + 676		; 128 bytes
arr_ent_en		equ ntc_bss + 804		; 12 bytes
ntc_bss_size	equ 816
ntc_free	equ ntc_bss + ntc_bss_size	; the first free byte (heap, Memory tables)
			IF ntc_free <= 32768	; fwdref-ok
ntc_memtab	equ 32768		; the Memory class's tables: above the window (Option Reserve)
			ELSE
ntc_memtab	equ ntc_free
			ENDIF
; Option Reserve: the program and its arrays (ntc_start .. ntc_free) must stay out of these
			ASSERT (ntc_free <= 16384) || (ntc_bss >= 32768), "the program (or its arrays) reaches into Option Reserve #4000-#7FFF (Main.bas line 26)"