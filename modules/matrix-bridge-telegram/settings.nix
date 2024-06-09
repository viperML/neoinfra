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
      hostname = "::1";
      port = 29317;
      address = "http://[::1]:${toString port}";
      database = "postgresql:///mautrix-telegram?host=/run/postgresql";
    };

    bridge = {
      double_puppet_server_map = {
        "ayats.org" = "https://ayats.org";
      };
      permissions = {
        "ayats.org" = "full";
        "@viperml:ayats.org" = "admin";
      };
      encryption = {
        allow = true;
        default = true;
        # require = true;
      };
    };
  };
}
