10 REM CyborgOS 320K: its command line to &BE80 (the boot drive - CYBORGOS.Z, the commands -, then words), then COSLOAD (Z ready-made, then CyborgOS)
20 d$="A"
25 o$="":REM o$=" KEYREP 10": keys repeating 10 times slower (WinAPE at 1000%)
30 a$="CYB "+d$+o$:FOR i=1 TO LEN(a$):POKE &BE7F+i,ASC(MID$(a$,i,1)):NEXT:POKE &BE80+LEN(a$),0
40 RUN"COSLOAD.BIN"
