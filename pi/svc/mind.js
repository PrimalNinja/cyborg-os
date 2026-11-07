// mind.js - MIND: the generative model (GEN.MDL, the Z80's ternary GRU) run natively on the Pi,
// through the ntck addon (pi/ntck/ntck.node). Same integer arithmetic as Net.cls - the Pi writes
// the same bytes the CPC would, ~1000x sooner. One model state a channel (like GRU on a port).
//   MODELS                 OK name name ...            the .MDL files in cfg.MODELS (default ~/.cosd/models)
//   LOAD name              OK V E H L K               loads NAME.MDL for this channel, state reset
//   RESET                  OK                         state back to the start
//   RUN n text             OK + body (n characters)   feeds text, writes n greedy characters; state carries on
//   RUN n  (body = text)   OK + body                  the same with the text in the body (long prompts)
//   INFO                   OK V E H L K charset
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';

module.exports = function(service, cfg)
{
	var m_objFs = require('fs');
	var m_objPath = require('path');
	var m_objOs = require('os');
	var m_objNtck = null;
	var m_strErr = '';
	var m_strDir = (cfg && cfg.MODELS) ? cfg.MODELS : m_objPath.join(m_objOs.homedir(), '.cosd', 'models');

	try
	{
		m_objNtck = require(process.env.NTCK_NODE || m_objPath.join(__dirname, '..', 'ntck', 'ntck.node'));
	}
	catch (e)
	{
		m_strErr = 'ntck.node not built (cd pi/ntck && sh build.sh): ' + e.message;
	}

	function gb_models()
	{
		var arrOut = [];
		var arrNames;
		var intI;
		if (m_objFs.existsSync(m_strDir))
		{
			arrNames = m_objFs.readdirSync(m_strDir);
			for (intI = 0; intI < arrNames.length; intI++)
			{
				if (/\.mdl$/i.test(arrNames[intI]))
				{
					arrOut.push(arrNames[intI].replace(/\.mdl$/i, '').toUpperCase());
				}
			}
		}
		return arrOut;
	}

	function gb_path(strName_a)
	{
		var strSafe = String(strName_a || '').replace(/[^A-Za-z0-9_\-]/g, '').toUpperCase();
		var strPath = '';
		var arrNames;
		var intI;
		if (strSafe !== '' && m_objFs.existsSync(m_strDir))
		{
			arrNames = m_objFs.readdirSync(m_strDir);
			for (intI = 0; intI < arrNames.length; intI++)
			{
				if (arrNames[intI].toUpperCase() === strSafe + '.MDL' && strPath === '')
				{
					strPath = m_objPath.join(m_strDir, arrNames[intI]);
				}
			}
		}
		return strPath;
	}

	function gb_info(intId_a)
	{
		var objI = m_objNtck.mdlInfo(intId_a);
		return objI.v + ' ' + objI.e + ' ' + objI.h + ' ' + objI.l + ' ' + objI.k;
	}

	service('mind', 'the generative model (GEN.MDL) run natively: MODELS, LOAD, RESET, RUN, INFO', function()
	{
		var m_intId = -1;		// this channel's loaded model (one state a channel)
		return {
			req: function(ch, id, text, body)
			{
				var strW = String(text || '').trim();
				var arrTok = strW.split(/\s+/);
				var strCmd = (arrTok[0] || '').toUpperCase();
				var strRsp = '';
				var strBody = null;
				var intN;
				var strPrompt;
				var strPath;
				try
				{
					if (m_objNtck === null)
					{
						strRsp = 'ERR ' + m_strErr;
					}
					else if (strCmd === 'MODELS')
					{
						strRsp = 'OK ' + gb_models().join(' ');
					}
					else if (strCmd === 'LOAD')
					{
						strPath = gb_path(arrTok[1]);
						if (strPath === '')
						{
							strRsp = 'ERR no model ' + (arrTok[1] || '') + ' in ' + m_strDir;
						}
						else
						{
							if (m_intId >= 0)
							{
								m_objNtck.mdlFree(m_intId);
							}
							m_intId = m_objNtck.mdlLoad(m_objFs.readFileSync(strPath));
							strRsp = 'OK ' + gb_info(m_intId);
						}
					}
					else if (m_intId < 0)
					{
						strRsp = 'ERR no model loaded (LOAD name)';
					}
					else if (strCmd === 'RESET')
					{
						m_objNtck.mdlReset(m_intId);
						strRsp = 'OK';
					}
					else if (strCmd === 'INFO')
					{
						strRsp = 'OK ' + gb_info(m_intId) + ' ' + m_objNtck.mdlInfo(m_intId).charset;
					}
					else if (strCmd === 'RUN')
					{
						intN = parseInt(arrTok[1], 10);
						if (isNaN(intN) || intN < 0 || intN > 4096)
						{
							strRsp = 'ERR RUN n text (n 0-4096)';
						}
						else
						{
							strPrompt = (body && body.length) ? body.toString('latin1') : strW.slice(strW.indexOf(arrTok[1]) + arrTok[1].length + 1);
							strBody = Buffer.from(m_objNtck.mdlRun(m_intId, strPrompt, intN), 'latin1');
							strRsp = 'OK ' + strBody.length;
						}
					}
					else
					{
						strRsp = 'ERR unknown ' + strCmd;
					}
				}
				catch (e)
				{
					strRsp = 'ERR ' + e.message;
					strBody = null;
				}
				if (strBody !== null)
				{
					ch.s.rsp(ch.n, id, strRsp, strBody);
				}
				else
				{
					ch.s.rsp(ch.n, id, strRsp);
				}
			},
			close: function()
			{
				if (m_intId >= 0 && m_objNtck !== null)
				{
					m_objNtck.mdlFree(m_intId);
					m_intId = -1;
				}
			}
		};
	});
};
