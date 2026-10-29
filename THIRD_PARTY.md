# Third-party components

Paper Anki connects existing projects; it does not implement Anki's scheduler or reMarkable's display driver.

| Component | Source / release | License / role |
|---|---|---|
| Anki | [ankitects/anki 26.09.3](https://github.com/ankitects/anki/releases/tag/26.09.3) | AGPL-3.0; full app, scheduler, sync, bundled Python and Qt WebEngine dependencies |
| XOVI and Qt resource rebuilder | [rm-xovi-extensions v19-23052026](https://github.com/asivery/rm-xovi-extensions/releases/tag/v19-23052026), [XOVI](https://github.com/asivery/xovi) | Upstream licenses; extension source is GPL-3.0 |
| AppLoad | [asivery/rm-appload v0.6.0](https://github.com/asivery/rm-appload/releases/tag/v0.6.0) | GPL-3.0; launcher and Qt frontend host |
| xovi-tripletap | [rmitchellscott/xovi-tripletap](https://github.com/rmitchellscott/xovi-tripletap/tree/46c6a959a6761bbda7410c905640a0ff48c2d9d9) | GPL-3.0; optional power-button helper and evtest binary |
| Ubuntu Base | [Ubuntu Base 24.04](https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/) | Per-package licenses; see `/usr/share/doc/*/copyright` inside the runtime |
| TigerVNC | [TigerVNC](https://github.com/TigerVNC/tigervnc) | GPL-2.0 and component licenses; local X/VNC desktop |
| Openbox | [Openbox](http://openbox.org/) | GPL-2.0; local window manager |
| Qt | [Qt](https://www.qt.io/licensing/) | Qt's applicable LGPL/GPL/commercial terms; dynamically linked tablet runtime and Anki's own bundled runtime |

`assets/anki.png` is the icon from the official Anki Linux distribution and retains that project's attribution/license. The six SVG toolbar icons are original simple vector drawings for this integration. `assets/demo.png` is a capture of the included synthetic test content.

No Ubuntu root filesystem, Anki executable, Qt library, XOVI/AppLoad binary, or vendor resource hash table is committed here. The fetch helper downloads the official Anki and Ubuntu archives and verifies the pinned SHA-256 digests. If distributing a binary bundle, retain relevant licenses and comply with the corresponding-source obligations of all redistributed components.
