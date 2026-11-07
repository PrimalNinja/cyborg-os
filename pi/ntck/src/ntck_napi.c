/* ntck_napi.c - Node.js binding for the NTCK integer runtime (plain C, N-API, no C++).
 *
 * Exports (so far):
 *   dot(x: Int8Array, planes: Uint8Array[k][in/4] flattened, k: number, mant: Int16Array, shift: number, useLut: boolean) -> BigInt
 *   version() -> string
 *
 * Build (Linux/Pi, no node-gyp):  gcc -O2 -shared -fPIC -I/usr/include/node -o ntck.node src/*.c
 * Or with node-gyp via the included binding.gyp.
 */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <node_api.h>
#include "tritdot.h"
#include "genmdl.h"

#define G_MAX_MODELS 64
static GenMdl* g_arrModels[G_MAX_MODELS];
static uint8_t* g_arrModelData[G_MAX_MODELS];

#define G_MAX_K 8

static int gb_get_typed(napi_env objEnv_a, napi_value objVal_a, void** ptrData_a, size_t* ptrLen_a)
{
    napi_typedarray_type intType;
    napi_value objBuf;
    size_t szOffset;
    napi_status intStatus = napi_get_typedarray_info(objEnv_a, objVal_a, &intType, ptrLen_a, ptrData_a, &objBuf, &szOffset);
    return (intStatus == napi_ok) ? 1 : 0;
}

static napi_value gb_dot(napi_env objEnv_a, napi_callback_info objInfo_a)
{
    size_t szArgc = 6;
    napi_value arrArgs[6];
    napi_value objResult = NULL;
    void* ptrX = NULL;
    void* ptrPlanes = NULL;
    void* ptrMant = NULL;
    size_t szIn = 0;
    size_t szPlanes = 0;
    size_t szMant = 0;
    int32_t intK = 0;
    int32_t intShift = 0;
    bool blnLut = false;
    int blnOk = 1;
    const uint8_t* arrPlanes[G_MAX_K];
    int intJ;
    int64_t i64Out = 0;
    int16_t* ptrLuts = NULL;

    napi_get_cb_info(objEnv_a, objInfo_a, &szArgc, arrArgs, NULL, NULL);
    if (szArgc < 6)
    {
        blnOk = 0;
    }
    if (blnOk)
    {
        blnOk = gb_get_typed(objEnv_a, arrArgs[0], &ptrX, &szIn) && gb_get_typed(objEnv_a, arrArgs[1], &ptrPlanes, &szPlanes)
             && gb_get_typed(objEnv_a, arrArgs[3], &ptrMant, &szMant);
        napi_get_value_int32(objEnv_a, arrArgs[2], &intK);
        napi_get_value_int32(objEnv_a, arrArgs[4], &intShift);
        napi_get_value_bool(objEnv_a, arrArgs[5], &blnLut);
    }
    if (blnOk)
    {
        blnOk = (intK >= 1 && intK <= G_MAX_K && (szIn % G_BLOCK) == 0 && szPlanes == (size_t)intK * szIn / G_GROUP && szMant == szIn / G_BLOCK);
    }
    if (!blnOk)
    {
        napi_throw_error(objEnv_a, NULL, "dot: bad arguments (x Int8Array multiple of 32, planes k*in/4 bytes, mant in/32 int16)");
    }
    else
    {
        for (intJ = 0; intJ < intK; intJ++)
        {
            arrPlanes[intJ] = (const uint8_t*)ptrPlanes + (size_t)intJ * szIn / G_GROUP;
        }
        if (blnLut)
        {
            ptrLuts = (int16_t*)malloc(sizeof(int16_t) * (szIn / G_GROUP) * G_LUT);
            gb_prepare_luts((const int8_t*)ptrX, (int)szIn, ptrLuts);
            i64Out = gb_dot_lut(ptrLuts, arrPlanes, intK, (const int16_t*)ptrMant, intShift, (int)szIn);
            free(ptrLuts);
        }
        else
        {
            i64Out = gb_dot_scalar((const int8_t*)ptrX, arrPlanes, intK, (const int16_t*)ptrMant, intShift, (int)szIn);
        }
        napi_create_bigint_int64(objEnv_a, i64Out, &objResult);
    }
    return objResult;
}


