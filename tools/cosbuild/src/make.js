// make.js - the one file: cosbuild.html with everything it loads put in it (<link> and <script src>
// as <style> and <script> blocks, id = the file's path), the project (the files the layout's Imports
// part names, read from the top folder) and the node starter - ../CyborgOSBuilder.htm.
//   node tools/cosbuild/src/make.js [--root=TOP] [--layout=PATH] [--out=FILE]
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
var fs = require('fs');
var path = require('path');
var vm = require('vm');
var strRoot = path.resolve(__dirname, '..', '..', '..');
var strLayout = '';
var strOut = path.resolve(__dirname, '..', 'CyborgOSBuilder.htm');
var strHtml = fs.readFileSync(path.join(__dirname, 'cosbuild.html'), 'utf8');
var re = /<script src="([^"]+)" data-node><\/script>/g;
var m = null;
var objProject = null;

process.argv.slice(2).forEach(function(a)
{
	if (a.indexOf('--root=') === 0) { strRoot = path.resolve(a.substr(7)); }
	if (a.indexOf('--layout=') === 0) { strLayout = a.substr(9); }
	if (a.indexOf('--out=') === 0) { strOut = path.resolve(a.substr(6)); }
});
global.window = global;
global.require = require;			// (the scripts use it: node's, not a module's)
while ((m = re.exec(strHtml)) !== null)
{
	vm.runInThisContext(fs.readFileSync(path.join(__dirname, m[1]), 'utf8'), { filename: m[1] });
}
strLayout = strLayout || cosNodeLayoutPath(strRoot);
objProject = cosNodeFolderProject(strRoot, strLayout);

function file(strF_a)
{
	var str = fs.readFileSync(path.join(__dirname, strF_a), 'utf8');

	if (/<\/script/i.test(str) || /<\/style/i.test(str))
	{
		throw new Error(strF_a + ' has a closing script / style tag in it: it can\'t go in the one file');
	}
	return str;
}
strHtml = strHtml.replace(/<link href="([^"]+)" rel="stylesheet">/g, function(a, f) { return '<style id="' + f + '">\n' + file(f) + '\n</style>'; });
strHtml = strHtml.replace(/<script src="([^"]+)"( data-node)?><\/script>/g, function(a, f, n) { return '<script id="' + f + '"' + (n || '') + '>\n' + file(f) + '\n</script>'; });
strHtml = strHtml.replace(/(<script type="application\/json" id="cos-project">)[\s\S]*?(<\/script>)/, function(a, b, c) { return b + cosProjectJson(objProject) + c; });
strHtml = strHtml.replace('</body>', [
	'<script id="cos-boot">',
	'// node: f = this file - every <script data-node> run, then cosNodeMain (js/cos_node.js has the commands)',
	'/*NODE*/',
	'if (typeof process !== "undefined" && process.versions && process.versions.node && typeof cosNodeMain === "undefined") { (function() {',
	'\tvar fs = require("fs"), vm = require("vm"), path = require("path"), strFile = path.resolve(typeof f !== "undefined" ? f : "CyborgOSBuilder.htm"), strText = fs.readFileSync(strFile, "utf8"), re = /<script id="([^"]+)" data-node(?:="")?>([\\s\\S]*?)<\\/script>/g, m = null;',
	'\tglobal.window = global;',
	'\twhile ((m = re.exec(strText)) !== null) { vm.runInThisContext(m[2], { filename: m[1] }); }',
	'\tcosNodeMain(process.argv.slice(1), { htm: strFile, text: strText });',
	'})(); }',
	'/*NODE*/',
	'</script>',
	'</body>'].join('\n'));
fs.writeFileSync(strOut, strHtml, 'utf8');
console.log(strOut + ': ' + Object.keys(objProject.files).length + ' project files, ' + fs.statSync(strOut).size + ' bytes');
