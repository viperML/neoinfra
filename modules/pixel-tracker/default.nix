{
  config,
  pkgs,
  inputs,
  rootPath,
  ...
}: let
  local_port = "9001";
in {
  sops.secrets."pixel-tracker" = {
    sopsFile = rootPath + "/secrets/shiva-pt.yaml";
  };

  systemd.services."pixel-tracker" = {
    script = "exec ${inputs.pixel-tracker.packages.${pkgs.system}.default}/bin/pixel-tracker --listen 127.0.0.1:${local_port} --url https://infra.ayats.org/pt/";
    serviceConfig = {
      EnvironmentFile = config.sops.secrets."pixel-tracker".path;
      DynamicUser = true;
      PrivateTmp = true;
      AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
      NoNewPrivileges = true;
      RestrictNamespaces = "uts ipc pid user cgroup";
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      PrivateDevices = true;
      RestrictSUIDSGID = true;
    };
    environment.RUST_LOG = "info,tower_http=trace,pixel_tracker=trace";
    wantedBy = ["multi-user.target"];
  };


  services.nginx.virtualHosts."pt.ayats.org" = {
    useACMEHost = "wildcard.ayats.org";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${local_port}";
    };
  };
}
