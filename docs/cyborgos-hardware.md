# CyborgOS and the hardware - what is supported, what is next, the claim tags

Started 2026-10-27. Julian's hardware: a CPC 6128 with a 4MB expansion (CPC4MB), M4, Net4CPC (W5100S),
X-MASS (IDE), 2 x Albireo, 2 x USIfAC II, 2 x CPC-CPLink (old model, I/O ports), MultiPlay (2 Amiga
mice), LambdaSpeak3 and SpeakAndSID, a sound card, a USB Gotek, UniDOS (Nova as its NVRAM / clock
where fitted), Powergraph (V9990, through AMSDAP). Also a ZX Spectrum Next and the MSX (Sanyo Wavy +
GR8NET). The ports below are from the CPCWiki pages and 1984's sources (its rtc.c, net4cpc.c,
m4.c, v9990.c, usifac.c, ide.c, ch376.c).

## 1. The permission mechanism: claims (there already)

A program that drives hardware itself asks first, by a tag and a unit: `CybSys.Claim(tag, unit)` -
0 it is yours, else the slot that has it (255: the table is full). `Release` gives it back; the claim
goes by itself when the program ends or is killed. `CLAIMS` lists them; `CLAIMS TAKE tag [unit]`
takes one back from the program that has it, and `CybSys.Held(tag, unit)` lets a program that can
lose it (a music player) see that it has, and stop. The table is C0's (BDOS 131 ops 16-19, 16
entries, the service page). FLOPPY already claims `FDC 0`; GREEN claims `IO 0`.

Nothing in it knows any hardware: it is a table of names. Every program that uses the same tag for
the same thing is friendly with every other; a program that doesn't ask can still touch anything (it
is a convention, not a lock - as you said). So the work is not the mechanism, it is:

- **One list of tags** (below), in CybSys.cls's header and HELP CLAIMS, so every program uses the same names.
- **CyborgOS claims what it drives itself**, as "the system" (slot 0 in the table), so a program
  asking for it is told no: the V9990 while the console is on it, the M4 and the Net4CPC while the
  network ops use them, the storage UniDOS drives (IDE, Albireo 0), Nova. Two kinds:
  - **Takeable**: the program gets it with `CLAIMS TAKE` (or asks with Take itself), CyborgOS stops
    using it until the claim ends. The V9990: the console goes back to the CPC's screen and returns
    to the card when the claim is released.
  - **Not takeable**: CyborgOS's files go through them (IDE, Albireo 0 under UniDOS, Nova, M4's
    files). A program banging the IDE under UniDOS's FAT cache breaks the disc. Take answers 255.
- **The programs that bang hardware now claim it**: GUI (the mouse it reads: `MOUSE MP0` ...).

## 2. The tags

Up to 8 characters, the unit 0-255 (which one, when there can be two). The names CybSys.cls
already used are kept: FDC, SOUND, SERIAL, NVRAM, MF2, M4.

