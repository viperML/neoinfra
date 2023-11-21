{config, ...}: {
  virtualisation.docker = {
    enable = true;

    autoPrune = {
      enable = true;
      flags = [
        "--all"
      ];
    };
  };

  virtualisation.oci-containers.backend = "docker";

  users.groups.docker.members = config.users.groups.wheel.members;
}
