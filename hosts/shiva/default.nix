let
  sources = import ../../npins;
in
import ../. {
  system = "aarch64-linux";
  modules = [
    ./configuration.nix
    "${sources.sops-nix}/modules/sops"
    ../../modules/oci-lustrate-oracle9
    ../../modules/login-classic.nix
    ../../modules/tailscale
    ../../modules/caddy-tailscale.nix

    ../../modules/login-ayats.nix
    ../../modules/docker

    ./caddy.nix

    ../../modules/consul/node.nix

    ./grafana.nix

    ../../modules/nomad/node.nix
    ../../modules/consul/nginx.nix
    ./minecraft.nix
  ];
}
