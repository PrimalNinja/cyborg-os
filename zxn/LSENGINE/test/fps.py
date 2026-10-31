import sys
src = open('/tmp/claude-0/-home-claude/763e589f-1b39-5ff1-8745-d6aace327178/scratchpad/cosbot.py').read()
src = src.replace("z.hooks.append(per)", """z.hooks.append(per)
SIG = open('/home/claude/work/games/LSENGINE/build/cosnext/LSEOUL/LSGAME.CYB','rb').read()[128:136]; cnt = [0]
def lost(z):
    if bytes(z.m.memory[0x100:0x108]) == SIG: cnt[0] += 1
    return False
BP[0x887A] = lost; z.m.set_breakpoint(0x887A)
def fp(z):
    if z.frame % 100 == 0 and z.frame >= 4400: print('fps-ish', z.frame, cnt[0], flush=True)
z.hooks.append(fp)""")
exec(src)
