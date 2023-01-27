args @ {
  config,
  pkgs,
  self,
  lib,
  ...
}: let
  # Tokens are immutable (?)
  # vault_token_path = "/var/lib/secrets/vault_token";
  vault_token_path = config.sops.secrets."vault_token".path;
in {
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    4646
    4647
    4648
  ];

  services.nomad = {
    enable = true;
    enableDocker = true;
    dropPrivileges = false;
    settings = import ./settings.nix args;
    extraPackages = [config.nix.package];

    package = let
      original = self.packages.${pkgs.system}.nomad;
    in
      pkgs.writeShellApplication {
        name = "nomad";
        runtimeInputs = [];
        text = ''
          VAULT_TOKEN=$(<${vault_token_path})
          export VAULT_TOKEN
          exec -a "$0" ${lib.getExe original} "$@"
        '';
      };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
    };
  };

  users.groups.docker.members = config.users.groups.wheel.members;

  # vault token create -policy nomad-server -orphan
  sops.secrets."vault_token" = {
    owner =
      if config.services.nomad.dropPrivileges
      then throw "dropProvileges not implemented"
      else "root";
    restartUnits = [
      "nomad.service"
      # "vault-token-reset.service"
    ];
  };

  systemd.services.nomad = {
    after = [
      "vault-token-renew.service"
    ];
  };

  # systemd.services."vault-token-reset" = {
  #   description = "Reset the vault token to the bundled one";
  #   script = ''
  #     set -eux
  #     cp -vfL ${config.sops.secrets."vault_token".path} ${vault_token_path}
  #     chmod 600 ${vault_token_path}
  #   '';
  # };

  systemd.services."vault-token-renew" = {
    path = with pkgs; [
      vault
      glibc
    ];
    # serviceConfig = {
    #   PrivateTmp = true;
    # };
    environment.VAULT_ADDR = config.services.nomad.settings.vault.address;
    script = ''
      set -eux
      VAULT_TOKEN=$(<${vault_token_path})
      vault token renew
    '';
  };

  systemd.timers."vault-token-renew" = {
    timerConfig.OnCalendar = "daily";
    timerConfig.Persistent = true;
    wantedBy = ["timers.target"];
  };

  # systemd.tmpfiles.rules = [
  #   "z ${vault_token_path} 0600 root root - -"
  # ];
}
