#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)"

out_path=$(nix build $ROOT#nixosConfigurations.lagos.config.system.build.googleComputeImage --print-out-paths)

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
