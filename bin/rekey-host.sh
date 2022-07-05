#!/usr/bin/env bash
set -euxo pipefail

HOST="$1"

ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]}); cd ..; pwd)"
pushd $ROOTDIR

: $CA_FINGERPRINT

export TEMP=$XDG_RUNTIME_DIR/ca-bootstrap
export STEPPATH=$TEMP

step ca bootstrap \
    --ca-url https://ca.ayats.org \
    --fingerprint $CA_FINGERPRINT \
    --force

step ssh certificate \
    --host \
    --force \
    --insecure \
    --no-password \
    $HOST $TEMP/ssh_host_ecdsa_key

dd status=none of=$TEMP/result.toml <<EOF
ssh_host_ecdsa_key = '''
$(<$TEMP/ssh_host_ecdsa_key)
'''

ssh_host_ecdsa_key-cert-pub = '''
$(<$TEMP/ssh_host_ecdsa_key-cert.pub)
'''
EOF

toml2yaml --yaml-style "|" $TEMP/result.toml $ROOTDIR/secrets/temp-$HOST-ssh.yaml

sops -e $ROOTDIR/secrets/temp-$HOST-ssh.yaml > $ROOTDIR/secrets/$HOST-ssh.yaml

rm $ROOTDIR/secrets/temp-*

AGE_PATH=$ROOTDIR/packer/$HOST/$HOST.age
rm -fv $AGE_PATH
age-keygen -o $AGE_PATH
AGE_PUB=$(age-keygen -y $AGE_PATH)

sed -ne "/&$HOST/!p" .sops.yaml | sponge $ROOTDIR/.sops.yaml
sed -e "/keys/a \  - &$HOST $AGE_PUB" .sops.yaml | sponge $ROOTDIR/.sops.yaml

for f in $ROOTDIR/secrets/$HOST*.yaml; do
    sops updatekeys --yes $f
done
