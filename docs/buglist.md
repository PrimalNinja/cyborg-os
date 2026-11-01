# CyborgOS - known bugs

Bugs seen and not yet fixed, by component - the numbers are [components.md](components.md)'s, the
same as the todo's (cyborgos-todo.md: work to do; this: things that are wrong). Newest first in each.
A fixed one moves to cyborgos-done.md. Each bug carries its state: REPORTED (seen, not yet
confirmed or traced), CONFIRMED (reproduced or found in the code), FIXED (moving to done).

## all hypervisors (1-6): a rule

- REPORTED 2026-11-01 (analysis of components 1-7) RULE, proven on NTC's test platform: a push or
  pop in an #asm block whose SP is the thread corrupts the thread words before the block - it works
  once and breaks on the next run (a loop of three calls printed garbage and hung). The cause of the
  ConClear (1) and Tiles (4) crashes. Blocks that switch SP first (Con, Say, Scr, KeyRep, Run, Go,
  FileCall, FileShut, Svc, Vdu, KRun), that pop a parameter word put in the thread on purpose
  (Info, Seg), or that push inside an interrupt routine (KInit's ki_isr) are sound.

## 1 C0 CPC 320K+

- REPORTED 2026-11-01 A 4 MB CPC (Julian's WinAPE): MEM shows "Total 4160 KB, Free 320 KB" and a map
  of ~52 pages - inconsistent figures from one C0 call. Not reproduced here yet: 1984 stops at 1 MB
  (memory = 4096 is invalid there - an earlier "doesn't boot at 4 MB" was that), and the Python
  harness's RAM model shows a full map at 4160. The probe's port scheme is WinAPE's own
  (#7F-#78, #C4-#FF) and the total says all 64 banks were found, so the fault is after the probe:
  Memory.Pages against RamSize, or the kernel's map op. Possibly a regression from today's
  COSLOAD / probe-order change - unproven either way; no baseline here to compare.
  2026-11-01: the mechanism is in NTC's runtime (NTC buglist, 9 - CONFIRMED in the code): mem_tb_fit
  cuts mem_count a page at a time until the page tables fit under the platform's top, with no flag,
  while RamSize stays the probe's (banks + 1) x 64. The top is ntc_plat_memtop, so more ROMs
  reserving workspace (Julian's WinAPE) leave less table room than the harness - the likely reason
  the harness's map is full and WinAPE's isn't (to check).
- REPORTED 2026-10-30 The CPC loses keys held less than ~40 ms while another slot is busy (the
  firmware's scan doesn't run in a busy slot's slice). Julian: seems to work; left as seen.

## 2 C0 CPC flat

- REPORTED 2026-11-01 The flat C0's BOOTDONE (op 33) never sets kw(9), the "Shift held" word the
  kernel reads for AUTOEXEC's skip: it is whatever the last op left there, so AUTOEXEC on the flat
  build runs or not by chance. Fix: kw(9) = 0 (or Keys.Down) there, as the other builds do.

## 3 C0 CPC 128K

- REPORTED 2026-11-01 The 128K C0 isn't in the build at all (no layout project): kept source, never
  compiled - it has none of this year's ops (42 and the rest). Either build it or mark it retired.

## 4 C0 ZX Spectrum Next

- REPORTED 2026-11-01 The Next's console isn't full height (Julian): it was 40 x 32 (the whole
  tilemap) in the first Next build; a port session made every Next mode its CPC rows, so MODE S is
  80 x 24 + the strip, 8 tilemap rows unused. The console page is 2K: 80 x 32 doesn't fit, 64 x 32
  does. Proposed: MODE P (64 x 32) as the Next's default.
- REPORTED 2026-11-01 Hyp.Mark on the Next (a DIAG routine, no callers) pushes IX and IY with no SP
  switch: it would corrupt the thread on its second call if anyone used it. Dead code: fix or drop.
- REPORTED 2026-10-29 The Next and the MSX can't receive slots (no LISTEN / ACCEPT in their C0s):
  SLOTD only on a CPC with an M4 and on a vCPC - also 5, 39.

## 5 C0 MSX

- REPORTED 2026-10-29 The MSX has no network: the GR8NET driver isn't written (C0 says "no network
  yet").
- (The MSX can't receive slots: see 4.)

## 6 C0 vCPC

- REPORTED 2026-10-31 Typed Cyrillic and accents on the vCPC under Windows: _getch gives the OEM code
  page's bytes, so LANG RU / ES text can't be typed there (it shows). The ReadConsoleInputW reading
  was reverted: it broke Control + T. Needs a try on a Windows console.
- REPORTED 2026-10-31 RAMDISC on the vCPC: "RAMDISC needs CyborgOS 320K" with 4 MB there - the vCPC's
  C0 has no RAM disc driver support (BDOS 130).

## 7 The kernel

- (The thread rule above covers the kernel's own #asm blocks too.)

## 8 CybSys.cls

- REPORTED 2026-11-01 CybSys.TextAt builds its result in a String Max 60: an op that answers with
  longer text (b(i) up to 255) is cut at 60 silently. Fine for today's callers (MEM's 32-char map
  groups, names), a trap for a new op.

## 9 CybDir.cls, CybVol.cls

- REPORTED 2026-11-01 CybDir / CybVol keep paths in String Max 40 and names in Max 12: a UniDOS
  folder path over 40 characters is cut silently (CD, DIR, the slot's folder shown). Names are 8.3
  so 12 is right; the path limit wants a check and a message.

## 10 Http.cls

- REPORTED 2026-11-01 Http.Get / Post: when the answer is longer than the caller's buffer the loop
  stops at the buffer's end and returns the part it has as if it were the whole page - no status,
  no message (Web.Fetch shows it as a page). Should set a status ("cut at n bytes").

## 11 SlotFrame.cls

- REPORTED 2026-11-01 SlotFrame recognises a CPC frame by the word on top of the slot's stack
  matching sb_rest or sb_far (the stubs' return points): a program stopped by neither (a key wait
  tried again) is refused ("try again") - right - but a program whose own data happens to equal one
  of those addresses at the top of its stack would be read as a frame and revived wrong. Unlikely;
  a second check (SP's range, the saved PC inside the TPA) would close it.
- REPORTED 2026-11-01 SlotFrame.GetW's comment still says the byte-array case is an NTC bug "noted":
  the compiler was fixed today; the two-variable form stays (clear enough), the comment to update.

## 13 DIR, 14 CD, 15 CV, 16 TYPE, 18 ERA, 19 RENAME

- REPORTED 2026-11-01 Paths in String Max 40 (CybDir's limit, 9): a UniDOS path over 40 characters is
  cut silently in each of these.

## 17 COPY

- REPORTED 2026-11-01 COPY . on a folder with more than 64 matching files copies the first 64 and
  says nothing about the rest (the list is capped, correctly, but silently).

## 25 RAMDISC

- (On the vCPC: "RAMDISC needs CyborgOS 320K" - see 6.)

## 28 MEM

- (A 4 MB CPC: the map and the totals disagree - see 1.)

## 31 FG, 32 KILL

- REPORTED 2026-11-01 With no argument the message is "nothing running in slot " / "no slot " with
  nothing after it (Val("") is 0; the kernel refuses 0). Should print the usage line instead.

## 37 DUMP / REVIVE

- REPORTED 2026-11-01 REVIVE reads the 128-byte header without checking the count (r =
  FileSystem.Read, not tested): a file shorter than a header (a wrong file given) is read as a dump -
  its lengths and frame garbage - and revived. Should require 128 and say "not a dump" (the CYBD
  signature is checked only after).
- REPORTED 2026-11-01 DUMP writes the header and the console-state block (11 bytes) without checking
  the count; a disc that fills at either loses them silently (the body's writes are checked and say
  so).

## 38 RMOVE / RCOPY

- REPORTED 2026-11-01 vCPC -> CPC live move: the CPC's SLOTD takes the slot (OK answered) but the
  program running there hasn't been seen: the harness's typed keys are lost while a slot is busy,
  and holding them long enough breaks the boot's own typed command. Needs a keyboard-free check.
- REPORTED 2026-11-01 CPC -> CPC live move: never shown working (two 1984 processes on one host
  don't connect - an environment problem as far as is known, not a CyborgOS one).

## 39 SLOTD

- REPORTED 2026-11-01 A sender that stops mid-transfer leaves SLOTD waiting the full 20 s per block
  before it gives up and the slot it opened is reset; fine for one, slow for a flood - no fix needed
  now, noted.

## 44 AUTOEXEC

- REPORTED 2026-11-01 AUTOEXEC's lines are typed into slot 1 only; a line that opens another slot's
  program (RUN 2 X) works, but typing into slot 2's own command line isn't a feature - by design,
  worth saying in HELP AUTOEXEC.

## 48 YING / YANG, RAWYING / RAWYANG

- REPORTED 2026-11-01 A page longer than YING's buffer arrives cut (Http, 10): YING shows it as a
  whole page with no mark. Once Http reports the cut, YING should show "(cut)" at the end.

## 49 RAT, RATS, RATBOX, MODEL

- REPORTED 2026-11-01 MODEL reads a .LUN file's 7-byte header and then k x nn bytes without testing
  either count (r = FileSystem.Read, not checked): a short or cut file leaves the weights half old,
  half new, and the model runs on them. Should require the counts and say the file is bad.

## 50 NEURAL, ASK, WATCH, PET, PROBE, GREEN

- REPORTED 2026-11-01 PET takes 16 values with Val from its command line and the .MDL file with no
  range check on most (a negative or huge count feeds its loops); RATBOX (49) 18. Inputs are the
  user's own files, so low risk, but a bad .MDL should say so rather than run with garbage.

## 52 TASKMAN

- REPORTED 2026-10-30 TASKMAN's VDU path never tried against a real VDU server. (51 RVDU: nothing
  found in the code; the same path, also untried against a real server.)

## 53 ENC / DEC, KEYMGR / KEYMAN

- REPORTED 2026-11-01 (a note, not a bug) KEYMAN keeps the key pool in a 16K byte array and KEYMGR
  two 8K ones in the TPA: with the program's own code these are near the TPA's limit on a 64K slot;
  fine today, no room to grow - worth a note in each file.

## 56 INSTALL.BAS

- REPORTED 2026-11-01 A file missing from a disc (|COPY fails) outside the DISK.DAT read is not
  trapped: Locomotive BASIC stops the installer with its own error mid-way, the rest of the discs
  not installed and no message of what's missing. ON ERROR round the copy loop, with the file's name.

## 58 The CPC discs and the Next's SD card (cards.sh)

- REPORTED 2026-11-01 cards.sh masks a failed build: `node cli.js build | grep ... || true` hides the
  builder's exit status, so with set -e a build that stops still has its images tidied, zipped and
  shipped - with the old files in them. Should fail when the builder does (pipefail, or test the
  builder's output for "stopped" / "error" and exit 1).
- REPORTED 2026-11-01 cards.sh's tidy takes files gone from the build out of /CYBORGOS and
  /CYBORGOS/C only: /CYBORGOS/HELP (and any other folder) keeps stale files from older images - an
  old help page nobody deleted stays on the card for ever. Tidy HELP too (and the language pages
  .HRU / .HES).
- REPORTED 2026-11-01 The Next card's base (its NEXTZXOS folder and system files) exists only inside
  cards/cyborgos-next-sd.img.zip, which cards.sh takes as its own base each time: a corrupted or
  lost zip has no other source in the repo (sdimage.py expects a tbblue.mmc nobody keeps). Keep the
  base image (or the NEXTZXOS files) under tools/ or document where they come from.

## 60 help/*.HLP, *.HRU, *.HES

- REPORTED 2026-11-01 IPCONFIG and NETSTAT have no help page at all (HELP IPCONFIG says nothing is
  known).
- REPORTED 2026-11-01 Pages with no ^Z end (the analysis said twelve; it named eighteen: ASK, COPY,
  MODEL, MOUNT, NEURAL, PET, PLUTO, PROBE, RAT, RATBOX, RATS, RAWYANG, RAWYING, RVDU, TASKMAN, WATCH,
  YANG, YING): fine on UniDOS (exact lengths) but on a plain AMSDOS disc the last 128-byte record's
  padding shows after the text.
- REPORTED 2026-11-01 Five pages are LF-only (HELP, MOUNT, PLUTO, RVDU, TASKMAN) where the rest are
  CR LF; they display because the console treats LF as a new line, but TYPE to a printer or a CP/M
  tool sees one long line. Make them CR LF like the others. (HELP, MOUNT and RVDU were Claude Opus's
  edits of 2026-10-29: a rewrite that dropped the CRs, and MOUNT written new with LF.)
- REPORTED 2026-11-01 Lines over 78 characters wrap on an 80-column screen: DUMP.HLP line 9,
  REVIVE.HLP line 9, SPEED.HLP line 5 (the LF-only files too, to be re-checked once fixed).
- REPORTED 2026-11-01 Only 6 of 56 pages exist in Russian and Spanish (HELP, LANG, DIR, TYPE, PS,
  AUTOEXEC); the other 50 fall back to English - also on the todo (60).

## 61 lang/KOI8.FNR, LATIN1.FNR

- REPORTED 2026-11-01 LATIN1.FNR leaves ten Latin-1 letters blank: µ Æ Ð Ø Þ ß æ ð ø þ. None is
  Spanish, so nothing shows wrong today; a German or Nordic page would. Draw them or document the
  limit.

## 62-65 The test suites (bugs in the suites, not the code)

Coverage (2026-11-01): the CPC suite (62) runs 50 tests - DIR, PS, MEM, TOP, HELP, TYPE, DRIVE,
CLAIMS, MODE, CV, CD, RAMDISC with COPY / RENAME / ERA, RUN / KILL / PAUSE / DUMP / REVIVE, LINES,
CRUNCH, the network (NET, IPCONFIG, NETSTAT, the four browsers against a local web server), the rat
set (ASK, RATS with MODEL and RAT, PROBE, WATCH), the ROM-RAM boot and the V9990 console. The MSX
suite (63) 28 of the same plus MKDIR / RMDIR, CD, MODE S. The vCPC suite (64) 15: PS, DIR, HELP,
IPCONFIG, GUI with GUIDEMO, MEM, SPEED, RATS, PAUSE, DUMP, RMOVE, RCOPY (right and wrong word, a
file). The Next (65): the slot keys and MON, plus nextrun for a look.

- REPORTED 2026-11-01 Never exercised anywhere: FG, RESET, WAIT, FLOPPY, MOUNT, LANG (RU / ES on the
  CPC and MSX; the Next only by nextrun's eye), AUTOEXEC's file (only its silent absence), MON2,
  NEURAL, PET, GREEN, RATBOX, RVDU, TASKMAN, ENC / DEC, KEYMGR / KEYMAN, GUI on the CPC and Next
  (vCPC only), SLOTD on a CPC (vCPC only), the hardware tests (hardware). Of these, LANG, FG, RESET,
  AUTOEXEC, MON2, ENC / DEC and GUI on the CPC can be added to cosregress today with a reference
  each; the rest need either a second machine or hardware.
- REPORTED 2026-11-01 (65) nextrun.js takes pictures and compares nothing: a Next change is "tested"
  only if someone looks. It wants a reference per scenario (the tile map read from the Next's RAM
  through ZRCP as text, like the CPC's screens) so a difference fails the run.
- REPORTED 2026-11-01 (65) nextkeys.js and nextrun.js boot on fixed sleeps (30 s to the video-mode
  prompt, 12 s to NextZXOS's menu, 25 s to CyborgOS): a slower or faster host, or a longer boot, and
  the keys land on the wrong screen (seen today: a command typed on the TBBlue splash put the Next in
  its video test card). Poll the Next's RAM (the kernel's front slot word) instead of sleeping.
- REPORTED 2026-11-01 (62) cosregress's references are the whole screen, so a harmless change (a new
  file in DIR, a count in QUIT) fails many tests at once and they are re-recorded in a batch - which
  is where a real change hides. A mask per test for the known-volatile parts (as ratsMask and
  noCursor already do) would keep the references stable.
- REPORTED 2026-11-01 (63) msxregress waits a fixed number of milliseconds per test (150 to 8000): a
  slow command on a loaded host reads the screen early and fails or, worse, reads it late and passes
  the wrong state. Poll for the prompt as the CPC harness does.
- REPORTED 2026-11-01 (64) vcpctest checks one substring per test: a test passes while the rest of
  the screen is wrong. Compare whole screens with references, like the other two.
- REPORTED 2026-11-01 (all four) No suite checks that what it boots is the build just made:
  cosregress installs from build/dsk, the Next from cards/*.zip (which cards.sh can leave stale, 58),
  the vCPC from build/next/CYBORGOS. A stamp (the build's time in HELP's first line, say) checked by
  each suite would catch a stale image.

## 66 espsim

- REPORTED 2026-11-01 Its own nettest.js wasn't run in the analysis: add it to the regression runs
  with the other four. (Nothing found in espsim itself; the CPC suite's network tests use it.)

## 67 docs/cyborgos-todo.md

- FIXED 2026-11-01 Four sections in the wrong order ("next", "ideas", 945 lines of "done", then
  "todo"): the open work split, new work going into "done". Now one open list by component and the
  done history in cyborgos-done.md (Claude Opus, this copy).
- REPORTED 2026-11-01 Nothing links the three: an open todo item fixed (TOP open-only, the console
  page, the MSX Shift, upper-casing) is in "done" and its todo line stays; a bug fixed from the
  buglist is noted in "done" but the buglist entry is removed without a pointer. Each fix: one line
  in done, the open line removed, the buglist entry marked FIXED with the date, then moved.

## 68 docs/buglist.md

- FIXED 2026-11-01 Two authors, two verdicts: on the Next's height one entry said "no change visible"
  (wrong - the height was cut by an earlier port session, as the fuller entry says), and two entries
  on MEM's 4 MB map. This copy keeps only the fuller entries (under 4 and 1).
- FIXED 2026-11-01 Headings at two levels under "## open", "by design" in the middle: now one level,
  a section a component, entries as bullets with their state, "by design" at the end.

## 69 docs/components.md

- REPORTED 2026-11-01 Documents not in the list: cyborgos.md, cyborgos-userguide.md,
  cyborgos-decisions.md, cyborgos-hardware.md, cyborgos-pi.md, cyborgos-gui.md,
  cyborgos-moving-slots.md, cyborgos-msx-port.md, cyborgos-next-port.md,
  cyborgos-next-update-2026-10-22.md, cvm.md, pluto.md, tools/regress/README.md, and the vCPC's own
  cyborg-os-vcpc/docs/cyborgos-vcpc-todo.md. (The analysis said "71 on": 71-85 are taken now - the
  unnumbered components and the future ones - so 86 on.)
- REPORTED 2026-11-01 12-46 pack several commands a row (a table now, three a row): a command's
  number is hard to find by eye. One a line. (Every .bas in cmds/ and apps/ is named somewhere:
  checked.)

## 70 ANALYSIS.LOG

- REPORTED 2026-11-01 Entries say what was done and the method, not which files changed: for "which
  model did what" a file list per entry is the useful part. Add "files:" to each.
- REPORTED 2026-11-01 The model's name is what the session reports of itself ("Claude Fable 5.1"); it
  can't be verified from inside the session, and a routed reply would carry the same name. Note it
  in the log's header so the reader knows the limit. (ANALYSIS.LOG isn't in this copy.)

## analysed, nothing found (2026-11-01)

26 PS, 27 TOP, 29 MODE, 30 CLAIMS, 33 RESET, 34 PAUSE / UNPAUSE, 35 WAIT, 36 SPEED, 40 NET,
41 IPCONFIG, 42 NETSTAT, 43 LANG; 47 MON, MON2 (the slot checked, 8-9 places each), YANG, 54 GUI,
GUIDEMO (the slot checked in 9 places, its 1K header buffer bounded). Checked sound: Bml's page writer
(pgn < pgm), its 120 links and its lines bounded; YING's page buffer (#BE00, 7678 bytes, ends #DBFD
under the TPA's end); Zc's Encode / Decode (an output maximum, -1 on bad input or a short key);
55 COSLOAD (Z's last page the machine's last - pmax = 4 x banks + 1 -, slots half the banks capped
at 20, refused under 8 banks and when Z can't fit above page 5), 57 Z and nexarc, 59 the builder;
cpcimg (58: "the image is full" rather than a short file); INSTALL.BAS's DISK.DAT read (ON ERROR
GOTO 690); 60: every name in HELP.HLP's index has a page, the Russian pages pure KOI8-R and the
Spanish pure Latin-1 (no C1 control bytes); 61: every Russian letter has a glyph (KOI8.FNR: none
blank), and every character the Russian and Spanish pages use has one. (12 HELP, 20 MKDIR, 21 RMDIR, 22 DRIVE, 23 MOUNT, 24 FLOPPY: not
named in the analysis either way.)
Method: every command scanned for an argument taken with Val and no range check, file results
ignored, string limits, fixed lists and buffers, timeouts; the flagged ones read. The slot numbers
of KILL, FG, PAUSE, RESET and SPEED are checked by the kernel (1..ns, else 255). 45 and 46 (hardware
and test programs) not analysed.

## by design, so people stop reporting them

- 4: The Next's slot keys are Caps Shift + 0 (TOP) then the number; Caps Shift + a number doesn't
  switch (2 is CAPS LOCK, 5-8 the cursor keys). nextkeys.js checks that.
- 59: the builder's NTC copy is refreshed by hand (`cli.js ntc PATH`): a stale copy builds silently
  with an older compiler.
- 1: 576K is 3 slots and Z (the 4th slot was never usable: COSLOAD put Z's pages over it); 1024K 7.
