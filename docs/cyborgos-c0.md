# CyborgOS - the C0 build (the hypervisor's memory model, and its exceptions)

The hypervisor's own memory map for the **C0 (flat) build** - the whole hypervisor in one 64K, with
no kernel bank. This build exists to compare against the C2 (split) build; the C2 build is the real
CyborgOS and is documented in [cyborgos-c2.md](cyborgos-c2.md). Written from the code, 2026-11-07
(src/bas/cyborgosc0/Main.bas, Hyp.cls; build/stage/CYBC0.BIN). Julian to verify.

Everything below is how C0 **differs** from the C2 model. The slot memory model
([cyborgos-memory-model.md](cyborgos-memory-model.md)) is the same in both builds.

## What the C0 build is

The entire hypervisor - the parts that in the C2 build are split between the thin block-1 hypervisor
and the kernel bank - is crammed into **block 1 (main RAM) alone**. No kernel bank. It is the
all-in-one build, kept to measure against the split.

Because block 1 already has the forced video memory (the VDU always reads block 1), cramming the
whole hypervisor in there runs the code+data straight through the ROM-RAM line at #A5F0. Without a
fix it overflows to about #B55D - ~3.9 KB over. There is no free *resident* RAM below the line to
take it, and the only free non-volatile 16K on the CPC is #C000 - which is the screen's default home.

So the C0 build does two forced things, both via NTC's `Option HighCode`:

1. **Move the screen to #4000** (so #C000 is no longer displayed, and code can live there unseen).
2. **Relocate the code overflow to #C000** - stored at #4000 in the file, copied up once at boot by
   a throwaway loader, then resident at #C000 for the session.

`Option Place Hyp, Ent` keeps Hyp's and Ent's code *out* of #C000 (they must stay in main RAM
whatever is paged at #C000). With this, code+data ends at `ntc_free #944C` - back under #A5F0, ~4.4 KB
to spare - and the overflow runs resident at #C000.

## The CPC memory map, C0 build (with HighCode)

```
 block 1 (main RAM) - the whole hypervisor
 #0000 +--------------------------------------------------+
       | #0000-#003F  switcher stubs / low vectors        |  ntc_start #0040
 #0040 +--------------------------------------------------+
       | #0040-#3FFF  hypervisor code                     |  mem_start #0AF3 (mem mgr low)
 #4000 +--------------------------------------------------+
       | #4000-#7FFF  SCREEN (main page 1) + the WINDOW   |  R12 = #10 -> displayed from
       |              shared: screen hidden while a bank  |  #4000 (sm_start db #10).
       |              is in; VDU reads block 1, no glitch |  banks map in via C4-C7
 #8000 +--------------------------------------------------+
       | #8000-#8C77  hypervisor code + data              |  ntc_end #8C77 (ticker #8C75)
       | #8C77-#944C  BSS arrays                          |  ntc_free #944C
       | #944C-#A5F0  free (~4.4K under the ROM line)      |
 #A5F0 +--------------------------------------------------+  NTC_FWBLK: ROMs' RAM
       | #A5F0-#BFFF  AMSDOS / UniDOS workspace           |
 #C000 +--------------------------------------------------+
       | #C000-#FFFF  OVERFLOW CODE (HighCode): BASIC      |  stored at #4000 in the file,
       |              procedures + class #asm, resident.  |  copied here once at boot.
       |              NOT Hyp/Ent (Option Place keeps      |  When a slot is mapped, its
       |              them below). The console uses a      |  page 3 (#C000) is the console
       |              slot's page 3 at #C000 (layout 1).  |  (layout 1).
 #FFFF +--------------------------------------------------+
```

## The cost: bank -> screen is no longer direct

With the screen at #4000 it shares the 16K with the paging window, so a bank and the screen can never
be mapped at once. Copying a bank's page onto the screen takes **two hops** (bank -> a buffer in main
RAM -> screen), where the C2 build (screen at #C000) does it in **one** (#4000 window -> #C000). This
penalty is unique to the C0 build.

## Deprecated directives - C0 build only

`Option HighCode` and `Option Place` are **deprecated** in NTC. The C0 flat build is their only
real-world use - HighCode exists precisely for "whole program in main RAM, must spill code to #C000,
move the screen to #4000," which is exactly this build and nothing else. So cyborgosc0/Main.bas
carries `Option Deprecated` to allow them; no other CyborgOS build uses either directive (the C2
build, the Next and the MSX need none of this), and HighCode is CPC-only regardless (NTC refuses it
on any platform but cpcfw, and with Library: ROM, since a ROM sits at #C000).

The options block (cyborgosc0/Main.bas):

```
Option Memory Paged &H4000, &H4000   ' the window (built round)
Option Deprecated                    ' C0 build ONLY: allow HighCode + Place
Option HighCode                      ' overflow code at #C000; screen to #4000
Option Place Hyp, Ent                ' keep Hyp/Ent in main, never at #C000
```

## Build outputs

CYBC0.BIN, loader COSLOADC0.BIN (named by CYB_HIGH, which the builder emits only for a HighCode
build), discs in build/dskc0/, installed by INSTALLF.BAS. Regression:
`node tools/regress/cosregress.js --dsk=build/dskc0` (its own ref/c0/ screens).
