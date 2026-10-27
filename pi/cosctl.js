// cosctl.js - a stand-in for the CPC: talks to cosd.js over TCP with the link protocol, so the Pi's
// side is tested (and used) from any computer. Also a module: Client for test/run.js.
//
//   node cosctl.js [--host=127.0.0.1] [--port=7000] command ...
//     time | ping | info | list | chans
//     store put TAG FILE | store get TAG [FILE] | store del TAG | store list [PREFIX]
//     run "ls -l"            the output as it comes, then its exit code
//     math "2^0.5" | big "2^200"
//     term [cols rows]       a shell on the Pi in this terminal (Ctrl+] ends it)
//     vdu [hd] < lines       display commands to the Pi's screen
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var net = require('net'), fs = require('fs'), P = require('./proto.js'), T = P.T;

function Client(objOpt_a)
{
	var c = this;

	c.opt = objOpt_a || {}; c.id = 0; c.pending = {}; c.chan = {}; c.max = c.opt.max || 512;
	c.parser = new P.Parser(4096, function(f) { c.frame(f); });
}
Client.prototype.connect = function(intPort_a, strHost_a)
{
	var c = this;

	return new Promise(function(fnOk, fnErr)
	{
		c.sock = net.connect(intPort_a, strHost_a || '127.0.0.1', function() { fnOk(c); });
		c.sock.on('data', function(b) { c.parser.feed(b); });
		c.sock.on('error', fnErr);
	});
};
// a socket the link arrives on (cosd connecting to us: the cplink2 test stands in for the bridge)
Client.prototype.attach = function(sock_a) { var c = this; c.sock = sock_a; sock_a.on('data', function(b) { c.parser.feed(b); }); };
Client.prototype.raw = function(intChan_a, intType_a, intId_a, buf_a) { this.sock.write(P.encode(intChan_a, intType_a, intId_a, buf_a)); };
Client.prototype.frame = function(f)
{
	var c = this, p, o;

	if (f.type === T.HELLO) { p = c.pending['h']; delete c.pending['h']; if (p) { p.ok(P.split(f.payload).text); } return; }
	if (f.type === T.RSP)
	{
		p = c.pending[f.chan + ':' + f.id];
		if (!p) { return; }
		o = P.split(f.payload);
		if (f.more)
		{
			p.parts.push(o.body || Buffer.alloc(0));
			if (p.onPart) { p.onPart(o.text, o.body); }
			c.credit(f.chan, f.payload.length);
			return;
		}
		delete c.pending[f.chan + ':' + f.id];
		p.parts.push(o.body || Buffer.alloc(0));
		c.credit(f.chan, f.payload.length);
		p.ok({ text: o.text, body: Buffer.concat(p.parts), frames: p.parts.length });
		return;
	}
	if (f.type === T.DATA) { c.credit(f.chan, f.payload.length); if (c.chan[f.chan] && c.chan[f.chan].onData) { c.chan[f.chan].onData(f.payload); } return; }
	if (f.type === T.EVT) { c.credit(f.chan, f.payload.length); if (c.chan[f.chan] && c.chan[f.chan].onEvt) { c.chan[f.chan].onEvt(P.split(f.payload).text); } else if (c.onEvt) { c.onEvt(f.chan, P.split(f.payload).text); } return; }
	if (f.type === T.CLOSE) { if (c.chan[f.chan] && c.chan[f.chan].onClose) { c.chan[f.chan].onClose(f.payload.toString('latin1')); } delete c.chan[f.chan]; }
};
// what was taken off the channel: room for that much again (as the CPC would say once it has
// moved it on)
Client.prototype.credit = function(intChan_a, intN_a)
{
	if (this.opt.noCredit || !intN_a) { return; }
	this.raw(intChan_a, T.CREDIT, 0, Buffer.from([intN_a & 255, (intN_a >> 8) & 255]));
};
Client.prototype.hello = function(strText_a)
{
	var c = this;
	return new Promise(function(fnOk) { c.pending['h'] = { ok: fnOk }; c.raw(0, T.HELLO, 0, P.payload(strText_a || 'COS1 machine=cpc name=test max=' + c.max + ' cols=80 rows=24')); });
};
Client.prototype.req = function(intChan_a, strText_a, bufBody_a, fnPart_a)
{
	var c = this, id = c.id = (c.id % 255) + 1;
	return new Promise(function(fnOk)
	{
		c.pending[intChan_a + ':' + id] = { ok: fnOk, parts: [], onPart: fnPart_a };
		// longer than the Pi's frames (1024): in parts - the text, a 0, a piece; MORE but the last
		var intRoom = 1000 - Buffer.byteLength(strText_a, 'latin1'), i;
		if (!bufBody_a || bufBody_a.length <= intRoom) { c.raw(intChan_a, T.REQ, id, P.payload(strText_a, bufBody_a)); return; }
		for (i = 0; i < bufBody_a.length; i += intRoom)
		{
			c.raw(intChan_a, T.REQ | (i + intRoom < bufBody_a.length ? T.MORE : 0), id, P.payload(strText_a, bufBody_a.slice(i, i + intRoom)));
		}
	});
};
Client.prototype.open = function(strSvc_a, strArgs_a)
{
	var c = this;
	return c.req(0, 'OPEN ' + strSvc_a + (strArgs_a ? ' ' + strArgs_a : '')).then(function(r)
	{
		var m = r.text.match(/^OK (\d+)/);
		if (!m) { throw new Error(r.text); }
		c.chan[+m[1]] = {};
		return +m[1];
	});
};
Client.prototype.data = function(intChan_a, buf_a) { this.raw(intChan_a, T.DATA, 0, buf_a); };
Client.prototype.end = function() { this.sock.end(); };
module.exports = { Client: Client };

