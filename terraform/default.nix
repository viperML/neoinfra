_: {
  perSystem = {pkgs, ...}: {
    devShells.terraform = pkgs.mkShellNoCC {
      name = "neoinfra-terraform";
      packages = with pkgs; [
        sops
        oci-cli
        hcloud
        (terraform.withPlugins (t: [
          t.google
          t.external
          t.cloudflare
          t.hcloud
          t.oci
        ]))
      ];
    };
  };
}
