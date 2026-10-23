# rbgfx.py - RATBOXN's graphics, drawn here in code: the tiles (8 x 8, 4 bits a pixel), the sprite
# patterns (16 x 16, 4 bits) and the palettes -> RBGfx.cls (the data as db lines, and Load: the tiles
# into bank 5 at #CC00 - the font's CyborgOS-Next's console's own, bank 5 + #2C00 -, the patterns
# into the sprite RAM, the palettes) and gfx/*.png (to look at, 4x).
#   python3 tools/rbgfx.py
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import os, random, math
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

def rgb(r, g, b):          # 0-7, 0-7, 0-3 -> RRRGGGBB
    return (r << 5) | (g << 2) | b

# ---- the tile palette (the tilemap's first; 15 is kept out of the tiles: see-through)
TPAL = [rgb(0, 0, 0),      # 0 black (the text rows)
        rgb(7, 7, 3),      # 1 white (text)
        rgb(7, 7, 0),      # 2 yellow
        rgb(6, 5, 1),      # 3 sawdust
        rgb(5, 4, 1),      # 4 sawdust, darker
        rgb(4, 2, 0),      # 5 wood
        rgb(2, 1, 0),      # 6 dark wood
        rgb(6, 1, 0),      # 7 red
        rgb(1, 5, 0),      # 8 green
        rgb(1, 3, 3),      # 9 TV blue
        rgb(4, 4, 2),      # 10 grey
        rgb(6, 6, 3),      # 11 light grey
        rgb(7, 4, 2),      # 12 pink
        rgb(7, 6, 0),      # 13 straw
        rgb(1, 1, 1),      # 14 dark grey
        rgb(7, 0, 3)]      # 15 (see-through)

# ---- the sprite palette: rows of 16 (a sprite's palette offset picks its row); 15 see-through
def srow(outline, body, shade, pink=rgb(7, 4, 2), eye=rgb(0, 0, 0), glint=rgb(7, 7, 3)):
    r = [rgb(0, 0, 0)] * 16
    r[1], r[2], r[3], r[4], r[5], r[6] = outline, body, shade, pink, eye, glint
    r[15] = rgb(7, 0, 3)
    return r
SPAL = (srow(rgb(1, 1, 0), rgb(5, 3, 1), rgb(4, 2, 0)) +          # 0 a male: brown
        srow(rgb(2, 2, 1), rgb(7, 7, 3), rgb(5, 5, 2)) +          # 1 a female: white
        srow(rgb(3, 2, 1), rgb(7, 6, 2), rgb(7, 5, 2)) +          # 2 a baby: pale pink
        srow(rgb(1, 1, 1), rgb(4, 4, 2), rgb(3, 3, 1)) +          # 3 old: grey
        srow(rgb(2, 0, 0), rgb(7, 2, 0), rgb(5, 1, 0)) +          # 4 fighting: red
        srow(rgb(0, 2, 0), rgb(3, 6, 1), rgb(2, 4, 0)) +          # 5 ill: green
        srow(rgb(3, 2, 0), rgb(7, 7, 0), rgb(7, 5, 0)) +          # 6 the marker: yellow
        srow(rgb(3, 0, 0), rgb(7, 1, 1), rgb(6, 0, 1)))           # 7 a heart: red

def grid(w, h, c):
    return [[c] * w for _ in range(h)]

def outline(g, inside, col=1):
    h, w = len(g), len(g[0])
    out = [row[:] for row in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] != 15: continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < w and 0 <= yy < h and g[yy][xx] in inside:
                    out[y][x] = col
                    break
    return out

def ell(g, cx, cy, rx, ry, col, shade=None, split=None):
    for y in range(len(g)):
        for x in range(len(g[0])):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                g[y][x] = shade if (shade is not None and y + 0.5 > split) else col

