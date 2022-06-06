{pkgs ? import ./default.nix {}}:
with pkgs; let
  treefmt-cfg = writeText "treefmt.toml" ''
    [formatter.nix]
    command = "alejandra"
    includes = ["*.nix"]

    [formatter.sh]
    command = "shfmt"
    includes = ["*.sh"]

    [formatter.hcl]
    command = "hclfmt"
    includes = ["*.hcl"]
  '';

  treefmt-wrapped = symlinkJoin {
    inherit (treefmt) name;
    paths = [treefmt];
    buildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/treefmt \
        --add-flags "--config-file ${treefmt-cfg} --tree-root ."
    '';
  };
in
  mkShell {
    packages = [
      packer
      hcloud
      shellcheck
      age
      sops
      deploy-rs
      nomad
      step-cli
      step-ca
      google-cloud-sdk-gce
      (terraform.withPlugins (t: [
        t.google
        t.external
        t.cloudflare
      ]))
      # Formatters
      treefmt-wrapped
      hcl
      alejandra
      shfmt
    ];
  }
