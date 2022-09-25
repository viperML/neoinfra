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
        flake_ref = "nixpkgs/${var.nixpkgs_rev}#miniserve"
        flake_sha = var.nixpkgs_narHash
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

variable "nixpkgs_rev" {
  type = string
  validation {
    condition     = var.nixpkgs_rev != "null"
    error_message = "Git tree is dirty."
  }
}

variable "nixpkgs_narHash" {
  type = string
}
