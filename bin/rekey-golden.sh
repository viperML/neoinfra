#!/usr/bin/env -S nix shell .#sops .#age .#moreutils --command bash
# shellcheck shell=bash
set -eux

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[@]}")"; cd ..; pwd)"

AGE_PATH="$ROOT_DIR/secrets/golden.age"
rm -fv "$AGE_PATH"

age-keygen -o "$AGE_PATH"

AGE_PUB="$(age-keygen -y "$AGE_PATH")"

sed -ne "/&golden/!p" "$ROOT_DIR/.sops.yaml" | sponge "$ROOT_DIR/.sops.yaml"
sed -e "/keys:/a \  - &golden $AGE_PUB" "$ROOT_DIR/.sops.yaml" | sponge "$ROOT_DIR/.sops.yaml"

sops updatekeys --yes "$ROOT_DIR/secrets/golden.yaml"
