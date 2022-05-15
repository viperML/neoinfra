{...}: {
  services.nginx.virtualHosts."nix.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "~ /(.+)" = {
        proxyPass = "http://localhost:8001";
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
