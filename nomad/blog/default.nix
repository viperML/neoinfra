{...}: {
  services.nginx.virtualHosts."ayats.org" = {
    default = true;
    enableACME = true;
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://localhost:8002";
      };
    };
  };
}
