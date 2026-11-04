' KERNEL - CyborgOS's core (docs/cyborgos.md: the kernel split). The scheduler, the command line,
' TOP, the slots' states, the BDOS calls' answers - everything that needs neither the firmware nor
' the banks - running in a 64K bank of its own (the CPC's C2, the Next's 48K swapped in), as a
' CP/M program: the hypervisor in main RAM (CYBORGOS.BIN on the CPC, CYBORGOS.NEX on the Next -
' "C0") loads this at boot and runs it. C0 is the memory manager and the hardware: the banks, the
' screen, the keys, the discs, the firmware, the slots' runs. Everything this asks of it goes
' through one BDOS call (132) with a block at KB (#EE00, in this bank's top 16K, where C0 reads it
' through its window):
'   KB + 0   the op           KB + 2 ... KB + 9    up to 4 words
'   KB + 16  the answer (r0)  KB + 18 ... KB + 29  more answers (r1 - r6)
'   KB + 30  C0's clock (Ticks: 300 a second on the CPC, 50 on the Next), with every answer
'   KB + 32  up to 224 bytes of data either way (a string to a console, a name, a slot's bytes)
' The ops (C0's Serve, in CYBORGOS.BIN's and CYBORGOS.NEX's Main.bas):
'   1 RB t a         slot t's byte at a          2 WB t a v     ... set
'   3 RW t a         ... its word                4 WW t a v     ... set
'   5 TOSLOT t a n   the data to slot t at a     6 FROMSLOT t a n   slot t's n bytes at a into the data
'   7 CON t n f      the data (n) to slot t's console (f: it is in front)
'   8 CONX t s n f   Hyp.Con with a value (the cursor's flash, the page drawn, the scrollback)
'   9 SCR m k        Hyp.Scr(m, k)               10 INKS p q b  the CPC's inks (the Next: nothing)
'   11 SAY n c r     the data (n) straight onto the screen at column c, row r (TOP)
'   12 RUN t a k n   slot t runs (its BDOS answer a) up to n And 255 slices, answering the BDOS
'                    calls that are C0's (up to n \ 256): r0 0 the slices used, 1 a call for the
'                    kernel (r1 the function, r2 DE), 2 C0 answered a call that ends the turn (r1
'                    the answer), 3 so did it and the slot sleeps a tick (a port); r3 the
'                    characters (on its console already), r4 its key byte (k: it has one), r5 its
'                    runs, r6 the runs its slice ended
'   13 FILE f x t    Hyp.FileCall (100: the data the name, x its length; t's DMA and drive C0's)
'   14 DRIVE d       Hyp.Drive                   15 SHUT t      a slot's files and claims shut
'   16 SVC t p       BDOS 131's ops in the service page        17 RAMDISC t p   BDOS 130
'   18 STORE t k     a slot's store, k K         19 INSTALL t   the bank image into slot t
'   20 MEMINFO       r0 the tables' end, r1 the top, r2 the pages, r3 the RAM (K), r4 free pages
'   21 MEMMAP p      32 pages of the map from p (the data, r0 its length)
'   22 HOT w         the system key pressed (Hot.Take); none and w: r1 a key (Inkey), r2 Control
'                    held, r3 the system key held
'   23 FRAME         a frame's wait                24 SETST t v   slot t's state (the services')
'   25 SETFRONT f    the slot in front           26 BOOT        r0 slots, r1 boot drive, r2 host
'                    (0 CPC, 1 Next), r3 make Z, r4 a command line's most, r5 no Z (NOSYSZ)
'   27 QUIT n        CyborgOS ends (n programs ran)            28 DVGET t / 29 DVSET t v   a slot's drive
'   30 LAUNCH s      slot s's first stack (its program starts at the stubs' start-up), its DMA #0080
'   31 OWNDRIVE t    the slot's drive (the boot drive if none yet) for the hypervisor's reading
'   32 INKEY         r0 a key (Inkey), r1 Control held, r2 the system key held
'   33 BOOTDONE      the boot drive from now on (the Next: D: when C:CYBORGOS/ is there)
'   34 STATS t       (CPC) the calls (r0) and characters (r1) C0 answered for slot t itself since
'                    the last
'   35 CONO t n      (CPC) n characters at slot t's OBUF to its console
'   38 LANG l        the language: 0 English, 1 Russian, 2 Spanish (the code page for 128-255)
'   37 SLOT t g v    r0 slot t's DMA, r1 True when it has a file open, r2 the build's stamp; g 1: its DMA
'                    = v, 3: its own words kept, 2: its bank made its own again (DUMP / REVIVE)
'   36 SG t          (CPC) slot t's RAM setting: the kernel runs the slots itself (KRun), their
'                    interrupts come here (KInit); a slot's calls go by the route in its page zero
'                    (#0008): the kernel's to the kernel, the rest to C0, which answers the slot
' One .CYB for both machines: what differs (the keys' names, the Next's TOP keys) comes from
' BOOT's host. Built for NTC's cyborgos platform; it must end below KB.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
#Const SCROLLBACK = 0             ' 1: the scrollback (Shift + Up / Down) - with CN_SB 1 in Hyp.cls's Con
Option Explicit
Const KB = &HEE00                 ' the block C0 reads (this bank's #EE00: below the stubs at #EF00)
Const TURNS = 3                   ' a slot's turn: up to 3 of Hyp.Run's slices (6 interrupts each: 1/50 s), unless it calls the BDOS
Const TOPKEY = 99                 ' Hot.TOPKEY
Const MAXS = 20                   ' the most slots (Control + 1-9, 0; twice: 11-20)
Const KEY = &HF681                ' a slot's bank (Hyp.cls): its next key (0 none)
Const CCOLS = &HF687              ' ... its console's columns, rows, MODE, the status strip's text
Const CROWS = &HF688
Const CMODE = &HF689
Const CSTRIP = &HF68A
Const CINK = &HF6E5               ' ... its own colours while in front (CPC)
Const LNLEN = &HF68F              ' ... the length of the command line being typed
Const LNBUF = &HF690              ' ... and its characters (lnmax at most: 70 CPC, 65 Next)
Const NMLEN = &HF6D8              ' ... the length of the name of the program it runs
Const NMBUF = &HF6D9              ' ... and its characters (12 at most)
Dim ns As Integer, i As Integer, k As Integer, hk As Integer, kr As Integer, ksp As Integer
Dim ck As Integer                 ' C0's clock (from every answer)
Dim host As Integer, lnmax As Integer, nosysz As Integer, mz As Integer
Dim bd As Integer                 ' the boot drive (A, or "CYB d"; the Next: D: once C:CYBORGOS/ is mapped)
Dim front As Integer, back As Integer, cur As Integer, quit As Integer, wt As Integer, runs As Integer, pk As Integer
Dim fr As Integer, td As Integer, tt As Integer, tc As Integer               ' front's turn next; TOP: last second's start
Dim kfn As Integer, karg As Integer                            ' the BDOS call RUN brought back (C, DE)
Dim kc As Integer, kh As Integer   ' with a key: Control held, the system key held (Hot)
Dim krn As Integer, kre As Integer, kcnt As Integer, ktk As Integer   ' KRun: the interrupts left, E, the characters waiting (CPC)
Dim sgt(MAXS) As Integer, ke(MAXS) As Integer   ' the slots' RAM settings (C0's sg: KRun goes there); E for the next run
Dim st(MAXS) As Integer           ' state (0 closed, 1 command line, 2 running, 3 paused: PAUSE)
Dim kq(MAXS) As Integer           ' key handed to it
Dim ra(MAXS) As Integer, wk(MAXS) As Integer                         ' the BDOS answer; waiting for a key since (Ticks, -1 not)
Dim nz(MAXS) As Integer
Dim lang As Integer                                                   ' the language: 0 English, 1 Russian, 2 Spanish (LANG)
Dim rul As Integer                                                    ' the Russian layout on (Control + Space, with LANG RU)
Dim ax As Integer, qt As Integer, qa As Integer                       ' AUTOEXEC still to run (not with Shift held at boot); a start kept quiet; its end too
Dim tq As String Max 250, tqs As Integer                              ' lines to type (op 5 sub 10), the slot they're for
Dim kl As String Max 70, kr8 As String Max 70                         ' the layout: Latin keys, their KOI8-R letters                                               ' napping: ticks left (BDOS 131 op 5 / 8 - TASKMAN)
Dim tn(MAXS) As Integer, nb(MAXS) As Integer, nc(MAXS) As Integer       ' TOP: turns, BDOS calls, characters this second
Dim lt(MAXS) As Integer, lb(MAXS) As Integer, lc(MAXS) As Integer, ld As Integer   ' ... and in the last whole second (ld ticks)
Dim ob As String Max 82           ' the command line; the longest string here sets every string parameter,
                                  ' function result and temp's size: 82 is a screen line + CR LF
Dim en As String Max 60           ' ... the name looked for; a DIR line
Dim dn As String Max 16           ' ... the file opened (FILE 100)
Dim a As String Max 72, b As String Max 72   ' a command's first word after the command, the rest of the line
                                  ' (RUN and a program run by its name: the program's command tail)
Dim bare As Integer               ' True: a program run by its name alone (not found: "? NAME (HELP)")
Dim txn As Integer, txs As Integer                             ' TOP: lines written, the slot they go to (0: the screen)
Dim ln(MAXS) As String Max 72     ' each slot's command line being typed (into its bank - LNLEN, LNBUF - at Enter:
                                  ' CybSys.Tail reads it there while the program runs)
Dim nm(MAXS) As String Max 12     ' the program each slot runs (in its bank too - NMLEN, NMBUF)

Doke KB + 16, 0                   ' (no answer unless C0 runs this)
kr = KOp(26, 0, 0, 0, 0)            ' BOOT: what C0 found
ns = kr
If ns < 1 Or ns > MAXS Then End               ' (not run by C0 - typed as a command: nothing to do)
bd = Deek(KB + 18) : host = Deek(KB + 20) : mz = Deek(KB + 22) : lnmax = Deek(KB + 24) : nosysz = Deek(KB + 26)
For i = 1 To ns
  wk(i) = -1
Next
ob = Space$(82)
SetFront 1
OpenSlot 1
If mz Then                                      ' no RAM discs survived a reset: the system drive Z made
  a = "RAMDISC" : b = "Z SYSTEM " + Chr$(bd)    ' (the files CYBORGOS.Z names copied to a RAM disc); the
  StartTask 1, 1                                ' command line waits for it (WAIT)
  If st(1) = 2 Then wt = 1
End If
bd = KOp(33, 0, 0, 0, 0)                          ' (BOOTDONE: the Next's D:, the services' boot drive)
ax = (Deek(KB + 18) = 0)                          ' AUTOEXEC: unless Shift was held at boot (BOOTDONE says)
If ax And wt = 0 Then StartAuto                   ' (nothing to wait for: now; else when RAMDISC ends)
If host = 0 Then                                ' the CPC: the kernel runs the slots (their settings from
  For i = 1 To ns                               ' C0) and counts the interrupts itself
    sgt(i) = KOp(36, i, 0, 0, 0)
  Next
  KInit
End If
kl = "qwertyuiop[]asdfghjkl;'zxcvbnm,.`QWERTYUIOP{}ASDFGHJKL:""ZXCVBNM<>~"                ' (the Russian layout: these keys give the KOI8-R letters below - JCUKEN)
kr8 = Chr$(202) + Chr$(195) + Chr$(213) + Chr$(203) + Chr$(197) + Chr$(206) + Chr$(199) + Chr$(219) + Chr$(221) + Chr$(218) + Chr$(200) + Chr$(223) + Chr$(198) + Chr$(217) + Chr$(215) + Chr$(193) + Chr$(208) + Chr$(210) + Chr$(207) + Chr$(204) + Chr$(196) + Chr$(214) + Chr$(220) + Chr$(209) + Chr$(222) + Chr$(211) + Chr$(205) + Chr$(201) + Chr$(212) + Chr$(216) + Chr$(194) + Chr$(192) + Chr$(163) + Chr$(234) + Chr$(227) + Chr$(245) + Chr$(235) + Chr$(229) + Chr$(238) + Chr$(231) + Chr$(251) + Chr$(253) + Chr$(250) + Chr$(232) + Chr$(255) + Chr$(230) + Chr$(249) + Chr$(247) + Chr$(225) + Chr$(240) + Chr$(242) + Chr$(239) + Chr$(236) + Chr$(228) + Chr$(246) + Chr$(252) + Chr$(241) + Chr$(254) + Chr$(243) + Chr$(237) + Chr$(233) + Chr$(244) + Chr$(248) + Chr$(226) + Chr$(224) + Chr$(179)
Do
  ' HOT: the system key - and, when there is none, the key for the front slot (Inkey), if one is
  ' wanted now (left in the keyboard buffer while its program has one waiting): one call a pass
  i = 0
  If pk = 0 And wt = 0 Then
    If front = 0 Then
      i = 1
    ElseIf st(front) <> 2 Or kq(front) = 0 Then
      i = 1
    End If
  End If
  hk = KOp(22, i, 0, 0, 0)
  k = Deek(KB + 18) : kc = Deek(KB + 20) : kh = Deek(KB + 22)        ' (with i and no system key: the key, Control, the system key held)
  If hk = TOPKEY Then
    If front = 0 Then ToFront back Else ShowTop      ' Control + ESC: TOP, and again: back
  ElseIf hk > 0 And hk <= ns Then
    ToFront hk
  End If
  If pk <> 0 And wt = 0 Then                    ' (a key left by a program: after WAIT's prompt)
    k = pk : pk = 0
    KeyIn k
  ElseIf wt = 0 Then
    ' a key for the front slot (left in the keyboard buffer while its program has one waiting)
    If front = 0 Or st(front) <> 2 Or kq(front) = 0 Then
      If hk <> 0 Or i = 0 Then                   ' (the front slot changed: its key asked for now)
        k = KOp(32, 0, 0, 0, 0)
        kc = Deek(KB + 18) : kh = Deek(KB + 20)
      End If
      If k = 32 And kc <> 0 And lang = 1 And front <> 0 Then     ' Control + Space, Russian: the layout
        rul = Not rul                                            ' (Latin / JCUKEN), R in the strip
        en = Left$("[" + N(front) + "]" + IIf(rul, "R", " ") + "   ", 4)
        ToSlot front, CSTRIP, VarPtr(en), 4
        k = 0
      End If
      If k <> 0 And (kc = 0 Or (k < 32 And kh = 0)) Then KeyIn k   ' (Control + a letter: the program's)
      If Len(tq) > 0 And k = 0 Then TypeLine       ' (lines waiting to be typed: AUTOEXEC's)
    End If
  ElseIf Running() = 0 Then
    Prompt wt : wt = 0          ' WAIT: nothing runs any more
  End If
  If ck - td >= 300 Then Roll
  If front <> 0 Then
    If ck - tc >= 150 Then                       ' the cursor flashes (0.5 s) - not for a slot with its
      tc = ck                                    ' own colours (the CPC's GUI: the screen is its picture)
      If host = 1 Then
        kr = KOp(8, front, 0, -3, 1)
      ElseIf RB(front, CINK) = 0 Then
        kr = KOp(8, front, 0, -3, 1)
      End If
    End If
  End If
  RunNext
