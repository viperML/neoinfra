{inputs, ...}: {
  flake.nixosModules.golden = _: {
    imports = [
      inputs.sops-nix.nixosModules.sops
      ./common.nix
    ];
  };
}
