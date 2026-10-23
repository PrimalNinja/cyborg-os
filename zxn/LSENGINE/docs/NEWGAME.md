# A new game on THE LITTLE SEOUL ENGINE

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

The engine is the city: `City.bas`, every class, the city's scripts, the tools and the pictures.
A game is `Game.bas` (and its own scripts). LITTLE SEOUL's postie game is the example: copy the
folder, keep the city, replace the game.

## 1. Copy and name it

1. Copy the whole folder (e.g. to `INVADERS`).
2. `game.json`: `"name"` is your game's name (8 letters at most: the NEX file, the data file).
   `"files"` keeps `Game.bas` first, then `City.bas`, then the classes.
3. `python3 tools/storyc.py` then makes `build/NAME.DAT` and `Data.cls` for that name.

## 2. Write Game.bas

`Game.bas` owns the program's start and the rules. The shape every game has:

```
Option Explicit
Option Turbo
' your Public variables (the city's are City.bas's)

CityStart                    ' the city's start-up: hardware, pictures, tables - first, always
Do
  ' your title, your player, your levels / days ...
  ' put the player somewhere:  GoStreet room, x, y, dir   or  GoInside shop, floor, x, y, dir
  mins = 540 : day = 1       ' the clock: minutes from midnight (the hundred keep to it)
  Round                      ' City.bas's frame loop: walking, people, cars, drawing, Space, T
  ' Round ends when quit is set (by you, in Clockwork or anywhere) - or at T_END (see 4)
Loop
```

`Round` runs a frame at a time: `Tick` (50 a second), your `Clockwork`, walking (unless stunned),
the people, the cars, drawing, then the keys: Space is `Act` (the city's: talk to someone near,
vending machines, binoculars, exhibits, the lift, the subway's tickets, a market stall - then your
Knock / Mailbox / Counter), M is your `BagScreen`, T is hyperspace.

## 3. The subs the city calls (your Game.bas must have each - empty is fine)

| Sub | Called from | LITTLE SEOUL does |
|---|---|---|
| `Clockwork()` | `Round`, once a frame | a minute every half second, energy runs down, "hungry", "tired" |
| `Hud()` | after a talk, going in somewhere, a stall | the status line: time, money, the bag (HudTime is the game's own, from its Clockwork) |
| `Stat(s, v)` | `Play`: a scene's `!STAT` | energy, speed, the boss, a haircut, a hanbok ... |
| `Feel(v)` | `Play`: a scene's `+N` / `-N` | how the one you talk to feels about you (`aff`) |
| `BagScreen(full)` | `Round`: the M key | the bag; Space there shows the city's `MapScreen` |
| `Knock(s, fl, u)` | `Door` (a house), `Act` (a flat's door) | a parcel, or nobody in |
| `Mailbox()` | `Act`: an apartment block's mailboxes | letters in |
| `Counter()` | `Act`: a shop's counter | buy / deliver to the shop |
| `AfterShop()` | `TalkTo`, `Counter` | a haircut shows |
| `BagFor(s, fl)`, `ItemWords(j)`, `Delivered(j, how)` | the `' GAME:` lines | the postie's bag |

## 4. The postie's rules inside the city: the `' GAME:` lines

A few city routines carry the postie game's rules; each such line ends in `' GAME:`. For a new game
change or drop them (and the bag subs above can go with them):

| Where in City.bas | What it does now |
|---|---|
| `Play` | a scene's `$N` changes `money` |
| `TalkTo` | meeting someone with a parcel for them: delivered by hand; flowers; asking strangers for an address |
| `Cars` | hit by a car: 10 minutes and energy lost (`hitToday`) |
| `DrawAll`, `Arrow` | the map app's arrow to the next delivery |
| `Round` | `Clockwork`, the M key (`BagScreen`), the day ends at `T_END` (18:00) |
| `Walk` | walking speed from `speedT` (coffee) and `energy` |
| `Door`, `Act` | knocking, mailboxes, counters, the apartment guard |
| `Lift`, `Subway` | stairs cost energy, the subway costs W1,400 |
| `MapScreen` | the bag's deliveries on the map, the PC bang's lookup |

## 5. What the city gives a game

- **Where you are:** `room` (the street, 0-191: 16 across, 12 down), `inShop` (the shop you're in,
  -1 in the street), `floor`, `px`, `py`, `pdir`; `GoStreet`, `GoInside`, `Hyper`.
- **The clock:** `day`, `mins` - the hundred go where their days take them by it (`WhereAt`).
- **The city's tables:** `LoadRoom`, `LoadShop`, `LoadType` (`rc`, `sh`, `ty`), `ShopName`,
  `DistName`, `Address`, `HomeAt` / `HomeRoom`, `Town.cls`'s constants (shop types, blocks).
- **People:** the hundred (`LoadRec`, `PNameOf`, `ThemIs`), strangers and keepers (`ThemNobody`),
  the cast for scenes (`cst`, `K_YOU`, `K_THEM`, ...), the people on screen (`nRoom`, `npx` ...).
- **Talking:** `Talk id, who` plays a scene (`Data.cls`'s numbers), `Play` the same with the face up;
  `Note`, `YesNo`, `Choose`; `NameEntry`, `PickFace` for making a player.
- **Drawing and sound:** `Panel`, `Mid1`, `Bar`, `Fx`, `Burst`, `Ring`, `Blip`, `Ding`, `Honk`,
  `Music`; the classes (`Spr`, `Board`, `L2`, `World`, `Sfx`).

## 6. Your story

`scripts/` holds every scene. The city's: `CHAT` (the hundred), `SHOPS` (every kind of shop),
`STRANGERS`, `THINGS` (things in the street). The postie game's: `POST` (the post office) and
`DELIVER` (deliveries). A new game replaces POST and DELIVER with its own files: add them to
`FILES` in `tools/storyc.py` (the scene names each file has, in order), write them in the format
in `scripts/BRIEF.md`, and run `tools/storyc.py`. `Data.cls` then has their numbers.

## 7. Room

The program and its arrays must end below #BE00 (the stack, then the screen). The postie game leaves
774 bytes (with the current NTC). Keep to Integers: one Long anywhere pulls in about 900 bytes of
NTC's Long arithmetic. Game.bas's code is about 5.8K (measured from the build): a new game has that, plus
whatever the ' GAME: lines it drops gave, for its own; the Next's other RAM (`Data`) holds as much story as you like.
Later, pages (NTC's `Option Page ... Loaded n`) and the CyborgOS town service (`services/`) move
more out.
