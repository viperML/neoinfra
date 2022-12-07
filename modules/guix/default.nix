{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.guix = args @ {pkgs, ...}: {
    imports = [
      inputs.nix-overlay-guix.nixosModules.guix
    ];

    services.guix = {
      enable = true;
      package = self.packages.${args.pkgs.system}.guix;
    };

    fileSystems."/gnu" = {
      device = "/var/guix-gnu";
      options = ["bind"];
      depends = ["/var"];
    };
  };
}
