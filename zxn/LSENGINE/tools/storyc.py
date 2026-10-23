# storyc.py - THE LITTLE SEOUL ENGINE's story compiler: scripts/*.txt -> the story banks (build/NAME.DAT, NAME: game.json's)
# and Data.cls (the scene numbers and the routines that read them). Also checks scripts:  python3 tools/storyc.py --check FILE...
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
#
# A script file:
#   # a comment
#   === SCENE              a scene (the names: SCENES below, or a generic one's)
#   - text                 the narrator
#   "text                  the person speaking (a closing " is optional)
#   :mood                  their face: smile open cat o grin smirk; :heart :broken :sparkle :note
#                          :star float an icon
#   ? option               a choice (2 or 3 options); the lines indented under it are what
#                          happens; +N / -N there (or anywhere) changes how they feel about you
#   *flag                  sets a flag on them (lied, helped ...)
#   $N / $-N               money (thousands of won)
#   {P} your name, {N} theirs, {Q} the Queen, {X} someone else, {PLACE} where you are
import os, sys, re, json

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
NAME = json.load(open(os.path.join(ROOT, 'game.json')))['name']     # the game's name: build/NAME.DAT

def eps(pre, n): return ['%s%02d' % (pre, k) for k in range(1, n + 1)]
SHOPKEYS = ['CAFE', 'CONV', 'CHICKEN', 'BBQ', 'NOODLE', 'BAKERY', 'PHARMACY', 'COSMETICS', 'PCBANG', 'NORAE', 'SALON',
            'BOUTIQUE', 'PHONE', 'BANK', 'BOOKSHOP', 'TEAHOUSE', 'CRAFT', 'HANBOK', 'GYM', 'FLORIST', 'FISH', 'POST',
            'POLICE', 'CLINIC', 'ELECTRO', 'THEATRE', 'CLUB', 'MUSEUM', 'HOTEL', 'APT', 'VILLA', 'HOUSE', 'OFFICE', 'DEPT',
            'TOWER', 'PALACE', 'TEMPLE', 'SUBWAY', 'GUEST', 'MARKET']
FILES = {'POST': ['INTRO', 'INTRO2'] + eps('MORN', 20) + ['PRAISE', 'FINE', 'SCOLD', 'WARN', 'SACKED', 'PAYDAY', 'LASTDAY',
                  'E_TOP', 'E_GOOD', 'E_OK', 'E_SACKED', 'LOVE', 'LOVE2', 'NOLOVE'],
         'DELIVER': eps('DLV', 16) + eps('HAND', 6) + eps('FRIEND', 6) + eps('WRONG', 8) + eps('AWAY', 4) + eps('BIZ', 8) + ['MAILBOX', 'GIFT', 'KNOCKED', 'NOTMINE'],
         'CHAT': eps('CHAT', 30),
         'SHOPS': SHOPKEYS + ['VIEW', 'STALL', 'LOBBY'],
         'STRANGERS': eps('STR', 30) + eps('HINT', 4),
         'THINGS': ['VENDING', 'POSTBOX', 'BINOCS', 'EXHIBIT', 'HIT', 'TIRED', 'HUNGRY', 'NOMONEY', 'LIFT', 'STAIRS', 'TRAIN', 'BRIDGE', 'RIVER', 'CLOSED', 'NIGHT']}
STATS = ['ENERGY', 'SPEED', 'BOSS', 'REP', 'TIME', 'LOOKUP', 'APP', 'HAIR', 'LOOK', 'HANBOK', 'FLOWERS', 'ASK']
WHO = {'Y': 0, 'N': 1, 'B': 2, 'X': 3}
NSLOT = 32
MOODS = {'SMILE': 0, 'OPEN': 1, 'CAT': 2, 'O': 3, 'GRIN': 4, 'SMIRK': 5}
ICONS = {'HEART': 0, 'STAR': 1, 'NOTE': 2, 'SPARKLE': 7, 'BROKEN': 9, 'RING': 4, 'CROWN': 4, 'DUCK': 10}
FLAGS = ['LIED', 'HELPED', 'STAYED', 'FORGAVE', 'CHEATED', 'TOLD', 'MET', 'HURT']
WIDTH = 34                      # the text box: 34 letters a line, 5 lines a page
LINES = 5
TOKENS = {'{P}': '\x01', '{N}': '\x02', '{X}': '\x03', '{PLACE}': '\x04', '{B}': '\x05', '{D}': '\x06', '{I}': '\x07',
          '{T}': '\x0b', '{H}': '\x0c'}
