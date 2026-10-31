// float.js - FLOAT: the Pi as the coprocessor behind NTC's Float class (its shim's jump block sends
// the operations here: C0 passes a slot's BDOS 131 op 40 over the link). The same answers as the
// Float class's Z80 engine and the vCPC: IEEE single (no denormals - 0; no NaNs - infinity, and
// the overflow flag), Fixed's scaled integers rounded halves away from zero. Little end first.
//   OP n                 body: A, B, C (4 bytes each)          -> OK, body: the answer (4), overflow (1)
//                        n: 1 + 2 - 3 * 4 / (singles), 5 from a Long, 6 to a Long, 7 negate,
//                        8 absolute, 9 half to single, 10 single to half, 11 a * b / c (Longs)
//   ARR eop es bk n      body: the scale (4), k (4), A (n elements), B (n elements, not if bk = 1:
//                        B is k)                               -> OK n, body: D (n elements), overflow (1)
//   MAT eop es r k c     body: the scale (4), A (r x k), B (k x c) - rows first
//                                                              -> OK, body: D (r x c), overflow (1)
// eop: 1-4 single + - * /, 5-8 fixed + - * / (scale = 10 ^ places); es: 4 (Long) or 2 (Integer:
// read sign extended, written back clamped to -32767..32767). The fixed product sums the exact
// products and rounds once. ES5: the 64 bit parts done exactly in 16 bit pieces.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
'use strict';

var m_arrF = new Float32Array(1);
var m_arrU = new Uint32Array(m_arrF.buffer);
var m_bOv = false;

// the bits of a single as a number, and back (denormals 0, infinity / NaN: infinity, overflow)
function bitsToFloat(intU_a)
{
	var intU = intU_a >>> 0;
	if ((intU & 0x7F800000) === 0)
	{
		intU = 0;
	}
	m_arrU[0] = intU;
	return m_arrF[0];
}

function floatToBits(fltF_a)
{
	var intU = 0;
	m_arrF[0] = fltF_a;
	intU = m_arrU[0] >>> 0;
	if ((intU & 0x7F800000) === 0)
	{
		intU = 0;
	}
	else if (((intU & 0x7F800000) >>> 0) === 0x7F800000)
	{
		m_bOv = true;
		intU = ((intU & 0x80000000) | 0x7F800000) >>> 0;
	}
	return intU;
}

function toInt(intU_a)
{
	var fltF = bitsToFloat(intU_a);
	var intR = 0;
	if (fltF >= 2147483648)
	{
		m_bOv = true;
		intR = 2147483647;
	}
	else if (fltF < -2147483648 || fltF !== fltF)
	{
		m_bOv = true;
		intR = -2147483648;
	}
	else
	{
		intR = (fltF < 0) ? Math.ceil(fltF) : Math.floor(fltF);
	}
	return intR;
}

function halfToSingle(intH_a)
{
	var intS = (intH_a & 0x8000) << 16;
	var intE = (intH_a >> 10) & 31;
	var intM = intH_a & 0x3FF;
	var intR = 0;
	if (intE === 0)
	{
		intR = intS;
	}
	else if (intE === 31)
	{
		intR = intS | 0x7F800000;
	}
	else
	{
		intR = intS | ((intE + 112) << 23) | (intM << 13);
	}
	return intR >>> 0;
}

function singleToHalf(intU_a)
{
	var intU = intU_a >>> 0;
	var intS = (intU >>> 16) & 0x8000;
	var intE = (intU >>> 23) & 255;
	var intM = 0;
	var intR = 0;
	if ((intU & 0x7F800000) === 0 || intE < 113)
	{
		intR = intS;
	}
	else if (intE >= 143)
	{
		m_bOv = true;
		intR = intS | 0x7C00;
	}
	else
	{
		intM = ((intU & 0x7FFFFF) | 0x800000) >>> 13;
		if (intU & 0x1000)
		{
			intM = intM + 1;                         // halves up, as the Z80 engine
		}
		intE = intE - 112;
		if (intM >= 0x800)
		{
			intM = 0x400;
			intE = intE + 1;
		}
		if (intE >= 31)
		{
			m_bOv = true;
			intR = intS | 0x7C00;
		}
		else
		{
			intR = intS | (intE << 10) | (intM & 0x3FF);
		}
	}
	return (intR & 0x8000) ? (intR | 0xFFFF0000) : intR;  // sign extended, as an Integer
}

