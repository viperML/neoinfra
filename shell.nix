{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [
    packer
    hcloud
    shellcheck
    age
    sops
  ];
}
