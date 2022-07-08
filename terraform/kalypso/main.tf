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
  image_id = one(data.oci_core_images.kalypso.images).id
}





resource "oci_core_vcn" "terraform_vnc" {
  compartment_id = var.compartment_id
  display_name   = "terraform_vnc"
  cidr_blocks = [
    "10.0.0.0/16"
  ]
  # TODO need to setup DNS ?
}

resource "oci_core_subnet" "terraform_subnet" {
    cidr_block = "10.0.0.0/24"
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.terraform_vnc.id
    display_name = "terraform_subnet"
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
    assign_public_ip = "false"
    display_name = "kalypso_vnic"
    subnet_id = oci_core_subnet.terraform_subnet.id
  }
}
