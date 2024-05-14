{config, ...}: let
  synapsePort = (builtins.head config.services.matrix-synapse.settings.listeners).port;
in {
  services.heisenbridge = {
    enable = true;
    homeserver = "http://[::1]:${toString synapsePort}";
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
