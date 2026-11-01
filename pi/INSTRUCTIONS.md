# CyborgOS for the Pi - setting it up (for later)

What to do on the Pi and on the CPC to have the Pi as the CPC's coprocessor: cosd with its
services (store, float, math, audio, vdu, vdp, run, term, disk), the vCPC on the Pi, and the
link. Nothing is fetched from the network on the Pi: Node.js is in 3p/nodejs (beside pi/). Written 2026-11-02
from the code; the parts marked "to come" are not written yet.

## 1. What you need

- A Raspberry Pi 3B, 4B or 5 (or a Zero 2 W: no HDMI worth a VDP, but every other service) with
  Raspberry Pi OS, 64-bit (the 32-bit OS works too: 3p/nodejs has both).
- A CPC-CPLink or CPLink2 on the CPC, wired to the Pi's GPIO as the card's documentation says
  (cplink-bridge.c is the Pi's side of the FIFO), or a serial link (USIfAC II to a USB serial
  adaptor on the Pi).
- On the CPC: UniDOS, and a ROM slot for Streamer (NTC's streamer/build/streamer.rom) when the
  Locomotive BASIC door is wanted; CyborgOS on the CPC only if you want slots on the CPC too.
- An HDMI screen on the Pi for the VDP and the vdu (and speakers on its jack or the HDMI for
  MUSIC).

## 2. The Pi

1. Copy the pi/ folder to the Pi, say to /home/cyborgos/pi (cosd runs as the user cyborgos; the
   volumes live in /home/cyborgos/<volume>/).
2. Build the link bridge once (the one piece that needs gcc, until a prebuilt one is in 3p/):
       gcc -O2 -o cplink-bridge cplink-bridge.c -lgpiod     (or as its header says)
3. Start cosd with the vendored Node:
       ./run.sh --link=cplink:7001 --store=/home/cyborgos/store --volumes=/home/cyborgos
   or, for a serial link:  ./run.sh --link=serial:/dev/ttyUSB0:115200
   run.sh picks 3p/nodejs/linux-arm64 or linux-armv7l by uname -m. cosd says what it listens on.
   Several machines: --link more than once (--link=cplink:7001 --link=serial:/dev/ttyAMA0:19200).
   A UART link needs the Pi's serial port freed for it: enable_uart=1 in /boot/firmware/config.txt,
   the serial console off (raspi-config: Serial Port - login shell no, hardware yes), and on a Pi
   3 / 4 / Zero W dtoverlay=disable-bt so GPIO 14 / 15 get the PL011 (the mini-UART drifts); the
   user in the dialout group (and gpio for the bridge). install.sh will do these (to come).
4. The display: a browser in kiosk mode on http://localhost:8084/ (Chromium is on the desktop
   image: chromium-browser --kiosk http://localhost:8084/). It shows every open vdu and VDP
   display; any browser on the LAN can watch the same page.
5. Music: mpg123 for .mp3 (sudo apt install mpg123); .wav plays through aplay, which is there.
6. At boot (to come: install.sh writes these): a systemd unit for cplink-bridge, one for cosd
   (run.sh), and the kiosk browser started by the desktop session. Until then, start them by hand.
7. The vCPC on the Pi (a CyborgOS in its own right, for programs offloaded from the CPC): make in
   cyborg-os-vcpc, then run it headless; its console-as-socket mode and the slot service in cosd
   are to come, so today it runs on its own.

## 3. Test it before the CPC is involved

From any PC with Node on the LAN (or on the Pi itself):
    node cosctl.js --host=pi --port=7000 ping          (with cosd started with --link=tcp:7000)
    node test/run.js                                   (every service, on a TCP link, 64 checks)
    node test/vdp.js                                   (the VDP service, 14 checks)
And NTC's streamer/test/streamer_test.py drives the Streamer ROM against a cosd on TCP (33).

## 4. The CPC

1. Streamer: put streamer.rom in a ROM slot (a ROM board, or the M4's slots). After a reset,
   |DRIVE lists V9990, V9938, ZXN, MD, PI, SPEECH, MUSIC.
2. Try it: the examples in NTC's streamer/examples (VDPDEMO.BAS: a bouncing sprite on the Pi's
   HDMI; MUSIC.BAS; SPEAK.BAS for an SSA-1 or dk'tronics card).
3. CyborgOS on the CPC (optional): NET and the Pi commands (PI, PIVOLUME, PITERM) are to come on
   the CPC side; the vCPC and the Pi's services work without it.

## 5. Assets on the Pi

A game's patterns, tiles and music are put in the Pi's store once (a STORE tag is a path:
GAMES/NAME/TILES.BIN), from the CPC through Streamer's STORE: device (to come), or from a PC on
the LAN with cosctl (node cosctl.js put GAMES/NAME/TILES.BIN tiles.bin), or into a Pi volume
through a share. The VDP's PATTERNS request names the tag; the link never carries the data again.

## 6. Licences

CyborgOS for the Pi is MIT. Vendored: Node.js (MIT; 3p/nodejs/README.md lists what it bundles).
Invoked, not linked: mpg123 (LGPL-2.1), aplay (GPL, part of ALSA), Chromium (BSD and others).
To come, each with its licence stated when added: the SP0256 and SC-01 speech emulations (from
MAME's device files, BSD-3-Clause) and Piper for a human-like voice (GPL-3.0, run as a separate
process).

## 7. Known limits today

- Streamer has not yet run on real UniDOS: its test stands in for UniDOS with the documented
  entry contracts (DOSNodes.a).
- No install.sh / systemd units yet; the vCPC's slot service and console socket to come; the
  CPC-side Pi commands in CyborgOS to come; STORE: as a Streamer device to come.
