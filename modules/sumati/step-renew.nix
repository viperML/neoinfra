{
  pkgs,
  self,
  config,
  ...
}: let
  pubCert = "/var/lib/secrets/ssh_host_ecdsa_key-cert.pub";
in {
  sops.secrets."root_ca_crt" = {
    sopsFile = "${self}/secrets/sumati-ssh.yaml";
    mode = "600";
  };

  systemd.services."step-renew" = {
    description = "Renew SSH certificates with step-ca and SSHPOP";
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

  systemd.tmpfiles.rules = [
    "C ${pubCert} - - - - ${config.sops.secrets."ssh_host_ecdsa_key-cert-pub".path}"
    "z ${pubCert} 0600 root root - -"
  ];
}
