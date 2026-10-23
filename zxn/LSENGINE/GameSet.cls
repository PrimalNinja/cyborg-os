' (taskify.py: task lines in IFNDEF NTC_ZXN)
' GameSet - the game's own sprites, put back after a talk scene (made by tools/facepack.py: don't edit). Its patterns are in the
' story banks (two pages, from tools/game.bin); Load page puts them in the Next's sprite RAM and its
' palettes (after them, on the third page) in the sprite palettes.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit

Private fp As Integer

Public Sub Load(ByVal page As Integer)
#asm
            pop hl
            ld a, (hl)
    IFNDEF NTC_ZXN
            ld h, #BF               ; (task: the data page from the page table)
            ld l, a
            ld a, (hl)
    ENDIF
            ld ({fp}), a
            ld bc, #243B
            ld a, #56               ; the patterns' pages in slots 6 and 7
            out (c), a
            inc b
            ld a, ({fp})
            out (c), a
            dec b
            ld a, #57
            out (c), a
            inc b
            ld a, ({fp})
            inc a
            out (c), a
            ld bc, #303B            ; from pattern 0
            xor a
            out (c), a
            ld hl, #C000
            ld c, #5B
            ld d, 64                ; 256 bytes at a time: 16K
fs_lp:
            ld b, 0
            otir
            dec d
            jr nz, fs_lp
            ld bc, #243B            ; the palettes: the third page's first 256 bytes
            ld a, #56
            out (c), a
            inc b
            ld a, ({fp})
            add a, 2
            out (c), a
            dec b
            ld a, #43               ; the sprites' first palette
            out (c), a
            inc b
            ld a, #20
            out (c), a
            dec b
            ld a, #40
            out (c), a
            inc b
            xor a
            out (c), a
            dec b
            ld a, #41
            out (c), a
            inc b
            ld hl, #C000
            ld e, 0
fs_pl:
            ld a, (hl)
            out (c), a
            inc hl
            dec e
            jr nz, fs_pl
            dec b
            ld a, #43
            out (c), a
            inc b
            xor a
            out (c), a
            ld bc, #243B            ; bank 5 back in slots 6 and 7
            ld a, #56
            out (c), a
            inc b
            ld a, 10
            out (c), a
            dec b
            ld a, #57
            out (c), a
            inc b
    IFDEF NTC_ZXN
            ld a, 11
    ELSE
            ld a, (ls_h7)           ; (task: its own page back in slot 7)
    ENDIF
            out (c), a
#endasm
End Sub
