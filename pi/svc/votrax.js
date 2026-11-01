// votrax.js - VOTRAX: the SC-01 speech chip emulated on the Pi (cyborg-os/3p/votrax, MAME's votrax.cpp,
// BSD-3-Clause). The chip's own 512-byte internal ROM is not ours to ship: it is looked for in
// the machine's store as SYS/SC01A.BIN; without it the service opens, says "norom" and plays
// nothing. DATA frames carry phoneme bytes (bits 0-5 the phone, 6-7 the inflection); the audio
// goes to aplay (40000 Hz, S16_LE, mono) when the Pi has it, else nowhere.
//   REQ: STATUS -> OK ready | OK norom | OK off (no program built) ; STOP -> OK (the chip restarted)
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var cp = require('child_process'), fs = require('fs'), path = require('path');

module.exports = function(service, cfg)
{
	var strProg = path.join(__dirname, '..', '..', '3p', 'votrax', 'votrax');	// 3p/ sits beside pi/
	var blnAplay = false;
	try { cp.execFileSync('which', ['aplay'], { stdio: 'ignore' }); blnAplay = true; } catch (e) { blnAplay = false; }

	service('votrax', 'the SC-01 (Votrax) speech chip emulated on the Pi: phoneme bytes as DATA (needs SYS/SC01A.BIN in the store)', function(ch)
	{
		var objChip = null, objPlay = null, strState = 'off';
		var strRom = path.join(cfg.STORE, ch.s.machine, 'SYS', 'SC01A.BIN');
		function stop()
		{
			if (objChip) { try { objChip.stdin.end(); objChip.kill(); } catch (e) { /* gone */ } objChip = null; }
			if (objPlay) { try { objPlay.kill(); } catch (e) { /* gone */ } objPlay = null; }
		}
		function start()
		{
			stop();
			if (!fs.existsSync(strProg)) { strState = 'off'; return; }
			if (!fs.existsSync(strRom)) { strState = 'norom'; return; }
			objChip = cp.spawn(strProg, [strRom], { stdio: ['pipe', 'pipe', 'ignore'] });
			objChip.on('exit', function() { objChip = null; });
			if (blnAplay)
			{
				objPlay = cp.spawn('aplay', ['-q', '-f', 'S16_LE', '-r', '40000', '-c', '1'], { stdio: ['pipe', 'ignore', 'ignore'] });
				objChip.stdout.pipe(objPlay.stdin);
			}
			else { objChip.stdout.on('data', function() { /* no sound device here: the samples dropped */ }); }
			strState = 'ready';
		}
		start();
		return {
			req: function(ch_a, intId_a, strText_a)
			{
				var cmd = strText_a.trim().split(/\s+/)[0].toUpperCase();
				if (cmd === 'STATUS') { ch_a.s.rsp(ch_a.n, intId_a, 'OK ' + strState); }
				else if (cmd === 'STOP') { start(); ch_a.s.rsp(ch_a.n, intId_a, 'OK'); }
				else { ch_a.s.rsp(ch_a.n, intId_a, 'ERR noreq ' + cmd); }
			},
			data: function(ch_a, buf_a) { if (objChip) { objChip.stdin.write(buf_a); } },
			close: function() { stop(); }
		};
	});
};
