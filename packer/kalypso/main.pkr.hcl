variable "oci-compartment-ocid" {
  type      = string
  default   = "${env("OCI_COMPARTMENT_OCID")}"
  sensitive = true
}

variable "oci-subnet-ocid" {
  type      = string
  default   = "${env("OCI_SUBNET_OCID")}"
  sensitive = true
}

source "oracle-oci" "kalypso" {
  availability_domain = "vOMn:EU-MARSEILLE-1-AD-1"
  base_image_filter {
    operating_system = "Canonical Ubuntu"
  }
  compartment_ocid = var.oci-compartment-ocid
  image_name       = "kalypso"
  shape            = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 2
    memory_in_gbs = 4
  }
  ssh_username = "ubuntu"
  subnet_ocid  = var.oci-subnet-ocid
}

build {
  sources = ["source.oracle-oci.kalypso"]

  provisioner "shell" {
    script = "bootstrap1.sh"
  }

  provisioner "shell" {
    script          = "bootstrap2.sh"
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
  }

  provisioner "file" {
    source      = "kalypso.age"
    destination = "/home/ubuntu/kalypso.age"
  }

  provisioner "shell" {
    script          = "bootstrap3.sh"
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
  }
}