Loop Until quit
kr = KOp(27, runs, 0, 0, 0)                       ' QUIT: C0 puts the screen back and ends
End

' ---- C0: the call, and the block's data

' KOp(op, p1, p2, p3, p4): op to C0 with its words; its answer (r0). ck: C0's clock
Function KOp(ByVal op As Integer, ByVal p1 As Integer, ByVal p2 As Integer, ByVal p3 As Integer, ByVal p4 As Integer) As Integer
#asm
            ld hl, ({op})
            ld ({KB}), hl
            ld hl, ({p1})
            ld ({KB} + 2), hl
            ld hl, ({p2})
            ld ({KB} + 4), hl
            ld hl, ({p3})
            ld ({KB} + 6), hl
            ld hl, ({p4})
            ld ({KB} + 8), hl
            ld ({ksp}), sp          ; (SP is the thread: the real stack for the call)
            ld sp, (ntc_csp)
            ld c, 132
            ld de, {KB}
            ei
            call 5
            di
            ld sp, ({ksp})
            ld hl, ({KB} + 30)
            ld ({ck}), hl
            ld hl, ({KB} + 16)
            ld ({result}), hl
#endasm
End Function

' KD p, n: n bytes from p into the block's data (224 at most)
Sub KD(ByVal p As Integer, ByVal n As Integer)
#asm
            ld hl, ({p})
            ld de, {KB} + 32
            ld bc, ({n})
            ld a, b
            or c
            jr z, kd_none
            ldir
kd_none:
#endasm
End Sub

' KS p, n: the block's first n bytes of data to p, a 0 after them (a string)
Sub KS(ByVal p As Integer, ByVal n As Integer)
#asm
            ld hl, {KB} + 32
            ld de, ({p})
            ld bc, ({n})
            ld a, b
            or c
            jr z, ks_none
            ldir
ks_none:
            xor a
            ld (de), a
#endasm
End Sub

' slot t's byte / word at a
Function RB(ByVal t As Integer, ByVal a As Integer) As Integer
  RB = KOp(1, t, a, 0, 0)
End Function
Sub WB(ByVal t As Integer, ByVal a As Integer, ByVal v As Integer)
  kr = KOp(2, t, a, v, 0)
End Sub
Function RW(ByVal t As Integer, ByVal a As Integer) As Integer
  RW = KOp(3, t, a, 0, 0)
End Function
Sub WW(ByVal t As Integer, ByVal a As Integer, ByVal v As Integer)
  kr = KOp(4, t, a, v, 0)
End Sub

' n bytes from p (here) to slot t's a
Sub ToSlot(ByVal t As Integer, ByVal a As Integer, ByVal p As Integer, ByVal n As Integer)
  KD p, n
  kr = KOp(5, t, a, n, 0)
End Sub

' slot t's n bytes at a to p here (a string: a 0 after them)
Sub FromSlot(ByVal t As Integer, ByVal a As Integer, ByVal p As Integer, ByVal n As Integer)
  kr = KOp(6, t, a, n, 0)
  KS p, n
End Sub

