// vdp.js - VDP: the Pi's HDMI as a video display processor for the machine on the link - a chip
// with RAM of its own, reached through a port (the link). docs/cyborgos-vdp.md is the design.
//   OPEN vdp profile=v9990 [vsync=1]      one of PROFILES below; vsync=1: a V event every frame
//   REQ: INFO | PATTERNS n (+ data, or a STORE tag) | PALETTE i + data | CLEAR | STATE [id]
//   DATA: the command stream (version byte once, then opcodes - section 4 of the design)
//   EVT: V n | HIT a b | EDGE id side | DIED id
// The engine runs a frame at the profile's rate: the commands held since the last COMMIT are
// applied, the movers move, the bounds act, the collisions are found, the events go out, the
// frame goes to the viewer page (vdu.js's page: a vdp display). A profile is an object in
// PROFILES: adding a target adds one. (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs'), path = require('path');

var VERSION = 1;
var OP = { SPR: 0x01, POS: 0x02, PAT: 0x03, SHOW: 0x04, VEL: 0x05, BOUNDS: 0x06, CLASS: 0x07, KILL: 0x08, ANIM: 0x09, BOX: 0x0C, FLAGS: 0x0D, SEQ: 0x0E, PLAY: 0x0F, TILE: 0x20, TILEROW: 0x21, TEXT: 0x30, SCROLL: 0x40, SCROLLV: 0x41, COMMIT: 0x7F };
var LEN = {};			// an opcode's length (the opcode byte in); TEXT's from its len8
LEN[OP.SPR] = 10; LEN[OP.POS] = 7; LEN[OP.PAT] = 5; LEN[OP.SHOW] = 4; LEN[OP.VEL] = 7; LEN[OP.BOUNDS] = 4; LEN[OP.CLASS] = 5; LEN[OP.KILL] = 3; LEN[OP.ANIM] = 7; LEN[OP.BOX] = 9; LEN[OP.FLAGS] = 4; LEN[OP.PLAY] = 5; LEN[OP.TILE] = 6; LEN[OP.SCROLL] = 6; LEN[OP.SCROLLV] = 6; LEN[OP.COMMIT] = 1;	// TEXT's, TILEROW's and SEQ's from their count byte
var BOUNDS = { NONE: 0, WRAP: 1, KILL: 2, STOP: 3, EVENT: 4, BOUNCE: 5 };	// BOUNCE: within the BOX (hwlib's Bounds), the velocity reversed

