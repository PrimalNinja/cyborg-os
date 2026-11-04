' AUTOEXEC: the boot drive's AUTOEXEC file (text, a command a line - LANG RU, NET M4, RUN 4 SLOTD,
' CD IDE:GAMES/ ...) typed into this slot's command line, a line as each prompt comes back, as if
' you had typed them. The kernel runs it in slot 1 at boot, after RAMDISC; holding Shift at boot
' skips it. No file: nothing. Build for cpm with cmds/CybSys.cls; a .CYB
Option Explicit
Dim m_byT(249) As Byte, m_strL As String Max 250
Dim intN As Integer, intI As Integer, intK As Integer
intN = FileSystem.Load("AUTOEXEC", VarPtr(m_byT), 250)
If intN > 0 Then
  intK = 0                                      ' (lines end with 13: CR LF, or LF alone, made 13)
  For intI = 0 To intN - 1
    If m_byT(intI) = 10 Then
      If intK = 0 Then m_byT(intK) = 13 : intK = intK + 1
      If intK > 0 Then
        If m_byT(intK - 1) <> 13 Then m_byT(intK) = 13 : intK = intK + 1
      End If
    ElseIf m_byT(intI) = 26 Then
      intI = intN
    ElseIf m_byT(intI) >= 32 Or m_byT(intI) = 13 Then
      m_byT(intK) = m_byT(intI) : intK = intK + 1
    End If
  Next
  If intK > 0 Then
    If m_byT(intK - 1) <> 13 Then m_byT(intK) = 13 : intK = intK + 1
    CybSys.Type VarPtr(m_byT), intK
  End If
End If
