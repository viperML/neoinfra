#!/usr/bin/env bash
# https://github.com/NixOS/nixpkgs/blob/master/nixos/maintainers/scripts/gce/create-gce.sh
set -euxo pipefail
shopt -s nullglob

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

nix build $DIR#nixosConfigurations.lagos.config.system.build.googleComputeImage
img_path=$(echo result/*.tar.gz)
img_name=${IMAGE_NAME:-$(basename "$img_path")}
img_id=$(echo "$img_name" | sed 's|.raw.tar.gz$||;s|\.|-|g;s|_|-|g')

read -p "Cleanup old? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[nN]$ ]]; then
	tarballs=($(gsutil ls "gs://$GCP_BUCKET" | grep nixos-image))
	for x in "${tarballs[@]}"; do
		echo "Removing $x"
		gsutil rm -r "$x"
	done
	images=($(gcloud compute images list --filter="name~nixos-image"))
	for x in "${images[@]}"; do
		echo "Removing $x"
		gcloud compute images delete "$x"
	done
fi

gsutil cp result/*.tar.gz "gs://$GCP_BUCKET/$img_name"

gcloud compute images create \
	"$img_id" \
	--source-uri "gs://${GCP_BUCKET}/$img_name" \
	--family=lagos
