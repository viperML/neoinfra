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
    };
    extraPackages = with pkgs; [
      cni-plugins
      dmidecode
    ];
    extraSettingsPlugins = with pkgs; [
      nomad-driver-podman
    ];
  };

  assertions = [
    {
      assertion = config.services.tailscale.enable;
      message = "nomad requires consul";
    }
  ];
}
