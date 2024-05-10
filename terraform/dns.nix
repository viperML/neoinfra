{lib, ...}: let
  inherit (lib.tf) ref;
  withZone = module:
    lib.mkMerge [
      {zone_id = ref "var.cloudflare_zone_id";}
      module
    ];
in {
  resource."cloudflare_record" = {
    "record-matrix" = withZone {
      name = "matrix";
      type = "A";
      proxied = false;
      value = ref "oci_core_instance.shiva.public_ip";
    };

    "record-matrix-wellknown" = withZone {
      type = "SRV";
      name = "_matrix._tcp";

      data = {
        service = "_matrix";
        proto = "_tcp";
        name = "ayats.org";
        priority = 0;
        weight = 0;
        port = 443;
        target = "matrix.ayats.org";
      };
    };

    # mail
    "record-mail-a" = withZone {
      name = "mail";
      type = "A";
      proxied = false;
      value = ref "oci_core_instance.shiva.public_ip";
      ttl = 10800;
    };

    "record-webmail-a" = withZone {
      name = "webmail";
      type = "A";
      proxied = true;
      value = ref "oci_core_instance.shiva.public_ip";
      # ttl     = 10800;
    };

    ## rdns managed by oracle

    "record-mail-mx" = withZone {
      name = "@";
      type = "MX";
      value = "mail.ayats.org";
      priority = 10;
    };

    "record-mail-spf" = withZone {
      name = "@";
      type = "TXT";
      value = "v=spf1 a:mail.ayats.org -all";
      ttl = 10800;
    };

    "record-mail-dkim" = withZone {
      name = "mail._domainkey";
      type = "TXT";
      value = "v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDF1CJldwrRKOLokhmDBgEuPtmo4G38D6DWVwFxarP7ethdcEQxQwty4nOFdwYxtjHcgeupJjv1/YT1oUVCWVHdy4tCUKCeVNb0FJt5cyLonma8jhv7PAMo+7hjQPqsZcteS6DXO3Dv+GhrOfIAHzT2e/gisvXq4a8LI+S7nGUcqQIDAQAB";
      ttl = 10800;
    };

    "record-mail-dmarc" = withZone {
      name = "_dmarc";
      type = "TXT";
      value = "v=DMARC1; p=none";
      ttl = 10800;
    };
  };

  # unused?
  resource."oci_dns_zone"."dns-zone" = {
    name = "ayats.org";
    compartment_id = ref "var.compartment_id";
    zone_type = "PRIMARY";
  };
}
