job "demo-nix" {
  datacenters = ["dc1"]
  type        = "batch"

  group "main" {
    count = 1
    restart {
      attempts = 0
    }

    task "build" {
      driver = "raw_exec"
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
      restart {
        attempts = 0
      }
      env {
        HOME = "/root"
      }
      config {
        command = "nix"
        args    = ["build", "nixpkgs#gitoxide^out", "-L", "--profile", "/var/lib/nomad/nix/${NOMAD_JOB_NAME}"]
      }
    }

    // task "run" {
    //   driver = "docker"
    //   config {
    //     image   = "busybox"
    //     command = "/nix/nomad/${NOMAD_JOB_NAME}/bin/gix"
    //     args    = ["--help"]
    //     mount {
    //       type     = "bind"
    //       target   = "/nix/store"
    //       source   = "/nix/store"
    //       readonly = true
    //       bind_options {
    //         propagation = "rshared"
    //       }
    //     }
    //     mount {
    //       type     = "bind"
    //       target   = "/nix/nomad"
    //       source   = "/var/lib/nomad/nix"
    //       readonly = true
    //       bind_options {
    //         propagation = "rshared"
    //       }
    //     }
    //   }
    // }

    task "run" {
      driver = "podman"
      config {
        image   = "busybox"
        command = "/nix/nomad/${NOMAD_JOB_NAME}/bin/gix"
        args    = ["--help"]
        volumes = [
          "/nix/store:/nix/store:ro",
          "/var/lib/nomad/nix:/nix/nomad:ro"
        ]
      }
    }
  }
}
