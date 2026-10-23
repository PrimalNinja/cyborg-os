// CyborgOS Builder from node, from its sources (as NTC's test/cli.js): the scripts cosbuild.html marks
// data-node loaded in its order, then the command - the project read from the top folder each time.
//   node tools/cosbuild/src/cli.js COMMAND ...      (no command: the list; js/cos_node.js has them all)
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
var fs = require('fs');
var path = require('path');
var vm = require('vm');
var strHtml = fs.readFileSync(path.join(__dirname, 'cosbuild.html'), 'utf8');
var re = /<script src="([^"]+)" data-node><\/script>/g;
var m = null;

global.window = global;
global.require = require;			// (the scripts use it: node's, not a module's)
while ((m = re.exec(strHtml)) !== null)
{
	vm.runInThisContext(fs.readFileSync(path.join(__dirname, m[1]), 'utf8'), { filename: m[1] });
}
cosNodeMain(process.argv.slice(2), { src: __dirname });
