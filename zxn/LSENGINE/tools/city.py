# city.py - LITTLE SEOUL's Seoul: 16 x 12 screens of streets (192 of them, each 16 x 12 blocks),
# real districts where they really are (roughly), real landmarks, the Han river and its bridges,
# a subway, and every door in town a shop, a flat, an office or a house with somebody behind it.
# The shops are groups of blocks (a roof, a sign, a window, a door); the insides are templates
# (tools/templates.py).
# Writes tools/world/*.bin (storyc.py puts them in the Next's other RAM), Town.cls (the numbers
# the game needs) and tools/map_preview.png.    (run: python3 tools/city.py, after blocks.py)
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import os, sys, random, json
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
sys.path.insert(0, HERE)
import blocks as BL
from templates import T as TEMPLATES, KEY, FLOORS

BI = BL.INDEX
W, H = 16, 12            # screens across, down
CW, CH = 16, 12          # blocks a screen
R = random.Random(2026)

# ---------------------------------------------------------------- shop types
# key, name, sign, sign block, frontage, inside (ground, upper, top), floors (min, max), keeper title, keeper sprite
TYPES = [
    ('CAFE', 'CAFE', 'CAFE', 'AWN2', 'shop2', ('CAFE',), (1, 1), 'BARISTA', 2),
    ('CONV', 'CONVENIENCE', '24H', 'SIGN2', 'shop', ('CONV',), (1, 1), 'CLERK', 1),
    ('CHICKEN', 'CHICKEN', 'CHIKN', 'SIGN0', 'shop', ('CHICKEN',), (1, 1), 'OWNER', 1),
    ('BBQ', 'BBQ HOUSE', 'GOGI', 'SIGN4', 'shop', ('BBQ',), (1, 1), 'AJUMMA', 3),
    ('NOODLE', 'NOODLE BAR', 'MYEON', 'SIGN1', 'shop', ('NOODLE',), (1, 1), 'CHEF', 1),
    ('BAKERY', 'BAKERY', 'BREAD', 'AWN3', 'shop2', ('BAKERY',), (1, 1), 'BAKER', 2),
    ('PHARMACY', 'PHARMACY', 'YAK', 'SIGN2', 'shop', ('PHARMACY',), (1, 1), 'PHARMACIST', 4),
    ('COSMETICS', 'COSMETICS', 'BEAUTY', 'SIGN3', 'shop3', ('COSMETICS',), (1, 1), 'CLERK', 2),
    ('PCBANG', 'PC BANG', 'PC', 'SIGN5', 'shop', ('PCBANG',), (1, 1), 'STAFF', 1),
    ('NORAE', 'NORAEBANG', 'NORAE', 'SIGN6', 'shop3', ('NORAE',), (1, 1), 'OWNER', 3),
    ('SALON', 'HAIR SALON', 'HAIR', 'SIGN3', 'shop3', ('SALON',), (1, 1), 'STYLIST', 2),
    ('BOUTIQUE', 'BOUTIQUE', 'STYLE', 'SIGN5', 'shop3', ('BOUTIQUE',), (1, 1), 'CLERK', 2),
    ('PHONE', 'PHONE SHOP', 'MOBILE', 'SIGN1', 'shop', ('PHONE',), (1, 1), 'CLERK', 1),
    ('BANK', 'BANK', 'BANK', 'SIGN1', 'glass', ('BANK',), (1, 1), 'TELLER', 2),
    ('BOOKSHOP', 'BOOKSHOP', 'BOOKS', 'SIGN4', 'shop', ('BOOKSHOP',), (1, 1), 'CLERK', 4),
    ('TEAHOUSE', 'TEAHOUSE', 'CHA', None, 'hanok', ('TEAHOUSE',), (1, 1), 'HOST', 2),
    ('CRAFT', 'CRAFT SHOP', 'CRAFT', None, 'hanok', ('CRAFT',), (1, 1), 'ARTISAN', 4),
    ('HANBOK', 'HANBOK RENTAL', 'HANBOK', 'SIGN3', 'shop3', ('HANBOK',), (1, 1), 'TAILOR', 2),
    ('GYM', 'GYM', 'GYM', 'SIGN5', 'shop', ('GYM',), (1, 1), 'TRAINER', 1),
    ('FLORIST', 'FLORIST', 'FLOWER', 'AWN1', 'shop2', ('FLORIST',), (1, 1), 'FLORIST', 2),
    ('FISH', 'FISH SHOP', 'FISH', 'AWN2', 'shop', ('FISH',), (1, 1), 'FISHMONGER', 3),
    ('POST', 'POST OFFICE', 'POST', 'SIGN0', 'glass', ('POST',), (1, 1), 'POSTMASTER', 1),
    ('POLICE', 'POLICE BOX', 'POLICE', 'SIGN1', 'shop', ('POLICE',), (1, 1), 'OFFICER', 1),
    ('CLINIC', 'CLINIC', 'CLINIC', 'SIGN7', 'shop', ('HOSPITAL',), (1, 1), 'NURSE', 2),
    ('ELECTRO', 'ELECTRONICS', 'TECH', 'SIGN5', 'shop', ('ELECTRO',), (1, 1), 'CLERK', 1),
    ('THEATRE', 'THEATRE', 'STAGE', 'SIGN6', 'shop3', ('THEATRE',), (1, 1), 'USHER', 2),
    ('CLUB', 'CLUB', 'CLUB', 'SIGN5', 'shop3', ('CLUB',), (1, 1), 'BOUNCER', 1),
    ('MUSEUM', 'MUSEUM', 'MUSEUM', None, 'land', ('MUSEUM',), (1, 1), 'CURATOR', 4),
    ('HOTEL', 'HOTEL', 'HOTEL', 'SIGN1', 'glass', ('HOTEL',), (1, 1), 'CONCIERGE', 1),
    ('APT', 'APT', '', None, 'apt', ('APT_LOBBY', 'APT_FLOOR'), (6, 15), 'GUARD', 4),
    ('VILLA', 'VILLA', '', None, 'villa', ('VILLA_G', 'VILLA_UP'), (3, 4), '', 0),
    ('HOUSE', 'HOUSE', '', None, 'house', (), (1, 1), '', 0),
    ('OFFICE', 'TOWER', '', None, 'glass', ('OFFICE_LOBBY', 'OFFICE_FLOOR'), (5, 12), 'RECEPTION', 2),
    ('DEPT', 'DEPT STORE', 'DEPT', None, 'glass', ('DEPT_G', 'DEPT_UP', 'DEPT_FOOD'), (4, 5), 'CLERK', 2),
    ('TOWER', 'TOWER', '', None, 'land', ('TOWER_LOBBY', 'OBSERVATORY', 'OBSERVATORY'), (2, 2), 'GUIDE', 2),
    ('PALACE', 'HALL', '', None, 'land', ('PALACE',), (1, 1), 'GUIDE', 2),
    ('TEMPLE', 'TEMPLE', '', None, 'land', ('TEMPLE',), (1, 1), 'MONK', 1),
    ('SUBWAY', 'STATION', '', None, 'land', ('SUBWAY',), (1, 1), 'STAFF', 1),
    ('GUEST', 'GUESTHOUSE', 'STAY', None, 'hanok', ('HOTEL',), (1, 1), 'HOST', 3),
    ('MARKET', 'MARKET STALL', '', None, 'land', (), (1, 1), 'AJUMMA', 3),
]
TY = {t[0]: k for k, t in enumerate(TYPES)}
TPLNAMES = list(TEMPLATES.keys())
TP = {n: k for k, n in enumerate(TPLNAMES)}

