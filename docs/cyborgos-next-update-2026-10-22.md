# CyborgOS on the ZX Spectrum Next - update, 22 October 2026

The first CyborgOS-Next preview booted to a working system in RAM: the hypervisor, the slots,
the hot keys, and a Z: drive made from an archive inside the NEX file. It had no file system -
nothing could be read from or written to the SD card. This update covers what has been done
since. CyborgOS is still alpha.

CyborgOS is a hypervisor for 8-bit machines, written in NTC BASIC: up to 20 programs run at once
in slots of their own, each seeing a CP/M 2.2 machine, switched with a key. It started on the
Amstrad CPC; the same source now builds for the Next.

## The SD card

- **The card is drive C:**, read and written through NextZXOS's own file calls - the Next's DOS
  does the work, so any card NextZXOS reads works.
- **Folders are drive letters**, the way the CPC version does it with UniDOS: `CD GAMES` gives the
  slot a letter whose path is that folder. `CD`, `CV`, `DIR` (`DIR FULL`: sizes and dates),
  `MKDIR`, `RMDIR`, `COPY`, `RENAME`, `ERA`, `TYPE`, `DRIVE` all work on the card.
- **Programs run from the card**, and read and write their files there.
- **CyborgOS boots into its own folder.** At start-up `D:` is `C:CYBORGOS/` and every slot starts
  on it; `P:` is `C:CYBORGOS/C/`, the commands. No more `C:` then `CD CYBORGOS` after each boot.
- **CD is per slot.** A letter's path is shared by every slot, so `CD` in one slot used to move
  them all. Now `CD` takes a free letter when the current one is the boot drive or another slot
  is on it; it moves a letter in place only when the slot is alone on it.
- **`RUN 2 PROGRAM`** starts the program on the drive of the slot that ran it, so its data files
  are found (`CD RATBOX` then `RUN 2 MODEL RATBOX` just works).
- **HELP** finds the help texts in the folder (`HELP PROBE`).

## One program file for both machines

- **`.CYB` is the program format on the CPC and the Next**: a CP/M program with an AMSDOS header.
  The same file runs on both; the drivers strip the header when a file is opened, as AMSDOS does
  on the CPC. A plain `.COM` still runs, for CP/M software. A `.CYB` is for anything that uses
  CyborgOS's own calls - plain CP/M can't load one by mistake.
- **NTC BASIC has a `cyborgos` platform** for writing them (and a `baremetal` platform for new
  machines: built from an org, nothing assumed). `CybSys.Host()` tells a program which machine
  it is on.
