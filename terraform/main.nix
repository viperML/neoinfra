{lib, ...}: let
  inherit (lib) tfRef;
in {
  imports = [
    ./variables.nix
    ./network.nix
    ./images.nix
    ./dns.nix
  ];

  terraform = {
    required_providers = {
      oci = {
        source = "oracle/oci";
        version = "~> 6.35";
      };
      cloudflare = {
        source = "cloudflare/cloudflare";
        version = "~> 5.3";
      };
    };

    # https://github.com/hashicorp/terraform/issues/33847#issuecomment-1974231305
    backend.s3 = {
      bucket = "neoinfra";
      key = "terraform.tfstate";
      region = "auto";
      skip_credentials_validation = true;
      skip_metadata_api_check = true;
      skip_region_validation = true;
      skip_requesting_account_id = true;
      skip_s3_checksum = true;
      use_path_style = true;
    };
  };

  provider."cloudflare" = {
    api_token = lib.tfRef "var.cloudflare_api_token";
  };

  provider."oci" = {
    auth = "SecurityToken";
    config_file_profile = "DEFAULT";
    region = "eu-marseille-1";
  };

  # module."network" = {
  #   source         = "./network"
  #   compartment_id = var.compartment_id
  # }

  # module "images" {
  #   source         = "./images"
  #   compartment_id = var.compartment_id
  # }

  variable."deploy" = {
    type = "bool";
    default = false;
    description = "Use big RAM size for deployment";
  };

  # data."local_file"."ssh_public_key" = {
  #   filename = "id.pub";
  # };

  # shiva

  resource."oci_core_instance"."shiva" = {
    display_name = "terraform-shiva";
    availability_domain = "vOMn:EU-MARSEILLE-1-AD-1";
    compartment_id = tfRef "var.compartment_id";
    shape = "VM.Standard.A1.Flex";
    shape_config = {
      memory_in_gbs = 24;
      ocpus = 4;
    };
    create_vnic_details = {
      assign_public_ip = true;
      assign_ipv6ip = true; # maybe need to provide ipv6SubnetCidr
      subnet_id = tfRef "resource.oci_core_subnet.terraform_subnet.id";
      assign_private_dns_record = false;
    };
    source_details = {
      source_type = "image";
      source_id = tfRef "data.oci_core_images.always-free.images[0].id";
      boot_volume_size_in_gbs = 140;
    };
    lifecycle = {
      ignore_changes = [
        "source_details"
        "metadata"
        "create_vnic_details"
      ];
    };
    metadata = {
      user_data = tfRef "data.cloudinit_config.shiva.rendered";
    };
  };

  data."oci_core_vnic_attachments"."shiva_vnic_attachment" = {
    compartment_id = tfRef "var.compartment_id";
    instance_id = tfRef "resource.oci_core_instance.shiva.id";
  };

  data."oci_core_vnic"."shiva_vnic" = {
    vnic_id = tfRef "data.oci_core_vnic_attachments.shiva_vnic_attachment.vnic_attachments[0].vnic_id";
  };

  # output."shiva_vnic" = {
  #   value = tfRef "data.oci_core_vnic_attachments.shiva_vnic_attachment.vnic_attachments[0]";
  # };

  output."shiva_ip" = {
    value = tfRef "oci_core_instance.shiva.public_ip";
  };

  output."shiva_ip6" = {
    value = tfRef "data.oci_core_vnic.shiva_vnic.ipv6addresses[0]";
  };

  data."local_file"."shiva_age" = {
    filename = "../secrets/shiva.age";
  };

  data."cloudinit_config"."shiva" = {
    gzip = false;
    base64_encode = true;
    part = {
      filename = "cloud-config.yaml";
      content_type = "text/cloud-config";
      content = lib.tf.template {
        source = ./cloud-config.yaml.tftpl;
        variables = {
          ssh_public_key = lib.fileContents ./id.pub;
          age_key = tfRef "jsonencode(data.local_file.shiva_age.content)";
        };
      };
      # content = FIXME;
      # content = templatefile("cloud-config.yaml.tftpl", {
      #   ssh_public_key = jsonencode(data.local_file.ssh_public_key.content)
      #   age_key        = jsonencode(data.local_file.shiva_age.content)
      # })
    };
  };

  # output."cloudinit_config_shiva_raw" = {
  #   value = FIXME;
  #   # value = templatefile("cloud-config.yaml.tftpl", {
  #   #   ssh_public_key = jsonencode(data.local_file.ssh_public_key.content)
  #   #   age_key        = jsonencode(data.local_file.shiva_age.content)
  #   # })
  #   sensitive = true;
  # };

  # module "aarch64-kexec-installer-noninteractive" {
  #   source = "github.com/numtide/nixos-anywhere//terraform/nix-build"
  #   attribute = ".#packages.aarch64-linux.kexec-installer-noninteractive"
  # }

  # module "shiva_deploy" {
  #   source = "github.com/numtide/nixos-anywhere//terraform/all-in-one"
  #   nixos_system_attr = ".#nixosConfigurations.aarch64-linux-oci-installer.config.system.build.toplevel"
  #   nixos_partitioner_attr = ".#nixosConfigurations.aarch64-linux-oci-installer.config.system.build.diskoNoDeps"
  #   kexec_tarball_url = "${module.aarch64-kexec-installer-noninteractive.result.out}/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz"
  #   target_host = oci_core_instance.shiva.public_ip
  #   install_user = "root"
  #   instance_id = oci_core_instance.shiva.id
  # }

  # vishnu

  /*
  resource "oci_core_instance" "vishnu" {
    display_name        = "terraform-visnhu"
    availability_domain = "vOMn:EU-MARSEILLE-1-AD-1"
    compartment_id      = var.compartment_id
    shape               = "VM.Standard.E2.1.Micro"
    create_vnic_details {
      assign_public_ip          = true
      subnet_id                 = module.network.terraform_subnet.id
      assign_private_dns_record = false
    }
    source_details {
      source_type = "image"
      source_id   = module.images.always-free
    }
    lifecycle {
      ignore_changes = [
        source_details,
        metadata
      ]
    }
    metadata = {
      user_data = data.cloudinit_config.visnhu.rendered
    }
  }

  output "vishnu_ip" {
    value = oci_core_instance.vishnu.public_ip
  }

  data "local_file" "vishnu_age" {
    filename = "../secrets/vishnu.age"
  }

  data "cloudinit_config" "visnhu" {
    gzip          = false
    base64_encode = true
    part {
      filename     = "cloud-config.yaml"
      content_type = "text/cloud-config"
      content = templatefile("cloud-config.yaml.tftpl", {
        ssh_public_key = jsonencode(data.local_file.ssh_public_key.content)
        age_key        = jsonencode(data.local_file.vishnu_age.content)
      })
    }
  }
  */

  # resource "oci_identity_dynamic_group" "vault_dynamic_group" {
  #   compartment_id = var.compartment_id
  #   name           = "TerraformVaultGroup"
  #   description    = "Group holding instances that should access Vault"
  #   matching_rule  = "instance.id = '${oci_core_instance.vishnu.id}'"
  # }

  # resource "oci_identity_policy" "vault_policy" {
  #   compartment_id = var.compartment_id
  #   description    = "Policies to access Vault"
  #   name           = "TerraformVaultPolicy"
  #   statements = [
  #     # ocikms
  #     "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to use keys in compartment id ${var.compartment_id} where target.key.id = '${var.oci_key_id}'",
  #     # object storage
  #     "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to {AUTHENTICATION_INSPECT} in tenancy",
  #     "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to {GROUP_MEMBERSHIP_INSPECT} in tenancy",
  #     "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to manage buckets in compartment id ${var.compartment_id}",
  #     "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to manage objects in compartment id ${var.compartment_id}",
  #     "allow dynamic-group ${oci_identity_dynamic_group.vault_dynamic_group.name} to use secrets in compartment id ${var.compartment_id}"
  #   ]
  # }
}
