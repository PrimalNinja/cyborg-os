#!/usr/bin/env python3
# Pluto (Cyborg Pluto Nuclear Tight Security, the CPC edition) - the six layers as the CPC's
# KEYMAN does them, in Python: the reference its output is checked against, and the PC end of a
# Pluto exchange (encode / decode the same layers with the same keys).
#
#   z  ZOSCII        16-bit addresses into the key's bytes
#   u  UNSIGNAL      16-bit: a header (offset, prefix, suffix), the random prefix and suffix
#   b  BRICS         16-bit: UNSIGNAL's header and a block header before each block, every block
#                    its own offset
#   mz microZOSCII   8-bit addresses into the key's nibbles (its first 256 bytes: 512 nibbles,
#                    each byte high nibble first - the C#'s MicroZOSCII.FromBytes way)
#   mu microUNSIGNAL, mb microBRICS: the same with 8-bit addresses and nibbles
#
# A message byte is one element (16-bit) or two (micro: its high nibble, then its low - as the
# C#'s MicroZOSCII.Encode). Header values are composed low part first (the specs): a 16-bit
# offset from two bytes, an 8-bit one from two nibbles; prefix / suffix lengths one element (16-bit:
# 10-255, micro: 10-15); block sizes two elements, counting message bytes (micro: 255 at most).
# The offset regime is the specs' and the C#'s (UNSIGNAL's EffectiveSize / SlidingWindow):
#   x < cap + 2% of cap      effective x - 2% of x, window 2% of x
#   x < 2 cap                effective cap, window 2 cap - x - 2% of x (0 or less: no offset)
#   else                     effective cap, window cap
# offset = the header's pointer mod (window + 1); a data address is a position in the effective
# span from the offset; decoding folds it (address mod effective) as the C#'s UNSIGNAL does.
# Header addresses: positions in the first min(cap, size) elements. Decoding ZOSCII: ROM[a mod size].
#
#   pluto.py e "z:K1 mu:K2" infile outfile [keysdir]     encode (layers in the order applied)
#   pluto.py d "z:K1 mu:K2" infile outfile [keysdir]     decode (the same list: undone last first)
#   pluto.py t                                           self test
import os
import random
import sys

m_objRand = random.SystemRandom()

LAYERS = ('z', 'u', 'b', 'mz', 'mu', 'mb')


class PlutoError(Exception):
    pass


def keyElements(arrKey_a, blnMicro_a):
    # the ROM as elements: the key's bytes, or the nibbles of its first 256 bytes (high first)
    arrResult = []
    intI = 0

    if blnMicro_a:
        for intI in range(min(256, len(arrKey_a))):
            arrResult.append((arrKey_a[intI] >> 4) & 15)
            arrResult.append(arrKey_a[intI] & 15)
    else:
        arrResult = list(arrKey_a)
    return arrResult


def regime(intX_a, intCap_a):
    # (effective size, sliding window)
    intPct = (intX_a * 2) // 100
    intT1 = intCap_a + (intCap_a * 2) // 100
    intEff = intCap_a
    intWin = intCap_a

    if intX_a < intT1:
        intEff = intX_a - intPct
        intWin = intPct
    elif intX_a < 2 * intCap_a:
        intEff = intCap_a
        intWin = 2 * intCap_a - intX_a - intPct
    return (intEff, intWin)


def offsetOf(intPtr_a, intX_a, intCap_a):
    intEff, intWin = regime(intX_a, intCap_a)
    intResult = 0

    if intWin > 0:
        intResult = intPtr_a % (intWin + 1)
    return intResult


