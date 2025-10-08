{
  pkgs ? import <nixpkgs> { },
}:
let
  sources = import ../npins;
  inherit (pkgs) lib;
in
lib.fix (self: {
  terraformWithPlugins = pkgs.terraform.withPlugins (t: [
    t.external
    t.cloudflare
    t.oci
    t.null
    t.local
    t.cloudinit
    t.aws
  ]);

  terranix =
    import "${sources.terranix}/core" {
      inherit pkgs;
      strip_nulls = true;
      extraArgs = {
        nixosConfigurations = {
          shiva = import ../hosts/shiva;
        };
      };
      terranix_config.imports = [
        ./main.nix
      ];
    }
    |> builtins.getAttr "config"
    |> (pkgs.formats.json { }).generate "config.tf.json";

  terraform-wrapped = (
    pkgs.writeShellScriptBin "terraform" ''
      if [[ ! -f .terraform.lock.hcl ]]; then
        echo "Run this in terraform dir"
        exit 127
      fi

      set -ex
      nix build -L -f "$PWD" terranix -o config.tf.json

      exec ${self.terraformWithPlugins}/bin/terraform "$@"
    ''
  );
})
