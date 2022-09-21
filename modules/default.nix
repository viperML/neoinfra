{inputs, ...}: {
  imports = [
    ./oci
    ./flake-parts.nix
  ];

  perSystem = {pkgs, ...}: {
    _module.args = {
      modulesPath = "${inputs.nixpkgs}/nixos/modules";

      nixosSystem = args:
        inputs.nixpkgs.lib.nixosSystem {
          inherit (args) system pkgs;
          modules =
            args.modules
            ++ [
              ./common.nix
            ];
        };
    };
  };
}
