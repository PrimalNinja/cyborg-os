CyborgOS

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License

RUN SEVERAL CP/M PROGRAMS AT ONCE ON YOUR AMSTRAD CPC OR ZX SPECTRUM NEXT!

Status: ALPHA. It runs, it's used, and it keeps changing. The Amstrad CPC 320K version is the reference and has been in daily use. The ZX Spectrum Next port boots to a working system with the SD card as a drive. Expect rough edges.

A HYPERVISOR FOR Z80 COMPUTERS

CyborgOS runs several CP/M programs side by side. Each one gets a whole 64K bank of its own, with its own command line and console, and you switch between them with a keystroke.

Every program sees a plain CP/M 2.2 machine: the BDOS, a BIOS jump table, a TPA from #0100 and drives with 8.3 file names. It never sees the hypervisor or the other programs. CyborgOS owns the real machine: the banking, the screen, the keyboard, the clock and the discs.

It runs NTC BASIC programs built for the cyborgos platform (.CYB, one file that runs on both the CPC and the Next), and any CP/M 2.2 program that sticks to the BDOS and BIOS (.COM).

THINGS CP/M NEVER HAD

- Many programs at once: each has its own screen and command line, you switch with a keystroke, and a TOP screen shows what every slot is running and how busy it is
- Directories: CP/M has none. CyborgOS binds a drive letter to a folder (CD GAMES/ACTION), using UniDOS on the CPC and the SD card on the Next. A program still sees a flat drive, with the folder hiding behind the letter. User numbers are ignored, because nobody misses them
- Real random access files (BDOS 33-36) on the RAM discs, where AMSDOS only ever did sequential. The Next's SD card gives the same
- RAM discs that outlive a reset, with any number of files open
- A network: through the CPC's M4 board or the Next's ESP, with NET, IPCONFIG and NETSTAT commands, plus HTTP GET, POST and streamed reads for your own programs. The boards do the TCP/IP, and CyborgOS never listens for incoming connections
- Ports between slots, so programs can talk to each other
- Decision services: RAT and MODEL, NEURAL, PROBE and a virtual pet, with documents on how to get an AI to build models
- Remote displays (RVDU)
- A GUI: GUI.CYB as a service, with its own heads for the CPC's mode 2 and the Next's tilemap, and a GUIDEMO to try
- System services for programs: the slot, the clock and the ports between slots, wrapped for NTC BASIC
- One .CYB program file that runs unchanged on the CPC and the Next

TWO VERSIONS

- CyborgOS 320K (Amstrad CPC): the reference version, and it works. Needs a CPC with 320K or more (a 256K expansion). Gives you 2 to 20 slots, AMSDOS and UniDOS discs and devices, RAM discs, and 80 x 25 text
- CyborgOS-Next (ZX Spectrum Next): alpha. Boots and runs commands and programs. C: is the SD card with folders, A: is a read-only archive inside the NEX, and Z: is a RAM disc. Needs a Next with 1MB or more (2MB tested). Gives you 10 slots on a 2MB Next and 80 x 32 tilemap text with Layer 2 underneath

Programs built for CyborgOS run on both.

GETTING STARTED

On a real Next: copy CYBORGOS.NEX and the whole CYBORGOS folder onto your SD card, then open the NEX from the NextZXOS browser (or use .nexload CYBORGOS.NEX). The folder holds the commands, the help texts and the CPC's apps, which run here too (FLOPPY excepted).

On an emulator: a bootable 64MB SD card image boots straight into CyborgOS. It works with ZEsarUX, CSpect and JNEXT. Reset and touch nothing, and it goes on by itself into CyborgOS.

On the CPC 320K: write the disc image to a disc (or mount it in an emulator) and type RUN"CYBORGOS. In WinAPE, use RUN"WINAPE. INSTALL.BAS on disc 1 sets up the full set.

Two Next builds are provided. The standard build boots without Z: and starts quicker, running the commands from P:, which is mapped to the card's CYBORGOS/C/ folder. The Z build makes the Z: RAM disc at boot as before. Copy one or the other.

THE COMMAND LINE

- HELP shows the list of commands, and HELP DIR shows one command's help
- DIR lists the files on this slot's drive
- Type a program's name to run it, or RUN 3 name to run it in slot 3
- TYPE file shows a text file
- CV B: or just B: changes this slot's drive
- CD folder changes this slot's folder
- TOP shows what every slot is doing, live
- FG 3 brings slot 3 to the front
- KILL 3 stops the program in slot 3
- RESET 3 resets slot 3
- RAMDISC manages RAM discs (RAMDISC D 256KB makes one as D:)
- MEM shows main RAM and the banks
- ERA, COPY and RENAME handle files
- MKDIR and RMDIR handle folders
- CLS clears the screen, and QUIT ends CyborgOS

SWITCHING PROGRAMS

Start something in slot 1, press Shift + 2 (Next) or Control + 2 (CPC), and you're at slot 2's prompt while slot 1 keeps running. Shift + 0 (Next) or Control + ESC (CPC) shows TOP: every slot, what it's running and how busy it is.

A program waiting for a key costs nothing. Programs that compute share the CPU in time slices.

WHAT'S NOT THERE YET

Next alpha:

- The SD card is read and written through NextZXOS, one file at a time per direction
- HELP's list is still the CPC's
- No key repeat yet
- 10 slots at most for now
- The 80-column console is 25 rows, though the screen has 32

CPC:

- Random access files work on RAM discs only
- The scrollback is off, and MODE's other text sizes are rough

Both: programs that poke the hardware directly (the CRTC, the sound chip) work on the CPC but will misbehave on the Next.

MORE INFORMATION

Documents cover the user guide, the Next port, the design, the GUI, the decision services, Pluto (NTS on the CPC), and CVM, a draft native host for Windows and Xbox.

Requires an Amstrad CPC with 320K or more, or a ZX Spectrum Next with 1MB or more.

Many programs. One machine. One keystroke apart.