// CyborgOS Builder - the page: Build (the layout's parts run in order), Design (the layout in
// CyborgDesigner, the parts as its datatypes), Files (the project), Tools. NTC BASIC's components
// (textEditor, listRenderer) and CyborgDesigner. ES5. (c) 2026 Cyborg Unicorn Pty Ltd - MIT License

var api = {
	element: function(strScope_a, strClass_a)
	{
		if (arguments.length === 1)
		{
			return $(strScope_a);
		}

		return $(strClass_a, strScope_a);
	}
};

var COS_PAGE = '';			// the page as it was loaded (Save page: with the project put in)
var m_objProject = { name: 'CyborgOS', files: {} };
var m_strLayout = '';			// the layout's path in the project
var m_objLayout = null;
var m_strSel = '';
var m_objEditor = null;
var m_objView = null;
var m_objList = null;
var m_objDesigner = null;
var m_objRun = null;			// the last run
var m_objCompiled = {};			// compiles kept between runs (same sources: same result)
var m_strPart = '';			// the part shown
var m_hStage = null;			// the stage folder (File System Access), when picked
var m_objStage = {};			// what is in the stage folder: { path: bytes }
var m_objImages = {};			// images parts start from: { build path: bytes }
var m_objTicks = {};
var m_blnDirty = false;
var m_arrUrls = [];
var m_arrInstFiles = null;
var m_strPage = 'build';

// ------------------------------------------------------------
// little things
// ------------------------------------------------------------

