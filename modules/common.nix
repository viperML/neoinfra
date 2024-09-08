{config, lib, pkgs, ...}: {

  system.build.firewallReport = pkgs.writeText "firewall-report" (lib.concatStringsSep "\n" (lib.flatten [
    (map (p: "TCP ${toString p}") config.networking.firewall.allowedTCPPorts)
    (map ({
      from,
      to,
    }: "TCP ${toString from}:${toString to}")
    config.networking.firewall.allowedTCPPortRanges)
    (map (p: "UDP ${toString p}") config.networking.firewall.allowedUDPPorts)
    (map ({
      from,
      to,
    }: "UDP ${toString from}:${toString to}")
    config.networking.firewall.allowedTCPPortRanges)
  ]));
}
