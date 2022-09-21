{...}: {
  documentation.enable = false;
  environment.defaultPackages = [];
  system.stateVersion = "22.05";
  services.openssh.enable = false;
  networking.hostName = "skadi";
  services.getty.autologinUser = "root";
}
