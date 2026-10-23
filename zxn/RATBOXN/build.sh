#!/bin/bash
# build.sh - RATBOXN for CyborgOS-Next: the graphics (tools/rbgfx.py), the program (NTC's cyborgos
# platform: RATBOXN.CYB), and beside it what it needs - RAT, LSMODEL (THE LITTLE SEOUL ENGINE's copy
# of MODEL, which fits CyborgOS-Next) and RATBOX.MDL - in build/RATBOXN/, the folder for the SD card.
#   bash build.sh <NTC src folder> <CyborgOS folder> [LSENGINE folder]
# Then in CyborgOS-Next: CD RATBOXN : RUN 2 LSMODEL RATBOX : RUN 3 RAT : RATBOXN
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
set -e
NTC=$(cd "${1:?the NTC src folder}" && pwd)
COS=$(cd "${2:?the CyborgOS folder}" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
LSE=$(cd "${3:-$HERE/../LSENGINE}" && pwd)
OUT=$HERE/build; rm -rf $OUT; mkdir -p $OUT/RATBOXN
SD=$OUT/RATBOXN
CLI="node $NTC/test/cli.js"
CLS=$(ls $COS/src/bas/cyborgos320kb/cmds/*.cls | tr '\n' ' ')
R=$COS/src/bas/cyborgos320kb/apps/rat
python3 $HERE/tools/rbgfx.py
(cd $HERE && $CLI RATBOXN.bas Nx.cls Spr.cls RBGfx.cls $CLS --platform=cyborgos --name=RATBOXN) > $OUT/RATBOXN.ASM 2> $OUT/err.txt || { grep -v WARN $OUT/err.txt; exit 1; }
(cd $OUT && sjasmplus --nologo --msg=err --sym=RATBOXN.sym RATBOXN.ASM)
$CLI $LSE/services/town/LSMODEL.bas $CLS --platform=cyborgos --nocomments --name=LSMODEL > $OUT/LSMODEL.ASM 2>/dev/null; (cd $OUT && sjasmplus --nologo --msg=err LSMODEL.ASM)
$CLI $R/RAT.bas $CLS --platform=cyborgos --nocomments --name=RAT > $OUT/RAT.ASM 2>/dev/null; (cd $OUT && sjasmplus --nologo --msg=err RAT.ASM)
mv $OUT/RATBOXN.CYB $OUT/LSMODEL.CYB $OUT/RAT.CYB $SD/
cp $R/RATBOX.MDL $SD/
rm -f $OUT/err.txt
grep "^ntc_free" $OUT/RATBOXN.sym
ls -la $SD
