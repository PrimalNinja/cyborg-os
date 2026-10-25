#!/bin/sh
# assemble2 (CyborgOS Builder): run it here, in the stage folder (build/stage)
cd "$(dirname "$0")"
SJ=${SJASMPLUS:-sjasmplus}
command -v "$SJ" > /dev/null 2>&1 || [ ! -x ../../sjasmplus/sjasmplus ] || SJ=$(pwd)/../../sjasmplus/sjasmplus
fail=0
(cd "COSLOAD.BIN" && "$SJ" --nologo --msg=err --sym=COSLOAD.sym COSLOAD.ASM) || { echo "COSLOAD.BIN failed"; fail=1; }
(cd "CYBORGOS.NEX" && "$SJ" --nologo --msg=err --sym=CYBORGOS.sym CYBORGOS.ASM) || { echo "CYBORGOS.NEX failed"; fail=1; }
(cd "CYBORGOSZ.NEX" && "$SJ" --nologo --msg=err --sym=CYBORGOSZ.sym CYBORGOSZ.ASM) || { echo "CYBORGOSZ.NEX failed"; fail=1; }
[ $fail = 0 ] && echo "assemble2: all done - now Run again"
exit $fail
