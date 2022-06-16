#!/usr/bin/env bash
set -euo pipefail

name="nixos-$(nix eval --raw .#nixosConfigurations.sumati-base.config.system.nixos.version)"

cat <<JSON
{
    "name": "$name"
}
JSON
