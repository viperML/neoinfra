{
  pkgs,
  config,
  ...
}: let
  inherit (builtins) toString;
  cache-port = 5000;
  # http-store-port = 5444;
in {
  sops.secrets."cache_priv_key" = {
    restartUnits = ["nix-serve"];
  };

  services.nix-serve = {
    enable = true;
    port = cache-port;
    secretKeyFile = config.sops.secrets."cache_priv_key".path;
  };

  services.nginx.virtualHosts."cache.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://localhost:${toString cache-port}";
      };
      "/robots.txt" = {
        return = ''200 "User-agent: *\nDisallow: /\n"'';
        # TODO
        # extraConfig = ''
        #   add_header Content-Type text/plain;
        # '';
      };
    };
  };
}
