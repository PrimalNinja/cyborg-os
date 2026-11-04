#!/bin/bash
# cards.sh - the card images in cards/ brought up to date with the build: each CyborgOS image
# (cyborgos-next-sd.img, cyborgos-next-sd-z.img) taken out of its zip as the builder's base, the
# build run (its "Into an image" parts put next/CYBORGOS and next/z/CYBORGOS into them, over what
# was there), then zipped back. blank64 and cpm are left as they are.
# The Next card's base - its NEXTZXOS folder, TBBlue's files, the FAT32 layout - lives only in those
# two zips (each run takes its own last output as the next base). They are the only copy: keep them
# in the repo. To start one again: ZEsarUX's tbblue.mmc (a NextZXOS distribution that comes with
# ZEsarUX) through tools/nexarc/sdimage.py, renamed cyborgos-next-sd.img and zipped, then this script.
#   bash tools/sdinstall/cards.sh            (node on the PATH; NTC beside, as the builder wants it)
set -e
HERE=$(cd "$(dirname "$0")/../.." && pwd); cd "$HERE"
mkdir -p build/next/z
unzip -o -q cards/cyborgos-next-sd.img.zip -d build/next/
unzip -o -q cards/cyborgos-next-sd-z.img.zip -d build/next/z/
# the builder's output kept: a build that stops (its exit status 1) stops here too - before the old
# files in the images are tidied, zipped and shipped as new (2026-11-01: the grep's || true hid it)
if ! node tools/cosbuild/src/cli.js build > build/cards-build.log 2>&1; then
  grep -E "img|error|stopped" build/cards-build.log; echo "cards.sh: the build stopped - nothing zipped (build/cards-build.log)"; exit 1
fi
grep -E "img|error|stopped" build/cards-build.log || true
# the builder puts files over the image's: one that has gone from a folder (a command moved into C/)
# stays - taken out here, for /CYBORGOS, /CYBORGOS/C and /CYBORGOS/HELP (help pages: .HLP, .HRU, .HES -
# an old page gone from the build stayed on the card; 2026-11-01) (cpcimg, built if it isn't)
[ -x tools/cpcimg/cpcimg ] || cc -O2 -o tools/cpcimg/cpcimg tools/cpcimg/cpcimg.c
tidy() {   # tidy IMAGE FOLDER-IN-IT FOLDER-IN-THE-BUILD
  tools/cpcimg/cpcimg dir "$1" "$2" | awk '$2 != "<folder>" && $1 ~ /\./ {print $1}' | while read f; do
    [ -e "$3/$f" ] || { tools/cpcimg/cpcimg del "$1" "$2/$f" > /dev/null && echo "  $2/$f taken out (gone from the build)"; }
  done
}
for I in build/next/cyborgos-next-sd.img:build/next/CYBORGOS build/next/z/cyborgos-next-sd-z.img:build/next/z/CYBORGOS; do
  tidy "${I%%:*}" CYBORGOS "${I#*:}"; tidy "${I%%:*}" CYBORGOS/C "${I#*:}/C"; tidy "${I%%:*}" CYBORGOS/HELP "${I#*:}/HELP"
done
( cd build/next && rm -f ../../cards/cyborgos-next-sd.img.zip && zip -q -9 ../../cards/cyborgos-next-sd.img.zip cyborgos-next-sd.img )
( cd build/next/z && rm -f ../../../cards/cyborgos-next-sd-z.img.zip && zip -q -9 ../../../cards/cyborgos-next-sd-z.img.zip cyborgos-next-sd-z.img )
rm -f build/next/cyborgos-next-sd.img build/next/z/cyborgos-next-sd-z.img
ls -l cards/