' slot t's state (C0's services see it too: a paused slot - 3 - is one with a program to them, 2)
Sub SetSt(ByVal t As Integer, ByVal v As Integer)
  st(t) = v
  kr = KOp(24, t, IIf(v = 3, 2, v), 0, 0)
End Sub

' the slot in front (0: TOP)
Sub SetFront(ByVal f As Integer)
  front = f
  kr = KOp(25, f, 0, 0, 0)
End Sub

' how many slots run a program
Function Running() As Integer
  Dim j As Integer
  For j = 1 To ns
    If st(j) = 2 Then Running = Running + 1
  Next
End Function

' a slot that can have the CPU: running, and not waiting for a key it hasn't got (a program that
' found no key waits until the clock moves on or a key comes)
Function Ready(ByVal t As Integer) As Integer
  Ready = 0
  If t < 1 Then Exit Function
  If st(t) <> 2 Then Exit Function
  If wk(t) = ck And kq(t) = 0 Then Exit Function
  If nz(t) > 0 Then                              ' (a nap: a tick off each time the clock has moved on)
    If wk(t) <> ck Then nz(t) = nz(t) - 1 : wk(t) = ck
    If nz(t) > 0 And kq(t) = 0 Then Exit Function
  End If
  Ready = -1
End Function

' the CPU to the next slot: the front one every other turn (half the time), the others in turn
Sub RunNext()
  Dim n As Integer, t As Integer, r As Integer, c As Integer, q As Integer, h As Integer
  fr = Not fr
  If fr Then
    If Ready(front) Then t = front
  End If
  If t = 0 Then
    For n = 1 To ns
      cur = cur + 1
      If cur > ns Then cur = 1
      If cur <> front Then
        If Ready(cur) Then t = cur : Exit For
      End If
    Next
  End If
  If t = 0 Then
    If Ready(front) Then t = front
  End If
  If t = 0 Then
    If Running() = 0 Then kr = KOp(23, 0, 0, 0, 0)   ' nothing to run: wait a frame (a program waiting
    Exit Sub                                       ' for a key looks again when the clock moves on)
  End If
  If host = 0 Then RunDirect t : Exit Sub         ' (the CPC: the kernel runs the slot itself)
  n = 0
  Do
    ' RUN: the slot runs, slice after slice (6 interrupts each, 1/50 s), up to TURNS - q slices,
    ' its BDOS calls that are C0's (the files, the DMA, the drive, the services, RAMDISC) answered
    ' there as they come - up to 32 - n of them; back here at a call that is the kernel's (r 1),
    ' with its slices used (0), or with a C0 answer that ends the turn (2; 3: a port's "not yet" -
    ' it sleeps a tick). Its characters are on its console when it comes back
    r = KOp(12, t, ra(t), kq(t), (TURNS - q) + 256 * (32 - n))
    kfn = Deek(KB + 18) : karg = Deek(KB + 20) : c = Deek(KB + 22)
    h = Deek(KB + 26) - Deek(KB + 28)                          ' (its runs, its slices: the calls C0 answered)
    tn(t) = tn(t) + Deek(KB + 26)
    If tn(t) < 0 Then tn(t) = 32767              ' (a vCPC: past 32767 a second - kept at the top, not wrapped)
    q = q + Deek(KB + 28)
    If r = 1 Then h = h - 1
    If h > 0 Then nb(t) = nb(t) + h : wk(t) = -1 : n = n + h
    If kq(t) <> 0 Then
      If Deek(KB + 24) = 0 Then kq(t) = 0               ' the program took its key
    End If
    If c > 0 Then nc(t) = nc(t) + c
    If r = 0 Then Exit Do                        ' its slices used up: the turn is over
    If r = 2 Then ra(t) = kfn : Exit Do          ' (C0's answer, for its next run)
    If r = 3 Then ra(t) = kfn : wk(t) = ck : Exit Do
    c = kfn
    Bdos t
    ' a file call (13-35, DMA 26 too), CyborgOS's own (131: the network, claims, memory) or
    ' characters shown (128: 128 collected): the same slot straight on, up to 32 calls a turn
    ' - the main loop's work (keys, the other slots) between each record made a copy crawl
    ' (an HTTP GET take 0.4 s, a screen of text 0.5 s)
    n = n + 1
    If c = 131 Or c = 128 Then c = 13
    If c < 13 Or c > 36 Or n >= 32 Or st(t) <> 2 Or wk(t) <> -1 Then Exit Do   ' (asleep: a port's wait)
  Loop
End Sub

' the CPC: slot t runs from here, its turn (TURNS slices: 6 interrupts each), its interrupts
' coming here (KRun counts them; at each frame C0's visit runs the firmware's interrupt handler) and
' its calls that are the kernel's (the route in its page zero: 0, #81, 131's ops 0-9) - the rest go
' to C0 and back to the slot without the kernel. Its characters (OBUF) shown by C0 (CONO) when it
' comes back with some
Sub RunDirect(ByVal t As Integer)
  Dim n As Integer, r As Integer, c As Integer, rl As Integer
  rl = TURNS * 6
  Do
    r = KRun(sgt(t), ra(t), ke(t), rl)
    rl = krn
    ke(t) = 0
    tn(t) = tn(t) + 1
    c = kcnt
    If c > 0 Then kr = KOp(35, t, c, 0, 0) : nc(t) = nc(t) + c : ke(t) = 1   ' (CONO; taken - E 1 next run)
    If kq(t) <> 0 Then
      If RB(t, KEY) = 0 Then kq(t) = 0           ' the program took its key
    End If
    If r = 0 Then Exit Do                        ' its turn used up
    c = kfn
    Bdos t
    n = n + 1
    If c = 131 Or c = 128 Then c = 13
    If c < 13 Or c > 36 Or n >= 32 Or st(t) <> 2 Or wk(t) <> -1 Then Exit Do   ' (asleep: a key's wait)
  Loop
End Sub

' KRun(setting, a, e, n): the slot at setting runs (a: its BDOS answer, A and HL; e 1: its OBUF's
' characters were taken) till a call of the kernel's (1: kfn, karg) or n interrupts (0); krn the
' interrupts left, kcnt its characters waiting (IX)
Function KRun(ByVal sg0 As Integer, ByVal ans As Integer, ByVal e As Integer, ByVal n As Integer) As Integer
#asm
            ld ({ksp}), sp          ; (the real stack)
            ld sp, (ntc_csp)
            di
            ld hl, ({n})
            ld ({krn}), hl
            ld a, ({e})
            ld ({kre}), a