// ---- the profiles: the model a program expects. decode(buf, n, palette) -> an array of n
// patterns, each { w, h, rgba: Buffer w*h*4 } for the viewer; a chip profile's pixel format
function decodeIndexed(intBits_a, intW_a, intH_a)
{
	return function(buf_a, intN_a, arrPal_a)
	{
		var arrOut = [], intP = 0, intI = 0, intJ = 0, intK = 0, intC = 0, intBytes = (intW_a * intH_a * intBits_a) >> 3, rgba, intPix = 0;
		for (intI = 0; intI < intN_a; intI++)
		{
			rgba = Buffer.alloc(intW_a * intH_a * 4);
			for (intJ = 0; intJ < intW_a * intH_a; intJ++)
			{
				if (intBits_a === 8) { intC = buf_a[intP + intJ] || 0; }
				else if (intBits_a === 4) { intK = buf_a[intP + (intJ >> 1)] || 0; intC = (intJ & 1) ? (intK & 15) : (intK >> 4); }
				else { intK = buf_a[intP + (intJ >> 3)] || 0; intC = (intK >> (7 - (intJ & 7))) & 1; }
				intPix = intJ * 4;
				if (intC === 0) { rgba[intPix + 3] = 0; }
				else { rgba[intPix] = arrPal_a[intC * 3] || 0; rgba[intPix + 1] = arrPal_a[intC * 3 + 1] || 0; rgba[intPix + 2] = arrPal_a[intC * 3 + 2] || 0; rgba[intPix + 3] = 255; }
			}
			arrOut.push({ w: intW_a, h: intH_a, rgba: rgba });
			intP += intBytes;
		}
		return arrOut;
	};
}
function decodeRgba(intW_a, intH_a)
{
	return function(buf_a, intN_a)
	{
		var arrOut = [], intI = 0, intBytes = intW_a * intH_a * 4;
		for (intI = 0; intI < intN_a; intI++)
		{
			arrOut.push({ w: intW_a, h: intH_a, rgba: Buffer.from(buf_a.slice(intI * intBytes, (intI + 1) * intBytes)) });
		}
		return arrOut;
	};
}
var PROFILES = {
	// bpp: a pattern's bits a pixel (its bytes = sprW x sprH x bpp / 8); colours: the palette's size (0: RGBA, no palette);
	// tileBpp: a tile's (8 x 8) bits a pixel; the tile layer is width / 8 x height / 8 cells (the Next's 40 x 32); the
	// bitmap layer (Layer 2) is width x height x bitmapBpp (zxn: 8-bit through the palette)
	v9938:  { width: 256, height: 212, sprites: 32, sprW: 16, sprH: 16, patterns: 256, bpp: 1, colours: 16, rate: 60, tileBpp: 1, bitmapBpp: 0, decode: decodeIndexed(1, 16, 16) },
	v9990:  { width: 256, height: 212, sprites: 125, sprW: 16, sprH: 16, patterns: 512, bpp: 4, colours: 256, rate: 60, tileBpp: 4, bitmapBpp: 4, decode: decodeIndexed(4, 16, 16) },
	zxn:    { width: 320, height: 256, sprites: 128, sprW: 16, sprH: 16, patterns: 64, bpp: 8, colours: 256, rate: 50, tileBpp: 4, bitmapBpp: 8, decode: decodeIndexed(8, 16, 16) },
	md:     { width: 320, height: 224, sprites: 80, sprW: 16, sprH: 16, patterns: 2048, bpp: 4, colours: 64, rate: 60, tileBpp: 4, bitmapBpp: 0, decode: decodeIndexed(4, 16, 16) },
	pi720:  { width: 1280, height: 720, sprites: 4096, sprW: 32, sprH: 32, patterns: 4096, bpp: 32, colours: 0, rate: 60, tileBpp: 32, bitmapBpp: 32, decode: decodeRgba(32, 32) },
	pi1080: { width: 1920, height: 1080, sprites: 4096, sprW: 32, sprH: 32, patterns: 4096, bpp: 32, colours: 0, rate: 60, tileBpp: 32, bitmapBpp: 32, decode: decodeRgba(32, 32) },
	pi2160: { width: 3840, height: 2160, sprites: 4096, sprW: 32, sprH: 32, patterns: 4096, bpp: 32, colours: 0, rate: 60, tileBpp: 32, bitmapBpp: 32, decode: decodeRgba(32, 32) }
};

function s16(buf_a, intAt_a) { var intV = buf_a[intAt_a] | (buf_a[intAt_a + 1] << 8); return intV >= 0x8000 ? intV - 0x10000 : intV; }
function u16(buf_a, intAt_a) { return buf_a[intAt_a] | (buf_a[intAt_a + 1] << 8); }

