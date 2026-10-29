#!/bin/bash
set -eu
mkdir -p /run/anki
chown anki:anki /run/anki
chmod 700 /run/anki
exec runuser -u anki -- /opt/paper-anki/user-session.sh
