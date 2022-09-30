{
  self,
  withSystem,
  inputs,
  config,
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
        ./common.nix
        ./step.nix
      ];
    };
  });

  flake.deploy.nodes."skadi" = {
    hostname = "skadi";
    fastConnection = false;
    profiles.system = {
      sshUser = "admin";
      path = inputs.deploy-rs.lib."x86_64-linux".activate.nixos config.flake.nixosConfigurations."skadi";
      user = "root";
    };
  };
}
