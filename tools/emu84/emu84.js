// emu84.js - CyborgOS run in the 1984 CPC emulator (https://github.com/salvogendut/1984, GPL v2,
// built with 1984-local.patch: README.md here), headless: a 6128 with the RAM expansion, an M4 whose
// SD card is a folder (the installed set, from build/dsk's discs as INSTALL.BAS lays it out), the
// V9990 (Powergraph) if asked for; RUN"CYBORGOS typed, then the commands; the screen saved at a
// frame (PNG), the V9990's own picture too when it is on.
//
//   node tools/emu84/emu84.js [--emu=PATH] [--ram=576] [--v9990] [--frames=N] [--out=DIR]
//                             [--set=DIR] [--trace=m4|v9990|net4cpc] [--rtc] [--net4cpc] "dir;ps;mode p"
//     --rtc      the DS12887 clock (SYMBiFACE II / Cyboard) on; --net4cpc the W5100S (host sockets)
//     --emu      the 1984 binary (default ../1984/1984 beside this repository, or $EMU84)
//     --set      an installed set to use as the M4's card (default: installed now into --out/A)
//     --frames   the frame the screen is taken at (default: 900 for the boot + 400 a command)
//     --out      where the card, the config and the pictures go (default: a temporary folder)
//   Each command waits 8 seconds (400 frames) before the next is typed. Needs the patched 1984
//   (ONE_K_WARP: no 50 Hz wait; ` in the typing: a second's pause; ONE_K_M4_DRIVE: "A:" left off
//   the M4's names - see README.md) and SDL3's library where the loader finds it (LD_LIBRARY_PATH).
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path'), cp = require('child_process'), os = require('os'), vm = require('vm'), zlib = require('zlib');

var COS = path.join(__dirname, '..', '..');
var objArg = {}, arrCmd = [];
process.argv.slice(2).forEach(function(a)
{
	var m = a.match(/^--(\w+)(?:=(.*))?$/);

	if (m) { objArg[m[1]] = (m[2] === undefined) ? true : m[2]; } else { arrCmd = a.split(';').filter(function(s) { return s.trim() !== ''; }); }
});
var EMU = path.resolve(objArg.emu || process.env.EMU84 || path.join(COS, '..', '1984', '1984'));
var ROMS = path.join(path.dirname(EMU), 'roms');
var OUT = path.resolve(objArg.out || fs.mkdtempSync(path.join(os.tmpdir(), 'emu84-')));
var FRAMES = parseInt(objArg.frames || String(900 + 400 * arrCmd.length + 200), 10);

// ---- the installed set (as cosregress.js does it: cos_core.js's cosInstallSet over the discs)
function install(strDir_a)
{
	var objCtx = { console: console }, strDsk = path.join(COS, 'build', 'dsk');

	objCtx.window = objCtx;
	vm.createContext(objCtx);
	vm.runInContext(fs.readFileSync(path.join(COS, 'tools', 'cosbuild', 'src', 'js', 'cos_core.js'), 'utf8'), objCtx);
	var arrSet = objCtx.cosInstallSet(function(n) { var p = path.join(strDsk, 'cos-disk' + n + '.dsk'); return fs.existsSync(p) ? new Uint8Array(fs.readFileSync(p)) : null; }, '');
	if (arrSet.length === 0) { throw new Error('no discs in ' + strDsk + ' (build first)'); }
	arrSet.forEach(function(f) { var p = path.join(strDir_a, f.path); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, Buffer.from(f.data)); });
	return arrSet.length;
}

