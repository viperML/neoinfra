{
  pkgs,
  lib,
  config,
  ...
}:
let
  stateDir = "/run/nginx-dynamic";
  configPath = "${stateDir}/nginx.conf";
  user = "nginx-dynamic";
  group = "nginx-dynamic";

  cfg = config.neoinfra.nginx-dynamic;
in
{
  options = {
    neoinfra.nginx-dynamic = {
      enable = (lib.mkEnableOption "Nginx with dynamic config from Consul") // {
        default = true;
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 9090;
        description = "The port on which Nginx listens";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."nginx-dynamic" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "consul.service" ];
      requires = [ "consul-template-nginx-dynamic.service" ];

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.nginx} -c ${configPath}";
        User = user;
        Group = group;
        ReadWritePaths = [
          stateDir
        ];
        Restart = "on-failure";
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectHome = true;
      };
    };

    systemd.services."nginx-dynamic-restart" = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl try-restart nginx-dynamic.service";
      };
    };

    systemd.paths."nginx-dynamic-config" = {
      wantedBy = [ "paths.target" ];
      pathConfig = {
        Unit = "nginx-dynamic-restart.service";
        PathModified = configPath;
      };
    };

    users.users.${user} = {
      group = group;
      home = stateDir;
      isSystemUser = true;
    };

    users.groups.${group} = {
    };

    services.consul-template.instances."nginx-dynamic" = {
      inherit user group;
      settings = {
        template = [
          {
            # exec = [
            #   {
            #     command = pkgs.writeShellScript "nginx-reload" ''
            #       set -x
            #       exec ${pkgs.coreutils}/bin/kill -s HUP $(<${stateDir}/nginx.pid)
            #     '';
            #   }
            # ];
            inherit user group;
            destination = configPath;
            contents = ''
              daemon off;
              error_log ${stateDir}/error.log;
              pid ${stateDir}/nginx.pid;
              events { }

              http {
                access_log ${stateDir}/access.log;
                server {
                  listen 9090;

                  {{ range services }}
                  # Service {{ .Name }}
                  {{ if (contains "shiva" .Tags) }}
                  {{ range service .Name }}
                  {{- $location := (index .ServiceMeta "location") -}}
                  {{- if (and $location (regexMatch "^/[a-zA-Z0-9._-]+$" $location)) -}}
                  location ~ ^{{ $location }}(/|$) {
                      proxy_pass http://{{ .Address }}:{{ .Port }};
                  }
                  {{- else if $location -}}
                  # location: {{ $location }}
                  {{- end -}}
                  {{ end }}
                  {{ end }}
                  {{ end }}

                  location / {
                    # Return Hello
                    return 200 "Hello from nginx-dynamic";
                  }
                }
              }
            '';
          }
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0700 ${user} ${group} - -"
    ];
  };

}
