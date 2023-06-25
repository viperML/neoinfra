{
  pkgs,
  inputs,
  ...
}: {
  services.envfs.enable = true;

  programs.nix-ld = {
    enable = true;
    package = inputs.nix-ld.packages.${pkgs.system}.default;
    libraries = with pkgs; [
      stdenv.cc.cc
      openssl
      curl
      glib
      util-linux
      icu
      libunwind
      libuuid
      zlib
      libsecret
    ];
  };
}
