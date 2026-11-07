#!/bin/sh
# Builds ntck.node without node-gyp. Pi: same command. Needs the node headers (apt install nodejs / nodejs-dev).
set -e
gcc -O2 -shared -fPIC -I/usr/include/node -o ntck.node src/tritdot.c src/genmdl.c src/ntck_napi.c -lm
echo "built ntck.node"