// ---- 64 bits exactly, ES5: a value as four 16 bit pieces (low first), always positive

function mul32(intA_a, intB_a)
{
	var arrP = [0, 0, 0, 0, 0];
	var arrA = [intA_a & 0xFFFF, Math.floor(intA_a / 65536)];
	var arrB = [intB_a & 0xFFFF, Math.floor(intB_a / 65536)];
	var intI = 0;
	var intJ = 0;
	var intK = 0;
	var intC = 0;
	for (intI = 0; intI < 2; intI++)
	{
		for (intJ = 0; intJ < 2; intJ++)
		{
			intC = arrA[intI] * arrB[intJ];
			intK = intI + intJ;
			while (intC > 0)
			{
				intC = intC + arrP[intK];
				arrP[intK] = intC % 65536;
				intC = Math.floor(intC / 65536);
				intK = intK + 1;
			}
		}
	}
	return arrP.slice(0, 4);
}

function add64(arrA_a, arrB_a)
{
	var arrR = [0, 0, 0, 0];
	var intC = 0;
	var intI = 0;
	for (intI = 0; intI < 4; intI++)
	{
		intC = intC + arrA_a[intI] + arrB_a[intI];
		arrR[intI] = intC % 65536;
		intC = Math.floor(intC / 65536);
	}
	return arrR;
}

function sub64(arrA_a, arrB_a)
{
	var arrR = [0, 0, 0, 0];
	var intB = 0;
	var intI = 0;
	var intV = 0;
	for (intI = 0; intI < 4; intI++)
	{
		intV = arrA_a[intI] - arrB_a[intI] - intB;
		intB = 0;
		if (intV < 0)
		{
			intV = intV + 65536;
			intB = 1;
		}
		arrR[intI] = intV;
	}
	return arrR;
}

function cmp64(arrA_a, arrB_a)
{
	var intI = 3;
	var intR = 0;
	while (intI >= 0 && intR === 0)
	{
		if (arrA_a[intI] !== arrB_a[intI])
		{
			intR = (arrA_a[intI] < arrB_a[intI]) ? -1 : 1;
		}
		intI = intI - 1;
	}
	return intR;
}

function from32(intV_a)
{
	return [intV_a % 65536, Math.floor(intV_a / 65536) % 65536, 0, 0];
}

// (p + c / 2) / c, rounded; -1 when it doesn't fit 31 bits
function divRound(arrP_a, intC_a)
{
	var arrP = add64(arrP_a, from32(Math.floor(intC_a / 2)));
	var intRem = 0;
	var intCur = 0;
	var arrQ = [0, 0, 0, 0];
	var intI = 0;
	var intR = 0;
	for (intI = 3; intI >= 0; intI--)
	{
		intCur = intRem * 65536 + arrP[intI];
		arrQ[intI] = Math.floor(intCur / intC_a);
		intRem = intCur - arrQ[intI] * intC_a;
	}
	if (arrQ[3] !== 0 || arrQ[2] !== 0 || arrQ[1] > 32767)
	{
		intR = -1;
	}
	else
	{
		intR = arrQ[1] * 65536 + arrQ[0];
	}
	return intR;
}

function mulDiv(intA_a, intB_a, intC_a)
{
	var bNeg = ((intA_a < 0) !== (intB_a < 0)) !== (intC_a < 0);
	var intQ = 0;
	if (intC_a === 0)
	{
		m_bOv = true;
		intQ = 2147483647;
	}
	else
	{
		intQ = divRound(mul32(Math.abs(intA_a), Math.abs(intB_a)), Math.abs(intC_a));
		if (intQ < 0)
		{
			m_bOv = true;
			intQ = 2147483647;
		}
	}
	return bNeg ? -intQ : intQ;
}

function fixedAdd(intA_a, intB_a, bSub_a)
{
	var intR = bSub_a ? intA_a - intB_a : intA_a + intB_a;
	if (intR > 2147483647)
	{
		m_bOv = true;
		intR = 2147483647;
	}
	else if (intR < -2147483647)
	{
		m_bOv = true;
		intR = -2147483647;
	}
	return intR;
}

