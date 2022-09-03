{
  inputs,
  withSystem,
  ...
}: {
  flake.nixosConfigurations = withSystem "x86_64-linux" ({
    pkgs,
    system,
    nixosSystem,
    modulesPath,
    ...
  }: let
    modules = [
      "${modulesPath}/profiles/minimal.nix"
      "${modulesPath}/profiles/qemu-guest.nix"
      ./common.nix
      ./step.nix
      ../oracle.nix
    ];
  in {
    "skadi" = nixosSystem {
      inherit pkgs system modules;
    };
  });
}
