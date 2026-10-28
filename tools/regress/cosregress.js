// cosregress.js - CyborgOS (the CPC set) booted and run in NTC's CPC harness: the discs the
// build made (build/dsk/cos-disk1..n.dsk) installed as INSTALL.BAS would, then each test - a
// boot, a few commands typed - and the screen compared with ref/<test>.txt.
//
//   node tools/regress/cosregress.js [--ram=576] [--ref] [--only=name,...] [--keep=DIR]
//     --ref     write the screens as the new references (after checking them by eye)
//     --only    just these tests
//     --keep    the installed set and the screens in DIR (default: a temporary folder)
//     --dsk     the discs from DIR (build/dskflat: the flat build - its CYBFLAT.sym, and ref/flat/<test>.txt
//               where its screen is its own; --ref writes there only those that differ from ref/)
//
// romram: the ROMs taking RAM from #A400 (NTC_ROMTOP: more ROMs than AMSDOS) - COSLOAD must put
// CyborgOS's fast ticker block and RAM top under it (the 22 Oct builds put it at #A5F0, in the
// ROMs' RAM: UniDOS lost, IDE: reset). The network tests run with the harness's M4 (NTC_M4=1: real sockets) against a small web
// server started here (cosweb.js: /echo, /moved, /big?n=), and check the browsers' requests too.
// Needs python3 with the z80 module and NTC (NTC_SRC, default ../ntc/src beside this folder).
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
// a prompt line's cursor ("1> _", the V9990's "1> ?") left out of the comparison: whether it's
// showing is where its blink is when the screen is read, not a fault
// RATS: the rat's food / energy / fun, where it is in the room and what it's doing are live (the
// moment the screen is read) - the screen's shape is checked, those values left out
function ratsMask(s)
{
	return s.replace(/food\d+  energy\d+  fun\d+ */g, 'food#  energy#  fun# ').replace(/^\|(?:[ r]{58})\|/mg, function(l) { return l.replace(/r/g, ' '); }).replace(/^(\d+): [a-z]+ \d+$/mg, '$1: # #');
}
function noCursor(s) { return s.replace(/^(\d+>) ?[_?]?[ \t]*$/mg, '$1'); }
var fs = require('fs'), path = require('path'), vm = require('vm'), cp = require('child_process'), os = require('os');

var COS = path.join(__dirname, '..', '..');
var REF = path.join(__dirname, 'ref');
var objArg = {};
process.argv.slice(2).forEach(function(a) { var m = a.match(/^--(\w+)(?:=(.*))?$/); if (m) { objArg[m[1]] = (m[2] === undefined) ? true : m[2]; } });
var RAM = objArg.ram || '576';

// the tests: name, the commands (; between), net: needs the web server ({U} its address)
var TESTS = [
	['dir', 'dir'], ['dirz', 'dir z:'], ['ps', 'ps'], ['mem', 'mem'], ['top', 'top'], ['help', 'help'],
	['helpdir', 'help dir'], ['type', 'type cyborgos.bas'], ['drive', 'drive'], ['claims', 'claims'],
	['mode', 'mode'], ['cv', 'cv'], ['cd', 'cd'], ['ramdisc', 'ramdisc'], ['rd_dir', 'ramdisc f 32;dir f:'],
	['rd_copy', 'ramdisc f 32;copy z:help.cyb f:;dir f:'],
	['rd_rename', 'ramdisc f 32;copy z:help.cyb f:;rename f:help.cyb x.cyb;dir f:'],
	['rd_era', 'ramdisc f 32;copy z:help.cyb f:;copy z:ps.cyb f:;era f:help.cyb;dir f:'],
	['rd_nolist', 'copy cyborgos.bas z:'],
	['run', 'run 2 ticker;ps'], ['kill', 'run 2 ticker;kill 2;ps'], ['lines', 'lines'], ['crunch', 'crunch'],
	['crunchcom', 'crunch.com'], ['ipconfig', 'ipconfig'], ['netstat', 'netstat'], ['net', 'net'],
	['ask', 'ask rat x'], ['rats', 'run 2 model ratmodel;run 3 rat;rats 3'], ['probe', 'probe help'],
	['watch', 'watch'], ['zhelp', 'z:help mem'],
	['romram', 'dir', false, { NTC_ROMTOP: '0xA3FF', NTC_UNIDOS: 'A,IDE' }],
	['net_on', 'net;net get {U}/echo?a=1;net m4;net;ipconfig', true],
	['net_get', 'net m4;netstat;net set MyNet,secret;net get {U}/echo?a=1&b=two', true],
	['net_test', 'net m4;net get {U}/moved;net test {U}/big?n=3000 3', true],
	['net_fail', 'net m4;net get 127.0.0.1:1/x;net get nosuchhost.invalid/x;net off;net;ipconfig', true],
	['web_ying', 'net m4;ying {U}/echo?from=ying', true], ['web_yang', 'net m4;yang {U}/echo?from=yang', true],
	['web_rawying', 'net m4;rawying {U}/echo?from=rawying', true], ['web_rawyang', 'net m4;rawyang {U}/echo?from=rawyang', true],
	// the console on a V9990 (NTC_V9990=1: the Powergraph's chip at &FF60 in the harness - V9.cls; the
	// screen read off its picture): not for the flat build (no V9990 there)
	['v9_dir', 'dir', false, { NTC_V9990: '1' }], ['v9_ps', 'ps', false, { NTC_V9990: '1' }],
	['v9_top', 'top', false, { NTC_V9990: '1' }], ['v9_mode', 'mode 2;ps;mode p;ps', false, { NTC_V9990: '1' }],
	['v9_lines', 'lines', false, { NTC_V9990: '1' }], ['v9_help', 'help', false, { NTC_V9990: '1' }],
	['v9_novdp', 'mem', false, { NTC_V9990: '1', NTC_POKE: 'BE80=CYB A NOV9990' }]
];
// what the browsers must have asked the server for (their screens are graphics)
var REQUESTS = {
	web_ying: '/echo?from=ying&8bml=7', web_yang: '/echo?from=yang&8bml=7',
	web_rawying: '/echo?from=rawying&8bml=7&raw=78', web_rawyang: '/echo?from=rawyang&8bml=7&raw=80'
};

