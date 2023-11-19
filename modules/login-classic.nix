{
  users.mutableUsers = false;
  users.allowNoPasswordLogin = true; # module system doesn't know about certs

  users.users.admin = {
    name = "admin";
    isNormalUser = true;
    extraGroups = ["wheel"];
    createHome = true;
  };

  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = ["@wheel"];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };
}
