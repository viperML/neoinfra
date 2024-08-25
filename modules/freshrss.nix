{config, pkgs, ...}: let
  sopsFile = ../secrets/freshrss.yaml;
  cfg = config.services.freshrss;
in {
  sops.secrets = {
    freshrss_password = {
      inherit sopsFile;
    };
  };

  services.freshrss = {
    enable = true;
    passwordFile = config.sops.secrets.freshrss_password.path;
    virtualHost = "freshrss";
    baseUrl = "https://${cfg.virtualHost}.ayats.org";
  };
}
