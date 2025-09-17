{ system, modules }:
let
  sources = import ../npins;
  pkgs = import ../packages.nix { inherit system; };
in
(import "${sources.nixpkgs}/nixos/lib/eval-config.nix" {
  system = null;
  modules = [
    {
      config.nixpkgs.pkgs = pkgs;
    }

  ]
  ++ modules;
})
