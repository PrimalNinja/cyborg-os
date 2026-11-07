# pi/ntck - the model runtime, native on the Pi (C, callable from Node)

Runs the Z80's generative model (`GEN.MDL`, the k-trit GRU of `ntc/src/lib/z80/Net.cls`) natively,
with the same integer arithmetic: byte-identical output to the CPC, ~1000x the speed. Also holds
the k-trit lookup-table dot product (`tritdot.c`) for the NTCK transformer format (in progress).

    cd pi/ntck && sh build.sh            # gcc only: needs the node headers (/usr/include/node;
                                         # Raspberry Pi OS: apt install nodejs - they come with it)
    node test.js                         # tritdot (scalar + LUT) vs a JS reference, 75 cases
    node test_mdl.js ../../../ntc/test/net_t.mdl ../../src/bas/cyborgosc2/apps/gen/GEN.MDL
                                         # the GRU vs the Z80's proven output (net_t.txt, GEN)
    (or: node-gyp rebuild, with binding.gyp)

API (`require('./ntck.node')`):
    mdlLoad(buffer) -> id          mdlInfo(id) -> {v,e,h,l,k,charset}       mdlReset(id)
    mdlRun(id, prompt, n) -> string  (feeds prompt, writes n greedy chars; state carries on)
    mdlFree(id)                    dot(x, planes, k, mant, shift, lut) -> BigInt    version()

The MIND service (`pi/svc/mind.js`) serves it over the link: MODELS, LOAD name, RUN n text,
RESET, INFO. Models live in ~/.cosd/models/NAME.MDL (or cosd --models=DIR).

Files: src/genmdl.c/.h (the GRU, MDL v1/v2 loader), src/tables.h (Tiny's tanh/sigm, frozen),
src/tritdot.c/.h (k-trit dot, scalar + 81-entry LUT), src/ntck_napi.c (the Node binding).
Verified: net_t.mdl (K=8) and GEN.MDL (K=2) match the Z80 byte for byte.
(c) 2026 Cyborg Unicorn Pty Ltd - MIT License
