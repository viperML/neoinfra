terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

variable "compartment_id" {
  type        = string
  description = "OCI Compartment OCID"
}

resource "oci_core_vcn" "terraform_vcn" {
  compartment_id = var.compartment_id
  display_name   = "terraform0"
  cidr_blocks = [
    "10.0.0.0/16"
  ]
  dns_label = "terraform0"
}

resource "oci_core_internet_gateway" "terraform_vcn_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.terraform_vcn.id
  enabled        = true
  display_name   = "terraform gateway"
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

output "terraform_subnet" {
  value = oci_core_subnet.terraform_subnet
}
