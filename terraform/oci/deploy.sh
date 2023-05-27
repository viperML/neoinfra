#!/usr/bin/env bash
set -eux

ROOT="$(cd "$(dirname "${BASH_SOURCE[@]}")"; pwd)"
ssh-add "$ROOT/id"

HOST="$1"
IP="$(terraform output -raw "$HOST"_ip)"


SYSTEM="$(nix eval --raw .#nixosConfigurations.shiva.pkgs.system)"

INSTALLER="$(nix build --no-link --print-out-paths .#packages."$SYSTEM".kexec-installer-noninteractive)/nixos-kexec-installer-noninteractive-$SYSTEM.tar.gz"

nix run github:numtide/nixos-anywhere -- \
    --kexec "$INSTALLER" \
    --flake .#"$HOST" \
    root@"$IP"