{
  lib,
  pkgs,
  config,
  ...
}: {
  services.k3s = {
    enable = true;
    extraFlags = lib.concatStringsSep " " [
      # "--no-deploy traefik"
    ];
  };

  environment.systemPackages = [
    pkgs.kubectl
  ];

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [
      6443
    ];
    allowedUDPPorts = [
      6443
    ];
  };
}