def rat(feet, s=1.0, ox=0, oy=0):
    g = grid(16, 16, 15)
    S = lambda v: v * s
    ell(g, ox + S(6.5), oy + S(10.2), S(5.6), S(3.3), 2, 3, oy + S(11.2))     # the body
    ell(g, ox + S(11.6), oy + S(9.2), S(3.1), S(2.5), 2)                       # the head
    ell(g, ox + S(14.0), oy + S(9.9), S(1.6), S(1.2), 2)                       # the snout
    ell(g, ox + S(10.6), oy + S(6.6), S(1.4), S(1.5), 4)                       # the ear
    g = outline(g, (2, 3, 4))
    def put(x, y, c):
        x, y = int(ox + S(x)), int(oy + S(y))
        if 0 <= x < 16 and 0 <= y < 16: g[y][x] = c
    put(12.2, 8.2, 5)                                                          # the eye
    put(15.2, 9.6, 4)                                                          # the nose
    for x, y in ((0.4, 10.8), (0.2, 11.8), (0.6, 12.8), (1.5, 13.4)):         # the tail
        put(x, y, 4)
    for fx in feet:                                                            # the feet
        put(fx, 13.6, 4)
    return g

def curled():
    g = grid(16, 16, 15)
    ell(g, 8, 10.5, 6.2, 4.4, 2, 3, 11.5)
    ell(g, 11.8, 8.4, 1.4, 1.5, 4)
    g = outline(g, (2, 3, 4))
    for x, y in ((3, 13), (4, 14), (6, 15), (9, 15), (11, 14)):              # the tail round it
        if g[y][x] == 15 or g[y][x] == 1: g[y][x] = 4
    g[9][13] = 5
    for x, y in ((12, 2), (13, 2), (14, 2), (13, 3), (12, 4), (13, 4), (14, 4)):   # a little z
        g[y][x] = 6
    return g