WORDS = ['MINT', 'MOON', 'STAR', 'SUNNY', 'HANA', 'DURI', 'SORA', 'BADA', 'NARU', 'GAON', 'BORA', 'HANBIT',
         'SEOUL', 'JOY', 'LUCKY', 'HAPPY', 'GOLDEN', 'BLUE', 'GREEN', 'CHERRY', 'PEACH', 'MAPLE', 'PINE', 'RIVER',
         'CLOUD', 'DREAM', "KIM'S", "PARK'S", "LEE'S", "CHOI'S", 'OLD', 'NEW', 'ROYAL', 'URBAN', 'COZY', 'TINY',
         'BIG', 'MAGPIE', 'TIGER', 'LOTUS', 'JADE', 'PEARL', 'AMBER', 'SILVER', 'RAINBOW', 'MORNING', 'DAWN', 'NOON',
         'HILL', 'SPRING', 'AUTUMN', 'SNOW', 'SAKURA', 'BAMBOO', 'POP', 'HOPE', 'ARIRANG', 'NAMU', 'BIT', 'ONE',
         'TWIN', 'SKY', 'HAN', 'NEO']
assert len(WORDS) == 64

# ---------------------------------------------------------------- districts
# name, kind, x0, y0, w, h; kinds: COMM APTS OFFICE HANOK MARKET PARK MOUNT RIVER PALACE
DISTRICTS = [
    ('BUKHANSAN', 'MOUNT', 0, 0, 3, 2), ('SEOCHON', 'HANOK', 3, 0, 2, 2), ('GYEONGBOKGUNG', 'PALACE', 5, 0, 2, 2),
    ('BUKCHON', 'HANOK', 7, 0, 2, 2), ('CHANGDEOKGUNG', 'PALACE', 9, 0, 2, 2), ('DAEHANGNO', 'COMM', 11, 0, 2, 2),
    ('SEONGBUK', 'APTS', 13, 0, 3, 2),
    ('HONGDAE', 'COMM', 0, 2, 2, 2), ('SINCHON', 'COMM', 2, 2, 2, 2), ('SEODAEMUN', 'APTS', 4, 2, 1, 2),
    ('GWANGHWAMUN', 'OFFICE', 5, 2, 2, 2), ('INSADONG', 'HANOK', 7, 2, 2, 2), ('JONGNO', 'COMM', 9, 2, 1, 2),
    ('GWANGJANG', 'MARKET', 10, 2, 2, 2), ('DONGDAEMUN', 'COMM', 12, 2, 2, 2), ('WANGSIMNI', 'APTS', 14, 2, 2, 2),
    ('MANGWON', 'MARKET', 0, 4, 2, 1), ('MAPO', 'APTS', 2, 4, 2, 1), ('NAMDAEMUN', 'MARKET', 4, 4, 1, 1),
    ('CITY HALL', 'OFFICE', 5, 4, 1, 1), ('MYEONGDONG', 'COMM', 6, 4, 2, 1), ('EULJIRO', 'OFFICE', 8, 4, 2, 1),
    ('SINDANG', 'MARKET', 10, 4, 2, 1), ('SEONGDONG', 'APTS', 12, 4, 2, 2), ('KONKUK', 'COMM', 14, 4, 2, 2),
    ('GONGDEOK', 'APTS', 0, 5, 2, 1), ('SEOUL STATION', 'OFFICE', 2, 5, 2, 1), ('NAMSAN', 'MOUNT', 4, 5, 4, 1),
    ('YAKSU', 'APTS', 8, 5, 2, 1), ('SEONGSU', 'COMM', 10, 5, 2, 1),
    ('HAPJEONG', 'COMM', 0, 6, 2, 1), ('YONGSAN', 'COMM', 2, 6, 2, 1), ('HAEBANGCHON', 'APTS', 4, 6, 2, 1),
    ('ITAEWON', 'COMM', 6, 6, 2, 1), ('HANNAM', 'APTS', 8, 6, 2, 1), ('SEOUL FOREST', 'PARK', 10, 6, 2, 1),
    ('GWANGJIN', 'APTS', 12, 6, 4, 1),
    ('HAN RIVER', 'RIVER', 0, 7, 16, 1),
    ('YEOUIDO', 'OFFICE', 0, 8, 3, 2), ('NORYANGJIN', 'MARKET', 3, 8, 2, 2), ('BANPO', 'APTS', 5, 8, 3, 2),
    ('SINSA', 'COMM', 8, 8, 2, 2), ('APGUJEONG', 'COMM', 10, 8, 2, 2), ('CHEONGDAM', 'COMM', 12, 8, 2, 2),
    ('JAMSIL', 'APTS', 14, 8, 2, 2),
    ('YEONGDEUNGPO', 'MARKET', 0, 10, 2, 2), ('GURO', 'OFFICE', 2, 10, 2, 2), ('SILLIM', 'COMM', 4, 10, 1, 2),
    ('GWANAK', 'MOUNT', 5, 10, 1, 2), ('SEOCHO', 'OFFICE', 6, 10, 2, 2), ('GANGNAM', 'COMM', 8, 10, 2, 2),
    ('YEOKSAM', 'OFFICE', 10, 10, 2, 2), ('SAMSEONG', 'OFFICE', 12, 10, 2, 2), ('SONGPA', 'PARK', 14, 10, 2, 2),
]
DGRID = [[None] * W for _ in range(H)]
for k, (n, kind, x0, y0, w, h) in enumerate(DISTRICTS):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            assert DGRID[y][x] is None, (n, x, y)
            DGRID[y][x] = k
for y in range(H):
    for x in range(W): assert DGRID[y][x] is not None, (x, y)
DK = {d[0]: k for k, d in enumerate(DISTRICTS)}

