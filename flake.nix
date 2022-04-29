{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
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
    nixos-flakes = {
      url = "github:viperML/nixos-flakes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
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
  in {
    nixosConfigurations."sumati" = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = pkgsFor.${system};
      specialArgs = {inherit inputs;};
      modules = let
        modulesPath = "${nixpkgs}/nixos/modules";
      in [
        ./modules/hardware.nix
        ./modules/admin.nix
        ./modules/services.nix
        "${modulesPath}/profiles/minimal.nix"
        "${modulesPath}/profiles/qemu-guest.nix"
        inputs.nixos-flakes.nixosModules.channels-to-flakes
        inputs.sops-nix.nixosModules.sops
        self.nixosModules.hcloud
        ./modules/nix-serve.nix
        ./modules/gitlab-runner.nix
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
      inherit
        (inputs.unstable.legacyPackages.${system})
        alejandra
        treefmt
        ;
    });
  };
}
