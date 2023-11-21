{
  config,
  lib,
  pkgs,
  ...
}: {
  # https://medium.com/oracledevs/deploying-and-integrating-hashicorp-vault-on-and-with-oci-cf9152b3d1a2
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
  };

  environment.systemPackages = [
    config.services.vault.package
  ];

  environment.sessionVariables.VAULT_ADDR = "http://localhost:8200";

  systemd.services.vault = {
    serviceConfig.ExecStart = lib.mkForce "${config.services.vault.package}/bin/vault server -config ${config.sops.secrets."vault_config".path}";
    # serviceConfig.AmbientCapabilities = lib.mkForce (lib.concatStringsSep " " [
    #   "cap_ipc_lock"
    #   "cap_net_bind_service"
    # ]);
    serviceConfig.EnvironmentFile = config.sops.secrets."vault_env".path;
  };

  systemd.services."vault-unseal" = {
    after = ["vault.service"];
    wantedBy = ["vault.service"];
    environment = {inherit (config.environment.sessionVariables) VAULT_ADDR;};
    serviceConfig = {
      ExecStart = pkgs.writers.writePerl "vault-unseal" {
        libraries = with pkgs.perlPackages; [
          JSON
          DataDumper
        ];
      } (lib.fileContents ./unseal.pl);
      RestartSec = "5s";
      Restart = "on-failure";
      StartLimitIntervalSec = "0";
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets."vault_unseal_env".path;
    };
  };

  sops.secrets =
    lib.genAttrs [
      "vault_config"
      "vault_env"
      "vault_unseal_env"
    ] (_: {
      owner = config.systemd.services.vault.serviceConfig.User;
      sopsFile = ../../secrets/vault.yaml;
      restartUnits = ["vault.service"];
    });

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [
      8200
    ];
  };
}
