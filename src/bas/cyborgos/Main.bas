' CYBORGOS-Next: the hypervisor for the ZX Spectrum Next in NTC BASIC (docs/cyborgos.md,
' cyborgos-next-port.md) - the CPC 320K version's, with the Next's hardware under it (the MMU's
' 8K pages shaped as the CPC's RAM settings, the tilemap console, esxDOS, the ESP). Up to 20
' slots, each its own 64K: a command line, or a CP/M program (.CYB) running from #0100. The
' programs run in turn (the one in front gets half the time); each BDOS call is a far call and
' characters out are collected in the bank and sent a line at a time; an interrupt stops a
' program and hands the CPU back. Every slot has its own text page; the slot in front is on the
' screen.
'   Caps Shift + 0    TOP; on TOP the slot's key: 1-9, 0 (10), A-J (11-20); Caps Shift + 0 again: back
'   commands          RUN, CLS, QUIT; any other name runs that program (HELP, DIR, PS ... are on
'                     the system drive Z, P: or the card)
' The kernel split: this is C0 - main RAM, the memory manager and the hardware (the banks, the
' screen, the keys, the card, the slots' runs). The kernel - the scheduler, the command line,
' TOP, the slots' states - is KERNEL.CYB (src/bas/cyborgoskernel, the same file the CPC runs),
' read at boot from the boot archive (A:) into a 64K of its own (its #0000-#BFFF swapped in, the
' tilemap's bank 5 above) and run as a slot's program is; it asks for everything here through
' BDOS 132 (a block at its #EE00: Serve). Main RAM keeps only this half.
#Const DIAGKEYS = 0               ' 1 (zxn): the keyboard matrix live on TOP's bottom line (KeyRows)
#Const SCROLLBACK = 0             ' 1: the scrollback (Shift + Up / Down) - with CN_SB 1 in Hyp.cls's Con. Off
                                  ' for now (2026-10-16)
Option PressAnyKeyOnEnd "Press a key"     ' at the end: a message and a key (a RUN" program resets when it ends)
Option Explicit
Option NoTurbo                    ' normal mode only (interrupt classes, the clock): one copy of each keyword
Option RomEnable All              ' every background ROM (the disc ROM in 7 - AMSDOS, UniDOS ... - and any
                                  ' others: an IDE / SD interface's, the M4's), for files
Option Reserve &H4000, &H4000     ' the window the slots' banks are reached through (built round)
#If NTC_ZXN Then
Option NexData "CYBORGOS.ARC", 10 ' zxn: the boot archive (A: - tools/nexarc/build.sh: CYBORGOS.Z, RAMDISC.CYB, the
                                  ' commands, the help, KERNEL.CYB), in the NEX's data banks (10 x 16K: banks 1-4,
                                  ' 6, 7, 11, 22-24 - the Memory class's pool starts after them), read by Hyp's
                                  ' FileCall as the CPC reads its boot disc; RAMDISC Z SYSTEM A makes Z from it
#End If
Option Buffer Size 128            ' Memory.Copy's buffer: 128 bytes a go (PRIMAL's copy buffer) - FileSystem,
                                  ' which needs 2K, isn't used (Hyp.FileCall)
#If NTC_LIBRARY_ROM Then
Option Memory CPCExpansion 33     ' 8 banks (32 pages + main RAM) at most: the page tables (3 bytes a
                                  ' page) must fit between the program and the ROM's RAM (#8800) - 4 slots
#Else
Option Memory CPCExpansion 257    ' 64 banks (256 pages + main RAM): all of a 4MB expansion - the page
                                  ' tables (3 bytes a page) between the program and the firmware
#End If
#If NTC_LIBRARY_ROM Then
Const MAXS = 4                    ' the most slots (Library: ROM: 8 banks of tables - 4 slots)
#Else
Const MAXS = 20                   ' the most slots (TOP's keys: 1-9, 0, A-J)
#End If
Const KB = &HEE00                 ' the kernel's block (its #EE00): #6E00 with its page 3 in the window
Const STORE = &HFF00              ' in a slot's bank: its store's page numbers (32, 0: none)
#If NTC_ZXN Then
Const LNMAX = 65                  ' a command line's most (#F690 on: #F6D1-#F6D5 are the hypervisor's -
#Else                             ' Hyp.SWAP - which a program's CybSys.Tail must not lose)
Const LNMAX = 70
#End If
Dim ns As Integer, i As Integer, k As Integer, hk As Integer, hp As Integer   ' hp: the hypervisor's page
Dim dp As Integer                 ' the RAM discs' driver's page (RAMDISC.CYB's; 0: none yet)
Dim bz As Integer                 ' FileCall 99's answer (zxn: 0 when D: was mapped to C:CYBORGOS/)
Dim bd As Integer                 ' the boot drive (A, or "CYB d" at #BE80): the slots' first drive, CYBORGOS.Z
Dim mz As Integer, nz As Integer  ' True: no RAM discs survived a reset - the kernel makes Z; no Z at all (NOSYSZ)
Dim front As Integer              ' the slot in front (the kernel's, for the services and the console)
Dim kra As Integer, kwp As Integer, ksp As Integer   ' the kernel's BDOS answer; its page 3 in the window
' slot 0 is the kernel's bank
Dim bk(MAXS) As Integer, sg(MAXS) As Integer, st(MAXS) As Integer       ' bank, RAM setting, state (the kernel's)
Dim wp(MAXS) As Integer                                           ' the RAM setting with its page 3 in the window
Dim bpg(MAXS * 4 + 3) As Integer  ' the 4 pages of each slot's bank (Far)
Dim dv(MAXS) As Integer                                           ' its drive (CD: the letter's code; 0: none yet)
Dim dm(MAXS) As Integer                                           ' its DMA address (CP/M's record buffer, BDOS 26)
Dim ca As Integer, cw As Integer  ' OwnCall: the answer, how the slot goes on
Dim kw(15) As Integer             ' the kernel's block: the op, 4 words; the answers (kw(8) on), kw(15) the clock
Dim kd(223) As Byte               ' ... its data
Dim rb(127) As Byte               ' a record (Hyp.FileCall's buf, the RAM disc driver's copies)
Dim en As String Max 60           ' (Memory.Map's line; DIAG's key rows)
Dim dn As String Max 16           ' the file opened (KERNEL.CYB)
Dim a As String Max 72            ' CyborgOS's command line at #BE80
Dim stage As Integer              ' DIAG: highest boot marker reached (MarkWait)

