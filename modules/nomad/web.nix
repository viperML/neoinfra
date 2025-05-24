{ pkgs, config, ... }:
let
  workdir = "/var/lib/nginx-nomad-auth";
  user = config.systemd.services."nginx".serviceConfig.User;
  group = config.systemd.services."nginx".serviceConfig.Group;
in
{
  services.nginx.virtualHosts."nomad.ayats.org" = {
    forceSSL = true;
    useACMEHost = "wildcard.ayats.org";
    enableACME = false;
    basicAuthFile = "${workdir}/nomad_http_auth";
    locations."/".proxyPass = "http://localhost:4646";
  };

  systemd.services."generate-nomad-password" = {
    serviceConfig = {
      WorkingDirectory = workdir;
    };
    path = with pkgs; [
      pwgen
      apacheHttpd
    ];
    script = ''
      pwgen 64 1 > nomad_http_password
      htpasswd -B -i -c nomad_http_auth gha < nomad_http_password
    '';
    wantedBy = [ "nginx.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${workdir} 0755 ${user} ${group} - -"
  ];
}
