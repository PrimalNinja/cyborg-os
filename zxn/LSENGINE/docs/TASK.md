# LITTLE SEOUL as a CyborgOS-Next task

The same game, built a second way: not a NEX on its own, but a program in its own 64K bank under
the CyborgOS hypervisor on the ZX Spectrum Next, next to the town service, RAT, the models, a
command line and the debugger. CyborgOS-Next runs it as it is - nothing in the hypervisor was
changed for it. The NEX build (`node build.js`) is untouched too: byte for byte the same file.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

## Build it

    bash tools/cosnext.sh <NTC src folder> <CyborgOS folder>

Out: `build/cosnext/LSEOUL/` - the folder for the SD card - plus the programs' `.ASM` and `.sym` in
`build/cosnext`. The CyborgOS folder is only read (RAT, MON and their classes come from it). The
script:

1. builds the NEX as always (`build.js`: the data, `LSENGINE.DAT`, the classes made task-ready by
   `tools/taskify.py`);
2. builds the game again for NTC's `cyborgos` platform: `LSGAME.CYB`, a CyborgOS program from
   #0100 (every program here is a `.CYB`, as CyborgOS's own build makes its commands);
3. builds TOWN, LSMODEL, RAT, MON (the debugger), `TOWN.DAT` and the debugger's map of the game
   (`tools/lsmap.py`, from this build's symbols, so the addresses are always right);
4. makes `LSCITY.DAT`: the city's data for the game to load (below).

What goes on the card (`LSEOUL/`):

| File | What |
|---|---|
| `LSGAME.CYB` | the game |
| `LSCITY.DAT` | the city's data, 384K: 24 banks |
| `TOWN.CYB`, `TOWN.DAT` | the town service and its town |
| `LSMODEL.CYB`, `SUIT.MDL`, `KEEPER.MDL`, `STAR.MDL` | the models |
| `RAT.CYB` | RAT |
| `MON.CYB`, `LSGAME.MAP` | the debugger and its map of the game |

## Run it

Copy `LSEOUL/` to the SD card (to its top here; anywhere works). Boot CyborgOS-Next as usual.
On slot 1's command line:

    CD LSEOUL
    RUN 2 LSMODEL SUIT
    RUN 3 LSMODEL KEEPER
    RUN 4 LSMODEL STAR
    RUN 5 RAT
    RUN 6 TOWN 8
    RUN 7 LSGAME
    RUN 8 MON LSGAME.MAP 7

then Caps Shift + 7 for the game.

- `CD LSEOUL` gives the folder a drive letter (`drive D: --> ...LSEOUL/`). LSGAME, TOWN and
  LSMODEL look for their files on their slot's drive first, then on A: to P: until one has them
  (in NTC's emulator a slot started with RUN n was on the boot drive; on the Next the map is
  found without a letter).
- **Wait for `LITTLE SEOUL: ready`** (slot 7, a few seconds) before the next RUN: CyborgOS-Next
  reads one file at a time, and a RUN while the game is still reading its data says "not found".
- If something's missing the game says so in its slot and ends: not enough free memory, its data
  file not found or not the city, no three pages in a row for Layer 2.
- On a CPC it ends at once with "For the ZX Spectrum Next": the first thing `Nx.LoadCity` does is
  ask CyborgOS which machine it is on (BDOS 131 op 20, 5 - what `CybSys.Host()` asks), before any
  port is touched (on a CPC the Next's NextReg port #243B is the PPI). NTC's `System` platform
  values are fixed when it's compiled, and a `.CYB` is the same file on both machines, so it has
  to be asked at run time.

The slots:

| Slot | What | Keys |
|---|---|---|
| 1 | the command line | Caps Shift + 1 |
| 2-4 | the models SUIT, KEEPER, STAR | |
| 5 | RAT | |
| 6 | TOWN | Caps Shift + 6: its log |
| 7 | the game | Caps Shift + 7 |
| 8 | the debugger: MON with the game's map | Caps Shift + 8 |
| 9, 10 | spare consoles | Caps Shift + 9 (10: FG 10) |
| - | TOP: every slot, its turns and BDOS calls a second | Caps Shift + 0 |

## How the game lives in a slot

### Its data: loaded into its store

A slot is 64K - the program. The city is 384K more. CyborgOS gives every program a store: up to
32 of its own 16K pages, for as long as it runs (BDOS 131 op 12). `Nx.LoadCity` (from `TaskStart`):

1. opens `LSCITY.DAT` - an AMSDOS header (CyborgOS reads past it), a record saying what's in it,
   then 24 banks of 16K: the NEX's data banks that have anything in them, gfxtool's bank 47 and a
   copy of the NEX's bank 5 (the first sprite patterns). The NEX's banks 1, 2, 4, 13, 14 and 15 are
   all 0 and are left out of the file;
2. asks for a store of 26 pages (416K): the 24 banks, one more for Layer 2, one all 0;
3. finds where the pages are. The store's page numbers (#FF00 in the slot) are the hypervisor's
   own numbering (16K bank = its first free bank + page - 2), and the game can't know the first
   free bank. So it puts its first 16 bytes into the store's first block (op 13), then looks at
   the banks it can be - its own slot's first bank (NextReg #50) less a multiple of 4, as slots
   are 64K - until they turn up;
4. reads the file 128 bytes at a time (BDOS 20) and copies each record into its page through MMU
   slot 6;
5. makes the page table at #BF00: a NEX page -> the 8K page it is in now (the empty banks -> the
   all-0 page; the rest of the pages themselves).

The data routines (`Data.Copy`, `Data.Expand`, `World.Draw`, `WhereAt`, `FaceSet` / `GameSet.Load`,
`GfxData.Load`) map a data page into slot 6 or 7 as in the NEX, but look the page up in #BF00
first (`ld h, #BF / ld l, a / ld a, (hl)`) and put the slot's own page back in slot 7 (noted by
`TaskInit`) instead of page 11. `tools/taskify.py` writes those lines into the classes gfxtool
makes, inside `IFNDEF NTC_ZXN`, so the NEX build never sees them.

