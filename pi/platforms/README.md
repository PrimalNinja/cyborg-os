# platforms/ - other machines on the same Pi

CyborgOS for the Pi serves any machine that has a byte stream to the Pi. The Pi side is the
same cosd; what differs per machine is the transport (a FIFO card, SPI, a UART) and so the
client code on the machine. A platform folder holds:

- README.md     the link: the hardware, which cosd --link= to start, the bridge if the transport
                needs one on the Pi (as cplink-bridge.c does for the CPC-CPLink), what is proven
- an example    the smallest client that speaks the protocol from that machine: HELLO, a PING,
                a STORE PUT and GET - the framing (A5 chan type id len payload check) in the
                machine's own BASIC or assembler, so a game author copies the routine and goes on

The protocol (docs/cyborgos-pi.md, proto.js) is the same for all: a frame is
A5, chan, type, id, len-lo, len-hi, payload, check (the low byte of the sum of chan to the end of
the payload). HELLO on channel 0 first ("COS1 machine=NAME name=NAME max=256"), OPEN service on
channel 0 ("OK n" names the channel), requests as REQ frames with an id and answers as RSP frames
carrying it back, data as DATA, events as EVT, CREDIT returned for what is read. The CPC's client
is NTC's streamer ROM; NTC classes for a machine come once NTC targets it.

## Sending Z80 code to the Pi (the coprocessor)

For a Z80 machine (MSX, TRS-80, and the CPC) a program can run ON the Pi rather than talk to it:
the vCPC (a CyborgOS with no machine under it) runs on the Pi, and a slot of it takes a program.
Two routes, both CyborgOS's, documented in cyborg-os/docs:
- A file: PUT a program compiled for NTC's cyborgos / cpm platform (a CP/M-shaped .CYB or .COM)
  into the store, then the slot service runs it (VCPC:n/RUN, IN, OUT, PS as paths - to come;
  today the vCPC runs programs from its host folders).
- A running program, moved with its registers and screen: RCOPY / RMOVE on the sending CyborgOS
  and SLOTD on the receiving one - the dump stream (a 128-byte header, the program, the console
  page) is in docs/cyborgos-design.md section 8 and docs/cyborgos-moving-slots.md; a client on
  another machine can produce that stream itself and send it to the vCPC's SLOTD port.
A 6502 machine (Apple II, C64, Atari) can't run its code on the Pi's Z80; it uses the services.

## Several machines at once

cosd takes --link more than once: each link is a session of its own, so a CPC on the CPLink and
a C64 on the UART share one Pi, one store (a tag space each, by the HELLO name), one display.

Status 2026-11-02: these five are sketches - the frame routine is real and shared, the transport
details are from each link's documentation and marked where they need checking on the hardware.
None has been run against a real machine yet.

- apple2pi/     Apple II with the Apple2Pi card (GPIO link, Linux on the Pi)
- msxpi/        MSX with the MSXPi cartridge (SPI to a Pi Zero, Linux on the Pi); MSX is an NTC
                platform, so NTC classes follow
- trs80sio/     TRS-80 Model III / 4 over its RS-232 to the Pi's UART
- atari8bsio/   Atari 8-bit over the SIO bus to the Pi's UART (a level shifter in between)
- c64sio/       Commodore 64 over the user port's RS-232 to the Pi's UART (a level shifter)
