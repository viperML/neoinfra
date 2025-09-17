let
  sources = import ./npins;
  lib = import "${sources.nixpkgs}/lib";
in
{
  system ? builtins.currentSystem,
}:
import sources.nixpkgs {
  inherit system;
  config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
      "consul"
      "nomad"
    ];
}
