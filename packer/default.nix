_: {
  perSystem = {pkgs, config, ...}: {
    devShells.packer = pkgs.mkShellNoCC {
      name = "neoinfra-packer";
      packages = with pkgs; [
        sops
        oci-cli
        hcloud
        packer
        config.packages.hcl
      ];
    };
  };
}
