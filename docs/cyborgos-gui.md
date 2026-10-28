# CyborgOS GUI (GUISVC)

A windowed, mouse-driven GUI for CyborgOS, split the way X Windows is:

- **GUI.CYB, the service**: a program in a slot with the port `GUI`. It holds the model (every
  window and control and its value) and draws it while its slot is in front - the local head.
- **Programs**: in other slots; they say what they want through the port and read values back
  (`GuiCli.cls`). They never draw.
- **Heads**: whatever shows the model. The first is GUI's own screen (the CPC's mode 2, the
  Next's tilemap). The second, RGUI, is a browser on another monitor (RVDU's way: through a VDU
  screen): it reads the same model and its clicks are done as if they were made on the machine.

Several GUIs can run at once (each its own port name, later), several programs share one, and
a program's model (RAT, a MODEL) can serve programs in several GUIs: a mini-computer's shape on
a CPC or a Next.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

## Running it

GUI.CYB is built for each machine (the CPC's in `build/gui/cpc`, the Next's in `build/gui/next`:
neither carries the other's code); GUIDEMO.CYB is one file for both.

```
RUN 2 GUI            the service (CPC: MultiPlay port B if one answers, else the SYMBiFACE's
                     mouse if it answers, else the keys; Next: Kempston)
RUN 2 GUI MP2        CPC: MultiPlay port B
RUN 2 GUI SF         CPC: the SYMBiFACE II / III's PS/2 mouse (#FD10)
RUN 2 GUI MP         CPC: MultiPlay port A
RUN 2 GUI AMX        CPC: an AMX-style mouse (or the PS2Mouse adapter) on the joystick port
RUN 2 GUI KEYS       no mouse: the keys only
RUN 2 GUI R=host/vdu CPC: a remote head as well (NET M4 first) - see RGUI below
RUN 3 GUIDEMO        a program with a window
Control + 2          GUI's screen (Caps Shift + 2 on the Next)
```

Without a mouse: **Tab** - or **ESC** (Caps Shift + Space, Break, on the Next, which has no Tab)
- goes to the next control in the front window, **Space / Return** works
it, a text field takes what is typed (Return in it counts as its value), the **cursor keys** move
the pointer, **Copy** clicks. On a slider the cursor keys left and right (or `,` `.` `<` `>`)
move it; in a list, up and down pick the row. **Q** (no control chosen), or clicking "Q quits" in the menu strip,
ends GUI.

With the mouse: click a button, a check box, a field; the title bar brings a window to the front
(drag it to move it). Drag a slider's knob; click a list's row; click a cycle for its next
choice. The box at a window's left is the close gadget (the program decides: GUIDEMO
ends), the one at its right sends the window to the back.

## Values, not events

Like RAT's callers, a program reads **states**: a button's value is how many times it was
clicked, a check box's 0 / 1, a field's its text (and how many times Return was pressed in it).
A busy program loses nothing: it asks `Q` - the ids the user changed since its last `Q` - and
reads those it cares about.

## The port's messages

128 characters at most. Positions and sizes in cells (8 x 8 pixels: 80 x 25 on the CPC's
screen); a control's x, y are from its window's inside (under the title bar).

| Message | What | Answer |
|---|---|---|
| `W x y w h title` | a window (`h` rows, the title bar one of them) | its id |
| `B win x y text` | a button | id - value: clicks |
| `C win x y text` | a check box | id - value: 0 / 1 |
| `L win x y text` | a label | id |
| `T win x y w text` | a text field | id - text: its text, value: Returns |
| `G win x y w n` | a gauge, 0-100 | id |
| `R win x y a\|b\|c` | a cycle: one choice shown, a click the next | id - value: the choice (0 ...) |
| `P win x y w max n` | a slider | id - value: 0-max |
| `V win x y w h` | a list, `h` rows | id - value: the row picked (-1 none), text: its item |
| `I list text` | an item at the list's end | its id |
| `S id text` | its text set | 0 |
| `V id n` | its value set (`V` on a control's id; on a window's id it makes a list) | 0 |
| `? id` | its state | `value text` |
| `Q` | the ids of the caller's objects the user changed since its last `Q` | `3 7 9` / "" |
| `X id` | a window closed with what is in it, or one control | 0 |

