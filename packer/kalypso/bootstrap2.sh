#!/usr/bin/env bash
set -euxo pipefail

ESP=/efi

set +ux
. /nix/var/nix/profiles/default/etc/profile.d/nix.sh
. /etc/profile
set -ux

echo "extra-experimental-features = nix-command flakes" | tee -a /etc/nix/nix.conf

# Needed to install the bootloader
touch /etc/NIXOS

nix build \
	--profile /nix/var/nix/profiles/system \
	--print-build-logs \
	github:viperML/neoinfra#nixosConfigurations.kalypso-base.config.system.build.toplevel

export NIXOS_INSTALL_BOOTLOADER=1

rm -rf /boot/efi/*

mkdir -pv $ESP
mount /dev/disk/by-label/UEFI $ESP

/nix/var/nix/profiles/system/bin/switch-to-configuration boot

umount $ESP

echo "sayonara"

rm -rfv \
	bin \
	boot \
	# dev \
	etc \
	home \
	lib \
	lost+found \
	media \
	mnt \
	opt \
	# proc \
	root \
	# run \
	sbin \
	snap \
	srv \
	# sys \
	tmp \
	usr \
	var
