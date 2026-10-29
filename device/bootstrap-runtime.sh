#!/bin/bash
# Run once on the tablet, after uploading the verified runtime archives.
set -euo pipefail
base=/home/root/anki-desktop
[[ $(id -u) = 0 && $(uname -m) = aarch64 ]] || { echo 'Requires root on ARM64.' >&2; exit 1; }
[[ -f "$base/ubuntu.tar.gz" && -f "$base/anki.tar.zst" ]] || { echo 'Upload the verified runtime archives first.' >&2; exit 1; }
[[ ! -e "$base/rootfs/etc/os-release" ]] || { echo 'A runtime already exists. Refusing to replace it or its profiles.' >&2; exit 1; }
(cd "$base" && printf '%s\n' \
    '04207713ece899c3740823d33690441ad3a7f0ded1101aca744e2b0f37ac7ff2  ubuntu.tar.gz' \
    '0b586efdb0e3582bee3b9d08b9fa57df681fb97a8066d76a6743e1bc3fc331eb  anki.tar.zst' | sha256sum -c -)
mkdir -p "$base/rootfs" "$base/logs"
tar -xzf "$base/ubuntu.tar.gz" -C "$base/rootfs"
cp -L /etc/resolv.conf "$base/rootfs/etc/resolv.conf"
mount -t proc proc "$base/rootfs/proc"
mount --rbind /dev "$base/rootfs/dev"
mount --make-rslave "$base/rootfs/dev"
printf '#!/bin/sh\nexit 101\n' > "$base/rootfs/usr/sbin/policy-rc.d"
chmod +x "$base/rootfs/usr/sbin/policy-rc.d"
chroot "$base/rootfs" /bin/bash -c '
set -e
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tigervnc-standalone-server openbox xdotool x11-utils \
    libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
    libxcb-render-util0 libxcb-xinerama0 libxkbcommon-x11-0 libnss3 \
    libasound2t64 libegl1 libgl1 libopengl0 libglib2.0-0t64 libdbus-1-3 \
    libfontconfig1 libfreetype6 libxcomposite1 libxdamage1 libxrandr2 \
    libxtst6 libxkbfile1 libxss1 libxshmfence1 libdrm2 libgbm1 \
    libgssapi-krb5-2 libwayland-client0 libwayland-cursor0 libwayland-egl1 \
    libudev1 libpulse0 fonts-dejavu-core ca-certificates zstd python3 \
    libsnappy1v5 libwebpmux3 libminizip1t64
'
mkdir -p "$base/rootfs/opt/anki" "$base/rootfs/opt/paper-anki"
chroot "$base/rootfs" /usr/bin/zstd -dc < "$base/anki.tar.zst" | tar -x -C "$base/rootfs/opt/anki" --strip-components=1
chroot "$base/rootfs" /usr/sbin/useradd -m -u 2000 -s /bin/bash anki
printf 'Runtime prepared. Install the app package next.\n'
