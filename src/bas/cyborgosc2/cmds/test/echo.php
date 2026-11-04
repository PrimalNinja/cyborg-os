<?php
// echo.php - HTTPTEST's page: q=get / q=post say what came (the POST body as it was sent);
// q=big a 20000-byte answer (HTTPTEST stops after its first pieces). (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
$strQ = isset($_GET['q']) ? $_GET['q'] : '';
if ($strQ === 'big')
{
	header('Content-Length: 20000');
	echo str_repeat('0123456789', 2000);
}
elseif ($strQ === 'post')
{
	echo 'posted ' . $_SERVER['CONTENT_TYPE'] . ' [' . file_get_contents('php://input') . ']';
}
else
{
	echo 'got ' . $_SERVER['REQUEST_METHOD'] . ' ' . $strQ;
}
