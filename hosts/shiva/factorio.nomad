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

    volume "factorio-data" {
      type      = "host"
      source    = "factorio-data"
      read_only = false
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "25s"
      mode     = "fail"
    }

    task "factorio" {
      driver = "docker"

      volume_mount {
        volume      = "factorio-data"
        destination = "/factorio"
        read_only   = false
      }

      config {
        image = "docker.io/factoriotools/factorio:stable"
        ports = ["game", "rcon"]
      }

      env {
        GENERATE_NEW_SAVE = "true"
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
