// rguiclick.js <base url> <vdu data folder> <out folder>: rguitest.sh's browser - waits for GUI's
// screen (a folder in vdu's data with GUIDEMO's window in its lines), opens rgui.html on it, takes
// a picture, clicks Feed, types a name in the field (Return), and takes another picture. GUIDEMO's
// answers are looked for in the screen's lines (on the page they last only until its next line:
// the harness runs some 8 times a real CPC's speed), and the gauge's moves (V: GUIDEMO's SetVal). It gives up when the harness has ended (cpc.done). (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const [strBase, strData, strOut] = process.argv.slice(2);

function sleep(intMs_a)
{
	return new Promise(function(fnDone_a) { setTimeout(fnDone_a, intMs_a); });
}

// the screen whose lines have GUIDEMO's window ('' while there is none)
// whether the screen's lines have this in them
function seen(strID_a, strText_a)
{
	return (fs.readFileSync(path.join(strData, strID_a, 'log.txt'), 'latin1').indexOf(strText_a) >= 0);
}

function findScreen()
{
	let strResult = '';
	if (fs.existsSync(strData))
	{
		for (const strD of fs.readdirSync(strData))
		{
			const strLog = path.join(strData, strD, 'log.txt');
			if (fs.existsSync(strLog) && fs.readFileSync(strLog, 'latin1').indexOf('GUIDEMO') >= 0)
			{
				strResult = strD;
			}
		}
	}
	return strResult;
}

(async function()
{
	let strID = '';
	let intI = 0;
	for (intI = 0; intI < 900 && strID === '' && !fs.existsSync(path.join(strOut, 'cpc.done')); intI++)
	{
		await sleep(2000);
		strID = findScreen();
	}
	if (strID === '')
	{
		console.log('no screen with GUIDEMO in it');
	}
	else
	{
		console.log('screen', strID);
		const objB = await chromium.launch();
		const objP = await objB.newPage({ viewport: { width: 1180, height: 760 } });
		objP.on('pageerror', function(objE_a) { console.log('page error:', objE_a.message); });
		await objP.goto(strBase + '/rgui.html?s=' + strID);
		await sleep(3000);
		await objP.screenshot({ path: path.join(strOut, 'rgui1.png') });
		await objP.click('button:has-text("Feed")');
		console.log('clicked Feed');
		let blnFed = false;
		for (intI = 0; intI < 300 && !blnFed && !fs.existsSync(path.join(strOut, 'cpc.done')); intI++)
		{
			await sleep(2000);
			blnFed = seen(strID, 'Fed 1 times');
		}
		console.log(blnFed ? 'GUIDEMO answered: Fed 1 times' : 'no answer to Feed');
		await objP.fill('input[data-field]', 'Rover');
		await objP.press('input[data-field]', 'Enter');
		console.log('typed Rover');
		let blnHello = false;
		for (intI = 0; intI < 150 && !blnHello && !fs.existsSync(path.join(strOut, 'cpc.done')); intI++)
		{
			await sleep(2000);
			blnHello = seen(strID, 'Hello, Rover.');
		}
		console.log(blnHello ? 'GUIDEMO answered: Hello, Rover.' : 'no answer to the name');
		const intGauge = fs.readFileSync(path.join(strData, strID, 'log.txt'), 'latin1').split('\n').filter(function(strL_a) { return strL_a.indexOf('O 4 6 ') === 0; }).length;
		console.log('the gauge sent ' + intGauge + ' times (more than 1: SetVal works)');
		await objP.screenshot({ path: path.join(strOut, 'rgui2.png') });
		await objB.close();
	}
})();