| Tag | Unit | Hardware | Ports | CyborgOS uses it |
|---|---|---|---|---|
| FDC | 0 | the disc controller (floppy, Gotek, HxC) | &FA7E, &FB7E-&FB7F | AMSDOS's files; FLOPPY claims it |
| SOUND | 0 | the AY (sound) - also the keyboard's port | &F4xx, &F6xx | C0 reads the keys through it every interrupt: a program writing the AY must do it with interrupts off, or the keys go wrong |
| SOUND | 1, 2 | PlayCity's two YMZ294 | &F884 / &F984, &F888 / &F988 | - |
| CTC | 0 | PlayCity's Z80 CTC (NMI, IM2) | &F880-&F883 | - (an NMI or IM2 left on stops CyborgOS: the claimer must turn it off) |
| V9990 | 0 | Powergraph / GFX9000 | &FF60-&FF6F | the console (takeable) |
| M4 | 0 | the M4 | &FE00, &FC00 + ROM 6 | the files on its SD, the network (not takeable) |
| W5100 | 0 | Net4CPC / Cyboard (and the GR8NET on the MSX) | &FD20-&FD23 | (planned: the network) |
| IDE | 0, 1 | X-MASS / SYMBiFACE II master, slave | &FD06-&FD0F | through UniDOS (not takeable) |
| CH376 | 0, 1 | Albireo &FE80 / &FE40 | &FE80-81, &FE40-41 | 0: through UniDOS (not takeable); 1 free (a USB mouse) |
| SERIAL | 0, 1 | USIfAC II | &FBD0-&FBDF | - |
| SERIAL | 2 | Albireo's SC16C650B | &FEB0-&FEB7 | - |
| SERIAL | 3 | CPC Booster | &FF00-&FF0x | - |
| CPLINK | 0, 1 | CPC-CPLink (old model) | (the card's jumpered ports) | - |
| MOUSE | 0, 1 | MultiPlay port A / B | &F990-&F995 | GUI (to claim it) |
| MOUSE | 2 | SYMBiFACE II PS/2 | &FD10 | GUI (to claim it) |
| MOUSE | 3 | AMX (the joystick lines) | the keyboard's row 9 | GUI (to claim it) |
| RTC | 0 | DS12887 (SYMBiFACE II / Cyboard) | &FD14-&FD15 | (planned: the clock - reading needs no claim, setting does) |
| NVRAM | 0 | Nova's NVRAM + clock | &FE82 (maps 8K over RAM) | not takeable: it maps over #6000-#7FFF, CyborgOS's window |
| SPEECH | 0 | SSA-1 (LambdaSpeak's SSA-1 mode) | &FBEE | - |
| SPEECH | 1 | dk'tronics (LambdaSpeak's DKT mode) | &FBFE | - |
| SID | 0 | SpeakAndSID's SID | (its ports) | - |
| OPL3 | 0 | Willy | &FEBC-&FEBE | - |
| MIDI | 0 | Willy | &FEAC-&FEAD | - |
| DAC | 0 | Amdrum | &FFxx (all of them) | - |
| DAC | 1 | Digiblaster (the printer port) | &EFxx | - |
| PRINTER | 0 | the printer port | &EFxx | - |
| MF2 | 0 | Multiface II's RAM / ROM | &FEE8 / &FEEA | - (maps over #0000-#3FFF: CyborgOS's stubs) |

Clashes the table can't fix (they are in the hardware):
- **Amdrum and AMSDAP**: the Amdrum takes every &FFxx write, the V9990 is at &FF60-&FF6F. An
  Amdrum program's writes go to the V9990 too. Don't have both on, or the console is trashed.
- **Nova and MF2** map over memory CyborgOS uses (the window, the stubs): only C0 may switch them.
- **SOUND 0**: the keyboard and the sound share the AY's port (above).

## 3. What is supported now

