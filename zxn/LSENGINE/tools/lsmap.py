# lsmap.py <LSGAME.sym> <LSGAME.MAP> - MON's map of LITTLE SEOUL running as a CyborgOS task: the
# player, the day, the talk, the program's memory, the page table - read live from the game's slot
# (MON LSGAME.MAP 7: {s} is the slot; the keys 1-8 pick the toolbar's pages - on the Next,
# Caps Shift + a digit, so MON's arrow keys, are CyborgOS's slot keys: every view is a tool). Made from the task build's symbols, so the addresses are
# always this build's. CyborgOS's MON (apps/mon) reads the slot's memory through BDOS 131 op 10.
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import sys, re

sym = {}
for line in open(sys.argv[1]):
    m = re.match(r'(\S+): EQU 0x([0-9A-F]+)', line)
    if m: sym[m.group(1)] = int(m.group(2), 16)

# (title, variable) - a group's variables read in one go (MON: a 2K buffer, 8 fields a page, their
# names 16 characters at most)
GROUPS = [
    ('player', 'The postie - where, what, how', [
        ('Day', 'day'), ('Minutes', 'mins'), ('Money', 'money'), ('Energy', 'energy'),
        ('Hungry', 'hungry'), ('Room', 'room'), ('Floor', 'floor'), ('In shop no.', 'inshop'),
        ('X', 'px'), ('Y', 'py'), ('Facing', 'pdir'), ('Step', 'pstep'), ('Stunned', 'stun'),
        ('Male', 'male'), ('Reputation', 'rep'), ('Strikes', 'strikes'), ('Hit today', 'hittoday')]),
    ('round', 'The round - the bag, the deliveries', [
        ('In the bag', 'nbag'), ('Done today', 'ndone'), ('Done in all', 'totaldone'),
        ('Total', 'total'), ('Picked', 'pick'), ('Boss', 'boss'), ('Broke', 'broke'), ('Quit', 'quit')]),
    ('talk', 'Talking - the scene, the faces', [
        ('Talking', 'talking'), ('Face shown', 'faceon'), ('Speaker', 'spk'), ('Mood', 'mood'),
        ('Tune', 'tune'), ('Beat', 'beat')]),
    ('frame', 'The frame - the clock, the keys', [
        ('Frames', 'frames'), ('Minute ticks', 'tickm'), ('Fast', 'fast'), ('Key time', 'keyt'),
        ('Street room', 'streetroom'), ('Door cell', 'doorcell'), ('Schedule page', 'schedpg'),
        ('Record of', 'recof')]),
]

out = []
w = out.append
w('; LSGAME.MAP: MON\'s map of LITTLE SEOUL in its slot - made by tools/lsmap.py from LSGAME.sym')
w('; (MON LSGAME.MAP 7: the game in slot 7). The directives: CyborgOS\'s user guide, MON')
w('')
w('title "MON - LITTLE SEOUL"')
w('text "The game in slot {s}, live: its variables, its memory (B back, R again: fresh)."')
w('tool home "Home"')
for key, title, _ in GROUPS: w('tool %s "%s"' % (key, key.capitalize()))
w('tool program "Program"')
w('tool pages "Pages"')
w('tool console "Console"')
w('')
w('cat "LITTLE SEOUL"')
w('')
for key, title, vs in GROUPS:
    assert all(len(t) <= 16 for t, _ in vs)
    vs = sorted(((t, sym['var_' + v]) for t, v in vs if 'var_' + v in sym), key=lambda x: x[1])
    parts = [[]]                        # MON reads 2K at most a source: far apart ones a page of their own
    for t, a in vs:
        if parts[-1] and (a + 2 - parts[-1][0][1] > 2048 or len(parts[-1]) == 8): parts.append([])   # (and 8 fields a page)
        parts[-1].append((t, a))
    for n, part in enumerate(parts):
        lo = part[0][1]; hi = part[-1][1] + 2
        nm = key if n == 0 else '%s%d' % (key, n + 1)
        w('node %s "%s%s"' % (nm, title, '' if len(parts) == 1 else ' (%d of %d)' % (n + 1, len(parts))))
        w('src slot {s} #%04X %d' % (lo, hi - lo))
        w('rec %d' % (hi - lo))
        for t, a in part: w('f "%s" w %d' % (t, a - lo))
        w('view data')
        w('link hex slot {s} #%04X "These in hex"' % lo)
        if n + 1 < len(parts): w('link %s%d "More"' % (key, n + 2))
        w('')
w('node prog "The game\'s memory"')
w('link hex slot {s} #0100 "Its program, from #0100"')
w('link hex slot {s} #%04X "Its variables, from var_%s"' % (min(v for k, v in sym.items() if k.startswith('var_')), 'first'))
w('link hex slot {s} #BF00 "The page table (#BF00: a NEX data page -> the archive\'s)"')
w('link hex slot {s} #F680 "The console\'s state (#F680: its strip [n] at #F68A)"')
w('link text slot {s} #F700 "Its console\'s text"')
w('')
for nm, title, a, n, v in [('program', 'The program, from #0100', 0x100, 2048, 'hex'),
                           ('console', 'Its console\'s text (#F700)', 0xF700, 2000, 'text')]:
    w('node %s "%s"' % (nm, title))
    w('src slot {s} #%04X %d' % (a, n))
    w('view %s' % v)
    w('')
w('node pages "The page table (#BF00)"')
w('src slot {s} #BF00 128')
w('rec 2')
w('count 64')
w('f "NEX bank" #')
w('f "Page" b 0')
w('f "Page" b 1')
w('view list')
w('')
w('node hex k p a "Memory in hex"')
w('title "Hex: {1} {2} {3}"')
w('src {1} {2} {3}')
w('view hex')
w('')
w('node text k p a "Memory as text"')
w('title "Text: {1} {2} {3}"')
w('src {1} {2} {3}')
w('view text')
open(sys.argv[2], 'w', newline='\r\n').write('\n'.join(out) + '\n')
print('LSGAME.MAP: %d bytes' % len('\r\n'.join(out)))
