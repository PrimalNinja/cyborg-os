#!/bin/sh
# assemble1 (CyborgOS Builder): run it here, in the stage folder (build/stage)
cd "$(dirname "$0")"
SJ=${SJASMPLUS:-sjasmplus}
command -v "$SJ" > /dev/null 2>&1 || [ ! -x ../../sjasmplus/sjasmplus ] || SJ=$(pwd)/../../sjasmplus/sjasmplus
fail=0
(cd "CYBORGOS.BIN" && "$SJ" --nologo --msg=err --sym=CYBORGOS.sym CYBORGOS.ASM) || { echo "CYBORGOS.BIN failed"; fail=1; }
(cd "CYBFLAT.BIN" && "$SJ" --nologo --msg=err --sym=CYBFLAT.sym CYBFLAT.ASM) || { echo "CYBFLAT.BIN failed"; fail=1; }
(cd "KERNEL.CYB" && "$SJ" --nologo --msg=err --sym=KERNEL.sym KERNEL.ASM) || { echo "KERNEL.CYB failed"; fail=1; }
(cd "HELP.CYB" && "$SJ" --nologo --msg=err --sym=HELP.sym HELP.ASM) || { echo "HELP.CYB failed"; fail=1; }
(cd "COPY.CYB" && "$SJ" --nologo --msg=err --sym=COPY.sym COPY.ASM) || { echo "COPY.CYB failed"; fail=1; }
(cd "ERA.CYB" && "$SJ" --nologo --msg=err --sym=ERA.sym ERA.ASM) || { echo "ERA.CYB failed"; fail=1; }
(cd "TYPE.CYB" && "$SJ" --nologo --msg=err --sym=TYPE.sym TYPE.ASM) || { echo "TYPE.CYB failed"; fail=1; }
(cd "RENAME.CYB" && "$SJ" --nologo --msg=err --sym=RENAME.sym RENAME.ASM) || { echo "RENAME.CYB failed"; fail=1; }
(cd "RAMDISC.CYB" && "$SJ" --nologo --msg=err --sym=RAMDISC.sym RAMDISC.ASM) || { echo "RAMDISC.CYB failed"; fail=1; }
(cd "DIR.CYB" && "$SJ" --nologo --msg=err --sym=DIR.sym DIR.ASM) || { echo "DIR.CYB failed"; fail=1; }
(cd "CD.CYB" && "$SJ" --nologo --msg=err --sym=CD.sym CD.ASM) || { echo "CD.CYB failed"; fail=1; }
(cd "CV.CYB" && "$SJ" --nologo --msg=err --sym=CV.sym CV.ASM) || { echo "CV.CYB failed"; fail=1; }
(cd "MOUNT.CYB" && "$SJ" --nologo --msg=err --sym=MOUNT.sym MOUNT.ASM) || { echo "MOUNT.CYB failed"; fail=1; }
(cd "MKDIR.CYB" && "$SJ" --nologo --msg=err --sym=MKDIR.sym MKDIR.ASM) || { echo "MKDIR.CYB failed"; fail=1; }
(cd "RMDIR.CYB" && "$SJ" --nologo --msg=err --sym=RMDIR.sym RMDIR.ASM) || { echo "RMDIR.CYB failed"; fail=1; }
(cd "DRIVE.CYB" && "$SJ" --nologo --msg=err --sym=DRIVE.sym DRIVE.ASM) || { echo "DRIVE.CYB failed"; fail=1; }
(cd "PS.CYB" && "$SJ" --nologo --msg=err --sym=PS.sym PS.ASM) || { echo "PS.CYB failed"; fail=1; }
(cd "KILL.CYB" && "$SJ" --nologo --msg=err --sym=KILL.sym KILL.ASM) || { echo "KILL.CYB failed"; fail=1; }
(cd "RESET.CYB" && "$SJ" --nologo --msg=err --sym=RESET.sym RESET.ASM) || { echo "RESET.CYB failed"; fail=1; }
(cd "FG.CYB" && "$SJ" --nologo --msg=err --sym=FG.sym FG.ASM) || { echo "FG.CYB failed"; fail=1; }
(cd "PAUSE.CYB" && "$SJ" --nologo --msg=err --sym=PAUSE.sym PAUSE.ASM) || { echo "PAUSE.CYB failed"; fail=1; }
(cd "UNPAUSE.CYB" && "$SJ" --nologo --msg=err --sym=UNPAUSE.sym UNPAUSE.ASM) || { echo "UNPAUSE.CYB failed"; fail=1; }
(cd "DUMP.CYB" && "$SJ" --nologo --msg=err --sym=DUMP.sym DUMP.ASM) || { echo "DUMP.CYB failed"; fail=1; }
(cd "REVIVE.CYB" && "$SJ" --nologo --msg=err --sym=REVIVE.sym REVIVE.ASM) || { echo "REVIVE.CYB failed"; fail=1; }
(cd "SPEED.CYB" && "$SJ" --nologo --msg=err --sym=SPEED.sym SPEED.ASM) || { echo "SPEED.CYB failed"; fail=1; }
(cd "WAIT.CYB" && "$SJ" --nologo --msg=err --sym=WAIT.sym WAIT.ASM) || { echo "WAIT.CYB failed"; fail=1; }
(cd "TOP.CYB" && "$SJ" --nologo --msg=err --sym=TOP.sym TOP.ASM) || { echo "TOP.CYB failed"; fail=1; }
(cd "MEM.CYB" && "$SJ" --nologo --msg=err --sym=MEM.sym MEM.ASM) || { echo "MEM.CYB failed"; fail=1; }
(cd "MODE.CYB" && "$SJ" --nologo --msg=err --sym=MODE.sym MODE.ASM) || { echo "MODE.CYB failed"; fail=1; }
(cd "CLAIMS.CYB" && "$SJ" --nologo --msg=err --sym=CLAIMS.sym CLAIMS.ASM) || { echo "CLAIMS.CYB failed"; fail=1; }
(cd "HWINFO.CYB" && "$SJ" --nologo --msg=err --sym=HWINFO.sym HWINFO.ASM) || { echo "HWINFO.CYB failed"; fail=1; }
(cd "RTCTEST.CYB" && "$SJ" --nologo --msg=err --sym=RTCTEST.sym RTCTEST.ASM) || { echo "RTCTEST.CYB failed"; fail=1; }
(cd "M4TIME.CYB" && "$SJ" --nologo --msg=err --sym=M4TIME.sym M4TIME.ASM) || { echo "M4TIME.CYB failed"; fail=1; }
(cd "NTPTEST.CYB" && "$SJ" --nologo --msg=err --sym=NTPTEST.sym NTPTEST.ASM) || { echo "NTPTEST.CYB failed"; fail=1; }
(cd "SPEAK.CYB" && "$SJ" --nologo --msg=err --sym=SPEAK.sym SPEAK.ASM) || { echo "SPEAK.CYB failed"; fail=1; }
(cd "SIDTEST.CYB" && "$SJ" --nologo --msg=err --sym=SIDTEST.sym SIDTEST.ASM) || { echo "SIDTEST.CYB failed"; fail=1; }
(cd "FLOPPY.CYB" && "$SJ" --nologo --msg=err --sym=FLOPPY.sym FLOPPY.ASM) || { echo "FLOPPY.CYB failed"; fail=1; }
(cd "NET.CYB" && "$SJ" --nologo --msg=err --sym=NET.sym NET.ASM) || { echo "NET.CYB failed"; fail=1; }
(cd "IPCONFIG.CYB" && "$SJ" --nologo --msg=err --sym=IPCONFIG.sym IPCONFIG.ASM) || { echo "IPCONFIG.CYB failed"; fail=1; }
(cd "NETSTAT.CYB" && "$SJ" --nologo --msg=err --sym=NETSTAT.sym NETSTAT.ASM) || { echo "NETSTAT.CYB failed"; fail=1; }
(cd "TICKER.CYB" && "$SJ" --nologo --msg=err --sym=TICKER.sym TICKER.ASM) || { echo "TICKER.CYB failed"; fail=1; }
(cd "CRUNCH.CYB" && "$SJ" --nologo --msg=err --sym=CRUNCH.sym CRUNCH.ASM) || { echo "CRUNCH.CYB failed"; fail=1; }
(cd "LINES.CYB" && "$SJ" --nologo --msg=err --sym=LINES.sym LINES.ASM) || { echo "LINES.CYB failed"; fail=1; }
(cd "CRUNCH.COM" && "$SJ" --nologo --msg=err --sym=CRUNCH.sym --raw=CRUNCH.COM CRUNCH.ASM) || { echo "CRUNCH.COM failed"; fail=1; }
(cd "MON.CYB" && "$SJ" --nologo --msg=err --sym=MON.sym MON.ASM) || { echo "MON.CYB failed"; fail=1; }
(cd "MON2.CYB" && "$SJ" --nologo --msg=err --sym=MON2.sym MON2.ASM) || { echo "MON2.CYB failed"; fail=1; }
(cd "YING.CYB" && "$SJ" --nologo --msg=err --sym=YING.sym YING.ASM) || { echo "YING.CYB failed"; fail=1; }
(cd "YANG.CYB" && "$SJ" --nologo --msg=err --sym=YANG.sym YANG.ASM) || { echo "YANG.CYB failed"; fail=1; }
(cd "RAWYING.CYB" && "$SJ" --nologo --msg=err --sym=RAWYING.sym RAWYING.ASM) || { echo "RAWYING.CYB failed"; fail=1; }
(cd "RAWYANG.CYB" && "$SJ" --nologo --msg=err --sym=RAWYANG.sym RAWYANG.ASM) || { echo "RAWYANG.CYB failed"; fail=1; }
(cd "MODEL.CYB" && "$SJ" --nologo --msg=err --sym=MODEL.sym MODEL.ASM) || { echo "MODEL.CYB failed"; fail=1; }
(cd "RAT.CYB" && "$SJ" --nologo --msg=err --sym=RAT.sym RAT.ASM) || { echo "RAT.CYB failed"; fail=1; }
(cd "RATS.CYB" && "$SJ" --nologo --msg=err --sym=RATS.sym RATS.ASM) || { echo "RATS.CYB failed"; fail=1; }
(cd "NEURAL.CYB" && "$SJ" --nologo --msg=err --sym=NEURAL.sym NEURAL.ASM) || { echo "NEURAL.CYB failed"; fail=1; }
(cd "ASK.CYB" && "$SJ" --nologo --msg=err --sym=ASK.sym ASK.ASM) || { echo "ASK.CYB failed"; fail=1; }
(cd "WATCH.CYB" && "$SJ" --nologo --msg=err --sym=WATCH.sym WATCH.ASM) || { echo "WATCH.CYB failed"; fail=1; }
(cd "PET.CYB" && "$SJ" --nologo --msg=err --sym=PET.sym PET.ASM) || { echo "PET.CYB failed"; fail=1; }
(cd "PROBE.CYB" && "$SJ" --nologo --msg=err --sym=PROBE.sym PROBE.ASM) || { echo "PROBE.CYB failed"; fail=1; }
(cd "GREEN.CYB" && "$SJ" --nologo --msg=err --sym=GREEN.sym GREEN.ASM) || { echo "GREEN.CYB failed"; fail=1; }
(cd "RATBOX.CYB" && "$SJ" --nologo --msg=err --sym=RATBOX.sym RATBOX.ASM) || { echo "RATBOX.CYB failed"; fail=1; }
(cd "RVDU.CYB" && "$SJ" --nologo --msg=err --sym=RVDU.sym RVDU.ASM) || { echo "RVDU.CYB failed"; fail=1; }
(cd "ENC.CYB" && "$SJ" --nologo --msg=err --sym=ENC.sym ENC.ASM) || { echo "ENC.CYB failed"; fail=1; }
(cd "DEC.CYB" && "$SJ" --nologo --msg=err --sym=DEC.sym DEC.ASM) || { echo "DEC.CYB failed"; fail=1; }
(cd "KEYMGR.CYB" && "$SJ" --nologo --msg=err --sym=KEYMGR.sym KEYMGR.ASM) || { echo "KEYMGR.CYB failed"; fail=1; }
(cd "KEYMAN.CYB" && "$SJ" --nologo --msg=err --sym=KEYMAN.sym KEYMAN.ASM) || { echo "KEYMAN.CYB failed"; fail=1; }
(cd "GUI.CYB-cpc" && "$SJ" --nologo --msg=err --sym=GUI.sym GUI.ASM) || { echo "GUI.CYB/cpc failed"; fail=1; }
(cd "GUI.CYB-next" && "$SJ" --nologo --msg=err --sym=GUI.sym GUI.ASM) || { echo "GUI.CYB/next failed"; fail=1; }
(cd "GUIDEMO.CYB" && "$SJ" --nologo --msg=err --sym=GUIDEMO.sym GUIDEMO.ASM) || { echo "GUIDEMO.CYB failed"; fail=1; }
[ $fail = 0 ] && echo "assemble1: all done - now Run again"
exit $fail