# what's in the shops, by the kind of district (weights), and a district's own extras
MIX = {
    'COMM': {'CAFE': 5, 'CONV': 3, 'CHICKEN': 2, 'BBQ': 2, 'NOODLE': 2, 'BAKERY': 1, 'PHARMACY': 1, 'COSMETICS': 2,
             'PCBANG': 1, 'NORAE': 1, 'SALON': 1, 'BOUTIQUE': 2, 'PHONE': 1, 'BANK': 1, 'BOOKSHOP': 1, 'FLORIST': 1,
             'VILLA': 2, 'GYM': 1, 'CLINIC': 1, 'HOTEL': 0.5, 'POLICE': 0.3},
    'APTS': {'APT': 8, 'VILLA': 4, 'CONV': 2, 'CAFE': 1, 'CHICKEN': 1, 'SALON': 1, 'PHARMACY': 1, 'BAKERY': 1,
             'CLINIC': 0.5, 'POLICE': 0.3, 'GYM': 0.5, 'FLORIST': 0.5},
    'OFFICE': {'OFFICE': 6, 'CAFE': 3, 'CONV': 2, 'BANK': 2, 'NOODLE': 1, 'HOTEL': 1, 'DEPT': 0.5, 'BBQ': 1, 'CLINIC': 0.5,
               'PHONE': 0.5, 'GYM': 0.5},
    'HANOK': {'HOUSE': 5, 'TEAHOUSE': 2, 'CRAFT': 2, 'HANBOK': 1, 'GUEST': 1, 'CAFE': 1},
    'MARKET': {'NOODLE': 2, 'BBQ': 2, 'FLORIST': 1, 'BOUTIQUE': 1, 'CONV': 1, 'PHARMACY': 1, 'CHICKEN': 1, 'VILLA': 1,
               'BAKERY': 1},
}
EXTRA = {'HONGDAE': {'CLUB': 3, 'NORAE': 2, 'CAFE': 2}, 'DAEHANGNO': {'THEATRE': 4}, 'MYEONGDONG': {'COSMETICS': 5},
         'ITAEWON': {'CLUB': 2, 'BBQ': 1}, 'SINSA': {'BOUTIQUE': 3, 'CAFE': 3}, 'APGUJEONG': {'BOUTIQUE': 3, 'SALON': 3},
         'CHEONGDAM': {'BOUTIQUE': 4, 'SALON': 2}, 'SEONGSU': {'CAFE': 6}, 'YONGSAN': {'ELECTRO': 5},
         'GANGNAM': {'CLINIC': 3, 'PCBANG': 2, 'NORAE': 2}, 'NORYANGJIN': {'FISH': 8}, 'KONKUK': {'CHICKEN': 2, 'PCBANG': 2},
         'SINCHON': {'PCBANG': 2, 'NORAE': 1, 'BOOKSHOP': 1}, 'INSADONG': {'CRAFT': 3, 'TEAHOUSE': 2},
         'DONGDAEMUN': {'BOUTIQUE': 4}, 'SEOCHON': {'CAFE': 1}, 'GWANGJANG': {'NOODLE': 2, 'BOUTIQUE': 1}}

# the subway: a station in these screens (x, y, name, lines)
STATIONS = [
    (1, 3, 'HONGIK UNIV.', '2'), (3, 3, 'SINCHON', '2'), (6, 3, 'GWANGHWAMUN', '5'), (8, 2, 'ANGUK', '3'),
    (9, 3, 'JONGGAK', '1'), (11, 1, 'HYEHWA', '4'), (13, 3, 'DONGDAEMUN', '1 4'), (15, 3, 'WANGSIMNI', '2 5'),
    (5, 4, 'CITY HALL', '1 2'), (7, 4, 'MYEONGDONG', '4'), (2, 4, 'MAPO', '5'), (10, 4, 'SINDANG', '2 6'),
    (3, 5, 'SEOUL STATION', '1 4'), (11, 5, 'SEONGSU', '2'), (15, 5, 'KONKUK UNIV.', '2 7'), (7, 6, 'ITAEWON', '6'),
    (3, 6, 'YONGSAN', '1'), (1, 8, 'YEOUIDO', '5 9'), (4, 8, 'NORYANGJIN', '1 9'), (9, 8, 'SINSA', '3'),
    (11, 9, 'APGUJEONG', '3'), (14, 9, 'JAMSIL', '2 8'), (1, 11, 'YEONGDEUNGPO', '1'), (3, 11, 'GURO DIGITAL', '2'),
    (4, 11, 'SILLIM', '2'), (7, 11, 'EXPRESS BUS', '3 7 9'), (9, 11, 'GANGNAM', '2'), (12, 11, 'SAMSEONG', '2'),
    (6, 9, 'BANPO', '9'), (13, 0, 'SEONGSHIN UNIV.', '4'),
]
BRIDGES = {1: 'YANGHWA BRIDGE', 4: 'HANGANG BRIDGE', 7: 'BANPO BRIDGE', 10: 'SEONGSU BRIDGE', 13: 'JAMSIL BRIDGE'}

NAMES = []          # landmark / special names (shop name byte >= 128)
def custom(n):
    if n not in NAMES: NAMES.append(n)
    return 128 + NAMES.index(n)

SHOPS = []          # [type, floors, name, number, district, room, doorcell, keeper]
def new_shop(ty, room, cell, name=None, floors=None, number=None):
    t = TYPES[TY[ty]]
    if floors is None:
        lo, hi = t[6]; floors = R.randint(lo, hi)
    if name is None: name = R.randrange(64)
    elif isinstance(name, str): name = custom(name)
    if number is None: number = R.randint(1, 99)
    x, y = room % W, room // W
    SHOPS.append([TY[ty], floors, name, number, DGRID[y][x], room, cell, 255])
    return len(SHOPS) - 1

# ---------------------------------------------------------------- a screen
class Screen:
    def __init__(s, x, y):
        s.x, s.y = x, y; s.room = y * W + x
        s.c = [['GRASS'] * CW for _ in range(CH)]
        s.doors = []          # (cell, shop, signx, signw)
        s.flags = 0           # 1 cars, 2 market stalls, 4 bridge
        s.d = DGRID[y][x]
    def set(s, x, y, b):
        if 0 <= x < CW and 0 <= y < CH: s.c[y][x] = b
    def rect(s, x0, y0, x1, y1, b):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1): s.set(x, y, b)
    def door(s, x, y, ty, sx=None, sw=0, **kw):
        sh = new_shop(ty, s.room, y * CW + x, **kw)
        s.doors.append((y * CW + x, sh, x if sx is None else sx, sw))
        return sh

def pick(mix):
    tot = sum(mix.values()); r = R.random() * tot
    for k, v in mix.items():
        r -= v
        if r <= 0: return k
    return k

def splits(w):
    if w == 7: return R.choice([[2, 2, 3], [3, 2, 2], [2, 3, 2], [3, 4], [4, 3], [7], [2, 2, 3]])
    return [w]

def frontage(s, x0, w, r0, ty, **kw):
    # a building of w blocks from column x0, its roof in row r0, its sign r0 + 1, its door r0 + 2
    t = TYPES[TY[ty]]; style = t[4]
    dx = x0 + (w - 1) // 2 if w > 2 else x0 + R.randrange(2)
    roof = R.choice(['ROOF', 'ROOF_AC', 'ROOF_TANK', 'ROOF', 'ROOF_GARDEN', 'ROOF_RED'])
    if style.startswith('shop'):
        win = {'shop': 'SHOPWIN', 'shop2': 'SHOPWIN2', 'shop3': 'SHOPWIN3'}[style]
        for x in range(x0, x0 + w):
            s.set(x, r0, roof); s.set(x, r0 + 1, t[3]); s.set(x, r0 + 2, win)
        s.set(dx, r0 + 2, 'DOOR')
    elif style == 'glass':
        for x in range(x0, x0 + w):
            s.set(x, r0, R.choice(['ROOF_BLUE', 'ROOF_AC'])); s.set(x, r0 + 1, 'GLASSWALL'); s.set(x, r0 + 2, 'GLASSWALL')
        s.set(dx, r0 + 2, 'DOOR_BIG')
    elif style == 'apt':
        for x in range(x0, x0 + w):
            s.set(x, r0, R.choice(['ROOF', 'ROOF_TANK', 'ROOF_AC'])); s.set(x, r0 + 1, 'WALL_BALC'); s.set(x, r0 + 2, 'WALL_BALC')
        s.set(dx, r0 + 2, 'DOOR_BIG')
    elif style == 'villa':
        for x in range(x0, x0 + w):
            s.set(x, r0, 'ROOF_RED'); s.set(x, r0 + 1, 'WALL_BRICK'); s.set(x, r0 + 2, 'WALL_BRICK')
        s.set(dx, r0 + 2, 'DOOR')
    elif style == 'house':
        for x in range(x0, x0 + w):
            s.set(x, r0, R.choice(['ROOF_RED', 'ROOF_GARDEN'])); s.set(x, r0 + 1, 'WALL'); s.set(x, r0 + 2, 'WALL')
        s.set(dx, r0 + 2, 'HOUSEDOOR')
    elif style == 'hanok':
        for x in range(x0, x0 + w):
            s.set(x, r0, 'HROOF'); s.set(x, r0 + 1, 'HWALL'); s.set(x, r0 + 2, 'HWALL')
        s.set(x0, r0, 'HROOF_L'); s.set(x0 + w - 1, r0, 'HROOF_R')
        s.set(dx, r0 + 2, 'HDOOR')
    s.door(dx, r0 + 2, ty, x0, w, **kw)

