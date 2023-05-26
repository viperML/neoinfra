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


data "oci_core_images" "golden_aarch64" {
  compartment_id = var.compartment_id
  display_name   = "golden-oci-aarch64"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}

output "golden_aarch64_id" {
  value = flatten([
    data.oci_core_images.golden_aarch64.images[*].id,
    ["PLACEHOLDER_GOLDEN"]
  ])[0]
}

data "oci_core_images" "golden_x86_64" {
  compartment_id = var.compartment_id
  display_name   = "golden-oci-x86_64"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}

output "golden_x86_64_id" {
  value = flatten([
    data.oci_core_images.golden_x86_64.images[*].id,
    ["PLACEHOLDER_GOLDEN"]
  ])[0]
}

# data "oci_core_images" "base" {
#   compartment_id           = var.compartment_id
#   operating_system = "Canonical Ubuntu"
#   operating_system_version = "22.04"
# }

data "oci_core_images" "base" {
  compartment_id = var.compartment_id
  operating_system = "Oracle Linux"
  operating_system_version = "9"
}

output "base" {
  value = flatten([
    data.oci_core_images.base.images[*].id,
    ["FIXME"]
  ])[0]
}
