#!/usr/bin/env bash
set -euxo pipefail
# Running on ubuntu

apt update -y
apt install -y \
    gdisk \
    parted \
    util-linux

DISK="/dev/sda"
sgdisk --zap-all $DISK

sgdisk -n1:1M:+300M -t1:EF02 $DISK
sgdisk -n2:0:0      -t2:8300 $DISK

partprobe $DISK
wipefs -a "$DISK"1
wipefs -a "$DISK"2

mkfs.ext4 -F -L BOOT "$DISK"1

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
    -f tank "$DISK"2

zfs create -o mountpoint=legacy tank/rootfs
zfs create -o mountpoint=legacy tank/nix
zfs create -o mountpoint=legacy tank/var
zfs create -o mountpoint=legacy tank/secrets

mkdir -p /mnt
mount -t zfs tank/rootfs /mnt
mkdir -p /mnt/{boot,nix,var,secrets}
mount "$DISK"1 /mnt/boot
mount -t zfs tank/nix /mnt/nix
mount -t zfs tank/var /mnt/var
mount -t zfs tank/secrets /mnt/secrets


## Install nix
VERSION="2.8.0"
curl -o install https://releases.nixos.org/nix/nix-$VERSION/install
curl -o install.asc https://releases.nixos.org/nix/nix-$VERSION/install.asc
gpg2 --keyserver hkps://keyserver.ubuntu.com --recv-keys B541D55301270E0BCF15CA5D8170B4726D7198DE
gpg2 --verify ./install.asc

sh ./install
set +u
. /root/.nix-profile/etc/profile.d/nix.sh
set -u

echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

nixos-install --no-root-passwd --flake=github:viperML/neoinfra#nixosConfigurations.sumati