// ---- a display: one open channel's VDP
function Display(ch_a, strProfile_a, blnVsync_a, fnViewer_a)
{
	var d = this;
	d.ch = ch_a;
	d.name = strProfile_a;
	d.p = PROFILES[strProfile_a];
	d.vsync = blnVsync_a;
	d.viewer = fnViewer_a;			// (what the page is sent: {open}, {frame}, {patterns}, {close})
	d.frame = 0;
	d.spr = [];						// id -> { x, y (12.4), pat, vis, vx, vy, bounds, cls, mask, af, ac, ad, at }
	d.box = { x0: 0, y0: 0, x1: (PROFILES[strProfile_a].width - PROFILES[strProfile_a].sprW) << 4, y1: (PROFILES[strProfile_a].height - PROFILES[strProfile_a].sprH) << 4 };	// the BOUNCE box (12.4): the screen unless BOX said
	d.held = [];					// commands since the last COMMIT (applied at the frame)
	d.batch = [];					// the batch being read (DATA frames can split a command)
	d.part = Buffer.alloc(0);
	d.gotVersion = false;
	d.pal = [];						// 3 bytes an entry
	d.pats = {};					// pattern id -> { w, h, rgba }
	d.text = {};					// 'col,row' -> character code (v1 of the text layer)
	d.cols = d.p.width >> 3; d.rows = d.p.height >> 3;
	d.cells = new Array(d.cols * d.rows);	// the tile layer: a cell is [tile, flags] or undefined (nothing: the bitmap shows)
	d.tilesDirty = true;
	d.tiles = {};					// tile id -> { w, h, rgba }
	d.scroll = { x: 0, y: 0, vx: 0, vy: 0 };	// the tile layer's offset (12.4) and its own velocity
	d.bitmap = null;				// Layer 2: { w, h, rgba } when set
	d.seqs = {};					// sequence id -> [frames]: a pattern number, 0 stop (the last frame stays), -n go to step n (1 based: a loop, or a redirect forward)
	d.hits = {};					// 'a,b' seen this frame
	d.timer = null;
}
// a tile layer cell set (col, row within the layer; tile 0xFFFF: nothing)
Display.prototype.cell = function(intCol_a, intRow_a, intTile_a, intFlags_a)
{
	var d = this;
	if (intCol_a >= 0 && intCol_a < d.cols && intRow_a >= 0 && intRow_a < d.rows)
	{
		d.cells[intRow_a * d.cols + intCol_a] = (intTile_a === 0xFFFF) ? undefined : [intTile_a, intFlags_a];
		d.tilesDirty = true;
	}
};
Display.prototype.sprite = function(intId_a)
{
	var d = this, s = null;
	if (intId_a >= 0 && intId_a < d.p.sprites)
	{
		s = d.spr[intId_a];
		if (!s) { s = { x: 0, y: 0, pat: 0, vis: 0, vx: 0, vy: 0, bounds: BOUNDS.NONE, cls: 0, mask: 0, af: 0, ac: 0, ad: 0, at: 0, flags: 0, seq: -1, step: 0 }; d.spr[intId_a] = s; }
	}
	return s;
};
// the command stream: whole commands cut out of the DATA bytes (a command can span two frames)
Display.prototype.data = function(buf_a)
{
	var d = this, buf = Buffer.concat([d.part, buf_a]), intAt = 0, intOp = 0, intLen = 0;
	if (!d.gotVersion && buf.length > 0)
	{
		if (buf[0] !== VERSION) { d.ch.s.evt(d.ch.n, 'ERR version ' + buf[0]); }
		d.gotVersion = true;
		intAt = 1;
	}
	while (intAt < buf.length)
	{
		intOp = buf[intAt];
		intLen = (intOp === OP.TEXT) ? (intAt + 3 < buf.length ? 4 + buf[intAt + 3] : 0) : (intOp === OP.TILEROW) ? (intAt + 3 < buf.length ? 4 + buf[intAt + 3] * 3 : 0) : (intOp === OP.SEQ) ? (intAt + 2 < buf.length ? 3 + buf[intAt + 2] * 2 : 0) : (LEN[intOp] || 0);
		if (intLen === 0 && intOp !== OP.TEXT && intOp !== OP.TILEROW && intOp !== OP.SEQ)
		{
			d.ch.s.evt(d.ch.n, 'ERR opcode ' + intOp.toString(16));	// unknown: the rest of this DATA frame dropped
			intAt = buf.length;
		}
		else if (intLen === 0 || intAt + intLen > buf.length)
		{
			d.part = Buffer.from(buf.slice(intAt));						// the rest comes in the next frame
			intAt = buf.length + 1;
		}
		else
		{
			if (intOp === OP.COMMIT) { d.commit(); } else { d.held.push(Buffer.from(buf.slice(intAt, intAt + intLen))); }
			intAt += intLen;
		}
	}
	if (intAt === buf.length) { d.part = Buffer.alloc(0); }
};
Display.prototype.commit = function()
{
	var d = this;
	d.batch = d.batch.concat(d.held);		// (two COMMITs within one frame: both batches applied, in order)
	d.held = [];
};
Display.prototype.apply = function(cmd_a)
{
	var d = this, s = null, intOp = cmd_a[0], intId = u16(cmd_a, 1), intI = 0, intCol = 0, intRow = 0;
	if (intOp === OP.TEXT)
	{
		intCol = cmd_a[1]; intRow = cmd_a[2];
		for (intI = 0; intI < cmd_a[3]; intI++) { d.text[(intCol + intI) + ',' + intRow] = cmd_a[4 + intI]; }
	}
	else if (intOp === OP.BOX) { d.box = { x0: s16(cmd_a, 1) << 4, y0: s16(cmd_a, 3) << 4, x1: s16(cmd_a, 5) << 4, y1: s16(cmd_a, 7) << 4 }; }
	else if (intOp === OP.SEQ)
	{
		var arrSeq = [];
		for (intI = 0; intI < cmd_a[2]; intI++) { arrSeq.push(s16(cmd_a, 3 + intI * 2)); }
		d.seqs[cmd_a[1]] = arrSeq;
	}
	else if (intOp === OP.TILE) { d.cell(cmd_a[1], cmd_a[2], u16(cmd_a, 3), cmd_a[5]); }
	else if (intOp === OP.TILEROW)
	{
		for (intI = 0; intI < cmd_a[3]; intI++) { d.cell(cmd_a[2] + intI, cmd_a[1], u16(cmd_a, 4 + intI * 3), cmd_a[6 + intI * 3]); }
	}
	else if (intOp === OP.SCROLL) { d.scroll.x = s16(cmd_a, 2) << 4; d.scroll.y = s16(cmd_a, 4) << 4; }
	else if (intOp === OP.SCROLLV) { d.scroll.vx = s16(cmd_a, 2); d.scroll.vy = s16(cmd_a, 4); }
	else
	{
		s = d.sprite(intId);
		if (s)
		{
			if (intOp === OP.SPR) { s.pat = u16(cmd_a, 3); s.x = s16(cmd_a, 5) << 4; s.y = s16(cmd_a, 7) << 4; s.vis = cmd_a[9] & 1; s.ac = 0; }
			else if (intOp === OP.ANIM) { s.af = u16(cmd_a, 3); s.ac = cmd_a[5]; s.ad = cmd_a[6]; s.at = cmd_a[6]; s.pat = s.af; }
			else if (intOp === OP.FLAGS) { s.flags = cmd_a[3]; }
			else if (intOp === OP.PLAY)
			{
				// PLAY id seq delay: the sequence from its first step; the range animation off
				s.seq = cmd_a[3]; s.step = 0; s.ad = cmd_a[4]; s.at = cmd_a[4]; s.ac = 0;
				if (d.seqs[s.seq] && d.seqs[s.seq].length && d.seqs[s.seq][0] > 0) { s.pat = d.seqs[s.seq][0]; }
			}		// bit 1 mirror X, 2 mirror Y, 3 rotate, 4-5 scale 0-3 (x1 x2 x4 x8)
			else if (intOp === OP.POS) { s.x = s16(cmd_a, 3) << 4; s.y = s16(cmd_a, 5) << 4; }
			else if (intOp === OP.PAT) { s.pat = u16(cmd_a, 3); }
			else if (intOp === OP.SHOW) { s.vis = cmd_a[3] & 1; }
			else if (intOp === OP.VEL) { s.vx = s16(cmd_a, 3); s.vy = s16(cmd_a, 5); }
			else if (intOp === OP.BOUNDS) { s.bounds = cmd_a[3]; }
			else if (intOp === OP.CLASS) { s.cls = cmd_a[3]; s.mask = cmd_a[4]; }
			else if (intOp === OP.KILL) { s.vis = 0; s.vx = 0; s.vy = 0; }
		}
	}
};
// one frame: the batch, the movers, the bounds, the collisions, the events, the viewer
Display.prototype.tick = function()
{
	var d = this, intI = 0, intJ = 0, s = null, t = null, intW = d.p.width << 4, intH = d.p.height << 4, intSw = d.p.sprW << 4, intSh = d.p.sprH << 4;
	var arrEvt = [], arrVis = [], strKey = '', objHits = {}, arrFrame = [];
	d.frame++;
	for (intI = 0; intI < d.batch.length; intI++) { d.apply(d.batch[intI]); }
	d.batch = [];
	for (intI = 0; intI < d.spr.length; intI++)
	{
		s = d.spr[intI];
		if (s && s.vis)
		{
			s.x += s.vx; s.y += s.vy;
			if (s.bounds === BOUNDS.BOUNCE)
			{
				if (s.x < d.box.x0) { s.x = d.box.x0; s.vx = -s.vx; } if (s.x > d.box.x1) { s.x = d.box.x1; s.vx = -s.vx; }
				if (s.y < d.box.y0) { s.y = d.box.y0; s.vy = -s.vy; } if (s.y > d.box.y1) { s.y = d.box.y1; s.vy = -s.vy; }
			}
			if (s.ac)
			{
				s.at--;
				if (s.at <= 0) { s.at = s.ad; s.pat++; if (s.pat >= s.af + s.ac) { s.pat = s.af; } }
			}
			else if (s.seq >= 0 && d.seqs[s.seq])
			{
				s.at--;
				if (s.at <= 0)
				{
					s.at = s.ad;
					var arrQ = d.seqs[s.seq], intV = (s.step + 1 < arrQ.length) ? arrQ[s.step + 1] : 0;
					if (intV > 0) { s.step++; s.pat = intV; }
					else if (intV < 0 && -intV - 1 < arrQ.length && arrQ[-intV - 1] > 0) { s.step = -intV - 1; s.pat = arrQ[s.step]; }
					else { s.seq = -1; arrEvt.push('DONE ' + intI); }	// 0 (or the end): stopped on the frame shown
				}
			}
			if (s.bounds !== BOUNDS.NONE && s.bounds !== BOUNDS.BOUNCE && (s.x < 0 || s.x + intSw > intW || s.y < 0 || s.y + intSh > intH))
			{
				if (s.bounds === BOUNDS.WRAP)
				{
					if (s.x + intSw < 0) { s.x += intW + intSw; } else if (s.x > intW) { s.x -= intW + intSw; }
					if (s.y + intSh < 0) { s.y += intH + intSh; } else if (s.y > intH) { s.y -= intH + intSh; }
				}
				else if (s.bounds === BOUNDS.KILL)
				{
					if (s.x + intSw < 0 || s.x > intW || s.y + intSh < 0 || s.y > intH) { s.vis = 0; s.vx = 0; s.vy = 0; arrEvt.push('DIED ' + intI); }
				}
				else if (s.bounds === BOUNDS.STOP)
				{
					if (s.x < 0) { s.x = 0; s.vx = 0; } if (s.x + intSw > intW) { s.x = intW - intSw; s.vx = 0; }
					if (s.y < 0) { s.y = 0; s.vy = 0; } if (s.y + intSh > intH) { s.y = intH - intSh; s.vy = 0; }
				}
				else
				{
					if (s.x < 0) { arrEvt.push('EDGE ' + intI + ' 0'); } if (s.x + intSw > intW) { arrEvt.push('EDGE ' + intI + ' 1'); }
					if (s.y < 0) { arrEvt.push('EDGE ' + intI + ' 2'); } if (s.y + intSh > intH) { arrEvt.push('EDGE ' + intI + ' 3'); }
				}
			}
			if (s.vis) { arrVis.push(intI); }
		}
	}
	for (intI = 0; intI < arrVis.length; intI++)
	{
		s = d.spr[arrVis[intI]];
		if (s.mask)
		{
			for (intJ = 0; intJ < arrVis.length; intJ++)
			{
				t = d.spr[arrVis[intJ]];
				if (intJ !== intI && (s.mask & (1 << t.cls)) && s.x < t.x + intSw && t.x < s.x + intSw && s.y < t.y + intSh && t.y < s.y + intSh)
				{
					strKey = Math.min(arrVis[intI], arrVis[intJ]) + ' ' + Math.max(arrVis[intI], arrVis[intJ]);
					if (!objHits[strKey]) { objHits[strKey] = true; arrEvt.push('HIT ' + strKey); }
				}
			}
		}
	}
	if (d.vsync) { arrEvt.push('V ' + d.frame); }
	for (intI = 0; intI < arrEvt.length; intI++) { d.ch.s.evt(d.ch.n, arrEvt[intI]); }
	d.scroll.x += d.scroll.vx; d.scroll.y += d.scroll.vy;
	for (intI = 0; intI < arrVis.length; intI++) { s = d.spr[arrVis[intI]]; arrFrame.push([arrVis[intI], s.x >> 4, s.y >> 4, s.pat, s.flags]); }
	var objOut = { frame: d.frame, spr: arrFrame, text: d.text, scroll: [d.scroll.x >> 4, d.scroll.y >> 4] };
	if (d.tilesDirty) { objOut.cells = d.cells.map(function(c_a) { return c_a ? c_a[0] + (c_a[1] << 16) : -1; }); objOut.cols = d.cols; d.tilesDirty = false; }
	d.viewer(objOut);
};
Display.prototype.state = function(intId_a)
{
	var d = this, arrOut = [], intI = 0, s = null;
	for (intI = 0; intI < d.spr.length; intI++)
	{
		s = d.spr[intI];
		if (s && (intId_a < 0 || intId_a === intI)) { arrOut.push(intI + ' ' + (s.x >> 4) + ' ' + (s.y >> 4) + ' ' + s.pat + ' ' + s.vis); }
	}
	return arrOut;
};

