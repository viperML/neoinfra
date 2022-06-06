terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

variable "gcp_project" {
  type        = string
  description = "The ID of the project in which the resource belongs."
}

variable "cloudflare_email" {
  type        = string
  description = "Email of the Cloudflare account"
}

variable "cloudflare_api_token" {
  type        = string
  description = "API Key for Cloudflare DNS"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Zone ID for Cloudflare"
}

provider "google" {
  project = var.gcp_project
  region  = "us-east1"
  zone    = "us-east1-b"
}

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}

data "external" "image" {
  program = ["./build.sh"]
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
      network_tier = "STANDARD"
    }
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}

locals {
  ip = "${google_compute_instance.lagos.network_interface.0.access_config.0.nat_ip}"
}

resource "cloudflare_record" "record" {
  zone_id = var.cloudflare_zone_id
  name    = "ca"
  type    = "A"
  proxied = false
  value   = local.ip
}

output "image_id" {
  value = google_compute_image.lagos.id
}

output "ip" {
  value = local.ip
}
