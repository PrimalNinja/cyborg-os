// run.js - RUN: a command run on the Pi, its output back (you type ls, the directory comes back).
//   RUN command line    its output as it comes (RSP + MORE parts), then OK exit=n (killed: exit=-1)
//   STOP                the command running stopped
// One command at a time on a channel; 60 seconds at most (OPEN run secs=n: another limit).
// Refused when cosd runs with --no-run.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var cp = require('child_process');

module.exports = function(service, cfg)
{
	service('run', 'a command run on the Pi, its output back (RUN ls -l)', function(ch, args)
	{
		if (!cfg.ALLOWRUN) { throw new Error('RUN is off on this Pi (cosd --no-run)'); }
		var objP = null, intSecs = parseInt((String(args).match(/secs=(\d+)/) || [])[1] || '60', 10);
		return {
			req: function(ch, id, text)
			{
				var w = text.trim(), c = w.split(/\s+/)[0].toUpperCase();
				if (c === 'STOP') { if (objP) { objP.kill(); } ch.s.rsp(ch.n, id, 'OK'); return; }
				if (c !== 'RUN') { ch.s.rsp(ch.n, id, 'ERR unknown ' + c); return; }
				if (objP) { ch.s.rsp(ch.n, id, 'ERR busy'); return; }
				objP = cp.spawn('/bin/sh', ['-c', w.slice(3).trim()], { env: Object.assign({}, process.env, { TERM: 'dumb', COLUMNS: String(ch.s.cols || 80), LINES: String(ch.s.rows || 24) }) });
				var tmr = setTimeout(function() { if (objP) { objP.kill('SIGKILL'); } }, intSecs * 1000);
				function out(b) { ch.s.parts(ch.n, 3, id, 'OUT', Buffer.from(b.toString('latin1').replace(/\r?\n/g, '\r\n'), 'latin1'), true); }
				objP.stdout.on('data', out);
				objP.stderr.on('data', out);
				objP.on('close', function(code) { clearTimeout(tmr); objP = null; ch.s.rsp(ch.n, id, 'OK exit=' + (code === null ? -1 : code)); });
			},
			close: function() { if (objP) { objP.kill(); } }
		};
	});
};
