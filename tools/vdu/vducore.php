<?php
// vducore.php - VDU's server side (vdu.php the requests, text.php and dumb.php the pages): VDU - remote displays over plain HTTP GETs, no database: each screen is an append-only text
// file of display commands (one a line) and an index of where each line starts. A writer (any
// program - a CPC through CyborgOS's NET, a PC, a script) appends lines; a viewer (a browser, a
// CPC, a Nintendo DS's dumb page) asks for the lines past the pointer it has, draws them and keeps
// the new pointer. Pointer 0 replays the screen from its start; -1 joins it live (from its last
// MODE - the last point a screen was cleared whole). Any number of viewers: spectators need only
// the screen's id; writing needs its key too. A private screen is left out of the list: it is
// seen only by those it is shared with (its id).
//
// Every answer is plain text (the first line "ok ..." or "error why"):
//   ?a=new&t=title[&p=0]            a screen: "ok id key" (p=0: private - not listed); the id 8
//                                   hex digits, the key 16 (only its hash is kept)
//   ?a=put&s=id&k=key&c=line        lines appended (several: %0A between them): "ok total"
//   ?a=get&s=id&n=pointer[&m=lines][&b=bytes]
//                                   "ok start next total" then the lines from start (n; -1:
//                                   the last MODE; past the end - the screen wiped -: from 0) to
//                                   next - 1: at most m lines (100), b bytes (16000)
//   ?a=ping&w=id:pointer,id:pointer the screens (of those) with lines past their pointer: "ok id id"
//   ?a=list                         the public screens: "ok n", then "id lines updated title" each
//   ?a=info&s=id                    "ok lines updated public title"
//   ?a=wipe&s=id&k=key              the screen emptied (viewers start again from 0): "ok 0"
// The way back - the viewers to the writer: a screen's ZONE commands mark touch zones; a tap in
// one (or a key) is an event, appended to the screen's events (a log of its own, with its own
// pointer). put's answer carries the events' count, so a writer knows there are some without
// asking:
//   ?a=event&s=id&e=line            an event appended (TOUCH name x y, KEY n ...): "ok events"
//   ?a=events&s=id&k=key&n=pointer[&m=lines]
//                                   "ok start next total" then the events from start (n) on
//   put's answer is then "ok total events"
// The commands themselves are the viewers' business (README.md): MODE, CLS, PRINT, LOCATE ...

$g_strData = __DIR__ . '/data';
$g_intMaxLine = 250;          // a line's characters at most
$g_intMaxLines = 200000;      // a screen's lines at most


// ---- the 8BML dialect (vdu1): a line of commands in 8BML's way - a letter, its parameters (a
// comma between them; "text" quoted, \" a quote in it, \\ a backslash; a number bare), a colon
// between commands: m1:l5,5:p"Hello":i1,24. A line starting with a small letter or - is one; any
// other is the word form (MODE 1). Both may be written to a screen, and every reader takes both.
//   -"vdu1","title" TITLE     m n MODE           c CLS              p "t" PRINT t
//   t "t" PRINT t; (no new line)                  l x,y LOCATE       f i PEN
//   a i PAPER       i i,c INK         b c BORDER         s n STREAM         w l,r,t,b WINDOW
//   h x,y ORIGIN    v x,y MOVE        d x,y DRAW         x x,y PLOT         g i GPEN
//   e [i] CLG       r x,y,w,h BOX     u x,y,w,h FILL     o x,y,r CIRCLE
//   z "name",x,y,w,h ZONE (z alone: ZONE OFF)            k CHECKPOINT (the writer: the screen is
//   whole from here - a viewer joining live may start here)
$g_arrVduWords = array('m' => 'MODE', 'c' => 'CLS', 'p' => 'PRINT', 't' => 'PRINT', 'l' => 'LOCATE',
	'f' => 'PEN', 'a' => 'PAPER', 'i' => 'INK', 'b' => 'BORDER', 's' => 'STREAM', 'w' => 'WINDOW',
	'h' => 'ORIGIN', 'v' => 'MOVE', 'd' => 'DRAW', 'x' => 'PLOT', 'g' => 'GPEN', 'e' => 'CLG',
	'r' => 'BOX', 'u' => 'FILL', 'o' => 'CIRCLE', 'z' => 'ZONE', 'k' => 'CHECKPOINT', '-' => 'TITLE');

