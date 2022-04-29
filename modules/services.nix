{
  pkgs,
  config,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  # Docker config
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
    extraOptions = "--registry-mirror=https://mirror.gcr.io";
  };
  users.groups.docker.members = config.users.groups.wheel.members;
  systemd .timers.docker-prune = {
    wantedBy = ["timers.target"];
    partOf = ["docker-prune.service"];
    timerConfig.OnCalendar = "*-*-* 2:00:00";
  };
  systemd.services.docker-prune = {
    script = ''
      ${pkgs.docker}/bin/docker image prune --filter "until=72h"
    '';
    requires = ["docker.service"];
  };
}
