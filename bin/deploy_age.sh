#!/usr/bin/env bash
set -eux

ROOT="$(cd "$(dirname "${BASH_SOURCE[@]}")" || exit; cd ..; pwd)"

NEW_HOSTNAME="$1"
OLD_HOSTNAME="${2:-golden}"

run_ssh() {
    ssh admin@"$OLD_HOSTNAME" "$@"
}

pprint() {
    echo "$@"
}

ssh-add "$ROOT/modules/golden/id_golden"

set +e
run_ssh "test -f /var/lib/secrets/.age"
exit_code="$?"
set -e

if [[ $exit_code == "1" ]]; then
    pprint "Key doesn't exist"
else
    pprint "Key exists"
fi

XDG_RUNTIME_DIR="$(run_ssh "printenv XDG_RUNTIME_DIR")"

LOCATION_TEMP="$XDG_RUNTIME_DIR/$NEW_HOSTNAME.age"
LOCATION="/var/lib/secrets/$NEW_HOSTNAME.age"

scp "$ROOT/secrets/$NEW_HOSTNAME.age" "admin@$OLD_HOSTNAME:$LOCATION_TEMP"

run_ssh "sudo mv $LOCATION_TEMP $LOCATION"
run_ssh "sudo chown root:root $LOCATION"
run_ssh "sudo chmod 0400 $LOCATION"

run_ssh "ls -la /var/lib/secrets"
