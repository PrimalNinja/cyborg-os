# Atari 8-bit over SIO to the Pi's UART

- Hardware: the SIO bus (data in, data out, and the command line) is a 5 V serial bus; the Pi's
  UART through a level shifter, the way SIO2PC cables do (a USB SIO2PC on the Pi is the same
  thing without soldering). The usual rate is 19200 baud.
- Pi: cosd --link=serial:/dev/ttyUSB0:19200. No bridge; the Pi is just the other end of the
  wire, not an SIO device (it answers no SIO commands: the link is raw bytes, which the Atari's
  SIO hardware carries fine when driven directly).
- The client: example.bas - Atari BASIC driving POKEY's serial port directly through the OS's
  serial vectors is involved; the practical route is the 850's R: handler (or a software R:
  handler such as the one in the BOBTERM / SIO2PC world) loaded first, then OPEN #1,13,0,"R:"
  and PUT / GET bytes. The example assumes an R: device at 19200 is present.
- To check on the hardware: which R: handler is in use and its XIO for the baud (XIO 36,#1,...),
  and that the command line is left alone (the Pi is not an SIO device).
