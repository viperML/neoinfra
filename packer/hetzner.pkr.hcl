variable "hcloud-token" {
  type      = string
  default   = "${env("HCLOUD_TOKEN")}"
  sensitive = true
}

locals {
  build-id = "${uuidv4()}"
  build-labels = {
    os-flavor              = "nixos"
    "packer.io/build.id"   = "${local.build-id}"
    "packer.io/build.time" = "{{ timestamp }}"
    "packer.io/version"    = "{{ packer_version }}"
  }
}

source "hcloud" "sumati" {
  server_type     = "cx21"
  image           = "debian-11" # doesn't matter since we boot the rescue system
  rescue          = "linux64"
  location        = "nbg1"
  snapshot_name   = "nixos-{{ timestamp }}"
  snapshot_labels = local.build-labels
  ssh_username    = "root"
  token           = "${var.hcloud-token}"
}

build {
  sources = ["source.hcloud.sumati"]

  provisioner "shell" {
    script = "packer/bootstrap1.sh"
  }

  provisioner "file" {
    source      = "secrets/sumati.age"
    destination = "/mnt/secrets/sumati.age"
  }

  provisioner "shell" {
    script = "packer/bootstrap2.sh"
  }

  post-processor "manifest" {
    custom_data = local.build-labels
  }
}
