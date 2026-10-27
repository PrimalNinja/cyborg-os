// cosd.js - CyborgOS's Pi side: the services a CPC or a ZX Spectrum Next asks for over its link
// (docs/cyborgos-pi.md). One byte stream, many channels: the control channel (0) opens the others,
// each to a service - STORE (tagged data kept on the Pi), RUN (a command, its output back), TERM (a
// shell on a pseudo terminal of the CPC's size), MATH (a coprocessor), VDU (a full HD virtual
// display on the Pi's HDMI, RVDU's commands), AUDIO (playing on the Pi) - with more to come.
//
//   node cosd.js [--link=tcp:7000 | tcp-connect:host:port | serial:/dev/ttyAMA0:115200 |
//                 cplink:7001] [--store=DIR] [--volumes=DIR] [--vdu=8084] [--no-run] [--trace]
//     tcp:PORT          wait for the link on a TCP port (127.0.0.1): tests, cosctl.js
//     tcp-connect:H:P   connect to one (1984's USIfAC in TCP mode: 127.0.0.1:4001)
//     serial:DEV:BAUD   a serial line (stty sets it raw): USIfAC, the Next's Pi Zero UART
//     cplink:PORT       the CPC-CPLink: cplink-bridge (C, the GPIO) on 127.0.0.1:PORT
//     cplink2:PORT      the CPLink2: the same, and big answers through its Pi ROM (the bridge's
//                       PORT + 1): the CPC reads them at &C000 (ROM 32 / 33) - BULK n in the frame
//     --store           where STORE keeps its tags (~/.cosd/store), a folder a machine
//     --volumes         the Pi volumes (DISK): /home/cyborgos/<volume>/, volumes.json there
//     --vdu             the virtual display's web page (http://pi:8084/): the HDMI's browser
//     --no-run          RUN and TERM refused (the Pi's shell kept from the link)
// No npm packages: Node 14+ only.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var net = require('net'), fs = require('fs'), path = require('path'), os = require('os'), cp = require('child_process');
var P = require('./proto.js'), T = P.T;

var VERSION = 'COS1 cosd 0.1';
var objArg = {};
process.argv.slice(2).forEach(function(a) { var m = a.match(/^--([\w-]+)(?:=(.*))?$/); if (m) { objArg[m[1]] = (m[2] === undefined) ? true : m[2]; } });
var LINK = objArg.link || 'tcp:7000';
var STORE = path.resolve(objArg.store || path.join(os.homedir(), '.cosd', 'store'));
var TRACE = !!objArg.trace;
var ALLOWRUN = !objArg['no-run'];
var PIMAX = 1024;									// the longest payload the Pi takes

function log() { if (TRACE) { console.log.apply(console, ['[cosd]'].concat([].slice.call(arguments))); } }

// ---- the services: name -> { about, ready, open(objCh, strArgs) -> handler }
// A handler: { req(objCh, intId, strText, bufBody), data(objCh, buf), close(objCh) } - any of them
var SVC = {};
function service(strName_a, strAbout_a, fnOpen_a) { SVC[strName_a] = { about: strAbout_a, ready: !!fnOpen_a, open: fnOpen_a }; }
var VOLUMES = path.resolve(objArg.volumes || '/home/cyborgos');
['store', 'run', 'term', 'math', 'vdu', 'audio', 'disk'].forEach(function(s) { require('./svc/' + s + '.js')(service, { STORE: STORE, ALLOWRUN: ALLOWRUN, VDU: objArg.vdu || '8084', VOLUMES: VOLUMES, log: log }); });
service('plugin', 'code sent from the CPC / Next, loaded as a plugin while its program runs', null);
service('rat', 'RAT decision models served from the Pi (a slot\'s ports)', null);
service('slot', 'a CyborgOS slot on the Pi (RAT models, a Linux terminal) reached by name', null);

