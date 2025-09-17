{
  services.tailscale.permitCertUid = "caddy";

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;

    # virtualHosts."localhost".extraConfig = ''
    #   respond "Hello, world!"
    # '';

    # virtualHosts."shiva.vulture-ratio.ts.net".extraConfig = ''
    #   reverse_proxy 127.0.0.1:8080
    # '';
  };
}
