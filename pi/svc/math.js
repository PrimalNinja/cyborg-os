// math.js - MATH: the Pi as a maths coprocessor.
//   EVAL expression      OK result - + - * / % ^, ( ), numbers (1.5, 1e9, &HFF, &B101), pi, e,
//                        sin cos tan asin acos atan atan2(y,x) sqrt abs exp ln log log10 floor
//                        ceil round int min max pow hypot - floating point (doubles); no eval()
//   BIG expression       OK result - whole numbers of any size (BigInt): + - * / % ^ ( )
//   XFORM + data         3D points through a matrix, projected: data = 12 words (a 3 x 4 matrix,
//                        8.8 fixed point, rows), 2 words (the screen's centre x, y), 1 word (the
//                        focal length), then the points (x, y, z: signed words) - back: the
//                        points' screen x, y (signed words; -32768 behind the eye). Little end
//                        first, as the Z80 keeps them.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';

module.exports = function(service)
{
	// a small expression reader: tokens, then precedence climbing
	function evaluate(str, bBig)
	{
		var t = [], i = 0, m, re = /\s*(?:(&H[0-9A-F]+)|(&B[01]+)|(\d+\.?\d*(?:E[+-]?\d+)?|\.\d+(?:E[+-]?\d+)?)|([A-Z_][A-Z0-9_]*)|(\*\*|[-+*\/%^(),]))/iy;
		while (i < str.length)
		{
			re.lastIndex = i;
			m = re.exec(str);
			if (!m) { if (/^\s*$/.test(str.slice(i))) { break; } throw new Error('what is ' + str.slice(i, i + 8) + '?'); }
			i = re.lastIndex;
			if (m[1]) { t.push({ n: bBig ? BigInt('0x' + m[1].slice(2)) : parseInt(m[1].slice(2), 16) }); }
			else if (m[2]) { t.push({ n: bBig ? BigInt('0b' + m[2].slice(2)) : parseInt(m[2].slice(2), 2) }); }
			else if (m[3]) { if (bBig && /[.E]/i.test(m[3])) { throw new Error('BIG takes whole numbers'); } t.push({ n: bBig ? BigInt(m[3]) : parseFloat(m[3]) }); }
			else if (m[4]) { t.push({ id: m[4].toLowerCase() }); }
			else { t.push({ op: m[5] === '**' ? '^' : m[5] }); }
		}
		var p = 0;
		var FN = { sin: Math.sin, cos: Math.cos, tan: Math.tan, asin: Math.asin, acos: Math.acos, atan: Math.atan, atan2: Math.atan2, sqrt: Math.sqrt, abs: Math.abs,
			exp: Math.exp, ln: Math.log, log: Math.log, log10: Math.log10, floor: Math.floor, ceil: Math.ceil, round: Math.round, int: Math.trunc, min: Math.min, max: Math.max, pow: Math.pow, hypot: Math.hypot };
		function peek() { return t[p]; }
		function atom()
		{
			var k = t[p++], a, v;
			if (!k) { throw new Error('the expression ends too soon'); }
			if (k.op === '-') { v = unary(); return bBig ? -v : -v; }
			if (k.op === '+') { return unary(); }
			if (k.op === '(') { v = expr(0); if (!t[p] || t[p].op !== ')') { throw new Error(') missing'); } p++; return v; }
			if (k.n !== undefined) { return k.n; }
			if (k.id)
			{
				if (bBig) { throw new Error('BIG has no ' + k.id); }
				if (k.id === 'pi') { return Math.PI; }
				if (k.id === 'e') { return Math.E; }
				if (!FN[k.id]) { throw new Error('no function ' + k.id); }
				if (!t[p] || t[p].op !== '(') { throw new Error(k.id + ' needs ( )'); }
				p++; a = [];
				if (t[p] && t[p].op === ')') { p++; } else { for (;;) { a.push(expr(0)); if (t[p] && t[p].op === ',') { p++; continue; } if (t[p] && t[p].op === ')') { p++; break; } throw new Error(') missing'); } }
				return FN[k.id].apply(null, a);
			}
			throw new Error('unexpected ' + (k.op || ''));
		}
		function unary() { return atom(); }
		var PREC = { '+': 1, '-': 1, '*': 2, '/': 2, '%': 2, '^': 3 };
		function expr(min)
		{
			var l = atom(), o, r;
			while ((o = peek()) && PREC[o.op] && PREC[o.op] >= min)
			{
				p++;
				r = expr(o.op === '^' ? PREC[o.op] : PREC[o.op] + 1);
				if (o.op === '+') { l = l + r; } else if (o.op === '-') { l = l - r; } else if (o.op === '*') { l = l * r; }
				else if (o.op === '/') { if (bBig && r === 0n) { throw new Error('divided by 0'); } l = l / r; }
				else if (o.op === '%') { l = l % r; } else { l = bBig ? l ** r : Math.pow(l, r); }
			}
			return l;
		}
		var v = expr(0);
		if (p < t.length) { throw new Error('more than one expression'); }
		return bBig ? v.toString() : (Number.isInteger(v) ? String(v) : String(+v.toPrecision(15)));
	}
	function xform(b)
	{
		var M = [], i, n, out, cx, cy, f, x, y, z, X, Y, Z;
		if (!b || b.length < 30) { throw new Error('XFORM: 12 + 3 words, then the points'); }
		for (i = 0; i < 12; i++) { M.push(b.readInt16LE(i * 2) / 256); }
		cx = b.readInt16LE(24); cy = b.readInt16LE(26); f = b.readInt16LE(28);
		n = Math.floor((b.length - 30) / 6);
		out = Buffer.alloc(n * 4);
		for (i = 0; i < n; i++)
		{
			x = b.readInt16LE(30 + i * 6); y = b.readInt16LE(32 + i * 6); z = b.readInt16LE(34 + i * 6);
			X = M[0] * x + M[1] * y + M[2] * z + M[3];
			Y = M[4] * x + M[5] * y + M[6] * z + M[7];
			Z = M[8] * x + M[9] * y + M[10] * z + M[11];
			if (Z <= 0) { out.writeInt16LE(-32768, i * 4); out.writeInt16LE(-32768, i * 4 + 2); continue; }
			out.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(cx + X * f / Z))), i * 4);
			out.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(cy - Y * f / Z))), i * 4 + 2);
		}
		return out;
	}
	service('math', 'a maths coprocessor (EVAL, BIG, XFORM: 3D points projected)', function()
	{
		return {
			req: function(ch, id, text, body)
			{
				var w = text.trim(), c = w.split(/\s+/)[0].toUpperCase(), r;
				try
				{
					if (c === 'EVAL') { ch.s.rsp(ch.n, id, 'OK ' + evaluate(w.slice(4), false)); }
					else if (c === 'BIG') { ch.s.rsp(ch.n, id, 'OK ' + evaluate(w.slice(3), true)); }
					else if (c === 'XFORM') { r = xform(body); ch.s.rsp(ch.n, id, 'OK ' + (r.length / 4), r); }
					else { ch.s.rsp(ch.n, id, 'ERR unknown ' + c); }
				}
				catch (e) { ch.s.rsp(ch.n, id, 'ERR ' + e.message); }
			}
		};
	});
	module.exports.evaluate = evaluate;
};
