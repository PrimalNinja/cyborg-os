#!/bin/bash
# build.sh - CyborgOS-Next: the commands (the cyborgos platform: .CYB) and the boot archive CYBORGOS.ARC
# the NEX carries (Option NexData in src/bas/cyborgos/Main.bas: 7 blocks of 16K), then the NEX itself.
#   bash tools/nexarc/build.sh <NTC checkout: its src/test holds cli.js, ntcrun.py>
# Needs node, python3 (with the z80 module for the boot check) and sjasmplus on the PATH.
# Out: build/next/CYBORGOS.ARC (the archive), build/next/cmds/*.COM, build/next/CYBORGOS.NEX, .ASM, .sym
set -e
NTC=${1:?the NTC checkout}
HERE=$(cd "$(dirname "$0")/../.." && pwd)
C=$HERE/src/bas/cyborgos320kb/cmds           # the commands (shared with the CPC: CP/M programs)
OUT=$HERE/build/next; mkdir -p $OUT/cmds
cd $NTC/src/test
CLS=$(ls $C/*.cls)
# the commands on the Next's boot archive (A:): CYBORGOS.Z names the ones RAMDISC Z SYSTEM A copies to Z:
# (RAMDISC itself stays on A:). BLOCKS x 16K - the same count as Option NexData in Main.bas. Left off
# for now: FLOPPY (CPC hardware), PS, WAIT, MODE; NET, IPCONFIG, NETSTAT are on the card only (CARDONLY)
BLOCKS=10
LIST=${LIST_OVERRIDE:-"RAMDISC DIR CD CV FG KILL MEM TOP TYPE HELP RESET ERA COPY RENAME MKDIR RMDIR DRIVE"}   # (LIST_OVERRIDE: a test build)
HELPS="HELP RUN CLS QUIT RAMDISC DIR CD CV FG KILL MEM TOP TYPE ERA RESET COPY RENAME MKDIR RMDIR DRIVE"
# the commands are built for the cyborgos platform: .CYB files (the program with its AMSDOS
# header), the same file as the CPC's - the one program format, carried as it is in the archive
# and on the card. (A plain .COM runs too, for CP/M software; it is the compatible form)
for n in $LIST; do
  node cli.js $C/$n.bas $CLS --platform=cyborgos --nocomments --name=$n > $OUT/cmds/$n.ASM
  (cd $OUT/cmds && sjasmplus --nologo --msg=err $n.ASM > /dev/null)
done
# commands for the card only (C:CYBORGOS/C/: dist.sh copies build/next/cmds/*.CYB there) - not in the
# boot archive, which has no room for them: the network's (the ESP)
CARDONLY=${CARDONLY_OVERRIDE:-"NET IPCONFIG NETSTAT"}
for n in $CARDONLY; do
  node cli.js $C/$n.bas $CLS --platform=cyborgos --nocomments --name=$n > $OUT/cmds/$n.ASM
  (cd $OUT/cmds && sjasmplus --nologo --msg=err $n.ASM > /dev/null)
done
rm -f $OUT/cmds/CYBORGOS.Z; for n in $LIST; do [ $n == RAMDISC ] || echo "$n.CYB" >> $OUT/cmds/CYBORGOS.Z; done
ARGS="$OUT/cmds/CYBORGOS.Z"; for n in $LIST; do ARGS="$ARGS $OUT/cmds/$n.CYB"; done
[ -n "$NOHELP" ] || for n in $HELPS; do ARGS="$ARGS $HERE/src/bas/cyborgos320kb/help/$n.HLP"; done   # (NOHELP=1: room for EXTRA)
ARGS="$ARGS $EXTRA"                      # EXTRA="file ...": more files in the archive (tests: an app and its model)
python3 $HERE/tools/nexarc/nexarc.py $OUT/CYBORGOS.ARC $BLOCKS $ARGS
# the hypervisor: assembled where the archive is (INCBIN "CYBORGOS.ARC")
W=t/cosnext; rm -rf $W; mkdir -p $W
cp $HERE/src/bas/cyborgos/{Main.bas,Hyp.cls,Ent.cls,Hot.cls} $W/; cp $OUT/CYBORGOS.ARC $W/; rm -f $W/NTC.NEX
node cli.js $W/Main.bas $W/Hyp.cls $W/Ent.cls $W/Hot.cls --platform=zxn $HYPARGS > $W/Main.ASM   # (HYPARGS="--const=NOIRQ": tests)
(cd $W && sjasmplus --nologo --msg=err --sym=Main.sym Main.ASM > /dev/null)
cp $W/Main.ASM $OUT/CYBORGOSZ.ASM; cp $W/Main.sym $OUT/CYBORGOSZ.sym; cp $W/NTC.NEX $OUT/CYBORGOSZ.NEX
# two builds: CYBORGOSZ.NEX makes the system drive Z: at boot (a RAM disc of the commands - slower to
# boot, ~150K of RAM); CYBORGOS.NEX, the default, has no Z: and runs the commands from P: (the card's
# CYBORGOS/C/, mapped at boot). tools/sdinstall/dist.sh lays out both
rm -f $W/NTC.NEX
node cli.js $W/Main.bas $W/Hyp.cls $W/Ent.cls $W/Hot.cls --platform=zxn --const=NOSYSZ $HYPARGS > $W/Main.ASM
(cd $W && sjasmplus --nologo --msg=err --sym=Main.sym Main.ASM > /dev/null)
cp $W/Main.ASM $OUT/CYBORGOS.ASM; cp $W/Main.sym $OUT/CYBORGOS.sym; cp $W/NTC.NEX $OUT/CYBORGOS.NEX
ls -la $OUT/CYBORGOS.NEX $OUT/CYBORGOSZ.NEX $OUT/CYBORGOS.ARC
