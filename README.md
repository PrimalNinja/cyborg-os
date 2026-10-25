# CyborgOS

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

**Status: ALPHA.** It runs, it is used, and it changes. The Amstrad CPC 320K version is the
reference and has been in daily use; the ZX Spectrum Next port boots to a working system with the
SD card as a drive as of this build. Expect rough edges and read the "What is not
there yet" lists before reporting one.

## What it is

CyborgOS is a hypervisor for Z80 computers. It runs several CP/M programs at once, each in a
whole 64K bank of its own with its own command line and console, and lets you switch between
them with a key. A program sees a plain CP/M 2.2 machine - the BDOS, a BIOS jump table, a TPA
from #0100, drives with 8.3 file names - and never sees the hypervisor or the other programs.
The hypervisor owns the real machine: the banking, the screen, the keyboard, the clock, the
discs.

It is written in NTC BASIC (the compiler is a separate project) and the programs that run under
it are either NTC BASIC programs built for NTC's `cyborgos` platform (`.CYB`: CP/M 2.2 plus the
hypervisor's services, the one file for every machine CyborgOS runs on) or any CP/M 2.2
program that keeps to the BDOS and the BIOS (`.COM`).

Things CP/M never had that CyborgOS gives its programs:

- **Many programs at once**, each with its own screen, switched in a keystroke, with a TOP
  screen showing what each is doing.
- **Directories.** CP/M has none; CyborgOS binds a drive letter to a folder (`CD GAMES/ACTION`:
  UniDOS on the CPC, the SD card on the Next). A program still sees a flat drive; the folder is
  behind the letter. User numbers are ignored - nobody misses them.
- **Real random access files** (BDOS 33-36) on the RAM discs, where AMSDOS only ever did
  sequential. The Next's SD driver will give the same on the card.
