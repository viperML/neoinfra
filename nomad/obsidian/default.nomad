job "obsidian" {
  datacenters = ["dc1"]

  group "main" {
    count = 1

    network {
      port "db" { to = "5984" }
    }

    service {
      port = "db"
      tags = ["public"]
      meta {
        domain = "obsidian.infra.ayats.org"
      }
    }

    task "prepare" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      driver = "raw_exec"
      config {
        command = "/bin/sh"
        args    = ["-c", "printenv; mkdir -pv /var/lib/obsidian"]
      }
    }

    task "couchdb" {
      driver = "docker"

      config {
        image = "docker.io/library/couchdb:3"
        ports = ["db"]
        volumes = [
          "local/config.ini:/opt/couchdb/etc/local.d/config.ini",
        ]
        mount {
          type     = "bind"
          source   = "/var/lib/obsidian"
          target   = "/opt/couchdb/data"
          readonly = false
          bind_options = {
            propagation = "rshared"
          }
        }
      }

      template {
        destination = "local/config.ini"
        data        = <<-EOH
          [couchdb]
          single_node=true
          max_document_size = 50000000

          [chttpd]
          ;require_valid_user = true
          require_valid_user_except_for_up = true
          max_http_request_size = 4294967296

          [chttpd_auth]
          require_valid_user = true
          authentication_redirect = /_utils/session.html

          [httpd]
          WWW-Authenticate = Basic realm="couchdb"
          enable_cors = true

          [cors]
          origins = app://obsidian.md,capacitor://localhost,http://localhost
          credentials = true
          headers = accept, authorization, content-type, origin, referer
          methods = GET, PUT, POST, HEAD, DELETE
          max_age = 3600
        EOH
      }

      vault {
        policies = ["nomad-obsidian"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env"
        env         = true
        data        = <<EOF
          {{ with secret "kv/data/obsidian" }}
          COUCHDB_USER={{ .Data.data.COUCHDB_USER }}
          COUCHDB_PASSWORD={{ .Data.data.COUCHDB_PASSWORD }}
          {{ end }}
          EOF
      }
    }
  }
}