def half(s, x0, w, r0, mix):
    x = x0
    for part in splits(w):
        ty = pick(mix)
        style = TYPES[TY[ty]][4]
        if style in ('apt', 'glass') and part < 3: ty = 'VILLA' if style == 'apt' else 'CAFE'
        if ty == 'HOUSE' and TYPES[TY['HOUSE']][4] == 'house' and DISTRICTS[s.d][1] == 'HANOK':
            frontage_hanok_house(s, x, part, r0)
        else:
            frontage(s, x, part, r0, ty)
        x += part

def frontage_hanok_house(s, x0, w, r0):
    dx = x0 + (w - 1) // 2
    for x in range(x0, x0 + w):
        s.set(x, r0, 'HROOF'); s.set(x, r0 + 1, 'HWALL'); s.set(x, r0 + 2, 'HWALL')
    s.set(x0, r0, 'HROOF_L'); s.set(x0 + w - 1, r0, 'HROOF_R'); s.set(dx, r0 + 2, 'HDOOR')
    s.door(dx, r0 + 2, 'HOUSE', x0, w)

STREET_THINGS = ['STREET_TREE', 'STREET_TREE', 'LAMP', 'BENCH', 'BUSSTOP', 'VENDING', 'POSTBOX', 'PLANTER']
def street(s, kind):
    mix = dict(MIX.get(kind, MIX['COMM']))
    for k, v in EXTRA.get(DISTRICTS[s.d][0], {}).items(): mix[k] = mix.get(k, 0) + v
    s.rect(0, 0, 15, 11, 'PAVE')
    if kind == 'HANOK':
        s.rect(0, 3, 15, 6, 'STONE'); s.rect(0, 10, 15, 11, 'STONE')
    elif kind == 'MARKET':
        s.rect(0, 4, 15, 5, 'LANE'); s.flags |= 2
        for x in (1, 4, 10, 13):
            if R.random() < 0.85:
                s.set(x, 5, 'MARKET_AWN'); s.set(x + 1, 5, 'MARKET_AWN')
    else:
        s.rect(0, 3, 15, 3, 'PAVE_KB'); s.rect(0, 4, 15, 4, 'ROAD_T'); s.rect(0, 5, 15, 5, 'ROAD_B'); s.rect(0, 6, 15, 6, 'PAVE_KT')
        s.rect(7, 4, 8, 5, 'ZEBRA'); s.flags |= 1
    s.rect(7, 0, 8, 2, 'LANE'); s.rect(7, 7, 8, 9, 'LANE')
    half(s, 0, 7, 0, mix); half(s, 9, 7, 0, mix); half(s, 0, 7, 7, mix); half(s, 9, 7, 7, mix)
    for x in range(16):
        if x in (7, 8): continue
        if kind != 'MARKET' and R.random() < 0.18: s.set(x, 6, R.choice(STREET_THINGS))
        if R.random() < 0.25: s.set(x, 11, R.choice(STREET_THINGS))

def park(s, mount):
    s.rect(0, 0, 15, 11, 'GRASS')
    r = R
    for y in range(12):
        for x in range(16):
            v = r.random()
            if mount:
                s.set(x, y, 'PINE' if v < 0.3 else 'TREE' if v < 0.42 else 'ROCK' if v < 0.5 else 'GRASS')
            else:
                s.set(x, y, 'TREE' if v < 0.18 else 'BUSH' if v < 0.24 else 'FLOWERS' if v < 0.36 else 'GRASS')
    path = 'DIRT'
    s.rect(0, 3, 15, 3, path); s.rect(0, 10, 15, 10, path); s.rect(7, 0, 8, 11, path)
    for (x, y) in ((2, 4), (12, 4), (4, 9), (11, 9)):
        if R.random() < 0.6: s.set(x, y, 'BENCH')
    if not mount and R.random() < 0.5:
        frontage(s, 2, 2, 0, 'CONV')                 # a kiosk

def river(s):
    s.rect(0, 0, 15, 0, 'GRASS'); s.rect(0, 1, 15, 1, 'DIRT'); s.rect(0, 2, 15, 2, 'BANK_T')
    s.rect(0, 3, 15, 8, 'WATER'); s.rect(0, 9, 15, 9, 'BANK_B'); s.rect(0, 10, 15, 10, 'DIRT'); s.rect(0, 11, 15, 11, 'GRASS')
    for x in range(16):
        if x not in (7, 8) and R.random() < 0.3: s.set(x, 0, R.choice(['TREE', 'BENCH', 'BUSH']))
        if x not in (7, 8) and R.random() < 0.3: s.set(x, 11, R.choice(['TREE', 'BENCH', 'FLOWERS']))
    if s.x in BRIDGES:
        s.rect(7, 0, 7, 11, 'BRIDGE_L'); s.rect(8, 0, 8, 11, 'BRIDGE_R'); s.flags |= 4

HALLS = {'GYEONGBOKGUNG': ['GEUNJEONGJEON', 'SAJEONGJEON', 'GYEONGHOERU', 'GANGNYEONGJEON', 'GYOTAEJEON', 'JAGYEONGJEON'],
         'CHANGDEOKGUNG': ['INJEONGJEON', 'SEONJEONGJEON', 'HUIJEONGDANG', 'DAEJOJEON', 'BUYONGJI', 'NAKSEONJAE']}
