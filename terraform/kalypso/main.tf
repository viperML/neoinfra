terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.76.0"
    }
  }
}

variable "compartment_id" {
  type        = string
  description = "OCI Compartment OCID"
}

# Get the image built with Packer
data "oci_core_images" "kalypso" {
  compartment_id = var.compartment_id
  display_name   = "kalypso"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}
data "oci_core_image" "kalypso" {
  image_id = element(data.oci_core_images.kalypso.images, 1).id
}


resource "oci_core_vcn" "terraform_vcn" {
  compartment_id = var.compartment_id
  display_name   = "terraform0"
  cidr_blocks = [
    "10.0.0.0/16"
  ]
  dns_label = "terraform0"
}

resource "oci_core_route_table" "terraform_vcn_route0" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.terraform_vcn.id
  display_name   = "Internet Gateway"
  route_rules {
    network_entity_id = oci_core_internet_gateway.terraform_vcn_gateway.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_internet_gateway" "terraform_vcn_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.terraform_vcn.id
  enabled        = true
  display_name   = "terraform gateway"
}

resource "oci_core_security_list" "terraform_subnet_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.terraform_vcn.id
  display_name   = "Terraform Security Lists"
  ingress_security_rules {
    protocol  = "all"
    source    = "0.0.0.0/0"
    stateless = true
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "terraform_subnet" {
  cidr_block     = "10.0.0.0/24"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.terraform_vcn.id
  display_name   = "terraform_subnet"
  security_list_ids = [
    oci_core_security_list.terraform_subnet_security_list.id
  ]
  route_table_id = oci_core_route_table.terraform_vcn_route0.id
}


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
    source_id   = data.oci_core_image.kalypso.image_id
  }
  create_vnic_details {
    assign_public_ip          = true
    display_name              = "kalypso_vnic"
    subnet_id                 = oci_core_subnet.terraform_subnet.id
    assign_private_dns_record = false
  }
}

variable "oci_key_id" {
  type        = string
  description = "Vault Key OCID"
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
    name = "TerraformVault"
    description = "Group holding instances that should access Vault"
    matching_rule = "instance.id = '${oci_core_instance.kalypso.id}'"
}
