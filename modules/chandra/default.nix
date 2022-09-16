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
    modules = [
      "${modulesPath}/profiles/minimal.nix"
      "${modulesPath}/profiles/qemu-guest.nix"
      inputs.nix-common.nixosModules.channels-to-flakes
      ../oracle.nix
      ../ssh-admin.nix
      ./common.nix
      inputs.sops-nix.nixosModules.sops

      # ./minecraft.nix
      ../ld.nix
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