- **RAM discs** that outlive a reset, any number of files open.
- **Decision services, a network, remote displays** (ports between slots; the network through the
  CPC's M4 board or the Next's ESP - the boards do TCP/IP, CyborgOS never listens: `NET`,
  `IPCONFIG`, `NETSTAT`, Http.cls's GET, POST and streamed reads; RVDU) - see the documents below.

## The platforms

| | CyborgOS 320K (Amstrad CPC) | CyborgOS 128K (Amstrad CPC) | CyborgOS-Next (ZX Spectrum Next) |
|---|---|---|---|
| State | the reference; works | frozen, changed only when asked for | **alpha**: boots, runs commands and programs from RAM |
| Needs | a CPC with 320K or more (a 256K expansion) | a 6128 or more | a Next with 1MB or more (2MB tested) |
| Slots | half the extra 64K banks: 2 with 256K ... 20 at most | 1 | half the free 64K banks: 10 on a 2MB Next |
| Program space | #0100-#EEFF, 59.5K | #0100-#F4FF, about 61K | #0100-#EEFF, 59.5K |
| Files | AMSDOS / UniDOS discs and devices, RAM discs | AMSDOS | C: the SD card (NextZXOS's esxDOS), with folders; A: a read-only archive inside the NEX; Z: a RAM disc made from it at boot |
| Screen | 80 x 25 text (MODE 2), other text modes per slot | 80 x 25 | 80 x 32 tilemap text, Layer 2 under it |
| Keys | Control + 1-9, 0 = that slot (twice: 11-20), Control + ESC = TOP | - | Shift + 0 = TOP, then the slot's key there: 1-9, 0 (10), A-J (11-20); Shift + 0 again = back (Delete still deletes; the cursor keys, Edit, Caps Lock, Graph ... keep their jobs) |
| Sources | `src/bas/cyborgos320kb/` | `src/bas/cyborgos128kb/` | `src/bas/cyborgos/` (the hypervisor, with the Next's code) + the 320K commands |
| Build | `src/build/dsk/cyborgos320k.dsk` | `src/build/dsk/cyborgos128k.dsk` | `build/next/CYBORGOS.NEX` |

A program built for CyborgOS runs on all three: the slot is the same 64K bank from #0100.

## Using it: the basics

### Starting

- **CPC 320K:** write `cyborgos320k.dsk` to a disc (or mount it in an emulator), then
  `RUN"CYBORGOS`. In WinAPE use `RUN"WINAPE` (it sets KEYREP for the emulator's speed).
- **Next:** copy `CYBORGOS.NEX` to the SD card and open it from the NextZXOS browser (or
  `.nexload CYBORGOS.NEX`). It makes the Z: drive from the files inside itself and shows slot 1.
  The card is drive C:; "Getting it onto a Next" below says what to copy, and there is a
  bootable card image for emulators.

You get a prompt for slot 1:

```
CyborgOS slot 1 of 10 - Shift + 0 TOP (then 1-9, 0), HELP                    [1]
1> Z: system drive, 11 commands (92K)
1>
```

### The command line

| Type | What happens |
|---|---|
| `HELP`, `HELP name` | the list of commands; one command's help (`HELP DIR`) |
| `DIR`, `DIR A:` | the files on this slot's drive; on another |
| `name` | runs the program `name` (NAME.CYB, else NAME.COM) from Z:, then this slot's drive, then the boot drive. The rest of the line is its command tail |
| `RUN 3 name` | runs it in slot 3 instead |
| `TYPE file` | shows a text file |
| `CV B:` or just `B:` | this slot's drive becomes B (each slot has its own) |
| `CD folder`, `CD ..`, `CD /` | this slot's folder (CPC with UniDOS; Next on C:) |
| `TOP`, `PS` | what every slot is doing (TOP: live, with turns and BDOS calls a second) |
| `FG 3` | slot 3 to the front (the same as the key) |
| `KILL 3` | stops the program in slot 3 |
| `RESET 3` | slot 3 as new |
| `RAMDISC` | the RAM discs; `RAMDISC D 256KB` makes one as D:, `RAMDISC D 0` drops it |
| `MEM` | main RAM and the banks |
| `ERA`, `COPY`, `RENAME` | files |
| `MKDIR`, `RMDIR` | folders |
| `CLS`, `QUIT` | clear this slot's screen; end CyborgOS |

### Switching programs

Start something in slot 1, press **Shift + 2** (Next) or **Control + 2** (CPC) and you are at
slot 2's prompt with slot 1 still running. **Shift + 0** / **Control + ESC** shows TOP - every
slot, what it runs, how busy it is - and the same key, or a slot's key, takes you back. A program
that waits for a key costs nothing; one that computes shares the CPU with the others in time
slices.

### Programs

Anything with a `.CYB` extension (an NTC BASIC program built for the `cyborgos` platform: the
same file runs on the CPC and the Next) or a plain CP/M `.COM`. Put it on a drive the slot can see and type its name. The user
guide covers writing one: `System.CommandLine()` is the command tail, the console is the BDOS
console, files are the BDOS file calls, and the extra services (the slot, the clock, the ports
between slots) are BDOS 30/131 calls wrapped by `CybSys.cls`.

## Getting it onto a Next

- **A real Next:** copy `build/next/CYBORGOS.NEX` and the whole `build/next/CYBORGOS/` folder onto
  your card (anywhere; the root is simplest). Open the NEX from the browser. The folder holds
  the commands (`C/`), the help texts (`HELP/`) and the CPC's apps, which run here too
  (FLOPPY excepted). A program only needs its own copy in `CYBORGOS/` if it is new.
- **An emulator:** `build/next/cyborgos-next-sd.img` is a bootable 64MB card image - the
  System/Next distribution (NextZXOS 2.06H; its licence allows copies, not sales) with
  `/NEXTZXOS/AUTOEXEC.BAS` running CyborgOS and the folder above installed - so it boots
  straight into CyborgOS. ZEsarUX: `--mmc-file`; CSpect: `-mmc=`; JNEXT: its SD image setting.
  Reset and touch nothing: the firmware's boot screen offers Space (menu) and C (extra cores)
  for a couple of seconds, then goes on by itself into CyborgOS. Taking either, or pressing a
  key while NextZXOS starts, lands on the NextZXOS menu instead (from there, run
  `CYBORGOS.NEX` with the Browser). Don't load the NEX as a snapshot: that bypasses NextZXOS's
  own start and the SD card then answers every call with an error.
- **A CPC:** `INSTALL.BAS` on disc 1, as always (`docs/cyborgos-userguide.md`).

**Two Next builds.** `build/next/` boots without Z: - quicker to start, and the ~150K a RAM disc
of the commands would take is the slots'; the commands run from P:, which CyborgOS maps to the
card's `CYBORGOS/C/` at boot (D: is `CYBORGOS/`, every slot's drive to start with). `build/next/z/`
(its own `CYBORGOS/` and `cyborgos-next-sd-z.img`) makes Z: at boot as before, and looks on P:
after it. Copy one or the other. (The CPC keeps Z:, as it always has.)

`tools/sdinstall` is what lays this out (`sdinstall.c`, one file: a FAT12/16/32 writer for a
card image with an MBR or a bare volume, WinAPE's `.ide` through its block map, or a plain
folder, with a CPCEMU `.DSK` reader that installs the CPC's discs as INSTALL.BAS's list says).
`bash tools/sdinstall/dist.sh` after `tools/nexarc/build.sh` rebuilds the folder and refreshes
the image in place; `dist.sh --cpc hdd.ide` puts the CPC set on a WinAPE drive.

## What is not there yet

**Next (this alpha):**
- The SD card is C: (`C:` then `DIR`, `CD`, `COPY` ...; `DIR FULL` for sizes and dates); D: is
  its `CYBORGOS/` folder and P: `CYBORGOS/C/` (mapped at boot). It is read and written through
  NextZXOS, one file at a time per direction, as the CPC's discs; random access reads on or
  reopens. A: is read-only (the files baked into the NEX); Z: is RAM (the Z build).
- The commands baked into the NEX (A:, and Z: in the Z build): RAMDISC, DIR, CD, CV, FG, KILL,
  MEM, TOP, TYPE, HELP, RESET, ERA, COPY, RENAME, MKDIR, RMDIR, DRIVE; the rest (PS, MODE, the
  apps) run from the card. HELP's list is still the CPC's.
- No key repeat yet. 10 slots at most for now. The 80-column console is 25 rows (the screen
  has 32).
- Main RAM is full. New hypervisor code has to go in the page code, not main RAM.

**CPC:**
- Random access files work on RAM discs only (AMSDOS is sequential).
- The scrollback is off; MODE's other text sizes are rough.

**Both:** it's an alpha. Programs that poke the hardware directly (the CRTC, the sound chip)
work on the CPC and are not stopped from doing so; they'll be wrong on the Next.

## Documents

| | |
|---|---|
| [docs/cyborgos-userguide.md](docs/cyborgos-userguide.md) | using the 320K version: commands, disc commands, RAM discs, programs, the BDOS and BIOS, plain .COM files, making a .CYB |
| [docs/cyborgos-next-port.md](docs/cyborgos-next-port.md) | the Next port: what was done and why, the hardware map, the Next's memory map, the keys, the archive drive, the SD driver, the installer |
| [docs/cyborgos.md](docs/cyborgos.md) | the design: the bank switch, the time slices, the memory maps, decisions |
| [docs/cyborgos-gui.md](docs/cyborgos-gui.md) | the GUI: GUI.CYB (the service, the port GUI), its heads (the CPC's mode 2, the Next's tilemap), GuiCli for programs, GUIDEMO |
| [docs/cyborgos-decisions.md](docs/cyborgos-decisions.md) | the decision services: ports, RAT and MODEL, NEURAL, PROBE, the virtual pet, and how to get an AI to build models |
| [docs/pluto.md](docs/pluto.md) | Pluto: NTS on the CPC - the six-layer encode / decode engine, the ENC / DEC file tools and KEYMGR |
| [docs/cvm.md](docs/cvm.md) | CVM: the CyborgOS virtual machine - a native host for CyborgOS on Windows / Xbox (draft) |
| [docs/cyborgos-todo.md](docs/cyborgos-todo.md) | what has been done (dated) and what is next |
| `src/bas/cyborgos128kb/README.md`, `USERGUIDE.md`, `DESIGN.md` | the 128K version, as it was frozen |

## Building

CyborgOS is built with NTC BASIC like any program: the hypervisor for **cpcfw** (CPC) or
**zxn** (Next) - the machine it runs on -, the commands and programs for **cyborgos** (a slot:
`.CYB`, the one file for both machines). It needs the NTC BASIC compiler, which is in its own repository, and sjasmplus.

Both machines are built with the **CyborgOS Builder**, `tools/cosbuild/src/cosbuild.html` - a page,
opened in a browser, needing nothing but sjasmplus (no node, no server). The build is its layout,
`tools/cosbuild/CyborgOS.layout.json`: a CyborgDesigner layout - stages of steps of parts - whose parts
are the build's own datatypes: NTC projects (each program: its files by path, platform, consts), an
assembly file, notes and checkboxes, external tools (what to give them, what to do, what to bring
back), and the packager's parts (system drive Z, COSCYB.INC, the Next's boot archive, INSTALL.BAS,
CPC discs, card folders, images). It carries NTC BASIC's own JS (the compiler, textEditor,
listRenderer) and CyborgDesigner.

To build: open `cosbuild.html` in Chrome or Edge, **Open the CyborgOS folder...** (this folder), then
Build: **Run**. It stops twice for sjasmplus - run `build/stage/assemble1.bat` (or `.sh`), Run,
`assemble2.bat`, Run - and ends with everything in `build/`: `dsk/cos-disk1..7.dsk`, `next/CYBORGOS/`,
`next/z/CYBORGOS/`, the NEX files, the card images (from `build/next/cyborgos-next-sd.img`).

- **Build** - Run goes through the parts in order and stops where it waits (an external tool, a box to
  tick). A project whose stage folder gets a new file is not back until the tool has run again.
- **Design** - the layout in CyborgDesigner: drag parts in, set their properties; New layout for
  another build.
- **Files** - the project's files (what the layout's Imports part names), edited in place.
- **Tools** - a .DSK opened, made or blank; a new hard disc image; files into an image that is there.

From node, without a browser: `node tools/cosbuild/src/cli.js build` runs it all with the same JS
(sjasmplus on the PATH, or `SJASMPLUS=`); `check`, `parts`, `run`, `ntc NTC_SRC`, `dsk`, `img`,
`install` - `tools/cosbuild/README.md`. The older scripts (tools/nexarc, tools/sdinstall,
tools/cpcimg) are kept, not used by it.

The Next's boot archive (`build/next/CYBORGOS.ARC`) is the files the NEX carries inside itself -
CYBORGOS.Z, RAMDISC and the commands and help - so a bare NEX runs with no card: at boot it is drive
A: and Z: is copied out of it. It is CyborgOS's own layout (a small directory, then the files
uncompressed in 128-byte records; `tools/nexarc/nexarc.py` documents it), not CP/M's ARC; a build
intermediate, not a file for the card.
