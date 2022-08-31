{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-common = {
      url = "github:viperML/nix-common";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    viperML-dotfiles.url = "github:viperML/dotfiles";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nomad-driver-containerd-nix = {
      # url = "git+https://gitea.redalder.org/Magic_RB/nomad-driver-containerd-nix.git";
      url = "gitlab:viperml-public/nomad-driver-containerd-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit self;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./modules/flake-parts.nix
        ./packages
        ./modules/kalypso
        ./modules/lagos
        ./modules/sumati
      ];

      perSystem = {
        pkgs,
        system,
        config,
        lib,
        ...
      }: {
        _module.args = {
          modulesPath = "${nixpkgs}/nixos/modules";
          pkgs = import nixpkgs {
            inherit system;
          };
          nixosSystem = args:
            nixpkgs.lib.nixosSystem (args
              // {
                specialArgs = {
                  inherit inputs self;
                };
              });
        };

        devShells.default = with pkgs;
          mkShell.override {
            stdenv = stdenvNoCC;
          } {
            name = "neoinfra-shell";
            packages = [
              config.packages.hcl
              config.packages.deploy-rs
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
              oci-cli
              (terraform.withPlugins (t: [
                t.google
                t.external
                t.cloudflare
                t.hcloud
                t.oci
              ]))
            ];
          };
      };
    };
}
