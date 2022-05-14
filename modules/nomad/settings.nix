{
  bind_addr = "0.0.0.0";

  server = {
    enabled = true;
    bootstrap_expect = 1;
  };

  client = {
    enabled = true;
    host_volume."nix" = {
      path = "/nix";
      read_only = false;
    };
  };

  plugin."containerd-driver".config = {
    enabled = true;
    containerd_runtime = "io.containerd.runc.v2";
    stats_interval = "5s";
  };
}
