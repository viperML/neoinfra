job "http-store" {
  datacenters = ["dc1"]
  group "main-group" {
    count = 1
    network {
      mode = "bridge"
      port "http" {
        static = 8001
        to     = 8080
      }
    }

    task "miniserve" {
      driver = "containerd-driver"

      config {
        flake_ref = "nixpkgs/a3917caedfead19f853aa5769de4c3ea4e4db584#miniserve"
        flake_sha = "sha256-NcJnbGDBBN023x8s3ll3HZxBcQoPq1ry9E2sjg+4flc="
        entrypoint = [
          "bin/miniserve",
          "/nix/store",
          "--enable-tar-gz",
          "--hide-version-footer",
          "--show-symlink-info",
          "--hidden",
        ]
        mounts = [
          {
            type    = "bind"
            target  = "/nix/store"
            source  = "/nix/store"
            options = ["rbind", "ro"]
          }
        ]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
