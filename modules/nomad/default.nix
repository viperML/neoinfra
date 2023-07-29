{
  config,
  pkgs,
  lib,
  ...
}: let
  nginx_consul = "/etc/nginx/consul.conf";
in {
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
      pkgs.git
    ];
    settings = {
      bind_addr = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }}'';

      server = {
        enabled = true;
        bootstrap_expect = 1;
      };

      client = {
        enabled = true;
        cni_path = "${pkgs.cni-plugins}/bin";
        host_volume = {
          "nix" = {
            path = "/nix";
            read_only = true;
          };
        };
      };

      vault = {
        enabled = true;
        address = "http://localhost:8200";
        create_from_role = "nomad-cluster";
        task_token_ttl = "1h";
      };

      plugin = [
        {raw_exec = [{config = [{enabled = true;}];}];}
        {docker = [{config = [{volumes = [{enabled = true;}];}];}];}
      ];

      consul = {
        address = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }}:8500'';
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/nomad 755 root root - -"
    "d /var/lib/nomad/nix 755 root root - -"
  ];

  # vault token create -policy nomad-server -period 72h
  sops.secrets."nomad" = {
    restartUnits = [
      "nomad.service"
    ];
  };

  systemd.services.nomad = {
    serviceConfig.EnvironmentFile = config.sops.secrets."nomad".path;
  };

  services.consul = {
    enable = true;
    webUi = true;
    interface = {
      bind = config.services.tailscale.interfaceName;
      advertise = config.services.tailscale.interfaceName;
    };
    extraConfig = {
      server = true;
      bootstrap_expect = 1;
      client_addr = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }} {{ GetAllInterfaces | include "flags" "loopback" | join "address" " " }}'';
    };
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
