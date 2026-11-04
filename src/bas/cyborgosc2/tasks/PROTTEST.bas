' PROTTEST: a CyborgOS test program (build for cpm) that writes where a slot may not - the console
' page at #F700 - to show the vCPC's memory protection stopping it (tools/regress/vcpctest.sh). On a
' CPC it would corrupt its own console page and carry on. Not on any disc or card.
' (c) 2026 Cyborg Unicorn Pty Ltd
Option Explicit
Print "PROTTEST: writing #F700"
Poke &HF700, 65
Print "PROTTEST: still here (no protection)"
