#!/usr/bin/env -S nix shell .#bash .#sops .#step-cli .#remarshal .#age .#moreutils --command bash
# shellcheck shell=bash
set -euxo pipefail

HOST="$1"

ROOT="$(cd "$(dirname "${BASH_SOURCE[@]}")"; cd ..; pwd)"
pushd "$ROOT"

: "$CA_FINGERPRINT"

export TEMP="$XDG_RUNTIME_DIR/ca-bootstrap-$HOST"
export STEPPATH=$TEMP

step_rekey() {
    step ca bootstrap \
        --ca-url https://ca.ayats.org \
        --fingerprint "$CA_FINGERPRINT" \
        --force

    step ssh certificate \
        --host \
        --force \
        --insecure \
        --no-password \
        "$HOST" "$TEMP/ssh_host_ecdsa_key"

    step ssh config \
        --force \
        --roots > "$ROOT/secrets/$HOST-ssh_user_key.pub"
}

if [[ -d "$TEMP" ]]; then
    read -p "Regen age key? [y/N] " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        step_rekey
    fi
else
    step_rekey
fi



dd status=none of="$TEMP/result.toml" <<EOF
ssh_host_ecdsa_key = '''
$(<"$TEMP"/ssh_host_ecdsa_key)
'''

ssh_host_ecdsa_key-cert-pub = '''
$(<"$TEMP"/ssh_host_ecdsa_key-cert.pub)
'''

root_ca_crt = '''
$(<"$TEMP"/certs/root_ca.crt)
'''

step-defaults = '''
$(<"$TEMP"/config/defaults.json)
'''
EOF

toml2yaml --yaml-style "|" "$TEMP/result.toml" "$ROOT/secrets/temp-$HOST-ssh.yaml"

sops -e "$ROOT/secrets/temp-$HOST-ssh.yaml" > "$ROOT/secrets/$HOST-ssh.yaml"

rm "$ROOT"/secrets/temp-*

read -p "Regen age key? [y/N] " -n 1 -r
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    AGE_PATH="$ROOT/secrets/$HOST.age"
    rm -fv "$AGE_PATH"
    age-keygen -o "$AGE_PATH"
    AGE_PUB=$(age-keygen -y "$AGE_PATH")

    sed -ne "/&$HOST/!p" .sops.yaml | sponge "$ROOT/.sops.yaml"
    sed -e "/keys:/a \  - &$HOST $AGE_PUB" .sops.yaml | sponge "$ROOT/.sops.yaml"
fi

for f in "$ROOT"/secrets/"$HOST"*.yaml; do
    sops updatekeys --yes "$f"
done
