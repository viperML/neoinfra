{
  pkgs,
  mkShell,
  deploy-rs,
  hcl,
  ...
}: let
  terraform' = pkgs.terraform.withPlugins (t: [
    t.google
    t.external
    t.cloudflare
  ]);
in
  mkShell {
    name = "neoinfra";
    packages = __attrValues {
      inherit
        (pkgs)
        age
        sops
        packer
        hcloud
        shellcheck
        nomad
        step-cli
        step-ca
        google-cloud-sdk-gce
        moreutils
        remarshal
        alejandra
        shfmt
        ;
      inherit
        deploy-rs
        hcl
        terraform'
        ;
    };
  }
