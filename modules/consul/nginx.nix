{
  pkgs,
  lib,
  ...
}:
let
  stateDir = "/run/nginx-dynamic";
  configPath = "${stateDir}/nginx.conf";
  user = "nginx-dynamic";
  group = "nginx-dynamic";
in
{
  systemd.services."nginx-dynamic" = {
    script = ''
      exec ${lib.getExe pkgs.nginx} -c ${configPath}
    '';

    serviceConfig = {
      User = user;
      Group = group;
      ReadWritePaths = [
        stateDir
      ];
      # StateDirectory = stateDir;
      # LogDirectory = stateDir;
      Restart = "on-failure";
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectHome = true;
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
          exec = [
            {
              command = pkgs.writeShellScript "nginx-reload" ''
                set -x
                exec ${pkgs.coreutils}/bin/kill -s HUP $(<${stateDir}/nginx.pid)
              '';
            }
          ];
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
    "d ${stateDir} 0755 ${user} ${group} - -"
  ];
}
