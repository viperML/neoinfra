{ system, modules }:
let
  sources = import ../npins;
  pkgs = import ../packages.nix { inherit system; };
in
pkgs.nixos (
  [
    "${sources.nix-common}/nixos"
  ]
  ++ modules
)
