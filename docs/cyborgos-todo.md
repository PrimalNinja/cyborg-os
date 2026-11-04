# CyborgOS - todo

Open work for CyborgOS, by component - the numbers are [components.md](components.md)'s; bugs are in
buglist.md under the same numbers; what is done is in [cyborgos-done.md](cyborgos-done.md). Items for NTC
BASIC itself are in NTC's todo.md. 71-75: components that had no number; 76 on: future components
(no code yet) - one keeps its number when it is built. The 128K version is frozen (changed only when asked).

## 1 C0 CPC 320K+
- The claim tags (one list, C0 claiming what it drives), a TIME command (RTC, Nova, M4, NTP; the
  MSX's clock), a Net4CPC / GR8NET W5100 driver, optional listening (off by default), serial,
  CPC-CPLink with the Pi as a coprocessor (plugins, slots on the Pi; the Next's Pi Zero), speech,
  NOVA and MF2 utilities.
- On a real M4: does it take "A:NAME" (CyborgOS's names)? 1984's M4 doesn't (tools/emu84).
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
- Idea (Julian, 2026-10-17): random access on a stream-only drive by a file per record or block -
  a folder named as the file (DATA.DAT/), one small file each (8.3 names: up to 65,534 in a
  folder); each access opens, reads or writes, closes. Any size, several files open, survives a
  reset; costs a cluster per piece (16K blocks better than 128-byte records), an open per access,
  and a format only CyborgOS reads (COPY to join / split). Alongside option 1 (the file in
  expansion RAM while open, written back at close) for files too big for RAM
- Random access on discs (UniDOS: Ctrl J seek); exact lengths for files COPY writes (CP/M
  writes whole records, and AMSDOS / UniDOS add a ^Z: a 20 byte file is 129 bytes)

## 2 C0 CPC flat
- **AUTOEXEC on the C0 build** (2026-11-01, found checking the buglist): the C0 build has no
  kernel, so no AUTOEXEC and no Shift skip - say so in HELP AUTOEXEC, or give it one

## 3 C0 CPC 128K
- **The 128K build's disc buffers at #C000** (the lost session, 2026-11-02): its disc buffers sit
  where the console page / a slot's page is on the other builds; to move or to retire with the
  build (buglist 3: build it or retire it - a question)
- 128K version (only when asked): the BIOS jump table and the default FCBs are the parts worth
  bringing back for console programs that work the hardware

## 4 C0 ZX Spectrum Next
- **Next and MSX receiving slots** (Julian's list, 2026-11-01): LISTEN / ACCEPT in their C0s (both
  say "Never AT+CIPSERVER: nothing listens") so SLOTD runs there - also 5, 39
- **Next: the Russian / Spanish font** seen in ZEsarUX only, never on a real Next (2026-11-01)

## 5 C0 MSX
- **GR8NET network driver** (Julian's list, 2026-11-01): the MSX has no network yet ("the GR8NET's
  TCP/IP UNAPI to come")
- **AUTOEXEC's Shift skip on the MSX** (2026-11-01): its runtime has no key-state read - it always runs

## 6 C0 vCPC
- **RAMDISC on the vCPC** (Julian's list, 2026-11-01): "RAMDISC needs CyborgOS 320K" with 4MB there -
  vcpc.c answers BDOS 130 as unsupported ("to come: its driver in a page")
- **Typed Cyrillic on Windows** (2026-11-01): tried with ReadConsoleInputW, broke Control+T,
  reverted; redone the same day with _getwch (_getch's wide twin: the same control codes) - built
  for Windows, to try on a Windows console (buglist 6)

## 7 The kernel
- **The pages a 4 MB CPC can't map** (2026-11-01: MEM now says "Not mapped") - NTC's page tables (3
  bytes a page) must fit under HIMEM, which ROMs' workspace lowers: room for them (C0's arrays
  smaller, the tables elsewhere) gets those pages back - Julian's call (also 1)
- **Upper-casing Russian and Spanish at the command line** (Julian's list, 2026-11-01): codes 128-255
  aren't case-mapped (KOI8-R, Latin-1)
- **Russian typing** (Control + Space, LANG RU) on the CPC and the Next: written, never tried (2026-11-01)
- C2's main RAM (Julian, 29 Oct - double buffering not CyborgOS's): main RAM's own #4000-#7FFF is kept
  as "a 2nd screen" (MEM) and nothing uses it. C0 moved its screen there and took #C000-#FFFF for code
  (16K more room, docs/cyborgos.md 0a); C2 could do the same (Option HighCode), or at least put C0's
  data that is reached through the window there (the disc buffers, the memory tables): C2 has about
  1.5K left under #A5F0
- **A slot's own colours outlive its program** (Julian, 2026-10-29: VDU run, killed - its colours
  stay in the slot, RESET too). Seen in the code: KERNEL's ResetSlot never clears CINK (#F6E5-7)
  nor calls Inks; EndTask (KILL's way, a program's end) does clear them - why KILL leaves them
  still to find (the program not st 2 when killed? GUI sets them itself: GuiScr.cls). Fix: both
  clear CINK and put the console's inks back when the slot is in front

## 13 DIR
- DIR on an M4 drive (its own listing: C_READDIR) - now "can't be listed", as plain AMSDOS.

## 15 CV
- **E: alone, then a device** (Julian, 2026-10-29): `c:` then `ide:` gives C: IDE:; a letter with no
  path that UniDOS doesn't know (E:, F: ...) says "no such drive" instead - take it, the device typed
  next gives it its path. Tried (CV: r = 0 for C-P): UniDOS's A: ended up M4:CPM in its
  !UNIDOS!.NVM - taken out until that's understood (maybe also Julian's "CD on the M4 reset to
  BASIC in that folder").

## 24 FLOPPY
- FLOPPY: two sides, 80 tracks; FLOPPY A B (disc to disc); a blank disc formatted (FLOPPY FORMAT A?)

## 25 RAMDISC
- Folders on RAM discs (the directory entry has a folder byte already): CD J:\WORK, a slot's
  folder, MD / RD, paths in COPY, ERA, TYPE, RENAME
- RAM disc: save / load a whole RAM disc as one disc file; QUIT warns when one holds files

## 27 TOP
- **TOP: only the slots in use** (Julian, 2026-10-29): TOP to list the active slots (not those
  shown "-"); TOP FULL all of them, as now.

## 29 MODE
- MODE S's status strip: what it shows (now only the slot's number)

## 37 DUMP / REVIVE
- **A moved slot loses its store, and its screen** (Julian, 2026-11-01: YING RCOPY'd CPC to vCPC -
  blank until a key, then its page gone): DUMP / RMOVE / RCOPY carry #0100 to the TPA's top only; the
  console is above it (C0's) and the store isn't kept - YING lays its lines out through the store
  (LBUF), so its first redraw reads an empty store. To do: the store's 2K blocks sent after the
  program (DUMP, RMOVE, RCOPY; REVIVE and SLOTD put them back); and a moved slot asked to redraw
  (a key or message queued after REVIVE) - also 38, 39, 11

## 38 RMOVE / RCOPY
- **Verify live moves** (Julian's list, 2026-11-01): vCPC to CPC - accepted by the CPC's SLOTD, the
  moved program never seen running there; CPC to CPC - never shown working

## 47 MON, MON2
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

## 49 RAT, RATS, RATBOX, MODEL
- LUNs allocated, not assumed (2026-10-18): two RATBOXes on one MODEL both take LUNs 1 up - rat 1 of
  each box is LUN 2, their habits and breeding mixed, and both save RATBOX.SAV. MODEL to hand LUNs
  out: "A n" - n free LUNs reserved for the caller (back: the first, or "full"), "F a n" - freed
  (a box ended, a rat dead for good); a LUN's owner kept in NAME.LUN so a saved box gets its own
  back. RATBOX asks for its LUNs at the start (RAT passes "A" through: "!model A n") and keeps the
  first in its save; the save's name from the box (RATBOX NEW 3 3 BOX2: BOX2.SAV)

## 50 NEURAL, ASK, WATCH, PET, PROBE, GREEN
- NEURAL as a recogniser (2026-10-18): an NPC remembering someone by their tags (shirt, shorts,
  hair, glasses ...) and asked later with some changed - Q already gives the best record and a
  score. To add: a weight a prop (glasses, shirt cheap to change; hair, height not - "~2" in the
  file), the second best's score too (83 against 80 a guess, 83 against 30 near sure), "R tags" -
  "who score margin", and trained again on a recognition (a "glasses=yes" learnt as one of yours)

## 52 TASKMAN
- **TASKMAN's VDU path against a real VDU server** (Julian's list, 2026-11-01): written, untested

## 53 ENC / DEC, KEYMGR / KEYMAN
- **KEYMAN doesn't load 128K keys** (the lost session, 2026-11-02; buglist 53 CONFIRMED: LoadKey
  reads 8K at most and refuses 8K exactly; the 16K pool holds two): the keys into the slot's
  store (op 12, up to 512K), Zc reading key bytes through a 2K window (op 14); "? key too big"
  told from "? no such key"
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
- KEYMAN with CyborgSCIF: realtime messaging encoded on the CPC (Julian's figure: about 57 keys a
  second for one layer of ZOSCII in NTC BASIC-like code; the assembly loop faster)

## 54 GUI, GUIDEMO
- **GUI ports** (Julian, 2026-10-29): GUI P=name - its port (GUI by default), so several GUIs run at
  once (local, remote heads); GuiCli.Port name, GUIDEMO P=name. Started: GUI.bas takes P=, shows
  the port and RGUI's page in its menu strip (not built yet); GuiCli / GUIDEMO to do.

## 57 Z and the Next archive
- **Z as a search path** (Julian with the lost session, 2026-11-02; the decision, not yet built):
  Z is a search path, the boot drive by default and pointable by the user; nothing is copied to a
  RAM disc at boot; the Next's boot archive (CYBORGOS.ARC) goes; the help pages are out of Z (done
  2026-11-03: HELP.CYB and the pages out of the archive entry - HELP reads C:CYBORGOS/HELP/ on the
  Next, the kernel finds commands on the boot drive's C/ - and the archive is 133632 of 163840)
- More text files beside CYBORGOS.Z (settings ...); the ROM disc as a source for Z
- Faster boot: prebuilt Z images (CYBORGOS.Z1, .Z2 ...: the RAM disc's 16K pages ready to load,
  made by a tool) instead of copying file by file; CYBORGOS.Z (text) stays for flexibility

## 59 The builder (and NTC)
- NTC's cpm platform: its 80 columns (Tab) from BDOS 49 when CyborgOS answers it

## 60 Help pages
- **More translations** (Julian's list, 2026-11-01): .HRU / .HES exist for AUTOEXEC, DIR, HELP, LANG,
  PS, TYPE only - the rest English
- **The help pages, all of them** (Julian, 2026-10-29): every command and program its .HLP - CRUNCH,
  GUI, GUIDEMO, RVDU's KEYS, M4TIME, NTPTEST, RTCTEST, SPEAK, SIDTEST, ENC, DEC,
  KEYMAN, KEYMGR, TICKER, LINES, GREEN, WATCH, ASK ... (help/ has 45; the commands are more).

## 56 INSTALL.BAS
- **A failed |COPY on a real CPC** (2026-11-01): the installer now traps it (ON ERROR, "Not copied:
  NAME"); whether UniDOS raises a BASIC error for it is to see on the machine

## 57 Z and the Next archive (room)
- **CYBORGOS.ARC is 384 bytes from full** (2026-11-01: 163456 of 163840 - this pass's fixes took
  1.1K of its 1.5K): the next change to a command in it, or KERNEL.CYB, needs room made - a
  bigger archive (11 blocks) or fewer pages in it

## 62-66 The test suites (2026-11-01, moved from the buglist: test work, not CyborgOS faults)
- 62: tests for LANG, FG, RESET, AUTOEXEC's file, MON2, ENC / DEC, GUI on the CPC (a reference each);
  masks for each test's volatile parts so a harmless change doesn't re-record many references
- 63: msxregress polls for the prompt instead of waiting fixed times
- 64: vcpctest compares whole screens with references, as the other two
- 65: nextrun.js compares (the tile map read through ZRCP as text); nextkeys.js / nextrun.js poll
  the Next's RAM instead of sleeping 30 + 12 + 25 s
- all: a build stamp each suite checks, so a stale image fails
- 66: espsim's nettest.js run with the others; 38: a keyboard-free check of a live vCPC -> CPC move

## 71 The Pi side (pi/)
- **Pi volumes** (Julian, 2026-10-27; docs/cyborgos-pi.md 5a - the Pi side done: pi/svc/disk.js, 26 tests; the CPC side to do): `/home/cyborgos/<volume>/` on the Pi,
  a volumes.json there keeping them and their mounts (persisting); PIVOLUME on the CPC (list, NEW,
  DROP, MOUNT name X, UNMOUNT X) as RAMDISC is; the Pi announcing the mounted ones at the start, C0
  binding their letters; 4 at most announced (mounted automatically) at the start - more by hand -
  letters in A-P for CP/M programs. Random access as
  the RAM discs have (the Pi's file system, not AMSDOS): a drive driver beside RAMDISC's, its record
  calls as REQs (READ h rec, WRITE h rec + 128 bytes).

- **PITERM and PI** (the lost session's work, not in any surviving zip; docs/cyborgos-pi.md still
  says "to come"): C0 owning the link with the BDOS 131 channel ops (OPEN / REQ / DATA / CLOSE for a
  slot), then PITERM (a slot as the Pi's terminal, on pi/svc/term.js, which is done) and PI (PI
  TIME / LIST / RUN / GET / PUT on run.js and store.js). With PI RUN the CPC compiles NTC BASIC on
  the Pi (node cli.js) - the development loop EDIT -> PISHELL -> compile -> PISHELL back closes.
- **PISHELL small** (Julian, 2026-11-04): PISHELL (NTC src/apps/pishell: the Pi's store from a bare
  CPC over the CPLink ports) is useful on its own if it is small enough to run from a floppy - or
  as an RSX in a ROM that just works. The ROM is the lower priority of the two.

## 76 vCPC spawning and the cluster
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

## 77 A second instruction set
- **A second instruction set** (Julian, 2026-10-29: Z80MMX / Z80AI): one opcode swaps to it
  (it would crash a real Z80 - never reached there); the new set has its own flow control, so a
  whole loop runs in it, and one instruction swaps back. Known once at start-up, not probed each
  time: the environment says so - a BDOS answer (CybSys's capabilities: real CyborgOS "none"),
  or a port / memory byte the build sets. Then a branch on that flag picks the loop. To decide:
  the same 64K or a space of its own (flat 4MB?); which Z80 registers carry across; the swap
  opcode clear of the Z80N's (ED 23-36, 8A, 90-95, A4-AC, B4, B7, BC), Z180 / eZ80 / R800's and
  the emulators' traps; the mode and the new set's registers in a slot's state (DUMP / SEND)

## 78 POSIX slots
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

## 79 Other machines
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

## 80 CVM
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

## 81 Servers on ports
- More servers on ports - all running at once, at the mercy of 4MHz: an X Window style display
  server (programs draw through it), and once ports reach outside (the M4, a serial card) a web
  server, a BBS

## 82 A native Linux boot
- Later: a minimal Linux kernel booting natively into a virtual Z80 running CyborgOS (proven with
  SymbOS)

## 83 Own filesystem drivers
- Own filesystem drivers (FatFS from UniDOS's open source, X-Mass / Albireo / M4 low level) in
  driver pages, no UniDOS ROMs needed - the RAM disc driver's way (a page each, offered the file
  calls first): needs the hypervisor to offer a call to more than one driver page

## 84 Printer and punch drivers
- The printer and the punch (BDOS 4, 5; the BIOS's LIST, PUNCH) - drivers, like RAM discs

## 85 VER
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

## 86 Generative model: bigger than one slot (GEN / MIND / GRU)
- Built 2026-11-04: GEN (completer), MIND (a model served on a port), GRU (the terminal), and
  Cynthia (CYNTHIA.MDL, a chitchat model).
- Done 2026-11-04 (later): k-trit weights - Net reads k balanced-trit planes (DotK, Horner,
  add/sub only); shipped models are k=2 (9 levels), H=64, ~29.5K. Fixed GEN's spelling. k=4/k=8 a
  training flag away; the table-lookup inner loop (section 1 / cyborgos-generative.md) is the next
  speed step. Still to do below: the width half (store-backed MIND), the ports. The port split - "the model is a port" - is the start;
  the model is only ~100K weights because that is what fits as a flat array in one slot. The rungs
  to grow it (cyborgos-generative.md section 4):
- Rung 1 - a store-backed MIND (one port, up to 512K): lift Net's MAXH/MAXV (128) caps and give
  Net a store-backed weight reader (window 16K in, dot that chunk, next). ~2M ternary weights at
  4 a byte; ~20x the model, ~4-5x wider (weights go as H^2). On-fleet work, no new training to
  prove the plumbing. ~20 s/char on a real CPC, sub-second on the vCPC.
- Rung 2 - 4 ports, up to 2MB: either a sharded single model (all ports run every char, ~4x
  slower) or a mixture of experts (a gate picks one expert a char; 4x the params at ~1x compute -
  the weights stay behind each port, only the small hidden state crosses). Needs: an async
  scatter/gather on ports (PortCall is one-at-a-time today), and for MoE, MIND to take an injected
  hidden state and return it (it keeps its own state now). The trained 2MB MoE itself is off-fleet
  (a GPU box); the fleet serves it.
- Beyond (design only): N ports across online vCPCs (~512MB at 1000 ports, top-1 routing keeps
  per-char compute at one expert); fan-in decision over parallel candidate answers (a judge MIND,
  RAT, or executing the candidates on a vCPC - GEN proposes, the OS runs, RAT decides).

## 87 RMOVE / RCOPY / SLOTD: packet-based with confirmation (Julian, 2026-11-04)
- The slot migration over TCP is paced by timing (the sender streams, the receiver keeps up),
  which races under load - vcpctest's rmove fails intermittently. Make it packet-based with
  confirmation: each block sent, then an ACK from the receiver before the next; a final ACK that
  the whole slot (DUMP's 64K + state) arrived and REVIVEd before the sender closes/kills the slot
  here (RMOVE) - so a lost or slow packet retries or aborts cleanly instead of corrupting or
  half-moving. RCOPY the same, minus the local kill. Touches SLOTD and RMOVE/RCOPY on CyborgOS and
  the vCPC's TCP path (cyborg-os-vcpc/src/vcpc.c). Not today's generative work.