class Layer:
    def __init__(self, strMethod_a, arrKey_a):
        self.method = strMethod_a
        self.micro = strMethod_a[0] == 'm'
        self.kind = strMethod_a[-1]                     # z u b
        self.rom = keyElements(arrKey_a, self.micro)
        self.x = len(self.rom)
        self.cap = 256 if self.micro else 65536
        self.abytes = 1 if self.micro else 2
        self.vbits = 4 if self.micro else 8
        self.unit = 2 if self.micro else 1
        self.pmax = 15 if self.micro else 255
        self.bmin = 128
        self.bmax = 255 if self.micro else 512
        self.lists = {}
        if self.x == 0:
            raise PlutoError('empty key')

    # positions of each value in [intLo_a, intHi_a)
    def window(self, intLo_a, intHi_a):
        strKey = '%d,%d' % (intLo_a, intHi_a)
        arrLists = None
        intI = 0

        if strKey in self.lists:
            arrLists = self.lists[strKey]
        else:
            arrLists = [[] for intI in range(1 << self.vbits)]
            for intI in range(intLo_a, min(intHi_a, self.x)):
                arrLists[self.rom[intI]].append(intI)
            self.lists[strKey] = arrLists
        return arrLists

    def pick(self, arrLists_a, intValue_a):
        if len(arrLists_a[intValue_a]) == 0:
            raise PlutoError('the key has no %d where it is needed (%s)' % (intValue_a, self.method))
        return m_objRand.choice(arrLists_a[intValue_a])

    def hasAll(self, arrLists_a, arrValues_a):
        blnResult = True
        for intV in arrValues_a:
            if len(arrLists_a[intV]) == 0:
                blnResult = False
        return blnResult

    def elements(self, arrData_a):
        arrResult = []
        for intB in arrData_a:
            if self.micro:
                arrResult.append((intB >> 4) & 15)
                arrResult.append(intB & 15)
            else:
                arrResult.append(intB)
        return arrResult

    def bytesOf(self, arrElems_a):
        arrResult = []
        intI = 0
        if self.micro:
            while intI + 1 < len(arrElems_a):
                arrResult.append((arrElems_a[intI] << 4) | arrElems_a[intI + 1])
                intI = intI + 2
        else:
            arrResult = list(arrElems_a)
        return arrResult

    def putAddr(self, arrOut_a, intAddr_a):
        arrOut_a.append(intAddr_a & 255)
        if self.abytes == 2:
            arrOut_a.append((intAddr_a >> 8) & 255)

    def getAddr(self, arrIn_a, intPos_a):
        intResult = arrIn_a[intPos_a]
        if self.abytes == 2:
            intResult = intResult | (arrIn_a[intPos_a + 1] << 8)
        return intResult

    # a header value: intParts_a elements, low part first
    def putValue(self, arrOut_a, intValue_a, intParts_a):
        arrH = self.window(0, min(self.cap, self.x))
        intMask = (1 << self.vbits) - 1
        for intI in range(intParts_a):
            self.putAddr(arrOut_a, self.pick(arrH, (intValue_a >> (self.vbits * intI)) & intMask))

    def getValue(self, arrIn_a, intPos_a, intParts_a):
        intResult = 0
        for intI in range(intParts_a):
            intResult = intResult | (self.rom[self.getAddr(arrIn_a, intPos_a + intI * self.abytes) % self.x] << (self.vbits * intI))
        return intResult

    def valueOk(self, intValue_a, intParts_a):
        arrH = self.window(0, min(self.cap, self.x))
        intMask = (1 << self.vbits) - 1
        return self.hasAll(arrH, [(intValue_a >> (self.vbits * intI)) & intMask for intI in range(intParts_a)])

    def randValue(self, intLo_a, intHi_a, intParts_a):
        # a random value the header can carry (its parts all in the key's first span)
        intTries = 0
        intResult = m_objRand.randint(intLo_a, intHi_a)
        while not self.valueOk(intResult, intParts_a):
            intTries = intTries + 1
            if intTries > 4000:
                raise PlutoError('the key cannot carry a header value (%s)' % self.method)
            intResult = m_objRand.randint(intLo_a, intHi_a)
        return intResult

    def encode(self, arrData_a):
        arrOut = []
        arrElems = self.elements(arrData_a)
        intEff, intWin = regime(self.x, self.cap)
        arrLists = None
        intPtr = 0
        intOff = 0
        intP = 0
        intS = 0
        arrBlocks = []
        intI = 0
        intK = 0
        intN = 0
        intTries = 0
        arrNeed = sorted(set(arrElems))

        if self.kind == 'z':
            arrLists = self.window(0, min(self.cap, self.x))
            for intV in arrElems:
                self.putAddr(arrOut, self.pick(arrLists, intV))
        elif self.kind == 'u':
            # an offset whose span has every value the message needs
            intPtr = self.randValue(0, self.cap - 1, 2)
            intOff = offsetOf(intPtr, self.x, self.cap)
            while not self.hasAll(self.window(intOff, intOff + intEff), arrNeed):
                intTries = intTries + 1
                if intTries > 200:
                    raise PlutoError('the key lacks a value the message needs (%s)' % self.method)
                intPtr = self.randValue(0, self.cap - 1, 2)
                intOff = offsetOf(intPtr, self.x, self.cap)
            intP = self.randValue(10, self.pmax, 1)
            intS = self.randValue(10, self.pmax, 1)
            self.putValue(arrOut, intPtr, 2)
            self.putValue(arrOut, intP, 1)
            self.putValue(arrOut, intS, 1)
            arrOut.extend(m_objRand.randrange(256) for intI in range(intP))
            arrLists = self.window(intOff, intOff + intEff)
            for intV in arrElems:
                self.putAddr(arrOut, self.pick(arrLists, intV) - intOff)
            arrOut.extend(m_objRand.randrange(256) for intI in range(intS))
        else:
            # blocks: [start, bytes, ptr, offset]
            intI = 0
            while intI < len(arrData_a) or len(arrBlocks) == 0:
                intN = min(m_objRand.randint(self.bmin, self.bmax), len(arrData_a) - intI)
                arrNeed = sorted(set(arrElems[intI * self.unit:(intI + intN) * self.unit]))
                intTries = 0
                intPtr = self.randValue(0, self.cap - 1, 2)
                intOff = offsetOf(intPtr, self.x, self.cap)
                while not self.hasAll(self.window(intOff, intOff + intEff), arrNeed):
                    intTries = intTries + 1
                    if intTries > 200:
                        raise PlutoError('the key lacks a value the message needs (%s)' % self.method)
                    intPtr = self.randValue(0, self.cap - 1, 2)
                    intOff = offsetOf(intPtr, self.x, self.cap)
                arrBlocks.append([intI, intN, intPtr, intOff])
                intI = intI + intN
            if not self.valueOk(arrBlocks[0][1], 2):
                raise PlutoError('the key cannot carry a block size (%s)' % self.method)
            intP = self.randValue(10, self.pmax, 1)
            intS = self.randValue(10, self.pmax, 1)
            self.putValue(arrOut, arrBlocks[0][2], 2)
            self.putValue(arrOut, arrBlocks[0][1], 2)
            self.putValue(arrOut, intP, 1)
            self.putValue(arrOut, intS, 1)
            arrOut.extend(m_objRand.randrange(256) for intI in range(intP))
            for intK in range(len(arrBlocks)):
                if intK + 1 < len(arrBlocks):
                    if not self.valueOk(arrBlocks[intK + 1][1], 2):
                        raise PlutoError('the key cannot carry a block size (%s)' % self.method)
                    self.putValue(arrOut, arrBlocks[intK + 1][2], 2)
                    self.putValue(arrOut, arrBlocks[intK + 1][1], 2)
                else:
                    self.putValue(arrOut, self.randValue(0, self.cap - 1, 2), 2)
                    self.putValue(arrOut, self.randValue(0, self.cap - 1, 2), 2)
                intOff = arrBlocks[intK][3]
                arrLists = self.window(intOff, intOff + intEff)
                for intV in arrElems[arrBlocks[intK][0] * self.unit:(arrBlocks[intK][0] + arrBlocks[intK][1]) * self.unit]:
                    self.putAddr(arrOut, self.pick(arrLists, intV) - intOff)
            arrOut.extend(m_objRand.randrange(256) for intI in range(intS))
        return bytes(arrOut)

    def decode(self, arrIn_a):
        arrIn = list(arrIn_a)
        arrElems = []
        intEff, intWin = regime(self.x, self.cap)
        intPos = 0
        intEnd = len(arrIn)
        intOff = 0
        intP = 0
        intS = 0
        intSize = 0
        intNextPtr = 0
        intNextSize = 0
        intI = 0
        intA = self.abytes

        if self.kind == 'z':
            while intPos + intA <= intEnd:
                arrElems.append(self.rom[self.getAddr(arrIn, intPos) % self.x])
                intPos = intPos + intA
        elif self.kind == 'u':
            if len(arrIn) < 4 * intA:
                raise PlutoError('too short for %s' % self.method)
            intOff = offsetOf(self.getValue(arrIn, 0, 2), self.x, self.cap)
            intP = self.getValue(arrIn, 2 * intA, 1)
            intS = self.getValue(arrIn, 3 * intA, 1)
            intPos = 4 * intA + intP
            intEnd = len(arrIn) - intS
            while intPos + intA <= intEnd:
                arrElems.append(self.rom[(intOff + self.getAddr(arrIn, intPos) % intEff) % self.x])
                intPos = intPos + intA
        else:
            if len(arrIn) < 6 * intA:
                raise PlutoError('too short for %s' % self.method)
            intOff = offsetOf(self.getValue(arrIn, 0, 2), self.x, self.cap)
            intSize = self.getValue(arrIn, 2 * intA, 2)
            intP = self.getValue(arrIn, 4 * intA, 1)
            intS = self.getValue(arrIn, 5 * intA, 1)
            intPos = 6 * intA + intP
            intEnd = len(arrIn) - intS
            while intPos + 4 * intA <= intEnd:
                intNextPtr = self.getValue(arrIn, intPos, 2)
                intNextSize = self.getValue(arrIn, intPos + 2 * intA, 2)
                intPos = intPos + 4 * intA
                for intI in range(intSize * self.unit):
                    if intPos + intA <= intEnd:
                        arrElems.append(self.rom[(intOff + self.getAddr(arrIn, intPos) % intEff) % self.x])
                    intPos = intPos + intA
                intOff = offsetOf(intNextPtr, self.x, self.cap)
                intSize = intNextSize
        return bytes(self.bytesOf(arrElems))


