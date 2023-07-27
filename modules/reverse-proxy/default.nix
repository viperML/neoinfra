{
  config,
  rootPath,
  ...
}: {
  sops.secrets."lets-encrypt-credentials" = {
    sopsFile = rootPath + "/secrets/lets-encrypt.yaml";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "ayatsfer@gmail.com";
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    certs."wildcard.ayats.org" = {
      domain = "*.ayats.org";
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets."lets-encrypt-credentials".path;
    };
  };

  users.users."nginx".extraGroups = ["acme"];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
