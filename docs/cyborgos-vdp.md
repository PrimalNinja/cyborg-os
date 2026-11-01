# CyborgOS - the Pi as a VDP (the vdp service)

Started 2026-11-02. The Pi's HDMI as a video display processor for the CPC (and any machine on the
link): a chip with RAM of its own, reached through a port - here the link. One service, vdp
(pi/svc/vdp.js), one profile a target, one binary command stream shared by every front (NTC
classes, Streamer's RTG paths, CyborgOS's C0, a PC on the LAN). Small now; the shape is what is
fixed, so what comes later (emitters, paths, tiles, masks, scroll) adds commands, not changes.

## 1. Profiles (OPEN vdp profile=NAME)

A profile is the model a program expects: the logical screen, the limits, the pixel format of
its patterns. The service keeps one superset model (sprites, tile layers, a text layer, palettes);
the profile sets the numbers. A profile module is one object in vdp.js (PROFILES[name]): adding a
target is adding an object, nothing in the engine changes.

```
   name     width height  sprites  spr w h  patterns  pixel format           colours    tiles   bitmap
   v9938    256   212     32       16 16    256       1 bit, 1 colour each   16 of 512
   v9990    256   212     125      16 16    512       4 bit, palette        16 x 16 of 32768
   zxn      320   256     128      16 16    64        8 bit, palette        256 of 512 40x32 4-bit  8-bit
   md       320   224     80       8..32    2048      4 bit, palette        4 x 16 of 512
   pi720    1280  720     4096     any      4096      RGBA                  24 bit + alpha
   pi1080   1920  1080    4096     any      4096      RGBA                  24 bit + alpha
   pi2160   3840  2160    4096     any      4096      RGBA                  24 bit + alpha
```

The chip profiles are drawn nearest-neighbour, scaled to the HDMI. Where this says "v1" below, the
profile exists but only what is listed is implemented; a command past it answers ERR notyet.

## 2. Coordinates and numbers

- Pixels: signed 16-bit, top-left origin, y down, in the profile's logical screen. Off-screen is
  allowed (a sprite enters from outside).
- Character cells (the text layer): 8-bit column and row.
- Velocities and the engine's own positions: 12.4 fixed point (a 16-bit word: 16 = one pixel).
  The program sees whole pixels; the fraction is the engine's.
- Ids: 16-bit for sprites, patterns, tiles, templates and tables, in every profile.
- All words little end first. All commands have a fixed length from their opcode, so a stream can
  be checked and skipped without understanding every opcode.

## 3. Requests (text, on the channel; a 0 then data where there is data)

```
   INFO                       OK profile width height sprites patterns cells frame-rate colsxrows
   TILES n [tag]              tile definitions n on: 8 x 8 at the profile's tileBpp (zxn, v9990, md:
                              4-bit, 32 bytes each; v9938 1-bit; pi RGBA), from the data or a tag
   LAYER2 [tag]               the bitmap layer whole: width x height at bitmapBpp (zxn: 8-bit
                              through the palette; pi: RGBA; none on v9938 and md): Layer 2 under
                              the tile layer under the sprites, the Next's order
   TILEAT col row             (tests, tools) OK tile flags | OK none
   PATTERNS n + data          patterns n on, from the data in the profile's pixel format: OK count
   PATTERNS n tag             ... from the STORE tag (installed once; the link carries the name)
   PALETTE i + data           palette entries i on, 3 bytes each (r g b): OK count
   CLEAR                      every sprite off, the text layer blank: OK
   STATE [id]                 (tests, tools) OK, a line a sprite: id x y pattern visible
```

## 4. The command stream (DATA frames; the same bytes from BASIC, NTC or C0)

A DATA frame is a run of commands; COMMIT ends a batch. Commands before a COMMIT are held and
applied together at the next frame, so a batch is atomic on the screen; two COMMITs within one
frame are applied in order, both. The first byte of a stream after OPEN is the version: 1 - the
front's to send (Streamer sends it at its OPEN opcode; a program never writes it, since 1 is also
the SPR opcode). Opcodes (hex), then the fields:

```
   01 SPR     id16 pat16 x16 y16 flags8        a sprite set whole (flags bit 0 visible)
   02 POS     id16 x16 y16                      moved
   03 PAT     id16 pat16                        its pattern
   04 SHOW    id16 on8                          shown / hidden
   05 VEL     id16 vx16 vy16                    a mover: velocity in 12.4 a frame, until changed
   06 BOUNDS  id16 mode8                        at the edge: 0 nothing, 1 wrap, 2 kill (hidden +
                                                DIED), 3 stop, 4 EDGE event
   07 CLASS   id16 cls8 mask8                   collision: its class, the classes it hits (bits)
   08 KILL    id16                              off, its mover gone
   30 TEXT    col8 row8 len8 bytes              the text layer (v1: shown, 8 x 8 cells)
   7F COMMIT                                    the batch applied at the next frame
   (to come, same shape:  09 ANIM  0A PATH  0B EMIT  20 TILE  21 TILEROW  40 SCROLL  50 PAL)
```

## 5. Events (EVT frames back, text)

```
   V n            a frame drawn, n its counter (sent when the client asked: OPEN ... vsync=1)
   HIT a b        sprites a and b overlap (box; once per pair per frame)
   EDGE id s      sprite id reached edge s (0 left 1 right 2 top 3 bottom) with BOUNDS 4
   DIED id        BOUNDS 2 took it off
   DONE id        the sprite's sequence stopped (a 0 step)
```

## 6. The engine (one frame)

```
   commands held since the last COMMIT applied  ->  movers: x += vx, y += vy  ->  bounds
   ->  collisions (class/mask, boxes)  ->  events out  ->  the picture to the viewer page
```

The viewer page (pi/web/vdu.html, a vdp display beside the vdu ones) draws the sprites from the
frame the service sends it (sprite list: id, x, y, pattern, visible) on a canvas of the profile's
size. Patterns go to the page once, decoded to RGBA by the profile's decoder.

## 7. The fronts

- NTC: a VDP class whose methods write these commands into a buffer and send it as DATA; events
  read as lines. The same class with a Z80 backend for the real chip.
- Streamer: RTG:V9990/CMD takes the same bytes (PRINT #9 of a string); RTG:V9990/EVENTS the
  events as lines; RTG:V9990/PATTERNS a SAVE of the pattern data (the PATTERNS request).
- CyborgOS: C0's channel ops; a slot's buffer is the DATA frame.
