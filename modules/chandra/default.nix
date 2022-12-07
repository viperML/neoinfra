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
  }: {
    "chandra" = nixosSystem {
      inherit system pkgs;
      modules = [
        self.nixosModules.oci
        inputs.sops-nix.nixosModules.sops
        ../ssh-admin.nix
        ../tailscale.nix

        ./common.nix
        ../user-ayats.nix

        # ./minecraft.nix
        ../ld.nix
        inputs.vscode-server.nixosModules.default
        {services.vscode-server.enable = true;}
        inputs.envfs.nixosModules.envfs

        ../direnv.nix
        inputs.viperML-dotfiles.nixosModules.xdg-ninja

        ../nomad
        # ../mosquitto
        # self.nixosModules.guix
      ];
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
