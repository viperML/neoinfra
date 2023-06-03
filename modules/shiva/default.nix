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
        ../tailscale.nix
        ../login-classic.nix

        ../vault

        ./configuration.nix
        ../user-ayats.nix

        inputs.vscode-server.nixosModules.default
        {services.vscode-server.enable = true;}

        inputs.nh.nixosModules.default
        {
          nh = {
            enable = true;
            clean.enable = true;
          };
        }

        ../mosh.nix
        # ../direnv.nix
        # inputs.viperML-dotfiles.nixosModules.xdg-ninja

        # ../nomad
        # ../mosquitto
        # self.nixosModules.guix
      ];
    };
  });
}
