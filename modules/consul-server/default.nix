{
  config,
  lib,
  ...
}: {
  services.consul = {
    enable = true;
    webUi = lib.mkDefault false;
    interface = {
      bind = config.services.tailscale.interfaceName;
      advertise = config.services.tailscale.interfaceName;
    };
    extraConfig = {
      server = true;
      bootstrap_expect = 2;
      client_addr = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }} {{ GetAllInterfaces | include "flags" "loopback" | join "address" " " }}'';
    };
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
    8500
  ];

  assertions = [
    {
      assertion = config.services.tailscale.enable;
      message = "consul-server relies on tailscale";
    }
  ];
}
