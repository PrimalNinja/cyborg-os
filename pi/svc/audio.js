// audio.js - AUDIO: music played by the Pi (its 3.5 mm jack or HDMI), the CPC saying what. The
// files are on the Pi already - STORE tags sent once, or the Pi's own - so the link carries
// commands, not megabytes. MP3 through mpg123's remote-control mode (mpg123 -R: pause, seek,
// position), .wav through aplay (play and stop only).
//   PLAY tag [seconds]        play it (from seconds in): OK          STOP            OK
//                             a tag under MUSIC/<type>/ (MP3, 8BIT, 4BIT, SID, AY38912: Streamer's folders) plays
//                             by its type - MP3 through mpg123, 8BIT (8-bit unsigned samples at 12324 Hz: NTC's
//                             Stream.cls .MUS) raw through aplay, SID through sidplayfp (a C64 tune, from any machine), 4BIT and
//                             AY38912 to come (ERR notyet) -
//                             SID (sidplayfp), VGM (vgmplay), FM (adplay), MOD (xmp), MIDI (fluidsynth with a
//                             soundfont: GM / GS / XG files, XG rendered as GM), GME and AY38912 (mpv's gme) -
//                             each a process; a missing one answers ERR noplayer <name>. Else by extension
//   PAUSE                     OK (paused; PAUSE again or RESUME goes on)   RESUME     OK
//   SKIP n                    n seconds forward (n negative: back): OK
//   SEEK seconds              to that point: OK
//   LIST tag tag ...          a playlist (then PLAY with no tag starts it; NEXT / PREV move):
//                             OK n
//   NEXT | PREV               the next / previous of the list: OK tag, or ERR nolist
//   STATUS                    OK playing tag seconds | OK paused tag seconds | OK idle
//   VOL n                     OK (0-100: amixer's Master / PCM)
//   EVT: ENDED tag (a track finished; the list moves on by itself), POS seconds (each second
//   while playing, when the channel was opened with pos=1)
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var cp = require('child_process'), fs = require('fs'), path = require('path');

