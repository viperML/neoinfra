#!/usr/bin/env bash
# https://github.com/NixOS/nixpkgs/blob/master/nixos/maintainers/scripts/gce/create-gce.sh
set -euxo pipefail
shopt -s nullglob

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

nix build $DIR#nixosConfigurations.lagos.config.system.build.googleComputeImage
img_path=$(echo result/*.tar.gz)
img_name=${IMAGE_NAME:-$(basename "$img_path")}
img_id=$(echo "$img_name" | sed 's|.raw.tar.gz$||;s|\.|-|g;s|_|-|g')

gsutil ls "gs://$GCP_BUCKET"
# Ask for confirmation or exit
read -p "Continue? [y/N] " -n 1 -r
echo # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	exit 0
fi

gsutil cp result/*.tar.gz "gs://$GCP_BUCKET/$img_name"

gcloud compute images create \
	"$img_id" \
	--source-uri "gs://${GCP_BUCKET}/$img_name" \
	--family=lagos
