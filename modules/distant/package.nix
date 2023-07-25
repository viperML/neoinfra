{
  rustPlatform,
  callPackages,
  pkg-config,
  openssl,
}: let
  nv = callPackages ./generated.nix {};
in
  rustPlatform.buildRustPackage {
    inherit (nv.distant) pname version src;
    cargoLock.lockFile = ./${nv.distant.pname}-${nv.distant.version}/Cargo.lock;
    nativeBuildInputs = [
      pkg-config
    ];
    buildInputs = [
      openssl
    ];
  }
