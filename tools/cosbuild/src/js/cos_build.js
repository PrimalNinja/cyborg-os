// The build: a layout (CyborgDesigner's: sections of containers of fields) whose fields are the
// build's parts - an NTC project, an assembly file, a note, a checkbox, another tool (external:
// what to give it, what to do, what to bring back), and the packager's own parts (Z packed, an
// .INC, a text file, the Next's archive, INSTALL.BAS, a .DSK, a card folder, an image). Run in
// order, sections then containers then fields; a run stops at the first part that waits (an
// external tool's files not back, a box not ticked) and says what it waits for. ES5: the page and node.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License

// ------------------------------------------------------------
// the part types (CyborgDesigner datatypes: the designer's palette and property editor)
// ------------------------------------------------------------

function cosProp(strName_a, strLabel_a, strType_a, strValue_a, blnShow_a, intLines_a)
{
	var objP = { name: strName_a, label: strLabel_a, datatype: strType_a || 'nativetextbox' };

	if (strValue_a !== undefined) { objP.value = strValue_a; }
	if (blnShow_a) { objP.showinbuilder = true; }
	if (intLines_a) { objP.lines = intLines_a; }
	return objP;
}

var COS_DATATYPES = [
	{ type: '--', caption: 'Projects', container: false, properties: [] },
	{ type: 'ntcproject', caption: 'NTC project', container: false, help: 'An NTC BASIC project: its files (paths in the project, a line each, the main module first) compiled with NTC to an .ASM in the stage folder (a folder of its own: its Makes, / as -). Makes: the file sjasmplus makes (HELP.CYB; a /tag when two make one name: GUI.CYB/cpc). Consts: NAME or NAME=value, spaces between. Out: the file sjasmplus writes when it isn\'t Makes (zxn: NTC.NEX).', properties: [
		cosProp('name', 'Makes'),
		cosProp('platform', 'Platform', '', 'cyborgos', true),
		cosProp('files', 'Files', 'nativemultilinetextbox', '', false, 6),
		cosProp('consts', 'Consts', '', '', true),
		cosProp('progname', 'Program name'),
		cosProp('out', 'Out'),
		cosProp('org', 'Org'),
		cosProp('library', 'Library')
	] },
	{ type: 'asmfile', caption: 'Assembly file', container: false, help: 'An assembly file as it is (a path in the project) into its own stage folder, for the external tool.', properties: [
		cosProp('name', 'Makes'),
		cosProp('file', 'File', '', '', true)
	] },
	{ type: '--', caption: 'People and tools', container: false, properties: [] },
	{ type: 'note', caption: 'Note', container: false, help: 'Text: nothing to do.', properties: [
		cosProp('name', 'Name'),
		cosProp('text', 'Text', 'nativemultilinetextbox', '', false, 4)
	] },
	{ type: 'checkbox', caption: 'Checkbox', container: false, help: 'Something a person does: the run waits here until it is ticked.', properties: [
		cosProp('name', 'Name'),
		cosProp('text', 'What to do', 'nativemultilinetextbox', '', false, 4),
		cosProp('done', 'Done', 'nativeyesno', 'no', true)
	] },
	{ type: 'external', caption: 'External tool', container: false, help: 'A tool outside the builder. Projects: the projects it is run for (their Makes, a line each; * every project before it). Give: files put in the stage folder for it (STAGE/PATH=what). Do: what to do - shown when the run waits here. Bring: the files that must come back (STAGE/PATH, a line each; empty: each project\'s file and .sym) - a project whose stage folder got a new file since is not back. Command: run in each project\'s folder ({name} {asm} {raw}); its scripts NAME.sh and NAME.bat are in the stage folder, and node runs it itself.', properties: [
		cosProp('name', 'Name'),
		cosProp('projects', 'Projects', 'nativemultilinetextbox', '', false, 3),
		cosProp('give', 'Give', 'nativemultilinetextbox', '', false, 3),
		cosProp('text', 'Do', 'nativemultilinetextbox', '', false, 4),
		cosProp('bring', 'Bring', 'nativemultilinetextbox', '', false, 3),
		cosProp('command', 'Command', '', 'sjasmplus --nologo --msg=err --sym={name}.sym{raw} {asm}')
	] },
	{ type: '--', caption: 'Packaging', container: false, properties: [] },
	{ type: 'packz', caption: 'System drive Z', container: false, help: 'CyborgOS\'s system drive Z packed as COSLOAD loads it: RAMDISC\'s driver page and the files in its 2K blocks, 32K a file (NAME1, NAME2 ...: gen:Z the lot), its .INC for COSLOAD, its list file (the names, CR LF). Files: NAME=what, a line each, in Z\'s order. Driver: the project with the RAM disc driver (its .sym: dr_img, dr_start, dr_end).', properties: [
		cosProp('name', 'Name', '', 'CYBORGOS.Z'),
		cosProp('driver', 'Driver', '', 'out:RAMDISC.CYB', true),
		cosProp('files', 'Files', 'nativemultilinetextbox', '', false, 6),
		cosProp('maxpages', 'Pages at most', '', '14'),
		cosProp('inc', 'Its .INC', '', 'COSZ.INC'),
		cosProp('list', 'Its list file', '', 'CYBORGOS.Z')
	] },
	{ type: 'cybinc', caption: 'COSCYB.INC', container: false, help: 'COSCYB.INC from the .sym of the CYBORGOS.BIN COSLOAD starts (its end, its free RAM, its firmware top).', properties: [
		cosProp('name', 'Name', '', 'COSCYB.INC'),
		cosProp('from', 'From', '', 'CYBORGOS.BIN', true)
	] },
	{ type: 'textfile', caption: 'Text file', container: false, help: 'A text file made from its lines (gen:NAME).', properties: [
		cosProp('name', 'Name'),
		cosProp('lines', 'Lines', 'nativemultilinetextbox', '', false, 6),
		cosProp('eol', 'Line ends', '', 'crlf', true)
	] },
	{ type: 'autoexec', caption: 'NextZXOS AUTOEXEC.BAS', container: false, help: 'A one-line NextBASIC program (line 10) as the +3DOS file NextZXOS runs at boot.', properties: [
		cosProp('name', 'Name', '', 'AUTOEXEC.BAS'),
		cosProp('command', 'Line 10', '', '.nexload /cyborgos.nex', true)
	] },
	{ type: 'arc', caption: 'Next boot archive', container: false, help: 'The Next\'s boot archive (the NEX carries it: Option NexData). Files: NAME=what, a line each.', properties: [
		cosProp('name', 'Name', '', 'CYBORGOS.ARC'),
		cosProp('blocks', '16K blocks', '', '10', true),
		cosProp('files', 'Files', 'nativemultilinetextbox', '', false, 6)
	] },
	{ type: 'installbas', caption: 'INSTALL.BAS', container: false, help: 'INSTALL.BAS: the program (a path in the project) to line 1000, then its DATA - the files of the .DSK parts named (a line each, disc 1 first) as they go in CYBORGOS/.', properties: [
		cosProp('name', 'Name', '', 'INSTALL.BAS'),
		cosProp('template', 'Program', '', '', true),
		cosProp('discs', 'Discs', 'nativemultilinetextbox', '', false, 4)
	] },
	{ type: 'dsk', caption: 'CPC disc (.DSK)', container: false, help: 'A CPC data format disc in build/ (Name: dsk/cos-disk1.dsk). Files: DEST=what [noinstall], a line each - DEST where INSTALL.BAS puts it (C/..., HELP/...); Z=gen:Z: the Z files.', properties: [
		cosProp('name', 'Name'),
		cosProp('files', 'Files', 'nativemultilinetextbox', '', false, 8)
	] },
	{ type: 'cardfolder', caption: 'Card folder', container: false, help: 'A folder in build/ (Name: next/CYBORGOS): the CPC\'s set first, from the .DSK parts named (as INSTALL.BAS lays it out), then its Files (DEST=what, a line each).', properties: [
		cosProp('name', 'Name'),
		cosProp('discs', 'Discs', 'nativemultilinetextbox', '', false, 3),
		cosProp('files', 'Files', 'nativemultilinetextbox', '', false, 6)
	] },
	{ type: 'imginstall', caption: 'Into an image', container: false, help: 'An image in build/ made from Base (an image in build/, or one attached): a card folder part\'s files in /CYBORGOS, then Top (DEST=what) at the top. 8.3 names, files over ones of their name; FAT12/16/32, an MBR or a bare volume, WinAPE\'s .ide.', properties: [
		cosProp('name', 'Makes'),
		cosProp('base', 'Base', '', '', true),
		cosProp('folder', 'Folder'),
		cosProp('top', 'Top', 'nativemultilinetextbox', '', false, 3)
	] },
	{ type: 'imgnew', caption: 'New hard disc image', container: false, help: 'A new image in build/ (MB: FAT16 under 64, FAT32): a card folder part\'s files in /CYBORGOS, or the CPC\'s set from the .DSK parts named.', properties: [
		cosProp('name', 'Makes'),
		cosProp('mb', 'MB', '', '32', true),
		cosProp('folder', 'Folder'),
		cosProp('discs', 'Discs', 'nativemultilinetextbox', '', false, 3)
	] },
	{ type: 'copy', caption: 'Copy to build/', container: false, help: 'Files put in build/ as they are (PATH=what, a line each).', properties: [
		cosProp('name', 'Name'),
		cosProp('files', 'Files', 'nativemultilinetextbox', '', false, 6)
	] },
	{ type: '--', caption: 'The project', container: false, properties: [] },
	{ type: 'imports', caption: 'Imports', container: false, help: 'The folders and files (from the top folder, a line each) Import takes into the project.', properties: [
		cosProp('name', 'Name', '', 'imports'),
		cosProp('folders', 'Folders', 'nativemultilinetextbox', '', false, 4)
	] }
];

