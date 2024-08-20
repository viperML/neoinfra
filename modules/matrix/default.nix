# copied from https://github.com/adamcstephens/stop-export/blob/795d6c683c0b2ed5f55cc16af348a372e2111149/services/synapse/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  server_name = "ayats.org";
  virtualHost = "matrix.${server_name}";

  synapsePort = 8008;
  slidingSyncPort = 8009;
  sopsFile = ../../secrets/matrix.yaml;
in {
  imports = [
    ../matrix-bridge-irc
    # ../matrix-bridge-whatsapp
    # ../matrix-bridge-telegram
  ];

  sops.secrets = {
    matrix-synapse-config = {
      inherit sopsFile;
      owner = config.systemd.services.matrix-synapse.serviceConfig.User;
      group = config.systemd.services.matrix-synapse.serviceConfig.Group;
    };

    matrix-backup-password = {
      inherit sopsFile;
      owner = config.systemd.services.matrix-synapse.serviceConfig.User;
      group = config.systemd.services.matrix-synapse.serviceConfig.Group;
    };

    matrix-sliding-sync-env = {
      inherit sopsFile;
      # owner = "matrix-sliding-sync";
      # group = "matrix-sliding-sync";
    };

    matrix-backup-env = {
      inherit sopsFile;
    };
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = ["matrix-synapse"];
  };

  services.matrix-synapse = {
    enable = true;

    settings = {
      inherit server_name;
      public_baseurl = "https://${virtualHost}/";
      web_client_location = "https://${virtualHost}/";
      # web_client_location = null;

      database.name = "psycopg2";
      enable_metrics = true;
      listeners = [
        {
          port = synapsePort;
          bind_addresses = ["::1"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
        # {
        #   port = 9008;
        #   resources = [];
        #   tls = false;
        #   bind_addresses = ["127.0.0.1"];
        #   type = "metrics";
        # }
      ];

      # we'll trust matrix.org implicitly
      suppress_key_server_warning = true;

      allow_guest_access = false;
      url_preview_enabled = true;
      expire_access_token = true;

      # deploy
      enable_registration = false;
      enable_registration_without_verification = true;
    };

    extras = ["oidc"];

    extraConfigFiles = [config.sops.secrets.matrix-synapse-config.path];
  };

  services.matrix-sliding-sync = {
    enable = false; # not used
    environmentFile = config.sops.secrets.matrix-sliding-sync-env.path;
    createDatabase = true;
    settings = {
      SYNCV3_SERVER = "https://${virtualHost}";
      SYNCV3_BINDADDR = "[::1]:${toString slidingSyncPort}";
    };
  };

  services.nginx.virtualHosts = {
    ${virtualHost} = {
      useACMEHost = "ayats.org";
      forceSSL = true;
      locations = {
        "~ ^/(_matrix|_synapse/client|versions)".proxyPass = "http://[::1]:${toString synapsePort}";
      };
    };
  };

  services.restic.backups = let
    common = {
      user = "matrix-synapse";
      passwordFile = config.sops.secrets.matrix-backup-password.path;
      rcloneConfig = import ../rclone-config.nix;
      initialize = true;
      environmentFile = config.sops.secrets.matrix-backup-env.path;
    };
  in {
    matrix-synapse-data = lib.mkMerge [
      common
      {
        repository = "rclone:matrix:matrix/backup-synapse-data";
        paths = [
          "/var/lib/matrix-synapse"
        ];
      }
    ];

    matrix-synapse-db = lib.mkMerge [
      common
      {
        repository = "rclone:matrix:matrix/backup-synapse-db";
        dynamicFilesFrom = "${pkgs.writeShellScript "restic-matrix-synapse-db-files" ''
          set -xeu
          outfile=$(mktemp -d)/matrix-synapse-backup
          ${config.services.postgresql.package}/bin/pg_dump --format=custom --compress=0 --clean matrix-synapse -f $outfile
          echo $outfile
        ''}";
      }
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/matrix-synapse 0700 matrix-synapse matrix-synapse - -"
    "z /var/lib/matrix-synapse 0700 matrix-synapse matrix-synapse - -"
  ];

  assertions = [
    {
      assertion = config.services.postgresql.enable;
      message = "matrix needs postgres";
    }
    {
      assertion = config.services.nginx.enable;
      message = "matrix needs nginx";
    }
  ];
}
