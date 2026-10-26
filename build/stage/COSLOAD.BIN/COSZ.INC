; COSZ.INC - made by CyborgOS Builder: the system drive Z ready-made (21 commands, 176K)
COSZ_FILES  equ 5
COSZ_PAGES  equ 10                  ; the pages in the files
COSZ_CLAIM  equ 12                  ; the pages Z keeps (D_POOL's slots + the driver page)
COSZ_ENT    equ 16                  ; an entry: its first page (0 the driver page), its pages, the name's length, the name (0s after it)
cosz_files:
            db 0, 2, 11, "CYBORGOS.Z1"
            ds 2
            db 2, 2, 11, "CYBORGOS.Z2"
            ds 2
            db 4, 2, 11, "CYBORGOS.Z3"
            ds 2
            db 6, 2, 11, "CYBORGOS.Z4"
            ds 2
            db 8, 2, 11, "CYBORGOS.Z5"
            ds 2
cosz_last   equ cosz_files + (COSZ_FILES - 1) * COSZ_ENT
