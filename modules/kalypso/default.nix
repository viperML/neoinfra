{
  config,
  inputs,
  self,
  withSystem,
  ...
}: {
  flake.nixosConfigurations = withSystem "x86_64-linux" ({
    nixosSystem,
    pkgs,
    system,
    ...
  }: let
    modules = [
      self.nixosModules.oci
      inputs.sops-nix.nixosModules.sops
      ../ssh-admin.nix
      ../tailscale.nix
      ./common.nix
    ];
  in {
    "kalypso-base" = nixosSystem {
      inherit system pkgs modules;
    };

    "kalypso-prod" = nixosSystem {
      inherit system pkgs;
      modules =
        modules
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
      path = inputs.deploy-rs.lib."x86_64-linux".activate.nixos config.flake.nixosConfigurations."kalypso-prod";
      user = "root";
    };
  };
}
