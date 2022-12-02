# https://github.com/hashicorp/vault/issues/17527
# https://github.com/NixOS/nixpkgs/blob/nixos-22.11/pkgs/tools/security/vault/vault-bin.nix
{
  vault-bin,
  fetchzip,
  system,
}: let
  suffix =
    {
      x86_64-linux = "linux_amd64";
      aarch64-linux = "linux_arm64";
      i686-linux = "linux_386";
      x86_64-darwin = "darwin_amd64";
      aarch64-darwin = "darwin_arm64";
    }
    .${system};
in
  vault-bin.overrideAttrs (old: rec {
    version = "1.11.6";
    src = fetchzip {
      url = "https://releases.hashicorp.com/vault/${version}/vault_${version}_${suffix}.zip";
      hash = "sha256-ppqlPvMIc3luhCs4V83K0J9IuUw9f9zLF5iYvo6amVE=";
    };
  })
