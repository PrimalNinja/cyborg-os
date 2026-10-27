// proto.js - CyborgOS's Pi link protocol: frames over any byte stream (the CPC-CPLink's FIFO, a
// serial line - USIfAC, the Next's UART to its Pi Zero -, a TCP socket for tests and emulators).
// docs/cyborgos-pi.md has the protocol; this is its framing, shared by cosd.js (the Pi) and
// cosctl.js (a test client standing in for the CPC).
//
// A frame:  A5  chan  type  id  len-lo  len-hi  payload ...  check
//   chan     0 the control channel, 1-254 those OPEN gave
//   type     1 HELLO, 2 REQ, 3 RSP, 4 DATA, 5 EVT, 6 CLOSE, 7 CREDIT (+ #80: more of this answer)
//   id       a request's number (its answer carries it back), 0 none
//   check    the low byte of the sum of chan ... the payload's last byte
// A receiver hunts for A5, takes a frame whose length is in range and whose check is right, and
// drops anything else (a serial line's noise), looking for the next A5.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';

var T = { HELLO: 1, REQ: 2, RSP: 3, DATA: 4, EVT: 5, CLOSE: 6, CREDIT: 7, MORE: 0x80 };
var SYNC = 0xA5;

function encode(intChan_a, intType_a, intId_a, bufPayload_a)
{
	var buf = bufPayload_a || Buffer.alloc(0), out = Buffer.alloc(buf.length + 7), intSum = 0, i;

	out[0] = SYNC; out[1] = intChan_a & 255; out[2] = intType_a & 255; out[3] = intId_a & 255;
	out[4] = buf.length & 255; out[5] = (buf.length >> 8) & 255;
	buf.copy(out, 6);
	for (i = 1; i < buf.length + 6; i++) { intSum += out[i]; }
	out[buf.length + 6] = intSum & 255;
	return out;
}

// a payload: command text, then a 0 and binary data when there is any
function payload(strText_a, bufBody_a)
{
	var bufT = Buffer.from(strText_a || '', 'latin1');

	return bufBody_a ? Buffer.concat([bufT, Buffer.from([0]), bufBody_a]) : bufT;
}
function split(bufPayload_a)
{
	var i = bufPayload_a.indexOf(0);

	if (i < 0) { return { text: bufPayload_a.toString('latin1'), body: null }; }
	return { text: bufPayload_a.slice(0, i).toString('latin1'), body: bufPayload_a.slice(i + 1) };
}

// Parser: bytes in (feed), frames out (onFrame); intMax_a the longest payload taken
function Parser(intMax_a, fnFrame_a)
{
	this.max = intMax_a; this.onFrame = fnFrame_a; this.buf = Buffer.alloc(0); this.dropped = 0;
}
Parser.prototype.feed = function(bufIn_a)
{
	var b = this.buf = Buffer.concat([this.buf, bufIn_a]), intLen, intSum, i;

	for (;;)
	{
		var intStart = b.indexOf(SYNC);
		if (intStart < 0) { this.dropped += b.length; b = Buffer.alloc(0); break; }
		if (intStart > 0) { this.dropped += intStart; b = b.slice(intStart); }
		if (b.length < 7) { break; }
		intLen = b[4] | (b[5] << 8);
		if (intLen > this.max) { this.dropped++; b = b.slice(1); continue; }	// (not a frame: on to the next A5)
		if (b.length < intLen + 7) { break; }
		for (intSum = 0, i = 1; i < intLen + 6; i++) { intSum += b[i]; }
		if ((intSum & 255) !== b[intLen + 6]) { this.dropped++; b = b.slice(1); continue; }
		var objF = { chan: b[1], type: b[2] & 0x7F, more: (b[2] & 0x80) !== 0, id: b[3], payload: Buffer.from(b.slice(6, 6 + intLen)) };
		b = b.slice(intLen + 7);
		this.onFrame(objF);
	}
	this.buf = b;
};

module.exports = { T: T, SYNC: SYNC, encode: encode, payload: payload, split: split, Parser: Parser };
