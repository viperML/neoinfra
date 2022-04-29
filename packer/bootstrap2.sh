#!/usr/bin/env bash
set -euxo pipefail

chown -R root:root /mnt/secrets
chmod 600 /mnt/secrets/*

umount /mnt/{var,nix,boot,secrets}
umount /mnt

zfs rollback -r tank/rootfs@empty
zpool export tank