kr_again:
            push ix
            push iy
            db #08                  ; ex af, af': the alternate registers kept
            exx
            push af
            push bc
            push de
            push hl
            exx
            db #08
            ld hl, kr_back
            push hl
            ld (#FFFE), sp          ; this bank's SP: its #0046 (sb_land) lands here
            ld a, ({kre})
            ld e, a                 ; E 1: its characters were taken
            ld a, ({ans})
            ld hl, ({ans})
            ld bc, ({sg0})
            jp #0044                ; out (c), c: the slot's bank
kr_back:
            ld ({kcnt}), ix         ; its characters (its stubs put them in IX)
            db #08
            exx
            pop hl
            pop de
            pop bc
            pop af
            exx
            db #08
            pop iy
            pop ix
            jr c, kr_far
            ld hl, ({ktk})          ; an interrupt in the slot: the tick (a frame: C0's visit)
            call kr_hl
            xor a
            ld ({kre}), a           ; (resumed: its characters stay)
            ld hl, ({krn})
            dec hl
            ld ({krn}), hl
            ld a, h
            or l
            jr nz, kr_again
            ld hl, 0
            jr kr_end
kr_hl:
            jp (hl)
kr_far:
            ld l, a                 ; a call: A = its function, DE its argument
            ld h, 0
            ld ({kfn}), hl
            ld ({karg}), de
            ld hl, 1
kr_end:
            ld ({result}), hl
            ld sp, ({ksp})
#endasm
End Function

' KInit: the CPC - the kernel's own interrupts (while its code runs) counted here (KIsr: #0038 of
' this bank), the tick routine KRun calls (ktk); at each frame (the sync, or 6 interrupts) C0's
' visit: the firmware's interrupt handler (the keys, the frame's events) and the clock made up for
' the interrupts it didn't see
Sub KInit()
#asm
            ld hl, ki_tick
            ld ({ktk}), hl
            ld hl, ki_isr
            ld (#0039), hl          ; #0038 jp ki_isr
            jr ki_done
ki_isr:
            push af                 ; own stack (the interrupt's: not the thread)
            push bc
            push de
            push hl
            call ki_tick
            pop hl
            pop de
            pop bc
            pop af
            ei
            ret
ki_tick:
            ld hl, ki_vn
            inc (hl)
            ld b, #F5               ; PPI port B bit 0: vertical sync
            in a, (c)
            and 1
            ld e, a
            ld a, (ki_vs)
            cpl
            and e
            ld d, a                 ; 1: the sync started since the last
            ld a, e
            ld (ki_vs), a
            ld a, (ki_ph)           ; a frame is 6 interrupts (the sync puts it back to 0: an
            inc a                   ; interrupt taken late still sees its frame)
            cp 6
            jr c, ki_ph1
            xor a
ki_ph1:
            bit 0, d
            jr z, ki_ph2
            xor a
ki_ph2:
            ld (ki_ph), a
            or a
            ret nz                  ; not a frame
            ld a, (ki_vn)           ; the frame: C0's visit, D = the interrupts since the last
            ld d, a
            xor a
            ld (ki_vn), a
            push ix
            push iy
            db #08
            exx
            push af
            push bc
            push de
            push hl
            exx
            db #08
            ld hl, ki_back
            push hl
            ld (#FFFE), sp
            ld hl, 0                ; (the kernel's)
            ld bc, #7FC0
            or a                    ; no carry: a visit
            jp #0044
ki_back:
            db #08
            exx
            pop hl
            pop de
            pop bc
            pop af
            exx
            db #08
            pop iy
            pop ix
            ret
ki_vn:      db 0
ki_vs:      db 0
ki_ph:      db 0
ki_done:
#endasm
End Sub

' a slot's BDOS call that C0 left for the kernel: kfn = C, karg = DE; the answer in ra(t). C0
' answers the files (13-36, 40), the drive (14, 24, 25), the DMA (26), 12, 128, RAMDISC (130) and
' BDOS 131's memory, store, claims, network and ports (10-15, 16-33: Hyp.Svc) itself
Sub Bdos(ByVal t As Integer)
  Dim f As Integer, a As Integer
  f = kfn : a = 0
  nb(t) = nb(t) + 1
  wk(t) = -1
  Select Case f
    Case 0
      EndTask t
      Exit Sub
    ' 1, 2, 6, 9, 10, 11: answered in the bank (Hyp's stubs), never here
    Case 131                      ' CyborgOS's own commands (PS, KILL, MEM ...)
      a = Sys(t, karg)
    Case 129                      ' the stub's key wait (BDOS 1, 10, BIOS CONIN): sleep till a key
      If kq(t) = 0 Then wk(t) = ck
    Case Else
      a = 255
  End Select
  ra(t) = a
End Sub

' BDOS 131: CyborgOS's own commands (PS.CYB, KILL.CYB, MEM.CYB ...: CybSys.cls): DE = a block -
' op, a slot or value, then what comes back. 0 slot's line (state, in front, its program's name),
' 1 kill, 2 reset (slot 0: this one), 3 to the front, 4 wait until no other program runs, 5 paused
' (Byte(2) 1) / going on (0) / its state (2: 0 closed, 1 command line, 2 running, 3 paused) / DUMP's
' state (3: 12 bytes at Word(4)) / REVIVE begins (4: a closed slot made a paused one) / done (5) / RUN
' in it (6: the name at Word(4) - SLOTD), 6 TOP's
' table into this slot, 7 the memory (the tables' end, the top, the pages, the totals line), 8 32
' pages of the map from page Word(2), 9 MODE (0-5 set, 255 which), 12 the slot's store (K); 10, 11,
' 13, 14, 15 (memory, the pointer, the store's blocks, tables), 16-19 (the claims: claim, release,
' take, held), 20-27 (the network), 28-33 (the ports): Hyp.Svc, in the service page. 0 done, 1
' nothing to do, 255 no such slot / page
Function Sys(ByVal t As Integer, ByVal p As Integer) As Integer
  Dim o As Integer, s As Integer, q As Integer, d1 As Integer, d2 As Integer, d3 As Integer
  o = RW(t, p) : s = ((o And &HFF00) \ 256) And 255 : o = o And 255   ' (the op, the slot or value: one word -
                                                 ' And first: #8000 on is negative)
  If o = 4 Then
    If Running() > 1 Then wt = t
    Exit Function
  ElseIf o = 6 Then                               ' TOP once: Word(2) 1 every slot (TOP FULL), else the open ones
    txs = t
    TopLines front, 0, RB(t, p + 2)
    Exit Function
  ElseIf o = 9 Then                               ' MODE: s 0-4 this slot's mode (its console
    If s = 255 Then Sys = RB(t, CMODE) : Exit Function   ' cleared), 255: which it is
    If s > 5 Then Sys = 255 : Exit Function
    SetMode t, s
    Exit Function
  ElseIf o >= 48 And o < 64 Then                 ' the lists (ListOp, below)
    Sys = ListOp(t, p, o)
    Exit Function
  ElseIf o = 10 Or o = 11 Or o >= 13 Then         ' memory, the pointer, the store's blocks, tables,
    Sys = KOp(16, t, p, 0, 0)                      ' the claims (16-19), the network, the ports
    If Sys = 1 And o >= 30 Then wk(t) = ck       ' (28-33): in the service page. A port's "not yet":
    Exit Function                                ' the slot sleeps a tick, as for a key
  ElseIf o = 12 Then                              ' the slot's store: Word(2) K (16K pages, 512K at most)
    Sys = KOp(18, t, RW(t, p + 2), 0, 0)
    Exit Function
  ElseIf o = 7 Then
    WB t, p + 1, host                            ' the host, for MEM's map of main RAM: 0 the CPC, 1 the Next
    kr = KOp(20, 0, 0, 0, 0)                       ' (MEMINFO: C0's main RAM, its pages)
    WW t, p + 2, kr
    WW t, p + 4, Deek(KB + 18)
    WW t, p + 6, Deek(KB + 20)
    Totals
    PutEn t, p + 8
    WW t, p + 60, IIf(host = 0, Deek(KB + 26), 0)  ' (the CPC: pages left unmapped - MEMINFO's r5, Totals')
    Exit Function
  ElseIf o = 8 Then
    kr = KOp(21, RW(t, p + 2), 0, 0, 0)
    KS VarPtr(en), kr
    PutEn t, p + 4
    Exit Function
  End If
  If o = 2 And s = 0 Then s = t
  Sys = 255
  If s < 1 Or s > ns Then Exit Function
  Sys = 0
  If o = 0 Then
    WW t, p + 2, st(s) + IIf(s = front, 256, 0)
    en = ""
    If st(s) >= 2 Then GetNm s
    PutEn t, p + 4
  ElseIf o = 1 Then
    If st(s) >= 2 Then EndTask s Else Sys = 1
  ElseIf o = 2 Then
    ResetSlot s
    If s = t Then Prompt t                       ' (RESET of its own slot: the program gone)
  ElseIf o = 3 Then
    ToFront s
  ElseIf o = 5 Then                               ' PAUSE / UNPAUSE: Byte(2) 1 paused (the scheduler
    o = RB(t, p + 2)                              ' passes it over, everything it had kept - its BDOS
    If o = 2 Then                                 ' answer, its key - kept), 0 going on, 2 its state
      Sys = st(s)
    ElseIf o = 1 And st(s) = 2 And s <> t Then
      SetSt s, 3
    ElseIf o = 0 And st(s) = 3 Then
      SetSt s, 2
      wk(s) = -1
    ElseIf o = 3 Then                             ' DUMP: its state into 12 bytes at the caller's Word(4) -
      q = RW(t, p + 4)                            ' +0 st, +1 kq, +2 ra, +4 its drive, +5 a file open (1),
      kr = KOp(37, s, 0, 0, 0)                    ' +6 its DMA, +8 the build's stamp (C0's SLOT)
      d1 = Deek(KB + 16) : d2 = Deek(KB + 18) : d3 = Deek(KB + 20)
      WB t, q, st(s) : WB t, q + 1, kq(s) : WW t, q + 2, ra(s)
      WB t, q + 4, KOp(28, s, 0, 0, 0) : WB t, q + 5, IIf(d2 <> 0, 1, 0)
      WW t, q + 6, d1 : WW t, q + 8, d3 : WW t, q + 10, 0
    ElseIf o = 4 And st(s) < 2 And s <> t Then    ' REVIVE begins: a closed slot (or its command line)
      FilesShut s                                 ' made one with a program, paused, whose bank the
      kr = KOp(37, s, 3, 0, 0)                    ' caller then writes (its own words kept first)
      SetSt s, 3
      kq(s) = 0 : wk(s) = -1 : ra(s) = 0
    ElseIf o = 5 And st(s) = 3 Then               ' REVIVE done: its bank its own again, the state from
      q = RW(t, p + 4)                            ' the 12 bytes at Word(4) (DUMP's) - it stays paused
      kr = KOp(37, s, 2, 0, 0)
      kr = KOp(37, s, 1, RW(t, q + 6), 0)
      kr = KOp(29, s, RB(t, q + 4), 0, 0)
      kq(s) = RB(t, q + 1) : ra(s) = RW(t, q + 2) : wk(s) = -1
      nm(s) = ""                                  ' its program's name, from its bank (the dump's)
      For d1 = 1 To RB(s, NMLEN)
        If d1 <= 12 Then nm(s) = nm(s) + Chr$(RB(s, NMLEN + d1))
      Next
      If s = front Then ToFront s
    ElseIf o = 6 And st(s) < 2 And s <> t Then    ' RUN in slot s (SLOTD's: a program sent to it): the
      q = RW(t, p + 4)                            ' name at the caller's Word(4) (its length, then it),
      a = ""                                      ' looked for as RUN looks (Z, the caller's drive, C/,
      For d1 = 1 To RB(t, q)                      ' the boot drive); not found: 1
        If d1 <= 60 Then a = a + Chr$(RB(t, q + d1))
      Next
      b = "" : bare = 0
      StartTask t, s
      If st(s) < 2 Then Sys = 1
    ElseIf o = 8 And s = t Then                   ' a nap: this slot sleeps Byte(3) ticks (1 at least:
      wk(t) = ck                                  ' TASKMAN between its looks at the keys); a key ends it
      nz(t) = RB(t, p + 3)
    ElseIf o = 10 Then                            ' Type: Byte(3) bytes at Word(4) typed into slot s's command
      kr = RB(t, p + 4) + RB(t, p + 5) * 256     ' line, a line a prompt (lines end with 13; AUTOEXEC's)
      For i = 1 To RB(t, p + 3)
        If Len(tq) < 250 Then tq = tq + Chr$(RB(t, kr + i - 1))
      Next
      tqs = s
      Sys = 0
    ElseIf o = 9 Then                             ' LANG: Byte(3) 255 the language (0 English, 1 Russian,
      If RB(t, p + 3) <> 255 Then                 ' 2 Spanish), else set - and C0 told (LANG l: the vCPC's
        lang = RB(t, p + 3)                       ' terminal shows it, the machines' fonts follow it)
        kr = KOp(38, lang, 0, 0, 0)
      End If
      Sys = lang
    ElseIf o = 7 Then                             ' TASKMAN: its last second's turns, BDOS calls and
      q = RW(t, p + 4)                            ' characters (TOP's figures) - 3 words at Word(4)
      WW t, q, Rate(lt(s), ld) : WW t, q + 2, Rate(lb(s), ld) : WW t, q + 4, Rate(lc(s), ld)
    Else
      Sys = 1                                     ' (nothing to do: not running, not paused, itself)
    End If
  End If
End Function

' en into slot t at address a: its length, then its characters
Sub PutEn(ByVal t As Integer, ByVal a As Integer)
  If Len(en) > 51 Then en = Left$(en, 51)        ' (CybSys's block is 64 bytes, the text at 4 or 8 in it, op 7's
                                                 ' word at 60: no longer)
  ob = Chr$(Len(en)) + en                        ' (empty: Chr$(0) - the 0 is the length)
  ToSlot t, a, VarPtr(ob), Len(en) + 1
End Sub

' the hypervisor's own reading (FILE 100, 102): open file dn (True / False), close
Function HOpen() As Integer
  KD VarPtr(dn), Len(dn)
  HOpen = (KOp(13, 100, Len(dn), 0, 0) = 0)
  KS VarPtr(dn), Len(dn)                          ' (NAME.CYB not there, NAME.COM: its name back)
End Function
Sub HClose()
  kr = KOp(13, 102, 0, 0, 0)
End Sub

' a slot's files closed, its claims freed (its program ended, was killed or reset)
Sub FilesShut(ByVal t As Integer)
  kr = KOp(15, t, 0, 0, 0)
End Sub

' the slot's store given back (its program ended)
Sub StoreFree(ByVal t As Integer)
  kr = KOp(18, t, 0, 0, 0)
End Sub

' ---- the slots' consoles: each slot's 80 x 25 page is in its bank (#F700, a ring of 25 rows),
' with its column, row, top row and escape state (#F682); the slot in front is on the screen
' too. All of it is C0's Hyp.Con, in Z80

' a string to slot t's console (the command line, messages)
Sub PutS(ByVal t As Integer, ByVal s As String)
  KD VarPtr(s), Len(s)
  kr = KOp(7, t, Len(s), IIf(t = front, 1, 0), 0)
End Sub

Sub PutLn(ByVal t As Integer, ByVal s As String)
  PutS t, s + Chr$(13) + Chr$(10)
End Sub

' one character (or control code) to slot t's console
Sub PutC(ByVal t As Integer, ByVal c As Integer)
  KD VarPtr(c), 1                                ' (the Integer's low byte is the character)
  kr = KOp(7, t, 1, IIf(t = front, 1, 0), 0)
End Sub

' slot t's page cleared (ESC E: Hyp.Con clears the page, its state, and the screen if in front)
Sub ClsT(ByVal t As Integer)
  PutS t, Chr$(27) + "E"
End Sub

' slot t to the front: its page drawn
Sub ToFront(ByVal t As Integer)
  Dim r As Integer
  SetFront t
  If st(t) = 0 Then OpenSlot t : Exit Sub
  r = KOp(9, RB(t, CMODE), 2, 0, 0)                ' the screen in its mode (cleared)
  kr = KOp(8, t, 0, -1, 1)                         ' (Show: its whole page on the screen)
  Inks t                                         ' (its own colours, if it set any: GUI's greens)
End Sub

' Inks t: the CPC's inks for slot t in front (its CINK bytes; 0: the console's own - TOP's)
Sub Inks(ByVal t As Integer)
  If host = 1 Then Exit Sub                      ' (the Next: none)
  If t = 0 Then kr = KOp(10, 0, 0, 0, 0) : Exit Sub
  kr = KOp(10, RB(t, CINK), RB(t, CINK + 1), RB(t, CINK + 2), 0)
End Sub

' slot t's MODE m (Hyp.Scr: 0 2, 1 S, 2 W, 3 UW, 4 P): its console's columns and rows in its bank
' (Hyp.Con and the bank's BDOS 49 go by them), the status strip's text ([slot]), the screen if
' it is in front; its page cleared
Sub SetMode(ByVal t As Integer, ByVal m As Integer)
  Dim r As Integer
  WB t, CCOLS, KOp(9, m, 0, 0, 0)
  WB t, CROWS, KOp(9, m, 1, 0, 0)
  WB t, CMODE, m
  en = Left$("[" + N(t) + "]   ", 4)
  ToSlot t, CSTRIP, VarPtr(en), 4
  If t = front Then r = KOp(9, m, 2, 0, 0)
  If t = front Then Inks t
  ClsT t
End Sub

' ---- TOP: every slot, its program and what it did in the last second (Control + ESC, TOP)

Sub ShowTop()
  Dim j As Integer
  If front <> 0 Then back = front
  SetFront 0
  j = KOp(9, 0, 2, 0, 0)            ' TOP in MODE 2 (80 x 25), the screen cleared
  Inks 0                          ' (the console's colours)
  txs = 0
  TopLines back, 1, 1
