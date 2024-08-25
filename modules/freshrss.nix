{
  config,
  lib,
  ...
}: let
  sopsFile = ../secrets/freshrss.yaml;
  cfg = config.services.freshrss;
  user = "freshrss";
in {
  sops.secrets = {
    freshrss_password = {
      inherit sopsFile;
      owner = lib.mkIf cfg.enable user;
    };
  };

  services.freshrss = {
    enable = true;
    passwordFile = config.sops.secrets.freshrss_password.path;
    virtualHost = "freshrss";
    baseUrl = "https://${cfg.virtualHost}.ayats.org";
    inherit user;
    database = {
      passFile = config.sops.secrets.freshrss_password.path;
    };
  };
}
