#!/bin/bash
# cpctest.sh - GUI and GUIDEMO on the CPC's CyborgOS in NTC's harness (4MB, the MultiPlay mouse on
# port B: NTC_MOUSE): RUN 2 GUI, RUN 3 GUIDEMO, Control + 2, then the typed text given (mouse
# moves {mdx,dy,buttons}, keys) and the screen at the end as a picture (shotm2.py).
#   bash test/cpctest.sh <NTC src> <CyborgOS folder> <out prefix> [typed text] [limit]
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
set -e
NTC=$(cd "${1:?NTC src}" && pwd); COS=$(cd "${2:?CyborgOS}" && pwd); OUT=${3:?out prefix}
HERE=$(cd "$(dirname "$0")/.." && pwd)
C=$COS/src/bas/cyborgos320kb
cd $NTC/test
T=t/gui_$(basename $OUT); rm -rf $T; mkdir -p $T/cy $T/files/A
cp $C/*.bas $C/*.cls $T/cy/
cp $COS/build/gui/cpc/GUI.CYB $COS/build/gui/GUIDEMO.CYB $T/files/A/
W=$(printf '~%.0s' $(seq 1 200))
NTC_MOUSE=1 NTC_SHOT=$OUT.bin NTC_FILES=$T/files NTC_LIMIT=${5:-1500000} python3 ntcrun.py $T/cy/Main.bas \
  "run 2 gui\n${W}${W}run 3 guidemo\n${W}${W}{23,65}${W}${4}${W}" $T/cy/Hyp.cls $T/cy/Hot.cls $T/cy/Ent.cls --platform=cpcfw --ram=4160 2>&1 | grep -v "^WARN" | grep -v "^ *$" | tail -30
python3 $HERE/test/shotm2.py $OUT.bin $OUT.png
