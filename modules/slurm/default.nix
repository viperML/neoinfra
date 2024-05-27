{
  pkgs,
  config,
  ...
}: {
  services.slurm = {
    controlMachine = config.networking.hostName;
    nodeName = ["shiva CPUs=1 State=UNKNOWN"];
    server = {
      enable = true;
    };
    client = {
      enable = true;
    };
  };

  services.munge.password = config.sops.secrets."munge_key".path;

  sops.secrets."munge_key" = {
    sopsFile = ../../secrets/slurm.yaml;
    owner = "munge";
    group = "munge";
    restartUnits = ["munged.service"];
  };
}
