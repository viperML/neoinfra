{ lib, ... }:
let
  inherit (lib) tfRef;
in
{
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
        version = "~> 7.18";
      };
      cloudflare = {
        source = "cloudflare/cloudflare";
        version = "~> 5.9";
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
}
