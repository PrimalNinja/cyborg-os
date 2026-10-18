# Cyborg Pluto - Nuclear Tight Security on the CPC

Pluto is the Amstrad CPC edition of Cyborg NTS: a short list of NTS's features as small
programs, one to a slot, built on NTC. Keys and plaintext stay on the CPC; only what has been
encoded goes on the wire (the TCP/IP stack lives on the M4, a separate microcontroller - the
"shown on a machine anyone can see through" point). A Pluto file is a plain UNSIGNAL / BRICS
file: the PC NTS tools read what the CPC makes, and the CPC reads theirs.

This document is the CPC implementation's state. The protocols themselves are Julian's
(`block-reinforced-index-confidentiality-scheme.md`, `unsignal-protocol.md`, the micro
variants, and the protocol creator `unsignal-creator.html`); the C# library
(`CyborgUnicorn.UNINTELLIGENCE`) is the other reference.

## The six layers

A request names 1 to 3 layers, any mix and order, each a method and its own key:

| code | method | addressing | notes |
|------|--------|-----------|-------|
| `z`  | ZOSCII | 16-bit, into the key's bytes | fixed window |
| `u`  | UNSIGNAL | 16-bit | `z` plus a random ROM offset and random prefix / suffix |
| `b`  | BRICS | 16-bit | `u` split into blocks, each re-offset |
| `mz` | microZOSCII | 8-bit, into the key's nibbles | the key's first 128 bytes = 256 nibbles, high nibble first |
| `mu` | microUNSIGNAL | 8-bit | `mz` with offset and padding |
| `mb` | microBRICS | 8-bit | `mz` in blocks |

The micro three are for key exchange and are usually the **inner** layer. One message byte is one
element for the 16-bit layers, two nibble elements (high then low) for the micro ones.

Header values (offset, prefix / suffix length, block size) are composed low part first, each part
an address dereferenced to a key value. The offset regime is the specs' and the C#'s
(`EffectiveSize` / `SlidingWindow`): for ROM size x and cap (65536, or 256 micro),

- `x < cap + 2% of cap`: effective `x - 2% of x`, window `2% of x`
- `x < 2·cap`: effective `cap`, window `2·cap - x - 2% of x`
- else: effective `cap`, window `cap`

The offset is `pointer mod (window + 1)`; a data address is window-relative, folded `mod effective`
on decode. Nibble order is high-first, as the C# does it (the protocol docs to be reconciled to
that later).

## Files and alignment

A Pluto file is exactly `[header addresses][prefix][encoded data][suffix]` - no extra wrapper. The
CPC's filesystem writes whole 128-byte records, and that is not a problem: the prefix and suffix
lengths are indirections in the spec's header, so the encoder sizes the **suffix** to bring the
whole file to a multiple of 128. The decoder strips exactly that suffix, so the record padding *is*
the suffix and disappears. The decode chain recovers the exact plaintext length itself (the data
address count), so nothing extra is stored. A `z` / `mz` outer layer has no suffix to pad with - wrap
it in `u` / `b`, or store on UniDOS (which keeps exact lengths). Micro suffixes are one nibble (max
15) and can't align a file, so the outer layer that aligns is always a 16-bit `u` / `b`.

## What is built (this session)

- **The engine, `apps/pluto/Zc.cls`** - all six layers, encode and decode, keys given as a byte
  array. Validated in the harness: every layer round-trips over several message lengths, and
  byte for byte against the PC reference `tools/pluto/pluto.py` (which is itself checked against
  Julian's C# and the protocol creator's C, both ways) - regress "Pluto engine".
- **The file tools, `ENC` / `DEC`** (`apps/pluto/Chain.cls`) - encode / decode a file through 1-3
  layers, keys from `KEYS/NAME.KEY`. The outer `u` / `b` layer aligns the file to 128. A CPC-made
  file decodes on the PC and vice versa.
    - `ENC mu:inner u:mykey message.txt message.pcb`
    - `DEC mu:inner u:mykey message.pcb back.txt` (the same layers, undone last first)
