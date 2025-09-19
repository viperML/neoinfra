let
  port = 2342;
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
        domain = "grafana.vulture-ratio.ts.net";
        http_addr = "127.0.0.1";
        http_port = port;
      };
    };
  };

  services.caddy.virtualHosts."grafana.vulture-ratio.ts.net".extraConfig = ''
    bind tailscale/grafana
    handle {
      reverse_proxy localhost:${toString port}
    }
  '';
}
