# CyborgOS - known bugs

Bugs seen and not yet fixed, by component - the numbers are [components.md](components.md)'s, the
same as the todo's (cyborgos-todo.md: work to do; this: things that are wrong). Newest first in each.
A fixed one moves to cyborgos-done.md. Each bug carries its state: REPORTED (seen, not yet
confirmed or traced), CONFIRMED (reproduced or found in the code), FIXED (moving to done).
2026-11-01 (evening): every entry checked (ANALYSIS.LOG: how, and the files) - the real ones fixed,
the wrong ones marked NOT A BUG with why, work that isn't a fault moved to cyborgos-todo.md.

## all hypervisors (1-6): a rule

- FIXED 2026-11-01 (the one left: Hyp.Mark, under 4) (analysis of components 1-7) RULE, proven on NTC's test platform: a push or
  pop in an #asm block whose SP is the thread corrupts the thread words before the block - it works
  once and breaks on the next run (a loop of three calls printed garbage and hung). The cause of the
  ConClear (1) and Tiles (4) crashes. Blocks that switch SP first (Con, Say, Scr, KeyRep, Run, Go,
  FileCall, FileShut, Svc, Vdu, KRun), that pop a parameter word put in the thread on purpose
  (Info, Seg), or that push inside an interrupt routine (KInit's ki_isr) are sound.
  NTC's compiler now warns (push, call, rst, ex (sp) in an #asm block before it switches SP): every
  CyborgOS project compiled with it - one warning, Hyp.Mark's, now fixed.

## 1 C0 CPC 320K+

- FIXED (shown, not cured) 2026-11-01 A 4 MB CPC (Julian's WinAPE): MEM shows "Total 4160 KB, Free 320 KB" and a map
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
  Now MEM says it: "Not mapped: nK (no room for their page tables)" under the totals - C0's
  MEMINFO gives Memory.PagesCut() (NTC's new call), the kernel puts it in op 7's answer (word 60 of
  CybSys's block; the C0 build's own op 7 too). Getting those pages back needs room for the
  tables under HIMEM - asked (ANALYSIS.LOG's questions).
- REPORTED 2026-10-30 The CPC loses keys held less than ~40 ms while another slot is busy (the
  firmware's scan doesn't run in a busy slot's slice). Julian: seems to work; left as seen.
  (2026-11-01: not reproduced; left open on Julian's word.)

## 2 C0 CPC flat

- NOT A BUG 2026-11-01 "The C0 build's BOOTDONE (op 33) never sets kw(9), so AUTOEXEC runs by chance."
  The C0 build has no kernel (cyborgosc0/Main.bas: "all of it in main RAM, no kernel bank"),
  no op 33 and no AUTOEXEC at all - nothing reads kw(9) there. (No AUTOEXEC on the C0 build:
  the todo, 2.)

## 3 C0 CPC 128K

- CONFIRMED 2026-11-01 (a question: build it or retire it) The 128K C0 isn't in the build at all (no layout project): kept source, never
  compiled - it has none of this year's ops (42 and the rest). Either build it or mark it retired.

## 4 C0 ZX Spectrum Next

- CONFIRMED 2026-11-01 (a question: MODE P the default?) The Next's console isn't full height (Julian): it was 40 x 32 (the whole
  tilemap) in the first Next build; a port session made every Next mode its CPC rows, so MODE S is
  80 x 24 + the strip, 8 tilemap rows unused. The console page is 2K: 80 x 32 doesn't fit, 64 x 32
  does. Proposed: MODE P (64 x 32) as the Next's default.
- FIXED 2026-11-01 Hyp.Mark on the Next (a DIAG routine, no callers) pushes IX and IY with no SP
  switch (and calls gfx_map): it would corrupt the thread on its second call. Now it goes onto the
  real stack first (ld (hsp), sp : ld sp, (ntc_csp)) and back at the end, as Con does. Compiled
  only: nothing calls it. NTC's new warning is gone from the build.
- (moved to the todo 2026-11-01: the Next and the MSX receiving slots is work not done - 4, 5, 39)

## 5 C0 MSX

- (moved to the todo 2026-11-01: the GR8NET driver - work not done, and C0 says so)
- (The MSX can't receive slots: see 4.)

## 6 C0 vCPC

- FIXED (to try on Windows) 2026-11-01 Typed Cyrillic and accents on the vCPC under Windows: _getch
  gives the OEM code page's bytes, so LANG RU / ES text can't be typed there (it shows). The
  ReadConsoleInputW reading was reverted: it broke Control + T. Now _getwch (_getch's wide twin:
  the same control codes - Control + T 20 - and the same 0 / 224 before an extended key), a typed
  letter sent on as UTF-8 like a Unix terminal's. A lone 224 is a typed a-grave (U+00E0), not an
  extended key (whose code is waiting already). Built for Windows (MinGW): compiles clean; not run
  on a Windows console here - Julian to try (cyborg-os-vcpc, src/compat.h).
- (moved to the todo 2026-11-01: RAMDISC on the vCPC - not written yet, the vCPC's todo has it; the
  message is the right one)

## 7 The kernel

- (The thread rule above covers the kernel's own #asm blocks too.)

## 8 CybSys.cls

- FIXED 2026-11-01 (not as reported) CybSys.TextAt's String Max 60 is no limit: its block, b(), is 64
  bytes, so text at 4 or 8 is 59 or 55 at most. The real fault: nothing stopped a longer answer -
  the kernel's PutEn wrote Len + 1 bytes into the slot's block, past its end into the program's
  other variables, and TextAt read b(i + k) past b(63) when the length byte said so. Now PutEn
  (C2 and C0) cuts the text at 51 (op 7's word at 60 kept free) and TextAt stops at b(63).

## 9 CybDir.cls, CybVol.cls

- NOT A BUG 2026-11-01 "CybDir / CybVol keep paths in String Max 40: a path over 40 is cut." A
  UniDOS path is 31 characters at most and CybVol checks it with a message ("A path is 31
  characters at most": SelectPath, the folder letters; CybDir.Into: over 31 refused). 40 holds any
  path a device gives back.

## 10 Http.cls

- FIXED 2026-11-01 Http.Get / Post: when the answer is longer than the caller's buffer the loop
  stopped at the buffer's end and returned the part it had as if it were the whole page. Now
  Http.Cut() says so (True: the buffer filled before the answer's end - the length the server gave
  says it all came, or the socket still open with more). NET GET prints "(cut: longer than 16K)";
  YING and YANG say "The page is cut" on the status line (Web.Cut()). cosregress: net_cut.

## 11 SlotFrame.cls

- FIXED (in part) 2026-11-01 SlotFrame recognises a CPC frame by the word on top of the slot's stack
  matching sb_rest or sb_far (the stubs' return points): a program stopped by neither (a key wait
  tried again) is refused ("try again") - right - but a program whose own data happens to equal one
  of those addresses at the top of its stack would be read as a frame and revived wrong. Unlikely;
  a second check (SP's range, the saved PC inside the TPA) would close it. Now Canon refuses a
  stack pointer outside #0100-#FFE0 (a frame lies under #FFFE in the slot's own RAM). The PC isn't
  checked: an interrupted program can be anywhere, the stubs and the BDOS too. The coincidence
  itself can't be closed without C0 saying how the slot stopped.
- FIXED 2026-11-01 SlotFrame.GetW's comment said the byte-array case is an NTC bug "noted": now it
  says NTC's compiler was fixed (2026-11-01 - the first fix covered a local array only, the second
  this one: an array parameter with an index expression); the two-variable form kept.

## 13 DIR, 14 CD, 15 CV, 16 TYPE, 18 ERA, 19 RENAME

- FIXED (another way) 2026-11-01 "Paths in String Max 40 are cut silently." Paths: not a bug (9). But
  the command line itself was cut at the string's size (40, CD and CV 60): a name past it was cut,
  and a cut name is another file - ERA, RENAME and COPY could act on the wrong one. Those three now
  refuse a line longer than they hold ("the line is too long (40 characters at most)" - the
  tail's length read at #0080, CP/M's). DIR, TYPE, CD and CV left as they were: they only read or
  list, CD and CV check 31, and the Next's boot archive had no room (CYBORGOS.ARC, 160K: full).

## 17 COPY

- FIXED 2026-11-01 COPY . on a folder with more than 64 matching files copied the first 64 and said
  nothing about the rest. Now: "64 files at a time: n more fit and are not copied (a narrower
  pattern for them)".

## 25 RAMDISC

- (On the vCPC: "RAMDISC needs CyborgOS 320K" - see 6.)

## 28 MEM

- (A 4 MB CPC: the map and the totals disagree - see 1.)

## 31 FG, 32 KILL

- FIXED 2026-11-01 With no argument the message was "nothing running in slot " / "no slot " with
  nothing after it. Now a slot under 1 prints the usage ("KILL slot   (its program stopped: PS
  lists them)"). cosregress: usage.

## 37 DUMP / REVIVE

- NOT A BUG 2026-11-01 "REVIVE reads the 128-byte header without checking the count." It does:
  DUMP.bas, If r <> 128 Or a <> "CYBDUMP1" Then ... "is no dump" - the count and the signature
  together, before anything is used.
- FIXED 2026-11-01 DUMP wrote the header without checking the count; a disc that filled there lost
  it silently (the body's writes were checked). Now the header's write is checked too: the file
  deleted, "the disc is full - not dumped". (The console state is in the header - bytes 10-21 -
  not a block of its own.)

## 38 RMOVE / RCOPY

- REPORTED 2026-11-01 (a test not written - moved to the todo too) vCPC -> CPC live move: the CPC's SLOTD takes the slot (OK answered) but the
  program running there hasn't been seen: the harness's typed keys are lost while a slot is busy,
  and holding them long enough breaks the boot's own typed command. Needs a keyboard-free check.
- REPORTED 2026-11-01 (the environment - the todo too) CPC -> CPC live move: never shown working (two 1984 processes on one host
  don't connect - an environment problem as far as is known, not a CyborgOS one).

## 39 SLOTD

- BY DESIGN 2026-11-01 (moved below) A sender that stops mid-transfer leaves SLOTD waiting 20 s.

## 44 AUTOEXEC

- FIXED (the page) 2026-11-01 AUTOEXEC's lines are typed into slot 1 only - by design; HELP AUTOEXEC
  didn't say. Now it does ("Every line goes to slot 1; a program for another slot: RUN n NAME"),
  and that the MSX always runs it. (The Russian and Spanish pages not changed: English only.)

## 48 YING / YANG, RAWYING / RAWYANG

- FIXED 2026-11-01 A page longer than YING's buffer arrived cut and YING showed it as whole. Now
  YING and YANG put "The page is cut: longer than 7.5K (shown as far as it fits)" on the status line
  (Web.Cut(), from Http.Cut()). At the page's end was the plan: the cut can fall inside an element,
  so a mark there could be swallowed - the status line can't.

## 49 RAT, RATS, RATBOX, MODEL

- FIXED 2026-11-01 MODEL read a .LUN file's 7-byte header and then k x nn bytes without testing
  either count. Now both counts are required; a short file prints "NAME.LUN is cut - its LUNs not
  used" and no LUN is marked loaded (li() stays 0: the model's own weights are used, and copied in
  when a LUN is first changed - as for a model with no .LUN).

## 50 NEURAL, ASK, WATCH, PET, PROBE, GREEN

- FIXED 2026-11-01 PET and RATBOX read their saved state (PET.SAV, RATBOX.SAV - not the .MDL) with
  Val and few checks. PET: the counts were capped (np to 8) - now np under 0 too, the poos' places
  kept inside the room, the five needs 0-100 (Lim, as play keeps them). RATBOX: a rat's place kept
  inside the room. And a real overrun found reading it: RATBOX takes its rat count from the model's
  LUNs (up to 249) into arrays of MAXR (100) - topr now capped at MAXR.

## 52 TASKMAN

- REPORTED 2026-10-30 (a test not done - the todo too) TASKMAN's VDU path never tried against a real VDU server. (51 RVDU: nothing
  found in the code; the same path, also untried against a real server.)

## 53 ENC / DEC, KEYMGR / KEYMAN

- NOT A BUG 2026-11-01 (a note, as it said) KEYMAN keeps the key pool in a 16K byte array and KEYMGR
  two 8K ones in the TPA: with the program's own code these are near the TPA's limit on a 64K slot;
  fine today, no room to grow - worth a note in each file.

## 53 ENC / DEC, KEYMGR / KEYMAN

- CONFIRMED 2026-11-02 KEYMAN refuses a key of 8K or more: LoadKey reads KEYMAXB (8192) at most and
  `If n <= 0 Or n >= KEYMAXB Then Exit Function` - so 8192 bytes exactly (an 8K ROM) is refused
  too, and the pool (16K in the TPA) holds two such keys at most. HELP PLUTO promises "4K, 64K,
  128K" keys; docs/pluto.md says ~8K. And a key too big answers "? bad layer z:NAME", the same as
  no such key: nothing says "too big". Fix: the keys in the slot's store (op 12: up to 512K), Zc
  reading key bytes through a 2K window (op 14) instead of a pointer; a "? key too big" / "? no
  such key" told apart. (The earlier note under 53, "near the TPA's limit", understated it.)

## 56 INSTALL.BAS

- FIXED (to try on a CPC) 2026-11-01 A file missing from a disc (|COPY fails) was not trapped. Now ON
  ERROR GOTO round each |COPY: "Not copied: NAME", counted, the install goes on, and the end says
  how many weren't. Whether UniDOS's |COPY raises a BASIC error on a failure (or only prints its
  own) isn't known here - no UniDOS to run it on.

## 58 The CPC discs and the Next's SD card (cards.sh)

- FIXED 2026-11-01 cards.sh masked a failed build: `node cli.js build | grep ... || true` hides the
  builder's exit status, so with set -e a build that stops still has its images tidied, zipped and
  shipped - with the old files in them. Should fail when the builder does (pipefail, or test the
  builder's output for "stopped" / "error" and exit 1). Now the builder's output goes to
  build/cards-build.log and its exit status is tested: a stopped build stops cards.sh, nothing
  zipped. (The builder does exit 1 when it stops - cli.js.)
- FIXED 2026-11-01 cards.sh's tidy took files gone from the build out of /CYBORGOS and
  /CYBORGOS/C only: /CYBORGOS/HELP (and any other folder) keeps stale files from older images - an
  old help page nobody deleted stays on the card for ever. Tidy HELP too (and the language pages
  .HRU / .HES). Now /CYBORGOS/HELP is tidied too (all three kinds of page).
- FIXED (documented) 2026-11-01 The Next card's base (its NEXTZXOS folder and system files) exists only inside
  cards/cyborgos-next-sd.img.zip, which cards.sh takes as its own base each time: a corrupted or
  lost zip has no other source in the repo (sdimage.py expects a tbblue.mmc nobody keeps). Keep the
  base image (or the NEXTZXOS files) under tools/ or document where they come from. Now cards.sh's
  header says: the two zips are the only copy (keep them); to start again, ZEsarUX's tbblue.mmc
  through tools/nexarc/sdimage.py.

## 59 The builder

- FIXED 2026-11-02 (found) A card folder (build/next/CYBORGOS, next/z/CYBORGOS, msx/CYBORGOS) kept
  files gone from its set: the builder wrote the set over the folder and took nothing out, so
  HOME.RAW and KEYS.RAW stayed after RAWYING stopped using them - in the MSX's folder (msxregress's
  dir reference had KEYS.RAW) and, through cards.sh, on the Next's card. Now cli.js takes a file
  out of a card folder when it isn't in the set ("gone ..."). (The builder's page, cos_gui.js,
  writes through the browser: not changed.)

## 60 help/*.HLP, *.HRU, *.HES

- FIXED 2026-11-01 IPCONFIG and NETSTAT had no help page at all (HELP IPCONFIG says nothing is
  known). Now both have one (on the CPC's disc 1, both builds: the Next's, MSX's and vCPC's sets
  come from there). cosregress: usage.
- FIXED 2026-11-01 Pages with no ^Z end (the analysis said twelve; it named eighteen: ASK, COPY,
  MODEL, MOUNT, NEURAL, PET, PLUTO, PROBE, RAT, RATBOX, RATS, RAWYANG, RAWYING, RVDU, TASKMAN, WATCH,
  YANG, YING): fine on UniDOS (exact lengths) but on a plain AMSDOS disc the last 128-byte record's
  padding shows after the text. Now every page ends CR LF ^Z.
- FIXED 2026-11-01 Five pages were LF-only (HELP, MOUNT, PLUTO, RVDU, TASKMAN) where the rest are
  CR LF; they display because the console treats LF as a new line, but TYPE to a printer or a CP/M
  tool sees one long line. Make them CR LF like the others. (HELP, MOUNT and RVDU were Claude Opus's
  edits of 2026-10-29: a rewrite that dropped the CRs, and MOUNT written new with LF.) Now CR LF.
- FIXED 2026-11-01 Lines over 78 characters wrap on an 80-column screen: DUMP.HLP line 9,
  REVIVE.HLP line 9, SPEED.HLP line 5 (the LF-only files too, to be re-checked once fixed). Of
  these only HELP.HLP's two (82 and 79) go past 78 in a way that matters (the others are 79); all
  re-wrapped to 78 at most. Checked: no page has a line over 78 now.
- REPORTED 2026-11-01 (work, not a fault: the todo has it) Only 6 of 56 pages exist in Russian and Spanish (HELP, LANG, DIR, TYPE, PS,
  AUTOEXEC); the other 50 fall back to English - also on the todo (60).

## 61 lang/KOI8.FNR, LATIN1.FNR

- FIXED 2026-11-01 LATIN1.FNR left ten Latin-1 letters blank: µ Æ Ð Ø Þ ß æ ð ø þ. Now drawn
  (lang/mkfont.py: L1, original 8 x 8 glyphs in the CPC font's style); LATIN1.FNR 252 -> 332 bytes
  (LANG's buffer is 600); KOI8.FNR made again, byte for byte the same. Still blank: Latin-1's
  symbols (¢ ¤ ¥ ¦ § ¨ © ¬ ® ¯ ± ² ³ ´ ¶ · ¸ ¹ ¼ ½ ¾ × ÷) - no page uses them.

## 62-65 The test suites (bugs in the suites, not the code)

Coverage (2026-11-01): the CPC suite (62) runs 50 tests - DIR, PS, MEM, TOP, HELP, TYPE, DRIVE,
CLAIMS, MODE, CV, CD, RAMDISC with COPY / RENAME / ERA, RUN / KILL / PAUSE / DUMP / REVIVE, LINES,
CRUNCH, the network (NET, IPCONFIG, NETSTAT, the four browsers against a local web server), the rat
set (ASK, RATS with MODEL and RAT, PROBE, WATCH), the ROM-RAM boot and the V9990 console. The MSX
suite (63) 28 of the same plus MKDIR / RMDIR, CD, MODE S. The vCPC suite (64) 15: PS, DIR, HELP,
IPCONFIG, GUI with GUIDEMO, MEM, SPEED, RATS, PAUSE, DUMP, RMOVE, RCOPY (right and wrong word, a
file). The Next (65): the slot keys and MON, plus nextrun for a look.

- FIXED 2026-11-01 (found running them) (62) The help tests (help, helpdir, zhelp, v9_help) had
  references of HELP failing: "No help for HELP.HLP". HELP looks in A:HELP/ through a drive letter
  UniDOS gives the folder, and the harness's UniDOS stand-in can't put a path on a letter - so the
  suite passed HELP showing nothing. Now cosregress puts the pages on A's top for the help tests
  only (DIR lists A) and takes them off after: the page, its wrapping and -- more -- are checked.
  (The harness's UniDOS getting folder letters is the proper fix: NTC's ntcrun.py, Ctrl J.)
- FIXED 2026-11-01 (62) A test's footer "typed left=n" (keys the harness hadn't typed when time ran
  out) went into the comparison: dump failed at 382 against 384, the screen the same. Masked, in
  the reference too. And only the first "Average" line of a screen was masked: all are now.
- FIXED 2026-11-01 (62) The C0 build's suite (--dsk=build/dskc0) had one reference of its own
  (mem, 29 October) and failed 40 of 46: its screens differ (4 slots at 576K, no kernel bank).
  Checked against the build before this pass: the same but for this pass's changes. Recorded.
- FIXED 2026-11-01 (63) msxregress's dir, cd and v9_dir references were cut mid-listing (400 / 500
  frames: DIR not done) - a change in speed failed them. Now 1000 / 1500 frames: each ends at its
  prompt. (The fixed frame counts themselves: still the entry below.)

(2026-11-01: the entries below are test work, not faults in CyborgOS - each is in the todo too
(62-66); left here as REPORTED until the suites are changed.)

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
- FIXED (by doing it) 2026-11-01 Nothing linked the three: an open todo item fixed (TOP open-only, the console
  page, the MSX Shift, upper-casing) is in "done" and its todo line stays; a bug fixed from the
  buglist is noted in "done" but the buglist entry is removed without a pointer. Each fix: one line
  in done, the open line removed, the buglist entry marked FIXED with the date, then moved. Done
  that way from this pass on: FIXED here with the date and how, a line in cyborgos-done.md.

## 68 docs/buglist.md

- FIXED 2026-11-01 Two authors, two verdicts: on the Next's height one entry said "no change visible"
  (wrong - the height was cut by an earlier port session, as the fuller entry says), and two entries
  on MEM's 4 MB map. This copy keeps only the fuller entries (under 4 and 1).
- FIXED 2026-11-01 Headings at two levels under "## open", "by design" in the middle: now one level,
  a section a component, entries as bullets with their state, "by design" at the end.

## 69 docs/components.md

- FIXED 2026-11-01 Documents not in the list: cyborgos.md, cyborgos-userguide.md,
  cyborgos-decisions.md, cyborgos-hardware.md, cyborgos-pi.md, cyborgos-gui.md,
  cyborgos-moving-slots.md, cyborgos-msx-port.md, cyborgos-next-port.md,
  cyborgos-next-update-2026-10-22.md, cvm.md, pluto.md, tools/regress/README.md, and the vCPC's own
  cyborg-os-vcpc/docs/cyborgos-vcpc-todo.md. (The analysis said "71 on": 71-85 are taken now - the
  unnumbered components and the future ones - so 86 on.) Now 86-99 in components.md.
- FIXED 2026-11-01 12-46 packed several commands a row (a table now, three a row): a command's
  number is hard to find by eye. One a line. (Every .bas in cmds/ and apps/ is named somewhere:
  checked.) Now one a line.

## 70 ANALYSIS.LOG

- FIXED 2026-11-01 Entries said what was done and the method, not which files changed: for "which
  model did what" a file list per entry is the useful part. Add "files:" to each. From this entry
  on each says its files (the earlier ones aren't rewritten: they are what was written then).
- FIXED 2026-11-01 The model's name is what the session reports of itself ("Claude Fable 5.1"); it
  can't be verified from inside the session, and a routed reply would carry the same name. Note it
  in the log's header so the reader knows the limit. Its header says so now.

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

## generative (GEN, MIND, GRU)

- FIXED 2026-11-04 the shipped GEN.MDL was an undertrained run: greedy decode (noise 0) collapsed
  to predicting spaces, so GEN/GRU wrote blank. Three things fixed it: (1) a focused corpus a small
  net can learn (tools/gen/gen_focus.py); (2) a sharper training loss (train.py --losstemp 6 instead
  of a fixed /16 - gradient shaping only, the exported integer model is unchanged); (3) 2 trits a
  weight (--trits 2: 9 levels not 3) - at 1 trit the net learned a keyword's shape but dropped
  letters ("Froo" for "For"), 9 levels made the right character win. The shipped GEN/CYNTHIA are
  H=64, 2-trit, ~29.5K (fit the 32K a slot loads); GEN writes clean NTC BASIC ("For i = 1 To 10" ->
  "Print i / Next"), CYNTHIA is a weaker chitchat toy (its corpus is harder). A genuinely strong
  model is a wider, store-backed one - cyborgos-generative.md section 4.
- the H=96 GEN net is ~10 min a character in the CPC interpreter harness (cosregress), so the full
  model is not tested there; net_t (H=16) covers Net inference on the CPC, vcpctest.sh runs the
  full GRU<->MIND path at speed on the vCPC. By design, not a bug.

## by design, so people stop reporting them

- 4: The Next's slot keys are Caps Shift + 0 (TOP) then the number; Caps Shift + a number doesn't
  switch (2 is CAPS LOCK, 5-8 the cursor keys). nextkeys.js checks that.
- 59: the builder's NTC copy is refreshed by hand (`cli.js ntc PATH`): a stale copy builds silently
  with an older compiler.
- 39: a sender that stops mid-transfer leaves SLOTD waiting 20 s a block before the slot it
  opened is reset - fine for one, slow for a flood (2026-11-01, from the list above).
- 1: 576K is 3 slots and Z (the 4th slot was never usable: COSLOAD put Z's pages over it); 1024K 7.
