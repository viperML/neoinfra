{
  pkgs,
  lib,
  ...
}:
{
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
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    defaultSopsFile = ../../secrets/shiva.yaml;

    # secrets.gh-pat = { };
    secrets.docker-config = { };
  };

  networking.hostName = "shiva";

  # boot.enableContainers = true;

  # services.consul.webUi = true;

  # services.nomad.settings = {
  #   plugin = [
  #     {
  #       docker = [
  #         {
  #           config = [
  #             {
  #               auth = [
  #                 {
  #                   config = config.sops.secrets.docker-config.path;
  #                 }
  #               ];
  #             }
  #           ];
  #         }
  #       ];
  #     }
  #   ];
  # };
}
