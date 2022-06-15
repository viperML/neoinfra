{lib, ...}: {
  documentation.enable = false;
  environment.defaultPackages = [];
  services.getty.autologinUser = "root";
  systemd.services."getty@".serviceConfig = {
    TTYVTDisallocate = false;
  };
  boot.initrd.systemd.enable = true;
}
