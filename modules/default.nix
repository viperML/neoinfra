{
  inputs,
  self,
  modulesPath,
  ...
}: {
  imports = [
    ./golden
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
            rootPath = ../.;
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
