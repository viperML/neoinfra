{
  config,
  pkgs,
  lib,
  ...
}: let
  nginx_consul = "/etc/nginx/consul.conf";
in {
  imports = [
    ./settings.nix
  ];

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
    # Nomad
    4646
    4647
    4648
    # Consul
    8500
  ];

  services.nomad = {
    enable = true;
    dropPrivileges = false;
    enableDocker = true;
    extraPackages = [
      config.nix.package
    ];
  };

  # vault token create -policy nomad-server -orphan
  sops.secrets."nomad" = {
    restartUnits = [
      "nomad.service"
    ];
  };

  systemd.services.nomad = {
    # after = [
    #   "vault-token-renew.service"
    # ];
    serviceConfig.EnvironmentFile = config.sops.secrets."nomad".path;
  };

  # systemd.services."vault-token-reset" = {
  #   description = "Reset the vault token to the bundled one";
  #   script = ''
  #     set -eux
  #     cp -vfL ${config.sops.secrets."vault_token".path} ${vault_token_path}
  #     chmod 600 ${vault_token_path}
  #   '';
  # };

  # systemd.services."vault-token-renew" = {
  #   path = with pkgs; [
  #     vault
  #     glibc
  #   ];
  #   # serviceConfig = {
  #   #   PrivateTmp = true;
  #   # };
  #   environment.VAULT_ADDR = config.services.nomad.settings.vault.address;
  #   script = ''
  #     set -eux
  #     VAULT_TOKEN=$(<${vault_token_path})
  #     vault token renew
  #   '';
  # };

  # systemd.timers."vault-token-renew" = {
  #   timerConfig.OnCalendar = "daily";
  #   timerConfig.Persistent = true;
  #   wantedBy = ["timers.target"];
  # };

  systemd.tmpfiles.rules = [
    "d /var/lib/nomad 755 root root - -"
    "d /var/lib/nomad/nix 755 root root - -"
  ];

  services.consul = {
    enable = true;
  };

  services.consul-template.instances = {
    "nginx" = {
      settings = {
        template = [
          {
            contents = lib.fileContents ./nginx.ctmpl;
            destination = nginx_consul;
            exec = [
              {
                command = ["systemctl" "kill" "-s" "SIGHUP" "nginx.service"];
                timeout = "10s";
              }
            ];
          }
        ];
      };
    };
  };

  services.nginx.appendHttpConfig = ''
    include ${nginx_consul};
  '';

  systemd.services."nginx" = {
    after = ["consul-template-nginx.service"];
  };
}
