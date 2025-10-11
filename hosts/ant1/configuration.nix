{ config, ... }:
{
  documentation.enable = true;

  system.stateVersion = "25.05";

  # environment.systemPackages = [
  #   pkgs.git
  #   pkgs.pkgsBuildBuild.ghostty.terminfo
  #   pkgs.net-tools
  # ];

  sops = {
    age = {
      keyFile = "/var/lib/secrets/main.age";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    defaultSopsFile = ../../secrets/ant1.yaml;
  };

  networking.hostName = "ant1";

  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
      port = 9096;
    };
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [
      9096
    ];
  };

  # services.postgresql = {
  #   enable = true;
  #   identMap = ''
  #     postgres root postgres
  #   '';
  # };
}
