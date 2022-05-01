{
  config,
  pkgs,
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
    settings = {
      bind_addr = "0.0.0.0";
      server = {
        enabled = true;
        bootstrap_expect = 1;
      };
      client = {
        enabled = true;
        host_volume."nix" = {
          path = "/nix";
          read_only = false;
        };
      };
    };
  };
}
