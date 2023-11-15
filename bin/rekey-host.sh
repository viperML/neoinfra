#!/usr/bin/env -S nix shell .#bash .#sops .#step-cli .#remarshal .#age .#moreutils --command bash
# shellcheck shell=bash
set -euxo pipefail

HOST="$1"

ROOT="$(cd "$(dirname "${BASH_SOURCE[@]}")"; cd ..; pwd)"
pushd "$ROOT"


export TEMP="$XDG_RUNTIME_DIR/ca-bootstrap-$HOST"
export STEPPATH=$TEMP




read -p "Regen age key? [y/N] " -n 1 -r
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    AGE_PATH="$ROOT/secrets/$HOST.age"
    rm -fv "$AGE_PATH"
    age-keygen -o "$AGE_PATH"
    AGE_PUB=$(age-keygen -y "$AGE_PATH")

    sed -ne "/&$HOST/!p" .sops.yaml | sponge "$ROOT/.sops.yaml"
    sed -e "/keys:/a \  - &$HOST $AGE_PUB" .sops.yaml | sponge "$ROOT/.sops.yaml"
fi

toml2yaml --yaml-style "|" "$TEMP/result.toml" "$ROOT/secrets/temp-$HOST-ssh.yaml"
sops -e "$ROOT/secrets/temp-$HOST-ssh.yaml" > "$ROOT/secrets/$HOST-ssh.yaml"

rm "$ROOT"/secrets/temp-*

for f in "$ROOT"/secrets/"$HOST"*.yaml; do
    sops updatekeys --yes "$f"
done
