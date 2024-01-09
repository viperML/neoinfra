{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;
in {
  options.neoinfra = {
    consul-service = mkOption {
      default = {};
      type = types.attrsOf (types.submodule ({
        config,
        name,
        ...
      }: {
        options = {
          port = mkOption {
            type = types.port;
          };

          domain = mkOption {
            type = types.str;
          };

          service = mkOption {
            type = types.str;
            default = "${name}.service";
          };
        };
      }));
    };
  };

  config = {
    services.consul = {
      enable = true;
      webUi = lib.mkDefault false;
      interface = {
        bind = config.services.tailscale.interfaceName;
        advertise = config.services.tailscale.interfaceName;
      };
      extraConfig = {
        server = true;
        bootstrap_expect = 2;
        client_addr = ''{{ GetInterfaceIP "${config.services.tailscale.interfaceName}" }} {{ GetAllInterfaces | include "flags" "loopback" | join "address" " " }}'';
        enable_script_checks = true;
      };
    };

    # https://developer.hashicorp.com/consul/docs/install/ports
    networking.firewall.interfaces.${config.services.tailscale.interfaceName} = rec {
      allowedTCPPorts =
        [
          8500
          8600
          8501
          8502
          8503
          8301
          8302
          8300
        ]
        ++ (lib.pipe config.neoinfra.consul-service [
          lib.attrsToList
          (map (x: x.value.port))
        ]);
      allowedUDPPorts = allowedTCPPorts;
      allowedTCPPortRanges = [
        {
          from = 21000;
          to = 21255;
        }
      ];
    };

    services.resolved = {
      extraConfig = ''
        [Resolve]
        DNS=127.0.0.1:8600
        DNSSEC=false
        Domains=~consul
      '';
    };

    systemd.services = lib.mapAttrs' (name: value:
      lib.nameValuePair "consul-service-${name}" {
        serviceConfig = {
          Type = "oneshot";
        };
        wantedBy = [value.service];
        after = [value.service];
        path = [
          pkgs.curl
        ];
        # TODO parse curl output and fail on bad req
        script = ''
          curl --request PUT --data @${(pkgs.formats.json {}).generate "service.json" {
            Name = name;
            Port = value.port;
            Tags = ["public"];
            Meta = {
              domain = value.domain;
            };
            Check = {
              Name = "systemd";
              Args = ["systemctl" "is-active" value.service];
              Interval = "5m";
            };
          }} http://localhost:8500/v1/agent/service/register
        '';
      })
    config.neoinfra.consul-service;

    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "consul-server relies on tailscale";
      }
    ];
  };
}
