{inputs, ...}: {
  perSystem = {
    pkgs,
    inputs',
    ...
  }: {
    packages = let
      guixpkgs = pkgs.extend inputs.nix-overlay-guix.overlays.default;
      old-guixpkgs = inputs'.nixpkgs-oldstable.legacyPackages.extend inputs.nix-overlay-guix.overlays.default;
    in {
      hcl = pkgs.callPackage ./hcl.nix {};

      # nomad-driver-containerd-nix = pkgs.buildGoModule {
      #   src = inputs.nomad-driver-containerd-nix;
      #   pname = "nomad-driver-containerd-nix";
      #   version = inputs.nomad-driver-containerd-nix.lastModifiedDate;
      #   vendorSha256 = "sha256-xLQZzs5WzdWUndKhc4hkVqijewfYY9CipAPCgi39a7M=";
      # };

      inherit (inputs'.deploy-rs.packages) deploy-rs;

      nomad = pkgs.callPackage ./nomad.nix {};

      vault-bin = pkgs.callPackage ./vault-bin.nix {};

      inherit (guixpkgs) guix;
      old-guix = old-guixpkgs.guix;
    };
  };
}