function cosEsc(str_a)
{
	return String(str_a).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function cosStatus(str_a)
{
	$('#cos-status').text(str_a);
}

function cosSetDirty(bln_a)
{
	m_blnDirty = bln_a;
	$('#cos-dirty').text(bln_a ? 'changed - Save page keeps it' : '');
}

function cosDownload(strName_a, data_a)
{
	var objBlob = new Blob([(typeof data_a === 'string') ? cosStrBytes(data_a) : data_a], { type: 'application/octet-stream' });
	var objA = document.createElement('a');

	objA.href = URL.createObjectURL(objBlob);
	objA.download = strName_a;
	document.body.appendChild(objA);
	objA.click();
	setTimeout(function() { URL.revokeObjectURL(objA.href); objA.remove(); }, 2000);
}

function cosUrl(data_a)
{
	var strUrl = URL.createObjectURL(new Blob([data_a], { type: 'application/octet-stream' }));

	m_arrUrls.push(strUrl);
	return strUrl;
}

function cosFreeUrls()
{
	m_arrUrls.forEach(function(s) { URL.revokeObjectURL(s); });
	m_arrUrls = [];
}

function cosSize(int_a)
{
	return (int_a >= 10240) ? Math.round(int_a / 1024) + 'K' : String(int_a);
}

// a File's bytes
function cosReadFile(objFile_a)
{
	return new Promise(function(fnOk_a, fnFail_a)
	{
		var objR = new FileReader();

		objR.onload = function() { fnOk_a(new Uint8Array(objR.result)); };
		objR.onerror = function() { fnFail_a(objR.error); };
		objR.readAsArrayBuffer(objFile_a);
	});
}

// the files an <input webkitdirectory> gave: { 'path in the folder': File } (the folder's own name off)
function cosDirFiles(objInput_a)
{
	var objResult = {};

	Array.prototype.forEach.call(objInput_a.files, function(objF_a)
	{
		var strRel = (objF_a.webkitRelativePath || objF_a.name).replace(/\\/g, '/');

		objResult[strRel.indexOf('/') >= 0 ? strRel.substr(strRel.indexOf('/') + 1) : strRel] = objF_a;
	});

	return objResult;
}

// a folder picked (File System Access: Chrome, Edge), null when there is none
function cosPickFolder(strId_a)
{
	if (typeof window.showDirectoryPicker !== 'function')
	{
		return Promise.resolve(null);
	}

	return window.showDirectoryPicker({ id: strId_a, mode: 'readwrite' }).catch(function() { return null; });
}

// files { 'a/b/c': bytes or text } written into a folder (handle)
function cosWriteFolder(hDir_a, objFiles_a)
{
	var arrKeys = Object.keys(objFiles_a);
	var intDone = 0;

	function one(strPath_a)
	{
		var arrParts = strPath_a.split('/');
		var strName = arrParts.pop();
		var pDir = Promise.resolve(hDir_a);

		arrParts.forEach(function(strP_a)
		{
			pDir = pDir.then(function(h) { return h.getDirectoryHandle(strP_a, { create: true }); });
		});

		return pDir.then(function(h) { return h.getFileHandle(strName, { create: true }); }).then(function(hF) { return hF.createWritable(); }).then(function(w)
		{
			var v = objFiles_a[strPath_a];

			return w.write((typeof v === 'string') ? cosStrBytes(v) : v).then(function() { return w.close(); });
		}).then(function()
		{
			intDone++;
			if (intDone % 20 === 0)
			{
				cosStatus('writing ' + intDone + ' / ' + arrKeys.length);
			}
		});
	}

	return arrKeys.reduce(function(p, k) { return p.then(function() { return one(k); }); }, Promise.resolve()).then(function()
	{
		cosStatus(arrKeys.length + ' files written');
	});
}

// a folder (handle) read: { 'a/b/c': bytes }
function cosReadFolder(hDir_a)
{
	var objResult = {};

	function walk(h_a, strRel_a)
	{
		var it = h_a.values();
		var arrEntries = [];

		function next()
		{
			return it.next().then(function(r)
			{
				if (r.done)
				{
					return arrEntries.reduce(function(p, e)
					{
						return p.then(function()
						{
							if (e.kind === 'directory')
							{
								return walk(e, strRel_a + e.name + '/');
							}
							return e.getFile().then(cosReadFile).then(function(arr) { objResult[strRel_a + e.name] = arr; });
						});
					}, Promise.resolve());
				}
				arrEntries.push(r.value);
				return next();
			});
		}
		return next();
	}

	return walk(hDir_a, '').then(function() { return objResult; });
}

function cosTable(arrHead_a, arrRows_a)
{
	var arrH = ['<table><tr>'];

	arrHead_a.forEach(function(s) { arrH.push('<th>' + cosEsc(s) + '</th>'); });
	arrH.push('</tr>');
	arrRows_a.forEach(function(objR_a)
	{
		arrH.push('<tr' + (objR_a.attr || '') + '>' + objR_a.cells.map(function(c) { return '<td' + (typeof c === 'object' ? (c.cls ? ' class="' + c.cls + '"' : '') + '>' + c.html : '>' + cosEsc(c)) + '</td>'; }).join('') + '</tr>');
	});
	arrH.push('</table>');

	return arrH.join('');
}

// ------------------------------------------------------------
// tabs, the layout
// ------------------------------------------------------------

function cosShow(strPage_a)
{
	m_strPage = strPage_a;
	$('.cos-tab').removeClass('cos-on');
	$('.cos-tab[data-page="' + strPage_a + '"]').addClass('cos-on');
	$('.cos-page').removeClass('cos-on');
	$('.cos-page[data-page="' + strPage_a + '"]').addClass('cos-on');
	if (strPage_a === 'design')
	{
		cosDesigner();
	}
}

function cosLayoutList()
{
	var objSel = $('#cos-layout');
	var arrL = cosLayouts(m_objProject);

	objSel.empty();
	arrL.forEach(function(k) { objSel.append($('<option></option>').val(k).text(k.replace(/^.*\//, '').replace(/\.layout\.json$/i, ''))); });
	if (arrL.indexOf(m_strLayout) < 0)
	{
		m_strLayout = arrL[0] || '';
	}
	objSel.val(m_strLayout);
	m_objLayout = m_strLayout ? cosLayoutOf(m_objProject, m_strLayout) : { name: '', sections: [] };
	m_objDesigner = null;
}

// the layout back into its project file (the designer changes it in place)
function cosLayoutSave()
{
	var strNew = JSON.stringify(m_objLayout, null, '\t');

	if (m_strLayout && JSON.stringify(JSON.parse(m_objProject.files[m_strLayout] || '{}')) !== JSON.stringify(m_objLayout))
	{
		m_objProject.files[m_strLayout] = strNew;
		cosSetDirty(true);
	}
}

function cosDesigner()
{
	if (m_objDesigner !== null || typeof cyborgDesigner !== 'function')
	{
		return;
	}
	$('#cos-designer').empty();
	m_objLayout.sections = m_objLayout.sections || [];
	m_objDesigner = new cyborgDesigner(
	{
		cbElement: element,
		cbDataRenderer: function(objRaw_a)
		{
			element('#cos-designer', '.gecd-layoutdata').html('<pre>' + cosEsc(JSON.stringify(objRaw_a, null, 2)) + '</pre>');
			cosLayoutSave();
		},
		cbTransformer: function(objRaw_a) { return objRaw_a; },
		target: '#cos-designer',
		datatypes: COS_DATATYPES,
		containers: COS_CONTAINERS,
		allowNativeDatatypes: false,
		nativeDatatypes: [],
		layoutSections: m_objLayout.sections
	});
}

// ------------------------------------------------------------
// files
// ------------------------------------------------------------

function cosListData(strSearch_a)
{
	var strLow = (strSearch_a || '').toLowerCase();
	var arrData = [];

	Object.keys(m_objProject.files).sort().forEach(function(strP_a)
	{
		if (strLow.length === 0 || strP_a.toLowerCase().indexOf(strLow) >= 0)
		{
			arrData.push([strP_a, strP_a, m_objProject.files[strP_a].length]);
		}
	});

	return {
		control: { offset: 0, limit: 99999, more: false, total: arrData.length },
		operations: [],
		fields: [
			{ code: 'ID', caption: 'ID', type: 'STRING', visible: false, sortable: false },
			{ code: 'PATH', caption: 'Path', type: 'STRING', visible: true, sortable: false },
			{ code: 'SIZE', caption: 'Bytes', type: 'NUMBER', visible: true, sortable: false }
		],
		data: arrData
	};
}

function cosMarkSelected()
{
	setTimeout(function()
	{
		$('#cos-filelist .gscr-list-row-selected').removeClass('gscr-list-row-selected');
		$('#cos-filelist tr').filter(function() { return $(this).attr('data-id') === m_strSel; }).addClass('gscr-list-row-selected');
	}, 20);
}

function cosRefreshProject()
{
	var arrMissing = m_objLayout ? cosMissing(m_objProject, m_objLayout) : [];
	var arrUnused = m_objLayout ? cosUnused(m_objProject, m_objLayout) : [];
	var intN = Object.keys(m_objProject.files).length;

	if (m_objList !== null)
	{
		m_objList.refresh();
		cosMarkSelected();
	}
	$('#cos-projectinfo').text(intN + ' files, ' + (m_objLayout ? cosParts(m_objLayout).length : 0) + ' parts');
	$('#cos-missing').html((arrMissing.length ? '<span class="cos-bad">' + arrMissing.length + ' missing: ' + cosEsc(arrMissing.slice(0, 5).join(', ')) + (arrMissing.length > 5 ? ' ...' : '') + '</span>' : '<span class="cos-ok">nothing missing</span>') + (arrUnused.length ? ' <span class="cos-warn" title="' + cosEsc(arrUnused.join('\n')) + '">' + arrUnused.length + ' not used by any part</span>' : ''));
}

function cosSelect(strPath_a)
{
	if (m_objProject.files[strPath_a] === undefined)
	{
		return;
	}
	m_strSel = strPath_a;
	m_objEditor.setValue(m_objProject.files[strPath_a]);
	$('#cos-filename').text('- ' + strPath_a);
	cosMarkSelected();
}

function cosImport(objInput_a)
{
	var objFiles = cosDirFiles(objInput_a);
	var strL = m_strLayout && objFiles[m_strLayout] ? m_strLayout : Object.keys(objFiles).filter(function(k) { return /^tools\/cosbuild\/[^\/]+\.layout\.json$/i.test(k); })[0];
	var pLayout = strL ? cosReadFile(objFiles[strL]).then(cosBytesStr) : Promise.resolve(m_objProject.files[m_strLayout] || '');

	cosStatus('importing ...');
	pLayout.then(function(strLayout_a)
	{
		var objL = null;
		var arrImports = [];
		var arrTake = [];
		var objNew = {};

		try { objL = JSON.parse(strLayout_a); } catch (e) { objL = { sections: [] }; }
		arrImports = cosImportsOf(objL);
		Object.keys(objFiles).forEach(function(strP_a)
		{
			var blnIn = arrImports.some(function(strI_a) { return strP_a === strI_a || strP_a.indexOf(strI_a.replace(/\/$/, '') + '/') === 0; });

			if (blnIn && !COS_SKIP.test(strP_a) && !/(^|\/)(test|screenshots)\//.test(strP_a) && !/(^|\/)\./.test(strP_a))
			{
				arrTake.push(strP_a);
			}
		});
		if (strL && arrTake.indexOf(strL) < 0)
		{
			arrTake.push(strL);
		}
		if (arrTake.length === 0)
		{
			window.alert('Nothing to import: pick the top folder (CyborgOS\'s: src/ and tools/ in it), its layout in tools/cosbuild/.');
			cosStatus('');
			return;
		}
		return arrTake.reduce(function(p, strP_a)
		{
			return p.then(function() { return cosReadFile(objFiles[strP_a]).then(function(arr) { objNew[strP_a] = cosBytesStr(arr); }); });
		}, Promise.resolve()).then(function()
		{
			m_objProject.files = objNew;
			m_strLayout = strL || m_strLayout;
			cosLayoutList();
			cosSetDirty(true);
			cosRefreshProject();
			cosStatus('imported ' + arrTake.length + ' files');
		});
	}).catch(function(e) { cosStatus('import: ' + e.message); });
}

function cosAddFiles(objInput_a)
{
	var arrFiles = Array.prototype.slice.call(objInput_a.files);
	var strFolder = window.prompt('Their folder in the project (src/bas/cyborgos320kb/help ...)', m_strSel.replace(/\/[^\/]*$/, ''));

	if (strFolder === null || arrFiles.length === 0)
	{
		return;
	}
	strFolder = strFolder.replace(/\\/g, '/').replace(/^\/+|\/+$/g, '');
	arrFiles.reduce(function(p, objF_a)
	{
		return p.then(function() { return cosReadFile(objF_a).then(function(arr) { m_objProject.files[(strFolder ? strFolder + '/' : '') + objF_a.name] = cosBytesStr(arr); }); });
	}, Promise.resolve()).then(function()
	{
		cosSetDirty(true);
		cosLayoutList();
		cosRefreshProject();
		cosStatus(arrFiles.length + ' files added');
	});
}

// ------------------------------------------------------------
// build: run the parts
// ------------------------------------------------------------

var COS_STATUS = { done: ['cos-ok', 'done'], wait: ['cos-warn', 'waits'], error: ['cos-bad', 'error'], todo: ['cos-dim', ''], note: ['cos-dim', 'note'], skip: ['cos-warn', 'skipped'] };

function cosRunNow()
{
	cosStatus('running ...');
	setTimeout(function()
	{
		try
		{
			m_objRun = cosRun({ project: m_objProject, layout: m_objLayout, stage: m_objStage, images: m_objImages, ticks: m_objTicks, compiled: m_objCompiled });
		}
		catch (e)
		{
			cosStatus('run: ' + e.message);
			return;
		}
		cosPartsTable();
		cosShowPart(m_strPart || (m_objRun.waiting ? m_objRun.waiting.part.name : ''));
		$('#cos-runinfo').html(m_objRun.done ? '<span class="cos-ok">done: build/ ready (' + Object.keys(m_objRun.build).length + ' files) - Save build/</span>' : (m_objRun.waiting ? '<span class="cos-warn">waits at ' + cosEsc(m_objRun.waiting.part.name) + '</span>' : '<span class="cos-bad">stopped: ' + cosEsc(m_objRun.errors[0] || '') + '</span>'));
		cosStatus('');
	}, 0);
}

function cosPartsTable()
{
	var arrH = ['<table><tr><th>Part</th><th>Type</th><th></th><th>What</th></tr>'];
	var strSection = null;

	(m_objRun ? m_objRun.parts : cosParts(m_objLayout).map(function(e) { return { name: e.part.name || e.part.caption, type: e.part.type, section: e.section, status: 'todo', text: '' }; })).forEach(function(r)
	{
		var arrS = COS_STATUS[r.status] || ['', r.status];

		if (r.section !== strSection)
		{
			strSection = r.section;
			arrH.push('<tr class="cos-sect"><td colspan="4">' + cosEsc(strSection) + '</td></tr>');
		}
		arrH.push('<tr class="cos-click' + (r.name === m_strPart ? ' cos-sel' : '') + '" data-part="' + cosEsc(r.name) + '"><td>' + cosEsc(r.name) + '</td><td class="cos-dim">' + cosEsc(r.type) + '</td><td class="' + arrS[0] + '">' + arrS[1] + '</td><td class="cos-what">' + cosEsc(r.text || '') + '</td></tr>');
	});
	arrH.push('</table>');
	$('#cos-parts').html(arrH.join(''));
}

function cosPartOf(strName_a)
{
	var arrP = cosParts(m_objLayout).filter(function(e) { return (e.part.name || e.part.caption) === strName_a; });

	return arrP.length ? arrP[0].part : null;
}

function cosShowPart(strName_a)
{
	var objP = cosPartOf(strName_a);
	var objRow = m_objRun ? m_objRun.parts.filter(function(r) { return r.name === strName_a; })[0] : null;
	var arrH = [];
	var strView = '';
	var objW = (m_objRun && m_objRun.waiting && m_objRun.waiting.part === objP) ? m_objRun.waiting : null;

	m_strPart = strName_a;
	$('#cos-partname').text(objP ? '- ' + strName_a + ' (' + objP.type + ')' : '');
	if (!objP)
	{
		$('#cos-partinfo').html('');
		m_objView.setValue('');
		return;
	}
	if (objRow && objRow.text)
	{
		arrH.push('<div class="' + (COS_STATUS[objRow.status] || [''])[0] + '">' + cosEsc(objRow.text) + '</div>');
	}
	arrH.push('<div class="cos-dim cos-helptext">' + cosEsc(cosHelpOf(objP.type)) + '</div>');
	if (objP.text)
	{
		arrH.push('<pre>' + cosEsc(objP.text) + '</pre>');
	}
	if (objP.type === 'checkbox')
	{
		arrH.push('<label><input type="checkbox" id="cos-tick"' + ((toBoolean(objP.done) || m_objTicks[objP.name]) ? ' checked' : '') + '> done</label>');
	}
	if (objP.type === 'ntcproject' || objP.type === 'asmfile')
	{
		arrH.push('<div class="cos-dim">' + cosEsc((objP.platform || 'asm') + (objP.consts ? ' - ' + objP.consts : '')) + '</div>');
		arrH.push('<div>' + cosLines(objP.type === 'asmfile' ? objP.file : objP.files).map(function(f) { return '<a href="#" class="cos-open" data-file="' + cosEsc(f) + '">' + cosEsc(f) + '</a>'; }).join('<br>') + '</div>');
		if (objRow && objRow.compile)
		{
			strView = objRow.compile.errors.map(function(s) { return 'ERR  ' + s; }).concat(objRow.compile.warnings.map(function(s) { return 'WARN ' + s; })).join('\n');
			strView = (strView ? strView + '\n\n' : '') + objRow.compile.asm;
		}
	}
	if (objP.type === 'external')
	{
		if (objW)
		{
			arrH.push('<div class="cos-warn">Waiting for: ' + cosEsc((objW.missing || []).slice(0, 8).join(', ')) + ((objW.missing || []).length > 8 ? ' ...' : '') + '</div>');
			arrH.push('<div>1 Save to the stage folder (its scripts ' + cosEsc(objP.name) + '.sh / .bat and what it is given are in it) &nbsp; 2 do the above &nbsp; 3 Attach the stage folder (or Read it again) - the run goes on</div>');
		}
		if (objP.give)
		{
			arrH.push('<div class="cos-dim">Give:</div><pre>' + cosEsc(objP.give) + '</pre>');
		}
		strView = (objRow && objRow.projects ? objRow.projects.map(function(t) { return 'cd ' + t.folder + ' && ' + cosCommandFor(objP, t); }).join('\n') : '');
	}
	if (['packz', 'arc', 'dsk', 'cardfolder', 'copy', 'installbas', 'imginstall', 'imgnew', 'textfile', 'cybinc', 'imports', 'autoexec'].indexOf(objP.type) >= 0)
	{
		strView = COS_DATATYPES.filter(function(d) { return d.type === objP.type; })[0].properties.map(function(pr)
		{
			return (objP[pr.name] !== undefined && objP[pr.name] !== '') ? '; ' + pr.label + '\n' + objP[pr.name] + '\n' : '';
		}).join('\n');
	}
	$('#cos-partinfo').html(arrH.join(''));
	m_objView.setValue(strView);
	cosPartsTable();
}

function cosSaveStage(blnZip_a)
{
	var objStage = m_objRun ? m_objRun.stage : null;

	if (!objStage)
	{
		window.alert('Run first.');
		return;
	}
	if (blnZip_a)
	{
		cosDownload('stage.zip', cosZip(objStage));
		return;
	}
	(m_hStage !== null ? Promise.resolve(m_hStage) : cosPickFolder('cosstage')).then(function(h)
	{
		if (h === null)
		{
			if (typeof window.showDirectoryPicker !== 'function')
			{
				cosDownload('stage.zip', cosZip(objStage));
			}
			return;
		}
		m_hStage = h;
		return h.requestPermission({ mode: 'readwrite' }).then(function() { return cosWriteFolder(h, objStage); }).then(function()
		{
			cosStatus('saved to ' + h.name + ' - run the waiting part\'s script there, then Read it again');
		});
	}).catch(function(e) { cosStatus('save: ' + e.message); });
}

function cosAttach(objInput_a)
{
	var objFiles = cosDirFiles(objInput_a);
	var objResult = {};
	var arrKeys = Object.keys(objFiles);

	cosStatus('reading ' + arrKeys.length + ' files ...');
	arrKeys.reduce(function(p, k) { return p.then(function() { return cosReadFile(objFiles[k]).then(function(arr) { objResult[k] = arr; }); }); }, Promise.resolve()).then(function()
	{
		m_objStage = objResult;
		cosRunNow();
	});
}

function cosReread()
{
	if (m_hStage === null)
	{
		window.alert('No stage folder picked in this session (Save to the stage folder) - attach it instead.');
		return;
	}
	cosStatus('reading the stage folder ...');
	m_hStage.requestPermission({ mode: 'readwrite' }).then(function() { return cosReadFolder(m_hStage); }).then(function(objFiles_a)
	{
		m_objStage = objFiles_a;
		cosRunNow();
	}).catch(function(e) { cosStatus('read: ' + e.message); });
}

function cosSaveBuild(blnZip_a)
{
	var objBuild = m_objRun ? m_objRun.build : {};

	if (Object.keys(objBuild).length === 0)
	{
		window.alert('Run first (to the end).');
		return;
	}
	if (blnZip_a)
	{
		cosDownload('build.zip', cosZip(objBuild));
		return;
	}
	cosPickFolder('cosbuild').then(function(h)
	{
		if (h === null)
		{
			cosDownload('build.zip', cosZip(objBuild));
			return;
		}
		return cosWriteFolder(h, objBuild);
	}).catch(function(e) { cosStatus('save: ' + e.message); });
}

function cosRunDiscs()
{
	var objB = m_objRun ? m_objRun.build : {};
	var arrD = [];

	Object.keys(objB).forEach(function(k)
	{
		var m = k.match(/cos-disk(\d+)\.dsk$/);

		if (m)
		{
			arrD.push({ n: parseInt(m[1], 10), data: objB[k] });
		}
	});
	return arrD;
}

// ------------------------------------------------------------
// 6 tools
// ------------------------------------------------------------

function cosDskOpen(objInput_a)
{
	var objF = objInput_a.files[0];

	if (!objF)
	{
		return;
	}
	cosReadFile(objF).then(function(arr)
	{
		var arrFiles = cosDskRead(arr);

		cosFreeUrls();
		$('#cos-dsklist').html('<div class="cos-pane-title">' + cosEsc(objF.name) + ': ' + arrFiles.length + ' files</div>' + cosTable(['Name', 'User', 'Bytes', 'AMSDOS', ''], arrFiles.map(function(f)
		{
			var objH = cosAmsdosOf(f.data);
			var arrT = cosFileTrim(f.data);

			return { cells: [f.name, String(f.user), { cls: 'cos-num', html: String(arrT.length) }, objH ? '#' + cosHex4(objH.load) + ' ' + objH.length : '', { html: '<a href="' + cosUrl(arrT) + '" download="' + cosEsc(f.name) + '">download</a>' }] };
		})));
	}).catch(function(e) { cosStatus('dsk: ' + e.message); });
}

function cosDskMakeFrom(objInput_a)
{
	var arrFiles = Array.prototype.slice.call(objInput_a.files);
	var arrOut = [];

	arrFiles.reduce(function(p, objF_a)
	{
		return p.then(function() { return cosReadFile(objF_a).then(function(arr) { arrOut.push({ name: objF_a.name.toUpperCase(), data: arr }); }); });
	}, Promise.resolve()).then(function()
	{
		var objD = cosDskMake(arrOut);

		cosDownload('disc.dsk', objD.image);
		cosStatus('disc.dsk: ' + arrOut.length + ' files, ' + objD.free + 'K free');
	}).catch(function(e) { window.alert('.dsk: ' + e.message); });
}

function cosImgFrom(arrFiles_a, strName_a)
{
	var intMb = parseInt($('#cos-imgmb').val(), 10) || 32;
	var objR = null;

	try
	{
		objR = cosFatImage(intMb, arrFiles_a);
	}
	catch (e)
	{
		window.alert('image: ' + e.message);
		return;
	}
	cosDownload(strName_a, objR.image);
	$('#cos-imginfo').text(strName_a + ': ' + intMb + ' MB, FAT' + objR.fat + ', ' + arrFiles_a.length + ' files');
}

function cosImgCpc(arrDsks_a)
{
	var objDisc = {};

	arrDsks_a.forEach(function(d) { objDisc[d.n] = d.data; });
	try
	{
		cosImgFrom(cosInstallSet(function(n) { return objDisc[n] || null; }, 'CYBORGOS/'), 'cyborgos.img');
	}
	catch (e)
	{
		window.alert('image: ' + e.message);
	}
}

// ------------------------------------------------------------
// save the page (the project in it)
// ------------------------------------------------------------

function cosPageText()
{
	return COS_PAGE.replace(/(<script type="application\/json" id="cos-project">)[\s\S]*?(<\/script>)/, function(a, b, c) { return b + cosProjectJson(m_objProject) + c; });
}

function cosSavePage()
{
	var strText = cosPageText();
	var arrBytes = new TextEncoder().encode(strText);

	if (typeof window.showSaveFilePicker === 'function')
	{
		window.showSaveFilePicker({ suggestedName: 'CyborgOSBuilder.htm', types: [{ description: 'CyborgOS Builder', accept: { 'text/html': ['.htm', '.html'] } }] }).then(function(h)
		{
			return h.createWritable().then(function(w) { return w.write(arrBytes).then(function() { return w.close(); }); });
		}).then(function()
		{
			cosSetDirty(false);
			cosStatus('page saved');
		}).catch(function() { /* cancelled */ });
		return;
	}
	cosDownload('CyborgOSBuilder.htm', arrBytes);
	cosSetDirty(false);
}


// ------------------------------------------------------------
// start
// ------------------------------------------------------------

$(function()
{
	var strJson = '';

	COS_PAGE = '<!DOCTYPE html>\n' + document.documentElement.outerHTML + '\n';	// (before anything changes the page)
	strJson = $('#cos-project').text();
	try
	{
		m_objProject = JSON.parse(strJson);
	}
	catch (e)
	{
		m_objProject = { name: 'CyborgOS', files: {} };
	}
	$('#cos-version').text(COS_VERSION);
	cosLayoutList();

	m_objEditor = new textEditor(api, 'cos-editor',
	{
		mode: 'CODE',
		language: 'sql',
		rows: 20,
		initialvalue: '',
		showlinenumbers: true,
		allowload: false,
		allowsave: true,
		cbOnChange: function(strValue_a)
		{
			if (m_strSel && m_objProject.files[m_strSel] !== strValue_a)
			{
				m_objProject.files[m_strSel] = strValue_a;
				cosSetDirty(true);
				if (m_strSel === m_strLayout)
				{
					m_objLayout = cosLayoutOf(m_objProject, m_strLayout);
					m_objDesigner = null;
				}
			}
		}
	});
	m_objView = new textEditor(api, 'cos-view', { mode: 'CODE', readonly: true, rows: 20, showstatus: false, showlinenumbers: false, initialvalue: '' });
	m_objList = new listRenderer(api, 'cos-filelist',
	{
		type: 'LIST',
		flow: 'EXPAND',
		target: '',
		initialData: cosListData(''),
		cbLoadData: function(objRequest_a, cbResult_a)
		{
			var strSearch = '';

			(objRequest_a.parameters || []).forEach(function(p) { if (p.name === 'search') { strSearch = p.value || ''; } });
			cbResult_a(cosListData(strSearch));
			cosMarkSelected();
		},
		cbOnClick: function(arrRow_a, strId_a)
		{
			cosSelect(strId_a);
		}
	});

	$('.cos-tab').on('click', function() { cosShow($(this).attr('data-page')); });
	$('#cos-layout').on('change', function() { m_strLayout = $(this).val(); cosLayoutList(); m_objRun = null; m_strPart = ''; cosPartsTable(); cosRefreshProject(); });
	$('#cos-newlayout').on('click', function()
	{
		var strName = window.prompt('The new layout\'s name (its file: tools/cosbuild/NAME.layout.json)', 'MyBuild');

		if (!strName)
		{
			return;
		}
		m_strLayout = 'tools/cosbuild/' + strName.replace(/[^A-Za-z0-9_-]/g, '') + '.layout.json';
		m_objProject.files[m_strLayout] = JSON.stringify({ name: strName, sections: [] }, null, '\t');
		cosLayoutList();
		cosSetDirty(true);
		cosShow('design');
	});
	$('#cos-savepage').on('click', cosSavePage);
	$('#cos-run').on('click', cosRunNow);
	$('#cos-parts').on('click', 'tr.cos-click', function() { cosShowPart($(this).attr('data-part')); });
	$('#cos-partinfo').on('click', 'a.cos-open', function(e) { e.preventDefault(); cosShow('files'); cosSelect($(this).attr('data-file')); });
	$('#cos-partinfo').on('change', '#cos-tick', function() { m_objTicks[m_strPart] = this.checked; cosRunNow(); });
	$('#cos-savestage').on('click', function() { cosSaveStage(false); });
	$('#cos-zipstage').on('click', function() { cosSaveStage(true); });
	$('#cos-attach').on('click', function() { $('#cos-attachdir').val('').trigger('click'); });
	$('#cos-attachdir').on('change', function() { cosAttach(this); });
	$('#cos-reread').on('click', cosReread);
	$('#cos-attachimg').on('click', function() { $('#cos-imginput').val('').trigger('click'); });
	$('#cos-imginput').on('change', function()
	{
		var f = this.files[0];

		if (!f)
		{
			return;
		}
		cosReadFile(f).then(function(arr)
		{
			cosParts(m_objLayout).forEach(function(e) { if (e.part.type === 'imginstall' && e.part.base) { m_objImages[e.part.base] = arr; } });
			cosStatus(f.name + ': the image the image parts start from');
			cosRunNow();
		});
	});
	$('#cos-savebuild').on('click', function() { cosSaveBuild(false); });
	$('#cos-zipbuild').on('click', function() { cosSaveBuild(true); });
	$('#cos-import').on('click', function() { $('#cos-importdir').val('').trigger('click'); });
	$('#cos-importdir').on('change', function() { cosImport(this); });
	$('#cos-addfiles').on('click', function() { $('#cos-addinput').val('').trigger('click'); });
	$('#cos-addinput').on('change', function() { cosAddFiles(this); });
	$('#cos-remove').on('click', function()
	{
		if (m_strSel && window.confirm('Remove ' + m_strSel + ' from the project?'))
		{
			delete m_objProject.files[m_strSel];
			m_strSel = '';
			m_objEditor.setValue('');
			cosSetDirty(true);
			cosRefreshProject();
		}
	});
	$('#cos-dskopen').on('click', function() { $('#cos-dskinput').val('').trigger('click'); });
	$('#cos-dskinput').on('change', function() { cosDskOpen(this); });
	$('#cos-dskmake').on('click', function() { $('#cos-dskfiles').val('').trigger('click'); });
	$('#cos-dskfiles').on('change', function() { cosDskMakeFrom(this); });
	$('#cos-dskblank').on('click', function() { cosDownload('blank.dsk', cosDskMake([]).image); });
	$('#cos-imgcpc').on('click', function()
	{
		var arrD = cosRunDiscs();

		if (arrD.length > 0)
		{
			cosImgCpc(arrD);
			return;
		}
		$('#cos-imgdsks').val('').trigger('click');
	});
	$('#cos-imgdsks').on('change', function()
	{
		var arrD = [];

		Array.prototype.slice.call(this.files).reduce(function(p, f)
		{
			return p.then(function() { return cosReadFile(f).then(function(arr) { var m = f.name.match(/(\d+)\.dsk$/i); arrD.push({ n: m ? parseInt(m[1], 10) : 1, data: arr }); }); });
		}, Promise.resolve()).then(function() { cosImgCpc(arrD); });
	});
	$('#cos-imgfolder').on('click', function() { $('#cos-imgdir').val('').trigger('click'); });
	$('#cos-imgdir').on('change', function()
	{
		var arrOut = [];

		Array.prototype.slice.call(this.files).reduce(function(p, f)
		{
			return p.then(function() { return cosReadFile(f).then(function(arr) { arrOut.push({ path: (f.webkitRelativePath || f.name).replace(/\\/g, '/'), data: arr }); }); });
		}, Promise.resolve()).then(function() { cosImgFrom(arrOut, 'disc.img'); });
	});
	$('#cos-instcpc').on('click', function()
	{
		var arrD = cosRunDiscs();
		var objDisc = {};

		arrD.forEach(function(d) { objDisc[d.n] = d.data; });
		if (objDisc[1] === undefined)
		{
			window.alert('Run to the end first (the discs come from the run).');
			return;
		}
		m_arrInstFiles = cosInstallSet(function(n) { return objDisc[n] || null; }, '');
		$('#cos-instimage').val('').trigger('click');
	});
	$('#cos-instfolder').on('click', function() { $('#cos-instdir').val('').trigger('click'); });
	$('#cos-instdir').on('change', function()
	{
		var objFiles = cosDirFiles(this);
		var arrOut = [];

		Object.keys(objFiles).reduce(function(p, k) { return p.then(function() { return cosReadFile(objFiles[k]).then(function(arr) { arrOut.push({ path: k, data: arr }); }); }); }, Promise.resolve()).then(function()
		{
			m_arrInstFiles = arrOut;
			$('#cos-instimage').val('').trigger('click');
		});
	});
	$('#cos-instimage').on('change', function()
	{
		var f = this.files[0];

		if (!f || m_arrInstFiles === null)
		{
			return;
		}
		cosStatus('installing into ' + f.name + ' ...');
		cosReadFile(f).then(function(arr)
		{
			var objR = cosFatInstall(arr, m_arrInstFiles, $('#cos-instdest').val() || '/');

			cosDownload(f.name, objR.image);
			$('#cos-instinfo').text(f.name + ': ' + objR.files + ' files in (FAT' + objR.fat + (objR.sparse ? ', WinAPE IDE image' : '') + ') - downloaded');
			cosStatus('');
		}).catch(function(e) { window.alert('install: ' + e.message); cosStatus(''); });
	});
	window.addEventListener('beforeunload', function(e)
	{
		if (m_blnDirty)
		{
			e.preventDefault();
			e.returnValue = '';
		}
	});

	cosRefreshProject();
	cosPartsTable();
	cosShow('build');
});
