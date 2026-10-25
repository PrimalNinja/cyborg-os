# CyborgOS Builder

A build in steps: NTC BASIC projects compiled with NTC's own JS, external tools (sjasmplus), and the
packager's parts (CPC discs, the Next's card, images). The build is a CyborgDesigner layout -
`CyborgOS.layout.json` here - of stages, steps and parts.

```
tools/cosbuild/
  CyborgOS.layout.json        CyborgOS's build (the layout)
  src/
    cosbuild.html             THE BUILDER - open it in a browser (no node, no server)
    cli.js                    the same build from node (loads the same js/ files)
    js/cos_core.js            DSK, AMSDOS, Z packed, the Next's archive, INSTALL.BAS, FAT images, zip, compile
    js/cos_build.js           the part datatypes and the run
    js/cos_gui.js             the page
    js/ntc_*.js textEditor.js listRenderer.js   NTC's (node src/cli.js ntc NTC_SRC refreshes them)
    js/utils.js cyborgDesigner.js               CyborgDesigner's
    css/                      cos.css, NTC's textEditor.css, listRenderer.css, CyborgDesigner's
    3p/                       jQuery, Bootstrap
```

## Building CyborgOS in the browser (Chrome or Edge)

1. Open `tools/cosbuild/src/cosbuild.html` (double-click it).
2. **Open the CyborgOS folder...** - pick the top folder (the one with `src/` and `tools/` in it).
   Allow it to view and save files. The project and its layout (`CyborgOS.layout.json`) load.
3. **Build** tab: **Run**. It compiles everything and writes `build/stage/`, then stops:
   *waits at assemble1: run assemble1.bat (or .sh) in .../build/stage*.
4. Run `build/stage/assemble1.bat` (Windows, double-click) or `sh build/stage/assemble1.sh`.
   It uses `%SJASMPLUS%`, else `sjasmplus\sjasmplus.exe` in the top folder, else sjasmplus on the PATH.
5. **Run** again - it stops at assemble2 the same way; run `assemble2.bat` / `.sh`.
6. **Run** again - *done*. Everything is in `build/`: `dsk/cos-disk1..7.dsk`, `next/CYBORGOS/`,
   `next/z/CYBORGOS/`, the NEX files and, if `build/next/cyborgos-next-sd.img` is there to start
   from, the card images.

Edits made in Files or Design are written back to the folder. Other browsers (Firefox, Safari) can
only read the folder: Open folder reads it, Stage .zip / Attach the stage folder replace steps 3-5,
build/ .zip downloads the result.

## Building from node (no browser)

`node tools/cosbuild/src/cli.js build` - the whole run, the sjasmplus steps included (sjasmplus on the
PATH or `SJASMPLUS=`). Other commands: `check` (files missing, files no part uses), `parts`, `run`
(one pass - stops where it waits), `ntc NTC_SRC` (NTC's components from an NTC checkout), `dsk`,
`img`, `install`. No command: the list. cli.js runs the same js/ files the page loads.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License
