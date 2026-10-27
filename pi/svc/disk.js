// disk.js - DISK: Pi volumes as CyborgOS drives. A volume is a folder, /home/cyborgos/<volume>/
// (cosd --volumes=DIR for another); volumes.json there keeps them - mounted or not, the drive
// letter, read-only - so mounts last across boots. The files are the Pi's: real random access
// (any 128-byte record, any order - as CyborgOS's RAM discs, unlike AMSDOS), long files, folders.
// At the start (after HELLO) cosd announces the mounted volumes on the control channel - EVT
// MOUNTED name X, 4 at most: more are mounted by hand (MOUNT) while letters are free.
//   OPEN disk
//   VOLUMES                    OK n - a line each: name letter|- rw|ro files bytes
//   NEW name                   a volume made (1-8 letters / digits: a CP/M-like name)
//   DROP name YES              a volume and its files gone (YES: the CPC asked first)
//   MOUNT name X [ro]          mounted as drive X (A-P); UNMOUNT X | name
//   OPEN X:[path/]NAME.EXT [new|ro]   OK h records bytes (new: made or emptied)
//   READ h rec [n]             OK k + k records (n 1-8, 1 if not given; the last one padded with
//                              ^Z, CP/M's end of a text file; k 0: past the end)
//   WRITE h rec + data         OK - 128-byte records from rec (a part record: padded with ^Z)
//   SIZE h                     OK records bytes          CLOSE h      OK
//   FIND X:[path/]pattern      OK n - a line each: NAME.EXT bytes, or NAME <DIR> (? and *: CP/M's)
//   ERA X:[path/]pattern       OK n (files gone)          REN X:[path/]NEW X:[path/]OLD   OK
//   MKDIR X:path   RMDIR X:path (empty)   FREE X  OK kilobytes free
// Names on the CPC side are 8.3 in capitals; on the Pi, found whatever their case, made in
// capitals. A path can't leave its volume (no .., no absolute paths).
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path');

var REC = 128, MAXOPEN = 16, ANNOUNCE = 4;

