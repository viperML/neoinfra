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
        EULA        = "TRUE"
        TYPE        = "PAPER"
        SERVER_HOST = "0.0.0.0"
      }

      service {
        name = "minecraft"
        port = "minecraft"
      }
    }
  }
}
