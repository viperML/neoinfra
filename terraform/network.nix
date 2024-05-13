{
  lib,
  nixosConfigurations,
  ...
}: let
  inherit (lib) tfRef;
  withCID = module:
    lib.mkMerge [
      {compartment_id = tfRef "var.compartment_id";}
      module
    ];
  withVCN = module:
    lib.mkMerge [
      (withCID {vcn_id = tfRef "oci_core_vcn.terraform_vcn.id";})
      module
    ];
in {
  resource."oci_core_vcn"."terraform_vcn" = withCID {
    display_name = "neoinfra";
    cidr_blocks = [
      "10.0.0.0/16"
    ];
    dns_label = "neoinfra";
  };

  resource."oci_core_internet_gateway"."terraform_vcn_gateway" = withVCN {
    enabled = true;
    display_name = "terraform gateway";
  };

  resource."oci_core_route_table"."terraform_vcn_route0" = withVCN {
    display_name = "Internet Gateway";
    route_rules = {
      network_entity_id = tfRef "oci_core_internet_gateway.terraform_vcn_gateway.id";
      destination = "0.0.0.0/0";
      destination_type = "CIDR_BLOCK";
    };
  };

  # https://github.com/oracle/terraform-provider-oci/issues/1324

  resource."oci_core_security_list"."all_ingress" = withVCN {
    display_name = "TF - All ingress";
    ingress_security_rules = {
      protocol = "all";
      source = "0.0.0.0/0";
      stateless = false;
    };
  };

  # resource."oci_core_security_list"."all-ingress-deploy" = withVCN {
  #   display_name = "TF - All ingress deploy";
  #   ingress_security_rules = {
  #     protocol = "all";
  #     source = "${tfRef "var.deploy_ip"}/32";
  #     stateless = false;
  #   };
  # };

  data."cloudflare_ip_ranges"."cloudflare" = {};

  resource."oci_core_security_list"."all-ingress-cloudflare" = let
    # https://www.cloudflare.com/ips-v4/#
    blocks = [
      "173.245.48.0/20"
      "103.21.244.0/22"
      "103.22.200.0/22"
      "103.31.4.0/22"
      "141.101.64.0/18"
      "108.162.192.0/18"
      "190.93.240.0/20"
      "188.114.96.0/20"
      "197.234.240.0/22"
      "198.41.128.0/17"
      "162.158.0.0/15"
      "104.16.0.0/13"
      "104.24.0.0/14"
      "172.64.0.0/13"
      "131.0.72.0/22"
    ];
  in
    withVCN {
      display_name = "TF - All ingress cloudflare";
      ingress_security_rules =
        map (source: {
          inherit source;
          protocol = "all";
          stateless = false;
        })
        blocks;
    };

  resource."oci_core_security_list"."core" = {
    compartment_id = tfRef "var.compartment_id";
    vcn_id = tfRef "oci_core_vcn.terraform_vcn.id";
    display_name = "TF - Core";
    ingress_security_rules = [
      {
        # ICMP
        protocol = "1";
        source = "0.0.0.0/0";
        stateless = false;
      }
    ];
    egress_security_rules = [
      {
        # All egress
        protocol = "all";
        destination = "0.0.0.0/0";
        stateless = false;
      }
    ];
  };

  resource."oci_core_security_list"."nixos" = withVCN {
    display_name = "TF - Main";
    ingress_security_rules = lib.mkMerge (map (
      nixos: let
        inherit
          (nixos.config.networking.firewall)
          allowedTCPPorts
          allowedTCPPortRanges
          allowedUDPPorts
          allowedUDPPortRanges
          ;
      in
        (map (port: {
            protocol = "6";
            source = "0.0.0.0/0";
            stateless = false;
            tcp_options = {
              min = port;
              max = port;
            };
          })
          allowedTCPPorts)
        ++ (map ({
            from,
            to,
          }: {
            protocol = "6";
            source = "0.0.0.0/0";
            stateless = false;
            tcp_options = {
              min = from;
              max = to;
            };
          })
          allowedTCPPortRanges)
        ++ (map (port: {
            protocol = "17";
            source = "0.0.0.0/0";
            stateless = false;
            tcp_options = {
              min = port;
              max = port;
            };
          })
          allowedUDPPorts)
        ++ (map ({
            from,
            to,
          }: {
            protocol = "17";
            source = "0.0.0.0/0";
            stateless = false;
            tcp_options = {
              min = from;
              max = to;
            };
          })
          allowedUDPPortRanges)
    ) (builtins.attrValues nixosConfigurations));
  };

  resource."oci_core_subnet"."terraform_subnet" = withVCN {
    display_name = "terraform_subnet";
    cidr_block = "10.0.0.0/24";
    security_list_ids = [
      (tfRef "oci_core_security_list.core.id")
      (tfRef "oci_core_security_list.nixos.id")
      # (tfRef "oci_core_security_list.all-ingress-deploy.id")
      (tfRef "oci_core_security_list.all-ingress-cloudflare.id")
    ];
    route_table_id = tfRef "oci_core_route_table.terraform_vcn_route0.id";
  };

  # resource."oci_core_subnet"."all_ingress_egress" = withVCN {
  #   display_name = "All ingress egress";
  #   cidr_block = "10.0.1.0/24";
  #   security_list_ids = [
  #     (tfRef "oci_core_security_list.core.id")
  #     (tfRef "oci_core_security_list.all_ingress.id")
  #   ];
  #   route_table_id = tfRef "oci_core_route_table.terraform_vcn_route0.id";
  # };
}
