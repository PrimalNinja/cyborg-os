// CyborgOS Builder - the packager: the project (every source and data file, and cosbuild.txt, the
// recipe), compiled with NTC's own JS (ntc_lib, ntc_parser, ntc_compiler), the assembly files and
// the sjasmplus scripts; then, with what sjasmplus made, the packages: the system drive Z
// (CYBORGOS.Z1 ...: RAMDISC's driver page and the files in its blocks), COSZ.INC and COSCYB.INC,
// INSTALL.BAS's DATA, the CPC's discs (cos-disk1 ...), the Next's boot archive (CYBORGOS.ARC) and
// card folders. And the tools: a .DSK made or read, a FAT hard disc image. ES5: the page and node.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License

var COS_VERSION = '2026.10.22';

// ------------------------------------------------------------
// bytes
// ------------------------------------------------------------

// a string (each character a byte: latin1) as bytes
function cosStrBytes(str_a)
{
	var arrResult = new Uint8Array(str_a.length);
	var intI = 0;

	for (intI = 0; intI < str_a.length; intI++)
	{
		arrResult[intI] = str_a.charCodeAt(intI) & 255;
	}

	return arrResult;
}

function cosBytesStr(arr_a)
{
	var strResult = '';
	var intI = 0;

	for (intI = 0; intI < arr_a.length; intI += 8192)
	{
		strResult += String.fromCharCode.apply(null, Array.prototype.slice.call(arr_a.subarray(intI, Math.min(arr_a.length, intI + 8192))));
	}

	return strResult;
}

function cosConcat(arrParts_a)
{
	var intLength = 0;
	var intAt = 0;
	var arrResult = null;

	arrParts_a.forEach(function(arrPart_a) { intLength += arrPart_a.length; });
	arrResult = new Uint8Array(intLength);
	arrParts_a.forEach(function(arrPart_a)
	{
		arrResult.set(arrPart_a, intAt);
		intAt += arrPart_a.length;
	});

	return arrResult;
}

function cosWord(arr_a, intAt_a)
{
	return arr_a[intAt_a] | (arr_a[intAt_a + 1] << 8);
}

function cosSetWord(arr_a, intAt_a, intValue_a)
{
	arr_a[intAt_a] = intValue_a & 255;
	arr_a[intAt_a + 1] = (intValue_a >> 8) & 255;
}

function cosHex4(intValue_a)
{
	return ('0000' + intValue_a.toString(16).toUpperCase()).slice(-4);
}

var COS_B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function cosB64Enc(arr_a)
{
	var arrOut = [];
	var intI = 0;
	var intV = 0;

	for (intI = 0; intI < arr_a.length; intI += 3)
	{
		intV = (arr_a[intI] << 16) | ((intI + 1 < arr_a.length ? arr_a[intI + 1] : 0) << 8) | (intI + 2 < arr_a.length ? arr_a[intI + 2] : 0);
		arrOut.push(COS_B64.charAt((intV >> 18) & 63) + COS_B64.charAt((intV >> 12) & 63) + (intI + 1 < arr_a.length ? COS_B64.charAt((intV >> 6) & 63) : '=') + (intI + 2 < arr_a.length ? COS_B64.charAt(intV & 63) : '='));
	}

	return arrOut.join('');
}

function cosB64Dec(str_a)
{
	var strClean = str_a.replace(/[^A-Za-z0-9+\/]/g, '');
	var arrResult = new Uint8Array(Math.floor(strClean.length * 3 / 4));
	var intI = 0;
	var intO = 0;
	var intV = 0;

	for (intI = 0; intI < strClean.length; intI += 4)
	{
		intV = (COS_B64.indexOf(strClean.charAt(intI)) << 18) | (COS_B64.indexOf(strClean.charAt(intI + 1)) << 12) | ((COS_B64.indexOf(strClean.charAt(intI + 2)) & 63) << 6) | (COS_B64.indexOf(strClean.charAt(intI + 3)) & 63);
		if (intO < arrResult.length) { arrResult[intO++] = (intV >> 16) & 255; }
		if (intO < arrResult.length) { arrResult[intO++] = (intV >> 8) & 255; }
		if (intO < arrResult.length) { arrResult[intO++] = intV & 255; }
	}

	return arrResult;
}

// ------------------------------------------------------------
// AMSDOS
// ------------------------------------------------------------

// the 128 byte header AMSDOS writes for a binary file (sjasmplus's SAVEAMSDOS: the same)
function cosAmsdosHeader(arrData_a, intLoad_a, intType_a)
{
	var arrH = new Uint8Array(128);
	var intN = arrData_a.length;
	var intSum = 0;
	var intI = 0;

	arrH[18] = (intType_a === undefined) ? 2 : intType_a;
	cosSetWord(arrH, 21, intLoad_a);
	cosSetWord(arrH, 24, intN);
	cosSetWord(arrH, 26, intLoad_a);
	arrH[64] = intN & 255;
	arrH[65] = (intN >> 8) & 255;
	arrH[66] = (intN >> 16) & 255;
	for (intI = 0; intI < 67; intI++)
	{
		intSum += arrH[intI];
	}
	cosSetWord(arrH, 67, intSum & 0xFFFF);

	return arrH;
}

// { load, length } when the bytes start with a valid AMSDOS header, else null
function cosAmsdosOf(arr_a)
{
	var intSum = 0;
	var intI = 0;

	if (arr_a.length < 128)
	{
		return null;
	}
	for (intI = 0; intI < 67; intI++)
	{
		intSum += arr_a[intI];
	}
	if ((intSum & 0xFFFF) !== cosWord(arr_a, 67) || (intSum === 0))
	{
		return null;
	}

	return { load: cosWord(arr_a, 21), length: cosWord(arr_a, 24), type: arr_a[18] };
}

// an 8.3 name as CP/M's 11 bytes (capitals, spaces)
function cosName83(strName_a)
{
	var arrParts = strName_a.toUpperCase().split('.');
	var strBase = (arrParts[0] + '        ').substr(0, 8);
	var strExt = ((arrParts[1] || '') + '   ').substr(0, 3);

	return cosStrBytes(strBase + strExt);
}

// ------------------------------------------------------------
// .DSK - the CPC's data format: 40 tracks, 9 sectors of 512 (#C1-#C9, interleaved), 1K blocks,
// 64 directory entries (blocks 0 and 1), 178K for files. Standard CPCEMU .DSK
// ------------------------------------------------------------

var COS_DSK_BLOCKS = 180;
var COS_DSK_DIRS = 64;

// files [{ name: 'NAME.EXT', data, user }] on a new disc: { image, free (K), entries } - throws
// when they don't fit
function cosDskMake(arrFiles_a, strFormat_a)
{
	var blnSystem = (strFormat_a === 'system');
	var intBase = blnSystem ? 0x41 : 0xC1;
	var intOff = blnSystem ? 2 : 0;
	var arrImg = new Uint8Array(40 * 9 * 512);
	var arrDir = new Uint8Array(2048);
	var intNb = 2;
	var intE = 0;
	var intBlocks = blnSystem ? (38 * 9 * 512 / 1024) : COS_DSK_BLOCKS;
	var arrOrder = [0, 5, 1, 6, 2, 7, 3, 8, 4];
	var arrHead = new Uint8Array(256);
	var arrOut = [];
	var intT = 0;
	var intS = 0;

	arrImg.fill(0xE5);
	arrDir.fill(0xE5);
	arrFiles_a.forEach(function(objFile_a)
	{
		var arrName = cosName83(objFile_a.name);
		var intPad = (128 - (objFile_a.data.length % 128)) % 128;
		var arrData = cosConcat([objFile_a.data, new Uint8Array(intPad)]);
		var intRecs = arrData.length / 128;
		var intExtents = Math.max(1, Math.ceil(intRecs / 128));
		var intX = 0;
		var intJ = 0;
		var arrPart = null;
		var arrEnt = null;
		var intO = 0;

		for (intX = 0; intX < intExtents; intX++)
		{
			arrPart = arrData.subarray(intX * 16384, (intX + 1) * 16384);
			if (intE >= COS_DSK_DIRS)
			{
				throw new Error('the directory is full (' + COS_DSK_DIRS + ' entries) at ' + objFile_a.name);
			}
			arrEnt = new Uint8Array(32);
			arrEnt[0] = objFile_a.user || 0;
			arrEnt.set(arrName, 1);
			arrEnt[12] = intX & 31;
			arrEnt[14] = intX >> 5;
			arrEnt[15] = Math.min(128, arrPart.length / 128);
			for (intJ = 0; intJ < Math.ceil(arrPart.length / 1024); intJ++)
			{
				if (intNb >= intBlocks)
				{
					throw new Error('the disc is full at ' + objFile_a.name);
				}
				arrEnt[16 + intJ] = intNb;
				intO = intOff * 9 * 512 + intNb * 1024;
				arrImg.set(arrPart.subarray(intJ * 1024, (intJ + 1) * 1024), intO);
				intNb++;
			}
			arrDir.set(arrEnt, intE * 32);
			intE++;
		}
	});
	arrImg.set(arrDir, intOff * 9 * 512);
	arrHead.set(cosStrBytes('MV - CPCEMU Disk-File\r\nDisk-Info\r\n'), 0);
	arrHead[0x30] = 40;
	arrHead[0x31] = 1;
	cosSetWord(arrHead, 0x32, 0x100 + 9 * 512);
	arrOut.push(arrHead);
	for (intT = 0; intT < 40; intT++)
	{
		var arrTi = new Uint8Array(256);

		arrTi.set(cosStrBytes('Track-Info\r\n'), 0);
		arrTi[0x10] = intT;
		arrTi[0x14] = 2;
		arrTi[0x15] = 9;
		arrTi[0x16] = 0x52;
		arrTi[0x17] = 0xE5;
		for (intS = 0; intS < 9; intS++)
		{
			arrTi.set([intT, 0, intBase + arrOrder[intS], 2, 0, 0, 0, 0], 0x18 + intS * 8);
		}
		arrOut.push(arrTi);
		for (intS = 0; intS < 9; intS++)
		{
			arrOut.push(arrImg.subarray((intT * 9 + arrOrder[intS]) * 512, (intT * 9 + arrOrder[intS] + 1) * 512));
		}
	}

	return { image: cosConcat(arrOut), free: intBlocks - intNb, entries: intE };
}

