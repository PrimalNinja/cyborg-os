# votrax - the SC-01 speech chip on the Pi (pi/3p/votrax)

The Votrax SC-01 (the arcade voice: Q*bert, Gorf, Wizard of Wor) emulated, as a program: phoneme
bytes in on stdin (bits 0-5 the phoneme, 6-7 the inflection), 16-bit mono PCM out on stdout at
40000 Hz. cosd's votrax service runs it and pipes the sound to aplay.

- votrax.cpp, votrax.h   MAME's emulation (license: BSD-3-Clause, copyright-holders: Olivier
                         Galibert), unchanged but for its includes (MAME's emu.h / logmacro.h
                         replaced by the shim) and three small hooks added to the class for the
                         program's use (the ROM given, the timer stepped, samples rendered)
- emu.h                  a stand-in for the parts of MAME's framework the emulation uses (MIT)
- main.cpp               the program (MIT)

The chip's 512-byte internal ROM (sc01a.bin in MAME's ROM sets, the chip's own microcode,
decapped) is not shipped: put it in the Pi's store as SYS/SC01A.BIN for the machine (STORE PUT
SYS/SC01A.BIN, or copy it to STORE/<machine>/SYS/SC01A.BIN). Without it the program writes
nothing and exits 2, and the service answers STATUS with "OK norom".

Build on the Pi (once):   g++ -O2 -std=c++17 -o votrax main.cpp votrax.cpp
A prebuilt binary for arm64 will sit here when the Pi build is done.
