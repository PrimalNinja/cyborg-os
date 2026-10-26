// cosperf.js - CyborgOS (the CPC set) timed in NTC's CPC harness: each benchmark a boot and a
// command, the emulated time from one text appearing on the screen to another (cosboot.py's
// COSBOOT_FROM / COSBOOT_UNTIL, looked at every 10 frames: 0.2 s). For comparing two builds -
// the discs of each installed as INSTALL.BAS would.
//   node tools/regress/cosperf.js [DSKDIR ...] [--ram=576]
// DSKDIR: a folder with cos-disk1..n.dsk (default build/dsk); several: a column each.
// Needs what cosregress.js needs. (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path'), vm = require('vm'), cp = require('child_process'), os = require('os');
var COS = path.join(__dirname, '..', '..');
var arrDirs = [], strRam = '576';
process.argv.slice(2).forEach(function(a) { if (/^--ram=/.test(a)) { strRam = a.substr(6); } else { arrDirs.push(path.resolve(a)); } });
if (arrDirs.length === 0) { arrDirs.push(path.join(COS, 'build', 'dsk')); }

// name, the commands, from, until
var BENCH = [
	['lines', 'lines', 'line1 ', 'lines done'],
	['crunch', 'crunch', 'Crunch - summing', 'Crunch: '],
	['dir', 'dir z:', '1> dir z:', '[DIR.CYB ended]'],
	['ps', 'ps', '1> ps', '[PS.CYB ended]'],
	['type', 'type cyborgos.bas', '1> type', '[TYPE.CYB ended]']
];

function install(strDsk_a, strDir_a)
{
	var objCtx = { console: console };
	objCtx.window = objCtx;
	vm.createContext(objCtx);
	vm.runInContext(fs.readFileSync(path.join(COS, 'tools', 'cosbuild', 'src', 'js', 'cos_core.js'), 'utf8'), objCtx);
	var arrSet = objCtx.cosInstallSet(function(n) { var p = path.join(strDsk_a, 'cos-disk' + n + '.dsk'); return fs.existsSync(p) ? new Uint8Array(fs.readFileSync(p)) : null; }, '');
	arrSet.forEach(function(f) { var p = path.join(strDir_a, 'A', f.path); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, Buffer.from(f.data)); });
}

var arrSets = arrDirs.map(function(d) { var t = fs.mkdtempSync(path.join(os.tmpdir(), 'cosperf')); install(d, t); return t; });
console.log('bench    ' + arrDirs.map(function(d) { return (d.length > 30 ? '...' + d.substr(-27) : d); }).join('  '));
BENCH.forEach(function(b)
{
	var arrR = arrSets.map(function(strSet)
	{
		var r = cp.spawnSync('python3', [path.join(__dirname, 'cosboot.py'), strSet, strRam, '60000', b[1]], { env: Object.assign({}, process.env, { COSBOOT_FROM: b[2], COSBOOT_UNTIL: b[3] }), encoding: 'latin1' });
		var m = (r.stdout || '').match(/TIME (\d+) T (\d+) ms/);
		return m ? (m[2] + ' ms') : 'none';
	});
	console.log((b[0] + '         ').substr(0, 9) + arrR.join('    '));
});
