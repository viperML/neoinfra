#!/usr/bin/env bash
set -euxo pipefail

DIR="$(cd ${BASH_SOURCE[0]}; pwd)"

name="$(nix eval .#nixosConfigurations.sumati.config.system.nixosVersion)"

packer build $DIR/main.pkr.hcl \
    -var "name=$name"
