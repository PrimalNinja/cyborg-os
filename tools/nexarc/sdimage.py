#!/usr/bin/env python3
# sdimage.py - an SD card image for testing CyborgOS-Next in an emulator (ZEsarUX: tbblue.mmc, a
# NextZXOS distribution): a copy of BASE.MMC with NEXTZXOS/AUTOEXEC.BAS replaced by a one-line
# NextBASIC program that runs the NEX, and files of yours put on the card.
#   python3 sdimage.py BASE.MMC OUT.MMC '.nexload /cyborgos.nex' local=/SDPATH [local=/SDPATH ...]
#   e.g. python3 sdimage.py tbblue.mmc cos.mmc '.nexload /cyborgos.nex' build/next/CYBORGOS.NEX=/CYBORGOS.NEX
# Then ZEsarUX: --machine tbblue --enable-mmc --enable-divmmc-ports --enable-divmmc-paging --mmc-file
# cos.mmc (--mmc-no-persistent-writes keeps the image as made). NextZXOS boots (Enter at the video
# mode test, Space at the welcome the first time), the autoexec runs CyborgOS.
# Needs pip install pyfatfs. The partition starts at sector 2048 in the ZEsarUX image (the MBR says).
import struct, sys, shutil

def bas(cmd):
    body = cmd.encode() + b'\r'
    prog = struct.pack('>H', 10) + struct.pack('<H', len(body)) + body
    hdr = bytearray(128)
    hdr[0:8] = b'PLUS3DOS'; hdr[8] = 0x1A; hdr[9] = 1
    struct.pack_into('<I', hdr, 11, 128 + len(prog))
    struct.pack_into('<H', hdr, 16, len(prog))      # the program's length
    struct.pack_into('<H', hdr, 18, 10)             # LINE 10
    struct.pack_into('<H', hdr, 20, len(prog))
    hdr[127] = sum(hdr[:127]) & 255
    return bytes(hdr) + prog

def main(base, out, cmd, files):
    from pyfatfs import PyFatFS
    shutil.copy(base, out)
    d = open(out, 'rb').read(512)
    start = int.from_bytes(d[0x1C6:0x1CA], 'little')   # partition 1's first sector
    fs = PyFatFS.PyFatFS(out, offset=start * 512)
    if fs.exists('/NEXTZXOS/AUTOEXEC.BAS'): fs.remove('/NEXTZXOS/AUTOEXEC.BAS')
    fs.writebytes('/NEXTZXOS/AUTOEXEC.BAS', bas(cmd))
    for a in files:
        src, _, dst = a.partition('=')
        if fs.exists(dst): fs.remove(dst)             # (pyfatfs can't overwrite in place)
        fs.writebytes(dst, open(src, 'rb').read())
    fs.close()
    print('%s: autoexec "%s", %d files' % (out, cmd, len(files)))

if __name__ == '__main__':
    if len(sys.argv) < 4: print(__doc__); sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:])