module.exports = function(service, cfg)
{
	var strMpg = cfg.MPG123 || 'mpg123';

	service('audio', 'music played on the Pi from a STORE tag or its own files (PLAY, PAUSE, SKIP, SEEK, LIST, NEXT, PREV, STOP, VOL)', function(ch, args)
	{
		var objP = null;			// the player process (mpg123 -R kept up, or an aplay)
		var blnRemote = false;		// objP is mpg123 -R
		var strNow = '';			// the tag playing
		var blnPaused = false;
		var intPos = 0;				// seconds into the track (from mpg123's @F lines)
		var arrList = [], intIdx = -1;
		var blnPosEvt = /pos=1/i.test(String(args || ''));
		var intLastPos = -1, strPart = '';

		function file(strTag_a)
		{
			var f = strTag_a;
			if (f.charAt(0) !== '/')
			{
				if (!/^[A-Za-z0-9_.\/-]{1,64}$/.test(f) || f.indexOf('..') >= 0) { return null; }
				f = path.join(cfg.STORE, ch.s.machine, f);
			}
			return fs.existsSync(f) ? f : null;
		}
		function stop()
		{
			if (objP) { try { objP.kill(); } catch (e) { /* gone */ } }
			objP = null; blnRemote = false; strNow = ''; blnPaused = false; intPos = 0;
		}
		function ended(strTag_a)
		{
			ch.s.evt(ch.n, 'ENDED ' + strTag_a);
			strNow = ''; blnPaused = false; intPos = 0;
			if (arrList.length && intIdx + 1 < arrList.length) { intIdx++; play(arrList[intIdx], 0); }
		}
		function remoteLine(strLine_a)
		{
			var m = strLine_a.match(/^@F \d+ \d+ ([\d.]+) [\d.]+/);
			if (m)
			{
				intPos = Math.floor(parseFloat(m[1]));
				if (blnPosEvt && intPos !== intLastPos) { intLastPos = intPos; ch.s.evt(ch.n, 'POS ' + intPos); }
			}
			else if (/^@P 0/.test(strLine_a) && strNow) { ended(strNow); }
			else if (/^@P 1/.test(strLine_a)) { blnPaused = true; }
			else if (/^@P 2/.test(strLine_a)) { blnPaused = false; }
			else if (/^@E/.test(strLine_a)) { ch.s.evt(ch.n, 'ERR ' + strLine_a.slice(3)); }
		}
		function remote()
		{
			if (objP && blnRemote) { return true; }
			stop();
			var p = null;
			try { p = cp.spawn(strMpg, ['-R', '-q'], { stdio: ['pipe', 'pipe', 'ignore'] }); }
			catch (e) { p = null; }
			if (!p) { return false; }
			objP = p; blnRemote = true;
			p.on('error', function(e) { ch.s.evt(ch.n, 'ERR ' + e.message); objP = null; blnRemote = false; });
			p.on('close', function() { if (objP === p) { objP = null; blnRemote = false; } });
			p.stdout.on('data', function(b)
			{
				var arr = (strPart + b.toString('latin1')).split(/\r?\n/);
				strPart = arr.pop();
				arr.forEach(remoteLine);
			});
			return true;
		}
		// a file's kind: by its MUSIC/<type>/ folder when it is installed there, else by its extension
		function kind(strTag_a, strFile_a)
		{
			var m = String(strTag_a).match(/^MUSIC\/(MP3|8BIT|4BIT|SID|AY38912|VGM|FM|MOD|MIDI|GME)\//i), strK = 'wav';
			if (m) { strK = m[1].toLowerCase(); }
			else if (/\.mp3$/i.test(strFile_a)) { strK = 'mp3'; }
			else if (/\.mus$/i.test(strFile_a)) { strK = '8bit'; }
			else if (/\.sid$/i.test(strFile_a)) { strK = 'sid'; }
			else if (/\.vg[mz]$/i.test(strFile_a)) { strK = 'vgm'; }
			else if (/\.(imf|dro|rad|d00)$/i.test(strFile_a)) { strK = 'fm'; }
			else if (/\.(mod|xm|s3m|it)$/i.test(strFile_a)) { strK = 'mod'; }
			else if (/\.midi?$/i.test(strFile_a)) { strK = 'midi'; }
			else if (/\.(ay|nsf|gbs|spc|hes|kss|sap)$/i.test(strFile_a)) { strK = 'gme'; }
			return strK;
		}
		// the players by kind: a process each (invoked, not linked), the binary and its arguments; the
		// binary's name can be changed with cosd's --player-<kind>= ; a missing player: ERR noplayer <name>
		var PLAYERS = {
			sid: [cfg.PLAYER_SID || 'sidplayfp', ['-q']],
			vgm: [cfg.PLAYER_VGM || 'vgmplay', []],
			fm: [cfg.PLAYER_FM || 'adplay', ['-q']],
			mod: [cfg.PLAYER_MOD || 'xmp', ['-q']],
			midi: [cfg.PLAYER_MIDI || 'fluidsynth', ['-a', 'alsa', '-i', '-q', cfg.SOUNDFONT || '/usr/share/sounds/sf2/FluidR3_GM.sf2']],
			gme: [cfg.PLAYER_GME || 'mpv', ['--no-video', '--really-quiet']],
			ay38912: [cfg.PLAYER_GME || 'mpv', ['--no-video', '--really-quiet']]
		};
		function hasPlayer(strBin_a) { var blnOk = true; try { cp.execFileSync('which', [strBin_a], { stdio: 'ignore' }); } catch (e) { blnOk = fs.existsSync(strBin_a); } return blnOk; }
		function play(strTag_a, intFrom_a)
		{
			var f = file(strTag_a), strK = '';
			if (!f) { return 'ERR nofile ' + strTag_a; }
			strK = kind(strTag_a, f);
			if (strK === 'sid')
			{
				// a C64 SID file: sidplayfp (reSID; GPL, a process - apt install sidplayfp) - even from a CPC
				stop();
				var pS = null;
				try { pS = cp.spawn(cfg.SIDPLAY || 'sidplayfp', ['-q', f], { stdio: ['ignore', 'ignore', 'ignore'] }); } catch (e) { pS = null; }
				if (!pS) { return 'ERR nosidplay'; }
				objP = pS; blnRemote = false; strNow = strTag_a;
				pS.on('error', function(e) { ch.s.evt(ch.n, 'ERR ' + e.message); objP = null; strNow = ''; });
				pS.on('close', function() { if (objP === pS) { objP = null; ended(strTag_a); } });
				return 'OK';
			}
			if (strK === '4bit' || strK === 'ay38912') { return 'ERR notyet ' + strK; }
			if (strK === 'mp3')
			{
				if (!remote()) { return 'ERR nompg123'; }
				objP.stdin.write('LOAD ' + f + '\n');
				strNow = strTag_a; blnPaused = false; intPos = 0; intLastPos = -1;
				if (intFrom_a > 0) { objP.stdin.write('JUMP ' + intFrom_a + 's\n'); }
			}
			else
			{
				stop();
				var p = cp.spawn(cfg.APLAY || 'aplay', (strK === '8bit') ? ['-q', '-t', 'raw', '-f', 'U8', '-r', '12324', '-c', '1', f] : ['-q', f]);
				objP = p; blnRemote = false; strNow = strTag_a;
				p.on('error', function(e) { ch.s.evt(ch.n, 'ERR ' + e.message); objP = null; });
				p.on('close', function() { if (objP === p) { objP = null; ended(strTag_a); } });
			}
			return 'OK';
		}
		return {
			req: function(ch_a, intId_a, strText_a)
			{
				var w = strText_a.trim().split(/\s+/), c = (w[0] || '').toUpperCase(), strR = 'OK', intN = 0;
				if (c === 'STOP') { stop(); }
				else if (c === 'STATUS') { strR = strNow ? ('OK ' + (blnPaused ? 'paused ' : 'playing ') + strNow + ' ' + intPos) : 'OK idle'; }
				else if (c === 'VOL')
				{
					var v = Math.max(0, Math.min(100, parseInt(w[1] || '50', 10)));
					cp.execFile('amixer', ['-q', 'sset', 'Master', v + '%'], function(e) { if (e) { cp.execFile('amixer', ['-q', 'sset', 'PCM', v + '%'], function() {}); } });
				}
				else if (c === 'PLAY')
				{
					if (w[1]) { strR = play(w[1], parseInt(w[2] || '0', 10)); }
					else if (arrList.length) { intIdx = intIdx < 0 ? 0 : intIdx; strR = play(arrList[intIdx], 0); }
					else { strR = 'ERR nolist'; }
				}
				else if (c === 'PAUSE' || c === 'RESUME')
				{
					if (!strNow || !blnRemote) { strR = 'ERR notplaying'; }
					else if (c === 'RESUME' && !blnPaused) { strR = 'OK'; }
					else { objP.stdin.write('PAUSE\n'); blnPaused = (c === 'PAUSE') ? !blnPaused : false; }
				}
				else if (c === 'SKIP' || c === 'SEEK')
				{
					if (!strNow || !blnRemote) { strR = 'ERR notplaying'; }
					else
					{
						intN = parseInt(w[1] || '0', 10);
						objP.stdin.write('JUMP ' + (c === 'SKIP' ? ((intN >= 0 ? '+' : '-') + Math.abs(intN)) : Math.max(0, intN)) + 's\n');
						intPos = c === 'SKIP' ? Math.max(0, intPos + intN) : Math.max(0, intN);
					}
				}
				else if (c === 'LIST') { arrList = w.slice(1); intIdx = -1; strR = 'OK ' + arrList.length; }
				else if (c === 'NEXT' || c === 'PREV')
				{
					if (!arrList.length) { strR = 'ERR nolist'; }
					else
					{
						intIdx = c === 'NEXT' ? Math.min(arrList.length - 1, intIdx + 1) : Math.max(0, intIdx - 1);
						strR = play(arrList[intIdx], 0);
						if (strR === 'OK') { strR = 'OK ' + arrList[intIdx]; }
					}
				}
				else { strR = 'ERR unknown ' + c; }
				ch_a.s.rsp(ch_a.n, intId_a, strR);
			},
			close: stop
		};
	});
};
