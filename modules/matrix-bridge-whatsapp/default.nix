{
  config,
  pkgs,
  lib,
  ...
}:
{
  assertions = [
    {
      assertion = config.services.matrix-synapse.enable;
      message = "Mautrix whatsapp requires matrix";
    }
  ];

  imports = [ ./settings.nix ];

  services.mautrix-whatsapp = {
    enable = true;
  };

  services.matrix-synapse.settings.app_service_config_files = [
    "/var/lib/mautrix-whatsapp/whatsapp-registration.yaml"
  ];
}
