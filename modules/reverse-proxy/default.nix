{
  config,
  pkgs,
  inputs,
  rootPath,
  ...
}: let
  local_port = "9001";
in {
  # security.acme = {
  #   acceptTerms = true;
  #   defaults.email = "ayatsfer@gmail.com";
  #   defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  # };

  # services.nginx = {
  #   enable = true;
  #   recommendedTlsSettings = true;
  #   recommendedOptimisation = true;
  #   recommendedBrotliSettings = true;
  #   recommendedGzipSettings = true;
  #   recommendedProxySettings = true;

  #   virtualHosts."infra.ayats.org" = {
  #     enableACME = true;
  #     forceSSL = true;
  #     locations."/" = {
  #       # root = "/var/www";
  #       proxyPass = "http://localhost:${local_port}";
  #     };
  #   };
  # };
  services.traefik = {
    enable = true;
    staticConfigFile = ./config.toml;
    dynamicConfigFile = ./dynamic.toml;
  };

  sops.secrets."pixel-tracker" = {
    sopsFile = rootPath + "/secrets/shiva-pt.yaml";
  };

  systemd.services."pixel-tracker" = {
    script = "exec ${inputs.pixel-tracker.packages.${pkgs.system}.default}/bin/pixel-tracker --listen 0.0.0.0:${local_port} --url https://infra.ayats.org/pt/";
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
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
