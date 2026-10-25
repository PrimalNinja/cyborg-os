// nettest.js - CyborgOS-Next's network in ZEsarUX: espsim.py (a stand-in ESP8266 on a
// pseudo-terminal, real sockets behind it) bridged to the emulated Next's UART, the test web
// server (tools/regress/cosweb.js) on this machine, the card image booted into CyborgOS, then
// NET ESP, IPCONFIG, NETSTAT, NET SET, NET GET (a page, a redirect), NET TEST, the failures,
// NET OFF and YING typed. Checked: what the web server was asked for and the AT commands the
// ESP got. Pictures of the screen after each group (--shots=DIR) to look at.
//
//   ZESARUX=path/to/zesarux node tools/espsim/nettest.js [CARD.img] [--shots=DIR]
//
// CARD.img: default build/next/cyborgos-next-sd.img (a copy is used). ZEsarUX built with
// --uartbridge-path support and its remote protocol (port 10000); python3 for espsim.py.
// The Next's console is a Layer 2 bitmap, so the screens are pictures, not text.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path'), cp = require('child_process'), net = require('net'), os = require('os');

var COS = path.join(__dirname, '..', '..');
var arrArgs = process.argv.slice(2), strShots = '';
arrArgs = arrArgs.filter(function(a) { if (/^--shots=/.test(a)) { strShots = path.resolve(a.substr(8)); return false; } return true; });
var strImg = path.resolve(arrArgs[0] || path.join(COS, 'build', 'next', 'cyborgos-next-sd.img'));
var ZES = process.env.ZESARUX;
if (!ZES || !fs.existsSync(ZES)) { console.log('ZESARUX=path to the zesarux binary'); process.exit(2); }

var strTmp = fs.mkdtempSync(path.join(os.tmpdir(), 'nettest'));
var sleep = function(ms) { return new Promise(function(r) { setTimeout(r, ms); }); };

var Zrcp = require(path.join(COS, 'tools', 'regress', 'zrcp.js'));

(async function()
{
	var web = require(path.join(COS, 'tools', 'regress', 'cosweb.js')).start(function() {});
	await sleep(300);
	var U = 'http://127.0.0.1:' + web.port;
	fs.copyFileSync(strImg, path.join(strTmp, 'net.mmc'));
	var strEspLog = path.join(strTmp, 'esp.log');
	var esp = cp.spawn('python3', [path.join(__dirname, 'espsim.py')], { env: Object.assign({}, process.env, { ESPSIM_LOG: '1' }), stdio: ['ignore', 'pipe', fs.openSync(strEspLog, 'w')] });
	var strPty = await new Promise(function(r) { esp.stdout.once('data', function(d) { r(String(d).trim().split('\n')[0]); }); });
	cp.spawnSync('pkill', ['-x', 'zesarux']);
	await sleep(1000);
	var zes = cp.spawn(ZES, ['--noconfigfile', '--machine', 'tbblue', '--vo', 'null', '--ao', 'null', '--nowelcomemessage',
		'--enable-remoteprotocol', '--remoteprotocol-port', '10000', '--verbose', '1', '--realvideo', '--enable-mmc',
		'--enable-divmmc-ports', '--enable-divmmc-paging', '--mmc-file', path.join(strTmp, 'net.mmc'), '--mmc-no-persistent-writes',
		'--uartbridge-path', strPty], { cwd: path.dirname(ZES), stdio: 'ignore' });
	await sleep(4000);
	var z = new Zrcp(10000);
	await sleep(500);
	var key = async function(k) { await z.cmd('send-keys-event ' + k + ' 1'); await sleep(150); await z.cmd('send-keys-event ' + k + ' 0'); };
	var typ = async function(str_a, intWait_a) { await z.cmd('send-keys-string 150 ' + str_a); await sleep(250 * str_a.length + 500); await z.cmd('send-keys-ascii 150 13'); await sleep(intWait_a * 1000); };
	var intShot = 0;
	var shot = async function() { intShot++; if (strShots) { fs.mkdirSync(strShots, { recursive: true }); await z.cmd('save-screen ' + path.join(strShots, 'net-' + intShot + '.bmp')); await sleep(1000); } };

	await sleep(30000); await key(129); await sleep(12000); await key(32); await sleep(25000);	// NextZXOS's menu, then CyborgOS
	await typ('net', 6); await typ('net esp', 10); await typ('net', 6); await typ('ipconfig', 8); await shot();
	await typ('cls', 3); await typ('netstat', 6); await typ('net set TestNet,secret', 8); await typ('net get ' + U + '/echo?next=1&b=two', 25); await shot();
	await typ('cls', 3); await typ('net get ' + U + '/moved', 25); await typ('net test ' + U + '/big?n=3000 3', 60); await shot();
	await typ('cls', 3); await typ('net get 127.0.0.1:1/x', 20); await typ('net get nosuchhost.invalid/x', 20); await typ('net off', 8); await typ('net', 6); await typ('ipconfig', 6); await shot();
	await typ('net esp', 10); await typ('ying ' + U + '/echo?from=ying', 40); await shot();
	zes.kill(); esp.kill(); web.close();

	var strAt = fs.readFileSync(strEspLog, 'latin1');
	var arrWant = ['/echo?next=1&b=two', '/moved', '/echo?moved=1', '/big?n=3000', '/echo?from=ying&8bml=7'];
	var intFail = 0;
	arrWant.forEach(function(s) { var ok = web.requests.indexOf(s) >= 0; if (!ok) { intFail++; } console.log((ok ? 'ok   ' : 'FAIL ') + 'asked for ' + s); });
	var intBig = web.requests.filter(function(s) { return s === '/big?n=3000'; }).length;
	console.log((intBig === 3 ? 'ok   ' : 'FAIL ') + 'NET TEST: ' + intBig + ' GETs (3)'); if (intBig !== 3) { intFail++; }
	[['AT+CIPRECVMODE=1', 'passive receive'], ['AT+CWJAP_DEF="TestNet","secret"', 'NET SET joins'], ['AT+CIPDOMAIN="nosuchhost.invalid"', 'a name looked up'], ['AT+CIPSTART=0,"TCP","127.0.0.1",1', 'a refused connect']].forEach(function(a)
	{
		var ok = strAt.indexOf(a[0]) >= 0;
		if (!ok) { intFail++; }
		console.log((ok ? 'ok   ' : 'FAIL ') + a[1] + ' (' + a[0] + ')');
	});
	if (strShots) { console.log('pictures: ' + strShots + '/net-1..' + intShot + '.bmp'); }
	console.log(intFail ? intFail + ' failed' : 'ALL PASS');
	process.exit(intFail ? 1 : 0);
})();
