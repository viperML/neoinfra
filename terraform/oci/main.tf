terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.76.0"
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


module "network" {
  source         = "./network"
  compartment_id = var.compartment_id
}

module "images" {
  source         = "./images"
  compartment_id = var.compartment_id
}

# FIXME
moved {
  from = oci_core_subnet.terraform_subnet
  to   = module.network.oci_core_subnet.terraform_subnet
}
moved {
  from = oci_core_security_list.terraform_subnet_security_list
  to = module.network.oci_core_security_list.terraform_subnet_security_list
}
moved {
  from = oci_core_route_table.terraform_vcn_route0
  to = module.network.oci_core_route_table.terraform_vcn_route0
}
moved {
  from = oci_core_internet_gateway.terraform_vcn_gateway
  to = module.network.oci_core_internet_gateway.terraform_vcn_gateway
}
moved {
  from = oci_core_vcn.terraform_vcn
  to = module.network.oci_core_vcn.terraform_vcn
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

