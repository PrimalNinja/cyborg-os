// test/fake-mpg123.js - stands in for mpg123 -R in test/audio.js: answers LOAD with @P 2 and @F
// lines (a second a line, 10 lines a second here), PAUSE with @P 1 / @P 2, JUMP by moving the
// position, and ends a "track" after 3 seconds with @P 0.   (c) 2026 Cyborg Unicorn Pty Ltd - MIT
'use strict';
var intPos = 0, blnPaused = false, blnLoaded = false, strPart = '';
process.stdout.write('@R MPG123 (fake)\n');
setInterval(function()
{
	if (blnLoaded && !blnPaused)
	{
		intPos += 0.1;
		process.stdout.write('@F ' + Math.floor(intPos * 38) + ' 100 ' + intPos.toFixed(2) + ' 9.00\n');
		if (intPos >= 3) { blnLoaded = false; intPos = 0; process.stdout.write('@P 0\n'); }
	}
}, 100);
process.stdin.on('data', function(b)
{
	var arr = (strPart + b.toString()).split('\n'); strPart = arr.pop();
	arr.forEach(function(l)
	{
		var m;
		if (/^LOAD /.test(l)) { blnLoaded = true; blnPaused = false; intPos = 0; process.stdout.write('@P 2\n'); }
		else if (l === 'PAUSE') { blnPaused = !blnPaused; process.stdout.write(blnPaused ? '@P 1\n' : '@P 2\n'); }
		else if ((m = l.match(/^JUMP ([+-]?)(\d+)s/))) { intPos = m[1] === '+' ? intPos + +m[2] : m[1] === '-' ? Math.max(0, intPos - +m[2]) : +m[2]; }
		else if (l === 'QUIT') { process.exit(0); }
	});
});
