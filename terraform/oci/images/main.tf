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


data "oci_core_images" "kalypso" {
  compartment_id = var.compartment_id
  display_name   = "kalypso"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}

output "kalypso_id" {
  value = flatten([
    data.oci_core_images.kalypso.images[*].id,
    ["PLACEHOLDER_KALYPSO"]
  ])[0]
}

data "oci_core_images" "skadi" {
  compartment_id = var.compartment_id
  display_name   = "skadi"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}

output "skadi_id" {
  value = flatten([
    data.oci_core_images.skadi.images[*].id,
    ["PLACEHOLDER_SKADI"]
  ])[0]
}

data "oci_core_images" "chandra" {
  compartment_id = var.compartment_id
  display_name   = "chandra"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}

output "chandra_id" {
  value = flatten([
    data.oci_core_images.chandra.images[*].id,
    ["PLACEHOLDER_CHANDRA"]
  ])[0]
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
