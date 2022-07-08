{inputs, ...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: {
    packages = {
      hcl = pkgs.callPackage ./hcl.nix {};
      inherit (inputs'.deploy-rs.packages) deploy-rs;
      nomad-driver-containerd-nix = pkgs.buildGoModule {
        src = inputs.nomad-driver-containerd-nix;
        pname = "nomad-driver-containerd-nix";
        version = inputs.nomad-driver-containerd-nix.lastModifiedDate;
        vendorSha256 = "sha256-+EniB8cZ2Jh4A/EdaLlFFhB69fD5ZzqEQ+Yw3M1qyfo=";
      };
    };

    legacyPackages = pkgs;
  };
}
