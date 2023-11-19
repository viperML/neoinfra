{pkgs, inputs, ...}: {
  imports = [
    inputs.sops-nix.nixosModules.default
    ../oci-lustrate-oracle9

    ../login-classic.nix
    ../tailscale.nix

    inputs.nix-common.nixosModules.default
  ];

  disabledModules = [
    inputs.nix-common.nixosModules.fhs
  ];

  documentation.enable = true;

  system.stateVersion = "23.11";

  environment.systemPackages = [
    pkgs.git
  ];

  sops.age = {
    keyFile = "/var/lib/secrets/main.age";
    sshKeyPaths = [];
  };

  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = ../../secrets/vishnu.yaml;
}
