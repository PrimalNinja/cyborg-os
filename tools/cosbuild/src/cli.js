// CyborgOS Builder from node (no browser): the same build as cosbuild.html, with the same JS -
// NTC's compiler and js/cos_core.js, js/cos_build.js - loaded here, then the command. The project
// is read from the top folder (CyborgOS's: three up from here) each time.
//   node tools/cosbuild/src/cli.js COMMAND ... [--root=TOP] [--layout=PATH]
//   check                  the files the layout names that the folder hasn't got, and the ones nothing uses
//   parts                  the layout's parts, in order
//   run [STAGE]            the layout's parts in order, once: the stage folder (build/stage) and build/
//                          written; it stops at the first part that waits, and says what for
//   build [STAGE]          run, and at an external part with a command (sjasmplus: SJASMPLUS=, or on the
//                          PATH) the command in each of its projects' folders, then on - to the end
//   ntc NTC_SRC            NTC's own components (NTC_SRC: an NTC checkout's src/) into js/, css/, 3p/
//   dsk list X.dsk | dsk get X.dsk NAME [OUT] | dsk make OUT.dsk FILE ... | dsk blank OUT.dsk
//   img OUT.img MB [FOLDER]  a new hard disc image (FAT16 under 64MB, FAT32): the CPC's set from
//                          build/dsk/cos-disk*.dsk in CYBORGOS/, or FOLDER's files under its own name
//   install IMAGE [FOLDER] [/DEST]  into an image that is there (a card, WinAPE's .ide ...): the CPC's
//                          set from build/dsk/ in /CYBORGOS, or FOLDER's files in /DEST (the default /CYBORGOS)
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
var fs = require('fs');
var path = require('path');
var vm = require('vm');

global.window = global;
// the page's JS that isn't the page (cosbuild.html loads the same files)
['js/ntc_lib.js', 'js/ntc_parser.js', 'js/ntc_compiler.js', 'js/ntc_flavour_js.js', 'js/ntc_flavour_php.js', 'js/ntc_flavour_loco.js', 'js/cos_core.js', 'js/cos_build.js'].forEach(function(strF_a)
{
	vm.runInThisContext(fs.readFileSync(path.join(__dirname, strF_a), 'utf8'), { filename: strF_a });
});

// NTC's own components, as they are in an NTC checkout's src/ (the ntc command)
var COS_NTC_FILES = ['3p/jquery-3.7.1.min.js', '3p/bootstrap.min.css', 'css/textEditor.css', 'css/listRenderer.css', 'js/textEditor.js', 'js/listRenderer.js', 'js/ntc_lib.js', 'js/ntc_parser.js', 'js/ntc_compiler.js', 'js/ntc_flavour_js.js', 'js/ntc_flavour_php.js', 'js/ntc_flavour_loco.js'];

