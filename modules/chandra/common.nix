{
  config,
  pkgs,
  rootPath,
  ...
}: let
  hostName = "chandra";
in {
  system.stateVersion = "22.05";

  networking = {
    inherit hostName;
    hostId = builtins.substring 0 8 (builtins.hashString "md5" hostName);
  };

  sops.age = {
    keyFile = "/var/lib/secrets/${hostName}.age";
    sshKeyPaths = [];
  };
  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = rootPath + "/secrets/${hostName}.yaml";
}
