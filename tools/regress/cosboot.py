# cosboot.py - boots CyborgOS (the CPC set) in NTC's CPC harness and types commands: used by
# cosregress.js (Python only because the harness, NTC's src/test/ntcrun.py, is Python).
#   python3 cosboot.py FILESDIR RAMK LIMIT 'cmd;cmd;...'
# FILESDIR/A holds the installed set (COSLOAD.BIN ...). COSLOAD.BIN is loaded at #40 and run with
# CYB A at #BE80; each command is typed after a pause. Prints the screen at the end, then a
# '===' line. NTC_SRC: NTC's src folder (default: ../ntc/src beside this CyborgOS folder).
# NTC_M4=1: an M4 board with real sockets (the harness's).
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import sys, os, time
HERE = os.path.dirname(os.path.abspath(__file__))
NTC = os.environ.get('NTC_SRC', os.path.join(HERE, '..', '..', '..', 'ntc', 'src'))
files, ram, limit, cmds = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4].split(';')
os.environ['NTC_FILES'] = files; os.environ['NTC_RAM'] = ram; os.environ['NTC_POKE'] = 'BE80=CYB A'
sys.path.insert(0, os.path.join(NTC, 'test'))
import ntcrun
typed = '~' * 400
for c in cmds:
    typed += c + '\r' + ('~' * 400)
d = open(os.path.join(files, 'A', 'COSLOAD.BIN'), 'rb').read()[128:]
t0 = time.time()
h = ntcrun.Host('cpcfw', d, 0x40, typed)
h.run(limit)
print(h.scr.text())
print('=== %s halted=%s pc=%04x typed left=%d secs=%.0f' % (ram, h.m.halted, h.m.pc, len(h.typed), time.time() - t0))
