variable "hcloud-token" {
  type      = string
  default   = "${env("HCLOUD_TOKEN")}"
  sensitive = true
}

locals {
  arch-release = "${ legacy_isotime("2006-01") }-01"
  build-id = "${ uuidv4() }"
  build-labels  = {
    os-flavor              = "nixos"
    # "nixos/channel"        = "${ var.nix-channel }"
    # "nixos/nix.release"    = "${ var.nix-release }"
    "packer.io/build.id"   = "${ local.build-id }"
    "packer.io/build.time" = "{{ timestamp }}"
    "packer.io/version"    = "{{ packer_version }}"
  }
}

source "hcloud" "sumati" {
  server_type = "cx11"
  # ZFS
  image = "ubuntu-22.04"
  rescue      = "linux64"
  location    = "nbg1"
  snapshot_name = "nixos-{{ timestamp }}"
  snapshot_labels = local.build-labels
  ssh_username  = "root"
  token         = "${ var.hcloud-token }"
}

build {
  sources = ["source.hcloud.sumati"]

  provisioner "shell" {
    script = "packer/bootstrap.sh"
  }

  provisioner "file" {
    source = "secrets/sumati.age"
    destination = "/mnt/secrets/sumati.age"
  }

  post-processor "manifest" {
    custom_data = local.build-labels
  }
}
