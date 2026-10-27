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
| A pause in the typing | `` ` `` in `--paste`: 50 frames (1 s) | a command typed only when the last one is done |
| "A:" left off M4 file names | `ONE_K_M4_DRIVE=1` | CyborgOS opens "A:CYBORGOS.Z5"; the M4 ROM passes the name on as it is and 1984's M4 doesn't know "A:". Whether a real M4 does is not known - to check on the real board |
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
