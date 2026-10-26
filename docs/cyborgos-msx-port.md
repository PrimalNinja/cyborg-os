# Porting CyborgOS to the MSX — porting notes

Living notes for the CyborgOS → MSX port, kept as the work goes (as `cyborgos-next-port.md` is for
the Next). Started 2026-10-27.

## The target

MSX2 or later (MSX2+, turbo R) under **MSX-DOS 2 or Nextor**, with a **memory mapper**: CyborgOS
needs 320K of it free (4 banks of 64K: the hypervisor's pages, the kernel, two slots). The machines
this was made for: Sanyo Wavy MSX2+ (PHC-70FD with a floppy, PHC-35J without) with a **GR8NET**
(a 512K mapper, Nextor on its microSD, a W5100 with TCP/IP UNAPI). MSX1 is out: no mapper, no
80 columns.

C0 is `CYBORGOS.COM`, an MSX-DOS 2 program (NTC's `msxdos` platform: the cpm platform's run time
plus the MSX's frame interrupt and the mapper as the CPC's RAM settings). The kernel is the same
`KERNEL.CYB` the CPC and the Next run, as are the commands and the apps - a slot is the same 64K
bank from #0100 on every machine. The model is the Next's: C0 runs the slots (host 3: the kernel
treats it as the Next's model, with the CPC's keys and texts).