Mode 2
#asm
    IFDEF NTC_ZXN
            ld (ntc_ip), sp        ; (SP is the thread: the real stack for the call)
            ld sp, (ntc_csp)
            call gfx_on            ; zxn: Layer 2 on under the tilemap (graphics later; the text is the tilemap)
            ; the background CPC blue: with Layer 2 on the tilemap's paper is see-through and
            ; Layer 2's cleared colour (its palette's index 0) is what shows - that index the CPC's
            ; blue (9-bit RGB 0 0 4: #44 takes RRRGGGBB then the blue's low bit), as gfx_on does
            ; its registers (gfx_nr: A = the register, E = the value); the tilemap's palette back after
            ld hl, l2blue
            ld d, 5
l2bl:       ld a, (hl)
            inc hl
            ld e, (hl)
            inc hl
            call gfx_nr
            dec d
            jr nz, l2bl
            jr l2bdone
l2blue:     db #43, #10, #40, 0, #44, #02, #44, 0, #43, #30
l2bdone:
            call ntc_zxn_inthold   ; the line interrupt held until taken (the Next's interrupt controller,
            ld sp, (ntc_ip)        ; core 3.02+): a slot computing with interrupts off between keywords
    ENDIF                          ; can't miss a tick - the keys, the slices, the ports stay live
#endasm
#If NOIRQ Then                     ' a test build (HYPARGS="--const=NOIRQ"): no interrupt counts a tick
#asm                               ' (as JNEXT while slots run) - every tick is the loop's catch-up
            ld hl, noirq
            ld (#0039), hl
            jr noirqd
noirq:      ei
            reti
noirqd:
#endasm
#End If
Hyp.Vdu 0                         ' the firmware's text off (TXT VDU DISABLE): AMSDOS says "NAME.CYB not
                                  ' found" when RUN looks for files, on top of the console (Con draws it).
                                  ' Jumpblock calls only - no ROM's own RAM (AMSDOS's message flag at #BE78
                                  ' is where one ROM keeps it, not every model's)
k = Memory.Banks()
#If NTC_ZXN Then
If k < 4 Then Hyp.Vdu 1 : Print "CyborgOS needs 320K" : End
#Else
If k < 4 Then Hyp.Vdu 1 : Print "CyborgOS needs 320K (a 256K expansion) or more" : End
#End If
ns = k \ 2                                      ' half the banks are slots (the first bank never:
If ns > MAXS Then ns = MAXS                     ' its pages are the hypervisor's)
Hot.Slots ns                                    ' (more than 10: Control + a number twice is 11-20)
' the hypervisor's own 16K pages: the first expansion bank's, C4 first (C5 ... as it grows),
' taken before any slot's bank - main RAM's own #4000-#7FFF (page 1) is kept, unused (a second
' screen): taken first, so that nothing else gets it (RAM discs take free pages)
i = Memory.AllocPage(Memory.TypeUser)           ' (page 1)
hp = Memory.AllocPage(Memory.TypeUser)          ' bank 1's page 0 (C4): the disc buffers ...
Memory.SelectPage hp
Hyp.UsePage                                     ' (its RAM setting, for Hyp.FileCall)
Hyp.FontInit                                    ' (the font into it, at #5000)
i = Memory.AllocPage(Memory.TypeUser)           ' bank 1's page 1 (C5): the services (Hyp.Svc: BDOS
Memory.SelectPage i                             ' 131 ops 10-15), out of main RAM
Hyp.UseSvc
Hyp.SvcVars VarPtr(st), VarPtr(sg), VarPtr(ns), VarPtr(front), VarPtr(dp)
bz = Hyp.FileCall(99, 0, 0, 0, 0, 0, VarPtr(rb)) ' (the bank image and FileCall's page code into it,
                                                ' from #5300: from main RAM's #4000-#7FFF, where the
                                                ' file put them - free from now on)
i = Hyp.Svc(0, 0, 0, VarPtr(rb))                ' (the services' code into the service page: #6000 on)
For i = 0 To ns                                 ' the kernel's bank (0), then the slots'
  bk(i) = Memory.AllocBank()
  Memory.SelectPage Memory.BankPage(bk(i), 0)
  sg(i) = Hyp.Setting()
  wp(i) = (sg(i) And &HFFF8) Or 7                ' its page 3 (#C000-#FFFF: OBUF, the console) in the window
  For k = 0 To 3
    bpg(i * 4 + k) = Memory.BankPage(bk(i), k)
  Next
                                                ' (zxn too: its settings are shaped as the CPC's)
#If SCROLLBACK Then
  Memory.WriteWord Far(i, &HFF20), 0             ' no scrollback yet (Hyp.Con: below)
  Memory.WriteWord Far(i, &HFF24), 0
  Memory.WriteByte Far(i, &HFF26), 0
#End If
Next
kwp = wp(0)
' CyborgOS's command line at #BE80 (it outlives a reset; CYBORGOS.BAS puts it there): "CYB d" - the
' boot drive -, then words: KEYREP n (the keys' repeat n times slower, the double tap's wait n times longer: WinAPE at 1000% wants 10)
a = ""
If Peek(&HBE80) = 67 And Peek(&HBE81) = 89 And Peek(&HBE82) = 66 And Peek(&HBE83) = 32 Then
  i = &HBE84
  Do While Peek(i) <> 0 And i < &HBEC0
    a = a + Chr$(Peek(i))
    i = i + 1
  Loop
  a = UCase$(a)
End If
i = InStr(a, " KEYREP ")
If i > 0 Then
  k = Val(Mid$(a, i + 8))
  If k > 1 Then Hyp.KeyRep k : Hot.Speed k             ' (the double tap's time too: real time, not ticks)