// a .DSK's files (standard or extended; data or system format, as its sector IDs say):
// [{ name, user, data }] - the data as CP/M has it (whole records)
function cosDskRead(arrDsk_a)
{
	var blnExt = cosBytesStr(arrDsk_a.subarray(0, 8)) === 'EXTENDED';
	var intTracks = arrDsk_a[0x30];
	var intSides = arrDsk_a[0x31];
	var intO = 0x100;
	var objSecs = {};
	var intT = 0;
	var intSize = 0;
	var intN = 0;
	var intQ = 0;
	var intS = 0;
	var intLen = 0;
	var intMin = 255;
	var intOff = 0;
	var arrDir = [];
	var objFiles = {};
	var arrResult = [];

	for (intT = 0; intT < intTracks * intSides; intT++)
	{
		intSize = blnExt ? arrDsk_a[0x34 + intT] * 256 : cosWord(arrDsk_a, 0x32);
		if (intSize === 0)
		{
			continue;
		}
		intN = arrDsk_a[intO + 0x15];
		intQ = intO + 0x100;
		for (intS = 0; intS < intN; intS++)
		{
			intLen = blnExt ? cosWord(arrDsk_a, intO + 0x18 + intS * 8 + 6) : (128 << arrDsk_a[intO + 0x14]);
			objSecs[arrDsk_a[intO + 0x10] + ':' + arrDsk_a[intO + 0x18 + intS * 8 + 2]] = arrDsk_a.subarray(intQ, intQ + intLen);
			intMin = Math.min(intMin, arrDsk_a[intO + 0x18 + intS * 8 + 2]);
			intQ += intLen;
		}
		intO += intSize;
	}
	intOff = ((intMin & 0xC0) === 0x40) ? 2 : 0;
	intMin = intMin & 0xC0 | 1;
	function sector(intLs_a)
	{
		return objSecs[(intOff + Math.floor(intLs_a / 9)) + ':' + (intMin + intLs_a % 9)] || new Uint8Array(512);
	}
	for (intS = 0; intS < 4; intS++)
	{
		arrDir.push(sector(intS));
	}
	arrDir = cosConcat(arrDir);
	for (intS = 0; intS < 64; intS++)
	{
		var arrE = arrDir.subarray(intS * 32, intS * 32 + 32);
		var strName = '';
		var strExt = '';
		var strKey = '';
		var intJ = 0;
		var arrData = [];

		if (arrE[0] === 0xE5 || arrE[0] > 15)
		{
			continue;
		}
		strName = cosBytesStr(arrE.subarray(1, 9).map(function(intB_a) { return intB_a & 127; })).replace(/\s+$/, '');
		strExt = cosBytesStr(arrE.subarray(9, 12).map(function(intB_a) { return intB_a & 127; })).replace(/\s+$/, '');
		strKey = arrE[0] + ':' + strName + (strExt ? '.' + strExt : '');
		for (intJ = 16; intJ < 32; intJ++)
		{
			if (arrE[intJ] !== 0)
			{
				arrData.push(sector(arrE[intJ] * 2), sector(arrE[intJ] * 2 + 1));
			}
		}
		objFiles[strKey] = objFiles[strKey] || { name: strName + (strExt ? '.' + strExt : ''), user: arrE[0], parts: [] };
		objFiles[strKey].parts.push({ ex: arrE[12] + arrE[14] * 32, data: cosConcat(arrData).subarray(0, arrE[15] * 128) });
	}
	Object.keys(objFiles).forEach(function(strKey_a)
	{
		var objF = objFiles[strKey_a];

		objF.parts.sort(function(a, b) { return a.ex - b.ex; });
		arrResult.push({ name: objF.name, user: objF.user, data: cosConcat(objF.parts.map(function(p) { return p.data; })) });
	});

	return arrResult;
}

// a file's own length: the AMSDOS header's (and the header), else to its first ^Z (ASCII), else all
function cosFileTrim(arr_a)
{
	var objH = cosAmsdosOf(arr_a);
	var intI = 0;

	if (objH !== null)
	{
		return arr_a.subarray(0, Math.min(arr_a.length, 128 + objH.length));
	}
	for (intI = 0; intI < arr_a.length; intI++)
	{
		if (arr_a[intI] === 0x1A)
		{
			return arr_a.subarray(0, intI);
		}
	}

	return arr_a;
}

// ------------------------------------------------------------
// sjasmplus's .sym: { label (lower case): value }
// ------------------------------------------------------------

function cosSym(str_a)
{
	var objResult = {};

	str_a.split(/\r?\n/).forEach(function(strLine_a)
	{
		var arrM = strLine_a.match(/^(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)/);

		if (arrM)
		{
			objResult['=' + arrM[1]] = parseInt(arrM[2], 16);		// (as it is: COSZ_FILES and cosz_files differ)
			if ((objResult[arrM[1].toLowerCase()] === undefined) || (arrM[1] === arrM[1].toLowerCase()))
			{
				objResult[arrM[1].toLowerCase()] = parseInt(arrM[2], 16);	// (a name in small letters wins:
			}															// ntc_fwblk the variable, NTC_FWBLK a constant)
		}
	});

	return objResult;
}

// a label in a .sym, also when NTC has given it its asm block's prefix (asm_0_226_n_dr_img)
function cosSymFind(objSym_a, strName_a)
{
	var strKey = '';
	var strLow = strName_a.toLowerCase();

	if (objSym_a[strLow] !== undefined)
	{
		return objSym_a[strLow];
	}
	for (strKey in objSym_a)
	{
		if (objSym_a.hasOwnProperty(strKey) && (strKey.length > strLow.length) && (strKey.substr(strKey.length - strLow.length - 1) === '_' + strLow))
		{
			return objSym_a[strKey];
		}
	}

	return undefined;
}

// ------------------------------------------------------------
// a project compiled (NTC: ntcCompile, loaded beside this)
// ------------------------------------------------------------

