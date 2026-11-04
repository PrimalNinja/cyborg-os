# CyborgOS - technical design (the system as it is, written from the code, 2026-11-01)

This is the current design. cyborgos.md (the October plan and its kernel-split revisions) and
cyborgos-decisions.md (the decisions as they were made) are history. Each section names the source it
describes, so a bug hunt starts from here. Components are numbered in components.md.

## 1. The shape

```
   +------------------------------------------------------------------+
   |  C0 - the hypervisor, in main RAM (components 1-6, one a machine) |
   |  memory manager, banks, screen, keys, discs, firmware, network    |
   |  runs each slot for a slice; answers the BDOS calls that are its  |
   +---------------------------+--------------------------------------+
                               | BDOS 132: a block at KB (#EE00)
   +---------------------------+--------------------------------------+
   |  the kernel (7) - KERNEL.CYB, one file for every machine          |
   |  in a bank of its own: scheduler, command line, TOP, slot states, |
   |  LANG, AUTOEXEC, the type queue; the BDOS calls that are its      |
   +---------------------------+--------------------------------------+
                               | each slot: a 64K bank, a CP/M-shaped TPA
   +------------+------------+-+----------+-------------------------+
   | slot 1     | slot 2     | ...        | slot n (MAXS = 20)      |
   | a program  | a program  |            | or a command line       |
   | (.CYB)     | or closed  |            |                         |
   +------------+------------+------------+-------------------------+
```

- C0 is an NTC program for the machine (cpcfw on the CPC, zxn on the Next, msxdos on the MSX; C,
  not NTC, on the vCPC). It owns the hardware. It never runs a program's code itself: it switches a
  slot's bank in, gives it a slice, and takes the bank out.
- The kernel is an NTC program for the cyborgos platform (a CP/M program with CybSys). It has no
  hardware: everything it needs it asks C0 for, one call at a time (section 4). It is the same
  KERNEL.CYB on every machine; what differs (key names, TOP's keys, the Next's console) comes from
  BOOT's host word.
- A slot is a 64K bank with a CP/M-shaped layout (section 3). A program is a .CYB file (NTC's
  cyborgos platform, or any CP/M .COM that uses the BDOS only) loaded at #0100.

Sources: src/bas/cyborgosc2/Main.bas and Hyp.cls (CPC), src/bas/cyborgos/ (Next),
src/bas/cyborgosmsx/ (MSX), src/bas/cyborgosc0/ (CPC, the C0 build), cyborg-os-vcpc/src/vcpc.c (vCPC),
src/bas/cyborgoskernel/KERNEL.bas (the kernel).

## 2. Memory, a machine at a time (MEM.bas prints these; the C0 sources define them)

### 2.1 CPC 320K and up (component 1)

```
   main RAM (C0)                        a bank (a slot, the kernel's, a store, a RAM disc)
   #0000-#003F  firmware restarts       #0000-#00FF  page zero: C0's stubs (the BDOS route at #0005,
   #0040-#3FFF  C0 (code)                            the slot's own route at #0008)
   #4000-#7FFF  the screen; the window  #0100-TPA    the program (its TPA top: SLOT op 37)
                (a bank's 16K page)     ...
   #8000-te     C0's data, arrays,      #EE00-#EEFF  KB: the kernel's call block (the kernel's bank)
                the memory tables       #EF00-#F5FF  the stubs (sb_rest, sb_far: the slot's resume
   te-tp        free                                 points; the far-call stub)
   tp-#BFFF     firmware and ROMs       #F600-#F6FF  the console's state: KEY #F681, CCOLS #F687,
   #C000-#FFFF  C0 (code)                            CROWS #F688, CMODE #F689, CSTRIP #F68A,
                                                     LNLEN #F68F, LNBUF #F690 (70 on the CPC,
                                                     65 on the Next), CINK #F6E5
                                        #F700-#FEFF  the console's text page (2K)
                                        #FF00-#FFFF  the switch-back code, SP save, the key
```

The banks are the 64K units of the expansion (4 pages of 16K a bank). The RAM probe counts them;
the memory tables (3 bytes a page) live above the window and must fit there (NTC's mem_tb_fit:
buglist, runtime 9/17). COSLOAD.ASM (55) loads C0 and the kernel and puts Z's pages at the top of
memory: 576K is 3 slots and Z, 1024K 7, 4 MB up to MAXS. C0's ProbeDiscs runs before the bank loop
so a surviving RAM disc's pages are not given to slots.

