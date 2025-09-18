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

    (pkgs.writeShellScriptBin "ocilogin" ''
      exec oci session authenticate --region eu-marseille-1 --profile-name DEFAULT
    '')
  ];
}
