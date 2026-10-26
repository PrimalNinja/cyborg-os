// split.js - CyborgOS-CPC's main RAM (CYBORGOS.BIN: #0040-#3FFF and #8000-ntc_free; the window
// #4000-#7FFF is Option Reserve) by owner, and how it would divide if the kernel were split:
//   C0 = memory management + firmware / screen / disc / keyboard / interrupts / the task side
//   C2 = everything else, in the kernel's own 64K (its variables too: C0 sees them through C1)
// The NTC runtime routines both halves use are counted on both sides.
//   node tools/sizes/split.js [--list]      --list: every owner and where it goes
// Needs a build (build/stage/CYBORGOS.BIN). (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path');
var COS = path.join(__dirname, '..', '..');
var D = path.join(COS, 'build', 'stage', 'CYBORGOS.BIN');
var SRC = path.join(COS, 'src', 'bas', 'cyborgos320kb');
var blnList = process.argv.indexOf('--list') >= 0;
var strAsm = fs.readFileSync(path.join(D, 'CYBORGOS.ASM'), 'latin1');
var sym = {};
fs.readFileSync(path.join(D, 'CYBORGOS.sym'), 'latin1').split(/\r?\n/).forEach(function(l) { var m = l.match(/^(\S+): EQU 0x([0-9A-Fa-f]+)/); if (m) { sym[m[1]] = parseInt(m[2], 16) & 0xFFFF; } });
var FREE = sym.ntc_free;

// the BASIC procedures (longest name first: var_memory_map_map is memory_map's)
var arrProcs = (strAsm.match(/^p_\w+?_c:/gm) || []).map(function(s) { return s.slice(2, -3); }).sort(function(a, b) { return b.length - a.length; });
// the procedures of each source file, by line (asm_<file>_<line>_n labels)
var FILES = ['Main.bas', 'Hyp.cls', 'Ent.cls', 'Hot.cls'], arrLines = [];
FILES.forEach(function(f, i) { var cur = '?'; arrLines[i] = []; fs.readFileSync(path.join(SRC, f), 'latin1').split('\n').forEach(function(l) { var m = l.match(/^\s*(?:Public |Private )?(?:Sub|Function|Property \w+) (\w+)/); if (m) { cur = m[1]; } arrLines[i].push(cur); }); });

