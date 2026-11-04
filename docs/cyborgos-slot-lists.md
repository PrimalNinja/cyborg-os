# Slot lists - linked lists for slot programs in the hypervisor's heap (design, to build)

Julian's design, 2026-11-02, written up from the conversation for the session that builds it.
PRIMAL (Julian's Z80 OS: load.asm's heaps, mem.asm's bank select and far copies) is the model.
The memory model as it stands is in cyborgos-memory-model.md.

## 1. The problem

NTC's List class gives a program on a bare CPC linked lists over every free page of the
machine, up to 4 MB. In a CyborgOS slot the same program has List only inside its own 59.5K: the
cyborgos target is Memory Small, and a slot must not touch the bank switch. The store (BDOS 131
ops 12-14) is the only memory a slot can have beyond its 64K: a flat block of up to 512K reached
by 2K copies, an REU. So a slot program cannot have a 3 MB list today.

## 2. The design

**Two kinds of list, one heap.** The hypervisor has its own lists, and each slot has its lists.
All of them live in the hypervisor's heap: C0's Memory (Option Memory CPCExpansion) heap, D pages
taken from the free pool, nodes packed into them by NTC's Memory.Alloc. The system allocates 16K
pages fast through its RAT (the page type table: a free page is a CPIR); node allocation inside a
page is Memory.Alloc's / List's own (blocks cut into nodes on a free chain, nothing fragments).

**One system list of all slot lists.**

    system list --> nodeS --> nodeS --> nodeS ...        (one entry a slot list: the owning slot,
                      |                                   the list's id, its head, its node size)
                      +--> node --> node --> node ...    (that slot list's own nodes)

A slot creates a list and gets a handle; it can create any number, as can the hypervisor. A slot
list's nodes take whatever RAM is free when each is made, from the same pool as everything else:
no size up front, no cap but free memory, shared with the hypervisor's own lists.

**Half the banks are slots; the other half is the pool.** C0 gives half the expansion banks
to slots (ns = banks \ 2, 20 at most - Main.bas, COSLOAD) for exactly this: the other half is the
heap the lists live in, beside Z, the RAM discs and the stores. That pool is shared, so:

- **no single program may take it all.** Each slot has a quota of pages for its lists and its
  store together, set by C0 at boot from the pool's size (the free pool divided among the slots,
  or a fixed cap - Julian's call; a per-slot limit in C0's slot table either way). A slot at its
  quota gets "no room" from append / create / size even while free pages remain. Nothing a slot
  does can shrink what another slot or the hypervisor can have;
- **the hypervisor keeps a reserve** of pages for its own lists that slots can't take;
- Z and the RAM discs are what they are now (pages taken at boot or by RAMDISC); MEM's totals
  show the pool, each slot's share in TOP or MEM (as the store size shows nothing today - it
  should).

**The slot never touches the switch.** Every operation is a C0 op (BDOS 131); a node's data
crosses by copy in the call, as the store's blocks do (PRIMAL's F2N / N2F). So the same .CYB
runs in a slot on the CPC, the Next, the MSX and the vCPC: C0 does the paging with each machine's
own switch (the gate array, the MMU, the mapper, the C banks).

**Ownership is the hypervisor's record.** Each entry on the system list carries its slot's
number. That is how C0 knows whose lists are whose when a slot ends, is killed, reset, dumped or
moved; nothing a slot can do puts a list anywhere else, so nothing is untracked.

**The store stays.** It is the fast flat block for a program that wants one (a key pool, a
table of fixed records); lists are for what grows and is walked. A program may hold both.

## 3. Handles

Handles must survive a dump and a move, so they are not addresses:

- a **list handle** is the list's id in the slot's own list table in C0 (1, 2, 3 ...), not a far
  pointer;
- a **node handle** is a node number within its list, nothing more: the hypervisor keeps a map
  from node number to where the node is, and only it ever knows the place;
- the maps are the hypervisor's, in its heap. A dump writes each list's nodes in order; a revive
  makes the lists again and gives the nodes the same numbers, so handles a program kept in its
  variables still work. And because a number isn't a place, the hypervisor can move a node
  (compaction, 8a) and nothing a program holds changes.

PRIMAL hands out addresses because its heaps never move; CyborgOS moves slots, so the ids are the
extra layer. One lookup an op in C0, small against the copy.

Handles are Longs on the slot's side, as NTC's List handles are now.

## 4. The ops (BDOS 131, new numbers - the next free ones)

