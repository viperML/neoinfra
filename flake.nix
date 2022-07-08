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
      flake = false;
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
    deploy-rs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit self;}
    {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./flake-parts.nix

        ./packages
        ./modules/lagos
        ./modules/kalypso
        ./modules/sumati
      ];

      perSystem = {
        pkgs,
        self',
        ...
      }: {
        devShells.default = pkgs.callPackage ./shell.nix {
          inherit (self'.packages) deploy-rs hcl;
        };
      };

      flake = let
        inherit (nixpkgs) lib;
      in {
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
        lib = {
          mkSystems = f: let
            input = f "${nixpkgs}/nixos/modules";
            inherit (input) system basename variants;
          in
            lib.mapAttrs' (n: modules:
              lib.nameValuePair "${basename}-${n}" (nixpkgs.lib.nixosSystem {
                inherit system;
                pkgs = self.legacyPackages.${system};
                modules =
                  modules
                  ++ [
                    {_module.args = {inherit inputs self;};}
                  ];
              }))
            variants;
        };
      };
    };
}