// strSrc_a: this folder (src/)
function cosNodeMain(arrArgs_a, strSrc_a)
{
	var objHost_a = { src: strSrc_a };
	var fs = require('fs');
	var path = require('path');
	var cp = require('child_process');
	var strRoot = path.resolve(strSrc_a, '..', '..', '..');
	var strLayout = '';
	var arrA = [];
	var strCmd = '';
	var objProject = null;

	arrArgs_a.forEach(function(strA_a)
	{
		if (strA_a.indexOf('--root=') === 0)
		{
			strRoot = path.resolve(strA_a.substr(7));
		}
		else if (strA_a.indexOf('--layout=') === 0)
		{
			strLayout = strA_a.substr(9);
		}
		else
		{
			arrA.push(strA_a);
		}
	});
	strCmd = arrA.shift() || '';
	strLayout = strLayout || cosNodeLayoutPath(strRoot);
	objProject = (strCmd === 'ntc' || strCmd === 'dsk' || strCmd === 'img' || strCmd === 'install' || strCmd === '') ? { files: {} } : cosNodeFolderProject(strRoot, strLayout);

	function layout()
	{
		if (!strLayout || objProject.files[strLayout] === undefined)
		{
			throw new Error('no layout in the project (*.layout.json) - import first');
		}
		return cosLayoutOf(objProject, strLayout);
	}
	function stageDir()
	{
		return path.resolve(arrA[0] || path.join(strRoot, 'build', 'stage'));
	}
	function write(strBase_a, objFiles_a)
	{
		Object.keys(objFiles_a).forEach(function(strP_a)
		{
			var strFull = path.join(strBase_a, strP_a);
			var v = objFiles_a[strP_a];
			var arrNew = (typeof v === 'string') ? Buffer.from(v, 'latin1') : Buffer.from(v);

			if (fs.existsSync(strFull) && Buffer.compare(fs.readFileSync(strFull), arrNew) === 0)
			{
				return;
			}
			fs.mkdirSync(path.dirname(strFull), { recursive: true });
			fs.writeFileSync(strFull, arrNew);
		});
	}
	function readTree(strBase_a)
	{
		var objResult = {};

		function walk(strDir_a, strRel_a)
		{
			fs.readdirSync(strDir_a).forEach(function(strN_a)
			{
				var strFull = path.join(strDir_a, strN_a);

				if (fs.statSync(strFull).isDirectory())
				{
					walk(strFull, strRel_a + strN_a + '/');
				}
				else
				{
					objResult[strRel_a + strN_a] = new Uint8Array(fs.readFileSync(strFull));
				}
			});
		}
		if (fs.existsSync(strBase_a))
		{
			walk(strBase_a, '');
		}
		return objResult;
	}
	var objCompiled = {};
	function runOnce(blnQuiet_a)
	{
		var objL = layout();
		var objImages = {};
		var objR = null;

		cosParts(objL).forEach(function(objE_a)
		{
			var strB = objE_a.part.base;
			var strP = strB ? path.join(strRoot, 'build', strB) : '';

			if (objE_a.part.type === 'imginstall' && strB && objImages[strB] === undefined && fs.existsSync(strP))
			{
				objImages[strB] = new Uint8Array(fs.readFileSync(strP));
			}
		});
		objR = cosRun({ project: objProject, layout: objL, stage: readTree(stageDir()), images: objImages, compiled: objCompiled });
		write(stageDir(), objR.stage);
		write(path.join(strRoot, 'build'), objR.build);
		if (!blnQuiet_a)
		{
			objR.parts.forEach(function(objP_a)
			{
				if (objP_a.status !== 'todo' && (objP_a.type !== 'ntcproject' || objP_a.status !== 'done'))
				{
					console.log((objP_a.status + '     ').substr(0, 6) + ' ' + objP_a.name + (objP_a.text ? ': ' + objP_a.text : ''));
				}
			});
		}
		return objR;
	}
	function runExternal(objW_a)
	{
		var blnOk = true;
		var strSj = process.env.SJASMPLUS || 'sjasmplus';

		(objW_a.projects || []).forEach(function(objT_a)
		{
			var arrCmd = cosCommandFor(objW_a.part, objT_a).split(/\s+/);
			var strExe = (arrCmd[0] === 'sjasmplus') ? strSj : arrCmd[0];
			var objR = null;

			try { fs.unlinkSync(path.join(stageDir(), objT_a.folder, objT_a.made)); } catch (objError) { /* not there */ }
			objR = cp.spawnSync(strExe, arrCmd.slice(1), { cwd: path.join(stageDir(), objT_a.folder), encoding: 'latin1' });
			if (objR.error)
			{
				console.log(arrCmd[0] + ': ' + objR.error.message);
				blnOk = false;
			}
			else if (objR.status !== 0)
			{
				console.log(objT_a.id + ':\n' + (objR.stdout + objR.stderr).split('\n').slice(0, 6).join('\n'));
				blnOk = false;
			}
		});
		console.log((objW_a.part.name || 'external') + (blnOk ? ': ran' : ': failed'));
		return blnOk;
	}

	try
	{
		switch (strCmd)
		{
			case 'check':
				console.log(cosMissing(objProject, layout()).map(function(s) { return 'missing: ' + s; }).join('\n') || 'nothing missing');
				cosUnused(objProject, layout()).forEach(function(s) { console.log('not used: ' + s); });
				break;
			case 'parts':
				cosParts(layout()).forEach(function(objE_a) { console.log(objE_a.section + ' | ' + objE_a.part.type + ' | ' + objE_a.part.name); });
				break;
			case 'run':
			{
				var objR1 = runOnce(false);

				if (objR1.waiting)
				{
					console.log('WAITING ' + objR1.waiting.part.name + ':\n' + objR1.waiting.text);
				}
				console.log(objR1.done ? 'done' : (objR1.errors.length ? 'stopped: ' + objR1.errors[0] : 'stopped'));
				break;
			}
			case 'build':
			{
				var intN = 0;
				var objR2 = runOnce(true);

				while (!objR2.done && objR2.waiting && objR2.waiting.part.type === 'external' && objR2.waiting.part.command && intN < 10)
				{
					console.log('-- ' + objR2.waiting.part.name);
					if (!runExternal(objR2.waiting))
					{
						break;
					}
					objR2 = runOnce(true);
					intN++;
				}
				objR2.parts.forEach(function(objP_a)
				{
					if (objP_a.type !== 'ntcproject' || objP_a.status !== 'done')
					{
						console.log((objP_a.status + '     ').substr(0, 6) + ' ' + objP_a.name + (objP_a.text ? ': ' + objP_a.text : ''));
					}
				});
				if (objR2.waiting)
				{
					console.log('WAITING ' + objR2.waiting.part.name + ':\n' + objR2.waiting.text);
				}
				console.log(objR2.done ? 'build: done - build/ in ' + strRoot : 'build: stopped' + (objR2.errors.length ? ': ' + objR2.errors[0] : ''));
				if (!objR2.done)
				{
					process.exitCode = 1;
				}
				break;
			}
			case 'ntc':
				cosNodeNtc(objHost_a, path.resolve(arrA[0] || '.'));
				break;
			case 'dsk':
				cosNodeDsk(arrA);
				break;
			case 'img':
				cosNodeImg(arrA, strRoot);
				break;
			case 'install':
				cosNodeInstall(arrA, strRoot);
				break;
			default:
				console.log('CyborgOS Builder ' + COS_VERSION + ': check | parts | run [STAGE] | build [STAGE] | ntc NTC_SRC | dsk ... | img ... | install ... [--root=TOP] [--layout=PATH] (the top folder: ' + strRoot + ')');
		}
	}
	catch (objError)
	{
		console.log('ERR ' + objError.message);
		process.exitCode = 1;
	}
}

