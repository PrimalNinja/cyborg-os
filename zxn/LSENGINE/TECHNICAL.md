# THE LITTLE SEOUL ENGINE

LITTLE SEOUL (the postie game, `../LILSEOUL`) taken apart into the city and a game, for the ZX
Spectrum Next in NTC BASIC. `City.bas` is the engine: 192 screens of Seoul, shops and their
insides, lifts and stairs, the subway, the hundred people living their days, strangers, cars,
talking with faces, the scene player, the map, hyperspace and the frame loop. `Game.bas` is the
postie game on top of it: the title, a new postie, twenty days of rounds, the bag, deliveries,
knocking, payday, strikes and the endings. It is the same game as LILSEOUL, with the same data
byte for byte; only the program is split. A new game keeps `City.bas` and writes its own
`Game.bas`.

`services/` is the next step: the town as a CyborgOS service, the hundred deciding their days with
RAT, tested on the CPC CyborgOS.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

## Technical specs

| | |
|---|---|
| Machine | ZX Spectrum Next, 28MHz (`Option Turbo` in `Game.bas`; `build.js` also builds with turbo on) |
| Language | NTC BASIC, built with the current NTC (`/home/claude/work/ntc/src`, 2026-10-21). Inline Z80 in 13 asm blocks in `City.bas` and in the classes; `Game.bas` has none |
| Screen | Layer 2 256 x 192, one byte a pixel, bank 16 (pages 32-37): the streets and insides, drawn a 16 x 16 block at a time. The tilemap 40 x 32, 2 bytes a cell (tile and palette row), in bank 5: text, panels, the HUD. 128 hardware sprites: you, the people, cars, icons, and the faces in a talk. Order sprites, tilemap, Layer 2 (`Nx.OrderSUL`) |
| Sprites | two sets of patterns take turns in the sprite RAM: the street's (`GameSet`) and the faces' (`FaceSet`, KPOP GROUP MANAGER's face parts), swapped at the start and end of each talk |
| Sound | the first of the Next's three AY chips, 3 channels of effects (`Sfx.cls`), a 16-note tune on the title |
| Program area | #0040-#BDFF in banks 8-10, bank 5 at #C000. The code ends at `ntc_bss` #B14D, the arrays take #9AD (2,477) bytes after it, and `ntc_free` is #BAFA: 774 bytes free under the #BE00 limit. `LSENGINE.asm` checks it: "the program and its arrays must end below #BE00 (the stack is #BE00-#BFFF, the screen #C000-#FFFF)". LILSEOUL's `ntc_free` is #BAE7 (793 free): `CityStart`, the city's start-up as a Sub of its own, costs 19 bytes |
| No Long arithmetic | money is an Integer in hundreds of won, and `MakeLook`'s seed sum (sd * 37 + 11, past an Integer for most seeds) is the asm Function `Part`, done in 24 bits. Nothing uses a Long, so NTC's Long library (about 900 bytes) isn't linked |
| Data | 458,752 bytes (`build/LSENGINE.DAT`, 28 banks): the story, the dictionary, the people, both sprite sets, the city's tables and its 158 blocks. All in the Next's other RAM, read through MMU slots 6 and 7 |
| Banks used | `game.json`'s `banks`: 0-4, 6, 7, 11-15, 19-34 (the data) and 47 (sprite patterns and tiles); plus 5 and 8-10 (the program) and 16-18 (Layer 2). The NEX line: `SAVENEX BANK 5, 2, 0, 1, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 19, 20, ... 34, 47` |
| Free | banks 35-46. Nothing past bank 47, so it fits a 1MB Next |
| Source | `City.bas` 2,645 lines (110 Subs and Functions, 13 asm blocks); `Game.bas` 567 (25, no asm). Classes: generated `GfxData.cls` 1,002, `Data.cls` 362, `FaceSet.cls` 133, `GameSet.cls` 88, `Town.cls` 49; by hand `Nx.cls` 215, `Spr.cls` 212, `L2.cls` 205, `Tiles.cls` 195, `World.cls` 184, `Board.cls` 141, `Sfx.cls` 88, `Face.cls` 68. LILSEOUL's `Main.bas` was 3,155 lines; `City.bas` and `Game.bas` together are 3,212. Services: `TOWN.bas` 482, `LSMODEL.bas` 425, `LSTEST.bas` 47, `towndat.py` 94, three models of 50 lines |
| Tools | 2,460 lines of Python in `tools/` (`city.py` 677, `storyc.py` 618, `blocks.py` 432, `art_city.py` 244, `facepack.py` 133, `templates.py` 123, `people.py` 91, `artkit.py` 81, `cvkit.py` 61); `gfxtool.js` 567, `build.js` 103 |
| Story | 210 scenes in `scripts/`: the city's `CHAT` 387 lines, `SHOPS` 568, `STRANGERS` 79, `THINGS` 61; the game's `POST` 367, `DELIVER` 674. 33,668 bytes of scenes after packing, with a 563-word dictionary |
| Tested | `test/lsbot2.py` played LSENGINE and LILSEOUL over 30,000 frames with the same seed: the two logs are the same, line for line (day 3, 12:50 game time, 4 of 4 delivered at the end) |

## How it's built

### The split

LILSEOUL was one `Main.bas` with the city and the game mixed through it. Here:

| | The city (`City.bas`) | The game (`Game.bas`) |
|---|---|---|
| What | start-up, walking, streets and insides, doors, lifts, stairs, the subway, the hundred's days (`WhereAt`), strangers, cars, talking and faces, the scene player (`Play`), the map, hyperspace, the frame loop (`Round`), Space (`Act`) | the title, a new postie, the season of days (`Season`, `OneDay`), the bag, deliveries, `Knock`, `Mailbox`, `Counter`, the stats, the HUD, payday, strikes, the endings |
| Classes | all of them | none |
| Scripts | `CHAT`, `SHOPS`, `STRANGERS`, `THINGS` | `POST`, `DELIVER` |
| Tools, pictures | `tools/`, `gfxtool.js`, `build.js`, `gfx/`, `gfx_faces/` | - |

`game.json` lists `Game.bas` first, so the program starts at the top of `Game.bas`:

```basic
' ---------------------------------------------------------------- the game starts here
CityStart
Do
  TitleScr
  NewMe
  Season
Loop
```

Both files are `Option Explicit` modules in one program, so a `Public` in either is seen by the
other, and a Sub in one is called from the other by its name.

#### What City.bas calls in Game.bas

`City.bas`'s header lists what a game must have. A search of `City.bas` for the names of
`Game.bas`'s Subs finds these calls:

| Sub | Called from (`City.bas` line) | What LITTLE SEOUL does in it |
|---|---|---|
| `Clockwork` | `Round` (2376), every frame | a game minute every 25 frames; hunger; "hungry" and "tired" scenes |
| `Hud` | `TalkOff` (542), `TalkTo` (1898), `Enter` (2179), `Stall` (2528) | the top and bottom lines: day, clock, money, bag, energy, where you are |
| `Stat s, v` | `Play` (794): a scene's `!STAT` | energy, speed, the boss, rep, time, the lookup, the map app, hair, clothes, hanbok, flowers |
| `Feel v` | `Play` (788): a scene's `+N` / `-N` | `aff()` of whoever you're talking to |
| `BagScreen 0` | `Round` (2387): M | the bag; Space there shows the city's `MapScreen` |
| `Knock s, fl, u` | `Door` (2482: a house), `Act` (2516: a flat's door) | a delivery, nobody in, a neighbour, or one of the hundred at home |
| `Mailbox` | `Act` (2510) | every letter for this building in the lobby's mailboxes |
| `Counter` | `Act` (2521) | a delivery to the shop, or the shop's own scene |
| `AfterShop` | `TalkTo` (1878) | a new hairdo shows |
| `BagFor s, fl` | `Door` (2488) | the first item not yet delivered for a building |
| `ItemWords j`, `Delivered j, how` | `TalkTo` (1866, 1868) | the item's words for a scene; pay, tips, hearts |

`HudTime` is not on the list: `City.bas` never calls it; only `Game.bas`'s own `Clockwork` does,
so a new game doesn't need it.

#### The lines marked ' GAME:

44 lines inside the city's routines carry the postie game's rules. Each ends in `' GAME:` (the
header names the mark on two more lines). A new game changes or drops them:

| Where | Lines | What they do |
|---|---|---|
| `TalkOff` | 542 | `Hud` after a talk |
| `Play` | 788, 794, 800, 801 | `+N` / `-N` go to `Feel`, `!STAT` to `Stat`; `$N` changes `money` (not below 0: `broke`, then the "no money" scene) |
| `TalkTo` | 1864-1898 (11 lines) | one of the hundred with a parcel for them: delivered by hand; flowers as a gift; a stranger who knows where someone in the bag lives; `AfterShop`, `Hud` |
| `Cars` | 1929-1931 | hit by a car: 10 minutes and 5 energy, and the "hit" scene once a day (`hitToday`) |
| `DrawAll`, `Arrow` | 2014, 2021-2025 | the map app's arrow to the next delivery's street |
| `Enter`, `Stall` | 2179, 2528 | `Hud` |
| `Round` | 2376, 2387, 2389 | `Clockwork`; M is `BagScreen`; the day ends at `T_END` (18:00) |
| `Walk` | 2408, 2409 | 3 pixels a frame with coffee (`speedT`), 1 under 10 energy |
| `Door` | 2482, 2488 | a house's door is `Knock`; an apartment block's guard when the bag has something for it |
| `Act` | 2510, 2516, 2521 | `Mailbox`, a flat's door (`Knock`), a counter (`Counter`) |
| `Lift` | 2551 | the stairs take a point of energy a floor |
| `Subway` | 2587, 2588 | W1,400 a ride (`money` 14) |
| `MapScreen` | 2621-2627 | the bag's deliveries on the map: their district, or their street after the PC bang's lookup |

Some examples, as they are in `City.bas`:

```basic
      Case Data.OP_MONEY
        v = SByte(pc + 1)
        If money + v * 10 < 0 Then broke = 1 : Exit Do   ' GAME:
        money = money + v * 10   ' GAME:
```

```basic
  sp = 2
  If speedT > 0 Then sp = 3   ' GAME:
  If energy < 10 Then sp = 1   ' GAME:
```

#### The Public variables

The city keeps what a game shares with it; the game keeps only what's its own.

`City.bas`'s Publics, by what they hold:

| Variables | Meaning |
|---|---|
| `room`, `inShop`, `floor`, `floors`, `sType`, `streetRoom`, `doorCell` | where you are: a street (`room` 0-191) or inside shop `inShop` (-1 in the street) on `floor`; its type, its door's street and cell |
| `px`, `py`, `pdir`, `pstep`, `stun`, `pPal` | you on the screen, facing, walking frame, stunned frames, your clothes' palette row |
| `day`, `mins` | the clock: the day and minutes from midnight. The hundred keep to it |
| `money`, `energy`, `speedT`, `boss`, `lookup`, `hasApp`, `flowers`, `hitToday` | the postie's state that the city's `' GAME:` lines read |
| `bP()`, `bShop()`, `bKind()`, `bDone()`, `nBag` | the bag: whose (a person, or -1 a shop), the building, letter 0 / parcel 1, done. Here because `TalkTo`, `Arrow` and `MapScreen` read them |
| `cLook(35)`, `cst(3)`, `themP`, `themName`, `hatV` | the cast's four faces (9 bytes each), who they are, them |
| `aff(99)`, `met(99)` | how the hundred feel about you; who you've met |
| `nRoom(9)`, `npx`, `npy`, `ntx`, `nty`, `nst`, `ntm`, `nkind`, `npal`, `nwho`, `ndir`, `nicon`, `nyf` | the ten people about |
| `cx(1)`, `crm`, `cl`, `cv`, `ck`, `cpal` | the two cars |
| `rc(255)`, `sh(7)`, `ty(63)`, `battr(255)`, `rec(31)`, `tb(23)` | this room's, a shop's, a type's records; block attributes; a person's record; a table's word |
| `sb(447)`, `lb(63)`, `de8(7)` | the scene being played, a line of it, its directory entry |
| `txt`, `pName`, `placeS`, `distS`, `itemS`, `tokT`, `tokH`, `lab0`-`lab2` | text: the HUD line, your name, where you are, the tokens, the choices |
| `frames`, `quit`, `pick`, `talking`, `tune`, `fast` | the frame count; `Round` ends when `quit` is set; the last choice picked |
| `i`, `k`, `n`, `f` | loop counters. `Game.bas` uses `k` without its own `Dim` |

`Game.bas`'s Publics are the postie's own and nothing in `City.bas` reads them: `myLook`, `male`,
`me`, `bFloor()`, `bUnit()`, `bFrom()`, `nDone`, `tickM`, `rep`, `strikes`, `total`, `totalDone`,
`hanbok`, `wantHair`, `hungry`. Its constants: the stats `S_ENERGY` to `S_ASK` (the scripts'
`!STAT` numbers), `BAGMAX` 12, `T_START` 540.

### CityStart

The city's start-up, once, first thing:

```basic
Sub CityStart()
  Nx.Border 0
  Tiles.Init
  Spr.Init
  GfxData.Load
  schedPg = Data.W_SCHED
  Sfx.Init
  Board.Init
  L2.Init
  Data.Init
  World.Init Data.W_BLOCKS
  Nx.Layers Nx.OrderSUL
  Nx.Reg &H4A, 0
  Colours
  recOf = -1
  Data.Copy Data.W_ATTR, 0, 256, VarPtr(battr)
  fxBase = GfxData.S_ICON : fxFl = Spr.Pal * 15
End Sub
```

The tilemap on and the ULA off; the sprites; the palettes, tiles and sprite patterns from
`GfxData`; the AY; the tilemap's attribute mode; Layer 2; `Data.Init` (it does nothing when it
runs: its asm is what puts the `.DAT` file in the banks when the NEX is made); where the blocks'
pictures start; the layer order; the text palettes (tilemap rows 0-7); then the 256 block attributes copied into
`battr`, which walking reads every frame.

### Making a new game

`docs/NEWGAME.md` says it step by step. In short: copy the folder, give `game.json` a new `name`
(8 letters: the NEX and the `.DAT` file), keep `Game.bas` first in `files`, write a new
`Game.bas` that calls `CityStart` then puts the player somewhere (`GoStreet` or `GoInside`), sets
`mins` and `day` and calls `Round`. It must have each of the Subs the city calls (empty is fine)
and change or drop the `' GAME:` lines. Its story goes in new script files added to `FILES` in
`tools/storyc.py`, in place of `POST` and `DELIVER`. `NEWGAME.md` puts `Game.bas`'s code at about
5.8K, measured from the build: that, plus the 774 bytes free and whatever the dropped `' GAME:`
lines gave back, is room for a new game.

`storyc.py` takes the name from `game.json`:

```python
NAME = json.load(open(os.path.join(ROOT, 'game.json')))['name']     # the game's name: build/NAME.DAT
```

and writes `build/NAME.DAT`, `Data.cls` (with `INCBIN "NAME.DAT"`) and `game.json`'s `banks`.

### The classes

| File | What it does |
|---|---|
| `Data.cls` | generated by `tools/storyc.py`: the scene numbers, the table pages, `Init` (the `INCBIN`s), `Copy` (bytes from any page to below #C000), `Expand` (a line of a scene with its dictionary words put back) |
| `Town.cls` | generated by `tools/city.py`: the city's numbers (192 screens, 1,523 shops, 40 types, 30 stations, 54 districts), block attributes, blocks by name, shop types, insides, and the record layouts as comments |
| `World.cls` | draws a screen on Layer 2 from its 192 block numbers; `Mini` draws one as 16 x 12 dots for the map |
| `GfxData.cls` | generated by `gfxtool.js` from `gfx/`: palettes, tiles, the street's sprite patterns (71 in bank 5, the rest and the tiles in bank 47) |
| `Face.cls` | a face from 15 sprite parts (clothes, face, mouth, eyes, hair, accessory), 1x, 2x or 4x, and a hat |
| `FaceSet.cls`, `GameSet.cls` | generated by `tools/facepack.py`: load one sprite set's patterns and palettes from the data banks |
| `Board.cls` | the tilemap as a text board: `Put`, `Text`, `Rect`, `Pal`, `Clear` |
| `L2.cls` | Layer 2: `Span`, `Rect`, `Plot`, `Big` (the title's big letters), `Tint` (the edge marks) |
| `Spr.cls` | the 128 sprites: `Put` and `Hide` write a table, `Show` sends it after `Frame` |
| `Tiles.cls`, `Nx.cls`, `Sfx.cls` | the tilemap's set-up; NextRegs, palettes, layers; the AY |

All the classes are the same files as LILSEOUL's except `Data.cls`, whose only change is the
`.DAT` file's name.

### The main loop: Round

`Round` is the city's frame loop. A game sets `quit` (or `T_END` does) to end it:

```basic
Sub Round()
  Dim v As Integer
  quit = 0
  Do
    Tick
    Clockwork   ' GAME:
    If stun > 0 Then
      stun = stun - 1
    Else
      Walk
    End If
    People
    If rc(194) And 1 Then Cars
    DrawAll
    v = Key()
    If v = 5 And stun = 0 Then Act
    If v = 6 Then BagScreen 0   ' GAME:
    If Keys.Down(Keys.KeyT) And stun = 0 Then Hyper
    If mins >= T_END Then quit = 1   ' GAME:
  Loop Until quit
End Sub
```

LITTLE SEOUL's day around it, in `Game.bas`: `Season` runs `OneDay` for each of the 20 days.
`OneDay` sets the clock to 9:00, makes the bag (`MakeBag`: 3 items on day 1, 3 + day * 9 \ 20 after,
at most 12, from further out each day), puts you in the Central Post Office (`GoInside
Town.POSTSHOP, 1, 160, 64, 1`), plays the Postmaster's morning, shows the bag with every address
(`BagScreen 1`), then `Round`. After it: all delivered is praise and +5 boss; half or more is fine;
under half is a strike, and three is the sack. Every fifth day is payday (+W50,000: `money + 500`).
After twenty days `Season` scores the round and looks for the one with the highest `aff` of 60 or
more.

### The frame

`Tick` is a frame: `Frame` (wait for the frame), `Spr.Show` (the sprite table to the hardware),
`Sfx.Update`, `frames`, the floating icons, and the title tune:

```basic
Sub Tick()
  Frame
  Spr.Show
  Sfx.Update
  frames = (frames + 1) And &H7FFF
  FxMove
  If tune Then Music
End Sub
```

Every wait in the engine (`WaitF`, `AnyKey`, `NextKey`, `WaitGo`, the letters of a scene coming up
two at a time) goes through `Tick`, so the frame count and the sound keep going in menus and
talks too.

Then `Clockwork` (the game's clock: a minute every 25 frames, so a game minute is half a second,
and `OffStage` and `HudTime` once a minute), walking, the people, the cars on streets that have
them (`rc(194)` bit 0), and `DrawAll` puts every sprite. Layer 2 is only drawn when you go
somewhere new (`Enter`), so a frame is sprites and a few tilemap cells.

`Key()` gives 1-4 for Q A O P (or the stick), with 14 frames before the first repeat and 6 after;
5 for Space or fire and 6 for M or fire 2, once a press.

## Memory

### The program's 64K

| Address | What |
|---|---|
| #0040-#B14C | the program: NTC's start and library, `Game.bas`, `City.bas`, the classes' code and asm |
| #B14D-#BAF9 | the arrays and variables (`ntc_bss`, #9AD bytes) |
| #BAFA-#BDFF | free: 774 bytes |
| #BE00-#BFFF | the stack. `SlotPal`'s 77-byte colour table sits at its foot (`sp_tab: equ #BE00`: "it never gets that deep") |
| #C000-#DFFF | bank 5: the tile definitions |
| #E000-#E9FF | bank 5: the tilemap, 40 x 32 x 2 bytes |
| #C000-#FFFF | MMU slots 6 and 7 are swapped for two data pages at a time, then pages 10 and 11 (bank 5) put back |

When the NEX is made, bank 5 also holds the first 71 sprite patterns (`GfxData`'s `ORG #C000` and
`ORG #F400`); `GfxData.Load` sends them to the sprite RAM and then writes the tiles over #C000.

### The data banks

`tools/storyc.py` packs everything into 8K pages and `Data.cls`'s `Init` puts them in their banks
with `INCBIN`. Its page list leaves out the program (banks 5, 8-10) and Layer 2 (16-18):

```python
RUNS = [(0, 9), (12, 15), (22, 31), (38, 93)]          # (bank 47: the sprites' and tiles' (gfxtool's gfxbank))
```

What's where (the constants in `Data.cls`, the rest read from the `.DAT` file):

| Pages | What |
|---|---|
| 0-1 | the dictionary: 563 words, a 2-byte index each then the words. The code has room for three windows (pages 0, 2, 4); this story fits the first |
| 6 | the scene directory (`DIRPAGE`): 210 entries of 5 bytes (page, offset, length), then a picture byte each (all 255: none, and the engine doesn't read them) |
| 7 | the hundred (`PPAGE`): 100 records of 32 bytes, then the full names, jobs, hobbies, cities and traits (6,532 bytes in all) |
| 12-14 | the faces' sprite set (`FACEPAGE`): `tools/faces.bin`, two pages of patterns and the palettes |
| 23-25 | the street's sprite set (`GAMEPAGE`): `tools/game.bin` |
| 38-45 | `W_ROOMS`: 235 rooms of 256 bytes (192 streets, then the 43 insides) |
| 46-47 | `W_SHOPS`: 1,523 shops of 8 bytes |
| 48-56 | `W_TYPES` (40 x 64), `W_HOMES` (100 x 4), `W_STATIONS` (30 x 32), `W_DISTRICTS` (54 x 32), `W_WORDS` (64 x 8), `W_NAMES` (56 x 20), `W_BRIDGES` (16 x 16), `W_ATTR` (256), `W_MINI` (256), a page each |
| 57-58 | `W_SCHED`: the hundred's days, 128 bytes each |
| 59-63 | `W_BLOCKS`: 158 block pictures of 256 bytes |
| 63-68 | the 210 scenes, 33,668 bytes |
| 94-95 (bank 47) | the rest of the street's sprite patterns, and the tiles |

Each table starts at the start of a page, so a record's page and offset come from its number
alone: shop s is `Data.Copy Data.W_SHOPS + s \ 1024, (s Mod 1024) * 8, 8, VarPtr(sh)`. A copy can
run on into the next page because both slots are mapped.

`Data.Copy` maps the page and the one after it into slots 6 and 7 (NextRegs #56 and #57 through
ports #243B and #253B), copies with `ldir` to below #C000, and puts pages 10 and 11 back. The page numbers are written into the code itself (`ld (dc_p1 + 1), a`).

## Data structures

### A room (256 bytes, `W_ROOMS`)

From `Town.cls`:

| Bytes | A street | An inside |
|---|---|---|
| 0-191 | its 16 x 12 block numbers | the same |
| 192 | 0 | 1 |
| 193 | its district | - |
| 194 | flags: 1 cars, 2 market stalls, 4 a bridge | - |
| 195 | how many doors (15 at most) | - |
| 196 + 4 each | a door: its cell, its shop (2 bytes), sign x + 16 * width | 196 the keeper's cell, 197 the counter spot, 198-201 people's spots, 202 the lift, 203-206 the flats' doors, 207 the mailboxes, 208 the way out, 209 how many flats |

A street is room 0-191 (16 across, 12 down: `room Mod 16`, `room \ 16`). An inside is room
192 + its template (43 of them, `Town.TP_*`); every shop of a kind shares it, and `GoInside`
picks the ground, upper or top floor's template from the shop's type.

### A shop (8 bytes, `W_SHOPS`) and a type (64 bytes, `W_TYPES`)

| Shop byte | | Type byte | |
|---|---|---|---|
| 0 | type (`Town.TY_*`, 255 none) | 0-2 | the insides: ground, upper, top |
| 1 | floors | 3-4 | floors (least, most) |
| 2 | name: a word, or 128 + a name | 5 | the keeper's sprite (0 none) |
| 3 | number (a flat block's, a house's) | 8-13 | the sign (6 letters) |
| 4 | district | 16-31 | the name |
| 5 | its street | 32-41 | the keeper's title |
| 6 | its door's cell | | |

### A person (32 bytes, `PPAGE`)

From `tools/people.py`: 0 girl, 1 age, 2 height - 100, 3 blood, 4 trait, 5 taste, 6 month,
7 day, 8-16 the look (face, skin, hair, hair colour, eyes, eye colour, mouth, accessory, outfit),
17-19 haunts, 20 job, 21 hobby, 22 city, 24-31 the name. `LoadRec` keeps the last one read in
`rec` (`recOf`), so asking twice in a row costs one copy.

The homes (`W_HOMES`, 4 bytes each): the building (2), the floor, the flat. `HomeAt` reads it into
`tb` each time; there's no copy of the hundred's homes in the program's memory.

### A person's day (128 bytes, `W_SCHED`)

From `tools/city.py`: 3 kinds of day (person + day, mod 3), each 19 half hours from 9:00 to
18:00, 2 bytes each: the shop they're in (their own building means at home), 65535 out of town.
114 bytes used of 128. 64 to a page.

### The people about

Ten slots (`NN`), each with a room number for where they are (`nRoom`): a street 0-191, 256 + a
shop (on its ground floor), -5 (upstairs: only there while you are), -1 nobody. `nwho` is which
of the hundred, or -1 a stranger; `npal` a stranger's look seed. `nst` is what they're doing:

| `nst` | |
|---|---|
| 1 | walking along the street (off the side: on into the next street) |
| 2 | going into a door (`nicon` holds which) |
| 4 | at the counter |
| 5 | going to a seat |
| 6 | sitting |
| 7 | walking out to the way out |
| 10 | inside a shop you're not in |

(`ArriveNpc` also handles a 3, to the counter, but nothing sets it now.)

### The scenes

`tools/storyc.py` compiles `scripts/*.txt` (the format is `scripts/BRIEF.md`) to byte code, at
most 448 bytes a scene (`sb(447)`):

| Op | Bytes | |
|---|---|---|
| 0 `OP_END` | 1 | |
| 1 `OP_SAY`, 2 `OP_NARR` | 1 + text + 0 | a page of up to 5 lines of 34 letters, lines ending in 10 |
| 3 `OP_MOOD` | 2 | the speaker's mouth |
| 4 `OP_CHOICE` | 2 + labels + a jump table | 2 or 3 options, then where each goes, then where after |
| 5 `OP_AFF` | 2 | +N / -N (signed) |
| 6 `OP_ICON` | 2 | a burst of icons |
| 7 `OP_GOTO` | 3 | |
| 8 `OP_FLAG` | 2 | read and passed over |
| 9 `OP_MONEY` | 3 | $N: thousands of won (the engine adds N * 10 hundreds) |
| 10 `OP_WHO` | 2 | who speaks next: 0 you, 1 them, 2 the boss, 3 the colleague |
| 11 `OP_STAT` | 3 | `!STAT n` |

In text, bytes under #60 are letters; 1-7, 11 and 12 are tokens (your name, theirs, the
colleague's, the place, the boss, the district, the item, who it's from, an address); #80-#FF are
the 128 most used dictionary words; #60-#7F and the next byte are the rest.

## The data file and the tools

The city and its data are LITTLE SEOUL's, built by the same tools in the same order (see
Building). `build/LSENGINE.DAT` and `build/LILSEOUL.DAT` are the same 458,752 bytes (`cmp` finds no
difference).

| Tool | Writes |
|---|---|
| `blocks.py` | `tools/blocks.bin`: 158 blocks of 16 x 16 Layer 2 pixels, and each one's attributes (`SOLID`, `DOOR`, `WATER`, `ROAD`, `COUNTER`, `LIFT`, `STAIRS`, `THING`) |
| `templates.py` | the 43 insides as text, a letter a cell (`@` the shopkeeper, `*` the counter spot, `+` where people go, `A` a flat's door, `X` mailboxes, `L` the lift, `E` the way out ...) |
| `city.py` | the 192 screens, real districts where they roughly are, the Han and its bridges, the subway, every door a shop, flat, office or house; the hundred's homes (spread over the districts) and days; `tools/world/*.bin`, `manifest.json`, `Town.cls`, `map_preview.png`. Its random numbers are seeded (2026, and 77 for the days) so it makes the same city every time |
| `people.py` | `people.json` and `people.bin` from KPOP GROUP MANAGER's people. It imports `idols_base`, which isn't in this folder: the two files it made are kept |
| `art_city.py` (`artkit.py`, `cvkit.py`) | `gfx/sprites.png`, `spr_pal.png`, `layout.txt`: the postie, men, women, ajummas, grandads, cars, icons |
| `facepack.py` | `faces.bin`, `game.bin`, `FaceSet.cls`, `GameSet.cls` |
| `storyc.py` | `build/NAME.DAT`, `Data.cls`, `game.json`'s `banks`. `--check FILE...` checks scripts |
| `gfxtool.js` | `GfxData.cls` from `gfx/` (run by `build.js`) |

A person's day, from `city.py`: on a working day (kind 0, and kind 1 for every other person) a
run of 10-16 half hours at the nearest workplace that fits the job, lunch in the middle, and
maybe a haunt after; the flight attendants, pilots and the sea people are out of town on kind 1;
other days one or two outings to their haunts, home the rest.

## How the important routines work

### WhereAt: where one of the hundred is

`WhereAt(p, t)` is asm. It works out the half hour from 9:00 (0-18: before 9:00 is 0, after is
18), the kind of day ((day + p) mod 3), and reads the one word straight out of `W_SCHED` through
slot 6:

```asm
wa_h:
            ld a, ({day})
wa_p:
            add a, 0
wa_m:
            sub 3
            jr nc, wa_m
            add a, 4
            ld c, a                 ; the kind of day + 1
            ld a, b
            add a, a
wa_k:
            dec c
            jr z, wa_o
            add a, 38
            jr wa_k
```

`wa_p + 1` has p written into it at the start. The record is (p And 63) * 128 into page
`schedPg` + p \ 64. The answer is a shop, so `WhereAt(p, mins) = s` is "p is in building s now",
and `WhereAt(p, mins) = HomeAt(p)` is "at home". `Knock` uses it to say whether anyone's in;
`Gather` uses it to bring the hundred into the street or shop you're in.

### Gather and the people about

`Gather` goes through the hundred. In a street, the ones whose place changed this half hour
(in its first ten minutes) and whose new place has a door in this street are put on the pavement
walking to it. In a shop, the ones due there who don't live there sit down (or, at the turn of a
half hour, walk in at the door). `Seen` makes sure nobody is put in twice, and that you, the boss
and the colleague never turn up as walkers.

```basic
    If inShop < 0 Then
      If (mins Mod 30) < 10 And d <> WhereAt(p, mins - 30) Then t = DoorOf(d)
    ElseIf d = inShop And HomeAt(p) <> inShop Then
      t = 0
    End If
```

`Arrive` (going into a room) keeps the walkers who belong here, clears the ones of the hundred
who don't, calls `Gather`, and fills the street with strangers up to a number set by the
district's kind (`"534423224"`: 5 in a shopping district, 2 in a market, park or by the river),
or 0-2 people in a shop (1-3 upstairs).

`People` moves everyone in the room one step a frame (`StepNpc`, asm: across then up into a door
in the street; inside along the aisle, column 7), counts down the ones sitting, brings a new
stranger in from the side now and then, and at each new half hour calls `Gather` again.
`OffStage`, once a game minute, counts down everyone in other rooms: they leave their shop for
its street when their time's up, so if you follow someone into a cafe and come back out later,
they're still there or they've gone.

Where they are is one number for the street, the shop's ground floor or upstairs (`HereKey`).
`NewNpc`, `Seen` and `NearNpc` each work it out again inline in asm rather than call it.
`NewNpc` then looks for a free slot (-1), or takes over one that's in another street.

### MakeLook and Part: a face from a seed

Strangers, shopkeepers, residents and neighbours get a face made from a number: the same number,
the same face. `MakeLook` builds the 9 bytes of the look:

```basic
  For q = 0 To 8
    cLook(9 + q) = Part(sd, Val(Mid$("010305071113171719", q * 2 + 1, 2)), Val(Mid$("237463617", q + 1, 1)))
  Next
```

Part k is ((Abs(sd * 37 + 11)) \ d) Mod m. sd * 37 is past 32767 for most seeds, and a Long would
pull in NTC's Long library, so `Part` does it in 24 bits: sd * 8 + sd, * 4 + sd (= 37), with the
top byte in A, then a 24-bit divide by d and a 24-bit remainder by m:

```asm
            ld h, d
            ld l, e
            ld c, 0                 ; C:HL = sd, then * 8 + sd, * 4 + sd (= * 37)
            add hl, hl
            rl c
            add hl, hl
            rl c
            add hl, hl
            rl c
            add hl, de
            ld a, c
            adc a, 0
            add hl, hl
            rla
            add hl, hl
            rla
            add hl, de
            adc a, 0
```

A negative seed is made positive first and the 11 taken off instead of added, which is the same
as Abs. The README says it gives the same faces as before. A stranger's walker also
takes its colours from its face: `SlotPal` writes the skin, hair and clothes colours of the look
into that slot's sprite palette row, so the walker you talk to looks like the face you see.

### Walking and Free

`Walk` reads Q A O P (or the stick), moves x then y, each only if `Free` says the feet can stand
there. `Free` tests the four corners of the feet (a box at the bottom of the 16 x 16 sprite)
against the room's blocks and `battr`:

```asm
            ld hl, {rc}
            add hl, de
            ld e, (hl)
            ld hl, {battr}
            add hl, de
            bit 0, (hl)             ; Town.A_SOLID
            jr nz, fr_no
...
fr_off:     db 3, 11, 12, 11, 3, 15, 12, 15
```

If you're already stuck in something (a car threw you there) you can walk out of it. Off the
edge of a street (`px < -6`, `px > 246`, `py < -10`, `py > 180`) `Flip` loads the next street and
checks you can stand where you'd be; if not, you stay. The edge cells you can walk off are tinted
(`EdgeMarks`, `L2.Tint`). Walking onto a door or the stairs (`A_DOOR`, `A_STAIRS` under the feet)
is `Door`: a house is `Knock`, any other shop is `GoInside s, 1, 112, 160, 1`; inside, the way out
puts you back in the street by the door.

### Doors, lifts and the subway

`GoInside s, fl, x, y, d` loads the shop, its type, the template for that floor, its name and
district, and calls `Enter`: draw the room on Layer 2, the edge marks, the signs and flat numbers
on the tilemap (`RoomText`), who's here (`Arrive`) and `Hud`.

`Act` (Space) is whatever's in front of you: a person near you (within 17 pixels each way:
`NearNpc`) is `TalkTo`; else the block you face. In the street: a market stall (an ajumma), a
vending machine, a postbox. Inside: mailboxes, the subway's ticket machine, binoculars, an
exhibit, a flat's door, the lift (`A_LIFT`), a counter (`A_COUNTER`).

`Lift` asks for a floor (1 to `floors`): the lift takes a minute; the stairs a minute a floor.
`Subway` lists the 30 stations with their lines: a ride is 4 minutes plus 2 a street of distance,
and drops you at the other station's ticket hall.

### Cars

Two cars at most (`NCAR`), on streets with the cars flag. A new one comes one frame in 80, lane 0
going left from the right edge, lane 1 going right. When you stand on the zebra crossing (x
100-132, on the lane) they stop. Off the side they go on into the next street and wait at its
edge, so if you follow one it's there. Hit by one: a honk, 50 frames stunned, thrown to the
pavement, and the game's `' GAME:` lines.

### Talking: TalkOn, Play, TalkOff

The sprite RAM holds 128 patterns: not enough for the street and the faces both. So a talk swaps
them: `TalkOn` hides every sprite, loads `FaceSet` from `Data.FACEPAGE` and points the floating
icons at the face set's. `TalkOff` loads `GameSet` back, puts every walker's colours back (`SlotPal 255, 0`), redraws the
signs and calls `Hud`.

`Play id, a` reads the scene's 5-byte directory entry, copies the scene into `sb`, and runs it:

```basic
  ln = id * 5
  Data.Copy Data.DIRPAGE + ln \ 8192, ln And 8191, 5, VarPtr(de8)
  ln = de8(3) + de8(4) * 256
  If ln = 0 Then Exit Sub
  Data.Copy de8(0), de8(1) + de8(2) * 256, ln, VarPtr(sb)
```

A page of text is `Data.Expand` a line at a time into `lb` (the dictionary words put back:
`Expand` maps the dictionary's pages, finds the word in the index, and copies it), then `PrintLB`
puts it on the tilemap a letter at a time, two letters a frame, with tokens turned into names.
Space during it shows the rest at once (`fast`). A choice shows 2 or 3 options (`Choose`) and
jumps through the scene's table. `Talk` is `Play`, then the "no money" scene if a `$-N` couldn't be
paid, then the face hidden and `TalkOff`.

The face is `Face.Put`: 15 sprites (and 2 for a hat) at 4x, at 160, 44, from the 9-byte look in
`cLook`. The cast is `cst`: you (`K_YOU`), them (`K_THEM`), the boss, the colleague. `ThemIs p`
makes one of the hundred them; `ThemNobody name, seed, kind` makes up somebody without a name.

### The map and hyperspace

`MapScreen` draws all 192 streets on Layer 2, a dot a block (`World.Mini` with the `W_MINI`
colours, 16 x 12 pixels a street), marks where you are, and lets you look round with Q A O P,
the district's name at the top. `Hyper` (T) picks a random street and spot until `Free`, takes 5
minutes and stuns you for 20 frames: a way out of anywhere.

## As a CyborgOS-Next task: docs/TASK.md

`bash tools/cosnext.sh <NTC src> <CyborgOS>` builds the same game a second way: `LSGAME.CYB`, a
program in its own 64K bank under CyborgOS-Next, as it is (nothing in the hypervisor changed),
with TOWN, RAT, the models and the debugger (MON with a map made from the game's symbols) - a
folder for the SD card, `LSEOUL/`. At the start the game loads its data, `LSCITY.DAT`, into its
store (the hypervisor's 16K pages, its own while it runs) and makes a page table at #BF00 that
the data routines look their pages up in (`tools/taskify.py` puts those lines in the generated
classes, task build only); Layer 2 goes in three of those pages, not bank 16. It hands over the
CPU every frame (`Nx.Yield` in `Nx.WaitFrame`), draws only while it's in front (`Nx.Front`), and
around a switch puts the console's screen registers back and then its own (`Nx.Snap`,
`Nx.ConSave`, `Nx.Back`), so it carries on at whatever screen it was at. All of it is in `#Else`
/ `IFNDEF NTC_ZXN` parts: the NEX is byte for byte what it was. The details, the slots, the
memory map and what's not done: docs/TASK.md.

## The town as a CyborgOS service: services/

The city's hundred, taken out of the game and run as their own program in a CyborgOS slot. Each
slot is a flat 64K of its own, and they talk through ports. The town lives its day by itself; a
game in another slot only draws it. Today this runs on the CPC CyborgOS (the town, RAT and the
models are plain Z80 BASIC with no Next hardware in them). The game's side, on the Next, waits for
the Next hypervisor (`services/docs/HYPERVISOR.md`). `City.bas` still reads `W_SCHED` with
`WhereAt`; it doesn't talk to TOWN yet.

| Slot | Program | Port |
|---|---|---|
| 1 | the game (`LSTEST.bas` stands in for it) | - |
| 2-4 | `LSMODEL SUIT`, `LSMODEL KEEPER`, `LSMODEL STAR` | `SUIT`, `KEEPER`, `STAR` |
| 5 | `RAT` (CyborgOS's `apps/rat`, unchanged) | `RAT` |
| 6 | `TOWN` | `TOWN` |

Started in that order:

```
RUN 2 LSMODEL SUIT
RUN 3 LSMODEL KEEPER
RUN 4 LSMODEL STAR
RUN 5 RAT
RUN 6 TOWN
LSTEST
```

`services/README.md` notes to let each LSMODEL print its banner before the next RUN: while one
slot is reading a file, another slot's RUN can't open its program and says "not found". TOWN
waits for all three models before it starts (it calls each one's `U` until it answers).

### TOWN.DAT: from the engine's own city

`services/towndat.py` reads `tools/world/shops.bin`, `homes.bin`, `sched.bin` and
`tools/people.json`, so the town the service runs is the one the game draws. Its layout, little
endian:

| Offset | What |
|---|---|
| 0 | "LSTD" |
| 4 | version (1) |
| 5 | shop types (40) |
| 6 | people (100) |
| 8 | for each type, the first of its shops in the list (2 bytes), then the end: 41 words |
| 90 | the shops, sorted by type, 3 bytes each: shop number (2), its street (0-191) |
| then | the people, 32 bytes each |

A person:

| Byte | |
|---|---|
| 0 | model: 0 SUIT, 1 KEEPER, 2 STAR |
| 1 | LUN (from 1: LUN 0 is the model file's own) |
| 2 | trait (towndat's `TRAITS` order) |
| 3 | girl |
| 4-6 | home shop (2), its street |
| 7-9 | work shop (2, 65535 none), its street (255 none) |
| 10, 11 | work starts, ends (half hours from 9:00; the end not included) |
| 12 | away: 1 out of town on their second kind of day |
| 13-15 | haunts (towndat's `HAUNTS` order, 255 none) |
| 16 | the days they work: bit k for kind of day k ((p + day) mod 3) |
| 18-27 | the name |

Work comes from LITTLE SEOUL's own days: the place that isn't home that fills 6 or more of the
19 half hours on kind 0, its first and last half hours, and the kinds of day it fills 6 or more
on. The model comes from the job: lawyers, bankers, doctors, teachers and the like are SUIT;
baristas, chefs, bakers, stylists, florists, trainers, couriers are KEEPER; everyone else
(models, actors, singers, dancers, DJs, streamers, the sea people) is STAR.

The built file is 7,643 bytes: 1,451 shops that are somewhere to go, and 100 people (46 SUIT,
32 KEEPER, 22 STAR; 86 with work). TOWN reads it into `db(8191)`.

### The port TOWN

From `TOWN.bas`'s header and `Answer`:

| Message | Answer |
|---|---|
| `T day mins` | `ok`. The game's clock: TOWN catches up to it 5 minutes at a time (arrivals, food, energy, fright). A new day puts everyone home, fed and rested, and the away jobs out of town on their away day |
| `P` | how many are waiting for a decision (0: caught up) |
| `W p` | person p: `name state shop street food energy fear last-decision` |
| `R street` | who is in that street now: walking through it or in one of its shops |
| `F street level radius` | fright: `level` (to 100) at that street and every street within `radius` of it. `ok n`, n the people frightened. They decide at once |
| `S` | `home a work b eat c out d walk e flee f away g dec h` |
| `Q` | `end`: TOWN stops |

States: HOME, WORK, EAT, OUT (a haunt), WALK, FLEE, AWAY.

TOWN's main loop answers a message on its port when there is one, and when there isn't, decides
for the next person due (`DecideNext`, round the hundred). Decisions only happen from 7:00 to 22:00 (`DAWN`, `NIGHT`).

### The table a game reads

A port call sleeps the caller for a tick, so a game can't ask TOWN where everyone is each frame.
TOWN keeps a table, `tb(799)`, 8 bytes a person, written by `Publish` whenever a person changes:

| Byte | |
|---|---|
| 0-1 | shop (LITTLE SEOUL's shop number; 65535 away, 65534 walking) |
| 2 | street (0-191) |
| 3 | state |
| 4 | food |
| 5 | energy |
| 6 | fear |
| 7 | - |

```basic
Sub Publish(ByVal p As Integer)
  Dim o As Integer
  o = p * 8
  tb(o) = pShop(p) And 255 : tb(o + 1) = (pShop(p) \ 256) And 255
  tb(o + 2) = RoomOf(p) : tb(o + 3) = pState(p)
  tb(o + 4) = pFood(p) : tb(o + 5) = pEnergy(p) : tb(o + 6) = pFear(p)
End Sub
```

Today it's TOWN's own array. On the Next it goes in a bank both the game's slot and the town's
slot map at the same address (HYPERVISOR.md asks for a "Share n" call), and the game's `WhereAt`
becomes a read of it; the ports then carry only the clock, commands and frights.

### How a person decides

When what someone is doing ends, or a fright reaches them, `Decide` asks RAT, passing only what
they can do now:

```basic
  s = ModelOf(p) + ":" + Trim$(Str$(PB(p, 1)))
  If pFear(p) > 0 Then s = s + " flee:" + Trim$(Str$(100 - pFear(p)))
  ws = 540 + PB(p, 10) * 30 : we = 540 + PB(p, 11) * 30
  If PB(p, 9) <> 255 And (PB(p, 16) And Pow2((p + day) Mod 3)) <> 0 And mins >= ws And mins < we Then s = s + " work"
  If pFood(p) < 90 Then s = s + " eat:" + Trim$(Str$(pFood(p)))
  s = s + " home:" + Trim$(Str$(pEnergy(p)))
```

then their haunts as plain tags. A call looks like:

```
SUIT:4 flee:30 work eat:42 home:77 office cafe park
```

`SUIT:4` is the model and the LUN. `flee:30` only when frightened (100 less the fear), `work`
only on a working day inside their hours, `eat:` and `home:` with their food and energy. In the
models these are N (necessities): below the model's N weight, the level wins over everything, so
someone hungry at work goes and eats. The haunts are L (likes).

RAT's answer is a path: `eat.noodle`, `park.temple`, `cafe.coffee`, `work`, `home`, `flee`.
`Act` turns it into a place: home, work, or the nearest shop of the leaf's type (`TypeOf`: noodle
is type 4, temple 36 ...) from the street they're in, one of the nearest three. They walk there
3 minutes a street (fleeing: 2), along then down (`RoomOf` works out which street they're in on
the way). Eating takes 40 minutes, an outing 60-150, home 60-120, work an hour at a time so hunger
can break in. Food drops a point every 5 minutes (eating puts back 12), energy a point every 15
minutes out (home puts back 3 every 5). Fright drops 3 every 5 minutes once they're out of the
frightened streets, and the streets' alert drops 2.

If RAT doesn't answer, the person goes home.

### The models: SUIT, KEEPER, STAR

`services/models/*.MDL`, 50 lines of branches each, in MODEL's format: a line a branch, its
depth the spaces before it, a name and a weight 0-100:

```
N
 eat 30
 home 20
 flee 45
R
 work 75
L
 eat 45
  noodle 55
  bbq 50
```

That's SUIT's start. The three differ in their weights: a KEEPER's work is 85 and they eat late
(N eat 25); a STAR's work is 60, `home` is only 15 and flee 55 (the first to run), with clubs,
concerts and karaoke liked most. SUIT dislikes clubs and the funfair; KEEPER dislikes the office
and the mall; STAR the office and home.

### Each person their own: LUNs tuned by trait

A LUN is one copy of a model's weights: every person is a LUN of their model, so 100 people are
three trees and 100 sets of weights. MODEL's L weights grow a point each time their tag is picked,
so each LUN learns its own habits and people go back to the same kind of place.

At the start TOWN sets two weights of each person's LUN from their trait, with MODEL's `V`
message (`#lun V cat\tag\weight`, sent on the model's port):

```basic
    s = "#" + Trim$(Str$(PB(p, 1))) + " V "
    If t = 0 Then Tune m, s + "R\work\85" : Tune m, s + "N\flee\25"          ' BORN LEADER
    If t = 1 Then Tune m, s + "L\karaoke\10" : Tune m, s + "N\flee\65"       ' SHY
    If t = 2 Then Tune m, s + "L\funfair\85" : Tune m, s + "L\karaoke\70"    ' PRANKSTER
```

and so on for the ten traits: CHARISMATIC likes clubs and bars, 4D the park and the chapel, a
FOODIE eats sooner (N eat 50) and likes it more, SOFTIE cafes and runs sooner, HARD WORKER work 95
and home only at 10, CHEERFUL karaoke and concerts, CHIC boutiques and the mall. So two SUITs with
different traits don't decide alike.

### LSMODEL: the engine's own copy of MODEL

`services/town/LSMODEL.bas` is CyborgOS's `apps/rat/MODEL.bas` (2026-10-21) kept under its own
name, so changes to MODEL don't land on the engine. The one difference is the size of the LUNs'
weights:

```basic
Const LBYTES = 24000                          ' the LUNs' weights: a byte a line each (LUN 0: nw)
Dim lw(23999) As Byte
```

MODEL has 30000. Built with this NTC, MODEL's arrays end at #F617, and the 320K hypervisor's
program area ends at #EF00, so it stops with "Not enough memory for the arrays". With 24000 it
ends at #DEA7 (`HYPERVISOR.md`). The number of LUNs is 1 + 24000 \ lines, at most 250, so a model
of up to 96 lines still gets 250; these 50-line models get 250 too, more than the 46 SUITs need.
Its banner says `LSMODEL`, but it serves its port by the model file's name (`SUIT`, `KEEPER`,
`STAR`), so TOWN and RAT don't know the difference.

### The test day

`services/test.sh <NTC src> <CyborgOS checkout>` builds `TOWN.DAT`, then TOWN, LSTEST, LSMODEL and
CyborgOS's RAT and ASK for CP/M with NTC's `cli.js` and `sjasmplus`, wraps each as a `.CYB`, boots
the CPC CyborgOS (`cyborgos320kb`) in NTC's harness with 4MB (20 slots, `--ram=4160`), types the
RUNs with pauses between them, and runs `lstest`. Scratch work goes in `<NTC src>/test/t/lse`.

`LSTEST` drives one day the way a game would: the clock 10 minutes a step from 9:00 to 18:00
(`T 0 m`), then `P` until the town has caught up, the town's numbers each hour (`S`), five people
at noon (`W`), and at 13:00 aliens land on street 70 (the post office's) with `F 70 90 2`.

`services/docs/day1.txt` is a run (its first line still says MODEL; `test.sh` now starts
LSMODEL). Some of it:

```
12:00 home 4 work 35 eat 8 out 36 walk 14 flee 0 away 3 dec 249
  0: RAON WALK -2 35 100 78 0 work
  1: DAON WORK 293 41 21 78 0 work
  2: HAEON OUT 153 27 28 78 0 boutique.clothes
13:00 home 3 work 26 eat 19 out 36 walk 13 flee 0 away 3 dec 325
  street 70 before: 67
  ALIENS LAND ON STREET 70: ok 7
13:10 home 4 work 22 eat 20 out 33 walk 12 flee 6 away 3 dec 345
  street 70 now: 67
13:40 home 9 work 22 eat 26 out 24 walk 16 flee 0 away 3 dec 386
  street 70 now:
```

Lunch shows (eating 0 at 10:00, 19-26 from 13:00 to 14:00); 7 people are frightened by the
landing, 6 are running at 13:10, and by 13:40 street 70 is empty. Three people are away all day.
698 decisions in the day.

## Decisions made to fit

- **The data out of the program.** The city, the story, the people and both sprite sets are 448K
  in 28 banks; the program holds one room, one shop, one person and one scene at a time.
- **Tables from the start of a page**, so a record's place comes from its number alone, and
  homes, days, names and words are copied in when wanted, not kept.
- **Two sprite sets** swapped at each talk, because the street's sprites and the faces don't fit
  the sprite RAM together.
- **Faces from a seed** for everyone who isn't one of the hundred: 9 bytes from one number, the
  same every time.
- **Ten people about** at most, in slots that go on living in the street or shop where you left
  them, and get taken over when somebody new is needed.
- **The hot routines in asm**: `WhereAt`, `StepNpc`, `NearNpc`, `Free`, `CellAt`, `RowOpen`,
  `NewNpc`, `Seen`, `DoorOf`, `PutAt`, `SlotPal`, `HereKey`, `Part`.
- **No Long anywhere**: money in hundreds of won (`Won` shows 125 as W12,500), and `Part` for the
  only sum that went past 32767. About 900 bytes of NTC library not linked.
- **The split costs 19 bytes**: `CityStart` as a Sub instead of lines at the top of `Main.bas`.
- **The game's rules marked, not moved**: the `' GAME:` lines stay where they act, so the city's
  routines are the same code as LILSEOUL's and play the same.

NTC rules that show in the code:

- **Parameters arrive as pointers**: `pop hl`, then the value through it, first parameter first.
  A Function's result goes back the same way (`pop hl / ld (hl), e / inc hl / ld (hl), d`).
- **`{name}` is a variable** in asm (`ld hl, ({inShop})`, `ld hl, {nRoom}`), and labels in a
  module's asm become `fn_<sub>_<label>` (`fn_slotpal_sp_tab`).
- **Self-modifying code** for values a routine needs later: `ld (wa_p + 1), a`, `ld (nw_c1 + 1),
  a`, `ld (dc_p1 + 1), a`.
- **Interrupts are off** (NTC runs that way), so a routine can map data into slots 6 and 7 and
  must put pages 10 and 11 back before it returns: the tilemap and the tiles live there.
- **A Function nobody calls isn't linked.** `Data.Init` is called once so its `INCBIN`s are in
  the build, though it does nothing when it runs.

## Building

```
python3 tools/blocks.py      # the blocks
python3 tools/city.py        # the city -> tools/world/, Town.cls
python3 tools/art_city.py    # the street's sprites -> gfx/
python3 tools/facepack.py    # the two sprite sets
python3 tools/storyc.py      # story + city + people + sprites -> build/LSENGINE.DAT, Data.cls
node build.js path/to/ntc/src
```

After changing a script, the last two are enough; after changing the BASIC, only `build.js`.

`build.js` does four things: `gfxtool.js` makes `GfxData.cls` from `gfx/`; it writes
`LSENGINE.json`, the project for NTC BASIC's IDE (every file in `game.json`, the zxn platform,
turbo); it loads NTC's `js/` files (`ntc_lib.js`, `ntc_parser.js`, `ntc_compiler.js`, the flavours)
and compiles to `build/LSENGINE.asm`, adding `game.json`'s `banks` to the `SAVENEX BANK` line; and
it runs `sjasmplus`, which writes `LSENGINE.NEX` and `LSENGINE.sym`. NTC's `src` folder is the
argument, or `NTC_SRC`, or found next to the game. `build/LSENGINE.DAT` must be beside the `.asm`
for the `INCBIN`s.

The services: `bash services/test.sh <NTC src> <CyborgOS checkout>`, or `python3
services/towndat.py [dir]` for `TOWN.DAT` alone. `services/build/` has the last built `TOWN.DAT`,
`TOWN.CYB`, `LSMODEL.CYB`, `LSTEST.CYB`, `RAT.CYB` and `ASK.CYB`.

## How it was tested

`test/lsbot2.py` plays the game in `nextemu.py` (a Next emulator in Python, in TOOLS.zip; the
script looks for it in `/home/claude/work/emu`):

```
LSG=<the game's folder>/ python3 test/lsbot2.py 30000 1 walk
```

The arguments are frames, the random seed, and the mode (`walk`: do the round; `subway`: ride the
subway first). `fast` jumps to day 19 and ends each day when the bag is done; `dbg` prints the
walking. The bot finds which BASIC routine is waiting by reading NTC's return addresses (`p_<sub>_rs`)
and the assembler's listing (`build/LSENGINE.lst`, made with `sjasmplus --lst`: `build.js` doesn't
write it), and answers each one: Space through the title and the talks, a random face, a random
choice, M at the name. In `Round` it walks: a breadth-first search over the whole city's blocks
from `tools/world/rooms.bin` to the nearest delivery's door, then inside to the counter, the
mailboxes, the lift and the flat's door. Every 2,000 frames it prints the day, the clock, the
room, the shop, the floor, where you are, the bag, the money and the routine waiting, and it
takes screenshots of the title, the face, the bag, the map, the streets and the talks.

The split was checked by playing both builds with the same seed for 30,000 frames. The two logs
are the same, all 15 lines, from `2000 day 1 mins 579 room 87 ... bag 1 / 3 money 130` to
`30000 day 3 mins 770 room 99 ... bag 4 / 4 money 340`. Same random numbers, same people in the
same places, same deliveries, same money: the city behaves the same with the game taken out.

The town service is tested on the CPC CyborgOS with `services/test.sh` (above).

## Lessons

- **Mark the game's rules where they are.** Moving them out would have changed the city's code;
  a comment on the line changes nothing and still shows a new game what to change.
- **Check a split by playing both.** The same seed and the same log lines over 30,000 frames is
  a better test than reading the diff.
- **Keep to Integers on an 8-bit machine.** One Long cost about 900 bytes of library; hundreds of
  won and a 24-bit asm Function did the same job.
- **Make the service's data from the game's own.** `towndat.py` reads the city's tables, so TOWN's
  hundred live at the same addresses and work at the same places as the game's.

## Files

| File | |
|---|---|
| `Game.bas` | the postie game: the title, a new postie, the season, the bag, deliveries, the HUD, the endings |
| `City.bas` | the engine: the city, its people, talking, the frame loop |
| `Data.cls`, `Town.cls`, `GfxData.cls`, `FaceSet.cls`, `GameSet.cls` | generated: the data, the city's numbers, the graphics, the two sprite sets |
| `World.cls`, `Face.cls`, `Board.cls`, `L2.cls`, `Spr.cls`, `Tiles.cls`, `Nx.cls`, `Sfx.cls` | screens, faces, the tilemap, Layer 2, sprites, the Next, sound |
| `game.json` | the name (`LSENGINE`), the files (`Game.bas` first), the data banks, `gfxbank` 47 |
| `build.js`, `gfxtool.js` | the build; the graphics |
| `LSENGINE.json` | the IDE project (made by `build.js`) |
| `tools/` | `blocks.py`, `templates.py`, `city.py`, `people.py`, `art_city.py`, `facepack.py`, `storyc.py` (and `artkit.py`, `cvkit.py`); `world/` the city's tables; `blocks.bin`, `people.bin`, `people.json`, `faces.bin`, `game.bin` |
| `scripts/` | `CHAT`, `SHOPS`, `STRANGERS`, `THINGS` (the city's); `POST`, `DELIVER` (the game's); `BRIEF.md` the format |
| `gfx/`, `gfx_faces/` | the street's sprites and tiles; the face parts |
| `build/` | `LSENGINE.NEX`, `.DAT`, `.asm`, `.sym` |
| `docs/NEWGAME.md` | how to make a new game on the engine |
| `test/lsbot2.py` | the bot |
| `screenshots/` | the title, your name, the round, the map, Itaewon, a neighbour |
| `services/town/` | `TOWN.bas`, `LSMODEL.bas`, `LSTEST.bas` |
| `services/models/` | `SUIT.MDL`, `KEEPER.MDL`, `STAR.MDL` |
| `services/towndat.py`, `services/test.sh` | `TOWN.DAT`; the CPC test |
| `services/docs/` | `ENGINE.md` (the slots, the port, the table), `HYPERVISOR.md` (what the Next needs), `day1.txt` (a test day) |
| `services/build/` | `TOWN.DAT` and the built tasks |
| `README.md`, `services/README.md` | the short versions |