// the line's commands in the word form (a word-form line: itself)
function vduExpand($strLine_a)
{
	global $g_arrVduWords;
	$arrResult = array();
	$strLine = ltrim($strLine_a);
	if ($strLine === '' || !preg_match('/^[a-z\-]/', $strLine))
	{
		if ($strLine !== '')
		{
			$arrResult[] = $strLine;
		}
	}
	else
	{
		$intLen = strlen($strLine);
		$intI = 0;
		while ($intI < $intLen)
		{
			$strCmd = $strLine[$intI];
			$intI++;
			if ($intI < $intLen && $strLine[$intI] === ',')
			{
				$intI++;                     // (m,1 as well as m1)
			}
			$arrParams = array();
			$strParam = '';
			$blnAny = false;
			while ($intI < $intLen && $strLine[$intI] !== ':')
			{
				$strC = $strLine[$intI];
				if ($strC === '"')
				{
					$intI++;
					while ($intI < $intLen && $strLine[$intI] !== '"')
					{
						if ($strLine[$intI] === '\\' && $intI + 1 < $intLen)
						{
							$intI++;
						}
						$strParam .= $strLine[$intI];
						$intI++;
					}
					$intI++;
					$blnAny = true;
				}
				elseif ($strC === ',')
				{
					$arrParams[] = $strParam;
					$strParam = '';
					$blnAny = false;
					$intI++;
				}
				else
				{
					$strParam .= $strC;
					$blnAny = true;
					$intI++;
				}
			}
			if ($blnAny || count($arrParams) > 0)
			{
				$arrParams[] = $strParam;
			}
			$intI++;                         // (past the colon)
			if (isset($g_arrVduWords[$strCmd]))
			{
				$strWord = $g_arrVduWords[$strCmd];
				if ($strCmd === 'p' || $strCmd === 't')
				{
					$strWord .= ' ' . (count($arrParams) > 0 ? $arrParams[0] : '') . ($strCmd === 't' ? ';' : '');
				}
				elseif ($strCmd === '-')
				{
					$strWord .= ' ' . (count($arrParams) > 1 ? $arrParams[1] : (count($arrParams) > 0 ? $arrParams[0] : ''));
				}
				elseif ($strCmd === 'z' && count($arrParams) === 0)
				{
					$strWord .= ' OFF';
				}
				elseif (count($arrParams) > 0)
				{
					$strWord .= ' ' . implode(' ', $arrParams);
				}
				if ($strCmd === 'p' && substr($strWord, -1) === ';')
				{
					$arrResult[] = $strWord . ';';   // (text ending in ; - which the word form reads as no new line:
					$strWord = 'PRINT';              //  the text kept, then the new line on its own)
				}
				$arrResult[] = $strWord;
			}
		}
	}
	return $arrResult;
}

// ---- the screen's checkpoints: where a viewer joining live may start - a MODE, a CLS of a window
// that is the whole screen, the writer's CHECKPOINT. win.txt keeps what that takes: the mode's
// columns, the stream, which streams' windows are the whole screen
function vduMarks($strID_a)
{
	$strFile = screenDir($strID_a) . '/win.txt';
	$arrResult = array('cols' => 40, 'stream' => 0, 'full' => array(1, 1, 1, 1, 1, 1, 1, 1));
	if (is_file($strFile))
	{
		$arrRead = json_decode(file_get_contents($strFile), true);
		if (is_array($arrRead))
		{
			$arrResult = $arrRead;
		}
	}
	return $arrResult;
}

