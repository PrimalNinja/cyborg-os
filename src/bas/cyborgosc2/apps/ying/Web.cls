' Web - the web side YING and YANG (apps/ying, apps/yang: the two CyborgOS 8BML web browsers)
' share: addresses and fetching. http only (no https). A page is asked for as 8BML: the request
' gets an 8bml parameter, the most it takes in K (?8bml=7 - &8bml=7 when the address has parameters
' already: the 7.5K page buffer, whole K); that is never shown, the address keeps it out (Request makes it, for the fetch alone).
' Built with RAWHEX (RAWYING, RAWYANG): raw - the address asked for as given (no 8bml), whatever
' comes back shown unprocessed, as MON's hex view (r"AAAA  hh .. hh  text" rows): the status line,
' the headers, the body; no redirect followed. Its first 1.25K (RAWMAX); a file the same.
'
' Fetch gets a page from its server with Http.cls (cmds: HTTP GETs over the M4, through
' CyborgOS - NET M4 turns the network on). A form is sent the same way: its fields as URL
' parameters (Bml's Query).
'
' Addresses: http://host[:port][/path][?parameters][#place]. One without a scheme is taken as
' http://; one with no path gets "/". A file is a page too - read from the disc (local pages,
' linked to each other like AmigaGuide's): one with a drive (A:NAME.8BM), one named .8BM
' (NAME.8BM: this drive), or file:NAME.EXT. Its links: from its drive.
Option Explicit
Private sn As Integer, sb As Integer, smx As Integer   ' the page being made: length, buffer, room
Private stt As Integer                                 ' the last fetch's status (Fetch)
Private sct As Integer                                 ' the last fetch's page cut (longer than the buffer)
#If RAWHEX Then
Const RAWMAX = 1280                                    ' raw: the bytes shown (80 rows of 16 - their rows
                                                       ' fit 7.5K, made in place from the buffer's top)
Private wh As String Max 72                            ' (raw: the title)
#End If

' Fetch(u, buf, max): page u (an address, as shown) fetched as 8BML into buf (max bytes at most):
' its length. Always a page - a status page when it couldn't be fetched. Status(): how it went
Public Function Fetch(ByVal u As String Max 255, ByVal buf As Integer, ByVal max As Integer) As Integer
  Dim n As Integer
  sb = buf : smx = max : sn = 0
  u = Clean(u)
  stt = 0 : sct = False
#If RAWHEX Then
  If IsFile(u) Or (UCase$(Left$(u, 7)) = "HTTP://" And Host(u) <> "") Then
    RawFetch u : Fetch = sn : Exit Function
  End If
#End If
  If IsFile(u) Then
    LoadFile u
  ElseIf UCase$(Left$(u, 8)) = "HTTPS://" Then
    stt = 2
    sn = Bml.Pg(0, "Not supported", sb, sn, smx)
    sn = Bml.Pg(1, "https isn't supported - http only:", sb, sn, smx)
    sn = Bml.Pg(1, u, sb, sn, smx)
  ElseIf UCase$(Left$(u, 7)) <> "HTTP://" Or Host(u) = "" Then
    stt = 1
    sn = Bml.Pg(0, "Bad address", sb, sn, smx)
    sn = Bml.Pg(1, "Not an http address: " + u, sb, sn, smx)
  Else
    n = Http.Get(Request(u), sb, smx - 4)
    If n < 0 Then
      stt = 4
      sn = Bml.Pg(0, "Can't fetch it", sb, sn, smx)
      sn = Bml.Pg(1, Http.Message(), sb, sn, smx)
      sn = Bml.Pg(1, u, sb, sn, smx)
    ElseIf Http.Code() <> 200 And Peek(sb) <> 45 And Peek(sb) <> 84 Then
      stt = 5                                      ' (an error with a page of its own: that page)
      sn = Bml.Pg(0, "HTTP " + Trim$(Str$(Http.Code())), sb, sn, smx)
      sn = Bml.Pg(1, "The server answered" + Str$(Http.Code()) + ": " + u, sb, sn, smx)
    Else
      sn = n
      sct = Http.Cut()                             ' (longer than the buffer: what fitted, the browser says so)
    End If
  End If
  If stt <> 0 Then                                 ' (the page's end - Bml's format: a status page
    sn = Bml.Pg(2, "", sb, sn, smx)                ' a back link; a file its own end, a fetched
  ElseIf IsFile(u) Then                            ' page a back link - raw: nothing, the page
    sn = Bml.Pg(3, "", sb, sn, smx)                ' has its own E)
  Else
    sn = Bml.Pg(4, "", sb, sn, smx)
  End If
  Fetch = sn
End Function

