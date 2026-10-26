@echo off
rem assemble2 (CyborgOS Builder): run it here, in the stage folder (build\stage)
cd /d "%~dp0"
set SJ=%SJASMPLUS%
if "%SJ%"=="" if exist "%~dp0..\..\sjasmplus\sjasmplus.exe" set SJ=%~dp0..\..\sjasmplus\sjasmplus.exe
if "%SJ%"=="" set SJ=sjasmplus
set fail=0
pushd "COSLOAD.BIN"
"%SJ%" --nologo --msg=err --sym=COSLOAD.sym COSLOAD.ASM
if errorlevel 1 (echo COSLOAD.BIN failed & set fail=1)
popd
pushd "COSLOADF.BIN"
"%SJ%" --nologo --msg=err --sym=COSLOADF.sym COSLOAD.ASM
if errorlevel 1 (echo COSLOADF.BIN failed & set fail=1)
popd
pushd "CYBORGOS.NEX"
"%SJ%" --nologo --msg=err --sym=CYBORGOS.sym CYBORGOS.ASM
if errorlevel 1 (echo CYBORGOS.NEX failed & set fail=1)
popd
pushd "CYBORGOSZ.NEX"
"%SJ%" --nologo --msg=err --sym=CYBORGOSZ.sym CYBORGOSZ.ASM
if errorlevel 1 (echo CYBORGOSZ.NEX failed & set fail=1)
popd
pushd "CYBORGOS.COM"
"%SJ%" --nologo --msg=err --sym=CYBORGOS.sym --raw=CYBORGOS.COM CYBORGOS.ASM
if errorlevel 1 (echo CYBORGOS.COM failed & set fail=1)
popd
if %fail%==0 echo assemble2: all done - now Run again
pause
