// test/run.js - cosd.js end to end: started on a TCP link with a store of its own, then every
// service asked through cosctl.js's Client (the CPC's part), the answers checked; then once more
// on a cplink2 link (this test standing in for cplink-bridge: the FIFO and the Pi ROM's port), a
// big STORE GET checked to come through the ROM.
//   node pi/test/run.js
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var cp = require('child_process'), path = require('path'), fs = require('fs'), os = require('os'), net = require('net');
var Client = require('../cosctl.js').Client, P = require('../proto.js');

var PI = path.join(__dirname, '..');
var STORE = fs.mkdtempSync(path.join(os.tmpdir(), 'cosd-store-'));
var VOLS = fs.mkdtempSync(path.join(os.tmpdir(), 'cosd-vols-'));
var intFail = 0, intRun = 0;

function check(strName_a, blnOk_a, strGot_a)
{
	intRun++;
	if (blnOk_a) { console.log('ok   ' + strName_a); } else { intFail++; console.log('FAIL ' + strName_a + ': ' + strGot_a); }
}
function wait(ms) { return new Promise(function(r) { setTimeout(r, ms); }); }
function start(strLink_a, intVdu_a)
{
	var p = cp.spawn(process.execPath, [path.join(PI, 'cosd.js'), '--link=' + strLink_a, '--store=' + STORE, '--volumes=' + VOLS, '--vdu=' + intVdu_a], { stdio: ['ignore', 'pipe', 'pipe'] });
	p.stderr.on('data', function(b) { process.stderr.write('[cosd] ' + b); });
	return p;
}

// the parser on its own: frames split anywhere, noise between them, a bad check dropped
(function()
{
	var arrF = [], prs = new P.Parser(1024, function(f) { arrF.push(f); });
	var a = P.encode(3, P.T.REQ, 7, P.payload('PUT x', Buffer.from([0, 1, 2]))), b = P.encode(0, P.T.DATA, 0, Buffer.from('hi')), bad = Buffer.from(a);
	bad[bad.length - 1] ^= 1;
	var all = Buffer.concat([Buffer.from([1, 2, 0xA5, 9]), a, bad, Buffer.from('noise'), b]);
	for (var i = 0; i < all.length; i += 3) { prs.feed(all.slice(i, i + 3)); }
	check('parser: frames out of noise', arrF.length === 2 && arrF[0].chan === 3 && arrF[0].id === 7 && P.split(arrF[0].payload).body.length === 3 && arrF[1].payload.toString() === 'hi', JSON.stringify(arrF.map(function(f) { return [f.chan, f.type, f.id, f.payload.length]; })));
})();

