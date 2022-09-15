{...}: let
  minecraftPort = 25565;
  name = "wuselcraft-create-edition";
in {
  virtualisation.oci-containers.containers."minecraft-${name}" = {
    image = "ghcr.io/viperml/minecraft-serverstarter-docker:v2.0.0";
    ports = [
      "${toString minecraftPort}:${toString minecraftPort}"
    ];
    volumes = [
      "${name}:/srv/minecraft"
      "${./. + "/${name}.yaml"}:/srv/minecraft-vendor/server-setup-config.yaml"
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
