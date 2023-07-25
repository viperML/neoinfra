{
  callPackages,
  stdenv,
  system,
  autoPatchelfHook,
  zlib,
}: let
  nv = callPackages ./generated.nix {};
  myNv = nv."distant-${system}";
in
  stdenv.mkDerivation {
    inherit (myNv) pname version src;
    nativeBuildInputs = [autoPatchelfHook];
    dontUnpack = true;

    buildInputs = [
      zlib
      stdenv.cc.cc
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp -avL $src $out/bin/distant
      chmod +x $out/bin/distant
    '';
  }
