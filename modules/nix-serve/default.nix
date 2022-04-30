{pkgs, ...}: let
  inherit (builtins) toString;
  cache-port = 5000;
  # http-store-port = 5444;
  cache-ip = "192.168.100.33";
  http-store-ip = "192.168.100.22";
in {
  # https://blog.beardhatcode.be/2020/12/Declarative-Nixos-Containers.html
  containers.nix-serve = {
    config = _: {
      networking.firewall.allowedTCPPorts = [cache-port];
      services.nix-serve = {
        enable = true;
        port = cache-port;
      };
    };
    privateNetwork = true;
    hostAddress = "192.168.100.2";
    localAddress = cache-ip;
    autoStart = true;
    ephemeral = true;
    extraFlags = ["-U"];
  };

  services.nginx.virtualHosts."cache.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://${cache-ip}:${toString cache-port}";
      };
      "/robots.txt" = {
        return = ''200 "User-agent: *\nDisallow: /\n"'';
        extraConfig = ''
          add_header Content-Type text/plain;
        '';
      };
    };
  };

  containers.http-store = {
    config = _: {
      networking.firewall.allowedTCPPorts = [80];
      services.nginx = {
        enable = true;
        virtualHosts."localhost".locations."~ /(.+)-(.+)" = {
          root = "/nix/store";
          extraConfig = ''
            autoindex on;
          '';
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

  services.nginx.virtualHosts."nix.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://${http-store-ip}:80";
      };
      "/robots.txt" = {
        return = ''200 "User-agent: *\nDisallow: /\n"'';
        extraConfig = ''
          add_header Content-Type text/plain;
        '';
      };
    };
  };
}
