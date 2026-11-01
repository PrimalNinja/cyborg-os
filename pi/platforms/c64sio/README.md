# C64 over the user port (RS-232) to the Pi's UART

- Hardware: the C64's user port RS-232 (TTL levels on the user port pins; the kernal's RS-232 is
  software-timed) through a 5 V <-> 3.3 V level shifter to the Pi's UART (GPIO 14 TX, 15 RX).
  The kernal does 300 to 2400 baud; 1200 is safe for the software UART. (A UP9600-style
  shift-register mod gives 9600 and is widely used; the same client code.)
- Pi: cosd --link=serial:/dev/ttyAMA0:1200 (or the baud used). No bridge: the UART is the link.
- The client: example.bas - Commodore BASIC V2 opening the RS-232 device (OPEN 2,2,3,CHR$(8)+
  CHR$(0): 1200 baud, 8 bits, no parity, 1 stop) and sending frames with PRINT#2 / GET#2.
  Binary-safe: the kernal passes every byte; CHR$(0) is fine in a string built with CHR$.
- To check on the hardware: the baud byte for the kernal (CHR$(8) = 1200: see the Programmer's
  Reference Guide table), and that the 300 ms the kernal needs after OPEN before the first byte
  is observed.