' Status(): the last Fetch - 0 a page, 1 not an http address, 2 https, 3 no such file (or too big),
' 4 not fetched (no network, no such host, no answer: its page says), 5 an HTTP error
Public Function Status() As Integer
  Status = stt
End Function

' Cut(): True when the last page fetched was longer than the buffer - shown as far as it fitted
Public Function Cut() As Integer
  Cut = sct
End Function

' Clean(u): u as an address - spaces off its ends, http:// before one with no scheme, "/" after a
' host with no path
Public Function Clean(ByVal u As String Max 255) As String Max 255
  Dim j As Integer
  u = Trim$(u)
  If UCase$(Left$(u, 5)) = "FILE:" Then u = Mid$(u, 6)
  If IsFile(u) Then Clean = UCase$(u) : Exit Function
  If u <> "" And InStr(u, "://") = 0 Then u = "http://" + u
  j = InStr(u, "://")
  If j > 0 Then
    If InStr(Mid$(u, j + 3), "/") = 0 Then
      If InStr(Mid$(u, j + 3), "?") = 0 And InStr(Mid$(u, j + 3), "#") = 0 Then u = u + "/"
    End If
  End If
  Clean = u
End Function

' Request(u): the address the fetch asks for - the place (#...) off, the 8bml parameter on: the most
' the page buffer takes (Fetch's max, less 4 for its end), in whole K - 8bml=7 for 7.5K
' (raw - RAWYING, RAWYANG: nothing added)
Public Function Request(ByVal u As String Max 255) As String Max 255
  Dim j As Integer, q As String Max 20
  j = InStr(u, "#")
  If j > 0 Then u = Left$(u, j - 1)
#If RAWHEX Then
  Request = u : Exit Function                    ' (raw: as given)
#End If
  q = "8bml=" + Trim$(Str$((smx - 4) \ 1024))
  If InStr(u, "?") > 0 Then
    If Right$(u, 1) = "?" Or Right$(u, 1) = "&" Then u = u + q Else u = u + "&" + q
  Else
    u = u + "?" + q
  End If
  Request = u
End Function

' Origin(u): "http://host[:port]" - u up to its path
Public Function Origin(ByVal u As String Max 80) As String Max 80
  Dim j As Integer, k As Integer
  j = InStr(u, "://")
  If j = 0 Then Origin = "" : Exit Function
  k = Edge(u, j + 3)
  Origin = Left$(u, k - 1)
End Function

' Host(u): its host name (no port)
Public Function Host(ByVal u As String Max 80) As String Max 80
  Dim h As String Max 80, j As Integer
  j = InStr(u, "://")
  If j = 0 Then Host = "" : Exit Function
  h = Mid$(Origin(u), j + 3)
  j = InStr(h, ":")
  If j > 0 Then h = Left$(h, j - 1)
  Host = h
End Function

' Port(u): its port (80 when it names none)
Public Function Port(ByVal u As String Max 80) As Integer
  Dim h As String Max 80, j As Integer
  Port = 80
  j = InStr(u, "://")
  If j = 0 Then Exit Function
  h = Mid$(Origin(u), j + 3)
  j = InStr(h, ":")
  If j > 0 Then Port = Val(Mid$(h, j + 1))
End Function

' Path(u): its path and parameters (what an HTTP GET names), "/" at least; the place left out
Public Function Path(ByVal u As String Max 255) As String Max 255
  Dim p As String Max 255, j As Integer
  p = Mid$(u, Len(Origin(u)) + 1)
  j = InStr(p, "#")
  If j > 0 Then p = Left$(p, j - 1)
  If Left$(p, 1) <> "/" Then p = "/" + p
  Path = p
End Function

