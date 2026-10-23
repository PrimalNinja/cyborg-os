#!/bin/bash
# dist.sh - CyborgOS-Next laid out for a card, after tools/nexarc/build.sh (cc, python3 on the PATH):
#   build/next/CYBORGOS/    the folder a real Next wants: copy it and build/next/CYBORGOS.NEX onto
#                           the card. CYBORGOS.NEX and CYBORGOS.Z, C/ the commands (.CYB), HELP/
#                           the help texts - the Next's build - and the CPC's whole set from
#                           build/dsk/cos-disk1..7.dsk (the apps run here too; FLOPPY doesn't)
#   build/next/cyborgos-next-sd.img   for emulators: a bootable 64MB card image (an MBR, FAT32)
#                           holding the System/Next distribution (NextZXOS; its licence allows
#                           copies, not sales) with /NEXTZXOS/AUTOEXEC.BAS running CyborgOS, and
#                           the folder above installed into it; refreshed in place by this script.
#                           ZEsarUX: --mmc-file; CSpect: -mmc=; JNEXT: the SD image setting
#   build/next/z/CYBORGOS/, build/next/z/cyborgos-next-sd-z.img   the same with CYBORGOSZ.NEX: the
#                           system drive Z: made at boot (a RAM disc of the commands). The default
#                           (above) has no Z: - it boots quicker and runs the commands from P:,
#                           the card's CYBORGOS/C/
#   bash tools/sdinstall/dist.sh [IMAGE]          another image instead (an .mmc, a dd of a card)
#   bash tools/sdinstall/dist.sh --cpc IMAGE.IDE  the CPC's set into WinAPE's IDE image (installed
#                           as INSTALL.BAS would; the CPC's own way is INSTALL.BAS from the discs)
#   EXTRAS="folder ..."     more folders installed at the image's top, each under its own name
#                           (LSENGINE's build/cosnext/LSEOUL, RATBOXN's build/RATBOXN: CD LSEOUL ...)
set -e
HERE=$(cd "$(dirname "$0")/../.." && pwd)
B=$HERE/build/next; T=$HERE/tools/sdinstall
[ -x $T/sdinstall ] || cc -O2 -o $T/sdinstall $T/sdinstall.c
if [ "$1" = "--cpc" ]; then
  [ -n "$2" ] || { echo "--cpc IMAGE"; exit 1; }
  exec $T/sdinstall "$2" --dsk $HERE/build/dsk/cos-disk[1-7].dsk /CYBORGOS
fi
[ -f $B/CYBORGOS.NEX ] && [ -f $B/CYBORGOSZ.NEX ] || { echo "build it first: bash tools/nexarc/build.sh <NTC>"; exit 1; }
HELPS=$(sed -n 's/^HELPS="\(.*\)"/\1/p' $HERE/tools/nexarc/build.sh)
# folder F (a real Next's) with NEX file X as its CYBORGOS.NEX
folder() {
  local F=$1 X=$2
  rm -rf $F; mkdir -p $F
  $T/sdinstall $(dirname $F) --dsk $HERE/build/dsk/cos-disk[1-7].dsk /$(basename $F) > /dev/null   # the CPC's set first
  cp $X $F/CYBORGOS.NEX; cp $B/cmds/CYBORGOS.Z $F/                                  # then the Next's over it
  cp $B/cmds/*.CYB $F/C/
  for c in $B/cmds/*.CYB; do if [ -f $F/$(basename $c) ]; then cp $c $F/; fi; done   # (a command the CPC's discs also have, NET ...: the new one there too)
  [ -f $HERE/build/gui/next/GUI.CYB ] && cp $HERE/build/gui/next/GUI.CYB $HERE/build/gui/GUIDEMO.CYB $F/   # (the GUI: apps/gui/build.sh)
  for n in $HELPS; do cp $HERE/src/bas/cyborgos320kb/help/$n.HLP $F/HELP/; done
  echo "$F: $(find $F -type f | wc -l) files"
}
# image I from folder F (its NEX booted by /NEXTZXOS/AUTOEXEC.BAS) and the EXTRAS
image() {
  local I=$1 F=$2
  local W=$(mktemp -d); mkdir -p $W/root/NEXTZXOS; cp $F/CYBORGOS.NEX $W/root/
  python3 $HERE/tools/nexarc/autoexec.py $W/root/NEXTZXOS/AUTOEXEC.BAS '.nexload /cyborgos.nex'
  $T/sdinstall "$I" $F /CYBORGOS > /dev/null
  $T/sdinstall "$I" $W/root / > /dev/null
  for x in $EXTRAS; do $T/sdinstall "$I" $x /$(basename $x) > /dev/null; echo "  + /$(basename $x)"; done
  rm -rf $W; echo "$I: CyborgOS installed"
}
# the two builds: without Z (the default - quicker to boot, the RAM the slots') and with Z
mkdir -p $B/z
folder $B/CYBORGOS $B/CYBORGOS.NEX
folder $B/z/CYBORGOS $B/CYBORGOSZ.NEX
IMG=${1:-$B/cyborgos-next-sd.img}
[ -f "$IMG" ] || exit 0
image "$IMG" $B/CYBORGOS
if [ -z "$1" ]; then
  IZ=$B/z/cyborgos-next-sd-z.img
  cp "$IMG" $IZ                      # (the same card - the System/Next distribution - with Z's NEX)
  image $IZ $B/z/CYBORGOS
fi
