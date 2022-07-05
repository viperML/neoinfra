#!/usr/bin/env bash
set -xe

chown -R root:root /new-var/lib/secrets
chmod 600 /new-var/lib/secrets/*.age

rm -rf /etc
