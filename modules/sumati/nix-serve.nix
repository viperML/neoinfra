{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) toString;
  cache-port = 5000;
  # http-store-port = 5444;
  cache-ip = "192.168.100.33";
  http-store-ip = "192.168.100.22";

  nginx-theme = with pkgs;
    stdenv.mkDerivation {
      pname = "nginx-fancyindex-flat-theme";
      version = "1.1";

      dontBuild = true;

      src = fetchzip {
        url = "https://github.com/alehaa/nginx-fancyindex-flat-theme/releases/download/v1.1/nginx-fancyindex-flat-theme-1.1.tar.gz";
        sha256 = "sha256-eT3D9hPlts3S+bzsGYz8KCNmaDcrPiiCRzVJLq8PDlA=";
      };

      installPhase = ''
        cp -r $src $out
      '';
    };
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
