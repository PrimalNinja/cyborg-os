# taskify.py - the generated classes (Data.cls by storyc.py, GfxData.cls by gfxtool.js, FaceSet.cls
# and GameSet.cls by facepack.py) made to run as a CyborgOS task as well as a NEX: the lines a task
# needs go in IFNDEF NTC_ZXN (the NEX build - zxn - assembles exactly what it did before).
#   python3 tools/taskify.py        (build.js runs it after the generators; running it twice is fine)
# What a task needs (docs/TASK.md):
#   - its data isn't where the NEX put it: the data's banks are wherever the hypervisor's archive
#     put them, so a data page is looked up in the page table at #BF00 (City.bas's TaskStart fills it)
#   - MMU slot 7 is the task's own page (the stack, the BDOS stubs, the switch's receiver), not
#     bank 5's second page: after using it, the task's own page goes back (ls_h7, Nx.cls)
#   - no INCBIN and no MMU / ORG data (a task's .CYB is only its program)
#   - the tilemap's map and tile definitions both in bank 5's first page (the second is the
#     hypervisor's console): the map at #0000, the tiles at #0C00
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
MARK = "' (taskify.py: task lines in IFNDEF NTC_ZXN)"

def rd(f): return open(os.path.join(ROOT, f), encoding='latin-1').read()
def wr(f, s): open(os.path.join(ROOT, f), 'w', encoding='latin-1').write(s)

TR_A = ['    IFNDEF NTC_ZXN', '            ld h, #BF               ; (task: the data page from the page table)', '            ld l, a', '            ld a, (hl)', '    ENDIF']
H7 = ['    IFDEF NTC_ZXN', '            ld a, 11', '    ELSE', '            ld a, (ls_h7)           ; (task: its own page back in slot 7)', '    ENDIF']

def back11(s):
    # every "slot 7 back to page 11" -> the task's own page
    return s.replace('            ld a, #57\n            out (c), a\n            inc b\n            ld a, 11\n            out (c), a',
                     '            ld a, #57\n            out (c), a\n            inc b\n' + '\n'.join(H7) + '\n            out (c), a')

def once(s, a, b, name):
    if s.count(a) != 1: raise SystemExit('taskify: %s: %d matches for %r' % (name, s.count(a), a[:60]))
    return s.replace(a, b)

def data():
    f = 'Data.cls'; s = rd(f)
    if MARK in s: return
    # Init: the INCBINs only in the NEX
    s = once(s, '            jp di_end\ndi_end:\n', '            jp di_end\ndi_end:\n    IFDEF NTC_ZXN\n', f)
    s = once(s, '            MMU 6 7, 0\n            ORG di_end\n', '            MMU 6 7, 0\n            ORG di_end\n    ENDIF\n', f)
    # Copy: its page through the table
    s = once(s, '            pop hl\n            ld a, (hl)\n            ld (dc_p1 + 1), a\n',
             '            pop hl\n            ld a, (hl)\n' + '\n'.join(TR_A) + '\n            ld (dc_p1 + 1), a\n', f)
    # Expand: the dictionary's window
    s = once(s, 'ex_win:\n            ld a, b                 ; the window\'s two pages in\n',
             'ex_win:\n            ld a, b                 ; the window\'s two pages in\n    IFNDEF NTC_ZXN\n            ld c, a\n            ld b, #BF\n            ld a, (bc)\n    ENDIF\n', f)
    # (the lines above put ex_end out of a jr's reach in the task build)
    s = once(s, '            jr z, ex_end\n            cp 10\n            jr z, ex_end\n',
             '    IFDEF NTC_ZXN\n            jr z, ex_end\n            cp 10\n            jr z, ex_end\n    ELSE\n            jp z, ex_end\n            cp 10\n            jp z, ex_end\n    ENDIF\n', f)
    s = back11(s)
    wr(f, MARK + '\n' + s)

def sets(f):
    s = rd(f)
    if MARK in s: return
    s = once(s, '            pop hl\n            ld a, (hl)\n            ld ({fp}), a\n',
             '            pop hl\n            ld a, (hl)\n' + '\n'.join(TR_A) + '\n            ld ({fp}), a\n', f)
    s = back11(s)
    wr(f, MARK + '\n' + s)

def gfx():
    f = 'GfxData.cls'; s = rd(f)
    if MARK in s: return
    i = s.index('Public Sub Load()'); j = s.index('End Sub', i)
    body = s[i:j]
    a = body.index('#asm\n') + 5; b = body.index('#endasm')
    nex = body[a:b]
    # the data the NEX file carries (MMU ... ORG ld_end): only the NEX's
    k = nex.index('ld_end:\n') + len('ld_end:\n')
    code, carried = nex[:k], nex[k:]
    t = code
    t = t.replace('            ld sp, (ntc_csp)\n', '            ld sp, (ls_stk)         ; (task: the real stack, ntc_cpmstack - slot 7 is borrowed below)\n')
    # the first patterns: bank 5's copy (pages 120, 121 in the page table), through slot 6
    t = t.replace('            ld hl, #C000            ; 64 from bank 5 (#C000)\n',
                  '            ld bc, #243B\n            ld a, #56\n            out (c), a\n            inc b\n            ld a, (#BF00 + 120)\n            out (c), a\n'
                  '            ld hl, #C000            ; 64 from bank 5\'s copy (its first page)\n')
    t = t.replace('            ld hl, #F400            ; 7 from bank 5 (#F400)\n',
                  '            ld bc, #243B\n            ld a, #56\n            out (c), a\n            inc b\n            ld a, (#BF00 + 121)\n            out (c), a\n'
                  '            ld hl, #D400            ; 7 from bank 5\'s copy (#F400: its second page + #1400)\n')
    t = re.sub(r'(            ld a, )(9[45])\n', lambda m: '            ld a, (#BF00 + %s)\n' % m.group(2), t)
    t = t.replace('            ld hl, #C000            ; every tile transparent (colour 15) first\n            ld de, #C001\n            ld bc, #1FFF\n',
                  '            ld a, #56               ; (task: slot 6 bank 5\'s first page: the tiles go there)\n            out (c), a\n            inc b\n            ld a, 10\n            out (c), a\n            dec b\n'
                  '            ld hl, #CC00            ; every tile transparent (colour 15) first: 128 tiles at #0C00\n            ld de, #CC01\n            ld bc, #0FFF\n')
    t = t.replace('            add a, #C0\n            ld h, a\n            ex de, hl\n', '            add a, #CC\n            ld h, a\n            ex de, hl\n')
    t = t.replace('            ld hl, pats\n', '            ld hl, 0                ; (task: not used - the patterns came from the data)\n')
    t = back11(t)
    new = body[:a] + '    IFDEF NTC_ZXN\n' + nex + '    ELSE\n' + t + '    ENDIF\n' + body[b:]
    s = s[:i] + new + s[j:]
    wr(f, MARK + '\n' + s)

data(); sets('FaceSet.cls'); sets('GameSet.cls'); gfx()
print('taskify: Data, FaceSet, GameSet, GfxData ready for a task build')
