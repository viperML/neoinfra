{ lib, ... }:
let
  inherit (lib) tfRef;
in
{
  resource.cloudflare_worker.posthog = {
    account_id = tfRef "var.cloudflare_account_id";
    name = "posthog";
    observability = {
      enabled = true;
    };
  };

  resource.cloudflare_worker_version.posthog = {
    account_id = tfRef "var.cloudflare_account_id";
    worker_id = tfRef "cloudflare_worker.posthog.id";
    compatibility_date = "2025-10-12";
    main_module = "posthog-proxy.js";
    modules = [
      {
        name = "posthog-proxy.js";
        content_type = "application/javascript+module";
        # Replacement (version creation) is triggered whenever this file changes
        content_file = "posthog-proxy.js";
      }
    ];
  };

  resource.cloudflare_workers_deployment.posthog = {
    account_id = tfRef "var.cloudflare_account_id";
    script_name = tfRef "cloudflare_worker.posthog.name";
    strategy = "percentage";
    versions = [
      {
        percentage = 100;
        version_id = tfRef "cloudflare_worker_version.posthog.id";
      }
    ];
  };

  resource.cloudflare_workers_route.posthog = {
    zone_id = tfRef "var.cloudflare_zone_id";
    pattern = "p.ayats.org/*";
    script = tfRef "cloudflare_worker.posthog.name";
  };

  resource.cloudflare_workers_custom_domain.posthog = {
    account_id = tfRef "var.cloudflare_account_id";
    zone_id = tfRef "var.cloudflare_zone_id";
    hostname = "p.ayats.org";
    service = "posthog";
    environment = "production";
  };
}
