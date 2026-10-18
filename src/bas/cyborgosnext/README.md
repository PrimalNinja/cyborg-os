# CyborgOS-Next — ZX Spectrum Next port (foundation)

The start of porting CyborgOS (the CPC 320K hypervisor, `src/bas/cyborgos320kb/`) to the ZX
Spectrum Next. See `docs/cyborgos-next-port.md` for the full porting notes, the CPC→Next hardware
map, and the staged plan.

This folder is the **proven foundation** — the banking the whole hypervisor stands on, on real
`zxn`-target code running in the harness:

- **`Banks.cls`** — CyborgOS-Next banking + allocation. The Next's 8K MMU pages (NextReg `#50-#57`)
  as the CPC's 64K slots. `MapWin` a 16K bank into the `#4000-#7FFF` window (MMU slots 2/3), `Probe`
  the RAM, `Slots`/`SlotBank`, a 64K-slot free list (`Init`/`Alloc`/`Free`), and `Copy` (cross-bank
  byte copy through a resident buffer). NextReg via ports `#243B`/`#253B` (no Z80N opcodes).
- **`bank_proof.bas`** — proves a 64K bank = 8 isolated 8K MMU pages through the window.
- **`cap_proof.bas`** — probes capacity: 111 usable 16K banks = 27 × 64K slots on a 2MB Next.
- **`sched_proof.bas`** — the round-robin scheduler model: 3 tasks, each state in its own bank,
  advancing independently across passes.
- **`alloc_proof.bas`** — the slot allocator (free-list reuse) and a cross-bank copy, verified.

Build/run any of them on the Next target:

```
node cli.js bas/cyborgosnext/cap_proof.bas bas/cyborgosnext/Banks.cls --platform=zxn
python3 src/test/ntcrun.py bas/cyborgosnext/cap_proof.bas "" bas/cyborgosnext/Banks.cls --platform=zxn
```

Still to come (see the porting notes): the asm register/SP context switch, the
console/keyboard/BDOS service layer on Next hardware, the NextZXOS file layer, the boot `.NEX`, and
folding `Hyp.cls` onto this base.
