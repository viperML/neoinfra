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
    pkgs.pkgsBuildBuild.ghostty.terminfo
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

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 1 --optimise";
    };
  };

  systemd.services."journalctl-vacuum" = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-size=300M";
    };
    startAt = "weekly";
  };
}
