' LANG: the language CyborgOS speaks - LANG shows it; LANG EN, LANG RU, LANG ES set it (EN: English
' again). Every slot sees it (the kernel keeps it: CybSys.Lang). It chooses HELP's pages (NAME.HRU,
' NAME.HES before NAME.HLP) and the characters 128-255: Russian KOI8-R, Spanish and English
' Latin-1 (the vCPC's terminal shows them as they are; the machines' fonts follow LANG). Build for cpm
' with cmds/CybSys.cls; a .CYB
Option Explicit
Dim strA As String Max 20, intL As Integer
Dim m_byR(599) As Byte, m_byG(767) As Byte    ' a recipe (KOI8.FNR, LATIN1.FNR), the 96 characters made from it
strA = UCase$(Trim$(System.CommandLine()))
If strA = "EN" Or strA = "ENGLISH" Then
  CybSys.SetLang 0
ElseIf strA = "RU" Or strA = "RUSSIAN" Then
  CybSys.SetLang 1
ElseIf strA = "ES" Or strA = "SPANISH" Then
  CybSys.SetLang 2
ElseIf strA <> "" Then
  Print "LANG [EN | RU | ES]"
End If
intL = CybSys.Lang()
If strA <> "" Then
  If intL = 1 Then LoadFont "KOI8.FNR" Else LoadFont "LATIN1.FNR"
End If
If intL = 1 Then
  Print Chr$(241) + Chr$(218) + Chr$(217) + Chr$(203) + ": " + Chr$(210) + Chr$(213) + Chr$(211) + Chr$(211) + Chr$(203) + Chr$(201) + Chr$(202) + " (LANG EN: English, LANG ES: Spanish)"
ElseIf intL = 2 Then
  Print "Idioma: espa" + Chr$(241) + "ol (LANG EN: English, LANG RU: Russian)"
Else
  Print "Language: English (LANG RU: Russian, LANG ES: Spanish)"
End If

' ---- characters 160-255: made from this machine's own font (characters 32-127, the bank's copy at
' #F300) by the recipe in the file - mkfont.py's: 0 blank, 1 c as it is, 2 c with accent a (a capital
' down a row), 3 c upside down, 4 an 8 x 8 glyph of CyborgOS's own - and handed to the console (BDOS
' 131 op 41). The file is looked for beside LANG (C/) and on A and B
Sub LoadFont(ByVal strName_a As String)
  Dim intN As Integer, intI As Integer, strP As String Max 40
  intN = -1
  For intI = 0 To 4
    If intN <= 0 Then
      If intI = 0 Then strP = strName_a
      If intI = 1 Then strP = "C/" + strName_a
      If intI = 2 Then strP = "A:C/" + strName_a
      If intI = 3 Then strP = "A:" + strName_a
      If intI = 4 Then strP = "B:" + strName_a
      intN = FileSystem.Load(strP, VarPtr(m_byR), 600)
    End If
  Next
  If intN > 0 Then
    Compose
    intI = CybSys.SetFont(VarPtr(m_byG))      ' (255: a console with nothing to take - the vCPC's terminal)
  End If
End Sub

Sub Compose()
  Dim intP As Integer, intG As Integer, intOp As Integer, intC As Integer, intM As Integer, intR As Integer, intQ As Integer
  intP = 0
  For intG = 0 To 95
    intQ = intG * 8
    For intR = 0 To 7
      m_byG(intQ + intR) = 0
    Next
    intOp = m_byR(intP) : intP = intP + 1
    If intOp = 1 Then
      intC = m_byR(intP) : intP = intP + 1
      For intR = 0 To 7
        m_byG(intQ + intR) = BaseRow(intC, intR)
      Next
    ElseIf intOp = 2 Then
      intC = m_byR(intP) : intM = m_byR(intP + 1) : intP = intP + 2
      If intM = 6 Then                                    ' the cedilla: under it, row 7
        For intR = 0 To 7
          m_byG(intQ + intR) = BaseRow(intC, intR)
        Next
        If intC >= 97 Then m_byG(intQ + 7) = &H0C Else m_byG(intQ + 7) = &H18
      ElseIf intC >= 65 And intC <= 90 Then              ' a capital: down a row, the accent on top
        m_byG(intQ) = AccRow(intM, 0)
        For intR = 1 To 7
          m_byG(intQ + intR) = BaseRow(intC, intR - 1)
        Next
      Else                                               ' small: the accent in rows 0-1 (i dotless)
        For intR = 0 To 7
          m_byG(intQ + intR) = BaseRow(intC, intR)
        Next
        If intC = 105 Then m_byG(intQ) = 0 : m_byG(intQ + 1) = 0
        m_byG(intQ) = m_byG(intQ) Or AccRow(intM, 0)
        m_byG(intQ + 1) = m_byG(intQ + 1) Or AccRow(intM, 1)
      End If
    ElseIf intOp = 3 Then                                ' upside down and round (! and ? for Spanish)
      intC = m_byR(intP) : intP = intP + 1
      For intR = 0 To 7
        m_byG(intQ + intR) = Mirror(BaseRow(intC, 7 - intR))
      Next
    ElseIf intOp = 4 Then
      For intR = 0 To 7
        m_byG(intQ + intR) = m_byR(intP + intR)
      Next
      intP = intP + 8
    End If
  Next
End Sub

' row r of character c in this bank's copy of the machine's font
Function BaseRow(ByVal intC_a As Integer, ByVal intR_a As Integer) As Integer
  BaseRow = Peek(&HF300 + (intC_a - 32) * 8 + intR_a)
End Function

' an accent's two rows: 1 acute, 2 grave, 3 circumflex, 4 diaeresis, 5 tilde, 7 ring
Function AccRow(ByVal intM_a As Integer, ByVal intR_a As Integer) As Integer
  Dim intV As Integer
  intV = 0
  If intM_a = 1 Then intV = IIf(intR_a = 0, &H0C, &H18)
  If intM_a = 2 Then intV = IIf(intR_a = 0, &H30, &H18)
  If intM_a = 3 Then intV = IIf(intR_a = 0, &H18, &H66)
  If intM_a = 4 Then intV = IIf(intR_a = 0, &H66, 0)
  If intM_a = 5 Then intV = IIf(intR_a = 0, &H76, &HDC)
  If intM_a = 7 Then intV = IIf(intR_a = 0, &H18, &H18)
  AccRow = intV
End Function

' a byte's bits the other way round
Function Mirror(ByVal intB_a As Integer) As Integer
  Dim intR As Integer, intI As Integer
  intR = 0
  For intI = 0 To 7
    If intB_a And (1 * Pow2(intI)) Then intR = intR Or Pow2(7 - intI)
  Next
  Mirror = intR
End Function

Function Pow2(ByVal intN_a As Integer) As Integer
  Dim intR As Integer, intI As Integer
  intR = 1
  For intI = 1 To intN_a
    intR = intR * 2
  Next
  Pow2 = intR
End Function
