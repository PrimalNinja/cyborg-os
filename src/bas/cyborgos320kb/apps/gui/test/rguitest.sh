#!/bin/bash
# rguitest.sh - RGUI end to end: tools/vdu served on this machine (php -S), the CPC's CyborgOS in
# NTC's harness with an M4 (NTC_M4: real sockets) - NET M4, RUN 2 GUI KEYS R=127.0.0.1:<port>,
# RUN 3 GUIDEMO - and a headless browser on rgui.html (rguiclick.js): pictures of the page before
# and after it clicks Feed and types a name, and the screen's lines and events.
#   bash test/rguitest.sh <NTC src> <CyborgOS folder> <out folder> [limit] [port]
# Needs php, node with playwright (npm i -g playwright; Chromium: PLAYWRIGHT_BROWSERS_PATH).
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
set -e
command -v sjasmplus > /dev/null || { echo "sjasmplus is not on the PATH (the harness assembles with it)"; exit 1; }
NTC=$(cd "${1:?NTC src}" && pwd); COS=$(cd "${2:?CyborgOS}" && pwd); OUT=${3:?out folder}
LIMIT=${4:-4000000}; PORT=${5:-8080}
HERE=$(cd "$(dirname "$0")/.." && pwd)
C=$COS/src/bas/cyborgos320kb
mkdir -p $OUT; OUT=$(cd $OUT && pwd)
rm -rf $OUT/www; mkdir -p $OUT/www
cp $COS/tools/vdu/*.php $COS/tools/vdu/*.html $COS/tools/vdu/*.css $COS/tools/vdu/*.js $OUT/www/
(cd $OUT/www && exec php -S 127.0.0.1:$PORT > $OUT/php.log 2>&1) &
PHP=$!
trap "kill $PHP 2>/dev/null" EXIT
cd $NTC/test
T=t/gui_rgui; rm -rf $T; mkdir -p $T/cy $T/files/A
cp $C/*.bas $C/*.cls $T/cy/
cp $COS/build/gui/cpc/GUI.CYB $COS/build/gui/GUIDEMO.CYB $COS/build/next/CYBORGOS/NET.CYB $T/files/A/
W=$(printf '~%.0s' $(seq 1 200)); L=""
for i in $(seq 1 60); do L="$L$W"; done
rm -f $OUT/cpc.done
(NTC_M4=1 NTC_SHOT=$OUT/cpc.bin NTC_FILES=$T/files NTC_LIMIT=$LIMIT python3 ntcrun.py $T/cy/Main.bas \
  "net m4\n${W}${W}run 2 gui keys r=127.0.0.1:$PORT\n${W}${W}${W}run 3 guidemo\n${W}${W}${L}" \
  $T/cy/Hyp.cls $T/cy/Hot.cls $T/cy/Ent.cls --platform=cpcfw --ram=4160 > $OUT/cpc.log 2>&1; touch $OUT/cpc.done) &
CPC=$!
NODE_PATH=$(npm root -g) node $HERE/test/rguiclick.js http://127.0.0.1:$PORT $OUT/www/data $OUT > $OUT/browser.log 2>&1 || true
wait $CPC || true
grep -v "^WARN" $OUT/cpc.log | grep -v "^ *$" | tail -20
cat $OUT/browser.log
for d in $OUT/www/data/*/; do echo "== lines"; cat $d/log.txt; echo "== events"; cat $d/ev.txt 2>/dev/null; done
python3 $HERE/test/shotgui.py $OUT/cpc.bin $OUT/cpc.png $NTC/test
