{
  config,
  lib,
  pkgs,
  ...
}:
let
  # sync with:
  # https://github.com/NixOS/nixpkgs/blob/nixos-23.11/nixos/modules/services/matrix/mautrix-whatsapp.nix
  dataDir = "/var/lib/mautrix-whatsapp";
  settingsFile = "${dataDir}/config.json";
  registrationFile = "${dataDir}/whatsapp-registration.yaml";
  doublepuppetRegistrationFile = "${dataDir}/doublepuppet-registration.yaml";
in
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

  # users.users."matrix-synapse".extraGroups = [ "mautrix-whatsapp" ];

  services.matrix-synapse.settings.app_service_config_files = [
    config.sops.secrets.mautrix-whatsapp-registration.path
    config.sops.secrets.mautrix-whatsapp-doublepuppet-registration.path
  ];

  services.postgresql = {
    ensureUsers = [
      {
        name = "mautrix-whatsapp";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "mautrix-whatsapp" ];
  };

  systemd.services.mautrix-whatsapp = {
    preStart = lib.mkMerge [
      (lib.mkBefore ''
        ln -vsfT '${config.sops.secrets.mautrix-whatsapp-registration.path}' '${registrationFile}'
        ln -vsfT '${config.sops.secrets.mautrix-whatsapp-doublepuppet-registration.path}' '${doublepuppetRegistrationFile}'
      '')

      (lib.mkAfter ''
        old_umask=$(umask)
        umask 0177

        ${pkgs.yq}/bin/yq -s '.[0].bridge.login_shared_secret_map."matrix.ayats.org" = "as_token:\(.[1].as_token)"
          | .[0]' \
          '${settingsFile}' '${doublepuppetRegistrationFile}' \
          > '${settingsFile}.tmp'
        mv '${settingsFile}.tmp' '${settingsFile}'

        umask $old_umask
      '')
    ];
  };

  sops.secrets =
    lib.genAttrs
      [
        "mautrix-whatsapp-registration"
        "mautrix-whatsapp-doublepuppet-registration"
      ]
      (
        name: {
          sopsFile = ../../secrets/matrix.yaml;
          owner = "mautrix-whatsapp";
          group = "matrix-synapse";
          mode = "0440";
          restartUnits = [
            "mautrix-whatsapp.service"
            "matrix-synapse.service"
          ];
        }

      );
}