| op | does | answers |
|---|---|---|
| create size | a new empty list, size data bytes a node | the list handle; 0 no room |
| destroy h | the list and all its nodes freed | 0 |
| append h / prepend h / insertafter h, node | a new node | the node handle; 0 no room |
| delete h, node | the node freed | 0 / 255 |
| first h / last h / next node / prev node | a walk | the node handle; 0 none |
| count h | | the count |
| read node, offset, n, dst | n bytes of the node's data to the slot at dst | 0 / 255 |
| write node, offset, n, src | n bytes from the slot at src into the node's data | 0 / 255 |
| search h, offset, value / sort h, offset | as List's | the node / 0 |

Op numbers, the block layout (CybSys's 64-byte block: op, slot, then words), and the answers
follow the existing ops' shape (the store's 12-14, the ports' 28-33).

## 5. The slot's side: no program changes

CybSys (NTC's cyborgos class) gets the List calls exactly as NTC's List has them - Create, Append,
Prepend, InsertAfter, Delete, First, Last, NextOf, PrevOf, Count, GetWord, GetByte, SetWord,
SetByte, Data, Search, Sort, Destroy - each a C0 op; handles Longs. A program written against
List reads the same in a slot and on a CPC.

Existing applications are not broken: they deal in handles and never in addresses, so a program
using List today (nodes in its own 64K) keeps building and running as it does, and one that
wants the hypervisor's heap uses the same calls through CybSys. Data(node) - a far pointer into
the node - has no meaning for a node outside the slot: in the slot class it gives 0, and
GetWord / SetWord and read / write are the way to the data. Programs that use Data() on
in-slot lists are unaffected.

Bml.cls (YING, YANG, MON) can move its page lines from the store to a list, or stay on the store:
either works, nothing forces it.

## 6. The kernel

- Passes the new ops to C0 as it passes the store's (KOp into Hyp.Svc's page).
- **A program's end, KILL, RESET** (EndTask, ResetSlot): walk the system list for slot n's
  entries, free every node and the entries - beside FilesShut and StoreFree.
- **DUMP / RMOVE / RCOPY**: after the slot's bank and the store's blocks, each of the slot's
  lists: its id, node size, count, then the nodes' data in order. **REVIVE / SLOTD**: the lists
  made again under the same ids. (This also closes the open buglist entry "a moved slot loses
  its store": the store's blocks go in the same file.)

## 7. C0

- The system list and the per-slot list tables in C0's own memory (main RAM on the CPC, the
  Next and the MSX; the host program on the vCPC), nodes in the heap's D pages.
- The same code on the CPC, the Next and the MSX (Main.bas's op dispatch, Hyp.Svc for the
  copies); the vCPC answers the ops in vcpc.c over its banks.
- MEM's map shows list pages as D (CyborgOS's), as the hypervisor's heap already shows.

## 8. What else this touches

- **Both stay.** The store is kept as it is - its 32-byte table at #FF00 in the slot's bank, its
  512K, its ops 12-14 - and the lists are added beside it. (Where the table came from: the store
  arrived with MON on 2026-10-14 when C0's RAM build had about 2.4K left - done.md - and the table
  went where there was room; a byte a page there means pages 256 and 257 on a 4 MB CPC can't be
  in a store. Left as it is; moving it into the hypervisor is a separate, optional change.) The
  system RAT (NTC's page type table, C0's, 1 byte a page sized to the probe: 15 bytes on 128K,
  51 on 320K, 771 on 4 MB) is unchanged and was never in a slot.
- **The lists are the hypervisor's.** Every list is created, held and freed by the hypervisor
  under a handle of its own; the slot only ever holds that handle. That is what lets the
  hypervisor allocate a list's nodes anywhere across the 4 MB, and free, KILL, RESET, DUMP, RMOVE
  and REVIVE them by walking its own records - the slot is never asked and never trusted with an
  address.
- PRIMAL's two heaps are also two bank-number spaces (256 banks for the system, 256 for
  applications: 8 MB when hardware decodes past the CPC's 8 ports). NTC's page numbers are
  16-bit already, so CyborgOS keeps one flat page space; the two lists are for ownership, not
  addressing.

## 8a. For later: compaction

Because every list and node is reached through a hypervisor handle and never by address, the
hypervisor can move nodes. If the heap runs out through fragmentation - free bytes scattered
through pages none of which has room for a node - it can compact: move the live nodes of a page
together (or into another page), fix its own id-to-address records, and free the page. No handle
changes, so no program notices. A native List can't do this (its handles are addresses); this one
can, which is a reason for the handles beyond dumps and moves. The map that makes it possible
(node number -> place, 9.2) is in the first build; compacting is the later step that uses it.
When: on a "no room" with free bytes still above a threshold, or on a MEM COMPACT.