- **The key manager, `KEYMGR`** - `LIST`; `JPEG name pic.jpg size` (a key from the first `size`
  bytes of a picture); `ENTROPY name size f1 .. f5` (a key XORed from up to 5 source files, each
  read from a start in a direction seeded by entropy sugar - the 300Hz clock, `CybSys.Uptime`, free
  memory - the ROM generator's `ROMGenerator.cs` way).
- **The service, `KEYMAN`** (`RUN 2 KEYMAN`) - hosts the keys (loaded from `KEYS/` on demand,
  cached) and encodes / decodes on its port, so other slots never handle the keys. The bulk never
  crosses the 128-byte port: the request names the layers and *where the data is in the caller's
  own memory*, and KEYMAN pulls it through the kernel into its buffer, works on it, and writes the
  result back into the caller's slot. The request (the three numbers in hex):
    - `E layer[s] nbytes src dst` - encode `nbytes` at `src` (in the caller) through the layers,
      the result to `dst`; reply `ok len`. `D ...` to decode. `K` the loaded keys, `R` clears the
      cache. Validated in the harness (regress "Pluto KEYMAN service") by a client that encodes a
      message and decodes it back, the data moving through the kernel both ways.
- Keys live in `KEYS/` as raw ROM bytes; the size says the kind (128 a microROM, more a full ROM).

### The transfer (KEYMAN and the kernel)

A port message is 128 bytes, far smaller than most encoded output, so KEYMAN moves the data through
the kernel, not the port:

- **Read from the caller:** BDOS 131 op 10 (memory) already copies another slot's memory into the
  caller's buffer (Byte(1) = 3, slot Word(2), from Word(4), to Word(6), Word(8) bytes).
- **Write to the caller:** op 10 gained the inverse (Byte(1) = 4): the caller's own Word(6) written
  into slot Word(2) at Word(4). A service hands a result back with it.
- Each op 10 moves up to 2K and stays within a 16K bank page, so KEYMAN's own SlotRead / SlotWrite
  (built on `CybSys.SetWord` / `Ask`, so the shared CybSys class is untouched) chunk a longer
  transfer. The crypto stays one clean UNSIGNAL / BRICS stream; only the transfer is chunked. KEYMAN
  message mode uses exact in-memory lengths, so it does not 128-align (that is only for files on
  disc).

### Engine limits (this build)

- The engine Peeks a flat key buffer, so a key must fit the addressable 64K. `ENC` / `DEC` hold the
  key and the file in RAM (a key up to ~8K, a file up to ~1K through three layers). Message mode
  (short messages, micro keys) is the target; larger needs the banked path below.
- 16-bit (`z` / `u` / `b`) keys larger than about 32K need the banked-store path (NTC's signed
  16-bit arithmetic can't index past 32767 in a flat buffer). Micro keys (128 bytes) are the
  common case and have no such limit.

## Measured on the emulated CPC

- A hypervisor call (BDOS 131) costs about 9-13 ms whatever it does - roughly 100 a second - because
  it goes through the BASIC dispatcher. So a service can't read its key a byte at a time per call;
  it moves data in 2K blocks (about 100 KB/s) and does the work in a local loop.
- The store (a slot's banked 16K pages, BDOS 131 op 12-14) now also reads from any byte offset in a
  block (Byte(1) = 1), so KEYMAN can fetch header bytes without copying a whole block.

## Still to build

- **KEYMAN into its store** - it now caches keys in RAM (up to ~8 keys). Loading them into the 512K
  store, and the banked path for 16-bit keys over ~32K (or hosting a key ROM the CPC addresses as an
  upper ROM - never in the untrusted Pi), is the next step for big keys.
- **KEYMGR DH** - 4 Diffie-Hellman exchanges to a 256-byte microROM. Needs the group (768-bit
  Oakley group 1, 64 bytes of each secret?), the relay channels (four PHP mailboxes?), and the Z80
  big-number maths (minutes on a CPC, the FromBytes 240-nibble clamp to watch).
- **SCIF** (the CyborgSCIF chat client), **PEER** (CPC-to-CPC messaging), both through KEYMAN.
- **FLOPWR** - the CPC's USB stick: format a floppy and write it by direct sector writes as one raw
  encoded stream, no directory, always the whole disc; the rest filled with encoded random bytes so
  the disc is one stream of the same statistics throughout.
- **SD container** `PLUTO.BIN` - FLOPWR's whole-disc stream as one fixed-size file for a PC (or the
  Next's SD) to read; only decoding needs the keys.
- **Exact file lengths without UniDOS** - a small hypervisor addition to write a short last record,
  for encoding files to exact lengths on a RAM disc / AMSDOS (the 128-alignment covers `u` / `b`
  already).
