' (taskify.py: task lines in IFNDEF NTC_ZXN)
' Data - LITTLE SEOUL's story, people and pictures, in the Next's other RAM (made by tools/storyc.py:
' don't edit). The data itself is build/LSENGINE.DAT, put in banks 0, 1, 2, 3, 4, 6, 7, 11, 12, 13, 14, 15, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34 by Init's assembler
' (INCBIN: keep the .DAT file next to the .asm), and game.json's "banks" puts them in the NEX file.
' Everything is read through MMU slots 6 and 7 (#C000-#FFFF, two pages at a time), then bank 5
' (the tilemap) put back.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit

Public Const NSCENE = 210, FACEPAGE = 12, GAMEPAGE = 23
' the city's tables (tools/city.py): each from the start of its page
Public Const W_ROOMS = 38     ' 256 bytes each, 235
Public Const W_SHOPS = 46     ' 8 bytes each, 1523
Public Const W_TYPES = 48     ' 64 bytes each, 40
Public Const W_HOMES = 49     ' 4 bytes each, 100
Public Const W_STATIONS = 50     ' 32 bytes each, 30
Public Const W_DISTRICTS = 51     ' 32 bytes each, 54
Public Const W_WORDS = 52     ' 8 bytes each, 64
Public Const W_NAMES = 53     ' 20 bytes each, 56
Public Const W_BRIDGES = 54     ' 16 bytes each, 16
Public Const W_ATTR = 55     ' 1 bytes each, 256
Public Const W_MINI = 56     ' 1 bytes each, 256
Public Const W_SCHED = 57     ' 128 bytes each, 100
Public Const W_BLOCKS = 59     ' 256 bytes each, 158
' the scenes' pictures: a byte each at DIRPAGE's NSCENE * 5 + scene (255: none named)
Public Const DIRPAGE = 6, PPAGE = 7, POFF = 0, PREC = 32
Public Const T_FULL = 3200, T_JOB = 4600, T_HOBBY = 5400, T_CITY = 6136, T_TRAIT = 6412
' POST
Public Const PO_BASE = 0
Public Const PO_INTRO = 0, PO_INTRO2 = 1, PO_MORN01 = 2, PO_MORN02 = 3, PO_MORN03 = 4, PO_MORN04 = 5
Public Const PO_MORN05 = 6, PO_MORN06 = 7, PO_MORN07 = 8, PO_MORN08 = 9, PO_MORN09 = 10, PO_MORN10 = 11
Public Const PO_MORN11 = 12, PO_MORN12 = 13, PO_MORN13 = 14, PO_MORN14 = 15, PO_MORN15 = 16, PO_MORN16 = 17
Public Const PO_MORN17 = 18, PO_MORN18 = 19, PO_MORN19 = 20, PO_MORN20 = 21, PO_PRAISE = 22, PO_FINE = 23
Public Const PO_SCOLD = 24, PO_WARN = 25, PO_SACKED = 26, PO_PAYDAY = 27, PO_LASTDAY = 28, PO_E_TOP = 29
Public Const PO_E_GOOD = 30, PO_E_OK = 31, PO_E_SACKED = 32, PO_LOVE = 33, PO_LOVE2 = 34, PO_NOLOVE = 35
' DELIVER
Public Const DE_BASE = 36
Public Const DE_DLV01 = 36, DE_DLV02 = 37, DE_DLV03 = 38, DE_DLV04 = 39, DE_DLV05 = 40, DE_DLV06 = 41
Public Const DE_DLV07 = 42, DE_DLV08 = 43, DE_DLV09 = 44, DE_DLV10 = 45, DE_DLV11 = 46, DE_DLV12 = 47
Public Const DE_DLV13 = 48, DE_DLV14 = 49, DE_DLV15 = 50, DE_DLV16 = 51, DE_HAND01 = 52, DE_HAND02 = 53
Public Const DE_HAND03 = 54, DE_HAND04 = 55, DE_HAND05 = 56, DE_HAND06 = 57, DE_FRIEND01 = 58, DE_FRIEND02 = 59
Public Const DE_FRIEND03 = 60, DE_FRIEND04 = 61, DE_FRIEND05 = 62, DE_FRIEND06 = 63, DE_WRONG01 = 64, DE_WRONG02 = 65
Public Const DE_WRONG03 = 66, DE_WRONG04 = 67, DE_WRONG05 = 68, DE_WRONG06 = 69, DE_WRONG07 = 70, DE_WRONG08 = 71
Public Const DE_AWAY01 = 72, DE_AWAY02 = 73, DE_AWAY03 = 74, DE_AWAY04 = 75, DE_BIZ01 = 76, DE_BIZ02 = 77
Public Const DE_BIZ03 = 78, DE_BIZ04 = 79, DE_BIZ05 = 80, DE_BIZ06 = 81, DE_BIZ07 = 82, DE_BIZ08 = 83
Public Const DE_MAILBOX = 84, DE_GIFT = 85, DE_KNOCKED = 86, DE_NOTMINE = 87
' CHAT
Public Const CH_BASE = 88
Public Const CH_CHAT01 = 88, CH_CHAT02 = 89, CH_CHAT03 = 90, CH_CHAT04 = 91, CH_CHAT05 = 92, CH_CHAT06 = 93
Public Const CH_CHAT07 = 94, CH_CHAT08 = 95, CH_CHAT09 = 96, CH_CHAT10 = 97, CH_CHAT11 = 98, CH_CHAT12 = 99
Public Const CH_CHAT13 = 100, CH_CHAT14 = 101, CH_CHAT15 = 102, CH_CHAT16 = 103, CH_CHAT17 = 104, CH_CHAT18 = 105
Public Const CH_CHAT19 = 106, CH_CHAT20 = 107, CH_CHAT21 = 108, CH_CHAT22 = 109, CH_CHAT23 = 110, CH_CHAT24 = 111
Public Const CH_CHAT25 = 112, CH_CHAT26 = 113, CH_CHAT27 = 114, CH_CHAT28 = 115, CH_CHAT29 = 116, CH_CHAT30 = 117
' SHOPS
Public Const SH_BASE = 118
Public Const SH_CAFE = 118, SH_CONV = 119, SH_CHICKEN = 120, SH_BBQ = 121, SH_NOODLE = 122, SH_BAKERY = 123
Public Const SH_PHARMACY = 124, SH_COSMETICS = 125, SH_PCBANG = 126, SH_NORAE = 127, SH_SALON = 128, SH_BOUTIQUE = 129
Public Const SH_PHONE = 130, SH_BANK = 131, SH_BOOKSHOP = 132, SH_TEAHOUSE = 133, SH_CRAFT = 134, SH_HANBOK = 135
Public Const SH_GYM = 136, SH_FLORIST = 137, SH_FISH = 138, SH_POST = 139, SH_POLICE = 140, SH_CLINIC = 141
Public Const SH_ELECTRO = 142, SH_THEATRE = 143, SH_CLUB = 144, SH_MUSEUM = 145, SH_HOTEL = 146, SH_APT = 147
Public Const SH_VILLA = 148, SH_HOUSE = 149, SH_OFFICE = 150, SH_DEPT = 151, SH_TOWER = 152, SH_PALACE = 153
Public Const SH_TEMPLE = 154, SH_SUBWAY = 155, SH_GUEST = 156, SH_MARKET = 157, SH_VIEW = 158, SH_STALL = 159
Public Const SH_LOBBY = 160
' STRANGERS
Public Const ST_BASE = 161
Public Const ST_STR01 = 161, ST_STR02 = 162, ST_STR03 = 163, ST_STR04 = 164, ST_STR05 = 165, ST_STR06 = 166
Public Const ST_STR07 = 167, ST_STR08 = 168, ST_STR09 = 169, ST_STR10 = 170, ST_STR11 = 171, ST_STR12 = 172
Public Const ST_STR13 = 173, ST_STR14 = 174, ST_STR15 = 175, ST_STR16 = 176, ST_STR17 = 177, ST_STR18 = 178
Public Const ST_STR19 = 179, ST_STR20 = 180, ST_STR21 = 181, ST_STR22 = 182, ST_STR23 = 183, ST_STR24 = 184
Public Const ST_STR25 = 185, ST_STR26 = 186, ST_STR27 = 187, ST_STR28 = 188, ST_STR29 = 189, ST_STR30 = 190
Public Const ST_HINT01 = 191, ST_HINT02 = 192, ST_HINT03 = 193, ST_HINT04 = 194
' THINGS
Public Const TH_BASE = 195
Public Const TH_VENDING = 195, TH_POSTBOX = 196, TH_BINOCS = 197, TH_EXHIBIT = 198, TH_HIT = 199, TH_TIRED = 200
Public Const TH_HUNGRY = 201, TH_NOMONEY = 202, TH_LIFT = 203, TH_STAIRS = 204, TH_TRAIN = 205, TH_BRIDGE = 206
Public Const TH_RIVER = 207, TH_CLOSED = 208, TH_NIGHT = 209
Public Const OP_END = 0, OP_SAY = 1, OP_NARR = 2, OP_MOOD = 3, OP_CHOICE = 4, OP_AFF = 5, OP_ICON = 6, OP_GOTO = 7, OP_FLAG = 8, OP_MONEY = 9, OP_WHO = 10, OP_STAT = 11

