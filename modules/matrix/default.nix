# copied from https://github.com/adamcstephens/stop-export/blob/795d6c683c0b2ed5f55cc16af348a372e2111149/services/synapse/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  virtualHost = "matrix.ayats.org";
  writeTOML = (pkgs.formats.toml {}).generate;
  synapsePort = 8008;
  slidingSyncPort = 8009;

  mkSynapseRestic = {
    systemdArgs,
    extraScript,
  }:
    lib.mkMerge [
      {
        serviceConfig = {
          EnvironmentFile = config.sops.secrets.matrix-backup-env.path;
          Type = "oneshot";
          PrivateTmp = true;
          User = "matrix-synapse";
          Group = "matrix-synapse";
        };
        environment = {
          RCLONE_CONFIG = pkgs.writeText "rclone.conf" ''
            [matrix]
            type = s3
            provider = Cloudflare
            env_auth = true
            acl = private
            no_check_bucket = true
          '';
        };
        path = [
          pkgs.rclone
          pkgs.rustic-rs
          config.services.postgresql.package
        ];
        script = ''
          # rustic reads the config from $HOME/rustic.toml
          set -xu pipefail

          export HOME=/tmp
          cd $HOME
          ln -vsfT ${writeTOML "rustic.toml" {
            forget = {
              keep-monthly = 1;
            };
            # backup.sources = [
            #   {
            #     source = "/var/lib/matrix-synapse";
            #   }
            # ];
          }} ./rustic.toml
          cat ./rustic.toml

          ${extraScript}
        '';
      }
      systemdArgs
    ];
in {
  sops.secrets.matrix-synapse-config = {
    sopsFile = ../../secrets/matrix.yaml;
    owner = config.systemd.services.matrix-synapse.serviceConfig.User;
    group = config.systemd.services.matrix-synapse.serviceConfig.Group;
  };

  sops.secrets.matrix-backup-env = {
    sopsFile = ../../secrets/matrix.yaml;
  };

  sops.secrets.matrix-sliding-sync-env = {
    sopsFile = ../../secrets/matrix.yaml;
    owner = "matrix-sliding-sync";
    group = "matrix-sliding-sync";
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "matrix-synapse"
    ];
  };

  services.matrix-synapse = {
    enable = true;

    settings = {
      server_name = virtualHost;
      public_baseurl = "https://${virtualHost}/";
      web_client_location = "https://${virtualHost}/";

      database.name = "psycopg2";
      enable_metrics = true;
      listeners = [
        {
          port = synapsePort;
          bind_addresses = ["127.0.0.1"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = ["client" "federation"];
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
      enable_registration = false;
      enable_registration_without_verification = false;
      url_preview_enabled = true;
      expire_access_token = true;
    };

    extras = ["oidc"];

    extraConfigFiles = [config.sops.secrets.matrix-synapse-config.path];

    sliding-sync = {
      enable = true;
      environmentFile = config.sops.secrets.matrix-sliding-sync-env.path;
      createDatabase = true;
      settings = {
        SYNCV3_SERVER = "https://${virtualHost}";
        SYNCV3_BINDADDR =  "127.0.0.1:${toString slidingSyncPort}";
      };
    };
  };

  services.nginx.virtualHosts = {
    ${virtualHost} = {
      useACMEHost = "wildcard.ayats.org";
      forceSSL = true;
      locations = let
        mkWellKnown = data: ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${builtins.toJSON data}';
        '';
      in {
        "/".extraConfig = ''
          return 301 https://ayats.org;
        '';

        "~ ^(/_matrix|/_synapse/client)".proxyPass = "http://localhost:${toString synapsePort}";

        "= /.well-known/matrix/server".extraConfig = mkWellKnown {
          "m.server" = "${virtualHost}:443";
        };
        "= /.well-known/matrix/client".extraConfig = mkWellKnown {
          "m.homeserver".base_url = "https://${virtualHost}";
          "org.matrix.msc3575.proxy".url = "https://${virtualHost}";
        };
        "~ ^/(client/|_matrix/client/unstable/org.matrix.msc3575/sync)".proxyPass = "http://localhost:${toString slidingSyncPort}";
      };
    };
  };

  systemd.services = {
    matrix-synapse-backup = mkSynapseRestic {
      extraScript = ''
        export RUSTIC_REPOSITORY="rclone:matrix:matrix/synapse-data"
        set +e
        rustic init || :
        set -e
        rustic backup /var/lib/matrix-synapse

        export RUSTIC_REPOSITORY="rclone:matrix:matrix/synapse-db"
        set +e
        rustic init || :
        set -e
        pg_dump --format=custom --compress=0 --clean matrix-synapse | rustic backup --stdin-filename matrix-synapse.dump -
      '';
      systemdArgs = {
        startAt = "*-*-* 03:00:00";
      };
    };

    matrix-synapse-restore = mkSynapseRestic {
      extraScript = ''
        if [[ ! -f /var/lib/matrix-synapse/homeserver.signing.key ]]; then
          export RUSTIC_REPOSITORY="rclone:matrix:matrix/synapse-data"
          rustic restore latest:/var/lib/matrix-synapse /var/lib/matrix-synapse

          export RUSTIC_REPOSITORY="rclone:matrix:matrix/synapse-db"
          rustic dump latest:matrix-synapse.dump | pg_restore --clean --if-exists -d matrix-synapse -e
        fi
      '';
      systemdArgs = {
        requiredBy = ["matrix-synapse.service"];
        before = ["matrix-synapse.service"];
      };
    };
  };

  systemd.timers."matrix-synapse-backup" = {
    timerConfig.Persistent = true;
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
