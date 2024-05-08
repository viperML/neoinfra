{inputs, ...}: {
  perSystem = {config, pkgs, system, ...}: {
    packages.terranix = inputs.terranix.lib.terranixConfiguration {
      inherit system;
      modules = [
        ./main.nix
      ];
    };
  };
}
