# zxnshot.py out.png: GUI's screen on the Next in ZEsarUX (its remote protocol, port 10000) - the
# tilemap and tiles GUI keeps in bank 5's page 10 (map at +0, 80 x 32; tiles at +#0A00), and
# sprite 0 (the pointer: NextReg reads aren't possible for sprites, so it isn't drawn).
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import sys, re, time, socket
from PIL import Image
class Z:
    def __init__(s, port=10000):
        s.s = socket.create_connection(('127.0.0.1', port)); s.s.settimeout(5); s.cmd('')
    def cmd(s, c):
        s.s.sendall((c + '\n').encode()); d = b''
        while not d.endswith(b'command> ') and not d.endswith(b'command@cpu-step> '):
            d += s.s.recv(65536)
        return d.decode('latin-1').rsplit('\n', 1)[0]
z = Z()
r = z.cmd('get-registers'); m = re.search(r'MMU=([0-9a-f]{32})', r); mmu7 = int(m.group(1)[28:32], 16)
z.cmd('enter-cpu-step'); time.sleep(0.1); z.cmd('tbblue-set-register 87 10'); time.sleep(0.1)
def rd(a, n):
    out = b''
    while len(out) < n:
        k = min(1024, n - len(out))
        d = z.cmd('read-memory %d %d' % (a + len(out), k)); h = ''.join(c for c in d.split('\n')[0] if c in '0123456789ABCDEFabcdef')
        out += bytes.fromhex(h[:2 * k])
    return out
def reg(r): return int(z.cmd('tbblue-get-register %d' % r).split('H')[0], 16)
try:
    tm = rd(0xE000, 2560); tl = rd(0xEA00, 2048)
    p43, p40 = reg(0x43), reg(0x40)                  # the tilemap's colours 0 and 1 (RRRGGGBB)
    z.cmd('tbblue-set-register 67 %d' % ((p43 & 0x8F) | 0x30)); col = []
    for i in (0, 1):
        z.cmd('tbblue-set-register 64 %d' % i); col.append(reg(0x41))
    z.cmd('tbblue-set-register 67 %d' % p43); z.cmd('tbblue-set-register 64 %d' % p40)
finally:
    z.cmd('tbblue-set-register 87 %d' % mmu7); z.cmd('exit-cpu-step')
def rgb(v): return ((v >> 5) * 255 // 7, ((v >> 2) & 7) * 255 // 7, (v & 3) * 255 // 3)
c0, c1 = rgb(col[0]), rgb(col[1])
im = Image.new('RGB', (640, 256)); px = im.load()
for row in range(32):
    for cx in range(80):
        t = tm[row * 80 + cx]
        for k in range(8):
            b = tl[t * 8 + k]
            for i in range(8): px[cx * 8 + i, row * 8 + k] = c1 if b & (0x80 >> i) else c0
im.resize((1280, 512), Image.NEAREST).save(sys.argv[1])
print('tiles used:', len(set(tm)))
