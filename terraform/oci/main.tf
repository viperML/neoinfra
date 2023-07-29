terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 4.76"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket                      = "viperml-neoinfra"
    key                         = "oci.tfstate"
    region                      = "pl-waw"
    endpoint                    = "https://s3.pl-waw.scw.cloud"
    skip_credentials_validation = true
    skip_region_validation      = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "oci" {
  auth                = "SecurityToken"
  config_file_profile = "DEFAULT"
  region              = "eu-marseille-1"
}


module "network" {
  source         = "./network"
  compartment_id = var.compartment_id
}

module "images" {
  source         = "./images"
  compartment_id = var.compartment_id
}


variable "deploy" {
  type        = bool
  default     = false
  description = "Use big RAM size for deployment"
}

data "local_file" "ssh_public_key" {
  filename = "id.pub"
}

#    ▄▄▄▄▄    ▄  █ ▄█     ▄   ██
#   █     ▀▄ █   █ ██      █  █ █
# ▄  ▀▀▀▀▄   ██▀▀█ ██ █     █ █▄▄█
#  ▀▄▄▄▄▀    █   █ ▐█  █    █ █  █
#               █   ▐   █  █     █
#              ▀         █▐     █
#                        ▐     ▀

data "local_file" "shiva_age" {
  filename = "../../secrets/shiva.age"
}

data "cloudinit_config" "shiva" {
  gzip          = false
  base64_encode = true
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = templatefile("cloud-config.yaml.tftpl", {
      ssh_public_key = jsonencode(data.local_file.ssh_public_key.content)
      age_key        = jsonencode(data.local_file.shiva_age.content)
    })
  }
}

resource "oci_core_instance" "shiva" {
  display_name        = "terraform-shiva"
  availability_domain = "vOMn:EU-MARSEILLE-1-AD-1"
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 24
    ocpus         = 4
  }
  create_vnic_details {
    assign_public_ip          = true
    subnet_id                 = module.network.terraform_subnet.id
    assign_private_dns_record = false
  }
  source_details {
    source_type             = "image"
    source_id               = module.images.base-aarch64
    boot_volume_size_in_gbs = 130
  }
  lifecycle {
    ignore_changes = [
      source_details,
      metadata
    ]
  }
  metadata = {
    user_data = data.cloudinit_config.shiva.rendered
  }
}


# module "aarch64-kexec-installer-noninteractive" {
#   source = "github.com/numtide/nixos-anywhere//terraform/nix-build"
#   attribute = ".#packages.aarch64-linux.kexec-installer-noninteractive"
# }

# module "shiva_deploy" {
#   source = "github.com/numtide/nixos-anywhere//terraform/all-in-one"
#   nixos_system_attr = ".#nixosConfigurations.aarch64-linux-oci-installer.config.system.build.toplevel"
#   nixos_partitioner_attr = ".#nixosConfigurations.aarch64-linux-oci-installer.config.system.build.diskoNoDeps"
#   kexec_tarball_url = "${module.aarch64-kexec-installer-noninteractive.result.out}/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz"
#   target_host = oci_core_instance.shiva.public_ip
#   install_user = "root"
#   instance_id = oci_core_instance.shiva.id
# }

output "shiva_ip" {
  value = oci_core_instance.shiva.public_ip
}

resource "oci_identity_dynamic_group" "vault_dynamic_group" {
  compartment_id = var.compartment_id
  name           = "TerraformVault"
  description    = "Group holding instances that should access Vault"
  matching_rule  = "instance.id = '${oci_core_instance.shiva.id}'"
}

resource "oci_identity_policy" "vault_policy" {
  compartment_id = var.compartment_id
  description    = "Policies to access Vault"
  name           = "TerraformVault"
  statements = [
    # ocikms
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to use keys in compartment id ${var.compartment_id} where target.key.id = '${var.oci_key_id}'",
    # object storage
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to {AUTHENTICATION_INSPECT} in tenancy",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to {GROUP_MEMBERSHIP_INSPECT} in tenancy",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to manage buckets in compartment id ${var.compartment_id}",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to manage objects in compartment id ${var.compartment_id}",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to use secrets in compartment id ${var.compartment_id}"
  ]
}

resource "cloudflare_record" "record-infra" {
  zone_id = var.cloudflare_zone_id
  name    = "*.infra"
  type    = "A"
  proxied = false
  value   = oci_core_instance.shiva.public_ip
}

resource "cloudflare_record" "record-obsidian" {
  zone_id = var.cloudflare_zone_id
  name    = "obsidian"
  type    = "A"
  proxied = false
  value   = oci_core_instance.shiva.public_ip
}