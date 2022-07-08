{self, ...}: {
  flake.nixosConfigurations = self.lib.mkSystems (modulesPath: {
    system = "x86_64-linux";
    basename = "lagos";
    variants = let
      base = [
        "${modulesPath}/profiles/minimal.nix"
        ./common.nix
        ./step.nix
      ];
    in {
      vm =
        base
        ++ [
          {
            fileSystems."/" = {
              fsType = "tmpfs";
              device = "none";
            };
            boot.loader.grub.device = "/dev/null";
          }
        ];
      prod =
        base
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
