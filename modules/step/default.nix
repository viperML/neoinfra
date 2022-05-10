/*
 Some background information:
 - Running on port 443, no reverse proxy
 - Firewall configured in the cloud provisioner
 */
{
  config,
  pkgs,
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
        ${step-cli}/bin/step ca init \
          --ssh \
          --name="ca-ayats-org" \
          --dns="ca.ayats.org" \
          --provisioner="ayatsfer@gmail.com" \
          --address=":443" \
          --password-file=''${CREDENTIALS_DIRECTORY}/password

        ${step-cli}/bin/step ca provisioner add Google \
          --type=oidc \
          --ssh \
          --client-id="578708326236-mt9pnsplbnm6m0b5l10l397mcar3u0rn.apps.googleusercontent.com" \
          --client-secret="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" \
          --configuration-endpoint="https://accounts.google.com/.well-known/openid-configuration" \
          --domain="ayats.org"

        ${step-cli}/bin/step ca provisioner add SSHPOP --type=sshpop --ssh

        sed -i 's/\%p$/%p --provisioner="Google"/g' ${STEPPATH}/templates/ssh/config.tpl
      '';
      serviceConfig =
        serviceConfigCommon
        // {
          Type = "oneshot";
        };
      unitConfig = {
        ConditionFileNotEmpty = "!${STEPPATH}/certs/root_ca.crt";
      };
    };
    "step-ca" = {
      wantedBy = ["multi-user.target"];
      after = [
        "step-ca-setup.service"
        "step-ca-secret.service"
      ];
      unitConfig = {
        ConditionFileNotEmpty = ""; # override upstream
      };
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
