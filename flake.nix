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
      url = "gitlab:_viperML/nomad-driver-containerd-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

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

        # ./modules/kalypso
        # ./modules/skadi
        # ./modules/sumati
        # ./modules/chandra

        # ./modules/oci
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
          };
        };

        legacyPackages = pkgs;

        devShells = with pkgs; {
          format = mkShellNoCC {
            name = "neoinfra-format";
            packages = [
              treefmt
              shfmt
              alejandra
              config.packages.hcl
            ];
          };

          python = mkShellNoCC {
            name = "neoinfra-python";
            packages = [
              (python3.withPackages (p: [
                p.click
                p.Fabric
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
}
