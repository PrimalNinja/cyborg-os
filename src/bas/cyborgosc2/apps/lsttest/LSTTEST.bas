' LSTTEST - a test of the hypervisor's slot lists (COSList): a list of 6-byte nodes built past
' what fits in a slot's 64K, walked and summed, some deleted, searched, sorted, destroyed - the
' heap is the shared pool, so the list is far bigger than the TPA. Prints each check and "LST ok"
' at the end. Build for cyborgos with COSList.cls.
'   RUN 2 LSTTEST [n]        n nodes (default 4000: 24000 data bytes, well past 64K)
' (c) 2026 Cyborg Unicorn Pty Ltd
Option Explicit
Dim h As Long, node As Long, prev As Long
Dim i As Integer, n As Integer, bad As Integer, got As Long, want As Long, c As Integer, v As Integer
Dim a As String Max 40

a = Trim$(System.CommandLine())
n = 4000
If a <> "" Then n = Val(a)
If n < 8 Then n = 8

h = COSList.Create(6)
If h = 0 Then Print "LST no list (no room?)" : End
Print "list "; Hex4Lo(h)

' append n nodes: each keeps its index (word 0) and index * 3 (word 2) and a byte (4)
want = 0
For i = 1 To n
  node = COSList.Append(h)
  If node = 0 Then Print "LST no room at "; i; " of "; n : Exit For
  COSList.SetWord node, 0, i And &HFFFF
  COSList.SetWord node, 2, (i * 3) And &HFFFF
  COSList.SetByte node, 4, i And 255
  want = want + (i And 255)
Next
n = i - 1
Print "appended "; n
If COSList.Count(h) <> n Then Print "FAIL count "; COSList.Count(h) : bad = bad + 1

' walk and sum the bytes
got = 0 : c = 0
node = COSList.First(h)
Do While node <> 0
  got = got + COSList.GetByte(node, 4)
  c = c + 1
  node = COSList.NextOf(node)
Loop
If c <> n Then Print "FAIL walked "; c : bad = bad + 1
If got <> want Then Print "FAIL sum "; : PrintL got : Print " want " : PrintL want : bad = bad + 1
Print "sum ok ("; c; " nodes)"

' the k-th node's words (k scaled to n: node k holds k and k*3)
Dim k As Integer
k = n \ 2
node = COSList.First(h)
For i = 1 To k - 1
  node = COSList.NextOf(node)
Next
If COSList.GetWord(node, 0) <> k Then Print "FAIL nodek w0 "; COSList.GetWord(node, 0) : bad = bad + 1
If COSList.GetWord(node, 2) <> k * 3 Then Print "FAIL nodek w2 "; COSList.GetWord(node, 2) : bad = bad + 1

' search for the node whose word 0 is k
node = COSList.Search(h, 0, k)
If node = 0 Then
  Print "FAIL search" : bad = bad + 1
ElseIf COSList.GetWord(node, 2) <> k * 3 Then
  Print "FAIL search w2 "; COSList.GetWord(node, 2) : bad = bad + 1
End If

' delete the first 10, count drops by 10, first is now 11
For i = 1 To 10
  node = COSList.First(h)
  c = COSList.Delete(h, node)
Next
If COSList.Count(h) <> n - 10 Then Print "FAIL count after delete "; COSList.Count(h) : bad = bad + 1
node = COSList.First(h)
If COSList.GetWord(node, 0) <> 11 Then Print "FAIL first after delete "; COSList.GetWord(node, 0) : bad = bad + 1
Print "deleted 10, count "; COSList.Count(h)

' a small list sorted by word 0, descending data built, ascending after
Dim h2 As Long
h2 = COSList.Create(2)
For i = 1 To 20
  node = COSList.Append(h2)
  COSList.SetWord node, 0, (21 - i) * 5
Next
c = COSList.Sort(h2, 0)
node = COSList.First(h2)
v = COSList.GetWord(node, 0)
c = 0
Do While node <> 0
  If COSList.GetWord(node, 0) < v Then c = 1
  v = COSList.GetWord(node, 0)
  node = COSList.NextOf(node)
Loop
If c <> 0 Then Print "FAIL sort not ascending" : bad = bad + 1 Else Print "sort ok"
c = COSList.Destroy(h2)

c = COSList.Destroy(h)
If bad = 0 Then Print "LST ok" Else Print "LST bad "; bad
End

' the low word of a Long in hex (the list id)
Function Hex4Lo(ByVal x As Long) As String
  Dim s As String Max 4, i As Integer, d As Integer, v As Long
  v = x And &HFFFF
  s = ""
  For i = 0 To 3
    d = (v \ (16 ^ (3 - i))) And 15
    s = s + Mid$("0123456789ABCDEF", d + 1, 1)
  Next
  Hex4Lo = s
End Function

Sub PrintL(ByVal x As Long)
  Print x;
End Sub
