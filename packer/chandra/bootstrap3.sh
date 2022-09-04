#!/usr/bin/env bash
set -xe

mkdir -p /new-var/lib/secrets
mv -vf /home/ubuntu/chandra.age /new-var/lib/secrets
chown -R root:root /new-var/lib/secrets
chmod 600 /new-var/lib/secrets/*.age

rm -rf /etc
