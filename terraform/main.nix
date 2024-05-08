{lib, ...}: let
  inherit (lib) tfRef;
in {
  imports = [
    ./variables.nix
    ./network.nix
    ./images.nix
  ];

  terraform = {
    required_providers = {
      oci = {
        source = "oracle/oci";
        version = "~> 5.17";
      };
      cloudflare = {
        source = "cloudflare/cloudflare";
        version = "~> 4.17";
      };
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
        # "create_vnic_details"
      ];
    };
    metadata = {
      user_data = tfRef "data.cloudinit_config.shiva.rendered";
    };
  };

  output."shiva_ip" = {
    value = tfRef "oci_core_instance.shiva.public_ip";
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

  resource."cloudflare_record"."record-infra" = {
    zone_id = tfRef "var.cloudflare_zone_id";
    name = "*.infra";
    type = "A";
    proxied = false;
    value = tfRef "oci_core_instance.shiva.public_ip";
  };

  resource."cloudflare_record"."record-matrix" = {
    zone_id = tfRef "var.cloudflare_zone_id";
    name = "matrix";
    type = "A";
    proxied = false;
    value = tfRef "oci_core_instance.shiva.public_ip";
  };

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

  # mail
  resource."cloudflare_record"."record-mail-a" = {
    zone_id = tfRef "var.cloudflare_zone_id";
    name = "mail";
    type = "A";
    proxied = false;
    value = tfRef "oci_core_instance.shiva.public_ip";
    ttl = 10800;
  };

  resource."cloudflare_record"."record-webmail-a" = {
    zone_id = tfRef "var.cloudflare_zone_id";
    name = "webmail";
    type = "A";
    proxied = false;
    value = tfRef "oci_core_instance.shiva.public_ip";
    # ttl     = 10800;
  };

  ## rdns managed by oracle

  resource."cloudflare_record"."record-mail-mx" = {
    zone_id = tfRef "var.cloudflare_zone_id";
    name = "@";
    type = "MX";
    value = "mail.ayats.org";
    priority = 10;
  };

  resource."cloudflare_record"."record-mail-spf" = {
    zone_id = lib.tfRef "var.cloudflare_zone_id";
    name = "@";
    type = "TXT";
    value = "v=spf1 a:mail.ayats.org -all";
    ttl = 10800;
  };

  resource."cloudflare_record"."record-mail-dkim" = {
    zone_id = tfRef "var.cloudflare_zone_id";
    name = "mail._domainkey";
    type = "TXT";
    value = "v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDF1CJldwrRKOLokhmDBgEuPtmo4G38D6DWVwFxarP7ethdcEQxQwty4nOFdwYxtjHcgeupJjv1/YT1oUVCWVHdy4tCUKCeVNb0FJt5cyLonma8jhv7PAMo+7hjQPqsZcteS6DXO3Dv+GhrOfIAHzT2e/gisvXq4a8LI+S7nGUcqQIDAQAB";
    ttl = 10800;
  };

  resource."cloudflare_record"."record-mail-dmarc" = {
    zone_id = tfRef "var.cloudflare_zone_id";
    name = "_dmarc";
    type = "TXT";
    value = "v=DMARC1; p=none";
    ttl = 10800;
  };

  resource."oci_dns_zone"."dns-zone" = {
    compartment_id = tfRef "var.compartment_id";
    name = "ayats.org";
    zone_type = "PRIMARY";
  };
}
