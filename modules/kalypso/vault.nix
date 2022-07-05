{
  config,
  lib,
  self,
  pkgs,
  ...
}: {
  services.vault = {
    enable = true;
    # Includes UI
    package = pkgs.vault-bin;
  };

  systemd.services.vault = {
    serviceConfig.ExecStart = lib.mkForce "${config.services.vault.package}/bin/vault server -config ${config.sops.secrets."vault_config".path}";
  };

  sops.secrets."vault_config" = {
    owner = config.systemd.services.vault.serviceConfig.User;
    sopsFile = "${self}/secrets/vault.yaml";
    restartUnits = ["vault.service"];
  };

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      8200
    ];
  };
}
