<?php
// html28bml.php - convert basic HTML to 8BML (8-bit Markup Language, what YING / YANG render on
// CyborgOS 320K). For larger machines: a server turns an ordinary HTML page into an 8BML page a
// CPC browser can read. Scripts and CSS are ignored; standard tags and forms map to the 8BML
// commands that correspond to them (tools/rawpage/8bml2raw.py is the 8BML reference).
//
//   CLI:  php html28bml.php page.html [out.8bm]        (out: else to stdout)
//   web:  POST the HTML as the request body, or html=... ; a 8BML page comes back (text/plain)
//   lib:  require 'html28bml.php'; $str8bml = html_to_8bml($strHtml);
//
// The mapping (everything else is walked into for its text):
//   <title>              the page title (the - header)        <h1>            p (page heading)
//   <h2>..<h6>           s (section heading)                  <p> <div> ...   t (body text)
//   <a href>             l (a link)                           <img src alt>   i (an image link)
//   <br>                 n (a blank line)                     <hr>            h (a rule)
//   <ul> <ol> <li>       t rows, "- " / "N. " before each     <table>         v (a table)
//   <form action>        its fields, then its button          <input text>    y (a text field)
//   <input password>     y with the p flag                    <textarea>      z (a text area)
//   <select><option>     w (a select)                         submit / button x (sends the form)
// A required field gets the m (mandatory) flag. Checkbox, radio, file and hidden inputs have no
// 8BML field and are left out.

// bml_text(str): a text part escaped for an 8BML "..." parameter - Latin-1, one line, no quote
// or backslash trouble (the 8BML string reader takes \" and \\ off).
function bml_text($str_a)
{
	$str = mb_convert_encoding($str_a, 'ISO-8859-1', 'UTF-8');
	$str = preg_replace('/\s+/', ' ', $str);
	$str = str_replace('\\', '\\\\', $str);
	$str = str_replace('"', '\\"', $str);
	$str = trim($str);

	return $str;
}

class Html8bml
{
	public $m_arrOut;			// the 8BML command lines
	public $m_strTitle;			// the page title (the - header)
	public $m_strPend;			// text gathered from inline content, not yet emitted
	public $m_strForm;			// the current form's action (empty outside a form)

	public $m_arrInline;		// tags whose text joins the line
	public $m_arrSkip;			// tags left out whole (head, scripts, styles)

	function __construct()
	{
		$this->m_arrOut = array();
		$this->m_strTitle = '';
		$this->m_strPend = '';
		$this->m_strForm = '';
		$this->m_arrInline = array('b', 'i', 'em', 'strong', 'span', 'u', 'small', 'big', 'font', 'code', 'tt', 'label', 'abbr', 'sub', 'sup', 'mark', 'q', 'cite', 'var', 'samp', 'kbd', 'ins', 'del', 'time', 'bdi', 'bdo', 'wbr');
		$this->m_arrSkip = array('script', 'style', 'head', 'meta', 'link', 'noscript', 'title', 'template', 'svg', 'canvas', 'iframe', 'object', 'embed', 'audio', 'video', 'map', 'area', 'source', 'track', 'param');
	}

	// emit(cmd, text): one command, text parts already escaped, a ":" after it (as the 8BML
	// examples do). cmd with no text (n, h, <) is emitted on its own.
	function emit($str_a)
	{
		$this->m_arrOut[] = $str_a . ':';
	}

	// flush(kind): the gathered inline text, if any, emitted as kind (t body, p page, s section);
	// then cleared. "" kind drops it.
	function flush($strKind_a)
	{
		$str = trim(preg_replace('/\s+/', ' ', $this->m_strPend));

		if ($str !== '' && $strKind_a !== '')
		{
			$this->emit($strKind_a . '"' . bml_text($str) . '"');
		}

		$this->m_strPend = '';
	}

	// attr(node, name): an element's attribute, "" if it has none
	function attr($objNode_a, $strName_a)
	{
		$str = '';

		if ($objNode_a->hasAttribute($strName_a))
		{
			$str = $objNode_a->getAttribute($strName_a);
		}

		return $str;
	}

	// flags(node): the 8BML field flags string - m mandatory (required), p password
	function flags($objNode_a, $blnPassword_a)
	{
		$str = '';

		if ($objNode_a->hasAttribute('required'))
		{
			$str = $str . 'm';
		}
		if ($blnPassword_a)
		{
			$str = $str . 'p';
		}

		return $str;
	}

	// link(node): the l command for an <a>, its text and its href
	function link($objNode_a)
	{
		$strHref = $this->attr($objNode_a, 'href');
		$strText = trim(preg_replace('/\s+/', ' ', $objNode_a->textContent));

		if ($strText === '')
		{
			$strText = $strHref;
		}
		if ($strHref !== '' && strpos($strHref, 'javascript:') !== 0)
		{
			$this->emit('l"' . bml_text($strHref) . '","' . bml_text($strText) . '"');
		}
	}