TOKW = {'\x01': 8, '\x02': 10, '\x03': 8, '\x04': 20, '\x05': 8, '\x06': 14, '\x07': 6, '\x0b': 10, '\x0c': 20}
OK = set(' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_') | set(TOKENS.values())

# ops
OP_END, OP_SAY, OP_NARR, OP_MOOD, OP_CHOICE, OP_AFF, OP_ICON, OP_GOTO, OP_FLAG, OP_MONEY, OP_WHO, OP_STAT = range(12)

class Err(Exception): pass

def clean(t, where):
    t = t.replace('’', "'").replace('‘', "'").replace('“', '"').replace('”', '"')
    t = t.replace('—', ' - ').replace('–', '-').replace('…', '...').replace('\t', ' ')
    t = t.upper()
    for k, v in TOKENS.items(): t = t.replace(k, v)
    bad = sorted(set(ch for ch in t if ch not in OK))
    if bad: raise Err('%s: letters the font hasn\'t got: %r' % (where, ''.join(bad)))
    return re.sub(' +', ' ', t).strip()

def wrap(t):
    # into lines of WIDTH (the tokens counted at their widest)
    words = t.split(' ')
    lines, cur, w = [], '', 0
    for wd in words:
        ww = sum(TOKW.get(ch, 1) for ch in wd)
        if ww > WIDTH: raise Err('a word too long: ' + wd)
        if cur and w + 1 + ww > WIDTH:
            lines.append(cur); cur, w = wd, ww
        else:
            cur = (cur + ' ' + wd) if cur else wd
            w = w + 1 + ww if w else ww
    if cur: lines.append(cur)
    return lines

def pages(t):
    ls = wrap(t)
    return ['\n'.join(ls[k:k + LINES]) for k in range(0, len(ls), LINES)]

def parse(path):
    """-> {scene: [steps]}; a step: ('say', text) ('narr', text) ('mood', n) ('icon', n) ('aff', n)
    ('flag', n) ('money', n) ('choice', [(label, [steps]), ...])"""
    scenes = {}
    cur = None; opt = None; where = path
    for ln, raw in enumerate(open(path, encoding='utf-8'), 1):
        where = '%s line %d' % (os.path.basename(path), ln)
        line = raw.rstrip('\n').rstrip()
        if not line.strip() or line.lstrip().startswith('#'): continue
        if line.startswith('==='):
            name = line[3:].strip().upper()
            if name in scenes: raise Err(where + ': scene %s twice' % name)
            cur = scenes[name] = []; opt = None
            continue
        if cur is None: raise Err(where + ': text before the first === scene')
        ind = line.startswith('  ') or line.startswith('\t')
        s = line.strip()
        if s.startswith('?'):
            label = clean(s[1:], where)
            if not label: raise Err(where + ': an empty option')
            if len(label) > 30: raise Err(where + ': option over 30 letters: ' + label)
            if cur and cur[-1][0] == 'choice' and opt is not None:
                cur[-1][1].append((label, []))
            else:
                cur.append(('choice', [(label, [])]))
            opt = cur[-1][1][-1][1]
            continue
        target = cur
        if ind and opt is not None: target = opt
        else: opt = None
        target.append(step(s, where))
    for name, st in scenes.items():
        for s in st:
            if s[0] == 'choice' and not (2 <= len(s[1]) <= 3): raise Err('%s: scene %s: a choice needs 2 or 3 options' % (path, name))
        if sum(1 for s in st if s[0] == 'choice') > 2: raise Err('%s: scene %s: more than 2 choices' % (path, name))
    return scenes

