terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
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

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}

provider "hcloud" {
  token = var.HCLOUD_TOKEN
}

variable "HCLOUD_TOKEN" {
  type        = string
  description = "Hetzner Cloud admin secret"
}

locals {
  cloudflare_ipv4 = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
  ]
  cloudflare_ipv6 = [
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32",
  ]
}

data "external" "snapshot" {
  program = ["./getname.sh"]
}

data "hcloud_image" "sumati-image" {
  with_selector = "name=${data.external.snapshot.result.name}"
}

resource "hcloud_firewall" "cloudflare" {
  name = "terraform-cloudflare"
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = local.cloudflare_ipv4
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = local.cloudflare_ipv4
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = local.cloudflare_ipv6
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = local.cloudflare_ipv6
  }
}

resource "hcloud_server" "sumati" {
  name        = "sumati"
  image       = data.hcloud_image.sumati-image.id
  server_type = "cx21"
  location    = "nbg1"
  firewall_ids = [hcloud_firewall.cloudflare.id]
}

resource "cloudflare_record" "wildcard-ayats-org-ipv4" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  type    = "A"
  proxied = true
  value   = hcloud_server.sumati.ipv4_address
}

resource "cloudflare_record" "ayats-org-ipv4" {
  zone_id = var.cloudflare_zone_id
  name    = "ayats.org"
  type    = "A"
  proxied = true
  value   = hcloud_server.sumati.ipv4_address
}

resource "cloudflare_record" "wildcard-ayats-org-ipv6" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  type    = "AAAA"
  proxied = true
  value   = hcloud_server.sumati.ipv6_address
}

resource "cloudflare_record" "ayats-org-ipv6" {
  zone_id = var.cloudflare_zone_id
  name    = "ayats.org"
  type    = "AAAA"
  proxied = true
  value   = hcloud_server.sumati.ipv6_address
}
