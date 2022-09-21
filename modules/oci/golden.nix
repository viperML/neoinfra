{...}: {
  system.stateVersion = "22.05";

  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    createHome = true;
    password = "admin";
  };
  services.getty.autologinUser = "admin";
  security.sudo.wheelNeedsPassword = false;
  nix.trustedUsers = ["@wheel"];
}
