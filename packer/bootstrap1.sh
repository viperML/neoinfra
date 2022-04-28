#!/usr/bin/env bash
set -euxo pipefail

# Prepare ZFS

export DEBIAN_FRONTEND=noninteractive

tee -a /etc/apt/sources.list.d/bullseye-backports.list <<EOF
deb http://deb.debian.org/debian bullseye-backports main contrib
deb-src http://deb.debian.org/debian bullseye-backports main contrib
EOF

tee -a /etc/apt/preferences.d/90_zfs <<EOF
Package: libnvpair1linux libnvpair3linux libuutil1linux libuutil3linux libzfs2linux libzfs4linux libzpool2linux libzpool4linux spl-dkms zfs-dkms zfs-test zfsutils-linux zfsutils-linux-dev zfs-zed
Pin: release n=bullseye-backports
Pin-Priority: 990
EOF

apt update -y
apt install -y \
    gdisk \
    parted \
    util-linux \
    zfsutils-linux \
    zfs-dkms \
    sudo

rm -f /usr/local/sbin/{zpool,zfs}

DISK="/dev/sda"
sgdisk --zap-all $DISK

sgdisk -a1 -n1:2048:4095 -t1:EF02 $DISK
sgdisk -a1 -n2:0:+300M   -t2:8300 $DISK
sgdisk     -n3:0:0       -t3:8300 $DISK

partprobe $DISK
wipefs -a "$DISK"1
wipefs -a "$DISK"2

mkfs.ext4 -F -L BOOT "$DISK"2

zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl \
    -O compression=zstd \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O atime=off \
    -O xattr=sa \
    -O mountpoint=none \
    -R /mnt \
    -f tank "$DISK"3

zfs create -o mountpoint=legacy tank/rootfs
zfs snap tank/rootfs@empty
zfs create -o mountpoint=legacy tank/nix
zfs create -o mountpoint=legacy tank/var
zfs create -o mountpoint=legacy tank/secrets

mkdir -p /mnt
mount -t zfs tank/rootfs /mnt
mkdir -p /mnt/{boot,nix,var,secrets}
mount /dev/disk/by-label/BOOT /mnt/boot
mount -t zfs tank/nix /mnt/nix
mount -t zfs tank/var /mnt/var
mount -t zfs tank/secrets /mnt/secrets


# Download nix installer
NIXVERSION="2.8.0"
curl -o install https://releases.nixos.org/nix/nix-$NIXVERSION/install
curl -o install.asc https://releases.nixos.org/nix/nix-$NIXVERSION/install.asc
gpg2 --keyserver hkps://keyserver.ubuntu.com --recv-keys B541D55301270E0BCF15CA5D8170B4726D7198DE
gpg2 --verify ./install.asc

# Add an user to run the installer and run it
useradd nixinstaller
usermod -aG sudo nixinstaller
echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/nixinstaller
chown :nixinstaller ./install
chmod ug+x ./install
sudo -u nixinstaller sh ./install --no-channel-add --daemon --daemon-user-count 4
set +u
# shellcheck source=/dev/null
. /root/.nix-profile/etc/profile.d/nix.sh
set -u

tee -a /etc/nix/nix.conf <<EOF
experimental-features = nix-command flakes
auto-optimise-store = true
EOF

nix profile install github:viperML/neoinfra#nixos-install-tools
nixos-install --no-root-passwd --flake github:viperML/neoinfra#sumati