`S` or `V` with what the object already has does nothing (nothing drawn, nothing sent to a
remote head), so a program can set its state every time round its loop. `?` is the answer to
anything it didn't understand. A window's own value turns 1 when its close
gadget is clicked. An object belongs to the slot that made it; when that slot's program has
gone, GUI takes its windows away (it looks every 2 seconds).

`GuiCli.cls` wraps it: `Win`, `Button`, `Check`, `Label`, `Field`, `Gauge`, `Cycle`, `Slider`,
`List`, `AddItem`, `SetText`, `SetVal`, `Value`, `Text`, `Changed`, `Remove`, `Ok`.

## The CPC's head (cpc/GuiScr.cls)

Mode 2, 640 x 200 in green-screen colours (green paper, pastel green ink: a slot's own colours -
CINK, #F6E5-#F6E7 in its bank - which CyborgOS sets while it is in front and puts back for the
next slot; GUI sets them, and clears them when it ends; a slot with its own colours also has no
console cursor flashing on its screen), drawn straight into main RAM's #C000
screen while GUI's slot is in front - BOUNCE's way (its README, part 4): RAM setting C3 puts the #C000 screen
at #4000 and keeps the slot's own page 7 at #C000, so the drawing routines are copied to #E000
(under the stub) and draw through the #4000 window, no stack and interrupts off while C3 is in
(GUI is an Option Turbo program; it gives the CPU away in every port call).