// each label: its owner
var strOwner = 'lib start', arrLabs = [];
strAsm.split('\n').forEach(function(l)
{
	var m = l.match(/^;## (\S+)/), n, o, mm;
	if (m) { strOwner = 'lib ' + m[1]; return; }
	m = l.match(/^([A-Za-z_]\w*):/) || l.match(/^([A-Za-z_]\w*)\s+(?:db|dw|ds)\b/);
	if (!m || /^ntc_rg/.test(m[1])) { return; }
	n = m[1];
	if (n === 'main_thread') { strOwner = 'BASIC main'; }
	else if (/^fn_[a-z0-9]+_[a-z0-9]+$/.test(n)) { strOwner = 'ASM ' + n.substr(3); }
	if ((mm = n.match(/^asm_(\d+)_(\d+)_n$/))) { strOwner = 'ASM ' + FILES[+mm[1]].split('.')[0] + '.' + (arrLines[+mm[1]][+mm[2] - 1] || '?'); }
	else if (/^p_[a-z0-9_]+$/.test(n) && !/_(c|r|rs|e)$|_si\d/.test(n)) { strOwner = 'BASIC ' + n.substr(2); }
	o = strOwner;
	if ((mm = n.match(/^p_(\w+?)_(c|r|rs)$/))) { o = 'BASIC ' + mm[1]; }
	else if ((mm = n.match(/^var_(\w+)$/)))
	{
		o = 'data: globals';
		for (var i = 0; i < arrProcs.length; i++) { if (mm[1].indexOf(arrProcs[i] + '_') === 0) { o = 'BASIC ' + arrProcs[i]; break; } }
	}
	else if (/^arr_/.test(n)) { o = 'data: globals'; }
	else if (/^(str|lit_|stmp|tmp|ltmp)/.test(n)) { o = 'data: strings, literals, temps'; }
	if (sym[n] !== undefined) { arrLabs.push([sym[n], n, o]); }
});
arrLabs.sort(function(a, b) { return a[0] - b[0]; });

// bytes per owner, main RAM only (clipped to #0040-#3FFF and #8000-ntc_free)
function clip(a, b)
{
	var t = 0;
	t += Math.max(0, Math.min(b, 0x4000) - Math.max(a, 0x0040));
	t += Math.max(0, Math.min(b, FREE) - Math.max(a, 0x8000));
	return t;
}
var objBytes = {};
for (var i = 0; i < arrLabs.length; i++)
{
	var a = arrLabs[i][0], b = (i + 1 < arrLabs.length) ? arrLabs[i + 1][0] : FREE;
	if (b < a) { continue; }
	objBytes[arrLabs[i][2]] = (objBytes[arrLabs[i][2]] || 0) + clip(a, b);
}
var intAll = clip(0x0040, FREE);

// where each owner goes. C0: memory management, firmware / ROMs, screen, disc, keys, interrupts,
// starting and switching a task (bank mapping), the service entry the tasks call
var C0 = /^(lib (ntc_mem|ntc_memcore|ntc_memcore2|ntc_memcopy|ntc_membank|ntc_plat_|ntc_keys|ntc_xnh|ntc_islots|start|kw_bssinit|ntc_buf2k|kw_inkey|kw_frame|kw_ticks|kw_waitkey|kw_stop|kw_model)|ASM (memory_|Hyp\.(Con|Scr|Inks|Vdu|FileCall|FileShut|Drive|Say|KeyRep|Svc|Run|ClaimPage|UseDriver)|hyp_fontinit|hyp_usepage|hyp_usesvc|hyp_farptr|hyp_info|keys_down)|BASIC (hyp_svc|hyp_svcvars|hyp_filecall|bdos|probediscs|install|storesize|ramdisc|setmode|inks|hot_\w+|owndrive|hopen|hclose|filesshut|memory_\w+|far|nearp|storefree|putc|clst)$)/;
// the NTC runtime both halves need (strings, numbers, compares, loops, printing)
var BOTH = /^lib (kw_|ntc_(atoi|itoa|div|mul|cmp|for_jump|printbuf|d_inbuf|d_numbuf|getn))/;
var o, objSide = {}, intC0 = 0, intC2 = 0, intBoth = 0, intData = 0;
for (o in objBytes)
{
	var s = BOTH.test(o) ? 'both' : (C0.test(o) ? 'C0' : 'C2');
	if (/^data:/.test(o)) { s = 'C2'; }		// the kernel's variables, strings, temps: in its own 64K (bank 7)
	objSide[o] = s;
	if (s === 'C0') { intC0 += objBytes[o]; } else if (s === 'C2') { intC2 += objBytes[o]; } else { intBoth += objBytes[o]; }
}
var CROSS = 150;		// the crossing (the same bytes in bank 0 and bank 4), its table of entries
var C2OWN = 200;		// C2's own restarts / #0038 (switch to C0 for the firmware's interrupt) / start

console.log('main RAM now (#0040-#3FFF, #8000-#' + FREE.toString(16).toUpperCase() + '): ' + intAll + ' bytes');
console.log('  to C0 (memory management, firmware, screen, disc, keys, interrupts): ' + intC0);
console.log('  to C2 (the rest, its variables included):                             ' + intC2);
console.log('  NTC runtime both need (on both sides):                                ' + intBoth);
console.log('');
console.log('C0 after:  ' + (intC0 + intBoth + CROSS) + ' bytes (+' + CROSS + ' the crossing)  ->  ' + (intAll - intC0 - intBoth - CROSS) + ' bytes freed in main RAM');
var intC2Used = intC2 + intBoth + CROSS + C2OWN;
console.log('C2 after:  ' + intC2Used + ' bytes of 65536 (+' + C2OWN + ' its own restarts / #0038 / start)  ->  ' + (65536 - intC2Used) + ' bytes free in the kernel\'s 64K');
if (blnList)
{
	console.log('');
	Object.keys(objBytes).sort(function(a, b) { return objBytes[b] - objBytes[a]; }).forEach(function(o) { if (objBytes[o]) { console.log(('     ' + objBytes[o]).slice(-6) + '  ' + objSide[o] + '  ' + o); } });
}