| Hardware | CPC | MSX | Next |
|---|---|---|---|
| RAM expansions (dk'tronics, RAM7, CPC4MB to 4MB) | yes: all of it | the mapper (to 2MB) | 2MB |
| Floppy / Gotek | AMSDOS's files; FLOPPY drives the FDC (claims FDC 0) | MSX-DOS 2's drives | - |
| IDE (X-MASS), Albireo, M4's SD | through UniDOS's / the M4 ROM's drives (A-P, folders) | Nextor's | esxDOS (C:) |
| M4 network (TCP, DNS) | NET, IPCONFIG, NETSTAT, Http.cls (BDOS 131 ops 20-27) | - | the ESP (same ops) |
| V9990 | the console (80 x 26) | the console | - |
| Mice | GUI: MultiPlay A / B, SYMBiFACE PS/2, AMX | - | Kempston |
| Everything else in section 2 | a program may drive it (and should claim it) | | |

## 4. The plan, in order

1. **The tag list** in CybSys.cls and HELP CLAIMS; C0 claims as "the system" what it drives
   (V9990 takeable, M4 / IDE / CH376 0 / NVRAM not); GUI claims its mouse. Small: C0 already has
   the table.
2. **The clock**: a TIME command and a kernel call (date and time), from the first that answers:
   - RTC: the DS12887 (&FD15 the register, &FD14 the data; wait for register A bit 7 clear, then
     the seconds to the year).
   - NOVA: page 3 mapped, its last 8 bytes, BCD. C0 only: it maps over the window.
   - M4: C_TIME (&4324), "HH:MM:SS YYYY-MM-DD"; the M4 sets it from NTP itself.
   - NTP over the network (UDP to port 123, 48 bytes) when there's no clock chip: through the
     Net4CPC, or the M4's sockets.
   - MSX: the MSX2's clock through MSX-DOS 2's date and time calls; the Next: NextZXOS's (with an RTC).
   File dates come later (with a filesystem of CyborgOS's own).
3. **Net4CPC**: a W5100S driver behind the network ops 20-27 (4 sockets, TCP and UDP), so NET,
   Http, YING / YANG work without an M4. The same driver serves the MSX's GR8NET (also a W5100):
   one driver, two machines.
   **Listening: optional, off by default** (Julian, 2026-10-27). Today CyborgOS never listens
   (sockets connect out only). Listening becomes possible, so a web server, a BBS or a
   CyborgOS service on the LAN can be written, but nothing listens unless the user turns it on:
   - a setting, off at every start: `NET LISTEN ON` / `NET LISTEN OFF` (the command line or the
     boot's words), shown by NET and NETSTAT;
   - with it off, the listen ops (bind, listen, accept) answer "not allowed" to every program;
   - with it on, a program still claims the port it serves (`PORT 80` as a claim: one
     program a port), and NETSTAT shows who listens on what; the claim goes when the program
     ends, and NET LISTEN OFF closes every listening socket;
   - the hardware has it: the M4's C_NETBIND / C_NETLISTEN / C_NETACCEPT (&4338-&433A), the
     W5100's socket LISTEN, the GR8NET's UNAPI.
   The rest of the stance stays: incoming data is only ever data, nothing is run from it.
4. **Serial** (USIfAC II x 2, Albireo's UART): a serial console in a slot, a terminal, a link to
   another machine. Claimed SERIAL n.
5. **CPC-CPLink: the Pi as a coprocessor** - started: docs/cyborgos-pi.md, `pi/` (the Pi side) (Julian has a Pi 3B and a Pi 4B, one on each CPLink).
   One protocol over the card's FIFO (16 bytes deep each way, ~50K a second checking the flags a
   byte at a time, over 100K in blocks), and plugins on the Pi behind it:
   - **The protocol**: a message is a header (plugin number, slot, request id, length) and its
     data; answers come back with the same id, so several slots can have requests out at once.
     C0 owns the card (claimed CPLINK n by the system) and hands each answer to its slot - the
     same model as the network ops and the ports: a slot asks, C0 moves the bytes, the slot gets
     the answer.
   - **Plugins on the Pi** (a native plugin type: each a small program the Pi side loads, with a
     number and a name, listed by a CPLINK command):
     - a math processor (floating point, big integers, trig - the answers back in a form NTC
       BASIC reads directly)
     - a 3D matrix processor (a list of points and a matrix in, the projected screen points out:
       the CPC draws, the Pi does the arithmetic)
     - a video driver (the Pi's HDMI as a second screen: text and graphics commands in, RVDU's /
       8BML's command style - one more remote head)
     - an audio driver (samples, MOD / MP3 playing on the Pi, controlled from the CPC)
     - TCP/IP, files on the Pi's card, HTTP (as the M4 does, through the same ops 20-27)
   - **Code sent from the CPC / Next** (Julian, 2026-10-27): a real coprocessor - an
     application carries its own Pi code (a file beside the .CYB), sends it over the link, has
     it loaded as a plugin for as long as the application runs, and calls it. Nothing has to be
     installed on the Pi first; the Pi side is only the loader, the protocol and the plugins.
     The plugin goes when the application ends (as a claim does); a plugin can also be sent to
     stay (a service). What the code is (a Python module, a native .so for the Pi's ARM, a
     script) is the loader's choice - more than one kind can be taken. The same stance as the
     network: the Pi runs only what the CPC sent or what is installed there, never anything
     arriving from elsewhere.
   - **Slots on the Pi**: limited functions running there as CyborgOS services - RAT models, a
     Linux terminal (a slot's console carried to a shell on the Pi) - reached by the same ports
     the CPC's own services use, so a program can't tell whether RAT is in a bank or on the Pi.
   - Two cards in one CPC: two Pis, units 0 and 1 (the 3B and the 4B), on different ports; a
     plugin can be on either, or both (the 3D one on the 4B, RAT on the 3B).
   - **The Next**: its Pi Zero (the accelerator socket, over the Next's UART) runs the same Pi
     side with a different link underneath; the plugins a Zero can carry (math, RAT models, a
     terminal) work there too, the same protocol above the link.
   - Testing: 1984 doesn't emulate the CPLink. A model of the card in the harness (the FIFO and
     its flags) with the Pi side as a Python or JS program on the host is the way to build it
     before the real cards.
6. **Speech** (LambdaSpeak3's SSA-1 / dk'tronics modes, SpeakAndSID): a SAY service on a port.
   - SSA-1 (&FBEE) and dk'tronics (&FBFE): the same code, the port and the "ready" bit apart (SSA-1
     bit 6 = 0, dk'tronics bit 7 = 0), a short wait between allophones - a loop in NTC BASIC
     (it gives the other slots their time anyway).
   - **LambdaSpeak 3** (https://cpcwiki.eu/index.php/LambdaSpeak_III_ROM, github lambdamikel):
     an emulation of both with more modes - Epson (its native text to speech: text in, no
     allophone table), DECtalk (text, sings), the SPO256 chip on board, Amdrum, PCM samples,
     serial / MIDI, MP3 / WAV, its own RTC (|GETTIME, |SAYTIME). Controlled through &FBEE:
     255 then a command byte (255 255 a literal 255), a status byte read back (16 ready, 3 after
     a 255, 4 busy). Amdrum and PCM modes are left only by a reset or power off - a SPEAK
     program never selects them.
   - **Speak&SID** (github.com/lambdamikel/Speak-SID): &FBEE too, 255 then the mode: 2 SpeakJet
     (its own allophone codes; &FBDE its status: bit 0 ready, 1 speaking, 3 buffer), 3 SSA-1,
     4 SID, 5 UART, 8 GPIO, 11 MIDI SID; 255 30 the mode now, 99 the version. The SID's 28
     registers at &FAC0-&FADC directly (no ATmega in the way): a SID test is one OUT a register.
   - Both boards answer at &FBEE: with both fitted, which one hears a 255 command depends on how
     each is set (to check on the real machine - HWINFO's job); the claim `SPEECH 0` covers
     the port, whichever board is on it.
7. **Sound** (PlayCity, Willy, SID, Amdrum): left to the programs, with their claims.
8. **Nova and Multiface II: dedicated utilities** (Julian, 2026-10-27), each claiming NOVA / MF2:
   - **NVRAM** (Nova): a command line management tool - the clock (read, set), the NVRAM's 4 x 8K
     pages (list, dump, save, load). UniDOS keeps its configured drives there; CyborgOS reads
     them at its start (the drives UniDOS had set up). It may have other uses (a small store
     that survives power off). The mapping goes over #6000-#7FFF, CyborgOS's window, so the
     tool asks C0 to do the mapping (a far call) rather than doing the OUT itself.
   - **MF2**: its buttons are an NMI - pressing STOP takes the machine from CyborgOS and it
     can't come back (the NTC program it stopped is already corrupted). That stays as it is.
     What can be used: its RAM while it is visible - the chip state it captures in real time
     (the gate array's mode and inks, the CRTC's registers, the PPI control: #3Fxx / #1DBx,
     section of the CPCWiki page), and its 8K of RAM (#2000-#3FFF) as a mini RAM disc. Mapped
     over #0000-#3FFF (CyborgOS's stubs), so again through C0.

## 5. The hardware tests (disc 8, 2026-10-27)

Small programs, each claiming what it drives, built for the cyborgos platform (CPC only):

| Program | What | Checked |
|---|---|---|
| HWINFO [ALL] | the ROMs by name, V9990, DS12887, W5100S, M4, Albireos (ALL: with an M4), SF2 mouse, speech ports, Booster - reads only | 1984 (with the V9990, RTC, Net4CPC, M4) |
| RTCTEST [SET ...] | the DS12887's date and time, its mode; SET writes it (RTC 0) | 1984 |
| M4TIME | the M4's C_TIME, through C0 (BDOS 131 op 20 / 11), the network on or not | 1984 |
| NTPTEST [a.b.c.d] | one NTP request on the W5100S's socket 3 (W5100 0): open, send, receive, close - the start of the Net4CPC driver | 1984 (a local NTP server) |
| SPEAK [SSA / DKT] ... | SP0256 allophones, a ready bit between each (SPEECH 0 / 1) | 1984: no card (the error path); the real cards to do |
| SIDTEST [ON] | a chord on Speak&SID's SID at &FAC0 (SID 0) | the real board to do |

Julian's real CPC is the next check: HWINFO there shows what CyborgOS sees, which slot the M4
ROM is in, and what answers at &FBEE with both LambdaSpeak 3 and Speak&SID fitted.

## 6. The V9990's VRAM as a RAM disc

512K of VRAM read and written through P#0 (R#0-2 the address, moving on by itself): a RAMDISC
driver ("RAMDISC V size"), a record an OTIR / INIR. With the console on the V9990 it takes 136K
(the ring of 256 lines and the font's 16, 512 bytes a line), so 376K is left; without, 512K.
Claimed V9990 1 (the VRAM; unit 0 the screen) so a graphics program doesn't write over it.

## 7. Testing

The 1984 emulator (https://github.com/salvogendut/1984, GPL v2) emulates the M4, Net4CPC (with a
TAP backend), the DS12887 RTC, SYMBiFACE IDE and mouse, Albireo, USIfAC II, the V9990 and up to
1MB. It builds here and boots CyborgOS from an M4 folder; it is the way to test the drivers above
before a real CPC. tools/emu84/ has the notes.
