# CyborgOS tests

Node scripts. They test what the build made (`build/`), so build first (`cosbuild.html`, or
`node tools/cosbuild/src/cli.js build`).

| Script | What it does | Needs |
|---|---|---|
| `tools/regress/cosregress.js [--ram=576] [--ref] [--only=a,b] [--keep=DIR]` | The CPC set: `build/dsk/cos-disk1..n.dsk` installed as INSTALL.BAS lays it out, booted in NTC's CPC harness, 40 tests (a boot and a few commands each: DIR, PS, MEM, HELP, RAMDISC, RUN / KILL, RATS, NET ..., the network through the harness's M4 against `cosweb.js`, the browsers' requests). Each screen compared with `ref/<test>.txt`; `--ref` writes them anew (look at them first). | python3 with the z80 module, NTC (`NTC_SRC`, default `../ntc/src` beside this folder) |
| `tools/espsim/nettest.js [CARD.img] [--shots=DIR]` | The Next: the card image booted in ZEsarUX with `espsim.py` as its ESP8266 (real sockets behind it), NET ESP, IPCONFIG, NETSTAT, NET SET, NET GET, NET TEST, the failures, NET OFF, YING. Checks what the web server was asked for and the AT commands the ESP got; pictures of the screen to look at. | `ZESARUX=` the zesarux binary (built with `--uartbridge-path`), python3 (espsim.py makes a pseudo-terminal) |
| `tools/regress/nextkeys.js [CARD.img] [--shots=DIR]` | The Next's system keys: the card image booted in ZEsarUX, then Caps Shift + 5-8 (the Next's cursor keys), the cursor keys, Caps Shift + 2 / 9 - none may change the slot; Caps Shift + 0 is TOP, then 2 and 0 pick slots 2 and 10, another key leaves TOP up, Caps Shift + 0 again goes back. The slot in front read from the hypervisor after each step. | `ZESARUX=` the zesarux binary |
| `tools/cosbuild/test/pagetest.js [COS_ROOT] [--shots=DIR]` | The builder page as a user drives it in Chrome: Open the CyborgOS folder, Run, the stage scripts, Run again to done; no page errors. | Playwright with its Chromium, sjasmplus |

`cosweb.js` is the test web server both network tests use (`/echo`, `/moved`, `/big?n=`); `zrcp.js`
ZEsarUX's remote protocol (nettest.js, nextkeys.js).
`cosboot.py` is the one piece in Python: NTC's harness (`src/test/ntcrun.py`) is Python.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License