// a command (word form): true when the screen is whole from it (the state in $arrMarks_a kept)
function vduMark(&$arrMarks_a, $strCmd_a)
{
	$blnResult = false;
	$arrW = preg_split('/\s+/', trim($strCmd_a));
	$strW = strtoupper($arrW[0]);
	if ($strW === 'MODE')
	{
		$intM = (count($arrW) > 1 ? (int)$arrW[1] : 1);
		$arrMarks_a['cols'] = ($intM === 0 ? 20 : ($intM === 2 ? 80 : 40));
		$arrMarks_a['stream'] = 0;
		$arrMarks_a['full'] = array(1, 1, 1, 1, 1, 1, 1, 1);
		$blnResult = true;
	}
	elseif ($strW === 'CHECKPOINT')
	{
		$blnResult = true;
	}
	elseif ($strW === 'STREAM' && count($arrW) > 1)
	{
		$arrMarks_a['stream'] = max(0, min(7, (int)$arrW[1]));
	}
	elseif ($strW === 'WINDOW' && count($arrW) > 4)
	{
		$intL = min((int)$arrW[1], (int)$arrW[2]);
		$intR = max((int)$arrW[1], (int)$arrW[2]);
		$intT = min((int)$arrW[3], (int)$arrW[4]);
		$intB = max((int)$arrW[3], (int)$arrW[4]);
		$arrMarks_a['full'][$arrMarks_a['stream']] = ($intL <= 1 && $intT <= 1 && $intR >= $arrMarks_a['cols'] && $intB >= 25) ? 1 : 0;
	}
	elseif ($strW === 'CLS')
	{
		$blnResult = ($arrMarks_a['full'][$arrMarks_a['stream']] === 1);
	}
	return $blnResult;
}

// a parameter ('' when not given): the URL's, or a POST's form's
function param($strName_a)
{
	$strResult = '';
	if (isset($_GET[$strName_a]))
	{
		$strResult = (string)$_GET[$strName_a];
	}
	elseif (isset($_POST[$strName_a]))
	{
		$strResult = (string)$_POST[$strName_a];   // (a POST's form: a writer's lines, no URL to fit in)
	}
	return $strResult;
}

// a screen's id: 8 hex digits
function validID($strID_a)
{
	return (preg_match('/^[0-9a-f]{8}$/', $strID_a) === 1);
}

function screenDir($strID_a)
{
	global $g_strData;
	return $g_strData . '/' . $strID_a;
}

// a screen's meta file: key=value lines
function readMeta($strID_a)
{
	$arrResult = array();
	$strFile = screenDir($strID_a) . '/meta.txt';
	if (is_file($strFile))
	{
		foreach (file($strFile, FILE_IGNORE_NEW_LINES) as $strLine)
		{
			$intPos = strpos($strLine, '=');
			if ($intPos !== false)
			{
				$arrResult[substr($strLine, 0, $intPos)] = substr($strLine, $intPos + 1);
			}
		}
	}
	return $arrResult;
}

function writeMeta($strID_a, $arrMeta_a)
{
	$strText = '';
	foreach ($arrMeta_a as $strKey => $strValue)
	{
		$strText .= $strKey . '=' . str_replace(array("\r", "\n"), ' ', $strValue) . "\n";
	}
	file_put_contents(screenDir($strID_a) . '/meta.txt', $strText, LOCK_EX);
}

// the screen's lines so far (the index: 4 bytes a line) - $strLog_a 'log' (its display) or 'ev'
// (its events)
function lineCount($strID_a, $strLog_a = 'log')
{
	$intResult = 0;
	$strFile = screenDir($strID_a) . '/' . $strLog_a . '.idx';
	clearstatcache();
	if (is_file($strFile))
	{
		$intResult = intdiv(filesize($strFile), 4);
	}
	return $intResult;
}

