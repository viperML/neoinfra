job "demo-nix" {
  datacenters = ["dc1"]
  type        = "batch"

  group "main" {
    count = 1
    restart {
      attempts = 0
    }

    volume "nix" {
      type      = "host"
      source    = "nix"
      read_only = true
    }

    task "build" {
      driver = "exec"
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
      restart {
        attempts = 0
      }
      env {
        HOME       = "${NOMAD_TASK_DIR}"
        NIX_REMOTE = "daemon"
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<-EOH
            set -x
            nix build \
              --out-link ${NOMAD_ALLOC_DIR}/result \
              --tarball-ttl 300 \
              --print-build-logs \
              nixpkgs#coreutils^out
          EOH
        ]
      }
      volume_mount {
        volume      = "nix"
        destination = "/nix"
      }
    }

    task "run" {
      driver = "docker"
      config {
        image   = "busybox"
        command = "${NOMAD_ALLOC_DIR}/result/bin/ls"
        args    = ["--help"]
      }
      volume_mount {
        volume      = "nix"
        destination = "/nix"
      }
    }
  }
}