async function main()
{
	var d = start('tcp:7310', 8394);
	await wait(600);
	var c = new Client({ max: 256 });
	await c.connect(7310);
	var h = await c.hello('COS1 machine=cpc name=testcpc max=256 cols=80 rows=24');
	check('hello', /^COS1 cosd/.test(h) && /services=.*store/.test(h), h);
	var r = await c.req(0, 'PING');
	check('ping', r.text === 'OK PONG', r.text);
	r = await c.req(0, 'TIME');
	check('time', /^OK \d{4}-\d\d-\d\d \d\d:\d\d:\d\d [+-]\d\d:\d\d \d+ [1-7]$/.test(r.text), r.text);
	r = await c.req(0, 'LIST');
	check('list', /store ready/.test(r.body.toString()) && /plugin notyet/.test(r.body.toString()), r.body.toString());
	r = await c.req(0, 'OPEN plugin');
	check('open a service not there yet', /^ERR notyet/.test(r.text), r.text);
	r = await c.req(0, 'OPEN nosuch');
	check('open no such service', /^ERR noservice/.test(r.text), r.text);

	// STORE: put, get (a big one: parts), list, size, del
	var st = await c.open('store');
	var big = Buffer.alloc(5000); for (var i = 0; i < big.length; i++) { big[i] = (i * 7) & 255; }
	r = await c.req(st, 'PUT games/scores.dat', Buffer.from('ACE 9999'));
	check('store put', r.text === 'OK 8', r.text);
	r = await c.req(st, 'PUT big.bin', big);
	check('store put 5000', r.text === 'OK 5000', r.text);
	r = await c.req(st, 'GET games/scores.dat');
	check('store get', r.text === 'OK 8' && r.body.toString() === 'ACE 9999', r.text + ' ' + r.body);
	r = await c.req(st, 'GET big.bin');
	check('store get 5000 in parts', r.text === 'OK 5000' && r.body.equals(big) && r.frames > 1, r.text + ' frames ' + r.frames + ' len ' + r.body.length);
	r = await c.req(st, 'GET big.bin 4990 20');
	check('store get a piece', r.text === 'OK 10' && r.body.equals(big.slice(4990)), r.text);
	r = await c.req(st, 'APPEND games/scores.dat', Buffer.from(' BOB 10'));
	check('store append', r.text === 'OK 15', r.text);
	r = await c.req(st, 'LIST');
	check('store list', /^OK 2/.test(r.text) && /games\/scores\.dat 15 /.test(r.body.toString()), r.text + ' ' + r.body);
	check('store kept on the Pi (its machine\'s folder)', fs.existsSync(path.join(STORE, 'testcpc', 'games', 'scores.dat')), '');
	r = await c.req(st, 'GET ../../etc/passwd');
	check('store refuses a path out', /^ERR/.test(r.text), r.text);
	r = await c.req(st, 'DEL big.bin');
	check('store del', r.text === 'OK', r.text);

	// RUN: output, exit code
	var rn = await c.open('run');
	var strOut = '';
	r = await c.req(rn, 'RUN echo hello; echo there; exit 3', null, function(t, b) { strOut += b.toString(); });
	check('run: output and exit', r.text === 'OK exit=3' && strOut === 'hello\r\nthere\r\n', JSON.stringify([r.text, strOut]));

	// MATH
	var m = await c.open('math');
	r = await c.req(m, 'EVAL 2^10 + sqrt(16) * 3 - (1 + 1)');
	check('math eval', r.text === 'OK 1034', r.text);
	r = await c.req(m, 'EVAL atan2(1, 1) * 4');
	check('math eval functions', /^OK 3\.14159265358979/.test(r.text), r.text);
	r = await c.req(m, 'BIG 2^128');
	check('math big', r.text === 'OK 340282366920938463463374607431768211456', r.text);
	r = await c.req(m, 'EVAL require("fs")');
	check('math refuses code', /^ERR/.test(r.text), r.text);
	var x = Buffer.alloc(30 + 6 * 2);
	[256, 0, 0, 0, 0, 256, 0, 0, 0, 0, 256, 0].forEach(function(v, k) { x.writeInt16LE(v, k * 2); });
	x.writeInt16LE(160, 24); x.writeInt16LE(100, 26); x.writeInt16LE(100, 28);
	x.writeInt16LE(10, 30); x.writeInt16LE(20, 32); x.writeInt16LE(100, 34);
	x.writeInt16LE(0, 36); x.writeInt16LE(0, 38); x.writeInt16LE(-5, 40);
	r = await c.req(m, 'XFORM', x);
	check('math xform', r.text === 'OK 2' && r.body.readInt16LE(0) === 170 && r.body.readInt16LE(2) === 80 && r.body.readInt16LE(4) === -32768, r.text + ' ' + (r.body.length ? [r.body.readInt16LE(0), r.body.readInt16LE(2), r.body.readInt16LE(4)] : ''));

	// FLOAT: the coprocessor behind NTC's Float class - the answers the Z80 engine gives
	var fl = await c.open('float');
	function f32(v) { var b = Buffer.alloc(4); b.writeFloatLE(v, 0); return b.readUInt32LE(0); }
	function op3(a, b, cc) { var q = Buffer.alloc(12); q.writeUInt32LE(a >>> 0, 0); q.writeUInt32LE(b >>> 0, 4); q.writeUInt32LE(cc >>> 0, 8); return q; }
	r = await c.req(fl, 'OP 4', op3(f32(1), f32(3), 0));
	check('float divide', r.text === 'OK' && r.body.readUInt32LE(0) === 0x3EAAAAAB && r.body[4] === 0, r.text + ' ' + (r.body.length ? r.body.readUInt32LE(0).toString(16) : ''));
	r = await c.req(fl, 'OP 3', op3(f32(1e30), f32(1e30), 0));
	check('float overflow', r.body.readUInt32LE(0) === 0x7F800000 && r.body[4] === 1, r.body.length ? r.body.readUInt32LE(0).toString(16) : r.text);
	r = await c.req(fl, 'OP 11', op3(-7, 2, 4));
	check('float muldiv', r.body.readInt32LE(0) === -4, r.body.length ? r.body.readInt32LE(0) : r.text);
	r = await c.req(fl, 'OP 11', op3(2000000000, 2000000000, 3));
	check('float muldiv clamped', r.body.readInt32LE(0) === 2147483647 && r.body[4] === 1, r.body.length ? r.body.readInt32LE(0) : r.text);
	r = await c.req(fl, 'OP 10', op3(f32(0.1), 0, 0));
	check('float to half', (r.body.readUInt32LE(0) & 0xFFFF) === 0x2E66, r.body.length ? r.body.readUInt32LE(0).toString(16) : r.text);
	var mm = Buffer.alloc(4 + 6 * 4 + 6 * 4);
	mm.writeInt32LE(1, 0);
	[1, 2, 3, 4, 5, 6].forEach(function(v, k) { mm.writeUInt32LE(f32(v), 4 + k * 4); });
	[7, 8, 9, 10, 11, 12].forEach(function(v, k) { mm.writeUInt32LE(f32(v), 28 + k * 4); });
	r = await c.req(fl, 'MAT 3 4 2 3 2', mm);
	check('float matrix product', r.text === 'OK' && [0, 1, 2, 3].map(function(k) { return r.body.readFloatLE(k * 4); }).join(' ') === '58 64 139 154', r.body.length ? [0, 1, 2, 3].map(function(k) { return r.body.readFloatLE(k * 4); }).join(' ') : r.text);
	var dt = Buffer.alloc(4 + 8 + 8);                   // a fixed dot product (2 places, 16 bit): 1 x 4 by 4 x 1
	dt.writeInt32LE(100, 0);
	[125, 250, 375, 500].forEach(function(v, k) { dt.writeInt16LE(v, 4 + k * 2); });
	[50, 50, 50, 50].forEach(function(v, k) { dt.writeInt16LE(v, 12 + k * 2); });
	r = await c.req(fl, 'MAT 7 2 1 4 1', dt);
	check('float fixed dot (one rounding)', r.body.readInt16LE(0) === 625, r.body.length ? r.body.readInt16LE(0) : r.text);
	var ar = Buffer.alloc(8 + 8);                       // fixed 16 bit times 300: clamped
	ar.writeInt32LE(100, 0); ar.writeInt32LE(30000, 4);
	[125, 250, 375, 500].forEach(function(v, k) { ar.writeInt16LE(v, 8 + k * 2); });
	r = await c.req(fl, 'ARR 7 2 1 4', ar);
	check('float array clamped', r.text === 'OK 4' && r.body.readInt16LE(0) === 32767 && r.body[8] === 1, r.text + ' ' + (r.body.length ? r.body.readInt16LE(0) : ''));

	// TERM: a shell, a command typed, its output, the exit
	var tm = await c.open('term', 'cols=40 rows=12 type=dumb cmd=/bin/sh');
	var strT = '', strEv = '';
	c.chan[tm].onData = function(b) { strT += b.toString(); };
	c.chan[tm].onEvt = function(t) { strEv += t; };
	await wait(400);
	c.data(tm, Buffer.from('stty size; echo DONE$((6*7))\rexit\r'));
	await wait(1500);
	check('term: the size, a command, the exit', /12 40/.test(strT) && /DONE42/.test(strT) && /EXIT 0/.test(strEv), JSON.stringify([strT.slice(-120), strEv]));

	// VDU: the page served, a display opened, its lines streamed to a viewer
	var vd = await c.open('vdu', 'mode=hd title=Test');
	var strPage = await new Promise(function(ok) { require('http').get('http://127.0.0.1:8394/', function(res) { var s = ''; res.on('data', function(k) { s += k; }); res.on('end', function() { ok(s); }); }); });
	check('vdu: the page', /CyborgOS display/.test(strPage), strPage.slice(0, 80));
	var strEvt = await new Promise(function(ok)
	{
		var s = '';
		var rq = require('http').get('http://127.0.0.1:8394/events', function(res) { res.on('data', function(k) { s += k; if (/TEXT 10 10 Hello/.test(s)) { rq.destroy(); ok(s); } }); });
		setTimeout(function() { c.data(vd, Buffer.from('CLS 0 0 64\nCOLOR 255 255 0\nTEXT 10 10 Hello\n')); }, 200);
		setTimeout(function() { rq.destroy(); ok(s); }, 2000);
	});
	check('vdu: lines to the viewer', /"open":\d+.*"mode":"hd"/.test(strEvt) && /TEXT 10 10 Hello/.test(strEvt), strEvt.slice(0, 200));
	var strTouch = await new Promise(function(ok)
	{
		c.chan[vd].onEvt = function(t) { ok(t); };
		var rq = require('http').request({ host: '127.0.0.1', port: 8394, path: '/event', method: 'POST' });
		rq.end(JSON.stringify({ d: 1, e: 'TOUCH 100 200' }));
		setTimeout(function() { ok('(none)'); }, 1500);
	});
	check('vdu: a touch back to the CPC', strTouch === 'TOUCH 100 200', strTouch);

	// DISK: Pi volumes - made, mounted, a file written and read back at random, wildcards, folders
	var dk = await c.open('disk');
	r = await c.req(dk, 'NEW games');
	check('disk: a new volume', r.text === 'OK' && fs.existsSync(path.join(VOLS, 'GAMES')), r.text);
	r = await c.req(dk, 'MOUNT GAMES G');
	check('disk: mounted as G:', r.text === 'OK GAMES G', r.text);
	r = await c.req(dk, 'MOUNT GAMES Q');
	check('disk: a letter past P refused', /^ERR a drive letter A-P/.test(r.text), r.text);
	r = await c.req(dk, 'OPEN G:SCORES.DAT new');
	var hd = r.text.split(' ')[1];
	check('disk: a file made', r.text === 'OK 0 0 0', r.text);
	var rec = function(ch) { return Buffer.alloc(128, ch); };
	r = await c.req(dk, 'WRITE ' + hd + ' 0', Buffer.concat([rec(65), rec(66), rec(67)]));
	check('disk: 3 records written', r.text === 'OK 3', r.text);
	r = await c.req(dk, 'WRITE ' + hd + ' 10', rec(90));
	check('disk: record 10 written (random, past the end)', r.text === 'OK 1', r.text);
	r = await c.req(dk, 'READ ' + hd + ' 10');
	check('disk: record 10 read back', r.text === 'OK 1' && r.body.length === 128 && r.body[0] === 90, r.text);
	r = await c.req(dk, 'READ ' + hd + ' 1 2');
	check('disk: records 1-2 read', r.text === 'OK 2' && r.body[0] === 66 && r.body[128] === 67, r.text);
	r = await c.req(dk, 'READ ' + hd + ' 11');
	check('disk: past the end', r.text === 'OK 0', r.text);
	r = await c.req(dk, 'SIZE ' + hd);
	check('disk: its size', r.text === 'OK 11 1408', r.text);
	r = await c.req(dk, 'WRITE ' + hd + ' 11', Buffer.from('HELLO'));
	r = await c.req(dk, 'READ ' + hd + ' 11');
	check('disk: a part record padded with ^Z', r.body.slice(0, 5).toString() === 'HELLO' && r.body[5] === 0x1A && r.body.length === 128, r.text);
	r = await c.req(dk, 'CLOSE ' + hd);
	check('disk: closed', r.text === 'OK', r.text);
	fs.writeFileSync(path.join(VOLS, 'GAMES', 'readme.txt'), 'small letters on the Pi');
	fs.writeFileSync(path.join(VOLS, 'GAMES', 'a long name.text'), 'not 8.3');
	r = await c.req(dk, 'MKDIR G:SAVES');
	r = await c.req(dk, 'FIND G:*.*');
	check('disk: FIND (8.3 only, folders)', r.text === 'OK 3' && /README\.TXT 23/.test(r.body.toString()) && /SAVES <DIR>/.test(r.body.toString()) && !/LONG/.test(r.body.toString()), r.text + ' ' + r.body);
	r = await c.req(dk, 'FIND G:*.DAT');
	check('disk: FIND a pattern', r.text === 'OK 1' && /SCORES\.DAT 1536/.test(r.body.toString()), r.text + ' ' + r.body);
	r = await c.req(dk, 'OPEN G:readme.txt ro');
	check('disk: a Pi file found whatever its case', /^OK \d+ 1 23$/.test(r.text), r.text);
	await c.req(dk, 'CLOSE ' + r.text.split(' ')[1]);
	r = await c.req(dk, 'OPEN G:SAVES/SLOT1.SAV new');
	check('disk: a file in a folder', /^OK \d+ 0 0$/.test(r.text) && fs.existsSync(path.join(VOLS, 'GAMES', 'SAVES', 'SLOT1.SAV')), r.text);
	await c.req(dk, 'CLOSE ' + r.text.split(' ')[1]);
	r = await c.req(dk, 'OPEN G:../../etc/passwd');
	check('disk: a path out of the volume refused', /^ERR a path must stay/.test(r.text), r.text);
	r = await c.req(dk, 'REN G:HISCORE.DAT G:SCORES.DAT');
	check('disk: renamed', r.text === 'OK' && fs.existsSync(path.join(VOLS, 'GAMES', 'HISCORE.DAT')), r.text);
	r = await c.req(dk, 'ERA G:*.TXT');
	check('disk: ERA a pattern', r.text === 'OK 1', r.text);
	r = await c.req(dk, 'FREE G');
	check('disk: free space', /^OK \d+$/.test(r.text), r.text);
	r = await c.req(dk, 'NEW docs');
	r = await c.req(dk, 'MOUNT DOCS G');
	check('disk: a letter already a volume\'s refused', /^ERR G: is GAMES's/.test(r.text), r.text);
	r = await c.req(dk, 'MOUNT DOCS D ro');
	r = await c.req(dk, 'OPEN D:NEW.TXT new');
	check('disk: a read-only volume refuses writing', /^ERR the volume is read-only/.test(r.text), r.text);
	r = await c.req(dk, 'DROP GAMES');
	check('disk: DROP needs YES', /^ERR DROP name YES/.test(r.text), r.text);
	r = await c.req(dk, 'DROP GAMES YES');
	check('disk: DROP refused while mounted', /is mounted/.test(r.text), r.text);
	r = await c.req(dk, 'VOLUMES');
	check('disk: VOLUMES', r.text === 'OK 2' && /DOCS D ro 0 0/.test(r.body.toString()) && /GAMES G rw 3 /.test(r.body.toString()), r.text + ' ' + r.body);
	// the mounted volumes announced at the start: 4 at most
	['V1', 'V2', 'V3'].forEach(function(v, k) { fs.mkdirSync(path.join(VOLS, v), { recursive: true }); });
	var objV = JSON.parse(fs.readFileSync(path.join(VOLS, 'volumes.json'), 'utf8'));
	objV.volumes.V1 = { letter: 'H', ro: false }; objV.volumes.V2 = { letter: 'I', ro: false }; objV.volumes.V3 = { letter: 'J', ro: false };
	fs.writeFileSync(path.join(VOLS, 'volumes.json'), JSON.stringify(objV));
	var c4 = new Client({ max: 256 }), arrAnn = [];
	c4.onEvt = function(ch, t) { if (ch === 0) { arrAnn.push(t); } };
	await c4.connect(7310);
	await c4.hello('COS1 name=testcpc max=256');
	await wait(300);
	check('disk: 4 mounted volumes announced at the start (of 5)', arrAnn.length === 4 && arrAnn[0] === 'MOUNTED DOCS D ro' && arrAnn[1] === 'MOUNTED GAMES G', JSON.stringify(arrAnn));
	c4.end();

	// credit: a channel with none left waits until the CPC gives it more
	var c2 = new Client({ max: 256, noCredit: true });
	await c2.connect(7310);
	await c2.hello('COS1 name=testcpc max=256');
	var st2 = await c2.open('store', 'credit=100');
	var blnGot = false;
	var pr = c2.req(st2, 'GET games/scores.dat').then(function() { blnGot = true; });
	await c2.req(0, 'PING');
	var big2 = Buffer.alloc(600, 65);
	await c.req(st, 'PUT b2', big2);
	var pr2 = c2.req(st2, 'GET b2');
	var blnGot2 = false; pr2.then(function() { blnGot2 = true; });
	await wait(500);
	var blnWaited = blnGot && !blnGot2;
	c2.raw(st2, P.T.CREDIT, 0, Buffer.from([0, 4]));
	await wait(500);
	check('credit: held back, then sent', blnWaited && blnGot2, JSON.stringify([blnGot, blnGot2]));
	c2.end(); c.end();
	d.kill();
	await wait(300);

	// cplink2: this test as the bridge - the FIFO on 7320, the Pi ROM on 7321
	var arrRom = [];
	var srvRom = net.createServer(function(s) { var bs = []; s.on('data', function(b) { bs.push(b); }); s.on('end', function() { var all = Buffer.concat(bs); arrRom.push(all); s.end('OK ' + all.length + '\n'); }); }).listen(7321, '127.0.0.1');
	var c3 = new Client({ max: 256 });
	var pLink = new Promise(function(ok) { var srv = net.createServer(function(s) { c3.attach(s); ok(srv); }).listen(7320, '127.0.0.1'); });
	var d2 = start('cplink2:7320', 8395);
	var srvFifo = await pLink;
	await c3.hello('COS1 name=testcpc max=256');
	var st3 = await c3.open('store');
	r = await c3.req(st3, 'GET games/scores.dat');
	check('cplink2: a small answer in the frame', r.text === 'OK 15', r.text);
	await c3.req(st3, 'PUT big3', Buffer.alloc(3000, 66));
	r = await c3.req(st3, 'GET big3');
	check('cplink2: a big answer through the Pi ROM', r.text === 'BULK 3000 OK 3000' && arrRom.length === 1 && arrRom[0].length === 3000 && arrRom[0][2999] === 66, r.text + ' rom ' + arrRom.map(function(b) { return b.length; }));
	c3.end(); d2.kill(); srvRom.close(); srvFifo.close();
	await wait(200);
	fs.rmSync(STORE, { recursive: true, force: true });
	fs.rmSync(VOLS, { recursive: true, force: true });
	console.log(intRun + ' tests, ' + intFail + ' failed');
	process.exit(intFail ? 1 : 0);
}
main().catch(function(e) { console.log('test: ' + e.stack); process.exit(1); });
