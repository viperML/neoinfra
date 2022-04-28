{
  localSystem ? {system = args.system or builtins.currentSystem;},
  system ? localSystem.system,
  crossSystem ? localSystem,
  ...
} @ args: let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  flake-compat = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
  };
  flake = import flake-compat {
    src = ./.;
  };
  lib = flake.defaultNix.legacyPackages.${system}.lib;
in
  assert args ? localSystem -> !(args ? system);
  assert args ? system -> !(args ? localSystem); lib.recursiveUpdate flake.defaultNix.legacyPackages.${system} flake.defaultNix.packages.${system}
