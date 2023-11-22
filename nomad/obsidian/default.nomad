job "obsidian" {
  datacenters = ["dc1"]

  group "main" {
    count = 1
    restart {
      attempts = 0
    }

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
            set -x
            nix build \
              --out-link ${NOMAD_ALLOC_DIR}/result \
              --tarball-ttl 300 \
              --print-build-logs \
              nixpkgs#couchdb3^out

              touch ${NOMAD_ALLOC_DIR}/couchdb.log
              touch ${NOMAD_ALLOC_DIR}/.erlang.cookie
              chmod 600 ${NOMAD_ALLOC_DIR}/.erlang.cookie
              dd if=/dev/random bs=16 count=1 | base64 > ${NOMAD_ALLOC_DIR}/.erlang.cookie
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
      restart {
        attempts = 0
      }
    }

    task "run" {
      driver = "docker"
      restart {
        attempts = 0
      }
      config {
        image   = "busybox"
        command = "${NOMAD_ALLOC_DIR}/result/bin/couchdb"
        // command = "/bin/sh"
        // args = ["-c", <<-EOH
        //     set -x
        //     env
        //     cat ${NOMAD_ALLOC_DIR}/result/etc/default.ini ${NOMAD_TASK_DIR}/config.ini ${NOMAD_SECRETS_DIR}/admin.ini
        //     ${NOMAD_ALLOC_DIR}/result/bin/couchdb
        //   EOH
        // ]
      }
      env {
        ERL_FLAGS = "-couch_ini ${NOMAD_ALLOC_DIR}/result/etc/default.ini ${NOMAD_TASK_DIR}/config.ini ${NOMAD_TASK_DIR}/nomad.ini ${NOMAD_SECRETS_DIR}/admin.ini"
        HOME      = "${NOMAD_ALLOC_DIR}"
      }
      volume_mount {
        volume      = "nix"
        destination = "/nix"
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
      template {
        destination = "local/nomad.ini"
        data        = <<-EOH
          [couchdb]
          database_dir={{ env "NOMAD_ALLOC_DIR" }}
          uri_file={{ env "NOMAD_ALLOC_DIR" }}/couchdb.uri
          view_index_dir={{ env "NOMAD_ALLOC_DIR" }}
          [log]
          file={{ env "NOMAD_ALLOC_DIR" }}/couchdb.log
        EOH
      }
      vault {
        policies = ["nomad-obsidian"]
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/admin.ini"
        env         = false
        data        = <<-EOF
          {{ with secret "kv/data/obsidian" }}
          [admins]
          {{ .Data.data.COUCHDB_USER }} = "{{ .Data.data.COUCHDB_PASSWORD }}"
          {{ end }}
        EOF
      }
    }
  }
}

