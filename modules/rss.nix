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
    virtualHost = "freshrss.ayats.org";
    baseUrl = "https://${cfg.virtualHost}";
    inherit user;
    database = {
      type = "sqlite";
      passFile = config.sops.secrets.freshrss_password.path;
    };
  };

  services.nginx.virtualHosts.${cfg.virtualHost} = {
    enableACME = false;
    useACMEHost = "wildcard.ayats.org";
    forceSSL = true;
  };
}
