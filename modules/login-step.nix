{
  lib,
  config,
  pkgs,
  rootPath,
  ...
}: let
  ca_path = "ssh/ca.d";
  pubCert = "/var/lib/secrets/ssh_host_ecdsa_key-cert.pub";
  inherit (config.networking) hostName;
in {
  users.mutableUsers = false;
  users.allowNoPasswordLogin = true; # module system doesn't know about certs

  users.users.admin = {
    name = "admin";
    isNormalUser = true;
    extraGroups = ["wheel"];
  };

  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = ["@wheel"];

  # services.getty.autologinUser = "admin";

  sops.secrets = let
    sopsFile = rootPath + "/secrets/${hostName}-ssh.yaml";
  in {
    "ssh_host_ecdsa_key" = {
      inherit sopsFile;
      mode = "600";
    };
    "ssh_host_ecdsa_key-cert-pub" = {
      inherit sopsFile;
      mode = "644";
      restartUnits = [
        "step-renew-reset.service"
      ];
    };
    "root_ca_crt" = {
      inherit sopsFile;
      mode = "600";
    };
  };

  services.openssh = {
    enable = true;
    # openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      HostKey = config.sops.secrets."ssh_host_ecdsa_key".path;
      HostCertificate = pubCert;
      # HostCertificate ${config.sops.secrets."ssh_host_ecdsa_key-cert-pub".path}
      TrustedUserCAKeys = "/etc/${ca_path}/ssh_user_keys.pub";
      AuthorizedPrincipalsFile = "/etc/${ca_path}/%u_principals";
    };
    hostKeys = [];
  };

  environment.etc = {
    "${ca_path}/ssh_user_keys.pub" = {
      mode = "0444";
      text = lib.concatStringsSep "\n" [
        (lib.fileContents (rootPath + "/secrets/${hostName}-ssh_user_key.pub"))
      ];
    };
    "${ca_path}/admin_principals" = {
      mode = "0444";
      text = lib.concatStringsSep "\n" [
        "admin"
        "ayatsfer@gmail.com"
      ];
    };
  };

  /*
  Host certificates (validates a host to a user to avoid TOFU) expire after some time.

  These services clone the certificate loaded by sops-nix, and update it if needed
  */

  systemd.services."step-renew" = {
    description = "Renew ssh host certificate with step-ca and SSHPOP";
    path = [pkgs.step-cli];
    environment."STEPPATH" = "/var/empty";
    script = ''
      set -xu

      if [[ ! -f ${pubCert} ]]; then
        cp -vfL ${config.sops.secrets."ssh_host_ecdsa_key-cert-pub".path} ${pubCert}
        chown root:root ${pubCert}
        chmod 0644 ${pubCert}
      fi

      step ssh inspect ${pubCert}

      set +e
      step ssh needs-renewal \
          ${pubCert} \
          --expires-in 50% &>/dev/null
      status=$?
      set -e

      if [ $status -eq 1 ]; then
          echo "Certificate does not need renewal"
      elif [ $status -eq 0 ]; then
          echo "Renewing certificate"
          step ssh renew --force \
              --ca-url https://ca.ayats.org \
              --root ${config.sops.secrets."root_ca_crt".path} \
              ${pubCert} \
              ${config.sops.secrets."ssh_host_ecdsa_key".path}
      else
          echo "Unknown error"
          exit 1
      fi
    '';
    wantedBy = ["multi-user.target"];
    before = ["sshd.service"];
    serviceConfig.Type = "oneshot";
  };

  systemd.timers."step-renew" = {
    timerConfig.OnCalendar = "daily";
    timerConfig.Persistent = true;
    wantedBy = ["timers.target"];
  };

  systemd.services."step-renew-reset" = {
    description = "Reset the ssh host certificate to the sops-nix certificate";
    script = ''
      cp -vfL ${config.sops.secrets."ssh_host_ecdsa_key-cert-pub".path} ${pubCert}
      chown root:root ${pubCert}
      chmod 0644 ${pubCert}
    '';
  };

  systemd.tmpfiles.rules =
    [
      "L+ /var/lib/secrets/ssh_host_ecdsa_key - - - - ${config.sops.secrets."ssh_host_ecdsa_key".path}"
      # FIXME
      # "C ${pubCert} - - - - ${config.sops.secrets."ssh_host_ecdsa_key-cert-pub".path}"
      # "z ${pubCert} 0644 root root - -"
    ]
    ++ (
      with config.users.users.admin; [
        "d ${home} 700 ${name} ${group} - -"
        "z ${home} 700 ${name} ${group} - -"
      ]
    );
}
