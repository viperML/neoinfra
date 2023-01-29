{
  outputs = {
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
        ./packages
        ./terraform
        ./packer
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
          };
        };

        legacyPackages = pkgs;

        devShells = with pkgs; {
          format = mkShellNoCC {
            name = "neoinfra-format";
            packages = [
              treefmt
              alejandra
              config.packages.hcl
              black
            ];
          };

          default = mkShellNoCC {
            name = "neoinfra-shell";
            packages = [
              sops
              age
              (python3.withPackages (p: [
                p.click
              ]))
            ];
            shellHook = ''
              venv="$(cd $(dirname $(which python)); cd ..; pwd)"
              ln -sfvT "$venv" "$PWD/.venv"
            '';
          };
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-oldstable.url = "github:NixOS/nixpkgs/nixos-22.05";
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
    viperML-dotfiles.url = "github:viperML/dotfiles";
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
    nix-overlay-guix = {
      url = "github:foo-dogsquared/nix-overlay-guix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
