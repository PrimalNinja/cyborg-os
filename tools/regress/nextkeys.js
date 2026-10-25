// nextkeys.js - CyborgOS-Next's system keys in ZEsarUX: the card image booted, then the keys a
// user presses, and after each the slot in front read from the hypervisor's variable (front,
// by the build's .sym): Caps Shift + 5-8 (what the Next's cursor keys are in the matrix) and the
// cursor keys must leave the slot alone; Caps Shift + 0 is TOP (front 0); on TOP, 2 is slot 2,
// 0 slot 10 (with 10 slots or more); Caps Shift + 0 twice: TOP, then back.
//
//   ZESARUX=path/to/zesarux node tools/regress/nextkeys.js [CARD.img] [--shots=DIR]
//
// CARD.img: default build/next/cyborgos-next-sd.img (a copy is used); the symbols from
// build/stage/CYBORGOS.NEX/CYBORGOS.sym. Exit code 1 when a step goes wrong.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path'), cp = require('child_process'), os = require('os');
var Zrcp = require('./zrcp.js');

var COS = path.join(__dirname, '..', '..');
var arrArgs = process.argv.slice(2), strShots = '';
arrArgs = arrArgs.filter(function(a) { if (/^--shots=/.test(a)) { strShots = path.resolve(a.substr(8)); return false; } return true; });
var strImg = path.resolve(arrArgs[0] || path.join(COS, 'build', 'next', 'cyborgos-next-sd.img'));
var ZES = process.env.ZESARUX;
if (!ZES || !fs.existsSync(ZES)) { console.log('ZESARUX=path to the zesarux binary'); process.exit(2); }
var strSym = fs.readFileSync(path.join(COS, 'build', 'stage', 'CYBORGOS.NEX', 'CYBORGOS.sym'), 'latin1');
function sym(strName_a) { var m = strSym.match(new RegExp('^' + strName_a + ': EQU 0x([0-9A-Fa-f]+)', 'm')); if (!m) { throw new Error('no ' + strName_a + ' in the .sym'); } return parseInt(m[1], 16) & 0xFFFF; }
var FRONT = sym('var_front'), NS = sym('var_ns');

var K = { CAPS: 135, ENTER: 129, SPACE: 128, LEFT: 142, RIGHT: 143, DOWN: 144, UP: 145 };
var sleep = function(ms) { return new Promise(function(r) { setTimeout(r, ms); }); };

(async function()
{
	var strTmp = fs.mkdtempSync(path.join(os.tmpdir(), 'nextkeys'));
	fs.copyFileSync(strImg, path.join(strTmp, 'card.mmc'));
	cp.spawnSync('pkill', ['-x', 'zesarux']);
	await sleep(1000);
	var zes = cp.spawn(ZES, ['--noconfigfile', '--machine', 'tbblue', '--vo', 'null', '--ao', 'null', '--nowelcomemessage',
		'--enable-remoteprotocol', '--remoteprotocol-port', '10000', '--verbose', '1', '--realvideo', '--enable-mmc',
		'--enable-divmmc-ports', '--enable-divmmc-paging', '--mmc-file', path.join(strTmp, 'card.mmc'), '--mmc-no-persistent-writes'],
		{ cwd: path.dirname(ZES), stdio: 'ignore' });
	await sleep(4000);
	var z = new Zrcp(10000);
	await sleep(500);
	var down = function(k) { return z.cmd('send-keys-event ' + k + ' 1'); };
	var up = function(k) { return z.cmd('send-keys-event ' + k + ' 0'); };
	var tap = async function(k) { await down(k); await sleep(200); await up(k); await sleep(400); };
	var chord = async function(k) { await down(K.CAPS); await sleep(100); await down(k); await sleep(300); await up(k); await sleep(100); await up(K.CAPS); await sleep(800); };
	// the word at an address, read several times (a slot's turn can have other pages in): the most common
	var word = async function(a)
	{
		var objN = {}, best = null;
		for (var i = 0; i < 9; i++)
		{
			var s = await z.cmd('read-memory ' + a + ' 2');
			var m = s.match(/([0-9A-Fa-f]{2})\s*([0-9A-Fa-f]{2})/);
			if (m) { var v = parseInt(m[1], 16) + 256 * parseInt(m[2], 16); objN[v] = (objN[v] || 0) + 1; if (best === null || objN[v] > objN[best]) { best = v; } }
			await sleep(50);
		}
		return best;
	};
	var intShot = 0, intFail = 0;
	var check = async function(strWhat_a, intWant_a)
	{
		var v = await word(FRONT);
		intShot++;
		if (strShots) { fs.mkdirSync(strShots, { recursive: true }); await z.cmd('save-screen ' + path.join(strShots, 'keys-' + intShot + '.bmp')); await sleep(800); }
		if (v !== intWant_a) { intFail++; }
		console.log(((v === intWant_a) ? 'ok   ' : 'FAIL ') + strWhat_a + ': slot ' + v + ' in front (' + intWant_a + ')');
	};

	await sleep(30000); await tap(K.ENTER); await sleep(12000); await tap(K.SPACE); await sleep(25000);	// NextZXOS's menu, then CyborgOS
	var ns = await word(NS);
	console.log('slots: ' + ns);
	await check('booted', 1);
	await chord('5'.charCodeAt(0)); await chord('6'.charCodeAt(0)); await chord('7'.charCodeAt(0)); await chord('8'.charCodeAt(0));
	await check('Caps Shift + 5, 6, 7, 8 (the Next\'s cursor keys)', 1);
	await tap(K.LEFT); await tap(K.UP); await tap(K.RIGHT); await tap(K.DOWN);
	await check('the cursor keys', 1);
	await chord('2'.charCodeAt(0)); await chord('9'.charCodeAt(0));
	await check('Caps Shift + 2 (CAPS LOCK), 9 (GRAPH)', 1);
	await chord('0'.charCodeAt(0));
	await check('Caps Shift + 0: TOP', 0);
	await tap('2'.charCodeAt(0));
	await check('2 on TOP', 2);
	if (ns >= 10)
	{
		await chord('0'.charCodeAt(0)); await tap('0'.charCodeAt(0));
		await check('0 on TOP', 10);
	}
	await chord('0'.charCodeAt(0)); await tap('x'.charCodeAt(0));
	await check('a key that is no slot on TOP: TOP stays', 0);
	await chord('0'.charCodeAt(0));
	await check('Caps Shift + 0 on TOP: back', (ns >= 10) ? 10 : 2);
	zes.kill();
	if (strShots) { console.log('pictures: ' + strShots + '/keys-1..' + intShot + '.bmp'); }
	console.log(intFail ? intFail + ' failed' : 'ALL PASS');
	process.exit(intFail ? 1 : 0);
})();
