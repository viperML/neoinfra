terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.76.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket                      = "viper-tfstate"
    key                         = "kalypso.tfstate"
    region                      = "fr-par"
    endpoint                    = "https://s3.fr-par.scw.cloud"
    skip_credentials_validation = true
    skip_region_validation      = true
  }
}

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}


module "network" {
  source         = "./network"
  compartment_id = var.compartment_id
}

module "images" {
  source         = "./images"
  compartment_id = var.compartment_id
}


###
# kalyspo
###

resource "oci_core_instance" "kalypso" {
  availability_domain = "vOMn:EU-MARSEILLE-1-AD-1"
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }
  display_name = "terraform-kalypso"
  source_details {
    source_type = "image"
    source_id   = module.images.kalypso_id
  }
  create_vnic_details {
    assign_public_ip          = true
    display_name              = "kalypso_vnic"
    subnet_id                 = module.network.terraform_subnet.id
    assign_private_dns_record = false
  }
  lifecycle {
    ignore_changes = [
      source_details
    ]
  }
}

resource "oci_identity_policy" "vault_policy" {
  compartment_id = var.compartment_id
  description    = "Policies for kalypso to access Vault"
  name           = "TerraformVault"
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to {AUTHENTICATION_INSPECT} in tenancy",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to {GROUP_MEMBERSHIP_INSPECT} in tenancy",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to use keys in compartment id ${var.compartment_id} where target.key.id = '${var.oci_key_id}'",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to manage buckets in compartment id ${var.compartment_id}",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to manage objects in compartment id ${var.compartment_id}",
    "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to use secrets in compartment id ${var.compartment_id}"
  ]
}

resource "oci_identity_dynamic_group" "vault_dynamic_group" {
  compartment_id = var.compartment_id
  name           = "TerraformVault"
  description    = "Group holding instances that should access Vault"
  matching_rule  = "instance.id = '${oci_core_instance.kalypso.id}'"
}


###
# skadi
###

resource "oci_core_instance" "skadi" {
  availability_domain = "vOMn:EU-MARSEILLE-1-AD-1"
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }
  display_name = "terraform-skadi"
  source_details {
    source_type = "image"
    source_id   = module.images.skadi_id
  }
  create_vnic_details {
    assign_public_ip          = true
    display_name              = "skadi_vnic"
    subnet_id                 = module.network.terraform_subnet.id
    assign_private_dns_record = false
  }
  lifecycle {
    ignore_changes = [
      source_details
    ]
  }
}

resource "cloudflare_record" "record" {
  zone_id = var.cloudflare_zone_id
  name    = "ca"
  type    = "A"
  proxied = false
  value   = oci_core_instance.skadi.public_ip
}


###
# chandra
###

resource "oci_core_instance" "chandra" {
  availability_domain = "vOMn:EU-MARSEILLE-1-AD-1"
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 2
    ocpus         = 1
  }
  display_name = "terraform-chandra"
  source_details {
    source_type = "image"
    source_id   = module.images.golden_aarch64_id
  }
  create_vnic_details {
    assign_public_ip          = true
    display_name              = "chandra_vnic"
    subnet_id                 = module.network.terraform_subnet.id
    assign_private_dns_record = false
  }
  lifecycle {
    ignore_changes = [
      source_details
    ]
  }
}

// resource "cloudflare_record" "chandra_a" {
//   zone_id = var.cloudflare_zone_id
//   name    = "minecraft"
//   type    = "A"
//   proxied = false
//   value   = oci_core_instance.chandra.public_ip
// }
