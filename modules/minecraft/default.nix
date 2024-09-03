{
  config,
  lib,
  ...
}: let
  sopsFile = ../../secrets/shiva.yaml;
  dataPath = "/var/lib/minecraft";
  minecraftPort' = 25565;
  minecraftPort = toString minecraftPort';
  voicechatPort' = 24454;
  voicechatPort = toString 24454;
in {
  networking.firewall = {
    allowedTCPPorts = [
      minecraftPort'
    ];
    allowedUDPPorts = [
      voicechatPort'
    ];
  };

  sops.secrets = {
    minecraft_env = {
      inherit sopsFile;
    };
  };

  virtualisation.oci-containers.containers."minecraft" = {
    image = "itzg/minecraft-server";
    ports = [
      "${minecraftPort}:${minecraftPort}"
      "${voicechatPort}:${voicechatPort}"
    ];
    environment = {
      EULA = "true";
      MOD_PLATFORM = "AUTO_CURSEFORGE";
      MEMORY = "6G";
      CF_PAGE_URL = "https://www.curseforge.com/minecraft/modpacks/all-the-mods-9-no-frills";
      DIFFICULTY = "hard";
      OPS = "viperML";
      ALLOW_FLIGHT = "TRUE";
      MOTD = "Modpack: All the Mods 9 - No frills";
      CURSEFORGE_FILES = lib.concatStringsSep "," [
        "https://www.curseforge.com/minecraft/mc-mods/simple-voice-chat/files/5676800"
      ];
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

  services.nginx.virtualHosts."mc.ayats.org" = {
    enableACME = false;
    useACMEHost = "wildcard.ayats.org";
    forceSSL = true;
    locations = {
      "/robots.txt".extraConfig = ''
        return 200 "User-agent: *\nDisallow: /";
        add_header Content-Type text/html;
      '';
      "/".root = ./.;
    };
  };

  systemd.services."${config.virtualisation.oci-containers.backend}-minecraft" = {
    serviceConfig = {
      RuntimeMaxSec = "6h";
      Restart = "always";
    };
  };
}
