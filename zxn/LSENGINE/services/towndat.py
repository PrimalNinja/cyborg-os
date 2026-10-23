# towndat.py - the LITTLE SEOUL ENGINE's town data: TOWN.DAT for the TOWN service (CyborgOS), from
# the engine's own city (tools/world/: shops.bin, homes.bin, sched.bin - made by tools/city.py - and
# tools/people.json), so the town the service runs is the very one the game draws.
#   python3 services/towndat.py [out dir]        (default: services/build/) -> TOWN.DAT
# TOWN.DAT (little endian):
#   0  "LSTD", 4 version (1), 5 shop types (40), 6 people (100), 7 -
#   8  per type: the first of its shops in the list below (2 bytes each), then the end (41 words)
#   then the shops, sorted by type: shop number (2), its street room (1: 0-191)
#   then the people, 32 bytes each:
#     0 model (0 SUIT, 1 KEEPER, 2 STAR), 1 LUN (1-), 2 trait (TRAITS), 3 girl
#     4 home shop (2), 6 its room, 7 work shop (2: 65535 none), 9 its room (255 none)
#     10 work starts (half hours from 9:00), 11 work ends (half hours from 9:00, not included)
#     12 away (1: out of town on their second kind of day), 13-15 haunts (HAUNTS index, 255 none)
#     16 kind of day mask: bit k = works on day kind k ((p + day) mod 3), 17 -, 18-27 name, 28-31 -
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import os, sys, json, struct, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
T = os.path.join(ROOT, 'tools')            # the city's own tools: world/*.bin (city.py) and people.json
A = os.path.join(T, 'world')
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'build')

NTYPE = 40
MODELS = ['SUIT', 'KEEPER', 'STAR']
SUIT = {'LAWYER', 'BANKER', 'STOCK TRADER', 'PROGRAMMER', 'ACCOUNTANT', 'ARCHITECT', 'DENTIST', 'DOCTOR',
        'PHYSIO', 'RADIO HOST', 'GAME DEVELOPER', 'VET', 'TEACHER', 'JOURNALIST', 'EVENT PLANNER', 'NURSE',
        'LIBRARIAN', 'SALES MANAGER', 'PILOT', 'FLIGHT ATTENDANT', 'ZOOKEEPER', 'DESIGNER', 'WEBTOON ARTIST'}
KEEPER = {'HAIRSTYLIST', 'BOOKSHOP OWNER', 'TATTOO ARTIST', 'FLORIST', 'FASHION BUYER', 'MECHANIC', 'YOGA TEACHER',
          'FIREFIGHTER', 'BAKER', 'BARTENDER', 'BARISTA', 'SOMMELIER', 'PERSONAL TRAINER', 'POTTER', 'CHEF', 'COURIER'}
# (everyone else - models, streamers, actors, singers, dancers, musicians, DJs, photographers, the sea
# people - is a STAR)
TRAITS = ['BORN LEADER', 'SHY', 'PRANKSTER', 'CHARISMATIC', '4D', 'FOODIE', 'SOFTIE', 'HARD WORKER', 'CHEERFUL', 'CHIC']
# a haunt (people.json) -> the tag the models know it by (TOWN.bas's tags, in this order)
HAUNTS = ['OFFICE', 'CAFE', 'MALL', 'BOUTIQUE', 'GYM', 'PARK', 'BEACH', 'CINEMA', 'BAR', 'CLUB', 'KARAOKE',
          'CONCERT HALL', 'FUNFAIR', 'CHAPEL']
AWAY = {'FLIGHT ATTENDANT', 'PILOT', 'MARINE BIOLOGIST', 'SURFER', 'LIFEGUARD'}

people = json.load(open(os.path.join(T, 'people.json')))['people']
shops = open(os.path.join(A, 'shops.bin'), 'rb').read()
homes = open(os.path.join(A, 'homes.bin'), 'rb').read()
sched = open(os.path.join(A, 'sched.bin'), 'rb').read()
nshop = len(shops) // 8
def stype(k): return shops[k * 8]
def sroom(k): return shops[k * 8 + 5]

# the shops by type
bytype = collections.defaultdict(list)
for k in range(nshop):
    t = stype(k)
    if t < NTYPE: bytype[t].append(k)
starts = []; lst = bytearray(); n = 0
for t in range(NTYPE):
    starts.append(n)
    for k in bytype[t]:
        lst += struct.pack('<HB', k, sroom(k)); n += 1
starts.append(n)

# the people: home from homes.bin; work and its hours from LITTLE SEOUL's own days (sched.bin: 3 kinds
# of day, 19 half hours from 9:00 each) - the working day's run of the one place that isn't home
recs = bytearray(); luns = [0, 0, 0]; summary = collections.Counter()
for p, per in enumerate(people):
    home = struct.unpack_from('<H', homes, p * 4)[0]
    days = [[struct.unpack_from('<H', sched, p * 128 + (k * 19 + t) * 2)[0] for t in range(19)] for k in range(3)]
    work, ws, we, mask = 65535, 0, 0, 0
    c = collections.Counter(v for v in days[0] if v not in (home, 65535))
    if c and c.most_common(1)[0][1] >= 6:
        work = c.most_common(1)[0][0]
        idx = [t for t in range(19) if days[0][t] == work]
        ws, we = idx[0], idx[-1] + 1
        for k in range(3):
            if days[k].count(work) >= 6: mask |= 1 << k
    job = per['job']
    model = 0 if job in SUIT else 1 if job in KEEPER else 2
    luns[model] += 1
    hs = [HAUNTS.index(h) for h in per['haunts'] if h in HAUNTS][:3]
    hs += [255] * (3 - len(hs))
    r = bytearray(32)
    r[0] = model; r[1] = luns[model]; r[2] = TRAITS.index(per['trait']); r[3] = per['girl']
    struct.pack_into('<HB', r, 4, home, sroom(home))
    struct.pack_into('<HB', r, 7, work, sroom(work) if work != 65535 else 255)
    r[10] = ws; r[11] = we; r[12] = 1 if job in AWAY else 0
    r[13:16] = bytes(hs); r[16] = mask
    r[18:28] = (per['name'][:10] + ' ' * 10)[:10].encode('latin-1')
    recs += r
    summary[MODELS[model]] += 1

out = bytearray(b'LSTD') + bytes([1, NTYPE, len(people), 0])
for s in starts: out += struct.pack('<H', s)
out += lst + recs
os.makedirs(OUT, exist_ok=True)
open(os.path.join(OUT, 'TOWN.DAT'), 'wb').write(out)
print('TOWN.DAT: %d bytes, %d shops, %d people (%s), %d with work' % (len(out), n, len(people),
      ', '.join('%s %d' % kv for kv in sorted(summary.items())), sum(1 for p in range(len(people)) if recs[p * 32 + 7:p * 32 + 9] != b'\xff\xff')))
