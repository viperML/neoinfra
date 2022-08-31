{
  inputs,
  withSystem,
  config,
  ...
}: {
  flake.nixosConfigurations = withSystem "aarch64-linux" ({
    pkgs,
    system,
    modulesPath,
    nixosSystem,
    ...
  }: let
    nixosModules = [
      "${modulesPath}/profiles/minimal.nix"
      "${modulesPath}/profiles/qemu-guest.nix"
      inputs.nix-common.nixosModules.channels-to-flakes
      ../oracle.nix
      ../admin.nix
      ./common.nix
      inputs.sops-nix.nixosModules.sops
    ];
  in {
    "kalypso-base" = nixosSystem {
      inherit system pkgs nixosModules;
    };

    "kalypso-prod" = nixosSystem {
      inherit system pkgs;
      nixosModules =
        nixosModules
        ++ [
          ./vault.nix
        ];
    };
  });

  flake.deploy.nodes."kalypso" = {
    hostname = "kalypso";
    fastConnection = false;
    profiles.system = {
      sshUser = "admin";
      path = inputs.deploy-rs.lib."aarch64-linux".activate.nixos config.flake.nixosConfigurations."kalypso-prod";
      user = "root";
    };
  };
}
