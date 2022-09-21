variable "oci_compartment_ocid" {
  type      = string
  default   = "${env("OCI_COMPARTMENT_OCID")}"
  sensitive = true
}

variable "oci_subnet_ocid" {
  type      = string
  default   = "${env("OCI_SUBNET_OCID")}"
  sensitive = true
}

# TODO implement x86_64
variable "system" {
  type = string
}

source "oracle-oci" "main" {
  image_name          = "golden-oci-${var.system}"
  availability_domain = "vOMn:EU-MARSEILLE-1-AD-1"
  base_image_filter {
    operating_system = "Canonical Ubuntu"
  }
  compartment_ocid = var.oci_compartment_ocid
  shape            = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 2
    memory_in_gbs = 4
  }
  ssh_username = "ubuntu"
  subnet_ocid  = var.oci_subnet_ocid
}

build {
  sources = ["source.oracle-oci.main"]

  provisioner "shell" {
    script = "bootstrap1.sh"
  }

  provisioner "shell" {
    script          = "bootstrap2.sh"
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }} ${var.system}"
  }
}
