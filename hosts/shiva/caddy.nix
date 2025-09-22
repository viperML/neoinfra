{ config, pkgs, ... }:
let
  inherit (config.networking) hostName;
  tailNet = "vulture-ratio.ts.net";
in
{
  services.consul.webUi = true;

  services.tailscale.permitCertUid = "caddy";

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    enableReload = false;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/tailscale/caddy-tailscale@v0.0.0-20250915161136-32b202f0a953"
      ];
      hash = "sha256-sakFvjkN0nwNBbL2wxjtlRlKmryu9akurTtM2309spg=";
    };

    environmentFile = "/var/lib/tailscale/auth-key.env";

    logFormat = "level WARN";

    virtualHosts."${hostName}.${tailNet}".extraConfig = ''
      handle {
        reverse_proxy localhost:${toString config.services.homepage-dashboard.listenPort}
      }
    '';

    virtualHosts."consul.${tailNet}".extraConfig = ''
      bind tailscale/consul
      handle {
        reverse_proxy localhost:8500
      }
    '';

    virtualHosts."nomad.${tailNet}".extraConfig = ''
      bind tailscale/nomad
      handle {
        reverse_proxy localhost:4646
      }
    '';

    virtualHosts."${hostName}1.${tailNet}".extraConfig = ''
      log {
        level DEBUG
      }
      bind tailscale/${hostName}1
      handle {
        reverse_proxy localhost:${toString config.neoinfra.nginx-dynamic.port}
      }
    '';

    virtualHosts."${hostName}.ayats.org".extraConfig = ''
      handle {
        reverse_proxy localhost:${toString config.neoinfra.nginx-dynamic.port}
      }
    '';
  };

  systemd.services.caddy = rec {
    after = [ "tailscaled-regen-authkey.service" ];
    wants = after;
  };

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "shiva.vulture-ratio.ts.net";
    services = [
      {
        "Main Group" = [
          {
            "Caddy" = {
              widgets = [
                {
                  type = "caddy";
                  url = "http://localhost:2019";
                }
              ];
            };
          }
          {
            "Consul" = {
              href = "https://consul.vulture-ratio.ts.net";
              icon = "si-consul-#e03875";
            };
          }
          {
            "Grafana" = {
              href = "https://ts-grafana.vulture-ratio.ts.net";
              icon = "si-grafana-#f58b1b";
            };
          }
          {
            "Prometheus" = {
              href = "https://ts-prometheus.vulture-ratio.ts.net";
              icon = "si-prometheus-#e64a22";
            };
          }
          {
            "Nomad" = {
              href = "https://nomad.vulture-ratio.ts.net";
              icon = "si-nomad-#1d9467";
            };
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/.oldroot";
          uptime = true;
          units = "metric";
        };
      }
    ];
  };
}
