job "pixel-tracker" {
  datacenters = ["dc1"]
  type        = "service"

  group "main" {
    count = 1
    restart {
      attempts = 0
    }

    network {
      port "http" {}
    }

    volume "nix" {
      type      = "host"
      source    = "nix"
      read_only = true
    }

    service {
      port = "http"
      tags = ["public"]
      meta {
        domain = "pt.infra.ayats.org"
      }
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
            printenv
            nix build \
              --out-link ${NOMAD_ALLOC_DIR}/result \
              --tarball-ttl 300 \
              --print-build-logs \
              --override-input nixpkgs nixpkgs \
              github:viperML/pixel-tracker^out
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
        command = "${NOMAD_ALLOC_DIR}/result/bin/pixel-tracker"
        args = [
          "--listen",
          "0.0.0.0:${NOMAD_PORT_http}",
          "--url",
          "https://pt.infra.ayats.org/pt"
        ]
        ports = ["http"]
      }

      volume_mount {
        volume      = "nix"
        destination = "/nix"
      }

      vault {
        policies = ["nomad-pixel-tracker"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env"
        env         = true
        data        = <<EOF
          {{ with secret "kv/data/pixel-tracker" }}
          KEY={{ .Data.data.KEY }}
          {{ end }}
          EOF
      }
    }
  }
}
