# shotgui.py dump.bin out.png [NTC test folder]: NTC_SHOT's dump (R12, main RAM #4000, #C000) - the
# screen shown, mode 2, as a picture. NTC's harness gives the CPC's font as one byte a character
# (its code on the first line, the other 7 lines 0 - so it can read text back off the screen); a
# cell that looks like that (or its inverse) is drawn with the harness's stand-in font instead, so
# the picture reads as it would on a CPC. (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import sys, os
from PIL import Image
d = open(sys.argv[1], 'rb').read(); r12 = d[0]; s4 = d[1:0x4001]; sc = d[0x4001:0x8001]
m = s4 if (r12 & 0x30) == 0x10 else sc
tdir = sys.argv[3] if len(sys.argv) > 3 else os.path.expanduser('~/ntc/src/test')
font = bytes(int(x, 16) for l in open(os.path.join(tdir, 'font_standin.txt')) if not l.startswith(';') for x in l.split(';')[0].split())
def at(xb, y): return m[(y // 8) * 80 + (y % 8) * 0x800 + xb]
bits = [[0] * 640 for _ in range(200)]
for y in range(200):
    for xb in range(80):
        b = at(xb, y)
        for i in range(8): bits[y][xb * 8 + i] = (b >> (7 - i)) & 1
for cy in range(25):
    for cx in range(80):
        rows = [at(cx, cy * 8 + k) for k in range(8)]
        done = False
        for edge in (0, 0x80, 0x01, 0x81):              # (a box's side through the cell: its edge pixels kept)
            for inv in (0, 0xFF):
                c = (rows[0] ^ inv) & ~edge & 0xFF
                if not done and 32 <= c < 127 and all(((r ^ inv) & ~edge & 0xFF) == 0 for r in rows[1:]) \
                        and all(((r ^ inv) & edge) == edge for r in rows[1:]):
                    g = font[(c - 32) * 8:(c - 32) * 8 + 8]
                    for k in range(8):
                        for i in range(8): bits[cy * 8 + k][cx * 8 + i] = (((g[k] | edge) ^ inv) >> (7 - i)) & 1
                    done = True
# the colours: the firmware's SCR SET INK / BORDER last set (the harness notes them after the
# screens), else the console's blue and bright yellow
CPC = [(0,0,0),(0,0,128),(0,0,255),(128,0,0),(128,0,128),(128,0,255),(255,0,0),(255,0,128),(255,0,255),
       (0,128,0),(0,128,128),(0,128,255),(128,128,0),(128,128,128),(128,128,255),(255,128,0),(255,128,128),
       (255,128,255),(0,255,0),(0,255,128),(0,255,255),(128,255,0),(128,255,128),(128,255,255),(255,255,0),
       (255,255,128),(255,255,255)]
ink = list(d[0x8001:0x8004]) if len(d) >= 0x8004 else [255, 255, 255]
c0 = CPC[ink[0]] if ink[0] < 27 else CPC[1]
c1 = CPC[ink[1]] if ink[1] < 27 else CPC[24]
im = Image.new('RGB', (640, 200)); px = im.load()
for y in range(200):
    for x in range(640): px[x, y] = c1 if bits[y][x] else c0
im.resize((1280, 800), Image.NEAREST).save(sys.argv[2])
print('R12 = #%02X: the screen at %s' % (r12, '#4000' if (r12 & 0x30) == 0x10 else '#C000'))
