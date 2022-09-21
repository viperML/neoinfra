{
  modulesPath,
  self,
  withSystem,
  ...
}: {
  flake = {
    nixosModules.oci = _: {
      imports = [
        ./hardware.nix
        "${modulesPath}/profiles/minimal.nix"
        "${modulesPath}/profiles/qemu-guest.nix"
      ];
    };

    nixosConfigurations = {
      "golden-oci-aarch64" = withSystem "aarch64-linux" ({
        pkgs,
        nixosSystem,
        ...
      }:
        nixosSystem {
          system = "aarch64-linux";
          inherit pkgs;
          modules = [
            self.nixosModules.oci
            ./golden.nix
          ];
        });

      "golden-oci-x86_64" = withSystem "x86_64-linux" ({
        pkgs,
        nixosSystem,
        ...
      }:
        nixosSystem {
          system = "aarch64-linux";
          inherit pkgs;
          modules = [
            self.nixosModules.oci
            ./golden.nix
          ];
        });
    };
  };
}
