variables {
  state_mountpoint = "/state"
}

job "obsidian-backup" {
  datacenters = ["dc1"]

  type = "batch"

  periodic {
    cron             = "00 03 * * *"
    prohibit_overlap = true
    time_zone        = "Europe/Berlin"
  }

  group "main" {
    count = 1

    volume "nix" {
      type      = "host"
      source    = "nix"
      read_only = true
    }

    task "build" {
      driver = "exec"
      env {
        HOME       = "${NOMAD_TASK_DIR}"
        NIX_REMOTE = "daemon"
      }
      config {
        command = "/bin/sh"
        args = ["-c", <<-EOH
            set -ex
            nix profile install \
              --tarball-ttl 300 \
              --profile "${NOMAD_ALLOC_DIR}/profile" \
              --print-build-logs \
              nixpkgs#rclone^out

            nix profile install \
              --tarball-ttl 300 \
              --profile "${NOMAD_ALLOC_DIR}/profile" \
              --print-build-logs \
              nixpkgs#rustic-rs^out
          EOH
        ]
      }
      volume_mount {
        volume      = "nix"
        destination = "/nix"
      }
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
    }

    task "run" {
      driver = "docker"
      config {
        network_mode = "host"
        image        = "debian"
        command      = "/bin/sh"
        args = ["-c", <<-EOH
            set -ex
            printenv
            cd "${NOMAD_TASK_DIR}"
            cat $SSL_CERT_FILE | wc -l

            export PATH="${NOMAD_ALLOC_DIR}/profile/bin:$(printenv PATH)"

            rclone ls obsidian:obsidian -vv

            set +e
            rustic init || :
            set -e

            rustic backup
          EOH
        ]
        mount {
          type   = "volume"
          source = "nomad-obsidian"
          target = var.state_mountpoint
          volume_options {
            labels {
              backup = "obsidian"
            }
          }
        }
        volumes = [
          "/etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-bundle.crt"
        ]
      }
      env {
        HOME              = "${NOMAD_TASK_DIR}"
        NIX_REMOTE        = "daemon"
        RCLONE_CONFIG     = "${NOMAD_TASK_DIR}/rclone.conf"
        RUSTIC_REPOSITORY = "rclone:obsidian:obsidian"
        SSL_CERT_FILE     = "/etc/ssl/certs/ca-bundle.crt"
      }
      volume_mount {
        volume      = "nix"
        destination = "/nix"
      }
      template {
        destination = "local/rclone.conf"
        data        = <<-EOF
          [obsidian]
          type = s3
          provider = Cloudflare
          env_auth = true
          acl = private
          no_check_bucket = true
        EOF
      }
      template {
        destination = "local/rustic.toml"
        data        = <<-EOF
          [forget]
          keep-daily = 14
          keep-weekly = 5
          [[backup.sources]]
          source = "${var.state_mountpoint}"
        EOF
      }
      vault {
        policies = ["nomad-obsidian"]
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env"
        env         = true
        data        = <<-EOF
          {{ with secret "kv/data/obsidian" }}
          AWS_ACCESS_KEY_ID={{ .Data.data.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY={{ .Data.data.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION={{ .Data.data.AWS_DEFAULT_REGION }}
          RCLONE_S3_ENDPOINT={{ .Data.data.RCLONE_S3_ENDPOINT }}
          RUSTIC_PASSWORD={{ .Data.data.RUSTIC_PASSWORD }}
          {{ end }}
        EOF
      }
    }
  }
}

