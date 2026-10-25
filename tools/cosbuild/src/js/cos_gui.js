// CyborgOS Builder - the page (no node: everything here runs in the browser). The project is a
// folder - CyborgOS's: Open the folder. Chrome / Edge (File System Access): it is read and written
// in place - the project's files, build/stage (what the external tools are given and bring back),
// build/ (what the build makes). Other browsers: the folder is read (Open, read only), the stage
// folder attached, what is made downloaded. Build (the layout's parts run in order), Design (the
// layout in CyborgDesigner), Files, Tools. NTC BASIC's components (textEditor, listRenderer) and
// CyborgDesigner's. ES5. (c) 2026 Cyborg Unicorn Pty Ltd - MIT License

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

var m_objSrc = null;			// the folder: { kind: 'fsa', root: handle, name } or { kind: 'files', files: { path: File }, name }
var m_objProject = { name: '', files: {} };
var m_strLayout = '';			// the layout's path (tools/cosbuild/NAME.layout.json)
var m_arrLayouts = [];
var m_objLayout = { name: '', sections: [] };
var m_strSel = '';
var m_objEditor = null;
var m_objView = null;
var m_objList = null;
var m_objDesigner = null;
var m_objRun = null;			// the last run
var m_objCompiled = {};			// compiles kept between runs (same sources: same result)
var m_strPart = '';			// the part shown
var m_objStage = {};			// what is in the stage folder: { path: bytes }
var m_objImages = {};			// images parts start from (attached): { build path: bytes }
var m_objTicks = {};
var m_objUnsaved = {};			// files changed here, not written to the folder yet (read only folder)
var m_arrUrls = [];
var m_arrInstFiles = null;
var m_intSaveTimer = 0;
var m_blnBusy = false;

