' Town - LITTLE SEOUL's numbers for its city (made by tools/city.py: don't edit). The city itself is
' in the Next's other RAM: Data.W_* are its tables' pages (see tools/city.py).
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit

' the screens: W x H of them, the room numbers of the insides (templates) after them
Public Const W = 16, H = 12, NSCREEN = 192, NSHOP = 1523, NTYPE = 40, NSTATION = 30, NDISTRICT = 54
Public Const POSTSHOP = 587, POSTROOM = 70, POSTDOOR = 35
' block attributes
Public Const A_SOLID = 1, A_DOOR = 2, A_WATER = 4, A_ROAD = 8, A_COUNTER = 16, A_LIFT = 32, A_STAIRS = 64, A_THING = 128
' a few blocks by name
Public Const B_MARKET_AWN = 37
Public Const B_POSTBOX = 25
Public Const B_VENDING = 24
Public Const B_MAILBOXES = 113
Public Const B_APTDOOR = 112
Public Const B_BINOCS = 145
Public Const B_EXHIBIT = 154
Public Const B_LIFT = 109
Public Const B_STAIRS_UP = 111
Public Const B_HOUSEDOOR = 80
Public Const B_HDOOR = 77
Public Const B_SUBWAY_STAIRS = 30
Public Const B_ZEBRA = 7
Public Const B_TICKETS = 140
' the shop types
Public Const TY_CAFE = 0, TY_CONV = 1, TY_CHICKEN = 2, TY_BBQ = 3, TY_NOODLE = 4, TY_BAKERY = 5, TY_PHARMACY = 6, TY_COSMETICS = 7
Public Const TY_PCBANG = 8, TY_NORAE = 9, TY_SALON = 10, TY_BOUTIQUE = 11, TY_PHONE = 12, TY_BANK = 13, TY_BOOKSHOP = 14, TY_TEAHOUSE = 15
Public Const TY_CRAFT = 16, TY_HANBOK = 17, TY_GYM = 18, TY_FLORIST = 19, TY_FISH = 20, TY_POST = 21, TY_POLICE = 22, TY_CLINIC = 23
Public Const TY_ELECTRO = 24, TY_THEATRE = 25, TY_CLUB = 26, TY_MUSEUM = 27, TY_HOTEL = 28, TY_APT = 29, TY_VILLA = 30, TY_HOUSE = 31
Public Const TY_OFFICE = 32, TY_DEPT = 33, TY_TOWER = 34, TY_PALACE = 35, TY_TEMPLE = 36, TY_SUBWAY = 37, TY_GUEST = 38, TY_MARKET = 39
' the insides
Public Const TP_CAFE = 0, TP_CONV = 1, TP_CHICKEN = 2, TP_BBQ = 3, TP_NOODLE = 4, TP_BAKERY = 5
Public Const TP_PHARMACY = 6, TP_COSMETICS = 7, TP_PCBANG = 8, TP_NORAE = 9, TP_SALON = 10, TP_BOUTIQUE = 11
Public Const TP_PHONE = 12, TP_BANK = 13, TP_BOOKSHOP = 14, TP_TEAHOUSE = 15, TP_CRAFT = 16, TP_HANBOK = 17
Public Const TP_GYM = 18, TP_FLORIST = 19, TP_FISH = 20, TP_POST = 21, TP_POLICE = 22, TP_HOSPITAL = 23
Public Const TP_ELECTRO = 24, TP_THEATRE = 25, TP_CLUB = 26, TP_MUSEUM = 27, TP_HOTEL = 28, TP_APT_LOBBY = 29
Public Const TP_APT_FLOOR = 30, TP_VILLA_G = 31, TP_VILLA_UP = 32, TP_OFFICE_LOBBY = 33, TP_OFFICE_FLOOR = 34, TP_DEPT_G = 35
Public Const TP_DEPT_UP = 36, TP_DEPT_FOOD = 37, TP_TOWER_LOBBY = 38, TP_OBSERVATORY = 39, TP_PALACE = 40, TP_TEMPLE = 41
Public Const TP_SUBWAY = 42
' the district kinds
Public Const DK_COMM = 0, DK_APTS = 1, DK_OFFICE = 2, DK_HANOK = 3, DK_MARKET = 4, DK_PARK = 5, DK_MOUNT = 6, DK_RIVER = 7, DK_PALACE = 8
' a room's record (256 bytes): 0-191 its blocks, 192 inside?, 193 district, 194 flags (1 cars, 2 market
' stalls, 4 a bridge), 195 doors; 196 + 4 each: the door's block, its shop (2 bytes), sign x + 16 * width.
' An inside's: 196 the keeper's block, 197 the counter spot, 198-201 people's spots, 202 the lift,
' 203-206 the flats' doors, 207 the mailboxes, 208 the way out, 209 how many flats
' a shop (8 bytes): type, floors, name (a word, or 128 + a name), number, district, room, door, -
' a type (64 bytes): 0-2 the insides (ground, upper, top), 3-4 floors, 5 keeper sprite, 8 sign (6),
' 16 name (16), 32 keeper title (10)
