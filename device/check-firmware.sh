#!/bin/sh
set -eu
. /etc/os-release
expected=$(cat /home/root/anki-desktop/validated-firmware)
if [ "$IMG_VERSION" != "$expected" ]; then
    echo "AppLoad setup needs validation for firmware $IMG_VERSION (last validated: $expected)." >&2
    echo "The normal reMarkable interface has been left running." >&2
    exit 1
fi
