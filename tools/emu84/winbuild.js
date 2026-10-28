// winbuild.js - 1984 for Windows from Linux: 1984's source with 1984-local.patch applied, cross-compiled
// with MinGW (gcc-mingw-w64-x86-64) against SDL3's MinGW release. Out: 1984.exe and SDL3.dll in OUT.
// No PDF printer (cairo) or video capture (ffmpeg), the same as 1984's own Windows build.
//   node tools/emu84/winbuild.js SRC_1984 SDL3_MINGW OUT
//     SRC_1984     1984's source, the patch applied (a clone at 4f8453f + git apply 1984-local.patch)
//     SDL3_MINGW   SDL3-devel-3.2.24-mingw.tar.gz unpacked: its x86_64-w64-mingw32 folder
// (c) 2026 Cyborg Unicorn Pty Ltd
'use strict';
var cp = require('child_process'), fs = require('fs'), path = require('path');

var a = process.argv.slice(2);
if (a.length < 3) { console.log('node winbuild.js SRC_1984 SDL3_MINGW OUT'); process.exit(1); }
var strSrc = path.resolve(a[0]), strSdl = path.resolve(a[1]), strOut = path.resolve(a[2]);
var strPc = path.join(strSdl, 'lib', 'pkgconfig', 'sdl3.pc');

// SDL3's .pc names the folder it was built in: point it at where it is
fs.writeFileSync(strPc, fs.readFileSync(strPc, 'utf8').replace(/^prefix=.*$/m, 'prefix=' + strSdl));
function run(s) { console.log('> ' + s); cp.execSync(s, { cwd: strSrc, stdio: 'inherit', env: Object.assign({}, process.env,
	{ PKG_CONFIG_LIBDIR: path.join(strSdl, 'lib', 'pkgconfig'), ac_cv_path_FFMPEG: '' }) }); }
try { run('make distclean'); } catch (e) { }
run('autoreconf -i');
run('./configure --host=x86_64-w64-mingw32 --without-cairo');
run('make -j8');
fs.mkdirSync(strOut, { recursive: true });
fs.copyFileSync(path.join(strSrc, '1984.exe'), path.join(strOut, '1984.exe'));
fs.copyFileSync(path.join(strSdl, 'bin', 'SDL3.dll'), path.join(strOut, 'SDL3.dll'));
console.log(strOut + ': 1984.exe, SDL3.dll');
