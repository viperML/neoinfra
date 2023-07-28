job "demo" {
  datacenters = ["dc1"]

  group "main" {
    count = 1

    network {
      port "http" { to = "8080" }
    }

    service {
      port = "http"
      tags = ["public"]
      meta {
        domain = "demo.ayats.org"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "pmorjan/demo"
        ports = ["http"]
      }
    }
  }
}