module.exports = function(service, cfg)
{
	var objDisp = {}, intNext = 1;
	function viewerFeed(d_a) { return function(o_a) { if (cfg.VIEWER) { o_a.d = d_a.key; o_a.kind = 'vdp'; cfg.VIEWER(o_a); } }; }

	service('vdp', 'the Pi\'s HDMI as a video display processor (profile=v9938|v9990|zxn|md|pi720|pi1080|pi2160)', function(ch, args)
	{
		var m = String(args).match(/profile=(\w+)/i), strProfile = m ? m[1].toLowerCase() : 'v9990', blnVsync = /vsync=1/i.test(String(args));
		var d = null;
		if (!PROFILES[strProfile]) { throw new Error('no such profile ' + strProfile); }
		d = new Display(ch, strProfile, blnVsync, function(o_a) { if (cfg.VIEWER) { o_a.d = d.key; o_a.kind = 'vdp'; cfg.VIEWER(o_a); } });
		d.key = intNext++;
		objDisp[d.key] = d;
		d.viewer({ open: d.key, kind: 'vdp', profile: strProfile, width: d.p.width, height: d.p.height, machine: ch.s.machine });
		d.timer = setInterval(function() { d.tick(); }, Math.round(1000 / d.p.rate));
		// the profile's installed assets: the store's GRAPHICS/<PROFILE>/PATTERNS, TILES, LAYER2, PALETTE
		// (put there by an installer through Streamer's GRAPHICS:V9990/... paths, or from a PC) loaded now
		var strFolder = { v9938: 'V9938', v9990: 'V9990', zxn: 'ZXNEXT', md: 'MD' }[strProfile] || 'PINATIVE';
		var strBase = path.join(cfg.STORE, ch.s.machine, 'GRAPHICS', strFolder);
		var fnLoad = function(strName_a, fnWith_a) { var f = path.join(strBase, strName_a); if (fs.existsSync(f)) { try { fnWith_a(fs.readFileSync(f)); } catch (e) { ch.s.evt(ch.n, 'ERR asset ' + strName_a + ' ' + e.message); } } };
		fnLoad('PALETTE', function(buf_a) { for (var intK = 0; intK < buf_a.length; intK++) { d.pal[intK] = buf_a[intK]; } });
		fnLoad('PATTERNS', function(buf_a)
		{
			var intN = Math.min(d.p.patterns, Math.floor(buf_a.length / ((d.p.sprW * d.p.sprH * d.p.bpp) >> 3))), arrP = d.p.decode(buf_a, intN, d.pal), intK = 0;
			for (intK = 0; intK < arrP.length; intK++) { d.pats[intK] = arrP[intK]; }
			d.viewer({ patterns: arrP.map(function(p_a, intJ_a) { return { id: intJ_a, w: p_a.w, h: p_a.h, rgba: p_a.rgba.toString('base64') }; }) });
		});
		fnLoad('TILES', function(buf_a)
		{
			var intN = Math.floor(buf_a.length / ((64 * d.p.tileBpp) >> 3)), arrT = (d.p.tileBpp === 32 ? decodeRgba(8, 8) : decodeIndexed(d.p.tileBpp, 8, 8))(buf_a, intN, d.pal), intK = 0;
			for (intK = 0; intK < arrT.length; intK++) { d.tiles[intK] = arrT[intK]; }
			d.viewer({ tiles: arrT.map(function(p_a, intJ_a) { return { id: intJ_a, w: 8, h: 8, rgba: p_a.rgba.toString('base64') }; }) });
		});
		fnLoad('LAYER2', function(buf_a)
		{
			if (d.p.bitmapBpp && buf_a.length >= ((d.p.width * d.p.height * d.p.bitmapBpp) >> 3))
			{
				d.bitmap = (d.p.bitmapBpp === 32 ? decodeRgba(d.p.width, d.p.height) : decodeIndexed(d.p.bitmapBpp, d.p.width, d.p.height))(buf_a, 1, d.pal)[0];
				d.viewer({ bitmap: { w: d.p.width, h: d.p.height, rgba: d.bitmap.rgba.toString('base64') } });
			}
		});
		return {
			req: function(ch_a, intId_a, strText_a, bufBody_a)
			{
				var w = strText_a.trim().split(/\s+/), cmd = (w[0] || '').toUpperCase(), intN = 0, intFrom = 0, buf = bufBody_a, arrPats = [], intI = 0, strTag = '';
				if (cmd === 'INFO') { ch_a.s.rsp(ch_a.n, intId_a, 'OK ' + d.name + ' ' + d.p.width + ' ' + d.p.height + ' ' + d.p.sprites + ' ' + d.p.patterns + ' ' + (d.cols * d.rows) + ' ' + d.p.rate + ' ' + d.cols + 'x' + d.rows); }
				else if (cmd === 'TILES')
				{
					// TILES n [tag]: tile definitions n on, 8 x 8 at the profile's tileBpp (zxn: 4-bit, 32 bytes each), from the data or a STORE tag
					intFrom = parseInt(w[1], 10) || 0;
					if (w[2])
					{
						if (!/^[A-Za-z0-9_.\/-]{1,64}$/.test(w[2]) || w[2].indexOf('..') >= 0) { throw new Error('bad tag ' + w[2]); }
						buf = fs.readFileSync(path.join(cfg.STORE, ch_a.s.machine, w[2]));
					}
					if (!buf || !buf.length) { throw new Error('no data'); }
					intN = Math.floor(buf.length / ((64 * d.p.tileBpp) >> 3));
					arrPats = (d.p.tileBpp === 32 ? decodeRgba(8, 8) : decodeIndexed(d.p.tileBpp, 8, 8))(buf, intN, d.pal);
					for (intI = 0; intI < arrPats.length; intI++) { d.tiles[intFrom + intI] = arrPats[intI]; }
					d.viewer({ tiles: arrPats.map(function(p_a, intK_a) { return { id: intFrom + intK_a, w: 8, h: 8, rgba: p_a.rgba.toString('base64') }; }) });
					ch_a.s.rsp(ch_a.n, intId_a, 'OK ' + intN);
				}
				else if (cmd === 'LAYER2')
				{
					// LAYER2 [tag]: the bitmap layer whole, width x height pixels at bitmapBpp (zxn: 8-bit through the palette; pi: RGBA)
					if (!d.p.bitmapBpp) { throw new Error('no bitmap layer in ' + d.name); }
					if (w[1])
					{
						if (!/^[A-Za-z0-9_.\/-]{1,64}$/.test(w[1]) || w[1].indexOf('..') >= 0) { throw new Error('bad tag ' + w[1]); }
						buf = fs.readFileSync(path.join(cfg.STORE, ch_a.s.machine, w[1]));
					}
					if (!buf || buf.length < ((d.p.width * d.p.height * d.p.bitmapBpp) >> 3)) { throw new Error('short data'); }
					arrPats = (d.p.bitmapBpp === 32 ? decodeRgba(d.p.width, d.p.height) : decodeIndexed(d.p.bitmapBpp, d.p.width, d.p.height))(buf, 1, d.pal);
					d.bitmap = arrPats[0];
					d.viewer({ bitmap: { w: d.p.width, h: d.p.height, rgba: d.bitmap.rgba.toString('base64') } });
					ch_a.s.rsp(ch_a.n, intId_a, 'OK');
				}
				else if (cmd === 'TILEAT')
				{
					// TILEAT col row: the cell (tests, tools): OK tile flags | OK none
					var c = d.cells[(parseInt(w[2], 10) || 0) * d.cols + (parseInt(w[1], 10) || 0)];
					ch_a.s.rsp(ch_a.n, intId_a, c ? ('OK ' + c[0] + ' ' + c[1]) : 'OK none');
				}
				else if (cmd === 'PATTERNS')
				{
					intFrom = parseInt(w[1], 10) || 0;
					if (w[2])
					{
						strTag = w[2];
						if (!/^[A-Za-z0-9_.\/-]{1,64}$/.test(strTag) || strTag.indexOf('..') >= 0) { throw new Error('bad tag ' + strTag); }
						buf = fs.readFileSync(path.join(cfg.STORE, ch_a.s.machine, strTag));
					}
					if (!buf || !buf.length) { throw new Error('no data'); }
					intN = Math.floor(buf.length / ((d.p.sprW * d.p.sprH * d.p.bpp) >> 3));
					if (intFrom + intN > d.p.patterns) { intN = d.p.patterns - intFrom; }
					arrPats = d.p.decode(buf, intN, d.pal);
					for (intI = 0; intI < arrPats.length; intI++) { d.pats[intFrom + intI] = arrPats[intI]; }
					d.viewer({ patterns: arrPats.map(function(p_a, intK_a) { return { id: intFrom + intK_a, w: p_a.w, h: p_a.h, rgba: p_a.rgba.toString('base64') }; }) });
					ch_a.s.rsp(ch_a.n, intId_a, 'OK ' + intN);
				}
				else if (cmd === 'PALETTE')
				{
					intFrom = parseInt(w[1], 10) || 0;
					if (!buf || !buf.length) { throw new Error('no data'); }
					for (intI = 0; intI < buf.length; intI++) { d.pal[intFrom * 3 + intI] = buf[intI]; }
					ch_a.s.rsp(ch_a.n, intId_a, 'OK ' + Math.floor(buf.length / 3));
				}
				else if (cmd === 'CLEAR') { d.spr = []; d.held = []; d.batch = []; d.text = {}; d.seqs = {}; d.cells = new Array(d.cols * d.rows); d.tilesDirty = true; d.scroll = { x: 0, y: 0, vx: 0, vy: 0 }; ch_a.s.rsp(ch_a.n, intId_a, 'OK'); }
				else if (cmd === 'STATE') { ch_a.s.rsp(ch_a.n, intId_a, 'OK ' + d.state(w[1] === undefined ? -1 : parseInt(w[1], 10)).join('\n')); }
				else { ch_a.s.rsp(ch_a.n, intId_a, 'ERR noreq ' + cmd); }
			},
			data: function(ch_a, buf_a) { d.data(buf_a); },
			close: function() { clearInterval(d.timer); delete objDisp[d.key]; d.viewer({ close: d.key }); }
		};
	});
};
