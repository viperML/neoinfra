# copied from https://github.com/adamcstephens/stop-export/blob/795d6c683c0b2ed5f55cc16af348a372e2111149/services/synapse/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  virtualHost = "matrix.ayats.org";
  synapsePort = 8008;
in {
  sops.secrets.matrix-synapse-config = {
    sopsFile = ../../secrets/matrix.yaml;
    owner = config.systemd.services.matrix-synapse.serviceConfig.User;
    group = config.systemd.services.matrix-synapse.serviceConfig.Group;
  };

  services.postgresql = {
    enable = true;
    # package = pkgs.postgresql_14; # 15 requires some public schema access not supported by module (ownership works...)
    settings.listen_addresses = lib.mkForce "";
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "matrix-synapse"
    ];
    initdbArgs = [
      "--locale=C"
      "--encoding=UTF8"
    ];
  };

  services.matrix-synapse = {
    enable = true;

    settings = {
      server_name = virtualHost;
      public_baseurl = "https://${virtualHost}/";
      web_client_location = "https://${virtualHost}/";
      # serve_server_wellknown = true; # doesn't support matrix.zone

      database.name = "psycopg2";
      enable_metrics = true;
      listeners = [
        {
          port = 8008;
          bind_addresses = ["::1"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = ["client" "federation"];
              compress = true;
            }
          ];
        }
        {
          port = 9008;
          resources = [];
          tls = false;
          bind_addresses = ["127.0.0.1"];
          type = "metrics";
        }
      ];

      # we'll trust matrix.org implicitly
      suppress_key_server_warning = true;

      allow_guest_access = false;
      enable_registration = false;
      enable_registration_without_verification = false;
      url_preview_enabled = true;
      expire_access_token = true;
    };

    extras = ["oidc"];

    extraConfigFiles = [config.sops.secrets.matrix-synapse-config.path];
  };

  services.nginx.virtualHosts = {
    "matrix.ayats.org" = {
      useACMEHost = "wildcard.ayats.org";
      forceSSL = true;
      locations = let
        mkWellKnown = data: ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${builtins.toJSON data}';
        '';
      in {
        "/".extraConfig = ''
          return 404;
        '';
        "/_matrix".proxyPass = "http://[::1]:8008";
        "/_synapse/client".proxyPass = "http://[::1]:8008";

        "= /.well-known/matrix/server".extraConfig = mkWellKnown {"m.server" = "${virtualHost}:443";};
        "= /.well-known/matrix/client".extraConfig = mkWellKnown {"m.homeserver".base_url = "https:://${virtualHost}";};
      };
    };
  };

  # neoinfra.consul-service.matrix-synapse = {
  #   domain = virtualHost;
  #   port = synapsePort;
  # };
}
