{
  config,
  pkgs,
  ...
}: {
  services.outline = {
    enable = true;
    publicUrl = "https://outline.ayats.org";
    databaseUrl = "local";
    redisUrl = "local";
  };
}
