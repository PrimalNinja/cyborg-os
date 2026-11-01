# Apple II with the Apple2Pi card

- Hardware: the Apple2Pi card (David Schmenk) in a slot, the Pi on its header; the Apple II
  side sees the card's registers in the slot's I/O space ($C0n0 up, n the slot + 8), and the Pi
  side reads and writes them through the GPIO. The Pi runs Linux (the Apple2Pi image is a
  Raspbian), so cosd runs as is.
- Pi: a bridge is needed: Apple2Pi's own daemon owns the GPIO link and speaks its own protocol.
  Two ways: (a) a small bridge like cplink-bridge.c that drives the card's GPIO lines itself and
  presents a TCP port, with cosd --link=tcp-connect:127.0.0.1:PORT; (b) run our frames inside
  Apple2Pi's own serial channel to the Pi, the way its "a2term" does, with cosd on a pty. (a) is
  cleaner; its GPIO handshake is in Apple2Pi's source (a2pi.c).
- The client: example.bas - Applesoft with two PEEK / POKE routines on the card's data and
  status registers (slot 7 assumed: $C0F0 data, $C0F1 status; the real register map and the
  ready bits from the card's documentation - to verify).
