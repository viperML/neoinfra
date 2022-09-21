{
  withSystem,
  config,
  inputs,
  modulesPath,
  ...
}: {
  flake.nixosConfigurations = withSystem "x86_64-linux" ({
    pkgs,
    system,
    nixosSystem,
    ...
  }: let
    modules = [
      # TODO hetzner.nix
      "${modulesPath}/profiles/minimal.nix"
      "${modulesPath}/profiles/qemu-guest.nix"

      inputs.sops-nix.nixosModules.sops
      ./common.nix
      ../ssh-admin.nix
    ];
  in {
    "sumati-base" = nixosSystem {
      inherit pkgs system modules;
    };

    "sumati-prod" = nixosSystem {
      inherit pkgs system;
      modules =
        modules
        ++ [
          ./services.nix
          # ./nix-serve.nix
          ./gitlab-runner.nix
          ./nomad
          #
          # ./nomad/http-store
          ../../nomad/blog
        ];
    };
  });

  flake.deploy.nodes."sumati" = {
    hostname = "sumati";
    fastConnection = false;
    profiles.system = {
      sshUser = "admin";
      path = inputs.deploy-rs.lib."x86_64-linux".activate.nixos config.flake.nixosConfigurations."sumati-prod";
      user = "root";
    };
  };
}