/* ---- GEN.MDL (the Z80 ternary GRU) ---- */
static int gb_model_arg(napi_env objEnv_a, napi_value objVal_a)
{
    int32_t intId = -1;
    napi_get_value_int32(objEnv_a, objVal_a, &intId);
    return (intId >= 0 && intId < G_MAX_MODELS && g_arrModels[intId] != NULL) ? intId : -1;
}

/* mdlLoad(buffer: Buffer|Uint8Array) -> id */
static napi_value gb_mdl_load(napi_env objEnv_a, napi_callback_info objInfo_a)
{
    size_t szArgc = 1;
    napi_value arrArgs[1];
    napi_value objResult = NULL;
    void* ptrData = NULL;
    size_t szLen = 0;
    int intId = -1;
    int intI;
    napi_get_cb_info(objEnv_a, objInfo_a, &szArgc, arrArgs, NULL, NULL);
    if (szArgc >= 1 && gb_get_typed(objEnv_a, arrArgs[0], &ptrData, &szLen))
    {
        for (intI = 0; intI < G_MAX_MODELS; intI++)
        {
            if (g_arrModels[intI] == NULL && intId < 0)
            {
                intId = intI;
            }
        }
    }
    if (intId >= 0)
    {
        g_arrModelData[intId] = (uint8_t*)malloc(szLen);
        memcpy(g_arrModelData[intId], ptrData, szLen);
        g_arrModels[intId] = (GenMdl*)malloc(sizeof(GenMdl));
        if (!gb_genmdl_load(g_arrModels[intId], g_arrModelData[intId], szLen))
        {
            free(g_arrModels[intId]);
            free(g_arrModelData[intId]);
            g_arrModels[intId] = NULL;
            g_arrModelData[intId] = NULL;
            intId = -1;
        }
    }
    if (intId < 0)
    {
        napi_throw_error(objEnv_a, NULL, "mdlLoad: not a GENM v1/v2 model (or no free slot)");
    }
    else
    {
        napi_create_int32(objEnv_a, intId, &objResult);
    }
    return objResult;
}

/* mdlFree(id) */
static napi_value gb_mdl_free(napi_env objEnv_a, napi_callback_info objInfo_a)
{
    size_t szArgc = 1;
    napi_value arrArgs[1];
    int intId;
    napi_get_cb_info(objEnv_a, objInfo_a, &szArgc, arrArgs, NULL, NULL);
    intId = (szArgc >= 1) ? gb_model_arg(objEnv_a, arrArgs[0]) : -1;
    if (intId >= 0)
    {
        free(g_arrModels[intId]);
        free(g_arrModelData[intId]);
        g_arrModels[intId] = NULL;
        g_arrModelData[intId] = NULL;
    }
    return NULL;
}

/* mdlInfo(id) -> { v, e, h, l, k, charset } */
static napi_value gb_mdl_info(napi_env objEnv_a, napi_callback_info objInfo_a)
{
    size_t szArgc = 1;
    napi_value arrArgs[1];
    napi_value objResult = NULL;
    napi_value objV;
    int intId;
    GenMdl* ptrM;
    napi_get_cb_info(objEnv_a, objInfo_a, &szArgc, arrArgs, NULL, NULL);
    intId = (szArgc >= 1) ? gb_model_arg(objEnv_a, arrArgs[0]) : -1;
    if (intId < 0)
    {
        napi_throw_error(objEnv_a, NULL, "mdlInfo: bad model id");
    }
    else
    {
        ptrM = g_arrModels[intId];
        napi_create_object(objEnv_a, &objResult);
        napi_create_int32(objEnv_a, ptrM->intV, &objV); napi_set_named_property(objEnv_a, objResult, "v", objV);
        napi_create_int32(objEnv_a, ptrM->intE, &objV); napi_set_named_property(objEnv_a, objResult, "e", objV);
        napi_create_int32(objEnv_a, ptrM->intH, &objV); napi_set_named_property(objEnv_a, objResult, "h", objV);
        napi_create_int32(objEnv_a, ptrM->intL, &objV); napi_set_named_property(objEnv_a, objResult, "l", objV);
        napi_create_int32(objEnv_a, ptrM->intK, &objV); napi_set_named_property(objEnv_a, objResult, "k", objV);
        napi_create_string_latin1(objEnv_a, (const char*)ptrM->ptrCharset, ptrM->intV, &objV);
        napi_set_named_property(objEnv_a, objResult, "charset", objV);
    }
    return objResult;
}