End Sub

' the TOP lines, to the screen (txs = 0) or slot txs's console: the slot marked with * is mark;
' keys <> 0: the line with the keys
Sub TopLines(ByVal mark As Integer, ByVal keys As Integer, ByVal full As Integer)
  Dim j As Integer, s As String Max 14                          ' (full 0: the slots not open left out - TOP typed)
  txn = 0
  TopAdd "CyborgOS TOP"
  If keys Then TopAdd TK() + ": back, " + SK() + ": that slot" Else TopAdd ""   ' (25 rows: 20 slots)
  If host = 1 Then
    TopAdd "SLOT  STATE          PROGRAM         TURNS/S   BDOS/S  CHARS/S"
  Else
    TopAdd "SLOT  STATE          PROGRAM         TURNS/S   BDOS/S  CHARS/S   (last second)"
  End If
  For j = 1 To ns
    If st(j) = 0 And full = 0 Then
      s = ""
    ElseIf st(j) = 0 Then
      s = "-"
    ElseIf st(j) = 1 Then
      s = "command line"
    ElseIf st(j) = 3 Then
      s = "paused"
    ElseIf wk(j) >= 0 Then
      s = "waiting (key)"
    Else
      s = "running"
    End If
    en = ""
    If st(j) >= 2 Then GetNm j
    If s <> "" Then TopAdd " " + Right$(" " + N(j), 2) + IIf(j = mark, "*", " ") + "  " + Left$(s + Space$(15), 15) + Left$(en + Space$(13), 13) + Pad(Rate(lt(j), ld)) + Pad(Rate(lb(j), ld)) + Pad(Rate(lc(j), ld))
  Next
  TopAdd ""
  Totals
  TopAdd en
End Sub

' en = "Total memory: n KB   Free memory: n KB" (free: the 16K pages no slot or anything has)
Sub Totals()
  kr = KOp(20, 0, 0, 0, 0)
  en = "Total memory: " + N(Deek(KB + 22)) + " KB   Free memory: " + N(Deek(KB + 24) * 16) + " KB"
End Sub

Sub TopAdd(ByVal s As String)
  If txs = 0 Then
    KD VarPtr(s), Len(s)                         ' straight into screen memory (C0's Hyp.Say)
    kr = KOp(11, Len(s), 0, txn, 0)
  Else
    PutLn txs, s
  End If
  txn = txn + 1
End Sub

' each second: this second's counts become the last second's (TOP shows those, once)
Sub Roll()
  Dim j As Integer
  ld = ck - td
  td = ck
  For j = 1 To ns
    If host = 0 Then                             ' (the CPC: the calls and characters C0 answered
      kr = KOp(34, j, 0, 0, 0)                   ' itself, the slot straight on - STATS)
      nb(j) = nb(j) + kr : nc(j) = nc(j) + Deek(KB + 18)
    End If
    If tn(j) < 0 Then tn(j) = 32767              ' (past 32767 in a second: kept at the top, not wrapped)
    If nb(j) < 0 Then nb(j) = 32767
    If nc(j) < 0 Then nc(j) = 32767
    lt(j) = tn(j) : lb(j) = nb(j) : lc(j) = nc(j)
    tn(j) = 0 : nb(j) = 0 : nc(j) = 0
  Next
End Sub

' n right aligned in 9 columns
Function Pad(ByVal v As Integer) As String
  Pad = Right$(Space$(9) + N(v), 9)
End Function

' a count over d ticks (300 a second) as a count a second
Function Rate(ByVal n As Integer, ByVal d As Integer) As Integer
  If n > 1000 Then Rate = n \ (d \ 300 + 1) Else Rate = n * 30 \ (d \ 10 + 1)
End Function

' ---- slots

' RESET: the slot as before its command line was first opened - its program (if any) stopped,
' nothing kept. The slot in front (the one typing it) opens again at once, as new
Sub ResetSlot(ByVal s As Integer)
  FilesShut s
  If st(s) >= 2 Then StoreFree s
  ListsFree s
  SetSt s, 0
  kr = KOp(29, s, 0, 0, 0)                          ' (its drive: none)
  kq(s) = 0
  wk(s) = -1
  tn(s) = 0 : nb(s) = 0 : nc(s) = 0
  lt(s) = 0 : lb(s) = 0 : lc(s) = 0
  If s = front Then
    kr = KOp(19, s, 0, 0, 0)                        ' (INSTALL: the bank image in)
    kq(s) = 0
    SetSt s, 1
    SetMode s, 1
    PutLn s, "CyborgOS slot " + N(s) + " of " + N(ns) + " - " + SLK()
    PutLn s, ""                   ' a blank line under the title
  End If                          ' (the prompt: the command line puts it after the command)
End Sub

Sub OpenSlot(ByVal t As Integer)
  kr = KOp(19, t, 0, 0, 0)
  kq(t) = 0
  SetSt t, 1
  SetMode t, 1                    ' MODE S: 80 x 24 and the status strip
  PutLn t, "CyborgOS slot " + N(t) + " of " + N(ns) + " - " + SLK()
  PutLn t, ""                     ' a blank line under the title
  Prompt t
End Sub

' the keys for the slots, as the help lines say them (the Next: the keys on TOP - Caps Shift + 0
' is TOP, then the slot's key)
Function SK() As String
  If host = 1 Then
    SK = "1-" + N(IIf(ns < 9, ns, 9))
    If ns > 9 Then SK = SK + ", 0"
    If ns > 10 Then SK = SK + ", A-" + Chr$(54 + ns)
  ElseIf ns <= 9 Then
    SK = "Control + 1-" + N(ns)
  ElseIf ns = 10 Then
    SK = "Control + 1-9, 0"
  ElseIf ns = 11 Then
    SK = "Control + 1-9, 0 (twice 11)"
  Else
    SK = "Control + 1-9, 0 (twice 11-" + N(ns) + ")"
  End If
End Function

