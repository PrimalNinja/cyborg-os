# runcos.py <dir with Main.ASM, Main.sym, NTC.NEX> 'typed'  - CyborgOS-Next in zxnrun
import sys, os
sys.path.insert(0, os.environ['NTCT'])
import zxnrun
d = sys.argv[1]
syms = {}
for line in open(os.path.join(d, 'Main.sym')):
    p = line.replace(':', ' ').split()
    if len(p) >= 3 and p[1] == 'EQU': syms[p[0]] = int(p[2], 16)
zxnrun.run(os.path.join(d, 'Main.ASM'), syms, sys.argv[2].replace('\\n', '\r'))
