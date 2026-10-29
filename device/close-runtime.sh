#!/bin/sh
set -eu
# Let Anki close its collection and handle any unsaved editing dialogs.
touch /home/root/anki-desktop/rootfs/home/anki/.paper-anki-close
