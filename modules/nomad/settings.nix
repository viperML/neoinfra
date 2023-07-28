{
  pkgs,
  config,
  ...
}: {
  services.nomad.settings = {
    bind_addr = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }}'';

    server = {
      enabled = true;
      bootstrap_expect = 1;
      # default_scheduler_config = {
      #   scheduler_algorithm = "spread";
      #   memory_oversubscription_enabled = true;
      #   preemption_config = {
      #     batch_scheduler_enabled = true;
      #     system_scheduler_enabled = true;
      #     service_scheduler_enabled = true;
      #   };
      # };
    };

    client = {
      enabled = true;
      cni_path = "${pkgs.cni-plugins}/bin";
    };

    # vault = {
    #   enabled = true;
    #   address = "http://kalypso:8200";
    #   create_from_role = "nomad-cluster";
    # };
    # plugin."raw_exec".config.enabled = true;
    # plugin."docker".config = {
    #   volumes.enabled = true;
    # };
    # plugin."docker"
    plugin = [
      {raw_exec = [{config = [{enabled = true;}];}];}
      {docker = [{config = [{volumes = [{enabled = true;}];}];}];}
    ];

    consul = {
      address = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }}:8500'';
    };
  };

  services.consul = {
    webUi = true;
    interface = {
      bind = config.services.tailscale.interfaceName;
      advertise = config.services.tailscale.interfaceName;
    };
    extraConfig = {
      server = true;
      bootstrap_expect = 1;
      client_addr = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }} {{ GetAllInterfaces | include "flags" "loopback" | join "address" " " }}'';
    };
  };
}