Sources: `src/bas/cyborgosmsx/` (Main.bas, Hyp.cls, Ent.cls, Hot.cls - started as a copy of the
Next's `src/bas/cyborgos/`; `IFDEF NTC_MSXDOS` / `#If NTC_MSXDOS` is the MSX's code). Build:
`build/msx/CYBORGOS/` (the builder's `CYBORGOS.COM` project and `msx/CYBORGOS` folder). Tests:
`node tools/regress/msxregress.js` (18 tests in NTC's `msxrun.py`, refs in `tools/regress/ref/msx/`).

## The memory

- **The mapper.** MSX-DOS 2's mapper support (EXTBIO #FFCA, D = 4, E = 2: its jump table) gives the
  segments: NTC's `ntc_lib_msx.asm` takes every free user segment of the primary mapper at the start
  (ALL_SEG) - MSX-DOS 2 frees them when the program ends - four a 64K "bank", looked up by
  `msx_segs` (a bank's four needn't be next to each other). A RAM setting is shaped as the CPC's
  (`B = 1`, `C = the bank's ordinal * 8 + 4 + its page`, + 2 the whole bank), so the CPC's setting
  arithmetic works unchanged - as on the Next. 31 banks at most (C's ordinal: 0-31) - 2MB.
- **The window** is page 1 (#4000-#7FFF), changed with PUT_P1 (`msx_win`), never an out to #FD:
  MSX-DOS 2 must know what is there, as a file call can read into it.
- **C0's own pages** are MSX-DOS 2's TPA segments (3, 2, 1, 0 on most machines: GET_Pn at the
  start, `msx_tpa`). The real stack is below #C000; the interrupt stub at #C000 (NTC's msxdos
  platform); MSX-DOS 2's system area above the TPA's top.

## The slot switch

MSX-DOS 2 keeps #0038-#005B of the TPA's page 0 (its interrupt and slot code: "must not be
modified"), so the CPC's and the Next's #0044 glue can't be there on C0's side. The mapper changes
one 16K page per port, so the switch pivots on page 3, which is the slot's own in each bank:

- **Task -> C0** (`sb_hout`, at HISW #FFD0 + 25 in each bank, from the stubs' far call and
  interrupt where the others `jp #0044`): A and its carry into AF', pages 0-2 to C0's segments (out
  #FC, #FD, #FE - running in page 3, which hasn't moved), then `jp msx_recv` in C0: page 3 back
  (out #FF), AF back, C0's SP (`ntc_bk_sp`), ret to Run's `rn_back`.
- **C0 -> task** (Run): the task's page 3 segment out to #FF first - Run's code is in pages 0-2,
  but C0's stack (page 3) is gone from there on, so no push or call - ra / rclr / rhl into the
  task's SWAP (#F6D1), then `jp HISW`: `sb_hin` maps pages 0-2 and lands through `sb_land`.
- Install copies `hi_sw` (sb_hin, sb_hout: 41 bytes) into each bank and patches their immediates:
  the bank's own segments (sb_hin) and C0's (sb_hout) - `Hyp.Seg`.
- A slot's interrupt arrives at its own #0038 (`sb_int`): to C0, whose `rst #38` runs MSX-DOS 2's
  handler (the BIOS's keyboard scan, JIFFY, H.TIMI - NTC's interrupt classes, Hot.Tick).

## The screen

TEXT 2 (80 columns) set on the V9938 directly, not through the BIOS: the name table at #0000 is a
**ring of 32 rows** (2560 bytes) and **R#23** (the vertical scroll) shows 26.5 of them from the
screen's top row (`sco`: R#23 = sco * 8) - the CPC's hardware scroll again: a line feed moves R#23
on a row and clears the new last row (and the ones under the console, which come round from the
ring). The blink table is at #0A00 (out of the ring's way), the patterns at #1000 - the main ROM's
font (CGTABL, read through RDSLT at the start). Light yellow on dark blue, the CPC's colours. The
console's code is the Next's (a byte a cell: `cn_scr` gives the cell's VRAM address, `cn_glyph8`
writes the character there), the tilemap writes made VDP writes (`msx_vrow`, `msx_vwa`, `msx_vclr`,
`msx_vclrow`, `msx_vr23` in Con's block). MODE P is 64 x 26 (TEXT 2 shows 26 rows). `Vdu 1` (QUIT,
an error before the start) puts R#23 back to 0 and the BIOS's screen back (INITXT through CALSLT),
and main RAM's own page 1 back in the window.

## The keys

CPC-style, as asked: **CTRL + 1-9, 0** a slot (twice with more than 10: 11-20), **CTRL + ESC** TOP.
Hot reads the keyboard matrix through the PPI (#AA the row, #A9 the keys: row 6 bit 1 CTRL, rows 0-1
the digits, row 7 bit 2 ESC). The typed keys come from MSX-DOS 2's console (the BIOS's buffer), as
NTC's `Inkey` gives them.

## The files

MSX-DOS 2's handle calls replace the Next's esxDOS layer (`sd_*` in Info's block, the hooks
FileCall's page code calls): #43 open, #44 create, #45 close, #48 read, #49 write, #4A seek, #4D
delete, #4E rename, #40 / #41 the search (the cache: DIR, CP/M's 17 / 18), #1B the free space (DRIVE),
#19 the current drive, #44 with the folder attribute (MKDIR). Every drive letter A-H is MSX-DOS 2's
own ("A:" in FL_MAP: a path, so the hooks take every call); `CD folder` binds a free letter (I on)
to a folder, as UniDOS does. "/" goes to the DOS as "\". An AMSDOS header (a .CYB's) is read past,
as everywhere. The boot drive is the current drive (FileCall 99's answer): KERNEL.CYB, the commands
and the slots' drive. The boot archive (the Next's A:) isn't there: `fl_arc_pg` gives an empty
directory.

No Z: is made at boot: copying the ~100K CYBORGOS.Z names into a RAM disc took over half a minute
in the harness (a record at a time through the file calls and the RAM disc driver), and an SD card
is as quick. `RAMDISC Z SYSTEM A` makes it by hand.

## The clock

The kernel's clock is 300 a second (the CPC's). `Hyp.T300` / `msx_t300`: JIFFY * 6 (50 Hz) or * 5
(60 Hz - R#9's PAL bit), **plus a tick for each look within the frame** (up to the frame's last):
the kernel puts a slot to sleep "until the clock moves on" (a key not there yet, a port's "not
yet"), and with the clock moving only at the frame a sleeping slot lost a whole frame each time -
the boot's RAMDISC took a frame a record. KOP 23 ("nothing to run: wait a frame") doesn't wait on
the MSX for the same reason.

## Measured (the harness, 3.58 MHz, 576K)

| | MSX | CPC 320K (05:02 build) |
|---|---|---|
| LINES | 1779 ticks (5.9 s) | 5066 |
| DIR | 1268 | 1958 |
| PS | 197 | 378 |

(The MSX's screen is a VDP write a character; the CPC's 8 bytes of bitmap. The harness's DOS is
instant - a real disc or card isn't.)

## Not there yet

- **A run on a real MSX, or in openMSX.** Only the harness so far (`msxrun.py`: the mapper, TEXT 2
  with R#23, MSX-DOS 2's handle calls on a folder, the PPI, RDSLT / CALSLT stand-ins). openMSX needs
  the machine's system ROMs (the Wavy's) and a Nextor ROM.
- **The network**: the GR8NET's TCP/IP UNAPI behind NET / IPCONFIG / NETSTAT and Http.cls (ops 20-27
  as the M4 and the ESP give them). NET says "no network" for now (`es_net`: 20/0 off, the rest
  an error).
- **CTRL + STOP**: the BIOS flags it and MSX-DOS 2 may abort the program at its next console call
  (all of CyborgOS with it). An abort routine (_DEFAB, #63) or keeping off the console calls.
- **GUI** (the CPC's and the Next's only), **FLOPPY** (AMSDOS's), **Inks** (a slot's own colours: R#7
  could do it), **KEYREP** (no command line: CyborgOS's at #BE80 is the CPC's).
- The help texts still speak of UniDOS and the CPC's drives.
- **Speed**: each window change is MSX-DOS 2's PUT_P1 (through its jump table); the Z: copy at
  3K a second.
