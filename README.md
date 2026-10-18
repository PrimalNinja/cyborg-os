# CyborgOS

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

A hypervisor for the Amstrad CPC, written in NTC BASIC. It runs CP/M programs - NTC BASIC
programs built for the `cpm` platform, or any CP/M 2.2 program that keeps to the BDOS and the
BIOS - each in a whole 64K bank of its own, many at once, switched with a keypress.

## Built with NTC BASIC

CyborgOS is not a compiler. It is written in NTC BASIC and built by the NTC BASIC compiler,
which lives in its own repository. Get that first - the hypervisor is built for the `cpcfw`
platform, the programs and disc commands for `cpm` with an AMSDOS header (`.CYB`). Everything
here is `.bas` / `.cls` source.

## The two versions

| | CyborgOS 128K | CyborgOS 320K |
|---|---|---|
| What it is for | one program with a big TPA: console programs, including ones that work the CPC's hardware directly | the real hypervisor: many programs at once |
| Needs | a 6128 (128K) or more | 320K or more (a 256K expansion) |
| Program space | #0100-#F4FF, about 61K | #0100-#EEFF, 59.5K |
| Slots | 1 on a 6128, up to 16 | half the extra 64K banks: 2 with 256K ... 20 with 3MB or more |
| CP/M | the BDOS console and file calls | a CP/M 2.2 BDOS and BIOS jump table, default FCBs from the command tail, RAM discs with real random access |
| Sources | `cyborgos128kb/` | `cyborgos320kb/` |
| Status | frozen: changed only when asked for | where new work goes |

A program built for CyborgOS runs on both: the slot is the same 64K bank from #0100.

**128K.** A program has the bank switched in as all 64K (the gate array's RAM setting C2), so it
has more room than the usual CPC CP/M (Amstrad's CP/M 2.2 gives about 41K) and still reaches
every I/O port: the CRTC, the sound chip, the PPI and the rest are not touched by the banking.
It suits programs that need a large TPA and drive the hardware themselves. Archived as it was on
2026-10-15 - not built or tested any more.

**320K.** The first expansion bank's 16K pages are the hypervisor's own (the disc buffers, the
RAM disc driver), main RAM's #4000-#7FFF is kept for a second screen, and half of the other
banks are slots (2 with 256K, 4 with 512K, 8 with 1MB, 16 with 2MB, 20 with 3MB or more). Each
slot has its own command line and console with its own MODE (80 x 25; 80 x 24 with a status
strip, the default; 88 x 23; 96 x 21; 64 x 32), switched with Control + a number; Control + ESC
shows TOP. The programs run in turn - the one in front gets half the time; an interrupt stops a
program and hands the CPU back to the hypervisor. The CP/M BDOS and BIOS are answered in the
slot's own bank where nothing of the hypervisor is needed (the console, the keys), the rest
through a far call to the hypervisor (files, RAM discs, the clock).

## Using it (320K)

| | |
|---|---|
| Control + 1-9, 0 | that slot to the front (opened as a command line the first time); with more than 10 slots, the same number twice quickly (Control held) is 11-20 |
| Control + ESC | the TOP screen (Control + ESC again, or Control + a slot: back) |
| built-in commands | RUN, FG, PS, TOP, KILL, RESET, WAIT, CLS, MEM, DIR, CD, MODE, NET, QUIT |
| disc commands | HELP, COPY, ERA, TYPE, RENAME, MKDIR, RMDIR, DRIVE, RAMDISC, FLOPPY, CLAIMS |
| any other name | runs that program from the disc |

## What comes on the disc

- **MON / MON2** - the monitor and decision-tree front end (MON2 uses the whole screen).
- **YING / YANG** - 8BML web browsers over HTTP (MON's screen and MON2's), through an M4 board's
  wifi; **RAWYING / RAWYANG** are the same with the server laying the pages out.
- **The decision services** (`apps/rat`) - MODEL, RAT, RATS, NEURAL, ASK, WATCH, PET, PROBE,
  GREEN, RATBOX: the reactive decision/behaviour-tree engine, a test drive, a virtual pet, a box
  of rats. See the decisions document.
- **Pluto** (`apps/pluto`) - ENC / DEC (the six-layer file encode / decode engine), KEYMGR and
  KEYMAN (keys from a JPEG or entropy files): NTS on the CPC.
- **RVDU** (`apps/rvdu`) - CyborgOS's console for remote HTTP displays.
- **Background tasks** (`tasks/`) - TICKER, CRUNCH, LINES, CLAIMT.

## Networking

An M4 board's wifi, claimed by CyborgOS (M4 0) until `NET OFF`. `NET` turns it on and reports
it; `NET GET` / `NET TEST` fetch pages; the browsers and RVDU use it. CyborgOS passes hostnames -
the IP and gateway come from the module, not from CyborgOS. The status strip shows a live `[N]`
network indicator under the slot number, blinking while there is traffic.

## Building

CyborgOS is built with NTC BASIC like any other program: the hypervisor (`Main.bas`, `Hyp.cls`,
`Hot.cls`, `Ent.cls`) for **cpcfw**; the programs and disc commands for **cpm** with an AMSDOS
header (`.CYB`). The build script compiles every piece, wraps the programs and lays out the two
disc images. Needs the NTC BASIC compiler (see above).

## Documents

| | |
|---|---|
| `docs/cyborgos-userguide.md` | using the 320K version: commands, disc commands, RAM discs, programs, the BDOS and BIOS, plain .COM files, making a .CYB |
| `docs/cyborgos.md` | the design: the bank switch, the time slices, the memory maps, decisions |
| `docs/cyborgos-decisions.md` | the decision services: ports, RAT and MODEL, NEURAL, PROBE, the virtual pet, and how to get an AI to build models |
| `docs/cyborgos-next-port.md` | porting CyborgOS to the ZX Spectrum Next: the hardware map, the staged plan, the proven banking foundation |
| `docs/cyborgos-todo.md` | what has been done (dated) and what is next |
| `cyborgos128kb/README.md`, `USERGUIDE.md`, `DESIGN.md` | the 128K version, as it was frozen |

## Status

The 320K version is where work goes; it passes its self-tests in the NTC harness. The 128K
version is frozen. A port to the ZX Spectrum Next is under way - the banking foundation is proven
on the real target; see the port notes. Not yet tested on a real CPC.