#!/bin/bash
set -eu
export HOME=/home/anki USER=anki LOGNAME=anki LANG=C.UTF-8
export DISPLAY=:7 XDG_RUNTIME_DIR=/run/anki
export QT_QPA_PLATFORM=xcb QT_OPENGL=software LIBGL_ALWAYS_SOFTWARE=1
export QTWEBENGINE_CHROMIUM_FLAGS=--disable-gpu
export QT_SCALE_FACTOR=1.25
Xtigervnc :7 -geometry 936x1200 -depth 24 -localhost yes -nolisten tcp -SecurityTypes None -AlwaysShared -FrameRate 20 -nocursor > "$HOME/vnc.log" 2>&1 &
vnc=$!
trap 'kill "$vnc" 2>/dev/null || true' EXIT
for attempt in {1..100}; do
    xdpyinfo >/dev/null 2>&1 && break
    kill -0 "$vnc" || exit 1
    sleep 0.1
done
xdpyinfo >/dev/null
openbox > "$HOME/openbox.log" 2>&1 &
cd /opt/anki
./anki -b /home/anki/Anki -p "${PAPER_ANKI_PROFILE:-User 1}" -l en_US
