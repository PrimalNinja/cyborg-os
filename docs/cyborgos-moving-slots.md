# Moving live programs between machines

CyborgOS can pick up a program that is running in a slot - with everything it
has in memory, exactly where it is - and send it to another CyborgOS machine
across the network, where it carries on from the same point. A CPC, a ZX
Spectrum Next, an MSX, and a vCPC (a "Headless Horseman" node on a PC or a Pi)
are all the same kind of machine to CyborgOS, so a program can travel between
any of them.

There are two commands for sending, and one for the machine that receives.

| Command | What it does |
|---|---|
| `RMOVE` *slot* *address* | the program **moves**: it carries on there, and is closed here |
| `RCOPY` *slot* *address* | the program is **copied**: it carries on there **and** here - two copies from that moment |
| `RCOPY` *NAME.CYB* *address* | a program **file** is sent, to run fresh on the other machine |
| `SLOTD` | the receiving end: it waits for programs sent to this machine and runs them |

Nothing listens on the network unless you start `SLOTD`. When you stop it,
the machine stops listening again.

---

## What you need

- **Two CyborgOS machines on the same network.** Two real machines, a real one
  and a PC running a vCPC, or two vCPCs on one PC - any mix.
- **The network turned on** on each machine:
  - a CPC with an M4 board: `NET M4`
  - a ZX Spectrum Next: `NET ESP`
  - a vCPC: its network is the host's, always on.
- **The address of the receiving machine.** On a home network this is something
  like `192.168.1.20`. `IPCONFIG` on a machine shows its own address. Two vCPCs
  on one PC use `127.0.0.1` (the PC itself).

Receiving is not built for the Next or the MSX yet - they can send, but only a
CPC or a vCPC can run `SLOTD` and receive. Any machine can send.

---

## Tutorial 1 - move a running program to another machine

Say you are running something in slot 2 - a game, YING, the MON monitor - and
you want to carry on with it on another machine.

**On the machine that will receive (we will call it the far machine):**

```
NET M4            (a CPC; on a vCPC the network is already on)
SLOTD
```

`SLOTD` prints that it is listening, and stays in its slot waiting. Leave it
running. Note the far machine's address with `IPCONFIG` if you don't know it.

**On your machine:**

```
RMOVE 2 192.168.1.20
```

That is all. Slot 2's program is paused for a moment while it is sent, then:

- on your machine, slot 2's program is gone (its command line comes back), and
  `RMOVE` says `slot 2 moved to 192.168.1.20, slot 4` (whichever slot it landed
  in there);
- on the far machine, the program is now in a slot, carrying on from exactly
  where it was. `SLOTD` prints `MON.CYB into slot 4` (or whatever it was).

Bring it to the front there with `FG 4` and it is as if it had always been
running on that machine.

If anything goes wrong - the far machine isn't listening, the network is down -
`RMOVE` says so and your program simply carries on where it is. Nothing is lost.

---

## Tutorial 2 - copy instead of move

`RCOPY` is the same, but your program keeps running on your machine too:

```
RCOPY 2 192.168.1.20
```

Now the program runs in two places at once, each going its own way from the
moment you copied it. This is handy for running the same thing on several
machines, or for sending a copy to try elsewhere without giving up your own.

---

## Tutorial 3 - send a program file to run fresh

If you have just built a new version of a game and want to try it on the other
machine, send the file itself. It runs there from the start, as if you had typed
its name:

```
RCOPY MYGAME.CYB 192.168.1.20
```

The far machine's `SLOTD` saves it and runs it in a slot. Because it is a plain
program starting fresh (not a running slot with its memory), this works between
any machines, even different kinds - a program file sent from a CPC runs on a
vCPC and the other way round.

---

## Deciding which slots can be used, and who may send

Start `SLOTD` with a list of slots, and only those are used:

```
SLOTD 4,5,6
```

Add a word and only a sender that gives the same word is let in:

```
SLOTD 4,5,6 SECRET
```

Then send with the word on the end:

```
RMOVE 2 192.168.1.20 SECRET
```

The word is a simple permission for your own machines - it is **not** encryption,
so don't treat it as protecting anything over an untrusted network.

To put a program into one particular slot there, replacing whatever is in it,
add `-o` and the slot number:

```
RCOPY MUSIC.CYB 192.168.1.20 -o 5
```

That kills slot 5 on the far machine and runs the new program there - useful for
replacing the music on another machine, or sending a game's newest build into
the same slot again and again. `SLOTD` only allows this for the slots it is set
to use.

To stop receiving, press `Q` in `SLOTD`'s slot. The machine stops listening.

---

## Two machines on one PC

You can run two vCPC nodes on one PC and move programs between them. Give each
its own folder for its files, and use `127.0.0.1` as the address:

```
(first node)   build/vcpc --sys CYBORGOS --data node1 --tty
(second node)  build/vcpc --sys CYBORGOS --data node2 --tty
```

Start `SLOTD` on one, and `RMOVE` or `RCOPY` to `127.0.0.1` on the other.

---

## What can and can't be sent

A running program can be sent as long as it isn't holding on to anything the
other machine can't be handed:

- **a file open** - close it first
- **a claimed device** (a port, a socket, a hardware claim) - release it first

`RMOVE` and `RCOPY` check this and tell you what is in the way, rather than
sending a program that would break. A program written to be moved can close its
file, send itself, and reopen it on arrival.

A **moved running slot** only goes between machines of the same build of
CyborgOS, because it is a snapshot of memory that must match on the other side;
`SLOTD` checks this and refuses a mismatch before anything is sent. A **program
file** (`RCOPY NAME.CYB`) has no such limit - it runs fresh, so it goes
anywhere.

---

## Quick reference

```
NET M4 / NET ESP              turn the network on (CPC / Next; vCPC always on)
IPCONFIG                      show this machine's address
SLOTD                         receive into any free slot, from anyone
SLOTD 4,5,6 WORD              receive only into those slots, only with the word
  Q                           (in SLOTD's slot) stop receiving
RMOVE slot address [word] [-o n]    move a running slot to another machine
RCOPY slot address [word] [-o n]    copy it (keeps running here too)
RCOPY NAME.CYB address [word] [-o n]   send a program file to run fresh there
```
