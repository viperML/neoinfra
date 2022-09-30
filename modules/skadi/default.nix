{
  self,
  withSystem,
  ...
}: {
  flake.nixosConfigurations = withSystem "aarch64-linux" ({
    pkgs,
    system,
    nixosSystem,
    ...
  }: {
    "skadi" = nixosSystem {
      inherit pkgs system;
      modules = [
        self.nixosModules.oci
        ./common.nix
        ./step.nix
      ];
    };
  });
}
