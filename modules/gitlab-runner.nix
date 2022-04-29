{
  config,
  pkgs,
  lib,
  ...
}: {
  # https://nixos.wiki/wiki/Gitlab_runner
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  sops.secrets."gitlab_runner_registration" = {
    owner = "gitlab-runner";
    restartUnits = [
      "gitlab-runner"
    ];
  };

  # https://github.com/Mic92/dotfiles/blob/ed456e0836d0562728c7e9fb3ce6405f270c9e7c/nixos/eve/modules/gitlab/runner.nix
  services.gitlab-runner = {
    enable = true;
    concurrent = 1;
    services.shell = {
      executor = "shell";
      registrationConfigFile = config.sops.secrets."gitlab_runner_registration".path;
    };
    extraPackages = with pkgs; [
      bash
      nettools
      git
      gnutar
      gzip
      rsync
      nix-eval-jobs
      config.nix.package
    ];
  };

  nix.trustedUsers = ["gitlab-runner"];

  systemd.services.gitlab-runner = {
    confinement.enable = true;
    confinement.packages = config.services.gitlab-runner.extraPackages;
    serviceConfig = {
      User = "gitlab-runner";
      Group = "gitlab-runner";
      DynamicUser = lib.mkForce false;
      Environment = [
        "NIX_REMOTE=daemon"
        "PAGER=cat"
      ];
      BindPaths = [
        "/nix/var/nix/daemon-socket/socket"
        "/run/nscd/socket"
        "/var/lib/gitlab-runner"
      ];
      BindReadOnlyPaths = [
        "/etc/resolv.conf"
        "/etc/nsswitch.conf"

        "/etc/passwd"
        "/etc/group"
        "/nix/var/nix/profiles/system/etc/nix:/etc/nix"
        config.sops.secrets."gitlab_runner_registration".path
        "${config.environment.etc."ssl/certs/ca-certificates.crt".source}:/etc/ssl/certs/ca-certificates.crt"
        "${config.environment.etc."ssl/certs/ca-bundle.crt".source}:/etc/ssl/certs/ca-bundle.crt"
        "${config.environment.etc."ssh/ssh_known_hosts".source}:/etc/ssh/ssh_known_hosts"
        "${config.environment.etc."hosts".source}:/etc/hosts"
        # "${
        #   builtins.toFile "ssh_config" ''
        #     Host eve.thalheim.io
        #       ForwardAgent yes
        #   ''
        # }:/etc/ssh/ssh_config"
        "/etc/machine-id"
        # channels are dynamic paths in the nix store, therefore we need to bind mount the whole thing
        "/nix/"
      ];
    };
  };

  users.users.gitlab-runner = {
    group = "gitlab-runner";
    isSystemUser = true;
    home = "/var/lib/gitlab-runner";
  };

  users.groups.gitlab-runner = {};
}
