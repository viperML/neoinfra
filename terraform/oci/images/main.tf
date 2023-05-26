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

data "oci_core_images" "base-aarch64" {
  compartment_id = var.compartment_id
  operating_system = "Oracle Linux"
  operating_system_version = "9"
  shape = "VM.Standard.A1.Flex"
}

output "base-aarch64" {
  value = data.oci_core_images.base-aarch64.images[0].id
}


data "oci_core_images" "base-x86_64" {
  compartment_id = var.compartment_id
  operating_system = "Oracle Linux"
  operating_system_version = "9"
  shape = "VM.Standard.E4.Flex"
}

output "base-x86_64" {
  value = data.oci_core_images.base-x86_64.images[0].id
}

