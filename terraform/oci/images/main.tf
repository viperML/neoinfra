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
  value = element(data.oci_core_images.kalypso.images, 1).id
}

data "oci_core_images" "skadi" {
  compartment_id = var.compartment_id
  display_name   = "skadi"
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"
}

output "skadi_id" {
  value = element(data.oci_core_images.kalypso.images, 1).id
}
