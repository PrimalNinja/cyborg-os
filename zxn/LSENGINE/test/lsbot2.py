# a bot for LITTLE SEOUL: plays the menus, walks the round (BFS over the city's blocks)
import sys, random, re, bisect, os, json
sys.path.insert(0, '/home/claude/work/emu')
import nextemu
SP, UP, DN, LF, RT, M = 56, 16, 8, 41, 40, 58
OUT = '/tmp/claude-0/-home-claude/763e589f-1b39-5ff1-8745-d6aace327178/scratchpad/'
G = os.environ.get('LSG', '/home/claude/work/games/LSENGINE/')
LST = G + 'build/LSENGINE.lst'
os.chdir(G)
z = nextemu.NextX('build/LSENGINE.NEX', 'build/LSENGINE.sym')
r = random.Random(int(sys.argv[2]) if len(sys.argv) > 2 else 1)
DBG = 'dbg' in sys.argv
MODE = sys.argv[3] if len(sys.argv) > 3 else 'walk'
TAG = sys.argv[4] if len(sys.argv) > 4 else MODE
addrs = []; cur = None
for l in open(LST, errors='replace'):
    m = re.match(r'\s*\d+\+?\s+([0-9A-F]{4})\s+(.*)', l)
    if not m: continue
    a = int(m.group(1), 16); rest = m.group(2)
    c = re.search(r';\s*(\w+\.(?:bas|cls)) (\d+)', rest)
    if c: cur = (c.group(1), int(c.group(2)))
    if cur and re.search(r'\bdw\b', rest): addrs.append((a, cur))
addrs.sort(); keys = [a for a, _ in addrs]
import glob
subs = {}
for fn_ in glob.glob('*.bas'):
    subs[fn_] = []
    for i, l in enumerate(open(fn_, encoding='latin-1'), 1):
        m = re.match(r'^(Sub|Function) (\w+)', l)
        if m: subs[fn_].append((i, m.group(2)))
def line_of(a):
    i = bisect.bisect_right(keys, a) - 1
    return addrs[i][1] if i >= 0 else ('?', 0)
def func_of(ln, f='Main.bas'):
    n = None
    for i, nm in subs.get(f, []):
        if i <= ln: n = nm
    return n
def rs(sub):
    a = z.symtab.get('p_%s_rs' % sub.lower())
    return z.deek(a) if a else 0
def strv(name):
    a = z.symtab[name]; s = ''
    while z.m.memory[a] and len(s) < 160: s += chr(z.m.memory[a]); a += 1
    return s
def v(n):
    x = z.var(n)
    return x - 65536 if x >= 32768 else x
def ab(name, i): return z.m.memory[z.symtab[name] + i]
def chain():
    f1, l1 = line_of(rs('Tick'))
    fn = func_of(l1, f1) if f1 in subs else None
    out = [fn]
    if fn:
        f2, l2 = line_of(rs(fn)); out.append(func_of(l2, f2) if f2 in subs else f2)
        if fn == 'NextKey' and out[1]:
            f3, l3 = line_of(rs(out[1])); out = [out[1], func_of(l3, f3) if f3 in subs else f3]
    return out
held = set(); st = {'t': 0, 'k': None, 'q': []}
def sel_to(cur, want):
    return [DN] * (want - cur) if want > cur else [UP] * (cur - want)
seen = {}
def snap(key, delay=30):
    if key not in seen:
        seen[key] = z.frame; z.shots[z.frame + delay] = OUT + 'ls' + TAG + '_' + key + '.png'
def decide():
    c = chain(); fn = c[0]
    if False: print('D', z.frame, c, v('var_px'), v('var_py'), v('var_room'), v('var_stun'), flush=True)
    if fn == 'AnyKey': return [('H', None, 70), SP]
    if fn == 'WaitGo': return ['W', SP]
    if fn in ('TitleScr', 'WaitF'): return [SP]
    if fn == 'PickFace': return [RT] * r.randrange(4) + [SP]
    if fn == 'NameEntry': return [('H', None, 70), M]
    if fn == 'Choose':
        nopt = v('var_choose_nopt'); want = r.randrange(max(2, nopt))
        return sel_to(v('var_choose_sel'), want) + [SP]
    if fn == 'BagScreen' and not NAV.get('bagwait'):
        NAV['bagwait'] = 1; return [('H', None, 100)]
    if fn == 'BagScreen':
        if 'map' not in seen and z.frame > 2000: return [SP]
        return [M]
    if fn == 'MapScreen': snap('map', 5); return [RT, RT, M]
    if fn == 'Lift':
        f0 = v('var_lift_fl'); want = NAV.get('floor', 1)
        return ([UP] * (want - f0) if want > f0 else [DN] * (f0 - want)) + [SP]
    if fn == 'Subway': snap('subway', 3); NAV['rode'] = 1; return [DN] * 5 + [SP]
    if fn == 'Round' and 'bagkey' not in NAV and z.frame > 2500:
        NAV['bagkey'] = 1; return [M]
    if fn == 'Round' and 'fast' in sys.argv:
        if v('var_day') == 2 and not NAV.get('jumped'): NAV['jumped'] = 1; z.setvar('var_day', 19)
        if v('var_ndone') == v('var_nbag'): z.setvar('var_mins', 1079)
    if fn == 'Round':
        w = walk()
        if DBG and 1420 < z.frame < 1800 and z.frame % 6 == 0: print('W', z.frame, v('var_px'), v('var_py'), v('var_room'), target(), NAV.get('pk'), w, flush=True)
        return w
    return [SP]

