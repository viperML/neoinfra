{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
  sopsFile = ../../secrets/mail.yaml;
in {
  imports = [inputs.snm.nixosModule];

  mailserver = {
    enable = true;
    fqdn = "mail.ayats.org";
    domains = ["ayats.org"];

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "fer@ayats.org" = {
        hashedPasswordFile = config.sops.secrets."snm_password_fer".path;
      };
    };

    certificateScheme = "acme-nginx";
  };

  services.roundcube = {
    enable = true;
    hostName = "webmail.ayats.org";
    extraConfig = ''
      # starttls needed for authentication, so the fqdn required to match
      # the certificate
      $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };

  services.nginx.virtualHosts."webmail.ayats.org" = {
    enableACME = false;
    useACMEHost = "wildcard.ayats.org";
    forceSSL = true;
  };

  sops.secrets = {
    "snm_password_fer" = {
      inherit sopsFile;
      owner = config.mailserver.vmailUserName;
      group = config.mailserver.vmailGroupName;
    };

    "snm_dkim_key" = {
      inherit sopsFile;
    };

    "snm-backup-password" = {
      inherit sopsFile;
    };

    "snm-backup-env" = {
      inherit sopsFile;
    };
  };

  systemd.tmpfiles.settings = {
    "99-dkim" = {
      "/var/dkim/ayats.org.mail.txt"."C+" = {
        argument =
          (pkgs.writeText "dkim" ''
            mail._domainkey IN TXT ( "v=DKIM1; k=rsa; "
                "p=${lib.fileContents ./dkim}" )
          '')
          .outPath;
        user = "opendkim";
        group = "opendkim";
        mode = "0600";
      };
      "/var/dkim/ayats.org.mail.key"."C+" = {
        argument = config.sops.secrets."snm_dkim_key".path;
        user = "opendkim";
        group = "opendkim";
        mode = "0600";
      };
    };
  };

  services.restic.backups.mail = {
    repository = "rclone:mail:mail/backup-mail-directory";
    paths = [
      config.mailserver.mailDirectory
    ];
    user = "root";
    passwordFile = config.sops.secrets.snm-backup-password.path;
    rcloneConfig = import ../rclone-config.nix;
    initialize = true;
    environmentFile = config.sops.secrets.snm-backup-env.path;
  };

  assertions = [
    {
      assertion = config.services.nginx.enable;
      message = "mail needs nginx";
    }
  ];
}
