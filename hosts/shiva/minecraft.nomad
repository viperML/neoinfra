job "minecraft" {
  datacenters = ["dc1"]

  group "group" {
    network {
      port "minecraft" {
        static = 25565
        to     = 25565
        # host_network = "lo"
      }

      port "minecraft-rcon" {
        static       = 25575
        to           = 25575
        host_network = "lo"
      }
    }
    task "main" {
      driver = "docker"

      resources {
        cpu    = 5000
        memory = 4096
      }

      config {
        image = "itzg/minecraft-server"
        ports = ["minecraft", "minecraft-rcon"]
        mounts = [
          {
            type   = "volume"
            target = "/data"
            source = "minecraft"
          }
        ]
      }

      env {
        EULA          = "TRUE"
        TYPE          = "PAPER"
        MEMORY        = "4G"
        MOTD          = "tonto el que lo lea"
        DIFFICULTY    = "hard"
        MAX_PLAYERS   = "100"
        ALLOW_FLIGHT  = "TRUE"
        RCON_PASSWORD = "rcon"
        # https://www.spigotmc.org/resources/simple-tpa.64270
        # https://www.spigotmc.org/resources/sleepfixer-one-player-sleep.76746/
        SPIGET_RESOURCES = "64270,76746"
      }

      service {
        name = "minecraft"
        port = "minecraft"
      }
    }
  }
}
