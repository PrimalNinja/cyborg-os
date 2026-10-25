// cosweb.js - a small web server for CyborgOS's network tests (cosregress.js, espsim/nettest.js):
// 8BML pages as an 8bitology server answers them, every request kept.
//   /echo?a=1&b=2   a page listing the parameters (t"a=1" ...)
//   /moved          a 302 to /echo?moved=1
//   /big?n=N        a page of about N bytes
// var web = require('./cosweb.js').start(function(port) { ... }); web.requests: the paths asked for
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var http = require('http');

function page(strTitle_a, arrLines_a)
{
	var q = function(t) { return t.replace(/\\/g, '\\\\').replace(/"/g, '\\"'); };

	return '-"1","' + q(strTitle_a) + '":p"' + q(strTitle_a) + '":n:' + arrLines_a.map(function(x) { return 't"' + q(x) + '":n:'; }).join('') + '.';
}

exports.start = function(cbReady_a, strHost_a)
{
	var objWeb = { requests: [] };

	objWeb.server = http.createServer(function(req, res)
	{
		var u = new URL(req.url, 'http://x');
		var strBody = '';

		objWeb.requests.push(req.url);
		if (u.pathname === '/echo')
		{
			var arrP = [];
			u.searchParams.forEach(function(v, k) { arrP.push(k + '=' + v); });
			strBody = page('Echo', arrP.length ? arrP : ['(no parameters)']);
		}
		else if (u.pathname === '/moved')
		{
			res.writeHead(302, { Location: '/echo?moved=1', 'Content-Length': 0 });
			res.end();
			return;
		}
		else if (u.pathname === '/big')
		{
			var n = parseInt(u.searchParams.get('n') || '4000', 10), arrL = [], k = 0, t = 0;
			while (t < n) { var s = 'line ' + k + ' of the big page, some words to fill it out'; arrL.push(s); t += s.length + 5; k++; }
			strBody = page('Big', arrL);
		}
		else
		{
			res.writeHead(404, { 'Content-Length': 0 });
			res.end();
			return;
		}
		res.writeHead(200, { 'Content-Type': 'text/plain', 'Content-Length': Buffer.byteLength(strBody, 'latin1') });
		res.end(strBody, 'latin1');
	});
	objWeb.server.listen(0, strHost_a || '127.0.0.1', function() { objWeb.port = objWeb.server.address().port; cbReady_a(objWeb.port); });
	objWeb.close = function() { objWeb.server.close(); };
	return objWeb;
};
