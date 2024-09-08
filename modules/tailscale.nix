{
  config,
  lib,
  ...
}: let
  keyNames = [
    "ssh_host_rsa_key"
    "ssh_host_ed25519_key"
    "ssh_host_ecdsa_key"
  ];
  prefix = "/var/lib/tailscale/ssh";
in {
  services.tailscale = {
    enable = true;
    extraUpFlags = ["--ssh"];
  };
  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [
      22
    ];
    allowedUDPPorts = [
      25565 # minecraft query port
    ];
  };
  networking.firewall.checkReversePath = "loose";

  services.openssh = {
    openFirewall = false;
    extraConfig = lib.mkOrder 0 ''
      ${lib.concatMapStringsSep "\n" (k: "HostKey ${prefix}/${k}") keyNames}
    '';
    hostKeys = lib.mkForce [];
  };

  systemd.paths = lib.mapAttrs' (name: value: lib.nameValuePair "tailscale-${name}" value) (lib.genAttrs keyNames (key: {
    wantedBy = ["paths.target"];
    pathConfig = {
      Unit = "sshd-restart-tailscale.service";
      PathModified = "${prefix}/${key}";
    };
  }));

  systemd.services."sshd-restart-tailscale" = {
    serviceConfig.Type = "oneshot";
    script = ''
      systemctl try-restart sshd.service
    '';
  };

  systemd.services."sshd" = {
    after = ["tailscaled.service"];
  };
}
