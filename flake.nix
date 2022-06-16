{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-common = {
      url = "github:viperML/nix-common";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    viperML-dotfiles.url = "github:viperML/dotfiles";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nomad-driver-containerd-nix = {
      url = "git+https://gitlab.com/viperml-public/nomad-driver-containerd-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unfree,
    deploy-rs,
    ...
  }: let
    inherit (nixpkgs) lib;
    supportedSystems = [
      "x86_64-linux"
    ];
    genSystems = lib.genAttrs supportedSystems;
    pkgsFor = genSystems (system:
      self.legacyPackages.${system}
      // self.packages.${system});

    sumati-base-modules = [
      ./modules/sumati/common.nix
      ./modules/admin.nix
      "${nixpkgs}/nixos/modules/profiles/minimal.nix"
      "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
      inputs.nix-common.nixosModules.channels-to-flakes
      inputs.sops-nix.nixosModules.sops
    ];
  in {
    nixosConfigurations."sumati" = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = pkgsFor.${system};
      specialArgs = {inherit inputs self;};
      modules = sumati-base-modules ++ [
        ./modules/sumati/services.nix
        ./modules/sumati/nix-serve.nix
        ./modules/sumati/gitlab-runner.nix
        ./modules/sumati/nomad
        ./nomad/http-store
        ./nomad/blog
      ];
    };

    nixosConfigurations."sumati-golden" = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = pkgsFor.${system};
      specialArgs = {inherit inputs self;};
      modules = sumati-base-modules;
    };

    nixosConfigurations."lagos" = let
      n = inputs.nixpkgs;
    in
      n.lib.nixosSystem rec {
        system = "x86_64-linux";
        pkgs = n.legacyPackages.${system};
        specialArgs = {
          inherit inputs;
        };
        modules = let
          modulesPath = "${n}/nixos/modules";
        in [
          "${modulesPath}/virtualisation/google-compute-image.nix"
          {
            virtualisation.googleComputeImage = {
              diskSize = "auto";
              compressionLevel = 9;
            };
          }
          "${modulesPath}/profiles/minimal.nix"
          ./modules/lagos/common.nix
          ./modules/lagos/step.nix
        ];
      };

    nixosModules = {
      hcloud = import ./modules/hcloud;
    };

    deploy.nodes."sumati" = {
      hostname = "sumati";
      fastConnection = false;
      profiles.system = {
        sshUser = "admin";
        path =
          deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."sumati";
        user = "root";
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    devShells = genSystems (system: {
      default = import ./shell.nix {pkgs = pkgsFor.${system};};
    });

    legacyPackages = nixpkgs-unfree.legacyPackages;

    packages = genSystems (system: let
      callPackage = pkgsFor.${system}.callPackage;
    in {
      hcl = callPackage ./packages/hcl.nix {};
      inherit (deploy-rs.packages.${system}) deploy-rs;
      inherit (inputs.nomad-driver-containerd-nix.packages.${system}) nomad-driver-containerd-nix;
      inherit
        (inputs.unstable.legacyPackages.${system})
        alejandra
        treefmt
        ;
    });
  };
}
