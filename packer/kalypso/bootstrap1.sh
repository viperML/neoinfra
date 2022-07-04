#!/usr/bin/env bash
set -euxo pipefail

NIXVERSION="2.9.2"
curl -o install https://releases.nixos.org/nix/nix-$NIXVERSION/install
# The ubuntu image comes without gpg so I won't bother to verify it

chmod +x ./install
./install --daemon --no-channel-add
