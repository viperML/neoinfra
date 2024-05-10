{ config, ... }:
{
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

  sops.secrets = {
    "letsencrypt_env" = {
      sopsFile = ../../secrets/letsencrypt.yaml;
    };
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "ayatsfer@gmail.com";
    # defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    certs."wildcard.ayats.org" = {
      domain = "*.ayats.org";
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets."letsencrypt_env".path;
    };
    certs."ayats.org" = {
      domain = "ayats.org";
      extraDomainNames = ["*.ayats.org"];
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.secrets."letsencrypt_env".path;
    };
  };

  users.users."nginx".extraGroups = ["acme"];
}
