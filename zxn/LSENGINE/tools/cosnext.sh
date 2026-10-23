#!/bin/bash
# cosnext.sh - THE LITTLE SEOUL ENGINE for CyborgOS-Next: LITTLE SEOUL (the postie game) as a task in
# its own 64K bank, with the town service (TOWN), RAT, the three models and the debugger (MON with
# the game's map) - a folder for the SD card, run by CyborgOS-Next as it is (docs/TASK.md).
#   bash tools/cosnext.sh <NTC src folder> <CyborgOS folder>
# Out: build/cosnext/LSEOUL/ - copy it to the SD card (any folder), then in CyborgOS-Next:
#   CD LSEOUL            (from C:, the card's top - or wherever it was put)
#   RUN 2 LSMODEL SUIT : RUN 3 LSMODEL KEEPER : RUN 4 LSMODEL STAR : RUN 5 RAT : RUN 6 TOWN 8
#   RUN 7 LSGAME         (it loads LSCITY.DAT into its store; wait for "ready" before the next RUN)
#   RUN 8 MON LSGAME.MAP 7     (the debugger, if wanted)
# and Caps Shift + 7 for the game. Also out: the programs' .ASM and .sym in build/cosnext.
# Every program is built for NTC's cyborgos platform (a .CYB), as CyborgOS's own build makes its
# commands. CyborgOS itself isn't touched: its folder is only read (RAT, MON, their classes).
# Needs node, python3 and sjasmplus.
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
set -e
NTC=$(cd "${1:?the NTC src folder}" && pwd)
COS=$(cd "${2:?the CyborgOS folder}" && pwd)
HERE=$(cd "$(dirname "$0")/.." && pwd)
OUT=$HERE/build/cosnext; rm -rf $OUT; mkdir -p $OUT/LSEOUL
SD=$OUT/LSEOUL
CLI="node $NTC/test/cli.js"
CLS=$(ls $COS/src/bas/cyborgos320kb/cmds/*.cls | tr '\n' ' ')

# 1. the NEX build: the data (build/LSENGINE.DAT), the classes made task-ready (taskify), the NEX the
#    banks 5 and 47 come from
node $HERE/build.js $NTC > $OUT/nexbuild.txt 2>&1 || { tail -5 $OUT/nexbuild.txt; exit 1; }

# 2. the game as a task (CyborgOS runs it from #0100 in its own bank)
FILES=$(cd $HERE && python3 -c "import json;print(' '.join(json.load(open('game.json'))['files']))")
(cd $HERE && $CLI $FILES Keys.cls --platform=cyborgos --name=LSGAME) > $OUT/LSGAME.ASM 2> $OUT/lsgame.err || { grep -v WARN $OUT/lsgame.err; exit 1; }
(cd $OUT && sjasmplus --nologo --msg=err --sym=LSGAME.sym LSGAME.ASM)

# 3. the services: TOWN, LSMODEL (the engine's MODEL), RAT; the models and TOWN.DAT
python3 $HERE/services/towndat.py $SD > /dev/null
for n in TOWN LSMODEL; do $CLI $HERE/services/town/$n.bas $CLS --platform=cyborgos --nocomments --name=$n > $OUT/$n.ASM 2>/dev/null; (cd $OUT && sjasmplus --nologo --msg=err $n.ASM); done
$CLI $COS/src/bas/cyborgos320kb/apps/rat/RAT.bas $CLS --platform=cyborgos --nocomments --name=RAT > $OUT/RAT.ASM 2>/dev/null; (cd $OUT && sjasmplus --nologo --msg=err RAT.ASM)
cp $HERE/services/models/SUIT.MDL $HERE/services/models/KEEPER.MDL $HERE/services/models/STAR.MDL $SD/

# 4. the debugger: CyborgOS's MON (apps/mon) and its map of the game (tools/lsmap.py, from this
#    build's symbols): MON LSGAME.MAP 7 in a console slot shows the game's variables live
M=$COS/src/bas/cyborgos320kb/apps/mon
$CLI $M/MON.bas $M/Bml.cls $M/Mouse.cls $CLS --platform=cyborgos --nocomments --name=MON > $OUT/MON.ASM 2>/dev/null; (cd $OUT && sjasmplus --nologo --msg=err MON.ASM)
python3 $HERE/tools/lsmap.py $OUT/LSGAME.sym $SD/LSGAME.MAP > /dev/null
for n in LSGAME TOWN LSMODEL RAT MON; do mv $OUT/$n.CYB $SD/; done

# 5. the city's data: LSCITY.DAT - an AMSDOS header (both of CyborgOS-Next's drivers read past one,
#    so no data is ever taken for one), a record saying what's in it ("LSC1", n, m, the n NEX banks
#    in the file, the m empty ones left out), then the n banks: the NEX's data banks that have
#    something in them, gfxtool's bank 47, the NEX's bank 5 (named 60) - Nx.LoadCity reads it
python3 - $HERE/build/LSENGINE.DAT $HERE/build/LSENGINE.NEX $SD/LSCITY.DAT $NTC/test $HERE/game.json <<'PY'
import sys, json
dat, nex, out, t, gj = sys.argv[1:6]
sys.path.insert(0, t)
import zxnrun
banks = zxnrun.read_nex(nex)[0]
d = open(dat, 'rb').read()
nb = [b for b in json.load(open(gj))['banks'] if b != 47]          # LSENGINE.DAT's banks, in order
if len(d) != len(nb) * 16384: raise SystemExit('cosnext: LSENGINE.DAT is %d bytes, not %d banks' % (len(d), len(nb)))
full = [(b, d[i * 16384:(i + 1) * 16384]) for i, b in enumerate(nb)]
keep = [(b, x) for b, x in full if any(x)] + [(47, banks[47]), (60, banks[5])]
empty = [b for b, x in full if not any(x)]
rec = bytearray(128); rec[0:4] = b'LSC1'; rec[4] = len(keep); rec[5] = len(empty)
rec[6:6 + len(keep)] = bytes(b for b, _ in keep); rec[6 + len(keep):6 + len(keep) + len(empty)] = bytes(empty)
blob = bytes(rec) + b''.join(x for _, x in keep)
h = bytearray(128); n = len(blob)
h[1:12] = b'LSCITY  DAT'; h[18] = 2                       # (a binary file)
h[24:26] = (n & 0xFFFF).to_bytes(2, 'little'); h[64:67] = n.to_bytes(3, 'little')
h[67:69] = (sum(h[0:67]) & 0xFFFF).to_bytes(2, 'little')
open(out, 'wb').write(bytes(h) + blob)
print('LSCITY.DAT: %d bytes - %d banks (%s), %d empty left out (%s); the store: %dK' % (n + 128, len(keep), ' '.join(str(b) for b, _ in keep), len(empty), ' '.join(map(str, empty)), (len(keep) + 2) * 16))
PY
rm -f $OUT/lsgame.err
ls -la $SD
