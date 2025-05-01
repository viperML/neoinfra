job "hello-nginx" {
  datacenters = ["dc1"]

  group "hello" {
    network {
      port "http" {
        to = 80
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginxdemos/hello"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64
      }

      service {
        tags     = ["shiva"]
        provider = "consul"
        port     = "http"

        meta {
          location = "/test"
        }
        # check {
        #   name     = "nginx-http"
        #   type     = "http"
        #   path     = "/test2"
        #   interval = "10s"
        #   timeout  = "2s"
        # }
      }
    }
  }
}
