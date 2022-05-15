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
        extraConfig = ''
          add_header Content-Type text/plain;
        '';
      };
    };
  };

  /*
   # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html
   containers.http-store = {
     config = _: {
       networking.firewall.allowedTCPPorts = [80];
       services.nginx = {
         enable = true;
         additionalModules = [pkgs.nginxModules.fancyindex];
         virtualHosts."localhost".locations = {
           "~ /(.+)-(.+)" = {
             root = "/nix/store";
             extraConfig = ''
               fancyindex on;
               fancyindex_exact_size off;
               fancyindex_header "${lib.removePrefix "/nix/store" nginx-theme.outPath}/header.html";
               fancyindex_footer "${lib.removePrefix "/nix/store" nginx-theme.outPath}/footer.html";
               fancyindex_show_path off;
               fancyindex_name_length 255;
               fancyindex_time_format "-";
               fancyindex_default_sort name;
               fancyindex_directories_first on;
             '';
           };
         };
       };
     };
     privateNetwork = true;
     hostAddress = "192.168.100.2";
     localAddress = http-store-ip;
     autoStart = true;
     ephemeral = true;
     extraFlags = ["-U"];
   };

   };
   */
}
