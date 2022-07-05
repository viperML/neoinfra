#!/usr/bin/env bash
set -euxo pipefail

ROOTDIR="$(cd $(dirname ${BASH_SOURCE[0]}); cd ..; pwd)"
TEMP=$(mktemp -d)

dd status=none of=$TEMP/result.toml <<EOF
vault_config = '''
$(<$ROOTDIR/secrets/vault.hcl)
'''
EOF

toml2yaml --yaml-style "|" $TEMP/result.toml $ROOTDIR/secrets/temp-vault.yaml

sops -e $ROOTDIR/secrets/temp-vault.yaml > $ROOTDIR/secrets/vault.yaml

rm -rf $TEMP
rm $ROOTDIR/secrets/temp-vault.yaml
