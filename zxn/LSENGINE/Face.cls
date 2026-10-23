' Face - a person's face (and a witch's hat) put together from sprite parts (15 sprites from a slot): the clothes, the
' face, the mouth, the eyes, the hair and an accessory, each in its own palette row (skin, hair
' and eye colours), from their look. 32 x 32 pixels, or 2x / 4x.
' (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
Option Explicit

Public Const SPRITES = 17

' Put sl, a, x, y, z, mo: the face whose look (9 bytes: face, skin, hair, hair colour, eyes, eye
' colour, mouth, accessory, outfit) is at address a, in sprite slots sl .. sl + 14, its top left
' at x, y (sprite coordinates: the paper's top left is 32, 32), z times the size (1, 2 or 4);
' mo: a mouth instead of its own (0-5: smile, open, cat, o, grin, smirk), or -1; h: a witch's hat
' (0 none, 1 or 2: the style) in slots sl + 15, sl + 16
Public Sub Put(ByVal sl As Integer, ByVal a As Integer, ByVal x As Integer, ByVal y As Integer, ByVal z As Integer, ByVal mo As Integer, ByVal h As Integer)
  Dim fl As Integer, q As Integer, sk As Integer, ac As Integer, p As Integer
  fl = 0
  If z = 2 Then fl = Spr.Scale2
  If z = 4 Then fl = Spr.Scale4
  q = 16 * z
  sk = Spr.Pal * (1 + Peek(a + 1))
  p = FaceSet.S_OUTFIT + Peek(a + 8) * 2
  Spr.Put sl, x, y + q, p, fl
  Spr.Put sl + 1, x + q, y + q, p + 1, fl
  Four sl + 2, x, y, FaceSet.S_FACE + Peek(a) * 4, fl + sk, q
  If mo < 0 Then mo = Peek(a + 6)
  Spr.Put sl + 6, x + 8 * z, y + q, FaceSet.S_MOUTH + mo, fl + sk
  p = FaceSet.S_EYES + Peek(a + 4) * 2
  Spr.Put sl + 7, x, y + 8 * z, p, fl + Spr.Pal * (12 + Peek(a + 5))
  Spr.Put sl + 8, x + q, y + 8 * z, p + 1, fl + Spr.Pal * (12 + Peek(a + 5))
  Four sl + 9, x, y, FaceSet.S_HAIR + Peek(a + 2) * 4, fl + Spr.Pal * (4 + Peek(a + 3)), q
  ac = Peek(a + 7)
  Spr.Hide sl + 14
  Select Case ac
    Case 0
      Spr.Hide sl + 13
    Case 6
      Spr.Put sl + 13, x, y + 8 * z, FaceSet.S_GLASSES, fl
      Spr.Put sl + 14, x + q, y + 8 * z, FaceSet.S_GLASSES + 1, fl
    Case 1
      Spr.Put sl + 13, x + 14 * z, y - 4 * z, FaceSet.S_ACC, fl
    Case 3
      Spr.Put sl + 13, x + z, y + 3 * z, FaceSet.S_ACC + 2, fl
    Case 5
      Spr.Put sl + 13, x + 16 * z, y + 10 * z, FaceSet.S_ACC2, fl
    Case Else
      Spr.Put sl + 13, x + 19 * z, y + (ac - 1) * z, FaceSet.S_ACC + ac - 1, fl
  End Select
  If h Then
    p = FaceSet.S_HAT + h * 2 - 2
    Spr.Put sl + 15, x, y - 6 * z, p, fl
    Spr.Put sl + 16, x + q, y - 6 * z, p + 1, fl
  Else
    Spr.HideRange sl + 15, 2
  End If
End Sub

' Hide sl: the face in slots sl .. sl + 14 gone
Public Sub Hide(ByVal sl As Integer)
  Spr.HideRange sl, SPRITES
End Sub

' four sprites: a 32 x 32 part (16 x 16 cells TL, TR, BL, BR)
Private Sub Four(ByVal sl As Integer, ByVal x As Integer, ByVal y As Integer, ByVal p As Integer, ByVal fl As Integer, ByVal q As Integer)
  Spr.Put sl, x, y, p, fl
  Spr.Put sl + 1, x + q, y, p + 1, fl
  Spr.Put sl + 2, x, y + q, p + 2, fl
  Spr.Put sl + 3, x + q, y + q, p + 3, fl
End Sub
