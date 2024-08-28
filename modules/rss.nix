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

    freshrss-backup-password = {
      inherit sopsFile;
    };

    freshrss-backup-env = {
      inherit sopsFile;
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

  services.restic.backups.freshrss = {
    repository = "rclone:freshrss:freshrss/backup-freshrss";
    paths = [
      cfg.dataDir
    ];
    user = "root";
    passwordFile = config.sops.secrets.freshrss-backup-password.path;
    rcloneConfig = import ./rclone-config.nix;
    initialize = true;
    environmentFile = config.sops.secrets.freshrss-backup-env.path;
  };
}
