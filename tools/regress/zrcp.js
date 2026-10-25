// zrcp.js - ZEsarUX's remote protocol (ZRCP, port 10000): new Zrcp(port); await z.cmd('...') gives
// the answer up to its prompt. Used by espsim/nettest.js and regress/nextkeys.js.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var net = require('net');

function Zrcp(intPort_a)
{
	var self = this;
	self.buf = '';
	self.wait = null;
	self.sock = net.createConnection(intPort_a, '127.0.0.1');
	self.sock.setEncoding('latin1');
	self.sock.on('data', function(d) { self.buf += d; if (self.wait && /command> ?$/.test(self.buf)) { var w = self.wait; self.wait = null; w(self.buf); } });
	self.cmd = function(str_a)
	{
		return new Promise(function(r)
		{
			self.buf = '';
			self.wait = function(s) { r(s.replace(/command> ?$/, '').trim()); };
			self.sock.write(str_a + '\n');
			setTimeout(function() { if (self.wait) { var w = self.wait; self.wait = null; w(self.buf); } }, 8000);
		});
	};
}

module.exports = Zrcp;
