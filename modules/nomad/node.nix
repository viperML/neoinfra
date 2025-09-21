{ config, pkgs, ... }:
{
  services.nomad = {
    enable = true;
    dropPrivileges = false;
    enableDocker = true;
    settings = {
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
