{
  lib,
  config,
  ...
}: let
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

    # "record-matrix-6" = withZone {
    #   name = "matrix";
    #   type = "AAAA";
    #   proxied = false;
    #   value = config.output."shiva_ip6".value;
    # };

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

    "record-mail-sub" = withZone {
      type = "SRV";
      name = "_submission._tcp";
      ttl = 3600;
      data = {
        service = "_submission";
        proto = "_tcp";
        name = "ayats.org";
        priority = 5;
        weight = 0;
        port = 587;
        target = "mail.ayats.org";
      };
    };
    "record-mail-subs" = withZone {
      type = "SRV";
      name = "_submissions._tcp";
      ttl = 3600;
      data = {
        service = "_submissions";
        proto = "_tcp";
        name = "ayats.org";
        priority = 5;
        weight = 0;
        port = 465;
        target = "mail.ayats.org";
      };
    };
    "record-mail-imap" = withZone {
      type = "SRV";
      name = "_imap._tcp";
      ttl = 3600;
      data = {
        service = "_imap";
        proto = "_tcp";
        name = "ayats.org";
        priority = 5;
        weight = 0;
        port = 143;
        target = "mail.ayats.org";
      };
    };
    "record-mail-imaps" = withZone {
      type = "SRV";
      name = "_imaps._tcp";
      ttl = 3600;
      data = {
        service = "_imaps";
        proto = "_tcp";
        name = "ayats.org";
        priority = 5;
        weight = 0;
        port = 993;
        target = "mail.ayats.org";
      };
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