// the files the layout's Imports part names, read from the top folder (the layout itself too): { files }

// the layout in the top folder: tools/cosbuild/*.layout.json, the first
function cosNodeLayoutPath(strRoot_a)
{
	var fs = require('fs');
	var path = require('path');
	var strDir = path.join(strRoot_a, 'tools', 'cosbuild');

	return fs.existsSync(strDir) ? (fs.readdirSync(strDir).filter(function(n) { return /\.layout\.json$/i.test(n); }).sort().map(function(n) { return 'tools/cosbuild/' + n; })[0] || '') : '';
}

function cosNodeFolderProject(strRoot_a, strLayout_a)
{
	var fs = require('fs');
	var path = require('path');
	var objLayout = null;
	var objFiles = {};

	if (!strLayout_a || !fs.existsSync(path.join(strRoot_a, strLayout_a)))
	{
		throw new Error('no layout (' + (strLayout_a || 'tools/cosbuild/*.layout.json') + ') in ' + strRoot_a);
	}
	objLayout = JSON.parse(fs.readFileSync(path.join(strRoot_a, strLayout_a), 'utf8'));
	function walk(strRel_a)
	{
		var strF = path.join(strRoot_a, strRel_a);

		if (!fs.existsSync(strF))
		{
			console.log('import ' + strRel_a + ': not there');
			return;
		}
		if (fs.statSync(strF).isDirectory())
		{
			fs.readdirSync(strF).forEach(function(strN_a)
			{
				if (strN_a === 'test' || strN_a === 'screenshots' || strN_a.charAt(0) === '.')
				{
					return;
				}
				walk(strRel_a + '/' + strN_a);
			});
		}
		else if (!COS_SKIP.test(strRel_a))
		{
			objFiles[strRel_a] = fs.readFileSync(strF, 'latin1');
		}
	}
	cosImportsOf(objLayout).forEach(walk);
	objFiles[strLayout_a] = fs.readFileSync(path.join(strRoot_a, strLayout_a), 'latin1');
	cosMissing({ files: objFiles }, objLayout).forEach(function(s) { console.log('missing: ' + s); });

	return { name: objLayout.name || 'project', files: objFiles };
}

// NTC's components from an NTC checkout's src/ into this src/ (js/, css/, 3p/)
function cosNodeNtc(objHost_a, strNtc_a)
{
	var fs = require('fs');
	var path = require('path');
	var intN = 0;

	COS_NTC_FILES.forEach(function(strF_a)
	{
		var strFrom = path.join(strNtc_a, strF_a);

		if (!fs.existsSync(strFrom))
		{
			console.log('ntc: no ' + strFrom + ' (kept as it was)');
			return;
		}
		fs.writeFileSync(path.join(objHost_a.src, strF_a), fs.readFileSync(strFrom));
		intN++;
	});
	console.log('ntc: ' + intN + ' components from ' + strNtc_a);
}

