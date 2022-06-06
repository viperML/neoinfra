variable "gcp_project" {
  type        = string
  description = "The ID of the project in which the resource belongs."
}

provider "google" {
  project = var.gcp_project
  region  = "us-east1"
  zone    = "us-east1-b"
}

data "external" "image" {
  program = ["bin/terraform-lagos.sh"]
}

locals {
  image_path     = data.external.image.result.path
  image_filename = data.external.image.result.filename
  image_out_path = data.external.image.result.out_path
  image_out_hash = element(split("-", basename(local.image_out_path)), 0)
  image_name = "x${substr(local.image_out_hash, 0, 12)}-${replace(
    replace(
      basename(local.image_path),
      "/\\.raw\\.tar\\.gz|nixos-image-/",
      "",
    ),
    "/[._]+/",
    "-",
  )}"
  gcp_bucket  = "lagos-bucket-1"
  gcp_project = "lagos-project"
}

resource "google_storage_bucket_object" "lagos_image" {
  bucket       = local.gcp_bucket
  name         = local.image_filename
  source       = local.image_path
  content_type = "application/tar+gzip"
}


resource "google_compute_image" "lagos" {
  name        = local.image_name
  family      = "lagos"
  description = "NixOS image for lagos"

  raw_disk {
    source = "https://${local.gcp_bucket}.storage.googleapis.com/${google_storage_bucket_object.lagos_image.name}"
  }
}

resource "google_compute_instance" "lagos" {
  name         = "instance"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = google_compute_image.lagos.name
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}

output "image_id" {
  value = google_compute_image.lagos.id
}
