#!/bin/sh
set -eu
/home/root/anki-desktop/check-firmware.sh
# Do not restart an already enabled launcher when the power shortcut is repeated.
if systemctl show xochitl --property=Environment | grep -q 'LD_PRELOAD=/home/root/xovi/xovi.so'; then
    exit 0
fi
systemctl reset-failed xochitl
exec /home/root/xovi/start.upstream