def palace(s):
    dn, kind, x0, y0, w, h = DISTRICTS[s.d]
    s.rect(0, 0, 15, 11, 'STONE')
    for (x, y) in ((1, 1), (14, 1), (1, 10), (14, 10), (2, 6), (13, 6)): s.set(x, y, 'PINE')
    names = HALLS[dn]
    k = ((s.y - y0) * w + (s.x - x0)) * 2
    def hall(hx, hy, hw, nm):
        s.set(hx, hy, 'PROOF_L'); s.rect(hx + 1, hy, hx + hw - 2, hy, 'PROOF'); s.set(hx + hw - 1, hy, 'PROOF_R')
        s.rect(hx, hy + 1, hx + hw - 1, hy + 1, 'PHALL'); s.rect(hx, hy + 2, hx + hw - 1, hy + 2, 'STEPS')
        dx = hx + hw // 2
        s.set(dx, hy + 1, 'PDOOR')
        s.door(dx, hy + 1, 'PALACE', hx, 0, name=nm)
    hall(4, 1, 8, names[k % len(names)])
    hall(4, 7, 8, names[(k + 1) % len(names)])
    # the walls round the palace (gates in them where the town goes on)
    if s.y == y0: s.rect(0, 0, 15, 0, 'PWALL_TOP'); s.rect(7, 0, 8, 0, 'STONE')
    if s.x == x0: s.rect(0, 0, 0, 11, 'PWALL_TOP'); s.rect(0, 3, 0, 3, 'STONE'); s.rect(0, 10, 0, 10, 'STONE')
    if s.x == x0 + w - 1: s.rect(15, 0, 15, 11, 'PWALL_TOP'); s.rect(15, 3, 15, 3, 'STONE'); s.rect(15, 10, 15, 10, 'STONE')
    if s.y == y0 + h - 1:
        s.rect(0, 11, 15, 11, 'PWALL')
        s.set(5, 10, 'PROOF_L'); s.rect(6, 10, 9, 10, 'PROOF'); s.set(10, 10, 'PROOF_R')
        s.rect(5, 11, 6, 11, 'GATESTONE'); s.rect(9, 11, 10, 11, 'GATESTONE'); s.rect(7, 11, 8, 11, 'GATEARCH')
        s.rect(7, 10, 8, 10, 'PROOF')
        s.set(7, 10, 'GATEARCH'); s.set(8, 10, 'GATEARCH')

# ---------------------------------------------------------------- landmarks
def gate(s, r0, name):
    # a great gate across the lane: its roof in row r0, the stone and the arch under it
    s.set(4, r0, 'PROOF_L'); s.rect(5, r0, 10, r0, 'PROOF'); s.set(11, r0, 'PROOF_R')
    s.rect(4, r0 + 1, 11, r0 + 2, 'GATESTONE'); s.rect(7, r0 + 1, 8, r0 + 2, 'GATEARCH')
    for x in (0, 1, 2, 3, 12, 13, 14, 15):
        for y in (r0, r0 + 1, r0 + 2): s.set(x, y, R.choice(['PINE', 'GRASS', 'STONE']))

def clear_doors(s, x0, x1, y0, y1):
    keep = []
    for d in s.doors:
        x, y = d[0] % CW, d[0] // CW
        if x0 <= x <= x1 and y0 <= y <= y1: SHOPS[d[1]][0] = 255     # (a shop no longer there)
        else: keep.append(d)
    s.doors = keep

def big(s, x0, w, r0, wall, ty, name, floors=None, roof='ROOF_BLUE', door='DOOR_BIG'):
    clear_doors(s, x0, x0 + w - 1, r0, r0 + 2)
    for x in range(x0, x0 + w):
        s.set(x, r0, roof); s.set(x, r0 + 1, wall); s.set(x, r0 + 2, wall)
    dx = x0 + w // 2
    s.set(dx, r0 + 2, door)
    return s.door(dx, r0 + 2, ty, x0, w, name=name, floors=floors)

