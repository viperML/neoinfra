{
  pkgs,
  lib,
  ...
}: let
  home = "/var/lib/step-ca";
  STEPPATH = home;

  serviceConfigCommon = {
    User = "step-ca";
    Group = "step-ca";
    UMask = "0077";
    Environment = [
      "HOME=${STEPPATH}"
      "STEPPATH=${STEPPATH}"
      # "PATH=${lib.makeBinPath [
      #   ]}"
    ];
    WorkingDirectory = STEPPATH;
    DynamicUser = true;
    StateDirectory = "step-ca";
    # LoadCredential = "password:/var/lib/step-ca-secret/password";
  };

  stepPort = 443;

  configFile = pkgs.substituteAll {
    src = ./config.json;
    steppath = STEPPATH;
    templates = "${./templates}";
  };

  step_setup_py = pkgs.writers.writePython3 "step_setup" {
    libraries = with pkgs.python3.pkgs; [
      oci
    ];
  } (builtins.readFile ./step_setup.py);
in {
  networking.firewall.allowedTCPPorts = [
    stepPort
  ];

  users.users.step-ca = {
    inherit home;
    group = "step-ca";
    isSystemUser = true;
  };
  users.groups.step-ca = {};

  environment.systemPackages = [
    # For admin
    pkgs.step-cli
    pkgs.step-ca
  ];

  systemd.packages = [pkgs.step-ca];

  systemd.services = {
    "step-ca-setup" = {
      wantedBy = ["multi-user.target"];
      serviceConfig =
        serviceConfigCommon
        // {
          ExecStart = step_setup_py.outPath;
          Type = "oneshot";
        };
    };

    "step-ca" = {
      wantedBy = ["multi-user.target"];
      after = [
        "step-ca-setup.service"
      ];
      unitConfig.ConditionFileNotEmpty = ""; # override upstream
      serviceConfig =
        serviceConfigCommon
        // {
          ReadWriteDirectories = ""; # override upstream
          ExecStart = [
            "" # override upstream
            ''
              ${pkgs.step-ca}/bin/step-ca \
                ${configFile} \
                --password-file ${STEPPATH}/secrets/password_intermediate
            ''
          ];
        };
    };
  };
}