// one element operation (A, B as unsigned bits for singles, signed for fixed): the answer's bits
function element(intEop_a, intA_a, intB_a, intScale_a)
{
	var intR = 0;
	if (intEop_a === 1)
	{
		intR = floatToBits(bitsToFloat(intA_a) + bitsToFloat(intB_a));
	}
	else if (intEop_a === 2)
	{
		intR = floatToBits(bitsToFloat(intA_a) - bitsToFloat(intB_a));
	}
	else if (intEop_a === 3)
	{
		intR = floatToBits(bitsToFloat(intA_a) * bitsToFloat(intB_a));
	}
	else if (intEop_a === 4)
	{
		intR = floatToBits(bitsToFloat(intA_a) / bitsToFloat(intB_a));
	}
	else if (intEop_a === 5)
	{
		intR = fixedAdd(intA_a | 0, intB_a | 0, false);
	}
	else if (intEop_a === 6)
	{
		intR = fixedAdd(intA_a | 0, intB_a | 0, true);
	}
	else if (intEop_a === 7)
	{
		intR = mulDiv(intA_a | 0, intB_a | 0, intScale_a);
	}
	else if (intEop_a === 8)
	{
		intR = mulDiv(intA_a | 0, intScale_a, intB_a | 0);
	}
	return intR >>> 0;
}

function getEl(bufB_a, intAt_a, intEs_a)
{
	return (intEs_a === 2) ? (bufB_a.readInt16LE(intAt_a) >>> 0) : bufB_a.readUInt32LE(intAt_a);
}

function putEl(bufB_a, intAt_a, intEs_a, intV_a)
{
	var intX = intV_a | 0;
	if (intEs_a === 2)
	{
		if (intX > 32767)
		{
			intX = 32767;
			m_bOv = true;
		}
		else if (intX < -32767)
		{
			intX = -32767;
			m_bOv = true;
		}
		bufB_a.writeInt16LE(intX, intAt_a);
	}
	else
	{
		bufB_a.writeUInt32LE(intV_a >>> 0, intAt_a);
	}
}

// ---- the requests

function doOp(intN_a, bufBody_a)
{
	var intA = bufBody_a.readUInt32LE(0);
	var intB = bufBody_a.readUInt32LE(4);
	var intC = bufBody_a.readUInt32LE(8);
	var intR = 0;
	if (intN_a >= 1 && intN_a <= 4)
	{
		intR = element(intN_a, intA, intB, 1);
	}
	else if (intN_a === 5)
	{
		intR = floatToBits(intA | 0);
	}
	else if (intN_a === 6)
	{
		intR = toInt(intA);
	}
	else if (intN_a === 7)
	{
		intR = intA ^ 0x80000000;
	}
	else if (intN_a === 8)
	{
		intR = intA & 0x7FFFFFFF;
	}
	else if (intN_a === 9)
	{
		intR = halfToSingle(intA & 0xFFFF);
	}
	else if (intN_a === 10)
	{
		intR = singleToHalf(intA);
	}
	else if (intN_a === 11)
	{
		intR = mulDiv(intA | 0, intB | 0, intC | 0);
	}
	else
	{
		throw new Error('no operation ' + intN_a);
	}
	return intR >>> 0;
}

function doArr(intEop_a, intEs_a, intBk_a, intN_a, bufBody_a)
{
	var intScale = bufBody_a.readInt32LE(0);
	var intK = bufBody_a.readUInt32LE(4);
	var bufD = Buffer.alloc(intN_a * intEs_a + 1);
	var intI = 0;
	var intB = 0;
	for (intI = 0; intI < intN_a; intI++)
	{
		intB = intBk_a ? intK : getEl(bufBody_a, 8 + (intN_a + intI) * intEs_a, intEs_a);
		putEl(bufD, intI * intEs_a, intEs_a, element(intEop_a, getEl(bufBody_a, 8 + intI * intEs_a, intEs_a), intB, intScale));
	}
	return bufD;
}

