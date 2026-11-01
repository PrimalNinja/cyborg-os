# TRS-80 Model III / 4 over RS-232 to the Pi's UART

- Hardware: the Model III / 4's RS-232 board (the Model I's RS-232 interface in the expansion
  interface) at real RS-232 levels, so a MAX3232-type level converter to the Pi's UART (GPIO 14 /
  15), or a USB-serial adaptor on the Pi and a plain serial cable.
- Pi: cosd --link=serial:/dev/ttyUSB0:9600 (or /dev/ttyAMA0). No bridge.
- The client: example.bas - BASIC with the serial port driven directly through the UART's ports
  (Model III / 4: the UART at &HEA status / &HEB data; the baud set through &HE8-&HE9), one byte
  at a time with INP / OUT, which is the whole of what the frame routine needs. A DOS's serial
  driver (LDOS / LS-DOS COM) would do as well, with PRINT / INPUT on the device.
- To check on the hardware: the status bit for "transmitter ready" and "byte received" in the
  UART's status port (the Model III technical manual: bit 6 THRE, bit 7 DAV, to be verified), and
  the baud-rate register's value for 9600.