	// image(node): the i command for an <img>, its alt (or "image") and its src
	function image($objNode_a)
	{
		$strSrc = $this->attr($objNode_a, 'src');
		$strAlt = $this->attr($objNode_a, 'alt');

		if ($strAlt === '')
		{
			$strAlt = 'image';
		}
		if ($strSrc !== '')
		{
			$this->emit('i"","' . bml_text($strSrc) . '","' . bml_text($strAlt) . '"');
		}
	}

	// field_input(node): an <input> - a text field (y), a password (y + p) or, for submit / button
	// / image, the form's button (x). Checkbox, radio, file, reset and hidden are left out.
	function field_input($objNode_a)
	{
		$strType = strtolower($this->attr($objNode_a, 'type'));

		if ($strType === '')
		{
			$strType = 'text';
		}

		if ($strType === 'submit' || $strType === 'image')
		{
			$strLabel = $this->attr($objNode_a, 'value');
			if ($strLabel === '')
			{
				$strLabel = 'Submit';
			}
			$this->emit('x"' . bml_text($this->m_strForm) . '","' . bml_text($strLabel) . '"');
		}
		else
		{
			$arrPlain = array('text', 'password', 'email', 'search', 'tel', 'url', 'number', 'date');

			if (in_array($strType, $arrPlain, true))
			{
				$strName = $this->attr($objNode_a, 'name');
				$strVal = $this->attr($objNode_a, 'value');
				$intMax = (int)$this->attr($objNode_a, 'maxlength');

				if ($intMax <= 0)
				{
					$intMax = (int)$this->attr($objNode_a, 'size');
				}
				if ($intMax <= 0)
				{
					$intMax = 20;
				}
				$this->emit('y"' . bml_text($strName) . '","' . $intMax . '","' . $this->flags($objNode_a, $strType === 'password') . '","' . bml_text($strVal) . '"');
			}
		}
	}

	// field_textarea(node): a <textarea> - the z command (its text is the value)
	function field_textarea($objNode_a)
	{
		$strName = $this->attr($objNode_a, 'name');
		$intCols = (int)$this->attr($objNode_a, 'cols');
		$intRows = (int)$this->attr($objNode_a, 'rows');
		$strVal = trim($objNode_a->textContent);

		if ($intCols <= 0)
		{
			$intCols = 30;
		}
		if ($intRows <= 0)
		{
			$intRows = 3;
		}
		$this->emit('z"' . bml_text($strName) . '","' . $intCols . '","' . $intRows . '","' . $this->flags($objNode_a, false) . '","' . bml_text($strVal) . '"');
	}

	// field_select(node): a <select> - the w command, its <option>s as code / label pairs; the
	// selected option (or the first) is the value
	function field_select($objNode_a)
	{
		$strName = $this->attr($objNode_a, 'name');
		$strValue = '';
		$blnGot = false;
		$strParams = '';
		$arrOpts = $objNode_a->getElementsByTagName('option');
		$intI = 0;

		while ($intI < $arrOpts->length)
		{
			$objOpt = $arrOpts->item($intI);
			$strCode = $this->attr($objOpt, 'value');
			$strLabel = trim(preg_replace('/\s+/', ' ', $objOpt->textContent));

			if (!$objOpt->hasAttribute('value'))
			{
				$strCode = $strLabel;
			}
			if ($blnGot === false)
			{
				$strValue = $strCode;
				$blnGot = true;
			}
			if ($objOpt->hasAttribute('selected'))
			{
				$strValue = $strCode;
			}
			$strParams = $strParams . ',"' . bml_text($strCode) . '","' . bml_text($strLabel) . '"';
			$intI = $intI + 1;
		}

		$this->emit('w"' . bml_text($strName) . '","' . bml_text($strValue) . '","' . $this->flags($objNode_a, false) . '"' . $strParams);
	}

