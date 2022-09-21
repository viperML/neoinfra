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
  }: let
    modules = [
      self.nixosModules.oci
      ./common.nix
      ./step.nix
    ];
  in {
    "skadi" = nixosSystem {
      inherit pkgs system modules;
    };
  });
}