// what a part type is, in words
function cosHelpOf(strType_a)
{
	var arrD = COS_DATATYPES.filter(function(d) { return d.type === strType_a; });

	return arrD.length ? (arrD[0].help || '') : '';
}

var COS_CONTAINERS = [
	{ type: '--', caption: 'Containers', container: false, properties: [] },
	{ type: 'verticalcontainer', caption: 'Steps (in order)', container: true, properties: [cosProp('name', 'Name', '', '', true), cosProp('label', 'Label', '', '', true)] },
	{ type: 'horizontalcontainer', caption: 'Steps (side by side)', container: true, properties: [cosProp('name', 'Name', '', '', true), cosProp('label', 'Label', '', '', true)] },
	{ type: '--', caption: 'Sections', container: false, properties: [] },
	{ type: 'layoutsection', caption: 'Stage', container: true, properties: [cosProp('name', 'Name', '', '', true), cosProp('label', 'Label', '', '', true)] }
];

// ------------------------------------------------------------
// the layout
// ------------------------------------------------------------

// the parts in order: [{ part, section (its caption) }]
function cosParts(objLayout_a)
{
	var arrResult = [];

	function walk(objC_a, strSection_a)
	{
		(objC_a.children || objC_a.containers || []).forEach(function(objK_a)
		{
			if (objK_a.container || objK_a.children)
			{
				walk(objK_a, strSection_a);
			}
			else
			{
				arrResult.push({ part: objK_a, section: strSection_a });
			}
		});
	}
	(objLayout_a.sections || []).forEach(function(objS_a) { walk(objS_a, objS_a.caption || ''); });

	return arrResult;
}