' the slot line's keys (the Next: TOP, then the slot's key there)
Function SLK() As String
  If host = 1 Then
    SLK = TK() + " TOP (then " + SK() + "), HELP"
  Else
    SLK = SK() + ", " + TK() + " TOP, HELP"
  End If
End Function

' the TOP key, as the help lines say it
Function TK() As String
  If host = 1 Then TK = "Shift + 0" Else TK = "Control + ESC"
End Function

' en = the name of the program slot t runs (from its bank)
Sub GetNm(ByVal t As Integer)
  en = nm(t)
End Sub

' a number without the space Str$ puts before it
Function N(ByVal v As Integer) As String
  N = Trim$(Str$(v))
End Function

Sub Prompt(ByVal t As Integer)
  ln(t) = ""                                     ' an empty command line
  PutS t, N(t) + "> "
End Sub

' a key typed: to the program in front, or its command line (none while TOP shows)
Sub KeyIn(ByVal k As Integer)
  Dim t As Integer, n As Integer
  If rul And lang = 1 And k >= 32 And k < 127 Then  ' the Russian layout: a Latin key's letter
    n = InStr(kl, Chr$(k))
    If n > 0 Then k = 256 + Asc(Mid$(kr8, n, 1))
  End If
  If front = 0 Then
    If host = 1 Then                             ' the Next: on TOP, a slot's key (0: 10, A-J: 11-20)
      t = InStr("1234567890abcdefghij", LCase$(Chr$(k)))
      If t > 0 And t <= ns Then ToFront t
    End If
    Exit Sub                      ' TOP stays until Control + ESC or Control + a slot
  End If
  t = front
#If SCROLLBACK Then
  If k = &HF4 Or k = &HF5 Then kr = KOp(8, t, k, -2, 1) : Exit Sub   ' Shift + Up / Down: the scrollback
#End If
  If st(t) >= 2 Then                              ' (a paused one in front: its key kept for when it goes on)
    If k = &HFC Then k = 27                       ' (ESC: the firmware's #FC - CP/M's #1B, as Amstrad's CP/M)
    k = k And 255                                 ' (a character 128-255: 256 + it here - the byte for the program)
    kq(t) = k                                     ' the key into its bank: its BDOS answers from it
    WB t, KEY, k
    Exit Sub
  End If
  n = Len(ln(t))                                 ' the command line so far
  If k = 13 Then
    ob = Chr$(n) + ln(t)                         ' into the slot's bank (LNLEN, then LNBUF): CybSys.Tail
    ToSlot t, LNLEN, VarPtr(ob), n + 1           ' reads it there while the program runs
    PutLn t, ""
    Command t
    If st(t) = 1 And wt = 0 And front = t Then Prompt t
  ElseIf k = 127 Or k = 8 Then
    If n > 0 Then
      ln(t) = Left$(ln(t), n - 1)
      PutS t, Chr$(8) + " " + Chr$(8)
    End If
  ElseIf ((k >= 32 And k < 127) Or (k >= 384 And k <= 511)) And n < lnmax Then   ' (384-511: a character
    ln(t) = ln(t) + Chr$(k And 255)                                              ' 128-255 - the language's)
    PutC t, k And 255
  End If
End Sub

Sub Command(ByVal t As Integer)
  Dim c As String Max 72, p As Integer, s As Integer
  c = UpLang(UCase$(Trim$(ln(t))))               ' the command line (upper case: the language's letters too)
  a = "" : b = ""
  p = InStr(c, " ")
  If p > 0 Then
    a = Trim$(Mid$(c, p + 1))
    c = Left$(c, p - 1)
  End If
  p = InStr(a, " ")
  If p > 0 Then
    b = Trim$(Mid$(a, p + 1))
    a = Left$(a, p - 1)
  End If
  If Right$(c, 1) = ":" And a = "" Then a = c : c = "CV"   ' B: or IDE: alone: CV B:, CV IDE: (CV.CYB)
  Select Case c
    Case ""
    Case "CLS"
      ClsT t
    Case "RUN"                                 ' RUN [slot] name [tail]: the program on the disc even
      s = t                                    ' when a command has its name; with a slot: in that one
      If a <> "" And N(Val(a)) = a Then
        s = Val(a) : a = b : b = ""
        p = InStr(a, " ")
        If p > 0 Then b = Trim$(Mid$(a, p + 1)) : a = Left$(a, p - 1)
      End If
      If s < 1 Or s > ns Then PutLn t, "no slot" + Str$(s) : Exit Sub
      If st(s) >= 2 Then PutLn t, "slot" + Str$(s) + " is busy" : Exit Sub
      StartTask t, s
    Case "QUIT"
      quit = -1
    Case Else                                  ' the rest are programs (the system drive Z's, else
      b = Trim$(a + " " + b)                   ' the slot's drive, else A): PS, MEM, CD, DIR ... and
      a = c                                    ' any other, the rest of the line their tail
      bare = -1
      StartTask t, t
      bare = 0
  End Select
End Sub

' RUN a: a program loaded into slot s's bank at #0100 (from slot t's command line) and started.
'   name.CYB   a cpm build with an AMSDOS header (the header gives its length)
'   name.COM   a CP/M program with no header: read to its end (UniDOS, a RAM disc know it)
'   name       name.CYB, else name.COM
' UpLang(s): s with the language's letters in upper case too (UCase$ does ASCII only): Russian
' KOI8-R's small letters are #C0-#DF, the capitals #E0-#FF (+32); Latin-1's small letters #E0-#FE
' but #F7 (a sign), the capitals 32 lower (English and Spanish: Latin-1)
Function UpLang(ByVal s As String) As String
  Dim i As Integer, c As Integer
  For i = 1 To Len(s)
    c = Asc(Mid$(s, i, 1))
    If lang = 1 Then
      If c >= 192 And c <= 223 Then Mid$(s, i, 1) = Chr$(c + 32)
    Else
      If c >= 224 And c <= 254 And c <> 247 Then Mid$(s, i, 1) = Chr$(c - 32)
    End If
  Next
  UpLang = s
End Function

' TypeLine: the next line waiting (tq) into its slot's command line - when that slot is in front, on
' its command line, nothing typed yet: the characters, then 13 (the command runs; the next line
' waits for the prompt again)
Sub TypeLine()
  Dim i As Integer, n As Integer
  If tqs = front And st(tqs) = 1 And Len(ln(tqs)) = 0 Then
    n = InStr(tq, Chr$(13))
    If n = 0 Then n = Len(tq) + 1
    For i = 1 To n - 1
      KeyIn Asc(Mid$(tq, i, 1))
    Next
    tq = Mid$(tq, n + 1)
    KeyIn 13
  End If
End Sub

' StartAuto: AUTOEXEC run in slot 1 (AUTOEXEC.CYB: the boot drive's AUTOEXEC file's lines typed, one a
' prompt - op 5 sub 10); nothing said when there's no such command
Sub StartAuto()
  ax = 0
  a = "AUTOEXEC" : b = "" : qt = 1
  StartTask 1, 1
  qa = (qt <> 0)                                  ' (it started - qt still set: its end kept quiet too)
  qt = 0
End Sub

Sub StartTask(ByVal t As Integer, ByVal s As Integer)
  Dim h As Integer, n As Integer, rest As Integer, com As Integer, w As String Max 72, d As Integer, a0 As String Max 72
  If a = "" Then PutLn t, "RUN what?" : Exit Sub
  a0 = a
  d = -1                                         ' where it is looked for: Z (-1: the commands loaded as
  If host = 1 And nosysz <> 0 Then d = 0         ' if built in), the slot's own drive (0), the commands'
  Do                                             ' folder C/ on the boot drive (1: CYBORGOS/C/ - all of
    If d = -1 Then                               ' them), then the boot drive itself (2: its apps)
      If KOp(14, 90, 0, 0, 0) = 0 Then d = 0     ' (no Z)
    End If
    If d = 0 Then OwnDrive t
    If d >= 1 Then n = KOp(14, bd, 0, 0, 0)
    w = a0
    If d = 1 Then
      If InStr(a0, "/") Or InStr(a0, ":") Then d = 2 Else w = "C/" + a0   ' (a name with a path: as given)
    End If
    a = w : h = 0 : com = 0
    If InStr(a, ".") = 0 Then
      dn = a + ".CYB"
      h = HOpen()
      If h Then a = dn Else com = -1
    ElseIf Right$(a, 4) = ".COM" Then
      com = -1
    Else
      dn = a
      h = HOpen()
    End If
    rest = &HEE00                                ' #0100 to the stub (#EF00)
    If com Then dn = a : h = HOpen()             ' (a .COM: UniDOS, a RAM disc read it to its end)
    If h Then Exit Do
    If d = 2 Or (d = 1 And KOp(28, t, 0, 0, 0) = bd) Then Exit Do   ' (the boot drive: once - the slot's may be it)
    d = d + 1
  Loop
  If d = 1 And h <> 0 Then a = Mid$(a, 3)        ' (its name without the folder: PS, TOP show PS.CYB)
  If h = 0 Then
    a = a0
    OwnDrive t
    If qt = 0 Then NotFound t                    ' (a quiet start - AUTOEXEC - says nothing)
    qt = 0
    Exit Sub
  End If
  If st(s) = 0 Then OpenSlot s
  If s <> t Then PutLn s, "RUN " + a
  kr = KOp(19, s, 0, 0, 0)                         ' (INSTALL)
  kq(s) = 0
  n = KOp(13, 103, rest, s, &H100)                 ' at #0100, rest bytes at most
  HClose
  If d <> 0 Then OwnDrive t                      ' (loaded from Z or A: the slot's drive again)
  ' its first stack: ret to the stub's start (the default FCBs from the tail, then #0100), under
  ' it #0000 (a ret from the program ends it) - LAUNCH. Then the command tail at #0080 as CP/M
  ' has it: its length, a space, the text in capitals, a 0
  kr = KOp(30, s, 0, 0, 0)
  If b <> "" Then b = " " + b
  ob = Chr$(Len(b)) + b                          ' (with a tail: its 0 after it too - ob's own end)
  ToSlot s, &H80, VarPtr(ob), Len(b) + IIf(b = "", 1, 2)
  nm(s) = a                                      ' its name (here, and in its bank: NMLEN, NMBUF)
  ob = Chr$(Len(a)) + a
  ToSlot s, NMLEN, VarPtr(ob), Len(a) + 1
  kq(s) = 0
  wk(s) = -1
  SetSt s, 2
  If s <> t Then kr = KOp(29, s, KOp(28, t, 0, 0, 0), 0, 0)   ' RUN 2 MODEL PET from C:RATBOXN: slot 2 starts on
  If s <> t Then PutLn t, a + " runs in slot" + Str$(s)  ' that drive (its files are there), not the boot drive
End Sub

Sub NotFound(ByVal t As Integer)
  If bare Then PutLn t, "? " + a + " (HELP)" Else PutLn t, a + ": not found"
End Sub

' the slot's own drive (CD) selected, as CP/M has one each (the boot drive to start with)
Sub OwnDrive(ByVal t As Integer)
  kr = KOp(31, t, 0, 0, 0)
End Sub

