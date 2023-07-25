{pkgs, ...}: let
  p = pkgs.callPackage ./package.nix {};
in {
  systemd.services.distant = {
    script = "${p}/bin/distant server listen --log-level trace";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
  };
}
