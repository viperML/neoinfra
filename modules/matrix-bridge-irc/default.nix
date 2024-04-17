{
  config,
  pkgs,
  ...
}: {
  services.heisenbridge = {
    enable = true;
    homeserver = "http://localhost:8008";
  };

  services.matrix-synapse.settings.app_service_config_files = [
    "/var/lib/heisenbridge/registration.yml"
  ];

  assertions = [
    {
      assertion = config.services.matrix-synapse.enable;
      message = "Heisenbridge requires matrix";
    }
  ];
}
