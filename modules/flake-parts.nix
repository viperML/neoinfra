{lib, ...}:
with lib; {
  options.flake.deploy = {
    nodes = mkOption {
      default = {};
      type = types.attrs;
    };
  };
}
