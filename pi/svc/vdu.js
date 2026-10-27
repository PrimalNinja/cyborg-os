// vdu.js - VDU: the Pi's HDMI as the CPC's (or the Next's) virtual display, full HD. A web page
// (http://pi:8084/) in a full screen browser on the Pi draws what the channels send; any other
// browser on the LAN can watch too.
//   OPEN vdu [mode=cpc|hd] [title=...]
//   DATA: lines (CR or LF between them), each a display command:
//     mode=cpc  RVDU's commands, word form or the 8BML dialect (tools/vdu/README.md): MODE, PRINT,
//               LOCATE, PEN, INK, WINDOW, DRAW, BOX ... on a CPC's 640 x 400, drawn by
//               tools/vdu/vdu.js and scaled up to the screen
//     mode=hd   1920 x 1080 itself: CLS [r g b] - COLOR r g b - FONT px [mono|sans|serif] - TEXT x y
//               text - RECT x y w h - FILL x y w h - LINE x1 y1 x2 y2 [w] - CIRCLE x y r [fill] -
//               IMG tag x y [w h] (a STORE tag: PNG / JPEG / GIF - sent once, shown any time) -
//               TITLE text (0, 0 the top left)
//   EVT back: TOUCH x y (a click or tap on the page, in the mode's coordinates), KEY n (a key)
// The page: every open display, side by side (one: the whole screen). Served by cosd itself.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var http = require('http'), fs = require('fs'), path = require('path');

module.exports = function(service, cfg)
{
	var arrViewers = [], objDisp = {}, intNext = 1, srv = null;
	var WEB = path.join(__dirname, '..', 'web'), TOOLS = path.join(__dirname, '..', '..', 'tools', 'vdu');

	function send(obj) { var s = 'data: ' + JSON.stringify(obj) + '\n\n'; arrViewers.forEach(function(r) { r.write(s); }); }
	function start()
	{
		if (srv) { return; }
		srv = http.createServer(function(req, res)
		{
			var u = req.url.split('?')[0], f;
			if (u === '/events')
			{
				res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', 'Connection': 'keep-alive' });
				arrViewers.push(res);
				Object.keys(objDisp).forEach(function(k) { var d = objDisp[k]; send({ open: d.key, mode: d.mode, title: d.title }); d.log.forEach(function(l) { res.write('data: ' + JSON.stringify({ d: d.key, line: l }) + '\n\n'); }); });
				req.on('close', function() { arrViewers = arrViewers.filter(function(r) { return r !== res; }); });
				return;
			}
			if (u === '/event' && req.method === 'POST')
			{
				var strB = '';
				req.on('data', function(c) { strB += c; });
				req.on('end', function()
				{
					try { var o = JSON.parse(strB), d = objDisp[o.d]; if (d) { d.ch.s.evt(d.ch.n, String(o.e).slice(0, 60)); } } catch (e) { /* bad */ }
					res.writeHead(204); res.end();
				});
				return;
			}
			if (u.indexOf('/img/') === 0)
			{
				var arrP = decodeURIComponent(u.slice(5)).split('/'), strM = arrP.shift(), strTag = arrP.join('/');
				if (/^[A-Za-z0-9_-]+$/.test(strM) && /^[A-Za-z0-9_.\/-]{1,64}$/.test(strTag) && strTag.indexOf('..') < 0)
				{
					f = path.join(cfg.STORE, strM, strTag);
					if (fs.existsSync(f)) { res.writeHead(200, { 'Content-Type': 'image/' + (/\.jpe?g$/i.test(f) ? 'jpeg' : /\.gif$/i.test(f) ? 'gif' : 'png') }); res.end(fs.readFileSync(f)); return; }
				}
				res.writeHead(404); res.end(); return;
			}
			var MAP = { '/': path.join(WEB, 'vdu.html'), '/vdu.js': path.join(TOOLS, 'vdu.js'), '/vdu.css': path.join(TOOLS, 'vdu.css') };
			f = MAP[u];
			if (f && fs.existsSync(f)) { res.writeHead(200, { 'Content-Type': /\.js$/.test(f) ? 'text/javascript' : /\.css$/.test(f) ? 'text/css' : 'text/html; charset=utf-8' }); res.end(fs.readFileSync(f)); return; }
			res.writeHead(404); res.end('not here');
		});
		srv.listen(parseInt(cfg.VDU, 10), '0.0.0.0', function() { console.log('cosd: the virtual display on http://' + require('os').hostname() + ':' + cfg.VDU + '/'); });
		srv.on('error', function(e) { console.log('cosd: VDU web page: ' + e.message); });
	}
	start();							// (up from cosd's start: the HDMI's browser waits on it)
	service('vdu', 'a full HD virtual display on the Pi\'s HDMI (RVDU\'s commands, or mode=hd)', function(ch, args)
	{
		start();
		var m = String(args).match(/mode=(\w+)/i), t = String(args).match(/title=(\S+)/i);
		var d = { key: intNext++, ch: ch, mode: m && m[1].toLowerCase() === 'hd' ? 'hd' : 'cpc', title: t ? t[1].replace(/\+/g, ' ') : 'CyborgOS', log: [], part: '', machine: ch.s.machine };
		objDisp[d.key] = d;
		send({ open: d.key, mode: d.mode, title: d.title, machine: d.machine });
		return {
			data: function(ch, b)
			{
				var arr = (d.part + b.toString('latin1')).split(/\r\n|\r|\n/);
				d.part = arr.pop();
				arr.forEach(function(l)
				{
					var blnCp = d.mode === 'hd' ? /^\s*CLS\b/i.test(l) : /^\s*(MODE\b|m\d)/i.test(l);
					if (blnCp) { d.log = []; }			// (a checkpoint: a viewer joining starts there)
					d.log.push(l);
					if (d.log.length > 5000) { d.log.shift(); }
					send({ d: d.key, line: l, machine: d.machine });
				});
			},
			close: function() { delete objDisp[d.key]; send({ close: d.key }); }
		};
	});
};
