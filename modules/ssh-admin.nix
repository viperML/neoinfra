{
  lib,
  self,
  config,
  pkgs,
  ...
}: let
  ca_path = "ssh/ca.d";
  pubCert = "/var/lib/secrets/ssh_host_ecdsa_key-cert.pub";
  inherit (config.networking) hostName;
in {
  users.users.admin = {
    name = "admin";
    isNormalUser = true;
    extraGroups = ["wheel"];
  };

  security.sudo.wheelNeedsPassword = false;
  nix.trustedUsers = ["@wheel"];

  services.getty.autologinUser = "admin";

  sops.secrets = let
    sopsFile = "${self}/secrets/${hostName}-ssh.yaml";
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
    openFirewall = false;
    passwordAuthentication = false;
    extraConfig = ''
      HostKey ${config.sops.secrets."ssh_host_ecdsa_key".path}
      HostCertificate ${pubCert}
      # HostCertificate ${config.sops.secrets."ssh_host_ecdsa_key-cert-pub".path}
      TrustedUserCAKeys /etc/${ca_path}/ssh_user_keys.pub
      AuthorizedPrincipalsFile /etc/${ca_path}/%u_principals
    '';
    hostKeys = [];
  };

  environment.etc = {
    "${ca_path}/ssh_user_keys.pub" = {
      mode = "0444";
      text = lib.concatStringsSep "\n" [
        (lib.fileContents "${self}/secrets/${hostName}-ssh_user_key.pub")
      ];
    };
    "${ca_path}/admin_principals" = {
      mode = "0444";
      text = lib.concatStringsSep "\n" [
        "admin"
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
    environment."STEPPATH" = "/dev/null";
    script = ''
      set -xu

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
      chmod 644 ${pubCert}
    '';
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/secrets/ssh_host_ecdsa_key - - - - ${config.sops.secrets."ssh_host_ecdsa_key".path}"
    "C ${pubCert} - - - - ${config.sops.secrets."ssh_host_ecdsa_key-cert-pub".path}"
    "z ${pubCert} 0644 root root - -"
  ];
}