// lines appended to the log ('log' or 'ev'): the count after them - at most $intMax_a in it;
// $intJoin_a set to the last MODE line's number (-1: none)
function appendLines($strID_a, $strLog_a, $arrLines_a, $intMax_a, &$intJoin_a)
{
	global $g_intMaxLine;
	$strDir = screenDir($strID_a);
	$objLog = fopen($strDir . '/' . $strLog_a . '.txt', 'ab');
	flock($objLog, LOCK_EX);                 // (the index and the log grow together, one writer at a time)
	$objIdx = fopen($strDir . '/' . $strLog_a . '.idx', 'ab');
	clearstatcache();
	$intOffset = filesize($strDir . '/' . $strLog_a . '.txt');
	$intCount = lineCount($strID_a, $strLog_a);
	$intJoin_a = -1;
	$arrMarks = ($strLog_a === 'log' ? vduMarks($strID_a) : null);
	foreach ($arrLines_a as $strLine)
	{
		$strLine = substr(str_replace("\t", ' ', $strLine), 0, $g_intMaxLine);
		if ($intCount < $intMax_a && trim($strLine) !== '')
		{
			if ($arrMarks !== null)
			{
				foreach (vduExpand($strLine) as $strCmd)
				{
					if (vduMark($arrMarks, $strCmd))
					{
						$intJoin_a = $intCount;          // (a checkpoint: a viewer joining live starts here)
					}
				}
			}
			fwrite($objLog, $strLine . "\n");
			fwrite($objIdx, pack('V', $intOffset));
			$intOffset += strlen($strLine) + 1;
			$intCount++;
		}
	}
	fclose($objIdx);
	if ($arrMarks !== null)
	{
		file_put_contents($strDir . '/win.txt', json_encode($arrMarks));
	}
	flock($objLog, LOCK_UN);
	fclose($objLog);
	return $intCount;
}

// lines $intStart_a on of the log ('log' or 'ev'): "ok start next total" and them - $intMax_a
// lines, $intBytes_a bytes at most (one at least)
function readLines($strID_a, $strLog_a, $intStart_a, $intMax_a, $intBytes_a)
{
	$intCount = lineCount($strID_a, $strLog_a);
	if ($intStart_a > $intCount)
	{
		$intStart_a = 0;                     // (wiped: from the start again)
	}
	$strLines = '';
	$intNext = $intStart_a;
	if ($intStart_a < $intCount)
	{
		$strLogFile = screenDir($strID_a) . '/' . $strLog_a . '.txt';
		$intLogSize = filesize($strLogFile);
		$objIdx = fopen(screenDir($strID_a) . '/' . $strLog_a . '.idx', 'rb');
		$intFrom = lineOffset($objIdx, $intStart_a, $intCount, $intLogSize);
		$intTo = lineOffset($objIdx, min($intCount, $intStart_a + $intMax_a), $intCount, $intLogSize);
		fclose($objIdx);
		$objLog = fopen($strLogFile, 'rb');
		fseek($objLog, $intFrom);
		$strChunk = ($intTo > $intFrom ? fread($objLog, $intTo - $intFrom) : '');
		fclose($objLog);
		$intPos = 0;
		$blnFull = false;
		while (!$blnFull && $intPos < strlen($strChunk))
		{
			$intEnd = strpos($strChunk, "\n", $intPos);
			if ($intEnd === false)
			{
				$intEnd = strlen($strChunk) - 1;
			}
			if ($intNext > $intStart_a && strlen($strLines) + $intEnd - $intPos + 1 > $intBytes_a)
			{
				$blnFull = true;
			}
			else
			{
				$strLines .= substr($strChunk, $intPos, $intEnd - $intPos + 1);
				$intPos = $intEnd + 1;
				$intNext++;
			}
		}
	}
	return 'ok ' . $intStart_a . ' ' . $intNext . ' ' . $intCount . "\n" . $strLines;
}

