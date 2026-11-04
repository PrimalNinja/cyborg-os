# CyborgOS: the generative model (GEN, MIND, GRU) and where it goes

A small generative neural net that runs on the Z80, served on a port, with a terminal to talk to
it - and a design for growing it past what one slot holds. Built 2026-11-04.

## 1. The model

A character-level **ternary GRU**: a 2-layer gated recurrent net whose weights are **k balanced
trits** each (k=1 is plain -1/0/1; the shipped models use **k=2**, nine levels -4..+4, stored as two
trit planes), activations 8-bit integers in `Tiny`'s units (1.0 = 64). It predicts the next
character from the ones so far. The shipped `GEN.MDL` and `CYNTHIA.MDL` are 64 hidden, 32 embedding,
2 layers, 97 classes (printable ASCII, newline, form feed), ~49k weights a plane, ~29.5K on disc
(under the 32K a slot loads). 2 trits a weight was the fix for spelling: at 1 trit the net learned
the shape of a keyword but dropped letters (`Froo` for `For`); 9 levels let the right character win
its argmax, so `For i = 1 To 10` / `Print i` / `Next` come out clean.

Multi-trit weights stay **multiply-free** on the Z80: a weight is k trit planes, and the dot splits
`Σ xᵢwᵢ = Dot(plane₀,x) + 3·Dot(plane₁,x) + 9·Dot(plane₂,x) + …`, each `Dot` the plain ternary
add/sub (`Trit.Dot`), Horner-combined in `Net.DotK` (the only arithmetic is the ×3 on the running
sum). So k=2 is two ternary passes, k=4 would be four (81 levels, 1 byte, still no multiply), k=8
two bytes. `test/net_t` proves the k=2 Z80 path is byte-identical to the PC reference.

It is trained on a PC (`ntc/tools/gen`: `corpus.py`/`gen_focus.py`, `train.py`, `qgru.py`) and run
on the Z80 by `Net.cls`. The training forward pass **is** the Z80's integer arithmetic - every
shift, saturation and table lookup the same - so the exported model gives the same characters on
the PC and the CPC, byte for byte. `test/net_t` proves it (a small model, 48 characters, Z80 ==
PC reference). `tools/gen/sample.py` reads a `.MDL` back and generates on the PC with that same
arithmetic, so you can see on a PC exactly what the CPC/vCPC will write at noise 0.

It is a **completer, not a chatbot**: it carries on from what it is given. A 100K-weight net cannot
hold a large, varied corpus (on 4MB of mixed source it collapses to predicting spaces under greedy
decode); it is trained instead on a focused corpus it can learn, or sampled with noise. The real
answer to "make it good" is a bigger model - see section 4.

Speed: about a second a character on a 4 MHz CPC; the vCPC (a Pi) does it ~100x faster.

## 2. The three programs

The split follows the decision services (`MODEL` serves a model on a port, `RAT` decides, `RATS`/
`RATBOX` are fronts):

- **GEN** - the standalone completer. Loads `GEN.MDL`, reads a file as the start, writes on. No
  ports; the whole thing in one slot.
- **MIND** - the model served on a port. `RUN 2 MIND GEN` loads `GEN.MDL` and opens the port `GEN`.
  The net and its hidden state live in MIND's slot; clients hold nothing.
- **GRU** - the terminal for a MIND. `GRU GEN` talks to the port, a character at a time, keeping
  the conversation going across turns because the state is on the server.

"The model is a port." A MIND can be kept while clients come and go, moved between machines with
`RMOVE`/`RCOPY`, or shared. The size of the model is the server's concern; `GRU` never changes.

## 3. The port protocol (BDOS/port messages, ASCII codes throughout)

MIND answers these on its port; the client never sees the model's own class numbers, only character
codes:

| message | does | reply |
|---|---|---|
| `?` | - | `vocab hidden layers` |
| `R` | clear the state (a new text) | `ok` |
| `S n` | set the noise seed | `ok` |
| `F c` | feed character code `c`, no noise | the code it expects next |
| `G c amp` | feed `c` with +/- `amp` (0-20) of noise | the next code |

Code 10 is newline, 12 the end of a program (GRU stops a turn on it). GRU feeds what you type with
`F` (deterministic - it is yours), then carries on with `G` (noise for variety), printing each code
and feeding it back.

