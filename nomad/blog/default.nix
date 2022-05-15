{...}: {
  services.nginx.virtualHosts."ayats.org" = {
    useACMEHost = "ayats.org";
    forceSSL = true;
    locations = {
      "/" = {
        proxyPass = "http://localhost:8002";
      };
    };
  };
}
