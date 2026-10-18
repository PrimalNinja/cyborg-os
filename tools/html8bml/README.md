# html28bml - HTML to 8BML

`html28bml.php` turns an ordinary HTML page into an **8BML** page (the markup YING / YANG render
on CyborgOS 320K). It is for larger machines: a server converts a normal web page so a CPC browser
can read it. Scripts and CSS are ignored; the standard tags and form controls map to the 8BML
commands that correspond to them.

`tools/rawpage/8bml2raw.py` is the 8BML reference - the output of this tool is meant to lay out
through it (and through YING's `Bml.cls`) the way a hand-written 8BML page would.

## Use

```
CLI:  php html28bml.php page.html [out.8bm]      # out: else to stdout
web:  POST the HTML as the request body, or send html=... ; an 8BML page comes back (text/plain)
lib:  require 'html28bml.php';  $str8bml = html_to_8bml($strHtml);
```

To check a conversion, render it the way a browser would:

```
php html28bml.php page.html page.8bm
python3 ../rawpage/8bml2raw.py page.8bm 78        # 78 = RAWYING's width (80 = RAWYANG)
```

## The mapping

| HTML | 8BML | |
|---|---|---|
| `<title>` (or first `<h1>`) | the `-` header (the page title) | |
| `<h1>` | `p` | page heading (underlined `=`) |
| `<h2>`..`<h6>` | `s` | section heading (underlined `-`) |
| `<p>`, `<div>`, `<pre>`, structural containers | `t` | body text, word-wrapped |
| `<a href>` | `l` | a link (its own row: `-> text`) |
| `<img src alt>` | `i` | an image link (`[image] alt`) |
| `<br>` | `n` | a blank line |
| `<hr>` | `h` | a rule |
| `<ul>` / `<ol>` + `<li>` | `t` rows | `- ` before each item, `1. ` `2. ` for `<ol>` |
| `<table>` + `<tr>`/`<th>`/`<td>` | `v` | columns = the widest row; a cell's `<a>` links it |
| `<form action>` | its fields then its button | the button sends the form to `action` |
| `<input type=text\|email\|...>` | `y` | a text field (`maxlength`, else `size`, else 20) |
| `<input type=password>` | `y` + `p` flag | shown as `*` |
| `<textarea cols rows>` | `z` | a text area |
| `<select>` + `<option>` | `w` | the `selected` option (else the first) is the value |
| `<input type=submit>`, `<button>` | `x` | the form's button |

- A `required` field gets the `m` (mandatory) flag.
- Inline formatting (`<b>`, `<i>`, `<strong>`, `<span>`, `<code>`, ...) contributes its text only.
- Because an 8BML link is always its own row, a link inside a paragraph splits that paragraph
  (text before it, the link, text after it) - as any 8BML page would.
- Text is taken to Latin-1 (the 8BML / CPC character set); `"` and `\` in text are escaped the way
  the 8BML string reader expects.

## Left out

- `<script>`, `<style>`, `<head>` contents, `<svg>`/`<canvas>`, `<iframe>`, media (`<audio>`,
  `<video>`, `<object>`).
- `<input>` kinds with no 8BML field: `hidden`, `checkbox`, `radio`, `file`, `reset`. (A hidden
  field's value is not carried - 8BML forms send only the fields the browser shows.)
- This is a converter for **basic** HTML. It does not fetch pages, run JavaScript, or lay out with
  CSS; it reads the markup as given.

## Test

`src/test/regress.sh` converts `src/test/h2b.html`, renders it through `8bml2raw.py` at width 40,
and checks the result against `src/test/ref/h2b.txt` (the "HTML -> 8BML" check; skipped where php
is absent).
