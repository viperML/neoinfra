{
  config,
  inputs,
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
      inputs.sops-nix.nixosModules.sops
      ../ssh-admin.nix
      ./common.nix
      ../user-ayats.nix

      # ./minecraft.nix
      ../ld.nix
      inputs.vscode-server.nixosModules.default
      {services.vscode-server.enable = true;}
    ];
  in {
    "chandra" = nixosSystem {
      inherit system pkgs modules;
    };
  });

  flake.deploy.nodes."chandra" = {
    hostname = "chandra";
    fastConnection = false;
    profiles.system = {
      sshUser = "admin";
      path = inputs.deploy-rs.lib."aarch64-linux".activate.nixos config.flake.nixosConfigurations."chandra";
      user = "root";
    };
  };
}