/* mdlReset(id) */
static napi_value gb_mdl_reset(napi_env objEnv_a, napi_callback_info objInfo_a)
{
    size_t szArgc = 1;
    napi_value arrArgs[1];
    int intId;
    napi_get_cb_info(objEnv_a, objInfo_a, &szArgc, arrArgs, NULL, NULL);
    intId = (szArgc >= 1) ? gb_model_arg(objEnv_a, arrArgs[0]) : -1;
    if (intId >= 0)
    {
        gb_genmdl_reset(g_arrModels[intId]);
    }
    return NULL;
}

/* mdlRun(id, prompt: string, n: number) -> string
 * Feeds the prompt (state carries on from any earlier call; mdlReset to start over), then writes
 * n greedy characters, exactly as GEN / GRU at noise 0 on the Z80. */
static napi_value gb_mdl_run(napi_env objEnv_a, napi_callback_info objInfo_a)
{
    size_t szArgc = 3;
    napi_value arrArgs[3];
    napi_value objResult = NULL;
    int intId;
    int32_t intN = 0;
    char* strPrompt = NULL;
    size_t szLen = 0;
    size_t szI;
    char* strOut = NULL;
    int intC = 0;
    GenMdl* ptrM;
    napi_get_cb_info(objEnv_a, objInfo_a, &szArgc, arrArgs, NULL, NULL);
    intId = (szArgc >= 3) ? gb_model_arg(objEnv_a, arrArgs[0]) : -1;
    if (intId < 0)
    {
        napi_throw_error(objEnv_a, NULL, "mdlRun: bad arguments (id, prompt, n)");
    }
    else
    {
        ptrM = g_arrModels[intId];
        napi_get_value_string_latin1(objEnv_a, arrArgs[1], NULL, 0, &szLen);
        strPrompt = (char*)malloc(szLen + 1);
        napi_get_value_string_latin1(objEnv_a, arrArgs[1], strPrompt, szLen + 1, &szLen);
        napi_get_value_int32(objEnv_a, arrArgs[2], &intN);
        if (intN < 0 || intN > 65536)
        {
            intN = 0;
        }
        strOut = (char*)malloc((size_t)intN + 1);
        for (szI = 0; szI < szLen; szI++)
        {
            intC = gb_genmdl_feed(ptrM, gb_genmdl_index(ptrM, (unsigned char)strPrompt[szI]));
        }
        for (szI = 0; szI < (size_t)intN; szI++)
        {
            strOut[szI] = (char)ptrM->ptrCharset[intC];
            intC = gb_genmdl_feed(ptrM, intC);
        }
        napi_create_string_latin1(objEnv_a, strOut, (size_t)intN, &objResult);
        free(strPrompt);
        free(strOut);
    }
    return objResult;
}

static napi_value gb_version(napi_env objEnv_a, napi_callback_info objInfo_a)
{
    napi_value objResult;
    napi_create_string_utf8(objEnv_a, "ntck 0.2 (tritdot, genmdl)", NAPI_AUTO_LENGTH, &objResult);
    return objResult;
}

static napi_value gb_init(napi_env objEnv_a, napi_value objExports_a)
{
    napi_property_descriptor arrProps[] = {
        { "dot", NULL, gb_dot, NULL, NULL, NULL, napi_default, NULL },
        { "mdlLoad", NULL, gb_mdl_load, NULL, NULL, NULL, napi_default, NULL },
        { "mdlFree", NULL, gb_mdl_free, NULL, NULL, NULL, napi_default, NULL },
        { "mdlInfo", NULL, gb_mdl_info, NULL, NULL, NULL, napi_default, NULL },
        { "mdlReset", NULL, gb_mdl_reset, NULL, NULL, NULL, napi_default, NULL },
        { "mdlRun", NULL, gb_mdl_run, NULL, NULL, NULL, napi_default, NULL },
        { "version", NULL, gb_version, NULL, NULL, NULL, napi_default, NULL }
    };
    napi_define_properties(objEnv_a, objExports_a, 7, arrProps);
    return objExports_a;
}

NAPI_MODULE(ntck, gb_init)
