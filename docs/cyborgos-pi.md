# CyborgOS and the Pi - the link protocol and its services

Started 2026-10-27. The Pi as the CPC's (and the Next's) coprocessor: one link, many channels,
each to a service on the Pi. The Pi side is `pi/` (cosd.js, Node, no npm packages; cplink-bridge.c
for the CPLink's GPIO). The CPC side - C0 owning the link, a slot's channels through BDOS 131 ops -
is the next step.

## 1. The links

The protocol runs over any byte stream:

| Link | The CPC / Next side | The Pi side (cosd.js --link=) |
|---|---|---|
| CPC-CPLink (Julian has two: a Pi 3B, a Pi 4B) | &FD80 data, &FD81 status (bit 0 a byte waiting, bit 1 room to write), 16 byte FIFOs | `cplink:7001` - cplink-bridge on the GPIO |
| CPLink2 (github.com/rabs664/Amstrad-CPC-CPLink2) | the same ports, 1K FIFOs; status bits 4-7 read 1010; **the Pi ROM**: ROM 32 / 33 (&DFxx) read at &C000, 32K the Pi writes - bulk data at LDIR speed | `cplink2:7001` - big answers through the Pi ROM |
| USIfAC II, any serial line | &FBD0 / &FBD1 | `serial:/dev/ttyUSB0:115200` |
| the Next's Pi Zero | the Next's UART to the accelerator | `serial:/dev/ttyAMA0:115200` (the Zero's side) |
| tests, emulators | cosctl.js; 1984's USIfAC in TCP mode | `tcp:7000`, `tcp-connect:127.0.0.1:4001` |

The link layer is the only part that knows the card: the CPLink2's DMA successor (shown on the
CPC forum, not out yet) will be one more link, the protocol above it the same.

## 2. Frames

```
A5  chan  type  id  len-lo  len-hi  payload ...  check
```

- **chan**: 0 the control channel (always open), 1-254 the ones OPEN gave.
- **type**: 1 HELLO, 2 REQ, 3 RSP, 4 DATA, 5 EVT, 6 CLOSE, 7 CREDIT; + #80 **MORE** (more parts
  of this request or answer follow).