End If
bd = 65                                         ' the boot drive: "CYB d" (A without it)
If a <> "" Then bd = Asc(a)
mz = 0 : nz = 0
#If NTC_ZXN Then
#If NOSYSZ Then
i = ProbeDiscs()                                ' zxn, NOSYSZ (tools/nexarc/build.sh --noz): no Z - the
nz = -1                                         ' commands run from P: (C:CYBORGOS/C/, mapped at boot),
#Else                                           ' boot faster and the RAM is the slots'. RAM discs a
                                                ' reset left are still claimed back
If ProbeDiscs() = 0 And Memory.Banks() >= 4 Then mz = -1   ' zxn: no RAM discs survived a reset: Z from the
                                                ' boot archive (A: the NEX's data banks) - from 4 banks up
#End If
#Else
If ProbeDiscs() = 0 And Memory.Banks() >= 8 Then mz = -1   ' no RAM discs survived a reset: Z from the disc -
                                                ' only from 576K (8 banks) up
#End If
#If SCROLLBACK Then
For i = 1 To ns                                 ' each slot's scrollback (Hyp.Con: 48 rows, 4 slots a free
  If (i And 3) = 1 Then                         ' 16K page - none when there is none; after the RAM discs
    hk = Memory.AllocPage(Memory.TypeUser) : k = 0   ' a reset left have their pages back)
    If hk Then Memory.SelectPage hk : k = (Hyp.Setting() And &HFFF8) Or (4 + ((hk - 2) And 3))   ' (it in the window)
  End If
  Memory.WriteWord Far(i, &HFF22), ((i - 1) And 3) * 4096 + &H4000
  Memory.WriteWord Far(i, &HFF20), k
Next
#End If
' the kernel: KERNEL.CYB from the boot archive (A:) into its bank at #0100, started as a slot's
' program is (the bank image, its first stack), then run - its asking served - till QUIT
#If NTC_ZXN Then
i = Hyp.Drive(65)
#Else
i = Hyp.Drive(bd)
#End If
dn = "KERNEL.CYB"
If Hyp.FileCall(100, VarPtr(dn), 0, 0, Len(dn), 0, 0) <> 0 Then
  Hyp.Vdu 1 : Mode 1
  Print "CyborgOS: no KERNEL.CYB"
  End
End If
Install 0
i = Hyp.FileCall(103, KB - &H100, 0, sg(0), &H100, 0, VarPtr(rb))   ' (#0100 to its block)
i = Hyp.FileCall(102, 0, 0, 0, 0, 0, 0)
Launch 0
Memory.WriteByte Far(0, &H80), 0                ' (no command tail)
kra = 0
Do
  Hyp.Reply kra, kra
  k = Hyp.Run(sg(0))
  kra = 0
  i = Hyp.Count()
  If i > 0 Then KShow i
  If k = 1 Then
    i = Hyp.Fn()
    If i = 132 Then
      Serve
    ElseIf i = 0 Then
      Quit -1                     ' (the kernel ended: a fault in it)
    ElseIf i <> 128 And i <> 129 Then
      kra = 255
    End If
  End If
Loop

' DIAG: step gate - wait for SPACE via the raw key matrix (Keys.Down works even before
' interrupts/Inkey are live). Release-press-release so a held key can't skip a step.
Sub WaitKey(ByVal ch As Integer)
  Dim k As Integer
  Do
    k = Inkey
    If k >= 97 And k <= 122 Then k = k - 32
  Loop Until k = ch                               ' press the displayed letter to step
End Sub

' ---- the kernel's asking (BDOS 132: KERNEL.bas's header lists the ops)

Sub Serve()
  Dim t As Integer, c As Integer
  KIn
  t = kw(1)
  Select Case kw(0)                               ' (the op: the kernel's word, high byte 0)
    Case 12                                       ' RUN t a k n: up to n And 255 slices, n \ 256 calls here
      Hyp.Reply kw(2), kw(2)
      kw(11) = 0 : kw(13) = 0 : kw(14) = 0
      c = kw(4) \ 256
      Do
        kw(8) = Hyp.Run(sg(t))
        kw(13) = kw(13) + 1
#If NTC_ZXN Then
        TickPoll                                  ' the clock after every turn a slot takes, not once a
                                                  ' pass: a pass is up to 32 calls - longer than a frame
                                                  ' (with no interrupt taken the clock ran at 78 a second
                                                  ' under PET + RAT + MODEL: PET 4x slow)
#End If
        kw(9) = Hyp.Count()
        If kw(9) > 0 Then Hyp.Con wp(t), 0, kw(9), IIf(t = front, 1, 0) : kw(11) = kw(11) + kw(9)   ' straight from the bank
        If kw(8) = 0 Then
          kw(14) = kw(14) + 1                     ' a slice used
          If kw(14) >= (kw(4) And 255) Then Exit Do
        Else
          OwnCall t                               ' a BDOS call: answered here if it is C0's (cw 0 on,
          If cw = 1 Then                          ' 2 the turn over, 3 a port's wait), else the kernel's
            kw(9) = Hyp.Fn() : kw(10) = Hyp.Arg()
            Exit Do
          End If
          Hyp.Reply ca, ca
          c = c - 1
          If cw <> 0 Or c <= 0 Then
            kw(8) = cw : kw(9) = ca
            If cw = 0 Then kw(8) = 2
            Exit Do
          End If
        End If
      Loop
      If kw(3) <> 0 Then kw(12) = Memory.ReadByte(Far(t, Hyp.KEY))
    Case 22                                       ' HOT w (once a pass of the kernel's loop)
