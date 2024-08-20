{
  pkgs,
  inputs,
  lib,
  ...
}: {
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

    ../matrix
    ../postgres

    ../mail

    # ../slurm
  ];

  # was broken
  services.envfs.enable = lib.mkForce false;

  documentation.enable = true;

  system.stateVersion = "23.11";

  environment.systemPackages = [
    pkgs.git
  ];

  sops = {
    age = {
      keyFile = "/var/lib/secrets/main.age";
      sshKeyPaths = [];
    };
    gnupg.sshKeyPaths = [];
    defaultSopsFile = ../../secrets/shiva.yaml;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
  };

  networking.hostName = "shiva";

  boot.enableContainers = true;
}
