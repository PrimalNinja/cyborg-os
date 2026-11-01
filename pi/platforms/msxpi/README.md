# MSX with the MSXPi cartridge

- Hardware: MSXPi (Ronivon Costa): a cartridge carrying a Pi Zero, the MSX reaching the Pi over
  SPI through the cartridge's I/O ports; the Pi runs Linux (the MSXPi image, Raspbian), so cosd
  runs as is. MSXPi has its own server on the Pi (msxpi-server) and its own commands on the MSX.
- Pi: a bridge like cplink-bridge.c for the cartridge's SPI handshake, presenting a TCP port for
  cosd (--link=tcp-connect:127.0.0.1:PORT); msxpi-server's source has the GPIO side to take it
  from. MSXPi's own server and ours can't both own the SPI, so one or the other runs.
- The client: example.bas - MSX-BASIC with the byte in / out on the cartridge's ports (MSXPi's
  documented ports: data and control, to verify from its source), the same frame routine as the
  other platforms. As MSX is an NTC platform, the real client is an NTC Link class for the
  cartridge, after which every NTC class (Float, the VDP, the store) works unchanged.
