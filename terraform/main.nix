{ lib, ... }:
let
  inherit (lib) tfRef;

  mkOCI = name: override: {
    resource."oci_core_instance".${name} = lib.mkMerge [
      {
        display_name = "terraform-${name}";
        availability_domain = "vOMn:EU-MARSEILLE-1-AD-1";
        compartment_id = tfRef "var.compartment_id";
        create_vnic_details = {
          assign_public_ip = true;
          assign_ipv6ip = true; # maybe need to provide ipv6SubnetCidr
          subnet_id = tfRef "resource.oci_core_subnet.terraform_subnet.id";
          assign_private_dns_record = false;
        };

        lifecycle = {
          ignore_changes = [
            "source_details"
            "metadata"
            "create_vnic_details"
          ];
        };
        metadata = {
          ssh_authorized_keys = lib.fileContents ./id.pub;
        };
      }
      override
    ];

    data."oci_core_vnic_attachments"."${name}_vnic_attachment" = {
      compartment_id = tfRef "var.compartment_id";
      instance_id = tfRef "resource.oci_core_instance.${name}.id";
    };

    data."oci_core_vnic"."${name}_vnic" = {
      vnic_id = tfRef "data.oci_core_vnic_attachments.${name}_vnic_attachment.vnic_attachments[0].vnic_id";
    };

    output."${name}_ip" = {
      value = tfRef "oci_core_instance.${name}.public_ip";
    };

    output."${name}_ip6" = {
      value = tfRef "data.oci_core_vnic.${name}_vnic.ipv6addresses[0]";
    };
  };
in
{
  imports = [
    ./variables.nix
    ./network.nix
    ./images.nix
    ./dns.nix
  ];

  config = lib.mkMerge [
    {
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
        api_token = tfRef "var.cloudflare_api_token";
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
    }

    (mkOCI "shiva" {
      shape = "VM.Standard.A1.Flex";
      shape_config = {
        memory_in_gbs = 24;
        ocpus = 4;
      };
      source_details = {
        source_type = "image";
        source_id = tfRef "data.oci_core_images.always-free.images[0].id";
        boot_volume_size_in_gbs = 140;
      };
    })

    (mkOCI "ant1" {
      shape = "VM.Standard.E2.1.Micro";
      source_details = {
        source_type = "image";
        source_id = tfRef "data.oci_core_images.always-free.images[0].id";
        boot_volume_size_in_gbs = 50;
      };
    })

    # (mkOCI "ant2" {
    #   shape = "VM.Standard.E2.1.Micro";
    #   source_details = {
    #     source_type = "image";
    #     source_id = tfRef "data.oci_core_images.always-free.images[0].id";
    #     boot_volume_size_in_gbs = 50;
    #   };
    # })
  ];
}
