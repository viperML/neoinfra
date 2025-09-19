{ pkgs, ... }:
{
  users.mutableUsers = false;
  users.allowNoPasswordLogin = true; # module system doesn't know about certs

  users.users.admin = {
    name = "admin";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    createHome = true;
    shell = pkgs.bashInteractive;
  };

  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = [ "@wheel" ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  programs.ssh = {
    startAgent = true;
    agentTimeout = "4h";
  };
}
