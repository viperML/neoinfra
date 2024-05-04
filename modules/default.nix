{
  inputs,
  withSystem,
  ...
}: let
  mkSystem = system: hostname:
    withSystem system ({pkgs, ...}:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.nixpkgs.nixosModules.readOnlyPkgs
          {nixpkgs.pkgs = pkgs;}
          ./host-${hostname}

          inputs.noshell.nixosModules.default
          {programs.noshell.enable = true;}
        ];
      });
in {
  flake.nixosConfigurations = {
    "vishnu" = mkSystem "x86_64-linux" "vishnu";
    "shiva" = mkSystem "aarch64-linux" "shiva";
  };
}
