{...}: {
  services.nginx.virtualHosts."ayats.org" = {
    default = true;
    useACMEHost = "ayats.org";
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://localhost:8002";
      };
    };
  };
}
