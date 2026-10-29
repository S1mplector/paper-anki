# Build and installation

These are development instructions for **Paper Pure firmware 3.29.0.153**. The individual components were installed and tested on a real tablet; the consolidated fresh-install workflow has not yet been repeated on a wiped device. Preserve existing profiles and take a backup before replacing an existing setup.

## 1. Build on a Linux host

Install CMake, Ninja, and Python 3.11+. Obtain the official reMarkable SDK:

https://storage.googleapis.com/remarkable-codex-toolchain/3.28.0.172/remarkable-production-image-5.8.203-tatsu-public-x86_64-toolchain.sh

Download and inspect the SDK installer, install it into a dedicated directory, then source its `environment-setup-cortexa55-remarkable-linux` file. This provides the ARM64 compiler, Qt 6.10.3 headers, CMake configuration, and host resource compiler.

From this repository:

```sh
./host/build.sh
python3 host/fetch.py
./host/package.sh
```

`host/fetch.py` verifies pinned SHA-256 digests from `host/downloads.json`. Build output is in `build/`, runtime archives in `.cache/`, and the integration package is `dist/paper-anki-aarch64.tar.gz`. Runtime archives and SDK files are deliberately not committed.

## 2. Prepare AppLoad

Enable Developer Mode and connect USB. Use the SSH password shown by your own tablet. Verify its host fingerprint; do not disable SSH host checking or put the password in scripts.

Use the ARM64 assets from:

- [XOVI bundle v19-23052026](https://github.com/asivery/rm-xovi-extensions/releases/tag/v19-23052026): `xovi-aarch64.tar.gz`
- [AppLoad v0.6.0](https://github.com/asivery/rm-appload/releases/tag/v0.6.0): `appload-aarch64.tar.gz`

Follow the upstream XOVI and AppLoad installation instructions. XOVI lives at `/home/root/xovi`; `appload.so` belongs in its `extensions.d`, and the AppLoad application root is `/home/root/xovi/exthome/appload`. Retain the AppLoad archive's supporting shims according to upstream instructions.

Generate a resource hash table on the actual installed firmware using `/home/root/xovi/rebuild_hashtable`. Do not copy a hash table from a different firmware. Before intentional xochitl maintenance, run `systemctl reset-failed xochitl`; avoid repeated restart loops. Keep SSH connected during initial validation and restore `systemctl start xochitl` if hash generation exits without restarting it.

Run `/home/root/xovi/start` once and confirm the AppLoad sidebar works before installing this integration. Do not configure XOVI to inject at boot.

## 3. Upload and prepare Ubuntu/Anki

On the host:

```sh
ssh root@10.11.99.1 'mkdir -p /home/root/anki-desktop'
scp .cache/ubuntu.tar.gz .cache/anki.tar.zst root@10.11.99.1:/home/root/anki-desktop/
scp dist/paper-anki-aarch64.tar.gz root@10.11.99.1:/home/root/
ssh root@10.11.99.1
```

On the tablet:

```sh
cd /home/root
tar -xzf paper-anki-aarch64.tar.gz
bash paper-anki/device/bootstrap-runtime.sh
bash paper-anki/device/install-app.sh
```

The bootstrap script verifies archive hashes again, refuses to overwrite an existing runtime, installs Ubuntu packages, and creates an unprivileged Anki user. Internet access is required for Ubuntu packages. The app installer refuses unsupported firmware or a running Anki runtime, backs up existing launcher/plugin files, and checks the QML on the actual tablet before replacing the app resource.

Once installed, restart the host UI once to load the native plugin:

```sh
systemctl reset-failed xochitl
systemctl restart xochitl
```

Open **sidebar → AppLoad → Anki**. Refresh AppLoad's app list if needed. The first launch takes several seconds.

## 4. Account and notes

Sign in through Anki's Sync button. On an empty new profile, download the existing AnkiWeb collection; do not upload an empty/test collection over your account. Wait for media sync to finish. Keep credentials in Anki's normal private profile storage.

The Notes reader recognizes deck names ending in `::Notes` with `Title` and `Body` fields. Optional fields and annotation format are documented in [Architecture](ARCHITECTURE.md). Existing Notes suspension and review history are preserved. The reader does not import arbitrary laptop documents: content must already be stored in and synced through these Anki notes.

## Optional power-button shortcut

The helper is optional; SSH `/home/root/xovi/start` always remains available. Download `main.sh`, `evtest.arm64`, and `LICENSE` from [xovi-tripletap commit 46c6a95](https://github.com/rmitchellscott/xovi-tripletap/tree/46c6a959a6761bbda7410c905640a0ff48c2d9d9). Install them into `/home/root/xovi-tripletap`, naming the binary `evtest`. Create a `config` file containing:

```sh
ENABLE_VERSION_SWITCHING=false
TRIGGER_ACTION=start
TIME_THRESHOLD=2
REQUIRED_PRESSES=3
```

Then, from the extracted package on the tablet:

```sh
cp device/paper-anki-tripletap.service /home/root/anki-desktop/
bash device/install-shortcut.sh
```

The installer temporarily remounts the root writable, installs only this helper service under `/usr/lib/systemd/system`, and restores its prior mount mode. The helper listens after boot; it does not inject XOVI until the power-button gesture. The wrapper refuses a changed firmware and avoids restarting an already-enabled launcher. Physical triple-press and extended sleep/wake remain unverified in this release.

## Updating

Close Anki and let sync finish first. Keep a private backup of its complete `Anki` directory. Build a new package, upload/extract it, run `install-app.sh`, and restart the native UI once. Replace shared libraries/resources by writing a new file and renaming it; never truncate a library currently mapped into xochitl. A native plugin change requires a UI restart; a resource-only change can be picked up by refreshing AppLoad's list.

A firmware update requires a newly generated resource table and separate Qt/plugin validation. See [Recovery](RECOVERY.md). Do not just change the validated-version text to bypass the check.
