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
	objects=($(gsutil ls "gs://$GCP_BUCKET"))
	# Run if object has "nixos-image" in the name
	for object in "${objects[@]}"; do
		if [[ $object =~ nixos-image ]]; then
			echo "Deleting $object"
			gsutil rm -r "$object"
		fi
	done

	images=($(gcloud compute images list --filter=name~nixos-image| grep -v NAME | cut -d' ' -f1))
	# Run if image has "nixos-image" in the name
	for image in "${images[@]}"; do
		if [[ $image =~ nixos-image ]]; then
			echo "Deleting $image"
			gcloud compute images delete "$image"
		fi
	done
fi

gsutil cp result/*.tar.gz "gs://$GCP_BUCKET/$img_name"

gcloud compute images create \
	"$img_id" \
	--source-uri "gs://${GCP_BUCKET}/$img_name" \
	--family=lagos
