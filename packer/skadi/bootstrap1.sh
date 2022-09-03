#!/usr/bin/env bash
set -euxo pipefail

curl -Ls -o install https://nixos.org/nix/install

chmod +x ./install
./install --daemon --no-channel-add

echo "extra-experimental-features = nix-command flakes" >> /etc/nix/nix.conf
