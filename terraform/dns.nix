{
  lib,
  ...
}:
let
  inherit (lib.tf) ref;
  withZone =
    module:
    lib.mkMerge [
      { zone_id = ref "var.cloudflare_zone_id"; }
      module
    ];

  shivaIp = ref "oci_core_instance.shiva.public_ip";
  shivaIp6 = ref "data.oci_core_vnic.shiva_vnic.ipv6addresses[0]";
in
{
  resource."cloudflare_dns_record" = {
    "record-shiva" = withZone {
      name = "shiva.ayats.org";
      type = "A";
      proxied = true;
      content = shivaIp;
      ttl = 1; # auto
    };

    "record-shiva-6" = withZone {
      name = "shiva.ayats.org";
      type = "AAAA";
      proxied = true;
      content = shivaIp6;
      ttl = 1; # auto
    };

    "record-shiva-mc" = withZone {
      name = "mc.ayats.org";
      type = "A";
      proxied = false;
      content = shivaIp;
      ttl = 1; # auto
    };
  };

  # unused?
  resource."oci_dns_zone"."dns-zone" = {
    name = "ayats.org";
    compartment_id = ref "var.compartment_id";
    zone_type = "PRIMARY";
  };
}