#If NTC_ZXN Then
      TickPoll                                    ' a tick whose pulse was lost (JNEXT: none taken while
      Hot.Poll                                    ' slots run) made up; the system keys once a frame from
#If DIAGKEYS Then                                 ' here too (the tick is a pulse the slots can miss)
      If front = 0 Then KeyRows                   ' DIAG: the keyboard matrix's 8 rows, on TOP's bottom line
#End If
#End If
      kw(8) = Hot.Take()
      If kw(8) = 0 And t <> 0 Then kw(9) = Inkey : kw(10) = Hot.Control() : kw(11) = Hot.Held()
    Case 1
      kw(8) = Memory.ReadByte(Far(t, kw(2)))
    Case 2
      Memory.WriteByte Far(t, kw(2)), kw(3)
    Case 7                                        ' CON t n f
      KDIn VarPtr(kd), kw(2)
      Hyp.Con wp(t), VarPtr(kd), kw(2), kw(3)
    Case 32
      kw(8) = Inkey : kw(9) = Hot.Control() : kw(10) = Hot.Held()
    Case 3
      kw(8) = Memory.ReadWord(Far(t, kw(2)))
    Case 4
      Memory.WriteWord Far(t, kw(2)), kw(3)
    Case 5                                        ' TOSLOT t a n
      KDIn VarPtr(kd), kw(3)
      Memory.Copy NearP(VarPtr(kd)), Far(t, kw(2)), kw(3)
    Case 6                                        ' FROMSLOT t a n
      Memory.Copy Far(t, kw(2)), NearP(VarPtr(kd)), kw(3)
      KDOut VarPtr(kd), kw(3)
    Case 8
      Hyp.Con wp(t), kw(2), kw(3), kw(4)
    Case 9
      kw(8) = Hyp.Scr(t, kw(2))
    Case 13                                       ' FILE f x t d
      If t = 100 Then
        KDIn VarPtr(kd), kw(2)
        kw(8) = Hyp.FileCall(100, VarPtr(kd), 0, 0, kw(2), 0, 0)
        KDOut VarPtr(kd), kw(2)                  ' (NAME.CYB not there, NAME.COM: the name back)
      ElseIf t >= 100 Then
        kw(8) = Hyp.FileCall(t, kw(2), kw(3), sg(kw(3)), kw(4), 0, VarPtr(rb))
      Else
        kw(8) = Hyp.FileCall(t, kw(2), kw(3), sg(kw(3)), dm(kw(3)), dv(kw(3)), VarPtr(rb))
      End If
    Case 14
      kw(8) = Hyp.Drive(t)
    Case 28
      kw(8) = dv(t)
    Case 29
      dv(t) = kw(2)
    Case 31                                       ' OWNDRIVE t
      If dv(t) = 0 Then dv(t) = bd
      kw(8) = Hyp.Drive(dv(t))
    Case 16
      kw(8) = Hyp.Svc(t, kw(2), sg(t), VarPtr(rb))
    Case 11                                       ' SAY n col row
      KDIn VarPtr(kd), t
      Hyp.Say VarPtr(kd), t, kw(2), kw(3)
    Case 10
