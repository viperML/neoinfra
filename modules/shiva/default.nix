{
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
    "shiva" = nixosSystem {
      inherit system pkgs;

      modules = [
        self.nixosModules.oci
        inputs.nix-common.nixosModules.default
        inputs.sops-nix.nixosModules.sops
        ../ssh-admin.nix
        ../tailscale.nix

        ./configuration.nix
        ../user-ayats.nix

        inputs.vscode-server.nixosModules.default
        {services.vscode-server.enable = true;}

        # ../direnv.nix
        # inputs.viperML-dotfiles.nixosModules.xdg-ninja

        # ../nomad
        # ../mosquitto
        # self.nixosModules.guix
      ];
    };
  });
}