Sub EndTask(ByVal t As Integer)
  Dim c As Integer
  FilesShut t
  StoreFree t
  ListsFree t
  SetSt t, 1
  runs = runs + 1
  If host = 0 Then
    WW t, CINK, 0                                ' its own colours gone with it
    WB t, CINK + 2, 0
    If t = front Then Inks t
  End If
  GetNm t
  If qa And en = "AUTOEXEC.CYB" Then             ' (the boot's AUTOEXEC: nothing said, the prompt as it is)
    qa = 0
  Else
    PutLn t, ""
    PutLn t, "[" + en + " ended]"
    If wt <> t Then Prompt t                     ' (WAIT: the prompt when nothing runs)
  End If
  If t = 1 And ax Then StartAuto                 ' (after the boot's RAMDISC: AUTOEXEC)
  c = kq(t) : kq(t) = 0
  If c <> 0 And t = front Then pk = c    ' a key typed for it after its last look: the command line's
End Sub

' ---- the lists (docs/cyborgos-slot-lists.md): every slot's lists and the hypervisor's own in one
' heap of 16K pages C0 hands out (KOp 43), nodes cut from them, reached only through C0's far copy
' (KOp 44 / 45). The kernel keeps the records: the system list (list 0) is a list like the others
' whose nodes are the records of every list in existence (its owner, node size, count, ends, map
' page, numbers); a list's node map (a page: number -> page, offset, 4 bytes each, 4095 nodes a
' list) is what a node handle indexes. A handle is a number, never a place: a dump and a revive
' make the lists again under the same numbers. A slot's node bytes count against its quota (the
' free pool at the first list divided among the slots); "no room" at the quota.
'   BDOS 131 ops 48-63 (COSList.cls on the slot's side; the block: byte 0 the op, words from 2:
'   2 the list, 4 a node / the answer, 6 an offset, 8 a value / a count, 10 a slot address):
'   48 CREATE size -> list (Word 2)     49 DESTROY h          50 APPEND h -> node (Word 4)
'   51 PREPEND h -> node                52 INSERTAFTER h n -> node    53 DELETE h n
'   54 FIRST h / 55 LAST h -> node      56 NEXT h n / 57 PREV h n -> node (0 none)
'   58 COUNT h -> Word 4                59 READ h n o k a: k bytes of the node's data from o to a
'   60 WRITE h n o k a: the other way   61 SEARCH h o v -> node (the word at o = v)
'   62 SORT h o (by the word at o)      63 INFO h -> Word 4 node size, Word 6 count
'   A 0 done, 1 no room, 255 no such list / node (or not this slot's)
Const LPMAX = 255                  ' the heap's pages (the 4 MB's 256 - the machine's bound, not a list's)
Const LREC = 16                    ' a record's bytes
Dim lpg(LPMAX) As Integer          ' C0's page numbers (0 unused)
Dim lps(LPMAX) As Integer          ' the node bytes a page serves (data + 4; -1 a map page)
Dim lpf(LPMAX) As Integer          ' the page's free chain head (an offset; 0 none)
Dim lpu(LPMAX) As Integer          ' nodes in use in it
Dim lpb(LPMAX) As Integer          ' its bump: the first offset never cut
Dim lsf As Integer, lsl As Integer, lsc As Integer, lsm As Integer, lsn As Integer, lsr As Integer   ' list 0: first, last, count, map page, next number, free number
Dim xlh As Integer                 ' the list in hand (0 none, -1 list 0) and its record:
Dim xlo As Integer, xlz As Integer, xlc As Integer, xlf As Integer, xll As Integer, xlm As Integer, xln As Integer, xlr As Integer
Dim xlb(31) As Byte                ' scratch for far copies (links, records, map entries)
Dim xlq(MAXS) As Long              ' bytes each slot's nodes take
Dim lquota As Long                 ' bytes a slot may have (0: not set yet)

' page pg at o to the kernel's a (n bytes), and back
Sub PRd(ByVal pg As Integer, ByVal o As Integer, ByVal a As Integer, ByVal n As Integer)
  kr = KOp(44, n * 32, pg, o, a)
End Sub
Sub PWr(ByVal pg As Integer, ByVal o As Integer, ByVal a As Integer, ByVal n As Integer)
  kr = KOp(45, n * 32, pg, o, a)
End Sub
Function PRdW(ByVal pg As Integer, ByVal o As Integer) As Integer
  PRd pg, o, VarPtr(xlb(0)), 2
  PRdW = xlb(0) + xlb(1) * 256
End Function
Sub PWrW(ByVal pg As Integer, ByVal o As Integer, ByVal v As Integer)
  xlb(0) = v And 255 : xlb(1) = ((v And &HFF00) \ 256) And 255
  PWr pg, o, VarPtr(xlb(0)), 2
End Sub

' a page for the heap serving node size z (-1: a map page), from the table or new from C0; -1 none
Function LPage(ByVal z As Integer) As Integer
  Dim i As Integer, e As Integer
  e = -1
  For i = 0 To LPMAX
    If lpg(i) = 0 Then
      If e < 0 Then e = i
    ElseIf lps(i) = z And z > 0 Then
      If lpf(i) <> 0 Or lpb(i) + z <= 16384 Then LPage = i : Exit Function
    End If
  Next
  If e < 0 Then LPage = -1 : Exit Function
  i = KOp(43, 0, 0, 0, 0)
  If i = 0 Then LPage = -1 : Exit Function
  lpg(e) = i : lps(e) = z : lpf(e) = 0 : lpu(e) = 0 : lpb(e) = 0
  LPage = e
End Function

' a page of the table given back to C0
Sub LPageFree(ByVal i As Integer)
  kr = KOp(43, 0, lpg(i), 0, 0)
  lpg(i) = 0 : lps(i) = 0 : lpf(i) = 0 : lpu(i) = 0 : lpb(i) = 0
End Sub

' a node of z bytes cut from the heap: its table page in r1, its offset back (0 none)
Dim r1 As Integer, r2 As Integer, r3 As Integer   ' (LCut's page, LPlace's page and offset)
Function LCut(ByVal z As Integer) As Integer
  Dim i As Integer, o As Integer
  i = LPage(z)
  If i < 0 Then LCut = 0 : Exit Function
  If lpf(i) <> 0 Then
    o = lpf(i)
    lpf(i) = PRdW(lpg(i), o)                     ' the free chain's next
  Else
    o = lpb(i)
    If o = 0 Then o = 2                           ' (offset 0 means none: the page's first node is at 2)
    lpb(i) = o + z
  End If
  lpu(i) = lpu(i) + 1
  r1 = i
  LCut = o
End Function

' a node given back (its page in the table at i)
Sub LFreeNode(ByVal i As Integer, ByVal o As Integer)
  PWrW lpg(i), o, lpf(i)
  lpf(i) = o
  lpu(i) = lpu(i) - 1
  If lpu(i) = 0 Then LPageFree i
End Sub

' the table index of C0's page p (-1 none)
Function LIdx(ByVal p As Integer) As Integer
  Dim i As Integer
  For i = 0 To LPMAX
    If lpg(i) = p Then LIdx = i : Exit Function
  Next
  LIdx = -1
End Function

' ---- the list in hand: its record read (list 0's is the kernel's variables) and written back

Function LFetch(ByVal h As Integer) As Integer
  Dim pg As Integer, o As Integer
  If h = 0 Then h = -1                             ' list 0 (the system list) is held as -1
  If h = xlh And h <> 0 Then LFetch = -1 : Exit Function
  If h = -1 Then
    xlh = -1
    xlo = 0
    xlz = LREC
    xlc = lsc
    xlf = lsf
    xll = lsl
    xlm = lsm
    xln = lsn
    xlr = lsr
    LFetch = -1 : Exit Function
  End If
  If lsm = 0 Or h < 1 Or h > 4095 Then LFetch = 0 : Exit Function
  PRd lsm, h * 4, VarPtr(xlb(0)), 4                ' list 0's map: the record's place
  pg = xlb(0) + xlb(1) * 256 : o = xlb(2) + xlb(3) * 256
  If pg = 0 Then LFetch = 0 : Exit Function
  PRd pg, o + 4, VarPtr(xlb(0)), LREC
  xlh = h
  xlo = xlb(0) + xlb(1) * 256 : xlz = xlb(2) + xlb(3) * 256 : xlc = xlb(4) + xlb(5) * 256
  xlf = xlb(6) + xlb(7) * 256 : xll = xlb(8) + xlb(9) * 256 : xlm = xlb(10) + xlb(11) * 256
  xln = xlb(12) + xlb(13) * 256 : xlr = xlb(14) + xlb(15) * 256
  LFetch = -1
End Function

Sub LSave()
  Dim pg As Integer, o As Integer
  If xlh = -1 Then
    lsc = xlc
    lsf = xlf
    lsl = xll
    lsm = xlm
    lsn = xln
    lsr = xlr
    Exit Sub
  End If
  If xlh = 0 Then Exit Sub
  PRd lsm, xlh * 4, VarPtr(xlb(0)), 4
  pg = xlb(0) + xlb(1) * 256 : o = xlb(2) + xlb(3) * 256
  xlb(0) = xlo And 255 : xlb(1) = (xlo \ 256) And 255
  xlb(2) = xlz And 255 : xlb(3) = (xlz \ 256) And 255
  xlb(4) = xlc And 255 : xlb(5) = (xlc \ 256) And 255
  xlb(6) = xlf And 255 : xlb(7) = (xlf \ 256) And 255
  xlb(8) = xll And 255 : xlb(9) = (xll \ 256) And 255
  xlb(10) = xlm And 255 : xlb(11) = (xlm \ 256) And 255
  xlb(12) = xln And 255 : xlb(13) = (xln \ 256) And 255
  xlb(14) = xlr And 255 : xlb(15) = (xlr \ 256) And 255
  PWr pg, o + 4, VarPtr(xlb(0)), LREC
End Sub

' the place of node n of the list in hand: True, with its page (C0's number) in r2 and offset in r3
Function LPlace(ByVal n As Integer) As Integer
  LPlace = 0
  If n < 1 Or n > 4095 Or xlm = 0 Then Exit Function
  PRd xlm, n * 4, VarPtr(xlb(0)), 4
  r2 = xlb(0) + xlb(1) * 256 : r3 = xlb(2) + xlb(3) * 256
  If r2 <> 0 Then LPlace = -1
