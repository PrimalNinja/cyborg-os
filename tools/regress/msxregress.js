// msxregress.js - CyborgOS for the MSX (build/msx/CYBORGOS: CYBORGOS.COM and its folder) run in
// NTC's MSX-DOS 2 harness (msxrun.py: the mapper, the V9938's TEXT 2, MSX-DOS 2's handle calls on
// a folder), a test at a time - a few commands typed, the screen after a set number of frames -
// and the screen compared with ref/msx/<test>.txt.
//
//   node tools/regress/msxregress.js [--ram=576] [--ref] [--only=name,...] [--keep=DIR]
//     --ref     write the screens as the new references (after checking them by eye)
//     --only    just these tests
//     --keep    each test's folder and screen in DIR (default: a temporary folder)
//
// A test: its name, the commands (; between - {49,58} in them is a key held: CTRL + ESC), the
// frames to run (50 a second), the environment it adds (NTC_V9990), CyborgOS's command tail. Each runs on a fresh copy of the folder (the files a test makes go).
// Needs python3 with the z80 module and NTC (NTC_SRC, default ../ntc/src beside this folder).
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path'), cp = require('child_process'), os = require('os');

var COS = path.join(__dirname, '..', '..');
var REF = path.join(__dirname, 'ref', 'msx');
var objArg = {};
process.argv.slice(2).forEach(function(a) { var m = a.match(/^--(\w+)(?:=(.*))?$/); if (m) { objArg[m[1]] = (m[2] === undefined) ? true : m[2]; } });
var RAM = objArg.ram || '576';
var NTC = process.env.NTC_SRC || path.join(COS, '..', 'ntc', 'src');
var MSXRUN = path.join(NTC, 'test', 'msxrun.py');
var SET = path.join(COS, 'build', 'msx', 'CYBORGOS');

var TESTS = [
	['boot', '', 150], ['dir', 'dir', 400], ['ps', 'ps', 300], ['mem', 'mem', 300], ['drive', 'drive', 300],
	['top', '{49,58}~~~~~~~~~~~~', 300], ['help', 'help', 400], ['mode', 'mode', 300],
	['modes', 'mode s;ps', 400], ['run', 'run 2 ticker;ps', 500], ['kill', 'run 2 ticker;kill 2;ps', 600],
	['slot2', 'run 2 ticker;{49,2}~~~~~~~~~~~~', 500], ['lines', 'lines', 700],
	['files', 'copy ratmodel.txt x.txt;rename x.txt y.txt;dir y.txt;era y.txt;mkdir t1;dir t1/;rmdir t1', 2500],
	['rd_copy', 'ramdisc f 32;copy help.cyb f:;dir f:', 2500], ['cd', 'cd help;dir', 500],
	['net', 'net', 300], ['quit', 'quit', 300],
	// the console on a V9990 (a GFX9000 at #60 in the harness: NTC_V9990=1 - V9.cls; the screen read
	// off its picture); NOV9990 on the command line leaves it alone
	['v9_dir', 'dir', 400, { NTC_V9990: '1' }], ['v9_ps', 'ps', 300, { NTC_V9990: '1' }],
	['v9_top', '{49,58}~~~~~~~~~~~~', 300, { NTC_V9990: '1' }], ['v9_mode', 'mode p;ps', 500, { NTC_V9990: '1' }],
	['v9_lines', 'lines', 900, { NTC_V9990: '1' }], ['v9_slot2', 'run 2 ticker;{49,2}~~~~~~~~~~~~', 500, { NTC_V9990: '1' }],
	['v9_quit', 'quit', 300, { NTC_V9990: '1' }], ['v9_novdp', 'ps', 300, { NTC_V9990: '1' }, 'NOV9990']
];

function copyDir(strFrom_a, strTo_a)
{
	fs.mkdirSync(strTo_a, { recursive: true });
	fs.readdirSync(strFrom_a).forEach(function(f)
	{
		var a = path.join(strFrom_a, f), b = path.join(strTo_a, f);

		if (fs.statSync(a).isDirectory()) { copyDir(a, b); } else { fs.copyFileSync(a, b); }
	});
}

if (!fs.existsSync(path.join(SET, 'CYBORGOS.COM'))) { console.log('no ' + path.join(SET, 'CYBORGOS.COM') + ': build first (node tools/cosbuild/src/cli.js build)'); process.exit(1); }
if (!fs.existsSync(MSXRUN)) { console.log('no ' + MSXRUN + ': NTC_SRC= NTC\'s src folder'); process.exit(1); }
var strKeep = objArg.keep ? path.resolve(objArg.keep) : fs.mkdtempSync(path.join(os.tmpdir(), 'msxreg-'));
var arrOnly = objArg.only ? String(objArg.only).split(',') : null;
var intFail = 0, intRun = 0;

fs.mkdirSync(REF, { recursive: true });
TESTS.forEach(function(t)
{
	if (arrOnly && arrOnly.indexOf(t[0]) < 0) { return; }
	var strDir = path.join(strKeep, t[0]);
	var strTyped = t[1] ? t[1].split(';').join('\\n') + '\\n' : '';
	var r, strOut, strRef = path.join(REF, t[0] + '.txt');

	fs.rmSync(strDir, { recursive: true, force: true });
	copyDir(SET, strDir);
	r = cp.spawnSync('python3', [MSXRUN, path.join(strDir, 'CYBORGOS.COM'), strTyped, '--ram=' + RAM].concat(t[4] ? ['--cmdline=' + t[4]] : []),
		{ env: Object.assign({}, process.env, { NTC_FILES: strDir, NTC_LIMIT: String(t[2]) }, t[3] || {}), encoding: 'latin1', maxBuffer: 1 << 24 });
	strOut = String(r.stdout || '').split('\n').filter(function(l) { return !/^TIMEOUT |^--- /.test(l); }).join('\n').replace(/\s+$/, '') + '\n';
	fs.writeFileSync(path.join(strKeep, t[0] + '.txt'), strOut);
	intRun++;
	if (objArg.ref)
	{
		fs.writeFileSync(strRef, strOut);
		console.log('ref  ' + t[0]);
	}
	else if (!fs.existsSync(strRef))
	{
		console.log('NEW  ' + t[0] + ' (no reference: --ref)');
		intFail++;
	}
	else if (fs.readFileSync(strRef, 'latin1') === strOut)
	{
		console.log('ok   ' + t[0]);
	}
	else
	{
		console.log('FAIL ' + t[0] + ' (' + path.join(strKeep, t[0] + '.txt') + ')');
		intFail++;
	}
});
console.log(intRun + ' tests, ' + intFail + ' failed' + (objArg.keep ? '' : ' (screens in ' + strKeep + ')'));
process.exit(intFail ? 1 : 0);
