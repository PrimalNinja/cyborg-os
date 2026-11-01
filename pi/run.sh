#!/bin/sh
# run.sh - start cosd with the vendored Node.js for this Pi (../3p/nodejs, 3p beside pi): run.sh [cosd options]
HERE=$(cd "$(dirname "$0")" && pwd)
case "$(uname -m)" in
  aarch64) NODE="$HERE/../3p/nodejs/linux-arm64/node" ;;
  armv7l)  NODE="$HERE/../3p/nodejs/linux-armv7l/node" ;;
  *)       NODE="$(command -v node)" ;;             # a PC: the system's node
esac
exec "$NODE" "$HERE/cosd.js" "$@"
