{
  config,
  pkgs,
  ...
}: let
  sopsFile = ../secrets/shiva.yaml;
  dataPath = "/var/lib/minecraft";
  minecraftPort' = 25565;
  minecraftPort = toString minecraftPort';
in {
  networking.firewall.allowedTCPPorts = [
    minecraftPort'
  ];

  sops.secrets = {
    minecraft_env = {
      inherit sopsFile;
    };
  };

  virtualisation.oci-containers.containers."minecraft" = {
    image = "itzg/minecraft-server";
    ports = ["${minecraftPort}:${minecraftPort}"];
    environment = {
      EULA = "true";
      MOD_PLATFORM = "AUTO_CURSEFORGE";
      MEMORY = "6G";
      CF_PAGE_URL = "https://www.curseforge.com/minecraft/modpacks/all-the-mods-9-no-frills";
    };
    environmentFiles = [
      config.sops.secrets.minecraft_env.path
    ];
    volumes = [
      "${dataPath}:/data"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${dataPath} 0755 root root - -"
  ];
}
