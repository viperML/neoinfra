{
  rootPath,
  config,
  ...
}: let
  obsidianPort = 5984;
in {
  sops.secrets."obsidian" = {
    sopsFile = rootPath + "/secrets/shiva-obsidian.yaml";
  };

  virtualisation.oci-containers.containers."obsidian-couchdb" = {
    image = "docker.io/couchdb";
    ports = ["${builtins.toString obsidianPort}:5984"];
    environmentFiles = [
      config.sops.secrets."obsidian".path
    ];
    volumes = [
      "${./config.ini}:/opt/couchdb/etc/local.ini"
      "obsidian:/var/lib/couchdb"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    obsidianPort
  ];
}