// ---- the installed set, from the discs (cos_core.js: as INSTALL.BAS lays it out)
function install(strDir_a)
{
	var objCtx = { console: console };
	var strDsk = objArg.dsk ? path.resolve(objArg.dsk) : path.join(COS, 'build', 'dsk');	// --dsk=DIR: another set (build/dskflat: the flat build)

	objCtx.window = objCtx;
	vm.createContext(objCtx);
	vm.runInContext(fs.readFileSync(path.join(COS, 'tools', 'cosbuild', 'src', 'js', 'cos_core.js'), 'utf8'), objCtx);
	var arrSet = objCtx.cosInstallSet(function(n) { var p = path.join(strDsk, 'cos-disk' + n + '.dsk'); return fs.existsSync(p) ? new Uint8Array(fs.readFileSync(p)) : null; }, '');
	if (arrSet.length === 0)
	{
		throw new Error('no discs in ' + strDsk + ' (build them first)');
	}
	arrSet.forEach(function(f) { var p = path.join(strDir_a, 'A', f.path); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, Buffer.from(f.data)); });
	return arrSet.length;
}

// the screen without what changes from run to run: the time a run took, NET TEST's times, where
// the harness's time limit found the Z80
function tidy(str_a)
{
	return str_a.replace(/ secs=\d+/, '').replace(/^TIMEOUT pc=\w+ sp=\w+$/m, 'TIMEOUT').replace(/, \d+ ms$/gm, ', (time) ms').replace(/^Average \d+ ms a GET, \d+ bytes a second$/m, 'Average (time)')
		.split('\n').map(function(l) { return l.replace(/\s+$/, ''); }).join('\n');
}

