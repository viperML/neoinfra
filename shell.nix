with import ./packages.nix { };
let
  tf = import ./terraform { inherit pkgs; };
in
mkShellNoCC {
  packages = [
    shellcheck
    age
    sops
    hclfmt
    oci-cli
    nodejs
    consul
    nomad
    nodejs

    tf.terraform-wrapped
    tf.terraformWithPlugins
    tf.deploy

    (pkgs.writeShellScriptBin "neoinfra-ocilogin" ''
      exec oci session authenticate --region eu-marseille-1 --profile-name DEFAULT
    '')

    (python3.withPackages (pp: [
      pp.ansible-core
    ]))

    (pkgs.writeShellScriptBin "neoinfra-rebuild" ''
      # Expect 2 arguments: rebuild <switch|boot|...> <file>
      if [ "$#" -ne 2 ]; then
        echo "Usage: rebuild <switch|boot|...> <file>"
        exit 1
      fi

      hostname="$(basename "$2")"

      extra_args=()
      if [[ "$hostname" = "shiva" ]]; then
        extra_args+=(--build-host "admin@$hostname")
      fi

      set -x
      exec nixos-rebuild \
        "$1" \
        --file "$2" \
        --no-reexec \
        --sudo \
        --target-host "admin@$hostname" \
        "''${extra_args[@]}" \
    '')
  ];
}