function doMat(intEop_a, intEs_a, intR_a, intK_a, intC_a, bufBody_a)
{
	var intScale = bufBody_a.readInt32LE(0);
	var intAt = 4;
	var intBt = 4 + intR_a * intK_a * intEs_a;
	var bufD = Buffer.alloc(intR_a * intC_a * intEs_a + 1);
	var intI = 0;
	var intJ = 0;
	var intQ = 0;
	var intAcc = 0;
	var intX = 0;
	var intY = 0;
	var arrPos = null;
	var arrNeg = null;
	var arrP = null;
	var intV = 0;
	for (intI = 0; intI < intR_a; intI++)
	{
		for (intJ = 0; intJ < intC_a; intJ++)
		{
			if (intEop_a >= 5)
			{
				arrPos = [0, 0, 0, 0];                       // the exact sum: positives and negatives apart
				arrNeg = [0, 0, 0, 0];
				for (intQ = 0; intQ < intK_a; intQ++)
				{
					intX = getEl(bufBody_a, intAt + (intI * intK_a + intQ) * intEs_a, intEs_a) | 0;
					intY = getEl(bufBody_a, intBt + (intQ * intC_a + intJ) * intEs_a, intEs_a) | 0;
					arrP = mul32(Math.abs(intX), Math.abs(intY));
					if ((intX < 0) !== (intY < 0))
					{
						arrNeg = add64(arrNeg, arrP);
					}
					else
					{
						arrPos = add64(arrPos, arrP);
					}
				}
				if (cmp64(arrPos, arrNeg) >= 0)
				{
					intV = divRound(sub64(arrPos, arrNeg), intScale);
					if (intV < 0)
					{
						m_bOv = true;
						intV = 2147483647;
					}
				}
				else
				{
					intV = divRound(sub64(arrNeg, arrPos), intScale);
					if (intV < 0)
					{
						m_bOv = true;
						intV = 2147483647;
					}
					intV = -intV;
				}
				putEl(bufD, (intI * intC_a + intJ) * intEs_a, intEs_a, intV >>> 0);
			}
			else
			{
				intAcc = 0;
				for (intQ = 0; intQ < intK_a; intQ++)
				{
					intAcc = element(1, intAcc, element(3, getEl(bufBody_a, intAt + (intI * intK_a + intQ) * intEs_a, intEs_a),
						getEl(bufBody_a, intBt + (intQ * intC_a + intJ) * intEs_a, intEs_a), 1), 1);
				}
				putEl(bufD, (intI * intC_a + intJ) * intEs_a, intEs_a, intAcc);
			}
		}
	}
	return bufD;
}

function request(strText_a, bufBody_a)
{
	var arrW = strText_a.trim().split(/\s+/);
	var strC = arrW[0].toUpperCase();
	var arrN = arrW.slice(1).map(function(s_a) { return parseInt(s_a, 10); });
	var objR = null;
	var bufR = null;
	var intN = 0;
	m_bOv = false;
	if (strC === 'OP')
	{
		bufR = Buffer.alloc(5);
		bufR.writeUInt32LE(doOp(arrN[0], bufBody_a), 0);
		bufR[4] = m_bOv ? 1 : 0;
		objR = { text: 'OK', body: bufR };
	}
	else if (strC === 'ARR')
	{
		intN = arrN[3];
		bufR = doArr(arrN[0], arrN[1], arrN[2], intN, bufBody_a);
		bufR[bufR.length - 1] = m_bOv ? 1 : 0;
		objR = { text: 'OK ' + intN, body: bufR };
	}
	else if (strC === 'MAT')
	{
		bufR = doMat(arrN[0], arrN[1], arrN[2], arrN[3], arrN[4], bufBody_a);
		bufR[bufR.length - 1] = m_bOv ? 1 : 0;
		objR = { text: 'OK', body: bufR };
	}
	else
	{
		throw new Error('unknown ' + strC);
	}
	return objR;
}

module.exports = function(fnService_a)
{
	fnService_a('float', 'the coprocessor behind NTC\'s Float class (OP, ARR, MAT)', function()
	{
		return {
			req: function(objCh_a, intId_a, strText_a, bufBody_a)
			{
				var objR = null;
				try
				{
					objR = request(strText_a, bufBody_a || Buffer.alloc(0));
					objCh_a.s.rsp(objCh_a.n, intId_a, objR.text, objR.body);
				}
				catch (e)
				{
					objCh_a.s.rsp(objCh_a.n, intId_a, 'ERR ' + e.message);
				}
			}
		};
	});
};
module.exports.request = request;
