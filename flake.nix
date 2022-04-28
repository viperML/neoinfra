{
  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    supportedSystems = [
      "x86_64-linux"
    ];
    pkgsFor = nixpkgs.legacyPackages;
    genSystems = lib.genAttrs supportedSystems;
  in {
    devShells = genSystems (system: {
      default = import ./shell.nix {pkgs = pkgsFor.${system};};
    });
  };
}
