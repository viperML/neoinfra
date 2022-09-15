{...}: let
  minecraftPort = 25565;
in {
  virtualisation.oci-containers.containers."minecraft-aof" = {
    image = "ghcr.io/viperml/minecraft-serverstarter-docker:v2.0.0";
    ports = [
      "${toString minecraftPort}:${toString minecraftPort}"
    ];
    volumes = [
      "wuselcraft01:/srv/minecraft"
      "${./wuselcraft-create-edition.yaml}:/srv/minecraft-vendor/server-setup-config.yaml"
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
