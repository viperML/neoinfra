{
  withSystem,
  config,
  inputs,
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
      ./common.nix
      ../admin.nix
      "${modulesPath}/profiles/minimal.nix"
      "${modulesPath}/profiles/qemu-guest.nix"
      inputs.nix-common.nixosModules.channels-to-flakes
      inputs.sops-nix.nixosModules.sops
      ./step-renew.nix
    ];
  in {
    "sumati-base" = nixosSystem {
      inherit pkgs system;
      nixosModules = modules;
    };

    "sumati-prod" = nixosSystem {
      inherit pkgs system;
      nixosModules =
        modules
        ++ [
          ./services.nix
          ./nix-serve.nix
          ./gitlab-runner.nix
          ./nomad
          #
          # ./nomad/http-store
          ../../nomad/blog
        ];
    };
  });
}
