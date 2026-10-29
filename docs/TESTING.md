# Validation record

Validated on a real Paper Pure, firmware 3.29.0.153, on 2026-10-29. This is a development release; observed working behavior is distinguished from untested cases below.

## Passed

- Cross-compilation of native Qt plugin, namespace helper, QML checker, and resource bundle using the official ARM64 SDK.
- Actual tablet Qt loads the SVG toolbar; offscreen capture visually inspected before deployment.
- User confirmed AppLoad opens Anki and the larger scale is comfortable.
- User confirmed the plain Notes reader works, including page controls and scrolling on the physical screen.
- Several real Notes decks rendered; next-page navigation and downloaded illustrations checked in the actual Anki webview. Existing saved annotations displayed.
- Before/after database row hashes for cards, notes, and review history were identical across the read-only Notes checks.
- Synthetic Notes fixture displayed its highlight, illustration, and saved annotation. The public screenshot contains this fixture only.
- Synthetic question and answer both computed white backgrounds, no wallpaper, and dark text despite a deliberately dark test template.
- Test-card reviews saved and survived graceful close/reopen in the separate Hardware Test profile. No real cards were graded by the tests.
- Normal account profile restored afterward; media-sync status inactive after completion.
- Runtime restart and stale-lock handling exercised during development.
- Unprivileged user namespace creation succeeds under the pivot-root helper. Chromium's sandbox is not disabled.
- VNC port 5907 listens only on IPv4/IPv6 loopback; X11 TCP listening disabled.
- Normal xochitl interface remains active alongside the Anki runtime; exiting returns to it.

## Not yet established

- Long-duration battery drain, extended sleep/wake, physical triple-press behavior, and a fresh reboot after the final optional shortcut-service install.
- A clean-device replay of the consolidated installer, complete uninstall/reinstall, or firmware versions other than those listed.
- Audio/video playback, arbitrary third-party add-ons/templates, handwriting, complex keyboard composition, and native accessibility support.

## Repeatable local checks

On the host:

```sh
for script in host/*.sh device/*.sh; do bash -n "$script"; done
python3 -m py_compile host/fetch.py device/tablet-addon.py device/notes_reader.py tests/create-fixture.py
node --check device/notes_reader.js
./host/build.sh
./host/package.sh
```

On the tablet, run the QML preflight in [Recovery](RECOVERY.md) before replacing a frontend. Review the capture and tool output; successful compilation alone is not a touch test.

To create harmless test content, close Anki first. Upload `tests/create-fixture.py` into the runtime's `/tmp`, then run:

```sh
chroot /home/root/anki-desktop/rootfs /usr/sbin/runuser -u anki -- \
  env PYTHONPATH=/opt/anki/app_packages \
  /opt/anki/python/bin/python3 /tmp/create-fixture.py
```

The fixture uses only `/home/anki/Anki/Hardware Test`, creates two basic cards and two suspended Notes, and skips creation if its tag already exists. Do not add account credentials to this profile. It does not reset existing test reviews.

Start the separate profile with:

```sh
systemd-run --unit=paper-anki-runtime --collect \
  -p TimeoutStopSec=20 -p KillMode=control-group \
  -E 'PAPER_ANKI_PROFILE=Hardware Test' /home/root/anki-desktop/runtime.sh
```

Test reveal/rate, exit/reopen, reader page arrows, highlight navigation, scroll, keyboard, and Add. Wait for normal exit before launching another profile. Stop the test session normally and launch from AppLoad to restore the default `User 1` profile. Never use a real study collection for automated rating tests.
