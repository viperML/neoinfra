variable "hcloud-token" {
  type      = string
  default   = "${env("HCLOUD_TOKEN")}"
  sensitive = true
}

variable "name" {
  type = string
}

locals {
  build-id = "${uuidv4()}"
  build-labels = {
    "name" = var.name
    "packer.io/build.time" = "{{ timestamp }}"
  }
}

source "hcloud" "sumati" {
  server_type     = "cx21"
  image           = "debian-11" # doesn't matter since we boot the rescue system
  rescue          = "linux64"
  location        = "nbg1"
  snapshot_name   = "${var.name}"
  snapshot_labels = local.build-labels
  ssh_username    = "root"
  token           = "${var.hcloud-token}"
}

build {
  sources = ["source.hcloud.sumati"]

  provisioner "shell" {
    script = "bootstrap1.sh"
  }

  provisioner "file" {
    source      = "sumati.age"
    destination = "/mnt/var/lib/secrets/sumati.age"
  }

  provisioner "shell" {
    script = "bootstrap2.sh"
  }

  post-processor "manifest" {
    custom_data = local.build-labels
  }
}