#If NTC_ZXN Then
#Else
      Hyp.Inks t, kw(2), kw(3)                    ' (the Next: no inks)
#End If
    Case 23
      Frame
    Case 24
      st(t) = kw(2)
    Case 25
      front = t
    Case 19
      Install t
    Case 30
      Launch t
    Case 15
      Hyp.FileShut t
      c = Hyp.Svc(t, 0, 0, VarPtr(rb))           ' its claims freed (the service page)
    Case 17
      kw(8) = RamDisc(t, kw(2))
    Case 18
      kw(8) = StoreSize(t, kw(2))
    Case 20                                       ' MEMINFO
      kw(8) = Memory.TableEnd() : kw(9) = Memory.Top() : kw(10) = Memory.Pages()
      kw(11) = Memory.RamSize() : kw(12) = Memory.FreePages()
    Case 21                                       ' MEMMAP p
      en = Memory.Map(t, 32)
      kw(8) = Len(en)
      KDOut VarPtr(en), Len(en)
    Case 26                                       ' BOOT
      kw(8) = ns : kw(9) = bd : kw(11) = mz : kw(12) = LNMAX : kw(13) = nz
#If NTC_ZXN Then
      kw(10) = 1                                  ' (the host: the Next)
#Else
      kw(10) = 0
#End If
    Case 33                                       ' BOOTDONE
#If NTC_ZXN Then
      If bz = 0 Then bd = 68 : dv(1) = 0          ' zxn: D: is C:CYBORGOS/ when that folder is on the card
#End If                                           ' (FileCall 99 mapped it): the slots start there - after
      Hyp.BootDrive bd, VarPtr(dv)                ' Z, which is made from the archive (RAMDISC.CYB is on A).
      kw(8) = bd                                  ' (CybSys.BootDrive: CD on it takes a free letter, as on A)
    Case 27
      Quit t
  End Select
  kw(15) = Ticks
  KOut
End Sub

#If NTC_ZXN Then
' TickPoll: a tick whose pulse was lost made up now - the handler run from here, on the real
' stack (Ticks moves on: a slot sleeping on a port wakes; Hot.Tick due)
Sub TickPoll()
#asm
            ld (ntc_ip), sp
            ld sp, (ntc_csp)
            call ntc_zxn_tickpoll
            ld sp, (ntc_ip)
#endasm
End Sub
#End If

