{
  config,
  pkgs,
  lib, ...
}: {

  services.mautrix-whatsapp = {};

  assertions = [
    {
      assertion = config.services.matrix-synapse.enable;
      message = "Mautrix whatsapp requires matrix";
    }
  ];
}
