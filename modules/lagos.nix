{
  lib,
  pkgs,
  ...
}: {
  # TODO
  services.getty.autologinUser = "root";

  # services.openssh.enable = lib.mkForce false;
  documentation.enable = false;
  environment.defaultPackages = [];
  # environment.systemPackages = with pkgs;
  #   lib.mkForce [
  #     stdenv.cc.libc
  #     # bashInteractive
  #     # su
  #     # coreutils-full
  #   ];
}
