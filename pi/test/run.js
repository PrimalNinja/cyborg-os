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
var intFail = 0, intRun = 0;

function check(strName_a, blnOk_a, strGot_a)
{
	intRun++;
	if (blnOk_a) { console.log('ok   ' + strName_a); } else { intFail++; console.log('FAIL ' + strName_a + ': ' + strGot_a); }
}
function wait(ms) { return new Promise(function(r) { setTimeout(r, ms); }); }
function start(strLink_a, intVdu_a)
{
	var p = cp.spawn(process.execPath, [path.join(PI, 'cosd.js'), '--link=' + strLink_a, '--store=' + STORE, '--vdu=' + intVdu_a], { stdio: ['ignore', 'pipe', 'pipe'] });
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
	console.log(intRun + ' tests, ' + intFail + ' failed');
	process.exit(intFail ? 1 : 0);
}
main().catch(function(e) { console.log('test: ' + e.stack); process.exit(1); });
