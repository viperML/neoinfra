{lib, ...}: let
  inherit (lib) tfRef;

  mkStringVar = description: {
    type = "string";
    inherit description;
  };
in {
  variable = {
    "compartment_id" = mkStringVar "OCI Compartment OCID";
    "oci_key_id" = mkStringVar "Vault Key OCID";

    "cloudflare_email" = mkStringVar "Email of the Cloudflare account";
    "cloudflare_api_token" = mkStringVar "API Key for Cloudflare";
    "cloudflare_zone_id" = mkStringVar "Zone ID for Cloudflare";
    "cloudflare_account_id" = mkStringVar "Account ID for Cloudflare";

    # "deploy_ip" = mkStringVar "Test IP of the deploy machine, for testing purposes";
  };
}
