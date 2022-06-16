#!/usr/bin/env bash
set -euxo pipefail

DIR="$(cd $(dirname ${BASH_SOURCE[0]}); pwd)"

name="$(nix eval .#nixosConfigurations.sumati.config.system.nixosVersion)"

pushd $DIR
packer build \
    -var "name=$name" \
    $DIR/main.pkr.hcl
