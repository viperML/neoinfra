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
      url = "git+https://gitea.redalder.org/Magic_RB/nomad-driver-containerd-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    deploy-rs,
    ...
  }: let
    inherit (nixpkgs) lib;

    genSystems = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];

    pkgsFor = inputs.nixpkgs.legacyPackages;

    mkSystems = {
      system,
      basename,
      variants,
    }:
      lib.mapAttrs' (n: modules:
        lib.nameValuePair "${basename}-${n}" (nixpkgs.lib.nixosSystem {
          inherit system modules;
          pkgs = pkgsFor.${system};
          specialArgs = {inherit inputs self;};
        }))
      variants;

    modulesPath = "${nixpkgs}/nixos/modules";
  in {
    nixosConfigurations =
      (mkSystems {
        system = "x86_64-linux";
        basename = "sumati";
        variants = rec {
          base = [
            ./modules/sumati/common.nix
            ./modules/admin.nix
            "${modulesPath}/profiles/minimal.nix"
            "${modulesPath}/profiles/qemu-guest.nix"
            inputs.nix-common.nixosModules.channels-to-flakes
            inputs.sops-nix.nixosModules.sops
          ];
          prod =
            base
            ++ [
              ./modules/sumati/services.nix
              ./modules/sumati/nix-serve.nix
              ./modules/sumati/gitlab-runner.nix
              ./modules/sumati/nomad
              #
              # ./nomad/http-store
              ./nomad/blog
            ];
        };
      })
      // (mkSystems {
        system = "x86_64-linux";
        basename = "lagos";
        variants = let
          base = [
            "${modulesPath}/profiles/minimal.nix"
            ./modules/lagos/common.nix
            ./modules/lagos/step.nix
          ];
        in {
          vm =
            base
            ++ [
              {
                fileSystems."/" = {
                  fsType = "tmpfs";
                  device = "none";
                };
                boot.loader.grub.device = "/dev/null";
              }
            ];
          prod =
            base
            ++ [
              "${modulesPath}/virtualisation/google-compute-image.nix"
              {
                virtualisation.googleComputeImage = {
                  diskSize = "auto";
                  compressionLevel = 9;
                };
              }
            ];
        };
      })
      // (mkSystems {
        system = "aarch64-linux";
        basename = "kalypso";
        variants = rec {
          base = [
            "${modulesPath}/profiles/minimal.nix"
            "${modulesPath}/profiles/qemu-guest.nix"
            inputs.nix-common.nixosModules.channels-to-flakes
            ./modules/kalypso/common.nix
            ./modules/admin.nix
          ];
          prod = base ++ [];
        };
      });

    deploy.nodes."sumati" = {
      hostname = "sumati";
      fastConnection = false;
      profiles.system = {
        sshUser = "admin";
        path =
          deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."sumati-prod";
        user = "root";
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    devShells = genSystems (system: {
      default = pkgsFor.${system}.callPackage ./shell.nix (self.packages.${system});
    });

    legacyPackages = pkgsFor;

    packages = genSystems (system: let
      inherit (pkgsFor.${system}) callPackage;
    in {
      hcl = callPackage ./packages/hcl.nix {};
      inherit (deploy-rs.packages.${system}) deploy-rs;
      nomad-driver-containerd-nix = pkgsFor.${system}.buildGoModule {
        src = inputs.nomad-driver-containerd-nix;
        pname = "nomad-driver-containerd-nix";
        version = inputs.nomad-driver-containerd-nix.lastModifiedDate;
        vendorSha256 = "sha256-+EniB8cZ2Jh4A/EdaLlFFhB69fD5ZzqEQ+Yw3M1qyfo=";
      };
    });
  };
}
