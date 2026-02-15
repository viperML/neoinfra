job "factorio" {
  datacenters = ["dc1"]

  group "factorio-server" {
    count = 1

    network {
      port "game" {
        static = 34197
        to     = 34197
      }

      port "rcon" {
        static = 27015
        to     = 27015
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "25s"
      mode     = "fail"
    }

    task "factorio" {
      driver = "docker"

      config {
        image = "docker.io/factoriotools/factorio:latest"
        ports = ["game", "rcon"]
        mounts = [
          {
            type   = "volume"
            target = "/factorio"
            source = "factorio-data"
          }
        ]
        network_mode = "host"
      }

      env {
        GENERATE_NEW_SAVE = "true"
        SAVE_NAME         = "main-deathworld"
        PRESET            = "death-world"
      }

      resources {
        cpu    = 4000 # 2 CPU
        memory = 4096 # 4GB
      }

      service {
        name = "factorio"
        port = "game"

        tags = [
          "game",
          "factorio",
          "udp"
        ]

        check {
          type     = "tcp"
          port     = "rcon"
          interval = "30s"
          timeout  = "5s"
        }
      }

      logs {
        max_files     = 5
        max_file_size = 10 # MB
      }
    }
  }
}