	// table(node): a <table> - the v command. k is the widest row; the first row with <th> (or
	// the first row) is the heading; a cell with an <a> carries its link.
	function table($objNode_a)
	{
		$arrRows = array();
		$arrTrs = $objNode_a->getElementsByTagName('tr');
		$intK = 1;
		$intI = 0;

		while ($intI < $arrTrs->length)
		{
			$objTr = $arrTrs->item($intI);
			$arrCells = array();
			$objChild = $objTr->firstChild;

			while ($objChild !== null)
			{
				if ($objChild->nodeType === XML_ELEMENT_NODE)
				{
					$strTag = strtolower($objChild->nodeName);

					if ($strTag === 'td' || $strTag === 'th')
					{
						$strText = trim(preg_replace('/\s+/', ' ', $objChild->textContent));
						$strUrl = '';
						$arrLinks = $objChild->getElementsByTagName('a');

						if ($arrLinks->length > 0)
						{
							$strUrl = $this->attr($arrLinks->item(0), 'href');
						}
						$arrCells[] = array($strUrl, $strText);
					}
				}
				$objChild = $objChild->nextSibling;
			}

			if (count($arrCells) > 0)
			{
				$arrRows[] = $arrCells;
				if (count($arrCells) > $intK)
				{
					$intK = count($arrCells);
				}
			}
			$intI = $intI + 1;
		}

		if (count($arrRows) > 0)
		{
			$strParams = '"' . $intK . '"';
			$intR = 0;

			while ($intR < count($arrRows))
			{
				$arrCells = $arrRows[$intR];
				$intC = 0;

				while ($intC < $intK)
				{
					$strUrl = '';
					$strText = '';

					if ($intC < count($arrCells))
					{
						$strUrl = $arrCells[$intC][0];
						$strText = $arrCells[$intC][1];
					}
					$strParams = $strParams . ',"' . bml_text($strUrl) . '","' . bml_text($strText) . '"';
					$intC = $intC + 1;
				}
				$intR = $intR + 1;
			}
			$this->emit('v' . $strParams);
		}
	}

	// list(node, ordered): a <ul> / <ol> - each <li> a t row, "- " or "N. " before it; a link in
	// an item becomes its own l row after it
	function list_block($objNode_a, $blnOrdered_a)
	{
		$objChild = $objNode_a->firstChild;
		$intN = 1;

		while ($objChild !== null)
		{
			if ($objChild->nodeType === XML_ELEMENT_NODE && strtolower($objChild->nodeName) === 'li')
			{
				$strPre = '- ';
				if ($blnOrdered_a)
				{
					$strPre = $intN . '. ';
				}
				$this->m_strPend = $strPre;
				$this->walk($objChild);
				$this->flush('t');
				$intN = $intN + 1;
			}
			$objChild = $objChild->nextSibling;
		}
	}

	// form(node): a <form> - its action remembered while its contents are walked, so the button
	// (x) and the fields know where the form sends
	function form($objNode_a)
	{
		$strWas = $this->m_strForm;
		$strAction = $this->attr($objNode_a, 'action');

		if ($strAction === '')
		{
			$strAction = '';
		}
		$this->m_strForm = $strAction;
		$this->walk($objNode_a);
		$this->flush('t');
		$this->m_strForm = $strWas;
	}

	// heading(node, kind): an <h1..h6> - all its text as one p / s row
	function heading($objNode_a, $strKind_a)
	{
		$this->m_strPend = $objNode_a->textContent;
		$this->flush($strKind_a);
	}

	// button(node): a <button> - the form's button (x), its text the label
	function button($objNode_a)
	{
		$strType = strtolower($this->attr($objNode_a, 'type'));

		if ($strType === '' || $strType === 'submit')
		{
			$strLabel = trim(preg_replace('/\s+/', ' ', $objNode_a->textContent));

			if ($strLabel === '')
			{
				$strLabel = 'Submit';
			}
			$this->emit('x"' . bml_text($this->m_strForm) . '","' . bml_text($strLabel) . '"');
		}
	}

	// walk(node): the children of a node, in order - text gathered, each element dispatched
	function walk($objNode_a)
	{
		$objChild = $objNode_a->firstChild;

		while ($objChild !== null)
		{
			if ($objChild->nodeType === XML_TEXT_NODE)
			{
				$this->m_strPend = $this->m_strPend . ' ' . $objChild->nodeValue;
			}
			else
			{
				if ($objChild->nodeType === XML_ELEMENT_NODE)
				{
					$this->element($objChild);
				}
			}
			$objChild = $objChild->nextSibling;
		}
	}

	// element(node): one element dispatched to its 8BML command (text flushed first where the
	// element starts a new block)
	function element($objNode_a)
	{
		$strTag = strtolower($objNode_a->nodeName);

		if (in_array($strTag, $this->m_arrSkip, true))
		{
			// left out whole
			$strTag = $strTag;
		}
		else
		{
			if (in_array($strTag, $this->m_arrInline, true))
			{
				$this->walk($objNode_a);
			}
			else
			{
				$this->element_block($objNode_a, $strTag);
			}
		}
	}

