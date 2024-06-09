{config, ...}: let
  synapsePort = (builtins.head config.services.matrix-synapse.settings.listeners).port;
in {
  services.postgresql = {
    ensureUsers = [
      {
        name = "mautrix-telegram";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = ["mautrix-telegram"];
  };

  # https://github.com/mautrix/telegram/blob/master/mautrix_telegram/example-config.yaml
  services.mautrix-telegram.settings = {
    homeserver = {
      address = "http://[::1]:${toString synapsePort}";
      domain = "ayats.org";
    };

    appservice = rec {
      hostname = "0.0.0.0";
      port = 29317;
      address = "http://localhost:${toString port}";
      database = "postgresql:///mautrix-telegram?host=/run/postgresql";
    };

    bridge = {
      double_puppet_server_map = {
        "ayats.org" = "https://ayats.org";
      };
      permissions = {
        "*" = "relaybot";
        "ayats.org" = "full";
        "@viperml:ayats.org" = "admin";
      };
      # relaybot = {
      #   whitelist = [];
      # };
      encryption = {
        allow = true;
        default = true;
        require = true;
      };
    };
  };
}
