# cosboot.py - boots CyborgOS (the CPC set) in NTC's CPC harness and types commands: used by
# cosregress.js (Python only because the harness, NTC's src/test/ntcrun.py, is Python).
#   python3 cosboot.py FILESDIR RAMK LIMIT 'cmd;cmd;...'
# FILESDIR/A holds the installed set (COSLOAD.BIN ...). COSLOAD.BIN is loaded at #40 and run with
# CYB A at #BE80; each command is typed after a pause. Prints the screen at the end, then a
# '===' line. NTC_SRC: NTC's src folder (default: ../ntc/src beside this CyborgOS folder).
# NTC_M4=1: an M4 board with real sockets (the harness's). NTC_ROMTOP: the ROMs' RAM lower (more
# ROMs); COSBOOT_PEEK=addr,...: those words printed at the end (hex); COSBOOT_FROM / _UNTIL: the
# emulated time between two texts on the screen (cosperf.js).
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
import sys, os, time, io, contextlib
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
# COSBOOT_PROF=file: where the Z80 is, sampled (NTC's harness profiler) with the map it runs in (main
# RAM, or which bank) - json [[pc, map], ...] (cosprof.js reads it)
if os.environ.get('COSBOOT_PROF'):
    class Prof(list):
        def append(self, x): list.append(self, [x[0], repr(h.ram.view[0]), x[2]])
    ntcrun.PROF = Prof()
# COSBOOT_FROM / COSBOOT_UNTIL: the emulated time between two texts appearing on the screen
# (looked at every 10 frames: 0.2 s) - printed as "TIME from-until T ms" (cosperf.js)
frm, until = os.environ.get('COSBOOT_FROM', ''), os.environ.get('COSBOOT_UNTIL', '')
if until:
    t0 = None; n = 0
    while n < limit and not h.m.halted:
        with contextlib.redirect_stdout(io.StringIO()): h.run(10)    # (its TIMEOUT line each time: not wanted)
        n += 10
        txt = h.scr.text()
        if t0 is None and (frm == '' or frm in txt):
            t0 = h.T
            if ntcrun.PROF is not None: del ntcrun.PROF[:]     # (the profile: from here)
        if t0 is not None and until in txt:
            print('TIME %d T %d ms' % (h.T - t0, (h.T - t0) // 4000)); break
    else:
        print('TIME none')
else:
    h.run(limit)
print(h.scr.text())
for a in filter(None, os.environ.get('COSBOOT_PEEK', '').split(',')):   # COSBOOT_PEEK=9C46,9C44: the words there at the end
    a = int(a, 16); pg = h.ram.main_page(a >> 14)   # (main RAM's: a slot or the kernel may be paged in at the end)
    print('PEEK %04X %04X' % (a, pg[a & 0x3FFF] | (pg[(a + 1) & 0x3FFF] << 8)))
if os.environ.get('COSBOOT_PROF'):
    import json; json.dump(ntcrun.PROF, open(os.environ['COSBOOT_PROF'], 'w'))
print('=== %s halted=%s pc=%04x typed left=%d secs=%.0f' % (ram, h.m.halted, h.m.pc, len(h.typed), time.time() - t0))
