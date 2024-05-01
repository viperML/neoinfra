{ config, inputs, ... }:
{
  imports = [ inputs.snm.nixosModule ];

  mailserver = {
    enable = true;
    fqdn = "mail.ayats.org";
    domains = [ "ayats.org" ];

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "fer@ayats.org" = {
        hashedPasswordFile = config.sops.secrets."snm_password_fer".path;
      };
    };

    certificateScheme = "acme-nginx";
  };

  services.roundcube = {
    enable = true;
    hostName = "webmail.ayats.org";
    extraConfig = ''
      # starttls needed for authentication, so the fqdn required to match
      # the certificate
      $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };

  services.nginx.virtualHosts."webmail.ayats.org" = {
    enableACME = false;
    useACMEHost = "wildcard.ayats.org";
    forceSSL = true;
  };

  sops.secrets."snm_password_fer" = {
    sopsFile = ../../secrets/mail.yaml;
    owner = config.mailserver.vmailUserName;
    group = config.mailserver.vmailGroupName;
  };

  assertions = [
    {
      assertion = config.services.nginx.enable;
      message = "mail needs nginx";
    }
  ];
}
