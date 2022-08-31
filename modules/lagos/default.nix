{
  inputs,
  withSystem,
  ...
}: {
  flake.nixosConfigurations = withSystem "x86_64-linux" ({
    pkgs,
    system,
    nixosSystem,
    modulesPath,
    ...
  }: let
    modules = [
      "${modulesPath}/profiles/minimal.nix"
      ./common.nix
      ./step.nix
    ];
  in {
    "lagos-vm" = nixosSystem {
      inherit pkgs system;
      nixosModules =
        modules
        ++ [
          {
            fileSystems."/" = {
              fsType = "tmpfs";
              device = "none";
            };
            boot.loader.grub.device = "/dev/null";
          }
        ];
    };

    "lagos-prod" = nixosSystem {
      inherit pkgs system;
      nixosModules =
        modules
        ++ [
          "${modulesPath}/virtualisation/google-compute-image.nix"
          {
            virtualisation.googleComputeImage = {
              diskSize = "auto";
              compressionLevel = 9;
            };
          }
        ];
    };
  });
}