End Function

' a new node of the list in hand, numbered and placed, not linked: its number (0 no room)
Function LNew() As Integer
  Dim o As Integer, n As Integer, i As Integer, p As Integer
  If xlm = 0 Then                                 ' the list's map page, at its first node
    i = LPage(-1)
    If i < 0 Then LNew = 0 : Exit Function
    xlm = lpg(i) : lpu(i) = 1
  End If
  o = LCut(xlz + 4)
  If o = 0 Then LNew = 0 : Exit Function
  If xlr <> 0 Then
    n = xlr                                       ' a number from the free chain (its entry holds the next)
    PRd xlm, n * 4, VarPtr(xlb(0)), 4
    xlr = xlb(2) + xlb(3) * 256
  Else
    n = xln + 1
    If n > 4095 Then
      LFreeNode r1, o
      LNew = 0 : Exit Function
    End If
    xln = n
  End If
  p = lpg(r1)
  xlb(0) = p And 255 : xlb(1) = (p \ 256) And 255 : xlb(2) = o And 255 : xlb(3) = (o \ 256) And 255
  PWr xlm, n * 4, VarPtr(xlb(0)), 4                ' the map: number -> place
  xlb(0) = 0 : xlb(1) = 0 : xlb(2) = 0 : xlb(3) = 0
  PWr p, o, VarPtr(xlb(0)), 4                     ' its links: none yet
  LNew = n
End Function

' node n of the list in hand linked after node a (0: at the start)
Sub LLink(ByVal n As Integer, ByVal a As Integer)
  Dim b As Integer, p As Integer, o As Integer
  If a = 0 Then                                   ' b: the one after a
    b = xlf
  Else
    kr = LPlace(a) : b = PRdW(r2, r3)
  End If
  kr = LPlace(n) : p = r2 : o = r3
  PWrW p, o, b : PWrW p, o + 2, a                  ' n's next, prev
  If a = 0 Then
    xlf = n
  Else
    kr = LPlace(a) : PWrW r2, r3, n
  End If
  If b = 0 Then
    xll = n
  Else
    kr = LPlace(b) : PWrW r2, r3 + 2, n
  End If
  xlc = xlc + 1
End Sub

' node n of the list in hand unlinked
Sub LUnlink(ByVal n As Integer)
  Dim a As Integer, b As Integer
  kr = LPlace(n)
  PRd r2, r3, VarPtr(xlb(0)), 4
  b = xlb(0) + xlb(1) * 256 : a = xlb(2) + xlb(3) * 256
  If a = 0 Then
    xlf = b
  Else
    kr = LPlace(a) : PWrW r2, r3, b
  End If
  If b = 0 Then
    xll = a
  Else
    kr = LPlace(b) : PWrW r2, r3 + 2, a
  End If
  xlc = xlc - 1
End Sub

' node n of the list in hand freed: its place back to the heap, its number to the map's chain
Sub LDrop(ByVal n As Integer)
  Dim i As Integer
  kr = LPlace(n)
  i = LIdx(r2)
  If i >= 0 Then LFreeNode i, r3
  xlb(0) = 0 : xlb(1) = 0 : xlb(2) = xlr And 255 : xlb(3) = (xlr \ 256) And 255
  PWr xlm, n * 4, VarPtr(xlb(0)), 4
  xlr = n
End Sub

' the list in hand destroyed: every node, its map page, its record (not list 0's)
Sub LDestroy()
  Dim n As Integer, m As Integer, i As Integer, h As Integer
  n = xlf
  Do While n <> 0
    kr = LPlace(n)
    m = PRdW(r2, r3)
    i = LIdx(r2)
    If i >= 0 Then LFreeNode i, r3
    n = m
  Loop
  If xlo > 0 And xlo <= MAXS Then xlq(xlo) = xlq(xlo) - CLng(xlc) * (xlz + 4)
  If xlm <> 0 Then
    i = LIdx(xlm)
    If i >= 0 Then LPageFree i
  End If
  h = xlh
  xlh = 0
  If h > 0 Then                                   ' the record off list 0
    kr = LFetch(0)
    LUnlink h
    LDrop h
    LSave
  End If
End Sub

' every list slot t owns destroyed (its program ended, KILL, RESET)
Sub ListsFree(ByVal t As Integer)
  Dim n As Integer, m As Integer, o As Integer
  If lsm = 0 Then Exit Sub
  kr = LFetch(0)
  n = xlf
  Do While n <> 0
    kr = LFetch(0)
    kr = LPlace(n)
    m = PRdW(r2, r3)                              ' the next record first (this one may go)
    o = PRdW(r2, r3 + 4)                          ' its owner
    If o = t Then
      kr = LFetch(n)
      LDestroy
    End If
    n = m
  Loop
  xlq(t) = 0
End Sub

' the ops (BDOS 131, 48-63) for slot t with its block at p
Function ListOp(ByVal t As Integer, ByVal p As Integer, ByVal o As Integer) As Integer
  Dim h As Integer, n As Integer, m As Integer, z As Integer, k As Integer, a As Integer, v As Integer, w As Integer
  Dim pg As Integer, po As Integer, i As Integer, j As Integer, x As Integer, y As Integer
  ListOp = 255
  h = RW(t, p + 2) : n = RW(t, p + 4)
  If o = 48 Then                                  ' CREATE size: a record on list 0, the new list's number
    z = h
    If z < 1 Or z > 2044 Then Exit Function
    If lquota = 0 Then
      kr = KOp(20, 0, 0, 0, 0)
      lquota = CLng(Deek(KB + 24)) * 16384 \ (ns + 1)   ' (MEMINFO's free pages, the pool, divided among the slots)
      If lquota < 32768 Then lquota = 32768
    End If
    kr = LFetch(0)
    m = LNew()
    If m = 0 Then ListOp = 1 : Exit Function
    LLink m, xll
    LSave
    kr = LPlace(m)
    xlb(0) = t And 255 : xlb(1) = 0 : xlb(2) = z And 255 : xlb(3) = (z \ 256) And 255
    For i = 4 To 15
      xlb(i) = 0
    Next
    PWr r2, r3 + 4, VarPtr(xlb(0)), LREC             ' the record: owner, node size, nothing yet
    WW t, p + 2, m
    ListOp = 0
    Exit Function
  End If
  If LFetch(h) = 0 Then Exit Function
  If xlo <> t And t <> 0 Then Exit Function      ' not this slot's (the kernel may touch any)
  Select Case o
    Case 49                                       ' DESTROY
      LDestroy
      ListOp = 0
    Case 50, 51, 52                               ' APPEND, PREPEND, INSERTAFTER n
      If t > 0 Then
        If xlq(t) + xlz + 4 > lquota Then ListOp = 1 : Exit Function
      End If
      If o = 52 Then
        If LPlace(n) = 0 Then Exit Function
      End If
      m = LNew()
      If m = 0 Then ListOp = 1 : Exit Function
      If o = 50 Then LLink m, xll
      If o = 51 Then LLink m, 0
      If o = 52 Then LLink m, n
      LSave
      If t > 0 Then xlq(t) = xlq(t) + xlz + 4
      WW t, p + 4, m
      ListOp = 0
    Case 53                                       ' DELETE n
      If LPlace(n) = 0 Then Exit Function
      LUnlink n
      LDrop n
      LSave
      If t > 0 Then xlq(t) = xlq(t) - xlz - 4
      ListOp = 0
    Case 54
      WW t, p + 4, xlf : ListOp = 0
    Case 55
      WW t, p + 4, xll : ListOp = 0
    Case 56, 57                                   ' NEXT n, PREV n
      If LPlace(n) = 0 Then Exit Function
      WW t, p + 4, PRdW(r2, r3 + IIf(o = 56, 0, 2)) : ListOp = 0
    Case 58
      WW t, p + 4, xlc : ListOp = 0
    Case 59, 60                                   ' READ / WRITE n o k a: the node's data
      If LPlace(n) = 0 Then Exit Function
      k = RW(t, p + 6) : z = RW(t, p + 8) : a = RW(t, p + 10)
      If k < 0 Or z < 1 Or k + z > xlz Or z > 1023 Then Exit Function
      If o = 59 Then kr = KOp(44, t + z * 32, r2, r3 + 4 + k, a) Else kr = KOp(45, t + z * 32, r2, r3 + 4 + k, a)
      ListOp = 0
    Case 61                                       ' SEARCH o v: the first node whose word at o is v
      k = RW(t, p + 6) : v = RW(t, p + 8)
      If k < 0 Or k + 2 > xlz Then Exit Function
      m = xlf : x = 0
      Do While m <> 0
        kr = LPlace(m)
        If PRdW(r2, r3 + 4 + k) = v Then x = m : Exit Do
        m = PRdW(r2, r3)
      Loop
      WW t, p + 4, x : ListOp = 0
    Case 62                                       ' SORT o: by the word at o, ascending (an insertion sort by relinking:
      k = RW(t, p + 6)                            ' each node taken off and put back after the last one not above it)
      If k < 0 Or k + 2 > xlz Then Exit Function
      If xlc > 1 Then
        kr = LPlace(xlf)
        m = PRdW(r2, r3)                          ' the second node on: the first is sorted on its own
        Do While m <> 0
          kr = LPlace(m)
          y = PRdW(r2, r3)                        ' the next to do
          v = PRdW(r2, r3 + 4 + k)
          LUnlink m
          x = 0 : j = xlf                         ' x: the last node not above v
          Do While j <> 0 And j <> y
            kr = LPlace(j)
            If PRdW(r2, r3 + 4 + k) > v Then Exit Do
            x = j
            j = PRdW(r2, r3)
          Loop
          LLink m, x
          m = y
        Loop
      End If
      LSave
      ListOp = 0
    Case 63                                       ' INFO
      WW t, p + 4, xlz : WW t, p + 6, xlc : ListOp = 0
  End Select
End Function
