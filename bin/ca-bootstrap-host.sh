#!/usr/bin/env bash
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

set -euxo pipefail

: $CA_FINGERPRINT

export STORAGE_ROOT=/var/lib/secrets
export STORAGE_INST=$STORAGE_ROOT/certs-$(date +"%Y-%m-%d")
export STEPPATH=$STORAGE_INST/step
rm -rf $STORAGE_INST
mkdir -p $STORAGE_INST


step ca bootstrap \
    --ca-url https://ca.ayats.org \
    --fingerprint $CA_FINGERPRINT \
    --force


step ssh certificate \
    --host \
    --insecure \
    --no-password \
    $(hostname) $STORAGE_INST/ssh_host_ecdsa_key


step ssh config \
    --force \
    --roots > $STORAGE_INST/ssh_user_key.pub

mkdir -p $STORAGE_INST/principals
tee $STORAGE_INST/principals/ayats <<EOF
ayats
EOF


ln -sfTs $STORAGE_INST $STORAGE_ROOT/certs
systemctl restart sshd.service