// ---- a session: one link, its channels
function Session(fnWrite_a, objLink_a)
{
	var s = this;

	s.write = fnWrite_a; s.link = objLink_a; s.chans = {}; s.hello = null; s.max = 256; s.machine = 'unknown';
	s.parser = new P.Parser(PIMAX, function(f) { s.frame(f); });
	s.chans[0] = { n: 0, svc: 'control', credit: Infinity, queue: [], h: null };
}
Session.prototype.send = function(intChan_a, intType_a, intId_a, bufPay_a)
{
	// the CPC's longest payload: a longer one in parts (an answer's parts carry MORE but the last)
	var buf = bufPay_a || Buffer.alloc(0), ch = this.chans[intChan_a], i, intN, bufPart;

	if (!ch) { return; }
	if (buf.length <= this.max) { this.queue(ch, P.encode(intChan_a, intType_a, intId_a, buf), buf.length); return; }
	for (i = 0; i < buf.length; i += this.max)
	{
		intN = Math.min(this.max, buf.length - i);
		bufPart = buf.slice(i, i + intN);
		this.queue(ch, P.encode(intChan_a, intType_a, intId_a, bufPart), intN);	// (DATA: a stream - cut anywhere)
	}
};
// a channel's frames go out while it has credit (what the CPC said it has room for), else wait
Session.prototype.queue = function(objCh_a, bufFrame_a, intCost_a)
{
	objCh_a.queue.push({ f: bufFrame_a, c: intCost_a });
	this.flush(objCh_a);
};
Session.prototype.flush = function(objCh_a)
{
	while (objCh_a.queue.length && objCh_a.credit >= objCh_a.queue[0].c)
	{
		var q = objCh_a.queue.shift();
		objCh_a.credit -= q.c;
		this.write(q.f);
	}
};
Session.prototype.rsp = function(intChan_a, intId_a, strText_a, bufBody_a)
{
	var s = this;

	// the CPLink2: a big answer's data through the Pi ROM (ROM 32 / 33 at &C000, 32K at most) -
	// the frame then only says so: BULK n then the answer's text, no data
	if (s.romPort && bufBody_a && bufBody_a.length > 2 * s.max && bufBody_a.length <= 32768)
	{
		s.bulkq = (s.bulkq || Promise.resolve()).then(function()
		{
			return new Promise(function(fnDone)
			{
				var sock = net.connect(s.romPort, '127.0.0.1', function() { sock.end(bufBody_a); });
				sock.on('data', function() { /* OK n */ });
				sock.on('close', function() { s.send(intChan_a, T.RSP, intId_a, P.payload('BULK ' + bufBody_a.length + ' ' + strText_a)); fnDone(); });
				sock.on('error', function() { s.send(intChan_a, T.RSP, intId_a, P.payload(strText_a, bufBody_a)); fnDone(); });
			});
		});
		return;
	}
	s.parts(intChan_a, T.RSP, intId_a, strText_a, bufBody_a, false);
};
// an answer (or an event) in parts when it is longer than the CPC's frames: each part its text,
// a 0, the next piece of the data - MORE on every part but the last (blnMore_a: on that one too:
// RUN's output, the answer's end still to come)
Session.prototype.parts = function(intChan_a, intType_a, intId_a, strText_a, bufBody_a, blnMore_a)
{
	var s = this, bufT = Buffer.from(strText_a || '', 'latin1'), intRoom = s.max - bufT.length - 1, i, bufP;

	if (!bufBody_a || bufT.length + 1 + bufBody_a.length <= s.max || intRoom < 16)
	{
		s.send(intChan_a, intType_a | (blnMore_a ? T.MORE : 0), intId_a, P.payload(strText_a, bufBody_a));
		return;
	}
	for (i = 0; i < bufBody_a.length; i += intRoom)
	{
		bufP = bufBody_a.slice(i, i + intRoom);
		var blnLast = i + intRoom >= bufBody_a.length;
		s.send(intChan_a, intType_a | (!blnLast || blnMore_a ? T.MORE : 0), intId_a, Buffer.concat([bufT, Buffer.from([0]), bufP]));
	}
};
Session.prototype.evt = function(intChan_a, strText_a, bufBody_a) { this.send(intChan_a, T.EVT, 0, P.payload(strText_a, bufBody_a)); };
Session.prototype.data = function(intChan_a, buf_a) { this.send(intChan_a, T.DATA, 0, buf_a); };
Session.prototype.close = function(intChan_a, strWhy_a)
{
	var ch = this.chans[intChan_a];

	if (!ch || intChan_a === 0) { return; }
	this.send(intChan_a, T.CLOSE, 0, Buffer.from(strWhy_a || '', 'latin1'));
	delete this.chans[intChan_a];
	if (ch.h && ch.h.close) { try { ch.h.close(ch); } catch (e) { log('close', e.message); } }
};
Session.prototype.frame = function(f)
{
	var s = this, ch = s.chans[f.chan], o;

	log('in', f.chan, f.type, f.id, f.payload.length);
	if (f.type === T.HELLO)
	{
		o = P.split(f.payload);
		s.hello = o.text;
		s.max = Math.max(32, Math.min(PIMAX, parseInt(kv(o.text, 'max') || '256', 10)));
		s.machine = (kv(o.text, 'name') || kv(o.text, 'machine') || 'cpc').replace(/[^A-Za-z0-9_-]/g, '').slice(0, 16) || 'cpc';
		s.cols = parseInt(kv(o.text, 'cols') || '80', 10); s.rows = parseInt(kv(o.text, 'rows') || '24', 10);
		s.send(0, T.HELLO, f.id, P.payload(VERSION + ' max=' + PIMAX + ' host=' + os.hostname() + ' link=' + s.link + ' services=' + Object.keys(SVC).filter(function(k) { return SVC[k].ready; }).join(',')));
		require('./svc/disk.js').announce(s);		// the mounted Pi volumes: MOUNTED name X (4 at most)
		return;
	}
	if (!ch) { s.send(0, T.EVT, 0, P.payload('ERR nochan ' + f.chan)); return; }
	if (f.type === T.CREDIT)
	{
		ch.credit += f.payload.length >= 2 ? (f.payload[0] | (f.payload[1] << 8)) : 0;
		s.flush(ch);
		return;
	}
	if (f.type === T.CLOSE) { if (f.chan !== 0) { delete s.chans[f.chan]; if (ch.h && ch.h.close) { ch.h.close(ch); } } return; }
	if (f.chan === 0) { if (f.type === T.REQ) { s.control(f.id, P.split(f.payload)); } return; }
	try
	{
		if (f.type === T.REQ && f.more)
		{
			// a request in parts (a PUT bigger than a frame): its text from the first, the data put together
			o = P.split(f.payload);
			ch.reqs = ch.reqs || {};
			if (!ch.reqs[f.id]) { ch.reqs[f.id] = { text: o.text, body: [] }; }
			if (o.body) { ch.reqs[f.id].body.push(o.body); }
			return;
		}
		if (f.type === T.REQ && ch.h.req)
		{
			o = P.split(f.payload);
			if (ch.reqs && ch.reqs[f.id]) { var r = ch.reqs[f.id]; delete ch.reqs[f.id]; if (o.body) { r.body.push(o.body); } o = { text: r.text, body: Buffer.concat(r.body) }; }
			ch.h.req(ch, f.id, o.text, o.body);
		}
		else if (f.type === T.DATA && ch.h.data) { ch.h.data(ch, f.payload); }
		else if (f.type === T.REQ) { s.rsp(f.chan, f.id, 'ERR noreq ' + ch.svc + ' takes no requests'); }
	}
	catch (e) { s.rsp(f.chan, f.id, 'ERR fail ' + e.message); }
};