// ---- the command line
if (require.main === module)
{
	var objArg = {}, arrW = [];
	process.argv.slice(2).forEach(function(a) { var m = a.match(/^--(\w+)(?:=(.*))?$/); if (m) { objArg[m[1]] = m[2] === undefined ? true : m[2]; } else { arrW.push(a); } });
	var c = new Client();
	var cmd = (arrW[0] || 'time').toLowerCase();
	c.connect(parseInt(objArg.port || '7000', 10), objArg.host).then(function() { return c.hello(); }).then(function(h)
	{
		if (objArg.v) { console.log(h); }
		function done(r) { console.log(r.text); if (r.body && r.body.length && cmd !== 'store') { console.log(r.body.toString('latin1')); } c.end(); }
		if (cmd === 'time' || cmd === 'ping' || cmd === 'info' || cmd === 'list' || cmd === 'chans') { return c.req(0, cmd.toUpperCase()).then(done); }
		if (cmd === 'store')
		{
			return c.open('store').then(function(ch)
			{
				var s = (arrW[1] || '').toUpperCase();
				if (s === 'PUT') { return c.req(ch, 'PUT ' + arrW[2], fs.readFileSync(arrW[3])).then(done); }
				return c.req(ch, s + ' ' + arrW.slice(2, s === 'GET' ? 3 : undefined).join(' ')).then(function(r)
				{
					if (s === 'GET' && arrW[3]) { fs.writeFileSync(arrW[3], r.body); console.log(r.text + ' -> ' + arrW[3]); c.end(); return; }
					console.log(r.text); if (r.body && r.body.length) { process.stdout.write(r.body.toString('latin1') + '\n'); } c.end();
				});
			});
		}
		if (cmd === 'run')
		{
			return c.open('run').then(function(ch) { return c.req(ch, 'RUN ' + arrW.slice(1).join(' '), null, function(t, b) { process.stdout.write(b.toString('latin1')); }); }).then(function(r) { console.log(r.text); c.end(); });
		}
		if (cmd === 'math' || cmd === 'big') { return c.open('math').then(function(ch) { return c.req(ch, (cmd === 'big' ? 'BIG ' : 'EVAL ') + arrW.slice(1).join(' ')); }).then(done); }
		if (cmd === 'term')
		{
			return c.open('term', 'cols=' + (arrW[1] || process.stdout.columns || 80) + ' rows=' + (arrW[2] || process.stdout.rows || 24) + ' type=' + (process.env.TERM || 'vt100')).then(function(ch)
			{
				c.chan[ch].onData = function(b) { process.stdout.write(b); };
				c.chan[ch].onEvt = function(t) { process.stderr.write('\r\n[' + t + ']\r\n'); };
				c.chan[ch].onClose = function() { if (process.stdin.isTTY) { process.stdin.setRawMode(false); } c.end(); process.exit(0); };
				if (process.stdin.isTTY) { process.stdin.setRawMode(true); }
				process.stdin.on('data', function(b) { if (b[0] === 0x1D) { c.end(); process.exit(0); } c.data(ch, b); });
			});
		}
		if (cmd === 'vdu')
		{
			return c.open('vdu', arrW[1] === 'hd' ? 'mode=hd' : '').then(function(ch)
			{
				c.chan[ch].onEvt = function(t) { console.log('event: ' + t); };
				process.stdin.on('data', function(b) { c.data(ch, b); });
				process.stdin.on('end', function() { console.log('sent - Ctrl+C ends (the display goes with it)'); });
			});
		}
		console.log('commands: time ping info list chans | store put/get/del/list | run | math | big | term | vdu');
		c.end();
	}).catch(function(e) { console.log('cosctl: ' + e.message); process.exit(1); });
}