Private cs As Integer, cn As Integer, xs As Integer, xd As Integer, xt As Integer, pp As Integer, po As Integer, py As Integer, pl As Integer

' Init: (puts the data in the banks, when the NEX file is made)
Public Sub Init()
#asm
            jp di_end
di_end:
    IFDEF NTC_ZXN
            MMU 6 7, 0
            ORG #C000
            INCBIN "LSENGINE.DAT", 0, 16384
            MMU 6 7, 2
            ORG #C000
            INCBIN "LSENGINE.DAT", 16384, 16384
            MMU 6 7, 4
            ORG #C000
            INCBIN "LSENGINE.DAT", 32768, 16384
            MMU 6 7, 6
            ORG #C000
            INCBIN "LSENGINE.DAT", 49152, 16384
            MMU 6 7, 8
            ORG #C000
            INCBIN "LSENGINE.DAT", 65536, 16384
            MMU 6 7, 12
            ORG #C000
            INCBIN "LSENGINE.DAT", 81920, 16384
            MMU 6 7, 14
            ORG #C000
            INCBIN "LSENGINE.DAT", 98304, 16384
            MMU 6 7, 22
            ORG #C000
            INCBIN "LSENGINE.DAT", 114688, 16384
            MMU 6 7, 24
            ORG #C000
            INCBIN "LSENGINE.DAT", 131072, 16384
            MMU 6 7, 26
            ORG #C000
            INCBIN "LSENGINE.DAT", 147456, 16384
            MMU 6 7, 28
            ORG #C000
            INCBIN "LSENGINE.DAT", 163840, 16384
            MMU 6 7, 30
            ORG #C000
            INCBIN "LSENGINE.DAT", 180224, 16384
            MMU 6 7, 38
            ORG #C000
            INCBIN "LSENGINE.DAT", 196608, 16384
            MMU 6 7, 40
            ORG #C000
            INCBIN "LSENGINE.DAT", 212992, 16384
            MMU 6 7, 42
            ORG #C000
            INCBIN "LSENGINE.DAT", 229376, 16384
            MMU 6 7, 44
            ORG #C000
            INCBIN "LSENGINE.DAT", 245760, 16384
            MMU 6 7, 46
            ORG #C000
            INCBIN "LSENGINE.DAT", 262144, 16384
            MMU 6 7, 48
            ORG #C000
            INCBIN "LSENGINE.DAT", 278528, 16384
            MMU 6 7, 50
            ORG #C000
            INCBIN "LSENGINE.DAT", 294912, 16384
            MMU 6 7, 52
            ORG #C000
            INCBIN "LSENGINE.DAT", 311296, 16384
            MMU 6 7, 54
            ORG #C000
            INCBIN "LSENGINE.DAT", 327680, 16384
            MMU 6 7, 56
            ORG #C000
            INCBIN "LSENGINE.DAT", 344064, 16384
            MMU 6 7, 58
            ORG #C000
            INCBIN "LSENGINE.DAT", 360448, 16384
            MMU 6 7, 60
            ORG #C000
            INCBIN "LSENGINE.DAT", 376832, 16384
            MMU 6 7, 62
            ORG #C000
            INCBIN "LSENGINE.DAT", 393216, 16384
            MMU 6 7, 64
            ORG #C000
            INCBIN "LSENGINE.DAT", 409600, 16384
            MMU 6 7, 66
            ORG #C000
            INCBIN "LSENGINE.DAT", 425984, 16384
            MMU 6 7, 68
            ORG #C000
            INCBIN "LSENGINE.DAT", 442368, 16384
            MMU 6 7, 0
            ORG di_end
    ENDIF
