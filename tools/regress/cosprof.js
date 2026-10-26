// cosprof.js - where CyborgOS (the CPC set) spends the time between two texts on the screen: a
// boot and a command in NTC's CPC harness, the Z80 sampled (cosboot.py's COSBOOT_PROF), each
// sample put down to its map (main RAM: CYBORGOS.BIN; a bank: the kernel's - KERNEL.CYB - or a
// slot's) and the routine there (the build's .sym files).
//   node tools/regress/cosprof.js COMMAND FROM UNTIL [--top=40] [--ram=576]
//   e.g. node tools/regress/cosprof.js crunch "Crunch - summing" "Crunch: "
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path'), vm = require('vm'), cp = require('child_process'), os = require('os');
var COS = path.join(__dirname, '..', '..');
var arrA = [], intTop = 40, strRam = '576';
process.argv.slice(2).forEach(function(a) { if (/^--top=/.test(a)) { intTop = +a.substr(6); } else if (/^--ram=/.test(a)) { strRam = a.substr(6); } else { arrA.push(a); } });
if (arrA.length < 3) { console.log('node tools/regress/cosprof.js COMMAND FROM UNTIL'); process.exit(2); }

function syms(strF_a)
{
	var arr = [];
	if (!fs.existsSync(strF_a)) { return arr; }
	fs.readFileSync(strF_a, 'latin1').split(/\r?\n/).forEach(function(l) { var m = l.match(/^([A-Za-z_]\w*): EQU 0x([0-9A-Fa-f]+)/); if (m && !/^(ntc_rg\d|vp_|var_|arr_|tmp|stmp|ltmp|lit_|str)/.test(m[1])) { arr.push([parseInt(m[2], 16) & 0xFFFF, m[1]]); } });
	return arr.sort(function(a, b) { return a[0] - b[0]; });
}
function at(arr_a, pc_a) { var lo = 0, hi = arr_a.length - 1, r = '?'; while (lo <= hi) { var mid = (lo + hi) >> 1; if (arr_a[mid][0] <= pc_a) { r = arr_a[mid][1]; lo = mid + 1; } else { hi = mid - 1; } } return r; }
var C0 = syms(path.join(COS, 'build', 'stage', 'CYBORGOS.BIN', 'CYBORGOS.sym'));
var KS = syms(path.join(COS, 'build', 'stage', 'KERNEL.CYB', 'KERNEL.sym'));

var strDir = fs.mkdtempSync(path.join(os.tmpdir(), 'cosprof'));
var objCtx = { console: console }; objCtx.window = objCtx; vm.createContext(objCtx);
vm.runInContext(fs.readFileSync(path.join(COS, 'tools', 'cosbuild', 'src', 'js', 'cos_core.js'), 'utf8'), objCtx);
objCtx.cosInstallSet(function(n) { var p = path.join(COS, 'build', 'dsk', 'cos-disk' + n + '.dsk'); return fs.existsSync(p) ? new Uint8Array(fs.readFileSync(p)) : null; }, '').forEach(function(f) { var p = path.join(strDir, 'A', f.path); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, Buffer.from(f.data)); });
var strProf = path.join(strDir, 'prof.json');
var r = cp.spawnSync('python3', [path.join(__dirname, 'cosboot.py'), strDir, strRam, '60000', arrA[0]], { env: Object.assign({}, process.env, { COSBOOT_FROM: arrA[1], COSBOOT_UNTIL: arrA[2], COSBOOT_PROF: strProf }), encoding: 'latin1' });
console.log(((r.stdout || '').match(/TIME .*/) || ['TIME none'])[0]);
var arrS = JSON.parse(fs.readFileSync(strProf, 'utf8'));
// the maps: main RAM, then the banks by how often (the kernel's: the one the kernel's code is in - the
// first bank allocated, so the busiest besides the slot is it; told apart by the samples' names)
var objMap = {}, objName = {};
arrS.forEach(function(s) { objMap[s[1]] = (objMap[s[1]] || 0) + 1; });
var strMain = "('m', 0)";
arrS.forEach(function(s)
{
	var n;
	if (s[1] === strMain) { n = 'C0 ' + at(C0, s[0]); }
	else if (s[0] >= 0xEF00) { n = 'bank ' + s[1] + ' stubs (#EF00+)'; }
	else { n = 'bank ' + s[1] + ' ' + at(KS, s[0]) + ' (as the kernel)'; }
	objName[n] = (objName[n] || 0) + 1;
});
// --sp: by where SP is (NTC's thread: the BASIC procedure running), not the PC
if (process.argv.indexOf('--sp') >= 0)
{
	var C0T = C0.filter(function(x) { return /^(p_|main_thread|if|for|do|while|sel|lbl_)/.test(x[1]); });
	var KST = KS.filter(function(x) { return /^(p_|main_thread)/.test(x[1]); });
	var C0P = C0.filter(function(x) { return /^(p_\w+|main_thread)$/.test(x[1]) && !/_(c|r|rs)$/.test(x[1]); });
	var KSP = KS.filter(function(x) { return /^(p_\w+|main_thread)$/.test(x[1]) && !/_(c|r|rs)$/.test(x[1]); });
	var CSP = (C0.filter(function(x) { return x[1] === 'ntc_csp'; })[0] || [0])[0];
	var CSPV = 0;
	objName = {};
	arrS.forEach(function(s)
	{
		var n;
		if ((s[1] === strMain) && (s[2] >= 0xA000)) { n = 'C0 (real stack) ' + at(C0, s[0]); }
		else if (s[1] === strMain) { n = 'C0 sp in ' + at(C0P, s[2]); }
		else if (s[0] >= 0xEF00 || s[2] >= 0xEF00) { n = 'bank ' + s[1] + ' stubs / its stack'; }
		else { n = 'bank ' + s[1] + ' sp in ' + at(KSP, s[2]); }
		objName[n] = (objName[n] || 0) + 1;
	});
}
console.log('samples ' + arrS.length + '; by map: ' + Object.keys(objMap).map(function(k) { return k + ' ' + Math.round(100 * objMap[k] / arrS.length) + '%'; }).join(', '));
Object.keys(objName).sort(function(a, b) { return objName[b] - objName[a]; }).slice(0, intTop).forEach(function(k) { console.log(('     ' + (100 * objName[k] / arrS.length).toFixed(1)).substr(-6) + '%  ' + k); });
