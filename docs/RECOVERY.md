# Recovery

## Blank screen or failed AppLoad frontend

Connect by USB SSH, then restore the normal reMarkable interface:

```sh
systemctl reset-failed xochitl
/home/root/xovi/stock
```

If Anki is still running, request a normal save/close:

```sh
/home/root/anki-desktop/close-runtime.sh
systemctl status paper-anki-runtime
```

Reopen Anki to complete any unsaved-editor or sync dialog. A forced service stop can interrupt saving/sync; use it only when the normal close path cannot finish.

Check a candidate UI before enabling it:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /home/root/anki-desktop/qmlcheck \
  /home/root/xovi/exthome/appload/anki/resources.rcc \
  /home/root/anki-desktop/logs/ui-check.png
```

Exit 0 means QML instantiated and the image was saved; it does not prove physical touch, sleep/wake, or sync. The checker neither starts nor closes Anki. If a runtime is already active, its current content appears in the capture—keep that image private.

A previous toolbar revision used Qt Quick's `Accessible` attached object. This tablet's Qt build did not provide it, so the entire frontend failed to load. Those declarations were removed; the exact-device preflight now catches that class of failure. A plain label property is not equivalent to working native screen-reader support.

## Firmware update

XOVI injection is temporary and does not persist across reboot. After an OS update, the guarded start script refuses to enable it until the new firmware is independently validated. Regenerate the resource hash table, rebuild/test against the applicable Qt runtime, and only then update the validated firmware record and installer compatibility. The optional helper service may need reinstalling because OS updates replace the root partition.

During development, repeated deliberate restarts hit xochitl's start limit and caused its configured failure recovery to reboot the tablet. Reset the failed counter before maintenance and investigate errors before trying again; do not disable the host's recovery safeguards.

## Runtime problems

```sh
journalctl -u paper-anki-runtime -n 80 --no-pager
cat /home/root/anki-desktop/rootfs/home/anki/vnc.log
cat /home/root/anki-desktop/rootfs/home/anki/paper-anki-status.json
```

- Missing desktop: confirm `paper-anki-runtime` is active, then use Refresh.
- Stale display lock after reboot: the runtime removes stale display `:7` locks only when no Xtigervnc process exists.
- Network/media failure: reconnect Wi-Fi, tap Sync, and wait for media sync. Local downloaded cards and notes remain usable offline.
- Missing Notes illustrations: confirm media sync has completed; verify the note's media references on the laptop.
- Anki sandbox failure: use `root-runner`; a plain chroot is insufficient. Do not add `--no-sandbox` to work around it.

## Disable without deleting study data

Restore stock with the commands above. Close Anki normally. Move `/home/root/xovi/exthome/appload/anki` outside the AppLoad application root, e.g. into `/home/root/anki-desktop/disabled-apps/`.

If installed, stop `paper-anki-tripletap`, remove only its service and `multi-user.target.wants` symlink under `/usr/lib/systemd/system`, reload systemd, and restore the root filesystem's prior read-only mode. Do not remove other XOVI helpers or applications.

Keep `/home/root/anki-desktop/rootfs/home/anki/Anki` until a verified backup and successful sync exist. Removing the integration does not require deleting this profile. Files from the normal reMarkable notebook library are not part of this integration.
