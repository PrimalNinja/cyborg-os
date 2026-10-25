' Hot: CyborgOS's system keys, looked at 50 times a second whatever runs (an interrupt class:
' its Tick runs at the hypervisor's safe points, and a program in a bank gives the CPU back at
' every interrupt). Control held: 1-9, 0 (10) a slot to the front, ESC the TOP screen. Each new
' key while Control stays down counts (Control + 1, then 2, then 3 ...). With more than 10 slots
' (Slots n), the same number pressed twice within DOUBLE ticks is slot 10 + that number: a
' single press then waits that long (or until Control is let go, or another key comes) before
' it counts. Take() gives the last one (0 none, 1-16 a slot, TOPKEY) and clears it. Speed(f): an
' emulator running f times a CPC's speed (KEYREP f) - the double tap's time f times as many ticks,
' so it stays 0.3 s of real time (WinAPE at 1000%: 10)
Option Class Interrupt 50
Public Const TOPKEY = 99
Const DOUBLE = 15                       ' ticks (0.3 s) for the second press of a double tap
Private pend As Integer, last As Integer, ctl As Integer, ns As Integer
Private one As Integer, age As Integer  ' a single press waiting to see if a second one comes
Private dbl As Integer                  ' DOUBLE x the emulator's speed (Speed): 0 until set - DOUBLE
#If NTC_ZXN Then
Private kk As Integer                   ' zxn: the chord read last tick (one counts when read twice running)
Private tk As Integer                   ' zxn: Ticks run (Poll: a frame with none gets one from the loop)
Private rl As Integer                   ' zxn: the raster line Poll saw last (a lower one: a new frame)
#End If

' Speed(f): the CPC running f times as fast (KEYREP f): the double tap waits f times as many ticks
Public Sub Speed(ByVal f As Integer)
  If f < 1 Then f = 1
  If f > 40 Then f = 40
  dbl = DOUBLE * f
End Sub

Public Sub Slots(ByVal n As Integer)
  ns = n
End Sub

Public Sub Tick()
  Dim k As Integer
#If NTC_ZXN Then
  ' zxn: no Control key on the Next's membrane, and Symbol Shift types the punctuation, so the
  ' one system key is Caps Shift + 0: TOP (the Next's Delete key stays Delete: Chord). A slot to
  ' the front: TOP, then its key there (1-9, 0, A-J: Main's KeyIn) - Caps Shift + 1-9 were the
  ' slots once, but the Next's own keys (the cursors, EDIT, CAPS LOCK, GRAPH ...) are those
  ' chords in the matrix. Caps + Space Break.
  ' ctl is on only during such a chord, so Caps + a letter still types a capital
  ' The real keyboard misreads for a scan as a key goes up (Caps held, 3 let go: a "1" for a moment),
  ' so a chord counts only when read the same twice running
  k = Chord()
  ctl = (k <> 0)
  tk = 1
  If k <> kk Then kk = k : k = 0                ' (the first read of a chord: not yet)
#Else
  ctl = Keys.Down(Keys.KeyControl)
  If ctl Then
    If Keys.Down(64) Then k = 1
    If Keys.Down(65) Then k = 2
    If Keys.Down(57) Then k = 3
    If Keys.Down(56) Then k = 4
    If Keys.Down(49) Then k = 5
    If Keys.Down(48) Then k = 6
    If Keys.Down(41) Then k = 7
    If Keys.Down(40) Then k = 8
    If Keys.Down(33) Then k = 9
    If Keys.Down(32) Then k = 10
    If Keys.Down(Keys.KeyEsc) Then k = TOPKEY
  End If
#End If
  If k <> 0 And k <> last Then
#If NTC_ZXN Then
    ' zxn: TOP only (the slots: TOP, then the slot's key)
    If k = TOPKEY Then
#Else
    If k = TOPKEY Or ns <= 10 Then