- **id**: a request's number, its answer carries it back (0 none) - several requests out at once.
- **check**: the low byte of the sum of chan ... the payload's last byte. A receiver hunts for A5,
  takes a frame whose length is in range and whose check is right, drops anything else (a serial
  line's noise) and looks for the next A5.
- **A payload** (REQ, RSP, EVT): text, then a 0 and binary data when there is any. Text is what an
  NTC BASIC program handles easily ("PUT scores.dat", "OK 15", "ERR notag x").
- **Parts**: a request or answer longer than the other side's frames goes in parts - each part
  the same text, a 0, the next piece of the data; MORE on every part but the last. Each part
  stands on its own (a CPC can save each piece as it comes).
- **Sizes**: HELLO says the longest payload each side takes (the CPC: max=256, say; the Pi 1024).

## 3. Flow control: credit

A CPC can't take everything at once: a slot reads its channel when it runs. So the Pi sends on a
channel only what the CPC said it has room for: OPEN's `credit=n` (1024 if not given), and each
CREDIT frame (2 bytes, little end first) adds to it - sent once the CPC has moved what came on.
A channel out of credit waits; the others go on (no channel holds up another). The CPC needs no
credit from the Pi: the Pi is quick.

## 4. The control channel (0)

| Request | Answer |
|---|---|
| (HELLO) `COS1 machine=cpc name=NAME max=256 cols=80 rows=24` | HELLO `COS1 cosd 0.1 max=1024 host=... link=... services=...` - name: the folder STORE keeps this machine's tags in |
| `PING` | `OK PONG` |
| `TIME` | `OK yyyy-mm-dd hh:mm:ss +zz:zz unix weekday` - the Pi's clock (NTP-set): a TIME source for CyborgOS |
| `INFO` | `OK cosd ... uptime= temp=` + the Pi's model |
| `LIST` | `OK n` + a line a service: `name ready|notyet about` |
| `OPEN service args` | `OK chan` / `ERR noservice` / `ERR notyet` |
| `CLOSE chan`, `CHANS` | `OK` / the open channels |

## 5. The services

| Service | What | Requests / data |
|---|---|---|
| **store** | tagged data kept on the Pi between boots - the CPC's own small file system there (a tag: 64 characters, `/` a folder; each machine its own) | `PUT tag`+data, `APPEND tag`+data, `GET tag [from [n]]`, `DEL tag`, `SIZE tag`, `LIST [prefix]` |
| **run** | a command run on the Pi, its output back - you type ls, the directory comes back | `RUN command` → parts `OUT`+output (MORE), then `OK exit=n`; `STOP` |
| **term** | a shell on the Pi on a pseudo terminal the CPC's size - the CPC a dumb or VT52 terminal, in a slot, while the other channels go on | `OPEN term cols=80 rows=24 type=vt52`; DATA both ways; `EVT EXIT n` |
| **math** | a coprocessor | `EVAL expr` (floating point, functions), `BIG expr` (whole numbers of any size), `XFORM`+data (3D points through a 3 x 4 matrix, projected: the CPC draws, the Pi does the arithmetic) |
| **vdu** | the Pi's HDMI as a full HD virtual display; a web page in a full screen browser there (any browser on the LAN can watch) | `OPEN vdu` - RVDU's commands (tools/vdu), drawn by vdu.js; `OPEN vdu mode=hd` - 1920 x 1080 itself: CLS, COLOR, FONT, TEXT, RECT, FILL, LINE, CIRCLE, IMG tag (a STORE tag: an image sent once, shown any time); EVT back: `TOUCH x y`, `KEY n` |
| **audio** | sound played on the Pi - the file there already (a STORE tag, or the Pi's own), so the link carries commands, not 3.5MB | `PLAY tag`, `STOP`, `VOL n`, `STATUS`; EVT `DONE tag` |
| disk | Pi volumes as CyborgOS drives with real random access (the Pi's file system, not AMSDOS: BDOS 33-36 work as on the RAM discs) - section 5a | `OPEN name [new]` → a handle, `READ h rec [n]` / `WRITE h rec`+128s, `SIZE h`, `CLOSE h`, `FIND pattern`, `ERA`, `REN`, `MKDIR`, `RMDIR`, `FREE` - 128-byte records, as the RAM disc driver; `VOLUMES`, `NEW`, `DROP`, `MOUNT`, `UNMOUNT` |
| plugin | not yet: code sent from the CPC / Next and loaded while its program runs (the Pi a real coprocessor - docs/cyborgos-hardware.md) | |
| rat, slot | not yet: RAT models, CyborgOS slots on the Pi, reached by the same names as the CPC's ports | |

Several at once: a terminal, the maths coprocessor, the display and STORE each on its channel,
over the one link.

## 5a. Pi volumes (Julian, 2026-10-27; the Pi side done: svc/disk.js - the CPC side, PIVOLUME and the drive driver, next)

- **On the Pi**: a volume is a folder, `/home/cyborgos/<volume>/` (cosd runs as the user
  `cyborgos`). `/home/cyborgos/volumes.json` keeps the list: each volume's name, mounted or not,
  its drive letter, read-only or not - so mounts persist across boots of both machines. Anything
  the Pi mounts (a USB stick, a NAS share) can be a volume: a link or a mount point in that folder.
- **On the CPC: PIVOLUME**, as RAMDISC sets up RAM discs:
  - `PIVOLUME` - the volumes, mounted ones with their letters
  - `PIVOLUME NEW name`, `PIVOLUME DROP name` (its files go: asked first)
  - `PIVOLUME MOUNT name X`, `PIVOLUME UNMOUNT X`
- **At the start** the Pi announces the mounted ones (after HELLO, an EVT `MOUNTED name X` each) and C0
  binds their letters: the drives are there with no command typed.
- **4 announced at the start** (a Pi): the limit is on the automatic mounts only, so the start
  doesn't fill the letters by itself; more can be mounted by hand (PIVOLUME MOUNT) while letters
  are free. CP/M programs see drives A-P (an FCB's drive is 1-16); CyborgOS's own letters go past
  that (Z:), so a Pi volume should take a letter in A-P for .COM programs to reach it. A letter a
  RAM disc or UniDOS has is refused (an announced one too: it stays unmounted, and is said so).
- Random access, long files, folders inside a volume (CD as on UniDOS), several CPCs (or the PC on
  the LAN, through a share) seeing the same files.
- The files: names 8.3 in capitals on the CPC's side; on the Pi found whatever their case, made in
  capitals; FIND lists only what a CP/M program can name (`a long name.text` is left out). READ
  pads a part record with ^Z (CP/M's text end); WRITE past the end grows the file (the gap 0s).
- From a PC: `node pi/cosctl.js vol mount GAMES G`, `vol find G:*.*` ...

## 6. The CPLink2's Pi ROM: bulk data

On a `cplink2` link an answer whose data is more than two frames' worth (and 32K at most) goes
through the Pi ROM: cosd hands the data to cplink-bridge (its port + 1), which waits until the CPC
has read the last ROM data (RRD1 / RRD2), writes the new data (RNF high: to the ROM, from offset 0),
then the frame goes out with no data: `BULK n` then the answer's text (`BULK 3000 OK 3000`). The
CPC selects ROM 32 (and 33 past 16K) through &DFxx and copies n bytes from &C000 - one LDIR,
instead of n FIFO reads.

## 7. The CPC side (next)

- C0 owns the link (claimed CPLINK 0 / 1 by the system, or SERIAL n), sends HELLO at the start
  (its name: from a setting; max= the slot buffers' size), and moves frames between the link and
  the slots: BDOS 131 ops to OPEN a channel, send a REQ and wait for its answer (or poll), send
  DATA, read DATA / EVT, CLOSE. A slot's channels close when its program ends.
- A slot's buffer for each channel; CREDIT goes back as the slot reads.
- Commands to come: `PI` (PI TIME, PI LIST, PI RUN ls, PI GET / PUT tag file - STORE and the
  drives), `PITERM` (a slot as the Pi's terminal), RVDU and GUI writing to the Pi's display, the
  TIME command taking the Pi's time.
- The Next: the same over its UART to the Pi Zero.

## 8. Testing

`node pi/test/run.js`: cosd started on a TCP link, every service asked through cosctl.js's
Client (standing in for the CPC), the answers checked - 30 tests: the parser in noise, HELLO,
TIME, LIST, STORE (parts both ways, paths kept in), RUN, MATH (EVAL, BIG, XFORM), TERM (a real
pty: its size, a command, its exit), VDU (the page, the lines to a viewer, a touch back), credit
(a channel held back until the CPC gives it room), and a cplink2 link (the test standing in for
the bridge: a big GET through the Pi ROM). cplink-bridge.c compiles here; it needs a Pi and the
card to run.
