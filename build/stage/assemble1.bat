@echo off
rem assemble1 (CyborgOS Builder): run it here, in the stage folder (build\stage)
cd /d "%~dp0"
set SJ=%SJASMPLUS%
if "%SJ%"=="" if exist "%~dp0..\..\sjasmplus\sjasmplus.exe" set SJ=%~dp0..\..\sjasmplus\sjasmplus.exe
if "%SJ%"=="" set SJ=sjasmplus
set fail=0
pushd "CYBORGOS.BIN"
"%SJ%" --nologo --msg=err --sym=CYBORGOS.sym CYBORGOS.ASM
if errorlevel 1 (echo CYBORGOS.BIN failed & set fail=1)
popd
pushd "CYBFLAT.BIN"
"%SJ%" --nologo --msg=err --sym=CYBFLAT.sym CYBFLAT.ASM
if errorlevel 1 (echo CYBFLAT.BIN failed & set fail=1)
popd
pushd "KERNEL.CYB"
"%SJ%" --nologo --msg=err --sym=KERNEL.sym KERNEL.ASM
if errorlevel 1 (echo KERNEL.CYB failed & set fail=1)
popd
pushd "HELP.CYB"
"%SJ%" --nologo --msg=err --sym=HELP.sym HELP.ASM
if errorlevel 1 (echo HELP.CYB failed & set fail=1)
popd
pushd "COPY.CYB"
"%SJ%" --nologo --msg=err --sym=COPY.sym COPY.ASM
if errorlevel 1 (echo COPY.CYB failed & set fail=1)
popd
pushd "ERA.CYB"
"%SJ%" --nologo --msg=err --sym=ERA.sym ERA.ASM
if errorlevel 1 (echo ERA.CYB failed & set fail=1)
popd
pushd "TYPE.CYB"
"%SJ%" --nologo --msg=err --sym=TYPE.sym TYPE.ASM
if errorlevel 1 (echo TYPE.CYB failed & set fail=1)
popd
pushd "RENAME.CYB"
"%SJ%" --nologo --msg=err --sym=RENAME.sym RENAME.ASM
if errorlevel 1 (echo RENAME.CYB failed & set fail=1)
popd
pushd "RAMDISC.CYB"
"%SJ%" --nologo --msg=err --sym=RAMDISC.sym RAMDISC.ASM
if errorlevel 1 (echo RAMDISC.CYB failed & set fail=1)
popd
pushd "DIR.CYB"
"%SJ%" --nologo --msg=err --sym=DIR.sym DIR.ASM
if errorlevel 1 (echo DIR.CYB failed & set fail=1)
popd
pushd "CD.CYB"
"%SJ%" --nologo --msg=err --sym=CD.sym CD.ASM
if errorlevel 1 (echo CD.CYB failed & set fail=1)
popd
pushd "CV.CYB"
"%SJ%" --nologo --msg=err --sym=CV.sym CV.ASM
if errorlevel 1 (echo CV.CYB failed & set fail=1)
popd
pushd "MKDIR.CYB"
"%SJ%" --nologo --msg=err --sym=MKDIR.sym MKDIR.ASM
if errorlevel 1 (echo MKDIR.CYB failed & set fail=1)
popd
pushd "RMDIR.CYB"
"%SJ%" --nologo --msg=err --sym=RMDIR.sym RMDIR.ASM
if errorlevel 1 (echo RMDIR.CYB failed & set fail=1)
popd
pushd "DRIVE.CYB"
"%SJ%" --nologo --msg=err --sym=DRIVE.sym DRIVE.ASM
if errorlevel 1 (echo DRIVE.CYB failed & set fail=1)
popd
pushd "PS.CYB"
"%SJ%" --nologo --msg=err --sym=PS.sym PS.ASM
if errorlevel 1 (echo PS.CYB failed & set fail=1)
popd
pushd "KILL.CYB"
"%SJ%" --nologo --msg=err --sym=KILL.sym KILL.ASM
if errorlevel 1 (echo KILL.CYB failed & set fail=1)
popd
pushd "RESET.CYB"
"%SJ%" --nologo --msg=err --sym=RESET.sym RESET.ASM
if errorlevel 1 (echo RESET.CYB failed & set fail=1)
popd
pushd "FG.CYB"
"%SJ%" --nologo --msg=err --sym=FG.sym FG.ASM
if errorlevel 1 (echo FG.CYB failed & set fail=1)
popd
pushd "WAIT.CYB"
"%SJ%" --nologo --msg=err --sym=WAIT.sym WAIT.ASM
if errorlevel 1 (echo WAIT.CYB failed & set fail=1)
popd
pushd "TOP.CYB"
"%SJ%" --nologo --msg=err --sym=TOP.sym TOP.ASM
if errorlevel 1 (echo TOP.CYB failed & set fail=1)
popd
pushd "MEM.CYB"
"%SJ%" --nologo --msg=err --sym=MEM.sym MEM.ASM
if errorlevel 1 (echo MEM.CYB failed & set fail=1)
popd
pushd "MODE.CYB"
"%SJ%" --nologo --msg=err --sym=MODE.sym MODE.ASM
if errorlevel 1 (echo MODE.CYB failed & set fail=1)
popd
pushd "CLAIMS.CYB"
"%SJ%" --nologo --msg=err --sym=CLAIMS.sym CLAIMS.ASM
if errorlevel 1 (echo CLAIMS.CYB failed & set fail=1)
popd
pushd "FLOPPY.CYB"
"%SJ%" --nologo --msg=err --sym=FLOPPY.sym FLOPPY.ASM
if errorlevel 1 (echo FLOPPY.CYB failed & set fail=1)
popd
pushd "NET.CYB"
"%SJ%" --nologo --msg=err --sym=NET.sym NET.ASM
if errorlevel 1 (echo NET.CYB failed & set fail=1)
popd
pushd "IPCONFIG.CYB"
"%SJ%" --nologo --msg=err --sym=IPCONFIG.sym IPCONFIG.ASM
if errorlevel 1 (echo IPCONFIG.CYB failed & set fail=1)
popd
pushd "NETSTAT.CYB"
"%SJ%" --nologo --msg=err --sym=NETSTAT.sym NETSTAT.ASM
if errorlevel 1 (echo NETSTAT.CYB failed & set fail=1)
popd
pushd "TICKER.CYB"
"%SJ%" --nologo --msg=err --sym=TICKER.sym TICKER.ASM
if errorlevel 1 (echo TICKER.CYB failed & set fail=1)
popd
pushd "CRUNCH.CYB"
"%SJ%" --nologo --msg=err --sym=CRUNCH.sym CRUNCH.ASM
if errorlevel 1 (echo CRUNCH.CYB failed & set fail=1)
popd
pushd "LINES.CYB"
"%SJ%" --nologo --msg=err --sym=LINES.sym LINES.ASM
if errorlevel 1 (echo LINES.CYB failed & set fail=1)
popd
pushd "CRUNCH.COM"
"%SJ%" --nologo --msg=err --sym=CRUNCH.sym --raw=CRUNCH.COM CRUNCH.ASM
if errorlevel 1 (echo CRUNCH.COM failed & set fail=1)
popd
pushd "MON.CYB"
"%SJ%" --nologo --msg=err --sym=MON.sym MON.ASM
if errorlevel 1 (echo MON.CYB failed & set fail=1)
popd
pushd "MON2.CYB"
"%SJ%" --nologo --msg=err --sym=MON2.sym MON2.ASM
if errorlevel 1 (echo MON2.CYB failed & set fail=1)
popd
pushd "YING.CYB"
"%SJ%" --nologo --msg=err --sym=YING.sym YING.ASM
if errorlevel 1 (echo YING.CYB failed & set fail=1)
popd
pushd "YANG.CYB"
"%SJ%" --nologo --msg=err --sym=YANG.sym YANG.ASM
if errorlevel 1 (echo YANG.CYB failed & set fail=1)
popd
pushd "RAWYING.CYB"
"%SJ%" --nologo --msg=err --sym=RAWYING.sym RAWYING.ASM
if errorlevel 1 (echo RAWYING.CYB failed & set fail=1)
popd
pushd "RAWYANG.CYB"
"%SJ%" --nologo --msg=err --sym=RAWYANG.sym RAWYANG.ASM
if errorlevel 1 (echo RAWYANG.CYB failed & set fail=1)
popd
pushd "MODEL.CYB"
"%SJ%" --nologo --msg=err --sym=MODEL.sym MODEL.ASM
if errorlevel 1 (echo MODEL.CYB failed & set fail=1)
popd
pushd "RAT.CYB"
"%SJ%" --nologo --msg=err --sym=RAT.sym RAT.ASM
if errorlevel 1 (echo RAT.CYB failed & set fail=1)
popd
pushd "RATS.CYB"
"%SJ%" --nologo --msg=err --sym=RATS.sym RATS.ASM
if errorlevel 1 (echo RATS.CYB failed & set fail=1)
popd
pushd "NEURAL.CYB"
"%SJ%" --nologo --msg=err --sym=NEURAL.sym NEURAL.ASM
if errorlevel 1 (echo NEURAL.CYB failed & set fail=1)
popd
pushd "ASK.CYB"
"%SJ%" --nologo --msg=err --sym=ASK.sym ASK.ASM
if errorlevel 1 (echo ASK.CYB failed & set fail=1)
popd
pushd "WATCH.CYB"
"%SJ%" --nologo --msg=err --sym=WATCH.sym WATCH.ASM
if errorlevel 1 (echo WATCH.CYB failed & set fail=1)
popd
pushd "PET.CYB"
"%SJ%" --nologo --msg=err --sym=PET.sym PET.ASM
if errorlevel 1 (echo PET.CYB failed & set fail=1)
popd
pushd "PROBE.CYB"
"%SJ%" --nologo --msg=err --sym=PROBE.sym PROBE.ASM
if errorlevel 1 (echo PROBE.CYB failed & set fail=1)
popd
pushd "GREEN.CYB"
"%SJ%" --nologo --msg=err --sym=GREEN.sym GREEN.ASM
if errorlevel 1 (echo GREEN.CYB failed & set fail=1)
popd
pushd "RATBOX.CYB"
"%SJ%" --nologo --msg=err --sym=RATBOX.sym RATBOX.ASM
if errorlevel 1 (echo RATBOX.CYB failed & set fail=1)
popd
pushd "RVDU.CYB"
"%SJ%" --nologo --msg=err --sym=RVDU.sym RVDU.ASM
if errorlevel 1 (echo RVDU.CYB failed & set fail=1)
popd
pushd "ENC.CYB"
"%SJ%" --nologo --msg=err --sym=ENC.sym ENC.ASM
if errorlevel 1 (echo ENC.CYB failed & set fail=1)
popd
pushd "DEC.CYB"
"%SJ%" --nologo --msg=err --sym=DEC.sym DEC.ASM
if errorlevel 1 (echo DEC.CYB failed & set fail=1)
popd
pushd "KEYMGR.CYB"
"%SJ%" --nologo --msg=err --sym=KEYMGR.sym KEYMGR.ASM
if errorlevel 1 (echo KEYMGR.CYB failed & set fail=1)
popd
pushd "KEYMAN.CYB"
"%SJ%" --nologo --msg=err --sym=KEYMAN.sym KEYMAN.ASM
if errorlevel 1 (echo KEYMAN.CYB failed & set fail=1)
popd
pushd "GUI.CYB-cpc"
"%SJ%" --nologo --msg=err --sym=GUI.sym GUI.ASM
if errorlevel 1 (echo GUI.CYB/cpc failed & set fail=1)
popd
pushd "GUI.CYB-next"
"%SJ%" --nologo --msg=err --sym=GUI.sym GUI.ASM
if errorlevel 1 (echo GUI.CYB/next failed & set fail=1)
popd
pushd "GUIDEMO.CYB"
"%SJ%" --nologo --msg=err --sym=GUIDEMO.sym GUIDEMO.ASM
if errorlevel 1 (echo GUIDEMO.CYB failed & set fail=1)
popd
if %fail%==0 echo assemble1: all done - now Run again
pause