	// element_block(node, tag): the block and special elements
	function element_block($objNode_a, $strTag_a)
	{
		if ($strTag_a === 'a')
		{
			$this->flush('t');
			$this->link($objNode_a);
		}
		else if ($strTag_a === 'img')
		{
			$this->flush('t');
			$this->image($objNode_a);
		}
		else if ($strTag_a === 'br')
		{
			$this->flush('t');
			$this->emit('n');
		}
		else if ($strTag_a === 'hr')
		{
			$this->flush('t');
			$this->emit('h');
		}
		else if ($strTag_a === 'h1')
		{
			$this->flush('t');
			$this->heading($objNode_a, 'p');
		}
		else if ($strTag_a === 'h2' || $strTag_a === 'h3' || $strTag_a === 'h4' || $strTag_a === 'h5' || $strTag_a === 'h6')
		{
			$this->flush('t');
			$this->heading($objNode_a, 's');
		}
		else if ($strTag_a === 'ul')
		{
			$this->flush('t');
			$this->list_block($objNode_a, false);
		}
		else if ($strTag_a === 'ol')
		{
			$this->flush('t');
			$this->list_block($objNode_a, true);
		}
		else if ($strTag_a === 'table')
		{
			$this->flush('t');
			$this->table($objNode_a);
		}
		else if ($strTag_a === 'form')
		{
			$this->flush('t');
			$this->form($objNode_a);
		}
		else if ($strTag_a === 'input')
		{
			$this->flush('t');
			$this->field_input($objNode_a);
		}
		else if ($strTag_a === 'textarea')
		{
			$this->flush('t');
			$this->field_textarea($objNode_a);
		}
		else if ($strTag_a === 'select')
		{
			$this->flush('t');
			$this->field_select($objNode_a);
		}
		else if ($strTag_a === 'button')
		{
			$this->flush('t');
			$this->button($objNode_a);
		}
		else if ($strTag_a === 'p' || $strTag_a === 'blockquote' || $strTag_a === 'pre' || $strTag_a === 'figcaption' || $strTag_a === 'dt' || $strTag_a === 'dd')
		{
			$this->flush('t');
			$this->walk($objNode_a);
			$this->flush('t');
		}
		else
		{
			// a structural container (div, section, article, main, header, footer, nav, ul wrapper
			// ...): its text is a block of its own, then walked into
			$this->flush('t');
			$this->walk($objNode_a);
			$this->flush('t');
		}
	}

	// convert(html): the whole page. The title (or the first h1) is the - header; the body (or
	// the document) is walked; a "." ends the page.
	function convert($strHtml_a)
	{
		$objDoc = new DOMDocument();
		$strIn = '<?xml encoding="UTF-8" ?>' . $strHtml_a;

		libxml_use_internal_errors(true);
		$objDoc->loadHTML($strIn, LIBXML_NOERROR | LIBXML_NOWARNING);
		libxml_clear_errors();

		$arrTitle = $objDoc->getElementsByTagName('title');

		if ($arrTitle->length > 0)
		{
			$this->m_strTitle = trim(preg_replace('/\s+/', ' ', $arrTitle->item(0)->textContent));
		}

		$arrBody = $objDoc->getElementsByTagName('body');
		$objRoot = $objDoc->documentElement;

		if ($arrBody->length > 0)
		{
			$objRoot = $arrBody->item(0);
		}

		if ($this->m_strTitle === '')
		{
			$arrH1 = $objDoc->getElementsByTagName('h1');
			if ($arrH1->length > 0)
			{
				$this->m_strTitle = trim(preg_replace('/\s+/', ' ', $arrH1->item(0)->textContent));
			}
		}
		if ($this->m_strTitle === '')
		{
			$this->m_strTitle = 'Page';
		}

		$this->m_arrOut[] = '-"1","' . bml_text($this->m_strTitle) . '":';

		if ($objRoot !== null)
		{
			$this->walk($objRoot);
			$this->flush('t');
		}

		$this->m_arrOut[] = '.';

		return implode("\n", $this->m_arrOut) . "\n";
	}
}

// html_to_8bml(html): the library entry - an HTML string in, an 8BML string out
function html_to_8bml($strHtml_a)
{
	$objConv = new Html8bml();
	$str = $objConv->convert($strHtml_a);

	return $str;
}

// the entry: CLI (a file argument, or stdin) or web (the request body, or html=...)
if (PHP_SAPI === 'cli')
{
	$arrArgs = $argv;

	if (count($arrArgs) < 2)
	{
		fwrite(STDERR, "usage: php html28bml.php page.html [out.8bm]   (or HTML on stdin)\n");
		exit(1);
	}
	else
	{
		$strHtml = file_get_contents($arrArgs[1]);
		$str8bml = html_to_8bml($strHtml);

		if (count($arrArgs) > 2)
		{
			file_put_contents($arrArgs[2], $str8bml);
		}
		else
		{
			echo $str8bml;
		}
	}
}
else
{
	$strHtml = '';

	if (isset($_REQUEST['html']))
	{
		$strHtml = $_REQUEST['html'];
	}
	else
	{
		$strHtml = file_get_contents('php://input');
	}

	header('Content-Type: text/plain; charset=iso-8859-1');
	echo html_to_8bml($strHtml);
}
