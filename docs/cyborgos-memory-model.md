# CyborgOS - the memory model

How CyborgOS lays memory out on each machine, what a program in a slot has, and what CyborgOS can
give it beyond that. Written from the code, 2026-11-02 (Main.bas, KERNEL.bas, CybSys.cls,
RAMDISC.bas, Bml.cls, cyborgos/Hyp.cls, cyborgosmsx/Main.bas, vcpc.c; NTC's cyborgos target:
asm/ntc_plat_cyborgos.asm and lib/cpm/Memory.cls, List.cls). Julian to verify.

## 1. One model on four machines

CyborgOS keeps one shape everywhere: memory is 16K pages, a bank is 4 pages (64K), and a page is
used by switching it into C0's window at #4000-#7FFF. What switches it is the machine's:

| Machine | The switch | Banks |
|---|---|---|
| CPC | the gate array (port #7F the first 512K, #7E .. #78 the rest) | up to 64 (4 MB) |
| ZX Spectrum Next | MMU slots 2 and 3 (NextReg #52, #53): a 16K page is two 8K MMU pages | 4 Next banks each; by the Next's RAM |
| MSX | MSX-DOS 2 / Nextor's memory mapper: a 16K page is a segment from its allocator | 4 segments each; by the mapper |
| vCPC | the host program: 64 banks of 64K in C (vcpc.c, NBANKS) | 64 (4 MB) |

C0 is the only thing that touches the switch. On the CPC, the Next and the MSX it lives in main
RAM with the window at #4000-#7FFF and its page tables (3 bytes a page) above; on the vCPC it is
the host program and needs no window. The kernel runs in a bank of its own; each slot is a bank;
Z (the system drive) and RAM discs are pages. 576K is 3 slots and Z, 1 MB 7, 4 MB up to 20.

On the CPC the page tables must fit between C0's arrays and HIMEM, which ROMs' workspace lowers:
when they don't, pages are dropped (NTC's mem_tb_fit) and MEM says "Not mapped: nK".

## 2. A slot

A slot is one bank laid out as CP/M 2.2, the same on all four machines:

| | |
|---|---|
| #0000-#00FF | CP/M's page zero: the BDOS jump at #0005, the FCBs, the command tail at #0080, the bank switch at #0044 |
| #0100-#EEFF | the program (59.5K) |
| #EF00-#F2FF | the BDOS, the BIOS jump table, the stubs, the first stack |
| #F300-#F6FF | the font, the console's state, the command line, the program's name |
| #F700-#FEFF | the slot's text page (2K) |
| #FF00-#FF1F | its store's page numbers (32: op 12) |
| #FFFE | its saved SP |

The hypervisor switches a slot's bank in for its slice and out again. A program sees its own 64K
and nothing else, and must not touch the bank switch: CyborgOS owns the banks and the window.

A slot program is built for NTC's cyborgos target, which is CP/M underneath (";@base cpm") with
CyborgOS's classes on top. So its Memory class is Memory Small: no paging, Alloc / Free over the
free part of the 59.5K, far pointers plain addresses, Pages() = 0. List (linked lists in Memory's
heap) lives there too. The compiler refuses Option Memory CPCExpansion for cyborgos. This is the
same on all four machines, and it is why one .CYB runs in a slot on any of them: it never touches
the hardware that differs.

## 3. What CyborgOS gives a slot beyond its 64K

A slot never addresses memory outside its bank. What it can have beyond its 64K it reaches
through C0 (BDOS 131), by copy - which is what keeps a slot off the bank switch, and the same
.CYB running on all four machines. Two kinds, for two uses; a program can hold both at once, and
C0 frees everything a program has when it ends.

### 3.1 The store - a slot's own flat block, like a C64 REU

The store is to a slot what an REU is to a C64: memory the program can't address, moved to and
from its own memory a block at a time by someone else. Three ops:

- **12, size:** "give me n K". C0 takes n \ 16 pages from the free pool (TypeUser in the system
  RAT), writes their numbers in the slot's own 32-byte table at #FF00 (a byte a page, 0 none) and
  answers 0; 2 when there aren't that many free. Asking for less frees the rest. 512K at most
  (32 entries); gone when the program ends. Not kept by DUMP, REVIVE or a move.
- **13, write:** 2K from the slot's memory at an address into block n of the store (block n is
  in page n \ 8: C0 maps it, copies, puts the window back).
- **14, read:** the reverse, block n into the slot's memory.

So the program has up to 256 numbered 2K blocks, private to it, with no headers and no walking:
an offset into its data is arithmetic (block = offset \ 2048). The fastest way to a big flat
thing - a key pool, a page of lines, a table of fixed records. One call to get it, then copies.
Today's user: Bml.cls (YING, YANG, MON) keeps a page's lines in it, 2K blocks at a time, a few
cached in the slot. KEYMAN should (its keys are capped at 8K by its 16K pool - buglist 53).

