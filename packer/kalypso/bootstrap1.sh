#!/usr/bin/env bash
set -euxo pipefail

NIXVERSION="2.9.2"
curl -o install https://releases.nixos.org/nix/nix-$NIXVERSION/install
chmod +x ./install
./install --daemon --no-channel-add

