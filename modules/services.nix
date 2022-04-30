{
  pkgs,
  config,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  sops.secrets."cloudflare_credentials" = {};

  security.acme = {
    acceptTerms = true;
    email = "ayatsfer@gmail.com";
    # https://nixos.org/manual/nixos/stable/index.html#module-security-acme-config-dns
    certs."ayats.org" = {
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      domain = "*.ayats.org";
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets."cloudflare_credentials".path;
    };
  };
}
