// term.js - TERM: a shell on the Pi on a pseudo terminal the CPC's size - the CPC (or the Next) a
// terminal of the Pi, as a dumb terminal or a VT52, in a slot while the other channels go on.
//   OPEN term [cols=80] [rows=24] [type=dumb|vt52|vt100] [cmd=...]
//   DATA both ways: the keys to the shell, its output back (CR LF line ends - the pty's)
//   EVT EXIT n when the shell ends; then the channel closes
// The pty is util-linux's script (no npm package): script -qfec "stty cols c rows r; exec shell".
// Refused when cosd runs with --no-run.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var cp = require('child_process');

module.exports = function(service, cfg)
{
	function kv(s, k, d) { var m = String(s).match(new RegExp('(?:^|\\s)' + k + '=(\\S+)', 'i')); return m ? m[1] : d; }
	service('term', 'a shell on the Pi, the CPC its terminal (OPEN term cols=80 rows=24 type=vt52)', function(ch, args)
	{
		if (!cfg.ALLOWRUN) { throw new Error('TERM is off on this Pi (cosd --no-run)'); }
		var intC = parseInt(kv(args, 'cols', ch.s.cols || 80), 10), intR = parseInt(kv(args, 'rows', ch.s.rows || 24), 10);
		var strType = kv(args, 'type', 'dumb'), strCmd = kv(args, 'cmd', '');
		var strSh = strCmd ? strCmd.replace(/\+/g, ' ') : 'exec ${SHELL:-/bin/bash} -i';
		var objP = cp.spawn('script', ['-qfec', 'stty cols ' + intC + ' rows ' + intR + ' 2>/dev/null; ' + strSh, '/dev/null'],
			{ env: Object.assign({}, process.env, { TERM: strType, COLUMNS: String(intC), LINES: String(intR) }) });
		objP.stdout.on('data', function(b) { ch.s.data(ch.n, b); });
		objP.stderr.on('data', function(b) { ch.s.data(ch.n, b); });
		objP.on('close', function(code) { ch.s.evt(ch.n, 'EXIT ' + code); ch.s.close(ch.n, 'exit'); });
		objP.on('error', function(e) { ch.s.evt(ch.n, 'ERR ' + e.message); ch.s.close(ch.n, 'error'); });
		return {
			data: function(ch, b) { objP.stdin.write(b); },
			close: function() { try { objP.kill(); } catch (e) { /* gone */ } }
		};
	});
};