// where line n starts in log.txt (n = the count: the end)
function lineOffset($objIdx_a, $intLine_a, $intCount_a, $intLogSize_a)
{
	$intResult = $intLogSize_a;
	if ($intLine_a < $intCount_a)
	{
		fseek($objIdx_a, $intLine_a * 4);
		$arrUnpacked = unpack('V', fread($objIdx_a, 4));
		$intResult = $arrUnpacked[1];
	}
	return $intResult;
}

// the last join point: the last MODE line (0: none)
function joinPoint($strID_a)
{
	$intResult = 0;
	$strFile = screenDir($strID_a) . '/join.txt';
	if (is_file($strFile))
	{
		$intResult = (int)file_get_contents($strFile);
	}
	return $intResult;
}

function randomID()
{
	return bin2hex(random_bytes(4));
}

function actionNew()
{
	global $g_strData;
	$strResult = '';
	$strTitle = substr(trim(param('t')), 0, 60);
	if ($strTitle === '')
	{
		$strTitle = 'Screen';
	}
	if (!is_dir($g_strData))
	{
		mkdir($g_strData, 0775, true);
		file_put_contents($g_strData . '/.htaccess', "Require all denied\nDeny from all\n");   // (the files: through vdu.php only)
		file_put_contents($g_strData . '/index.html', '');
	}
	$strID = randomID();
	while (is_dir(screenDir($strID)))
	{
		$strID = randomID();
	}
	$strKey = bin2hex(random_bytes(8));       // (the write key: 16 hex digits)
	mkdir(screenDir($strID), 0775);
	touch(screenDir($strID) . '/log.txt');
	touch(screenDir($strID) . '/log.idx');
	writeMeta($strID, array('title' => $strTitle, 'key' => hash('sha256', $strKey),
		'public' => (param('p') === '0' ? 'N' : 'Y'), 'created' => time(), 'updated' => time()));
	$strResult = 'ok ' . $strID . ' ' . $strKey;
	return $strResult;
}

// the screen's meta when id and key are right (null: not)
function ownerMeta($strID_a)
{
	$arrResult = null;
	if (validID($strID_a))
	{
		$arrMeta = readMeta($strID_a);
		if (isset($arrMeta['key']) && hash_equals($arrMeta['key'], hash('sha256', param('k'))))
		{
			$arrResult = $arrMeta;
		}
	}
	return $arrResult;
}

function actionPut()
{
	global $g_intMaxLines;
	$strResult = '';
	$strID = param('s');
	$arrMeta = ownerMeta($strID);
	if ($arrMeta === null)
	{
		$strResult = 'error no such screen, or the wrong key';
	}
	else
	{
		$intJoin = -1;
		$intCount = appendLines($strID, 'log', preg_split('/\r\n|\r|\n/', param('c')), $g_intMaxLines, $intJoin);
		if ($intJoin >= 0)
		{
			file_put_contents(screenDir($strID) . '/join.txt', (string)$intJoin);
		}
		$arrMeta['updated'] = time();
		writeMeta($strID, $arrMeta);
		$strResult = 'ok ' . $intCount . ' ' . lineCount($strID, 'ev');
	}
	return $strResult;
}

function actionGet()
{
	$strResult = '';
	$strID = param('s');
	if (!validID($strID) || !is_dir(screenDir($strID)))
	{
		$strResult = 'error no such screen';
	}
	else
	{
		$intStart = (param('n') === '' ? -1 : (int)param('n'));
		if ($intStart < 0)
		{
			$intStart = joinPoint($strID);
		}
		$strResult = readLines($strID, 'log', $intStart, (param('m') === '' ? 100 : max(1, min(1000, (int)param('m')))),
			(param('b') === '' ? 16000 : max(64, min(200000, (int)param('b')))));
	}
	return $strResult;
}

