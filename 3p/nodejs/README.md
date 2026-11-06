# Node.js, vendored (pi/3p/nodejs)

cosd and its services run on Node.js and need nothing else (no npm packages). So the runtime
comes with CyborgOS for the Pi rather than being installed from the network:

- linux-arm64/node    Node.js 22.23.4, the official build, for the 64-bit Raspberry Pi OS
                      (Pi 3B, 4B, 5, Zero 2 W)
- linux-armv7l/node   Node.js 22.23.4 for the 32-bit Raspberry Pi OS on the same boards
- (a Pi Zero W, armv6: no official build; a Zero 2 W is arm64)

Source: the official binaries as published on the npm registry by the Node.js project
(packages node-linux-arm64 and node-linux-armv7l, version 22.23.4), taken 2026-11-02;
SHA256SUMS has the sums. Licence: MIT (LICENSE beside each binary, with the licences of what Node
bundles: V8 BSD-3-Clause, libuv MIT, OpenSSL Apache-2.0, ICU Unicode, and the rest).

pi/run.sh picks the binary for the machine it is on (uname -m) and starts cosd with it.
