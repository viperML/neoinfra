#!/usr/bin/env bash
set -euxo pipefail

DIR="$(cd $(dirname ${BASH_SOURCE[0]}); pwd)"

name="nixos-$(nix eval --raw .#nixosConfigurations.sumati-base.config.system.nixos.version)"

pushd $DIR
packer build \
    -var "name=$name" \
    $DIR/main.pkr.hcl
