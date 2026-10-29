#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
stage="$repo/dist/paper-anki"
mkdir -p "$stage/qml/PaperAnki" "$stage/appload" "$stage/device"
cp "$repo/build/libpaperankiplugin.so" "$repo/app/qmldir" "$stage/qml/PaperAnki/"
cp "$repo/build/root-runner" "$repo/build/qmlcheck" "$stage/"
cp "$repo/build/resources.rcc" "$repo/app/manifest.json" "$stage/appload/"
cp "$repo/assets/anki.png" "$stage/appload/icon.png"
cp "$repo"/device/*.sh "$repo"/device/*.py "$repo"/device/*.js "$repo"/device/*.css "$repo"/device/*.service "$stage/device/"
mkdir -p "$stage/docs" "$stage/tests"
cp "$repo"/docs/*.md "$stage/docs/"
cp "$repo"/tests/*.py "$stage/tests/"
cp "$repo/README.md" "$repo/LICENSE" "$repo/THIRD_PARTY.md" "$stage/"
(cd "$repo/dist" && tar -czf paper-anki-aarch64.tar.gz paper-anki)
sha256sum "$repo/dist/paper-anki-aarch64.tar.gz"