function cosLines(str_a)
{
	return String(str_a || '').split(/\r?\n/).map(function(s) { return s.replace(/;.*$/, '').trim(); }).filter(function(s) { return s.length > 0; });
}

// DEST=what [flags]
function cosPairs(str_a)
{
	return cosLines(str_a).map(function(strL_a)
	{
		var arrW = strL_a.split(/\s+/);
		var intEq = arrW[0].indexOf('=');

		return { dest: arrW[0].substr(0, intEq), src: arrW[0].substr(intEq + 1), flags: arrW.slice(1) };
	});
}

function cosFolderOf(strName_a)
{
	return strName_a.replace(/\//g, '-');
}

// an NTC project part as the compiler wants it: { name, file, folder, made, platform, src, consts, progname }
function cosProjectOf(objP_a)
{
	var objT = { id: objP_a.name, file: String(objP_a.name).split('/')[0], platform: objP_a.platform || 'cyborgos', src: cosLines(objP_a.files), consts: {}, org: objP_a.org || '', library: objP_a.library || '' };

	if (objP_a.type === 'asmfile')
	{
		objT.platform = 'asm';
		objT.src = [objP_a.file];
	}
	String(objP_a.consts || '').split(/\s+/).filter(Boolean).forEach(function(strC_a)
	{
		var arrKv = strC_a.split('=');

		objT.consts[arrKv[0]] = (arrKv.length > 1) ? arrKv[1] : -1;
	});
	objT.name = objP_a.progname || objT.file.replace(/\.\w+$/, '');
	objT.folder = cosFolderOf(objP_a.name);
	objT.made = objP_a.out || objT.file;

	return objT;
}

// ------------------------------------------------------------
// a run: ctx = { project, layout, stage (what is in the stage folder now: { path: bytes }),
//   images ({ build path: bytes }: base images given), ticks ({ part name: true }), compiled
//   (a cache) } - the result: { parts: [{ name, type, section, status, text }], stage (files for
//   the stage folder: { path: text or bytes }), build ({ path: bytes }), waiting (the part it
//   stopped at, or null), errors }
// ------------------------------------------------------------

var COS_SJ_DEFAULT = 'sjasmplus --nologo --msg=err --sym={name}.sym{raw} {asm}';

function cosRun(objCtx_a)
{
	var arrParts = cosParts(objCtx_a.layout);
	var objR = { parts: [], stage: {}, build: {}, gen: {}, waiting: null, errors: [], projects: {} };
	var objByName = {};
	var intI = 0;
	var blnStop = false;

	arrParts.forEach(function(objE_a) { objByName[objE_a.part.name] = objE_a.part; });
	arrParts.forEach(function(objE_a)
	{
		if (objE_a.part.type === 'ntcproject' || objE_a.part.type === 'asmfile')
		{
			objR.projects[objE_a.part.name] = cosProjectOf(objE_a.part);
		}
	});

	// a project's file as sjasmplus made it (null: not there, or made from other input - stale)
	function built(strName_a)
	{
		var objT = objR.projects[strName_a];
		var arrData = null;

		if (!objT)
		{
			return null;
		}
		arrData = objCtx_a.stage[objT.folder + '/' + objT.made];
		if (arrData === undefined || objR.stale[objT.folder])
		{
			return null;
		}
		return { data: arrData, sym: (objCtx_a.stage[objT.folder + '/' + objT.name + '.sym'] !== undefined) ? cosSym(cosBytesStr(objCtx_a.stage[objT.folder + '/' + objT.name + '.sym'])) : {} };
	}
	objR.stale = {};
	// what a line names: out:PROJECT, gen:NAME, build:PATH, or a project file
	function ref(strRef_a, strWhere_a)
	{
		var arrM = String(strRef_a).match(/^(out|gen|build):(.*)$/);
		var objB = null;

		if (arrM === null)
		{
			if (objCtx_a.project.files[strRef_a] === undefined)
			{
				throw new Error(strWhere_a + ': no ' + strRef_a + ' in the project');
			}
			return cosStrBytes(objCtx_a.project.files[strRef_a]);
		}
		if (arrM[1] === 'gen')
		{
			if (objR.gen[arrM[2]] === undefined)
			{
				throw new Error(strWhere_a + ': ' + strRef_a + ' is not made yet (a part before this one makes it)');
			}
			return objR.gen[arrM[2]];
		}
		if (arrM[1] === 'build')
		{
			if (objR.build[arrM[2]] === undefined)
			{
				throw new Error(strWhere_a + ': ' + strRef_a + ' is not made yet');
			}
			return objR.build[arrM[2]];
		}
		objB = built(arrM[2]);
		if (objB === null)
		{
			throw new Error(strWhere_a + ': ' + strRef_a + ' is not assembled');
		}
		return objB.data;
	}
	// a file put in the stage folder: when the stage has another, the project there is stale
	function toStage(strPath_a, data_a)
	{
		var arrNew = (typeof data_a === 'string') ? cosStrBytes(data_a) : data_a;
		var arrOld = objCtx_a.stage[strPath_a];
		var strFolder = strPath_a.indexOf('/') > 0 ? strPath_a.substr(0, strPath_a.indexOf('/')) : '';

		objR.stage[strPath_a] = data_a;
		if (strFolder && (arrOld === undefined || !cosSame(arrOld, arrNew)))
		{
			objR.stale[strFolder] = true;
		}
	}
	// the CPC's set from .DSK parts, as INSTALL.BAS lays it out: [{ path, data }]
	function cpcSet(arrDiscs_a, strWhere_a)
	{
		var arrOut = [];

		arrDiscs_a.forEach(function(strD_a)
		{
			var objD = objByName[strD_a];

			if (!objD || objD.type !== 'dsk')
			{
				throw new Error(strWhere_a + ': no .DSK part ' + strD_a);
			}
			cosPairs(objD.files).forEach(function(objF_a)
			{
				if (objF_a.flags.indexOf('noinstall') >= 0)
				{
					return;
				}
				if (objF_a.src === 'gen:Z')
				{
					(objR.gen.Z || []).forEach(function(objZ_a) { arrOut.push({ path: objZ_a.name, data: objZ_a.data }); });
					return;
				}
				arrOut.push({ path: objF_a.dest, data: ref(objF_a.src, strWhere_a) });
			});
		});
		return arrOut;
	}

	for (intI = 0; intI < arrParts.length && !blnStop; intI++)
	{
		var objP = arrParts[intI].part;
		var objRow = { name: objP.name || objP.caption, type: objP.type, section: arrParts[intI].section, status: 'done', text: '' };

		objR.parts.push(objRow);
		try
		{
			switch (objP.type)
			{
				case 'ntcproject':
				case 'asmfile':
				{
					var objT = objR.projects[objP.name];
					var strKey = JSON.stringify(objT) + '|' + objT.src.map(function(s) { return objCtx_a.project.files[s] || ''; }).join('\u0001');
					var objC = (objCtx_a.compiled && objCtx_a.compiled[strKey]) || cosCompile(objCtx_a.project, objT);

					if (objCtx_a.compiled)
					{
						objCtx_a.compiled[strKey] = objC;
					}
					objRow.compile = objC;
					if (objC.errors.length > 0)
					{
						objRow.status = 'error';
						objRow.text = objC.errors.length + ' errors: ' + objC.errors[0];
						objR.errors.push(objP.name + ': ' + objC.errors[0]);
						blnStop = true;
						break;
					}
					toStage(objT.folder + '/' + cosAsmName(objT), objC.asm);
					objRow.text = objC.asm.split('\n').length + ' lines' + (objC.warnings.length ? ', ' + objC.warnings.length + ' warnings' : '') + (objR.stale[objT.folder] ? ' - changed: to assemble' : '');
					break;
				}
				case 'note':
					objRow.status = 'note';
					objRow.text = String(objP.text || '').split('\n')[0];
					break;
				case 'imports':
					objRow.status = 'note';
					objRow.text = cosLines(objP.folders).join(', ');
					break;
				case 'checkbox':
					if (!toBoolean(objP.done) && !(objCtx_a.ticks || {})[objP.name])
					{
						objRow.status = 'wait';
						objRow.text = objP.text || 'tick it when it is done';
						objR.waiting = { part: objP, text: objP.text || '' };
						blnStop = true;
					}
					break;
				case 'external':
				{
					var arrProj = cosExternalProjects(objP, arrParts, intI, objR.projects);
					var arrBring = cosLines(objP.bring);
					var arrMissing = [];
					var objScripts = null;

					cosPairs(objP.give).forEach(function(objG_a) { toStage(objG_a.dest, ref(objG_a.src, objP.name)); });
					objScripts = cosScriptsFor(objP, arrProj);
					Object.keys(objScripts).forEach(function(k) { objR.stage[k] = objScripts[k]; });
					if (arrBring.length === 0)
					{
						arrProj.forEach(function(objT_a)
						{
							arrBring.push(objT_a.folder + '/' + objT_a.made);
							if (objT_a.platform !== 'cpm')
							{
								arrBring.push(objT_a.folder + '/' + objT_a.name + '.sym');
							}
						});
					}
					arrBring.forEach(function(strB_a)
					{
						var strFolder = strB_a.indexOf('/') > 0 ? strB_a.substr(0, strB_a.indexOf('/')) : '';

						if (objCtx_a.stage[strB_a] === undefined || objR.stale[strFolder])
						{
							arrMissing.push(strB_a);
						}
					});
					objRow.projects = arrProj;
					if (arrMissing.length > 0)
					{
						objRow.status = 'wait';
						objRow.text = arrMissing.length + ' of ' + arrBring.length + ' files to bring back (' + arrMissing.slice(0, 3).join(', ') + (arrMissing.length > 3 ? ' ...' : '') + ')';
						objR.waiting = { part: objP, text: objP.text || '', missing: arrMissing, projects: arrProj };
						blnStop = true;
					}
					else
					{
						objRow.text = arrBring.length + ' files back';
					}
					break;
				}
				case 'packz':
				{
					var objDrvT = objR.projects[String(objP.driver).replace(/^out:/, '')];
					var objDrv = built(String(objP.driver).replace(/^out:/, ''));
					var intImg = 0;
					var intLen = 0;
					var intAt = 0;
					var arrZ = [];
					var objZ = null;

					if (!objDrvT || objDrv === null)
					{
						throw new Error('the driver ' + objP.driver + ' is not assembled');
					}
					intImg = cosSymFind(objDrv.sym, 'dr_img');
					intLen = cosSymFind(objDrv.sym, 'dr_end') - cosSymFind(objDrv.sym, 'dr_start');
					if (intImg === undefined || isNaN(intLen))
					{
						throw new Error(objP.driver + '\'s .sym has no dr_img / dr_start / dr_end');
					}
					intAt = 128 + intImg - objDrv.sym.ntc_start;
					cosPairs(objP.files).forEach(function(objF_a) { arrZ.push({ name: objF_a.dest, data: ref(objF_a.src, objP.name) }); });
					objZ = cosZPack(arrZ, objDrv.data.subarray(intAt, intAt + intLen), parseInt(objP.maxpages, 10) || 14);
					objZ.files.forEach(function(f) { f.name = String(objP.name || 'CYBORGOS.Z') + f.name.replace(/^CYBORGOS\.Z/, ''); objR.gen[f.name] = f.data; });
					objR.gen.Z = objZ.files;
					objR.gen[objP.inc || 'COSZ.INC'] = cosStrBytes(objZ.inc.replace(/"CYBORGOS\.Z(\d+)"/g, function(a, n) { return '"' + (objP.name || 'CYBORGOS.Z') + n + '"'; }));
					objR.gen[objP.list || 'CYBORGOS.Z'] = cosStrBytes(cosPairs(objP.files).map(function(f) { return f.dest; }).join('\r\n') + '\r\n');
					objRow.text = objZ.commands + ' commands, ' + objZ.kb + 'K, ' + objZ.files.length + ' files (Z keeps ' + objZ.claim + ' pages)' + (objZ.skipped.length ? ' - ' + objZ.skipped.join('; ') : '');
					break;
				}
				case 'cybinc':
				{
					var objSys = built(objP.from);

					if (objSys === null)
					{
						throw new Error(objP.from + ' is not assembled');
					}
					objR.gen[objP.name] = cosStrBytes(cosCybInc(objSys.sym));
					objRow.text = objP.from + ': ' + objSys.data.length + ' bytes, its arrays end #' + cosHex4(objSys.sym.ntc_free);
					break;
				}
				case 'textfile':
					objR.gen[objP.name] = cosStrBytes(cosLines(objP.lines).join(objP.eol === 'lf' ? '\n' : '\r\n') + (objP.eol === 'lf' ? '\n' : '\r\n'));
					objRow.text = cosLines(objP.lines).length + ' lines';
					break;
				case 'autoexec':
					objR.gen[objP.name] = cosAutoexec(objP.command || '.nexload /cyborgos.nex');
					objRow.text = objP.command;
					break;
				case 'arc':
				{
					var arrA = cosPairs(objP.files).map(function(f) { return { name: f.dest, data: ref(f.src, objP.name) }; });
					var objArc = cosArc(arrA, parseInt(objP.blocks, 10) || 10);

					objR.gen[objP.name] = objArc.data;
					objRow.text = arrA.length + ' files, ' + objArc.used + ' of ' + objArc.data.length + ' bytes';
					break;
				}
				case 'installbas':
				{
					var arrInst = cosLines(objP.discs).map(function(strD_a, intN_a)
					{
						var objD = objByName[strD_a];
						var arrNames = [];

						if (!objD || objD.type !== 'dsk')
						{
							throw new Error('no .DSK part ' + strD_a);
						}
						cosPairs(objD.files).forEach(function(objF_a)
						{
							if (objF_a.flags.indexOf('noinstall') >= 0)
							{
								return;
							}
							if (objF_a.src === 'gen:Z')
							{
								(objR.gen.Z || []).forEach(function(z) { arrNames.push(z.name); });
							}
							else
							{
								arrNames.push(objF_a.dest);
							}
						});
						return { n: intN_a + 1, files: arrNames };
					});

					objR.gen[objP.name] = cosStrBytes(cosInstallBas(cosBytesStr(ref(objP.template, objP.name)), arrInst));
					objRow.text = arrInst.length + ' discs, ' + arrInst.reduce(function(n, d) { return n + d.files.length; }, 0) + ' files';
					break;
				}
				case 'dsk':
				{
					var arrF = [];
					var objDsk = null;

					cosPairs(objP.files).forEach(function(objF_a)
					{
						if (objF_a.src === 'gen:Z')
						{
							(objR.gen.Z || []).forEach(function(z) { arrF.push({ name: z.name, data: z.data }); });
						}
						else
						{
							arrF.push({ name: objF_a.dest.replace(/^.*\//, ''), data: ref(objF_a.src, objP.name) });
						}
					});
					objDsk = cosDskMake(arrF);
					objR.build[objP.name] = objDsk.image;
					objRow.text = arrF.length + ' files, ' + objDsk.free + 'K free, ' + (COS_DSK_DIRS - objDsk.entries) + ' entries free';
					break;
				}
				case 'cardfolder':
				{
					var strBase = String(objP.name).replace(/\/?$/, '/');
					var objFiles = {};

					cpcSet(cosLines(objP.discs), objP.name).forEach(function(f) { objFiles[f.path] = f.data; });
					cosPairs(objP.files).forEach(function(f) { objFiles[f.dest] = ref(f.src, objP.name); });
					Object.keys(objFiles).forEach(function(k) { objR.build[strBase + k] = objFiles[k]; });
					objR.gen['folder:' + objP.name] = objFiles;
					objRow.text = Object.keys(objFiles).length + ' files';
					break;
				}
				case 'imginstall':
				{
					var arrBase = (objCtx_a.images || {})[objP.base] || objR.build[objP.base];
					var objFold = objR.gen['folder:' + objP.folder];
					var objI = null;

					if (arrBase === undefined)
					{
						objRow.status = 'skip';
						objRow.text = 'not made: no ' + objP.base + ' (attach it, or put it in build/)';
						break;
					}
					if (objP.folder && objFold === undefined)
					{
						throw new Error('no card folder part ' + objP.folder + ' before this one');
					}
					objI = cosFatInstall(arrBase, Object.keys(objFold || {}).map(function(k) { return { path: k, data: objFold[k] }; }), '/CYBORGOS');
					if (cosPairs(objP.top).length > 0)
					{
						objI = cosFatInstall(objI.image, cosPairs(objP.top).map(function(f) { return { path: f.dest, data: ref(f.src, objP.name) }; }), '/');
					}
					objR.build[objP.name] = objI.image;
					objRow.text = 'FAT' + objI.fat + ', ' + Object.keys(objFold || {}).length + ' files in /CYBORGOS';
					break;
				}
				case 'imgnew':
				{
					var arrIn = [];
					var objFo = objR.gen['folder:' + objP.folder];
					var objNew = null;

					if (objP.folder)
					{
						Object.keys(objFo || {}).forEach(function(k) { arrIn.push({ path: 'CYBORGOS/' + k, data: objFo[k] }); });
					}
					else
					{
						cpcSet(cosLines(objP.discs), objP.name).forEach(function(f) { arrIn.push({ path: 'CYBORGOS/' + f.path, data: f.data }); });
					}
					objNew = cosFatImage(parseInt(objP.mb, 10) || 32, arrIn);
					objR.build[objP.name] = objNew.image;
					objRow.text = objP.mb + ' MB, FAT' + objNew.fat + ', ' + arrIn.length + ' files';
					break;
				}
				case 'copy':
					cosPairs(objP.files).forEach(function(f) { objR.build[f.dest] = ref(f.src, objP.name); });
					objRow.text = cosPairs(objP.files).length + ' files';
					break;
				default:
					objRow.status = 'skip';
					objRow.text = 'what is a ' + objP.type + '?';
			}
		}
		catch (objError)
		{
			objRow.status = 'error';
			objRow.text = objError.message;
			objR.errors.push((objP.name || objP.type) + ': ' + objError.message);
			blnStop = true;
		}
	}
	for (; intI < arrParts.length; intI++)
	{
		objR.parts.push({ name: arrParts[intI].part.name || arrParts[intI].part.caption, type: arrParts[intI].part.type, section: arrParts[intI].section, status: 'todo', text: '' });
	}
	objR.done = !blnStop;

	return objR;
}

function cosSame(a_a, b_a)
{
	var intI = 0;

	if (a_a.length !== b_a.length)
	{
		return false;
	}
	for (intI = 0; intI < a_a.length; intI++)
	{
		if (a_a[intI] !== b_a[intI])
		{
			return false;
		}
	}
	return true;
}

// the projects an external part assembles: its list, or * every project before it
function cosExternalProjects(objP_a, arrParts_a, intAt_a, objProjects_a)
{
	var arrNames = cosLines(objP_a.projects);
	var arrResult = [];

	if (arrNames.length === 1 && arrNames[0] === '*')
	{
		arrNames = [];
		arrParts_a.slice(0, intAt_a).forEach(function(objE_a)
		{
			if (objE_a.part.type === 'ntcproject' || objE_a.part.type === 'asmfile')
			{
				arrNames.push(objE_a.part.name);
			}
		});
	}
	arrNames.forEach(function(strN_a)
	{
		if (!objProjects_a[strN_a])
		{
			throw new Error('no project ' + strN_a);
		}
		arrResult.push(objProjects_a[strN_a]);
	});

	return arrResult;
}

// a project's command line for an external part (the part's command, its {name} {asm} {raw})
function cosCommandFor(objP_a, objT_a)
{
	return String(objP_a.command || COS_SJ_DEFAULT).replace(/\{name\}/g, objT_a.name).replace(/\{asm\}/g, cosAsmName(objT_a)).replace(/\{raw\}/g, objT_a.platform === 'cpm' ? ' --raw=' + objT_a.file : '');
}

// an external part's scripts: NAME.sh and NAME.bat - its command in each project's folder. sjasmplus:
// SJASMPLUS if set, else the one CyborgOS carries (sjasmplus/sjasmplus.exe, two up from build/stage),
// else the PATH's
function cosScriptsFor(objP_a, arrProj_a)
{
	var strName = objP_a.name || 'external';
	var arrSh = ['#!/bin/sh', '# ' + strName + ' (CyborgOS Builder): run it here, in the stage folder (build/stage)', 'cd "$(dirname "$0")"', 'SJ=${SJASMPLUS:-sjasmplus}', 'command -v "$SJ" > /dev/null 2>&1 || [ ! -x ../../sjasmplus/sjasmplus ] || SJ=$(pwd)/../../sjasmplus/sjasmplus', 'fail=0'];
	var arrBat = ['@echo off', 'rem ' + strName + ' (CyborgOS Builder): run it here, in the stage folder (build\\stage)', 'cd /d "%~dp0"', 'set SJ=%SJASMPLUS%', 'if "%SJ%"=="" if exist "%~dp0..\\..\\sjasmplus\\sjasmplus.exe" set SJ=%~dp0..\\..\\sjasmplus\\sjasmplus.exe', 'if "%SJ%"=="" set SJ=sjasmplus', 'set fail=0'];
	var objOut = {};

	if (arrProj_a.length === 0)
	{
		return objOut;
	}
	arrProj_a.forEach(function(objT_a)
	{
		var strCmd = cosCommandFor(objP_a, objT_a);
		var blnSj = /^sjasmplus\b/.test(strCmd);

		arrSh.push('(cd "' + objT_a.folder + '" && ' + (blnSj ? strCmd.replace(/^sjasmplus\b/, '"$SJ"') : strCmd) + ') || { echo "' + objT_a.id + ' failed"; fail=1; }');
		arrBat.push('pushd "' + objT_a.folder + '"');
		arrBat.push(blnSj ? strCmd.replace(/^sjasmplus\b/, '"%SJ%"') : strCmd);
		arrBat.push('if errorlevel 1 (echo ' + objT_a.id + ' failed & set fail=1)');
		arrBat.push('popd');
	});
	arrSh.push('[ $fail = 0 ] && echo "' + strName + ': all done - now Run again"', 'exit $fail', '');
	arrBat.push('if %fail%==0 echo ' + strName + ': all done - now Run again', 'pause', '');
	objOut[strName + '.sh'] = arrSh.join('\n');
	objOut[strName + '.bat'] = arrBat.join('\r\n');

	return objOut;
}

// the project files no part names (carried, never used)
function cosUnused(objProject_a, objLayout_a)
{
	var objUsed = {};

	cosParts(objLayout_a).forEach(function(objE_a)
	{
		var p = objE_a.part;

		cosLines(p.files).forEach(function(s) { objUsed[s.replace(/^[^=]*=/, '').split(/\s+/)[0]] = true; });
		cosLines(p.give).forEach(function(s) { objUsed[s.replace(/^[^=]*=/, '')] = true; });
		cosLines(p.top).forEach(function(s) { objUsed[s.replace(/^[^=]*=/, '')] = true; });
		[p.file, p.template, p.driver].forEach(function(s) { if (s) { objUsed[s] = true; } });
	});

	return Object.keys(objProject_a.files).filter(function(k) { return !objUsed[k] && !/\.layout\.json$/i.test(k); });
}

// the project files the parts name that the project hasn't got
function cosMissing(objProject_a, objLayout_a)
{
	var arrResult = [];

	function check(strRef_a, strWhere_a)
	{
		if (!/^(out|gen|build):/.test(strRef_a) && objProject_a.files[strRef_a] === undefined)
		{
			arrResult.push(strRef_a + ' (' + strWhere_a + ')');
		}
	}
	cosParts(objLayout_a).forEach(function(objE_a)
	{
		var p = objE_a.part;

		if (p.type === 'ntcproject')
		{
			cosLines(p.files).forEach(function(s) { check(s, p.name); });
		}
		if (p.type === 'asmfile') { check(p.file, p.name); }
		if (p.type === 'installbas') { check(p.template, p.name); }
		['files', 'give', 'top'].forEach(function(k)
		{
			if (p.type !== 'ntcproject')
			{
				cosPairs(p[k]).forEach(function(f) { if (f.src) { check(f.src, p.name); } });
			}
		});
	});

	return arrResult;
}

// the layout files in the project (*.layout.json): [path]
function cosLayouts(objProject_a)
{
	return Object.keys(objProject_a.files).filter(function(k) { return /\.layout\.json$/i.test(k); }).sort();
}

function cosLayoutOf(objProject_a, strPath_a)
{
	try
	{
		return JSON.parse(objProject_a.files[strPath_a]);
	}
	catch (objError)
	{
		return { name: strPath_a, sections: [] };
	}
}

function cosImportsOf(objLayout_a)
{
	var arrResult = [];

	cosParts(objLayout_a).forEach(function(objE_a)
	{
		if (objE_a.part.type === 'imports')
		{
			arrResult = arrResult.concat(cosLines(objE_a.part.folders));
		}
	});

	return arrResult;
}

if (typeof toBoolean === 'undefined')
{
	var toBoolean = function(v_a) { return (v_a === 'yes' || v_a === 'true' || v_a === '1' || v_a === true); };
}

// the files an import takes: under one of the Imports part's folders (or one it names), not a
// binary nor a test / screenshot folder's
var COS_SKIP = /\.(png|jpg|gif|bmp|exe|zip|dsk|img|ide|nex|bin|cyb|com|sym|pyc|htm)$/i;

function cosImportWanted(strPath_a, arrImports_a)
{
	var blnIn = arrImports_a.some(function(strI_a) { return strPath_a === strI_a || strPath_a.indexOf(strI_a.replace(/\/$/, '') + '/') === 0; });

	return blnIn && !COS_SKIP.test(strPath_a) && !/(^|\/)(test|screenshots)\//.test(strPath_a) && !/(^|\/)\./.test(strPath_a);
}
