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
        nixosConfigurations =
          builtins.readDir ../hosts
          |> lib.filterAttrs (n: _: n != "default.nix")
          |> builtins.mapAttrs (n: v: import ../hosts/${n});
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

  deploy = pkgs.writeShellApplication {
    name = "neoinfra-bootstrap";

    runtimeInputs = [
      self.terraform-wrapped
      pkgs.jq
      (pkgs.python3.withPackages (pp: [
        pp.ansible-core
      ]))
    ];

    text = ''
      if [[ ! -f .terraform.lock.hcl ]]; then
        echo "Run this in terraform dir"
        exit 127
      fi

      if [[ "$#" -ne 1 ]]; then
        echo "Usage: $0 [hostname]"
        exit 1
      fi
      hostname="$1"

      terraform_output="$(terraform output -json)"

      # Generate Ansible inventory file
      echo "all:" > inventory.yml
      echo "  hosts:" >> inventory.yml

      # Extract all *_ip outputs and create inventory entries
      echo "$terraform_output" | jq -r 'to_entries[] | select(.key | endswith("_ip")) | .key' | while read -r key; do
        hostname="''${key%_ip}"
        ip=$(echo "$terraform_output" | jq -r ".[\"$key\"].value")
        {
          echo "    $hostname:"
          echo "      ansible_host: $ip"
          echo "      ansible_user: opc"
          echo "      ansible_ssh_private_key_file: $PWD/id"
        } >> inventory.yml
      done
      cat inventory.yml

      # Check if hostname exists using jq
      if ! echo "$terraform_output" | jq -e "has(\"''${hostname}_ip\")" > /dev/null; then
        echo "Error: Hostname '$hostname' does not exist in Terraform outputs."
        exit 1
      fi

      command="ansible-playbook -i inventory.yml playbook.yml --limit $hostname --ssh-extra-args='-o StrictHostKeyChecking=no'"
      echo "$command"
      eval "$command"
    '';
  };
})
