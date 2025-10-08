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
      aws = {
        source = "hashicorp/aws";
        version = "~> 6";
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
    api_token = tfRef "var.cloudflare_api_token";
  };

  provider."aws" = {
    region = "auto";
    skip_credentials_validation = true;
    skip_region_validation = true;
    skip_requesting_account_id = true;
  };

  provider."oci" = {
    auth = "SecurityToken";
    config_file_profile = "DEFAULT";
    region = "eu-marseille-1";
  };

  data."aws_s3_object"."shiva-key" = {
    bucket = "neoinfra";
    key = "shiva.age";
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

  output."shiva_ip" = {
    value = tfRef "oci_core_instance.shiva.public_ip";
  };

  output."shiva_ip6" = {
    value = tfRef "data.oci_core_vnic.shiva_vnic.ipv6addresses[0]";
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
          age_key = tfRef "jsonencode(data.aws_s3_object.shiva-key.body)";
        };
      };
    };
  };

  data."aws_s3_object"."ant1-key" = {
    bucket = "neoinfra";
    key = "ant1.age";
  };

  data."cloudinit_config"."ant1" = {
    gzip = false;
    base64_encode = true;
    part = {
      filename = "cloud-config.yaml";
      content_type = "text/cloud-config";
      content = lib.tf.template {
        source = ./cloud-config.yaml.tftpl;
        variables = {
          ssh_public_key = lib.fileContents ./id.pub;
          age_key = tfRef "jsonencode(data.aws_s3_object.ant1-key.body)";
        };
      };
    };
  };

  resource."oci_core_instance"."ant1" = {
    display_name = "terraform-ant1";
    availability_domain = "vOMn:EU-MARSEILLE-1-AD-1";
    compartment_id = tfRef "var.compartment_id";
    shape = "VM.Standard.E2.1.Micro";
    create_vnic_details = {
      assign_public_ip = true;
      assign_ipv6ip = true; # maybe need to provide ipv6SubnetCidr
      subnet_id = tfRef "resource.oci_core_subnet.terraform_subnet.id";
      assign_private_dns_record = false;
    };
    source_details = {
      source_type = "image";
      source_id = tfRef "data.oci_core_images.always-free.images[0].id";
      boot_volume_size_in_gbs = 50;
    };
    lifecycle = {
      ignore_changes = [
        "source_details"
        "metadata"
        "create_vnic_details"
      ];
    };
    metadata = {
      user_data = tfRef "data.cloudinit_config.ant1.rendered";
    };
  };

  data."oci_core_vnic_attachments"."ant1_vnic_attachment" = {
    compartment_id = tfRef "var.compartment_id";
    instance_id = tfRef "resource.oci_core_instance.ant1.id";
  };

  data."oci_core_vnic"."ant1_vnic" = {
    vnic_id = tfRef "data.oci_core_vnic_attachments.ant1_vnic_attachment.vnic_attachments[0].vnic_id";
  };

  output."ant1_ip" = {
    value = tfRef "oci_core_instance.ant1.public_ip";
  };

  output."ant1_ip6" = {
    value = tfRef "data.oci_core_vnic.ant1_vnic.ipv6addresses[0]";
  };

  data."aws_s3_object"."ant2-key" = {
    bucket = "neoinfra";
    key = "ant2.age";
  };

  data."cloudinit_config"."ant2" = {
    gzip = false;
    base64_encode = true;
    part = {
      filename = "cloud-config.yaml";
      content_type = "text/cloud-config";
      content = lib.tf.template {
        source = ./cloud-config.yaml.tftpl;
        variables = {
          ssh_public_key = lib.fileContents ./id.pub;
          age_key = tfRef "jsonencode(data.aws_s3_object.ant2-key.body)";
        };
      };
    };
  };

  resource."oci_core_instance"."ant2" = {
    display_name = "terraform-ant2";
    availability_domain = "vOMn:EU-MARSEILLE-1-AD-1";
    compartment_id = tfRef "var.compartment_id";
    shape = "VM.Standard.E2.1.Micro";
    create_vnic_details = {
      assign_public_ip = true;
      assign_ipv6ip = true; # maybe need to provide ipv6SubnetCidr
      subnet_id = tfRef "resource.oci_core_subnet.terraform_subnet.id";
      assign_private_dns_record = false;
    };
    source_details = {
      source_type = "image";
      source_id = tfRef "data.oci_core_images.always-free.images[0].id";
      boot_volume_size_in_gbs = 50;
    };
    lifecycle = {
      ignore_changes = [
        "source_details"
        "metadata"
        "create_vnic_details"
      ];
    };
    metadata = {
      user_data = tfRef "data.cloudinit_config.ant2.rendered";
    };
  };

  data."oci_core_vnic_attachments"."ant2_vnic_attachment" = {
    compartment_id = tfRef "var.compartment_id";
    instance_id = tfRef "resource.oci_core_instance.ant2.id";
  };

  data."oci_core_vnic"."ant2_vnic" = {
    vnic_id = tfRef "data.oci_core_vnic_attachments.ant2_vnic_attachment.vnic_attachments[0].vnic_id";
  };

  output."ant2_ip" = {
    value = tfRef "oci_core_instance.ant2.public_ip";
  };

  output."ant2_ip6" = {
    value = tfRef "data.oci_core_vnic.ant2_vnic.ipv6addresses[0]";
  };
}