// CYBORGOS.BIN's variables (romram: where COSLOAD must have put the ROMs' RAM top)
var CYB = {};
var FLAT = /dskflat/.test(String(objArg.dsk || ''));	// the flat build's discs: its symbols, ref/flat/ first
fs.readFileSync(/dskflat/.test(String(objArg.dsk || '')) ? path.join(COS, 'build', 'stage', 'CYBFLAT.BIN', 'CYBFLAT.sym') : path.join(COS, 'build', 'stage', 'CYBORGOS.BIN', 'CYBORGOS.sym'), 'latin1').split(/\r?\n/).forEach(function(l) { var m = l.match(/^(ntc_fwblk|ntc_fwtop): EQU 0x([0-9A-Fa-f]+)/); if (m) { CYB[m[1]] = parseInt(m[2], 16) & 0xFFFF; } });
var strDir = objArg.keep ? path.resolve(objArg.keep) : fs.mkdtempSync(path.join(os.tmpdir(), 'cosregress'));
var arrOnly = objArg.only ? String(objArg.only).split(',') : null;
console.log('installed ' + install(strDir) + ' files from ' + (objArg.dsk || 'build/dsk') + ' into ' + strDir + '/A');
fs.mkdirSync(REF, { recursive: true });
var objWeb = require('./cosweb.js').start(function(intPort_a)
{
	var U = 'http://127.0.0.1:' + intPort_a;
	var arrReqs = objWeb.requests;
	var intFail = 0, intOk = 0;
	var arrRun = TESTS.filter(function(t) { return (!arrOnly || arrOnly.indexOf(t[0]) >= 0) && !(FLAT && /^v9_/.test(t[0])); });

	(function next(i)
	{
		if (i >= arrRun.length)
		{
			objWeb.close();
			console.log(objArg.ref ? 'references written (' + arrRun.length + ')' : (intFail ? intFail + ' failed, ' : '') + intOk + ' passed' + (intFail ? '' : ' - ALL PASS'));
			process.exit(intFail ? 1 : 0);
		}
		var t = arrRun[i];
		var n0 = arrReqs.length;
		// (a boot runs asynchronously: the web server here answers it meanwhile)
		var objEnv = Object.assign({}, process.env);
		if (t[2]) { objEnv.NTC_M4 = '1'; }
		Object.assign(objEnv, t[3] || {});
		if (t[0] === 'romram') { objEnv.COSBOOT_PEEK = [CYB.ntc_fwblk, CYB.ntc_fwtop].map(function(v) { return v.toString(16); }).join(','); }
		var p = cp.spawn('python3', [path.join(__dirname, 'cosboot.py'), strDir, RAM, '60000', t[1].replace(/\{U\}/g, U)], { env: objEnv });
		var strOut = '', strErr = '';
		p.stdout.on('data', function(d) { strOut += d.toString('latin1'); });
		p.stderr.on('data', function(d) { strErr += d.toString('latin1'); });
		p.on('close', function(intCode)
		{
			var strScr = tidy(strOut.replace(new RegExp(U.replace(/[.:\/]/g, '\\$&'), 'g'), 'http://SERVER'));
			var strF = path.join(REF, t[0] + '.txt');
			var strFF = path.join(REF, 'flat', t[0] + '.txt');		// the flat build's own (--dsk=build/dskflat), where its screen differs

			if (FLAT && fs.existsSync(strFF)) { strF = strFF; }
			var strWhy = '';

			fs.writeFileSync(path.join(strDir, t[0] + '.txt'), strScr);
			if (intCode) { strWhy = 'exit ' + intCode + ': ' + strErr.split('\n').slice(-3).join(' | '); }
			else if ((t[0] === 'romram') && !/PEEK \w+ A3F0\n[^]*PEEK \w+ A3F0/.test(strOut)) { strWhy = 'with the ROMs\' RAM from #A400, CyborgOS\'s ntc_fwblk / ntc_fwtop are not #A3F0 (under it): ' + (strOut.match(/PEEK .*/g) || []).join(', '); }
			else if (REQUESTS[t[0]] && arrReqs.slice(n0).indexOf(REQUESTS[t[0]]) < 0) { strWhy = 'the server was not asked for ' + REQUESTS[t[0]] + ' (asked: ' + arrReqs.slice(n0).join(', ') + ')'; }
			else if (t[0] === 'romram') { }		// (checked by its PEEKs, not a screen)
			else if (objArg.ref && FLAT && (!fs.existsSync(path.join(REF, t[0] + '.txt')) || fs.readFileSync(path.join(REF, t[0] + '.txt'), 'latin1') !== strScr)) { fs.mkdirSync(path.dirname(strFF), { recursive: true }); fs.writeFileSync(strFF, strScr); }
			else if (objArg.ref && FLAT) { if (fs.existsSync(strFF)) { fs.unlinkSync(strFF); } }
			else if (objArg.ref) { fs.writeFileSync(strF, strScr); }
			else if (!fs.existsSync(strF)) { strWhy = 'no reference (--ref)'; }
			else if ((t[0] === 'rats' ? ratsMask : String)(noCursor(fs.readFileSync(strF, 'latin1'))) !== (t[0] === 'rats' ? ratsMask : String)(noCursor(strScr))) { strWhy = 'the screen differs: diff ' + strF + ' ' + path.join(strDir, t[0] + '.txt'); }
			if (strWhy) { intFail++; console.log('FAIL ' + t[0] + ' - ' + strWhy); } else { intOk++; console.log('ok   ' + t[0]); }
			next(i + 1);
		});
	})(0);
});
