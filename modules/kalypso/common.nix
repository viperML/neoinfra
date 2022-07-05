{
  config,
  pkgs,
  self,
  ...
}: {
  networking = rec {
    hostName = "kalypso";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" hostName);
  };

  sops.age = {
    keyFile = "/var/lib/secrets/kalypso.age";
    sshKeyPaths = [];
  };
  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = "${self}/secrets/kalypso.yaml";
  sops.secrets."ssh_host_ecdsa_key" = {
    sopsFile = "${self}/secrets/kalypso-ssh.yaml";
    mode = "600";
  };
  sops.secrets."ssh_host_ecdsa_key-cert-pub" = {
    sopsFile = "${self}/secrets/kalypso-ssh.yaml";
    mode = "644";
  };

  services.openssh = {
    enable = true;
    # openFirewall = false;
    passwordAuthentication = false;
    extraConfig = ''
      HostKey ${config.sops.secrets."ssh_host_ecdsa_key".path}
      HostCertificate ${config.sops.secrets."ssh_host_ecdsa_key-cert-pub".path}
    '';
    hostKeys = [];
  };

  # services.tailscale.enable = true;
  # networking.firewall.interfaces."tailscale0".allowedTCPPorts = [22];
  # networking.firewall.checkReversePath = "loose";
}
