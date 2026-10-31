# art_city.py - LITTLE SEOUL's sprites: the postie, the people of Seoul (men, women, ajummas,
# grandads), cars, taxis, buses, scooters, and the icons over heads. Writes ../gfx/sprites.png,
# spr_pal.png and layout.txt (the font and panel tiles are THE NEWS HOST's: gfx/tiles.png).
# (run: python3 tools/art_city.py)        (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from artkit import *
from cvkit import Cv

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'gfx')
def c(r, g, b): return (r * 255 // 7, g * 255 // 7, b * 255 // 3)

# person colours: 0 outline, 1 white, 2 skin, 3 skin shade, 4 hair, 5 hair shade, 6 top, 7 top
# shade, 8 legs (trousers / skirt), 9 shoes, 10 accent (cap, bag, apron), 11 accent shade,
# 12 glass, 13 body (vehicles), 14 body shade
def row(top, top2, legs, hair=c(1, 1, 1), hair2=c(0, 0, 0), acc=c(7, 6, 0), acc2=c(5, 4, 0), skin=c(7, 5, 2), body=c(6, 6, 3), body2=c(4, 4, 2)):
    return [c(0, 0, 0), c(7, 7, 3), skin, (skin[0] * 4 // 5, skin[1] * 4 // 5, skin[2] * 4 // 5), hair, hair2, top, top2, legs, c(1, 1, 1),
            acc, acc2, c(2, 5, 3), body, body2, MAGENTA]
PAL = [
    row(c(7, 1, 0), c(5, 0, 0), c(0, 0, 2), hair=c(2, 1, 0), hair2=c(1, 0, 0), acc=c(7, 6, 0), acc2=c(5, 4, 0)),                    # 0 the postie (red jacket, navy, a yellow bag)
    row(c(0, 2, 3), c(0, 1, 2), c(1, 1, 1)),                                                       # 1-10 people
    row(c(7, 7, 3), c(5, 5, 2), c(1, 1, 2), hair=c(3, 2, 0), hair2=c(2, 1, 0)),
    row(c(7, 3, 3), c(6, 2, 2), c(6, 6, 3), hair=c(5, 3, 1), hair2=c(3, 2, 0)),
    row(c(1, 1, 1), c(0, 0, 0), c(1, 1, 1)),
    row(c(4, 6, 1), c(2, 4, 1), c(5, 4, 2), hair=c(2, 1, 0), hair2=c(1, 0, 0)),
    row(c(6, 5, 0), c(5, 3, 0), c(2, 2, 3), hair=c(6, 5, 2), hair2=c(4, 3, 1)),
    row(c(5, 0, 3), c(3, 0, 2), c(1, 1, 1), hair=c(5, 1, 3), hair2=c(3, 0, 2)),
    row(c(4, 4, 2), c(3, 3, 1), c(2, 1, 0), hair=c(5, 5, 2), hair2=c(3, 3, 2)),               # greys: the old
    row(c(0, 5, 3), c(0, 3, 2), c(6, 6, 3)),
    row(c(7, 5, 0), c(5, 3, 0), c(1, 2, 3), hair=c(1, 1, 1)),
    row(c(1, 1, 2), c(0, 0, 1), c(1, 1, 1), acc=c(7, 7, 3), acc2=c(5, 5, 2)),                # 11 a shopkeeper (a white apron)
    row(c(7, 7, 3), c(5, 5, 2), c(1, 1, 1), body=c(6, 6, 3), body2=c(4, 4, 2)),              # 12 a white car
    row(c(7, 7, 3), c(5, 5, 2), c(1, 1, 1), body=c(7, 4, 0), body2=c(5, 2, 0)),              # 13 a taxi
    row(c(7, 7, 3), c(5, 5, 2), c(1, 1, 1), body=c(0, 2, 3), body2=c(0, 1, 2)),              # 14 a blue bus / a dark car
    [c(0, 0, 0), c(7, 7, 3), c(7, 0, 0), c(7, 3, 3), c(7, 7, 0), c(4, 2, 0), c(0, 5, 0), c(0, 3, 3),     # 15 the icons
     c(7, 4, 0), c(5, 5, 2), c(6, 5, 2), c(3, 3, 1), c(2, 5, 3), c(5, 0, 3), c(1, 1, 2), MAGENTA],
]

# ---------------------------------------------------------------- people
# kind: 0 the postie, 1 a man, 2 a woman, 3 an ajumma, 4 a grandad
# view: 0 front, 1 back, 2 side (facing right); f: 0 standing, 1 / 2 walking
def person(kind, view, f):
    v = Cv(16, 16)
    s = (0, 1, -1)[f]
    skirt = kind == 2
    # legs
    if view == 2:
        v.rect(6 + s, 11, 7 + s, 14, 8); v.rect(8 - s, 11, 9 - s, 14, 8)
        v.rect(6 + s, 15, 8 + s, 15, 9); v.rect(8 - s, 15, 10 - s, 15, 9)
    else:
        l = 15 - (f == 1); r = 15 - (f == 2)
        v.rect(5, 11, 6, l - 1, 8); v.rect(9, 11, 10, r - 1, 8)
        v.rect(5, l, 6, l, 9); v.rect(9, r, 10, r, 9)
    if skirt:
        if view == 2: v.rect(5, 10, 10, 12, 8)
        else: v.rect(4, 10, 11, 12, 8)
        if view != 2:
            v.rect(5, 13, 6, 14 - (f == 1), 2); v.rect(9, 13, 10, 14 - (f == 2), 2)
    # body
    if view == 2:
        v.rect(5, 6, 10, 11, 6); v.rect(5, 6, 6, 11, 7)
        arm = (0, 2, -2)[f]
        v.rect(7 + arm // 2, 7, 8 + arm // 2, 10, 7); v.set(7 + arm // 2, 11, 2)
    else:
        v.rect(4, 6, 11, 11, 6); v.rect(4, 6, 4, 11, 7); v.rect(11, 6, 11, 11, 7)
        v.set(4, 11, 2); v.set(11, 11, 2)
        if kind == 4: v.rect(7, 6, 8, 7, 1)                        # grandad: a collar
    # the postie's bag (a strap across, the bag at the side)
    if kind == 0:
        if view == 0:
            for k in range(6): v.set(5 + k, 6 + k, 10)
            v.rect(9, 9, 12, 12, 10); v.rect(9, 12, 12, 12, 11)
        elif view == 1:
            for k in range(6): v.set(10 - k, 6 + k, 10)
            v.rect(3, 9, 6, 12, 10); v.rect(3, 12, 6, 12, 11)
        else:
            v.rect(3, 8, 6, 11, 10); v.rect(3, 11, 6, 11, 11); v.set(6, 6, 10); v.set(6, 7, 10)
    # head
    v.circle(7.5, 3.5, 3.4, 2)
    if view == 2: v.set(11, 4, 2)
    # hair
    if kind == 0:                                                  # a cap
        v.rect(4, 0, 11, 2, 10); v.rect(4, 2, 11, 2, 11)
        if view == 0: v.rect(5, 3, 10, 3, 11)
        if view == 2: v.rect(10, 2, 13, 2, 11)
        if view == 1: v.rect(4, 3, 11, 5, 4)
    elif kind == 1:
        v.rect(4, 0, 11, 1, 4); v.set(4, 2, 4); v.set(11, 2, 4)
        if view == 1: v.rect(4, 0, 11, 5, 4)
        if view == 2: v.rect(4, 0, 9, 3, 4)
    elif kind == 2:
        v.rect(4, 0, 11, 1, 4); v.rect(3, 1, 4, 8, 4); v.rect(11, 1, 12, 8, 4); v.rect(3, 8, 4, 8, 5); v.rect(11, 8, 12, 8, 5)
        if view == 1: v.rect(3, 0, 12, 8, 4); v.rect(4, 8, 11, 8, 5)
        if view == 2: v.rect(3, 0, 9, 8, 4); v.rect(3, 8, 8, 8, 5); v.set(10, 1, 4)
    elif kind == 3:                                                # a perm (and a visor)
        for x in range(4, 12, 2): v.circle(x + 0.5, 1, 1.4, 4)
        v.circle(3.5, 3, 1.4, 4); v.circle(11.5, 3, 1.4, 4)
        if view == 1: v.rect(4, 0, 11, 5, 4); [v.set(x, 5, 5) for x in range(4, 12, 2)]
        if view == 2: v.rect(4, 0, 8, 4, 4)
        if view != 1: v.rect(4, 2, 12, 2, 10)
    else:                                                          # grey, thin on top
        v.set(4, 2, 4); v.set(11, 2, 4); v.rect(4, 3, 4, 4, 4); v.rect(11, 3, 11, 4, 4)
        if view == 1: v.rect(4, 2, 11, 5, 4)
        if view == 2: v.rect(4, 2, 6, 5, 4)
    # the face
    if view == 0:
        v.set(6, 4, 0); v.set(9, 4, 0)
        if kind == 4: v.rect(5, 4, 7, 4, 0); v.rect(8, 4, 10, 4, 0)    # glasses
    elif view == 2:
        v.set(10, 4, 0)
    v.outline(0)
    return v

def car(kind):
    # 32 x 16, facing right: 0 a car, 1 a taxi (a light on top)
    v = Cv(32, 16)
    v.rect(1, 6, 30, 13, 13); v.rect(1, 12, 30, 13, 14)
    v.rect(8, 2, 22, 7, 13); v.rect(10, 3, 15, 6, 12); v.rect(17, 3, 21, 6, 12)
    v.rect(28, 7, 30, 8, 1); v.rect(1, 7, 2, 8, 2 if False else 0)
    v.circle(7.5, 13.5, 2.5, 0); v.circle(24.5, 13.5, 2.5, 0); v.circle(7.5, 13.5, 1, 1); v.circle(24.5, 13.5, 1, 1)
    if kind == 1: v.rect(13, 0, 17, 1, 10)
    v.outline(0)
    return v

def bus():
    v = Cv(48, 16)
    v.rect(1, 1, 46, 13, 13); v.rect(1, 11, 46, 13, 14)
    for x in range(4, 44, 7): v.rect(x, 3, x + 5, 7, 12)
    v.rect(43, 3, 46, 9, 12); v.rect(6, 9, 40, 9, 10)
    for x in (8, 38): v.circle(x + 0.5, 13.5, 2.5, 0); v.circle(x + 0.5, 13.5, 1, 1)
    v.outline(0)
    return v

def scooter():
    v = Cv(16, 16)
    v.rect(2, 9, 13, 11, 13); v.rect(10, 5, 11, 9, 0); v.rect(9, 4, 12, 4, 0)
    v.rect(1, 5, 6, 9, 10)                                 # the delivery box
    v.circle(3, 13, 2.2, 0); v.circle(12, 13, 2.2, 0)
    v.circle(7.5, 3, 2.2, 13); v.rect(6, 5, 9, 8, 6)       # the rider (a helmet)
    v.outline(0)
    return v

# ---------------------------------------------------------------- icons (palette row 15)
def icon(n):
    v = Cv(16, 16)
    if n == 0:      # a letter
        v.rect(2, 4, 13, 12, 1); v.rect(2, 4, 13, 4, 9)
        for k in range(6): v.set(2 + k, 5 + k * 0.6, 9); v.set(13 - k, 5 + k * 0.6, 9)
        v.rect(10, 6, 12, 8, 2)
    elif n == 1:    # a parcel
        v.rect(2, 5, 13, 13, 10); v.rect(2, 5, 13, 6, 6 if False else 10); v.rect(2, 5, 13, 5, 5); v.rect(7, 5, 8, 13, 5); v.rect(2, 9, 13, 9, 5)
        v.rect(3, 3, 12, 4, 10)
    elif n == 2:    # a speech bubble
        v.circle(8, 6, 5.5, 1); v.poly([(4, 9), (8, 10), (3, 14)], 1); v.set(5, 6, 0); v.set(8, 6, 0); v.set(11, 6, 0)
    elif n == 3:    # a heart
        v.circle(5, 6, 3, 2); v.circle(10, 6, 3, 2); v.poly([(2, 7), (13.5, 7), (7.5, 14)], 2); v.set(4, 5, 3)
    elif n == 4:    # !
        v.rect(6, 1, 9, 10, 4); v.rect(6, 12, 9, 14, 4)
    elif n == 5:    # ?
        v.rect(4, 2, 11, 3, 4); v.rect(10, 3, 11, 7, 4); v.rect(7, 7, 10, 8, 4); v.rect(7, 8, 8, 10, 4); v.rect(7, 12, 8, 14, 4)
    elif n == 6:    # stars (knocked over)
        for (x, y) in ((3, 4), (11, 3), (7, 10)):
            v.rect(x - 2, y, x + 2, y, 4); v.rect(x, y - 2, x, y + 2, 4); v.set(x, y, 1)
    elif n == 7:    # a coffee
        v.rect(4, 5, 10, 13, 1); v.rect(4, 5, 10, 6, 5); v.rect(11, 7, 12, 10, 1); v.rect(5, 8, 9, 10, 8)
        v.set(6, 2, 9); v.set(7, 1, 9); v.set(8, 3, 9)
    elif n == 8:    # a bowl of food
        v.rect(2, 8, 13, 9, 1); v.circle(7.5, 9, 5.5, 2); v.rect(1, 3, 14, 8, None); v.rect(3, 6, 12, 8, 4); v.set(5, 5, 6); v.set(9, 5, 6)
        v.rect(11, 1, 11, 7, 5); v.rect(13, 1, 13, 7, 5)
    elif n == 9:    # an arrow, down
        v.rect(6, 1, 9, 8, 4); v.poly([(2, 8), (14, 8), (8, 14.5)], 4)
    elif n == 10:   # a coin (won)
        v.circle(8, 8, 6, 4); v.circle(8, 8, 4.5, 8); v.rect(5, 6, 11, 6, 4); v.rect(5, 9, 11, 9, 4); v.set(6, 7, 4); v.set(10, 7, 4)
    elif n == 11:   # a note (singing)
        v.rect(9, 1, 10, 11, 7); v.circle(7, 12, 2.5, 7); v.rect(10, 1, 13, 3, 7)
    elif n == 12:   # a shopping bag
        v.rect(3, 6, 12, 14, 13); v.rect(5, 3, 5, 6, 0); v.rect(10, 3, 10, 6, 0); v.rect(5, 3, 10, 3, 0)
    elif n == 13:   # zzz / ...
        v.rect(3, 9, 4, 10, 1); v.rect(7, 9, 8, 10, 1); v.rect(11, 9, 12, 10, 1)
    elif n == 14:   # a sparkle
        for k in range(8):
            a = k * math.pi / 4
            for t in range(2, 7): v.set(7.5 + math.cos(a) * t, 7.5 + math.sin(a) * t, 4 if t < 5 else 1)
    elif n == 15:   # a broken heart
        v.circle(5, 6, 3, 13); v.circle(10, 6, 3, 13); v.poly([(2, 7), (13.5, 7), (7.5, 14)], 13)
        for y in range(3, 14): v.set(7 + (y % 2), y, None)
    elif n == 16:   # the you-are-here marker (a ring)
        v.circle(8, 8, 7, 2); v.circle(8, 8, 5, None); v.circle(8, 8, 2.5, 4)
    elif n == 17:   # a flower
        for k in range(5):
            a = k * 2 * math.pi / 5
            v.circle(8 + math.cos(a) * 3.5, 6 + math.sin(a) * 3.5, 2.3, 3)
        v.circle(8, 6, 2, 4); v.rect(7, 9, 8, 15, 6)
    if n not in (13, 16): v.outline(0)
    return v

if __name__ == '__main__':
    os.makedirs(D, exist_ok=True)
    palette_png(D + '/spr_pal.png', PAL)
    S = Sheet(16, 8, PAL[0])
    names = []
    col = 0; rw = 0
    def place(v):
        global col, rw
        w = v.w // 16
        if col + w > 16: col = 0; rw += 1
        for k in range(w):
            sub = Cv(16, 16)
            for y in range(16):
                for x in range(16): sub.p[y][x] = v.p[y][x + k * 16]
            sub.into(S, col + k, rw)
        at = (col, rw); col += w
        return at
    def group(vs, r, c0):
        global col, rw
        col, rw = c0, r
        at = None
        for v in vs:
            p = place(v)
            if at is None: at = p
        return at
    for kind, nm in enumerate(('POSTIE', 'MAN', 'WOMAN', 'AJUMMA', 'GRANDAD')):
        at = group([person(kind, view, f) for view in range(3) for f in range(3)], kind, 0)
        names.append('sprite %-8s %d %d 9     # front x3 (standing, walking x2), back x3, side x3 (facing right)' % (nm, at[0], at[1]))
    at = group([car(0), car(1)], 0, 9)
    names.append('sprite CAR      %d %d 2 2 1 # 32 x 16 facing right: a car, a taxi (palette 12-14: white, orange, blue)' % at)
    at = group([bus()], 0, 13)
    names.append('sprite BUS      %d %d 1 3 1 # 48 x 16 facing right' % at)
    at = group([scooter()], 1, 9)
    names.append('sprite SCOOTER  %d %d 1     # a delivery scooter, facing right' % at)
    at = group([icon(n) for n in range(16)], 5, 0)
    names.append('sprite ICON     %d %d 16    # palette 15: letter, parcel, speech, heart, !, ?, stars, coffee, food, arrow, coin, note, bag, ..., sparkle, broken heart' % at)
    at = group([icon(n) for n in range(16, 18)], 6, 0)
    names.append('sprite ICON2    %d %d 2     # (ICON 16, 17: a ring, a flower)' % at)
    S.save(D + '/sprites.png')
    tiles = open(os.path.join(D, '..', '..', 'NEWSHOST', 'gfx', 'layout.txt')).read().splitlines()
    tl = [l for l in tiles if l.startswith('tile')]
    open(D + '/layout.txt', 'w').write('''# LITTLE SEOUL - names for the cells of tiles.png (8 x 8) and sprites.png (16 x 16)
# tile   NAME   index [count]
# sprite NAME   column row [frames [w h]]
# sprite palettes (spr_pal.png rows): 0 the postie, 1-10 people, 11 a shopkeeper, 12-14 cars
# (white, taxi, blue), 15 the icons
''' + '\n'.join(tl) + '\n\n' + '\n'.join(names) + '\n')
    print('sprites: up to row %d' % rw)
