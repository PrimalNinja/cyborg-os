// nextrun.js - CyborgOS-Next in ZEsarUX: the card image booted, then commands typed one by one
// into slot 1 (Enter after each, a wait), a picture of the screen after each - for looking at
// what the Next shows (its font, LANG, a program's output), the way emu84 does for the CPC.
//
//   ZESARUX=path/to/zesarux node tools/regress/nextrun.js [--card=CARD.img] [--shots=DIR] [--wait=ms] "cmd;cmd;..."
//
// Exit code 1 when ZEsarUX or the card is missing. (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path'), cp = require('child_process'), os = require('os');
var Zrcp = require('./zrcp.js');

var COS = path.join(__dirname, '..', '..');
var strShots = '/tmp/nextrun', strImg = path.join(COS, 'build', 'next', 'cyborgos-next-sd.img'), intWait = 6000;
var arrArgs = process.argv.slice(2).filter(function(a_a)
{
	if (/^--shots=/.test(a_a)) { strShots = path.resolve(a_a.substr(8)); return false; }
	if (/^--card=/.test(a_a)) { strImg = path.resolve(a_a.substr(7)); return false; }
	if (/^--wait=/.test(a_a)) { intWait = parseInt(a_a.substr(7), 10); return false; }
	return true;
});
var ZES = process.env.ZESARUX;
if (!ZES || !fs.existsSync(ZES) || !fs.existsSync(strImg)) { console.log('ZESARUX=zesarux and the card image needed'); process.exit(1); }
var arrCmds = (arrArgs[0] || 'ps').split(';');
var K = { ENTER: 129 };
var sleep = function(ms_a) { return new Promise(function(r_a) { setTimeout(r_a, ms_a); }); };

(async function()
{
	var strTmp = fs.mkdtempSync(path.join(os.tmpdir(), 'nextrun'));
	fs.copyFileSync(strImg, path.join(strTmp, 'card.mmc'));
	cp.spawnSync('pkill', ['-x', 'zesarux']);
	await sleep(1000);
	var zes = cp.spawn(ZES, ['--noconfigfile', '--machine', 'tbblue', '--vo', 'null', '--ao', 'null', '--nowelcomemessage',
		'--enable-remoteprotocol', '--remoteprotocol-port', '10000', '--verbose', '1', '--realvideo', '--enable-mmc',
		'--enable-divmmc-ports', '--enable-divmmc-paging', '--mmc-file', path.join(strTmp, 'card.mmc'), '--mmc-no-persistent-writes'],
		{ cwd: path.dirname(ZES), stdio: 'ignore' });
	await sleep(4000);
	var z = new Zrcp(10000);
	await sleep(500);
	await sleep(30000); await z.cmd('send-keys-event 129 1'); await sleep(200); await z.cmd('send-keys-event 129 0');   // the video mode: Enter
	await sleep(12000); await z.cmd('send-keys-event 128 1'); await sleep(200); await z.cmd('send-keys-event 128 0');   // NextZXOS's menu: Space
	await sleep(25000);                                     // CyborgOS up (as nextkeys.js waits)
	fs.mkdirSync(strShots, { recursive: true });
	var intN = 0;
	await z.cmd('save-screen ' + path.join(strShots, 'boot.bmp')); await sleep(800);
	for (intN = 0; intN < arrCmds.length; intN++)
	{
		if (/^\^.$/.test(arrCmds[intN]))                        // ^0: Caps Shift + that key (TOP); ^2 on TOP: slot 2
		{
			await z.cmd('send-keys-event 135 1'); await sleep(100);
			await z.cmd('send-keys-event ' + arrCmds[intN].charCodeAt(1) + ' 1'); await sleep(300);
			await z.cmd('send-keys-event ' + arrCmds[intN].charCodeAt(1) + ' 0'); await sleep(100);
			await z.cmd('send-keys-event 135 0');
		}
		else if (/^[0-9a-z]$/.test(arrCmds[intN]) && intN > 0 && /^\^/.test(arrCmds[intN - 1]))   // a key on TOP
		{
			await z.cmd('send-keys-event ' + arrCmds[intN].charCodeAt(0) + ' 1'); await sleep(200); await z.cmd('send-keys-event ' + arrCmds[intN].charCodeAt(0) + ' 0');
		}
		else
		{
			await z.cmd('send-keys-string 150 ' + arrCmds[intN]); await sleep(300 + 160 * arrCmds[intN].length);
			await z.cmd('send-keys-event ' + K.ENTER + ' 1'); await sleep(200); await z.cmd('send-keys-event ' + K.ENTER + ' 0');
		}
		await sleep(intWait);
		await z.cmd('save-screen ' + path.join(strShots, 'cmd-' + (intN + 1) + '.bmp')); await sleep(800);
		console.log('typed: ' + arrCmds[intN]);
	}
	zes.kill();
	console.log('pictures: ' + strShots + '/boot.bmp, cmd-1..' + intN + '.bmp');
	process.exit(0);
})();
