// audio.js - AUDIO: sound played by the Pi (its 3.5 mm jack or HDMI), the CPC saying what. The
// sound is on the Pi already - a STORE tag sent once, or a file of the Pi's - so the link carries
// commands, not 3.5MB.
//   PLAY tag | /path/file     OK (mpg123 for .mp3, aplay for .wav - what the Pi has)
//   STOP                      OK                     STATUS     OK playing name | OK idle
//   VOL n                     OK (0-100: amixer's Master / PCM)
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var cp = require('child_process'), fs = require('fs'), path = require('path');

module.exports = function(service, cfg)
{
	service('audio', 'sound played on the Pi from a STORE tag or its own files (PLAY, STOP, VOL)', function(ch)
	{
		var objP = null, strNow = '';
		function stop() { if (objP) { try { objP.kill(); } catch (e) { /* gone */ } objP = null; strNow = ''; } }
		return {
			req: function(ch, id, text)
			{
				var w = text.trim().split(/\s+/), c = (w[0] || '').toUpperCase(), f;
				if (c === 'STOP') { stop(); ch.s.rsp(ch.n, id, 'OK'); }
				else if (c === 'STATUS') { ch.s.rsp(ch.n, id, objP ? 'OK playing ' + strNow : 'OK idle'); }
				else if (c === 'VOL')
				{
					var v = Math.max(0, Math.min(100, parseInt(w[1] || '50', 10)));
					cp.execFile('amixer', ['-q', 'sset', 'Master', v + '%'], function(e) { if (e) { cp.execFile('amixer', ['-q', 'sset', 'PCM', v + '%'], function() {}); } });
					ch.s.rsp(ch.n, id, 'OK');
				}
				else if (c === 'PLAY')
				{
					f = w[1] || '';
					if (f.charAt(0) !== '/') { if (!/^[A-Za-z0-9_.\/-]{1,64}$/.test(f) || f.indexOf('..') >= 0) { ch.s.rsp(ch.n, id, 'ERR bad tag'); return; } f = path.join(cfg.STORE, ch.s.machine, f); }
					if (!fs.existsSync(f)) { ch.s.rsp(ch.n, id, 'ERR nofile ' + w[1]); return; }
					stop();
					objP = cp.spawn(/\.mp3$/i.test(f) ? 'mpg123' : 'aplay', ['-q', f]);
					strNow = w[1];
					objP.on('error', function(e) { ch.s.evt(ch.n, 'ERR ' + e.message); objP = null; });
					objP.on('close', function() { if (strNow === w[1]) { objP = null; strNow = ''; ch.s.evt(ch.n, 'DONE ' + w[1]); } });
					ch.s.rsp(ch.n, id, 'OK');
				}
				else { ch.s.rsp(ch.n, id, 'ERR unknown ' + c); }
			},
			close: stop
		};
	});
};