A second model, **Cynthia** (`CYNTHIA.MDL`), is a chitchat "ELIZA killer" trained on short
exchanges - served and talked to the same way (`RUN 2 MIND CYNTHIA`, `GRU CYNTHIA`). Any `NAME.MDL`
trained with `tools/gen` serves as `MIND NAME`.

## 4. Where it goes: bigger models over more ports

The model that fits in one slot (~29.5K) is small. The architecture is built to grow, and the rungs
are concrete.

**Done - weight precision (k trits a weight).** `Net` reads k balanced-trit weights (k planes,
`DotK` Horner-combines them, still add/sub only - section 1). The shipped models use k=2 (9 levels);
k=4 (81 levels, a byte, still multiply-free) and k=8 (two bytes) are a training flag away and need
no Z80 change. The table-lookup inner loop (a (trit-group x input) product table, ~k/4 lookups a
weight instead of k add/sub passes) is the speed optimisation on top - identical results, not yet
built. This is the precision half of making a small model spell; the width half is rung 1.

**Rung 1 - a store-backed MIND (one port, up to 512K).** Today `Net` holds the weights as a flat
array in the slot and caps at 128 hidden / 128 classes. The store (the REU-like 512K a slot can
claim) holds ~2 million ternary weights at 4 a byte - ~20x the current model. The work: lift the
`MAXH`/`MAXV` caps and give `Net` a store-backed weight reader (window 16K in, dot that chunk, next
window). The weight layout is already row-contiguous and pack-friendly. Weights go as H^2, so 20x
the budget is ~4-5x wider (H ~96 -> ~400), not 20x. Compute is linear in weights: ~20 s/character on
a real CPC, sub-second on the vCPC. **This is on-fleet work - no new training needed to prove the
plumbing.**

**Rung 2 - 4 ports, up to 2MB.** Two forms:

- *Sharded one model* - one 2MB model split across 4 MINDs, the forward pass running through all
  four. Pure storage split, no new training, but every port runs every character (sequential, ~4x
  slower): the "all visible" case.
- *Mixture of experts (4 experts + a gate)* - the "not all visible" case. The gate picks one
  expert per character; only that expert runs, so 4x the parameters at ~1x the compute. The
  asymmetry that makes it work: the weights (<=512K each) stay behind each port and never all need
  to be visible; the only thing that crosses a port is the recurrent hidden state, which is tiny (H
  bytes). The router owns the state, ships `(state, char)` to the chosen expert, gets `(state,
  logits)` back.

What each needs honestly: the 4-port **serving** fabric and an **async scatter/gather** on ports
(today's `PortCall` is one call at a time - fan-out needs several in flight) is on-fleet work. A
trained 2MB MoE (experts + gate trained jointly, top-k selection, straight-through routing) is
**off-fleet** - it is trained on a GPU box, and the vCPC fleet serves it. For MoE, MIND also needs
one protocol change: it currently keeps its own hidden state internally (right for one model), but
a routed expert must accept an injected state and return it, since the router owns the canonical
state.

**Beyond that (design, not built).** The same mechanism runs N times: 1000 ports across online
vCPCs = ~512MB of parameters, with per-character compute still that of one expert under top-1
routing. The limits are latency (a network hop per character unless routing is sticky; a flat gate
wants to become a tree of router ports) and training (done off-fleet; the Z80s serve, they do not
learn). Parallelism helps *width* (top-k experts fired at once - k becomes free given the machines;
ensembles; many streams) but not the token axis of a single stream (character N+1 needs N), except
speculative decoding (a small drafter + a big verifier). And a coarser pattern on top: N nodes each
produce a whole candidate answer in parallel, then **fan in to a decision** - a judge MIND, `RAT`
scoring measured features, or, uniquely here, **executing the candidates** (a vCPC can compile and
run a generated NTC BASIC program and keep the ones that work). GEN proposes, the OS runs, RAT
decides: the three pieces compose into a self-checking code generator.

## 5. Tests

- `ntc/test/net_t` - Net inference on the CPC (Z80 == PC reference, 48 characters). The CPC
  interpreter harness is ~10 min a character at H=96, so the full-size model is not tested there.
- `vcpctest.sh` `gru` - the full GRU <-> MIND port path at speed on the vCPC: MIND serves GEN, GRU
  feeds a prompt and generates.
- `tools/gen/sample.py` - the PC reference generator, for seeing a model's output and for building
  references.

(c) 2026 Cyborg Unicorn Pty Ltd
