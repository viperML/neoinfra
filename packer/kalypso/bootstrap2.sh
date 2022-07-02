#!/usr/bin/env bash
set -euxo pipefail

set +ux
. /nix/var/nix/profiles/default/etc/profile.d/nix.sh
. /etc/profile
set -ux

echo "extra-experimental-features = nix-command flakes" | tee -a /etc/nix/nix.conf

touch /etc/NIXOS

nix build --profile /nix/var/nix/profiles/system github:viperML/neoinfra#nixosConfigurations.kalypso-base.config.system.build.toplevel

mkdir /efi
mount /dev/disk/by-label/UEFI /efi
export NIXOS_INSTALL_BOOTLOADER=1
/nix/var/nix/profiles/system/bin/switch-to-configuration boot

rm -rf /etc
