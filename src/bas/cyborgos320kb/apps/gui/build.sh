#!/bin/bash
# build.sh - CyborgOS's GUI, built for NTC's cyborgos platform:
#   build/gui/cpc/GUI.CYB    the service with the CPC's head (cpc/GuiScr.cls: mode 2, the screen)
#   build/gui/next/GUI.CYB   the service with the Next's head (zxn/GuiScr.cls: the tilemap)
#   build/gui/GUIDEMO.CYB    a program with a window (GuiCli.cls) - one file for both machines
# GUI is built once for each machine (--const=HEADZXN for the Next's), so neither carries the
# other's code.   bash build.sh <NTC src folder>
# (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
set -e
NTC=$(cd "${1:?the NTC src folder}" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
NTCT=$NTC/../test; [ -f $NTCT/cli.js ] || NTCT=$NTC/test   # NTC's test/: beside its src/ (src/test/ in an older NTC)
OUT=$(cd "$HERE/../../../../.." && pwd)/build/gui; mkdir -p $OUT
cd $HERE
b() {   # b FOLDER NAME files... (and --const=...)
  local f=$1 o=$OUT/$1 n=$2; shift 2; mkdir -p $o; rm -f $o/$n.CYB
  node $NTCT/cli.js "$@" --platform=cyborgos --name=$n > $o/$n.ASM 2> $o/$n.err || { grep -v WARN $o/$n.err; exit 1; }
  grep -v WARN $o/$n.err || true; rm -f $o/$n.err
  (cd $o && sjasmplus --nologo --msg=err --sym=$n.sym $n.ASM)
  [ -f $o/$n.CYB ] || { echo "$f/$n did not assemble"; exit 1; }
  echo "$f/$n.CYB: $(stat -c %s $o/$n.CYB) bytes, $(grep '^ntc_free' $o/$n.sym)"
}
b cpc GUI GUI.bas cpc/GuiScr.cls ../../cmds/Http.cls --const=HTTPLITE
b next GUI GUI.bas zxn/GuiScr.cls --const=HEADZXN
b . GUIDEMO GUIDEMO.bas GuiCli.cls
