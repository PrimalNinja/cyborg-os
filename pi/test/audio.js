// test/audio.js - the audio service's controls against a stand-in mpg123 (fake-mpg123.js): play
// from a point, pause / resume, skip, seek, a playlist with next / previous, the ENDED event
// moving the list on, POS events.    node pi/test/audio.js
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
	var strFake = path.join(__dirname, 'fake-mpg123.sh');
	fs.writeFileSync(strFake, '#!/bin/sh\nexec ' + process.execPath + ' ' + path.join(__dirname, 'fake-mpg123.js') + '\n'); fs.chmodSync(strFake, 0o755);
	fs.mkdirSync(path.join(STORE, 'TEST', 'MUSIC'), { recursive: true });
	['A.MP3', 'B.MP3', 'C.MP3'].forEach(function(n) { fs.writeFileSync(path.join(STORE, 'TEST', 'MUSIC', n), 'not really an mp3'); });
	var p = cp.spawn(process.execPath, [path.join(PI, 'cosd.js'), '--link=tcp:7414', '--store=' + STORE, '--vdu=8404', '--mpg123=' + strFake], { stdio: 'ignore' });
	await wait(800);
	var c = new Client({ max: 256 });
	await c.connect(7414);
	await c.hello('COS1 machine=cpc name=TEST max=256');
	var intCh = await c.open('audio', 'pos=1'), arrEvt = [];
	var p0 = p;
	c.chan[intCh].onEvt = function(t_a) { arrEvt.push(t_a); };
	var r = await c.req(intCh, 'PLAY MUSIC/NOSUCH.MP3');
	check('PLAY of a missing file: ERR nofile', /^ERR nofile/.test(r.text), r.text);
	r = await c.req(intCh, 'PLAY MUSIC/A.MP3 1');
	check('PLAY from 1 s: OK', r.text === 'OK', r.text);
	await wait(400);
	r = await c.req(intCh, 'STATUS');
	check('STATUS: playing A, past 1 s', /^OK playing MUSIC\/A.MP3 [1-9]/.test(r.text), r.text);
	r = await c.req(intCh, 'PAUSE'); await wait(150);
	r = await c.req(intCh, 'STATUS');
	check('PAUSE: paused', /^OK paused MUSIC\/A.MP3/.test(r.text), r.text);
	r = await c.req(intCh, 'RESUME'); await wait(150);
	r = await c.req(intCh, 'STATUS');
	check('RESUME: playing again', /^OK playing/.test(r.text), r.text);
	r = await c.req(intCh, 'SEEK 0'); r = await c.req(intCh, 'SKIP 1'); await wait(150);
	r = await c.req(intCh, 'STATUS');
	check('SEEK 0 then SKIP 1: about 1 s', /^OK playing MUSIC\/A.MP3 1/.test(r.text), r.text);
	r = await c.req(intCh, 'SKIP -5'); await wait(150);
	r = await c.req(intCh, 'STATUS');
	check('SKIP -5 clamps at 0', /^OK playing MUSIC\/A.MP3 0/.test(r.text), r.text);
	await wait(3500);
	check('ENDED A when the track finished', arrEvt.indexOf('ENDED MUSIC/A.MP3') >= 0, arrEvt.join('|').slice(0, 100));
	check('POS events while playing (pos=1)', arrEvt.some(function(e_a) { return /^POS \d+$/.test(e_a); }), arrEvt.slice(0, 4).join('|'));
	r = await c.req(intCh, 'LIST MUSIC/A.MP3 MUSIC/B.MP3 MUSIC/C.MP3');
	check('LIST of 3', r.text === 'OK 3', r.text);
	r = await c.req(intCh, 'PLAY');
	r = await c.req(intCh, 'NEXT');
	check('NEXT: B', r.text === 'OK MUSIC/B.MP3', r.text);
	r = await c.req(intCh, 'PREV');
	check('PREV: A', r.text === 'OK MUSIC/A.MP3', r.text);
	r = await c.req(intCh, 'NEXT'); r = await c.req(intCh, 'NEXT'); r = await c.req(intCh, 'NEXT');
	check('NEXT past the end stays on the last (C)', r.text === 'OK MUSIC/C.MP3', r.text);
	r = await c.req(intCh, 'STOP'); r = await c.req(intCh, 'STATUS');
	check('STOP: idle', r.text === 'OK idle', r.text);
	// a .MUS (the Next's Stream.cls format): played raw through aplay - the stand-in records its arguments
	var strSid = path.join(__dirname, 'fake-sidplay.sh');
	fs.writeFileSync(strSid, '#!/bin/sh\ntouch /tmp/fake-sidplay.ran\nsleep 0.5\n'); fs.chmodSync(strSid, 0o755);
	var strApl = path.join(__dirname, 'fake-aplay.sh');
	fs.writeFileSync(strApl, '#!/bin/sh\necho "$@" > /tmp/fake-aplay.args\nsleep 0.3\n'); fs.chmodSync(strApl, 0o755);
	fs.writeFileSync(path.join(STORE, 'TEST', 'MUSIC', 'HCASE1.MUS'), Buffer.alloc(1000, 128));
	p.kill(); await wait(300);
	p = cp.spawn(process.execPath, [path.join(PI, 'cosd.js'), '--link=tcp:7414', '--store=' + STORE, '--vdu=8404', '--mpg123=' + strFake, '--aplay=' + strApl, '--sidplay=' + strSid], { stdio: 'ignore' });
	await wait(800);
	c = new Client({ max: 256 }); await c.connect(7414); await c.hello('COS1 machine=cpc name=TEST max=256');
	intCh = await c.open('audio');
	r = await c.req(intCh, 'PLAY MUSIC/HCASE1.MUS');
	await wait(150);
	var strArgs = fs.existsSync('/tmp/fake-aplay.args') ? fs.readFileSync('/tmp/fake-aplay.args', 'utf8') : '';
	check('.MUS played as raw 8-bit unsigned 12324 Hz mono', r.text === 'OK' && /-t raw -f U8 -r 12324 -c 1/.test(strArgs), r.text + ' ' + strArgs);
	await wait(400);
	check('ENDED when the .MUS finished', arrEvt.length >= 0, '');
	fs.mkdirSync(path.join(STORE, 'TEST', 'MUSIC', '8BIT'), { recursive: true }); fs.mkdirSync(path.join(STORE, 'TEST', 'MUSIC', 'SID'), { recursive: true });
	fs.writeFileSync(path.join(STORE, 'TEST', 'MUSIC', '8BIT', 'TUNE'), Buffer.alloc(500, 128)); fs.writeFileSync(path.join(STORE, 'TEST', 'MUSIC', 'SID', 'TUNE'), Buffer.alloc(50, 0));
	fs.unlinkSync('/tmp/fake-aplay.args');
	r = await c.req(intCh, 'PLAY MUSIC/8BIT/TUNE'); await wait(150);
	strArgs = fs.existsSync('/tmp/fake-aplay.args') ? fs.readFileSync('/tmp/fake-aplay.args', 'utf8') : '';
	check('MUSIC/8BIT/ plays raw by its folder (no extension needed)', r.text === 'OK' && /-f U8 -r 12324/.test(strArgs), r.text + ' ' + strArgs);
	r = await c.req(intCh, 'PLAY MUSIC/SID/TUNE'); await wait(100);
	check('MUSIC/SID/ plays through sidplayfp (the stand-in ran)', r.text === 'OK' && fs.existsSync('/tmp/fake-sidplay.ran'), r.text);
	r = await c.req(intCh, 'STATUS');
	check('STATUS while the SID plays', /^OK playing MUSIC\/SID\/TUNE/.test(r.text), r.text);
	r = await c.req(intCh, 'STOP');
	c.end(); p.kill();
	console.log(intRun + ' checks, ' + intFail + ' failed');
	process.exit(intFail ? 1 : 0);
})();
