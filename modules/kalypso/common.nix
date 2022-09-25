{
  config,
  pkgs,
  rootPath,
  ...
}: let
  hostName = "kalypso";
in {
  system.stateVersion = "22.05";

  networking = {
    inherit hostName;
    hostId = builtins.substring 0 8 (builtins.hashString "md5" hostName);
  };

  sops.age = {
    keyFile = "/var/lib/secrets/kalypso.age";
    sshKeyPaths = [];
  };
  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = rootPath + "/secrets/kalypso.yaml";
}
