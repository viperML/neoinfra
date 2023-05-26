{
  self,
  withSystem,
  ...
}: {
  flake.nixosConfigurations = withSystem "x86_64-linux" ({
    pkgs,
    system,
    nixosSystem,
    ...
  }: {
    "skadi" = nixosSystem {
      inherit pkgs system;
      modules = [
        self.nixosModules.oci
        ./configuration.nix
        ../step-ca
      ];
    };
  });
}