// a viewer's event (a tap in a zone, a key): appended to the screen's events
function actionEvent()
{
	$strResult = '';
	$strID = param('s');
	$strEvent = trim(param('e'));
	if (!validID($strID) || !is_dir(screenDir($strID)))
	{
		$strResult = 'error no such screen';
	}
	elseif ($strEvent === '' || strlen($strEvent) > 120)
	{
		$strResult = 'error e= an event (120 characters at most)';
	}
	else
	{
		$intJoin = -1;
		$strResult = 'ok ' . appendLines($strID, 'ev', array($strEvent), 50000, $intJoin);
	}
	return $strResult;
}

// the screen's events (its writer: the key)
function actionEvents()
{
	$strResult = '';
	$strID = param('s');
	if (ownerMeta($strID) === null)
	{
		$strResult = 'error no such screen, or the wrong key';
	}
	else
	{
		$strResult = readLines($strID, 'ev', max(0, (int)param('n')), (param('m') === '' ? 100 : max(1, min(1000, (int)param('m')))), 16000);
	}
	return $strResult;
}

// the poll: which of these screens have lines past their pointers
function actionPing()
{
	$strResult = 'ok';
	foreach (explode(',', param('w')) as $strPair)
	{
		$arrPair = explode(':', $strPair);
		if (count($arrPair) === 2 && validID($arrPair[0]) && is_dir(screenDir($arrPair[0])))
		{
			if (lineCount($arrPair[0]) !== (int)$arrPair[1])
			{
				$strResult .= ' ' . $arrPair[0];
			}
		}
	}
	return $strResult;
}

function actionList()
{
	global $g_strData;
	$arrRows = array();
	if (is_dir($g_strData))
	{
		foreach (scandir($g_strData) as $strID)
		{
			if (validID($strID))
			{
				$arrMeta = readMeta($strID);
				if (isset($arrMeta['public']) && $arrMeta['public'] === 'Y')
				{
					$arrRows[] = array((int)$arrMeta['updated'], $strID . ' ' . lineCount($strID) . ' ' . $arrMeta['updated'] . ' ' . $arrMeta['title']);
				}
			}
		}
	}
	usort($arrRows, function ($arrA_a, $arrB_a) { return $arrB_a[0] - $arrA_a[0]; });   // (the latest first)
	$strResult = 'ok ' . count($arrRows);
	foreach ($arrRows as $arrRow)
	{
		$strResult .= "\n" . $arrRow[1];
	}
	return $strResult;
}

function actionInfo()
{
	$strResult = '';
	$strID = param('s');
	if (!validID($strID) || !is_dir(screenDir($strID)))
	{
		$strResult = 'error no such screen';
	}
	else
	{
		$arrMeta = readMeta($strID);
		$strResult = 'ok ' . lineCount($strID) . ' ' . $arrMeta['updated'] . ' ' . $arrMeta['public'] . ' ' . $arrMeta['title'];
	}
	return $strResult;
}

function actionWipe()
{
	$strResult = '';
	$strID = param('s');
	$arrMeta = ownerMeta($strID);
	if ($arrMeta === null)
	{
		$strResult = 'error no such screen, or the wrong key';
	}
	else
	{
		$objLog = fopen(screenDir($strID) . '/log.txt', 'cb');
		flock($objLog, LOCK_EX);
		ftruncate($objLog, 0);
		file_put_contents(screenDir($strID) . '/log.idx', '');
		@unlink(screenDir($strID) . '/join.txt');
		@unlink(screenDir($strID) . '/win.txt');
		@unlink(screenDir($strID) . '/ev.txt');
		@unlink(screenDir($strID) . '/ev.idx');
		flock($objLog, LOCK_UN);
		fclose($objLog);
		$arrMeta['updated'] = time();
		writeMeta($strID, $arrMeta);
		$strResult = 'ok 0';
	}
	return $strResult;
}
