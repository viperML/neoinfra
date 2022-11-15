#!/bin/sh

if [ -n "$HOME" ] && [ -n "$USER" ]; then
    file="/nix/var/nix/profiles/per-user/$USER/profile/etc/profile.d/hm-session-vars.sh"
    if [ -f "$file" ]; then
        # shellcheck source=/dev/null
        . "$file"
    fi
fi
