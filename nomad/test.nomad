# https://www.nomadproject.io/docs/job-specification
# https://learn.hashicorp.com/tutorials/nomad/jobs-submit
job "python_server" {
  datacenters = ["dc1"]
  type        = "service"

  group "mygroup" {
    count = 1
    volume "nix" {
      type      = "host"
      source    = "nix"
      read_only = false
    }
    task "mytask" {
      driver = "exec"
      volume_mount {
        volume      = "nix"
        destination = "/nix"
      }
      config {
        command = "nix"
        args    = ["run", "nixpkgs#python3", "--", "-m", "http.server", "8080"]
      }
    }
  }
}
