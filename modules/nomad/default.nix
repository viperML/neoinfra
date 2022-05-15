args @ {
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      4646
      4647
      4648
    ];
    allowedTCPPortRanges = [
      {
        from = 8000;
        to = 8999;
      }
    ];
  };

  services.nomad = {
    enable = true;
    enableDocker = false;
    dropPrivileges = false;
    settings = import ./settings.nix args;
    extraPackages = [
      config.nix.package
      pkgs.git
    ];
    extraSettingsPlugins = [
      inputs.nomad-driver-containerd-nix.packages.${pkgs.system}.nomad-driver-containerd-nix
    ];
  };

  virtualisation.containerd = {
    enable = true;
  };
}
