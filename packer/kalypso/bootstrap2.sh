#!/usr/bin/env bash
set -euxo pipefail

ESP=/efi
FLAKE=github:viperML/neoinfra

set +ux
. /nix/var/nix/profiles/default/etc/profile.d/nix.sh
. /etc/profile
set -ux

echo "extra-experimental-features = nix-command flakes" | tee -a /etc/nix/nix.conf

# Needed to install the bootloader
touch /etc/NIXOS

nix profile install $FLAKE#git

nix build \
	--profile /nix/var/nix/profiles/system \
	--print-build-logs \
	$FLAKE#nixosConfigurations.kalypso-base.config.system.build.toplevel


export NIXOS_INSTALL_BOOTLOADER=1
rm -rf /boot/efi/*
mkdir -pv $ESP
mount /dev/disk/by-label/UEFI $ESP
/nix/var/nix/profiles/system/bin/switch-to-configuration boot
umount $ESP

mkdir -p /new-var

# 0 1 are nix and nsscert from installer
# 2 is git installed before
nix profile remove 0 1 2
