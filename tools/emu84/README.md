# emu84 - CyborgOS in the 1984 CPC emulator

1984 (https://github.com/salvogendut/1984, GPL v2, C + SDL3) emulates the CPC 464 / 664 / 6128 /
Plus with the real ROMs, the RAM expansions to 1MB, and much of the hardware CyborgOS cares about:
M4 (the M4 ROM and its file / network commands, an SD card that can be a host folder), Net4CPC
(W5100S, host sockets or a TAP device), the DS12887 RTC, SYMBiFACE II IDE and mouse, Albireo,
USIfAC II, the Powergraph V9990. It runs headless. It is the second test bench, after NTC's
harness: the harness's firmware is a stand-in; here it is the real one, with the CRTC timed.

## Building it (Linux)

```
git clone https://github.com/salvogendut/1984          # beside cyborgos/ (../1984)
# SDL3 (Ubuntu 24.04 has none): from source
git clone -b release-3.2.24 https://github.com/libsdl-org/SDL sdl3src
cmake -S sdl3src -B sdl3src/build -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/sdl3 -DSDL_TESTS=OFF
ninja -C sdl3src/build install
cd 1984
git apply ../cyborgos/tools/emu84/1984-local.patch
autoreconf -fi && PKG_CONFIG_PATH=/opt/sdl3/lib/pkgconfig ./configure && make -j8
export LD_LIBRARY_PATH=/opt/sdl3/lib
```

Built against 1984's commit 4f8453f (2026-10-08).

## 1984-local.patch

Changes to 1984 for testing (GPL v2 as 1984 is; kept here as the patch only):

| What | How | Why |
|---|---|---|
| No 50 Hz wait | `ONE_K_WARP=1` | 1984 runs at the real speed, headless too; this runs flat out |
| The speed while running | Shift+F4 faster, Shift+F3 slower (WinAPE's keys): 25%, 50%, 100%, 200%, 400%, 800%, Max; `ONE_K_SPEED=pct` the starting speed (0 Max) | the sound is kept to 0.2 s queued when not at 100% |
| M4 and Albireo together | always | stock 1984 turns one off when the other goes on; the Albireo's ports are claimed first |
| The Albireo's SD card and USB stick apart, a 2nd Albireo | `albireo_image` (SD:), `albireo_usb_image` (UMS:), `albireo2=true`, `albireo2_image` (SD2:), `albireo2_usb_image` (UMS2:) in 1984.conf; F9 Extensions rows "CH376-B USB stick", "Albireo 2 SD card", "Albireo 2 USB stick" | stock 1984 gives SD: and UMS: the one image and has no second card (&FE40 is only the dual-chip mouse's); the medium follows SET_USB_MODE (3 the card, 5-7 the stick) |
| The M4 for UniDOS's M4 node (m4.rom) | always | C_CD's status byte, C_RENAME / C_MAKEDIR on card images, C_WRITE2's block form, FatFs's open modes, folders as the real M4 lists them ('>', 8.3, terminator) |
| The DS12887's NVRAM kept | `rtc.nvram` beside 1984.conf | stock 1984 loses it at every reset and exit |
| A pause in the typing | `` ` `` in `--paste`: 50 frames (1 s) | a command typed only when the last one is done |
| "A:" left off M4 file names | `ONE_K_M4_DRIVE=1` | no longer needed by CyborgOS (it leaves the boot drive's letter off now: the real M4 doesn't know "A:" either - Julian's board, 2026-10-28); `--stock` turns it off |
| The M4's ROM number | `m4_rom_slot=N` in 1984.conf, 1-255 (6 by default) | with UniDOS in 7 the M4's Ctrl J must be out of the firmware's walk: 16-31 on a stock 6128 (it walks 0-15), 32-255 on a firmware that walks 0-31. 32 and up are kept apart from 1984's 32 ROM slots |
| The V9990's own picture | `ONE_K_V9_PPM=file` | saved with `--screenshot-at`: 512 x 212, not squeezed into the CPC's 768 x 272 |
| A trace | `MYTRACE=frame` from that frame: the last 64K instructions (PC, SP, the RAM bank, the ROMs' state) written when `MYPC=hex` is reached, when the RAM bank goes back to 0 with the lower ROM in (`MYBANK=1`: a crash into the firmware), or at frame `MYEND`; `MYFR=1` a line a frame (PC, IFF, the interrupt lines) | how the two bugs below were found |

## emu84.js

```
node tools/emu84/emu84.js [--v9990] [--ram=576] [--frames=N] [--out=DIR] "dir;ps;mode p"
```

Installs the set from build/dsk as the M4's card, writes a 1984.conf of its own (a HOME of its
own: your ~/.config/1984 is left alone), boots, types the commands 8 seconds apart, saves
screen.png (and v9990.png) in --out. `--trace=m4` keeps 1984's M4 trace in trace.log.

## What it found (2026-10-27)

- **The M4's Ctrl J**: CyborgOS looked for UniDOS by its hidden command Ctrl J (KL FIND COMMAND
  of #8A). The M4 ROM has a Ctrl J too - `CALL #B906 / LD HL,0 / JP #0077`, a restart - and in
  slot 6 it is found before UniDOS's in 7. The first DIR restarted the CPC. Now Hyp's fl_fcj
  looks through ROMs 0-15 itself, the ROM named "M4 BOARD" passed over.
- **The CRTC in V9990 mode**: Scr wrote the V9990 table's 0s to the CPC's CRTC (R1, R2, R7): its
  sync stopped, so no frame flyback and no interrupts - CyborgOS hung at its first wait for the
  frame. The CPC's CRTC is now left alone when the V9990 has the console.

Neither shows in NTC's harness (its firmware finds commands by name in its own table; it doesn't
time the CRTC).

## The card image

`--img` boots from an image instead of a folder: by default `build/next/cyborgos-next-sd.img`, the
same card the Next boots (ZEsarUX, CSpect, a real Next). The CPC's whole installed set (discs 1-8, as
INSTALL.BAS lays it out) is in its CYBORGOS/ folder beside the Next's files: one card, both
machines. Where the two differ, GUI.CYB is the CPC's in CYBORGOS/ and the Next's in CYBORGOS/C/
(the Next looks there first, the CPC never does), and CYBORGOS.Z is the CPC's (the Next's own is in
its NEX). emu84 types `|CD,"CYBORGOS"` and then `RUN"CYBORGOS`. The .DSK images are still made.

## The 6128 Plus

`--model=6128plus` (or 464plus): 1984's system.cpr cartridge, F1 pressed at its menu for BASIC
(`~` in the typing is the keypad's f1 - the patch). Stock 1984 maps every ROM number below 128
on the Plus to the cartridge (7 to its AMSDOS), so an M4 or a ROM board is never seen there; a
real Plus passes those numbers to the expansion port. The patch does the same: an expansion ROM
that's there answers its number, the cartridge only when none does (and the M4's ports follow
it). With that, CyborgOS boots from the M4 on the Plus. `--add=FILE,...` puts programs to try on
the card beside the set (`--add=BOUNCE.CYB`).
