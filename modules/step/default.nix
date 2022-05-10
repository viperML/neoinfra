{
  config,
  pkgs,
  ...
}: let
  home = "/var/lib/step-ca";
  STEPPATH = home;

  settingsFormat = pkgs.formats.json {};
  settings = {
    root = "${STEPPATH}/certs/root_ca.crt";
    federatedRoots = null;
    crt = "${STEPPATH}/certs/intermediate_ca.crt";
    key = "${STEPPATH}/secrets/intermediate_ca_key"; # needed?
    address = "0.0.0.0:443";
    insecureAddress = "";
    dnsNames = [
      "ca.ayats.org"
    ];
    ssh = {
      hostKey = "${STEPPATH}/secrets/ssh_host_ca_key";
      userKey = "${STEPPATH}/secrets/ssh_user_ca_key";
    };
    logger = {
      format = "text";
    };
    db = {
      type = "badgerv2";
      badgerFileLoadingMode = "";
      dataSource = "${STEPPATH}/db";
    };
    tls = {
      cipherSuites = [
        "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
        "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
      ];
      minVersion = 1.2;
      maxVersion = 1.3;
      renegotiation = false;
    };
    authority = {
      provisioners = [
        {
          type = "OIDC";
          name = "Google";
          clientID = "578708326236-mt9pnsplbnm6m0b5l10l397mcar3u0rn.apps.googleusercontent.com";
          clientSecret = "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";
          configurationEndpoint = "https://accounts.google.com/.well-known/openid-configuration";
          admins = ["ayatsfer@gmail.com"];
          domains = ["ca.ayats.org"];
          listenAddress = ":10000";
          # https://smallstep.com/docs/step-ca/provisioners#claims
          claims = {
            maxTLSCertDuration = "8h";
            defaultTLSCertDuration = "2h";
            disableRenewal = true;
            enableSSHCA = true;
          };
        }
      ];
    };
    templates = {
      ssh = {
        user = [
          {
            name = "include.tpl";
            type = "snippet";
            template = "templates/ssh/include.tpl";
            path = "~/.ssh/config";
            comment = "#";
          }
          {
            name = "config.tpl";
            type = "file";
            template = "templates/ssh/config.tpl";
            path = "ssh/config";
            comment = "#";
          }
          {
            name = "known_hosts.tpl";
            type = "file";
            template = "templates/ssh/known_hosts.tpl";
            path = "ssh/known_hosts";
            comment = "#";
          }
        ];
        host = [
          {
            name = "sshd_config.tpl";
            type = "snippet";
            template = "templates/ssh/sshd_config.tpl";
            path = "/etc/ssh/sshd_config";
            requires = ["Certificate" "Key"];
            comment = "#";
          }
          {
            name = "ca.tpl";
            type = "snippet";
            path = "/etc/ssh/ca.pub";
            template = "templates/ssh/ca.tpl";
            comment = "#";
          }
        ];
      };
    };
  };

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

  settingsFile = settingsFormat.generate "ca.json" settings;
in {
  users.users.step-ca = {
    inherit home;
    group = "step-ca";
    isSystemUser = true;
  };
  users.groups.step-ca = {};

  environment.etc."smallstep/ca.json".source = settingsFile;

  systemd.packages = [pkgs.step-ca];
  systemd.services = {
    "step-ca-secret" = {
      wantedBy = ["multi-user.target"];
      script = ''
        ${pkgs.pwgen}/bin/pwgen -sy 30 1 > password
        echo "Password generated successfully"
      '';
      serviceConfig = {
        UMask = "0077";
        WorkingDirectory = "/var/lib/step-ca-secret";
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
      script = ''
        ${pkgs.step-cli}/bin/step ca init \
          --pki \
          --ssh \
          --deployment-type=standalone \
          --name=step-pki \
          --password-file=''${CREDENTIALS_DIRECTORY}/password
        mkdir -p ${STEPPATH}/templates
        cp -r ${./templates}/* ${STEPPATH}/templates
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
      restartTriggers = [settingsFile];
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
                ${settingsFile} \
                --password-file ''${CREDENTIALS_DIRECTORY}/password
            ''
          ];
        };
    };
  };
}
