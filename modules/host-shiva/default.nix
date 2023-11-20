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
    inputs.nh.nixosModules.default

    #-- Services
    ../direnv.nix
    ../login-ayats.nix
  ];

  # was broken
  services.envfs.enable = lib.mkForce false;

  documentation.enable = true;

  system.stateVersion = "23.11";

  environment.systemPackages = [
    pkgs.git
  ];

  sops.age = {
    keyFile = "/var/lib/secrets/main.age";
    sshKeyPaths = [];
  };

  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = ../../secrets/shiva.yaml;

  nh = {
    enable = true;
    clean.enable = true;
  };
}
