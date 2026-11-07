// ES5. Checks the native dot (scalar and LUT) against a pure-JS integer reference on random cases.
var m_objNtck = require('./index.js');

function gb_reference(arrX_a, arrPlanes_a, intK_a, arrMant_a, intShift_a)
{
    var intIn = arrX_a.length;
    var intBlocks = intIn / 32;
    var bigOut = 0n;
    var intB;
    var intI;
    var intJ;
    var intW;
    var intAcc;
    var intPow;
    for (intB = 0; intB < intBlocks; intB++)
    {
        intAcc = 0;
        for (intI = intB * 32; intI < (intB + 1) * 32; intI++)
        {
            intW = 0;
            intPow = 1;
            for (intJ = 0; intJ < intK_a; intJ++)
            {
                intW += (arrPlanes_a[intJ][intI] * intPow);
                intPow *= 3;
            }
            intAcc += arrX_a[intI] * intW;
        }
        bigOut += BigInt(intAcc) * BigInt(arrMant_a[intB]);
    }
    return bigOut >> BigInt(intShift_a);
}

function gb_pack(arrPlanes_a, intK_a, intIn_a)
{
    var objOut = new Uint8Array(intK_a * intIn_a / 4);
    var intJ;
    var intG;
    for (intJ = 0; intJ < intK_a; intJ++)
    {
        for (intG = 0; intG < intIn_a / 4; intG++)
        {
            objOut[intJ * intIn_a / 4 + intG] = (arrPlanes_a[intJ][intG * 4] + 1)
                + 3 * (arrPlanes_a[intJ][intG * 4 + 1] + 1)
                + 9 * (arrPlanes_a[intJ][intG * 4 + 2] + 1)
                + 27 * (arrPlanes_a[intJ][intG * 4 + 3] + 1);
        }
    }
    return objOut;
}

function gb_randInt(intLo_a, intHi_a)
{
    return intLo_a + Math.floor(Math.random() * (intHi_a - intLo_a + 1));
}

function gb_run()
{
    var arrKs = [1, 2, 3, 4, 8];
    var arrIns = [32, 256, 2048];
    var intFail = 0;
    var intCases = 0;
    var intKi;
    var intIi;
    var intRep;
    var intK;
    var intIn;
    var intShift;
    var objX;
    var arrPlanes;
    var objMant;
    var intI;
    var intJ;
    var bigRef;
    var bigA;
    var bigB;
    console.log(m_objNtck.version());
    for (intKi = 0; intKi < arrKs.length; intKi++)
    {
        for (intIi = 0; intIi < arrIns.length; intIi++)
        {
            for (intRep = 0; intRep < 5; intRep++)
            {
                intK = arrKs[intKi];
                intIn = arrIns[intIi];
                intShift = gb_randInt(0, 23);
                objX = new Int8Array(intIn);
                objMant = new Int16Array(intIn / 32);
                arrPlanes = [];
                for (intI = 0; intI < intIn; intI++)
                {
                    objX[intI] = gb_randInt(-128, 127);
                }
                for (intI = 0; intI < intIn / 32; intI++)
                {
                    objMant[intI] = gb_randInt(1, 32767);
                }
                for (intJ = 0; intJ < intK; intJ++)
                {
                    arrPlanes.push(new Int8Array(intIn));
                    for (intI = 0; intI < intIn; intI++)
                    {
                        arrPlanes[intJ][intI] = gb_randInt(-1, 1);
                    }
                }
                bigRef = gb_reference(objX, arrPlanes, intK, objMant, intShift);
                bigA = m_objNtck.dot(objX, gb_pack(arrPlanes, intK, intIn), intK, objMant, intShift, false);
                bigB = m_objNtck.dot(objX, gb_pack(arrPlanes, intK, intIn), intK, objMant, intShift, true);
                intCases++;
                if (bigA !== bigRef || bigB !== bigRef)
                {
                    intFail++;
                    console.log('MISMATCH k=' + intK + ' in=' + intIn + ' ref=' + bigRef + ' scalar=' + bigA + ' lut=' + bigB);
                }
            }
        }
    }
    console.log(intCases + ' cases, ' + intFail + ' mismatches');
    process.exit(intFail ? 1 : 0);
}

gb_run();
