// store.js - STORE: tagged data kept on the Pi between boots - a CPC's (or a Next's) own small
// file system there. A tag: up to 64 characters of A-Z a-z 0-9 _ - . / (a / a folder); each machine
// (its HELLO name=) has its own. Requests (a REQ's text, a 0, then its data):
//   PUT tag + data       kept (replacing): OK size          APPEND tag + data   added on: OK size
//   GET tag [from [n]]   OK size, the data (parts: RSP + MORE; in the CPLink2's ROM when big)
//   DEL tag              OK                                  SIZE tag            OK size date
//   LIST [prefix]        OK n, a line each: tag size yyyy-mm-dd hh:mm
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path');

module.exports = function(service, cfg)
{
	function file(ch, strTag)
	{
		if (!/^[A-Za-z0-9_.\/-]{1,64}$/.test(strTag) || /(^|\/)\.\.?(\/|$)/.test(strTag)) { throw new Error('bad tag ' + strTag); }
		var strDir = path.join(cfg.STORE, ch.s.machine);
		return path.join(strDir, strTag);
	}
	function when(d) { function p(n) { return (n < 10 ? '0' : '') + n; } return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate()) + ' ' + p(d.getHours()) + ':' + p(d.getMinutes()); }
	function walk(strDir, strPre, arrOut)
	{
		if (!fs.existsSync(strDir)) { return arrOut; }
		fs.readdirSync(strDir).sort().forEach(function(n)
		{
			var p = path.join(strDir, n), st = fs.statSync(p);
			if (st.isDirectory()) { walk(p, strPre + n + '/', arrOut); } else { arrOut.push(strPre + n + ' ' + st.size + ' ' + when(st.mtime)); }
		});
		return arrOut;
	}
	service('store', 'tagged data kept on the Pi between boots (PUT / GET / DEL / LIST)', function(ch)
	{
		return {
			req: function(ch, id, text, body)
			{
				var w = text.trim().split(/\s+/), c = (w[0] || '').toUpperCase(), f, buf, st;
				if (c === 'PUT' || c === 'APPEND')
				{
					f = file(ch, w[1] || '');
					fs.mkdirSync(path.dirname(f), { recursive: true });
					if (c === 'PUT') { fs.writeFileSync(f, body || Buffer.alloc(0)); } else { fs.appendFileSync(f, body || Buffer.alloc(0)); }
					ch.s.rsp(ch.n, id, 'OK ' + fs.statSync(f).size);
				}
				else if (c === 'GET')
				{
					f = file(ch, w[1] || '');
					if (!fs.existsSync(f)) { ch.s.rsp(ch.n, id, 'ERR notag ' + w[1]); return; }
					buf = fs.readFileSync(f);
					var intFrom = parseInt(w[2] || '0', 10), intN = w[3] ? parseInt(w[3], 10) : buf.length;
					buf = buf.slice(intFrom, intFrom + intN);
					ch.s.rsp(ch.n, id, 'OK ' + buf.length, buf);
				}
				else if (c === 'DEL')
				{
					f = file(ch, w[1] || '');
					if (!fs.existsSync(f)) { ch.s.rsp(ch.n, id, 'ERR notag ' + w[1]); return; }
					fs.unlinkSync(f);
					ch.s.rsp(ch.n, id, 'OK');
				}
				else if (c === 'SIZE')
				{
					f = file(ch, w[1] || '');
					if (!fs.existsSync(f)) { ch.s.rsp(ch.n, id, 'ERR notag ' + w[1]); return; }
					st = fs.statSync(f);
					ch.s.rsp(ch.n, id, 'OK ' + st.size + ' ' + when(st.mtime));
				}
				else if (c === 'LIST')
				{
					var arr = walk(path.join(cfg.STORE, ch.s.machine), '', []);
					if (w[1]) { arr = arr.filter(function(l) { return l.indexOf(w[1]) === 0; }); }
					ch.s.rsp(ch.n, id, 'OK ' + arr.length, Buffer.from(arr.join('\r\n'), 'latin1'));
				}
				else { ch.s.rsp(ch.n, id, 'ERR unknown ' + c); }
			}
		};
	});
};
