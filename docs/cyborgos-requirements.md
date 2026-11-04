# CyborgOS - user requirements

What it does for the person at the keyboard, written after the fact from the code and the help
pages, 2026-11-01.

What a user can expect, machine by machine, and what is not there. The user guide
(cyborgos-userguide.md) is the manual, command by command; this is the contract. Components are
numbered in components.md; bugs against these in buglist.md.

## 1. The idea

- A CP/M-style computer runs several programs at once, each in its own slot, on one machine: a
  CPC with a 64K-bank expansion, a ZX Spectrum Next, an MSX with MSX-DOS 2, or a PC running the
  vCPC. One slot is on the screen; the others keep running.
- Each slot has a command line, its own screen page, its own drive and folder, and runs one
  program at a time: CyborgOS's own commands (.CYB) or a CP/M program that uses the BDOS.
- A program can be moved, running, to another slot or another machine, and dumped to a file.

## 2. Slots

| Requirement | CPC | Next | MSX | vCPC |
|---|---|---|---|---|
| Slots on a machine | 3 (576K), 7 (1 MB), up to 20 (4 MB) | up to 20 (by RAM) | by RAM | up to 20 |
| Switch the slot on the screen | Control + 1-9, 0 (twice: 11-20) | Caps Shift + 0 then 1-9, 0 | Control + number | Control + T then number |
| See every slot | TOP (Control + ESC live; TOP typed: open slots; TOP FULL: all) | same | same | same |
| A slot's program | RUN n NAME, or NAME typed in it; KILL n; PAUSE / UNPAUSE n; RESET n; FG n; WAIT | same | same | same |
| Keys go to | the slot on the screen (its command line or its program) | same | same | same |
| A program's screen kept while another is in front | yes (its page) | yes | yes | yes |

## 3. Files and drives

| Requirement | CPC | Next | MSX | vCPC |
|---|---|---|---|---|
| Drives | floppy A/B, UniDOS devices and folders as drives (CV, CD) | the SD card (C:CYBORGOS/...) | MSX-DOS 2 drives | the host's folders |
| Z: the system drive with the commands | a RAM disc made at boot | made from the archive | made at boot | the host folder |
| DIR, TYPE, COPY, ERA, RENAME, MKDIR, RMDIR, DRIVE, CD, CV, MOUNT | yes | yes | yes | yes |
| FLOPPY (track by track) | yes | - | - | - |
| RAM discs (RAMDISC v size, 64K to 4 MB, survive a reset) | yes | yes | yes | NOT YET (buglist) |
| HELP, in English; Russian and Spanish for some pages | yes | yes | yes | yes |

## 4. Moving programs (RMOVE / RCOPY, DUMP / REVIVE, SLOTD)

| Requirement | CPC | Next | MSX | vCPC |
|---|---|---|---|---|
| DUMP a slot to a file, REVIVE it (same or another slot) | yes | yes | yes | yes |
| Send a running program to another machine (RMOVE / RCOPY n address) | yes (M4) | yes (ESP) | no network | yes |
| Receive one (SLOTD) | yes | NOT YET | NOT YET | yes |
| Across platforms (-f) | the vCPC takes any; others with -f | | | |
| What goes with it | the program, its registers, its screen page; not its open files, claims, ports or sockets (refused) | | | |

## 5. The network

| Requirement | CPC | Next | MSX | vCPC |
|---|---|---|---|---|
| Turn it on | NET M4 | NET | - | on |
| IPCONFIG, NETSTAT | yes | yes | - | yes |
| The browsers YING / YANG (8BML pages over HTTP) | yes | yes | - | yes |
| A program's ports (messages between machines) | yes | yes | - | yes |
| HTTPS | no | no | no | no |

## 6. Languages

- LANG EN / RU / ES sets the language for every slot: HELP pages in it where translated, typing in
  it (Russian: Control + Space switches the layout; R shown in the strip), the command line
  upper-cases its letters.
- Russian and Spanish letters show on the CPC (glyphs built from the ROM font), the Next (tiles),
  the vCPC (UTF-8). The MSX: not yet.
- Translated: HELP, LANG, DIR, TYPE, PS, AUTOEXEC. The rest fall back to English (todo).

## 7. Boot

- A text file AUTOEXEC on the boot drive is typed into slot 1 at boot, a line a prompt. Shift held
  at boot skips it (the vCPC: --no-autoexec).
- The screen, the slot count and the free memory are shown by PS, TOP and MEM.

## 8. Apps that ship

MON / MON2 (a monitor), YING / YANG and the raw forms (browsers), the rat set (RAT, RATS, RATBOX,
MODEL, NEURAL, ASK, WATCH, PET, PROBE, GREEN), RVDU (a remote VDU), TASKMAN, ENC / DEC and
KEYMGR / KEYMAN (encryption), GUI and GUIDEMO (CPC and Next). Hardware tests for the CPC's M4, RTC,
SID and speech.

## 9. Not there, so nobody looks for it

- HTTPS; the MSX's network; receiving a slot on the Next or MSX; RAM discs on the vCPC; a
  program's open files moving with it; Russian / Spanish on the MSX; more than 20 slots; a
  program larger than a slot's TPA.
