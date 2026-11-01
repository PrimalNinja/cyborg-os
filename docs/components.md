# CyborgOS - the components, numbered

Refer to them by number. (Tables, not numbered lists: a Markdown viewer renumbers a list, and the
numbers must stay as written.)

## Hypervisors (C0: the host's own program, one a machine)

| # | Component |
|---|---|
| 1 | C0 CPC 320K+ - src/bas/cyborgos320kb (Main.bas, Hyp.cls): CYBORGOS.BIN, with the M4 network |
| 2 | C0 CPC flat (one bank, no kernel bank) - src/bas/cyborgosflat: CYBFLAT.BIN |
| 3 | C0 CPC 128K (the first, kept) - src/bas/cyborgos128kb |
| 4 | C0 ZX Spectrum Next - src/bas/cyborgos (NEX, tilemap console, esxDOS, ESP) |
| 5 | C0 MSX (MSX-DOS 2, mapper, V9990) - src/bas/cyborgosmsx |
| 6 | C0 vCPC (C, Windows/Linux/Mac, host network) - repo cyborg-os-vcpc (src/vcpc.c, compat.h) |
| 7 | The kernel (C2: scheduler, command line, TOP, slots, AUTOEXEC, LANG) - src/bas/cyborgoskernel/KERNEL.bas: KERNEL.CYB, one file for every machine |

## Shared classes for commands and apps (src/bas/cyborgos320kb/cmds)

| # | Component |
|---|---|
| 8 | CybSys.cls - the hypervisor's ops (BDOS 131) |
| 9 | CybDir.cls, CybVol.cls - directories and volumes |
| 10 | Http.cls - HTTP GET/POST over the network |
| 11 | SlotFrame.cls - a stopped slot's registers in a portable form (moves and dumps) |

## Commands (*.CYB on Z)

| # | Component | # | Component | # | Component |
|---|---|---|---|---|---|
| 12 | HELP | 13 | DIR | 14 | CD |
| 15 | CV | 16 | TYPE | 17 | COPY |
| 18 | ERA | 19 | RENAME | 20 | MKDIR |
| 21 | RMDIR | 22 | DRIVE | 23 | MOUNT |
| 24 | FLOPPY | 25 | RAMDISC | 26 | PS |
| 27 | TOP | 28 | MEM | 29 | MODE |
| 30 | CLAIMS | 31 | FG | 32 | KILL |
| 33 | RESET | 34 | PAUSE / UNPAUSE | 35 | WAIT |
| 36 | SPEED | 37 | DUMP / REVIVE | 38 | RMOVE / RCOPY |
| 39 | SLOTD | 40 | NET | 41 | IPCONFIG |
| 42 | NETSTAT | 43 | LANG | 44 | AUTOEXEC |

| # | Component |
|---|---|
| 45 | Hardware tests: HWINFO, RTCTEST, M4TIME, NTPTEST, SPEAK, SIDTEST (cmds/hw) |
| 46 | Test programs: TICKER, CRUNCH (.CYB and .COM), LINES, HTTPTEST |

## Apps (src/bas/cyborgos320kb/apps)

| # | Component |
|---|---|
| 47 | MON, MON2 - the monitor |
| 48 | YING / YANG - the 8BML browser and its raw forms RAWYING / RAWYANG (Web.cls, Bml.cls, Mouse.cls) |
| 49 | RAT, RATS, RATBOX, MODEL - the rat model |
| 50 | NEURAL, ASK, WATCH, PET, PROBE, GREEN - the neural apps (apps/rat) |
| 51 | RVDU - the remote VDU |
| 52 | TASKMAN - the task manager (VDU path) |
| 53 | ENC / DEC, KEYMGR / KEYMAN - encryption and keys (apps/pluto) |
| 54 | GUI (cpc and next builds), GUIDEMO |

## Boot, loading, packaging

| # | Component |
|---|---|
| 55 | COSLOAD.ASM - the CPC loader (Z's pages, the slots' banks) - tools/ |
| 56 | INSTALL.BAS, CYBORGOS.BAS, WINAPE.BAS - the CPC's disc installers |
| 57 | Z - the system drive (packed from the commands) and the Next's archive (tools/nexarc) |
| 58 | The CPC discs (cards/.dsk, tools/cpcimg) and the Next's SD card (cards/.img, tools/sdinstall) |
| 59 | The builder - tools/cosbuild (CyborgOS.layout.json, cli.js) with its NTC copy |

## Help and languages

| # | Component |
|---|---|
| 60 | help/*.HLP (English), *.HRU (Russian), *.HES (Spanish) |
| 61 | lang/KOI8.FNR, LATIN1.FNR - the font recipes |

## Test harnesses (tools/regress)

| # | Component |
|---|---|
| 62 | cosregress.js + cosboot.py - the CPC suite (emu84 / the Z80 core) |
| 63 | msxregress.js - the MSX suite |
| 64 | vcpctest.sh - the vCPC suite (repo cyborg-os-vcpc) |
| 65 | nextkeys.js, nextrun.js, zrcp.js - the Next in ZEsarUX |
| 66 | espsim - the M4 / ESP network simulator (nettest.js) |

## Documents

| # | Component |
|---|---|
| 67 | docs/cyborgos-todo.md (open work, by component) and docs/cyborgos-done.md (what is done) |
| 68 | docs/buglist.md (bugs) |
| 69 | docs/components.md (this) |
| 70 | docs/ANALYSIS.LOG - each turn's work, the model and a UTC time in front |

## Components that had no number (2026-11-01)

| # | Component |
|---|---|
| 71 | The Pi side - pi/ (cosd.js, proto.js, svc/, cplink-bridge.c, cosctl.js) |
| 72 | The VDU server - tools/vdu (vdu.php, view.html, index.html, rgui.html, vdu.js) |
| 73 | 1984, the emulator's local patch - tools/emu84 (1984-local.patch, emu84.js, winbuild.js) |
| 74 | The other tools - tools/ideflat, html8bml, rawpage, pluto, sizes |
| 75 | The Next's proofs - src/bas/cyborgosnext |

## Future components (no code yet - each keeps its number when it is built)

| # | Component |
|---|---|
| 76 | vCPC spawning and the cluster (Docker instances, the dispatcher, ports across machines) |
| 77 | A second instruction set (Z80MMX / Z80AI) |
| 78 | POSIX slots (Fuzix's userland) |
| 79 | Other machines (Coleco Adam, SC-3000H, TRS-80) |
| 80 | CVM, the CyborgOS virtual machine |
| 81 | Servers on ports (a display server, a web server, a BBS) |
| 82 | A native Linux boot into CyborgOS |
| 83 | Own filesystem drivers (no UniDOS ROMs) |
| 84 | Printer and punch drivers |
| 85 | VER - a version header in every .CYB, and the VER command |
