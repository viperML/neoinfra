/*
Some background information:
- Running on port 443, no reverse proxy
- Firewall configured in the cloud provisioner
*/
{
  config,
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
      "HOME=%S/step-ca"
      "STEPPATH=${STEPPATH}"
      "PATH=${lib.makeBinPath [
        pkgs.step-cli
        pkgs.gnused
        pkgs.jq
        pkgs.moreutils
      ]}"
    ];
    WorkingDirectory = "";
    DynamicUser = true;
    StateDirectory = "step-ca";
    LoadCredential = "password:/var/lib/step-ca-secret/password";
  };
in {
  users.users.step-ca = {
    inherit home;
    group = "step-ca";
    isSystemUser = true;
  };
  users.groups.step-ca = {};

  environment.systemPackages = [pkgs.step-cli];

  systemd.packages = [pkgs.step-ca];
  systemd.tmpfiles.rules = [
    "d /var/lib/step-ca-secret 0700 root root - -"
  ];

  systemd.services = {
    "step-ca-secret" = {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        UMask = "0077";
        WorkingDirectory = "/var/lib/step-ca-secret";
        StandardOutput = "truncate:/var/lib/step-ca-secret/password";
        ExecStart = "${pkgs.pwgen}/bin/pwgen -sy 42 1";
        StateDirectory = "step-ca-secret";
        Type = "oneshot";
      };
      unitConfig = {
        ConditionFileNotEmpty = "!/var/lib/step-ca-secret/password";
      };
    };
    "step-ca-setup" = {
      wantedBy = ["multi-user.target"];
      after = ["step-ca-secret.service"];
      script = with pkgs; ''
        set -euxo pipefail
        step ca init \
          --ssh \
          --name="ca-ayats-org" \
          --dns="ca.ayats.org" \
          --provisioner="ayatsfer@gmail.com" \
          --address=":443" \
          --password-file=''${CREDENTIALS_DIRECTORY}/password

        step ca provisioner remove "ayatsfer@gmail.com" --all

        step ca provisioner add Google \
          --type=oidc \
          --ssh \
          --client-id="578708326236-mt9pnsplbnm6m0b5l10l397mcar3u0rn.apps.googleusercontent.com" \
          --client-secret="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" \
          --configuration-endpoint="https://accounts.google.com/.well-known/openid-configuration" \
          --admin="ayatsfer@gmail.com" \
          --domain="ayats.org"

        jq '(.authority.provisioners[] | select(.name=="sshpop") | .claims) |= { "enableSSHCA": true, "maxHostSSHCertDuration": "1440h", "defaultHostSSHCertDuration": "1440h" }' \
          ${STEPPATH}/config/ca.json \
          | sponge ${STEPPATH}/config/ca.json

        jq '(.authority.provisioners[] | select(.name=="Google") | .claims) |= { "enableSSHCA": true, "maxHostSSHCertDuration": "1440h", "defaultHostSSHCertDuration": "1440h", "defaultUserSSHCertDuration": "14h", "maxUserSSHCertDuration": "14h" }' \
          ${STEPPATH}/config/ca.json \
          | sponge ${STEPPATH}/config/ca.json

        sed -i 's/\%p$/%p --provisioner="Google"/g' ${STEPPATH}/templates/ssh/step_config.tpl
      '';
      serviceConfig =
        lib.recursiveUpdate
        serviceConfigCommon
        {
          Type = "oneshot";
          StandardOutput = "tty";
          StandardError = "tty";
        };
      unitConfig.ConditionFileNotEmpty = "!${STEPPATH}/certs/root_ca.crt";
    };
    "step-ca" = {
      wantedBy = ["multi-user.target"];
      after = [
        "step-ca-setup.service"
        "step-ca-secret.service"
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
                ${STEPPATH}/config/ca.json \
                --password-file ''${CREDENTIALS_DIRECTORY}/password
            ''
          ];
        };
    };
  };
}
