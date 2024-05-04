{
  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({lib, ...}: {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./modules
      ];

      perSystem = {
        pkgs,
        system,
        ...
      }: {
        _module.args = {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
            ];
            config.allowUnfreePredicate = pkg:
              builtins.elem (lib.getName pkg) [
                "terraform"
                "consul"
                "nomad"
              ];
          };
        };

        legacyPackages = pkgs;

        devShells.default = with pkgs;
          mkShell.override {stdenv = stdenvNoCC;} {
            packages = [
              sops
              rclone
              (inputs.wrapper-manager.lib.build {
                inherit pkgs;
                modules = [
                  {
                    wrappers.rustic = {
                      basePackage = pkgs.rustic-rs;
                      extraWrapperFlags = ''--run 'cd "$ROOT"' '';
                    };
                  }
                ];
              })
              (terraform.withPlugins (t: [
                t.external
                t.cloudflare
                t.oci
                t.null
                t.local
                t.cloudinit
              ]))
              oci-cli
              shellcheck
              age
              just
              nomad
              hclfmt

              perlPackages.perl
              perlPackages.AppCmd
              perlPackages.DataDumper
              perlPackages.Exporter
              perlPackages.TermANSIColor
              perlPackages.JSON
              perlPackages.NetOpenSSH
              perlPackages.StringUtil
              perlPackages.PerlCritic
              perlPackages.PadWalker
              perlPackages.FileSlurp
            ];
          };
      };
    });

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    snm = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-common = {
      url = "github:viperML/nix-common";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrapper-manager = {
      url = "github:viperML/wrapper-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noshell = {
      url = "github:viperML/noshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
