{
  pkgs,
  lib,
  ...
}: let
  env = {
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [
      stdenv.cc.cc
      openssl
      curl
      glib
      util-linux
      glibc
      icu
      libunwind
      libuuid
      zlib
      libsecret
    ]);

    NIX_LD = "$(${pkgs.coreutils}/bin/cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)";
  };
in {
  programs.nix-ld.enable = true;

  environment = {
    sessionVariables = env;
    variables = env;
  };
}

