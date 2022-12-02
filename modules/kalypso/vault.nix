{
  config,
  lib,
  pkgs,
  rootPath,
  inputs,
  ...
}: {
  # https://medium.com/oracledevs/deploying-and-integrating-hashicorp-vault-on-and-with-oci-cf9152b3d1a2
  services.vault = {
    enable = true;
    # Includes UI
    # package = pkgs.vault-bin;
    package = inputs.self.packages.${pkgs.system}.vault-bin;
  };

  systemd.services.vault = {
    serviceConfig.ExecStart = lib.mkForce "${config.services.vault.package}/bin/vault server -config ${config.sops.secrets."vault_config".path}";
    # serviceConfig.AmbientCapabilities = lib.mkForce (lib.concatStringsSep " " [
    #   "cap_ipc_lock"
    #   "cap_net_bind_service"
    # ]);
  };

  sops.secrets."vault_config" = {
    owner = config.systemd.services.vault.serviceConfig.User;
    sopsFile = rootPath + "/secrets/vault.yaml";
    restartUnits = ["vault.service"];
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [
      8200
    ];
  };
}
