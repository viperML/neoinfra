{ pkgs, config, ... }:
{
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
  };

  systemd.services.caddy = rec {
    after = [ "tailscaled-regen-authkey.service" ];
    wants = after;
  };

  assertions = [
    {
      assertion = config.services.tailscale.enable;
      message = "caddy-tailscale relies on tailscale";
    }
  ];
}