def parseLayers(strSpec_a):
    # "z:K1 mu:K2" -> [(method, keyname)], 1-3 of them
    arrResult = []
    for strPart in strSpec_a.split():
        if ':' not in strPart:
            raise PlutoError('a layer is method:key - ' + strPart)
        strM, strK = strPart.split(':', 1)
        strM = strM.lower()
        if strM not in LAYERS:
            raise PlutoError('no such method: ' + strM)
        arrResult.append((strM, strK.upper()))
    if len(arrResult) < 1 or len(arrResult) > 3:
        raise PlutoError('1 to 3 layers')
    return arrResult


def loadKey(strName_a, strDir_a):
    strPath = os.path.join(strDir_a, strName_a + '.KEY')
    if not os.path.exists(strPath):
        strPath = os.path.join(strDir_a, strName_a.lower() + '.key')
    with open(strPath, 'rb') as objF:
        arrResult = objF.read()
    return arrResult


def encodeLayers(arrLayers_a, arrData_a):
    arrResult = bytes(arrData_a)
    for objL in arrLayers_a:
        arrResult = objL.encode(arrResult)
    return arrResult


def decodeLayers(arrLayers_a, arrData_a):
    arrResult = bytes(arrData_a)
    for objL in reversed(arrLayers_a):
        arrResult = objL.decode(arrResult)
    return arrResult