' the kernel's block in: its first 32 bytes (the op, its words) into kw
Sub KIn()
#asm
            ld ({ksp}), sp          ; (the real stack: the Next's window is a call)
            ld sp, (ntc_csp)
            ld bc, ({kwp})          ; the kernel's page 3 in the window: its #EE00 at #6E00
    IFDEF NTC_ZXN
            call nxt_win
    ELSE
            out (c), c
    ENDIF
            ld hl, {KB} - #8000
            ld de, {kw}
            ld bc, 32
            ldir
            ld bc, (ntc_rampt)      ; the page that was in the window back
    IFDEF NTC_ZXN
            call nxt_win
    ELSE
            out (c), c
    ENDIF
            ld sp, ({ksp})
#endasm
End Sub

' the answers (kw(8) on) out into the kernel's block
Sub KOut()
#asm
            ld ({ksp}), sp
            ld sp, (ntc_csp)
            ld bc, ({kwp})
    IFDEF NTC_ZXN
            call nxt_win
    ELSE
            out (c), c
    ENDIF
            ld hl, {kw} + 16
            ld de, {KB} - #8000 + 16
            ld bc, 16
            ldir
            ld bc, (ntc_rampt)
    IFDEF NTC_ZXN
            call nxt_win
    ELSE
            out (c), c
    ENDIF
            ld sp, ({ksp})
#endasm
End Sub

' KDIn p, n: the kernel's block's data, n bytes (224 at most), to p here, a 0 after them
Sub KDIn(ByVal p As Integer, ByVal n As Integer)
#asm
            ld ({ksp}), sp
            ld sp, (ntc_csp)
            ld bc, ({kwp})
    IFDEF NTC_ZXN
            call nxt_win
    ELSE
            out (c), c
    ENDIF
            ld hl, {KB} - #8000 + 32
            ld de, ({p})
            ld bc, ({n})
            ld a, b
            or c
            jr z, kdi_none
            ldir
kdi_none:
            xor a
            ld (de), a
            ld bc, (ntc_rampt)
    IFDEF NTC_ZXN
            call nxt_win
    ELSE
            out (c), c
    ENDIF
            ld sp, ({ksp})
#endasm
End Sub

' KDOut p, n: n bytes from p here into the kernel's block's data
Sub KDOut(ByVal p As Integer, ByVal n As Integer)
#asm
            ld ({ksp}), sp
            ld sp, (ntc_csp)
            ld bc, ({kwp})
    IFDEF NTC_ZXN
            call nxt_win
    ELSE
            out (c), c
    ENDIF
            ld hl, ({p})
            ld de, {KB} - #8000 + 32
            ld bc, ({n})
            ld a, b
            or c
            jr z, kdo_none
            ldir
kdo_none:
            ld bc, (ntc_rampt)
    IFDEF NTC_ZXN
            call nxt_win
    ELSE
            out (c), c
    ENDIF
            ld sp, ({ksp})
#endasm
End Sub

' KShow n: characters the kernel printed itself (an NTC run time message: a fault) - on the
' slot in front's console, so they are seen
Sub KShow(ByVal n As Integer)
  Dim t As Integer
  t = front
  If t = 0 Then t = 1
  Memory.Copy Far(0, Hyp.OBUF), NearP(VarPtr(kd)), n
  Hyp.Con wp(t), VarPtr(kd), n, IIf(t = front, 1, 0)
End Sub

' CyborgOS ends (n programs ran; -1: the kernel ended by itself)
Sub Quit(ByVal n As Integer)
  i = Hyp.Scr(0, 2)               ' the screen as at the start (80 x 25)
  Hyp.Vdu 1
  Mode 1
  If n < 0 Then
    Print "CyborgOS: the kernel ended"
  Else
    Print "CyborgOS ended, "; n; " programs ran"
  End If
  End
End Sub

' OwnCall t: slot t's BDOS call (Hyp.Fn, Hyp.Arg) answered here if it is C0's - ca the answer, cw
' 0 the slot goes straight on, 2 the turn ends after it, 3 so does it and the slot sleeps a tick (a
' port's "not yet"); cw 1: the kernel's (0 the end, 129 a key wait, 131's slots, MODE, TOP, MEM)
Sub OwnCall(ByVal t As Integer)
  Dim f As Integer, e As Integer, j As Integer, o As Integer
  f = Hyp.Fn() : e = Hyp.Arg()
  ca = 0 : cw = 0
  Select Case f
    Case 128                                      ' only the characters (already shown)
    Case 26                                       ' the DMA address (CP/M's record buffer)
      dm(t) = e
    Case 14                                       ' select a disc: the slot's drive (as CD)
      dv(t) = 65 + (e And 255)
    Case 25
      If dv(t) <> 0 Then ca = dv(t) - 65
    Case 24                                       ' the login vector: the slot's drive (a bit a drive:
      ca = 1                                      ' A 1, B 2, C 4 - A to H: the low byte)
      If dv(t) <> 0 Then
        For j = 1 To (dv(t) - 65) And 7
          ca = ca * 2
        Next
      End If
    Case 13, 32                                   ' reset the discs; user number: nothing to do
    Case 15 To 36                                 ' files: Hyp.FileCall
      ca = Hyp.FileCall(f, e, t, sg(t), dm(t), dv(t), VarPtr(rb))
    Case 131                                      ' CyborgOS's own: memory, the pointer, the store's
      o = Memory.ReadByte(Far(t, e))              ' blocks, tables, the claims (16-19), the network,
      If o = 10 Or o = 11 Or o >= 13 Then        ' the ports (28-33): in the service page
        ca = Hyp.Svc(t, e, sg(t), VarPtr(rb))
        If ca = 1 And o >= 30 Then cw = 3         ' (a port's "not yet": the slot sleeps a tick)
      ElseIf o = 12 Then                          ' the slot's store: Word(2) K
        ca = StoreSize(t, Memory.ReadWord(Far(t, e + 2)))
      Else
        cw = 1
      End If
    Case 12
      ca = &H22 : cw = 2                          ' CP/M 2.2
    Case 40                                       ' write random with zero fill: as 34
      ca = Hyp.FileCall(34, e, t, sg(t), dm(t), dv(t), VarPtr(rb)) : cw = 2
    Case 130                                      ' RAMDISC.CYB: the RAM discs' driver
      ca = RamDisc(t, e) : cw = 2
    Case Else
      cw = 1
  End Select