// ---- a PPM (P6) to a PNG (zlib's deflate; no other library)
function ppmToPng(strPpm_a, strPng_a)
{
	var buf = fs.readFileSync(strPpm_a), arrHdr = [], intPos = 0, i, y;

	while (arrHdr.length < 4)
	{
		while (/\s/.test(String.fromCharCode(buf[intPos]))) { intPos++; }
		if (buf[intPos] === 35) { while (buf[intPos] !== 10) { intPos++; } continue; }	// (# a comment)
		var s = '';
		while (!/\s/.test(String.fromCharCode(buf[intPos]))) { s += String.fromCharCode(buf[intPos++]); }
		arrHdr.push(s);
	}
	intPos++;
	var w = parseInt(arrHdr[1], 10), h = parseInt(arrHdr[2], 10);
	var raw = Buffer.alloc((w * 3 + 1) * h);
	for (y = 0; y < h; y++) { raw[y * (w * 3 + 1)] = 0; buf.copy(raw, y * (w * 3 + 1) + 1, intPos + y * w * 3, intPos + (y + 1) * w * 3); }
	var arrCrc = [];
	for (i = 0; i < 256; i++) { var c = i; for (var k = 0; k < 8; k++) { c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1); } arrCrc[i] = c >>> 0; }
	function chunk(strType_a, bufData_a)
	{
		var bufLen = Buffer.alloc(4), bufType = Buffer.from(strType_a, 'latin1'), bufCrc = Buffer.alloc(4), c = 0xFFFFFFFF, all = Buffer.concat([bufType, bufData_a]);
		bufLen.writeUInt32BE(bufData_a.length);
		for (var j = 0; j < all.length; j++) { c = arrCrc[(c ^ all[j]) & 255] ^ (c >>> 8); }
		bufCrc.writeUInt32BE((c ^ 0xFFFFFFFF) >>> 0);
		return Buffer.concat([bufLen, all, bufCrc]);
	}
	var ihdr = Buffer.alloc(13);
	ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2;
	fs.writeFileSync(strPng_a, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}

if (!fs.existsSync(EMU)) { console.log('no 1984 at ' + EMU + ' (--emu=, or build it: tools/emu84/README.md)'); process.exit(1); }
var strCard = objArg.set ? path.resolve(objArg.set) : path.join(OUT, 'A');
if (!objArg.set) { fs.rmSync(strCard, { recursive: true, force: true }); console.log('installed ' + install(strCard) + ' files into ' + strCard); }

// 1984 reads ~/.config/1984/1984.conf: a HOME of its own, so the user's config is left alone
var strHome = path.join(OUT, 'home');
fs.mkdirSync(path.join(strHome, '.config', '1984'), { recursive: true });
fs.writeFileSync(path.join(strHome, '.config', '1984', '1984.conf'), [
	'[machine]', 'model=6128', 'memory=' + (objArg.ram || '576'), 'crtc=auto', '',
	'[roms]', 'os=' + path.join(ROMS, 'OS_6128.ROM'), 'basic=' + path.join(ROMS, 'BASIC_1.1.ROM'), 'amsdos=' + path.join(ROMS, 'AMSDOS.ROM'), '',
	'[storage]', 'drive_a=', 'drive_b=', '',
	'[hardware]', 'mx4=true', 'powergraph_v9990=' + (objArg.v9990 ? 'true' : 'false'), 'powergraph_video_source=auto', 'rom_board=true',
	'm4=true', 'm4_path=' + strCard, 'm4_image=', 'rtc=' + (objArg.rtc ? 'true' : 'false'), 'net4cpc=' + (objArg.net4cpc ? 'true' : 'false'), 'net4cpc_tap=false', '',
	'[advanced]', 'debug=false', 'notifications=console', ''].join('\n'));

// the typing: RUN"CYBORGOS, the boot's wait (18 s), each command and 8 s after it
var strPaste = 'run"cyborgos\\n' + '`'.repeat(18) + arrCmd.map(function(s) { return s.trim() + '\\n' + '`'.repeat(8); }).join('');
var strPpm = path.join(OUT, 'screen.ppm'), strV9 = path.join(OUT, 'v9990.ppm');
var arrEmuArg = ['--headless', '--paste=' + strPaste.replace(/\\n$/, ''), '--screenshot-at=' + FRAMES + ':' + strPpm];
if (objArg.trace) { arrEmuArg.push('--trace-' + objArg.trace); }
var env = Object.assign({}, process.env, { HOME: strHome, ONE_K_WARP: '1', ONE_K_M4_DRIVE: '1', ONE_K_V9_PPM: strV9 });
fs.rmSync(strV9, { force: true });
var r = cp.spawnSync(EMU, arrEmuArg, { env: env, encoding: 'latin1', maxBuffer: 1 << 26, timeout: 600000 });
if (objArg.trace) { fs.writeFileSync(path.join(OUT, 'trace.log'), (r.stderr || '') + (r.stdout || '')); }
if (!fs.existsSync(strPpm)) { console.log('no screen taken: ' + String(r.stderr || r.error || '').slice(-400)); process.exit(1); }
ppmToPng(strPpm, path.join(OUT, 'screen.png'));
console.log('screen: ' + path.join(OUT, 'screen.png') + ' (frame ' + FRAMES + ')');
if (fs.existsSync(strV9)) { ppmToPng(strV9, path.join(OUT, 'v9990.png')); console.log('V9990:  ' + path.join(OUT, 'v9990.png')); }