// ---- the control channel's requests
Session.prototype.control = function(intId_a, o)
{
	var s = this, w = o.text.trim().split(/\s+/), cmd = (w[0] || '').toUpperCase(), d, i, intCh;

	if (cmd === 'PING') { s.rsp(0, intId_a, 'OK PONG'); }
	else if (cmd === 'TIME')
	{
		d = new Date();
		var z = -d.getTimezoneOffset(), strZ = (z >= 0 ? '+' : '-') + p2(Math.floor(Math.abs(z) / 60)) + ':' + p2(Math.abs(z) % 60);
		s.rsp(0, intId_a, 'OK ' + d.getFullYear() + '-' + p2(d.getMonth() + 1) + '-' + p2(d.getDate()) + ' ' + p2(d.getHours()) + ':' + p2(d.getMinutes()) + ':' + p2(d.getSeconds()) + ' ' + strZ + ' ' + Math.floor(d.getTime() / 1000) + ' ' + (d.getDay() + 1));
	}
	else if (cmd === 'INFO')
	{
		var strTemp = '';
		try { strTemp = ' temp=' + (parseInt(fs.readFileSync('/sys/class/thermal/thermal_zone0/temp', 'latin1'), 10) / 1000).toFixed(1); } catch (e) { /* not a Pi */ }
		var strModel = '';
		try { strModel = fs.readFileSync('/proc/device-tree/model', 'latin1').replace(/\0/g, ''); } catch (e) { strModel = os.type() + ' ' + os.arch(); }
		s.rsp(0, intId_a, 'OK ' + VERSION + ' host=' + os.hostname() + ' uptime=' + Math.floor(os.uptime()) + strTemp + ' machine=' + s.machine, Buffer.from(strModel, 'latin1'));
	}
	else if (cmd === 'LIST')
	{
		s.rsp(0, intId_a, 'OK ' + Object.keys(SVC).length, Buffer.from(Object.keys(SVC).map(function(k) { return k + ' ' + (SVC[k].ready ? 'ready' : 'notyet') + ' ' + SVC[k].about; }).join('\r\n'), 'latin1'));
	}
	else if (cmd === 'CHANS')
	{
		s.rsp(0, intId_a, 'OK', Buffer.from(Object.keys(s.chans).map(function(k) { return k + ' ' + s.chans[k].svc; }).join('\r\n'), 'latin1'));
	}
	else if (cmd === 'OPEN')
	{
		var strSvc = (w[1] || '').toLowerCase(), objS = SVC[strSvc];
		if (!objS) { s.rsp(0, intId_a, 'ERR noservice ' + strSvc); return; }
		if (!objS.ready) { s.rsp(0, intId_a, 'ERR notyet ' + strSvc + ' is not there yet'); return; }
		for (intCh = 1; intCh < 255 && s.chans[intCh]; intCh++) { /* the first free */ }
		if (intCh >= 255) { s.rsp(0, intId_a, 'ERR full'); return; }
		var strArgs = w.slice(2).join(' ');
		var ch = { n: intCh, svc: strSvc, credit: parseInt(kv(strArgs, 'credit') || '1024', 10), queue: [], s: s, h: null, args: strArgs };
		s.chans[intCh] = ch;
		try { ch.h = objS.open(ch, strArgs) || {}; }
		catch (e) { delete s.chans[intCh]; s.rsp(0, intId_a, 'ERR fail ' + e.message); return; }
		s.rsp(0, intId_a, 'OK ' + intCh);
	}
	else if (cmd === 'CLOSE')
	{
		intCh = parseInt(w[1], 10);
		if (!s.chans[intCh] || intCh === 0) { s.rsp(0, intId_a, 'ERR nochan'); return; }
		s.close(intCh, 'closed');
		s.rsp(0, intId_a, 'OK');
	}
	else { s.rsp(0, intId_a, 'ERR unknown ' + cmd); }
};
Session.prototype.end = function()
{
	var s = this;

	Object.keys(s.chans).forEach(function(k) { var ch = s.chans[k]; if (k !== '0' && ch.h && ch.h.close) { try { ch.h.close(ch); } catch (e) { /* gone */ } } });
	s.chans = { 0: s.chans[0] };
};

