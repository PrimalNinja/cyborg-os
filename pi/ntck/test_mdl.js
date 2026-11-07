// ES5. Runs GEN.MDL / net_t.mdl through the native addon and checks against the Z80's proven output.
var m_objNtck = require('./index.js');
var m_objFs = require('fs');

function gb_check(strPath_a, strPrompt_a, intN_a, strExpect_a)
{
    var intId = m_objNtck.mdlLoad(m_objFs.readFileSync(strPath_a));
    var objInfo = m_objNtck.mdlInfo(intId);
    var strOut = m_objNtck.mdlRun(intId, strPrompt_a, intN_a).replace(/\n/g, '|');
    var blnOk = (strExpect_a === null) || (strOut === strExpect_a);
    console.log((blnOk ? 'OK   ' : 'FAIL ') + strPath_a.split('/').pop() + ' V=' + objInfo.v + ' H=' + objInfo.h + ' K=' + objInfo.k + ' -> ' + strOut);
    m_objNtck.mdlFree(intId);
    return blnOk;
}

var m_blnAll = true;
m_blnAll = gb_check(process.argv[2], 'Dim i As Integer\nFor i = 1 To 10\n', 48, 'n00rror=r=i=i=i=i=ii=ii=iiNtDiiiiiiiiNtDiiiiiiii') && m_blnAll;
m_blnAll = gb_check(process.argv[3], 'For i = 1 To 10', 24, '| Print i| Next|End Sub\f') && m_blnAll;
console.log(m_objNtck.version() + ' ' + (m_blnAll ? 'all match the Z80' : 'MISMATCH'));
process.exit(m_blnAll ? 0 : 1);
