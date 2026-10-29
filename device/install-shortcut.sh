#!/bin/sh
set -eu
base=/home/root/anki-desktop
chmod +x /home/root/xovi-tripletap/main.sh /home/root/xovi-tripletap/evtest
was_ro=0
if awk '$2=="/" && $4 ~ /(^|,)ro(,|$)/ {found=1} END {exit !found}' /proc/mounts; then
    was_ro=1
    mount -o remount,rw /
fi
restore() { [ "$was_ro" = 0 ] || mount -o remount,ro /; }
trap restore EXIT INT TERM
cp "$base/paper-anki-tripletap.service" /usr/lib/systemd/system/paper-anki-tripletap.service
mkdir -p /usr/lib/systemd/system/multi-user.target.wants
ln -sfn ../paper-anki-tripletap.service /usr/lib/systemd/system/multi-user.target.wants/paper-anki-tripletap.service
systemctl daemon-reload
systemctl start paper-anki-tripletap