def tall(s, x0, w, wall, top, ty, name, floors):
    # a skyscraper: no road here - a plaza round a tower from row 0 to row 9
    clear_doors(s, 0, 15, 0, 11)
    s.rect(0, 3, 15, 6, 'STONE'); s.rect(0, 10, 15, 11, 'STONE'); s.flags &= ~1
    s.rect(9, 0, 15, 9, 'STONE')
    for (x, y) in ((14, 1), (14, 8), (9, 1)): s.set(x, y, 'STREET_TREE')
    for x in range(x0, x0 + w):
        s.set(x, 0, top)
        s.rect(x, 1, x, 9, wall)
    s.set(x0 + w // 2, 9, 'DOOR_BIG')
    s.door(x0 + w // 2, 9, ty, x0, 0, name=name, floors=floors)
    half(s, 0, 7, 0, MIX['OFFICE']); half(s, 0, 7, 7, MIX['OFFICE'])
    s.rect(7, 0, 8, 2, 'LANE'); s.rect(7, 7, 8, 9, 'LANE')

def landmark(s):
    x, y = s.x, s.y
    if (x, y) == (4, 5) or (x, y) == (5, 5):
        pass
    if (x, y) == (5, 5):                                      # N SEOUL TOWER
        clear_doors(s, 0, 15, 0, 11)
        s.rect(3, 0, 6, 9, 'GRASS')
        s.set(5, 0, 'ANTENNA'); s.set(5, 1, 'POD'); s.rect(5, 2, 5, 7, 'MAST')
        s.rect(4, 8, 6, 8, 'ROOF_BLUE'); s.rect(4, 9, 6, 9, 'GLASSWALL'); s.set(5, 9, 'DOOR_BIG')
        s.rect(3, 10, 12, 10, 'STONE'); s.rect(4, 10, 6, 10, 'STONE')
        s.door(5, 9, 'TOWER', 3, 0, name='N SEOUL TOWER', floors=2)
    if (x, y) == (3, 5):                                      # SEOUL STATION
        clear_doors(s, 0, 6, 0, 2)
        s.rect(0, 0, 6, 0, 'ROOF_GARDEN'); s.set(2, 0, 'DOME_L'); s.set(3, 0, 'DOME_R')
        s.rect(0, 1, 6, 2, 'OLDBRICK'); s.set(3, 2, 'DOOR_BIG')
        s.door(3, 2, 'SUBWAY', 0, 0, name='SEOUL STATION')
        STATION_SHOPS[(x, y)] = s.doors[-1][1]
    if (x, y) == (5, 4):                                      # CITY HALL, the library, Seoul Plaza
        big(s, 0, 7, 0, 'GLASSWALL', 'OFFICE', 'CITY HALL', floors=9)
        big(s, 9, 7, 0, 'OLDBRICK', 'BOOKSHOP', 'SEOUL LIBRARY', roof='ROOF')
        clear_doors(s, 0, 15, 7, 9)
        s.rect(0, 7, 15, 9, 'GRASS'); s.rect(7, 7, 8, 9, 'LANE')
        for xx in (1, 4, 11, 14): s.set(xx, 7, 'STREET_TREE')
    if (x, y) == (6, 4):                                      # the Central Post Office
        global POST_SHOP
        POST_SHOP = big(s, 0, 7, 0, 'GLASSWALL', 'POST', 'CENTRAL POST OFFICE', roof='ROOF_RED')
        s.set(2, 6, 'POSTBOX'); s.set(5, 6, 'POSTBOX')
    if (x, y) in ((5, 2), (6, 2)):                            # Gwanghwamun Square: King Sejong, Admiral Yi
        s.rect(0, 3, 15, 6, 'STONE'); s.flags &= ~1
        s.set(4, 4, 'STATUE_T'); s.set(4, 5, 'STATUE_B')
        s.set(11, 4, 'FOUNTAIN'); s.set(12, 4, 'FOUNTAIN')
        for xx in (1, 14): s.set(xx, 6, 'PLANTER')
    if (x, y) == (4, 4):                                      # Sungnyemun (Namdaemun)
        clear_doors(s, 0, 15, 7, 9); gate(s, 7, 'SUNGNYEMUN')
    if (x, y) == (12, 2):                                     # Heunginjimun (Dongdaemun)
        clear_doors(s, 0, 15, 7, 9); gate(s, 7, 'HEUNGINJIMUN')
    if (x, y) == (13, 3):                                     # DDP
        clear_doors(s, 0, 15, 7, 9)
        big(s, 0, 7, 7, 'SILVERWALL', 'DEPT', 'DDP', floors=4, roof='ROOF')
        big(s, 9, 7, 7, 'SILVERWALL', 'MUSEUM', 'DDP DESIGN HALL', roof='ROOF')
    if (x, y) == (2, 8):                                      # 63 BUILDING
        tall(s, 10, 3, 'GOLDWALL', 'ROOF_BLUE', 'TOWER', '63 BUILDING', 2)
    if (x, y) == (14, 9):                                     # the tower in Jamsil
        tall(s, 10, 3, 'GLASSWALL', 'SPIRE', 'TOWER', 'JAMSIL SKY TOWER', 2)
    if (x, y) == (0, 8):                                      # the National Assembly
        clear_doors(s, 0, 15, 7, 9)
        big(s, 1, 6, 7, 'WALL', 'MUSEUM', 'NATIONAL ASSEMBLY', roof='ROOF')
        s.set(3, 7, 'DOME_L'); s.set(4, 7, 'DOME_R')
    if (x, y) == (2, 6):                                      # the National Museum
        clear_doors(s, 0, 15, 7, 9)
        big(s, 0, 7, 7, 'OLDBRICK', 'MUSEUM', 'NATIONAL MUSEUM', roof='ROOF')
    if (x, y) == (12, 10):                                    # COEX
        clear_doors(s, 0, 15, 0, 2)
        big(s, 0, 7, 0, 'GLASSWALL', 'DEPT', 'COEX MALL', floors=3)
        big(s, 9, 7, 0, 'GLASSWALL', 'HOTEL', 'COEX HOTEL')
    if (x, y) == (13, 11):                                    # Bongeunsa
        clear_doors(s, 0, 15, 7, 9)
        s.rect(0, 7, 15, 9, 'STONE'); s.rect(0, 7, 2, 9, 'PINE'); s.rect(13, 7, 15, 9, 'PINE')
        s.set(3, 7, 'PROOF_L'); s.rect(4, 7, 11, 7, 'PROOF'); s.set(12, 7, 'PROOF_R'); s.rect(3, 8, 12, 9, 'PHALL')
        s.set(7, 9, 'PDOOR'); s.door(7, 9, 'TEMPLE', 3, 0, name='BONGEUNSA')
        s.rect(7, 7, 7, 8, 'PROOF'); s.set(8, 9, 'PHALL')
    if (x, y) == (1, 1):                                      # a temple on the mountain
        s.set(9, 7, 'PROOF_L'); s.rect(10, 7, 13, 7, 'PROOF'); s.set(14, 7, 'PROOF_R'); s.rect(9, 8, 14, 8, 'PHALL'); s.rect(9, 9, 14, 9, 'STEPS')
        s.set(11, 8, 'PDOOR'); s.door(11, 8, 'TEMPLE', 9, 0, name='DOSEONSA')
    if (x, y) == (6, 10):                                     # the Express Bus Terminal
        big(s, 9, 7, 0, 'GLASSWALL', 'DEPT', 'BUS TERMINAL', floors=3)
    if (x, y) == (14, 11):                                    # Olympic Park's gate
        s.set(5, 7, 'PROOF_L'); s.rect(6, 7, 9, 7, 'PROOF'); s.set(10, 7, 'PROOF_R'); s.rect(5, 8, 6, 9, 'GATESTONE'); s.rect(9, 8, 10, 9, 'GATESTONE')
        s.rect(7, 8, 8, 9, 'GATEARCH')
    if (x, y) == (1, 9):                                      # Yeouido Park: fountain
        s.set(4, 5, 'FOUNTAIN'); s.set(11, 5, 'FOUNTAIN')

STATION_SHOPS = {}
POST_SHOP = None
def subway(s, name):
    if (s.x, s.y) in STATION_SHOPS: return
    # the way down: a sign and stairs in row 11, columns 4-5 (or 10-11)
    col = 4 if s.c[11][4] not in ('BRIDGE_L',) else 10
    for cx in (col, col + 1, col + 2):
        if s.c[11][cx] in ('WATER',): col = 10
    s.set(col, 11, 'SUBWAY_SIGN'); s.set(col + 1, 11, 'SUBWAY_STAIRS')
    s.set(col, 10, 'PAVE' if s.c[10][col] in BAD else s.c[10][col]); s.set(col + 1, 10, 'PAVE' if s.c[10][col + 1] in BAD else s.c[10][col + 1])
    STATION_SHOPS[(s.x, s.y)] = s.door(col + 1, 11, 'SUBWAY', col, 0, name=name)
BAD = {'TREE', 'PINE', 'ROCK', 'BUSH', 'STREET_TREE', 'LAMP', 'BENCH', 'BUSSTOP', 'VENDING', 'POSTBOX', 'PLANTER', 'WATER'}

def make_screen(x, y):
    s = Screen(x, y)
    kind = DISTRICTS[s.d][1]
    if kind in ('COMM', 'APTS', 'OFFICE', 'HANOK', 'MARKET'): street(s, kind)
    elif kind == 'PARK': park(s, False)
    elif kind == 'MOUNT': park(s, True)
    elif kind == 'RIVER': river(s)
    elif kind == 'PALACE': palace(s)
    landmark(s)
    for (sx, sy, nm, ln) in STATIONS:
        if (sx, sy) == (x, y): subway(s, nm)
    return s

SCREENS = [make_screen(x, y) for y in range(H) for x in range(W)]
assert POST_SHOP is not None

# ---------------------------------------------------------------- the insides
TMETA = []
def template_room(name):
    fl, rows = TEMPLATES[name]
    assert len(rows) == 12, name
    cells = []; meta = {'keeper': 255, 'spot': 255, 'spots': [], 'lift': 255, 'units': [], 'mail': 255, 'exit': 255}
    for y, row in enumerate(rows):
        assert len(row) == 16, (name, y, row)
        for x, ch in enumerate(row):
            c = y * 16 + x
            if ch in '.@*+':
                cells.append(BI[FLOORS[fl]])
                if ch == '@' and meta['keeper'] == 255: meta['keeper'] = c
                if ch == '*': meta['spot'] = c
                if ch == '+': meta['spots'].append(c)
            else:
                cells.append(BI[KEY[ch]])
                if ch in 'LS': meta['lift'] = c
                if ch == 'A': meta['units'].append(c)
                if ch == 'X' and meta['mail'] == 255: meta['mail'] = c
                if ch == 'E' and meta['exit'] == 255: meta['exit'] = c
    # the people's paths: up the aisle (column 7) from the door, then across
    def walk(x, y): return not (BL.ATTR[cells[y * 16 + x]] & BL.SOLID)
    for c in meta['spots'] + ([meta['spot']] if meta['spot'] != 255 else []):
        x, y = c % 16, c // 16
        for yy in range(y, 11): assert walk(7, yy), (name, 'aisle', x, y, yy)
        for xx in range(min(x, 7), max(x, 7) + 1): assert walk(xx, y), (name, 'row', x, y, xx)
    assert len(meta['spots']) <= 4, name
    return cells, meta

TROOMS = [template_room(n) for n in TPLNAMES]

# ---------------------------------------------------------------- homes: the hundred people's addresses
def units_on(shop, f):
    t = TYPES[SHOPS[shop][0]][0]
    if t == 'APT': return 4 if f >= 2 else 0
    if t == 'VILLA': return 2 if f == 1 else 4
    return 1
homes = []
used = set()
live = [k for k, sh in enumerate(SHOPS) if sh[0] != 255 and TYPES[sh[0]][0] in ('APT', 'VILLA', 'HOUSE')]
R.shuffle(live)
# spread them: one each in as many districts as possible first
bydist = {}
for k in live: bydist.setdefault(SHOPS[k][4], []).append(k)
order = []
while len(order) < 100:
    for d in sorted(bydist):
        if bydist[d]: order.append(bydist[d].pop())
        if len(order) == 100: break
for k in order:
    sh = SHOPS[k]; t = TYPES[sh[0]][0]
    if t == 'HOUSE': f, u = 1, 1
    else:
        f = R.randint(2 if t == 'APT' else 1, sh[1]); u = R.randint(1, units_on(k, f))
    homes.append((k, f, u))


# ---------------------------------------------------------------- the hundred's days: where each one is
# A person's record (128 bytes): 3 kinds of day (the game takes (person + day) mod 3), each 19
# half hours from 9:00 to 18:00: the shop they're in (their home: at home), 65535 out of town.
RS = random.Random(77)   # its own, so the rest of the city doesn't change
PEOPLE = json.load(open(os.path.join(HERE, 'people.json')))['people']
WORK = {'OFFICE': ['ACCOUNTANT', 'ARCHITECT', 'LAWYER', 'STOCK TRADER', 'PROGRAMMER', 'GAME DEVELOPER',
                   'DESIGNER', 'RADIO HOST', 'JOURNALIST', 'SALES MANAGER', 'EVENT PLANNER', 'WEBTOON ARTIST'],
        'BANK': ['BANKER'], 'SALON': ['HAIRSTYLIST', 'TATTOO ARTIST'], 'BOOKSHOP': ['BOOKSHOP OWNER', 'LIBRARIAN'],
        'CLINIC': ['DOCTOR', 'DENTIST', 'PHYSIO', 'NURSE', 'VET'], 'FLORIST': ['FLORIST'], 'BAKERY': ['BAKER'],
        'CAFE': ['BARISTA'], 'CLUB': ['BARTENDER', 'DJ'], 'BBQ': ['CHEF', 'SOMMELIER'],
        'GYM': ['PERSONAL TRAINER', 'YOGA TEACHER'], 'DEPT': ['FASHION BUYER'], 'BOUTIQUE': ['MODEL'],
        'THEATRE': ['ACTOR', 'SINGER', 'DANCER', 'MUSICIAN'], 'ELECTRO': ['MECHANIC'], 'POLICE': ['FIREFIGHTER'],
        'MUSEUM': ['TEACHER', 'ZOOKEEPER'], 'CRAFT': ['POTTER'], 'POST': ['COURIER']}
JOBPLACE = {j: t for t, js in WORK.items() for j in js}
AWAY = {'FLIGHT ATTENDANT', 'PILOT', 'MARINE BIOLOGIST', 'SURFER', 'LIFEGUARD'}   # some days out of town
HAUNT = {'OFFICE': ['OFFICE'], 'CAFE': ['CAFE', 'TEAHOUSE', 'BAKERY'], 'MALL': ['DEPT', 'COSMETICS', 'PHONE', 'ELECTRO'],
         'BOUTIQUE': ['BOUTIQUE', 'HANBOK', 'SALON'], 'GYM': ['GYM'], 'PARK': ['PALACE', 'TEMPLE', 'MUSEUM'],
         'BEACH': ['FISH', 'TEAHOUSE'], 'CINEMA': ['THEATRE'], 'RESTAURANT': ['BBQ', 'NOODLE', 'CHICKEN'],
         'BAR': ['CHICKEN', 'CLUB'], 'CLUB': ['CLUB'], 'KARAOKE': ['NORAE'], 'CONCERT HALL': ['THEATRE'],
         'FUNFAIR': ['PCBANG', 'TOWER'], 'CHAPEL': ['TEMPLE'], 'HOME': []}
def rxy(k): r = SHOPS[k][5]; return r % W, r // W
def near(home, types, pick=1):
    # the shops of these types nearest home (one of the nearest few)
    hx, hy = rxy(home)
    c = [k for k, s in enumerate(SHOPS) if s[0] != 255 and TYPES[s[0]][0] in types and TYPES[s[0]][5]]
    c.sort(key=lambda k: abs(rxy(k)[0] - hx) + abs(rxy(k)[1] - hy) + RS.random() * 0.5)
    return c[RS.randrange(min(pick, len(c)))] if c else None
def le16(v): return bytes([v & 255, v >> 8])
sched = bytearray()
athome = 0
for p, per in enumerate(PEOPLE):
    home = homes[p][0]
    job = JOBPLACE.get(per['job'])
    work = near(home, [job]) if job else None
    hs = [h for h in (near(home, HAUNT[x], 3) for x in per['haunts']) if h is not None]
    food = [h for h in (near(home, ['BBQ', 'NOODLE', 'CHICKEN', 'CAFE', 'BAKERY'], 4) for _ in range(2))]
    rec = bytearray()
    for kind in range(3):
        d = [home] * 19
        if work is not None and (kind == 0 or (kind == 1 and p % 2)):
            a = RS.choice([0, 0, 1, 2]); b = min(19, a + RS.randint(10, 16))
            for t in range(a, b): d[t] = work
            if b - a > 10:
                l = a + RS.randint(5, 7)
                d[l] = d[l + 1] = RS.choice(food)
            if b < 17 and hs and RS.random() < 0.6:
                h = RS.choice(hs)
                for t in range(b, min(19, b + RS.randint(2, 4))): d[t] = h
        elif per['job'] in AWAY and kind == 1:
            d = [65535] * 19
        else:
            for _ in range(RS.randint(1, 2)):
                if not hs: break
                h = RS.choice(hs); a = RS.randrange(19); n = RS.randint(2, 5)
                for t in range(a, min(19, a + n)): d[t] = h
        athome += d.count(home)
        for v in d: rec += le16(v)
    sched += rec + bytes(128 - len(rec))
print('the hundred: at home %d%% of the day' % (athome * 100 // (100 * 3 * 19)))

# ---------------------------------------------------------------- the data
def le16(v): return bytes([v & 255, v >> 8])
def text(s, n): s = s[:n]; return (s + ' ' * (n - len(s))).encode('latin-1')
out = os.path.join(HERE, 'world'); os.makedirs(out, exist_ok=True)
rooms = bytearray()
for s in SCREENS:
    rec = bytearray(256)
    for y in range(CH):
        for x in range(CW): rec[y * CW + x] = BI[s.c[y][x]]
    rec[192] = 0; rec[193] = s.d; rec[194] = s.flags
    assert len(s.doors) <= 15, (s.x, s.y, len(s.doors))
    rec[195] = len(s.doors)
    for k, (cell, sh, sx, sw) in enumerate(s.doors):
        rec[196 + k * 4:200 + k * 4] = bytes([cell, sh & 255, sh >> 8, (sx & 15) | (min(sw, 7) << 4)])
    rooms += rec
for (cells, meta), name in zip(TROOMS, TPLNAMES):
    rec = bytearray(256)
    rec[0:192] = bytes(cells); rec[192] = 1; rec[193] = 0; rec[194] = 0; rec[195] = 0
    sp = meta['spots'] + [255] * (4 - len(meta['spots'])); un = meta['units'] + [255] * (4 - len(meta['units']))
    rec[196:210] = bytes([meta['keeper'], meta['spot']] + sp + [meta['lift']] + un + [meta['mail'], meta['exit'], len(meta['units'])])
    rooms += rec
shops = bytearray()
for sh in SHOPS: shops += bytes(sh)
types = bytearray()
for t in TYPES:
    rec = bytearray(64)
    tp = [TP[n] for n in t[5]] + [255] * (3 - len(t[5]))
    if len(t[5]) == 2: tp[2] = tp[1]
    rec[0:3] = bytes(tp); rec[3], rec[4] = t[6]; rec[5] = t[8]
    rec[8:14] = text(t[2], 6); rec[16:32] = text(t[1], 16); rec[32:42] = text(t[7], 10)
    types += rec
hb = bytearray()
for (k, f, u) in homes: hb += le16(k) + bytes([f, u])
st = bytearray()
for (sx, sy, nm, ln) in STATIONS:
    k = STATION_SHOPS[(sx, sy)]
    rec = bytearray(32); rec[0:2] = le16(k); rec[2] = sx; rec[3] = sy; rec[4:10] = text(ln, 6); rec[16:32] = text(nm, 16)
    st += rec
dist = bytearray()
for (n, kind, x0, y0, w, h) in DISTRICTS:
    rec = bytearray(32); rec[0:16] = text(n, 16)
    rec[16] = ['COMM', 'APTS', 'OFFICE', 'HANOK', 'MARKET', 'PARK', 'MOUNT', 'RIVER', 'PALACE'].index(kind)
    rec[17:21] = bytes([x0, y0, w, h]); dist += rec
words = b''.join(text(w, 8) for w in WORDS)
names = b''.join(text(n, 20) for n in NAMES)
bridges = b''.join(text(BRIDGES.get(x, ''), 16) for x in range(16))
attr = bytes(BL.ATTR)
from collections import Counter
mini = bytes([Counter(v for row in b.p for v in row).most_common(1)[0][0] for n, a, b in BL.BLOCKS] + [0] * (256 - len(BL.BLOCKS)))
TABLES = [('ROOMS', rooms, 256), ('SHOPS', shops, 8), ('TYPES', types, 64), ('HOMES', hb, 4), ('STATIONS', st, 32),
          ('DISTRICTS', dist, 32), ('WORDS', words, 8), ('NAMES', names, 20), ('BRIDGES', bridges, 16), ('ATTR', attr, 1), ('MINI', mini, 1), ('SCHED', sched, 128)]
man = []
for name, data, size in TABLES:
    open(os.path.join(out, name.lower() + '.bin'), 'wb').write(data)
    man.append({'name': name, 'file': 'world/' + name.lower() + '.bin', 'size': size, 'n': len(data) // size})
man.append({'name': 'BLOCKS', 'file': 'blocks.bin', 'size': 256, 'n': len(BL.BLOCKS)})
json.dump(man, open(os.path.join(out, 'manifest.json'), 'w'), indent=1)

# ---------------------------------------------------------------- Town.cls: the numbers
L = []; A = L.append
A("' Town - LITTLE SEOUL's numbers for its city (made by tools/city.py: don't edit). The city itself is")
A("' in the Next's other RAM: Data.W_* are its tables' pages (see tools/city.py).")
A("' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License")
A('Option Explicit')
A('')
A("' the screens: W x H of them, the room numbers of the insides (templates) after them")
A('Public Const W = %d, H = %d, NSCREEN = %d, NSHOP = %d, NTYPE = %d, NSTATION = %d, NDISTRICT = %d' % (W, H, W * H, len(SHOPS), len(TYPES), len(STATIONS), len(DISTRICTS)))
A('Public Const POSTSHOP = %d, POSTROOM = %d, POSTDOOR = %d' % (POST_SHOP, SHOPS[POST_SHOP][5], SHOPS[POST_SHOP][6]))
A("' block attributes")
A('Public Const A_SOLID = 1, A_DOOR = 2, A_WATER = 4, A_ROAD = 8, A_COUNTER = 16, A_LIFT = 32, A_STAIRS = 64, A_THING = 128')
A("' a few blocks by name")
for n in ('MARKET_AWN', 'POSTBOX', 'VENDING', 'MAILBOXES', 'APTDOOR', 'BINOCS', 'EXHIBIT', 'LIFT', 'STAIRS_UP', 'HOUSEDOOR', 'HDOOR', 'SUBWAY_STAIRS', 'ZEBRA', 'TICKETS'):
    A('Public Const B_%s = %d' % (n, BI[n]))
A("' the shop types")
for k in range(0, len(TYPES), 8):
    A('Public Const ' + ', '.join('TY_%s = %d' % (t[0], k + j) for j, t in enumerate(TYPES[k:k + 8])))
A("' the insides")
for k in range(0, len(TPLNAMES), 6):
    A('Public Const ' + ', '.join('TP_%s = %d' % (n, k + j) for j, n in enumerate(TPLNAMES[k:k + 6])))
A("' the district kinds")
A('Public Const DK_COMM = 0, DK_APTS = 1, DK_OFFICE = 2, DK_HANOK = 3, DK_MARKET = 4, DK_PARK = 5, DK_MOUNT = 6, DK_RIVER = 7, DK_PALACE = 8')
A("' a room's record (256 bytes): 0-191 its blocks, 192 inside?, 193 district, 194 flags (1 cars, 2 market")
A("' stalls, 4 a bridge), 195 doors; 196 + 4 each: the door's block, its shop (2 bytes), sign x + 16 * width.")
A("' An inside's: 196 the keeper's block, 197 the counter spot, 198-201 people's spots, 202 the lift,")
A("' 203-206 the flats' doors, 207 the mailboxes, 208 the way out, 209 how many flats")
A("' a shop (8 bytes): type, floors, name (a word, or 128 + a name), number, district, room, door, -")
A("' a type (64 bytes): 0-2 the insides (ground, upper, top), 3-4 floors, 5 keeper sprite, 8 sign (6),")
A("' 16 name (16), 32 keeper title (10)")
open(os.path.join(ROOT, 'Town.cls'), 'w').write('\r\n'.join(L) + '\r\n')

# ---------------------------------------------------------------- a map of it all
from PIL import Image
img = Image.new('RGB', (W * CW * 4, H * CH * 4))
for s in SCREENS:
    for y in range(CH):
        for x in range(CW):
            b = BL.BLOCKS[BI[s.c[y][x]]][2]
            for py in range(4):
                for px in range(4):
                    img.putpixel((s.x * 64 + x * 4 + px, s.y * 48 + y * 4 + py), BL.rgb(b.p[py * 4 + 1][px * 4 + 1]))
img.save(os.path.join(HERE, 'map_preview.png'))
live_shops = sum(1 for sh in SHOPS if sh[0] != 255)
print('%d screens, %d doors (%d shops), %d insides, %d names, rooms %d bytes' % (len(SCREENS), len(SHOPS), live_shops, len(TPLNAMES), len(NAMES), len(rooms)))
