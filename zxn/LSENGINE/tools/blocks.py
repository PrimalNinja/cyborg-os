# blocks.py - LITTLE SEOUL's city blocks: 16 x 16 pictures in Layer 2's colours (one byte a pixel,
# RRRGGGBB), the streets, shopfronts, landmarks and insides of everything. The town is put together
# from these (tools/city.py): a shop is a group of them (a roof, a sign, a window, a door).
# Writes tools/blocks.bin (256 bytes a block, up to 256) and tools/blocks_preview.png.
# Each block has attributes (city.py reads ATTR): what it does when you walk into it.
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import os, math, random
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))

def C(r, g, b): return (r << 5) | (g << 2) | b
def rgb(c): return ((c >> 5) * 255 // 7, ((c >> 2) & 7) * 255 // 7, (c & 3) * 255 // 3)

# attributes
SOLID, DOOR, WATER, ROAD, COUNTER, LIFT, STAIRS, THING = 1, 2, 4, 8, 16, 32, 64, 128

class B:
    def __init__(s, base=0):
        s.p = [[base] * 16 for _ in range(16)]
    def set(s, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < 16 and 0 <= y < 16 and c is not None: s.p[y][x] = c
    def rect(s, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1): s.set(x, y, c)
    def box(s, x0, y0, x1, y1, c):
        s.rect(x0, y0, x1, y0, c); s.rect(x0, y1, x1, y1, c); s.rect(x0, y0, x0, y1, c); s.rect(x1, y0, x1, y1, c)
    def circle(s, cx, cy, r, c):
        for y in range(16):
            for x in range(16):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r: s.set(x, y, c)
    def noise(s, cols, n, seed):
        r = random.Random(seed)
        for k in range(n): s.set(r.randrange(16), r.randrange(16), r.choice(cols))
    def hline(s, y, c, x0=0, x1=15): s.rect(x0, y, x1, y, c)
    def vline(s, x, c, y0=0, y1=15): s.rect(x, y0, x, y1, c)
    def copy(s):
        b = B(); b.p = [r[:] for r in s.p]; return b

BLACK = C(0, 0, 0); WHITE = C(7, 7, 3); GREY = C(4, 4, 2); DGREY = C(2, 2, 1); LGREY = C(5, 5, 2)
GRASS = C(1, 5, 0); GRASS2 = C(1, 4, 0); DGREEN = C(0, 3, 0); TREE = C(0, 4, 0); TREE2 = C(1, 6, 0)
ASPH = C(1, 1, 1); ASPH2 = C(2, 2, 1); YEL = C(7, 6, 0); RED = C(6, 0, 0); BLUE = C(0, 2, 3)
WATER_C = C(0, 3, 3); WATER2_C = C(1, 4, 3); SAND_C = C(6, 5, 1); WOOD = C(4, 2, 0); DWOOD = C(2, 1, 0)
SKIN = C(7, 5, 2); GLASS = C(2, 4, 3); GLASS2 = C(3, 5, 3); CREAM = C(7, 6, 2); BRICK = C(5, 1, 0)

BLOCKS = []        # (name, attr, B)
def add(name, attr, b):
    BLOCKS.append((name, attr, b))

# ---------------------------------------------------------------- the ground
def grass(seed, flowers=False):
    b = B(GRASS); b.noise([GRASS2, C(2, 5, 0)], 40, seed)
    if flowers:
        b.noise([C(7, 3, 2), YEL, WHITE], 8, seed + 1)
    return b
add('GRASS', 0, grass(1))
add('FLOWERS', 0, grass(2, True))
def pave(seed):
    b = B(LGREY)
    for y in range(0, 16, 4):
        b.hline(y, GREY)
        off = 0 if (y // 4) % 2 == 0 else 4
        for x in range(off, 16, 8): b.vline(x, GREY, y, y + 3)
    b.noise([C(4, 4, 1)], 6, seed)
    return b
P = pave(3); add('PAVE', 0, P)
b = P.copy(); b.rect(0, 14, 15, 15, DGREY); b.hline(13, WHITE); add('PAVE_KB', 0, b)      # a kerb below
b = P.copy(); b.rect(0, 0, 15, 1, DGREY); b.hline(2, WHITE); add('PAVE_KT', 0, b)        # a kerb above
def road(seed):
    b = B(ASPH); b.noise([ASPH2, C(1, 1, 0)], 30, seed); return b
b = road(5); b.rect(0, 15, 5, 15, YEL); b.rect(9, 15, 14, 15, YEL); add('ROAD_T', ROAD, b)
b = road(6); add('ROAD_B', ROAD, b)
b = road(7)
for x in range(1, 16, 4): b.rect(x, 0, x + 1, 15, WHITE)
add('ZEBRA', ROAD, b)
b = B(C(5, 5, 2)); b.noise([C(4, 4, 2), C(6, 6, 2)], 30, 8); add('LANE', 0, b)         # an alley
def stone(seed):
    b = B(C(5, 4, 2))
    for y in (0, 8): b.hline(y, C(3, 3, 1))
    for x in (0, 8): b.vline(x, C(3, 3, 1), 0, 7)
    for x in (4, 12): b.vline(x, C(3, 3, 1), 8, 15)
    b.noise([C(6, 5, 2)], 10, seed); return b
add('STONE', 0, stone(9))
b = B(C(5, 3, 1)); b.noise([C(4, 3, 1), C(6, 4, 1)], 40, 10); add('DIRT', 0, b)
b = B(SAND_C); b.noise([C(7, 6, 1), C(5, 4, 1)], 30, 11); add('SAND', 0, b)
def water(seed):
    b = B(WATER_C); r = random.Random(seed)
    for k in range(6):
        x = r.randrange(12); y = r.randrange(16); b.rect(x, y, x + 3, y, WATER2_C)
    return b
add('WATER', WATER | SOLID, water(12))
b = water(13); b.rect(0, 0, 15, 5, GRASS); b.noise([GRASS2], 10, 3); b.rect(0, 6, 15, 7, C(4, 4, 2)); add('BANK_T', WATER | SOLID, b)
b = water(14); b.rect(0, 10, 15, 15, GRASS); b.noise([GRASS2], 10, 4); b.rect(0, 8, 15, 9, C(4, 4, 2)); add('BANK_B', WATER | SOLID, b)
b = B(C(4, 4, 2)); b.noise([C(3, 3, 1)], 20, 15); b.rect(0, 0, 1, 15, C(6, 0, 0)); b.rect(2, 0, 2, 15, DGREY)
for y in range(0, 16, 4): b.set(0, y, WHITE)
add('BRIDGE_L', 0, b)
b = B(C(4, 4, 2)); b.noise([C(3, 3, 1)], 20, 16); b.rect(14, 0, 15, 15, C(6, 0, 0)); b.rect(13, 0, 13, 15, DGREY)
for y in range(0, 16, 4): b.set(15, y, WHITE)
add('BRIDGE_R', 0, b)

# ---------------------------------------------------------------- things in the street (solid)
def tree(base, seed, pine=False):
    b = base.copy()
    b.circle(8, 12.5, 3, C(0, 1, 0))                     # its shadow
    if pine:
        for k in range(4):
            b.rect(8 - k * 1.5 - 1, 2 + k * 3, 8 + k * 1.5, 4 + k * 3, C(0, 3, 0))
        b.rect(7, 13, 8, 15, DWOOD)
    else:
        b.circle(8, 7, 6.5, TREE); b.circle(7, 6, 4.5, TREE2); b.circle(6, 4.5, 2, C(3, 7, 1))
        b.rect(7, 13, 8, 15, DWOOD)
    return b
G = grass(20)
add('TREE', SOLID, tree(G, 1))
add('PINE', SOLID, tree(G, 2, True))
add('STREET_TREE', SOLID, tree(P, 3))
b = G.copy(); b.circle(8, 9, 6, C(0, 4, 0)); b.circle(7, 8, 4, C(1, 5, 0)); b.noise([C(7, 3, 2)], 5, 3); add('BUSH', SOLID, b)
b = P.copy(); b.rect(1, 6, 14, 9, WOOD); b.hline(7, DWOOD); b.rect(2, 10, 2, 12, DGREY); b.rect(13, 10, 13, 12, DGREY); add('BENCH', SOLID, b)
b = P.copy(); b.rect(7, 2, 8, 14, DGREY); b.rect(5, 0, 10, 2, C(3, 3, 1)); b.rect(6, 2, 9, 3, YEL); b.rect(6, 14, 9, 15, BLACK); add('LAMP', SOLID, b)
b = P.copy(); b.rect(0, 2, 15, 4, C(0, 3, 1)); b.rect(1, 5, 1, 13, DGREY); b.rect(14, 5, 14, 13, DGREY); b.rect(2, 5, 13, 10, GLASS2); b.rect(3, 6, 8, 8, C(7, 7, 2))
b.rect(2, 11, 13, 12, WOOD); add('BUSSTOP', SOLID, b)
b = P.copy(); b.rect(2, 0, 13, 15, C(6, 0, 0)); b.rect(3, 1, 12, 8, GLASS2)
for y in (2, 4, 6):
    for x in (4, 7, 10): b.rect(x, y, x + 1, y + 1, [C(7, 0, 0), YEL, C(0, 6, 3)][x % 3])
b.rect(4, 10, 11, 11, BLACK); b.rect(4, 13, 11, 14, DGREY); add('VENDING', SOLID | THING, b)
b = P.copy(); b.rect(4, 2, 11, 14, C(6, 0, 0)); b.rect(4, 2, 11, 3, C(7, 2, 1)); b.rect(5, 6, 10, 6, BLACK); b.rect(6, 9, 9, 10, WHITE); b.rect(4, 14, 11, 15, DGREY)
add('POSTBOX', SOLID | THING, b)
b = P.copy(); b.rect(1, 4, 14, 14, C(4, 2, 1)); b.rect(2, 3, 13, 9, C(0, 4, 0)); b.noise([C(7, 2, 3), YEL, C(7, 1, 0)], 10, 5); add('PLANTER', SOLID, b)
b = G.copy(); b.rect(0, 6, 15, 7, WHITE); b.rect(0, 11, 15, 11, WHITE)
for x in (1, 7, 13): b.rect(x, 5, x + 1, 13, WHITE)
add('FENCE', SOLID, b)
b = G.copy(); b.circle(8, 9, 6, C(4, 4, 2)); b.circle(7, 8, 4, C(5, 5, 2)); b.circle(6, 6.5, 1.5, C(6, 6, 3)); add('ROCK', SOLID, b)
# the subway: a sign on a pole, and the stairs down
b = P.copy(); b.rect(7, 6, 8, 15, DGREY); b.circle(8, 4, 4, C(0, 3, 3)); b.circle(8, 4, 2.5, WHITE); b.rect(6, 3, 9, 4, C(0, 3, 3)); add('SUBWAY_SIGN', SOLID, b)
b = B(C(3, 3, 1))
for y in range(2, 16, 2): b.rect(1, y, 14, y, C(5, 5, 2)); b.rect(1, y + 1, 14, y + 1, C(2, 2, 1))
b.rect(0, 0, 0, 15, C(0, 3, 3)); b.rect(15, 0, 15, 15, C(0, 3, 3)); b.rect(0, 0, 15, 1, C(0, 3, 3))
add('SUBWAY_STAIRS', STAIRS, b)
# a statue on a plinth (two blocks: top, bottom)
b = B(C(5, 4, 2)); b.rect(5, 6, 10, 15, C(1, 2, 1)); b.circle(8, 4, 2.6, C(1, 2, 1)); b.rect(3, 7, 4, 12, C(1, 2, 1)); b.rect(11, 8, 12, 15, C(2, 3, 1))
b.rect(2, 13, 13, 14, C(1, 2, 1)); add('STATUE_T', SOLID, b)
b = B(C(5, 4, 2)); b.rect(2, 0, 13, 13, C(6, 6, 2)); b.rect(2, 0, 13, 1, C(7, 7, 3)); b.rect(1, 13, 14, 15, C(4, 4, 2)); add('STATUE_B', SOLID, b)
b = stone(30); b.circle(8, 8, 7, C(4, 4, 2)); b.circle(8, 8, 5.5, WATER2_C); b.circle(8, 8, 2, WHITE); add('FOUNTAIN', SOLID, b)
b = B(C(5, 0, 0)); b.rect(0, 0, 15, 3, C(1, 1, 1));
for x in range(0, 16, 4): b.rect(x, 0, x + 2, 2, C(2, 2, 1))
b.rect(0, 4, 15, 15, C(6, 2, 1)); b.hline(10, C(5, 1, 1)); add('PWALL', SOLID, b)     # a palace wall
b = B(C(1, 1, 1))
for x in range(0, 16, 4): b.rect(x, 4, x + 2, 15, C(2, 2, 1))
b.rect(0, 0, 15, 3, C(3, 3, 1)); add('PWALL_TOP', SOLID, b)
b = B(C(3, 2, 1)); b.noise([C(4, 3, 1), C(2, 1, 0)], 50, 31)
for y in (4, 11): b.rect(0, y, 15, y, C(2, 1, 0))
add('MARKET_STALL', SOLID | COUNTER, b)
b = B(C(6, 0, 0)); b.rect(0, 0, 15, 3, C(7, 1, 1))
for x in range(0, 16, 4): b.rect(x, 0, x + 1, 15, C(7, 6, 2))
b.rect(1, 12, 14, 15, C(3, 2, 1)); b.noise([YEL, C(7, 3, 0), C(5, 0, 0)], 12, 32); add('MARKET_AWN', SOLID | COUNTER, b)
b = road(40); b.rect(0, 6, 15, 9, C(1, 1, 1)); b.rect(2, 0, 3, 15, C(3, 2, 1)); b.rect(12, 0, 13, 15, C(3, 2, 1))
for x in range(4, 12, 3): b.rect(x, 6, x + 1, 9, C(4, 4, 2))
add('RAILS', SOLID, b)

# ---------------------------------------------------------------- roofs (the top row of a building)
def roof_flat(seed, base=C(5, 5, 2), extra=0):
    b = B(base); b.box(0, 0, 15, 15, C(4, 4, 2)); b.hline(15, C(3, 3, 1)); b.noise([C(4, 4, 1)], 10, seed)
    if extra == 1: b.rect(3, 3, 8, 8, C(6, 6, 3)); b.rect(4, 4, 7, 7, C(4, 4, 2)); b.circle(5.5, 5.5, 1.5, DGREY)    # an air conditioner
    if extra == 2: b.circle(10, 7, 4, C(3, 4, 3)); b.rect(6, 7, 14, 10, C(2, 3, 3))                               # a water tank
    if extra == 3: b.rect(2, 2, 13, 12, C(1, 5, 0)); b.noise([C(7, 3, 2), YEL, C(0, 3, 0)], 16, seed)                # a roof garden
    return b
add('ROOF', SOLID, roof_flat(50))
add('ROOF_AC', SOLID, roof_flat(51, extra=1))
add('ROOF_TANK', SOLID, roof_flat(52, extra=2))
add('ROOF_GARDEN', SOLID, roof_flat(53, extra=3))
b = roof_flat(54, C(3, 4, 3)); add('ROOF_BLUE', SOLID, b)
b = roof_flat(55, C(6, 3, 1)); add('ROOF_RED', SOLID, b)
def hanok_roof(eave_l=False, eave_r=False, palace=False):
    b = B(C(2, 2, 2)); base = C(2, 2, 2) if not palace else C(2, 2, 1)
    for y in range(0, 16):
        for x in range(16):
            b.set(x, y, C(3, 3, 2) if (x % 3 == 0) else base)
    b.rect(0, 0, 15, 1, C(1, 1, 1))
    b.rect(0, 13, 15, 15, C(1, 1, 1) if not palace else C(0, 4, 2))     # the eave (green under a palace's)
    if palace:
        for x in range(0, 16, 4): b.rect(x, 14, x + 1, 14, C(6, 0, 0))
    if eave_l:
        for y in range(16):
            for x in range(16):
                if x < 4 - y // 4: b.set(x, y, None)
        b.rect(0, 12, 2, 15, C(1, 1, 1))
    if eave_r:
        b.rect(13, 12, 15, 15, C(1, 1, 1))
    return b
add('HROOF', SOLID, hanok_roof())
add('HROOF_L', SOLID, hanok_roof(eave_l=True))
add('HROOF_R', SOLID, hanok_roof(eave_r=True))
add('PROOF', SOLID, hanok_roof(palace=True))
add('PROOF_L', SOLID, hanok_roof(eave_l=True, palace=True))
add('PROOF_R', SOLID, hanok_roof(eave_r=True, palace=True))

# ---------------------------------------------------------------- walls, signs, windows, doors
def wall(col, win=None, seed=0):
    b = B(col); b.noise([col ^ 0x24 & col], 0, seed)
    b.hline(0, C(3, 3, 1))
    if win:
        for x0 in (2, 9):
            b.rect(x0, 4, x0 + 4, 11, BLACK); b.rect(x0 + 1, 5, x0 + 3, 10, win); b.set(x0 + 1, 5, WHITE)
    return b
add('WALL', SOLID, wall(C(6, 6, 2), GLASS))
add('WALL_BRICK', SOLID, wall(BRICK, GLASS))
b = wall(C(5, 5, 3)); b.rect(0, 2, 15, 9, GLASS); b.rect(0, 10, 15, 11, WHITE); b.rect(1, 12, 14, 13, DGREY)
for x in (3, 7, 11): b.rect(x, 2, x, 9, WHITE)
add('WALL_BALC', SOLID, b)                       # apartment balconies
b = B(GLASS)
for y in range(0, 16, 4): b.hline(y, C(1, 2, 2))
for x in (0, 8): b.vline(x, C(1, 2, 2))
b.rect(1, 1, 3, 2, GLASS2); b.rect(9, 5, 11, 6, GLASS2); add('GLASSWALL', SOLID, b)
b = B(C(6, 5, 0))
for y in range(0, 16, 4): b.hline(y, C(4, 3, 0))
for x in (0, 8): b.vline(x, C(4, 3, 0))
b.rect(1, 1, 3, 2, C(7, 7, 1)); add('GOLDWALL', SOLID, b)
b = B(C(5, 5, 3))
for y in range(0, 16, 3): b.hline(y, C(6, 6, 3))
b.rect(0, 0, 15, 15, None); add('SILVERWALL', SOLID, b)
b = B(CREAM); b.rect(0, 0, 15, 1, DWOOD); b.rect(0, 0, 1, 15, DWOOD); b.rect(14, 0, 15, 15, DWOOD); b.rect(0, 14, 15, 15, C(3, 3, 2))
b.rect(4, 4, 11, 11, WOOD)
for k in range(5, 11, 2): b.hline(k, CREAM, 5, 10); b.vline(k, CREAM, 5, 10)
add('HWALL', SOLID, b)                           # a hanok wall with a lattice window
b = B(C(5, 1, 0)); b.rect(0, 0, 15, 15, C(4, 0, 0)); b.rect(2, 0, 3, 15, C(6, 1, 0)); b.rect(12, 0, 13, 15, C(6, 1, 0))
b.rect(4, 2, 11, 13, C(5, 2, 0))
for k in range(3, 13, 2): b.hline(k, C(6, 4, 1), 5, 10)
b.rect(0, 14, 15, 15, C(5, 5, 2)); add('PHALL', SOLID, b)  # a palace hall's front: red pillars, lattice doors
b = B(C(5, 5, 2)); b.rect(0, 0, 15, 3, C(6, 6, 3)); b.hline(7, C(4, 4, 2)); b.hline(11, C(4, 4, 2)); b.hline(15, C(4, 4, 2)); add('STEPS', 0, b)
SIGNS = [C(6, 0, 0), C(0, 2, 3), C(0, 4, 1), C(5, 0, 2), C(7, 4, 0), C(1, 1, 1), C(4, 0, 3), C(0, 4, 3)]
for k, sc in enumerate(SIGNS):
    b = B(sc); b.rect(0, 0, 15, 0, C(4, 4, 2)); b.hline(1, WHITE); b.hline(15, C(1, 1, 1))
    for x in range(2, 14, 4): b.rect(x, 3, x + 1, 5, WHITE if k != 7 else YEL)
    add('SIGN%d' % k, SOLID, b)
AWNS = [(C(6, 0, 0), WHITE), (C(0, 4, 1), WHITE), (C(0, 2, 3), C(7, 7, 2)), (C(7, 4, 0), C(7, 6, 2))]
for k, (a, c2) in enumerate(AWNS):
    b = B(C(5, 5, 2)); b.rect(0, 0, 15, 1, C(4, 4, 2))
    b.rect(0, 2, 15, 12, a)
    for x in range(0, 16, 4): b.rect(x, 2, x + 1, 12, c2)
    for x in range(0, 16, 4): b.rect(x, 13, x + 1, 14, a)
    add('AWN%d' % k, SOLID, b)
def window(goods, seed):
    b = B(C(4, 4, 2)); b.rect(0, 0, 15, 1, C(3, 3, 1)); b.rect(1, 2, 14, 14, GLASS); b.rect(1, 2, 14, 3, GLASS2)
    r = random.Random(seed)
    for k in range(6):
        x = 2 + r.randrange(11); b.rect(x, 9 + r.randrange(3), x + 1, 13, r.choice(goods))
    b.rect(0, 15, 15, 15, DGREY); return b
add('SHOPWIN', SOLID, window([C(7, 2, 2), YEL, C(0, 5, 3), WHITE], 60))
add('SHOPWIN2', SOLID, window([C(0, 5, 0), C(1, 6, 1), C(4, 2, 0)], 61))     # plants, a cafe
add('SHOPWIN3', SOLID, window([C(7, 3, 3), C(7, 5, 3), C(5, 2, 3)], 62))      # pinks: beauty, fashion
b = B(C(4, 4, 2)); b.rect(0, 0, 15, 1, C(3, 3, 1)); b.rect(2, 2, 13, 15, BLACK); b.rect(3, 3, 7, 15, GLASS); b.rect(8, 3, 12, 15, GLASS)
b.rect(3, 3, 7, 4, GLASS2); b.rect(6, 9, 6, 10, WHITE); b.rect(9, 9, 9, 10, WHITE); add('DOOR', DOOR, b)
b = B(C(4, 4, 2)); b.rect(0, 0, 15, 1, C(3, 3, 1)); b.rect(1, 2, 14, 15, BLACK); b.rect(2, 3, 13, 15, GLASS2); b.vline(7, BLACK, 3, 15); b.vline(8, BLACK, 3, 15)
b.rect(2, 3, 13, 4, WHITE); add('DOOR_BIG', DOOR, b)
b = B(CREAM); b.rect(0, 0, 15, 1, DWOOD); b.rect(3, 2, 12, 15, DWOOD); b.rect(4, 3, 7, 15, WOOD); b.rect(8, 3, 11, 15, WOOD); b.set(7, 9, YEL); b.set(8, 9, YEL)
add('HDOOR', DOOR, b)
b = B(C(5, 1, 0)); b.rect(2, 0, 3, 15, C(6, 1, 0)); b.rect(12, 0, 13, 15, C(6, 1, 0)); b.rect(4, 0, 11, 15, C(1, 0, 0)); b.rect(5, 1, 10, 15, C(4, 2, 0)); b.vline(7, C(2, 1, 0), 1, 15)
b.rect(0, 14, 15, 15, C(5, 5, 2)); add('PDOOR', DOOR, b)
b = B(C(4, 4, 2)); b.rect(0, 0, 15, 1, C(3, 3, 1))
for y in range(2, 16, 2): b.rect(1, y, 14, y, C(5, 5, 3)); b.rect(1, y + 1, 14, y + 1, C(3, 3, 2))
add('SHUTTER', SOLID, b)
b = B(C(5, 5, 2)); b.rect(0, 0, 15, 15, C(6, 6, 2)); b.rect(1, 1, 14, 14, C(5, 4, 2)); b.rect(4, 2, 11, 15, C(1, 1, 1)); b.rect(5, 3, 10, 15, C(2, 3, 3)); b.rect(5, 3, 10, 4, WHITE)
add('HOUSEDOOR', DOOR, b)
# a stone gate (two blocks across): the arch is walked through
b = B(C(5, 5, 3)); b.noise([C(4, 4, 2)], 30, 70)
for y in range(0, 16, 5): b.hline(y, C(4, 4, 2))
add('GATESTONE', SOLID, b)
b = B(C(5, 5, 3)); b.noise([C(4, 4, 2)], 20, 71); b.rect(3, 4, 12, 15, C(1, 1, 1)); b.circle(7.5, 5, 4.6, C(1, 1, 1)); b.rect(5, 6, 10, 15, C(2, 1, 0))
add('GATEARCH', 0, b)
# landmarks' parts
b = B(C(0, 3, 3)); b.circle(8, 16, 11, C(1, 5, 3)); b.circle(6, 13, 5, C(2, 6, 3))
for y in range(16):
    for x in range(16):
        if (x - 8) ** 2 + (y - 16) ** 2 > 121: b.set(x, y, C(5, 5, 2))
add('DOME_L', SOLID, b)
b2 = B(); b2.p = [r[::-1] for r in b.p]; add('DOME_R', SOLID, b2)
b = B(C(5, 5, 2)); b.rect(6, 0, 9, 15, WHITE); b.rect(7, 0, 7, 15, C(5, 5, 3)); add('MAST', SOLID, b)      # a tower's shaft
b = B(C(5, 5, 2)); b.rect(1, 3, 14, 12, WHITE); b.rect(1, 6, 14, 9, GLASS); b.rect(0, 5, 15, 5, C(5, 5, 3)); b.rect(0, 10, 15, 10, C(5, 5, 3)); add('POD', SOLID, b)
b = B(C(5, 5, 2)); b.rect(7, 0, 8, 15, C(6, 0, 0)); b.rect(7, 0, 8, 1, WHITE); b.rect(7, 4, 8, 5, WHITE); b.rect(7, 8, 8, 9, WHITE); add('ANTENNA', SOLID, b)
b = B(C(5, 5, 2))
for y in range(16):
    w = 2 + y // 2; b.rect(8 - w, y, 7 + w, y, GLASS if y % 4 else C(1, 2, 2))
add('SPIRE', SOLID, b)
b = B(BRICK)
for y in range(0, 16, 4): b.hline(y, C(4, 1, 0))
b.rect(2, 3, 5, 12, WHITE); b.rect(3, 4, 4, 12, GLASS); b.rect(10, 3, 13, 12, WHITE); b.rect(11, 4, 12, 12, GLASS); add('OLDBRICK', SOLID, b)

# ---------------------------------------------------------------- inside
def floor(kind, seed):
    if kind == 'wood':
        b = B(C(5, 3, 1))
        for y in range(0, 16, 4): b.hline(y, C(4, 2, 0))
        for y in range(0, 16, 4): b.set((y * 5 + 3) % 16, y + 2, C(4, 2, 0))
        return b
    if kind == 'tile':
        b = B(WHITE)
        for y in range(16):
            for x in range(16):
                if ((x // 8) + (y // 8)) % 2: b.set(x, y, C(6, 6, 3))
        return b
    if kind == 'carpet': b = B(C(5, 0, 1)); b.noise([C(4, 0, 1), C(6, 1, 1)], 30, seed); return b
    if kind == 'grey': b = B(C(4, 4, 3)); b.noise([C(3, 3, 2)], 20, seed); return b
    if kind == 'marble':
        b = B(C(6, 6, 3)); b.noise([C(5, 5, 3), WHITE], 30, seed); b.hline(0, C(5, 5, 2)); b.vline(0, C(5, 5, 2)); return b
    if kind == 'ondol': b = B(C(6, 5, 1)); b.hline(0, C(5, 4, 1)); b.vline(0, C(5, 4, 1)); b.hline(8, C(5, 4, 1)); return b
    if kind == 'green': b = B(C(1, 4, 1)); b.noise([C(1, 3, 1)], 20, seed); return b
FW = floor('wood', 80); add('F_WOOD', 0, FW)
FT = floor('tile', 81); add('F_TILE', 0, FT)
add('F_CARPET', 0, floor('carpet', 82))
FG = floor('grey', 83); add('F_GREY', 0, FG)
FM = floor('marble', 84); add('F_MARBLE', 0, FM)
add('F_ONDOL', 0, floor('ondol', 85))
add('F_GYM', 0, floor('green', 86))
b = FG.copy(); b.rect(0, 12, 15, 13, YEL)
for x in range(0, 16, 3): b.set(x, 12, C(5, 4, 0))
add('F_PLATFORM', 0, b)
# the back wall: its top row, then a feature in the row under it
def bwall(col=CREAM):
    b = B(col); b.rect(0, 13, 15, 15, C(3, 2, 1)); return b
add('W_TOP', SOLID, B(C(3, 2, 1)))
add('W_PLAIN', SOLID, bwall())
b = bwall(C(7, 6, 3)); b.rect(0, 0, 15, 12, WHITE); b.hline(4, C(6, 6, 3)); b.hline(8, C(6, 6, 3)); b.vline(4, C(6, 6, 3), 0, 12); b.vline(12, C(6, 6, 3), 0, 12)
add('W_TILE', SOLID, b)
b = bwall(C(4, 2, 1)); b.rect(0, 0, 15, 12, C(4, 2, 1));
for x in range(0, 16, 5): b.vline(x, C(3, 1, 0), 0, 12)
add('W_WOOD', SOLID, b)
b = bwall(); b.rect(1, 1, 14, 11, C(1, 1, 1)); b.rect(2, 2, 13, 10, BLACK)
for y in (3, 5, 7, 9): b.rect(3, y, 7 + (y % 3), y, WHITE); b.rect(10, y, 12, y, YEL)
add('W_MENU', SOLID, b)
b = bwall(); b.rect(3, 1, 12, 11, C(7, 3, 2)); b.rect(5, 3, 10, 8, C(7, 6, 3)); b.circle(7.5, 5, 2, SKIN); b.rect(4, 9, 11, 10, WHITE); add('W_POSTER', SOLID, b)
b = bwall(); b.rect(1, 1, 14, 11, WHITE); b.rect(2, 2, 13, 10, C(3, 5, 3)); b.rect(2, 7, 13, 10, C(2, 4, 1)); b.vline(7, WHITE, 2, 10); add('W_WINDOW', SOLID, b)
b = bwall(); b.rect(0, 4, 15, 4, DWOOD); b.rect(0, 9, 15, 9, DWOOD); r = random.Random(3)
for x in range(1, 15, 3): b.rect(x, 1, x + 1, 3, r.choice([C(7, 2, 2), C(0, 5, 3), YEL])); b.rect(x, 6, x + 1, 8, r.choice([C(6, 0, 3), C(0, 6, 0), WHITE]))
add('W_SHELF', SOLID, b)
b = bwall(); b.rect(2, 1, 13, 11, C(5, 5, 2)); b.rect(3, 2, 12, 10, C(5, 6, 3)); b.rect(4, 3, 5, 6, WHITE); add('W_MIRROR', SOLID, b)
b = bwall(C(1, 0, 1)); b.rect(0, 0, 15, 12, C(1, 0, 1)); b.rect(1, 1, 14, 10, BLACK); b.rect(2, 2, 13, 9, C(1, 1, 3)); b.rect(3, 6, 12, 7, YEL); b.rect(4, 3, 7, 4, C(7, 2, 3))
add('W_SCREEN', SOLID, b)
b = bwall(C(1, 1, 1)); b.rect(0, 0, 15, 12, C(1, 1, 2)); r = random.Random(9)
for k in range(30): b.set(r.randrange(16), r.randrange(8), r.choice([YEL, WHITE, C(7, 4, 0)]))
b.rect(0, 8, 15, 12, C(2, 2, 2)); b.rect(0, 0, 0, 12, WHITE); b.rect(15, 0, 15, 12, WHITE); add('W_VIEW', SOLID, b)   # the city at night from up high
b = B(C(3, 2, 1)); b.rect(0, 0, 15, 15, C(4, 4, 2)); b.rect(1, 1, 14, 15, C(5, 5, 3)); b.vline(7, C(3, 3, 2), 1, 15); b.vline(8, C(3, 3, 2), 1, 15)
b.rect(5, 6, 6, 7, C(3, 3, 2)); b.rect(9, 6, 10, 7, C(3, 3, 2)); add('LIFT', SOLID | LIFT, b)
b = B(C(3, 2, 1)); b.rect(4, 4, 11, 11, BLACK); b.rect(6, 6, 9, 9, C(7, 2, 0)); add('LIFT_TOP', SOLID, b)
b = B(C(3, 2, 1))
for y in range(0, 16, 3): b.rect(1, y, 14, y + 1, C(5, 4, 2))
b.rect(0, 0, 0, 15, C(2, 1, 0)); b.rect(15, 0, 15, 15, C(2, 1, 0)); add('STAIRS_UP', SOLID | LIFT, b)
b = bwall(); b.rect(3, 0, 12, 15, C(1, 2, 3)); b.rect(4, 1, 11, 15, C(2, 3, 3)); b.rect(10, 7, 10, 8, YEL); b.rect(6, 3, 9, 4, WHITE); add('APTDOOR', SOLID | DOOR | THING, b)
b = bwall(C(5, 5, 2)); b.rect(0, 0, 15, 12, C(5, 5, 2))
for y in (1, 5, 9):
    for x in (1, 5, 9, 13): b.rect(x, y, x + 2, y + 2, C(4, 4, 3)); b.set(x + 1, y + 1, BLACK)
add('MAILBOXES', SOLID | THING, b)
add('W_SIDE', SOLID, B(C(3, 2, 1)))
b = B(C(3, 2, 1)); b.rect(0, 0, 15, 5, C(4, 3, 1)); add('W_BOTTOM', SOLID, b)
b = FG.copy(); b.rect(0, 0, 15, 15, C(2, 2, 1)); b.rect(1, 2, 14, 15, C(1, 3, 1)); b.rect(1, 2, 14, 3, C(2, 4, 1)); add('EXIT', DOOR, b)
# counters
def counter(top=C(6, 5, 2), front=C(4, 2, 1), till=False, glass=False):
    b = B(None); b.rect(0, 0, 15, 15, FW.p[0][0])
    b.rect(0, 2, 15, 7, top); b.rect(0, 8, 15, 15, front); b.hline(8, C(2, 1, 0))
    if till: b.rect(5, 2, 11, 6, C(1, 1, 1)); b.rect(6, 3, 10, 4, C(0, 6, 3))
    if glass: b.rect(0, 0, 15, 4, GLASS2); b.hline(0, WHITE)
    for y in range(16):
        for x in range(16):
            if b.p[y][x] is None: b.p[y][x] = FW.p[y][x]
    return b
add('COUNTER', SOLID | COUNTER, counter())
add('COUNTER_TILL', SOLID | COUNTER, counter(till=True))
add('COUNTER_GLASS', SOLID | COUNTER, counter(C(6, 6, 3), C(3, 3, 3), glass=True))
add('COUNTER_W', SOLID | COUNTER, counter(WHITE, C(5, 5, 3)))
def onfloor(fl, draw):
    b = fl.copy(); draw(b); return b
add('TABLE', SOLID, onfloor(FW, lambda b: (b.circle(8, 8, 5.5, C(6, 6, 3)), b.circle(8, 8, 4.5, WHITE), b.rect(6, 6, 7, 8, C(4, 2, 0)), b.circle(2, 3, 1.6, C(6, 0, 0)), b.circle(13, 13, 1.6, C(6, 0, 0)))))
add('BBQ', SOLID, onfloor(FW, lambda b: (b.rect(1, 2, 14, 13, C(2, 1, 0)), b.circle(8, 7.5, 4.5, BLACK), b.circle(8, 7.5, 3.5, C(5, 1, 0)), b.rect(5, 6, 10, 6, C(7, 4, 2)), b.rect(5, 9, 10, 9, C(7, 4, 2)))))
add('SHELF_SNACK', SOLID, onfloor(FT, lambda b: (b.rect(0, 2, 15, 13, C(4, 4, 3)), [b.rect(x, 3, x + 1, 12, random.Random(x).choice([C(7, 0, 0), YEL, C(0, 4, 3), C(7, 4, 0)])) for x in range(1, 15, 2)])))
add('FRIDGE', SOLID, onfloor(FT, lambda b: (b.rect(0, 0, 15, 15, C(5, 5, 3)), b.rect(1, 1, 14, 14, GLASS2), [b.rect(x, y, x, y + 2, random.Random(x * y).choice([C(7, 6, 0), C(0, 6, 0), C(7, 3, 3), WHITE])) for x in range(2, 14, 2) for y in (2, 7, 11)])))
add('SHELF_BOOK', SOLID, onfloor(FW, lambda b: (b.rect(0, 1, 15, 14, DWOOD), [b.rect(x, 2, x, 13, random.Random(x + 5).choice([C(6, 0, 0), C(0, 2, 3), C(0, 4, 0), YEL, WHITE])) for x in range(1, 15)])))
add('RACK', SOLID, onfloor(FW, lambda b: (b.rect(0, 2, 15, 2, DGREY), [b.rect(x, 3, x + 1, 13, random.Random(x + 9).choice([C(7, 2, 3), C(0, 2, 3), C(6, 6, 3), C(1, 1, 1), C(6, 5, 0)])) for x in range(1, 15, 2)])))
add('RACK_HANBOK', SOLID, onfloor(FW, lambda b: (b.rect(0, 2, 15, 2, DWOOD), [b.poly if False else b.rect(x, 3, x + 2, 13, random.Random(x + 2).choice([C(7, 2, 3), C(7, 6, 0), C(0, 5, 3), C(6, 0, 1), C(5, 0, 3)])) for x in range(0, 15, 3)])))
add('SHELF_MED', SOLID, onfloor(FT, lambda b: (b.rect(0, 1, 15, 14, WHITE), [b.rect(x, y, x + 1, y + 2, random.Random(x + y).choice([C(0, 5, 3), C(7, 3, 2), C(6, 6, 0)])) for x in range(1, 15, 3) for y in (2, 7, 11)])))
add('SHELF_COSM', SOLID, onfloor(FT, lambda b: (b.rect(0, 1, 15, 14, C(7, 5, 3)), [b.rect(x, y, x, y + 2, random.Random(x + y + 1).choice([C(7, 0, 2), C(7, 3, 3), WHITE, C(5, 0, 3)])) for x in range(1, 15, 2) for y in (3, 9)])))
add('CAKECASE', SOLID | COUNTER, onfloor(FW, lambda b: (b.rect(0, 1, 15, 14, C(5, 5, 3)), b.rect(1, 2, 14, 12, GLASS2), [b.circle(x, 8, 2, random.Random(x).choice([C(6, 4, 1), C(7, 6, 2), C(7, 3, 3)])) for x in (3, 8, 13)])))
add('SALONCHAIR', SOLID, onfloor(FT, lambda b: (b.rect(3, 3, 12, 12, BLACK), b.rect(4, 4, 11, 10, C(1, 1, 2)), b.rect(7, 12, 8, 15, DGREY))))
add('PCDESK', SOLID, onfloor(FG, lambda b: (b.rect(0, 2, 15, 13, C(1, 1, 1)), b.rect(3, 2, 12, 8, BLACK), b.rect(4, 3, 11, 7, C(0, 3, 3)), b.rect(3, 10, 12, 12, C(3, 3, 3)))))
add('DESK', SOLID, onfloor(FG, lambda b: (b.rect(0, 2, 15, 13, C(5, 4, 2)), b.rect(2, 3, 8, 8, C(1, 1, 1)), b.rect(3, 4, 7, 7, C(1, 4, 3)), b.rect(10, 4, 13, 9, WHITE), b.circle(12, 12, 1.5, C(6, 0, 0)))))
add('SOFA', SOLID, onfloor(floor('carpet', 7), lambda b: (b.rect(0, 2, 15, 13, C(5, 0, 3)), b.rect(1, 5, 14, 11, C(6, 1, 3)))))
add('PLANT', SOLID, onfloor(FW, lambda b: (b.rect(5, 10, 10, 15, C(5, 2, 0)), b.circle(8, 6, 5, C(0, 4, 0)), b.circle(6, 5, 2.5, C(1, 6, 0)))))
add('THRONE', SOLID | COUNTER, onfloor(floor('ondol', 4), lambda b: (b.rect(0, 0, 15, 8, C(0, 2, 3)), b.circle(4, 3, 2, WHITE), b.circle(11, 3, 2, C(7, 1, 0)), b.rect(0, 5, 15, 8, C(0, 4, 1)), b.rect(3, 9, 12, 14, C(6, 1, 0)), b.rect(4, 9, 11, 10, YEL))))
add('ALTAR', SOLID | COUNTER, onfloor(floor('ondol', 5), lambda b: (b.rect(0, 9, 15, 15, C(5, 1, 0)), b.circle(8, 6, 5, C(7, 5, 0)), b.circle(8, 3, 2.5, C(7, 6, 1)), b.rect(6, 10, 9, 11, YEL))))
add('CUSHION', 0, onfloor(floor('ondol', 6), lambda b: (b.rect(4, 4, 11, 11, C(6, 4, 0)), b.rect(5, 5, 10, 10, C(7, 5, 1)))))
add('GATES', SOLID, onfloor(FG, lambda b: (b.rect(0, 4, 5, 11, C(4, 4, 3)), b.rect(10, 4, 15, 11, C(4, 4, 3)), b.rect(1, 5, 4, 6, C(0, 6, 0)), b.rect(11, 5, 14, 6, C(0, 6, 0)), b.rect(6, 7, 9, 8, C(6, 0, 0)))))
add('TICKETS', SOLID | COUNTER, onfloor(FG, lambda b: (b.rect(1, 1, 14, 14, C(0, 3, 3)), b.rect(3, 3, 12, 8, BLACK), b.rect(4, 4, 11, 7, C(1, 5, 3)), b.rect(5, 10, 10, 11, YEL))))
add('TRACK', SOLID, onfloor(B(C(1, 1, 1)), lambda b: (b.rect(0, 3, 15, 3, LGREY), b.rect(0, 12, 15, 12, LGREY), [b.rect(x, 2, x + 1, 13, DWOOD) for x in range(0, 16, 4)])))
add('TRAIN', SOLID, onfloor(B(C(1, 1, 1)), lambda b: (b.rect(0, 1, 15, 14, C(6, 6, 3)), b.rect(0, 4, 15, 9, GLASS), b.rect(0, 11, 15, 12, C(0, 4, 1)), b.vline(15, DGREY, 1, 14))))
add('TREADMILL', SOLID, onfloor(floor('green', 3), lambda b: (b.rect(2, 1, 13, 14, C(1, 1, 1)), b.rect(4, 4, 11, 13, C(2, 2, 2)), b.rect(3, 1, 12, 2, C(6, 0, 0)))))
add('BED', SOLID, onfloor(floor('carpet', 9), lambda b: (b.rect(1, 1, 14, 15, WHITE), b.rect(2, 2, 13, 5, C(6, 6, 3)), b.rect(1, 7, 14, 15, C(4, 5, 3)))))
add('BINOCS', SOLID | THING, onfloor(FM, lambda b: (b.rect(7, 8, 8, 15, DGREY), b.rect(3, 3, 12, 8, C(0, 4, 3)), b.circle(5, 5, 2, BLACK), b.circle(10, 5, 2, BLACK))))
add('ROPE', SOLID, onfloor(FM, lambda b: (b.rect(0, 7, 15, 8, C(6, 0, 0)), b.rect(0, 4, 1, 15, YEL), b.rect(14, 4, 15, 15, YEL))))
add('FISHTANK', SOLID | COUNTER, onfloor(FT, lambda b: (b.rect(0, 1, 15, 14, C(4, 4, 3)), b.rect(1, 2, 14, 13, C(0, 3, 3)), b.rect(3, 5, 7, 6, C(7, 4, 2)), b.rect(9, 9, 13, 10, C(5, 5, 3)), b.rect(4, 11, 6, 12, C(6, 1, 0)))))
add('FLOWERS_IN', SOLID, onfloor(FW, lambda b: (b.rect(1, 6, 14, 14, C(4, 2, 0)), [b.circle(x, 5, 2, random.Random(x).choice([C(7, 0, 1), C(7, 6, 0), C(7, 3, 3), WHITE])) for x in (3, 7, 11)], b.noise([C(0, 5, 0)], 8, 2))))
add('POOLTABLE', SOLID, onfloor(FW, lambda b: (b.rect(0, 1, 15, 14, DWOOD), b.rect(1, 2, 14, 13, C(0, 4, 1)), b.circle(5, 6, 1, WHITE), b.circle(10, 9, 1, C(6, 0, 0)))))
add('STAGE', 0, onfloor(B(C(1, 0, 1)), lambda b: (b.noise([C(2, 0, 2), C(3, 0, 3)], 30, 3), b.hline(0, C(7, 6, 0)))))
add('SEATS', SOLID, onfloor(floor('carpet', 11), lambda b: [b.rect(x, 4, x + 2, 11, C(6, 0, 0)) for x in (1, 5, 9, 13)]))
add('BOXES', SOLID, onfloor(FG, lambda b: (b.rect(1, 3, 7, 14, C(5, 3, 1)), b.rect(8, 6, 14, 14, C(6, 4, 1)), b.rect(1, 3, 7, 4, C(6, 5, 2)), b.rect(8, 6, 14, 7, C(7, 5, 2)), b.rect(3, 8, 5, 9, C(6, 0, 0)))))
add('SORTING', SOLID | COUNTER, onfloor(FG, lambda b: (b.rect(0, 1, 15, 14, DWOOD), [b.rect(x, y, x + 2, y + 2, C(1, 0, 0)) for x in range(1, 15, 4) for y in (2, 6, 10)], b.noise([WHITE], 10, 4))))
add('EXHIBIT', SOLID | THING, onfloor(FM, lambda b: (b.rect(2, 4, 13, 15, C(4, 4, 2)), b.rect(3, 1, 12, 9, GLASS2), b.circle(8, 6, 2.5, C(4, 6, 2)), b.rect(3, 9, 12, 9, WHITE))))
add('SPEAKER', SOLID, onfloor(B(C(1, 0, 1)), lambda b: (b.rect(3, 1, 12, 14, BLACK), b.circle(8, 5, 2.5, C(2, 2, 2)), b.circle(8, 11, 3, C(2, 2, 2)))))
add('PHONES', SOLID, onfloor(FT, lambda b: (b.rect(0, 2, 15, 13, C(5, 5, 3)), [b.rect(x, 4, x + 2, 10, BLACK) for x in (1, 6, 11)], [b.rect(x + 1, 5, x + 1, 8, C(0, 5, 3)) for x in (1, 6, 11)])))
add('TV_WALL', SOLID, onfloor(FG, lambda b: [b.rect(x, y, x + 6, y + 5, C(0, 2, 3)) for x in (0, 8) for y in (1, 8)]))

assert len(BLOCKS) <= 256, len(BLOCKS)
INDEX = {n: k for k, (n, a, b) in enumerate(BLOCKS)}
ATTR = [a for n, a, b in BLOCKS] + [0] * (256 - len(BLOCKS))
for n, a, b in BLOCKS:
    for row in b.p:
        for v in row: assert v is not None and v != 0xE3, n

if __name__ == '__main__':
    data = bytearray()
    for n, a, b in BLOCKS:
        for row in b.p: data += bytes(row)
    open(os.path.join(HERE, 'blocks.bin'), 'wb').write(data)
    cols = 16; rows = (len(BLOCKS) + cols - 1) // cols
    img = Image.new('RGB', (cols * 17 * 3, rows * 17 * 3), (40, 40, 40))
    for k, (n, a, b) in enumerate(BLOCKS):
        for y in range(16):
            for x in range(16):
                c = rgb(b.p[y][x])
                for dy in range(3):
                    for dx in range(3):
                        img.putpixel(((k % cols) * 51 + x * 3 + dx, (k // cols) * 51 + y * 3 + dy), c)
    img.save(os.path.join(HERE, 'blocks_preview.png'))
    print('%d blocks, %d bytes' % (len(BLOCKS), len(data)))
