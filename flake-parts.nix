{
  config,
  self,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit
    (lib)
    filterAttrs
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit
    (flake-parts-lib)
    mkSubmoduleOptions
    ;
in {
  options = {
    flake = mkSubmoduleOptions {
      deploy.nodes = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = {};
        # apply = mapAttrs (k: v: {
        #   _file = "${toString self.outPath}/flake.nix#nixosModules.${k}";
        #   imports = [v];
        # });
        description = ''
          NixOS modules.
        '';
      };
    };
  };
}