#endasm
End Sub

' Copy page, off, n, dest: n bytes (up to 8192) from page's offset off (on into the next page) to
' dest (below #C000)
Public Sub Copy(ByVal page As Integer, ByVal off As Integer, ByVal n As Integer, ByVal dest As Integer)
#asm
            pop hl
            ld a, (hl)
    IFNDEF NTC_ZXN
            ld h, #BF               ; (task: the data page from the page table)
            ld l, a
            ld a, (hl)
    ENDIF
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
dc_done:
            ld bc, #243B            ; bank 5 back in slots 6 and 7
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
            dec b
            ld a, #57
            out (c), a
            inc b
    IFDEF NTC_ZXN
            ld a, 11
    ELSE
            ld a, (ls_h7)           ; (task: its own page back in slot 7)
    ENDIF
            out (c), a
#endasm
End Sub

' Expand(src, dst): the text at src (a scene's, in RAM) up to its end (0) or the line's (10), its
' words from the dictionary, into dst (ending 0): gives where the next starts (Term(): which end)
Public Function Expand(ByVal src As Integer, ByVal dst As Integer) As Integer
#asm
            pop hl
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
    IFDEF NTC_ZXN
            jr z, ex_end
            cp 10
            jr z, ex_end
    ELSE
            jp z, ex_end
            cp 10
            jp z, ex_end
    ENDIF
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
            ld de, 563
            or a
            sbc hl, de
            ld b, 4
            jr nc, ex_win
            add hl, de
            ld de, 563
            or a
            sbc hl, de
            ld b, 2
            jr nc, ex_win
            add hl, de
            ld b, 0
ex_win:
            ld a, b                 ; the window's two pages in
    IFNDEF NTC_ZXN
            ld c, a
            ld b, #BF
            ld a, (bc)
    ENDIF
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
            ld ({xs}), hl
            ld bc, #243B            ; bank 5 back in slots 6 and 7
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
            dec b
            ld a, #57
            out (c), a
            inc b
    IFDEF NTC_ZXN
            ld a, 11
    ELSE
            ld a, (ls_h7)           ; (task: its own page back in slot 7)
    ENDIF
            out (c), a
            pop hl
            ld de, ({xs})
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function

' Term(): the last Expand's end: 0 the text's, 10 a line's
Public Function Term() As Integer
  Term = xt And 255
End Function

