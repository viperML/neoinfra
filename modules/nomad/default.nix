{
  config,
  pkgs,
  lib,
  ...
}: let
  nginx_consul_config = "/etc/nginx/consul.conf";
in {
  #-- Firewall
  networking.firewall = {
    interfaces.${config.services.tailscale.interfaceName} = {
      allowedTCPPorts = [
        # Nomad
        4646
        4647
        4648
        # Vault
        8200
      ];

      allowedTCPPortRanges = [
        # https://developer.hashicorp.com/nomad/docs/job-specification/network#dynamic-ports
        {
          from = 20000;
          to = 32000;
        }
      ];
    };
  };

  #-- Secrets
  sops.secrets = {
    "nomad_env" = {
      restartUnits = [
        "nomad.service"
      ];
      sopsFile = ../../secrets/nomad.yaml;
    };
  };

  #-- Nomad
  services.nomad = {
    enable = true;
    dropPrivileges = false;
    enableDocker = true;
    extraPackages =
      [
        config.nix.package
        pkgs.git
      ]
      ++ pkgs.stdenv.initialPath;
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
        network_interface = config.services.tailscale.interfaceName;
      };

      vault = {
        enabled = true;
        address = "http://vault.service.consul:8200";
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

  systemd.services.nomad = {
    serviceConfig.EnvironmentFile = config.sops.secrets."nomad_env".path;
  };

  #-- Consul
  services.consul-template.instances = {
    "nginx" = {
      settings = {
        template = [
          {
            contents = lib.fileContents ./nginx.ctmpl;
            destination = nginx_consul_config;
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

  systemd.services."nginx" = {
    after = ["consul-template-nginx.service"];
  };

  #-- Nginx
  services.nginx.appendHttpConfig = ''
    include ${nginx_consul_config};
  '';

  assertions = [
    {
      assertion = config.services.consul.enable;
      message = "nomad requires consul";
    }
    {
      assertion = config.services.tailscale.enable;
      message = "nomad requires tailscale";
    }
    {
      assertion = config.virtualisation.docker.enable;
      message = "nomad requires docker";
    }
  ];
}
