{pkgs, ...}: {
  networking.hostName = "shiva";
  system.stateVersion = "23.05";

  environment.systemPackages = [
    pkgs.git
  ];

  documentation = {
    enable = true;
    man.enable = true;
  };

  sops.age = {
    keyFile = "/var/lib/secrets/main.age";
    sshKeyPaths = [];
  };

  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = ../../secrets/shiva.yaml;
}