Every drawing call is a rectangle of bytes changed as `(byte AND m) OR p` (a value for the even
lines, one for the odd: the title bar's stripes), a line of text from the slot's font (#F300),
or the pointer XORed. A plain fill (the desktop, a window's inside) is an LDIR a line. About 41 T a byte: a window of 40 cells by 10 rows is 3200 bytes, 33 ms;
a character about 400 T. Only what changed is drawn again: a control (a click, a new value), a
window (brought to the front), everything (a window moved, closed or sent back).

Coming to the front GUI sets its console to MODE 2 (as BOUNCE does) and draws it all; behind, it
draws nothing - CyborgOS puts the CRTC and #C000 back for the slot it brings to the front.

## The Next's head (zxn/GuiScr.cls)

The same calls draw into a picture laid out as the CPC's screen (640 x 200, a bit a pixel) at
#8000 in GUI's own memory; after each call the cells it touched become tiles of the Next's
tilemap - which is what the Next's console already is (80 x 32 cells of 8 x 8, a bit a pixel).
A cell's 8 bytes are its tile: found in a cache of the 256 tiles (a hash table) or made a new
one; a GUI screen has a few dozen different cells (GUIDEMO's: 55). Full: the cache cleared and
everything drawn again. The tilemap and its tiles are GUI's own while it is in front, in bank
5's first page (the ULA's - the ULA is off meanwhile), reached through MMU slot 6 for a moment;
the console's stay where they are (so its cursor doesn't show), and its registers go back when
another slot comes to the front. The colours: the tilemap's 0 and 1 set to greens (#0C, #9E)
while GUI is in front, the console's back on Leave. The pointer is hardware sprite 0; the mouse the Kempston
(#FBDF, #FFDF, #FADF). The picture's 25 rows are the tilemap's rows 4-28.

## RGUI, the remote head (CPC)

`RUN 2 GUI R=192.168.1.10/vdu` (after `NET M4`): GUI makes a private screen on that VDU server
(tools/vdu - PHP, no database) and prints the page to open: `http://192.168.1.10/vdu/rgui.html?s=id`.
Open it in any number of browsers, on any monitors: each shows the windows as they are (in the
same greens, at a higher resolution: `&z=1.5` scales it) and works them - a click, a ticked
box, a slider let go, a list's row, a field's Return (or the field left with its text changed), a window's close gadget, its depth gadget,
a title bar dragged. GUI does them as if they were made with the machine's mouse, so the
program sees no difference, and the machine's own screen keeps up too.

Drags are sent when they end, not while they move: a window dragged by its title bar (on the
machine or in a browser) goes out once, at its new place, when the button is let go; a slider
dragged on the machine's screen is drawn there as it moves (the program reads its value as it
goes) and goes to the remote heads once, let go; a browser's slider sends its value let go.

The model goes out as lines on the screen (`a=put`, several in a request, sent at most every
0.2 seconds):

| Line | What |
|---|---|
| `MODE 2` | the start: a browser joining reads from the last one |
| `O id kind parent x y w h value extra text` | an object as it is now (kinds: 1 window, 2 button, 3 check box, 4 label, 5 field, 6 gauge, 7 cycle, 8 slider, 9 list, 10 a list's item) |
| `X id` | gone (with what is in it) |
| `Z id id ...` | the windows' order, back to front |

The browsers' events come back as the screen's events (`a=event`); GUI reads them every second,
and at once when a `put`'s answer shows there are more:

| Event | What |
|---|---|
| `C id` | clicked (a button, a check box, a cycle) |
| `S id n` | a value set (a slider, a list's row) |
| `T id text` | a field's text: Return pressed, or the field left with its text changed |
| `F id` / `K id` | a window to the front / its close gadget |
| `M id x y` | a window moved |

Several machines' GUIs can use one server, each its own screen. The Next's GUI has no remote head
yet: its build leaves the RGUI code out (the Next has the network now - NET ESP - so it can come).

## Building

```
bash src/bas/cyborgos320kb/apps/gui/build.sh <NTC src>    -> build/gui/cpc/GUI.CYB, next/GUI.CYB, GUIDEMO.CYB
bash src/bas/cyborgos320kb/apps/gui/test/cpctest.sh <NTC src> <CyborgOS> <out> "[typed]" [limit]
python3 src/bas/cyborgos320kb/apps/gui/test/shotgui.py <out>.bin <out>.png <NTC src>/test
python3 src/bas/cyborgos320kb/apps/gui/test/zxntest.py <card image> <GUI.CYB> <GUIDEMO.CYB> <out> [steps]
bash src/bas/cyborgos320kb/apps/gui/test/rguitest.sh <NTC src> <CyborgOS> <out folder> [limit] [port]
```

`tools/sdinstall/dist.sh` puts the Next's GUI.CYB and GUIDEMO.CYB in the card's CYBORGOS folder.


The test boots the CPC's CyborgOS in NTC's harness (4MB, the MultiPlay mouse on port B), runs
GUI and GUIDEMO, brings GUI to the front, types what it's given (`{mdx,dy,b}` a mouse move and
its buttons) and writes the screen as a picture (shotgui.py draws the harness's one-byte
characters with a real font). zxntest.py does the same on the Next in ZEsarUX (Break and Space
for the controls; the pictures read GUI's tilemap and tiles).

Tested: CPC (the harness, 4MB) - the window drawn, the mouse moved, Feed clicked, TV ticked, the
name field clicked and typed into ("RexBo"), GUIDEMO answering in its label. Next (ZEsarUX) -
the same window, Break to Feed, Space: "Rex eats. Fed 1 times."; away to slot 1 (the console
back) and to GUI again. CPC, the new controls: the greens, a list's row picked, a cycle clicked,
a slider dragged to its end. RGUI (rguitest.sh: the harness's M4 with real sockets, vdu.php on
this machine, headless Chromium on rgui.html): GUIDEMO's window drawn in the browser; Feed
clicked there - GUIDEMO answers "Rex eats. Fed 1 times."; a name typed there - "Hello, Rover.";
the food gauge running down as GUIDEMO sets it. Not on real hardware yet.

## Not yet

- The AMX-style mouse is untested (the harness has none). The Next's Kempston mouse is read but
  untested (ZEsarUX's can't be driven from the test).
- Several GUIs (ports GUI1, GUI2 ...); the per-head focus for several users; RGUI on the Next.
- More controls: a canvas, the menu strip's own items; a list longer than its rows scrolls only
  with the keys.
- Notifications instead of `Q` polling (the CYB header's handler).