function cosEsc(str_a)
{
	return String(str_a).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function cosStatus(str_a)
{
	$('#cos-status').text(str_a);
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
// the folder
// ------------------------------------------------------------

function cosFsa()
{
	return m_objSrc !== null && m_objSrc.kind === 'fsa';
}

// a handle in the folder by its path ('' the folder itself): null when it isn't there
function cosFsGet(strPath_a, blnDir_a, blnCreate_a)
{
	var arrParts = strPath_a.split('/').filter(function(s) { return s.length > 0; });
	var strLast = arrParts.pop();
	var p = Promise.resolve(m_objSrc.root);

	arrParts.forEach(function(s)
	{
		p = p.then(function(h) { return h ? h.getDirectoryHandle(s, { create: !!blnCreate_a }) : null; });
	});
	if (strLast === undefined)
	{
		return p;
	}

	return p.then(function(h)
	{
		if (!h)
		{
			return null;
		}
		return blnDir_a ? h.getDirectoryHandle(strLast, { create: !!blnCreate_a }) : h.getFileHandle(strLast, { create: !!blnCreate_a });
	}).catch(function() { return null; });
}

// a folder's names: [{ name, kind }]
function cosFsList(hDir_a)
{
	var it = hDir_a.values();
	var arrResult = [];

	function next()
	{
		return it.next().then(function(r)
		{
			if (r.done)
			{
				return arrResult;
			}
			arrResult.push({ name: r.value.name, kind: r.value.kind, handle: r.value });
			return next();
		});
	}
	return next();
}

// a file in the folder: its bytes, null when it isn't there
function cosSrcRead(strPath_a)
{
	if (cosFsa())
	{
		return cosFsGet(strPath_a, false, false).then(function(h) { return h ? h.getFile().then(cosReadFile) : null; });
	}
	return m_objSrc.files[strPath_a] ? cosReadFile(m_objSrc.files[strPath_a]) : Promise.resolve(null);
}

// files written into the folder (Chrome / Edge): { path: bytes or text }, only those that differ
// from what is there (objOld_a: what is there, when known)
function cosSrcWrite(objFiles_a, objOld_a)
{
	var objNew = {};

	Object.keys(objFiles_a).forEach(function(k)
	{
		var v = objFiles_a[k];
		var arr = (typeof v === 'string') ? cosStrBytes(v) : v;

		if (!objOld_a || objOld_a[k] === undefined || !cosSame(objOld_a[k], arr))
		{
			objNew[k] = arr;
		}
	});
	return cosWriteFolder(m_objSrc.root, objNew).then(function() { return Object.keys(objNew).length; });
}

// the files under a folder of the folder (build/stage ...): { path in it: bytes }
function cosSrcTree(strDir_a)
{
	var objResult = {};

	if (cosFsa())
	{
		return cosFsGet(strDir_a, true, false).then(function(h) { return h ? cosReadFolder(h) : {}; });
	}
	Object.keys(m_objSrc.files).forEach(function(k)
	{
		if (k.indexOf(strDir_a + '/') === 0)
		{
			objResult[k.substr(strDir_a.length + 1)] = m_objSrc.files[k];
		}
	});
	return Object.keys(objResult).reduce(function(p, k)
	{
		return p.then(function() { return cosReadFile(objResult[k]).then(function(a) { objResult[k] = a; }); });
	}, Promise.resolve()).then(function() { return objResult; });
}

// the layouts in the folder: tools/cosbuild/*.layout.json
function cosSrcLayouts()
{
	if (cosFsa())
	{
		return cosFsGet('tools/cosbuild', true, false).then(function(h)
		{
			return h ? cosFsList(h).then(function(a) { return a.filter(function(e) { return e.kind === 'file' && /\.layout\.json$/i.test(e.name); }).map(function(e) { return 'tools/cosbuild/' + e.name; }).sort(); }) : [];
		});
	}
	return Promise.resolve(Object.keys(m_objSrc.files).filter(function(k) { return /^tools\/cosbuild\/[^\/]+\.layout\.json$/i.test(k); }).sort());
}

// the project: the files the layout's Imports part names (and the layout), read from the folder
function cosSrcProject(strLayout_a)
{
	var objFiles = {};

	return cosSrcRead(strLayout_a).then(function(arrL_a)
	{
		var objL = null;
		var arrImports = [];

		if (arrL_a === null)
		{
			throw new Error('no ' + strLayout_a + ' in the folder');
		}
		objFiles[strLayout_a] = cosBytesStr(arrL_a);
		objL = JSON.parse(cosBytesStr(arrL_a));
		arrImports = cosImportsOf(objL);
		if (!cosFsa())
		{
			return Object.keys(m_objSrc.files).filter(function(k) { return cosImportWanted(k, arrImports); }).reduce(function(p, k)
			{
				return p.then(function() { return cosReadFile(m_objSrc.files[k]).then(function(a) { objFiles[k] = cosBytesStr(a); }); });
			}, Promise.resolve());
		}
		// (Chrome / Edge: each import a folder or a file, walked)
		return arrImports.reduce(function(p, strI_a)
		{
			return p.then(function()
			{
				return cosFsGet(strI_a, true, false).then(function(hD)
				{
					if (hD)
					{
						return cosReadFolder(hD).then(function(o)
						{
							Object.keys(o).forEach(function(k) { if (cosImportWanted(strI_a + '/' + k, arrImports)) { objFiles[strI_a + '/' + k] = cosBytesStr(o[k]); } });
						});
					}
					return cosSrcRead(strI_a).then(function(a) { if (a !== null) { objFiles[strI_a] = cosBytesStr(a); } });
				});
			});
		}, Promise.resolve());
	}).then(function() { return { name: m_objSrc.name, files: objFiles }; });
}

// open the CyborgOS folder: read and write (Chrome / Edge), else read only (the folder input)
function cosOpenFolder()
{
	if (typeof window.showDirectoryPicker !== 'function')
	{
		$('#cos-opendir').val('').trigger('click');
		return;
	}
	window.showDirectoryPicker({ id: 'cosroot', mode: 'readwrite' }).then(function(h)
	{
		m_objSrc = { kind: 'fsa', root: h, name: h.name };
		return cosLoad();
	}).catch(function(e) { if (e && e.name !== 'AbortError') { cosStatus('open: ' + e.message); } });
}

function cosOpenFiles(objInput_a)
{
	var objFiles = cosDirFiles(objInput_a);
	var arrAll = Array.prototype.slice.call(objInput_a.files);

	if (arrAll.length === 0)
	{
		return;
	}
	m_objSrc = { kind: 'files', files: objFiles, name: (arrAll[0].webkitRelativePath || '').split('/')[0] || 'folder' };
	cosLoad();
}

// (re)load the project from the folder: its layouts, the one chosen, its files
function cosLoad()
{
	if (m_objSrc === null)
	{
		return Promise.resolve();
	}
	cosStatus('reading ' + m_objSrc.name + ' ...');
	return cosSrcLayouts().then(function(arrL_a)
	{
		m_arrLayouts = arrL_a;
		if (arrL_a.length === 0)
		{
			throw new Error(m_objSrc.name + ' has no tools/cosbuild/*.layout.json - open the CyborgOS folder (the one with src/ and tools/ in it)');
		}
		if (arrL_a.indexOf(m_strLayout) < 0)
		{
			m_strLayout = arrL_a[0];
		}
		return cosSrcProject(m_strLayout);
	}).then(function(objP_a)
	{
		m_objProject = objP_a;
		m_objLayout = cosLayoutOf(m_objProject, m_strLayout);
		m_objDesigner = null;
		m_objUnsaved = {};
		m_objRun = null;
		m_strPart = '';
		cosShowFolder();
		cosRefreshProject();
		cosPartsTable();
		cosStatus('');
	}).catch(function(e)
	{
		cosStatus('');
		window.alert(e.message);
	});
}

function cosShowFolder()
{
	var objSel = $('#cos-layout');

	$('#cos-start').toggle(m_objSrc === null);
	$('#cos-main').css('display', m_objSrc !== null ? 'flex' : 'none');
	$('#cos-folder').text(m_objSrc ? m_objSrc.name + (cosFsa() ? '' : ' (read only)') : '');
	objSel.empty();
	m_arrLayouts.forEach(function(k) { objSel.append($('<option></option>').val(k).text(k.replace(/^.*\//, '').replace(/\.layout\.json$/i, ''))); });
	objSel.val(m_strLayout);
	// (read and write: the stage folder and build/ are the folder's - no buttons for them)
	$('.cos-ro').toggle(!cosFsa());
	$('.cos-rw').toggle(cosFsa());
}

// a project file changed here: written to the folder (Chrome / Edge) a moment later, else kept to download
function cosChanged(strPath_a)
{
	m_objUnsaved[strPath_a] = true;
	cosShowUnsaved();
	if (!cosFsa())
	{
		return;
	}
	clearTimeout(m_intSaveTimer);
	m_intSaveTimer = setTimeout(cosSaveChanged, 700);
}

function cosSaveChanged()
{
	var objW = {};

	Object.keys(m_objUnsaved).forEach(function(k) { objW[k] = m_objProject.files[k]; });
	if (!cosFsa() || Object.keys(objW).length === 0)
	{
		return Promise.resolve();
	}
	return cosWriteFolder(m_objSrc.root, objW).then(function()
	{
		m_objUnsaved = {};
		cosShowUnsaved();
	}).catch(function(e) { cosStatus('save: ' + e.message); });
}

function cosShowUnsaved()
{
	var arrK = Object.keys(m_objUnsaved);

	$('#cos-dirty').text(arrK.length === 0 ? '' : (cosFsa() ? 'saving ...' : arrK.length + ' changed here: Download changed files'));
}

// ------------------------------------------------------------
// tabs, the layout
// ------------------------------------------------------------

function cosShow(strPage_a)
{
	$('.cos-tab').removeClass('cos-on');
	$('.cos-tab[data-page="' + strPage_a + '"]').addClass('cos-on');
	$('.cos-page').removeClass('cos-on');
	$('.cos-page[data-page="' + strPage_a + '"]').addClass('cos-on');
	if (strPage_a === 'design')
	{
		cosDesigner();
	}
}

// the layout back into its file (the designer changes it in place)
function cosLayoutSave()
{
	var strNew = JSON.stringify(m_objLayout, null, '\t');

	if (m_strLayout && JSON.stringify(JSON.parse(m_objProject.files[m_strLayout] || '{}')) !== JSON.stringify(m_objLayout))
	{
		m_objProject.files[m_strLayout] = strNew;
		cosChanged(m_strLayout);
		cosRefreshProject();
	}
}

function cosDesigner()
{
	if (m_objDesigner !== null || typeof cyborgDesigner !== 'function' || m_objSrc === null)
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

function cosNewLayout()
{
	var strName = window.prompt('The new layout\'s name (its file: tools/cosbuild/NAME.layout.json)', 'MyBuild');

	if (!strName)
	{
		return;
	}
	m_strLayout = 'tools/cosbuild/' + strName.replace(/[^A-Za-z0-9_-]/g, '') + '.layout.json';
	m_objProject.files[m_strLayout] = JSON.stringify({ name: strName, sections: [] }, null, '\t');
	m_objLayout = cosLayoutOf(m_objProject, m_strLayout);
	if (m_arrLayouts.indexOf(m_strLayout) < 0)
	{
		m_arrLayouts.push(m_strLayout);
	}
	m_objDesigner = null;
	cosChanged(m_strLayout);
	cosShowFolder();
	cosShow('design');
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
	var arrMissing = cosMissing(m_objProject, m_objLayout);
	var arrUnused = cosUnused(m_objProject, m_objLayout);
	var intN = Object.keys(m_objProject.files).length;

	if (m_objList !== null)
	{
		m_objList.refresh();
		cosMarkSelected();
	}
	$('#cos-projectinfo').text(m_objSrc ? intN + ' files, ' + cosParts(m_objLayout).length + ' parts' : '');
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

function cosAddFiles(objInput_a)
{
	var arrFiles = Array.prototype.slice.call(objInput_a.files);
	var strFolder = window.prompt('Their folder in CyborgOS\'s (src/bas/cyborgos320kb/help ...)', m_strSel.replace(/\/[^\/]*$/, ''));

	if (strFolder === null || arrFiles.length === 0)
	{
		return;
	}
	strFolder = strFolder.replace(/\\/g, '/').replace(/^\/+|\/+$/g, '');
	arrFiles.reduce(function(p, objF_a)
	{
		return p.then(function()
		{
			return cosReadFile(objF_a).then(function(arr)
			{
				var strP = (strFolder ? strFolder + '/' : '') + objF_a.name;

				m_objProject.files[strP] = cosBytesStr(arr);
				cosChanged(strP);
			});
		});
	}, Promise.resolve()).then(function()
	{
		cosRefreshProject();
		cosStatus(arrFiles.length + ' files added');
	});
}

function cosDownloadChanged()
{
	var objW = {};

	Object.keys(m_objUnsaved).forEach(function(k) { objW[k] = m_objProject.files[k]; });
	if (Object.keys(objW).length === 0)
	{
		window.alert('Nothing changed here.');
		return;
	}
	cosDownload('changed.zip', cosZip(objW));
}

// ------------------------------------------------------------
// build: run the parts
// ------------------------------------------------------------

var COS_STATUS = { done: ['cos-ok', 'done'], wait: ['cos-warn', 'waits'], error: ['cos-bad', 'error'], todo: ['cos-dim', ''], note: ['cos-dim', 'note'], skip: ['cos-warn', 'skipped'] };

// Run: (read and write) the project and build/stage read from the folder, the parts run, then
// build/stage and build/ written; (read only) the attached stage folder, nothing written
function cosRunNow()
{
	var pPrep = Promise.resolve();
	var objStageNow = null;

	if (m_objSrc === null || m_blnBusy)
	{
		return;
	}
	m_blnBusy = true;
	$('#cos-run').prop('disabled', true);
	cosStatus('reading ...');
	if (cosFsa())
	{
		pPrep = cosSaveChanged().then(function() { return cosSrcProject(m_strLayout); }).then(function(objP_a)
		{
			m_objProject = objP_a;
			m_objLayout = cosLayoutOf(m_objProject, m_strLayout);
			m_objDesigner = null;
			return cosSrcTree('build/stage');
		}).then(function(objS_a)
		{
			objStageNow = objS_a;
			// the images parts start from: build/BASE in the folder (unless one is attached)
			return cosParts(m_objLayout).reduce(function(p, e)
			{
				return p.then(function()
				{
					var strB = e.part.type === 'imginstall' ? e.part.base : '';

					if (!strB || m_objImages[strB] !== undefined)
					{
						return null;
					}
					return cosSrcRead('build/' + strB).then(function(a) { if (a) { m_objImages[strB] = a; } });
				});
			}, Promise.resolve());
		});
	}
	pPrep.then(function()
	{
		cosStatus('running ...');
		return new Promise(function(fnOk_a) { setTimeout(fnOk_a, 0); });
	}).then(function()
	{
		m_objRun = cosRun({ project: m_objProject, layout: m_objLayout, stage: objStageNow || m_objStage, images: m_objImages, ticks: m_objTicks, compiled: m_objCompiled });
		if (!cosFsa())
		{
			return null;
		}
		cosStatus('writing build/stage ...');
		return cosSrcWrite(prefix(m_objRun.stage, 'build/stage/'), prefix(objStageNow, 'build/stage/')).then(function(n)
		{
			cosStatus('writing build/ ...');
			return cosSrcWrite(prefix(m_objRun.build, 'build/'), null);
		});
	}).then(function()
	{
		cosPartsTable();
		cosShowPart(m_strPart || (m_objRun.waiting ? m_objRun.waiting.part.name : ''));
		cosRunInfo();
		cosStatus('');
	}).catch(function(e)
	{
		cosStatus('run: ' + e.message);
	}).then(function()
	{
		m_blnBusy = false;
		$('#cos-run').prop('disabled', false);
	});

	function prefix(objF_a, strP_a)
	{
		var objR = {};

		Object.keys(objF_a || {}).forEach(function(k) { objR[strP_a + k] = objF_a[k]; });
		return objR;
	}
}

function cosRunInfo()
{
	var objW = m_objRun ? m_objRun.waiting : null;
	var strH = '';

	if (!m_objRun)
	{
		strH = '';
	}
	else if (m_objRun.done)
	{
		strH = '<span class="cos-ok">done: ' + Object.keys(m_objRun.build).length + ' files ' + (cosFsa() ? 'in ' + cosEsc(m_objSrc.name) + '/build/' : 'made - download build/') + '</span>';
	}
	else if (objW)
	{
		strH = '<span class="cos-warn">waits at ' + cosEsc(objW.part.name) + (objW.part.type === 'external' ? (cosFsa() ? ': run ' + cosEsc(objW.part.name) + '.bat (or .sh) in ' + cosEsc(m_objSrc.name) + '/build/stage, then Run again' : ': Save the stage files, run ' + cosEsc(objW.part.name) + '.bat (.sh) there, Attach the stage folder') : ': tick it, then Run again') + '</span>';
	}
	else
	{
		strH = '<span class="cos-bad">stopped: ' + cosEsc(m_objRun.errors[0] || '') + '</span>';
	}
	$('#cos-runinfo').html(strH);
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
			arrH.push(cosFsa() ? '<div>Its scripts and what it is given are in ' + cosEsc(m_objSrc.name) + '/build/stage already: run ' + cosEsc(objP.name) + '.bat (Windows) or sh ' + cosEsc(objP.name) + '.sh there, then Run.</div>' : '<div>1 Save the stage files (its scripts ' + cosEsc(objP.name) + '.bat / .sh and what it is given are in them) &nbsp; 2 run the script there &nbsp; 3 Attach the stage folder - the run goes on</div>');
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

// (read only) the stage files to a folder picked, else a zip
function cosSaveStage(blnZip_a)
{
	var objStage = m_objRun ? m_objRun.stage : null;

	if (!objStage)
	{
		window.alert('Run first.');
		return;
	}
	cosDownload('stage.zip', cosZip(objStage));
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

function cosSaveBuild()
{
	var objBuild = m_objRun ? m_objRun.build : {};

	if (Object.keys(objBuild).length === 0)
	{
		window.alert('Run first (to the end).');
		return;
	}
	cosDownload('build.zip', cosZip(objBuild));
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
// start
// ------------------------------------------------------------

$(function()
{
	$('#cos-version').text(COS_VERSION);
	if (typeof window.showDirectoryPicker !== 'function')
	{
		$('#cos-startnote').text('This browser can only read the folder (Chrome or Edge can write to it: the stage folder and build/ then need no saving or attaching).');
	}

	m_objEditor = new textEditor(api, 'cos-editor',
	{
		mode: 'CODE',
		language: 'sql',
		rows: 20,
		initialvalue: '',
		showlinenumbers: true,
		allowload: false,
		allowsave: false,
		cbOnChange: function(strValue_a)
		{
			if (m_strSel && m_objProject.files[m_strSel] !== strValue_a)
			{
				m_objProject.files[m_strSel] = strValue_a;
				cosChanged(m_strSel);
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

	$('.cos-open-folder').on('click', cosOpenFolder);
	$('#cos-opendir').on('change', function() { cosOpenFiles(this); });
	$('#cos-reload').on('click', function() { cosLoad(); });
	$('.cos-tab').on('click', function() { cosShow($(this).attr('data-page')); });
	$('#cos-layout').on('change', function() { m_strLayout = $(this).val(); cosLoad(); });
	$('#cos-newlayout').on('click', cosNewLayout);
	$('#cos-run').on('click', cosRunNow);
	$('#cos-parts').on('click', 'tr.cos-click', function() { cosShowPart($(this).attr('data-part')); });
	$('#cos-partinfo').on('click', 'a.cos-open', function(e) { e.preventDefault(); cosShow('files'); cosSelect($(this).attr('data-file')); });
	$('#cos-partinfo').on('change', '#cos-tick', function() { m_objTicks[m_strPart] = this.checked; cosRunNow(); });
	$('#cos-zipstage').on('click', function() { cosSaveStage(true); });
	$('#cos-attach').on('click', function() { $('#cos-attachdir').val('').trigger('click'); });
	$('#cos-attachdir').on('change', function() { cosAttach(this); });
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
		});
	});
	$('#cos-zipbuild').on('click', cosSaveBuild);
	$('#cos-addfiles').on('click', function() { $('#cos-addinput').val('').trigger('click'); });
	$('#cos-addinput').on('change', function() { cosAddFiles(this); });
	$('#cos-dlchanged').on('click', cosDownloadChanged);
	$('#cos-remove').on('click', function()
	{
		if (m_strSel && window.confirm('Take ' + m_strSel + ' out of the project here? (The file in the folder stays.)'))
		{
			delete m_objProject.files[m_strSel];
			m_strSel = '';
			m_objEditor.setValue('');
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
		if (Object.keys(m_objUnsaved).length > 0)
		{
			e.preventDefault();
			e.returnValue = '';
		}
	});

	cosShowFolder();
	cosShow('build');
});