def marker():
    g = grid(16, 16, 15)
    for y in range(0, 9):
        w = 4 if y < 4 else 8 - (y - 4) * 2
        for x in range(8 - w // 2, 8 + w // 2):
            if w > 0: g[y][x] = 2
    return outline(g, (2,))

def heart():
    g = grid(16, 16, 15)
    ell(g, 5.2, 5.2, 3.6, 3.4, 2); ell(g, 10.8, 5.2, 3.6, 3.4, 2)
    for y in range(5, 14):
        for x in range(16):
            if abs(x + 0.5 - 8) <= (13.6 - y) * 0.85: g[y][x] = 2
    return outline(g, (2,))

def star():
    g = grid(16, 16, 15)
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = 7 if k % 2 == 0 else 3
        pts.append((8 + r * math.cos(a), 8 + r * math.sin(a)))
    for y in range(16):
        for x in range(16):
            px, py, ins = x + 0.5, y + 0.5, False
            j = len(pts) - 1
            for i in range(len(pts)):
                xi, yi = pts[i]; xj, yj = pts[j]
                if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi: ins = not ins
                j = i
            if ins: g[y][x] = 2
    return outline(g, (2,))

PATS = [rat((4.5, 9.5)), rat((5.5, 10.5)),                    # 0, 1 walking (right; mirrored: left)
        rat((5, 9), 0.62, 3.5, 6.5), rat((5.5, 9.5), 0.62, 3.5, 6.5),   # 2, 3 a baby
        curled(), marker(), heart(), star()]                 # 4 asleep, 5 the chosen one, 6, 7
P_WALK, P_BABY, P_SLEEP, P_MARK, P_HEART, P_STAR = 0, 2, 4, 5, 6, 7

# ---- the tiles (8 x 8)
rnd = random.Random(7)
def floor(var=0):
    g = grid(8, 8, 3)
    r = random.Random(11 + var)
    for _ in range(7):
        g[r.randrange(8)][r.randrange(8)] = 4
    return g

TILES = {}
def tile(name, g):
    TILES[name] = (len(TILES), g)

tile('floor', floor(0))
tile('floor2', floor(1))
g = grid(8, 8, 5)
for x in range(8): g[0][x] = 6; g[3][x] = 6; g[7][x] = 6
g[1][2] = 6; g[5][6] = 6
tile('wallh', g)
g = grid(8, 8, 5)
for y in range(8): g[y][0] = 6; g[y][3] = 6; g[y][7] = 6
tile('wallv', g)
g = grid(8, 8, 6); tile('corner', g)

def big(w, h, draw):          # a picture of w x h tiles: drawn on the floor, cut into tiles
    G = [[3 if (x * 7 + y * 13) % 11 else 4 for x in range(w * 8)] for y in range(h * 8)]
    draw(G)
    return [[[G[ty * 8 + y][tx * 8 + x] for x in range(8)] for y in range(8)] for ty in range(h) for tx in range(w)]

def nest(G):
    ell(G, 8, 9, 7.6, 5.6, 5); ell(G, 8, 8.6, 6.4, 4.4, 13)
    for x, y in ((4, 6), (7, 5), (10, 7), (6, 10), (11, 10), (9, 9)): G[y][x] = 5
for k, t in enumerate(big(2, 2, nest)): tile('bed%d' % k, t)
def bowl(G):
    ell(G, 8, 3.5, 6.5, 2.2, 13)
    for x, y in ((4, 2), (7, 1), (10, 2), (6, 3), (9, 3)): G[y][x] = 5
    for y in range(4, 8):
        for x in range(1 + (y - 4), 15 - (y - 4)): G[y][x] = 10 if y < 6 else 14
    for x in range(1, 15): G[4][x] = 11
for k, t in enumerate(big(2, 1, bowl)): tile('bowl%d' % k, t)
def wheel(G):
    ell(G, 8, 7, 7, 7, 11); ell(G, 8, 7, 5.5, 5.5, 3)
    for k in range(4):
        a = k * math.pi / 4
        for r in range(6):
            G[int(7 + r * math.sin(a))][int(8 + r * math.cos(a))] = 10
            G[int(7 - r * math.sin(a))][int(8 - r * math.cos(a))] = 10
    for y in range(13, 16):
        for x in range(5, 11): G[y][x] = 6
for k, t in enumerate(big(2, 2, wheel)): tile('wheel%d' % k, t)
def tv(on):
    def d(G):
        for y in range(0, 7):
            for x in range(1, 15): G[y][x] = 10
        for y in range(1, 6):
            for x in range(2, 14): G[y][x] = 9 if on else 14
        if on:
            for x, y in ((4, 2), (5, 2), (9, 3), (10, 4), (6, 4), (11, 2)): G[y][x] = 1
        G[7][5] = 6; G[7][10] = 6
    return d
for k, t in enumerate(big(2, 1, tv(0))): tile('tvoff%d' % k, t)
for k, t in enumerate(big(2, 1, tv(1))): tile('tvon%d' % k, t)
def cushion(G):
    for y in range(1, 7):
        for x in range(1, 15): G[y][x] = 7
    for x in range(1, 15): G[1][x] = 12; G[6][x] = 6
    G[3][4] = 6; G[3][11] = 6
for k, t in enumerate(big(2, 1, cushion)): tile('naughty%d' % k, t)
g = floor(2)
for x in range(8): g[3][x] = 7 if x % 4 < 2 else 1; g[4][x] = 7 if x % 4 < 2 else 1
tile('rope', g)
g = floor(3)
for y in range(1, 8):
    for x in range(2, 6): g[y][x] = 6
for x in range(2, 6): g[1][x] = 7
tile('post', g)
g = floor(4)
for y in range(1, 7):
    for x in range(2, 6): g[y][x] = 10
for x in range(1, 7): g[7][x] = 6
g[2][3] = 11; g[2][4] = 11; g[3][2] = 11; g[3][3] = 11; g[3][4] = 11; g[3][5] = 11; g[4][3] = 11; g[4][4] = 11
tile('grave', g)
g = floor(5)
for x in range(8): g[2][x] = 5; g[5][x] = 5
for x in (1, 5):
    for y in range(0, 8): g[y][x] = 6
tile('fence', g)
g = floor(6)
for x, y in ((3, 4), (4, 4), (4, 3), (5, 5), (2, 5), (3, 5), (4, 5)): g[y][x] = 6
tile('poo', g)
g = grid(8, 8, 0); tile('black', g)
assert len(TILES) <= 32, len(TILES)

# ---- RBGfx.cls
def nib(g):                  # 4 bits a pixel, the left one high
    out = []
    for row in g:
        for x in range(0, len(row), 2):
            out.append((row[x] << 4) | row[x + 1])
    return out

def dbs(label, data, per=16):
    lines = []
    for i in range(0, len(data), per):
        lines.append('%-12sdb %s' % (label if i == 0 else '', ', '.join('#%02X' % b for b in data[i:i + per])))
    return lines

tdata = []
for name, (n, g) in sorted(TILES.items(), key=lambda kv: kv[1][0]):
    tdata += nib(g)
pdata = []
for g in PATS:
    pdata += nib(g)

L = []
w = L.append
w("' RBGfx - RATBOXN's graphics: made by tools/rbgfx.py (don't edit: run it again). The tiles 0-%d" % (len(TILES) - 1))
w("' (8 x 8, 4 bits) and the font as tiles 32-127, the %d sprite patterns (16 x 16, 4 bits), the" % len(PATS))
w("' tilemap's and the sprites' palettes.")
w("' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License")
w("Option Explicit")
w("")
for name, (n, g) in sorted(TILES.items(), key=lambda kv: kv[1][0]):
    w("Public Const T_%s = %d" % (name.upper(), n))
w("Public Const P_WALK = %d, P_BABY = %d, P_SLEEP = %d, P_MARK = %d, P_HEART = %d, P_STAR = %d" % (P_WALK, P_BABY, P_SLEEP, P_MARK, P_HEART, P_STAR))
w("Public Const PAL_MALE = 0, PAL_FEMALE = 1, PAL_BABY = 2, PAL_OLD = 3, PAL_FIGHT = 4, PAL_ILL = 5, PAL_MARK = 6, PAL_HEART = 7")
w("")
w("' Load: bank 5's first page put in MMU slot 6 (#C000) for a moment - the program's own page back")
w("' after (it holds its arrays) -, the tiles to #CC00: ours, then the font (CyborgOS-Next's")
w("' console's: its tilemap's tiles 32-127 at bank 5 + #2C00, a bit a pixel) as tiles 32-127,")
w("' white on black -, the patterns to the sprite RAM, both palettes (the tilemap's first, the")
w("' sprites' first)")
w("Public Sub Load()")
w("#asm")
w("            ld hl, rg_tiles")
w("            ld de, #CC00")
w("            ld bc, %d" % len(tdata))
w("            ldir")
w("            ld bc, #243B            ; the font: CyborgOS's console's (its tilemap's tiles, a bit a")
w("            ld a, #57               ; pixel, bank 5 + #2C00: the second page, put in slot 7 for")
w("            out (c), a              ; this - the program's own page back after)")
w("            inc b")
w("            ld a, 11")
w("            out (c), a")
w("            ld de, #CC00 + 32 * 32  ; a bit a pixel -> 4 bits (1 white, 0 black)")
w("            ld hl, #E000 + #0C00 + 32 * 8")
w("            ld bc, 96 * 8")
w("rg_fr:")
w("            push bc")
w("            ld c, (hl)")
w("            ld b, 4")
w("rg_fp:")
w("            xor a")
w("            rl c")
w("            jr nc, rg_f0")
w("            or #10")
w("rg_f0:")
w("            rl c")
w("            jr nc, rg_f1")
w("            or #01")
w("rg_f1:")
w("            ld (de), a")
w("            inc de")
w("            djnz rg_fp")
w("            inc hl")
w("            pop bc")
w("            dec bc")
w("            ld a, b")
w("            or c")
w("            jr nz, rg_fr")
w("            ld bc, #243B            ; slot 7: the program's own page back")
w("            ld a, #57")
w("            out (c), a")
w("            inc b")
w("            ld a, (ls_h7)")
w("            out (c), a")
w("            ld bc, #303B            ; the patterns: from pattern slot 0")
w("            xor a")
w("            out (c), a")
w("            ld hl, rg_pats")
w("            ld de, %d" % len(pdata))
w("rg_pp:")
w("            ld a, (hl)")
w("            out (#5B), a")
w("            inc hl")
w("            dec de")
w("            ld a, d")
w("            or e")
w("            jr nz, rg_pp")
w("            ld bc, #243B            ; the palettes")
w("            ld a, #43")
w("            out (c), a")
w("            inc b")
w("            ld a, #30               ; the tilemap's first")
w("            out (c), a")
w("            dec b")
w("            ld hl, rg_tpal")
w("            ld e, 16")
w("            call rg_pal")
w("            ld a, #43")
w("            out (c), a")
w("            inc b")
w("            ld a, #20               ; the sprites' first")
w("            out (c), a")
w("            dec b")
w("            ld hl, rg_spal")
w("            ld e, %d" % len(SPAL))
w("            call rg_pal")
w("            jp rg_end")
w("rg_pal:                             ; (on the real stack: CyborgOS's tasks run their asm on the")
w("            ld a, #40               ; thread, so this is jumped round - see below)")
w("            out (c), a")
w("            inc b")
w("            xor a")
w("            out (c), a")
w("            dec b")
w("            ld a, #41")
w("            out (c), a")
w("            inc b")
w("rg_pl:")
w("            ld a, (hl)")
w("            out (c), a")
w("            inc hl")
w("            dec e")
w("            jr nz, rg_pl")
w("            dec b")
w("            ret")
L += dbs('rg_tpal:', TPAL)
L += dbs('rg_spal:', SPAL)
L += dbs('rg_tiles:', tdata)
L += dbs('rg_pats:', pdata)
w("rg_end:")
w("#endasm")
w("End Sub")
src = '\n'.join(L) + '\n'
# the two calls: SP is the thread in NTC's code, so a call needs the real stack - the routine is
# entered with it (ld (x), sp / ld sp, (ntc_csp)) and left with SP back
src = src.replace("            ld hl, rg_tiles\n", "            ld (rg_sp), sp\n            ld sp, (ntc_csp)\n            ld bc, #243B            ; slot 6: its page now noted, bank 5's first in\n            ld a, #56\n            out (c), a\n            inc b\n            in a, (c)\n            ld (rg_s6), a\n            ld a, 10\n            out (c), a\n            ld hl, rg_tiles\n", 1)
src = src.replace("            jp rg_end\n", "            ld a, #56               ; slot 6: the program's own page back\n            out (c), a\n            inc b\n            ld a, (rg_s6)\n            out (c), a\n            ld sp, (rg_sp)\n            jp rg_end\nrg_sp:      dw 0\nrg_s6:      db 0\n", 1)
open(os.path.join(ROOT, 'RBGfx.cls'), 'w').write(src)

# ---- pictures to look at
try:
    from PIL import Image
    os.makedirs(os.path.join(ROOT, 'gfx'), exist_ok=True)
    def c8(v): return (((v >> 5) & 7) * 255 // 7, ((v >> 2) & 7) * 255 // 7, (v & 3) * 255 // 3)
    im = Image.new('RGB', (8 * 8, 8 * ((len(TILES) + 7) // 8)))
    for name, (n, g) in TILES.items():
        for y in range(8):
            for x in range(8): im.putpixel(((n % 8) * 8 + x, (n // 8) * 8 + y), c8(TPAL[g[y][x]]))
    im.resize((im.width * 4, im.height * 4), Image.NEAREST).save(os.path.join(ROOT, 'gfx', 'tiles.png'))
    im = Image.new('RGB', (16 * len(PATS), 16 * 8), (40, 40, 40))
    for row in range(8):
        for k, g in enumerate(PATS):
            for y in range(16):
                for x in range(16):
                    if g[y][x] != 15: im.putpixel((k * 16 + x, row * 16 + y), c8(SPAL[row * 16 + g[y][x]]))
    im.resize((im.width * 4, im.height * 4), Image.NEAREST).save(os.path.join(ROOT, 'gfx', 'sprites.png'))
except ImportError:
    pass
print('RBGfx.cls: %d tiles, %d patterns, %d bytes of data' % (len(TILES), len(PATS), len(tdata) + len(pdata) + 16 + len(SPAL)))
