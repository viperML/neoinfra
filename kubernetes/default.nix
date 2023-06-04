{
  perSystem = {pkgs, ...}: {
    devShells.kubernetes = with pkgs;
      mkShellNoCC {
        packages = [
          kubectl
        ];
      };
  };
}
