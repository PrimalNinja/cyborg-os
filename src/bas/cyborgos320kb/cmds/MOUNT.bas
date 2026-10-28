' MOUNT: a device (or a device's folder) given a drive letter, in CyborgOS (build for cpm, with
' CybVol.cls). Needs UniDOS. The slot stays on its own drive (CV changes that)
'   MOUNT                            the drives with paths, and the devices
'   MOUNT SD E    MOUNT SD: E:       drive E is SD:
'   MOUNT SD:GAMES F                 drive F is SD:'s folder GAMES
'   MOUNT - E                        drive E's path dropped
' C-P only: A and B are UniDOS's own, Z CyborgOS's, a RAM disc's letter has no path
Option Explicit
Dim a As String Max 60, d As String Max 40, v As String Max 4
Dim i As Integer
a = UCase$(Trim$(System.CommandLine()))
If Not CybVol.Uni() Then Print "MOUNT needs UniDOS" : End
If a = "" Then CybVol.Show True : End
i = InStr(a, " ")
If i = 0 Then Print "MOUNT device letter (MOUNT SD E), MOUNT - letter, MOUNT alone: the list" : End
d = Left$(a, i - 1) : v = Trim$(Mid$(a, i + 1))
If Right$(v, 1) = ":" Then v = Left$(v, Len(v) - 1)
If Len(v) <> 1 Or v < "C" Or v > "P" Then Print v; ": not a letter MOUNT gives (C-P)" : End
If v = CybSys.BootDrive() Then Print v; ": is the boot drive" : End
If d = "-" Then
  If CybVol.SetPath(v, "") Then Print v; ": its path dropped"
  End
End If
If InStr(d, ":") = 0 Then
  If Not CybVol.IsDevice(d) Then Print d; ": no such device (MOUNT alone lists them)" : End
  d = d + ":"
End If
If CybVol.SetPath(v, d) Then
  Print v; ": --> "; CybVol.PathOf(v);
  If CybSys.Shared(v) > 0 Then Print " (a slot is on "; v; ": it sees it now)";
  Print
End If
End
