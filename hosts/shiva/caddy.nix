{ config, ... }:
{
  services.tailscale.permitCertUid = "caddy";

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;

    logFormat = "level INFO";

    virtualHosts."shiva.vulture-ratio.ts.net".extraConfig = ''
      route /consul* {
          uri strip_prefix /consul
          reverse_proxy localhost:8500 {
              rewrite /ui{path}
          }
      }

      handle {
        reverse_proxy localhost:${toString config.services.homepage-dashboard.listenPort}
      }
    '';
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