module.exports = function(service, cfg)
{
	var ROOT = cfg.VOLUMES;

	function cfgFile() { return path.join(ROOT, 'volumes.json'); }
	function load()
	{
		try { return JSON.parse(fs.readFileSync(cfgFile(), 'utf8')); } catch (e) { return { volumes: {} }; }
	}
	function save(o) { fs.mkdirSync(ROOT, { recursive: true }); fs.writeFileSync(cfgFile() + '.tmp', JSON.stringify(o, null, '\t')); fs.renameSync(cfgFile() + '.tmp', cfgFile()); }
	function okName(n) { return /^[A-Za-z0-9]{1,8}$/.test(n); }
	function byLetter(o, x) { var k; for (k in o.volumes) { if (o.volumes[k].letter === x) { return k; } } return null; }
	// a host path from "X:path/NAME.EXT": each part found whatever its case; a new last part in capitals
	function resolve(strSpec_a, blnNew_a)
	{
		var m = String(strSpec_a || '').match(/^([A-Pa-p]):(.*)$/);
		if (!m) { throw new Error('a drive first (X:name)'); }
		var o = load(), v = byLetter(o, m[1].toUpperCase());
		if (!v) { throw new Error(m[1].toUpperCase() + ': is no Pi volume'); }
		var arrP = m[2].replace(/\\/g, '/').split('/').filter(function(p) { return p !== ''; });
		arrP.forEach(function(p) { if (p === '.' || p === '..' || /[\0]/.test(p)) { throw new Error('a path must stay in its volume'); } });
		var strDir = path.join(ROOT, v), i;
		for (i = 0; i < arrP.length; i++)
		{
			var strHit = null;
			try { strHit = fs.readdirSync(strDir).filter(function(f) { return f.toUpperCase() === arrP[i].toUpperCase(); })[0] || null; } catch (e) { /* not a folder */ }
			strDir = path.join(strDir, strHit || (blnNew_a || i < arrP.length - 1 ? arrP[i].toUpperCase() : arrP[i]));
		}
		return { file: strDir, vol: v, ro: !!o.volumes[v].ro, rel: arrP };
	}
	function wild(strPat_a)
	{
		// CP/M's ? (any one) and * (the rest of the name or the type), against 8.3 in capitals
		var p = strPat_a.toUpperCase(), d = p.indexOf('.'), n = d < 0 ? p : p.slice(0, d), t = d < 0 ? '*' : p.slice(d + 1);
		function part(s, len) { var i = s.indexOf('*'); if (i >= 0) { s = s.slice(0, i) + '?'.repeat(Math.max(0, len - i)); } return (s + ' '.repeat(len)).slice(0, len); }
		return { n: part(n, 8), t: part(t, 3) };
	}
	function match(w, strName_a)
	{
		var u = strName_a.toUpperCase(), d = u.lastIndexOf('.'), n = d < 0 ? u : u.slice(0, d), t = d < 0 ? '' : u.slice(d + 1), i;
		if (n.length === 0 || n.length > 8 || t.length > 3 || /[^A-Z0-9!#$%&'()\-@^_`{}~]/.test(n + t)) { return false; }	// (8.3 only: what a CP/M program can name)
		n = (n + '        ').slice(0, 8); t = (t + '   ').slice(0, 3);
		for (i = 0; i < 8; i++) { if (w.n[i] !== '?' && w.n[i] !== n[i]) { return false; } }
		for (i = 0; i < 3; i++) { if (w.t[i] !== '?' && w.t[i] !== t[i]) { return false; } }
		return true;
	}
	function dirOf(strSpec_a)
	{
		// "X:path/pattern" -> the folder and the pattern
		var m = String(strSpec_a).match(/^([A-Pa-p]:)(.*)$/);
		if (!m) { throw new Error('a drive first (X:name)'); }
		var i = m[2].lastIndexOf('/'), strPat = i < 0 ? m[2] : m[2].slice(i + 1), r = resolve(m[1] + (i < 0 ? '' : m[2].slice(0, i)), false);
		return { dir: r.file, pat: strPat || '*.*', ro: r.ro };
	}

	// the mounted volumes, told to the CPC after its HELLO (4 at most)
	module.exports.announce = function(s)
	{
		var o = load(), n = 0;
		Object.keys(o.volumes).sort().forEach(function(k)
		{
			var v = o.volumes[k];
			if (v.letter && n < ANNOUNCE) { s.evt(0, 'MOUNTED ' + k + ' ' + v.letter + (v.ro ? ' ro' : '')); n++; }
		});
	};

	service('disk', 'Pi volumes as CyborgOS drives: real random access (VOLUMES, MOUNT, OPEN, READ, WRITE ...)', function(ch)
	{
		var arrH = [];						// the open files: { fd, file, ro }
		function handle(h) { var o = arrH[+h]; if (!o) { throw new Error('no such handle ' + h); } return o; }
		function recs(n) { return Math.ceil(n / REC); }
		return {
			req: function(ch, id, text, body)
			{
				var w = text.trim().split(/\s+/), c = (w[0] || '').toUpperCase(), o, r, st, i, n, h;
				var ok = function(t, b) { ch.s.rsp(ch.n, id, 'OK' + (t !== undefined && t !== '' ? ' ' + t : ''), b); };
				try
				{
					if (c === 'VOLUMES')
					{
						o = load();
						var arrL = Object.keys(o.volumes).sort().map(function(k)
						{
							var v = o.volumes[k], intF = 0, intB = 0;
							(function walk(d) { try { fs.readdirSync(d).forEach(function(f) { var p = path.join(d, f), q = fs.statSync(p); if (q.isDirectory()) { walk(p); } else { intF++; intB += q.size; } }); } catch (e) { /* gone */ } })(path.join(ROOT, k));
							return k + ' ' + (v.letter || '-') + ' ' + (v.ro ? 'ro' : 'rw') + ' ' + intF + ' ' + intB;
						});
						ok(arrL.length, Buffer.from(arrL.join('\r\n'), 'latin1'));
					}
					else if (c === 'NEW')
					{
						if (!okName(w[1] || '')) { throw new Error('a name of 1-8 letters and digits'); }
						o = load(); n = w[1].toUpperCase();
						if (o.volumes[n]) { throw new Error(n + ' is there already'); }
						fs.mkdirSync(path.join(ROOT, n), { recursive: true });
						o.volumes[n] = { letter: null, ro: false };
						save(o); ok();
					}
					else if (c === 'DROP')
					{
						o = load(); n = (w[1] || '').toUpperCase();
						if (!o.volumes[n]) { throw new Error('no volume ' + n); }
						if ((w[2] || '').toUpperCase() !== 'YES') { throw new Error('DROP name YES - its files go'); }
						if (o.volumes[n].letter) { throw new Error(n + ' is mounted (' + o.volumes[n].letter + ':) - UNMOUNT it first'); }
						fs.rmSync(path.join(ROOT, n), { recursive: true, force: true });
						delete o.volumes[n];
						save(o); ok();
					}
					else if (c === 'MOUNT')
					{
						o = load(); n = (w[1] || '').toUpperCase();
						var x = (w[2] || '').toUpperCase().replace(':', '');
						if (!o.volumes[n]) { throw new Error('no volume ' + n); }
						if (!/^[A-P]$/.test(x)) { throw new Error('a drive letter A-P (what CP/M programs can reach)'); }
						var strOther = byLetter(o, x);
						if (strOther && strOther !== n) { throw new Error(x + ': is ' + strOther + '\'s'); }
						o.volumes[n].letter = x;
						o.volumes[n].ro = (w[3] || '').toLowerCase() === 'ro';
						save(o); ok(n + ' ' + x);
					}
					else if (c === 'UNMOUNT')
					{
						o = load(); n = (w[1] || '').toUpperCase().replace(':', '');
						var k = o.volumes[n] ? n : byLetter(o, n);
						if (!k || !o.volumes[k].letter) { throw new Error(n + ' is not mounted'); }
						o.volumes[k].letter = null;
						save(o); ok(k);
					}
					else if (c === 'OPEN')
					{
						var strMode = (w[2] || '').toLowerCase();
						r = resolve(w[1], strMode === 'new');
						if (strMode === 'new' && r.ro) { throw new Error('the volume is read-only'); }
						for (h = 0; h < MAXOPEN && arrH[h]; h++) { /* a free handle */ }
						if (h >= MAXOPEN) { throw new Error('too many files open'); }
						if (strMode === 'new') { fs.mkdirSync(path.dirname(r.file), { recursive: true }); fs.writeFileSync(r.file, Buffer.alloc(0)); }
						if (!fs.existsSync(r.file) || fs.statSync(r.file).isDirectory()) { throw new Error('no file ' + w[1]); }
						var blnRo = r.ro || strMode === 'ro';
						arrH[h] = { fd: fs.openSync(r.file, blnRo ? 'r' : 'r+'), file: r.file, ro: blnRo };
						st = fs.fstatSync(arrH[h].fd);
						ok(h + ' ' + recs(st.size) + ' ' + st.size);
					}
					else if (c === 'READ')
					{
						o = handle(w[1]); r = parseInt(w[2] || '0', 10); n = Math.max(1, Math.min(8, parseInt(w[3] || '1', 10)));
						var buf = Buffer.alloc(n * REC, 0x1A), got = fs.readSync(o.fd, buf, 0, n * REC, r * REC);
						var k2 = recs(got);
						ok(k2, buf.slice(0, k2 * REC));
					}
					else if (c === 'WRITE')
					{
						o = handle(w[1]); r = parseInt(w[2] || '0', 10);
						if (o.ro) { throw new Error('read-only'); }
						var b2 = body || Buffer.alloc(0);
						if (b2.length % REC) { b2 = Buffer.concat([b2, Buffer.alloc(REC - b2.length % REC, 0x1A)]); }
						fs.writeSync(o.fd, b2, 0, b2.length, r * REC);
						ok(recs(b2.length));
					}
					else if (c === 'SIZE') { o = handle(w[1]); st = fs.fstatSync(o.fd); ok(recs(st.size) + ' ' + st.size); }
					else if (c === 'CLOSE') { o = handle(w[1]); fs.closeSync(o.fd); arrH[+w[1]] = null; ok(); }
					else if (c === 'FIND')
					{
						var d = dirOf(w[1] || ''), wp = wild(d.pat), arr = [];
						fs.readdirSync(d.dir).sort().forEach(function(f)
						{
							var q = fs.statSync(path.join(d.dir, f));
							if (q.isDirectory()) { if (match(wp, f) || d.pat === '*.*') { arr.push(f.toUpperCase() + ' <DIR>'); } }
							else if (match(wp, f)) { arr.push(f.toUpperCase() + ' ' + q.size); }
						});
						ok(arr.length, Buffer.from(arr.join('\r\n'), 'latin1'));
					}
					else if (c === 'ERA')
					{
						var d2 = dirOf(w[1] || ''), wp2 = wild(d2.pat);
						if (d2.ro) { throw new Error('the volume is read-only'); }
						n = 0;
						fs.readdirSync(d2.dir).forEach(function(f) { var p = path.join(d2.dir, f); if (!fs.statSync(p).isDirectory() && match(wp2, f)) { fs.unlinkSync(p); n++; } });
						ok(n);
					}
					else if (c === 'REN')
					{
						var rN = resolve(w[1], true), rO = resolve(w[2], false);
						if (rN.ro) { throw new Error('the volume is read-only'); }
						if (!fs.existsSync(rO.file)) { throw new Error('no file ' + w[2]); }
						if (fs.existsSync(rN.file)) { throw new Error(w[1] + ' is there already'); }
						fs.renameSync(rO.file, rN.file); ok();
					}
					else if (c === 'MKDIR') { r = resolve(w[1], true); if (r.ro) { throw new Error('the volume is read-only'); } fs.mkdirSync(r.file, { recursive: true }); ok(); }
					else if (c === 'RMDIR') { r = resolve(w[1], false); if (r.ro) { throw new Error('the volume is read-only'); } fs.rmdirSync(r.file); ok(); }
					else if (c === 'FREE')
					{
						r = resolve((w[1] || '').replace(/:?$/, ':'), false);
						var intK = 0;
						try { var sf = fs.statfsSync(r.file); intK = Math.floor(sf.bavail * sf.bsize / 1024); } catch (e) { intK = 0; }
						ok(intK);
					}
					else { ch.s.rsp(ch.n, id, 'ERR unknown ' + c); }
				}
				catch (e) { ch.s.rsp(ch.n, id, 'ERR ' + e.message); }
			},
			close: function() { arrH.forEach(function(o) { if (o) { try { fs.closeSync(o.fd); } catch (e) { /* gone */ } } }); arrH = []; }
		};
	});
};