def selfTest():
    intBad = 0
    arrMsg = b'Hello from Pluto - the CPC edition of NTS. ' * 13
    arrKeys = {
        'tiny': bytes(range(256)) * 3,                                   # 768 bytes: rule 1
        'k64': bytes(m_objRand.randrange(256) for i in range(65536)),    # rule 1 (64K < 66846)
        'k100': bytes(m_objRand.randrange(256) for i in range(100000)),  # rule 2
        'k128': bytes(m_objRand.randrange(256) for i in range(131072)),  # rule 3
        'm128': bytes(m_objRand.randrange(256) for i in range(128)),     # micro 256 nibbles: rule 1
        'm200': bytes(m_objRand.randrange(256) for i in range(200)),     # micro 400 nibbles: rule 2
        'm256': bytes(m_objRand.randrange(256) for i in range(256)),     # micro 512: rule 3
    }
    for strM in LAYERS:
        for strK in arrKeys:
            if (strM[0] == 'm') != (strK[0] == 'm') and strK != 'tiny':
                continue
            objL = Layer(strM, arrKeys[strK])
            for arrM in (arrMsg, b'', b'x', bytes(range(256))):
                try:
                    arrE = objL.encode(arrM)
                    arrD = objL.decode(arrE)
                    if arrD != arrM:
                        print('FAIL %s %s %d' % (strM, strK, len(arrM)))
                        intBad = intBad + 1
                except PlutoError as objE:
                    print('ERR  %s %s %d: %s' % (strM, strK, len(arrM), objE))
                    intBad = intBad + 1
            print('ok   %-2s %-5s %d -> %d' % (strM, strK, len(arrMsg), len(objL.encode(arrMsg))))
    arrLs = [Layer('mu', arrKeys['m128']), Layer('z', arrKeys['k64']), Layer('b', arrKeys['k128'])]
    arrE = encodeLayers(arrLs, arrMsg)
    if decodeLayers(arrLs, arrE) != arrMsg:
        print('FAIL 3 layers')
        intBad = intBad + 1
    else:
        print('ok   mu z b: %d -> %d' % (len(arrMsg), len(arrE)))
    return intBad


def main(arrArgs_a):
    intResult = 0
    if len(arrArgs_a) >= 1 and arrArgs_a[0] == 't':
        intResult = 1 if selfTest() else 0
    elif len(arrArgs_a) >= 4 and arrArgs_a[0] in ('e', 'd'):
        strDir = arrArgs_a[4] if len(arrArgs_a) > 4 else 'KEYS'
        arrLayers = [Layer(strM, loadKey(strK, strDir)) for (strM, strK) in parseLayers(arrArgs_a[1])]
        with open(arrArgs_a[2], 'rb') as objF:
            arrData = objF.read()
        if arrArgs_a[0] == 'e':
            arrData = encodeLayers(arrLayers, arrData)
        else:
            arrData = decodeLayers(arrLayers, arrData)
        with open(arrArgs_a[3], 'wb') as objF:
            objF.write(arrData)
    else:
        print(__doc__ or 'pluto.py e|d "layers" infile outfile [keysdir] | t')
        intResult = 2
    return intResult


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
