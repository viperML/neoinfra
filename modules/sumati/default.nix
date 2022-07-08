{
  self,
  inputs,
  ...
}: let
  inherit (inputs) deploy-rs;
in {
  flake.nixosConfigurations = self.lib.mkSystems (modulesPath: {
    system = "x86_64-linux";
    basename = "sumati";
    variants = rec {
      base = [
        ./common.nix
        ../admin.nix
        "${modulesPath}/profiles/minimal.nix"
        "${modulesPath}/profiles/qemu-guest.nix"
        inputs.nix-common.nixosModules.channels-to-flakes
        inputs.sops-nix.nixosModules.sops
      ];
      prod =
        base
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

  flake.deploy.nodes."sumati" = {
    hostname = "sumati";
    fastConnection = false;
    profiles.system = {
      sshUser = "admin";
      path =
        deploy-rs.lib."x86_64-linux".activate.nixos self.nixosConfigurations."sumati-prod";
      user = "root";
    };
  };
}
