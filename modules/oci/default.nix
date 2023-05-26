{
  inputs,
  withSystem,
  config,
  lib,
  self,
  ...
}: let
  modulesPath = "${inputs.nixpkgs}/nixos/modules";
in {
  flake = {
    nixosModules.oci.imports = [
      ./hardware.nix
      ./opts.nix
      inputs.disko.nixosModules.disko
      "${modulesPath}/profiles/minimal.nix"
      "${modulesPath}/profiles/qemu-guest.nix"
    ];

    # nixosConfigurations = {
    #   "oci-aarch64-installer" = withSystem "aarch64-linux" ({
    #     system,
    #     pkgs,
    #     ...
    #   }:
    #     inputs.nixpkgs.lib.nixosSystem {
    #       inherit system pkgs;
    #       modules = [
    #         config.flake.nixosModules.oci
    #         ./installer.nix
    #       ];
    #     });

    #   "oci-x86_64-installer" = inputs.nixpkgs.lib.nixosSystem {
    #     system = "x86_64-linux";
    #     modules = [
    #       config.flake.nixosModules.oci
    #       ./installer.nix
    #     ];
    #   };
    # };
    nixosConfigurations = lib.listToAttrs (map (system:
      lib.nameValuePair "${system}-oci-installer" (withSystem system ({
        pkgs,
        nixosSystem,
        ...
      }:
        nixosSystem {
          inherit pkgs system;
          modules = [
            config.flake.nixosModules.oci
            ./installer.nix
          ];
        })))
    config.systems);
    # nixosConfigurations = lib.genAttrs config.systems (system: {
    #   "oci-installer-${system}" = withSystem system ({pkgs, ...}:
    #     inputs.nixpkgs.lib.nixosSystem {
    #     });
    # });
  };

  perSystem = {
    pkgs,
    system,
    ...
  }: {
    packages.oci-disko-check =
      (pkgs.nixos [
        inputs.delphix.nixosModules.installer
        {delphix.target = self.nixosConfigurations."${system}-oci-installer".extendModules {
          modules = [{viper.mainDisk="/dev/vda";}];
        };}
      ])
      .config
      .delphix
      .vm-interactive;
  };
}
