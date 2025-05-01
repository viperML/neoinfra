{
  config,
  lib,
  ...
}:
{
  services.consul = {
    enable = true;
    webUi = lib.mkDefault false;
    interface = {
      bind = config.services.tailscale.interfaceName;
      advertise = config.services.tailscale.interfaceName;
    };
    extraConfig = {
      server = true;
      bootstrap_expect = 1;
      client_addr = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }} {{ GetAllInterfaces | include "flags" "loopback" | join "address" " " }}'';
      enable_script_checks = true;
    };
  };

  # https://developer.hashicorp.com/consul/docs/install/ports
  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = rec {
    allowedTCPPorts = [
      8500
      8600
      8501
      8502
      8503
      8301
      8302
      8300
    ];
    allowedUDPPorts = allowedTCPPorts;
    allowedTCPPortRanges = [
      {
        from = 21000;
        to = 21255;
      }
    ];
  };

  services.resolved = {
    extraConfig = ''
      [Resolve]
      DNS=127.0.0.1:8600
      DNSSEC=false
      Domains=~consul
    '';
  };

  assertions = [
    {
      assertion = config.services.tailscale.enable;
      message = "consul relies on tailscale";
    }
  ];
}
