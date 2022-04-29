{...}: let
  inherit (builtins) toString;
  cache-port = 5000;
in {
  # TODO sign packages
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

  services.nginx.virtualHosts."nix.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      root = "/nix/store";
      extraConfig = ''
        autoindex off;
      '';
    };
    locations."~ /(.+)" = {
      root = "/nix/store";
      extraConfig = ''
        autoindex on;
      '';
    };
  };
}
