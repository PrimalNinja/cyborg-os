; the window data (; @window ... ; @endwindow in #asm): put in the window hole by its guard
			MACRO ntc_windata
; (the hypervisor's page from #5300 - #4000 the disc buffers, #5000 the font: Install copies
; these into each bank from there, FileCall 99 put them there at the start. zxn: the SD card's
; code from #4000 - no disc buffers, no font there)
    IFDEF NTC_MSXDOS		; Hyp.cls 2209
; ---- MSX: the files through MSX-DOS 2's (Nextor's) handle calls (BDOS #43 open, #44 create, #45
; close, #48 read, #49 write, #4A seek, #4D delete, #4E rename, #40 / #41 the search, #1B the free
; space, #19 the current drive). Here in the hypervisor's page (window data from #4000) - called
; with the page in the window, by the hooks in FileCall's code (the names it needs come as g_*
; from that block; this is Info's block, so no {name} here). Every drive letter A-H is a path
; ("A:" ...: the DOS's drives; CD, CV set a folder - "A:GAMES/"), so the hooks take every call
; (the boot archive's code, the Next's, finds nothing). MSX-DOS 2 takes its parameters in any
; page (the window's segment is PUT_P1's: it knows); its calls may turn interrupts on - di after.
; Paths: "/" goes to the DOS as "\".
fn_hyp_info_sd_fi:      db 0                    ; the file being read: its handle + 1 (0: none) [2219]
fn_hyp_info_sd_fo:      db 0                    ; the file being written: its handle + 1 [2220]
fn_hyp_info_sd_hn:      db 0                    ; (spare) [2221]
fn_hyp_info_sd_par:     dw 0                    ; FileCall's parameters: f, fcb, slot, setting, dma, drive, buf (sd_h_init) [2222]
fn_hyp_info_sd_pfin:    dw 0                    ; fin's address, fout's (the slot reading / writing a file) [2223]
fn_hyp_info_sd_pfout:   dw 0		; Hyp.cls 2224
; sd_bufix - IX = buf (FileCall's); sd_fcbhl - HL = fcb
fn_hyp_info_sd_bufix:		; Hyp.cls 2226
            ld hl, (g_fl_bufa)      ; (not sd_par + 12: an open can come before sd_h_init) [2227]
            ld e, (hl)		; Hyp.cls 2228
            inc hl		; Hyp.cls 2229
            ld d, (hl)		; Hyp.cls 2230
            push de		; Hyp.cls 2231
            pop ix		; Hyp.cls 2232
            ret		; Hyp.cls 2233
fn_hyp_info_sd_fcbhl:		; Hyp.cls 2234
            ld hl, (fn_hyp_info_sd_par)		; Hyp.cls 2235
            inc hl		; Hyp.cls 2236
            inc hl		; Hyp.cls 2237
            ld a, (hl)		; Hyp.cls 2238
            inc hl		; Hyp.cls 2239
            ld h, (hl)		; Hyp.cls 2240
            ld l, a		; Hyp.cls 2241
            ret		; Hyp.cls 2242
fn_hyp_info_sd_dirs:    db 0                    ; sd_cache: 1 folders too [2243]
fn_hyp_info_sd_nm:      ds 64                   ; a name: the path and NAME.EXT, ASCIIZ [2244]
fn_hyp_info_sd_nm2:     ds 64                   ; (rename: the new one) [2245]
fn_hyp_info_sd_fib:     ds 64                   ; a file info block (the search's) [2246]
; sd_dos - the DOS's call C (its registers as it wants): A = 0 done (no carry), else its error
; (carry). B, DE, HL back as it gives them; interrupts off again
fn_hyp_info_sd_dos:		; Hyp.cls 2249
            push ix		; Hyp.cls 2250
            push iy		; Hyp.cls 2251
            call 5		; Hyp.cls 2252
            pop iy		; Hyp.cls 2253
            pop ix		; Hyp.cls 2254
            di		; Hyp.cls 2255
            or a		; Hyp.cls 2256
            ret z		; Hyp.cls 2257
            scf		; Hyp.cls 2258
            ret		; Hyp.cls 2259
; sd_hclose - the handle A + 1 (0: none) closed
fn_hyp_info_sd_hclose:		; Hyp.cls 2261
            or a		; Hyp.cls 2262
            ret z		; Hyp.cls 2263
            dec a		; Hyp.cls 2264
            ld b, a		; Hyp.cls 2265
            ld c, #45               ; _CLOSE [2266]
            jr fn_hyp_info_sd_dos		; Hyp.cls 2267
; sd_name - fl_name_s (the length, the characters) to sd_nm, ASCIIZ (the page in the window).
; sd_namehl: HL = such a name, DE = where; sd_nmz: the end
fn_hyp_info_sd_name:		; Hyp.cls 2270
            ld hl, g_fl_name_s		; Hyp.cls 2271
fn_hyp_info_sd_name1:		; Hyp.cls 2272
            ld de, fn_hyp_info_sd_nm		; Hyp.cls 2273
fn_hyp_info_sd_namehl:		; Hyp.cls 2274
            ld b, (hl)		; Hyp.cls 2275
            inc hl		; Hyp.cls 2276
            inc b		; Hyp.cls 2277
            dec b		; Hyp.cls 2278
            jr z, fn_hyp_info_sd_nmz		; Hyp.cls 2279
fn_hyp_info_sd_nmcp:		; Hyp.cls 2280
            ld a, (hl)		; Hyp.cls 2281
            cp '/'		; Hyp.cls 2282
            jr nz, fn_hyp_info_sd_nmcp1		; Hyp.cls 2283
            ld a, #5C               ; ("/" to the DOS as "\") [2284]
fn_hyp_info_sd_nmcp1:		; Hyp.cls 2285
            ld (de), a		; Hyp.cls 2286
            inc hl		; Hyp.cls 2287
            inc de		; Hyp.cls 2288
            djnz fn_hyp_info_sd_nmcp		; Hyp.cls 2289
fn_hyp_info_sd_nmz:		; Hyp.cls 2290
            xor a		; Hyp.cls 2291
            ld (de), a		; Hyp.cls 2292
            ret		; Hyp.cls 2293
; sd_folder - a path (length, characters at HL) to sd_nm as the DOS wants a folder: no "\" at
; the end ("A:GAMES/" -> "A:GAMES"; "A:" as it is: the drive's current folder). DE at its 0
fn_hyp_info_sd_folder:		; Hyp.cls 2296
            call fn_hyp_info_sd_name1		; Hyp.cls 2297
            dec de		; Hyp.cls 2298
            ld a, (de)		; Hyp.cls 2299
            cp #5C		; Hyp.cls 2300
            jr nz, fn_hyp_info_sd_fo_e		; Hyp.cls 2301
            dec de		; Hyp.cls 2302
            ld a, (de)		; Hyp.cls 2303
            inc de		; Hyp.cls 2304
            cp ':'		; Hyp.cls 2305
            jr z, fn_hyp_info_sd_fo_e           ; ("A:\": the top, kept) [2306]
            xor a		; Hyp.cls 2307
            ld (de), a		; Hyp.cls 2308
            ret		; Hyp.cls 2309
fn_hyp_info_sd_fo_e:		; Hyp.cls 2310
            inc de		; Hyp.cls 2311
            ret		; Hyp.cls 2312
; ---- fl_inopen: a path's file opened (carry: done), else the archive's open (none on the MSX)
@sd_h_inopen:		; Hyp.cls 2314
            ld a, (g_fl_sdf)		; Hyp.cls 2315
            or a		; Hyp.cls 2316
            jp z, g_fl_inopen_a		; Hyp.cls 2317
            call fn_hyp_info_sd_name		; Hyp.cls 2318
            ld de, fn_hyp_info_sd_nm		; Hyp.cls 2319
            ld a, 1                 ; no writing [2320]
            ld c, #43               ; _OPEN: B = the handle [2321]
            call fn_hyp_info_sd_dos		; Hyp.cls 2322
            jr c, fn_hyp_info_sd_io_no		; Hyp.cls 2323
            ld a, b		; Hyp.cls 2324
            inc a		; Hyp.cls 2325
            ld (fn_hyp_info_sd_fi), a		; Hyp.cls 2326
            call fn_hyp_info_sd_hdr             ; its AMSDOS header, if it has one, read past [2327]
            jr nz, fn_hyp_info_sd_io_rw		; Hyp.cls 2328
            scf		; Hyp.cls 2329
            ret		; Hyp.cls 2330
fn_hyp_info_sd_io_rw:                           ; (none: the start again - _SEEK to 0) [2331]
            ld a, (fn_hyp_info_sd_fi)		; Hyp.cls 2332
            dec a		; Hyp.cls 2333
            ld b, a		; Hyp.cls 2334
            xor a		; Hyp.cls 2335
            ld de, 0		; Hyp.cls 2336
            ld hl, 0		; Hyp.cls 2337
            ld c, #4A		; Hyp.cls 2338
            call fn_hyp_info_sd_dos		; Hyp.cls 2339
            scf		; Hyp.cls 2340
            ret		; Hyp.cls 2341
fn_hyp_info_sd_io_no:		; Hyp.cls 2342
            or a		; Hyp.cls 2343
            ret		; Hyp.cls 2344
; sd_hdr - the first record of the file just opened read into buf: Z when it is an AMSDOS header
; (the CPC's .CYB, a .BIN), which is then not part of the file - as AMSDOS's CAS IN OPEN leaves it
; out on the CPC, so a program reads "what CP/M sees" and Z: gets the program alone; NZ: a file
; without one - the caller reads from its start again
fn_hyp_info_sd_hdr:		; Hyp.cls 2349
            ld a, 128		; Hyp.cls 2350
            ld (g_fl_n), a		; Hyp.cls 2351
            ld hl, 0		; Hyp.cls 2352
            ld (g_fl_cnt), hl		; Hyp.cls 2353
            ld ix, (g_fl_bufa)      ; the record into sd_hb: the open has no buffer of the [2354]
            ld l, (ix + 0)          ; caller's (the hypervisor's own opens give none) [2355]
            ld h, (ix + 1)		; Hyp.cls 2356
            push hl		; Hyp.cls 2357
            ld hl, fn_hyp_info_sd_hb		; Hyp.cls 2358
            ld (ix + 0), l		; Hyp.cls 2359
            ld (ix + 1), h		; Hyp.cls 2360
            call g_fl_rdrec         ; (either driver: the one just opened) [2361]
            ld ix, (g_fl_bufa)		; Hyp.cls 2362
            pop hl		; Hyp.cls 2363
            ld (ix + 0), l		; Hyp.cls 2364
            ld (ix + 1), h		; Hyp.cls 2365
            jr z, fn_hyp_info_sd_hdr_no		; Hyp.cls 2366
            ld hl, fn_hyp_info_sd_hb + 128		; Hyp.cls 2367
            jp sd_amsh		; Hyp.cls 2368
fn_hyp_info_sd_hdr_no:		; Hyp.cls 2369
            inc a                   ; NZ [2370]
            ret		; Hyp.cls 2371
fn_hyp_info_sd_hb:      ds 128		; Hyp.cls 2372
; sd_h_ahdr - the archive's open: the header read past (the open's state back if there is none)
@sd_h_ahdr:		; Hyp.cls 2374
            ld hl, (g_fl_arec)		; Hyp.cls 2375
            push hl		; Hyp.cls 2376
            ld hl, (g_fl_aleft)		; Hyp.cls 2377
            push hl		; Hyp.cls 2378
            call fn_hyp_info_sd_hdr		; Hyp.cls 2379
            pop hl		; Hyp.cls 2380
            jr z, fn_hyp_info_sd_ah_yes		; Hyp.cls 2381
            ld (g_fl_aleft), hl		; Hyp.cls 2382
            pop hl		; Hyp.cls 2383
            ld (g_fl_arec), hl		; Hyp.cls 2384
            xor a		; Hyp.cls 2385
            ld (g_fl_aoff), a		; Hyp.cls 2386
            ret		; Hyp.cls 2387
fn_hyp_info_sd_ah_yes:		; Hyp.cls 2388
            pop hl		; Hyp.cls 2389
            ret		; Hyp.cls 2390
; ---- fl_rdrec: fl_n bytes (128 at most) into buf: A = how many (Z none), HL past them
@sd_h_rdrec:		; Hyp.cls 2392
            ld a, (fn_hyp_info_sd_fi)		; Hyp.cls 2393
            or a		; Hyp.cls 2394
            jp z, g_fl_rdrec_a		; Hyp.cls 2395
            dec a		; Hyp.cls 2396
            ld b, a		; Hyp.cls 2397
            call fn_hyp_info_sd_bufix		; Hyp.cls 2398
            push ix		; Hyp.cls 2399
            pop de		; Hyp.cls 2400
            push de		; Hyp.cls 2401
            ld a, (g_fl_n)		; Hyp.cls 2402
            ld l, a		; Hyp.cls 2403
            ld h, 0		; Hyp.cls 2404
            ld c, #48               ; _READ: HL = bytes read (the end of the file: an error, none) [2405]
            call fn_hyp_info_sd_dos		; Hyp.cls 2406
            jr nc, fn_hyp_info_sd_rr_ok		; Hyp.cls 2407
            ld hl, 0		; Hyp.cls 2408
fn_hyp_info_sd_rr_ok:		; Hyp.cls 2409
            ex de, hl		; Hyp.cls 2410
            pop hl		; Hyp.cls 2411
            add hl, de		; Hyp.cls 2412
            ld a, e		; Hyp.cls 2413
            or a		; Hyp.cls 2414
            ret		; Hyp.cls 2415
; ---- fl_inclose
@sd_h_inclose:		; Hyp.cls 2417
            ld a, (fn_hyp_info_sd_fi)		; Hyp.cls 2418
            or a		; Hyp.cls 2419
            jp z, g_fl_inclose_a		; Hyp.cls 2420
            call fn_hyp_info_sd_hclose		; Hyp.cls 2421
            xor a		; Hyp.cls 2422
            ld (fn_hyp_info_sd_fi), a		; Hyp.cls 2423
            ld hl, (fn_hyp_info_sd_pfin)		; Hyp.cls 2424
            ld (hl), a		; Hyp.cls 2425
            ret		; Hyp.cls 2426
; ---- 22: make - a new file to write (fout), where the name has a path (else 255: the archive)
@sd_h_make:		; Hyp.cls 2428
            ld hl, (fn_hyp_info_sd_pfout)		; Hyp.cls 2429
            ld a, (hl)		; Hyp.cls 2430
            or a		; Hyp.cls 2431
            jp nz, g_fp_done		; Hyp.cls 2432
            call g_fl_name		; Hyp.cls 2433
            ld a, (g_fl_sdf)		; Hyp.cls 2434
            or a		; Hyp.cls 2435
            jp z, g_fp_done		; Hyp.cls 2436
            call fn_hyp_info_sd_name		; Hyp.cls 2437
            ld de, fn_hyp_info_sd_nm		; Hyp.cls 2438
            xor a                   ; (reading and writing) [2439]
            ld b, a                 ; (no attributes; one there already: made anew) [2440]
            ld c, #44               ; _CREATE: B = the handle [2441]
            call fn_hyp_info_sd_dos		; Hyp.cls 2442
            jp c, g_fp_done		; Hyp.cls 2443
            ld a, b		; Hyp.cls 2444
            inc a		; Hyp.cls 2445
            ld (fn_hyp_info_sd_fo), a		; Hyp.cls 2446
            ld a, (g_fl_slot)		; Hyp.cls 2447
            ld hl, (fn_hyp_info_sd_pfout)		; Hyp.cls 2448
            ld (hl), a		; Hyp.cls 2449
            call fn_hyp_info_sd_fcbhl		; Hyp.cls 2450
            ld (g_fl_outfcb), hl		; Hyp.cls 2451
            ld a, 1		; Hyp.cls 2452
            ld (g_fl_outfcb + 2), a		; Hyp.cls 2453
            ld hl, 0		; Hyp.cls 2454
            ld (g_fl_outrec), hl		; Hyp.cls 2455
            jp g_fl_ok		; Hyp.cls 2456
; ---- 21 / 34: the record in buf written
@sd_h_write:		; Hyp.cls 2458
            ld a, (fn_hyp_info_sd_fo)		; Hyp.cls 2459
            or a		; Hyp.cls 2460
            jp z, g_fp_done		; Hyp.cls 2461
            dec a		; Hyp.cls 2462
            ld b, a		; Hyp.cls 2463
            call fn_hyp_info_sd_bufix		; Hyp.cls 2464
            push ix		; Hyp.cls 2465
            pop de		; Hyp.cls 2466
            ld hl, 128		; Hyp.cls 2467
            ld c, #49               ; _WRITE: HL = bytes written [2468]
            call fn_hyp_info_sd_dos		; Hyp.cls 2469
            jp c, g_fp_done		; Hyp.cls 2470
            ld a, l		; Hyp.cls 2471
            cp 128		; Hyp.cls 2472
            jp nz, g_fp_done        ; (fewer: the disc is full) [2473]
            ld hl, (g_fl_outrec)		; Hyp.cls 2474
            inc hl		; Hyp.cls 2475
            ld (g_fl_outrec), hl		; Hyp.cls 2476
            jp g_fl_ok		; Hyp.cls 2477
; ---- 16: close - the file being written
@sd_h_clout:		; Hyp.cls 2479
            ld a, (fn_hyp_info_sd_fo)		; Hyp.cls 2480
            call fn_hyp_info_sd_hclose		; Hyp.cls 2481
            xor a		; Hyp.cls 2482
            ld (fn_hyp_info_sd_fo), a		; Hyp.cls 2483
            jp g_fl_ok		; Hyp.cls 2484
; ---- 19: delete (a folder too: _DELETE takes an empty one)
@sd_h_del:		; Hyp.cls 2486
            ld a, (g_fl_sdf)		; Hyp.cls 2487
            or a		; Hyp.cls 2488
            jp z, g_fp_done		; Hyp.cls 2489
            call fn_hyp_info_sd_name		; Hyp.cls 2490
            call fn_hyp_info_sd_unread          ; (open to read still, as CP/M leaves it: closed first) [2491]
            xor a		; Hyp.cls 2492
            ld (g_fl_yes), a		; Hyp.cls 2493
            ld de, fn_hyp_info_sd_nm		; Hyp.cls 2494
            ld c, #4D               ; _DELETE [2495]
            call fn_hyp_info_sd_dos		; Hyp.cls 2496
            jp c, g_fp_done		; Hyp.cls 2497
            jp g_fl_ok		; Hyp.cls 2498
; ---- 23: rename - fl_name_s the old name, fl_new_s the new (the DOS wants the new name alone:
; past its last ":" or "\")
@sd_h_ren:		; Hyp.cls 2501
            ld a, (g_fl_sdf)		; Hyp.cls 2502
            or a		; Hyp.cls 2503
            jp z, g_fp_done		; Hyp.cls 2504
            call fn_hyp_info_sd_name		; Hyp.cls 2505
            call fn_hyp_info_sd_unread		; Hyp.cls 2506
            ld hl, g_fl_new_s		; Hyp.cls 2507
            ld de, fn_hyp_info_sd_nm2		; Hyp.cls 2508
            call fn_hyp_info_sd_namehl		; Hyp.cls 2509
            ld hl, fn_hyp_info_sd_nm2		; Hyp.cls 2510
            ld de, fn_hyp_info_sd_nm2		; Hyp.cls 2511
fn_hyp_info_sd_rn_lp:		; Hyp.cls 2512
            ld a, (hl)		; Hyp.cls 2513
            or a		; Hyp.cls 2514
            jr z, fn_hyp_info_sd_rn_go		; Hyp.cls 2515
            inc hl		; Hyp.cls 2516
            cp ':'		; Hyp.cls 2517
            jr z, fn_hyp_info_sd_rn_cut		; Hyp.cls 2518
            cp #5C		; Hyp.cls 2519
            jr nz, fn_hyp_info_sd_rn_lp		; Hyp.cls 2520
fn_hyp_info_sd_rn_cut:		; Hyp.cls 2521
            ld e, l		; Hyp.cls 2522
            ld d, h		; Hyp.cls 2523
            jr fn_hyp_info_sd_rn_lp		; Hyp.cls 2524
fn_hyp_info_sd_rn_go:		; Hyp.cls 2525
            ex de, hl               ; HL = the new name alone [2526]
            ld de, fn_hyp_info_sd_nm		; Hyp.cls 2527
            ld c, #4E               ; _RENAME [2528]
            call fn_hyp_info_sd_dos		; Hyp.cls 2529
            jp c, g_fp_done		; Hyp.cls 2530
            jp g_fl_ok		; Hyp.cls 2531
; ---- 17: the folder's files into the search's cache (#6000): the path's (the SD card), else
; the archive's. DE: past the path at fl_name_s + 1
@sd_h_srch1:		; Hyp.cls 2534
            ld a, (g_fl_sdf)		; Hyp.cls 2535
            or a		; Hyp.cls 2536
            jr nz, fn_hyp_info_sd_s1_sd		; Hyp.cls 2537
            call g_fl_arc_dir		; Hyp.cls 2538
            jp g_fl_srch		; Hyp.cls 2539
fn_hyp_info_sd_s1_sd:		; Hyp.cls 2540
            ld hl, -(g_fl_name_s + 1)		; Hyp.cls 2541
            add hl, de		; Hyp.cls 2542
            ld a, l		; Hyp.cls 2543
            ld (g_fl_name_s), a		; Hyp.cls 2544
            ld hl, g_fl_name_s		; Hyp.cls 2545
            xor a		; Hyp.cls 2546
            call fn_hyp_info_sd_cache		; Hyp.cls 2547
            jp g_fl_srch		; Hyp.cls 2548
; sd_cache - the folder whose path is at HL (length, characters) into the cache: A = 1 folders
; too (DIR), 0 files only (CP/M's search). An entry (64 bytes): 1, the name (8 + 3), kind (1 a
; folder), the attributes, the length as a word (#FFFF: 64K or more), the size (4), time, date
; (MS-DOS's words). fl_cn how many (FL_CMAX at most). A = 0 done, else the DOS's error
fn_hyp_info_sd_cache:		; Hyp.cls 2553
            ld (fn_hyp_info_sd_dirs), a		; Hyp.cls 2554
            call fn_hyp_info_sd_folder          ; (DE at its 0) [2555]
            dec de		; Hyp.cls 2556
            ld a, (de)		; Hyp.cls 2557
            inc de		; Hyp.cls 2558
            cp ':'		; Hyp.cls 2559
            jr z, fn_hyp_info_sd_ca_pat		; Hyp.cls 2560
            cp #5C		; Hyp.cls 2561
            jr z, fn_hyp_info_sd_ca_pat		; Hyp.cls 2562
            ld a, #5C		; Hyp.cls 2563
            ld (de), a		; Hyp.cls 2564
            inc de		; Hyp.cls 2565
fn_hyp_info_sd_ca_pat:		; Hyp.cls 2566
            ld hl, fn_hyp_info_sd_all		; Hyp.cls 2567
            ld bc, 4		; Hyp.cls 2568
            ldir                    ; "*.*", 0 [2569]
            xor a		; Hyp.cls 2570
            ld (g_fl_cn), a		; Hyp.cls 2571
            ld hl, #6000		; Hyp.cls 2572
            ld (g_fl_at), hl		; Hyp.cls 2573
            ld de, fn_hyp_info_sd_nm		; Hyp.cls 2574
            ld a, (fn_hyp_info_sd_dirs)		; Hyp.cls 2575
            or a		; Hyp.cls 2576
            ld b, 0		; Hyp.cls 2577
            jr z, fn_hyp_info_sd_ca_b		; Hyp.cls 2578
            ld b, #10               ; (folders too) [2579]
fn_hyp_info_sd_ca_b:		; Hyp.cls 2580
            ld ix, fn_hyp_info_sd_fib		; Hyp.cls 2581
            ld c, #40               ; _FFIRST [2582]
            call fn_hyp_info_sd_dos		; Hyp.cls 2583
            jr nc, fn_hyp_info_sd_ca_one		; Hyp.cls 2584
            cp #D7                  ; .NOFIL: an empty folder [2585]
            ret nz		; Hyp.cls 2586
            xor a		; Hyp.cls 2587
            ret		; Hyp.cls 2588
fn_hyp_info_sd_ca_lp:		; Hyp.cls 2589
            ld ix, fn_hyp_info_sd_fib		; Hyp.cls 2590
            ld c, #41               ; _FNEXT [2591]
            call fn_hyp_info_sd_dos		; Hyp.cls 2592
            jr c, fn_hyp_info_sd_ca_end		; Hyp.cls 2593
fn_hyp_info_sd_ca_one:		; Hyp.cls 2594
            ld a, (fn_hyp_info_sd_fib + 1)		; Hyp.cls 2595
            cp '.'		; Hyp.cls 2596
            jr z, fn_hyp_info_sd_ca_lp          ; (".", "..": not entries) [2597]
            ld a, (g_fl_cn)		; Hyp.cls 2598
            cp g_FL_CMAX		; Hyp.cls 2599
            jr nc, fn_hyp_info_sd_ca_end		; Hyp.cls 2600
            ld hl, (g_fl_at)		; Hyp.cls 2601
            ld (hl), 1		; Hyp.cls 2602
            inc hl		; Hyp.cls 2603
            ex de, hl		; Hyp.cls 2604
            ld hl, fn_hyp_info_sd_fib + 1		; Hyp.cls 2605
            call fn_hyp_info_sd_n11             ; the name, DE on past it [2606]
            ld a, (fn_hyp_info_sd_fib + 14)		; Hyp.cls 2607
            bit 4, a		; Hyp.cls 2608
            ld a, 0		; Hyp.cls 2609
            jr z, fn_hyp_info_sd_ca_k		; Hyp.cls 2610
            inc a		; Hyp.cls 2611
fn_hyp_info_sd_ca_k:		; Hyp.cls 2612
            ld (de), a              ; kind [2613]
            inc de		; Hyp.cls 2614
            ld a, (fn_hyp_info_sd_fib + 14)		; Hyp.cls 2615
            ld (de), a              ; the attributes [2616]
            inc de		; Hyp.cls 2617
            ld hl, (fn_hyp_info_sd_fib + 21)    ; the size's low word (#FFFF when more) [2618]
            ld a, (fn_hyp_info_sd_fib + 23)		; Hyp.cls 2619
            ld c, a		; Hyp.cls 2620
            ld a, (fn_hyp_info_sd_fib + 24)		; Hyp.cls 2621
            or c		; Hyp.cls 2622
            jr z, fn_hyp_info_sd_ca_sz		; Hyp.cls 2623
            ld hl, #FFFF		; Hyp.cls 2624
fn_hyp_info_sd_ca_sz:		; Hyp.cls 2625
            ex de, hl		; Hyp.cls 2626
            ld (hl), e		; Hyp.cls 2627
            inc hl		; Hyp.cls 2628
            ld (hl), d		; Hyp.cls 2629
            inc hl		; Hyp.cls 2630
            ex de, hl		; Hyp.cls 2631
            ld hl, fn_hyp_info_sd_fib + 21		; Hyp.cls 2632
            ld bc, 4		; Hyp.cls 2633
            ldir                    ; the size [2634]
            ld hl, fn_hyp_info_sd_fib + 15		; Hyp.cls 2635
            ld bc, 4		; Hyp.cls 2636
            ldir                    ; time, date [2637]
            ld hl, (g_fl_at)		; Hyp.cls 2638
            ld bc, 64		; Hyp.cls 2639
            add hl, bc		; Hyp.cls 2640
            ld (g_fl_at), hl		; Hyp.cls 2641
            ld hl, g_fl_cn		; Hyp.cls 2642
            inc (hl)		; Hyp.cls 2643
            jp fn_hyp_info_sd_ca_lp		; Hyp.cls 2644
fn_hyp_info_sd_ca_end:		; Hyp.cls 2645
            xor a		; Hyp.cls 2646
            ret		; Hyp.cls 2647
fn_hyp_info_sd_all:     db "*.*", 0		; Hyp.cls 2648
; sd_unread - the file fl_name_s names closed if it is the one being read (fl_inname): CP/M
; needs no close after reading, so a program deletes or renames it still open - esxDOS says
; access denied to that
fn_hyp_info_sd_unread:		; Hyp.cls 2652
            ld a, (fn_hyp_info_sd_fi)		; Hyp.cls 2653
            or a		; Hyp.cls 2654
            ret z		; Hyp.cls 2655
            ld hl, g_fl_name_s		; Hyp.cls 2656
            ld de, g_fl_inname		; Hyp.cls 2657
            ld a, (de)		; Hyp.cls 2658
            cp (hl)		; Hyp.cls 2659
            ret nz		; Hyp.cls 2660
            ld b, a		; Hyp.cls 2661
            inc b		; Hyp.cls 2662
fn_hyp_info_sd_ur_cmp:		; Hyp.cls 2663
            ld a, (de)		; Hyp.cls 2664
            cp (hl)		; Hyp.cls 2665
            ret nz		; Hyp.cls 2666
            inc hl		; Hyp.cls 2667
            inc de		; Hyp.cls 2668
            djnz fn_hyp_info_sd_ur_cmp		; Hyp.cls 2669
            jp sd_h_inclose		; Hyp.cls 2670
; sd_amsh - A = the bytes fl_rdrec read (not 0), HL past them: Z when that record is an AMSDOS
; header (a file's first: fl_cnt = 0, 128 read, the checksum at 67 the sum of bytes 0-66, not 0); else NZ
; with A as it was. BC, DE, HL used
@sd_amsh:		; Hyp.cls 2674
            cp 128		; Hyp.cls 2675
            jr nz, fn_hyp_info_sd_am_no		; Hyp.cls 2676
            push hl		; Hyp.cls 2677
            ld hl, g_fl_cnt		; Hyp.cls 2678
            ld a, (hl)		; Hyp.cls 2679
            inc hl		; Hyp.cls 2680
            or (hl)		; Hyp.cls 2681
            pop hl		; Hyp.cls 2682
            jr nz, fn_hyp_info_sd_am_no         ; (not the first record) [2683]
            ld de, -128		; Hyp.cls 2684
            add hl, de              ; the record [2685]
            ld bc, 67		; Hyp.cls 2686
            ld de, 0		; Hyp.cls 2687
fn_hyp_info_sd_am_lp:		; Hyp.cls 2688
            ld a, (hl)		; Hyp.cls 2689
            add a, e		; Hyp.cls 2690
            ld e, a		; Hyp.cls 2691
            jr nc, fn_hyp_info_sd_am_c		; Hyp.cls 2692
            inc d		; Hyp.cls 2693
fn_hyp_info_sd_am_c:		; Hyp.cls 2694
            inc hl		; Hyp.cls 2695
            dec c		; Hyp.cls 2696
            jr nz, fn_hyp_info_sd_am_lp		; Hyp.cls 2697
            ld a, d		; Hyp.cls 2698
            or e		; Hyp.cls 2699
            jr z, fn_hyp_info_sd_am_no          ; (0: no header) [2700]
            ld a, (hl)		; Hyp.cls 2701
            cp e		; Hyp.cls 2702
            jr nz, fn_hyp_info_sd_am_no		; Hyp.cls 2703
            inc hl		; Hyp.cls 2704
            ld a, (hl)		; Hyp.cls 2705
            cp d		; Hyp.cls 2706
            jr nz, fn_hyp_info_sd_am_no		; Hyp.cls 2707
            xor a                   ; Z: a header [2708]
            ret		; Hyp.cls 2709
fn_hyp_info_sd_am_no:		; Hyp.cls 2710
            ld a, 1		; Hyp.cls 2711
            or a                    ; NZ [2712]
            ret		; Hyp.cls 2713
; sd_zcopy - the string at HL (to its 0) to DE
fn_hyp_info_sd_zcopy:		; Hyp.cls 2715
            ld a, (hl)		; Hyp.cls 2716
            ld (de), a		; Hyp.cls 2717
            inc hl		; Hyp.cls 2718
            inc de		; Hyp.cls 2719
            or a		; Hyp.cls 2720
            jr nz, fn_hyp_info_sd_zcopy		; Hyp.cls 2721
            ret		; Hyp.cls 2722
; sd_zend - HL past the 0 ending the string at HL
fn_hyp_info_sd_zend:		; Hyp.cls 2724
            ld a, (hl)		; Hyp.cls 2725
            inc hl		; Hyp.cls 2726
            or a		; Hyp.cls 2727
            jr nz, fn_hyp_info_sd_zend		; Hyp.cls 2728
            ret		; Hyp.cls 2729
; sd_n11 - the name at HL (NAME.EXT, ASCIIZ) as 8 + 3 at DE (spaces), DE on past it
fn_hyp_info_sd_n11:		; Hyp.cls 2731
            push de		; Hyp.cls 2732
            ld b, 11		; Hyp.cls 2733
            ld a, ' '		; Hyp.cls 2734
fn_hyp_info_sd_n1_sp:		; Hyp.cls 2735
            ld (de), a		; Hyp.cls 2736
            inc de		; Hyp.cls 2737
            djnz fn_hyp_info_sd_n1_sp		; Hyp.cls 2738
            pop de		; Hyp.cls 2739
            push de		; Hyp.cls 2740
            ld b, 8		; Hyp.cls 2741
fn_hyp_info_sd_n1_nm:		; Hyp.cls 2742
            ld a, (hl)		; Hyp.cls 2743
            or a		; Hyp.cls 2744
            jr z, fn_hyp_info_sd_n1_end		; Hyp.cls 2745
            cp '.'		; Hyp.cls 2746
            jr z, fn_hyp_info_sd_n1_dot		; Hyp.cls 2747
            ld (de), a		; Hyp.cls 2748
            inc hl		; Hyp.cls 2749
            inc de		; Hyp.cls 2750
            djnz fn_hyp_info_sd_n1_nm		; Hyp.cls 2751
fn_hyp_info_sd_n1_sk:                           ; (past 8: on to the dot) [2752]
            ld a, (hl)		; Hyp.cls 2753
            or a		; Hyp.cls 2754
            jr z, fn_hyp_info_sd_n1_end		; Hyp.cls 2755
            inc hl		; Hyp.cls 2756
            cp '.'		; Hyp.cls 2757
            jr nz, fn_hyp_info_sd_n1_sk		; Hyp.cls 2758
            dec hl		; Hyp.cls 2759
fn_hyp_info_sd_n1_dot:		; Hyp.cls 2760
            inc hl                  ; past the dot [2761]
            pop de		; Hyp.cls 2762
            push de		; Hyp.cls 2763
            ex de, hl		; Hyp.cls 2764
            ld bc, 8		; Hyp.cls 2765
            add hl, bc		; Hyp.cls 2766
            ex de, hl		; Hyp.cls 2767
            ld b, 3		; Hyp.cls 2768
fn_hyp_info_sd_n1_ex:		; Hyp.cls 2769
            ld a, (hl)		; Hyp.cls 2770
            or a		; Hyp.cls 2771
            jr z, fn_hyp_info_sd_n1_end		; Hyp.cls 2772
            ld (de), a		; Hyp.cls 2773
            inc hl		; Hyp.cls 2774
            inc de		; Hyp.cls 2775
            djnz fn_hyp_info_sd_n1_ex		; Hyp.cls 2776
fn_hyp_info_sd_n1_end:		; Hyp.cls 2777
            pop de		; Hyp.cls 2778
            ld hl, 11		; Hyp.cls 2779
            add hl, de		; Hyp.cls 2780
            ex de, hl		; Hyp.cls 2781
            ret		; Hyp.cls 2782
; ---- BDOS 30 (fl_unicall): the block in FL_UB, its op 0-8 at FL_UB
;   0 here: 0;  1 the letter's path (fl_uc_get);  2 the letter's path set (a folder of the SD card:
;   F_OPENDIR tries it);  3 the devices: the SD card's drive letter;  4 a device: folders, its free K
;   (F_GETFREE);  5 the folder's entry Word(2) (the cache, filled at entry 0);  6 a folder made
;   (F_MKDIR);  7 no header (255);  8 the next delete may take a folder
@sd_h_uc:		; Hyp.cls 2788
            ld a, (g_FL_UB)		; Hyp.cls 2789
            or a		; Hyp.cls 2790
            jp z, g_fl_ok		; Hyp.cls 2791
            dec a		; Hyp.cls 2792
            jp z, g_fl_uc_get		; Hyp.cls 2793
            dec a		; Hyp.cls 2794
            jp z, fn_hyp_info_sd_uc_set		; Hyp.cls 2795
            dec a		; Hyp.cls 2796
            jr z, fn_hyp_info_sd_uc_dev		; Hyp.cls 2797
            dec a		; Hyp.cls 2798
            jr z, fn_hyp_info_sd_uc_inf		; Hyp.cls 2799
            dec a		; Hyp.cls 2800
            jp z, fn_hyp_info_sd_uc_dir		; Hyp.cls 2801
            dec a		; Hyp.cls 2802
            jr z, fn_hyp_info_sd_uc_md		; Hyp.cls 2803
            dec a		; Hyp.cls 2804
            jp z, g_fp_done		; Hyp.cls 2805
            ld a, 1		; Hyp.cls 2806
            ld (g_fl_yes), a		; Hyp.cls 2807
            jp g_fl_ok		; Hyp.cls 2808
fn_hyp_info_sd_uc_dev:		; Hyp.cls 2809
            ld a, (fn_hyp_info_sd_drv)		; Hyp.cls 2810
            or #80		; Hyp.cls 2811
            ld (g_FL_UB + 2), a		; Hyp.cls 2812
            ld a, 255		; Hyp.cls 2813
            ld (g_FL_UB + 3), a		; Hyp.cls 2814
            xor a		; Hyp.cls 2815
            ld b, 66		; Hyp.cls 2816
            jp g_fl_uc_back		; Hyp.cls 2817
fn_hyp_info_sd_uc_inf:		; Hyp.cls 2818
            ld a, 3                 ; there (bit 0), folders (bit 1) [2819]
            ld (g_FL_UB + 8), a		; Hyp.cls 2820
            ld e, 0                 ; _ALLOC (the current drive): HL free clusters, A sectors a [2821]
            ld c, #1B               ; cluster: BCDE = HL * A 512 byte sectors [2822]
            call 5		; Hyp.cls 2823
            di		; Hyp.cls 2824
            ld c, a		; Hyp.cls 2825
            ex de, hl		; Hyp.cls 2826
            ld hl, 0		; Hyp.cls 2827
            ld b, 0		; Hyp.cls 2828
fn_hyp_info_sd_ui_mul:		; Hyp.cls 2829
            ld a, c		; Hyp.cls 2830
            or a		; Hyp.cls 2831
            jr z, fn_hyp_info_sd_ui_md		; Hyp.cls 2832
            add hl, de		; Hyp.cls 2833
            jr nc, fn_hyp_info_sd_ui_nc		; Hyp.cls 2834
            inc b		; Hyp.cls 2835
fn_hyp_info_sd_ui_nc:		; Hyp.cls 2836
            dec c		; Hyp.cls 2837
            jr fn_hyp_info_sd_ui_mul		; Hyp.cls 2838
fn_hyp_info_sd_ui_md:		; Hyp.cls 2839
            ld c, b		; Hyp.cls 2840
            ld b, 0		; Hyp.cls 2841
            ex de, hl               ; BCDE [2842]
            srl b                   ; K: halved [2843]
            rr c		; Hyp.cls 2844
            rr d		; Hyp.cls 2845
            rr e		; Hyp.cls 2846
            ld hl, g_FL_UB + 10		; Hyp.cls 2847
            ld (hl), e		; Hyp.cls 2848
            inc hl		; Hyp.cls 2849
            ld (hl), d		; Hyp.cls 2850
            inc hl		; Hyp.cls 2851
            ld (hl), c		; Hyp.cls 2852
            inc hl		; Hyp.cls 2853
            ld (hl), b		; Hyp.cls 2854
            inc hl		; Hyp.cls 2855
            ld b, 4		; Hyp.cls 2856
fn_hyp_info_sd_ui_z:		; Hyp.cls 2857
            ld (hl), 0              ; (all K: not known) [2858]
            inc hl		; Hyp.cls 2859
            djnz fn_hyp_info_sd_ui_z		; Hyp.cls 2860
            ex de, hl		; Hyp.cls 2861
            ld hl, fn_hyp_info_sd_desc		; Hyp.cls 2862
            ld bc, 8		; Hyp.cls 2863
            ldir		; Hyp.cls 2864
            xor a		; Hyp.cls 2865
            ld b, 72		; Hyp.cls 2866
            jp g_fl_uc_back		; Hyp.cls 2867
fn_hyp_info_sd_desc:    db "MSX-DO", "S" + #80, 255		; Hyp.cls 2868
fn_hyp_info_sd_uc_md:		; Hyp.cls 2869
            ld hl, g_FL_UB + 2		; Hyp.cls 2870
            call fn_hyp_info_sd_folder		; Hyp.cls 2871
            ld de, fn_hyp_info_sd_nm		; Hyp.cls 2872
            xor a		; Hyp.cls 2873
            ld b, #10               ; _CREATE with the folder's attribute: a folder made [2874]
            ld c, #44		; Hyp.cls 2875
            call fn_hyp_info_sd_dos		; Hyp.cls 2876
            jp nc, g_fl_ok		; Hyp.cls 2877
            ld (g_fl_res), a		; Hyp.cls 2878
            jp g_fp_done		; Hyp.cls 2879
; 2: the letter's path from Byte(2) (length, 31 at most, "/" put at its end when it has no "/" or
; ":"): 0 the letter itself again; a folder of a drive, else the DOS's error
fn_hyp_info_sd_uc_set:		; Hyp.cls 2882
            ld a, (g_FL_UB + 1)		; Hyp.cls 2883
            call g_fl_mapa		; Hyp.cls 2884
            jp c, g_fp_done		; Hyp.cls 2885
            push hl		; Hyp.cls 2886
            ld a, (g_FL_UB + 2)		; Hyp.cls 2887
            or a		; Hyp.cls 2888
            jr z, fn_hyp_info_sd_us_put		; Hyp.cls 2889
            cp 32		; Hyp.cls 2890
            jr nc, fn_hyp_info_sd_us_no		; Hyp.cls 2891
            ld b, a		; Hyp.cls 2892
            ld hl, g_FL_UB + 3		; Hyp.cls 2893
fn_hyp_info_sd_us_up:                           ; capitals [2894]
            ld a, (hl)		; Hyp.cls 2895
            cp 'a'		; Hyp.cls 2896
            jr c, fn_hyp_info_sd_us_c		; Hyp.cls 2897
            cp 'z' + 1		; Hyp.cls 2898
            jr nc, fn_hyp_info_sd_us_c		; Hyp.cls 2899
            sub 32		; Hyp.cls 2900
            ld (hl), a		; Hyp.cls 2901
fn_hyp_info_sd_us_c:		; Hyp.cls 2902
            inc hl		; Hyp.cls 2903
            djnz fn_hyp_info_sd_us_up		; Hyp.cls 2904
            dec hl		; Hyp.cls 2905
            ld a, (hl)		; Hyp.cls 2906
            cp ':'		; Hyp.cls 2907
            jr z, fn_hyp_info_sd_us_try		; Hyp.cls 2908
            cp '/'		; Hyp.cls 2909
            jr z, fn_hyp_info_sd_us_try		; Hyp.cls 2910
            ld a, (g_FL_UB + 2)		; Hyp.cls 2911
            cp 31		; Hyp.cls 2912
            jr nc, fn_hyp_info_sd_us_no		; Hyp.cls 2913
            inc a		; Hyp.cls 2914
            ld (g_FL_UB + 2), a		; Hyp.cls 2915
            inc hl		; Hyp.cls 2916
            ld (hl), '/'		; Hyp.cls 2917
fn_hyp_info_sd_us_try:		; Hyp.cls 2918
            ld hl, g_FL_UB + 2		; Hyp.cls 2919
            call fn_hyp_info_sd_folder          ; (DE at its 0) [2920]
            dec de		; Hyp.cls 2921
            ld a, (de)		; Hyp.cls 2922
            cp ':'		; Hyp.cls 2923
            jr z, fn_hyp_info_sd_us_put         ; (a drive alone: its current folder; its top) [2924]
            cp #5C		; Hyp.cls 2925
            jr z, fn_hyp_info_sd_us_put		; Hyp.cls 2926
            ld de, fn_hyp_info_sd_nm		; Hyp.cls 2927
            ld b, #10               ; _FFIRST: there, and a folder? [2928]
            ld ix, fn_hyp_info_sd_fib		; Hyp.cls 2929
            ld c, #40		; Hyp.cls 2930
            call fn_hyp_info_sd_dos		; Hyp.cls 2931
            jr c, fn_hyp_info_sd_us_err		; Hyp.cls 2932
            ld a, (fn_hyp_info_sd_fib + 14)		; Hyp.cls 2933
            and #10		; Hyp.cls 2934
            ld a, #D6               ; (.NODIR when a file) [2935]
            scf		; Hyp.cls 2936
            jr z, fn_hyp_info_sd_us_err		; Hyp.cls 2937
fn_hyp_info_sd_us_put:		; Hyp.cls 2938
            pop de		; Hyp.cls 2939
            ld hl, g_FL_UB + 2		; Hyp.cls 2940
            ld bc, 32		; Hyp.cls 2941
            ldir		; Hyp.cls 2942
            jp g_fl_ok		; Hyp.cls 2943
fn_hyp_info_sd_us_no:		; Hyp.cls 2944
            pop hl		; Hyp.cls 2945
            jp g_fp_done		; Hyp.cls 2946
fn_hyp_info_sd_us_err:		; Hyp.cls 2947
            pop hl		; Hyp.cls 2948
            or a		; Hyp.cls 2949
            jr nz, fn_hyp_info_sd_us_e1		; Hyp.cls 2950
            inc a		; Hyp.cls 2951
fn_hyp_info_sd_us_e1:		; Hyp.cls 2952
            ld (g_fl_res), a		; Hyp.cls 2953
            jp g_fp_done		; Hyp.cls 2954
; 5: the folder's entry Word(2): Byte(1) the letter (its path; none: 254 - the archive, listed
; by the search), 0 the path at Byte(28). Entry 0 fills the cache (folders too). Back: Byte(4)
; its bits (bit 4 a folder, 0 read only, 1 hidden, 2 system), Byte(5-8) its size, Byte(9-15)
; its date (the year as a word, month, day, hours, minutes, seconds), Byte(16-26) its name: 0;
; 1 no more
fn_hyp_info_sd_uc_dir:		; Hyp.cls 2960
            ld a, (g_FL_UB + 1)		; Hyp.cls 2961
            or a		; Hyp.cls 2962
            jr z, fn_hyp_info_sd_ud_p		; Hyp.cls 2963
            call g_fl_mapa		; Hyp.cls 2964
            jp c, fn_hyp_info_sd_ud_254		; Hyp.cls 2965
            jp z, fn_hyp_info_sd_ud_254		; Hyp.cls 2966
            jr fn_hyp_info_sd_ud_k		; Hyp.cls 2967
fn_hyp_info_sd_ud_p:		; Hyp.cls 2968
            ld hl, g_FL_UB + 28		; Hyp.cls 2969
            ld a, (hl)		; Hyp.cls 2970
            cp 32		; Hyp.cls 2971
            jp nc, g_fp_done		; Hyp.cls 2972
fn_hyp_info_sd_ud_k:		; Hyp.cls 2973
            ld de, (g_FL_UB + 2)		; Hyp.cls 2974
            ld a, d		; Hyp.cls 2975
            or e		; Hyp.cls 2976
            jr nz, fn_hyp_info_sd_ud_n		; Hyp.cls 2977
            ld a, 1		; Hyp.cls 2978
            call fn_hyp_info_sd_cache           ; (HL = the path) [2979]
            or a		; Hyp.cls 2980
            jr z, fn_hyp_info_sd_ud_n		; Hyp.cls 2981
            ld (g_fl_res), a		; Hyp.cls 2982
            jp g_fp_done		; Hyp.cls 2983
fn_hyp_info_sd_ud_n:		; Hyp.cls 2984
            ld a, (g_fl_cn)		; Hyp.cls 2985
            ld hl, (g_FL_UB + 2)		; Hyp.cls 2986
            ld c, a		; Hyp.cls 2987
            ld b, 0		; Hyp.cls 2988
            or a		; Hyp.cls 2989
            sbc hl, bc		; Hyp.cls 2990
            jp nc, fn_hyp_info_sd_ud_end        ; no more (1) [2991]
            ld hl, (g_FL_UB + 2)		; Hyp.cls 2992
            add hl, hl		; Hyp.cls 2993
            add hl, hl		; Hyp.cls 2994
            add hl, hl		; Hyp.cls 2995
            add hl, hl		; Hyp.cls 2996
            add hl, hl		; Hyp.cls 2997
            add hl, hl		; Hyp.cls 2998
            ld de, #6000		; Hyp.cls 2999
            add hl, de              ; the entry [3000]
            push hl		; Hyp.cls 3001
            ld bc, 13		; Hyp.cls 3002
            add hl, bc		; Hyp.cls 3003
            ld a, (hl)		; Hyp.cls 3004
            and #17		; Hyp.cls 3005
            ld (g_FL_UB + 4), a		; Hyp.cls 3006
            inc hl		; Hyp.cls 3007
            inc hl		; Hyp.cls 3008
            inc hl		; Hyp.cls 3009
            ld de, g_FL_UB + 5		; Hyp.cls 3010
            ld bc, 4		; Hyp.cls 3011
            ldir                    ; the size [3012]
            ld e, (hl)              ; time [3013]
            inc hl		; Hyp.cls 3014
            ld d, (hl)		; Hyp.cls 3015
            inc hl		; Hyp.cls 3016
            ld c, (hl)              ; date [3017]
            inc hl		; Hyp.cls 3018
            ld b, (hl)		; Hyp.cls 3019
            push de		; Hyp.cls 3020
            ld a, b		; Hyp.cls 3021
            srl a		; Hyp.cls 3022
            ld l, a		; Hyp.cls 3023
            ld h, 0		; Hyp.cls 3024
            ld de, 1980		; Hyp.cls 3025
            add hl, de		; Hyp.cls 3026
            ld (g_FL_UB + 9), hl    ; the year [3027]
            ld a, b		; Hyp.cls 3028
            and 1		; Hyp.cls 3029
            rlca		; Hyp.cls 3030
            rlca		; Hyp.cls 3031
            rlca		; Hyp.cls 3032
            ld h, a		; Hyp.cls 3033
            ld a, c		; Hyp.cls 3034
            rlca		; Hyp.cls 3035
            rlca		; Hyp.cls 3036
            rlca		; Hyp.cls 3037
            and 7		; Hyp.cls 3038
            or h		; Hyp.cls 3039
            ld (g_FL_UB + 11), a    ; the month [3040]
            ld a, c		; Hyp.cls 3041
            and 31		; Hyp.cls 3042
            ld (g_FL_UB + 12), a    ; the day [3043]
            pop de		; Hyp.cls 3044
            ld a, d		; Hyp.cls 3045
            srl a		; Hyp.cls 3046
            srl a		; Hyp.cls 3047
            srl a		; Hyp.cls 3048
            ld (g_FL_UB + 13), a    ; hours [3049]
            ld a, d		; Hyp.cls 3050
            and 7		; Hyp.cls 3051
            rlca		; Hyp.cls 3052
            rlca		; Hyp.cls 3053
            rlca		; Hyp.cls 3054
            ld h, a		; Hyp.cls 3055
            ld a, e		; Hyp.cls 3056
            rlca		; Hyp.cls 3057
            rlca		; Hyp.cls 3058
            rlca		; Hyp.cls 3059
            and 7		; Hyp.cls 3060
            or h		; Hyp.cls 3061
            ld (g_FL_UB + 14), a    ; minutes [3062]
            ld a, e		; Hyp.cls 3063
            and 31		; Hyp.cls 3064
            add a, a		; Hyp.cls 3065
            ld (g_FL_UB + 15), a    ; seconds [3066]
            pop hl		; Hyp.cls 3067
            inc hl		; Hyp.cls 3068
            ld de, g_FL_UB + 16		; Hyp.cls 3069
            ld bc, 11		; Hyp.cls 3070
            ldir                    ; the name [3071]
            xor a		; Hyp.cls 3072
            ld b, 28		; Hyp.cls 3073
            jp g_fl_uc_back		; Hyp.cls 3074
fn_hyp_info_sd_ud_254:		; Hyp.cls 3075
            ld a, 254		; Hyp.cls 3076
            ld (g_fl_res), a		; Hyp.cls 3077
            jp g_fp_done		; Hyp.cls 3078
fn_hyp_info_sd_ud_end:		; Hyp.cls 3079
            ld a, 1		; Hyp.cls 3080
            ld (g_fl_res), a		; Hyp.cls 3081
            jp g_fp_done		; Hyp.cls 3082
; ---- at the start (FileCall 99, the page in the window): every drive letter A-H the DOS's own
; ("A:" ...: a path, so the hooks take it); FileCall 99's answer the current drive's letter
; (_CURDRV) - Main's boot drive; then fl_done
fn_hyp_info_sd_drv:     db 'A'                  ; the current drive's letter [3086]
@sd_h_init:		; Hyp.cls 3087
            ld (fn_hyp_info_sd_par), hl         ; (fl_inst: HL FileCall's parameters, DE fin, BC fout) [3088]
            ld (fn_hyp_info_sd_pfin), de		; Hyp.cls 3089
            ld (fn_hyp_info_sd_pfout), bc		; Hyp.cls 3090
            ld a, 1		; Hyp.cls 3091
            ld (g_fl_cjf), a		; Hyp.cls 3092
            ld hl, g_FL_MAP		; Hyp.cls 3093
            ld de, g_FL_MAP + 1		; Hyp.cls 3094
            ld bc, 511		; Hyp.cls 3095
            ld (hl), 0		; Hyp.cls 3096
            ldir		; Hyp.cls 3097
            ld c, #19               ; _CURDRV: L = the drive (0 A) [3098]
            call 5		; Hyp.cls 3099
            di		; Hyp.cls 3100
            ld a, l		; Hyp.cls 3101
            and 7		; Hyp.cls 3102
            add a, 'A'		; Hyp.cls 3103
            ld (fn_hyp_info_sd_drv), a		; Hyp.cls 3104
            ld hl, g_FL_MAP         ; A: - H: "A:" - "H:" [3105]
            ld b, 'A'		; Hyp.cls 3106
fn_hyp_info_sd_in_lp:		; Hyp.cls 3107
            ld (hl), 2		; Hyp.cls 3108
            inc hl		; Hyp.cls 3109
            ld (hl), b		; Hyp.cls 3110
            inc hl		; Hyp.cls 3111
            ld (hl), ':'		; Hyp.cls 3112
            ld de, 30		; Hyp.cls 3113
            add hl, de		; Hyp.cls 3114
            inc b		; Hyp.cls 3115
            ld a, b		; Hyp.cls 3116
            cp 'I'		; Hyp.cls 3117
            jr nz, fn_hyp_info_sd_in_lp		; Hyp.cls 3118
            ld a, (fn_hyp_info_sd_drv)		; Hyp.cls 3119
            ld (g_fl_res), a		; Hyp.cls 3120
            jp g_fl_done		; Hyp.cls 3121
; ---- FileShut: the slot's files closed with the rest
@sd_shut_in:		; Hyp.cls 3123
            ld a, (fn_hyp_info_sd_fi)		; Hyp.cls 3124
            call fn_hyp_info_sd_hclose		; Hyp.cls 3125
            xor a		; Hyp.cls 3126
            ld (fn_hyp_info_sd_fi), a		; Hyp.cls 3127
            ret		; Hyp.cls 3128
@sd_shut_out:		; Hyp.cls 3129
            ld a, (fn_hyp_info_sd_fo)		; Hyp.cls 3130
            call fn_hyp_info_sd_hclose		; Hyp.cls 3131
            xor a		; Hyp.cls 3132
            ld (fn_hyp_info_sd_fo), a		; Hyp.cls 3133
            ret		; Hyp.cls 3134
    ENDIF		; Hyp.cls 3135
            ds #5300 - $		; Hyp.cls 3136
; page zero (#0000-#0080)
fn_hyp_info_hi_p0:		; Hyp.cls 3138
            db #C3		; Hyp.cls 3139
            dw fn_hyp_info_sb_bwb                           ; #0000: warm boot - the BIOS's WBOOT (the task [3140]
            db 0, 0                             ; ends); (#0001) - 3: the BIOS jump table [3141]
            db #C3		; Hyp.cls 3142
            dw fn_hyp_info_sb_start                         ; #0005: BDOS (#0006: the top of the TPA) [3143]
            ds #38 - 8		; Hyp.cls 3144
            db #C3		; Hyp.cls 3145
            dw fn_hyp_info_sb_int                           ; #0038: the interrupt [3146]
            ds #44 - #3B		; Hyp.cls 3147
    IFDEF NTC_MSXDOS		; Hyp.cls 3148
            ds #5C - #44                        ; (MSX: no #0044 glue - the switch is in page 3: sb_hout / sb_hin at HISW) [3149]
    ELSE		; Hyp.cls 3150
            db #ED, #49                         ; #0044: out (c), c [3151]
            db #C3		; Hyp.cls 3152
            dw fn_hyp_info_sb_land                          ; #0046: this bank switched in [3153]
            ds #5C - #49		; Hyp.cls 3154
    ENDIF		; Hyp.cls 3155
            db 0, "           "                 ; #005C: the default FCB [3156]
            ds #80 - #68		; Hyp.cls 3157
            db 0                                ; #0080: no command tail [3158]
fn_hyp_info_hi_p0e:		; Hyp.cls 3159
; the stubs: assembled here, run at STUB in the bank (DISP: their labels are the bank's
; addresses). The BDOS: what needs nothing of the hypervisor is answered here, with no
; switch - the console out (2, 9: collected at OBUF; the hypervisor gets them, IX = how many, at
; the next far call or interrupt, or when 128 wait), the keys (1, 6, 10, 11: from KEY, where
; the hypervisor leaves the slot's next key), the IOBYTE (7, 8), the disc's parameters (27, 31)
; and the calls with nothing to do (3, 4, 5, 28, 29, 30, 37 - 30 with #C0 on at DE is CyborgOS's
; UniDOS call), CP/M 3's 49 for the console's size (MODE); the rest is a far call. Then the
; BIOS (its jump table: (#0001) - 3) and the start-up (the default FCBs)
fn_hyp_info_sb_img:		; Hyp.cls 3168
            DISP 61184		; Hyp.cls 3169
fn_hyp_info_sb_start:		; Hyp.cls 3170
            ld a, c                             ; BDOS: C = function, DE = argument [3171]
            cp 6                                ; 6 and 11 with interrupts left as they are: a key poll [3172]
            jr z, fn_hyp_info_sb_f6                         ; loop is the time a slot has them in at all, and a [3173]
            cp 11                               ; tick missed there is the Next's pulse gone (sb_get [3174]
            jr z, fn_hyp_info_sb_stat                       ; closes them for the two instructions that take the key) [3175]
            di		; Hyp.cls 3176
            cp 2		; Hyp.cls 3177
            jp z, fn_hyp_info_sb_put		; Hyp.cls 3178
            cp 1		; Hyp.cls 3179
            jp z, fn_hyp_info_sb_f1		; Hyp.cls 3180
            cp 9		; Hyp.cls 3181
            jp z, fn_hyp_info_sb_str		; Hyp.cls 3182
            cp 10		; Hyp.cls 3183
            jp z, fn_hyp_info_sb_line		; Hyp.cls 3184
            cp 3		; Hyp.cls 3185
            jr z, fn_hyp_info_sb_rdr		; Hyp.cls 3186
            cp 7		; Hyp.cls 3187
            jr z, fn_hyp_info_sb_iob		; Hyp.cls 3188
            cp 8		; Hyp.cls 3189
            jr z, fn_hyp_info_sb_siob		; Hyp.cls 3190
            cp 27		; Hyp.cls 3191
            jr z, fn_hyp_info_sb_alv		; Hyp.cls 3192
            cp 31		; Hyp.cls 3193
            jr z, fn_hyp_info_sb_dpb		; Hyp.cls 3194
            cp 4		; Hyp.cls 3195
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 3196
            cp 5		; Hyp.cls 3197
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 3198
            cp 28		; Hyp.cls 3199
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 3200
            cp 29		; Hyp.cls 3201
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 3202
            cp 30		; Hyp.cls 3203
            jr z, fn_hyp_info_sb_f30		; Hyp.cls 3204
            cp 37		; Hyp.cls 3205
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 3206
            cp 49		; Hyp.cls 3207
            jp z, fn_hyp_info_sb_scb		; Hyp.cls 3208
            jp fn_hyp_info_sb_call		; Hyp.cls 3209
fn_hyp_info_sb_f30:                                         ; 30: nothing - unless #C0 on at DE: CyborgOS's [3210]
            ld a, (de)                          ; UniDOS call (CD, DIR: the hypervisor's) [3211]
            cp #C0		; Hyp.cls 3212
            jp nc, fn_hyp_info_sb_call		; Hyp.cls 3213
fn_hyp_info_sb_zero:		; Hyp.cls 3214
            xor a                               ; 4, 5 (the printer: not yet), 28, 29, 30, 37 [3215]
fn_hyp_info_sb_ret:		; Hyp.cls 3216
            ld l, a		; Hyp.cls 3217
            ld h, 0		; Hyp.cls 3218
            ei		; Hyp.cls 3219
            ret		; Hyp.cls 3220
fn_hyp_info_sb_rdr:		; Hyp.cls 3221
            ld a, #1A                           ; 3: the reader - the end of a file [3222]
            jr fn_hyp_info_sb_ret		; Hyp.cls 3223
fn_hyp_info_sb_iob:		; Hyp.cls 3224
            ld a, (#0003)                       ; 7: the IOBYTE [3225]
            jr fn_hyp_info_sb_ret		; Hyp.cls 3226
fn_hyp_info_sb_siob:		; Hyp.cls 3227
            ld a, e                             ; 8 [3228]
            ld (#0003), a		; Hyp.cls 3229
            jr fn_hyp_info_sb_zero		; Hyp.cls 3230
fn_hyp_info_sb_alv:		; Hyp.cls 3231
            ld hl, fn_hyp_info_sb_alvec                     ; 27: the allocation vector (a CPC data disc's) [3232]
            ei		; Hyp.cls 3233
            ret		; Hyp.cls 3234
fn_hyp_info_sb_dpb:		; Hyp.cls 3235
            ld hl, fn_hyp_info_sb_dpbv                      ; 31: the disc parameter block [3236]
            ei		; Hyp.cls 3237
            ret		; Hyp.cls 3238
fn_hyp_info_sb_f6:		; Hyp.cls 3239
            ld a, e		; Hyp.cls 3240
            cp #FF		; Hyp.cls 3241
            jr z, fn_hyp_info_sb_get		; Hyp.cls 3242
            cp #FE		; Hyp.cls 3243
            jr c, fn_hyp_info_sb_put		; Hyp.cls 3244
fn_hyp_info_sb_stat:		; Hyp.cls 3245
            ld a, (63105)                       ; 6 / #FE, 11: is a key waiting (#FF / 0) [3246]
            or a		; Hyp.cls 3247
            jr z, fn_hyp_info_sb_poll		; Hyp.cls 3248
            ld a, #FF		; Hyp.cls 3249
            jr fn_hyp_info_sb_ret		; Hyp.cls 3250
fn_hyp_info_sb_get:		; Hyp.cls 3251
            ld hl, 63105                        ; 6 / #FF: the key or 0 (no wait) [3252]
            di		; Hyp.cls 3253
            ld a, (hl)		; Hyp.cls 3254
            ld (hl), 0		; Hyp.cls 3255
            or a		; Hyp.cls 3256
            jr nz, fn_hyp_info_sb_ret		; Hyp.cls 3257
fn_hyp_info_sb_poll:                                        ; no key: a program polling (Inkey, Input) gives the [3258]
            ld hl, fn_hyp_info_SB_POLLC                     ; hypervisor a turn every 256th empty poll - its keys [3259]
            inc (hl)                            ; reach KEY only when it runs, and a tight poll loop [3260]
            jr nz, fn_hyp_info_sb_zero                      ; with interrupts off (NTC: on for an instruction a [3261]
            ld c, 12                            ; call) can miss the Next's INT pulse for ever [3262]
            call fn_hyp_info_sb_call                        ; (a far call ends the slot's turn, as 12 does) [3263]
            jr fn_hyp_info_sb_zero		; Hyp.cls 3264
fn_hyp_info_sb_f1:		; Hyp.cls 3265
            call fn_hyp_info_sb_key                         ; 1: a key (waited for), echoed [3266]
            push af		; Hyp.cls 3267
            ld e, a		; Hyp.cls 3268
            call fn_hyp_info_sb_putc		; Hyp.cls 3269
            pop af		; Hyp.cls 3270
            jr fn_hyp_info_sb_ret		; Hyp.cls 3271
fn_hyp_info_sb_put:		; Hyp.cls 3272
            di		; Hyp.cls 3273
            call fn_hyp_info_sb_putc                        ; 2: E out (6 / E < #FE too) [3274]
            ei		; Hyp.cls 3275
            ret		; Hyp.cls 3276
fn_hyp_info_sb_str:		; Hyp.cls 3277
            ld h, d                             ; 9: the string at DE, to "$" [3278]
            ld l, e		; Hyp.cls 3279
fn_hyp_info_sb_st_lp:		; Hyp.cls 3280
            ld a, (hl)		; Hyp.cls 3281
            cp '$'		; Hyp.cls 3282
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 3283
            push hl		; Hyp.cls 3284
            ld e, a		; Hyp.cls 3285
            call fn_hyp_info_sb_putc		; Hyp.cls 3286
            pop hl		; Hyp.cls 3287
            inc hl		; Hyp.cls 3288
            jr fn_hyp_info_sb_st_lp		; Hyp.cls 3289
; sb_putc - E collected at OBUF (the hypervisor shown them when 128 wait). Interrupts off
fn_hyp_info_sb_putc:		; Hyp.cls 3291
            ld hl, 62976 + 128                 ; the count [3292]
            ld a, (hl)		; Hyp.cls 3293
            inc (hl)		; Hyp.cls 3294
            ld l, a		; Hyp.cls 3295
            ld h, 62976 / 256		; Hyp.cls 3296
            ld (hl), e		; Hyp.cls 3297
            cp 127		; Hyp.cls 3298
            ret c		; Hyp.cls 3299
            push bc		; Hyp.cls 3300
            push de		; Hyp.cls 3301
            ld c, #80                           ; full: function #80, only the characters [3302]
            call fn_hyp_info_sb_call		; Hyp.cls 3303
            di		; Hyp.cls 3304
            pop de		; Hyp.cls 3305
            pop bc		; Hyp.cls 3306
            ret		; Hyp.cls 3307
; sb_key - A = the next key, waited for: none at KEY - a far call (#81) that has the hypervisor
; run the others until a key comes (or the clock moves on), then look again
fn_hyp_info_sb_key:		; Hyp.cls 3310
            ld hl, 63105		; Hyp.cls 3311
            ld a, (hl)		; Hyp.cls 3312
            or a		; Hyp.cls 3313
            jr z, fn_hyp_info_sb_k_wait		; Hyp.cls 3314
            ld (hl), 0		; Hyp.cls 3315
            ret		; Hyp.cls 3316
fn_hyp_info_sb_k_wait:		; Hyp.cls 3317
            ld c, #81                           ; (BC, DE: nothing after needs them) [3318]
            call fn_hyp_info_sb_call		; Hyp.cls 3319
            di		; Hyp.cls 3320
            jr fn_hyp_info_sb_key		; Hyp.cls 3321
; 10: a line typed into the buffer at DE (its size, then how many came, then them): BS / DEL
; rub out, Control + U / X the whole line, Control + C at its start ends the program, CR / LF
; end it (CR echoed)
fn_hyp_info_sb_line:		; Hyp.cls 3325
            ld (fn_hyp_info_sb_lbuf), de		; Hyp.cls 3326
            xor a		; Hyp.cls 3327
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 3328
fn_hyp_info_sb_l_lp:		; Hyp.cls 3329
            call fn_hyp_info_sb_key		; Hyp.cls 3330
            cp 13		; Hyp.cls 3331
            jr z, fn_hyp_info_sb_l_end		; Hyp.cls 3332
            cp 10		; Hyp.cls 3333
            jr z, fn_hyp_info_sb_l_end		; Hyp.cls 3334
            cp 8		; Hyp.cls 3335
            jr z, fn_hyp_info_sb_l_bs		; Hyp.cls 3336
            cp 127		; Hyp.cls 3337
            jr z, fn_hyp_info_sb_l_bs		; Hyp.cls 3338
            cp 21		; Hyp.cls 3339
            jr z, fn_hyp_info_sb_l_kill		; Hyp.cls 3340
            cp 24		; Hyp.cls 3341
            jr z, fn_hyp_info_sb_l_kill		; Hyp.cls 3342
            cp 3		; Hyp.cls 3343
            jr nz, fn_hyp_info_sb_l_ch		; Hyp.cls 3344
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 3345
            or a		; Hyp.cls 3346
            jr nz, fn_hyp_info_sb_l_lp		; Hyp.cls 3347
            ld c, 0                             ; Control + C: the program ends [3348]
            jp fn_hyp_info_sb_call		; Hyp.cls 3349
fn_hyp_info_sb_l_ch:		; Hyp.cls 3350
            cp 32		; Hyp.cls 3351
            jr c, fn_hyp_info_sb_l_lp		; Hyp.cls 3352
            ld b, a		; Hyp.cls 3353
            ld hl, (fn_hyp_info_sb_lbuf)		; Hyp.cls 3354
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 3355
            cp (hl)		; Hyp.cls 3356
            jr nc, fn_hyp_info_sb_l_lp                      ; full [3357]
            inc a		; Hyp.cls 3358
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 3359
            ld e, a		; Hyp.cls 3360
            ld d, 0		; Hyp.cls 3361
            inc hl		; Hyp.cls 3362
            add hl, de		; Hyp.cls 3363
            ld (hl), b		; Hyp.cls 3364
            ld e, b		; Hyp.cls 3365
            call fn_hyp_info_sb_putc		; Hyp.cls 3366
            jr fn_hyp_info_sb_l_lp		; Hyp.cls 3367
fn_hyp_info_sb_l_kill:		; Hyp.cls 3368
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 3369
            or a		; Hyp.cls 3370
            jr z, fn_hyp_info_sb_l_lp		; Hyp.cls 3371
            call fn_hyp_info_sb_l_rub		; Hyp.cls 3372
            jr fn_hyp_info_sb_l_kill		; Hyp.cls 3373
fn_hyp_info_sb_l_bs:		; Hyp.cls 3374
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 3375
            or a		; Hyp.cls 3376
            jr z, fn_hyp_info_sb_l_lp		; Hyp.cls 3377
            call fn_hyp_info_sb_l_rub		; Hyp.cls 3378
            jr fn_hyp_info_sb_l_lp		; Hyp.cls 3379
fn_hyp_info_sb_l_rub:		; Hyp.cls 3380
            dec a		; Hyp.cls 3381
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 3382
            ld e, 8		; Hyp.cls 3383
            call fn_hyp_info_sb_putc		; Hyp.cls 3384
            ld e, ' '		; Hyp.cls 3385
            call fn_hyp_info_sb_putc		; Hyp.cls 3386
            ld e, 8		; Hyp.cls 3387
            jp fn_hyp_info_sb_putc		; Hyp.cls 3388
fn_hyp_info_sb_l_end:		; Hyp.cls 3389
            ld hl, (fn_hyp_info_sb_lbuf)		; Hyp.cls 3390
            inc hl		; Hyp.cls 3391
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 3392
            ld (hl), a		; Hyp.cls 3393
            ld e, 13		; Hyp.cls 3394
            call fn_hyp_info_sb_putc		; Hyp.cls 3395
            jp fn_hyp_info_sb_zero		; Hyp.cls 3396
fn_hyp_info_sb_lbuf:    equ #F6E9                           ; (the bank's own bytes after the program's name, [3397]
fn_hyp_info_sb_lcnt:    equ #F6EB                           ; #F6D8-#F6E4, not the stub's: it is at its limit) [3398]
fn_hyp_info_SB_POLLC:   equ #F6E8		; Hyp.cls 3399
fn_hyp_info_sb_call:		; Hyp.cls 3400
            di                                  ; (a poll's turn given with them in) [3401]
            push ix                             ; a far call: IX, IY and the alternate [3402]
            push iy                             ; registers kept over it (ex af, af') [3403]
            db #08		; Hyp.cls 3404
            exx		; Hyp.cls 3405
            push af		; Hyp.cls 3406
            push bc		; Hyp.cls 3407
            push de		; Hyp.cls 3408
            push hl		; Hyp.cls 3409
            exx		; Hyp.cls 3410
            db #08		; Hyp.cls 3411
            ld a, (62976 + 128)		; Hyp.cls 3412
            ld ixl, a		; Hyp.cls 3413
            ld ixh, 0		; Hyp.cls 3414
            ld a, c		; Hyp.cls 3415
            ld hl, fn_hyp_info_sb_far		; Hyp.cls 3416
            push hl		; Hyp.cls 3417
            ld (#FFFE), sp		; Hyp.cls 3418
            ld bc, #7FC0		; Hyp.cls 3419
            scf                                 ; carry: a far call [3420]
    IFDEF NTC_MSXDOS		; Hyp.cls 3421
            jp fn_hyp_info_sb_hout		; Hyp.cls 3422
    ELSE		; Hyp.cls 3423
            jp #0044		; Hyp.cls 3424
    ENDIF		; Hyp.cls 3425
fn_hyp_info_sb_far:		; Hyp.cls 3426
            db #08                              ; the answer in A and HL; the program's [3427]
            exx                                 ; other registers back [3428]
            pop hl		; Hyp.cls 3429
            pop de		; Hyp.cls 3430
            pop bc		; Hyp.cls 3431
            pop af		; Hyp.cls 3432
            exx		; Hyp.cls 3433
            db #08		; Hyp.cls 3434
            pop iy		; Hyp.cls 3435
            pop ix		; Hyp.cls 3436
            ei		; Hyp.cls 3437
            ret		; Hyp.cls 3438
fn_hyp_info_sb_int:		; Hyp.cls 3439
            push af                             ; an interrupt: everything kept [3440]
            push bc		; Hyp.cls 3441
            push de		; Hyp.cls 3442
            push hl		; Hyp.cls 3443
            db #08                              ; ex af, af' [3444]
            exx		; Hyp.cls 3445
            push af		; Hyp.cls 3446
            push bc		; Hyp.cls 3447
            push de		; Hyp.cls 3448
            push hl		; Hyp.cls 3449
            push ix		; Hyp.cls 3450
            push iy		; Hyp.cls 3451
            ld a, (62976 + 128)		; Hyp.cls 3452
            ld ixl, a		; Hyp.cls 3453
            ld ixh, 0		; Hyp.cls 3454
            ld hl, fn_hyp_info_sb_rest		; Hyp.cls 3455
            push hl		; Hyp.cls 3456
            ld (#FFFE), sp		; Hyp.cls 3457
            ld bc, #7FC0		; Hyp.cls 3458
            or a                                ; no carry: an interrupt [3459]
    IFDEF NTC_MSXDOS		; Hyp.cls 3460
            jp fn_hyp_info_sb_hout		; Hyp.cls 3461
    ELSE		; Hyp.cls 3462
            jp #0044		; Hyp.cls 3463
    ENDIF		; Hyp.cls 3464
fn_hyp_info_sb_rest:		; Hyp.cls 3465
            pop iy		; Hyp.cls 3466
            pop ix		; Hyp.cls 3467
            pop hl		; Hyp.cls 3468
            pop de		; Hyp.cls 3469
            pop bc		; Hyp.cls 3470
            pop af		; Hyp.cls 3471
            exx		; Hyp.cls 3472
            db #08                              ; ex af, af' [3473]
            pop hl		; Hyp.cls 3474
            pop de		; Hyp.cls 3475
            pop bc		; Hyp.cls 3476
            pop af		; Hyp.cls 3477
            ei		; Hyp.cls 3478
            ret		; Hyp.cls 3479
fn_hyp_info_sb_land:		; Hyp.cls 3480
            ld sp, (#FFFE)                      ; this bank's SP [3481]
            push af		; Hyp.cls 3482
            ld a, e                             ; E = 1: the hypervisor has the characters [3483]
            or a		; Hyp.cls 3484
            jr z, fn_hyp_info_sb_lkeep		; Hyp.cls 3485
            xor a		; Hyp.cls 3486
            ld (62976 + 128), a		; Hyp.cls 3487
fn_hyp_info_sb_lkeep:		; Hyp.cls 3488
            pop af		; Hyp.cls 3489
            ret		; Hyp.cls 3490
fn_hyp_info_sb_scb:		; Hyp.cls 3491
            ld h, d                             ; 49 (CP/M 3's system control block): the [3492]
            ld l, e                             ; console's width - 1 (#1A), its page length [3493]
            inc hl                              ; (#1C) - MODE's; other bytes 0, sets kept [3494]
            ld a, (hl)                          ; nowhere [3495]
            or a		; Hyp.cls 3496
            jp nz, fn_hyp_info_sb_zero		; Hyp.cls 3497
            ld a, (de)		; Hyp.cls 3498
            cp #1C		; Hyp.cls 3499
            ld hl, 63112		; Hyp.cls 3500
            jr z, fn_hyp_info_sb_scb_a		; Hyp.cls 3501
            cp #1A		; Hyp.cls 3502
            jp nz, fn_hyp_info_sb_zero		; Hyp.cls 3503
            ld a, (63111)		; Hyp.cls 3504
            dec a		; Hyp.cls 3505
            jp fn_hyp_info_sb_ret		; Hyp.cls 3506
fn_hyp_info_sb_scb_a:		; Hyp.cls 3507
            ld a, (hl)		; Hyp.cls 3508
            jp fn_hyp_info_sb_ret		; Hyp.cls 3509
; the BIOS: CP/M 2.2's 17 entries. The console ones as the BDOS's; the printer and punch take
; nothing yet; the disc ones (sectors) can't be had here: SELDSK gives 0 (no such drive),
; READ / WRITE 1 (an error)
fn_hyp_info_sb_bios:		; Hyp.cls 3513
            jp fn_hyp_info_sb_bboot                         ; BOOT [3514]
fn_hyp_info_sb_bwb:		; Hyp.cls 3515
            jp fn_hyp_info_sb_bboot                         ; WBOOT: (#0001) [3516]
            jp fn_hyp_info_sb_bconst                        ; CONST [3517]
            jp fn_hyp_info_sb_bconin                        ; CONIN [3518]
            jp fn_hyp_info_sb_bconout                       ; CONOUT [3519]
            jp fn_hyp_info_sb_bnone                         ; LIST [3520]
            jp fn_hyp_info_sb_bnone                         ; PUNCH [3521]
            jp fn_hyp_info_sb_brdr                          ; READER [3522]
            jp fn_hyp_info_sb_bnone                         ; HOME [3523]
            jp fn_hyp_info_sb_bseld                         ; SELDSK [3524]
            jp fn_hyp_info_sb_bnone                         ; SETTRK [3525]
            jp fn_hyp_info_sb_bnone                         ; SETSEC [3526]
            jp fn_hyp_info_sb_bdma                          ; SETDMA [3527]
            jp fn_hyp_info_sb_bfail                         ; READ [3528]
            jp fn_hyp_info_sb_bfail                         ; WRITE [3529]
            jp fn_hyp_info_sb_blstst                        ; LISTST [3530]
            jp fn_hyp_info_sb_bsectr                        ; SECTRAN [3531]
fn_hyp_info_sb_bboot:		; Hyp.cls 3532
            ld c, 0                             ; the task ends [3533]
            jp fn_hyp_info_sb_start		; Hyp.cls 3534
fn_hyp_info_sb_bconst:		; Hyp.cls 3535
            di		; Hyp.cls 3536
            ld a, (63105)		; Hyp.cls 3537
            or a		; Hyp.cls 3538
            jr z, fn_hyp_info_sb_bc_n		; Hyp.cls 3539
            ld a, #FF		; Hyp.cls 3540
fn_hyp_info_sb_bc_n:		; Hyp.cls 3541
            ei		; Hyp.cls 3542
            ret		; Hyp.cls 3543
fn_hyp_info_sb_bconin:		; Hyp.cls 3544
            di		; Hyp.cls 3545
            call fn_hyp_info_sb_key		; Hyp.cls 3546
            ei		; Hyp.cls 3547
            ret		; Hyp.cls 3548
fn_hyp_info_sb_bconout:		; Hyp.cls 3549
            di		; Hyp.cls 3550
            ld e, c		; Hyp.cls 3551
            call fn_hyp_info_sb_putc		; Hyp.cls 3552
            ei		; Hyp.cls 3553
fn_hyp_info_sb_bnone:		; Hyp.cls 3554
            ret		; Hyp.cls 3555
fn_hyp_info_sb_brdr:		; Hyp.cls 3556
            ld a, #1A		; Hyp.cls 3557
            ret		; Hyp.cls 3558
fn_hyp_info_sb_bseld:		; Hyp.cls 3559
            ld hl, 0		; Hyp.cls 3560
            ret		; Hyp.cls 3561
fn_hyp_info_sb_bdma:		; Hyp.cls 3562
            ld d, b		; Hyp.cls 3563
            ld e, c		; Hyp.cls 3564
            ld c, 26		; Hyp.cls 3565
            jp fn_hyp_info_sb_start		; Hyp.cls 3566
fn_hyp_info_sb_bfail:		; Hyp.cls 3567
            ld a, 1		; Hyp.cls 3568
            ret		; Hyp.cls 3569
fn_hyp_info_sb_blstst:		; Hyp.cls 3570
            ld a, #FF		; Hyp.cls 3571
            ret		; Hyp.cls 3572
fn_hyp_info_sb_bsectr:		; Hyp.cls 3573
            ld h, b		; Hyp.cls 3574
            ld l, c		; Hyp.cls 3575
            ret		; Hyp.cls 3576
; a CPC data format disc's parameters (31) and allocation vector (27): 180 1K blocks, 64
; directory entries in the first two
fn_hyp_info_sb_dpbv:		; Hyp.cls 3579
            dw 36                               ; SPT: 128 byte records a track [3580]
            db 3, 7, 0                          ; BSH, BLM, EXM [3581]
            dw 179, 63                          ; DSM, DRM [3582]
            db #C0, 0                           ; AL0, AL1 [3583]
            dw 16, 0                            ; CKS, OFF [3584]
fn_hyp_info_sb_alvec:		; Hyp.cls 3585
            db #C0		; Hyp.cls 3586
            ds 22		; Hyp.cls 3587
; the start-up: the default FCBs (#005C, #006C) from the command tail (#0080), as the CCP
; makes them - "B:NAME.EXT", * as ?s - then the program at #0100
fn_hyp_info_sb_init:		; Hyp.cls 3590
            ld hl, #005C		; Hyp.cls 3591
            call fn_hyp_info_sb_iclr		; Hyp.cls 3592
            ld hl, #006C		; Hyp.cls 3593
            call fn_hyp_info_sb_iclr		; Hyp.cls 3594
            ld hl, #0081		; Hyp.cls 3595
            ld a, (#0080)		; Hyp.cls 3596
            ld b, a		; Hyp.cls 3597
            ld de, #005C		; Hyp.cls 3598
            call fn_hyp_info_sb_parse		; Hyp.cls 3599
            ld de, #006C		; Hyp.cls 3600
            call fn_hyp_info_sb_parse		; Hyp.cls 3601
            jp #0100		; Hyp.cls 3602
fn_hyp_info_sb_iclr:		; Hyp.cls 3603
            ld (hl), 0		; Hyp.cls 3604
            inc hl		; Hyp.cls 3605
            ld c, 11		; Hyp.cls 3606
fn_hyp_info_sb_ic_sp:		; Hyp.cls 3607
            ld (hl), ' '		; Hyp.cls 3608
            inc hl		; Hyp.cls 3609
            dec c		; Hyp.cls 3610
            jr nz, fn_hyp_info_sb_ic_sp		; Hyp.cls 3611
            ld c, 4		; Hyp.cls 3612
fn_hyp_info_sb_ic_z:		; Hyp.cls 3613
            ld (hl), 0		; Hyp.cls 3614
            inc hl		; Hyp.cls 3615
            dec c		; Hyp.cls 3616
            jr nz, fn_hyp_info_sb_ic_z		; Hyp.cls 3617
            ret		; Hyp.cls 3618
; sb_parse - HL = the tail, B = characters left; DE = an FCB: the next word into it
fn_hyp_info_sb_parse:		; Hyp.cls 3620
            ld a, b		; Hyp.cls 3621
            or a		; Hyp.cls 3622
            ret z		; Hyp.cls 3623
            ld a, (hl)		; Hyp.cls 3624
            cp ' '		; Hyp.cls 3625
            jr nz, fn_hyp_info_sb_p_word		; Hyp.cls 3626
            inc hl		; Hyp.cls 3627
            dec b		; Hyp.cls 3628
            jr fn_hyp_info_sb_parse		; Hyp.cls 3629
fn_hyp_info_sb_p_word:		; Hyp.cls 3630
            ld (fn_hyp_info_sb_pfcb), de		; Hyp.cls 3631
            ld a, b		; Hyp.cls 3632
            cp 2		; Hyp.cls 3633
            jr c, fn_hyp_info_sb_p_name		; Hyp.cls 3634
            inc hl		; Hyp.cls 3635
            ld a, (hl)		; Hyp.cls 3636
            dec hl		; Hyp.cls 3637
            cp ':'		; Hyp.cls 3638
            jr nz, fn_hyp_info_sb_p_name		; Hyp.cls 3639
            ld a, (hl)		; Hyp.cls 3640
            sub '@'		; Hyp.cls 3641
            ld (de), a                          ; its drive [3642]
            inc hl		; Hyp.cls 3643
            inc hl		; Hyp.cls 3644
            dec b		; Hyp.cls 3645
            dec b		; Hyp.cls 3646
fn_hyp_info_sb_p_name:		; Hyp.cls 3647
            inc de		; Hyp.cls 3648
            ld c, 8		; Hyp.cls 3649
            call fn_hyp_info_sb_pfield		; Hyp.cls 3650
            ld a, b		; Hyp.cls 3651
            or a		; Hyp.cls 3652
            ret z		; Hyp.cls 3653
            ld a, (hl)		; Hyp.cls 3654
            cp '.'		; Hyp.cls 3655
            jr nz, fn_hyp_info_sb_p_skip		; Hyp.cls 3656
            inc hl		; Hyp.cls 3657
            dec b		; Hyp.cls 3658
            ld de, (fn_hyp_info_sb_pfcb)		; Hyp.cls 3659
            ld a, e		; Hyp.cls 3660
            add a, 9		; Hyp.cls 3661
            ld e, a		; Hyp.cls 3662
            ld c, 3		; Hyp.cls 3663
            call fn_hyp_info_sb_pfield		; Hyp.cls 3664
fn_hyp_info_sb_p_skip:		; Hyp.cls 3665
            ld a, b                             ; the rest of the word [3666]
            or a		; Hyp.cls 3667
            ret z		; Hyp.cls 3668
            ld a, (hl)		; Hyp.cls 3669
            cp ' '		; Hyp.cls 3670
            ret z		; Hyp.cls 3671
            inc hl		; Hyp.cls 3672
            dec b		; Hyp.cls 3673
            jr fn_hyp_info_sb_p_skip		; Hyp.cls 3674
; sb_pfield - up to C characters into the field at DE, to a "." or a space; * fills it with ?
fn_hyp_info_sb_pfield:		; Hyp.cls 3676
            ld a, b		; Hyp.cls 3677
            or a		; Hyp.cls 3678
            ret z		; Hyp.cls 3679
            ld a, (hl)		; Hyp.cls 3680
            cp ' '		; Hyp.cls 3681
            ret z		; Hyp.cls 3682
            cp '.'		; Hyp.cls 3683
            ret z		; Hyp.cls 3684
            cp '*'		; Hyp.cls 3685
            jr z, fn_hyp_info_sb_pf_star		; Hyp.cls 3686
            inc c		; Hyp.cls 3687
            dec c		; Hyp.cls 3688
            jr z, fn_hyp_info_sb_pf_on                      ; (the field full: the extra left out) [3689]
            ld (de), a		; Hyp.cls 3690
            inc de		; Hyp.cls 3691
            dec c		; Hyp.cls 3692
fn_hyp_info_sb_pf_on:		; Hyp.cls 3693
            inc hl		; Hyp.cls 3694
            dec b		; Hyp.cls 3695
            jr fn_hyp_info_sb_pfield		; Hyp.cls 3696
fn_hyp_info_sb_pf_star:		; Hyp.cls 3697
            inc c		; Hyp.cls 3698
            dec c		; Hyp.cls 3699
            jr z, fn_hyp_info_sb_pf_on		; Hyp.cls 3700
            ld a, '?'		; Hyp.cls 3701
            ld (de), a		; Hyp.cls 3702
            inc de		; Hyp.cls 3703
            dec c		; Hyp.cls 3704
            jr fn_hyp_info_sb_pf_star		; Hyp.cls 3705
fn_hyp_info_sb_pfcb:    dw 0		; Hyp.cls 3706
fn_hyp_info_sb_end:		; Hyp.cls 3707
            ENT		; Hyp.cls 3708
            ASSERT fn_hyp_info_sb_end - fn_hyp_info_sb_start <= 62208 - 61184, "the bank stubs must fit below FONT"		; Hyp.cls 3709
            ASSERT fn_hyp_info_sb_end - fn_hyp_info_sb_start <= #340, "the stubs must leave a program's first stack (#F240-#F2FF) free"		; Hyp.cls 3710
    IFDEF NTC_MSXDOS		; Hyp.cls 3711
; The MSX's switch, both ways, in each bank's own page 3 below #FFFE (HISW): the mapper's pages
; change one port at a time, so the code doing it sits in the one page that changes last (hyp ->
; task) or not at all (task -> hyp). MSX-DOS 2 keeps #0038-#005B of the hypervisor's page 0 (its
; interrupt and slot code), so no #0044 glue there. Install copies this in and patches the
; immediates: the bank's own segments (pages 0-2) and the hypervisor's (msx_tpa).
; sb_hin: hyp -> task. Run maps the task's page 3 (out (#FF)), leaves ra / rclr / rhl in SWAP and
; jumps here: pages 0-2 to the task's, then sb_land.
; sb_hout: task -> hyp (the stubs' far call and interrupt): A and its carry into AF', pages 0-2
; to the hypervisor's, then its receiver msx_recv (Run's block) maps its page 3 and lands.
fn_hyp_info_hi_sw:		; Hyp.cls 3721
            DISP 65488		; Hyp.cls 3722
fn_hyp_info_sb_hin:		; Hyp.cls 3723
            ld a, 0                             ; (HISW + 1: the bank's page 0 segment) [3724]
            out (#FC), a		; Hyp.cls 3725
            ld a, 0                             ; (HISW + 5: page 1) [3726]
            out (#FD), a		; Hyp.cls 3727
            ld a, 0                             ; (HISW + 9: page 2) [3728]
            out (#FE), a		; Hyp.cls 3729
            ld a, (63185 + 2)		; Hyp.cls 3730
            ld e, a                             ; rclr -> E (for sb_land) [3731]
            ld hl, (63185 + 3)                 ; far-call result -> HL [3732]
            ld a, (63185 + 1)                  ; far-call result -> A [3733]
            jp fn_hyp_info_sb_land		; Hyp.cls 3734
fn_hyp_info_sb_hout:		; Hyp.cls 3735
            db #08                              ; ex af, af': A and the carry (far / interrupt) kept [3736]
            ld a, 0                             ; (HISW + 27: the hypervisor's page 0 segment) [3737]
            out (#FC), a		; Hyp.cls 3738
            ld a, 0                             ; (HISW + 31: page 1) [3739]
            out (#FD), a		; Hyp.cls 3740
            ld a, 0                             ; (HISW + 35: page 2) [3741]
            out (#FE), a		; Hyp.cls 3742
            jp msx_recv                         ; the hypervisor's pages 0-2: its receiver [3743]
fn_hyp_info_sb_hin_end:		; Hyp.cls 3744
            ENT		; Hyp.cls 3745
            ASSERT fn_hyp_info_sb_hout - fn_hyp_info_sb_hin == 25, "Install patches fn_hyp_info_sb_hin / fn_hyp_info_sb_hout at fixed offsets"		; Hyp.cls 3746
            ASSERT fn_hyp_info_sb_hin_end - fn_hyp_info_sb_hin <= #FFFE - 65488, "fn_hyp_info_sb_hin must fit below #FFFE"		; Hyp.cls 3747
fn_hyp_info_hi_swe:		; Hyp.cls 3748
    ENDIF		; Hyp.cls 3749
    IFDEF NTC_MSXDOS		; Hyp.cls 4364
; zxn: the SD card's code (sd_*: in FileShut's block, main RAM - this page code is full) reaches
; this block's names through these (a name with no colon is sjasmplus's, not the block's own)
@g_fl_peek: EQU asm_1_3817_n_fl_peek		; Hyp.cls 4367
@g_fl_poke: EQU asm_1_3817_n_fl_poke		; Hyp.cls 4368
@g_fl_toslot: EQU asm_1_3817_n_fl_toslot		; Hyp.cls 4369
@g_fl_fromslot: EQU asm_1_3817_n_fl_fromslot		; Hyp.cls 4370
@g_fl_ok: EQU asm_1_3817_n_fl_ok		; Hyp.cls 4371
@g_fp_done: EQU asm_1_3817_n_fp_done		; Hyp.cls 4372
@g_fp_sp: EQU asm_1_3817_n_fp_sp		; Hyp.cls 4373
@g_fl_done: EQU asm_1_3817_n_fl_done		; Hyp.cls 4374
@g_fl_srch: EQU asm_1_3817_n_fl_srch		; Hyp.cls 4375
@g_fl_uc_back: EQU asm_1_3817_n_fl_uc_back		; Hyp.cls 4376
@g_fl_uc_get: EQU asm_1_3817_n_fl_uc_get		; Hyp.cls 4377
@g_fl_inopen_a: EQU asm_1_3817_n_fl_inopen_a		; Hyp.cls 4378
@g_fl_rdrec_a: EQU asm_1_3817_n_fl_rdrec_a		; Hyp.cls 4379
@g_fl_rdrec: EQU asm_1_3817_n_fl_rdrec		; Hyp.cls 4380
@g_fl_bufa: dw var_hyp_filecall_buf                ; (where {buf} is: a dw, not an EQU - an EQU to a variable lags a pass) [4381]
@g_fl_arec: EQU asm_1_3817_n_fl_arec		; Hyp.cls 4382
@g_fl_aoff: EQU asm_1_3817_n_fl_aoff		; Hyp.cls 4383
@g_fl_aleft: EQU asm_1_3817_n_fl_aleft		; Hyp.cls 4384
@g_fl_inclose_a: EQU asm_1_3817_n_fl_inclose_a		; Hyp.cls 4385
@g_fl_arc_dir: EQU asm_1_3817_n_fl_arc_dir		; Hyp.cls 4386
@g_fl_mapa: EQU asm_1_3817_n_fl_mapa		; Hyp.cls 4387
@g_fl_name: EQU asm_1_3817_n_fl_name		; Hyp.cls 4388
@g_fl_n: EQU asm_1_3817_n_fl_n		; Hyp.cls 4389
@g_fl_cn: EQU asm_1_3817_n_fl_cn		; Hyp.cls 4390
@g_fl_cnt: EQU asm_1_3817_n_fl_cnt		; Hyp.cls 4391
@g_fl_at: EQU asm_1_3817_n_fl_at		; Hyp.cls 4392
@g_fl_res: EQU asm_1_3817_n_fl_res		; Hyp.cls 4393
@g_fl_slot: EQU asm_1_3817_n_fl_slot		; Hyp.cls 4394
@g_fl_outfcb: EQU asm_1_3817_n_fl_outfcb		; Hyp.cls 4395
@g_fl_outrec: EQU asm_1_3817_n_fl_outrec		; Hyp.cls 4396
@g_fl_yes: EQU asm_1_3817_n_fl_yes		; Hyp.cls 4397
@g_fl_sdf: EQU asm_1_3817_n_fl_sdf		; Hyp.cls 4398
@g_fl_exv: EQU asm_1_3817_n_fl_exv		; Hyp.cls 4399
@g_fl_cjf: EQU asm_1_3817_n_fl_cjf		; Hyp.cls 4400
@g_fl_name_s: EQU asm_1_3817_n_fl_name_s		; Hyp.cls 4401
@g_fl_new_s: EQU asm_1_3817_n_fl_new_s		; Hyp.cls 4402
@g_fl_inname: EQU asm_1_3817_n_fl_inname		; Hyp.cls 4403
@g_FL_UB: EQU asm_1_3817_n_FL_UB		; Hyp.cls 4404
@g_FL_MAP: EQU asm_1_3817_n_FL_MAP		; Hyp.cls 4405
@g_FL_EXK: EQU asm_1_3817_n_FL_EXK		; Hyp.cls 4406
@g_FL_CMAX: EQU asm_1_3817_n_FL_CMAX		; Hyp.cls 4407
    ENDIF		; Hyp.cls 4408
; ---- the page code: in the hypervisor's page (window data), called with it in the window
asm_1_3817_n_fp_start:		; Hyp.cls 4410
            ASSERT asm_1_3817_n_fp_start >= #5300, "FileCall's page code: after the disc buffers and the font"		; Hyp.cls 4411
asm_1_3817_n_fp_go:		; Hyp.cls 4412
            ld (asm_1_3817_n_fp_sp), sp		; Hyp.cls 4413
            ld a, (var_hyp_filecall_f)		; Hyp.cls 4414
            cp 15		; Hyp.cls 4415
            jp z, asm_1_3817_n_fl_open		; Hyp.cls 4416
            cp 16		; Hyp.cls 4417
            jp z, asm_1_3817_n_fl_close		; Hyp.cls 4418
            cp 19		; Hyp.cls 4419
            jp z, asm_1_3817_n_fl_del		; Hyp.cls 4420
            cp 23		; Hyp.cls 4421
            jp z, asm_1_3817_n_fl_ren		; Hyp.cls 4422
            cp 20		; Hyp.cls 4423
            jp z, asm_1_3817_n_fl_rdseq		; Hyp.cls 4424
            cp 33		; Hyp.cls 4425
            jp z, asm_1_3817_n_fl_rdran		; Hyp.cls 4426
            cp 21		; Hyp.cls 4427
            jp z, asm_1_3817_n_fl_write		; Hyp.cls 4428
            cp 34		; Hyp.cls 4429
            jp z, asm_1_3817_n_fl_write		; Hyp.cls 4430
            cp 22		; Hyp.cls 4431
            jp z, asm_1_3817_n_fl_make		; Hyp.cls 4432
            cp 17		; Hyp.cls 4433
            jp z, asm_1_3817_n_fl_srch1		; Hyp.cls 4434
            cp 18		; Hyp.cls 4435
            jp z, asm_1_3817_n_fl_srch		; Hyp.cls 4436
            cp 35		; Hyp.cls 4437
            jp z, asm_1_3817_n_fl_size		; Hyp.cls 4438
            cp 36		; Hyp.cls 4439
            jp z, asm_1_3817_n_fl_setran		; Hyp.cls 4440
            cp 100		; Hyp.cls 4441
            jp z, asm_1_3817_n_fl_hopen		; Hyp.cls 4442
            cp 101		; Hyp.cls 4443
            jp z, asm_1_3817_n_fl_hread		; Hyp.cls 4444
            cp 102		; Hyp.cls 4445
            jp z, asm_1_3817_n_fl_hclose		; Hyp.cls 4446
            cp 103		; Hyp.cls 4447
            jp z, asm_1_3817_n_fl_hload		; Hyp.cls 4448
            cp 30		; Hyp.cls 4449
            jp z, asm_1_3817_n_fl_unicall		; Hyp.cls 4450
            jp asm_1_3817_n_fp_done		; Hyp.cls 4451
; ---- the hypervisor's own reading (RUN, DIR, CD): 100 open the file named at fcb (dma
; characters, main RAM); 101 read dma bytes (128 at most) to buf: how many; 102 close; 103 the
; rest of it into the slot (setting) from address dma, fcb bytes at most: how many. Not while
; a slot reads a file (255)
asm_1_3817_n_fl_hopen:		; Hyp.cls 4456
            ld a, (var_hyp_fin)		; Hyp.cls 4457
            or a		; Hyp.cls 4458
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4459
            ld de, asm_1_3817_n_fl_name_s + 1		; Hyp.cls 4460
            ld hl, (var_hyp_filecall_fcb)          ; a name with no drive: the hypervisor's drive's path first [4461]
            ld bc, (var_hyp_filecall_dma)          ; when it has one (UniDOS: CD IDE: ...) [4462]
            ld a, ':'		; Hyp.cls 4463
            cpir		; Hyp.cls 4464
            jr z, asm_1_3817_n_fl_ho_nm		; Hyp.cls 4465
            ld a, (var_hyp_hdr)		; Hyp.cls 4466
            call asm_1_3817_n_fl_pfxm		; Hyp.cls 4467
asm_1_3817_n_fl_ho_nm:		; Hyp.cls 4468
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4469
            ld bc, (var_hyp_filecall_dma)		; Hyp.cls 4470
            ldir		; Hyp.cls 4471
            call asm_1_3817_n_fl_nlen		; Hyp.cls 4472
            call asm_1_3817_n_fl_inopen		; Hyp.cls 4473
            jr c, asm_1_3817_n_fl_ho_ok		; Hyp.cls 4474
            ld hl, asm_1_3817_n_fl_name_s        ; NAME.CYB not there: with UniDOS NAME.COM instead (RUN - a [4475]
            ld e, (hl)              ; .COM with no entry: UniDOS reads a file with no header to [4476]
            ld d, 0                 ; its real end) [4477]
            add hl, de		; Hyp.cls 4478
            ld a, (hl)		; Hyp.cls 4479
            cp 'B'		; Hyp.cls 4480
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4481
            ld (hl), 'M'		; Hyp.cls 4482
            dec hl		; Hyp.cls 4483
            ld a, (hl)		; Hyp.cls 4484
            cp 'Y'		; Hyp.cls 4485
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4486
            ld (hl), 'O'		; Hyp.cls 4487
    IFNDEF NTC_MSXDOS		; Hyp.cls 4488
            call asm_1_3817_n_fl_uni		; Hyp.cls 4489
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4490
    ENDIF		; Hyp.cls 4491
            call asm_1_3817_n_fl_inopen		; Hyp.cls 4492
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4493
            ld hl, (var_hyp_filecall_fcb)          ; (the caller's name too: NAME.COM) [4494]
            ld bc, (var_hyp_filecall_dma)		; Hyp.cls 4495
            add hl, bc		; Hyp.cls 4496
            dec hl		; Hyp.cls 4497
            ld (hl), 'M'		; Hyp.cls 4498
            dec hl		; Hyp.cls 4499
            ld (hl), 'O'		; Hyp.cls 4500
asm_1_3817_n_fl_ho_ok:		; Hyp.cls 4501
            ld a, 99                ; (99: the hypervisor's) [4502]
            ld (var_hyp_fin), a		; Hyp.cls 4503
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4504
asm_1_3817_n_fl_hread:		; Hyp.cls 4505
            ld a, (var_hyp_filecall_dma)		; Hyp.cls 4506
            ld (asm_1_3817_n_fl_n), a		; Hyp.cls 4507
            call asm_1_3817_n_fl_rdrec		; Hyp.cls 4508
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 4509
            jp asm_1_3817_n_fp_done		; Hyp.cls 4510
asm_1_3817_n_fl_hclose:		; Hyp.cls 4511
            ld a, (var_hyp_fin)		; Hyp.cls 4512
            cp 99		; Hyp.cls 4513
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4514
            call asm_1_3817_n_fl_inclose		; Hyp.cls 4515
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4516
asm_1_3817_n_fl_hload:		; Hyp.cls 4517
            ld hl, 0		; Hyp.cls 4518
            ld (asm_1_3817_n_fl_cnt), hl		; Hyp.cls 4519
            ld hl, (var_hyp_filecall_dma)		; Hyp.cls 4520
            ld (asm_1_3817_n_fl_at), hl		; Hyp.cls 4521
asm_1_3817_n_fl_hl_lp:		; Hyp.cls 4522
            ld hl, (var_hyp_filecall_fcb)          ; what is left to load (fcb bytes at most) [4523]
            ld de, (asm_1_3817_n_fl_cnt)		; Hyp.cls 4524
            or a		; Hyp.cls 4525
            sbc hl, de		; Hyp.cls 4526
            jr z, asm_1_3817_n_fl_hl_end		; Hyp.cls 4527
            ld a, h		; Hyp.cls 4528
            or a		; Hyp.cls 4529
            ld a, 128		; Hyp.cls 4530
            jr nz, asm_1_3817_n_fl_hl_n		; Hyp.cls 4531
            ld a, l		; Hyp.cls 4532
            cp 128		; Hyp.cls 4533
            jr c, asm_1_3817_n_fl_hl_n		; Hyp.cls 4534
            ld a, 128		; Hyp.cls 4535
asm_1_3817_n_fl_hl_n:		; Hyp.cls 4536
            ld (asm_1_3817_n_fl_n), a		; Hyp.cls 4537
            ld (asm_1_3817_n_fl_want), a		; Hyp.cls 4538
            call asm_1_3817_n_fl_rdrec           ; a record's worth into buf [4539]
            jr z, asm_1_3817_n_fl_hl_end		; Hyp.cls 4540
            ld b, a		; Hyp.cls 4541
            ld (asm_1_3817_n_fl_want + 1), a		; Hyp.cls 4542
            ld hl, (asm_1_3817_n_fl_cnt)		; Hyp.cls 4543
            ld e, a		; Hyp.cls 4544
            ld d, 0		; Hyp.cls 4545
            add hl, de		; Hyp.cls 4546
            ld (asm_1_3817_n_fl_cnt), hl		; Hyp.cls 4547
            ld hl, (asm_1_3817_n_fl_at)		; Hyp.cls 4548
            ld c, b		; Hyp.cls 4549
            ld b, 0		; Hyp.cls 4550
            call asm_1_3817_n_fl_fits		; Hyp.cls 4551
            jr c, asm_1_3817_n_fl_hl_slow		; Hyp.cls 4552
            push bc		; Hyp.cls 4553
            ld de, (var_hyp_filecall_buf)          ; in one page: one ldir [4554]
            call asm_1_3817_n_fl_toslot		; Hyp.cls 4555
            pop bc		; Hyp.cls 4556
            ld hl, (asm_1_3817_n_fl_at)		; Hyp.cls 4557
            add hl, bc		; Hyp.cls 4558
            jr asm_1_3817_n_fl_hl_put		; Hyp.cls 4559
asm_1_3817_n_fl_hl_slow:		; Hyp.cls 4560
            ld b, c		; Hyp.cls 4561
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 4562
asm_1_3817_n_fl_hl_cp:		; Hyp.cls 4563
            ld a, (de)              ; into the slot [4564]
            call asm_1_3817_n_fl_poke		; Hyp.cls 4565
            inc hl		; Hyp.cls 4566
            inc de		; Hyp.cls 4567
            djnz asm_1_3817_n_fl_hl_cp		; Hyp.cls 4568
asm_1_3817_n_fl_hl_put:		; Hyp.cls 4569
            ld (asm_1_3817_n_fl_at), hl		; Hyp.cls 4570
            ld a, (asm_1_3817_n_fl_want)		; Hyp.cls 4571
            ld b, a		; Hyp.cls 4572
            ld a, (asm_1_3817_n_fl_want + 1)		; Hyp.cls 4573
            cp b		; Hyp.cls 4574
            jr z, asm_1_3817_n_fl_hl_lp          ; a whole one: on [4575]
asm_1_3817_n_fl_hl_end:		; Hyp.cls 4576
            ld hl, (asm_1_3817_n_fl_cnt)		; Hyp.cls 4577
            ld (asm_1_3817_n_fl_res16), hl		; Hyp.cls 4578
            ld a, 1		; Hyp.cls 4579
            ld (asm_1_3817_n_fl_r16), a		; Hyp.cls 4580
            jp asm_1_3817_n_fp_done		; Hyp.cls 4581
; ---- 15: open (to read)
asm_1_3817_n_fl_open:		; Hyp.cls 4583
            ld a, (var_hyp_fin)		; Hyp.cls 4584
            or a		; Hyp.cls 4585
            jr z, asm_1_3817_n_fl_op_new		; Hyp.cls 4586
            ld b, a		; Hyp.cls 4587
            ld a, (asm_1_3817_n_fl_slot)		; Hyp.cls 4588
            cp b		; Hyp.cls 4589
            jp nz, asm_1_3817_n_fp_done          ; another slot's being read [4590]
            call asm_1_3817_n_fl_inclose         ; this slot's: CP/M needs no close after reading - this open [4591]
asm_1_3817_n_fl_op_new:                          ; replaces it (Exists opens and leaves it) [4592]
            call asm_1_3817_n_fl_name		; Hyp.cls 4593
            call asm_1_3817_n_fl_inopen		; Hyp.cls 4594
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4595
            ld hl, asm_1_3817_n_fl_name_s        ; kept, to open it again (33 going back) [4596]
            ld de, asm_1_3817_n_fl_inname		; Hyp.cls 4597
            ld bc, asm_1_3817_n_FL_NL		; Hyp.cls 4598
            ldir		; Hyp.cls 4599
            ld a, (asm_1_3817_n_fl_slot)		; Hyp.cls 4600
            ld (var_hyp_fin), a		; Hyp.cls 4601
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4602
            ld (asm_1_3817_n_fl_infcb), hl		; Hyp.cls 4603
            ld a, 1		; Hyp.cls 4604
            ld (asm_1_3817_n_fl_infcb + 2), a		; Hyp.cls 4605
            ld hl, 0		; Hyp.cls 4606
            ld (asm_1_3817_n_fl_inrec), hl		; Hyp.cls 4607
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4608
; ---- 22: make (a new file, to write)
asm_1_3817_n_fl_make:		; Hyp.cls 4610
    IFDEF NTC_MSXDOS		; Hyp.cls 4611
            jp sd_h_make            ; zxn: the SD card's (the boot archive is read only: 255) [4612]
    ENDIF		; Hyp.cls 4613
            ld a, (var_hyp_fout)		; Hyp.cls 4614
            or a		; Hyp.cls 4615
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4616
            call asm_1_3817_n_fl_name		; Hyp.cls 4617
            call asm_1_3817_n_fl_plain		; Hyp.cls 4618
            ld hl, asm_1_3817_n_fl_name_s + 1		; Hyp.cls 4619
            ld a, (asm_1_3817_n_fl_name_s)		; Hyp.cls 4620
            ld b, a		; Hyp.cls 4621
            ld de, #4800		; Hyp.cls 4622
            call #BC8C              ; CAS OUT OPEN [4623]
            di		; Hyp.cls 4624
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4625
            ld a, (asm_1_3817_n_fl_slot)		; Hyp.cls 4626
            ld (var_hyp_fout), a		; Hyp.cls 4627
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4628
            ld (asm_1_3817_n_fl_outfcb), hl		; Hyp.cls 4629
            ld a, 1		; Hyp.cls 4630
            ld (asm_1_3817_n_fl_outfcb + 2), a		; Hyp.cls 4631
            ld hl, 0		; Hyp.cls 4632
            ld (asm_1_3817_n_fl_outrec), hl		; Hyp.cls 4633
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4634
; ---- 16: close
asm_1_3817_n_fl_close:		; Hyp.cls 4636
            call asm_1_3817_n_fl_isin		; Hyp.cls 4637
            jr nz, asm_1_3817_n_fl_cl_out		; Hyp.cls 4638
            call asm_1_3817_n_fl_inclose		; Hyp.cls 4639
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4640
asm_1_3817_n_fl_cl_out:		; Hyp.cls 4641
            call asm_1_3817_n_fl_isout		; Hyp.cls 4642
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4643
            xor a		; Hyp.cls 4644
            ld (var_hyp_fout), a		; Hyp.cls 4645
    IFDEF NTC_MSXDOS		; Hyp.cls 4646
            jp sd_h_clout		; Hyp.cls 4647
    ELSE		; Hyp.cls 4648
            call asm_1_3817_n_fl_plain		; Hyp.cls 4649
            call #BC8F              ; CAS OUT CLOSE [4650]
            di		; Hyp.cls 4651
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4652
    ENDIF		; Hyp.cls 4653
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4654
; ---- 19: delete (|ERA, "name")
asm_1_3817_n_fl_del:		; Hyp.cls 4656
            call asm_1_3817_n_fl_name		; Hyp.cls 4657
    IFDEF NTC_MSXDOS		; Hyp.cls 4658
            jp sd_h_del             ; zxn: the SD card's (the boot archive is read only: 255) [4659]
    ENDIF		; Hyp.cls 4660
            call asm_1_3817_n_fl_plain		; Hyp.cls 4661
            ld hl, asm_1_3817_n_fl_name_s + 1		; Hyp.cls 4662
            ld (asm_1_3817_n_fl_desc + 1), hl		; Hyp.cls 4663
            ld a, (asm_1_3817_n_fl_name_s)		; Hyp.cls 4664
            ld (asm_1_3817_n_fl_desc), a		; Hyp.cls 4665
            ld hl, asm_1_3817_n_fl_yes           ; (UniDOS asks before it deletes a folder - all it holds too -, [4666]
            ld a, (hl)              ; a read-only or a hidden file: KM WAIT CHAR, its text unseen, [4667]
            ld (hl), 0              ; the VDU off. KM CHAR RETURN: the answer waiting for it - N, [4668]
            or a                    ; so a CP/M program's delete never takes a folder; Y only after [4669]
            ld a, 'N'               ; BDOS 30 op 8, RMDIR's, for its empty folder) [4670]
            jr z, asm_1_3817_n_fl_del_n		; Hyp.cls 4671
            ld a, 'Y'		; Hyp.cls 4672
asm_1_3817_n_fl_del_n:		; Hyp.cls 4673
            call #BB0C		; Hyp.cls 4674
            ld hl, asm_1_3817_n_fl_era           ; KL FIND COMMAND; KM READ CHAR after [4675]
            call #BCD4              ; takes the answer back when nothing asked [4676]
            di		; Hyp.cls 4677
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4678
            ld ix, asm_1_3817_n_fl_par		; Hyp.cls 4679
            ld a, 1                 ; one parameter: the string [4680]
            call #001B              ; KL FAR PCALL [4681]
            call #BB09              ; KM READ CHAR (interrupts: off again in fl_done) [4682]
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4683
; ---- 23: rename (the disc ROM's |REN, "new", "old"): the old name at FCB 0-11, the new
; at 16-27 (its drive 0: the old one's)
asm_1_3817_n_fl_ren:		; Hyp.cls 4686
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4687
            call asm_1_3817_n_fl_peek		; Hyp.cls 4688
            ld (asm_1_3817_n_fl_dfl), a		; Hyp.cls 4689
            ld de, 16		; Hyp.cls 4690
            add hl, de		; Hyp.cls 4691
            call asm_1_3817_n_fl_namehl          ; the new name [4692]
            xor a		; Hyp.cls 4693
            ld (asm_1_3817_n_fl_dfl), a		; Hyp.cls 4694
            ld hl, asm_1_3817_n_fl_name_s		; Hyp.cls 4695
            ld de, asm_1_3817_n_fl_new_s		; Hyp.cls 4696
            ld bc, asm_1_3817_n_FL_NL		; Hyp.cls 4697
            ldir		; Hyp.cls 4698
            call asm_1_3817_n_fl_name            ; the old one [4699]
    IFDEF NTC_MSXDOS		; Hyp.cls 4700
            jp sd_h_ren             ; zxn: the SD card's (the boot archive is read only: 255) [4701]
    ENDIF		; Hyp.cls 4702
            call asm_1_3817_n_fl_plain		; Hyp.cls 4703
            ld hl, asm_1_3817_n_fl_name_s + 1		; Hyp.cls 4704
            ld (asm_1_3817_n_fl_desc + 1), hl		; Hyp.cls 4705
            ld a, (asm_1_3817_n_fl_name_s)		; Hyp.cls 4706
            ld (asm_1_3817_n_fl_desc), a		; Hyp.cls 4707
            ld hl, asm_1_3817_n_fl_new_s + 1		; Hyp.cls 4708
            ld (asm_1_3817_n_fl_desc2 + 1), hl		; Hyp.cls 4709
            ld a, (asm_1_3817_n_fl_new_s)		; Hyp.cls 4710
            ld (asm_1_3817_n_fl_desc2), a		; Hyp.cls 4711
            ld hl, asm_1_3817_n_fl_rencmd		; Hyp.cls 4712
            call #BCD4              ; KL FIND COMMAND [4713]
            di		; Hyp.cls 4714
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4715
            ld ix, asm_1_3817_n_fl_par2          ; IX+0: the last parameter (the old name), IX+2: the new [4716]
            ld a, 2		; Hyp.cls 4717
            call #001B              ; KL FAR PCALL [4718]
            jp asm_1_3817_n_fl_ok              ; (interrupts: off again in fl_done) [4719]
; ---- 33: read record r0-r1: on to it (from the start again if it is behind)
asm_1_3817_n_fl_rdran:		; Hyp.cls 4721
            call asm_1_3817_n_fl_isin		; Hyp.cls 4722
            jp nz, asm_1_3817_n_fl_rdout		; Hyp.cls 4723
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4724
            ld de, 33		; Hyp.cls 4725
            add hl, de		; Hyp.cls 4726
            call asm_1_3817_n_fl_peek		; Hyp.cls 4727
            ld e, a		; Hyp.cls 4728
            inc hl		; Hyp.cls 4729
            call asm_1_3817_n_fl_peek		; Hyp.cls 4730
            ld d, a		; Hyp.cls 4731
            ld (asm_1_3817_n_fl_want), de		; Hyp.cls 4732
            ld hl, (asm_1_3817_n_fl_inrec)		; Hyp.cls 4733
            or a		; Hyp.cls 4734
            sbc hl, de		; Hyp.cls 4735
            jr c, asm_1_3817_n_fl_rr_on		; Hyp.cls 4736
            jr z, asm_1_3817_n_fl_rr_on		; Hyp.cls 4737
            call asm_1_3817_n_fl_inclose         ; behind: open it again [4738]
            ld hl, asm_1_3817_n_fl_inname		; Hyp.cls 4739
            ld de, asm_1_3817_n_fl_name_s		; Hyp.cls 4740
            ld bc, asm_1_3817_n_FL_NL		; Hyp.cls 4741
            ldir		; Hyp.cls 4742
            call asm_1_3817_n_fl_inopen		; Hyp.cls 4743
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4744
            ld a, (asm_1_3817_n_fl_slot)		; Hyp.cls 4745
            ld (var_hyp_fin), a		; Hyp.cls 4746
            ld hl, 0		; Hyp.cls 4747
            ld (asm_1_3817_n_fl_inrec), hl		; Hyp.cls 4748
asm_1_3817_n_fl_rr_on:		; Hyp.cls 4749
            ld hl, (asm_1_3817_n_fl_inrec)		; Hyp.cls 4750
            ld de, (asm_1_3817_n_fl_want)		; Hyp.cls 4751
            or a		; Hyp.cls 4752
            sbc hl, de		; Hyp.cls 4753
            jr nc, asm_1_3817_n_fl_rdseq		; Hyp.cls 4754
            call asm_1_3817_n_fl_rdrec		; Hyp.cls 4755
            jp z, asm_1_3817_n_fl_eof		; Hyp.cls 4756
            ld hl, (asm_1_3817_n_fl_inrec)		; Hyp.cls 4757
            inc hl		; Hyp.cls 4758
            ld (asm_1_3817_n_fl_inrec), hl		; Hyp.cls 4759
            jr asm_1_3817_n_fl_rr_on		; Hyp.cls 4760
; ---- 20: read the next record
asm_1_3817_n_fl_rdseq:		; Hyp.cls 4762
            call asm_1_3817_n_fl_isin		; Hyp.cls 4763
            jr nz, asm_1_3817_n_fl_rdout		; Hyp.cls 4764
            call asm_1_3817_n_fl_rdrec		; Hyp.cls 4765
            jr z, asm_1_3817_n_fl_eof		; Hyp.cls 4766
            ex de, hl		; Hyp.cls 4767
            ld hl, (asm_1_3817_n_fl_inrec)		; Hyp.cls 4768
            inc hl		; Hyp.cls 4769
            ld (asm_1_3817_n_fl_inrec), hl		; Hyp.cls 4770
            ex de, hl		; Hyp.cls 4771
            ld b, a                 ; the record padded with #1A [4772]
            ld a, 128		; Hyp.cls 4773
            sub b		; Hyp.cls 4774
            jr z, asm_1_3817_n_fl_rd_put		; Hyp.cls 4775
            ld b, a		; Hyp.cls 4776
            ld a, #1A		; Hyp.cls 4777
asm_1_3817_n_fl_rd_pad:		; Hyp.cls 4778
            ld (hl), a		; Hyp.cls 4779
            inc hl		; Hyp.cls 4780
            djnz asm_1_3817_n_fl_rd_pad		; Hyp.cls 4781
asm_1_3817_n_fl_rd_put:		; Hyp.cls 4782
            ld hl, (var_hyp_filecall_dma)          ; into the slot's DMA: in one page, one ldir [4783]
            ld bc, 128		; Hyp.cls 4784
            call asm_1_3817_n_fl_fits		; Hyp.cls 4785
            jr c, asm_1_3817_n_fl_rd_slow		; Hyp.cls 4786
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 4787
            call asm_1_3817_n_fl_toslot		; Hyp.cls 4788
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4789
asm_1_3817_n_fl_rd_slow:                         ; (across two pages: a byte at a time) [4790]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 4791
            ld de, (var_hyp_filecall_dma)		; Hyp.cls 4792
            ld b, 128		; Hyp.cls 4793
asm_1_3817_n_fl_rd_cp:		; Hyp.cls 4794
            ld a, (hl)		; Hyp.cls 4795
            ex de, hl		; Hyp.cls 4796
            call asm_1_3817_n_fl_poke		; Hyp.cls 4797
            ex de, hl		; Hyp.cls 4798
            inc hl		; Hyp.cls 4799
            inc de		; Hyp.cls 4800
            djnz asm_1_3817_n_fl_rd_cp		; Hyp.cls 4801
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4802
asm_1_3817_n_fl_rdout:		; Hyp.cls 4803
            call asm_1_3817_n_fl_isout           ; a file being written: nothing to read back [4804]
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4805
asm_1_3817_n_fl_eof:		; Hyp.cls 4806
            ld a, 1		; Hyp.cls 4807
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 4808
            jp asm_1_3817_n_fp_done		; Hyp.cls 4809
; ---- 21 / 34: write the next record
asm_1_3817_n_fl_write:		; Hyp.cls 4811
            call asm_1_3817_n_fl_isout		; Hyp.cls 4812
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4813
            ld hl, (var_hyp_filecall_dma)          ; the slot's DMA into buf [4814]
            ld bc, 128		; Hyp.cls 4815
            call asm_1_3817_n_fl_fits		; Hyp.cls 4816
            jr c, asm_1_3817_n_fl_wr_slow		; Hyp.cls 4817
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 4818
            call asm_1_3817_n_fl_fromslot		; Hyp.cls 4819
            jr asm_1_3817_n_fl_wr_got		; Hyp.cls 4820
asm_1_3817_n_fl_wr_slow:		; Hyp.cls 4821
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 4822
            ld b, 128		; Hyp.cls 4823
asm_1_3817_n_fl_wr_cp:		; Hyp.cls 4824
            call asm_1_3817_n_fl_peek		; Hyp.cls 4825
            ld (de), a		; Hyp.cls 4826
            inc hl		; Hyp.cls 4827
            inc de		; Hyp.cls 4828
            djnz asm_1_3817_n_fl_wr_cp		; Hyp.cls 4829
asm_1_3817_n_fl_wr_got:		; Hyp.cls 4830
    IFDEF NTC_MSXDOS		; Hyp.cls 4831
            jp sd_h_write           ; zxn: buf to the SD card's file [4832]
    ENDIF		; Hyp.cls 4833
            call asm_1_3817_n_fl_plain		; Hyp.cls 4834
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 4835
            ld b, 128		; Hyp.cls 4836
asm_1_3817_n_fl_wr_lp:		; Hyp.cls 4837
            ld a, (hl)		; Hyp.cls 4838
            push bc		; Hyp.cls 4839
            push hl		; Hyp.cls 4840
            call #BC95              ; CAS OUT CHAR [4841]
            di		; Hyp.cls 4842
            pop hl		; Hyp.cls 4843
            pop bc		; Hyp.cls 4844
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4845
            inc hl		; Hyp.cls 4846
            djnz asm_1_3817_n_fl_wr_lp		; Hyp.cls 4847
            ld hl, (asm_1_3817_n_fl_outrec)		; Hyp.cls 4848
            inc hl		; Hyp.cls 4849
            ld (asm_1_3817_n_fl_outrec), hl		; Hyp.cls 4850
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4851
; ---- 35: the file's size in records (r0-r2): counted, reading it through. The file this slot
; is reading is opened again after, at its record; another slot's being read: 255
asm_1_3817_n_fl_size:		; Hyp.cls 4854
            ld a, (var_hyp_fin)		; Hyp.cls 4855
            or a		; Hyp.cls 4856
            jr z, asm_1_3817_n_fl_sz_free		; Hyp.cls 4857
            ld b, a		; Hyp.cls 4858
            ld a, (asm_1_3817_n_fl_slot)		; Hyp.cls 4859
            cp b		; Hyp.cls 4860
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 4861
            call asm_1_3817_n_fl_inclose		; Hyp.cls 4862
            ld a, 1		; Hyp.cls 4863
asm_1_3817_n_fl_sz_free:		; Hyp.cls 4864
            ld (asm_1_3817_n_fl_had), a		; Hyp.cls 4865
            call asm_1_3817_n_fl_name		; Hyp.cls 4866
            call asm_1_3817_n_fl_inopen		; Hyp.cls 4867
            jr nc, asm_1_3817_n_fl_sz_back		; Hyp.cls 4868
            ld hl, 0		; Hyp.cls 4869
            ld (asm_1_3817_n_fl_cnt), hl		; Hyp.cls 4870
asm_1_3817_n_fl_sz_lp:		; Hyp.cls 4871
            call asm_1_3817_n_fl_rdrec		; Hyp.cls 4872
            jr z, asm_1_3817_n_fl_sz_end		; Hyp.cls 4873
            ld hl, (asm_1_3817_n_fl_cnt)		; Hyp.cls 4874
            inc hl		; Hyp.cls 4875
            ld (asm_1_3817_n_fl_cnt), hl		; Hyp.cls 4876
            cp 128		; Hyp.cls 4877
            jr z, asm_1_3817_n_fl_sz_lp		; Hyp.cls 4878
asm_1_3817_n_fl_sz_end:		; Hyp.cls 4879
            call asm_1_3817_n_fl_inclose		; Hyp.cls 4880
            ld hl, (asm_1_3817_n_fl_cnt)		; Hyp.cls 4881
            call asm_1_3817_n_fl_ranput		; Hyp.cls 4882
            xor a		; Hyp.cls 4883
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 4884
asm_1_3817_n_fl_sz_back:		; Hyp.cls 4885
            ld a, (asm_1_3817_n_fl_had)		; Hyp.cls 4886
            or a		; Hyp.cls 4887
            jp z, asm_1_3817_n_fp_done		; Hyp.cls 4888
            ld hl, asm_1_3817_n_fl_inname        ; the slot's read file again, on to its record [4889]
            ld de, asm_1_3817_n_fl_name_s		; Hyp.cls 4890
            ld bc, asm_1_3817_n_FL_NL		; Hyp.cls 4891
            ldir		; Hyp.cls 4892
            call asm_1_3817_n_fl_inopen		; Hyp.cls 4893
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 4894
            ld a, (asm_1_3817_n_fl_slot)		; Hyp.cls 4895
            ld (var_hyp_fin), a		; Hyp.cls 4896
            ld hl, (asm_1_3817_n_fl_inrec)		; Hyp.cls 4897
asm_1_3817_n_fl_sz_skip:		; Hyp.cls 4898
            ld a, h		; Hyp.cls 4899
            or l		; Hyp.cls 4900
            jp z, asm_1_3817_n_fp_done		; Hyp.cls 4901
            push hl		; Hyp.cls 4902
            call asm_1_3817_n_fl_rdrec		; Hyp.cls 4903
            pop hl		; Hyp.cls 4904
            dec hl		; Hyp.cls 4905
            jr asm_1_3817_n_fl_sz_skip		; Hyp.cls 4906
    IFDEF NTC_MSXDOS		; Hyp.cls 4907
; zxn: #5B00-#5CFF kept as scratch - the 48K ROM and the DOS keep their system variables there
; (BANKM #5B5C, BANK678 #5B67; the interrupt handler's KSTATE, LAST_K, FLAGS, FRAMES at #5C00-
; #5C7B), and this page is in the window during an esxDOS call (sd_x)
            ASSERT $ <= #5B00, "the page code up to asm_1_3817_n_fl_setran must end below #5B00 (asm_1_3817_n_fl_sysv)"		; Hyp.cls 4911
            ds #5B00 - $		; Hyp.cls 4912
asm_1_3817_n_fl_sysv:    ds #200		; Hyp.cls 4913
    ENDIF		; Hyp.cls 4914
; ---- 36: set the random record (r0-r2) from where the file is: the next record read or
; written; a file not open here: from the FCB's extent and record (ex * 128 + cr)
asm_1_3817_n_fl_setran:		; Hyp.cls 4917
            call asm_1_3817_n_fl_isin		; Hyp.cls 4918
            ld hl, (asm_1_3817_n_fl_inrec)		; Hyp.cls 4919
            jr z, asm_1_3817_n_fl_sr_put		; Hyp.cls 4920
            call asm_1_3817_n_fl_isout		; Hyp.cls 4921
            ld hl, (asm_1_3817_n_fl_outrec)		; Hyp.cls 4922
            jr z, asm_1_3817_n_fl_sr_put		; Hyp.cls 4923
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4924
            ld de, 32		; Hyp.cls 4925
            add hl, de		; Hyp.cls 4926
            call asm_1_3817_n_fl_peek            ; cr [4927]
            ld e, a		; Hyp.cls 4928
            ld bc, -20		; Hyp.cls 4929
            add hl, bc		; Hyp.cls 4930
            call asm_1_3817_n_fl_peek            ; ex [4931]
            ld h, a		; Hyp.cls 4932
            srl h		; Hyp.cls 4933
            ld a, e		; Hyp.cls 4934
            jr nc, asm_1_3817_n_fl_sr_lo		; Hyp.cls 4935
            or #80		; Hyp.cls 4936
asm_1_3817_n_fl_sr_lo:		; Hyp.cls 4937
            ld l, a		; Hyp.cls 4938
asm_1_3817_n_fl_sr_put:		; Hyp.cls 4939
            call asm_1_3817_n_fl_ranput		; Hyp.cls 4940
            jp asm_1_3817_n_fl_ok		; Hyp.cls 4941
; ---- 17 / 18: search the folder (UniDOS: the FCB's drive's, else the slot's) for BDOS 17's
; name ("?" any character; kept at SRCH in the bank, SRCH + 12 the entries passed - 18 goes on
; from there): the next one, as a CP/M directory entry at the DMA (its record count from its
; length, 128 at most). 17 examines the folder (Ctrl J) into the hypervisor's page (#6000-#7BFF:
; 112 entries at most), then 17 and 18 look there. No UniDOS (or an AMSDOS floppy): none (255)
asm_1_3817_n_fl_srch1:		; Hyp.cls 4947
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4948
            ld de, 63216		; Hyp.cls 4949
            ld b, 12		; Hyp.cls 4950
asm_1_3817_n_fl_s1_lp:		; Hyp.cls 4951
            call asm_1_3817_n_fl_peek		; Hyp.cls 4952
            ex de, hl		; Hyp.cls 4953
            call asm_1_3817_n_fl_poke		; Hyp.cls 4954
            ex de, hl		; Hyp.cls 4955
            inc hl		; Hyp.cls 4956
            inc de		; Hyp.cls 4957
            djnz asm_1_3817_n_fl_s1_lp		; Hyp.cls 4958
            ex de, hl		; Hyp.cls 4959
            xor a		; Hyp.cls 4960
            call asm_1_3817_n_fl_poke            ; none passed [4961]
            xor a		; Hyp.cls 4962
            ld (asm_1_3817_n_fl_cn), a		; Hyp.cls 4963
            ld hl, #6000		; Hyp.cls 4964
            ld (asm_1_3817_n_fl_at), hl		; Hyp.cls 4965
            ld de, asm_1_3817_n_fl_name_s + 1    ; "B:" (or B's path) [4966]
            ld hl, 63216		; Hyp.cls 4967
            call asm_1_3817_n_fl_peek		; Hyp.cls 4968
            or a		; Hyp.cls 4969
            jr z, asm_1_3817_n_fl_s_own		; Hyp.cls 4970
            add a, 64		; Hyp.cls 4971
            jr asm_1_3817_n_fl_s_drv		; Hyp.cls 4972
asm_1_3817_n_fl_s_own:		; Hyp.cls 4973
            ld a, (var_hyp_filecall_drive)		; Hyp.cls 4974
            or a		; Hyp.cls 4975
            jr z, asm_1_3817_n_fl_s_nod		; Hyp.cls 4976
asm_1_3817_n_fl_s_drv:		; Hyp.cls 4977
            call asm_1_3817_n_fl_pfx		; Hyp.cls 4978
asm_1_3817_n_fl_s_nod:		; Hyp.cls 4979
    IFDEF NTC_MSXDOS		; Hyp.cls 4980
            jp sd_h_srch1           ; zxn: the folder (the SD card's, else the boot archive's) into the cache [4981]
    ENDIF		; Hyp.cls 4982
; UniDOS: the directory itself (Ctrl J examine), its files into the cache - no file opened (so
; not held up by another slot's reading)
    IFNDEF NTC_MSXDOS		; Hyp.cls 4985
            push de		; Hyp.cls 4986
            call asm_1_3817_n_fl_exdir		; Hyp.cls 4987
            pop de		; Hyp.cls 4988
            jp nz, asm_1_3817_n_fp_done          ; (none to list: no UniDOS, an AMSDOS floppy - 255) [4989]
asm_1_3817_n_fl_sx_lp:		; Hyp.cls 4990
            ld hl, (asm_1_3817_n_fl_at)		; Hyp.cls 4991
            inc hl                  ; (the name straight into the entry) [4992]
            ld ix, asm_1_3817_n_FL_DATE		; Hyp.cls 4993
            ld c, 13                ; examine next [4994]
            call asm_1_3817_n_fl_cjc		; Hyp.cls 4995
            jr nc, asm_1_3817_n_fl_sx_end		; Hyp.cls 4996
            jr nz, asm_1_3817_n_fl_sx_end		; Hyp.cls 4997
            bit 4, a		; Hyp.cls 4998
            jr nz, asm_1_3817_n_fl_sx_lp         ; (a folder: not for CP/M) [4999]
            ld hl, (asm_1_3817_n_fl_at)		; Hyp.cls 5000
            ld (hl), 1              ; in use [5001]
            ld a, b		; Hyp.cls 5002
            or c		; Hyp.cls 5003
            jr z, asm_1_3817_n_fl_sx_sz		; Hyp.cls 5004
            ld de, #FFFF            ; (64K or more) [5005]
asm_1_3817_n_fl_sx_sz:		; Hyp.cls 5006
            ld bc, 12		; Hyp.cls 5007
            add hl, bc		; Hyp.cls 5008
            ld (hl), b              ; kind, flags 0 [5009]
            inc hl		; Hyp.cls 5010
            ld (hl), b		; Hyp.cls 5011
            inc hl		; Hyp.cls 5012
            ld (hl), e              ; its length [5013]
            inc hl		; Hyp.cls 5014
            ld (hl), d		; Hyp.cls 5015
            ld hl, (asm_1_3817_n_fl_at)		; Hyp.cls 5016
            ld bc, 64		; Hyp.cls 5017
            add hl, bc		; Hyp.cls 5018
            ld (asm_1_3817_n_fl_at), hl		; Hyp.cls 5019
            ld hl, asm_1_3817_n_fl_cn		; Hyp.cls 5020
            inc (hl)		; Hyp.cls 5021
            ld a, (hl)		; Hyp.cls 5022
            cp asm_1_3817_n_FL_CMAX		; Hyp.cls 5023
            jr c, asm_1_3817_n_fl_sx_lp		; Hyp.cls 5024
asm_1_3817_n_fl_sx_end:		; Hyp.cls 5025
            jp asm_1_3817_n_fl_srch		; Hyp.cls 5026
    ENDIF		; Hyp.cls 5027
    IFDEF NTC_MSXDOS		; Hyp.cls 5028
; fl_arc_dir - the archive's entries into the search's cache (#6000: 64 bytes each - 1, the name
; 8 + 3, 0, 0, the length as a word; FL_CMAX at most): fl_cn how many, for fl_srch (17 / 18)
asm_1_3817_n_fl_arc_dir:		; Hyp.cls 5031
            xor a		; Hyp.cls 5032
            ld (asm_1_3817_n_fl_cn), a		; Hyp.cls 5033
            ld hl, #6000		; Hyp.cls 5034
            ld (asm_1_3817_n_fl_at), hl		; Hyp.cls 5035
            ld hl, 0		; Hyp.cls 5036
            call asm_1_3817_n_fl_arc_pg          ; the directory: HL = #C000 [5037]
            ld de, 4		; Hyp.cls 5038
            add hl, de		; Hyp.cls 5039
            ld e, (hl)		; Hyp.cls 5040
            inc hl		; Hyp.cls 5041
            ld d, (hl)              ; DE = the entries [5042]
            ld bc, 0                ; BC = this entry [5043]
asm_1_3817_n_fl_ad_lp:		; Hyp.cls 5044
            ld a, c		; Hyp.cls 5045
            cp e		; Hyp.cls 5046
            ld a, b		; Hyp.cls 5047
            sbc a, d		; Hyp.cls 5048
            jr nc, asm_1_3817_n_fl_ad_end		; Hyp.cls 5049
            ld a, (asm_1_3817_n_fl_cn)		; Hyp.cls 5050
            cp asm_1_3817_n_FL_CMAX		; Hyp.cls 5051
            jr nc, asm_1_3817_n_fl_ad_end		; Hyp.cls 5052
            push bc		; Hyp.cls 5053
            push de		; Hyp.cls 5054
            inc bc                  ; the entry's record: (n + 1) / 8, in it ((n + 1) and 7) * 16 [5055]
            ld h, b		; Hyp.cls 5056
            ld l, c		; Hyp.cls 5057
            srl h		; Hyp.cls 5058
            rr l		; Hyp.cls 5059
            srl h		; Hyp.cls 5060
            rr l		; Hyp.cls 5061
            srl h		; Hyp.cls 5062
            rr l		; Hyp.cls 5063
            call asm_1_3817_n_fl_arc_pg		; Hyp.cls 5064
            ld a, c		; Hyp.cls 5065
            and 7		; Hyp.cls 5066
            add a, a		; Hyp.cls 5067
            add a, a		; Hyp.cls 5068
            add a, a		; Hyp.cls 5069
            add a, a		; Hyp.cls 5070
            add a, l		; Hyp.cls 5071
            ld l, a		; Hyp.cls 5072
            ld de, (asm_1_3817_n_fl_at)		; Hyp.cls 5073
            ld a, 1		; Hyp.cls 5074
            ld (de), a              ; in use [5075]
            inc de		; Hyp.cls 5076
            ld bc, 11		; Hyp.cls 5077
            ldir                    ; the name [5078]
            ex de, hl		; Hyp.cls 5079
            ld (hl), 0              ; kind, flags [5080]
            inc hl		; Hyp.cls 5081
            ld (hl), 0		; Hyp.cls 5082
            inc hl		; Hyp.cls 5083
            ex de, hl		; Hyp.cls 5084
            ld a, (hl)              ; the length: a word (65535 from 64K) [5085]
            inc hl		; Hyp.cls 5086
            ld c, (hl)		; Hyp.cls 5087
            inc hl		; Hyp.cls 5088
            ld b, (hl)		; Hyp.cls 5089
            ld l, a		; Hyp.cls 5090
            ld h, c		; Hyp.cls 5091
            ld a, b		; Hyp.cls 5092
            or a		; Hyp.cls 5093
            jr z, asm_1_3817_n_fl_ad_ln		; Hyp.cls 5094
            ld hl, 65535		; Hyp.cls 5095
asm_1_3817_n_fl_ad_ln:		; Hyp.cls 5096
            ex de, hl		; Hyp.cls 5097
            ld (hl), e		; Hyp.cls 5098
            inc hl		; Hyp.cls 5099
            ld (hl), d		; Hyp.cls 5100
            ld hl, (asm_1_3817_n_fl_at)		; Hyp.cls 5101
            ld bc, 64		; Hyp.cls 5102
            add hl, bc		; Hyp.cls 5103
            ld (asm_1_3817_n_fl_at), hl		; Hyp.cls 5104
            ld hl, asm_1_3817_n_fl_cn		; Hyp.cls 5105
            inc (hl)		; Hyp.cls 5106
            pop de		; Hyp.cls 5107
            pop bc		; Hyp.cls 5108
            inc bc		; Hyp.cls 5109
            jr asm_1_3817_n_fl_ad_lp		; Hyp.cls 5110
asm_1_3817_n_fl_ad_end:		; Hyp.cls 5111
            jp asm_1_3817_n_fl_arc_off		; Hyp.cls 5112
    ENDIF		; Hyp.cls 5113
asm_1_3817_n_fl_srch:		; Hyp.cls 5114
            ld hl, 63216 + 12		; Hyp.cls 5115
            call asm_1_3817_n_fl_peek		; Hyp.cls 5116
            ld (asm_1_3817_n_fl_skip), a		; Hyp.cls 5117
            xor a		; Hyp.cls 5118
            ld (asm_1_3817_n_fl_k), a		; Hyp.cls 5119
asm_1_3817_n_fl_s_lp:		; Hyp.cls 5120
            ld a, (asm_1_3817_n_fl_cn)           ; the next entry, from the cache [5121]
            ld b, a		; Hyp.cls 5122
            ld a, (asm_1_3817_n_fl_k)		; Hyp.cls 5123
            cp b		; Hyp.cls 5124
            jp nc, asm_1_3817_n_fp_done          ; (none: 255) [5125]
            ld l, a		; Hyp.cls 5126
            ld h, 0		; Hyp.cls 5127
            add hl, hl		; Hyp.cls 5128
            add hl, hl		; Hyp.cls 5129
            add hl, hl		; Hyp.cls 5130
            add hl, hl		; Hyp.cls 5131
            add hl, hl		; Hyp.cls 5132
            add hl, hl		; Hyp.cls 5133
            ld de, #6000		; Hyp.cls 5134
            add hl, de		; Hyp.cls 5135
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 5136
            ld bc, 64		; Hyp.cls 5137
            ldir		; Hyp.cls 5138
            ld hl, asm_1_3817_n_fl_k		; Hyp.cls 5139
            inc (hl)		; Hyp.cls 5140
            ld a, (asm_1_3817_n_fl_skip)		; Hyp.cls 5141
            cp (hl)		; Hyp.cls 5142
            jr nc, asm_1_3817_n_fl_s_lp          ; passed already [5143]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 5144
            ld a, (hl)		; Hyp.cls 5145
            dec a		; Hyp.cls 5146
            jr nz, asm_1_3817_n_fl_s_lp          ; not in use (1) [5147]
            inc hl		; Hyp.cls 5148
            ld de, 63216 + 1		; Hyp.cls 5149
            ld b, 11		; Hyp.cls 5150
asm_1_3817_n_fl_s_cmp:		; Hyp.cls 5151
            ex de, hl		; Hyp.cls 5152
            call asm_1_3817_n_fl_peek		; Hyp.cls 5153
            ex de, hl		; Hyp.cls 5154
            and #7F		; Hyp.cls 5155
            cp '?'		; Hyp.cls 5156
            jr z, asm_1_3817_n_fl_s_any		; Hyp.cls 5157
            ld c, a		; Hyp.cls 5158
            ld a, (hl)		; Hyp.cls 5159
            and #7F		; Hyp.cls 5160
            cp c		; Hyp.cls 5161
            jr nz, asm_1_3817_n_fl_s_lp		; Hyp.cls 5162
asm_1_3817_n_fl_s_any:		; Hyp.cls 5163
            inc hl		; Hyp.cls 5164
            inc de		; Hyp.cls 5165
            djnz asm_1_3817_n_fl_s_cmp		; Hyp.cls 5166
            ld hl, (var_hyp_filecall_buf)          ; the entry: user 0, the name, extent 0, the records, no blocks [5167]
            ld (hl), 0		; Hyp.cls 5168
            ld de, 14		; Hyp.cls 5169
            add hl, de		; Hyp.cls 5170
            ld e, (hl)		; Hyp.cls 5171
            inc hl		; Hyp.cls 5172
            ld d, (hl)		; Hyp.cls 5173
            ex de, hl		; Hyp.cls 5174
            ld bc, 127		; Hyp.cls 5175
            add hl, bc		; Hyp.cls 5176
            jr c, asm_1_3817_n_fl_s_big		; Hyp.cls 5177
            ld a, h		; Hyp.cls 5178
            cp #40		; Hyp.cls 5179
            jr nc, asm_1_3817_n_fl_s_big		; Hyp.cls 5180
            sla l		; Hyp.cls 5181
            rla		; Hyp.cls 5182
            jr asm_1_3817_n_fl_s_rc		; Hyp.cls 5183
asm_1_3817_n_fl_s_big:		; Hyp.cls 5184
            ld a, 128		; Hyp.cls 5185
asm_1_3817_n_fl_s_rc:		; Hyp.cls 5186
            ex de, hl		; Hyp.cls 5187
            ld (hl), a		; Hyp.cls 5188
            ld b, 3		; Hyp.cls 5189
asm_1_3817_n_fl_s_z1:		; Hyp.cls 5190
            dec hl		; Hyp.cls 5191
            ld (hl), 0		; Hyp.cls 5192
            djnz asm_1_3817_n_fl_s_z1		; Hyp.cls 5193
            ld de, 4		; Hyp.cls 5194
            add hl, de		; Hyp.cls 5195
            ld b, 16		; Hyp.cls 5196
asm_1_3817_n_fl_s_z2:		; Hyp.cls 5197
            ld (hl), 0		; Hyp.cls 5198
            inc hl		; Hyp.cls 5199
            djnz asm_1_3817_n_fl_s_z2		; Hyp.cls 5200
            ld hl, (var_hyp_filecall_dma)		; Hyp.cls 5201
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 5202
            ld b, 32		; Hyp.cls 5203
asm_1_3817_n_fl_s_put:		; Hyp.cls 5204
            ld a, (de)		; Hyp.cls 5205
            call asm_1_3817_n_fl_poke		; Hyp.cls 5206
            inc hl		; Hyp.cls 5207
            inc de		; Hyp.cls 5208
            djnz asm_1_3817_n_fl_s_put		; Hyp.cls 5209
            ld hl, 63216 + 12		; Hyp.cls 5210
            ld a, (asm_1_3817_n_fl_k)		; Hyp.cls 5211
            call asm_1_3817_n_fl_poke		; Hyp.cls 5212
            jp asm_1_3817_n_fl_ok		; Hyp.cls 5213
asm_1_3817_n_fl_skip:    db 0		; Hyp.cls 5214
asm_1_3817_n_fl_k:       db 0		; Hyp.cls 5215
asm_1_3817_n_fl_cn:      db 0                    ; the folder's entries in the cache (#6000) [5216]
asm_1_3817_n_fl_ranput:                          ; the FCB's r0-r2 = HL [5217]
            ex de, hl		; Hyp.cls 5218
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 5219
            ld bc, 33		; Hyp.cls 5220
            add hl, bc		; Hyp.cls 5221
            ld a, e		; Hyp.cls 5222
            call asm_1_3817_n_fl_poke		; Hyp.cls 5223
            inc hl		; Hyp.cls 5224
            ld a, d		; Hyp.cls 5225
            call asm_1_3817_n_fl_poke		; Hyp.cls 5226
            inc hl		; Hyp.cls 5227
            xor a		; Hyp.cls 5228
            jp asm_1_3817_n_fl_poke		; Hyp.cls 5229
; ---- the parts
    IFNDEF NTC_MSXDOS		; Hyp.cls 5231
asm_1_3817_n_fl_inopen:                          ; open fl_name_s to read: carry = done [5232]
            call asm_1_3817_n_fl_plain		; Hyp.cls 5233
            ld hl, asm_1_3817_n_fl_name_s + 1		; Hyp.cls 5234
            ld a, (asm_1_3817_n_fl_name_s)		; Hyp.cls 5235
            ld b, a		; Hyp.cls 5236
            ld de, #4000		; Hyp.cls 5237
            call #BC77              ; CAS IN OPEN [5238]
            di		; Hyp.cls 5239
            ld (asm_1_3817_n_fl_hdr), hl         ; (its header: BDOS 30 #C7) [5240]
            ret		; Hyp.cls 5241
asm_1_3817_n_fl_inclose:		; Hyp.cls 5242
            xor a		; Hyp.cls 5243
            ld (var_hyp_fin), a		; Hyp.cls 5244
            call asm_1_3817_n_fl_plain		; Hyp.cls 5245
            call #BC7A              ; CAS IN CLOSE [5246]
            di		; Hyp.cls 5247
            ret		; Hyp.cls 5248
asm_1_3817_n_fl_rdrec:                           ; read up to fl_n bytes (128) into buf: A = how many (Z [5249]
            call asm_1_3817_n_fl_plain           ; none), HL past them. A #1A is a byte (the soft end of file) [5250]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 5251
            ld a, (asm_1_3817_n_fl_n)		; Hyp.cls 5252
            ld b, a		; Hyp.cls 5253
asm_1_3817_n_fl_rr_lp:		; Hyp.cls 5254
            push bc		; Hyp.cls 5255
            push hl		; Hyp.cls 5256
            call #BC80              ; CAS IN CHAR [5257]
            di		; Hyp.cls 5258
            pop hl		; Hyp.cls 5259
            pop bc		; Hyp.cls 5260
            jr c, asm_1_3817_n_fl_rr_b		; Hyp.cls 5261
            cp #1A		; Hyp.cls 5262
            jr nz, asm_1_3817_n_fl_rr_end		; Hyp.cls 5263
asm_1_3817_n_fl_rr_b:		; Hyp.cls 5264
            ld (hl), a		; Hyp.cls 5265
            inc hl		; Hyp.cls 5266
            djnz asm_1_3817_n_fl_rr_lp		; Hyp.cls 5267
asm_1_3817_n_fl_rr_end:		; Hyp.cls 5268
            ld a, (asm_1_3817_n_fl_n)		; Hyp.cls 5269
            sub b		; Hyp.cls 5270
            ld c, a		; Hyp.cls 5271
            ld a, 128		; Hyp.cls 5272
            ld (asm_1_3817_n_fl_n), a            ; (128 again for the next) [5273]
            ld a, c		; Hyp.cls 5274
            or a		; Hyp.cls 5275
            ret		; Hyp.cls 5276
    ENDIF		; Hyp.cls 5277
asm_1_3817_n_fl_fits:                            ; HL = a slot address, BC = bytes: NC = all in its 16K page. [5278]
            push hl                 ; Keeps BC, DE, HL [5279]
            ld a, h		; Hyp.cls 5280
            and #3F		; Hyp.cls 5281
            ld h, a		; Hyp.cls 5282
            add hl, bc		; Hyp.cls 5283
            ld a, h		; Hyp.cls 5284
            cp #40		; Hyp.cls 5285
            jr c, asm_1_3817_n_fl_ft_ok		; Hyp.cls 5286
            jr nz, asm_1_3817_n_fl_ft_no		; Hyp.cls 5287
            ld a, l		; Hyp.cls 5288
            or a		; Hyp.cls 5289
            jr nz, asm_1_3817_n_fl_ft_no		; Hyp.cls 5290
asm_1_3817_n_fl_ft_ok:		; Hyp.cls 5291
            pop hl		; Hyp.cls 5292
            or a		; Hyp.cls 5293
            ret		; Hyp.cls 5294
asm_1_3817_n_fl_ft_no:		; Hyp.cls 5295
            pop hl		; Hyp.cls 5296
            scf		; Hyp.cls 5297
            ret		; Hyp.cls 5298
asm_1_3817_n_fl_plain:                           ; the hypervisor's page in the window (the buffers) [5299]
            ld bc, (var_hyp_hps)		; Hyp.cls 5300
    IFDEF NTC_MSXDOS		; Hyp.cls 5301
            call msx_win		; Hyp.cls 5302
    ELSE		; Hyp.cls 5303
            out (c), c		; Hyp.cls 5304
    ENDIF		; Hyp.cls 5305
            ret		; Hyp.cls 5306
asm_1_3817_n_fl_name:                            ; fl_name_s = the FCB's file: length, "B:NAME.EXT" [5307]
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 5308
asm_1_3817_n_fl_namehl:                          ; (HL = an FCB in the slot) [5309]
            ld de, asm_1_3817_n_fl_name_s + 1		; Hyp.cls 5310
            call asm_1_3817_n_fl_peek            ; its drive: 0 = the slot's (or fl_dfl's) [5311]
            or a		; Hyp.cls 5312
            jr nz, asm_1_3817_n_fl_nm_d		; Hyp.cls 5313
            ld a, (asm_1_3817_n_fl_dfl)		; Hyp.cls 5314
            or a		; Hyp.cls 5315
            jr nz, asm_1_3817_n_fl_nm_d		; Hyp.cls 5316
            ld a, (var_hyp_filecall_drive)		; Hyp.cls 5317
            or a		; Hyp.cls 5318
            jr z, asm_1_3817_n_fl_nm_nod		; Hyp.cls 5319
            sub 64		; Hyp.cls 5320
asm_1_3817_n_fl_nm_d:		; Hyp.cls 5321
            add a, 64		; Hyp.cls 5322
            call asm_1_3817_n_fl_pfx             ; "B:", or B's path (UniDOS: "IDE:GAMES/") [5323]
asm_1_3817_n_fl_nm_nod:		; Hyp.cls 5324
            ld b, 11		; Hyp.cls 5325
asm_1_3817_n_fl_nm_lp:		; Hyp.cls 5326
            inc hl		; Hyp.cls 5327
            ld a, b		; Hyp.cls 5328
            cp 3		; Hyp.cls 5329
            jr nz, asm_1_3817_n_fl_nm_c		; Hyp.cls 5330
            ld a, '.'		; Hyp.cls 5331
            ld (de), a		; Hyp.cls 5332
            inc de		; Hyp.cls 5333
asm_1_3817_n_fl_nm_c:		; Hyp.cls 5334
            call asm_1_3817_n_fl_peek		; Hyp.cls 5335
            and #7F		; Hyp.cls 5336
            cp ' ' + 1		; Hyp.cls 5337
            jr c, asm_1_3817_n_fl_nm_sk		; Hyp.cls 5338
            ld (de), a		; Hyp.cls 5339
            inc de		; Hyp.cls 5340
asm_1_3817_n_fl_nm_sk:		; Hyp.cls 5341
            djnz asm_1_3817_n_fl_nm_lp		; Hyp.cls 5342
            ex de, hl		; Hyp.cls 5343
            ld de, asm_1_3817_n_fl_name_s + 1		; Hyp.cls 5344
            or a		; Hyp.cls 5345
            sbc hl, de		; Hyp.cls 5346
            ld a, l		; Hyp.cls 5347
            ld (asm_1_3817_n_fl_name_s), a		; Hyp.cls 5348
            ret		; Hyp.cls 5349
asm_1_3817_n_fl_ok:		; Hyp.cls 5350
            xor a		; Hyp.cls 5351
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 5352
asm_1_3817_n_fp_done:                            ; back to FileCall in main RAM (fp_done) [5353]
            ld sp, (asm_1_3817_n_fp_sp)		; Hyp.cls 5354
            ret		; Hyp.cls 5355
asm_1_3817_n_fl_era:     db "ER", "A" + #80		; Hyp.cls 5356
asm_1_3817_n_fl_rencmd:  db "RE", "N" + #80		; Hyp.cls 5357
asm_1_3817_n_fl_par2:    dw asm_1_3817_n_fl_desc, asm_1_3817_n_fl_desc2		; Hyp.cls 5358
asm_1_3817_n_fl_desc2:   db 0		; Hyp.cls 5359
            dw 0		; Hyp.cls 5360
asm_1_3817_n_fl_dfl:     db 0                    ; fl_name: the drive for an FCB whose own is 0 (rename) [5361]
asm_1_3817_n_fl_par:     dw asm_1_3817_n_fl_desc		; Hyp.cls 5362
asm_1_3817_n_fl_desc:    db 0		; Hyp.cls 5363
            dw 0		; Hyp.cls 5364
asm_1_3817_n_fl_n:       db 128                  ; bytes fl_rdrec reads [5365]
asm_1_3817_n_fl_cnt:     dw 0		; Hyp.cls 5366
asm_1_3817_n_fl_at:      dw 0		; Hyp.cls 5367
asm_1_3817_n_fl_infcb:   dw 0		; Hyp.cls 5368
            db 0                    ; (1: fl_infcb the open's - fl_is) [5369]
asm_1_3817_n_fl_inrec:   dw 0		; Hyp.cls 5370
asm_1_3817_n_fl_want:    dw 0		; Hyp.cls 5371
asm_1_3817_n_fl_outfcb:  dw 0		; Hyp.cls 5372
            db 0		; Hyp.cls 5373
asm_1_3817_n_fl_outrec:  dw 0                    ; the next record written (36) [5374]
asm_1_3817_n_fl_had:     db 0                    ; 35: this slot's read file closed for it [5375]
asm_1_3817_n_fp_sp:      dw 0		; Hyp.cls 5376
; ---- UniDOS: its Ctrl J BIOS command (found once, KL FIND COMMAND) - a drive letter can be a
; path (CD IDE:, CD SD:GAMES ...: any UniDOS device's folder), folders listed (examine). FL_MAP:
; letters A-P, 32 bytes each: the path's length (0 none: the letter itself, "B:"), the path
; ("IDE:GAMES/": a device or logical drive, its folders, the last "/" or ":"). Cleared when
; UniDOS is found, and only set with it: with AMSDOS no letter has a path. Up there with the
; names (48 characters: a path and NAME.EXT), BDOS 132's block, DIR's listing: the FILES.DIR
; cache is #6000-#7BFF (112 entries)
asm_1_3817_n_FL_CMAX:    equ 112                 ; the cache's entries [5384]
asm_1_3817_n_FL_NL:      equ 49                  ; a name: its length, then the characters [5385]
asm_1_3817_n_fl_name_s:  equ #7C00               ; length, then "B:NAME.EXT" (or "IDE:GAMES/NAME.EXT") [5386]
asm_1_3817_n_fl_inname:  equ asm_1_3817_n_fl_name_s + asm_1_3817_n_FL_NL   ; the one being read's (33 going back) [5387]
asm_1_3817_n_fl_new_s:   equ asm_1_3817_n_fl_inname + asm_1_3817_n_FL_NL   ; (23: the new name) [5388]
asm_1_3817_n_FL_UB:      equ #7D00               ; BDOS 132's block (72 bytes) [5389]
asm_1_3817_n_FL_EXK:     equ #7D48               ; the folder DIR lists (its path: length, 31 characters) [5390]
asm_1_3817_n_FL_DATE:    equ #7D68               ; a date examine gives (7), then a name (11) [5391]
asm_1_3817_n_FL_TN:      equ #7D70		; Hyp.cls 5392
asm_1_3817_n_FL_MAP:     equ #7E00		; Hyp.cls 5393
            ASSERT #6000 + asm_1_3817_n_FL_CMAX * 64 <= asm_1_3817_n_fl_name_s, "the search's cache, below the names"		; Hyp.cls 5394
            ASSERT asm_1_3817_n_fl_new_s + asm_1_3817_n_FL_NL <= asm_1_3817_n_FL_UB, "the names, below BDOS 132's block"		; Hyp.cls 5395
            ASSERT (asm_1_3817_n_FL_MAP & 255) = 0, "asm_1_3817_n_FL_MAP: a page's start (asm_1_3817_n_fl_mapa)"		; Hyp.cls 5396
asm_1_3817_n_fl_cjf:     db 0                    ; 0: not looked for yet, 1: UniDOS, 2: none [5397]
asm_1_3817_n_fl_cj:      dw 0                    ; Ctrl J's far address (address, ROM) [5398]
            db 0		; Hyp.cls 5399
asm_1_3817_n_fl_cjn:     db #8A                  ; (its name) [5400]
asm_1_3817_n_fl_exv:     db 0                    ; FL_EXK's listing is the one UniDOS examines now ... [5401]
asm_1_3817_n_fl_exi:     dw 0                    ; ... at this entry next [5402]
asm_1_3817_n_fl_ue:      dw 0		; Hyp.cls 5403
; carry: UniDOS here (the first time: looked for, the paths cleared)
asm_1_3817_n_fl_uni:		; Hyp.cls 5405
    IFDEF NTC_MSXDOS		; Hyp.cls 5406
            scf                     ; zxn: the SD card stands in for UniDOS (paths: FL_MAP) [5407]
            ret		; Hyp.cls 5408
    ELSE		; Hyp.cls 5409
            ld a, (asm_1_3817_n_fl_cjf)		; Hyp.cls 5410
            cp 1		; Hyp.cls 5411
            jr z, asm_1_3817_n_fl_un_y		; Hyp.cls 5412
            or a		; Hyp.cls 5413
            ret nz                  ; (2: none - NC) [5414]
            ld hl, asm_1_3817_n_fl_cjn		; Hyp.cls 5415
            call #BCD4              ; KL FIND COMMAND: C = its ROM, HL = its address [5416]
            di		; Hyp.cls 5417
            ld a, 2		; Hyp.cls 5418
            jr nc, asm_1_3817_n_fl_un_s		; Hyp.cls 5419
            ld (asm_1_3817_n_fl_cj), hl		; Hyp.cls 5420
            ld a, c		; Hyp.cls 5421
            ld (asm_1_3817_n_fl_cj + 2), a		; Hyp.cls 5422
            ld hl, asm_1_3817_n_FL_MAP		; Hyp.cls 5423
            ld de, asm_1_3817_n_FL_MAP + 1		; Hyp.cls 5424
            ld bc, 511		; Hyp.cls 5425
            ld (hl), 0		; Hyp.cls 5426
            ldir		; Hyp.cls 5427
            ld a, 1		; Hyp.cls 5428
asm_1_3817_n_fl_un_s:		; Hyp.cls 5429
            ld (asm_1_3817_n_fl_cjf), a		; Hyp.cls 5430
            jr asm_1_3817_n_fl_uni		; Hyp.cls 5431
asm_1_3817_n_fl_un_y:		; Hyp.cls 5432
            scf		; Hyp.cls 5433
            ret		; Hyp.cls 5434
; Ctrl J command C (the other registers its input; its output back)
asm_1_3817_n_fl_cjc:		; Hyp.cls 5436
            rst #18                 ; (RST 3: a far call) [5437]
            dw asm_1_3817_n_fl_cj		; Hyp.cls 5438
            di		; Hyp.cls 5439
            ret		; Hyp.cls 5440
    ENDIF		; Hyp.cls 5441
; A = a drive letter: HL = its FL_MAP entry, A = its path's length (Z: none). Carry: not A-P,
; or no UniDOS (no paths). A, HL only
asm_1_3817_n_fl_mapa:		; Hyp.cls 5444
            sub 'A'		; Hyp.cls 5445
            cp 16		; Hyp.cls 5446
            ccf		; Hyp.cls 5447
            ret c		; Hyp.cls 5448
            ld l, a		; Hyp.cls 5449
            ld a, (asm_1_3817_n_fl_cjf)		; Hyp.cls 5450
            cp 1		; Hyp.cls 5451
            scf		; Hyp.cls 5452
            ret nz		; Hyp.cls 5453
            ld h, 0		; Hyp.cls 5454
            add hl, hl		; Hyp.cls 5455
            add hl, hl		; Hyp.cls 5456
            add hl, hl		; Hyp.cls 5457
            add hl, hl		; Hyp.cls 5458
            add hl, hl		; Hyp.cls 5459
            ld a, h		; Hyp.cls 5460
            add a, asm_1_3817_n_FL_MAP / 256		; Hyp.cls 5461
            ld h, a		; Hyp.cls 5462
            ld a, (hl)		; Hyp.cls 5463
            or a		; Hyp.cls 5464
            ret		; Hyp.cls 5465
; A = a drive letter: "B:" at DE, or its path - DE past it (BC, HL kept)
asm_1_3817_n_fl_pfx:		; Hyp.cls 5467
            push af		; Hyp.cls 5468
            call asm_1_3817_n_fl_pfxm		; Hyp.cls 5469
            jr nz, asm_1_3817_n_fl_px_d		; Hyp.cls 5470
            pop af		; Hyp.cls 5471
            ld (de), a		; Hyp.cls 5472
            inc de		; Hyp.cls 5473
            ld a, ':'		; Hyp.cls 5474
            ld (de), a		; Hyp.cls 5475
            inc de		; Hyp.cls 5476
            ret		; Hyp.cls 5477
asm_1_3817_n_fl_px_d:		; Hyp.cls 5478
            pop af		; Hyp.cls 5479
            ret		; Hyp.cls 5480
; ... its path only, if it has one (NZ; Z: none, nothing put)
asm_1_3817_n_fl_pfxm:		; Hyp.cls 5482
            push hl		; Hyp.cls 5483
            call asm_1_3817_n_fl_mapa		; Hyp.cls 5484
            jr c, asm_1_3817_n_fl_pm_no		; Hyp.cls 5485
            jr z, asm_1_3817_n_fl_pm_no		; Hyp.cls 5486
            push bc		; Hyp.cls 5487
            ld c, a		; Hyp.cls 5488
            ld b, 0		; Hyp.cls 5489
            inc hl		; Hyp.cls 5490
            ldir		; Hyp.cls 5491
            pop bc		; Hyp.cls 5492
            or a		; Hyp.cls 5493
            jr asm_1_3817_n_fl_pm_r		; Hyp.cls 5494
asm_1_3817_n_fl_pm_no:		; Hyp.cls 5495
            xor a		; Hyp.cls 5496
asm_1_3817_n_fl_pm_r:		; Hyp.cls 5497
    IFDEF NTC_MSXDOS		; Hyp.cls 5498
            ld (asm_1_3817_n_fl_sdf), a          ; (zxn: a path put = the SD card's file) [5499]
    ENDIF		; Hyp.cls 5500
            pop hl		; Hyp.cls 5501
            ret		; Hyp.cls 5502
    IFDEF NTC_MSXDOS		; Hyp.cls 5503
asm_1_3817_n_fl_sdf:     db 0		; Hyp.cls 5504
    ENDIF		; Hyp.cls 5505
asm_1_3817_n_fl_nlen:                            ; fl_name_s's length: its characters end at DE [5506]
            ld hl, -(asm_1_3817_n_fl_name_s + 1)		; Hyp.cls 5507
            add hl, de		; Hyp.cls 5508
            ld a, l		; Hyp.cls 5509
            ld (asm_1_3817_n_fl_name_s), a		; Hyp.cls 5510
            ret		; Hyp.cls 5511
; the folder whose path is at fl_name_s + 1 to DE (fl_exdir2: fl_name_s, its length set)
; examined (Ctrl J 12): Z its listing ready (examine next: Ctrl J 13), NZ no UniDOS, a drive
; it can't examine (AMSDOS's floppies), not a folder
    IFNDEF NTC_MSXDOS		; Hyp.cls 5515
asm_1_3817_n_fl_exdir:		; Hyp.cls 5516
            call asm_1_3817_n_fl_nlen		; Hyp.cls 5517
asm_1_3817_n_fl_exdir2:		; Hyp.cls 5518
            call asm_1_3817_n_fl_uni		; Hyp.cls 5519
            jr nc, asm_1_3817_n_fl_ed_no		; Hyp.cls 5520
            xor a		; Hyp.cls 5521
            ld (asm_1_3817_n_fl_exv), a		; Hyp.cls 5522
            ld hl, asm_1_3817_n_fl_name_s		; Hyp.cls 5523
            ld b, (hl)		; Hyp.cls 5524
            inc hl		; Hyp.cls 5525
            ld ix, asm_1_3817_n_FL_DATE		; Hyp.cls 5526
            ld c, 12		; Hyp.cls 5527
            call asm_1_3817_n_fl_cjc		; Hyp.cls 5528
            ret c		; Hyp.cls 5529
asm_1_3817_n_fl_ed_no:		; Hyp.cls 5530
            ld a, 254               ; (254: no UniDOS, or a drive it can't examine) [5531]
            or a		; Hyp.cls 5532
            ret		; Hyp.cls 5533
    ENDIF		; Hyp.cls 5534
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
asm_1_3817_n_fl_unicall:		; Hyp.cls 5558
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 5559
            ld de, asm_1_3817_n_FL_UB		; Hyp.cls 5560
            ld b, 72		; Hyp.cls 5561
asm_1_3817_n_fl_uc_in:		; Hyp.cls 5562
            call asm_1_3817_n_fl_peek		; Hyp.cls 5563
            ld (de), a		; Hyp.cls 5564
            inc hl		; Hyp.cls 5565
            inc de		; Hyp.cls 5566
            djnz asm_1_3817_n_fl_uc_in		; Hyp.cls 5567
            ld a, (asm_1_3817_n_FL_UB)		; Hyp.cls 5568
            sub #C0		; Hyp.cls 5569
            cp 9		; Hyp.cls 5570
            jp nc, asm_1_3817_n_fp_done          ; (CP/M's 30) [5571]
            ld (asm_1_3817_n_FL_UB), a		; Hyp.cls 5572
    IFDEF NTC_MSXDOS		; Hyp.cls 5573
            jp sd_h_uc              ; zxn: the SD card's folders [5574]
    ELSE		; Hyp.cls 5575
            call asm_1_3817_n_fl_uni		; Hyp.cls 5576
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 5577
            ld a, (asm_1_3817_n_FL_UB)		; Hyp.cls 5578
            or a		; Hyp.cls 5579
            jp z, asm_1_3817_n_fl_ok		; Hyp.cls 5580
            dec a		; Hyp.cls 5581
            jp z, asm_1_3817_n_fl_uc_get		; Hyp.cls 5582
            dec a		; Hyp.cls 5583
            jp z, asm_1_3817_n_fl_uc_set		; Hyp.cls 5584
            dec a		; Hyp.cls 5585
            jp z, asm_1_3817_n_fl_uc_dev		; Hyp.cls 5586
            dec a		; Hyp.cls 5587
            jp z, asm_1_3817_n_fl_uc_inf		; Hyp.cls 5588
            dec a		; Hyp.cls 5589
            jp z, asm_1_3817_n_fl_uc_dir		; Hyp.cls 5590
            dec a		; Hyp.cls 5591
            jr z, asm_1_3817_n_fl_uc_md		; Hyp.cls 5592
            cp 2		; Hyp.cls 5593
            jr z, asm_1_3817_n_fl_uc_yes		; Hyp.cls 5594
            ld a, (var_hyp_fin)           ; 7: the header of the file this slot reads (the disc ROM's, [5595]
            ld hl, asm_1_3817_n_fl_slot          ; from CAS IN OPEN: 69 bytes) to Byte(2) [5596]
            cp (hl)		; Hyp.cls 5597
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 5598
            ld hl, (asm_1_3817_n_fl_hdr)		; Hyp.cls 5599
            ld de, asm_1_3817_n_FL_UB + 2		; Hyp.cls 5600
            ld bc, 69		; Hyp.cls 5601
            ldir		; Hyp.cls 5602
            xor a		; Hyp.cls 5603
            ld b, 71		; Hyp.cls 5604
            jp asm_1_3817_n_fl_uc_back		; Hyp.cls 5605
    ENDIF		; Hyp.cls 5606
asm_1_3817_n_fl_hdr:     dw 0		; Hyp.cls 5607
    IFNDEF NTC_MSXDOS		; Hyp.cls 5608
asm_1_3817_n_fl_uc_yes:                          ; 8: the next delete (19) may take a folder (RMDIR's) [5609]
            ld a, 1		; Hyp.cls 5610
            ld (asm_1_3817_n_fl_yes), a		; Hyp.cls 5611
            jp asm_1_3817_n_fl_ok		; Hyp.cls 5612
    ENDIF		; Hyp.cls 5613
asm_1_3817_n_fl_yes:     db 0		; Hyp.cls 5614
    IFNDEF NTC_MSXDOS		; Hyp.cls 5615
asm_1_3817_n_fl_uc_md:                           ; 6: a folder made (CAS OUT OPEN, the path ending "/") [5616]
            ld a, (var_hyp_fout)		; Hyp.cls 5617
            or a		; Hyp.cls 5618
            jp nz, asm_1_3817_n_fp_done		; Hyp.cls 5619
            ld hl, asm_1_3817_n_FL_UB + 2		; Hyp.cls 5620
            ld a, (hl)		; Hyp.cls 5621
            or a		; Hyp.cls 5622
            jp z, asm_1_3817_n_fp_done		; Hyp.cls 5623
            ld b, a		; Hyp.cls 5624
            inc hl		; Hyp.cls 5625
            ld de, #4800		; Hyp.cls 5626
            call #BC8C              ; CAS OUT OPEN [5627]
            di		; Hyp.cls 5628
            jr nc, asm_1_3817_n_fl_md_nc		; Hyp.cls 5629
            call #BC92              ; (a file: CAS OUT ABANDON - not made) [5630]
            di		; Hyp.cls 5631
            ld a, 1		; Hyp.cls 5632
            jr asm_1_3817_n_fl_md_r		; Hyp.cls 5633
asm_1_3817_n_fl_md_nc:		; Hyp.cls 5634
            and #7F		; Hyp.cls 5635
            cp #17                  ; (DSK_ERR_DIRECTORY_FOUND: made) [5636]
            jp z, asm_1_3817_n_fl_ok		; Hyp.cls 5637
            or a		; Hyp.cls 5638
            jr nz, asm_1_3817_n_fl_md_r		; Hyp.cls 5639
            inc a		; Hyp.cls 5640
asm_1_3817_n_fl_md_r:		; Hyp.cls 5641
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 5642
            jp asm_1_3817_n_fp_done		; Hyp.cls 5643
    ENDIF		; Hyp.cls 5644
asm_1_3817_n_fl_uc_back:                         ; A the answer, the block's first B bytes back to the slot [5645]
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 5646
            ld a, (asm_1_3817_n_FL_UB)		; Hyp.cls 5647
            add a, #C0		; Hyp.cls 5648
            ld (asm_1_3817_n_FL_UB), a		; Hyp.cls 5649
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 5650
            ld de, asm_1_3817_n_FL_UB		; Hyp.cls 5651
asm_1_3817_n_fl_uc_out:		; Hyp.cls 5652
            ld a, (de)		; Hyp.cls 5653
            call asm_1_3817_n_fl_poke		; Hyp.cls 5654
            inc hl		; Hyp.cls 5655
            inc de		; Hyp.cls 5656
            djnz asm_1_3817_n_fl_uc_out		; Hyp.cls 5657
            jp asm_1_3817_n_fp_done		; Hyp.cls 5658
asm_1_3817_n_fl_uc_get:		; Hyp.cls 5659
            ld a, (asm_1_3817_n_FL_UB + 1)		; Hyp.cls 5660
            call asm_1_3817_n_fl_mapa		; Hyp.cls 5661
            jp c, asm_1_3817_n_fp_done		; Hyp.cls 5662
            ld de, asm_1_3817_n_FL_UB + 2		; Hyp.cls 5663
            ld c, (hl)		; Hyp.cls 5664
            ld b, 0		; Hyp.cls 5665
            inc bc		; Hyp.cls 5666
            ldir		; Hyp.cls 5667
            xor a		; Hyp.cls 5668
            ld b, 34		; Hyp.cls 5669
            jr asm_1_3817_n_fl_uc_back		; Hyp.cls 5670
    IFNDEF NTC_MSXDOS		; Hyp.cls 5671
asm_1_3817_n_fl_uc_dev:		; Hyp.cls 5672
            ld de, asm_1_3817_n_FL_UB + 2		; Hyp.cls 5673
            ld c, 1		; Hyp.cls 5674
            call asm_1_3817_n_fl_cjc		; Hyp.cls 5675
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 5676
            xor a		; Hyp.cls 5677
            ld b, 66		; Hyp.cls 5678
            jr asm_1_3817_n_fl_uc_back		; Hyp.cls 5679
asm_1_3817_n_fl_uc_inf:		; Hyp.cls 5680
            ld hl, asm_1_3817_n_FL_UB + 2		; Hyp.cls 5681
            ld de, asm_1_3817_n_FL_UB + 8		; Hyp.cls 5682
            ld c, 2		; Hyp.cls 5683
            call asm_1_3817_n_fl_cjc		; Hyp.cls 5684
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 5685
            xor a		; Hyp.cls 5686
            ld b, 72		; Hyp.cls 5687
            jr asm_1_3817_n_fl_uc_back		; Hyp.cls 5688
asm_1_3817_n_fl_uc_set:		; Hyp.cls 5689
            ld a, (asm_1_3817_n_FL_UB + 1)		; Hyp.cls 5690
            call asm_1_3817_n_fl_mapa		; Hyp.cls 5691
            jp c, asm_1_3817_n_fp_done		; Hyp.cls 5692
            ld (asm_1_3817_n_fl_ue), hl		; Hyp.cls 5693
            xor a		; Hyp.cls 5694
            ld (asm_1_3817_n_fl_exv), a		; Hyp.cls 5695
            ld a, (asm_1_3817_n_FL_UB + 2)		; Hyp.cls 5696
            or a		; Hyp.cls 5697
            jr z, asm_1_3817_n_fl_us_put         ; none: the letter itself again [5698]
            cp 32		; Hyp.cls 5699
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 5700
            ld b, a		; Hyp.cls 5701
            ld hl, asm_1_3817_n_FL_UB + 3		; Hyp.cls 5702
asm_1_3817_n_fl_us_up:                           ; capitals [5703]
            ld a, (hl)		; Hyp.cls 5704
            cp 'a'		; Hyp.cls 5705
            jr c, asm_1_3817_n_fl_us_c		; Hyp.cls 5706
            cp 'z' + 1		; Hyp.cls 5707
            jr nc, asm_1_3817_n_fl_us_c		; Hyp.cls 5708
            sub 32		; Hyp.cls 5709
            ld (hl), a		; Hyp.cls 5710
asm_1_3817_n_fl_us_c:		; Hyp.cls 5711
            inc hl		; Hyp.cls 5712
            djnz asm_1_3817_n_fl_us_up		; Hyp.cls 5713
            dec hl		; Hyp.cls 5714
            ld a, (hl)		; Hyp.cls 5715
            cp ':'		; Hyp.cls 5716
            jr z, asm_1_3817_n_fl_us_ex		; Hyp.cls 5717
            cp '/'		; Hyp.cls 5718
            jr z, asm_1_3817_n_fl_us_ex		; Hyp.cls 5719
            ld a, (asm_1_3817_n_FL_UB + 2)		; Hyp.cls 5720
            cp 31		; Hyp.cls 5721
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 5722
            inc a		; Hyp.cls 5723
            ld (asm_1_3817_n_FL_UB + 2), a		; Hyp.cls 5724
            inc hl		; Hyp.cls 5725
            ld (hl), '/'		; Hyp.cls 5726
asm_1_3817_n_fl_us_ex:		; Hyp.cls 5727
            ld hl, asm_1_3817_n_FL_UB + 2        ; a folder? [5728]
            ld de, asm_1_3817_n_fl_name_s		; Hyp.cls 5729
            ld bc, 32		; Hyp.cls 5730
            ldir		; Hyp.cls 5731
            call asm_1_3817_n_fl_exdir2		; Hyp.cls 5732
            jr z, asm_1_3817_n_fl_us_put		; Hyp.cls 5733
            cp 254		; Hyp.cls 5734
            jr z, asm_1_3817_n_fl_us_put         ; (a floppy AMSDOS runs - DFA:, DFB: - can't be examined: taken) [5735]
            or a		; Hyp.cls 5736
            jr nz, asm_1_3817_n_fl_us_err		; Hyp.cls 5737
            inc a		; Hyp.cls 5738
asm_1_3817_n_fl_us_err:		; Hyp.cls 5739
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 5740
            jp asm_1_3817_n_fp_done		; Hyp.cls 5741
asm_1_3817_n_fl_us_put:		; Hyp.cls 5742
            ld hl, asm_1_3817_n_FL_UB + 2		; Hyp.cls 5743
            ld de, (asm_1_3817_n_fl_ue)		; Hyp.cls 5744
            ld bc, 32		; Hyp.cls 5745
            ldir		; Hyp.cls 5746
            jp asm_1_3817_n_fl_ok		; Hyp.cls 5747
asm_1_3817_n_fl_uc_dir:		; Hyp.cls 5748
            ld de, asm_1_3817_n_fl_name_s + 1    ; the folder's path [5749]
            ld a, (asm_1_3817_n_FL_UB + 1)		; Hyp.cls 5750
            or a		; Hyp.cls 5751
            jr z, asm_1_3817_n_fl_ud_p		; Hyp.cls 5752
            call asm_1_3817_n_fl_pfx		; Hyp.cls 5753
            jr asm_1_3817_n_fl_ud_k		; Hyp.cls 5754
asm_1_3817_n_fl_ud_p:		; Hyp.cls 5755
            ld hl, asm_1_3817_n_FL_UB + 28		; Hyp.cls 5756
            ld a, (hl)		; Hyp.cls 5757
            cp 32		; Hyp.cls 5758
            jp nc, asm_1_3817_n_fp_done		; Hyp.cls 5759
            ld c, a		; Hyp.cls 5760
            ld b, 0		; Hyp.cls 5761
            inc hl		; Hyp.cls 5762
            ldir		; Hyp.cls 5763
asm_1_3817_n_fl_ud_k:		; Hyp.cls 5764
            call asm_1_3817_n_fl_nlen		; Hyp.cls 5765
            ld hl, asm_1_3817_n_fl_name_s        ; the same folder, still the one examined, at this entry: [5766]
            ld de, asm_1_3817_n_FL_EXK           ; on from there [5767]
            ld a, (asm_1_3817_n_fl_exv)		; Hyp.cls 5768
            or a		; Hyp.cls 5769
            jr z, asm_1_3817_n_fl_ud_new		; Hyp.cls 5770
            ld a, (hl)		; Hyp.cls 5771
            inc a		; Hyp.cls 5772
            ld b, a		; Hyp.cls 5773
asm_1_3817_n_fl_ud_cmp:		; Hyp.cls 5774
            ld a, (de)		; Hyp.cls 5775
            cp (hl)		; Hyp.cls 5776
            jr nz, asm_1_3817_n_fl_ud_new		; Hyp.cls 5777
            inc hl		; Hyp.cls 5778
            inc de		; Hyp.cls 5779
            djnz asm_1_3817_n_fl_ud_cmp		; Hyp.cls 5780
            ld hl, (asm_1_3817_n_fl_exi)		; Hyp.cls 5781
            ld de, (asm_1_3817_n_FL_UB + 2)		; Hyp.cls 5782
            or a		; Hyp.cls 5783
            sbc hl, de		; Hyp.cls 5784
            jr z, asm_1_3817_n_fl_ud_next		; Hyp.cls 5785
asm_1_3817_n_fl_ud_new:		; Hyp.cls 5786
            ld hl, asm_1_3817_n_fl_name_s		; Hyp.cls 5787
            ld de, asm_1_3817_n_FL_EXK		; Hyp.cls 5788
            ld bc, 32		; Hyp.cls 5789
            ldir		; Hyp.cls 5790
            call asm_1_3817_n_fl_exdir2		; Hyp.cls 5791
            jr z, asm_1_3817_n_fl_ud_ok		; Hyp.cls 5792
            or a		; Hyp.cls 5793
            jr nz, asm_1_3817_n_fl_us_err		; Hyp.cls 5794
            inc a		; Hyp.cls 5795
            jr asm_1_3817_n_fl_us_err		; Hyp.cls 5796
asm_1_3817_n_fl_ud_ok:		; Hyp.cls 5797
            ld hl, 0		; Hyp.cls 5798
            ld (asm_1_3817_n_fl_exi), hl		; Hyp.cls 5799
            ld a, 1		; Hyp.cls 5800
            ld (asm_1_3817_n_fl_exv), a		; Hyp.cls 5801
asm_1_3817_n_fl_ud_skip:                         ; on to entry Word(2) [5802]
            ld hl, (asm_1_3817_n_fl_exi)		; Hyp.cls 5803
            ld de, (asm_1_3817_n_FL_UB + 2)		; Hyp.cls 5804
            or a		; Hyp.cls 5805
            sbc hl, de		; Hyp.cls 5806
            jr z, asm_1_3817_n_fl_ud_next		; Hyp.cls 5807
            ld hl, asm_1_3817_n_FL_TN		; Hyp.cls 5808
            ld ix, asm_1_3817_n_FL_DATE		; Hyp.cls 5809
            ld c, 13		; Hyp.cls 5810
            call asm_1_3817_n_fl_cjc		; Hyp.cls 5811
            jr nc, asm_1_3817_n_fl_ud_end		; Hyp.cls 5812
            jr nz, asm_1_3817_n_fl_ud_end		; Hyp.cls 5813
            ld hl, (asm_1_3817_n_fl_exi)		; Hyp.cls 5814
            inc hl		; Hyp.cls 5815
            ld (asm_1_3817_n_fl_exi), hl		; Hyp.cls 5816
            jr asm_1_3817_n_fl_ud_skip		; Hyp.cls 5817
asm_1_3817_n_fl_ud_next:		; Hyp.cls 5818
            ld hl, asm_1_3817_n_FL_UB + 16		; Hyp.cls 5819
            ld ix, asm_1_3817_n_FL_UB + 9		; Hyp.cls 5820
            ld c, 13		; Hyp.cls 5821
            call asm_1_3817_n_fl_cjc		; Hyp.cls 5822
            jr nc, asm_1_3817_n_fl_ud_end		; Hyp.cls 5823
            jr nz, asm_1_3817_n_fl_ud_end		; Hyp.cls 5824
            ld (asm_1_3817_n_FL_UB + 4), a		; Hyp.cls 5825
            ld (asm_1_3817_n_FL_UB + 5), de		; Hyp.cls 5826
            ld (asm_1_3817_n_FL_UB + 7), bc		; Hyp.cls 5827
            ld hl, (asm_1_3817_n_fl_exi)		; Hyp.cls 5828
            inc hl		; Hyp.cls 5829
            ld (asm_1_3817_n_fl_exi), hl		; Hyp.cls 5830
            xor a		; Hyp.cls 5831
            ld b, 28		; Hyp.cls 5832
            jp asm_1_3817_n_fl_uc_back		; Hyp.cls 5833
asm_1_3817_n_fl_ud_end:		; Hyp.cls 5834
            xor a		; Hyp.cls 5835
            ld (asm_1_3817_n_fl_exv), a		; Hyp.cls 5836
            inc a		; Hyp.cls 5837
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 5838
            jp asm_1_3817_n_fp_done		; Hyp.cls 5839
    ENDIF		; Hyp.cls 5840
asm_1_3817_n_fp_end:		; Hyp.cls 5841
            ASSERT asm_1_3817_n_fp_end <= #6000, "FileCall's page code: below the search's cache (#6000)"		; Hyp.cls 5842
; ---- the service page's code (window data from #6000, copied there by FileCall 99)
            ds #6000 - $		; Hyp.cls 6056
asm_1_5940_n_sv_go:		; Hyp.cls 6057
            ld (asm_1_5940_n_sv_sp), sp		; Hyp.cls 6058
            ld hl, (var_hyp_svc_p)            ; p 0: slot t's claims freed (Main's FilesShut) [6059]
            ld a, h		; Hyp.cls 6060
            or l		; Hyp.cls 6061
            jp z, asm_1_5940_n_sv_cfree		; Hyp.cls 6062
            ld hl, (var_hyp_svc_p)            ; the request (16 bytes) from the slot [6063]
            ld de, (var_hyp_svc_setting)		; Hyp.cls 6064
            call asm_1_5940_n_sv_sw		; Hyp.cls 6065
            push bc		; Hyp.cls 6066
            pop ix		; Hyp.cls 6067
            ld iy, (var_hyp_svp)		; Hyp.cls 6068
            ld de, asm_1_5940_n_sv_blk		; Hyp.cls 6069
            ld a, 16		; Hyp.cls 6070
            call asm_1_5940_n_sv_dx		; Hyp.cls 6071
            ld hl, (asm_1_5940_n_sv_blk + 8)     ; how many: 2K at most [6072]
            bit 7, h		; Hyp.cls 6073
            jr nz, asm_1_5940_n_sv_n2		; Hyp.cls 6074
            ld de, 2049		; Hyp.cls 6075
            or a		; Hyp.cls 6076
            sbc hl, de		; Hyp.cls 6077
            add hl, de		; Hyp.cls 6078
            jr c, asm_1_5940_n_sv_n1		; Hyp.cls 6079
asm_1_5940_n_sv_n2:		; Hyp.cls 6080
            ld hl, 2048		; Hyp.cls 6081
asm_1_5940_n_sv_n1:		; Hyp.cls 6082
            ld (asm_1_5940_n_sv_n), hl		; Hyp.cls 6083
            xor a		; Hyp.cls 6084
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 6085
            ld a, 2                 ; (the copies to the slot: its bank) [6086]
            ld (asm_1_5940_n_sv_dk), a		; Hyp.cls 6087
            ld hl, (var_hyp_svc_setting)		; Hyp.cls 6088
            ld (asm_1_5940_n_sv_ds), hl		; Hyp.cls 6089
            ld hl, (asm_1_5940_n_sv_blk + 6)		; Hyp.cls 6090
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 6091
            ld a, (asm_1_5940_n_sv_blk)		; Hyp.cls 6092
            cp 10		; Hyp.cls 6093
            jp z, asm_1_5940_n_sv_mem		; Hyp.cls 6094
            cp 11		; Hyp.cls 6095
            jp z, asm_1_5940_n_sv_ptr		; Hyp.cls 6096
            cp 13		; Hyp.cls 6097
            jp z, asm_1_5940_n_sv_store		; Hyp.cls 6098
            cp 14		; Hyp.cls 6099
            jp z, asm_1_5940_n_sv_store		; Hyp.cls 6100
            cp 15		; Hyp.cls 6101
            jp z, asm_1_5940_n_sv_tab		; Hyp.cls 6102
            cp 16		; Hyp.cls 6103
            jp c, asm_1_5940_n_sv_err		; Hyp.cls 6104
            cp 20		; Hyp.cls 6105
            jp c, asm_1_5940_n_sv_claim		; Hyp.cls 6106
            cp 28		; Hyp.cls 6107
            jp c, asm_1_5940_n_sv_net		; Hyp.cls 6108
            cp 34		; Hyp.cls 6109
            jp c, asm_1_5940_n_sv_port		; Hyp.cls 6110
            jp z, asm_1_5940_n_pt_list		; Hyp.cls 6111
asm_1_5940_n_sv_err:		; Hyp.cls 6112
            ld sp, (asm_1_5940_n_sv_sp)		; Hyp.cls 6113
            ld a, 255		; Hyp.cls 6114
            ret		; Hyp.cls 6115
asm_1_5940_n_sv_ok:		; Hyp.cls 6116
            ld sp, (asm_1_5940_n_sv_sp)		; Hyp.cls 6117
            xor a		; Hyp.cls 6118
            ret		; Hyp.cls 6119
; 10: memory
asm_1_5940_n_sv_mem:		; Hyp.cls 6121
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 6122
            cp 4		; Hyp.cls 6123
            jr z, asm_1_5940_n_sv_m4             ; 4: the caller's Word(6) into slot Word(2) at Word(4) [6124]
            ld hl, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 6125
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 6126
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 6127
            or a		; Hyp.cls 6128
            jr nz, asm_1_5940_n_sv_m1		; Hyp.cls 6129
            ld de, (mem_count)      ; 0: a page (below Pages) [6130]
            push hl		; Hyp.cls 6131
            or a		; Hyp.cls 6132
            sbc hl, de		; Hyp.cls 6133
            pop hl		; Hyp.cls 6134
            jp nc, asm_1_5940_n_sv_err		; Hyp.cls 6135
            call asm_1_5940_n_sv_pgset		; Hyp.cls 6136
            ld (asm_1_5940_n_sv_ss), bc		; Hyp.cls 6137
            ld a, 1		; Hyp.cls 6138
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 6139
            jr asm_1_5940_n_sv_mgo		; Hyp.cls 6140
asm_1_5940_n_sv_m1:		; Hyp.cls 6141
            dec a		; Hyp.cls 6142
            jr nz, asm_1_5940_n_sv_m2		; Hyp.cls 6143
            ld (asm_1_5940_n_sv_ss), hl          ; 1: a ROM [6144]
            ld a, 1		; Hyp.cls 6145
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 6146
            ld a, 3		; Hyp.cls 6147
            jr asm_1_5940_n_sv_mgo1		; Hyp.cls 6148
asm_1_5940_n_sv_m2:		; Hyp.cls 6149
            dec a		; Hyp.cls 6150
            jr nz, asm_1_5940_n_sv_m3		; Hyp.cls 6151
            ld a, 4                 ; 2: main RAM [6152]
            jr asm_1_5940_n_sv_mgo1		; Hyp.cls 6153
asm_1_5940_n_sv_m3:		; Hyp.cls 6154
            dec a		; Hyp.cls 6155
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 6156
            call asm_1_5940_n_sv_slot            ; 3: a slot's memory (one in use) [6157]
            jp z, asm_1_5940_n_sv_err		; Hyp.cls 6158
            ld (asm_1_5940_n_sv_ss), de		; Hyp.cls 6159
            ld a, 2		; Hyp.cls 6160
            jr asm_1_5940_n_sv_mgo1		; Hyp.cls 6161
asm_1_5940_n_sv_mgo:		; Hyp.cls 6162
            ld a, 1		; Hyp.cls 6163
asm_1_5940_n_sv_mgo1:		; Hyp.cls 6164
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 6165
            call asm_1_5940_n_sv_copy		; Hyp.cls 6166
            jr asm_1_5940_n_sv_ok		; Hyp.cls 6167
; 10 Byte(1) 4: the caller's own Word(6) written into slot Word(2) at Word(4), Word(8) bytes
asm_1_5940_n_sv_m4:		; Hyp.cls 6169
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 6170
            call asm_1_5940_n_sv_slot            ; the target slot (one in use): DE its RAM setting [6171]
            jp z, asm_1_5940_n_sv_err		; Hyp.cls 6172
            ld (asm_1_5940_n_sv_ds), de          ; dest: that slot's bank, at Word(4) [6173]
            ld a, 2		; Hyp.cls 6174
            ld (asm_1_5940_n_sv_dk), a		; Hyp.cls 6175
            ld hl, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 6176
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 6177
            ld hl, (var_hyp_svc_setting)      ; source: the caller's bank, at Word(6) [6178]
            ld (asm_1_5940_n_sv_ss), hl		; Hyp.cls 6179
            ld a, 2		; Hyp.cls 6180
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 6181
            ld hl, (asm_1_5940_n_sv_blk + 6)		; Hyp.cls 6182
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 6183
            xor a		; Hyp.cls 6184
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 6185
            call asm_1_5940_n_sv_copy		; Hyp.cls 6186
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6187
; HL = a slot number: Z when it isn't one in use, else DE = its RAM setting
asm_1_5940_n_sv_slot:		; Hyp.cls 6189
            ld a, h		; Hyp.cls 6190
            or a		; Hyp.cls 6191
            jr nz, asm_1_5940_n_sv_sl0		; Hyp.cls 6192
            or l		; Hyp.cls 6193
            ret z		; Hyp.cls 6194
            ld de, (var_hyp_svns)		; Hyp.cls 6195
            ld a, (de)		; Hyp.cls 6196
            cp l		; Hyp.cls 6197
            jr c, asm_1_5940_n_sv_sl0		; Hyp.cls 6198
            add hl, hl		; Hyp.cls 6199
            push hl		; Hyp.cls 6200
            ld de, (var_hyp_svst)		; Hyp.cls 6201
            add hl, de		; Hyp.cls 6202
            ld a, (hl)		; Hyp.cls 6203
            pop hl		; Hyp.cls 6204
            or a		; Hyp.cls 6205
            ret z		; Hyp.cls 6206
            ld de, (var_hyp_svsg)		; Hyp.cls 6207
            add hl, de		; Hyp.cls 6208
            ld e, (hl)		; Hyp.cls 6209
            inc hl		; Hyp.cls 6210
            ld d, (hl)		; Hyp.cls 6211
            or 1                    ; (NZ) [6212]
            ret		; Hyp.cls 6213
asm_1_5940_n_sv_sl0:		; Hyp.cls 6214
            xor a		; Hyp.cls 6215
            ret		; Hyp.cls 6216
; 13 / 14: a 2K block of the store (13 from the slot, 14 to it) - Byte(1) 1: from Word(4) bytes into
; the block (any part of its 16K page, not past the page's end: Pluto's KEYMAN reads a key a byte at a time)
asm_1_5940_n_sv_store:		; Hyp.cls 6219
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 6220
            ld a, h		; Hyp.cls 6221
            or a		; Hyp.cls 6222
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 6223
            ld a, l		; Hyp.cls 6224
            and 7		; Hyp.cls 6225
            add a, a		; Hyp.cls 6226
            add a, a		; Hyp.cls 6227
            add a, a		; Hyp.cls 6228
            ld (asm_1_5940_n_sv_sa + 1), a       ; the block's place in its page [6229]
            xor a		; Hyp.cls 6230
            ld (asm_1_5940_n_sv_sa), a		; Hyp.cls 6231
            srl l		; Hyp.cls 6232
            srl l		; Hyp.cls 6233
            srl l		; Hyp.cls 6234
            ld a, (asm_1_5940_n_sv_blk + 1)      ; Byte(1) 1: Word(4) bytes on from the block's start (its page's end the limit) [6235]
            or a		; Hyp.cls 6236
            jr z, asm_1_5940_n_sv_sto0		; Hyp.cls 6237
            ld a, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 6238
            ld (asm_1_5940_n_sv_sa), a		; Hyp.cls 6239
            ld a, (asm_1_5940_n_sv_blk + 5)		; Hyp.cls 6240
            ld b, a		; Hyp.cls 6241
            ld a, (asm_1_5940_n_sv_sa + 1)		; Hyp.cls 6242
            add a, b		; Hyp.cls 6243
            and #3F		; Hyp.cls 6244
            ld (asm_1_5940_n_sv_sa + 1), a		; Hyp.cls 6245
asm_1_5940_n_sv_sto0:		; Hyp.cls 6246
            ld h, #FF               ; its page: the slot's byte at #FF00 + block / 8 [6247]
            ld de, (var_hyp_svc_setting)		; Hyp.cls 6248
            call asm_1_5940_n_sv_sw		; Hyp.cls 6249
            push bc		; Hyp.cls 6250
            pop ix		; Hyp.cls 6251
            ld iy, (var_hyp_svp)		; Hyp.cls 6252
            ld de, asm_1_5940_n_sv_tmp		; Hyp.cls 6253
            ld a, 1		; Hyp.cls 6254
            call asm_1_5940_n_sv_dx		; Hyp.cls 6255
            ld a, (asm_1_5940_n_sv_tmp)		; Hyp.cls 6256
            or a		; Hyp.cls 6257
            jp z, asm_1_5940_n_sv_err		; Hyp.cls 6258
            ld l, a		; Hyp.cls 6259
            ld h, 0		; Hyp.cls 6260
            call asm_1_5940_n_sv_pgset		; Hyp.cls 6261
            ld (asm_1_5940_n_sv_ss), bc		; Hyp.cls 6262
            ld a, 1		; Hyp.cls 6263
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 6264
            ld a, (asm_1_5940_n_sv_blk)		; Hyp.cls 6265
            cp 14		; Hyp.cls 6266
            jr z, asm_1_5940_n_sv_st1		; Hyp.cls 6267
            ld hl, (asm_1_5940_n_sv_sa)          ; 13: the slot to the page [6268]
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 6269
            ld hl, (asm_1_5940_n_sv_ss)		; Hyp.cls 6270
            ld (asm_1_5940_n_sv_ds), hl		; Hyp.cls 6271
            ld a, 1		; Hyp.cls 6272
            ld (asm_1_5940_n_sv_dk), a		; Hyp.cls 6273
            ld hl, (asm_1_5940_n_sv_blk + 6)		; Hyp.cls 6274
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 6275
            ld hl, (var_hyp_svc_setting)		; Hyp.cls 6276
            ld (asm_1_5940_n_sv_ss), hl		; Hyp.cls 6277
            ld a, 2		; Hyp.cls 6278
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 6279
asm_1_5940_n_sv_st1:		; Hyp.cls 6280
            call asm_1_5940_n_sv_copy		; Hyp.cls 6281
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6282
; 11: the pointer, while the slot is in front
asm_1_5940_n_sv_ptr:		; Hyp.cls 6284
            ld hl, (var_hyp_svfr)		; Hyp.cls 6285
            ld a, (hl)		; Hyp.cls 6286
            ld hl, var_hyp_svc_t		; Hyp.cls 6287
            cp (hl)		; Hyp.cls 6288
            jp nz, asm_1_5940_n_sv_ok		; Hyp.cls 6289
            ld a, (var_hyp_pon)		; Hyp.cls 6290
            or a		; Hyp.cls 6291
            call nz, asm_1_5940_n_pt_xor		; Hyp.cls 6292
            xor a		; Hyp.cls 6293
            ld (var_hyp_pon), a		; Hyp.cls 6294
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 6295
            or a		; Hyp.cls 6296
            jp z, asm_1_5940_n_sv_ok		; Hyp.cls 6297
            ld a, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 6298
            ld hl, var_hyp_scc		; Hyp.cls 6299
            cp (hl)		; Hyp.cls 6300
            jp nc, asm_1_5940_n_sv_ok            ; (off the screen: none) [6301]
            ld (var_hyp_pox), a		; Hyp.cls 6302
            ld a, (asm_1_5940_n_sv_blk + 3)		; Hyp.cls 6303
            ld (var_hyp_poy), a		; Hyp.cls 6304
            call asm_1_5940_n_pt_xor		; Hyp.cls 6305
            ld a, 1		; Hyp.cls 6306
            ld (var_hyp_pon), a		; Hyp.cls 6307
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6308
asm_1_5940_n_pt_xor:                             ; the checkerboard XORed at pox, poy (the screen is main RAM) [6309]
            ld a, (var_hyp_poy)		; Hyp.cls 6310
            ld e, a		; Hyp.cls 6311
            ld d, 0		; Hyp.cls 6312
            ld hl, 0		; Hyp.cls 6313
            ld a, (var_hyp_scc)		; Hyp.cls 6314
            ld b, 8		; Hyp.cls 6315
asm_1_5940_n_pt_mul:		; Hyp.cls 6316
            add hl, hl		; Hyp.cls 6317
            rlca		; Hyp.cls 6318
            jr nc, asm_1_5940_n_pt_mn		; Hyp.cls 6319
            add hl, de		; Hyp.cls 6320
asm_1_5940_n_pt_mn:		; Hyp.cls 6321
            djnz asm_1_5940_n_pt_mul		; Hyp.cls 6322
            ld a, (var_hyp_pox)		; Hyp.cls 6323
            ld e, a		; Hyp.cls 6324
            add hl, de		; Hyp.cls 6325
            ld de, (var_hyp_sco)		; Hyp.cls 6326
            add hl, de		; Hyp.cls 6327
            ld a, h		; Hyp.cls 6328
            and #07		; Hyp.cls 6329
            or #C0		; Hyp.cls 6330
            ld h, a		; Hyp.cls 6331
            ld b, 4		; Hyp.cls 6332
asm_1_5940_n_pt_ln:		; Hyp.cls 6333
            ld a, (hl)		; Hyp.cls 6334
            xor #AA		; Hyp.cls 6335
            ld (hl), a		; Hyp.cls 6336
            ld a, h		; Hyp.cls 6337
            add a, 8		; Hyp.cls 6338
            ld h, a		; Hyp.cls 6339
            ld a, (hl)		; Hyp.cls 6340
            xor #55		; Hyp.cls 6341
            ld (hl), a		; Hyp.cls 6342
            ld a, h		; Hyp.cls 6343
            add a, 8		; Hyp.cls 6344
            ld h, a		; Hyp.cls 6345
            djnz asm_1_5940_n_pt_ln		; Hyp.cls 6346
            ret		; Hyp.cls 6347
; 15: a table
asm_1_5940_n_sv_tab:		; Hyp.cls 6349
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 6350
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 6351
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 6352
            or a		; Hyp.cls 6353
            jr z, asm_1_5940_n_sv_t0		; Hyp.cls 6354
            dec a		; Hyp.cls 6355
            jp z, asm_1_5940_n_sv_t1		; Hyp.cls 6356
            dec a		; Hyp.cls 6357
            jp z, asm_1_5940_n_sv_t2		; Hyp.cls 6358
            dec a		; Hyp.cls 6359
            jp z, asm_1_5940_n_sv_t3		; Hyp.cls 6360
            dec a		; Hyp.cls 6361
            jp z, asm_1_5940_n_sv_t4		; Hyp.cls 6362
            jp asm_1_5940_n_sv_err		; Hyp.cls 6363
; 4: the claims - CL_N records of 10 bytes: the slot holding it (0: a free record), the unit,
; the name (8 characters, spaces after it)
asm_1_5940_n_sv_t4:		; Hyp.cls 6366
            ld hl, asm_1_5940_n_sv_cl		; Hyp.cls 6367
            ld de, (asm_1_5940_n_sv_da)		; Hyp.cls 6368
            ld bc, asm_1_5940_n_CL_N * 10		; Hyp.cls 6369
            call asm_1_5940_n_sv_out		; Hyp.cls 6370
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6371
; 0: the slots - a word how many, then from 16 a record each: state, in front, MODE, the name's
; length, the name
asm_1_5940_n_sv_t0:		; Hyp.cls 6374
            call asm_1_5940_n_sv_clr		; Hyp.cls 6375
            ld hl, (var_hyp_svns)		; Hyp.cls 6376
            ld a, (hl)		; Hyp.cls 6377
            ld (asm_1_5940_n_sv_rec), a		; Hyp.cls 6378
            ld (asm_1_5940_n_sv_tn), a		; Hyp.cls 6379
            call asm_1_5940_n_sv_out16		; Hyp.cls 6380
            ld a, 1		; Hyp.cls 6381
            ld (asm_1_5940_n_sv_tj), a		; Hyp.cls 6382
asm_1_5940_n_sv_t0lp:		; Hyp.cls 6383
            ld a, (asm_1_5940_n_sv_tn)		; Hyp.cls 6384
            ld b, a		; Hyp.cls 6385
            ld a, (asm_1_5940_n_sv_tj)		; Hyp.cls 6386
            cp b		; Hyp.cls 6387
            jr z, asm_1_5940_n_sv_t0a		; Hyp.cls 6388
            jp nc, asm_1_5940_n_sv_ok		; Hyp.cls 6389
asm_1_5940_n_sv_t0a:		; Hyp.cls 6390
            ld hl, (asm_1_5940_n_sv_da)		; Hyp.cls 6391
            ld de, 16		; Hyp.cls 6392
            add hl, de		; Hyp.cls 6393
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 6394
            call asm_1_5940_n_sv_clr		; Hyp.cls 6395
            ld a, (asm_1_5940_n_sv_tj)		; Hyp.cls 6396
            ld l, a		; Hyp.cls 6397
            ld h, 0		; Hyp.cls 6398
            add hl, hl		; Hyp.cls 6399
            ld de, (var_hyp_svst)		; Hyp.cls 6400
            add hl, de		; Hyp.cls 6401
            ld a, (hl)		; Hyp.cls 6402
            ld (asm_1_5940_n_sv_rec), a          ; its state [6403]
            ld hl, (var_hyp_svfr)		; Hyp.cls 6404
            ld a, (asm_1_5940_n_sv_tj)		; Hyp.cls 6405
            cp (hl)		; Hyp.cls 6406
            jr nz, asm_1_5940_n_sv_t0b		; Hyp.cls 6407
            ld a, 1		; Hyp.cls 6408
            ld (asm_1_5940_n_sv_rec + 1), a      ; in front [6409]
asm_1_5940_n_sv_t0b:		; Hyp.cls 6410
            ld a, (asm_1_5940_n_sv_rec)		; Hyp.cls 6411
            or a		; Hyp.cls 6412
            jr z, asm_1_5940_n_sv_t0d		; Hyp.cls 6413
            ld a, (asm_1_5940_n_sv_tj)           ; its RAM setting [6414]
            ld l, a		; Hyp.cls 6415
            ld h, 0		; Hyp.cls 6416
            add hl, hl		; Hyp.cls 6417
            ld de, (var_hyp_svsg)		; Hyp.cls 6418
            add hl, de		; Hyp.cls 6419
            ld e, (hl)		; Hyp.cls 6420
            inc hl		; Hyp.cls 6421
            ld d, (hl)		; Hyp.cls 6422
            ld (asm_1_5940_n_sv_tsg), de		; Hyp.cls 6423
            ld hl, 63113          ; MODE [6424]
            ld a, 1		; Hyp.cls 6425
            call asm_1_5940_n_sv_from		; Hyp.cls 6426
            ld a, (asm_1_5940_n_sv_tmp)		; Hyp.cls 6427
            ld (asm_1_5940_n_sv_rec + 2), a		; Hyp.cls 6428
            ld a, (asm_1_5940_n_sv_rec)		; Hyp.cls 6429
            cp 2		; Hyp.cls 6430
            jr nz, asm_1_5940_n_sv_t0d		; Hyp.cls 6431
            ld de, (asm_1_5940_n_sv_tsg)		; Hyp.cls 6432
            ld hl, #F6D8            ; the program's name: its length, then 12 [6433]
            ld a, 13		; Hyp.cls 6434
            call asm_1_5940_n_sv_from		; Hyp.cls 6435
            ld a, (asm_1_5940_n_sv_tmp)		; Hyp.cls 6436
            cp 13		; Hyp.cls 6437
            jr c, asm_1_5940_n_sv_t0c		; Hyp.cls 6438
            ld a, 12		; Hyp.cls 6439
asm_1_5940_n_sv_t0c:		; Hyp.cls 6440
            ld (asm_1_5940_n_sv_rec + 3), a		; Hyp.cls 6441
            ld hl, asm_1_5940_n_sv_tmp + 1		; Hyp.cls 6442
            ld de, asm_1_5940_n_sv_rec + 4		; Hyp.cls 6443
            ld bc, 12		; Hyp.cls 6444
            ldir		; Hyp.cls 6445
asm_1_5940_n_sv_t0d:		; Hyp.cls 6446
            ld hl, asm_1_5940_n_sv_tj		; Hyp.cls 6447
            push hl		; Hyp.cls 6448
            call asm_1_5940_n_sv_out16		; Hyp.cls 6449
            pop hl		; Hyp.cls 6450
            inc (hl)		; Hyp.cls 6451
            jp asm_1_5940_n_sv_t0lp		; Hyp.cls 6452
; 1: the memory - words: the tables' end, the top, the pages, total K, free pages; from 16 a byte a page
asm_1_5940_n_sv_t1:		; Hyp.cls 6454
            call asm_1_5940_n_sv_clr		; Hyp.cls 6455
            ld hl, (mem_tend)		; Hyp.cls 6456
            ld (asm_1_5940_n_sv_rec), hl		; Hyp.cls 6457
            call mem_top		; Hyp.cls 6458
            ld (asm_1_5940_n_sv_rec + 2), hl		; Hyp.cls 6459
            ld hl, (mem_count)		; Hyp.cls 6460
            ld (asm_1_5940_n_sv_rec + 4), hl		; Hyp.cls 6461
            call mem_ramsize		; Hyp.cls 6462
            ld (asm_1_5940_n_sv_rec + 6), hl		; Hyp.cls 6463
            call mem_freepages		; Hyp.cls 6464
            ld (asm_1_5940_n_sv_rec + 8), hl		; Hyp.cls 6465
            ld hl, asm_1_5940_n_sv_rec		; Hyp.cls 6466
            ld de, (asm_1_5940_n_sv_da)		; Hyp.cls 6467
            ld bc, 18               ; (and pages 0, 1: 0) [6468]
            call asm_1_5940_n_sv_out		; Hyp.cls 6469
            ld hl, (mem_count)      ; pages 2 on: the RAT (2030 at most) [6470]
            dec hl		; Hyp.cls 6471
            ld a, h		; Hyp.cls 6472
            or l		; Hyp.cls 6473
            jp z, asm_1_5940_n_sv_ok		; Hyp.cls 6474
            ld de, 2031		; Hyp.cls 6475
            or a		; Hyp.cls 6476
            sbc hl, de		; Hyp.cls 6477
            add hl, de		; Hyp.cls 6478
            jr c, asm_1_5940_n_sv_t1a		; Hyp.cls 6479
            ld hl, 2030		; Hyp.cls 6480
asm_1_5940_n_sv_t1a:		; Hyp.cls 6481
            ld (asm_1_5940_n_sv_n), hl		; Hyp.cls 6482
            ld hl, (mem_ttype)		; Hyp.cls 6483
            inc hl		; Hyp.cls 6484
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 6485
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 6486
            ld de, 18		; Hyp.cls 6487
            add hl, de		; Hyp.cls 6488
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 6489
            xor a		; Hyp.cls 6490
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 6491
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 6492
            call asm_1_5940_n_sv_copy		; Hyp.cls 6493
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6494
; 2: the upper ROMs 0-31 - 64 bytes each: the first 16, then 48 of the name table (0s if none)
asm_1_5940_n_sv_t2:		; Hyp.cls 6496
    IFDEF NTC_MSXDOS		; Hyp.cls 6497
            jp asm_1_5940_n_sv_err               ; zxn: no upper ROMs [6498]
    ENDIF		; Hyp.cls 6499
            xor a		; Hyp.cls 6500
            ld (asm_1_5940_n_sv_tj), a		; Hyp.cls 6501
asm_1_5940_n_sv_t2lp:		; Hyp.cls 6502
            call asm_1_5940_n_sv_clr		; Hyp.cls 6503
            ld a, (asm_1_5940_n_sv_tj)		; Hyp.cls 6504
            ld c, a		; Hyp.cls 6505
            call #B90F              ; KL ROM SELECT (#C000 only: this code at #6000 stays) [6506]
            di		; Hyp.cls 6507
            push bc		; Hyp.cls 6508
            ld hl, #C000		; Hyp.cls 6509
            ld de, asm_1_5940_n_sv_rec		; Hyp.cls 6510
            ld bc, 16		; Hyp.cls 6511
            ldir		; Hyp.cls 6512
            ld hl, (asm_1_5940_n_sv_rec + 4)		; Hyp.cls 6513
            ld a, h		; Hyp.cls 6514
            and #C0		; Hyp.cls 6515
            cp #C0		; Hyp.cls 6516
            jr nz, asm_1_5940_n_sv_t2a		; Hyp.cls 6517
            ld de, #FF90		; Hyp.cls 6518
            or a		; Hyp.cls 6519
            sbc hl, de		; Hyp.cls 6520
            add hl, de		; Hyp.cls 6521
            jr nc, asm_1_5940_n_sv_t2a		; Hyp.cls 6522
            ld de, asm_1_5940_n_sv_rec + 16		; Hyp.cls 6523
            ld bc, 48		; Hyp.cls 6524
            ldir		; Hyp.cls 6525
asm_1_5940_n_sv_t2a:		; Hyp.cls 6526
            pop bc		; Hyp.cls 6527
            call #B918              ; KL ROM DESELECT [6528]
            di		; Hyp.cls 6529
            ld hl, asm_1_5940_n_sv_rec		; Hyp.cls 6530
            ld de, (asm_1_5940_n_sv_da)		; Hyp.cls 6531
            ld bc, 64		; Hyp.cls 6532
            call asm_1_5940_n_sv_out		; Hyp.cls 6533
            ld hl, (asm_1_5940_n_sv_da)		; Hyp.cls 6534
            ld de, 64		; Hyp.cls 6535
            add hl, de		; Hyp.cls 6536
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 6537
            ld hl, asm_1_5940_n_sv_tj		; Hyp.cls 6538
            inc (hl)		; Hyp.cls 6539
            ld a, (hl)		; Hyp.cls 6540
            cp 32		; Hyp.cls 6541
            jr c, asm_1_5940_n_sv_t2lp		; Hyp.cls 6542
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6543
; 3: the RAM discs - the driver's table (its page, #6A00: 128 bytes), 0s if none
asm_1_5940_n_sv_t3:		; Hyp.cls 6545
            call asm_1_5940_n_sv_clr		; Hyp.cls 6546
            ld hl, (var_hyp_svdp)		; Hyp.cls 6547
            ld e, (hl)		; Hyp.cls 6548
            inc hl		; Hyp.cls 6549
            ld d, (hl)		; Hyp.cls 6550
            ld a, d		; Hyp.cls 6551
            or e		; Hyp.cls 6552
            jr z, asm_1_5940_n_sv_t3a		; Hyp.cls 6553
            ex de, hl		; Hyp.cls 6554
            call asm_1_5940_n_sv_pgset		; Hyp.cls 6555
            ld (asm_1_5940_n_sv_ss), bc		; Hyp.cls 6556
            ld hl, #6A00		; Hyp.cls 6557
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 6558
            ld hl, 128		; Hyp.cls 6559
            ld (asm_1_5940_n_sv_n), hl		; Hyp.cls 6560
            ld a, 1		; Hyp.cls 6561
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 6562
            xor a		; Hyp.cls 6563
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 6564
            call asm_1_5940_n_sv_copy		; Hyp.cls 6565
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6566
asm_1_5940_n_sv_t3a:		; Hyp.cls 6567
            ld hl, asm_1_5940_n_sv_rec		; Hyp.cls 6568
            ld de, (asm_1_5940_n_sv_da)		; Hyp.cls 6569
            ld bc, 128		; Hyp.cls 6570
            call asm_1_5940_n_sv_out		; Hyp.cls 6571
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6572
; sv_from - A bytes from slot (sv_tsg's) HL into sv_tmp
asm_1_5940_n_sv_from:		; Hyp.cls 6574
            ld de, (asm_1_5940_n_sv_tsg)		; Hyp.cls 6575
            push af		; Hyp.cls 6576
            call asm_1_5940_n_sv_sw		; Hyp.cls 6577
            push bc		; Hyp.cls 6578
            pop ix		; Hyp.cls 6579
            ld iy, (var_hyp_svp)		; Hyp.cls 6580
            ld de, asm_1_5940_n_sv_tmp		; Hyp.cls 6581
            pop af		; Hyp.cls 6582
            jp asm_1_5940_n_sv_dx		; Hyp.cls 6583
; sv_clr - sv_rec (128 bytes) 0
asm_1_5940_n_sv_clr:		; Hyp.cls 6585
            ld hl, asm_1_5940_n_sv_rec		; Hyp.cls 6586
            ld de, asm_1_5940_n_sv_rec + 1		; Hyp.cls 6587
            ld bc, 127		; Hyp.cls 6588
            ld (hl), 0		; Hyp.cls 6589
            ldir		; Hyp.cls 6590
            ret		; Hyp.cls 6591
; sv_out16 - sv_rec's first 16 to the slot at sv_da; sv_out - BC bytes from HL (here) to the slot's DE
asm_1_5940_n_sv_out16:		; Hyp.cls 6593
            ld hl, asm_1_5940_n_sv_rec		; Hyp.cls 6594
            ld de, (asm_1_5940_n_sv_da)		; Hyp.cls 6595
            ld bc, 16		; Hyp.cls 6596
asm_1_5940_n_sv_out:		; Hyp.cls 6597
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 6598
            ld (asm_1_5940_n_sv_da), de		; Hyp.cls 6599
            ld (asm_1_5940_n_sv_n), bc		; Hyp.cls 6600
            ld a, 1		; Hyp.cls 6601
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 6602
            ld hl, (var_hyp_svp)		; Hyp.cls 6603
            ld (asm_1_5940_n_sv_ss), hl		; Hyp.cls 6604
            xor a		; Hyp.cls 6605
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 6606
            ld hl, (asm_1_5940_n_sv_da)		; Hyp.cls 6607
            push hl		; Hyp.cls 6608
            call asm_1_5940_n_sv_copy		; Hyp.cls 6609
            pop hl		; Hyp.cls 6610
            ld (asm_1_5940_n_sv_da), hl          ; (where it went: kept) [6611]
            ret		; Hyp.cls 6612
; sv_copy - sv_n bytes from the source (sv_sk: 0 main RAM outside the window, 1 a page - RAM setting
; sv_ss, 2 a bank - C2 setting sv_ss, 3 ROM sv_ss, 4 main RAM anywhere) at sv_sa to the
; destination (sv_dk: 1 a page, 2 a bank; sv_ds) at sv_da, 128 at most a go, none across a 16K
; page's end; sv_stop: at the source's page end, stop
asm_1_5940_n_sv_copy:		; Hyp.cls 6617
            ld hl, (asm_1_5940_n_sv_n)		; Hyp.cls 6618
            ld a, h		; Hyp.cls 6619
            or l		; Hyp.cls 6620
            ret z		; Hyp.cls 6621
            ld bc, 128		; Hyp.cls 6622
            or a		; Hyp.cls 6623
            sbc hl, bc		; Hyp.cls 6624
            add hl, bc		; Hyp.cls 6625
            jr nc, asm_1_5940_n_sc_c1		; Hyp.cls 6626
            ld b, h		; Hyp.cls 6627
            ld c, l		; Hyp.cls 6628
asm_1_5940_n_sc_c1:		; Hyp.cls 6629
            ld (asm_1_5940_n_sv_c), bc		; Hyp.cls 6630
            ld a, (asm_1_5940_n_sv_sk)		; Hyp.cls 6631
            or a		; Hyp.cls 6632
            jr z, asm_1_5940_n_sc_dl		; Hyp.cls 6633
            ld hl, (asm_1_5940_n_sv_sa)		; Hyp.cls 6634
            call asm_1_5940_n_sc_room		; Hyp.cls 6635
asm_1_5940_n_sc_dl:		; Hyp.cls 6636
            ld hl, (asm_1_5940_n_sv_da)		; Hyp.cls 6637
            call asm_1_5940_n_sc_room		; Hyp.cls 6638
            ld a, (asm_1_5940_n_sv_sk)           ; the source: IX its RAM setting, HL where [6639]
            ld hl, (asm_1_5940_n_sv_sa)		; Hyp.cls 6640
            ld ix, 0		; Hyp.cls 6641
            or a		; Hyp.cls 6642
            jr z, asm_1_5940_n_sc_sok		; Hyp.cls 6643
            cp 1		; Hyp.cls 6644
            jr nz, asm_1_5940_n_sc_s2		; Hyp.cls 6645
            ld ix, (asm_1_5940_n_sv_ss)		; Hyp.cls 6646
            call asm_1_5940_n_sc_win		; Hyp.cls 6647
            jr asm_1_5940_n_sc_sok		; Hyp.cls 6648
asm_1_5940_n_sc_s2:		; Hyp.cls 6649
            cp 2		; Hyp.cls 6650
            jr nz, asm_1_5940_n_sc_s3		; Hyp.cls 6651
            ld de, (asm_1_5940_n_sv_ss)		; Hyp.cls 6652
            call asm_1_5940_n_sv_sw		; Hyp.cls 6653
            push bc		; Hyp.cls 6654
            pop ix		; Hyp.cls 6655
            jr asm_1_5940_n_sc_sok		; Hyp.cls 6656
asm_1_5940_n_sc_s3:		; Hyp.cls 6657
            cp 3		; Hyp.cls 6658
            jr nz, asm_1_5940_n_sc_s4		; Hyp.cls 6659
    IFDEF NTC_MSXDOS		; Hyp.cls 6660
            jp asm_1_5940_n_sv_err               ; zxn: no upper ROMs [6661]
    ENDIF		; Hyp.cls 6662
            ld a, (asm_1_5940_n_sv_ss)           ; a ROM: its bytes into buf first [6663]
            ld c, a		; Hyp.cls 6664
            call #B90F              ; KL ROM SELECT [6665]
            di		; Hyp.cls 6666
            push bc		; Hyp.cls 6667
            ld hl, (asm_1_5940_n_sv_sa)		; Hyp.cls 6668
            ld a, h		; Hyp.cls 6669
            or #C0		; Hyp.cls 6670
            ld h, a		; Hyp.cls 6671
            ld de, (var_hyp_svc_buf)		; Hyp.cls 6672
            ld bc, (asm_1_5940_n_sv_c)		; Hyp.cls 6673
            ldir		; Hyp.cls 6674
            pop bc		; Hyp.cls 6675
            call #B918              ; KL ROM DESELECT [6676]
            di		; Hyp.cls 6677
            ld hl, (var_hyp_svc_buf)		; Hyp.cls 6678
            jr asm_1_5940_n_sc_sok		; Hyp.cls 6679
asm_1_5940_n_sc_s4:		; Hyp.cls 6680
            ld a, h                 ; main RAM: its #4000-#7FFF is page 1 [6681]
            and #C0		; Hyp.cls 6682
            cp #40		; Hyp.cls 6683
            jr nz, asm_1_5940_n_sc_sok		; Hyp.cls 6684
            push hl		; Hyp.cls 6685
            ld hl, 1		; Hyp.cls 6686
            call asm_1_5940_n_sv_pgset		; Hyp.cls 6687
            pop hl		; Hyp.cls 6688
            push bc		; Hyp.cls 6689
            pop ix		; Hyp.cls 6690
asm_1_5940_n_sc_sok:		; Hyp.cls 6691
            push hl		; Hyp.cls 6692
            ld a, (asm_1_5940_n_sv_dk)           ; the destination: IY, DE [6693]
            ld hl, (asm_1_5940_n_sv_da)		; Hyp.cls 6694
            cp 1		; Hyp.cls 6695
            jr nz, asm_1_5940_n_sc_d2		; Hyp.cls 6696
            ld iy, (asm_1_5940_n_sv_ds)		; Hyp.cls 6697
            call asm_1_5940_n_sc_win		; Hyp.cls 6698
            jr asm_1_5940_n_sc_dok		; Hyp.cls 6699
asm_1_5940_n_sc_d2:		; Hyp.cls 6700
            ld de, (asm_1_5940_n_sv_ds)		; Hyp.cls 6701
            call asm_1_5940_n_sv_sw		; Hyp.cls 6702
            push bc		; Hyp.cls 6703
            pop iy		; Hyp.cls 6704
asm_1_5940_n_sc_dok:		; Hyp.cls 6705
            ex de, hl		; Hyp.cls 6706
            pop hl		; Hyp.cls 6707
            ld a, (asm_1_5940_n_sv_c)		; Hyp.cls 6708
            call asm_1_5940_n_sv_dx		; Hyp.cls 6709
            ld bc, (asm_1_5940_n_sv_c)		; Hyp.cls 6710
            ld hl, (asm_1_5940_n_sv_sa)		; Hyp.cls 6711
            add hl, bc		; Hyp.cls 6712
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 6713
            ld hl, (asm_1_5940_n_sv_da)		; Hyp.cls 6714
            add hl, bc		; Hyp.cls 6715
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 6716
            ld hl, (asm_1_5940_n_sv_n)		; Hyp.cls 6717
            or a		; Hyp.cls 6718
            sbc hl, bc		; Hyp.cls 6719
            ld (asm_1_5940_n_sv_n), hl		; Hyp.cls 6720
            ld a, (asm_1_5940_n_sv_stop)		; Hyp.cls 6721
            or a		; Hyp.cls 6722
            jp z, asm_1_5940_n_sv_copy		; Hyp.cls 6723
            ld a, (asm_1_5940_n_sv_sa + 1)		; Hyp.cls 6724
            and #3F		; Hyp.cls 6725
            ld b, a		; Hyp.cls 6726
            ld a, (asm_1_5940_n_sv_sa)		; Hyp.cls 6727
            or b		; Hyp.cls 6728
            jp nz, asm_1_5940_n_sv_copy		; Hyp.cls 6729
            ret		; Hyp.cls 6730
asm_1_5940_n_sc_room:                            ; sv_c no more than to HL's 16K page's end [6731]
            ld a, h		; Hyp.cls 6732
            and #3F		; Hyp.cls 6733
            ld h, a		; Hyp.cls 6734
            ex de, hl		; Hyp.cls 6735
            ld hl, 16384		; Hyp.cls 6736
            or a		; Hyp.cls 6737
            sbc hl, de		; Hyp.cls 6738
            ld de, (asm_1_5940_n_sv_c)		; Hyp.cls 6739
            or a		; Hyp.cls 6740
            sbc hl, de		; Hyp.cls 6741
            ret nc		; Hyp.cls 6742
            add hl, de		; Hyp.cls 6743
            ld (asm_1_5940_n_sv_c), hl		; Hyp.cls 6744
            ret		; Hyp.cls 6745
asm_1_5940_n_sc_win:                             ; HL: its place in the window [6746]
            ld a, h		; Hyp.cls 6747
            and #3F		; Hyp.cls 6748
            or #40		; Hyp.cls 6749
            ld h, a		; Hyp.cls 6750
            ret		; Hyp.cls 6751
; sv_sw - DE = a bank's C2 setting, HL = an address in it: BC = the setting with its page in the
; window, HL = the address there
asm_1_5940_n_sv_sw:		; Hyp.cls 6754
            ld a, h		; Hyp.cls 6755
            rlca		; Hyp.cls 6756
            rlca		; Hyp.cls 6757
            and 3		; Hyp.cls 6758
            add a, 4		; Hyp.cls 6759
            ld b, a		; Hyp.cls 6760
            ld a, e		; Hyp.cls 6761
            and #F8		; Hyp.cls 6762
            or b		; Hyp.cls 6763
            ld c, a		; Hyp.cls 6764
            ld b, d		; Hyp.cls 6765
            jr asm_1_5940_n_sc_win		; Hyp.cls 6766
; sv_pgset - HL = a page: BC = its RAM setting (the Memory class's port table; 0 main RAM)
asm_1_5940_n_sv_pgset:		; Hyp.cls 6768
            ld a, h		; Hyp.cls 6769
            or l		; Hyp.cls 6770
            ld bc, #7FC0		; Hyp.cls 6771
            ret z		; Hyp.cls 6772
            add hl, hl		; Hyp.cls 6773
            ld de, (mem_tport)		; Hyp.cls 6774
            add hl, de		; Hyp.cls 6775
            dec hl		; Hyp.cls 6776
            ld b, (hl)		; Hyp.cls 6777
            dec hl		; Hyp.cls 6778
            ld c, (hl)		; Hyp.cls 6779
            ret		; Hyp.cls 6780
; ---- 16-19: the claims - hardware a program drives itself (FDC, SOUND, MF2, NVRAM, M4 ...): a
; name (Byte(2-9): 8 characters, spaces after) and a unit (Byte(1): which of them - a LUN), held
; by one slot at a time; all a slot's freed when its program ends, is killed or reset (p 0). The
; answer: 16 claim - 0 yours (now, or already), else the slot holding it (255: CL_N in use);
; 17 release - 0 done, 1 not yours; 18 take - yours now, whoever had it: the slot that had it
; (0 nobody); 19 held - 0 yours, else the slot holding it (254 nobody)
asm_1_5940_n_CL_N:       equ 16		; Hyp.cls 6787
asm_1_5940_n_sv_claim:		; Hyp.cls 6788
            ld b, a                 ; B = the op [6789]
            call asm_1_5940_n_cl_find            ; Z: HL = its record [6790]
            ld a, (var_hyp_svc_t)		; Hyp.cls 6791
            ld c, a                 ; C = this slot [6792]
            jr nz, asm_1_5940_n_cl_none		; Hyp.cls 6793
            ld a, b		; Hyp.cls 6794
            cp 17		; Hyp.cls 6795
            jr z, asm_1_5940_n_cl_rel		; Hyp.cls 6796
            ld a, (hl)              ; who has it [6797]
            ld (asm_1_5940_n_sv_tn), a		; Hyp.cls 6798
            ld a, b		; Hyp.cls 6799
            cp 18		; Hyp.cls 6800
            jr nz, asm_1_5940_n_cl_who		; Hyp.cls 6801
            ld (hl), c              ; 18: taken [6802]
            ld a, (asm_1_5940_n_sv_tn)		; Hyp.cls 6803
            jr asm_1_5940_n_cl_ret		; Hyp.cls 6804
asm_1_5940_n_cl_who:		; Hyp.cls 6805
            ld a, (asm_1_5940_n_sv_tn)           ; 16, 19: 0 when it is this slot's [6806]
            cp c		; Hyp.cls 6807
            jp z, asm_1_5940_n_sv_ok		; Hyp.cls 6808
            jr asm_1_5940_n_cl_ret		; Hyp.cls 6809
asm_1_5940_n_cl_rel:		; Hyp.cls 6810
            ld a, (hl)		; Hyp.cls 6811
            cp c		; Hyp.cls 6812
            jr nz, asm_1_5940_n_cl_one		; Hyp.cls 6813
            ld (hl), 0		; Hyp.cls 6814
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6815
asm_1_5940_n_cl_none:		; Hyp.cls 6816
            ld a, b		; Hyp.cls 6817
            cp 17		; Hyp.cls 6818
            jr z, asm_1_5940_n_cl_one		; Hyp.cls 6819
            cp 19		; Hyp.cls 6820
            ld a, 254		; Hyp.cls 6821
            jr z, asm_1_5940_n_cl_ret		; Hyp.cls 6822
            ld hl, asm_1_5940_n_sv_cl            ; 16, 18: into a free record [6823]
            ld de, 10		; Hyp.cls 6824
            ld b, asm_1_5940_n_CL_N		; Hyp.cls 6825
asm_1_5940_n_cl_fr:		; Hyp.cls 6826
            ld a, (hl)		; Hyp.cls 6827
            or a		; Hyp.cls 6828
            jr z, asm_1_5940_n_cl_put		; Hyp.cls 6829
            add hl, de		; Hyp.cls 6830
            djnz asm_1_5940_n_cl_fr		; Hyp.cls 6831
            jp asm_1_5940_n_sv_err		; Hyp.cls 6832
asm_1_5940_n_cl_put:		; Hyp.cls 6833
            ld (hl), c		; Hyp.cls 6834
            inc hl		; Hyp.cls 6835
            ex de, hl		; Hyp.cls 6836
            ld hl, asm_1_5940_n_sv_blk + 1		; Hyp.cls 6837
            ld bc, 9		; Hyp.cls 6838
            ldir		; Hyp.cls 6839
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6840
asm_1_5940_n_cl_one:		; Hyp.cls 6841
            ld a, 1		; Hyp.cls 6842
asm_1_5940_n_cl_ret:		; Hyp.cls 6843
            ld sp, (asm_1_5940_n_sv_sp)		; Hyp.cls 6844
            ret		; Hyp.cls 6845
; cl_find - Z: HL = the record with sv_blk's unit and name, else NZ (B kept)
asm_1_5940_n_cl_find:		; Hyp.cls 6847
            ld hl, asm_1_5940_n_sv_cl		; Hyp.cls 6848
            ld c, asm_1_5940_n_CL_N		; Hyp.cls 6849
asm_1_5940_n_cl_f1:		; Hyp.cls 6850
            ld a, (hl)		; Hyp.cls 6851
            or a		; Hyp.cls 6852
            jr z, asm_1_5940_n_cl_f3             ; (a free record) [6853]
            push hl		; Hyp.cls 6854
            push bc		; Hyp.cls 6855
            inc hl		; Hyp.cls 6856
            ld de, asm_1_5940_n_sv_blk + 1		; Hyp.cls 6857
            ld b, 9		; Hyp.cls 6858
asm_1_5940_n_cl_f2:		; Hyp.cls 6859
            ld a, (de)		; Hyp.cls 6860
            cp (hl)		; Hyp.cls 6861
            jr nz, asm_1_5940_n_cl_f4		; Hyp.cls 6862
            inc hl		; Hyp.cls 6863
            inc de		; Hyp.cls 6864
            djnz asm_1_5940_n_cl_f2		; Hyp.cls 6865
asm_1_5940_n_cl_f4:		; Hyp.cls 6866
            pop bc		; Hyp.cls 6867
            pop hl		; Hyp.cls 6868
            ret z		; Hyp.cls 6869
asm_1_5940_n_cl_f3:		; Hyp.cls 6870
            ld de, 10		; Hyp.cls 6871
            add hl, de		; Hyp.cls 6872
            dec c		; Hyp.cls 6873
            jr nz, asm_1_5940_n_cl_f1		; Hyp.cls 6874
            or 1		; Hyp.cls 6875
            ret		; Hyp.cls 6876
; p 0: slot t's claims all freed
asm_1_5940_n_sv_cfree:		; Hyp.cls 6878
            ld a, (var_hyp_svc_t)		; Hyp.cls 6879
            ld c, a		; Hyp.cls 6880
            ld hl, asm_1_5940_n_sv_cl		; Hyp.cls 6881
            ld de, 10		; Hyp.cls 6882
            ld b, asm_1_5940_n_CL_N		; Hyp.cls 6883
asm_1_5940_n_cl_cf:		; Hyp.cls 6884
            ld a, (hl)		; Hyp.cls 6885
            cp c		; Hyp.cls 6886
            jr nz, asm_1_5940_n_cl_cf1		; Hyp.cls 6887
            ld (hl), 0		; Hyp.cls 6888
asm_1_5940_n_cl_cf1:		; Hyp.cls 6889
            add hl, de		; Hyp.cls 6890
            djnz asm_1_5940_n_cl_cf		; Hyp.cls 6891
            call asm_1_5940_n_pt_free            ; its ports closed, its calls forgotten (C = the slot) [6892]
            ld a, (asm_1_5940_n_nt_rom)          ; its sockets closed [6893]
            inc a		; Hyp.cls 6894
            jp z, asm_1_5940_n_sv_ok		; Hyp.cls 6895
            ld b, 0		; Hyp.cls 6896
asm_1_5940_n_cl_cs:		; Hyp.cls 6897
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 6898
            ld e, b		; Hyp.cls 6899
            ld d, 0		; Hyp.cls 6900
            add hl, de		; Hyp.cls 6901
            ld a, (hl)		; Hyp.cls 6902
            cp c		; Hyp.cls 6903
            jr nz, asm_1_5940_n_cl_cs1		; Hyp.cls 6904
            push bc		; Hyp.cls 6905
            ld a, b		; Hyp.cls 6906
            call asm_1_5940_n_nt_close		; Hyp.cls 6907
            pop bc		; Hyp.cls 6908
asm_1_5940_n_cl_cs1:		; Hyp.cls 6909
            inc b		; Hyp.cls 6910
            ld a, b		; Hyp.cls 6911
            cp 8		; Hyp.cls 6912
            jr c, asm_1_5940_n_cl_cs		; Hyp.cls 6913
            jp asm_1_5940_n_sv_ok		; Hyp.cls 6914
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
asm_1_5940_n_NT_N:       equ 8                   ; sockets 0-7 [6936]
asm_1_5940_n_sv_net:		; Hyp.cls 6937
    IFDEF NTC_MSXDOS		; Hyp.cls 6938
            jp asm_1_5940_n_es_net               ; zxn: the ESP (below) [6939]
    ENDIF		; Hyp.cls 6940
            ld b, a		; Hyp.cls 6941
            cp 20		; Hyp.cls 6942
            jr z, asm_1_5940_n_nt_20		; Hyp.cls 6943
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 6944
            inc a		; Hyp.cls 6945
            jp z, asm_1_5940_n_sv_err            ; (no network) [6946]
            ld a, b		; Hyp.cls 6947
            cp 21		; Hyp.cls 6948
            jp z, asm_1_5940_n_nt_look		; Hyp.cls 6949
            cp 23		; Hyp.cls 6950
            jp z, asm_1_5940_n_nt_sock		; Hyp.cls 6951
            call asm_1_5940_n_nt_chk             ; (the rest: one of the slot's sockets) [6952]
            ld a, b		; Hyp.cls 6953
            cp 22		; Hyp.cls 6954
            jp z, asm_1_5940_n_nt_stat		; Hyp.cls 6955
            cp 24		; Hyp.cls 6956
            jp z, asm_1_5940_n_nt_conn		; Hyp.cls 6957
            cp 25		; Hyp.cls 6958
            jp z, asm_1_5940_n_nt_send		; Hyp.cls 6959
            cp 26		; Hyp.cls 6960
            jp z, asm_1_5940_n_nt_recv		; Hyp.cls 6961
            ld a, (asm_1_5940_n_sv_blk + 1)      ; 27 [6962]
            call asm_1_5940_n_nt_close		; Hyp.cls 6963
            jp asm_1_5940_n_nt_ans		; Hyp.cls 6964
asm_1_5940_n_nt_20:		; Hyp.cls 6965
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 6966
            or a		; Hyp.cls 6967
            jr nz, asm_1_5940_n_nt_20a		; Hyp.cls 6968
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 6969
            jp asm_1_5940_n_nt_ret		; Hyp.cls 6970
asm_1_5940_n_nt_20a:		; Hyp.cls 6971
            cp 7		; Hyp.cls 6972
            jp z, asm_1_5940_n_nt_shared		; Hyp.cls 6973
            cp 6		; Hyp.cls 6974
            jp z, asm_1_5940_n_nt_boot		; Hyp.cls 6975
            cp 5		; Hyp.cls 6976
            jp z, asm_1_5940_n_nt_host		; Hyp.cls 6977
            cp 4		; Hyp.cls 6978
            jr z, asm_1_5940_n_nt_uptime		; Hyp.cls 6979
            cp 3		; Hyp.cls 6980
            jr z, asm_1_5940_n_nt_time		; Hyp.cls 6981
            dec a		; Hyp.cls 6982
            jp nz, asm_1_5940_n_nt_off		; Hyp.cls 6983
    IFDEF NTC_MSXDOS		; Hyp.cls 6984
            jp asm_1_5940_n_sv_err               ; zxn: no M4 (the Next's own network is to come) [6985]
    ENDIF		; Hyp.cls 6986
            ld a, (asm_1_5940_n_sv_blk + 2)      ; on: the M4's ROM, where its answers and sockets are [6987]
            ld (asm_1_5940_n_nt_rom), a		; Hyp.cls 6988
            ld a, 1                 ; the network indicator: up [6989]
            ld (var_hyp_ntu), a		; Hyp.cls 6990
            ld hl, #FF02		; Hyp.cls 6991
            ld de, asm_1_5940_n_nt_rsp		; Hyp.cls 6992
            ld bc, 2		; Hyp.cls 6993
            call asm_1_5940_n_nt_rd		; Hyp.cls 6994
            ld hl, #FF06		; Hyp.cls 6995
            ld de, asm_1_5940_n_nt_skt		; Hyp.cls 6996
            ld bc, 2		; Hyp.cls 6997
            call asm_1_5940_n_nt_rd		; Hyp.cls 6998
            ld c, 255               ; M4 0: CyborgOS's [6999]
            call asm_1_5940_n_nt_m4c		; Hyp.cls 7000
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7001
asm_1_5940_n_nt_off:		; Hyp.cls 7002
    IFDEF NTC_MSXDOS		; Hyp.cls 7003
            jp asm_1_5940_n_sv_ok                ; zxn: nothing to close [7004]
    ENDIF		; Hyp.cls 7005
            ld b, 0                 ; off: every socket closed, M4 0 given back [7006]
asm_1_5940_n_nt_of1:		; Hyp.cls 7007
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 7008
            ld e, b		; Hyp.cls 7009
            ld d, 0		; Hyp.cls 7010
            add hl, de		; Hyp.cls 7011
            ld a, (hl)		; Hyp.cls 7012
            or a		; Hyp.cls 7013
            jr z, asm_1_5940_n_nt_of2		; Hyp.cls 7014
            push bc		; Hyp.cls 7015
            ld a, b		; Hyp.cls 7016
            call asm_1_5940_n_nt_close		; Hyp.cls 7017
            pop bc		; Hyp.cls 7018
asm_1_5940_n_nt_of2:		; Hyp.cls 7019
            inc b		; Hyp.cls 7020
            ld a, b		; Hyp.cls 7021
            cp asm_1_5940_n_NT_N		; Hyp.cls 7022
            jr c, asm_1_5940_n_nt_of1		; Hyp.cls 7023
            ld c, 0		; Hyp.cls 7024
            call asm_1_5940_n_nt_m4c		; Hyp.cls 7025
            ld a, 255		; Hyp.cls 7026
            ld (asm_1_5940_n_nt_rom), a		; Hyp.cls 7027
            xor a                   ; the network indicator: off [7028]
            ld (var_hyp_ntu), a		; Hyp.cls 7029
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7030
asm_1_5940_n_nt_time:		; Hyp.cls 7031
    IFDEF NTC_MSXDOS		; Hyp.cls 7032
            call msx_t300               ; zxn: the interrupt count (300 a second, as the CPC's) [7033]
    ELSE		; Hyp.cls 7034
            call #BD0D              ; 3: KL TIME PLEASE - its low word (300 a second) to Word(6) [7035]
            di		; Hyp.cls 7036
    ENDIF		; Hyp.cls 7037
            ld (asm_1_5940_n_sv_tmp + 4), hl		; Hyp.cls 7038
            ld hl, (var_hyp_svc_p)		; Hyp.cls 7039
            ld de, 6		; Hyp.cls 7040
            add hl, de		; Hyp.cls 7041
            ex de, hl		; Hyp.cls 7042
            ld hl, asm_1_5940_n_sv_tmp + 4		; Hyp.cls 7043
            ld bc, 2		; Hyp.cls 7044
            call asm_1_5940_n_sv_out		; Hyp.cls 7045
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7046
asm_1_5940_n_nt_uptime:		; Hyp.cls 7047
    IFDEF NTC_MSXDOS		; Hyp.cls 7048
            call msx_t300               ; zxn: the interrupt count (16 bits: wraps at 65536 / 300 s) [7049]
            ld de, 0		; Hyp.cls 7050
    ELSE		; Hyp.cls 7051
            call #BD0D              ; 4: KL TIME PLEASE - all 32 bits (300 a second since the reset) to Word(6), Word(8) [7052]
            di		; Hyp.cls 7053
    ENDIF		; Hyp.cls 7054
            ld (asm_1_5940_n_sv_tmp + 4), hl		; Hyp.cls 7055
            ld (asm_1_5940_n_sv_tmp + 6), de		; Hyp.cls 7056
            ld hl, (var_hyp_svc_p)		; Hyp.cls 7057
            ld de, 6		; Hyp.cls 7058
            add hl, de		; Hyp.cls 7059
            ex de, hl		; Hyp.cls 7060
            ld hl, asm_1_5940_n_sv_tmp + 4		; Hyp.cls 7061
            ld bc, 4		; Hyp.cls 7062
            call asm_1_5940_n_sv_out		; Hyp.cls 7063
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7064
asm_1_5940_n_nt_ans:		; Hyp.cls 7065
            ld a, (asm_1_5940_n_sv_tmp + 3)      ; the M4's answer [7066]
asm_1_5940_n_nt_ret:		; Hyp.cls 7067
            ld sp, (asm_1_5940_n_sv_sp)		; Hyp.cls 7068
            ret		; Hyp.cls 7069
asm_1_5940_n_nt_boot:                            ; 6: the boot drive's letter (CybSys.BootDrive: A, or the Next's D = [7070]
            ld a, (var_hyp_svbd)          ; C:CYBORGOS/): CD on it gives the slot a free letter, as on A and B [7071]
            jp asm_1_5940_n_nt_ret               ; (the letter is every slot's: its path changed would move them all) [7072]
asm_1_5940_n_nt_shared:                          ; 7: the other slots (open) on drive letter Byte(2) - their dv(), [7073]
            ld a, (var_hyp_svc_t)             ; 0 being the boot drive's (CybSys.Shared: CD moves a letter only [7074]
            ld c, a                 ; nobody else is on - a letter's path is every slot's) [7075]
            ld b, 0                 ; B = the count [7076]
            ld hl, (var_hyp_svns)		; Hyp.cls 7077
            ld a, (hl)		; Hyp.cls 7078
            or a		; Hyp.cls 7079
            jr z, asm_1_5940_n_ns_end		; Hyp.cls 7080
            ld e, a                 ; E = the slot [7081]
asm_1_5940_n_ns_lp:		; Hyp.cls 7082
            ld a, e		; Hyp.cls 7083
            cp c		; Hyp.cls 7084
            jr z, asm_1_5940_n_ns_nx		; Hyp.cls 7085
            ld l, e		; Hyp.cls 7086
            ld h, 0		; Hyp.cls 7087
            add hl, hl		; Hyp.cls 7088
            push hl		; Hyp.cls 7089
            push de		; Hyp.cls 7090
            ld de, (var_hyp_svst)		; Hyp.cls 7091
            add hl, de		; Hyp.cls 7092
            ld a, (hl)		; Hyp.cls 7093
            pop de		; Hyp.cls 7094
            pop hl		; Hyp.cls 7095
            or a		; Hyp.cls 7096
            jr z, asm_1_5940_n_ns_nx		; Hyp.cls 7097
            push de		; Hyp.cls 7098
            ld de, (var_hyp_svdv)		; Hyp.cls 7099
            add hl, de		; Hyp.cls 7100
            pop de		; Hyp.cls 7101
            ld a, (hl)		; Hyp.cls 7102
            or a		; Hyp.cls 7103
            jr nz, asm_1_5940_n_ns_d		; Hyp.cls 7104
            ld a, (var_hyp_svbd)		; Hyp.cls 7105
asm_1_5940_n_ns_d:		; Hyp.cls 7106
            ld d, a		; Hyp.cls 7107
            ld a, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7108
            cp d		; Hyp.cls 7109
            jr nz, asm_1_5940_n_ns_nx		; Hyp.cls 7110
            inc b		; Hyp.cls 7111
asm_1_5940_n_ns_nx:		; Hyp.cls 7112
            dec e		; Hyp.cls 7113
            jr nz, asm_1_5940_n_ns_lp		; Hyp.cls 7114
asm_1_5940_n_ns_end:		; Hyp.cls 7115
            ld a, b		; Hyp.cls 7116
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7117
asm_1_5940_n_nt_host:                            ; 5: the host machine (CybSys.Host): 0 an Amstrad CPC, 1 a ZX Spectrum Next [7118]
    IFDEF NTC_MSXDOS		; Hyp.cls 7119
            ld a, 1		; Hyp.cls 7120
    ELSE		; Hyp.cls 7121
            xor a		; Hyp.cls 7122
    ENDIF		; Hyp.cls 7123
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7124
; 21: a name looked up
asm_1_5940_n_nt_look:		; Hyp.cls 7126
            ld a, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7127
            cp 64		; Hyp.cls 7128
            jp nc, asm_1_5940_n_sv_err		; Hyp.cls 7129
            ld c, a		; Hyp.cls 7130
            ld b, 0		; Hyp.cls 7131
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7132
            ld de, asm_1_5940_n_nt_pk + 3		; Hyp.cls 7133
            push bc		; Hyp.cls 7134
            call asm_1_5940_n_sv_in		; Hyp.cls 7135
            pop bc		; Hyp.cls 7136
            ld hl, asm_1_5940_n_nt_pk + 3		; Hyp.cls 7137
            add hl, bc		; Hyp.cls 7138
            ld (hl), 0		; Hyp.cls 7139
            ld a, c		; Hyp.cls 7140
            add a, 3		; Hyp.cls 7141
            ld hl, #4336            ; C_NETHOSTIP [7142]
            call asm_1_5940_n_nt_hdr		; Hyp.cls 7143
            call asm_1_5940_n_nt_go		; Hyp.cls 7144
            jr asm_1_5940_n_nt_ans		; Hyp.cls 7145
; 22: a socket's 16 bytes to the slot
asm_1_5940_n_nt_stat:		; Hyp.cls 7147
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7148
            call asm_1_5940_n_nt_ent		; Hyp.cls 7149
            ld de, asm_1_5940_n_sv_tmp		; Hyp.cls 7150
            ld bc, 16		; Hyp.cls 7151
            call asm_1_5940_n_nt_rd		; Hyp.cls 7152
            ld hl, asm_1_5940_n_sv_tmp		; Hyp.cls 7153
            ld de, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7154
            ld bc, 16		; Hyp.cls 7155
            call asm_1_5940_n_sv_out		; Hyp.cls 7156
            ld a, (asm_1_5940_n_sv_tmp)		; Hyp.cls 7157
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7158
; 23: a TCP socket
asm_1_5940_n_nt_sock:		; Hyp.cls 7160
            ld hl, #0600            ; (domain 0, type 0, protocol 6: TCP) [7161]
            ld (asm_1_5940_n_nt_pk + 4), hl		; Hyp.cls 7162
            xor a		; Hyp.cls 7163
            ld (asm_1_5940_n_nt_pk + 3), a		; Hyp.cls 7164
            ld a, 5		; Hyp.cls 7165
            ld hl, #4331            ; C_NETSOCKET [7166]
            call asm_1_5940_n_nt_hdr		; Hyp.cls 7167
            call asm_1_5940_n_nt_go		; Hyp.cls 7168
            ld a, (asm_1_5940_n_sv_tmp + 3)		; Hyp.cls 7169
            cp asm_1_5940_n_NT_N		; Hyp.cls 7170
            jp nc, asm_1_5940_n_nt_sk1		; Hyp.cls 7171
            ld e, a		; Hyp.cls 7172
            ld d, 0		; Hyp.cls 7173
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 7174
            add hl, de		; Hyp.cls 7175
            ld a, (var_hyp_svc_t)		; Hyp.cls 7176
            ld (hl), a		; Hyp.cls 7177
            jp asm_1_5940_n_nt_ans		; Hyp.cls 7178
asm_1_5940_n_nt_sk1:		; Hyp.cls 7179
            cp 255		; Hyp.cls 7180
            jp z, asm_1_5940_n_nt_ret		; Hyp.cls 7181
            call asm_1_5940_n_nt_close           ; (one this can't keep: closed) [7182]
            ld a, 255		; Hyp.cls 7183
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7184
; 24: connected to an IP address and port
asm_1_5940_n_nt_conn:		; Hyp.cls 7186
            ld hl, asm_1_5940_n_sv_blk + 1		; Hyp.cls 7187
            ld de, asm_1_5940_n_nt_pk + 3		; Hyp.cls 7188
            ld bc, 7		; Hyp.cls 7189
            ldir		; Hyp.cls 7190
            ld a, 9		; Hyp.cls 7191
            ld hl, #4332            ; C_NETCONNECT [7192]
            call asm_1_5940_n_nt_hdr		; Hyp.cls 7193
            call asm_1_5940_n_nt_go		; Hyp.cls 7194
            jp asm_1_5940_n_nt_ans		; Hyp.cls 7195
; 25: bytes sent
asm_1_5940_n_nt_send:		; Hyp.cls 7197
            ld a, 4                 ; the network indicator: blink for the next ~2s (4 x 0.5s) [7198]
            ld (var_hyp_nta), a		; Hyp.cls 7199
            ld hl, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7200
            ld a, h		; Hyp.cls 7201
            or a		; Hyp.cls 7202
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 7203
            ld a, l		; Hyp.cls 7204
            or a		; Hyp.cls 7205
            jp z, asm_1_5940_n_sv_err		; Hyp.cls 7206
            cp 241		; Hyp.cls 7207
            jp nc, asm_1_5940_n_sv_err		; Hyp.cls 7208
            ld (asm_1_5940_n_nt_pk + 4), hl		; Hyp.cls 7209
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7210
            ld (asm_1_5940_n_nt_pk + 3), a		; Hyp.cls 7211
            ld b, h		; Hyp.cls 7212
            ld c, l		; Hyp.cls 7213
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7214
            ld de, asm_1_5940_n_nt_pk + 6		; Hyp.cls 7215
            call asm_1_5940_n_sv_in		; Hyp.cls 7216
            ld a, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7217
            add a, 5		; Hyp.cls 7218
            ld hl, #4334            ; C_NETSEND [7219]
            call asm_1_5940_n_nt_hdr		; Hyp.cls 7220
            call asm_1_5940_n_nt_go		; Hyp.cls 7221
            jp asm_1_5940_n_nt_ans		; Hyp.cls 7222
; 26: bytes received
asm_1_5940_n_nt_recv:		; Hyp.cls 7224
            ld a, 4                 ; the network indicator: blink for the next ~2s (4 x 0.5s) [7225]
            ld (var_hyp_nta), a		; Hyp.cls 7226
            ld hl, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7227
            ld de, 2049		; Hyp.cls 7228
            or a		; Hyp.cls 7229
            sbc hl, de		; Hyp.cls 7230
            jp nc, asm_1_5940_n_sv_err		; Hyp.cls 7231
            ld hl, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7232
            ld (asm_1_5940_n_nt_pk + 4), hl		; Hyp.cls 7233
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7234
            ld (asm_1_5940_n_nt_pk + 3), a		; Hyp.cls 7235
            ld a, 5		; Hyp.cls 7236
            ld hl, #4335            ; C_NETRECV [7237]
            call asm_1_5940_n_nt_hdr		; Hyp.cls 7238
            call asm_1_5940_n_nt_go		; Hyp.cls 7239
            ld hl, 0		; Hyp.cls 7240
            ld a, (asm_1_5940_n_sv_tmp + 3)		; Hyp.cls 7241
            or a		; Hyp.cls 7242
            jr nz, asm_1_5940_n_nt_rc1		; Hyp.cls 7243
            ld hl, (asm_1_5940_n_sv_tmp + 4)     ; how many (no more than asked for) [7244]
            ld de, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7245
            or a		; Hyp.cls 7246
            sbc hl, de		; Hyp.cls 7247
            add hl, de		; Hyp.cls 7248
            jr c, asm_1_5940_n_nt_rc0		; Hyp.cls 7249
            ex de, hl		; Hyp.cls 7250
asm_1_5940_n_nt_rc0:		; Hyp.cls 7251
            ld (asm_1_5940_n_sv_n), hl		; Hyp.cls 7252
            push hl		; Hyp.cls 7253
            ld hl, (asm_1_5940_n_nt_rsp)         ; from the M4's ROM to the slot [7254]
            ld de, 6		; Hyp.cls 7255
            add hl, de		; Hyp.cls 7256
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 7257
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 7258
            ld (asm_1_5940_n_sv_ss), a		; Hyp.cls 7259
            ld a, 3		; Hyp.cls 7260
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 7261
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7262
            ld (asm_1_5940_n_sv_da), hl		; Hyp.cls 7263
            xor a		; Hyp.cls 7264
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 7265
            call asm_1_5940_n_sv_copy		; Hyp.cls 7266
            pop hl		; Hyp.cls 7267
asm_1_5940_n_nt_rc1:		; Hyp.cls 7268
            ld (asm_1_5940_n_sv_tmp + 4), hl     ; how many: to the request's Word(6) [7269]
            ld hl, (var_hyp_svc_p)		; Hyp.cls 7270
            ld de, 6		; Hyp.cls 7271
            add hl, de		; Hyp.cls 7272
            ex de, hl		; Hyp.cls 7273
            ld hl, asm_1_5940_n_sv_tmp + 4		; Hyp.cls 7274
            ld bc, 2		; Hyp.cls 7275
            call asm_1_5940_n_sv_out		; Hyp.cls 7276
            jp asm_1_5940_n_nt_ans		; Hyp.cls 7277
; nt_chk - Byte(1): a socket of this slot's (else the request fails)
asm_1_5940_n_nt_chk:		; Hyp.cls 7279
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7280
            cp asm_1_5940_n_NT_N		; Hyp.cls 7281
            jp nc, asm_1_5940_n_nt_chk1		; Hyp.cls 7282
            ld e, a		; Hyp.cls 7283
            ld d, 0		; Hyp.cls 7284
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 7285
            add hl, de		; Hyp.cls 7286
            ld a, (var_hyp_svc_t)		; Hyp.cls 7287
            cp (hl)		; Hyp.cls 7288
            ret z		; Hyp.cls 7289
            jp asm_1_5940_n_sv_err		; Hyp.cls 7290
asm_1_5940_n_nt_chk1:		; Hyp.cls 7291
            cp 255                  ; (255: the lookup's - 22 only) [7292]
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 7293
            ld a, b		; Hyp.cls 7294
            cp 22		; Hyp.cls 7295
            ret z		; Hyp.cls 7296
            jp asm_1_5940_n_sv_err		; Hyp.cls 7297
; nt_close - socket A closed (no longer anyone's)
asm_1_5940_n_nt_close:		; Hyp.cls 7299
    IFDEF NTC_MSXDOS		; Hyp.cls 7300
            jp asm_1_5940_n_es_close             ; zxn: the ESP's link [7301]
    ENDIF		; Hyp.cls 7302
            ld (asm_1_5940_n_nt_pk + 3), a		; Hyp.cls 7303
            cp asm_1_5940_n_NT_N		; Hyp.cls 7304
            jr nc, asm_1_5940_n_nt_cl1		; Hyp.cls 7305
            ld e, a		; Hyp.cls 7306
            ld d, 0		; Hyp.cls 7307
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 7308
            add hl, de		; Hyp.cls 7309
            ld (hl), 0		; Hyp.cls 7310
asm_1_5940_n_nt_cl1:		; Hyp.cls 7311
            ld a, 3		; Hyp.cls 7312
            ld hl, #4333            ; C_NETCLOSE [7313]
            call asm_1_5940_n_nt_hdr		; Hyp.cls 7314
; nt_go - the packet at nt_pk to the M4 (its size first); the answer's first 8 bytes to sv_tmp
asm_1_5940_n_nt_go:		; Hyp.cls 7316
            ld hl, asm_1_5940_n_nt_pk		; Hyp.cls 7317
            ld bc, #FE00		; Hyp.cls 7318
            ld d, (hl)		; Hyp.cls 7319
            inc d		; Hyp.cls 7320
asm_1_5940_n_nt_go1:		; Hyp.cls 7321
            inc b		; Hyp.cls 7322
            outi		; Hyp.cls 7323
            dec d		; Hyp.cls 7324
            jr nz, asm_1_5940_n_nt_go1		; Hyp.cls 7325
            ld bc, #FC00		; Hyp.cls 7326
            out (c), c		; Hyp.cls 7327
            ld hl, (asm_1_5940_n_nt_rsp)		; Hyp.cls 7328
            ld de, asm_1_5940_n_sv_tmp		; Hyp.cls 7329
            ld bc, 8		; Hyp.cls 7330
; nt_rd - BC bytes of the M4's ROM from HL to DE (here)
asm_1_5940_n_nt_rd:		; Hyp.cls 7332
            push hl		; Hyp.cls 7333
            push de		; Hyp.cls 7334
            push bc		; Hyp.cls 7335
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 7336
            ld c, a		; Hyp.cls 7337
            call #B90F              ; KL ROM SELECT [7338]
            di		; Hyp.cls 7339
            ld (asm_1_5940_n_nt_old), bc		; Hyp.cls 7340
            pop bc		; Hyp.cls 7341
            pop de		; Hyp.cls 7342
            pop hl		; Hyp.cls 7343
            ld a, h		; Hyp.cls 7344
            or #C0		; Hyp.cls 7345
            ld h, a		; Hyp.cls 7346
            ldir		; Hyp.cls 7347
            ld bc, (asm_1_5940_n_nt_old)		; Hyp.cls 7348
            call #B918              ; KL ROM DESELECT [7349]
            di		; Hyp.cls 7350
            ret		; Hyp.cls 7351
; nt_hdr - the packet's size A, its command HL
asm_1_5940_n_nt_hdr:		; Hyp.cls 7353
            ld (asm_1_5940_n_nt_pk), a		; Hyp.cls 7354
            ld (asm_1_5940_n_nt_pk + 1), hl		; Hyp.cls 7355
            ret		; Hyp.cls 7356
; nt_ent - socket A's 16 bytes in the M4's table: HL (255: the first - the lookup's)
asm_1_5940_n_nt_ent:		; Hyp.cls 7358
            cp 255		; Hyp.cls 7359
            jr nz, asm_1_5940_n_nt_e1		; Hyp.cls 7360
            xor a		; Hyp.cls 7361
asm_1_5940_n_nt_e1:		; Hyp.cls 7362
            ld l, a		; Hyp.cls 7363
            ld h, 0		; Hyp.cls 7364
            add hl, hl		; Hyp.cls 7365
            add hl, hl		; Hyp.cls 7366
            add hl, hl		; Hyp.cls 7367
            add hl, hl		; Hyp.cls 7368
            ld de, (asm_1_5940_n_nt_skt)		; Hyp.cls 7369
            add hl, de		; Hyp.cls 7370
            ret		; Hyp.cls 7371
; nt_m4c - the claim on M4 0 held by C (255 CyborgOS, 0 given back)
asm_1_5940_n_nt_m4c:		; Hyp.cls 7373
            push bc		; Hyp.cls 7374
            ld hl, asm_1_5940_n_sv_blk + 1		; Hyp.cls 7375
            ld (hl), 0		; Hyp.cls 7376
            inc hl		; Hyp.cls 7377
            ld (hl), 'M'		; Hyp.cls 7378
            inc hl		; Hyp.cls 7379
            ld (hl), '4'		; Hyp.cls 7380
            ld b, 6		; Hyp.cls 7381
asm_1_5940_n_nt_m4c1:		; Hyp.cls 7382
            inc hl		; Hyp.cls 7383
            ld (hl), ' '		; Hyp.cls 7384
            djnz asm_1_5940_n_nt_m4c1		; Hyp.cls 7385
            call asm_1_5940_n_cl_find		; Hyp.cls 7386
            pop bc		; Hyp.cls 7387
            jr nz, asm_1_5940_n_nt_m4c2		; Hyp.cls 7388
            ld (hl), c              ; (CyborgOS's now - or no one's) [7389]
            ret		; Hyp.cls 7390
asm_1_5940_n_nt_m4c2:		; Hyp.cls 7391
            ld a, c		; Hyp.cls 7392
            or a		; Hyp.cls 7393
            ret z		; Hyp.cls 7394
            ld hl, asm_1_5940_n_sv_cl            ; into a free record [7395]
            ld de, 10		; Hyp.cls 7396
            ld b, asm_1_5940_n_CL_N		; Hyp.cls 7397
asm_1_5940_n_nt_m4c3:		; Hyp.cls 7398
            ld a, (hl)		; Hyp.cls 7399
            or a		; Hyp.cls 7400
            jr z, asm_1_5940_n_nt_m4c4		; Hyp.cls 7401
            add hl, de		; Hyp.cls 7402
            djnz asm_1_5940_n_nt_m4c3		; Hyp.cls 7403
            ret		; Hyp.cls 7404
asm_1_5940_n_nt_m4c4:		; Hyp.cls 7405
            ld (hl), c		; Hyp.cls 7406
            inc hl		; Hyp.cls 7407
            ex de, hl		; Hyp.cls 7408
            ld hl, asm_1_5940_n_sv_blk + 1		; Hyp.cls 7409
            ld bc, 9		; Hyp.cls 7410
            ldir		; Hyp.cls 7411
            ret		; Hyp.cls 7412
; sv_in - BC bytes from the slot's HL to DE (here, in the service page)
asm_1_5940_n_sv_in:		; Hyp.cls 7414
            ld (asm_1_5940_n_sv_sa), hl		; Hyp.cls 7415
            ld (asm_1_5940_n_sv_da), de		; Hyp.cls 7416
            ld (asm_1_5940_n_sv_n), bc		; Hyp.cls 7417
            ld a, 2		; Hyp.cls 7418
            ld (asm_1_5940_n_sv_sk), a		; Hyp.cls 7419
            ld hl, (var_hyp_svc_setting)		; Hyp.cls 7420
            ld (asm_1_5940_n_sv_ss), hl		; Hyp.cls 7421
            ld a, 1		; Hyp.cls 7422
            ld (asm_1_5940_n_sv_dk), a		; Hyp.cls 7423
            ld hl, (var_hyp_svp)		; Hyp.cls 7424
            ld (asm_1_5940_n_sv_ds), hl		; Hyp.cls 7425
            xor a		; Hyp.cls 7426
            ld (asm_1_5940_n_sv_stop), a		; Hyp.cls 7427
            call asm_1_5940_n_sv_copy		; Hyp.cls 7428
            ld a, 2                 ; (the copies to the slot again) [7429]
            ld (asm_1_5940_n_sv_dk), a		; Hyp.cls 7430
            ld hl, (var_hyp_svc_setting)		; Hyp.cls 7431
            ld (asm_1_5940_n_sv_ds), hl		; Hyp.cls 7432
            ret		; Hyp.cls 7433
    IFDEF NTC_MSXDOS		; Hyp.cls 7434
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
asm_1_5940_n_ES_TX:      equ #133B		; Hyp.cls 7447
asm_1_5940_n_ES_RX:      equ #143B		; Hyp.cls 7448
asm_1_5940_n_ES_SEL:     equ #153B		; Hyp.cls 7449
asm_1_5940_n_ES_NL:      equ 5                   ; links (sockets) 0-4 [7450]
asm_1_5940_n_es_net:		; Hyp.cls 7451
            ld b, a                 ; MSX: no network yet (the GR8NET's TCP/IP UNAPI to come) - 20/0 [7452]
            cp 20                   ; says off, the rest of 20 / 21-27 an error. The ESP's code below [7453]
            jp nz, asm_1_5940_n_sv_err           ; isn't reached [7454]
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7455
            or a		; Hyp.cls 7456
            jr z, asm_1_5940_n_es_n0		; Hyp.cls 7457
            jp asm_1_5940_n_sv_err		; Hyp.cls 7458
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7459
            cp 1		; Hyp.cls 7460
            jp z, asm_1_5940_n_es_init		; Hyp.cls 7461
            cp 2		; Hyp.cls 7462
            jp z, asm_1_5940_n_es_off		; Hyp.cls 7463
            cp 8		; Hyp.cls 7464
            jp z, asm_1_5940_n_es_info		; Hyp.cls 7465
            cp 9		; Hyp.cls 7466
            jp z, asm_1_5940_n_es_set		; Hyp.cls 7467
            cp 10		; Hyp.cls 7468
            jp z, asm_1_5940_n_es_list		; Hyp.cls 7469
            jp asm_1_5940_n_nt_20a               ; (3-7: the clock, the host ... - not the network's) [7470]
asm_1_5940_n_es_n0:		; Hyp.cls 7471
            ld a, (asm_1_5940_n_nt_rom)          ; 0: 255 off, else on [7472]
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7473
asm_1_5940_n_es_n1:		; Hyp.cls 7474
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 7475
            inc a		; Hyp.cls 7476
            jp z, asm_1_5940_n_sv_err            ; (no network) [7477]
            call asm_1_5940_n_es_pump		; Hyp.cls 7478
            ld a, (asm_1_5940_n_sv_blk)          ; (the op again: es_pump used B) [7479]
            ld b, a		; Hyp.cls 7480
            cp 21		; Hyp.cls 7481
            jp z, asm_1_5940_n_es_look		; Hyp.cls 7482
            cp 23		; Hyp.cls 7483
            jp z, asm_1_5940_n_es_sock		; Hyp.cls 7484
            call asm_1_5940_n_nt_chk             ; (the rest: one of the slot's sockets) [7485]
            ld a, b		; Hyp.cls 7486
            cp 22		; Hyp.cls 7487
            jp z, asm_1_5940_n_es_stat		; Hyp.cls 7488
            cp 24		; Hyp.cls 7489
            jp z, asm_1_5940_n_es_conn		; Hyp.cls 7490
            cp 25		; Hyp.cls 7491
            jp z, asm_1_5940_n_es_send		; Hyp.cls 7492
            cp 26		; Hyp.cls 7493
            jp z, asm_1_5940_n_es_recv		; Hyp.cls 7494
            ld a, (asm_1_5940_n_sv_blk + 1)      ; 27 [7495]
            call asm_1_5940_n_nt_close		; Hyp.cls 7496
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7497

; 20/1: on - the ESP's UART chosen, 115200 from the video timing's clock, then AT, ATE0, every
; link closed, AT+CIPMUX=1, AT+CIPRECVMODE=1 (a firmware without passive receive: not on)
asm_1_5940_n_es_init:		; Hyp.cls 7501
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 7502
            inc a		; Hyp.cls 7503
            jp nz, asm_1_5940_n_sv_ok            ; (on already) [7504]
            ld bc, asm_1_5940_n_ES_SEL		; Hyp.cls 7505
            xor a		; Hyp.cls 7506
            out (c), a              ; the ESP's UART [7507]
            ld bc, #243B		; Hyp.cls 7508
            ld a, #11		; Hyp.cls 7509
            out (c), a		; Hyp.cls 7510
            inc b		; Hyp.cls 7511
            in a, (c)               ; the video timing: its clock [7512]
            and 7		; Hyp.cls 7513
            add a, a		; Hyp.cls 7514
            ld e, a		; Hyp.cls 7515
            ld d, 0		; Hyp.cls 7516
            ld hl, asm_1_5940_n_es_baud		; Hyp.cls 7517
            add hl, de		; Hyp.cls 7518
            ld e, (hl)		; Hyp.cls 7519
            inc hl		; Hyp.cls 7520
            ld d, (hl)              ; DE = clock / 115200 [7521]
            ld bc, asm_1_5940_n_ES_RX		; Hyp.cls 7522
            ld a, e		; Hyp.cls 7523
            and #7F		; Hyp.cls 7524
            out (c), a              ; its low 7 bits [7525]
            sla e		; Hyp.cls 7526
            rl d		; Hyp.cls 7527
            ld a, d		; Hyp.cls 7528
            and #7F		; Hyp.cls 7529
            or #80		; Hyp.cls 7530
            out (c), a              ; the next 7 [7531]
            call asm_1_5940_n_es_flush		; Hyp.cls 7532
            xor a		; Hyp.cls 7533
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 7534
            ld hl, asm_1_5940_n_es_tab		; Hyp.cls 7535
            ld b, 48		; Hyp.cls 7536
asm_1_5940_n_es_i0:		; Hyp.cls 7537
            ld (hl), a		; Hyp.cls 7538
            inc hl		; Hyp.cls 7539
            djnz asm_1_5940_n_es_i0		; Hyp.cls 7540
            ld hl, asm_1_5940_n_es_s_at          ; AT (twice: the first may meet half a line) [7541]
            call asm_1_5940_n_es_sync		; Hyp.cls 7542
            ld hl, asm_1_5940_n_es_s_at		; Hyp.cls 7543
            call asm_1_5940_n_es_sync		; Hyp.cls 7544
            jr nz, asm_1_5940_n_es_ifail		; Hyp.cls 7545
            ld hl, asm_1_5940_n_es_s_e0		; Hyp.cls 7546
            call asm_1_5940_n_es_sync		; Hyp.cls 7547
            ld hl, asm_1_5940_n_es_s_cl5		; Hyp.cls 7548
            call asm_1_5940_n_es_sync            ; (every link closed: an error is all right) [7549]
            ld hl, asm_1_5940_n_es_s_mux		; Hyp.cls 7550
            call asm_1_5940_n_es_sync		; Hyp.cls 7551
            jr nz, asm_1_5940_n_es_ifail		; Hyp.cls 7552
            ld hl, asm_1_5940_n_es_s_rcv		; Hyp.cls 7553
            call asm_1_5940_n_es_sync		; Hyp.cls 7554
            jr nz, asm_1_5940_n_es_ifail		; Hyp.cls 7555
            xor a		; Hyp.cls 7556
            ld (asm_1_5940_n_nt_rom), a          ; on (0: the ESP, as the M4's ROM number would be) [7557]
            inc a		; Hyp.cls 7558
            ld (var_hyp_ntu), a           ; the network indicator: up [7559]
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7560
asm_1_5940_n_es_ifail:		; Hyp.cls 7561
            ld a, 1		; Hyp.cls 7562
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7563
asm_1_5940_n_es_baud:    dw 243, 248, 256, 260, 269, 278, 286, 234   ; 28.0 28.57 29.46 30 31 32 33 27 MHz / 115200 [7564]

; 20/2: off - every link closed
asm_1_5940_n_es_off:		; Hyp.cls 7567
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 7568
            inc a		; Hyp.cls 7569
            jp z, asm_1_5940_n_sv_ok		; Hyp.cls 7570
            call asm_1_5940_n_es_idle		; Hyp.cls 7571
            ld hl, asm_1_5940_n_es_s_cl5		; Hyp.cls 7572
            call asm_1_5940_n_es_sync		; Hyp.cls 7573
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 7574
            ld b, asm_1_5940_n_NT_N		; Hyp.cls 7575
asm_1_5940_n_es_o1:		; Hyp.cls 7576
            ld (hl), 0		; Hyp.cls 7577
            inc hl		; Hyp.cls 7578
            djnz asm_1_5940_n_es_o1		; Hyp.cls 7579
            ld a, 255		; Hyp.cls 7580
            ld (asm_1_5940_n_nt_rom), a		; Hyp.cls 7581
            xor a		; Hyp.cls 7582
            ld (var_hyp_ntu), a		; Hyp.cls 7583
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7584

; 21: a name looked up (Word(2), Byte(4) its length): AT+CIPDOMAIN="name" - 1: started (22 with
; 255: 5 looking, 0 found, its IP at +4; 255 not found)
asm_1_5940_n_es_look:		; Hyp.cls 7588
            ld a, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7589
            cp 64		; Hyp.cls 7590
            jp nc, asm_1_5940_n_sv_err		; Hyp.cls 7591
            ld c, a		; Hyp.cls 7592
            ld b, 0		; Hyp.cls 7593
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7594
            ld de, asm_1_5940_n_nt_pk		; Hyp.cls 7595
            push bc		; Hyp.cls 7596
            call asm_1_5940_n_sv_in		; Hyp.cls 7597
            pop bc		; Hyp.cls 7598
            ld hl, asm_1_5940_n_nt_pk		; Hyp.cls 7599
            add hl, bc		; Hyp.cls 7600
            ld (hl), 0		; Hyp.cls 7601
            call asm_1_5940_n_es_idle		; Hyp.cls 7602
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 7603
            ld hl, asm_1_5940_n_es_s_dom		; Hyp.cls 7604
            call asm_1_5940_n_es_puts		; Hyp.cls 7605
            ld hl, asm_1_5940_n_nt_pk		; Hyp.cls 7606
            call asm_1_5940_n_es_puts		; Hyp.cls 7607
            ld a, '"'		; Hyp.cls 7608
            call asm_1_5940_n_es_put		; Hyp.cls 7609
            call asm_1_5940_n_es_crlf		; Hyp.cls 7610
            ld a, 5		; Hyp.cls 7611
            ld (asm_1_5940_n_es_tab + 40), a     ; the lookup's: looking [7612]
            ld a, 5		; Hyp.cls 7613
            ld (asm_1_5940_n_es_bl), a		; Hyp.cls 7614
            ld a, 2		; Hyp.cls 7615
            call asm_1_5940_n_es_start		; Hyp.cls 7616
            ld a, 1		; Hyp.cls 7617
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7618

; 22: socket Byte(1)'s 16 bytes to Word(2) (255: the lookup's) - its state
asm_1_5940_n_es_stat:		; Hyp.cls 7621
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7622
            call asm_1_5940_n_es_ent		; Hyp.cls 7623
            ld de, asm_1_5940_n_sv_tmp		; Hyp.cls 7624
            ld bc, 8		; Hyp.cls 7625
            ldir		; Hyp.cls 7626
            ld hl, asm_1_5940_n_sv_tmp + 8		; Hyp.cls 7627
            ld b, 8		; Hyp.cls 7628
asm_1_5940_n_es_st1:		; Hyp.cls 7629
            ld (hl), 0		; Hyp.cls 7630
            inc hl		; Hyp.cls 7631
            djnz asm_1_5940_n_es_st1		; Hyp.cls 7632
            ld hl, asm_1_5940_n_sv_tmp		; Hyp.cls 7633
            ld de, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7634
            ld bc, 16		; Hyp.cls 7635
            call asm_1_5940_n_sv_out		; Hyp.cls 7636
            ld a, (asm_1_5940_n_sv_tmp)		; Hyp.cls 7637
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7638

; 23: a socket: a free link (255 none)
asm_1_5940_n_es_sock:		; Hyp.cls 7641
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 7642
            ld b, 0		; Hyp.cls 7643
asm_1_5940_n_es_sk1:		; Hyp.cls 7644
            ld a, (hl)		; Hyp.cls 7645
            or a		; Hyp.cls 7646
            jr z, asm_1_5940_n_es_sk2		; Hyp.cls 7647
            inc hl		; Hyp.cls 7648
            inc b		; Hyp.cls 7649
            ld a, b		; Hyp.cls 7650
            cp asm_1_5940_n_ES_NL		; Hyp.cls 7651
            jr c, asm_1_5940_n_es_sk1		; Hyp.cls 7652
            ld a, 255		; Hyp.cls 7653
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7654
asm_1_5940_n_es_sk2:		; Hyp.cls 7655
            ld a, (var_hyp_svc_t)		; Hyp.cls 7656
            ld (hl), a              ; the slot's now [7657]
            ld a, b		; Hyp.cls 7658
            ld (asm_1_5940_n_sv_tmp), a		; Hyp.cls 7659
            call asm_1_5940_n_es_ent		; Hyp.cls 7660
            ld b, 8		; Hyp.cls 7661
asm_1_5940_n_es_sk3:		; Hyp.cls 7662
            ld (hl), 0		; Hyp.cls 7663
            inc hl		; Hyp.cls 7664
            djnz asm_1_5940_n_es_sk3		; Hyp.cls 7665
            ld a, (asm_1_5940_n_sv_tmp)		; Hyp.cls 7666
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7667

; 24: socket Byte(1) connected to IP Byte(2-5), port Word(6): AT+CIPSTART=n,"TCP","a.b.c.d",port
asm_1_5940_n_es_conn:		; Hyp.cls 7670
            call asm_1_5940_n_es_idle		; Hyp.cls 7671
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 7672
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7673
            call asm_1_5940_n_es_ent		; Hyp.cls 7674
            push hl		; Hyp.cls 7675
            ld (hl), 1              ; connecting [7676]
            ld de, 4		; Hyp.cls 7677
            add hl, de		; Hyp.cls 7678
            ex de, hl		; Hyp.cls 7679
            ld hl, asm_1_5940_n_sv_blk + 2       ; its IP kept (NETSTAT) [7680]
            ld bc, 4		; Hyp.cls 7681
            ldir		; Hyp.cls 7682
            pop hl		; Hyp.cls 7683
            ld hl, asm_1_5940_n_es_s_start		; Hyp.cls 7684
            call asm_1_5940_n_es_puts		; Hyp.cls 7685
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7686
            add a, '0'		; Hyp.cls 7687
            call asm_1_5940_n_es_put		; Hyp.cls 7688
            ld hl, asm_1_5940_n_es_s_tcp		; Hyp.cls 7689
            call asm_1_5940_n_es_puts		; Hyp.cls 7690
            ld b, 4		; Hyp.cls 7691
            ld hl, asm_1_5940_n_sv_blk + 2		; Hyp.cls 7692
asm_1_5940_n_es_c1:		; Hyp.cls 7693
            push bc		; Hyp.cls 7694
            push hl		; Hyp.cls 7695
            ld l, (hl)		; Hyp.cls 7696
            ld h, 0		; Hyp.cls 7697
            call asm_1_5940_n_es_putdec		; Hyp.cls 7698
            pop hl		; Hyp.cls 7699
            pop bc		; Hyp.cls 7700
            inc hl		; Hyp.cls 7701
            ld a, b		; Hyp.cls 7702
            cp 1		; Hyp.cls 7703
            ld a, '.'		; Hyp.cls 7704
            call nz, asm_1_5940_n_es_put		; Hyp.cls 7705
            djnz asm_1_5940_n_es_c1		; Hyp.cls 7706
            ld a, '"'		; Hyp.cls 7707
            call asm_1_5940_n_es_put		; Hyp.cls 7708
            ld a, ','		; Hyp.cls 7709
            call asm_1_5940_n_es_put		; Hyp.cls 7710
            ld hl, (asm_1_5940_n_sv_blk + 6)		; Hyp.cls 7711
            call asm_1_5940_n_es_putdec		; Hyp.cls 7712
            call asm_1_5940_n_es_crlf		; Hyp.cls 7713
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7714
            ld (asm_1_5940_n_es_bl), a		; Hyp.cls 7715
            ld a, 3		; Hyp.cls 7716
            call asm_1_5940_n_es_start		; Hyp.cls 7717
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7718

; 25: Word(4) bytes (1-240) from Word(2) sent on socket Byte(1): AT+CIPSEND=n,len, then (es_pump)
; the data at the ESP's > and SEND OK - the state 2 meanwhile
asm_1_5940_n_es_send:		; Hyp.cls 7722
            ld hl, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7723
            ld a, h		; Hyp.cls 7724
            or a		; Hyp.cls 7725
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 7726
            ld a, l		; Hyp.cls 7727
            or a		; Hyp.cls 7728
            jp z, asm_1_5940_n_sv_err		; Hyp.cls 7729
            cp 241		; Hyp.cls 7730
            jp nc, asm_1_5940_n_sv_err		; Hyp.cls 7731
            call asm_1_5940_n_es_idle		; Hyp.cls 7732
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 7733
            ld bc, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7734
            ld (asm_1_5940_n_es_sl), bc		; Hyp.cls 7735
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7736
            ld de, asm_1_5940_n_nt_pk		; Hyp.cls 7737
            call asm_1_5940_n_sv_in		; Hyp.cls 7738
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7739
            call asm_1_5940_n_es_ent		; Hyp.cls 7740
            ld (hl), 2              ; sending [7741]
            ld hl, asm_1_5940_n_es_s_send		; Hyp.cls 7742
            call asm_1_5940_n_es_puts		; Hyp.cls 7743
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7744
            add a, '0'		; Hyp.cls 7745
            call asm_1_5940_n_es_put		; Hyp.cls 7746
            ld a, ','		; Hyp.cls 7747
            call asm_1_5940_n_es_put		; Hyp.cls 7748
            ld hl, (asm_1_5940_n_es_sl)		; Hyp.cls 7749
            call asm_1_5940_n_es_putdec		; Hyp.cls 7750
            call asm_1_5940_n_es_crlf		; Hyp.cls 7751
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7752
            ld (asm_1_5940_n_es_bl), a		; Hyp.cls 7753
            ld a, 4		; Hyp.cls 7754
            call asm_1_5940_n_es_start		; Hyp.cls 7755
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7756

; 26: up to Word(4) bytes of socket Byte(1)'s to Word(2) - how many to the request's Word(6). The
; ESP has them (passive): AT+CIPRECVDATA=n,len, its answer +CIPRECVDATA,len:data (or
; +CIPRECVDATA:len,data) waited for here - 160 at most a call (14 ms at 115200: within a frame)
asm_1_5940_n_es_recv:		; Hyp.cls 7761
            ld hl, 0		; Hyp.cls 7762
            ld (asm_1_5940_n_es_rn), hl		; Hyp.cls 7763
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7764
            call asm_1_5940_n_es_ent		; Hyp.cls 7765
            inc hl		; Hyp.cls 7766
            inc hl		; Hyp.cls 7767
            ld a, (hl)		; Hyp.cls 7768
            inc hl		; Hyp.cls 7769
            or (hl)		; Hyp.cls 7770
            jp z, asm_1_5940_n_es_r9             ; (nothing waiting) [7771]
            call asm_1_5940_n_es_idle		; Hyp.cls 7772
            jp nz, asm_1_5940_n_es_r9            ; (the ESP busy: none this time) [7773]
            ld hl, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7774
            ld de, 161		; Hyp.cls 7775
            or a		; Hyp.cls 7776
            sbc hl, de		; Hyp.cls 7777
            add hl, de		; Hyp.cls 7778
            jr c, asm_1_5940_n_es_r1		; Hyp.cls 7779
            ld hl, 160		; Hyp.cls 7780
asm_1_5940_n_es_r1:		; Hyp.cls 7781
            ld a, h		; Hyp.cls 7782
            or l		; Hyp.cls 7783
            jp z, asm_1_5940_n_es_r9		; Hyp.cls 7784
            push hl		; Hyp.cls 7785
            ld hl, asm_1_5940_n_es_s_rdat		; Hyp.cls 7786
            call asm_1_5940_n_es_puts		; Hyp.cls 7787
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 7788
            add a, '0'		; Hyp.cls 7789
            call asm_1_5940_n_es_put		; Hyp.cls 7790
            ld a, ','		; Hyp.cls 7791
            call asm_1_5940_n_es_put		; Hyp.cls 7792
            pop hl		; Hyp.cls 7793
            call asm_1_5940_n_es_putdec		; Hyp.cls 7794
            call asm_1_5940_n_es_crlf		; Hyp.cls 7795
            ld a, 7                 ; (7: a receive - es_line hands its data line here) [7796]
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 7797
            ld hl, 0		; Hyp.cls 7798
            ld (asm_1_5940_n_es_rn), hl		; Hyp.cls 7799
            call msx_t300		; Hyp.cls 7800
            ld (asm_1_5940_n_es_t0), hl		; Hyp.cls 7801
            call asm_1_5940_n_es_now		; Hyp.cls 7802
            ld (asm_1_5940_n_es_f0), hl		; Hyp.cls 7803
asm_1_5940_n_es_r2:		; Hyp.cls 7804
            call asm_1_5940_n_es_pump            ; until its OK (es_busy 0) - 2 s at most [7805]
            ld a, (asm_1_5940_n_es_busy)		; Hyp.cls 7806
            or a		; Hyp.cls 7807
            jr z, asm_1_5940_n_es_r3		; Hyp.cls 7808
            call asm_1_5940_n_es_since		; Hyp.cls 7809
            ld de, 100		; Hyp.cls 7810
            or a		; Hyp.cls 7811
            sbc hl, de		; Hyp.cls 7812
            jr c, asm_1_5940_n_es_r2		; Hyp.cls 7813
            xor a		; Hyp.cls 7814
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 7815
asm_1_5940_n_es_r3:		; Hyp.cls 7816
            ld hl, (asm_1_5940_n_es_rn)          ; how many came [7817]
            ld (asm_1_5940_n_es_rn), hl		; Hyp.cls 7818
            ld a, h		; Hyp.cls 7819
            or l		; Hyp.cls 7820
            jr z, asm_1_5940_n_es_r4		; Hyp.cls 7821
            push hl		; Hyp.cls 7822
            ld b, h		; Hyp.cls 7823
            ld c, l		; Hyp.cls 7824
            ld hl, asm_1_5940_n_nt_pk		; Hyp.cls 7825
            ld de, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7826
            call asm_1_5940_n_sv_out		; Hyp.cls 7827
            pop bc		; Hyp.cls 7828
asm_1_5940_n_es_r4:		; Hyp.cls 7829
            ld a, (asm_1_5940_n_sv_blk + 1)      ; the bytes waiting less those [7830]
            call asm_1_5940_n_es_ent		; Hyp.cls 7831
            inc hl		; Hyp.cls 7832
            inc hl		; Hyp.cls 7833
            ld e, (hl)		; Hyp.cls 7834
            inc hl		; Hyp.cls 7835
            ld d, (hl)		; Hyp.cls 7836
            ex de, hl		; Hyp.cls 7837
            ld bc, (asm_1_5940_n_es_rn)		; Hyp.cls 7838
            ld a, b		; Hyp.cls 7839
            or c		; Hyp.cls 7840
            jr z, asm_1_5940_n_es_r5             ; (none came: none waiting) [7841]
            or a		; Hyp.cls 7842
            sbc hl, bc		; Hyp.cls 7843
            jr nc, asm_1_5940_n_es_r6		; Hyp.cls 7844
asm_1_5940_n_es_r5:		; Hyp.cls 7845
            ld hl, 0		; Hyp.cls 7846
asm_1_5940_n_es_r6:		; Hyp.cls 7847
            ex de, hl		; Hyp.cls 7848
            ld (hl), d		; Hyp.cls 7849
            dec hl		; Hyp.cls 7850
            ld (hl), e		; Hyp.cls 7851
asm_1_5940_n_es_r9:		; Hyp.cls 7852
            ld hl, (asm_1_5940_n_es_rn)		; Hyp.cls 7853
            ld (asm_1_5940_n_sv_tmp + 4), hl     ; how many: to the request's Word(6) [7854]
            ld hl, (var_hyp_svc_p)		; Hyp.cls 7855
            ld de, 6		; Hyp.cls 7856
            add hl, de		; Hyp.cls 7857
            ex de, hl		; Hyp.cls 7858
            ld hl, asm_1_5940_n_sv_tmp + 4		; Hyp.cls 7859
            ld bc, 2		; Hyp.cls 7860
            call asm_1_5940_n_sv_out		; Hyp.cls 7861
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7862

; 20/8: the details (IPCONFIG) - 64 bytes to Word(2), as the CPC's: AT+CWJAP_CUR? (the network's
; name, the signal), AT+CIPSTA_CUR? (the IP, gateway, netmask), AT+CIPSTAMAC_CUR? (the MAC)
asm_1_5940_n_es_info:		; Hyp.cls 7866
            ld hl, asm_1_5940_n_nt_pk + 192		; Hyp.cls 7867
            ld b, 64		; Hyp.cls 7868
asm_1_5940_n_es_fz:		; Hyp.cls 7869
            ld (hl), 0		; Hyp.cls 7870
            inc hl		; Hyp.cls 7871
            djnz asm_1_5940_n_es_fz		; Hyp.cls 7872
            ld a, 255		; Hyp.cls 7873
            ld (asm_1_5940_n_nt_pk + 193), a		; Hyp.cls 7874
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 7875
            inc a		; Hyp.cls 7876
            jr z, asm_1_5940_n_es_f9		; Hyp.cls 7877
            ld a, 1		; Hyp.cls 7878
            ld (asm_1_5940_n_nt_pk + 192), a     ; on [7879]
            call asm_1_5940_n_es_idle		; Hyp.cls 7880
            jr nz, asm_1_5940_n_es_f9		; Hyp.cls 7881
            ld a, 1		; Hyp.cls 7882
            ld (asm_1_5940_n_es_cap), a          ; (lines starting +CWJAP / +CIPSTA: es_capl) [7883]
            ld hl, asm_1_5940_n_es_s_jap		; Hyp.cls 7884
            call asm_1_5940_n_es_sync		; Hyp.cls 7885
            ld hl, asm_1_5940_n_es_s_sta		; Hyp.cls 7886
            call asm_1_5940_n_es_sync		; Hyp.cls 7887
            ld hl, asm_1_5940_n_es_s_mac		; Hyp.cls 7888
            call asm_1_5940_n_es_sync		; Hyp.cls 7889
            xor a		; Hyp.cls 7890
            ld (asm_1_5940_n_es_cap), a		; Hyp.cls 7891
asm_1_5940_n_es_f9:		; Hyp.cls 7892
            ld hl, asm_1_5940_n_nt_pk + 192		; Hyp.cls 7893
            ld de, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7894
            ld bc, 64		; Hyp.cls 7895
            call asm_1_5940_n_sv_out		; Hyp.cls 7896
            ld a, (asm_1_5940_n_nt_pk + 192)		; Hyp.cls 7897
            jp asm_1_5940_n_nt_ret		; Hyp.cls 7898

; 20/9: the network joined - Word(2), Byte(4): name,password -> AT+CWJAP_DEF="name","password"
; (kept by the ESP; in the background: IPCONFIG shows it when joined)
asm_1_5940_n_es_set:		; Hyp.cls 7902
            ld a, (asm_1_5940_n_sv_blk + 4)		; Hyp.cls 7903
            cp 100		; Hyp.cls 7904
            jp nc, asm_1_5940_n_sv_err		; Hyp.cls 7905
            ld c, a		; Hyp.cls 7906
            ld b, 0		; Hyp.cls 7907
            ld hl, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 7908
            ld de, asm_1_5940_n_nt_pk		; Hyp.cls 7909
            push bc		; Hyp.cls 7910
            call asm_1_5940_n_sv_in		; Hyp.cls 7911
            pop bc		; Hyp.cls 7912
            ld hl, asm_1_5940_n_nt_pk		; Hyp.cls 7913
            add hl, bc		; Hyp.cls 7914
            ld (hl), 0		; Hyp.cls 7915
            call asm_1_5940_n_es_idle		; Hyp.cls 7916
            jp nz, asm_1_5940_n_sv_err		; Hyp.cls 7917
            ld hl, asm_1_5940_n_es_s_join		; Hyp.cls 7918
            call asm_1_5940_n_es_puts		; Hyp.cls 7919
            ld hl, asm_1_5940_n_nt_pk		; Hyp.cls 7920
asm_1_5940_n_es_j1:		; Hyp.cls 7921
            ld a, (hl)		; Hyp.cls 7922
            or a		; Hyp.cls 7923
            jr z, asm_1_5940_n_es_j2		; Hyp.cls 7924
            cp ','		; Hyp.cls 7925
            jr nz, asm_1_5940_n_es_j3		; Hyp.cls 7926
            ld a, '"'		; Hyp.cls 7927
            call asm_1_5940_n_es_put		; Hyp.cls 7928
            ld a, ','		; Hyp.cls 7929
            call asm_1_5940_n_es_put		; Hyp.cls 7930
            ld a, '"'		; Hyp.cls 7931
asm_1_5940_n_es_j3:		; Hyp.cls 7932
            call asm_1_5940_n_es_put		; Hyp.cls 7933
            inc hl		; Hyp.cls 7934
            jr asm_1_5940_n_es_j1		; Hyp.cls 7935
asm_1_5940_n_es_j2:		; Hyp.cls 7936
            ld a, '"'		; Hyp.cls 7937
            call asm_1_5940_n_es_put		; Hyp.cls 7938
            call asm_1_5940_n_es_crlf		; Hyp.cls 7939
            ld a, 1		; Hyp.cls 7940
            call asm_1_5940_n_es_start		; Hyp.cls 7941
            jp asm_1_5940_n_sv_ok		; Hyp.cls 7942

; 20/10: the sockets (NETSTAT) - 8 bytes each to Word(2): the slot, the state, the bytes
; waiting, the IP - A how many in use
asm_1_5940_n_es_list:		; Hyp.cls 7946
            ld hl, asm_1_5940_n_nt_pk + 192		; Hyp.cls 7947
            ld b, 64		; Hyp.cls 7948
asm_1_5940_n_es_l0:		; Hyp.cls 7949
            ld (hl), 0		; Hyp.cls 7950
            inc hl		; Hyp.cls 7951
            djnz asm_1_5940_n_es_l0		; Hyp.cls 7952
            ld c, 0		; Hyp.cls 7953
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 7954
            inc a		; Hyp.cls 7955
            jr z, asm_1_5940_n_es_l9		; Hyp.cls 7956
            ld b, 0		; Hyp.cls 7957
asm_1_5940_n_es_l1:		; Hyp.cls 7958
            push bc		; Hyp.cls 7959
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 7960
            ld e, b		; Hyp.cls 7961
            ld d, 0		; Hyp.cls 7962
            add hl, de		; Hyp.cls 7963
            ld a, (hl)		; Hyp.cls 7964
            or a		; Hyp.cls 7965
            jr z, asm_1_5940_n_es_l2		; Hyp.cls 7966
            ld l, b		; Hyp.cls 7967
            ld h, 0		; Hyp.cls 7968
            add hl, hl		; Hyp.cls 7969
            add hl, hl		; Hyp.cls 7970
            add hl, hl		; Hyp.cls 7971
            ld de, asm_1_5940_n_nt_pk + 192		; Hyp.cls 7972
            add hl, de		; Hyp.cls 7973
            ld (hl), a              ; the slot [7974]
            inc hl		; Hyp.cls 7975
            push hl		; Hyp.cls 7976
            ld a, b		; Hyp.cls 7977
            call asm_1_5940_n_es_ent		; Hyp.cls 7978
            pop de		; Hyp.cls 7979
            ldi                     ; the state [7980]
            inc hl		; Hyp.cls 7981
            ldi                     ; the bytes waiting [7982]
            ldi		; Hyp.cls 7983
            ldi                     ; the IP [7984]
            ldi		; Hyp.cls 7985
            ldi		; Hyp.cls 7986
            ldi		; Hyp.cls 7987
            pop bc		; Hyp.cls 7988
            inc c		; Hyp.cls 7989
            push bc		; Hyp.cls 7990
asm_1_5940_n_es_l2:		; Hyp.cls 7991
            pop bc		; Hyp.cls 7992
            inc b		; Hyp.cls 7993
            ld a, b		; Hyp.cls 7994
            cp asm_1_5940_n_ES_NL		; Hyp.cls 7995
            jr c, asm_1_5940_n_es_l1		; Hyp.cls 7996
asm_1_5940_n_es_l9:		; Hyp.cls 7997
            ld a, c		; Hyp.cls 7998
            ld (asm_1_5940_n_sv_tmp), a		; Hyp.cls 7999
            ld hl, asm_1_5940_n_nt_pk + 192		; Hyp.cls 8000
            ld de, (asm_1_5940_n_sv_blk + 2)		; Hyp.cls 8001
            ld bc, 64		; Hyp.cls 8002
            call asm_1_5940_n_sv_out		; Hyp.cls 8003
            ld a, (asm_1_5940_n_sv_tmp)		; Hyp.cls 8004
            jp asm_1_5940_n_nt_ret		; Hyp.cls 8005

; es_close - link A closed (nt_close's, on the Next): no longer anyone's; AT+CIPCLOSE=n if it was
; connected (in the background)
asm_1_5940_n_es_close:		; Hyp.cls 8009
            cp asm_1_5940_n_ES_NL		; Hyp.cls 8010
            ret nc		; Hyp.cls 8011
            ld c, a		; Hyp.cls 8012
            ld e, a		; Hyp.cls 8013
            ld d, 0		; Hyp.cls 8014
            ld hl, asm_1_5940_n_nt_own		; Hyp.cls 8015
            add hl, de		; Hyp.cls 8016
            ld (hl), 0		; Hyp.cls 8017
            ld a, c		; Hyp.cls 8018
            call asm_1_5940_n_es_ent		; Hyp.cls 8019
            ld a, (hl)		; Hyp.cls 8020
            ld (hl), 0		; Hyp.cls 8021
            inc hl		; Hyp.cls 8022
            ld (hl), 0		; Hyp.cls 8023
            inc hl		; Hyp.cls 8024
            ld (hl), 0		; Hyp.cls 8025
            inc hl		; Hyp.cls 8026
            ld (hl), 0		; Hyp.cls 8027
            cp 3		; Hyp.cls 8028
            ret z                   ; (closed already) [8029]
            ld a, (asm_1_5940_n_nt_rom)		; Hyp.cls 8030
            inc a		; Hyp.cls 8031
            ret z		; Hyp.cls 8032
            push bc		; Hyp.cls 8033
            call asm_1_5940_n_es_idle		; Hyp.cls 8034
            pop bc		; Hyp.cls 8035
            ret nz		; Hyp.cls 8036
            ld hl, asm_1_5940_n_es_s_close		; Hyp.cls 8037
            call asm_1_5940_n_es_puts		; Hyp.cls 8038
            ld a, c		; Hyp.cls 8039
            add a, '0'		; Hyp.cls 8040
            call asm_1_5940_n_es_put		; Hyp.cls 8041
            call asm_1_5940_n_es_crlf		; Hyp.cls 8042
            ld a, 6		; Hyp.cls 8043
            jp asm_1_5940_n_es_start		; Hyp.cls 8044

; ---- the ESP's talk
; es_start - a command sent (kind A: 1 OK / ERROR awaited, 2 a lookup, 3 a connect, 4 a send's >,
; 6 a close): in flight from now (es_pump moves it on); its clock started
asm_1_5940_n_es_start:		; Hyp.cls 8049
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 8050
            call msx_t300		; Hyp.cls 8051
            ld (asm_1_5940_n_es_t0), hl		; Hyp.cls 8052
            ret		; Hyp.cls 8053
; es_now - HL = frames counted from the raster (a service runs with interrupts off: the clock
; stands still, so a wait here counts the raster's returns to its top - called often enough to see
; each: every wait below calls it each time round)
asm_1_5940_n_es_now:		; Hyp.cls 8057
            push bc		; Hyp.cls 8058
            push de		; Hyp.cls 8059
            ld bc, #243B		; Hyp.cls 8060
asm_1_5940_n_es_nw1:		; Hyp.cls 8061
            ld a, #1E		; Hyp.cls 8062
            out (c), a		; Hyp.cls 8063
            inc b		; Hyp.cls 8064
            in d, (c)		; Hyp.cls 8065
            dec b		; Hyp.cls 8066
            ld a, #1F		; Hyp.cls 8067
            out (c), a		; Hyp.cls 8068
            inc b		; Hyp.cls 8069
            in e, (c)		; Hyp.cls 8070
            dec b		; Hyp.cls 8071
            ld a, #1E		; Hyp.cls 8072
            out (c), a		; Hyp.cls 8073
            inc b		; Hyp.cls 8074
            in a, (c)		; Hyp.cls 8075
            dec b		; Hyp.cls 8076
            cp d		; Hyp.cls 8077
            jr nz, asm_1_5940_n_es_nw1		; Hyp.cls 8078
            and 1		; Hyp.cls 8079
            ld d, a                 ; DE = the line now [8080]
            ld hl, (asm_1_5940_n_es_lln)		; Hyp.cls 8081
            ld (asm_1_5940_n_es_lln), de		; Hyp.cls 8082
            or a		; Hyp.cls 8083
            sbc hl, de		; Hyp.cls 8084
            jr c, asm_1_5940_n_es_nw2		; Hyp.cls 8085
            jr z, asm_1_5940_n_es_nw2		; Hyp.cls 8086
            ld hl, (asm_1_5940_n_es_frm)         ; (lower than before: a new frame) [8087]
            inc hl		; Hyp.cls 8088
            ld (asm_1_5940_n_es_frm), hl		; Hyp.cls 8089
asm_1_5940_n_es_nw2:		; Hyp.cls 8090
            ld hl, (asm_1_5940_n_es_frm)		; Hyp.cls 8091
            pop de		; Hyp.cls 8092
            pop bc		; Hyp.cls 8093
            ret		; Hyp.cls 8094
; es_since - HL = frames since es_f0
asm_1_5940_n_es_since:		; Hyp.cls 8096
            call asm_1_5940_n_es_now		; Hyp.cls 8097
            ld de, (asm_1_5940_n_es_f0)		; Hyp.cls 8098
            or a		; Hyp.cls 8099
            sbc hl, de		; Hyp.cls 8100
            ret		; Hyp.cls 8101
; es_idle - NZ when a command is still in flight after waiting (0.3 s) for it
asm_1_5940_n_es_idle:		; Hyp.cls 8103
            call asm_1_5940_n_es_now		; Hyp.cls 8104
            ld (asm_1_5940_n_es_f0), hl		; Hyp.cls 8105
asm_1_5940_n_es_id1:		; Hyp.cls 8106
            call asm_1_5940_n_es_pump		; Hyp.cls 8107
            ld a, (asm_1_5940_n_es_busy)		; Hyp.cls 8108
            or a		; Hyp.cls 8109
            ret z		; Hyp.cls 8110
            call asm_1_5940_n_es_since		; Hyp.cls 8111
            ld de, 15		; Hyp.cls 8112
            or a		; Hyp.cls 8113
            sbc hl, de		; Hyp.cls 8114
            jr c, asm_1_5940_n_es_id1		; Hyp.cls 8115
            or 1		; Hyp.cls 8116
            ret		; Hyp.cls 8117
; es_sync - command HL sent, its OK / ERROR waited for (1 s): Z when OK
asm_1_5940_n_es_sync:		; Hyp.cls 8119
            call asm_1_5940_n_es_puts		; Hyp.cls 8120
            call asm_1_5940_n_es_crlf		; Hyp.cls 8121
            ld a, 1		; Hyp.cls 8122
            call asm_1_5940_n_es_start		; Hyp.cls 8123
            call asm_1_5940_n_es_now		; Hyp.cls 8124
            ld (asm_1_5940_n_es_f0), hl		; Hyp.cls 8125
asm_1_5940_n_es_sy1:		; Hyp.cls 8126
            call asm_1_5940_n_es_pump		; Hyp.cls 8127
            ld a, (asm_1_5940_n_es_busy)		; Hyp.cls 8128
            or a		; Hyp.cls 8129
            jr z, asm_1_5940_n_es_sy2		; Hyp.cls 8130
            call asm_1_5940_n_es_since		; Hyp.cls 8131
            ld de, 50		; Hyp.cls 8132
            or a		; Hyp.cls 8133
            sbc hl, de		; Hyp.cls 8134
            jr c, asm_1_5940_n_es_sy1		; Hyp.cls 8135
            xor a		; Hyp.cls 8136
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 8137
            or 1		; Hyp.cls 8138
            ret		; Hyp.cls 8139
asm_1_5940_n_es_sy2:		; Hyp.cls 8140
            ld a, (asm_1_5940_n_es_res)		; Hyp.cls 8141
            or a		; Hyp.cls 8142
            ret		; Hyp.cls 8143
; es_pump - what the ESP has said read: lines (es_line); a send's > (its data sent); a
; receive's data (es_busy 7: the count after +CIPRECVDATA, then that many bytes); and a command
; that has waited 15 s given up
asm_1_5940_n_es_pump:		; Hyp.cls 8147
            ld a, (asm_1_5940_n_es_busy)		; Hyp.cls 8148
            or a		; Hyp.cls 8149
            jr z, asm_1_5940_n_es_pu1		; Hyp.cls 8150
            call msx_t300		; Hyp.cls 8151
            ld de, (asm_1_5940_n_es_t0)		; Hyp.cls 8152
            or a		; Hyp.cls 8153
            sbc hl, de		; Hyp.cls 8154
            ld de, 4500		; Hyp.cls 8155
            or a		; Hyp.cls 8156
            sbc hl, de		; Hyp.cls 8157
            jr c, asm_1_5940_n_es_pu1		; Hyp.cls 8158
            call asm_1_5940_n_es_fail            ; (15 s: no answer) [8159]
asm_1_5940_n_es_pu1:		; Hyp.cls 8160
            ld bc, asm_1_5940_n_ES_TX		; Hyp.cls 8161
            in a, (c)		; Hyp.cls 8162
            and 1		; Hyp.cls 8163
            ret z		; Hyp.cls 8164
            ld bc, asm_1_5940_n_ES_RX		; Hyp.cls 8165
            in a, (c)		; Hyp.cls 8166
            ld c, a		; Hyp.cls 8167
            ld a, (asm_1_5940_n_es_busy)		; Hyp.cls 8168
            cp 4		; Hyp.cls 8169
            jr nz, asm_1_5940_n_es_pu2		; Hyp.cls 8170
            ld a, c		; Hyp.cls 8171
            cp '>'		; Hyp.cls 8172
            jr nz, asm_1_5940_n_es_pu2		; Hyp.cls 8173
            call asm_1_5940_n_es_data            ; the send's data, now [8174]
            jr asm_1_5940_n_es_pu1		; Hyp.cls 8175
asm_1_5940_n_es_pu2:		; Hyp.cls 8176
            ld a, c		; Hyp.cls 8177
            cp 13		; Hyp.cls 8178
            jr z, asm_1_5940_n_es_pu1		; Hyp.cls 8179
            cp 10		; Hyp.cls 8180
            jr z, asm_1_5940_n_es_pu4		; Hyp.cls 8181
            ld hl, asm_1_5940_n_es_lp		; Hyp.cls 8182
            ld e, (hl)		; Hyp.cls 8183
            ld a, e		; Hyp.cls 8184
            cp 95		; Hyp.cls 8185
            jr nc, asm_1_5940_n_es_pu1		; Hyp.cls 8186
            inc (hl)		; Hyp.cls 8187
            ld d, 0		; Hyp.cls 8188
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8189
            add hl, de		; Hyp.cls 8190
            ld (hl), c		; Hyp.cls 8191
            inc hl		; Hyp.cls 8192
            ld (hl), 0		; Hyp.cls 8193
            ld a, (asm_1_5940_n_es_busy)         ; a receive: +CIPRECVDATA,n: (or :n,) - the data follows now [8194]
            cp 7		; Hyp.cls 8195
            jr nz, asm_1_5940_n_es_pu1		; Hyp.cls 8196
            ld a, c		; Hyp.cls 8197
            cp ':'		; Hyp.cls 8198
            jr z, asm_1_5940_n_es_pu3		; Hyp.cls 8199
            cp ','		; Hyp.cls 8200
            jr nz, asm_1_5940_n_es_pu1		; Hyp.cls 8201
asm_1_5940_n_es_pu3:		; Hyp.cls 8202
            call asm_1_5940_n_es_rhead		; Hyp.cls 8203
            jr asm_1_5940_n_es_pu1		; Hyp.cls 8204
asm_1_5940_n_es_pu4:		; Hyp.cls 8205
            ld a, (asm_1_5940_n_es_lp)		; Hyp.cls 8206
            or a		; Hyp.cls 8207
            call nz, asm_1_5940_n_es_line		; Hyp.cls 8208
            xor a		; Hyp.cls 8209
            ld (asm_1_5940_n_es_lp), a		; Hyp.cls 8210
            ld (asm_1_5940_n_es_ln), a		; Hyp.cls 8211
            jr asm_1_5940_n_es_pu1		; Hyp.cls 8212
; es_rhead - in a receive, es_ln so far "+CIPRECVDATA,n:" or "+CIPRECVDATA:n," : n read, then
; that many bytes into nt_pk (es_rn)
asm_1_5940_n_es_rhead:		; Hyp.cls 8215
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8216
            ld de, asm_1_5940_n_es_k_rdat		; Hyp.cls 8217
            call asm_1_5940_n_es_pfx		; Hyp.cls 8218
            ret nz		; Hyp.cls 8219
            ld a, (hl)              ; the count: after , or : [8220]
            cp ','		; Hyp.cls 8221
            jr z, asm_1_5940_n_es_rh1		; Hyp.cls 8222
            cp ':'		; Hyp.cls 8223
            ret nz		; Hyp.cls 8224
asm_1_5940_n_es_rh1:		; Hyp.cls 8225
            inc hl		; Hyp.cls 8226
            ld a, (hl)		; Hyp.cls 8227
            cp '0'		; Hyp.cls 8228
            ret c		; Hyp.cls 8229
            cp '9' + 1		; Hyp.cls 8230
            ret nc		; Hyp.cls 8231
            call asm_1_5940_n_es_num             ; DE = n, HL past it [8232]
            ld a, (hl)		; Hyp.cls 8233
            or a		; Hyp.cls 8234
            jr nz, asm_1_5940_n_es_rh2           ; (no separator yet: not all there) [8235]
            ret		; Hyp.cls 8236
asm_1_5940_n_es_rh2:		; Hyp.cls 8237
            ld a, (asm_1_5940_n_es_lp)           ; ("+CIPRECVDATA:n," ends with , ; ",n:" with : - the last character) [8238]
            dec a		; Hyp.cls 8239
            ld c, a		; Hyp.cls 8240
            ld b, 0		; Hyp.cls 8241
            push hl		; Hyp.cls 8242
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8243
            add hl, bc		; Hyp.cls 8244
            ld a, (hl)		; Hyp.cls 8245
            pop hl		; Hyp.cls 8246
            ld b, a		; Hyp.cls 8247
            ld a, (asm_1_5940_n_es_ln + 12)      ; the character after +CIPRECVDATA [8248]
            cp ','		; Hyp.cls 8249
            jr nz, asm_1_5940_n_es_rh3		; Hyp.cls 8250
            ld a, b		; Hyp.cls 8251
            cp ':'		; Hyp.cls 8252
            ret nz		; Hyp.cls 8253
            jr asm_1_5940_n_es_rh4		; Hyp.cls 8254
asm_1_5940_n_es_rh3:		; Hyp.cls 8255
            ld a, b		; Hyp.cls 8256
            cp ','		; Hyp.cls 8257
            ret nz		; Hyp.cls 8258
asm_1_5940_n_es_rh4:		; Hyp.cls 8259
            ld hl, 160              ; (no more than asked: 160) [8260]
            or a		; Hyp.cls 8261
            sbc hl, de		; Hyp.cls 8262
            ret c		; Hyp.cls 8263
            ld (asm_1_5940_n_es_rn), de		; Hyp.cls 8264
            ld hl, asm_1_5940_n_nt_pk		; Hyp.cls 8265
asm_1_5940_n_es_rh5:		; Hyp.cls 8266
            ld a, d		; Hyp.cls 8267
            or e		; Hyp.cls 8268
            jr z, asm_1_5940_n_es_rh7		; Hyp.cls 8269
            push hl		; Hyp.cls 8270
            push de		; Hyp.cls 8271
            call asm_1_5940_n_es_now             ; (each byte waited for - 0.5 s) [8272]
            ld (asm_1_5940_n_es_f1), hl		; Hyp.cls 8273
            pop de		; Hyp.cls 8274
            pop hl		; Hyp.cls 8275
asm_1_5940_n_es_rh6:		; Hyp.cls 8276
            ld bc, asm_1_5940_n_ES_TX		; Hyp.cls 8277
            in a, (c)		; Hyp.cls 8278
            and 1		; Hyp.cls 8279
            jr nz, asm_1_5940_n_es_rh8		; Hyp.cls 8280
            push hl		; Hyp.cls 8281
            push de		; Hyp.cls 8282
            call asm_1_5940_n_es_now		; Hyp.cls 8283
            ld de, (asm_1_5940_n_es_f1)		; Hyp.cls 8284
            or a		; Hyp.cls 8285
            sbc hl, de		; Hyp.cls 8286
            ld de, 25		; Hyp.cls 8287
            or a		; Hyp.cls 8288
            sbc hl, de		; Hyp.cls 8289
            pop de		; Hyp.cls 8290
            pop hl		; Hyp.cls 8291
            jr c, asm_1_5940_n_es_rh6		; Hyp.cls 8292
            jr asm_1_5940_n_es_rh7		; Hyp.cls 8293
asm_1_5940_n_es_rh8:		; Hyp.cls 8294
            ld bc, asm_1_5940_n_ES_RX		; Hyp.cls 8295
            in a, (c)		; Hyp.cls 8296
            ld (hl), a		; Hyp.cls 8297
            inc hl		; Hyp.cls 8298
            dec de		; Hyp.cls 8299
            jr asm_1_5940_n_es_rh5		; Hyp.cls 8300
asm_1_5940_n_es_rh7:		; Hyp.cls 8301
            xor a		; Hyp.cls 8302
            ld (asm_1_5940_n_es_lp), a		; Hyp.cls 8303
            ld (asm_1_5940_n_es_ln), a		; Hyp.cls 8304
            ret		; Hyp.cls 8305
; es_data - the send's bytes (nt_pk, es_sl) to the ESP: then SEND OK awaited (5)
asm_1_5940_n_es_data:		; Hyp.cls 8307
            ld hl, asm_1_5940_n_nt_pk		; Hyp.cls 8308
            ld de, (asm_1_5940_n_es_sl)		; Hyp.cls 8309
asm_1_5940_n_es_da1:		; Hyp.cls 8310
            ld a, d		; Hyp.cls 8311
            or e		; Hyp.cls 8312
            jr z, asm_1_5940_n_es_da2		; Hyp.cls 8313
            ld a, (hl)		; Hyp.cls 8314
            call asm_1_5940_n_es_put		; Hyp.cls 8315
            inc hl		; Hyp.cls 8316
            dec de		; Hyp.cls 8317
            jr asm_1_5940_n_es_da1		; Hyp.cls 8318
asm_1_5940_n_es_da2:		; Hyp.cls 8319
            ld a, 5		; Hyp.cls 8320
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 8321
            ret		; Hyp.cls 8322
; es_line - a line the ESP said (es_ln, es_lp long)
asm_1_5940_n_es_line:		; Hyp.cls 8324
            ld a, (asm_1_5940_n_es_cap)          ; (IPCONFIG's: its lines first) [8325]
            or a		; Hyp.cls 8326
            call nz, asm_1_5940_n_es_capl		; Hyp.cls 8327
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8328
            ld de, asm_1_5940_n_es_k_ok		; Hyp.cls 8329
            call asm_1_5940_n_es_pfz		; Hyp.cls 8330
            jp z, asm_1_5940_n_es_ok		; Hyp.cls 8331
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8332
            ld de, asm_1_5940_n_es_k_sendok		; Hyp.cls 8333
            call asm_1_5940_n_es_pfz		; Hyp.cls 8334
            jp z, asm_1_5940_n_es_sendok		; Hyp.cls 8335
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8336
            ld de, asm_1_5940_n_es_k_err		; Hyp.cls 8337
            call asm_1_5940_n_es_pfz		; Hyp.cls 8338
            jp z, asm_1_5940_n_es_err		; Hyp.cls 8339
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8340
            ld de, asm_1_5940_n_es_k_fail		; Hyp.cls 8341
            call asm_1_5940_n_es_pfx		; Hyp.cls 8342
            jp z, asm_1_5940_n_es_err		; Hyp.cls 8343
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8344
            ld de, asm_1_5940_n_es_k_sfail		; Hyp.cls 8345
            call asm_1_5940_n_es_pfz		; Hyp.cls 8346
            jp z, asm_1_5940_n_es_err		; Hyp.cls 8347
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8348
            ld de, asm_1_5940_n_es_k_dom		; Hyp.cls 8349
            call asm_1_5940_n_es_pfx		; Hyp.cls 8350
            jp z, asm_1_5940_n_es_dom		; Hyp.cls 8351
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8352
            ld de, asm_1_5940_n_es_k_ipd		; Hyp.cls 8353
            call asm_1_5940_n_es_pfx		; Hyp.cls 8354
            jp z, asm_1_5940_n_es_ipd		; Hyp.cls 8355
            ld a, (asm_1_5940_n_es_ln)           ; n,CONNECT / n,CLOSED / n,CONNECT FAIL [8356]
            sub '0'		; Hyp.cls 8357
            cp asm_1_5940_n_ES_NL		; Hyp.cls 8358
            ret nc		; Hyp.cls 8359
            ld c, a		; Hyp.cls 8360
            ld a, (asm_1_5940_n_es_ln + 1)		; Hyp.cls 8361
            cp ','		; Hyp.cls 8362
            ret nz		; Hyp.cls 8363
            ld hl, asm_1_5940_n_es_ln + 2		; Hyp.cls 8364
            ld de, asm_1_5940_n_es_k_conn		; Hyp.cls 8365
            call asm_1_5940_n_es_pfz		; Hyp.cls 8366
            jp z, asm_1_5940_n_es_lconn		; Hyp.cls 8367
            ld hl, asm_1_5940_n_es_ln + 2		; Hyp.cls 8368
            ld de, asm_1_5940_n_es_k_closed		; Hyp.cls 8369
            call asm_1_5940_n_es_pfz		; Hyp.cls 8370
            ret nz		; Hyp.cls 8371
            ld a, c                 ; closed: by the other end (or by us) [8372]
            call asm_1_5940_n_es_ent		; Hyp.cls 8373
            ld (hl), 3		; Hyp.cls 8374
            ret		; Hyp.cls 8375
asm_1_5940_n_es_lconn:		; Hyp.cls 8376
            ld a, c		; Hyp.cls 8377
            call asm_1_5940_n_es_ent		; Hyp.cls 8378
            ld (hl), 0              ; connected: ready [8379]
            ret		; Hyp.cls 8380
asm_1_5940_n_es_ok:		; Hyp.cls 8381
            ld a, (asm_1_5940_n_es_busy)		; Hyp.cls 8382
            cp 4		; Hyp.cls 8383
            ret z                   ; (a send: its > comes next) [8384]
            cp 5		; Hyp.cls 8385
            ret z                   ; (a send: SEND OK comes next) [8386]
            cp 7		; Hyp.cls 8387
            jr z, asm_1_5940_n_es_ok7		; Hyp.cls 8388
            cp 2		; Hyp.cls 8389
            jr nz, asm_1_5940_n_es_ok1		; Hyp.cls 8390
            ld a, (asm_1_5940_n_es_tab + 40)     ; a lookup ended without an address: not found [8391]
            cp 5		; Hyp.cls 8392
            jr nz, asm_1_5940_n_es_ok1		; Hyp.cls 8393
            ld a, 255		; Hyp.cls 8394
            ld (asm_1_5940_n_es_tab + 40), a		; Hyp.cls 8395
asm_1_5940_n_es_ok1:		; Hyp.cls 8396
            cp 3		; Hyp.cls 8397
            jr nz, asm_1_5940_n_es_ok2		; Hyp.cls 8398
            ld a, (asm_1_5940_n_es_bl)           ; a connect's OK: ready (its n,CONNECT may come first) [8399]
            call asm_1_5940_n_es_ent		; Hyp.cls 8400
            ld (hl), 0		; Hyp.cls 8401
asm_1_5940_n_es_ok2:		; Hyp.cls 8402
            xor a		; Hyp.cls 8403
            ld (asm_1_5940_n_es_res), a		; Hyp.cls 8404
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 8405
            ret		; Hyp.cls 8406
asm_1_5940_n_es_ok7:		; Hyp.cls 8407
            xor a		; Hyp.cls 8408
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 8409
            ret		; Hyp.cls 8410
asm_1_5940_n_es_sendok:		; Hyp.cls 8411
            ld a, (asm_1_5940_n_es_bl)		; Hyp.cls 8412
            call asm_1_5940_n_es_ent		; Hyp.cls 8413
            ld (hl), 0              ; sent: ready [8414]
            xor a		; Hyp.cls 8415
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 8416
            ret		; Hyp.cls 8417
asm_1_5940_n_es_err:		; Hyp.cls 8418
            ld a, (asm_1_5940_n_es_busy)		; Hyp.cls 8419
            or a		; Hyp.cls 8420
            ret z		; Hyp.cls 8421
asm_1_5940_n_es_fail:                            ; the command in flight failed [8422]
            ld a, (asm_1_5940_n_es_busy)		; Hyp.cls 8423
            cp 1		; Hyp.cls 8424
            jr z, asm_1_5940_n_es_e1		; Hyp.cls 8425
            cp 6		; Hyp.cls 8426
            jr z, asm_1_5940_n_es_e1		; Hyp.cls 8427
            cp 7		; Hyp.cls 8428
            jr z, asm_1_5940_n_es_e1		; Hyp.cls 8429
            ld a, (asm_1_5940_n_es_bl)		; Hyp.cls 8430
            call asm_1_5940_n_es_ent		; Hyp.cls 8431
            ld (hl), 255		; Hyp.cls 8432
asm_1_5940_n_es_e1:		; Hyp.cls 8433
            ld a, 1		; Hyp.cls 8434
            ld (asm_1_5940_n_es_res), a		; Hyp.cls 8435
            xor a		; Hyp.cls 8436
            ld (asm_1_5940_n_es_busy), a		; Hyp.cls 8437
            ret		; Hyp.cls 8438
asm_1_5940_n_es_dom:                             ; +CIPDOMAIN:a.b.c.d (or "a.b.c.d") [8439]
            ld de, asm_1_5940_n_es_tab + 44		; Hyp.cls 8440
            call asm_1_5940_n_es_ip		; Hyp.cls 8441
            xor a		; Hyp.cls 8442
            ld (asm_1_5940_n_es_tab + 40), a     ; found [8443]
            ret		; Hyp.cls 8444
asm_1_5940_n_es_ipd:                             ; +IPD,n,len: len more bytes waiting on link n [8445]
            ld a, (hl)		; Hyp.cls 8446
            sub '0'		; Hyp.cls 8447
            cp asm_1_5940_n_ES_NL		; Hyp.cls 8448
            ret nc		; Hyp.cls 8449
            ld c, a		; Hyp.cls 8450
            inc hl		; Hyp.cls 8451
            inc hl                  ; (past n,) [8452]
            call asm_1_5940_n_es_num             ; DE = len [8453]
            ld a, c		; Hyp.cls 8454
            push de		; Hyp.cls 8455
            call asm_1_5940_n_es_ent		; Hyp.cls 8456
            inc hl		; Hyp.cls 8457
            inc hl		; Hyp.cls 8458
            ld e, (hl)		; Hyp.cls 8459
            inc hl		; Hyp.cls 8460
            ld d, (hl)		; Hyp.cls 8461
            ex (sp), hl		; Hyp.cls 8462
            add hl, de		; Hyp.cls 8463
            ex de, hl		; Hyp.cls 8464
            pop hl		; Hyp.cls 8465
            ld (hl), d		; Hyp.cls 8466
            dec hl		; Hyp.cls 8467
            ld (hl), e		; Hyp.cls 8468
            ret		; Hyp.cls 8469
; es_capl - IPCONFIG's lines: +CWJAP_CUR:"name","bssid",ch,rssi - connected, its name and signal;
; +CIPSTA_CUR:ip:"a.b.c.d" (gateway:, netmask:); +CIPSTAMAC_CUR:"aa:bb:..."
asm_1_5940_n_es_capl:		; Hyp.cls 8472
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8473
            ld de, asm_1_5940_n_es_k_jap		; Hyp.cls 8474
            call asm_1_5940_n_es_pfx		; Hyp.cls 8475
            jr nz, asm_1_5940_n_es_cp2		; Hyp.cls 8476
            ld a, 2		; Hyp.cls 8477
            ld (asm_1_5940_n_nt_pk + 192), a     ; connected [8478]
            ld de, asm_1_5940_n_nt_pk + 220      ; "Connected to " and the name [8479]
            push hl		; Hyp.cls 8480
            ld hl, asm_1_5940_n_es_k_conto		; Hyp.cls 8481
            ld bc, 13		; Hyp.cls 8482
            ldir		; Hyp.cls 8483
            pop hl		; Hyp.cls 8484
            inc hl                  ; (past ") [8485]
            ld b, 17		; Hyp.cls 8486
asm_1_5940_n_es_cp1:		; Hyp.cls 8487
            ld a, (hl)		; Hyp.cls 8488
            cp '"'		; Hyp.cls 8489
            jr z, asm_1_5940_n_es_cp1b		; Hyp.cls 8490
            or a		; Hyp.cls 8491
            jr z, asm_1_5940_n_es_cp1b		; Hyp.cls 8492
            ld (de), a		; Hyp.cls 8493
            inc hl		; Hyp.cls 8494
            inc de		; Hyp.cls 8495
            djnz asm_1_5940_n_es_cp1		; Hyp.cls 8496
asm_1_5940_n_es_cp1b:		; Hyp.cls 8497
            ld hl, asm_1_5940_n_es_ln            ; the signal: after the last comma, -n [8498]
            ld a, (asm_1_5940_n_es_lp)		; Hyp.cls 8499
            ld e, a		; Hyp.cls 8500
            ld d, 0		; Hyp.cls 8501
            add hl, de		; Hyp.cls 8502
asm_1_5940_n_es_cp1c:		; Hyp.cls 8503
            dec hl		; Hyp.cls 8504
            ld a, (hl)		; Hyp.cls 8505
            cp ','		; Hyp.cls 8506
            jr nz, asm_1_5940_n_es_cp1c		; Hyp.cls 8507
            inc hl		; Hyp.cls 8508
            ld a, (hl)		; Hyp.cls 8509
            cp '-'		; Hyp.cls 8510
            ret nz		; Hyp.cls 8511
            inc hl		; Hyp.cls 8512
            call asm_1_5940_n_es_num		; Hyp.cls 8513
            ld a, e		; Hyp.cls 8514
            ld (asm_1_5940_n_nt_pk + 193), a		; Hyp.cls 8515
            ret		; Hyp.cls 8516
asm_1_5940_n_es_cp2:		; Hyp.cls 8517
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8518
            ld de, asm_1_5940_n_es_k_sta		; Hyp.cls 8519
            call asm_1_5940_n_es_pfx		; Hyp.cls 8520
            jr nz, asm_1_5940_n_es_cp5		; Hyp.cls 8521
            ld de, asm_1_5940_n_es_k_ip		; Hyp.cls 8522
            push hl		; Hyp.cls 8523
            call asm_1_5940_n_es_pfx		; Hyp.cls 8524
            pop bc		; Hyp.cls 8525
            jr nz, asm_1_5940_n_es_cp3		; Hyp.cls 8526
            ld de, asm_1_5940_n_nt_pk + 194		; Hyp.cls 8527
            jp asm_1_5940_n_es_ip		; Hyp.cls 8528
asm_1_5940_n_es_cp3:		; Hyp.cls 8529
            ld h, b		; Hyp.cls 8530
            ld l, c		; Hyp.cls 8531
            ld de, asm_1_5940_n_es_k_mask		; Hyp.cls 8532
            push hl		; Hyp.cls 8533
            call asm_1_5940_n_es_pfx		; Hyp.cls 8534
            pop bc		; Hyp.cls 8535
            jr nz, asm_1_5940_n_es_cp4		; Hyp.cls 8536
            ld de, asm_1_5940_n_nt_pk + 198		; Hyp.cls 8537
            jp asm_1_5940_n_es_ip		; Hyp.cls 8538
asm_1_5940_n_es_cp4:		; Hyp.cls 8539
            ld h, b		; Hyp.cls 8540
            ld l, c		; Hyp.cls 8541
            ld de, asm_1_5940_n_es_k_gw		; Hyp.cls 8542
            call asm_1_5940_n_es_pfx		; Hyp.cls 8543
            ret nz		; Hyp.cls 8544
            ld de, asm_1_5940_n_nt_pk + 202		; Hyp.cls 8545
            jp asm_1_5940_n_es_ip		; Hyp.cls 8546
asm_1_5940_n_es_cp5:		; Hyp.cls 8547
            ld hl, asm_1_5940_n_es_ln		; Hyp.cls 8548
            ld de, asm_1_5940_n_es_k_mac		; Hyp.cls 8549
            call asm_1_5940_n_es_pfx		; Hyp.cls 8550
            ret nz		; Hyp.cls 8551
            inc hl                  ; (past ") [8552]
            ld de, asm_1_5940_n_nt_pk + 214		; Hyp.cls 8553
            ld b, 6		; Hyp.cls 8554
asm_1_5940_n_es_cp6:		; Hyp.cls 8555
            call asm_1_5940_n_es_hex2		; Hyp.cls 8556
            ld (de), a		; Hyp.cls 8557
            inc de		; Hyp.cls 8558
            inc hl                  ; (past :) [8559]
            djnz asm_1_5940_n_es_cp6		; Hyp.cls 8560
            ret		; Hyp.cls 8561
; ---- the pieces
; es_pfx - Z when the text at HL starts with DE's (0 at its end); HL then past it
asm_1_5940_n_es_pfx:		; Hyp.cls 8564
            ld a, (de)		; Hyp.cls 8565
            or a		; Hyp.cls 8566
            ret z		; Hyp.cls 8567
            cp (hl)		; Hyp.cls 8568
            ret nz		; Hyp.cls 8569
            inc hl		; Hyp.cls 8570
            inc de		; Hyp.cls 8571
            jr asm_1_5940_n_es_pfx		; Hyp.cls 8572
; es_pfz - Z when the text at HL is DE's, all of it
asm_1_5940_n_es_pfz:		; Hyp.cls 8574
            call asm_1_5940_n_es_pfx		; Hyp.cls 8575
            ret nz		; Hyp.cls 8576
            ld a, (hl)		; Hyp.cls 8577
            or a		; Hyp.cls 8578
            ret		; Hyp.cls 8579
; es_num - DE = the decimal number at HL (HL past it)
asm_1_5940_n_es_num:		; Hyp.cls 8581
            ld de, 0		; Hyp.cls 8582
asm_1_5940_n_es_nu1:		; Hyp.cls 8583
            ld a, (hl)		; Hyp.cls 8584
            sub '0'		; Hyp.cls 8585
            ret c		; Hyp.cls 8586
            cp 10		; Hyp.cls 8587
            ret nc		; Hyp.cls 8588
            push hl		; Hyp.cls 8589
            ld h, d		; Hyp.cls 8590
            ld l, e		; Hyp.cls 8591
            add hl, hl		; Hyp.cls 8592
            add hl, hl		; Hyp.cls 8593
            add hl, de		; Hyp.cls 8594
            add hl, hl		; Hyp.cls 8595
            ld e, a		; Hyp.cls 8596
            ld d, 0		; Hyp.cls 8597
            add hl, de		; Hyp.cls 8598
            ex de, hl		; Hyp.cls 8599
            pop hl		; Hyp.cls 8600
            inc hl		; Hyp.cls 8601
            jr asm_1_5940_n_es_nu1		; Hyp.cls 8602
; es_ip - a.b.c.d at HL (a " before it skipped) into the 4 bytes at DE
asm_1_5940_n_es_ip:		; Hyp.cls 8604
            ld a, (hl)		; Hyp.cls 8605
            cp '"'		; Hyp.cls 8606
            jr nz, asm_1_5940_n_es_ip1		; Hyp.cls 8607
            inc hl		; Hyp.cls 8608
asm_1_5940_n_es_ip1:		; Hyp.cls 8609
            ld b, 4		; Hyp.cls 8610
asm_1_5940_n_es_ip2:		; Hyp.cls 8611
            push de		; Hyp.cls 8612
            call asm_1_5940_n_es_num		; Hyp.cls 8613
            ld a, e		; Hyp.cls 8614
            pop de		; Hyp.cls 8615
            ld (de), a		; Hyp.cls 8616
            inc de		; Hyp.cls 8617
            inc hl                  ; (past .) [8618]
            djnz asm_1_5940_n_es_ip2		; Hyp.cls 8619
            ret		; Hyp.cls 8620
; es_hex2 - A = the two hex digits at HL (HL past them)
asm_1_5940_n_es_hex2:		; Hyp.cls 8622
            call asm_1_5940_n_es_hex1		; Hyp.cls 8623
            add a, a		; Hyp.cls 8624
            add a, a		; Hyp.cls 8625
            add a, a		; Hyp.cls 8626
            add a, a		; Hyp.cls 8627
            ld c, a		; Hyp.cls 8628
            call asm_1_5940_n_es_hex1		; Hyp.cls 8629
            or c		; Hyp.cls 8630
            ret		; Hyp.cls 8631
asm_1_5940_n_es_hex1:		; Hyp.cls 8632
            ld a, (hl)		; Hyp.cls 8633
            inc hl		; Hyp.cls 8634
            or #20		; Hyp.cls 8635
            sub '0'		; Hyp.cls 8636
            cp 10		; Hyp.cls 8637
            ret c		; Hyp.cls 8638
            sub 'a' - '0' - 10		; Hyp.cls 8639
            and 15		; Hyp.cls 8640
            ret		; Hyp.cls 8641
; es_ent - HL = link A's 8 bytes in es_tab (255: the lookup's, the sixth)
asm_1_5940_n_es_ent:		; Hyp.cls 8643
            cp 255		; Hyp.cls 8644
            jr nz, asm_1_5940_n_es_en1		; Hyp.cls 8645
            ld a, 5		; Hyp.cls 8646
asm_1_5940_n_es_en1:		; Hyp.cls 8647
            ld l, a		; Hyp.cls 8648
            ld h, 0		; Hyp.cls 8649
            add hl, hl		; Hyp.cls 8650
            add hl, hl		; Hyp.cls 8651
            add hl, hl		; Hyp.cls 8652
            ld de, asm_1_5940_n_es_tab		; Hyp.cls 8653
            add hl, de		; Hyp.cls 8654
            ret		; Hyp.cls 8655
; es_put - A to the ESP (when its send buffer has room); es_puts - the text at HL (0 at its end)
asm_1_5940_n_es_put:		; Hyp.cls 8657
            push bc		; Hyp.cls 8658
            push af		; Hyp.cls 8659
            ld bc, asm_1_5940_n_ES_TX		; Hyp.cls 8660
asm_1_5940_n_es_pt1:		; Hyp.cls 8661
            in a, (c)		; Hyp.cls 8662
            and 2		; Hyp.cls 8663
            jr nz, asm_1_5940_n_es_pt1		; Hyp.cls 8664
            pop af		; Hyp.cls 8665
            out (c), a		; Hyp.cls 8666
            pop bc		; Hyp.cls 8667
            ret		; Hyp.cls 8668
asm_1_5940_n_es_puts:		; Hyp.cls 8669
            ld a, (hl)		; Hyp.cls 8670
            or a		; Hyp.cls 8671
            ret z		; Hyp.cls 8672
            call asm_1_5940_n_es_put		; Hyp.cls 8673
            inc hl		; Hyp.cls 8674
            jr asm_1_5940_n_es_puts		; Hyp.cls 8675
asm_1_5940_n_es_crlf:		; Hyp.cls 8676
            ld a, 13		; Hyp.cls 8677
            call asm_1_5940_n_es_put		; Hyp.cls 8678
            ld a, 10		; Hyp.cls 8679
            jr asm_1_5940_n_es_put		; Hyp.cls 8680
; es_putdec - HL in decimal to the ESP
asm_1_5940_n_es_putdec:		; Hyp.cls 8682
            ld de, 10000		; Hyp.cls 8683
            ld b, 0                 ; (B: a digit sent - the noughts after it too) [8684]
            call asm_1_5940_n_es_pd1		; Hyp.cls 8685
            ld de, 1000		; Hyp.cls 8686
            call asm_1_5940_n_es_pd1		; Hyp.cls 8687
            ld de, 100		; Hyp.cls 8688
            call asm_1_5940_n_es_pd1		; Hyp.cls 8689
            ld de, 10		; Hyp.cls 8690
            call asm_1_5940_n_es_pd1		; Hyp.cls 8691
            ld a, l		; Hyp.cls 8692
            add a, '0'		; Hyp.cls 8693
            jr asm_1_5940_n_es_put		; Hyp.cls 8694
asm_1_5940_n_es_pd1:		; Hyp.cls 8695
            ld a, '0' - 1		; Hyp.cls 8696
asm_1_5940_n_es_pd2:		; Hyp.cls 8697
            inc a		; Hyp.cls 8698
            or a		; Hyp.cls 8699
            sbc hl, de		; Hyp.cls 8700
            jr nc, asm_1_5940_n_es_pd2		; Hyp.cls 8701
            add hl, de		; Hyp.cls 8702
            cp '0'		; Hyp.cls 8703
            jr nz, asm_1_5940_n_es_pd3		; Hyp.cls 8704
            inc b		; Hyp.cls 8705
            dec b		; Hyp.cls 8706
            ret z		; Hyp.cls 8707
asm_1_5940_n_es_pd3:		; Hyp.cls 8708
            ld b, 1		; Hyp.cls 8709
            jr asm_1_5940_n_es_put		; Hyp.cls 8710
; es_flush - what the ESP has said so far thrown away
asm_1_5940_n_es_flush:		; Hyp.cls 8712
            ld bc, asm_1_5940_n_ES_TX		; Hyp.cls 8713
            in a, (c)		; Hyp.cls 8714
            and 1		; Hyp.cls 8715
            ret z		; Hyp.cls 8716
            ld bc, asm_1_5940_n_ES_RX		; Hyp.cls 8717
            in a, (c)		; Hyp.cls 8718
            jr asm_1_5940_n_es_flush		; Hyp.cls 8719
asm_1_5940_n_es_s_at:    db "AT", 0		; Hyp.cls 8720
asm_1_5940_n_es_s_e0:    db "ATE0", 0		; Hyp.cls 8721
asm_1_5940_n_es_s_cl5:   db "AT+CIPCLOSE=5", 0		; Hyp.cls 8722
asm_1_5940_n_es_s_mux:   db "AT+CIPMUX=1", 0		; Hyp.cls 8723
asm_1_5940_n_es_s_rcv:   db "AT+CIPRECVMODE=1", 0		; Hyp.cls 8724
asm_1_5940_n_es_s_dom:   db "AT+CIPDOMAIN=", 34, 0		; Hyp.cls 8725
asm_1_5940_n_es_s_start: db "AT+CIPSTART=", 0		; Hyp.cls 8726
asm_1_5940_n_es_s_tcp:   db ",", 34, "TCP", 34, ",", 34, 0		; Hyp.cls 8727
asm_1_5940_n_es_s_send:  db "AT+CIPSEND=", 0		; Hyp.cls 8728
asm_1_5940_n_es_s_rdat:  db "AT+CIPRECVDATA=", 0		; Hyp.cls 8729
asm_1_5940_n_es_s_close: db "AT+CIPCLOSE=", 0		; Hyp.cls 8730
asm_1_5940_n_es_s_jap:   db "AT+CWJAP_CUR?", 0		; Hyp.cls 8731
asm_1_5940_n_es_s_sta:   db "AT+CIPSTA_CUR?", 0		; Hyp.cls 8732
asm_1_5940_n_es_s_mac:   db "AT+CIPSTAMAC_CUR?", 0		; Hyp.cls 8733
asm_1_5940_n_es_s_join:  db "AT+CWJAP_DEF=", 34, 0		; Hyp.cls 8734
asm_1_5940_n_es_k_ok:    db "OK", 0		; Hyp.cls 8735
asm_1_5940_n_es_k_sendok: db "SEND OK", 0		; Hyp.cls 8736
asm_1_5940_n_es_k_err:   db "ERROR", 0		; Hyp.cls 8737
asm_1_5940_n_es_k_fail:  db "FAIL", 0		; Hyp.cls 8738
asm_1_5940_n_es_k_sfail: db "SEND FAIL", 0		; Hyp.cls 8739
asm_1_5940_n_es_k_dom:   db "+CIPDOMAIN:", 0		; Hyp.cls 8740
asm_1_5940_n_es_k_ipd:   db "+IPD,", 0		; Hyp.cls 8741
asm_1_5940_n_es_k_conn:  db "CONNECT", 0		; Hyp.cls 8742
asm_1_5940_n_es_k_closed: db "CLOSED", 0		; Hyp.cls 8743
asm_1_5940_n_es_k_rdat:  db "+CIPRECVDATA", 0		; Hyp.cls 8744
asm_1_5940_n_es_k_jap:   db "+CWJAP_CUR:", 0		; Hyp.cls 8745
asm_1_5940_n_es_k_sta:   db "+CIPSTA_CUR:", 0		; Hyp.cls 8746
asm_1_5940_n_es_k_ip:    db "ip:", 0		; Hyp.cls 8747
asm_1_5940_n_es_k_mask:  db "netmask:", 0		; Hyp.cls 8748
asm_1_5940_n_es_k_gw:    db "gateway:", 0		; Hyp.cls 8749
asm_1_5940_n_es_k_mac:   db "+CIPSTAMAC_CUR:", 0		; Hyp.cls 8750
asm_1_5940_n_es_k_conto: db "Connected to "		; Hyp.cls 8751
asm_1_5940_n_es_busy:    db 0                    ; the command in flight: 0 none, 1 OK awaited, 2 a lookup, 3 a connect, [8752]
asm_1_5940_n_es_bl:      db 0                    ; 4 a send's >, 5 its SEND OK, 6 a close, 7 a receive; es_bl its link [8753]
asm_1_5940_n_es_res:     db 0                    ; the last one's end: 0 OK, 1 an error [8754]
asm_1_5940_n_es_cap:     db 0                    ; 1: IPCONFIG's lines to es_capl [8755]
asm_1_5940_n_es_lp:      db 0                    ; the line so far: its length, its text [8756]
asm_1_5940_n_es_ln:      ds 96		; Hyp.cls 8757
asm_1_5940_n_es_tab:     ds 48                   ; links 0-4 and the lookup's: 8 bytes each [8758]
asm_1_5940_n_es_sl:      dw 0                    ; a send's length (its data in nt_pk) [8759]
asm_1_5940_n_es_rn:      dw 0                    ; a receive's: how many came (in nt_pk) [8760]
asm_1_5940_n_es_t0:      dw 0                    ; the clock when the command in flight was sent [8761]
asm_1_5940_n_es_f0:      dw 0                    ; frames (es_now) when a wait began [8762]
asm_1_5940_n_es_f1:      dw 0		; Hyp.cls 8763
asm_1_5940_n_es_frm:     dw 0                    ; frames counted [8764]
asm_1_5940_n_es_lln:     dw 0                    ; the raster's line last seen [8765]
    ENDIF		; Hyp.cls 8766

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
asm_1_5940_n_PT_N:       equ 8		; Hyp.cls 8783
asm_1_5940_n_PT_SZ:      equ 140		; Hyp.cls 8784
asm_1_5940_n_sv_port:		; Hyp.cls 8785
            ld (asm_1_5940_n_pt_op), a		; Hyp.cls 8786
            call asm_1_5940_n_pt_find            ; Z: HL = the port named Byte(2-9); pt_fr: a free record (0: none) [8787]
            ld (asm_1_5940_n_pt_rec), hl		; Hyp.cls 8788
            ld a, 0		; Hyp.cls 8789
            jr z, asm_1_5940_n_sp_f		; Hyp.cls 8790
            inc a		; Hyp.cls 8791
asm_1_5940_n_sp_f:		; Hyp.cls 8792
            ld (asm_1_5940_n_pt_has), a          ; 0 there, 1 not [8793]
            ld a, (var_hyp_svc_t)		; Hyp.cls 8794
            ld (asm_1_5940_n_pt_me), a		; Hyp.cls 8795
            ld a, (asm_1_5940_n_sv_blk + 12)     ; the length: 128 at most [8796]
            cp 129		; Hyp.cls 8797
            jr c, asm_1_5940_n_sp_l		; Hyp.cls 8798
            ld a, 128		; Hyp.cls 8799
            ld (asm_1_5940_n_sv_blk + 12), a		; Hyp.cls 8800
asm_1_5940_n_sp_l:		; Hyp.cls 8801
            ld a, (asm_1_5940_n_pt_op)		; Hyp.cls 8802
            cp 28		; Hyp.cls 8803
            jr z, asm_1_5940_n_pt_open		; Hyp.cls 8804
            ld a, (asm_1_5940_n_pt_has)		; Hyp.cls 8805
            or a		; Hyp.cls 8806
            jr nz, asm_1_5940_n_pt_two           ; (no such port) [8807]
            ld hl, (asm_1_5940_n_pt_rec)		; Hyp.cls 8808
            ld a, (asm_1_5940_n_pt_op)		; Hyp.cls 8809
            cp 29		; Hyp.cls 8810
            jr z, asm_1_5940_n_pt_close		; Hyp.cls 8811
            cp 30		; Hyp.cls 8812
            jp z, asm_1_5940_n_pt_call		; Hyp.cls 8813
            cp 31		; Hyp.cls 8814
            jp z, asm_1_5940_n_pt_poll		; Hyp.cls 8815
            cp 32		; Hyp.cls 8816
            jp z, asm_1_5940_n_pt_recv		; Hyp.cls 8817
            jp asm_1_5940_n_pt_reply		; Hyp.cls 8818
asm_1_5940_n_pt_two:		; Hyp.cls 8819
            ld a, 2		; Hyp.cls 8820
            jr asm_1_5940_n_pt_ret		; Hyp.cls 8821
asm_1_5940_n_pt_one:		; Hyp.cls 8822
            ld a, 1		; Hyp.cls 8823
asm_1_5940_n_pt_ret:		; Hyp.cls 8824
            ld sp, (asm_1_5940_n_sv_sp)		; Hyp.cls 8825
            ret		; Hyp.cls 8826
; 28: open
asm_1_5940_n_pt_open:		; Hyp.cls 8828
            ld a, (asm_1_5940_n_pt_has)		; Hyp.cls 8829
            or a		; Hyp.cls 8830
            jr nz, asm_1_5940_n_po_new		; Hyp.cls 8831
            ld hl, (asm_1_5940_n_pt_rec)		; Hyp.cls 8832
            ld a, (asm_1_5940_n_pt_me)		; Hyp.cls 8833
            cp (hl)		; Hyp.cls 8834
            jp z, asm_1_5940_n_sv_ok		; Hyp.cls 8835
            jr asm_1_5940_n_pt_two		; Hyp.cls 8836
asm_1_5940_n_po_new:		; Hyp.cls 8837
            ld hl, (asm_1_5940_n_pt_fr)		; Hyp.cls 8838
            ld a, h		; Hyp.cls 8839
            or l		; Hyp.cls 8840
            jp z, asm_1_5940_n_sv_err		; Hyp.cls 8841
            ld a, (asm_1_5940_n_pt_me)		; Hyp.cls 8842
            ld (hl), a		; Hyp.cls 8843
            inc hl		; Hyp.cls 8844
            ex de, hl		; Hyp.cls 8845
            ld hl, asm_1_5940_n_sv_blk + 2		; Hyp.cls 8846
            ld bc, 8		; Hyp.cls 8847
            ldir		; Hyp.cls 8848
            ex de, hl		; Hyp.cls 8849
            xor a		; Hyp.cls 8850
            ld (hl), a              ; free [8851]
            inc hl		; Hyp.cls 8852
            ld (hl), a              ; no caller [8853]
            jp asm_1_5940_n_sv_ok		; Hyp.cls 8854
; 29: close
asm_1_5940_n_pt_close:		; Hyp.cls 8856
            ld a, (asm_1_5940_n_pt_me)		; Hyp.cls 8857
            cp (hl)		; Hyp.cls 8858
            jr nz, asm_1_5940_n_pt_two		; Hyp.cls 8859
            ld (hl), 0		; Hyp.cls 8860
            jp asm_1_5940_n_sv_ok		; Hyp.cls 8861
; 30: call - the message into the box (the box busy: 1)
asm_1_5940_n_pt_call:		; Hyp.cls 8863
            ld de, 9		; Hyp.cls 8864
            add hl, de		; Hyp.cls 8865
            ld a, (hl)		; Hyp.cls 8866
            or a		; Hyp.cls 8867
            jr nz, asm_1_5940_n_pt_one		; Hyp.cls 8868
            inc hl		; Hyp.cls 8869
            ld a, (asm_1_5940_n_pt_me)		; Hyp.cls 8870
            ld (hl), a              ; the caller [8871]
            inc hl		; Hyp.cls 8872
            ld a, (asm_1_5940_n_sv_blk + 12)		; Hyp.cls 8873
            ld (hl), a              ; the length [8874]
            inc hl		; Hyp.cls 8875
            ex de, hl               ; DE = the box [8876]
            ld c, a		; Hyp.cls 8877
            ld b, 0		; Hyp.cls 8878
            ld a, b		; Hyp.cls 8879
            or c		; Hyp.cls 8880
            jr z, asm_1_5940_n_pc_0		; Hyp.cls 8881
            ld hl, (asm_1_5940_n_sv_blk + 10)		; Hyp.cls 8882
            call asm_1_5940_n_sv_in		; Hyp.cls 8883
asm_1_5940_n_pc_0:		; Hyp.cls 8884
            ld hl, (asm_1_5940_n_pt_rec)		; Hyp.cls 8885
            ld de, 9		; Hyp.cls 8886
            add hl, de		; Hyp.cls 8887
            ld (hl), 1              ; a message in [8888]
            jp asm_1_5940_n_sv_ok		; Hyp.cls 8889
; 31: the answer to this slot's call
asm_1_5940_n_pt_poll:		; Hyp.cls 8891
            ld de, 9		; Hyp.cls 8892
            add hl, de		; Hyp.cls 8893
            ld a, (hl)		; Hyp.cls 8894
            or a		; Hyp.cls 8895
            jp z, asm_1_5940_n_pt_two            ; (no call) [8896]
            inc hl		; Hyp.cls 8897
            ld a, (asm_1_5940_n_pt_me)		; Hyp.cls 8898
            cp (hl)		; Hyp.cls 8899
            jp nz, asm_1_5940_n_pt_two           ; (not this slot's call) [8900]
            dec hl		; Hyp.cls 8901
            ld a, (hl)		; Hyp.cls 8902
            cp 3		; Hyp.cls 8903
            jp nz, asm_1_5940_n_pt_one           ; not answered yet [8904]
            ld (hl), 0              ; the box free again [8905]
            inc hl		; Hyp.cls 8906
            ld (hl), 0		; Hyp.cls 8907
            call asm_1_5940_n_pt_give            ; the answer to the slot, its length to Byte(12) [8908]
            jp asm_1_5940_n_sv_ok		; Hyp.cls 8909
; 32: the server's next message
asm_1_5940_n_pt_recv:		; Hyp.cls 8911
            ld a, (asm_1_5940_n_pt_me)		; Hyp.cls 8912
            cp (hl)		; Hyp.cls 8913
            jp nz, asm_1_5940_n_pt_two		; Hyp.cls 8914
            ld de, 9		; Hyp.cls 8915
            add hl, de		; Hyp.cls 8916
            ld a, (hl)		; Hyp.cls 8917
            cp 1		; Hyp.cls 8918
            jp nz, asm_1_5940_n_pt_one           ; nothing in [8919]
            ld (hl), 2              ; received [8920]
            call asm_1_5940_n_pt_give		; Hyp.cls 8921
            jp asm_1_5940_n_sv_ok		; Hyp.cls 8922
; 33: the server's reply
asm_1_5940_n_pt_reply:		; Hyp.cls 8924
            ld a, (asm_1_5940_n_pt_me)		; Hyp.cls 8925
            cp (hl)		; Hyp.cls 8926
            jp nz, asm_1_5940_n_pt_two		; Hyp.cls 8927
            ld de, 9		; Hyp.cls 8928
            add hl, de		; Hyp.cls 8929
            ld a, (hl)		; Hyp.cls 8930
            cp 2		; Hyp.cls 8931
            jp nz, asm_1_5940_n_pt_two           ; (nothing received to reply to) [8932]
            inc hl		; Hyp.cls 8933
            ld a, (hl)		; Hyp.cls 8934
            dec hl		; Hyp.cls 8935
            or a		; Hyp.cls 8936
            jr nz, asm_1_5940_n_pr_1		; Hyp.cls 8937
            ld (hl), a              ; its caller gone: dropped, the box free [8938]
            jp asm_1_5940_n_sv_ok		; Hyp.cls 8939
asm_1_5940_n_pr_1:		; Hyp.cls 8940
            ld (hl), 3              ; answered [8941]
            inc hl		; Hyp.cls 8942
            inc hl		; Hyp.cls 8943
            ld a, (asm_1_5940_n_sv_blk + 12)		; Hyp.cls 8944
            ld (hl), a		; Hyp.cls 8945
            inc hl		; Hyp.cls 8946
            ex de, hl		; Hyp.cls 8947
            ld c, a		; Hyp.cls 8948
            ld b, 0		; Hyp.cls 8949
            ld a, b		; Hyp.cls 8950
            or c		; Hyp.cls 8951
            jp z, asm_1_5940_n_sv_ok		; Hyp.cls 8952
            ld hl, (asm_1_5940_n_sv_blk + 10)		; Hyp.cls 8953
            call asm_1_5940_n_sv_in		; Hyp.cls 8954
            jp asm_1_5940_n_sv_ok		; Hyp.cls 8955
; 34: port Byte(1) (0-7) - its name to the request's Byte(2-9), its slot to Byte(10) (0: free);
; 255 no such port number (PROBE lists the services with it)
asm_1_5940_n_pt_list:		; Hyp.cls 8958
            ld a, (asm_1_5940_n_sv_blk + 1)		; Hyp.cls 8959
            cp asm_1_5940_n_PT_N		; Hyp.cls 8960
            jp nc, asm_1_5940_n_sv_err		; Hyp.cls 8961
            ld hl, asm_1_5940_n_pt_tab		; Hyp.cls 8962
            ld de, asm_1_5940_n_PT_SZ		; Hyp.cls 8963
            or a		; Hyp.cls 8964
            jr z, asm_1_5940_n_pl_2		; Hyp.cls 8965
            ld b, a		; Hyp.cls 8966
asm_1_5940_n_pl_1:		; Hyp.cls 8967
            add hl, de		; Hyp.cls 8968
            djnz asm_1_5940_n_pl_1		; Hyp.cls 8969
asm_1_5940_n_pl_2:		; Hyp.cls 8970
            ld a, (hl)              ; the slot (0 free) [8971]
            inc hl		; Hyp.cls 8972
            ld de, asm_1_5940_n_sv_rec		; Hyp.cls 8973
            ld bc, 8		; Hyp.cls 8974
            ldir		; Hyp.cls 8975
            ld (de), a		; Hyp.cls 8976
            ld hl, (var_hyp_svc_p)		; Hyp.cls 8977
            ld de, 2		; Hyp.cls 8978
            add hl, de		; Hyp.cls 8979
            ex de, hl		; Hyp.cls 8980
            ld hl, asm_1_5940_n_sv_rec		; Hyp.cls 8981
            ld bc, 9		; Hyp.cls 8982
            call asm_1_5940_n_sv_out		; Hyp.cls 8983
            jp asm_1_5940_n_sv_ok		; Hyp.cls 8984
; pt_give - the port's box (pt_rec) to the slot's Word(10); its length and the caller to the
; request's Byte(12), Byte(13)
asm_1_5940_n_pt_give:		; Hyp.cls 8987
            ld hl, (asm_1_5940_n_pt_rec)		; Hyp.cls 8988
            ld de, 10		; Hyp.cls 8989
            add hl, de		; Hyp.cls 8990
            ld a, (hl)		; Hyp.cls 8991
            ld (asm_1_5940_n_pt_tmp + 1), a      ; the caller [8992]
            inc hl		; Hyp.cls 8993
            ld a, (hl)		; Hyp.cls 8994
            ld (asm_1_5940_n_pt_tmp), a          ; the length [8995]
            inc hl		; Hyp.cls 8996
            ld c, a		; Hyp.cls 8997
            ld b, 0		; Hyp.cls 8998
            or a		; Hyp.cls 8999
            jr z, asm_1_5940_n_pg_0		; Hyp.cls 9000
            ld de, (asm_1_5940_n_sv_blk + 10)		; Hyp.cls 9001
            call asm_1_5940_n_sv_out		; Hyp.cls 9002
asm_1_5940_n_pg_0:		; Hyp.cls 9003
            ld hl, (var_hyp_svc_p)		; Hyp.cls 9004
            ld de, 12		; Hyp.cls 9005
            add hl, de		; Hyp.cls 9006
            ex de, hl		; Hyp.cls 9007
            ld hl, asm_1_5940_n_pt_tmp		; Hyp.cls 9008
            ld bc, 2		; Hyp.cls 9009
            jp asm_1_5940_n_sv_out		; Hyp.cls 9010
; pt_find - Z: HL = the port named sv_blk's Byte(2-9), else NZ; pt_fr: a free record (0 none)
asm_1_5940_n_pt_find:		; Hyp.cls 9012
            ld hl, 0		; Hyp.cls 9013
            ld (asm_1_5940_n_pt_fr), hl		; Hyp.cls 9014
            ld hl, asm_1_5940_n_pt_tab		; Hyp.cls 9015
            ld b, asm_1_5940_n_PT_N		; Hyp.cls 9016
asm_1_5940_n_pf_1:		; Hyp.cls 9017
            ld a, (hl)		; Hyp.cls 9018
            or a		; Hyp.cls 9019
            jr nz, asm_1_5940_n_pf_2		; Hyp.cls 9020
            ld a, (asm_1_5940_n_pt_fr + 1)		; Hyp.cls 9021
            or a		; Hyp.cls 9022
            jr nz, asm_1_5940_n_pf_n		; Hyp.cls 9023
            ld (asm_1_5940_n_pt_fr), hl		; Hyp.cls 9024
            jr asm_1_5940_n_pf_n		; Hyp.cls 9025
asm_1_5940_n_pf_2:		; Hyp.cls 9026
            push hl		; Hyp.cls 9027
            push bc		; Hyp.cls 9028
            inc hl		; Hyp.cls 9029
            ld de, asm_1_5940_n_sv_blk + 2		; Hyp.cls 9030
            ld b, 8		; Hyp.cls 9031
asm_1_5940_n_pf_3:		; Hyp.cls 9032
            ld a, (de)		; Hyp.cls 9033
            cp (hl)		; Hyp.cls 9034
            jr nz, asm_1_5940_n_pf_4		; Hyp.cls 9035
            inc hl		; Hyp.cls 9036
            inc de		; Hyp.cls 9037
            djnz asm_1_5940_n_pf_3		; Hyp.cls 9038
asm_1_5940_n_pf_4:		; Hyp.cls 9039
            pop bc		; Hyp.cls 9040
            pop hl		; Hyp.cls 9041
            ret z		; Hyp.cls 9042
asm_1_5940_n_pf_n:		; Hyp.cls 9043
            ld de, asm_1_5940_n_PT_SZ		; Hyp.cls 9044
            add hl, de		; Hyp.cls 9045
            djnz asm_1_5940_n_pf_1		; Hyp.cls 9046
            or 1		; Hyp.cls 9047
            ret		; Hyp.cls 9048
; pt_free - slot C's ports closed; its calls forgotten (a message not received yet, an answer not
; taken: the box free; one being worked on: its reply dropped). Keeps C
asm_1_5940_n_pt_free:		; Hyp.cls 9051
            ld hl, asm_1_5940_n_pt_tab		; Hyp.cls 9052
            ld b, asm_1_5940_n_PT_N		; Hyp.cls 9053
asm_1_5940_n_pt_fr1:		; Hyp.cls 9054
            ld a, (hl)		; Hyp.cls 9055
            cp c		; Hyp.cls 9056
            jr nz, asm_1_5940_n_pt_fr2		; Hyp.cls 9057
            ld (hl), 0		; Hyp.cls 9058
asm_1_5940_n_pt_fr2:		; Hyp.cls 9059
            push hl		; Hyp.cls 9060
            ld de, 10		; Hyp.cls 9061
            add hl, de		; Hyp.cls 9062
            ld a, (hl)		; Hyp.cls 9063
            cp c		; Hyp.cls 9064
            jr nz, asm_1_5940_n_pt_fr4		; Hyp.cls 9065
            ld (hl), 0              ; no caller [9066]
            dec hl		; Hyp.cls 9067
            ld a, (hl)		; Hyp.cls 9068
            cp 2		; Hyp.cls 9069
            jr z, asm_1_5940_n_pt_fr4            ; (being worked on: its reply dropped then) [9070]
            ld (hl), 0		; Hyp.cls 9071
asm_1_5940_n_pt_fr4:		; Hyp.cls 9072
            pop hl		; Hyp.cls 9073
            ld de, asm_1_5940_n_PT_SZ		; Hyp.cls 9074
            add hl, de		; Hyp.cls 9075
            djnz asm_1_5940_n_pt_fr1		; Hyp.cls 9076
            ret		; Hyp.cls 9077
asm_1_5940_n_pt_op:      db 0		; Hyp.cls 9078
asm_1_5940_n_pt_has:     db 0		; Hyp.cls 9079
asm_1_5940_n_pt_me:      db 0		; Hyp.cls 9080
asm_1_5940_n_pt_rec:     dw 0		; Hyp.cls 9081
asm_1_5940_n_pt_fr:      dw 0		; Hyp.cls 9082
asm_1_5940_n_pt_tmp:     dw 0		; Hyp.cls 9083
asm_1_5940_n_nt_rom:     db 255		; Hyp.cls 9084
asm_1_5940_n_nt_old:     dw 0		; Hyp.cls 9085
asm_1_5940_n_nt_rsp:     dw 0		; Hyp.cls 9086
asm_1_5940_n_nt_skt:     dw 0		; Hyp.cls 9087
asm_1_5940_n_nt_own:     ds asm_1_5940_n_NT_N		; Hyp.cls 9088
asm_1_5940_n_sv_sp:      dw 0		; Hyp.cls 9089
asm_1_5940_n_sv_n:       dw 0		; Hyp.cls 9090
asm_1_5940_n_sv_c:       dw 0		; Hyp.cls 9091
asm_1_5940_n_sv_sk:      db 0		; Hyp.cls 9092
asm_1_5940_n_sv_ss:      dw 0		; Hyp.cls 9093
asm_1_5940_n_sv_sa:      dw 0		; Hyp.cls 9094
asm_1_5940_n_sv_dk:      db 0		; Hyp.cls 9095
asm_1_5940_n_sv_ds:      dw 0		; Hyp.cls 9096
asm_1_5940_n_sv_da:      dw 0		; Hyp.cls 9097
asm_1_5940_n_sv_stop:    db 0		; Hyp.cls 9098
asm_1_5940_n_sv_tj:      db 0		; Hyp.cls 9099
asm_1_5940_n_sv_tn:      db 0		; Hyp.cls 9100
asm_1_5940_n_sv_tsg:     dw 0		; Hyp.cls 9101
asm_1_5940_n_sv_blk:     ds 16		; Hyp.cls 9102
asm_1_5940_n_sv_tmp:     ds 16		; Hyp.cls 9103
asm_1_5940_n_sv_rec:     ds 128		; Hyp.cls 9104
asm_1_5940_n_sv_cl:      ds asm_1_5940_n_CL_N * 10            ; the claims (16-19; table 4) [9105]
asm_1_5940_n_nt_pk:      ds 256                  ; a packet to the M4 (21-27) [9106]
asm_1_5940_n_pt_tab:     ds asm_1_5940_n_PT_N * asm_1_5940_n_PT_SZ         ; the ports (28-33) [9107]
asm_1_5940_n_sv_end:		; Hyp.cls 9108
            ASSERT asm_1_5940_n_sv_end <= #8000, "the service page's code"		; Hyp.cls 9109
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

			; Main.bas 70: Mode 2
			dw kw_model, 2

			; Main.bas 71: #asm
			dw asm_0_71_n

			; Main.bas 152: Hyp.Vdu 0                         ' the firmware's text off (TXT VDU DISABLE): AMSDOS says "NAME.CYB not
			dw p_hyp_vdu_c, lit_0

			; Main.bas 156: k = Memory.Banks()
			dw fn_memory_banks, var_k

			; Main.bas 158: If k < 4 Then Hyp.Vdu 1 : Print "CyborgOS needs 320K" : End
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

			; Main.bas 162: ns = k \ 2                                      ' half the banks are slots (the first bank never:
			dw kw_divvl, var_k, 2, var_ns

			; Main.bas 163: If ns > MAXS Then ns = MAXS                     ' its pages are the hypervisor's)
			dw kw_scpgtvl, var_ns, 20
			dw kw_goto_iffalse_n, if2_1
			dw kw_ltov, 20, var_ns
if2_1:

			; Main.bas 164: Hot.Slots ns                                    ' (more than 10: Control + a number twice is 11-20)
			dw p_hot_slots_c, var_ns

			; Main.bas 168: i = Memory.AllocPage(Memory.TypeUser)           ' (page 1)
			dw fn_memory_allocpage, lit_85, var_i

			; Main.bas 169: hp = Memory.AllocPage(Memory.TypeUser)          ' bank 1's page 0 (C4): the disc buffers ...
			dw fn_memory_allocpage, lit_85, var_hp

			; Main.bas 170: Memory.SelectPage hp
			dw fn_memory_selectpage, var_hp, var_memory_selectpage_selectpage

			; Main.bas 171: Hyp.UsePage                                     ' (its RAM setting, for Hyp.FileCall)
			dw fn_hyp_usepage

			; Main.bas 172: Hyp.FontInit                                    ' (the font into it, at #5000)
			dw fn_hyp_fontinit

			; Main.bas 173: i = Memory.AllocPage(Memory.TypeUser)           ' bank 1's page 1 (C5): the services (Hyp.Svc: BDOS
			dw fn_memory_allocpage, lit_85, var_i

			; Main.bas 174: Memory.SelectPage i                             ' 131 ops 10-15), out of main RAM
			dw fn_memory_selectpage, var_i, var_memory_selectpage_selectpage

			; Main.bas 175: Hyp.UseSvc
			dw fn_hyp_usesvc

			; Main.bas 176: Hyp.SvcVars VarPtr(st), VarPtr(sg), VarPtr(ns), VarPtr(front), VarPtr(dp)
			dw p_hyp_svcvars_c, vp_arr_st, vp_arr_sg, vp_var_ns, vp_var_front, vp_var_dp

			; Main.bas 177: bz = Hyp.FileCall(99, 0, 0, 0, 0, 0, VarPtr(rb)) ' (the bank image and FileCall's page code into it,
			dw p_hyp_filecall_c, lit_99, lit_0, lit_0, lit_0, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_bz

			; Main.bas 180: i = Hyp.Svc(0, 0, 0, VarPtr(rb))                ' (the services' code into the service page: #6000 on)
			dw p_hyp_svc_c, lit_0, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_i

			; Main.bas 181: For i = 0 To ns                                 ' the kernel's bank (0), then the slots'
			dw kw_ztov, var_i
			dw kw_vtov, var_ns, for3_l
			dw kw_forupv_n, var_i, for3_l, for3_e
for3_t:

			; Main.bas 182: bk(i) = Memory.AllocBank()
			dw fn_memory_allocbank, var_memory_allocbank_allocbank
			dw kw_aset, arr_bk, var_i, var_memory_allocbank_allocbank

			; Main.bas 183: Memory.SelectPage Memory.BankPage(bk(i), 0)
			dw kw_aget, arr_bk, var_i, tmp0
			dw p_memory_bankpage_c, tmp0, lit_0
			dw kw_vtov, var_memory_bankpage_bankpage, tmp0
			dw fn_memory_selectpage, tmp0, var_memory_selectpage_selectpage

			; Main.bas 184: sg(i) = Hyp.Setting()
			dw fn_hyp_setting, var_hyp_setting_setting
			dw kw_aset, arr_sg, var_i, var_hyp_setting_setting

			; Main.bas 185: wp(i) = (sg(i) And &HFFF8) Or 7                ' its page 3 (#C000-#FFFF: OBUF, the console) in the window
			dw kw_aget, arr_sg, var_i, tmp1
			dw kw_andvl, tmp1, -8, tmp1
			dw kw_orvl, tmp1, 7, tmp1
			dw kw_aset, arr_wp, var_i, tmp1

			; Main.bas 186: For k = 0 To 3
			dw kw_ztov, var_k
for4_t:

			; Main.bas 187: bpg(i * 4 + k) = Memory.BankPage(bk(i), k)
			dw kw_4x, var_i, tmp0
			dw kw_add, tmp0, var_k, tmp0
			dw kw_aget, arr_bk, var_i, tmp1
			dw p_memory_bankpage_c, tmp1, var_k
			dw kw_aset, arr_bpg, tmp0, var_memory_bankpage_bankpage

			; Main.bas 188: Next
			dw kw_next1l_n, var_k, 3, for4_t
for4_e:

			; Main.bas 195: Next
			dw kw_next1v_n, var_i, for3_l, for3_t
for3_e:

			; Main.bas 196: kwp = wp(0)
			dw kw_vtov, arr_wp, var_kwp

			; Main.bas 199: a = ""
			dw kw_strcpy, var_a, str2

			; Main.bas 200: If Peek(&HBE80) = 67 And Peek(&HBE81) = 89 And Peek(&HBE82) = 66 And Peek(&HBE83) = 32 Then
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

			; Main.bas 201: i = &HBE84
			dw kw_ltov, -16764, var_i

			; Main.bas 202: Do While Peek(i) <> 0 And i < &HBEC0
do6_t:
			dw kw_vptrtov8, var_i, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_ftov, tmp0
			dw kw_scpltvl, var_i, -16704
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do6_e

			; Main.bas 203: a = a + Chr$(Peek(i))
			dw kw_vptrtov8, var_i, tmp1
			dw kw_strchr, stmp1, tmp1
			dw kw_strcat, var_a, stmp1

			; Main.bas 204: i = i + 1
			dw kw_inc, var_i

			; Main.bas 205: Loop
			dw do6_t_go
do6_e:

			; Main.bas 206: a = UCase$(a)
			dw kw_strucase, var_a, var_a

			; Main.bas 207: End If
if5_1:

			; Main.bas 208: i = InStr(a, " KEYREP ")
			dw kw_strinstr, lit_1, var_a, str3, var_i

			; Main.bas 209: If i > 0 Then
			dw kw_scpgtvl, var_i, 0
			dw kw_goto_iffalse_n, if7_1

			; Main.bas 210: k = Val(Mid$(a, i + 8))
			dw kw_addl, var_i, 8, tmp1
			dw kw_strmid, stmp0, var_a, tmp1, lit_255
			dw kw_strval, stmp0, var_k

			; Main.bas 211: If k > 1 Then Hyp.KeyRep k : Hot.Speed k             ' (the double tap's time too: real time, not ticks)
			dw kw_scpgtvl, var_k, 1
			dw kw_goto_iffalse_n, if8_1
			dw p_hyp_keyrep_c, var_k
			dw p_hot_speed_c, var_k
if8_1:

			; Main.bas 212: End If
if7_1:

			; Main.bas 213: bd = 65                                         ' the boot drive: "CYB d" (A without it)
			dw kw_ltov, 65, var_bd

			; Main.bas 215: bd = bz                                         ' MSX: the DOS's current drive (FileCall 99's answer)
			dw kw_vtov, var_bz, var_bd

			; Main.bas 217: If a <> "" Then bd = Asc(a)
			dw kw_strcmpne, var_a, str2
			dw kw_goto_iffalse_n, if9_1
			dw kw_strasc, var_a, var_bd
if9_1:

			; Main.bas 218: mz = 0 : nz = 0
			dw kw_ztov, var_mz
			dw kw_ztov, var_nz

			; Main.bas 220: i = ProbeDiscs()                                ' MSX: no Z made at boot - the commands run from the boot
			dw p_probediscs_c
			dw kw_vtov, var_probediscs_probediscs, var_i

			; Main.bas 240: i = Hyp.Drive(bd)
			dw p_hyp_drive_c, var_bd
			dw kw_vtov, var_hyp_drive_drive, var_i

			; Main.bas 241: dn = "KERNEL.CYB"
			dw kw_strcpy, var_dn, str4

			; Main.bas 242: If Hyp.FileCall(100, VarPtr(dn), 0, 0, Len(dn), 0, 0) <> 0 Then
			dw kw_strlen, var_dn, tmp4
			dw p_hyp_filecall_c, lit_100, vp_var_dn, lit_0, lit_0, tmp4, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, if10_1

			; Main.bas 243: Hyp.Vdu 1 : Mode 1
			dw p_hyp_vdu_c, lit_1
			dw kw_model, 1

			; Main.bas 244: Print "CyborgOS: no KERNEL.CYB"
			dw kw_printstrvar, str5
			dw kw_printnl

			; Main.bas 245: End
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop

			; Main.bas 246: End If
if10_1:

			; Main.bas 247: Install 0
			dw p_install_c, lit_0

			; Main.bas 248: i = Hyp.FileCall(103, KB - &H100, 0, sg(0), &H100, 0, VarPtr(rb))   ' (#0100 to its block)
			dw p_hyp_filecall_c, lit_103, lit_m4864, lit_0, arr_sg, lit_256, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_i

			; Main.bas 249: i = Hyp.FileCall(102, 0, 0, 0, 0, 0, 0)
			dw p_hyp_filecall_c, lit_102, lit_0, lit_0, lit_0, lit_0, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_i

			; Main.bas 250: Launch 0
			dw p_launch_c, lit_0

			; Main.bas 251: Memory.WriteByte Far(0, &H80), 0                ' (no command tail)
			dw p_far_c, lit_0, lit_128
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 252: kra = 0
			dw kw_ztov, var_kra

			; Main.bas 253: Do
do11_t:

			; Main.bas 254: Hyp.Reply kra, kra
			dw p_hyp_reply_c, var_kra, var_kra

			; Main.bas 255: k = Hyp.Run(sg(0))
			dw p_hyp_run_c, arr_sg
			dw kw_vtov, var_hyp_run_run, var_k

			; Main.bas 256: kra = 0
			dw kw_ztov, var_kra

			; Main.bas 257: i = Hyp.Count()
			dw p_hyp_count_c
			dw kw_vtov, var_hyp_count_count, var_i

			; Main.bas 258: If i > 0 Then KShow i
			dw kw_scpgtvl, var_i, 0
			dw kw_goto_iffalse_n, if12_1
			dw p_kshow_c, var_i
if12_1:

			; Main.bas 259: If k = 1 Then
			dw kw_cpeqvl, var_k, 1
			dw kw_goto_iffalse_n, do11_t

			; Main.bas 260: i = Hyp.Fn()
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_i

			; Main.bas 261: If i = 132 Then
			dw kw_cpeqvl, var_i, 132
			dw kw_goto_iffalse_n, if14_1

			; Main.bas 262: Serve
			dw p_serve_c

			; Main.bas 263: ElseIf i = 0 Then
			dw do11_t_go
if14_1:
			dw kw_cpeqvl, var_i, 0
			dw kw_goto_iffalse_n, if14_2

			; Main.bas 264: Quit -1                     ' (the kernel ended: a fault in it)
			dw p_quit_c, lit_m1

			; Main.bas 265: ElseIf i <> 128 And i <> 129 Then
			dw do11_t_go
if14_2:
			dw kw_cpnevl, var_i, 128
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_i, 129
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do11_t

			; Main.bas 266: kra = 255
			dw kw_ltov, 255, var_kra

			; Main.bas 267: End If
if14_3:
if14_e:

			; Main.bas 268: End If
if13_1:

			; Main.bas 269: Loop
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

			; Main.bas 284: Dim t As Integer, c As Integer

			; Main.bas 285: KIn
			dw fn_kin

			; Main.bas 286: t = kw(1)
			dw kw_vtov, arr_kw+2, var_serve_t

			; Main.bas 287: Select Case kw(0)                               ' (the op: the kernel's word, high byte 0)
			dw kw_vtov, arr_kw, var_serve___sel17

			; Main.bas 288: Case 12                                       ' RUN t a k n: up to n And 255 slices, n \ 256 calls here
			dw kw_cpeqvl, var_serve___sel17, 12
			dw kw_goto_iffalse_n, sel17_1
sel17_b1:

			; Main.bas 289: Hyp.Reply kw(2), kw(2)
			dw p_hyp_reply_c, arr_kw+4, arr_kw+4

			; Main.bas 290: kw(11) = 0 : kw(13) = 0 : kw(14) = 0
			dw kw_ztov, arr_kw+22
			dw kw_ztov, arr_kw+26
			dw kw_ztov, arr_kw+28

			; Main.bas 291: c = kw(4) \ 256
			dw kw_divvl, arr_kw+8, 256, var_serve_c

			; Main.bas 292: Do
do18_t:

			; Main.bas 293: kw(8) = Hyp.Run(sg(t))
			dw kw_aget, arr_sg, var_serve_t, tmp0
			dw p_hyp_run_c, tmp0
			dw kw_vtov, var_hyp_run_run, arr_kw+16

			; Main.bas 294: kw(13) = kw(13) + 1
			dw kw_inc, arr_kw+26

			; Main.bas 295: kw(9) = Hyp.Count()
			dw p_hyp_count_c
			dw kw_vtov, var_hyp_count_count, arr_kw+18

			; Main.bas 296: If kw(9) > 0 Then Hyp.Con wp(t), 0, kw(9), IIf(t = front, 1, 0) : kw(11) = kw(11) + kw(9)   ' straight from the bank
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

			; Main.bas 297: If kw(8) = 0 Then
			dw kw_cpeqvl, arr_kw+16, 0
			dw kw_goto_iffalse_n, if21_1

			; Main.bas 298: kw(14) = kw(14) + 1                     ' a slice used
			dw kw_inc, arr_kw+28

			; Main.bas 299: If kw(14) >= (kw(4) And 255) Then Exit Do
			dw kw_andvl, arr_kw+8, 255, tmp1
			dw kw_scpgevv, arr_kw+28, tmp1
			dw kw_goto_iffalse_n, do18_t
			dw do18_e_go
if22_1:

			; Main.bas 300: Else
			dw do18_t_go
if21_1:

			; Main.bas 301: OwnCall t                               ' a BDOS call: answered here if it is C0's (cw 0 on,
			dw p_owncall_c, var_serve_t

			; Main.bas 302: If cw = 1 Then                          ' 2 the turn over, 3 a port's wait), else the kernel's
			dw kw_cpeqvl, var_cw, 1
			dw kw_goto_iffalse_n, if23_1

			; Main.bas 303: kw(9) = Hyp.Fn() : kw(10) = Hyp.Arg()
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, arr_kw+18
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, arr_kw+20

			; Main.bas 304: Exit Do
			dw do18_e_go

			; Main.bas 305: End If
if23_1:

			; Main.bas 306: Hyp.Reply ca, ca
			dw p_hyp_reply_c, var_ca, var_ca

			; Main.bas 307: c = c - 1
			dw kw_dec, var_serve_c

			; Main.bas 308: If cw <> 0 Or c <= 0 Then
			dw kw_cpnevl, var_cw, 0
			dw kw_ftov, tmp0
			dw kw_scplevl, var_serve_c, 0
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do18_t

			; Main.bas 309: kw(8) = cw : kw(9) = ca
			dw kw_vtov, var_cw, arr_kw+16
			dw kw_vtov, var_ca, arr_kw+18

			; Main.bas 310: If cw = 0 Then kw(8) = 2
			dw kw_cpeqvl, var_cw, 0
			dw kw_goto_iffalse_n, do18_e
			dw kw_ltov, 2, arr_kw+16
if25_1:

			; Main.bas 311: Exit Do
			dw do18_e_go

			; Main.bas 312: End If
if24_1:

			; Main.bas 313: End If
if21_e:

			; Main.bas 314: Loop
			dw do18_t_go
do18_e:

			; Main.bas 315: If kw(3) <> 0 Then kw(12) = Memory.ReadByte(Far(t, Hyp.KEY))
			dw kw_cpnevl, arr_kw+6, 0
			dw kw_goto_iffalse_n, sel17_e
			dw p_far_c, var_serve_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, arr_kw+24
if26_1:

			; Main.bas 316: Case 22                                       ' HOT w (once a pass of the kernel's loop)
			dw sel17_e_go
sel17_1:
			dw kw_cpeqvl, var_serve___sel17, 22
			dw kw_goto_iffalse_n, sel17_2
sel17_b2:

			; Main.bas 317: kw(8) = Hot.Take()
			dw p_hot_take_c
			dw kw_vtov, var_hot_take_take, arr_kw+16

			; Main.bas 318: If kw(8) = 0 And t <> 0 Then kw(9) = Inkey : kw(10) = Hot.Control() : kw(11) = Hot.Held()
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

			; Main.bas 319: Case 1
			dw sel17_e_go
sel17_2:
			dw kw_cpeqvl, var_serve___sel17, 1
			dw kw_goto_iffalse_n, sel17_3
sel17_b3:

			; Main.bas 320: kw(8) = Memory.ReadByte(Far(t, kw(2)))
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, arr_kw+16

			; Main.bas 321: Case 2
			dw sel17_e_go
sel17_3:
			dw kw_cpeqvl, var_serve___sel17, 2
			dw kw_goto_iffalse_n, sel17_4
sel17_b4:

			; Main.bas 322: Memory.WriteByte Far(t, kw(2)), kw(3)
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, arr_kw+6

			; Main.bas 323: Case 7                                        ' CON t n f
			dw sel17_e_go
sel17_4:
			dw kw_cpeqvl, var_serve___sel17, 7
			dw kw_goto_iffalse_n, sel17_5
sel17_b5:

			; Main.bas 324: KDIn VarPtr(kd), kw(2)
			dw p_kdin_c, vp_arr_kd, arr_kw+4

			; Main.bas 325: Hyp.Con wp(t), VarPtr(kd), kw(2), kw(3)
			dw kw_aget, arr_wp, var_serve_t, tmp0
			dw p_hyp_con_c, tmp0, vp_arr_kd, arr_kw+4, arr_kw+6

			; Main.bas 326: Case 32
			dw sel17_e_go
sel17_5:
			dw kw_cpeqvl, var_serve___sel17, 32
			dw kw_goto_iffalse_n, sel17_6
sel17_b6:

			; Main.bas 327: kw(8) = Inkey : kw(9) = Hot.Control() : kw(10) = Hot.Held()
			dw kw_inkey, tmp0
			dw kw_vtov, tmp0, arr_kw+16
			dw p_hot_control_c
			dw kw_vtov, var_hot_control_control, arr_kw+18
			dw p_hot_held_c
			dw kw_vtov, var_hot_held_held, arr_kw+20

			; Main.bas 328: Case 3
			dw sel17_e_go
sel17_6:
			dw kw_cpeqvl, var_serve___sel17, 3
			dw kw_goto_iffalse_n, sel17_7
sel17_b7:

			; Main.bas 329: kw(8) = Memory.ReadWord(Far(t, kw(2)))
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readword, ltmp0, arr_kw+16

			; Main.bas 330: Case 4
			dw sel17_e_go
sel17_7:
			dw kw_cpeqvl, var_serve___sel17, 4
			dw kw_goto_iffalse_n, sel17_8
sel17_b8:

			; Main.bas 331: Memory.WriteWord Far(t, kw(2)), kw(3)
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, arr_kw+6

			; Main.bas 332: Case 5                                        ' TOSLOT t a n
			dw sel17_e_go
sel17_8:
			dw kw_cpeqvl, var_serve___sel17, 5
			dw kw_goto_iffalse_n, sel17_9
sel17_b9:

			; Main.bas 333: KDIn VarPtr(kd), kw(3)
			dw p_kdin_c, vp_arr_kd, arr_kw+6

			; Main.bas 334: Memory.Copy NearP(VarPtr(kd)), Far(t, kw(2)), kw(3)
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, arr_kw+6, var_memory_copy_copy

			; Main.bas 335: Case 6                                        ' FROMSLOT t a n
			dw sel17_e_go
sel17_9:
			dw kw_cpeqvl, var_serve___sel17, 6
			dw kw_goto_iffalse_n, sel17_10
sel17_b10:

			; Main.bas 336: Memory.Copy Far(t, kw(2)), NearP(VarPtr(kd)), kw(3)
			dw p_far_c, var_serve_t, arr_kw+4
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, arr_kw+6, var_memory_copy_copy

			; Main.bas 337: KDOut VarPtr(kd), kw(3)
			dw p_kdout_c, vp_arr_kd, arr_kw+6

			; Main.bas 338: Case 8
			dw sel17_e_go
sel17_10:
			dw kw_cpeqvl, var_serve___sel17, 8
			dw kw_goto_iffalse_n, sel17_11
sel17_b11:

			; Main.bas 339: Hyp.Con wp(t), kw(2), kw(3), kw(4)
			dw kw_aget, arr_wp, var_serve_t, tmp0
			dw p_hyp_con_c, tmp0, arr_kw+4, arr_kw+6, arr_kw+8

			; Main.bas 340: Case 9
			dw sel17_e_go
sel17_11:
			dw kw_cpeqvl, var_serve___sel17, 9
			dw kw_goto_iffalse_n, sel17_12
sel17_b12:

			; Main.bas 341: kw(8) = Hyp.Scr(t, kw(2))
			dw p_hyp_scr_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_hyp_scr_scr, arr_kw+16

			; Main.bas 342: Case 13                                       ' FILE f x t d
			dw sel17_e_go
sel17_12:
			dw kw_cpeqvl, var_serve___sel17, 13
			dw kw_goto_iffalse_n, sel17_13
sel17_b13:

			; Main.bas 343: If t = 100 Then
			dw kw_cpeqvl, var_serve_t, 100
			dw kw_goto_iffalse_n, if28_1

			; Main.bas 344: KDIn VarPtr(kd), kw(2)
			dw p_kdin_c, vp_arr_kd, arr_kw+4

			; Main.bas 345: kw(8) = Hyp.FileCall(100, VarPtr(kd), 0, 0, kw(2), 0, 0)
			dw p_hyp_filecall_c, lit_100, vp_arr_kd, lit_0, lit_0, arr_kw+4, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16

			; Main.bas 346: KDOut VarPtr(kd), kw(2)                  ' (NAME.CYB not there, NAME.COM: the name back)
			dw p_kdout_c, vp_arr_kd, arr_kw+4

			; Main.bas 347: ElseIf t >= 100 Then
			dw sel17_e_go
if28_1:
			dw kw_scpgevl, var_serve_t, 100
			dw kw_goto_iffalse_n, if28_2

			; Main.bas 348: kw(8) = Hyp.FileCall(t, kw(2), kw(3), sg(kw(3)), kw(4), 0, VarPtr(rb))
			dw kw_aget, arr_sg, arr_kw+6, tmp3
			dw p_hyp_filecall_c, var_serve_t, arr_kw+4, arr_kw+6, tmp3, arr_kw+8, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16

			; Main.bas 349: Else
			dw sel17_e_go
if28_2:

			; Main.bas 350: kw(8) = Hyp.FileCall(t, kw(2), kw(3), sg(kw(3)), dm(kw(3)), dv(kw(3)), VarPtr(rb))
			dw kw_aget, arr_sg, arr_kw+6, tmp3
			dw kw_aget, arr_dm, arr_kw+6, tmp4
			dw kw_aget, arr_dv, arr_kw+6, tmp5
			dw p_hyp_filecall_c, var_serve_t, arr_kw+4, arr_kw+6, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, arr_kw+16

			; Main.bas 351: End If
if28_e:

			; Main.bas 352: Case 14
			dw sel17_e_go
sel17_13:
			dw kw_cpeqvl, var_serve___sel17, 14
			dw kw_goto_iffalse_n, sel17_14
sel17_b14:

			; Main.bas 353: kw(8) = Hyp.Drive(t)
			dw p_hyp_drive_c, var_serve_t
			dw kw_vtov, var_hyp_drive_drive, arr_kw+16

			; Main.bas 354: Case 28
			dw sel17_e_go
sel17_14:
			dw kw_cpeqvl, var_serve___sel17, 28
			dw kw_goto_iffalse_n, sel17_15
sel17_b15:

			; Main.bas 355: kw(8) = dv(t)
			dw kw_aget, arr_dv, var_serve_t, arr_kw+16

			; Main.bas 356: Case 29
			dw sel17_e_go
sel17_15:
			dw kw_cpeqvl, var_serve___sel17, 29
			dw kw_goto_iffalse_n, sel17_16
sel17_b16:

			; Main.bas 357: dv(t) = kw(2)
			dw kw_aset, arr_dv, var_serve_t, arr_kw+4

			; Main.bas 358: Case 31                                       ' OWNDRIVE t
			dw sel17_e_go
sel17_16:
			dw kw_cpeqvl, var_serve___sel17, 31
			dw kw_goto_iffalse_n, sel17_17
sel17_b17:

			; Main.bas 359: If dv(t) = 0 Then dv(t) = bd
			dw kw_aget, arr_dv, var_serve_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if29_1
			dw kw_aset, arr_dv, var_serve_t, var_bd
if29_1:

			; Main.bas 360: kw(8) = Hyp.Drive(dv(t))
			dw kw_aget, arr_dv, var_serve_t, tmp0
			dw p_hyp_drive_c, tmp0
			dw kw_vtov, var_hyp_drive_drive, arr_kw+16

			; Main.bas 361: Case 16
			dw sel17_e_go
sel17_17:
			dw kw_cpeqvl, var_serve___sel17, 16
			dw kw_goto_iffalse_n, sel17_18
sel17_b18:

			; Main.bas 362: kw(8) = Hyp.Svc(t, kw(2), sg(t), VarPtr(rb))
			dw kw_aget, arr_sg, var_serve_t, tmp2
			dw p_hyp_svc_c, var_serve_t, arr_kw+4, tmp2, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, arr_kw+16

			; Main.bas 363: Case 11                                       ' SAY n col row
			dw sel17_e_go
sel17_18:
			dw kw_cpeqvl, var_serve___sel17, 11
			dw kw_goto_iffalse_n, sel17_19
sel17_b19:

			; Main.bas 364: KDIn VarPtr(kd), t
			dw p_kdin_c, vp_arr_kd, var_serve_t

			; Main.bas 365: Hyp.Say VarPtr(kd), t, kw(2), kw(3)
			dw p_hyp_say_c, vp_arr_kd, var_serve_t, arr_kw+4, arr_kw+6

			; Main.bas 366: Case 10
			dw sel17_e_go
sel17_19:
			dw kw_cpeqvl, var_serve___sel17, 10
			dw kw_goto_iffalse_n, sel17_20
sel17_b20:

			; Main.bas 371: Case 23
			dw sel17_e_go
sel17_20:
			dw kw_cpeqvl, var_serve___sel17, 23
			dw kw_goto_iffalse_n, sel17_21
sel17_b21:

			; Main.bas 379: Case 24
			dw sel17_e_go
sel17_21:
			dw kw_cpeqvl, var_serve___sel17, 24
			dw kw_goto_iffalse_n, sel17_22
sel17_b22:

			; Main.bas 380: st(t) = kw(2)
			dw kw_aset, arr_st, var_serve_t, arr_kw+4

			; Main.bas 381: Case 25
			dw sel17_e_go
sel17_22:
			dw kw_cpeqvl, var_serve___sel17, 25
			dw kw_goto_iffalse_n, sel17_23
sel17_b23:

			; Main.bas 382: front = t
			dw kw_vtov, var_serve_t, var_front

			; Main.bas 383: Case 19
			dw sel17_e_go
sel17_23:
			dw kw_cpeqvl, var_serve___sel17, 19
			dw kw_goto_iffalse_n, sel17_24
sel17_b24:

			; Main.bas 384: Install t
			dw p_install_c, var_serve_t

			; Main.bas 385: Case 30
			dw sel17_e_go
sel17_24:
			dw kw_cpeqvl, var_serve___sel17, 30
			dw kw_goto_iffalse_n, sel17_25
sel17_b25:

			; Main.bas 386: Launch t
			dw p_launch_c, var_serve_t

			; Main.bas 387: Case 15
			dw sel17_e_go
sel17_25:
			dw kw_cpeqvl, var_serve___sel17, 15
			dw kw_goto_iffalse_n, sel17_26
sel17_b26:

			; Main.bas 388: Hyp.FileShut t
			dw p_hyp_fileshut_c, var_serve_t

			; Main.bas 389: c = Hyp.Svc(t, 0, 0, VarPtr(rb))           ' its claims freed (the service page)
			dw p_hyp_svc_c, var_serve_t, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_serve_c

			; Main.bas 390: Case 17
			dw sel17_e_go
sel17_26:
			dw kw_cpeqvl, var_serve___sel17, 17
			dw kw_goto_iffalse_n, sel17_27
sel17_b27:

			; Main.bas 391: kw(8) = RamDisc(t, kw(2))
			dw p_ramdisc_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_ramdisc_ramdisc, arr_kw+16

			; Main.bas 392: Case 18
			dw sel17_e_go
sel17_27:
			dw kw_cpeqvl, var_serve___sel17, 18
			dw kw_goto_iffalse_n, sel17_28
sel17_b28:

			; Main.bas 393: kw(8) = StoreSize(t, kw(2))
			dw p_storesize_c, var_serve_t, arr_kw+4
			dw kw_vtov, var_storesize_storesize, arr_kw+16

			; Main.bas 394: Case 20                                       ' MEMINFO
			dw sel17_e_go
sel17_28:
			dw kw_cpeqvl, var_serve___sel17, 20
			dw kw_goto_iffalse_n, sel17_29
sel17_b29:

			; Main.bas 395: kw(8) = Memory.TableEnd() : kw(9) = Memory.Top() : kw(10) = Memory.Pages()
			dw fn_memory_tableend, arr_kw+16
			dw fn_memory_top, arr_kw+18
			dw fn_memory_pages, arr_kw+20

			; Main.bas 396: kw(11) = Memory.RamSize() : kw(12) = Memory.FreePages()
			dw fn_memory_ramsize, arr_kw+22
			dw fn_memory_freepages, arr_kw+24

			; Main.bas 397: Case 21                                       ' MEMMAP p
			dw sel17_e_go
sel17_29:
			dw kw_cpeqvl, var_serve___sel17, 21
			dw kw_goto_iffalse_n, sel17_30
sel17_b30:

			; Main.bas 398: en = Memory.Map(t, 32)
			dw fn_memory_map, var_serve_t, lit_32, var_memory_map_map
			dw kw_strcpy, var_en, var_memory_map_map

			; Main.bas 399: kw(8) = Len(en)
			dw kw_strlen, var_en, arr_kw+16

			; Main.bas 400: KDOut VarPtr(en), Len(en)
			dw kw_strlen, var_en, tmp1
			dw p_kdout_c, vp_var_en, tmp1

			; Main.bas 401: Case 26                                       ' BOOT
			dw sel17_e_go
sel17_30:
			dw kw_cpeqvl, var_serve___sel17, 26
			dw kw_goto_iffalse_n, sel17_31
sel17_b31:

			; Main.bas 402: kw(8) = ns : kw(9) = bd : kw(11) = mz : kw(12) = LNMAX : kw(13) = nz
			dw kw_vtov, var_ns, arr_kw+16
			dw kw_vtov, var_bd, arr_kw+18
			dw kw_vtov, var_mz, arr_kw+22
			dw kw_ltov, 65, arr_kw+24
			dw kw_vtov, var_nz, arr_kw+26

			; Main.bas 404: kw(10) = 3                                  ' (the host: the MSX - C0 runs the slots, the CPC's keys)
			dw kw_ltov, 3, arr_kw+20

			; Main.bas 408: Case 33                                       ' BOOTDONE
			dw sel17_e_go
sel17_31:
			dw kw_cpeqvl, var_serve___sel17, 33
			dw kw_goto_iffalse_n, sel17_32
sel17_b32:

			; Main.bas 409: Hyp.BootDrive bd, VarPtr(dv)                ' Z, which is made from the archive (RAMDISC.CYB is on A).
			dw p_hyp_bootdrive_c, var_bd, vp_arr_dv

			; Main.bas 410: kw(8) = bd                                  ' (CybSys.BootDrive: CD on it takes a free letter, as on A)
			dw kw_vtov, var_bd, arr_kw+16

			; Main.bas 411: Case 27
			dw sel17_e_go
sel17_32:
			dw kw_cpeqvl, var_serve___sel17, 27
			dw kw_goto_iffalse_n, sel17_33
sel17_b33:

			; Main.bas 412: Quit t
			dw p_quit_c, var_serve_t

			; Main.bas 413: End Select
sel17_33:
sel17_e:

			; Main.bas 414: kw(15) = Hyp.T300()
			dw p_hyp_t300_c
			dw kw_vtov, var_hyp_t300_t300, arr_kw+30

			; Main.bas 415: KOut
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

			; Main.bas 471: #asm
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

			; Main.bas 502: #asm
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

			; Main.bas 532: Dim t As Integer

			; Main.bas 533: t = front
			dw kw_vtov, var_front, var_kshow_t

			; Main.bas 534: If t = 0 Then t = 1
			dw kw_cpeqvl, var_kshow_t, 0
			dw kw_goto_iffalse_n, if30_1
			dw kw_ltov, 1, var_kshow_t
if30_1:

			; Main.bas 535: Memory.Copy Far(0, Hyp.OBUF), NearP(VarPtr(kd)), n
			dw p_far_c, lit_0, lit_m2560
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_arr_kd
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_kshow_n, var_memory_copy_copy

			; Main.bas 536: Hyp.Con wp(t), VarPtr(kd), n, IIf(t = front, 1, 0)
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

			; Main.bas 541: i = Hyp.Scr(0, 2)               ' the screen as at the start (80 x 25)
			dw p_hyp_scr_c, lit_0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_i

			; Main.bas 542: Hyp.Vdu 1
			dw p_hyp_vdu_c, lit_1

			; Main.bas 543: Mode 1
			dw kw_model, 1

			; Main.bas 544: If n < 0 Then
			dw kw_scpltvl, var_quit_n, 0
			dw kw_goto_iffalse_n, if32_1

			; Main.bas 545: Print "CyborgOS: the kernel ended"
			dw kw_printstrvar, str6
			dw kw_printnl

			; Main.bas 546: Else
			dw if32_e_go
if32_1:

			; Main.bas 547: Print "CyborgOS ended, "; n; " programs ran"
			dw kw_printstrvar, str7
			dw kw_printint, var_quit_n
			dw kw_printstrvar, str8
			dw kw_printnl

			; Main.bas 548: End If
if32_e:

			; Main.bas 549: End
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

			; Main.bas 556: Dim f As Integer, e As Integer, j As Integer, o As Integer

			; Main.bas 557: f = Hyp.Fn() : e = Hyp.Arg()
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_owncall_f
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, var_owncall_e

			; Main.bas 558: ca = 0 : cw = 0
			dw kw_ztov, var_ca
			dw kw_ztov, var_cw

			; Main.bas 559: Select Case f
			dw kw_vtov, var_owncall_f, var_owncall___sel33

			; Main.bas 560: Case 128                                      ' only the characters (already shown)
			dw kw_cpeqvl, var_owncall___sel33, 128
			dw kw_goto_iffalse_n, sel33_1
sel33_b1:

			; Main.bas 561: Case 26                                       ' the DMA address (CP/M's record buffer)
			dw sel33_e_go
sel33_1:
			dw kw_cpeqvl, var_owncall___sel33, 26
			dw kw_goto_iffalse_n, sel33_2
sel33_b2:

			; Main.bas 562: dm(t) = e
			dw kw_aset, arr_dm, var_owncall_t, var_owncall_e

			; Main.bas 563: Case 14                                       ' select a disc: the slot's drive (as CD)
			dw sel33_e_go
sel33_2:
			dw kw_cpeqvl, var_owncall___sel33, 14
			dw kw_goto_iffalse_n, sel33_3
sel33_b3:

			; Main.bas 564: dv(t) = 65 + (e And 255)
			dw kw_andvl, var_owncall_e, 255, tmp2
			dw kw_addl, tmp2, 65, tmp1
			dw kw_aset, arr_dv, var_owncall_t, tmp1

			; Main.bas 565: Case 25
			dw sel33_e_go
sel33_3:
			dw kw_cpeqvl, var_owncall___sel33, 25
			dw kw_goto_iffalse_n, sel33_4
sel33_b4:

			; Main.bas 566: If dv(t) <> 0 Then ca = dv(t) - 65
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, sel33_e
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_addl, tmp0, -65, var_ca
if34_1:

			; Main.bas 567: Case 24                                       ' the login vector: the slot's drive (a bit a drive:
			dw sel33_e_go
sel33_4:
			dw kw_cpeqvl, var_owncall___sel33, 24
			dw kw_goto_iffalse_n, sel33_5
sel33_b5:

			; Main.bas 568: ca = 1                                      ' A 1, B 2, C 4 - A to H: the low byte)
			dw kw_ltov, 1, var_ca

			; Main.bas 569: If dv(t) <> 0 Then
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, sel33_e

			; Main.bas 570: For j = 1 To (dv(t) - 65) And 7
			dw kw_ltov, 1, var_owncall_j
			dw kw_aget, arr_dv, var_owncall_t, tmp0
			dw kw_addl, tmp0, -65, tmp0
			dw kw_andvl, tmp0, 7, for36_l
			dw kw_forupv_n, var_owncall_j, for36_l, sel33_e
for36_t:

			; Main.bas 571: ca = ca * 2
			dw kw_2x, var_ca, var_ca

			; Main.bas 572: Next
			dw kw_next1v_n, var_owncall_j, for36_l, for36_t
for36_e:

			; Main.bas 573: End If
if35_1:

			; Main.bas 574: Case 13, 32                                   ' reset the discs; user number: nothing to do
			dw sel33_e_go
sel33_5:
			dw kw_cpeqvl, var_owncall___sel33, 13
			dw kw_goto_iftrue_n, sel33_e
			dw kw_cpeqvl, var_owncall___sel33, 32
			dw kw_goto_iffalse_n, sel33_6
sel33_b6:

			; Main.bas 575: Case 15 To 36                                 ' files: Hyp.FileCall
			dw sel33_e_go
sel33_6:
			dw kw_scpltvl, var_owncall___sel33, 15
			dw kw_goto_iftrue_n, sel33_7
			dw kw_scplevl, var_owncall___sel33, 36
			dw kw_goto_iffalse_n, sel33_7
sel33_b7:

			; Main.bas 576: ca = Hyp.FileCall(f, e, t, sg(t), dm(t), dv(t), VarPtr(rb))
			dw kw_aget, arr_sg, var_owncall_t, tmp3
			dw kw_aget, arr_dm, var_owncall_t, tmp4
			dw kw_aget, arr_dv, var_owncall_t, tmp5
			dw p_hyp_filecall_c, var_owncall_f, var_owncall_e, var_owncall_t, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_ca

			; Main.bas 577: Case 131                                      ' CyborgOS's own: memory, the pointer, the store's
			dw sel33_e_go
sel33_7:
			dw kw_cpeqvl, var_owncall___sel33, 131
			dw kw_goto_iffalse_n, sel33_8
sel33_b8:

			; Main.bas 578: o = Memory.ReadByte(Far(t, e))              ' blocks, tables, the claims (16-19), the network,
			dw p_far_c, var_owncall_t, var_owncall_e
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_owncall_o

			; Main.bas 579: If o = 10 Or o = 11 Or o >= 13 Then        ' the ports (28-33): in the service page
			dw kw_cpeqvl, var_owncall_o, 10
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_owncall_o, 11
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_scpgevl, var_owncall_o, 13
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if37_1

			; Main.bas 580: ca = Hyp.Svc(t, e, sg(t), VarPtr(rb))
			dw kw_aget, arr_sg, var_owncall_t, tmp2
			dw p_hyp_svc_c, var_owncall_t, var_owncall_e, tmp2, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_ca

			; Main.bas 581: If ca = 1 And o >= 30 Then cw = 3         ' (a port's "not yet": the slot sleeps a tick)
			dw kw_cpeqvl, var_ca, 1
			dw kw_ftov, tmp0
			dw kw_scpgevl, var_owncall_o, 30
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, sel33_e
			dw kw_ltov, 3, var_cw
if38_1:

			; Main.bas 582: ElseIf o = 12 Then                          ' the slot's store: Word(2) K
			dw sel33_e_go
if37_1:
			dw kw_cpeqvl, var_owncall_o, 12
			dw kw_goto_iffalse_n, if37_2

			; Main.bas 583: ca = StoreSize(t, Memory.ReadWord(Far(t, e + 2)))
			dw kw_addl, var_owncall_e, 2, tmp2
			dw p_far_c, var_owncall_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_readword, ltmp1, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp1
			dw p_storesize_c, var_owncall_t, tmp1
			dw kw_vtov, var_storesize_storesize, var_ca

			; Main.bas 584: Else
			dw sel33_e_go
if37_2:

			; Main.bas 585: cw = 1
			dw kw_ltov, 1, var_cw

			; Main.bas 586: End If
if37_e:

			; Main.bas 587: Case 12
			dw sel33_e_go
sel33_8:
			dw kw_cpeqvl, var_owncall___sel33, 12
			dw kw_goto_iffalse_n, sel33_9
sel33_b9:

			; Main.bas 588: ca = &H22 : cw = 2                          ' CP/M 2.2
			dw kw_ltov, 34, var_ca
			dw kw_ltov, 2, var_cw

			; Main.bas 589: Case 40                                       ' write random with zero fill: as 34
			dw sel33_e_go
sel33_9:
			dw kw_cpeqvl, var_owncall___sel33, 40
			dw kw_goto_iffalse_n, sel33_10
sel33_b10:

			; Main.bas 590: ca = Hyp.FileCall(34, e, t, sg(t), dm(t), dv(t), VarPtr(rb)) : cw = 2
			dw kw_aget, arr_sg, var_owncall_t, tmp3
			dw kw_aget, arr_dm, var_owncall_t, tmp4
			dw kw_aget, arr_dv, var_owncall_t, tmp5
			dw p_hyp_filecall_c, lit_34, var_owncall_e, var_owncall_t, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_ca
			dw kw_ltov, 2, var_cw

			; Main.bas 591: Case 130                                      ' RAMDISC.CYB: the RAM discs' driver
			dw sel33_e_go
sel33_10:
			dw kw_cpeqvl, var_owncall___sel33, 130
			dw kw_goto_iffalse_n, sel33_11
sel33_b11:

			; Main.bas 592: ca = RamDisc(t, e) : cw = 2
			dw p_ramdisc_c, var_owncall_t, var_owncall_e
			dw kw_vtov, var_ramdisc_ramdisc, var_ca
			dw kw_ltov, 2, var_cw

			; Main.bas 593: Case Else
			dw sel33_e_go
sel33_11:

			; Main.bas 594: cw = 1
			dw kw_ltov, 1, var_cw

			; Main.bas 595: End Select
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

			; Main.bas 605: Dim g As Integer, o As Integer, f As Long

			; Main.bas 606: o = Memory.ReadByte(Far(t, p))
			dw p_far_c, var_ramdisc_t, var_ramdisc_p
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_ramdisc_o

			; Main.bas 607: If dp = 0 Then
			dw kw_cpeqvl, var_dp, 0
			dw kw_goto_iffalse_n, if39_1

			; Main.bas 608: RamDisc = 255
			dw kw_ltov, 255, var_ramdisc_ramdisc

			; Main.bas 609: If o = 3 Then Exit Function                              ' (the list: none)
			dw kw_cpeqvl, var_ramdisc_o, 3
			dw kw_goto_iffalse_n, if40_1
			dw p_ramdisc_r
if40_1:

			; Main.bas 610: dp = Memory.AllocPage(Memory.TypeUser)
			dw fn_memory_allocpage, lit_85, var_dp

			; Main.bas 611: If dp = 0 Then RamDisc = 2 : Exit Function
			dw kw_cpeqvl, var_dp, 0
			dw kw_goto_iffalse_n, if41_1
			dw kw_ltov, 2, var_ramdisc_ramdisc
			dw p_ramdisc_r
if41_1:

			; Main.bas 612: f = Far(t, Memory.ReadWord(Far(t, p + 2)))                 ' (Far's FarPtr: one result for all calls)
			dw kw_addl, var_ramdisc_p, 2, tmp2
			dw p_far_c, var_ramdisc_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_readword, ltmp1, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp1
			dw p_far_c, var_ramdisc_t, tmp1
			dw kw_l_mov, var_far_far, var_ramdisc_f

			; Main.bas 613: Memory.Copy f, Hyp.FarPtr(dp, 0), Memory.ReadWord(Far(t, p + 4))
			dw fn_hyp_farptr, var_dp, lit_0, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp1
			dw kw_addl, var_ramdisc_p, 4, tmp3
			dw p_far_c, var_ramdisc_t, tmp3
			dw kw_l_mov, var_far_far, ltmp2
			dw fn_memory_readword, ltmp2, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp2
			dw fn_memory_copy, var_ramdisc_f, ltmp1, tmp2, var_memory_copy_copy

			; Main.bas 614: g = Memory.SelectPage(dp)
			dw fn_memory_selectpage, var_dp, var_ramdisc_g

			; Main.bas 615: Hyp.UseDriver VarPtr(rb)
			dw p_hyp_usedriver_c, vp_arr_rb

			; Main.bas 616: g = Hyp.FileCall(110, 0, 0, 0, 0, 0, 0)                    ' (its tables cleared)
			dw p_hyp_filecall_c, lit_110, lit_0, lit_0, lit_0, lit_0, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_ramdisc_g

			; Main.bas 617: End If
if39_1:

			; Main.bas 618: g = 0
			dw kw_ztov, var_ramdisc_g

			; Main.bas 619: If o = 2 Then
			dw kw_cpeqvl, var_ramdisc_o, 2
			dw kw_goto_iffalse_n, if42_1

			; Main.bas 620: g = Memory.AllocPage(Memory.TypeUser)
			dw fn_memory_allocpage, lit_85, var_ramdisc_g

			; Main.bas 621: RamDisc = 2
			dw kw_ltov, 2, var_ramdisc_ramdisc

			; Main.bas 622: If g = 0 Then Exit Function
			dw kw_cpeqvl, var_ramdisc_g, 0
			dw kw_goto_iffalse_n, if43_1
			dw p_ramdisc_r
if43_1:

			; Main.bas 623: RamDisc = Memory.SelectPage(g)
			dw fn_memory_selectpage, var_ramdisc_g, var_ramdisc_ramdisc

			; Main.bas 624: End If
if42_1:

			; Main.bas 625: RamDisc = Hyp.FileCall(116, p, t, sg(t), g, Hyp.Setting(), 0)
			dw kw_aget, arr_sg, var_ramdisc_t, tmp3
			dw fn_hyp_setting, var_hyp_setting_setting
			dw kw_vtov, var_hyp_setting_setting, tmp5
			dw p_hyp_filecall_c, lit_116, var_ramdisc_p, var_ramdisc_t, tmp3, var_ramdisc_g, tmp5, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_ramdisc_ramdisc

			; Main.bas 626: If RamDisc < 0 Then RamDisc = Memory.FreePage(RamDisc And &H7FFF) : RamDisc = 0   ' (a page back: + #8000)
			dw kw_scpltvl, var_ramdisc_ramdisc, 0
			dw kw_goto_iffalse_n, if44_1
			dw kw_andvl, var_ramdisc_ramdisc, 32767, tmp0
			dw fn_memory_freepage, tmp0, var_ramdisc_ramdisc
			dw kw_ztov, var_ramdisc_ramdisc
if44_1:

			; Main.bas 627: If g <> 0 And RamDisc <> 0 Then RamDisc = Memory.FreePage(g) : RamDisc = 2
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

			; Main.bas 635: Dim n As Integer, j As Integer, g As Integer

			; Main.bas 636: n = (kb + 15) \ 16
			dw kw_addl, var_storesize_kb, 15, tmp0
			dw kw_divvl, tmp0, 16, var_storesize_n

			; Main.bas 637: If kb < 0 Or n > 32 Then n = 32
			dw kw_scpltvl, var_storesize_kb, 0
			dw kw_ftov, tmp0
			dw kw_scpgtvl, var_storesize_n, 32
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if46_1
			dw kw_ltov, 32, var_storesize_n
if46_1:

			; Main.bas 638: For j = 0 To 31
			dw kw_ztov, var_storesize_j
for47_t:

			; Main.bas 639: g = Memory.ReadByte(Far(t, STORE + j))
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_storesize_g

			; Main.bas 640: If j < n And g = 0 Then
			dw kw_scpltvv, var_storesize_j, var_storesize_n
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_storesize_g, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if48_1

			; Main.bas 641: g = Memory.AllocPage(Memory.TypeUser)
			dw fn_memory_allocpage, lit_85, var_storesize_g

			; Main.bas 642: If g = 0 Then StoreSize = 2 : Exit Function
			dw kw_cpeqvl, var_storesize_g, 0
			dw kw_goto_iffalse_n, if49_1
			dw kw_ltov, 2, var_storesize_storesize
			dw p_storesize_r
if49_1:

			; Main.bas 643: Memory.WriteByte Far(t, STORE + j), g
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_storesize_g

			; Main.bas 644: ElseIf j >= n And g <> 0 Then
			dw if48_e_go
if48_1:
			dw kw_scpgevv, var_storesize_j, var_storesize_n
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_storesize_g, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if48_2

			; Main.bas 645: g = Memory.FreePage(g)
			dw fn_memory_freepage, var_storesize_g, var_memory_freepage_freepage
			dw kw_vtov, var_memory_freepage_freepage, var_storesize_g

			; Main.bas 646: Memory.WriteByte Far(t, STORE + j), 0
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 647: End If
if48_2:
if48_e:

			; Main.bas 648: Next
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

			; Main.bas 655: Dim p As Integer, su As Integer, j As Integer, a As Integer, pg As Integer, r As Integer

			; Main.bas 656: ProbeDiscs = 0
			dw kw_ztov, var_probediscs_probediscs

			; Main.bas 657: For p = 2 To Memory.Pages()
			dw kw_ltov, 2, var_probediscs_p
			dw fn_memory_pages, for50_l
			dw kw_forupv_n, var_probediscs_p, for50_l, for50_e
for50_t:

			; Main.bas 658: If Memory.PageType(p) = Memory.TypeFree Then
			dw fn_memory_pagetype, var_probediscs_p, var_memory_pagetype_pagetype
			dw kw_vtov, var_memory_pagetype_pagetype, tmp0
			dw kw_cpeqvl, tmp0, 45
			dw kw_goto_iffalse_n, if51_1

			; Main.bas 659: r = Memory.SelectPage(p)
			dw fn_memory_selectpage, var_probediscs_p, var_probediscs_r

			; Main.bas 660: If Peek(&H7F00) = 67 And Peek(&H7F01) = 89 And Peek(&H7F02) = 66 And Peek(&H7F03) = 68 And Peek(&H7F04) = &H5A And Peek(&H7F05) = &HCB Then
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

			; Main.bas 661: su = 0
			dw kw_ztov, var_probediscs_su

			; Main.bas 662: For j = &H5400 To &H59FF
			dw kw_ltov, 21504, var_probediscs_j
for53_t:

			; Main.bas 663: su = (su + Peek(j)) And &HFFFF
			dw kw_vptrtov8, var_probediscs_j, tmp1
			dw kw_add, var_probediscs_su, tmp1, tmp0
			dw kw_vtov, tmp0, var_probediscs_su

			; Main.bas 664: Next
			dw kw_next1l_n, var_probediscs_j, 23039, for53_t
for53_e:

			; Main.bas 665: If su = Peek(&H7F06) + Peek(&H7F07) * 256 Then
			dw kw_lptrtov8, 32518, tmp1
			dw kw_lptrtov8, 32519, tmp2
			dw kw_mulvl, tmp2, 256, tmp2
			dw kw_add, tmp1, tmp2, tmp1
			dw kw_cpeqvv, var_probediscs_su, tmp1
			dw kw_goto_iffalse_n, if54_1

			; Main.bas 666: dp = Hyp.ClaimPage(p)
			dw p_hyp_claimpage_c, var_probediscs_p
			dw kw_vtov, var_hyp_claimpage_claimpage, var_dp

			; Main.bas 667: For j = 0 To 255                       ' the pages D_POOL lists (owner <> 0) back too
			dw kw_ztov, var_probediscs_j
for55_t:

			; Main.bas 668: a = &H5400 + j * 6
			dw kw_mulvl, var_probediscs_j, 6, tmp1
			dw kw_addl, tmp1, 21504, var_probediscs_a

			; Main.bas 669: If Peek(a) <> 0 Then
			dw kw_vptrtov8, var_probediscs_a, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, if56_1

			; Main.bas 670: pg = Peek(a + 2) + Peek(a + 3) * 256
			dw kw_addl, var_probediscs_a, 2, tmp0
			dw kw_vptrtov8, tmp0, tmp0
			dw kw_addl, var_probediscs_a, 3, tmp1
			dw kw_vptrtov8, tmp1, tmp1
			dw kw_mulvl, tmp1, 256, tmp1
			dw kw_add, tmp0, tmp1, var_probediscs_pg

			; Main.bas 671: r = Hyp.ClaimPage(pg)
			dw p_hyp_claimpage_c, var_probediscs_pg
			dw kw_vtov, var_hyp_claimpage_claimpage, var_probediscs_r

			; Main.bas 672: End If
if56_1:

			; Main.bas 673: Next
			dw kw_next1l_n, var_probediscs_j, 255, for55_t
for55_e:

			; Main.bas 674: r = Memory.SelectPage(dp)
			dw fn_memory_selectpage, var_dp, var_probediscs_r

			; Main.bas 675: Hyp.UseDriver VarPtr(rb)
			dw p_hyp_usedriver_c, vp_arr_rb

			; Main.bas 676: ProbeDiscs = -1
			dw kw_ltov, -1, var_probediscs_probediscs

			; Main.bas 677: Exit Function
			dw p_probediscs_r

			; Main.bas 678: End If
if54_1:

			; Main.bas 679: End If
if52_1:

			; Main.bas 680: End If
if51_1:

			; Main.bas 681: Next
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

			; Main.bas 687: NearP = CLng(p)
			dw kw_l_itol, var_nearp_p, var_nearp_nearp

			; Main.bas 688: If p < 0 Then NearP = NearP + 65536
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

			; Main.bas 695: #asm
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

			; Main.bas 725: Dim p As Integer, n As Integer

			; Main.bas 726: p = Hyp.Info(0) : n = Hyp.Info(1)             ' (one Info result each: it is one variable)
			dw fn_hyp_info, lit_0, var_install_p
			dw fn_hyp_info, lit_1, var_install_n

			; Main.bas 727: Memory.Copy Hyp.FarPtr(hp, p), Far(t, 0), n   ' (from the hypervisor's page)
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_0
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy

			; Main.bas 728: p = Hyp.Info(2) : n = Hyp.Info(3)
			dw fn_hyp_info, lit_2, var_install_p
			dw fn_hyp_info, lit_3, var_install_n

			; Main.bas 729: Memory.Copy Hyp.FarPtr(hp, p), Far(t, Hyp.STUB), n
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m4352
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy

			; Main.bas 730: Memory.Copy Hyp.FarPtr(hp, Hyp.HFONT), Far(t, Hyp.FONT), 768   ' the font (Con draws from it)
			dw fn_hyp_farptr, var_hp, lit_4096, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m3328
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, lit_768, var_memory_copy_copy

			; Main.bas 732: p = Hyp.Info(5) : n = Hyp.Info(6)
			dw fn_hyp_info, lit_5, var_install_p
			dw fn_hyp_info, lit_6, var_install_n

			; Main.bas 733: Memory.Copy Hyp.FarPtr(hp, p), Far(t, Hyp.HISW), n   ' the switch both ways (sb_hin, sb_hout), below #FFFE
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m48
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy

			; Main.bas 734: For n = 0 To 2                                  ' its immediates: the bank's segments, the hypervisor's
			dw kw_ztov, var_install_n
for58_t:

			; Main.bas 735: Memory.WriteByte Far(t, Hyp.HISW + 1 + n * 4), Hyp.Seg((sg(t) And &HFFF8) Or (4 + n))
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

			; Main.bas 736: Memory.WriteByte Far(t, Hyp.HISW + 27 + n * 4), Hyp.Seg(n)
			dw kw_4x, var_install_n, tmp2
			dw kw_addl, tmp2, -21, tmp1
			dw p_far_c, var_install_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_hyp_seg, var_install_n, var_hyp_seg_seg
			dw kw_vtov, var_hyp_seg_seg, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 737: Next
			dw kw_next1l_n, var_install_n, 2, for58_t
for58_e:

			; Main.bas 739: Memory.WriteByte Far(t, Hyp.OBUF + 128), 0      ' no characters collected
			dw p_far_c, var_install_t, lit_m2432
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 740: Memory.WriteByte Far(t, Hyp.KEY), 0             ' no key waiting
			dw p_far_c, var_install_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 741: For n = 0 To 31                                 ' no store yet
			dw kw_ztov, var_install_n
for59_t:

			; Main.bas 742: Memory.WriteByte Far(t, STORE + n), 0
			dw kw_addl, var_install_n, -256, tmp1
			dw p_far_c, var_install_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 743: Next
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

			; Main.bas 750: dm(s) = &H80                                   ' CP/M's record buffer to start with
			dw kw_asetl, arr_dm, var_launch_s, 128

			; Main.bas 751: Memory.WriteByte Far(s, &HF685), 0             ' no escape sequence rest half done (its console)
			dw p_far_c, var_launch_s, lit_m2427
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 752: Memory.WriteWord Far(s, &HF2FC), Hyp.Info(4)
			dw p_far_c, var_launch_s, lit_m3332
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_hyp_info, lit_4, var_hyp_info_info
			dw kw_vtov, var_hyp_info_info, tmp1
			dw fn_memory_writeword, ltmp0, tmp1

			; Main.bas 753: Memory.WriteWord Far(s, &HF2FE), 0
			dw p_far_c, var_launch_s, lit_m3330
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, lit_0

			; Main.bas 754: Memory.WriteWord Far(s, &HFFFE), &HF2FC
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

			; Hyp.cls 67: dxb = b
			dw kw_vtov, var_hyp_usedriver_b, var_hyp_dxb

			; Hyp.cls 68: #asm
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

			; Hyp.cls 78: #asm
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

			; Hyp.cls 304: #asm
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

			; Hyp.cls 1652: #asm
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

			; Hyp.cls 1777: #asm
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

			; Hyp.cls 1940: #asm
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

			; Hyp.cls 1990: ra = a : rhl = hl
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

			; Hyp.cls 1994: Fn = rfn And 255
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

			; Hyp.cls 1998: Arg = rde
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

			; Hyp.cls 2003: Count = rcnt
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

			; Hyp.cls 2008: #asm
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

			; Hyp.cls 2125: #asm
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

			; Hyp.cls 3760: #asm
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

			; Hyp.cls 3817: #asm
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

			; Hyp.cls 5850: #asm
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

			; Hyp.cls 5928: svst = vst : svsg = vsg : svns = vns : svfr = vfr : svdp = vdp
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

			; Hyp.cls 5933: svbd = d : svdv = vdv                         ' (and the slots' drives, dv(): 20/7)
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

			; Hyp.cls 5940: #asm
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

			; Hyp.cls 9123: #asm
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

			; Hot.cls 19: If f < 1 Then f = 1
			dw kw_scpltvl, var_hot_speed_f, 1
			dw kw_goto_iffalse_n, if60_1
			dw kw_ltov, 1, var_hot_speed_f
if60_1:

			; Hot.cls 20: If f > 40 Then f = 40
			dw kw_scpgtvl, var_hot_speed_f, 40
			dw kw_goto_iffalse_n, if61_1
			dw kw_ltov, 40, var_hot_speed_f
if61_1:

			; Hot.cls 21: dbl = DOUBLE * f
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

			; Hot.cls 25: ns = n
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

			; Hot.cls 29: Dim k As Integer

			; Hot.cls 31: Dim i As Integer, j As Integer

			; Hot.cls 36: ctl = ((Row(6) And 2) = 0)
			dw fn_hot_row, lit_6, var_hot_row_row
			dw kw_vtov, var_hot_row_row, tmp6
			dw kw_andvl, tmp6, 2, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_ftov, var_hot_ctl

			; Hot.cls 37: If ctl Then
			dw kw_goto_ifzero_n, var_hot_ctl, if62_1

			; Hot.cls 38: i = Row(0)
			dw fn_hot_row, lit_0, var_hot_tick_i

			; Hot.cls 39: j = 2
			dw kw_ltov, 2, var_hot_tick_j

			; Hot.cls 40: For k = 1 To 7
			dw kw_ltov, 1, var_hot_tick_k
for63_t:

			; Hot.cls 41: If (i And j) = 0 Then Exit For
			dw kw_andvv, var_hot_tick_i, var_hot_tick_j, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if64_1
			dw for63_e_go
if64_1:

			; Hot.cls 42: j = j * 2
			dw kw_2x, var_hot_tick_j, var_hot_tick_j

			; Hot.cls 43: Next
			dw kw_next1l_n, var_hot_tick_k, 7, for63_t
for63_e:

			; Hot.cls 44: If k > 7 Then k = 0
			dw kw_scpgtvl, var_hot_tick_k, 7
			dw kw_goto_iffalse_n, if65_1
			dw kw_ztov, var_hot_tick_k
if65_1:

			; Hot.cls 45: If (i And 1) = 0 Then k = 10
			dw kw_andvl, var_hot_tick_i, 1, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if66_1
			dw kw_ltov, 10, var_hot_tick_k
if66_1:

			; Hot.cls 46: i = Row(1)
			dw fn_hot_row, lit_1, var_hot_tick_i

			; Hot.cls 47: If (i And 1) = 0 Then k = 8
			dw kw_andvl, var_hot_tick_i, 1, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if67_1
			dw kw_ltov, 8, var_hot_tick_k
if67_1:

			; Hot.cls 48: If (i And 2) = 0 Then k = 9
			dw kw_andvl, var_hot_tick_i, 2, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if68_1
			dw kw_ltov, 9, var_hot_tick_k
if68_1:

			; Hot.cls 49: If (Row(7) And 4) = 0 Then k = TOPKEY
			dw fn_hot_row, lit_7, var_hot_row_row
			dw kw_vtov, var_hot_row_row, tmp6
			dw kw_andvl, tmp6, 4, tmp6
			dw kw_cpeqvl, tmp6, 0
			dw kw_goto_iffalse_n, if69_1
			dw kw_ltov, 99, var_hot_tick_k
if69_1:

			; Hot.cls 50: End If
if62_1:

			; Hot.cls 67: If k <> 0 And k <> last Then
			dw kw_cpnevl, var_hot_tick_k, 0
			dw kw_ftov, tmp6
			dw kw_cpnevv, var_hot_tick_k, var_hot_last
			dw kw_ftov, tmp7
			dw kw_andvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if70_1

			; Hot.cls 68: If k = TOPKEY Or ns <= 10 Then
			dw kw_cpeqvl, var_hot_tick_k, 99
			dw kw_ftov, tmp6
			dw kw_scplevl, var_hot_ns, 10
			dw kw_ftov, tmp7
			dw kw_orvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if71_1

			; Hot.cls 69: If one <> 0 Then one = 0
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if72_1
			dw kw_ztov, var_hot_one
if72_1:

			; Hot.cls 70: pend = k                          ' at once (no double taps to wait for)
			dw kw_vtov, var_hot_tick_k, var_hot_pend

			; Hot.cls 71: ElseIf one = k Then
			dw if71_e_go
if71_1:
			dw kw_cpeqvv, var_hot_one, var_hot_tick_k
			dw kw_goto_iffalse_n, if71_2

			; Hot.cls 72: one = 0
			dw kw_ztov, var_hot_one

			; Hot.cls 73: If k + 10 <= ns Then pend = k + 10 Else pend = k  ' the second press: slot 11-20
			dw kw_addl, var_hot_tick_k, 10, tmp6
			dw kw_scplevv, tmp6, var_hot_ns
			dw kw_goto_iffalse_n, if73_1
			dw kw_addl, var_hot_tick_k, 10, var_hot_pend
			dw if71_e_go
if73_1:
			dw kw_vtov, var_hot_tick_k, var_hot_pend
if73_e:

			; Hot.cls 74: Else
			dw if71_e_go
if71_2:

			; Hot.cls 75: If one <> 0 Then pend = one       ' another number: the waiting one counts now
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if74_1
			dw kw_vtov, var_hot_one, var_hot_pend
if74_1:

			; Hot.cls 76: one = k : age = 0
			dw kw_vtov, var_hot_tick_k, var_hot_one
			dw kw_ztov, var_hot_age

			; Hot.cls 77: End If
if71_e:

			; Hot.cls 78: End If
if70_1:

			; Hot.cls 79: If one <> 0 Then
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if75_1

			; Hot.cls 80: age = age + 1
			dw kw_inc, var_hot_age

			; Hot.cls 81: If dbl = 0 Then dbl = DOUBLE
			dw kw_cpeqvl, var_hot_dbl, 0
			dw kw_goto_iffalse_n, if76_1
			dw kw_ltov, 15, var_hot_dbl
if76_1:

			; Hot.cls 82: If age > dbl Or ctl = 0 Then pend = one : one = 0       ' no second press (or Control let go)
			dw kw_scpgtvv, var_hot_age, var_hot_dbl
			dw kw_ftov, tmp6
			dw kw_cpeqvl, var_hot_ctl, 0
			dw kw_ftov, tmp7
			dw kw_orvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if77_1
			dw kw_vtov, var_hot_one, var_hot_pend
			dw kw_ztov, var_hot_one
if77_1:

			; Hot.cls 83: End If
if75_1:

			; Hot.cls 84: last = k
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

			; Hot.cls 108: Take = pend
			dw kw_vtov, var_hot_pend, var_hot_take_take

			; Hot.cls 109: pend = 0
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

			; Hot.cls 114: Control = ctl
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

			; Hot.cls 120: Held = last
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

			; Memory.cls 450: BankPage = 4 * bank - 2 + n
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
    IFDEF NTC_MSXDOS		; Main.bas 72
            ; MSX: the screen TEXT 2 (80 columns) on the V9938 straight (not the BIOS's: its
            ; name table a ring of 32 rows for the vertical scroll, Hyp's msx_vrow), the font from
            ; the main ROM's (CGTABL, through RDSLT: the DOS's page 0) into its pattern table
            ld (ntc_ip), sp		; Main.bas 76
            ld sp, (ntc_csp)		; Main.bas 77
            di		; Main.bas 78
            ld hl, asm_0_71_n_vdp_regs		; Main.bas 79
asm_0_71_n_vdp_rl:     ld a, (hl)		; Main.bas 80
            inc hl		; Main.bas 81
            cp #FF		; Main.bas 82
            jr z, asm_0_71_n_vdp_rd		; Main.bas 83
            out (#99), a		; Main.bas 84
            ld a, (hl)		; Main.bas 85
            inc hl		; Main.bas 86
            out (#99), a		; Main.bas 87
            jr asm_0_71_n_vdp_rl		; Main.bas 88
asm_0_71_n_vdp_rd:     ld a, (#FFE8)          ; R#9: 212 lines (26.5 rows), the PAL / NTSC bit as the BIOS had it [89]
            and #02		; Main.bas 90
            or #80		; Main.bas 91
            out (#99), a		; Main.bas 92
            ld a, #80 + 9		; Main.bas 93
            out (#99), a		; Main.bas 94
            ld hl, #0A00           ; the blink table: none [95]
            call msx_vwa		; Main.bas 96
            ld b, 0		; Main.bas 97
            xor a		; Main.bas 98
asm_0_71_n_vdp_bl:     out (#98), a		; Main.bas 99
            djnz asm_0_71_n_vdp_bl		; Main.bas 100
            call msx_vclr		; Main.bas 101
            ld a, (#FCC1)          ; EXPTBL: the main ROM's slot [102]
            ld hl, 4               ; CGTABL: where its font is [103]
            push af		; Main.bas 104
            call #000C             ; RDSLT [105]
            ld e, a		; Main.bas 106
            pop af		; Main.bas 107
            push af		; Main.bas 108
            inc hl		; Main.bas 109
            call #000C		; Main.bas 110
            ld d, a		; Main.bas 111
            pop af		; Main.bas 112
            ex de, hl              ; HL = the font [113]
            push af		; Main.bas 114
            push hl		; Main.bas 115
            ld hl, #1000           ; the pattern table [116]
            call msx_vwa		; Main.bas 117
            pop hl		; Main.bas 118
            pop af		; Main.bas 119
            ld bc, #0008           ; 2048 bytes: B 0 (256), C 8 [120]
asm_0_71_n_vdp_fl:     push af		; Main.bas 121
            push bc		; Main.bas 122
            call #000C             ; (interrupts off after it) [123]
            out (#98), a		; Main.bas 124
            pop bc		; Main.bas 125
            pop af		; Main.bas 126
            inc hl		; Main.bas 127
            djnz asm_0_71_n_vdp_fl		; Main.bas 128
            dec c		; Main.bas 129
            jr nz, asm_0_71_n_vdp_fl		; Main.bas 130
            di		; Main.bas 131
            ld sp, (ntc_ip)		; Main.bas 132
            jr asm_0_71_n_vdp_end		; Main.bas 133
; R#0 TEXT 2, R#1 on + the frame interrupt + text, R#2 the name table #0000, R#3 / R#10 the blink
; table #0A00, R#4 the patterns #1000, R#7 light yellow on dark blue (the CPC's colours), R#8 as
; the BIOS's, R#12 / R#13 no blink, R#14 0, R#23 0 (the scroll)
asm_0_71_n_vdp_regs:   db #04, #80, #70, #81, #03, #82, #2F, #83, #00, #8A, #02, #84, #B4, #87, #08, #88		; Main.bas 137
            db #00, #8C, #00, #8D, #00, #8E, #00, #97, #FF		; Main.bas 138
asm_0_71_n_vdp_end:		; Main.bas 139
    ENDIF		; Main.bas 140
			ret			; end of #asm

fn_kin:		; sub kin (asm keyword), Main.bas line 421
            ld (var_ksp), sp          ; (the real stack: the Next's window is a call) [422]
            ld sp, (ntc_csp)		; Main.bas 423
            ld bc, (var_kwp)          ; the kernel's page 3 in the window: its #EE00 at #6E00 [424]
    IFDEF NTC_MSXDOS		; Main.bas 425
            call msx_win		; Main.bas 426
    ELSE		; Main.bas 427
            out (c), c		; Main.bas 428
    ENDIF		; Main.bas 429
            ld hl, 60928 - #8000		; Main.bas 430
            ld de, arr_kw		; Main.bas 431
            ld bc, 32		; Main.bas 432
            ldir		; Main.bas 433
            ld bc, (ntc_rampt)      ; the page that was in the window back [434]
    IFDEF NTC_MSXDOS		; Main.bas 435
            call msx_win		; Main.bas 436
    ELSE		; Main.bas 437
            out (c), c		; Main.bas 438
    ENDIF		; Main.bas 439
            ld sp, (var_ksp)		; Main.bas 440
			ret			; end of #asm

fn_kout:		; sub kout (asm keyword), Main.bas line 446
            ld (var_ksp), sp		; Main.bas 447
            ld sp, (ntc_csp)		; Main.bas 448
            ld bc, (var_kwp)		; Main.bas 449
    IFDEF NTC_MSXDOS		; Main.bas 450
            call msx_win		; Main.bas 451
    ELSE		; Main.bas 452
            out (c), c		; Main.bas 453
    ENDIF		; Main.bas 454
            ld hl, arr_kw + 16		; Main.bas 455
            ld de, 60928 - #8000 + 16		; Main.bas 456
            ld bc, 16		; Main.bas 457
            ldir		; Main.bas 458
            ld bc, (ntc_rampt)		; Main.bas 459
    IFDEF NTC_MSXDOS		; Main.bas 460
            call msx_win		; Main.bas 461
    ELSE		; Main.bas 462
            out (c), c		; Main.bas 463
    ENDIF		; Main.bas 464
            ld sp, (var_ksp)		; Main.bas 465
			ret			; end of #asm

asm_0_471_n:		; #asm, Main.bas line 471 (normal)
            ld (var_ksp), sp		; Main.bas 472
            ld sp, (ntc_csp)		; Main.bas 473
            ld bc, (var_kwp)		; Main.bas 474
    IFDEF NTC_MSXDOS		; Main.bas 475
            call msx_win		; Main.bas 476
    ELSE		; Main.bas 477
            out (c), c		; Main.bas 478
    ENDIF		; Main.bas 479
            ld hl, 60928 - #8000 + 32		; Main.bas 480
            ld de, (var_kdin_p)		; Main.bas 481
            ld bc, (var_kdin_n)		; Main.bas 482
            ld a, b		; Main.bas 483
            or c		; Main.bas 484
            jr z, asm_0_471_n_kdi_none		; Main.bas 485
            ldir		; Main.bas 486
asm_0_471_n_kdi_none:		; Main.bas 487
            xor a		; Main.bas 488
            ld (de), a		; Main.bas 489
            ld bc, (ntc_rampt)		; Main.bas 490
    IFDEF NTC_MSXDOS		; Main.bas 491
            call msx_win		; Main.bas 492
    ELSE		; Main.bas 493
            out (c), c		; Main.bas 494
    ENDIF		; Main.bas 495
            ld sp, (var_ksp)		; Main.bas 496
			ret			; end of #asm

asm_0_502_n:		; #asm, Main.bas line 502 (normal)
            ld (var_ksp), sp		; Main.bas 503
            ld sp, (ntc_csp)		; Main.bas 504
            ld bc, (var_kwp)		; Main.bas 505
    IFDEF NTC_MSXDOS		; Main.bas 506
            call msx_win		; Main.bas 507
    ELSE		; Main.bas 508
            out (c), c		; Main.bas 509
    ENDIF		; Main.bas 510
            ld hl, (var_kdout_p)		; Main.bas 511
            ld de, 60928 - #8000 + 32		; Main.bas 512
            ld bc, (var_kdout_n)		; Main.bas 513
            ld a, b		; Main.bas 514
            or c		; Main.bas 515
            jr z, asm_0_502_n_kdo_none		; Main.bas 516
            ldir		; Main.bas 517
asm_0_502_n_kdo_none:		; Main.bas 518
            ld bc, (ntc_rampt)		; Main.bas 519
    IFDEF NTC_MSXDOS		; Main.bas 520
            call msx_win		; Main.bas 521
    ELSE		; Main.bas 522
            out (c), c		; Main.bas 523
    ENDIF		; Main.bas 524
            ld sp, (var_ksp)		; Main.bas 525
			ret			; end of #asm

asm_0_695_n:		; #asm, Main.bas line 695 (normal)
            ld a, (var_far_t)		; Main.bas 696
            add a, a		; Main.bas 697
            add a, a                ; t * 4 [698]
            ld e, a		; Main.bas 699
            ld a, (var_far_a + 1)		; Main.bas 700
            rlca		; Main.bas 701
            rlca		; Main.bas 702
            and 3                   ; + the address's 16K page [703]
            add a, e		; Main.bas 704
            ld e, a		; Main.bas 705
            ld d, 0		; Main.bas 706
            ld hl, arr_bpg		; Main.bas 707
            add hl, de		; Main.bas 708
            add hl, de		; Main.bas 709
            ld c, (hl)		; Main.bas 710
            inc hl		; Main.bas 711
            ld b, (hl)              ; BC = the page [712]
            ld hl, (var_far_a)		; Main.bas 713
            ld a, h		; Main.bas 714
            and #3F		; Main.bas 715
            or #40		; Main.bas 716
            ld h, a                 ; HL = #4000 + the low 14 bits [717]
            ld (var_far_far), hl		; Main.bas 718
            ld (var_far_far + 2), bc		; Main.bas 719
			ret			; end of #asm

fn_hyp_usepage:		; sub usepage (asm keyword), Hyp.cls line 58
            ld hl, (ntc_rampt)		; Hyp.cls 59
            ld (var_hyp_hps), hl		; Hyp.cls 60
			ret			; end of #asm

asm_1_68_n:		; #asm, Hyp.cls line 68 (normal)
            ld hl, (ntc_rampt)		; Hyp.cls 69
            ld (var_hyp_drs), hl		; Hyp.cls 70
			ret			; end of #asm

asm_1_78_n:		; #asm, Hyp.cls line 78 (normal)
            ld hl, (var_hyp_claimpage_page)		; Hyp.cls 79
            ld a, h		; Hyp.cls 80
            or l		; Hyp.cls 81
            jr z, asm_1_78_n_cp_no		; Hyp.cls 82
            ld de, (mem_count)		; Hyp.cls 83
            ex de, hl		; Hyp.cls 84
            or a		; Hyp.cls 85
            sbc hl, de              ; page - count: carry means page > count [86]
            jr c, asm_1_78_n_cp_no		; Hyp.cls 87
            ld hl, (var_hyp_claimpage_page)         ; the RAT byte: (mem_ttype) + page - 1 [88]
            ld de, (mem_ttype)		; Hyp.cls 89
            add hl, de		; Hyp.cls 90
            dec hl		; Hyp.cls 91
            ld a, (hl)		; Hyp.cls 92
            cp "-"                  ; free? [93]
            jr nz, asm_1_78_n_cp_no		; Hyp.cls 94
            ld (hl), "U"            ; TypeUser [95]
            ld hl, (var_hyp_claimpage_page)		; Hyp.cls 96
            jr asm_1_78_n_cp_done		; Hyp.cls 97
asm_1_78_n_cp_no:		; Hyp.cls 98
            ld hl, 0		; Hyp.cls 99
asm_1_78_n_cp_done:		; Hyp.cls 100
            ld (var_hyp_claimpage_claimpage), hl		; Hyp.cls 101
			ret			; end of #asm

fn_hyp_setting:		; function setting (asm keyword), Hyp.cls line 106
            ld de, (ntc_rampt)      ; (zxn: the Next's setting is shaped as the CPC's - B = ZXN_SETB, C = the [107]
            ld a, e                 ; 64K bank's ordinal * 8 + 4 + page - so this arithmetic holds there too) [108]
            and #F8		; Hyp.cls 109
            or 2		; Hyp.cls 110
            ld e, a		; Hyp.cls 111
            pop hl		; Hyp.cls 112
            ld (hl), e		; Hyp.cls 113
            inc hl		; Hyp.cls 114
            ld (hl), d		; Hyp.cls 115
			ret			; end of #asm

fn_hyp_farptr:		; function farptr (asm keyword), Hyp.cls line 122
            pop hl		; Hyp.cls 123
            ld c, (hl)		; Hyp.cls 124
            inc hl		; Hyp.cls 125
            ld b, (hl)              ; BC = page [126]
            pop hl		; Hyp.cls 127
            ld e, (hl)		; Hyp.cls 128
            inc hl		; Hyp.cls 129
            ld a, (hl)		; Hyp.cls 130
            and #3F		; Hyp.cls 131
            or #40		; Hyp.cls 132
            ld d, a                 ; DE = #4000 + the address's low 14 bits [133]
            pop hl		; Hyp.cls 134
            ld (hl), e		; Hyp.cls 135
            inc hl		; Hyp.cls 136
            ld (hl), d		; Hyp.cls 137
            inc hl		; Hyp.cls 138
            ld (hl), c		; Hyp.cls 139
            inc hl		; Hyp.cls 140
            ld (hl), b		; Hyp.cls 141
			ret			; end of #asm

fn_hyp_fontinit:		; sub fontinit (asm keyword), Hyp.cls line 175
    IFDEF NTC_MSXDOS		; Hyp.cls 176
            ret                     ; ZX Next: the tilemap renders char codes via its own tiles; [177]
                                    ; no CPC font needed, and #F300 would clobber the tiles
    ELSE		; Hyp.cls 179
            ld (var_hyp_hsp), sp		; Hyp.cls 180
            ld sp, (ntc_csp)		; Hyp.cls 181
            ld bc, (var_hyp_hps)		; Hyp.cls 182
            out (c), c		; Hyp.cls 183
            ld de, 32               ; D = 0: a table, E = its first character [184]
            ld hl, #4000 + 4096		; Hyp.cls 185
            call #BBAB              ; TXT SET M TABLE (the matrices from 32 on, copied there) [186]
            di		; Hyp.cls 187
            ld de, #FF00            ; D <> 0: no table of its own any more [188]
            call #BBAB		; Hyp.cls 189
            di		; Hyp.cls 190
            ld bc, (ntc_rampt)		; Hyp.cls 191
            out (c), c		; Hyp.cls 192
            ld sp, (var_hyp_hsp)		; Hyp.cls 193
    ENDIF		; Hyp.cls 194
			ret			; end of #asm

asm_1_304_n:		; #asm, Hyp.cls line 304 (normal)
; CN_SB 1: the scrollback (Shift + Up / Down: 48 rows a slot, kept in a 16K page Main gives - #If
; SCROLLBACK in Main.bas, set the two together). Off for now: 526 bytes of main RAM (2026-10-16)
asm_1_304_n_CN_SB:      equ 0		; Hyp.cls 307
            ld (var_hyp_hsp), sp		; Hyp.cls 308
            ld sp, (ntc_csp)		; Hyp.cls 309
            ld bc, (var_hyp_con_pg)		; Hyp.cls 310
    IFNDEF NTC_MSXDOS		; Hyp.cls 311
            out (c), c              ; the slot's page 3 at #4000: OBUF #7600, state #7682, page #7700 [312]
    ELSE		; Hyp.cls 313
            call msx_win            ; zxn: the slot's page 3 (its setting or 7, as the CPC's) into the window via the MMU [314]
    ENDIF		; Hyp.cls 315
            IF asm_1_304_n_CN_SB		; Hyp.cls 316
            ld (asm_1_304_n_cn_pg), bc		; Hyp.cls 317
            ENDIF		; Hyp.cls 318
            xor a		; Hyp.cls 319
            ld (asm_1_304_n_cn_pv), a		; Hyp.cls 320
            ld a, (var_hyp_con_front)		; Hyp.cls 321
            ld (asm_1_304_n_cn_front), a		; Hyp.cls 322
            ld a, (#7687)           ; its columns and rows (MODE) [323]
            ld (asm_1_304_n_cn_c), a		; Hyp.cls 324
            ld a, (#7688)		; Hyp.cls 325
            ld (asm_1_304_n_cn_r), a		; Hyp.cls 326
            ld a, (var_hyp_ccu)           ; the cursor off first, whatever comes (it was on: cn_was) [327]
            ld (asm_1_304_n_cn_was), a		; Hyp.cls 328
            or a		; Hyp.cls 329
            call nz, asm_1_304_n_cn_cuxor		; Hyp.cls 330
            ld hl, (var_hyp_con_n)		; Hyp.cls 331
            bit 7, h		; Hyp.cls 332
            jp nz, asm_1_304_n_cn_neg		; Hyp.cls 333
            ld (asm_1_304_n_cn_left), hl		; Hyp.cls 334
            IF asm_1_304_n_CN_SB		; Hyp.cls 335
            ld a, (asm_1_304_n_cn_front)        ; in front and looking back (scrollback): the page again first [336]
            or a		; Hyp.cls 337
            jr z, asm_1_304_n_cn_live		; Hyp.cls 338
            ld a, (#7F26)		; Hyp.cls 339
            or a		; Hyp.cls 340
            jr z, asm_1_304_n_cn_live		; Hyp.cls 341
            xor a		; Hyp.cls 342
            ld (#7F26), a		; Hyp.cls 343
            call asm_1_304_n_cn_cls		; Hyp.cls 344
            call asm_1_304_n_cn_strip		; Hyp.cls 345
            call asm_1_304_n_cn_draw		; Hyp.cls 346
            ld hl, (asm_1_304_n_cn_left)		; Hyp.cls 347
asm_1_304_n_cn_live:		; Hyp.cls 348
            ENDIF		; Hyp.cls 349
            ld hl, (var_hyp_con_src)		; Hyp.cls 350
            ld a, h		; Hyp.cls 351
            or l		; Hyp.cls 352
            jr nz, asm_1_304_n_cn_src		; Hyp.cls 353
            ld hl, #7600            ; src 0: the characters the program collected (OBUF) [354]
asm_1_304_n_cn_src:		; Hyp.cls 355
            ld (asm_1_304_n_cn_ptr), hl		; Hyp.cls 356
asm_1_304_n_cn_lp:		; Hyp.cls 357
            ld hl, (asm_1_304_n_cn_left)		; Hyp.cls 358
            ld a, h		; Hyp.cls 359
            or l		; Hyp.cls 360
            jr z, asm_1_304_n_cn_done		; Hyp.cls 361
            dec hl		; Hyp.cls 362
            ld (asm_1_304_n_cn_left), hl		; Hyp.cls 363
            ld hl, (asm_1_304_n_cn_ptr)		; Hyp.cls 364
            ld a, (hl)		; Hyp.cls 365
            inc hl		; Hyp.cls 366
            ld (asm_1_304_n_cn_ptr), hl		; Hyp.cls 367
            call asm_1_304_n_cn_char		; Hyp.cls 368
            jr asm_1_304_n_cn_lp		; Hyp.cls 369
asm_1_304_n_cn_done:		; Hyp.cls 370
            ld bc, (ntc_rampt)      ; the window's page back [371]
    IFDEF NTC_MSXDOS		; Hyp.cls 372
            call msx_win		; Hyp.cls 373
    ELSE		; Hyp.cls 374
            out (c), c		; Hyp.cls 375
    ENDIF		; Hyp.cls 376
            ld sp, (var_hyp_hsp)		; Hyp.cls 377
            jp asm_1_304_n_cn_end		; Hyp.cls 378

; n < 0: -1 the whole page to the screen (it was cleared: Show), not looking back any more; -2
; the scrollback (src: the key - #F4 Shift + Up a screen back, #F5 Shift + Down one on), drawn
asm_1_304_n_cn_neg:		; Hyp.cls 382
            ld a, l		; Hyp.cls 383
            cp #FD                  ; -3: the cursor flashes - on (it was off), an underline XORed [384]
            jr nz, asm_1_304_n_cn_neg1          ; where the next character goes; off (it was on: done above) [385]
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 386
            or a		; Hyp.cls 387
            jr z, asm_1_304_n_cn_done		; Hyp.cls 388
            ld a, (var_hyp_nta)           ; the network blink: advance it (0.5s) while there's traffic [389]
            or a		; Hyp.cls 390
            jr z, asm_1_304_n_cn_nt1		; Hyp.cls 391
            dec a		; Hyp.cls 392
            ld (var_hyp_nta), a		; Hyp.cls 393
            ld a, (var_hyp_ntb)		; Hyp.cls 394
            xor 1		; Hyp.cls 395
            ld (var_hyp_ntb), a		; Hyp.cls 396
asm_1_304_n_cn_nt1:		; Hyp.cls 397
            call asm_1_304_n_cn_net		; Hyp.cls 398
            ld a, (asm_1_304_n_cn_was)		; Hyp.cls 399
            or a		; Hyp.cls 400
            jr nz, asm_1_304_n_cn_done		; Hyp.cls 401
            ld a, (#7682)		; Hyp.cls 402
            ld d, a		; Hyp.cls 403
            ld a, (#7683)		; Hyp.cls 404
            ld e, a		; Hyp.cls 405
            call asm_1_304_n_cn_scr		; Hyp.cls 406
    IFNDEF NTC_MSXDOS		; Hyp.cls 407
            ld a, h		; Hyp.cls 408
            add a, #38              ; (its cell's last pixel line) [409]
            ld h, a		; Hyp.cls 410
    ENDIF		; Hyp.cls 411
            ld (asm_1_304_n_cn_ca), hl          ; zxn: cn_ca = the logical cell address as is [412]
            call asm_1_304_n_cn_cuxor		; Hyp.cls 413
            jr asm_1_304_n_cn_done		; Hyp.cls 414
asm_1_304_n_cn_neg1:		; Hyp.cls 415
            IF asm_1_304_n_CN_SB		; Hyp.cls 416
            inc hl		; Hyp.cls 417
            ld a, h		; Hyp.cls 418
            or l		; Hyp.cls 419
            jr nz, asm_1_304_n_cn_view		; Hyp.cls 420
            ld (#7F26), a		; Hyp.cls 421
            ENDIF		; Hyp.cls 422
asm_1_304_n_cn_show:		; Hyp.cls 423
            call asm_1_304_n_cn_strip		; Hyp.cls 424
            call asm_1_304_n_cn_draw		; Hyp.cls 425
            jr asm_1_304_n_cn_done		; Hyp.cls 426
            IF asm_1_304_n_CN_SB		; Hyp.cls 427
asm_1_304_n_cn_view:		; Hyp.cls 428
            ld a, (#7F21)           ; (no history page: nothing) [429]
            or a		; Hyp.cls 430
            jr z, asm_1_304_n_cn_done		; Hyp.cls 431
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 432
            dec a		; Hyp.cls 433
            ld b, a                 ; a screen: its rows - 1 [434]
            ld a, (var_hyp_con_src)		; Hyp.cls 435
            cp #F4		; Hyp.cls 436
            ld a, (#7F26)		; Hyp.cls 437
            jr nz, asm_1_304_n_cn_vw_dn		; Hyp.cls 438
            add a, b		; Hyp.cls 439
            ld hl, #7F25		; Hyp.cls 440
            cp (hl)		; Hyp.cls 441
            jr c, asm_1_304_n_cn_vw_set		; Hyp.cls 442
            ld a, (hl)              ; (not past the oldest row kept) [443]
            jr asm_1_304_n_cn_vw_set		; Hyp.cls 444
asm_1_304_n_cn_vw_dn:		; Hyp.cls 445
            sub b		; Hyp.cls 446
            jr nc, asm_1_304_n_cn_vw_set		; Hyp.cls 447
            xor a		; Hyp.cls 448
asm_1_304_n_cn_vw_set:		; Hyp.cls 449
            ld hl, #7F26		; Hyp.cls 450
            cp (hl)		; Hyp.cls 451
            jr z, asm_1_304_n_cn_done		; Hyp.cls 452
            ld (hl), a		; Hyp.cls 453
            call asm_1_304_n_cn_cls		; Hyp.cls 454
            jr asm_1_304_n_cn_show		; Hyp.cls 455

            ENDIF		; Hyp.cls 457

; the screen's rows: the page's - or, looking back (#FF26 rows), the history's first, then the
; page's. Row e shows line count + e - back of history + page (count the rows kept, #FF25)
asm_1_304_n_cn_draw:		; Hyp.cls 461
            ld e, 0		; Hyp.cls 462
            IF asm_1_304_n_CN_SB		; Hyp.cls 463
asm_1_304_n_cn_dr_row:		; Hyp.cls 464
            push de		; Hyp.cls 465
            ld a, (#7F25)		; Hyp.cls 466
            add a, e		; Hyp.cls 467
            ld hl, #7F26		; Hyp.cls 468
            sub (hl)                ; the line: count + e - back [469]
            ld hl, #7F25		; Hyp.cls 470
            sub (hl)		; Hyp.cls 471
            jr c, asm_1_304_n_cn_dr_h		; Hyp.cls 472
            call asm_1_304_n_cn_rowa            ; HL = row (line - count) of the page [473]
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 474
            jr asm_1_304_n_cn_dr_go		; Hyp.cls 475
asm_1_304_n_cn_dr_h:		; Hyp.cls 476
            add a, (hl)		; Hyp.cls 477
            call asm_1_304_n_cn_hget            ; HL = the history's row (copied in), 80 characters at most [478]
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 479
            cp asm_1_304_n_HW		; Hyp.cls 480
            jr c, asm_1_304_n_cn_dr_go		; Hyp.cls 481
            ld a, asm_1_304_n_HW		; Hyp.cls 482
asm_1_304_n_cn_dr_go:		; Hyp.cls 483
            ld b, a		; Hyp.cls 484
            pop de		; Hyp.cls 485
            push de		; Hyp.cls 486
            ld d, 0		; Hyp.cls 487
asm_1_304_n_cn_dr_col:		; Hyp.cls 488
            ld a, (hl)		; Hyp.cls 489
            inc hl		; Hyp.cls 490
            cp 33		; Hyp.cls 491
            jr c, asm_1_304_n_cn_dr_sk		; Hyp.cls 492
            push hl		; Hyp.cls 493
            push de		; Hyp.cls 494
            push bc		; Hyp.cls 495
            call asm_1_304_n_cn_glyph		; Hyp.cls 496
            pop bc		; Hyp.cls 497
            pop de		; Hyp.cls 498
            pop hl		; Hyp.cls 499
asm_1_304_n_cn_dr_sk:		; Hyp.cls 500
            inc d		; Hyp.cls 501
            djnz asm_1_304_n_cn_dr_col		; Hyp.cls 502
            pop de		; Hyp.cls 503
            inc e		; Hyp.cls 504
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 505
            dec a		; Hyp.cls 506
            cp e		; Hyp.cls 507
            jr nc, asm_1_304_n_cn_dr_row		; Hyp.cls 508
            ret		; Hyp.cls 509
            ELSE		; Hyp.cls 510
asm_1_304_n_cn_sh_row:                          ; (no scrollback: the page's rows as they are) [511]
            push de		; Hyp.cls 512
            ld a, e		; Hyp.cls 513
            call asm_1_304_n_cn_rowa            ; HL = row e of the page [514]
            pop de		; Hyp.cls 515
            ld d, 0		; Hyp.cls 516
asm_1_304_n_cn_sh_col:		; Hyp.cls 517
            ld a, (hl)		; Hyp.cls 518
            inc hl		; Hyp.cls 519
            cp 33		; Hyp.cls 520
            jr c, asm_1_304_n_cn_sh_skip		; Hyp.cls 521
            push hl		; Hyp.cls 522
            push de		; Hyp.cls 523
            call asm_1_304_n_cn_glyph		; Hyp.cls 524
            pop de		; Hyp.cls 525
            pop hl		; Hyp.cls 526
asm_1_304_n_cn_sh_skip:		; Hyp.cls 527
            inc d		; Hyp.cls 528
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 529
            dec a		; Hyp.cls 530
            cp d		; Hyp.cls 531
            jr nc, asm_1_304_n_cn_sh_col		; Hyp.cls 532
            inc e		; Hyp.cls 533
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 534
            dec a		; Hyp.cls 535
            cp e		; Hyp.cls 536
            jr nc, asm_1_304_n_cn_sh_row		; Hyp.cls 537
            ret		; Hyp.cls 538
            ENDIF		; Hyp.cls 539

            IF asm_1_304_n_CN_SB		; Hyp.cls 541
; the scrollback: each row that scrolls off the top of the page - its first HW characters - goes
; to the slot's history: HROWS rows (a ring) in a 16K page of its own that Main gave it (#FF20:
; its RAM setting, 0 none; #FF22 where in it; #FF24 the next row written, #FF25 how many, #FF26
; how far back the screen looks). Copied 8 bytes at a time through the stack - only the window
; changes, so no main RAM for a buffer
asm_1_304_n_HW:         equ 80		; Hyp.cls 547
asm_1_304_n_HROWS:      equ 48		; Hyp.cls 548
asm_1_304_n_cn_hput:                            ; HL = the row going (the page) [549]
            ld a, (#7F21)		; Hyp.cls 550
            or a		; Hyp.cls 551
            ret z		; Hyp.cls 552
            ld (asm_1_304_n_cn_hs), hl		; Hyp.cls 553
            ld hl, (asm_1_304_n_cn_pg)		; Hyp.cls 554
            ld (asm_1_304_n_cn_h1), hl		; Hyp.cls 555
            ld hl, (#7F20)		; Hyp.cls 556
            ld (asm_1_304_n_cn_h2), hl		; Hyp.cls 557
            ld a, (#7F24)		; Hyp.cls 558
            call asm_1_304_n_cn_haddr		; Hyp.cls 559
            ld (asm_1_304_n_cn_hd), hl		; Hyp.cls 560
            ld hl, #7F24            ; the next row on, one more kept [561]
            ld a, (hl)		; Hyp.cls 562
            inc a		; Hyp.cls 563
            cp asm_1_304_n_HROWS		; Hyp.cls 564
            jr c, asm_1_304_n_cn_hp_h		; Hyp.cls 565
            xor a		; Hyp.cls 566
asm_1_304_n_cn_hp_h:		; Hyp.cls 567
            ld (hl), a		; Hyp.cls 568
            inc hl		; Hyp.cls 569
            ld a, (hl)		; Hyp.cls 570
            cp asm_1_304_n_HROWS		; Hyp.cls 571
            jr nc, asm_1_304_n_cn_hcp		; Hyp.cls 572
            inc (hl)		; Hyp.cls 573
; cn_hcp: HW bytes from cn_hs in RAM setting cn_h1 to cn_hd in cn_h2, then the slot's page back
asm_1_304_n_cn_hcp:		; Hyp.cls 575
            ld a, asm_1_304_n_HW / 8		; Hyp.cls 576
asm_1_304_n_cn_hc_lp:		; Hyp.cls 577
            ld (asm_1_304_n_cn_hn), a		; Hyp.cls 578
            ld bc, (asm_1_304_n_cn_h1)		; Hyp.cls 579
    IFDEF NTC_MSXDOS		; Hyp.cls 580
            call msx_win		; Hyp.cls 581
    ELSE		; Hyp.cls 582
            out (c), c		; Hyp.cls 583
    ENDIF		; Hyp.cls 584
            ld hl, (asm_1_304_n_cn_hs)		; Hyp.cls 585
            ld b, 4		; Hyp.cls 586
asm_1_304_n_cn_hc_in:		; Hyp.cls 587
            ld e, (hl)		; Hyp.cls 588
            inc hl		; Hyp.cls 589
            ld d, (hl)		; Hyp.cls 590
            inc hl		; Hyp.cls 591
            push de		; Hyp.cls 592
            djnz asm_1_304_n_cn_hc_in		; Hyp.cls 593
            ld (asm_1_304_n_cn_hs), hl		; Hyp.cls 594
            ld bc, (asm_1_304_n_cn_h2)		; Hyp.cls 595
    IFDEF NTC_MSXDOS		; Hyp.cls 596
            call msx_win		; Hyp.cls 597
    ELSE		; Hyp.cls 598
            out (c), c		; Hyp.cls 599
    ENDIF		; Hyp.cls 600
            ld hl, (asm_1_304_n_cn_hd)		; Hyp.cls 601
            ld de, 8		; Hyp.cls 602
            add hl, de		; Hyp.cls 603
            ld (asm_1_304_n_cn_hd), hl		; Hyp.cls 604
            ld b, 4		; Hyp.cls 605
asm_1_304_n_cn_hc_out:		; Hyp.cls 606
            pop de		; Hyp.cls 607
            dec hl		; Hyp.cls 608
            ld (hl), d		; Hyp.cls 609
            dec hl		; Hyp.cls 610
            ld (hl), e		; Hyp.cls 611
            djnz asm_1_304_n_cn_hc_out		; Hyp.cls 612
            ld a, (asm_1_304_n_cn_hn)		; Hyp.cls 613
            dec a		; Hyp.cls 614
            jr nz, asm_1_304_n_cn_hc_lp		; Hyp.cls 615
            ld bc, (asm_1_304_n_cn_pg)		; Hyp.cls 616
    IFDEF NTC_MSXDOS		; Hyp.cls 617
            call msx_win		; Hyp.cls 618
    ELSE		; Hyp.cls 619
            out (c), c		; Hyp.cls 620
    ENDIF		; Hyp.cls 621
            ret		; Hyp.cls 622
asm_1_304_n_cn_hget:                            ; A = a line of the history (0 the oldest kept): copied to [623]
            ld hl, #7F24            ; #FF30 in the slot's page (HL) [624]
            add a, (hl)		; Hyp.cls 625
            inc hl		; Hyp.cls 626
            sub (hl)		; Hyp.cls 627
            jr nc, asm_1_304_n_cn_hg_r		; Hyp.cls 628
            add a, asm_1_304_n_HROWS		; Hyp.cls 629
asm_1_304_n_cn_hg_r:		; Hyp.cls 630
            call asm_1_304_n_cn_haddr		; Hyp.cls 631
            ld (asm_1_304_n_cn_hs), hl		; Hyp.cls 632
            ld hl, (#7F20)		; Hyp.cls 633
            ld (asm_1_304_n_cn_h1), hl		; Hyp.cls 634
            ld hl, (asm_1_304_n_cn_pg)		; Hyp.cls 635
            ld (asm_1_304_n_cn_h2), hl		; Hyp.cls 636
            ld hl, #7F30		; Hyp.cls 637
            ld (asm_1_304_n_cn_hd), hl		; Hyp.cls 638
            call asm_1_304_n_cn_hcp		; Hyp.cls 639
            ld hl, #7F30		; Hyp.cls 640
            ret		; Hyp.cls 641
asm_1_304_n_cn_haddr:                           ; A = a history row: HL = its address in the history page [642]
            ld e, a		; Hyp.cls 643
            ld a, asm_1_304_n_HW		; Hyp.cls 644
            call asm_1_304_n_cn_mul		; Hyp.cls 645
            ld de, (#7F22)		; Hyp.cls 646
            add hl, de		; Hyp.cls 647
            ret		; Hyp.cls 648
; cn_cls: the screen cleared (written only: the Library: ROM build's keyword ROM may be over it)
asm_1_304_n_cn_cls:		; Hyp.cls 650
    IFDEF NTC_MSXDOS		; Hyp.cls 651
            jp msx_vclr             ; MSX: the name table (32 rows) all spaces [652]
    ENDIF		; Hyp.cls 653
            ld hl, #C000		; Hyp.cls 654
            ld bc, #4000		; Hyp.cls 655
asm_1_304_n_cn_cl_lp:		; Hyp.cls 656
            ld (hl), 0		; Hyp.cls 657
            inc hl		; Hyp.cls 658
            dec bc		; Hyp.cls 659
            ld a, b		; Hyp.cls 660
            or c		; Hyp.cls 661
            jr nz, asm_1_304_n_cn_cl_lp		; Hyp.cls 662
            ret		; Hyp.cls 663
            ENDIF		; Hyp.cls 664

; cn_char: A = one character
asm_1_304_n_cn_char:		; Hyp.cls 667
            ld b, a		; Hyp.cls 668
            ld a, (#7685)           ; in an escape sequence? [669]
            or a		; Hyp.cls 670
            jr nz, asm_1_304_n_cn_esc0		; Hyp.cls 671
            ld a, b		; Hyp.cls 672
            cp 32		; Hyp.cls 673
            jp nc, asm_1_304_n_cn_print		; Hyp.cls 674
            ld hl, asm_1_304_n_cn_pv            ; a control code: the cursor may move (the pointers redone) [675]
            ld (hl), 0		; Hyp.cls 676
            cp 27		; Hyp.cls 677
            jr z, asm_1_304_n_cn_setesc		; Hyp.cls 678
            cp 13		; Hyp.cls 679
            jr z, asm_1_304_n_cn_cr		; Hyp.cls 680
            cp 10		; Hyp.cls 681
            jp z, asm_1_304_n_cn_nl		; Hyp.cls 682
            cp 9		; Hyp.cls 683
            jr z, asm_1_304_n_cn_tab		; Hyp.cls 684
            cp 8		; Hyp.cls 685
            ret nz                  ; other control codes: nothing [686]
            ld a, (#7682)           ; BS: back one (not past the start of the row) [687]
            or a		; Hyp.cls 688
            ret z		; Hyp.cls 689
            dec a		; Hyp.cls 690
            ld (#7682), a		; Hyp.cls 691
            ret		; Hyp.cls 692
asm_1_304_n_cn_tab:                             ; TAB: spaces to the next column of 8 [693]
            ld b, ' '		; Hyp.cls 694
            call asm_1_304_n_cn_print		; Hyp.cls 695
            ld a, (#7682)		; Hyp.cls 696
            and 7		; Hyp.cls 697
            jr nz, asm_1_304_n_cn_tab		; Hyp.cls 698
            ret		; Hyp.cls 699
asm_1_304_n_cn_setesc:		; Hyp.cls 700
            ld a, 1		; Hyp.cls 701
            ld (#7685), a		; Hyp.cls 702
            ret		; Hyp.cls 703
asm_1_304_n_cn_cr:		; Hyp.cls 704
            xor a		; Hyp.cls 705
            ld (#7682), a		; Hyp.cls 706
            ret		; Hyp.cls 707
asm_1_304_n_cn_esc0:		; Hyp.cls 708
            ld hl, asm_1_304_n_cn_pv		; Hyp.cls 709
            ld (hl), 0		; Hyp.cls 710
asm_1_304_n_cn_esc:		; Hyp.cls 711
            cp 1		; Hyp.cls 712
            jr nz, asm_1_304_n_cn_esc2		; Hyp.cls 713
            xor a                   ; ESC x [714]
            ld (#7685), a		; Hyp.cls 715
            ld a, b		; Hyp.cls 716
            cp 'E'		; Hyp.cls 717
            jp z, asm_1_304_n_cn_clear		; Hyp.cls 718
            cp 'H'		; Hyp.cls 719
            jr z, asm_1_304_n_cn_home		; Hyp.cls 720
            cp 'I'		; Hyp.cls 721
            jp z, asm_1_304_n_cn_rev		; Hyp.cls 722
            cp 'Y'		; Hyp.cls 723
            jr z, asm_1_304_n_cn_sety		; Hyp.cls 724
            cp 'A'		; Hyp.cls 725
            jr z, asm_1_304_n_cn_up		; Hyp.cls 726
            cp 'B'		; Hyp.cls 727
            jr z, asm_1_304_n_cn_down		; Hyp.cls 728
            cp 'C'		; Hyp.cls 729
            jr z, asm_1_304_n_cn_right		; Hyp.cls 730
            cp 'D'		; Hyp.cls 731
            jr z, asm_1_304_n_cn_lft		; Hyp.cls 732
            cp 'K'		; Hyp.cls 733
            jp z, asm_1_304_n_cn_eol		; Hyp.cls 734
            cp 'J'		; Hyp.cls 735
            jp z, asm_1_304_n_cn_eos		; Hyp.cls 736
            cp 'l'		; Hyp.cls 737
            jp z, asm_1_304_n_cn_eln		; Hyp.cls 738
            cp 'o'		; Hyp.cls 739
            jp z, asm_1_304_n_cn_sol		; Hyp.cls 740
            cp 'd'		; Hyp.cls 741
            jp z, asm_1_304_n_cn_sos		; Hyp.cls 742
            cp 'M'		; Hyp.cls 743
            jp z, asm_1_304_n_cn_dell		; Hyp.cls 744
            cp 'L'		; Hyp.cls 745
            jp z, asm_1_304_n_cn_insl		; Hyp.cls 746
            ret                     ; (the rest - e f j k p q ...: nothing) [747]
asm_1_304_n_cn_sety:		; Hyp.cls 748
            ld a, 2		; Hyp.cls 749
            ld (#7685), a		; Hyp.cls 750
            ret		; Hyp.cls 751
asm_1_304_n_cn_up:                              ; ESC A, B, C, D: up, down, right, left (not past the edge) [752]
            ld hl, #7683		; Hyp.cls 753
            jr asm_1_304_n_cn_dec		; Hyp.cls 754
asm_1_304_n_cn_lft:		; Hyp.cls 755
            ld hl, #7682		; Hyp.cls 756
asm_1_304_n_cn_dec:		; Hyp.cls 757
            ld a, (hl)		; Hyp.cls 758
            or a		; Hyp.cls 759
            ret z		; Hyp.cls 760
            dec (hl)		; Hyp.cls 761
            ret		; Hyp.cls 762
asm_1_304_n_cn_down:		; Hyp.cls 763
            ld de, #7683		; Hyp.cls 764
            ld hl, asm_1_304_n_cn_r		; Hyp.cls 765
            jr asm_1_304_n_cn_inc		; Hyp.cls 766
asm_1_304_n_cn_right:		; Hyp.cls 767
            ld de, #7682		; Hyp.cls 768
            ld hl, asm_1_304_n_cn_c		; Hyp.cls 769
asm_1_304_n_cn_inc:		; Hyp.cls 770
            ld a, (de)		; Hyp.cls 771
            inc a		; Hyp.cls 772
            cp (hl)		; Hyp.cls 773
            ret nc		; Hyp.cls 774
            ld (de), a		; Hyp.cls 775
            ret		; Hyp.cls 776
asm_1_304_n_cn_home:		; Hyp.cls 777
            xor a		; Hyp.cls 778
            ld (#7682), a		; Hyp.cls 779
            ld (#7683), a		; Hyp.cls 780
            ret		; Hyp.cls 781
asm_1_304_n_cn_esc2:		; Hyp.cls 782
            cp 2		; Hyp.cls 783
            jr nz, asm_1_304_n_cn_esc3		; Hyp.cls 784
            ld a, b                 ; ESC Y row [785]
            sub 32		; Hyp.cls 786
            ld (#7686), a		; Hyp.cls 787
            ld a, 3		; Hyp.cls 788
            ld (#7685), a		; Hyp.cls 789
            ret		; Hyp.cls 790
asm_1_304_n_cn_esc3:		; Hyp.cls 791
            xor a                   ; ESC Y row col [792]
            ld (#7685), a		; Hyp.cls 793
            ld a, b		; Hyp.cls 794
            sub 32		; Hyp.cls 795
            ld hl, asm_1_304_n_cn_c		; Hyp.cls 796
            cp (hl)		; Hyp.cls 797
            jr c, asm_1_304_n_cn_e3_col		; Hyp.cls 798
            xor a		; Hyp.cls 799
asm_1_304_n_cn_e3_col:		; Hyp.cls 800
            ld (#7682), a		; Hyp.cls 801
            ld a, (#7686)		; Hyp.cls 802
            ld hl, asm_1_304_n_cn_r		; Hyp.cls 803
            cp (hl)		; Hyp.cls 804
            jr c, asm_1_304_n_cn_e3_row		; Hyp.cls 805
            xor a		; Hyp.cls 806
asm_1_304_n_cn_e3_row:		; Hyp.cls 807
            ld (#7683), a		; Hyp.cls 808
            ret		; Hyp.cls 809

; a printable character (B): into the page, on the screen if in front, the column on. The page
; and screen pointers are worked out at the first character after the cursor moved (cn_pv 0),
; then just stepped on - a run of characters costs the 8 screen bytes each, not a sum each
asm_1_304_n_cn_print:		; Hyp.cls 814
            ld a, (asm_1_304_n_cn_pv)		; Hyp.cls 815
            or a		; Hyp.cls 816
            jr nz, asm_1_304_n_cn_pr_have		; Hyp.cls 817
            ld a, (#7683)		; Hyp.cls 818
            call asm_1_304_n_cn_rowa		; Hyp.cls 819
            ld a, (#7682)		; Hyp.cls 820
            ld e, a		; Hyp.cls 821
            ld d, 0		; Hyp.cls 822
            add hl, de		; Hyp.cls 823
            ld (asm_1_304_n_cn_pp), hl		; Hyp.cls 824
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 825
            or a		; Hyp.cls 826
            jr z, asm_1_304_n_cn_pr_set		; Hyp.cls 827
            ld a, (#7682)		; Hyp.cls 828
            ld d, a		; Hyp.cls 829
            ld a, (#7683)		; Hyp.cls 830
            ld e, a		; Hyp.cls 831
            push bc                 ; (B: the character) [832]
            call asm_1_304_n_cn_scr		; Hyp.cls 833
            pop bc		; Hyp.cls 834
            ld (asm_1_304_n_cn_sp), hl		; Hyp.cls 835
asm_1_304_n_cn_pr_set:		; Hyp.cls 836
            ld a, 1		; Hyp.cls 837
            ld (asm_1_304_n_cn_pv), a		; Hyp.cls 838
asm_1_304_n_cn_pr_have:		; Hyp.cls 839
            ld hl, (asm_1_304_n_cn_pp)          ; the page [840]
            ld (hl), b		; Hyp.cls 841
            inc hl		; Hyp.cls 842
            ld (asm_1_304_n_cn_pp), hl		; Hyp.cls 843
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 844
            or a		; Hyp.cls 845
            jr z, asm_1_304_n_cn_pr_adv		; Hyp.cls 846
            ld hl, (asm_1_304_n_cn_sp)          ; the screen [847]
            push hl		; Hyp.cls 848
            ld a, b		; Hyp.cls 849
            call asm_1_304_n_cn_glyph8		; Hyp.cls 850
            pop hl		; Hyp.cls 851
            call asm_1_304_n_cn_next		; Hyp.cls 852
            ld (asm_1_304_n_cn_sp), hl		; Hyp.cls 853
asm_1_304_n_cn_pr_adv:		; Hyp.cls 854
            ld hl, #7682		; Hyp.cls 855
            inc (hl)		; Hyp.cls 856
            ld a, (hl)		; Hyp.cls 857
            ld hl, asm_1_304_n_cn_c		; Hyp.cls 858
            cp (hl)		; Hyp.cls 859
            ret c		; Hyp.cls 860
            xor a                   ; past the last column: the next row [861]
            ld (#7682), a		; Hyp.cls 862
            ld (asm_1_304_n_cn_pv), a		; Hyp.cls 863
; a line feed: the next row, or the page (and the screen) scroll
asm_1_304_n_cn_nl:		; Hyp.cls 865
            ld a, (#7683)		; Hyp.cls 866
            inc a		; Hyp.cls 867
            ld hl, asm_1_304_n_cn_r		; Hyp.cls 868
            cp (hl)		; Hyp.cls 869
            jr nc, asm_1_304_n_cn_scroll		; Hyp.cls 870
            ld (#7683), a		; Hyp.cls 871
            ret		; Hyp.cls 872
asm_1_304_n_cn_scroll:		; Hyp.cls 873
            ld a, (#7684)           ; the ring's top row moves on (no copy) [874]
            inc a		; Hyp.cls 875
            cp (hl)		; Hyp.cls 876
            jr c, asm_1_304_n_cn_sc_top		; Hyp.cls 877
            xor a		; Hyp.cls 878
asm_1_304_n_cn_sc_top:		; Hyp.cls 879
            ld (#7684), a		; Hyp.cls 880
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 881
            dec a		; Hyp.cls 882
            call asm_1_304_n_cn_rowa            ; the new last row cleared (the old top row: kept first) [883]
            IF asm_1_304_n_CN_SB		; Hyp.cls 884
            push hl		; Hyp.cls 885
            call asm_1_304_n_cn_hput		; Hyp.cls 886
            pop hl		; Hyp.cls 887
            ENDIF		; Hyp.cls 888
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 889
            ld b, a		; Hyp.cls 890
asm_1_304_n_cn_sc_cl:		; Hyp.cls 891
            ld (hl), ' '		; Hyp.cls 892
            inc hl		; Hyp.cls 893
            djnz asm_1_304_n_cn_sc_cl		; Hyp.cls 894
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 895
            or a		; Hyp.cls 896
            ret z		; Hyp.cls 897
    IFDEF NTC_MSXDOS		; Hyp.cls 898
            ld a, (var_hyp_sco)           ; MSX: the screen's top row (of the name table's 32) a row on - the [899]
            inc a                   ; V9938's vertical scroll (R#23) -, the new last row cleared [900]
            and 31		; Hyp.cls 901
            ld (var_hyp_sco), a		; Hyp.cls 902
            call asm_1_304_n_cn_crtc		; Hyp.cls 903
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 904
            dec a		; Hyp.cls 905
            ld e, a		; Hyp.cls 906
            jp asm_1_304_n_cn_sc_clr		; Hyp.cls 907
    ENDIF		; Hyp.cls 908
            ld hl, (var_hyp_sco)          ; the screen: its start a row on (R12, R13), the new last row [909]
            ld de, (var_hyp_scc)          ; cleared, the status strip again (it went off the top) [910]
            add hl, de		; Hyp.cls 911
            ld a, h		; Hyp.cls 912
            and #07		; Hyp.cls 913
            ld h, a		; Hyp.cls 914
            ld (var_hyp_sco), hl		; Hyp.cls 915
            call asm_1_304_n_cn_crtc		; Hyp.cls 916
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 917
            dec a		; Hyp.cls 918
            ld e, a		; Hyp.cls 919
asm_1_304_n_cn_sc_clr:                          ; E = a screen row: cleared, then the status strip again [920]
    IFDEF NTC_MSXDOS		; Hyp.cls 921
            ld a, e                 ; MSX: that row, and the rows under the console down to the [922]
            call msx_vclrow         ; screen's last (26: TEXT 2's 26.5) - the scroll brings old [923]
            ld a, (asm_1_304_n_cn_r)            ; rows of the name table's ring in there [924]
asm_1_304_n_cn_sc_ms:		; Hyp.cls 925
            cp 27		; Hyp.cls 926
            jp nc, asm_1_304_n_cn_strip		; Hyp.cls 927
            push af		; Hyp.cls 928
            call msx_vclrow		; Hyp.cls 929
            pop af		; Hyp.cls 930
            inc a		; Hyp.cls 931
            jr asm_1_304_n_cn_sc_ms		; Hyp.cls 932
    ENDIF		; Hyp.cls 933
            ld d, 0		; Hyp.cls 934
            call asm_1_304_n_cn_scr		; Hyp.cls 935
            ld b, 8		; Hyp.cls 936
asm_1_304_n_cn_sc_ln:		; Hyp.cls 937
            push bc		; Hyp.cls 938
            push hl		; Hyp.cls 939
            ld a, (var_hyp_scc)		; Hyp.cls 940
            ld b, a		; Hyp.cls 941
asm_1_304_n_cn_sc_b:		; Hyp.cls 942
            ld (hl), 0		; Hyp.cls 943
            call asm_1_304_n_cn_next		; Hyp.cls 944
            djnz asm_1_304_n_cn_sc_b		; Hyp.cls 945
            pop hl		; Hyp.cls 946
            ld a, h		; Hyp.cls 947
            add a, 8		; Hyp.cls 948
            ld h, a		; Hyp.cls 949
            pop bc		; Hyp.cls 950
            djnz asm_1_304_n_cn_sc_ln		; Hyp.cls 951
            jp asm_1_304_n_cn_strip		; Hyp.cls 952

; ESC I (reverse line feed): the row before, or on the top row the page (and the screen) scroll
; back: the ring's top row a row back, the new top row cleared; on the screen its start a row
; back (R12, R13) and the new top row cleared - the line feed's scroll the other way
asm_1_304_n_cn_rev:		; Hyp.cls 957
            ld a, (#7683)		; Hyp.cls 958
            or a		; Hyp.cls 959
            jr z, asm_1_304_n_cn_rv_sc		; Hyp.cls 960
            dec a		; Hyp.cls 961
            ld (#7683), a		; Hyp.cls 962
            ret		; Hyp.cls 963
asm_1_304_n_cn_rv_sc:		; Hyp.cls 964
            ld a, (#7684)		; Hyp.cls 965
            or a		; Hyp.cls 966
            jr nz, asm_1_304_n_cn_rv_top		; Hyp.cls 967
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 968
asm_1_304_n_cn_rv_top:		; Hyp.cls 969
            dec a		; Hyp.cls 970
            ld (#7684), a		; Hyp.cls 971
            xor a		; Hyp.cls 972
            call asm_1_304_n_cn_rowa            ; (row 0 of the page now) [973]
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 974
            ld b, a		; Hyp.cls 975
asm_1_304_n_cn_rv_cl:		; Hyp.cls 976
            ld (hl), ' '		; Hyp.cls 977
            inc hl		; Hyp.cls 978
            djnz asm_1_304_n_cn_rv_cl		; Hyp.cls 979
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 980
            or a		; Hyp.cls 981
            ret z		; Hyp.cls 982
    IFDEF NTC_MSXDOS		; Hyp.cls 983
            ld a, (var_hyp_sco)           ; MSX: the top row a row back (R#23), the new top row cleared [984]
            dec a		; Hyp.cls 985
            and 31		; Hyp.cls 986
            ld (var_hyp_sco), a		; Hyp.cls 987
            call asm_1_304_n_cn_crtc		; Hyp.cls 988
            ld e, 0		; Hyp.cls 989
            jp asm_1_304_n_cn_sc_clr		; Hyp.cls 990
    ENDIF		; Hyp.cls 991
            ld hl, (var_hyp_sco)		; Hyp.cls 992
            ld de, (var_hyp_scc)		; Hyp.cls 993
            or a		; Hyp.cls 994
            sbc hl, de		; Hyp.cls 995
            ld a, h		; Hyp.cls 996
            and #07		; Hyp.cls 997
            ld h, a		; Hyp.cls 998
            ld (var_hyp_sco), hl		; Hyp.cls 999
            call asm_1_304_n_cn_crtc		; Hyp.cls 1000
            ld e, 0		; Hyp.cls 1001
            jp asm_1_304_n_cn_sc_clr		; Hyp.cls 1002

; ESC K the row from the cursor on cleared, J the rest of the page too, l the whole row, o the
; row up to the cursor, d the page up to it; M the cursor's row deleted (those below up a row, a
; blank one at the end), L a blank one put in (those below down, the last gone) - the column 0.
; The page changed first, then its rows drawn again on the screen when in front
asm_1_304_n_cn_eol:		; Hyp.cls 1008
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 1009
            ld hl, #7682		; Hyp.cls 1010
            sub (hl)		; Hyp.cls 1011
            ld b, a		; Hyp.cls 1012
            ld d, (hl)		; Hyp.cls 1013
            ld a, (#7683)		; Hyp.cls 1014
            ld e, a		; Hyp.cls 1015
            jp asm_1_304_n_cn_wipen		; Hyp.cls 1016
asm_1_304_n_cn_eos:		; Hyp.cls 1017
            call asm_1_304_n_cn_eol		; Hyp.cls 1018
            ld a, (#7683)		; Hyp.cls 1019
asm_1_304_n_cn_eos_lp:		; Hyp.cls 1020
            inc a		; Hyp.cls 1021
            ld hl, asm_1_304_n_cn_r		; Hyp.cls 1022
            cp (hl)		; Hyp.cls 1023
            ret nc		; Hyp.cls 1024
            push af		; Hyp.cls 1025
            ld e, a		; Hyp.cls 1026
            call asm_1_304_n_cn_wrow		; Hyp.cls 1027
            pop af		; Hyp.cls 1028
            jr asm_1_304_n_cn_eos_lp		; Hyp.cls 1029
asm_1_304_n_cn_eln:		; Hyp.cls 1030
            ld a, (#7683)		; Hyp.cls 1031
            ld e, a		; Hyp.cls 1032
            jp asm_1_304_n_cn_wrow		; Hyp.cls 1033
asm_1_304_n_cn_sol:		; Hyp.cls 1034
            ld a, (#7682)		; Hyp.cls 1035
            inc a		; Hyp.cls 1036
            ld b, a		; Hyp.cls 1037
            ld d, 0		; Hyp.cls 1038
            ld a, (#7683)		; Hyp.cls 1039
            ld e, a		; Hyp.cls 1040
            jp asm_1_304_n_cn_wipen		; Hyp.cls 1041
asm_1_304_n_cn_sos:		; Hyp.cls 1042
            call asm_1_304_n_cn_sol		; Hyp.cls 1043
            ld a, (#7683)		; Hyp.cls 1044
asm_1_304_n_cn_sos_lp:		; Hyp.cls 1045
            or a		; Hyp.cls 1046
            ret z		; Hyp.cls 1047
            dec a		; Hyp.cls 1048
            push af		; Hyp.cls 1049
            ld e, a		; Hyp.cls 1050
            call asm_1_304_n_cn_wrow		; Hyp.cls 1051
            pop af		; Hyp.cls 1052
            jr asm_1_304_n_cn_sos_lp		; Hyp.cls 1053
asm_1_304_n_cn_dell:		; Hyp.cls 1054
            xor a		; Hyp.cls 1055
            ld (#7682), a		; Hyp.cls 1056
            ld a, (#7683)		; Hyp.cls 1057
            ld b, a                 ; B: the row filled from the one below [1058]
asm_1_304_n_cn_dl_lp:		; Hyp.cls 1059
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 1060
            dec a		; Hyp.cls 1061
            cp b		; Hyp.cls 1062
            jr z, asm_1_304_n_cn_dl_end		; Hyp.cls 1063
            ld c, b		; Hyp.cls 1064
            inc c		; Hyp.cls 1065
            ld a, b		; Hyp.cls 1066
            push bc		; Hyp.cls 1067
            call asm_1_304_n_cn_cpr		; Hyp.cls 1068
            pop bc		; Hyp.cls 1069
            inc b		; Hyp.cls 1070
            jr asm_1_304_n_cn_dl_lp		; Hyp.cls 1071
asm_1_304_n_cn_dl_end:		; Hyp.cls 1072
            ld e, b		; Hyp.cls 1073
            call asm_1_304_n_cn_wrow            ; the last row blank [1074]
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 1075
            dec a		; Hyp.cls 1076
            ld c, a		; Hyp.cls 1077
            ld a, (#7683)		; Hyp.cls 1078
            jr asm_1_304_n_cn_redr		; Hyp.cls 1079
asm_1_304_n_cn_insl:		; Hyp.cls 1080
            xor a		; Hyp.cls 1081
            ld (#7682), a		; Hyp.cls 1082
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 1083
            dec a		; Hyp.cls 1084
            ld b, a                 ; B: the row filled from the one above [1085]
asm_1_304_n_cn_il_lp:		; Hyp.cls 1086
            ld a, (#7683)		; Hyp.cls 1087
            cp b		; Hyp.cls 1088
            jr z, asm_1_304_n_cn_il_end		; Hyp.cls 1089
            ld c, b		; Hyp.cls 1090
            dec c		; Hyp.cls 1091
            ld a, b		; Hyp.cls 1092
            push bc		; Hyp.cls 1093
            call asm_1_304_n_cn_cpr		; Hyp.cls 1094
            pop bc		; Hyp.cls 1095
            dec b		; Hyp.cls 1096
            jr asm_1_304_n_cn_il_lp		; Hyp.cls 1097
asm_1_304_n_cn_il_end:		; Hyp.cls 1098
            ld e, b		; Hyp.cls 1099
            call asm_1_304_n_cn_wrow            ; the cursor's row blank [1100]
            ld a, (asm_1_304_n_cn_r)		; Hyp.cls 1101
            ld c, a		; Hyp.cls 1102
            ld a, (#7683)		; Hyp.cls 1103
            inc a		; Hyp.cls 1104
; cn_redr: rows A to C - 1 drawn again from the page
asm_1_304_n_cn_redr:		; Hyp.cls 1106
            cp c		; Hyp.cls 1107
            ret nc		; Hyp.cls 1108
            push af		; Hyp.cls 1109
            push bc		; Hyp.cls 1110
            ld e, a		; Hyp.cls 1111
            ld d, 0		; Hyp.cls 1112
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 1113
            ld b, a		; Hyp.cls 1114
            call asm_1_304_n_cn_drwn		; Hyp.cls 1115
            pop bc		; Hyp.cls 1116
            pop af		; Hyp.cls 1117
            inc a		; Hyp.cls 1118
            jr asm_1_304_n_cn_redr		; Hyp.cls 1119
; cn_cpr: the page's row C copied to its row A
asm_1_304_n_cn_cpr:		; Hyp.cls 1121
            push af		; Hyp.cls 1122
            ld a, c		; Hyp.cls 1123
            call asm_1_304_n_cn_rowa		; Hyp.cls 1124
            pop af		; Hyp.cls 1125
            push hl		; Hyp.cls 1126
            call asm_1_304_n_cn_rowa		; Hyp.cls 1127
            ex de, hl		; Hyp.cls 1128
            pop hl		; Hyp.cls 1129
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 1130
            ld c, a		; Hyp.cls 1131
            ld b, 0		; Hyp.cls 1132
            ldir		; Hyp.cls 1133
            ret		; Hyp.cls 1134
; cn_wrow: row E blank; cn_wipen: B characters of row E from column D blank (B > 0) - in the page,
; then drawn (cn_drwn: B characters of row E from column D, from the page, when in front)
asm_1_304_n_cn_wrow:		; Hyp.cls 1137
            ld d, 0		; Hyp.cls 1138
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 1139
            ld b, a		; Hyp.cls 1140
asm_1_304_n_cn_wipen:		; Hyp.cls 1141
            push de		; Hyp.cls 1142
            push bc		; Hyp.cls 1143
            ld a, e		; Hyp.cls 1144
            call asm_1_304_n_cn_rowa		; Hyp.cls 1145
            pop bc		; Hyp.cls 1146
            pop de		; Hyp.cls 1147
            push bc		; Hyp.cls 1148
            ld a, l		; Hyp.cls 1149
            add a, d		; Hyp.cls 1150
            ld l, a		; Hyp.cls 1151
            jr nc, asm_1_304_n_cn_wn_lp		; Hyp.cls 1152
            inc h		; Hyp.cls 1153
asm_1_304_n_cn_wn_lp:		; Hyp.cls 1154
            ld (hl), ' '		; Hyp.cls 1155
            inc hl		; Hyp.cls 1156
            djnz asm_1_304_n_cn_wn_lp		; Hyp.cls 1157
            pop bc		; Hyp.cls 1158
asm_1_304_n_cn_drwn:		; Hyp.cls 1159
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 1160
            or a		; Hyp.cls 1161
            ret z		; Hyp.cls 1162
            push de		; Hyp.cls 1163
            push bc		; Hyp.cls 1164
            ld a, e		; Hyp.cls 1165
            call asm_1_304_n_cn_rowa		; Hyp.cls 1166
            pop bc		; Hyp.cls 1167
            pop de		; Hyp.cls 1168
            ld a, l		; Hyp.cls 1169
            add a, d		; Hyp.cls 1170
            ld l, a		; Hyp.cls 1171
            jr nc, asm_1_304_n_cn_dw_p		; Hyp.cls 1172
            inc h		; Hyp.cls 1173
asm_1_304_n_cn_dw_p:                            ; the screen address worked out once, then stepped on (as [1174]
            push hl                 ; cn_print: a sum each character was a fifth of the time [1175]
            push bc                 ; a screen of text took - ESC K's) [1176]
            call asm_1_304_n_cn_scr		; Hyp.cls 1177
            pop bc		; Hyp.cls 1178
            pop de                  ; DE: the page's characters, HL the screen [1179]
asm_1_304_n_cn_dw_lp:		; Hyp.cls 1180
            ld a, (de)		; Hyp.cls 1181
            inc de		; Hyp.cls 1182
            push hl		; Hyp.cls 1183
            push de		; Hyp.cls 1184
            push bc		; Hyp.cls 1185
            call asm_1_304_n_cn_glyph8		; Hyp.cls 1186
            pop bc		; Hyp.cls 1187
            pop de		; Hyp.cls 1188
            pop hl		; Hyp.cls 1189
            call asm_1_304_n_cn_next		; Hyp.cls 1190
            djnz asm_1_304_n_cn_dw_lp		; Hyp.cls 1191
            ret		; Hyp.cls 1192

; ESC E: the page cleared, column, row and ring back to 0; the screen too if in front (written,
; not copied: the Library: ROM build may have the keyword ROM over it for reads)
asm_1_304_n_cn_clear:		; Hyp.cls 1196
            ld hl, #7700		; Hyp.cls 1197
            ld de, #7701		; Hyp.cls 1198
            ld (hl), ' '		; Hyp.cls 1199
            ld bc, 2047		; Hyp.cls 1200
            ldir		; Hyp.cls 1201
            xor a		; Hyp.cls 1202
            ld (#7682), a		; Hyp.cls 1203
            ld (#7683), a		; Hyp.cls 1204
            ld (#7684), a		; Hyp.cls 1205
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 1206
            or a		; Hyp.cls 1207
            ret z		; Hyp.cls 1208
            ld hl, 0		; Hyp.cls 1209
            ld (var_hyp_sco), hl		; Hyp.cls 1210
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen) [1211]
            call asm_1_304_n_cn_crtc		; Hyp.cls 1212
    IFDEF NTC_MSXDOS		; Hyp.cls 1213
            call msx_vclr           ; MSX: the name table all spaces (sco 0, R#23 0: above) [1214]
    ELSE		; Hyp.cls 1215
            xor a		; Hyp.cls 1216
            ld hl, #C000		; Hyp.cls 1217
            ld c, #40		; Hyp.cls 1218
asm_1_304_n_cn_cl_l:		; Hyp.cls 1219
            ld b, 0		; Hyp.cls 1220
asm_1_304_n_cn_cl_b:		; Hyp.cls 1221
            ld (hl), a		; Hyp.cls 1222
            inc hl		; Hyp.cls 1223
            djnz asm_1_304_n_cn_cl_b		; Hyp.cls 1224
            dec c		; Hyp.cls 1225
            jr nz, asm_1_304_n_cn_cl_l		; Hyp.cls 1226
    ENDIF		; Hyp.cls 1227
; cn_strip: MODE S (the screen wider than the console): the status strip's 4 characters (#F68A)
; at the top of the columns right of the console
asm_1_304_n_cn_strip:		; Hyp.cls 1230
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 1231
            or a		; Hyp.cls 1232
            ret z		; Hyp.cls 1233
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 1234
            ld d, a		; Hyp.cls 1235
            ld a, (var_hyp_scc)		; Hyp.cls 1236
            cp d		; Hyp.cls 1237
            ret z		; Hyp.cls 1238
            ret c		; Hyp.cls 1239
            ld e, 0		; Hyp.cls 1240
            ld hl, #768A		; Hyp.cls 1241
            ld b, 4		; Hyp.cls 1242
asm_1_304_n_cn_st_lp:		; Hyp.cls 1243
            ld a, (hl)		; Hyp.cls 1244
            push hl		; Hyp.cls 1245
            push de		; Hyp.cls 1246
            push bc		; Hyp.cls 1247
            call asm_1_304_n_cn_glyph		; Hyp.cls 1248
            pop bc		; Hyp.cls 1249
            pop de		; Hyp.cls 1250
            pop hl		; Hyp.cls 1251
            inc hl		; Hyp.cls 1252
            inc d		; Hyp.cls 1253
            djnz asm_1_304_n_cn_st_lp		; Hyp.cls 1254
            jp asm_1_304_n_cn_net                       ; then the network indicator, two rows down [1255]

; cn_net: the network indicator - the status strip's row 2 (row 1 left blank under [1]). 'N' when
; the network's up and idle; it blinks N / blank while there's traffic (nta, counted down by the
; 0.5s cursor-flash tick); the cell is left BLANK when the network's off, so nothing shows until a
; network is turned on (the screen is unchanged from before this feature). The cell is system-wide
; (not a slot's), so its state is in class vars (ntu / nta / ntb), reachable from the NET service
asm_1_304_n_cn_net:		; Hyp.cls 1262
            ld a, (asm_1_304_n_cn_front)		; Hyp.cls 1263
            or a		; Hyp.cls 1264
            ret z		; Hyp.cls 1265
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 1266
            ld d, a		; Hyp.cls 1267
            ld a, (var_hyp_scc)		; Hyp.cls 1268
            cp d		; Hyp.cls 1269
            ret z		; Hyp.cls 1270
            ret c		; Hyp.cls 1271
            ld hl, asm_1_304_n_cn_nblk                  ; the network's off: a blank cell (nothing shown) [1272]
            ld a, (var_hyp_ntu)		; Hyp.cls 1273
            or a		; Hyp.cls 1274
            jr z, asm_1_304_n_cn_net_draw		; Hyp.cls 1275
            ld a, (var_hyp_nta)                   ; up: steady 'N', or blank on the odd blink while busy [1276]
            or a		; Hyp.cls 1277
            ld a, 78		; Hyp.cls 1278
            jr z, asm_1_304_n_cn_net_put		; Hyp.cls 1279
            ld a, (var_hyp_ntb)		; Hyp.cls 1280
            and 1		; Hyp.cls 1281
            ld a, 78		; Hyp.cls 1282
            jr z, asm_1_304_n_cn_net_put		; Hyp.cls 1283
            ld a, 32		; Hyp.cls 1284
asm_1_304_n_cn_net_put:		; Hyp.cls 1285
            ld (asm_1_304_n_cn_nbuf + 1), a		; Hyp.cls 1286
            ld hl, asm_1_304_n_cn_nbuf		; Hyp.cls 1287
asm_1_304_n_cn_net_draw:		; Hyp.cls 1288
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 1289
            ld d, a                         ; the first strip column [1290]
            ld e, 2                         ; row 2 (row 1 blank, under [1] at row 0) [1291]
            ld b, 4		; Hyp.cls 1292
asm_1_304_n_cn_net_lp:		; Hyp.cls 1293
            ld a, (hl)		; Hyp.cls 1294
            push hl		; Hyp.cls 1295
            push de		; Hyp.cls 1296
            push bc		; Hyp.cls 1297
            call asm_1_304_n_cn_glyph		; Hyp.cls 1298
            pop bc		; Hyp.cls 1299
            pop de		; Hyp.cls 1300
            pop hl		; Hyp.cls 1301
            inc hl		; Hyp.cls 1302
            inc d		; Hyp.cls 1303
            djnz asm_1_304_n_cn_net_lp		; Hyp.cls 1304
            ret		; Hyp.cls 1305
asm_1_304_n_cn_nbuf:    db 91, 78, 93, 32               ; "[N] " when up; +1 overwritten with N / blank (blink) [1306]
asm_1_304_n_cn_nblk:    db 32, 32, 32, 32               ; a blank cell (network off: nothing shown) [1307]

; cn_crtc: the screen's start (sco, bytes) to the CRTC: R12 = #30 + its words' high 2 bits, R13
; the low 8 (#C000, MA10 / MA11 clear: kept within 2K, never the carry into the next 16K)
asm_1_304_n_cn_crtc:		; Hyp.cls 1311
    IFDEF NTC_MSXDOS		; Hyp.cls 1312
            jp msx_vr23             ; MSX: R#23 = the top row * 8 [1313]
    ENDIF		; Hyp.cls 1314
            ld hl, (var_hyp_sco)		; Hyp.cls 1315
            srl h		; Hyp.cls 1316
            rr l		; Hyp.cls 1317
            ld a, h		; Hyp.cls 1318
            and 3		; Hyp.cls 1319
            or #30		; Hyp.cls 1320
            ld bc, #BC0C		; Hyp.cls 1321
            out (c), c		; Hyp.cls 1322
            inc b		; Hyp.cls 1323
            out (c), a		; Hyp.cls 1324
            ld bc, #BC0D		; Hyp.cls 1325
            out (c), c		; Hyp.cls 1326
            inc b		; Hyp.cls 1327
            out (c), l		; Hyp.cls 1328
            ret		; Hyp.cls 1329

; cn_rowa: A = row of the screen -> HL = its row in the page ring (#7700 + ((top + A) mod rows)
; * columns)
asm_1_304_n_cn_rowa:		; Hyp.cls 1333
            ld hl, #7684		; Hyp.cls 1334
            add a, (hl)		; Hyp.cls 1335
            ld hl, asm_1_304_n_cn_r		; Hyp.cls 1336
            cp (hl)		; Hyp.cls 1337
            jr c, asm_1_304_n_cn_ra_in		; Hyp.cls 1338
            sub (hl)		; Hyp.cls 1339
asm_1_304_n_cn_ra_in:		; Hyp.cls 1340
            ld e, a		; Hyp.cls 1341
            ld a, (asm_1_304_n_cn_c)		; Hyp.cls 1342
            call asm_1_304_n_cn_mul		; Hyp.cls 1343
            ld de, #7700		; Hyp.cls 1344
            add hl, de		; Hyp.cls 1345
            ret		; Hyp.cls 1346

; cn_mul: HL = A * E (BC kept; D = 0 after)
asm_1_304_n_cn_mul:		; Hyp.cls 1349
            push bc		; Hyp.cls 1350
            ld hl, 0		; Hyp.cls 1351
            ld d, 0		; Hyp.cls 1352
            ld b, 8		; Hyp.cls 1353
asm_1_304_n_cn_mu_lp:		; Hyp.cls 1354
            add hl, hl		; Hyp.cls 1355
            rlca		; Hyp.cls 1356
            jr nc, asm_1_304_n_cn_mu_n		; Hyp.cls 1357
            add hl, de		; Hyp.cls 1358
asm_1_304_n_cn_mu_n:		; Hyp.cls 1359
            djnz asm_1_304_n_cn_mu_lp		; Hyp.cls 1360
            pop bc		; Hyp.cls 1361
            ret		; Hyp.cls 1362

; cn_next: HL = the next screen byte: + 1 within its 2K line block (BC kept)
asm_1_304_n_cn_next:		; Hyp.cls 1365
    IFDEF NTC_MSXDOS		; Hyp.cls 1366
            inc l                   ; ZX Next: the tilemap is linear - plain 16-bit increment [1367]
            ret nz		; Hyp.cls 1368
            inc h		; Hyp.cls 1369
            ret		; Hyp.cls 1370
    ENDIF		; Hyp.cls 1371
            inc l		; Hyp.cls 1372
            ret nz		; Hyp.cls 1373
            ld a, h		; Hyp.cls 1374
            inc a		; Hyp.cls 1375
            and #07		; Hyp.cls 1376
            push bc		; Hyp.cls 1377
            ld c, a		; Hyp.cls 1378
            ld a, h		; Hyp.cls 1379
            and #F8		; Hyp.cls 1380
            or c		; Hyp.cls 1381
            ld h, a		; Hyp.cls 1382
            pop bc		; Hyp.cls 1383
            ret		; Hyp.cls 1384

; cn_glyph: A = character, D = column, E = row: drawn (cn_show)
asm_1_304_n_cn_glyph:		; Hyp.cls 1387
            push af		; Hyp.cls 1388
            call asm_1_304_n_cn_scr		; Hyp.cls 1389
            pop af		; Hyp.cls 1390
; cn_glyph8: A = character, HL = its screen address: its 8 bytes into screen memory (mode 2, pen
; 1 on paper 0), one per pixel line (#800 apart; unrolled)
asm_1_304_n_cn_glyph8:		; Hyp.cls 1393
    IFDEF NTC_MSXDOS		; Hyp.cls 1394
            ; MSX: the character into its cell of the name table (HL: cn_scr's VRAM address)
            ld c, a		; Hyp.cls 1396
            ld a, l		; Hyp.cls 1397
            out (#99), a		; Hyp.cls 1398
            ld a, h		; Hyp.cls 1399
            or #40		; Hyp.cls 1400
            out (#99), a		; Hyp.cls 1401
            ld a, c		; Hyp.cls 1402
            out (#98), a		; Hyp.cls 1403
            ret		; Hyp.cls 1404
    ENDIF		; Hyp.cls 1405
            sub 32		; Hyp.cls 1406
            cp 96		; Hyp.cls 1407
            jr c, asm_1_304_n_cn_gl_ok		; Hyp.cls 1408
            ld a, '?' - 32		; Hyp.cls 1409
asm_1_304_n_cn_gl_ok:		; Hyp.cls 1410
            push hl		; Hyp.cls 1411
            ld l, a		; Hyp.cls 1412
            ld h, 0		; Hyp.cls 1413
            add hl, hl		; Hyp.cls 1414
            add hl, hl		; Hyp.cls 1415
            add hl, hl		; Hyp.cls 1416
            ld de, 62208 - #8000   ; (the bank's page 3 in the window: FONT - #C000 + #4000) [1417]
            add hl, de		; Hyp.cls 1418
            ex de, hl               ; DE = its matrix [1419]
            pop hl		; Hyp.cls 1420
            ld a, (de)		; Hyp.cls 1421
            ld (hl), a		; Hyp.cls 1422
            inc de		; Hyp.cls 1423
            ld a, h		; Hyp.cls 1424
            add a, 8		; Hyp.cls 1425
            ld h, a		; Hyp.cls 1426
            ld a, (de)		; Hyp.cls 1427
            ld (hl), a		; Hyp.cls 1428
            inc de		; Hyp.cls 1429
            ld a, h		; Hyp.cls 1430
            add a, 8		; Hyp.cls 1431
            ld h, a		; Hyp.cls 1432
            ld a, (de)		; Hyp.cls 1433
            ld (hl), a		; Hyp.cls 1434
            inc de		; Hyp.cls 1435
            ld a, h		; Hyp.cls 1436
            add a, 8		; Hyp.cls 1437
            ld h, a		; Hyp.cls 1438
            ld a, (de)		; Hyp.cls 1439
            ld (hl), a		; Hyp.cls 1440
            inc de		; Hyp.cls 1441
            ld a, h		; Hyp.cls 1442
            add a, 8		; Hyp.cls 1443
            ld h, a		; Hyp.cls 1444
            ld a, (de)		; Hyp.cls 1445
            ld (hl), a		; Hyp.cls 1446
            inc de		; Hyp.cls 1447
            ld a, h		; Hyp.cls 1448
            add a, 8		; Hyp.cls 1449
            ld h, a		; Hyp.cls 1450
            ld a, (de)		; Hyp.cls 1451
            ld (hl), a		; Hyp.cls 1452
            inc de		; Hyp.cls 1453
            ld a, h		; Hyp.cls 1454
            add a, 8		; Hyp.cls 1455
            ld h, a		; Hyp.cls 1456
            ld a, (de)		; Hyp.cls 1457
            ld (hl), a		; Hyp.cls 1458
            inc de		; Hyp.cls 1459
            ld a, h		; Hyp.cls 1460
            add a, 8		; Hyp.cls 1461
            ld h, a		; Hyp.cls 1462
            ld a, (de)		; Hyp.cls 1463
            ld (hl), a		; Hyp.cls 1464
            ret		; Hyp.cls 1465
; cn_scr: D = column, E = row -> HL = the screen address: the screen's start (sco) + row *
; columns (scc) + column, within each 2K line block, at #C000
asm_1_304_n_cn_scr:		; Hyp.cls 1468
    IFDEF NTC_MSXDOS		; Hyp.cls 1469
            ld a, e                 ; MSX: the name table's row (the top row sco on, of 32) * 80 + [1470]
            push de                 ; the column (80 a row whatever the console's width) [1471]
            call msx_vrow		; Hyp.cls 1472
            pop de		; Hyp.cls 1473
            ld c, d		; Hyp.cls 1474
            ld b, 0		; Hyp.cls 1475
            add hl, bc		; Hyp.cls 1476
            ret		; Hyp.cls 1477
    ENDIF		; Hyp.cls 1478
            push de		; Hyp.cls 1479
            ld a, (var_hyp_scc)		; Hyp.cls 1480
            call asm_1_304_n_cn_mul		; Hyp.cls 1481
            pop de		; Hyp.cls 1482
            ld c, d		; Hyp.cls 1483
            ld b, 0		; Hyp.cls 1484
            add hl, bc		; Hyp.cls 1485
    IFDEF NTC_MSXDOS		; Hyp.cls 1486
            ret                     ; (MSX: not reached - cn_scr's own above) [1487]
    ENDIF		; Hyp.cls 1488
            ld bc, (var_hyp_sco)		; Hyp.cls 1489
            add hl, bc		; Hyp.cls 1490
            ld a, h		; Hyp.cls 1491
            and #07		; Hyp.cls 1492
            or #C0		; Hyp.cls 1493
            ld h, a		; Hyp.cls 1494
            ret		; Hyp.cls 1495
asm_1_304_n_cn_cuxor:                           ; the cursor's underline XORed at cn_ca, on <-> off [1496]
    IFDEF NTC_MSXDOS		; Hyp.cls 1497
            ld hl, (asm_1_304_n_cn_ca)          ; MSX: the cell - on: the character there kept (cn_cuch), an [1498]
            ld a, (var_hyp_ccu)           ; underline shown; off: the character back [1499]
            xor 1		; Hyp.cls 1500
            ld (var_hyp_ccu), a		; Hyp.cls 1501
            jr z, asm_1_304_n_cn_cuoff		; Hyp.cls 1502
            ld a, l		; Hyp.cls 1503
            out (#99), a		; Hyp.cls 1504
            ld a, h		; Hyp.cls 1505
            and #3F		; Hyp.cls 1506
            out (#99), a		; Hyp.cls 1507
            nop		; Hyp.cls 1508
            in a, (#98)		; Hyp.cls 1509
            ld (asm_1_304_n_cn_cuch), a		; Hyp.cls 1510
            ld a, '_'		; Hyp.cls 1511
            jp asm_1_304_n_cn_glyph8		; Hyp.cls 1512
asm_1_304_n_cn_cuoff:   ld a, (asm_1_304_n_cn_cuch)		; Hyp.cls 1513
            jp asm_1_304_n_cn_glyph8		; Hyp.cls 1514
asm_1_304_n_cn_cuch:    db ' '		; Hyp.cls 1515
; ---- the MSX's screen: TEXT 2 (80 columns) on the V9938, its name table at #0000 a ring of 32
; rows (2560 bytes), the screen's top row sco of them (R#23 = sco * 8: the vertical scroll), 26.5
; rows shown (the blink table at #0A00, out of the ring's way). Interrupts off throughout (the
; BIOS's handler reads the status: a half set address lost)
@msx_vrow:                          ; A = a screen row -> HL = its name table address. BC kept [1520]
            ld hl, var_hyp_sco		; Hyp.cls 1521
            add a, (hl)		; Hyp.cls 1522
            and 31		; Hyp.cls 1523
            ld l, a		; Hyp.cls 1524
            ld h, 0		; Hyp.cls 1525
            add hl, hl		; Hyp.cls 1526
            add hl, hl		; Hyp.cls 1527
            add hl, hl		; Hyp.cls 1528
            add hl, hl              ; * 16 [1529]
            ld e, l		; Hyp.cls 1530
            ld d, h		; Hyp.cls 1531
            add hl, hl		; Hyp.cls 1532
            add hl, hl              ; * 64 [1533]
            add hl, de              ; * 80 [1534]
            ret		; Hyp.cls 1535
@msx_vwa:                           ; the VDP's address for writing = HL. A used [1536]
            ld a, l		; Hyp.cls 1537
            out (#99), a		; Hyp.cls 1538
            ld a, h		; Hyp.cls 1539
            and #3F		; Hyp.cls 1540
            or #40		; Hyp.cls 1541
            out (#99), a		; Hyp.cls 1542
            ret		; Hyp.cls 1543
@msx_vclrow:                        ; A = a screen row: all spaces. BC, DE, HL used [1544]
            call msx_vrow		; Hyp.cls 1545
            call msx_vwa		; Hyp.cls 1546
            ld b, 80		; Hyp.cls 1547
            ld a, ' '		; Hyp.cls 1548
asm_1_304_n_msx_vcr_lp:		; Hyp.cls 1549
            out (#98), a		; Hyp.cls 1550
            djnz asm_1_304_n_msx_vcr_lp		; Hyp.cls 1551
            ret		; Hyp.cls 1552
@msx_vclr:                          ; the whole name table spaces (sco, R#23 as they are) [1553]
            ld hl, 0		; Hyp.cls 1554
            call msx_vwa		; Hyp.cls 1555
            ld bc, 10               ; 2560: B 0 (256), C 10 [1556]
            ld a, ' '		; Hyp.cls 1557
asm_1_304_n_msx_vcl_lp:		; Hyp.cls 1558
            out (#98), a		; Hyp.cls 1559
            djnz asm_1_304_n_msx_vcl_lp		; Hyp.cls 1560
            dec c		; Hyp.cls 1561
            jr nz, asm_1_304_n_msx_vcl_lp		; Hyp.cls 1562
            ret		; Hyp.cls 1563
; msx_t300 - HL = the clock at 300 a second, as the CPC's (the kernel's, the services'): JIFFY
; (the frames) * 6 at 50 Hz, * 5 at 60 (R#9's PAL bit, as the BIOS keeps it), + a tick for each
; look within the frame (up to its last: never past the next frame's first). DE used
@msx_t300:		; Hyp.cls 1567
            ld hl, (#FC9E)		; Hyp.cls 1568
            ld de, (asm_1_304_n_msx_tj)		; Hyp.cls 1569
            ld (asm_1_304_n_msx_tj), hl		; Hyp.cls 1570
            or a		; Hyp.cls 1571
            sbc hl, de		; Hyp.cls 1572
            add hl, de		; Hyp.cls 1573
            ld a, 0		; Hyp.cls 1574
            jr nz, asm_1_304_n_msx_t3_new       ; (a new frame: its first tick) [1575]
            ld a, (asm_1_304_n_msx_ts)		; Hyp.cls 1576
            inc a		; Hyp.cls 1577
asm_1_304_n_msx_t3_new:		; Hyp.cls 1578
            ld e, l		; Hyp.cls 1579
            ld d, h		; Hyp.cls 1580
            add hl, hl		; Hyp.cls 1581
            add hl, hl		; Hyp.cls 1582
            add hl, de              ; * 5 [1583]
            ld e, a		; Hyp.cls 1584
            ld a, (#FFE8)		; Hyp.cls 1585
            and 2		; Hyp.cls 1586
            jr z, asm_1_304_n_msx_t3_60		; Hyp.cls 1587
            add hl, de              ; * 6 (50 Hz) [1588]
            ld a, e		; Hyp.cls 1589
            cp 6		; Hyp.cls 1590
            jr asm_1_304_n_msx_t3_sub		; Hyp.cls 1591
asm_1_304_n_msx_t3_60:		; Hyp.cls 1592
            ld a, e		; Hyp.cls 1593
            cp 5		; Hyp.cls 1594
asm_1_304_n_msx_t3_sub:		; Hyp.cls 1595
            jr c, asm_1_304_n_msx_t3_ok		; Hyp.cls 1596
            dec e                   ; (no further than the frame's last tick) [1597]
asm_1_304_n_msx_t3_ok:		; Hyp.cls 1598
            ld a, e		; Hyp.cls 1599
            ld (asm_1_304_n_msx_ts), a		; Hyp.cls 1600
            ld d, 0		; Hyp.cls 1601
            add hl, de              ; + the ticks seen within the frame [1602]
            ret		; Hyp.cls 1603
asm_1_304_n_msx_tj:     dw 0                    ; JIFFY when msx_t300 looked last [1604]
asm_1_304_n_msx_ts:     db 0                    ; the ticks given within that frame (0 - 5): each look moves the [1605]
                                    ; clock on one, so a slot asleep for a tick (the kernel's wk) runs
                                    ; again at its next pass, not a frame later
@msx_vr23:                          ; R#23 = sco * 8 [1608]
            ld a, (var_hyp_sco)		; Hyp.cls 1609
            add a, a		; Hyp.cls 1610
            add a, a		; Hyp.cls 1611
            add a, a		; Hyp.cls 1612
            out (#99), a		; Hyp.cls 1613
            ld a, #80 + 23		; Hyp.cls 1614
            out (#99), a		; Hyp.cls 1615
            ret		; Hyp.cls 1616
    ENDIF		; Hyp.cls 1617
            ld hl, (asm_1_304_n_cn_ca)		; Hyp.cls 1618
            ld a, (hl)		; Hyp.cls 1619
            cpl		; Hyp.cls 1620
            ld (hl), a		; Hyp.cls 1621
            ld a, (var_hyp_ccu)		; Hyp.cls 1622
            xor 1		; Hyp.cls 1623
            ld (var_hyp_ccu), a		; Hyp.cls 1624
            ret		; Hyp.cls 1625
asm_1_304_n_cn_was:     db 0		; Hyp.cls 1626
asm_1_304_n_cn_ca:      dw 0		; Hyp.cls 1627
asm_1_304_n_cn_front:   db 0		; Hyp.cls 1628
asm_1_304_n_cn_c:       db 80                   ; the slot's columns, rows [1629]
asm_1_304_n_cn_r:       db 25		; Hyp.cls 1630
asm_1_304_n_cn_pv:      db 0                    ; cn_pp / cn_sp valid (0: the cursor moved) [1631]
asm_1_304_n_cn_pp:      dw 0                    ; the page byte for the next character [1632]
asm_1_304_n_cn_sp:      dw 0                    ; its screen address [1633]
asm_1_304_n_cn_left:    dw 0		; Hyp.cls 1634
asm_1_304_n_cn_ptr:     dw 0		; Hyp.cls 1635
            IF asm_1_304_n_CN_SB		; Hyp.cls 1636
asm_1_304_n_cn_pg:      dw 0                    ; the slot's page 3 setting (pg) [1637]
asm_1_304_n_cn_h1:      dw 0                    ; cn_hcp: from (its setting, address), to, 8-byte runs left [1638]
asm_1_304_n_cn_hs:      dw 0		; Hyp.cls 1639
asm_1_304_n_cn_h2:      dw 0		; Hyp.cls 1640
asm_1_304_n_cn_hd:      dw 0		; Hyp.cls 1641
asm_1_304_n_cn_hn:      db 0		; Hyp.cls 1642
            ENDIF		; Hyp.cls 1643
asm_1_304_n_cn_end:		; Hyp.cls 1644
			ret			; end of #asm

asm_1_1652_n:		; #asm, Hyp.cls line 1652 (normal)
    IFDEF NTC_MSXDOS		; Hyp.cls 1653
            ; MSX: straight into the name table, row, col on (msx_vrow: the scroll's top row)
            ld (var_hyp_hsp), sp		; Hyp.cls 1655
            ld sp, (ntc_csp)		; Hyp.cls 1656
            ld a, (var_hyp_say_n)		; Hyp.cls 1657
            or a		; Hyp.cls 1658
            jr z, asm_1_1652_n_sy_zdone		; Hyp.cls 1659
            ld b, a		; Hyp.cls 1660
            ld a, (var_hyp_say_row)		; Hyp.cls 1661
            call msx_vrow		; Hyp.cls 1662
            ld a, (var_hyp_say_col)		; Hyp.cls 1663
            ld e, a		; Hyp.cls 1664
            ld d, 0		; Hyp.cls 1665
            add hl, de		; Hyp.cls 1666
            call msx_vwa		; Hyp.cls 1667
            ld hl, (var_hyp_say_p)		; Hyp.cls 1668
            ld a, (var_hyp_say_col)		; Hyp.cls 1669
            ld c, a		; Hyp.cls 1670
asm_1_1652_n_sy_zlp:		; Hyp.cls 1671
            ld a, c		; Hyp.cls 1672
            cp 80		; Hyp.cls 1673
            jr nc, asm_1_1652_n_sy_zdone		; Hyp.cls 1674
            ld a, (hl)		; Hyp.cls 1675
            out (#98), a		; Hyp.cls 1676
            inc hl		; Hyp.cls 1677
            inc c		; Hyp.cls 1678
            djnz asm_1_1652_n_sy_zlp		; Hyp.cls 1679
asm_1_1652_n_sy_zdone:		; Hyp.cls 1680
            ld sp, (var_hyp_hsp)		; Hyp.cls 1681
            jp asm_1_1652_n_sy_end		; Hyp.cls 1682
    ENDIF		; Hyp.cls 1683
            ld (var_hyp_hsp), sp		; Hyp.cls 1684
            ld sp, (ntc_csp)		; Hyp.cls 1685
            ld bc, (var_hyp_hps)          ; the hypervisor's page in the window: the font [1686]
            out (c), c		; Hyp.cls 1687
            ld hl, (var_hyp_sco)          ; the screen's start (TOP is shown in MODE 2: 80 columns) [1688]
            ld (asm_1_1652_n_sy_off), hl		; Hyp.cls 1689
            ld hl, (var_hyp_say_p)		; Hyp.cls 1690
            ld a, (var_hyp_say_n)		; Hyp.cls 1691
            ld b, a		; Hyp.cls 1692
            ld a, (var_hyp_say_col)		; Hyp.cls 1693
            ld d, a		; Hyp.cls 1694
            ld a, (var_hyp_say_row)		; Hyp.cls 1695
            ld e, a		; Hyp.cls 1696
            inc b		; Hyp.cls 1697
asm_1_1652_n_sy_lp:		; Hyp.cls 1698
            dec b		; Hyp.cls 1699
            jr z, asm_1_1652_n_sy_done		; Hyp.cls 1700
            ld a, d		; Hyp.cls 1701
            cp 80		; Hyp.cls 1702
            jr nc, asm_1_1652_n_sy_done		; Hyp.cls 1703
            ld a, (hl)		; Hyp.cls 1704
            inc hl		; Hyp.cls 1705
            push hl		; Hyp.cls 1706
            push bc		; Hyp.cls 1707
            push de		; Hyp.cls 1708
            sub 32                  ; the character's matrix [1709]
            cp 96		; Hyp.cls 1710
            jr c, asm_1_1652_n_sy_ok		; Hyp.cls 1711
            ld a, '?' - 32		; Hyp.cls 1712
asm_1_1652_n_sy_ok:		; Hyp.cls 1713
            ld l, a		; Hyp.cls 1714
            ld h, 0		; Hyp.cls 1715
            add hl, hl		; Hyp.cls 1716
            add hl, hl		; Hyp.cls 1717
            add hl, hl		; Hyp.cls 1718
            ld bc, #4000 + 4096  ; (the hypervisor's page in the window) [1719]
            add hl, bc		; Hyp.cls 1720
            push hl		; Hyp.cls 1721
            ld l, e                 ; its screen address: start + row * 80 + column, in 2K [1722]
            ld h, 0		; Hyp.cls 1723
            add hl, hl		; Hyp.cls 1724
            add hl, hl		; Hyp.cls 1725
            add hl, hl		; Hyp.cls 1726
            add hl, hl		; Hyp.cls 1727
            push hl		; Hyp.cls 1728
            add hl, hl		; Hyp.cls 1729
            add hl, hl		; Hyp.cls 1730
            pop bc		; Hyp.cls 1731
            add hl, bc		; Hyp.cls 1732
            ld c, d		; Hyp.cls 1733
            ld b, 0		; Hyp.cls 1734
            add hl, bc		; Hyp.cls 1735
            ld bc, (asm_1_1652_n_sy_off)		; Hyp.cls 1736
            add hl, bc		; Hyp.cls 1737
            ld a, h		; Hyp.cls 1738
            and #07		; Hyp.cls 1739
            or #C0		; Hyp.cls 1740
            ld h, a		; Hyp.cls 1741
            pop de		; Hyp.cls 1742
            ld b, 8		; Hyp.cls 1743
asm_1_1652_n_sy_ln:		; Hyp.cls 1744
            ld a, (de)		; Hyp.cls 1745
            ld (hl), a		; Hyp.cls 1746
            inc de		; Hyp.cls 1747
            ld a, h		; Hyp.cls 1748
            add a, 8		; Hyp.cls 1749
            ld h, a		; Hyp.cls 1750
            djnz asm_1_1652_n_sy_ln		; Hyp.cls 1751
            pop de		; Hyp.cls 1752
            pop bc		; Hyp.cls 1753
            pop hl		; Hyp.cls 1754
            inc d		; Hyp.cls 1755
            jr asm_1_1652_n_sy_lp		; Hyp.cls 1756
asm_1_1652_n_sy_done:		; Hyp.cls 1757
            ld bc, (ntc_rampt)		; Hyp.cls 1758
            out (c), c		; Hyp.cls 1759
            ld sp, (var_hyp_hsp)		; Hyp.cls 1760
            jr asm_1_1652_n_sy_end		; Hyp.cls 1761
asm_1_1652_n_sy_off:     dw 0		; Hyp.cls 1762
asm_1_1652_n_sy_end:		; Hyp.cls 1763
			ret			; end of #asm

asm_1_1777_n:		; #asm, Hyp.cls line 1777 (normal)
            ld (var_hyp_hsp), sp          ; (the real stack: SP is the thread) [1778]
            ld sp, (ntc_csp)		; Hyp.cls 1779
            xor a		; Hyp.cls 1780
            ld (var_hyp_ccu), a           ; (the screen cleared: no cursor on it) [1781]
            ld a, (var_hyp_scr_m)		; Hyp.cls 1782
            cp 6		; Hyp.cls 1783
            jr c, asm_1_1777_n_sm_ok		; Hyp.cls 1784
            xor a		; Hyp.cls 1785
asm_1_1777_n_sm_ok:		; Hyp.cls 1786
            ld l, a                 ; the mode's row of the table (6 bytes) [1787]
            add a, a		; Hyp.cls 1788
            add a, l		; Hyp.cls 1789
            add a, a		; Hyp.cls 1790
            ld e, a		; Hyp.cls 1791
            ld d, 0		; Hyp.cls 1792
            ld hl, asm_1_1777_n_sm_tab		; Hyp.cls 1793
    IFDEF NTC_MSXDOS		; Hyp.cls 1794
            ld hl, asm_1_1777_n_zxn_sm_tab       ; MSX: TEXT 2's modes (80 columns at most) [1795]
    ENDIF		; Hyp.cls 1796
            add hl, de		; Hyp.cls 1797
            ld a, (var_hyp_scr_k)		; Hyp.cls 1798
            or a		; Hyp.cls 1799
            jr z, asm_1_1777_n_sm_cols		; Hyp.cls 1800
            dec a		; Hyp.cls 1801
            jr z, asm_1_1777_n_sm_rows		; Hyp.cls 1802
            push hl                 ; 2: the screen [1803]
            ld e, (hl)              ; its columns [1804]
            ld d, 0		; Hyp.cls 1805
            ld (var_hyp_scc), de		; Hyp.cls 1806
            srl e		; Hyp.cls 1807
            ld (var_hyp_scw), de		; Hyp.cls 1808
            ld hl, 0		; Hyp.cls 1809
            ld (var_hyp_sco), hl		; Hyp.cls 1810
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen) [1811]
            pop hl		; Hyp.cls 1812
    IFNDEF NTC_MSXDOS		; Hyp.cls 1813
            inc hl		; Hyp.cls 1814
            inc hl                  ; R1, R2, R6, R7 [1815]
            di		; Hyp.cls 1816
            ld d, 1		; Hyp.cls 1817
            call asm_1_1777_n_sm_crtc		; Hyp.cls 1818
            ld d, 2		; Hyp.cls 1819
            call asm_1_1777_n_sm_crtc		; Hyp.cls 1820
            ld d, 6		; Hyp.cls 1821
            call asm_1_1777_n_sm_crtc		; Hyp.cls 1822
            ld d, 7		; Hyp.cls 1823
            call asm_1_1777_n_sm_crtc		; Hyp.cls 1824
            ld hl, asm_1_1777_n_sm_start         ; R12, R13: #C000 [1825]
            ld d, 12		; Hyp.cls 1826
            call asm_1_1777_n_sm_crtc		; Hyp.cls 1827
            ld d, 13		; Hyp.cls 1828
            call asm_1_1777_n_sm_crtc		; Hyp.cls 1829
            xor a                   ; cleared (written, not copied: the Library: ROM build may [1830]
            ld hl, #C000            ; have the keyword ROM over it for reads) [1831]
            ld c, #40		; Hyp.cls 1832
asm_1_1777_n_sm_cl:		; Hyp.cls 1833
            ld b, 0		; Hyp.cls 1834
asm_1_1777_n_sm_cl1:		; Hyp.cls 1835
            ld (hl), a		; Hyp.cls 1836
            inc hl		; Hyp.cls 1837
            djnz asm_1_1777_n_sm_cl1		; Hyp.cls 1838
            dec c		; Hyp.cls 1839
            jr nz, asm_1_1777_n_sm_cl		; Hyp.cls 1840
    ELSE                            ; MSX: no CRTC; the name table cleared, its top row 0 (R#23) [1841]
            call msx_vclr		; Hyp.cls 1842
            call msx_vr23		; Hyp.cls 1843
    ENDIF		; Hyp.cls 1844
            ld hl, 0		; Hyp.cls 1845
            jr asm_1_1777_n_sm_res		; Hyp.cls 1846
asm_1_1777_n_sm_cols:		; Hyp.cls 1847
            ld a, (hl)              ; the console's: the screen's, less the status strip's 4 (S) [1848]
            inc hl		; Hyp.cls 1849
            sub (hl)		; Hyp.cls 1850
            jr asm_1_1777_n_sm_a		; Hyp.cls 1851
asm_1_1777_n_sm_rows:		; Hyp.cls 1852
            inc hl		; Hyp.cls 1853
            inc hl		; Hyp.cls 1854
            inc hl		; Hyp.cls 1855
            inc hl		; Hyp.cls 1856
            ld a, (hl)		; Hyp.cls 1857
asm_1_1777_n_sm_a:		; Hyp.cls 1858
            ld l, a		; Hyp.cls 1859
            ld h, 0		; Hyp.cls 1860
asm_1_1777_n_sm_res:		; Hyp.cls 1861
            ld (var_hyp_scr_scr), hl		; Hyp.cls 1862
            ld sp, (var_hyp_hsp)		; Hyp.cls 1863
            ret                     ; (on with the thread) [1864]
asm_1_1777_n_sm_crtc:                            ; CRTC register D = (HL), HL on [1865]
            ld bc, #BC00		; Hyp.cls 1866
            out (c), d		; Hyp.cls 1867
            ld b, #BD		; Hyp.cls 1868
            ld a, (hl)		; Hyp.cls 1869
            out (c), a		; Hyp.cls 1870
            inc hl		; Hyp.cls 1871
            ret		; Hyp.cls 1872
asm_1_1777_n_sm_start:   db #30, 0		; Hyp.cls 1873
; columns, the status strip's, R1 (words a row), R2 (horizontal sync), R6 (rows), R7 (vertical sync)
asm_1_1777_n_sm_tab:     db 80, 0, 40, 46, 25, 30		; Hyp.cls 1875
            db 84, 4, 42, 47, 24, 30		; Hyp.cls 1876
            db 88, 0, 44, 48, 23, 29		; Hyp.cls 1877
            db 96, 0, 48, 50, 21, 28		; Hyp.cls 1878
            db 64, 0, 32, 42, 32, 34		; Hyp.cls 1879
            db 84, 0, 42, 47, 24, 30		; Hyp.cls 1880
    IFDEF NTC_MSXDOS		; Hyp.cls 1881
; MSX: TEXT 2, 80 x 26 at most (msx_vrow). cols (the status strip's in them), the strip's, (R1 R2
; unused), rows, (R7 unused). The CPC's wider modes (88, 96 columns) are 80 here
asm_1_1777_n_zxn_sm_tab: db 80, 0, 0, 0, 25, 0   ; MODE 2  80 x 25 [1884]
            db 80, 4, 0, 0, 24, 0   ; MODE S  console 76 + 4 status, 24 rows [1885]
            db 80, 0, 0, 0, 23, 0   ; MODE W  (88 x 23 on the CPC) [1886]
            db 80, 0, 0, 0, 21, 0   ; MODE UW (96 x 21) [1887]
            db 64, 0, 0, 0, 26, 0   ; MODE P  64 x 26 (TEXT 2 shows 26 rows; the CPC's 64 x 32) [1888]
            db 80, 0, 0, 0, 24, 0   ; MODE F  (84 x 24) [1889]
    ENDIF		; Hyp.cls 1890
			ret			; end of #asm

asm_1_1940_n:		; #asm, Hyp.cls line 1940 (normal)
    IFDEF NTC_MSXDOS		; Hyp.cls 1941
            ret                     ; ZX Next: no CPC firmware key-repeat (platform-specific) [1942]
    ELSE		; Hyp.cls 1943
            ld (var_hyp_hsp), sp		; Hyp.cls 1944
            ld sp, (ntc_csp)		; Hyp.cls 1945
            call #BB42              ; KM GET DELAY: H the start delay, L the repeat [1946]
            di		; Hyp.cls 1947
            ld a, h		; Hyp.cls 1948
            call asm_1_1940_n_kr_mul		; Hyp.cls 1949
            ld h, a		; Hyp.cls 1950
            ld a, l		; Hyp.cls 1951
            call asm_1_1940_n_kr_mul		; Hyp.cls 1952
            ld l, a		; Hyp.cls 1953
            call #BB3F              ; KM SET DELAY [1954]
            di		; Hyp.cls 1955
            ld sp, (var_hyp_hsp)		; Hyp.cls 1956
            jr asm_1_1940_n_kr_end		; Hyp.cls 1957
asm_1_1940_n_kr_mul:                             ; A = A x f, 255 at most (0: 256 to the firmware - kept) [1958]
            or a		; Hyp.cls 1959
            ret z		; Hyp.cls 1960
            push hl		; Hyp.cls 1961
            ld e, a		; Hyp.cls 1962
            ld d, 0		; Hyp.cls 1963
            ld hl, 0		; Hyp.cls 1964
            ld a, (var_hyp_keyrep_f)		; Hyp.cls 1965
            ld b, a		; Hyp.cls 1966
asm_1_1940_n_kr_lp:		; Hyp.cls 1967
            add hl, de		; Hyp.cls 1968
            djnz asm_1_1940_n_kr_lp		; Hyp.cls 1969
            ld a, h		; Hyp.cls 1970
            or a		; Hyp.cls 1971
            ld a, l		; Hyp.cls 1972
            pop hl		; Hyp.cls 1973
            ret z		; Hyp.cls 1974
            ld a, 255		; Hyp.cls 1975
            ret		; Hyp.cls 1976
asm_1_1940_n_kr_end:		; Hyp.cls 1977
    ENDIF		; Hyp.cls 1978
			ret			; end of #asm

asm_1_2008_n:		; #asm, Hyp.cls line 2008 (normal)
            ld (var_hyp_sps), sp		; Hyp.cls 2009
            ld sp, (ntc_csp)		; Hyp.cls 2010
    IFNDEF NTC_MSXDOS		; Hyp.cls 2011
            call #B903              ; KL U ROM DISABLE: the task's top 16K, not a ROM (Library: [2012]
    ELSE		; Hyp.cls 2013
            xor a                   ; zxn: no ROMs to disable [2014]
    ENDIF		; Hyp.cls 2015
            di                      ; ROM has the keyword ROM on), while it runs [2016]
            ld (var_hyp_rrom), a		; Hyp.cls 2017
            ld a, 6		; Hyp.cls 2018
            ld (var_hyp_slc), a		; Hyp.cls 2019
            ld a, 1                 ; from BASIC: it has taken the characters (Collected) [2020]
            ld (var_hyp_rclr), a		; Hyp.cls 2021
asm_1_2008_n_rn_again:		; Hyp.cls 2022
            push ix                 ; IX, IY and [2023]
            push iy		; Hyp.cls 2024
            db #08                  ; ex af, af': the alternate registers kept - the [2025]
            exx                     ; firmware's (BC' = its ROM / mode setting); a task [2026]
            push af                 ; may use them [2027]
            push bc		; Hyp.cls 2028
            push de		; Hyp.cls 2029
            push hl		; Hyp.cls 2030
            exx		; Hyp.cls 2031
            db #08		; Hyp.cls 2032
            ld hl, asm_1_2008_n_rn_back		; Hyp.cls 2033
            push hl                 ; where main RAM carries on [2034]
            ld (ntc_bk_sp), sp		; Hyp.cls 2035
            ld a, (var_hyp_rclr)		; Hyp.cls 2036
            ld e, a                 ; E = 1: the bank empties its characters out (BASIC has them) [2037]
            ld a, (var_hyp_ra)		; Hyp.cls 2038
            ld hl, (var_hyp_rhl)		; Hyp.cls 2039
            ld bc, (var_hyp_run_setting)		; Hyp.cls 2040
    IFDEF NTC_MSXDOS		; Hyp.cls 2041
            ; hyp -> task: the task's page 3 first (out (#FF): this code is in pages 0-2, the
            ; hypervisor's stack in page 3 is gone from here on - no push, no call), ra / rclr /
            ; rhl into the task's SWAP, then its sb_hin (HISW) maps pages 0-2 and lands it
            ld a, c		; Hyp.cls 2045
            or 7                                ; its page 3's setting (C2 + 5 = ordinal * 8 + 7) [2046]
            ld c, a		; Hyp.cls 2047
            call msx_mem_bank                   ; A = its segment [2048]
            out (#FF), a		; Hyp.cls 2049
            ld a, (var_hyp_rclr)		; Hyp.cls 2050
            ld (63185 + 2), a		; Hyp.cls 2051
            ld hl, (var_hyp_rhl)		; Hyp.cls 2052
            ld (63185 + 3), hl		; Hyp.cls 2053
            ld a, (var_hyp_ra)		; Hyp.cls 2054
            ld (63185 + 1), a		; Hyp.cls 2055
            jp 65488		; Hyp.cls 2056
; msx_recv: task -> hyp, from the bank's sb_hout (pages 0-2 already the hypervisor's, A and its
; carry in AF'): page 3 back, the hypervisor's SP, ret to rn_back. DE, HL, IX as the task left them
@msx_recv:		; Hyp.cls 2059
            ld a, (msx_tpa + 3)		; Hyp.cls 2060
            out (#FF), a		; Hyp.cls 2061
            db #08		; Hyp.cls 2062
            ld sp, (ntc_bk_sp)		; Hyp.cls 2063
            ret		; Hyp.cls 2064
@ntc_bk_sp: dw 0                                ; the hypervisor's SP while a task runs [2065]
    ELSE		; Hyp.cls 2066
            jp ntc_bk_out           ; out (c), c: the task's bank; its #0046 lands it [2067]
    ENDIF		; Hyp.cls 2068
asm_1_2008_n_rn_back:		; Hyp.cls 2069
            ld (var_hyp_rcnt), ix         ; the characters it collected (the stubs put them in IX) [2070]
            db #08                  ; ex af, af' [2071]
            exx		; Hyp.cls 2072
            pop hl                  ; the alternate registers back [2073]
            pop de		; Hyp.cls 2074
            pop bc		; Hyp.cls 2075
            pop af		; Hyp.cls 2076
            exx		; Hyp.cls 2077
            db #08		; Hyp.cls 2078
            pop iy		; Hyp.cls 2079
            pop ix		; Hyp.cls 2080
            push af                 ; carry: a BDOS call (A = C, DE = DE) [2081]
            push bc		; Hyp.cls 2082
            ld bc, (ntc_rampt)      ; the window's page back [2083]
    IFDEF NTC_MSXDOS		; Hyp.cls 2084
            call msx_win		; Hyp.cls 2085
    ELSE		; Hyp.cls 2086
            out (c), c		; Hyp.cls 2087
    ENDIF		; Hyp.cls 2088
            pop bc		; Hyp.cls 2089
            pop af		; Hyp.cls 2090
            jr c, asm_1_2008_n_rn_far		; Hyp.cls 2091
            rst #38                 ; an interrupt stopped the task: the firmware's handler [2092]
            di		; Hyp.cls 2093
            ld hl, var_hyp_slc            ; a time slice is SLICE interrupts: until it is used up the [2094]
            dec (hl)                ; task carries on straight away (no trip through BASIC) [2095]
            jr z, asm_1_2008_n_rn_int		; Hyp.cls 2096
            ld a, (ntc_isldue)      ; ... unless an interrupt class (the system keys) is due [2097]
            or a		; Hyp.cls 2098
            jr nz, asm_1_2008_n_rn_int		; Hyp.cls 2099
            xor a                   ; its characters stay in its bank (and the count goes on) [2100]
            ld (var_hyp_rclr), a		; Hyp.cls 2101
            jp asm_1_2008_n_rn_again		; Hyp.cls 2102
asm_1_2008_n_rn_int:		; Hyp.cls 2103
            ld hl, 0		; Hyp.cls 2104
            jr asm_1_2008_n_rn_end		; Hyp.cls 2105
asm_1_2008_n_rn_far:		; Hyp.cls 2106
            ld (var_hyp_rfn), a		; Hyp.cls 2107
            ld (var_hyp_rde), de		; Hyp.cls 2108
            ld hl, 1		; Hyp.cls 2109
asm_1_2008_n_rn_end:		; Hyp.cls 2110
            ld (var_hyp_run_run), hl		; Hyp.cls 2111
            ld a, (var_hyp_rrom)		; Hyp.cls 2112
    IFNDEF NTC_MSXDOS		; Hyp.cls 2113
            call #B90C              ; KL ROM RESTORE [2114]
    ENDIF		; Hyp.cls 2115
            di		; Hyp.cls 2116
            ld sp, (var_hyp_sps)		; Hyp.cls 2117

			ret			; end of #asm

asm_1_2125_n:		; #asm, Hyp.cls line 2125 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 2126
            ld sp, (ntc_csp)		; Hyp.cls 2127
            call msx_t300		; Hyp.cls 2128
            ld (var_hyp_t300_t300), hl		; Hyp.cls 2129
            ld sp, (var_hyp_hsp)		; Hyp.cls 2130
			ret			; end of #asm

fn_hyp_seg:		; function seg (asm keyword), Hyp.cls line 2137
            pop hl		; Hyp.cls 2138
            ld c, (hl)		; Hyp.cls 2139
            inc hl		; Hyp.cls 2140
            ld b, (hl)		; Hyp.cls 2141
            ld a, b		; Hyp.cls 2142
            or a		; Hyp.cls 2143
            jr nz, fn_hyp_seg_sg_bank		; Hyp.cls 2144
            ld a, c		; Hyp.cls 2145
            cp 4		; Hyp.cls 2146
            jr nc, fn_hyp_seg_sg_bank		; Hyp.cls 2147
            ld e, a		; Hyp.cls 2148
            ld d, 0		; Hyp.cls 2149
            ld hl, msx_tpa		; Hyp.cls 2150
            add hl, de		; Hyp.cls 2151
            ld a, (hl)		; Hyp.cls 2152
            jr fn_hyp_seg_sg_e		; Hyp.cls 2153
fn_hyp_seg_sg_bank:		; Hyp.cls 2154
            ld (var_hyp_hsp), sp          ; (the real stack for the call: SP is the thread) [2155]
            ld sp, (ntc_csp)		; Hyp.cls 2156
            call msx_mem_bank		; Hyp.cls 2157
            ld sp, (var_hyp_hsp)		; Hyp.cls 2158
fn_hyp_seg_sg_e:		; Hyp.cls 2159
            pop hl		; Hyp.cls 2160
            ld (hl), a		; Hyp.cls 2161
            inc hl		; Hyp.cls 2162
            ld (hl), 0		; Hyp.cls 2163
            ret		; Hyp.cls 2164
			ret			; end of #asm

fn_hyp_info:		; function info (asm keyword), Hyp.cls line 2174
            pop hl		; Hyp.cls 2175
            ld a, (hl)		; Hyp.cls 2176
            ld hl, fn_hyp_info_hi_p0		; Hyp.cls 2177
            or a		; Hyp.cls 2178
            jr z, fn_hyp_info_in_e		; Hyp.cls 2179
            ld hl, fn_hyp_info_hi_p0e - fn_hyp_info_hi_p0		; Hyp.cls 2180
            dec a		; Hyp.cls 2181
            jr z, fn_hyp_info_in_e		; Hyp.cls 2182
            ld hl, fn_hyp_info_sb_img		; Hyp.cls 2183
            dec a		; Hyp.cls 2184
            jr z, fn_hyp_info_in_e		; Hyp.cls 2185
            ld hl, fn_hyp_info_sb_end - fn_hyp_info_sb_start		; Hyp.cls 2186
            dec a		; Hyp.cls 2187
            jr z, fn_hyp_info_in_e		; Hyp.cls 2188
            ld hl, fn_hyp_info_sb_init		; Hyp.cls 2189
    IFDEF NTC_MSXDOS		; Hyp.cls 2190
            dec a		; Hyp.cls 2191
            jr z, fn_hyp_info_in_e		; Hyp.cls 2192
            ld hl, fn_hyp_info_hi_sw                        ; 5: the switch-back receiver's source (window image) [2193]
            dec a		; Hyp.cls 2194
            jr z, fn_hyp_info_in_e		; Hyp.cls 2195
            ld hl, fn_hyp_info_hi_swe - fn_hyp_info_hi_sw               ; 6: its length (copied below #FFFE: HISW) [2196]
    ENDIF		; Hyp.cls 2197
fn_hyp_info_in_e:		; Hyp.cls 2198
            ex de, hl		; Hyp.cls 2199
            pop hl		; Hyp.cls 2200
            ld (hl), e		; Hyp.cls 2201
            inc hl		; Hyp.cls 2202
            ld (hl), d		; Hyp.cls 2203
            ret		; Hyp.cls 2204

			ret			; end of #asm

asm_1_3760_n:		; #asm, Hyp.cls line 3760 (normal)
    IFDEF NTC_MSXDOS		; Hyp.cls 3761
            ld a, (var_hyp_vdu_on)            ; MSX: Vdu 1 - the DOS's screen back (the BIOS's INITXT through [3762]
            or a                    ; CALSLT, R#23 0 first: the BIOS doesn't know of the scroll); [3763]
            jr z, asm_1_3760_n_vd_msx            ; Vdu 0 - nothing (CyborgOS's screen is set at the start) [3764]
            ld (var_hyp_hsp), sp		; Hyp.cls 3765
            ld sp, (ntc_csp)		; Hyp.cls 3766
            push ix		; Hyp.cls 3767
            push iy		; Hyp.cls 3768
            xor a		; Hyp.cls 3769
            out (#99), a		; Hyp.cls 3770
            ld a, #80 + 23		; Hyp.cls 3771
            out (#99), a		; Hyp.cls 3772
            ld a, (#FCC1)           ; EXPTBL: the main ROM's slot [3773]
            ld iyh, a		; Hyp.cls 3774
            ld ix, #006C            ; INITXT [3775]
            call #001C              ; CALSLT [3776]
            di		; Hyp.cls 3777
            ld bc, #7FC0            ; the program's own page 1 in the window again (MSX-DOS 2 frees [3778]
            call msx_win            ; the segments it gave at the end: none of them left in a page) [3779]
            pop iy		; Hyp.cls 3780
            pop ix		; Hyp.cls 3781
            ld sp, (var_hyp_hsp)		; Hyp.cls 3782
asm_1_3760_n_vd_msx:		; Hyp.cls 3783
    ELSE		; Hyp.cls 3784
            ld (var_hyp_hsp), sp		; Hyp.cls 3785
            ld sp, (ntc_csp)		; Hyp.cls 3786
            ld a, (var_hyp_vdu_on)		; Hyp.cls 3787
            or a		; Hyp.cls 3788
            jr z, asm_1_3760_n_vd_off		; Hyp.cls 3789
            call #BB54              ; TXT VDU ENABLE [3790]
            jr asm_1_3760_n_vd_done		; Hyp.cls 3791
asm_1_3760_n_vd_off:		; Hyp.cls 3792
            call #BB57              ; TXT VDU DISABLE [3793]
asm_1_3760_n_vd_done:		; Hyp.cls 3794
            di		; Hyp.cls 3795
            ld sp, (var_hyp_hsp)		; Hyp.cls 3796
    ENDIF		; Hyp.cls 3797
			ret			; end of #asm

asm_1_3817_n:		; #asm, Hyp.cls line 3817 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 3818
            ld sp, (ntc_csp)		; Hyp.cls 3819
            ld (asm_1_3817_n_fl_ix), ix		; Hyp.cls 3820
            ld (asm_1_3817_n_fl_iy), iy		; Hyp.cls 3821
            ld a, 255		; Hyp.cls 3822
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 3823
            ld a, (var_hyp_filecall_slot)		; Hyp.cls 3824
            ld (asm_1_3817_n_fl_slot), a		; Hyp.cls 3825
            ld a, (var_hyp_filecall_f)		; Hyp.cls 3826
            cp 99		; Hyp.cls 3827
            jp z, asm_1_3817_n_fl_inst		; Hyp.cls 3828
            IF NTC_ROMLIB = 0		; Hyp.cls 3829
; the RAM discs' driver (RAMDISC.CYB's, in a page of its own at #4000) sees the call first:
; carry - it was one of its drives' (HL the answer), else on to the disc ROM. It gets IX = the
; call (f, fcb, slot, setting, dma, drive, buf; 100-105: drive = the hypervisor's drive), at
; #4003 a jump to fl_dx (its copies: it runs in the window, so can't switch it itself), at
; #4006 its page's RAM setting
            ASSERT var_hyp_filecall_buf - var_hyp_filecall_f = 12, "FileCall's parameters, one after another"		; Hyp.cls 3835
            ld a, (var_hyp_drs + 1)		; Hyp.cls 3836
            or a		; Hyp.cls 3837
            jr z, asm_1_3817_n_fl_nodrv		; Hyp.cls 3838
            di		; Hyp.cls 3839
            ld a, (var_hyp_filecall_f)		; Hyp.cls 3840
            cp 100		; Hyp.cls 3841
            jr c, asm_1_3817_n_fl_dr_go		; Hyp.cls 3842
            cp 106		; Hyp.cls 3843
            jr nc, asm_1_3817_n_fl_dr_go		; Hyp.cls 3844
            ld hl, (var_hyp_hdr)		; Hyp.cls 3845
            ld (var_hyp_filecall_drive), hl		; Hyp.cls 3846
asm_1_3817_n_fl_dr_go:		; Hyp.cls 3847
            ld bc, (var_hyp_drs)		; Hyp.cls 3848
    IFDEF NTC_MSXDOS		; Hyp.cls 3849
            call msx_win		; Hyp.cls 3850
    ELSE		; Hyp.cls 3851
            out (c), c		; Hyp.cls 3852
    ENDIF		; Hyp.cls 3853
            ld hl, asm_1_3817_n_fl_dx		; Hyp.cls 3854
            ld (#4004), hl		; Hyp.cls 3855
            ld hl, (var_hyp_drs)		; Hyp.cls 3856
            ld (#4006), hl		; Hyp.cls 3857
            ld ix, var_hyp_filecall_f		; Hyp.cls 3858
            call #4000		; Hyp.cls 3859
            jr nc, asm_1_3817_n_fl_nodrv		; Hyp.cls 3860
            ld (asm_1_3817_n_fl_res16), hl		; Hyp.cls 3861
            ld a, 1		; Hyp.cls 3862
            ld (asm_1_3817_n_fl_r16), a		; Hyp.cls 3863
            jp asm_1_3817_n_fl_done		; Hyp.cls 3864
; fl_dx - A bytes (1-128) from HL to DE through dxb: IX = HL's RAM setting, IY = DE's (0:
; main RAM, no switch); the driver's page back in the window after. HL, DE on past them
asm_1_3817_n_fl_dx:		; Hyp.cls 3867
            ld (asm_1_3817_n_fl_dxn), a		; Hyp.cls 3868
            push de		; Hyp.cls 3869
            ld de, (var_hyp_dxb)		; Hyp.cls 3870
            push ix		; Hyp.cls 3871
            pop bc		; Hyp.cls 3872
            inc b		; Hyp.cls 3873
            dec b		; Hyp.cls 3874
            jr z, asm_1_3817_n_fl_dx1		; Hyp.cls 3875
    IFDEF NTC_MSXDOS		; Hyp.cls 3876
            call msx_win		; Hyp.cls 3877
    ELSE		; Hyp.cls 3878
            out (c), c		; Hyp.cls 3879
    ENDIF		; Hyp.cls 3880
asm_1_3817_n_fl_dx1:		; Hyp.cls 3881
            ld c, a		; Hyp.cls 3882
            ld b, 0		; Hyp.cls 3883
            ldir		; Hyp.cls 3884
            pop de		; Hyp.cls 3885
            push hl		; Hyp.cls 3886
            push iy		; Hyp.cls 3887
            pop bc		; Hyp.cls 3888
            inc b		; Hyp.cls 3889
            dec b		; Hyp.cls 3890
            jr z, asm_1_3817_n_fl_dx2		; Hyp.cls 3891
    IFDEF NTC_MSXDOS		; Hyp.cls 3892
            call msx_win		; Hyp.cls 3893
    ELSE		; Hyp.cls 3894
            out (c), c		; Hyp.cls 3895
    ENDIF		; Hyp.cls 3896
asm_1_3817_n_fl_dx2:		; Hyp.cls 3897
            ld hl, (var_hyp_dxb)		; Hyp.cls 3898
            ld a, (asm_1_3817_n_fl_dxn)		; Hyp.cls 3899
            ld c, a		; Hyp.cls 3900
            ld b, 0		; Hyp.cls 3901
            ldir		; Hyp.cls 3902
            pop hl		; Hyp.cls 3903
            ld bc, (var_hyp_drs)		; Hyp.cls 3904
    IFDEF NTC_MSXDOS		; Hyp.cls 3905
            call msx_win		; Hyp.cls 3906
    ELSE		; Hyp.cls 3907
            out (c), c		; Hyp.cls 3908
    ENDIF		; Hyp.cls 3909
            ret		; Hyp.cls 3910
asm_1_3817_n_fl_dxn:     db 0		; Hyp.cls 3911
asm_1_3817_n_fl_nodrv:		; Hyp.cls 3912
            ENDIF		; Hyp.cls 3913
            di		; Hyp.cls 3914
            ld bc, (var_hyp_hps)          ; the rest runs in the hypervisor's page (window data from [3915]
    IFDEF NTC_MSXDOS		; Hyp.cls 3916
            call msx_win  ; #5300: fp_go) [3917]
    ELSE		; Hyp.cls 3918
            out (c), c  ; #5300: fp_go) [3919]
    ENDIF		; Hyp.cls 3920
            call asm_1_3817_n_fp_go		; Hyp.cls 3921
            jp asm_1_3817_n_fl_done		; Hyp.cls 3922
; 99: the window data (#5300 to fp_end: the bank image, the page code) copied from main RAM's
; own #4000-#7FFF (where the file put it) into the hypervisor's page, through buf; once, at the
; start, before anything else uses main RAM's #4000-#7FFF
asm_1_3817_n_fl_inst:		; Hyp.cls 3926
    IFDEF NTC_MSXDOS		; Hyp.cls 3927
            ld hl, #4000            ; (zxn: the SD card's code is there) [3928]
    ELSE		; Hyp.cls 3929
            ld hl, #5300		; Hyp.cls 3930
    ENDIF		; Hyp.cls 3931
asm_1_3817_n_fl_in_lp:		; Hyp.cls 3932
            push hl		; Hyp.cls 3933
            ld bc, #7FC0            ; main RAM's own (zxn: bank 9 = the hypervisor's own pages 18, 19, holding the loaded image) [3934]
    IFDEF NTC_MSXDOS		; Hyp.cls 3935
            call asm_1_3817_n_fl_zxn_map		; Hyp.cls 3936
    ELSE		; Hyp.cls 3937
            out (c), c		; Hyp.cls 3938
    ENDIF		; Hyp.cls 3939
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3940
            ld bc, 128		; Hyp.cls 3941
            ldir		; Hyp.cls 3942
            ld bc, (var_hyp_hps)		; Hyp.cls 3943
    IFDEF NTC_MSXDOS		; Hyp.cls 3944
            call asm_1_3817_n_fl_zxn_map		; Hyp.cls 3945
    ELSE		; Hyp.cls 3946
            out (c), c		; Hyp.cls 3947
    ENDIF		; Hyp.cls 3948
            pop de		; Hyp.cls 3949
            push de		; Hyp.cls 3950
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3951
            ld bc, 128		; Hyp.cls 3952
            ldir		; Hyp.cls 3953
            pop hl		; Hyp.cls 3954
            ld bc, 128		; Hyp.cls 3955
            add hl, bc		; Hyp.cls 3956
            ld de, asm_1_3817_n_fp_end		; Hyp.cls 3957
            or a		; Hyp.cls 3958
            sbc hl, de		; Hyp.cls 3959
            add hl, de		; Hyp.cls 3960
            jr c, asm_1_3817_n_fl_in_lp		; Hyp.cls 3961
            xor a		; Hyp.cls 3962
            ld (asm_1_3817_n_fl_res), a		; Hyp.cls 3963
    IFDEF NTC_MSXDOS		; Hyp.cls 3964
            ld hl, var_hyp_filecall_f              ; (the SD card: its drive set up, with where these are; then fl_done) [3965]
            ld de, var_hyp_fin		; Hyp.cls 3966
            ld bc, var_hyp_fout		; Hyp.cls 3967
            jp sd_h_init		; Hyp.cls 3968
    ELSE		; Hyp.cls 3969
            jp asm_1_3817_n_fl_done		; Hyp.cls 3970
    ENDIF		; Hyp.cls 3971
    IFDEF NTC_MSXDOS		; Hyp.cls 3972
; fl_zxn_map - BC = a RAM setting -> its 16K bank into the window (slots 2, 3) via the MMU
; (msx_win), noted in ntc_rampt as the Memory class's mem_se_out notes its. Keeps every register
asm_1_3817_n_fl_zxn_map:		; Hyp.cls 3975
            ld (ntc_rampt), bc		; Hyp.cls 3976
            jp msx_win		; Hyp.cls 3977
    ENDIF		; Hyp.cls 3978
; ---- what the page code can't do itself (it runs in the window): switch the window to a slot's
; page and back. Each puts the hypervisor's page back in the window
asm_1_3817_n_fl_sel:                             ; the slot's page holding HL in the window: HL = there [3981]
            push de		; Hyp.cls 3982
            ld a, h		; Hyp.cls 3983
            rlca		; Hyp.cls 3984
            rlca		; Hyp.cls 3985
            and 3		; Hyp.cls 3986
            add a, 4		; Hyp.cls 3987
            ld e, a		; Hyp.cls 3988
            ld bc, (var_hyp_filecall_setting)		; Hyp.cls 3989
            ld a, c		; Hyp.cls 3990
            and #F8		; Hyp.cls 3991
            or e		; Hyp.cls 3992
            ld c, a		; Hyp.cls 3993
    IFDEF NTC_MSXDOS		; Hyp.cls 3994
            call msx_win		; Hyp.cls 3995
    ELSE		; Hyp.cls 3996
            out (c), c		; Hyp.cls 3997
    ENDIF		; Hyp.cls 3998
            ld a, h		; Hyp.cls 3999
            and #3F		; Hyp.cls 4000
            or #40		; Hyp.cls 4001
            ld h, a		; Hyp.cls 4002
            pop de		; Hyp.cls 4003
            ret		; Hyp.cls 4004
asm_1_3817_n_fl_peek:                            ; A = the slot's byte at HL (BC, DE, HL kept) [4005]
            push bc		; Hyp.cls 4006
            push hl		; Hyp.cls 4007
            call asm_1_3817_n_fl_sel		; Hyp.cls 4008
            ld a, (hl)		; Hyp.cls 4009
asm_1_3817_n_fl_pk_back:		; Hyp.cls 4010
            ld bc, (var_hyp_hps)		; Hyp.cls 4011
    IFDEF NTC_MSXDOS		; Hyp.cls 4012
            call msx_win		; Hyp.cls 4013
    ELSE		; Hyp.cls 4014
            out (c), c		; Hyp.cls 4015
    ENDIF		; Hyp.cls 4016
            pop hl		; Hyp.cls 4017
            pop bc		; Hyp.cls 4018
            ret		; Hyp.cls 4019
asm_1_3817_n_fl_poke:                            ; the slot's byte at HL = A (BC, DE, HL kept) [4020]
            push bc		; Hyp.cls 4021
            push hl		; Hyp.cls 4022
            push af		; Hyp.cls 4023
            call asm_1_3817_n_fl_sel		; Hyp.cls 4024
            pop af		; Hyp.cls 4025
            ld (hl), a		; Hyp.cls 4026
            jr asm_1_3817_n_fl_pk_back		; Hyp.cls 4027
asm_1_3817_n_fl_toslot:                          ; BC bytes from DE (main RAM) to the slot's HL (all in one of [4028]
            push bc                 ; its pages: fl_fits) [4029]
            call asm_1_3817_n_fl_sel		; Hyp.cls 4030
            pop bc		; Hyp.cls 4031
            ex de, hl		; Hyp.cls 4032
            ldir		; Hyp.cls 4033
            jr asm_1_3817_n_fl_blk_back		; Hyp.cls 4034
asm_1_3817_n_fl_fromslot:                        ; BC bytes from the slot's HL (in one page) to DE (main RAM) [4035]
            push bc		; Hyp.cls 4036
            call asm_1_3817_n_fl_sel		; Hyp.cls 4037
            pop bc		; Hyp.cls 4038
            ldir		; Hyp.cls 4039
asm_1_3817_n_fl_blk_back:		; Hyp.cls 4040
            ld bc, (var_hyp_hps)		; Hyp.cls 4041
    IFDEF NTC_MSXDOS		; Hyp.cls 4042
            call msx_win		; Hyp.cls 4043
    ELSE		; Hyp.cls 4044
            out (c), c		; Hyp.cls 4045
    ENDIF		; Hyp.cls 4046
            ret		; Hyp.cls 4047
asm_1_3817_n_fl_done:		; Hyp.cls 4048
            di		; Hyp.cls 4049
            ld bc, (ntc_rampt)      ; the page that was in the window back [4050]
    IFDEF NTC_MSXDOS		; Hyp.cls 4051
            call msx_win		; Hyp.cls 4052
    ELSE		; Hyp.cls 4053
            out (c), c		; Hyp.cls 4054
    ENDIF		; Hyp.cls 4055
            ld a, (asm_1_3817_n_fl_res)		; Hyp.cls 4056
            ld l, a		; Hyp.cls 4057
            ld h, 0		; Hyp.cls 4058
            ld a, (asm_1_3817_n_fl_r16)		; Hyp.cls 4059
            or a		; Hyp.cls 4060
            jr z, asm_1_3817_n_fl_d8		; Hyp.cls 4061
            ld hl, (asm_1_3817_n_fl_res16)		; Hyp.cls 4062
            xor a		; Hyp.cls 4063
            ld (asm_1_3817_n_fl_r16), a		; Hyp.cls 4064
asm_1_3817_n_fl_d8:		; Hyp.cls 4065
            ld (var_hyp_filecall_filecall), hl		; Hyp.cls 4066
            ld ix, (asm_1_3817_n_fl_ix)		; Hyp.cls 4067
            ld iy, (asm_1_3817_n_fl_iy)		; Hyp.cls 4068
            ld sp, (var_hyp_hsp)		; Hyp.cls 4069
            jp asm_1_3817_n_fl_exit		; Hyp.cls 4070
asm_1_3817_n_fl_ix:      dw 0		; Hyp.cls 4071
asm_1_3817_n_fl_iy:      dw 0		; Hyp.cls 4072
asm_1_3817_n_fl_res:     db 0		; Hyp.cls 4073
asm_1_3817_n_fl_r16:     db 0                    ; 1: the result is fl_res16 [4074]
asm_1_3817_n_fl_res16:   dw 0		; Hyp.cls 4075
asm_1_3817_n_fl_slot:    db 0		; Hyp.cls 4076
; (main RAM: the page code calls them - no room left in the page)
asm_1_3817_n_fl_isin:                            ; Z: the file being read is this slot's, this FCB [4078]
            ld a, (var_hyp_fin)		; Hyp.cls 4079
            ld hl, asm_1_3817_n_fl_infcb		; Hyp.cls 4080
            jr asm_1_3817_n_fl_is		; Hyp.cls 4081
asm_1_3817_n_fl_isout:		; Hyp.cls 4082
            ld a, (var_hyp_fout)		; Hyp.cls 4083
            ld hl, asm_1_3817_n_fl_outfcb		; Hyp.cls 4084
asm_1_3817_n_fl_is:                              ; (its FCB: the one it was opened with - or, the first [4085]
            ld b, a                 ; call after with another, that one: a program's own copy [4086]
            ld a, (asm_1_3817_n_fl_slot)         ; of it, BBC BASIC's channels) [4087]
            cp b		; Hyp.cls 4088
            ret nz		; Hyp.cls 4089
            ld e, (hl)		; Hyp.cls 4090
            inc hl		; Hyp.cls 4091
            ld d, (hl)		; Hyp.cls 4092
            inc hl		; Hyp.cls 4093
            push hl		; Hyp.cls 4094
            call asm_1_3817_n_fl_cmpf		; Hyp.cls 4095
            pop de		; Hyp.cls 4096
            ret z		; Hyp.cls 4097
            ld a, (de)              ; (the open's FCB still: this one from now on - unless it [4098]
            xor 1                   ; is the other file's: a program reading the record it [4099]
            ret nz                  ; writes, through that file's FCB) [4100]
            push de		; Hyp.cls 4101
            ld a, (var_hyp_fin)		; Hyp.cls 4102
            ld de, (asm_1_3817_n_fl_infcb)		; Hyp.cls 4103
            call asm_1_3817_n_fl_oth		; Hyp.cls 4104
            jr z, asm_1_3817_n_fl_is_no		; Hyp.cls 4105
            ld a, (var_hyp_fout)		; Hyp.cls 4106
            ld de, (asm_1_3817_n_fl_outfcb)		; Hyp.cls 4107
            call asm_1_3817_n_fl_oth		; Hyp.cls 4108
asm_1_3817_n_fl_is_no:		; Hyp.cls 4109
            pop de		; Hyp.cls 4110
            jr nz, asm_1_3817_n_fl_is_re		; Hyp.cls 4111
            inc a                   ; (NZ: not this one) [4112]
            ret		; Hyp.cls 4113
asm_1_3817_n_fl_is_re:		; Hyp.cls 4114
            xor a		; Hyp.cls 4115
            ld (de), a		; Hyp.cls 4116
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4117
            ex de, hl		; Hyp.cls 4118
            dec hl		; Hyp.cls 4119
            ld (hl), d		; Hyp.cls 4120
            dec hl		; Hyp.cls 4121
            ld (hl), e		; Hyp.cls 4122
            ret		; Hyp.cls 4123
asm_1_3817_n_fl_oth:                             ; Z: the slot's file (A: fin / fout), its FCB DE the call's [4124]
            ld b, a		; Hyp.cls 4125
            ld a, (asm_1_3817_n_fl_slot)		; Hyp.cls 4126
            cp b		; Hyp.cls 4127
            ret nz		; Hyp.cls 4128
asm_1_3817_n_fl_cmpf:                            ; Z: the call's FCB is DE [4129]
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4130
            or a		; Hyp.cls 4131
            sbc hl, de		; Hyp.cls 4132
            ret		; Hyp.cls 4133
    IFDEF NTC_MSXDOS		; Hyp.cls 4134
; ---- zxn: the boot archive is the drive here - the NEX's data banks (Option NexData in Main.bas,
; made by tools/nexarc/nexarc.py): block 0 the directory ("CARC", the entries as a word at 4, then
; from 16 an entry of 16 bytes each: the name 8 + 3, the length 3 bytes, the first record 2 bytes -
; 128 byte records from the archive's start), then the files. Read only, as the CPC's CAS IN:
; a file opened by name, read a record at a time. A record's page is mapped into slot 6 (#C000-
; #DFFF: page 10 there otherwise, nothing of the hypervisor's) while it is copied. In main RAM (not
; the window data: the page code calls it here - room below #6000 there)
asm_1_3817_n_fl_aopen:   db 0                    ; 1: a file is open [4142]
asm_1_3817_n_fl_arec:    dw 0                    ; its record being read (from the archive's start) [4143]
asm_1_3817_n_fl_aoff:    db 0                    ; where in that record the next byte is (0-127) [4144]
asm_1_3817_n_fl_aleft:   dw 0                    ; bytes left in it (65535 at most: a file is read to its end) [4145]
asm_1_3817_n_fl_aname:   ds 11                   ; the name looked for, 8 + 3 (spaces, capitals) [4146]
; fl_arc_pg - HL = a record number: its page into slot 6, HL = the record's address there (#C000-
; #DF80). Keeps BC, DE
asm_1_3817_n_fl_arc_pg:                          ; MSX: no boot archive - an empty directory (no entries) [4149]
            ld hl, asm_1_3817_n_fl_arc_none		; Hyp.cls 4150
            ret		; Hyp.cls 4151
asm_1_3817_n_fl_arc_none: ds 8		; Hyp.cls 4152
asm_1_3817_n_fl_arc_off:		; Hyp.cls 4153
            ret		; Hyp.cls 4154
; fl_arc_nm - fl_aname = fl_name_s's NAME.EXT as 8 + 3 (a drive "X:" in front skipped; no paths)
asm_1_3817_n_fl_arc_nm:		; Hyp.cls 4156
            ld hl, asm_1_3817_n_fl_aname		; Hyp.cls 4157
            ld b, 11		; Hyp.cls 4158
asm_1_3817_n_fl_an_sp:		; Hyp.cls 4159
            ld (hl), ' '		; Hyp.cls 4160
            inc hl		; Hyp.cls 4161
            djnz asm_1_3817_n_fl_an_sp		; Hyp.cls 4162
            ld hl, asm_1_3817_n_fl_name_s		; Hyp.cls 4163
            ld a, (hl)		; Hyp.cls 4164
            or a		; Hyp.cls 4165
            ret z		; Hyp.cls 4166
            ld b, a		; Hyp.cls 4167
            inc hl		; Hyp.cls 4168
            ld a, b		; Hyp.cls 4169
            cp 2		; Hyp.cls 4170
            jr c, asm_1_3817_n_fl_an_go		; Hyp.cls 4171
            inc hl		; Hyp.cls 4172
            ld a, (hl)		; Hyp.cls 4173
            dec hl		; Hyp.cls 4174
            cp ':'		; Hyp.cls 4175
            jr nz, asm_1_3817_n_fl_an_go		; Hyp.cls 4176
            inc hl                  ; "X:" skipped [4177]
            inc hl		; Hyp.cls 4178
            dec b		; Hyp.cls 4179
            dec b		; Hyp.cls 4180
            ret z		; Hyp.cls 4181
asm_1_3817_n_fl_an_go:		; Hyp.cls 4182
            ld de, asm_1_3817_n_fl_aname		; Hyp.cls 4183
            ld c, 8                 ; characters left in this part [4184]
asm_1_3817_n_fl_an_lp:		; Hyp.cls 4185
            ld a, (hl)		; Hyp.cls 4186
            inc hl		; Hyp.cls 4187
            cp '.'		; Hyp.cls 4188
            jr nz, asm_1_3817_n_fl_an_c		; Hyp.cls 4189
            ld de, asm_1_3817_n_fl_aname + 8     ; the extension [4190]
            ld c, 3		; Hyp.cls 4191
            jr asm_1_3817_n_fl_an_nx		; Hyp.cls 4192
asm_1_3817_n_fl_an_c:                            ; (capitals already: an FCB's, or Main's command line) [4193]
            inc c		; Hyp.cls 4194
            dec c		; Hyp.cls 4195
            jr z, asm_1_3817_n_fl_an_nx          ; (a part longer than its 8 / 3: the rest dropped) [4196]
            ld (de), a		; Hyp.cls 4197
            inc de		; Hyp.cls 4198
            dec c		; Hyp.cls 4199
asm_1_3817_n_fl_an_nx:		; Hyp.cls 4200
            djnz asm_1_3817_n_fl_an_lp		; Hyp.cls 4201
            ret		; Hyp.cls 4202
; (fl_inopen, fl_rdrec, fl_inclose are the SD card's sd_h_* here, which come to these - the
; archive's - for a name with no path)
asm_1_3817_n_fl_inopen: EQU sd_h_inopen		; Hyp.cls 4205
asm_1_3817_n_fl_rdrec: EQU sd_h_rdrec		; Hyp.cls 4206
asm_1_3817_n_fl_inclose: EQU sd_h_inclose		; Hyp.cls 4207
asm_1_3817_n_fl_inopen_a:                        ; open fl_name_s to read: carry = done [4208]
            call asm_1_3817_n_fl_arc_nm		; Hyp.cls 4209
            ld hl, 0		; Hyp.cls 4210
            call asm_1_3817_n_fl_arc_pg          ; the directory: HL = #C000 [4211]
            ld de, 4		; Hyp.cls 4212
            add hl, de		; Hyp.cls 4213
            ld e, (hl)		; Hyp.cls 4214
            inc hl		; Hyp.cls 4215
            ld d, (hl)              ; DE = the entries [4216]
            ld bc, 0                ; BC = this entry [4217]
asm_1_3817_n_fl_ao_lp:		; Hyp.cls 4218
            ld a, c		; Hyp.cls 4219
            cp e		; Hyp.cls 4220
            ld a, b		; Hyp.cls 4221
            sbc a, d		; Hyp.cls 4222
            jr nc, asm_1_3817_n_fl_ao_no         ; (BC = DE: all seen) [4223]
            push bc		; Hyp.cls 4224
            push de		; Hyp.cls 4225
            inc bc                  ; the entry's record: (16 + 16 * n) / 128 = (n + 1) / 8 [4226]
            ld h, b		; Hyp.cls 4227
            ld l, c		; Hyp.cls 4228
            srl h		; Hyp.cls 4229
            rr l		; Hyp.cls 4230
            srl h		; Hyp.cls 4231
            rr l		; Hyp.cls 4232
            srl h		; Hyp.cls 4233
            rr l		; Hyp.cls 4234
            call asm_1_3817_n_fl_arc_pg		; Hyp.cls 4235
            ld a, c                 ; in it: ((n + 1) and 7) * 16 [4236]
            and 7		; Hyp.cls 4237
            add a, a		; Hyp.cls 4238
            add a, a		; Hyp.cls 4239
            add a, a		; Hyp.cls 4240
            add a, a		; Hyp.cls 4241
            add a, l		; Hyp.cls 4242
            ld l, a		; Hyp.cls 4243
            ld de, asm_1_3817_n_fl_aname		; Hyp.cls 4244
            ld b, 11		; Hyp.cls 4245
asm_1_3817_n_fl_ao_cmp:		; Hyp.cls 4246
            ld a, (de)		; Hyp.cls 4247
            cp (hl)		; Hyp.cls 4248
            jr nz, asm_1_3817_n_fl_ao_nx		; Hyp.cls 4249
            inc hl		; Hyp.cls 4250
            inc de		; Hyp.cls 4251
            djnz asm_1_3817_n_fl_ao_cmp		; Hyp.cls 4252
            ld e, (hl)              ; found: the length (its third byte: 65535 at most here) [4253]
            inc hl		; Hyp.cls 4254
            ld d, (hl)		; Hyp.cls 4255
            inc hl		; Hyp.cls 4256
            ld a, (hl)		; Hyp.cls 4257
            inc hl		; Hyp.cls 4258
            or a		; Hyp.cls 4259
            jr z, asm_1_3817_n_fl_ao_ln		; Hyp.cls 4260
            ld de, 65535		; Hyp.cls 4261
asm_1_3817_n_fl_ao_ln:		; Hyp.cls 4262
            ld (asm_1_3817_n_fl_aleft), de		; Hyp.cls 4263
            ld e, (hl)		; Hyp.cls 4264
            inc hl		; Hyp.cls 4265
            ld d, (hl)		; Hyp.cls 4266
            ld (asm_1_3817_n_fl_arec), de        ; its first record [4267]
            xor a		; Hyp.cls 4268
            ld (asm_1_3817_n_fl_aoff), a		; Hyp.cls 4269
            inc a		; Hyp.cls 4270
            ld (asm_1_3817_n_fl_aopen), a		; Hyp.cls 4271
            pop de		; Hyp.cls 4272
            pop bc		; Hyp.cls 4273
            call asm_1_3817_n_fl_arc_off         ; (fl_hdr not set: BDOS 30 #C7 isn't answered here) [4274]
            call sd_h_ahdr          ; an AMSDOS header read past (as AMSDOS does on the CPC) [4275]
            scf		; Hyp.cls 4276
            ret		; Hyp.cls 4277
asm_1_3817_n_fl_ao_nx:		; Hyp.cls 4278
            pop de		; Hyp.cls 4279
            pop bc		; Hyp.cls 4280
            inc bc		; Hyp.cls 4281
            jr asm_1_3817_n_fl_ao_lp		; Hyp.cls 4282
asm_1_3817_n_fl_ao_no:		; Hyp.cls 4283
            call asm_1_3817_n_fl_arc_off		; Hyp.cls 4284
            or a		; Hyp.cls 4285
            ret		; Hyp.cls 4286
asm_1_3817_n_fl_inclose_a:		; Hyp.cls 4287
            xor a		; Hyp.cls 4288
            ld (var_hyp_fin), a		; Hyp.cls 4289
            ld (asm_1_3817_n_fl_aopen), a		; Hyp.cls 4290
            ret		; Hyp.cls 4291
asm_1_3817_n_fl_rdrec_a:                         ; read up to fl_n bytes (128) into buf: A = how many (Z [4292]
            ld a, (asm_1_3817_n_fl_aopen)        ; none), HL past them [4293]
            or a		; Hyp.cls 4294
            jr z, asm_1_3817_n_fl_rr_none		; Hyp.cls 4295
            ld a, (asm_1_3817_n_fl_n)		; Hyp.cls 4296
            ld b, a                 ; B = wanted [4297]
            ld a, (asm_1_3817_n_fl_aoff)		; Hyp.cls 4298
            ld c, a		; Hyp.cls 4299
            ld a, 128		; Hyp.cls 4300
            sub c                   ; what is left of this record [4301]
            cp b		; Hyp.cls 4302
            jr nc, asm_1_3817_n_fl_rr_w1		; Hyp.cls 4303
            ld b, a                 ; (fewer: to its end) [4304]
asm_1_3817_n_fl_rr_w1:		; Hyp.cls 4305
            ld de, (asm_1_3817_n_fl_aleft)		; Hyp.cls 4306
            ld a, d		; Hyp.cls 4307
            or a		; Hyp.cls 4308
            jr nz, asm_1_3817_n_fl_rr_w2		; Hyp.cls 4309
            ld a, e		; Hyp.cls 4310
            cp b		; Hyp.cls 4311
            jr nc, asm_1_3817_n_fl_rr_w2		; Hyp.cls 4312
            ld b, e                 ; (fewer: to the file's end) [4313]
asm_1_3817_n_fl_rr_w2:		; Hyp.cls 4314
            ld a, b		; Hyp.cls 4315
            or a		; Hyp.cls 4316
            jr z, asm_1_3817_n_fl_rr_none		; Hyp.cls 4317
            ld a, e                 ; left - B [4318]
            sub b		; Hyp.cls 4319
            ld e, a		; Hyp.cls 4320
            ld a, d		; Hyp.cls 4321
            sbc a, 0		; Hyp.cls 4322
            ld d, a		; Hyp.cls 4323
            ld (asm_1_3817_n_fl_aleft), de		; Hyp.cls 4324
            push bc		; Hyp.cls 4325
            ld hl, (asm_1_3817_n_fl_arec)		; Hyp.cls 4326
            call asm_1_3817_n_fl_arc_pg          ; HL = the record in slot 6 [4327]
            ld a, (asm_1_3817_n_fl_aoff)		; Hyp.cls 4328
            add a, l		; Hyp.cls 4329
            ld l, a                 ; (+ 0-127: no carry out of the record's 128) [4330]
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 4331
            pop bc		; Hyp.cls 4332
            ld a, c                 ; the offset on: 128 = the next record [4333]
            add a, b		; Hyp.cls 4334
            ld c, b		; Hyp.cls 4335
            ld b, 0		; Hyp.cls 4336
            push bc		; Hyp.cls 4337
            ldir		; Hyp.cls 4338
            pop bc		; Hyp.cls 4339
            ex de, hl               ; HL = buf past the bytes (the caller pads from there) [4340]
            cp 128		; Hyp.cls 4341
            jr c, asm_1_3817_n_fl_rr_off		; Hyp.cls 4342
            push hl		; Hyp.cls 4343
            ld hl, (asm_1_3817_n_fl_arec)		; Hyp.cls 4344
            inc hl		; Hyp.cls 4345
            ld (asm_1_3817_n_fl_arec), hl		; Hyp.cls 4346
            pop hl		; Hyp.cls 4347
            xor a		; Hyp.cls 4348
asm_1_3817_n_fl_rr_off:		; Hyp.cls 4349
            ld (asm_1_3817_n_fl_aoff), a		; Hyp.cls 4350
            call asm_1_3817_n_fl_arc_off		; Hyp.cls 4351
            ld a, 128		; Hyp.cls 4352
            ld (asm_1_3817_n_fl_n), a            ; (128 again for the next) [4353]
            ld a, c		; Hyp.cls 4354
            or a		; Hyp.cls 4355
            ret		; Hyp.cls 4356
asm_1_3817_n_fl_rr_none:		; Hyp.cls 4357
            ld a, 128		; Hyp.cls 4358
            ld (asm_1_3817_n_fl_n), a		; Hyp.cls 4359
            xor a		; Hyp.cls 4360
            ret		; Hyp.cls 4361
    ENDIF		; Hyp.cls 4362
asm_1_3817_n_fl_exit:		; Hyp.cls 5844
			ret			; end of #asm

asm_1_5850_n:		; #asm, Hyp.cls line 5850 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 5851
            ld sp, (ntc_csp)		; Hyp.cls 5852
            ld bc, (var_hyp_hps)          ; (the buffers: the hypervisor's page) [5853]
    IFDEF NTC_MSXDOS		; Hyp.cls 5854
            call msx_win		; Hyp.cls 5855
    ELSE		; Hyp.cls 5856
            out (c), c		; Hyp.cls 5857
    ENDIF		; Hyp.cls 5858
            ld a, (var_hyp_fileshut_slot)		; Hyp.cls 5859
            ld b, a		; Hyp.cls 5860
            ld a, (var_hyp_fin)		; Hyp.cls 5861
            cp b		; Hyp.cls 5862
            jr nz, asm_1_5850_n_fs_out		; Hyp.cls 5863
            xor a		; Hyp.cls 5864
            ld (var_hyp_fin), a		; Hyp.cls 5865
    IFDEF NTC_MSXDOS		; Hyp.cls 5866
            push bc		; Hyp.cls 5867
            call sd_shut_in         ; (the SD card's file, when it is one) [5868]
            pop bc		; Hyp.cls 5869
    ELSE		; Hyp.cls 5870
            push bc		; Hyp.cls 5871
            call #BC7A              ; CAS IN CLOSE [5872]
            di		; Hyp.cls 5873
            pop bc		; Hyp.cls 5874
    ENDIF		; Hyp.cls 5875
asm_1_5850_n_fs_out:		; Hyp.cls 5876
            ld a, (var_hyp_fout)		; Hyp.cls 5877
            cp b		; Hyp.cls 5878
            jr nz, asm_1_5850_n_fs_done		; Hyp.cls 5879
            xor a		; Hyp.cls 5880
            ld (var_hyp_fout), a		; Hyp.cls 5881
    IFDEF NTC_MSXDOS		; Hyp.cls 5882
            call sd_shut_out		; Hyp.cls 5883
    ELSE		; Hyp.cls 5884
            call #BC8F              ; CAS OUT CLOSE [5885]
            di		; Hyp.cls 5886
    ENDIF		; Hyp.cls 5887
asm_1_5850_n_fs_done:		; Hyp.cls 5888
            ld bc, (ntc_rampt)		; Hyp.cls 5889
    IFDEF NTC_MSXDOS		; Hyp.cls 5890
            call msx_win		; Hyp.cls 5891
    ELSE		; Hyp.cls 5892
            out (c), c		; Hyp.cls 5893
    ENDIF		; Hyp.cls 5894
            ld sp, (var_hyp_hsp)		; Hyp.cls 5895
			ret			; end of #asm

fn_hyp_usesvc:		; sub usesvc (asm keyword), Hyp.cls line 5921
            ld hl, (ntc_rampt)		; Hyp.cls 5922
            ld (var_hyp_svp), hl		; Hyp.cls 5923
			ret			; end of #asm

asm_1_5940_n:		; #asm, Hyp.cls line 5940 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 5941
            ld sp, (ntc_csp)		; Hyp.cls 5942
            ld (asm_1_5940_n_sv_ix), ix		; Hyp.cls 5943
            ld (asm_1_5940_n_sv_iy), iy		; Hyp.cls 5944
            di		; Hyp.cls 5945
            ld a, (var_hyp_svc_t)		; Hyp.cls 5946
            or a		; Hyp.cls 5947
            jr z, asm_1_5940_n_sv_inst		; Hyp.cls 5948
            ld bc, (var_hyp_svp)		; Hyp.cls 5949
    IFDEF NTC_MSXDOS		; Hyp.cls 5950
            call msx_win		; Hyp.cls 5951
    ELSE		; Hyp.cls 5952
            out (c), c		; Hyp.cls 5953
    ENDIF		; Hyp.cls 5954
            call asm_1_5940_n_sv_go              ; (in the service page) A = the answer [5955]
asm_1_5940_n_sv_back:		; Hyp.cls 5956
            di		; Hyp.cls 5957
            ld l, a		; Hyp.cls 5958
            ld h, 0		; Hyp.cls 5959
            ld (var_hyp_svc_svc), hl		; Hyp.cls 5960
            ld bc, (ntc_rampt)      ; the page that was in the window back [5961]
    IFDEF NTC_MSXDOS		; Hyp.cls 5962
            call msx_win		; Hyp.cls 5963
    ELSE		; Hyp.cls 5964
            out (c), c		; Hyp.cls 5965
    ENDIF		; Hyp.cls 5966
            ld ix, (asm_1_5940_n_sv_ix)		; Hyp.cls 5967
            ld iy, (asm_1_5940_n_sv_iy)		; Hyp.cls 5968
            ld sp, (var_hyp_hsp)		; Hyp.cls 5969
            jp asm_1_5940_n_sv_exit		; Hyp.cls 5970
asm_1_5940_n_sv_inst:		; Hyp.cls 5971
            ld hl, #6000		; Hyp.cls 5972
asm_1_5940_n_sv_in_lp:		; Hyp.cls 5973
            push hl		; Hyp.cls 5974
            ld bc, #7FC0            ; main RAM's own [5975]
    IFDEF NTC_MSXDOS		; Hyp.cls 5976
            call msx_win		; Hyp.cls 5977
    ELSE		; Hyp.cls 5978
            out (c), c		; Hyp.cls 5979
    ENDIF		; Hyp.cls 5980
            ld de, (var_hyp_svc_buf)		; Hyp.cls 5981
            ld bc, 128		; Hyp.cls 5982
            ldir		; Hyp.cls 5983
            ld bc, (var_hyp_svp)		; Hyp.cls 5984
    IFDEF NTC_MSXDOS		; Hyp.cls 5985
            call msx_win		; Hyp.cls 5986
    ELSE		; Hyp.cls 5987
            out (c), c		; Hyp.cls 5988
    ENDIF		; Hyp.cls 5989
            pop de		; Hyp.cls 5990
            push de		; Hyp.cls 5991
            ld hl, (var_hyp_svc_buf)		; Hyp.cls 5992
            ld bc, 128		; Hyp.cls 5993
            ldir		; Hyp.cls 5994
            pop hl		; Hyp.cls 5995
            ld bc, 128		; Hyp.cls 5996
            add hl, bc		; Hyp.cls 5997
            ld de, asm_1_5940_n_sv_end		; Hyp.cls 5998
            or a		; Hyp.cls 5999
            sbc hl, de		; Hyp.cls 6000
            add hl, de		; Hyp.cls 6001
            jr c, asm_1_5940_n_sv_in_lp		; Hyp.cls 6002
            xor a		; Hyp.cls 6003
            jr asm_1_5940_n_sv_back		; Hyp.cls 6004
asm_1_5940_n_sv_ix:      dw 0		; Hyp.cls 6005
asm_1_5940_n_sv_iy:      dw 0		; Hyp.cls 6006
; sv_dx - A bytes (1-128) from HL to DE through buf: IX = HL's RAM setting, IY = DE's (0: none -
; main RAM outside the window); the service page back in the window after. HL, DE on past them
asm_1_5940_n_sv_dx:		; Hyp.cls 6009
            ld (asm_1_5940_n_sv_dxn), a		; Hyp.cls 6010
            push de		; Hyp.cls 6011
            ld de, (var_hyp_svc_buf)		; Hyp.cls 6012
            push ix		; Hyp.cls 6013
            pop bc		; Hyp.cls 6014
            inc b		; Hyp.cls 6015
            dec b		; Hyp.cls 6016
            jr z, asm_1_5940_n_sv_dx1		; Hyp.cls 6017
    IFDEF NTC_MSXDOS		; Hyp.cls 6018
            call msx_win		; Hyp.cls 6019
    ELSE		; Hyp.cls 6020
            out (c), c		; Hyp.cls 6021
    ENDIF		; Hyp.cls 6022
asm_1_5940_n_sv_dx1:		; Hyp.cls 6023
            ld c, a		; Hyp.cls 6024
            ld b, 0		; Hyp.cls 6025
            ldir		; Hyp.cls 6026
            pop de		; Hyp.cls 6027
            push hl		; Hyp.cls 6028
            push iy		; Hyp.cls 6029
            pop bc		; Hyp.cls 6030
            inc b		; Hyp.cls 6031
            dec b		; Hyp.cls 6032
            jr z, asm_1_5940_n_sv_dx2		; Hyp.cls 6033
    IFDEF NTC_MSXDOS		; Hyp.cls 6034
            call msx_win		; Hyp.cls 6035
    ELSE		; Hyp.cls 6036
            out (c), c		; Hyp.cls 6037
    ENDIF		; Hyp.cls 6038
asm_1_5940_n_sv_dx2:		; Hyp.cls 6039
            ld hl, (var_hyp_svc_buf)		; Hyp.cls 6040
            ld a, (asm_1_5940_n_sv_dxn)		; Hyp.cls 6041
            ld c, a		; Hyp.cls 6042
            ld b, 0		; Hyp.cls 6043
            ldir		; Hyp.cls 6044
            pop hl		; Hyp.cls 6045
            ld bc, (var_hyp_svp)		; Hyp.cls 6046
    IFDEF NTC_MSXDOS		; Hyp.cls 6047
            call msx_win		; Hyp.cls 6048
    ELSE		; Hyp.cls 6049
            out (c), c		; Hyp.cls 6050
    ENDIF		; Hyp.cls 6051
            ret		; Hyp.cls 6052
asm_1_5940_n_sv_dxn:     db 0		; Hyp.cls 6053
asm_1_5940_n_sv_exit:		; Hyp.cls 9111
			ret			; end of #asm

asm_1_9123_n:		; #asm, Hyp.cls line 9123 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 9124
            ld sp, (ntc_csp)		; Hyp.cls 9125
            ld (asm_1_9123_n_dv_ix), ix		; Hyp.cls 9126
            ld (asm_1_9123_n_dv_iy), iy		; Hyp.cls 9127
            ld hl, 0		; Hyp.cls 9128
            ld (var_hyp_drive_drive), hl		; Hyp.cls 9129
            ld hl, (var_hyp_drive_letter)		; Hyp.cls 9130
            ld (var_hyp_hdr), hl		; Hyp.cls 9131
            IF NTC_ROMLIB = 0		; Hyp.cls 9132
            ld a, (var_hyp_drs + 1)		; Hyp.cls 9133
            or a		; Hyp.cls 9134
            jr z, asm_1_9123_n_dv_rsx		; Hyp.cls 9135
            ld (asm_1_9123_n_dv_blk + 2), hl		; Hyp.cls 9136
            di		; Hyp.cls 9137
            ld bc, (var_hyp_drs)		; Hyp.cls 9138
    IFDEF NTC_MSXDOS		; Hyp.cls 9139
            call msx_win		; Hyp.cls 9140
    ELSE		; Hyp.cls 9141
            out (c), c		; Hyp.cls 9142
    ENDIF		; Hyp.cls 9143
            ld ix, asm_1_9123_n_dv_blk		; Hyp.cls 9144
            call #4000		; Hyp.cls 9145
            ld bc, (ntc_rampt)		; Hyp.cls 9146
    IFDEF NTC_MSXDOS		; Hyp.cls 9147
            call msx_win		; Hyp.cls 9148
    ELSE		; Hyp.cls 9149
            out (c), c		; Hyp.cls 9150
    ENDIF		; Hyp.cls 9151
            jr nc, asm_1_9123_n_dv_rsx		; Hyp.cls 9152
            ld hl, -1		; Hyp.cls 9153
            ld (var_hyp_drive_drive), hl		; Hyp.cls 9154
            jr asm_1_9123_n_dv_done		; Hyp.cls 9155
asm_1_9123_n_dv_blk:     dw 114, 0, 0, 0, 0, 0, 0		; Hyp.cls 9156
            ENDIF		; Hyp.cls 9157
asm_1_9123_n_dv_rsx:		; Hyp.cls 9158
    IFDEF NTC_MSXDOS		; Hyp.cls 9159
            jr asm_1_9123_n_dv_done              ; zxn: no ROM commands (KL FIND COMMAND): False [9160]
    ENDIF		; Hyp.cls 9161
            ld a, (var_hyp_drive_letter)		; Hyp.cls 9162
            or #80                  ; a one letter command name: its last letter + #80 [9163]
            ld (asm_1_9123_n_dv_nm), a		; Hyp.cls 9164
            ld hl, asm_1_9123_n_dv_nm		; Hyp.cls 9165
            call #BCD4              ; KL FIND COMMAND: carry = found, C = its ROM, HL = its address [9166]
            di		; Hyp.cls 9167
            jr nc, asm_1_9123_n_dv_done		; Hyp.cls 9168
            xor a                   ; no parameters [9169]
            call #001B              ; KL FAR PCALL [9170]
            di		; Hyp.cls 9171
            ld hl, -1		; Hyp.cls 9172
            ld (var_hyp_drive_drive), hl		; Hyp.cls 9173
            jr asm_1_9123_n_dv_done		; Hyp.cls 9174
asm_1_9123_n_dv_nm:      db 0		; Hyp.cls 9175
asm_1_9123_n_dv_ix:      dw 0		; Hyp.cls 9176
asm_1_9123_n_dv_iy:      dw 0		; Hyp.cls 9177
asm_1_9123_n_dv_done:		; Hyp.cls 9178
            ld ix, (asm_1_9123_n_dv_ix)		; Hyp.cls 9179
            ld iy, (asm_1_9123_n_dv_iy)		; Hyp.cls 9180
            ld sp, (var_hyp_hsp)		; Hyp.cls 9181
			ret			; end of #asm

fn_hot_row:		; function row (asm keyword), Hot.cls line 91
            pop hl                  ; r [92]
            ld e, (hl)		; Hot.cls 93
            in a, (#AA)		; Hot.cls 94
            and #F0		; Hot.cls 95
            or e		; Hot.cls 96
            out (#AA), a		; Hot.cls 97
            in a, (#A9)		; Hot.cls 98
            pop hl                  ; the result [99]
            ld (hl), a		; Hot.cls 100
            inc hl		; Hot.cls 101
            ld (hl), 0		; Hot.cls 102
			ret			; end of #asm

fn_memory_pages:		; function pages (asm keyword), Memory.cls line 70
            pop hl		; Memory.cls 71
            ld (mem_res), hl		; Memory.cls 72
            ld hl, mem_pages		; Memory.cls 73
            jp mem_go		; Memory.cls 74
			ret			; end of #asm

fn_memory_freepages:		; function freepages (asm keyword), Memory.cls line 80
            pop hl		; Memory.cls 81
            ld (mem_res), hl		; Memory.cls 82
            ld hl, mem_freepages		; Memory.cls 83
            jp mem_go		; Memory.cls 84
			ret			; end of #asm

fn_memory_ramsize:		; function ramsize (asm keyword), Memory.cls line 90
            pop hl		; Memory.cls 91
            ld (mem_res), hl		; Memory.cls 92
            ld hl, mem_ramsize		; Memory.cls 93
            jp mem_go		; Memory.cls 94
			ret			; end of #asm

fn_memory_pagetype:		; function pagetype (asm keyword), Memory.cls line 110
            pop hl		; Memory.cls 111
            ld e, (hl)		; Memory.cls 112
            inc hl		; Memory.cls 113
            ld d, (hl)		; Memory.cls 114
            ld (mem_a1), de		; Memory.cls 115
            pop hl		; Memory.cls 116
            ld (mem_res), hl		; Memory.cls 117
            ld hl, mem_pagetype		; Memory.cls 118
            jp mem_go		; Memory.cls 119
			ret			; end of #asm

fn_memory_tableend:		; function tableend (asm keyword), Memory.cls line 146
            pop hl		; Memory.cls 147
            ld (mem_res), hl		; Memory.cls 148
            ld hl, mem_tableend		; Memory.cls 149
            jp mem_go		; Memory.cls 150
			ret			; end of #asm

fn_memory_top:		; function top (asm keyword), Memory.cls line 176
            pop hl		; Memory.cls 177
            ld (mem_res), hl		; Memory.cls 178
            ld hl, mem_top		; Memory.cls 179
            jp mem_go		; Memory.cls 180
			ret			; end of #asm

fn_memory_map:		; function map (asm keyword), Memory.cls line 196
            pop hl		; Memory.cls 197
            ld e, (hl)		; Memory.cls 198
            inc hl		; Memory.cls 199
            ld d, (hl)		; Memory.cls 200
            ld (mem_a1), de		; Memory.cls 201
            pop hl		; Memory.cls 202
            ld e, (hl)		; Memory.cls 203
            inc hl		; Memory.cls 204
            ld d, (hl)		; Memory.cls 205
            ld (mem_a2), de		; Memory.cls 206
            pop hl		; Memory.cls 207
            ld (mem_res), hl		; Memory.cls 208
            ld hl, mem_map		; Memory.cls 209
            jp mem_go0		; Memory.cls 210
			ret			; end of #asm

fn_memory_allocpage:		; function allocpage (asm keyword), Memory.cls line 219
            pop hl		; Memory.cls 220
            ld e, (hl)		; Memory.cls 221
            inc hl		; Memory.cls 222
            ld d, (hl)		; Memory.cls 223
            ld (mem_a1), de		; Memory.cls 224
            pop hl		; Memory.cls 225
            ld (mem_res), hl		; Memory.cls 226
            ld hl, mem_allocpage		; Memory.cls 227
            jp mem_go		; Memory.cls 228
			ret			; end of #asm

fn_memory_freepage:		; function freepage (asm keyword), Memory.cls line 235
            pop hl		; Memory.cls 236
            ld e, (hl)		; Memory.cls 237
            inc hl		; Memory.cls 238
            ld d, (hl)		; Memory.cls 239
            ld (mem_a1), de		; Memory.cls 240
            pop hl		; Memory.cls 241
            ld (mem_res), hl		; Memory.cls 242
            ld hl, mem_freepage		; Memory.cls 243
            jp mem_go		; Memory.cls 244
			ret			; end of #asm

fn_memory_selectpage:		; function selectpage (asm keyword), Memory.cls line 250
            pop hl		; Memory.cls 251
            ld e, (hl)		; Memory.cls 252
            inc hl		; Memory.cls 253
            ld d, (hl)		; Memory.cls 254
            ld (mem_a1), de		; Memory.cls 255
            pop hl		; Memory.cls 256
            ld (mem_res), hl		; Memory.cls 257
            ld hl, mem_selpage		; Memory.cls 258
            jp mem_go		; Memory.cls 259
			ret			; end of #asm

fn_memory_readbyte:		; function readbyte (asm keyword), Memory.cls line 340
            pop hl		; Memory.cls 341
            ld (mem_a1), hl		; Memory.cls 342
            pop hl		; Memory.cls 343
            ld (mem_res), hl		; Memory.cls 344
            ld hl, mem_readbyte		; Memory.cls 345
            jp mem_go		; Memory.cls 346
			ret			; end of #asm

fn_memory_readword:		; function readword (asm keyword), Memory.cls line 351
            pop hl		; Memory.cls 352
            ld (mem_a1), hl		; Memory.cls 353
            pop hl		; Memory.cls 354
            ld (mem_res), hl		; Memory.cls 355
            ld hl, mem_readword		; Memory.cls 356
            jp mem_go		; Memory.cls 357
			ret			; end of #asm

fn_memory_writebyte:		; sub writebyte (asm keyword), Memory.cls line 362
            pop hl		; Memory.cls 363
            ld (mem_a1), hl		; Memory.cls 364
            pop hl		; Memory.cls 365
            ld e, (hl)		; Memory.cls 366
            inc hl		; Memory.cls 367
            ld d, (hl)		; Memory.cls 368
            ld (mem_a2), de		; Memory.cls 369
            ld hl, mem_writebyte		; Memory.cls 370
            jp mem_go0		; Memory.cls 371
			ret			; end of #asm

fn_memory_writeword:		; sub writeword (asm keyword), Memory.cls line 376
            pop hl		; Memory.cls 377
            ld (mem_a1), hl		; Memory.cls 378
            pop hl		; Memory.cls 379
            ld e, (hl)		; Memory.cls 380
            inc hl		; Memory.cls 381
            ld d, (hl)		; Memory.cls 382
            ld (mem_a2), de		; Memory.cls 383
            ld hl, mem_writeword		; Memory.cls 384
            jp mem_go0		; Memory.cls 385
			ret			; end of #asm

fn_memory_copy:		; function copy (asm keyword), Memory.cls line 393
            pop hl		; Memory.cls 394
            ld (mem_a1), hl		; Memory.cls 395
            pop hl		; Memory.cls 396
            ld (mem_a2), hl		; Memory.cls 397
            pop hl		; Memory.cls 398
            ld e, (hl)		; Memory.cls 399
            inc hl		; Memory.cls 400
            ld d, (hl)		; Memory.cls 401
            ld (mem_a3), de		; Memory.cls 402
            pop hl		; Memory.cls 403
            ld (mem_res), hl		; Memory.cls 404
            ld hl, mem_copy		; Memory.cls 405
            jp mem_go		; Memory.cls 406
			ret			; end of #asm

fn_memory_banks:		; function banks (asm keyword), Memory.cls line 415
            pop hl		; Memory.cls 416
            ld (mem_res), hl		; Memory.cls 417
            ld hl, mem_bankcount		; Memory.cls 418
            jp mem_go		; Memory.cls 419
			ret			; end of #asm

fn_memory_allocbank:		; function allocbank (asm keyword), Memory.cls line 425
            pop hl		; Memory.cls 426
            ld (mem_res), hl		; Memory.cls 427
            ld hl, mem_allocbank		; Memory.cls 428
            jp mem_go		; Memory.cls 429
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
