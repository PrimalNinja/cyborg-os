# THE LITTLE SEOUL ENGINE

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

LITTLE SEOUL taken apart into **the city** and **a game**, so new games can be set in the city.
It is the same game as LILSEOUL - the postie game plays exactly the same, byte for byte the same
data - with a different architecture:

| | LILSEOUL (the original) | LSENGINE (this) |
|---|---|---|
| Program | one `Main.bas`: city and game mixed | `City.bas` (the engine) + `Game.bas` (the game) |
| City data | `build/LILSEOUL.DAT` | `build/LSENGINE.DAT` (the same bytes: game.json's name is the file's) |
| Making a new game | rewrite Main.bas round its game | keep City.bas, write a new Game.bas |
| The town (later) | the hundred's days in Main.bas | also `services/`: the town on CyborgOS, people deciding with RAT |

For the **ZX Spectrum Next**, in **NTC BASIC**, built with the current NTC (2026-10-21): 774 bytes
free under #BE00 (LILSEOUL: 793; `CityStart`, the city's start-up as a Sub of its own, costs 19).
Both dropped NTC's Long arithmetic (about 900 bytes of library): money is kept in hundreds of won
(an Integer: `Won` shows it as W12,500) and the face seeds' sd * 37 + 11 is done in 24 bits by a
small asm Function (`Part`) - the same faces as before.

## What is what

| | The engine (the city) | The game (LITTLE SEOUL, the postie) |
|---|---|---|
| BASIC | `City.bas`: start-up, walking, the streets and insides, doors, lifts, stairs, the subway, the hundred's days, strangers, cars, talking and faces, the scene player, the map, hyperspace, the frame loop (`Round`), Space (`Act`) | `Game.bas`: the title, a new postie, the season of days, the bag, deliveries, knocking, mailboxes, shop counters, the stats and the HUD, payday, strikes, the endings |
| Classes | all of them: `Nx`, `Spr`, `Tiles`, `Sfx`, `Board`, `L2`, `World`, `Town`, `Data`, `GfxData`, `Face`, `FaceSet`, `GameSet` | - |
| Story | `scripts/CHAT.txt`, `SHOPS.txt`, `STRANGERS.txt`, `THINGS.txt` - the city's voices | `scripts/POST.txt`, `DELIVER.txt` |
| Tools | `tools/` (blocks, city, templates, art_city, facepack, people, storyc), `gfxtool.js`, `build.js` | - |
| Pictures | `gfx/` (the street's sprites and tiles), `gfx_faces/` | - |

**`docs/NEWGAME.md` says how to make a new game on it.** `City.bas`'s header lists what it needs from
a game; lines marked `' GAME:` inside it are the postie game's rules that a new game changes.

## The town as a service (CyborgOS)

`services/` is the town running on its own in a CyborgOS slot: TOWN (the hundred living their
days, from this city's own data: `services/towndat.py` reads `tools/world/` and `tools/people.json`),
deciding with RAT through LSMODEL (the engine's own copy of CyborgOS's MODEL) and three models
(SUIT, KEEPER, STAR). Tested on the CPC CyborgOS; the game slot on the Next waits for the Next
hypervisor (`services/docs/HYPERVISOR.md`). `services/README.md` has it all.

## Keys (the postie game)

| | |
|---|---|
| Q A O P (or the joystick) | walk / move |
| Space (fire) | talk, knock, buy, pick / go on |
| M (fire 2) | the bag; then Space for the map (Q A O P look round) |
| T | hyperspace: out of anywhere (stuck, lost, cornered) to a random free spot on a street |

## Building

```
python3 tools/blocks.py      # the blocks
python3 tools/city.py        # the city -> tools/world/, Town.cls
python3 tools/art_city.py    # the street's sprites -> gfx/
python3 tools/facepack.py    # the two sprite sets
python3 tools/storyc.py      # story + city + people + sprites -> build/LSENGINE.DAT, Data.cls
node build.js path/to/ntc/src
```

`build/LSENGINE.NEX` goes on the SD card. `test/lsbot2.py` plays it in the emulator (`nextemu.py` is
in TOOLS.zip): `LSG=<this folder>/ python3 test/lsbot2.py 30000 1 walk`.

The city itself - its 192 screens, districts, landmarks, 1,500 doors, the hundred - is described in
LILSEOUL's README; it is the same city.
