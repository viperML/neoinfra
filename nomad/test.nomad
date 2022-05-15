# https://www.nomadproject.io/docs/job-specification
# https://learn.hashicorp.com/tutorials/nomad/jobs-submit
job "server4" {
  datacenters = ["dc1"]

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
        flake_ref  = "git+https://github.com/viperML/home?ref=bookworm#packages.x86_64-linux.serve"
        flake_sha  = "sha256-/EXw/7dMvWZC7ZnSMDCki1ViMJ5zE6uJaDt7S7Mukl0="
        entrypoint = ["bin/serve"]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