sys.path.insert(0, G + 'tools')
import blocks as BL
from collections import deque
ATTR = BL.ATTR
ROOMS = open(G + 'tools/world/rooms.bin', 'rb').read()
SHOPS = open(G + 'tools/world/shops.bin', 'rb').read()
def shop(s): return SHOPS[s * 8:s * 8 + 8]
SOLID, DOOR, STAIRS = 1, 2, 64
def gcell(room, c): return ((room // 16) * 12 + c // 16, (room % 16) * 16 + c % 16)   # (row, col) global
def gblock(R, C):
    room = (R // 12) * 16 + C // 16; c = (R % 12) * 16 + C % 16
    return ROOMS[room * 256 + c]
def bfs(start, goal, blocked):
    # cells (row, col); blocked(cell) -> bool (the goal is always allowed)
    prev = {start: None}; q = deque([start])
    while q:
        u = q.popleft()
        if u == goal: break
        for dr, dc in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            w = (u[0] + dr, u[1] + dc)
            if w in prev: continue
            if w != goal and blocked(w): continue
            prev[w] = u; q.append(w)
    if goal not in prev: return None
    path = []; u = goal
    while u is not None: path.append(u); u = prev[u]
    return path[::-1]
def street_blocked(w):
    R, C = w
    if R < 0 or C < 0 or R >= 144 or C >= 256: return True
    return ATTR[gblock(R, C)] & (SOLID | DOOR | STAIRS) != 0
def rcb(i): return z.peek(z.symtab['arr_rc'] + i)
def inner_blocked(w):
    R, C = w
    if R < 0 or C < 0 or R >= 12 or C >= 16: return True
    return ATTR[rcb(R * 16 + C)] & (SOLID | DOOR | STAIRS) != 0
NAV = {'plan': None, 'stuck': 0, 'last': None}
def pos():
    px = v('var_px'); py = v('var_py')
    return px, py, (min(11, max(0, (py + 12) // 16)), min(15, max(0, (px + 8) // 16)))
def step_to(cell, cur, px, py, base=(0, 0)):
    # keys to move from cur toward the neighbouring cell (local coordinates)
    tr, tc = cell[0] - base[0], cell[1] - base[1]
    tx, ty = tc * 16, tr * 16 - 4
    if cell[0] != cur[0]:
        if abs(px - tx) > 1: return RT if px < tx else LF
        return DN if cell[0] > cur[0] else UP
    if abs(py - ty) > 2: return DN if py < ty else UP
    return RT if cell[1] > cur[1] else LF
STATIONS = open(G + 'tools/world/stations.bin', 'rb').read()
def target():
    if MODE == 'subway' and not NAV.get('rode'):
        room = v('var_room') if v('var_inshop') < 0 else shop(v('var_inshop'))[5]
        best = None
        for k in range(len(STATIONS) // 32):
            sh2 = STATIONS[k * 32] + STATIONS[k * 32 + 1] * 256; rr = shop(sh2)[5]
            d = abs(rr % 16 - room % 16) + abs(rr // 16 - room // 16)
            if best is None or d < best[0]: best = (d, -1, sh2)
        return best
    nb = v('var_nbag'); best = None
    room = v('var_room'); here = room if v('var_inshop') < 0 else shop(v('var_inshop'))[5]
    for j in range(nb):
        if z.arr('arr_bdone', j, 1): continue
        s = z.arr('arr_bshop', j)
        d = abs(shop(s)[5] % 16 - here % 16) + abs(shop(s)[5] // 16 - here // 16)
        if best is None or d < best[0]: best = (d, j, s)
    return best
def walk():
    px, py, cur = pos()
    ins = v('var_inshop'); room = v('var_room')
    t = target()
    if ins >= 0:
        fl = v('var_floor'); want = None; face = False
        if t and t[1] == -1 and t[2] == ins:
            want = 7 * 16 + 2; face = True
        elif t and t[2] == ins:
            j = t[1]; kind = z.arr('arr_bkind', j, 1); tf = z.arr('arr_bfloor', j, 1); tu = z.arr('arr_bunit', j, 1)
            if z.arr('arr_bp', j) < 0:
                want = rcb(197); face = True
            elif kind == 0 and rcb(207) != 255 and fl == 1:
                want = rcb(207) + 16; face = True
            elif fl != tf:
                want = rcb(202) + 16; face = True; NAV['floor'] = tf
            else:
                want = rcb(203 + tu - 1) + 16; face = True
        else:
            if fl > 1: want = rcb(202) + 16; face = True; NAV['floor'] = 1
            else: want = rcb(208)
        if want is None or want >= 192: return [SP]
        goal = (want // 16, want % 16)
        if cur == goal:
            if face:
                if (abs(px - goal[1] * 16) > 1): return [('H', RT if px < goal[1] * 16 else LF, 1)]
                return [('H', UP, 3), SP]
            return [('H', DN, 2)]
        path = bfs(cur, goal, inner_blocked)
        if not path or len(path) < 2: return [('H', r.choice([UP, DN, LF, RT]), 8)]
        return [('H', step_to(path[1], cur, px, py), 1)]
    if not t: return [('H', r.choice([UP, LF, RT, DN]), 10)]
    sh = shop(t[2]); groom, gc = sh[5], sh[6]
    goal = gcell(groom, gc)
    start = gcell(room, (cur[0] * 16 + cur[1]) if 0 <= cur[0] < 12 and 0 <= cur[1] < 16 else 0)
    if NAV.get('ps') != (start, goal):
        NAV['path'] = bfs(start, goal, street_blocked); NAV['ps'] = (start, goal)
        if NAV['path'] is None: print('NO PATH', start, goal, flush=True); NAV['path'] = [start]
    path = NAV['path']; i = path.index(start)
    if i + 1 >= len(path): return [('H', UP, 4)]
    nxt = path[i + 1]
    if DBG and 1480 < z.frame < 1530: print('P', z.frame, (px, py), cur, start, goal, path[i:i+3], step_to(nxt, start, px, py, ((room // 16) * 12, (room % 16) * 16)), flush=True)
    if z.frame % 50 == 0 and DBG: print('NAV', z.frame, room, (px, py), start, nxt, goal, len(path), flush=True)
    base = ((room // 16) * 12, (room % 16) * 16)
    return [('H', step_to(nxt, start, px, py, base), 1)]
def onframe(z):
    held.clear()
    try:
        c = chain()
        if c[0] == 'TitleScr' and z.frame > 200: snap('title', 3)
        if c[0] == 'AnyKey' and c[1] == 'Final': snap('final', 40); print('FINAL', z.frame, flush=True)
        if c[0] == 'AnyKey' and c[1] == 'Results': snap('results%d' % v('var_day'), 40)
        if c[0] == 'PickFace': snap('face')
        if c[0] == 'NameEntry': snap('name', 50)
        if c[0] == 'BagScreen': snap('bag', 80)
        if c[0] == 'WaitGo' and v('var_day') == 1 and v('var_mins') == 540: snap('boss', 3)
        if c[0] == 'Round':
            snap('street%d' % (z.frame // 3000), 1)
        if c[0] == 'WaitGo' and v('var_mins') > 540: snap('talk%d' % (z.frame // 4000), 3)
    except Exception as e: pass
    if z.frame < 300: return
    if st['t'] > 0:
        st['t'] -= 1
        if st['k'] is not None and (st['t'] > 3 or st.get('hold')): held.add(st['k'])
        return
    if not st['q']:
        try: st['q'] = decide()
        except Exception as e: print('ERR', e); st['q'] = [SP]
    k = st['q'].pop(0)
    if isinstance(k, tuple):
        st['k'] = k[1]; st['t'] = k[2]; st['hold'] = 1
    else:
        st['hold'] = 0
        st['k'] = k; st['t'] = 6
        if k == 'W': st['k'] = None; st['t'] = 4
def per(z):
    print(z.frame, 'day', v('var_day'), 'mins', v('var_mins'), 'room', v('var_room'), 'shop', v('var_inshop'), 'fl', v('var_floor'), 'xy', v('var_px'), v('var_py'), 'bag', v('var_ndone'), '/', v('var_nbag'), 'money', z.var('var_money'), chain(), flush=True)
z.onframe = onframe
z.keysheld = lambda f: held
n = int(sys.argv[1])
for f in range(0, n, 2000):
    z.run_frames(2000, (2000, per))
    if z.m.halted or z.reset: print('CRASH', z.frame, hex(z.m.pc)); break
z.shot(OUT + 'lsbot_last_%s.png' % TAG)
