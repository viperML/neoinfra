{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.default
    ../oci-lustrate-oracle9

    ../login-classic.nix
    ../tailscale.nix

    inputs.nix-common.nixosModules.default

    #-- Services
    ../direnv.nix
    ../login-ayats.nix
    ./nginx.nix
    ../docker

    # ../obsidian
    ../consul/node.nix
    ../nomad/node.nix
    ../nomad/web.nix
    ../consul/nginx.nix

    # ../matrix
    # ../postgres

    # ../mail

    # ../rss.nix

    # ../slurm
    # ../minecraft
  ];

  # was broken
  services.envfs.enable = lib.mkForce false;

  documentation.enable = true;

  system.stateVersion = "23.11";

  environment.systemPackages = [
    pkgs.git
    pkgs.btop
  ];

  sops = {
    age = {
      keyFile = "/var/lib/secrets/main.age";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    defaultSopsFile = ../../secrets/shiva.yaml;

    # secrets.gh-pat = { };
    secrets.docker-config = { };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
  };

  networking.hostName = "shiva";

  boot.enableContainers = true;

  services.consul.webUi = true;

  services.nomad.settings = {
    plugin = [
      {
        docker = [
          {
            config = [
              {
                auth = [
                  {
                    config = config.sops.secrets.docker-config.path;
                  }
                ];
              }
            ];
          }
        ];
      }
    ];
  };
}
