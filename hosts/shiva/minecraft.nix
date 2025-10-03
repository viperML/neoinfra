{ pkgs, ... }:
let

  json = pkgs.formats.json { };
in
{
  virtualisation.oci-containers.containers.minecraft = {
    image = "itzg/minecraft-server";
    volumes = [
      "minecraft:/data"
      "${
        json.generate "config.yaml" {
          host = "0.0.0.0";
          port = 25566;
          enable_metrics = {
            entities_total = true;
            villagers_total = true;
            loaded_chunks_total = true;
            jvm_memory = true;
            players_online_total = true;
            players_total = true;
            tps = true;
            jvm_threads = true;
            jvm_gc = true;
            tick_duration_median = true;
            tick_duration_average = true;
            tick_duration_min = false;
            tick_duration_max = true;
            player_online = false;
            player_statistic = false;
          };
        }
      }:/data/plugins/PrometheusExporter/config.yml:ro"
    ];
    ports = [
      "25565:25565/tcp"
      "25575:25575/udp"
      "25566:25566/tcp" # prometheus exporter
    ];
    environment = {
      EULA = "TRUE";
      TYPE = "PAPER";
      MEMORY = "4G";
      MOTD = "tonto el que lo lea";
      DIFFICULTY = "hard";
      MAX_PLAYERS = "100";
      ALLOW_FLIGHT = "TRUE";
      RCON_PASSWORD = "rcon";
      # https://www.spigotmc.org/resources/simple-tpa.64270
      # https://www.spigotmc.org/resources/sleepfixer-one-player-sleep.76746/
      # https://www.spigotmc.org/resources/prometheus-exporter.36618/
      SPIGET_RESOURCES = "64270,76746,36618";
      # MINECRAFT_PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
      # MINECRAFT_PROMETHEUS_EXPORTER_PORT = "25566";
    };
  };
}
