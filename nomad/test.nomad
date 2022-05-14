# https://www.nomadproject.io/docs/job-specification
# https://learn.hashicorp.com/tutorials/nomad/jobs-submit
job "python_server3" {
  datacenters = ["dc1"]
  // type        = "service"

  group "mygroup" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        static = 8080
        to     = 8080
      }
    }

    task "mytask" {
      driver = "containerd-driver"

      config {
        flake_ref  = "git+https://github.com/viperML/home#serve"
        flake_sha  = "sha256-IW7Tvwuw2tvDdbAmFY37y57KZvEuaE8TXuEs2vJysi0="
        entrypoint = ["bin/serve"]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
