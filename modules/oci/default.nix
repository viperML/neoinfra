{
  withSystem,
  self,
  inputs,
  ...
}: {
  flake = {
    nixosModules.oci = args: {
      imports = [
        ./hardware.nix
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