Against an REU: the REU moves any length from any address by DMA; the store moves aligned 2K
blocks by C0's LDIR with a bank switch each side - a few hundred T of overhead, then 21 T a byte,
far quicker than a disc. On the vCPC a store is one free 64K bank, not pages: 64K there until it
does pages.

### 3.2 Lists - nodes in the hypervisor's heap (built 2026-11-04; PRIMAL is the model)

Not built yet. The design: C0's Memory heap (D pages from the free pool, nodes packed in them by
NTC's Memory.Alloc) holds one system list; each slot's lists are entries on it, a head a list,
and a slot creates as many as it likes and gets a handle (a Long, a far pointer into C0's heap)
for each. Nodes come from the same free pool, so a slot's list takes whatever RAM is free across
the banks - no fixed size up front, no 512K cap, shared with the hypervisor's own lists.
Ops (BDOS 131): create, free, append, prepend, insert, remove, first, next, previous, read node,
write node, count; a node's data crosses by copy in the call, as the store's blocks do. CybSys
wraps them with NTC's List calls, so a program's code reads the same in a slot as on a CPC.
Each node is a C0 call (a few hundred T) against a few dozen for a native List node: right for
indexes, tables and anything that grows; wrong for walking thousands of nodes a frame.

PRIMAL (Julian's Z80 OS) is the model: separate heaps - the system's, an application's - each a
linked list of nodes over bank memory, the kernel owning the bank select and copying between
banks; the heap type is in effect a ninth address bit (256 banks for the system and 256 for
applications, 8 MB, when hardware decodes past the CPC's 8 ports).

### 3.3 The rest

- **A RAM disc** (RAMDISC v size; BDOS 130 - the CPC, the Next and the MSX; not the vCPC yet):
  free pages as a CP/M drive with real random access - any number of files, open from any slot, in
  16K steps up to 4 MB in all, surviving a program's end. For a database: fixed-length records, a
  seek a record, several files open. Shared between slots.
- **Memory read** (op 10): a slot reads any page, ROM, main RAM or another slot, 2K at a time:
  MON's. Read only.

MEM shows: Total memory (the banks found), Free memory (pages no slot, store, RAM disc or
CyborgOS has), and on the CPC "Not mapped" when the tables didn't fit.

### 3.4 Protection: what a slot can reach, and what stops it (Julian, 2026-11-03)

There is no memory protection in CyborgOS, by decision. The computer is the user's: a program
that wants to work on the whole machine may. What exists is isolation of accidents, not a
security boundary:

- A slot's own 64K is its own. Its top (#EF00-#FFFF on a CP/M-layout slot: the BDOS and BIOS
  traps, the kernel's state for the slot, the console page, the store table at #FF00, the saved
  registers) is the hypervisor's, and a program that writes there breaks its own slot - on a real
  CPC without a word said.
- A slot can reach other slots on purpose: op 10 (a service reading and writing the caller's
  memory, as KEYMAN does) takes any slot number; the store table at #FF00 is in the slot's own
  bank, so a program that changes its page numbers makes ops 12-14 work on another slot's pages.
  Both stay as they are. (The vCPC keeps its store mapping in C, so the second isn't reachable
  there.)
- The slot lists (cyborgos-slot-lists.md) are the other way round by construction: the hypervisor
  holds the tables and a slot holds only a number, looked up in the caller's own list. If the store
  table and op 10 are ever to be tightened, that is the shape: the table out of the slot into C0,
  indexed by slot; op 10 only between a service and the slots with a port open to it.
- The vCPC has an optional protection, on by default (`--protect 0` turns it off): a slot's write
  to #EF00-#FFFF or #0000-#0007, or its PC running into #EF49-#FFFF, stops that slot with a line on
  its console saying where. It catches a program's bug before the same program is run on a CPC;
  C0 itself (the C code) is not checked, and neither is op 10 - it is a bug-finder, not a wall.

## 4. The limits, and what would move them

| In a slot, any machine | now | with lists |
|---|---|---|
| Program's own memory | 59.5K | 59.5K |
| Memory mode | Small only | Small only |
| A flat block of its own | the store: up to 512K, by 2K copies (vCPC 64K) | the same |
| Lists | the slot's free RAM | the hypervisor's heap: whatever is free, up to 4 MB |
| Big data with random access | a RAM disc, up to 4 MB, shared (not the vCPC yet) | the same |

- **The store's table** at #FF00 holds page numbers as bytes: on a 4 MB CPC (pages 1-257) pages
  256 and 257 can never be in a store. Words, or the table in C0's memory, fixes it; and 512K is
  only the table's 32 entries.
- **Lists** are the build above: C0's ops, the kernel passing them through, CybSys's wrapper, a
  test program.
- **RAM discs and paged stores on the vCPC**: BDOS 130 unanswered there; the store one bank -
  the vCPC's todo.
- **A real window** (C0 mapping a page of the slot's own into #4000-#7FFF on request, and a
  cyborgos Memory.cls that asks C0 instead of the hardware) would give a slot NTC's own paged
  Memory and List at the machine's speed. A bigger change; the lists above don't need it.
