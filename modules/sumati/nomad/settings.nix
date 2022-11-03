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
    cni_path = "${args.pkgs.cni-plugins}/bin";
  };

  vault = {
    enabled = true;
    address = "http://kalypso:8200";
    create_from_role = "nomad-cluster";
  };
}
