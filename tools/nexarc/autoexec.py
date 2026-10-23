#!/usr/bin/env python3
# autoexec.py OUT.BAS 'command' - a one-line NextBASIC program (line 10: the command) as the
# +3DOS file NextZXOS runs at boot when it is /NEXTZXOS/AUTOEXEC.BAS: the card image boots
# straight into CyborgOS with '.nexload /cyborgos.nex'
import struct, sys
out, cmd = sys.argv[1], sys.argv[2]
body = cmd.encode() + b'\r'
prog = struct.pack('>H', 10) + struct.pack('<H', len(body)) + body
hdr = bytearray(128)
hdr[0:8] = b'PLUS3DOS'; hdr[8] = 0x1A; hdr[9] = 1
struct.pack_into('<I', hdr, 11, 128 + len(prog)); struct.pack_into('<H', hdr, 16, len(prog))
struct.pack_into('<H', hdr, 18, 10); struct.pack_into('<H', hdr, 20, len(prog))
hdr[127] = sum(hdr[:127]) & 255
open(out, 'wb').write(bytes(hdr) + prog)