// a target compiled: { asm, errors: [text], warnings: [text], ms }
function cosCompile(objProject_a, objTarget_a)
{
	var arrFiles = [];
	var objOpts = { platform: objTarget_a.platform, sourcecomments: false };
	var objR = null;
	var intStart = Date.now();
	var arrErr = [];

	if (objTarget_a.platform === 'asm')
	{
		return { asm: objProject_a.files[objTarget_a.src[0]] || '', errors: (objProject_a.files[objTarget_a.src[0]] === undefined) ? ['no ' + objTarget_a.src[0]] : [], warnings: [], ms: 0 };
	}
	objTarget_a.src.forEach(function(strS_a)
	{
		if (objProject_a.files[strS_a] === undefined)
		{
			arrErr.push('no ' + strS_a + ' in the project');
		}
		else
		{
			arrFiles.push({ name: strS_a.replace(/^.*\//, ''), text: objProject_a.files[strS_a] });
		}
	});
	if (arrErr.length > 0)
	{
		return { asm: '', errors: arrErr, warnings: [], ms: 0 };
	}
	if (objTarget_a.platform === 'cyborgos')
	{
		objOpts.name = objTarget_a.name;
	}
	else if (/^cpc/.test(objTarget_a.platform))
	{
		objOpts.amsdos = objTarget_a.name;
	}
	if (objTarget_a.org)
	{
		objOpts.org = objTarget_a.org;
	}
	if (objTarget_a.library)
	{
		objOpts.library = objTarget_a.library;
	}
	if (Object.keys(objTarget_a.consts).length > 0)
	{
		objOpts.consts = {};
		Object.keys(objTarget_a.consts).forEach(function(strK_a)
		{
			var v = objTarget_a.consts[strK_a];

			objOpts.consts[strK_a] = (typeof v === 'string' && !isNaN(v)) ? Number(v) : v;
		});
	}
	try
	{
		objR = ntcCompile(arrFiles, objOpts);
	}
	catch (objError)
	{
		return { asm: '', errors: ['the compiler stopped: ' + objError.message], warnings: [], ms: Date.now() - intStart };
	}

	return {
		asm: objR.asm || '',
		errors: (objR.errors || []).map(function(e) { return (e.file || '') + ':' + e.line + ': ' + e.msg; }),
		warnings: (objR.warnings || []).map(function(e) { return (e.file || '') + ':' + e.line + ': ' + e.msg; }),
		ms: Date.now() - intStart
	};
}

function cosAsmName(objTarget_a)
{
	return (objTarget_a.platform === 'asm') ? objTarget_a.src[0].replace(/^.*\//, '') : objTarget_a.name + '.ASM';
}

// ------------------------------------------------------------
// the system drive Z, packed: RAMDISC's driver page (its code at #4000, its tables) and the files
// CYBORGOS.Z names in its 2K blocks - as RAMDISC Z SYSTEM leaves it (cmds/RAMDISC.bas: Driver
// and SysDrive), 32K (two 16K pages) a file: CYBORGOS.Z1 (the driver page first), Z2 ...
// COSLOAD.BIN loads them and gives D_POOL each data page's page and RAM setting
// ------------------------------------------------------------

var COS_D_POOL = 0x1400;		// (in the page: #5400 - #4000)
var COS_D_FAT = 0x1A00;
var COS_D_VOL = 0x2A00;
var COS_D_DIR = 0x2C00;
var COS_D_SIG = 0x3F00;

// arrFiles_a [{ name: 'HELP.CYB', data }], arrDriver_a the driver (#4000 on); intMaxPages_a the
// pages at most (driver page and data): { files: [{ name, data }], inc, pages, claim, commands,
// kb, skipped: [text] }
function cosZPack(arrFiles_a, arrDriver_a, intMaxPages_a)
{
	var arrDrv = new Uint8Array(0x4000);
	var arrData = [];			// the data pages (D_POOL slot k: blocks 8k .. 8k+7)
	var intFree = 0;			// fr: the blocks counted free (7 a page)
	var intNextBlock = 1;			// block 0 is never used
	var intEntries = 0;
	var intCommands = 0;
	var intKb = 0;
	var arrSkipped = [];
	var arrPages = [];
	var arrOut = [];
	var arrInc = [];
	var intFp = 0;
	var intUsed = 0;
	var intI = 0;
	var intSum = 0;

	if (arrDriver_a.length > COS_D_POOL)
	{
		throw new Error('the RAM disc driver is ' + arrDriver_a.length + ' bytes: more than #1400');
	}
	arrDrv.set(arrDriver_a, 0);
	cosSetWord(arrDrv, COS_D_FAT, 0xFFFF);			// block 0: never used
	arrDrv[COS_D_VOL] = 0x5A;				// Z (RAM disc 0)

	function addPage()
	{
		var intSlot = arrData.length;
		var intVol = COS_D_VOL;

		if (1 + arrData.length >= intMaxPages_a)
		{
			return false;
		}
		arrData.push(new Uint8Array(0x4000));
		arrDrv[COS_D_POOL + intSlot * 6] = 1;		// owner: RAM disc 0 + 1
		cosSetWord(arrDrv, intVol + 2, cosWord(arrDrv, intVol + 2) + 8);
		cosSetWord(arrDrv, intVol + 4, cosWord(arrDrv, intVol + 4) + ((intSlot === 0) ? 7 : 8));

		return true;
	}

	arrFiles_a.forEach(function(objF_a)
	{
		var objH = cosAmsdosOf(objF_a.data);
		var arrFile = (objH !== null) ? objF_a.data.subarray(128, 128 + objH.length) : objF_a.data;	// (FileSystem.Load: the file without its AMSDOS header - CyborgOS's loader takes it either way)
		var intR = arrFile.length;
		var intRecPad = (128 - (intR % 128)) % 128;
		var intNb = Math.ceil(intR / 2048);
		var intRecs = Math.ceil(intR / 128);
		var intEnt = COS_D_DIR + intEntries * 20;
		var intFirst = 0;
		var intPrev = 0;
		var intB = 0;
		var intBlock = 0;
		var arrBlock = null;

		if (arrSkipped.length > 0 && arrSkipped[arrSkipped.length - 1].indexOf('no room') >= 0)
		{
			return;					// (RAMDISC stops at the first that doesn't fit)
		}
		if (intR > 32640)
		{
			arrSkipped.push(objF_a.name + ' is over 32K - not copied');
			return;
		}
		while (intFree < intNb)
		{
			if (!addPage())
			{
				arrSkipped.push('no room for ' + objF_a.name + ' (the rest from the disc)');
				return;
			}
			intFree += 7;
		}
		for (intB = 0; intB < intNb; intB++)
		{
			intBlock = intNextBlock++;
			if (intB === 0)
			{
				intFirst = intBlock;
			}
			else
			{
				cosSetWord(arrDrv, COS_D_FAT + intPrev * 2, intBlock);
			}
			cosSetWord(arrDrv, COS_D_FAT + intBlock * 2, 0xFFFF);
			arrBlock = arrFile.subarray(intB * 2048, Math.min(intR, (intB + 1) * 2048));
			arrData[intBlock >> 3].set(arrBlock, (intBlock & 7) * 2048);
			if (intB === intNb - 1 && intRecPad > 0)
			{
				arrData[intBlock >> 3].fill(0x1A, (intBlock & 7) * 2048 + arrBlock.length, (intBlock & 7) * 2048 + arrBlock.length + intRecPad);	// (the last record's rest: ^Z, as the file's)
			}
			intPrev = intBlock;
		}
		cosSetWord(arrDrv, COS_D_VOL + 4, cosWord(arrDrv, COS_D_VOL + 4) - intNb);
		arrDrv[intEnt] = 1;
		arrDrv.set(cosName83(objF_a.name.replace(/^.*\//, '')), intEnt + 1);
		cosSetWord(arrDrv, intEnt + 14, intFirst);
		cosSetWord(arrDrv, intEnt + 16, intRecs);
		intEntries++;
		intFree -= intNb;
		if (/\.CYB$/i.test(objF_a.name))
		{
			intCommands++;
		}
	});
	// the signature: "CYBD", #5A #CB, the sum of D_POOL (COSLOAD writes the pages in, then the sum)
	for (intI = 0; intI < 1536; intI++)
	{
		intSum = (intSum + arrDrv[COS_D_POOL + intI]) & 0xFFFF;
	}
	arrDrv.set(cosStrBytes('CYBD'), COS_D_SIG);
	arrDrv[COS_D_SIG + 4] = 0x5A;
	arrDrv[COS_D_SIG + 5] = 0xCB;
	cosSetWord(arrDrv, COS_D_SIG + 6, intSum);
	intKb = cosWord(arrDrv, COS_D_VOL + 2) * 2;
	// the data pages up to the last one in use (packz: the ones after it aren't written)
	intUsed = Math.ceil(intNextBlock / 8);
	arrPages = [arrDrv].concat(arrData.slice(0, intUsed));
	for (intI = 0; intI < arrPages.length; intI += 2)
	{
		var arrD = cosConcat(arrPages.slice(intI, intI + 2));

		arrOut.push({ name: 'CYBORGOS.Z' + (intI / 2 + 1), data: cosConcat([cosAmsdosHeader(arrD, 0x1000), arrD]), pages: Math.min(2, arrPages.length - intI) });
	}
	arrInc.push('; COSZ.INC - made by CyborgOS Builder: the system drive Z ready-made (' + intCommands + ' commands, ' + intKb + 'K)');
	arrInc.push('COSZ_FILES  equ ' + arrOut.length);
	arrInc.push('COSZ_PAGES  equ ' + arrPages.length + '                  ; the pages in the files');
	arrInc.push('COSZ_CLAIM  equ ' + (1 + arrData.length) + '                  ; the pages Z keeps (D_POOL\'s slots + the driver page)');
	arrInc.push('COSZ_ENT    equ 16                  ; an entry: its first page (0 the driver page), its pages, the name\'s length, the name (0s after it)');
	arrInc.push('cosz_files:');
	arrOut.forEach(function(objF_a)
	{
		arrInc.push('            db ' + intFp + ', ' + objF_a.pages + ', ' + objF_a.name.length + ', "' + objF_a.name + '"\n            ds ' + (13 - objF_a.name.length));
		intFp += objF_a.pages;
	});
	arrInc.push('cosz_last   equ cosz_files + (COSZ_FILES - 1) * COSZ_ENT');

	return { files: arrOut, inc: arrInc.join('\n') + '\n', pages: arrPages.length, claim: 1 + arrData.length, commands: intCommands, kb: intKb, entries: intEntries, skipped: arrSkipped };
}

// COSCYB.INC from CYBORGOS.BIN's .sym (the CYBORGOS.BIN COSLOAD starts)
function cosCybInc(objSym_a)
{
	var arrOut = ['; COSCYB.INC - made by CyborgOS Builder from CYBORGOS.BIN\'s .sym: the CYBORGOS.BIN COSLOAD.BIN starts'];
	var intEnd = Math.max(objSym_a.ntc_end || 0, objSym_a.ntc_fileend || 0);

	// (the variables by their exact names: the .sym also has NTC_FWBLK, a constant - #A5F0 - which
	// COSLOAD once wrote the ROMs' RAM top into, in the middle of the ROMs' own RAM)
	[['CYB_END', intEnd], ['CYB_FREE', objSym_a['=ntc_free']], ['CYB_FWBLK', objSym_a['=ntc_fwblk']], ['CYB_FWTOP', objSym_a['=ntc_fwtop']]].forEach(function(arrP_a)
	{
		if (arrP_a[1] === undefined || arrP_a[1] === 0)
		{
			throw new Error('CYBORGOS.BIN\'s .sym has no ' + arrP_a[0]);
		}
		arrOut.push((arrP_a[0] + '           ').substr(0, 11) + ' equ #' + cosHex4(arrP_a[1]));
	});
	if (objSym_a.ntc_hiph !== undefined)
	{
		arrOut.push('CYB_HIGH    equ 1           ; Option HighCode (the flat build: code in #C000-#FFFF) - COSLOAD saves as COSLOADF.BIN');
	}
	if (!(objSym_a['=ntc_fwblk'] < objSym_a['=ntc_free']) || !(objSym_a['=ntc_fwtop'] < objSym_a['=ntc_free']))
	{
		throw new Error('COSCYB.INC: ntc_fwblk / ntc_fwtop must be variables in CYBORGOS.BIN (below its free RAM)');
	}
	if (objSym_a.ntc_start !== 0x40)
	{
		throw new Error('CYBORGOS.BIN is not at #0040');
	}

	return arrOut.join('\n') + '\n';
}

// the values an .INC sets: { NAME: value }
function cosIncValues(str_a)
{
	var objResult = {};

	str_a.split(/\n/).forEach(function(strL_a)
	{
		var arrM = strL_a.match(/^(\w+)\s+equ\s+(#[0-9A-Fa-f]+|\d+)\s*(;.*)?$/);

		if (arrM)
		{
			objResult['=' + arrM[1]] = (arrM[2].charAt(0) === '#') ? parseInt(arrM[2].substr(1), 16) : parseInt(arrM[2], 10);
		}
	});

	return objResult;
}

// ------------------------------------------------------------
// the Next's boot archive (tools/nexarc/nexarc.py's layout): "CARC", the count, 0s to 16; 16-byte
// entries (8 + 3 name, length 3 bytes, first record 2 bytes); the files from record boundaries
// (128), padded with #1A; the whole padded with #1A to blocks x 16K
// ------------------------------------------------------------

function cosArc(arrFiles_a, intBlocks_a)
{
	var intDrec = Math.ceil((16 + 16 * arrFiles_a.length) / 128);
	var arrDir = new Uint8Array(intDrec * 128);
	var arrData = [];
	var intRec = intDrec;
	var arrImg = null;
	var arrOut = null;

	arrDir.fill(0x1A);
	arrDir.fill(0, 0, 16 + 16 * arrFiles_a.length);
	arrDir.set(cosStrBytes('CARC'), 0);
	cosSetWord(arrDir, 4, arrFiles_a.length);
	arrFiles_a.forEach(function(objF_a, intI_a)
	{
		var intE = 16 + intI_a * 16;
		var intPad = (128 - (objF_a.data.length % 128)) % 128;
		var arrPad = new Uint8Array(intPad);

		arrDir.set(cosName83(objF_a.name), intE);
		arrDir[intE + 11] = objF_a.data.length & 255;
		arrDir[intE + 12] = (objF_a.data.length >> 8) & 255;
		arrDir[intE + 13] = (objF_a.data.length >> 16) & 255;
		cosSetWord(arrDir, intE + 14, intRec);
		arrPad.fill(0x1A);
		arrData.push(objF_a.data, arrPad);
		intRec += (objF_a.data.length + intPad) / 128;
	});
	arrImg = cosConcat([arrDir].concat(arrData));
	if (arrImg.length > intBlocks_a * 16384)
	{
		throw new Error('the archive is ' + arrImg.length + ' bytes: more than ' + intBlocks_a + ' blocks of 16K');
	}
	arrOut = new Uint8Array(intBlocks_a * 16384);
	arrOut.fill(0x1A);
	arrOut.set(arrImg, 0);

	return { data: arrOut, used: arrImg.length };
}

// /NEXTZXOS/AUTOEXEC.BAS: a one-line NextBASIC program (line 10: the command), a +3DOS file
function cosAutoexec(strCmd_a)
{
	var arrBody = cosStrBytes(strCmd_a + '\r');
	var arrProg = new Uint8Array(4 + arrBody.length);
	var arrHdr = new Uint8Array(128);
	var intSum = 0;
	var intI = 0;
	var intTotal = 128 + arrProg.length;

	arrProg[0] = 0;
	arrProg[1] = 10;
	cosSetWord(arrProg, 2, arrBody.length);
	arrProg.set(arrBody, 4);
	arrHdr.set(cosStrBytes('PLUS3DOS'), 0);
	arrHdr[8] = 0x1A;
	arrHdr[9] = 1;
	arrHdr[11] = intTotal & 255;
	arrHdr[12] = (intTotal >> 8) & 255;
	cosSetWord(arrHdr, 16, arrProg.length);
	cosSetWord(arrHdr, 18, 10);
	cosSetWord(arrHdr, 20, arrProg.length);
	for (intI = 0; intI < 127; intI++)
	{
		intSum += arrHdr[intI];
	}
	arrHdr[127] = intSum & 255;

	return cosConcat([arrHdr, arrProg]);
}

// ------------------------------------------------------------
// INSTALL.BAS: the program to line 1000, then its DATA - how many files, "#n" (disc n) and the
// files as they go in CYBORGOS/ (4 a line), "*" at the end. CR LF lines, ^Z after
// ------------------------------------------------------------

function cosInstallBas(strInstall_a, arrDiscs_a)
{
	var arrLines = strInstall_a.replace(/\x1a[\s\S]*$/, '').split(/\r?\n/);
	var arrHead = [];
	var arrItems = [];
	var intCount = 0;
	var intNo = 1010;
	var arrOut = [];
	var intI = 0;

	for (intI = 0; intI < arrLines.length; intI++)
	{
		if (/^\s*(\d+)/.test(arrLines[intI]) && parseInt(arrLines[intI], 10) >= 1000)
		{
			break;
		}
		if (arrLines[intI].length > 0)
		{
			arrHead.push(arrLines[intI]);
		}
	}
	arrDiscs_a.forEach(function(objD_a)
	{
		arrItems.push('#' + objD_a.n);
		objD_a.files.forEach(function(strDest_a)
		{
			arrItems.push(strDest_a);
			intCount++;
		});
	});
	arrOut = arrHead.slice(0);
	arrOut.push('1000 DATA ' + intCount);
	for (intI = 0; intI < arrItems.length; intI += 4)
	{
		arrOut.push(intNo + ' DATA ' + arrItems.slice(intI, intI + 4).map(function(s) { return '"' + s + '"'; }).join(','));
		intNo += 10;
	}
	if (intNo > 5000)
	{
		throw new Error('INSTALL.BAS: its DATA reaches line ' + intNo + ' (5000 is the end mark)');
	}
	arrOut.push('5000 DATA "*"');
	arrOut.forEach(function(strL_a)
	{
		if (strL_a.length > 120)
		{
			throw new Error('INSTALL.BAS: a line over 120 characters: ' + strL_a.substr(0, 40));
		}
	});

	return arrOut.join('\r\n') + '\r\n\x1a';
}

function cosIndexOf(arrHay_a, arrNeedle_a)
{
	var intI = 0;
	var intJ = 0;

	for (intI = 0; intI + arrNeedle_a.length <= arrHay_a.length; intI++)
	{
		for (intJ = 0; intJ < arrNeedle_a.length; intJ++)
		{
			if (arrHay_a[intI + intJ] !== arrNeedle_a[intJ])
			{
				break;
			}
		}
		if (intJ === arrNeedle_a.length)
		{
			return intI;
		}
	}

	return -1;
}

// ------------------------------------------------------------
// a .ZIP (stored, no compression): { path: bytes or text } - for a browser's one download
// ------------------------------------------------------------

var COS_CRC = null;

function cosCrc32(arr_a)
{
	var intC = 0;
	var intI = 0;
	var intK = 0;

	if (COS_CRC === null)
	{
		COS_CRC = new Uint32Array(256);
		for (intI = 0; intI < 256; intI++)
		{
			intC = intI;
			for (intK = 0; intK < 8; intK++)
			{
				intC = (intC & 1) ? (0xEDB88320 ^ (intC >>> 1)) : (intC >>> 1);
			}
			COS_CRC[intI] = intC >>> 0;
		}
	}
	intC = 0xFFFFFFFF;
	for (intI = 0; intI < arr_a.length; intI++)
	{
		intC = COS_CRC[(intC ^ arr_a[intI]) & 255] ^ (intC >>> 8);
	}

	return (intC ^ 0xFFFFFFFF) >>> 0;
}

function cosZip(objFiles_a)
{
	var arrParts = [];
	var arrCentral = [];
	var intAt = 0;
	var intCount = 0;

	function le(intV_a, intN_a)
	{
		var arr = new Uint8Array(intN_a);
		var intI = 0;

		for (intI = 0; intI < intN_a; intI++)
		{
			arr[intI] = (intV_a >>> (8 * intI)) & 255;
		}
		return arr;
	}
	Object.keys(objFiles_a).sort().forEach(function(strPath_a)
	{
		var arrData = (typeof objFiles_a[strPath_a] === 'string') ? cosStrBytes(objFiles_a[strPath_a]) : objFiles_a[strPath_a];
		var arrName = cosStrBytes(strPath_a);
		var intCrc = cosCrc32(arrData);
		var arrLocal = cosConcat([le(0x04034b50, 4), le(10, 2), le(0, 2), le(0, 2), le(0, 2), le(0x21, 2), le(intCrc, 4), le(arrData.length, 4), le(arrData.length, 4), le(arrName.length, 2), le(0, 2), arrName]);

		arrCentral.push(cosConcat([le(0x02014b50, 4), le(20, 2), le(10, 2), le(0, 2), le(0, 2), le(0, 2), le(0x21, 2), le(intCrc, 4), le(arrData.length, 4), le(arrData.length, 4), le(arrName.length, 2), le(0, 2), le(0, 2), le(0, 2), le(0, 2), le(0, 4), le(intAt, 4), arrName]));
		arrParts.push(arrLocal, arrData);
		intAt += arrLocal.length + arrData.length;
		intCount++;
	});
	arrCentral = cosConcat(arrCentral);

	return cosConcat(arrParts.concat([arrCentral, cosConcat([le(0x06054b50, 4), le(0, 2), le(0, 2), le(intCount, 2), le(intCount, 2), le(arrCentral.length, 4), le(intAt, 4), le(0, 2)])]));
}

// ------------------------------------------------------------
// a hard disc image (tools/cpcimg's layout: WinAPE's IDE drive, UniDOS's IDE node, a CF card or a
// Next's card written with dd): an MBR, one FAT16 (under 64MB) or FAT32 partition at sector 2048,
// 8.3 names; the files [{ path: 'CYBORGOS/C/HELP.CYB', data }] in it, folders made as needed
// ------------------------------------------------------------

function cosFatImage(intMb_a, arrFiles_a)
{
	var SEC = 512;
	var PART = 2048;
	var intTotal = intMb_a * 2048;
	var intTotSec = intTotal - PART;
	var blnFat32 = intMb_a >= 64;
	var intBytes = blnFat32 ? (intMb_a <= 260 ? 512 : 4096) : (intMb_a < 16 ? 512 : 2048);
	var intSpc = intBytes / SEC;
	var intRsvd = blnFat32 ? 32 : 4;
	var intRootEnts = blnFat32 ? 0 : 512;
	var intRootSecs = intRootEnts * 32 / SEC;
	var intEnt = blnFat32 ? 4 : 2;
	var intFatSz = 1;
	var intClusters = 0;
	var intI = 0;
	var arrImg = null;
	var intP = PART * SEC;
	var intFat0 = 0;
	var intRoot0 = 0;
	var intData0 = 0;
	var objRoot = { name: '', dir: true, kids: [], index: {} };
	var intNext = 2;
	var arrFat = null;
	var intDate = ((2026 - 1980) << 9) | (10 << 5) | 22;

	if (intMb_a < 8 || intMb_a > 1024)
	{
		throw new Error('a hard disc image is 8 .. 1024 MB here');
	}
	for (intI = 0; intI < 20; intI++)
	{
		intClusters = Math.floor((intTotSec - intRsvd - 2 * intFatSz - intRootSecs) / intSpc);
		intFatSz = Math.ceil((intClusters + 2) * intEnt / SEC);
	}
	intClusters = Math.floor((intTotSec - intRsvd - 2 * intFatSz - intRootSecs) / intSpc);
	if (blnFat32 ? intClusters < 65525 : (intClusters < 4085 || intClusters > 65524))
	{
		throw new Error('no FAT type fits ' + intMb_a + ' MB');
	}
	intFat0 = intRsvd;
	intRoot0 = intRsvd + 2 * intFatSz;
	intData0 = intRoot0 + intRootSecs;
	arrImg = new Uint8Array(intTotal * SEC);
	arrFat = new Uint32Array(intClusters + 2);
	arrFat[0] = blnFat32 ? 0x0FFFFFF8 : 0xFFF8;
	arrFat[1] = blnFat32 ? 0x0FFFFFFF : 0xFFFF;

	function w16(intAt_a, v) { arrImg[intAt_a] = v & 255; arrImg[intAt_a + 1] = (v >> 8) & 255; }
	function w32(intAt_a, v) { w16(intAt_a, v & 0xFFFF); w16(intAt_a + 2, (v >>> 16) & 0xFFFF); }
	function n83(strN_a)
	{
		var arrP = strN_a.toUpperCase().replace(/[^A-Z0-9._$~!#%&'()@^`{}-]/g, '_').split('.');
		var strB = arrP[0].substr(0, 8);
		var strX = (arrP.length > 1) ? arrP[arrP.length - 1].substr(0, 3) : '';

		return cosStrBytes((strB + '        ').substr(0, 8) + (strX + '   ').substr(0, 3));
	}
	function csec(intC_a) { return intP + (intData0 + (intC_a - 2) * intSpc) * SEC; }
	function alloc(intN_a)
	{
		var intFirst = intNext;
		var intK = 0;

		if (intN_a === 0)
		{
			return 0;
		}
		if (intNext + intN_a > intClusters + 2)
		{
			throw new Error('the image is full');
		}
		for (intK = 0; intK < intN_a; intK++)
		{
			arrFat[intNext + intK] = (intK === intN_a - 1) ? (blnFat32 ? 0x0FFFFFFF : 0xFFFF) : intNext + intK + 1;
		}
		intNext += intN_a;
		return intFirst;
	}
	// the tree
	arrFiles_a.forEach(function(objF_a)
	{
		var arrParts = objF_a.path.split('/').filter(function(s) { return s.length > 0; });
		var objD = objRoot;

		arrParts.forEach(function(strP_a, intK_a)
		{
			var strKey = cosBytesStr(n83(strP_a));

			if (intK_a === arrParts.length - 1)
			{
				if (objD.index[strKey] === undefined)
				{
					objD.index[strKey] = { name: strP_a, data: objF_a.data };
					objD.kids.push(objD.index[strKey]);
				}
				else
				{
					objD.index[strKey].data = objF_a.data;
				}
			}
			else
			{
				if (objD.index[strKey] === undefined)
				{
					objD.index[strKey] = { name: strP_a, dir: true, kids: [], index: {} };
					objD.kids.push(objD.index[strKey]);
				}
				objD = objD.index[strKey];
			}
		});
	});
	// the folders' clusters (the root's on FAT32), then the files'
	function placeDirs(objD_a, blnRoot_a)
	{
		var intN = objD_a.kids.length + (blnRoot_a ? 0 : 2);

		if (blnRoot_a && !blnFat32)
		{
			if (intN > intRootEnts)
			{
				throw new Error('the root folder is full (FAT16: 512 entries)');
			}
			objD_a.cluster = 0;
		}
		else
		{
			objD_a.cluster = alloc(Math.max(1, Math.ceil(intN * 32 / intBytes)));
		}
		objD_a.kids.forEach(function(objK_a) { if (objK_a.dir) { placeDirs(objK_a, false); } });
	}
	placeDirs(objRoot, true);
	function placeFiles(objD_a)
	{
		objD_a.kids.forEach(function(objK_a)
		{
			if (objK_a.dir)
			{
				placeFiles(objK_a);
				return;
			}
			objK_a.cluster = alloc(Math.ceil(objK_a.data.length / intBytes));
			if (objK_a.cluster)
			{
				arrImg.set(objK_a.data, csec(objK_a.cluster));
			}
		});
	}
	placeFiles(objRoot);
	// the folders' entries
	function entry(intAt_a, arrName_a, intAttr_a, intCluster_a, intSize_a)
	{
		arrImg.set(arrName_a, intAt_a);
		arrImg[intAt_a + 11] = intAttr_a;
		w16(intAt_a + 14, 0);
		w16(intAt_a + 16, intDate);
		w16(intAt_a + 18, intDate);
		w16(intAt_a + 20, (intCluster_a >>> 16) & 0xFFFF);
		w16(intAt_a + 22, 0);
		w16(intAt_a + 24, intDate);
		w16(intAt_a + 26, intCluster_a & 0xFFFF);
		w32(intAt_a + 28, intSize_a);
	}
	function writeDir(objD_a, intParent_a, blnRoot_a)
	{
		var intAt = (blnRoot_a && !blnFat32) ? intP + intRoot0 * SEC : csec(objD_a.cluster);

		if (!blnRoot_a)
		{
			entry(intAt, cosStrBytes('.          '), 0x10, objD_a.cluster, 0);
			entry(intAt + 32, cosStrBytes('..         '), 0x10, intParent_a, 0);
			intAt += 64;
		}
		objD_a.kids.forEach(function(objK_a)
		{
			entry(intAt, n83(objK_a.name), objK_a.dir ? 0x10 : 0x20, objK_a.cluster, objK_a.dir ? 0 : objK_a.data.length);
			intAt += 32;
			if (objK_a.dir)
			{
				writeDir(objK_a, (blnRoot_a ? 0 : objD_a.cluster), false);
			}
		});
	}
	writeDir(objRoot, 0, true);
	// the MBR
	arrImg[446 + 4] = blnFat32 ? 0x0C : 0x0E;
	arrImg.set([0xFE, 0xFF, 0xFF], 446 + 1);
	arrImg.set([0xFE, 0xFF, 0xFF], 446 + 5);
	w32(446 + 8, PART);
	w32(446 + 12, intTotSec);
	arrImg[510] = 0x55;
	arrImg[511] = 0xAA;
	// the boot sector
	arrImg.set([0xEB, blnFat32 ? 0x58 : 0x3C, 0x90], intP);
	arrImg.set(cosStrBytes('CPCIMG  '), intP + 3);
	w16(intP + 11, SEC);
	arrImg[intP + 13] = intSpc;
	w16(intP + 14, intRsvd);
	arrImg[intP + 16] = 2;
	w16(intP + 17, intRootEnts);
	arrImg[intP + 21] = 0xF8;
	w16(intP + 22, blnFat32 ? 0 : intFatSz);
	w16(intP + 24, 63);
	w16(intP + 26, 255);
	w32(intP + 28, PART);
	w32(intP + 32, intTotSec);
	if (blnFat32)
	{
		w32(intP + 36, intFatSz);
		w32(intP + 44, objRoot.cluster);
		w16(intP + 48, 1);
		w16(intP + 50, 6);
		arrImg[intP + 64] = 0x80;
		arrImg[intP + 66] = 0x29;
		w32(intP + 67, 0x20261022);
		arrImg.set(cosStrBytes('CPC        FAT32   '), intP + 71);
	}
	else
	{
		arrImg[intP + 36] = 0x80;
		arrImg[intP + 38] = 0x29;
		w32(intP + 39, 0x20261022);
		arrImg.set(cosStrBytes('CPC        FAT16   '), intP + 43);
	}
	arrImg[intP + 510] = 0x55;
	arrImg[intP + 511] = 0xAA;
	if (blnFat32)
	{
		arrImg.set(arrImg.subarray(intP, intP + SEC), intP + 6 * SEC);
		w32(intP + SEC, 0x41615252);
		w32(intP + SEC + 484, 0x61417272);
		w32(intP + SEC + 488, intClusters + 2 - intNext);
		w32(intP + SEC + 492, intNext);
		arrImg[intP + SEC + 510] = 0x55;
		arrImg[intP + SEC + 511] = 0xAA;
		arrImg.set(arrImg.subarray(intP + SEC, intP + 2 * SEC), intP + 7 * SEC);
	}
	// the two FATs
	[0, 1].forEach(function(intF_a)
	{
		var intAt = intP + (intFat0 + intF_a * intFatSz) * SEC;
		var intK = 0;

		for (intK = 0; intK < intNext; intK++)
		{
			if (blnFat32)
			{
				w32(intAt + intK * 4, arrFat[intK]);
			}
			else
			{
				w16(intAt + intK * 2, arrFat[intK]);
			}
		}
	});

	return { image: arrImg, fat: blnFat32 ? 32 : 16, clusters: intClusters, used: intNext - 2, bytes: intBytes };
}

// the CPC's set as INSTALL.BAS lays it out, from the discs (cos-disk1 ...: fnDisc_a(n) its bytes,
// null after the last): INSTALL.BAS's DATA on disc 1 says where each file goes - [{ path, data }]
function cosInstallSet(fnDisc_a, strBase_a)
{
	var arrD1 = fnDisc_a(1);
	var objDiscs = {};
	var arrInst = null;
	var strText = '';
	var arrItems = [];
	var intDisc = 0;
	var arrOut = [];
	var intN = 1;
	var arrD = null;

	if (arrD1 === null)
	{
		throw new Error('no cos-disk1.dsk');
	}
	for (intN = 1; (arrD = (intN === 1) ? arrD1 : fnDisc_a(intN)) !== null; intN++)
	{
		objDiscs[intN] = {};
		cosDskRead(arrD).forEach(function(objF_a) { objDiscs[intN][objF_a.name] = cosFileTrim(objF_a.data); });
	}
	arrInst = objDiscs[1]['INSTALL.BAS'];
	if (arrInst === undefined)
	{
		throw new Error('cos-disk1.dsk has no INSTALL.BAS');
	}
	strText = cosBytesStr(arrInst);
	strText.split(/\r?\n/).forEach(function(strL_a)
	{
		var arrM = strL_a.match(/^\s*\d+\s+DATA\s+(.*)$/);

		if (arrM)
		{
			(arrM[1].match(/"[^"]*"|[^,]+/g) || []).forEach(function(s) { arrItems.push(s.replace(/"/g, '').trim()); });
		}
	});
	arrItems.slice(1).forEach(function(strI_a)
	{
		var strName = strI_a.replace(/^.*\//, '');

		if (strI_a === '*')
		{
			intDisc = -1;
		}
		else if (strI_a.charAt(0) === '#')
		{
			intDisc = parseInt(strI_a.substr(1), 10);
		}
		else if (intDisc > 0)
		{
			if (objDiscs[intDisc] === undefined || objDiscs[intDisc][strName] === undefined)
			{
				throw new Error('cos-disk' + intDisc + '.dsk has no ' + strName + ' (INSTALL.BAS names it)');
			}
			arrOut.push({ path: strBase_a + strI_a, data: objDiscs[intDisc][strName] });
		}
	});

	return arrOut;
}

// ------------------------------------------------------------
// files installed into an image that is there already (tools/sdinstall's way): a card image (a
// System/Next one, a dd of a card), an IDE image - an MBR (partition 1) or a bare FAT volume,
// FAT12 / 16 / 32 - or WinAPE's IDE image ("BITWISE DRIVE IMAGE FILE": sparse, through its block
// map). arrFiles_a [{ path: 'CYBORGOS/C/HELP.CYB', data }] under strDest_a ('/', '/CYBORGOS');
// folders made as needed, a file over one of its name. 8.3 names only, no long names written.
// The image as it is now: { image (the same bytes, or longer: a sparse image grows), fat, files }
// ------------------------------------------------------------

function cosFatInstall(arrImage_a, arrFiles_a, strDest_a)
{
	var arrImg = arrImage_a;
	var intLen = arrImage_a.length;
	var blnSparse = cosBytesStr(arrImage_a.subarray(0, 24)) === 'BITWISE DRIVE IMAGE FILE';
	var intPart = 0;
	var intBps = 512;
	var intSpc = 0;
	var intFatStart = 0;
	var intFatSecs = 0;
	var intNFats = 0;
	var intRootEnts = 0;
	var intRootStart = 0;
	var intDataStart = 0;
	var intClusters = 0;
	var intFatType = 0;
	var intEoc = 0;
	var intRootCluster = 0;
	var intFsInfo = 0;
	var intNextFree = 2;
	var arrFat = null;
	var arrS0 = null;
	var intDate = ((2026 - 1980) << 9) | (10 << 5) | 22;
	var intCount = 0;

	function rd16(a, o) { return a[o] | (a[o + 1] << 8); }
	function rd32(a, o) { return (a[o] | (a[o + 1] << 8) | (a[o + 2] << 16) | (a[o + 3] << 24)) >>> 0; }
	function wr16(a, o, v) { a[o] = v & 255; a[o + 1] = (v >> 8) & 255; }
	function wr32(a, o, v) { wr16(a, o, v & 0xFFFF); wr16(a, o + 2, (v >>> 16) & 0xFFFF); }
	// the image's own 512 byte blocks (a sparse one grows at its end)
	function blk(intB_a)
	{
		return arrImg.subarray(intB_a * 512, intB_a * 512 + 512);
	}
	function newBlock()
	{
		var intB = intLen / 512;
		var arrNew = null;

		if (intLen + 512 > arrImg.length)
		{
			arrNew = new Uint8Array(Math.max(arrImg.length * 2, intLen + 65536));
			arrNew.set(arrImg.subarray(0, intLen));
			arrImg = arrNew;
		}
		arrImg.fill(0, intLen, intLen + 512);
		intLen += 512;
		return intB;
	}
	function spUnset(e) { return e === 0 || e === 0xFFFF0000 || e === 0xFFFFFFFF; }
	function spBlock(intS_a, blnAlloc_a)
	{
		var intB = 1;
		var intLvl = 0;
		var intIx = 0;
		var e = 0;
		var intK = 0;

		for (intLvl = 0; intLvl < 4; intLvl++)
		{
			intIx = (intS_a >>> (21 - 7 * intLvl)) & 127;
			e = rd32(blk(intB), 4 * intIx);
			if (spUnset(e))
			{
				if (!blnAlloc_a)
				{
					return 0;
				}
				e = newBlock();
				if (intLvl === 2)
				{
					for (intK = 0; intK < 128; intK++)
					{
						wr32(blk(e), 4 * intK, 0xFFFF0000);
					}
				}
				wr32(blk(intB), 4 * intIx, e);
			}
			intB = e;
		}
		return intB;
	}
	// a sector of the volume: its bytes (a sparse one never written: zeros, not kept)
	function sec(intS_a)
	{
		var intB = 0;

		if (!blnSparse)
		{
			return arrImg.subarray((intPart + intS_a) * intBps, (intPart + intS_a + 1) * intBps);
		}
		intB = spBlock(intPart + intS_a, false);
		return intB ? blk(intB) : new Uint8Array(512);
	}
	function secW(intS_a, arrData_a)
	{
		var blnZero = true;
		var intK = 0;
		var intB = 0;

		if (!blnSparse)
		{
			arrImg.set(arrData_a, (intPart + intS_a) * intBps);
			return;
		}
		intB = spBlock(intPart + intS_a, false);
		if (!intB)
		{
			for (intK = 0; intK < 512; intK++)
			{
				if (arrData_a[intK]) { blnZero = false; break; }
			}
			if (blnZero)
			{
				return;
			}
			intB = spBlock(intPart + intS_a, true);
		}
		blk(intB).set(arrData_a);
	}
	function fatGet(c)
	{
		var o = 0;
		var v = 0;

		if (intFatType === 32) { return rd32(arrFat, c * 4) & 0x0FFFFFFF; }
		if (intFatType === 16) { return rd16(arrFat, c * 2); }
		o = c + (c >> 1);
		v = rd16(arrFat, o);
		return (c & 1) ? v >> 4 : v & 0xFFF;
	}
	function fatSet(c, v)
	{
		var o = 0;
		var w = 0;

		if (intFatType === 32) { wr32(arrFat, c * 4, ((rd32(arrFat, c * 4) & 0xF0000000) | (v & 0x0FFFFFFF)) >>> 0); }
		else if (intFatType === 16) { wr16(arrFat, c * 2, v); }
		else
		{
			o = c + (c >> 1);
			w = rd16(arrFat, o);
			w = (c & 1) ? (w & 0x000F) | (v << 4) : (w & 0xF000) | (v & 0xFFF);
			wr16(arrFat, o, w);
		}
	}
	function isEoc(v) { return v >= (intFatType === 32 ? 0x0FFFFFF8 : (intFatType === 16 ? 0xFFF8 : 0xFF8)); }
	function cSec(c) { return intDataStart + (c - 2) * intSpc; }
	function zeroCluster(c)
	{
		var intK = 0;

		for (intK = 0; intK < intSpc; intK++)
		{
			secW(cSec(c) + intK, new Uint8Array(intBps));
		}
	}
	function alloc()
	{
		var n = 0;
		var c = 0;

		for (n = 0; n < intClusters; n++)
		{
			c = intNextFree + n;
			if (c >= intClusters + 2) { c -= intClusters; }
			if (c < 2) { continue; }
			if (fatGet(c) === 0)
			{
				fatSet(c, intEoc);
				intNextFree = c + 1;
				zeroCluster(c);
				return c;
			}
		}
		throw new Error('the image is full');
	}
	function freeChain(c)
	{
		var n = 0;

		while (c >= 2 && !isEoc(c))
		{
			n = fatGet(c);
			fatSet(c, 0);
			c = n;
		}
	}
	function n83(strName_a)
	{
		var intDot = strName_a.lastIndexOf('.');
		var strN = (intDot >= 0) ? strName_a.substr(0, intDot) : strName_a;
		var strX = (intDot >= 0) ? strName_a.substr(intDot + 1) : '';

		if (strN.length < 1 || strN.length > 8 || strX.length > 3 || /[\s"*+,\/:;<=>?\[\\\]|.]/.test(strN + strX))
		{
			throw new Error(strName_a + ': not an 8.3 name');
		}
		return cosStrBytes((strN.toUpperCase() + '        ').substr(0, 8) + (strX.toUpperCase() + '   ').substr(0, 3));
	}
	function same(a, o, b)
	{
		var k = 0;

		for (k = 0; k < 11; k++)
		{
			if (a[o + k] !== b[k]) { return false; }
		}
		return true;
	}
	function eCluster(a, o) { return rd16(a, o + 26) | (intFatType === 32 ? (rd16(a, o + 20) << 16) >>> 0 : 0); }
	function eSetCluster(a, o, c) { wr16(a, o + 26, c & 0xFFFF); wr16(a, o + 20, intFatType === 32 ? (c >>> 16) : 0); }
	function stamp(a, o) { wr16(a, o + 14, 0); wr16(a, o + 16, intDate); wr16(a, o + 18, intDate); wr16(a, o + 22, 0); wr16(a, o + 24, intDate); }
	// an entry in folder d (d.fixed: FAT12/16's root): { s, o } of the name's, or of a free one (blnFree_a)
	function find(objD_a, arrName_a, blnFree_a)
	{
		var c = objD_a.cluster;
		var intS = 0;
		var intN = 0;
		var k = 0;
		var o = 0;
		var a = null;
		var n = 0;

		for (;;)
		{
			intS = objD_a.fixed ? intRootStart : cSec(c);
			intN = objD_a.fixed ? Math.ceil(intRootEnts * 32 / intBps) : intSpc;
			for (k = 0; k < intN; k++)
			{
				a = sec(intS + k);
				for (o = 0; o < intBps; o += 32)
				{
					if (blnFree_a)
					{
						if (a[o] === 0 || a[o] === 0xE5) { return { s: intS + k, o: o }; }
					}
					else
					{
						if (a[o] === 0) { return null; }
						if (a[o] !== 0xE5 && (a[o + 11] & 0x08) === 0 && same(a, o, arrName_a)) { return { s: intS + k, o: o, cluster: eCluster(a, o), attr: a[o + 11] }; }
					}
				}
			}
			if (objD_a.fixed)
			{
				if (blnFree_a) { throw new Error('the root folder is full'); }
				return null;
			}
			n = fatGet(c);
			if (isEoc(n))
			{
				if (!blnFree_a) { return null; }
				n = alloc();
				fatSet(c, n);
			}
			c = n;
		}
	}
	function setEntry(objAt_a, fnFill_a)
	{
		var a = new Uint8Array(sec(objAt_a.s));

		fnFill_a(a, objAt_a.o);
		secW(objAt_a.s, a);
	}
	function child(objD_a, strName_a)
	{
		var arrN = n83(strName_a);
		var objE = find(objD_a, arrN, false);
		var c = 0;
		var a = null;

		if (objE !== null)
		{
			if (!(objE.attr & 0x10)) { throw new Error(strName_a + ': a file, not a folder'); }
			return { cluster: objE.cluster, fixed: false };
		}
		c = alloc();
		objE = find(objD_a, arrN, true);
		setEntry(objE, function(b, o) { b.fill(0, o, o + 32); b.set(arrN, o); b[o + 11] = 0x10; eSetCluster(b, o, c); stamp(b, o); });
		a = new Uint8Array(intBps);
		a.fill(32, 0, 11);
		a[0] = 46;
		a[11] = 0x10;
		eSetCluster(a, 0, c);
		stamp(a, 0);
		a.fill(32, 32, 43);
		a[32] = 46;
		a[33] = 46;
		a[43] = 0x10;
		eSetCluster(a, 32, (objD_a.fixed || (intFatType === 32 && objD_a.cluster === intRootCluster)) ? 0 : objD_a.cluster);
		stamp(a, 32);
		secW(cSec(c), a);
		return { cluster: c, fixed: false };
	}
	function put(objD_a, strName_a, arrData_a)
	{
		var arrN = n83(strName_a);
		var objE = find(objD_a, arrN, false);
		var intCs = intSpc * intBps;
		var intFirst = 0;
		var intPrev = 0;
		var intAt = 0;
		var c = 0;
		var k = 0;
		var arrS = null;

		if (objE !== null)
		{
			if (objE.attr & 0x10) { throw new Error(strName_a + ': a folder is there'); }
			freeChain(objE.cluster);
		}
		else
		{
			objE = find(objD_a, arrN, true);
		}
		for (intAt = 0; intAt < arrData_a.length; intAt += intCs)
		{
			c = alloc();
			if (intPrev) { fatSet(intPrev, c); } else { intFirst = c; }
			for (k = 0; k < intSpc && intAt + k * intBps < arrData_a.length; k++)
			{
				arrS = new Uint8Array(intBps);
				arrS.set(arrData_a.subarray(intAt + k * intBps, Math.min(arrData_a.length, intAt + (k + 1) * intBps)));
				secW(cSec(c) + k, arrS);
			}
			intPrev = c;
		}
		setEntry(objE, function(b, o) { b.fill(0, o, o + 32); b.set(arrN, o); b[o + 11] = 0x20; eSetCluster(b, o, intFirst); wr32(b, o + 28, arrData_a.length); stamp(b, o); });
		intCount++;
	}

	// the volume
	if (blnSparse)
	{
		arrImg = new Uint8Array(arrImage_a.length);
		arrImg.set(arrImage_a);
	}
	else
	{
		arrImg = new Uint8Array(arrImage_a);
	}
	arrS0 = sec(0);
	if (!(arrS0[0] === 0xEB || arrS0[0] === 0xE9) || rd16(arrS0, 11) === 0 || (rd16(arrS0, 11) & (rd16(arrS0, 11) - 1)))
	{
		if (arrS0[510] !== 0x55 || arrS0[511] !== 0xAA || arrS0[0x1C2] === 0)
		{
			throw new Error('neither a FAT boot sector nor an MBR with a partition');
		}
		intPart = rd32(arrS0, 0x1C6);
		arrS0 = sec(0);
	}
	intBps = rd16(arrS0, 11);
	intSpc = arrS0[13];
	intFatStart = rd16(arrS0, 14);
	intNFats = arrS0[16];
	intRootEnts = rd16(arrS0, 17);
	intFatSecs = rd16(arrS0, 22) || rd32(arrS0, 36);
	if (!intBps || !intSpc || !intNFats || !intFatSecs || (blnSparse && intBps !== 512))
	{
		throw new Error('not a FAT volume');
	}
	intRootStart = intFatStart + intNFats * intFatSecs;
	intDataStart = intRootStart + Math.ceil(intRootEnts * 32 / intBps);
	intClusters = Math.floor(((rd16(arrS0, 19) || rd32(arrS0, 32)) - intDataStart) / intSpc);
	intFatType = (intClusters < 4085) ? 12 : ((intClusters < 65525) ? 16 : 32);
	intEoc = (intFatType === 32) ? 0x0FFFFFFF : ((intFatType === 16) ? 0xFFFF : 0xFFF);
	intRootCluster = (intFatType === 32) ? rd32(arrS0, 44) : 0;
	intFsInfo = (intFatType === 32) ? rd16(arrS0, 48) : 0;
	arrFat = new Uint8Array(intFatSecs * intBps);
	for (var intK = 0; intK < intFatSecs; intK++)
	{
		arrFat.set(sec(intFatStart + intK), intK * intBps);
	}
	if (intFsInfo)
	{
		var arrFi = sec(intFsInfo);

		if (rd32(arrFi, 0) === 0x41615252 && rd32(arrFi, 492) >= 2 && rd32(arrFi, 492) < intClusters + 2)
		{
			intNextFree = rd32(arrFi, 492);
		}
	}

	// the files
	var objBase = { cluster: intRootCluster, fixed: intFatType !== 32 };

	(strDest_a || '/').split('/').filter(function(s) { return s.length > 0; }).forEach(function(strP_a) { objBase = child(objBase, strP_a); });
	arrFiles_a.forEach(function(objF_a)
	{
		var arrP = objF_a.path.split('/').filter(function(s) { return s.length > 0; });
		var objD = objBase;
		var strName = arrP.pop();

		arrP.forEach(function(strP_a) { objD = child(objD, strP_a); });
		put(objD, strName, objF_a.data);
	});

	// the FATs back, the free hint
	for (var intF = 0; intF < intNFats; intF++)
	{
		for (var intS = 0; intS < intFatSecs; intS++)
		{
			secW(intFatStart + intF * intFatSecs + intS, arrFat.subarray(intS * intBps, (intS + 1) * intBps));
		}
	}
	if (intFsInfo)
	{
		var arrFi2 = new Uint8Array(sec(intFsInfo));

		if (rd32(arrFi2, 0) === 0x41615252)
		{
			wr32(arrFi2, 488, 0xFFFFFFFF);
			wr32(arrFi2, 492, intNextFree);
			secW(intFsInfo, arrFi2);
		}
	}

	return { image: arrImg.subarray(0, blnSparse ? intLen : arrImg.length), fat: intFatType, files: intCount, sparse: blnSparse };
}