## 8b. For later: dump to make room

Beyond compaction: when the heap is full and can't be compacted enough, the hypervisor can make
room by dumping a slot - its bank, its store, its lists - to disc (DUMP, which exists) and
freeing all of it. Nothing is lost: the user revives it later (REVIVE, which exists) and the
program goes on where it was, lists and all, since the handles come back under the same ids.
Which slot: the user's choice (a prompt naming the slots and what each holds), or a rule (the
one paused longest, the one holding most). That is what the id handles and the hypervisor's
ownership buy: memory pressure becomes "swap a program out", not "a program fails". Not in the
first build; the DUMP / REVIVE of lists (section 6) is what makes it possible.

## 9. How to build it

The pieces, where each goes, and in what order. The names in brackets are the files as they are.

### 9.1 Where the list logic lives: the kernel, with C0's pages

Not in C0's main RAM: on the CPC it is nearly full (CYBORGOS.BIN's arrays end #A2CD under a top
of #A5EF). Not in the service page as Z80 unless it has to be. The kernel (KERNEL.bas, its own
64K bank, about 40K free) already sees every BDOS 131 op a slot makes (its Sys function) and
already owns the slots' lifecycle (EndTask, ResetSlot, the DUMP / REVIVE ops) - so the lists'
bookkeeping goes there, in NTC BASIC, and C0 supplies the two things the kernel can't do itself:
pages, and copies into them. The kernel is slot 0 to C0; it talks to C0 with KOp (its block at KB,
#EE00 in its bank: the op, up to 4 words, 224 bytes of data either way).

**C0 adds (Main.bas's Case list; the next free KOp numbers):**
- **page alloc / free for the kernel**: a free page of TypeUser (as StoreSize takes them), the
  page number back (0 none); free a page. Two ops, or one with a direction. The system RAT is
  C0's; the kernel never sees it.
- **a far copy**: n bytes (2K at most) between page p at offset o and slot t's memory at address
  a (t = 0: the kernel's own bank), either way. Hyp.Svc's sv_store already does this for store
  pages through its page-switch helper (sv_dx / sv_pgset): generalise it to a page number given in
  the block instead of one looked up at #FF00. On the vCPC the same two ops in vcpc.c over its
  banks (memcpy).
That is all C0 needs: it stays the page owner, the kernel the list owner.

### 9.2 The kernel's data

Section 2's shape and nothing else: one heap, shared; lists as the hypervisor's records; no
fixed tables, no ceilings. The kernel keeps only heads in its bank.

- **the heap** is the free pool - pages taken from C0 (page alloc) as needed and given back when
  empty. Nodes of every list, every slot's and the hypervisor's own, are cut from the same pages:
  a page is nobody's, it holds whatever nodes were made while it had room (NTC's Memory.Alloc
  shape: blocks cut into nodes, a free chain, nothing fragments by itself). Which page a node
  landed in is the hypervisor's business alone.
- **the system list** is the hypervisor's own list (owner: slot 0): a node a list in existence -
  the owning slot, the list's id, its node size, its node count, the head of its node map. A slot
  makes as many lists as its share allows; the quota is the only limit.
- **a list's node map** is what a node handle indexes: node number -> the node's place (a far
  pointer, 4 bytes). It lives in the heap like everything else (a list of map pages, or one page
  of 4096 places - either, never a kernel array). Numbers are given out from 1 and reused from a
  free chain. This map is what makes a handle not an address: a revive rebuilds the map, a
  compaction rewrites it, the program's handles stay.
- **a node** in a page: its data (the list's node size) plus next and previous as node numbers
  (words), so a walk is a map lookup a step.
- **per-slot quota**: pages the slot's nodes and store occupy, against the share C0 reports at
  boot (MEMINFO's free pages \ slots, or a fixed cap); "no room" at the share.

### 9.3 An op, end to end

`List.Append h` in a slot program (the stub, 9.5) puts op, h in CybSys's block and calls BDOS
131. C0's Serve hands it to the kernel's Sys as it does every 131 op. Sys, for a list op: finds
the list's node on the system list (the id in h, owned by this slot - else 255); takes a node
from the heap (a free node of that size in any page the heap has, or a fresh page from C0 when
none has room); gives it the next free number in the list's map and writes its place there;
links it (next / previous numbers, a far copy of 4 bytes each way); answers the number in the
block. `List.SetWord node, offset, value`: the map gives the place, one far copy of 2 bytes from
the slot's block into the page. `GetWord` the reverse. `First / Last / NextOf / PrevOf`: the
links read with a far copy, answered as numbers. `Delete`: unlink, the node back to the heap's
free chain, its number back to the map's. `Destroy`: every node of the list freed, its map
freed, its system-list node removed; a page with no nodes left goes back to C0. `Count`: the
list's node. `Search` and `Sort`: the kernel walking the nodes - slower, and fine.

Each op is one far call from the slot plus a map lookup and one or two far copies: a few hundred
T. The copy of a node's data is 2K at most per call; a node's data can be bigger than 2K only by
two calls.

### 9.4 The kernel's lifecycle paths

- **EndTask / ResetSlot** (a program ending, KILL, RESET): every system-list node owned by the
  slot - its list's nodes back to the heap, its map freed, the node removed. Beside FilesShut and
  StoreFree.
- **DUMP** (DUMP.bas, the kernel's op 3 / SlotFrame): after the slot's bank, the store's blocks
  (op 14 each), then each of the slot's lists: its id, node size and count, then its nodes walked
  in list order - each node's number and data - through the far copy into the dumping slot's
  buffer and out to the file. **REVIVE**: the lists made again under the same ids, each node made
  again under its own number (the map built so the numbers match), wherever the heap puts them
  now. Handles in the revived program's variables are numbers, so they still point right.
  **RMOVE / RCOPY / SLOTD**: the same bytes over the link, the same rebuild.
- The hypervisor's own lists (slot 0) are never freed by a slot's end and never dumped.

### 9.5 The stub in the slot: COSList.cls

A new class, **COSList.cls** (Julian, 2026-11-03: CyborgOS's List - the same shape as List.cls
conceptually, a different name), in NTC's src/lib/cyborgos/ beside CybSys.cls and System.cls,
with List's calls exactly (Create, Append, Prepend, InsertAfter, Delete, First, Last, NextOf,
PrevOf, Count, GetWord, GetByte, SetWord, SetByte, Search, Sort, Destroy; Data gives 0). Each is
CybSys.Ask with the op and the arguments in the block (a handle is two words; a value a word) and
the answer read back. No allocator, no Memory. List.cls stays as it is: a program picks `List`
(its own, in its 64K) or `COSList` (the hypervisor's, across the pool). A program written to List's
calls through GetWord / SetWord only - never Data() or an address - moves to COSList by the name
alone (ALYSSA2's DBMS is written that way). test/gen.js packs it; CyborgOS's builder gets it with
its NTC copy.

### 9.6 The ops' numbers and block

BDOS 131 ops 48-62 (free: 0-19, 20-27 the network, 28-36 the ports, 37 SLOT, 38 LANG, 40 the
vCPC's float, 42 the stubs' points are taken). CybSys's block: byte 0 the op, byte 1 the slot
(the kernel fills it), words from 2: the list handle (2, 4), a node handle (6, 8), offset (10),
value or n (12), the slot address for a copy (14); the answer in A and the handle back in the
same words. Keep the shape of the store's ops.

### 9.7 The vCPC

vcpc.c answers the two C0 ops (page alloc / free from its 64 banks, far copy by memcpy); the
kernel is the same KERNEL.CYB on every machine, so nothing else changes there. The CPC, the Next
and the MSX share Main.bas's Case code and Hyp.Svc's copy.

### 9.8 Order of work

1. C0's two ops (page alloc / free, far copy) on the CPC harness; a scratch test that reads a
   page back. Then the vCPC's.
2. The kernel's tables and the create / append / get / set / next / destroy ops; the stub
   List.cls; a slot program on the CPC harness appending past 64K and summing. cosregress test.
3. EndTask / ResetSlot freeing; MEM's free pages back. The quota.
4. Delete, Prepend, InsertAfter, Last, PrevOf, Count, Search, Sort.
5. DUMP / REVIVE with lists and the store; RMOVE / RCOPY / SLOTD.
6. The vCPC suite; the MSX suite; the Next by hand.
7. Docs: cyborgos-memory-model.md section 3.2 from "to build" to what it is; the user guide;
   HELP's pages; ANALYSIS.LOG every turn with the files.

## 10. Tests

- A slot that appends until "no room": stops at its quota, with free pages still there; another
  slot can still create and append; MEM's totals right throughout.

- A slot program that creates a list, appends more nodes than fit in 64K, walks and sums them,
  deletes some, destroys the list: on the CPC harness (cosregress) and the vCPC (vcpctest).
- KILL and RESET with lists open: MEM's free pages back to what they were.
- DUMP, REVIVE, RMOVE of a slot holding a list and a store: the data the same after.
- Two slots with lists at once, and a hypervisor list beside them.

## 11. Settled since (Julian with the other session, 2026-11-02; its tree was lost, these lines are what came back)

- Two top lists: the kernel list (the hypervisor's own) and the slot list. Each is two levels and
  only two: the top list's nodes are lists, their nodes are the records.
- A list handle is its node on the slot list.
- A dozen-node lookup is what an op costs on the hypervisor's side.
- A hypervisor list that is too slow through the ops goes direct (the kernel's own code walks it).
- The first build measured 185 ms an append (every op is a BDOS 131 call and a kernel pass in
  BASIC: thousands of T, right for indexes and records, wrong for a per-frame walk).
- The first build's lost tree had: C0 ops 41 PAGE / 42 COPY (PageTake / PageFree / PageCopy in
  KERNEL.bas), the kernel engine (HeapTake, records with ids on the slot list and the kernel list,
  one map page a list, ListCreate / Add / Delete / Data / Destroy, ListsFree from EndTask and
  ResetSlot, ListOp ops 48-63 with the slot block copied whole each way, an LFind cache), Hyp.cls
  routing 131 ops 48-63 to the kernel (sub 48 / cp 16 / jr c), the stub, LSTTEST (apps/lsttest,
  built to tools/regress/extra, the cosregress test 'lsttest' at 120 s, not in the system layout),
  vcpc.c cases 41 and 42 (pages as bank quarters). Bugs it met: the route's 0-9 rule, the handle-0
  case, lb / ob name clashes, the t/ex folder.

## 12. Built (2026-11-04)

Steps 1-4 and the ops of 9.8 are built and tested; dump / move (step 5) is coded on the lifecycle
paths and to do under test.

- **C0 (all four): PAGE and COPY.** KOp 43 PAGE (a free TypeUser page for the kernel's heap, or one
  back), KOp 44 / 45 COPY (a page <-> a slot / the kernel, 1K at most a call). Main.bas Case 43-45
  on the CPC, the Next and the MSX (Memory.AllocPage, Memory.Copy over Hyp.FarPtr); vcpc.c on the
  vCPC (pages are 16K quarters of free banks, memcpy; MEM shows them D). The route (Hyp.cls page
  zero, Main.bas, vcpc.c) sends 131 ops 48-63 to the kernel.
- **The kernel: the list engine** (KERNEL.bas, ~300 lines): the heap page table (lpg/lps/lpf/lpu/
  lpb), the system list (list 0, held as -1) of records, each list's node map (number -> place),
  LFetch / LSave / LNew / LCut / LLink / LUnlink / LDrop / LDestroy / LPlace, ListsFree from EndTask
  and ResetSlot, ListOp (ops 48-63). A handle is a Long: the list number in the high word, the node
  number in the low. The quota (the pool's free pages / the slots at the first Create, 32K least) is
  checked on append.
- **The slot: COSList.cls** (NTC lib/cyborgos): List's calls over BDOS 131; Data() gives 0.
- **Tests.** LSTTEST (apps/lsttest, built to build/extra and disc 8, not shipped): create, append
  past 64K, walk and sum, the k-th node, Search, Delete, Sort, Destroy. cosregress 'lsttest' (60
  nodes at 4 MB, the CPC harness); vcpctest 'lists' (3000 nodes, 18K of data, past the TPA); no leak
  over repeated runs (EndTask frees). The vCPC runs 3000 in a second; the emulated CPC is far slower
  (each op is a BDOS pass in BASIC), so its reference is small - capacity is the vCPC's test.
- Two bugs met and fixed while building: Memory.Copy is Copy(source, dest, n) - the CPC COPY had
  the two reversed, so the map round-trip read 0 (the vCPC's explicit memcpy was right, so only the
  CPC failed); and LFetch's "already in hand" cache matched spuriously when both the asked handle
  and the held one were 0 at boot, so list 0 was never loaded - list 0 is now held as -1.

To do: DUMP / REVIVE and RMOVE with the lists under test (the code is on the paths); the MSX and the
Next by hand; Search / Sort are the kernel walking the nodes (slow, fine). cyborgos-memory-model.md
3.2 moved from "to build" to built.

