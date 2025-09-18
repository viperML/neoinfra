{ config, pkgs, ... }:
{
  services.tailscale.permitCertUid = "caddy";

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/tailscale/caddy-tailscale@v0.0.0-20250915161136-32b202f0a953"
      ];
      hash = "sha256-sakFvjkN0nwNBbL2wxjtlRlKmryu9akurTtM2309spg=";
    };

    environmentFile = "/var/lib/tailscale/auth-key.env";

    logFormat = "level INFO";

    virtualHosts."shiva.vulture-ratio.ts.net".extraConfig = ''
      handle {
        reverse_proxy localhost:${toString config.services.homepage-dashboard.listenPort}
      }
    '';

    virtualHosts."consul.vulture-ratio.ts.net".extraConfig = ''
      bind tailscale/consul
      handle {
        reverse_proxy localhost:8500
      }
    '';
  };

  systemd.services.caddy = rec {
    after = [ "tailscale-regen-authkey.service" ];
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