' Resolve(base, h): link h as an address, from page base: a whole address as it is; //host...
' with http:; /path from base's host; ?parameters and #place on base's path; else from base's
' folder (./ and ../ followed)
Public Function Resolve(ByVal b As String Max 255, ByVal h As String Max 255) As String Max 255
  Dim d As String Max 255, j As Integer
  h = Trim$(h)
  If h = "" Then Resolve = b : Exit Function
  If InStr(h, "://") > 0 Then Resolve = h : Exit Function
  If UCase$(Left$(h, 5)) = "FILE:" Then Resolve = Mid$(h, 6) : Exit Function
  If IsFile(b) Then                              ' (from a file: its drive)
    j = InStr(h, "#")
    If j > 0 Then h = Left$(h, j - 1)
    If Mid$(h, 2, 1) = ":" Or Mid$(b, 2, 1) <> ":" Then Resolve = h Else Resolve = Left$(b, 2) + h
    Exit Function
  End If
  If Left$(h, 2) = "//" Then Resolve = "http:" + h : Exit Function
  If Left$(h, 1) = "/" Then Resolve = Origin(b) + h : Exit Function
  j = InStr(b, "#")
  If j > 0 Then b = Left$(b, j - 1)
  If Left$(h, 1) = "#" Then Resolve = b + h : Exit Function
  j = InStr(b, "?")
  If j > 0 Then b = Left$(b, j - 1)
  If Left$(h, 1) = "?" Then Resolve = b + h : Exit Function
  d = Mid$(b, Len(Origin(b)) + 1)                ' base's folder: its path to the last /
  j = Len(d)
  Do While j > 0
    If Mid$(d, j, 1) = "/" Then Exit Do
    j = j - 1
  Loop
  d = Left$(d, j)
  If d = "" Then d = "/"
  Do
    If Left$(h, 2) = "./" Then
      h = Mid$(h, 3)
    ElseIf Left$(h, 3) = "../" Then
      h = Mid$(h, 4)
      If Len(d) > 1 Then                         ' up a folder (not above /)
        j = Len(d) - 1
        Do While j > 0
          If Mid$(d, j, 1) = "/" Then Exit Do
          j = j - 1
        Loop
        d = Left$(d, j)
      End If
    Else
      Exit Do
    End If
  Loop
  Resolve = Origin(b) + d + h
End Function

' IsFile(u): u names a file - a drive (A:...), or NAME.8BM (no "/" - host/x.8bm is the web's)
Public Function IsFile(ByVal u As String Max 80) As Integer
  Dim c As String Max 1
  IsFile = False
  If InStr(u, "://") > 0 Then Exit Function
  c = UCase$(Left$(u, 1))
  If Mid$(u, 2, 1) = ":" And c >= "A" And c <= "P" Then IsFile = True : Exit Function
  If UCase$(Right$(u, 4)) = Ext() And InStr(u, "/") = 0 Then IsFile = True
End Function

' Home(): the home page - HOME.8BM on this drive, else A:'s, else Z:'s (else this drive's, not
' there: its page says so). Raw: the same file, its bytes
Public Function Home() As String Max 12
  Home = "HOME" + Ext()
  If FileSystem.Exists(Home) Then Exit Function
  If FileSystem.Exists("A:" + Home) Then Home = "A:" + Home : Exit Function
  If FileSystem.Exists("Z:" + Home) Then Home = "Z:" + Home
End Function

' Ext(): a local page's extension - .8BM
Public Function Ext() As String Max 4
  Ext = ".8BM"
End Function

' Name(n): the program's name - n (YING, YANG), raw: RAWn
Public Function Name(ByVal n As String Max 4) As String Max 8
#If RAWHEX Then
  Name = "RAW" + n
#Else
  Name = n
#End If
End Function

' where u's host part (from j) ends: its first /, ? or # (else past the end)
Private Function Edge(ByVal u As String Max 80, ByVal j As Integer) As Integer
  Dim c As String Max 1
  Do While j <= Len(u)
    c = Mid$(u, j, 1)
    If c = "/" Or c = "?" Or c = "#" Then Exit Do
    j = j + 1
  Loop
  Edge = j
End Function

' ---- a file: read whole (to its first ^Z: CP/M's records); none, or too big: a page says so
Private Sub LoadFile(ByVal u As String Max 72)
  Dim n As Integer, j As Integer
  n = FileSystem.Load(u, sb, smx)
  If n < 0 Then
    stt = 3
    sn = Bml.Pg(0, "No such page", sb, sn, smx)
    sn = Bml.Pg(1, "No such file (or too big: 7.5K at most): " + u, sb, sn, smx)
    Exit Sub
  End If
  For j = 0 To n - 1
    If Peek(sb + j) = 26 Then n = j : Exit For
  Next
  sn = n
End Sub

#If RAWHEX Then
' ---- raw: u fetched (or read) as it comes, its first RAWMAX bytes put at the buffer's top, then made
' into MON's hex rows from the buffer's start under a title (the rows outgrow the bytes they're made
' from, 16 -> up to 90, but never catch them up: 80 rows from 6394 bytes in)
Private Sub RawFetch(ByVal u As String Max 255)
  Dim n As Integer, a As Integer, h As Integer
  a = sb + smx - 4 - RAWMAX
  If IsFile(u) Then
    n = -1
    h = FileSystem.Open(u, FileSystem.ForReadRaw)
    If h >= 0 Then n = FileSystem.Read(h, a, RAWMAX) : sct = Not FileSystem.Eof(h) : h = FileSystem.Close(h)
    wh = u
  Else
    n = Http.Get(Request(u), a, RAWMAX)
    sct = Http.Cut()
    wh = "HTTP " + Trim$(Str$(Http.Code())) + "  " + u
  End If
  If n < 0 Then
    stt = 4
    sn = Bml.Pg(0, "Can't fetch it", sb, sn, smx)
    If IsFile(u) Then sn = Bml.Pg(1, "No such file: " + u, sb, sn, smx) Else sn = Bml.Pg(1, Http.Message(), sb, sn, smx)
    sn = Bml.Pg(2, "", sb, sn, smx)
    Exit Sub
  End If
  sn = Bml.Pg(0, Left$(wh, 60) + " (" + Trim$(Str$(n)) + " bytes" + IIf(sct, ", the first", "") + ")", sb, sn, smx)
  HexOut a, n
  sn = Bml.Pg(4, "", sb, sn, smx)
