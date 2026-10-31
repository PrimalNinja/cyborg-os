# THE LITTLE SEOUL ENGINE - the town as a CyborgOS service

LITTLE SEOUL's city as an engine for games set in it, on CyborgOS: the town lives in its own
slot (TOWN), the hundred people decide their days with RAT (each person a LUN of a model: SUIT,
KEEPER, STAR), and a game in another slot draws them and plays in the city. The first game on it
is to be an alien invasion shoot 'em up.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

## What's here (first cut)

| | |
|---|---|
| `town/TOWN.bas` | the town service (a CyborgOS task, port TOWN) |
| `town/LSMODEL.bas` | the engine's own copy of CyborgOS's MODEL (served the models): its own name so MODEL's changes don't land on it; its LUN table 24000 bytes so it fits a slot |
| `town/LSTEST.bas` | stands in for the game: one day, aliens at 13:00 |
| `models/SUIT.MDL`, `KEEPER.MDL`, `STAR.MDL` | the RAT models for the three kinds of people (served by LSMODEL) |
| `towndat.py` | `build/TOWN.DAT` from the engine's own city (`../tools/world/`, `../tools/people.json`) |
| `docs/ENGINE.md` | how it fits together: the slots, the port TOWN, the table a game reads |
| `docs/HYPERVISOR.md` | what the Next hypervisor needs to give the game slot |
| `docs/day1.txt` | a day of the town in the harness |
| `build/` | TOWN.DAT and the built tasks: TOWN.CYB, LSTEST.CYB, LSMODEL.CYB, RAT.CYB, ASK.CYB |
| `test.sh` | builds and runs it all on the CPC CyborgOS in NTC's harness |

## Running it (CyborgOS, CPC or Next)

Put `TOWN.CYB`, `LSMODEL.CYB`, `RAT.CYB`, the three `.MDL` files and `TOWN.DAT` on the drive, then:

    RUN 2 LSMODEL SUIT
    RUN 3 LSMODEL KEEPER
    RUN 4 LSMODEL STAR
    RUN 5 RAT
    RUN 6 TOWN
    LSTEST

Give each LSMODEL time to print its banner before the next RUN: while one slot is reading a file,
another slot's RUN can't open its program and says "not found" (seen in the harness). TOWN waits
for all three models before it starts.

`ASK TOWN S` shows how the town is (home, work, eating, out, walking, fleeing, away); `ASK TOWN W 0`
one person; `ASK TOWN F 70 90 2` frightens the streets round the post office.

## Testing

    bash services/test.sh <NTC's src folder> <CyborgOS checkout>

The town, RAT and the models have no Next hardware in them, so they are tested on the CPC
version (20 slots with 4MB in the harness). The game slot waits for the Next hypervisor
(docs/HYPERVISOR.md).
