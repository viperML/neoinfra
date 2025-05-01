{ pkgs, config, ... }:
let
  stateDir = "/run/nginx-consul";
  configPath = "${stateDir}/nginx-consul.conf";

  # Copied from the Nginx module
  recommendedProxyConfig = pkgs.writeText "nginx-recommended-proxy-headers.conf" ''
    proxy_set_header        Host $host;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        X-Forwarded-Host $host;
    proxy_set_header        X-Forwarded-Server $host;
  '';

  certs = config.security.acme.certs."wildcard.ayats.org";

  serverName = "shiva.ayats.org";

  user = config.systemd.services."nginx".serviceConfig.User;
  group = config.systemd.services."nginx".serviceConfig.Group;
in
{
  # Generated sample
  # services.nginx.virtualHosts = {
  #   "shiva.ayats.org" = {
  #     enableACME = false;
  #     useACMEHost = "wildcard.ayats.org";
  #     forceSSL = true;
  #     locations = {
  #       "/".proxyPass = "http://127.0.0.1:8080/";
  #     };
  #   };
  # };

  services.nginx.appendHttpConfig = ''
    include ${configPath} ;
  '';

  systemd.services."nginx" = {
    after = [ "consul-template-nginx.service" ];
  };

  services.consul-template.instances."nginx" = {
    # inherit user group;
    settings = {
      template = [
        {
          exec = [
            {
              command = "${pkgs.systemdMinimal}/bin/systemctl reload nginx.service";
            }
          ];
          inherit user group;
          destination = configPath;
          contents = ''
            # consul-template config: dynamically generate a server for each consul service with tag "shiva"
            server {
                listen 0.0.0.0:80 ;
                listen [::0]:80 ;
                server_name ${serverName} ;
                location / {
                    return 301 https://$host$request_uri;
                }
            }

            server {
                listen 0.0.0.0:443 ssl ;
                listen [::0]:443 ssl ;
                server_name ${serverName} ;
                http2 on;
                ssl_certificate ${certs.directory}/fullchain.pem;
                ssl_certificate_key ${certs.directory}/key.pem;
                ssl_trusted_certificate ${certs.directory}/chain.pem;

                {{ range services }}
                # Service {{ .Name }}
                {{ if (contains "shiva" .Tags) }}
                {{ range service .Name }}
                {{- $location := (index .ServiceMeta "location") -}}
                {{- if (and $location (regexMatch "^/[a-zA-Z0-9._-]+$" $location)) -}}
                location ~ ^{{ $location }}(/|$) {
                    proxy_pass http://{{ .Address }}:{{ .Port }};
                    include ${recommendedProxyConfig};
                }
                {{- else if $location -}}
                # location: {{ $location }}
                {{- end -}}
                {{ end }}
                {{ end }}
                {{ end }}

                # location / {
                #     proxy_pass http://127.0.0.1:8080/;
                #     include ${recommendedProxyConfig} ;
                # }
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