### 2.2 The Next (4)

```
   #0000-#003F  restarts, the interrupt (#0038), the bank switch (#0044)
   #0040-#3FFF  C0
   #4000-#7FFF  the window (MMU slots 2, 3: a bank's 16K page); main RAM's own kept
   #8000-te     C0, its arrays, the memory tables
   te-tp        free;  tp-#BFFF the stack
   #C000-#DFFF  MMU slot 6: the boot archive read through it; Layer 2 drawn
   #E000-#FFFF  the text screen: the tilemap #E000-#E9FF (80 x 32 cells, bank 5 + #2000),
                the tiles #EC00-#F3FF (256 x 8 bytes, bank 5 + #2C00); the boot stub
```

The console is the tilemap: 80 columns, 32 rows of cells, of which the console uses 24 and the
strip (buglist: the 40 x 32 of the first port was cut to the CPC's rows; MODE P proposed). Files
go through esxDOS (rst 8, the 48K ROM paged in). The slot keys are Caps Shift + 0 (TOP) then the
number. A bank is 4 MMU pages of 8K.

### 2.3 The MSX (5)

```
   #0000-#00FF  MSX-DOS 2's page zero       #8000-te   C0, its arrays, the memory tables
   #0100-#3FFF  C0 (CYBORGOS.COM)           te-tp      free;  tp-#BFFF the stack
   #4000-#7FFF  the window (the mapper's    #C000-#FFFF the interrupt stub; MSX-DOS 2
                16K segments)
```

A bank is 4 mapper segments of 16K from MSX-DOS 2's allocator. The console is the V9938 text
screen or, with a V9990, its own. No network driver yet (GR8NET: buglist). The Shift read for
AUTOEXEC's skip is the PPI (row 6 bit 0): Hyp.ShiftDown.

### 2.4 The vCPC (6)

A C program (Windows, Linux, Mac). C0 is the host's own code: there is no main-RAM Z80 program,
the kernel and the slots run on an emulated Z80 in the banks. 4 MB of banks (260 pages). The
console is the terminal (UTF-8 out; keys as a Unix terminal sends them, Control + T then a number
for a slot). The network is the host's sockets. No RAM discs yet (BDOS 130 unanswered: buglist).

### 2.5 The CPC flat (2) and 128K (3)

The C0 build has one bank: the kernel runs in it with the slots' programs (no kernel bank). The
128K build is the first and is not built any more (buglist).

## 3. A slot

A slot is a 64K bank (section 2.1's right-hand column). Its states are the kernel's st(): 0 closed,
1 at its command line, 2 running a program, 3 paused (PAUSE). The kernel keeps, a slot: its state,
the key handed to it (kq), its BDOS answer (ra), since when it waits for a key (wk), its drive, its
program's name (in its bank). C0 keeps: its DMA, its open files, its claims, its ports, its RAM
setting (sg: which bank), its stubs' resume points.

The console is in the bank: the state bytes at #F681-#F6FF and the text page at #F700-#FEFF. C0
draws the slot in front from its page (Con, Scr); the others' pages change unseen; FG brings one to
the front and redraws it from its page. The strip (row 0) is CSTRIP, drawn by C0 (the slot number,
the network cell, the R of a Russian layout).

## 4. The kernel's calls to C0 (KERNEL.bas's header; C0's Serve in each Main.bas)

The block at KB (#EE00 in the kernel's bank, which C0 reads through its window):

```
   KB + 0    the op                 KB + 2 .. KB + 9     up to 4 words of arguments
   KB + 16   the answer r0          KB + 18 .. KB + 29   r1 - r6
   KB + 30   C0's clock (Ticks: 300 a second on the CPC, 50 on the Next), with every answer
   KB + 32   up to 224 bytes of data either way
```

The ops (KOp): 1-4 RB / WB / RW / WW a slot's byte or word; 5 TOSLOT, 6 FROMSLOT (n bytes); 7 CON
(data to a slot's console; f: it is in front), 8 CONX (cursor flash, page drawn, scrollback), 9 SCR,
10 INKS (CPC), 11 SAY (straight onto the screen: TOP); 12 RUN t a k n (the slot runs up to n slices;
r0 0 slices used, 1 a call for the kernel, 2 C0 answered and the turn ends, 3 the slot sleeps a
tick; r3 characters, r4 its key, r5 / r6 runs); 13 FILE (Hyp.FileCall: the slot's DMA and drive),
14 DRIVE, 15 SHUT (files and claims), 16 SVC (BDOS 131 ops in the service page), 17 RAMDISC (BDOS
130), 18 STORE, 19 INSTALL (the bank image into a slot), 20 MEMINFO, 21 MEMMAP, 22 HOT (the system
key; else a key, Control, the system key held), 23 FRAME, 24 SETST, 25 SETFRONT, 26 BOOT (slots,
boot drive, host 0 CPC / 1 Next / 2 MSX / 3 vCPC, make Z, a line's most, NOSYSZ), 27 QUIT, 28 / 29
DVGET / DVSET, 30 LAUNCH (a slot's first stack and DMA), 31 OWNDRIVE, 32 INKEY, 33 BOOTDONE (the
boot drive from now on; r1 Shift held: AUTOEXEC skipped), 34 STATS, 35 CONO, 36 SG (the kernel runs
the slot itself: KRun), 37 SLOT (DMA, a file open, the build's stamp; DUMP / REVIVE's bank
ownership), 38 LANG (0 English, 1 Russian, 2 Spanish).

## 5. The programs' calls (BDOS from a slot)

A program calls the BDOS at #0005 as under CP/M. Page zero's route (#0008) sends the kernel's own
functions to the kernel and the rest to C0, which answers the slot directly (CPC: the kernel runs the
slot itself under KRun and takes its interrupts under KInit). CP/M functions 1-40 are the console,
the DMA (26), the drive (14, 24) and files (15-36: Hyp.FileCall, through UniDOS folders as drives).
Two are CyborgOS's own:

- BDOS 130: the RAM discs' driver (RAMDISC.CYB; a disc as drive A-P from pages).
- BDOS 131: the hypervisor's services, a block at DE (CybSys.cls, component 8): 0 a slot's PS
  line; 1 KILL; 2 RESET (0: this slot); 3 FG; 4 WAIT; 5 PAUSE / UNPAUSE (and DUMP / REVIVE's
  state in and out); 6 TOP's table (Word(2) 1: every slot); 7 the memory; 8 32 pages of the map;
  9 MODE; 10 a slot's memory read / written (kinds 3 / 4, used by DUMP, REVIVE, RCOPY, SLOTD);
  15 a table (the claims); 16-19 Claim ...; 20 the clock, uptime, host; 28-34 the ports; 38 LANG;
  41 the Next's tile glyphs (LANG); 42 the CPC's resume points (SlotFrame); 43 the Next's font
  (LANG). The answer in A: 0 done, 1 nothing to do, 255 no such slot or not CyborgOS.

## 6. The scheduler and keys (KERNEL.bas: the main loop, KeyIn, Command, StartTask)

```
   loop:  HOT (22): the system key? a key?  -->  KeyIn: the system key chord (TOP, a slot), or
          |                                       the key to the slot in front (its command line,
          |                                       or kq for its program; language letters as
          |                                       256 + byte; Control + Space: the Russian layout)
          |  a line waiting in tq (AUTOEXEC)? --> TypeLine into slot 1's command line
          |  for each slot with st = 2, in turn: RUN (12) for up to TURNS = 3 slices
          |      r0 = 1: a call for the kernel -> Sys (section 5's BDOS 131, or the file ops)
          |      the program ended -> the "[NAME ended]" line (quiet for AUTOEXEC.CYB), st = 1
          |  TOP live (Control + ESC): TopLines, keys pick a slot
   <------+
```

A turn is up to 3 of Hyp.Run's slices (6 interrupts each on the CPC, 1/50 s). A slot waiting for a
key is passed over until it has one. A program that ends returns the slot to its command line.

Command: the line upper-cased (UpLang: the language's letters too), the built-ins (RUN n, the slot
number), else StartTask: the name tried on Z (NAME.CYB), the slot's drive, then C/ (the Next); the
header read, the program loaded at #0100, its tail at #0080, the DMA #0080, LAUNCH (30).

## 7. Boot (Main.bas's start; the kernel's start)

```
   COSLOAD (CPC) / CYBORGOS.NEX (Next) / CYBORGOS.COM (MSX) / vcpc (host)
     -> C0 up: the RAM probe, the banks counted, ProbeDiscs (RAM discs that survived a reset),
        the console, the network (CPC: NET M4 later, by hand)
     -> the kernel's bank: KERNEL.CYB loaded, INSTALL (19) of the bank image, LAUNCH
     -> the kernel: BOOT (26): the slot count, the drive, the host; slot 1 opened; Z made from
        the commands (RAMDISC.CYB on the CPC, the archive on the Next) unless NOSYSZ
     -> BOOTDONE (33): the boot drive from now on; r1 says whether Shift was held
     -> AUTOEXEC: unless Shift (or --no-autoexec on the vCPC), AUTOEXEC.CYB runs in slot 1
        quietly and types the boot drive's AUTOEXEC file, a line a prompt (the type queue tq)
     -> slot 1's prompt
```

## 8. Moving and dumping a program (DUMP.bas, RCOPY.bas, SLOTD.bas, SlotFrame.cls - 11, 37-39)

A dump is a file or a network stream of the same shape:

```
   128 bytes  the header: "CYBD" + the version, the state (hd 46-47 the TPA top, hd 48-49 the
              trimmed length), the program's name, its drive's path, the build's stamp, hd 52
              the frame kind (1 interrupt, 2 call), hd 53 PC or the return, hd 55 SP, hd 57-76
              AF BC DE HL AF' BC' DE' HL' IX IY (SlotFrame.Canon), hd 77 1: the console follows
   n bytes    the program: #0100 to #0100 + the trimmed length (trailing zeros cut, 2K at a time)
   2048       the console's text page (#F700)         } when hd 77 = 1 (2026-11-01 on)
   11         the console's state (8 at #F682) and colours (3 at #F6E5)  }
```

DUMP pauses the slot, reads its memory through op 10, writes the file, and lets it go on. REVIVE
loads into a closed slot or one at its command line, clears the rest of the TPA, rebuilds the frame
the receiving machine's way (SlotFrame.Native: the CPC's sb_rest / sb_far, the vCPC's call byte at
#EF48), puts the console back, and leaves it paused. RMOVE / RCOPY send the same stream to SLOTD on
another machine (a request line first: the slot wanted, -f for another platform); SLOTD takes it
into a slot and replies OK. A slot with a file, a claim, a port or a socket open is refused; a slot
stopped by neither of the two frame shapes is refused with "try again". The zero page and everything
above the TPA are the receiver's own.

## 9. The network (Http.cls 10, NET 40-42, Hyp.cls's net_)

The CPC's M4 (NET M4 turns it on), the Next's ESP, the vCPC's host sockets; the MSX none yet. A
program's ports are BDOS 131 ops 28-34 (PortOpen, a port's message, PortName). Http.cls does
HTTP/1.0 GET and POST with Connection: close, a 10 s idle timeout, the answer into the caller's
buffer (a longer answer is cut: buglist). The strip's network cell shows the state.

## 10. Languages (LANG 43, the kernel, Hyp.cls's HFONT2 / Tiles, lang/*.FNR 61)

LANG EN / RU / ES, kept by the kernel (op 38 to C0). Characters 128-255 travel from the keys as
256 + byte. The CPC builds the glyphs for 160-255 from its ROM font at run time following a recipe
file (KOI8.FNR, LATIN1.FNR); the Next writes them into tiles 160-255 (Tiles: MMU slot 2 mapped to
bank 5's upper page, interrupts off, the flag kept in a byte - SP is the thread). The vCPC shows the
code page as UTF-8. HELP tries NAME.HRU / NAME.HES before NAME.HLP. The command line upper-cases the
language's letters (UpLang). Control + Space switches the Russian layout (R in the strip).

## 11. The tests (62-66)

cosregress (the CPC on the Z80 core, 50 screens against references), msxregress (28), vcpctest (15),
nextkeys and nextrun (the Next in ZEsarUX), espsim (the M4 simulated for the network tests). All
four machines before a build. What each leaves out is in buglist.md under 62-66.