def step(s, where):
    if s.startswith('"'):
        t = s[1:]
        if t.endswith('"'): t = t[:-1]
        return ('say', clean(t, where))
    if s.startswith('-') and not re.match(r'^-\d', s): return ('narr', clean(s[1:], where))
    if s.startswith(':'):
        m = s[1:].strip().upper()
        if m in MOODS: return ('mood', MOODS[m])
        if m in ICONS: return ('icon', ICONS[m])
        raise Err(where + ': no such mood or icon: ' + m)
    if re.match(r'^[+-]\d+$', s):
        n = int(s)
        if not -20 <= n <= 20: raise Err(where + ': affection change too big')
        return ('aff', n)
    if s.startswith('*'):
        f = s[1:].strip().upper()
        if f not in FLAGS: raise Err(where + ': no such flag ' + f + ' (' + ' '.join(FLAGS) + ')')
        return ('flag', FLAGS.index(f))
    if s.startswith('$'):
        return ('money', int(s[1:]))
    if s.startswith('@'):
        k = s[1:].strip().upper()
        if k not in WHO: raise Err(where + ': @Y @N @B or @X, not ' + s)
        return ('who', WHO[k])
    if s.startswith('!'):
        m = re.match(r'^!([A-Z]+)\s*([+-]?\d+)$', s.upper())
        if not m or m.group(1) not in STATS: raise Err(where + ': !' + ' !'.join(STATS) + ' and a number: ' + s)
        n = int(m.group(2))
        if not -20 <= n <= 20: raise Err(where + ': a stat change from -20 to 20')
        return ('stat', STATS.index(m.group(1)), n)
    raise Err(where + ': what is this? ' + s)

def check_steps(st, where):
    for s in st:
        if s[0] in ('say', 'narr'): pages(s[1])
        if s[0] == 'choice':
            for lab, sub in s[1]: check_steps(sub, where)

def file_key(path):
    return os.path.splitext(os.path.basename(path))[0].upper()

def check_file(path, person=True):
    sc = parse(path)
    key = file_key(path)
    if key not in FILES: raise Err('%s: not one of the files the game knows: %s' % (path, ' '.join(sorted(FILES))))
    want = FILES[key]
    for n, st in sc.items():
        if n not in want: raise Err('%s: no scene called %s in this file' % (path, n))
        check_steps(st, path + ' ' + n)
    missing = [n for n in want if n not in sc]
    if missing: raise Err('%s: missing scenes: %s' % (path, ' '.join(missing)))
    if list(sc.keys()) != want: raise Err('%s: the scenes must be in this order: %s' % (path, ' '.join(want)))
    words = sum(len(s[1].split()) for st in sc.values() for s in flat(st) if s[0] in ('say', 'narr'))
    return sc, words

def flat(st):
    for s in st:
        yield s
        if s[0] == 'choice':
            for lab, sub in s[1]: yield from flat(sub)

if __name__ == '__main__' and len(sys.argv) > 1 and sys.argv[1] == '--check':
    bad = 0
    for f in sys.argv[2:]:
        try:
            sc, w = check_file(f)
            print('%s: ok, %d scenes, %d words' % (f, len(sc), w))
        except Err as e:
            print('ERROR', e); bad = 1
    sys.exit(bad)

# ================================================================ compiling
# The pages the data can go in (8K each): banks 0-4, 6, 7, 11-15, 19-47 (not 5, 8-10: the
# program; not 16-18: Layer 2). Banks 0-2: the dictionary; 3-4: the directory
RUNS = [(0, 9), (12, 15), (22, 31), (38, 93)]          # (bank 47: the sprites' and tiles' (gfxtool's gfxbank))
DICTW = [(0, 16384), (2, 16384), (4, 16320)]      # the dictionary's windows: page, room (bank 2's top: the NEX file's start stack)
PAGES = [p for a, b in RUNS for p in range(a, b + 1)]
NPEOPLE = 100
GBASE = NPEOPLE * NSLOT

def pieces(line):
    return re.findall(r'[^ ]+ ?| ', line)

def all_texts(scenes_list):
    for sc in scenes_list:
        for st in sc.values():
            for s in flat(st):
                if s[0] in ('say', 'narr'):
                    for pg in pages(s[1]): yield pg
                if s[0] == 'choice':
                    for lab, sub in s[1]: yield lab

def build_dict(texts, limit=48000):
    from collections import Counter
    cnt = Counter()
    for t in texts:
        for line in t.split('\n'):
            for pc in pieces(line):
                if len(pc) >= 3 or (len(pc) == 2 and pc[1] != ' '): cnt[pc] += 1
    cands = [(c * (len(w) - 2) - (len(w) + 3), w) for w, c in cnt.items() if c * (len(w) - 2) - (len(w) + 3) > 0]
    cands.sort(reverse=True)
    words = []; size = 0
    for v, w in cands:
        if len(words) >= 128 + 32 * 256: break
        if size + len(w) + 3 > limit: break
        words.append(w); size += len(w) + 3
    # the most used get the one-byte codes
    words.sort(key=lambda w: -cnt[w])
    return words

