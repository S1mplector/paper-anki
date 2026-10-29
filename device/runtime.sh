#!/bin/sh
set -eu
base=/home/root/anki-desktop
cd "$base"
mountpoint -q rootfs/proc || mount -t proc proc rootfs/proc
if ! mountpoint -q rootfs/dev; then
    mount --rbind /dev rootfs/dev
    mount --make-rslave rootfs/dev
fi
cp -L /etc/resolv.conf rootfs/etc/resolv.conf
if pidof Xtigervnc >/dev/null; then
    echo "A tablet desktop is already running." >&2
    exit 1
fi
rm -f rootfs/tmp/.X7-lock rootfs/tmp/.X11-unix/X7
rm -f rootfs/home/anki/.paper-anki-close
exec ./root-runner "$base/rootfs" /opt/paper-anki/session.sh
