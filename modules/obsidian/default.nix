{
  config,
  pkgs,
  lib,
  ...
}: let
  writeTOML = (pkgs.formats.toml {}).generate;
  writeJSON = (pkgs.formats.json {}).generate;
  dataDir = "/var/lib/obsidian";
  inherit (config.services.couchdb) user group;

  mkResticService = args: extraScript:
    {
      serviceConfig = {
        EnvironmentFile = config.sops.secrets."obsidian_env".path;
        Type = "oneshot";
        PrivateTmp = true;
        User = user;
        Group = group;
      };
      environment = {
        RCLONE_CONFIG = pkgs.writeText "rclone.conf" ''
          [obsidian]
          type = s3
          provider = Cloudflare
          env_auth = true
          acl = private
          no_check_bucket = true
        '';
        RUSTIC_REPOSITORY = "rclone:obsidian:obsidian";
      };
      path = with pkgs; [
        rclone
        rustic-rs
      ];
      script = ''
        # rustic reads the config from $HOME/rustic.toml
        export HOME=/tmp
        cd $HOME
        ln -vsfT ${writeTOML "rustic.toml" {
          forget = {
            keep-daily = 14;
            keep-weekly = 5;
          };
          backup.sources = [
            {
              source = dataDir;
            }
          ];
        }} ./rustic.toml
        cat ./rustic.toml

        ${extraScript}
      '';
    }
    // args;
in {
  sops.secrets."obsidian_env" = {
    sopsFile = ../../secrets/obsidian.yaml;
  };

  systemd.services."obsidian-restore" =
    mkResticService {
      requiredBy = ["couchdb.service"];
      before = ["couchdb.service"];
    } ''
      rclone ls obsidian:obsidian -vv

      if [[ ! -d ${dataDir}/state/shards ]]; then
        rustic restore latest ${dataDir}
      else
        echo "Data already exists, skipping restore"
      fi
    '';

  systemd.services."obsidian-backup" =
    mkResticService {
      startAt = "*-*-* 03:00:00";
    } ''
      rclone ls obsidian:obsidian -vv

      set +e
      rustic init || :
      set -e

      rustic backup
    '';

  systemd.timers."obsidian-backup" = {
    timerConfig.Persistent = true;
  };

  systemd.services."couchdb" = {
    serviceConfig = {
      MemoryMax = "500M";
    };
  };

  services.couchdb = {
    enable = true;
    viewIndexDir = "${dataDir}/state";
    databaseDir = "${dataDir}/state";
    configFile = "${dataDir}/state/local.ini";
    # https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md
    extraConfig = lib.fileContents ./config.ini;
    bindAddress = "0.0.0.0";
  };

  systemd.services."obsidian-consul" = {
    serviceConfig = {
      Type = "oneshot";
    };
    wantedBy = ["couchdb.service"];
    after = ["couchdb.service"];
    path = [
      pkgs.curl
    ];
    # TODO parse curl output and fail on bad req
    script = ''
      curl --request PUT --data @${writeJSON "service.json" {
        Name = "obsidian";
        Port = config.services.couchdb.port;
        Tags = ["public"];
        Meta = {
          domain = "obsidian.infra.ayats.org";
        };
        Check = {
          Name = "systemd";
          Args = ["systemctl" "is-active" "couchdb.service"];
          Interval = "5m";
        };
      }} http://localhost:8500/v1/agent/service/register
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 700 ${user} ${group} - -"
  ];
}
