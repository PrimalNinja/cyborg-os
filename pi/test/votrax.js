// test/votrax.js - the votrax service: without the ROM in the store it opens and says norom (and
// nothing plays); with a ROM (a synthetic one here: the layout, not the chip's data) it says ready,
// takes phoneme DATA and the program produces samples.    node pi/test/votrax.js
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var cp = require('child_process'), path = require('path'), fs = require('fs'), os = require('os');
var Client = require('../cosctl.js').Client;
var PI = path.join(__dirname, '..');
var STORE = fs.mkdtempSync(path.join(os.tmpdir(), 'cosd-store-'));
var intFail = 0, intRun = 0;
function check(strName_a, blnOk_a, strGot_a) { intRun++; if (blnOk_a) { console.log('ok   ' + strName_a); } else { intFail++; console.log('FAIL ' + strName_a + ': ' + strGot_a); } }
function wait(ms_a) { return new Promise(function(r_a) { setTimeout(r_a, ms_a); }); }
(async function()
{
	var p = cp.spawn(process.execPath, [path.join(PI, 'cosd.js'), '--link=tcp:7413', '--store=' + STORE, '--vdu=8403'], { stdio: 'ignore' });
	await wait(800);
	var c = new Client({ max: 256 });
	await c.connect(7413);
	await c.hello('COS1 machine=cpc name=TEST max=256');
	var intCh = await c.open('votrax');
	var r = await c.req(intCh, 'STATUS');
	check('no ROM in the store: norom (and nothing plays)', r.text === 'OK norom', r.text);
	fs.mkdirSync(path.join(STORE, 'TEST', 'SYS'), { recursive: true });
	var bufRom = Buffer.alloc(512);
	for (var intI = 0; intI < 64; intI++) { bufRom.writeUInt32LE(0x12345678 + intI * 7919, intI * 8); bufRom.writeUInt32LE(((intI & 0x3f) << 24) | (intI * 31 & 0xffffff), intI * 8 + 4); }
	fs.writeFileSync(path.join(STORE, 'TEST', 'SYS', 'SC01A.BIN'), bufRom);
	r = await c.req(intCh, 'STOP');
	r = await c.req(intCh, 'STATUS');
	check('the ROM there: ready', r.text === 'OK ready', r.text);
	c.data(intCh, Buffer.from([0x1b, 0x07, 0x2d, 0x35, 0x03]));
	await wait(600);
	r = await c.req(intCh, 'STATUS');
	check('phonemes taken, the chip still up', r.text === 'OK ready', r.text);
	c.end(); p.kill();
	console.log(intRun + ' checks, ' + intFail + ' failed');
	process.exit(intFail ? 1 : 0);
})();
