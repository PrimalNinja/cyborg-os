// ideflat.js - WinAPE's IDE image ("BITWISE DRIVE IMAGE FILE": sparse, a 4-level block map of 512
// byte blocks) to a plain disc image (a sparse file on the PC: only the sectors the image holds are
// written), so any FAT tool can read it.
//   node tools/ideflat/ideflat.js IN.ide OUT.img
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';
var fs = require('fs');

var arrA = process.argv.slice(2);
if (arrA.length < 2) { console.log('node ideflat.js IN.ide OUT.img'); process.exit(1); }
var buf = fs.readFileSync(arrA[0]);
if (buf.toString('latin1', 0, 24) !== 'BITWISE DRIVE IMAGE FILE') { console.log('not a WinAPE IDE image'); process.exit(1); }

function unset(e) { return e === 0 || e === 0xFFFF0000 || e === 0xFFFFFFFF; }
var fd = fs.openSync(arrA[1], 'w'), intMax = 0, intN = 0;

// the map: block 1 the top level; each level 128 entries (7 bits of the sector number), sector
// bits 27-21, 20-14, 13-7, 6-0; the last level's entry the block holding the sector
(function walk(intB_a, intLvl_a, intBase_a)
{
	for (var i = 0; i < 128; i++)
	{
		var e = buf.readUInt32LE(intB_a * 512 + 4 * i);
		if (unset(e) || e * 512 + 512 > buf.length) { continue; }
		var intS = intBase_a | (i << (21 - 7 * intLvl_a));
		if (intLvl_a < 3) { walk(e, intLvl_a + 1, intS); continue; }
		fs.writeSync(fd, buf, e * 512, 512, intS * 512);
		intN++; if (intS + 1 > intMax) { intMax = intS + 1; }
	}
})(1, 0, 0);
fs.closeSync(fd);
console.log(arrA[1] + ': ' + intN + ' sectors written, the last ' + (intMax - 1) + ' (' + Math.ceil(intMax / 2048) + 'MB in)');
