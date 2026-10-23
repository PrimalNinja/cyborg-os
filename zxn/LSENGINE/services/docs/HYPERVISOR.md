# What the LITTLE SEOUL ENGINE needs from the CyborgOS Next hypervisor

For the session working on CyborgOS-Next. The engine (docs/ENGINE.md) runs the town, RAT and
the models as ordinary CyborgOS tasks - they need nothing new and run today on the CPC version.
The game slot is what needs the hypervisor's help: it is a Next game, not a console program.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

**Where it stands (2026-10-21):** the game runs as a task on CyborgOS-Next as it is - no change to
the hypervisor (docs/TASK.md). Parts 1, 2, 3 and 5 below are done by the game itself: it hands
the CPU over every frame (BDOS 12), asks whether it's in front (BDOS 131 op 0), puts the
console's screen registers back when it isn't and its own when it is again; its data and its
Layer 2 are in its store (op 12), loaded from the SD card. **Part 4, the shared bank, is still
needed** to join the game to TOWN.

## 1. A slot that owns the screen

LITTLE SEOUL draws with Layer 2 (bank 16, pages 32-37: the backdrops), the sprites, the tilemap
(bank 5: text, the HUD) and the palettes, all through the NextReg ports, and reads the keys and
the joystick itself.

- A "game" mode for the front slot: the hypervisor stops drawing the console over it (no
  per-slot text page shown, no status strip), leaves Layer 2, the sprites, the tilemap and the
  layer order to it, and doesn't change the palettes while it is in front.
- The hot keys still work (Caps/Symbol Shift + n): switching away puts the console back;
  switching back to the game slot hands the screen back. The game redraws when told (a flag
  in its bank, or a BDOS answer) - it can't know its screen was taken.
- Its keys: the slot reads the matrix itself (ports #xxFE), so the hypervisor's key handling
  must not eat the keys it needs while it is in front (or hand them over as the BDOS stub
  does now - either works, the first is simpler).

## 2. Banks for the game's data that are never slots

LITTLE SEOUL's city, story, faces and graphics are 458K in 28 banks (today 0-4, 6, 7, 11-15,
19-34 and 47, via game.json's "banks"). Today's CyborgOS-Next uses 1-4, 6, 7, 11 for its
archive, 8-10 for itself and 22 up for slots, so they clash.

- A way to reserve banks for a slot's data: either the game's data goes in banks past the
  slots (the probe hands out banks 22 up - a ceiling for the pool), or the NEX's data banks
  are marked taken before the pool is made (as NTC's Loaded pages are: ntc_pgloaded).
- The game slot maps them itself (MMU slots 6 and 7, #C000-#FFFF, two 8K pages at a time,
  then its own pages back). That needs rule 4.

## 3. A fixed share for the game slot

Round robin gives the game a turn among all the slots; it needs 50 frames a second, steady.

- The front game slot gets its time first: a fixed share (as NTC's interrupt classes have
  rate vs Share), or it runs until it gives the CPU back once a frame (a BDOS "frame done").
- The town, RAT and the models split the rest. They are not in a hurry: a decision a person
  is a few ticks, and the game's clock is a minute every half second.

## 4. The shared bank

The game reads where everyone is every frame - too often for port calls (a call sleeps the
caller a tick). So:

- One bank (16K is plenty: the table is 800 bytes today) that two slots both map at the same
  address: the town writes it, the game reads it. For example "Share n" (BDOS 131 op): this
  slot maps shared bank n at #8000-#BFFF, MMU slots 4 and 5.
- The hypervisor's switch keeps those two MMU slots for those two programs.

## 5. Slot 7 while a game maps its data

The switch's receiver (`sb_hin`, #FFD0) is in slot 7 of every bank. LITTLE SEOUL maps its data
into MMU slots 6 and 7 to read it. That is safe only with interrupts off while mapped and its
own page back in slot 7 before they are on again. The game will keep to that (Data.Copy does
its copies with interrupts off); the hypervisor need do nothing, but should know it.

## Found on the way (not this engine's)

MODEL (apps/rat) built with the NTC here: its arrays end at #F617, and the 320K hypervisor's
TPA ends at #EF00 (STUB), so it stops with "Not enough memory for the arrays". With
`LBYTES = 24000` (lw(23999)) it fits (#DEA7) - 250 LUNs still fit for models up to 96 lines.
The engine has its own copy, town/LSMODEL.bas (LBYTES 24000), so MODEL.bas itself is not touched
and changes to it don't land on the engine.
