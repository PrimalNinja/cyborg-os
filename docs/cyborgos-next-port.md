# Porting CyborgOS to the ZX Spectrum Next — porting notes

Living notes for the CyborgOS → ZX Spectrum Next port. Kept as the work goes so later ports (other
Z80 machines, the planned CPC-free virtual Z80) can reuse the hardware map and the decisions.
Started 2026-10-18.

## 2026-10-21 — boots to a working system in RAM with a Z: drive

The startup crash, found and fixed (traced in ZEsarUX, built from source and driven over its remote
protocol, and in the harness), plus the things behind it:

1. **`out (c), c` on a RAM setting — the crash.** Hyp.cls had ~33 gate-array writes (`ld bc,
   setting : out (c), c`) with no zxn branch: Con, Say, FileCall, FileShut, Svc (`sv_inst`), Drive.
   On the Next `#7FC0` decodes as `#7FFD`, the 128K paging port: ROM into MMU slots 0/1, bank 0 into
   6/7 — the hypervisor's thread vanishes under it and it runs into the ROM (first hit: `Svc(0,0,0)`
   installing the services at boot). The harness never showed it: it has no gate array, so the
   write did nothing and the window happened to hold the right page. Every one is now
   `call nxt_win` under `IFDEF NTC_ZXN` (`ntc_lib_nxt.asm`: BC = a setting → its 16K bank into the
   window via the MMU ports, keeps every register as the `out` does).
