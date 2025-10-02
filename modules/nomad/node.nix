{ config, pkgs, ... }:
{
  services.nomad = {
    enable = true;
    dropPrivileges = false;
    enableDocker = true;
    settings = {
      # bind_addr = "0.0.0.0";
      acl.enabled = true;
      data_dir = "/var/lib/nomad";
      server = {
        enabled = true;
        bootstrap_expect = 1;
      };
      client = {
        enabled = true;
        alloc_dir = "/var/lib/nomad/alloc";
        alloc_mounts_dir = "/var/lib/nomad/alloc_mounts";
        host_network = [
          {
            "lo" = [
              {
                interface = "lo";
              }
            ];
          }
        ];
      };
      plugin = [
        {
          docker = {
            config = {
              volumes = [ { enabled = true; } ];
            };
          };
        }
      ];
      telemetry = {
        collection_interval = "1s";
        # disable_hostname = true;
        prometheus_metrics = true;
        publish_allocation_metrics = true;
        publish_node_metrics = true;
      };
    };
    extraPackages = with pkgs; [
      cni-plugins
      dmidecode
    ];
  };

  assertions = [
    {
      assertion = config.virtualisation.docker.enable;
      message = "nomad requires docker";
    }
  ];
}
