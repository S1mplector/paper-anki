# Architecture

```text
reMarkable xochitl + XOVI + AppLoad
    └─ QML toolbar + native PaperAnki QQuickPaintedItem
          └─ loopback RFB 3.8, port 5907
                └─ TigerVNC / Openbox, display :7
                      └─ official ARM64 Anki + Qt WebEngine
                            └─ normal Anki collection and AnkiWeb sync
```

Everything runs on the tablet. RFB is only an internal display transport; there is no desktop streaming from a laptop. Native xochitl keeps owning the e-ink display and touch input, which avoids competing standalone display clients.

## Runtime and sandbox

`runtime.sh` prepares `/dev` and `/proc` mounts under `/home/root/anki-desktop/rootfs`, refreshes DNS, removes stale X locks only when no VNC process exists, and executes `root-runner`.

`root-runner` creates private mount and PID namespaces, pivots into the Ubuntu root, detaches the old root, and mounts a new `/proc` and read-only `/sys`. The session then drops privileges to UID 2000 (`anki`). The pivot is necessary because Chromium's user namespace sandbox cannot initialize correctly inside an ordinary chroot. The app does **not** use `--no-sandbox`; only GPU acceleration is disabled.

This is not a security boundary for hostile software. The runtime shares the host network and device nodes, and the launcher/native plugin run with the host interface's privileges. Install trusted add-ons and cards. VNC is unauthenticated but binds IPv4/IPv6 loopback only, and X11 TCP listening is disabled.

The root filesystem normally remains read-only. Almost all files live in `/home/root`. The optional power-button service is the explicit exception; its installer restores the previous root mount mode afterward. Do not replace xochitl boot services with automatic XOVI injection.

## Rendering and input

The minimal C++ RFB client accepts raw 32-bit updates and checks rectangle bounds before copying pixels. It schedules incremental requests at up to 20 frames/second and repaints the changed bounding rectangle. The native item maps touch-generated mouse events into the 936 × 1200 virtual desktop. The displayed desktop scales to the available AppLoad surface. Qt inside the desktop uses scale factor 1.25.

The server cursor is hidden to avoid a dragged cursor leaving additional e-ink trails. Mouse dragging remains text selection or a native desktop drag; it is not converted into a mobile scrolling gesture. Toolbar arrows send mouse-wheel events. The keyboard sends X keysyms, including Unicode input for characters provided by the frontend.

On close/unload, the plugin creates a close request. The Anki add-on polls it and calls Anki's ordinary close path. Unsaved editors and sync dialogs can defer exit. The service owns the entire runtime process group; normal Anki exit tears down the VNC session. Refresh reconnects or starts a stopped runtime.

## Notes and tablet appearance

The add-on overrides `Overview._renderPage` and `_renderBottom` only for deck names ending in `::Notes`. Notes must contain `Title` and `Body`; `Course`, `Lecture`, `Visuals`, and `Source` are optional. Pages are sorted by Title, as in the original desktop reader. Media uses Anki's local media server, so downloaded illustrations work offline.

Existing annotations are read from collection config `study_annotations_<note GUID>`. Each entry can have `start`, `end`, `quote`, and `text`. Highlight offsets are checked against the article text before marking it; mismatched offsets still leave the annotation readable in the list. Annotation text is inserted as text, not executable HTML. Rich-text formatting is shown as its saved plain-text equivalent. The tablet reader never modifies annotation config, cards, note fields, suspension, or scheduling.

Tablet CSS is appended through Anki's content/card hooks. It removes decorative backgrounds and animations without changing any synced note-type CSS or fields. Thus tablet presentation changes do not alter laptop presentation.

## Local data and diagnostics

- Profile: `/home/root/anki-desktop/rootfs/home/anki/Anki/User 1`
- Add-on: `.../Anki/addons21/paper_pure`
- Account/preferences: Anki's normal `prefs21.db`, kept private
- Health: `.../home/anki/paper-anki-status.json` (profile, state, counts, media-sync status; no card contents)
- Runtime log: `journalctl -u paper-anki-runtime`
- VNC log: `.../home/anki/vnc.log`
- UI preflight: `/home/root/anki-desktop/qmlcheck`

Do not upload profiles, account databases, real screenshots, or verbose logs containing private content to public issues. Development QA helpers are not installed by the package.