- The CPC's apps run from the card on the Next: RAT, MODEL, PROBE, PET, RATBOX, NEURAL, MON and
  the rest (FLOPPY excepted - it drives the CPC's disc hardware).

## Getting it onto a Next

- **A real Next:** copy `CYBORGOS.NEX` and the `CYBORGOS/` folder to the card and run the NEX.
- **An emulator:** a bootable 64MB card image - the System/Next distribution with an AUTOEXEC that
  starts CyborgOS (ZEsarUX, CSpect, JNEXT). Reset and touch nothing: the boot screen goes on by
  itself into CyborgOS.
- **Two builds.** The default boots without a Z: RAM disc - quicker to start, and the ~150K it
  took goes to the slots; the commands run from `P:`. The other builds Z: at boot as before (and
  still looks on `P:` for what Z: has no room for). Copy one or the other.
- **`sdinstall`** (tools/sdinstall): a PC tool that lays CyborgOS out - into a folder, a card
  image (FAT12/16/32), or WinAPE's IDE drive image for the CPC version, from the CPC's seven disc
  images as the CPC installer would.

## Running together

- **Ports work on the Next.** Programs talk to each other through named ports (a model serves
  RAT, RAT serves PET and RATBOX, `ASK` and `PROBE` call any of them). On the Next a waiting
  slot never woke: the clock stood still while programs ran, because the Next's interrupt is a
  short pulse that a busy slot misses. The hypervisor now catches up the clock from the raster
  after every slot's turn - 300 ticks a second, measured with four programs running - and uses
  the Next's interrupt controller to hold the interrupt where the core has it.
- **The slot keys work under load.** Caps Shift + a number switches slots while programs compute
  or wait for keys (they died before: the keys were read only on the missed interrupt).
- **PET, RATBOX and LITTLE SEOUL run** - the decision models with their pets and town.
- **NTC's `cyborgos` platform now refuses to build a program that doesn't fit** in a slot (MODEL's
  overflow, below, would have been caught at build time).
- **A NEX fix:** the NEX loader's stack sat in a bank that held the boot archive, and overwrote 6
  bytes of it - a command on Z: was quietly corrupt. Fixed in NTC's NEX output.

## The programs: services, models and what they do

CyborgOS's programs are split the way a mini-computer's are: **services** sit in a slot with a
named port and answer other slots; **programs** call them. The decision logic of a game or a pet
is not written into it - it lives in a model file that a service serves, so the same rules drive
a pet, a box of rats or a town of a hundred people. On the Next they are loaded from the SD
card, and they are the same .CYB files as on the CPC - except where noted below (GREEN needs the
CPC's greenhouse board, RATBOXN is the Next's own).

### The decision services

- **RAT** - the decision service (port `RAT`). A program asks it "model tag tag:level ..." and
  gets one decision back. It decides the same way for every model, at every level of it:
  necessities first (food, sleep, flee - whichever has run lowest below its threshold wins over
  everything), then requirements (what the program wants of it - a game character's role), then
  its own likes less its dislikes. A model is a tree as deep as its maker wants: RAT chooses at
  the top, then among the branches under the winner, down to a leaf (`food.fruit.apple`).
- **MODEL** - serves one model file (a `.MDL`: a line a branch, the depth its indent, each with a
  weight) on a port named after the file. RAT asks it for weights and tells it what was picked;
  the likes grow each time they're picked - habits - and are saved back to the file. A model has
  **LUNs**: copies of its weights, one per creature, so a swarm on one model has a habit each;
  a new LUN can be bred from two others (each weight one parent's, a little changed).
  **Fixed since the preview:** MODEL's LUN table ran 1.8K past the top of a slot's memory into
  CyborgOS's own code - it crashed RATBOX on the Next. The table is now 28000 bytes and fits;
  the same fix applies to the CPC.
- **NEURAL** - a small neural net served on a port, trained by example: it learns records
  (`seen=wolf near=yes action=run`) and, asked with some of their properties, gives back the
  record that fits best with the rest of it - what goes with what was asked.
- **ASK** - calls any port from the command line and prints the answer (`ASK RAT RATMODEL
  food:10 tv`, `ASK NPC Q seen=wolf action?`): any service tried by hand.
- **PROBE** - a test drive for the models: its own command line (`probe>`) - a decision from any
  model with its plan (how RAT got there, level by level, as a database shows a query plan), dry
  runs that learn nothing, a model's weights, the services running.
- **WATCH** - NEURAL's sample: every 2 seconds it asks a net what goes with CyborgOS's own numbers
  (free memory, programs running) and shows it; with `prop=value` words it trains it instead.

### What runs on them

- **PET** - a virtual pet, Tamagotchi style, in a room with a bed, a food bowl, a play corner and
  a TV. It decides for itself what to do next (RAT on PET.MDL): hungry, tired or bored wins, else
  what it likes. You fill the bowl, switch the TV, clean up its mess, give medicine, praise or
  scold it (its likes go up or down); it forms habits but gets bored of the same thing three
  times running, grows up from baby to old, falls ill if the room is dirty, and dies if neglected.
  Saved when you quit. **Fixed since the preview:** PET moved far slower on the Next than on the
  CPC, though the Next is 8 times faster - its timing goes by CyborgOS's clock, which stood still
  while programs ran; with the clock caught up from the raster it runs at the CPC's pace.
- **RATS** - RAT's simplest sample: one rat in a box with four corners, its food, energy and fun
  running down, RAT choosing where it goes next.
- **RATBOX** - a box of pet rats: a swarm on one model, each rat a LUN with its own habits. They
  eat, sleep, play, watch TV, groom friends, mate, fight rivals in the boxing ring and nurse their
  babies; babies are bred from their parents' LUNs; they like or dislike each other; a crowded box
  gets dirty, ill and fights more; the dead go to the graveyard. Up to 100 rats. **On the Next:**
  `RATBOX` crashed (MODEL's table - above) and couldn't find its model's LUNs when run from
  another folder (`RUN` now starts a program on the drive of the slot that ran it); both fixed.
- **RATBOXN** (new, Next only) - the same box of rats, line for line the same lives, drawn on the
  Next's own screen: the room as a tilemap, each rat a hardware sprite walking to the bed, bowl,
  wheel, TV, boxing ring, pen or graves - brown males, white females, pink babies, grey when old,
  red fighting, green when ill, a heart over a mating pair. It draws only while it is in front,
  gives the CPU away every frame, and puts the console back when you switch slots. It shares
  `RATBOX.SAV` with RATBOX, so either carries on the other's box. It uses CyborgOS's own MODEL
  (LSMODEL, the copy it needed while MODEL overflowed, is no longer required).
- **LITTLE SEOUL** (THE LITTLE SEOUL ENGINE) - the Next game taken apart into the city (the
  engine) and the game (the postie), so new games can be set in the same city. Its town also runs
  as CyborgOS services: **TOWN** keeps the hundred people living their days, each deciding with
  RAT as a LUN of one of three models (SUIT, KEEPER, STAR) served by MODEL; `ASK TOWN S` shows
  where everyone is, `ASK TOWN F x y n` frightens a street and they flee. The game runs as a task
  on CyborgOS-Next; TOWN and its models are so far tested on the CPC version.
- **GREEN** - the greenhouse bridge: a board's sensors to RAT, its decisions to the relays (CPC
  hardware).

### The other programs

- **MON** and **MON2** - a monitor of the machine and CyborgOS in the spirit of the Amiga's SCOUT:
  pages of CyborgOS's tables, memory pages, ROMs, slots and drives, laid out from a hand-made map
  (SYSTEM.MAP), each row a link to the next page. MON in a window, MON2 on the whole screen.
- **YING** and **YANG** - web browsers for 8BML pages (8bitology's markup for 8-bit machines):
  links, forms, local pages on the disc linked AmigaGuide style; a slot a tab. YING in a window,
  YANG on the whole screen. They need the network (`NET M4` on the CPC, `NET ESP` on the Next).
- **RVDU** - a remote VDU console: a screen on a VDU server shown live on the slot's console,
  keys going back - or the machine writing to a screen that browsers watch. The network too.
- **Pluto** (ENC, DEC, KEYMAN, KEYMGR) - files encoded through 1-3 layers of ROM keys. KEYMAN
  is a service holding the keys: other slots ask it to encode or decode their own memory, and
  never handle the keys themselves.

## A GUI (new, first version)

- **GUI.CYB** is a service like X Windows': it holds windows, buttons, check boxes, labels, text
  fields, gauges, cycles, sliders and lists that programs in other slots create through its port, and draws them while
  its slot is in front. Programs read states back (a button's clicks, a box's tick, a field's
  text) - nothing is lost while they're busy.
- **The Next:** drawn through the tilemap the console already uses (no extra memory banks), the
  pointer a hardware sprite, the Kempston mouse. **The CPC:** mode 2 straight into the screen,
  MultiPlay or SYMBiFACE PS/2 mouse. Both in green-screen colours.
- Keyboard too: Tab or Break moves between controls, Space presses.
- A demo, GUIDEMO, and a class for programs (GuiCli).
- **RGUI, a remote head** (the CPC with an M4 so far): the same windows shown and worked in any
  number of browsers on other monitors, through the VDU server (tools/vdu, rgui.html).

## The network (new)

- **The Next's ESP wifi works**: `NET ESP` turns it on. CyborgOS drives the ESP8266's AT firmware
  over the Next's UART, behind the same network calls the CPC's M4 has - so the same programs (`NET
  GET`, the web browsers, RVDU, GUI's remote head) run on both machines, the same .CYB files.
- **The ESP does TCP/IP; CyborgOS never sees a packet and never listens.** It keeps what arrives
  until asked (passive receive), so nothing is lost while a program is busy; up to 5 connections.
- **`IPCONFIG`** shows the network: connected or not, the IP address, netmask, gateway, MAC, the
  signal (on the CPC, the DNS servers too, from Duke's M4 firmware). **`NETSTAT`** shows each
  connection: the slot that opened it, its state, the address, the bytes waiting. **`NET SET`**
  joins a network (`NET SET name,password` on the Next; the M4's `|NETSET` text on the CPC).
- **Http.cls** (for programs) has POST, and reads that can stop early (`Start`, `More`, `Finish`):
  a program looks at the first piece of an answer and drops the rest without fetching it.
- Tested in ZEsarUX with a stand-in ESP (tools/espsim) that answers as the ESP's AT firmware does,
  with real connections behind it: GETs, a POST, a stream stopped early. Not yet on a real ESP.

## Still to come

- Key repeat on the Next keyboard.
- The 80-column console uses 25 of the Next's 32 rows.
- Sound and the hardware claims on the Next.
- Testing the network on a real Next's ESP (so far: an emulated ESP).
- More slots than 10 on the Next.
- Testing on real Next hardware (so far: JNEXT and ZEsarUX).

---

*CyborgOS and NTC BASIC: (c) 2026 Cyborg Unicorn Pty Ltd - MIT License.*
