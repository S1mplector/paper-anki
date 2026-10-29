#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
: "${OECORE_TARGET_SYSROOT:?Source the matching reMarkable SDK environment first.}"
cmake -S "$repo" -B "$repo/build" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$repo/build" --parallel "${JOBS:-4}"
