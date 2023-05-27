{
  perSystem = {pkgs, ...}: {
    packages = {
      nomad = pkgs.callPackage ./nomad.nix {};
    };
  };
}
