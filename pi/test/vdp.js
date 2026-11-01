// test/vdp.js - the vdp service end to end on a TCP link: OPEN with a profile, INFO, PALETTE and
// PATTERNS, a command stream (SPR, VEL, BOUNDS, CLASS, COMMIT), then the engine's frames: STATE
// shows the movement, the EVT frames carry HIT, EDGE, DIED and V. Headless: the viewer page's
// feed is checked by what the service sends, not drawn.    node pi/test/vdp.js
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var cp = require('child_process'), path = require('path'), fs = require('fs'), os = require('os'), net = require('net');
var Client = require('../cosctl.js').Client;
var PI = path.join(__dirname, '..');
var STORE = fs.mkdtempSync(path.join(os.tmpdir(), 'cosd-store-'));
var intFail = 0, intRun = 0;
function check(strName_a, blnOk_a, strGot_a)
{
	intRun++;
	if (blnOk_a) { console.log('ok   ' + strName_a); } else { intFail++; console.log('FAIL ' + strName_a + ': ' + strGot_a); }
}
function wait(ms_a) { return new Promise(function(r_a) { setTimeout(r_a, ms_a); }); }
function w16(arr_a, intV_a) { arr_a.push(intV_a & 255, (intV_a >> 8) & 255); }
function cmd(strOp_a, arrArgs_a)
{
	var OP = { SPR: 1, POS: 2, PAT: 3, SHOW: 4, VEL: 5, BOUNDS: 6, CLASS: 7, KILL: 8, ANIM: 9, BOX: 0x0C, FLAGS: 0x0D, SEQ: 0x0E, PLAY: 0x0F, TILE: 0x20, TILEROW: 0x21, TEXT: 0x30, SCROLL: 0x40, SCROLLV: 0x41, COMMIT: 0x7F }, arrB = [OP[strOp_a]], intI = 0;
	for (intI = 0; intI < arrArgs_a.length; intI++)
	{
		if (typeof arrArgs_a[intI] === 'object') { arrB.push(arrArgs_a[intI].b); } else { w16(arrB, arrArgs_a[intI]); }
	}
	return Buffer.from(arrB);
}
(async function()
{
	var p = cp.spawn(process.execPath, [path.join(PI, 'cosd.js'), '--link=tcp:7391', '--store=' + STORE, '--vdu=8395']);
	p.stderr.on('data', function(b_a) { process.stderr.write('[cosd] ' + b_a); });
	await wait(800);
	var c = new Client({ max: 256 });
	await c.connect(7391);
	await c.hello('COS1 machine=cpc name=TEST max=256');
	var intCh = await c.open('vdp', 'profile=v9990 vsync=1');
	var arrEvt = [];
	c.chan[intCh].onEvt = function(t_a) { arrEvt.push(t_a); };
	var r = await c.req(intCh, 'INFO');
	check('INFO: the v9990 profile', /^OK v9990 256 212 125 512/.test(r.text), r.text);
	r = await c.req(intCh, 'PALETTE 0', Buffer.from([0, 0, 0, 255, 0, 0, 0, 255, 0]));
	check('PALETTE: 3 entries', r.text === 'OK 3', r.text);
	var bufPat = Buffer.alloc(128 * 2, 0x11);		// two 16 x 16 4-bit patterns, colour 1 everywhere
	r = await c.req(intCh, 'PATTERNS 0', bufPat);
	check('PATTERNS: 2 from data', r.text === 'OK 2', r.text);
	fs.mkdirSync(path.join(STORE, 'TEST'), { recursive: true });
	fs.writeFileSync(path.join(STORE, 'TEST', 'game.pat'), Buffer.alloc(128, 0x22));
	r = await c.req(intCh, 'PATTERNS 2 game.pat');
	check('PATTERNS: 1 from a STORE tag', r.text === 'OK 1', r.text);
	// a stream: version, sprite 1 at 10,10 moving right 2 px a frame with EDGE events, sprite 2 at 40,10 still, both class 1 hitting class 1
	var arrS = [Buffer.from([1]),
		cmd('SPR', [1, 0, 10, 10, { b: 1 }]), cmd('VEL', [1, 32, 0]), cmd('BOUNDS', [1, { b: 4 }]), cmd('CLASS', [1, { b: 1 }, { b: 2 }]),
		cmd('SPR', [2, 1, 40, 10, { b: 1 }]), cmd('CLASS', [2, { b: 1 }, { b: 2 }]),
		cmd('TEXT', [{ b: 2 }, { b: 20 }, { b: 2 }, { b: 72 }, { b: 73 }]), cmd('COMMIT', [])];
	c.data(intCh, Buffer.concat(arrS));
	await wait(120);
	r = await c.req(intCh, 'STATE 1');
	var m = r.text.match(/^OK 1 (\d+) 10 0 1/);
	check('STATE: sprite 1 moved right by 2 a frame (x > 10)', m && parseInt(m[1], 10) > 10 && parseInt(m[1], 10) <= 10 + 2 * 12, r.text);
	await wait(400);
	check('HIT 1 2 reported once per frame while they overlap', arrEvt.filter(function(e_a) { return e_a === 'HIT 1 2'; }).length >= 1, arrEvt.join('|').slice(0, 120));
	await wait(2200);
	check('EDGE 1 1 (the right edge) reached with BOUNDS 4', arrEvt.indexOf('EDGE 1 1') >= 0, arrEvt.filter(function(e_a) { return /^EDGE/.test(e_a); }).join('|').slice(0, 80));
	check('V n every frame (vsync=1)', arrEvt.filter(function(e_a) { return /^V \d+$/.test(e_a); }).length > 50, String(arrEvt.length));
	// KILL bounds: sprite 3 leaving the top dies
	c.data(intCh, Buffer.concat([cmd('SPR', [3, 0, 100, 2, { b: 1 }]), cmd('VEL', [3, 0, -64]), cmd('BOUNDS', [3, { b: 2 }]), cmd('COMMIT', [])]));
	await wait(600);
	check('DIED 3 with BOUNDS 2', arrEvt.indexOf('DIED 3') >= 0, arrEvt.filter(function(e_a) { return /^DIED/.test(e_a); }).join('|'));
	r = await c.req(intCh, 'STATE 3');
	check('a dead sprite is hidden', /^OK 3 \S+ \S+ 0 0$/.test(r.text), r.text);
	// a command split across two DATA frames
	var bufOne = cmd('SPR', [4, 1, 50, 50, { b: 1 }]);
	c.data(intCh, bufOne.slice(0, 4)); await wait(30); c.data(intCh, Buffer.concat([bufOne.slice(4), cmd('COMMIT', [])]));
	await wait(100);
	r = await c.req(intCh, 'STATE 4');
	check('a command split across DATA frames', /^OK 4 50 50 1 1$/.test(r.text), r.text);
	// hwlib's model: BOX then BOUNCE bounds reverse the velocity at the box; ANIM steps the pattern first..first+count-1 at delay
	c.data(intCh, Buffer.concat([cmd('BOX', [0, 0, 100, 100]), cmd('SPR', [7, 0, 95, 50, { b: 1 }]), cmd('VEL', [7, 64, 0]), cmd('BOUNDS', [7, { b: 5 }]), cmd('ANIM', [7, 10, { b: 4 }, { b: 2 }]), cmd('COMMIT', [])]));
	await wait(250);
	r = await c.req(intCh, 'STATE 7');
	m = r.text.match(/^OK 7 (\d+) 50 (\d+) 1/);
	check('BOUNCE: turned back inside the box (x <= 100 and heading left)', m && parseInt(m[1], 10) <= 100 && parseInt(m[1], 10) < 99, r.text);
	check('ANIM: the pattern within 10..13', m && parseInt(m[2], 10) >= 10 && parseInt(m[2], 10) <= 13, r.text);
	// sequences: 1 = walk (20 21 22 23, back to step 1), 2 = die (30 31 32 then 0: stops on 32, DONE)
	c.data(intCh, Buffer.concat([cmd('SEQ', [{ b: 1 }, { b: 5 }, 20, 21, 22, 23, -1]), cmd('SEQ', [{ b: 2 }, { b: 4 }, 30, 31, 32, 0]),
		cmd('SPR', [8, 0, 50, 50, { b: 1 }]), cmd('PLAY', [8, { b: 1 }, { b: 1 }]), cmd('SPR', [9, 0, 60, 60, { b: 1 }]), cmd('PLAY', [9, { b: 2 }, { b: 2 }]), cmd('COMMIT', [])]));
	arrEvt.length = 0;
	await wait(400);
	r = await c.req(intCh, 'STATE 8');
	m = r.text.match(/^OK 8 50 50 (\d+) 1/);
	check('a looping sequence: the pattern within 20..23', m && parseInt(m[1], 10) >= 20 && parseInt(m[1], 10) <= 23, r.text);
	r = await c.req(intCh, 'STATE 9');
	check('a stopping sequence: ends on its last frame (32)', /^OK 9 60 60 32 1/.test(r.text), r.text);
	check('DONE 9 when it stopped', arrEvt.indexOf('DONE 9') >= 0, arrEvt.filter(function(e_a) { return /^DONE/.test(e_a); }).join('|'));
	// two COMMITs within one frame: both batches applied (the second must not replace the first)
	c.data(intCh, Buffer.concat([cmd('SPR', [5, 0, 1, 1, { b: 1 }]), cmd('COMMIT', []), cmd('SPR', [6, 0, 2, 2, { b: 1 }]), cmd('COMMIT', [])]));
	await wait(100);
	r = await c.req(intCh, 'STATE');
	check('two COMMITs in one frame: both sprites exist', /\n5 1 1 0 1/.test(r.text) && /\n6 2 2 0 1/.test(r.text), r.text.slice(0, 80));
	r = await c.req(intCh, 'CLEAR');
	check('CLEAR', r.text === 'OK', r.text);
	var intCh2 = await c.open('vdp', 'profile=pi1080');
	r = await c.req(intCh2, 'INFO');
	check('INFO: pi1080', /^OK pi1080 1920 1080 4096/.test(r.text), r.text);
	// the Next's layers on the zxn profile: tiles (8 x 8 4-bit, 32 bytes each), the tile layer 40 x 32, TILE / TILEROW with flags,
	// a scroll with its own velocity, Layer 2 as a 320 x 256 8-bit bitmap, sprite FLAGS
	var intZx = await c.open('vdp', 'profile=zxn');
	r = await c.req(intZx, 'INFO');
	check('INFO: zxn has a 40 x 32 tile layer', /^OK zxn 320 256 128 64 1280 50 40x32/.test(r.text), r.text);
	r = await c.req(intZx, 'PALETTE 0', Buffer.from([0, 0, 0, 255, 255, 255, 0, 255, 0]));
	r = await c.req(intZx, 'TILES 0', Buffer.alloc(32 * 3, 0x11));
	check('TILES: 3 tiles from 96 bytes', r.text === 'OK 3', r.text);
	fs.writeFileSync(path.join(STORE, 'TEST', 'tiles.bin'), Buffer.alloc(32 * 4, 0x22));
	r = await c.req(intZx, 'TILES 3 tiles.bin');
	check('TILES from a STORE tag (4 on from 3)', r.text === 'OK 4', r.text);
	c.data(intZx, Buffer.concat([Buffer.from([1]), cmd('TILE', [{ b: 5 }, { b: 6 }, 2, { b: 0x02 }]),
		cmd('TILEROW', [{ b: 7 }, { b: 0 }, { b: 3 }, 1, { b: 0 }, 2, { b: 8 }, 3, { b: 0 }]),
		cmd('SCROLL', [{ b: 0 }, 8, 0]), cmd('SCROLLV', [{ b: 0 }, 16, 0]),
		cmd('SPR', [1, 0, 10, 10, { b: 1 }]), cmd('FLAGS', [1, { b: 0x12 }]), cmd('COMMIT', [])]));
	await wait(150);
	r = await c.req(intZx, 'TILEAT 5 6');
	check('TILE: cell (5, 6) is tile 2 mirrored X', r.text === 'OK 2 2', r.text);
	r = await c.req(intZx, 'TILEAT 1 7');
	check('TILEROW: cell (1, 7) is tile 2 rotated', r.text === 'OK 2 8', r.text);
	r = await c.req(intZx, 'TILEAT 9 9');
	check('an unset cell: none (Layer 2 shows through)', r.text === 'OK none', r.text);
	r = await c.req(intZx, 'LAYER2', Buffer.alloc(320 * 256, 1));
	check('LAYER2: a 320 x 256 8-bit bitmap taken', r.text === 'OK', r.text);
	r = await c.req(intZx, 'LAYER2', Buffer.alloc(100, 1));
	check('LAYER2: short data refused', /^ERR/.test(r.text), r.text);
	// installed assets: GRAPHICS/V9990/PATTERNS in the store is loaded when a v9990 display opens
	fs.mkdirSync(path.join(STORE, 'TEST', 'GRAPHICS', 'V9990'), { recursive: true });
	fs.writeFileSync(path.join(STORE, 'TEST', 'GRAPHICS', 'V9990', 'PATTERNS'), Buffer.alloc(128 * 5, 0x33));
	fs.writeFileSync(path.join(STORE, 'TEST', 'GRAPHICS', 'V9990', 'PALETTE'), Buffer.from([0, 0, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90]));
	var intCh3 = await c.open('vdp', 'profile=v9990');
	c.data(intCh3, Buffer.concat([Buffer.from([1]), cmd('SPR', [1, 4, 5, 5, { b: 1 }]), cmd('COMMIT', [])]));
	await wait(100);
	r = await c.req(intCh3, 'STATE 1');
	check('a v9990 display opens with the installed PATTERNS (pattern 4 exists for sprite 1)', /^OK 1 5 5 4 1/.test(r.text), r.text);
	r = await c.req(intCh3, 'PATTERNS 5', Buffer.alloc(128, 0x44));
	check('PATTERNS 5 adds after the installed five', r.text === 'OK 1', r.text);
	c.end(); p.kill();
	console.log(intRun + ' checks, ' + intFail + ' failed');
	process.exit(intFail ? 1 : 0);
})();