def enc_text(t, code):
    out = bytearray()
    for li, line in enumerate(t.split('\n')):
        if li: out.append(10)
        for pc in pieces(line):
            k = code.get(pc)
            if k is None: out += pc.encode('latin-1')
            elif k < 128: out.append(0x80 + k)
            else: out += bytes([0x60 + (k - 128) // 256, (k - 128) % 256])
    return bytes(out)

def enc_steps(st, code, out, base):
    for s in st:
        k = s[0]
        if k in ('say', 'narr'):
            for pg in pages(s[1]):
                out.append(OP_SAY if k == 'say' else OP_NARR); out += enc_text(pg, code); out.append(0)
        elif k == 'mood': out += bytes([OP_MOOD, s[1]])
        elif k == 'icon': out += bytes([OP_ICON, s[1]])
        elif k == 'aff': out += bytes([OP_AFF, s[1] & 255])
        elif k == 'flag': out += bytes([OP_FLAG, s[1]])
        elif k == 'money': out += bytes([OP_MONEY, s[1] & 255, (s[1] >> 8) & 255])
        elif k == 'who': out += bytes([OP_WHO, s[1]])
        elif k == 'stat': out += bytes([OP_STAT, s[1], s[2] & 255])
        elif k == 'choice':
            opts = s[1]; n = len(opts)
            out += bytes([OP_CHOICE, n])
            for lab, sub in opts: out += enc_text(lab, code) + b'\0'
            tab = len(out); out += bytes(2 * n + 2)
            gotos = []
            for j, (lab, sub) in enumerate(opts):
                p = len(out) - base
                out[tab + 2 * j] = p & 255; out[tab + 2 * j + 1] = p >> 8
                enc_steps(sub, code, out, base)
                out.append(OP_GOTO); gotos.append(len(out)); out += b'\0\0'
            after = len(out) - base
            out[tab + 2 * n] = after & 255; out[tab + 2 * n + 1] = after >> 8
            for g in gotos: out[g] = after & 255; out[g + 1] = after >> 8

def enc_scene(st, code):
    out = bytearray()
    enc_steps(st, code, out, 0)
    out.append(OP_END)
    if len(out) > 448: raise Err('a scene over 448 bytes (Main.bas: sb(447))')
    return bytes(out)

class Packer:
    def __init__(s): s.i = 0; s.off = 0; s.data = {p: bytearray(8192) for p in PAGES}
    def page_start(s):
        if s.off: s.i += 1; s.off = 0
    def put(s, b, window=True):
        # b somewhere it can be read through the two-page window (the next page must follow on)
        if s.off + len(b) > 8192:
            nxt = PAGES[s.i + 1] if s.i + 1 < len(PAGES) else None
            if not (window and nxt == PAGES[s.i] + 1 and s.off + len(b) <= 16384):
                s.page_start()
        if s.i >= len(PAGES): raise Err('out of memory')
        at = (PAGES[s.i], s.off)
        p, o = s.i, s.off
        for byte in b:
            if o == 8192: p += 1; o = 0
            s.data[PAGES[p]][o] = byte; o += 1
        s.i, s.off = p, o
        if s.off == 8192: s.i += 1; s.off = 0
        return at
    def used(s): return s.i + (1 if s.off else 0)

ORDER = ['POST', 'DELIVER', 'CHAT', 'SHOPS', 'STRANGERS', 'THINGS']
PREFIX = {'POST': 'PO', 'DELIVER': 'DE', 'CHAT': 'CH', 'SHOPS': 'SH', 'STRANGERS': 'ST', 'THINGS': 'TH'}

# a scene's picture, from the place its first narration names (255: none named; the game picks)
def scene_pic(st): return 255

def compile_all():
    sys.path.insert(0, HERE)
    files = {}; missing = []; nwords = 0
    for key in ORDER:
        path = os.path.join(ROOT, 'scripts', key + '.txt')
        if os.path.exists(path):
            sc, w = check_file(path); files[key] = sc; nwords += w
        else:
            files[key] = {}; missing.append(key)
    # every scene a number: the files one after another, in ORDER
    seq = []; base = {}
    for key in ORDER:
        base[key] = len(seq)
        for name in FILES[key]:
            st = files[key].get(name)
            if st is None: st = [('narr', '(%s %s TO COME)' % (key, name))]
            seq.append(st)
    nscene = len(seq)
    texts = list(all_texts([{k: st for k, st in enumerate(seq)}]))
    words = build_dict(texts)
    code = {w: k for k, w in enumerate(words)}
    pk = Packer()
    wins = []; k = 0
    for pg, room in DICTW:
        start = k; size = 0
        while k < len(words) and size + len(words[k]) + 3 <= room:
            size += len(words[k]) + 3; k += 1
        idx = bytearray(); blob = bytearray(); b0 = (k - start) * 2
        for w in words[start:k]:
            o = b0 + len(blob); idx += bytes([o & 255, o >> 8]); blob += w.encode('latin-1') + b'\0'
        assert len(idx) + len(blob) <= room
        for j, byte in enumerate(idx + blob): pk.data[pg + j // 8192][j % 8192] = byte
        wins.append((start, pg))
    if k < len(words): words = words[:k]; code = {w: n for n, w in enumerate(words)}
    dictat = wins
    while PAGES[pk.i] != 6: pk.i += 1
    assert nscene * 6 <= 16384
    dirat = pk.put(bytes(nscene * 6))
    assert dirat == (6, 0)
    pbin = open(os.path.join(HERE, 'people.bin'), 'rb').read()
    pk.page_start()
    peopleat = pk.put(pbin)
    picat = []
    fbin = open(os.path.join(HERE, 'faces.bin'), 'rb').read()
    pk.page_start()
    while not (PAGES[pk.i + 1] == PAGES[pk.i] + 1 and PAGES[pk.i + 2] == PAGES[pk.i] + 2): pk.i += 1
    faceat = pk.put(fbin, window=False)
    gbin = open(os.path.join(HERE, 'game.bin'), 'rb').read()
    while not (PAGES[pk.i + 1] == PAGES[pk.i] + 1 and PAGES[pk.i + 2] == PAGES[pk.i] + 2): pk.i += 1
    gameat = pk.put(gbin, window=False)
    # the city: each table from the start of a page (big ones run on through the next pages)
    worldat = []
    for t in json.load(open(os.path.join(HERE, 'world', 'manifest.json'))):
        b = open(os.path.join(HERE, t['file']), 'rb').read()
        pk.page_start()
        npg = (len(b) + 8191) // 8192
        while not all(pk.i + j < len(PAGES) and PAGES[pk.i + j] == PAGES[pk.i] + j for j in range(npg + 1)): pk.i += 1
        at = (PAGES[pk.i], 0)
        for j, byte in enumerate(b): pk.data[PAGES[pk.i] + j // 8192][j % 8192] = byte
        pk.i += npg; pk.off = 0
        if len(b) % 8192: pk.i -= 1; pk.off = len(b) % 8192
        worldat.append((t['name'], at[0], t['size'], t['n']))
    dirb = bytearray(nscene * 5)
    total = 0; biggest = (0, '')
    for n, st in enumerate(seq):
        b = enc_scene(st, code)
        at = pk.put(b); total += len(b)
        if len(b) > biggest[0]: biggest = (len(b), n)
        e = n * 5
        dirb[e:e + 5] = bytes([at[0], at[1] & 255, at[1] >> 8, len(b) & 255, len(b) >> 8])
    dirb += bytes(scene_pic(st) for st in seq)
    for k2, byte in enumerate(dirb):
        pg = 6 + k2 // 8192; pk.data[pg][k2 % 8192] = byte
    used_pages = PAGES[:pk.used()]
    databanks = sorted(set(p // 2 for p in used_pages))
    banks = sorted(set(databanks + [47]))
    dat = bytearray()
    for b in databanks: dat += pk.data.get(2 * b, bytearray(8192)) + pk.data.get(2 * b + 1, bytearray(8192))
    os.makedirs(os.path.join(ROOT, 'build'), exist_ok=True)
    open(os.path.join(ROOT, 'build', NAME + '.DAT'), 'wb').write(dat)
    cfgp = os.path.join(ROOT, 'game.json')
    cfg = json.load(open(cfgp)); cfg['banks'] = banks
    json.dump(cfg, open(cfgp, 'w'))
    print('story: %d scenes, %d words (missing files: %s), %d bytes of scenes, %d words in the dictionary'
          % (nscene, nwords, ' '.join(missing) or 'none', total, len(words)))
    print('the biggest scene: %d bytes (scene %d)' % biggest)
    print('pages used %d of %d (%d K); banks %s' % (len(used_pages), len(PAGES), len(used_pages) * 8, banks))
    write_cls(dirat, dictat, len(words), peopleat, picat, databanks, base, nscene, faceat, gameat, worldat)

def write_cls(dirat, dictat, nwords, peopleat, picat, banks, base, nscene, faceat, gameat, worldat):
    tabs = json.load(open(os.path.join(HERE, 'people_tabs.json')))
    # which window a token is in: HL the token -> B the window's page, HL the token in it
    wl = []
    for j in range(len(dictat) - 1, 0, -1):
        st, pg = dictat[j]
        wl += ['            ld de, %d' % st, '            or a', '            sbc hl, de',
               '            ld b, %d' % pg, '            jr nc, ex_win', '            add hl, de']
    wl += ['            ld b, %d' % dictat[0][1]]
    global WINASM
    WINASM = '\n'.join(wl)
    L = []
    A = L.append
    A("' Data - LITTLE SEOUL's story, people and pictures, in the Next's other RAM (made by tools/storyc.py:")
    A("' don't edit). The data itself is build/%s.DAT, put in banks %s by Init's assembler" % (NAME, ', '.join(map(str, banks))))
    A("' (INCBIN: keep the .DAT file next to the .asm), and game.json's \"banks\" puts them in the NEX file.")
    A("' Everything is read through MMU slots 6 and 7 (#C000-#FFFF, two pages at a time), then bank 5")
    A("' (the tilemap) put back.")
    A("' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License")
    A('Option Explicit')
    A('')
    A('Public Const NSCENE = %d, FACEPAGE = %d, GAMEPAGE = %d' % (nscene, faceat[0], gameat[0]))
    A("' the city's tables (tools/city.py): each from the start of its page")
    for n, pg, size, cnt in worldat:
        A('Public Const W_%s = %d     \' %d bytes each, %d' % (n, pg, size, cnt))
    A("' the scenes' pictures: a byte each at DIRPAGE's NSCENE * 5 + scene (255: none named)")
    A('Public Const DIRPAGE = %d, PPAGE = %d, POFF = %d, PREC = 32' % (dirat[0], peopleat[0], peopleat[1]))
    A('Public Const T_FULL = %d, T_JOB = %d, T_HOBBY = %d, T_CITY = %d, T_TRAIT = %d' % (tabs['FULL'], tabs['JOB'], tabs['HOBBY'], tabs['CITY'], tabs['TRAIT']))
    for key, pre in PREFIX.items():
        A("' %s" % key)
        A('Public Const %s_BASE = %d' % (pre, base[key]))
        names = FILES[key]
        for k in range(0, len(names), 6):
            A('Public Const ' + ', '.join('%s_%s = %d' % (pre, n, base[key] + k + j) for j, n in enumerate(names[k:k + 6])))
    A('Public Const OP_END = 0, OP_SAY = 1, OP_NARR = 2, OP_MOOD = 3, OP_CHOICE = 4, OP_AFF = 5, OP_ICON = 6, OP_GOTO = 7, OP_FLAG = 8, OP_MONEY = 9, OP_WHO = 10, OP_STAT = 11')
    A('')
    A('Private cs As Integer, cn As Integer, xs As Integer, xd As Integer, xt As Integer, pp As Integer, po As Integer, py As Integer, pl As Integer')
    A('')
    A("' Init: (puts the data in the banks, when the NEX file is made)")
    A('Public Sub Init()')
    A('#asm')
    A('            jp di_end')
    A('di_end:')
    for k, b in enumerate(banks):
        A('            MMU 6 7, %d' % (2 * b))
        A('            ORG #C000')
        A('            INCBIN "%s.DAT", %%d, 16384' % NAME % (k * 16384))
    A('            MMU 6 7, 0')
    A('            ORG di_end')
    A('#endasm')
    A('End Sub')
    A('')
    A("' Copy page, off, n, dest: n bytes (up to 8192) from page's offset off (on into the next page) to")
    A("' dest (below #C000)")
    A('Public Sub Copy(ByVal page As Integer, ByVal off As Integer, ByVal n As Integer, ByVal dest As Integer)')
    A('#asm')
    A('''            pop hl
            ld a, (hl)
            ld (dc_p1 + 1), a
            inc a
            ld (dc_p2 + 1), a
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld hl, #C000
            add hl, de
            ld ({cs}), hl
            pop hl
            ld c, (hl)
            inc hl
            ld b, (hl)
            ld ({cn}), bc
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld bc, #243B
            ld a, #56
            out (c), a
            inc b
dc_p1:
            ld a, 0
            out (c), a
            dec b
            ld a, #57
            out (c), a
            inc b
dc_p2:
            ld a, 0
            out (c), a
            ld hl, ({cs})
            ld bc, ({cn})
            ld a, b
            or c
            jr z, dc_done
            ldir
dc_done:''')
    A(RESTORE)
    A('#endasm')
    A('End Sub')
    A('')
    A("' Expand(src, dst): the text at src (a scene's, in RAM) up to its end (0) or the line's (10), its")
    A("' words from the dictionary, into dst (ending 0): gives where the next starts (Term(): which end)")
    A('Public Function Expand(ByVal src As Integer, ByVal dst As Integer) As Integer')
    A('#asm')
    A('''            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld ({xs}), de
            pop hl
            ld e, (hl)
            inc hl
            ld d, (hl)
            ld ({xd}), de
            ld hl, ({xs})
            ld de, ({xd})
ex_lp:
            ld a, (hl)
            inc hl
            or a
            jr z, ex_end
            cp 10
            jr z, ex_end
            cp #60
            jr nc, ex_tok
            ld (de), a
            inc de
            jr ex_lp
ex_tok:
            ld ({xd}), de           ; (DE: where the text goes - kept while the word is looked up)
            cp #80
            jr nc, ex_t1
            sub #60
            ld b, a
            ld c, (hl)
            inc hl
            ld ({xs}), hl
            ld hl, 128
            add hl, bc
            jr ex_look
ex_t1:
            ld ({xs}), hl
            sub #80
            ld l, a
            ld h, 0
ex_look:
%s
ex_win:
            ld a, b                 ; the window's two pages in
            ld bc, #243B
            ld (ex_w2 + 1), a
            inc a
            ld (ex_w3 + 1), a
            ld a, #56
            out (c), a
            inc b
ex_w2:
            ld a, 0
            out (c), a
            dec b
            ld a, #57
            out (c), a
            inc b
ex_w3:
            ld a, 0
            out (c), a
            add hl, hl
            ld bc, #C000
            add hl, bc
            ld c, (hl)
            inc hl
            ld b, (hl)
            ld hl, #C000
            add hl, bc
            ld de, ({xd})
ex_cp:
            ld a, (hl)
            or a
            jr z, ex_cpd
            ld (de), a
            inc de
            inc hl
            jr ex_cp
ex_cpd:
            ld hl, ({xs})
            jp ex_lp
ex_end:
            ld ({xt}), a
            xor a
            ld (de), a
            ld ({xs}), hl''' % WINASM)
    A(RESTORE)
    A('''            pop hl
            ld de, ({xs})
            ld (hl), e
            inc hl
            ld (hl), d''')
    A('#endasm')
    A('End Function')
    A('')
    A("' Term(): the last Expand's end: 0 the text's, 10 a line's")
    A('Public Function Term() As Integer')
    A('  Term = xt And 255')
    A('End Function')
    A('')
    open(os.path.join(ROOT, 'Data.cls'), 'w').write('\r\n'.join(L) + '\r\n')
    print('Data.cls written')

RESTORE = '''            ld bc, #243B            ; bank 5 back in slots 6 and 7
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
            dec b
            ld a, #57
            out (c), a
            inc b
            ld a, 11
            out (c), a'''

if __name__ == '__main__' and (len(sys.argv) == 1 or sys.argv[1] != '--check'):
    try:
        compile_all()
    except Err as e:
        print('ERROR', e); sys.exit(1)