#End If
      If one <> 0 Then one = 0
      pend = k                          ' at once (no double taps to wait for)
    ElseIf one = k Then
      one = 0
      If k + 10 <= ns Then pend = k + 10 Else pend = k  ' the second press: slot 11-20
    Else
      If one <> 0 Then pend = one       ' another number: the waiting one counts now
      one = k : age = 0
    End If
  End If
  If one <> 0 Then
    age = age + 1
    If dbl = 0 Then dbl = DOUBLE
    If age > dbl Or ctl = 0 Then pend = one : one = 0       ' no second press (or Control let go)
  End If
  last = k
End Sub

#If NTC_ZXN Then
' Poll(): from the hypervisor's loop, which runs at every slot's turn end: once a frame (the raster
' line, NextReg #1F / #1E bit 0, wrapped: a 50 Hz clock the hardware keeps whatever the CPU does),
' Tick - if no interrupt-driven Tick came in that frame. The Next's INT is a pulse, and with slots
' polling (interrupts in for a moment a call) the ticks come seldom, seconds apart at the worst:
' the chords, read only by Tick, were missed; the loop, driven by the slots' turns, never stops.
' And the clock itself first: a tick whose pulse was lost (the raster past the line the interrupt
' was set for, no interrupt taken - on JNEXT none come while slots run: a slot waiting on a port
' "until the clock moves on" waited for ever) is made up by ntc_zxn_tickpoll, which the loop calls
' before this (Main): it runs the handler - Ticks counts it, Tick falls due as it would have
Public Sub Poll()
  Dim r As Integer
#asm
            ld bc, #243B
            ld a, #1F
            out (c), a
            inc b
            in a, (c)
            ld e, a
            dec b
            ld a, #1E
            out (c), a
            inc b
            in a, (c)
            and 1
            ld d, a
            dec b
            ld a, (ntc_zxsel)
            out (c), a
            ld ({r}), de
#endasm
  If r < rl Then                                ' a new frame
    If tk = 0 Then Tick                         ' (no tick came in the last one)
    tk = 0
  End If
  rl = r
End Sub

' Chord(): the system chord held now: 0 none, TOPKEY Caps Shift + 0 (Z80). The Next's own keys
' reach the matrix as Caps Shift + a digit (EDIT 1, CAPS LOCK 2, TRUE / INV VIDEO 3 / 4, the
' cursor keys 5-8, GRAPH 9, DELETE 0 - a PC keyboard's too), so the slots aren't Caps Shift +
' 1-9 on the Next: TOP, then the slot's key (Main: KeyIn). Caps + 0 is Delete on a Spectrum, and
' the Next's Delete key reaches the matrix as Caps + 0 as well; NextReg #B1 bit 7 is the Delete
' key itself, so that one stays Delete and Caps + 0 pressed as two keys is TOP. No push: SP is
' the thread
Private Function Chord() As Integer
#asm
            pop hl                  ; the result
            ld de, 0
            ld bc, #FEFE
            in a, (c)
            rra
            jr c, chend             ; no Caps Shift (bit 0 of half row #FE)
            ld b, #EF
            in a, (c)               ; #EF: 0 in bit 0
            rra
            jr c, chend             ; no 0
            ld bc, #243B
            ld a, #B1
            out (c), a
            inc b
            in d, (c)               ; NextReg #B1 bit 7: the Next's Delete key (the dedicated keys, raw)
            dec b
            ld a, (ntc_zxsel)       ; (the NextReg the code had selected, back)
            out (c), a
            bit 7, d
            ld de, 0
            jr nz, chend            ; the Delete key: not TOP
            ld e, 99                ; Caps + 0 as two keys: TOPKEY
chend:      ld d, 0
            ld (hl), e
            inc hl
            ld (hl), d
#endasm
End Function
#End If

Public Function Take() As Integer
  Take = pend
  pend = 0
End Function

' Control(): True while Control is held (with a number or ESC: system keys, not for the programs)
Public Function Control() As Integer
  Control = ctl
End Function

' Held(): the system key held now with Control (a slot, TOPKEY), 0 none - another key with Control
' is the program's (Control + A ... Control + Z: WordStar's keys)
Public Function Held() As Integer
  Held = last
End Function
