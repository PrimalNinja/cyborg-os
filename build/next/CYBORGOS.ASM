; the window data (; @window ... ; @endwindow in #asm): put in the window hole by its guard
			MACRO ntc_windata
; (the hypervisor's page from #5300 - #4000 the disc buffers, #5000 the font: Install copies
; these into each bank from there, FileCall 99 put them there at the start)
            ds #5300 - $		; Hyp.cls 2127
; page zero (#0000-#0080)
fn_hyp_info_hi_p0:		; Hyp.cls 2129
            db #C3		; Hyp.cls 2130
            dw fn_hyp_info_sb_bwb                           ; #0000: warm boot - the BIOS's WBOOT (the task [2131]
            db 0, 0                             ; ends); (#0001) - 3: the BIOS jump table [2132]
            db #C3		; Hyp.cls 2133
            dw fn_hyp_info_sb_start                         ; #0005: BDOS (#0006: the top of the TPA) [2134]
            ds #38 - 8		; Hyp.cls 2135
            db #C3		; Hyp.cls 2136
            dw fn_hyp_info_sb_int                           ; #0038: the interrupt [2137]
            ds #44 - #3B		; Hyp.cls 2138
    IFDEF NTC_ZXN		; Hyp.cls 2139
            db #08                              ; #0044: ex af, af - stash A + FLAGS (carry = far / interrupt) before the port flip clobbers A [2140]
            ld bc, #243B                        ; zxn PIVOT via the MMU ports (no Z80N opcode): select MMU slot 0 (#50) [2141]
            ld a, #50		; Hyp.cls 2142
            out (c), a		; Hyp.cls 2143
            inc b                               ; #253B [2144]
            ld a, 16                            ; the hypervisor's slot-0 page; slot 0 flips HERE, next byte (#0051) is its receiver [2145]
            out (c), a		; Hyp.cls 2146
            ds #5C - #51                        ; (no #0046 landing on zxn: hyp->task arrives high via sb_hin -> sb_land) [2147]
    ELSE		; Hyp.cls 2148
            db #ED, #49                         ; #0044: out (c), c [2149]
            db #C3		; Hyp.cls 2150
            dw fn_hyp_info_sb_land                          ; #0046: this bank switched in [2151]
            ds #5C - #49		; Hyp.cls 2152
    ENDIF		; Hyp.cls 2153
            db 0, "           "                 ; #005C: the default FCB [2154]
            ds #80 - #68		; Hyp.cls 2155
            db 0                                ; #0080: no command tail [2156]
fn_hyp_info_hi_p0e:		; Hyp.cls 2157
; the stubs: assembled here, run at STUB in the bank (DISP: their labels are the bank's
; addresses). The BDOS: what needs nothing of the hypervisor is answered here, with no
; switch - the console out (2, 9: collected at OBUF; the hypervisor gets them, IX = how many, at
; the next far call or interrupt, or when 128 wait), the keys (1, 6, 10, 11: from KEY, where
; the hypervisor leaves the slot's next key), the IOBYTE (7, 8), the disc's parameters (27, 31)
; and the calls with nothing to do (3, 4, 5, 28, 29, 30, 37 - 30 with #C0 on at DE is CyborgOS's
; UniDOS call), CP/M 3's 49 for the console's size (MODE); the rest is a far call. Then the
; BIOS (its jump table: (#0001) - 3) and the start-up (the default FCBs)
fn_hyp_info_sb_img:		; Hyp.cls 2166
            DISP 61184		; Hyp.cls 2167
fn_hyp_info_sb_start:		; Hyp.cls 2168
            di                                  ; BDOS: C = function, DE = argument [2169]
            ld a, c		; Hyp.cls 2170
            cp 2		; Hyp.cls 2171
            jp z, fn_hyp_info_sb_put		; Hyp.cls 2172
            cp 6		; Hyp.cls 2173
            jr z, fn_hyp_info_sb_f6		; Hyp.cls 2174
            cp 11		; Hyp.cls 2175
            jr z, fn_hyp_info_sb_stat		; Hyp.cls 2176
            cp 1		; Hyp.cls 2177
            jr z, fn_hyp_info_sb_f1		; Hyp.cls 2178
            cp 9		; Hyp.cls 2179
            jp z, fn_hyp_info_sb_str		; Hyp.cls 2180
            cp 10		; Hyp.cls 2181
            jp z, fn_hyp_info_sb_line		; Hyp.cls 2182
            cp 3		; Hyp.cls 2183
            jr z, fn_hyp_info_sb_rdr		; Hyp.cls 2184
            cp 7		; Hyp.cls 2185
            jr z, fn_hyp_info_sb_iob		; Hyp.cls 2186
            cp 8		; Hyp.cls 2187
            jr z, fn_hyp_info_sb_siob		; Hyp.cls 2188
            cp 27		; Hyp.cls 2189
            jr z, fn_hyp_info_sb_alv		; Hyp.cls 2190
            cp 31		; Hyp.cls 2191
            jr z, fn_hyp_info_sb_dpb		; Hyp.cls 2192
            cp 4		; Hyp.cls 2193
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 2194
            cp 5		; Hyp.cls 2195
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 2196
            cp 28		; Hyp.cls 2197
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 2198
            cp 29		; Hyp.cls 2199
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 2200
            cp 30		; Hyp.cls 2201
            jr z, fn_hyp_info_sb_f30		; Hyp.cls 2202
            cp 37		; Hyp.cls 2203
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 2204
            cp 49		; Hyp.cls 2205
            jp z, fn_hyp_info_sb_scb		; Hyp.cls 2206
            jp fn_hyp_info_sb_call		; Hyp.cls 2207
fn_hyp_info_sb_f30:                                         ; 30: nothing - unless #C0 on at DE: CyborgOS's [2208]
            ld a, (de)                          ; UniDOS call (CD, DIR: the hypervisor's) [2209]
            cp #C0		; Hyp.cls 2210
            jp nc, fn_hyp_info_sb_call		; Hyp.cls 2211
fn_hyp_info_sb_zero:		; Hyp.cls 2212
            xor a                               ; 4, 5 (the printer: not yet), 28, 29, 30, 37 [2213]
fn_hyp_info_sb_ret:		; Hyp.cls 2214
            ld l, a		; Hyp.cls 2215
            ld h, 0		; Hyp.cls 2216
            ei		; Hyp.cls 2217
            ret		; Hyp.cls 2218
fn_hyp_info_sb_rdr:		; Hyp.cls 2219
            ld a, #1A                           ; 3: the reader - the end of a file [2220]
            jr fn_hyp_info_sb_ret		; Hyp.cls 2221
fn_hyp_info_sb_iob:		; Hyp.cls 2222
            ld a, (#0003)                       ; 7: the IOBYTE [2223]
            jr fn_hyp_info_sb_ret		; Hyp.cls 2224
fn_hyp_info_sb_siob:		; Hyp.cls 2225
            ld a, e                             ; 8 [2226]
            ld (#0003), a		; Hyp.cls 2227
            jr fn_hyp_info_sb_zero		; Hyp.cls 2228
fn_hyp_info_sb_alv:		; Hyp.cls 2229
            ld hl, fn_hyp_info_sb_alvec                     ; 27: the allocation vector (a CPC data disc's) [2230]
            ei		; Hyp.cls 2231
            ret		; Hyp.cls 2232
fn_hyp_info_sb_dpb:		; Hyp.cls 2233
            ld hl, fn_hyp_info_sb_dpbv                      ; 31: the disc parameter block [2234]
            ei		; Hyp.cls 2235
            ret		; Hyp.cls 2236
fn_hyp_info_sb_f6:		; Hyp.cls 2237
            ld a, e		; Hyp.cls 2238
            cp #FF		; Hyp.cls 2239
            jr z, fn_hyp_info_sb_get		; Hyp.cls 2240
            cp #FE		; Hyp.cls 2241
            jr c, fn_hyp_info_sb_put		; Hyp.cls 2242
fn_hyp_info_sb_stat:		; Hyp.cls 2243
            ld a, (63105)                       ; 6 / #FE, 11: is a key waiting (#FF / 0) [2244]
            or a		; Hyp.cls 2245
            jr z, fn_hyp_info_sb_ret		; Hyp.cls 2246
            ld a, #FF		; Hyp.cls 2247
            jr fn_hyp_info_sb_ret		; Hyp.cls 2248
fn_hyp_info_sb_get:		; Hyp.cls 2249
            ld hl, 63105                        ; 6 / #FF: the key or 0 (no wait) [2250]
            ld a, (hl)		; Hyp.cls 2251
            ld (hl), 0		; Hyp.cls 2252
            jr fn_hyp_info_sb_ret		; Hyp.cls 2253
fn_hyp_info_sb_f1:		; Hyp.cls 2254
            call fn_hyp_info_sb_key                         ; 1: a key (waited for), echoed [2255]
            push af		; Hyp.cls 2256
            ld e, a		; Hyp.cls 2257
            call fn_hyp_info_sb_putc		; Hyp.cls 2258
            pop af		; Hyp.cls 2259
            jr fn_hyp_info_sb_ret		; Hyp.cls 2260
fn_hyp_info_sb_put:		; Hyp.cls 2261
            call fn_hyp_info_sb_putc                        ; 2: E out [2262]
            ei		; Hyp.cls 2263
            ret		; Hyp.cls 2264
fn_hyp_info_sb_str:		; Hyp.cls 2265
            ld h, d                             ; 9: the string at DE, to "$" [2266]
            ld l, e		; Hyp.cls 2267
fn_hyp_info_sb_st_lp:		; Hyp.cls 2268
            ld a, (hl)		; Hyp.cls 2269
            cp '$'		; Hyp.cls 2270
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 2271
            push hl		; Hyp.cls 2272
            ld e, a		; Hyp.cls 2273
            call fn_hyp_info_sb_putc		; Hyp.cls 2274
            pop hl		; Hyp.cls 2275
            inc hl		; Hyp.cls 2276
            jr fn_hyp_info_sb_st_lp		; Hyp.cls 2277
; sb_putc - E collected at OBUF (the hypervisor shown them when 128 wait). Interrupts off
fn_hyp_info_sb_putc:		; Hyp.cls 2279
            ld hl, 62976 + 128                 ; the count [2280]
            ld a, (hl)		; Hyp.cls 2281
            inc (hl)		; Hyp.cls 2282
            ld l, a		; Hyp.cls 2283
            ld h, 62976 / 256		; Hyp.cls 2284
            ld (hl), e		; Hyp.cls 2285
            cp 127		; Hyp.cls 2286
            ret c		; Hyp.cls 2287
            push bc		; Hyp.cls 2288
            push de		; Hyp.cls 2289
            ld c, #80                           ; full: function #80, only the characters [2290]
            call fn_hyp_info_sb_call		; Hyp.cls 2291
            di		; Hyp.cls 2292
            pop de		; Hyp.cls 2293
            pop bc		; Hyp.cls 2294
            ret		; Hyp.cls 2295
; sb_key - A = the next key, waited for: none at KEY - a far call (#81) that has the hypervisor
; run the others until a key comes (or the clock moves on), then look again
fn_hyp_info_sb_key:		; Hyp.cls 2298
            ld hl, 63105		; Hyp.cls 2299
            ld a, (hl)		; Hyp.cls 2300
            or a		; Hyp.cls 2301
            jr z, fn_hyp_info_sb_k_wait		; Hyp.cls 2302
            ld (hl), 0		; Hyp.cls 2303
            ret		; Hyp.cls 2304
fn_hyp_info_sb_k_wait:		; Hyp.cls 2305
            push bc		; Hyp.cls 2306
            push de		; Hyp.cls 2307
            ld c, #81		; Hyp.cls 2308
            call fn_hyp_info_sb_call		; Hyp.cls 2309
            di		; Hyp.cls 2310
            pop de		; Hyp.cls 2311
            pop bc		; Hyp.cls 2312
            jr fn_hyp_info_sb_key		; Hyp.cls 2313
; 10: a line typed into the buffer at DE (its size, then how many came, then them): BS / DEL
; rub out, Control + U / X the whole line, Control + C at its start ends the program, CR / LF
; end it (CR echoed)
fn_hyp_info_sb_line:		; Hyp.cls 2317
            ld (fn_hyp_info_sb_lbuf), de		; Hyp.cls 2318
            xor a		; Hyp.cls 2319
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 2320
fn_hyp_info_sb_l_lp:		; Hyp.cls 2321
            call fn_hyp_info_sb_key		; Hyp.cls 2322
            cp 13		; Hyp.cls 2323
            jr z, fn_hyp_info_sb_l_end		; Hyp.cls 2324
            cp 10		; Hyp.cls 2325
            jr z, fn_hyp_info_sb_l_end		; Hyp.cls 2326
            cp 8		; Hyp.cls 2327
            jr z, fn_hyp_info_sb_l_bs		; Hyp.cls 2328
            cp 127		; Hyp.cls 2329
            jr z, fn_hyp_info_sb_l_bs		; Hyp.cls 2330
            cp 21		; Hyp.cls 2331
            jr z, fn_hyp_info_sb_l_kill		; Hyp.cls 2332
            cp 24		; Hyp.cls 2333
            jr z, fn_hyp_info_sb_l_kill		; Hyp.cls 2334
            cp 3		; Hyp.cls 2335
            jr nz, fn_hyp_info_sb_l_ch		; Hyp.cls 2336
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 2337
            or a		; Hyp.cls 2338
            jr nz, fn_hyp_info_sb_l_lp		; Hyp.cls 2339
            ld c, 0                             ; Control + C: the program ends [2340]
            jp fn_hyp_info_sb_call		; Hyp.cls 2341
fn_hyp_info_sb_l_ch:		; Hyp.cls 2342
            cp 32		; Hyp.cls 2343
            jr c, fn_hyp_info_sb_l_lp		; Hyp.cls 2344
            ld b, a		; Hyp.cls 2345
            ld hl, (fn_hyp_info_sb_lbuf)		; Hyp.cls 2346
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 2347
            cp (hl)		; Hyp.cls 2348
            jr nc, fn_hyp_info_sb_l_lp                      ; full [2349]
            inc a		; Hyp.cls 2350
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 2351
            ld e, a		; Hyp.cls 2352
            ld d, 0		; Hyp.cls 2353
            inc hl		; Hyp.cls 2354
            add hl, de		; Hyp.cls 2355
            ld (hl), b		; Hyp.cls 2356
            ld e, b		; Hyp.cls 2357
            call fn_hyp_info_sb_putc		; Hyp.cls 2358
            jr fn_hyp_info_sb_l_lp		; Hyp.cls 2359
fn_hyp_info_sb_l_kill:		; Hyp.cls 2360
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 2361
            or a		; Hyp.cls 2362
            jr z, fn_hyp_info_sb_l_lp		; Hyp.cls 2363
            call fn_hyp_info_sb_l_rub		; Hyp.cls 2364
            jr fn_hyp_info_sb_l_kill		; Hyp.cls 2365
fn_hyp_info_sb_l_bs:		; Hyp.cls 2366
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 2367
            or a		; Hyp.cls 2368
            jr z, fn_hyp_info_sb_l_lp		; Hyp.cls 2369
            call fn_hyp_info_sb_l_rub		; Hyp.cls 2370
            jr fn_hyp_info_sb_l_lp		; Hyp.cls 2371
fn_hyp_info_sb_l_rub:		; Hyp.cls 2372
            dec a		; Hyp.cls 2373
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 2374
            ld e, 8		; Hyp.cls 2375
            call fn_hyp_info_sb_putc		; Hyp.cls 2376
            ld e, ' '		; Hyp.cls 2377
            call fn_hyp_info_sb_putc		; Hyp.cls 2378
            ld e, 8		; Hyp.cls 2379
            jp fn_hyp_info_sb_putc		; Hyp.cls 2380
fn_hyp_info_sb_l_end:		; Hyp.cls 2381
            ld hl, (fn_hyp_info_sb_lbuf)		; Hyp.cls 2382
            inc hl		; Hyp.cls 2383
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 2384
            ld (hl), a		; Hyp.cls 2385
            ld e, 13		; Hyp.cls 2386
            call fn_hyp_info_sb_putc		; Hyp.cls 2387
            jp fn_hyp_info_sb_zero		; Hyp.cls 2388
fn_hyp_info_sb_lbuf:    dw 0		; Hyp.cls 2389
fn_hyp_info_sb_lcnt:    db 0		; Hyp.cls 2390
fn_hyp_info_sb_call:		; Hyp.cls 2391
            push ix                             ; a far call: IX, IY and the alternate [2392]
            push iy                             ; registers kept over it (ex af, af') [2393]
            db #08		; Hyp.cls 2394
            exx		; Hyp.cls 2395
            push af		; Hyp.cls 2396
            push bc		; Hyp.cls 2397
            push de		; Hyp.cls 2398
            push hl		; Hyp.cls 2399
            exx		; Hyp.cls 2400
            db #08		; Hyp.cls 2401
            ld a, (62976 + 128)		; Hyp.cls 2402
            ld ixl, a		; Hyp.cls 2403
            ld ixh, 0		; Hyp.cls 2404
            ld a, c		; Hyp.cls 2405
            ld hl, fn_hyp_info_sb_far		; Hyp.cls 2406
            push hl		; Hyp.cls 2407
            ld (#FFFE), sp		; Hyp.cls 2408
            ld bc, #7FC0		; Hyp.cls 2409
            scf                                 ; carry: a far call [2410]
            jp #0044		; Hyp.cls 2411
fn_hyp_info_sb_far:		; Hyp.cls 2412
            db #08                              ; the answer in A and HL; the program's [2413]
            exx                                 ; other registers back [2414]
            pop hl		; Hyp.cls 2415
            pop de		; Hyp.cls 2416
            pop bc		; Hyp.cls 2417
            pop af		; Hyp.cls 2418
            exx		; Hyp.cls 2419
            db #08		; Hyp.cls 2420
            pop iy		; Hyp.cls 2421
            pop ix		; Hyp.cls 2422
            ei		; Hyp.cls 2423
            ret		; Hyp.cls 2424
fn_hyp_info_sb_int:		; Hyp.cls 2425
            push af                             ; an interrupt: everything kept [2426]
            push bc		; Hyp.cls 2427
            push de		; Hyp.cls 2428
            push hl		; Hyp.cls 2429
            db #08                              ; ex af, af' [2430]
            exx		; Hyp.cls 2431
            push af		; Hyp.cls 2432
            push bc		; Hyp.cls 2433
            push de		; Hyp.cls 2434
            push hl		; Hyp.cls 2435
            push ix		; Hyp.cls 2436
            push iy		; Hyp.cls 2437
            ld a, (62976 + 128)		; Hyp.cls 2438
            ld ixl, a		; Hyp.cls 2439
            ld ixh, 0		; Hyp.cls 2440
            ld hl, fn_hyp_info_sb_rest		; Hyp.cls 2441
            push hl		; Hyp.cls 2442
            ld (#FFFE), sp		; Hyp.cls 2443
            ld bc, #7FC0		; Hyp.cls 2444
            or a                                ; no carry: an interrupt [2445]
            jp #0044		; Hyp.cls 2446
fn_hyp_info_sb_rest:		; Hyp.cls 2447
            pop iy		; Hyp.cls 2448
            pop ix		; Hyp.cls 2449
            pop hl		; Hyp.cls 2450
            pop de		; Hyp.cls 2451
            pop bc		; Hyp.cls 2452
            pop af		; Hyp.cls 2453
            exx		; Hyp.cls 2454
            db #08                              ; ex af, af' [2455]
            pop hl		; Hyp.cls 2456
            pop de		; Hyp.cls 2457
            pop bc		; Hyp.cls 2458
            pop af		; Hyp.cls 2459
            ei		; Hyp.cls 2460
            ret		; Hyp.cls 2461
fn_hyp_info_sb_land:		; Hyp.cls 2462
            ld sp, (#FFFE)                      ; this bank's SP [2463]
            push af		; Hyp.cls 2464
            ld a, e                             ; E = 1: the hypervisor has the characters [2465]
            or a		; Hyp.cls 2466
            jr z, fn_hyp_info_sb_lkeep		; Hyp.cls 2467
            xor a		; Hyp.cls 2468
            ld (62976 + 128), a		; Hyp.cls 2469
fn_hyp_info_sb_lkeep:		; Hyp.cls 2470
            pop af		; Hyp.cls 2471
            ret		; Hyp.cls 2472
fn_hyp_info_sb_scb:		; Hyp.cls 2473
            ld h, d                             ; 49 (CP/M 3's system control block): the [2474]
            ld l, e                             ; console's width - 1 (#1A), its page length [2475]
            inc hl                              ; (#1C) - MODE's; other bytes 0, sets kept [2476]
            ld a, (hl)                          ; nowhere [2477]
            or a		; Hyp.cls 2478
            jp nz, fn_hyp_info_sb_zero		; Hyp.cls 2479
            ld a, (de)		; Hyp.cls 2480
            cp #1C		; Hyp.cls 2481
            ld hl, 63112		; Hyp.cls 2482
            jr z, fn_hyp_info_sb_scb_a		; Hyp.cls 2483
            cp #1A		; Hyp.cls 2484
            jp nz, fn_hyp_info_sb_zero		; Hyp.cls 2485
            ld a, (63111)		; Hyp.cls 2486
            dec a		; Hyp.cls 2487
            jp fn_hyp_info_sb_ret		; Hyp.cls 2488
fn_hyp_info_sb_scb_a:		; Hyp.cls 2489
            ld a, (hl)		; Hyp.cls 2490
            jp fn_hyp_info_sb_ret		; Hyp.cls 2491
; the BIOS: CP/M 2.2's 17 entries. The console ones as the BDOS's; the printer and punch take
; nothing yet; the disc ones (sectors) can't be had here: SELDSK gives 0 (no such drive),
; READ / WRITE 1 (an error)
fn_hyp_info_sb_bios:		; Hyp.cls 2495
            jp fn_hyp_info_sb_bboot                         ; BOOT [2496]
fn_hyp_info_sb_bwb:		; Hyp.cls 2497
            jp fn_hyp_info_sb_bboot                         ; WBOOT: (#0001) [2498]
            jp fn_hyp_info_sb_bconst                        ; CONST [2499]
            jp fn_hyp_info_sb_bconin                        ; CONIN [2500]
            jp fn_hyp_info_sb_bconout                       ; CONOUT [2501]
            jp fn_hyp_info_sb_bnone                         ; LIST [2502]
            jp fn_hyp_info_sb_bnone                         ; PUNCH [2503]
            jp fn_hyp_info_sb_brdr                          ; READER [2504]
            jp fn_hyp_info_sb_bnone                         ; HOME [2505]
            jp fn_hyp_info_sb_bseld                         ; SELDSK [2506]
            jp fn_hyp_info_sb_bnone                         ; SETTRK [2507]
            jp fn_hyp_info_sb_bnone                         ; SETSEC [2508]
            jp fn_hyp_info_sb_bdma                          ; SETDMA [2509]
            jp fn_hyp_info_sb_bfail                         ; READ [2510]
            jp fn_hyp_info_sb_bfail                         ; WRITE [2511]
            jp fn_hyp_info_sb_blstst                        ; LISTST [2512]
            jp fn_hyp_info_sb_bsectr                        ; SECTRAN [2513]
fn_hyp_info_sb_bboot:		; Hyp.cls 2514
            ld c, 0                             ; the task ends [2515]
            jp fn_hyp_info_sb_start		; Hyp.cls 2516
fn_hyp_info_sb_bconst:		; Hyp.cls 2517
            di		; Hyp.cls 2518
            ld a, (63105)		; Hyp.cls 2519
            or a		; Hyp.cls 2520
            jr z, fn_hyp_info_sb_bc_n		; Hyp.cls 2521
            ld a, #FF		; Hyp.cls 2522
fn_hyp_info_sb_bc_n:		; Hyp.cls 2523
            ei		; Hyp.cls 2524
            ret		; Hyp.cls 2525
fn_hyp_info_sb_bconin:		; Hyp.cls 2526
            di		; Hyp.cls 2527
            call fn_hyp_info_sb_key		; Hyp.cls 2528
            ei		; Hyp.cls 2529
            ret		; Hyp.cls 2530
fn_hyp_info_sb_bconout:		; Hyp.cls 2531
            di		; Hyp.cls 2532
            ld e, c		; Hyp.cls 2533
            call fn_hyp_info_sb_putc		; Hyp.cls 2534
            ei		; Hyp.cls 2535
fn_hyp_info_sb_bnone:		; Hyp.cls 2536
            ret		; Hyp.cls 2537
fn_hyp_info_sb_brdr:		; Hyp.cls 2538
            ld a, #1A		; Hyp.cls 2539
            ret		; Hyp.cls 2540
fn_hyp_info_sb_bseld:		; Hyp.cls 2541
            ld hl, 0		; Hyp.cls 2542
            ret		; Hyp.cls 2543
fn_hyp_info_sb_bdma:		; Hyp.cls 2544
            ld d, b		; Hyp.cls 2545
            ld e, c		; Hyp.cls 2546
            ld c, 26		; Hyp.cls 2547
            jp fn_hyp_info_sb_start		; Hyp.cls 2548
fn_hyp_info_sb_bfail:		; Hyp.cls 2549
            ld a, 1		; Hyp.cls 2550
            ret		; Hyp.cls 2551
fn_hyp_info_sb_blstst:		; Hyp.cls 2552
            ld a, #FF		; Hyp.cls 2553
            ret		; Hyp.cls 2554
fn_hyp_info_sb_bsectr:		; Hyp.cls 2555
            ld h, b		; Hyp.cls 2556
            ld l, c		; Hyp.cls 2557
            ret		; Hyp.cls 2558
; a CPC data format disc's parameters (31) and allocation vector (27): 180 1K blocks, 64
; directory entries in the first two
fn_hyp_info_sb_dpbv:		; Hyp.cls 2561
            dw 36                               ; SPT: 128 byte records a track [2562]
            db 3, 7, 0                          ; BSH, BLM, EXM [2563]
            dw 179, 63                          ; DSM, DRM [2564]
            db #C0, 0                           ; AL0, AL1 [2565]
            dw 16, 0                            ; CKS, OFF [2566]
fn_hyp_info_sb_alvec:		; Hyp.cls 2567
            db #C0		; Hyp.cls 2568
            ds 22		; Hyp.cls 2569
; the start-up: the default FCBs (#005C, #006C) from the command tail (#0080), as the CCP
; makes them - "B:NAME.EXT", * as ?s - then the program at #0100
fn_hyp_info_sb_init:		; Hyp.cls 2572
            ld hl, #005C		; Hyp.cls 2573
            call fn_hyp_info_sb_iclr		; Hyp.cls 2574
            ld hl, #006C		; Hyp.cls 2575
            call fn_hyp_info_sb_iclr		; Hyp.cls 2576
            ld hl, #0081		; Hyp.cls 2577
            ld a, (#0080)		; Hyp.cls 2578
            ld b, a		; Hyp.cls 2579
            ld de, #005C		; Hyp.cls 2580
            call fn_hyp_info_sb_parse		; Hyp.cls 2581
            ld de, #006C		; Hyp.cls 2582
            call fn_hyp_info_sb_parse		; Hyp.cls 2583
            jp #0100		; Hyp.cls 2584
fn_hyp_info_sb_iclr:		; Hyp.cls 2585
            ld (hl), 0		; Hyp.cls 2586
            inc hl		; Hyp.cls 2587
            ld c, 11		; Hyp.cls 2588
fn_hyp_info_sb_ic_sp:		; Hyp.cls 2589
            ld (hl), ' '		; Hyp.cls 2590
            inc hl		; Hyp.cls 2591
            dec c		; Hyp.cls 2592
            jr nz, fn_hyp_info_sb_ic_sp		; Hyp.cls 2593
            ld c, 4		; Hyp.cls 2594
fn_hyp_info_sb_ic_z:		; Hyp.cls 2595
            ld (hl), 0		; Hyp.cls 2596
            inc hl		; Hyp.cls 2597
            dec c		; Hyp.cls 2598
            jr nz, fn_hyp_info_sb_ic_z		; Hyp.cls 2599
            ret		; Hyp.cls 2600
; sb_parse - HL = the tail, B = characters left; DE = an FCB: the next word into it
fn_hyp_info_sb_parse:		; Hyp.cls 2602
            ld a, b		; Hyp.cls 2603
            or a		; Hyp.cls 2604
            ret z		; Hyp.cls 2605
            ld a, (hl)		; Hyp.cls 2606
            cp ' '		; Hyp.cls 2607
            jr nz, fn_hyp_info_sb_p_word		; Hyp.cls 2608
            inc hl		; Hyp.cls 2609
            dec b		; Hyp.cls 2610
            jr fn_hyp_info_sb_parse		; Hyp.cls 2611
fn_hyp_info_sb_p_word:		; Hyp.cls 2612
            ld (fn_hyp_info_sb_pfcb), de		; Hyp.cls 2613
            ld a, b		; Hyp.cls 2614
            cp 2		; Hyp.cls 2615
            jr c, fn_hyp_info_sb_p_name		; Hyp.cls 2616
            inc hl		; Hyp.cls 2617
            ld a, (hl)		; Hyp.cls 2618
            dec hl		; Hyp.cls 2619
            cp ':'		; Hyp.cls 2620
            jr nz, fn_hyp_info_sb_p_name		; Hyp.cls 2621
            ld a, (hl)		; Hyp.cls 2622
            sub '@'		; Hyp.cls 2623
            ld (de), a                          ; its drive [2624]
            inc hl		; Hyp.cls 2625
            inc hl		; Hyp.cls 2626
            dec b		; Hyp.cls 2627
            dec b		; Hyp.cls 2628
fn_hyp_info_sb_p_name:		; Hyp.cls 2629
            inc de		; Hyp.cls 2630
            ld c, 8		; Hyp.cls 2631
            call fn_hyp_info_sb_pfield		; Hyp.cls 2632
            ld a, b		; Hyp.cls 2633
            or a		; Hyp.cls 2634
            ret z		; Hyp.cls 2635
            ld a, (hl)		; Hyp.cls 2636
            cp '.'		; Hyp.cls 2637
            jr nz, fn_hyp_info_sb_p_skip		; Hyp.cls 2638
            inc hl		; Hyp.cls 2639
            dec b		; Hyp.cls 2640
            ld de, (fn_hyp_info_sb_pfcb)		; Hyp.cls 2641
            ld a, e		; Hyp.cls 2642
            add a, 9		; Hyp.cls 2643
            ld e, a		; Hyp.cls 2644
            ld c, 3		; Hyp.cls 2645
            call fn_hyp_info_sb_pfield		; Hyp.cls 2646
fn_hyp_info_sb_p_skip:		; Hyp.cls 2647
            ld a, b                             ; the rest of the word [2648]
            or a		; Hyp.cls 2649
            ret z		; Hyp.cls 2650
            ld a, (hl)		; Hyp.cls 2651
            cp ' '		; Hyp.cls 2652
            ret z		; Hyp.cls 2653
            inc hl		; Hyp.cls 2654
            dec b		; Hyp.cls 2655
            jr fn_hyp_info_sb_p_skip		; Hyp.cls 2656
; sb_pfield - up to C characters into the field at DE, to a "." or a space; * fills it with ?
fn_hyp_info_sb_pfield:		; Hyp.cls 2658
            ld a, b		; Hyp.cls 2659
            or a		; Hyp.cls 2660
            ret z		; Hyp.cls 2661
            ld a, (hl)		; Hyp.cls 2662
            cp ' '		; Hyp.cls 2663
            ret z		; Hyp.cls 2664
            cp '.'		; Hyp.cls 2665
            ret z		; Hyp.cls 2666
            cp '*'		; Hyp.cls 2667
            jr z, fn_hyp_info_sb_pf_star		; Hyp.cls 2668
            inc c		; Hyp.cls 2669
            dec c		; Hyp.cls 2670
            jr z, fn_hyp_info_sb_pf_on                      ; (the field full: the extra left out) [2671]
            ld (de), a		; Hyp.cls 2672
            inc de		; Hyp.cls 2673
            dec c		; Hyp.cls 2674
fn_hyp_info_sb_pf_on:		; Hyp.cls 2675
            inc hl		; Hyp.cls 2676
            dec b		; Hyp.cls 2677
            jr fn_hyp_info_sb_pfield		; Hyp.cls 2678
fn_hyp_info_sb_pf_star:		; Hyp.cls 2679
            inc c		; Hyp.cls 2680
            dec c		; Hyp.cls 2681
            jr z, fn_hyp_info_sb_pf_on		; Hyp.cls 2682
            ld a, '?'		; Hyp.cls 2683
            ld (de), a		; Hyp.cls 2684
            inc de		; Hyp.cls 2685
            dec c		; Hyp.cls 2686
            jr fn_hyp_info_sb_pf_star		; Hyp.cls 2687
fn_hyp_info_sb_pfcb:    dw 0		; Hyp.cls 2688
fn_hyp_info_sb_end:		; Hyp.cls 2689
            ENT		; Hyp.cls 2690
            ASSERT fn_hyp_info_sb_end - fn_hyp_info_sb_start <= 62208 - 61184, "the bank stubs must fit below FONT"		; Hyp.cls 2691
            ASSERT fn_hyp_info_sb_end - fn_hyp_info_sb_start <= #340, "the stubs must leave a program's first stack (#F240-#F2FF) free"		; Hyp.cls 2692
    IFDEF NTC_ZXN		; Hyp.cls 2693
; sb_hin: the hyp->task switch-back receiver, placed below #FFFE in each bank (its own high memory,
; clear of the stub budget). Reached from Run after nextreg #57 maps the task's slot 7 in; it maps
; slots 0-6 to the task too, loads the handed-over result/rclr out of the task's SWAP scratch, then
; lands the task through sb_land. Install copies it in via the window, like the stubs and font.
fn_hyp_info_hi_sw:		; Hyp.cls 2698
            DISP 65488		; Hyp.cls 2699
fn_hyp_info_sb_hin:		; Hyp.cls 2700
            ld a, (63120 + 0)                  ; the task's slot-0 base page [2701]
            ld e, a		; Hyp.cls 2702
            ld bc, #243B                        ; NextReg select port (#253B = value) [2703]
            ld d, #50                           ; slot register 0 [2704]
fn_hyp_info_sb_hin1:		; Hyp.cls 2705
            ld a, d		; Hyp.cls 2706
            out (c), a                          ; select the slot register [2707]
            inc b                               ; #253B [2708]
            out (c), e                          ; = its page (base, base+1, ...) [2709]
            dec b                               ; #243B [2710]
            inc d		; Hyp.cls 2711
            inc e		; Hyp.cls 2712
            ld a, d		; Hyp.cls 2713
            cp #57                              ; slots #50..#56 (0..6)? (slot 7 already mapped by Run) [2714]
            jr nz, fn_hyp_info_sb_hin1		; Hyp.cls 2715
            ld a, (63120 + 2)		; Hyp.cls 2716
            ld e, a                             ; rclr -> E (for sb_land) [2717]
            ld hl, (63120 + 3)                 ; far-call result -> HL [2718]
            ld a, (63120 + 1)                  ; far-call result -> A [2719]
            jp fn_hyp_info_sb_land		; Hyp.cls 2720
fn_hyp_info_sb_hin_end:		; Hyp.cls 2721
            ENT		; Hyp.cls 2722
            ASSERT fn_hyp_info_sb_hin_end - fn_hyp_info_sb_hin <= #FFFE - 65488, "fn_hyp_info_sb_hin must fit below #FFFE"		; Hyp.cls 2723
fn_hyp_info_hi_swe:		; Hyp.cls 2724
    ENDIF		; Hyp.cls 2725
; ---- the page code: in the hypervisor's page (window data), called with it in the window
asm_1_2771_n_fp_start:		; Hyp.cls 3063
            ASSERT asm_1_2771_n_fp_start >= #5300, "FileCall's page code: after the disc buffers and the font"		; Hyp.cls 3064
asm_1_2771_n_fp_go:		; Hyp.cls 3065
            ld (asm_1_2771_n_fp_sp), sp		; Hyp.cls 3066
            ld a, (var_hyp_filecall_f)		; Hyp.cls 3067
            cp 15		; Hyp.cls 3068
            jp z, asm_1_2771_n_fl_open		; Hyp.cls 3069
            cp 16		; Hyp.cls 3070
            jp z, asm_1_2771_n_fl_close		; Hyp.cls 3071
            cp 19		; Hyp.cls 3072
            jp z, asm_1_2771_n_fl_del		; Hyp.cls 3073
            cp 23		; Hyp.cls 3074
            jp z, asm_1_2771_n_fl_ren		; Hyp.cls 3075
            cp 20		; Hyp.cls 3076
            jp z, asm_1_2771_n_fl_rdseq		; Hyp.cls 3077
            cp 33		; Hyp.cls 3078
            jp z, asm_1_2771_n_fl_rdran		; Hyp.cls 3079
            cp 21		; Hyp.cls 3080
            jp z, asm_1_2771_n_fl_write		; Hyp.cls 3081
            cp 34		; Hyp.cls 3082
            jp z, asm_1_2771_n_fl_write		; Hyp.cls 3083
            cp 22		; Hyp.cls 3084
            jp z, asm_1_2771_n_fl_make		; Hyp.cls 3085
            cp 17		; Hyp.cls 3086
            jp z, asm_1_2771_n_fl_srch1		; Hyp.cls 3087
            cp 18		; Hyp.cls 3088
            jp z, asm_1_2771_n_fl_srch		; Hyp.cls 3089
            cp 35		; Hyp.cls 3090
            jp z, asm_1_2771_n_fl_size		; Hyp.cls 3091
            cp 36		; Hyp.cls 3092
            jp z, asm_1_2771_n_fl_setran		; Hyp.cls 3093
            cp 100		; Hyp.cls 3094
            jp z, asm_1_2771_n_fl_hopen		; Hyp.cls 3095
            cp 101		; Hyp.cls 3096
            jp z, asm_1_2771_n_fl_hread		; Hyp.cls 3097
            cp 102		; Hyp.cls 3098
            jp z, asm_1_2771_n_fl_hclose		; Hyp.cls 3099
            cp 103		; Hyp.cls 3100
            jp z, asm_1_2771_n_fl_hload		; Hyp.cls 3101
            cp 30		; Hyp.cls 3102
            jp z, asm_1_2771_n_fl_unicall		; Hyp.cls 3103
            jp asm_1_2771_n_fp_done		; Hyp.cls 3104
; ---- the hypervisor's own reading (RUN, DIR, CD): 100 open the file named at fcb (dma
; characters, main RAM); 101 read dma bytes (128 at most) to buf: how many; 102 close; 103 the
; rest of it into the slot (setting) from address dma, fcb bytes at most: how many. Not while
; a slot reads a file (255)
asm_1_2771_n_fl_hopen:		; Hyp.cls 3109
            ld a, (var_hyp_fin)		; Hyp.cls 3110
            or a		; Hyp.cls 3111
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3112
            ld de, asm_1_2771_n_fl_name_s + 1		; Hyp.cls 3113
            ld hl, (var_hyp_filecall_fcb)          ; a name with no drive: the hypervisor's drive's path first [3114]
            ld bc, (var_hyp_filecall_dma)          ; when it has one (UniDOS: CD IDE: ...) [3115]
            ld a, ':'		; Hyp.cls 3116
            cpir		; Hyp.cls 3117
            jr z, asm_1_2771_n_fl_ho_nm		; Hyp.cls 3118
            ld a, (var_hyp_hdr)		; Hyp.cls 3119
            call asm_1_2771_n_fl_pfxm		; Hyp.cls 3120
asm_1_2771_n_fl_ho_nm:		; Hyp.cls 3121
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3122
            ld bc, (var_hyp_filecall_dma)		; Hyp.cls 3123
            ldir		; Hyp.cls 3124
            call asm_1_2771_n_fl_nlen		; Hyp.cls 3125
            call asm_1_2771_n_fl_inopen		; Hyp.cls 3126
            jr c, asm_1_2771_n_fl_ho_ok		; Hyp.cls 3127
            ld hl, asm_1_2771_n_fl_name_s        ; NAME.CYB not there: with UniDOS NAME.COM instead (RUN - a [3128]
            ld e, (hl)              ; .COM with no entry: UniDOS reads a file with no header to [3129]
            ld d, 0                 ; its real end) [3130]
            add hl, de		; Hyp.cls 3131
            ld a, (hl)		; Hyp.cls 3132
            cp 'B'		; Hyp.cls 3133
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3134
            ld (hl), 'M'		; Hyp.cls 3135
            dec hl		; Hyp.cls 3136
            ld a, (hl)		; Hyp.cls 3137
            cp 'Y'		; Hyp.cls 3138
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3139
            ld (hl), 'O'		; Hyp.cls 3140
            call asm_1_2771_n_fl_uni		; Hyp.cls 3141
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3142
            call asm_1_2771_n_fl_inopen		; Hyp.cls 3143
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3144
            ld hl, (var_hyp_filecall_fcb)          ; (the caller's name too: NAME.COM) [3145]
            ld bc, (var_hyp_filecall_dma)		; Hyp.cls 3146
            add hl, bc		; Hyp.cls 3147
            dec hl		; Hyp.cls 3148
            ld (hl), 'M'		; Hyp.cls 3149
            dec hl		; Hyp.cls 3150
            ld (hl), 'O'		; Hyp.cls 3151
asm_1_2771_n_fl_ho_ok:		; Hyp.cls 3152
            ld a, 99                ; (99: the hypervisor's) [3153]
            ld (var_hyp_fin), a		; Hyp.cls 3154
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3155
asm_1_2771_n_fl_hread:		; Hyp.cls 3156
            ld a, (var_hyp_filecall_dma)		; Hyp.cls 3157
            ld (asm_1_2771_n_fl_n), a		; Hyp.cls 3158
            call asm_1_2771_n_fl_rdrec		; Hyp.cls 3159
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 3160
            jp asm_1_2771_n_fp_done		; Hyp.cls 3161
asm_1_2771_n_fl_hclose:		; Hyp.cls 3162
            ld a, (var_hyp_fin)		; Hyp.cls 3163
            cp 99		; Hyp.cls 3164
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3165
            call asm_1_2771_n_fl_inclose		; Hyp.cls 3166
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3167
asm_1_2771_n_fl_hload:		; Hyp.cls 3168
            ld hl, 0		; Hyp.cls 3169
            ld (asm_1_2771_n_fl_cnt), hl		; Hyp.cls 3170
            ld hl, (var_hyp_filecall_dma)		; Hyp.cls 3171
            ld (asm_1_2771_n_fl_at), hl		; Hyp.cls 3172
asm_1_2771_n_fl_hl_lp:		; Hyp.cls 3173
            ld hl, (var_hyp_filecall_fcb)          ; what is left to load (fcb bytes at most) [3174]
            ld de, (asm_1_2771_n_fl_cnt)		; Hyp.cls 3175
            or a		; Hyp.cls 3176
            sbc hl, de		; Hyp.cls 3177
            jr z, asm_1_2771_n_fl_hl_end		; Hyp.cls 3178
            ld a, h		; Hyp.cls 3179
            or a		; Hyp.cls 3180
            ld a, 128		; Hyp.cls 3181
            jr nz, asm_1_2771_n_fl_hl_n		; Hyp.cls 3182
            ld a, l		; Hyp.cls 3183
            cp 128		; Hyp.cls 3184
            jr c, asm_1_2771_n_fl_hl_n		; Hyp.cls 3185
            ld a, 128		; Hyp.cls 3186
asm_1_2771_n_fl_hl_n:		; Hyp.cls 3187
            ld (asm_1_2771_n_fl_n), a		; Hyp.cls 3188
            ld (asm_1_2771_n_fl_want), a		; Hyp.cls 3189
            call asm_1_2771_n_fl_rdrec           ; a record's worth into buf [3190]
            jr z, asm_1_2771_n_fl_hl_end		; Hyp.cls 3191
            ld b, a		; Hyp.cls 3192
            ld (asm_1_2771_n_fl_want + 1), a		; Hyp.cls 3193
            ld hl, (asm_1_2771_n_fl_cnt)		; Hyp.cls 3194
            ld e, a		; Hyp.cls 3195
            ld d, 0		; Hyp.cls 3196
            add hl, de		; Hyp.cls 3197
            ld (asm_1_2771_n_fl_cnt), hl		; Hyp.cls 3198
            ld hl, (asm_1_2771_n_fl_at)		; Hyp.cls 3199
            ld c, b		; Hyp.cls 3200
            ld b, 0		; Hyp.cls 3201
            call asm_1_2771_n_fl_fits		; Hyp.cls 3202
            jr c, asm_1_2771_n_fl_hl_slow		; Hyp.cls 3203
            push bc		; Hyp.cls 3204
            ld de, (var_hyp_filecall_buf)          ; in one page: one ldir [3205]
            call asm_1_2771_n_fl_toslot		; Hyp.cls 3206
            pop bc		; Hyp.cls 3207
            ld hl, (asm_1_2771_n_fl_at)		; Hyp.cls 3208
            add hl, bc		; Hyp.cls 3209
            jr asm_1_2771_n_fl_hl_put		; Hyp.cls 3210
asm_1_2771_n_fl_hl_slow:		; Hyp.cls 3211
            ld b, c		; Hyp.cls 3212
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3213
asm_1_2771_n_fl_hl_cp:		; Hyp.cls 3214
            ld a, (de)              ; into the slot [3215]
            call asm_1_2771_n_fl_poke		; Hyp.cls 3216
            inc hl		; Hyp.cls 3217
            inc de		; Hyp.cls 3218
            djnz asm_1_2771_n_fl_hl_cp		; Hyp.cls 3219
asm_1_2771_n_fl_hl_put:		; Hyp.cls 3220
            ld (asm_1_2771_n_fl_at), hl		; Hyp.cls 3221
            ld a, (asm_1_2771_n_fl_want)		; Hyp.cls 3222
            ld b, a		; Hyp.cls 3223
            ld a, (asm_1_2771_n_fl_want + 1)		; Hyp.cls 3224
            cp b		; Hyp.cls 3225
            jr z, asm_1_2771_n_fl_hl_lp          ; a whole one: on [3226]
asm_1_2771_n_fl_hl_end:		; Hyp.cls 3227
            ld hl, (asm_1_2771_n_fl_cnt)		; Hyp.cls 3228
            ld (asm_1_2771_n_fl_res16), hl		; Hyp.cls 3229
            ld a, 1		; Hyp.cls 3230
            ld (asm_1_2771_n_fl_r16), a		; Hyp.cls 3231
            jp asm_1_2771_n_fp_done		; Hyp.cls 3232
; ---- 15: open (to read)
asm_1_2771_n_fl_open:		; Hyp.cls 3234
            ld a, (var_hyp_fin)		; Hyp.cls 3235
            or a		; Hyp.cls 3236
            jr z, asm_1_2771_n_fl_op_new		; Hyp.cls 3237
            ld b, a		; Hyp.cls 3238
            ld a, (asm_1_2771_n_fl_slot)		; Hyp.cls 3239
            cp b		; Hyp.cls 3240
            jp nz, asm_1_2771_n_fp_done          ; another slot's being read [3241]
            call asm_1_2771_n_fl_inclose         ; this slot's: CP/M needs no close after reading - this open [3242]
asm_1_2771_n_fl_op_new:                          ; replaces it (Exists opens and leaves it) [3243]
            call asm_1_2771_n_fl_name		; Hyp.cls 3244
            call asm_1_2771_n_fl_inopen		; Hyp.cls 3245
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3246
            ld hl, asm_1_2771_n_fl_name_s        ; kept, to open it again (33 going back) [3247]
            ld de, asm_1_2771_n_fl_inname		; Hyp.cls 3248
            ld bc, asm_1_2771_n_FL_NL		; Hyp.cls 3249
            ldir		; Hyp.cls 3250
            ld a, (asm_1_2771_n_fl_slot)		; Hyp.cls 3251
            ld (var_hyp_fin), a		; Hyp.cls 3252
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3253
            ld (asm_1_2771_n_fl_infcb), hl		; Hyp.cls 3254
            ld a, 1		; Hyp.cls 3255
            ld (asm_1_2771_n_fl_infcb + 2), a		; Hyp.cls 3256
            ld hl, 0		; Hyp.cls 3257
            ld (asm_1_2771_n_fl_inrec), hl		; Hyp.cls 3258
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3259
; ---- 22: make (a new file, to write)
asm_1_2771_n_fl_make:		; Hyp.cls 3261
            ld a, (var_hyp_fout)		; Hyp.cls 3262
            or a		; Hyp.cls 3263
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3264
            call asm_1_2771_n_fl_name		; Hyp.cls 3265
            call asm_1_2771_n_fl_plain		; Hyp.cls 3266
            ld hl, asm_1_2771_n_fl_name_s + 1		; Hyp.cls 3267
            ld a, (asm_1_2771_n_fl_name_s)		; Hyp.cls 3268
            ld b, a		; Hyp.cls 3269
            ld de, #4800		; Hyp.cls 3270
            call #BC8C              ; CAS OUT OPEN [3271]
            di		; Hyp.cls 3272
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3273
            ld a, (asm_1_2771_n_fl_slot)		; Hyp.cls 3274
            ld (var_hyp_fout), a		; Hyp.cls 3275
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3276
            ld (asm_1_2771_n_fl_outfcb), hl		; Hyp.cls 3277
            ld a, 1		; Hyp.cls 3278
            ld (asm_1_2771_n_fl_outfcb + 2), a		; Hyp.cls 3279
            ld hl, 0		; Hyp.cls 3280
            ld (asm_1_2771_n_fl_outrec), hl		; Hyp.cls 3281
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3282
; ---- 16: close
asm_1_2771_n_fl_close:		; Hyp.cls 3284
            call asm_1_2771_n_fl_isin		; Hyp.cls 3285
            jr nz, asm_1_2771_n_fl_cl_out		; Hyp.cls 3286
            call asm_1_2771_n_fl_inclose		; Hyp.cls 3287
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3288
asm_1_2771_n_fl_cl_out:		; Hyp.cls 3289
            call asm_1_2771_n_fl_isout		; Hyp.cls 3290
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3291
            xor a		; Hyp.cls 3292
            ld (var_hyp_fout), a		; Hyp.cls 3293
            call asm_1_2771_n_fl_plain		; Hyp.cls 3294
            call #BC8F              ; CAS OUT CLOSE [3295]
            di		; Hyp.cls 3296
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3297
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3298
; ---- 19: delete (|ERA, "name")
asm_1_2771_n_fl_del:		; Hyp.cls 3300
            call asm_1_2771_n_fl_name		; Hyp.cls 3301
            call asm_1_2771_n_fl_plain		; Hyp.cls 3302
            ld hl, asm_1_2771_n_fl_name_s + 1		; Hyp.cls 3303
            ld (asm_1_2771_n_fl_desc + 1), hl		; Hyp.cls 3304
            ld a, (asm_1_2771_n_fl_name_s)		; Hyp.cls 3305
            ld (asm_1_2771_n_fl_desc), a		; Hyp.cls 3306
            ld hl, asm_1_2771_n_fl_yes           ; (UniDOS asks before it deletes a folder - all it holds too -, [3307]
            ld a, (hl)              ; a read-only or a hidden file: KM WAIT CHAR, its text unseen, [3308]
            ld (hl), 0              ; the VDU off. KM CHAR RETURN: the answer waiting for it - N, [3309]
            or a                    ; so a CP/M program's delete never takes a folder; Y only after [3310]
            ld a, 'N'               ; BDOS 30 op 8, RMDIR's, for its empty folder) [3311]
            jr z, asm_1_2771_n_fl_del_n		; Hyp.cls 3312
            ld a, 'Y'		; Hyp.cls 3313
asm_1_2771_n_fl_del_n:		; Hyp.cls 3314
            call #BB0C		; Hyp.cls 3315
            ld hl, asm_1_2771_n_fl_era           ; KL FIND COMMAND; KM READ CHAR after [3316]
            call #BCD4              ; takes the answer back when nothing asked [3317]
            di		; Hyp.cls 3318
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3319
            ld ix, asm_1_2771_n_fl_par		; Hyp.cls 3320
            ld a, 1                 ; one parameter: the string [3321]
            call #001B              ; KL FAR PCALL [3322]
            call #BB09              ; KM READ CHAR (interrupts: off again in fl_done) [3323]
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3324
; ---- 23: rename (the disc ROM's |REN, "new", "old"): the old name at FCB 0-11, the new
; at 16-27 (its drive 0: the old one's)
asm_1_2771_n_fl_ren:		; Hyp.cls 3327
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3328
            call asm_1_2771_n_fl_peek		; Hyp.cls 3329
            ld (asm_1_2771_n_fl_dfl), a		; Hyp.cls 3330
            ld de, 16		; Hyp.cls 3331
            add hl, de		; Hyp.cls 3332
            call asm_1_2771_n_fl_namehl          ; the new name [3333]
            xor a		; Hyp.cls 3334
            ld (asm_1_2771_n_fl_dfl), a		; Hyp.cls 3335
            ld hl, asm_1_2771_n_fl_name_s		; Hyp.cls 3336
            ld de, asm_1_2771_n_fl_new_s		; Hyp.cls 3337
            ld bc, asm_1_2771_n_FL_NL		; Hyp.cls 3338
            ldir		; Hyp.cls 3339
            call asm_1_2771_n_fl_name            ; the old one [3340]
            call asm_1_2771_n_fl_plain		; Hyp.cls 3341
            ld hl, asm_1_2771_n_fl_name_s + 1		; Hyp.cls 3342
            ld (asm_1_2771_n_fl_desc + 1), hl		; Hyp.cls 3343
            ld a, (asm_1_2771_n_fl_name_s)		; Hyp.cls 3344
            ld (asm_1_2771_n_fl_desc), a		; Hyp.cls 3345
            ld hl, asm_1_2771_n_fl_new_s + 1		; Hyp.cls 3346
            ld (asm_1_2771_n_fl_desc2 + 1), hl		; Hyp.cls 3347
            ld a, (asm_1_2771_n_fl_new_s)		; Hyp.cls 3348
            ld (asm_1_2771_n_fl_desc2), a		; Hyp.cls 3349
            ld hl, asm_1_2771_n_fl_rencmd		; Hyp.cls 3350
            call #BCD4              ; KL FIND COMMAND [3351]
            di		; Hyp.cls 3352
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3353
            ld ix, asm_1_2771_n_fl_par2          ; IX+0: the last parameter (the old name), IX+2: the new [3354]
            ld a, 2		; Hyp.cls 3355
            call #001B              ; KL FAR PCALL [3356]
            jp asm_1_2771_n_fl_ok              ; (interrupts: off again in fl_done) [3357]
; ---- 33: read record r0-r1: on to it (from the start again if it is behind)
asm_1_2771_n_fl_rdran:		; Hyp.cls 3359
            call asm_1_2771_n_fl_isin		; Hyp.cls 3360
            jp nz, asm_1_2771_n_fl_rdout		; Hyp.cls 3361
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3362
            ld de, 33		; Hyp.cls 3363
            add hl, de		; Hyp.cls 3364
            call asm_1_2771_n_fl_peek		; Hyp.cls 3365
            ld e, a		; Hyp.cls 3366
            inc hl		; Hyp.cls 3367
            call asm_1_2771_n_fl_peek		; Hyp.cls 3368
            ld d, a		; Hyp.cls 3369
            ld (asm_1_2771_n_fl_want), de		; Hyp.cls 3370
            ld hl, (asm_1_2771_n_fl_inrec)		; Hyp.cls 3371
            or a		; Hyp.cls 3372
            sbc hl, de		; Hyp.cls 3373
            jr c, asm_1_2771_n_fl_rr_on		; Hyp.cls 3374
            jr z, asm_1_2771_n_fl_rr_on		; Hyp.cls 3375
            call asm_1_2771_n_fl_inclose         ; behind: open it again [3376]
            ld hl, asm_1_2771_n_fl_inname		; Hyp.cls 3377
            ld de, asm_1_2771_n_fl_name_s		; Hyp.cls 3378
            ld bc, asm_1_2771_n_FL_NL		; Hyp.cls 3379
            ldir		; Hyp.cls 3380
            call asm_1_2771_n_fl_inopen		; Hyp.cls 3381
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3382
            ld a, (asm_1_2771_n_fl_slot)		; Hyp.cls 3383
            ld (var_hyp_fin), a		; Hyp.cls 3384
            ld hl, 0		; Hyp.cls 3385
            ld (asm_1_2771_n_fl_inrec), hl		; Hyp.cls 3386
asm_1_2771_n_fl_rr_on:		; Hyp.cls 3387
            ld hl, (asm_1_2771_n_fl_inrec)		; Hyp.cls 3388
            ld de, (asm_1_2771_n_fl_want)		; Hyp.cls 3389
            or a		; Hyp.cls 3390
            sbc hl, de		; Hyp.cls 3391
            jr nc, asm_1_2771_n_fl_rdseq		; Hyp.cls 3392
            call asm_1_2771_n_fl_rdrec		; Hyp.cls 3393
            jp z, asm_1_2771_n_fl_eof		; Hyp.cls 3394
            ld hl, (asm_1_2771_n_fl_inrec)		; Hyp.cls 3395
            inc hl		; Hyp.cls 3396
            ld (asm_1_2771_n_fl_inrec), hl		; Hyp.cls 3397
            jr asm_1_2771_n_fl_rr_on		; Hyp.cls 3398
; ---- 20: read the next record
asm_1_2771_n_fl_rdseq:		; Hyp.cls 3400
            call asm_1_2771_n_fl_isin		; Hyp.cls 3401
            jr nz, asm_1_2771_n_fl_rdout		; Hyp.cls 3402
            call asm_1_2771_n_fl_rdrec		; Hyp.cls 3403
            jr z, asm_1_2771_n_fl_eof		; Hyp.cls 3404
            ex de, hl		; Hyp.cls 3405
            ld hl, (asm_1_2771_n_fl_inrec)		; Hyp.cls 3406
            inc hl		; Hyp.cls 3407
            ld (asm_1_2771_n_fl_inrec), hl		; Hyp.cls 3408
            ex de, hl		; Hyp.cls 3409
            ld b, a                 ; the record padded with #1A [3410]
            ld a, 128		; Hyp.cls 3411
            sub b		; Hyp.cls 3412
            jr z, asm_1_2771_n_fl_rd_put		; Hyp.cls 3413
            ld b, a		; Hyp.cls 3414
            ld a, #1A		; Hyp.cls 3415
asm_1_2771_n_fl_rd_pad:		; Hyp.cls 3416
            ld (hl), a		; Hyp.cls 3417
            inc hl		; Hyp.cls 3418
            djnz asm_1_2771_n_fl_rd_pad		; Hyp.cls 3419
asm_1_2771_n_fl_rd_put:		; Hyp.cls 3420
            ld hl, (var_hyp_filecall_dma)          ; into the slot's DMA: in one page, one ldir [3421]
            ld bc, 128		; Hyp.cls 3422
            call asm_1_2771_n_fl_fits		; Hyp.cls 3423
            jr c, asm_1_2771_n_fl_rd_slow		; Hyp.cls 3424
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3425
            call asm_1_2771_n_fl_toslot		; Hyp.cls 3426
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3427
asm_1_2771_n_fl_rd_slow:                         ; (across two pages: a byte at a time) [3428]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3429
            ld de, (var_hyp_filecall_dma)		; Hyp.cls 3430
            ld b, 128		; Hyp.cls 3431
asm_1_2771_n_fl_rd_cp:		; Hyp.cls 3432
            ld a, (hl)		; Hyp.cls 3433
            ex de, hl		; Hyp.cls 3434
            call asm_1_2771_n_fl_poke		; Hyp.cls 3435
            ex de, hl		; Hyp.cls 3436
            inc hl		; Hyp.cls 3437
            inc de		; Hyp.cls 3438
            djnz asm_1_2771_n_fl_rd_cp		; Hyp.cls 3439
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3440
asm_1_2771_n_fl_rdout:		; Hyp.cls 3441
            call asm_1_2771_n_fl_isout           ; a file being written: nothing to read back [3442]
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3443
asm_1_2771_n_fl_eof:		; Hyp.cls 3444
            ld a, 1		; Hyp.cls 3445
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 3446
            jp asm_1_2771_n_fp_done		; Hyp.cls 3447
; ---- 21 / 34: write the next record
asm_1_2771_n_fl_write:		; Hyp.cls 3449
            call asm_1_2771_n_fl_isout		; Hyp.cls 3450
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3451
            ld hl, (var_hyp_filecall_dma)          ; the slot's DMA into buf [3452]
            ld bc, 128		; Hyp.cls 3453
            call asm_1_2771_n_fl_fits		; Hyp.cls 3454
            jr c, asm_1_2771_n_fl_wr_slow		; Hyp.cls 3455
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3456
            call asm_1_2771_n_fl_fromslot		; Hyp.cls 3457
            jr asm_1_2771_n_fl_wr_got		; Hyp.cls 3458
asm_1_2771_n_fl_wr_slow:		; Hyp.cls 3459
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3460
            ld b, 128		; Hyp.cls 3461
asm_1_2771_n_fl_wr_cp:		; Hyp.cls 3462
            call asm_1_2771_n_fl_peek		; Hyp.cls 3463
            ld (de), a		; Hyp.cls 3464
            inc hl		; Hyp.cls 3465
            inc de		; Hyp.cls 3466
            djnz asm_1_2771_n_fl_wr_cp		; Hyp.cls 3467
asm_1_2771_n_fl_wr_got:		; Hyp.cls 3468
            call asm_1_2771_n_fl_plain		; Hyp.cls 3469
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3470
            ld b, 128		; Hyp.cls 3471
asm_1_2771_n_fl_wr_lp:		; Hyp.cls 3472
            ld a, (hl)		; Hyp.cls 3473
            push bc		; Hyp.cls 3474
            push hl		; Hyp.cls 3475
            call #BC95              ; CAS OUT CHAR [3476]
            di		; Hyp.cls 3477
            pop hl		; Hyp.cls 3478
            pop bc		; Hyp.cls 3479
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3480
            inc hl		; Hyp.cls 3481
            djnz asm_1_2771_n_fl_wr_lp		; Hyp.cls 3482
            ld hl, (asm_1_2771_n_fl_outrec)		; Hyp.cls 3483
            inc hl		; Hyp.cls 3484
            ld (asm_1_2771_n_fl_outrec), hl		; Hyp.cls 3485
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3486
; ---- 35: the file's size in records (r0-r2): counted, reading it through. The file this slot
; is reading is opened again after, at its record; another slot's being read: 255
asm_1_2771_n_fl_size:		; Hyp.cls 3489
            ld a, (var_hyp_fin)		; Hyp.cls 3490
            or a		; Hyp.cls 3491
            jr z, asm_1_2771_n_fl_sz_free		; Hyp.cls 3492
            ld b, a		; Hyp.cls 3493
            ld a, (asm_1_2771_n_fl_slot)		; Hyp.cls 3494
            cp b		; Hyp.cls 3495
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 3496
            call asm_1_2771_n_fl_inclose		; Hyp.cls 3497
            ld a, 1		; Hyp.cls 3498
asm_1_2771_n_fl_sz_free:		; Hyp.cls 3499
            ld (asm_1_2771_n_fl_had), a		; Hyp.cls 3500
            call asm_1_2771_n_fl_name		; Hyp.cls 3501
            call asm_1_2771_n_fl_inopen		; Hyp.cls 3502
            jr nc, asm_1_2771_n_fl_sz_back		; Hyp.cls 3503
            ld hl, 0		; Hyp.cls 3504
            ld (asm_1_2771_n_fl_cnt), hl		; Hyp.cls 3505
asm_1_2771_n_fl_sz_lp:		; Hyp.cls 3506
            call asm_1_2771_n_fl_rdrec		; Hyp.cls 3507
            jr z, asm_1_2771_n_fl_sz_end		; Hyp.cls 3508
            ld hl, (asm_1_2771_n_fl_cnt)		; Hyp.cls 3509
            inc hl		; Hyp.cls 3510
            ld (asm_1_2771_n_fl_cnt), hl		; Hyp.cls 3511
            cp 128		; Hyp.cls 3512
            jr z, asm_1_2771_n_fl_sz_lp		; Hyp.cls 3513
asm_1_2771_n_fl_sz_end:		; Hyp.cls 3514
            call asm_1_2771_n_fl_inclose		; Hyp.cls 3515
            ld hl, (asm_1_2771_n_fl_cnt)		; Hyp.cls 3516
            call asm_1_2771_n_fl_ranput		; Hyp.cls 3517
            xor a		; Hyp.cls 3518
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 3519
asm_1_2771_n_fl_sz_back:		; Hyp.cls 3520
            ld a, (asm_1_2771_n_fl_had)		; Hyp.cls 3521
            or a		; Hyp.cls 3522
            jp z, asm_1_2771_n_fp_done		; Hyp.cls 3523
            ld hl, asm_1_2771_n_fl_inname        ; the slot's read file again, on to its record [3524]
            ld de, asm_1_2771_n_fl_name_s		; Hyp.cls 3525
            ld bc, asm_1_2771_n_FL_NL		; Hyp.cls 3526
            ldir		; Hyp.cls 3527
            call asm_1_2771_n_fl_inopen		; Hyp.cls 3528
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 3529
            ld a, (asm_1_2771_n_fl_slot)		; Hyp.cls 3530
            ld (var_hyp_fin), a		; Hyp.cls 3531
            ld hl, (asm_1_2771_n_fl_inrec)		; Hyp.cls 3532
asm_1_2771_n_fl_sz_skip:		; Hyp.cls 3533
            ld a, h		; Hyp.cls 3534
            or l		; Hyp.cls 3535
            jp z, asm_1_2771_n_fp_done		; Hyp.cls 3536
            push hl		; Hyp.cls 3537
            call asm_1_2771_n_fl_rdrec		; Hyp.cls 3538
            pop hl		; Hyp.cls 3539
            dec hl		; Hyp.cls 3540
            jr asm_1_2771_n_fl_sz_skip		; Hyp.cls 3541
; ---- 36: set the random record (r0-r2) from where the file is: the next record read or
; written; a file not open here: from the FCB's extent and record (ex * 128 + cr)
asm_1_2771_n_fl_setran:		; Hyp.cls 3544
            call asm_1_2771_n_fl_isin		; Hyp.cls 3545
            ld hl, (asm_1_2771_n_fl_inrec)		; Hyp.cls 3546
            jr z, asm_1_2771_n_fl_sr_put		; Hyp.cls 3547
            call asm_1_2771_n_fl_isout		; Hyp.cls 3548
            ld hl, (asm_1_2771_n_fl_outrec)		; Hyp.cls 3549
            jr z, asm_1_2771_n_fl_sr_put		; Hyp.cls 3550
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3551
            ld de, 32		; Hyp.cls 3552
            add hl, de		; Hyp.cls 3553
            call asm_1_2771_n_fl_peek            ; cr [3554]
            ld e, a		; Hyp.cls 3555
            ld bc, -20		; Hyp.cls 3556
            add hl, bc		; Hyp.cls 3557
            call asm_1_2771_n_fl_peek            ; ex [3558]
            ld h, a		; Hyp.cls 3559
            srl h		; Hyp.cls 3560
            ld a, e		; Hyp.cls 3561
            jr nc, asm_1_2771_n_fl_sr_lo		; Hyp.cls 3562
            or #80		; Hyp.cls 3563
asm_1_2771_n_fl_sr_lo:		; Hyp.cls 3564
            ld l, a		; Hyp.cls 3565
asm_1_2771_n_fl_sr_put:		; Hyp.cls 3566
            call asm_1_2771_n_fl_ranput		; Hyp.cls 3567
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3568
; ---- 17 / 18: search the folder (UniDOS: the FCB's drive's, else the slot's) for BDOS 17's
; name ("?" any character; kept at SRCH in the bank, SRCH + 12 the entries passed - 18 goes on
; from there): the next one, as a CP/M directory entry at the DMA (its record count from its
; length, 128 at most). 17 examines the folder (Ctrl J) into the hypervisor's page (#6000-#7BFF:
; 112 entries at most), then 17 and 18 look there. No UniDOS (or an AMSDOS floppy): none (255)
asm_1_2771_n_fl_srch1:		; Hyp.cls 3574
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3575
            ld de, 63216		; Hyp.cls 3576
            ld b, 12		; Hyp.cls 3577
asm_1_2771_n_fl_s1_lp:		; Hyp.cls 3578
            call asm_1_2771_n_fl_peek		; Hyp.cls 3579
            ex de, hl		; Hyp.cls 3580
            call asm_1_2771_n_fl_poke		; Hyp.cls 3581
            ex de, hl		; Hyp.cls 3582
            inc hl		; Hyp.cls 3583
            inc de		; Hyp.cls 3584
            djnz asm_1_2771_n_fl_s1_lp		; Hyp.cls 3585
            ex de, hl		; Hyp.cls 3586
            xor a		; Hyp.cls 3587
            call asm_1_2771_n_fl_poke            ; none passed [3588]
            xor a		; Hyp.cls 3589
            ld (asm_1_2771_n_fl_cn), a		; Hyp.cls 3590
            ld hl, #6000		; Hyp.cls 3591
            ld (asm_1_2771_n_fl_at), hl		; Hyp.cls 3592
            ld de, asm_1_2771_n_fl_name_s + 1    ; "B:" (or B's path) [3593]
            ld hl, 63216		; Hyp.cls 3594
            call asm_1_2771_n_fl_peek		; Hyp.cls 3595
            or a		; Hyp.cls 3596
            jr z, asm_1_2771_n_fl_s_own		; Hyp.cls 3597
            add a, 64		; Hyp.cls 3598
            jr asm_1_2771_n_fl_s_drv		; Hyp.cls 3599
asm_1_2771_n_fl_s_own:		; Hyp.cls 3600
            ld a, (var_hyp_filecall_drive)		; Hyp.cls 3601
            or a		; Hyp.cls 3602
            jr z, asm_1_2771_n_fl_s_nod		; Hyp.cls 3603
asm_1_2771_n_fl_s_drv:		; Hyp.cls 3604
            call asm_1_2771_n_fl_pfx		; Hyp.cls 3605
asm_1_2771_n_fl_s_nod:		; Hyp.cls 3606
; UniDOS: the directory itself (Ctrl J examine), its files into the cache - no file opened (so
; not held up by another slot's reading)
            push de		; Hyp.cls 3609
            call asm_1_2771_n_fl_exdir		; Hyp.cls 3610
            pop de		; Hyp.cls 3611
            jp nz, asm_1_2771_n_fp_done          ; (none to list: no UniDOS, an AMSDOS floppy - 255) [3612]
asm_1_2771_n_fl_sx_lp:		; Hyp.cls 3613
            ld hl, (asm_1_2771_n_fl_at)		; Hyp.cls 3614
            inc hl                  ; (the name straight into the entry) [3615]
            ld ix, asm_1_2771_n_FL_DATE		; Hyp.cls 3616
            ld c, 13                ; examine next [3617]
            call asm_1_2771_n_fl_cjc		; Hyp.cls 3618
            jr nc, asm_1_2771_n_fl_sx_end		; Hyp.cls 3619
            jr nz, asm_1_2771_n_fl_sx_end		; Hyp.cls 3620
            bit 4, a		; Hyp.cls 3621
            jr nz, asm_1_2771_n_fl_sx_lp         ; (a folder: not for CP/M) [3622]
            ld hl, (asm_1_2771_n_fl_at)		; Hyp.cls 3623
            ld (hl), 1              ; in use [3624]
            ld a, b		; Hyp.cls 3625
            or c		; Hyp.cls 3626
            jr z, asm_1_2771_n_fl_sx_sz		; Hyp.cls 3627
            ld de, #FFFF            ; (64K or more) [3628]
asm_1_2771_n_fl_sx_sz:		; Hyp.cls 3629
            ld bc, 12		; Hyp.cls 3630
            add hl, bc		; Hyp.cls 3631
            ld (hl), b              ; kind, flags 0 [3632]
            inc hl		; Hyp.cls 3633
            ld (hl), b		; Hyp.cls 3634
            inc hl		; Hyp.cls 3635
            ld (hl), e              ; its length [3636]
            inc hl		; Hyp.cls 3637
            ld (hl), d		; Hyp.cls 3638
            ld hl, (asm_1_2771_n_fl_at)		; Hyp.cls 3639
            ld bc, 64		; Hyp.cls 3640
            add hl, bc		; Hyp.cls 3641
            ld (asm_1_2771_n_fl_at), hl		; Hyp.cls 3642
            ld hl, asm_1_2771_n_fl_cn		; Hyp.cls 3643
            inc (hl)		; Hyp.cls 3644
            ld a, (hl)		; Hyp.cls 3645
            cp asm_1_2771_n_FL_CMAX		; Hyp.cls 3646
            jr c, asm_1_2771_n_fl_sx_lp		; Hyp.cls 3647
asm_1_2771_n_fl_sx_end:		; Hyp.cls 3648
            jp asm_1_2771_n_fl_srch		; Hyp.cls 3649
asm_1_2771_n_fl_srch:		; Hyp.cls 3650
            ld hl, 63216 + 12		; Hyp.cls 3651
            call asm_1_2771_n_fl_peek		; Hyp.cls 3652
            ld (asm_1_2771_n_fl_skip), a		; Hyp.cls 3653
            xor a		; Hyp.cls 3654
            ld (asm_1_2771_n_fl_k), a		; Hyp.cls 3655
asm_1_2771_n_fl_s_lp:		; Hyp.cls 3656
            ld a, (asm_1_2771_n_fl_cn)           ; the next entry, from the cache [3657]
            ld b, a		; Hyp.cls 3658
            ld a, (asm_1_2771_n_fl_k)		; Hyp.cls 3659
            cp b		; Hyp.cls 3660
            jp nc, asm_1_2771_n_fp_done          ; (none: 255) [3661]
            ld l, a		; Hyp.cls 3662
            ld h, 0		; Hyp.cls 3663
            add hl, hl		; Hyp.cls 3664
            add hl, hl		; Hyp.cls 3665
            add hl, hl		; Hyp.cls 3666
            add hl, hl		; Hyp.cls 3667
            add hl, hl		; Hyp.cls 3668
            add hl, hl		; Hyp.cls 3669
            ld de, #6000		; Hyp.cls 3670
            add hl, de		; Hyp.cls 3671
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3672
            ld bc, 64		; Hyp.cls 3673
            ldir		; Hyp.cls 3674
            ld hl, asm_1_2771_n_fl_k		; Hyp.cls 3675
            inc (hl)		; Hyp.cls 3676
            ld a, (asm_1_2771_n_fl_skip)		; Hyp.cls 3677
            cp (hl)		; Hyp.cls 3678
            jr nc, asm_1_2771_n_fl_s_lp          ; passed already [3679]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3680
            ld a, (hl)		; Hyp.cls 3681
            dec a		; Hyp.cls 3682
            jr nz, asm_1_2771_n_fl_s_lp          ; not in use (1) [3683]
            inc hl		; Hyp.cls 3684
            ld de, 63216 + 1		; Hyp.cls 3685
            ld b, 11		; Hyp.cls 3686
asm_1_2771_n_fl_s_cmp:		; Hyp.cls 3687
            ex de, hl		; Hyp.cls 3688
            call asm_1_2771_n_fl_peek		; Hyp.cls 3689
            ex de, hl		; Hyp.cls 3690
            and #7F		; Hyp.cls 3691
            cp '?'		; Hyp.cls 3692
            jr z, asm_1_2771_n_fl_s_any		; Hyp.cls 3693
            ld c, a		; Hyp.cls 3694
            ld a, (hl)		; Hyp.cls 3695
            and #7F		; Hyp.cls 3696
            cp c		; Hyp.cls 3697
            jr nz, asm_1_2771_n_fl_s_lp		; Hyp.cls 3698
asm_1_2771_n_fl_s_any:		; Hyp.cls 3699
            inc hl		; Hyp.cls 3700
            inc de		; Hyp.cls 3701
            djnz asm_1_2771_n_fl_s_cmp		; Hyp.cls 3702
            ld hl, (var_hyp_filecall_buf)          ; the entry: user 0, the name, extent 0, the records, no blocks [3703]
            ld (hl), 0		; Hyp.cls 3704
            ld de, 14		; Hyp.cls 3705
            add hl, de		; Hyp.cls 3706
            ld e, (hl)		; Hyp.cls 3707
            inc hl		; Hyp.cls 3708
            ld d, (hl)		; Hyp.cls 3709
            ex de, hl		; Hyp.cls 3710
            ld bc, 127		; Hyp.cls 3711
            add hl, bc		; Hyp.cls 3712
            jr c, asm_1_2771_n_fl_s_big		; Hyp.cls 3713
            ld a, h		; Hyp.cls 3714
            cp #40		; Hyp.cls 3715
            jr nc, asm_1_2771_n_fl_s_big		; Hyp.cls 3716
            sla l		; Hyp.cls 3717
            rla		; Hyp.cls 3718
            jr asm_1_2771_n_fl_s_rc		; Hyp.cls 3719
asm_1_2771_n_fl_s_big:		; Hyp.cls 3720
            ld a, 128		; Hyp.cls 3721
asm_1_2771_n_fl_s_rc:		; Hyp.cls 3722
            ex de, hl		; Hyp.cls 3723
            ld (hl), a		; Hyp.cls 3724
            ld b, 3		; Hyp.cls 3725
asm_1_2771_n_fl_s_z1:		; Hyp.cls 3726
            dec hl		; Hyp.cls 3727
            ld (hl), 0		; Hyp.cls 3728
            djnz asm_1_2771_n_fl_s_z1		; Hyp.cls 3729
            ld de, 4		; Hyp.cls 3730
            add hl, de		; Hyp.cls 3731
            ld b, 16		; Hyp.cls 3732
asm_1_2771_n_fl_s_z2:		; Hyp.cls 3733
            ld (hl), 0		; Hyp.cls 3734
            inc hl		; Hyp.cls 3735
            djnz asm_1_2771_n_fl_s_z2		; Hyp.cls 3736
            ld hl, (var_hyp_filecall_dma)		; Hyp.cls 3737
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3738
            ld b, 32		; Hyp.cls 3739
asm_1_2771_n_fl_s_put:		; Hyp.cls 3740
            ld a, (de)		; Hyp.cls 3741
            call asm_1_2771_n_fl_poke		; Hyp.cls 3742
            inc hl		; Hyp.cls 3743
            inc de		; Hyp.cls 3744
            djnz asm_1_2771_n_fl_s_put		; Hyp.cls 3745
            ld hl, 63216 + 12		; Hyp.cls 3746
            ld a, (asm_1_2771_n_fl_k)		; Hyp.cls 3747
            call asm_1_2771_n_fl_poke		; Hyp.cls 3748
            jp asm_1_2771_n_fl_ok		; Hyp.cls 3749
asm_1_2771_n_fl_skip:    db 0		; Hyp.cls 3750
asm_1_2771_n_fl_k:       db 0		; Hyp.cls 3751
asm_1_2771_n_fl_cn:      db 0                    ; the folder's entries in the cache (#6000) [3752]
asm_1_2771_n_fl_ranput:                          ; the FCB's r0-r2 = HL [3753]
            ex de, hl		; Hyp.cls 3754
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3755
            ld bc, 33		; Hyp.cls 3756
            add hl, bc		; Hyp.cls 3757
            ld a, e		; Hyp.cls 3758
            call asm_1_2771_n_fl_poke		; Hyp.cls 3759
            inc hl		; Hyp.cls 3760
            ld a, d		; Hyp.cls 3761
            call asm_1_2771_n_fl_poke		; Hyp.cls 3762
            inc hl		; Hyp.cls 3763
            xor a		; Hyp.cls 3764
            jp asm_1_2771_n_fl_poke		; Hyp.cls 3765
; ---- the parts
asm_1_2771_n_fl_inopen:                          ; open fl_name_s to read: carry = done [3767]
            call asm_1_2771_n_fl_plain		; Hyp.cls 3768
            ld hl, asm_1_2771_n_fl_name_s + 1		; Hyp.cls 3769
            ld a, (asm_1_2771_n_fl_name_s)		; Hyp.cls 3770
            ld b, a		; Hyp.cls 3771
            ld de, #4000		; Hyp.cls 3772
            call #BC77              ; CAS IN OPEN [3773]
            di		; Hyp.cls 3774
            ld (asm_1_2771_n_fl_hdr), hl         ; (its header: BDOS 30 #C7) [3775]
            ret		; Hyp.cls 3776
asm_1_2771_n_fl_inclose:		; Hyp.cls 3777
            xor a		; Hyp.cls 3778
            ld (var_hyp_fin), a		; Hyp.cls 3779
            call asm_1_2771_n_fl_plain		; Hyp.cls 3780
            call #BC7A              ; CAS IN CLOSE [3781]
            di		; Hyp.cls 3782
            ret		; Hyp.cls 3783
asm_1_2771_n_fl_rdrec:                           ; read up to fl_n bytes (128) into buf: A = how many (Z [3784]
            call asm_1_2771_n_fl_plain           ; none), HL past them. A #1A is a byte (the soft end of file) [3785]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3786
            ld a, (asm_1_2771_n_fl_n)		; Hyp.cls 3787
            ld b, a		; Hyp.cls 3788
asm_1_2771_n_fl_rr_lp:		; Hyp.cls 3789
            push bc		; Hyp.cls 3790
            push hl		; Hyp.cls 3791
            call #BC80              ; CAS IN CHAR [3792]
            di		; Hyp.cls 3793
            pop hl		; Hyp.cls 3794
            pop bc		; Hyp.cls 3795
            jr c, asm_1_2771_n_fl_rr_b		; Hyp.cls 3796
            cp #1A		; Hyp.cls 3797
            jr nz, asm_1_2771_n_fl_rr_end		; Hyp.cls 3798
asm_1_2771_n_fl_rr_b:		; Hyp.cls 3799
            ld (hl), a		; Hyp.cls 3800
            inc hl		; Hyp.cls 3801
            djnz asm_1_2771_n_fl_rr_lp		; Hyp.cls 3802
asm_1_2771_n_fl_rr_end:		; Hyp.cls 3803
            ld a, (asm_1_2771_n_fl_n)		; Hyp.cls 3804
            sub b		; Hyp.cls 3805
            ld c, a		; Hyp.cls 3806
            ld a, 128		; Hyp.cls 3807
            ld (asm_1_2771_n_fl_n), a            ; (128 again for the next) [3808]
            ld a, c		; Hyp.cls 3809
            or a		; Hyp.cls 3810
            ret		; Hyp.cls 3811
asm_1_2771_n_fl_fits:                            ; HL = a slot address, BC = bytes: NC = all in its 16K page. [3812]
            push hl                 ; Keeps BC, DE, HL [3813]
            ld a, h		; Hyp.cls 3814
            and #3F		; Hyp.cls 3815
            ld h, a		; Hyp.cls 3816
            add hl, bc		; Hyp.cls 3817
            ld a, h		; Hyp.cls 3818
            cp #40		; Hyp.cls 3819
            jr c, asm_1_2771_n_fl_ft_ok		; Hyp.cls 3820
            jr nz, asm_1_2771_n_fl_ft_no		; Hyp.cls 3821
            ld a, l		; Hyp.cls 3822
            or a		; Hyp.cls 3823
            jr nz, asm_1_2771_n_fl_ft_no		; Hyp.cls 3824
asm_1_2771_n_fl_ft_ok:		; Hyp.cls 3825
            pop hl		; Hyp.cls 3826
            or a		; Hyp.cls 3827
            ret		; Hyp.cls 3828
asm_1_2771_n_fl_ft_no:		; Hyp.cls 3829
            pop hl		; Hyp.cls 3830
            scf		; Hyp.cls 3831
            ret		; Hyp.cls 3832
asm_1_2771_n_fl_plain:                           ; the hypervisor's page in the window (the buffers) [3833]
            ld bc, (var_hyp_hps)		; Hyp.cls 3834
            out (c), c		; Hyp.cls 3835
            ret		; Hyp.cls 3836
asm_1_2771_n_fl_name:                            ; fl_name_s = the FCB's file: length, "B:NAME.EXT" [3837]
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3838
asm_1_2771_n_fl_namehl:                          ; (HL = an FCB in the slot) [3839]
            ld de, asm_1_2771_n_fl_name_s + 1		; Hyp.cls 3840
            call asm_1_2771_n_fl_peek            ; its drive: 0 = the slot's (or fl_dfl's) [3841]
            or a		; Hyp.cls 3842
            jr nz, asm_1_2771_n_fl_nm_d		; Hyp.cls 3843
            ld a, (asm_1_2771_n_fl_dfl)		; Hyp.cls 3844
            or a		; Hyp.cls 3845
            jr nz, asm_1_2771_n_fl_nm_d		; Hyp.cls 3846
            ld a, (var_hyp_filecall_drive)		; Hyp.cls 3847
            or a		; Hyp.cls 3848
            jr z, asm_1_2771_n_fl_nm_nod		; Hyp.cls 3849
            sub 64		; Hyp.cls 3850
asm_1_2771_n_fl_nm_d:		; Hyp.cls 3851
            add a, 64		; Hyp.cls 3852
            call asm_1_2771_n_fl_pfx             ; "B:", or B's path (UniDOS: "IDE:GAMES/") [3853]
asm_1_2771_n_fl_nm_nod:		; Hyp.cls 3854
            ld b, 11		; Hyp.cls 3855
asm_1_2771_n_fl_nm_lp:		; Hyp.cls 3856
            inc hl		; Hyp.cls 3857
            ld a, b		; Hyp.cls 3858
            cp 3		; Hyp.cls 3859
            jr nz, asm_1_2771_n_fl_nm_c		; Hyp.cls 3860
            ld a, '.'		; Hyp.cls 3861
            ld (de), a		; Hyp.cls 3862
            inc de		; Hyp.cls 3863
asm_1_2771_n_fl_nm_c:		; Hyp.cls 3864
            call asm_1_2771_n_fl_peek		; Hyp.cls 3865
            and #7F		; Hyp.cls 3866
            cp ' ' + 1		; Hyp.cls 3867
            jr c, asm_1_2771_n_fl_nm_sk		; Hyp.cls 3868
            ld (de), a		; Hyp.cls 3869
            inc de		; Hyp.cls 3870
asm_1_2771_n_fl_nm_sk:		; Hyp.cls 3871
            djnz asm_1_2771_n_fl_nm_lp		; Hyp.cls 3872
            ex de, hl		; Hyp.cls 3873
            ld de, asm_1_2771_n_fl_name_s + 1		; Hyp.cls 3874
            or a		; Hyp.cls 3875
            sbc hl, de		; Hyp.cls 3876
            ld a, l		; Hyp.cls 3877
            ld (asm_1_2771_n_fl_name_s), a		; Hyp.cls 3878
            ret		; Hyp.cls 3879
asm_1_2771_n_fl_ok:		; Hyp.cls 3880
            xor a		; Hyp.cls 3881
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 3882
asm_1_2771_n_fp_done:                            ; back to FileCall in main RAM (fp_done) [3883]
            ld sp, (asm_1_2771_n_fp_sp)		; Hyp.cls 3884
            ret		; Hyp.cls 3885
asm_1_2771_n_fl_era:     db "ER", "A" + #80		; Hyp.cls 3886
asm_1_2771_n_fl_rencmd:  db "RE", "N" + #80		; Hyp.cls 3887
asm_1_2771_n_fl_par2:    dw asm_1_2771_n_fl_desc, asm_1_2771_n_fl_desc2		; Hyp.cls 3888
asm_1_2771_n_fl_desc2:   db 0		; Hyp.cls 3889
            dw 0		; Hyp.cls 3890
asm_1_2771_n_fl_dfl:     db 0                    ; fl_name: the drive for an FCB whose own is 0 (rename) [3891]
asm_1_2771_n_fl_par:     dw asm_1_2771_n_fl_desc		; Hyp.cls 3892
asm_1_2771_n_fl_desc:    db 0		; Hyp.cls 3893
            dw 0		; Hyp.cls 3894
asm_1_2771_n_fl_n:       db 128                  ; bytes fl_rdrec reads [3895]
asm_1_2771_n_fl_cnt:     dw 0		; Hyp.cls 3896
asm_1_2771_n_fl_at:      dw 0		; Hyp.cls 3897
asm_1_2771_n_fl_infcb:   dw 0		; Hyp.cls 3898
            db 0                    ; (1: fl_infcb the open's - fl_is) [3899]
asm_1_2771_n_fl_inrec:   dw 0		; Hyp.cls 3900
asm_1_2771_n_fl_want:    dw 0		; Hyp.cls 3901
asm_1_2771_n_fl_outfcb:  dw 0		; Hyp.cls 3902
            db 0		; Hyp.cls 3903
asm_1_2771_n_fl_outrec:  dw 0                    ; the next record written (36) [3904]
asm_1_2771_n_fl_had:     db 0                    ; 35: this slot's read file closed for it [3905]
asm_1_2771_n_fp_sp:      dw 0		; Hyp.cls 3906
; ---- UniDOS: its Ctrl J BIOS command (found once, KL FIND COMMAND) - a drive letter can be a
; path (CD IDE:, CD SD:GAMES ...: any UniDOS device's folder), folders listed (examine). FL_MAP:
; letters A-P, 32 bytes each: the path's length (0 none: the letter itself, "B:"), the path
; ("IDE:GAMES/": a device or logical drive, its folders, the last "/" or ":"). Cleared when
; UniDOS is found, and only set with it: with AMSDOS no letter has a path. Up there with the
; names (48 characters: a path and NAME.EXT), BDOS 132's block, DIR's listing: the FILES.DIR
; cache is #6000-#7BFF (112 entries)
asm_1_2771_n_FL_CMAX:    equ 112                 ; the cache's entries [3914]
asm_1_2771_n_FL_NL:      equ 49                  ; a name: its length, then the characters [3915]
asm_1_2771_n_fl_name_s:  equ #7C00               ; length, then "B:NAME.EXT" (or "IDE:GAMES/NAME.EXT") [3916]
asm_1_2771_n_fl_inname:  equ asm_1_2771_n_fl_name_s + asm_1_2771_n_FL_NL   ; the one being read's (33 going back) [3917]
asm_1_2771_n_fl_new_s:   equ asm_1_2771_n_fl_inname + asm_1_2771_n_FL_NL   ; (23: the new name) [3918]
asm_1_2771_n_FL_UB:      equ #7D00               ; BDOS 132's block (72 bytes) [3919]
asm_1_2771_n_FL_EXK:     equ #7D48               ; the folder DIR lists (its path: length, 31 characters) [3920]
asm_1_2771_n_FL_DATE:    equ #7D68               ; a date examine gives (7), then a name (11) [3921]
asm_1_2771_n_FL_TN:      equ #7D70		; Hyp.cls 3922
asm_1_2771_n_FL_MAP:     equ #7E00		; Hyp.cls 3923
            ASSERT #6000 + asm_1_2771_n_FL_CMAX * 64 <= asm_1_2771_n_fl_name_s, "the search's cache, below the names"		; Hyp.cls 3924
            ASSERT asm_1_2771_n_fl_new_s + asm_1_2771_n_FL_NL <= asm_1_2771_n_FL_UB, "the names, below BDOS 132's block"		; Hyp.cls 3925
            ASSERT (asm_1_2771_n_FL_MAP & 255) = 0, "asm_1_2771_n_FL_MAP: a page's start (asm_1_2771_n_fl_mapa)"		; Hyp.cls 3926
asm_1_2771_n_fl_cjf:     db 0                    ; 0: not looked for yet, 1: UniDOS, 2: none [3927]
asm_1_2771_n_fl_cj:      dw 0                    ; Ctrl J's far address (address, ROM) [3928]
            db 0		; Hyp.cls 3929
asm_1_2771_n_fl_cjn:     db #8A                  ; (its name) [3930]
asm_1_2771_n_fl_exv:     db 0                    ; FL_EXK's listing is the one UniDOS examines now ... [3931]
asm_1_2771_n_fl_exi:     dw 0                    ; ... at this entry next [3932]
asm_1_2771_n_fl_ue:      dw 0		; Hyp.cls 3933
; carry: UniDOS here (the first time: looked for, the paths cleared)
asm_1_2771_n_fl_uni:		; Hyp.cls 3935
            ld a, (asm_1_2771_n_fl_cjf)		; Hyp.cls 3936
            cp 1		; Hyp.cls 3937
            jr z, asm_1_2771_n_fl_un_y		; Hyp.cls 3938
            or a		; Hyp.cls 3939
            ret nz                  ; (2: none - NC) [3940]
            ld hl, asm_1_2771_n_fl_cjn		; Hyp.cls 3941
            call #BCD4              ; KL FIND COMMAND: C = its ROM, HL = its address [3942]
            di		; Hyp.cls 3943
            ld a, 2		; Hyp.cls 3944
            jr nc, asm_1_2771_n_fl_un_s		; Hyp.cls 3945
            ld (asm_1_2771_n_fl_cj), hl		; Hyp.cls 3946
            ld a, c		; Hyp.cls 3947
            ld (asm_1_2771_n_fl_cj + 2), a		; Hyp.cls 3948
            ld hl, asm_1_2771_n_FL_MAP		; Hyp.cls 3949
            ld de, asm_1_2771_n_FL_MAP + 1		; Hyp.cls 3950
            ld bc, 511		; Hyp.cls 3951
            ld (hl), 0		; Hyp.cls 3952
            ldir		; Hyp.cls 3953
            ld a, 1		; Hyp.cls 3954
asm_1_2771_n_fl_un_s:		; Hyp.cls 3955
            ld (asm_1_2771_n_fl_cjf), a		; Hyp.cls 3956
            jr asm_1_2771_n_fl_uni		; Hyp.cls 3957
asm_1_2771_n_fl_un_y:		; Hyp.cls 3958
            scf		; Hyp.cls 3959
            ret		; Hyp.cls 3960
; Ctrl J command C (the other registers its input; its output back)
asm_1_2771_n_fl_cjc:		; Hyp.cls 3962
            rst #18                 ; (RST 3: a far call) [3963]
            dw asm_1_2771_n_fl_cj		; Hyp.cls 3964
            di		; Hyp.cls 3965
            ret		; Hyp.cls 3966
; A = a drive letter: HL = its FL_MAP entry, A = its path's length (Z: none). Carry: not A-P,
; or no UniDOS (no paths). A, HL only
asm_1_2771_n_fl_mapa:		; Hyp.cls 3969
            sub 'A'		; Hyp.cls 3970
            cp 16		; Hyp.cls 3971
            ccf		; Hyp.cls 3972
            ret c		; Hyp.cls 3973
            ld l, a		; Hyp.cls 3974
            ld a, (asm_1_2771_n_fl_cjf)		; Hyp.cls 3975
            cp 1		; Hyp.cls 3976
            scf		; Hyp.cls 3977
            ret nz		; Hyp.cls 3978
            ld h, 0		; Hyp.cls 3979
            add hl, hl		; Hyp.cls 3980
            add hl, hl		; Hyp.cls 3981
            add hl, hl		; Hyp.cls 3982
            add hl, hl		; Hyp.cls 3983
            add hl, hl		; Hyp.cls 3984
            ld a, h		; Hyp.cls 3985
            add a, asm_1_2771_n_FL_MAP / 256		; Hyp.cls 3986
            ld h, a		; Hyp.cls 3987
            ld a, (hl)		; Hyp.cls 3988
            or a		; Hyp.cls 3989
            ret		; Hyp.cls 3990
; A = a drive letter: "B:" at DE, or its path - DE past it (BC, HL kept)
asm_1_2771_n_fl_pfx:		; Hyp.cls 3992
            push af		; Hyp.cls 3993
            call asm_1_2771_n_fl_pfxm		; Hyp.cls 3994
            jr nz, asm_1_2771_n_fl_px_d		; Hyp.cls 3995
            pop af		; Hyp.cls 3996
            ld (de), a		; Hyp.cls 3997
            inc de		; Hyp.cls 3998
            ld a, ':'		; Hyp.cls 3999
            ld (de), a		; Hyp.cls 4000
            inc de		; Hyp.cls 4001
            ret		; Hyp.cls 4002
asm_1_2771_n_fl_px_d:		; Hyp.cls 4003
            pop af		; Hyp.cls 4004
            ret		; Hyp.cls 4005
; ... its path only, if it has one (NZ; Z: none, nothing put)
asm_1_2771_n_fl_pfxm:		; Hyp.cls 4007
            push hl		; Hyp.cls 4008
            call asm_1_2771_n_fl_mapa		; Hyp.cls 4009
            jr c, asm_1_2771_n_fl_pm_no		; Hyp.cls 4010
            jr z, asm_1_2771_n_fl_pm_no		; Hyp.cls 4011
            push bc		; Hyp.cls 4012
            ld c, a		; Hyp.cls 4013
            ld b, 0		; Hyp.cls 4014
            inc hl		; Hyp.cls 4015
            ldir		; Hyp.cls 4016
            pop bc		; Hyp.cls 4017
            or a		; Hyp.cls 4018
            jr asm_1_2771_n_fl_pm_r		; Hyp.cls 4019
asm_1_2771_n_fl_pm_no:		; Hyp.cls 4020
            xor a		; Hyp.cls 4021
asm_1_2771_n_fl_pm_r:		; Hyp.cls 4022
            pop hl		; Hyp.cls 4023
            ret		; Hyp.cls 4024
asm_1_2771_n_fl_nlen:                            ; fl_name_s's length: its characters end at DE [4025]
            ld hl, -(asm_1_2771_n_fl_name_s + 1)		; Hyp.cls 4026
            add hl, de		; Hyp.cls 4027
            ld a, l		; Hyp.cls 4028
            ld (asm_1_2771_n_fl_name_s), a		; Hyp.cls 4029
            ret		; Hyp.cls 4030
; the folder whose path is at fl_name_s + 1 to DE (fl_exdir2: fl_name_s, its length set)
; examined (Ctrl J 12): Z its listing ready (examine next: Ctrl J 13), NZ no UniDOS, a drive
; it can't examine (AMSDOS's floppies), not a folder
asm_1_2771_n_fl_exdir:		; Hyp.cls 4034
            call asm_1_2771_n_fl_nlen		; Hyp.cls 4035
asm_1_2771_n_fl_exdir2:		; Hyp.cls 4036
            call asm_1_2771_n_fl_uni		; Hyp.cls 4037
            jr nc, asm_1_2771_n_fl_ed_no		; Hyp.cls 4038
            xor a		; Hyp.cls 4039
            ld (asm_1_2771_n_fl_exv), a		; Hyp.cls 4040
            ld hl, asm_1_2771_n_fl_name_s		; Hyp.cls 4041
            ld b, (hl)		; Hyp.cls 4042
            inc hl		; Hyp.cls 4043
            ld ix, asm_1_2771_n_FL_DATE		; Hyp.cls 4044
            ld c, 12		; Hyp.cls 4045
            call asm_1_2771_n_fl_cjc		; Hyp.cls 4046
            ret c		; Hyp.cls 4047
asm_1_2771_n_fl_ed_no:		; Hyp.cls 4048
            ld a, 254               ; (254: no UniDOS, or a drive it can't examine) [4049]
            or a		; Hyp.cls 4050
            ret		; Hyp.cls 4051
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
asm_1_2771_n_fl_unicall:		; Hyp.cls 4075
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4076
            ld de, asm_1_2771_n_FL_UB		; Hyp.cls 4077
            ld b, 72		; Hyp.cls 4078
asm_1_2771_n_fl_uc_in:		; Hyp.cls 4079
            call asm_1_2771_n_fl_peek		; Hyp.cls 4080
            ld (de), a		; Hyp.cls 4081
            inc hl		; Hyp.cls 4082
            inc de		; Hyp.cls 4083
            djnz asm_1_2771_n_fl_uc_in		; Hyp.cls 4084
            ld a, (asm_1_2771_n_FL_UB)		; Hyp.cls 4085
            sub #C0		; Hyp.cls 4086
            cp 9		; Hyp.cls 4087
            jp nc, asm_1_2771_n_fp_done          ; (CP/M's 30) [4088]
            ld (asm_1_2771_n_FL_UB), a		; Hyp.cls 4089
            call asm_1_2771_n_fl_uni		; Hyp.cls 4090
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 4091
            ld a, (asm_1_2771_n_FL_UB)		; Hyp.cls 4092
            or a		; Hyp.cls 4093
            jp z, asm_1_2771_n_fl_ok		; Hyp.cls 4094
            dec a		; Hyp.cls 4095
            jp z, asm_1_2771_n_fl_uc_get		; Hyp.cls 4096
            dec a		; Hyp.cls 4097
            jp z, asm_1_2771_n_fl_uc_set		; Hyp.cls 4098
            dec a		; Hyp.cls 4099
            jp z, asm_1_2771_n_fl_uc_dev		; Hyp.cls 4100
            dec a		; Hyp.cls 4101
            jp z, asm_1_2771_n_fl_uc_inf		; Hyp.cls 4102
            dec a		; Hyp.cls 4103
            jp z, asm_1_2771_n_fl_uc_dir		; Hyp.cls 4104
            dec a		; Hyp.cls 4105
            jr z, asm_1_2771_n_fl_uc_md		; Hyp.cls 4106
            cp 2		; Hyp.cls 4107
            jr z, asm_1_2771_n_fl_uc_yes		; Hyp.cls 4108
            ld a, (var_hyp_fin)           ; 7: the header of the file this slot reads (the disc ROM's, [4109]
            ld hl, asm_1_2771_n_fl_slot          ; from CAS IN OPEN: 69 bytes) to Byte(2) [4110]
            cp (hl)		; Hyp.cls 4111
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 4112
            ld hl, (asm_1_2771_n_fl_hdr)		; Hyp.cls 4113
            ld de, asm_1_2771_n_FL_UB + 2		; Hyp.cls 4114
            ld bc, 69		; Hyp.cls 4115
            ldir		; Hyp.cls 4116
            xor a		; Hyp.cls 4117
            ld b, 71		; Hyp.cls 4118
            jp asm_1_2771_n_fl_uc_back		; Hyp.cls 4119
asm_1_2771_n_fl_hdr:     dw 0		; Hyp.cls 4120
asm_1_2771_n_fl_uc_yes:                          ; 8: the next delete (19) may take a folder (RMDIR's) [4121]
            ld a, 1		; Hyp.cls 4122
            ld (asm_1_2771_n_fl_yes), a		; Hyp.cls 4123
            jp asm_1_2771_n_fl_ok		; Hyp.cls 4124
asm_1_2771_n_fl_yes:     db 0		; Hyp.cls 4125
asm_1_2771_n_fl_uc_md:                           ; 6: a folder made (CAS OUT OPEN, the path ending "/") [4126]
            ld a, (var_hyp_fout)		; Hyp.cls 4127
            or a		; Hyp.cls 4128
            jp nz, asm_1_2771_n_fp_done		; Hyp.cls 4129
            ld hl, asm_1_2771_n_FL_UB + 2		; Hyp.cls 4130
            ld a, (hl)		; Hyp.cls 4131
            or a		; Hyp.cls 4132
            jp z, asm_1_2771_n_fp_done		; Hyp.cls 4133
            ld b, a		; Hyp.cls 4134
            inc hl		; Hyp.cls 4135
            ld de, #4800		; Hyp.cls 4136
            call #BC8C              ; CAS OUT OPEN [4137]
            di		; Hyp.cls 4138
            jr nc, asm_1_2771_n_fl_md_nc		; Hyp.cls 4139
            call #BC92              ; (a file: CAS OUT ABANDON - not made) [4140]
            di		; Hyp.cls 4141
            ld a, 1		; Hyp.cls 4142
            jr asm_1_2771_n_fl_md_r		; Hyp.cls 4143
asm_1_2771_n_fl_md_nc:		; Hyp.cls 4144
            and #7F		; Hyp.cls 4145
            cp #17                  ; (DSK_ERR_DIRECTORY_FOUND: made) [4146]
            jp z, asm_1_2771_n_fl_ok		; Hyp.cls 4147
            or a		; Hyp.cls 4148
            jr nz, asm_1_2771_n_fl_md_r		; Hyp.cls 4149
            inc a		; Hyp.cls 4150
asm_1_2771_n_fl_md_r:		; Hyp.cls 4151
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 4152
            jp asm_1_2771_n_fp_done		; Hyp.cls 4153
asm_1_2771_n_fl_uc_back:                         ; A the answer, the block's first B bytes back to the slot [4154]
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 4155
            ld a, (asm_1_2771_n_FL_UB)		; Hyp.cls 4156
            add a, #C0		; Hyp.cls 4157
            ld (asm_1_2771_n_FL_UB), a		; Hyp.cls 4158
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 4159
            ld de, asm_1_2771_n_FL_UB		; Hyp.cls 4160
asm_1_2771_n_fl_uc_out:		; Hyp.cls 4161
            ld a, (de)		; Hyp.cls 4162
            call asm_1_2771_n_fl_poke		; Hyp.cls 4163
            inc hl		; Hyp.cls 4164
            inc de		; Hyp.cls 4165
            djnz asm_1_2771_n_fl_uc_out		; Hyp.cls 4166
            jp asm_1_2771_n_fp_done		; Hyp.cls 4167
asm_1_2771_n_fl_uc_get:		; Hyp.cls 4168
            ld a, (asm_1_2771_n_FL_UB + 1)		; Hyp.cls 4169
            call asm_1_2771_n_fl_mapa		; Hyp.cls 4170
            jp c, asm_1_2771_n_fp_done		; Hyp.cls 4171
            ld de, asm_1_2771_n_FL_UB + 2		; Hyp.cls 4172
            ld c, (hl)		; Hyp.cls 4173
            ld b, 0		; Hyp.cls 4174
            inc bc		; Hyp.cls 4175
            ldir		; Hyp.cls 4176
            xor a		; Hyp.cls 4177
            ld b, 34		; Hyp.cls 4178
            jr asm_1_2771_n_fl_uc_back		; Hyp.cls 4179
asm_1_2771_n_fl_uc_dev:		; Hyp.cls 4180
            ld de, asm_1_2771_n_FL_UB + 2		; Hyp.cls 4181
            ld c, 1		; Hyp.cls 4182
            call asm_1_2771_n_fl_cjc		; Hyp.cls 4183
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 4184
            xor a		; Hyp.cls 4185
            ld b, 66		; Hyp.cls 4186
            jr asm_1_2771_n_fl_uc_back		; Hyp.cls 4187
asm_1_2771_n_fl_uc_inf:		; Hyp.cls 4188
            ld hl, asm_1_2771_n_FL_UB + 2		; Hyp.cls 4189
            ld de, asm_1_2771_n_FL_UB + 8		; Hyp.cls 4190
            ld c, 2		; Hyp.cls 4191
            call asm_1_2771_n_fl_cjc		; Hyp.cls 4192
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 4193
            xor a		; Hyp.cls 4194
            ld b, 72		; Hyp.cls 4195
            jr asm_1_2771_n_fl_uc_back		; Hyp.cls 4196
asm_1_2771_n_fl_uc_set:		; Hyp.cls 4197
            ld a, (asm_1_2771_n_FL_UB + 1)		; Hyp.cls 4198
            call asm_1_2771_n_fl_mapa		; Hyp.cls 4199
            jp c, asm_1_2771_n_fp_done		; Hyp.cls 4200
            ld (asm_1_2771_n_fl_ue), hl		; Hyp.cls 4201
            xor a		; Hyp.cls 4202
            ld (asm_1_2771_n_fl_exv), a		; Hyp.cls 4203
            ld a, (asm_1_2771_n_FL_UB + 2)		; Hyp.cls 4204
            or a		; Hyp.cls 4205
            jr z, asm_1_2771_n_fl_us_put         ; none: the letter itself again [4206]
            cp 32		; Hyp.cls 4207
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 4208
            ld b, a		; Hyp.cls 4209
            ld hl, asm_1_2771_n_FL_UB + 3		; Hyp.cls 4210
asm_1_2771_n_fl_us_up:                           ; capitals [4211]
            ld a, (hl)		; Hyp.cls 4212
            cp 'a'		; Hyp.cls 4213
            jr c, asm_1_2771_n_fl_us_c		; Hyp.cls 4214
            cp 'z' + 1		; Hyp.cls 4215
            jr nc, asm_1_2771_n_fl_us_c		; Hyp.cls 4216
            sub 32		; Hyp.cls 4217
            ld (hl), a		; Hyp.cls 4218
asm_1_2771_n_fl_us_c:		; Hyp.cls 4219
            inc hl		; Hyp.cls 4220
            djnz asm_1_2771_n_fl_us_up		; Hyp.cls 4221
            dec hl		; Hyp.cls 4222
            ld a, (hl)		; Hyp.cls 4223
            cp ':'		; Hyp.cls 4224
            jr z, asm_1_2771_n_fl_us_ex		; Hyp.cls 4225
            cp '/'		; Hyp.cls 4226
            jr z, asm_1_2771_n_fl_us_ex		; Hyp.cls 4227
            ld a, (asm_1_2771_n_FL_UB + 2)		; Hyp.cls 4228
            cp 31		; Hyp.cls 4229
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 4230
            inc a		; Hyp.cls 4231
            ld (asm_1_2771_n_FL_UB + 2), a		; Hyp.cls 4232
            inc hl		; Hyp.cls 4233
            ld (hl), '/'		; Hyp.cls 4234
asm_1_2771_n_fl_us_ex:		; Hyp.cls 4235
            ld hl, asm_1_2771_n_FL_UB + 2        ; a folder? [4236]
            ld de, asm_1_2771_n_fl_name_s		; Hyp.cls 4237
            ld bc, 32		; Hyp.cls 4238
            ldir		; Hyp.cls 4239
            call asm_1_2771_n_fl_exdir2		; Hyp.cls 4240
            jr z, asm_1_2771_n_fl_us_put		; Hyp.cls 4241
            cp 254		; Hyp.cls 4242
            jr z, asm_1_2771_n_fl_us_put         ; (a floppy AMSDOS runs - DFA:, DFB: - can't be examined: taken) [4243]
            or a		; Hyp.cls 4244
            jr nz, asm_1_2771_n_fl_us_err		; Hyp.cls 4245
            inc a		; Hyp.cls 4246
asm_1_2771_n_fl_us_err:		; Hyp.cls 4247
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 4248
            jp asm_1_2771_n_fp_done		; Hyp.cls 4249
asm_1_2771_n_fl_us_put:		; Hyp.cls 4250
            ld hl, asm_1_2771_n_FL_UB + 2		; Hyp.cls 4251
            ld de, (asm_1_2771_n_fl_ue)		; Hyp.cls 4252
            ld bc, 32		; Hyp.cls 4253
            ldir		; Hyp.cls 4254
            jp asm_1_2771_n_fl_ok		; Hyp.cls 4255
asm_1_2771_n_fl_uc_dir:		; Hyp.cls 4256
            ld de, asm_1_2771_n_fl_name_s + 1    ; the folder's path [4257]
            ld a, (asm_1_2771_n_FL_UB + 1)		; Hyp.cls 4258
            or a		; Hyp.cls 4259
            jr z, asm_1_2771_n_fl_ud_p		; Hyp.cls 4260
            call asm_1_2771_n_fl_pfx		; Hyp.cls 4261
            jr asm_1_2771_n_fl_ud_k		; Hyp.cls 4262
asm_1_2771_n_fl_ud_p:		; Hyp.cls 4263
            ld hl, asm_1_2771_n_FL_UB + 28		; Hyp.cls 4264
            ld a, (hl)		; Hyp.cls 4265
            cp 32		; Hyp.cls 4266
            jp nc, asm_1_2771_n_fp_done		; Hyp.cls 4267
            ld c, a		; Hyp.cls 4268
            ld b, 0		; Hyp.cls 4269
            inc hl		; Hyp.cls 4270
            ldir		; Hyp.cls 4271
asm_1_2771_n_fl_ud_k:		; Hyp.cls 4272
            call asm_1_2771_n_fl_nlen		; Hyp.cls 4273
            ld hl, asm_1_2771_n_fl_name_s        ; the same folder, still the one examined, at this entry: [4274]
            ld de, asm_1_2771_n_FL_EXK           ; on from there [4275]
            ld a, (asm_1_2771_n_fl_exv)		; Hyp.cls 4276
            or a		; Hyp.cls 4277
            jr z, asm_1_2771_n_fl_ud_new		; Hyp.cls 4278
            ld a, (hl)		; Hyp.cls 4279
            inc a		; Hyp.cls 4280
            ld b, a		; Hyp.cls 4281
asm_1_2771_n_fl_ud_cmp:		; Hyp.cls 4282
            ld a, (de)		; Hyp.cls 4283
            cp (hl)		; Hyp.cls 4284
            jr nz, asm_1_2771_n_fl_ud_new		; Hyp.cls 4285
            inc hl		; Hyp.cls 4286
            inc de		; Hyp.cls 4287
            djnz asm_1_2771_n_fl_ud_cmp		; Hyp.cls 4288
            ld hl, (asm_1_2771_n_fl_exi)		; Hyp.cls 4289
            ld de, (asm_1_2771_n_FL_UB + 2)		; Hyp.cls 4290
            or a		; Hyp.cls 4291
            sbc hl, de		; Hyp.cls 4292
            jr z, asm_1_2771_n_fl_ud_next		; Hyp.cls 4293
asm_1_2771_n_fl_ud_new:		; Hyp.cls 4294
            ld hl, asm_1_2771_n_fl_name_s		; Hyp.cls 4295
            ld de, asm_1_2771_n_FL_EXK		; Hyp.cls 4296
            ld bc, 32		; Hyp.cls 4297
            ldir		; Hyp.cls 4298
            call asm_1_2771_n_fl_exdir2		; Hyp.cls 4299
            jr z, asm_1_2771_n_fl_ud_ok		; Hyp.cls 4300
            or a		; Hyp.cls 4301
            jr nz, asm_1_2771_n_fl_us_err		; Hyp.cls 4302
            inc a		; Hyp.cls 4303
            jr asm_1_2771_n_fl_us_err		; Hyp.cls 4304
asm_1_2771_n_fl_ud_ok:		; Hyp.cls 4305
            ld hl, 0		; Hyp.cls 4306
            ld (asm_1_2771_n_fl_exi), hl		; Hyp.cls 4307
            ld a, 1		; Hyp.cls 4308
            ld (asm_1_2771_n_fl_exv), a		; Hyp.cls 4309
asm_1_2771_n_fl_ud_skip:                         ; on to entry Word(2) [4310]
            ld hl, (asm_1_2771_n_fl_exi)		; Hyp.cls 4311
            ld de, (asm_1_2771_n_FL_UB + 2)		; Hyp.cls 4312
            or a		; Hyp.cls 4313
            sbc hl, de		; Hyp.cls 4314
            jr z, asm_1_2771_n_fl_ud_next		; Hyp.cls 4315
            ld hl, asm_1_2771_n_FL_TN		; Hyp.cls 4316
            ld ix, asm_1_2771_n_FL_DATE		; Hyp.cls 4317
            ld c, 13		; Hyp.cls 4318
            call asm_1_2771_n_fl_cjc		; Hyp.cls 4319
            jr nc, asm_1_2771_n_fl_ud_end		; Hyp.cls 4320
            jr nz, asm_1_2771_n_fl_ud_end		; Hyp.cls 4321
            ld hl, (asm_1_2771_n_fl_exi)		; Hyp.cls 4322
            inc hl		; Hyp.cls 4323
            ld (asm_1_2771_n_fl_exi), hl		; Hyp.cls 4324
            jr asm_1_2771_n_fl_ud_skip		; Hyp.cls 4325
asm_1_2771_n_fl_ud_next:		; Hyp.cls 4326
            ld hl, asm_1_2771_n_FL_UB + 16		; Hyp.cls 4327
            ld ix, asm_1_2771_n_FL_UB + 9		; Hyp.cls 4328
            ld c, 13		; Hyp.cls 4329
            call asm_1_2771_n_fl_cjc		; Hyp.cls 4330
            jr nc, asm_1_2771_n_fl_ud_end		; Hyp.cls 4331
            jr nz, asm_1_2771_n_fl_ud_end		; Hyp.cls 4332
            ld (asm_1_2771_n_FL_UB + 4), a		; Hyp.cls 4333
            ld (asm_1_2771_n_FL_UB + 5), de		; Hyp.cls 4334
            ld (asm_1_2771_n_FL_UB + 7), bc		; Hyp.cls 4335
            ld hl, (asm_1_2771_n_fl_exi)		; Hyp.cls 4336
            inc hl		; Hyp.cls 4337
            ld (asm_1_2771_n_fl_exi), hl		; Hyp.cls 4338
            xor a		; Hyp.cls 4339
            ld b, 28		; Hyp.cls 4340
            jp asm_1_2771_n_fl_uc_back		; Hyp.cls 4341
asm_1_2771_n_fl_ud_end:		; Hyp.cls 4342
            xor a		; Hyp.cls 4343
            ld (asm_1_2771_n_fl_exv), a		; Hyp.cls 4344
            inc a		; Hyp.cls 4345
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 4346
            jp asm_1_2771_n_fp_done		; Hyp.cls 4347
asm_1_2771_n_fp_end:		; Hyp.cls 4348
            ASSERT asm_1_2771_n_fp_end <= #6000, "FileCall's page code: below the search's cache (#6000)"		; Hyp.cls 4349
; ---- the service page's code (window data from #6000, copied there by FileCall 99)
            ds #6000 - $		; Hyp.cls 4512
asm_1_4424_n_sv_go:		; Hyp.cls 4513
            ld (asm_1_4424_n_sv_sp), sp		; Hyp.cls 4514
            ld hl, (var_hyp_svc_p)            ; p 0: slot t's claims freed (Main's FilesShut) [4515]
            ld a, h		; Hyp.cls 4516
            or l		; Hyp.cls 4517
            jp z, asm_1_4424_n_sv_cfree		; Hyp.cls 4518
            ld hl, (var_hyp_svc_p)            ; the request (16 bytes) from the slot [4519]
            ld de, (var_hyp_svc_setting)		; Hyp.cls 4520
            call asm_1_4424_n_sv_sw		; Hyp.cls 4521
            push bc		; Hyp.cls 4522
            pop ix		; Hyp.cls 4523
            ld iy, (var_hyp_svp)		; Hyp.cls 4524
            ld de, asm_1_4424_n_sv_blk		; Hyp.cls 4525
            ld a, 16		; Hyp.cls 4526
            call asm_1_4424_n_sv_dx		; Hyp.cls 4527
            ld hl, (asm_1_4424_n_sv_blk + 8)     ; how many: 2K at most [4528]
            bit 7, h		; Hyp.cls 4529
            jr nz, asm_1_4424_n_sv_n2		; Hyp.cls 4530
            ld de, 2049		; Hyp.cls 4531
            or a		; Hyp.cls 4532
            sbc hl, de		; Hyp.cls 4533
            add hl, de		; Hyp.cls 4534
            jr c, asm_1_4424_n_sv_n1		; Hyp.cls 4535
asm_1_4424_n_sv_n2:		; Hyp.cls 4536
            ld hl, 2048		; Hyp.cls 4537
asm_1_4424_n_sv_n1:		; Hyp.cls 4538
            ld (asm_1_4424_n_sv_n), hl		; Hyp.cls 4539
            xor a		; Hyp.cls 4540
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 4541
            ld a, 2                 ; (the copies to the slot: its bank) [4542]
            ld (asm_1_4424_n_sv_dk), a		; Hyp.cls 4543
            ld hl, (var_hyp_svc_setting)		; Hyp.cls 4544
            ld (asm_1_4424_n_sv_ds), hl		; Hyp.cls 4545
            ld hl, (asm_1_4424_n_sv_blk + 6)		; Hyp.cls 4546
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 4547
            ld a, (asm_1_4424_n_sv_blk)		; Hyp.cls 4548
            cp 10		; Hyp.cls 4549
            jp z, asm_1_4424_n_sv_mem		; Hyp.cls 4550
            cp 11		; Hyp.cls 4551
            jp z, asm_1_4424_n_sv_ptr		; Hyp.cls 4552
            cp 13		; Hyp.cls 4553
            jp z, asm_1_4424_n_sv_store		; Hyp.cls 4554
            cp 14		; Hyp.cls 4555
            jp z, asm_1_4424_n_sv_store		; Hyp.cls 4556
            cp 15		; Hyp.cls 4557
            jp z, asm_1_4424_n_sv_tab		; Hyp.cls 4558
            cp 16		; Hyp.cls 4559
            jp c, asm_1_4424_n_sv_err		; Hyp.cls 4560
            cp 20		; Hyp.cls 4561
            jp c, asm_1_4424_n_sv_claim		; Hyp.cls 4562
            cp 28		; Hyp.cls 4563
            jp c, asm_1_4424_n_sv_net		; Hyp.cls 4564
            cp 34		; Hyp.cls 4565
            jp c, asm_1_4424_n_sv_port		; Hyp.cls 4566
            jp z, asm_1_4424_n_pt_list		; Hyp.cls 4567
asm_1_4424_n_sv_err:		; Hyp.cls 4568
            ld sp, (asm_1_4424_n_sv_sp)		; Hyp.cls 4569
            ld a, 255		; Hyp.cls 4570
            ret		; Hyp.cls 4571
asm_1_4424_n_sv_ok:		; Hyp.cls 4572
            ld sp, (asm_1_4424_n_sv_sp)		; Hyp.cls 4573
            xor a		; Hyp.cls 4574
            ret		; Hyp.cls 4575
; 10: memory
asm_1_4424_n_sv_mem:		; Hyp.cls 4577
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 4578
            cp 4		; Hyp.cls 4579
            jr z, asm_1_4424_n_sv_m4             ; 4: the caller's Word(6) into slot Word(2) at Word(4) [4580]
            ld hl, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 4581
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 4582
            ld hl, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 4583
            or a		; Hyp.cls 4584
            jr nz, asm_1_4424_n_sv_m1		; Hyp.cls 4585
            ld de, (mem_count)      ; 0: a page (below Pages) [4586]
            push hl		; Hyp.cls 4587
            or a		; Hyp.cls 4588
            sbc hl, de		; Hyp.cls 4589
            pop hl		; Hyp.cls 4590
            jp nc, asm_1_4424_n_sv_err		; Hyp.cls 4591
            call asm_1_4424_n_sv_pgset		; Hyp.cls 4592
            ld (asm_1_4424_n_sv_ss), bc		; Hyp.cls 4593
            ld a, 1		; Hyp.cls 4594
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 4595
            jr asm_1_4424_n_sv_mgo		; Hyp.cls 4596
asm_1_4424_n_sv_m1:		; Hyp.cls 4597
            dec a		; Hyp.cls 4598
            jr nz, asm_1_4424_n_sv_m2		; Hyp.cls 4599
            ld (asm_1_4424_n_sv_ss), hl          ; 1: a ROM [4600]
            ld a, 1		; Hyp.cls 4601
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 4602
            ld a, 3		; Hyp.cls 4603
            jr asm_1_4424_n_sv_mgo1		; Hyp.cls 4604
asm_1_4424_n_sv_m2:		; Hyp.cls 4605
            dec a		; Hyp.cls 4606
            jr nz, asm_1_4424_n_sv_m3		; Hyp.cls 4607
            ld a, 4                 ; 2: main RAM [4608]
            jr asm_1_4424_n_sv_mgo1		; Hyp.cls 4609
asm_1_4424_n_sv_m3:		; Hyp.cls 4610
            dec a		; Hyp.cls 4611
            jp nz, asm_1_4424_n_sv_err		; Hyp.cls 4612
            call asm_1_4424_n_sv_slot            ; 3: a slot's memory (one in use) [4613]
            jp z, asm_1_4424_n_sv_err		; Hyp.cls 4614
            ld (asm_1_4424_n_sv_ss), de		; Hyp.cls 4615
            ld a, 2		; Hyp.cls 4616
            jr asm_1_4424_n_sv_mgo1		; Hyp.cls 4617
asm_1_4424_n_sv_mgo:		; Hyp.cls 4618
            ld a, 1		; Hyp.cls 4619
asm_1_4424_n_sv_mgo1:		; Hyp.cls 4620
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 4621
            call asm_1_4424_n_sv_copy		; Hyp.cls 4622
            jr asm_1_4424_n_sv_ok		; Hyp.cls 4623
; 10 Byte(1) 4: the caller's own Word(6) written into slot Word(2) at Word(4), Word(8) bytes
asm_1_4424_n_sv_m4:		; Hyp.cls 4625
            ld hl, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 4626
            call asm_1_4424_n_sv_slot            ; the target slot (one in use): DE its RAM setting [4627]
            jp z, asm_1_4424_n_sv_err		; Hyp.cls 4628
            ld (asm_1_4424_n_sv_ds), de          ; dest: that slot's bank, at Word(4) [4629]
            ld a, 2		; Hyp.cls 4630
            ld (asm_1_4424_n_sv_dk), a		; Hyp.cls 4631
            ld hl, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 4632
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 4633
            ld hl, (var_hyp_svc_setting)      ; source: the caller's bank, at Word(6) [4634]
            ld (asm_1_4424_n_sv_ss), hl		; Hyp.cls 4635
            ld a, 2		; Hyp.cls 4636
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 4637
            ld hl, (asm_1_4424_n_sv_blk + 6)		; Hyp.cls 4638
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 4639
            xor a		; Hyp.cls 4640
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 4641
            call asm_1_4424_n_sv_copy		; Hyp.cls 4642
            jp asm_1_4424_n_sv_ok		; Hyp.cls 4643
; HL = a slot number: Z when it isn't one in use, else DE = its RAM setting
asm_1_4424_n_sv_slot:		; Hyp.cls 4645
            ld a, h		; Hyp.cls 4646
            or a		; Hyp.cls 4647
            jr nz, asm_1_4424_n_sv_sl0		; Hyp.cls 4648
            or l		; Hyp.cls 4649
            ret z		; Hyp.cls 4650
            ld de, (var_hyp_svns)		; Hyp.cls 4651
            ld a, (de)		; Hyp.cls 4652
            cp l		; Hyp.cls 4653
            jr c, asm_1_4424_n_sv_sl0		; Hyp.cls 4654
            add hl, hl		; Hyp.cls 4655
            push hl		; Hyp.cls 4656
            ld de, (var_hyp_svst)		; Hyp.cls 4657
            add hl, de		; Hyp.cls 4658
            ld a, (hl)		; Hyp.cls 4659
            pop hl		; Hyp.cls 4660
            or a		; Hyp.cls 4661
            ret z		; Hyp.cls 4662
            ld de, (var_hyp_svsg)		; Hyp.cls 4663
            add hl, de		; Hyp.cls 4664
            ld e, (hl)		; Hyp.cls 4665
            inc hl		; Hyp.cls 4666
            ld d, (hl)		; Hyp.cls 4667
            or 1                    ; (NZ) [4668]
            ret		; Hyp.cls 4669
asm_1_4424_n_sv_sl0:		; Hyp.cls 4670
            xor a		; Hyp.cls 4671
            ret		; Hyp.cls 4672
; 13 / 14: a 2K block of the store (13 from the slot, 14 to it) - Byte(1) 1: from Word(4) bytes into
; the block (any part of its 16K page, not past the page's end: Pluto's KEYMAN reads a key a byte at a time)
asm_1_4424_n_sv_store:		; Hyp.cls 4675
            ld hl, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 4676
            ld a, h		; Hyp.cls 4677
            or a		; Hyp.cls 4678
            jp nz, asm_1_4424_n_sv_err		; Hyp.cls 4679
            ld a, l		; Hyp.cls 4680
            and 7		; Hyp.cls 4681
            add a, a		; Hyp.cls 4682
            add a, a		; Hyp.cls 4683
            add a, a		; Hyp.cls 4684
            ld (asm_1_4424_n_sv_sa + 1), a       ; the block's place in its page [4685]
            xor a		; Hyp.cls 4686
            ld (asm_1_4424_n_sv_sa), a		; Hyp.cls 4687
            srl l		; Hyp.cls 4688
            srl l		; Hyp.cls 4689
            srl l		; Hyp.cls 4690
            ld a, (asm_1_4424_n_sv_blk + 1)      ; Byte(1) 1: Word(4) bytes on from the block's start (its page's end the limit) [4691]
            or a		; Hyp.cls 4692
            jr z, asm_1_4424_n_sv_sto0		; Hyp.cls 4693
            ld a, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 4694
            ld (asm_1_4424_n_sv_sa), a		; Hyp.cls 4695
            ld a, (asm_1_4424_n_sv_blk + 5)		; Hyp.cls 4696
            ld b, a		; Hyp.cls 4697
            ld a, (asm_1_4424_n_sv_sa + 1)		; Hyp.cls 4698
            add a, b		; Hyp.cls 4699
            and #3F		; Hyp.cls 4700
            ld (asm_1_4424_n_sv_sa + 1), a		; Hyp.cls 4701
asm_1_4424_n_sv_sto0:		; Hyp.cls 4702
            ld h, #FF               ; its page: the slot's byte at #FF00 + block / 8 [4703]
            ld de, (var_hyp_svc_setting)		; Hyp.cls 4704
            call asm_1_4424_n_sv_sw		; Hyp.cls 4705
            push bc		; Hyp.cls 4706
            pop ix		; Hyp.cls 4707
            ld iy, (var_hyp_svp)		; Hyp.cls 4708
            ld de, asm_1_4424_n_sv_tmp		; Hyp.cls 4709
            ld a, 1		; Hyp.cls 4710
            call asm_1_4424_n_sv_dx		; Hyp.cls 4711
            ld a, (asm_1_4424_n_sv_tmp)		; Hyp.cls 4712
            or a		; Hyp.cls 4713
            jp z, asm_1_4424_n_sv_err		; Hyp.cls 4714
            ld l, a		; Hyp.cls 4715
            ld h, 0		; Hyp.cls 4716
            call asm_1_4424_n_sv_pgset		; Hyp.cls 4717
            ld (asm_1_4424_n_sv_ss), bc		; Hyp.cls 4718
            ld a, 1		; Hyp.cls 4719
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 4720
            ld a, (asm_1_4424_n_sv_blk)		; Hyp.cls 4721
            cp 14		; Hyp.cls 4722
            jr z, asm_1_4424_n_sv_st1		; Hyp.cls 4723
            ld hl, (asm_1_4424_n_sv_sa)          ; 13: the slot to the page [4724]
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 4725
            ld hl, (asm_1_4424_n_sv_ss)		; Hyp.cls 4726
            ld (asm_1_4424_n_sv_ds), hl		; Hyp.cls 4727
            ld a, 1		; Hyp.cls 4728
            ld (asm_1_4424_n_sv_dk), a		; Hyp.cls 4729
            ld hl, (asm_1_4424_n_sv_blk + 6)		; Hyp.cls 4730
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 4731
            ld hl, (var_hyp_svc_setting)		; Hyp.cls 4732
            ld (asm_1_4424_n_sv_ss), hl		; Hyp.cls 4733
            ld a, 2		; Hyp.cls 4734
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 4735
asm_1_4424_n_sv_st1:		; Hyp.cls 4736
            call asm_1_4424_n_sv_copy		; Hyp.cls 4737
            jp asm_1_4424_n_sv_ok		; Hyp.cls 4738
; 11: the pointer, while the slot is in front
asm_1_4424_n_sv_ptr:		; Hyp.cls 4740
            ld hl, (var_hyp_svfr)		; Hyp.cls 4741
            ld a, (hl)		; Hyp.cls 4742
            ld hl, var_hyp_svc_t		; Hyp.cls 4743
            cp (hl)		; Hyp.cls 4744
            jp nz, asm_1_4424_n_sv_ok		; Hyp.cls 4745
            ld a, (var_hyp_pon)		; Hyp.cls 4746
            or a		; Hyp.cls 4747
            call nz, asm_1_4424_n_pt_xor		; Hyp.cls 4748
            xor a		; Hyp.cls 4749
            ld (var_hyp_pon), a		; Hyp.cls 4750
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 4751
            or a		; Hyp.cls 4752
            jp z, asm_1_4424_n_sv_ok		; Hyp.cls 4753
            ld a, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 4754
            ld hl, var_hyp_scc		; Hyp.cls 4755
            cp (hl)		; Hyp.cls 4756
            jp nc, asm_1_4424_n_sv_ok            ; (off the screen: none) [4757]
            ld (var_hyp_pox), a		; Hyp.cls 4758
            ld a, (asm_1_4424_n_sv_blk + 3)		; Hyp.cls 4759
            ld (var_hyp_poy), a		; Hyp.cls 4760
            call asm_1_4424_n_pt_xor		; Hyp.cls 4761
            ld a, 1		; Hyp.cls 4762
            ld (var_hyp_pon), a		; Hyp.cls 4763
            jp asm_1_4424_n_sv_ok		; Hyp.cls 4764
asm_1_4424_n_pt_xor:                             ; the checkerboard XORed at pox, poy (the screen is main RAM) [4765]
            ld a, (var_hyp_poy)		; Hyp.cls 4766
            ld e, a		; Hyp.cls 4767
            ld d, 0		; Hyp.cls 4768
            ld hl, 0		; Hyp.cls 4769
            ld a, (var_hyp_scc)		; Hyp.cls 4770
            ld b, 8		; Hyp.cls 4771
asm_1_4424_n_pt_mul:		; Hyp.cls 4772
            add hl, hl		; Hyp.cls 4773
            rlca		; Hyp.cls 4774
            jr nc, asm_1_4424_n_pt_mn		; Hyp.cls 4775
            add hl, de		; Hyp.cls 4776
asm_1_4424_n_pt_mn:		; Hyp.cls 4777
            djnz asm_1_4424_n_pt_mul		; Hyp.cls 4778
            ld a, (var_hyp_pox)		; Hyp.cls 4779
            ld e, a		; Hyp.cls 4780
            add hl, de		; Hyp.cls 4781
            ld de, (var_hyp_sco)		; Hyp.cls 4782
            add hl, de		; Hyp.cls 4783
            ld a, h		; Hyp.cls 4784
            and #07		; Hyp.cls 4785
            or #C0		; Hyp.cls 4786
            ld h, a		; Hyp.cls 4787
            ld b, 4		; Hyp.cls 4788
asm_1_4424_n_pt_ln:		; Hyp.cls 4789
            ld a, (hl)		; Hyp.cls 4790
            xor #AA		; Hyp.cls 4791
            ld (hl), a		; Hyp.cls 4792
            ld a, h		; Hyp.cls 4793
            add a, 8		; Hyp.cls 4794
            ld h, a		; Hyp.cls 4795
            ld a, (hl)		; Hyp.cls 4796
            xor #55		; Hyp.cls 4797
            ld (hl), a		; Hyp.cls 4798
            ld a, h		; Hyp.cls 4799
            add a, 8		; Hyp.cls 4800
            ld h, a		; Hyp.cls 4801
            djnz asm_1_4424_n_pt_ln		; Hyp.cls 4802
            ret		; Hyp.cls 4803
; 15: a table
asm_1_4424_n_sv_tab:		; Hyp.cls 4805
            ld hl, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 4806
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 4807
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 4808
            or a		; Hyp.cls 4809
            jr z, asm_1_4424_n_sv_t0		; Hyp.cls 4810
            dec a		; Hyp.cls 4811
            jp z, asm_1_4424_n_sv_t1		; Hyp.cls 4812
            dec a		; Hyp.cls 4813
            jp z, asm_1_4424_n_sv_t2		; Hyp.cls 4814
            dec a		; Hyp.cls 4815
            jp z, asm_1_4424_n_sv_t3		; Hyp.cls 4816
            dec a		; Hyp.cls 4817
            jp z, asm_1_4424_n_sv_t4		; Hyp.cls 4818
            jp asm_1_4424_n_sv_err		; Hyp.cls 4819
; 4: the claims - CL_N records of 10 bytes: the slot holding it (0: a free record), the unit,
; the name (8 characters, spaces after it)
asm_1_4424_n_sv_t4:		; Hyp.cls 4822
            ld hl, asm_1_4424_n_sv_cl		; Hyp.cls 4823
            ld de, (asm_1_4424_n_sv_da)		; Hyp.cls 4824
            ld bc, asm_1_4424_n_CL_N * 10		; Hyp.cls 4825
            call asm_1_4424_n_sv_out		; Hyp.cls 4826
            jp asm_1_4424_n_sv_ok		; Hyp.cls 4827
; 0: the slots - a word how many, then from 16 a record each: state, in front, MODE, the name's
; length, the name
asm_1_4424_n_sv_t0:		; Hyp.cls 4830
            call asm_1_4424_n_sv_clr		; Hyp.cls 4831
            ld hl, (var_hyp_svns)		; Hyp.cls 4832
            ld a, (hl)		; Hyp.cls 4833
            ld (asm_1_4424_n_sv_rec), a		; Hyp.cls 4834
            ld (asm_1_4424_n_sv_tn), a		; Hyp.cls 4835
            call asm_1_4424_n_sv_out16		; Hyp.cls 4836
            ld a, 1		; Hyp.cls 4837
            ld (asm_1_4424_n_sv_tj), a		; Hyp.cls 4838
asm_1_4424_n_sv_t0lp:		; Hyp.cls 4839
            ld a, (asm_1_4424_n_sv_tn)		; Hyp.cls 4840
            ld b, a		; Hyp.cls 4841
            ld a, (asm_1_4424_n_sv_tj)		; Hyp.cls 4842
            cp b		; Hyp.cls 4843
            jr z, asm_1_4424_n_sv_t0a		; Hyp.cls 4844
            jp nc, asm_1_4424_n_sv_ok		; Hyp.cls 4845
asm_1_4424_n_sv_t0a:		; Hyp.cls 4846
            ld hl, (asm_1_4424_n_sv_da)		; Hyp.cls 4847
            ld de, 16		; Hyp.cls 4848
            add hl, de		; Hyp.cls 4849
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 4850
            call asm_1_4424_n_sv_clr		; Hyp.cls 4851
            ld a, (asm_1_4424_n_sv_tj)		; Hyp.cls 4852
            ld l, a		; Hyp.cls 4853
            ld h, 0		; Hyp.cls 4854
            add hl, hl		; Hyp.cls 4855
            ld de, (var_hyp_svst)		; Hyp.cls 4856
            add hl, de		; Hyp.cls 4857
            ld a, (hl)		; Hyp.cls 4858
            ld (asm_1_4424_n_sv_rec), a          ; its state [4859]
            ld hl, (var_hyp_svfr)		; Hyp.cls 4860
            ld a, (asm_1_4424_n_sv_tj)		; Hyp.cls 4861
            cp (hl)		; Hyp.cls 4862
            jr nz, asm_1_4424_n_sv_t0b		; Hyp.cls 4863
            ld a, 1		; Hyp.cls 4864
            ld (asm_1_4424_n_sv_rec + 1), a      ; in front [4865]
asm_1_4424_n_sv_t0b:		; Hyp.cls 4866
            ld a, (asm_1_4424_n_sv_rec)		; Hyp.cls 4867
            or a		; Hyp.cls 4868
            jr z, asm_1_4424_n_sv_t0d		; Hyp.cls 4869
            ld a, (asm_1_4424_n_sv_tj)           ; its RAM setting [4870]
            ld l, a		; Hyp.cls 4871
            ld h, 0		; Hyp.cls 4872
            add hl, hl		; Hyp.cls 4873
            ld de, (var_hyp_svsg)		; Hyp.cls 4874
            add hl, de		; Hyp.cls 4875
            ld e, (hl)		; Hyp.cls 4876
            inc hl		; Hyp.cls 4877
            ld d, (hl)		; Hyp.cls 4878
            ld (asm_1_4424_n_sv_tsg), de		; Hyp.cls 4879
            ld hl, 63113          ; MODE [4880]
            ld a, 1		; Hyp.cls 4881
            call asm_1_4424_n_sv_from		; Hyp.cls 4882
            ld a, (asm_1_4424_n_sv_tmp)		; Hyp.cls 4883
            ld (asm_1_4424_n_sv_rec + 2), a		; Hyp.cls 4884
            ld a, (asm_1_4424_n_sv_rec)		; Hyp.cls 4885
            cp 2		; Hyp.cls 4886
            jr nz, asm_1_4424_n_sv_t0d		; Hyp.cls 4887
            ld de, (asm_1_4424_n_sv_tsg)		; Hyp.cls 4888
            ld hl, #F6D8            ; the program's name: its length, then 12 [4889]
            ld a, 13		; Hyp.cls 4890
            call asm_1_4424_n_sv_from		; Hyp.cls 4891
            ld a, (asm_1_4424_n_sv_tmp)		; Hyp.cls 4892
            cp 13		; Hyp.cls 4893
            jr c, asm_1_4424_n_sv_t0c		; Hyp.cls 4894
            ld a, 12		; Hyp.cls 4895
asm_1_4424_n_sv_t0c:		; Hyp.cls 4896
            ld (asm_1_4424_n_sv_rec + 3), a		; Hyp.cls 4897
            ld hl, asm_1_4424_n_sv_tmp + 1		; Hyp.cls 4898
            ld de, asm_1_4424_n_sv_rec + 4		; Hyp.cls 4899
            ld bc, 12		; Hyp.cls 4900
            ldir		; Hyp.cls 4901
asm_1_4424_n_sv_t0d:		; Hyp.cls 4902
            ld hl, asm_1_4424_n_sv_tj		; Hyp.cls 4903
            push hl		; Hyp.cls 4904
            call asm_1_4424_n_sv_out16		; Hyp.cls 4905
            pop hl		; Hyp.cls 4906
            inc (hl)		; Hyp.cls 4907
            jp asm_1_4424_n_sv_t0lp		; Hyp.cls 4908
; 1: the memory - words: the tables' end, the top, the pages, total K, free pages; from 16 a byte a page
asm_1_4424_n_sv_t1:		; Hyp.cls 4910
            call asm_1_4424_n_sv_clr		; Hyp.cls 4911
            ld hl, (mem_tend)		; Hyp.cls 4912
            ld (asm_1_4424_n_sv_rec), hl		; Hyp.cls 4913
            call mem_top		; Hyp.cls 4914
            ld (asm_1_4424_n_sv_rec + 2), hl		; Hyp.cls 4915
            ld hl, (mem_count)		; Hyp.cls 4916
            ld (asm_1_4424_n_sv_rec + 4), hl		; Hyp.cls 4917
            call mem_ramsize		; Hyp.cls 4918
            ld (asm_1_4424_n_sv_rec + 6), hl		; Hyp.cls 4919
            call mem_freepages		; Hyp.cls 4920
            ld (asm_1_4424_n_sv_rec + 8), hl		; Hyp.cls 4921
            ld hl, asm_1_4424_n_sv_rec		; Hyp.cls 4922
            ld de, (asm_1_4424_n_sv_da)		; Hyp.cls 4923
            ld bc, 18               ; (and pages 0, 1: 0) [4924]
            call asm_1_4424_n_sv_out		; Hyp.cls 4925
            ld hl, (mem_count)      ; pages 2 on: the RAT (2030 at most) [4926]
            dec hl		; Hyp.cls 4927
            ld a, h		; Hyp.cls 4928
            or l		; Hyp.cls 4929
            jp z, asm_1_4424_n_sv_ok		; Hyp.cls 4930
            ld de, 2031		; Hyp.cls 4931
            or a		; Hyp.cls 4932
            sbc hl, de		; Hyp.cls 4933
            add hl, de		; Hyp.cls 4934
            jr c, asm_1_4424_n_sv_t1a		; Hyp.cls 4935
            ld hl, 2030		; Hyp.cls 4936
asm_1_4424_n_sv_t1a:		; Hyp.cls 4937
            ld (asm_1_4424_n_sv_n), hl		; Hyp.cls 4938
            ld hl, (mem_ttype)		; Hyp.cls 4939
            inc hl		; Hyp.cls 4940
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 4941
            ld hl, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 4942
            ld de, 18		; Hyp.cls 4943
            add hl, de		; Hyp.cls 4944
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 4945
            xor a		; Hyp.cls 4946
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 4947
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 4948
            call asm_1_4424_n_sv_copy		; Hyp.cls 4949
            jp asm_1_4424_n_sv_ok		; Hyp.cls 4950
; 2: the upper ROMs 0-31 - 64 bytes each: the first 16, then 48 of the name table (0s if none)
asm_1_4424_n_sv_t2:		; Hyp.cls 4952
            xor a		; Hyp.cls 4953
            ld (asm_1_4424_n_sv_tj), a		; Hyp.cls 4954
asm_1_4424_n_sv_t2lp:		; Hyp.cls 4955
            call asm_1_4424_n_sv_clr		; Hyp.cls 4956
            ld a, (asm_1_4424_n_sv_tj)		; Hyp.cls 4957
            ld c, a		; Hyp.cls 4958
            call #B90F              ; KL ROM SELECT (#C000 only: this code at #6000 stays) [4959]
            di		; Hyp.cls 4960
            push bc		; Hyp.cls 4961
            ld hl, #C000		; Hyp.cls 4962
            ld de, asm_1_4424_n_sv_rec		; Hyp.cls 4963
            ld bc, 16		; Hyp.cls 4964
            ldir		; Hyp.cls 4965
            ld hl, (asm_1_4424_n_sv_rec + 4)		; Hyp.cls 4966
            ld a, h		; Hyp.cls 4967
            and #C0		; Hyp.cls 4968
            cp #C0		; Hyp.cls 4969
            jr nz, asm_1_4424_n_sv_t2a		; Hyp.cls 4970
            ld de, #FF90		; Hyp.cls 4971
            or a		; Hyp.cls 4972
            sbc hl, de		; Hyp.cls 4973
            add hl, de		; Hyp.cls 4974
            jr nc, asm_1_4424_n_sv_t2a		; Hyp.cls 4975
            ld de, asm_1_4424_n_sv_rec + 16		; Hyp.cls 4976
            ld bc, 48		; Hyp.cls 4977
            ldir		; Hyp.cls 4978
asm_1_4424_n_sv_t2a:		; Hyp.cls 4979
            pop bc		; Hyp.cls 4980
            call #B918              ; KL ROM DESELECT [4981]
            di		; Hyp.cls 4982
            ld hl, asm_1_4424_n_sv_rec		; Hyp.cls 4983
            ld de, (asm_1_4424_n_sv_da)		; Hyp.cls 4984
            ld bc, 64		; Hyp.cls 4985
            call asm_1_4424_n_sv_out		; Hyp.cls 4986
            ld hl, (asm_1_4424_n_sv_da)		; Hyp.cls 4987
            ld de, 64		; Hyp.cls 4988
            add hl, de		; Hyp.cls 4989
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 4990
            ld hl, asm_1_4424_n_sv_tj		; Hyp.cls 4991
            inc (hl)		; Hyp.cls 4992
            ld a, (hl)		; Hyp.cls 4993
            cp 32		; Hyp.cls 4994
            jr c, asm_1_4424_n_sv_t2lp		; Hyp.cls 4995
            jp asm_1_4424_n_sv_ok		; Hyp.cls 4996
; 3: the RAM discs - the driver's table (its page, #6A00: 128 bytes), 0s if none
asm_1_4424_n_sv_t3:		; Hyp.cls 4998
            call asm_1_4424_n_sv_clr		; Hyp.cls 4999
            ld hl, (var_hyp_svdp)		; Hyp.cls 5000
            ld e, (hl)		; Hyp.cls 5001
            inc hl		; Hyp.cls 5002
            ld d, (hl)		; Hyp.cls 5003
            ld a, d		; Hyp.cls 5004
            or e		; Hyp.cls 5005
            jr z, asm_1_4424_n_sv_t3a		; Hyp.cls 5006
            ex de, hl		; Hyp.cls 5007
            call asm_1_4424_n_sv_pgset		; Hyp.cls 5008
            ld (asm_1_4424_n_sv_ss), bc		; Hyp.cls 5009
            ld hl, #6A00		; Hyp.cls 5010
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 5011
            ld hl, 128		; Hyp.cls 5012
            ld (asm_1_4424_n_sv_n), hl		; Hyp.cls 5013
            ld a, 1		; Hyp.cls 5014
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 5015
            xor a		; Hyp.cls 5016
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 5017
            call asm_1_4424_n_sv_copy		; Hyp.cls 5018
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5019
asm_1_4424_n_sv_t3a:		; Hyp.cls 5020
            ld hl, asm_1_4424_n_sv_rec		; Hyp.cls 5021
            ld de, (asm_1_4424_n_sv_da)		; Hyp.cls 5022
            ld bc, 128		; Hyp.cls 5023
            call asm_1_4424_n_sv_out		; Hyp.cls 5024
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5025
; sv_from - A bytes from slot (sv_tsg's) HL into sv_tmp
asm_1_4424_n_sv_from:		; Hyp.cls 5027
            ld de, (asm_1_4424_n_sv_tsg)		; Hyp.cls 5028
            push af		; Hyp.cls 5029
            call asm_1_4424_n_sv_sw		; Hyp.cls 5030
            push bc		; Hyp.cls 5031
            pop ix		; Hyp.cls 5032
            ld iy, (var_hyp_svp)		; Hyp.cls 5033
            ld de, asm_1_4424_n_sv_tmp		; Hyp.cls 5034
            pop af		; Hyp.cls 5035
            jp asm_1_4424_n_sv_dx		; Hyp.cls 5036
; sv_clr - sv_rec (128 bytes) 0
asm_1_4424_n_sv_clr:		; Hyp.cls 5038
            ld hl, asm_1_4424_n_sv_rec		; Hyp.cls 5039
            ld de, asm_1_4424_n_sv_rec + 1		; Hyp.cls 5040
            ld bc, 127		; Hyp.cls 5041
            ld (hl), 0		; Hyp.cls 5042
            ldir		; Hyp.cls 5043
            ret		; Hyp.cls 5044
; sv_out16 - sv_rec's first 16 to the slot at sv_da; sv_out - BC bytes from HL (here) to the slot's DE
asm_1_4424_n_sv_out16:		; Hyp.cls 5046
            ld hl, asm_1_4424_n_sv_rec		; Hyp.cls 5047
            ld de, (asm_1_4424_n_sv_da)		; Hyp.cls 5048
            ld bc, 16		; Hyp.cls 5049
asm_1_4424_n_sv_out:		; Hyp.cls 5050
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 5051
            ld (asm_1_4424_n_sv_da), de		; Hyp.cls 5052
            ld (asm_1_4424_n_sv_n), bc		; Hyp.cls 5053
            ld a, 1		; Hyp.cls 5054
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 5055
            ld hl, (var_hyp_svp)		; Hyp.cls 5056
            ld (asm_1_4424_n_sv_ss), hl		; Hyp.cls 5057
            xor a		; Hyp.cls 5058
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 5059
            ld hl, (asm_1_4424_n_sv_da)		; Hyp.cls 5060
            push hl		; Hyp.cls 5061
            call asm_1_4424_n_sv_copy		; Hyp.cls 5062
            pop hl		; Hyp.cls 5063
            ld (asm_1_4424_n_sv_da), hl          ; (where it went: kept) [5064]
            ret		; Hyp.cls 5065
; sv_copy - sv_n bytes from the source (sv_sk: 0 main RAM outside the window, 1 a page - RAM setting
; sv_ss, 2 a bank - C2 setting sv_ss, 3 ROM sv_ss, 4 main RAM anywhere) at sv_sa to the
; destination (sv_dk: 1 a page, 2 a bank; sv_ds) at sv_da, 128 at most a go, none across a 16K
; page's end; sv_stop: at the source's page end, stop
asm_1_4424_n_sv_copy:		; Hyp.cls 5070
            ld hl, (asm_1_4424_n_sv_n)		; Hyp.cls 5071
            ld a, h		; Hyp.cls 5072
            or l		; Hyp.cls 5073
            ret z		; Hyp.cls 5074
            ld bc, 128		; Hyp.cls 5075
            or a		; Hyp.cls 5076
            sbc hl, bc		; Hyp.cls 5077
            add hl, bc		; Hyp.cls 5078
            jr nc, asm_1_4424_n_sc_c1		; Hyp.cls 5079
            ld b, h		; Hyp.cls 5080
            ld c, l		; Hyp.cls 5081
asm_1_4424_n_sc_c1:		; Hyp.cls 5082
            ld (asm_1_4424_n_sv_c), bc		; Hyp.cls 5083
            ld a, (asm_1_4424_n_sv_sk)		; Hyp.cls 5084
            or a		; Hyp.cls 5085
            jr z, asm_1_4424_n_sc_dl		; Hyp.cls 5086
            ld hl, (asm_1_4424_n_sv_sa)		; Hyp.cls 5087
            call asm_1_4424_n_sc_room		; Hyp.cls 5088
asm_1_4424_n_sc_dl:		; Hyp.cls 5089
            ld hl, (asm_1_4424_n_sv_da)		; Hyp.cls 5090
            call asm_1_4424_n_sc_room		; Hyp.cls 5091
            ld a, (asm_1_4424_n_sv_sk)           ; the source: IX its RAM setting, HL where [5092]
            ld hl, (asm_1_4424_n_sv_sa)		; Hyp.cls 5093
            ld ix, 0		; Hyp.cls 5094
            or a		; Hyp.cls 5095
            jr z, asm_1_4424_n_sc_sok		; Hyp.cls 5096
            cp 1		; Hyp.cls 5097
            jr nz, asm_1_4424_n_sc_s2		; Hyp.cls 5098
            ld ix, (asm_1_4424_n_sv_ss)		; Hyp.cls 5099
            call asm_1_4424_n_sc_win		; Hyp.cls 5100
            jr asm_1_4424_n_sc_sok		; Hyp.cls 5101
asm_1_4424_n_sc_s2:		; Hyp.cls 5102
            cp 2		; Hyp.cls 5103
            jr nz, asm_1_4424_n_sc_s3		; Hyp.cls 5104
            ld de, (asm_1_4424_n_sv_ss)		; Hyp.cls 5105
            call asm_1_4424_n_sv_sw		; Hyp.cls 5106
            push bc		; Hyp.cls 5107
            pop ix		; Hyp.cls 5108
            jr asm_1_4424_n_sc_sok		; Hyp.cls 5109
asm_1_4424_n_sc_s3:		; Hyp.cls 5110
            cp 3		; Hyp.cls 5111
            jr nz, asm_1_4424_n_sc_s4		; Hyp.cls 5112
            ld a, (asm_1_4424_n_sv_ss)           ; a ROM: its bytes into buf first [5113]
            ld c, a		; Hyp.cls 5114
            call #B90F              ; KL ROM SELECT [5115]
            di		; Hyp.cls 5116
            push bc		; Hyp.cls 5117
            ld hl, (asm_1_4424_n_sv_sa)		; Hyp.cls 5118
            ld a, h		; Hyp.cls 5119
            or #C0		; Hyp.cls 5120
            ld h, a		; Hyp.cls 5121
            ld de, (var_hyp_svc_buf)		; Hyp.cls 5122
            ld bc, (asm_1_4424_n_sv_c)		; Hyp.cls 5123
            ldir		; Hyp.cls 5124
            pop bc		; Hyp.cls 5125
            call #B918              ; KL ROM DESELECT [5126]
            di		; Hyp.cls 5127
            ld hl, (var_hyp_svc_buf)		; Hyp.cls 5128
            jr asm_1_4424_n_sc_sok		; Hyp.cls 5129
asm_1_4424_n_sc_s4:		; Hyp.cls 5130
            ld a, h                 ; main RAM: its #4000-#7FFF is page 1 [5131]
            and #C0		; Hyp.cls 5132
            cp #40		; Hyp.cls 5133
            jr nz, asm_1_4424_n_sc_sok		; Hyp.cls 5134
            push hl		; Hyp.cls 5135
            ld hl, 1		; Hyp.cls 5136
            call asm_1_4424_n_sv_pgset		; Hyp.cls 5137
            pop hl		; Hyp.cls 5138
            push bc		; Hyp.cls 5139
            pop ix		; Hyp.cls 5140
asm_1_4424_n_sc_sok:		; Hyp.cls 5141
            push hl		; Hyp.cls 5142
            ld a, (asm_1_4424_n_sv_dk)           ; the destination: IY, DE [5143]
            ld hl, (asm_1_4424_n_sv_da)		; Hyp.cls 5144
            cp 1		; Hyp.cls 5145
            jr nz, asm_1_4424_n_sc_d2		; Hyp.cls 5146
            ld iy, (asm_1_4424_n_sv_ds)		; Hyp.cls 5147
            call asm_1_4424_n_sc_win		; Hyp.cls 5148
            jr asm_1_4424_n_sc_dok		; Hyp.cls 5149
asm_1_4424_n_sc_d2:		; Hyp.cls 5150
            ld de, (asm_1_4424_n_sv_ds)		; Hyp.cls 5151
            call asm_1_4424_n_sv_sw		; Hyp.cls 5152
            push bc		; Hyp.cls 5153
            pop iy		; Hyp.cls 5154
asm_1_4424_n_sc_dok:		; Hyp.cls 5155
            ex de, hl		; Hyp.cls 5156
            pop hl		; Hyp.cls 5157
            ld a, (asm_1_4424_n_sv_c)		; Hyp.cls 5158
            call asm_1_4424_n_sv_dx		; Hyp.cls 5159
            ld bc, (asm_1_4424_n_sv_c)		; Hyp.cls 5160
            ld hl, (asm_1_4424_n_sv_sa)		; Hyp.cls 5161
            add hl, bc		; Hyp.cls 5162
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 5163
            ld hl, (asm_1_4424_n_sv_da)		; Hyp.cls 5164
            add hl, bc		; Hyp.cls 5165
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 5166
            ld hl, (asm_1_4424_n_sv_n)		; Hyp.cls 5167
            or a		; Hyp.cls 5168
            sbc hl, bc		; Hyp.cls 5169
            ld (asm_1_4424_n_sv_n), hl		; Hyp.cls 5170
            ld a, (asm_1_4424_n_sv_stop)		; Hyp.cls 5171
            or a		; Hyp.cls 5172
            jp z, asm_1_4424_n_sv_copy		; Hyp.cls 5173
            ld a, (asm_1_4424_n_sv_sa + 1)		; Hyp.cls 5174
            and #3F		; Hyp.cls 5175
            ld b, a		; Hyp.cls 5176
            ld a, (asm_1_4424_n_sv_sa)		; Hyp.cls 5177
            or b		; Hyp.cls 5178
            jp nz, asm_1_4424_n_sv_copy		; Hyp.cls 5179
            ret		; Hyp.cls 5180
asm_1_4424_n_sc_room:                            ; sv_c no more than to HL's 16K page's end [5181]
            ld a, h		; Hyp.cls 5182
            and #3F		; Hyp.cls 5183
            ld h, a		; Hyp.cls 5184
            ex de, hl		; Hyp.cls 5185
            ld hl, 16384		; Hyp.cls 5186
            or a		; Hyp.cls 5187
            sbc hl, de		; Hyp.cls 5188
            ld de, (asm_1_4424_n_sv_c)		; Hyp.cls 5189
            or a		; Hyp.cls 5190
            sbc hl, de		; Hyp.cls 5191
            ret nc		; Hyp.cls 5192
            add hl, de		; Hyp.cls 5193
            ld (asm_1_4424_n_sv_c), hl		; Hyp.cls 5194
            ret		; Hyp.cls 5195
asm_1_4424_n_sc_win:                             ; HL: its place in the window [5196]
            ld a, h		; Hyp.cls 5197
            and #3F		; Hyp.cls 5198
            or #40		; Hyp.cls 5199
            ld h, a		; Hyp.cls 5200
            ret		; Hyp.cls 5201
; sv_sw - DE = a bank's C2 setting, HL = an address in it: BC = the setting with its page in the
; window, HL = the address there
asm_1_4424_n_sv_sw:		; Hyp.cls 5204
            ld a, h		; Hyp.cls 5205
            rlca		; Hyp.cls 5206
            rlca		; Hyp.cls 5207
            and 3		; Hyp.cls 5208
            add a, 4		; Hyp.cls 5209
            ld b, a		; Hyp.cls 5210
            ld a, e		; Hyp.cls 5211
            and #F8		; Hyp.cls 5212
            or b		; Hyp.cls 5213
            ld c, a		; Hyp.cls 5214
            ld b, d		; Hyp.cls 5215
            jr asm_1_4424_n_sc_win		; Hyp.cls 5216
; sv_pgset - HL = a page: BC = its RAM setting (the Memory class's port table; 0 main RAM)
asm_1_4424_n_sv_pgset:		; Hyp.cls 5218
            ld a, h		; Hyp.cls 5219
            or l		; Hyp.cls 5220
            ld bc, #7FC0		; Hyp.cls 5221
            ret z		; Hyp.cls 5222
            add hl, hl		; Hyp.cls 5223
            ld de, (mem_tport)		; Hyp.cls 5224
            add hl, de		; Hyp.cls 5225
            dec hl		; Hyp.cls 5226
            ld b, (hl)		; Hyp.cls 5227
            dec hl		; Hyp.cls 5228
            ld c, (hl)		; Hyp.cls 5229
            ret		; Hyp.cls 5230
; ---- 16-19: the claims - hardware a program drives itself (FDC, SOUND, MF2, NVRAM, M4 ...): a
; name (Byte(2-9): 8 characters, spaces after) and a unit (Byte(1): which of them - a LUN), held
; by one slot at a time; all a slot's freed when its program ends, is killed or reset (p 0). The
; answer: 16 claim - 0 yours (now, or already), else the slot holding it (255: CL_N in use);
; 17 release - 0 done, 1 not yours; 18 take - yours now, whoever had it: the slot that had it
; (0 nobody); 19 held - 0 yours, else the slot holding it (254 nobody)
asm_1_4424_n_CL_N:       equ 16		; Hyp.cls 5237
asm_1_4424_n_sv_claim:		; Hyp.cls 5238
            ld b, a                 ; B = the op [5239]
            call asm_1_4424_n_cl_find            ; Z: HL = its record [5240]
            ld a, (var_hyp_svc_t)		; Hyp.cls 5241
            ld c, a                 ; C = this slot [5242]
            jr nz, asm_1_4424_n_cl_none		; Hyp.cls 5243
            ld a, b		; Hyp.cls 5244
            cp 17		; Hyp.cls 5245
            jr z, asm_1_4424_n_cl_rel		; Hyp.cls 5246
            ld a, (hl)              ; who has it [5247]
            ld (asm_1_4424_n_sv_tn), a		; Hyp.cls 5248
            ld a, b		; Hyp.cls 5249
            cp 18		; Hyp.cls 5250
            jr nz, asm_1_4424_n_cl_who		; Hyp.cls 5251
            ld (hl), c              ; 18: taken [5252]
            ld a, (asm_1_4424_n_sv_tn)		; Hyp.cls 5253
            jr asm_1_4424_n_cl_ret		; Hyp.cls 5254
asm_1_4424_n_cl_who:		; Hyp.cls 5255
            ld a, (asm_1_4424_n_sv_tn)           ; 16, 19: 0 when it is this slot's [5256]
            cp c		; Hyp.cls 5257
            jp z, asm_1_4424_n_sv_ok		; Hyp.cls 5258
            jr asm_1_4424_n_cl_ret		; Hyp.cls 5259
asm_1_4424_n_cl_rel:		; Hyp.cls 5260
            ld a, (hl)		; Hyp.cls 5261
            cp c		; Hyp.cls 5262
            jr nz, asm_1_4424_n_cl_one		; Hyp.cls 5263
            ld (hl), 0		; Hyp.cls 5264
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5265
asm_1_4424_n_cl_none:		; Hyp.cls 5266
            ld a, b		; Hyp.cls 5267
            cp 17		; Hyp.cls 5268
            jr z, asm_1_4424_n_cl_one		; Hyp.cls 5269
            cp 19		; Hyp.cls 5270
            ld a, 254		; Hyp.cls 5271
            jr z, asm_1_4424_n_cl_ret		; Hyp.cls 5272
            ld hl, asm_1_4424_n_sv_cl            ; 16, 18: into a free record [5273]
            ld de, 10		; Hyp.cls 5274
            ld b, asm_1_4424_n_CL_N		; Hyp.cls 5275
asm_1_4424_n_cl_fr:		; Hyp.cls 5276
            ld a, (hl)		; Hyp.cls 5277
            or a		; Hyp.cls 5278
            jr z, asm_1_4424_n_cl_put		; Hyp.cls 5279
            add hl, de		; Hyp.cls 5280
            djnz asm_1_4424_n_cl_fr		; Hyp.cls 5281
            jp asm_1_4424_n_sv_err		; Hyp.cls 5282
asm_1_4424_n_cl_put:		; Hyp.cls 5283
            ld (hl), c		; Hyp.cls 5284
            inc hl		; Hyp.cls 5285
            ex de, hl		; Hyp.cls 5286
            ld hl, asm_1_4424_n_sv_blk + 1		; Hyp.cls 5287
            ld bc, 9		; Hyp.cls 5288
            ldir		; Hyp.cls 5289
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5290
asm_1_4424_n_cl_one:		; Hyp.cls 5291
            ld a, 1		; Hyp.cls 5292
asm_1_4424_n_cl_ret:		; Hyp.cls 5293
            ld sp, (asm_1_4424_n_sv_sp)		; Hyp.cls 5294
            ret		; Hyp.cls 5295
; cl_find - Z: HL = the record with sv_blk's unit and name, else NZ (B kept)
asm_1_4424_n_cl_find:		; Hyp.cls 5297
            ld hl, asm_1_4424_n_sv_cl		; Hyp.cls 5298
            ld c, asm_1_4424_n_CL_N		; Hyp.cls 5299
asm_1_4424_n_cl_f1:		; Hyp.cls 5300
            ld a, (hl)		; Hyp.cls 5301
            or a		; Hyp.cls 5302
            jr z, asm_1_4424_n_cl_f3             ; (a free record) [5303]
            push hl		; Hyp.cls 5304
            push bc		; Hyp.cls 5305
            inc hl		; Hyp.cls 5306
            ld de, asm_1_4424_n_sv_blk + 1		; Hyp.cls 5307
            ld b, 9		; Hyp.cls 5308
asm_1_4424_n_cl_f2:		; Hyp.cls 5309
            ld a, (de)		; Hyp.cls 5310
            cp (hl)		; Hyp.cls 5311
            jr nz, asm_1_4424_n_cl_f4		; Hyp.cls 5312
            inc hl		; Hyp.cls 5313
            inc de		; Hyp.cls 5314
            djnz asm_1_4424_n_cl_f2		; Hyp.cls 5315
asm_1_4424_n_cl_f4:		; Hyp.cls 5316
            pop bc		; Hyp.cls 5317
            pop hl		; Hyp.cls 5318
            ret z		; Hyp.cls 5319
asm_1_4424_n_cl_f3:		; Hyp.cls 5320
            ld de, 10		; Hyp.cls 5321
            add hl, de		; Hyp.cls 5322
            dec c		; Hyp.cls 5323
            jr nz, asm_1_4424_n_cl_f1		; Hyp.cls 5324
            or 1		; Hyp.cls 5325
            ret		; Hyp.cls 5326
; p 0: slot t's claims all freed
asm_1_4424_n_sv_cfree:		; Hyp.cls 5328
            ld a, (var_hyp_svc_t)		; Hyp.cls 5329
            ld c, a		; Hyp.cls 5330
            ld hl, asm_1_4424_n_sv_cl		; Hyp.cls 5331
            ld de, 10		; Hyp.cls 5332
            ld b, asm_1_4424_n_CL_N		; Hyp.cls 5333
asm_1_4424_n_cl_cf:		; Hyp.cls 5334
            ld a, (hl)		; Hyp.cls 5335
            cp c		; Hyp.cls 5336
            jr nz, asm_1_4424_n_cl_cf1		; Hyp.cls 5337
            ld (hl), 0		; Hyp.cls 5338
asm_1_4424_n_cl_cf1:		; Hyp.cls 5339
            add hl, de		; Hyp.cls 5340
            djnz asm_1_4424_n_cl_cf		; Hyp.cls 5341
            call asm_1_4424_n_pt_free            ; its ports closed, its calls forgotten (C = the slot) [5342]
            ld a, (asm_1_4424_n_nt_rom)          ; its sockets closed [5343]
            inc a		; Hyp.cls 5344
            jp z, asm_1_4424_n_sv_ok		; Hyp.cls 5345
            ld b, 0		; Hyp.cls 5346
asm_1_4424_n_cl_cs:		; Hyp.cls 5347
            ld hl, asm_1_4424_n_nt_own		; Hyp.cls 5348
            ld e, b		; Hyp.cls 5349
            ld d, 0		; Hyp.cls 5350
            add hl, de		; Hyp.cls 5351
            ld a, (hl)		; Hyp.cls 5352
            cp c		; Hyp.cls 5353
            jr nz, asm_1_4424_n_cl_cs1		; Hyp.cls 5354
            push bc		; Hyp.cls 5355
            ld a, b		; Hyp.cls 5356
            call asm_1_4424_n_nt_close		; Hyp.cls 5357
            pop bc		; Hyp.cls 5358
asm_1_4424_n_cl_cs1:		; Hyp.cls 5359
            inc b		; Hyp.cls 5360
            ld a, b		; Hyp.cls 5361
            cp 8		; Hyp.cls 5362
            jr c, asm_1_4424_n_cl_cs		; Hyp.cls 5363
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5364
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
;       the reset) to Word(6), Word(8) - network or not
;   21  a name looked up: Word(2) where it is, Byte(4) its length (63 at most) - 1: started
;       (22 with 255 then: the state, 0 found - its IP at +4)
;   22  socket Byte(1)'s 16 bytes to Word(2) (255: the lookup's): its state
;   23  a TCP socket: its number (255 none)
;   24  socket Byte(1) connected to IP Byte(2-5), port Word(6): 0 started (22: 1 still, 0 done)
;   25  Word(4) bytes (1-240) from Word(2) sent on socket Byte(1): 0 done
;   26  up to Word(4) bytes (2048 at most) of socket Byte(1)'s to Word(2): 0 done - how many
;       written back to the request's Word(6)
;   27  socket Byte(1) closed
asm_1_4424_n_NT_N:       equ 8                   ; sockets 0-7 [5385]
asm_1_4424_n_sv_net:		; Hyp.cls 5386
            ld b, a		; Hyp.cls 5387
            cp 20		; Hyp.cls 5388
            jr z, asm_1_4424_n_nt_20		; Hyp.cls 5389
            ld a, (asm_1_4424_n_nt_rom)		; Hyp.cls 5390
            inc a		; Hyp.cls 5391
            jp z, asm_1_4424_n_sv_err            ; (no network) [5392]
            ld a, b		; Hyp.cls 5393
            cp 21		; Hyp.cls 5394
            jp z, asm_1_4424_n_nt_look		; Hyp.cls 5395
            cp 23		; Hyp.cls 5396
            jp z, asm_1_4424_n_nt_sock		; Hyp.cls 5397
            call asm_1_4424_n_nt_chk             ; (the rest: one of the slot's sockets) [5398]
            ld a, b		; Hyp.cls 5399
            cp 22		; Hyp.cls 5400
            jp z, asm_1_4424_n_nt_stat		; Hyp.cls 5401
            cp 24		; Hyp.cls 5402
            jp z, asm_1_4424_n_nt_conn		; Hyp.cls 5403
            cp 25		; Hyp.cls 5404
            jp z, asm_1_4424_n_nt_send		; Hyp.cls 5405
            cp 26		; Hyp.cls 5406
            jp z, asm_1_4424_n_nt_recv		; Hyp.cls 5407
            ld a, (asm_1_4424_n_sv_blk + 1)      ; 27 [5408]
            call asm_1_4424_n_nt_close		; Hyp.cls 5409
            jp asm_1_4424_n_nt_ans		; Hyp.cls 5410
asm_1_4424_n_nt_20:		; Hyp.cls 5411
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 5412
            or a		; Hyp.cls 5413
            jr nz, asm_1_4424_n_nt_20a		; Hyp.cls 5414
            ld a, (asm_1_4424_n_nt_rom)		; Hyp.cls 5415
            jp asm_1_4424_n_nt_ret		; Hyp.cls 5416
asm_1_4424_n_nt_20a:		; Hyp.cls 5417
            cp 4		; Hyp.cls 5418
            jr z, asm_1_4424_n_nt_uptime		; Hyp.cls 5419
            cp 3		; Hyp.cls 5420
            jr z, asm_1_4424_n_nt_time		; Hyp.cls 5421
            dec a		; Hyp.cls 5422
            jr nz, asm_1_4424_n_nt_off		; Hyp.cls 5423
            ld a, (asm_1_4424_n_sv_blk + 2)      ; on: the M4's ROM, where its answers and sockets are [5424]
            ld (asm_1_4424_n_nt_rom), a		; Hyp.cls 5425
            ld a, 1                 ; the network indicator: up [5426]
            ld (var_hyp_ntu), a		; Hyp.cls 5427
            ld hl, #FF02		; Hyp.cls 5428
            ld de, asm_1_4424_n_nt_rsp		; Hyp.cls 5429
            ld bc, 2		; Hyp.cls 5430
            call asm_1_4424_n_nt_rd		; Hyp.cls 5431
            ld hl, #FF06		; Hyp.cls 5432
            ld de, asm_1_4424_n_nt_skt		; Hyp.cls 5433
            ld bc, 2		; Hyp.cls 5434
            call asm_1_4424_n_nt_rd		; Hyp.cls 5435
            ld c, 255               ; M4 0: CyborgOS's [5436]
            call asm_1_4424_n_nt_m4c		; Hyp.cls 5437
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5438
asm_1_4424_n_nt_off:		; Hyp.cls 5439
            ld b, 0                 ; off: every socket closed, M4 0 given back [5440]
asm_1_4424_n_nt_of1:		; Hyp.cls 5441
            ld hl, asm_1_4424_n_nt_own		; Hyp.cls 5442
            ld e, b		; Hyp.cls 5443
            ld d, 0		; Hyp.cls 5444
            add hl, de		; Hyp.cls 5445
            ld a, (hl)		; Hyp.cls 5446
            or a		; Hyp.cls 5447
            jr z, asm_1_4424_n_nt_of2		; Hyp.cls 5448
            push bc		; Hyp.cls 5449
            ld a, b		; Hyp.cls 5450
            call asm_1_4424_n_nt_close		; Hyp.cls 5451
            pop bc		; Hyp.cls 5452
asm_1_4424_n_nt_of2:		; Hyp.cls 5453
            inc b		; Hyp.cls 5454
            ld a, b		; Hyp.cls 5455
            cp asm_1_4424_n_NT_N		; Hyp.cls 5456
            jr c, asm_1_4424_n_nt_of1		; Hyp.cls 5457
            ld c, 0		; Hyp.cls 5458
            call asm_1_4424_n_nt_m4c		; Hyp.cls 5459
            ld a, 255		; Hyp.cls 5460
            ld (asm_1_4424_n_nt_rom), a		; Hyp.cls 5461
            xor a                   ; the network indicator: off [5462]
            ld (var_hyp_ntu), a		; Hyp.cls 5463
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5464
asm_1_4424_n_nt_time:		; Hyp.cls 5465
            call #BD0D              ; 3: KL TIME PLEASE - its low word (300 a second) to Word(6) [5466]
            di		; Hyp.cls 5467
            ld (asm_1_4424_n_sv_tmp + 4), hl		; Hyp.cls 5468
            ld hl, (var_hyp_svc_p)		; Hyp.cls 5469
            ld de, 6		; Hyp.cls 5470
            add hl, de		; Hyp.cls 5471
            ex de, hl		; Hyp.cls 5472
            ld hl, asm_1_4424_n_sv_tmp + 4		; Hyp.cls 5473
            ld bc, 2		; Hyp.cls 5474
            call asm_1_4424_n_sv_out		; Hyp.cls 5475
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5476
asm_1_4424_n_nt_uptime:		; Hyp.cls 5477
            call #BD0D              ; 4: KL TIME PLEASE - all 32 bits (300 a second since the reset) to Word(6), Word(8) [5478]
            di		; Hyp.cls 5479
            ld (asm_1_4424_n_sv_tmp + 4), hl		; Hyp.cls 5480
            ld (asm_1_4424_n_sv_tmp + 6), de		; Hyp.cls 5481
            ld hl, (var_hyp_svc_p)		; Hyp.cls 5482
            ld de, 6		; Hyp.cls 5483
            add hl, de		; Hyp.cls 5484
            ex de, hl		; Hyp.cls 5485
            ld hl, asm_1_4424_n_sv_tmp + 4		; Hyp.cls 5486
            ld bc, 4		; Hyp.cls 5487
            call asm_1_4424_n_sv_out		; Hyp.cls 5488
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5489
asm_1_4424_n_nt_ans:		; Hyp.cls 5490
            ld a, (asm_1_4424_n_sv_tmp + 3)      ; the M4's answer [5491]
asm_1_4424_n_nt_ret:		; Hyp.cls 5492
            ld sp, (asm_1_4424_n_sv_sp)		; Hyp.cls 5493
            ret		; Hyp.cls 5494
; 21: a name looked up
asm_1_4424_n_nt_look:		; Hyp.cls 5496
            ld a, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 5497
            cp 64		; Hyp.cls 5498
            jp nc, asm_1_4424_n_sv_err		; Hyp.cls 5499
            ld c, a		; Hyp.cls 5500
            ld b, 0		; Hyp.cls 5501
            ld hl, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 5502
            ld de, asm_1_4424_n_nt_pk + 3		; Hyp.cls 5503
            push bc		; Hyp.cls 5504
            call asm_1_4424_n_sv_in		; Hyp.cls 5505
            pop bc		; Hyp.cls 5506
            ld hl, asm_1_4424_n_nt_pk + 3		; Hyp.cls 5507
            add hl, bc		; Hyp.cls 5508
            ld (hl), 0		; Hyp.cls 5509
            ld a, c		; Hyp.cls 5510
            add a, 3		; Hyp.cls 5511
            ld hl, #4336            ; C_NETHOSTIP [5512]
            call asm_1_4424_n_nt_hdr		; Hyp.cls 5513
            call asm_1_4424_n_nt_go		; Hyp.cls 5514
            jr asm_1_4424_n_nt_ans		; Hyp.cls 5515
; 22: a socket's 16 bytes to the slot
asm_1_4424_n_nt_stat:		; Hyp.cls 5517
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 5518
            call asm_1_4424_n_nt_ent		; Hyp.cls 5519
            ld de, asm_1_4424_n_sv_tmp		; Hyp.cls 5520
            ld bc, 16		; Hyp.cls 5521
            call asm_1_4424_n_nt_rd		; Hyp.cls 5522
            ld hl, asm_1_4424_n_sv_tmp		; Hyp.cls 5523
            ld de, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 5524
            ld bc, 16		; Hyp.cls 5525
            call asm_1_4424_n_sv_out		; Hyp.cls 5526
            ld a, (asm_1_4424_n_sv_tmp)		; Hyp.cls 5527
            jr asm_1_4424_n_nt_ret		; Hyp.cls 5528
; 23: a TCP socket
asm_1_4424_n_nt_sock:		; Hyp.cls 5530
            ld hl, #0600            ; (domain 0, type 0, protocol 6: TCP) [5531]
            ld (asm_1_4424_n_nt_pk + 4), hl		; Hyp.cls 5532
            xor a		; Hyp.cls 5533
            ld (asm_1_4424_n_nt_pk + 3), a		; Hyp.cls 5534
            ld a, 5		; Hyp.cls 5535
            ld hl, #4331            ; C_NETSOCKET [5536]
            call asm_1_4424_n_nt_hdr		; Hyp.cls 5537
            call asm_1_4424_n_nt_go		; Hyp.cls 5538
            ld a, (asm_1_4424_n_sv_tmp + 3)		; Hyp.cls 5539
            cp asm_1_4424_n_NT_N		; Hyp.cls 5540
            jp nc, asm_1_4424_n_nt_sk1		; Hyp.cls 5541
            ld e, a		; Hyp.cls 5542
            ld d, 0		; Hyp.cls 5543
            ld hl, asm_1_4424_n_nt_own		; Hyp.cls 5544
            add hl, de		; Hyp.cls 5545
            ld a, (var_hyp_svc_t)		; Hyp.cls 5546
            ld (hl), a		; Hyp.cls 5547
            jp asm_1_4424_n_nt_ans		; Hyp.cls 5548
asm_1_4424_n_nt_sk1:		; Hyp.cls 5549
            cp 255		; Hyp.cls 5550
            jp z, asm_1_4424_n_nt_ret		; Hyp.cls 5551
            call asm_1_4424_n_nt_close           ; (one this can't keep: closed) [5552]
            ld a, 255		; Hyp.cls 5553
            jp asm_1_4424_n_nt_ret		; Hyp.cls 5554
; 24: connected to an IP address and port
asm_1_4424_n_nt_conn:		; Hyp.cls 5556
            ld hl, asm_1_4424_n_sv_blk + 1		; Hyp.cls 5557
            ld de, asm_1_4424_n_nt_pk + 3		; Hyp.cls 5558
            ld bc, 7		; Hyp.cls 5559
            ldir		; Hyp.cls 5560
            ld a, 9		; Hyp.cls 5561
            ld hl, #4332            ; C_NETCONNECT [5562]
            call asm_1_4424_n_nt_hdr		; Hyp.cls 5563
            call asm_1_4424_n_nt_go		; Hyp.cls 5564
            jp asm_1_4424_n_nt_ans		; Hyp.cls 5565
; 25: bytes sent
asm_1_4424_n_nt_send:		; Hyp.cls 5567
            ld a, 4                 ; the network indicator: blink for the next ~2s (4 x 0.5s) [5568]
            ld (var_hyp_nta), a		; Hyp.cls 5569
            ld hl, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 5570
            ld a, h		; Hyp.cls 5571
            or a		; Hyp.cls 5572
            jp nz, asm_1_4424_n_sv_err		; Hyp.cls 5573
            ld a, l		; Hyp.cls 5574
            or a		; Hyp.cls 5575
            jp z, asm_1_4424_n_sv_err		; Hyp.cls 5576
            cp 241		; Hyp.cls 5577
            jp nc, asm_1_4424_n_sv_err		; Hyp.cls 5578
            ld (asm_1_4424_n_nt_pk + 4), hl		; Hyp.cls 5579
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 5580
            ld (asm_1_4424_n_nt_pk + 3), a		; Hyp.cls 5581
            ld b, h		; Hyp.cls 5582
            ld c, l		; Hyp.cls 5583
            ld hl, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 5584
            ld de, asm_1_4424_n_nt_pk + 6		; Hyp.cls 5585
            call asm_1_4424_n_sv_in		; Hyp.cls 5586
            ld a, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 5587
            add a, 5		; Hyp.cls 5588
            ld hl, #4334            ; C_NETSEND [5589]
            call asm_1_4424_n_nt_hdr		; Hyp.cls 5590
            call asm_1_4424_n_nt_go		; Hyp.cls 5591
            jp asm_1_4424_n_nt_ans		; Hyp.cls 5592
; 26: bytes received
asm_1_4424_n_nt_recv:		; Hyp.cls 5594
            ld a, 4                 ; the network indicator: blink for the next ~2s (4 x 0.5s) [5595]
            ld (var_hyp_nta), a		; Hyp.cls 5596
            ld hl, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 5597
            ld de, 2049		; Hyp.cls 5598
            or a		; Hyp.cls 5599
            sbc hl, de		; Hyp.cls 5600
            jp nc, asm_1_4424_n_sv_err		; Hyp.cls 5601
            ld hl, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 5602
            ld (asm_1_4424_n_nt_pk + 4), hl		; Hyp.cls 5603
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 5604
            ld (asm_1_4424_n_nt_pk + 3), a		; Hyp.cls 5605
            ld a, 5		; Hyp.cls 5606
            ld hl, #4335            ; C_NETRECV [5607]
            call asm_1_4424_n_nt_hdr		; Hyp.cls 5608
            call asm_1_4424_n_nt_go		; Hyp.cls 5609
            ld hl, 0		; Hyp.cls 5610
            ld a, (asm_1_4424_n_sv_tmp + 3)		; Hyp.cls 5611
            or a		; Hyp.cls 5612
            jr nz, asm_1_4424_n_nt_rc1		; Hyp.cls 5613
            ld hl, (asm_1_4424_n_sv_tmp + 4)     ; how many (no more than asked for) [5614]
            ld de, (asm_1_4424_n_sv_blk + 4)		; Hyp.cls 5615
            or a		; Hyp.cls 5616
            sbc hl, de		; Hyp.cls 5617
            add hl, de		; Hyp.cls 5618
            jr c, asm_1_4424_n_nt_rc0		; Hyp.cls 5619
            ex de, hl		; Hyp.cls 5620
asm_1_4424_n_nt_rc0:		; Hyp.cls 5621
            ld (asm_1_4424_n_sv_n), hl		; Hyp.cls 5622
            push hl		; Hyp.cls 5623
            ld hl, (asm_1_4424_n_nt_rsp)         ; from the M4's ROM to the slot [5624]
            ld de, 6		; Hyp.cls 5625
            add hl, de		; Hyp.cls 5626
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 5627
            ld a, (asm_1_4424_n_nt_rom)		; Hyp.cls 5628
            ld (asm_1_4424_n_sv_ss), a		; Hyp.cls 5629
            ld a, 3		; Hyp.cls 5630
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 5631
            ld hl, (asm_1_4424_n_sv_blk + 2)		; Hyp.cls 5632
            ld (asm_1_4424_n_sv_da), hl		; Hyp.cls 5633
            xor a		; Hyp.cls 5634
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 5635
            call asm_1_4424_n_sv_copy		; Hyp.cls 5636
            pop hl		; Hyp.cls 5637
asm_1_4424_n_nt_rc1:		; Hyp.cls 5638
            ld (asm_1_4424_n_sv_tmp + 4), hl     ; how many: to the request's Word(6) [5639]
            ld hl, (var_hyp_svc_p)		; Hyp.cls 5640
            ld de, 6		; Hyp.cls 5641
            add hl, de		; Hyp.cls 5642
            ex de, hl		; Hyp.cls 5643
            ld hl, asm_1_4424_n_sv_tmp + 4		; Hyp.cls 5644
            ld bc, 2		; Hyp.cls 5645
            call asm_1_4424_n_sv_out		; Hyp.cls 5646
            jp asm_1_4424_n_nt_ans		; Hyp.cls 5647
; nt_chk - Byte(1): a socket of this slot's (else the request fails)
asm_1_4424_n_nt_chk:		; Hyp.cls 5649
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 5650
            cp asm_1_4424_n_NT_N		; Hyp.cls 5651
            jp nc, asm_1_4424_n_nt_chk1		; Hyp.cls 5652
            ld e, a		; Hyp.cls 5653
            ld d, 0		; Hyp.cls 5654
            ld hl, asm_1_4424_n_nt_own		; Hyp.cls 5655
            add hl, de		; Hyp.cls 5656
            ld a, (var_hyp_svc_t)		; Hyp.cls 5657
            cp (hl)		; Hyp.cls 5658
            ret z		; Hyp.cls 5659
            jp asm_1_4424_n_sv_err		; Hyp.cls 5660
asm_1_4424_n_nt_chk1:		; Hyp.cls 5661
            cp 255                  ; (255: the lookup's - 22 only) [5662]
            jp nz, asm_1_4424_n_sv_err		; Hyp.cls 5663
            ld a, b		; Hyp.cls 5664
            cp 22		; Hyp.cls 5665
            ret z		; Hyp.cls 5666
            jp asm_1_4424_n_sv_err		; Hyp.cls 5667
; nt_close - socket A closed (no longer anyone's)
asm_1_4424_n_nt_close:		; Hyp.cls 5669
            ld (asm_1_4424_n_nt_pk + 3), a		; Hyp.cls 5670
            cp asm_1_4424_n_NT_N		; Hyp.cls 5671
            jr nc, asm_1_4424_n_nt_cl1		; Hyp.cls 5672
            ld e, a		; Hyp.cls 5673
            ld d, 0		; Hyp.cls 5674
            ld hl, asm_1_4424_n_nt_own		; Hyp.cls 5675
            add hl, de		; Hyp.cls 5676
            ld (hl), 0		; Hyp.cls 5677
asm_1_4424_n_nt_cl1:		; Hyp.cls 5678
            ld a, 3		; Hyp.cls 5679
            ld hl, #4333            ; C_NETCLOSE [5680]
            call asm_1_4424_n_nt_hdr		; Hyp.cls 5681
; nt_go - the packet at nt_pk to the M4 (its size first); the answer's first 8 bytes to sv_tmp
asm_1_4424_n_nt_go:		; Hyp.cls 5683
            ld hl, asm_1_4424_n_nt_pk		; Hyp.cls 5684
            ld bc, #FE00		; Hyp.cls 5685
            ld d, (hl)		; Hyp.cls 5686
            inc d		; Hyp.cls 5687
asm_1_4424_n_nt_go1:		; Hyp.cls 5688
            inc b		; Hyp.cls 5689
            outi		; Hyp.cls 5690
            dec d		; Hyp.cls 5691
            jr nz, asm_1_4424_n_nt_go1		; Hyp.cls 5692
            ld bc, #FC00		; Hyp.cls 5693
            out (c), c		; Hyp.cls 5694
            ld hl, (asm_1_4424_n_nt_rsp)		; Hyp.cls 5695
            ld de, asm_1_4424_n_sv_tmp		; Hyp.cls 5696
            ld bc, 8		; Hyp.cls 5697
; nt_rd - BC bytes of the M4's ROM from HL to DE (here)
asm_1_4424_n_nt_rd:		; Hyp.cls 5699
            push hl		; Hyp.cls 5700
            push de		; Hyp.cls 5701
            push bc		; Hyp.cls 5702
            ld a, (asm_1_4424_n_nt_rom)		; Hyp.cls 5703
            ld c, a		; Hyp.cls 5704
            call #B90F              ; KL ROM SELECT [5705]
            di		; Hyp.cls 5706
            ld (asm_1_4424_n_nt_old), bc		; Hyp.cls 5707
            pop bc		; Hyp.cls 5708
            pop de		; Hyp.cls 5709
            pop hl		; Hyp.cls 5710
            ld a, h		; Hyp.cls 5711
            or #C0		; Hyp.cls 5712
            ld h, a		; Hyp.cls 5713
            ldir		; Hyp.cls 5714
            ld bc, (asm_1_4424_n_nt_old)		; Hyp.cls 5715
            call #B918              ; KL ROM DESELECT [5716]
            di		; Hyp.cls 5717
            ret		; Hyp.cls 5718
; nt_hdr - the packet's size A, its command HL
asm_1_4424_n_nt_hdr:		; Hyp.cls 5720
            ld (asm_1_4424_n_nt_pk), a		; Hyp.cls 5721
            ld (asm_1_4424_n_nt_pk + 1), hl		; Hyp.cls 5722
            ret		; Hyp.cls 5723
; nt_ent - socket A's 16 bytes in the M4's table: HL (255: the first - the lookup's)
asm_1_4424_n_nt_ent:		; Hyp.cls 5725
            cp 255		; Hyp.cls 5726
            jr nz, asm_1_4424_n_nt_e1		; Hyp.cls 5727
            xor a		; Hyp.cls 5728
asm_1_4424_n_nt_e1:		; Hyp.cls 5729
            ld l, a		; Hyp.cls 5730
            ld h, 0		; Hyp.cls 5731
            add hl, hl		; Hyp.cls 5732
            add hl, hl		; Hyp.cls 5733
            add hl, hl		; Hyp.cls 5734
            add hl, hl		; Hyp.cls 5735
            ld de, (asm_1_4424_n_nt_skt)		; Hyp.cls 5736
            add hl, de		; Hyp.cls 5737
            ret		; Hyp.cls 5738
; nt_m4c - the claim on M4 0 held by C (255 CyborgOS, 0 given back)
asm_1_4424_n_nt_m4c:		; Hyp.cls 5740
            push bc		; Hyp.cls 5741
            ld hl, asm_1_4424_n_sv_blk + 1		; Hyp.cls 5742
            ld (hl), 0		; Hyp.cls 5743
            inc hl		; Hyp.cls 5744
            ld (hl), 'M'		; Hyp.cls 5745
            inc hl		; Hyp.cls 5746
            ld (hl), '4'		; Hyp.cls 5747
            ld b, 6		; Hyp.cls 5748
asm_1_4424_n_nt_m4c1:		; Hyp.cls 5749
            inc hl		; Hyp.cls 5750
            ld (hl), ' '		; Hyp.cls 5751
            djnz asm_1_4424_n_nt_m4c1		; Hyp.cls 5752
            call asm_1_4424_n_cl_find		; Hyp.cls 5753
            pop bc		; Hyp.cls 5754
            jr nz, asm_1_4424_n_nt_m4c2		; Hyp.cls 5755
            ld (hl), c              ; (CyborgOS's now - or no one's) [5756]
            ret		; Hyp.cls 5757
asm_1_4424_n_nt_m4c2:		; Hyp.cls 5758
            ld a, c		; Hyp.cls 5759
            or a		; Hyp.cls 5760
            ret z		; Hyp.cls 5761
            ld hl, asm_1_4424_n_sv_cl            ; into a free record [5762]
            ld de, 10		; Hyp.cls 5763
            ld b, asm_1_4424_n_CL_N		; Hyp.cls 5764
asm_1_4424_n_nt_m4c3:		; Hyp.cls 5765
            ld a, (hl)		; Hyp.cls 5766
            or a		; Hyp.cls 5767
            jr z, asm_1_4424_n_nt_m4c4		; Hyp.cls 5768
            add hl, de		; Hyp.cls 5769
            djnz asm_1_4424_n_nt_m4c3		; Hyp.cls 5770
            ret		; Hyp.cls 5771
asm_1_4424_n_nt_m4c4:		; Hyp.cls 5772
            ld (hl), c		; Hyp.cls 5773
            inc hl		; Hyp.cls 5774
            ex de, hl		; Hyp.cls 5775
            ld hl, asm_1_4424_n_sv_blk + 1		; Hyp.cls 5776
            ld bc, 9		; Hyp.cls 5777
            ldir		; Hyp.cls 5778
            ret		; Hyp.cls 5779
; sv_in - BC bytes from the slot's HL to DE (here, in the service page)
asm_1_4424_n_sv_in:		; Hyp.cls 5781
            ld (asm_1_4424_n_sv_sa), hl		; Hyp.cls 5782
            ld (asm_1_4424_n_sv_da), de		; Hyp.cls 5783
            ld (asm_1_4424_n_sv_n), bc		; Hyp.cls 5784
            ld a, 2		; Hyp.cls 5785
            ld (asm_1_4424_n_sv_sk), a		; Hyp.cls 5786
            ld hl, (var_hyp_svc_setting)		; Hyp.cls 5787
            ld (asm_1_4424_n_sv_ss), hl		; Hyp.cls 5788
            ld a, 1		; Hyp.cls 5789
            ld (asm_1_4424_n_sv_dk), a		; Hyp.cls 5790
            ld hl, (var_hyp_svp)		; Hyp.cls 5791
            ld (asm_1_4424_n_sv_ds), hl		; Hyp.cls 5792
            xor a		; Hyp.cls 5793
            ld (asm_1_4424_n_sv_stop), a		; Hyp.cls 5794
            call asm_1_4424_n_sv_copy		; Hyp.cls 5795
            ld a, 2                 ; (the copies to the slot again) [5796]
            ld (asm_1_4424_n_sv_dk), a		; Hyp.cls 5797
            ld hl, (var_hyp_svc_setting)		; Hyp.cls 5798
            ld (asm_1_4424_n_sv_ds), hl		; Hyp.cls 5799
            ret		; Hyp.cls 5800
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
asm_1_4424_n_PT_N:       equ 8		; Hyp.cls 5816
asm_1_4424_n_PT_SZ:      equ 140		; Hyp.cls 5817
asm_1_4424_n_sv_port:		; Hyp.cls 5818
            ld (asm_1_4424_n_pt_op), a		; Hyp.cls 5819
            call asm_1_4424_n_pt_find            ; Z: HL = the port named Byte(2-9); pt_fr: a free record (0: none) [5820]
            ld (asm_1_4424_n_pt_rec), hl		; Hyp.cls 5821
            ld a, 0		; Hyp.cls 5822
            jr z, asm_1_4424_n_sp_f		; Hyp.cls 5823
            inc a		; Hyp.cls 5824
asm_1_4424_n_sp_f:		; Hyp.cls 5825
            ld (asm_1_4424_n_pt_has), a          ; 0 there, 1 not [5826]
            ld a, (var_hyp_svc_t)		; Hyp.cls 5827
            ld (asm_1_4424_n_pt_me), a		; Hyp.cls 5828
            ld a, (asm_1_4424_n_sv_blk + 12)     ; the length: 128 at most [5829]
            cp 129		; Hyp.cls 5830
            jr c, asm_1_4424_n_sp_l		; Hyp.cls 5831
            ld a, 128		; Hyp.cls 5832
            ld (asm_1_4424_n_sv_blk + 12), a		; Hyp.cls 5833
asm_1_4424_n_sp_l:		; Hyp.cls 5834
            ld a, (asm_1_4424_n_pt_op)		; Hyp.cls 5835
            cp 28		; Hyp.cls 5836
            jr z, asm_1_4424_n_pt_open		; Hyp.cls 5837
            ld a, (asm_1_4424_n_pt_has)		; Hyp.cls 5838
            or a		; Hyp.cls 5839
            jr nz, asm_1_4424_n_pt_two           ; (no such port) [5840]
            ld hl, (asm_1_4424_n_pt_rec)		; Hyp.cls 5841
            ld a, (asm_1_4424_n_pt_op)		; Hyp.cls 5842
            cp 29		; Hyp.cls 5843
            jr z, asm_1_4424_n_pt_close		; Hyp.cls 5844
            cp 30		; Hyp.cls 5845
            jp z, asm_1_4424_n_pt_call		; Hyp.cls 5846
            cp 31		; Hyp.cls 5847
            jp z, asm_1_4424_n_pt_poll		; Hyp.cls 5848
            cp 32		; Hyp.cls 5849
            jp z, asm_1_4424_n_pt_recv		; Hyp.cls 5850
            jp asm_1_4424_n_pt_reply		; Hyp.cls 5851
asm_1_4424_n_pt_two:		; Hyp.cls 5852
            ld a, 2		; Hyp.cls 5853
            jr asm_1_4424_n_pt_ret		; Hyp.cls 5854
asm_1_4424_n_pt_one:		; Hyp.cls 5855
            ld a, 1		; Hyp.cls 5856
asm_1_4424_n_pt_ret:		; Hyp.cls 5857
            ld sp, (asm_1_4424_n_sv_sp)		; Hyp.cls 5858
            ret		; Hyp.cls 5859
; 28: open
asm_1_4424_n_pt_open:		; Hyp.cls 5861
            ld a, (asm_1_4424_n_pt_has)		; Hyp.cls 5862
            or a		; Hyp.cls 5863
            jr nz, asm_1_4424_n_po_new		; Hyp.cls 5864
            ld hl, (asm_1_4424_n_pt_rec)		; Hyp.cls 5865
            ld a, (asm_1_4424_n_pt_me)		; Hyp.cls 5866
            cp (hl)		; Hyp.cls 5867
            jp z, asm_1_4424_n_sv_ok		; Hyp.cls 5868
            jr asm_1_4424_n_pt_two		; Hyp.cls 5869
asm_1_4424_n_po_new:		; Hyp.cls 5870
            ld hl, (asm_1_4424_n_pt_fr)		; Hyp.cls 5871
            ld a, h		; Hyp.cls 5872
            or l		; Hyp.cls 5873
            jp z, asm_1_4424_n_sv_err		; Hyp.cls 5874
            ld a, (asm_1_4424_n_pt_me)		; Hyp.cls 5875
            ld (hl), a		; Hyp.cls 5876
            inc hl		; Hyp.cls 5877
            ex de, hl		; Hyp.cls 5878
            ld hl, asm_1_4424_n_sv_blk + 2		; Hyp.cls 5879
            ld bc, 8		; Hyp.cls 5880
            ldir		; Hyp.cls 5881
            ex de, hl		; Hyp.cls 5882
            xor a		; Hyp.cls 5883
            ld (hl), a              ; free [5884]
            inc hl		; Hyp.cls 5885
            ld (hl), a              ; no caller [5886]
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5887
; 29: close
asm_1_4424_n_pt_close:		; Hyp.cls 5889
            ld a, (asm_1_4424_n_pt_me)		; Hyp.cls 5890
            cp (hl)		; Hyp.cls 5891
            jr nz, asm_1_4424_n_pt_two		; Hyp.cls 5892
            ld (hl), 0		; Hyp.cls 5893
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5894
; 30: call - the message into the box (the box busy: 1)
asm_1_4424_n_pt_call:		; Hyp.cls 5896
            ld de, 9		; Hyp.cls 5897
            add hl, de		; Hyp.cls 5898
            ld a, (hl)		; Hyp.cls 5899
            or a		; Hyp.cls 5900
            jr nz, asm_1_4424_n_pt_one		; Hyp.cls 5901
            inc hl		; Hyp.cls 5902
            ld a, (asm_1_4424_n_pt_me)		; Hyp.cls 5903
            ld (hl), a              ; the caller [5904]
            inc hl		; Hyp.cls 5905
            ld a, (asm_1_4424_n_sv_blk + 12)		; Hyp.cls 5906
            ld (hl), a              ; the length [5907]
            inc hl		; Hyp.cls 5908
            ex de, hl               ; DE = the box [5909]
            ld c, a		; Hyp.cls 5910
            ld b, 0		; Hyp.cls 5911
            ld a, b		; Hyp.cls 5912
            or c		; Hyp.cls 5913
            jr z, asm_1_4424_n_pc_0		; Hyp.cls 5914
            ld hl, (asm_1_4424_n_sv_blk + 10)		; Hyp.cls 5915
            call asm_1_4424_n_sv_in		; Hyp.cls 5916
asm_1_4424_n_pc_0:		; Hyp.cls 5917
            ld hl, (asm_1_4424_n_pt_rec)		; Hyp.cls 5918
            ld de, 9		; Hyp.cls 5919
            add hl, de		; Hyp.cls 5920
            ld (hl), 1              ; a message in [5921]
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5922
; 31: the answer to this slot's call
asm_1_4424_n_pt_poll:		; Hyp.cls 5924
            ld de, 9		; Hyp.cls 5925
            add hl, de		; Hyp.cls 5926
            ld a, (hl)		; Hyp.cls 5927
            or a		; Hyp.cls 5928
            jp z, asm_1_4424_n_pt_two            ; (no call) [5929]
            inc hl		; Hyp.cls 5930
            ld a, (asm_1_4424_n_pt_me)		; Hyp.cls 5931
            cp (hl)		; Hyp.cls 5932
            jp nz, asm_1_4424_n_pt_two           ; (not this slot's call) [5933]
            dec hl		; Hyp.cls 5934
            ld a, (hl)		; Hyp.cls 5935
            cp 3		; Hyp.cls 5936
            jp nz, asm_1_4424_n_pt_one           ; not answered yet [5937]
            ld (hl), 0              ; the box free again [5938]
            inc hl		; Hyp.cls 5939
            ld (hl), 0		; Hyp.cls 5940
            call asm_1_4424_n_pt_give            ; the answer to the slot, its length to Byte(12) [5941]
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5942
; 32: the server's next message
asm_1_4424_n_pt_recv:		; Hyp.cls 5944
            ld a, (asm_1_4424_n_pt_me)		; Hyp.cls 5945
            cp (hl)		; Hyp.cls 5946
            jp nz, asm_1_4424_n_pt_two		; Hyp.cls 5947
            ld de, 9		; Hyp.cls 5948
            add hl, de		; Hyp.cls 5949
            ld a, (hl)		; Hyp.cls 5950
            cp 1		; Hyp.cls 5951
            jp nz, asm_1_4424_n_pt_one           ; nothing in [5952]
            ld (hl), 2              ; received [5953]
            call asm_1_4424_n_pt_give		; Hyp.cls 5954
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5955
; 33: the server's reply
asm_1_4424_n_pt_reply:		; Hyp.cls 5957
            ld a, (asm_1_4424_n_pt_me)		; Hyp.cls 5958
            cp (hl)		; Hyp.cls 5959
            jp nz, asm_1_4424_n_pt_two		; Hyp.cls 5960
            ld de, 9		; Hyp.cls 5961
            add hl, de		; Hyp.cls 5962
            ld a, (hl)		; Hyp.cls 5963
            cp 2		; Hyp.cls 5964
            jp nz, asm_1_4424_n_pt_two           ; (nothing received to reply to) [5965]
            inc hl		; Hyp.cls 5966
            ld a, (hl)		; Hyp.cls 5967
            dec hl		; Hyp.cls 5968
            or a		; Hyp.cls 5969
            jr nz, asm_1_4424_n_pr_1		; Hyp.cls 5970
            ld (hl), a              ; its caller gone: dropped, the box free [5971]
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5972
asm_1_4424_n_pr_1:		; Hyp.cls 5973
            ld (hl), 3              ; answered [5974]
            inc hl		; Hyp.cls 5975
            inc hl		; Hyp.cls 5976
            ld a, (asm_1_4424_n_sv_blk + 12)		; Hyp.cls 5977
            ld (hl), a		; Hyp.cls 5978
            inc hl		; Hyp.cls 5979
            ex de, hl		; Hyp.cls 5980
            ld c, a		; Hyp.cls 5981
            ld b, 0		; Hyp.cls 5982
            ld a, b		; Hyp.cls 5983
            or c		; Hyp.cls 5984
            jp z, asm_1_4424_n_sv_ok		; Hyp.cls 5985
            ld hl, (asm_1_4424_n_sv_blk + 10)		; Hyp.cls 5986
            call asm_1_4424_n_sv_in		; Hyp.cls 5987
            jp asm_1_4424_n_sv_ok		; Hyp.cls 5988
; 34: port Byte(1) (0-7) - its name to the request's Byte(2-9), its slot to Byte(10) (0: free);
; 255 no such port number (PROBE lists the services with it)
asm_1_4424_n_pt_list:		; Hyp.cls 5991
            ld a, (asm_1_4424_n_sv_blk + 1)		; Hyp.cls 5992
            cp asm_1_4424_n_PT_N		; Hyp.cls 5993
            jp nc, asm_1_4424_n_sv_err		; Hyp.cls 5994
            ld hl, asm_1_4424_n_pt_tab		; Hyp.cls 5995
            ld de, asm_1_4424_n_PT_SZ		; Hyp.cls 5996
            or a		; Hyp.cls 5997
            jr z, asm_1_4424_n_pl_2		; Hyp.cls 5998
            ld b, a		; Hyp.cls 5999
asm_1_4424_n_pl_1:		; Hyp.cls 6000
            add hl, de		; Hyp.cls 6001
            djnz asm_1_4424_n_pl_1		; Hyp.cls 6002
asm_1_4424_n_pl_2:		; Hyp.cls 6003
            ld a, (hl)              ; the slot (0 free) [6004]
            inc hl		; Hyp.cls 6005
            ld de, asm_1_4424_n_sv_rec		; Hyp.cls 6006
            ld bc, 8		; Hyp.cls 6007
            ldir		; Hyp.cls 6008
            ld (de), a		; Hyp.cls 6009
            ld hl, (var_hyp_svc_p)		; Hyp.cls 6010
            ld de, 2		; Hyp.cls 6011
            add hl, de		; Hyp.cls 6012
            ex de, hl		; Hyp.cls 6013
            ld hl, asm_1_4424_n_sv_rec		; Hyp.cls 6014
            ld bc, 9		; Hyp.cls 6015
            call asm_1_4424_n_sv_out		; Hyp.cls 6016
            jp asm_1_4424_n_sv_ok		; Hyp.cls 6017
; pt_give - the port's box (pt_rec) to the slot's Word(10); its length and the caller to the
; request's Byte(12), Byte(13)
asm_1_4424_n_pt_give:		; Hyp.cls 6020
            ld hl, (asm_1_4424_n_pt_rec)		; Hyp.cls 6021
            ld de, 10		; Hyp.cls 6022
            add hl, de		; Hyp.cls 6023
            ld a, (hl)		; Hyp.cls 6024
            ld (asm_1_4424_n_pt_tmp + 1), a      ; the caller [6025]
            inc hl		; Hyp.cls 6026
            ld a, (hl)		; Hyp.cls 6027
            ld (asm_1_4424_n_pt_tmp), a          ; the length [6028]
            inc hl		; Hyp.cls 6029
            ld c, a		; Hyp.cls 6030
            ld b, 0		; Hyp.cls 6031
            or a		; Hyp.cls 6032
            jr z, asm_1_4424_n_pg_0		; Hyp.cls 6033
            ld de, (asm_1_4424_n_sv_blk + 10)		; Hyp.cls 6034
            call asm_1_4424_n_sv_out		; Hyp.cls 6035
asm_1_4424_n_pg_0:		; Hyp.cls 6036
            ld hl, (var_hyp_svc_p)		; Hyp.cls 6037
            ld de, 12		; Hyp.cls 6038
            add hl, de		; Hyp.cls 6039
            ex de, hl		; Hyp.cls 6040
            ld hl, asm_1_4424_n_pt_tmp		; Hyp.cls 6041
            ld bc, 2		; Hyp.cls 6042
            jp asm_1_4424_n_sv_out		; Hyp.cls 6043
; pt_find - Z: HL = the port named sv_blk's Byte(2-9), else NZ; pt_fr: a free record (0 none)
asm_1_4424_n_pt_find:		; Hyp.cls 6045
            ld hl, 0		; Hyp.cls 6046
            ld (asm_1_4424_n_pt_fr), hl		; Hyp.cls 6047
            ld hl, asm_1_4424_n_pt_tab		; Hyp.cls 6048
            ld b, asm_1_4424_n_PT_N		; Hyp.cls 6049
asm_1_4424_n_pf_1:		; Hyp.cls 6050
            ld a, (hl)		; Hyp.cls 6051
            or a		; Hyp.cls 6052
            jr nz, asm_1_4424_n_pf_2		; Hyp.cls 6053
            ld a, (asm_1_4424_n_pt_fr + 1)		; Hyp.cls 6054
            or a		; Hyp.cls 6055
            jr nz, asm_1_4424_n_pf_n		; Hyp.cls 6056
            ld (asm_1_4424_n_pt_fr), hl		; Hyp.cls 6057
            jr asm_1_4424_n_pf_n		; Hyp.cls 6058
asm_1_4424_n_pf_2:		; Hyp.cls 6059
            push hl		; Hyp.cls 6060
            push bc		; Hyp.cls 6061
            inc hl		; Hyp.cls 6062
            ld de, asm_1_4424_n_sv_blk + 2		; Hyp.cls 6063
            ld b, 8		; Hyp.cls 6064
asm_1_4424_n_pf_3:		; Hyp.cls 6065
            ld a, (de)		; Hyp.cls 6066
            cp (hl)		; Hyp.cls 6067
            jr nz, asm_1_4424_n_pf_4		; Hyp.cls 6068
            inc hl		; Hyp.cls 6069
            inc de		; Hyp.cls 6070
            djnz asm_1_4424_n_pf_3		; Hyp.cls 6071
asm_1_4424_n_pf_4:		; Hyp.cls 6072
            pop bc		; Hyp.cls 6073
            pop hl		; Hyp.cls 6074
            ret z		; Hyp.cls 6075
asm_1_4424_n_pf_n:		; Hyp.cls 6076
            ld de, asm_1_4424_n_PT_SZ		; Hyp.cls 6077
            add hl, de		; Hyp.cls 6078
            djnz asm_1_4424_n_pf_1		; Hyp.cls 6079
            or 1		; Hyp.cls 6080
            ret		; Hyp.cls 6081
; pt_free - slot C's ports closed; its calls forgotten (a message not received yet, an answer not
; taken: the box free; one being worked on: its reply dropped). Keeps C
asm_1_4424_n_pt_free:		; Hyp.cls 6084
            ld hl, asm_1_4424_n_pt_tab		; Hyp.cls 6085
            ld b, asm_1_4424_n_PT_N		; Hyp.cls 6086
asm_1_4424_n_pt_fr1:		; Hyp.cls 6087
            ld a, (hl)		; Hyp.cls 6088
            cp c		; Hyp.cls 6089
            jr nz, asm_1_4424_n_pt_fr2		; Hyp.cls 6090
            ld (hl), 0		; Hyp.cls 6091
asm_1_4424_n_pt_fr2:		; Hyp.cls 6092
            push hl		; Hyp.cls 6093
            ld de, 10		; Hyp.cls 6094
            add hl, de		; Hyp.cls 6095
            ld a, (hl)		; Hyp.cls 6096
            cp c		; Hyp.cls 6097
            jr nz, asm_1_4424_n_pt_fr4		; Hyp.cls 6098
            ld (hl), 0              ; no caller [6099]
            dec hl		; Hyp.cls 6100
            ld a, (hl)		; Hyp.cls 6101
            cp 2		; Hyp.cls 6102
            jr z, asm_1_4424_n_pt_fr4            ; (being worked on: its reply dropped then) [6103]
            ld (hl), 0		; Hyp.cls 6104
asm_1_4424_n_pt_fr4:		; Hyp.cls 6105
            pop hl		; Hyp.cls 6106
            ld de, asm_1_4424_n_PT_SZ		; Hyp.cls 6107
            add hl, de		; Hyp.cls 6108
            djnz asm_1_4424_n_pt_fr1		; Hyp.cls 6109
            ret		; Hyp.cls 6110
asm_1_4424_n_pt_op:      db 0		; Hyp.cls 6111
asm_1_4424_n_pt_has:     db 0		; Hyp.cls 6112
asm_1_4424_n_pt_me:      db 0		; Hyp.cls 6113
asm_1_4424_n_pt_rec:     dw 0		; Hyp.cls 6114
asm_1_4424_n_pt_fr:      dw 0		; Hyp.cls 6115
asm_1_4424_n_pt_tmp:     dw 0		; Hyp.cls 6116
asm_1_4424_n_nt_rom:     db 255		; Hyp.cls 6117
asm_1_4424_n_nt_old:     dw 0		; Hyp.cls 6118
asm_1_4424_n_nt_rsp:     dw 0		; Hyp.cls 6119
asm_1_4424_n_nt_skt:     dw 0		; Hyp.cls 6120
asm_1_4424_n_nt_own:     ds asm_1_4424_n_NT_N		; Hyp.cls 6121
asm_1_4424_n_sv_sp:      dw 0		; Hyp.cls 6122
asm_1_4424_n_sv_n:       dw 0		; Hyp.cls 6123
asm_1_4424_n_sv_c:       dw 0		; Hyp.cls 6124
asm_1_4424_n_sv_sk:      db 0		; Hyp.cls 6125
asm_1_4424_n_sv_ss:      dw 0		; Hyp.cls 6126
asm_1_4424_n_sv_sa:      dw 0		; Hyp.cls 6127
asm_1_4424_n_sv_dk:      db 0		; Hyp.cls 6128
asm_1_4424_n_sv_ds:      dw 0		; Hyp.cls 6129
asm_1_4424_n_sv_da:      dw 0		; Hyp.cls 6130
asm_1_4424_n_sv_stop:    db 0		; Hyp.cls 6131
asm_1_4424_n_sv_tj:      db 0		; Hyp.cls 6132
asm_1_4424_n_sv_tn:      db 0		; Hyp.cls 6133
asm_1_4424_n_sv_tsg:     dw 0		; Hyp.cls 6134
asm_1_4424_n_sv_blk:     ds 16		; Hyp.cls 6135
asm_1_4424_n_sv_tmp:     ds 16		; Hyp.cls 6136
asm_1_4424_n_sv_rec:     ds 128		; Hyp.cls 6137
asm_1_4424_n_sv_cl:      ds asm_1_4424_n_CL_N * 10            ; the claims (16-19; table 4) [6138]
asm_1_4424_n_nt_pk:      ds 256                  ; a packet to the M4 (21-27) [6139]
asm_1_4424_n_pt_tab:     ds asm_1_4424_n_PT_N * asm_1_4424_n_PT_SZ         ; the ports (28-33) [6140]
asm_1_4424_n_sv_end:		; Hyp.cls 6141
            ASSERT asm_1_4424_n_sv_end <= #8000, "the service page's code"		; Hyp.cls 6142
			ENDM
; ============================================================
; NTC program - generated by NTC BASIC (VB style BASIC to NTC)
; platform: zxn (ZX Spectrum Next - direct hardware (native)), starts in normal mode
; ============================================================

			DEVICE ZXSPECTRUMNEXT		; for SAVENEX at the end
			MMU 0 5, 16			; #0000-#BFFF: pages 16-21 (banks 8, 9, 10)
			org #0040

NTC_TERM	equ 0		; Option Terminal: 0 none, 1 VT52, 2 ANSI (CP/M)
NTC_STRMAX	equ 82		; the longest string (library buffers, temps)
NTC_MEMBANKS	equ 64		; Option Memory: the most 64K banks the Memory class looks for
NTC_ROMENABLE	equ 0		; Option RomEnable (cpcfw, cpcmin): the start code starts the ROMs
NTC_ROMLIB	equ 0		; 1 = the library is the keyword ROM (Library: ROM; ntcRomAsm builds it)
NTC_WINHOLE	equ 1		; 1 = the program is built round an Option Reserve range over the window #4000-#7FFF
NTC_BUFSIZE	equ 128		; the library's buffer (ntc_buf: FileSystem, Memory.Copy): Option Buffer
; the ZX Spectrum Next: NTC_ZXN defined (a DEFINE - sjasmplus's IFDEF tests those, not labels)
			DEFINE NTC_ZXN
ZXN_FIRSTBANK	equ 22		; first free 16K bank (page 44), above the program/screen/low banks
ZXN_MAXBANK	equ 106		; scan range up to bank 127 (2MB)
NTC_CPMGFX	equ 0		; 1 = CP/M: Graphics draws on an Amstrad CPC's screen (2.2: #C000, Plus: block 1 from common memory)

ntc_start:
			jr ntc_start2		; #0040 (2 bytes): over the glue
ntc_bk_sp:		dw 0			; #0042: this bank's SP while another runs
ntc_bk_out:
			db #08			; #0044: ex af, af - stash A + FLAGS (carry = far-call / interrupt) to the alternate set, before the port flip clobbers A
			ld bc, #243B		; PIVOT via the MMU ports (no Z80N opcode): select MMU slot 0 (#50)
			ld a, #50
			out (c), a
			inc b			; #253B
			ld a, 16		; the hypervisor's slot-0 page; slot 0 flips HERE - next byte is the receiver
			out (c), a
ntc_bk_recv:			; now running in the hypervisor's slot 0 (A + FLAGS already in the alternate set)
			ld (ntc_bk_svd), de	; DE / HL message to slot-0 scratch (slot 0 stays the hypervisor here)
			ld (ntc_bk_svh), hl
			ld hl, ntc_bk_hpg	; the hypervisor's resting pages, slots 1-7
			ld bc, #243B		; NextReg select port (#253B = value)
			ld d, #51		; slot register 1
ntc_bk_rc1:
			ld a, d
			out (c), a		; select the slot register
			inc b			; #253B
			ld a, (hl)
			out (c), a		; = its resting page
			dec b			; #243B
			inc hl
			inc d
			ld a, d
			cp #58			; slots #51..#57 (1..7) done? (clobbers flags - carry safe in AF\')
			jr nz, ntc_bk_rc1
			ld de, (ntc_bk_svd)
			ld hl, (ntc_bk_svh)
			db #08			; ex af, af - A + FLAGS back (IX untouched throughout = also preserved)
ntc_bk_land:
			ld sp, (ntc_bk_sp)	; the hypervisor's own SP
			ret				; to where it handed over (Run's rn_back), A/DE/IX + carry intact
			ASSERT ntc_bk_out == #0044, "the bank switch must be at #0044"
ntc_bk_svd:		dw 0		; DE / HL message held across the slot 1-7 remap
ntc_bk_svh:		dw 0
ntc_bk_hpg:		db 17, 18, 19, 20, 21, 10, 11	; hypervisor resting pages, slots 1-7 (boot MMU map)
ntc_start2:
ntc_bk_cold:
			di
			ld sp, #C000		; the platform's own real stack
			ld (ntc_csp), sp
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
			dw kw_scrinit		; mode 1, ROMs off, clear screen
			dw kw_bssinit, ntc_bss, ntc_bss_size		; the arrays: do they fit, clear them

			; Main.bas 85: Mode 2
			dw kw_model, 2

			; Main.bas 86: #asm
			dw asm_0_86_n

			; Main.bas 91: Hyp.Vdu 0                         ' the firmware's text off (TXT VDU DISABLE): AMSDOS says "NAME.CYB not
			dw p_hyp_vdu_c, lit_0

			; Main.bas 95: k = Memory.Banks()
			dw fn_memory_banks, var_k

			; Main.bas 96: If k < 4 Then Hyp.Vdu 1 : Print "CyborgOS needs 320K (a 256K expansion) or more" : End
			dw kw_scpltvl, var_k, 4
			dw kw_goto_iffalse_n, if1_1
			dw p_hyp_vdu_c, lit_1
			dw kw_printzoscii
			dw glyph_43, glyph_79, glyph_62, glyph_6F, glyph_72, glyph_67, glyph_4F, glyph_53
			dw glyph_20, glyph_6E, glyph_65, glyph_65, glyph_64, glyph_73, glyph_20, glyph_33
			dw glyph_32, glyph_30, glyph_4B, glyph_20, glyph_28, glyph_61, glyph_20, glyph_32
			dw glyph_35, glyph_36, glyph_4B, glyph_20, glyph_65, glyph_78, glyph_70, glyph_61
			dw glyph_6E, glyph_73, glyph_69, glyph_6F, glyph_6E, glyph_29, glyph_20, glyph_6F
			dw glyph_72, glyph_20, glyph_6D, glyph_6F, glyph_72, glyph_65, 1, 0		; "CyborgOS needs 320K (a 256K expansion) or more\n"
			dw kw_printnl0
			dw kw_printzoscii
			dw glyph_50, glyph_72, glyph_65, glyph_73, glyph_73, glyph_20, glyph_61, glyph_20
			dw glyph_6B, glyph_65, glyph_79, 0		; "Press a key"
			dw kw_waitkey
			dw kw_stop
if1_1:

			; Main.bas 97: ns = k \ 2                                      ' half the banks are slots (the first bank never:
			dw kw_divvl, var_k, 2, var_ns

			; Main.bas 98: If ns > MAXS Then ns = MAXS                     ' its pages are the hypervisor's)
			dw kw_scpgtvl, var_ns, 20
			dw kw_goto_iffalse_n, if2_1
			dw kw_ltov, 20, var_ns
if2_1:

			; Main.bas 99: Hot.Slots ns                                    ' (more than 10: Control + a number twice is 11-20)
			dw p_hot_slots_c, var_ns

			; Main.bas 103: i = Memory.AllocPage(Memory.TypeUser)           ' (page 1)
			dw fn_memory_allocpage, lit_85, var_i

			; Main.bas 104: hp = Memory.AllocPage(Memory.TypeUser)          ' bank 1's page 0 (C4): the disc buffers ...
			dw fn_memory_allocpage, lit_85, var_hp

			; Main.bas 105: Memory.SelectPage hp
			dw fn_memory_selectpage, var_hp, var_memory_selectpage_selectpage

			; Main.bas 106: Hyp.UsePage                                     ' (its RAM setting, for Hyp.FileCall)
			dw fn_hyp_usepage

			; Main.bas 107: Hyp.FontInit                                    ' (the font into it, at #5000)
			dw fn_hyp_fontinit

			; Main.bas 110: i = Memory.AllocPage(Memory.TypeUser)           ' bank 1's page 1 (C5): the services (Hyp.Svc: BDOS
			dw fn_memory_allocpage, lit_85, var_i

			; Main.bas 111: Memory.SelectPage i                             ' 131 ops 10-15), out of main RAM
			dw fn_memory_selectpage, var_i, var_memory_selectpage_selectpage

			; Main.bas 112: Hyp.UseSvc
			dw fn_hyp_usesvc

			; Main.bas 113: Hyp.SvcVars VarPtr(st), VarPtr(sg), VarPtr(ns), VarPtr(front), VarPtr(dp)
			dw p_hyp_svcvars_c, vp_arr_st, vp_arr_sg, vp_var_ns, vp_var_front, vp_var_dp

			; Main.bas 115: i = Hyp.FileCall(99, 0, 0, 0, 0, 0, VarPtr(rb))  ' (the bank image and FileCall's page code into it,
			dw p_hyp_filecall_c, lit_99, lit_0, lit_0, lit_0, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_i

			; Main.bas 120: i = Hyp.Svc(0, 0, 0, VarPtr(rb))                ' (the services' code into the service page: #6000 on)
			dw p_hyp_svc_c, lit_0, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_i

			; Main.bas 122: For i = 1 To ns
			dw kw_ltov, 1, var_i
			dw kw_vtov, var_ns, for3_l
			dw kw_forupv_n, var_i, for3_l, for3_e
for3_t:

			; Main.bas 123: bk(i) = Memory.AllocBank()
			dw fn_memory_allocbank, var_memory_allocbank_allocbank
			dw kw_aset, arr_bk, var_i, var_memory_allocbank_allocbank

			; Main.bas 124: Memory.SelectPage Memory.BankPage(bk(i), 0)
			dw kw_aget, arr_bk, var_i, tmp0
			dw p_memory_bankpage_c, tmp0, lit_0
			dw kw_vtov, var_memory_bankpage_bankpage, tmp0
			dw fn_memory_selectpage, tmp0, var_memory_selectpage_selectpage

			; Main.bas 125: sg(i) = Hyp.Setting()
			dw fn_hyp_setting, var_hyp_setting_setting
			dw kw_aset, arr_sg, var_i, var_hyp_setting_setting

			; Main.bas 127: wp(i) = sg(i)                                  ' zxn: the bank index; the MMU window-map decodes it to page 3
			dw kw_aget, arr_sg, var_i, tmp1
			dw kw_aset, arr_wp, var_i, tmp1

			; Main.bas 132: wk(i) = -1
			dw kw_asetl, arr_wk, var_i, -1

			; Main.bas 138: Next
			dw kw_next1v_n, var_i, for3_l, for3_t
for3_e:

			; Main.bas 141: ob = Space$(82)
			dw kw_strspace, var_ob, lit_82

			; Main.bas 142: front = 1
			dw kw_ltov, 1, var_front

			; Main.bas 143: OpenSlot 1
			dw p_openslot_c, lit_1

			; Main.bas 146: a = ""
			dw kw_strcpy, var_a, str0

			; Main.bas 147: If Peek(&HBE80) = 67 And Peek(&HBE81) = 89 And Peek(&HBE82) = 66 And Peek(&HBE83) = 32 Then
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
			dw kw_goto_ifzero_n, tmp0, if4_1

			; Main.bas 148: i = &HBE84
			dw kw_ltov, -16764, var_i

			; Main.bas 149: Do While Peek(i) <> 0 And i < &HBEC0
do5_t:
			dw kw_vptrtov8, var_i, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_ftov, tmp0
			dw kw_scpltvl, var_i, -16704
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do5_e

			; Main.bas 150: a = a + Chr$(Peek(i))
			dw kw_vptrtov8, var_i, tmp1
			dw kw_strchr, stmp1, tmp1
			dw kw_strcat, var_a, stmp1

			; Main.bas 151: i = i + 1
			dw kw_inc, var_i

			; Main.bas 152: Loop
			dw do5_t_go
do5_e:

			; Main.bas 153: a = UCase$(a)
			dw kw_strucase, stmp0, var_a
			dw kw_strcpy, var_a, stmp0

			; Main.bas 154: End If
if4_1:

			; Main.bas 155: i = InStr(a, " KEYREP ")
			dw kw_strinstr, lit_1, var_a, str1, var_i

			; Main.bas 156: If i > 0 Then
			dw kw_scpgtvl, var_i, 0
			dw kw_goto_iffalse_n, if6_1

			; Main.bas 157: k = Val(Mid$(a, i + 8))
			dw kw_addl, var_i, 8, tmp1
			dw kw_strmid, stmp0, var_a, tmp1, lit_255
			dw kw_strval, stmp0, var_k

			; Main.bas 158: If k > 1 Then Hyp.KeyRep k : Hot.Speed k             ' (the double tap's time too: real time, not ticks)
			dw kw_scpgtvl, var_k, 1
			dw kw_goto_iffalse_n, if7_1
			dw p_hyp_keyrep_c, var_k
			dw p_hot_speed_c, var_k
if7_1:

			; Main.bas 159: End If
if6_1:

			; Main.bas 162: bd = 65                                         ' the boot drive: "CYB d" (A without it)
			dw kw_ltov, 65, var_bd

			; Main.bas 163: If a <> "" Then bd = Asc(a)
			dw kw_strcmpne, var_a, str0
			dw kw_goto_iffalse_n, if8_1
			dw kw_strasc, var_a, var_bd
if8_1:

			; Main.bas 187: Do
do9_t:

			; Main.bas 188: hk = Hot.Take()
			dw p_hot_take_c
			dw kw_vtov, var_hot_take_take, var_hk

			; Main.bas 189: If hk = Hot.TOPKEY Then
			dw kw_cpeqvl, var_hk, 99
			dw kw_goto_iffalse_n, if10_1

			; Main.bas 190: If front = 0 Then ToFront back Else ShowTop      ' Control + ESC: TOP, and again: back
			dw kw_cpeqvl, var_front, 0
			dw kw_goto_iffalse_n, if11_1
			dw p_tofront_c, var_back
			dw if10_e_go
if11_1:
			dw p_showtop_c
if11_e:

			; Main.bas 191: ElseIf hk > 0 And hk <= ns Then
			dw if10_e_go
if10_1:
			dw kw_scpgtvl, var_hk, 0
			dw kw_ftov, tmp0
			dw kw_scplevv, var_hk, var_ns
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if10_2

			; Main.bas 192: ToFront hk
			dw p_tofront_c, var_hk

			; Main.bas 193: End If
if10_2:
if10_e:

			; Main.bas 194: If pk <> 0 And wt = 0 Then                    ' (a key left by a program: after WAIT's prompt)
			dw kw_cpnevl, var_pk, 0
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_wt, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if12_1

			; Main.bas 195: k = pk : pk = 0
			dw kw_vtov, var_pk, var_k
			dw kw_ztov, var_pk

			; Main.bas 196: KeyIn k
			dw p_keyin_c, var_k

			; Main.bas 197: ElseIf wt = 0 Then
			dw if12_e_go
if12_1:
			dw kw_cpeqvl, var_wt, 0
			dw kw_goto_iffalse_n, if12_2

			; Main.bas 199: If front = 0 Or st(front) <> 2 Or kq(front) = 0 Then
			dw kw_cpeqvl, var_front, 0
			dw kw_ftov, tmp0
			dw kw_aget, arr_st, var_front, tmp1
			dw kw_cpnevl, tmp1, 2
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_aget, arr_kq, var_front, tmp1
			dw kw_cpeqvl, tmp1, 0
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if12_e

			; Main.bas 200: k = Inkey
			dw kw_inkey, tmp0
			dw kw_vtov, tmp0, var_k

			; Main.bas 201: If k <> 0 And (Hot.Control() = 0 Or (k < 32 And Hot.Held() = 0)) Then KeyIn k   ' (Control + a letter: the program's)
			dw kw_cpnevl, var_k, 0
			dw kw_ftov, tmp0
			dw p_hot_control_c
			dw kw_vtov, var_hot_control_control, tmp1
			dw kw_cpeqvl, tmp1, 0
			dw kw_ftov, tmp1
			dw kw_scpltvl, var_k, 32
			dw kw_ftov, tmp2
			dw p_hot_held_c
			dw kw_vtov, var_hot_held_held, tmp3
			dw kw_cpeqvl, tmp3, 0
			dw kw_ftov, tmp3
			dw kw_andvv, tmp2, tmp3, tmp2
			dw kw_orvv, tmp1, tmp2, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if12_e
			dw p_keyin_c, var_k
if14_1:

			; Main.bas 202: End If
if13_1:

			; Main.bas 203: ElseIf Running() = 0 Then
			dw if12_e_go
if12_2:
			dw p_running_c
			dw kw_vtov, var_running_running, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if12_3

			; Main.bas 204: Prompt wt : wt = 0          ' WAIT: nothing runs any more
			dw p_prompt_c, var_wt
			dw kw_ztov, var_wt

			; Main.bas 205: End If
if12_3:
if12_e:

			; Main.bas 206: If Ticks - td >= 300 Then Roll
			dw kw_ticks, tmp0
			dw kw_subvv, tmp0, var_td, tmp0
			dw kw_scpgevl, tmp0, 300
			dw kw_goto_iffalse_n, if15_1
			dw p_roll_c
if15_1:

			; Main.bas 207: If front <> 0 Then
			dw kw_cpnevl, var_front, 0
			dw kw_goto_iffalse_n, if16_1

			; Main.bas 208: If Ticks - tc >= 150 Then tc = Ticks : Hyp.Con wp(front), 0, -3, 1   ' the cursor flashes (0.5 s)
			dw kw_ticks, tmp0
			dw kw_subvv, tmp0, var_tc, tmp0
			dw kw_scpgevl, tmp0, 150
			dw kw_goto_iffalse_n, if17_1
			dw kw_ticks, tmp0
			dw kw_vtov, tmp0, var_tc
			dw kw_aget, arr_wp, var_front, tmp0
			dw p_hyp_con_c, tmp0, lit_0, lit_m3, lit_1
if17_1:

			; Main.bas 209: End If
if16_1:

			; Main.bas 210: RunNext
			dw p_runnext_c

			; Main.bas 211: Loop Until quit
			dw kw_goto_ifzero_n, var_quit, do9_t
do9_e:

			; Main.bas 212: i = Hyp.Scr(0, 2)                 ' the CRTC as the firmware has it (80 x 25)
			dw p_hyp_scr_c, lit_0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_i

			; Main.bas 213: Hyp.Vdu 1
			dw p_hyp_vdu_c, lit_1

			; Main.bas 214: Mode 1
			dw kw_model, 1

			; Main.bas 215: Print "CyborgOS ended, "; runs; " programs ran"
			dw kw_printzoscii
			dw glyph_43, glyph_79, glyph_62, glyph_6F, glyph_72, glyph_67, glyph_4F, glyph_53
			dw glyph_20, glyph_65, glyph_6E, glyph_64, glyph_65, glyph_64, glyph_2C, glyph_20
			dw 0		; "CyborgOS ended, "
			dw kw_printint, var_runs
			dw kw_printzoscii
			dw glyph_20, glyph_70, glyph_72, glyph_6F, glyph_67, glyph_72, glyph_61, glyph_6D
			dw glyph_73, glyph_20, glyph_72, glyph_61, glyph_6E, 1, 0		; " programs ran\n"

			; Main.bas 216: End
			dw kw_printnl0
			dw kw_printzoscii
			dw glyph_50, glyph_72, glyph_65, glyph_73, glyph_73, glyph_20, glyph_61, glyph_20
			dw glyph_6B, glyph_65, glyph_79, 0		; "Press a key"
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
; function running (normal mode)
; ============================================================

p_running:

			; Main.bas 230: Dim j As Integer

			; Main.bas 231: For j = 1 To ns
			dw kw_ltov, 1, var_running_j
			dw kw_vtov, var_ns, for20_l
			dw kw_forupv_n, var_running_j, for20_l, for20_e
for20_t:

			; Main.bas 232: If st(j) = 2 Then Running = Running + 1
			dw kw_aget, arr_st, var_running_j, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if21_1
			dw kw_inc, var_running_running
if21_1:

			; Main.bas 233: Next
			dw kw_next1v_n, var_running_j, for20_l, for20_t
for20_e:
			dw p_running_r

ntc_rg2_e:
			IF ($ < 32768) && (ntc_rg3_e - ntc_rg3 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg3:
; ============================================================
; function ready (normal mode)
; ============================================================

p_ready:

			; Main.bas 239: Ready = 0
			dw kw_ztov, var_ready_ready

			; Main.bas 240: If t < 1 Then Exit Function
			dw kw_scpltvl, var_ready_t, 1
			dw kw_goto_iffalse_n, if22_1
			dw p_ready_r
if22_1:

			; Main.bas 241: If st(t) <> 2 Then Exit Function
			dw kw_aget, arr_st, var_ready_t, tmp0
			dw kw_cpnevl, tmp0, 2
			dw kw_goto_iffalse_n, if23_1
			dw p_ready_r
if23_1:

			; Main.bas 242: If wk(t) = Ticks And kq(t) = 0 Then Exit Function
			dw kw_aget, arr_wk, var_ready_t, tmp0
			dw kw_ticks, tmp1
			dw kw_cpeqvv, tmp0, tmp1
			dw kw_ftov, tmp0
			dw kw_aget, arr_kq, var_ready_t, tmp1
			dw kw_cpeqvl, tmp1, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if24_1
			dw p_ready_r
if24_1:

			; Main.bas 243: Ready = -1
			dw kw_ltov, -1, var_ready_ready
			dw p_ready_r

ntc_rg3_e:
			IF ($ < 32768) && (ntc_rg4_e - ntc_rg4 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg4:
; ============================================================
; sub runnext (normal mode)
; ============================================================

p_runnext:

			; Main.bas 248: Dim n As Integer, t As Integer, r As Integer, c As Integer, q As Integer

			; Main.bas 249: fr = Not fr
			dw kw_notv, var_fr, var_fr

			; Main.bas 250: If fr Then
			dw kw_goto_ifzero_n, var_fr, if25_1

			; Main.bas 251: If Ready(front) Then t = front
			dw p_ready_c, var_front
			dw kw_goto_ifzero_n, var_ready_ready, if26_1
			dw kw_vtov, var_front, var_runnext_t
if26_1:

			; Main.bas 252: End If
if25_1:

			; Main.bas 253: If t = 0 Then
			dw kw_cpeqvl, var_runnext_t, 0
			dw kw_goto_iffalse_n, if27_1

			; Main.bas 254: For n = 1 To ns
			dw kw_ltov, 1, var_runnext_n
			dw kw_vtov, var_ns, for28_l
			dw kw_forupv_n, var_runnext_n, for28_l, for28_e
for28_t:

			; Main.bas 255: cur = cur + 1
			dw kw_inc, var_cur

			; Main.bas 256: If cur > ns Then cur = 1
			dw kw_scpgtvv, var_cur, var_ns
			dw kw_goto_iffalse_n, if29_1
			dw kw_ltov, 1, var_cur
if29_1:

			; Main.bas 257: If cur <> front Then
			dw kw_cpnevv, var_cur, var_front
			dw kw_goto_iffalse_n, if30_1

			; Main.bas 258: If Ready(cur) Then t = cur : Exit For
			dw p_ready_c, var_cur
			dw kw_goto_ifzero_n, var_ready_ready, if31_1
			dw kw_vtov, var_cur, var_runnext_t
			dw for28_e_go
if31_1:

			; Main.bas 259: End If
if30_1:

			; Main.bas 260: Next
			dw kw_next1v_n, var_runnext_n, for28_l, for28_t
for28_e:

			; Main.bas 261: End If
if27_1:

			; Main.bas 262: If t = 0 Then
			dw kw_cpeqvl, var_runnext_t, 0
			dw kw_goto_iffalse_n, if32_1

			; Main.bas 263: If Ready(front) Then t = front
			dw p_ready_c, var_front
			dw kw_goto_ifzero_n, var_ready_ready, if33_1
			dw kw_vtov, var_front, var_runnext_t
if33_1:

			; Main.bas 264: End If
if32_1:

			; Main.bas 265: If t = 0 Then
			dw kw_cpeqvl, var_runnext_t, 0
			dw kw_goto_iffalse_n, if34_1

			; Main.bas 266: If Running() = 0 Then Frame     ' nothing to run: wait a frame (a program waiting for a
			dw p_running_c
			dw kw_vtov, var_running_running, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if35_1
			dw kw_frame
if35_1:

			; Main.bas 267: Exit Sub                        ' key looks again when the clock moves on)
			dw p_runnext_r

			; Main.bas 268: End If
if34_1:

			; Main.bas 269: n = 0
			dw kw_ztov, var_runnext_n

			; Main.bas 270: Do
do36_t:

			; Main.bas 271: Hyp.Reply ra(t), ra(t)
			dw kw_aget, arr_ra, var_runnext_t, tmp0
			dw kw_aget, arr_ra, var_runnext_t, tmp1
			dw p_hyp_reply_c, tmp0, tmp1

			; Main.bas 272: r = Hyp.Run(sg(t))
			dw kw_aget, arr_sg, var_runnext_t, tmp0
			dw p_hyp_run_c, tmp0
			dw kw_vtov, var_hyp_run_run, var_runnext_r

			; Main.bas 273: tn(t) = tn(t) + 1
			dw kw_aget, arr_tn, var_runnext_t, tmp1
			dw kw_inc, tmp1
			dw kw_aset, arr_tn, var_runnext_t, tmp1

			; Main.bas 274: If kq(t) <> 0 Then
			dw kw_aget, arr_kq, var_runnext_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, if37_1

			; Main.bas 275: If Memory.ReadByte(Far(t, Hyp.KEY)) = 0 Then kq(t) = 0     ' the program took its key
			dw p_far_c, var_runnext_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_memory_readbyte_readbyte
			dw kw_vtov, var_memory_readbyte_readbyte, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if38_1
			dw kw_asetl, arr_kq, var_runnext_t, 0
if38_1:

			; Main.bas 276: End If
if37_1:

			; Main.bas 277: c = Hyp.Count()
			dw p_hyp_count_c
			dw kw_vtov, var_hyp_count_count, var_runnext_c

			; Main.bas 278: If c > 0 Then Collected t, c
			dw kw_scpgtvl, var_runnext_c, 0
			dw kw_goto_iffalse_n, if39_1
			dw p_collected_c, var_runnext_t, var_runnext_c
if39_1:

			; Main.bas 279: If r = 0 Then
			dw kw_cpeqvl, var_runnext_r, 0
			dw kw_goto_iffalse_n, if40_1

			; Main.bas 283: q = q + 1
			dw kw_inc, var_runnext_q

			; Main.bas 284: If q >= TURNS Then Exit Do
			dw kw_scpgevl, var_runnext_q, 3
			dw kw_goto_iffalse_n, do36_t
			dw do36_e_go
if41_1:

			; Main.bas 285: ElseIf r <> 1 Then
			dw do36_t_go
if40_1:
			dw kw_cpnevl, var_runnext_r, 1
			dw kw_goto_iffalse_n, if40_2

			; Main.bas 286: Exit Do
			dw do36_e_go

			; Main.bas 287: Else
if40_2:

			; Main.bas 288: c = Hyp.Fn()
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_runnext_c

			; Main.bas 289: Bdos t
			dw p_bdos_c, var_runnext_t

			; Main.bas 294: n = n + 1
			dw kw_inc, var_runnext_n

			; Main.bas 295: If c = 131 Or c = 128 Then c = 13
			dw kw_cpeqvl, var_runnext_c, 131
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_runnext_c, 128
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if42_1
			dw kw_ltov, 13, var_runnext_c
if42_1:

			; Main.bas 296: If c < 13 Or c > 36 Or n >= 32 Or st(t) <> 2 Or wk(t) <> -1 Then Exit Do   ' (asleep: a port's wait)
			dw kw_scpltvl, var_runnext_c, 13
			dw kw_ftov, tmp0
			dw kw_scpgtvl, var_runnext_c, 36
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_scpgevl, var_runnext_n, 32
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_aget, arr_st, var_runnext_t, tmp1
			dw kw_cpnevl, tmp1, 2
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_aget, arr_wk, var_runnext_t, tmp1
			dw kw_cpnevl, tmp1, -1
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do36_t
			dw do36_e_go
if43_1:

			; Main.bas 297: End If
if40_e:

			; Main.bas 298: Loop
			dw do36_t_go
do36_e:
			dw p_runnext_r

ntc_rg4_e:
			IF ($ < 32768) && (ntc_rg5_e - ntc_rg5 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg5:
; ============================================================
; sub bdos (normal mode)
; ============================================================

p_bdos:

			; Main.bas 303: Dim f As Integer, e As Integer, a As Integer

			; Main.bas 304: f = Hyp.Fn() : e = Hyp.Arg() And 255 : a = 0
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_bdos_f
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, tmp0
			dw kw_andvl, tmp0, 255, var_bdos_e
			dw kw_ztov, var_bdos_a

			; Main.bas 305: nb(t) = nb(t) + 1
			dw kw_aget, arr_nb, var_bdos_t, tmp1
			dw kw_inc, tmp1
			dw kw_aset, arr_nb, var_bdos_t, tmp1

			; Main.bas 306: wk(t) = -1
			dw kw_asetl, arr_wk, var_bdos_t, -1

			; Main.bas 307: If f = 40 Then f = 34           ' write random with zero fill: as 34
			dw kw_cpeqvl, var_bdos_f, 40
			dw kw_goto_iffalse_n, if44_1
			dw kw_ltov, 34, var_bdos_f
if44_1:

			; Main.bas 308: Select Case f
			dw kw_vtov, var_bdos_f, var_bdos___sel45

			; Main.bas 309: Case 0
			dw kw_cpeqvl, var_bdos___sel45, 0
			dw kw_goto_iffalse_n, sel45_1
sel45_b1:

			; Main.bas 310: EndTask t
			dw p_endtask_c, var_bdos_t

			; Main.bas 311: Exit Sub
			dw p_bdos_r

			; Main.bas 332: Case 12
sel45_1:
			dw kw_cpeqvl, var_bdos___sel45, 12
			dw kw_goto_iffalse_n, sel45_2
sel45_b2:

			; Main.bas 333: a = &H22                    ' CP/M 2.2
			dw kw_ltov, 34, var_bdos_a

			; Main.bas 334: Case 13, 32                   ' reset the discs; user number: nothing to do here
			dw sel45_e_go
sel45_2:
			dw kw_cpeqvl, var_bdos___sel45, 13
			dw kw_goto_iftrue_n, sel45_b3
			dw kw_cpeqvl, var_bdos___sel45, 32
			dw kw_goto_iffalse_n, sel45_3
sel45_b3:

			; Main.bas 335: a = 0
			dw kw_ztov, var_bdos_a

			; Main.bas 336: Case 14                       ' select a disc: the slot's drive (as CD)
			dw sel45_e_go
sel45_3:
			dw kw_cpeqvl, var_bdos___sel45, 14
			dw kw_goto_iffalse_n, sel45_4
sel45_b4:

			; Main.bas 339: dv(t) = 65 + e
			dw kw_addl, var_bdos_e, 65, tmp1
			dw kw_aset, arr_dv, var_bdos_t, tmp1

			; Main.bas 341: Case 25
			dw sel45_e_go
sel45_4:
			dw kw_cpeqvl, var_bdos___sel45, 25
			dw kw_goto_iffalse_n, sel45_5
sel45_b5:

			; Main.bas 345: If dv(t) = 0 Then a = 0 Else a = dv(t) - 65
			dw kw_aget, arr_dv, var_bdos_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if46_1
			dw kw_ztov, var_bdos_a
			dw sel45_e_go
if46_1:
			dw kw_aget, arr_dv, var_bdos_t, tmp0
			dw kw_addl, tmp0, -65, var_bdos_a
if46_e:

			; Main.bas 347: Case 26                       ' the DMA address (CP/M's record buffer)
			dw sel45_e_go
sel45_5:
			dw kw_cpeqvl, var_bdos___sel45, 26
			dw kw_goto_iffalse_n, sel45_6
sel45_b6:

			; Main.bas 348: dm(t) = Hyp.Arg()
			dw p_hyp_arg_c
			dw kw_aset, arr_dm, var_bdos_t, var_hyp_arg_arg

			; Main.bas 349: Case 24                       ' the login vector: the slot's drive
			dw sel45_e_go
sel45_6:
			dw kw_cpeqvl, var_bdos___sel45, 24
			dw kw_goto_iffalse_n, sel45_7
sel45_b7:

			; Main.bas 353: a = 1                       ' (a bit a drive: A 1, B 2, C 4 - A to H: the low byte)
			dw kw_ltov, 1, var_bdos_a

			; Main.bas 354: If dv(t) <> 0 Then
			dw kw_aget, arr_dv, var_bdos_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, sel45_e

			; Main.bas 355: For e = 1 To (dv(t) - 65) And 7
			dw kw_ltov, 1, var_bdos_e
			dw kw_aget, arr_dv, var_bdos_t, tmp0
			dw kw_addl, tmp0, -65, tmp0
			dw kw_andvl, tmp0, 7, for48_l
			dw kw_forupv_n, var_bdos_e, for48_l, sel45_e
for48_t:

			; Main.bas 356: a = a * 2
			dw kw_2x, var_bdos_a, var_bdos_a

			; Main.bas 357: Next
			dw kw_next1v_n, var_bdos_e, for48_l, for48_t
for48_e:

			; Main.bas 358: End If
if47_1:

			; Main.bas 360: Case 15 To 36                 ' files: Hyp.FileCall
			dw sel45_e_go
sel45_7:
			dw kw_scpltvl, var_bdos___sel45, 15
			dw kw_goto_iftrue_n, sel45_8
			dw kw_scplevl, var_bdos___sel45, 36
			dw kw_goto_iffalse_n, sel45_8
sel45_b8:

			; Main.bas 364: a = Hyp.FileCall(f, Hyp.Arg(), t, sg(t), dm(t), dv(t), VarPtr(rb))
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, tmp1
			dw kw_aget, arr_sg, var_bdos_t, tmp3
			dw kw_aget, arr_dm, var_bdos_t, tmp4
			dw kw_aget, arr_dv, var_bdos_t, tmp5
			dw p_hyp_filecall_c, var_bdos_f, tmp1, var_bdos_t, tmp3, tmp4, tmp5, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_bdos_a

			; Main.bas 368: Case 130                      ' RAMDISC.CYB: the RAM discs' driver
			dw sel45_e_go
sel45_8:
			dw kw_cpeqvl, var_bdos___sel45, 130
			dw kw_goto_iffalse_n, sel45_9
sel45_b9:

			; Main.bas 369: a = RamDisc(t, Hyp.Arg())
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, tmp1
			dw p_ramdisc_c, var_bdos_t, tmp1
			dw kw_vtov, var_ramdisc_ramdisc, var_bdos_a

			; Main.bas 371: Case 131                      ' CyborgOS's own commands (PS, KILL, MEM ...)
			dw sel45_e_go
sel45_9:
			dw kw_cpeqvl, var_bdos___sel45, 131
			dw kw_goto_iffalse_n, sel45_10
sel45_b10:

			; Main.bas 372: a = Sys(t, Hyp.Arg())
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, tmp1
			dw p_sys_c, var_bdos_t, tmp1
			dw kw_vtov, var_sys_sys, var_bdos_a

			; Main.bas 373: Case 128
			dw sel45_e_go
sel45_10:
			dw kw_cpeqvl, var_bdos___sel45, 128
			dw kw_goto_iffalse_n, sel45_11
sel45_b11:

			; Main.bas 375: Case 129                      ' the stub's key wait (BDOS 1, 10, BIOS CONIN): sleep till a key
			dw sel45_e_go
sel45_11:
			dw kw_cpeqvl, var_bdos___sel45, 129
			dw kw_goto_iffalse_n, sel45_12
sel45_b12:

			; Main.bas 376: If kq(t) = 0 Then wk(t) = Ticks
			dw kw_aget, arr_kq, var_bdos_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, sel45_e
			dw kw_ticks, tmp1
			dw kw_aset, arr_wk, var_bdos_t, tmp1
if49_1:

			; Main.bas 377: Case Else
			dw sel45_e_go
sel45_12:

			; Main.bas 378: a = 255
			dw kw_ltov, 255, var_bdos_a

			; Main.bas 379: End Select
sel45_e:

			; Main.bas 380: ra(t) = a
			dw kw_aset, arr_ra, var_bdos_t, var_bdos_a
			dw p_bdos_r

ntc_rg5_e:
			IF ($ < 32768) && (ntc_rg6_e - ntc_rg6 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg6:
; ============================================================
; function ramdisc (normal mode)
; ============================================================

p_ramdisc:

			; Main.bas 390: Dim g As Integer, o As Integer, f As Long

			; Main.bas 391: o = Memory.ReadByte(Far(t, p))
			dw p_far_c, var_ramdisc_t, var_ramdisc_p
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_ramdisc_o

			; Main.bas 392: If dp = 0 Then
			dw kw_cpeqvl, var_dp, 0
			dw kw_goto_iffalse_n, if50_1

			; Main.bas 393: RamDisc = 255
			dw kw_ltov, 255, var_ramdisc_ramdisc

			; Main.bas 394: If o = 3 Then Exit Function                              ' (the list: none)
			dw kw_cpeqvl, var_ramdisc_o, 3
			dw kw_goto_iffalse_n, if51_1
			dw p_ramdisc_r
if51_1:

			; Main.bas 395: dp = Memory.AllocPage(Memory.TypeUser)
			dw fn_memory_allocpage, lit_85, var_dp

			; Main.bas 396: If dp = 0 Then RamDisc = 2 : Exit Function
			dw kw_cpeqvl, var_dp, 0
			dw kw_goto_iffalse_n, if52_1
			dw kw_ltov, 2, var_ramdisc_ramdisc
			dw p_ramdisc_r
if52_1:

			; Main.bas 397: f = Far(t, Memory.ReadWord(Far(t, p + 2)))                 ' (Far's FarPtr: one result for all calls)
			dw kw_addl, var_ramdisc_p, 2, tmp2
			dw p_far_c, var_ramdisc_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_readword, ltmp1, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp1
			dw p_far_c, var_ramdisc_t, tmp1
			dw kw_l_mov, var_far_far, var_ramdisc_f

			; Main.bas 398: Memory.Copy f, Hyp.FarPtr(dp, 0), Memory.ReadWord(Far(t, p + 4))
			dw fn_hyp_farptr, var_dp, lit_0, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp1
			dw kw_addl, var_ramdisc_p, 4, tmp3
			dw p_far_c, var_ramdisc_t, tmp3
			dw kw_l_mov, var_far_far, ltmp2
			dw fn_memory_readword, ltmp2, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp2
			dw fn_memory_copy, var_ramdisc_f, ltmp1, tmp2, var_memory_copy_copy

			; Main.bas 399: g = Memory.SelectPage(dp)
			dw fn_memory_selectpage, var_dp, var_ramdisc_g

			; Main.bas 400: Hyp.UseDriver VarPtr(rb)
			dw p_hyp_usedriver_c, vp_arr_rb

			; Main.bas 401: g = Hyp.FileCall(110, 0, 0, 0, 0, 0, 0)                    ' (its tables cleared)
			dw p_hyp_filecall_c, lit_110, lit_0, lit_0, lit_0, lit_0, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_ramdisc_g

			; Main.bas 402: End If
if50_1:

			; Main.bas 403: g = 0
			dw kw_ztov, var_ramdisc_g

			; Main.bas 404: If o = 2 Then
			dw kw_cpeqvl, var_ramdisc_o, 2
			dw kw_goto_iffalse_n, if53_1

			; Main.bas 405: g = Memory.AllocPage(Memory.TypeUser)
			dw fn_memory_allocpage, lit_85, var_ramdisc_g

			; Main.bas 406: RamDisc = 2
			dw kw_ltov, 2, var_ramdisc_ramdisc

			; Main.bas 407: If g = 0 Then Exit Function
			dw kw_cpeqvl, var_ramdisc_g, 0
			dw kw_goto_iffalse_n, if54_1
			dw p_ramdisc_r
if54_1:

			; Main.bas 408: RamDisc = Memory.SelectPage(g)
			dw fn_memory_selectpage, var_ramdisc_g, var_ramdisc_ramdisc

			; Main.bas 409: End If
if53_1:

			; Main.bas 410: RamDisc = Hyp.FileCall(116, p, t, sg(t), g, Hyp.Setting(), 0)
			dw kw_aget, arr_sg, var_ramdisc_t, tmp3
			dw fn_hyp_setting, var_hyp_setting_setting
			dw kw_vtov, var_hyp_setting_setting, tmp5
			dw p_hyp_filecall_c, lit_116, var_ramdisc_p, var_ramdisc_t, tmp3, var_ramdisc_g, tmp5, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_ramdisc_ramdisc

			; Main.bas 411: If RamDisc < 0 Then RamDisc = Memory.FreePage(RamDisc And &H7FFF) : RamDisc = 0   ' (a page back: + #8000)
			dw kw_scpltvl, var_ramdisc_ramdisc, 0
			dw kw_goto_iffalse_n, if55_1
			dw kw_andvl, var_ramdisc_ramdisc, 32767, tmp0
			dw fn_memory_freepage, tmp0, var_ramdisc_ramdisc
			dw kw_ztov, var_ramdisc_ramdisc
if55_1:

			; Main.bas 412: If g <> 0 And RamDisc <> 0 Then RamDisc = Memory.FreePage(g) : RamDisc = 2
			dw kw_cpnevl, var_ramdisc_g, 0
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_ramdisc_ramdisc, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if56_1
			dw fn_memory_freepage, var_ramdisc_g, var_ramdisc_ramdisc
			dw kw_ltov, 2, var_ramdisc_ramdisc
if56_1:
			dw p_ramdisc_r

ntc_rg6_e:
			IF ($ < 32768) && (ntc_rg7_e - ntc_rg7 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg7:
; ============================================================
; function storesize (normal mode)
; ============================================================

p_storesize:

			; Main.bas 423: Dim n As Integer, j As Integer, g As Integer

			; Main.bas 424: n = (kb + 15) \ 16
			dw kw_addl, var_storesize_kb, 15, tmp0
			dw kw_divvl, tmp0, 16, var_storesize_n

			; Main.bas 425: If kb < 0 Or n > 32 Then n = 32
			dw kw_scpltvl, var_storesize_kb, 0
			dw kw_ftov, tmp0
			dw kw_scpgtvl, var_storesize_n, 32
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if57_1
			dw kw_ltov, 32, var_storesize_n
if57_1:

			; Main.bas 426: For j = 0 To 31
			dw kw_ztov, var_storesize_j
for58_t:

			; Main.bas 427: g = Memory.ReadByte(Far(t, STORE + j))
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_storesize_g

			; Main.bas 428: If j < n And g = 0 Then
			dw kw_scpltvv, var_storesize_j, var_storesize_n
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_storesize_g, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if59_1

			; Main.bas 429: g = Memory.AllocPage(Memory.TypeUser)
			dw fn_memory_allocpage, lit_85, var_storesize_g

			; Main.bas 430: If g = 0 Then StoreSize = 2 : Exit Function
			dw kw_cpeqvl, var_storesize_g, 0
			dw kw_goto_iffalse_n, if60_1
			dw kw_ltov, 2, var_storesize_storesize
			dw p_storesize_r
if60_1:

			; Main.bas 431: Memory.WriteByte Far(t, STORE + j), g
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_storesize_g

			; Main.bas 432: ElseIf j >= n And g <> 0 Then
			dw if59_e_go
if59_1:
			dw kw_scpgevv, var_storesize_j, var_storesize_n
			dw kw_ftov, tmp0
			dw kw_cpnevl, var_storesize_g, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if59_2

			; Main.bas 433: g = Memory.FreePage(g)
			dw fn_memory_freepage, var_storesize_g, var_memory_freepage_freepage
			dw kw_vtov, var_memory_freepage_freepage, var_storesize_g

			; Main.bas 434: Memory.WriteByte Far(t, STORE + j), 0
			dw kw_addl, var_storesize_j, -256, tmp1
			dw p_far_c, var_storesize_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 435: End If
if59_2:
if59_e:

			; Main.bas 436: Next
			dw kw_next1l_n, var_storesize_j, 31, for58_t
for58_e:
			dw p_storesize_r

ntc_rg7_e:
			IF ($ < 32768) && (ntc_rg8_e - ntc_rg8 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg8:
; ============================================================
; sub storefree (normal mode)
; ============================================================

p_storefree:

			; Main.bas 477: Dim r As Integer

			; Main.bas 478: r = StoreSize(t, 0)
			dw p_storesize_c, var_storefree_t, lit_0
			dw kw_vtov, var_storesize_storesize, var_storefree_r
			dw p_storefree_r

ntc_rg8_e:
			IF ($ < 32768) && (ntc_rg9_e - ntc_rg9 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg9:
; ============================================================
; function sys (normal mode)
; ============================================================

p_sys:

			; Main.bas 492: Dim o As Integer, s As Integer, d As Integer

			; Main.bas 493: o = Memory.ReadByte(Far(t, p)) : s = Memory.ReadByte(Far(t, p + 1))
			dw p_far_c, var_sys_t, var_sys_p
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_sys_o
			dw kw_addl, var_sys_p, 1, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_sys_s

			; Main.bas 494: If o = 4 Then
			dw kw_cpeqvl, var_sys_o, 4
			dw kw_goto_iffalse_n, if68_1

			; Main.bas 495: If Running() > 1 Then wt = t
			dw p_running_c
			dw kw_vtov, var_running_running, tmp0
			dw kw_scpgtvl, tmp0, 1
			dw kw_goto_iffalse_n, if69_1
			dw kw_vtov, var_sys_t, var_wt
if69_1:

			; Main.bas 496: Exit Function
			dw p_sys_r

			; Main.bas 497: ElseIf o = 6 Then
if68_1:
			dw kw_cpeqvl, var_sys_o, 6
			dw kw_goto_iffalse_n, if68_2

			; Main.bas 498: txs = t
			dw kw_vtov, var_sys_t, var_txs

			; Main.bas 499: TopLines front, 0
			dw p_toplines_c, var_front, lit_0

			; Main.bas 500: Exit Function
			dw p_sys_r

			; Main.bas 501: ElseIf o = 9 Then                               ' MODE: s 0-4 this slot's mode (its console
if68_2:
			dw kw_cpeqvl, var_sys_o, 9
			dw kw_goto_iffalse_n, if68_3

			; Main.bas 502: If s = 255 Then Sys = Memory.ReadByte(Far(t, Hyp.CMODE)) : Exit Function   ' cleared), 255: which
			dw kw_cpeqvl, var_sys_s, 255
			dw kw_goto_iffalse_n, if70_1
			dw p_far_c, var_sys_t, lit_m2423
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_sys_sys
			dw p_sys_r
if70_1:

			; Main.bas 503: If s > 5 Then Sys = 255 : Exit Function                                     ' it is
			dw kw_scpgtvl, var_sys_s, 5
			dw kw_goto_iffalse_n, if71_1
			dw kw_ltov, 255, var_sys_sys
			dw p_sys_r
if71_1:

			; Main.bas 504: SetMode t, s
			dw p_setmode_c, var_sys_t, var_sys_s

			; Main.bas 505: Exit Function
			dw p_sys_r

			; Main.bas 508: ElseIf o = 10 Or o = 11 Or o >= 13 Then         ' memory, the pointer, the store's blocks, tables,
if68_3:
			dw kw_cpeqvl, var_sys_o, 10
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_sys_o, 11
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_scpgevl, var_sys_o, 13
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if68_4

			; Main.bas 509: Sys = Hyp.Svc(t, p, sg(t), VarPtr(rb))       ' the claims (16-19), the network, the ports
			dw kw_aget, arr_sg, var_sys_t, tmp2
			dw p_hyp_svc_c, var_sys_t, var_sys_p, tmp2, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_sys_sys

			; Main.bas 510: If Sys = 1 And o >= 30 Then wk(t) = Ticks    ' (28-33): in the service page. A port's "not yet":
			dw kw_cpeqvl, var_sys_sys, 1
			dw kw_ftov, tmp0
			dw kw_scpgevl, var_sys_o, 30
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if72_1
			dw kw_ticks, tmp1
			dw kw_aset, arr_wk, var_sys_t, tmp1
if72_1:

			; Main.bas 511: Exit Function                                ' the slot sleeps a tick, as for a key
			dw p_sys_r

			; Main.bas 512: ElseIf o = 12 Then                              ' the slot's store: Word(2) K (16K pages, 512K at most)
if68_4:
			dw kw_cpeqvl, var_sys_o, 12
			dw kw_goto_iffalse_n, if68_5

			; Main.bas 513: Sys = StoreSize(t, Memory.ReadWord(Far(t, p + 2)))
			dw kw_addl, var_sys_p, 2, tmp2
			dw p_far_c, var_sys_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_readword, ltmp1, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp1
			dw p_storesize_c, var_sys_t, tmp1
			dw kw_vtov, var_storesize_storesize, var_sys_sys

			; Main.bas 514: Exit Function
			dw p_sys_r

			; Main.bas 518: ElseIf o = 7 Then
if68_5:
			dw kw_cpeqvl, var_sys_o, 7
			dw kw_goto_iffalse_n, if68_6

			; Main.bas 519: Memory.WriteWord Far(t, p + 2), Memory.TableEnd()
			dw kw_addl, var_sys_p, 2, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_tableend, var_memory_tableend_tableend
			dw kw_vtov, var_memory_tableend_tableend, tmp1
			dw fn_memory_writeword, ltmp0, tmp1

			; Main.bas 520: Memory.WriteWord Far(t, p + 4), Memory.Top()
			dw kw_addl, var_sys_p, 4, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_top, var_memory_top_top
			dw kw_vtov, var_memory_top_top, tmp1
			dw fn_memory_writeword, ltmp0, tmp1

			; Main.bas 521: Memory.WriteWord Far(t, p + 6), Memory.Pages()
			dw kw_addl, var_sys_p, 6, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_pages, var_memory_pages_pages
			dw kw_vtov, var_memory_pages_pages, tmp1
			dw fn_memory_writeword, ltmp0, tmp1

			; Main.bas 522: Totals
			dw p_totals_c

			; Main.bas 523: PutEn t, p + 8
			dw kw_addl, var_sys_p, 8, tmp1
			dw p_puten_c, var_sys_t, tmp1

			; Main.bas 524: Exit Function
			dw p_sys_r

			; Main.bas 525: ElseIf o = 8 Then
if68_6:
			dw kw_cpeqvl, var_sys_o, 8
			dw kw_goto_iffalse_n, if68_7

			; Main.bas 526: en = Memory.Map(Memory.ReadWord(Far(t, p + 2)), 32)
			dw kw_addl, var_sys_p, 2, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readword, ltmp0, var_memory_readword_readword
			dw kw_vtov, var_memory_readword_readword, tmp0
			dw fn_memory_map, tmp0, lit_32, var_memory_map_map
			dw kw_strcpy, var_en, var_memory_map_map

			; Main.bas 527: PutEn t, p + 4
			dw kw_addl, var_sys_p, 4, tmp1
			dw p_puten_c, var_sys_t, tmp1

			; Main.bas 528: Exit Function
			dw p_sys_r

			; Main.bas 530: End If
if68_7:
if68_e:

			; Main.bas 531: If o = 2 And s = 0 Then s = t
			dw kw_cpeqvl, var_sys_o, 2
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_sys_s, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if73_1
			dw kw_vtov, var_sys_t, var_sys_s
if73_1:

			; Main.bas 532: Sys = 255
			dw kw_ltov, 255, var_sys_sys

			; Main.bas 533: If s < 1 Or s > ns Then Exit Function
			dw kw_scpltvl, var_sys_s, 1
			dw kw_ftov, tmp0
			dw kw_scpgtvv, var_sys_s, var_ns
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if74_1
			dw p_sys_r
if74_1:

			; Main.bas 534: Sys = 0
			dw kw_ztov, var_sys_sys

			; Main.bas 535: If o = 0 Then
			dw kw_cpeqvl, var_sys_o, 0
			dw kw_goto_iffalse_n, if75_1

			; Main.bas 536: Memory.WriteByte Far(t, p + 2), st(s)
			dw kw_addl, var_sys_p, 2, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_aget, arr_st, var_sys_s, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 537: Memory.WriteByte Far(t, p + 3), IIf(s = front, 1, 0)
			dw kw_addl, var_sys_p, 3, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_cpeqvv, var_sys_s, var_front
			dw kw_ftov, tmp1
			dw kw_goto_ifzero_n, tmp1, ch76_0
			dw kw_ltov, 1, tmp1
			dw ch76_e_go
ch76_0:
			dw kw_ztov, tmp1
			dw ch76_e_go
ch76_1:
			dw kw_ztov, tmp1
ch76_e:
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 538: en = ""
			dw kw_strcpy, var_en, str0

			; Main.bas 539: If st(s) = 2 Then GetNm s
			dw kw_aget, arr_st, var_sys_s, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if77_1
			dw p_getnm_c, var_sys_s
if77_1:

			; Main.bas 540: PutEn t, p + 4
			dw kw_addl, var_sys_p, 4, tmp1
			dw p_puten_c, var_sys_t, tmp1

			; Main.bas 541: ElseIf o = 1 Then
			dw if75_e_go
if75_1:
			dw kw_cpeqvl, var_sys_o, 1
			dw kw_goto_iffalse_n, if75_2

			; Main.bas 542: If st(s) = 2 Then EndTask s Else Sys = 1
			dw kw_aget, arr_st, var_sys_s, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if78_1
			dw p_endtask_c, var_sys_s
			dw if75_e_go
if78_1:
			dw kw_ltov, 1, var_sys_sys
if78_e:

			; Main.bas 543: ElseIf o = 2 Then
			dw if75_e_go
if75_2:
			dw kw_cpeqvl, var_sys_o, 2
			dw kw_goto_iffalse_n, if75_3

			; Main.bas 544: ResetSlot s
			dw p_resetslot_c, var_sys_s

			; Main.bas 545: If s = t Then Prompt t                       ' (RESET of its own slot: the program gone)
			dw kw_cpeqvv, var_sys_s, var_sys_t
			dw kw_goto_iffalse_n, if75_e
			dw p_prompt_c, var_sys_t
if79_1:

			; Main.bas 546: ElseIf o = 3 Then
			dw if75_e_go
if75_3:
			dw kw_cpeqvl, var_sys_o, 3
			dw kw_goto_iffalse_n, if75_4

			; Main.bas 547: ToFront s
			dw p_tofront_c, var_sys_s

			; Main.bas 548: End If
if75_4:
if75_e:
			dw p_sys_r

ntc_rg9_e:
			IF ($ < 32768) && (ntc_rg10_e - ntc_rg10 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg10:
; ============================================================
; sub puten (normal mode)
; ============================================================

p_puten:

			; Main.bas 553: Memory.WriteByte Far(t, a), Len(en)
			dw p_far_c, var_puten_t, var_puten_a
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_strlen, var_en, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 554: Memory.Copy NearP(VarPtr(en)), Far(t, a + 1), Len(en)
			dw p_nearp_c, vp_var_en
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw kw_addl, var_puten_a, 1, tmp2
			dw p_far_c, var_puten_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw kw_strlen, var_en, tmp2
			dw fn_memory_copy, ltmp0, ltmp1, tmp2, var_memory_copy_copy
			dw p_puten_r

ntc_rg10_e:
			IF ($ < 32768) && (ntc_rg11_e - ntc_rg11 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg11:
; ============================================================
; function hopen (normal mode)
; ============================================================

p_hopen:

			; Main.bas 560: HOpen = (Hyp.FileCall(100, VarPtr(dn), 0, 0, Len(dn), 0, 0) = 0)
			dw kw_strlen, var_dn, tmp4
			dw p_hyp_filecall_c, lit_100, vp_var_dn, lit_0, lit_0, tmp4, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_ftov, var_hopen_hopen
			dw p_hopen_r

ntc_rg11_e:
			IF ($ < 32768) && (ntc_rg12_e - ntc_rg12 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg12:
; ============================================================
; sub hclose (normal mode)
; ============================================================

p_hclose:

			; Main.bas 566: Dim r As Integer

			; Main.bas 567: r = Hyp.FileCall(102, 0, 0, 0, 0, 0, 0)
			dw p_hyp_filecall_c, lit_102, lit_0, lit_0, lit_0, lit_0, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_hclose_r
			dw p_hclose_r

ntc_rg12_e:
			IF ($ < 32768) && (ntc_rg13_e - ntc_rg13 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg13:
; ============================================================
; sub filesshut (normal mode)
; ============================================================

p_filesshut:

			; Main.bas 572: Dim r As Integer

			; Main.bas 573: Hyp.FileShut t
			dw p_hyp_fileshut_c, var_filesshut_t

			; Main.bas 576: r = Hyp.Svc(t, 0, 0, VarPtr(rb))               ' its claims freed (the service page)
			dw p_hyp_svc_c, var_filesshut_t, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_svc_svc, var_filesshut_r
			dw p_filesshut_r

ntc_rg13_e:
			IF ($ < 32768) && (ntc_rg14_e - ntc_rg14 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg14:
; ============================================================
; sub collected (normal mode)
; ============================================================

p_collected:

			; Main.bas 586: nc(t) = nc(t) + n
			dw kw_aget, arr_nc, var_collected_t, tmp1
			dw kw_add, tmp1, var_collected_n, tmp1
			dw kw_aset, arr_nc, var_collected_t, tmp1

			; Main.bas 587: Hyp.Con wp(t), 0, n, IIf(t = front, 1, 0)       ' straight from the bank: no copy to main RAM
			dw kw_aget, arr_wp, var_collected_t, tmp0
			dw kw_cpeqvv, var_collected_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch80_0
			dw kw_ltov, 1, tmp3
			dw ch80_e_go
ch80_0:
			dw kw_ztov, tmp3
			dw ch80_e_go
ch80_1:
			dw kw_ztov, tmp3
ch80_e:
			dw p_hyp_con_c, tmp0, lit_0, var_collected_n, tmp3
			dw p_collected_r

ntc_rg14_e:
			IF ($ < 32768) && (ntc_rg15_e - ntc_rg15 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg15:
; ============================================================
; sub puts (normal mode)
; ============================================================

p_puts:

			; Main.bas 592: Hyp.Con wp(t), VarPtr(s), Len(s), IIf(t = front, 1, 0)
			dw kw_aget, arr_wp, var_puts_t, tmp0
			dw kw_strlen, var_puts_s, tmp2
			dw kw_cpeqvv, var_puts_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch81_0
			dw kw_ltov, 1, tmp3
			dw ch81_e_go
ch81_0:
			dw kw_ztov, tmp3
			dw ch81_e_go
ch81_1:
			dw kw_ztov, tmp3
ch81_e:
			dw p_hyp_con_c, tmp0, vp_var_puts_s, tmp2, tmp3
			dw p_puts_r

ntc_rg15_e:
			IF ($ < 32768) && (ntc_rg16_e - ntc_rg16 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg16:
; ============================================================
; sub putln (normal mode)
; ============================================================

p_putln:

			; Main.bas 596: PutS t, s + Chr$(13) + Chr$(10)
			dw kw_strcpy, stmp1, var_putln_s
			dw kw_strcat, stmp1, str2
			dw kw_strcat, stmp1, str3
			dw p_puts_c, var_putln_t, stmp1
			dw p_putln_r

ntc_rg16_e:
			IF ($ < 32768) && (ntc_rg17_e - ntc_rg17 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg17:
; ============================================================
; sub putc (normal mode)
; ============================================================

p_putc:

			; Main.bas 601: Hyp.Con wp(t), VarPtr(c), 1, IIf(t = front, 1, 0)   ' (the Integer's low byte is the character)
			dw kw_aget, arr_wp, var_putc_t, tmp0
			dw kw_cpeqvv, var_putc_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch82_0
			dw kw_ltov, 1, tmp3
			dw ch82_e_go
ch82_0:
			dw kw_ztov, tmp3
			dw ch82_e_go
ch82_1:
			dw kw_ztov, tmp3
ch82_e:
			dw p_hyp_con_c, tmp0, vp_var_putc_c, lit_1, tmp3
			dw p_putc_r

ntc_rg17_e:
			IF ($ < 32768) && (ntc_rg18_e - ntc_rg18 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg18:
; ============================================================
; function nearp (normal mode)
; ============================================================

p_nearp:

			; Main.bas 624: NearP = CLng(p)
			dw kw_l_itol, var_nearp_p, var_nearp_nearp

			; Main.bas 625: If p < 0 Then NearP = NearP + 65536
			dw kw_scpltvl, var_nearp_p, 0
			dw kw_goto_iffalse_n, if83_1
			dw kw_l_add, var_nearp_nearp, llit_65536, var_nearp_nearp
if83_1:
			dw p_nearp_r

ntc_rg18_e:
			IF ($ < 32768) && (ntc_rg19_e - ntc_rg19 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg19:
; ============================================================
; function far (normal mode)
; ============================================================

p_far:

			; Main.bas 630: Far = Hyp.FarPtr(Memory.BankPage(bk(t), ((a And &HC000) \ 16384) And 3), a)
			dw kw_aget, arr_bk, var_far_t, tmp2
			dw kw_andvl, var_far_a, -16384, tmp3
			dw kw_divvl, tmp3, 16384, tmp3
			dw kw_andvl, tmp3, 3, tmp3
			dw p_memory_bankpage_c, tmp2, tmp3
			dw kw_vtov, var_memory_bankpage_bankpage, tmp2
			dw fn_hyp_farptr, tmp2, var_far_a, var_far_far
			dw p_far_r

ntc_rg19_e:
			IF ($ < 32768) && (ntc_rg20_e - ntc_rg20 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg20:
; ============================================================
; sub clst (normal mode)
; ============================================================

p_clst:

			; Main.bas 635: PutS t, Chr$(27) + "E"
			dw kw_strcpy, stmp1, str4
			dw kw_strcat, stmp1, str5
			dw p_puts_c, var_clst_t, stmp1
			dw p_clst_r

ntc_rg20_e:
			IF ($ < 32768) && (ntc_rg21_e - ntc_rg21 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg21:
; ============================================================
; sub tofront (normal mode)
; ============================================================

p_tofront:

			; Main.bas 640: Dim r As Integer

			; Main.bas 641: front = t
			dw kw_vtov, var_tofront_t, var_front

			; Main.bas 642: If st(t) = 0 Then OpenSlot t : Exit Sub
			dw kw_aget, arr_st, var_tofront_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if84_1
			dw p_openslot_c, var_tofront_t
			dw p_tofront_r
if84_1:

			; Main.bas 643: r = Hyp.Scr(Memory.ReadByte(Far(t, Hyp.CMODE)), 2)   ' the screen in its mode (cleared)
			dw p_far_c, var_tofront_t, lit_m2423
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_memory_readbyte_readbyte
			dw kw_vtov, var_memory_readbyte_readbyte, tmp0
			dw p_hyp_scr_c, tmp0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_tofront_r

			; Main.bas 644: Hyp.Show wp(t)
			dw kw_aget, arr_wp, var_tofront_t, tmp0
			dw p_hyp_show_c, tmp0
			dw p_tofront_r

ntc_rg21_e:
			IF ($ < 32768) && (ntc_rg22_e - ntc_rg22 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg22:
; ============================================================
; sub setmode (normal mode)
; ============================================================

p_setmode:

			; Main.bas 651: Dim r As Integer

			; Main.bas 652: Memory.WriteByte Far(t, Hyp.CCOLS), Hyp.Scr(m, 0)
			dw p_far_c, var_setmode_t, lit_m2425
			dw kw_l_mov, var_far_far, ltmp0
			dw p_hyp_scr_c, var_setmode_m, lit_0
			dw kw_vtov, var_hyp_scr_scr, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 653: Memory.WriteByte Far(t, Hyp.CROWS), Hyp.Scr(m, 1)
			dw p_far_c, var_setmode_t, lit_m2424
			dw kw_l_mov, var_far_far, ltmp0
			dw p_hyp_scr_c, var_setmode_m, lit_1
			dw kw_vtov, var_hyp_scr_scr, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 654: Memory.WriteByte Far(t, Hyp.CMODE), m
			dw p_far_c, var_setmode_t, lit_m2423
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_setmode_m

			; Main.bas 655: en = Left$("[" + N(t) + "]   ", 4)
			dw p_n_c, var_setmode_t
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcpy, stmp0, str6
			dw kw_strcat, stmp0, stmp1
			dw kw_strcat, stmp0, str7
			dw kw_strleft, stmp0, stmp0, lit_4
			dw kw_strcpy, var_en, stmp0

			; Main.bas 656: Memory.Copy NearP(VarPtr(en)), Far(t, Hyp.CSTRIP), 4
			dw p_nearp_c, vp_var_en
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_setmode_t, lit_m2422
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, lit_4, var_memory_copy_copy

			; Main.bas 657: If t = front Then r = Hyp.Scr(m, 2)
			dw kw_cpeqvv, var_setmode_t, var_front
			dw kw_goto_iffalse_n, if85_1
			dw p_hyp_scr_c, var_setmode_m, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_setmode_r
if85_1:

			; Main.bas 658: ClsT t
			dw p_clst_c, var_setmode_t
			dw p_setmode_r

ntc_rg22_e:
			IF ($ < 32768) && (ntc_rg23_e - ntc_rg23 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg23:
; ============================================================
; sub showtop (normal mode)
; ============================================================

p_showtop:

			; Main.bas 821: Dim j As Integer

			; Main.bas 822: If front <> 0 Then back = front
			dw kw_cpnevl, var_front, 0
			dw kw_goto_iffalse_n, if86_1
			dw kw_vtov, var_front, var_back
if86_1:

			; Main.bas 823: front = 0
			dw kw_ztov, var_front

			; Main.bas 824: j = Hyp.Scr(0, 2)               ' TOP in MODE 2 (80 x 25), the screen cleared
			dw p_hyp_scr_c, lit_0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_showtop_j

			; Main.bas 825: txs = 0
			dw kw_ztov, var_txs

			; Main.bas 826: TopLines back, 1
			dw p_toplines_c, var_back, lit_1
			dw p_showtop_r

ntc_rg23_e:
			IF ($ < 32768) && (ntc_rg24_e - ntc_rg24 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg24:
; ============================================================
; sub toplines (normal mode)
; ============================================================

p_toplines:

			; Main.bas 832: Dim j As Integer, s As String Max 14

			; Main.bas 833: txn = 0
			dw kw_ztov, var_txn

			; Main.bas 834: TopAdd "CyborgOS TOP"
			dw p_topadd_c, str8

			; Main.bas 835: If keys Then TopAdd "Control + ESC: back, " + SK() + ": that slot" Else TopAdd ""   ' (25 rows: 20 slots)
			dw kw_goto_ifzero_n, var_toplines_keys, if87_1
			dw p_sk_c
			dw kw_strcpy, stmp1, var_sk_sk
			dw kw_strcpy, stmp0, str9
			dw kw_strcat, stmp0, stmp1
			dw kw_strcat, stmp0, str10
			dw p_topadd_c, stmp0
			dw if87_e_go
if87_1:
			dw p_topadd_c, str0
if87_e:

			; Main.bas 836: TopAdd "SLOT  STATE          PROGRAM         TURNS/S   BDOS/S  CHARS/S   (last second)"
			dw p_topadd_c, str11

			; Main.bas 837: For j = 1 To ns
			dw kw_ltov, 1, var_toplines_j
			dw kw_vtov, var_ns, for88_l
			dw kw_forupv_n, var_toplines_j, for88_l, for88_e
for88_t:

			; Main.bas 838: If st(j) = 0 Then
			dw kw_aget, arr_st, var_toplines_j, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if89_1

			; Main.bas 839: s = "-"
			dw kw_strcpy, var_toplines_s, str12

			; Main.bas 840: ElseIf st(j) = 1 Then
			dw if89_e_go
if89_1:
			dw kw_aget, arr_st, var_toplines_j, tmp0
			dw kw_cpeqvl, tmp0, 1
			dw kw_goto_iffalse_n, if89_2

			; Main.bas 841: s = "command line"
			dw kw_strcpy, var_toplines_s, str13

			; Main.bas 842: ElseIf wk(j) >= 0 Then
			dw if89_e_go
if89_2:
			dw kw_aget, arr_wk, var_toplines_j, tmp0
			dw kw_scpgevl, tmp0, 0
			dw kw_goto_iffalse_n, if89_3

			; Main.bas 843: s = "waiting (key)"
			dw kw_strcpy, var_toplines_s, str14

			; Main.bas 844: Else
			dw if89_e_go
if89_3:

			; Main.bas 845: s = "running"
			dw kw_strcpy, var_toplines_s, str15

			; Main.bas 846: End If
if89_e:

			; Main.bas 847: en = ""
			dw kw_strcpy, var_en, str0

			; Main.bas 848: If st(j) = 2 Then GetNm j
			dw kw_aget, arr_st, var_toplines_j, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if90_1
			dw p_getnm_c, var_toplines_j
if90_1:

			; Main.bas 849: TopAdd " " + Right$(" " + N(j), 2) + IIf(j = mark, "*", " ") + "  " + Left$(s + Space$(15), 15) + Left$(en + Space$(13), 13) + Pad(Rate(lt(j), ld)) + Pad(Rate(lb(j), ld)) + Pad(Rate(lc(j), ld))
			dw p_n_c, var_toplines_j
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcpy, stmp1, str16
			dw kw_strcat, stmp1, stmp2
			dw kw_strright, stmp1, stmp1, lit_2
			dw kw_strcpy, stmp0, str16
			dw kw_strcat, stmp0, stmp1
			dw kw_cpeqvv, var_toplines_j, var_toplines_mark
			dw kw_ftov, tmp1
			dw kw_goto_ifzero_n, tmp1, ch91_0
			dw kw_strcpy, stmp1, str17
			dw ch91_e_go
ch91_0:
			dw kw_strcpy, stmp1, str16
			dw ch91_e_go
ch91_1:
			dw kw_strcpy, stmp1, str0
ch91_e:
			dw kw_strcat, stmp0, stmp1
			dw kw_strcat, stmp0, str18
			dw kw_strspace, stmp2, lit_15
			dw kw_strcpy, stmp1, var_toplines_s
			dw kw_strcat, stmp1, stmp2
			dw kw_strleft, stmp1, stmp1, lit_15
			dw kw_strcat, stmp0, stmp1
			dw kw_strspace, stmp2, lit_13
			dw kw_strcpy, stmp1, var_en
			dw kw_strcat, stmp1, stmp2
			dw kw_strleft, stmp1, stmp1, lit_13
			dw kw_strcat, stmp0, stmp1
			dw kw_aget, arr_lt, var_toplines_j, tmp1
			dw p_rate_c, tmp1, var_ld
			dw kw_vtov, var_rate_rate, tmp1
			dw p_pad_c, tmp1
			dw kw_strcpy, stmp1, var_pad_pad
			dw kw_strcat, stmp0, stmp1
			dw kw_aget, arr_lb, var_toplines_j, tmp1
			dw p_rate_c, tmp1, var_ld
			dw kw_vtov, var_rate_rate, tmp1
			dw p_pad_c, tmp1
			dw kw_strcpy, stmp1, var_pad_pad
			dw kw_strcat, stmp0, stmp1
			dw kw_aget, arr_lc, var_toplines_j, tmp1
			dw p_rate_c, tmp1, var_ld
			dw kw_vtov, var_rate_rate, tmp1
			dw p_pad_c, tmp1
			dw kw_strcpy, stmp1, var_pad_pad
			dw kw_strcat, stmp0, stmp1
			dw p_topadd_c, stmp0

			; Main.bas 850: Next
			dw kw_next1v_n, var_toplines_j, for88_l, for88_t
for88_e:

			; Main.bas 851: TopAdd ""
			dw p_topadd_c, str0

			; Main.bas 852: Totals
			dw p_totals_c

			; Main.bas 853: TopAdd en
			dw p_topadd_c, var_en
			dw p_toplines_r

ntc_rg24_e:
			IF ($ < 32768) && (ntc_rg25_e - ntc_rg25 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg25:
; ============================================================
; sub totals (normal mode)
; ============================================================

p_totals:

			; Main.bas 858: en = "Total memory: " + N(Memory.RamSize()) + " KB   Free memory: " + N(Memory.FreePages() * 16) + " KB"
			dw fn_memory_ramsize, var_memory_ramsize_ramsize
			dw kw_vtov, var_memory_ramsize_ramsize, tmp1
			dw p_n_c, tmp1
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcpy, stmp0, str19
			dw kw_strcat, stmp0, stmp1
			dw kw_strcat, stmp0, str20
			dw fn_memory_freepages, var_memory_freepages_freepages
			dw kw_vtov, var_memory_freepages_freepages, tmp1
			dw kw_mulvl, tmp1, 16, tmp1
			dw p_n_c, tmp1
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcat, stmp0, stmp1
			dw kw_strcpy, var_en, stmp0
			dw kw_strcat, var_en, str21
			dw p_totals_r

ntc_rg25_e:
			IF ($ < 32768) && (ntc_rg26_e - ntc_rg26 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg26:
; ============================================================
; sub topadd (normal mode)
; ============================================================

p_topadd:

			; Main.bas 866: If txs = 0 Then
			dw kw_cpeqvl, var_txs, 0
			dw kw_goto_iffalse_n, if92_1

			; Main.bas 867: Hyp.Say VarPtr(s), Len(s), 0, txn          ' straight into screen memory (Print took ~0.7 s)
			dw kw_strlen, var_topadd_s, tmp1
			dw p_hyp_say_c, vp_var_topadd_s, tmp1, lit_0, var_txn

			; Main.bas 868: Else
			dw if92_e_go
if92_1:

			; Main.bas 869: PutLn txs, s
			dw p_putln_c, var_txs, var_topadd_s

			; Main.bas 870: End If
if92_e:

			; Main.bas 871: txn = txn + 1
			dw kw_inc, var_txn
			dw p_topadd_r

ntc_rg26_e:
			IF ($ < 32768) && (ntc_rg27_e - ntc_rg27 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg27:
; ============================================================
; sub roll (normal mode)
; ============================================================

p_roll:

			; Main.bas 876: Dim j As Integer

			; Main.bas 877: ld = Ticks - td
			dw kw_ticks, tmp0
			dw kw_subvv, tmp0, var_td, var_ld

			; Main.bas 878: td = Ticks
			dw kw_ticks, tmp0
			dw kw_vtov, tmp0, var_td

			; Main.bas 879: For j = 1 To ns
			dw kw_ltov, 1, var_roll_j
			dw kw_vtov, var_ns, for93_l
			dw kw_forupv_n, var_roll_j, for93_l, for93_e
for93_t:

			; Main.bas 880: lt(j) = tn(j) : lb(j) = nb(j) : lc(j) = nc(j)
			dw kw_aget, arr_tn, var_roll_j, tmp1
			dw kw_aset, arr_lt, var_roll_j, tmp1
			dw kw_aget, arr_nb, var_roll_j, tmp1
			dw kw_aset, arr_lb, var_roll_j, tmp1
			dw kw_aget, arr_nc, var_roll_j, tmp1
			dw kw_aset, arr_lc, var_roll_j, tmp1

			; Main.bas 881: tn(j) = 0 : nb(j) = 0 : nc(j) = 0
			dw kw_asetl, arr_tn, var_roll_j, 0
			dw kw_asetl, arr_nb, var_roll_j, 0
			dw kw_asetl, arr_nc, var_roll_j, 0

			; Main.bas 882: Next
			dw kw_next1v_n, var_roll_j, for93_l, for93_t
for93_e:
			dw p_roll_r

ntc_rg27_e:
			IF ($ < 32768) && (ntc_rg28_e - ntc_rg28 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg28:
; ============================================================
; function pad (normal mode)
; ============================================================

p_pad:

			; Main.bas 887: Pad = Right$(Space$(9) + N(v), 9)
			dw kw_strspace, stmp1, lit_9
			dw p_n_c, var_pad_v
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcat, stmp1, stmp2
			dw kw_strright, var_pad_pad, stmp1, lit_9
			dw p_pad_r

ntc_rg28_e:
			IF ($ < 32768) && (ntc_rg29_e - ntc_rg29 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg29:
; ============================================================
; function rate (normal mode)
; ============================================================

p_rate:

			; Main.bas 892: If n > 1000 Then Rate = n \ (d \ 300 + 1) Else Rate = n * 30 \ (d \ 10 + 1)
			dw kw_scpgtvl, var_rate_n, 1000
			dw kw_goto_iffalse_n, if94_1
			dw kw_divvl, var_rate_d, 300, tmp2
			dw kw_inc, tmp2
			dw kw_divvv, var_rate_n, tmp2, var_rate_rate
			dw if94_e_go
if94_1:
			dw kw_mulvl, var_rate_n, 30, tmp1
			dw kw_divvl, var_rate_d, 10, tmp2
			dw kw_inc, tmp2
			dw kw_divvv, tmp1, tmp2, var_rate_rate
if94_e:
			dw p_rate_r

ntc_rg29_e:
			IF ($ < 32768) && (ntc_rg30_e - ntc_rg30 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg30:
; ============================================================
; sub install (normal mode)
; ============================================================

p_install:

			; Main.bas 899: Dim p As Integer, n As Integer

			; Main.bas 900: p = Hyp.Info(0) : n = Hyp.Info(1)             ' (one Info result each: it is one variable)
			dw fn_hyp_info, lit_0, var_install_p
			dw fn_hyp_info, lit_1, var_install_n

			; Main.bas 901: Memory.Copy Hyp.FarPtr(hp, p), Far(t, 0), n   ' (from the hypervisor's page)
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_0
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy

			; Main.bas 902: p = Hyp.Info(2) : n = Hyp.Info(3)
			dw fn_hyp_info, lit_2, var_install_p
			dw fn_hyp_info, lit_3, var_install_n

			; Main.bas 903: Memory.Copy Hyp.FarPtr(hp, p), Far(t, Hyp.STUB), n
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m4352
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy

			; Main.bas 904: Memory.Copy Hyp.FarPtr(hp, Hyp.HFONT), Far(t, Hyp.FONT), 768   ' the font (Con draws from it)
			dw fn_hyp_farptr, var_hp, lit_4096, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m3328
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, lit_768, var_memory_copy_copy

			; Main.bas 906: p = Hyp.Info(5) : n = Hyp.Info(6)
			dw fn_hyp_info, lit_5, var_install_p
			dw fn_hyp_info, lit_6, var_install_n

			; Main.bas 907: Memory.Copy Hyp.FarPtr(hp, p), Far(t, Hyp.HISW), n   ' the hyp->task switch-back receiver, below #FFFE
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m48
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy

			; Main.bas 909: Memory.WriteByte Far(t, Hyp.OBUF + 128), 0      ' no characters collected
			dw p_far_c, var_install_t, lit_m2432
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 910: Memory.WriteByte Far(t, Hyp.KEY), 0             ' no key waiting
			dw p_far_c, var_install_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 911: kq(t) = 0
			dw kw_asetl, arr_kq, var_install_t, 0

			; Main.bas 914: For n = 0 To 31                                 ' no store yet
			dw kw_ztov, var_install_n
for95_t:

			; Main.bas 915: Memory.WriteByte Far(t, STORE + n), 0
			dw kw_addl, var_install_n, -256, tmp1
			dw p_far_c, var_install_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 916: Next
			dw kw_next1l_n, var_install_n, 31, for95_t
for95_e:
			dw p_install_r

ntc_rg30_e:
			IF ($ < 32768) && (ntc_rg31_e - ntc_rg31 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg31:
; ============================================================
; sub resetslot (normal mode)
; ============================================================

p_resetslot:

			; Main.bas 923: FilesShut s
			dw p_filesshut_c, var_resetslot_s

			; Main.bas 926: If st(s) = 2 Then StoreFree s
			dw kw_aget, arr_st, var_resetslot_s, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if96_1
			dw p_storefree_c, var_resetslot_s
if96_1:

			; Main.bas 928: st(s) = 0
			dw kw_asetl, arr_st, var_resetslot_s, 0

			; Main.bas 931: dv(s) = 0
			dw kw_asetl, arr_dv, var_resetslot_s, 0

			; Main.bas 933: kq(s) = 0
			dw kw_asetl, arr_kq, var_resetslot_s, 0

			; Main.bas 934: wk(s) = -1
			dw kw_asetl, arr_wk, var_resetslot_s, -1

			; Main.bas 935: tn(s) = 0 : nb(s) = 0 : nc(s) = 0
			dw kw_asetl, arr_tn, var_resetslot_s, 0
			dw kw_asetl, arr_nb, var_resetslot_s, 0
			dw kw_asetl, arr_nc, var_resetslot_s, 0

			; Main.bas 936: lt(s) = 0 : lb(s) = 0 : lc(s) = 0
			dw kw_asetl, arr_lt, var_resetslot_s, 0
			dw kw_asetl, arr_lb, var_resetslot_s, 0
			dw kw_asetl, arr_lc, var_resetslot_s, 0

			; Main.bas 937: If s = front Then
			dw kw_cpeqvv, var_resetslot_s, var_front
			dw kw_goto_iffalse_n, if97_1

			; Main.bas 938: Install s
			dw p_install_c, var_resetslot_s

			; Main.bas 939: st(s) = 1
			dw kw_asetl, arr_st, var_resetslot_s, 1

			; Main.bas 940: SetMode s, 1
			dw p_setmode_c, var_resetslot_s, lit_1

			; Main.bas 941: PutLn s, "CyborgOS slot " + N(s) + " of " + N(ns) + " - " + SK() + ", Control + ESC TOP, HELP"
			dw p_n_c, var_resetslot_s
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcpy, stmp1, str22
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str23
			dw p_n_c, var_ns
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str24
			dw p_sk_c
			dw kw_strcpy, stmp2, var_sk_sk
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str25
			dw p_putln_c, var_resetslot_s, stmp1

			; Main.bas 942: PutLn s, ""                   ' a blank line under the title
			dw p_putln_c, var_resetslot_s, str0

			; Main.bas 943: End If                          ' (the prompt: the command line puts it after the command)
if97_1:
			dw p_resetslot_r

ntc_rg31_e:
			IF ($ < 32768) && (ntc_rg32_e - ntc_rg32 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg32:
; ============================================================
; sub openslot (normal mode)
; ============================================================

p_openslot:

			; Main.bas 947: Install t
			dw p_install_c, var_openslot_t

			; Main.bas 948: st(t) = 1
			dw kw_asetl, arr_st, var_openslot_t, 1

			; Main.bas 949: SetMode t, 1                    ' MODE S: 40 x 32 (console 36 + 4 status) on the Layer 2 bitmap
			dw p_setmode_c, var_openslot_t, lit_1

			; Main.bas 950: PutLn t, "CyborgOS slot " + N(t) + " of " + N(ns) + " - " + SK() + ", Control + ESC TOP, HELP"
			dw p_n_c, var_openslot_t
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcpy, stmp1, str22
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str23
			dw p_n_c, var_ns
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str24
			dw p_sk_c
			dw kw_strcpy, stmp2, var_sk_sk
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str25
			dw p_putln_c, var_openslot_t, stmp1

			; Main.bas 951: PutLn t, ""                     ' a blank line under the title
			dw p_putln_c, var_openslot_t, str0

			; Main.bas 952: Prompt t
			dw p_prompt_c, var_openslot_t
			dw p_openslot_r

ntc_rg32_e:
			IF ($ < 32768) && (ntc_rg33_e - ntc_rg33 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg33:
; ============================================================
; function sk (normal mode)
; ============================================================

p_sk:

			; Main.bas 957: If ns <= 9 Then
			dw kw_scplevl, var_ns, 9
			dw kw_goto_iffalse_n, if98_1

			; Main.bas 958: SK = "Control + 1-" + N(ns)
			dw p_n_c, var_ns
			dw kw_strcpy, stmp3, var_n_n
			dw kw_strcpy, var_sk_sk, str26
			dw kw_strcat, var_sk_sk, stmp3

			; Main.bas 959: ElseIf ns = 10 Then
			dw if98_e_go
if98_1:
			dw kw_cpeqvl, var_ns, 10
			dw kw_goto_iffalse_n, if98_2

			; Main.bas 960: SK = "Control + 1-9, 0"
			dw kw_strcpy, var_sk_sk, str27

			; Main.bas 961: ElseIf ns = 11 Then
			dw if98_e_go
if98_2:
			dw kw_cpeqvl, var_ns, 11
			dw kw_goto_iffalse_n, if98_3

			; Main.bas 962: SK = "Control + 1-9, 0 (twice 11)"
			dw kw_strcpy, var_sk_sk, str28

			; Main.bas 963: Else
			dw if98_e_go
if98_3:

			; Main.bas 964: SK = "Control + 1-9, 0 (twice 11-" + N(ns) + ")"
			dw p_n_c, var_ns
			dw kw_strcpy, stmp3, var_n_n
			dw kw_strcpy, stmp2, str29
			dw kw_strcat, stmp2, stmp3
			dw kw_strcpy, var_sk_sk, stmp2
			dw kw_strcat, var_sk_sk, str30

			; Main.bas 965: End If
if98_e:
			dw p_sk_r

ntc_rg33_e:
			IF ($ < 32768) && (ntc_rg34_e - ntc_rg34 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg34:
; ============================================================
; sub getnm (normal mode)
; ============================================================

p_getnm:

			; Main.bas 972: Dim n As Integer

			; Main.bas 973: n = Memory.ReadByte(Far(t, NMLEN))
			dw p_far_c, var_getnm_t, lit_m2344
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_getnm_n

			; Main.bas 974: en = Space$(12)
			dw kw_strspace, stmp0, lit_12
			dw kw_strcpy, var_en, stmp0

			; Main.bas 975: Memory.Copy Far(t, NMBUF), NearP(VarPtr(en)), n
			dw p_far_c, var_getnm_t, lit_m2343
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_var_en
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_getnm_n, var_memory_copy_copy

			; Main.bas 976: en = Left$(en, n)
			dw kw_strleft, stmp0, var_en, var_getnm_n
			dw kw_strcpy, var_en, stmp0
			dw p_getnm_r

ntc_rg34_e:
			IF ($ < 32768) && (ntc_rg35_e - ntc_rg35 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg35:
; ============================================================
; function n (normal mode)
; ============================================================

p_n:

			; Main.bas 980: N = Trim$(Str$(v))
			dw kw_strstr, stmp3, var_n_v
			dw kw_strtrim, var_n_n, stmp3
			dw p_n_r

ntc_rg35_e:
			IF ($ < 32768) && (ntc_rg36_e - ntc_rg36 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg36:
; ============================================================
; sub prompt (normal mode)
; ============================================================

p_prompt:

			; Main.bas 984: Memory.WriteByte Far(t, LNLEN), 0                ' an empty command line
			dw p_far_c, var_prompt_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 985: PutS t, N(t) + "> "
			dw p_n_c, var_prompt_t
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcat, stmp1, str31
			dw p_puts_c, var_prompt_t, stmp1
			dw p_prompt_r

ntc_rg36_e:
			IF ($ < 32768) && (ntc_rg37_e - ntc_rg37 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg37:
; ============================================================
; sub keyin (normal mode)
; ============================================================

p_keyin:

			; Main.bas 990: Dim t As Integer, n As Integer

			; Main.bas 991: If front = 0 Then
			dw kw_cpeqvl, var_front, 0
			dw kw_goto_iffalse_n, if99_1

			; Main.bas 992: Exit Sub                      ' TOP stays until Control + ESC or Control + a slot
			dw p_keyin_r

			; Main.bas 993: End If
if99_1:

			; Main.bas 994: t = front
			dw kw_vtov, var_front, var_keyin_t

			; Main.bas 998: If st(t) = 2 Then
			dw kw_aget, arr_st, var_keyin_t, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if100_1

			; Main.bas 999: If k = &HFC Then k = 27                       ' (ESC: the firmware's #FC - CP/M's #1B, as Amstrad's CP/M)
			dw kw_cpeqvl, var_keyin_k, 252
			dw kw_goto_iffalse_n, if101_1
			dw kw_ltov, 27, var_keyin_k
if101_1:

			; Main.bas 1000: kq(t) = k                                     ' the key into its bank: its BDOS answers from it
			dw kw_aset, arr_kq, var_keyin_t, var_keyin_k

			; Main.bas 1001: Memory.WriteByte Far(t, Hyp.KEY), k
			dw p_far_c, var_keyin_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_keyin_k

			; Main.bas 1002: Exit Sub
			dw p_keyin_r

			; Main.bas 1003: End If
if100_1:

			; Main.bas 1004: n = Memory.ReadByte(Far(t, LNLEN))             ' the command line so far (in the slot's bank)
			dw p_far_c, var_keyin_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_keyin_n

			; Main.bas 1005: If k = 13 Then
			dw kw_cpeqvl, var_keyin_k, 13
			dw kw_goto_iffalse_n, if102_1

			; Main.bas 1006: PutLn t, ""
			dw p_putln_c, var_keyin_t, str0

			; Main.bas 1007: Command t
			dw p_command_c, var_keyin_t

			; Main.bas 1008: If st(t) = 1 And wt = 0 And front = t Then Prompt t
			dw kw_aget, arr_st, var_keyin_t, tmp0
			dw kw_cpeqvl, tmp0, 1
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_wt, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_cpeqvv, var_front, var_keyin_t
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if102_e
			dw p_prompt_c, var_keyin_t
if103_1:

			; Main.bas 1009: ElseIf k = 127 Or k = 8 Then
			dw if102_e_go
if102_1:
			dw kw_cpeqvl, var_keyin_k, 127
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_keyin_k, 8
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if102_2

			; Main.bas 1010: If n > 0 Then
			dw kw_scpgtvl, var_keyin_n, 0
			dw kw_goto_iffalse_n, if102_e

			; Main.bas 1011: Memory.WriteByte Far(t, LNLEN), n - 1
			dw p_far_c, var_keyin_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_addl, var_keyin_n, -1, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 1012: PutC t, 8 : PutC t, 32 : PutC t, 8
			dw p_putc_c, var_keyin_t, lit_8
			dw p_putc_c, var_keyin_t, lit_32
			dw p_putc_c, var_keyin_t, lit_8

			; Main.bas 1013: End If
if104_1:

			; Main.bas 1014: ElseIf k >= 32 And k < 127 And n < 70 Then
			dw if102_e_go
if102_2:
			dw kw_scpgevl, var_keyin_k, 32
			dw kw_ftov, tmp0
			dw kw_scpltvl, var_keyin_k, 127
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_scpltvl, var_keyin_n, 70
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if102_3

			; Main.bas 1015: Memory.WriteByte Far(t, LNBUF + n), k
			dw kw_addl, var_keyin_n, -2416, tmp1
			dw p_far_c, var_keyin_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_keyin_k

			; Main.bas 1016: Memory.WriteByte Far(t, LNLEN), n + 1
			dw p_far_c, var_keyin_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_addl, var_keyin_n, 1, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 1017: PutC t, k
			dw p_putc_c, var_keyin_t, var_keyin_k

			; Main.bas 1018: End If
if102_3:
if102_e:
			dw p_keyin_r

ntc_rg37_e:
			IF ($ < 32768) && (ntc_rg38_e - ntc_rg38 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg38:
; ============================================================
; sub command (normal mode)
; ============================================================

p_command:

			; Main.bas 1022: Dim c As String Max 72, p As Integer, s As Integer

			; Main.bas 1023: p = Memory.ReadByte(Far(t, LNLEN))              ' the command line, from the slot's bank
			dw p_far_c, var_command_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_command_p

			; Main.bas 1024: Memory.Copy Far(t, LNBUF), NearP(VarPtr(ob)), p
			dw p_far_c, var_command_t, lit_m2416
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_var_ob
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_command_p, var_memory_copy_copy

			; Main.bas 1025: c = UCase$(Trim$(Left$(ob, p)))
			dw kw_strleft, stmp0, var_ob, var_command_p
			dw kw_strtrim, stmp0, stmp0
			dw kw_strucase, stmp0, stmp0
			dw kw_strcpy, var_command_c, stmp0

			; Main.bas 1026: a = "" : b = ""
			dw kw_strcpy, var_a, str0
			dw kw_strcpy, var_b, str0

			; Main.bas 1027: p = InStr(c, " ")
			dw kw_strinstr, lit_1, var_command_c, str16, var_command_p

			; Main.bas 1028: If p > 0 Then
			dw kw_scpgtvl, var_command_p, 0
			dw kw_goto_iffalse_n, if105_1

			; Main.bas 1029: a = Trim$(Mid$(c, p + 1))
			dw kw_addl, var_command_p, 1, tmp1
			dw kw_strmid, stmp0, var_command_c, tmp1, lit_255
			dw kw_strtrim, stmp0, stmp0
			dw kw_strcpy, var_a, stmp0

			; Main.bas 1030: c = Left$(c, p - 1)
			dw kw_addl, var_command_p, -1, tmp1
			dw kw_strleft, stmp0, var_command_c, tmp1
			dw kw_strcpy, var_command_c, stmp0

			; Main.bas 1031: End If
if105_1:

			; Main.bas 1032: p = InStr(a, " ")
			dw kw_strinstr, lit_1, var_a, str16, var_command_p

			; Main.bas 1033: If p > 0 Then
			dw kw_scpgtvl, var_command_p, 0
			dw kw_goto_iffalse_n, if106_1

			; Main.bas 1034: b = Trim$(Mid$(a, p + 1))
			dw kw_addl, var_command_p, 1, tmp1
			dw kw_strmid, stmp0, var_a, tmp1, lit_255
			dw kw_strtrim, stmp0, stmp0
			dw kw_strcpy, var_b, stmp0

			; Main.bas 1035: a = Left$(a, p - 1)
			dw kw_addl, var_command_p, -1, tmp1
			dw kw_strleft, stmp0, var_a, tmp1
			dw kw_strcpy, var_a, stmp0

			; Main.bas 1036: End If
if106_1:

			; Main.bas 1037: If Right$(c, 1) = ":" And a = "" Then a = c : c = "CV"   ' B: or IDE: alone: CV B:, CV IDE: (CV.CYB)
			dw kw_strright, stmp0, var_command_c, lit_1
			dw kw_strcmpeq, stmp0, str32
			dw kw_ftov, tmp0
			dw kw_strcmpeq, var_a, str0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if107_1
			dw kw_strcpy, var_a, var_command_c
			dw kw_strcpy, var_command_c, str33
if107_1:

			; Main.bas 1038: Select Case c
			dw kw_strcpy, var_command___sel108, var_command_c

			; Main.bas 1039: Case ""
			dw kw_strcmpeq, var_command___sel108, str0
			dw kw_goto_iffalse_n, sel108_1
sel108_b1:

			; Main.bas 1040: Case "CLS"
			dw sel108_e_go
sel108_1:
			dw kw_strcmpeq, var_command___sel108, str34
			dw kw_goto_iffalse_n, sel108_2
sel108_b2:

			; Main.bas 1041: ClsT t
			dw p_clst_c, var_command_t

			; Main.bas 1042: Case "RUN"                                 ' RUN [slot] name [tail]: the program on the disc even
			dw sel108_e_go
sel108_2:
			dw kw_strcmpeq, var_command___sel108, str35
			dw kw_goto_iffalse_n, sel108_3
sel108_b3:

			; Main.bas 1043: s = t                                    ' when a command has its name; with a slot: in that one
			dw kw_vtov, var_command_t, var_command_s

			; Main.bas 1044: If a <> "" And N(Val(a)) = a Then
			dw kw_strcmpne, var_a, str0
			dw kw_ftov, tmp0
			dw kw_strval, var_a, tmp1
			dw p_n_c, tmp1
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcmpeq, stmp1, var_a
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if109_1

			; Main.bas 1045: s = Val(a) : a = b : b = ""
			dw kw_strval, var_a, var_command_s
			dw kw_strcpy, var_a, var_b
			dw kw_strcpy, var_b, str0

			; Main.bas 1046: p = InStr(a, " ")
			dw kw_strinstr, lit_1, var_a, str16, var_command_p

			; Main.bas 1047: If p > 0 Then b = Trim$(Mid$(a, p + 1)) : a = Left$(a, p - 1)
			dw kw_scpgtvl, var_command_p, 0
			dw kw_goto_iffalse_n, if110_1
			dw kw_addl, var_command_p, 1, tmp1
			dw kw_strmid, stmp0, var_a, tmp1, lit_255
			dw kw_strtrim, stmp0, stmp0
			dw kw_strcpy, var_b, stmp0
			dw kw_addl, var_command_p, -1, tmp1
			dw kw_strleft, stmp0, var_a, tmp1
			dw kw_strcpy, var_a, stmp0
if110_1:

			; Main.bas 1048: End If
if109_1:

			; Main.bas 1049: If s < 1 Or s > ns Then PutLn t, "no slot" + Str$(s) : Exit Sub
			dw kw_scpltvl, var_command_s, 1
			dw kw_ftov, tmp0
			dw kw_scpgtvv, var_command_s, var_ns
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if111_1
			dw kw_strstr, stmp2, var_command_s
			dw kw_strcpy, stmp1, str36
			dw kw_strcat, stmp1, stmp2
			dw p_putln_c, var_command_t, stmp1
			dw p_command_r
if111_1:

			; Main.bas 1050: If st(s) = 2 Then PutLn t, "slot" + Str$(s) + " is busy" : Exit Sub
			dw kw_aget, arr_st, var_command_s, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if112_1
			dw kw_strstr, stmp2, var_command_s
			dw kw_strcpy, stmp1, str37
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str38
			dw p_putln_c, var_command_t, stmp1
			dw p_command_r
if112_1:

			; Main.bas 1051: StartTask t, s
			dw p_starttask_c, var_command_t, var_command_s

			; Main.bas 1052: Case "QUIT"
			dw sel108_e_go
sel108_3:
			dw kw_strcmpeq, var_command___sel108, str39
			dw kw_goto_iffalse_n, sel108_4
sel108_b4:

			; Main.bas 1053: quit = -1
			dw kw_ltov, -1, var_quit

			; Main.bas 1054: Case Else                                  ' the rest are programs (the system drive Z's, else
			dw sel108_e_go
sel108_4:

			; Main.bas 1055: b = Trim$(a + " " + b)                   ' the slot's drive, else A): PS, MEM, CD, DIR ... and
			dw kw_strcpy, stmp0, var_a
			dw kw_strcat, stmp0, str16
			dw kw_strcat, stmp0, var_b
			dw kw_strtrim, stmp0, stmp0
			dw kw_strcpy, var_b, stmp0

			; Main.bas 1056: a = c                                    ' any other, the rest of the line their tail
			dw kw_strcpy, var_a, var_command_c

			; Main.bas 1057: bare = -1
			dw kw_ltov, -1, var_bare

			; Main.bas 1058: StartTask t, t
			dw p_starttask_c, var_command_t, var_command_t

			; Main.bas 1059: bare = 0
			dw kw_ztov, var_bare

			; Main.bas 1060: End Select
sel108_e:
			dw p_command_r

ntc_rg38_e:
			IF ($ < 32768) && (ntc_rg39_e - ntc_rg39 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg39:
; ============================================================
; sub starttask (normal mode)
; ============================================================

p_starttask:

			; Main.bas 1068: Dim h As Integer, n As Integer, rest As Integer, com As Integer, w As String Max 72, d As Integer

			; Main.bas 1069: If a = "" Then PutLn t, "RUN what?" : Exit Sub
			dw kw_strcmpeq, var_a, str0
			dw kw_goto_iffalse_n, if113_1
			dw p_putln_c, var_starttask_t, str40
			dw p_starttask_r
if113_1:

			; Main.bas 1070: w = a
			dw kw_strcpy, var_starttask_w, var_a

			; Main.bas 1071: d = 0                                          ' the drive looked on: Z (-1, the system drive: the
			dw kw_ztov, var_starttask_d

			; Main.bas 1074: d = -1
			dw kw_ltov, -1, var_starttask_d

			; Main.bas 1076: Do
do114_t:

			; Main.bas 1079: If d = -1 Then
			dw kw_cpeqvl, var_starttask_d, -1
			dw kw_goto_iffalse_n, if115_1

			; Main.bas 1080: If Hyp.Drive(90) = 0 Then d = 0            ' (no system drive)
			dw p_hyp_drive_c, lit_90
			dw kw_vtov, var_hyp_drive_drive, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if116_1
			dw kw_ztov, var_starttask_d
if116_1:

			; Main.bas 1081: End If
if115_1:

			; Main.bas 1082: If d = 0 Then OwnDrive t
			dw kw_cpeqvl, var_starttask_d, 0
			dw kw_goto_iffalse_n, if117_1
			dw p_owndrive_c, var_starttask_t
if117_1:

			; Main.bas 1083: If d = 1 Then n = Hyp.Drive(bd)
			dw kw_cpeqvl, var_starttask_d, 1
			dw kw_goto_iffalse_n, if118_1
			dw p_hyp_drive_c, var_bd
			dw kw_vtov, var_hyp_drive_drive, var_starttask_n
if118_1:

			; Main.bas 1085: a = w : h = 0 : com = 0
			dw kw_strcpy, var_a, var_starttask_w
			dw kw_ztov, var_starttask_h
			dw kw_ztov, var_starttask_com

			; Main.bas 1086: If InStr(a, ".") = 0 Then
			dw kw_strinstr, lit_1, var_a, str41, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if119_1

			; Main.bas 1087: dn = a + ".CYB"
			dw kw_strcpy, var_dn, var_a
			dw kw_strcat, var_dn, str42

			; Main.bas 1088: h = HOpen()
			dw p_hopen_c
			dw kw_vtov, var_hopen_hopen, var_starttask_h

			; Main.bas 1089: If h Then a = dn Else com = -1
			dw kw_goto_ifzero_n, var_starttask_h, if120_1
			dw kw_strcpy, var_a, var_dn
			dw if119_e_go
if120_1:
			dw kw_ltov, -1, var_starttask_com
if120_e:

			; Main.bas 1090: ElseIf Right$(a, 4) = ".COM" Then
			dw if119_e_go
if119_1:
			dw kw_strright, stmp0, var_a, lit_4
			dw kw_strcmpeq, stmp0, str43
			dw kw_goto_iffalse_n, if119_2

			; Main.bas 1091: com = -1
			dw kw_ltov, -1, var_starttask_com

			; Main.bas 1092: Else
			dw if119_e_go
if119_2:

			; Main.bas 1093: dn = a
			dw kw_strcpy, var_dn, var_a

			; Main.bas 1094: h = HOpen()
			dw p_hopen_c
			dw kw_vtov, var_hopen_hopen, var_starttask_h

			; Main.bas 1095: End If
if119_e:

			; Main.bas 1096: rest = &HEE00                                ' #0100 to the stub (#EF00)
			dw kw_ltov, -4608, var_starttask_rest

			; Main.bas 1097: If com Then dn = a : h = HOpen()             ' (a .COM: UniDOS, a RAM disc read it to its end)
			dw kw_goto_ifzero_n, var_starttask_com, if121_1
			dw kw_strcpy, var_dn, var_a
			dw p_hopen_c
			dw kw_vtov, var_hopen_hopen, var_starttask_h
if121_1:

			; Main.bas 1098: If h Then Exit Do
			dw kw_goto_ifzero_n, var_starttask_h, if122_1
			dw do114_e_go
if122_1:

			; Main.bas 1102: If d = 1 Or (d = 0 And dv(t) = bd) Then Exit Do   ' not on Z nor the slot's drive: the boot drive
			dw kw_cpeqvl, var_starttask_d, 1
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_starttask_d, 0
			dw kw_ftov, tmp1
			dw kw_aget, arr_dv, var_starttask_t, tmp2
			dw kw_cpeqvv, tmp2, var_bd
			dw kw_ftov, tmp2
			dw kw_andvv, tmp1, tmp2, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if123_1
			dw do114_e_go
if123_1:

			; Main.bas 1103: d = d + 1
			dw kw_inc, var_starttask_d

			; Main.bas 1105: Loop
			dw do114_t_go
do114_e:

			; Main.bas 1106: If h = 0 Then
			dw kw_cpeqvl, var_starttask_h, 0
			dw kw_goto_iffalse_n, if124_1

			; Main.bas 1107: a = w
			dw kw_strcpy, var_a, var_starttask_w

			; Main.bas 1110: OwnDrive t
			dw p_owndrive_c, var_starttask_t

			; Main.bas 1112: NotFound t
			dw p_notfound_c, var_starttask_t

			; Main.bas 1113: Exit Sub
			dw p_starttask_r

			; Main.bas 1114: End If
if124_1:

			; Main.bas 1115: If st(s) = 0 Then OpenSlot s
			dw kw_aget, arr_st, var_starttask_s, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if125_1
			dw p_openslot_c, var_starttask_s
if125_1:

			; Main.bas 1116: If s <> t Then PutLn s, "RUN " + a
			dw kw_cpnevv, var_starttask_s, var_starttask_t
			dw kw_goto_iffalse_n, if126_1
			dw kw_strcpy, stmp1, str44
			dw kw_strcat, stmp1, var_a
			dw p_putln_c, var_starttask_s, stmp1
if126_1:

			; Main.bas 1117: Install s
			dw p_install_c, var_starttask_s

			; Main.bas 1118: n = Hyp.FileCall(103, rest, s, sg(s), &H100, 0, VarPtr(rb))  ' at #0100, rest bytes at most
			dw kw_aget, arr_sg, var_starttask_s, tmp3
			dw p_hyp_filecall_c, lit_103, var_starttask_rest, var_starttask_s, tmp3, lit_256, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_starttask_n

			; Main.bas 1119: HClose
			dw p_hclose_c

			; Main.bas 1122: If d <> 0 Then OwnDrive t                      ' (loaded from Z or A: the slot's drive again)
			dw kw_cpnevl, var_starttask_d, 0
			dw kw_goto_iffalse_n, if127_1
			dw p_owndrive_c, var_starttask_t
if127_1:

			; Main.bas 1127: Memory.WriteWord Far(s, &HF2FC), Hyp.Info(4)
			dw p_far_c, var_starttask_s, lit_m3332
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_hyp_info, lit_4, var_hyp_info_info
			dw kw_vtov, var_hyp_info_info, tmp1
			dw fn_memory_writeword, ltmp0, tmp1

			; Main.bas 1128: Memory.WriteWord Far(s, &HF2FE), 0
			dw p_far_c, var_starttask_s, lit_m3330
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, lit_0

			; Main.bas 1129: Memory.WriteWord Far(s, &HFFFE), &HF2FC
			dw p_far_c, var_starttask_s, lit_m2
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, lit_m3332

			; Main.bas 1131: If b = "" Then
			dw kw_strcmpeq, var_b, str0
			dw kw_goto_iffalse_n, if128_1

			; Main.bas 1132: Memory.WriteByte Far(s, &H80), 0
			dw p_far_c, var_starttask_s, lit_128
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 1133: Else
			dw if128_e_go
if128_1:

			; Main.bas 1134: b = " " + b
			dw kw_strcpy, stmp0, str16
			dw kw_strcat, stmp0, var_b
			dw kw_strcpy, var_b, stmp0

			; Main.bas 1135: Memory.Copy NearP(VarPtr(b)), Far(s, &H81), Len(b)
			dw p_nearp_c, vp_var_b
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_starttask_s, lit_129
			dw kw_l_mov, var_far_far, ltmp1
			dw kw_strlen, var_b, tmp2
			dw fn_memory_copy, ltmp0, ltmp1, tmp2, var_memory_copy_copy

			; Main.bas 1136: Memory.WriteByte Far(s, &H80), Len(b)
			dw p_far_c, var_starttask_s, lit_128
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_strlen, var_b, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 1137: Memory.WriteByte Far(s, &H81 + Len(b)), 0
			dw kw_strlen, var_b, tmp2
			dw kw_addl, tmp2, 129, tmp1
			dw p_far_c, var_starttask_s, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 1138: End If
if128_e:

			; Main.bas 1139: Memory.WriteByte Far(s, NMLEN), Len(a)
			dw p_far_c, var_starttask_s, lit_m2344
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_strlen, var_a, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 1140: Memory.Copy NearP(VarPtr(a)), Far(s, NMBUF), Len(a)
			dw p_nearp_c, vp_var_a
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_starttask_s, lit_m2343
			dw kw_l_mov, var_far_far, ltmp1
			dw kw_strlen, var_a, tmp2
			dw fn_memory_copy, ltmp0, ltmp1, tmp2, var_memory_copy_copy

			; Main.bas 1141: kq(s) = 0
			dw kw_asetl, arr_kq, var_starttask_s, 0

			; Main.bas 1142: Memory.WriteByte Far(s, &HF685), 0             ' no escape sequence rest half done
			dw p_far_c, var_starttask_s, lit_m2427
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 1143: wk(s) = -1
			dw kw_asetl, arr_wk, var_starttask_s, -1

			; Main.bas 1144: dm(s) = &H80                                   ' CP/M's record buffer to start with
			dw kw_asetl, arr_dm, var_starttask_s, 128

			; Main.bas 1145: st(s) = 2
			dw kw_asetl, arr_st, var_starttask_s, 2

			; Main.bas 1146: If s <> t Then PutLn t, a + " runs in slot" + Str$(s)
			dw kw_cpnevv, var_starttask_s, var_starttask_t
			dw kw_goto_iffalse_n, if129_1
			dw kw_strcpy, stmp1, var_a
			dw kw_strcat, stmp1, str45
			dw kw_strstr, stmp2, var_starttask_s
			dw kw_strcat, stmp1, stmp2
			dw p_putln_c, var_starttask_t, stmp1
if129_1:
			dw p_starttask_r

ntc_rg39_e:
			IF ($ < 32768) && (ntc_rg40_e - ntc_rg40 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg40:
; ============================================================
; sub notfound (normal mode)
; ============================================================

p_notfound:

			; Main.bas 1150: If bare Then PutLn t, "? " + a + " (HELP)" Else PutLn t, a + ": not found"
			dw kw_goto_ifzero_n, var_bare, if130_1
			dw kw_strcpy, stmp1, str46
			dw kw_strcat, stmp1, var_a
			dw kw_strcat, stmp1, str47
			dw p_putln_c, var_notfound_t, stmp1
			dw if130_e_go
if130_1:
			dw kw_strcpy, stmp1, var_a
			dw kw_strcat, stmp1, str48
			dw p_putln_c, var_notfound_t, stmp1
if130_e:
			dw p_notfound_r

ntc_rg40_e:
			IF ($ < 32768) && (ntc_rg41_e - ntc_rg41 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg41:
; ============================================================
; sub owndrive (normal mode)
; ============================================================

p_owndrive:

			; Main.bas 1157: Dim r As Integer

			; Main.bas 1158: If dv(t) = 0 Then dv(t) = bd
			dw kw_aget, arr_dv, var_owndrive_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if131_1
			dw kw_aset, arr_dv, var_owndrive_t, var_bd
if131_1:

			; Main.bas 1159: r = Hyp.Drive(dv(t))
			dw kw_aget, arr_dv, var_owndrive_t, tmp0
			dw p_hyp_drive_c, tmp0
			dw kw_vtov, var_hyp_drive_drive, var_owndrive_r
			dw p_owndrive_r

ntc_rg41_e:
			IF ($ < 32768) && (ntc_rg42_e - ntc_rg42 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg42:
; ============================================================
; sub endtask (normal mode)
; ============================================================

p_endtask:

			; Main.bas 1164: Dim c As Integer

			; Main.bas 1165: FilesShut t
			dw p_filesshut_c, var_endtask_t

			; Main.bas 1168: StoreFree t
			dw p_storefree_c, var_endtask_t

			; Main.bas 1170: st(t) = 1
			dw kw_asetl, arr_st, var_endtask_t, 1

			; Main.bas 1171: runs = runs + 1
			dw kw_inc, var_runs

			; Main.bas 1172: PutLn t, ""
			dw p_putln_c, var_endtask_t, str0

			; Main.bas 1173: GetNm t
			dw p_getnm_c, var_endtask_t

			; Main.bas 1174: PutLn t, "[" + en + " ended]"
			dw kw_strcpy, stmp1, str6
			dw kw_strcat, stmp1, var_en
			dw kw_strcat, stmp1, str49
			dw p_putln_c, var_endtask_t, stmp1

			; Main.bas 1175: If wt <> t Then Prompt t                       ' (WAIT: the prompt when nothing runs)
			dw kw_cpnevv, var_wt, var_endtask_t
			dw kw_goto_iffalse_n, if132_1
			dw p_prompt_c, var_endtask_t
if132_1:

			; Main.bas 1176: c = kq(t) : kq(t) = 0
			dw kw_aget, arr_kq, var_endtask_t, var_endtask_c
			dw kw_asetl, arr_kq, var_endtask_t, 0

			; Main.bas 1177: If c <> 0 And t = front Then pk = c    ' a key typed for it after its last look: the command line's
			dw kw_cpnevl, var_endtask_c, 0
			dw kw_ftov, tmp0
			dw kw_cpeqvv, var_endtask_t, var_front
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if133_1
			dw kw_vtov, var_endtask_c, var_pk
if133_1:
			dw p_endtask_r

ntc_rg42_e:
			IF ($ < 32768) && (ntc_rg43_e - ntc_rg43 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg43:
; ============================================================
; sub usedriver (normal mode)
; ============================================================

p_hyp_usedriver:

			; Hyp.cls 61: dxb = b
			dw kw_vtov, var_hyp_usedriver_b, var_hyp_dxb

			; Hyp.cls 62: #asm
			dw asm_1_62_n
			dw p_hyp_usedriver_r

ntc_rg43_e:
			IF ($ < 32768) && (ntc_rg44_e - ntc_rg44 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg44:
; ============================================================
; sub con (normal mode)
; ============================================================

p_hyp_con:

			; Hyp.cls 395: #asm
			dw asm_1_395_n
			dw p_hyp_con_r

ntc_rg44_e:
			IF ($ < 32768) && (ntc_rg45_e - ntc_rg45 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg45:
; ============================================================
; sub say (normal mode)
; ============================================================

p_hyp_say:

			; Hyp.cls 1694: #asm
			dw asm_1_1694_n
			dw p_hyp_say_r

ntc_rg45_e:
			IF ($ < 32768) && (ntc_rg46_e - ntc_rg46 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg46:
; ============================================================
; function scr (normal mode)
; ============================================================

p_hyp_scr:

			; Hyp.cls 1788: #asm
			dw asm_1_1788_n
			dw p_hyp_scr_r

ntc_rg46_e:
			IF ($ < 32768) && (ntc_rg47_e - ntc_rg47 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg47:
; ============================================================
; sub keyrep (normal mode)
; ============================================================

p_hyp_keyrep:

			; Hyp.cls 1904: #asm
			dw asm_1_1904_n
			dw p_hyp_keyrep_r

ntc_rg47_e:
			IF ($ < 32768) && (ntc_rg48_e - ntc_rg48 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg48:
; ============================================================
; sub show (normal mode)
; ============================================================

p_hyp_show:

			; Hyp.cls 1947: Con pg, 0, -1, 1
			dw p_hyp_con_c, var_hyp_show_pg, lit_0, lit_m1, lit_1
			dw p_hyp_show_r

ntc_rg48_e:
			IF ($ < 32768) && (ntc_rg49_e - ntc_rg49 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg49:
; ============================================================
; sub reply (normal mode)
; ============================================================

p_hyp_reply:

			; Hyp.cls 1953: ra = a : rhl = hl
			dw kw_vtov, var_hyp_reply_a, var_hyp_ra
			dw kw_vtov, var_hyp_reply_hl, var_hyp_rhl
			dw p_hyp_reply_r

ntc_rg49_e:
			IF ($ < 32768) && (ntc_rg50_e - ntc_rg50 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg50:
; ============================================================
; function fn (normal mode)
; ============================================================

p_hyp_fn:

			; Hyp.cls 1957: Fn = rfn And 255
			dw kw_andvl, var_hyp_rfn, 255, var_hyp_fn_fn
			dw p_hyp_fn_r

ntc_rg50_e:
			IF ($ < 32768) && (ntc_rg51_e - ntc_rg51 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg51:
; ============================================================
; function arg (normal mode)
; ============================================================

p_hyp_arg:

			; Hyp.cls 1961: Arg = rde
			dw kw_vtov, var_hyp_rde, var_hyp_arg_arg
			dw p_hyp_arg_r

ntc_rg51_e:
			IF ($ < 32768) && (ntc_rg52_e - ntc_rg52 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg52:
; ============================================================
; function count (normal mode)
; ============================================================

p_hyp_count:

			; Hyp.cls 1966: Count = rcnt
			dw kw_vtov, var_hyp_rcnt, var_hyp_count_count
			dw p_hyp_count_r

ntc_rg52_e:
			IF ($ < 32768) && (ntc_rg53_e - ntc_rg53 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg53:
; ============================================================
; function run (normal mode)
; ============================================================

p_hyp_run:

			; Hyp.cls 1971: #asm
			dw asm_1_1971_n
			dw p_hyp_run_r

ntc_rg53_e:
			IF ($ < 32768) && (ntc_rg54_e - ntc_rg54 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg54:
; ============================================================
; sub vdu (normal mode)
; ============================================================

p_hyp_vdu:

			; Hyp.cls 2736: #asm
			dw asm_1_2736_n
			dw p_hyp_vdu_r

ntc_rg54_e:
			IF ($ < 32768) && (ntc_rg55_e - ntc_rg55 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg55:
; ============================================================
; function filecall (normal mode)
; ============================================================

p_hyp_filecall:

			; Hyp.cls 2771: #asm
			dw asm_1_2771_n
			dw p_hyp_filecall_r

ntc_rg55_e:
			IF ($ < 32768) && (ntc_rg56_e - ntc_rg56 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg56:
; ============================================================
; sub fileshut (normal mode)
; ============================================================

p_hyp_fileshut:

			; Hyp.cls 4357: #asm
			dw asm_1_4357_n
			dw p_hyp_fileshut_r

ntc_rg56_e:
			IF ($ < 32768) && (ntc_rg57_e - ntc_rg57 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg57:
; ============================================================
; sub svcvars (normal mode)
; ============================================================

p_hyp_svcvars:

			; Hyp.cls 4417: svst = vst : svsg = vsg : svns = vns : svfr = vfr : svdp = vdp
			dw kw_vtov, var_hyp_svcvars_vst, var_hyp_svst
			dw kw_vtov, var_hyp_svcvars_vsg, var_hyp_svsg
			dw kw_vtov, var_hyp_svcvars_vns, var_hyp_svns
			dw kw_vtov, var_hyp_svcvars_vfr, var_hyp_svfr
			dw kw_vtov, var_hyp_svcvars_vdp, var_hyp_svdp
			dw p_hyp_svcvars_r

ntc_rg57_e:
			IF ($ < 32768) && (ntc_rg58_e - ntc_rg58 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg58:
; ============================================================
; function svc (normal mode)
; ============================================================

p_hyp_svc:

			; Hyp.cls 4424: #asm
			dw asm_1_4424_n
			dw p_hyp_svc_r

ntc_rg58_e:
			IF ($ < 32768) && (ntc_rg59_e - ntc_rg59 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg59:
; ============================================================
; function drive (normal mode)
; ============================================================

p_hyp_drive:

			; Hyp.cls 6156: #asm
			dw asm_1_6156_n
			dw p_hyp_drive_r

ntc_rg59_e:
			IF ($ < 32768) && (ntc_rg60_e - ntc_rg60 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg60:
; ============================================================
; sub speed (normal mode)
; ============================================================

p_hot_speed:

			; Hot.cls 19: If f < 1 Then f = 1
			dw kw_scpltvl, var_hot_speed_f, 1
			dw kw_goto_iffalse_n, if134_1
			dw kw_ltov, 1, var_hot_speed_f
if134_1:

			; Hot.cls 20: If f > 40 Then f = 40
			dw kw_scpgtvl, var_hot_speed_f, 40
			dw kw_goto_iffalse_n, if135_1
			dw kw_ltov, 40, var_hot_speed_f
if135_1:

			; Hot.cls 21: dbl = DOUBLE * f
			dw kw_mulvl, var_hot_speed_f, 15, var_hot_dbl
			dw p_hot_speed_r

ntc_rg60_e:
			IF ($ < 32768) && (ntc_rg61_e - ntc_rg61 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg61:
; ============================================================
; sub slots (normal mode)
; ============================================================

p_hot_slots:

			; Hot.cls 25: ns = n
			dw kw_vtov, var_hot_slots_n, var_hot_ns
			dw p_hot_slots_r

ntc_rg61_e:
			IF ($ < 32768) && (ntc_rg62_e - ntc_rg62 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg62:
; ============================================================
; sub tick (normal mode)
; ============================================================

p_hot_tick:

			; Hot.cls 29: Dim k As Integer

			; Hot.cls 31: ctl = 0                               ' control-key scanning parked while the boot path is stabilised
			dw kw_ztov, var_hot_ctl

			; Hot.cls 48: If k <> 0 And k <> last Then
			dw kw_cpnevl, var_hot_tick_k, 0
			dw kw_ftov, tmp6
			dw kw_cpnevv, var_hot_tick_k, var_hot_last
			dw kw_ftov, tmp7
			dw kw_andvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if136_1

			; Hot.cls 49: If k = TOPKEY Or ns <= 10 Then
			dw kw_cpeqvl, var_hot_tick_k, 99
			dw kw_ftov, tmp6
			dw kw_scplevl, var_hot_ns, 10
			dw kw_ftov, tmp7
			dw kw_orvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if137_1

			; Hot.cls 50: If one <> 0 Then one = 0
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if138_1
			dw kw_ztov, var_hot_one
if138_1:

			; Hot.cls 51: pend = k                          ' at once (no double taps to wait for)
			dw kw_vtov, var_hot_tick_k, var_hot_pend

			; Hot.cls 52: ElseIf one = k Then
			dw if137_e_go
if137_1:
			dw kw_cpeqvv, var_hot_one, var_hot_tick_k
			dw kw_goto_iffalse_n, if137_2

			; Hot.cls 53: one = 0
			dw kw_ztov, var_hot_one

			; Hot.cls 54: If k + 10 <= ns Then pend = k + 10 Else pend = k  ' the second press: slot 11-20
			dw kw_addl, var_hot_tick_k, 10, tmp6
			dw kw_scplevv, tmp6, var_hot_ns
			dw kw_goto_iffalse_n, if139_1
			dw kw_addl, var_hot_tick_k, 10, var_hot_pend
			dw if137_e_go
if139_1:
			dw kw_vtov, var_hot_tick_k, var_hot_pend
if139_e:

			; Hot.cls 55: Else
			dw if137_e_go
if137_2:

			; Hot.cls 56: If one <> 0 Then pend = one       ' another number: the waiting one counts now
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if140_1
			dw kw_vtov, var_hot_one, var_hot_pend
if140_1:

			; Hot.cls 57: one = k : age = 0
			dw kw_vtov, var_hot_tick_k, var_hot_one
			dw kw_ztov, var_hot_age

			; Hot.cls 58: End If
if137_e:

			; Hot.cls 59: End If
if136_1:

			; Hot.cls 60: If one <> 0 Then
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if141_1

			; Hot.cls 61: age = age + 1
			dw kw_inc, var_hot_age

			; Hot.cls 62: If dbl = 0 Then dbl = DOUBLE
			dw kw_cpeqvl, var_hot_dbl, 0
			dw kw_goto_iffalse_n, if142_1
			dw kw_ltov, 15, var_hot_dbl
if142_1:

			; Hot.cls 63: If age > dbl Or ctl = 0 Then pend = one : one = 0       ' no second press (or Control let go)
			dw kw_scpgtvv, var_hot_age, var_hot_dbl
			dw kw_ftov, tmp6
			dw kw_cpeqvl, var_hot_ctl, 0
			dw kw_ftov, tmp7
			dw kw_orvv, tmp6, tmp7, tmp6
			dw kw_goto_ifzero_n, tmp6, if143_1
			dw kw_vtov, var_hot_one, var_hot_pend
			dw kw_ztov, var_hot_one
if143_1:

			; Hot.cls 64: End If
if141_1:

			; Hot.cls 65: last = k
			dw kw_vtov, var_hot_tick_k, var_hot_last
			dw p_hot_tick_r

ntc_rg62_e:
			IF ($ < 32768) && (ntc_rg63_e - ntc_rg63 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg63:
; ============================================================
; function take (normal mode)
; ============================================================

p_hot_take:

			; Hot.cls 69: Take = pend
			dw kw_vtov, var_hot_pend, var_hot_take_take

			; Hot.cls 70: pend = 0
			dw kw_ztov, var_hot_pend
			dw p_hot_take_r

ntc_rg63_e:
			IF ($ < 32768) && (ntc_rg64_e - ntc_rg64 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg64:
; ============================================================
; function control (normal mode)
; ============================================================

p_hot_control:

			; Hot.cls 75: Control = ctl
			dw kw_vtov, var_hot_ctl, var_hot_control_control
			dw p_hot_control_r

ntc_rg64_e:
			IF ($ < 32768) && (ntc_rg65_e - ntc_rg65 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg65:
; ============================================================
; function held (normal mode)
; ============================================================

p_hot_held:

			; Hot.cls 81: Held = last
			dw kw_vtov, var_hot_last, var_hot_held_held
			dw p_hot_held_r

ntc_rg65_e:
			IF ($ < 32768) && (ntc_rg66_e - ntc_rg66 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg66:
; ============================================================
; function bankpage (normal mode)
; ============================================================

p_memory_bankpage:

			; Memory.cls 449: BankPage = 4 * bank - 2 + n
			dw kw_4x, var_memory_bankpage_bank, tmp2
			dw kw_addl, tmp2, -2, tmp2
			dw kw_add, tmp2, var_memory_bankpage_n, var_memory_bankpage_bankpage
			dw p_memory_bankpage_r

; ============================================================
; Jump stubs (code, ROMable)
;   label_go: GOTO label
;   label_gs: GOSUB label, return point -> label_rs (RAM)
;   label_rt: RETURN from label
;   p_name_c: call a procedure, p_name_r: end of it
;   turbo mode ends with ret, normal mode with jp ntc_xn
; ============================================================

do5_t_go:			ld sp, do5_t
			jp ntc_xn
if10_e_go:			ld sp, if10_e
			jp ntc_xn
if12_e_go:			ld sp, if12_e
			jp ntc_xn
for28_e_go:			ld sp, for28_e
			jp ntc_xn
do36_e_go:			ld sp, do36_e
			jp ntc_xn
do36_t_go:			ld sp, do36_t
			jp ntc_xn
sel45_e_go:			ld sp, sel45_e
			jp ntc_xn
if59_e_go:			ld sp, if59_e
			jp ntc_xn
ch76_e_go:			ld sp, ch76_e
			jp ntc_xn
if75_e_go:			ld sp, if75_e
			jp ntc_xn
ch80_e_go:			ld sp, ch80_e
			jp ntc_xn
ch81_e_go:			ld sp, ch81_e
			jp ntc_xn
ch82_e_go:			ld sp, ch82_e
			jp ntc_xn
if87_e_go:			ld sp, if87_e
			jp ntc_xn
if89_e_go:			ld sp, if89_e
			jp ntc_xn
ch91_e_go:			ld sp, ch91_e
			jp ntc_xn
if92_e_go:			ld sp, if92_e
			jp ntc_xn
if94_e_go:			ld sp, if94_e
			jp ntc_xn
if98_e_go:			ld sp, if98_e
			jp ntc_xn
if102_e_go:			ld sp, if102_e
			jp ntc_xn
sel108_e_go:			ld sp, sel108_e
			jp ntc_xn
if119_e_go:			ld sp, if119_e
			jp ntc_xn
do114_e_go:			ld sp, do114_e
			jp ntc_xn
do114_t_go:			ld sp, do114_t
			jp ntc_xn
if128_e_go:			ld sp, if128_e
			jp ntc_xn
if130_e_go:			ld sp, if130_e
			jp ntc_xn
if137_e_go:			ld sp, if137_e
			jp ntc_xn

p_running_c:		; call running (normal)
			ld hl, 0
			ld (var_running_running), hl
			ld hl, 0
			ld (var_running_j), hl
			ld (p_running_rs), sp
			ld sp, p_running
			jp ntc_xn
p_running_r:		; end of running
			ld sp, (p_running_rs)
			jp ntc_xn
p_ready_c:		; call ready (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_ready_t), de
			ld hl, 0
			ld (var_ready_ready), hl
			ld (p_ready_rs), sp
			ld sp, p_ready
			jp ntc_xn
p_ready_r:		; end of ready
			ld sp, (p_ready_rs)
			jp ntc_xn
p_runnext_c:		; call runnext (normal)
			ld hl, 0
			ld (var_runnext_n), hl
			ld hl, 0
			ld (var_runnext_t), hl
			ld hl, 0
			ld (var_runnext_r), hl
			ld hl, 0
			ld (var_runnext_c), hl
			ld hl, 0
			ld (var_runnext_q), hl
			ld (p_runnext_rs), sp
			ld sp, p_runnext
			jp ntc_xn
p_runnext_r:		; end of runnext
			ld sp, (p_runnext_rs)
			jp ntc_xn
p_bdos_c:		; call bdos (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_bdos_t), de
			ld hl, 0
			ld (var_bdos_f), hl
			ld hl, 0
			ld (var_bdos_e), hl
			ld hl, 0
			ld (var_bdos_a), hl
			ld (p_bdos_rs), sp
			ld sp, p_bdos
			jp ntc_xn
p_bdos_r:		; end of bdos
			ld sp, (p_bdos_rs)
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
p_storefree_c:		; call storefree (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_storefree_t), de
			ld hl, 0
			ld (var_storefree_r), hl
			ld (p_storefree_rs), sp
			ld sp, p_storefree
			jp ntc_xn
p_storefree_r:		; end of storefree
			ld sp, (p_storefree_rs)
			jp ntc_xn
p_sys_c:		; call sys (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_sys_t), de
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_sys_p), de
			ld hl, 0
			ld (var_sys_sys), hl
			ld hl, 0
			ld (var_sys_o), hl
			ld hl, 0
			ld (var_sys_s), hl
			ld hl, 0
			ld (var_sys_d), hl
			ld (p_sys_rs), sp
			ld sp, p_sys
			jp ntc_xn
p_sys_r:		; end of sys
			ld sp, (p_sys_rs)
			jp ntc_xn
p_puten_c:		; call puten (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_puten_t), de
			pop hl			; a
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_puten_a), de
			ld (p_puten_rs), sp
			ld sp, p_puten
			jp ntc_xn
p_puten_r:		; end of puten
			ld sp, (p_puten_rs)
			jp ntc_xn
p_hopen_c:		; call hopen (normal)
			ld hl, 0
			ld (var_hopen_hopen), hl
			ld (p_hopen_rs), sp
			ld sp, p_hopen
			jp ntc_xn
p_hopen_r:		; end of hopen
			ld sp, (p_hopen_rs)
			jp ntc_xn
p_hclose_c:		; call hclose (normal)
			ld hl, 0
			ld (var_hclose_r), hl
			ld (p_hclose_rs), sp
			ld sp, p_hclose
			jp ntc_xn
p_hclose_r:		; end of hclose
			ld sp, (p_hclose_rs)
			jp ntc_xn
p_filesshut_c:		; call filesshut (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_filesshut_t), de
			ld hl, 0
			ld (var_filesshut_r), hl
			ld (p_filesshut_rs), sp
			ld sp, p_filesshut
			jp ntc_xn
p_filesshut_r:		; end of filesshut
			ld sp, (p_filesshut_rs)
			jp ntc_xn
p_collected_c:		; call collected (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_collected_t), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_collected_n), de
			ld (p_collected_rs), sp
			ld sp, p_collected
			jp ntc_xn
p_collected_r:		; end of collected
			ld sp, (p_collected_rs)
			jp ntc_xn
p_puts_c:		; call puts (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_puts_t), de
			pop hl			; s
			ld de, var_puts_s
			ld b, 82
p_puts_si1:
			ld a, (hl)
			ld (de), a
			or a
			jr z, p_puts_si1_e
			inc hl
			inc de
			djnz p_puts_si1
			xor a
			ld (de), a
p_puts_si1_e:
			ld (p_puts_rs), sp
			ld sp, p_puts
			jp ntc_xn
p_puts_r:		; end of puts
			ld sp, (p_puts_rs)
			jp ntc_xn
p_putln_c:		; call putln (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_putln_t), de
			pop hl			; s
			ld de, var_putln_s
			ld b, 82
p_putln_si1:
			ld a, (hl)
			ld (de), a
			or a
			jr z, p_putln_si1_e
			inc hl
			inc de
			djnz p_putln_si1
			xor a
			ld (de), a
p_putln_si1_e:
			ld (p_putln_rs), sp
			ld sp, p_putln
			jp ntc_xn
p_putln_r:		; end of putln
			ld sp, (p_putln_rs)
			jp ntc_xn
p_putc_c:		; call putc (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_putc_t), de
			pop hl			; c
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_putc_c), de
			ld (p_putc_rs), sp
			ld sp, p_putc
			jp ntc_xn
p_putc_r:		; end of putc
			ld sp, (p_putc_rs)
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
p_clst_c:		; call clst (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_clst_t), de
			ld (p_clst_rs), sp
			ld sp, p_clst
			jp ntc_xn
p_clst_r:		; end of clst
			ld sp, (p_clst_rs)
			jp ntc_xn
p_tofront_c:		; call tofront (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_tofront_t), de
			ld hl, 0
			ld (var_tofront_r), hl
			ld (p_tofront_rs), sp
			ld sp, p_tofront
			jp ntc_xn
p_tofront_r:		; end of tofront
			ld sp, (p_tofront_rs)
			jp ntc_xn
p_setmode_c:		; call setmode (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_setmode_t), de
			pop hl			; m
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_setmode_m), de
			ld hl, 0
			ld (var_setmode_r), hl
			ld (p_setmode_rs), sp
			ld sp, p_setmode
			jp ntc_xn
p_setmode_r:		; end of setmode
			ld sp, (p_setmode_rs)
			jp ntc_xn
p_showtop_c:		; call showtop (normal)
			ld hl, 0
			ld (var_showtop_j), hl
			ld (p_showtop_rs), sp
			ld sp, p_showtop
			jp ntc_xn
p_showtop_r:		; end of showtop
			ld sp, (p_showtop_rs)
			jp ntc_xn
p_toplines_c:		; call toplines (normal)
			pop hl			; mark
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_toplines_mark), de
			pop hl			; keys
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_toplines_keys), de
			ld hl, 0
			ld (var_toplines_j), hl
			xor a
			ld (var_toplines_s), a
			ld (p_toplines_rs), sp
			ld sp, p_toplines
			jp ntc_xn
p_toplines_r:		; end of toplines
			ld sp, (p_toplines_rs)
			jp ntc_xn
p_totals_c:		; call totals (normal)
			ld (p_totals_rs), sp
			ld sp, p_totals
			jp ntc_xn
p_totals_r:		; end of totals
			ld sp, (p_totals_rs)
			jp ntc_xn
p_topadd_c:		; call topadd (normal)
			pop hl			; s
			ld de, var_topadd_s
			ld b, 82
p_topadd_si0:
			ld a, (hl)
			ld (de), a
			or a
			jr z, p_topadd_si0_e
			inc hl
			inc de
			djnz p_topadd_si0
			xor a
			ld (de), a
p_topadd_si0_e:
			ld (p_topadd_rs), sp
			ld sp, p_topadd
			jp ntc_xn
p_topadd_r:		; end of topadd
			ld sp, (p_topadd_rs)
			jp ntc_xn
p_roll_c:		; call roll (normal)
			ld hl, 0
			ld (var_roll_j), hl
			ld (p_roll_rs), sp
			ld sp, p_roll
			jp ntc_xn
p_roll_r:		; end of roll
			ld sp, (p_roll_rs)
			jp ntc_xn
p_pad_c:		; call pad (normal)
			pop hl			; v
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_pad_v), de
			xor a
			ld (var_pad_pad), a
			ld (p_pad_rs), sp
			ld sp, p_pad
			jp ntc_xn
p_pad_r:		; end of pad
			ld sp, (p_pad_rs)
			jp ntc_xn
p_rate_c:		; call rate (normal)
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_rate_n), de
			pop hl			; d
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_rate_d), de
			ld hl, 0
			ld (var_rate_rate), hl
			ld (p_rate_rs), sp
			ld sp, p_rate
			jp ntc_xn
p_rate_r:		; end of rate
			ld sp, (p_rate_rs)
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
p_resetslot_c:		; call resetslot (normal)
			pop hl			; s
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_resetslot_s), de
			ld (p_resetslot_rs), sp
			ld sp, p_resetslot
			jp ntc_xn
p_resetslot_r:		; end of resetslot
			ld sp, (p_resetslot_rs)
			jp ntc_xn
p_openslot_c:		; call openslot (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_openslot_t), de
			ld (p_openslot_rs), sp
			ld sp, p_openslot
			jp ntc_xn
p_openslot_r:		; end of openslot
			ld sp, (p_openslot_rs)
			jp ntc_xn
p_sk_c:		; call sk (normal)
			xor a
			ld (var_sk_sk), a
			ld (p_sk_rs), sp
			ld sp, p_sk
			jp ntc_xn
p_sk_r:		; end of sk
			ld sp, (p_sk_rs)
			jp ntc_xn
p_getnm_c:		; call getnm (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_getnm_t), de
			ld hl, 0
			ld (var_getnm_n), hl
			ld (p_getnm_rs), sp
			ld sp, p_getnm
			jp ntc_xn
p_getnm_r:		; end of getnm
			ld sp, (p_getnm_rs)
			jp ntc_xn
p_n_c:		; call n (normal)
			pop hl			; v
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_n_v), de
			xor a
			ld (var_n_n), a
			ld (p_n_rs), sp
			ld sp, p_n
			jp ntc_xn
p_n_r:		; end of n
			ld sp, (p_n_rs)
			jp ntc_xn
p_prompt_c:		; call prompt (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_prompt_t), de
			ld (p_prompt_rs), sp
			ld sp, p_prompt
			jp ntc_xn
p_prompt_r:		; end of prompt
			ld sp, (p_prompt_rs)
			jp ntc_xn
p_keyin_c:		; call keyin (normal)
			pop hl			; k
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_keyin_k), de
			ld hl, 0
			ld (var_keyin_t), hl
			ld hl, 0
			ld (var_keyin_n), hl
			ld (p_keyin_rs), sp
			ld sp, p_keyin
			jp ntc_xn
p_keyin_r:		; end of keyin
			ld sp, (p_keyin_rs)
			jp ntc_xn
p_command_c:		; call command (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_command_t), de
			xor a
			ld (var_command_c), a
			ld hl, 0
			ld (var_command_p), hl
			ld hl, 0
			ld (var_command_s), hl
			ld (p_command_rs), sp
			ld sp, p_command
			jp ntc_xn
p_command_r:		; end of command
			ld sp, (p_command_rs)
			jp ntc_xn
p_starttask_c:		; call starttask (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_starttask_t), de
			pop hl			; s
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_starttask_s), de
			ld hl, 0
			ld (var_starttask_h), hl
			ld hl, 0
			ld (var_starttask_n), hl
			ld hl, 0
			ld (var_starttask_rest), hl
			ld hl, 0
			ld (var_starttask_com), hl
			xor a
			ld (var_starttask_w), a
			ld hl, 0
			ld (var_starttask_d), hl
			ld (p_starttask_rs), sp
			ld sp, p_starttask
			jp ntc_xn
p_starttask_r:		; end of starttask
			ld sp, (p_starttask_rs)
			jp ntc_xn
p_notfound_c:		; call notfound (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_notfound_t), de
			ld (p_notfound_rs), sp
			ld sp, p_notfound
			jp ntc_xn
p_notfound_r:		; end of notfound
			ld sp, (p_notfound_rs)
			jp ntc_xn
p_owndrive_c:		; call owndrive (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_owndrive_t), de
			ld hl, 0
			ld (var_owndrive_r), hl
			ld (p_owndrive_rs), sp
			ld sp, p_owndrive
			jp ntc_xn
p_owndrive_r:		; end of owndrive
			ld sp, (p_owndrive_rs)
			jp ntc_xn
p_endtask_c:		; call endtask (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_endtask_t), de
			ld hl, 0
			ld (var_endtask_c), hl
			ld (p_endtask_rs), sp
			ld sp, p_endtask
			jp ntc_xn
p_endtask_r:		; end of endtask
			ld sp, (p_endtask_rs)
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
p_hyp_show_c:		; call show (normal)
			pop hl			; pg
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_show_pg), de
			ld (p_hyp_show_rs), sp
			ld sp, p_hyp_show
			jp ntc_xn
p_hyp_show_r:		; end of show
			ld sp, (p_hyp_show_rs)
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

ntc_rg66_e:
			IF ($ < 32768) && (ntc_rg67_e - ntc_rg67 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg67:
; ============================================================
; Inline assembly (#asm ... #endasm)
; ============================================================

asm_0_86_n:		; #asm, Main.bas line 86 (normal)
    IFDEF NTC_ZXN		; Main.bas 87
            call gfx_on            ; zxn: Layer 2 bitmap on - the console blits its font into it [88]
    ENDIF		; Main.bas 89
			ret			; end of #asm

fn_hyp_usepage:		; sub usepage (asm keyword), Hyp.cls line 52
            ld hl, (ntc_rampt)		; Hyp.cls 53
            ld (var_hyp_hps), hl		; Hyp.cls 54
			ret			; end of #asm

asm_1_62_n:		; #asm, Hyp.cls line 62 (normal)
            ld hl, (ntc_rampt)		; Hyp.cls 63
            ld (var_hyp_drs), hl		; Hyp.cls 64
			ret			; end of #asm

fn_hyp_setting:		; function setting (asm keyword), Hyp.cls line 100
            ld de, (ntc_rampt)		; Hyp.cls 101
    IFDEF NTC_ZXN		; Hyp.cls 102
            ld a, e                 ; E = the Next 16K bank in the window (mem_sel put it there) [103]
            sub ZXN_FIRSTBANK		; Hyp.cls 104
            srl a		; Hyp.cls 105
            srl a                   ; (bank - FIRSTBANK) / 4 = the 64K bank's ordinal [106]
            inc a                   ; + 1 = the bank index (1-based), the zxn "setting" [107]
            ld e, a		; Hyp.cls 108
            ld d, 0		; Hyp.cls 109
            pop hl		; Hyp.cls 110
            ld (hl), e		; Hyp.cls 111
            inc hl		; Hyp.cls 112
            ld (hl), d		; Hyp.cls 113
            jp fn_hyp_setting_cn_set_z		; Hyp.cls 114
    ENDIF		; Hyp.cls 115
            ld a, e		; Hyp.cls 116
            and #F8		; Hyp.cls 117
            or 2		; Hyp.cls 118
            ld e, a		; Hyp.cls 119
            pop hl		; Hyp.cls 120
            ld (hl), e		; Hyp.cls 121
            inc hl		; Hyp.cls 122
            ld (hl), d		; Hyp.cls 123
fn_hyp_setting_cn_set_z:		; Hyp.cls 124
			ret			; end of #asm

fn_hyp_farptr:		; function farptr (asm keyword), Hyp.cls line 131
            pop hl		; Hyp.cls 132
            ld c, (hl)		; Hyp.cls 133
            inc hl		; Hyp.cls 134
            ld b, (hl)              ; BC = page [135]
            pop hl		; Hyp.cls 136
            ld e, (hl)		; Hyp.cls 137
            inc hl		; Hyp.cls 138
            ld a, (hl)		; Hyp.cls 139
            and #3F		; Hyp.cls 140
            or #40		; Hyp.cls 141
            ld d, a                 ; DE = #4000 + the address's low 14 bits [142]
            pop hl		; Hyp.cls 143
            ld (hl), e		; Hyp.cls 144
            inc hl		; Hyp.cls 145
            ld (hl), d		; Hyp.cls 146
            inc hl		; Hyp.cls 147
            ld (hl), c		; Hyp.cls 148
            inc hl		; Hyp.cls 149
            ld (hl), b		; Hyp.cls 150
			ret			; end of #asm

fn_hyp_fontinit:		; sub fontinit (asm keyword), Hyp.cls line 184
    IFDEF NTC_ZXN		; Hyp.cls 185
            ret                     ; ZX Next: the tilemap renders char codes via its own tiles; [186]
                                    ; no CPC font needed, and #F300 would clobber the tiles
    ENDIF		; Hyp.cls 188
            ld (var_hyp_hsp), sp		; Hyp.cls 189
            ld sp, (ntc_csp)		; Hyp.cls 190
            ld bc, (var_hyp_hps)		; Hyp.cls 191
            out (c), c		; Hyp.cls 192
            ld de, 32               ; D = 0: a table, E = its first character [193]
            ld hl, #4000 + 4096		; Hyp.cls 194
            call #BBAB              ; TXT SET M TABLE (the matrices from 32 on, copied there) [195]
            di		; Hyp.cls 196
            ld de, #FF00            ; D <> 0: no table of its own any more [197]
            call #BBAB		; Hyp.cls 198
            di		; Hyp.cls 199
            ld bc, (ntc_rampt)		; Hyp.cls 200
            out (c), c		; Hyp.cls 201
            ld sp, (var_hyp_hsp)		; Hyp.cls 202
			ret			; end of #asm

asm_1_395_n:		; #asm, Hyp.cls line 395 (normal)
; CN_SB 1: the scrollback (Shift + Up / Down: 48 rows a slot, kept in a 16K page Main gives - #If
; SCROLLBACK in Main.bas, set the two together). Off for now: 526 bytes of main RAM (2026-10-16)
asm_1_395_n_CN_SB:      equ 0		; Hyp.cls 398
            ld (var_hyp_hsp), sp		; Hyp.cls 399
            ld sp, (ntc_csp)		; Hyp.cls 400
            ld bc, (var_hyp_con_pg)		; Hyp.cls 401
    IFNDEF NTC_ZXN		; Hyp.cls 402
            out (c), c              ; the slot's page 3 at #4000: OBUF #7600, state #7682, page #7700 [403]
    ELSE		; Hyp.cls 404
            call asm_1_395_n_zxn_winpg          ; zxn: map the slot's page-3 16K into the window (slots 2,3) via MMU [405]
    ENDIF		; Hyp.cls 406
            IF asm_1_395_n_CN_SB		; Hyp.cls 407
            ld (asm_1_395_n_cn_pg), bc		; Hyp.cls 408
            ENDIF		; Hyp.cls 409
            xor a		; Hyp.cls 410
            ld (asm_1_395_n_cn_pv), a		; Hyp.cls 411
            ld a, (var_hyp_con_front)		; Hyp.cls 412
            ld (asm_1_395_n_cn_front), a		; Hyp.cls 413
            ld a, (#7687)           ; its columns and rows (MODE) [414]
            ld (asm_1_395_n_cn_c), a		; Hyp.cls 415
            ld a, (#7688)		; Hyp.cls 416
            ld (asm_1_395_n_cn_r), a		; Hyp.cls 417
            ld a, (var_hyp_ccu)           ; the cursor off first, whatever comes (it was on: cn_was) [418]
            ld (asm_1_395_n_cn_was), a		; Hyp.cls 419
            or a		; Hyp.cls 420
            call nz, asm_1_395_n_cn_cuxor		; Hyp.cls 421
            ld hl, (var_hyp_con_n)		; Hyp.cls 422
            bit 7, h		; Hyp.cls 423
            jp nz, asm_1_395_n_cn_neg		; Hyp.cls 424
            ld (asm_1_395_n_cn_left), hl		; Hyp.cls 425
            IF asm_1_395_n_CN_SB		; Hyp.cls 426
            ld a, (asm_1_395_n_cn_front)        ; in front and looking back (scrollback): the page again first [427]
            or a		; Hyp.cls 428
            jr z, asm_1_395_n_cn_live		; Hyp.cls 429
            ld a, (#7F26)		; Hyp.cls 430
            or a		; Hyp.cls 431
            jr z, asm_1_395_n_cn_live		; Hyp.cls 432
            xor a		; Hyp.cls 433
            ld (#7F26), a		; Hyp.cls 434
            call asm_1_395_n_cn_cls		; Hyp.cls 435
            call asm_1_395_n_cn_strip		; Hyp.cls 436
            call asm_1_395_n_cn_draw		; Hyp.cls 437
            ld hl, (asm_1_395_n_cn_left)		; Hyp.cls 438
asm_1_395_n_cn_live:		; Hyp.cls 439
            ENDIF		; Hyp.cls 440
            ld hl, (var_hyp_con_src)		; Hyp.cls 441
            ld a, h		; Hyp.cls 442
            or l		; Hyp.cls 443
            jr nz, asm_1_395_n_cn_src		; Hyp.cls 444
            ld hl, #7600            ; src 0: the characters the program collected (OBUF) [445]
asm_1_395_n_cn_src:		; Hyp.cls 446
            ld (asm_1_395_n_cn_ptr), hl		; Hyp.cls 447
asm_1_395_n_cn_lp:		; Hyp.cls 448
            ld hl, (asm_1_395_n_cn_left)		; Hyp.cls 449
            ld a, h		; Hyp.cls 450
            or l		; Hyp.cls 451
            jr z, asm_1_395_n_cn_done		; Hyp.cls 452
            dec hl		; Hyp.cls 453
            ld (asm_1_395_n_cn_left), hl		; Hyp.cls 454
            ld hl, (asm_1_395_n_cn_ptr)		; Hyp.cls 455
            ld a, (hl)		; Hyp.cls 456
            inc hl		; Hyp.cls 457
            ld (asm_1_395_n_cn_ptr), hl		; Hyp.cls 458
            call asm_1_395_n_cn_char		; Hyp.cls 459
            jr asm_1_395_n_cn_lp		; Hyp.cls 460
asm_1_395_n_cn_done:		; Hyp.cls 461
            ld bc, (ntc_rampt)      ; the window's page back [462]
            out (c), c		; Hyp.cls 463
            ld sp, (var_hyp_hsp)		; Hyp.cls 464
            jp asm_1_395_n_cn_end		; Hyp.cls 465

; n < 0: -1 the whole page to the screen (it was cleared: Show), not looking back any more; -2
; the scrollback (src: the key - #F4 Shift + Up a screen back, #F5 Shift + Down one on), drawn
asm_1_395_n_cn_neg:		; Hyp.cls 469
            ld a, l		; Hyp.cls 470
            cp #FD                  ; -3: the cursor flashes - on (it was off), an underline XORed [471]
            jr nz, asm_1_395_n_cn_neg1          ; where the next character goes; off (it was on: done above) [472]
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 473
            or a		; Hyp.cls 474
            jr z, asm_1_395_n_cn_done		; Hyp.cls 475
            ld a, (var_hyp_nta)           ; the network blink: advance it (0.5s) while there's traffic [476]
            or a		; Hyp.cls 477
            jr z, asm_1_395_n_cn_nt1		; Hyp.cls 478
            dec a		; Hyp.cls 479
            ld (var_hyp_nta), a		; Hyp.cls 480
            ld a, (var_hyp_ntb)		; Hyp.cls 481
            xor 1		; Hyp.cls 482
            ld (var_hyp_ntb), a		; Hyp.cls 483
asm_1_395_n_cn_nt1:		; Hyp.cls 484
            call asm_1_395_n_cn_net		; Hyp.cls 485
            ld a, (asm_1_395_n_cn_was)		; Hyp.cls 486
            or a		; Hyp.cls 487
            jr nz, asm_1_395_n_cn_done		; Hyp.cls 488
            ld a, (#7682)		; Hyp.cls 489
            ld d, a		; Hyp.cls 490
            ld a, (#7683)		; Hyp.cls 491
            ld e, a		; Hyp.cls 492
            call asm_1_395_n_cn_scr		; Hyp.cls 493
    IFNDEF NTC_ZXN		; Hyp.cls 494
            ld a, h		; Hyp.cls 495
            add a, #38              ; (its cell's last pixel line) [496]
            ld h, a		; Hyp.cls 497
    ENDIF		; Hyp.cls 498
            ld (asm_1_395_n_cn_ca), hl          ; zxn: cn_ca = the logical cell address as is [499]
            call asm_1_395_n_cn_cuxor		; Hyp.cls 500
            jr asm_1_395_n_cn_done		; Hyp.cls 501
asm_1_395_n_cn_neg1:		; Hyp.cls 502
            IF asm_1_395_n_CN_SB		; Hyp.cls 503
            inc hl		; Hyp.cls 504
            ld a, h		; Hyp.cls 505
            or l		; Hyp.cls 506
            jr nz, asm_1_395_n_cn_view		; Hyp.cls 507
            ld (#7F26), a		; Hyp.cls 508
            ENDIF		; Hyp.cls 509
asm_1_395_n_cn_show:		; Hyp.cls 510
            call asm_1_395_n_cn_strip		; Hyp.cls 511
            call asm_1_395_n_cn_draw		; Hyp.cls 512
            jr asm_1_395_n_cn_done		; Hyp.cls 513
            IF asm_1_395_n_CN_SB		; Hyp.cls 514
asm_1_395_n_cn_view:		; Hyp.cls 515
            ld a, (#7F21)           ; (no history page: nothing) [516]
            or a		; Hyp.cls 517
            jr z, asm_1_395_n_cn_done		; Hyp.cls 518
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 519
            dec a		; Hyp.cls 520
            ld b, a                 ; a screen: its rows - 1 [521]
            ld a, (var_hyp_con_src)		; Hyp.cls 522
            cp #F4		; Hyp.cls 523
            ld a, (#7F26)		; Hyp.cls 524
            jr nz, asm_1_395_n_cn_vw_dn		; Hyp.cls 525
            add a, b		; Hyp.cls 526
            ld hl, #7F25		; Hyp.cls 527
            cp (hl)		; Hyp.cls 528
            jr c, asm_1_395_n_cn_vw_set		; Hyp.cls 529
            ld a, (hl)              ; (not past the oldest row kept) [530]
            jr asm_1_395_n_cn_vw_set		; Hyp.cls 531
asm_1_395_n_cn_vw_dn:		; Hyp.cls 532
            sub b		; Hyp.cls 533
            jr nc, asm_1_395_n_cn_vw_set		; Hyp.cls 534
            xor a		; Hyp.cls 535
asm_1_395_n_cn_vw_set:		; Hyp.cls 536
            ld hl, #7F26		; Hyp.cls 537
            cp (hl)		; Hyp.cls 538
            jr z, asm_1_395_n_cn_done		; Hyp.cls 539
            ld (hl), a		; Hyp.cls 540
            call asm_1_395_n_cn_cls		; Hyp.cls 541
            jr asm_1_395_n_cn_show		; Hyp.cls 542

            ENDIF		; Hyp.cls 544

; the screen's rows: the page's - or, looking back (#FF26 rows), the history's first, then the
; page's. Row e shows line count + e - back of history + page (count the rows kept, #FF25)
asm_1_395_n_cn_draw:		; Hyp.cls 548
            ld e, 0		; Hyp.cls 549
            IF asm_1_395_n_CN_SB		; Hyp.cls 550
asm_1_395_n_cn_dr_row:		; Hyp.cls 551
            push de		; Hyp.cls 552
            ld a, (#7F25)		; Hyp.cls 553
            add a, e		; Hyp.cls 554
            ld hl, #7F26		; Hyp.cls 555
            sub (hl)                ; the line: count + e - back [556]
            ld hl, #7F25		; Hyp.cls 557
            sub (hl)		; Hyp.cls 558
            jr c, asm_1_395_n_cn_dr_h		; Hyp.cls 559
            call asm_1_395_n_cn_rowa            ; HL = row (line - count) of the page [560]
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 561
            jr asm_1_395_n_cn_dr_go		; Hyp.cls 562
asm_1_395_n_cn_dr_h:		; Hyp.cls 563
            add a, (hl)		; Hyp.cls 564
            call asm_1_395_n_cn_hget            ; HL = the history's row (copied in), 80 characters at most [565]
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 566
            cp asm_1_395_n_HW		; Hyp.cls 567
            jr c, asm_1_395_n_cn_dr_go		; Hyp.cls 568
            ld a, asm_1_395_n_HW		; Hyp.cls 569
asm_1_395_n_cn_dr_go:		; Hyp.cls 570
            ld b, a		; Hyp.cls 571
            pop de		; Hyp.cls 572
            push de		; Hyp.cls 573
            ld d, 0		; Hyp.cls 574
asm_1_395_n_cn_dr_col:		; Hyp.cls 575
            ld a, (hl)		; Hyp.cls 576
            inc hl		; Hyp.cls 577
            cp 33		; Hyp.cls 578
            jr c, asm_1_395_n_cn_dr_sk		; Hyp.cls 579
            push hl		; Hyp.cls 580
            push de		; Hyp.cls 581
            push bc		; Hyp.cls 582
            call asm_1_395_n_cn_glyph		; Hyp.cls 583
            pop bc		; Hyp.cls 584
            pop de		; Hyp.cls 585
            pop hl		; Hyp.cls 586
asm_1_395_n_cn_dr_sk:		; Hyp.cls 587
            inc d		; Hyp.cls 588
            djnz asm_1_395_n_cn_dr_col		; Hyp.cls 589
            pop de		; Hyp.cls 590
            inc e		; Hyp.cls 591
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 592
            dec a		; Hyp.cls 593
            cp e		; Hyp.cls 594
            jr nc, asm_1_395_n_cn_dr_row		; Hyp.cls 595
            ret		; Hyp.cls 596
            ELSE		; Hyp.cls 597
asm_1_395_n_cn_sh_row:                          ; (no scrollback: the page's rows as they are) [598]
            push de		; Hyp.cls 599
            ld a, e		; Hyp.cls 600
            call asm_1_395_n_cn_rowa            ; HL = row e of the page [601]
            pop de		; Hyp.cls 602
            ld d, 0		; Hyp.cls 603
asm_1_395_n_cn_sh_col:		; Hyp.cls 604
            ld a, (hl)		; Hyp.cls 605
            inc hl		; Hyp.cls 606
            cp 33		; Hyp.cls 607
            jr c, asm_1_395_n_cn_sh_skip		; Hyp.cls 608
            push hl		; Hyp.cls 609
            push de		; Hyp.cls 610
            call asm_1_395_n_cn_glyph		; Hyp.cls 611
            pop de		; Hyp.cls 612
            pop hl		; Hyp.cls 613
asm_1_395_n_cn_sh_skip:		; Hyp.cls 614
            inc d		; Hyp.cls 615
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 616
            dec a		; Hyp.cls 617
            cp d		; Hyp.cls 618
            jr nc, asm_1_395_n_cn_sh_col		; Hyp.cls 619
            inc e		; Hyp.cls 620
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 621
            dec a		; Hyp.cls 622
            cp e		; Hyp.cls 623
            jr nc, asm_1_395_n_cn_sh_row		; Hyp.cls 624
            ret		; Hyp.cls 625
            ENDIF		; Hyp.cls 626

            IF asm_1_395_n_CN_SB		; Hyp.cls 628
; the scrollback: each row that scrolls off the top of the page - its first HW characters - goes
; to the slot's history: HROWS rows (a ring) in a 16K page of its own that Main gave it (#FF20:
; its RAM setting, 0 none; #FF22 where in it; #FF24 the next row written, #FF25 how many, #FF26
; how far back the screen looks). Copied 8 bytes at a time through the stack - only the window
; changes, so no main RAM for a buffer
asm_1_395_n_HW:         equ 80		; Hyp.cls 634
asm_1_395_n_HROWS:      equ 48		; Hyp.cls 635
asm_1_395_n_cn_hput:                            ; HL = the row going (the page) [636]
            ld a, (#7F21)		; Hyp.cls 637
            or a		; Hyp.cls 638
            ret z		; Hyp.cls 639
            ld (asm_1_395_n_cn_hs), hl		; Hyp.cls 640
            ld hl, (asm_1_395_n_cn_pg)		; Hyp.cls 641
            ld (asm_1_395_n_cn_h1), hl		; Hyp.cls 642
            ld hl, (#7F20)		; Hyp.cls 643
            ld (asm_1_395_n_cn_h2), hl		; Hyp.cls 644
            ld a, (#7F24)		; Hyp.cls 645
            call asm_1_395_n_cn_haddr		; Hyp.cls 646
            ld (asm_1_395_n_cn_hd), hl		; Hyp.cls 647
            ld hl, #7F24            ; the next row on, one more kept [648]
            ld a, (hl)		; Hyp.cls 649
            inc a		; Hyp.cls 650
            cp asm_1_395_n_HROWS		; Hyp.cls 651
            jr c, asm_1_395_n_cn_hp_h		; Hyp.cls 652
            xor a		; Hyp.cls 653
asm_1_395_n_cn_hp_h:		; Hyp.cls 654
            ld (hl), a		; Hyp.cls 655
            inc hl		; Hyp.cls 656
            ld a, (hl)		; Hyp.cls 657
            cp asm_1_395_n_HROWS		; Hyp.cls 658
            jr nc, asm_1_395_n_cn_hcp		; Hyp.cls 659
            inc (hl)		; Hyp.cls 660
; cn_hcp: HW bytes from cn_hs in RAM setting cn_h1 to cn_hd in cn_h2, then the slot's page back
asm_1_395_n_cn_hcp:		; Hyp.cls 662
            ld a, asm_1_395_n_HW / 8		; Hyp.cls 663
asm_1_395_n_cn_hc_lp:		; Hyp.cls 664
            ld (asm_1_395_n_cn_hn), a		; Hyp.cls 665
            ld bc, (asm_1_395_n_cn_h1)		; Hyp.cls 666
            out (c), c		; Hyp.cls 667
            ld hl, (asm_1_395_n_cn_hs)		; Hyp.cls 668
            ld b, 4		; Hyp.cls 669
asm_1_395_n_cn_hc_in:		; Hyp.cls 670
            ld e, (hl)		; Hyp.cls 671
            inc hl		; Hyp.cls 672
            ld d, (hl)		; Hyp.cls 673
            inc hl		; Hyp.cls 674
            push de		; Hyp.cls 675
            djnz asm_1_395_n_cn_hc_in		; Hyp.cls 676
            ld (asm_1_395_n_cn_hs), hl		; Hyp.cls 677
            ld bc, (asm_1_395_n_cn_h2)		; Hyp.cls 678
            out (c), c		; Hyp.cls 679
            ld hl, (asm_1_395_n_cn_hd)		; Hyp.cls 680
            ld de, 8		; Hyp.cls 681
            add hl, de		; Hyp.cls 682
            ld (asm_1_395_n_cn_hd), hl		; Hyp.cls 683
            ld b, 4		; Hyp.cls 684
asm_1_395_n_cn_hc_out:		; Hyp.cls 685
            pop de		; Hyp.cls 686
            dec hl		; Hyp.cls 687
            ld (hl), d		; Hyp.cls 688
            dec hl		; Hyp.cls 689
            ld (hl), e		; Hyp.cls 690
            djnz asm_1_395_n_cn_hc_out		; Hyp.cls 691
            ld a, (asm_1_395_n_cn_hn)		; Hyp.cls 692
            dec a		; Hyp.cls 693
            jr nz, asm_1_395_n_cn_hc_lp		; Hyp.cls 694
            ld bc, (asm_1_395_n_cn_pg)		; Hyp.cls 695
            out (c), c		; Hyp.cls 696
            ret		; Hyp.cls 697
asm_1_395_n_cn_hget:                            ; A = a line of the history (0 the oldest kept): copied to [698]
            ld hl, #7F24            ; #FF30 in the slot's page (HL) [699]
            add a, (hl)		; Hyp.cls 700
            inc hl		; Hyp.cls 701
            sub (hl)		; Hyp.cls 702
            jr nc, asm_1_395_n_cn_hg_r		; Hyp.cls 703
            add a, asm_1_395_n_HROWS		; Hyp.cls 704
asm_1_395_n_cn_hg_r:		; Hyp.cls 705
            call asm_1_395_n_cn_haddr		; Hyp.cls 706
            ld (asm_1_395_n_cn_hs), hl		; Hyp.cls 707
            ld hl, (#7F20)		; Hyp.cls 708
            ld (asm_1_395_n_cn_h1), hl		; Hyp.cls 709
            ld hl, (asm_1_395_n_cn_pg)		; Hyp.cls 710
            ld (asm_1_395_n_cn_h2), hl		; Hyp.cls 711
            ld hl, #7F30		; Hyp.cls 712
            ld (asm_1_395_n_cn_hd), hl		; Hyp.cls 713
            call asm_1_395_n_cn_hcp		; Hyp.cls 714
            ld hl, #7F30		; Hyp.cls 715
            ret		; Hyp.cls 716
asm_1_395_n_cn_haddr:                           ; A = a history row: HL = its address in the history page [717]
            ld e, a		; Hyp.cls 718
            ld a, asm_1_395_n_HW		; Hyp.cls 719
            call asm_1_395_n_cn_mul		; Hyp.cls 720
            ld de, (#7F22)		; Hyp.cls 721
            add hl, de		; Hyp.cls 722
            ret		; Hyp.cls 723
; cn_cls: the screen cleared (written only: the Library: ROM build's keyword ROM may be over it)
asm_1_395_n_cn_cls:		; Hyp.cls 725
    IFDEF NTC_ZXN		; Hyp.cls 726
            ld hl, #E000            ; zxn: clear the tilemap (80 x 32 = #E000-#E9FF) to blank (space) [727]
            ld bc, 80 * 32		; Hyp.cls 728
asm_1_395_n_cn_cl_zx:		; Hyp.cls 729
            ld (hl), ' '		; Hyp.cls 730
            inc hl		; Hyp.cls 731
            dec bc		; Hyp.cls 732
            ld a, b		; Hyp.cls 733
            or c		; Hyp.cls 734
            jr nz, asm_1_395_n_cn_cl_zx		; Hyp.cls 735
            ret		; Hyp.cls 736
    ENDIF		; Hyp.cls 737
            ld hl, #C000		; Hyp.cls 738
            ld bc, #4000		; Hyp.cls 739
asm_1_395_n_cn_cl_lp:		; Hyp.cls 740
            ld (hl), 0		; Hyp.cls 741
            inc hl		; Hyp.cls 742
            dec bc		; Hyp.cls 743
            ld a, b		; Hyp.cls 744
            or c		; Hyp.cls 745
            jr nz, asm_1_395_n_cn_cl_lp		; Hyp.cls 746
            ret		; Hyp.cls 747
            ENDIF		; Hyp.cls 748

; cn_char: A = one character
asm_1_395_n_cn_char:		; Hyp.cls 751
            ld b, a		; Hyp.cls 752
            ld a, (#7685)           ; in an escape sequence? [753]
            or a		; Hyp.cls 754
            jr nz, asm_1_395_n_cn_esc0		; Hyp.cls 755
            ld a, b		; Hyp.cls 756
            cp 32		; Hyp.cls 757
            jp nc, asm_1_395_n_cn_print		; Hyp.cls 758
            ld hl, asm_1_395_n_cn_pv            ; a control code: the cursor may move (the pointers redone) [759]
            ld (hl), 0		; Hyp.cls 760
            cp 27		; Hyp.cls 761
            jr z, asm_1_395_n_cn_setesc		; Hyp.cls 762
            cp 13		; Hyp.cls 763
            jr z, asm_1_395_n_cn_cr		; Hyp.cls 764
            cp 10		; Hyp.cls 765
            jp z, asm_1_395_n_cn_nl		; Hyp.cls 766
            cp 9		; Hyp.cls 767
            jr z, asm_1_395_n_cn_tab		; Hyp.cls 768
            cp 8		; Hyp.cls 769
            ret nz                  ; other control codes: nothing [770]
            ld a, (#7682)           ; BS: back one (not past the start of the row) [771]
            or a		; Hyp.cls 772
            ret z		; Hyp.cls 773
            dec a		; Hyp.cls 774
            ld (#7682), a		; Hyp.cls 775
            ret		; Hyp.cls 776
asm_1_395_n_cn_tab:                             ; TAB: spaces to the next column of 8 [777]
            ld b, ' '		; Hyp.cls 778
            call asm_1_395_n_cn_print		; Hyp.cls 779
            ld a, (#7682)		; Hyp.cls 780
            and 7		; Hyp.cls 781
            jr nz, asm_1_395_n_cn_tab		; Hyp.cls 782
            ret		; Hyp.cls 783
asm_1_395_n_cn_setesc:		; Hyp.cls 784
            ld a, 1		; Hyp.cls 785
            ld (#7685), a		; Hyp.cls 786
            ret		; Hyp.cls 787
asm_1_395_n_cn_cr:		; Hyp.cls 788
            xor a		; Hyp.cls 789
            ld (#7682), a		; Hyp.cls 790
            ret		; Hyp.cls 791
asm_1_395_n_cn_esc0:		; Hyp.cls 792
            ld hl, asm_1_395_n_cn_pv		; Hyp.cls 793
            ld (hl), 0		; Hyp.cls 794
asm_1_395_n_cn_esc:		; Hyp.cls 795
            cp 1		; Hyp.cls 796
            jr nz, asm_1_395_n_cn_esc2		; Hyp.cls 797
            xor a                   ; ESC x [798]
            ld (#7685), a		; Hyp.cls 799
            ld a, b		; Hyp.cls 800
            cp 'E'		; Hyp.cls 801
            jp z, asm_1_395_n_cn_clear		; Hyp.cls 802
            cp 'H'		; Hyp.cls 803
            jr z, asm_1_395_n_cn_home		; Hyp.cls 804
            cp 'I'		; Hyp.cls 805
            jp z, asm_1_395_n_cn_rev		; Hyp.cls 806
            cp 'Y'		; Hyp.cls 807
            jr z, asm_1_395_n_cn_sety		; Hyp.cls 808
            cp 'A'		; Hyp.cls 809
            jr z, asm_1_395_n_cn_up		; Hyp.cls 810
            cp 'B'		; Hyp.cls 811
            jr z, asm_1_395_n_cn_down		; Hyp.cls 812
            cp 'C'		; Hyp.cls 813
            jr z, asm_1_395_n_cn_right		; Hyp.cls 814
            cp 'D'		; Hyp.cls 815
            jr z, asm_1_395_n_cn_lft		; Hyp.cls 816
            cp 'K'		; Hyp.cls 817
            jp z, asm_1_395_n_cn_eol		; Hyp.cls 818
            cp 'J'		; Hyp.cls 819
            jp z, asm_1_395_n_cn_eos		; Hyp.cls 820
            cp 'l'		; Hyp.cls 821
            jp z, asm_1_395_n_cn_eln		; Hyp.cls 822
            cp 'o'		; Hyp.cls 823
            jp z, asm_1_395_n_cn_sol		; Hyp.cls 824
            cp 'd'		; Hyp.cls 825
            jp z, asm_1_395_n_cn_sos		; Hyp.cls 826
            cp 'M'		; Hyp.cls 827
            jp z, asm_1_395_n_cn_dell		; Hyp.cls 828
            cp 'L'		; Hyp.cls 829
            jp z, asm_1_395_n_cn_insl		; Hyp.cls 830
            ret                     ; (the rest - e f j k p q ...: nothing) [831]
asm_1_395_n_cn_sety:		; Hyp.cls 832
            ld a, 2		; Hyp.cls 833
            ld (#7685), a		; Hyp.cls 834
            ret		; Hyp.cls 835
asm_1_395_n_cn_up:                              ; ESC A, B, C, D: up, down, right, left (not past the edge) [836]
            ld hl, #7683		; Hyp.cls 837
            jr asm_1_395_n_cn_dec		; Hyp.cls 838
asm_1_395_n_cn_lft:		; Hyp.cls 839
            ld hl, #7682		; Hyp.cls 840
asm_1_395_n_cn_dec:		; Hyp.cls 841
            ld a, (hl)		; Hyp.cls 842
            or a		; Hyp.cls 843
            ret z		; Hyp.cls 844
            dec (hl)		; Hyp.cls 845
            ret		; Hyp.cls 846
asm_1_395_n_cn_down:		; Hyp.cls 847
            ld de, #7683		; Hyp.cls 848
            ld hl, asm_1_395_n_cn_r		; Hyp.cls 849
            jr asm_1_395_n_cn_inc		; Hyp.cls 850
asm_1_395_n_cn_right:		; Hyp.cls 851
            ld de, #7682		; Hyp.cls 852
            ld hl, asm_1_395_n_cn_c		; Hyp.cls 853
asm_1_395_n_cn_inc:		; Hyp.cls 854
            ld a, (de)		; Hyp.cls 855
            inc a		; Hyp.cls 856
            cp (hl)		; Hyp.cls 857
            ret nc		; Hyp.cls 858
            ld (de), a		; Hyp.cls 859
            ret		; Hyp.cls 860
asm_1_395_n_cn_home:		; Hyp.cls 861
            xor a		; Hyp.cls 862
            ld (#7682), a		; Hyp.cls 863
            ld (#7683), a		; Hyp.cls 864
            ret		; Hyp.cls 865
asm_1_395_n_cn_esc2:		; Hyp.cls 866
            cp 2		; Hyp.cls 867
            jr nz, asm_1_395_n_cn_esc3		; Hyp.cls 868
            ld a, b                 ; ESC Y row [869]
            sub 32		; Hyp.cls 870
            ld (#7686), a		; Hyp.cls 871
            ld a, 3		; Hyp.cls 872
            ld (#7685), a		; Hyp.cls 873
            ret		; Hyp.cls 874
asm_1_395_n_cn_esc3:		; Hyp.cls 875
            xor a                   ; ESC Y row col [876]
            ld (#7685), a		; Hyp.cls 877
            ld a, b		; Hyp.cls 878
            sub 32		; Hyp.cls 879
            ld hl, asm_1_395_n_cn_c		; Hyp.cls 880
            cp (hl)		; Hyp.cls 881
            jr c, asm_1_395_n_cn_e3_col		; Hyp.cls 882
            xor a		; Hyp.cls 883
asm_1_395_n_cn_e3_col:		; Hyp.cls 884
            ld (#7682), a		; Hyp.cls 885
            ld a, (#7686)		; Hyp.cls 886
            ld hl, asm_1_395_n_cn_r		; Hyp.cls 887
            cp (hl)		; Hyp.cls 888
            jr c, asm_1_395_n_cn_e3_row		; Hyp.cls 889
            xor a		; Hyp.cls 890
asm_1_395_n_cn_e3_row:		; Hyp.cls 891
            ld (#7683), a		; Hyp.cls 892
            ret		; Hyp.cls 893

; a printable character (B): into the page, on the screen if in front, the column on. The page
; and screen pointers are worked out at the first character after the cursor moved (cn_pv 0),
; then just stepped on - a run of characters costs the 8 screen bytes each, not a sum each
asm_1_395_n_cn_print:		; Hyp.cls 898
            ld a, (asm_1_395_n_cn_pv)		; Hyp.cls 899
            or a		; Hyp.cls 900
            jr nz, asm_1_395_n_cn_pr_have		; Hyp.cls 901
            ld a, (#7683)		; Hyp.cls 902
            call asm_1_395_n_cn_rowa		; Hyp.cls 903
            ld a, (#7682)		; Hyp.cls 904
            ld e, a		; Hyp.cls 905
            ld d, 0		; Hyp.cls 906
            add hl, de		; Hyp.cls 907
            ld (asm_1_395_n_cn_pp), hl		; Hyp.cls 908
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 909
            or a		; Hyp.cls 910
            jr z, asm_1_395_n_cn_pr_set		; Hyp.cls 911
            ld a, (#7682)		; Hyp.cls 912
            ld d, a		; Hyp.cls 913
            ld a, (#7683)		; Hyp.cls 914
            ld e, a		; Hyp.cls 915
            push bc                 ; (B: the character) [916]
            call asm_1_395_n_cn_scr		; Hyp.cls 917
            pop bc		; Hyp.cls 918
            ld (asm_1_395_n_cn_sp), hl		; Hyp.cls 919
asm_1_395_n_cn_pr_set:		; Hyp.cls 920
            ld a, 1		; Hyp.cls 921
            ld (asm_1_395_n_cn_pv), a		; Hyp.cls 922
asm_1_395_n_cn_pr_have:		; Hyp.cls 923
            ld hl, (asm_1_395_n_cn_pp)          ; the page [924]
            ld (hl), b		; Hyp.cls 925
            inc hl		; Hyp.cls 926
            ld (asm_1_395_n_cn_pp), hl		; Hyp.cls 927
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 928
            or a		; Hyp.cls 929
            jr z, asm_1_395_n_cn_pr_adv		; Hyp.cls 930
            ld hl, (asm_1_395_n_cn_sp)          ; the screen [931]
            push hl		; Hyp.cls 932
            ld a, b		; Hyp.cls 933
            call asm_1_395_n_cn_glyph8		; Hyp.cls 934
            pop hl		; Hyp.cls 935
            call asm_1_395_n_cn_next		; Hyp.cls 936
            ld (asm_1_395_n_cn_sp), hl		; Hyp.cls 937
asm_1_395_n_cn_pr_adv:		; Hyp.cls 938
            ld hl, #7682		; Hyp.cls 939
            inc (hl)		; Hyp.cls 940
            ld a, (hl)		; Hyp.cls 941
            ld hl, asm_1_395_n_cn_c		; Hyp.cls 942
            cp (hl)		; Hyp.cls 943
            ret c		; Hyp.cls 944
            xor a                   ; past the last column: the next row [945]
            ld (#7682), a		; Hyp.cls 946
            ld (asm_1_395_n_cn_pv), a		; Hyp.cls 947
; a line feed: the next row, or the page (and the screen) scroll
asm_1_395_n_cn_nl:		; Hyp.cls 949
            ld a, (#7683)		; Hyp.cls 950
            inc a		; Hyp.cls 951
            ld hl, asm_1_395_n_cn_r		; Hyp.cls 952
            cp (hl)		; Hyp.cls 953
            jr nc, asm_1_395_n_cn_scroll		; Hyp.cls 954
            ld (#7683), a		; Hyp.cls 955
            ret		; Hyp.cls 956
asm_1_395_n_cn_scroll:		; Hyp.cls 957
            ld a, (#7684)           ; the ring's top row moves on (no copy) [958]
            inc a		; Hyp.cls 959
            cp (hl)		; Hyp.cls 960
            jr c, asm_1_395_n_cn_sc_top		; Hyp.cls 961
            xor a		; Hyp.cls 962
asm_1_395_n_cn_sc_top:		; Hyp.cls 963
            ld (#7684), a		; Hyp.cls 964
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 965
            dec a		; Hyp.cls 966
            call asm_1_395_n_cn_rowa            ; the new last row cleared (the old top row: kept first) [967]
            IF asm_1_395_n_CN_SB		; Hyp.cls 968
            push hl		; Hyp.cls 969
            call asm_1_395_n_cn_hput		; Hyp.cls 970
            pop hl		; Hyp.cls 971
            ENDIF		; Hyp.cls 972
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 973
            ld b, a		; Hyp.cls 974
asm_1_395_n_cn_sc_cl:		; Hyp.cls 975
            ld (hl), ' '		; Hyp.cls 976
            inc hl		; Hyp.cls 977
            djnz asm_1_395_n_cn_sc_cl		; Hyp.cls 978
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 979
            or a		; Hyp.cls 980
            ret z		; Hyp.cls 981
    IFDEF NTC_ZXN		; Hyp.cls 982
            call gfx_clear          ; zxn: no HW scroll - clear Layer 2 and redraw from the page [983]
            call asm_1_395_n_cn_draw		; Hyp.cls 984
            jp asm_1_395_n_cn_strip		; Hyp.cls 985
    ENDIF		; Hyp.cls 986
            ld hl, (var_hyp_sco)          ; the screen: its start a row on (R12, R13), the new last row [987]
            ld de, (var_hyp_scc)          ; cleared, the status strip again (it went off the top) [988]
            add hl, de		; Hyp.cls 989
            ld a, h		; Hyp.cls 990
            and #07		; Hyp.cls 991
            ld h, a		; Hyp.cls 992
            ld (var_hyp_sco), hl		; Hyp.cls 993
            call asm_1_395_n_cn_crtc		; Hyp.cls 994
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 995
            dec a		; Hyp.cls 996
            ld e, a		; Hyp.cls 997
asm_1_395_n_cn_sc_clr:                          ; E = a screen row: cleared, then the status strip again [998]
            ld d, 0		; Hyp.cls 999
            call asm_1_395_n_cn_scr		; Hyp.cls 1000
            ld b, 8		; Hyp.cls 1001
asm_1_395_n_cn_sc_ln:		; Hyp.cls 1002
            push bc		; Hyp.cls 1003
            push hl		; Hyp.cls 1004
            ld a, (var_hyp_scc)		; Hyp.cls 1005
            ld b, a		; Hyp.cls 1006
asm_1_395_n_cn_sc_b:		; Hyp.cls 1007
            ld (hl), 0		; Hyp.cls 1008
            call asm_1_395_n_cn_next		; Hyp.cls 1009
            djnz asm_1_395_n_cn_sc_b		; Hyp.cls 1010
            pop hl		; Hyp.cls 1011
            ld a, h		; Hyp.cls 1012
            add a, 8		; Hyp.cls 1013
            ld h, a		; Hyp.cls 1014
            pop bc		; Hyp.cls 1015
            djnz asm_1_395_n_cn_sc_ln		; Hyp.cls 1016
            jp asm_1_395_n_cn_strip		; Hyp.cls 1017

; ESC I (reverse line feed): the row before, or on the top row the page (and the screen) scroll
; back: the ring's top row a row back, the new top row cleared; on the screen its start a row
; back (R12, R13) and the new top row cleared - the line feed's scroll the other way
asm_1_395_n_cn_rev:		; Hyp.cls 1022
            ld a, (#7683)		; Hyp.cls 1023
            or a		; Hyp.cls 1024
            jr z, asm_1_395_n_cn_rv_sc		; Hyp.cls 1025
            dec a		; Hyp.cls 1026
            ld (#7683), a		; Hyp.cls 1027
            ret		; Hyp.cls 1028
asm_1_395_n_cn_rv_sc:		; Hyp.cls 1029
            ld a, (#7684)		; Hyp.cls 1030
            or a		; Hyp.cls 1031
            jr nz, asm_1_395_n_cn_rv_top		; Hyp.cls 1032
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 1033
asm_1_395_n_cn_rv_top:		; Hyp.cls 1034
            dec a		; Hyp.cls 1035
            ld (#7684), a		; Hyp.cls 1036
            xor a		; Hyp.cls 1037
            call asm_1_395_n_cn_rowa            ; (row 0 of the page now) [1038]
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1039
            ld b, a		; Hyp.cls 1040
asm_1_395_n_cn_rv_cl:		; Hyp.cls 1041
            ld (hl), ' '		; Hyp.cls 1042
            inc hl		; Hyp.cls 1043
            djnz asm_1_395_n_cn_rv_cl		; Hyp.cls 1044
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 1045
            or a		; Hyp.cls 1046
            ret z		; Hyp.cls 1047
            ld hl, (var_hyp_sco)		; Hyp.cls 1048
            ld de, (var_hyp_scc)		; Hyp.cls 1049
            or a		; Hyp.cls 1050
            sbc hl, de		; Hyp.cls 1051
            ld a, h		; Hyp.cls 1052
            and #07		; Hyp.cls 1053
            ld h, a		; Hyp.cls 1054
            ld (var_hyp_sco), hl		; Hyp.cls 1055
            call asm_1_395_n_cn_crtc		; Hyp.cls 1056
            ld e, 0		; Hyp.cls 1057
            jp asm_1_395_n_cn_sc_clr		; Hyp.cls 1058

; ESC K the row from the cursor on cleared, J the rest of the page too, l the whole row, o the
; row up to the cursor, d the page up to it; M the cursor's row deleted (those below up a row, a
; blank one at the end), L a blank one put in (those below down, the last gone) - the column 0.
; The page changed first, then its rows drawn again on the screen when in front
asm_1_395_n_cn_eol:		; Hyp.cls 1064
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1065
            ld hl, #7682		; Hyp.cls 1066
            sub (hl)		; Hyp.cls 1067
            ld b, a		; Hyp.cls 1068
            ld d, (hl)		; Hyp.cls 1069
            ld a, (#7683)		; Hyp.cls 1070
            ld e, a		; Hyp.cls 1071
            jp asm_1_395_n_cn_wipen		; Hyp.cls 1072
asm_1_395_n_cn_eos:		; Hyp.cls 1073
            call asm_1_395_n_cn_eol		; Hyp.cls 1074
            ld a, (#7683)		; Hyp.cls 1075
asm_1_395_n_cn_eos_lp:		; Hyp.cls 1076
            inc a		; Hyp.cls 1077
            ld hl, asm_1_395_n_cn_r		; Hyp.cls 1078
            cp (hl)		; Hyp.cls 1079
            ret nc		; Hyp.cls 1080
            push af		; Hyp.cls 1081
            ld e, a		; Hyp.cls 1082
            call asm_1_395_n_cn_wrow		; Hyp.cls 1083
            pop af		; Hyp.cls 1084
            jr asm_1_395_n_cn_eos_lp		; Hyp.cls 1085
asm_1_395_n_cn_eln:		; Hyp.cls 1086
            ld a, (#7683)		; Hyp.cls 1087
            ld e, a		; Hyp.cls 1088
            jp asm_1_395_n_cn_wrow		; Hyp.cls 1089
asm_1_395_n_cn_sol:		; Hyp.cls 1090
            ld a, (#7682)		; Hyp.cls 1091
            inc a		; Hyp.cls 1092
            ld b, a		; Hyp.cls 1093
            ld d, 0		; Hyp.cls 1094
            ld a, (#7683)		; Hyp.cls 1095
            ld e, a		; Hyp.cls 1096
            jp asm_1_395_n_cn_wipen		; Hyp.cls 1097
asm_1_395_n_cn_sos:		; Hyp.cls 1098
            call asm_1_395_n_cn_sol		; Hyp.cls 1099
            ld a, (#7683)		; Hyp.cls 1100
asm_1_395_n_cn_sos_lp:		; Hyp.cls 1101
            or a		; Hyp.cls 1102
            ret z		; Hyp.cls 1103
            dec a		; Hyp.cls 1104
            push af		; Hyp.cls 1105
            ld e, a		; Hyp.cls 1106
            call asm_1_395_n_cn_wrow		; Hyp.cls 1107
            pop af		; Hyp.cls 1108
            jr asm_1_395_n_cn_sos_lp		; Hyp.cls 1109
asm_1_395_n_cn_dell:		; Hyp.cls 1110
            xor a		; Hyp.cls 1111
            ld (#7682), a		; Hyp.cls 1112
            ld a, (#7683)		; Hyp.cls 1113
            ld b, a                 ; B: the row filled from the one below [1114]
asm_1_395_n_cn_dl_lp:		; Hyp.cls 1115
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 1116
            dec a		; Hyp.cls 1117
            cp b		; Hyp.cls 1118
            jr z, asm_1_395_n_cn_dl_end		; Hyp.cls 1119
            ld c, b		; Hyp.cls 1120
            inc c		; Hyp.cls 1121
            ld a, b		; Hyp.cls 1122
            push bc		; Hyp.cls 1123
            call asm_1_395_n_cn_cpr		; Hyp.cls 1124
            pop bc		; Hyp.cls 1125
            inc b		; Hyp.cls 1126
            jr asm_1_395_n_cn_dl_lp		; Hyp.cls 1127
asm_1_395_n_cn_dl_end:		; Hyp.cls 1128
            ld e, b		; Hyp.cls 1129
            call asm_1_395_n_cn_wrow            ; the last row blank [1130]
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 1131
            dec a		; Hyp.cls 1132
            ld c, a		; Hyp.cls 1133
            ld a, (#7683)		; Hyp.cls 1134
            jr asm_1_395_n_cn_redr		; Hyp.cls 1135
asm_1_395_n_cn_insl:		; Hyp.cls 1136
            xor a		; Hyp.cls 1137
            ld (#7682), a		; Hyp.cls 1138
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 1139
            dec a		; Hyp.cls 1140
            ld b, a                 ; B: the row filled from the one above [1141]
asm_1_395_n_cn_il_lp:		; Hyp.cls 1142
            ld a, (#7683)		; Hyp.cls 1143
            cp b		; Hyp.cls 1144
            jr z, asm_1_395_n_cn_il_end		; Hyp.cls 1145
            ld c, b		; Hyp.cls 1146
            dec c		; Hyp.cls 1147
            ld a, b		; Hyp.cls 1148
            push bc		; Hyp.cls 1149
            call asm_1_395_n_cn_cpr		; Hyp.cls 1150
            pop bc		; Hyp.cls 1151
            dec b		; Hyp.cls 1152
            jr asm_1_395_n_cn_il_lp		; Hyp.cls 1153
asm_1_395_n_cn_il_end:		; Hyp.cls 1154
            ld e, b		; Hyp.cls 1155
            call asm_1_395_n_cn_wrow            ; the cursor's row blank [1156]
            ld a, (asm_1_395_n_cn_r)		; Hyp.cls 1157
            ld c, a		; Hyp.cls 1158
            ld a, (#7683)		; Hyp.cls 1159
            inc a		; Hyp.cls 1160
; cn_redr: rows A to C - 1 drawn again from the page
asm_1_395_n_cn_redr:		; Hyp.cls 1162
            cp c		; Hyp.cls 1163
            ret nc		; Hyp.cls 1164
            push af		; Hyp.cls 1165
            push bc		; Hyp.cls 1166
            ld e, a		; Hyp.cls 1167
            ld d, 0		; Hyp.cls 1168
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1169
            ld b, a		; Hyp.cls 1170
            call asm_1_395_n_cn_drwn		; Hyp.cls 1171
            pop bc		; Hyp.cls 1172
            pop af		; Hyp.cls 1173
            inc a		; Hyp.cls 1174
            jr asm_1_395_n_cn_redr		; Hyp.cls 1175
; cn_cpr: the page's row C copied to its row A
asm_1_395_n_cn_cpr:		; Hyp.cls 1177
            push af		; Hyp.cls 1178
            ld a, c		; Hyp.cls 1179
            call asm_1_395_n_cn_rowa		; Hyp.cls 1180
            pop af		; Hyp.cls 1181
            push hl		; Hyp.cls 1182
            call asm_1_395_n_cn_rowa		; Hyp.cls 1183
            ex de, hl		; Hyp.cls 1184
            pop hl		; Hyp.cls 1185
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1186
            ld c, a		; Hyp.cls 1187
            ld b, 0		; Hyp.cls 1188
            ldir		; Hyp.cls 1189
            ret		; Hyp.cls 1190
; cn_wrow: row E blank; cn_wipen: B characters of row E from column D blank (B > 0) - in the page,
; then drawn (cn_drwn: B characters of row E from column D, from the page, when in front)
asm_1_395_n_cn_wrow:		; Hyp.cls 1193
            ld d, 0		; Hyp.cls 1194
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1195
            ld b, a		; Hyp.cls 1196
asm_1_395_n_cn_wipen:		; Hyp.cls 1197
            push de		; Hyp.cls 1198
            push bc		; Hyp.cls 1199
            ld a, e		; Hyp.cls 1200
            call asm_1_395_n_cn_rowa		; Hyp.cls 1201
            pop bc		; Hyp.cls 1202
            pop de		; Hyp.cls 1203
            push bc		; Hyp.cls 1204
            ld a, l		; Hyp.cls 1205
            add a, d		; Hyp.cls 1206
            ld l, a		; Hyp.cls 1207
            jr nc, asm_1_395_n_cn_wn_lp		; Hyp.cls 1208
            inc h		; Hyp.cls 1209
asm_1_395_n_cn_wn_lp:		; Hyp.cls 1210
            ld (hl), ' '		; Hyp.cls 1211
            inc hl		; Hyp.cls 1212
            djnz asm_1_395_n_cn_wn_lp		; Hyp.cls 1213
            pop bc		; Hyp.cls 1214
asm_1_395_n_cn_drwn:		; Hyp.cls 1215
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 1216
            or a		; Hyp.cls 1217
            ret z		; Hyp.cls 1218
            push de		; Hyp.cls 1219
            push bc		; Hyp.cls 1220
            ld a, e		; Hyp.cls 1221
            call asm_1_395_n_cn_rowa		; Hyp.cls 1222
            pop bc		; Hyp.cls 1223
            pop de		; Hyp.cls 1224
            ld a, l		; Hyp.cls 1225
            add a, d		; Hyp.cls 1226
            ld l, a		; Hyp.cls 1227
            jr nc, asm_1_395_n_cn_dw_p		; Hyp.cls 1228
            inc h		; Hyp.cls 1229
asm_1_395_n_cn_dw_p:                            ; the screen address worked out once, then stepped on (as [1230]
            push hl                 ; cn_print: a sum each character was a fifth of the time [1231]
            push bc                 ; a screen of text took - ESC K's) [1232]
            call asm_1_395_n_cn_scr		; Hyp.cls 1233
            pop bc		; Hyp.cls 1234
            pop de                  ; DE: the page's characters, HL the screen [1235]
asm_1_395_n_cn_dw_lp:		; Hyp.cls 1236
            ld a, (de)		; Hyp.cls 1237
            inc de		; Hyp.cls 1238
            push hl		; Hyp.cls 1239
            push de		; Hyp.cls 1240
            push bc		; Hyp.cls 1241
            call asm_1_395_n_cn_glyph8		; Hyp.cls 1242
            pop bc		; Hyp.cls 1243
            pop de		; Hyp.cls 1244
            pop hl		; Hyp.cls 1245
            call asm_1_395_n_cn_next		; Hyp.cls 1246
            djnz asm_1_395_n_cn_dw_lp		; Hyp.cls 1247
            ret		; Hyp.cls 1248

; ESC E: the page cleared, column, row and ring back to 0; the screen too if in front (written,
; not copied: the Library: ROM build may have the keyword ROM over it for reads)
asm_1_395_n_cn_clear:		; Hyp.cls 1252
            ld hl, #7700		; Hyp.cls 1253
            ld de, #7701		; Hyp.cls 1254
            ld (hl), ' '		; Hyp.cls 1255
            ld bc, 2047		; Hyp.cls 1256
            ldir		; Hyp.cls 1257
            xor a		; Hyp.cls 1258
            ld (#7682), a		; Hyp.cls 1259
            ld (#7683), a		; Hyp.cls 1260
            ld (#7684), a		; Hyp.cls 1261
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 1262
            or a		; Hyp.cls 1263
            ret z		; Hyp.cls 1264
            ld hl, 0		; Hyp.cls 1265
            ld (var_hyp_sco), hl		; Hyp.cls 1266
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen) [1267]
            call asm_1_395_n_cn_crtc		; Hyp.cls 1268
    IFDEF NTC_ZXN		; Hyp.cls 1269
            ld hl, #E000            ; zxn: clear the tilemap (80 x 32 = #E000-#E9FF) to blank (space) [1270]
            ld bc, 80 * 32		; Hyp.cls 1271
asm_1_395_n_cn_cle_zx:		; Hyp.cls 1272
            ld (hl), ' '		; Hyp.cls 1273
            inc hl		; Hyp.cls 1274
            dec bc		; Hyp.cls 1275
            ld a, b		; Hyp.cls 1276
            or c		; Hyp.cls 1277
            jr nz, asm_1_395_n_cn_cle_zx		; Hyp.cls 1278
    ELSE		; Hyp.cls 1279
            xor a		; Hyp.cls 1280
            ld hl, #C000		; Hyp.cls 1281
            ld c, #40		; Hyp.cls 1282
asm_1_395_n_cn_cl_l:		; Hyp.cls 1283
            ld b, 0		; Hyp.cls 1284
asm_1_395_n_cn_cl_b:		; Hyp.cls 1285
            ld (hl), a		; Hyp.cls 1286
            inc hl		; Hyp.cls 1287
            djnz asm_1_395_n_cn_cl_b		; Hyp.cls 1288
            dec c		; Hyp.cls 1289
            jr nz, asm_1_395_n_cn_cl_l		; Hyp.cls 1290
    ENDIF		; Hyp.cls 1291
; cn_strip: MODE S (the screen wider than the console): the status strip's 4 characters (#F68A)
; at the top of the columns right of the console
asm_1_395_n_cn_strip:		; Hyp.cls 1294
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 1295
            or a		; Hyp.cls 1296
            ret z		; Hyp.cls 1297
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1298
            ld d, a		; Hyp.cls 1299
            ld a, (var_hyp_scc)		; Hyp.cls 1300
            cp d		; Hyp.cls 1301
            ret z		; Hyp.cls 1302
            ret c		; Hyp.cls 1303
            ld e, 0		; Hyp.cls 1304
            ld hl, #768A		; Hyp.cls 1305
            ld b, 4		; Hyp.cls 1306
asm_1_395_n_cn_st_lp:		; Hyp.cls 1307
            ld a, (hl)		; Hyp.cls 1308
            push hl		; Hyp.cls 1309
            push de		; Hyp.cls 1310
            push bc		; Hyp.cls 1311
            call asm_1_395_n_cn_glyph		; Hyp.cls 1312
            pop bc		; Hyp.cls 1313
            pop de		; Hyp.cls 1314
            pop hl		; Hyp.cls 1315
            inc hl		; Hyp.cls 1316
            inc d		; Hyp.cls 1317
            djnz asm_1_395_n_cn_st_lp		; Hyp.cls 1318
            jp asm_1_395_n_cn_net                       ; then the network indicator, two rows down [1319]

; cn_net: the network indicator - the status strip's row 2 (row 1 left blank under [1]). 'N' when
; the network's up and idle; it blinks N / blank while there's traffic (nta, counted down by the
; 0.5s cursor-flash tick); the cell is left BLANK when the network's off, so nothing shows until a
; network is turned on (the screen is unchanged from before this feature). The cell is system-wide
; (not a slot's), so its state is in class vars (ntu / nta / ntb), reachable from the NET service
asm_1_395_n_cn_net:		; Hyp.cls 1326
            ld a, (asm_1_395_n_cn_front)		; Hyp.cls 1327
            or a		; Hyp.cls 1328
            ret z		; Hyp.cls 1329
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1330
            ld d, a		; Hyp.cls 1331
            ld a, (var_hyp_scc)		; Hyp.cls 1332
            cp d		; Hyp.cls 1333
            ret z		; Hyp.cls 1334
            ret c		; Hyp.cls 1335
            ld hl, asm_1_395_n_cn_nblk                  ; the network's off: a blank cell (nothing shown) [1336]
            ld a, (var_hyp_ntu)		; Hyp.cls 1337
            or a		; Hyp.cls 1338
            jr z, asm_1_395_n_cn_net_draw		; Hyp.cls 1339
            ld a, (var_hyp_nta)                   ; up: steady 'N', or blank on the odd blink while busy [1340]
            or a		; Hyp.cls 1341
            ld a, 78		; Hyp.cls 1342
            jr z, asm_1_395_n_cn_net_put		; Hyp.cls 1343
            ld a, (var_hyp_ntb)		; Hyp.cls 1344
            and 1		; Hyp.cls 1345
            ld a, 78		; Hyp.cls 1346
            jr z, asm_1_395_n_cn_net_put		; Hyp.cls 1347
            ld a, 32		; Hyp.cls 1348
asm_1_395_n_cn_net_put:		; Hyp.cls 1349
            ld (asm_1_395_n_cn_nbuf + 1), a		; Hyp.cls 1350
            ld hl, asm_1_395_n_cn_nbuf		; Hyp.cls 1351
asm_1_395_n_cn_net_draw:		; Hyp.cls 1352
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1353
            ld d, a                         ; the first strip column [1354]
            ld e, 2                         ; row 2 (row 1 blank, under [1] at row 0) [1355]
            ld b, 4		; Hyp.cls 1356
asm_1_395_n_cn_net_lp:		; Hyp.cls 1357
            ld a, (hl)		; Hyp.cls 1358
            push hl		; Hyp.cls 1359
            push de		; Hyp.cls 1360
            push bc		; Hyp.cls 1361
            call asm_1_395_n_cn_glyph		; Hyp.cls 1362
            pop bc		; Hyp.cls 1363
            pop de		; Hyp.cls 1364
            pop hl		; Hyp.cls 1365
            inc hl		; Hyp.cls 1366
            inc d		; Hyp.cls 1367
            djnz asm_1_395_n_cn_net_lp		; Hyp.cls 1368
            ret		; Hyp.cls 1369
asm_1_395_n_cn_nbuf:    db 91, 78, 93, 32               ; "[N] " when up; +1 overwritten with N / blank (blink) [1370]
asm_1_395_n_cn_nblk:    db 32, 32, 32, 32               ; a blank cell (network off: nothing shown) [1371]

; cn_crtc: the screen's start (sco, bytes) to the CRTC: R12 = #30 + its words' high 2 bits, R13
; the low 8 (#C000, MA10 / MA11 clear: kept within 2K, never the carry into the next 16K)
asm_1_395_n_cn_crtc:		; Hyp.cls 1375
    IFDEF NTC_ZXN		; Hyp.cls 1376
            ret                     ; zxn: no CRTC hardware scroll (the tilemap is the screen) [1377]
    ENDIF		; Hyp.cls 1378
            ld hl, (var_hyp_sco)		; Hyp.cls 1379
            srl h		; Hyp.cls 1380
            rr l		; Hyp.cls 1381
            ld a, h		; Hyp.cls 1382
            and 3		; Hyp.cls 1383
            or #30		; Hyp.cls 1384
            ld bc, #BC0C		; Hyp.cls 1385
            out (c), c		; Hyp.cls 1386
            inc b		; Hyp.cls 1387
            out (c), a		; Hyp.cls 1388
            ld bc, #BC0D		; Hyp.cls 1389
            out (c), c		; Hyp.cls 1390
            inc b		; Hyp.cls 1391
            out (c), l		; Hyp.cls 1392
            ret		; Hyp.cls 1393
    IFDEF NTC_ZXN		; Hyp.cls 1394
; zxn_winpg: C = a slot's bank index (1-based) -> its page-3 16K (the 4th of the 64K bank) into
; the window #4000-#7FFF (MMU slots 2, 3). The CPC pages page 3 in with out (c),c; this is the
; MMU equivalent. Keeps HL; clobbers A, BC, DE.
; zxn_winpg: C = a slot's bank index (1-based) -> its page-3 16K into the window (MMU slots 2, 3).
; The CPC pages page 3 in with out (c),c; this is the MMU equivalent. Keeps HL; clobbers A, BC, DE.
asm_1_395_n_zxn_winpg:		; Hyp.cls 1400
            ld a, c		; Hyp.cls 1401
            dec a		; Hyp.cls 1402
            add a, a		; Hyp.cls 1403
            add a, a                ; (index - 1) * 4 [1404]
            add a, ZXN_FIRSTBANK + 3 ; + the 4th 16K bank = page 3 [1405]
            add a, a                ; * 2 = its first 8K page [1406]
            ld e, a		; Hyp.cls 1407
            ld bc, #243B		; Hyp.cls 1408
            ld a, #52		; Hyp.cls 1409
            ld (ntc_zxsel), a		; Hyp.cls 1410
            out (c), a		; Hyp.cls 1411
            inc b		; Hyp.cls 1412
            out (c), e              ; MMU slot 2 = the page [1413]
            dec b		; Hyp.cls 1414
            ld a, #53		; Hyp.cls 1415
            ld (ntc_zxsel), a		; Hyp.cls 1416
            out (c), a		; Hyp.cls 1417
            inc b		; Hyp.cls 1418
            inc e		; Hyp.cls 1419
            out (c), e              ; MMU slot 3 = page + 1 [1420]
            ret		; Hyp.cls 1421
    ENDIF		; Hyp.cls 1422

; cn_rowa: A = row of the screen -> HL = its row in the page ring (#7700 + ((top + A) mod rows)
; * columns)
asm_1_395_n_cn_rowa:		; Hyp.cls 1426
            ld hl, #7684		; Hyp.cls 1427
            add a, (hl)		; Hyp.cls 1428
            ld hl, asm_1_395_n_cn_r		; Hyp.cls 1429
            cp (hl)		; Hyp.cls 1430
            jr c, asm_1_395_n_cn_ra_in		; Hyp.cls 1431
            sub (hl)		; Hyp.cls 1432
asm_1_395_n_cn_ra_in:		; Hyp.cls 1433
            ld e, a		; Hyp.cls 1434
            ld a, (asm_1_395_n_cn_c)		; Hyp.cls 1435
            call asm_1_395_n_cn_mul		; Hyp.cls 1436
            ld de, #7700		; Hyp.cls 1437
            add hl, de		; Hyp.cls 1438
            ret		; Hyp.cls 1439

; cn_mul: HL = A * E (BC kept; D = 0 after)
asm_1_395_n_cn_mul:		; Hyp.cls 1442
            push bc		; Hyp.cls 1443
            ld hl, 0		; Hyp.cls 1444
            ld d, 0		; Hyp.cls 1445
            ld b, 8		; Hyp.cls 1446
asm_1_395_n_cn_mu_lp:		; Hyp.cls 1447
            add hl, hl		; Hyp.cls 1448
            rlca		; Hyp.cls 1449
            jr nc, asm_1_395_n_cn_mu_n		; Hyp.cls 1450
            add hl, de		; Hyp.cls 1451
asm_1_395_n_cn_mu_n:		; Hyp.cls 1452
            djnz asm_1_395_n_cn_mu_lp		; Hyp.cls 1453
            pop bc		; Hyp.cls 1454
            ret		; Hyp.cls 1455

; cn_next: HL = the next screen byte: + 1 within its 2K line block (BC kept)
asm_1_395_n_cn_next:		; Hyp.cls 1458
    IFDEF NTC_ZXN		; Hyp.cls 1459
            inc l                   ; ZX Next: the tilemap is linear - plain 16-bit increment [1460]
            ret nz		; Hyp.cls 1461
            inc h		; Hyp.cls 1462
            ret		; Hyp.cls 1463
    ENDIF		; Hyp.cls 1464
            inc l		; Hyp.cls 1465
            ret nz		; Hyp.cls 1466
            ld a, h		; Hyp.cls 1467
            inc a		; Hyp.cls 1468
            and #07		; Hyp.cls 1469
            push bc		; Hyp.cls 1470
            ld c, a		; Hyp.cls 1471
            ld a, h		; Hyp.cls 1472
            and #F8		; Hyp.cls 1473
            or c		; Hyp.cls 1474
            ld h, a		; Hyp.cls 1475
            pop bc		; Hyp.cls 1476
            ret		; Hyp.cls 1477

; cn_glyph: A = character, D = column, E = row: drawn (cn_show)
asm_1_395_n_cn_glyph:		; Hyp.cls 1480
            push af		; Hyp.cls 1481
            call asm_1_395_n_cn_scr		; Hyp.cls 1482
            pop af		; Hyp.cls 1483
; cn_glyph8: A = character, HL = its screen address: its 8 bytes into screen memory (mode 2, pen
; 1 on paper 0), one per pixel line (#800 apart; unrolled)
asm_1_395_n_cn_glyph8:		; Hyp.cls 1486
    IFDEF NTC_ZXN		; Hyp.cls 1487
            ; ZX Next: write the character code straight to the tilemap cell - its tile IS that
            ; glyph (ntc_plat_mode loaded the font into the tiles). HL = cn_scr's tilemap address
            ; (#E000 + row*scc + col), scc = 80. This is the 80-column text console.
            ; The Layer 2 bitmap blit (cn_l2b, below) is kept for the 40-column graphics modes.
            ld (hl), a		; Hyp.cls 1492
            ret		; Hyp.cls 1493
asm_1_395_n_cn_l2ch:    db 0		; Hyp.cls 1494
; cn_l2b - A = character, D = col (0-39), E = row (0-31): 8x8 font cell blitted into Layer 2
; (320 x 256, column by column: byte at x*256+y). Page = 24 + D/4 into slot 6; high byte base
; = #C0 + (D and 3)*8; low byte = E*8 + font row. White (#FF) where the font bit is set, else 0.
asm_1_395_n_cn_l2b:		; Hyp.cls 1498
            push iy		; Hyp.cls 1499
            push ix		; Hyp.cls 1500
            sub 32		; Hyp.cls 1501
            jr nc, asm_1_395_n_cn_l2_ok		; Hyp.cls 1502
            xor a		; Hyp.cls 1503
asm_1_395_n_cn_l2_ok:		; Hyp.cls 1504
            cp 95		; Hyp.cls 1505
            jr c, asm_1_395_n_cn_l2_g		; Hyp.cls 1506
            ld a, '?' - 32		; Hyp.cls 1507
asm_1_395_n_cn_l2_g:		; Hyp.cls 1508
            ld l, a                 ; font src = ntc_zxfont + a*8 [1509]
            ld h, 0		; Hyp.cls 1510
            add hl, hl		; Hyp.cls 1511
            add hl, hl		; Hyp.cls 1512
            add hl, hl		; Hyp.cls 1513
            ld bc, ntc_zxfont		; Hyp.cls 1514
            add hl, bc		; Hyp.cls 1515
            push hl		; Hyp.cls 1516
            ld a, d                 ; page = 24 + D/4 -> slot 6 [1517]
            srl a		; Hyp.cls 1518
            srl a		; Hyp.cls 1519
            add a, 24		; Hyp.cls 1520
            call gfx_map		; Hyp.cls 1521
            ld a, d                 ; high byte base = #C0 + (D and 3)*8 [1522]
            and 3		; Hyp.cls 1523
            add a, a		; Hyp.cls 1524
            add a, a		; Hyp.cls 1525
            add a, a		; Hyp.cls 1526
            add a, #C0		; Hyp.cls 1527
            ld c, a                 ; C = base high byte (leftmost pixel column of the cell) [1528]
            ld a, e                 ; low base = E*8 [1529]
            add a, a		; Hyp.cls 1530
            add a, a		; Hyp.cls 1531
            add a, a		; Hyp.cls 1532
            ld b, a                 ; B = E*8 (low byte base, += font row below) [1533]
            pop hl                  ; font ptr [1534]
            ld iy, 0		; Hyp.cls 1535
asm_1_395_n_cn_l2_row:		; Hyp.cls 1536
            ld a, (hl)              ; font byte (bit 7 leftmost) [1537]
            inc hl		; Hyp.cls 1538
            ld d, a		; Hyp.cls 1539
            ld e, 8                 ; 8 pixels across [1540]
            ld a, c		; Hyp.cls 1541
            ld (asm_1_395_n_cn_l2_h + 2), a     ; high byte = leftmost column of this cell [1542]
            push bc		; Hyp.cls 1543
asm_1_395_n_cn_l2_col:		; Hyp.cls 1544
            sla d                   ; top bit -> carry [1545]
            ld a, 0		; Hyp.cls 1546
            jr nc, asm_1_395_n_cn_l2_pap		; Hyp.cls 1547
            ld a, #FF		; Hyp.cls 1548
asm_1_395_n_cn_l2_pap:		; Hyp.cls 1549
            push hl		; Hyp.cls 1550
asm_1_395_n_cn_l2_h:		; Hyp.cls 1551
            ld hl, #C000            ; (high byte self-modified; low set next) [1552]
            ld l, b                 ; low byte = E*8 + font row [1553]
            ld (hl), a		; Hyp.cls 1554
            pop hl		; Hyp.cls 1555
            ld a, (asm_1_395_n_cn_l2_h + 2)     ; next pixel column: high byte += 1 [1556]
            inc a		; Hyp.cls 1557
            ld (asm_1_395_n_cn_l2_h + 2), a		; Hyp.cls 1558
            dec e		; Hyp.cls 1559
            jr nz, asm_1_395_n_cn_l2_col		; Hyp.cls 1560
            pop bc		; Hyp.cls 1561
            inc b                   ; next font row: low byte += 1 [1562]
            inc iyl		; Hyp.cls 1563
            ld a, iyl		; Hyp.cls 1564
            cp 8		; Hyp.cls 1565
            jr c, asm_1_395_n_cn_l2_row		; Hyp.cls 1566
            pop ix		; Hyp.cls 1567
            pop iy		; Hyp.cls 1568
            ret		; Hyp.cls 1569
    ENDIF		; Hyp.cls 1570
            sub 32		; Hyp.cls 1571
            cp 96		; Hyp.cls 1572
            jr c, asm_1_395_n_cn_gl_ok		; Hyp.cls 1573
            ld a, '?' - 32		; Hyp.cls 1574
asm_1_395_n_cn_gl_ok:		; Hyp.cls 1575
            push hl		; Hyp.cls 1576
            ld l, a		; Hyp.cls 1577
            ld h, 0		; Hyp.cls 1578
            add hl, hl		; Hyp.cls 1579
            add hl, hl		; Hyp.cls 1580
            add hl, hl		; Hyp.cls 1581
            ld de, 62208 - #8000   ; (the bank's page 3 in the window: FONT - #C000 + #4000) [1582]
            add hl, de		; Hyp.cls 1583
            ex de, hl               ; DE = its matrix [1584]
            pop hl		; Hyp.cls 1585
            ld a, (de)		; Hyp.cls 1586
            ld (hl), a		; Hyp.cls 1587
            inc de		; Hyp.cls 1588
            ld a, h		; Hyp.cls 1589
            add a, 8		; Hyp.cls 1590
            ld h, a		; Hyp.cls 1591
            ld a, (de)		; Hyp.cls 1592
            ld (hl), a		; Hyp.cls 1593
            inc de		; Hyp.cls 1594
            ld a, h		; Hyp.cls 1595
            add a, 8		; Hyp.cls 1596
            ld h, a		; Hyp.cls 1597
            ld a, (de)		; Hyp.cls 1598
            ld (hl), a		; Hyp.cls 1599
            inc de		; Hyp.cls 1600
            ld a, h		; Hyp.cls 1601
            add a, 8		; Hyp.cls 1602
            ld h, a		; Hyp.cls 1603
            ld a, (de)		; Hyp.cls 1604
            ld (hl), a		; Hyp.cls 1605
            inc de		; Hyp.cls 1606
            ld a, h		; Hyp.cls 1607
            add a, 8		; Hyp.cls 1608
            ld h, a		; Hyp.cls 1609
            ld a, (de)		; Hyp.cls 1610
            ld (hl), a		; Hyp.cls 1611
            inc de		; Hyp.cls 1612
            ld a, h		; Hyp.cls 1613
            add a, 8		; Hyp.cls 1614
            ld h, a		; Hyp.cls 1615
            ld a, (de)		; Hyp.cls 1616
            ld (hl), a		; Hyp.cls 1617
            inc de		; Hyp.cls 1618
            ld a, h		; Hyp.cls 1619
            add a, 8		; Hyp.cls 1620
            ld h, a		; Hyp.cls 1621
            ld a, (de)		; Hyp.cls 1622
            ld (hl), a		; Hyp.cls 1623
            inc de		; Hyp.cls 1624
            ld a, h		; Hyp.cls 1625
            add a, 8		; Hyp.cls 1626
            ld h, a		; Hyp.cls 1627
            ld a, (de)		; Hyp.cls 1628
            ld (hl), a		; Hyp.cls 1629
            ret		; Hyp.cls 1630
; cn_scr: D = column, E = row -> HL = the screen address: the screen's start (sco) + row *
; columns (scc) + column, within each 2K line block, at #C000
asm_1_395_n_cn_scr:		; Hyp.cls 1633
            push de		; Hyp.cls 1634
            ld a, (var_hyp_scc)		; Hyp.cls 1635
            call asm_1_395_n_cn_mul		; Hyp.cls 1636
            pop de		; Hyp.cls 1637
            ld c, d		; Hyp.cls 1638
            ld b, 0		; Hyp.cls 1639
            add hl, bc		; Hyp.cls 1640
    IFDEF NTC_ZXN		; Hyp.cls 1641
            ld bc, #E000            ; ZX Next: the tilemap, linear (#E000 + row * cols + col) [1642]
            add hl, bc		; Hyp.cls 1643
            ret		; Hyp.cls 1644
    ENDIF		; Hyp.cls 1645
            ld bc, (var_hyp_sco)		; Hyp.cls 1646
            add hl, bc		; Hyp.cls 1647
            ld a, h		; Hyp.cls 1648
            and #07		; Hyp.cls 1649
            or #C0		; Hyp.cls 1650
            ld h, a		; Hyp.cls 1651
            ret		; Hyp.cls 1652
asm_1_395_n_cn_cuxor:                           ; the cursor's underline XORed at cn_ca, on <-> off [1653]
    IFDEF NTC_ZXN		; Hyp.cls 1654
            ld a, (var_hyp_ccu)           ; zxn: no tile cursor for now (bitmap) - just track on/off [1655]
            xor 1		; Hyp.cls 1656
            ld (var_hyp_ccu), a		; Hyp.cls 1657
            ret		; Hyp.cls 1658
    ENDIF		; Hyp.cls 1659
            ld hl, (asm_1_395_n_cn_ca)		; Hyp.cls 1660
            ld a, (hl)		; Hyp.cls 1661
            cpl		; Hyp.cls 1662
            ld (hl), a		; Hyp.cls 1663
            ld a, (var_hyp_ccu)		; Hyp.cls 1664
            xor 1		; Hyp.cls 1665
            ld (var_hyp_ccu), a		; Hyp.cls 1666
            ret		; Hyp.cls 1667
asm_1_395_n_cn_was:     db 0		; Hyp.cls 1668
asm_1_395_n_cn_ca:      dw 0		; Hyp.cls 1669
asm_1_395_n_cn_front:   db 0		; Hyp.cls 1670
asm_1_395_n_cn_c:       db 80                   ; the slot's columns, rows [1671]
asm_1_395_n_cn_r:       db 25		; Hyp.cls 1672
asm_1_395_n_cn_pv:      db 0                    ; cn_pp / cn_sp valid (0: the cursor moved) [1673]
asm_1_395_n_cn_pp:      dw 0                    ; the page byte for the next character [1674]
asm_1_395_n_cn_sp:      dw 0                    ; its screen address [1675]
asm_1_395_n_cn_left:    dw 0		; Hyp.cls 1676
asm_1_395_n_cn_ptr:     dw 0		; Hyp.cls 1677
            IF asm_1_395_n_CN_SB		; Hyp.cls 1678
asm_1_395_n_cn_pg:      dw 0                    ; the slot's page 3 setting (pg) [1679]
asm_1_395_n_cn_h1:      dw 0                    ; cn_hcp: from (its setting, address), to, 8-byte runs left [1680]
asm_1_395_n_cn_hs:      dw 0		; Hyp.cls 1681
asm_1_395_n_cn_h2:      dw 0		; Hyp.cls 1682
asm_1_395_n_cn_hd:      dw 0		; Hyp.cls 1683
asm_1_395_n_cn_hn:      db 0		; Hyp.cls 1684
            ENDIF		; Hyp.cls 1685
asm_1_395_n_cn_end:		; Hyp.cls 1686
			ret			; end of #asm

asm_1_1694_n:		; #asm, Hyp.cls line 1694 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 1695
            ld sp, (ntc_csp)		; Hyp.cls 1696
            ld bc, (var_hyp_hps)          ; the hypervisor's page in the window: the font [1697]
            out (c), c		; Hyp.cls 1698
            ld hl, (var_hyp_sco)          ; the screen's start (TOP is shown in MODE 2: 80 columns) [1699]
            ld (asm_1_1694_n_sy_off), hl		; Hyp.cls 1700
            ld hl, (var_hyp_say_p)		; Hyp.cls 1701
            ld a, (var_hyp_say_n)		; Hyp.cls 1702
            ld b, a		; Hyp.cls 1703
            ld a, (var_hyp_say_col)		; Hyp.cls 1704
            ld d, a		; Hyp.cls 1705
            ld a, (var_hyp_say_row)		; Hyp.cls 1706
            ld e, a		; Hyp.cls 1707
            inc b		; Hyp.cls 1708
asm_1_1694_n_sy_lp:		; Hyp.cls 1709
            dec b		; Hyp.cls 1710
            jr z, asm_1_1694_n_sy_done		; Hyp.cls 1711
            ld a, d		; Hyp.cls 1712
            cp 80		; Hyp.cls 1713
            jr nc, asm_1_1694_n_sy_done		; Hyp.cls 1714
            ld a, (hl)		; Hyp.cls 1715
            inc hl		; Hyp.cls 1716
            push hl		; Hyp.cls 1717
            push bc		; Hyp.cls 1718
            push de		; Hyp.cls 1719
            sub 32                  ; the character's matrix [1720]
            cp 96		; Hyp.cls 1721
            jr c, asm_1_1694_n_sy_ok		; Hyp.cls 1722
            ld a, '?' - 32		; Hyp.cls 1723
asm_1_1694_n_sy_ok:		; Hyp.cls 1724
            ld l, a		; Hyp.cls 1725
            ld h, 0		; Hyp.cls 1726
            add hl, hl		; Hyp.cls 1727
            add hl, hl		; Hyp.cls 1728
            add hl, hl		; Hyp.cls 1729
            ld bc, #4000 + 4096  ; (the hypervisor's page in the window) [1730]
            add hl, bc		; Hyp.cls 1731
            push hl		; Hyp.cls 1732
            ld l, e                 ; its screen address: start + row * 80 + column, in 2K [1733]
            ld h, 0		; Hyp.cls 1734
            add hl, hl		; Hyp.cls 1735
            add hl, hl		; Hyp.cls 1736
            add hl, hl		; Hyp.cls 1737
            add hl, hl		; Hyp.cls 1738
            push hl		; Hyp.cls 1739
            add hl, hl		; Hyp.cls 1740
            add hl, hl		; Hyp.cls 1741
            pop bc		; Hyp.cls 1742
            add hl, bc		; Hyp.cls 1743
            ld c, d		; Hyp.cls 1744
            ld b, 0		; Hyp.cls 1745
            add hl, bc		; Hyp.cls 1746
            ld bc, (asm_1_1694_n_sy_off)		; Hyp.cls 1747
            add hl, bc		; Hyp.cls 1748
            ld a, h		; Hyp.cls 1749
            and #07		; Hyp.cls 1750
            or #C0		; Hyp.cls 1751
            ld h, a		; Hyp.cls 1752
            pop de		; Hyp.cls 1753
            ld b, 8		; Hyp.cls 1754
asm_1_1694_n_sy_ln:		; Hyp.cls 1755
            ld a, (de)		; Hyp.cls 1756
            ld (hl), a		; Hyp.cls 1757
            inc de		; Hyp.cls 1758
            ld a, h		; Hyp.cls 1759
            add a, 8		; Hyp.cls 1760
            ld h, a		; Hyp.cls 1761
            djnz asm_1_1694_n_sy_ln		; Hyp.cls 1762
            pop de		; Hyp.cls 1763
            pop bc		; Hyp.cls 1764
            pop hl		; Hyp.cls 1765
            inc d		; Hyp.cls 1766
            jr asm_1_1694_n_sy_lp		; Hyp.cls 1767
asm_1_1694_n_sy_done:		; Hyp.cls 1768
            ld bc, (ntc_rampt)		; Hyp.cls 1769
            out (c), c		; Hyp.cls 1770
            ld sp, (var_hyp_hsp)		; Hyp.cls 1771
            jr asm_1_1694_n_sy_end		; Hyp.cls 1772
asm_1_1694_n_sy_off:     dw 0		; Hyp.cls 1773
asm_1_1694_n_sy_end:		; Hyp.cls 1774
			ret			; end of #asm

asm_1_1788_n:		; #asm, Hyp.cls line 1788 (normal)
            ld (var_hyp_hsp), sp          ; (the real stack: SP is the thread) [1789]
            ld sp, (ntc_csp)		; Hyp.cls 1790
            xor a		; Hyp.cls 1791
            ld (var_hyp_ccu), a           ; (the screen cleared: no cursor on it) [1792]
            ld a, (var_hyp_scr_m)		; Hyp.cls 1793
            cp 6		; Hyp.cls 1794
            jr c, asm_1_1788_n_sm_ok		; Hyp.cls 1795
            xor a		; Hyp.cls 1796
asm_1_1788_n_sm_ok:		; Hyp.cls 1797
            ld l, a                 ; the mode's row of the table (6 bytes) [1798]
            add a, a		; Hyp.cls 1799
            add a, l		; Hyp.cls 1800
            add a, a		; Hyp.cls 1801
            ld e, a		; Hyp.cls 1802
            ld d, 0		; Hyp.cls 1803
            ld hl, asm_1_1788_n_sm_tab		; Hyp.cls 1804
    IFDEF NTC_ZXN		; Hyp.cls 1805
            ld hl, asm_1_1788_n_zxn_sm_tab       ; zxn: the Layer 2 bitmap is 40 x 32, so every mode is 40 x 32 [1806]
    ENDIF		; Hyp.cls 1807
            add hl, de		; Hyp.cls 1808
            ld a, (var_hyp_scr_k)		; Hyp.cls 1809
            or a		; Hyp.cls 1810
            jr z, asm_1_1788_n_sm_cols		; Hyp.cls 1811
            dec a		; Hyp.cls 1812
            jr z, asm_1_1788_n_sm_rows		; Hyp.cls 1813
            push hl                 ; 2: the screen [1814]
            ld e, (hl)              ; its columns [1815]
            ld d, 0		; Hyp.cls 1816
            ld (var_hyp_scc), de		; Hyp.cls 1817
            srl e		; Hyp.cls 1818
            ld (var_hyp_scw), de		; Hyp.cls 1819
            ld hl, 0		; Hyp.cls 1820
            ld (var_hyp_sco), hl		; Hyp.cls 1821
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen) [1822]
            pop hl		; Hyp.cls 1823
    IFNDEF NTC_ZXN		; Hyp.cls 1824
            inc hl		; Hyp.cls 1825
            inc hl                  ; R1, R2, R6, R7 [1826]
            di		; Hyp.cls 1827
            ld d, 1		; Hyp.cls 1828
            call asm_1_1788_n_sm_crtc		; Hyp.cls 1829
            ld d, 2		; Hyp.cls 1830
            call asm_1_1788_n_sm_crtc		; Hyp.cls 1831
            ld d, 6		; Hyp.cls 1832
            call asm_1_1788_n_sm_crtc		; Hyp.cls 1833
            ld d, 7		; Hyp.cls 1834
            call asm_1_1788_n_sm_crtc		; Hyp.cls 1835
            ld hl, asm_1_1788_n_sm_start         ; R12, R13: #C000 [1836]
            ld d, 12		; Hyp.cls 1837
            call asm_1_1788_n_sm_crtc		; Hyp.cls 1838
            ld d, 13		; Hyp.cls 1839
            call asm_1_1788_n_sm_crtc		; Hyp.cls 1840
            xor a                   ; cleared (written, not copied: the Library: ROM build may [1841]
            ld hl, #C000            ; have the keyword ROM over it for reads) [1842]
            ld c, #40		; Hyp.cls 1843
asm_1_1788_n_sm_cl:		; Hyp.cls 1844
            ld b, 0		; Hyp.cls 1845
asm_1_1788_n_sm_cl1:		; Hyp.cls 1846
            ld (hl), a		; Hyp.cls 1847
            inc hl		; Hyp.cls 1848
            djnz asm_1_1788_n_sm_cl1		; Hyp.cls 1849
            dec c		; Hyp.cls 1850
            jr nz, asm_1_1788_n_sm_cl		; Hyp.cls 1851
    ENDIF                           ; zxn: no CRTC, no #C000 screen clear (the tilemap is the screen) [1852]
            ld hl, 0		; Hyp.cls 1853
            jr asm_1_1788_n_sm_res		; Hyp.cls 1854
asm_1_1788_n_sm_cols:		; Hyp.cls 1855
            ld a, (hl)              ; the console's: the screen's, less the status strip's 4 (S) [1856]
            inc hl		; Hyp.cls 1857
            sub (hl)		; Hyp.cls 1858
            jr asm_1_1788_n_sm_a		; Hyp.cls 1859
asm_1_1788_n_sm_rows:		; Hyp.cls 1860
            inc hl		; Hyp.cls 1861
            inc hl		; Hyp.cls 1862
            inc hl		; Hyp.cls 1863
            inc hl		; Hyp.cls 1864
            ld a, (hl)		; Hyp.cls 1865
asm_1_1788_n_sm_a:		; Hyp.cls 1866
            ld l, a		; Hyp.cls 1867
            ld h, 0		; Hyp.cls 1868
asm_1_1788_n_sm_res:		; Hyp.cls 1869
            ld (var_hyp_scr_scr), hl		; Hyp.cls 1870
            ld sp, (var_hyp_hsp)		; Hyp.cls 1871
            ret                     ; (on with the thread) [1872]
asm_1_1788_n_sm_crtc:                            ; CRTC register D = (HL), HL on [1873]
            ld bc, #BC00		; Hyp.cls 1874
            out (c), d		; Hyp.cls 1875
            ld b, #BD		; Hyp.cls 1876
            ld a, (hl)		; Hyp.cls 1877
            out (c), a		; Hyp.cls 1878
            inc hl		; Hyp.cls 1879
            ret		; Hyp.cls 1880
asm_1_1788_n_sm_start:   db #30, 0		; Hyp.cls 1881
; columns, the status strip's, R1 (words a row), R2 (horizontal sync), R6 (rows), R7 (vertical sync)
asm_1_1788_n_sm_tab:     db 80, 0, 40, 46, 25, 30		; Hyp.cls 1883
            db 84, 4, 42, 47, 24, 30		; Hyp.cls 1884
            db 88, 0, 44, 48, 23, 29		; Hyp.cls 1885
            db 96, 0, 48, 50, 21, 28		; Hyp.cls 1886
            db 64, 0, 32, 42, 32, 34		; Hyp.cls 1887
            db 84, 0, 42, 47, 24, 30		; Hyp.cls 1888
    IFDEF NTC_ZXN		; Hyp.cls 1889
; zxn: Layer 2 bitmap 40 x 32. cols, status strip, (R1 R2 unused), rows, (R7 unused). scc = 40.
asm_1_1788_n_zxn_sm_tab: db 80, 0, 0, 0, 25, 0   ; MODE 2  80 x 25 (tilemap text - the 80-column console) [1891]
            db 40, 4, 0, 0, 32, 0   ; MODE S  console 36 + 4 status [1892]
            db 40, 0, 0, 0, 32, 0   ; MODE W [1893]
            db 40, 0, 0, 0, 32, 0   ; MODE UW [1894]
            db 40, 0, 0, 0, 32, 0   ; MODE P [1895]
            db 40, 0, 0, 0, 32, 0   ; MODE F [1896]
    ENDIF		; Hyp.cls 1897
			ret			; end of #asm

asm_1_1904_n:		; #asm, Hyp.cls line 1904 (normal)
    IFDEF NTC_ZXN		; Hyp.cls 1905
            ret                     ; ZX Next: no CPC firmware key-repeat (platform-specific) [1906]
    ENDIF		; Hyp.cls 1907
            ld (var_hyp_hsp), sp		; Hyp.cls 1908
            ld sp, (ntc_csp)		; Hyp.cls 1909
            call #BB42              ; KM GET DELAY: H the start delay, L the repeat [1910]
            di		; Hyp.cls 1911
            ld a, h		; Hyp.cls 1912
            call asm_1_1904_n_kr_mul		; Hyp.cls 1913
            ld h, a		; Hyp.cls 1914
            ld a, l		; Hyp.cls 1915
            call asm_1_1904_n_kr_mul		; Hyp.cls 1916
            ld l, a		; Hyp.cls 1917
            call #BB3F              ; KM SET DELAY [1918]
            di		; Hyp.cls 1919
            ld sp, (var_hyp_hsp)		; Hyp.cls 1920
            jr asm_1_1904_n_kr_end		; Hyp.cls 1921
asm_1_1904_n_kr_mul:                             ; A = A x f, 255 at most (0: 256 to the firmware - kept) [1922]
            or a		; Hyp.cls 1923
            ret z		; Hyp.cls 1924
            push hl		; Hyp.cls 1925
            ld e, a		; Hyp.cls 1926
            ld d, 0		; Hyp.cls 1927
            ld hl, 0		; Hyp.cls 1928
            ld a, (var_hyp_keyrep_f)		; Hyp.cls 1929
            ld b, a		; Hyp.cls 1930
asm_1_1904_n_kr_lp:		; Hyp.cls 1931
            add hl, de		; Hyp.cls 1932
            djnz asm_1_1904_n_kr_lp		; Hyp.cls 1933
            ld a, h		; Hyp.cls 1934
            or a		; Hyp.cls 1935
            ld a, l		; Hyp.cls 1936
            pop hl		; Hyp.cls 1937
            ret z		; Hyp.cls 1938
            ld a, 255		; Hyp.cls 1939
            ret		; Hyp.cls 1940
asm_1_1904_n_kr_end:		; Hyp.cls 1941
			ret			; end of #asm

asm_1_1971_n:		; #asm, Hyp.cls line 1971 (normal)
            ld (var_hyp_sps), sp		; Hyp.cls 1972
            ld sp, (ntc_csp)		; Hyp.cls 1973
    IFNDEF NTC_ZXN		; Hyp.cls 1974
            call #B903              ; KL U ROM DISABLE: the task's top 16K, not a ROM (Library: [1975]
    ELSE		; Hyp.cls 1976
            xor a                   ; zxn: no ROMs to disable [1977]
    ENDIF		; Hyp.cls 1978
            di                      ; ROM has the keyword ROM on), while it runs [1979]
            ld (var_hyp_rrom), a		; Hyp.cls 1980
            ld a, 6		; Hyp.cls 1981
            ld (var_hyp_slc), a		; Hyp.cls 1982
            ld a, 1                 ; from BASIC: it has taken the characters (Collected) [1983]
            ld (var_hyp_rclr), a		; Hyp.cls 1984
asm_1_1971_n_rn_again:		; Hyp.cls 1985
            push ix                 ; IX, IY and [1986]
            push iy		; Hyp.cls 1987
            db #08                  ; ex af, af': the alternate registers kept - the [1988]
            exx                     ; firmware's (BC' = its ROM / mode setting); a task [1989]
            push af                 ; may use them [1990]
            push bc		; Hyp.cls 1991
            push de		; Hyp.cls 1992
            push hl		; Hyp.cls 1993
            exx		; Hyp.cls 1994
            db #08		; Hyp.cls 1995
            ld hl, asm_1_1971_n_rn_back		; Hyp.cls 1996
            push hl                 ; where main RAM carries on [1997]
            ld (ntc_bk_sp), sp		; Hyp.cls 1998
            ld a, (var_hyp_rclr)		; Hyp.cls 1999
            ld e, a                 ; E = 1: the bank empties its characters out (BASIC has them) [2000]
            ld a, (var_hyp_ra)		; Hyp.cls 2001
            ld hl, (var_hyp_rhl)		; Hyp.cls 2002
            ld bc, (var_hyp_run_setting)		; Hyp.cls 2003
    IFDEF NTC_ZXN		; Hyp.cls 2004
            ; hyp -> task: PIVOT on the HIGH slot (7). The task preserved all its registers on its own
            ; stack, so nothing has to ride the multi-step flip. The result (ra/rhl), rclr and the
            ; slot-0 base page are handed to the task through its own slot 7 - which the nextreg below
            ; exposes at #E000-#FFFF - before sb_hin maps slots 0-6 and sb_land pops the task back.
            push af                             ; ra + flags [2009]
            push de                             ; E = rclr [2010]
            push hl                             ; rhl [2011]
            ld a, c		; Hyp.cls 2012
            dec a		; Hyp.cls 2013
            add a, a		; Hyp.cls 2014
            add a, a                            ; (index - 1) * 4 = its first 16K bank from FIRSTBANK [2015]
            add a, ZXN_FIRSTBANK		; Hyp.cls 2016
            add a, a                            ; * 2 = the task's slot-0 base page [2017]
            ld e, a		; Hyp.cls 2018
            add a, 7                            ; its slot-7 page (the top 8K) [2019]
            ld d, a		; Hyp.cls 2020
            ld bc, #243B                        ; map the task's slot 7 in via the MMU ports (#243B/#253B - no Z80N opcode) [2021]
            ld a, #57		; Hyp.cls 2022
            out (c), a		; Hyp.cls 2023
            inc b		; Hyp.cls 2024
            out (c), d		; Hyp.cls 2025
            ld a, e		; Hyp.cls 2026
            ld (63120 + 0), a                  ; base page -> the task's own slot 7, for sb_hin [2027]
            pop hl		; Hyp.cls 2028
            ld (63120 + 3), hl                 ; rhl (far-call result) [2029]
            pop de		; Hyp.cls 2030
            ld a, e		; Hyp.cls 2031
            ld (63120 + 2), a                  ; rclr (sb_land's E) [2032]
            pop af		; Hyp.cls 2033
            ld (63120 + 1), a                  ; ra (far-call result) [2034]
            jp 65488                           ; into the task's own slot 7 (sb_hin at HISW): it maps slots 0-6, then -> sb_land [2035]
    ELSE		; Hyp.cls 2036
            jp ntc_bk_out           ; out (c), c: the task's bank; its #0046 lands it [2037]
    ENDIF		; Hyp.cls 2038
asm_1_1971_n_rn_back:		; Hyp.cls 2039
            ld (var_hyp_rcnt), ix         ; the characters it collected (the stubs put them in IX) [2040]
            db #08                  ; ex af, af' [2041]
            exx		; Hyp.cls 2042
            pop hl                  ; the alternate registers back [2043]
            pop de		; Hyp.cls 2044
            pop bc		; Hyp.cls 2045
            pop af		; Hyp.cls 2046
            exx		; Hyp.cls 2047
            db #08		; Hyp.cls 2048
            pop iy		; Hyp.cls 2049
            pop ix		; Hyp.cls 2050
            push af                 ; carry: a BDOS call (A = C, DE = DE) [2051]
            push bc		; Hyp.cls 2052
            ld bc, (ntc_rampt)      ; the window's page back [2053]
            out (c), c		; Hyp.cls 2054
            pop bc		; Hyp.cls 2055
            pop af		; Hyp.cls 2056
            jr c, asm_1_1971_n_rn_far		; Hyp.cls 2057
            rst #38                 ; an interrupt stopped the task: the firmware's handler [2058]
            di		; Hyp.cls 2059
            ld hl, var_hyp_slc            ; a time slice is SLICE interrupts: until it is used up the [2060]
            dec (hl)                ; task carries on straight away (no trip through BASIC) [2061]
            jr z, asm_1_1971_n_rn_int		; Hyp.cls 2062
            ld a, (ntc_isldue)      ; ... unless an interrupt class (the system keys) is due [2063]
            or a		; Hyp.cls 2064
            jr nz, asm_1_1971_n_rn_int		; Hyp.cls 2065
            xor a                   ; its characters stay in its bank (and the count goes on) [2066]
            ld (var_hyp_rclr), a		; Hyp.cls 2067
            jp asm_1_1971_n_rn_again		; Hyp.cls 2068
asm_1_1971_n_rn_int:		; Hyp.cls 2069
            ld hl, 0		; Hyp.cls 2070
            jr asm_1_1971_n_rn_end		; Hyp.cls 2071
asm_1_1971_n_rn_far:		; Hyp.cls 2072
            ld (var_hyp_rfn), a		; Hyp.cls 2073
            ld (var_hyp_rde), de		; Hyp.cls 2074
            ld hl, 1		; Hyp.cls 2075
asm_1_1971_n_rn_end:		; Hyp.cls 2076
            ld (var_hyp_run_run), hl		; Hyp.cls 2077
            ld a, (var_hyp_rrom)		; Hyp.cls 2078
    IFNDEF NTC_ZXN		; Hyp.cls 2079
            call #B90C              ; KL ROM RESTORE [2080]
    ENDIF		; Hyp.cls 2081
            di		; Hyp.cls 2082
            ld sp, (var_hyp_sps)		; Hyp.cls 2083

			ret			; end of #asm

fn_hyp_info:		; function info (asm keyword), Hyp.cls line 2093
            pop hl		; Hyp.cls 2094
            ld a, (hl)		; Hyp.cls 2095
            ld hl, fn_hyp_info_hi_p0		; Hyp.cls 2096
            or a		; Hyp.cls 2097
            jr z, fn_hyp_info_in_e		; Hyp.cls 2098
            ld hl, fn_hyp_info_hi_p0e - fn_hyp_info_hi_p0		; Hyp.cls 2099
            dec a		; Hyp.cls 2100
            jr z, fn_hyp_info_in_e		; Hyp.cls 2101
            ld hl, fn_hyp_info_sb_img		; Hyp.cls 2102
            dec a		; Hyp.cls 2103
            jr z, fn_hyp_info_in_e		; Hyp.cls 2104
            ld hl, fn_hyp_info_sb_end - fn_hyp_info_sb_start		; Hyp.cls 2105
            dec a		; Hyp.cls 2106
            jr z, fn_hyp_info_in_e		; Hyp.cls 2107
            ld hl, fn_hyp_info_sb_init		; Hyp.cls 2108
    IFDEF NTC_ZXN		; Hyp.cls 2109
            dec a		; Hyp.cls 2110
            jr z, fn_hyp_info_in_e		; Hyp.cls 2111
            ld hl, fn_hyp_info_hi_sw                        ; 5: the switch-back receiver's source (window image) [2112]
            dec a		; Hyp.cls 2113
            jr z, fn_hyp_info_in_e		; Hyp.cls 2114
            ld hl, fn_hyp_info_hi_swe - fn_hyp_info_hi_sw               ; 6: its length (copied below #FFFE: HISW) [2115]
    ENDIF		; Hyp.cls 2116
fn_hyp_info_in_e:		; Hyp.cls 2117
            ex de, hl		; Hyp.cls 2118
            pop hl		; Hyp.cls 2119
            ld (hl), e		; Hyp.cls 2120
            inc hl		; Hyp.cls 2121
            ld (hl), d		; Hyp.cls 2122
            ret		; Hyp.cls 2123

			ret			; end of #asm

asm_1_2736_n:		; #asm, Hyp.cls line 2736 (normal)
    IFDEF NTC_ZXN		; Hyp.cls 2737
            ret                     ; ZX Next: no CPC firmware text layer to enable/disable [2738]
    ENDIF		; Hyp.cls 2739
            ld (var_hyp_hsp), sp		; Hyp.cls 2740
            ld sp, (ntc_csp)		; Hyp.cls 2741
            ld a, (var_hyp_vdu_on)		; Hyp.cls 2742
            or a		; Hyp.cls 2743
            jr z, asm_1_2736_n_vd_off		; Hyp.cls 2744
            call #BB54              ; TXT VDU ENABLE [2745]
            jr asm_1_2736_n_vd_done		; Hyp.cls 2746
asm_1_2736_n_vd_off:		; Hyp.cls 2747
            call #BB57              ; TXT VDU DISABLE [2748]
asm_1_2736_n_vd_done:		; Hyp.cls 2749
            di		; Hyp.cls 2750
            ld sp, (var_hyp_hsp)		; Hyp.cls 2751
			ret			; end of #asm

asm_1_2771_n:		; #asm, Hyp.cls line 2771 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 2772
            ld sp, (ntc_csp)		; Hyp.cls 2773
            ld (asm_1_2771_n_fl_ix), ix		; Hyp.cls 2774
            ld (asm_1_2771_n_fl_iy), iy		; Hyp.cls 2775
            ld a, 255		; Hyp.cls 2776
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 2777
            ld a, (var_hyp_filecall_slot)		; Hyp.cls 2778
            ld (asm_1_2771_n_fl_slot), a		; Hyp.cls 2779
            ld a, (var_hyp_filecall_f)		; Hyp.cls 2780
            cp 99		; Hyp.cls 2781
            jp z, asm_1_2771_n_fl_inst		; Hyp.cls 2782
            IF NTC_ROMLIB = 0		; Hyp.cls 2783
; the RAM discs' driver (RAMDISC.CYB's, in a page of its own at #4000) sees the call first:
; carry - it was one of its drives' (HL the answer), else on to the disc ROM. It gets IX = the
; call (f, fcb, slot, setting, dma, drive, buf; 100-105: drive = the hypervisor's drive), at
; #4003 a jump to fl_dx (its copies: it runs in the window, so can't switch it itself), at
; #4006 its page's RAM setting
            ASSERT var_hyp_filecall_buf - var_hyp_filecall_f = 12, "FileCall's parameters, one after another"		; Hyp.cls 2789
            ld a, (var_hyp_drs + 1)		; Hyp.cls 2790
            or a		; Hyp.cls 2791
            jr z, asm_1_2771_n_fl_nodrv		; Hyp.cls 2792
            di		; Hyp.cls 2793
            ld a, (var_hyp_filecall_f)		; Hyp.cls 2794
            cp 100		; Hyp.cls 2795
            jr c, asm_1_2771_n_fl_dr_go		; Hyp.cls 2796
            cp 106		; Hyp.cls 2797
            jr nc, asm_1_2771_n_fl_dr_go		; Hyp.cls 2798
            ld hl, (var_hyp_hdr)		; Hyp.cls 2799
            ld (var_hyp_filecall_drive), hl		; Hyp.cls 2800
asm_1_2771_n_fl_dr_go:		; Hyp.cls 2801
            ld bc, (var_hyp_drs)		; Hyp.cls 2802
            out (c), c		; Hyp.cls 2803
            ld hl, asm_1_2771_n_fl_dx		; Hyp.cls 2804
            ld (#4004), hl		; Hyp.cls 2805
            ld hl, (var_hyp_drs)		; Hyp.cls 2806
            ld (#4006), hl		; Hyp.cls 2807
            ld ix, var_hyp_filecall_f		; Hyp.cls 2808
            call #4000		; Hyp.cls 2809
            jr nc, asm_1_2771_n_fl_nodrv		; Hyp.cls 2810
            ld (asm_1_2771_n_fl_res16), hl		; Hyp.cls 2811
            ld a, 1		; Hyp.cls 2812
            ld (asm_1_2771_n_fl_r16), a		; Hyp.cls 2813
            jp asm_1_2771_n_fl_done		; Hyp.cls 2814
; fl_dx - A bytes (1-128) from HL to DE through dxb: IX = HL's RAM setting, IY = DE's (0:
; main RAM, no switch); the driver's page back in the window after. HL, DE on past them
asm_1_2771_n_fl_dx:		; Hyp.cls 2817
            ld (asm_1_2771_n_fl_dxn), a		; Hyp.cls 2818
            push de		; Hyp.cls 2819
            ld de, (var_hyp_dxb)		; Hyp.cls 2820
            push ix		; Hyp.cls 2821
            pop bc		; Hyp.cls 2822
            inc b		; Hyp.cls 2823
            dec b		; Hyp.cls 2824
            jr z, asm_1_2771_n_fl_dx1		; Hyp.cls 2825
            out (c), c		; Hyp.cls 2826
asm_1_2771_n_fl_dx1:		; Hyp.cls 2827
            ld c, a		; Hyp.cls 2828
            ld b, 0		; Hyp.cls 2829
            ldir		; Hyp.cls 2830
            pop de		; Hyp.cls 2831
            push hl		; Hyp.cls 2832
            push iy		; Hyp.cls 2833
            pop bc		; Hyp.cls 2834
            inc b		; Hyp.cls 2835
            dec b		; Hyp.cls 2836
            jr z, asm_1_2771_n_fl_dx2		; Hyp.cls 2837
            out (c), c		; Hyp.cls 2838
asm_1_2771_n_fl_dx2:		; Hyp.cls 2839
            ld hl, (var_hyp_dxb)		; Hyp.cls 2840
            ld a, (asm_1_2771_n_fl_dxn)		; Hyp.cls 2841
            ld c, a		; Hyp.cls 2842
            ld b, 0		; Hyp.cls 2843
            ldir		; Hyp.cls 2844
            pop hl		; Hyp.cls 2845
            ld bc, (var_hyp_drs)		; Hyp.cls 2846
            out (c), c		; Hyp.cls 2847
            ret		; Hyp.cls 2848
asm_1_2771_n_fl_dxn:     db 0		; Hyp.cls 2849
asm_1_2771_n_fl_nodrv:		; Hyp.cls 2850
            ENDIF		; Hyp.cls 2851
            di		; Hyp.cls 2852
            ld bc, (var_hyp_hps)          ; the rest runs in the hypervisor's page (window data from [2853]
            out (c), c              ; #5300: fp_go) [2854]
            call asm_1_2771_n_fp_go		; Hyp.cls 2855
            jp asm_1_2771_n_fl_done		; Hyp.cls 2856
; 99: the window data (#5300 to fp_end: the bank image, the page code) copied from main RAM's
; own #4000-#7FFF (where the file put it) into the hypervisor's page, through buf; once, at the
; start, before anything else uses main RAM's #4000-#7FFF
asm_1_2771_n_fl_inst:		; Hyp.cls 2860
            ld hl, #5300		; Hyp.cls 2861
asm_1_2771_n_fl_in_lp:		; Hyp.cls 2862
            push hl		; Hyp.cls 2863
            ld bc, #7FC0            ; main RAM's own (zxn: bank 9 = the hypervisor's own pages 18, 19, holding the loaded image) [2864]
    IFDEF NTC_ZXN		; Hyp.cls 2865
            call asm_1_2771_n_fl_zxn_map		; Hyp.cls 2866
    ELSE		; Hyp.cls 2867
            out (c), c		; Hyp.cls 2868
    ENDIF		; Hyp.cls 2869
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 2870
            ld bc, 128		; Hyp.cls 2871
            ldir		; Hyp.cls 2872
            ld bc, (var_hyp_hps)		; Hyp.cls 2873
    IFDEF NTC_ZXN		; Hyp.cls 2874
            call asm_1_2771_n_fl_zxn_map		; Hyp.cls 2875
    ELSE		; Hyp.cls 2876
            out (c), c		; Hyp.cls 2877
    ENDIF		; Hyp.cls 2878
            pop de		; Hyp.cls 2879
            push de		; Hyp.cls 2880
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 2881
            ld bc, 128		; Hyp.cls 2882
            ldir		; Hyp.cls 2883
            pop hl		; Hyp.cls 2884
            ld bc, 128		; Hyp.cls 2885
            add hl, bc		; Hyp.cls 2886
            ld de, asm_1_2771_n_fp_end		; Hyp.cls 2887
            or a		; Hyp.cls 2888
            sbc hl, de		; Hyp.cls 2889
            add hl, de		; Hyp.cls 2890
            jr c, asm_1_2771_n_fl_in_lp		; Hyp.cls 2891
            xor a		; Hyp.cls 2892
            ld (asm_1_2771_n_fl_res), a		; Hyp.cls 2893
            jp asm_1_2771_n_fl_done		; Hyp.cls 2894
    IFDEF NTC_ZXN		; Hyp.cls 2895
; fl_zxn_map - BC = a RAM setting -> its 16K bank into the window (slots 2, 3) via the MMU, the
; same mapping the Memory class's mem_se_out does (B = #7F: bank 9, the hypervisor's own pages).
; FileCall 99 runs before interrupts, so no ntc_zxsel re-select is needed. Keeps HL.
asm_1_2771_n_fl_zxn_map:		; Hyp.cls 2899
            ld (ntc_rampt), bc		; Hyp.cls 2900
            ld a, b		; Hyp.cls 2901
            cp #7F		; Hyp.cls 2902
            jr nz, asm_1_2771_n_fl_zm1		; Hyp.cls 2903
            ld c, 9		; Hyp.cls 2904
asm_1_2771_n_fl_zm1:		; Hyp.cls 2905
            ld a, c		; Hyp.cls 2906
            add a, a                ; first 8K page = Next 16K bank * 2 [2907]
            ld d, a		; Hyp.cls 2908
            ld bc, #243B		; Hyp.cls 2909
            ld a, #52		; Hyp.cls 2910
            out (c), a		; Hyp.cls 2911
            inc b		; Hyp.cls 2912
            out (c), d		; Hyp.cls 2913
            dec b		; Hyp.cls 2914
            ld a, #53		; Hyp.cls 2915
            out (c), a		; Hyp.cls 2916
            inc b		; Hyp.cls 2917
            inc d		; Hyp.cls 2918
            out (c), d		; Hyp.cls 2919
            ret		; Hyp.cls 2920
    ENDIF		; Hyp.cls 2921
; ---- what the page code can't do itself (it runs in the window): switch the window to a slot's
; page and back. Each puts the hypervisor's page back in the window
asm_1_2771_n_fl_sel:                             ; the slot's page holding HL in the window: HL = there [2924]
            push de		; Hyp.cls 2925
            ld a, h		; Hyp.cls 2926
            rlca		; Hyp.cls 2927
            rlca		; Hyp.cls 2928
            and 3		; Hyp.cls 2929
            add a, 4		; Hyp.cls 2930
            ld e, a		; Hyp.cls 2931
            ld bc, (var_hyp_filecall_setting)		; Hyp.cls 2932
            ld a, c		; Hyp.cls 2933
            and #F8		; Hyp.cls 2934
            or e		; Hyp.cls 2935
            ld c, a		; Hyp.cls 2936
            out (c), c		; Hyp.cls 2937
            ld a, h		; Hyp.cls 2938
            and #3F		; Hyp.cls 2939
            or #40		; Hyp.cls 2940
            ld h, a		; Hyp.cls 2941
            pop de		; Hyp.cls 2942
            ret		; Hyp.cls 2943
asm_1_2771_n_fl_peek:                            ; A = the slot's byte at HL (BC, DE, HL kept) [2944]
            push bc		; Hyp.cls 2945
            push hl		; Hyp.cls 2946
            call asm_1_2771_n_fl_sel		; Hyp.cls 2947
            ld a, (hl)		; Hyp.cls 2948
asm_1_2771_n_fl_pk_back:		; Hyp.cls 2949
            ld bc, (var_hyp_hps)		; Hyp.cls 2950
            out (c), c		; Hyp.cls 2951
            pop hl		; Hyp.cls 2952
            pop bc		; Hyp.cls 2953
            ret		; Hyp.cls 2954
asm_1_2771_n_fl_poke:                            ; the slot's byte at HL = A (BC, DE, HL kept) [2955]
            push bc		; Hyp.cls 2956
            push hl		; Hyp.cls 2957
            push af		; Hyp.cls 2958
            call asm_1_2771_n_fl_sel		; Hyp.cls 2959
            pop af		; Hyp.cls 2960
            ld (hl), a		; Hyp.cls 2961
            jr asm_1_2771_n_fl_pk_back		; Hyp.cls 2962
asm_1_2771_n_fl_toslot:                          ; BC bytes from DE (main RAM) to the slot's HL (all in one of [2963]
            push bc                 ; its pages: fl_fits) [2964]
            call asm_1_2771_n_fl_sel		; Hyp.cls 2965
            pop bc		; Hyp.cls 2966
            ex de, hl		; Hyp.cls 2967
            ldir		; Hyp.cls 2968
            jr asm_1_2771_n_fl_blk_back		; Hyp.cls 2969
asm_1_2771_n_fl_fromslot:                        ; BC bytes from the slot's HL (in one page) to DE (main RAM) [2970]
            push bc		; Hyp.cls 2971
            call asm_1_2771_n_fl_sel		; Hyp.cls 2972
            pop bc		; Hyp.cls 2973
            ldir		; Hyp.cls 2974
asm_1_2771_n_fl_blk_back:		; Hyp.cls 2975
            ld bc, (var_hyp_hps)		; Hyp.cls 2976
            out (c), c		; Hyp.cls 2977
            ret		; Hyp.cls 2978
asm_1_2771_n_fl_done:		; Hyp.cls 2979
            di		; Hyp.cls 2980
            ld bc, (ntc_rampt)      ; the page that was in the window back [2981]
            out (c), c		; Hyp.cls 2982
            ld a, (asm_1_2771_n_fl_res)		; Hyp.cls 2983
            ld l, a		; Hyp.cls 2984
            ld h, 0		; Hyp.cls 2985
            ld a, (asm_1_2771_n_fl_r16)		; Hyp.cls 2986
            or a		; Hyp.cls 2987
            jr z, asm_1_2771_n_fl_d8		; Hyp.cls 2988
            ld hl, (asm_1_2771_n_fl_res16)		; Hyp.cls 2989
            xor a		; Hyp.cls 2990
            ld (asm_1_2771_n_fl_r16), a		; Hyp.cls 2991
asm_1_2771_n_fl_d8:		; Hyp.cls 2992
            ld (var_hyp_filecall_filecall), hl		; Hyp.cls 2993
            ld ix, (asm_1_2771_n_fl_ix)		; Hyp.cls 2994
            ld iy, (asm_1_2771_n_fl_iy)		; Hyp.cls 2995
            ld sp, (var_hyp_hsp)		; Hyp.cls 2996
            jp asm_1_2771_n_fl_exit		; Hyp.cls 2997
asm_1_2771_n_fl_ix:      dw 0		; Hyp.cls 2998
asm_1_2771_n_fl_iy:      dw 0		; Hyp.cls 2999
asm_1_2771_n_fl_res:     db 0		; Hyp.cls 3000
asm_1_2771_n_fl_r16:     db 0                    ; 1: the result is fl_res16 [3001]
asm_1_2771_n_fl_res16:   dw 0		; Hyp.cls 3002
asm_1_2771_n_fl_slot:    db 0		; Hyp.cls 3003
; (main RAM: the page code calls them - no room left in the page)
asm_1_2771_n_fl_isin:                            ; Z: the file being read is this slot's, this FCB [3005]
            ld a, (var_hyp_fin)		; Hyp.cls 3006
            ld hl, asm_1_2771_n_fl_infcb		; Hyp.cls 3007
            jr asm_1_2771_n_fl_is		; Hyp.cls 3008
asm_1_2771_n_fl_isout:		; Hyp.cls 3009
            ld a, (var_hyp_fout)		; Hyp.cls 3010
            ld hl, asm_1_2771_n_fl_outfcb		; Hyp.cls 3011
asm_1_2771_n_fl_is:                              ; (its FCB: the one it was opened with - or, the first [3012]
            ld b, a                 ; call after with another, that one: a program's own copy [3013]
            ld a, (asm_1_2771_n_fl_slot)         ; of it, BBC BASIC's channels) [3014]
            cp b		; Hyp.cls 3015
            ret nz		; Hyp.cls 3016
            ld e, (hl)		; Hyp.cls 3017
            inc hl		; Hyp.cls 3018
            ld d, (hl)		; Hyp.cls 3019
            inc hl		; Hyp.cls 3020
            push hl		; Hyp.cls 3021
            call asm_1_2771_n_fl_cmpf		; Hyp.cls 3022
            pop de		; Hyp.cls 3023
            ret z		; Hyp.cls 3024
            ld a, (de)              ; (the open's FCB still: this one from now on - unless it [3025]
            xor 1                   ; is the other file's: a program reading the record it [3026]
            ret nz                  ; writes, through that file's FCB) [3027]
            push de		; Hyp.cls 3028
            ld a, (var_hyp_fin)		; Hyp.cls 3029
            ld de, (asm_1_2771_n_fl_infcb)		; Hyp.cls 3030
            call asm_1_2771_n_fl_oth		; Hyp.cls 3031
            jr z, asm_1_2771_n_fl_is_no		; Hyp.cls 3032
            ld a, (var_hyp_fout)		; Hyp.cls 3033
            ld de, (asm_1_2771_n_fl_outfcb)		; Hyp.cls 3034
            call asm_1_2771_n_fl_oth		; Hyp.cls 3035
asm_1_2771_n_fl_is_no:		; Hyp.cls 3036
            pop de		; Hyp.cls 3037
            jr nz, asm_1_2771_n_fl_is_re		; Hyp.cls 3038
            inc a                   ; (NZ: not this one) [3039]
            ret		; Hyp.cls 3040
asm_1_2771_n_fl_is_re:		; Hyp.cls 3041
            xor a		; Hyp.cls 3042
            ld (de), a		; Hyp.cls 3043
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3044
            ex de, hl		; Hyp.cls 3045
            dec hl		; Hyp.cls 3046
            ld (hl), d		; Hyp.cls 3047
            dec hl		; Hyp.cls 3048
            ld (hl), e		; Hyp.cls 3049
            ret		; Hyp.cls 3050
asm_1_2771_n_fl_oth:                             ; Z: the slot's file (A: fin / fout), its FCB DE the call's [3051]
            ld b, a		; Hyp.cls 3052
            ld a, (asm_1_2771_n_fl_slot)		; Hyp.cls 3053
            cp b		; Hyp.cls 3054
            ret nz		; Hyp.cls 3055
asm_1_2771_n_fl_cmpf:                            ; Z: the call's FCB is DE [3056]
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3057
            or a		; Hyp.cls 3058
            sbc hl, de		; Hyp.cls 3059
            ret		; Hyp.cls 3060
asm_1_2771_n_fl_exit:		; Hyp.cls 4351
			ret			; end of #asm

asm_1_4357_n:		; #asm, Hyp.cls line 4357 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 4358
            ld sp, (ntc_csp)		; Hyp.cls 4359
            ld bc, (var_hyp_hps)          ; (the buffers: the hypervisor's page) [4360]
            out (c), c		; Hyp.cls 4361
            ld a, (var_hyp_fileshut_slot)		; Hyp.cls 4362
            ld b, a		; Hyp.cls 4363
            ld a, (var_hyp_fin)		; Hyp.cls 4364
            cp b		; Hyp.cls 4365
            jr nz, asm_1_4357_n_fs_out		; Hyp.cls 4366
            xor a		; Hyp.cls 4367
            ld (var_hyp_fin), a		; Hyp.cls 4368
            push bc		; Hyp.cls 4369
            call #BC7A              ; CAS IN CLOSE [4370]
            di		; Hyp.cls 4371
            pop bc		; Hyp.cls 4372
asm_1_4357_n_fs_out:		; Hyp.cls 4373
            ld a, (var_hyp_fout)		; Hyp.cls 4374
            cp b		; Hyp.cls 4375
            jr nz, asm_1_4357_n_fs_done		; Hyp.cls 4376
            xor a		; Hyp.cls 4377
            ld (var_hyp_fout), a		; Hyp.cls 4378
            call #BC8F              ; CAS OUT CLOSE [4379]
            di		; Hyp.cls 4380
asm_1_4357_n_fs_done:		; Hyp.cls 4381
            ld bc, (ntc_rampt)		; Hyp.cls 4382
            out (c), c		; Hyp.cls 4383
            ld sp, (var_hyp_hsp)		; Hyp.cls 4384
			ret			; end of #asm

fn_hyp_usesvc:		; sub usesvc (asm keyword), Hyp.cls line 4410
            ld hl, (ntc_rampt)		; Hyp.cls 4411
            ld (var_hyp_svp), hl		; Hyp.cls 4412
			ret			; end of #asm

asm_1_4424_n:		; #asm, Hyp.cls line 4424 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 4425
            ld sp, (ntc_csp)		; Hyp.cls 4426
            ld (asm_1_4424_n_sv_ix), ix		; Hyp.cls 4427
            ld (asm_1_4424_n_sv_iy), iy		; Hyp.cls 4428
            di		; Hyp.cls 4429
            ld a, (var_hyp_svc_t)		; Hyp.cls 4430
            or a		; Hyp.cls 4431
            jr z, asm_1_4424_n_sv_inst		; Hyp.cls 4432
            ld bc, (var_hyp_svp)		; Hyp.cls 4433
            out (c), c		; Hyp.cls 4434
            call asm_1_4424_n_sv_go              ; (in the service page) A = the answer [4435]
asm_1_4424_n_sv_back:		; Hyp.cls 4436
            di		; Hyp.cls 4437
            ld l, a		; Hyp.cls 4438
            ld h, 0		; Hyp.cls 4439
            ld (var_hyp_svc_svc), hl		; Hyp.cls 4440
            ld bc, (ntc_rampt)      ; the page that was in the window back [4441]
            out (c), c		; Hyp.cls 4442
            ld ix, (asm_1_4424_n_sv_ix)		; Hyp.cls 4443
            ld iy, (asm_1_4424_n_sv_iy)		; Hyp.cls 4444
            ld sp, (var_hyp_hsp)		; Hyp.cls 4445
            jp asm_1_4424_n_sv_exit		; Hyp.cls 4446
asm_1_4424_n_sv_inst:		; Hyp.cls 4447
            ld hl, #6000		; Hyp.cls 4448
asm_1_4424_n_sv_in_lp:		; Hyp.cls 4449
            push hl		; Hyp.cls 4450
            ld bc, #7FC0            ; main RAM's own [4451]
            out (c), c		; Hyp.cls 4452
            ld de, (var_hyp_svc_buf)		; Hyp.cls 4453
            ld bc, 128		; Hyp.cls 4454
            ldir		; Hyp.cls 4455
            ld bc, (var_hyp_svp)		; Hyp.cls 4456
            out (c), c		; Hyp.cls 4457
            pop de		; Hyp.cls 4458
            push de		; Hyp.cls 4459
            ld hl, (var_hyp_svc_buf)		; Hyp.cls 4460
            ld bc, 128		; Hyp.cls 4461
            ldir		; Hyp.cls 4462
            pop hl		; Hyp.cls 4463
            ld bc, 128		; Hyp.cls 4464
            add hl, bc		; Hyp.cls 4465
            ld de, asm_1_4424_n_sv_end		; Hyp.cls 4466
            or a		; Hyp.cls 4467
            sbc hl, de		; Hyp.cls 4468
            add hl, de		; Hyp.cls 4469
            jr c, asm_1_4424_n_sv_in_lp		; Hyp.cls 4470
            xor a		; Hyp.cls 4471
            jr asm_1_4424_n_sv_back		; Hyp.cls 4472
asm_1_4424_n_sv_ix:      dw 0		; Hyp.cls 4473
asm_1_4424_n_sv_iy:      dw 0		; Hyp.cls 4474
; sv_dx - A bytes (1-128) from HL to DE through buf: IX = HL's RAM setting, IY = DE's (0: none -
; main RAM outside the window); the service page back in the window after. HL, DE on past them
asm_1_4424_n_sv_dx:		; Hyp.cls 4477
            ld (asm_1_4424_n_sv_dxn), a		; Hyp.cls 4478
            push de		; Hyp.cls 4479
            ld de, (var_hyp_svc_buf)		; Hyp.cls 4480
            push ix		; Hyp.cls 4481
            pop bc		; Hyp.cls 4482
            inc b		; Hyp.cls 4483
            dec b		; Hyp.cls 4484
            jr z, asm_1_4424_n_sv_dx1		; Hyp.cls 4485
            out (c), c		; Hyp.cls 4486
asm_1_4424_n_sv_dx1:		; Hyp.cls 4487
            ld c, a		; Hyp.cls 4488
            ld b, 0		; Hyp.cls 4489
            ldir		; Hyp.cls 4490
            pop de		; Hyp.cls 4491
            push hl		; Hyp.cls 4492
            push iy		; Hyp.cls 4493
            pop bc		; Hyp.cls 4494
            inc b		; Hyp.cls 4495
            dec b		; Hyp.cls 4496
            jr z, asm_1_4424_n_sv_dx2		; Hyp.cls 4497
            out (c), c		; Hyp.cls 4498
asm_1_4424_n_sv_dx2:		; Hyp.cls 4499
            ld hl, (var_hyp_svc_buf)		; Hyp.cls 4500
            ld a, (asm_1_4424_n_sv_dxn)		; Hyp.cls 4501
            ld c, a		; Hyp.cls 4502
            ld b, 0		; Hyp.cls 4503
            ldir		; Hyp.cls 4504
            pop hl		; Hyp.cls 4505
            ld bc, (var_hyp_svp)		; Hyp.cls 4506
            out (c), c		; Hyp.cls 4507
            ret		; Hyp.cls 4508
asm_1_4424_n_sv_dxn:     db 0		; Hyp.cls 4509
asm_1_4424_n_sv_exit:		; Hyp.cls 6144
			ret			; end of #asm

asm_1_6156_n:		; #asm, Hyp.cls line 6156 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 6157
            ld sp, (ntc_csp)		; Hyp.cls 6158
            ld (asm_1_6156_n_dv_ix), ix		; Hyp.cls 6159
            ld (asm_1_6156_n_dv_iy), iy		; Hyp.cls 6160
            ld hl, 0		; Hyp.cls 6161
            ld (var_hyp_drive_drive), hl		; Hyp.cls 6162
            ld hl, (var_hyp_drive_letter)		; Hyp.cls 6163
            ld (var_hyp_hdr), hl		; Hyp.cls 6164
            IF NTC_ROMLIB = 0		; Hyp.cls 6165
            ld a, (var_hyp_drs + 1)		; Hyp.cls 6166
            or a		; Hyp.cls 6167
            jr z, asm_1_6156_n_dv_rsx		; Hyp.cls 6168
            ld (asm_1_6156_n_dv_blk + 2), hl		; Hyp.cls 6169
            di		; Hyp.cls 6170
            ld bc, (var_hyp_drs)		; Hyp.cls 6171
            out (c), c		; Hyp.cls 6172
            ld ix, asm_1_6156_n_dv_blk		; Hyp.cls 6173
            call #4000		; Hyp.cls 6174
            ld bc, (ntc_rampt)		; Hyp.cls 6175
            out (c), c		; Hyp.cls 6176
            jr nc, asm_1_6156_n_dv_rsx		; Hyp.cls 6177
            ld hl, -1		; Hyp.cls 6178
            ld (var_hyp_drive_drive), hl		; Hyp.cls 6179
            jr asm_1_6156_n_dv_done		; Hyp.cls 6180
asm_1_6156_n_dv_blk:     dw 114, 0, 0, 0, 0, 0, 0		; Hyp.cls 6181
            ENDIF		; Hyp.cls 6182
asm_1_6156_n_dv_rsx:		; Hyp.cls 6183
            ld a, (var_hyp_drive_letter)		; Hyp.cls 6184
            or #80                  ; a one letter command name: its last letter + #80 [6185]
            ld (asm_1_6156_n_dv_nm), a		; Hyp.cls 6186
            ld hl, asm_1_6156_n_dv_nm		; Hyp.cls 6187
            call #BCD4              ; KL FIND COMMAND: carry = found, C = its ROM, HL = its address [6188]
            di		; Hyp.cls 6189
            jr nc, asm_1_6156_n_dv_done		; Hyp.cls 6190
            xor a                   ; no parameters [6191]
            call #001B              ; KL FAR PCALL [6192]
            di		; Hyp.cls 6193
            ld hl, -1		; Hyp.cls 6194
            ld (var_hyp_drive_drive), hl		; Hyp.cls 6195
            jr asm_1_6156_n_dv_done		; Hyp.cls 6196
asm_1_6156_n_dv_nm:      db 0		; Hyp.cls 6197
asm_1_6156_n_dv_ix:      dw 0		; Hyp.cls 6198
asm_1_6156_n_dv_iy:      dw 0		; Hyp.cls 6199
asm_1_6156_n_dv_done:		; Hyp.cls 6200
            ld ix, (asm_1_6156_n_dv_ix)		; Hyp.cls 6201
            ld iy, (asm_1_6156_n_dv_iy)		; Hyp.cls 6202
            ld sp, (var_hyp_hsp)		; Hyp.cls 6203
			ret			; end of #asm

fn_memory_pages:		; function pages (asm keyword), Memory.cls line 69
            pop hl		; Memory.cls 70
            ld (mem_res), hl		; Memory.cls 71
            ld hl, mem_pages		; Memory.cls 72
            jp mem_go		; Memory.cls 73
			ret			; end of #asm

fn_memory_freepages:		; function freepages (asm keyword), Memory.cls line 79
            pop hl		; Memory.cls 80
            ld (mem_res), hl		; Memory.cls 81
            ld hl, mem_freepages		; Memory.cls 82
            jp mem_go		; Memory.cls 83
			ret			; end of #asm

fn_memory_ramsize:		; function ramsize (asm keyword), Memory.cls line 89
            pop hl		; Memory.cls 90
            ld (mem_res), hl		; Memory.cls 91
            ld hl, mem_ramsize		; Memory.cls 92
            jp mem_go		; Memory.cls 93
			ret			; end of #asm

fn_memory_tableend:		; function tableend (asm keyword), Memory.cls line 145
            pop hl		; Memory.cls 146
            ld (mem_res), hl		; Memory.cls 147
            ld hl, mem_tableend		; Memory.cls 148
            jp mem_go		; Memory.cls 149
			ret			; end of #asm

fn_memory_top:		; function top (asm keyword), Memory.cls line 175
            pop hl		; Memory.cls 176
            ld (mem_res), hl		; Memory.cls 177
            ld hl, mem_top		; Memory.cls 178
            jp mem_go		; Memory.cls 179
			ret			; end of #asm

fn_memory_map:		; function map (asm keyword), Memory.cls line 195
            pop hl		; Memory.cls 196
            ld e, (hl)		; Memory.cls 197
            inc hl		; Memory.cls 198
            ld d, (hl)		; Memory.cls 199
            ld (mem_a1), de		; Memory.cls 200
            pop hl		; Memory.cls 201
            ld e, (hl)		; Memory.cls 202
            inc hl		; Memory.cls 203
            ld d, (hl)		; Memory.cls 204
            ld (mem_a2), de		; Memory.cls 205
            pop hl		; Memory.cls 206
            ld (mem_res), hl		; Memory.cls 207
            ld hl, mem_map		; Memory.cls 208
            jp mem_go0		; Memory.cls 209
			ret			; end of #asm

fn_memory_allocpage:		; function allocpage (asm keyword), Memory.cls line 218
            pop hl		; Memory.cls 219
            ld e, (hl)		; Memory.cls 220
            inc hl		; Memory.cls 221
            ld d, (hl)		; Memory.cls 222
            ld (mem_a1), de		; Memory.cls 223
            pop hl		; Memory.cls 224
            ld (mem_res), hl		; Memory.cls 225
            ld hl, mem_allocpage		; Memory.cls 226
            jp mem_go		; Memory.cls 227
			ret			; end of #asm

fn_memory_freepage:		; function freepage (asm keyword), Memory.cls line 234
            pop hl		; Memory.cls 235
            ld e, (hl)		; Memory.cls 236
            inc hl		; Memory.cls 237
            ld d, (hl)		; Memory.cls 238
            ld (mem_a1), de		; Memory.cls 239
            pop hl		; Memory.cls 240
            ld (mem_res), hl		; Memory.cls 241
            ld hl, mem_freepage		; Memory.cls 242
            jp mem_go		; Memory.cls 243
			ret			; end of #asm

fn_memory_selectpage:		; function selectpage (asm keyword), Memory.cls line 249
            pop hl		; Memory.cls 250
            ld e, (hl)		; Memory.cls 251
            inc hl		; Memory.cls 252
            ld d, (hl)		; Memory.cls 253
            ld (mem_a1), de		; Memory.cls 254
            pop hl		; Memory.cls 255
            ld (mem_res), hl		; Memory.cls 256
            ld hl, mem_selpage		; Memory.cls 257
            jp mem_go		; Memory.cls 258
			ret			; end of #asm

fn_memory_readbyte:		; function readbyte (asm keyword), Memory.cls line 339
            pop hl		; Memory.cls 340
            ld (mem_a1), hl		; Memory.cls 341
            pop hl		; Memory.cls 342
            ld (mem_res), hl		; Memory.cls 343
            ld hl, mem_readbyte		; Memory.cls 344
            jp mem_go		; Memory.cls 345
			ret			; end of #asm

fn_memory_readword:		; function readword (asm keyword), Memory.cls line 350
            pop hl		; Memory.cls 351
            ld (mem_a1), hl		; Memory.cls 352
            pop hl		; Memory.cls 353
            ld (mem_res), hl		; Memory.cls 354
            ld hl, mem_readword		; Memory.cls 355
            jp mem_go		; Memory.cls 356
			ret			; end of #asm

fn_memory_writebyte:		; sub writebyte (asm keyword), Memory.cls line 361
            pop hl		; Memory.cls 362
            ld (mem_a1), hl		; Memory.cls 363
            pop hl		; Memory.cls 364
            ld e, (hl)		; Memory.cls 365
            inc hl		; Memory.cls 366
            ld d, (hl)		; Memory.cls 367
            ld (mem_a2), de		; Memory.cls 368
            ld hl, mem_writebyte		; Memory.cls 369
            jp mem_go0		; Memory.cls 370
			ret			; end of #asm

fn_memory_writeword:		; sub writeword (asm keyword), Memory.cls line 375
            pop hl		; Memory.cls 376
            ld (mem_a1), hl		; Memory.cls 377
            pop hl		; Memory.cls 378
            ld e, (hl)		; Memory.cls 379
            inc hl		; Memory.cls 380
            ld d, (hl)		; Memory.cls 381
            ld (mem_a2), de		; Memory.cls 382
            ld hl, mem_writeword		; Memory.cls 383
            jp mem_go0		; Memory.cls 384
			ret			; end of #asm

fn_memory_copy:		; function copy (asm keyword), Memory.cls line 392
            pop hl		; Memory.cls 393
            ld (mem_a1), hl		; Memory.cls 394
            pop hl		; Memory.cls 395
            ld (mem_a2), hl		; Memory.cls 396
            pop hl		; Memory.cls 397
            ld e, (hl)		; Memory.cls 398
            inc hl		; Memory.cls 399
            ld d, (hl)		; Memory.cls 400
            ld (mem_a3), de		; Memory.cls 401
            pop hl		; Memory.cls 402
            ld (mem_res), hl		; Memory.cls 403
            ld hl, mem_copy		; Memory.cls 404
            jp mem_go		; Memory.cls 405
			ret			; end of #asm

fn_memory_banks:		; function banks (asm keyword), Memory.cls line 414
            pop hl		; Memory.cls 415
            ld (mem_res), hl		; Memory.cls 416
            ld hl, mem_bankcount		; Memory.cls 417
            jp mem_go		; Memory.cls 418
			ret			; end of #asm

fn_memory_allocbank:		; function allocbank (asm keyword), Memory.cls line 424
            pop hl		; Memory.cls 425
            ld (mem_res), hl		; Memory.cls 426
            ld hl, mem_allocbank		; Memory.cls 427
            jp mem_go		; Memory.cls 428
			ret			; end of #asm


ntc_rg67_e:
			IF ($ < 32768) && (ntc_rg68_e - ntc_rg68 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg68:
; ============================================================
; Variables
; ============================================================

ntc_rg68_e:
			IF ($ < 32768) && (ntc_rg69_e - ntc_rg69 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg69:
var_k:			dw 0
ntc_rg69_e:
			IF ($ < 32768) && (ntc_rg70_e - ntc_rg70 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg70:
var_ns:			dw 0
ntc_rg70_e:
			IF ($ < 32768) && (ntc_rg71_e - ntc_rg71 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg71:
var_i:			dw 0
ntc_rg71_e:
			IF ($ < 32768) && (ntc_rg72_e - ntc_rg72 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg72:
var_hp:			dw 0
ntc_rg72_e:
			IF ($ < 32768) && (ntc_rg73_e - ntc_rg73 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg73:
var_memory_selectpage_selectpage:			dw 0
ntc_rg73_e:
			IF ($ < 32768) && (ntc_rg74_e - ntc_rg74 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg74:
var_front:			dw 0
ntc_rg74_e:
			IF ($ < 32768) && (ntc_rg75_e - ntc_rg75 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg75:
var_dp:			dw 0
ntc_rg75_e:
			IF ($ < 32768) && (ntc_rg76_e - ntc_rg76 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg76:
var_hyp_filecall_filecall:			dw 0
ntc_rg76_e:
			IF ($ < 32768) && (ntc_rg77_e - ntc_rg77 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg77:
var_hyp_svc_svc:			dw 0
ntc_rg77_e:
			IF ($ < 32768) && (ntc_rg78_e - ntc_rg78 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg78:
for3_l:			dw 0
ntc_rg78_e:
			IF ($ < 32768) && (ntc_rg79_e - ntc_rg79 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg79:
var_memory_allocbank_allocbank:			dw 0
ntc_rg79_e:
			IF ($ < 32768) && (ntc_rg80_e - ntc_rg80 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg80:
var_memory_bankpage_bankpage:			dw 0
ntc_rg80_e:
			IF ($ < 32768) && (ntc_rg81_e - ntc_rg81 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg81:
var_hyp_setting_setting:			dw 0
ntc_rg81_e:
			IF ($ < 32768) && (ntc_rg82_e - ntc_rg82 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg82:
			db 82			; capacity
var_ob:			ds 83
ntc_rg82_e:
			IF ($ < 32768) && (ntc_rg83_e - ntc_rg83 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg83:
			db 72			; capacity
var_a:			ds 73
ntc_rg83_e:
			IF ($ < 32768) && (ntc_rg84_e - ntc_rg84 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg84:
var_bd:			dw 0
ntc_rg84_e:
			IF ($ < 32768) && (ntc_rg85_e - ntc_rg85 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg85:
var_hk:			dw 0
ntc_rg85_e:
			IF ($ < 32768) && (ntc_rg86_e - ntc_rg86 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg86:
var_hot_take_take:			dw 0
ntc_rg86_e:
			IF ($ < 32768) && (ntc_rg87_e - ntc_rg87 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg87:
var_back:			dw 0
ntc_rg87_e:
			IF ($ < 32768) && (ntc_rg88_e - ntc_rg88 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg88:
var_pk:			dw 0
ntc_rg88_e:
			IF ($ < 32768) && (ntc_rg89_e - ntc_rg89 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg89:
var_wt:			dw 0
ntc_rg89_e:
			IF ($ < 32768) && (ntc_rg90_e - ntc_rg90 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg90:
var_hot_control_control:			dw 0
ntc_rg90_e:
			IF ($ < 32768) && (ntc_rg91_e - ntc_rg91 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg91:
var_hot_held_held:			dw 0
ntc_rg91_e:
			IF ($ < 32768) && (ntc_rg92_e - ntc_rg92 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg92:
var_running_running:			dw 0
ntc_rg92_e:
			IF ($ < 32768) && (ntc_rg93_e - ntc_rg93 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg93:
var_td:			dw 0
ntc_rg93_e:
			IF ($ < 32768) && (ntc_rg94_e - ntc_rg94 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg94:
var_tc:			dw 0
ntc_rg94_e:
			IF ($ < 32768) && (ntc_rg95_e - ntc_rg95 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg95:
var_quit:			dw 0
ntc_rg95_e:
			IF ($ < 32768) && (ntc_rg96_e - ntc_rg96 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg96:
var_hyp_scr_scr:			dw 0
ntc_rg96_e:
			IF ($ < 32768) && (ntc_rg97_e - ntc_rg97 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg97:
var_runs:			dw 0
ntc_rg97_e:
			IF ($ < 32768) && (ntc_rg98_e - ntc_rg98 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg98:
p_running_rs:			dw 0
ntc_rg98_e:
			IF ($ < 32768) && (ntc_rg99_e - ntc_rg99 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg99:
var_running_j:			dw 0
ntc_rg99_e:
			IF ($ < 32768) && (ntc_rg100_e - ntc_rg100 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg100:
for20_l:			dw 0
ntc_rg100_e:
			IF ($ < 32768) && (ntc_rg101_e - ntc_rg101 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg101:
p_ready_rs:			dw 0
ntc_rg101_e:
			IF ($ < 32768) && (ntc_rg102_e - ntc_rg102 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg102:
var_ready_t:			dw 0
ntc_rg102_e:
			IF ($ < 32768) && (ntc_rg103_e - ntc_rg103 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg103:
var_ready_ready:			dw 0
ntc_rg103_e:
			IF ($ < 32768) && (ntc_rg104_e - ntc_rg104 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg104:
p_runnext_rs:			dw 0
ntc_rg104_e:
			IF ($ < 32768) && (ntc_rg105_e - ntc_rg105 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg105:
var_runnext_n:			dw 0
ntc_rg105_e:
			IF ($ < 32768) && (ntc_rg106_e - ntc_rg106 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg106:
var_runnext_t:			dw 0
ntc_rg106_e:
			IF ($ < 32768) && (ntc_rg107_e - ntc_rg107 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg107:
var_runnext_r:			dw 0
ntc_rg107_e:
			IF ($ < 32768) && (ntc_rg108_e - ntc_rg108 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg108:
var_runnext_c:			dw 0
ntc_rg108_e:
			IF ($ < 32768) && (ntc_rg109_e - ntc_rg109 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg109:
var_runnext_q:			dw 0
ntc_rg109_e:
			IF ($ < 32768) && (ntc_rg110_e - ntc_rg110 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg110:
var_fr:			dw 0
ntc_rg110_e:
			IF ($ < 32768) && (ntc_rg111_e - ntc_rg111 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg111:
for28_l:			dw 0
ntc_rg111_e:
			IF ($ < 32768) && (ntc_rg112_e - ntc_rg112 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg112:
var_cur:			dw 0
ntc_rg112_e:
			IF ($ < 32768) && (ntc_rg113_e - ntc_rg113 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg113:
var_hyp_run_run:			dw 0
ntc_rg113_e:
			IF ($ < 32768) && (ntc_rg114_e - ntc_rg114 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg114:
var_far_far:			dw 0, 0
ntc_rg114_e:
			IF ($ < 32768) && (ntc_rg115_e - ntc_rg115 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg115:
var_memory_readbyte_readbyte:			dw 0
ntc_rg115_e:
			IF ($ < 32768) && (ntc_rg116_e - ntc_rg116 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg116:
var_hyp_count_count:			dw 0
ntc_rg116_e:
			IF ($ < 32768) && (ntc_rg117_e - ntc_rg117 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg117:
var_hyp_fn_fn:			dw 0
ntc_rg117_e:
			IF ($ < 32768) && (ntc_rg118_e - ntc_rg118 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg118:
p_bdos_rs:			dw 0
ntc_rg118_e:
			IF ($ < 32768) && (ntc_rg119_e - ntc_rg119 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg119:
var_bdos_t:			dw 0
ntc_rg119_e:
			IF ($ < 32768) && (ntc_rg120_e - ntc_rg120 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg120:
var_bdos_f:			dw 0
ntc_rg120_e:
			IF ($ < 32768) && (ntc_rg121_e - ntc_rg121 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg121:
var_bdos_e:			dw 0
ntc_rg121_e:
			IF ($ < 32768) && (ntc_rg122_e - ntc_rg122 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg122:
var_bdos_a:			dw 0
ntc_rg122_e:
			IF ($ < 32768) && (ntc_rg123_e - ntc_rg123 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg123:
var_hyp_arg_arg:			dw 0
ntc_rg123_e:
			IF ($ < 32768) && (ntc_rg124_e - ntc_rg124 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg124:
var_bdos___sel45:			dw 0
ntc_rg124_e:
			IF ($ < 32768) && (ntc_rg125_e - ntc_rg125 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg125:
for48_l:			dw 0
ntc_rg125_e:
			IF ($ < 32768) && (ntc_rg126_e - ntc_rg126 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg126:
var_ramdisc_ramdisc:			dw 0
ntc_rg126_e:
			IF ($ < 32768) && (ntc_rg127_e - ntc_rg127 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg127:
var_sys_sys:			dw 0
ntc_rg127_e:
			IF ($ < 32768) && (ntc_rg128_e - ntc_rg128 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg128:
p_ramdisc_rs:			dw 0
ntc_rg128_e:
			IF ($ < 32768) && (ntc_rg129_e - ntc_rg129 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg129:
var_ramdisc_t:			dw 0
ntc_rg129_e:
			IF ($ < 32768) && (ntc_rg130_e - ntc_rg130 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg130:
var_ramdisc_p:			dw 0
ntc_rg130_e:
			IF ($ < 32768) && (ntc_rg131_e - ntc_rg131 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg131:
var_ramdisc_g:			dw 0
ntc_rg131_e:
			IF ($ < 32768) && (ntc_rg132_e - ntc_rg132 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg132:
var_ramdisc_o:			dw 0
ntc_rg132_e:
			IF ($ < 32768) && (ntc_rg133_e - ntc_rg133 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg133:
var_ramdisc_f:			dw 0, 0
ntc_rg133_e:
			IF ($ < 32768) && (ntc_rg134_e - ntc_rg134 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg134:
var_memory_readword_readword:			dw 0
ntc_rg134_e:
			IF ($ < 32768) && (ntc_rg135_e - ntc_rg135 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg135:
var_hyp_farptr_farptr:			dw 0, 0
ntc_rg135_e:
			IF ($ < 32768) && (ntc_rg136_e - ntc_rg136 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg136:
var_memory_copy_copy:			dw 0
ntc_rg136_e:
			IF ($ < 32768) && (ntc_rg137_e - ntc_rg137 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg137:
p_storesize_rs:			dw 0
ntc_rg137_e:
			IF ($ < 32768) && (ntc_rg138_e - ntc_rg138 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg138:
var_storesize_t:			dw 0
ntc_rg138_e:
			IF ($ < 32768) && (ntc_rg139_e - ntc_rg139 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg139:
var_storesize_kb:			dw 0
ntc_rg139_e:
			IF ($ < 32768) && (ntc_rg140_e - ntc_rg140 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg140:
var_storesize_storesize:			dw 0
ntc_rg140_e:
			IF ($ < 32768) && (ntc_rg141_e - ntc_rg141 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg141:
var_storesize_n:			dw 0
ntc_rg141_e:
			IF ($ < 32768) && (ntc_rg142_e - ntc_rg142 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg142:
var_storesize_j:			dw 0
ntc_rg142_e:
			IF ($ < 32768) && (ntc_rg143_e - ntc_rg143 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg143:
var_storesize_g:			dw 0
ntc_rg143_e:
			IF ($ < 32768) && (ntc_rg144_e - ntc_rg144 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg144:
var_memory_freepage_freepage:			dw 0
ntc_rg144_e:
			IF ($ < 32768) && (ntc_rg145_e - ntc_rg145 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg145:
p_storefree_rs:			dw 0
ntc_rg145_e:
			IF ($ < 32768) && (ntc_rg146_e - ntc_rg146 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg146:
var_storefree_t:			dw 0
ntc_rg146_e:
			IF ($ < 32768) && (ntc_rg147_e - ntc_rg147 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg147:
var_storefree_r:			dw 0
ntc_rg147_e:
			IF ($ < 32768) && (ntc_rg148_e - ntc_rg148 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg148:
p_sys_rs:			dw 0
ntc_rg148_e:
			IF ($ < 32768) && (ntc_rg149_e - ntc_rg149 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg149:
var_sys_t:			dw 0
ntc_rg149_e:
			IF ($ < 32768) && (ntc_rg150_e - ntc_rg150 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg150:
var_sys_p:			dw 0
ntc_rg150_e:
			IF ($ < 32768) && (ntc_rg151_e - ntc_rg151 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg151:
var_sys_o:			dw 0
ntc_rg151_e:
			IF ($ < 32768) && (ntc_rg152_e - ntc_rg152 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg152:
var_sys_s:			dw 0
ntc_rg152_e:
			IF ($ < 32768) && (ntc_rg153_e - ntc_rg153 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg153:
var_sys_d:			dw 0
ntc_rg153_e:
			IF ($ < 32768) && (ntc_rg154_e - ntc_rg154 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg154:
var_txs:			dw 0
ntc_rg154_e:
			IF ($ < 32768) && (ntc_rg155_e - ntc_rg155 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg155:
var_memory_tableend_tableend:			dw 0
ntc_rg155_e:
			IF ($ < 32768) && (ntc_rg156_e - ntc_rg156 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg156:
var_memory_top_top:			dw 0
ntc_rg156_e:
			IF ($ < 32768) && (ntc_rg157_e - ntc_rg157 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg157:
var_memory_pages_pages:			dw 0
ntc_rg157_e:
			IF ($ < 32768) && (ntc_rg158_e - ntc_rg158 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg158:
			db 60			; capacity
var_en:			ds 61
ntc_rg158_e:
			IF ($ < 32768) && (ntc_rg159_e - ntc_rg159 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg159:
			db 82			; capacity
var_memory_map_map:			ds 83
ntc_rg159_e:
			IF ($ < 32768) && (ntc_rg160_e - ntc_rg160 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg160:
p_puten_rs:			dw 0
ntc_rg160_e:
			IF ($ < 32768) && (ntc_rg161_e - ntc_rg161 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg161:
var_puten_t:			dw 0
ntc_rg161_e:
			IF ($ < 32768) && (ntc_rg162_e - ntc_rg162 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg162:
var_puten_a:			dw 0
ntc_rg162_e:
			IF ($ < 32768) && (ntc_rg163_e - ntc_rg163 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg163:
var_nearp_nearp:			dw 0, 0
ntc_rg163_e:
			IF ($ < 32768) && (ntc_rg164_e - ntc_rg164 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg164:
p_hopen_rs:			dw 0
ntc_rg164_e:
			IF ($ < 32768) && (ntc_rg165_e - ntc_rg165 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg165:
var_hopen_hopen:			dw 0
ntc_rg165_e:
			IF ($ < 32768) && (ntc_rg166_e - ntc_rg166 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg166:
			db 16			; capacity
var_dn:			ds 17
ntc_rg166_e:
			IF ($ < 32768) && (ntc_rg167_e - ntc_rg167 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg167:
p_hclose_rs:			dw 0
ntc_rg167_e:
			IF ($ < 32768) && (ntc_rg168_e - ntc_rg168 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg168:
var_hclose_r:			dw 0
ntc_rg168_e:
			IF ($ < 32768) && (ntc_rg169_e - ntc_rg169 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg169:
p_filesshut_rs:			dw 0
ntc_rg169_e:
			IF ($ < 32768) && (ntc_rg170_e - ntc_rg170 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg170:
var_filesshut_t:			dw 0
ntc_rg170_e:
			IF ($ < 32768) && (ntc_rg171_e - ntc_rg171 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg171:
var_filesshut_r:			dw 0
ntc_rg171_e:
			IF ($ < 32768) && (ntc_rg172_e - ntc_rg172 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg172:
p_collected_rs:			dw 0
ntc_rg172_e:
			IF ($ < 32768) && (ntc_rg173_e - ntc_rg173 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg173:
var_collected_t:			dw 0
ntc_rg173_e:
			IF ($ < 32768) && (ntc_rg174_e - ntc_rg174 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg174:
var_collected_n:			dw 0
ntc_rg174_e:
			IF ($ < 32768) && (ntc_rg175_e - ntc_rg175 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg175:
p_puts_rs:			dw 0
ntc_rg175_e:
			IF ($ < 32768) && (ntc_rg176_e - ntc_rg176 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg176:
var_puts_t:			dw 0
ntc_rg176_e:
			IF ($ < 32768) && (ntc_rg177_e - ntc_rg177 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg177:
			db 82			; capacity
var_puts_s:			ds 83
ntc_rg177_e:
			IF ($ < 32768) && (ntc_rg178_e - ntc_rg178 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg178:
p_putln_rs:			dw 0
ntc_rg178_e:
			IF ($ < 32768) && (ntc_rg179_e - ntc_rg179 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg179:
var_putln_t:			dw 0
ntc_rg179_e:
			IF ($ < 32768) && (ntc_rg180_e - ntc_rg180 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg180:
			db 82			; capacity
var_putln_s:			ds 83
ntc_rg180_e:
			IF ($ < 32768) && (ntc_rg181_e - ntc_rg181 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg181:
p_putc_rs:			dw 0
ntc_rg181_e:
			IF ($ < 32768) && (ntc_rg182_e - ntc_rg182 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg182:
var_putc_t:			dw 0
ntc_rg182_e:
			IF ($ < 32768) && (ntc_rg183_e - ntc_rg183 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg183:
var_putc_c:			dw 0
ntc_rg183_e:
			IF ($ < 32768) && (ntc_rg184_e - ntc_rg184 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg184:
p_nearp_rs:			dw 0
ntc_rg184_e:
			IF ($ < 32768) && (ntc_rg185_e - ntc_rg185 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg185:
var_nearp_p:			dw 0
ntc_rg185_e:
			IF ($ < 32768) && (ntc_rg186_e - ntc_rg186 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg186:
p_far_rs:			dw 0
ntc_rg186_e:
			IF ($ < 32768) && (ntc_rg187_e - ntc_rg187 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg187:
var_far_t:			dw 0
ntc_rg187_e:
			IF ($ < 32768) && (ntc_rg188_e - ntc_rg188 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg188:
var_far_a:			dw 0
ntc_rg188_e:
			IF ($ < 32768) && (ntc_rg189_e - ntc_rg189 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg189:
p_clst_rs:			dw 0
ntc_rg189_e:
			IF ($ < 32768) && (ntc_rg190_e - ntc_rg190 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg190:
var_clst_t:			dw 0
ntc_rg190_e:
			IF ($ < 32768) && (ntc_rg191_e - ntc_rg191 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg191:
p_tofront_rs:			dw 0
ntc_rg191_e:
			IF ($ < 32768) && (ntc_rg192_e - ntc_rg192 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg192:
var_tofront_t:			dw 0
ntc_rg192_e:
			IF ($ < 32768) && (ntc_rg193_e - ntc_rg193 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg193:
var_tofront_r:			dw 0
ntc_rg193_e:
			IF ($ < 32768) && (ntc_rg194_e - ntc_rg194 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg194:
p_setmode_rs:			dw 0
ntc_rg194_e:
			IF ($ < 32768) && (ntc_rg195_e - ntc_rg195 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg195:
var_setmode_t:			dw 0
ntc_rg195_e:
			IF ($ < 32768) && (ntc_rg196_e - ntc_rg196 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg196:
var_setmode_m:			dw 0
ntc_rg196_e:
			IF ($ < 32768) && (ntc_rg197_e - ntc_rg197 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg197:
var_setmode_r:			dw 0
ntc_rg197_e:
			IF ($ < 32768) && (ntc_rg198_e - ntc_rg198 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg198:
			db 82			; capacity
var_n_n:			ds 83
ntc_rg198_e:
			IF ($ < 32768) && (ntc_rg199_e - ntc_rg199 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg199:
p_showtop_rs:			dw 0
ntc_rg199_e:
			IF ($ < 32768) && (ntc_rg200_e - ntc_rg200 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg200:
var_showtop_j:			dw 0
ntc_rg200_e:
			IF ($ < 32768) && (ntc_rg201_e - ntc_rg201 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg201:
p_toplines_rs:			dw 0
ntc_rg201_e:
			IF ($ < 32768) && (ntc_rg202_e - ntc_rg202 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg202:
var_toplines_mark:			dw 0
ntc_rg202_e:
			IF ($ < 32768) && (ntc_rg203_e - ntc_rg203 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg203:
var_toplines_keys:			dw 0
ntc_rg203_e:
			IF ($ < 32768) && (ntc_rg204_e - ntc_rg204 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg204:
var_toplines_j:			dw 0
ntc_rg204_e:
			IF ($ < 32768) && (ntc_rg205_e - ntc_rg205 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg205:
			db 14			; capacity
var_toplines_s:			ds 15
ntc_rg205_e:
			IF ($ < 32768) && (ntc_rg206_e - ntc_rg206 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg206:
var_txn:			dw 0
ntc_rg206_e:
			IF ($ < 32768) && (ntc_rg207_e - ntc_rg207 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg207:
			db 82			; capacity
var_sk_sk:			ds 83
ntc_rg207_e:
			IF ($ < 32768) && (ntc_rg208_e - ntc_rg208 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg208:
for88_l:			dw 0
ntc_rg208_e:
			IF ($ < 32768) && (ntc_rg209_e - ntc_rg209 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg209:
var_ld:			dw 0
ntc_rg209_e:
			IF ($ < 32768) && (ntc_rg210_e - ntc_rg210 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg210:
var_rate_rate:			dw 0
ntc_rg210_e:
			IF ($ < 32768) && (ntc_rg211_e - ntc_rg211 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg211:
			db 82			; capacity
var_pad_pad:			ds 83
ntc_rg211_e:
			IF ($ < 32768) && (ntc_rg212_e - ntc_rg212 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg212:
p_totals_rs:			dw 0
ntc_rg212_e:
			IF ($ < 32768) && (ntc_rg213_e - ntc_rg213 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg213:
var_memory_ramsize_ramsize:			dw 0
ntc_rg213_e:
			IF ($ < 32768) && (ntc_rg214_e - ntc_rg214 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg214:
var_memory_freepages_freepages:			dw 0
ntc_rg214_e:
			IF ($ < 32768) && (ntc_rg215_e - ntc_rg215 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg215:
p_topadd_rs:			dw 0
ntc_rg215_e:
			IF ($ < 32768) && (ntc_rg216_e - ntc_rg216 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg216:
			db 82			; capacity
var_topadd_s:			ds 83
ntc_rg216_e:
			IF ($ < 32768) && (ntc_rg217_e - ntc_rg217 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg217:
p_roll_rs:			dw 0
ntc_rg217_e:
			IF ($ < 32768) && (ntc_rg218_e - ntc_rg218 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg218:
var_roll_j:			dw 0
ntc_rg218_e:
			IF ($ < 32768) && (ntc_rg219_e - ntc_rg219 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg219:
for93_l:			dw 0
ntc_rg219_e:
			IF ($ < 32768) && (ntc_rg220_e - ntc_rg220 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg220:
p_pad_rs:			dw 0
ntc_rg220_e:
			IF ($ < 32768) && (ntc_rg221_e - ntc_rg221 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg221:
var_pad_v:			dw 0
ntc_rg221_e:
			IF ($ < 32768) && (ntc_rg222_e - ntc_rg222 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg222:
p_rate_rs:			dw 0
ntc_rg222_e:
			IF ($ < 32768) && (ntc_rg223_e - ntc_rg223 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg223:
var_rate_n:			dw 0
ntc_rg223_e:
			IF ($ < 32768) && (ntc_rg224_e - ntc_rg224 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg224:
var_rate_d:			dw 0
ntc_rg224_e:
			IF ($ < 32768) && (ntc_rg225_e - ntc_rg225 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg225:
p_install_rs:			dw 0
ntc_rg225_e:
			IF ($ < 32768) && (ntc_rg226_e - ntc_rg226 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg226:
var_install_t:			dw 0
ntc_rg226_e:
			IF ($ < 32768) && (ntc_rg227_e - ntc_rg227 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg227:
var_install_p:			dw 0
ntc_rg227_e:
			IF ($ < 32768) && (ntc_rg228_e - ntc_rg228 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg228:
var_install_n:			dw 0
ntc_rg228_e:
			IF ($ < 32768) && (ntc_rg229_e - ntc_rg229 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg229:
p_resetslot_rs:			dw 0
ntc_rg229_e:
			IF ($ < 32768) && (ntc_rg230_e - ntc_rg230 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg230:
var_resetslot_s:			dw 0
ntc_rg230_e:
			IF ($ < 32768) && (ntc_rg231_e - ntc_rg231 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg231:
p_openslot_rs:			dw 0
ntc_rg231_e:
			IF ($ < 32768) && (ntc_rg232_e - ntc_rg232 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg232:
var_openslot_t:			dw 0
ntc_rg232_e:
			IF ($ < 32768) && (ntc_rg233_e - ntc_rg233 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg233:
p_sk_rs:			dw 0
ntc_rg233_e:
			IF ($ < 32768) && (ntc_rg234_e - ntc_rg234 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg234:
p_getnm_rs:			dw 0
ntc_rg234_e:
			IF ($ < 32768) && (ntc_rg235_e - ntc_rg235 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg235:
var_getnm_t:			dw 0
ntc_rg235_e:
			IF ($ < 32768) && (ntc_rg236_e - ntc_rg236 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg236:
var_getnm_n:			dw 0
ntc_rg236_e:
			IF ($ < 32768) && (ntc_rg237_e - ntc_rg237 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg237:
p_n_rs:			dw 0
ntc_rg237_e:
			IF ($ < 32768) && (ntc_rg238_e - ntc_rg238 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg238:
var_n_v:			dw 0
ntc_rg238_e:
			IF ($ < 32768) && (ntc_rg239_e - ntc_rg239 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg239:
p_prompt_rs:			dw 0
ntc_rg239_e:
			IF ($ < 32768) && (ntc_rg240_e - ntc_rg240 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg240:
var_prompt_t:			dw 0
ntc_rg240_e:
			IF ($ < 32768) && (ntc_rg241_e - ntc_rg241 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg241:
p_keyin_rs:			dw 0
ntc_rg241_e:
			IF ($ < 32768) && (ntc_rg242_e - ntc_rg242 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg242:
var_keyin_k:			dw 0
ntc_rg242_e:
			IF ($ < 32768) && (ntc_rg243_e - ntc_rg243 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg243:
var_keyin_t:			dw 0
ntc_rg243_e:
			IF ($ < 32768) && (ntc_rg244_e - ntc_rg244 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg244:
var_keyin_n:			dw 0
ntc_rg244_e:
			IF ($ < 32768) && (ntc_rg245_e - ntc_rg245 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg245:
p_command_rs:			dw 0
ntc_rg245_e:
			IF ($ < 32768) && (ntc_rg246_e - ntc_rg246 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg246:
var_command_t:			dw 0
ntc_rg246_e:
			IF ($ < 32768) && (ntc_rg247_e - ntc_rg247 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg247:
			db 72			; capacity
var_command_c:			ds 73
ntc_rg247_e:
			IF ($ < 32768) && (ntc_rg248_e - ntc_rg248 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg248:
var_command_p:			dw 0
ntc_rg248_e:
			IF ($ < 32768) && (ntc_rg249_e - ntc_rg249 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg249:
var_command_s:			dw 0
ntc_rg249_e:
			IF ($ < 32768) && (ntc_rg250_e - ntc_rg250 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg250:
			db 72			; capacity
var_b:			ds 73
ntc_rg250_e:
			IF ($ < 32768) && (ntc_rg251_e - ntc_rg251 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg251:
			db 82			; capacity
var_command___sel108:			ds 83
ntc_rg251_e:
			IF ($ < 32768) && (ntc_rg252_e - ntc_rg252 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg252:
var_bare:			dw 0
ntc_rg252_e:
			IF ($ < 32768) && (ntc_rg253_e - ntc_rg253 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg253:
p_starttask_rs:			dw 0
ntc_rg253_e:
			IF ($ < 32768) && (ntc_rg254_e - ntc_rg254 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg254:
var_starttask_t:			dw 0
ntc_rg254_e:
			IF ($ < 32768) && (ntc_rg255_e - ntc_rg255 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg255:
var_starttask_s:			dw 0
ntc_rg255_e:
			IF ($ < 32768) && (ntc_rg256_e - ntc_rg256 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg256:
var_starttask_h:			dw 0
ntc_rg256_e:
			IF ($ < 32768) && (ntc_rg257_e - ntc_rg257 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg257:
var_starttask_n:			dw 0
ntc_rg257_e:
			IF ($ < 32768) && (ntc_rg258_e - ntc_rg258 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg258:
var_starttask_rest:			dw 0
ntc_rg258_e:
			IF ($ < 32768) && (ntc_rg259_e - ntc_rg259 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg259:
var_starttask_com:			dw 0
ntc_rg259_e:
			IF ($ < 32768) && (ntc_rg260_e - ntc_rg260 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg260:
			db 72			; capacity
var_starttask_w:			ds 73
ntc_rg260_e:
			IF ($ < 32768) && (ntc_rg261_e - ntc_rg261 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg261:
var_starttask_d:			dw 0
ntc_rg261_e:
			IF ($ < 32768) && (ntc_rg262_e - ntc_rg262 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg262:
var_hyp_drive_drive:			dw 0
ntc_rg262_e:
			IF ($ < 32768) && (ntc_rg263_e - ntc_rg263 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg263:
var_hyp_info_info:			dw 0
ntc_rg263_e:
			IF ($ < 32768) && (ntc_rg264_e - ntc_rg264 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg264:
p_notfound_rs:			dw 0
ntc_rg264_e:
			IF ($ < 32768) && (ntc_rg265_e - ntc_rg265 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg265:
var_notfound_t:			dw 0
ntc_rg265_e:
			IF ($ < 32768) && (ntc_rg266_e - ntc_rg266 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg266:
p_owndrive_rs:			dw 0
ntc_rg266_e:
			IF ($ < 32768) && (ntc_rg267_e - ntc_rg267 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg267:
var_owndrive_t:			dw 0
ntc_rg267_e:
			IF ($ < 32768) && (ntc_rg268_e - ntc_rg268 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg268:
var_owndrive_r:			dw 0
ntc_rg268_e:
			IF ($ < 32768) && (ntc_rg269_e - ntc_rg269 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg269:
p_endtask_rs:			dw 0
ntc_rg269_e:
			IF ($ < 32768) && (ntc_rg270_e - ntc_rg270 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg270:
var_endtask_t:			dw 0
ntc_rg270_e:
			IF ($ < 32768) && (ntc_rg271_e - ntc_rg271 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg271:
var_endtask_c:			dw 0
ntc_rg271_e:
			IF ($ < 32768) && (ntc_rg272_e - ntc_rg272 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg272:
var_hyp_hps:			dw 0
ntc_rg272_e:
			IF ($ < 32768) && (ntc_rg273_e - ntc_rg273 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg273:
p_hyp_usedriver_rs:			dw 0
ntc_rg273_e:
			IF ($ < 32768) && (ntc_rg274_e - ntc_rg274 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg274:
var_hyp_usedriver_b:			dw 0
ntc_rg274_e:
			IF ($ < 32768) && (ntc_rg275_e - ntc_rg275 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg275:
var_hyp_dxb:			dw 0
ntc_rg275_e:
			IF ($ < 32768) && (ntc_rg276_e - ntc_rg276 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg276:
var_hyp_drs:			dw 0
ntc_rg276_e:
			IF ($ < 32768) && (ntc_rg277_e - ntc_rg277 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg277:
var_hyp_hsp:			dw 0
ntc_rg277_e:
			IF ($ < 32768) && (ntc_rg278_e - ntc_rg278 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg278:
p_hyp_con_rs:			dw 0
ntc_rg278_e:
			IF ($ < 32768) && (ntc_rg279_e - ntc_rg279 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg279:
var_hyp_con_pg:			dw 0
ntc_rg279_e:
			IF ($ < 32768) && (ntc_rg280_e - ntc_rg280 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg280:
var_hyp_con_src:			dw 0
ntc_rg280_e:
			IF ($ < 32768) && (ntc_rg281_e - ntc_rg281 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg281:
var_hyp_con_n:			dw 0
ntc_rg281_e:
			IF ($ < 32768) && (ntc_rg282_e - ntc_rg282 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg282:
var_hyp_con_front:			dw 0
ntc_rg282_e:
			IF ($ < 32768) && (ntc_rg283_e - ntc_rg283 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg283:
var_hyp_ccu:			dw 0
ntc_rg283_e:
			IF ($ < 32768) && (ntc_rg284_e - ntc_rg284 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg284:
var_hyp_nta:			dw 0
ntc_rg284_e:
			IF ($ < 32768) && (ntc_rg285_e - ntc_rg285 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg285:
var_hyp_ntb:			dw 0
ntc_rg285_e:
			IF ($ < 32768) && (ntc_rg286_e - ntc_rg286 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg286:
var_hyp_sco:			dw 0
ntc_rg286_e:
			IF ($ < 32768) && (ntc_rg287_e - ntc_rg287 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg287:
var_hyp_scc:			dw 0
ntc_rg287_e:
			IF ($ < 32768) && (ntc_rg288_e - ntc_rg288 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg288:
var_hyp_pon:			dw 0
ntc_rg288_e:
			IF ($ < 32768) && (ntc_rg289_e - ntc_rg289 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg289:
var_hyp_ntu:			dw 0
ntc_rg289_e:
			IF ($ < 32768) && (ntc_rg290_e - ntc_rg290 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg290:
p_hyp_say_rs:			dw 0
ntc_rg290_e:
			IF ($ < 32768) && (ntc_rg291_e - ntc_rg291 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg291:
var_hyp_say_p:			dw 0
ntc_rg291_e:
			IF ($ < 32768) && (ntc_rg292_e - ntc_rg292 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg292:
var_hyp_say_n:			dw 0
ntc_rg292_e:
			IF ($ < 32768) && (ntc_rg293_e - ntc_rg293 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg293:
var_hyp_say_col:			dw 0
ntc_rg293_e:
			IF ($ < 32768) && (ntc_rg294_e - ntc_rg294 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg294:
var_hyp_say_row:			dw 0
ntc_rg294_e:
			IF ($ < 32768) && (ntc_rg295_e - ntc_rg295 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg295:
p_hyp_scr_rs:			dw 0
ntc_rg295_e:
			IF ($ < 32768) && (ntc_rg296_e - ntc_rg296 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg296:
var_hyp_scr_m:			dw 0
ntc_rg296_e:
			IF ($ < 32768) && (ntc_rg297_e - ntc_rg297 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg297:
var_hyp_scr_k:			dw 0
ntc_rg297_e:
			IF ($ < 32768) && (ntc_rg298_e - ntc_rg298 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg298:
var_hyp_scw:			dw 0
ntc_rg298_e:
			IF ($ < 32768) && (ntc_rg299_e - ntc_rg299 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg299:
p_hyp_keyrep_rs:			dw 0
ntc_rg299_e:
			IF ($ < 32768) && (ntc_rg300_e - ntc_rg300 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg300:
var_hyp_keyrep_f:			dw 0
ntc_rg300_e:
			IF ($ < 32768) && (ntc_rg301_e - ntc_rg301 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg301:
p_hyp_show_rs:			dw 0
ntc_rg301_e:
			IF ($ < 32768) && (ntc_rg302_e - ntc_rg302 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg302:
var_hyp_show_pg:			dw 0
ntc_rg302_e:
			IF ($ < 32768) && (ntc_rg303_e - ntc_rg303 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg303:
p_hyp_reply_rs:			dw 0
ntc_rg303_e:
			IF ($ < 32768) && (ntc_rg304_e - ntc_rg304 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg304:
var_hyp_reply_a:			dw 0
ntc_rg304_e:
			IF ($ < 32768) && (ntc_rg305_e - ntc_rg305 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg305:
var_hyp_reply_hl:			dw 0
ntc_rg305_e:
			IF ($ < 32768) && (ntc_rg306_e - ntc_rg306 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg306:
var_hyp_ra:			dw 0
ntc_rg306_e:
			IF ($ < 32768) && (ntc_rg307_e - ntc_rg307 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg307:
var_hyp_rhl:			dw 0
ntc_rg307_e:
			IF ($ < 32768) && (ntc_rg308_e - ntc_rg308 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg308:
p_hyp_fn_rs:			dw 0
ntc_rg308_e:
			IF ($ < 32768) && (ntc_rg309_e - ntc_rg309 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg309:
var_hyp_rfn:			dw 0
ntc_rg309_e:
			IF ($ < 32768) && (ntc_rg310_e - ntc_rg310 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg310:
p_hyp_arg_rs:			dw 0
ntc_rg310_e:
			IF ($ < 32768) && (ntc_rg311_e - ntc_rg311 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg311:
var_hyp_rde:			dw 0
ntc_rg311_e:
			IF ($ < 32768) && (ntc_rg312_e - ntc_rg312 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg312:
p_hyp_count_rs:			dw 0
ntc_rg312_e:
			IF ($ < 32768) && (ntc_rg313_e - ntc_rg313 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg313:
var_hyp_rcnt:			dw 0
ntc_rg313_e:
			IF ($ < 32768) && (ntc_rg314_e - ntc_rg314 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg314:
p_hyp_run_rs:			dw 0
ntc_rg314_e:
			IF ($ < 32768) && (ntc_rg315_e - ntc_rg315 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg315:
var_hyp_run_setting:			dw 0
ntc_rg315_e:
			IF ($ < 32768) && (ntc_rg316_e - ntc_rg316 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg316:
var_hyp_sps:			dw 0
ntc_rg316_e:
			IF ($ < 32768) && (ntc_rg317_e - ntc_rg317 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg317:
var_hyp_rrom:			dw 0
ntc_rg317_e:
			IF ($ < 32768) && (ntc_rg318_e - ntc_rg318 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg318:
var_hyp_slc:			dw 0
ntc_rg318_e:
			IF ($ < 32768) && (ntc_rg319_e - ntc_rg319 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg319:
var_hyp_rclr:			dw 0
ntc_rg319_e:
			IF ($ < 32768) && (ntc_rg320_e - ntc_rg320 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg320:
p_hyp_vdu_rs:			dw 0
ntc_rg320_e:
			IF ($ < 32768) && (ntc_rg321_e - ntc_rg321 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg321:
var_hyp_vdu_on:			dw 0
ntc_rg321_e:
			IF ($ < 32768) && (ntc_rg322_e - ntc_rg322 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg322:
p_hyp_filecall_rs:			dw 0
ntc_rg322_e:
			IF ($ < 32768) && (ntc_rg323_e - ntc_rg323 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg323:
var_hyp_filecall_f:			dw 0
ntc_rg323_e:
			IF ($ < 32768) && (ntc_rg324_e - ntc_rg324 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg324:
var_hyp_filecall_fcb:			dw 0
ntc_rg324_e:
			IF ($ < 32768) && (ntc_rg325_e - ntc_rg325 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg325:
var_hyp_filecall_slot:			dw 0
ntc_rg325_e:
			IF ($ < 32768) && (ntc_rg326_e - ntc_rg326 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg326:
var_hyp_filecall_setting:			dw 0
ntc_rg326_e:
			IF ($ < 32768) && (ntc_rg327_e - ntc_rg327 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg327:
var_hyp_filecall_dma:			dw 0
ntc_rg327_e:
			IF ($ < 32768) && (ntc_rg328_e - ntc_rg328 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg328:
var_hyp_filecall_drive:			dw 0
ntc_rg328_e:
			IF ($ < 32768) && (ntc_rg329_e - ntc_rg329 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg329:
var_hyp_filecall_buf:			dw 0
ntc_rg329_e:
			IF ($ < 32768) && (ntc_rg330_e - ntc_rg330 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg330:
var_hyp_hdr:			dw 0
ntc_rg330_e:
			IF ($ < 32768) && (ntc_rg331_e - ntc_rg331 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg331:
var_hyp_fin:			dw 0
ntc_rg331_e:
			IF ($ < 32768) && (ntc_rg332_e - ntc_rg332 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg332:
var_hyp_fout:			dw 0
ntc_rg332_e:
			IF ($ < 32768) && (ntc_rg333_e - ntc_rg333 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg333:
p_hyp_fileshut_rs:			dw 0
ntc_rg333_e:
			IF ($ < 32768) && (ntc_rg334_e - ntc_rg334 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg334:
var_hyp_fileshut_slot:			dw 0
ntc_rg334_e:
			IF ($ < 32768) && (ntc_rg335_e - ntc_rg335 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg335:
var_hyp_svp:			dw 0
ntc_rg335_e:
			IF ($ < 32768) && (ntc_rg336_e - ntc_rg336 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg336:
p_hyp_svcvars_rs:			dw 0
ntc_rg336_e:
			IF ($ < 32768) && (ntc_rg337_e - ntc_rg337 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg337:
var_hyp_svcvars_vst:			dw 0
ntc_rg337_e:
			IF ($ < 32768) && (ntc_rg338_e - ntc_rg338 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg338:
var_hyp_svcvars_vsg:			dw 0
ntc_rg338_e:
			IF ($ < 32768) && (ntc_rg339_e - ntc_rg339 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg339:
var_hyp_svcvars_vns:			dw 0
ntc_rg339_e:
			IF ($ < 32768) && (ntc_rg340_e - ntc_rg340 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg340:
var_hyp_svcvars_vfr:			dw 0
ntc_rg340_e:
			IF ($ < 32768) && (ntc_rg341_e - ntc_rg341 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg341:
var_hyp_svcvars_vdp:			dw 0
ntc_rg341_e:
			IF ($ < 32768) && (ntc_rg342_e - ntc_rg342 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg342:
var_hyp_svst:			dw 0
ntc_rg342_e:
			IF ($ < 32768) && (ntc_rg343_e - ntc_rg343 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg343:
var_hyp_svsg:			dw 0
ntc_rg343_e:
			IF ($ < 32768) && (ntc_rg344_e - ntc_rg344 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg344:
var_hyp_svns:			dw 0
ntc_rg344_e:
			IF ($ < 32768) && (ntc_rg345_e - ntc_rg345 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg345:
var_hyp_svfr:			dw 0
ntc_rg345_e:
			IF ($ < 32768) && (ntc_rg346_e - ntc_rg346 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg346:
var_hyp_svdp:			dw 0
ntc_rg346_e:
			IF ($ < 32768) && (ntc_rg347_e - ntc_rg347 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg347:
p_hyp_svc_rs:			dw 0
ntc_rg347_e:
			IF ($ < 32768) && (ntc_rg348_e - ntc_rg348 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg348:
var_hyp_svc_t:			dw 0
ntc_rg348_e:
			IF ($ < 32768) && (ntc_rg349_e - ntc_rg349 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg349:
var_hyp_svc_p:			dw 0
ntc_rg349_e:
			IF ($ < 32768) && (ntc_rg350_e - ntc_rg350 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg350:
var_hyp_svc_setting:			dw 0
ntc_rg350_e:
			IF ($ < 32768) && (ntc_rg351_e - ntc_rg351 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg351:
var_hyp_svc_buf:			dw 0
ntc_rg351_e:
			IF ($ < 32768) && (ntc_rg352_e - ntc_rg352 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg352:
var_hyp_pox:			dw 0
ntc_rg352_e:
			IF ($ < 32768) && (ntc_rg353_e - ntc_rg353 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg353:
var_hyp_poy:			dw 0
ntc_rg353_e:
			IF ($ < 32768) && (ntc_rg354_e - ntc_rg354 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg354:
p_hyp_drive_rs:			dw 0
ntc_rg354_e:
			IF ($ < 32768) && (ntc_rg355_e - ntc_rg355 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg355:
var_hyp_drive_letter:			dw 0
ntc_rg355_e:
			IF ($ < 32768) && (ntc_rg356_e - ntc_rg356 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg356:
p_hot_speed_rs:			dw 0
ntc_rg356_e:
			IF ($ < 32768) && (ntc_rg357_e - ntc_rg357 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg357:
var_hot_speed_f:			dw 0
ntc_rg357_e:
			IF ($ < 32768) && (ntc_rg358_e - ntc_rg358 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg358:
var_hot_dbl:			dw 0
ntc_rg358_e:
			IF ($ < 32768) && (ntc_rg359_e - ntc_rg359 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg359:
p_hot_slots_rs:			dw 0
ntc_rg359_e:
			IF ($ < 32768) && (ntc_rg360_e - ntc_rg360 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg360:
var_hot_slots_n:			dw 0
ntc_rg360_e:
			IF ($ < 32768) && (ntc_rg361_e - ntc_rg361 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg361:
var_hot_ns:			dw 0
ntc_rg361_e:
			IF ($ < 32768) && (ntc_rg362_e - ntc_rg362 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg362:
p_hot_tick_rs:			dw 0
ntc_rg362_e:
			IF ($ < 32768) && (ntc_rg363_e - ntc_rg363 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg363:
var_hot_tick_k:			dw 0
ntc_rg363_e:
			IF ($ < 32768) && (ntc_rg364_e - ntc_rg364 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg364:
var_hot_ctl:			dw 0
ntc_rg364_e:
			IF ($ < 32768) && (ntc_rg365_e - ntc_rg365 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg365:
var_hot_last:			dw 0
ntc_rg365_e:
			IF ($ < 32768) && (ntc_rg366_e - ntc_rg366 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg366:
var_hot_one:			dw 0
ntc_rg366_e:
			IF ($ < 32768) && (ntc_rg367_e - ntc_rg367 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg367:
var_hot_pend:			dw 0
ntc_rg367_e:
			IF ($ < 32768) && (ntc_rg368_e - ntc_rg368 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg368:
var_hot_age:			dw 0
ntc_rg368_e:
			IF ($ < 32768) && (ntc_rg369_e - ntc_rg369 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg369:
p_hot_take_rs:			dw 0
ntc_rg369_e:
			IF ($ < 32768) && (ntc_rg370_e - ntc_rg370 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg370:
p_hot_control_rs:			dw 0
ntc_rg370_e:
			IF ($ < 32768) && (ntc_rg371_e - ntc_rg371 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg371:
p_hot_held_rs:			dw 0
ntc_rg371_e:
			IF ($ < 32768) && (ntc_rg372_e - ntc_rg372 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg372:
p_memory_bankpage_rs:			dw 0
ntc_rg372_e:
			IF ($ < 32768) && (ntc_rg373_e - ntc_rg373 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg373:
var_memory_bankpage_bank:			dw 0
ntc_rg373_e:
			IF ($ < 32768) && (ntc_rg374_e - ntc_rg374 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg374:
var_memory_bankpage_n:			dw 0
ntc_rg374_e:
			IF ($ < 32768) && (ntc_rg375_e - ntc_rg375 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg375:
tmp0:			dw 0
ntc_rg375_e:
			IF ($ < 32768) && (ntc_rg376_e - ntc_rg376 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg376:
tmp1:			dw 0
ntc_rg376_e:
			IF ($ < 32768) && (ntc_rg377_e - ntc_rg377 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg377:
tmp2:			dw 0
ntc_rg377_e:
			IF ($ < 32768) && (ntc_rg378_e - ntc_rg378 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg378:
tmp3:			dw 0
ntc_rg378_e:
			IF ($ < 32768) && (ntc_rg379_e - ntc_rg379 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg379:
tmp4:			dw 0
ntc_rg379_e:
			IF ($ < 32768) && (ntc_rg380_e - ntc_rg380 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg380:
tmp5:			dw 0
ntc_rg380_e:
			IF ($ < 32768) && (ntc_rg381_e - ntc_rg381 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg381:
tmp6:			dw 0
ntc_rg381_e:
			IF ($ < 32768) && (ntc_rg382_e - ntc_rg382 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg382:
tmp7:			dw 0
ntc_rg382_e:
			IF ($ < 32768) && (ntc_rg383_e - ntc_rg383 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg383:
			db 82			; capacity
stmp0:			ds 83
ntc_rg383_e:
			IF ($ < 32768) && (ntc_rg384_e - ntc_rg384 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg384:
			db 82			; capacity
stmp1:			ds 83
ntc_rg384_e:
			IF ($ < 32768) && (ntc_rg385_e - ntc_rg385 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg385:
			db 82			; capacity
stmp2:			ds 83
ntc_rg385_e:
			IF ($ < 32768) && (ntc_rg386_e - ntc_rg386 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg386:
			db 82			; capacity
stmp3:			ds 83
ntc_rg386_e:
			IF ($ < 32768) && (ntc_rg387_e - ntc_rg387 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg387:
ltmp0:			dw 0, 0
ntc_rg387_e:
			IF ($ < 32768) && (ntc_rg388_e - ntc_rg388 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg388:
ltmp1:			dw 0, 0
ntc_rg388_e:
			IF ($ < 32768) && (ntc_rg389_e - ntc_rg389 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg389:
ltmp2:			dw 0, 0

; numbers passed by address (read only)
ntc_rg389_e:
			IF ($ < 32768) && (ntc_rg390_e - ntc_rg390 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg390:
lit_0:			dw 0
ntc_rg390_e:
			IF ($ < 32768) && (ntc_rg391_e - ntc_rg391 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg391:
lit_1:			dw 1
ntc_rg391_e:
			IF ($ < 32768) && (ntc_rg392_e - ntc_rg392 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg392:
lit_85:			dw 85
ntc_rg392_e:
			IF ($ < 32768) && (ntc_rg393_e - ntc_rg393 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg393:
vp_arr_st:			dw arr_st
ntc_rg393_e:
			IF ($ < 32768) && (ntc_rg394_e - ntc_rg394 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg394:
vp_arr_sg:			dw arr_sg
ntc_rg394_e:
			IF ($ < 32768) && (ntc_rg395_e - ntc_rg395 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg395:
vp_var_ns:			dw var_ns
ntc_rg395_e:
			IF ($ < 32768) && (ntc_rg396_e - ntc_rg396 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg396:
vp_var_front:			dw var_front
ntc_rg396_e:
			IF ($ < 32768) && (ntc_rg397_e - ntc_rg397 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg397:
vp_var_dp:			dw var_dp
ntc_rg397_e:
			IF ($ < 32768) && (ntc_rg398_e - ntc_rg398 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg398:
vp_arr_rb:			dw arr_rb
ntc_rg398_e:
			IF ($ < 32768) && (ntc_rg399_e - ntc_rg399 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg399:
lit_99:			dw 99
ntc_rg399_e:
			IF ($ < 32768) && (ntc_rg400_e - ntc_rg400 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg400:
lit_82:			dw 82
ntc_rg400_e:
			IF ($ < 32768) && (ntc_rg401_e - ntc_rg401 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg401:
lit_255:			dw 255
ntc_rg401_e:
			IF ($ < 32768) && (ntc_rg402_e - ntc_rg402 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg402:
lit_m3:			dw -3
ntc_rg402_e:
			IF ($ < 32768) && (ntc_rg403_e - ntc_rg403 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg403:
lit_2:			dw 2
ntc_rg403_e:
			IF ($ < 32768) && (ntc_rg404_e - ntc_rg404 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg404:
lit_m2431:			dw -2431
ntc_rg404_e:
			IF ($ < 32768) && (ntc_rg405_e - ntc_rg405 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg405:
lit_110:			dw 110
ntc_rg405_e:
			IF ($ < 32768) && (ntc_rg406_e - ntc_rg406 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg406:
lit_116:			dw 116
ntc_rg406_e:
			IF ($ < 32768) && (ntc_rg407_e - ntc_rg407 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg407:
lit_m2423:			dw -2423
ntc_rg407_e:
			IF ($ < 32768) && (ntc_rg408_e - ntc_rg408 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg408:
lit_32:			dw 32
ntc_rg408_e:
			IF ($ < 32768) && (ntc_rg409_e - ntc_rg409 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg409:
vp_var_en:			dw var_en
ntc_rg409_e:
			IF ($ < 32768) && (ntc_rg410_e - ntc_rg410 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg410:
vp_var_dn:			dw var_dn
ntc_rg410_e:
			IF ($ < 32768) && (ntc_rg411_e - ntc_rg411 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg411:
lit_100:			dw 100
ntc_rg411_e:
			IF ($ < 32768) && (ntc_rg412_e - ntc_rg412 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg412:
lit_101:			dw 101
ntc_rg412_e:
			IF ($ < 32768) && (ntc_rg413_e - ntc_rg413 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg413:
lit_102:			dw 102
ntc_rg413_e:
			IF ($ < 32768) && (ntc_rg414_e - ntc_rg414 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg414:
vp_var_puts_s:			dw var_puts_s
ntc_rg414_e:
			IF ($ < 32768) && (ntc_rg415_e - ntc_rg415 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg415:
vp_var_putc_c:			dw var_putc_c
ntc_rg415_e:
			IF ($ < 32768) && (ntc_rg416_e - ntc_rg416 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg416:
llit_65536:			dw 0, 1
ntc_rg416_e:
			IF ($ < 32768) && (ntc_rg417_e - ntc_rg417 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg417:
lit_m2425:			dw -2425
ntc_rg417_e:
			IF ($ < 32768) && (ntc_rg418_e - ntc_rg418 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg418:
lit_m2424:			dw -2424
ntc_rg418_e:
			IF ($ < 32768) && (ntc_rg419_e - ntc_rg419 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg419:
lit_4:			dw 4
ntc_rg419_e:
			IF ($ < 32768) && (ntc_rg420_e - ntc_rg420 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg420:
lit_m2422:			dw -2422
ntc_rg420_e:
			IF ($ < 32768) && (ntc_rg421_e - ntc_rg421 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg421:
lit_15:			dw 15
ntc_rg421_e:
			IF ($ < 32768) && (ntc_rg422_e - ntc_rg422 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg422:
lit_13:			dw 13
ntc_rg422_e:
			IF ($ < 32768) && (ntc_rg423_e - ntc_rg423 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg423:
vp_var_topadd_s:			dw var_topadd_s
ntc_rg423_e:
			IF ($ < 32768) && (ntc_rg424_e - ntc_rg424 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg424:
lit_9:			dw 9
ntc_rg424_e:
			IF ($ < 32768) && (ntc_rg425_e - ntc_rg425 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg425:
lit_3:			dw 3
ntc_rg425_e:
			IF ($ < 32768) && (ntc_rg426_e - ntc_rg426 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg426:
lit_m4352:			dw -4352
ntc_rg426_e:
			IF ($ < 32768) && (ntc_rg427_e - ntc_rg427 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg427:
lit_4096:			dw 4096
ntc_rg427_e:
			IF ($ < 32768) && (ntc_rg428_e - ntc_rg428 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg428:
lit_m3328:			dw -3328
ntc_rg428_e:
			IF ($ < 32768) && (ntc_rg429_e - ntc_rg429 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg429:
lit_768:			dw 768
ntc_rg429_e:
			IF ($ < 32768) && (ntc_rg430_e - ntc_rg430 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg430:
lit_5:			dw 5
ntc_rg430_e:
			IF ($ < 32768) && (ntc_rg431_e - ntc_rg431 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg431:
lit_6:			dw 6
ntc_rg431_e:
			IF ($ < 32768) && (ntc_rg432_e - ntc_rg432 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg432:
lit_m48:			dw -48
ntc_rg432_e:
			IF ($ < 32768) && (ntc_rg433_e - ntc_rg433 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg433:
lit_m2432:			dw -2432
ntc_rg433_e:
			IF ($ < 32768) && (ntc_rg434_e - ntc_rg434 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg434:
lit_m2344:			dw -2344
ntc_rg434_e:
			IF ($ < 32768) && (ntc_rg435_e - ntc_rg435 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg435:
lit_12:			dw 12
ntc_rg435_e:
			IF ($ < 32768) && (ntc_rg436_e - ntc_rg436 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg436:
lit_m2343:			dw -2343
ntc_rg436_e:
			IF ($ < 32768) && (ntc_rg437_e - ntc_rg437 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg437:
lit_m2417:			dw -2417
ntc_rg437_e:
			IF ($ < 32768) && (ntc_rg438_e - ntc_rg438 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg438:
lit_8:			dw 8
ntc_rg438_e:
			IF ($ < 32768) && (ntc_rg439_e - ntc_rg439 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg439:
lit_m2416:			dw -2416
ntc_rg439_e:
			IF ($ < 32768) && (ntc_rg440_e - ntc_rg440 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg440:
vp_var_ob:			dw var_ob
ntc_rg440_e:
			IF ($ < 32768) && (ntc_rg441_e - ntc_rg441 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg441:
lit_90:			dw 90
ntc_rg441_e:
			IF ($ < 32768) && (ntc_rg442_e - ntc_rg442 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg442:
lit_103:			dw 103
ntc_rg442_e:
			IF ($ < 32768) && (ntc_rg443_e - ntc_rg443 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg443:
lit_256:			dw 256
ntc_rg443_e:
			IF ($ < 32768) && (ntc_rg444_e - ntc_rg444 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg444:
lit_m3332:			dw -3332
ntc_rg444_e:
			IF ($ < 32768) && (ntc_rg445_e - ntc_rg445 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg445:
lit_m3330:			dw -3330
ntc_rg445_e:
			IF ($ < 32768) && (ntc_rg446_e - ntc_rg446 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg446:
lit_m2:			dw -2
ntc_rg446_e:
			IF ($ < 32768) && (ntc_rg447_e - ntc_rg447 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg447:
lit_128:			dw 128
ntc_rg447_e:
			IF ($ < 32768) && (ntc_rg448_e - ntc_rg448 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg448:
vp_var_b:			dw var_b
ntc_rg448_e:
			IF ($ < 32768) && (ntc_rg449_e - ntc_rg449 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg449:
lit_129:			dw 129
ntc_rg449_e:
			IF ($ < 32768) && (ntc_rg450_e - ntc_rg450 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg450:
vp_var_a:			dw var_a
ntc_rg450_e:
			IF ($ < 32768) && (ntc_rg451_e - ntc_rg451 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg451:
lit_m2427:			dw -2427
ntc_rg451_e:
			IF ($ < 32768) && (ntc_rg452_e - ntc_rg452 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg452:
lit_m1:			dw -1

ntc_rg452_e:
			IF ($ < 32768) && (ntc_rg453_e - ntc_rg453 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg453:
; ============================================================
; ZOSCII glyphs - each points at its 8 byte bitmap in ntc_font
; ============================================================


ntc_rg453_e:
			IF ($ < 32768) && (ntc_rg454_e - ntc_rg454 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg454:
; ============================================================
; Strings
; ============================================================

ntc_rg454_e:
			IF ($ < 32768) && (ntc_rg455_e - ntc_rg455 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg455:
str0:			db 0
ntc_rg455_e:
			IF ($ < 32768) && (ntc_rg456_e - ntc_rg456 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg456:
str1:			db " KEYREP ", 0
ntc_rg456_e:
			IF ($ < 32768) && (ntc_rg457_e - ntc_rg457 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg457:
str2:			db 13, 0
ntc_rg457_e:
			IF ($ < 32768) && (ntc_rg458_e - ntc_rg458 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg458:
str3:			db 10, 0
ntc_rg458_e:
			IF ($ < 32768) && (ntc_rg459_e - ntc_rg459 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg459:
str4:			db 27, 0
ntc_rg459_e:
			IF ($ < 32768) && (ntc_rg460_e - ntc_rg460 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg460:
str5:			db "E", 0
ntc_rg460_e:
			IF ($ < 32768) && (ntc_rg461_e - ntc_rg461 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg461:
str6:			db "[", 0
ntc_rg461_e:
			IF ($ < 32768) && (ntc_rg462_e - ntc_rg462 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg462:
str7:			db "]   ", 0
ntc_rg462_e:
			IF ($ < 32768) && (ntc_rg463_e - ntc_rg463 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg463:
str8:			db "CyborgOS TOP", 0
ntc_rg463_e:
			IF ($ < 32768) && (ntc_rg464_e - ntc_rg464 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg464:
str9:			db "Control + ESC: back, ", 0
ntc_rg464_e:
			IF ($ < 32768) && (ntc_rg465_e - ntc_rg465 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg465:
str10:			db ": that slot", 0
ntc_rg465_e:
			IF ($ < 32768) && (ntc_rg466_e - ntc_rg466 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg466:
str11:			db "SLOT  STATE          PROGRAM         TURNS/S   BDOS/S  CHARS/S   (last second)", 0
ntc_rg466_e:
			IF ($ < 32768) && (ntc_rg467_e - ntc_rg467 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg467:
str12:			db "-", 0
ntc_rg467_e:
			IF ($ < 32768) && (ntc_rg468_e - ntc_rg468 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg468:
str13:			db "command line", 0
ntc_rg468_e:
			IF ($ < 32768) && (ntc_rg469_e - ntc_rg469 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg469:
str14:			db "waiting (key)", 0
ntc_rg469_e:
			IF ($ < 32768) && (ntc_rg470_e - ntc_rg470 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg470:
str15:			db "running", 0
ntc_rg470_e:
			IF ($ < 32768) && (ntc_rg471_e - ntc_rg471 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg471:
str16:			db " ", 0
ntc_rg471_e:
			IF ($ < 32768) && (ntc_rg472_e - ntc_rg472 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg472:
str17:			db "*", 0
ntc_rg472_e:
			IF ($ < 32768) && (ntc_rg473_e - ntc_rg473 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg473:
str18:			db "  ", 0
ntc_rg473_e:
			IF ($ < 32768) && (ntc_rg474_e - ntc_rg474 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg474:
str19:			db "Total memory: ", 0
ntc_rg474_e:
			IF ($ < 32768) && (ntc_rg475_e - ntc_rg475 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg475:
str20:			db " KB   Free memory: ", 0
ntc_rg475_e:
			IF ($ < 32768) && (ntc_rg476_e - ntc_rg476 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg476:
str21:			db " KB", 0
ntc_rg476_e:
			IF ($ < 32768) && (ntc_rg477_e - ntc_rg477 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg477:
str22:			db "CyborgOS slot ", 0
ntc_rg477_e:
			IF ($ < 32768) && (ntc_rg478_e - ntc_rg478 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg478:
str23:			db " of ", 0
ntc_rg478_e:
			IF ($ < 32768) && (ntc_rg479_e - ntc_rg479 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg479:
str24:			db " - ", 0
ntc_rg479_e:
			IF ($ < 32768) && (ntc_rg480_e - ntc_rg480 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg480:
str25:			db ", Control + ESC TOP, HELP", 0
ntc_rg480_e:
			IF ($ < 32768) && (ntc_rg481_e - ntc_rg481 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg481:
str26:			db "Control + 1-", 0
ntc_rg481_e:
			IF ($ < 32768) && (ntc_rg482_e - ntc_rg482 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg482:
str27:			db "Control + 1-9, 0", 0
ntc_rg482_e:
			IF ($ < 32768) && (ntc_rg483_e - ntc_rg483 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg483:
str28:			db "Control + 1-9, 0 (twice 11)", 0
ntc_rg483_e:
			IF ($ < 32768) && (ntc_rg484_e - ntc_rg484 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg484:
str29:			db "Control + 1-9, 0 (twice 11-", 0
ntc_rg484_e:
			IF ($ < 32768) && (ntc_rg485_e - ntc_rg485 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg485:
str30:			db ")", 0
ntc_rg485_e:
			IF ($ < 32768) && (ntc_rg486_e - ntc_rg486 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg486:
str31:			db "> ", 0
ntc_rg486_e:
			IF ($ < 32768) && (ntc_rg487_e - ntc_rg487 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg487:
str32:			db ":", 0
ntc_rg487_e:
			IF ($ < 32768) && (ntc_rg488_e - ntc_rg488 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg488:
str33:			db "CV", 0
ntc_rg488_e:
			IF ($ < 32768) && (ntc_rg489_e - ntc_rg489 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg489:
str34:			db "CLS", 0
ntc_rg489_e:
			IF ($ < 32768) && (ntc_rg490_e - ntc_rg490 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg490:
str35:			db "RUN", 0
ntc_rg490_e:
			IF ($ < 32768) && (ntc_rg491_e - ntc_rg491 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg491:
str36:			db "no slot", 0
ntc_rg491_e:
			IF ($ < 32768) && (ntc_rg492_e - ntc_rg492 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg492:
str37:			db "slot", 0
ntc_rg492_e:
			IF ($ < 32768) && (ntc_rg493_e - ntc_rg493 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg493:
str38:			db " is busy", 0
ntc_rg493_e:
			IF ($ < 32768) && (ntc_rg494_e - ntc_rg494 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg494:
str39:			db "QUIT", 0
ntc_rg494_e:
			IF ($ < 32768) && (ntc_rg495_e - ntc_rg495 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg495:
str40:			db "RUN what?", 0
ntc_rg495_e:
			IF ($ < 32768) && (ntc_rg496_e - ntc_rg496 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg496:
str41:			db ".", 0
ntc_rg496_e:
			IF ($ < 32768) && (ntc_rg497_e - ntc_rg497 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg497:
str42:			db ".CYB", 0
ntc_rg497_e:
			IF ($ < 32768) && (ntc_rg498_e - ntc_rg498 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg498:
str43:			db ".COM", 0
ntc_rg498_e:
			IF ($ < 32768) && (ntc_rg499_e - ntc_rg499 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg499:
str44:			db "RUN ", 0
ntc_rg499_e:
			IF ($ < 32768) && (ntc_rg500_e - ntc_rg500 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg500:
str45:			db " runs in slot", 0
ntc_rg500_e:
			IF ($ < 32768) && (ntc_rg501_e - ntc_rg501 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg501:
str46:			db "? ", 0
ntc_rg501_e:
			IF ($ < 32768) && (ntc_rg502_e - ntc_rg502 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg502:
str47:			db " (HELP)", 0
ntc_rg502_e:
			IF ($ < 32768) && (ntc_rg503_e - ntc_rg503 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg503:
str48:			db ": not found", 0
ntc_rg503_e:
			IF ($ < 32768) && (ntc_rg504_e - ntc_rg504 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg504:
str49:			db " ended]", 0

ntc_rg504_e:
			IF ($ < 32768) && (ntc_rg505_e - ntc_rg505 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg505:
; ============================================================
; Keyword library (used)
; ============================================================

ntc_rg505_e:
			IF ($ < 32768) && (ntc_rg506_e - ntc_rg506 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg506:
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

ntc_rg506_e:
			IF ($ < 32768) && (ntc_rg507_e - ntc_rg507 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg507:
;## ntc_d_ticks @data
ntc_ticks:		dw 0			; interrupt count (normal mode, platform handler)

ntc_rg507_e:
			IF ($ < 32768) && (ntc_rg508_e - ntc_rg508 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg508:
;## ntc_d_gnlo @data
ntc_gnlo:		db 0			; ntc_getn: low byte

ntc_rg508_e:
			IF ($ < 32768) && (ntc_rg509_e - ntc_rg509 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg509:
;## ntc_d_nmode @data
ntc_nmode:		db 0			; 1 = running in normal mode (waits let interrupts in)

ntc_rg509_e:
			IF ($ < 32768) && (ntc_rg510_e - ntc_rg510 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg510:
;## ntc_d_div @data
ntc_mode:		db 0			; div mode 0=quotient 1=remainder
ntc_sgnq:		db 0			; quotient sign (bit 7)
ntc_sgnr:		db 0			; remainder sign (bit 7)

ntc_rg510_e:
			IF ($ < 32768) && (ntc_rg511_e - ntc_rg511 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg511:
;## ntc_d_lead @data
ntc_lead:		db 0			; printint: digit seen

ntc_rg511_e:
			IF ($ < 32768) && (ntc_rg512_e - ntc_rg512 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg512:
;## ntc_d_sptr @data
ntc_sptr:		dw 0			; printbuf: text pointer

ntc_rg512_e:
			IF ($ < 32768) && (ntc_rg513_e - ntc_rg513 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg513:
;## ntc_d_iptr @data
ntc_iptr:		dw 0			; gets: buffer pointer
ntc_ilink:		dw 0			; gets: where to go when done

ntc_rg513_e:
			IF ($ < 32768) && (ntc_rg514_e - ntc_rg514 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg514:
;## ntc_d_ivar @data
ntc_ivar:		dw 0			; inputint / inkey: dest var

ntc_rg514_e:
			IF ($ < 32768) && (ntc_rg515_e - ntc_rg515 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg515:
;## ntc_d_aptr @data
ntc_aptr:		dw 0			; atoi: text pointer

ntc_rg515_e:
			IF ($ < 32768) && (ntc_rg516_e - ntc_rg516 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg516:
;## ntc_d_hook @data
ntc_hookon:		db 0			; 1 = the Interrupt hook may run (set, and not running now)
ntc_hookset:	db 0			; 1 = an Interrupt hook is set
ntc_hookpend:	db 0			; 1 = an interrupt came, the hook runs at the next safe point
ntc_hook:		dw 0			; the hook Sub's call stub

ntc_rg516_e:
			IF ($ < 32768) && (ntc_rg517_e - ntc_rg517 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg517:
;## ntc_d_rampt @data
ntc_rampt:		dw #7FC0		; the gate array's RAM setting now (B = port, C = value): the
								; Memory class keeps it, Graphics puts it back after drawing

ntc_rg517_e:
			IF ($ < 32768) && (ntc_rg518_e - ntc_rg518 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg518:
;## ntc_d_numbuf @data
ntc_numbuf:		ds 14			; printint / long print: digits (+ spaces for Option VBPrint)

ntc_rg518_e:
			IF ($ < 32768) && (ntc_rg519_e - ntc_rg519 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg519:
;## ntc_d_inbuf @data
				db 40			; ntc_inbuf's capacity (as every string variable has)
ntc_inbuf:		ds 41			; inputint: typed text

ntc_rg519_e:
			IF ($ < 32768) && (ntc_rg520_e - ntc_rg520 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg520:
;## kw_stop ntc_data ntc_plat_exit @shared
kw_stop:
			ld ix, ntc_stop_back
			jp ntc_plat_exit
ntc_stop_back:
			ld sp, (ntc_csp)
			ei
			ret

ntc_rg520_e:
			IF ($ < 32768) && (ntc_rg521_e - ntc_rg521 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg521:
;## kw_waitkey ntc_data ntc_plat_key
; kw_waitkey - wait for a key (Option PressAnyKeyOnEnd, before kw_stop)
kw_waitkey:
			ld ix, ntc_next
			jp ntc_plat_getkey

ntc_rg521_e:
			IF ($ < 32768) && (ntc_rg522_e - ntc_rg522 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg522:
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

ntc_rg522_e:
			IF ($ < 32768) && (ntc_rg523_e - ntc_rg523 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg523:
;## kw_goto_iffalse (normal mode copy)
;kw_goto_iffalse, <label>  - branch if NZ (false)
kw_goto_iffalse_n:
			pop hl
			jp z, ntc_xn
			ld sp, hl
			jp ntc_xn

ntc_rg523_e:
			IF ($ < 32768) && (ntc_rg524_e - ntc_rg524 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg524:
;## kw_goto_iftrue (normal mode copy)
;kw_goto_iftrue, <label>  - branch if Z (true)
kw_goto_iftrue_n:
			pop hl
			jp nz, ntc_xn
			ld sp, hl
			jp ntc_xn

ntc_rg524_e:
			IF ($ < 32768) && (ntc_rg525_e - ntc_rg525 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg525:
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

ntc_rg525_e:
			IF ($ < 32768) && (ntc_rg526_e - ntc_rg526 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg526:
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

ntc_rg526_e:
			IF ($ < 32768) && (ntc_rg527_e - ntc_rg527 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg527:
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

ntc_rg527_e:
			IF ($ < 32768) && (ntc_rg528_e - ntc_rg528 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg528:
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

ntc_rg528_e:
			IF ($ < 32768) && (ntc_rg529_e - ntc_rg529 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg529:
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

ntc_rg529_e:
			IF ($ < 32768) && (ntc_rg530_e - ntc_rg530 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg530:
;## kw_ltov
;kw_ltov, <literal>, <destvar>
kw_ltov:
			pop de
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg530_e:
			IF ($ < 32768) && (ntc_rg531_e - ntc_rg531 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg531:
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

ntc_rg531_e:
			IF ($ < 32768) && (ntc_rg532_e - ntc_rg532 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg532:
;## kw_ztov
;kw_ztov, <destvar>
kw_ztov:
			xor a
			pop hl
			ld (hl), a
			inc hl
			ld (hl), a
			ret

ntc_rg532_e:
			IF ($ < 32768) && (ntc_rg533_e - ntc_rg533 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg533:
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

ntc_rg533_e:
			IF ($ < 32768) && (ntc_rg534_e - ntc_rg534 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg534:
;## kw_inc
;kw_inc, <var>
kw_inc:
			pop hl
			inc (hl)
			ret nz
			inc hl
			inc (hl)
			ret

ntc_rg534_e:
			IF ($ < 32768) && (ntc_rg535_e - ntc_rg535 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg535:
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

ntc_rg535_e:
			IF ($ < 32768) && (ntc_rg536_e - ntc_rg536 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg536:
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

ntc_rg536_e:
			IF ($ < 32768) && (ntc_rg537_e - ntc_rg537 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg537:
;## kw_subvv
;kw_subvv, <var1>, <var2>, <destvar>  - var1 - var2
kw_subvv:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			ex de, hl
			or a
			sbc hl, de
			ex de, hl
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

ntc_rg537_e:
			IF ($ < 32768) && (ntc_rg538_e - ntc_rg538 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg538:
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

ntc_rg538_e:
			IF ($ < 32768) && (ntc_rg539_e - ntc_rg539 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg539:
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

ntc_rg539_e:
			IF ($ < 32768) && (ntc_rg540_e - ntc_rg540 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg540:
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

ntc_rg540_e:
			IF ($ < 32768) && (ntc_rg541_e - ntc_rg541 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg541:
;## kw_mulvl ntc_mul
;kw_mulvl, <var>, <literal>, <destvar>
kw_mulvl:
			pop hl
			ld c, (hl)
			inc hl
			ld b, (hl)
			pop de
			jp ntc_mul

ntc_rg541_e:
			IF ($ < 32768) && (ntc_rg542_e - ntc_rg542 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg542:
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

ntc_rg542_e:
			IF ($ < 32768) && (ntc_rg543_e - ntc_rg543 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg543:
;## kw_divvv ntc_div
;kw_divvv, <var1>, <var2>, <destvar>  - var1 / var2
kw_divvv:
			xor a
			ld (ntc_mode), a
ntc_divvv:
			pop hl
			ld c, (hl)
			inc hl
			ld b, (hl)
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld h, b
			ld l, c
			jp ntc_div

ntc_rg543_e:
			IF ($ < 32768) && (ntc_rg544_e - ntc_rg544 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg544:
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

ntc_rg544_e:
			IF ($ < 32768) && (ntc_rg545_e - ntc_rg545 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg545:
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

ntc_rg545_e:
			IF ($ < 32768) && (ntc_rg546_e - ntc_rg546 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg546:
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

ntc_rg546_e:
			IF ($ < 32768) && (ntc_rg547_e - ntc_rg547 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg547:
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

ntc_rg547_e:
			IF ($ < 32768) && (ntc_rg548_e - ntc_rg548 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg548:
;## kw_notv
;kw_notv, <var>, <destvar>
kw_notv:
			pop hl
			ld a, (hl)
			cpl
			ld e, a
			inc hl
			ld a, (hl)
			cpl
			ld d, a
			pop hl
			ld (hl), e
			inc hl
			ld (hl), d
			ret

; ============================================================
; Compares - result in Z flag (Z = true)
; Tails take DE = a, HL = b and test a <rel> b.
; ============================================================

ntc_rg548_e:
			IF ($ < 32768) && (ntc_rg549_e - ntc_rg549 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg549:
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

ntc_rg549_e:
			IF ($ < 32768) && (ntc_rg550_e - ntc_rg550 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg550:
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

ntc_rg550_e:
			IF ($ < 32768) && (ntc_rg551_e - ntc_rg551 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg551:
;## kw_scpltvl ntc_cmp
;kw_scpltvl, <var>, <literal>
kw_scpltvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_slt

ntc_rg551_e:
			IF ($ < 32768) && (ntc_rg552_e - ntc_rg552 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg552:
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

ntc_rg552_e:
			IF ($ < 32768) && (ntc_rg553_e - ntc_rg553 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg553:
;## kw_scplevl ntc_cmp
kw_scplevl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sle

ntc_rg553_e:
			IF ($ < 32768) && (ntc_rg554_e - ntc_rg554 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg554:
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

ntc_rg554_e:
			IF ($ < 32768) && (ntc_rg555_e - ntc_rg555 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg555:
;## kw_scpgtvl ntc_cmp
kw_scpgtvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sgt

ntc_rg555_e:
			IF ($ < 32768) && (ntc_rg556_e - ntc_rg556 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg556:
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

ntc_rg556_e:
			IF ($ < 32768) && (ntc_rg557_e - ntc_rg557 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg557:
;## kw_scpgevl ntc_cmp
kw_scpgevl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_sge

ntc_rg557_e:
			IF ($ < 32768) && (ntc_rg558_e - ntc_rg558 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg558:
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

ntc_rg558_e:
			IF ($ < 32768) && (ntc_rg559_e - ntc_rg559 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg559:
;## kw_cpeqvl ntc_cmp
kw_cpeqvl:
			pop hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			pop hl
			jp ntc_cmp_eq

ntc_rg559_e:
			IF ($ < 32768) && (ntc_rg560_e - ntc_rg560 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg560:
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

ntc_rg560_e:
			IF ($ < 32768) && (ntc_rg561_e - ntc_rg561 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg561:
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

ntc_rg561_e:
			IF ($ < 32768) && (ntc_rg562_e - ntc_rg562 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg562:
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

ntc_rg562_e:
			IF ($ < 32768) && (ntc_rg563_e - ntc_rg563 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg563:
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

ntc_rg563_e:
			IF ($ < 32768) && (ntc_rg564_e - ntc_rg564 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg564:
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

ntc_rg564_e:
			IF ($ < 32768) && (ntc_rg565_e - ntc_rg565 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg565:
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

ntc_rg565_e:
			IF ($ < 32768) && (ntc_rg566_e - ntc_rg566 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg566:
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

ntc_rg566_e:
			IF ($ < 32768) && (ntc_rg567_e - ntc_rg567 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg567:
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

ntc_rg567_e:
			IF ($ < 32768) && (ntc_rg568_e - ntc_rg568 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg568:
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

ntc_rg568_e:
			IF ($ < 32768) && (ntc_rg569_e - ntc_rg569 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg569:
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

ntc_rg569_e:
			IF ($ < 32768) && (ntc_rg570_e - ntc_rg570 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg570:
;## kw_strcmpeq
;kw_strcmpeq, <addr1>, <addr2>  - Z if equal
kw_strcmpeq:
			pop de
			pop hl
ntc_streq_loop:
			ld a, (de)
			cp (hl)
			ret nz
			or a
			ret z
			inc hl
			inc de
			jr ntc_streq_loop

ntc_rg570_e:
			IF ($ < 32768) && (ntc_rg571_e - ntc_rg571 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg571:
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

ntc_rg571_e:
			IF ($ < 32768) && (ntc_rg572_e - ntc_rg572 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg572:
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

ntc_rg572_e:
			IF ($ < 32768) && (ntc_rg573_e - ntc_rg573 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg573:
;## kw_printzoscii ntc_data ntc_font ntc_plat_screen
;kw_printzoscii / dw glyph, glyph, ..., 0  - ZOSCII text inline in the thread
;  each word points at an 8 byte glyph bitmap. 1 = newline, 0 = end (only those two:
;  a program at #0040 can have glyphs below #0100)
kw_printzoscii:
			pop de
			ld a, d
			or a
			jr nz, ntc_pz_glyph
			ld a, e
			cp 2
			jr c, ntc_pz_ctl
ntc_pz_glyph:
			ld ix, kw_printzoscii
			jp ntc_plat_putglyph
ntc_pz_ctl:
			or a
			ret z
			ld ix, kw_printzoscii
			jp ntc_plat_newline

ntc_rg573_e:
			IF ($ < 32768) && (ntc_rg574_e - ntc_rg574 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg574:
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

ntc_rg574_e:
			IF ($ < 32768) && (ntc_rg575_e - ntc_rg575 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg575:
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

ntc_rg575_e:
			IF ($ < 32768) && (ntc_rg576_e - ntc_rg576 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg576:
;## kw_printnl0 ntc_data ntc_plat_screen
;kw_printnl0  - new line unless the cursor is at the start of a line
kw_printnl0:
			ld a, (ntc_curx)
			or a
			ret z
			ld ix, ntc_next
			jp ntc_plat_newline

ntc_rg576_e:
			IF ($ < 32768) && (ntc_rg577_e - ntc_rg577 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg577:
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

ntc_rg577_e:
			IF ($ < 32768) && (ntc_rg578_e - ntc_rg578 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg578:
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

ntc_rg578_e:
			IF ($ < 32768) && (ntc_rg579_e - ntc_rg579 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg579:
;## kw_scrinit ntc_data ntc_plat_screen
;kw_scrinit  - first word of any program that prints or reads keys:
;  mode 1, ROMs off, clear screen
kw_scrinit:
			ld a, 1
			ld ix, ntc_next
			jp ntc_plat_mode

ntc_rg579_e:
			IF ($ < 32768) && (ntc_rg580_e - ntc_rg580 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg580:
;## kw_model ntc_data ntc_plat_screen
;kw_model, <literal>  - 0, 1 or 2, clears the screen
kw_model:
			pop hl
			ld a, l
			ld ix, ntc_next
			jp ntc_plat_mode

ntc_rg580_e:
			IF ($ < 32768) && (ntc_rg581_e - ntc_rg581 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg581:
;## kw_frame ntc_data ntc_plat_frame
;kw_frame  - wait for the start of the next frame flyback
kw_frame:
			ld ix, ntc_next
			jp ntc_plat_frame

ntc_rg581_e:
			IF ($ < 32768) && (ntc_rg582_e - ntc_rg582 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg582:
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

ntc_rg582_e:
			IF ($ < 32768) && (ntc_rg583_e - ntc_rg583 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg583:
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

ntc_rg583_e:
			IF ($ < 32768) && (ntc_rg584_e - ntc_rg584 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg584:
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

ntc_rg584_e:
			IF ($ < 32768) && (ntc_rg585_e - ntc_rg585 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg585:
;## kw_strright ntc_getn kw_strleft
;kw_strright, <dest>, <src>, <nvar>  - Right$(src, n)
kw_strright:
			pop de
			pop hl
			pop bc
			ld ix, ntc_sr_n
			jp ntc_getn
ntc_sr_n:
			ld c, a
			ld (ntc_sptr), hl
			ld b, 0
ntc_sr_len:
			ld a, (hl)
			or a
			jr z, ntc_sr_got
			inc hl
			inc b
			jr ntc_sr_len
ntc_sr_got:
			ld a, b
			sub c
			jr nc, ntc_sr_skip
			xor a
ntc_sr_skip:
			ld hl, (ntc_sptr)
			ld c, a
			ld b, 0
			add hl, bc
			ld b, 255
			jp ntc_strncpy

ntc_rg585_e:
			IF ($ < 32768) && (ntc_rg586_e - ntc_rg586 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg586:
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

ntc_rg586_e:
			IF ($ < 32768) && (ntc_rg587_e - ntc_rg587 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg587:
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

ntc_rg587_e:
			IF ($ < 32768) && (ntc_rg588_e - ntc_rg588 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg588:
;## kw_strstr ntc_itoa
;kw_strstr, <dest>, <nvar>  - Str$(n): a space before 0 and positives
kw_strstr:
			pop de
			pop hl
			ld a, (hl)
			inc hl
			ld h, (hl)
			ld l, a
			bit 7, h
			jr nz, ntc_st_go
			ld a, ' '
			ld (de), a
			inc de
ntc_st_go:
			ld ix, ntc_next
			jp ntc_itoa

ntc_rg588_e:
			IF ($ < 32768) && (ntc_rg589_e - ntc_rg589 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg589:
;## kw_strspace ntc_getn
;kw_strspace, <dest>, <nvar>  - Space$(n)
kw_strspace:
			pop de
			pop bc
			ld ix, ntc_sp_n
			jp ntc_getn
ntc_sp_n:
			ld c, ' '
; A = count (NTC_STRMAX at most), C = char, DE = dest
ntc_strfill:
	IF NTC_STRMAX < 255
			cp NTC_STRMAX + 1
			jr c, ntc_sf_ok
			ld a, NTC_STRMAX
ntc_sf_ok:
	ENDIF
			ld b, a
			inc b
ntc_sf_loop:
			dec b
			jr z, ntc_sf_end
			ld a, c
			ld (de), a
			inc de
			jr ntc_sf_loop
ntc_sf_end:
			xor a
			ld (de), a
			ret

ntc_rg589_e:
			IF ($ < 32768) && (ntc_rg590_e - ntc_rg590 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg590:
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

ntc_rg590_e:
			IF ($ < 32768) && (ntc_rg591_e - ntc_rg591 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg591:
;## kw_strrtrim ntc_data
;kw_strrtrim, <dest>, <src>  - RTrim$
kw_strrtrim:
			pop de
			pop hl
			ld (ntc_sptr), de
ntc_rt_copy:
			ld a, (hl)
			ld (de), a
			or a
			jr z, ntc_rt_back
			inc hl
			inc de
			jr ntc_rt_copy
ntc_rt_back:
			ld hl, (ntc_sptr)
			ex de, hl
ntc_rt_loop:
			or a
			sbc hl, de
			add hl, de
			ret z
			dec hl
			ld a, (hl)
			cp ' '
			ret nz
			ld (hl), 0
			jr ntc_rt_loop

ntc_rg591_e:
			IF ($ < 32768) && (ntc_rg592_e - ntc_rg592 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg592:
;## kw_strtrim kw_strrtrim
;kw_strtrim, <dest>, <src>  - Trim$
kw_strtrim:
			pop de
			pop hl
ntc_tr_skip:
			ld a, (hl)
			cp ' '
			jr nz, ntc_tr_go
			inc hl
			jr ntc_tr_skip
ntc_tr_go:
			ld (ntc_sptr), de
			jp ntc_rt_copy

ntc_rg592_e:
			IF ($ < 32768) && (ntc_rg593_e - ntc_rg593 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg593:
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

ntc_rg593_e:
			IF ($ < 32768) && (ntc_rg594_e - ntc_rg594 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg594:
;## kw_strval ntc_atoi
;kw_strval, <src>, <destvar>  - Val(src): decimal or &H hex
kw_strval:
			pop hl
			pop de
			ld (ntc_ivar), de
			jp ntc_atoi_hl

ntc_rg594_e:
			IF ($ < 32768) && (ntc_rg595_e - ntc_rg595 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg595:
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

ntc_rg595_e:
			IF ($ < 32768) && (ntc_rg596_e - ntc_rg596 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg596:
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

ntc_rg596_e:
			IF ($ < 32768) && (ntc_rg597_e - ntc_rg597 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg597:
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

ntc_rg597_e:
			IF ($ < 32768) && (ntc_rg598_e - ntc_rg598 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg598:
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

ntc_rg598_e:
			IF ($ < 32768) && (ntc_rg599_e - ntc_rg599 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg599:
;## ntc_font
; 8x8 font buffer, chars 32-126, 8 bytes each, bit 7 = leftmost pixel.
; The platform fills it at start: the CPC copies its own font from the
; lower ROM (#3900), so text looks like the CPC's.
; glyph for char c = ntc_font + (c - 32) * 8
ntc_font:		ds 95 * 8

; ============================================================
; Platform class capabilities
; ============================================================

ntc_rg599_e:
			IF ($ < 32768) && (ntc_rg600_e - ntc_rg600 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg600:
;## ntc_buf2k
; ntc_buf - a buffer shared by the classes that need one: FileSystem's
; CAS IN / OUT OPEN buffer (CPC firmware: 2K) and Memory.Copy's page to page
; copy (that much at a time). NTC_BUFSIZE (Option Buffer): 2048 unless set
ntc_buf:		ds NTC_BUFSIZE

ntc_rg600_e:
			IF ($ < 32768) && (ntc_rg601_e - ntc_rg601 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg601:
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

ntc_rg601_e:
			IF ($ < 32768) && (ntc_rg602_e - ntc_rg602 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg602:
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

ntc_rg602_e:
			IF ($ < 32768) && (ntc_rg603_e - ntc_rg603 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg603:
;## ntc_mem ntc_memcore ntc_membank ntc_nxt_bank @shared @far
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
			jr z, mem_tb_ports
			ld d, h
			ld e, l
			inc de
			ldir
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

ntc_rg603_e:
			IF ($ < 32768) && (ntc_rg604_e - ntc_rg604 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg604:
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

ntc_rg604_e:
			IF ($ < 32768) && (ntc_rg605_e - ntc_rg605 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg605:
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

ntc_rg605_e:
			IF ($ < 32768) && (ntc_rg606_e - ntc_rg606 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg606:
;## ntc_gfx ntc_data ntc_plat_data @shared
; ------------------------------------------------------------
; ntc_gfx - the Graphics class on the Next (in place of the library's CPC one,
; with its labels): Layer 2 at 320 x 256, 256 colours, two buffers - banks
; 12-16 and 17-21 (5 x 16K each; column by column: a byte for each pixel at
; x * 256 + y). Lines XOR the pen (as on the CPC: drawing one again takes it
; off), in 320 x 200 (the CPC's mode 1), shown 28 rows down (centred in the
; 256). The page being drawn on goes in slot 6 (#C000-#DFFF). The text stays
; on the tilemap, over Layer 2, its paper see-through while Layer 2 is on.
; Called on the real stack (call / ret); uses IX, IY.
; ------------------------------------------------------------
ZXN_L2A			equ 12			; Layer 2's two buffers: their first 16K banks
ZXN_L2B			equ 17
ZXN_L2Y			equ 28			; the CPC's 200 rows, 28 rows down in Layer 2's 256
gfx_x0:			dw 0
gfx_y0:			dw 0
gfx_x1:			dw 0
gfx_y1:			dw 0
gfx_pen:		db 1
gfx_clip:		db 1			; 1: a line with an end off the screen isn't drawn; 0: no checks
gfx_base:		db ZXN_L2A		; the buffer drawn on (its first bank)
gfx_dbl:		db 0			; 1 = double buffering
gfx_shown:		db ZXN_L2A		; the buffer shown (NextReg #12)
gfx_sp:			dw 0			; the thread position while a Graphics method works
gfx_cpg:		db 0			; the page in slot 6
gfx_dx:			dw 0
gfx_dy:			dw 0

; gfx_begin / gfx_end - around drawing (the CPC: main RAM in the window): nothing here
gfx_begin:
gfx_end:
			ret

; gfx_width - HL = the width in pixels
gfx_width:
			ld hl, 320
			ret

; gfx_nr - NextReg A = E (through ntc_zxsel: interrupts may be in). Uses BC
gfx_nr:
			ld (ntc_zxsel), a
			ld bc, #243B
			out (c), a
			inc b
			out (c), e
			ret

; gfx_map - A = a page: into slot 6 (#C000-#DFFF). Keeps DE, HL, IX, IY
gfx_map:
			ld (gfx_cpg), a
			push de
			ld e, a
			ld a, #56
			call gfx_nr
			pop de
			ret

; gfx_on - Layer 2 on (once, after Mode): 320 x 256, buffer A shown and drawn on (cleared),
; its clip window the whole of it, the order sprites - ULA and tilemap - Layer 2, the ULA
; off, the tilemap's paper see-through
gfx_on:
			push hl
			push de
			ld hl, gfx_onregs
			ld d, 11
gfx_on1:
			ld a, (hl)
			inc hl
			ld e, (hl)
			inc hl
			call gfx_nr
			dec d
			jr nz, gfx_on1
			ld a, #18				; Layer 2's clip window: x 0-255 (in 320 x 256: doubled, 0-511),
			ld (ntc_zxsel), a		; y 0-255
			ld bc, #243B
			out (c), a
			inc b
			xor a
			out (c), a
			dec a
			out (c), a
			inc a
			out (c), a
			dec a
			out (c), a
			ld a, ZXN_L2A
			ld (gfx_base), a
			ld (gfx_shown), a
			call gfx_clear
			ld a, 1
			ld (ntc_zxl2), a
			pop de
			pop hl
			ret
gfx_onregs:		db #70, #10, #12, ZXN_L2A, #1C, 1, #15, 8, #68, #80, #4C, 0, #69, #80
			db #14, #E3, #43, #30, #40, 0, #41, #E3	; the tilemap's paper (index 0) the global transparent
								; colour: in text mode that is what makes it see-through, not #4C

; gfx_chk - HL >= DE (unsigned): carry (off the screen)
gfx_chk:
			or a
			sbc hl, de
			ccf
			ret

; gfx_line - (gfx_x0, gfx_y0) to (gfx_x1, gfx_y1), 320 x 200, XOR the pen
gfx_line:
			ld a, (ntc_zxl2)
			or a
			call z, gfx_on
			ld a, (gfx_clip)
			or a
			jr z, gfx_l_go
			ld de, 320
			ld hl, (gfx_x0)
			call gfx_chk
			ret c
			ld hl, (gfx_x1)
			call gfx_chk
			ret c
			ld de, 200
			ld hl, (gfx_y0)
			call gfx_chk
			ret c
			ld hl, (gfx_y1)
			call gfx_chk
			ret c
gfx_l_go:
			ld hl, (gfx_x1)			; left to right
			ld de, (gfx_x0)
			or a
			sbc hl, de
			jr nc, gfx_l_lr
			ld hl, (gfx_x0)
			ld de, (gfx_x1)
			ld (gfx_x0), de
			ld (gfx_x1), hl
			ld hl, (gfx_y0)
			ld de, (gfx_y1)
			ld (gfx_y0), de
			ld (gfx_y1), hl
			ld hl, (gfx_x1)
			ld de, (gfx_x0)
			or a
			sbc hl, de
gfx_l_lr:
			ld (gfx_dx), hl			; dx = x1 - x0 (0 - 319)
			ld a, #2C				; inc l: down
			ld hl, (gfx_y1)
			ld de, (gfx_y0)
			or a
			sbc hl, de
			jr nc, gfx_l_dy
			ex de, hl				; dy < 0: negated, up
			ld hl, 0
			or a
			sbc hl, de
			ld a, #2D				; dec l
gfx_l_dy:
			ld (gfx_dy), hl
			ld (gfx_xys), a			; the y step in both loops
			ld (gfx_yys), a
			ld a, (gfx_pen)
			ld (gfx_xpn + 1), a
			ld (gfx_ypn + 1), a
			ld hl, (gfx_x0)			; the first pixel's page: the buffer's + x / 32
			ld a, l
			and 31
			add a, #C0
			ld d, a					; D = #C0 + x mod 32 (the column in the page)
			srl h
			rr l
			srl h
			rr l
			srl h
			rr l
			srl h
			rr l
			srl h
			rr l
			ld a, (gfx_base)
			add a, a
			add a, l
			call gfx_map
			ld a, (gfx_y0)
			add a, ZXN_L2Y
			ld e, a
			ex de, hl				; HL = the pixel
			ld de, (gfx_dx)
			ld bc, (gfx_dy)
			ex de, hl
			or a
			sbc hl, bc				; dx - dy
			ex de, hl
			jr c, gfx_ymaj
			; x major: dx + 1 pixels; err = dx / 2, - dy each, + dx (and a y step) below 0
			ld a, (gfx_dy)
			ld (gfx_xdy + 1), a
			ld a, (gfx_dy + 1)
			ld (gfx_xdy2 + 1), a
			ld a, (gfx_dx)
			ld (gfx_xdx + 1), a
			ld a, (gfx_dx + 1)
			ld (gfx_xdx2 + 1), a
			ld bc, (gfx_dx)
			inc bc					; BC = the pixels
			ld de, (gfx_dx)
			srl d
			rr e					; DE = err
gfx_xl:
			ld a, (hl)
gfx_xpn:	xor 1
			ld (hl), a
			dec bc
			ld a, b
			or c
			ret z
			inc h					; x + 1
			ld a, h
			cp #E0
			call z, gfx_nxp
			ld a, e
gfx_xdy:	sub 0
			ld e, a
			ld a, d
gfx_xdy2:	sbc a, 0
			ld d, a
			jp p, gfx_xl
			ld a, e
gfx_xdx:	add a, 0
			ld e, a
			ld a, d
gfx_xdx2:	adc a, 0
			ld d, a
gfx_xys:	inc l					; (inc l / dec l)
			jr gfx_xl
gfx_ymaj:
			; y major: dy + 1 pixels; err = dy / 2, - dx each, + dy (and an x step) below 0
			ld a, (gfx_dx)
			ld (gfx_ydx + 1), a
			ld a, (gfx_dx + 1)
			ld (gfx_ydx2 + 1), a
			ld a, (gfx_dy)
			ld (gfx_ydy + 1), a
			ld a, (gfx_dy + 1)
			ld (gfx_ydy2 + 1), a
			ld bc, (gfx_dy)
			inc bc
			ld de, (gfx_dy)
			srl d
			rr e
gfx_yl:
			ld a, (hl)
gfx_ypn:	xor 1
			ld (hl), a
			dec bc
			ld a, b
			or c
			ret z
gfx_yys:	inc l					; (inc l / dec l)
			ld a, e
gfx_ydx:	sub 0
			ld e, a
			ld a, d
gfx_ydx2:	sbc a, 0
			ld d, a
			jp p, gfx_yl
			ld a, e
gfx_ydy:	add a, 0
			ld e, a
			ld a, d
gfx_ydy2:	adc a, 0
			ld d, a
			inc h					; x + 1
			ld a, h
			cp #E0
			call z, gfx_nxp
			jr gfx_yl
; past this page's 32 columns: the next page, column 0
gfx_nxp:
			ld h, #C0
			push bc
			ld a, (gfx_cpg)
			inc a
			call gfx_map
			pop bc
			ret

; gfx_clear (zxn_gclr: the name a program's #asm uses - IFDEF NTC_ZXN - so a CPC Library: ROM
; build, which sees every name, doesn't look for it) - the buffer drawn on cleared (its 10 pages,
; through slot 6). Interrupts kept out while SP runs through it (back on after when they were on)
zxn_gclr:
gfx_clear:
			ld a, i					; P/V = interrupts on
			push af
			di
			ld a, (gfx_base)
			add a, a
			ld d, 10
gfx_cl1:
			push af
			call gfx_map
			ld (gfx_dx), sp
			ld sp, #E000
			ld hl, 0
			ld b, 0					; 256 x 32 bytes = 8K
gfx_cl2:
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			push hl
			djnz gfx_cl2
			ld sp, (gfx_dx)
			pop af
			inc a
			dec d
			jr nz, gfx_cl1
			pop af
			ret po
			ei
			ret

; gfx_rline - HL = the raster line (#1E bit 8, #1F bits 0-7: read again until bit 8 holds)
gfx_rline:
			ld bc, #243B
			ld a, #1E
			ld (ntc_zxsel), a
			out (c), a
			inc b
			in h, (c)
			dec b
			ld a, #1F
			ld (ntc_zxsel), a
			out (c), a
			inc b
			in l, (c)
			dec b
			ld a, #1E
			ld (ntc_zxsel), a
			out (c), a
			inc b
			in a, (c)
			cp h
			jr nz, gfx_rline
			ld a, h
			and 1
			ld h, a
			ret

; gfx_flip - double buffering: wait for Layer 2's flyback (raster lines 224-279: below its
; 256 rows), show the buffer just drawn (NextReg #12), draw on the other one
gfx_flip:
			ld a, (gfx_dbl)
			or a
			ret z
gfx_fw:
			call gfx_rline
			ld de, 224
			or a
			sbc hl, de
			jr c, gfx_fw
			ld de, 280 - 224
			or a
			sbc hl, de
			jr nc, gfx_fw
			ld a, (gfx_base)
			ld (gfx_shown), a
			ld e, a
			ld a, #12
			call gfx_nr
			ld a, (gfx_shown)
			cp ZXN_L2A
			ld a, ZXN_L2B
			jr z, gfx_fl1
			ld a, ZXN_L2A
gfx_fl1:
			ld (gfx_base), a
			ret

; gfx_double - A = 1: double buffering on (the other buffer cleared, drawn on); 0: off -
; drawing on the buffer shown
gfx_double:
			ld (gfx_dbl), a
			ld a, (ntc_zxl2)
			or a
			call z, gfx_on
			ld a, (gfx_dbl)
			or a
			jr z, gfx_dboff
			ld a, (gfx_shown)
			cp ZXN_L2A
			ld a, ZXN_L2B
			jr z, gfx_db1
			ld a, ZXN_L2A
gfx_db1:
			ld (gfx_base), a
			jp gfx_clear
gfx_dboff:
			ld a, (gfx_shown)
			ld (gfx_base), a
			ret

; gfx_copyrows - the CPC copies its text rows to the other screen: here the text is on the
; tilemap, over both buffers - nothing to copy
gfx_copyrows:
			ret

ntc_rg606_e:
			IF ($ < 32768) && (ntc_rg607_e - ntc_rg607 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg607:
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
	IFDEF NTC_ZXN
			ld a, c					; zxn: the handler's frame flag in C (1: the line 0 interrupt)
	ELSE
			ld b, #F5				; PPI port B bit 0: vertical sync
			in a, (c)
	ENDIF
			and 1
			ld e, a
			ld a, (ntc_islvs)
			cpl
			and e
			ld d, a					; 1 = the sync started since the last interrupt
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

ntc_rg607_e:
			IF ($ < 32768) && (ntc_rg608_e - ntc_rg608 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg608:
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

ntc_rg608_e:
			IF ($ < 32768) && (ntc_rg609_e - ntc_rg609 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg609:
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

; nxt_mem_jbc - E = a 64K bank (0-63) -> BC = its first 16K Next bank (B = 0, the
; four 16K parts step C). Called from mem_jbc (jp, so its ret returns to mem_jbc's
; caller). Keeps DE, HL.
nxt_mem_jbc:
			ld a, e
			add a, a
			add a, a				; E * 4
			add a, ZXN_FIRSTBANK
			ld c, a					; C = the Next 16K bank
			ld b, 0
			ret

; nxt_mem_se_out - BC = the RAM setting (B = port, C = value): the Next 16K bank
; into the window (slots 2, 3). B = #7F (page 1 / plain RAM) = the program's own
; window bank 9. Reached by jp from mem_se_out; exits through mem_se_end.
; ntc_zxsel is kept so an interrupt handler can re-assert the window.
nxt_mem_se_out:
			ld (ntc_rampt), bc
			ld a, b
			cp #7F						; B = #7F: page 1 / plain RAM = the program's own window bank 9
			jr nz, nxt_se_zc
			ld c, 9
nxt_se_zc:
			ld a, c
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

ntc_rg609_e:
			IF ($ < 32768) && (ntc_rg610_e - ntc_rg610 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg610:
;## ntc_plat_data
ntc_curx:		db 0			; cursor column (0 based)
ntc_cury:		db 0			; cursor row (0 based)
ntc_smode:		db 1			; screen mode (0, 1: 40 columns, 2: 80)
ntc_sinit:		db 0			; 1 once the tilemap is set up
ntc_scols:		db 40			; columns
ntc_wrapped:	db 0			; 1 = the last character wrapped to the next line
ntc_klink:		dw 0			; return for ntc_plat_getkey
ntc_kidx:		db 0			; key index found by the scan
ntc_kcur:		ds 8			; the 8 half rows this scan (0 = pressed)
ntc_kprev:		db #FF, #FF, #FF, #FF, #FF, #FF, #FF, #FF
ntc_irqset:		db 0			; 1 = our interrupt handler is at #38
ntc_irqold:		ds 3			; the 3 bytes it replaced
ntc_irqhl:		dw 0			; handler scratch
ntc_irqv:		dw 0			; interrupt classes' counting (ntc_isl_tick), 0 = none
ntc_zxvs:		db 0			; 1: this interrupt is a frame's first (line 0: to ntc_isl_tick in C)
ntc_zxline:		dw 0			; the raster line the line interrupt is set to
ntc_zxsel:		db 0			; the NextReg selected (#243B) by code interrupts can get into: the
								; handler selects it again after its own (store it, then select)
ntc_zxl2:		db 0			; 1 = Layer 2 is on (Graphics); Mode turns it off
ZXN_MAP			equ #E000		; the tilemap (bank 5 + #2000: NextReg #6E = #20)
ZXN_TILES		equ #EC00		; its characters (bank 5 + #2C00: NextReg #6F = #2C)
ZXN_ROWS		equ 32
ZXN_PAPER		equ #02			; RRRGGGBB: blue
ZXN_INK			equ #FC			; yellow

ntc_rg610_e:
			IF ($ < 32768) && (ntc_rg611_e - ntc_rg611 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg611:
;## ntc_plat_screen ntc_plat_data ntc_font ntc_data ntc_plat_scroll @shared
; ------------------------------------------------------------
; ntc_plat_putc - A = character 32-126 (others print as ?), draw it
; ------------------------------------------------------------
ntc_plat_putc:
			cp 32
			jr c, ntc_pc_bad
			cp 127
			jr c, ntc_zx_put
ntc_pc_bad:
			ld a, '?'
			jr ntc_zx_put

; ------------------------------------------------------------
; ntc_plat_putglyph - DE = an 8 byte glyph in ntc_font (ZOSCII text): that
; character at the cursor, the cursor on (a glyph not in ntc_font: ?)
; ------------------------------------------------------------
ntc_plat_putglyph:
			ld hl, -ntc_font
			add hl, de				; HL = the glyph's offset: 0 .. 95 * 8 - 1
			ld a, h
			cp (95 * 8) / 256
			jr c, ntc_pg_in
			jr nz, ntc_pc_bad
			ld a, l
			cp (95 * 8) & 255
			jr nc, ntc_pc_bad
ntc_pg_in:
			srl h
			rr l
			srl h
			rr l
			srl h
			rr l
			ld a, l
			add a, 32
			; fall into ntc_zx_put

; A = a character code: into the tilemap at the cursor (its tile), the cursor on
ntc_zx_put:
			ld c, a
			ld a, (ntc_cury)		; HL = ZXN_MAP + row * columns + column
			ld l, a
			ld h, 0
			add hl, hl
			add hl, hl
			add hl, hl
			ld d, h
			ld e, l
			add hl, hl
			add hl, hl
			add hl, de				; row * 40
			ld a, (ntc_scols)
			cp 80
			jr nz, $+3
			add hl, hl				; row * 80
			ld a, (ntc_curx)
			ld e, a
			ld d, ZXN_MAP / 256		; (ZXN_MAP's low byte is 0)
			add hl, de
			ld (hl), c
			ld a, (ntc_scols)
			ld b, a
			ld a, (ntc_curx)
			inc a
			ld (ntc_curx), a
			cp b
			jr z, ntc_pg_wrap
			xor a
			ld (ntc_wrapped), a
			jp (ix)
ntc_pg_wrap:
			ld a, 1				; wrapped: a new line straight after does nothing
			ld (ntc_wrapped), a
			jr ntc_nl_do

; ------------------------------------------------------------
; ntc_plat_newline - column 0, next row, scroll at the bottom. Straight
; after a wrap at the last column it does nothing (as the firmware does)
; ------------------------------------------------------------
ntc_plat_newline:
			ld a, (ntc_wrapped)
			or a
			jr z, ntc_nl_do
			xor a
			ld (ntc_wrapped), a
			jp (ix)
ntc_nl_do:
			xor a
			ld (ntc_curx), a
			ld a, (ntc_cury)
			inc a
			cp ZXN_ROWS
			jp nc, ntc_plat_scroll
			ld (ntc_cury), a
			jp (ix)

ntc_rg611_e:
			IF ($ < 32768) && (ntc_rg612_e - ntc_rg612 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg612:
;## ntc_plat_mode @unit ntc_plat_screen ntc_plat_data ntc_font ntc_data ntc_plat_scroll @shared
; ------------------------------------------------------------
; ntc_plat_mode - A = mode: 0, 1 = 40 x 32, 2 (3) = 80 x 32. The first time the
; tilemap is set up (font, palette, its registers); then its width, clear screen
; ------------------------------------------------------------
ntc_plat_mode:
			cp 3
			jr c, ntc_md_ok
			ld a, 2
ntc_md_ok:
			ld (ntc_smode), a
			ld a, (ntc_sinit)
			or a
			jp nz, ntc_md_set
			inc a
			ld (ntc_sinit), a
			ld hl, ntc_zxfont		; the font to ntc_font (ZOSCII's glyphs point there)
			ld de, ntc_font
			ld bc, 95 * 8
			ldir
			ld hl, ZXN_TILES		; the tiles: 0-31 and 127-255 blank, 32-126 the font
			ld de, ZXN_TILES + 1
			ld bc, 256 * 8 - 1
			ld (hl), 0
			ldir
			ld hl, ntc_zxfont
			ld de, ZXN_TILES + 32 * 8
			ld bc, 95 * 8
			ldir
			ld bc, #243B
			ld a, #43
			out (c), a
			inc b
			ld a, #30
			out (c), a
			dec b					; palette: the tilemap's first, index 0 paper, 1 ink
			ld bc, #243B
			ld a, #40
			out (c), a
			inc b
			ld a, 0
			out (c), a
			dec b
			ld a, #41
			out (c), a
			inc b
			ld a, ZXN_PAPER
			out (c), a
			ld a, ZXN_INK
			out (c), a				; (the index moves on by itself)
			ld bc, #243B
			ld a, #6C
			out (c), a
			inc b
			ld a, 0
			out (c), a
			dec b					; every tile's attribute: palette offset 0
			ld bc, #243B
			ld a, #6E
			out (c), a
			inc b
			ld a, #20
			out (c), a
			dec b					; the map at bank 5 + #2000
			ld bc, #243B
			ld a, #6F
			out (c), a
			inc b
			ld a, #2C
			out (c), a
			dec b					; the tiles at bank 5 + #2C00
			ld bc, #243B
			ld bc, #243B
			ld a, #2F
			out (c), a
			inc b
			ld a, 0
			out (c), a
			dec b					; no scroll
			ld bc, #243B
			ld a, #30
			out (c), a
			inc b
			ld a, 0
			out (c), a
			dec b
			ld bc, #243B
			ld a, #31
			out (c), a
			inc b
			ld a, 0
			out (c), a
			dec b
			ld bc, #243B
			ld a, #1C
			out (c), a
			inc b
			ld a, 8
			out (c), a
			dec b					; the tilemap's clip window: the whole of it
			ld a, #1B
			out (c), a
			inc b
			xor a
			out (c), a
			ld a, 159
			out (c), a
			xor a
			out (c), a
			dec a
			out (c), a
ntc_md_set:
			ld hl, ntc_md_regs		; the text screen alone: Layer 2 off (Graphics turns it on), the
			ld bc, #243B			; ULA on, the tilemap opaque, bank 5's first page at #C000
			ld e, 9
ntc_md_rg:
			ld a, (hl)
			inc hl
			out (c), a
			inc b
			ld a, (hl)
			inc hl
			out (c), a
			dec b
			dec e
			jr nz, ntc_md_rg
			xor a
			ld (ntc_zxl2), a
			ld a, (ntc_smode)
			cp 2
			ld a, 40
			ld e, #A9				; tilemap on, 40 x 32, no attributes, text mode, over the ULA
			jr nz, ntc_md_40
			ld a, 80
			ld e, #E9				; the same, 80 x 32
ntc_md_40:
			ld (ntc_scols), a
			ld bc, #243B
			ld a, #6B
			out (c), a
			inc b
			ld a, e
			out (c), a
			jp ntc_plat_cls

; NextReg, value: Layer 2 off, the ULA from bank 5, no Timex mode (#69); sprites off, the
; layers' order as at reset (#15); the ULA on, no ULA+ (#68); the tilemap's index 15
; transparent - its paper (0) not (#4C); page 10 at #C000 (#56: Graphics draws there); the
; tilemap's paper its colour again (Graphics makes it see-through)
ntc_md_regs:	db #69, 0, #15, 0, #68, 0, #4C, #0F, #56, 10, #57, 11, #43, #30, #40, 0, #41, ZXN_PAPER

; the font: font8x8_basic by Daniel Hepper (public domain) - chars 32-126, 8 bytes each,
; bit 7 the leftmost pixel
ntc_zxfont:
			db #00, #00, #00, #00, #00, #00, #00, #00	; 32
			db #18, #3C, #3C, #18, #18, #00, #18, #00	; 33 !
			db #6C, #6C, #00, #00, #00, #00, #00, #00	; 34 "
			db #6C, #6C, #FE, #6C, #FE, #6C, #6C, #00	; 35 #
			db #30, #7C, #C0, #78, #0C, #F8, #30, #00	; 36 $
			db #00, #C6, #CC, #18, #30, #66, #C6, #00	; 37 %
			db #38, #6C, #38, #76, #DC, #CC, #76, #00	; 38 &
			db #60, #60, #C0, #00, #00, #00, #00, #00	; 39 '
			db #18, #30, #60, #60, #60, #30, #18, #00	; 40 (
			db #60, #30, #18, #18, #18, #30, #60, #00	; 41 )
			db #00, #66, #3C, #FF, #3C, #66, #00, #00	; 42 *
			db #00, #30, #30, #FC, #30, #30, #00, #00	; 43 +
			db #00, #00, #00, #00, #00, #30, #30, #60	; 44 ,
			db #00, #00, #00, #FC, #00, #00, #00, #00	; 45 -
			db #00, #00, #00, #00, #00, #30, #30, #00	; 46 .
			db #06, #0C, #18, #30, #60, #C0, #80, #00	; 47 /
			db #7C, #C6, #CE, #DE, #F6, #E6, #7C, #00	; 48 0
			db #30, #70, #30, #30, #30, #30, #FC, #00	; 49 1
			db #78, #CC, #0C, #38, #60, #CC, #FC, #00	; 50 2
			db #78, #CC, #0C, #38, #0C, #CC, #78, #00	; 51 3
			db #1C, #3C, #6C, #CC, #FE, #0C, #1E, #00	; 52 4
			db #FC, #C0, #F8, #0C, #0C, #CC, #78, #00	; 53 5
			db #38, #60, #C0, #F8, #CC, #CC, #78, #00	; 54 6
			db #FC, #CC, #0C, #18, #30, #30, #30, #00	; 55 7
			db #78, #CC, #CC, #78, #CC, #CC, #78, #00	; 56 8
			db #78, #CC, #CC, #7C, #0C, #18, #70, #00	; 57 9
			db #00, #30, #30, #00, #00, #30, #30, #00	; 58 :
			db #00, #30, #30, #00, #00, #30, #30, #60	; 59 ;
			db #18, #30, #60, #C0, #60, #30, #18, #00	; 60 <
			db #00, #00, #FC, #00, #00, #FC, #00, #00	; 61 =
			db #60, #30, #18, #0C, #18, #30, #60, #00	; 62 >
			db #78, #CC, #0C, #18, #30, #00, #30, #00	; 63 ?
			db #7C, #C6, #DE, #DE, #DE, #C0, #78, #00	; 64 @
			db #30, #78, #CC, #CC, #FC, #CC, #CC, #00	; 65 A
			db #FC, #66, #66, #7C, #66, #66, #FC, #00	; 66 B
			db #3C, #66, #C0, #C0, #C0, #66, #3C, #00	; 67 C
			db #F8, #6C, #66, #66, #66, #6C, #F8, #00	; 68 D
			db #FE, #62, #68, #78, #68, #62, #FE, #00	; 69 E
			db #FE, #62, #68, #78, #68, #60, #F0, #00	; 70 F
			db #3C, #66, #C0, #C0, #CE, #66, #3E, #00	; 71 G
			db #CC, #CC, #CC, #FC, #CC, #CC, #CC, #00	; 72 H
			db #78, #30, #30, #30, #30, #30, #78, #00	; 73 I
			db #1E, #0C, #0C, #0C, #CC, #CC, #78, #00	; 74 J
			db #E6, #66, #6C, #78, #6C, #66, #E6, #00	; 75 K
			db #F0, #60, #60, #60, #62, #66, #FE, #00	; 76 L
			db #C6, #EE, #FE, #FE, #D6, #C6, #C6, #00	; 77 M
			db #C6, #E6, #F6, #DE, #CE, #C6, #C6, #00	; 78 N
			db #38, #6C, #C6, #C6, #C6, #6C, #38, #00	; 79 O
			db #FC, #66, #66, #7C, #60, #60, #F0, #00	; 80 P
			db #78, #CC, #CC, #CC, #DC, #78, #1C, #00	; 81 Q
			db #FC, #66, #66, #7C, #6C, #66, #E6, #00	; 82 R
			db #78, #CC, #E0, #70, #1C, #CC, #78, #00	; 83 S
			db #FC, #B4, #30, #30, #30, #30, #78, #00	; 84 T
			db #CC, #CC, #CC, #CC, #CC, #CC, #FC, #00	; 85 U
			db #CC, #CC, #CC, #CC, #CC, #78, #30, #00	; 86 V
			db #C6, #C6, #C6, #D6, #FE, #EE, #C6, #00	; 87 W
			db #C6, #C6, #6C, #38, #38, #6C, #C6, #00	; 88 X
			db #CC, #CC, #CC, #78, #30, #30, #78, #00	; 89 Y
			db #FE, #C6, #8C, #18, #32, #66, #FE, #00	; 90 Z
			db #78, #60, #60, #60, #60, #60, #78, #00	; 91 [
			db #C0, #60, #30, #18, #0C, #06, #02, #00	; 92 \
			db #78, #18, #18, #18, #18, #18, #78, #00	; 93 ]
			db #10, #38, #6C, #C6, #00, #00, #00, #00	; 94 ^
			db #00, #00, #00, #00, #00, #00, #00, #FF	; 95 _
			db #30, #30, #18, #00, #00, #00, #00, #00	; 96 `
			db #00, #00, #78, #0C, #7C, #CC, #76, #00	; 97 a
			db #E0, #60, #60, #7C, #66, #66, #DC, #00	; 98 b
			db #00, #00, #78, #CC, #C0, #CC, #78, #00	; 99 c
			db #1C, #0C, #0C, #7C, #CC, #CC, #76, #00	; 100 d
			db #00, #00, #78, #CC, #FC, #C0, #78, #00	; 101 e
			db #38, #6C, #60, #F0, #60, #60, #F0, #00	; 102 f
			db #00, #00, #76, #CC, #CC, #7C, #0C, #F8	; 103 g
			db #E0, #60, #6C, #76, #66, #66, #E6, #00	; 104 h
			db #30, #00, #70, #30, #30, #30, #78, #00	; 105 i
			db #0C, #00, #0C, #0C, #0C, #CC, #CC, #78	; 106 j
			db #E0, #60, #66, #6C, #78, #6C, #E6, #00	; 107 k
			db #70, #30, #30, #30, #30, #30, #78, #00	; 108 l
			db #00, #00, #CC, #FE, #FE, #D6, #C6, #00	; 109 m
			db #00, #00, #F8, #CC, #CC, #CC, #CC, #00	; 110 n
			db #00, #00, #78, #CC, #CC, #CC, #78, #00	; 111 o
			db #00, #00, #DC, #66, #66, #7C, #60, #F0	; 112 p
			db #00, #00, #76, #CC, #CC, #7C, #0C, #1E	; 113 q
			db #00, #00, #DC, #76, #66, #60, #F0, #00	; 114 r
			db #00, #00, #7C, #C0, #78, #0C, #F8, #00	; 115 s
			db #10, #30, #7C, #30, #30, #34, #18, #00	; 116 t
			db #00, #00, #CC, #CC, #CC, #CC, #76, #00	; 117 u
			db #00, #00, #CC, #CC, #CC, #78, #30, #00	; 118 v
			db #00, #00, #C6, #D6, #FE, #FE, #6C, #00	; 119 w
			db #00, #00, #C6, #6C, #38, #6C, #C6, #00	; 120 x
			db #00, #00, #CC, #CC, #CC, #7C, #0C, #F8	; 121 y
			db #00, #00, #FC, #98, #30, #64, #FC, #00	; 122 z
			db #1C, #30, #30, #E0, #30, #30, #1C, #00	; 123 {
			db #18, #18, #18, #00, #18, #18, #18, #00	; 124 |
			db #E0, #30, #30, #1C, #30, #30, #E0, #00	; 125 }
			db #76, #DC, #00, #00, #00, #00, #00, #00	; 126 ~

ntc_rg612_e:
			IF ($ < 32768) && (ntc_rg613_e - ntc_rg613 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg613:
;## ntc_plat_scroll ntc_plat_data ntc_data @shared
; ------------------------------------------------------------
; ntc_plat_scroll - move rows 1-31 up one, clear row 31
; ------------------------------------------------------------
ntc_plat_scroll:
			ld a, ZXN_ROWS - 1
			ld (ntc_cury), a
			ld a, (ntc_scols)
			ld c, a
			ld b, 0					; BC = a row
			ld hl, ZXN_MAP
			add hl, bc
			ld de, ZXN_MAP
			cp 80
			ld bc, (ZXN_ROWS - 1) * 40
			jr nz, ntc_sc_40
			ld bc, (ZXN_ROWS - 1) * 80
ntc_sc_40:
			ldir					; DE = the last row
			ld h, d
			ld l, e
			ld (hl), ' '
			inc de
			ld c, a
			dec c
			ld b, 0
			ldir
			jp (ix)

; ------------------------------------------------------------
; ntc_plat_cls - the whole tilemap spaces, cursor home
; ------------------------------------------------------------
ntc_plat_cls:
			ld hl, ZXN_MAP
			ld de, ZXN_MAP + 1
			ld bc, ZXN_ROWS * 80 - 1
			ld (hl), ' '
			ldir
			xor a
			ld (ntc_wrapped), a
			ld (ntc_curx), a
			ld (ntc_cury), a
			jp (ix)

ntc_rg613_e:
			IF ($ < 32768) && (ntc_rg614_e - ntc_rg614 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg614:
;## ntc_plat_key ntc_plat_data ntc_data @shared
; ------------------------------------------------------------
; ntc_plat_scankey - A = ASCII of a key pressed since the last scan,
; 0 if none
; ------------------------------------------------------------
ntc_plat_scankey:
			ld hl, ntc_kcur
			ld b, #FE				; half row 0 (address line A8 low) ... 7 (A15)
ntc_ks_line:
			ld c, #FE
			in a, (c)
			or #E0					; (bits 5-7: no keys)
			ld (hl), a
			inc hl
			rlc b
			jr c, ntc_ks_line		; (B's 0 bit moves up: done after A15)
			ld a, #FF
			ld (ntc_kidx), a
			ld hl, ntc_kcur
			ld de, ntc_kprev
			ld iy, ntc_kign
			ld bc, #0800			; B = 8 half rows, C = key index (half row * 8 + bit)
ntc_ks_find:
			ld a, (ntc_kidx)
			inc a
			jr nz, ntc_ks_next
			ld a, (hl)
			cpl
			ex de, hl
			and (hl)				; pressed now, released last scan
			ex de, hl
			and (iy+0)				; not Caps Shift / Symbol Shift
			jr z, ntc_ks_next
ntc_ks_bit:
			rrca
			jr c, ntc_ks_got
			inc c
			jr ntc_ks_bit
ntc_ks_got:
			ld a, c
			ld (ntc_kidx), a
ntc_ks_next:
			ld a, c
			and #F8
			add a, 8
			ld c, a
			inc hl
			inc de
			inc iy
			djnz ntc_ks_find
			ld hl, ntc_kcur
			ld de, ntc_kprev
			ld bc, 8
			ldir
			ld a, (ntc_kidx)
			cp #FF
			jr z, ntc_ks_none
			ld e, a
			ld d, 0
			ld hl, ntc_keymapy		; Symbol Shift (half row 7 bit 1) first
			ld a, (ntc_kcur + 7)
			bit 1, a
			jr z, ntc_ks_map
			ld hl, ntc_keymapc		; then Caps Shift (half row 0 bit 0)
			ld a, (ntc_kcur)
			bit 0, a
			jr z, ntc_ks_map
			ld hl, ntc_keymap
ntc_ks_map:
			add hl, de
			ld a, (hl)
			jp (ix)
ntc_ks_none:
			xor a
			jp (ix)

; ------------------------------------------------------------
; ntc_plat_getkey - wait for a key press, A = ASCII
; ------------------------------------------------------------
ntc_plat_getkey:
			ld (ntc_klink), ix
ntc_gk_scan:
			ld ix, ntc_gk_back
			jp ntc_plat_scankey
ntc_gk_back:
			or a
			jr nz, ntc_gk_done
			ld a, (ntc_nmode)		; normal mode: interrupts in while waiting
			or a
			jr z, ntc_gk_wait
			ld (ntc_ip), sp
			ld sp, (ntc_csp)
			ei
ntc_gk_wait:
			ld bc, 7000				; about 6ms between scans at 28MHz (debounce)
ntc_gk_delay:
			dec bc
			ld a, b
			or c
			jr nz, ntc_gk_delay
			di
			ld a, (ntc_nmode)
			or a
			jr z, ntc_gk_scan
			ld sp, (ntc_ip)
			jr ntc_gk_scan
ntc_gk_done:
			ld ix, (ntc_klink)
			jp (ix)

; keys that never count as a press on their own (Caps Shift, Symbol Shift)
ntc_kign:		db #FE, #FF, #FF, #FF, #FF, #FF, #FF, #FD

; half row 0-7, bit 0-4 -> ASCII (0 = nothing); 8 a half row, 5-7 unused
; 0 Caps Z X C V   1 A S D F G   2 Q W E R T   3 1 2 3 4 5
; 4 0 9 8 7 6      5 P O I U Y  6 Enter L K J H   7 Space Symbol M N B
ntc_keymap:
			db 0, "z", "x", "c", "v", 0, 0, 0
			db "a", "s", "d", "f", "g", 0, 0, 0
			db "q", "w", "e", "r", "t", 0, 0, 0
			db "1", "2", "3", "4", "5", 0, 0, 0
			db "0", "9", "8", "7", "6", 0, 0, 0
			db "p", "o", "i", "u", "y", 0, 0, 0
			db 13, "l", "k", "j", "h", 0, 0, 0
			db " ", 0, "m", "n", "b", 0, 0, 0
ntc_keymapc:								; Caps Shift: capitals; + 0 DEL, + Space Break
			db 0, "Z", "X", "C", "V", 0, 0, 0
			db "A", "S", "D", "F", "G", 0, 0, 0
			db "Q", "W", "E", "R", "T", 0, 0, 0
			db 0, 0, 0, 0, 0, 0, 0, 0			; (Edit, Caps Lock, True / Inverse Video, cursor left)
			db 127, 0, 0, 0, 0, 0, 0, 0			; (Graphics, cursor right / up / down)
			db "P", "O", "I", "U", "Y", 0, 0, 0
			db 13, "L", "K", "J", "H", 0, 0, 0
			db 27, 0, "M", "N", "B", 0, 0, 0
ntc_keymapy:								; Symbol Shift: the symbols on the keys (+ the 128's ~ | \ { } [ ])
			db 0, ":", 0, "?", "/", 0, 0, 0		; (X: pound)
			db "~", "|", 92, "{", "}", 0, 0, 0
			db 0, 0, 0, "<", ">", 0, 0, 0		; (Q, W, E: <= <> >=)
			db "!", "@", "#", "$", "%", 0, 0, 0
			db "_", ")", "(", 39, "&", 0, 0, 0
			db 34, ";", 0, "]", "[", 0, 0, 0		; (I: copyright)
			db 13, "=", "+", "-", "^", 0, 0, 0
			db " ", 0, ".", ",", "*", 0, 0, 0

ntc_rg614_e:
			IF ($ < 32768) && (ntc_rg615_e - ntc_rg615 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg615:
;## ntc_plat_frame ntc_plat_data ntc_data @shared
; ------------------------------------------------------------
; ntc_plat_frame - wait for the end of the display (raster line 192: the
; bottom border starts). Normal mode: interrupts in while waiting
; ------------------------------------------------------------
ntc_plat_frame:
			ld (ntc_klink), ix		; (ntc_klink: the return - IX runs ntc_fr_line)
			ld a, (ntc_nmode)
			or a
			jr z, ntc_fr_go
			ld (ntc_ip), sp
			ld sp, (ntc_csp)
			ei
ntc_fr_go:
			ld bc, #243B
ntc_fr_out:						; first out of lines 192 and on (the border, the sync)
			ld ix, ntc_fr_out2
			jr ntc_fr_line
ntc_fr_out2:
			jr nz, ntc_fr_out
ntc_fr_in:						; then wait for line 192
			ld ix, ntc_fr_in2
			jr ntc_fr_line
ntc_fr_in2:
			jr z, ntc_fr_in
			jr ntc_fr_at
; the raster line (NextReg #1E: its bit 8, #1F: bits 0-7), its two halves read
; again until bit 8 is the same both times (line 255 to 256 between them reads
; as 0): NZ = line 192 or more. Back to IX; keeps BC (#243B)
ntc_fr_line:
			ld a, #1E
			ld (ntc_zxsel), a		; (interrupts are in: the handler selects it again)
			out (c), a
			inc b
			in d, (c)
			dec b
			ld a, #1F
			ld (ntc_zxsel), a
			out (c), a
			inc b
			in e, (c)
			dec b
			ld a, #1E
			ld (ntc_zxsel), a
			out (c), a
			inc b
			in a, (c)
			dec b
			cp d
			jr nz, ntc_fr_line
			rra
			jr c, ntc_fr_lnz		; 256 and on
			ld a, e
			cp 192
			ccf
			sbc a, a				; #FF: 192-255, 0: below
			jp (ix)
ntc_fr_lnz:
			or 1
			jp (ix)
ntc_fr_at:
			di
			ld a, (ntc_nmode)
			or a
			jr z, ntc_fr_done
			ld sp, (ntc_ip)
ntc_fr_done:
			ld ix, (ntc_klink)
			jp (ix)

ntc_rg615_e:
			IF ($ < 32768) && (ntc_rg616_e - ntc_rg616 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg616:
;## ntc_plat_ticks ntc_data
; ------------------------------------------------------------
; ntc_plat_ticks - HL = interrupt count (300 a second, normal mode)
; ------------------------------------------------------------
ntc_plat_ticks:
			ld hl, (ntc_ticks)
			jp (ix)

ntc_rg616_e:
			IF ($ < 32768) && (ntc_rg617_e - ntc_rg617 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg617:
;## ntc_plat_irq ntc_plat_data ntc_data ntc_plat_irqh @shared
; ------------------------------------------------------------
; ntc_plat_irqon - put the interrupt handler at #38 (IM 1: the stub set it) and
; start the line interrupt at raster line 0, the ULA's frame interrupt off
; (NextReg #22: bit 2 the ULA's off, bit 1 the line interrupt on, bit 0 the
; line's bit 8; #23 its bits 0-7). The handler moves it on 52 lines each time
; ------------------------------------------------------------
ntc_plat_irqon:
			ld hl, (#0038)
			ld (ntc_irqold), hl
			ld a, (#003A)
			ld (ntc_irqold + 2), a
			ld a, #C3			; jp ntc_irq
			ld (#0038), a
			ld hl, ntc_irq
			ld (#0039), hl
			ld hl, 0
			ld (ntc_zxline), hl
			ld bc, #243B
			ld a, #23
			out (c), a
			inc b
			xor a
			out (c), a
			dec b
			ld a, #22
			out (c), a
			inc b
			ld a, 6
			out (c), a
			ld a, 1
			ld (ntc_irqset), a
			jp (ix)

ntc_rg617_e:
			IF ($ < 32768) && (ntc_rg618_e - ntc_rg618 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg618:
;## ntc_plat_irqh ntc_plat_data ntc_data @shared
; the handler: runs on the real stack, between keywords. The line interrupt,
; every 52 raster lines - 6 a frame of 312 lines, 300 a second, as the CPC's:
; counts a tick and sets the next one (52 lines on; the one at line 0 is a
; frame's first: ntc_zxvs 1 for the interrupt classes' counting). AF goes to
; AF', HL to RAM, the other registers are kept.
ntc_irq:
			ex af, af'
			ld (ntc_irqhl), hl
			ld hl, (ntc_ticks)
			inc hl
			ld (ntc_ticks), hl
			push bc
			push de
			ld hl, (ntc_zxline)		; the line this one came at
			ld a, h
			or l
			ld a, 0
			jr nz, ntc_irq_nf
			inc a
ntc_irq_nf:
			ld (ntc_zxvs), a		; 1: line 0, a frame's first
			ld de, 52
			add hl, de
			ld de, -312
			add hl, de
			jr c, ntc_irq_wr		; past the last line (312 and on): line 0 again
			sbc hl, de				; (carry clear: back to the line)
ntc_irq_wr:
			ld (ntc_zxline), hl
			ld bc, #243B
			ld a, #23
			out (c), a
			inc b
			out (c), l
			dec b
			ld a, #22
			out (c), a
			inc b
			ld a, h
			or 6					; the ULA's interrupt off, the line interrupt on
			out (c), a
			dec b
			ld a, (ntc_zxsel)		; the NextReg the code it came in on had selected
			out (c), a
			pop de
			pop bc
			ld a, (ntc_hookon)	; an Interrupt hook: run it at the next safe point
			or a
			jr z, ntc_irq_nohook
			ld (ntc_hookpend), a
ntc_irq_nohook:
			ld hl, (ntc_irqv)		; interrupt classes (Option Class Interrupt): count them
			ld a, h
			or l
			jr z, ntc_irq_nocl
			push bc
			ld a, (ntc_zxvs)
			ld c, a					; C = 1: a frame's first (ntc_isl_tick reads it on zxn)
			call ntc_irq_jp			; (the handler runs on the real stack)
			pop bc
ntc_irq_nocl:
			ld hl, (ntc_irqhl)
			ex af, af'
			ei
			ret
ntc_irq_jp:
			jp (hl)

ntc_rg618_e:
			IF ($ < 32768) && (ntc_rg619_e - ntc_rg619 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg619:
;## ntc_plat_exit ntc_plat_data
; ------------------------------------------------------------
; ntc_plat_exit - the end: interrupts off, a soft reset (NextReg 2 bit 0) -
; back to NextZXOS (a NEX file has no caller to return to)
; ------------------------------------------------------------
ntc_plat_exit:
			di
			ld bc, #243B
			ld a, #02
			out (c), a
			inc b
			ld a, 1
			out (c), a
ntc_ex_wait:
			jr ntc_ex_wait

ntc_rg619_e:
			IF ($ < 32768) && (ntc_rg620_e - ntc_rg620 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg620:
;## ntc_plat_memtop
; ntc_plat_memtop - HL = the first byte the Memory class's Small heap must not
; use: #BE00 (the stack is above, to #C000). Called on the real stack
; (call / ret), only by the Memory class.
ntc_plat_memtop:
			ld hl, #BE00
			ret

ntc_rg620_e:
			IF ($ < 32768) && (ntc_rg621_e - ntc_rg621 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg621:
;## ntc_plat_rmr ntc_plat_data
; ntc_plat_rmr - zxn has no CPC gate-array ROM/mode byte; CallBank needs no ROM
; switching here. Return the current screen mode byte, keep BC, DE, HL.
ntc_plat_rmr:
			ld a, (ntc_smode)
			ret


ntc_rg621_e:
ntc_end:				; the end of the program (and of its file)
glyph_20			equ ntc_font + 0		; " "
glyph_28			equ ntc_font + 64		; "("
glyph_29			equ ntc_font + 72		; ")"
glyph_2C			equ ntc_font + 96		; ","
glyph_30			equ ntc_font + 128		; "0"
glyph_32			equ ntc_font + 144		; "2"
glyph_33			equ ntc_font + 152		; "3"
glyph_35			equ ntc_font + 168		; "5"
glyph_36			equ ntc_font + 176		; "6"
glyph_43			equ ntc_font + 280		; "C"
glyph_4B			equ ntc_font + 344		; "K"
glyph_4F			equ ntc_font + 376		; "O"
glyph_50			equ ntc_font + 384		; "P"
glyph_53			equ ntc_font + 408		; "S"
glyph_61			equ ntc_font + 520		; "a"
glyph_62			equ ntc_font + 528		; "b"
glyph_64			equ ntc_font + 544		; "d"
glyph_65			equ ntc_font + 552		; "e"
glyph_67			equ ntc_font + 568		; "g"
glyph_69			equ ntc_font + 584		; "i"
glyph_6B			equ ntc_font + 600		; "k"
glyph_6D			equ ntc_font + 616		; "m"
glyph_6E			equ ntc_font + 624		; "n"
glyph_6F			equ ntc_font + 632		; "o"
glyph_70			equ ntc_font + 640		; "p"
glyph_72			equ ntc_font + 656		; "r"
glyph_73			equ ntc_font + 664		; "s"
glyph_78			equ ntc_font + 704		; "x"
glyph_79			equ ntc_font + 712		; "y"
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
arr_kq		equ ntc_bss + 126		; 42 bytes
arr_wp		equ ntc_bss + 168		; 42 bytes
arr_dm		equ ntc_bss + 210		; 42 bytes
arr_dv		equ ntc_bss + 252		; 42 bytes
arr_ra		equ ntc_bss + 294		; 42 bytes
arr_wk		equ ntc_bss + 336		; 42 bytes
arr_tn		equ ntc_bss + 378		; 42 bytes
arr_nb		equ ntc_bss + 420		; 42 bytes
arr_nc		equ ntc_bss + 462		; 42 bytes
arr_lt		equ ntc_bss + 504		; 42 bytes
arr_lb		equ ntc_bss + 546		; 42 bytes
arr_lc		equ ntc_bss + 588		; 42 bytes
arr_rb		equ ntc_bss + 630		; 128 bytes
arr_ent_en		equ ntc_bss + 758		; 12 bytes
ntc_bss_size	equ 770
ntc_free	equ ntc_bss + ntc_bss_size	; the first free byte (heap, Memory tables)
			IF ntc_free <= 32768	; fwdref-ok
ntc_memtab	equ 32768		; the Memory class's tables: above the window (Option Reserve)
			ELSE
ntc_memtab	equ ntc_free
			ENDIF
; Option Reserve: the program and its arrays (ntc_start .. ntc_free) must stay out of these
			ASSERT (ntc_free <= 16384) || (ntc_bss >= 32768), "the program (or its arrays) reaches into Option Reserve #4000-#7FFF (Main.bas line 25)"

; ============================================================
; ZX Spectrum Next: the start stub (bank 5, page 11 at #7E00) and the NEX file
; ============================================================
			ASSERT ntc_free <= #BE00, "the program and its arrays must end below #BE00 (the stack is #BE00-#BFFF, the screen #C000-#FFFF)"
			MMU 3, 11			; page 11 (bank 5's second half) at #6000 to assemble the stub
			org #7E00
zxn_boot:
			di
			ld bc, #243B		; NextReg select (#253B: its value)
			ld a, 6			; Peripheral 2: the NMI buttons off (bit 3 Multiface M1, bit 4 DivMMC DRIVE)
			out (c), a
			inc b
			in a, (c)
			and %11100111
			out (c), a
			dec b
			ld a, 10			; Peripheral 5: DivMMC automatic paging off (bit 4)
			out (c), a
			inc b
			in a, (c)
			and %11101111
			out (c), a
			dec b
			xor a
			out (#E3), a		; DivMMC: its memory out
			ld a, 7			; CPU speed: 28MHz
			out (c), a
			inc b
			ld a, 3
			out (c), a
			dec b
			ld hl, zxn_mmu		; the slots but 3
			ld e, 7
zxn_bmmu:
			ld a, (hl)
			inc hl
			out (c), a
			inc b
			ld a, (hl)
			inc hl
			out (c), a
			dec b
			dec e
			jr nz, zxn_bmmu
			jp zxn_boot2 + #8000	; on in the copy at #E000-#FFFF (page 11 in slot 7)
zxn_boot2:
			ld a, #53			; slot 3: page 19
			out (c), a
			inc b
			ld a, 19
			out (c), a
			ld hl, #C9FB		; #0038: ei, ret until ntc_plat_irqon puts its jump there
			ld (#0038), hl
			im 1
			jp ntc_start
zxn_mmu:	db #50, 16, #51, 17, #52, 18, #54, 20, #55, 21, #56, 10, #57, 11
			SAVENEX OPEN "NTC.NEX", zxn_boot, #BFFE
			SAVENEX CORE 3, 0, 0
			SAVENEX CFG 0
			SAVENEX BANK 5, 8, 9, 10
			SAVENEX CLOSE
