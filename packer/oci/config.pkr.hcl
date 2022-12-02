# packer init ./config.pkr.hcl
# packer build -var "system=x86_64" ./config.pkr.hcl

packer {
  required_plugins {
    oracle-oci = {
      version = "~> 1.0"
      source = "github.com/hashicorp/oracle"
    }
  }
}

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

variable "system" {
  type = string
}

locals {
  shape_config = {
    "aarch64" = {
      shape         = "VM.Standard.A1.Flex"
      ocpus         = 2
      memory_in_gbs = 4
    }
    "x86_64" = {
      shape         = "VM.Standard.E4.Flex"
      ocpus         = 2
      memory_in_gbs = 4
    }
  }
}

source "oracle-oci" "main" {
  image_name          = "golden-oci-${var.system}"
  availability_domain = "vOMn:EU-MARSEILLE-1-AD-1"
  base_image_filter {
    operating_system = "Canonical Ubuntu"
  }
  compartment_ocid = var.oci_compartment_ocid
  shape            = local.shape_config[var.system]["shape"]
  shape_config {
    ocpus         = local.shape_config[var.system]["ocpus"]
    memory_in_gbs = local.shape_config[var.system]["memory_in_gbs"]
  }
  ssh_username = "ubuntu"
  subnet_ocid  = var.oci_subnet_ocid
}

build {
  sources = ["source.oracle-oci.main"]

  provisioner "file" {
    source      = "../../secrets/golden.age"
    destination = "/home/ubuntu/golden.age"
  }

  provisioner "shell" {
    script = "bootstrap1.sh"
  }

  provisioner "shell" {
    script          = "bootstrap2.sh"
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }} ${var.system}"
  }
}
