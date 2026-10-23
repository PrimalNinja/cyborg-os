#!/bin/bash
# test.sh - the LITTLE SEOUL ENGINE's town on the CPC CyborgOS, in NTC's harness: builds TOWN.DAT,
# TOWN and LSTEST (and RAT, ASK from CyborgOS's apps/rat), boots CyborgOS with 4MB (20 slots),
# starts the models, RAT and TOWN, and runs LSTEST's day. Prints the console at the end.
#   bash test.sh <NTC src folder> <CyborgOS checkout>      (needs node, python3, sjasmplus)
# Scratch work in <NTC src>/test/t/lse (removed first).
# The models are served by town/LSMODEL.bas, the engine's own copy of CyborgOS's MODEL (LBYTES 24000).
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
set -e
NTC=$(cd "${1:?the NTC src folder}" && pwd)
COS=$(cd "${2:?the CyborgOS checkout}" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
C=$COS/src/bas/cyborgos320kb
CLS=$(ls $C/cmds/*.cls | tr '\n' ' ')
python3 $HERE/towndat.py $HERE/build
cd $NTC/test
T=t/lse; rm -rf $T; mkdir -p $T/cy $T/files/A
cp $C/*.bas $C/*.cls $T/cy/
cp $HERE/models/*.MDL $HERE/build/TOWN.DAT $T/files/A/
cp $C/apps/rat/RAT.bas $C/apps/rat/ASK.bas $HERE/town/LSMODEL.bas $HERE/town/TOWN.bas $HERE/town/LSTEST.bas $T/
for n in LSMODEL RAT ASK TOWN LSTEST; do
  node cli.js $T/$n.bas $CLS --platform=cpm > $T/$n.asm
  (cd $T && sjasmplus --nologo --msg=err --raw=$n.COM $n.asm > /dev/null)
  python3 -c "import ntcrun; d = open('$T/$n.COM', 'rb').read(); open('$T/files/A/$n.CYB', 'wb').write(ntcrun.amsdos_header(d, 0x100) + d)"
done
W=$(printf '~%.0s' $(seq 1 200))
NTC_FILES=$T/files NTC_LIMIT=${LIMIT:-1700000} python3 ntcrun.py $T/cy/Main.bas \
  "run 2 lsmodel suit\n${W}run 3 lsmodel keeper\n${W}run 4 lsmodel star\n${W}run 5 rat\n${W}run 6 town 8\n${W}${W}${W}lstest\n" \
  $T/cy/Hyp.cls $T/cy/Hot.cls $T/cy/Ent.cls --platform=cpcfw --ram=4160 2>&1 | grep -v "^WARN" | grep -v "^ *$"