End Sub

' HexOut(src, n): n bytes at src as MON's hex rows (HexRows) into the page from sn - r"AAAA  hh .. hh
' text": (AAAA from 0, 16 a row, the last row's missing bytes as spaces; text: 32-126 as they are,
' the rest ".", " and \ after a \), 4 bytes of the room kept for the page's end
Private Sub HexOut(ByVal src As Integer, ByVal n As Integer)
#asm
            ld (wh_sp), sp
            ld sp, (ntc_csp)        ; (the real stack: wh_put is called)
            ld hl, ({smx})
            ld bc, ({sn})
            or a
            sbc hl, bc
            ld bc, 4
            or a
            sbc hl, bc
            ld b, h
            ld c, l                 ; BC = room left
            ld hl, ({sb})
            ld de, ({sn})
            add hl, de              ; HL = the page's end
            ld ix, ({src})
            ld de, 0
            ld (wh_adr), de
            ld de, ({n})
            ld (wh_left), de
wh_row:
            ld de, (wh_left)
            ld a, d
            or e
            jp z, wh_done
            ld a, d
            or a
            jr nz, wh_16
            ld a, e
            cp 16
            jr c, wh_cnt
wh_16:
            ld a, 16
wh_cnt:
            ld (wh_n), a            ; this row's bytes
            push hl
            ld hl, (wh_left)
            ld e, a
            ld d, 0
            or a
            sbc hl, de
            ld (wh_left), hl
            pop hl
            ld a, 'r'
            call wh_put
            ld a, 34
            call wh_put
            ld a, (wh_adr + 1)
            call wh_hex
            ld a, (wh_adr)
            call wh_hex
            ld a, ' '
            call wh_put
            call wh_put
            ld a, (wh_n)
            ld e, a
            ld d, 16
wh_byte:
            ld a, e
            or a
            jr z, wh_pad
            ld a, (ix + 0)
            call wh_hex
            inc ix
            dec e
            jr wh_gap
wh_pad:
            ld a, ' '
            call wh_put
            call wh_put
wh_gap:
            ld a, ' '
            call wh_put
            dec d
            jr nz, wh_byte
            call wh_put             ; (A: a space)
            push hl
            push ix
            pop hl
            ld a, (wh_n)
            ld e, a
            ld d, 0
            or a
            sbc hl, de
            push hl
            pop ix                  ; back to the row's first byte
            pop hl
wh_text:
            ld a, (ix + 0)
            cp 32
            jr c, wh_dot
            cp 127
            jr c, wh_ch
wh_dot:
            ld a, '.'
wh_ch:
            cp 34
            jr z, wh_esc
            cp 92
            jr nz, wh_one
wh_esc:
            push af
            ld a, 92
            call wh_put
            pop af
wh_one:
            call wh_put
            inc ix
            dec e
            jr nz, wh_text
            ld a, 34
            call wh_put
            ld a, ':'
            call wh_put
            push hl
            ld hl, (wh_adr)
            ld de, 16
            add hl, de
            ld (wh_adr), hl
            pop hl
            jp wh_row
wh_done:
            ld de, ({sb})
            or a
            sbc hl, de
            ld ({sn}), hl
            ld sp, (wh_sp)
            jr wh_end
wh_hex:                             ; A as 2 hex digits
            push af
            rrca
            rrca
            rrca
            rrca
            call wh_dig
            pop af
wh_dig:
            and 15
            add a, #90
            daa
            adc a, #40
            daa
wh_put:                             ; A into the page when there is room
            push af
            ld a, b
            or c
            jr z, wh_full
            pop af
            ld (hl), a
            inc hl
            dec bc
            ret
wh_full:
            pop af
            ret
wh_sp:      dw 0
wh_adr:     dw 0
wh_left:    dw 0
wh_n:       db 0
wh_end:
#endasm
End Sub
#End If

