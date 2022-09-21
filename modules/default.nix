{
  inputs,
  self,
  modulesPath,
  ...
}: {
  imports = [
    ./oci
    ./flake-parts.nix

    ./kalypso
    ./skadi
    ./chandra
    ./sumati
  ];

  _module.args.modulesPath = "${inputs.nixpkgs}/nixos/modules";

  perSystem = {pkgs, ...}: {
    _module.args = {
      nixosSystem = args:
        inputs.nixpkgs.lib.nixosSystem {
          inherit (args) system pkgs;
          specialArgs = {
            inherit self;
            inputs = inputs // {inherit self;};
          };
          modules =
            args.modules
            ++ [
              ./common.nix
              inputs.nix-common.nixosModules.channels-to-flakes
            ];
        };
    };
  };
}
