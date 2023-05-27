{
  inputs,
  self,
  ...
}: {
  imports = [
    ./oci
    ./flake-parts.nix

    ./shiva
    # ./skadi
    # ./kalypso
    # ./chandra
    # ./sumati
    # ./guix
  ];

  perSystem = {pkgs, ...}: {
    /*
    Copy this for our nixpkgs
    https://github.com/nix-community/nixos-images/blob/main/flake.nix
    */
    packages.kexec-installer-noninteractive =
      (pkgs.nixos [
        inputs.nixos-images.nixosModules.kexec-installer
        inputs.nixos-images.nixosModules.noninteractive
        {system.kexec-installer.name = "nixos-kexec-installer-noninteractive";}
      ])
      .config
      .system
      .build
      .kexecTarball;

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
