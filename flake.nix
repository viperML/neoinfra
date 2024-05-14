{
  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (out @ {
      lib,
      config,
      ...
    }: {
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
        config,
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

        packages.terranix = inputs.terranix.lib.terranixConfiguration {
          inherit system;
          modules = [
            ./terraform/main.nix
            {
              _module.args = {
                inherit (out.config.flake) nixosConfigurations;
              };
            }
          ];
        };

        devShells.default = with pkgs; let
          myTerraform = terraform.withPlugins (t: [
            t.external
            t.cloudflare
            t.oci
            t.null
            t.local
            t.cloudinit
          ]);
        in
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
              (pkgs.writeShellScriptBin "terraform" ''
                if [[ ! -f .terraform.lock.hcl ]]; then
                  echo "Please run this in a folder with a .terraform.lock.hcl"
                  exit 127
                fi

                set -ex
                nix build "$ROOT#terranix" -L -o config.tf.json

                exec -a "$0" "${myTerraform}/bin/terraform" "$@"
              '')
              myTerraform
              oci-cli
              shellcheck
              age
              just
              # nomad
              hclfmt
              nodejs

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
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
