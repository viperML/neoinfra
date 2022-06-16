#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd $(dirname ${BASH_SOURCE[0]}); pwd)"

out_path=$(nix build $DIR#nixosConfigurations.lagos.config.system.build.googleComputeImage --print-out-paths --no-link)

image_path=
for path in "$out_path"/*.tar.gz; do
  image_path=$path
done

filename=$(basename $image_path)

cat <<JSON
{
  "out_path": "$out_path",
  "path": "$image_path",
  "filename": "$filename",
  "name": "${filename%.raw.tar.gz}"
}
JSON
