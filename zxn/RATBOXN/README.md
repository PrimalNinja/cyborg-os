# RATBOXN - RATBOX on the ZX Spectrum Next's screen

CyborgOS's RATBOX (apps/rat/RATBOX.bas: a box of pet rats, a swarm on one model, a LUN a rat, RAT
deciding for each) with graphics: the Next's tilemap for the room and hardware sprites for the
rats. The rats' lives are RATBOX's line for line; the screen is new. It runs as a CyborgOS-Next
task like LITTLE SEOUL, on CyborgOS-Next as it is.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

## Build

    bash build.sh <NTC src folder> <CyborgOS folder> [LSENGINE folder]

Out: `build/RATBOXN/` - the folder for the SD card:

| File | What |
|---|---|
| `RATBOXN.CYB` | the program |
| `LSMODEL.CYB` | the model server: THE LITTLE SEOUL ENGINE's copy of MODEL (CyborgOS's own MODEL doesn't fit under the hypervisor with the current NTC) |
| `RAT.CYB` | RAT, from CyborgOS's apps/rat |
| `RATBOX.MDL` | the rats' model, from CyborgOS's apps/rat |

The CyborgOS and LSENGINE folders are only read.

## Run

Copy `build/RATBOXN/` to the SD card, then in CyborgOS-Next:

    CD RATBOXN
    RUN 2 LSMODEL RATBOX
    RUN 3 RAT
    RATBOXN 4 4

`RATBOXN males females` starts a new box; `RATBOXN` alone carries on the saved box
(`RATBOX.SAV` - the same file the text RATBOX keeps, so either can carry on the other's box),
else it asks how many. `RATBOXN m f n` ends after n tenths of a second (for tests).

Keys, as RATBOX: F fill the bowl, T the TV, C clean, M medicine, `.` and `,` the next / last rat,
N the chosen one to the naughty bed, + praise, - scold, Q quit (the box saved, the console back).
Caps Shift + a slot's number switches away and back as usual.

On a CPC it stops at once with "RATBOXN is for the ZX Spectrum Next - on the CPC, RATBOX":
`CybSys.Host()` (BDOS 131 op 20) is asked before any port is touched - on a CPC the Next's
NextReg port #243B would be the PPI.

## The screen

- Rows 0-2: the box (rats, day, the bowl, clean, born, died, CROWDED), the chosen rat (age, food,
  energy, fun, health, ill, expecting, what it's doing), the last thing that happened.
- Rows 3-30: the room, RATBOX's 78 x 19 grid at 4 x 12 pixels a step: the bed (top left), the
  naughty bed (top middle), the bowl (top right), the graves (left), the pen with its fence
  (right), the wheel (bottom left), the boxing ring with its ropes (bottom middle), the TV (bottom
  right: lit when on). The mess and the graves appear where RATBOX puts them.
- Row 31: the keys.
- The rats: brown males, white females, pink babies (smaller), grey when old (40 days), green when
  ill, red when fighting, curled up asleep; they face the way they walk and step as they go. A
  heart over a mating pair, a star over a fight, a yellow arrow bobbing over the chosen one.

A tick of their lives every 5 frames (a tenth of a second, as RATBOX); the sprites move a pixel
or two every frame towards where RATBOX has each rat, so they walk instead of jumping.

## How it's made

- `RATBOXN.bas` - RATBOX's code with its screen (Room, Show) redone and the loop by frames;
  Screen (the Next set up), Room (the floor, walls, places), Pic, Show (the text rows, the TV, the
  graves, the mess), Move (the sprites), TPrint / TPut (the tilemap).
- `tools/rbgfx.py` - draws the tiles and the sprite patterns in code (original art) and writes
  `RBGfx.cls` (the data and Load) and `gfx/tiles.png`, `gfx/sprites.png`. Run it to change them.
- `Nx.cls` - THE LITTLE SEOUL ENGINE's task routines, its own copy: WaitFrame (the frame, the CPU
  handed over, away and back), Snap / Back, ConSave / ConIn / ConOut, Yield, Front, TaskInit.
- `Spr.cls` - the engine's sprite class, as it is.

Memory: the program and its arrays run to #DEAE (the arrays alone are 21K: how each rat likes
each other one is 10,000 bytes), so unlike LITTLE SEOUL it keeps its own pages in MMU slots 6 and
7 and reaches bank 5 (the tilemap, its map at #0000 and its tiles at #0C00) through slot 7 only
while it writes a cell, putting its own page back after. The font is the console's own (its tiles
at bank 5 + #2C00), turned into 4-bit tiles at the start. Layer 2 isn't used.

## Tested

In NTC's emulator on CyborgOS-Next 974b78e2 as built by its own `tools/nexarc/build.sh`, the SD
card a folder on the PC (`test/cosbot.py`): the commands above, the rats deciding through RAT and
the model, walking, mating, fighting in the ring; F and T; Caps Shift + 2 to the model's console
and Caps Shift + 1 back (the box as it was); Q (the console back, "saved - 8 rats").
Not on a real Next yet.
