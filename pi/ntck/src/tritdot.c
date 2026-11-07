/* tritdot.c - k-trit integer dot product for the NTCK format, Pi/ARM native C.
 *
 * Weights: k planes of balanced trits {-1,0,1}, w = sum_j p_j * 3^j, packed 4 trits per byte per plane
 *          (base-3 index 0..80, trit t stored as t+1 in digit position).
 * Activations: int8.
 * Scale: per block of 32 inputs, int16 mantissa, per-tensor shift: out = sum_blocks(acc_b * mant_b) >> shift.
 *
 * Two paths, identical results:
 *   gb_dot_scalar : unpacks every trit and multiplies - the reference.
 *   gb_dot_lut    : per group of 4 activations builds an 81-entry table once, then one lookup per
 *                   (plane, group) replaces 4 multiply-adds. This is the Z80 trick; on ARM it maps
 *                   onto NEON TBL (hook marked below).
 *
 * Build: gcc -O2 -o tritdot tritdot.c    Test: python tritdot_test.py
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tritdot.h"


static const int32_t g_arrPow3[9] = { 1, 3, 9, 27, 81, 243, 729, 2187, 6561 };

/* unpack trit intPos (0..3) of a packed byte -> -1, 0, 1 */
static int gb_trit(uint8_t byPacked_a, int intPos_a)
{
    int intV = byPacked_a;
    int intI;
    for (intI = 0; intI < intPos_a; intI++)
    {
        intV /= 3;
    }
    return (intV % 3) - 1;
}

/* reference: one output row. ptrPlanes_a[k][inBytes], inBytes = intIn_a / 4 */
int64_t gb_dot_scalar(const int8_t* ptrX_a, const uint8_t* const* ptrPlanes_a, int intK_a,
                      const int16_t* ptrMant_a, int intShift_a, int intIn_a)
{
    int64_t i64Out = 0;
    int intBlocks = intIn_a / G_BLOCK;
    int intB;
    int intI;
    int intJ;
    int intW;
    int32_t i32Acc;
    for (intB = 0; intB < intBlocks; intB++)
    {
        i32Acc = 0;
        for (intI = intB * G_BLOCK; intI < (intB + 1) * G_BLOCK; intI++)
        {
            intW = 0;
            for (intJ = 0; intJ < intK_a; intJ++)
            {
                intW += gb_trit(ptrPlanes_a[intJ][intI / G_GROUP], intI % G_GROUP) * g_arrPow3[intJ];
            }
            i32Acc += (int32_t)ptrX_a[intI] * intW;
        }
        i64Out += (int64_t)i32Acc * ptrMant_a[intB];
    }
    return i64Out >> intShift_a;
}

/* build the 81-entry table for 4 activations: arrLut[idx] = sum_p (trit_p(idx)) * x[p] */
static void gb_build_lut(const int8_t* ptrX4_a, int16_t* arrLut_a)
{
    int intIdx;
    int intV;
    int intP;
    int intSum;
    for (intIdx = 0; intIdx < G_LUT; intIdx++)
    {
        intV = intIdx;
        intSum = 0;
        for (intP = 0; intP < G_GROUP; intP++)
        {
            intSum += ((intV % 3) - 1) * ptrX4_a[intP];
            intV /= 3;
        }
        arrLut_a[intIdx] = (int16_t)intSum;       /* |sum| <= 4*127 = 508 */
    }
}

/* lookup path: same contract as gb_dot_scalar. ptrLuts_a is scratch of (intIn_a/4)*81 int16, built once per activation vector */
void gb_prepare_luts(const int8_t* ptrX_a, int intIn_a, int16_t* ptrLuts_a)
{
    int intG;
    for (intG = 0; intG < intIn_a / G_GROUP; intG++)
    {
        gb_build_lut(ptrX_a + intG * G_GROUP, ptrLuts_a + intG * G_LUT);
    }
}

int64_t gb_dot_lut(const int16_t* ptrLuts_a, const uint8_t* const* ptrPlanes_a, int intK_a,
                   const int16_t* ptrMant_a, int intShift_a, int intIn_a)
{
    int64_t i64Out = 0;
    int intBlocks = intIn_a / G_BLOCK;
    int intGroupsPerBlock = G_BLOCK / G_GROUP;
    int intB;
    int intG;
    int intJ;
    int32_t i32Plane;
    int32_t i32Acc;
    for (intB = 0; intB < intBlocks; intB++)
    {
        i32Acc = 0;
        for (intJ = 0; intJ < intK_a; intJ++)
        {
            i32Plane = 0;
            /* NEON hook: this 8-iteration loop is 8 byte-indexed lookups into 8 tables - vtbl/TBX territory */
            for (intG = intB * intGroupsPerBlock; intG < (intB + 1) * intGroupsPerBlock; intG++)
            {
                i32Plane += ptrLuts_a[intG * G_LUT + ptrPlanes_a[intJ][intG]];
            }
            i32Acc += i32Plane * g_arrPow3[intJ];
        }
        i64Out += (int64_t)i32Acc * ptrMant_a[intB];
    }
    return i64Out >> intShift_a;
}

#ifdef TRITDOT_MAIN
/* ---- test driver: reads a binary case from stdin, prints both results ----
 * stdin: int32 k, in, shift | int8 x[in] | uint8 planes[k][in/4] | int16 mant[in/32]
 */
int main(void)
{
    int32_t arrHdr[3];
    int intRet = 0;
    if (fread(arrHdr, sizeof(int32_t), 3, stdin) != 3)
    {
        intRet = 1;
    }
    else
    {
        int intK = arrHdr[0];
        int intIn = arrHdr[1];
        int intShift = arrHdr[2];
        int8_t* ptrX = (int8_t*)malloc(intIn);
        uint8_t* ptrPlaneData = (uint8_t*)malloc((size_t)intK * intIn / G_GROUP);
        int16_t* ptrMant = (int16_t*)malloc(sizeof(int16_t) * intIn / G_BLOCK);
        int16_t* ptrLuts = (int16_t*)malloc(sizeof(int16_t) * (intIn / G_GROUP) * G_LUT);
        const uint8_t* arrPlanes[8];
        int intJ;
        int64_t i64A;
        int64_t i64B;
        if (fread(ptrX, 1, intIn, stdin) != (size_t)intIn) { intRet = 1; }
        if (fread(ptrPlaneData, 1, (size_t)intK * intIn / G_GROUP, stdin) != (size_t)intK * intIn / G_GROUP) { intRet = 1; }
        if (fread(ptrMant, sizeof(int16_t), intIn / G_BLOCK, stdin) != (size_t)(intIn / G_BLOCK)) { intRet = 1; }
        for (intJ = 0; intJ < intK; intJ++)
        {
            arrPlanes[intJ] = ptrPlaneData + (size_t)intJ * intIn / G_GROUP;
        }
        i64A = gb_dot_scalar(ptrX, arrPlanes, intK, ptrMant, intShift, intIn);
        gb_prepare_luts(ptrX, intIn, ptrLuts);
        i64B = gb_dot_lut(ptrLuts, arrPlanes, intK, ptrMant, intShift, intIn);
        printf("%lld %lld\n", (long long)i64A, (long long)i64B);
        free(ptrX);
        free(ptrPlaneData);
        free(ptrMant);
        free(ptrLuts);
    }
    return intRet;
}
#endif /* TRITDOT_MAIN */