End Sub

' ---- memory: the slots' banks, their pages

' BDOS 130 (RAMDISC.CYB): DE = op, letter, the driver's address and length (words) in the
' slot. The driver goes into a page of its own the first time; then it is handed the call (its
' 116: op 0 a RAM disc as drive letter, 2 a free page more for it - taken here -, 1 one of its
' pages back - freed here -, 3 a line for RAMDISC's list). 2: no free page
Function RamDisc(ByVal t As Integer, ByVal p As Integer) As Integer
  Dim g As Integer, o As Integer, f As Long
  o = Memory.ReadByte(Far(t, p))
  If dp = 0 Then
    RamDisc = 255
    If o = 3 Then Exit Function                              ' (the list: none)
    dp = Memory.AllocPage(Memory.TypeUser)
    If dp = 0 Then RamDisc = 2 : Exit Function
    f = Far(t, Memory.ReadWord(Far(t, p + 2)))                 ' (Far's FarPtr: one result for all calls)
    Memory.Copy f, Hyp.FarPtr(dp, 0), Memory.ReadWord(Far(t, p + 4))
    g = Memory.SelectPage(dp)
    Hyp.UseDriver VarPtr(rb)
    g = Hyp.FileCall(110, 0, 0, 0, 0, 0, 0)                    ' (its tables cleared)
  End If
  g = 0
  If o = 2 Then
    g = Memory.AllocPage(Memory.TypeUser)
    RamDisc = 2
    If g = 0 Then Exit Function
    RamDisc = Memory.SelectPage(g)
  End If
  RamDisc = Hyp.FileCall(116, p, t, sg(t), g, Hyp.Setting(), 0)
  If RamDisc < 0 Then RamDisc = Memory.FreePage(RamDisc And &H7FFF) : RamDisc = 0   ' (a page back: + #8000)
  If g <> 0 And RamDisc <> 0 Then RamDisc = Memory.FreePage(g) : RamDisc = 2
End Function

' BDOS 131 op 12: slot t's store - its program's own 16K pages (TypeUser, their numbers in its
' bank at STORE: 32 at most, 0 none), kb K of them (rounded up to whole pages): more taken or
' the extra given back. 0 done, 2 not enough free memory (what it had kept). Gone when the
' program ends (EndTask, RESET: the kernel's StoreFree); a program starts with none (Install)
Function StoreSize(ByVal t As Integer, ByVal kb As Integer) As Integer
  Dim n As Integer, j As Integer, g As Integer
  n = (kb + 15) \ 16
  If kb < 0 Or n > 32 Then n = 32
  For j = 0 To 31
    g = Memory.ReadByte(Far(t, STORE + j))
    If j < n And g = 0 Then
      g = Memory.AllocPage(Memory.TypeUser)
      If g = 0 Then StoreSize = 2 : Exit Function
      Memory.WriteByte Far(t, STORE + j), g
    ElseIf j >= n And g <> 0 Then
      g = Memory.FreePage(g)
      Memory.WriteByte Far(t, STORE + j), 0
    End If
  Next
End Function

' at boot: a RAM disc driver page that outlived a reset (its "CYBD" signature at #7F00, the magic
' word, and the checksum of D_POOL + D_VOL) found among the free pages - that page and the pages
' D_POOL lists are reclaimed, so Z and any other RAM disc are back with no loading. True = found
Function ProbeDiscs() As Integer
  Dim p As Integer, su As Integer, j As Integer, a As Integer, pg As Integer, r As Integer
  ProbeDiscs = 0
  For p = 2 To Memory.Pages()
    If Memory.PageType(p) = Memory.TypeFree Then
      r = Memory.SelectPage(p)
      If Peek(&H7F00) = 67 And Peek(&H7F01) = 89 And Peek(&H7F02) = 66 And Peek(&H7F03) = 68 And Peek(&H7F04) = &H5A And Peek(&H7F05) = &HCB Then
        su = 0
        For j = &H5400 To &H59FF
          su = (su + Peek(j)) And &HFFFF
        Next
        If su = Peek(&H7F06) + Peek(&H7F07) * 256 Then
          dp = Hyp.ClaimPage(p)
          For j = 0 To 255                       ' the pages D_POOL lists (owner <> 0) back too
            a = &H5400 + j * 6
            If Peek(a) <> 0 Then
              pg = Peek(a + 2) + Peek(a + 3) * 256
              r = Hyp.ClaimPage(pg)
            End If
          Next
          r = Memory.SelectPage(dp)
          Hyp.UseDriver VarPtr(rb)
          ProbeDiscs = -1
          Exit Function
        End If
      End If
    End If
  Next
