{
  networking.firewall = {
    allowedUDPPorts = [ 34197 ];
    # allowedTCPPorts = [ 27015 ];
  };

  virtualisation.oci-containers.containers.factorio = {
    image = "factoriotools/factorio:stable";
    ports = [
      "34197:34197/udp"
      "27015:27015"
    ];
    volumes = [
      "factorio:/factorio"
    ];
  };
}
