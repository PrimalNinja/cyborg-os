#!/usr/bin/env python3
# nexarc.py - the CyborgOS-Next boot archive: the files the NEX carries (Option NexData in Main.bas),
# read by the hypervisor as its boot drive (A: the CPC's disc) - CYBORGOS.Z, RAMDISC.CYB and the
# commands RAMDISC Z SYSTEM A copies onto the Z: RAM disc. Read only.
#   python3 nexarc.py OUT.ARC blocks FILE [FILE ...]       (blocks: 16K blocks, the Option NexData count)
#   python3 nexarc.py --list OUT.ARC
# Layout (Hyp.cls, the zxn page code: fl_arc_*):
#   "CARC", the entries (a word at 4), 0s to 16; from 16 the entries, 16 bytes each (up to 1023):
#   the name (8 + 3, spaces, capitals), the length (3 bytes), the first record (2 bytes: 128 byte
#   records from the archive's start); then the files, each from a record boundary, in the order given
# A name is the file's base name in capitals (RAMDISC.CYB), or SRC=NAME to store it under another.
# The files go in as they are: a .CYB with its AMSDOS header (the hypervisor's loader skips the
# header, as it does on the card), a plain .COM without
import os, sys

def entry_name(n):
    b, _, x = n.upper().partition('.')
    return (b.ljust(8)[:8] + x.ljust(3)[:3]).encode()

def build(out, blocks, files):
    d = bytearray(16 + 16 * len(files))
    d[0:4] = b'CARC'
    data = bytearray()
    drec = (16 + 16 * len(files) + 127) // 128  # the directory's records: the files from the next
    rec = drec
    for i, f in enumerate(files):
        src, _, name = f.partition('=')
        if not name: name = os.path.basename(src)
        if i >= 1023: raise SystemExit('nexarc: too many files')
        b = open(src, 'rb').read()
        e = 16 + i * 16
        d[e:e + 11] = entry_name(name)
        d[e + 11:e + 14] = len(b).to_bytes(3, 'little')
        d[e + 14:e + 16] = rec.to_bytes(2, 'little')
        pad = (-len(b)) % 128
        data += b + b'\x1a' * pad               # (padding as AMSDOS pads: #1A soft ends)
        rec += (len(b) + pad) // 128
    d[4] = len(files) & 255; d[5] = len(files) >> 8
    d += b'\x1a' * (drec * 128 - len(d))
    img = bytes(d) + bytes(data)
    if len(img) > blocks * 16384:
        raise SystemExit('nexarc: %d bytes: more than %d blocks of 16K' % (len(img), blocks))
    img += b'\x1a' * (blocks * 16384 - len(img))
    open(out, 'wb').write(img)
    print('%s: %d files, %d bytes in %d blocks' % (out, len(files), len(img), blocks))

def list_(path):
    d = open(path, 'rb').read()
    if d[:4] != b'CARC': raise SystemExit('not an archive')
    n = d[4] | d[5] << 8
    for i in range(n):
        e = 16 + i * 16
        nm = d[e:e + 8].decode().rstrip() + '.' + d[e + 8:e + 11].decode().rstrip()
        ln = int.from_bytes(d[e + 11:e + 14], 'little'); rc = int.from_bytes(d[e + 14:e + 16], 'little')
        print('%-12s %7d  record %d' % (nm, ln, rc))

if __name__ == '__main__':
    if len(sys.argv) >= 3 and sys.argv[1] == '--list': list_(sys.argv[2])
    elif len(sys.argv) >= 4: build(sys.argv[1], int(sys.argv[2]), sys.argv[3:])
    else: print(__doc__ or 'nexarc.py OUT.ARC blocks FILE...  |  --list OUT.ARC')
