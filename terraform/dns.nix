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
      value = "v=DKIM1; p=${lib.fileContents ../modules/mail/dkim}";
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

  resource."cloudflare_worker_script"."well-known" = {
    name = "well-known";
    account_id = ref "var.cloudflare_account_id";
    content = ref ''
      file("${./well-known.js}")
    '';
    module = true;
  };

  resource."cloudflare_worker_route"."well-known" = withZone {
    pattern = "ayats.org/.well-known/*";
    script_name = ref "cloudflare_worker_script.well-known.name";
  };
}