function cosNodeDsk(arrA_a)
{
	var fs = require('fs');
	var path = require('path');
	var strOp = arrA_a[0];
	var arrFiles = null;

	if (strOp === 'list')
	{
		cosDskRead(new Uint8Array(fs.readFileSync(arrA_a[1]))).forEach(function(objF_a)
		{
			var objH = cosAmsdosOf(objF_a.data);

			console.log((objF_a.user ? objF_a.user + ':' : '') + (objF_a.name + '             ').substr(0, 13) + ('      ' + objF_a.data.length).slice(-7) + (objH ? '  AMSDOS #' + cosHex4(objH.load) + ' ' + objH.length : ''));
		});
	}
	else if (strOp === 'get')
	{
		arrFiles = cosDskRead(new Uint8Array(fs.readFileSync(arrA_a[1]))).filter(function(f) { return f.name.toUpperCase() === String(arrA_a[2]).toUpperCase(); });
		if (arrFiles.length === 0)
		{
			console.log('not there');
			return;
		}
		fs.writeFileSync(arrA_a[3] || arrFiles[0].name, Buffer.from(arrFiles[0].data));
	}
	else if (strOp === 'blank')
	{
		fs.writeFileSync(arrA_a[1], Buffer.from(cosDskMake([]).image));
		console.log(arrA_a[1] + ': a blank data format disc');
	}
	else if (strOp === 'make')
	{
		arrFiles = arrA_a.slice(2).map(function(strF_a) { return { name: path.basename(strF_a).toUpperCase(), data: new Uint8Array(fs.readFileSync(strF_a)) }; });
		var objD = cosDskMake(arrFiles);

		fs.writeFileSync(arrA_a[1], Buffer.from(objD.image));
		console.log(arrA_a[1] + ': ' + arrFiles.length + ' files, ' + objD.free + 'K free');
	}
	else
	{
		console.log('dsk list X.dsk | dsk get X.dsk NAME [OUT] | dsk make OUT.dsk FILE ...');
	}
}

// a hard disc image: the CPC's set (the discs' INSTALL.BAS) in CYBORGOS/, or a folder's files
function cosNodeImg(arrA_a, strRoot_a)
{
	var fs = require('fs');
	var path = require('path');
	var arrFiles = [];
	var objR = null;

	if (arrA_a.length < 2)
	{
		console.log('img OUT.img MB [FOLDER]');
		return;
	}
	if (arrA_a[2])
	{
		(function walk(strDir_a, strRel_a)
		{
			fs.readdirSync(strDir_a).forEach(function(strN_a)
			{
				var strFull = path.join(strDir_a, strN_a);

				if (fs.statSync(strFull).isDirectory())
				{
					walk(strFull, strRel_a + strN_a + '/');
				}
				else
				{
					arrFiles.push({ path: strRel_a + strN_a, data: new Uint8Array(fs.readFileSync(strFull)) });
				}
			});
		})(path.resolve(arrA_a[2]), path.basename(path.resolve(arrA_a[2])) + '/');
	}
	else
	{
		arrFiles = cosInstallSet(function(intN_a)
		{
			var strP = path.join(strRoot_a, 'build', 'dsk', 'cos-disk' + intN_a + '.dsk');

			return fs.existsSync(strP) ? new Uint8Array(fs.readFileSync(strP)) : null;
		}, 'CYBORGOS/');
	}
	objR = cosFatImage(parseInt(arrA_a[1], 10), arrFiles);
	fs.writeFileSync(arrA_a[0], Buffer.from(objR.image));
	console.log(arrA_a[0] + ': ' + arrA_a[1] + ' MB, FAT' + objR.fat + ', ' + arrFiles.length + ' files, ' + objR.used + ' of ' + objR.clusters + ' clusters of ' + objR.bytes + ' bytes used');
}

// files into an image that is there: the CPC's set (from build/dsk) or a folder's
function cosNodeInstall(arrA_a, strRoot_a)
{
	var fs = require('fs');
	var path = require('path');
	var arrFiles = [];
	var strDest = '/CYBORGOS';
	var objR = null;

	if (arrA_a.length < 1)
	{
		console.log('install IMAGE [FOLDER] [/DEST]');
		return;
	}
	arrA_a.slice(1).forEach(function(strA_a)
	{
		if (strA_a.charAt(0) === '/')
		{
			strDest = strA_a;
		}
		else
		{
			(function walk(strDir_a, strRel_a)
			{
				fs.readdirSync(strDir_a).forEach(function(strN_a)
				{
					var strFull = path.join(strDir_a, strN_a);

					if (fs.statSync(strFull).isDirectory())
					{
						walk(strFull, strRel_a + strN_a + '/');
					}
					else
					{
						arrFiles.push({ path: strRel_a + strN_a, data: new Uint8Array(fs.readFileSync(strFull)) });
					}
				});
			})(path.resolve(strA_a), '');
		}
	});
	if (arrFiles.length === 0)
	{
		arrFiles = cosInstallSet(function(intN_a)
		{
			var strP = path.join(strRoot_a, 'build', 'dsk', 'cos-disk' + intN_a + '.dsk');

			return fs.existsSync(strP) ? new Uint8Array(fs.readFileSync(strP)) : null;
		}, '');
	}
	objR = cosFatInstall(new Uint8Array(fs.readFileSync(arrA_a[0])), arrFiles, strDest);
	fs.writeFileSync(arrA_a[0], Buffer.from(objR.image));
	console.log(arrA_a[0] + ': ' + objR.files + ' files into ' + strDest + ' (FAT' + objR.fat + (objR.sparse ? ', WinAPE IDE image' : '') + ')');
}

cosNodeMain(process.argv.slice(2), __dirname);