End Function

' a far pointer to address p of main RAM (page 0): CLng(p) of an address from #8000 up is
' negative - not page 0
Function NearP(ByVal p As Integer) As Long
  NearP = CLng(p)
  If p < 0 Then NearP = NearP + 65536
End Function

' a far pointer to address a of slot t's bank (0: the kernel's): its page (bpg: the 4 of each
' slot's bank, kept at the start) * 65536 + #4000 + the address's low 14 bits - as Hyp.FarPtr
' (Memory.BankPage (a And &HC000) \ 16384 was a division and a call every time)
Function Far(ByVal t As Integer, ByVal a As Integer) As Long
#asm
            ld a, ({t})
            add a, a
            add a, a                ; t * 4
            ld e, a
            ld a, ({a} + 1)
            rlca
            rlca
            and 3                   ; + the address's 16K page
            add a, e
            ld e, a
            ld d, 0
            ld hl, {bpg}
            add hl, de
            add hl, de
            ld c, (hl)
            inc hl
            ld b, (hl)              ; BC = the page
            ld hl, ({a})
            ld a, h
            and #3F
            or #40
            ld h, a                 ; HL = #4000 + the low 14 bits
            ld ({result}), hl
            ld ({result} + 2), bc
#endasm
End Function

' the bank image in (page zero, the stubs) - its program and text page are left as they are
Sub Install(ByVal t As Integer)
  Dim p As Integer, n As Integer
  p = Hyp.Info(0) : n = Hyp.Info(1)             ' (one Info result each: it is one variable)
  Memory.Copy Hyp.FarPtr(hp, p), Far(t, 0), n   ' (from the hypervisor's page)
  p = Hyp.Info(2) : n = Hyp.Info(3)
  Memory.Copy Hyp.FarPtr(hp, p), Far(t, Hyp.STUB), n
  Memory.Copy Hyp.FarPtr(hp, Hyp.HFONT), Far(t, Hyp.FONT), 768   ' the font (Con draws from it)
#If NTC_ZXN Then
  p = Hyp.Info(5) : n = Hyp.Info(6)
  Memory.Copy Hyp.FarPtr(hp, p), Far(t, Hyp.HISW), n   ' the hyp->task switch-back receiver, below #FFFE
#End If
  Memory.WriteByte Far(t, Hyp.OBUF + 128), 0      ' no characters collected
  Memory.WriteByte Far(t, Hyp.KEY), 0             ' no key waiting
  For n = 0 To 31                                 ' no store yet
    Memory.WriteByte Far(t, STORE + n), 0
  Next
End Sub

' slot s's first stack: ret to the stub's start (the default FCBs from the tail, then #0100),
' under it #0000 (a ret from the program ends it). At the top of the stub area (#F240-#F2FF,
' which the stubs leave free): BDOS calls and the console run on it, so not next to the text page
Sub Launch(ByVal s As Integer)
  dm(s) = &H80                                   ' CP/M's record buffer to start with
  Memory.WriteByte Far(s, &HF685), 0             ' no escape sequence rest half done (its console)
  Memory.WriteWord Far(s, &HF2FC), Hyp.Info(4)
  Memory.WriteWord Far(s, &HF2FE), 0
  Memory.WriteWord Far(s, &HFFFE), &HF2FC
End Sub

#If NTC_ZXN And DIAGKEYS Then
' DIAG: KeyRow(r) = port #FE read with half row r (0 = #FE: Caps Z X C V ... 7 = #7F: Space Sym M N B),
' bits 0-4 a key each (0 = down); KeyRows: the 8 as hex on TOP's row 31
Function KeyRow(ByVal r As Integer) As Integer
#asm
            pop hl                  ; r
            ld a, (hl)
            inc a
            ld b, a
            ld a, #7F
krrow:      rlca
            djnz krrow
            ld b, a
            ld c, #FE
            in a, (c)
            and #1F
            pop hl                  ; the result
            ld (hl), a
            inc hl
            ld (hl), 0
#endasm
End Function

Sub KeyRows()
  Dim j As Integer
  en = ""
  For j = 0 To 7
    en = en + Hex$(KeyRow(j)) + " "
  Next
  Hyp.Say VarPtr(en), Len(en), 0, 31
End Sub
#End If
