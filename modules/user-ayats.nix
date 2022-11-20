# depends on ssh-admin.nix
{
  lib,
  config,
  ...
}: let
  ca_path = "ssh/ca.d";
in {
  users.users.ayats = {
    name = "ayats";
    isNormalUser = true;
    extraGroups = [];
  };

  environment.etc.
    "${ca_path}/ayats_principals" = {
    mode = "0444";
    text = lib.concatStringsSep "\n" [
      "ayats"
      "admin"
      "ayatsfer@gmail.com"
    ];
  };

  programs.ssh = {
    startAgent = true;
    agentTimeout = "4h";
  };

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPortRanges = [
      {
        from = 8000;
        to = 8999;
      }
    ];
  };

  systemd.tmpfiles.rules = with config.users.users.ayats; [
    "d ${home} 700 ${name} ${group} - -"
    "z ${home} 700 ${name} ${group} - -"
  ];
}
