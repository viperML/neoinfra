#!/usr/bin/env bash
set -euxo pipefail

chown -R root:root /mnt/var/lib/secrets
chmod 600 /mnt/var/lib/secrets/sumati.age

umount /mnt/var/lib/secrets
umount /mnt/{var,nix,boot}
umount /mnt

zfs rollback -r tank/rootfs@empty
zpool export tank