### Layer 2: its own banks

In the NEX, Layer 2 is bank 16. Under CyborgOS-Next that bank is the hypervisor's (its console's
Layer 2 is banks 12-16), so the task uses three of its own store pages: banks 47 and 60 (read only
by `GfxData.Load`, which is done with them before `L2.Init`) and the one more after them. Layer 2
needs three banks in a row; the store's pages are given out in order, so they are, and the game
checks. `Nx.L2Bank` gives `L2.Init` the bank for NextReg #12, and `LoadCity` writes the first 8K
page into the four routines that map Layer 2 to draw (`l2pg_a` - `l2pg_d` in `L2.cls` and
`World.cls`: `add a, 32` in the NEX).

### The CPU: it hands it over every frame

A task built with Option Turbo runs with interrupts off and is never stopped by the hypervisor:
the hypervisor only gets the CPU when the task makes a BDOS call. So the game gives it back
itself. `Nx.WaitFrame` (the task build's `Frame`, called from `Tick`) waits for the display to pass
line 200 and calls `Nx.Yield` (BDOS 12, CP/M's version number - any call below 13 ends a slot's
turn) while it waits. Every other slot gets its turn there. Measured in the emulator with all
five services running: 50 game frames a second.

A slot that never waits slows it down: MON busy-polls its keys (TOP shows it with no BDOS calls),
so with MON running the game is at about 25 frames a second. Quit MON (Q) and it's back to 50.

### The screen: only while it's in front

`Nx.Front()` asks CyborgOS (BDOS 131 op 0, a slot's line) whether the game's slot is the one in
front. The slot's number comes from its status strip text in its own bank (`[7] ` at #F68A),
read once by `Nx.TaskInit`.

- At the start, before it touches anything, `TaskStart` notes the console's screen registers
  (`Nx.Snap`, `Nx.ConSave`): the tilemap's (#6B, #6C, #6E, #6F, the scroll #2F-#31), the layers
  (#15, #68, #69), the transparency (#14, #4A, #4C), the palette control (#40, #43) and the
  tilemap's first two colours, Layer 2's bank, mode and scroll (#12, #70, #16, #17, #71) and its
  port #123B. Then it waits until it's in front.
- Each frame, before it hands the CPU over, `Nx.Snap` notes the same registers as the game has
  them. The hypervisor only ever has the CPU inside one of the game's BDOS calls, so that is
  always the game's last word.
- After each `Yield` the game asks `Front()`. If another slot has come to the front (Caps Shift +
  1, TOP ...), CyborgOS has drawn its console in bank 5's second page, which the game's registers
  don't show - so the game puts the console's registers back (`ConIn`, `Back`, `ConOut`), waits
  without touching anything until it's in front again, then puts its own back (`Back`) and
  carries on where it was.

The game's pictures are never touched: its map and tiles are in bank 5's first page, its Layer 2
in its own store pages, its sprites in the sprite RAM. So nothing is redrawn: the title screen,
a talk with its faces, a menu, the street all come back as they were.

### The memory: one flat 64K

| Address | What |
|---|---|
| #0000-#00FF | CP/M's page zero (CyborgOS's) |
| #0100-#BEF4 | the program, its arrays and variables |
| #BEF5-#BEFF | free |
| #BF00-#BF7F | the page table |
| #C000-#DFFF | MMU slot 6: bank 5's first page - the tilemap at #C000, the tiles at #CC00 |
| #E000-#FFFF | the slot's own top page: LoadCity's buffers at #E000 while loading, CyborgOS's stub (#EF00), font, console page, switch |

## The debugger

`MON LSGAME.MAP 7` in slot 8: CyborgOS's own monitor (apps/mon), with a map made from the
game's symbols. The keys 1-8 pick a page off its toolbar:

1. Home - the list of pages
2. Player - day, minutes, money, energy, room, floor, X, Y ... (3 pages)
3. Round - the bag, deliveries
4. Talk - talking, the face, speaker, mood, tune
5. Frame - the frame count, the minute ticks, the keys
6. Program - the program in hex from #0100
7. Pages - the page table, bank by bank
8. Console - the game slot's console text

R reads the page again (the values are live), Enter opens the chosen link, B goes back. It reads
the game's memory through CyborgOS (BDOS 131 op 10) while the game runs.

On the Next, Caps Shift + 5-8 (the arrow keys) are CyborgOS's slot keys, so MON's own arrows
(next link, scrolling) can't be reached; that's why every view is on the toolbar.

## Tested

In NTC's emulator (zxnrun with nextemu's picture), on CyborgOS-Next 974b78e2 built by its own
`tools/nexarc/build.sh`, untouched. The emulator has no esxDOS, so the test driver
(`test/cosbot.py`) is the SD card: it answers `rst 8` from a folder on the PC (open, read,
write, close, seek, the folder's entries, the drive). With `LSEOUL/` on that card:

- the commands above, all in their slots, the game loading its city (about 5 seconds) and
  running at 50 frames a second beside the five services;
- game -> console -> game at the "WHAT DO YOU DO?" menu; game -> MON -> TOP -> game at the name
  screen with the face, then on playing; the console clean each time (no game picture behind it);
- MON's page table view matching the game's memory.

Not on a real Next yet.

## Not done yet

- **The game and TOWN aren't joined.** TOWN runs beside the game and keeps the hundred's days,
  but the game still works out where people are itself (`WhereAt`). Reading TOWN's table every
  frame through a port is too slow (a port call sleeps the caller a tick); that needs two slots
  sharing a bank (services/docs/HYPERVISOR.md part 4).
- No boot script: the RUN lines are typed by hand.
