args: {
  bind_addr = ''{{ GetInterfaceIP "tailscale0" }}'';

  server = {
    enabled = true;
    bootstrap_expect = 1;
    # default_scheduler_config = {
    #   scheduler_algorithm = "spread";
    #   memory_oversubscription_enabled = true;
    #   preemption_config = {
    #     batch_scheduler_enabled = true;
    #     system_scheduler_enabled = true;
    #     service_scheduler_enabled = true;
    #   };
    # };
  };

  client = {
    enabled = true;
    # host_volume."nix" = {
    #   path = "/nix";
    #   read_only = false;
    # };
    cni_path = "${args.pkgs.cni-plugins}/bin";
  };

  plugin = {
    "nomad-driver-containerd".config = {
      enabled = true;
      stats_interval = "5s";
      containerd_runtime = "io.containerd.runc.v2";
      nix_executable = args.config.nix.package.outPath;
    };
  };
}
