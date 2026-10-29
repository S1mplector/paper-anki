#!/bin/sh
set -eu
rm -f /home/root/anki-desktop/rootfs/home/anki/.paper-anki-close
systemctl is-active --quiet paper-anki-runtime && exit 0
exec systemd-run --unit=paper-anki-runtime --collect -p TimeoutStopSec=20 -p KillMode=control-group /home/root/anki-desktop/runtime.sh
