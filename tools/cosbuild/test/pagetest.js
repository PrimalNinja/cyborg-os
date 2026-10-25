// pagetest.js - the builder page (src/cosbuild.html) driven as a user drives it in Chrome, start
// to end: Open the CyborgOS folder (File System Access - here a stand-in backed by the real
// folder), Run, the stage scripts run (sh build/stage/NAME.sh, as the user would), Run again ...
// until it says done. Pictures of the start screen, the end and the Design tab.
//
//   node tools/cosbuild/test/pagetest.js [COS_ROOT] [--shots=DIR]
//
// Needs Playwright (require('playwright') with its Chromium) and sjasmplus for the stage scripts.
// It writes to the folder as the page would: build/stage and build/. Exit code 1 on a page
// error or when the run doesn't reach "done".
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path'), cp = require('child_process');
var chromium = require('playwright').chromium;

var arrArgs = process.argv.slice(2);
var strShots = '';
arrArgs = arrArgs.filter(function(a) { if (/^--shots=/.test(a)) { strShots = path.resolve(a.substr(8)); return false; } return true; });
var ROOT = path.resolve(arrArgs[0] || path.join(__dirname, '..', '..', '..'));

(async function()
{
	var b = await chromium.launch();
	var p = await b.newPage({ viewport: { width: 1600, height: 950 } });
	var intErr = 0;
	var shot = async function(n) { if (strShots) { fs.mkdirSync(strShots, { recursive: true }); await p.screenshot({ path: path.join(strShots, n + '.png') }); } };

	p.on('pageerror', function(e) { intErr++; console.log('PAGE ERROR ' + e.message); });
	p.on('console', function(m) { if (m.type() === 'error') { intErr++; console.log('CONSOLE ERROR ' + m.text()); } });
	// the folder, for the page's stand-in handles
	await p.exposeFunction('fsKind', function(rel) { var f = path.join(ROOT, rel); return fs.existsSync(f) ? (fs.statSync(f).isDirectory() ? 'directory' : 'file') : ''; });
	await p.exposeFunction('fsList', function(rel) { return fs.readdirSync(path.join(ROOT, rel)).map(function(n) { return [n, fs.statSync(path.join(ROOT, rel, n)).isDirectory() ? 'directory' : 'file']; }); });
	await p.exposeFunction('fsRead', function(rel) { return fs.readFileSync(path.join(ROOT, rel)).toString('base64'); });
	await p.exposeFunction('fsMkdir', function(rel) { fs.mkdirSync(path.join(ROOT, rel), { recursive: true }); });
	await p.exposeFunction('fsWrite', function(rel, b64) { fs.mkdirSync(path.dirname(path.join(ROOT, rel)), { recursive: true }); fs.writeFileSync(path.join(ROOT, rel), Buffer.from(b64, 'base64')); });
	// showDirectoryPicker: directory and file handles as Chrome's, over the functions above
	await p.addInitScript(function()
	{
		function b64(u8) { var s = ''; for (var i = 0; i < u8.length; i += 8192) { s += String.fromCharCode.apply(null, u8.subarray(i, i + 8192)); } return btoa(s); }
		function unb64(s) { var t = atob(s); var u = new Uint8Array(t.length); for (var i = 0; i < t.length; i++) { u[i] = t.charCodeAt(i); } return u; }
		function file(rel, name)
		{
			return { kind: 'file', name: name,
				getFile: async function() { return new File([unb64(await window.fsRead(rel))], name); },
				createWritable: async function()
				{
					var parts = [];
					return { write: async function(d) { parts.push(d instanceof Uint8Array ? d : new Uint8Array(d)); },
						close: async function() { var n = 0; parts.forEach(function(x) { n += x.length; }); var u = new Uint8Array(n), o = 0; parts.forEach(function(x) { u.set(x, o); o += x.length; }); await window.fsWrite(rel, b64(u)); } };
				} };
		}
		function dir(rel, name)
		{
			var j = function(n) { return rel ? rel + '/' + n : n; };
			return { kind: 'directory', name: name,
				requestPermission: async function() { return 'granted'; }, queryPermission: async function() { return 'granted'; },
				getDirectoryHandle: async function(n, o) { if (await window.fsKind(j(n)) !== 'directory') { if (o && o.create) { await window.fsMkdir(j(n)); } else { throw new DOMException('no', 'NotFoundError'); } } return dir(j(n), n); },
				getFileHandle: async function(n, o) { if (await window.fsKind(j(n)) !== 'file' && !(o && o.create)) { throw new DOMException('no', 'NotFoundError'); } return file(j(n), n); },
				values: function() { var list = null, i = 0; return { next: async function() { if (!list) { list = await window.fsList(rel); } if (i >= list.length) { return { done: true }; } var e = list[i++]; return { done: false, value: (e[1] === 'directory') ? dir(j(e[0]), e[0]) : file(j(e[0]), e[0]) }; } }; } };
		}
		window.showDirectoryPicker = async function() { return dir('', 'cyborgos'); };
	});

	await p.goto('file://' + path.join(ROOT, 'tools', 'cosbuild', 'src', 'cosbuild.html'));
	await p.waitForTimeout(1000);
	console.log('start screen shown: ' + await p.isVisible('#cos-start'));
	await shot('start');
	await p.click('#cos-start .cos-open-folder');
	await p.waitForFunction(function() { return /parts/.test(document.querySelector('#cos-projectinfo').textContent); }, null, { timeout: 120000 });
	console.log('opened: ' + await p.textContent('#cos-folder') + ' - ' + await p.textContent('#cos-projectinfo'));
	var strInfo = '';
	for (var k = 0; k < 8; k++)
	{
		await p.click('#cos-run');
		await p.waitForFunction(function() { return !document.querySelector('#cos-run').disabled && document.querySelector('#cos-runinfo').textContent.length > 0; }, null, { timeout: 600000 });
		strInfo = await p.textContent('#cos-runinfo');
		console.log('run ' + (k + 1) + ': ' + strInfo);
		var m = strInfo.match(/run (\S+)\.bat/);
		if (!m) { break; }
		var r = cp.spawnSync('sh', [path.join(ROOT, 'build', 'stage', m[1] + '.sh')], { encoding: 'latin1' });
		console.log('  sh ' + m[1] + '.sh: ' + (r.stdout + r.stderr).trim().split('\n').slice(-1)[0]);
	}
	await shot('done');
	await p.click('.cos-tab[data-page="design"]');
	await p.waitForTimeout(1200);
	await shot('design');
	await b.close();
	var blnOk = /^done/.test(strInfo) && intErr === 0;
	console.log(blnOk ? 'PASS' : 'FAIL');
	process.exit(blnOk ? 0 : 1);
})();
