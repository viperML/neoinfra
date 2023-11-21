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
    allowedTCPPorts = [
      80
      443
    ];

    interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
      # Nomad
      4646
      4647
      4648
    ];
  };

  #-- Secrets
  sops.secrets = {
    "nomad_env" = {
      restartUnits = [
        "nomad.service"
      ];
      sopsFile = ../../secrets/nomad.yaml;
    };
    "letsencrypt_env" = {
      sopsFile = ../../secrets/letsencrypt.yaml;
    };
  };

  #-- Nomad
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
        address = "http://vishnu:8200";
        create_from_role = "nomad-cluster";
        task_token_ttl = "1h";
      };

      plugin = [
        {raw_exec = [{config = [{enabled = true;}];}];}
        # {docker = [{config = [{volumes = [{enabled = true;}];}];}];}
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
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "ayatsfer@gmail.com";
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    certs."wildcard.infra.ayats.org" = {
      domain = "*.infra.ayats.org";
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets."letsencrypt_env".path;
    };
  };

  services.nginx.appendHttpConfig = ''
    include ${nginx_consul_config};
  '';

  users.users."nginx".extraGroups = ["acme"];

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
