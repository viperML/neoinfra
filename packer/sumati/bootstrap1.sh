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
    sudo

export DISK="/dev/sda"
sgdisk --zap-all $DISK

sgdisk -a1 -n5:0:1M      -t5:EF02 $DISK
sgdisk     -n1:0:+300M   -t1:8300 $DISK
sgdisk     -n2:0:+4G     -t2:8200 $DISK
sgdisk     -n3:0:0       -t3:8300 $DISK

partprobe $DISK
wipefs -a "$DISK"1
wipefs -a "$DISK"2
wipefs -a "$DISK"3

mkfs.ext4 -F -L BOOT "$DISK"1

mkswap -L SWAP -f "$DISK"2
swapon "$DISK"2

sudo apt install -y \
    zfsutils-linux \
    zfs-dkms
rm -f /usr/local/sbin/{zpool,zfs}

zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl \
    -O compression=lz4 \
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
zfs create -o mountpoint=legacy tank/docker


mkdir -p /mnt
mount -t zfs tank/rootfs /mnt
mkdir -p /mnt/{boot,nix,var}
mount /dev/disk/by-label/BOOT /mnt/boot
mount -t zfs tank/nix /mnt/nix
mount -t zfs tank/var /mnt/var
mkdir -p /mnt/var/lib/secrets
mount -t zfs tank/secrets /mnt/var/lib/secrets


# Download nix installer
NIXVERSION="2.9.1"
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
sudo -u nixinstaller sh ./install --no-channel-add --daemon
set +u
# shellcheck source=/dev/null
. /root/.nix-profile/etc/profile.d/nix.sh
set -u

tee -a /etc/nix/nix.conf <<EOF
extra-experimental-features = nix-command flakes
EOF

nix profile install github:viperML/neoinfra#nixos-install-tools
nixos-install --no-root-passwd --flake github:viperML/neoinfra#sumati-golden

swapoff "$DISK"2
