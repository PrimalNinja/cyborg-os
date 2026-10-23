# CyborgOS Builder

A build in steps: NTC BASIC projects compiled with NTC's own JS, external tools (sjasmplus), and the
packager's parts (CPC discs, the Next's card, images). The build is a CyborgDesigner layout -
`CyborgOS.layout.json` here - of stages, steps and parts.

```
tools/cosbuild/
  CyborgOS.layout.json        CyborgOS's build
  CyborgOSBuilder.htm         the one file (made by src/make.js): the page, the project, node
  src/
    cosbuild.html             the page (loads the files below, as NTC's ntc.html does)
    js/cos_core.js            DSK, AMSDOS, Z packed, the Next's archive, INSTALL.BAS, FAT images, zip, compile
    js/cos_build.js           the part datatypes and the run
    js/cos_node.js            the node commands
    js/cos_gui.js             the page
    js/ntc_*.js textEditor.js listRenderer.js   NTC's (node src/cli.js ntc NTC_SRC refreshes them)
    js/utils.js cyborgDesigner.js               CyborgDesigner's
    css/                      cos.css, NTC's textEditor.css, listRenderer.css, CyborgDesigner's
    3p/                       jQuery, Bootstrap
    cli.js                    node, from the sources (the project read from the top folder each time)
    make.js                   ../CyborgOSBuilder.htm: everything put in one file, with the project
```

- Edit `src/js/...`, open `src/cosbuild.html` (Files: Import the top folder), or
  `node tools/cosbuild/src/cli.js build` - all of it, sjasmplus on the PATH (or `SJASMPLUS=`).
- `node tools/cosbuild/src/make.js` - the one file again (`CyborgOSBuilder.htm`), with the project
  as the top folder has it now. From it: `node -e "f='CyborgOSBuilder.htm';eval(require('fs').readFileSync(f,'utf8').split('/*NODE'+'*/')[1])" build`
- Commands (both): import, check, parts, run, build, ntc, dsk, img, install - `js/cos_node.js` says what each does.

(c) 2026 Cyborg Unicorn Pty Ltd - MIT License
