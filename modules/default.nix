{
  inputs,
  self,
  withSystem,
  lib,
  ...
}: {
  flake.nixosConfigurations = {
    "vishnu" = withSystem "x86_64-linux" ({
      system,
      pkgs,
      ...
    }:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.nixpkgs.nixosModules.readOnlyPkgs
          {nixpkgs.pkgs = pkgs;}
          ./host-vishnu
        ];
      });
  };

  perSystem = {pkgs, ...}: {
    /*
    Copy this for our nixpkgs
    https://github.com/nix-community/nixos-images/blob/main/flake.nix
    */
    # packages.kexec-installer-noninteractive =
    #   (pkgs.nixos [
    #     inputs.nixos-images.nixosModules.kexec-installer
    #     inputs.nixos-images.nixosModules.noninteractive
    #     {system.kexec-installer.name = "nixos-kexec-installer-noninteractive";}
    #   ])
    #   .config
    #   .system
    #   .build
    #   .kexecTarball;

    _module.args.nixosSystem = args:
      inputs.nixpkgs.lib.nixosSystem (args
        // {
          specialArgs = {
            inherit self inputs;
            rootPath = ../.;
          };
        });
  };
}
