#!/usr/bin/env bash
set -euxo pipefail

NIXVERSION="2.9.2"
curl -o install https://releases.nixos.org/nix/nix-$NIXVERSION/install
curl -o install.asc https://releases.nixos.org/nix/nix-$NIXVERSION/install.asc
gpg2 --keyserver hkps://keyserver.ubuntu.com --recv-keys B541D55301270E0BCF15CA5D8170B4726D7198DE
gpg2 --verify ./install.asc


./install --daemon --no-channel-add

set +u
. /nix/var/nix/profiles/default/etc/profile.d/nix.sh
set -u

echo "extra-experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf

nix build --profile /nix/var/nix/profiles/system github:viperML/neoinfra#nixosConfigurations.kalypso-base.config.system.build.toplevel

sudo mkdir /efi
sudo mount /dev/disk/by-label/UEFI /efi

export NIXOS_INSTALL_BOOTLOADER=1
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot

sudo rm -rf /etc
