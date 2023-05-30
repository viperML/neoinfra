{
  pkgs,
  lib,
  ...
}: {
  networking.hostName = "shiva";
  system.stateVersion = "23.05";

  environment.systemPackages = [
    pkgs.git
  ];

  documentation = {
    enable = true;
    man.enable = true;
  };

  sops.age = {
    keyFile = "/var/lib/secrets/main.age";
    sshKeyPaths = [];
  };

  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = ../../secrets/shiva.yaml;

  nix.package = let
    base = pkgs.nix;
    min = pkgs.nixVersions.nix_2_15;
  in
    if lib.versionAtLeast base.version min.version
    then base
    else min;
}
