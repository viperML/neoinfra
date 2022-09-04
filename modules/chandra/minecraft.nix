{...}: let
  minecraftPort = 25565;
in {
  virtualisation.oci-containers.containers."minecraft-aof" = {
    image = "ghcr.io/viperml/aof-docker:v1.0.5";
    ports = [
      "${toString minecraftPort}:${toString minecraftPort}"
    ];
    volumes = [
      "aof_runtime:/srv/aof-runtime"
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      minecraftPort
    ];
    allowedUDPPorts = [
      minecraftPort
    ];
  };
}
