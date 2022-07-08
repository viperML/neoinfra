{
  self,
  inputs,
  ...
}: let
  inherit (inputs) deploy-rs;
in {
  flake.nixosConfigurations = self.lib.mkSystems (modulesPath: {
    system = "aarch64-linux";
    basename = "kalypso";
    variants = rec {
      base = [
        "${modulesPath}/profiles/minimal.nix"
        "${modulesPath}/profiles/qemu-guest.nix"
        inputs.nix-common.nixosModules.channels-to-flakes
        ../oracle.nix
        ../admin.nix
        ./common.nix
        inputs.sops-nix.nixosModules.sops
      ];
      prod =
        base
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
      path =
        deploy-rs.lib."aarch64-linux".activate.nixos self.nixosConfigurations."kalypso-prod";
      user = "root";
    };
  };
}
