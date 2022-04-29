{...}: let
  inherit (builtins) toString;
  nar-port = 8383;
  cache-port = 5000;
in {
  services.nar-serve = {
    enable = true;
    port = nar-port;
    cacheURL = "http://localhost:${toString cache-port}";
  };

  services.nix-serve = {
    enable = true;
    bindAddress = "localhost";
    port = cache-port;
  };

  services.nginx.virtualHosts."cache.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString cache-port}";
    };
  };

  services.nginx.virtualHosts."nar.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString nar-port}";
    };
  };
}
