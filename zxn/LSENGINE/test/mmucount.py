import sys
src = open('/tmp/claude-0/-home-claude/763e589f-1b39-5ff1-8745-d6aace327178/scratchpad/cosbot.py').read()
src = src.replace("z.nreg_write = nw; z.nreg_read = nr", """z.nreg_write = nw; z.nreg_read = nr
_nw = z.nreg_write; cnt = {}
def nw2(r, v):
    if 0x50 <= r <= 0x57 and z.frame >= 4500 and z.frame < 4750:
        k = 'hyp' if z.mmu[0] == 16 else ('game' if bytes(z.m.memory[0x100:0x108]) == SIG else 'other task')
        cnt[(k, r)] = cnt.get((k, r), 0) + 1
    _nw(r, v)
z.nreg_write = nw2
SIG = open('/home/claude/work/games/LSENGINE/build/cosnext/LSEOUL/LSGAME.CYB','rb').read()[128:136]
def rep(z):
    if z.frame == 4750:
        tot = sum(cnt.values())
        print('MMU writes in 250 frames (5 s):', tot, '=', tot // 5, 'a second')
        by = {}
        for (k, r), n in cnt.items(): by[k] = by.get(k, 0) + n
        for k, n in by.items(): print(' ', k, n // 5, 'a second')
        print('  by slot:', ' '.join('%X:%d' % (r, sum(n for (k, rr), n in cnt.items() if rr == r) // 5) for r in range(0x50, 0x58)))
z.hooks.append(rep)""")
exec(src)
