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
        # ./packages
        # ./terraform
        # ./packer
        # ./modules
        # ./kubernetes
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
            ];
          };
      };
    });

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs-oldstable.url = "github:NixOS/nixpkgs/nixos-22.05";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-common = {
      url = "github:viperML/nix-common";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # viperML-dotfiles.url = "github:viperML/dotfiles";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nomad-driver-containerd-nix = {
    #   # url = "git+https://gitea.redalder.org/Magic_RB/nomad-driver-containerd-nix.git";
    #   url = "gitlab:_viperML/nomad-driver-containerd-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    envfs = {
      url = "github:Mic92/envfs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh = {
      url = "github:viperML/nh";
      # Broken in 23.05
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-images = {
      url = "github:nix-community/nixos-images";
    };
    delphix = {
      url = "github:viperML/delphix";
    };
    nix-ld = {
      url = "github:nix-community/nix-ld-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pixel-tracker = {
      url = "github:viperML/pixel-tracker";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    wrapper-manager = {
      url = "github:viperML/wrapper-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
