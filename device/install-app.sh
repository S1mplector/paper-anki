#!/bin/bash
# Execute from the extracted paper-anki package directory on the tablet.
set -euo pipefail
package=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
base=/home/root/anki-desktop
source /etc/os-release
[[ "$IMG_VERSION" = 3.29.0.153 ]] || { echo "Firmware $IMG_VERSION has not been validated by this release." >&2; exit 1; }
[[ -d /home/root/xovi/exthome/appload ]] || { echo 'Install and validate AppLoad first.' >&2; exit 1; }
[[ -x "$base/rootfs/opt/anki/anki" ]] || { echo 'Prepare the runtime first.' >&2; exit 1; }
if systemctl is-active --quiet paper-anki-runtime; then
    echo 'Close Anki and allow its sync to finish before updating.' >&2
    exit 1
fi
mkdir -p "$base/qml/PaperAnki" "$base/logs" /home/root/xovi/exthome/appload/anki
if [[ -f "$base/qml/PaperAnki/libpaperankiplugin.so" ]]; then
    backup="$base/backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup"
    cp -a "$base/qml" "$backup/"
    cp -a /home/root/xovi/exthome/appload/anki "$backup/appload"
fi
cp "$package/root-runner" "$package/qmlcheck" "$base/"
cp "$package/qml/PaperAnki/qmldir" "$base/qml/PaperAnki/"
cp "$package/qml/PaperAnki/libpaperankiplugin.so" "$base/qml/PaperAnki/libpaperankiplugin.next.so"
mv "$base/qml/PaperAnki/libpaperankiplugin.next.so" "$base/qml/PaperAnki/libpaperankiplugin.so"
cp "$package/device/"{runtime.sh,start-runtime.sh,close-runtime.sh,check-firmware.sh} "$base/"
cp "$package/device/"{session.sh,user-session.sh} "$base/rootfs/opt/paper-anki/"
mkdir -p "$base/rootfs/home/anki/Anki/addons21/paper_pure"
cp "$package/device/tablet-addon.py" "$base/rootfs/home/anki/Anki/addons21/paper_pure/__init__.py"
cp "$package/device/"{notes_reader.py,notes_reader.js,notes_reader.css,paper.css} "$base/rootfs/home/anki/Anki/addons21/paper_pure/"
chown -R 2000:2000 "$base/rootfs/home/anki/Anki/addons21/paper_pure"
chmod +x "$base/"*.sh "$base/root-runner" "$base/qmlcheck" "$base/rootfs/opt/paper-anki/"*.sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software "$base/qmlcheck" "$package/appload/resources.rcc" "$base/logs/ui-preflight.png"
cp "$package/appload/"{icon.png,manifest.json} /home/root/xovi/exthome/appload/anki/
cp "$package/appload/resources.rcc" /home/root/xovi/exthome/appload/anki/resources.next.rcc
mv /home/root/xovi/exthome/appload/anki/resources.next.rcc /home/root/xovi/exthome/appload/anki/resources.rcc
printf '%s\n' "$IMG_VERSION" > "$base/validated-firmware"
if [[ ! -f /home/root/xovi/start.upstream ]]; then cp -p /home/root/xovi/start /home/root/xovi/start.upstream; fi
cp "$package/device/xovi-start-guarded.sh" /home/root/xovi/start
chmod +x /home/root/xovi/start
printf 'Installed and UI preflight passed. Restart the reMarkable UI once to load the new native plugin, then open AppLoad → Anki.\n'
