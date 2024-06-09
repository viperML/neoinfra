{config,lib, ...}: {
  imports = [
    ./settings.nix
  ];

  users.users.mautrix-telegram = {
    isSystemUser = true;
    group = "mautrix-telegram";
  };

  users.groups.mautrix-telegram = {};

  sops.secrets = {
    "mautrix-telegram-environment" = {
      sopsFile = ../../secrets/matrix.yaml;
    };
  };

  systemd.services.mautrix-telegram = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "mautrix-telegram";
      Group = "matrix-synapse"; # so synapse can read the registration
    };
  };

  services.mautrix-telegram = {
    enable = true;
    environmentFile = config.sops.secrets."mautrix-telegram-environment".path;
  };

  services.matrix-synapse.settings.app_service_config_files = [
    "/var/lib/mautrix-telegram/telegram-registration.yaml"
  ];
}
