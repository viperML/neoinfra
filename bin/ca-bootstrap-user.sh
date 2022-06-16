#!/usr/bin/env bash
set -euxo pipefail

: $CA_FINGERPRINT

step ca bootstrap \
    --ca-url https://ca.ayats.org \
    --fingerprint $CA_FINGERPRINT \
    --force

step ssh login $USER

step ssh config --set User=ayats --force

