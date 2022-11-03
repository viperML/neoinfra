args @ {
  config,
  pkgs,
  self,
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
    enableDocker = true;
    dropPrivileges = false;
    settings = import ./settings.nix args;
    package = self.packages.${pkgs.system}.nomad;
    extraPackages = [
      config.nix.package
      pkgs.git
    ];
  };

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
    };
  };

  users.groups.docker.members = config.users.groups.wheel.members;

  sops.secrets."nomad_env" = {
    owner = config.systemd.services.nomad.serviceConfig.User or "root";
    restartUnits = ["nomad.service"];
  };

  systemd.services.nomad = {
    serviceConfig = {
      EnvironmentFile = [
        config.sops.secrets."nomad_env".path
      ];
    };
  };
}
