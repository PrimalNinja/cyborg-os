# The LITTLE SEOUL ENGINE

LITTLE SEOUL turned into an engine for games set in its city. The game is no longer one program:
it is a set of CyborgOS slots, each its own flat 64K, talking through ports. The town lives on
its own; a game only draws it and plays in it.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

## The slots

| Slot | Program | What it does | Port |
|---|---|---|---|
| game | the game (LITTLE SEOUL, the alien shoot 'em up ...) | draws, the player, the story, the aliens | - |
| town | `TOWN` (services/town/TOWN.bas) | the hundred people's days: where everyone is, walking street by street, food, energy, fright | `TOWN` |
| rat | `RAT` (CyborgOS apps/rat, unchanged) | the decision service | `RAT` |
| models | `LSMODEL SUIT`, `LSMODEL KEEPER`, `LSMODEL STAR` (town/LSMODEL.bas: the engine's own copy of MODEL, models/*.MDL) | the weights: a model per kind of person, a LUN per person | `SUIT`, `KEEPER`, `STAR` |

Each one has the whole 64K. More fit the same way: a model for strangers, one for the aliens'
own behaviour, a second town service for traffic, a NEURAL net that learns the player.

Started by hand (or by the game's start-up) in this order:

    RUN 2 LSMODEL SUIT
    RUN 3 LSMODEL KEEPER
    RUN 4 LSMODEL STAR
    RUN 5 RAT
    RUN 6 TOWN

## The town

`TOWN.DAT` (made by `services/towndat.py` from the engine's own city: `tools/world/`, `tools/people.json`) holds the 1451
shops that are somewhere to go (by type, with their street) and the hundred: home, work and its
hours, which days they work, their haunts, their trait, their model and LUN. The same city the
game draws, the same homes and workplaces LITTLE SEOUL's schedules had.

At the start TOWN tunes each person's LUN to their trait (two weights each: a BORN LEADER's work
85 and flee 25, a SHY one's karaoke 10 and flee 65, a FOODIE's eat 50 and 75 ...), so the hundred
are a hundred, not three.

When what someone is doing ends (or a fright reaches them), TOWN asks RAT what they do next,
passing only what they can do now - their senses:

    SUIT:4 flee:30 work eat:42 home:77 office cafe park

- `work` only on a working day, inside their hours (LITTLE SEOUL's own).
- `eat:<food>`, `home:<energy>`: necessities (N). Below the model's threshold they win over
  everything: hungry at work, they go and eat.
- `flee:<calm>` only when they are frightened.
- their haunts (people.json's), as likes (L).

RAT's answer is a path - `eat.noodle`, `park.temple`, `cafe.coffee`, `work`, `home`, `flee`.
TOWN turns it into a place: home, work, or the nearest shop of that kind (one of the nearest
three) from the street they are in, and they walk there, 3 minutes a street (fleeing 2), along
then down. Eating takes 40 minutes, an outing 60-150, home 60-120, work an hour at a time (so
hunger can break in).

Food runs down a point every 5 minutes (eating fills it), energy a point every 15 out (home fills
it). Fright fades 3 a step once they are out of the frightened streets.

The RAT habits (MODEL's L weights growing with each pick) make regulars: the same people
going back to the same kind of place.

## The port TOWN

| Message | Answer |
|---|---|
| `T day mins` | `ok` - the game's clock (TOWN catches up: arrivals, food, energy, fright). A new day: everyone home, fed, rested; the away jobs out of town on their away day |
| `P` | how many are waiting for a decision (0: caught up) |
| `W p` | person p: `name state shop street food energy fear last-decision` |
| `R street` | who is in that street (0-191) now - walking through it or in one of its shops |
| `F street level radius` | fright at that street and every street within radius: `ok n` (n frightened). Those people decide at once - most flee home |
| `S` | `home a work b eat c out d walk e flee f away g dec h` |
| `Q` | `end` - TOWN stops |

States: HOME, WORK, EAT, OUT (a haunt), WALK, FLEE, AWAY (out of town).

## The table (what the game reads every frame)

A port call sleeps the caller a tick, so a game can't ask TOWN where everyone is each frame.
TOWN keeps a table instead, 8 bytes a person:

| Offset | |
|---|---|
| 0-1 | shop (LITTLE SEOUL's shop number; 65535 away, 65534 walking) |
| 2 | street (0-191) |
| 3 | state |
| 4 | food |
| 5 | energy |
| 6 | fear |
| 7 | - |

Today it is TOWN's own array (`tb`). On the Next it goes in a bank that the game slot and the
town slot both map at the same place (docs/HYPERVISOR.md); the game's `WhereAt` becomes a read of
it. Ports then carry only commands and frights.

## The game's side (LITTLE SEOUL, then the shoot 'em up)

- The clock stays the game's: it sends `T` each game minute (or every few).
- Drawing: who is in this street - the table's rows with this street (WALK: walking across it,
  others: in a shop whose door is here).
- Talking to someone: their row says how they are (hungry, tired, frightened).
- Aliens land: `F street level radius`. The town empties round them, brave ones last.

## Testing (here: the CPC CyborgOS)

The town, RAT and the models are pure Z80 BASIC - no Next hardware - so they are tested on the
CPC CyborgOS, which is solid. `town/LSTEST.bas` stands in for the game: it drives one day 10
minutes a step, prints the town each hour, five people at noon, and lands aliens on street 70
(the post office's) at 13:00. `test.sh` builds it all and runs it in NTC's harness
(`docs/day1.txt` is a run).

## Next

1. The Next hypervisor's part (docs/HYPERVISOR.md) - the other session.
2. LITTLE SEOUL as the game slot: `WhereAt` from the table, `T` from its clock; the walkers and
   cars stay the game's (they are drawing).
3. Strangers by RAT too: a STRANGER model (ajummas, grandads, students, tourists), a crowd
   per street from the time of day and the town's mood.
4. The alien shoot 'em up as a game slot: the city, the town panicking where they land.
