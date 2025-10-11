{
  documentation.enable = true;

  system.stateVersion = "25.05";

  # environment.systemPackages = [
  #   pkgs.git
  #   pkgs.pkgsBuildBuild.ghostty.terminfo
  #   pkgs.net-tools
  # ];

  sops = {
    age = {
      keyFile = "/var/lib/secrets/main.age";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
    defaultSopsFile = ../../secrets/ant1.yaml;
  };

  networking.hostName = "ant1";
}
