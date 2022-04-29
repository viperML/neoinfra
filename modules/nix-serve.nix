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

  services.nginx.virtualHosts."nix.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      # "/" = {
      #   root = "/nix/store";
      #   extraConfig = ''
      #     autoindex off;
      #   '';
      # };
      "/robots.txt" = {
        return = ''200 "User-agent: *\nDisallow: /\n"'';
        extraConfig = ''
          add_header Content-Type text/plain;
        '';
      };
      "~ /(.+)-(.+)" = {
        root = "/nix/store";
        extraConfig = ''
          autoindex on;
        '';
      };
    };
  };
}
