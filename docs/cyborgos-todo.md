# CyborgOS - todo

What has been done and what is next for CyborgOS (see [cyborgos-readme.md](cyborgos-readme.md)).
Items for NTC BASIC itself, the compiler CyborgOS is built with, are in [todo.md](todo.md).
Newest first. The 128K version is frozen (changed only when asked for); new work is the 320K
version.

---

## next (2026-10-27: docs/cyborgos-hardware.md has the plan)
- The claim tags (one list, C0 claiming what it drives), a TIME command (RTC, Nova, M4, NTP; the
  MSX's clock), a Net4CPC / GR8NET W5100 driver, optional listening (off by default), serial,
  CPC-CPLink with the Pi as a coprocessor (plugins, slots on the Pi; the Next's Pi Zero), speech,
  NOVA and MF2 utilities.
- **Pi volumes** (Julian, 2026-10-27; docs/cyborgos-pi.md 5a - the Pi side done: pi/svc/disk.js, 26 tests; the CPC side to do): `/home/cyborgos/<volume>/` on the Pi,
  a volumes.json there keeping them and their mounts (persisting); PIVOLUME on the CPC (list, NEW,
  DROP, MOUNT name X, UNMOUNT X) as RAMDISC is; the Pi announcing the mounted ones at the start, C0
  binding their letters; 4 at most announced (mounted automatically) at the start - more by hand -
  letters in A-P for CP/M programs. Random access as
  the RAM discs have (the Pi's file system, not AMSDOS): a drive driver beside RAMDISC's, its record
  calls as REQs (READ h rec, WRITE h rec + 128 bytes).
- On a real M4: does it take "A:NAME" (CyborgOS's names)? 1984's M4 doesn't (tools/emu84).
- DIR on an M4 drive (its own listing: C_READDIR) - now "can't be listed", as plain AMSDOS.
- **VER** (Julian, 2026-10-29): a version in every .CYB (the cyborgos platform only, not other
  targets). A .CYB is a CP/M program (#0100, after the 128-byte AMSDOS header); it starts with a
  header: `C9` (RET: run by a plain CP/M it ends at once, cleanly - it needs CyborgOS), a header
  version byte, then that version's fields. Version 0: `C9 00`, no fields - the entry at #0102 (the
  smallest: still safe under a plain CP/M, no version). Version 1: `C9 01` + 6 BCD bytes
  YYYYMMDDnnnn (the date and that day's build number) - `C9 01 20 26 10 29 00 01`, the entry at
  #0108. CyborgOS's loader: a C9 first - the header's version picks where the entry is (0: #0102,
  1: #0108); anything else - an old .CYB, a .COM - starts at #0100 as now. NTC's cyborgos start code to emit it; the builder
  (cosbuild) stamps the date and a build counter per day. VER: CyborgOS's own (KERNEL.CYB); VER
  name: that program's, read from the file (offset 128 with the AMSDOS header, 0 without - the
  Next's plain ones), not run; shown as 2026-10-29 build 1.
- **The help pages, all of them** (Julian, 2026-10-29): every command and program its .HLP - CRUNCH,
  GUI, GUIDEMO, RVDU's KEYS, NETSTAT, IPCONFIG, M4TIME, NTPTEST, RTCTEST, SPEAK, SIDTEST, ENC, DEC,
  KEYMAN, KEYMGR, TICKER, LINES, GREEN, WATCH, ASK ... (help/ has 45; the commands are more).
- **TOP: only the slots in use** (Julian, 2026-10-29): TOP to list the active slots (not those
  shown "-"); TOP FULL all of them, as now.
- **Slot servers, a cluster** (Julian, 2026-10-29 - after SEND / SLOTD): a Docker instance the CPC
  launches (an id back) and talks to; an instance one machine or several, any up to 4MB (a slot a
  64K bank - the 4MB variants: many slots each); slots run flat out (no 50 Hz, no video), the BDOS
  answered there (console back to the CPC or a VDU screen, files in the instance, keys from the
  CPC). Then named ports across the network (PortCall to a slot on another node), a dispatcher,
  migration (DUMP / REVIVE) between nodes; later the Pi's interface (pi/) to the Linux side.
  The Z80: superzazu/z80 (MIT, C99, ~1800 lines, zexdoc and zexall pass - checked here: 93.5G
  cycles in 101 s on one core, ~930 MHz, ~280x a CPC). 1984's own core is GPL v2 (the server would
  be GPL); floooh/chips' z80.h (zlib) is cycle-stepped - slower for this. Speed: the interpreter
  first (computed goto, no cycle counts), a JIT later (self-modifying code - NTC's - to watch)
- **vCPCs** (Julian, 2026-10-29 - the slot servers' shape): a machine (a CPC, or a vCPC) spawns
  vCPCs and keeps up to x of them, each by a short number plus an alias. Where they run: a Docker
  instance through a web stub on an ordinary host (the stub holds the API keys - Amazon, Google, a
  LAN's own Docker - never the CPC), or on the CPC-CPLink's Pi. One protocol: the Pi link's (cosd -
  channels, tagged STORE data) also for the vCPCs - each keeps and fetches its data in its own
  container (or the Pi); nothing outside reaches a vCPC directly (only the Pi on the CPC's own link -
  the CPC itself one more vCPC to it). With the Pi a vCPC opens like a slot, by the same
  mechanism: a small CPC gets 20 or 40 slots, and RVIEW / RCLI (a vCPC's screen and command line)
  give the same experience as on the CPC. Control + its number brings a vCPC to the front as a
  local slot comes (RVIEW its screen); the CPC keeps the slot list (local slots and vCPCs), so PS /
  TOP list them all and the user picks one. Farming: a program spins up many (100) containers, sends
  each its share of the data and gathers the results; the containers can be handed each other's
  details - a controlled mesh (they talk to whom they're told, ports across the network).
  Access: a plain-text password for now, ZOSCII later
- **A second instruction set** (Julian, 2026-10-29: Z80MMX / Z80AI): one opcode swaps to it
  (it would crash a real Z80 - never reached there); the new set has its own flow control, so a
  whole loop runs in it, and one instruction swaps back. Known once at start-up, not probed each
  time: the environment says so - a BDOS answer (CybSys's capabilities: real CyborgOS "none"),
  or a port / memory byte the build sets. Then a branch on that flag picks the loop. To decide:
  the same 64K or a space of its own (flat 4MB?); which Z80 registers carry across; the swap
  opcode clear of the Z80N's (ED 23-36, 8A, 90-95, A4-AC, B4, B7, BC), Z180 / eZ80 / R800's and
  the emulators' traps; the mode and the new set's registers in a slot's state (DUMP / SEND)
- **A slot's own colours outlive its program** (Julian, 2026-10-29: VDU run, killed - its colours
  stay in the slot, RESET too). Seen in the code: KERNEL's ResetSlot never clears CINK (#F6E5-7)
  nor calls Inks; EndTask (KILL's way, a program's end) does clear them - why KILL leaves them
  still to find (the program not st 2 when killed? GUI sets them itself: GuiScr.cls). Fix: both
  clear CINK and put the console's inks back when the slot is in front
- **Slots moved: PAUSE, DUMP, SEND** (Julian, 2026-10-29) - in this order:
  - DONE 2026-10-29: PAUSE n / UNPAUSE n: the scheduler passes the slot over (kernel state 3; the state it had kept)
  - DONE 2026-10-29: DUMP n FILE / REVIVE n FILE: its bank's 4 pages and a header (magic, the build's stamp - VER -,
    the kernel's st / ra / kq / wk, the DMA, its drive and that letter's path, the program's name)
    to a file; back into a closed slot, paused. Refused for a slot with a file open, a claim, a
    port or a socket (said which). Its scrollback / store pages not kept (fresh ones, #FF20 put
    right). Another slot number is fine; another build isn't
  - SEND slot IP [word] [-o target]: the same over the network - the slot paused, sent, closed once
    the other end says it has it (else it runs on here). -o: the target slot there killed and taken
    over (Julian: music played on the other machine, a game's new version sent again and again
    into the same slot) - only one of the slots SLOTD permits (refused otherwise: SLOTD's own,
    whatever else runs there, is safe); without -o the first open slot SLOTD permits
  - SEND FILE.CYB IP [word] [-o target]: a program file sent instead of a running slot - SLOTD
    runs it fresh there (a game's new build): its size, not 64K, and none of DUMP's refusals
  - SLOTD [slots] [word]: the receiving end, a daemon in a slot of its own (SLOTD 4,5,6 SECRET): it
    listens, takes a slot sent into one of those slots (any closed one without a list) and runs it.
    No walking to the other machine: started once, it takes whatever comes (later the tooling
    drives it through the remote displays too)
  - The word: optional, only a permission to receive (a dev's own machines), not encryption. Later,
    if this works well: ZOSCII for it. The M4 listening (its listen / accept - to check), else
    through the VDU server as a relay. CPC to CPC, Next to Next (the same build)
- DONE 2026-10-29: **MOUNT device letter** (Julian: MOUNT SD E, MOUNT SD: E:) - a device or its folder
  to a letter C-P, the slot left on its own drive; MOUNT - E drops it, MOUNT alone lists. On the boot
  drive (beside FLOPPY), not Z: (Z: was full at 160K).
- **E: alone, then a device** (Julian, 2026-10-29): `c:` then `ide:` gives C: IDE:; a letter with no
  path that UniDOS doesn't know (E:, F: ...) says "no such drive" instead - take it, the device typed
  next gives it its path. Tried (CV: r = 0 for C-P): UniDOS's A: ended up M4:CPM in its
  !UNIDOS!.NVM - taken out until that's understood (maybe also Julian's "CD on the M4 reset to
  BASIC in that folder").
- DONE 2026-10-29: **an empty device** (SD:, UMS: with no file on it - UniDOS's examine answers
  18) is taken by CV as BASIC takes it (Hyp: 18 on a device's top); DIR lists it as empty.
- DONE 2026-10-29: **HELP CRUNCH and FTP: hung** with AMSDOS in (UniDOS's DFA / DFB): AMSDOS's
  "Retry, Ignore or Cancel?" waited on a key CyborgOS never passes to the firmware. Main sets
  AMSDOS's message flag (#BE78 = #FF) at boot; CV says "FTP: not there" for a device with nothing in it.
- **GUI ports** (Julian, 2026-10-29): GUI P=name - its port (GUI by default), so several GUIs run at
  once (local, remote heads); GuiCli.Port name, GUIDEMO P=name. Started: GUI.bas takes P=, shows
  the port and RGUI's page in its menu strip (not built yet); GuiCli / GUIDEMO to do.

## ideas (not now - Julian, 2026-10-27)
- **POSIX slots, UZI-style** (later - Julian, 2026-10-27): a slot running Unix programs beside CP/M,
  .CYB and RAT under the one scheduler - Fuzix's userland (UZI's successor; it runs on the CPC
  already) through its syscall entry in the slot's page zero, forwarded to new BDOS 131 ops:
  - small: open / read / write / lseek / close / unlink / rename / mkdir (the file calls), the
    console as stdin / stdout, exit / wait (the kernel's slot states), exec (RUN into the same
    slot), getpid (the slot), time (the TIME work);
  - the main job: fork - the slot's 64K bank copied into a free slot's (no relocation: every slot
    is a whole 64K at the same addresses, as UZI forks without an MMU), a parent / child table in
    the kernel; pipes - the ports as byte streams;
  - last: signals (the kernel calling the slot's handler - the CYB header's), select / poll
    (a slot woken on events);
  - faked: one user, no permissions or links (AMSDOS / UniDOS / FAT have none), /dev names in the
    layer (tty, null, the serial ports). A process is a slot: 20 at most.
  - First: Fuzix's Z80 syscall ABI and its CPC port's sources - https://codeberg.org/EtchedPixels/FUZIX
    (Alan Cox's Fuzix: the kernel, the libc, the userland, the Z80 platforms, the CPC's among them).
- **Coleco Adam** (+ a memory expander): the full slot model - port #7F maps both 32K halves to
  expansion RAM, so a slot is a whole 64K with RAM at #0000 and the existing .CYB / .COM run;
  C0 in the Adam's own 64K. Console: the TMS9918's Text mode, 40 x 24 (ntc_font6 fits its 6 x 8
  cells; scroll by rewriting the 960-byte name table), 80 x 24 with an F18A. Needs a 40 column
  mode in CyborgOS (TOP, PS, MEM, DIR, the status strip). The VDP's NMI is the tick (R#1 bit 5
  turns it off). Files / network / clock through FujiNet or EOS. To pin down first: the
  expander's bank select port.
- **Sega SC-3000H** with its 1MB RAM expansion: the same kind of port.
- TRS-80 Model 1 / III + X-MEM/80 (512K, only #8000-#FFFF banked): a cut-down CyborgOS at best
  (32K slots, every command rebuilt at #8000, no CP/M) - not a candidate.
- NTC BASIC already builds games for the Adam's and the SC-3000's chips (the ColecoVision
  platform: TMS9918, SN76489).

## done
- 2026-10-29 GUI on the Headless Horseman (a vCPC; Julian found it refused): GUI.bas's CPC build refused
  any host but 0 - now only the Next (1), its own build being the Next's. The CPC head (cpc/GuiScr.cls)
  can't draw on a vCPC (no gate array: its OUT C3 and #4000 writes would land in GUI's own program; its
  RAM setting from BC isn't there), so on host 4 it is headless - Init succeeds without them, Rect /
  Fill / Text / Ptr draw nothing - and the desktop goes only to RGUI (R=). In the vCPC: GUI runs, mouse
  KEYS, GUIDEMO's window opens on it through the port. GUI's and GUIDEMO's messages had their numbers
  run into the words ("Control +2for", "window0on"). Not tried: R= to a VDU server; GUI's P=name and
  the menu strip's port / RGUI address are still untested on a CPC.
- 2026-10-29 The commands all in C/ (CYBORGOS/C/; Julian): MOUNT, PAUSE, UNPAUSE, DUMP, REVIVE, SPEED,
  FLOPPY, NET, IPCONFIG, NETSTAT and disc 8's HWINFO ... moved there on the CPC's discs, beside Z's 21;
  Z: is the ones loaded as if built in (the Z list, unchanged). The kernel looks on Z, then the slot's
  own drive, then C/ on the boot drive (C/NAME: UniDOS takes the folder in the name - no letter for
  it), then the boot drive itself (its apps); a name with a path is taken as it is; a command found in
  C/ shows its own name (PS: PS.CYB). The Next's card: C/ holds all 38 (it had them in C/ and the root);
  the MSX's folder keeps its commands at its top (no C/ there: the five new ones named in its list).
  HELP's overview says so. The flat build is as it was (its own kernel: commands where its discs put
  them). Tests: cosregress 51 (dump, speed re-recorded: timing), msxregress 28 (dir, cd, v9_dir, help:
  SPEED in its folder, HELP's text); the vCPC finds PAUSE, SPEED, IPCONFIG in C/ with only CYBORGOS given.
- 2026-10-29 cards/: the two CyborgOS card images (the hard files) brought up to date - they were from
  28 October 17:56: no PAUSE, UNPAUSE, DUMP, REVIVE, SPEED, nor today's KERNEL.CYB / CYBORGOS.BIN.
  tools/sdinstall/cards.sh does it from now on (each image out of its zip as the builder's base, the
  build, zipped back); the README says so. Checked: KERNEL.CYB and SPEED.CYB in the image are the
  build's, byte for byte.
- 2026-10-29 tools/sdinstall/dist.sh (--cpc: the CPC's set onto a WinAPE drive; the Next's folders)
  takes every CPC disc - cos-disk*.dsk, in order - not 1-8: disc 9's SPEED, DUMP, REVIVE were left out
  (Julian's hard file). The README's disc lists say 1-9 (the flat set 1-8).
- 2026-10-29 SPEED [seconds]: how fast its slot's Z80 runs against a 4 MHz CPC - a DJNZ loop (25,600
  at a time: 0.1 s on a CPC, so CyborgOS's turns go on) timed by CybSys.Clock, as n times a CPC and
  about n MHz. On disc 9 (flat: 8), in the Next's and MSX's folders. A vCPC here: 478 times a CPC
  alone, 69 with CRUNCH and TICKER running beside it. cosregress speed: NTC's harness says 2.55 (its
  Z80 has no CPC wait states - DJNZ 13 T, not 16 - and its clock isn't the CPC's): the reference
  holds that, not a real CPC's figure - to try on a real CPC and in 1984 (should be a little under 1).
- 2026-10-29 MEM: a vCPC's own section (host 4: no CPC under it, the banks' map: B a slot's or the
  kernel's, U a store's); the CPC's, Next's, MSX's and flat build's screens as before (cosregress mem,
  msxregress mem pass).
- 2026-10-29 DUMP / REVIVE ("Slots moved", second; next: SEND / SLOTD): a slot's program saved whole
  and where it is, and back into a slot, paused. A stopped slot's registers are on its own stack
  (SP at #FFFE), so a dump is its bank's 64K and 12 bytes of state: the kernel's st, kq, ra, its
  drive, a file open, its DMA, the build's stamp. C0's op 37 (SLOT t g v, all three C0s): r0 the
  DMA, r1 a file open (Hyp.FileOwns: FileCall's fin / fout), r2 the stamp (BankStamp: a sum of the
  bank image, page zero and the stubs - another build's bank isn't taken; no VER needed for it);
  g 1 the DMA set, 3 the slot's own words kept (the scrollback's #FF20-#FF27), 2 its bank made its
  own again (those words, no store, the CPC's #003B / #003D, the Next's / MSX's switch below #FFFE).
  The kernel's op 5: 3 the state (12 bytes), 4 REVIVE begins (a closed slot or its command line made
  a paused slot with a program: its bank written by the caller, BDOS 131 op 10 kind 4), 5 REVIVE done
  (the state set, its name from its bank - PS). CybSys.SlotState / ReviveBegin / ReviveDone (NTC's
  copy too). DUMP.bas is both commands (its own name): DUMP refuses a slot with a file open, a claim,
  a port or a socket (says which), pauses a running one and lets it go on after; the file is 128
  bytes (CYBDUMP1, the state, the name, the drive's path) and the 64K. REVIVE checks the stamp, says
  when its drive's path differs. On a new disc 9 (the flat set's disc 8), in the Next's and the MSX's
  folders. Tests: cosregress dump (TICKER dumped from slot 2, revived in 3, UNPAUSE, FG 3: its count
  going on) - 50 pass, mem and v9_novdp re-recorded (C0 169 bytes more); msxregress dump - 28 pass
  (dir, mem, cd, v9_dir, help re-recorded: the new files, C0's size, HELP's cursor). In the vCPC
  (cyborg-os-vcpc) too: the revived TICKER stays at its count while paused and counts on after.
  Not yet: the Next on hardware. A revived slot's page shows the dumped slot's strip number ([2])
  until it is drawn again.
  The flat build (its own kernel in its C0, src/bas/cyborgosflat) has PAUSE / DUMP / REVIVE too (pz():
  paused while still a program to the services; 238 bytes more, #936E, MEM's reference re-recorded):
  its pause test passes; its dump test does not yet - the revived TICKER runs on in slot 3, but FG 3
  shows slot 1's old screen under the new lines, not the dumped page (to find: how the flat build
  keeps a slot's console).
- 2026-10-29 PAUSE / UNPAUSE (the first of "Slots moved", next: DUMP / REVIVE): a slot's program
  stopped where it is and going on again. The kernel's state 3 (C0 is told 2: to its services the
  slot still has a program - a port's reply, KEYMAN's op 10 write still reach it); Ready() passes
  it over, so its BDOS answer, its key and everything else it had wait for UNPAUSE. KILL, RESET,
  PS ("TICKER.CYB (paused)"), TOP ("paused"), RUN's busy check and the keys typed to it in front
  take state 3 as a slot with a program. BDOS 131 op 5 (Byte(2) 1 pause, 0 go on, 2 the state; a
  slot can't pause itself), CybSys.Pause / CybSys.State (NTC's lib/cyborgos copy too). PAUSE.bas is
  both commands (its own name, at #F6D8, says which): PAUSE.CYB, UNPAUSE.CYB, PAUSE.HLP, UNPAUSE.HLP
  on CPC disc 2 (both sets - now full: 0K free) and so in the Next's and the MSX's folders. HELP's
  first paragraph wrapped at 75 (the MSX's console wrapped it). Tests: cosregress pause (49 pass),
  msxregress pause (27 pass: dir, cd, v9_dir, help re-recorded - MOUNT and PAUSE in them); in the
  vCPC (cyborg-os-vcpc, its own project: the real KERNEL.CYB under a C0 in C) a paused TICKER's count
  stops and goes on after UNPAUSE.
- 2026-10-29 NTC BASIC has a new target, `cyborgoshh` - CyborgOS - The Headless Horseman (a program
  for a headless CyborgOS, a vCPC). For now it is the cyborgos target exactly (`;@base cyborgos`: the
  same .CYB; `#If NTC_CYBORGOSHH`, with NTC_CYBORGOS and NTC_CPM). The builder's copy of NTC's JS
  refreshed (`cli.js ntc`): the build is byte for byte the same.
- 2026-10-27 The Pi side (`pi/`, docs/cyborgos-pi.md): cosd.js - one link (CPC-CPLink through
  cplink-bridge.c's GPIO, the CPLink2 with big answers through its Pi ROM, a serial line for USIfAC
  and the Next's Pi Zero, TCP for tests), frames with channels, credit, parts; the control channel
  (TIME, LIST, OPEN ...) and STORE, RUN, TERM, MATH, VDU (full HD on the HDMI, RVDU's commands or
  mode=hd), AUDIO; plugin / rat / slot listed as not yet. cosctl.js stands in for the CPC;
  test/run.js: 56 tests (DISK - Pi volumes - with them). Next: the CPC side (C0 owning the link, BDOS 131 ops, PI / PITERM).
- 2026-10-27 The hardware tests (disc 8, `cmds/hw/`, docs/cyborgos-hardware.md 5): HWINFO,
  RTCTEST, M4TIME (C0: BDOS 131 op 20 / 11, the M4's C_TIME, the network on or not), NTPTEST
  (the W5100S's socket 3: UDP to an NTP server), SPEAK (SSA-1 / dk'tronics allophones), SIDTEST
  (Speak&SID). HWINFO, RTCTEST, M4TIME, NTPTEST checked in 1984 (emu84.js --rtc --net4cpc);
  SPEAK and SIDTEST wait for the real cards. HELP HWINFO covers them all.
- 2026-10-27 The 1984 emulator as a test bench (tools/emu84: the patch, emu84.js, the notes):
  CyborgOS boots there from an M4 folder, with the V9990. Two bugs found and fixed: UniDOS found
  by its Ctrl J through KL FIND COMMAND took the M4's Ctrl J (a restart) - the first DIR on a CPC
  with an M4 in a lower slot than UniDOS restarted it (fl_fcj now, the folder cache from #6040,
  111 entries); with the V9990 on, Scr wrote 0s to the CPC's CRTC (R1, R2, R7) and stopped its
  sync - no interrupts, CyborgOS hung (the CRTC left alone now).
- 2026-10-27 The console on a V9990, the CPC (the Powergraph, an MSX card through AMSDAP: &FF60) and
  the MSX (GFX9000 / Video9000: #60): V9.cls in both C0s (docs/cyborgos.md 8a) - found at the start
  (R#15 read back), NOV9990 on the command line leaves it alone; B3 512 x 212, 80 x 26 (84 in MODE
  S), the text a ring of 32 rows on SCAY (rolled at 256), the font drawn once into lines 256-271
  (the CPC: ntc_font6 as window data, read from main RAM's own #4000 - no main RAM; the MSX: the
  ROM's), characters LMMM, rows LMMV, the cursor an XOR; Inks are its palette 0 / 1. Con's
  primitives (cn_scr, cn_next, cn_glyph8, the scroll, the clears, the cursor), Say, Scr, Inks and
  Vdu 1 branch on v9_on. CPC disc 1 was full (CYBORGOS.BIN 760 bytes bigger): MON2.CYB to disc 7.
  NTC's harnesses: test/v9990.py (a model of the chip: ports, registers, VRAM, palette, LMMV / LMMM
  / LMMC / PSET, SCAY's roll, the text read off the picture), NTC_V9990=1 in ntcrun.py (the CPC)
  and msxrun.py (the MSX; its ROM font is ntc_font6 now). Tests: cosregress v9_* (7), msxregress
  v9_* (8)
- 2026-10-27 The MSX port (docs/cyborgos-msx-port.md): CYBORGOS.COM, an MSX-DOS 2 / Nextor program
  (NTC's msxdos platform), C0 from the Next's in `src/bas/cyborgosmsx/`, the same KERNEL.CYB and
  commands (host 3: MEM's map). The slot switch over the mapper pivoting on page 3 (sb_hout /
  sb_hin at HISW, msx_recv: MSX-DOS 2 keeps #0038-#005B); TEXT 2 on the V9938 with the name table a
  ring of 32 rows and R#23's scroll; the CPC's keys through the PPI; the files through MSX-DOS 2's
  handle calls (every drive A-H, CD's folders); the clock at 300 a second with a tick each look in a
  frame. Builder: the CYBORGOS.COM project, `build/msx/CYBORGOS/` (cardfolder: DEST=- leaves a file
  of the CPC's set out). `tools/regress/msxregress.js`: 18 tests in NTC's msxrun.py. Not yet: a real
  MSX or openMSX, the GR8NET's network, CTRL + STOP, GUI, FLOPPY, Inks, KEYREP
- 2026-10-27 The CPC's install discs (both sets, dsk and dskflat) each have DISK.DAT: the disc's
  number (1-7, a text line). INSTALL.BAS reads B:DISK.DAT before each disc's files (disc 1 too):
  another number, no DISK.DAT or no disc (an error, trapped) - it says which and asks for the disc
  again. DISK.DAT is noinstall (not copied). Builder: textfile parts DISK1.DAT ... DISK7.DAT
- 2026-10-26 (evening) The CPC's flat build, to compare with the split (docs/cyborgos.md 0a):
  CYBFLAT.BIN from `src/bas/cyborgosflat/` (05:02's C0, no kernel bank) with the screen at #4000
  and code in #C000-#FFFF (NTC's new Option HighCode, Option Place Hyp, Ent); the console with the
  slot's page 3 at #C000 (layout 1), TOP's font in main RAM, the pointer's XOR in main RAM; MEM's
  host 2. Its discs `build/dskflat/` (COSLOADF.BIN, INSTALLF.BAS); `cosregress.js --dsk=DIR`.
  Data from #8000 to #921E with 512K: about 5K free under #A5F0, plus room left at #C000.
  Harness (NTC's ntcrun.py): SCR SET BASE, the screen read from wherever it is, the RAM under a
  selected ROM kept. Speed = 05:02's (LINES 5059, CRUNCH 6295, DIR 1932, PS 370, TYPE 665 ms).
- 2026-10-26 (afternoon) The CPC: the kernel runs the slots. KRun (KERNEL.bas) switches into a slot
  and its interrupts come back to the kernel (#0038 of each bank: the kernel's RAM setting at
  #003B, its slot number at #003D - Install); 6 a slice, 3 slices a turn; at each frame C0's visit
  runs the firmware's interrupt handler once and makes TIME up (KL TIME SET). The kernel's own
  interrupts: KInit's handler at its #0038. A slot's calls go by the route at #0008 of its page
  zero (RST 1-5's bytes): 0, #81 and 131's ops 0-9 to the kernel, the rest to C0, which answers the
  slot directly (Hyp.Go: C0 only waits to be called now; RUN gone from the CPC's C0) - TOP gets C0's
  counts once a second (STATS); a slot's characters at a slice's end shown by CONO. Speed against
  the 05:02 build (harness): CRUNCH -5%, DIR -4%, LINES +5%, PS +9%, TYPE +20%. The Next is
  unchanged (C0 runs its slots: RUN). C0 ends at #9738 (3.8K free under #A5F0). To do: the Next the same way; the screen to #4000 and C0
  through #C000 (Option Place in NTC for the class that must stay under the ROMs' RAM).
- 2026-10-26 The kernel split, both machines. C0 (CYBORGOS.BIN, CYBORGOS.NEX: main RAM) is the
  memory manager and the hardware; the kernel - the scheduler, the command line, TOP, the slots'
  states, the BDOS calls that are its - is KERNEL.CYB (src/bas/cyborgoskernel/KERNEL.bas, NTC's
  cyborgos platform: one file for the CPC and the Next), loaded at boot into a 64K bank of its own
  (taken after the hypervisor's pages, before the slots') with the bank image every slot gets,
  read from the boot drive (the Next: the archive A:) and run as a slot's program is. It asks C0
  through BDOS 132, a block at its #EE00 (C0 reads it through the window, the kernel's page 3 in:
  #6E00) - the ops in KERNEL.bas's header. RUN runs a slot's slices and answers its BDOS calls
  that are C0's (files, DMA, drive, 12, RAMDISC, BDOS 131's memory / store / claims / network /
  ports) as they come - only the kernel's come back (the end, a key wait, PS, KILL, RESET, FG,
  WAIT, MODE, TOP, MEM); the command lines and the programs' names are kept in the kernel (into
  the slot's bank at Enter / RUN: CybSys.Tail reads them there). The CPC's disc buffers (CAS IN /
  OUT, 2K each) are in main RAM now (#8000 on - a firmware call has the lower ROM in), out of the
  hypervisor's page (#4000-#4FFF free there). Main RAM: the CPC's C0 with its arrays ends at
  #94CB (576K's tables; 4.4K free under #A5F0 - it was #A0A3, 1.2K, with the buffers in the
  page); the Next's at #981D (it was #AFEB; the limit #BE00). The kernel uses 16K of its bank
  (#0100-#4130). Speed against the 05:02 build (tools/regress/cosperf.js): CRUNCH 14% slower,
  LINES 7%, DIR 8%, PS and TYPE 17-19%. 128K dropped: 320K the least, 576K realistic. MEM says
  the kernel's bank is a B. Tests: cosregress 41 (MEM's new screen the reference), nextkeys
  (reads C0's front from the Next's RAM itself: ZEsarUX's zone 0 - the kernel or a slot is mapped
  in most of the time), nettest. New tools: tools/regress/cosperf.js (timing two builds),
  cosprof.js (where the time goes: C0, the kernel, a slot), tools/sizes/split.js.
- 2026-10-26 Fixed: on a real CPC with more ROMs than AMSDOS (UniDOS, its FatFS ROMs, M4 ...) every
  build since 22 Oct lost UniDOS (DIR: "A: its files can't be listed") and IDE: reset. COSLOAD walks
  the ROMs and, when they take more RAM than AMSDOS alone, puts the fast ticker's block and the RAM
  top under them - into CYBORGOS.BIN's variables ntc_fwblk / ntc_fwtop, whose addresses the builder
  writes in COSCYB.INC. The builder took NTC_FWBLK (a constant, #A5F0) for ntc_fwblk (the .sym has
  both; the names were matched without case): COSLOAD wrote into #A5F0, in the ROMs' RAM, and
  CyborgOS put its event block there too - the ROMs' RAM overwritten. The 18 Oct discs (gendsk /
  packz) had it right. cos_core.js now takes the exact names (a name in small letters wins), checks
  they are CYBORGOS.BIN's variables, and COSLOAD.ASM asserts it. tools/regress/cosregress.js: test
  romram (the ROMs' RAM from #A400: ntc_fwblk / ntc_fwtop must be #A3F0). The emulator never showed
  it: its ROMs keep nothing in RAM.
- 2026-10-26 The Next's cursor keys in MON, MON2, YING, YANG: NTC's zxn keyboard gave nothing for
  Caps Shift + 5-8 (the Next's cursor keys); it gives the CPC firmware's codes now (up 240, down
  241, left 242, right 243), which the programs read. tools/cosbuild's NTC components brought up
  to date with NTC (cli.js ntc). tools/regress/nextkeys.js runs MON and checks a cursor down moves it.
- 2026-10-26 The Next's slot keys: Caps Shift + 0 is TOP, then the slot's key on TOP (1-9, 0, A-J).
  Caps Shift + 1-9 are no longer slots: the Next's cursor keys (and EDIT, CAPS LOCK, GRAPH ...) are
  those chords in the keyboard matrix, so the cursor keys switched slots (MON, MON2, YING, YANG
  unusable). Checked in ZEsarUX by tools/regress/nextkeys.js (the slot in front read from the
  hypervisor after each key). The CPC's keys are unchanged.
- 2026-10-26 Tests in tools/ as node scripts: tools/regress/cosregress.js (the CPC set from the
  discs, booted in NTC's harness: 40 tests with reference screens, the network through the M4
  against tools/regress/cosweb.js), tools/espsim/nettest.js (the Next in ZEsarUX with espsim.py:
  replaces nettest.py), tools/cosbuild/test/pagetest.js (the builder page end to end). Found by
  them: Http.cls showed a port over 32767 as negative (http://host:-29973/) in the address after a
  redirect and in "Can't connect to" - the port is an Integer; shown unsigned now. The connection
  itself was right. COPY and ERA said "A:: its files can't be listed (UniDOS, or a RAM disc)" -
  now "A: its files can't be listed (UniDOS's drives and RAM discs can)", as DIR says it.
- 2026-10-25 CPC regression and the builder restructured. Fault found: CYBORGOS.BAS and WINAPE.BAS
  on disc 1 had lost their ^Z (end of file) - RUN"CYBORGOS read past the end. Fixed in the sources.
  The 7 discs booted (576K) and 31 commands run against the 10-18 set: the same but for the new
  commands (IPCONFIG, NETSTAT), MEM / Z: free sizes. The one-file CyborgOSBuilder.htm and make.js
  removed: tools/cosbuild/src/cosbuild.html is the builder - no node; it opens the CyborgOS folder
  (Chrome/Edge read and write it in place, others read it) and writes build/stage and build/.
  src/cli.js is the node command line, loading the same js/. Page and cli.js builds compared: the
  same files, byte for byte.
- 2026-10-22 CyborgOS Builder on CyborgDesigner: the build is a layout (CyborgOS.layout.json: stages of
  steps of parts) - the parts its own datatypes: NTC project, assembly file, note, checkbox, external
  tool (give / do / bring, its scripts, node runs its command), system drive Z, COSCYB.INC, text
  file, AUTOEXEC.BAS, Next boot archive, INSTALL.BAS, .DSK, card folder, image (new / into one),
  copy, imports. Build runs them in order, stops where one waits; Design edits the layout in
  CyborgDesigner; a page can hold any number of layouts. cosbuild.txt (the recipe) replaced by the
  layout: the same outputs, byte for byte (the 7 discs, both NEX files, the archive)
- 2026-10-22 CyborgOS Builder (tools/cosbuild/CyborgOSBuilder.htm): one file - the page and node - that
  holds the project (sources, data, the recipe cosbuild.txt), compiles every target with NTC's own JS,
  writes the stage folder and the sjasmplus scripts, and packages: Z packed directly (RAMDISC's driver
  page and the commands in its blocks - checked against packz.py's: the same pages, but for the call's
  scratch bytes and D_POOL's pages, which COSLOAD writes; booted in the harness: COSLOAD loads it,
  DIR Z: lists the 21), COSZ.INC, COSCYB.INC, CYBORGOS.ARC, INSTALL.BAS's DATA, cos-disk1..7.dsk, the
  Next's card folders; .DSK and FAT image tools. Replaces packz.py and the missing gendsk. The discs
  rebuilt (the first since 10-18): IPCONFIG, NETSTAT on disc 4; RVDU to disc 5 (disc 6 full); GUI,
  GUIDEMO on disc 7. The commands built for the cyborgos platform (was cpm --amsdos). KEYMAN without
  Chain.cls (as its header says: with it, its arrays reached #EF00). HOME.RAW, KEYS.RAW, CYBORGOS.BAS,
  WINAPE.BAS back in the sources (they were only on the discs). INSTALL.BAS: seven discs
  The card images too (sdinstall's install into an image that is there, in JS: FAT12/16/32, an MBR or
  a bare volume, WinAPE's sparse .ide): the builder needs nothing but sjasmplus. Booted: the CPC
  (COSLOAD, Z ready-made) in the harness, the Next's card image in ZEsarUX (DIR, MEM)
- 2026-10-21 (Next port) The slot keys while programs poll: Hot.Poll, called from the hypervisor's
  loop (which runs at every slot's turn end), reads the chords once a frame by the raster line
  (NextReg #1F / #1E) when no interrupt-driven Tick came in that frame - the Next's pulse was
  being taken seconds apart with RAT polling (a 3-second press got through, a normal one not),
  and the chords were read only on the tick. The stub leaves interrupts in during a key poll (6,
  11) as well. Tested: MODEL + RAT + PET running, Shift + 1-3 and Shift + 0 at once, PET fed.
- 2026-10-21 (Next port) A program polling for a key (Inkey, Input: BDOS 6 / 11 with none
  waiting) now gives the hypervisor a turn every 256th empty poll (the stub: a far call as 12
  makes). Its keys reach its KEY only when the hypervisor runs, and on the Next a tight poll loop
  with interrupts off between keywords can miss the INT pulse for ever - Input in a program got
  nothing (PROBE's prompt, a test program), and the slot keys died while busy programs ran. The
  stub is at its size limit: its line buffer and counters moved to the bank's own bytes
  (#F6E8-#F6EB). Open: PROBE with RAT running still dies now and then in ZEsarUX at a key (a
  race that recording the CPU history makes vanish); PET + RAT run.
- 2026-10-21 (Next port, to test on JNEXT / hardware) The missed-pulse problem: the Next's INT is
  a 32 T pulse and a slot running an NTC program (interrupts in for one instruction between
  keywords) misses some - the slot keys go dead while RAT computes, PET's port call never gets
  RAT's answer. The Next's interrupt controller (core 3.02+) can hold the line interrupt until
  it is taken: NTC's new `ntc_zxn_inthold` (NextReg #C4 = 2, #C0 = 1: "hw IM2 mode" latching,
  in IM 1 too) and the handler ends with reti; the hypervisor calls it at start. Emulators
  without the controller (ZEsarUX) ignore it: unchanged there (RAT / ASK pass). If JNEXT
  misbehaves with it, remove the call in Main.bas's zxn init.
- 2026-10-21 (Next port) Slot keys with 10 slots or more: the same number twice quickly is 9
  more (Shift + 1, 1 = slot 10 ... 9, 9 = 18), since the Next has nine slot keys (Shift + 0 is
  TOP); the banner says "(twice 10-n)". The CPC keeps Control + 0 = 10 and doubles 11-20.
- 2026-10-21 (Next port) .CYB is the program format on the Next too: build.sh builds the commands
  with --amsdos (the AMSDOS header, the same file as the CPC's), the archive and the card carry
  them as they are, and both drivers (the archive, the SD card) leave the header out when a file
  is opened - as AMSDOS's CAS IN OPEN does on the CPC, so a program reads "what CP/M sees", Z:
  gets the program alone, and the CPC's own .CYB files run from the card unchanged (PS, MODE,
  CLAIMS from the installed discs: tested; FLOPPY won't, it drives the CPC's disc hardware). A
  plain .COM still runs (the compatible form). sd_x passes HL (F_SEEK's mode). NTC has a
  `cyborgos` platform now (what `cpm` is plus CyborgOS's: a .CYB out, VT52, CybSys built in,
  NTC_CYBORGOS) and the Next's build.sh builds the commands for it; CybSys.Host() (BDOS 131 op
  20 / 5, both hypervisors) says which machine - DRIVE uses it for its A: line. The CPC's
  gendsk still builds the commands for cpm with --amsdos: the same bytes; switch it when the
  discs are next built. Not a feature of either machine: TYPE C:FOLDER/X.TXT (a path in a
  file name - the cpm FileSystem's FCB has no room for one; CD first).
- 2026-10-21 For people: build/next/CYBORGOS/ is the raw folder a real Next wants (the Next's
  commands and help, the CPC's whole set), build/next/cyborgos-next-sd.img a bootable card
  image for emulators (the System/Next distribution with AUTOEXEC.BAS running CyborgOS and the
  folder installed; dist.sh refreshes both). The plain FAT32 images are gone; sdinstall can
  write into a folder (its IMAGE a directory). Booted and tested in ZEsarUX from the image.
- 2026-10-21 sdinstall writes WinAPE's IDE images (.ide, "BITWISE DRIVE IMAGE FILE": a 512 byte
  header and a 4 level block map of 128 entry tables, so a 10GB drive is a 17MB file) through
  the map: `dist.sh --cpc hdd-a.ide` puts the CPC set on the drive WinAPE uses. The FAT32 image
  in build/dsk is a plain one (MBR), which WinAPE doesn't read as a drive.
- 2026-10-21 tools/sdinstall: the installer on the PC - sdinstall.c writes a folder, or the CPC's
  seven .DSK images as INSTALL.BAS's DATA list says (AMSDOS headers kept), into a FAT12/16/32
  image (MBR's first partition or a bare volume: ZEsarUX's .mmc, WinAPE's IDE image, a card);
  dist.sh lays out and installs the Next's build (`--cpc` the CPC's). DRIVE on the Next's Z:
  (the SD card's status says "there", with folders); built with `--const=NTC_HOST_ZXN` (NTC's
  new cli option) it says "A: the boot archive" and no B. DIR C:FOLDER/ - a drive letter followed
  by a path is a path (it was taken as a pattern on drive C). Two RAMDISC Z SYSTEM faults: the
  archive's record read gave HL as the archive, not the buffer, so a short last record wasn't
  padded with ^Z and CYBORGOS.Z's names were counted twice ("26 commands"); a command over 16K
  (the Next's COPY.CYB, 16421 bytes) was skipped without a word - the buffer is 32K now and a
  file that isn't copied is named.
- 2026-10-21 (Next port): the SD card as drive C: with folders, through NextZXOS's esxDOS API -
  the CPC's UniDOS design (a letter with a path is a folder: CD, CV, DIR FULL with sizes and
  dates, MKDIR, RMDIR, COPY, RENAME, ERA, TYPE, programs run from it), hooked into FileCall's page
  code, the SD code in the hypervisor's page at #4000. Shift + 0 is TOP (the Next's Delete key is
  told apart by NextReg #B1), the cursor flashes, the background is the CPC's blue, a keyboard
  matrix readout on TOP's bottom row (DIAG). docs/cyborgos-next-port.md items 12-14
- 2026-10-21 (Next port): boots to a working system in RAM with a Z: drive - in the harness and in
  ZEsarUX. The startup crash was the gate-array `out (c), c` on RAM settings (#7FC0 = the Next's
  #7FFD paging port); every one is `nxt_win` on zxn, the Next's settings are shaped as the CPC's,
  the probe stops at bank 111, the line-interrupt chain survives missed pulses, the console is the
  80-column tilemap, Caps Shift + 1-9 / Caps + Enter are the hotkeys, the boot drive A: is an
  archive in the NEX (tools/nexarc) and RAMDISC Z SYSTEM A makes Z: from it at boot. Details and
  what is next: docs/cyborgos-next-port.md (the 2026-10-21 section)

- 2026-10-18 Pluto (NTS on the CPC), the start of it (docs/pluto.md): the six-layer engine
  apps/pluto/Zc.cls (z u b mz mu mb - encode and decode), validated in the regress and byte for
  byte against the PC reference tools/pluto/pluto.py (itself checked both ways against Julian's C#
  and the protocol creator's C). The file tools ENC / DEC (apps/pluto/Chain.cls) - 1-3 layers,
  keys from KEYS/, the outer u / b layer sizing its suffix so the file is a multiple of 128 (a
  plain UNSIGNAL / BRICS file, no private header - reads on the PC and vice versa). KEYMGR: LIST,
  JPEG (a key from a picture), ENTROPY (a key XORed from files, seeded by the clock, uptime and
  free memory - ROMGenerator.cs's way). And KEYMAN, the service (RUN 2 KEYMAN): it hosts the keys
  and encodes / decodes on its port, the bulk moving through the kernel (the request names where the
  data is in the caller's memory - KEYMAN reads the caller's slot, works on it, writes the result
  back), so the port's 128 bytes carry only the control request. Validated in the regress by a
  client round-trip. On cos-disk7. Remaining Pluto pieces are below.
- 2026-10-18 The kernel can write to a slot, not only read it: BDOS 131 op 10 Byte(1) 4 - the
  caller's own Word(6) into slot Word(2) at Word(4), Word(8) bytes (the inverse of the Byte(1) 3
  read). KEYMAN wraps it in its own SlotRead / SlotWrite (on CybSys.SetWord / Ask, so CybSys is
  untouched), chunking so no copy crosses a 16K bank page. KEYMAN
  uses it to hand a result back to the slot that asked.
- 2026-10-18 Uptime: CybSys.Uptime() - the firmware clock in full (1/300 s since reset, 32 bits;
  it wraps after about 165 days), for entropy sugar, as a new clock sub-op (BDOS 131 op 20 sub 4,
  all four bytes to Word(6), Word(8)); sub 3 (the low word) is unchanged.
- 2026-10-18 The slot store (BDOS 131 op 13 / 14) reads / writes from any byte offset in a block
  (Byte(1) = 1, Word(4) the offset), so a service can fetch a few bytes without copying a 2K block.
- 2026-10-18 Compiler: VarPtr(arr(i)) gave the address of element i of a one-dimensional fixed
  array (it used to compile to 0 and overwrite the bottom of memory); anything else in VarPtr's
  brackets is now a clear error.
- 2026-10-18 The double tap (Control + a number twice: slots 11-20) in a fast emulator: KEYREP n
  now also makes it wait n times as many ticks (Hot.Speed), so it is 0.3 s of real time - WinAPE
  at 1000% with KEYREP 10 (WINAPE.BAS) had 0.03 s.

- 2026-10-18 LUNs: MODEL keeps copies of a model's weights (as many as fit in 30000 bytes, 250 at
  most; LUN 0 the file's, the others copied when first changed, kept in NAME.LUN): "#n" messages,
  U (how many), R (a LUN anew; LUN 0: the file again), B (a LUN bred from two: each weight a
  parent's, -2 to +2). RAT: "model:n" (each LUN its own deadband - 128 kept), "LUNS model",
  "!model message". RATBOX (apps/rat, cos-disk6): a box of rats on RATBOX.MDL, a LUN a rat - males
  and females, mating, rivals fighting in the boxing ring, babies in the pen bred from their
  parents and nursed by their mothers, the graveyard, crowding, the naughty bed.

- 2026-10-18 VDU and RVDU: remote displays over plain HTTP GETs (tools/vdu - PHP, no database:
  each screen an append-only text file of display commands and a 4-byte-a-line index; a viewer's
  pointer - 0 a replay, -1 live from the last MODE, past the end after a wipe from 0 again; one
  ping for many screens, then each drained; touch zones and keys back to the writer as events,
  their count in each put's answer). Viewers: view.html (a canvas, the CPC's way: modes, inks,
  windows, streams, graphics), text.php (a text grid, no script), dumb.php (a rolling log for a
  DS / 3DS), test.html (the test harness: tests sent to a screen, its events listed). RVDU on
  CyborgOS (apps/rvdu, cos-disk6): a screen shown on the console live, rolling or replayed, the
  CPC's keys sent back; NEW, LIST, PUT, TEST (the CPC writing to a screen, the taps coming back).
  The compiler: a string literal over 96 bytes goes out as more db lines (sjasmplus takes 128 in
  one). The harness: \x1b typed is ESC.

- 2026-10-17 Ports: a program opens a named port and other slots call it (BDOS 131 ops 28-33:
  open, close, call, the answer, receive, reply; 8 ports, a 128-byte message each, in the service
  page - no main RAM); a slot waiting on a port sleeps until the next tick. CybSys.PortOpen,
  PortClose, PortCall, PortGet, PortMessage, PortCaller, PortReply, PortStatus, Clock. The rat
  (apps/rat): MODEL (a decision model served on a port: N, R, L, D trees of weights, the L weights
  growing with habit and saved to the .MDL), RAT (the decision service: "model tag tag:level ..."
  -> "tag value"; a necessity below its N weight - the threshold - first, then R, then L - D,
  ties within 5 at random), RATS (the four-corner sample), RATMODEL.MDL, ORC.MDL, GOBLIN.MDL and
  RATMODEL.TXT (how a model is made: for an AI making models - NPCs, later CyborgShell automation).
  NEURAL (jNeuralNetwork's way: records of prop=value learnt, the best match given back; numbers by
  nearness), DUNGEON.NN, SYS.NN with WATCH (CyborgOS's numbers as inputs), ASK (any port from the
  command line); PET (a Tamagotchi-style virtual pet on RAT: feed, TV, clean, medicine, praise /
  scold to train its likes - MODEL's P tag n, X tag n -, boredom, illness, ageing, saved in
  PET.SAV) - on cos-disk6 (a sixth disc: disc 5 is full), with their help. RAT's tolerance is a deadband: a model's last pick stays
  while it is within 5 of the best (no flipping between near-equal choices), else one at random;
  ?calls give the plan (how it chose), ~calls are dry. PROBE: the test drive (its own command
  line: decisions with plans, PORTS - BDOS 131 op 34 -, SHOW - MODEL's D n -, ASK any port), TRY / RUN).
  Multilevel: RAT goes down the model's tree, as deep as it is (MODEL's C path, W @path), to a
  branch with none - food.fruit.apple (FOOD.MDL); every level gets the habit and the deadband.
  Weights from outside: MODEL's V [cat\]tag\tag\x (PROBE: SET) - a game or a sensor sets one.
  docs/cyborgos-decisions.md: how it all works, getting an AI to build models, hooking a model up
  to an IO board (GREEN: a greenhouse bridge and GREEN.MDL)
- Later: programs reading real sensors (ports, the M4) and setting a model's weights with V
- 2026-10-17 RAWYING, RAWYANG: YING and YANG for raw pages (apps/rawying/Bml.cls in place of
  Bml.cls): raw=width asked for, the server lays the page out - rows, links, fields and buttons as
  records (tools/rawpage/RAW.TXT; 8bml2raw.py the reference, websrv.py answers raw=). The rows
  copied in Z80: a 6K page laid out in 0.45 s (YING 1.8 s). On a fifth disc (cos-disk5) with
  HOME.RAW and KEYS.RAW; INSTALL.BAS takes five discs
- 2026-10-17 The network: NET M4 (the M4 found by its ROM's name, claimed by CyborgOS), NET OFF,
  NET GET, NET TEST; BDOS 131 ops 20-27 in the service page (the M4's sockets, a slot's own -
  closed when its program ends: no main RAM); cmds/Http.cls (HTTP/1.0 GETs: lookups, redirects,
  the headers scanned in Z80, the request sent in one go). The harness has an M4 (NTC_M4: real
  sockets) and a web server (websrv.py). A GET: 0.15 s of the CPC's time in the harness
- 2026-10-17 YING, YANG fetch real pages (the stub gone) and send 8BML forms: text fields, text
  areas, selects, buttons - a GET with the fields as URL parameters and action=, mandatory fields
  checked (Bml.cls with #Const BML_FORMS: MON stays as it was). Addresses up to 255 characters;
  the buffers moved up (#B500: values, #BE00: the page, #DC00: the lines), history 8 pages
- 2026-10-17 Claims: CybSys.Claim / Release / Take / Held (BDOS 131 ops 16-19 - a name and a unit,
  one slot at a time), freed when a program ends, is killed or reset; CLAIMS (CLAIMS TAKE), PS
  shows them, FLOPPY claims FDC 0. No main RAM (the service page)
- 2026-10-17 The command tail as it was typed (CybSys.Tail: from the line still in the slot's
  command line buffer - #0080 stays in capitals for CP/M; no main RAM): NET, YING, YANG keep an
  address's small letters
- 2026-10-17 BDOS 131 calls run on in the same turn (as the file calls, 32 at most): each ended
  the program's turn before

- 2026-10-16 Control + a letter reaches the program (WordStar's keys, Control + C): Main dropped
  every key typed with Control held (for Control + 1-9); now only while a system key (a number,
  ESC) is held (Hot.Held). ESC reaches programs as #1B (the firmware's #FC), as Amstrad's CP/M.
  64 bytes of main RAM (#9A21)
- 2026-10-16 TYPE and HELP: lines up to 255 characters (they were cut at 40: the library's strings
  are as long as the program's longest), word wrapped to the console, a page at a time (-- more
  --: space, Enter, Q / ESC / Control + C)

- 2026-10-16 WINAPE.BAS on disc 1 (installed in CYBORGOS/): CYBORGOS.BAS with o$=" KEYREP 10"
- 2026-10-16 The regression's small test programs (hook, for, gs ... wrap) are built into
  src/test/out/PLATFORM[_turbo][_rom], one folder each, not over each other in src/test

- 2026-10-16 FLOPPY both ways, as COPY (from, to): FLOPPY GAMES A writes a folder's files onto a
  formatted disc (its free blocks, its directory - one of the same name replaced; the AMSDOS
  header from the disc ROM's copy: BDOS 30 #C7, new - the hypervisor keeps CAS IN OPEN's HL; 29
  bytes of page code, 43 left); FLOPPY GAME.DSK A writes an image: each track formatted (uPD765
  format, the image's IDs), its sectors written. The harness's controller writes and formats
  too (saving the image)

- 2026-10-16 FILES.DIR gone (320K): the commands read the real directories - UniDOS's listing
  (BDOS 30 #C5), a RAM disc's own (BDOS 17, 18, 35). CybDir.cls rewritten (16 byte entries, no
  save); COPY, ERA (patterns now), TYPE, RENAME, DIR take any file; CD needs no FILES.DIR; PREP,
  NAME.HDR, long names gone; RUN NAME.COM opens it (Main's FindCom / FindEnt gone: main RAM
  smaller); the hypervisor's search from FILES.DIR gone (UniDOS's listing only); RAMDISC makes no
  FILES.DIR. UniDOS is needed for the disc commands (the 128K version keeps FILES.DIR)
- 2026-10-16 The installer puts CyborgOS in A:CYBORGOS/ (commands in C/, help in HELP/: |SAVE
  "PATH/", |COPY), and at the end: run on a real CPC, run on WinAPE (KEYREP 10), exit (|DRIVE
  "A","CYBORGOS", then as CYBORGOS.BAS). RAMDISC Z SYSTEM reads CYBORGOS.Z's C/NAME.CYB lines from
  the boot drive's folder C (a free letter's path for a moment); HELP looks in A:HELP/, B:HELP/
- 2026-10-16 FLOPPY's syntax: FLOPPY A, FLOPPY A folder, FLOPPY A NAME.DSK (INSTALL gone); FLOPPY
  folder A / NAME.DSK A (onto a floppy) say "not yet"

- 2026-10-16 COPY name FOLDER made a file of the folder - and the folder's contents were lost:
  COPY's make (the Library deletes first, BDOS 19) went to |ERA with Y waiting (put there for
  RMDIR), and UniDOS's |ERA takes a folder with all it holds. Now: a CP/M delete answers N (a
  folder is never deleted by one), only RMDIR asks for Y (BDOS 30 op 8, just before its delete of
  the empty folder); COPY into a folder (its name or name/: CybDir.Into, a free letter C-P with
  the folder's path for the copy). Test: COPY into a folder, a folder never deleted by ERA
- 2026-10-16 INSTALL.BAS: Line too long - its CR LF line ends had become LF (an edit); back to
  CR LF, its lines kept to 120 characters (comments split, 4 names a DATA line); gendsk checks
- 2026-10-16 The console's VT52, the rest of it (VDE couldn't rub out or clear: it sends these):
  ESC A B C D (cursor up, down, right, left), K (clear to the end of the row), J (to the end of
  the page), L (insert a row), M (delete a row), and Amstrad's l (clear the row), o (the row up to
  the cursor), d (the page up to it). The page changes first, then the rows drawn again from it
  (test: console VT52, cpm/vt52t.asm). ESC e f j k p q ...: ignored
- 2026-10-17 CV (change volume) and CD (change directory) split: CV the drive, a device, a drive
  letter's path (CV B, CV IDE:, CV C: IDE:WORK, CV C: -; B: or IDE: alone is CV), CD only folders
  (CD C is the folder C - CYBORGOS/C, the commands -, CD .., CD /). CD with a letter always took the
  drive. CybVol.cls: their drive letters, paths, devices (test: CyborgOS UniDOS: CD C). COPY said
  "0 of 1 files copied" for a file over 32K (its byte count went into an Integer). INSTALL asks the device (Enter: IDE) and sets A to its top
  (|DRIVE,"A","IDE:") before it makes CYBORGOS/, then A to IDE:CYBORGOS to run it - A keeps the
  last path set, so a second install went in CYBORGOS/CYBORGOS, a third deeper (|DRIVE,"A",":"
  gave Bad command)
- 2026-10-16 Open: BBC BASIC's FILETEST stops at line 80 on UniDOS / AMSDOS drives (passes on a RAM
  disc). The disc files go through the cassette calls: one file read and one written at a time,
  writing only forward - BDOS 35 on a file being written fails, OPENUP / PTR# writes / update in
  place can't be done. Choice pending: files copied into expansion RAM while open (written back
  at close), or the stream kept (RAM discs for random access), or UniDOS's seek calls
- 2026-10-16 YING and YANG (apps/ying, apps/yang): web browsers from MON and MON2 - the same
  browser (Web.cls: addresses, fetching; Bml.cls: the layout) on MON's window and MON2's whole
  screen. http only; the request gets an empty 8bml parameter (not shown). The fetch is a stub (a
  made-up page) until there is a network driver (M4, Net4CPC ...). Files as pages (A:NAME.8BM):
  local pages, AmigaGuide-like. Disc 4 (cos-disk4) carries them: discs 1-3 are full
- 2026-10-16 BBC BASIC couldn't open a file for output (VDE couldn't save either, probably the
  same): BBC BASIC makes the file (BDOS 22) at its FCB, then copies the FCB into the channel's own
  and reads / writes / closes through the copy (CMOS.Z80: OPEN3). The hypervisor knew a file by
  the FCB's address, so every call through the copy got 255 ("Disk full"). Now the first call
  through another FCB after an open / make takes that one as the file's from then on - unless it is
  the slot's other open file's FCB (the Library's FileSystem reads the record it writes through
  the written file's FCB). The check (fl_is) is in main RAM: the page code had no room (test: BBC
  BASIC's files, cpm/bbct.asm, run twice). BDOS 24 (login vector) gives a bit for the drive (C: 4), not its
  number
- 2026-10-16 The cursor: an underline XORed into the cell where the next character goes, flashing
  (on / off each 0.5 s, Main's loop: Hyp.Con mode -3); off at every Con call before it prints, so
  it never smears; Scr (a cleared screen) forgets it

- 2026-10-16 A plain .COM on a RAM disc runs by its name (BBC BASIC put on E: with FLOPPY ...
  INSTALL E: didn't, from IDE:BEEB it did): the RAM disc driver answers the hypervisor's own
  open (FileCall 100) itself, so the UniDOS .CYB -> .COM fallback never reached it. The driver
  now does the same: NAME.CYB not there, NAME.COM, the caller's name made NAME.COM. No main RAM
  (the driver's own page)

- 2026-10-16 RMDIR hung or took ages on a real CPC: UniDOS's |ERA asks before it deletes a folder
  ("is a directory" - Yes/No/All, KM WAIT CHAR), and with the firmware's text off (Vdu 0) the
  question never showed: it waited for a Y, N or A typed by chance. The hypervisor's delete
  (BDOS 19) now puts a Y waiting first (KM CHAR RETURN) and takes it back after (KM READ CHAR)
  when nothing asked - also for read-only and hidden files. No main RAM (6 bytes of the page
  code, its last). The harness's |ERA asks too (a folder only with a Y)

- 2026-10-16 INSTALL.BAS: SPEED KEY 100,100 at the start (keys don't repeat on WinAPE at full
  speed), 30,2 again at the end

- 2026-10-16 INSTALL.BAS on disc 1 only: "CyborgOS Installer", map the floppy as B and the mass
  storage as A; disc 1, then asks for disc 2 and 3; a bar and the % done per file; |ERA / |COPY with
  @p1$ / @p2$ (BASIC 1.0: no literal strings to an RSX). gendsk writes its DATA (how many, "#n" and
  each disc's files)

- 2026-10-16 FLOPPY on a real CPC: "track 0 sector &C1: can't be read (ST0-2 &41 &90 &0)" - ST1 &90
  is an overrun: a byte not taken within its 32 us. The read loop's wait for each byte went
  through the timeout count (26 us more); now only the first byte has a timeout and the rest
  come in a tight loop (22 us a byte), with interrupts off for the whole controller call (as
  they were, after)

- 2026-10-16 FLOPPY A INSTALL folder DSK [name]: the whole disc as an extended .DSK image (FLOPPY.DSK
  by default) - two passes: each track's sector IDs (read ID round the track: the header needs the
  tracks' sizes first), then each track read by those IDs and written; unreadable sectors kept
  with their ST1 / ST2. Tracks 0-39, 40 and 41 when formatted, side 0

- 2026-10-16 FLOPPY: a floppy disc read track by track through the uPD765 itself (UniDOS turns
  AMSDOS's sector calls off): FLOPPY A lists the files (data, system, IBM formats), FLOPPY A
  INSTALL folder copies each into a folder (made if needed, reached through a free letter as RMDIR
  does) or a drive (C:). A program on the disc (disc 2, run from the boot drive; not in Z: 16K
  of Z for a command seldom run): no main RAM. The harness has the controller
  (NTC_FDC=a.dsk,b.dsk) and make_dsk for test discs. Not tried on real hardware yet

- 2026-10-16 HELP from text files: HELP shows HELP.HLP, HELP name NAME.HLP (from the slot's drive,
  then A, then Z) - one for each command, on disc 1, plain text anyone can edit

- 2026-10-16 RMDIR (UniDOS): an empty folder removed - it looks first (UniDOS's |ERA takes a folder
  with all it holds), then deletes it through a free letter whose path is the parent for a moment
  (BDOS 19: no hypervisor code). DRIVES renamed DRIVE

- 2026-10-16 A RAM disc's letter never has a path: a letter that got one (CD F: IDE:) then made a RAM
  disc showed "drive F: IDE:" and DIR listed IDE: (DIR asked UniDOS for the path's folder; file
  calls already went to the RAM disc - its driver sees them first). Now RAMDISC drops the path,
  CD and DIR treat the letter as the RAM disc, CD IDE: from a RAM disc takes another letter

- 2026-10-16 UniDOS: MKDIR (BDOS 30 #C6: CAS OUT OPEN of "NAME/"), DRIVE (the letters in use, UniDOS's
  devices by their own names with what they are and their free space), a plain .COM with no entry
  runs (the hypervisor's own open: NAME.CYB not there - NAME.COM, UniDOS reads it to its real end;
  the caller's name made NAME.COM too), `IDE:` alone is CD IDE: (any word ending ":" - Main's B:
  test made simpler: no main RAM), CD IDE as CD IDE:, CD DFB: (a floppy UniDOS can't examine:
  taken). MON's ROMs page: ROMs 0-31 (op 15 table 2: 64 bytes each - 16 of the ROM, 48 of its
  names). Main RAM still to #9DB4; the hypervisor's page code full (#5FFA of #6000)

- 2026-10-16 UniDOS: a drive letter (A-P) can be a path - any UniDOS device's folder (`CD IDE:`,
  `CD SD:GAMES`, `CD GAMES`, `CD ..`, `CD C: IDE:WORK`, `CD C: -`; `CD` lists the paths and the
  devices). The hypervisor's file calls put the letter's path before the name (`IDE:GAMES/NAME.EXT`,
  the programs it runs too); a directory search (BDOS 17, 18) lists the folder itself (Ctrl J
  examine: no FILES.DIR needed - a floppy AMSDOS runs still uses FILES.DIR, and isn't held up by
  another slot's read file); DIR lists folders, sizes, dates; COPY, ERA, TYPE, RENAME take any file
  there (CybDir.LoadAll: the folder's files FILES.DIR hasn't got, never written to it). All in the
  hypervisor's page (its page code, 124 bytes left; the FILES.DIR cache 112 entries now, the
  paths, the longer names and BDOS 30's block above it at #7C00-#7FFF) and the bank's stub: BDOS
  30 with #C0 on at DE is CyborgOS's UniDOS call (CP/M's own 30 still answered 0). No main RAM
  (#9DB4 as before). The harness stands in for UniDOS (NTC_UNIDOS=IDE,SD: devices as folders,
  Ctrl J 1, 2, 12, 13)

- 2026-10-16 Under 576K: no system drive Z (made only with 8 expansion banks or more; COSLOAD's Z
  doesn't fit on 320K either) - the commands run from the boot drive; on 320K 96K left free (C6,
  C7, bank 4) for RAM discs, stores and the like. No main RAM cost

- 2026-10-16 COSLOAD's loader and its 2K buffer in screen RAM (#C780, #E000) instead of past
  CYBORGOS.BIN's end: COSLOAD needed the ROMs' RAM above about #A31D, CyborgOS itself only above
  its arrays' end + 16 (#9DC4) - with more ROMs than AMSDOS COSLOAD refused where CYBORGOS.BIN ran.
  Now the same limit as CyborgOS (KL ROM WALK with DE = its ntc_free). gendsk prints CyborgOS's
  main RAM end each build

- 2026-10-16 MON, MON2: the map (SYSTEM.MAP) closed once read (BDOS 16). Left open, it held
  CyborgOS's one read file for as long as MON ran: in every other slot CD said "no such drive,
  or no FILES.DIR there" and DIR listed nothing. Still open: any CP/M program that reads a file
  and doesn't close it (CP/M doesn't need the close) does the same while it runs - FileCall's 15
  refuses another slot's open (fin). A fix would be in the hypervisor (main RAM)

- 2026-10-16 MON2 (apps/mon2/MON2.bas, with apps/mon's Bml, Mouse and SYSTEM.MAP): MON on the whole
  screen - row 0 the toolbar (tools, the link's URL, line / lines), rows 1-23 the page (80
  columns), column 81 the current line's <, column 83 the scroll bar. A line at a time the page
  scrolls with the console's hardware scroll (LF on row 23 on, ESC I on row 0 back; the toolbar
  drawn again after); further, drawn again. ESC Y sent raw (Locate stops at column 80, Print
  turns ESC into ?). 40 lines down from the top: 4.85 s (MON 13.41 s, its window redrawn)
- 2026-10-16 The console: VT52 ESC I (reverse line feed: on the top row the page ring and the
  screen scroll back a row - the hardware scroll the other way). 100 bytes of main RAM
- 2026-10-16 MON: its 8BML writers in Z80 (asm keywords E, EQ, H2, H4, NmU, HexRows, TextRows -
  the BASIC kept as '| comments) and Bml's r lines straight into the line (Put): the hex page
  18.8 s -> 7.7 s, the text page 8.0 s -> 4.3 s (emulator, from MON's map home). Same screens
  (test/monnw/cmp: cmp.sh, timing.py). Next: Bml's NextP / Put / NewLine / Emit in Z80 (half
  the hex page's time now; the base of the web browser)
- 2026-10-16 Fast boot: COSLOAD.BIN (tools/COSLOAD.ASM, built per build) loads Z ready-made from
  CYBORGOS.Z1 ... (test/packz.py: Z's pages, 32K a file) into the pages the slow way gives it (C6,
  C7, the bank after the slots - worked out from a bank probe as the Memory class does; D_POOL
  and its checksum written for them), keeps Z after a reset, then CYBORGOS.BIN (a loader put
  past its end). Z not loaded when it doesn't fit (320K: 9 pages, 6 free) or a file is missing:
  CyborgOS makes Z from CYBORGOS.Z as before. CyborgOS itself unchanged. Three discs carry it to
  IDE: cos-disk1 (CyborgOS, COSLOAD, the apps, FILES.DIR of all three), cos-disk2 (the commands
  Z has), cos-disk3 (the Z files), each with its own INSTALL.BAS (replaces cyborgos320k.dsk)

- 2026-10-16 PREP keeps FILES.DIR (replaces the AMSDOS CYBADD, which is dropped from the 320K disc):
  PREP [v:]pattern ADD / REMOVE, wildcards (* ?). ADD sees a RAM disc's real directory (Z and
  RAMDISC drives); a floppy's own catalogue is still unread. CybDir.AddFile; CRUNCH.COM folded
  back onto the one 320K disc (no cyborgos320k2.dsk). Test "CyborgOS PREP add / remove"
- 2026-10-16 RAM discs survive a reset. The driver page carries a signature at #7F00 ("CYBD", a
  magic word, and a checksum of D_POOL - the page ownership, which file writes don't change),
  written whenever a disc or a page is made or dropped (dr_sig). At boot, before RAMDISC runs,
  Main's ProbeDiscs scans the free pages for it; on a match it reclaims the driver page and every
  page D_POOL lists (Hyp.ClaimPage - CyborgOS's own, marks a free RAT page TypeUser; not in the
  library, so the shared ROM is untouched), and Z and any other RAM disc are back with no loading.
  Only a cold start (no signature) makes Z from the disc as before. Test "CyborgOS reset survival"
  (two boots sharing the expansion RAM: the second loads nothing). Still to come: fast cold load
  of Z from ready-made 16K chunks (CYBORGOS.Z1 ...) and the IDE tool that builds them
- 2026-10-15 CyborgOS's command line at #BE80 (CYB d, then words): KEYREP n (KM SET DELAY, the keys'
  start delay and repeat n times as long - WinAPE at 1000%); CYBORGOS.BAS's o$. RUN [slot] name
  [args] (was RUN name slot, which lost the tail). Harness: NTC_POKE, KM SET / GET DELAY. Test
  "CyborgOS KEYREP, RUN slot name"
- 2026-10-15 Harness: a stand-in's own out (n), a with A = #BC / #BD was taken for a CRTC write (the
  MODE test's screen read 6 characters off when an interrupt came at the wrong moment); stand-ins
  are now told apart by where they are (STANDPC)
- 2026-10-15 The services out of main RAM: BDOS 131 ops 10, 11, 13, 14, 15 (memory reads, the
  pointer, the store's blocks, the tables) as Z80 in a page of the hypervisor's own (C5, the
  service page: Hyp.Svc, window data from #6000) - they had been BASIC in main RAM (MemRead,
  Tables, Ptr, RomRead: 2K). CyborgOS ends at #969A (was #9E2C): main RAM free 3K on 576K (was
  1.1K), 2.3K on 4MB. One page more taken (UU-- in MEM)
- 2026-10-15 4MB again: Option Memory CPCExpansion 257 (it was 193 - 48 banks, 3136K - since
  2026-10-14, when main RAM had no room for all 64 banks' tables; there is now: #A451-#A5EF free
  on 4MB with AMSDOS alone). Test "CyborgOS MEM map": 4160 KB
- 2026-10-15 DIR: the names alone across the screen (by the console's width, none split); DIR FULL the
  old listing (bytes, long names, counts); a pattern (CybDir.Fits public)
- 2026-10-15 INSTALL.BAS on the 320K disc (tools/): Locomotive BASIC - the disc's files erased on, then
  copied from B to, IDE: (DATA read twice)
- 2026-10-15 COPY with a pattern (`COPY *.CYB B:`: * and ?, disc names and long names; CybDir.Match,
  Keep, Back), the target's FILES.DIR written once. Test: COPY *.TXT C
- 2026-10-15 cyborgos320k2.dsk: CYBADD.BIN and CRUNCH.COM (with their own FILES.DIR) off the
  first 320K disc, which was full (10K free now)
- 2026-10-15 MON from a map: its pages are no longer in its code - SYSTEM.MAP (a text file, made
  and changed by hand; MON MY.MAP 2 maps a program running in slot 2) says where the data is (a
  CyborgOS table, a page, a ROM, main RAM, a slot's memory, a drive's files), how its records are
  laid out (columns: numbers, hex, strings, names, enums), how it is shown (list, data, hex, text,
  words) and where each row leads; walk follows linked lists, deref pointers. MON makes only the
  page asked for (a list 48 rows at a time). CyborgOS: op 15 (a whole table raw into the slot), op
  10 kind 3 (a slot's memory), a turn up to 3 slices. Fixed: Far twice in one statement (one
  result for both: the slot table's names and modes went wrong - and the mode was written into
  the other slot). Test "CyborgOS MON": TEST.MAP walks a list in slot 2
- 2026-10-15 MON (apps/mon), the first application: SCOUT-like pages (slots, memory and its
  pages, hex of any 1K, ROMs and their names, RAM discs, Z, the firmware jumpblock) as 8BML laid
  out by Bml.cls (a class for the web browser later; CyborgOS's own command r - a line as it is),
  the Amiga mouse (Mouse.cls, the mouse card's ports) with a pointer CyborgOS draws (BDOS 131 op
  11: an XOR checkerboard on a cell), Tab / arrows / Enter. CyborgOS: MODE F (84 x 24, all the
  program's), op 10 (up to 2K of a page, an upper ROM or main RAM), ops 12-14 (a slot's store:
  its own 16K pages, 512K at most, 2K blocks through its buffer; freed when its program ends).
  Harness: the screen read from main RAM's page 3 wherever it is (a slot running), a mouse
  ({mdx,dy,b}, NTC_MOUSE). Test "CyborgOS MON". RAM build ends at #9C52 (about 2.4K free on 320K)
- 2026-10-15 MODE per slot (MODE.CYB on Z, BDOS 131 op 9): 2 80 x 25, S 84 x 24 (the console
  80 x 24 and a status strip of 4 columns on the right - the default), W 88 x 23, UW 96 x 21, P
  64 x 32. CyborgOS sets the CRTC itself (Hyp.Scr) and Hyp.Con draws and scrolls by the slot's
  columns and rows (in its bank at #F687; the text page a ring of up to 2K, #F700-#FEFF - room
  since the first stack moved to #F2FC: the TPA unchanged); the bank's BDOS answers 49 (CP/M 3's
  SCB: width - 1, rows). TOP in MODE 2. MODE clears the console. The harness reads the CRTC
  (width, rows, start) for the screen's text. Test "CyborgOS MODE"; the COPY and HELP tests
  split / changed for 24 rows. RAM build ends at #956D (about 4.1K free on 320K)
- 2026-10-15 Main RAM back: the bank image (page zero, the stubs) and FileCall's disc code moved
  into the hypervisor's page (#5300 on), as window data - NTC's new `; @window` ... `; @endwindow`
  in #asm: put in the window hole of the file, copied into the page at the start (FileCall 99);
  FileCall keeps in main RAM only its entry, the RAM disc driver's turn, the window-switching
  copies and its exit. The strings: ob Max 82 (was 130; the longest string sizes every
  parameter, result and temp - 13 buffers), records in rb(127). RAM build ends at #9279 (was
  #9D80): about 4.9K free on 320K, 4.4K with 48 banks (was 2.1K, 1.6K). The Library: ROM build
  ends below #4000 (was #874C against #8800)
- 2026-10-15 System drive Z and almost no built-in commands: at start CyborgOS runs RAMDISC Z
  SYSTEM d (d the boot drive: "CYB d" at #BE80, put there by CYBORGOS.BAS, else A), which copies
  the files d:CYBORGOS.Z names (one a line) to a RAM disc Z that grows a page at a time; keys
  wait meanwhile. Names typed are looked for on Z, then the slot's drive, then the boot drive.
  Built in now only RUN, CLS, QUIT; FG, PS, TOP, KILL, RESET, WAIT, MEM, DIR, CD are programs
  (cmds/*.bas; CybSys.cls asks the hypervisor through BDOS 131) - 1.5K of main RAM back (RAM build
  ends at #9D80, was #A38A). Z is for CyborgOS's programs: the cpm FileSystem takes drives A-Z
  (was A-P), the driver takes FCB drives up to 26 and never Z as a slot's own drive. Test "CyborgOS
  system drive Z"; the tests' expectations for PS (its own slot shows PS.CYB) and DIR (DIR.CYB)
  changed. Fixed on the way: a program's own `call 5` (the commands' Bdos functions) now has ei
  before, di after - the BDOS came back with interrupts on and an interrupt pushed its return
  address over the threaded code (SP), which skipped a later BDOS call (Z lost pages: FS_FULL);
  a slot's first stack moved from #FEFC (44 bytes above the text page) to #F2FC (#F240-#F2FF)
- 2026-10-15 CyborgOS 320K RAM discs: RAMDISC v size (KB / MB, 16K steps, 4MB in all), RAMDISC v 0,
  RAMDISC (the list); any number of them (8). Real CP/M file calls on them (15-23, 33-36, 40):
  read / write in place, any number of files open, true sizes, searches of their own
  directory (extents), DIR lists it; programs run from them. The driver lives in a page of its
  own (cmds/RAMDISC.bas carries it; BDOS 130); Hyp.FileCall offers it each call first; Hyp.Drive
  knows its letters. Main RAM's page 1 is now kept (allocated at start) so no page of it goes to a
  RAM disc. Fix found on the way: two FarPtr results in one statement are one variable (Far's
  inner FarPtr) - the driver copy took a temporary. Tests "CyborgOS RAM discs: files, random
  access" (cpm/rdt.asm), "CyborgOS RAMDISC made, dropped, too big". Test programs moved to
  src/test/cpm (regress.sh's cleanup deleted src/test/*.asm)
- 2026-10-15 CyborgOS 320K CP/M compatibility: a CP/M 2.2 BIOS jump table at (#0001) (console
  entries work, BOOT / WBOOT end the program, disc entries answer "no drive" / error); BDOS 1
  waits in the bank (the slot sleeps: far call #81), 3-5, 7, 8, 10 (line editor), 27-31, 37 in
  the bank; 17 / 18 search FILES.DIR, 24, 35 (size), 36 (random record), 40; the default FCBs
  filled from the command tail before #0100; TAB in the console. The bank: stubs at #EF00 (TPA
  #0100-#EEFF), the font at #F300 (from the hypervisor's page: 768 bytes of main RAM back).
  Main's dead BDOS 1/2/6/9/11 BASIC and PutMem kept as comments. Fix: CLng(VarPtr(x)) of an
  address from #8000 up is negative - not a page 0 far pointer (NearP). Test "CyborgOS CP/M
  calls" (cpmt.asm, RAM and Library: ROM). Harness: CAS IN OPEN of a folder name is "not found"
- 2026-10-15 Two CyborgOS discs, each built from its own sources: build/dsk/cyborgos320k.dsk and
  build/dsk/cyborgos128k.dsk (cyborgos.dsk gone)
- 2026-10-15 CyborgOS 320K (`bas/cyborgos320kb`, now the one built and tested; the 128K version
  kept as `bas/cyborgos128kb`): 320K at least; the hypervisor's own page (the first expansion
  bank's page 0) taken before the slots' banks - the disc buffers there, main RAM's own
  #4000-#7FFF left free (a second screen); up to 20 slots (Control + 1-9, 0; twice 11-20); TOP
  fits 25 rows with 20. Tests: 20 slots, Control + 0, 2 slots on 320K, refused on 128K.
  Harness: a held matrix key ({n}) lasts 12 scans and at least 2 frames (a program looking at
  many keys scans many times a frame)
- 2026-10-15 CyborgOS: HELP is a program on the disc (cmds/HELP.bas, HELP.CYB), its text out of the
  hypervisor (823 bytes of RAM back). Test "CyborgOS HELP from the disc"
- 2026-10-15 CyborgOS: B: alone is CD B (as in CP/M), CD B: is CD B
- 2026-10-15 CyborgOS file speed: a slot's file calls run on in the same turn (up to 32), and a
  record goes into / out of the slot with one ldir when it is in one 16K page (38K COPY: about
  35 s of CPC time down to about 22 s, in the harness). Library: ROM build: 4 slots at most (its
  per-slot arrays sized to that)
- 2026-10-14 CyborgOS output tidied: TOP's first line just "CyborgOS TOP", "(last second)" (fits 80
  columns), "Total memory: n KB   Free memory: n KB" (TOP and MEM); MEM's main RAM as a table
  (address range, what is there), blank lines round the map; HELP: the names with commas, then a
  line each. Main RAM's own page 1 (the disc buffers) taken at the start, so it isn't counted free
- 2026-10-14 CyborgOS: RENAME (cmds/RENAME.bas: on the disc and in FILES.DIR; the hypervisor's BDOS 23
  through the disc ROM's |REN); the disc's FILES.DIR lists every file on it (test "CyborgOS
  command RENAME"). Built round the window, variables are laid out one by one as strings are
  (a section moving whole above the hole wasted 2.7K below it). Library: ROM build of CyborgOS:
  no CD / DIR, shorter HELP (room)
- 2026-10-14 CyborgOS: the memory map moved from TOP to MEM - main RAM's breakdown, then the banks'
  pages 32 a group, two groups a line (test "CyborgOS MEM map")
- 2026-10-14 CyborgOS's 128K version archived in `bas/cyborgos128kb` (not built or tested). Next:
  320K minimum - the hypervisor's data in the first expansion bank's pages (C4 first), main
  RAM's #4000-#7FFF left free, slots = banks - 1
- 2026-10-14 CyborgOS: programs run by their names (not a command: NAME [args] runs NAME from
  the slot's drive, else from A; the rest of the line is the CP/M command tail at #0080); RUN
  NAME [args] forces the disc's (RUN CLS runs CLS.CYB), RUN NAME slot as before. Disc commands
  COPY, ERA, TYPE, PREP (`bas/cyborgos/cmds`, cpm builds with CybDir.cls; only files in
  FILES.DIR). Hypervisor BDOS file calls 13-16, 19-22, 25, 26, 32-34 (Hyp.FileCall, Z80 on the
  cassette calls); RUN, DIR, CD read through it too (FileSystem and Option Buffer left out).
  Test "CyborgOS commands COPY ERA TYPE PREP"
- 2026-10-14 CyborgOS and CYBADD start every background ROM (`Option RomEnable All`: IDE / SD
  interfaces' ROMs too). Option RomEnable: when the ROMs take more RAM than AMSDOS's, cpcfw
  moves its top (event block, heap / Memory tables limit) under it; it stops (with the address
  the ROMs reached) only when the program itself would overlap
- 2026-10-14 CyborgOS: MEM as TOP's first line (slots, banks, free pages); TOP shows the memory
  (KB) and its page map under the slots
- 2026-10-14 CyborgOS: plain CP/M .COM files (no AMSDOS header) run when FILES.DIR or NAME.HDR
  has a 64 byte entry for them (disc name, length, long name ...; RUN by a long name too);
  CYBADD.BIN (a CPC program) writes FILES.DIR, `DIR` lists it, `CD` picks a slot's drive (the
  disc system's |letter); a .COM without an entry is not run. The entry code is Z80
  (Hyp.cls). AMSDOS's messages kept off the console (TXT VDU DISABLE). Program names moved into
  each bank. Tests "CyborgOS .COM with FILES.DIR / .HDR" and on the real ROMs (realcpc)
- 2026-10-14 CyborgOS: RESET [slot] (the slot as before its command line was first opened: its
  program stopped, nothing kept; this slot opens again at once); Option Memory CPCExpansion 193
  (48 banks: the page tables no longer fit for all 64 of 4MB). Test "CyborgOS RESET"
- 2026-10-14 CyborgOS: up to 16 slots (half the extra banks: 16 on 2MB or more); Control + a
  number twice quickly (Control held, 0.3 s) is slots 9-16, a single press waits 0.3 s only when
  there are more than 8 slots; each slot's command line kept in its bank (#F68F / #F690 - 16
  in BASIC arrays did not fit the Library: ROM build). Harness: {n,m} holds keys together;
  realcpc: down / up (8A: Control). Tests: 16 slots, Control + 3 twice / once
- 2026-10-14 CyborgOS: the TOP screen drawn straight into screen memory (Hyp.Say: about 0.1 s,
  was about 0.7 s through TXT OUTPUT); the TOP command back, printing the table once into the
  slot's console (test "CyborgOS TOP command")
- 2026-10-14 CyborgOS console in Z80 (Hyp.Con, Hyp.Show): the slot's page 3 in the window once,
  the characters read where the program collected them, page (ring) and screen written in one
  routine, page / screen pointers stepped along a run, the glyph loop unrolled, screen addresses
  from SCR GET LOCATION (was SCR CHAR POSITION per character), SCR HW ROLL to scroll (was 4 TXT
  calls); the console state in the bank (#F682). The BASIC it replaced (Collected / Out / PutC /
  NewLine / RowA / ClsT / ToFront) kept in Main.bas as comments, with why. The bank no longer
  hands over at each line end (at the slice's end: one BASIC turn per line less). Real ROMs: 16
  lines a second (was 8; harness: about 100,000 T a line, was 216,000). realcpc PROF=file: a
  profile by address (main RAM, bank, lower / upper ROM), "profon" in the script restarts it
- 2026-10-14 CyborgOS speed and fixes: text for the front slot written straight into screen
  memory (Hyp.Text: the firmware's matrices via TXT SET M TABLE, SCR CHAR POSITION; mode 2),
  the slot's page a ring of 25 rows (no copy to scroll), the control-code scan in Z80
  (Hyp.Printable); keys answered in the bank (#F681: BDOS 1, 6, 11 with no switch); time
  slices of 6 interrupts handled in Hyp.Run (no BASIC between); BDOS 9 fetched with
  Memory.Copy. Fixes: the screen didn't scroll on the real ROMs (the firmware scrolls only at the
  next character below the last line); TOP closed at once (the ESC of Control + ESC) and
  refreshed - now drawn once, Control + ESC / Control + a slot go back, the TOP command is gone;
  firmware calls come back with interrupts on (di after them, or an interrupt is pushed into the
  thread); the upper ROM is off while a program runs (Library: ROM had the keyword ROM over the
  bank's top 16K). Library: ROM: Option Buffer has no buffer to place (the ROM has its own), and
  the ROM's Memory tables start at the end of the program below the window when the arrays went
  after an Option Reserve range. Harness: screen memory text (mode 2) for cpcfw, the RAM under
  the keyword ROM, TXT SET M TABLE / SCR CHAR POSITION / ROM enable stand-ins, NTC_PROF
  (a profile), NTC_LIMIT, NTC_PEEK; realcpc: Control + 1-8 / ESC (\c1 ... \ce). Measured on the
  real ROMs: about 8 lines a second (was 3)
- 2026-10-14 CyborgOS: the front slot gets half the turns, a program with no key gives up its
  turns until the clock moves, characters out collected in the bank (128) and written in runs,
  the system keys from an interrupt class (Hot.cls; Control held, numbers in turn), TOP
  (Control + ESC), every register kept for the programs (IX, IY, alternates). 4MB: 64 banks
- 2026-10-14 **CyborgOS** first version (`bas/cyborgos`, cpcfw, `build/dsk/cyborgos.dsk`): slots in
  whole 64K banks running cpm-built programs (.CYB = with an AMSDOS header) at #0100; BDOS at
  #0005 as far calls into the hypervisor; interrupts stop a program and hand back; per-slot text
  pages, a shared command line (RUN / FG / PS / KILL / WAIT ...), Control + 1-8. Checked in the
  harness and on the real 6128 ROMs. See docs/cyborgos.md for what is next (the interrupt classes
  as the scheduler, files, drivers, speed). Core: the bank switch at #0040-#004C in every cpc /
  cpcmin / cpcfw start code; `Option Buffer address` (the 2K buffer out of the program); cpcfw
  FileSystem Read / ReadByte read a #1A in a binary file as a byte (AMSDOS reports it as a soft
  end of file); the harness gives #0F (hard end) at the end of a binary file

---

## todo

- LUNs allocated, not assumed (2026-10-18): two RATBOXes on one MODEL both take LUNs 1 up - rat 1 of
  each box is LUN 2, their habits and breeding mixed, and both save RATBOX.SAV. MODEL to hand LUNs
  out: "A n" - n free LUNs reserved for the caller (back: the first, or "full"), "F a n" - freed
  (a box ended, a rat dead for good); a LUN's owner kept in NAME.LUN so a saved box gets its own
  back. RATBOX asks for its LUNs at the start (RAT passes "A" through: "!model A n") and keeps the
  first in its save; the save's name from the box (RATBOX NEW 3 3 BOX2: BOX2.SAV)
- NEURAL as a recogniser (2026-10-18): an NPC remembering someone by their tags (shirt, shorts,
  hair, glasses ...) and asked later with some changed - Q already gives the best record and a
  score. To add: a weight a prop (glasses, shirt cheap to change; hair, height not - "~2" in the
  file), the second best's score too (83 against 80 a guess, 83 against 30 near sure), "R tags" -
  "who score margin", and trained again on a recognition (a "glasses=yes" learnt as one of yours)
- Cyborg Pluto Nuclear Tight Security (2026-10-18): the CPC edition of NTS - a short list of NTS's
  features, as separate small programs, one a slot (not one big program). Keys and plaintext stay
  on the CPC; the TCP/IP stack is on the M4 (a separate microcontroller), so the network only ever
  carries what KEYMAN has encoded (the John Wick point, shown on a machine anyone can see through).
  (The engine, ENC / DEC, KEYMGR's LIST / JPEG / ENTROPY, and KEYMAN as a service are built - see
  done and docs/pluto.md; what is below is the rest: KEYMGR's DH, SCIF, PEER, FLOPWR, the SD
  container, KEYMAN into its 512K store, and the larger-key banked path.)
  - KEYMAN, the service: loads the keys from a KEYS folder (KEYS/NAME.KEY - the ROM's bytes; its
    size says which: 256 microZOSCII, 64K / 128K ZOSCII) into its store (512K at most) and encodes
    / decodes on request; no message ever gives out a key's bytes (a monitor can still look - not
    the point). A request names 1-3 layers, any mix and order, each a method and its own key:
    z ZOSCII, u microUNSIGNAL, b microBRICS - E z:k1 u:k2 b:k3 text / D ... hex (short messages:
    realtime messaging, CyborgSCIF), EF / DF layers infile outfile (files, any size - sequential,
    slow on a CPC but steady), LIST (names, sizes), RELOAD. The inner loop in assembly
  - KEYMGR, the user's key manager: keys from a JPEG (a chosen size of it), keys by 4 x DH (4
    exchanges, ~64 bytes each -> a 256-byte microZOSCII ROM; the DH maths in Z80 assembly - a
    few minutes on a CPC, seconds on CVM), list, delete, rename; tells KEYMAN to RELOAD
  - SCIF: the CyborgSCIF client (chat), every message through KEYMAN
  - PEER: peer-to-peer messages, CPC to CPC (or a PC), through KEYMAN
  - ENC / DEC: a file encoded / decoded, the layers and keys on the command line
  - FLOPWR: the CPC's USB stick - formats a floppy and writes it with direct sector writes (the
    FDC claimed as FLOPPY does): one raw stream over the tracks, no directory, no names; always
    the WHOLE disc, whether a "hello" or as many files as fit (their names and lengths inside the
    encoded data); the rest filled by encoding random bytes with the same layers and keys (so the
    disc is one stream with the same statistics throughout - nothing shows where the data ends).
    Its own format (40 x 9 x 512 = 180K, 10 sectors a track = 200K, or bigger sectors). A standard
    data disc as an option, for a PC with a USB floppy drive
  - SD cards (the Next's microSD; on a CPC the M4's or Albireo's, through UniDOS - FAT): Pluto's
    encoded files written there for a PC to read directly (only the decoding needs the keys - NTS on
    the PC); or a container file (PLUTO.BIN, a fixed size): FLOPWR's whole-disc stream as one file -
    always full, any number of files inside it (names and lengths encoded), the rest encoded random
    bytes: one opaque file of the same size whatever it holds
  - Settled (2026-10-18): six layers - z ZOSCII, u UNSIGNAL, b BRICS (16-bit / byte), mz microZOSCII,
    mu microUNSIGNAL, mb microBRICS (8-bit / nibble) - the micro ones for key exchange, usually the
    inner layer; the reference is Julian's protocol creator (unsignal-creator.html: its C version
    built here to check the CPC against, byte for byte), but nibbles high first as the C# does (the
    docs fixed later); block sizes count message bytes (micro: 255 at most)
  - KEYMGR: keys from an ENTROPY folder too - the ROM generator's way (ROMGenerator.cs): 5 files
    from the folder (any kind: MP3s, JPEGs...), each with a start and a direction (forward /
    backward, wrapping) from entropy sugar - on the CPC: the 300Hz clock, the R register, the
    times between keys pressed, free memory, slots, files - each output byte the XOR of the 5;
    128K (or a chosen size). AMSDOS reads one file at a time: the 5 are read in turn, each XORed
    into the key in the store (o = (i - start) mod len, + len while under the size)
  - Needed from Julian: the microUNSIGNAL and microBRICS specs (or the PHP / C# code) and test
    vectors - the CPC's output must decode on the PC versions; the CyborgSCIF protocol; the DH
    channels (another KEYMGR at the other end, each exchange through a different relay - four
    PHP mailboxes on four servers?) and group (768-bit Oakley group 1, 64 bytes of each secret?);
    which bytes of a JPEG make the key (the first n, or the image data past the header); PEER
    direct TCP (the M4 listening) or through a relay; Http.cls: POST (NTS's protocol) or GET forms
    on the server
- CVM, the CyborgOS virtual machine (docs/cvm.md, a draft): a Z80 with only what CyborgOS needs - no
  gate array, CRTC, FDC, firmware, UniDOS or M4: 16K pages in four windows (64MB at most), a few
  ports (pages, timer, clock, the screen page, keys), host calls for files (the host's folders as
  drives), sockets and block copies, a text screen page the host draws. NTC gets a cvm platform;
  CyborgOS is rebuilt on it, the .CYB programs unchanged. Still a Z80 inside: every program keeps
  its 64K and the CPC's limits; what grows is the slots (hundreds) and the speed. Slots 1-20 keep
  the hotkeys (Control + a number, twice for 11-20), beyond 20 only FG n (services, models,
  servers); the hypervisor's tables (slots, claims, ports - 8 now) must grow, and the scheduler
  give turns only to ready slots. Hosts: one C++ source for Windows and the Xbox One (CVM_UWP: the
  UWP app, Developer Mode; without it a Win32 cvm.exe - no WinAPE needed to run CyborgOS), then
  Linux (and the minimal-kernel boot) and the browser (WebAssembly). Order: the spec settled, the
  core in C with a terminal test host, NTC's cvm platform, CyborgOS booting on it, the Windows
  host, the Xbox build. To settle: the pages to start with (4MB or all the host has), the slot
  limit (250 - a byte, BDOS 131 as it is - or two-byte slot numbers), the text screen's largest
  size (128 x 32?), the timer (fixed 300Hz?), sound (an AY-style port or host calls)
- KEYMAN with CyborgSCIF: realtime messaging encoded on the CPC (Julian's figure: about 57 keys a
  second for one layer of ZOSCII in NTC BASIC-like code; the assembly loop faster)

- More servers on ports - all running at once, at the mercy of 4MHz: an X Window style display
  server (programs draw through it), and once ports reach outside (the M4, a serial card) a web
  server, a BBS
- Later: a minimal Linux kernel booting natively into a virtual Z80 running CyborgOS (proven with
  SymbOS)

- Scrollback (built, switched off - `#Const SCROLLBACK` in Main.bas and `CN_SB` in Hyp.cls's Con, set
  both to 1): Shift + Up a screen back, Shift + Down one on, any other key the live screen; 48 rows a
  slot (2 screens), the first 80 columns, in a 16K page for 4 slots taken after the RAM discs are
  reclaimed; rows copied 8 bytes at a time through the stack (no buffer). Off because it costs 526
  bytes of main RAM (#9DB4 -> #9FC2); to cut: the drawing and the keys into the service page, one
  history page for all slots (about 200-250 bytes left: saving rows as they scroll off has to be in
  Con)

- UniDOS next: random reads by seek (Ctrl J 6 with Ctrl J 5 instead of CAS IN CHAR: BDOS 33 and
  a slot taking the read stream back without reading from the start), whole files straight into
  a bank (Ctrl J 5: COSLOAD, RUN), the drive map kept over a reset (the hypervisor's page)
- Own filesystem drivers (FatFS from UniDOS's open source, X-Mass / Albireo / M4 low level) in
  driver pages, no UniDOS ROMs needed - the RAM disc driver's way (a page each, offered the file
  calls first): needs the hypervisor to offer a call to more than one driver page

- Folders on RAM discs (the directory entry has a folder byte already): CD J:\WORK, a slot's
  folder, MD / RD, paths in COPY, ERA, TYPE, RENAME
- Idea (Julian, 2026-10-17): random access on a stream-only drive by a file per record or block -
  a folder named as the file (DATA.DAT/), one small file each (8.3 names: up to 65,534 in a
  folder); each access opens, reads or writes, closes. Any size, several files open, survives a
  reset; costs a cluster per piece (16K blocks better than 128-byte records), an open per access,
  and a format only CyborgOS reads (COPY to join / split). Alongside option 1 (the file in
  expansion RAM while open, written back at close) for files too big for RAM
- Random access on discs (UniDOS: Ctrl J seek); exact lengths for files COPY writes (CP/M
  writes whole records, and AMSDOS / UniDOS add a ^Z: a 20 byte file is 129 bytes)
- FLOPPY: two sides, 80 tracks; FLOPPY A B (disc to disc); a blank disc formatted (FLOPPY FORMAT A?)
- The printer and the punch (BDOS 4, 5; the BIOS's LIST, PUNCH) - drivers, like RAM discs
- RAM disc: save / load a whole RAM disc as one disc file; QUIT warns when one holds files
- 128K version (only when asked): the BIOS jump table and the default FCBs are the parts worth
  bringing back for console programs that work the hardware
- MODE S's status strip: what it shows (now only the slot's number)
- MON: speed (a page takes 2-3 s to make, 1 s to draw: its map, 8BML and layout in BASIC a
  character at a time; the firmware's interrupts and the hypervisor take a third), forms, a
  disassembler (view dis) and a detailed memory map as overlays, far pointers in walk (a page and
  an address), text view by a width (a console's page), names for the firmware's entries;
  CyborgOS handing the mouse to one slot at a time
- MON's map tool (separate from NTC BASIC, so it can change and be fixed on its own): hints put
  in the source before the assembler (a hints file beside it), then the hints and the
  assembler's output (any assembler that gives symbols - NTC BASIC relies on none) into the tool:
  a map for MON, and map.log (what matched, what disappeared ...)
- A debug wedge class compiled into a program: MON takes control through it (a low part in the
  program, a high part that can flex) - watches, and breaks using NTC BASIC's breakpoints; the
  state comes back raw as the rest does
- NTC's cpm platform: its 80 columns (Tab) from BDOS 49 when CyborgOS answers it
- More text files beside CYBORGOS.Z (settings ...); the ROM disc as a source for Z
- Faster boot: prebuilt Z images (CYBORGOS.Z1, .Z2 ...: the RAM disc's 16K pages ready to load,
  made by a tool) instead of copying file by file; CYBORGOS.Z (text) stays for flexibility