function p2(n) { return (n < 10 ? '0' : '') + n; }
function kv(str_a, strKey_a) { var m = String(str_a || '').match(new RegExp('(?:^|\\s)' + strKey_a + '=(\\S+)', 'i')); return m ? m[1] : null; }

// ---- the links
function stream(sock_a, strName_a)
{
	var s = new Session(function(b) { if (!sock_a.destroyed) { sock_a.write(b); } }, strName_a);

	log('link up', strName_a);
	sock_a.on('data', function(b) { s.parser.feed(b); });
	sock_a.on('close', function() { log('link down', strName_a); s.end(); });
	sock_a.on('error', function(e) { log('link error', e.message); });
	return s;
}
var arrL = LINK.split(':');
if (arrL[0] === 'tcp')
{
	net.createServer(function(sock) { stream(sock, 'tcp'); }).listen(parseInt(arrL[1] || '7000', 10), objArg.bind || '127.0.0.1', function() { console.log('cosd: waiting on tcp ' + (objArg.bind || '127.0.0.1') + ':' + (arrL[1] || '7000')); });
}
else if (arrL[0] === 'tcp-connect' || arrL[0] === 'cplink' || arrL[0] === 'cplink2')
{
	var blnCp = arrL[0] !== 'tcp-connect';
	var strHost = blnCp ? '127.0.0.1' : arrL[1], intPort = parseInt(blnCp ? (arrL[1] || '7001') : arrL[2], 10);
	(function connect()
	{
		var sock = net.connect(intPort, strHost, function()
		{
			console.log('cosd: link ' + LINK);
			var objS = stream(sock, arrL[0]);
			if (arrL[0] === 'cplink2') { objS.romPort = intPort + 1; }	// (the bridge's Pi ROM writes)
		});
		sock.on('error', function() { /* not there yet */ });
		sock.on('close', function() { setTimeout(connect, 2000); });
	})();
}
else if (arrL[0] === 'serial')
{
	var strDev = arrL[1], strBaud = arrL[2] || '115200';
	cp.execFileSync('stty', ['-F', strDev, strBaud, 'raw', '-echo', '-crtscts', 'cs8', '-cstopb', '-parenb']);
	var fdIn = fs.createReadStream(strDev), fdOut = fs.createWriteStream(strDev);
	var objS = new Session(function(b) { fdOut.write(b); }, 'serial');
	fdIn.on('data', function(b) { objS.parser.feed(b); });
	console.log('cosd: link serial ' + strDev + ' ' + strBaud);
}
else { console.log('cosd: --link=tcp:PORT | tcp-connect:HOST:PORT | serial:DEV:BAUD | cplink:PORT | cplink2:PORT'); process.exit(1); }
