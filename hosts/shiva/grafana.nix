{ config, ... }:
let
  grafanaPort = 2342;
  prometheusPort = 9095;
  prometheusNodePort = 9096;
in
{
  services.grafana = {
    enable = true;
    settings = {
      "auth.anonymous" = {
        enabled = true;
        org_role = "Admin";
        org_name = "Main Org.";
      };
      server = {
        domain = "ts-grafana.vulture-ratio.ts.net";
        http_addr = "127.0.0.1";
        http_port = grafanaPort;
      };
    };
  };

  services.caddy.virtualHosts."ts-grafana.vulture-ratio.ts.net".extraConfig = ''
    bind tailscale/ts-grafana
    handle {
      reverse_proxy localhost:${toString grafanaPort}
    }
  '';

  services.prometheus = {
    enable = true;
    port = prometheusPort;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = prometheusNodePort;
      };
    };

    scrapeConfigs = [
      {
        job_name = config.networking.hostName;
        static_configs = [
          {
            targets = [ "localhost:${toString prometheusNodePort}" ];
          }
        ];
      }
      {
        job_name = "nomad";
        static_configs = [
          {
            targets = [ "localhost:4646" ];
          }
        ];
        metrics_path = "/v1/metrics";
        params = {
          format = [ "prometheus" ];
        };
      }
      {
        job_name = "minecraft";
        static_configs = [
          {
            targets = [ "localhost:25566" ];
          }
        ];
      }
    ];

  };

  services.caddy.virtualHosts."ts-prometheus.vulture-ratio.ts.net".extraConfig = ''
    bind tailscale/ts-prometheus
    handle {
      reverse_proxy localhost:${toString prometheusPort}
    }
  '';
}
