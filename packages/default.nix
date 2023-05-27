{
  perSystem = {pkgs, ...}: {
    packages = {
      nomad = pkgs.nomad.overrideAttrs (old: {
        patches =
          (old.patches or [])
          ++ [
            ./0001-Add-Nix-integration.patch
          ];
      });
    };
  };
}
