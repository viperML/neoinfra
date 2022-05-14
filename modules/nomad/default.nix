{
  config,
  pkgs,
  inputs,
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

  # Pseudo-fhsenv for the exec runner
  systemd.tmpfiles.rules = let
    collection = pkgs.symlinkJoin {
      name = "nomad-environment";
      paths = [
        pkgs.coreutils
        config.nix.package
      ];
    };
  in [
    "L+ /usr/local - - - - ${collection}"
  ];

  services.nomad = {
    enable = true;
    enableDocker = false;
    dropPrivileges = false;
    settings = import ./settings.nix;
    extraSettingsPlugins = [
      inputs.nomad-driver-containerd-nix.packages."x86_64-linux".nomad-driver-containerd-nix
    ];
  };

  virtualisation.containerd = {
    enable = true;
  };
}