2. **One setting encoding on the Next, shaped as the CPC's.** The Memory class's settings were
   `B = 0, C = the Next 16K bank`; `Hyp.Setting()` gave a 1-based bank index; `sv_dx`/`fl_dx` take
   `B = 0` as "main RAM, no switch"; `fl_sel`, `sv_sw`, Main's `wp(i)` do the CPC's `and #F8 : or
   4 + n`. None of that fitted. Now (`ntc_lib_nxt.asm`: `nxt_mem_jbc`, `nxt_mem_bank`) a setting is
   `B = 1` (never 0, never #7F), `C = the 64K bank's ordinal * 8 + 4 + its 16K page` — so a bank's
   "C2" setting is page 0's `and #F8 or 2`, page n in the window is `or 4 + n`, exactly the CPC's
   arithmetic, and `Setting()`, `Run`, `fl_sel`, `sv_sw`, Main all work unchanged. `nxt_mem_bank`
   decodes it (`#7FC0` = main RAM's own bank 9).
3. **The RAM probe stops at bank 111.** It marked banks 22-127; a 2MB Next has 112 16K banks
   (pages 0-223) and the MMU has no page past 223 — those would alias or hit nothing. `ZXN_MAXBANK`
   is 90. (A 1MB Next: 26 banks = 6 of 64K = 3 slots, Z: in what is left; 2MB: 22 = 11 slots.)
4. **The 300 Hz line-interrupt chain stalled dead.** The Next's INT is a pulse (32T at 3.5MHz), not
   held until taken (the harness holds it — a fidelity gap, noted in `zxnrun.py`). NTC normal mode
   runs with interrupts off except the one-instruction window at safe points and the Frame / key
   waits. CyborgOS's main loop is paced by Frame (back at line 192, then a stretch with interrupts
   off), so the pulse at line 208 came in that stretch every frame: `ntc_ticks` froze at 4, Hot's
   Tick never ran, the hotkeys were dead. Fixed in `ntc_plat_zxn.asm`: the handler reads the raster,
   counts every 52-line step missed since the line it was set for (the clock keeps time, the
   interrupt classes see each tick, the frame's first among them) and sets the next line ahead of
   the raster; and the Frame wait re-arms the chain when the raster has passed the set line with
   no interrupt. The zxn interrupt-class, hook, Frame/Ticks and keys regress tests pass.
5. **Console: 80 columns on the tilemap.** `zxn_sm_tab` had MODE S as 40 x 32 (a Layer 2 plan) while
   the tilemap is 80 wide: a 40-column layout drawn into an 80-column map. All modes are 80 (P 64)
   x their CPC rows now; `Scr(m, 2)` clears the tilemap; the scroll moves the tilemap's rows up and
   clears the last (no redraw); `Say` (TOP's direct writer) writes the tilemap — it wrote the CPC's
   mode 2 bitmap at `#C000-#FFFF`, which on the Next is the tiles, the stub copy and the hypervisor's
   top of memory (the "missing letters" and TOP's crash).
6. **No pushes on the thread.** `Say`'s zxn code and Main's `call gfx_on` pushed with SP on the NTC
   thread, overwriting executed thread words: Main's loop re-ran them (restart at `ntc_start`).
   `gfx_on` is called on the real stack now; `Say` uses registers only.
7. **Hotkeys on the Next (Hot.cls).** No Control key on the membrane, and Symbol Shift types the
   punctuation, so: **Caps Shift + 1-9 = that slot, Caps Shift + 0 = TOP** (Caps + Space Break).
   Caps + 0 is Delete on a Spectrum and the Next's Delete key reaches the matrix as Caps + 0 too,
   so Hot's `Chord()` reads NextReg `#B1` (the Next's dedicated keys, raw: bit 7 Delete, 6 Edit, 5
   Break, 4 Inv Video, 3 True Video, 2 Graph, 1 Caps Lock, 0 Extend; `#B0` the cursors and ; " , .):
   the Delete key stays Delete, Caps + 0 pressed as two keys is TOP (Julian's choice over Caps +
   Enter, which went). Hot's `ctl` is on only during such a chord, so Caps + a letter still types a
   capital. The banners say so (`SK()`, `TK()` in Main.bas: "Shift + 1-9", "Shift + 0").
   The background is the CPC's blue: with Layer 2 on the tilemap's paper is see-through, so
   Main.bas sets Layer 2's palette index 0 (its cleared colour) to RGB 0 0 4 after `gfx_on`.
8. **The boot drive A: is an archive in the NEX; Z: is made from it.** No ROM drive exists on the
   Next, so the CPC's disc reads (CAS IN, in FileCall's page code) have zxn versions that read a
   read-only archive carried in the NEX's data banks (`Option NexData "CYBORGOS.ARC", 7` — banks 1-4,
   6, 7, 11, outside the Memory class's pool): `tools/nexarc/nexarc.py` makes it (CyborgOS's own
   layout, not CP/M's ARC: 16 bytes - "CARC", the entry count -, then 16-byte entries - the 8 + 3
   name, a 3-byte length, the first record -, then the files uncompressed from 128-byte record
   boundaries), `tools/nexarc/build.sh` builds the commands (the cyborgos platform: .CYB, carried
   with their AMSDOS header, which the open leaves out) and the archive and the NEX. `fl_inopen` / `fl_rdrec` / `fl_inclose` read it (a record's 8K page mapped into
   slot 6, `#C000-#DFFF`, for the copy — page 10 there is unused); writes, UniDOS and the ROM commands
   answer 255 / no. Boot then does what the CPC does: `ProbeDiscs()` (RAM discs that outlived a reset),
   else `RAMDISC Z SYSTEM A` as a task — RAMDISC.CYB reads A:CYBORGOS.Z and copies the commands onto
   the Z: RAM disc (the driver page, Memory-class pages: pure Z80, unchanged). On a 1MB Next: 13
   commands, 94K, 2 banks left over; every command (DIR, PS, MEM, FG, KILL, TOP ...) runs from Z:.
   Verified in the harness and in ZEsarUX. On A: now (`build.sh`'s LIST / HELPS): RAMDISC, DIR, CD,
   CV, FG, KILL, MEM, TOP, TYPE, HELP, RESET, ERA and their .HLP files (10 blocks = 160K; WAIT, PS,
   MODE left off at Julian's word, FLOPPY, NET, DRIVE, COPY not yet). `dir a:` lists it (BDOS
   17/18 over the archive's directory, `fl_arc_dir`). The archive can grow past the 7 low banks:
   NTC puts blocks 8+ in bank 22 on and starts the Memory class's pool after them (`ZXN_FIRSTBANK`
   from the block count). MEM shows the Next's main memory map (op 7 hands MEM the host in byte 1).
9. **Hot.cls debounce.** On the real keyboard a chord's digit going up with Caps still down reads as
   another key for a scan (3 let go: a "1"), so a chord counts only when read the same two ticks
   running (`kk`).
10. **Main RAM is at the edge.** The code below the window hole (`#0040-#3FFF`) ends at `#30A2` and
   the big region after it (the hypervisor's #asm blocks, 3.9K) just fits before `#4000`; a few
   bytes more anywhere below the hole and the compiler moves that region above it, losing 4K and
   failing the `ntc_free <= #BE00` assert. When that happens: shave bytes, or move code out of main
   RAM (the archive's `fl_arc_dir` lives in the page code for that reason).
11. **Harness.** `zxnrun.py`: `{a+b}` chords (`{0+25*}` = Caps Shift + 2 held), `NTC_TRACEZ` (an
   instruction trace into a condition: `sp>c000`, `pc>dfff`, `pc=xxxx`; `NTC_TRACEZ_SKIP` ranges).
12. **Caps Shift alone selects slot 1 on Julian's Next** (and a digit let go with Caps held did the
   same). Hot.cls cannot make a 1 from nothing: a "1" needs port `#F7FE` bit 0 low, so his machine
   reports the "1" key down with Caps - the Next's keyboard controller makes its dedicated keys as
   48K chords (Edit = Caps + 1, Caps Lock = Caps + 2, the cursors = Caps + 5-8, Delete = Caps + 0,
   Break = Caps + Space; NextReg `#B0`/`#B1` have them raw), a PS/2 mapping or a joystick on
   Sinclair 2 (whose left is key 1) are the suspects. Neither emulator shows it. To see it: **the TOP
   screen's bottom row (31) shows the 8 half rows of the matrix as hex, live** (`KeyRow`, `KeyRows`
   in Main.bas: `1E 1F 1F 1F 1F 1F 1F 1F` = Caps Shift down, 5 bits a row, 0 = down; rows `#FE`
   Caps Z X C V, `#FD` A S D F G, `#FB` Q W E R T, `#F7` 1 2 3 4 5, `#EF` 0 9 8 7 6, `#DF` P O I U Y,
   `#BF` Enter L K J H, `#7F` Space Sym M N B). Hot's eleven `Keys.Down` calls became one Z80
   `Chord()` (0 = TOP, then 9 down to 1: the highest wins) - 200 bytes of main RAM back, which the
   readout needed (item 10); the readout runs every loop while TOP shows. If the matrix shows `#F7` bit 0 low with Caps, the fix is the
   machine's; if not, Symbol Shift + 1-9 is the fallback (nothing on the Next synthesizes it).
13. **The cursor.** `cn_cuxor` on zxn was a stub (the CPC XORs an underline into the bitmap; the
   text is tiles). Now: on, the cell's character is kept (`cn_cuch`) and `_` put in its tile; off,
   the character back. Main's 0.5 s flash (`Hyp.Con wp(front), 0, -3, 1`) drives it as on the CPC.
14. **The SD card: drive C: and folders, through NextZXOS's esxDOS API.** The design is the CPC's
   UniDOS one: a drive letter with a path in `FL_MAP` is a folder of the SD card (`C:` its top,
   `C:GAMES/` after `CD GAMES`; `CD ..`, `CD /`, `CV`, a free letter from C getting a folder - the
   CD / CV / DIR / MKDIR / RMDIR commands unchanged), letters with no path stay the boot archive's.
   `fl_pfxm` notes a path put before a name (`fl_sdf`), and hooks in FileCall's page code hand such
   calls to the SD code `sd_*`: `fl_inopen` / `fl_rdrec` / `fl_inclose` (reading - the CPC's one
   file at a time, records in turn; random access by reading on or opening again, as with AMSDOS),
   `fl_make` / `fl_wr_got` / `fl_cl_out` (writing: `F_OPEN` made anew, `F_WRITE` 128 at a time,
   `F_CLOSE`), `fl_del` (`F_UNLINK`, `F_RMDIR` after BDOS 30 op 8), `fl_ren` (`F_RENAME`: the new
   name without its drive letter - esxDOS calls that "invalid path"; the file being read is closed
   first when it is the one: CP/M leaves read files open), `fl_s_nod` (BDOS 17: the folder's files
   into the search's cache with `F_OPENDIR` / `F_READDIR`, folders left out), `fl_unicall` (BDOS
   30: 0 yes, 1 the letter's path, 2 set it - `F_OPENDIR` tries the folder -, 3 the devices: the
   SD card's letter, 4 free K (`F_GETFREE`), 5 the folder's entries with sizes and MS-DOS dates
   for DIR - the cache again, folders in, filled at entry 0 -, 6 `F_MKDIR`, 7 none, 8 the delete
   may take a folder). `sd_h_init` at FileCall 99: `fl_cjf` = 1 (paths on), FL_MAP cleared, the
   drive letter asked (`M_GETSETDRV`), `F_CHDIR "/"`, C: = "<letter>:". Programs load from the SD
   (`RUN`, a name typed: the hypervisor's reads 100-103 go through the same three hooks).
   **The call** (`sd_x`): the 48K ROM into slots 0-1 (MMU 0, 1 = 255), ROM 3 selected by NextReg
   `#8E` (= 3; it leaves slots 6, 7 alone - the ports `#7FFD` / `#1FFD` would move bank 0 into
   them), a stack of its own, `rst 8` + the hook byte (patched in), then `di`, ROM 0 (`#8E` = 0) and
   the MMU as it was. For `rst 8` to page DivMMC in, NextReg `#B8` must allow it: **NTC's NEX stub
   now leaves DivMMC's automatic paging on but cuts its entry points to RST 8 with ROM 3 selected**
   (`#B8` = 2, `#B9` = 0, `#BB` = 0) - the old stub turned paging off (NextReg `#0A` bit 4) and
   wrote port `#E3`, and either loses NextZXOS's esxDOS state (its handles are in DivMMC RAM): in
   ZEsarUX every call after came back "bad file number". Nothing an NTC program does is `rst 8`
   with ROM 3 in, so nothing else pages DivMMC in. **Where the code is**: the page code is full,
   main RAM too; the SD code sits in the hypervisor's page at `#4000`-`#4FFF` (window data from
   `#4000` - on zxn the CPC's disc buffers and font aren't there; `fl_inst` copies from `#4000`),
   in Info's block (the first `; @window`), reaching FileCall's names through sjasmplus global
   labels (`@g_fl_peek: EQU fl_peek` ...: NTC's new `@name:`). Variables' addresses (fin, fout,
   the parameters) come at init in registers, not as `EQU`s: an `EQU` of a label defined later in
   the file lags a pass in sjasmplus (the code got an address 74 bytes stale). The DOS is called
   with the hypervisor's page in the window, so `#5B00`-`#5CFF` of the page code is kept as
   scratch (`fl_sysv`): the ROM and the DOS keep system variables there (BANKM, the interrupt
   handler's), and that is where the page code's fl_srch1 used to be - corrupted by the first
   file read. `sd_trc` (DIAG, 16 entries: hook, A, IX, BC, then A, F, BC back) in the page at
   `#400D` is a ring of the calls made, readable from a debugger. **Tested in ZEsarUX booted
   from NextZXOS** (`tools/nexarc/sdimage.py`: an SD image from ZEsarUX's tbblue.mmc with the NEX
   on it and an AUTOEXEC.BAS that `.nexload`s it; ZEsarUX with `--enable-mmc --enable-divmmc-ports
   --enable-divmmc-paging --mmc-file`): DIR (names, FULL with sizes and dates), CD, CV, TYPE, COPY (to and from),
   RENAME, ERA, MKDIR, RMDIR, a .CYB run from the SD, A: and Z: as before. Not done: random
   access by `F_SEEK` (reads on / reopens, as the CPC), more than one file open per drive type,
   long names (short 8.3 names are listed), the free letter / device checks of CV (`IsDevice`),
   COPY, RENAME, MKDIR, RMDIR are on the NEX now (`build.sh`'s LIST). **A CPC's `.CYB` runs as it
   is**: the loader (`fl_hload`) skips a first record that is an AMSDOS header (`sd_amsh`: 128
   bytes, the checksum at 67 the sum of bytes 0-66), so a `.CYB` on the card can carry the header
   (copied from a CPC disc) or be the plain program (the archive's, `nexarc.py`'s way), and a
   `.COM` is the same bytes under the other name.

The keyboard while a program polls (a task with interrupts off misses the Next's INT pulse) is
done three ways at once: the stub gives the hypervisor a turn every 256th empty key poll and
leaves interrupts in during a poll; `Hot.Poll` reads the slot chords from the hypervisor's loop
once a frame by the raster line when the tick hasn't; and `ntc_zxn_inthold` asks the Next's
interrupt controller (core 3.02+) to hold the line interrupt until taken. Still to do, in
order: key repeat on the Next (the CPC's firmware repeats keys; the matrix scan reads new
presses only); the apps (MON, YING: the mouse on
Kempston); `Memory.Banks() >= 4` makes Z: on a 1MB Next (the CPC wants 8 — 576K) - keep or not;
the SD drive's random access (`F_SEEK`) and several files open; the scrollback (CN_SB, CPC
only); `Hyp.Mark` (DIAG) can go.

## The banking and switch — as built and proven (2026-10-20)

The sections further down (from "The context switch on the Next MMU") were the *design*. This is
what was actually built and runs. A CP/M task launches in its own 64K bank, runs at `#0100`, prints
via BDOS, is interrupted, the hypervisor reads its output through the window and renders it, then
resumes the task — both switch directions, stable past 120,000 frames. Both platforms compile 0
errors. The build is `build/next/CYBORGOS.NEX`.

### The one rule: NextReg only through ports `#243B`/`#253B`

Every MMU remap is `ld bc,#243B : ld a,<slot reg #50-#57> : out (c),a : inc b : out (c),<page>`
(slot register to `#243B`, page to `#253B`). Never the Z80N `nextreg` opcode. This is the
convention in `ntc_plat_zxn.asm`, and it is the thing that made the switch work: the pivots first
used `nextreg` and silently did nothing — the emulator doesn't execute the opcode, and it would tie
the build to a Z80N assembler. That was the real breakthrough, not the switch logic.

### The switch is asymmetric — task→hyp pivots LOW, hyp→task pivots HIGH

No atomic 64K flip, no shared memory, so one slot is the pivot: map that slot to the receiver, jump
into it, let the receiver map the rest. The two directions pivot on opposite ends:

- **task → hyp: the LOW pivot at `#0044`.** The receiver (the hypervisor) is in slot 0 (page 16).
  Low memory has room to pivot and re-seat all 7 of the hyp's slots.
- **hyp → task: the HIGH pivot on slot 7.** Going back there isn't room in low memory to pivot
  *and* re-enable the task's 7 slots, so it pivots on slot 7, where each bank carries its own
  receiver (`sb_hin`) just below `#FFFE`.

Push all regs / store SP / pivot memory / fetch SP / pop all regs — each side is unaware a new
context arrived. Only SP (and the far-call message in A/DE/HL) crosses.

### task → hyp — the `#0044` LOW pivot (compiler glue, `ntc_bk_out`)

At `#0044` in every bank and in main RAM:

```
#0044  db #08              ; ex af,af' - stash A+FLAGS (carry = far-call/interrupt) before the flip clobbers A
       ld bc,#243B         ; select MMU slot 0 (#50)
       ld a,#50
       out (c),a
       inc b               ; #253B
       ld a,16             ; the hypervisor's slot-0 page - slot 0 flips HERE
       out (c),a
ntc_bk_recv:               ; now executing in the hyp's slot 0 (the next byte, #0051)
       ld hl,ntc_bk_hpg    ; the hyp's resting pages, slots 1-7
       ld bc,#243B
       ld d,#51
ntc_bk_rc1:
       ld a,d : out (c),a : inc b : ld a,(hl) : out (c),a : dec b : inc hl : inc d
       ld a,d : cp #58 : jr nz,ntc_bk_rc1    ; slots #51..#57
       db #08              ; ex af,af' back  (IX untouched throughout = also preserved)
ntc_bk_land:
       ld sp,(ntc_bk_sp)   ; the hypervisor's own SP
       ret
ntc_bk_hpg: db 17,18,19,20,21,10,11   ; hyp resting pages, slots 1-7 (the boot MMU map)
```

What makes it survive the flip: slot 0 changes on the second `out`, and the very next instruction
fetched (`#0051`) is already in the hypervisor's slot 0, so execution runs straight through. The
carry (far-call vs interrupt) is parked in `AF'` because the port writes clobber A. `ntc_bk_out` is
asserted `== #0044`. There is no `#0046` landing on zxn (that is the CPC path); the pivot occupies
`#0044-#005B`.

### hyp → task — the HIGH pivot on slot 7 (`Run`)

The task saved all its own registers on its own stack before it ever left, so nothing rides the
multi-step flip. `Run` hands the task its results through the task's own slot-7 scratch (`SWAP` =
`#F690`: base page, A, rclr/E, HL), maps the task's slot 7 in, and jumps to the receiver in it:

```
       ld a,c : dec a : add a,a : add a,a    ; (index-1)*4
       add a,ZXN_FIRSTBANK : add a,a         ; = the task's slot-0 base page
       ld e,a : add a,7 : ld d,a             ; d = its slot-7 page
       ld bc,#243B : ld a,#57 : out (c),a : inc b : out (c),d   ; map task slot 7
       ... write SWAP: base(0), A(1), rclr(2), HL(3-4) ...
       jp #FFD0            ; HISW - sb_hin, in the task's own slot 7
```

`sb_hin` (copied below `#FFFE` in every bank, at `HISW=#FFD0`) runs from the just-mapped slot 7 —
the one slot it won't remap — maps slots 0-6 via the port loop (`#50..#56`), loads A/E/HL back out of
`SWAP`, and `jp sb_land` lands the task (its SP, `ret` into it).

### The window (Memory class) — `mem_se_out`, zxn branch

Slots 2,3 (`#4000-#7FFF`) are the window the hypervisor reads a task's memory through. `mem_se_out`
maps it: `B=#7F` → bank 9 (the hyp's own pages 18,19), else `C` = the Next 16K bank, page = bank\*2,
written to `#52`/`#53` via the ports. `ntc_rampt`/`ntc_zxsel` are saved so the interrupt handler
re-asserts the window.

### `fl_zxn_map` — the Install far-copy fix

FileCall 99 (`fl_inst`) + Install copy the window image + stubs + `sb_hin` + font into each task
bank. On the CPC that is `out (c),c`; on zxn that instruction is dead, so task banks were filled
with zeros (no stubs, no receiver — the empty-bank bug). `fl_zxn_map` replaces it: BC = a RAM
setting → its 16K bank into the window via the MMU, the same mapping as `mem_se_out`. Runs before
interrupts, so no `ntc_zxsel` re-select.

### The platform split (done 2026-10-20)

The keyword library is now three files: `ntc_lib_gen.asm` (the language core), `ntc_lib_cpc.asm`
(the Memory class / banking, CPC bodies) and `ntc_lib_nxt.asm` (the Next banking). The three
divergent routines — `mem_probe` (the RAM probe + `zxn_pr_map`), `mem_jbc`, `mem_se_out` — have
their Next versions in `ntc_lib_nxt.asm` as `nxt_mem_probe` / `nxt_mem_jbc` / `nxt_mem_se_out`,
the whole section guarded `IFDEF NTC_ZXN`; `ntc_lib_cpc.asm` keeps the CPC bodies and dispatches
to the Next ones (`call`/`jp nxt_*`) only on the Next path. `ntc_lib_nxt.asm` is a dependency of
`ntc_mem`, so the picker pulls it; `gen.js` bundles gen + cpc + nxt. CPC output is byte-identical
(only the `IFDEF NTC_ZXN`/`ELSE` branches moved, which CPC never assembled); the Next banking was
exercised before/after the split (probe reports the same pages/banks/RAM) and CyborgOS-Next builds
0 errors and boots unchanged.

`fl_zxn_map` (the FileCall 99 / Install far-copy) still lives in `Hyp.cls` — it is CyborgOS's own
code, not a Memory-class routine, so it stays with the hypervisor. The library platform split is
complete.

## What CyborgOS is (the thing being ported)

The CPC 320K build (`src/bas/cyborgos320kb/`), in NTC BASIC:

- `Main.bas` (~1150 lines) — the hypervisor entry: the slot table, the keyboard hotkeys
  (Ctrl+1..0 to the front, Ctrl+ESC the TOP screen), the round-robin scheduler, the command
  dispatch.
- `Hyp.cls` (~5700 lines) — the hypervisor proper: bank/slot management, the far-call BDOS a task
  makes (console, keys, files, exit), per-slot text pages, the context switch, services (ports).
- `Ent.cls`, `Hot.cls` — entry/hotkey helpers.
- `apps/` (ying, yang, mon, rvdu, rat, pluto), `cmds/` (PS, DIR, CD, COPY, …), `tasks/`, `tools/`.

The model: up to 20 slots, **each its own 64K bank**; a slot is a command line or a `.CYB` CP/M
program running from `#0100`; programs run round-robin (front slot gets half the time); each BDOS
call is a far call into the hypervisor; characters out are collected per bank and sent a line at a
time; an interrupt stops a task and returns the CPU to the hypervisor.

So CyborgOS is **three things stacked**: (1) a banked-memory manager, (2) a round-robin scheduler
with a per-task context switch, (3) a syscall (BDOS) + console/keyboard/file service layer. The
port has to re-seat all three on Next hardware.

## The hardware map — CPC → ZX Spectrum Next

| Concern | CPC (now) | ZX Spectrum Next | Port impact |
|---|---|---|---|
| CPU | Z80 | Z80N (extra ops, optional) | none — NTC zxn uses no Z80N ops (works on any assembler/harness) |
| Base map | firmware ROM + 64K RAM, screen `#C000` | NTC zxn maps 8K MMU pages **to look CPC-like**: pages 16-21 at `#0000-#BFFF`, screen bank 5 at `#C000` | **the per-slot 64K already looks like the CPC** — big head start |
| Banking | gate array, 16K pages into `#4000-#7FFF` (`Option Memory CPCExpansion`) | **8K MMU**, 8 slots (NextReg `#50-#57`), any 8K page to any slot; up to 2MB = 256 pages | the window-switch primitive **exists** (`zxn_sel`, maps a 16K bank → MMU slots 2,3 / NextReg `#52,#53`); the **allocation scheme does not** (zxn `Memory` is Small-only — "8K pages come later") |
| Window | `#4000-#7FFF` reserved (`Option Reserve`) | same `#4000-#7FFF` = MMU slots 2,3 | unchanged — CyborgOS's window model maps straight onto two Next MMU slots |
| Text screen | CPC mode 2, 80×25 | Next **tilemap text, 80×32** (Mode 2), over the ULA | better than the CPC (80×32); per-slot text pages port directly |
| Keyboard | PPI matrix (`#F6`/PSG 14) | 8×5 matrix (`#xxFE`) + extended keys | NTC zxn already reads it; hotkeys (Ctrl+…) need the Next's Caps/Symbol-shift mapping |
| Storage | AMSDOS / UniDOS / IDE / M4, via background ROMs (`Option RomEnable All`) | NextZXOS / esxDOS on SD (FatFS) | the file layer (`Hyp.FileCall`, the `.CYB` loader) must retarget to NextZXOS file hooks — **no CPC disc ROM** |
| Firmware | CPC firmware jumpblocks (cpcfw build) | **none** | CyborgOS's cpcfw build leans on firmware for files; the Next build must be firmware-free (NTC zxn is already native/no-firmware) |
| Timing / IRQ | 300Hz / 50Hz | 50Hz (`IM 1`, `#0038`) | the scheduler's interrupt classes port; the clock divisor differs |
| Boot | RUN"/disc, AMSDOS header | `NAME.NEX` (SAVENEX), loaded by NextZXOS | the boot/loader (`COSLOAD.BIN`) → a `.NEX` start stub |

## What NTC's `zxn` target already gives us (verified in `asm/ntc_plat_zxn.asm`, `lib/zxn/`)

- A **CPC-like flat 64K** per program: MMU pages 16-21 at `#0000-#BFFF`, stack at `#BE00` down,
  screen bank 5 at `#C000-#FFFF`.
- **80×32 tilemap text** (Mode 2), font `font8x8_basic`, yellow-on-blue; `Mode`, `Locate`, `Print`,
  `Cls` all work.
- **Keyboard** read (`#xxFE`, Caps/Symbol shift mapping).
- **The window-switch primitive `zxn_sel`**: HL = a 16K bank → mapped into `#4000-#7FFF` (MMU slots
  2,3, NextReg `#52`/`#53`); bank 0 restores the program's own pages (bank 9 = pages 18,19). Keeps
  BC/DE/HL, re-asserted by the interrupt handler. Today it serves `Option NexData` (static data
  blocks); it is exactly the primitive a banked allocator needs.
- **NextReg access via ports `#243B`/`#253B`** (no Z80N opcodes) — portable to any assembler/harness.
- `.NEX` output via SAVENEX; the start stub turns off the NMI buttons, DivMMC auto-paging and
  DivMMC memory, sets 28MHz + IM 1, maps the slots, jumps to `ntc_start`.

## The gaps (what the port has to build)

1. **A Next MMU page-allocation scheme** (the keystone). NTC's zxn `Memory` is Small (no paging).
   CyborgOS needs to allocate 64K banks (= 8 × 8K Next pages) for slots, hold free/used page lists,
   and switch a bank into the window. The `zxn_sel` primitive is the bottom of this; the allocator
   (probe RAM size, free list, AllocPage/Free, Far pointers, Copy-through-window) is missing. Either
   extend the core `Memory` class with a `zxn` banking scheme (compiler support like
   `cpcexpansion`), or give CyborgOS-Next its own banking class with the same API the hypervisor
   already calls.
2. **The context switch** on the Next MMU. The CPC switches a slot by paging its 64K bank; the Next
   switch remaps MMU slots to the task's 8 pages. A full-64K task (not just a window) means mapping
   slots 0-5 (`#0000-#BFFF`) to the task's pages while the hypervisor's own pages are saved/restored
   — different from the CPC's "keep main RAM, page the window" dance.
3. **The file/BDOS layer** retargeted to NextZXOS (no CPC disc ROM); the `.CYB` loader → load from
   SD.
4. **Boot**: a `.NEX` that brings up the hypervisor (the CPC's COSLOAD/CYBORGOS.BIN chain → a Next
   loader).

## Plan (staged, foundation-first)

1. **Next MMU banking foundation** — ✅ DONE (2026-10-18). `src/bas/cyborgosnext/`: `bank_proof.bas`
   proves a 64K bank = 8 isolated 8K MMU pages through the window; `Banks.cls` wraps it (MapWin a
   16K bank, Probe RAM, Slots, SlotBank); `cap_proof.bas` reports **111 usable 16K banks = 27 ×
   64K slots** isolated on a 2MB Next (more than CyborgOS's 20-slot cap). All run on the `zxn`
   harness.
2. Fit it to the `Memory` class API the hypervisor uses (AllocPage, Pages, Far, Copy), so `Hyp.cls`
   can call it unchanged where possible. *(next)*
3. The context switch on the MMU; a round-robin proof (tasks switched on the interrupt, each in its
   own bank, each with its own state/text page). *(design below)*
4. The console/keyboard/BDOS service layer on Next text + keyboard.
5. The file layer on NextZXOS; the `.CYB`-equivalent loader.
6. Boot `.NEX`; fold the apps/cmds in.

## The context switch on the Next MMU (design)

The CPC switch is one atomic `out (c),c` at `#0044` that swaps the whole 64K bank; `#0046` in each
bank holds that bank's own `jp` to its receiver, so execution continues in the new bank. The Next
has no single-OUT full-64K swap — remapping takes up to 8 NextReg writes (`#50-#57`), and the code
doing them pages itself out mid-sequence. Two ways to re-seat it:

- **Fixed window layout (what the foundation uses, simplest).** Slots 0-1 + 4-7 (`#0000-#3FFF`,
  `#8000-#FFFF`) stay the **hypervisor + screen/text** (`#C000-#FFFF` is the Next's ULA screen +
  tilemap text already); slots 2-3 (`#4000-#7FFF`) are the **window** a task's bank is mapped into.
  Small tasks run from the window; the hypervisor never pages itself out. This is cooperative and
  bounded to 16K-at-a-time task code, but needs no switch-glue trick. Good for services and the
  command line.
- **Full-bank tasks (CP/M-style, the real goal).** A task is `#0000-#DFFF` (seven 8K pages = **56K**;
  only `#E000-#FFFF` is the system/tilemap region). The switch is **two-stage** (Julian's): enable
  the one 8K page holding the task's receiver, `jp` into it, and from there the receiver enables the
  other 48K. Per-task, like the CPC's `#0046` landing — details in "The Next re-seating" below.

**Task size note:** a full-bank task is **56K** (`#0000-#DFFF`), not the CPC's 64K, because
`#E000-#FFFF` is the tilemap/system region. CP/M's ~61K TPA shrinks to ~55K. Record as a
compatibility delta.

### The CPC switch mechanism, exactly (from `Hyp.cls`)

Every task bank and main RAM hold the **same** switch glue at the same low addresses:
- `#0000 jp WBOOT`, `#0005 jp STUB` (BDOS entry), `#0038 jp` the interrupt save.
- `#0044 out (c), c` — the gate-array bank flip (B = the `#7Fxx` port, C = the bank value).
- `#0046 jp` the landing: `ld sp, (#FFFE) : ret`.

`Run(setting)` preloads BC with the port+bank, jumps to `#0044`; the `out (c),c` flips the whole 64K
in one instruction, and because `#0040-#0048` is identical on both sides, the **next** byte executed
is `#0046` *in the new bank*, which loads that side's SP from its own `#FFFE` and `ret`s into it.
**Only SP changes** — A, DE, HL pass straight through as the far-call message. A task runs until it
calls BDOS (`call 5` → `#0005` → `STUB` at `#EF00`, a far call back: `Run` returns 1, Fn = C, Arg =
DE; the next `Run` answers with `Reply`'s A/HL) or an interrupt stops it (`Run` returns 0). The
per-slot text page is at `BUF #F700`; stubs at `STUB #EF00`; the slot's next key at `KEY #F681`.

### The Next re-seating, exactly (Julian's two-stage switch)

The Next has no one-instruction 64K flip — remapping takes several NextReg writes, and the code
doing them pages itself out when it rewrites its own slot. The CPC solves "continue in the new bank"
with the atomic `out (c),c` landing at `#0046`; the Next does it **in two stages — enable one 8K
page, jump into it, then from there enable the rest:**

1. **Enable the receiver 16K (two 8K blocks).** The natural Next unit is the 16K bank = two 8K MMU
   pages (both window slots, `#52`+`#53`) — the same two blocks `MapWin` enables. Each task bank has
   its **receiver** (the landing code) in its first 16K; the hypervisor maps **those two 8K blocks**
   into their slots (two NextReg writes), then `jp` to the receiver — now executing the new task's
   **own** 16K.
2. **The receiver enables the rest.** Running from the just-mapped receiver 16K (never paged out,
   because it is where execution is), the receiver maps the task's **remaining 8K pages** into their
   slots, loads the task's SP, and jumps into the task proper.

That is the whole trick: you never remap the slot you are executing from until you no longer need it.
It keeps the receiver **per-task** (the CPC's per-bank `#0046` idea), not in a shared system region.

Layout this implies:
- **A task is 56K** (`#0000-#DFFF`, MMU slots 0-6, seven 8K pages) — not 48K. Only **slot 7**
  (`#E000-#FFFF`) is system: the tilemap (`#E000-#E9FF`), tiles (`#EC00-#F3FF`), and the switch /
  stubs / hypervisor stack in `#F400-#FFFF`. (Text is the tilemap; the ULA screen isn't used, so
  `#C000-#DFFF` is task RAM.) The receiver page is one of the seven task pages — map it first.
- **Per-task SP** lives wherever the receiver can reach it (the task's own bank, or the slot table) —
  the CPC's `#FFFE` is in slot 7 (system) on the Next, so SP moves off `#FFFE`.
- **The BDOS stub** (`#0005 jp STUB`) and `BUF` (the text page) move out of the CPC's `#EF00`/`#F700`
  (which collide with the Next tilemap/tiles) to fit the slot-7 system map above.
- **Interrupts** still stop a task and return to the hypervisor; the IM 1 handler at `#0038` lives in
  a task page (slot 0) and re-asserts the hypervisor's map on the way back — the zxn platform already
  re-asserts `ntc_zxsel` from the handler, extended to the task's slots.

**Net:** the switch ports as the CPC mechanism re-seated — `out (c),c` + `#0046` becomes *enable the
receiver 16K (two 8K blocks) → jp → receiver enables the rest*. Task size is **56K**. No new NTC core
support — `Hyp.cls` asm + the Next memory-map constants.

## Proven so far (2026-10-18, on the `zxn` harness)

`src/bas/cyborgosnext/`:
- `Banks.cls` — the banking + allocation API the hypervisor needs: `MapWin` a 16K bank into
  `#4000-#7FFF`; `Probe` RAM; `Banks`/`Slots`/`SlotBank`; `Init`/`Alloc`/`Free` (a 64K-slot free
  list); `Copy` (cross-bank byte copy through a resident buffer, the way the hypervisor moves data
  between slots — cf. KEYMAN's SlotRead/SlotWrite). NextReg via ports `#243B`/`#253B`.
- `bank_proof.bas` — a 64K bank = 8 isolated 8K MMU pages through the window. **BANKING OK.**
- `cap_proof.bas` — **111 usable 16K banks = 27 × 64K slots**, all isolated (2MB Next).
- `sched_proof.bas` — round-robin over 3 tasks, each state in its own bank; counters advance
  independently (4 / 8 / 12 over 4 passes). The scheduler loop + per-task banked state proven.
- `alloc_proof.bas` — Alloc/Free (free-list reuse) and a 20-byte cross-bank Copy verified.

So **stage 1 (banking) is done and stage 2 (the Memory-style API: alloc, slots, cross-bank copy) is
substantially there.**

**Update 2026-10-20 — the context switch is now done and proven** (see "The banking and switch — as
built" at the top). The asm register/SP switch works both directions, `Hyp.cls`/`Main.bas` are
folded onto this base, and it compiles 0 errors / boots to `1>`. The real remainder now: the
`ntc_lib_<platform>.asm` split (platform dependence not separated yet), RAM disc Z: (cd/dir),
terminal swapping, multiple concurrent tasks + scheduler, and in-task interrupt preemption.

## What breaks on compile (the inventory — `cli.js Main.bas Hyp.cls Ent.cls Hot.cls --platform=zxn`)

**Closed as of 2026-10-20 — the port now compiles 0 errors on both platforms.** The inventory below
is the record of what the 7 blockers were; each was resolved by the zxn banking branches
(`mem_se_out`, `mem_jbc`, the probe) and the `ntc_plat_rmr`/`#If` guards. (Those branches still sit
inside `ntc_lib.asm` — the platform split that moves them out is still pending.)

Only **7 errors** — the port's compile-blockers were concentrated in the banking layer and one CPC
routine, not spread through the hypervisor:

1. `Option Memory CPCExpansion is for the CPC platforms, not zxn` — needs a **zxn banking scheme**
   (the Next-MMU equivalent). Either add it to the core `Memory` class or teach `Option Memory` a
   `zxn`/`NextExpansion` scheme.
2. `Memory.Banks` / `Memory.AllocBank` / `Memory.BankPage` **unknown on zxn** — the banking API
   `Hyp.cls`/`Main.bas` call. These are exactly what `cyborgosnext/Banks.cls` already does:
   - CPC `Banks()` = number of 64K banks; `AllocBank()` = allocate one; `BankPage(bank,n) =
     4*bank-2+n` (a CPC 64K bank is 4 × 16K pages). On the Next a 64K slot is 4 × 16K banks too, so
     the same shape holds — `Banks.cls`'s `Slots`/`SlotBank`/`Alloc` are the Next versions.
   - **Path:** add `Banks`/`AllocBank`/`BankPage` (+ the `SelectPage`/`Far`/`Copy`/`ReadByte…` the
     hypervisor uses) to the **zxn `Memory` class**, presenting **16K "pages"** (each = two Next 8K
     MMU pages) so the CPC's 16K-page abstraction holds and the window maps via `zxn_sel`. This is
     the "fit to the Memory API" stage, done as a real NTC feature (`lib/zxn/Memory.cls` currently
     Small-only).
3. `not in library: ntc_plat_rmr` — the CPC gate-array **ROM/mode byte reader** (`#8x`), used by the
   hypervisor's asm to save/restore the mode/ROM state around a bank switch. The Next has no gate
   array; provide a zxn `ntc_plat_rmr` stub (return the Next's equivalent, or make the two Hyp.cls
   asm sites that use it `#If`-guarded for zxn).

Everything else (the ~20 warnings) is benign: `Option RomEnable` is a no-op on zxn, and the
unchecked `Copy`/`SelectPage` results are style warnings.

**So the critical path to a compiling Next CyborgOS is small and known:** (1) a zxn banking `Memory`
scheme presenting 16K pages over the Next MMU (the `Banks.cls` model, promoted into `lib/zxn/`), (2)
an `ntc_plat_rmr` stub, (3) retarget `Option Memory CPCExpansion` → the zxn scheme. *Compiling* is
not *running* — the switch asm (above), the BDOS/console/file layer and boot still need the Next
re-seating — but the banking wall, the thing that looked biggest, is essentially down.

## Generalizing: porting to any Z80 target (MSX and beyond)

The value of the inventory above is that it is the **same for every target** — only the mechanism
per layer changes. What is **portable, untouched** on any Z80 machine: NTC BASIC itself, the whole
hypervisor *logic* (`Hyp.cls`/`Main.bas` minus the hardware pokes), and **all the apps** (ying, yang,
mon, mon2, rvdu, rat, pluto) — they use abstractions, not hardware (mouse aside, now switchable). A
port is: re-seat these layers, leave everything else.

| Layer | CPC (source) | ZX Spectrum Next | MSX (sketch) |
|---|---|---|---|
| **Banking** | gate array `#7Fxx`, 16K pages | 8K MMU (`#50-#57`), two 8K = a 16K page | **memory mapper** ports `#FC-#FF`, native 16K pages into the 4 slots — *closest to the CPC model, easiest* |
| **Display / text** | CRTC `#BCxx` + firmware SCR | tilemap 80×32 (NextReg) | **VDP** (V9938/V9958) text mode via ports `#98-#9B`, VRAM |
| **Keyboard** | PPI matrix (platform) | `#xxFE` (platform) | PPI `#A9`/`#AA` / BIOS (platform) |
| **Files** | AMSDOS/UniDOS ROMs, CAS pack | NextZXOS/esxDOS (SD) | MSX-DOS / disk BIOS |
| **Clock / IRQ** | `KL TIME PLEASE` 300 Hz | 50 Hz frame / Next counter | VDP 50/60 Hz interrupt, optional RTC |
| **Mouse** | Amiga card `#F991/4/5` (now off) | Kempston `#FADF/FBDF/FFDF` | general-purpose (joystick) port via the PSG |
| **Network** | M4 WiFi `#FE00/#FC00` | Next WiFi (ESP/UART) | cartridge-specific / none |

The per-target work is always: **banking first** (everything depends on it), then **display +
files + clock** for a running system, then mouse/network as add-ons. For NTC specifically the
banking is the `mem_*` platform-asm routines (`asm/ntc_plat_<target>.asm`) behind the standard
`Memory` class — so a new target that fills in `mem_*` (16K pages over its mapper) and a text/file
back-end gets CyborgOS largely for free. MSX is notably the least work for banking: its memory
mapper is already 16K-paged like the CPC's.

## Install / boot on the Next

**Mechanism (already proven).** An NTC `zxn` build produces a `NAME.NEX` (SAVENEX). NextZXOS loads a
`.NEX` straight off the SD card and runs it — the start stub turns off the NMI buttons and DivMMC
auto-paging, sets 28 MHz + IM 1, maps the MMU slots, and jumps to the program. So *any* zxn program,
including the foundation proofs in `cyborgosnext/`, installs by **copying its `.NEX` to the SD and
running it** (the NextZXOS Browser → select it, the `.nex` dot-command, or autoboot). No installer
is needed to boot; `tools/sdinstall` lays the command and help files out on the card (below).

**CyborgOS on the Next (the target shape):**
- `CYBORGOS.NEX` — the hypervisor (`Main.bas`+`Hyp.cls` built for zxn), carrying its core banks. Put
  it in a folder on the SD, e.g. `/CYBORGOS/`.
- The **apps and commands** (the `.CYB` equivalents — MON, YING, PS, DIR, …) as ordinary **files in
  that SD folder**, loaded on demand through the NextZXOS file layer (this replaces the CPC's
  IDE-drive `.CYB` loading).
- **Run / autoboot:** launch `CYBORGOS.NEX` from the NextZXOS Browser, or have the Next autostart it
  (NextZXOS `autoexec.bas`, or a per-folder autostart) so the machine boots straight into CyborgOS.

**Vs the CPC install:** the CPC chain was `COSLOAD.BIN` loading `CYBORGOS.Z1…` + `CYBORGOS.BIN` from
an IDE drive (cos-disk1/2/3, each with `INSTALL.BAS`, `FILES.DIR`). The Next collapses that to **one
`.NEX` + an SD folder of app files** — NextZXOS does what COSLOAD did, so there is no custom loader
to port.

**Status (2026-10-21):** done. The commands on the Next are the same `.CYB` files as the CPC's
(the cpm build with its AMSDOS header); the NEX's archive and the card carry them as they are
and the drivers leave the header out on open, as AMSDOS does - so the CPC's own set, installed
from its discs, runs on the Next (except FLOPPY). A plain `.COM` runs as well. `CYBORGOS.NEX` boots (stage 6), the SD card is C: (stage 5, item
13). The layout on the card is the CPC installer's - `CYBORGOS/`, `CYBORGOS/C/`, `CYBORGOS/HELP/`
- written by `tools/sdinstall` (sdinstall.c: a FAT12/16/32 writer for an image with an MBR or a
bare volume, with a CPCEMU .DSK reader so the CPC's own discs install from the PC exactly as
INSTALL.BAS's DATA list says; `dist.sh` for the Next's build). README.md "Getting it onto a
Next". The paragraph below is the plan as it was: The `.NEX` packaging is free (every zxn build makes one); what it waits on is the hypervisor
*compiling* on zxn (the `mem_*` banking + display/file re-seat) so there is a `CYBORGOS.NEX` to copy,
and the command/app loader retargeting to NextZXOS file calls.

## Prior art

**SymbOS** already runs its banked, pre-emptive multitasking on the ZX Spectrum Next (as well as the
CPC and MSX). That is the proof the approach is **tractable, not research** — banked tasks + an MMU
context switch + a message/syscall layer are a solved shape on this hardware. The two-stage MMU
switch (enable the receiver 16K = two 8K blocks, jump, enable the rest) is established technique, not a novel
risk. Treat the CyborgOS-Next port as an engineering port of a known pattern, not an open problem.

## The banking port, scoped exactly (what "close the 7 errors" means)

`Memory.cls` is a **thin wrapper**: every method (`Pages`, `AllocPage`, `SelectPage`, `Copy`,
`Banks`, `AllocBank`, `ReadByte`…) is a few lines of inline asm that put the args in
`mem_a1`/`mem_a2`/`mem_a3` and `jp mem_go`/`mem_go0`/`mem_go4` to a routine pointer (`mem_pages`,
`mem_allocpage`, `mem_selpage`, `mem_copy`, `mem_bankcount`, `mem_allocbank`, …). **The real memory
manager — the page lists, the RAM probe, the window switch, Copy, the 64K-bank logic — lives in the
platform asm** (`asm/ntc_plat_cpc.asm`, the `mem_*` routines), not in the `.cls`.

So the banking port is: **re-implement the `mem_*` routines in `asm/ntc_plat_zxn.asm`**, the CPC
gate-array memory manager re-seated on the Next MMU (the window switch becomes NextReg `#52`/`#53`
writes, the probe becomes a Next RAM probe, a 16K "page" = two 8K MMU pages). The `.cls` wrapper is
then essentially the CPC one. The 19 methods CyborgOS uses (`WriteByte`, `Copy`, `WriteWord`,
`ReadByte`, `SelectPage`, `AllocPage`, `BankPage`, `ReadWord`, `FreePage`, `Pages`, `Banks`,
`Top`, `TableEnd`, `RamSize`, `PageType`, `Map`, `FreePages`, `AllocBank`, + the Type consts) are
the surface to cover. Plus the `ntc_plat_rmr` stub.

**`src/bas/cyborgosnext/Banks.cls` is the proven BASIC prototype of this `mem_*` logic** — the
window map, the probe, the slot/bank allocation and the cross-bank copy all work there on the real
Next target. Porting it to the platform-asm `mem_*` contract is mechanical but delicate (register
conventions, the `mem_go`/`mem_a1`/`mem_res` marshalling) and wants runtime testing against a
running hypervisor, which is why it is the next focused job rather than a session-tail rush.

## CPC-specific hardware inventory (searched — every `out`/`in` and firmware call)

Inline-asm `out`/`in` lives in only `Hyp.cls` and `cmds/FLOPPY.bas`. But **port access also comes
through the `Inp()`/`Out` built-ins** (BASIC, not asm) — the apps use those for the **mouse**, so
the apps are *not* fully clean. Full picture (searched both asm `out`/`in` and the `Inp`/`Out`
built-ins): the hardware is in `Hyp.cls`, `cmds/FLOPPY.bas`, `apps/mon/Mouse.cls`, and one rat demo.
The eight CPC-specific subsystems to re-seat:

1. **Banking** — gate array `#7FC0` (`out (c),c`, the bulk of the hits) + `KL ROM SELECT`/`DESELECT`
   (`#B90F`/`#B918`). → **Next MMU** (the `mem_*` port, already scoped). Most `out (c),c` are this.
2. **Display / screen** — the **CRTC** (`#BC00`/`#BC0C`/`#BC0D`: R12/R13 screen-base, offset/scroll)
   and `TXT SET M TABLE` (`#BBAB`, the font matrices). → the Next **tilemap / Layer 2** base and
   scroll via NextReg, and the zxn font. This is "which slot's screen is shown" + double-buffer +
   scroll. (The console/display layer.)
3. **Files** — the **CAS pack** firmware (`#BC7A` CAS IN CLOSE, `#BC8C` OUT OPEN, `#BC8F` OUT CLOSE,
   `#BC92` OUT ABANDON, `#BC95` OUT CHAR) + the disc ROM. → **NextZXOS / esxDOS** file calls on SD.
   (The file layer.)
4. **Command lookup** — `KL FIND COMMAND` (`#BCD4`) finds RSX commands in background ROMs. → the
   Next has no expansion ROMs; the "run a `.CYB` by name" path stays (load from SD), the
   external-ROM-command path drops.
5. **Clock / timing** — `KL TIME PLEASE` (`#BD0D`, 300 Hz). → the Next timer (50 Hz frame count, or
   the Next's own counter). Affects the scheduler slice length and TOP's per-second stats.
6. **Network — NET M4** (`#FE00`/`#FC00`, `outi`): the CPC's M4 WiFi board (packets out, answer in
   the M4's ROM). → the Next's own WiFi (ESP via UART/NextReg) or a stubbed `NET`. A separate driver;
   not needed for first boot.
7. **Floppy — `cmds/FLOPPY.bas`** (the µPD765 FDC: `#FB7E`/`#FA7E`, `in a,(c)`, `outi`, direct sector
   writes). → the Next has no CPC FDC. **Drop it** (or rewrite for SD) — CPC-floppy-only, not a core
   dependency.
8. **Mouse — `apps/mon/Mouse.cls`** (used by MON, MON2, YING, YANG): the **dual Amiga mouse card**,
   read with `Inp()` — `#F994` X, `#F995` Y (signed deltas), `#F991` buttons (bits 4/5/6).
   **2026-10-18: the mouse reading is now commented out** in `Mouse.cls` (`Present()` returns False,
   `Poll()` is a no-op) so the apps build keyboard-only on **both CPC and Next** for now; all four
   apps still compile clean. To bring it back: uncomment the `Inp()` reads for the CPC, or add a
   Next back-end — the Next's **Kempston mouse** (`#FBDF` X, `#FFDF` Y — *absolute* 0-255 counters,
   so Poll computes the delta, `#FADF` buttons). The apps call `Mouse.Present/Poll/MoveX/MoveY/
   Buttons` and are unchanged either way. (Also: `apps/rat/GREEN.bas` reads an ADC sensor via
   `Inp(ADCDAT)` — a demo, droppable.) Other `Inp`/`Peek(&HF6xx)` in the apps read CyborgOS's own
   per-slot memory (console cols/rows, command tail), not hardware — they move with the hypervisor.

**So the port's hardware work, in order:** banking (`mem_*`, scoped) → display (CRTC → tilemap) +
files (CAS → NextZXOS) + clock (TIME → Next timer) for a running system → then NET, floppy and the
mouse (`Mouse.cls` → Kempston) are small/optional add-ons. The apps need no change beyond `Mouse.cls`
getting a Next back-end. Keyboard is already the platform's (no raw PPI reads in CyborgOS).

## Decisions / gotchas log

- *2026-10-18* — The Next's per-program environment is already CPC-shaped by NTC's zxn platform, so
  the port is **not** a from-scratch rewrite of the single-task layer; it is a re-seat of the
  **banking + scheduler + syscall** layers. Start at banking because everything else depends on it.
- *2026-10-18* — `zxn_sel` maps a **16K** bank to the window (two 8K MMU pages). CyborgOS banks are
  64K; through a 16K window that is four window-loads, same as the CPC pages a 64K bank in 16K
  pieces. The Next's 8K granularity also allows finer maps if wanted later.
- *2026-10-18* — Keep NextReg writes through ports `#243B`/`#253B` (not Z80N `nextreg`) so the build
  stays assembler- and harness-agnostic, matching the rest of the zxn platform.
- *2026-10-18* — **Memory abstraction decision: 16K pages** (each = two Next 8K MMU pages), not
  native 8K. This keeps `BankPage(bank,n)=4*bank-2+n` and the whole CPC 16K-page model, so `Hyp.cls`
  compiles unchanged — a *port*, not a redesign. 8K-native would be a different OS.
- *2026-10-18* — **Context switch** is the CPC's `out (c),c`/`#0046` re-seated as Julian's two-stage
  MMU switch: enable the receiver 16K (two 8K blocks), `jp` in, then the receiver enables the rest.
  Task = 56K (`#0000-#DFFF`); slot 7 is the tilemap/system region.
- *2026-10-18* — **SymbOS** already runs banked pre-emptive multitasking on the Next (and CPC/MSX):
  this port is a known pattern, not research. Build it as engineering, not an open problem.
