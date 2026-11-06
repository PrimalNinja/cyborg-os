# CyborgOS - the C2 build (the hypervisor's memory model)

The hypervisor's own memory map for the **C2 (split) build** - the real CyborgOS, and the model the
rest of the docs assume. Written from the code, 2026-11-07 (src/bas/cyborgosc2/Main.bas, Hyp.cls;
build/stage/CYBORGOS.BIN + KERNEL.CYB). Julian to verify. The C0 (flat) build's exceptions are in
[cyborgos-c0.md](cyborgos-c0.md). The *slot* memory model - what a program in a 64K slot sees - is
[cyborgos-memory-model.md](cyborgos-memory-model.md), and is the same in both builds.

## What the C2 build is

The hypervisor is split in two:

- **C0 side** - a *thin* hypervisor in block 1 (main RAM). It does only what must live in block 1:
  own the forced video memory and coordinate the paging (the gate array). Nothing else.
- **C2 side** - the kernel (scheduler, the kernel BDOS functions, the bulk of CyborgOS) in **its own
  clean 64K bank**. C0 pages the kernel's banks (C4-C7) when it needs direct access; the kernel keeps
  its variables high in its bank.

This is the whole architecture in one move: block 1 is the only "dirty" 64K (video is nailed to it -
the VDU always reads block 1), so everything that does *not* need to be there is pushed to clean
banks. That is also why there can be so many slots: every 64K except block 1 is an identical clean
64K.

## C0's role in the C2 model: a block-1 resource holder, not a hypervisor

In the C2 model C0 is **not** the hypervisor - **C2 is**, and every slot talks to C2 as if C0 did not
exist. C0 is reduced to holding only the things physically nailed to block 1, and serving them to C2
on request:

- **disc buffers** - the firmware / AMSDOS reads and writes its buffers in main RAM.
- **two screens (video memory)** - the VDU reads block 1, so the screen lives there; with the kernel
  gone to C2 there is room for a double-buffer (front #C000, back #4000) - double buffering, dropped
  for memory in the flat build, can come back here.
- **block-transfer functions** - the copy engine (the store's 2K blocks, bank <-> slot, bank ->
  screen). The LDIR code must stay resident *while* it switches banks, so it cannot live in a bank
  that gets swapped out from under it.
- **far-call redirection** - the #0044 / #0046 trampoline: a far call routed through C0 instead of a
  full 64K bank swap, resident so any bank can reach it.
- **6128 Plus sprites / ASIC** - the Plus maps its sprite RAM and registers into block 1's #4000
  space, reachable only from there.
- **firmware** - the CPC ROMs run in block 1; firmware calls go through C0.
- **loadable-driver dispatch (the wedges)** - the linked list of installed drivers and the loop that
  walks it. A driver loads into any bank (up to 255) as a relocatable module with a jumpblock and an
  optional ISR (PRIMAL's module format). It is reachable only by paging its bank into the window,
  which only C0 can do (the selector is one `out (c),c` on ports #78-#7F). So C0 holds the list and
  calls through it: a jumpblock call on demand, the ISR on the tick walk. *Open:* the ticker/keyscan
  *policy* could move to C2, but the per-driver paging cannot - C2 is itself a bank and can't select
  banks, so a dispatch loop in C2 would round-trip to C0 per driver per tick.

Everything not chained to block 1 - the scheduler, the kernel BDOS functions, the lists, the
services - is C2's, in its clean bank. So C0 is a dumb I/O and plumbing surface; the brain is C2.

**The rule (what removes the mess):** something belongs in C0 only if it is *physically chained to
block 1* - forced video, the firmware and its buffers, the resident copy/trampoline code, the Plus
ASIC. If it isn't, it goes to C2. The flat build had no such line (it crammed the OS and the hardware
surface into one 64K - that is the mess); the split draws the line by the hardware, not by judgment,
so nothing creeps back.

## The CPC memory map, C2 build

```
 C0 side - block 1 (main RAM), the thin hypervisor
 #0000 +--------------------------------------------------+
       | #0000-#003F  switcher stubs / low vectors        |  ntc_start #0040
 #0040 +--------------------------------------------------+
       | #0040-#3FFF  hypervisor code                     |
 #4000 +--------------------------------------------------+
       | #4000-#7FFF  the PAGING WINDOW (main page 1)     |  banks map in here (gate-array
       |              also kept as an unused "2nd screen" |  codes C4-C7); the VDU still
       |              - volatile, never resident code     |  reads block 1, so no glitch
 #8000 +--------------------------------------------------+
       | #8000-#8E72  code + page tables (3 bytes a page) |  mem_start #83D3
       |              + data                              |  ntc_end #8E72
       | #8E72-#A39F  BSS                                 |  ntc_free #A39F
       | #A39F-#A5F0  free (~0.6K under the ROM line)     |
 #A5F0 +--------------------------------------------------+  NTC_FWBLK: ROMs' RAM
       | #A5F0-#BFFF  AMSDOS / UniDOS workspace           |
 #C000 +--------------------------------------------------+
       | #C000-#FFFF  SCREEN (main RAM) - the console,    |  R12 = #30 -> displayed from
       |              displayed from here                 |  #C000 (sm_start db #30)
 #FFFF +--------------------------------------------------+

 C2 side - its own clean 64K bank, the kernel
 #0000 +--------------------------------------------------+
       | full clean 64K, no forced video: the scheduler,  |
       | the kernel BDOS functions, the bulk of CyborgOS  |
 #FFFF +--------------------------------------------------+   (+ kernel pages C4-C7 as needed)
```

## Why it fits, and why it needs no HighCode

Because the kernel lives in its own bank, the block-1 hypervisor is small: its code and data end at
`ntc_free #A39F`, just under the ROM-RAM line at #A5F0. Nothing overflows, so there is no need to
relocate code to #C000 - and the screen stays at its default #C000.

That keeps a real advantage the C0 build loses: **bank -> screen copies are direct.** A bank is
mapped into the #4000 window, the screen is at #C000, both are addressable at once, so a copy is one
hop (#4000 -> #C000). (In the C0 build the screen is at #4000, sharing the window, so the same copy
needs two hops through a buffer - see cyborgos-c0.md.)

## Gate-array configs this build uses (CPC)

| config (OUT &7Fxx, xx =) | #0000 | #4000 | #8000 | #C000 | use |
|---|---|---|---|---|---|
| C0 (&C0) | base 0 | base 1 | base 2 | base 3 | normal (screen at #C000 displays) |
| C4-C7 (&C4-&C7) | base 0 | **bank page** | base 2 | base 3 | the paging window |
| C1 (&C1) | base 0 | base 1 | base 2 | **bank page** | a possible 2nd window at #C000 (the VDU still reads block 1, so the screen is undisturbed) - not used yet |

C2 (&C2, all-expansion) and C3 (&C3, repeats a sub-block) are not used by the hypervisor.

Note (Dk'tronics hardware): the VDU circuitry always reads from block 1 regardless of the config, so
paging a bank into any region for the Z80 never corrupts the displayed screen.

## The other machines

The Next and the MSX run the same split (thin C0 + kernel bank) with their own switch (the Next's 8K
MMU, the MSX mapper) and no CPC #C000/#4000 constraints - HighCode is CPC-only and not used there. The
vCPC is the host program and needs no window at all. The slot layout (cyborgos-memory-model.md) is
identical on all of them.
