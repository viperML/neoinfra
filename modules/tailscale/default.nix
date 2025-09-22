{
  config,
  lib,
  pkgs,
  ...
}:
let
  keyNames = [
    "ssh_host_rsa_key"
    "ssh_host_ed25519_key"
    "ssh_host_ecdsa_key"
  ];
  prefix = "/var/lib/tailscale/ssh";
  authKeyFile = "/var/lib/tailscale/auth-key";
in
{
  sops.secrets = {
    tailscale_oauth = {
      sopsFile = ../../secrets/tailscale.yaml;
    };
  };

  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
    inherit authKeyFile;
    useRoutingFeatures = "both";
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [
      22
    ];

    allowedTCPPortRanges = [
      {
        from = 8000;
        to = 8999;
      }
    ];
  };

  services.openssh = {
    openFirewall = false;
    extraConfig = lib.mkOrder 0 ''
      ${lib.concatMapStringsSep "\n" (k: "HostKey ${prefix}/${k}") keyNames}
    '';
    hostKeys = lib.mkForce [ ];
  };

  systemd.paths = lib.mapAttrs' (name: value: lib.nameValuePair "tailscale-${name}" value) (
    lib.genAttrs keyNames (key: {
      wantedBy = [ "paths.target" ];
      pathConfig = {
        Unit = "sshd-restart-tailscale.service";
        PathModified = "${prefix}/${key}";
      };
    })
  );

  systemd.services."sshd-restart-tailscale" = {
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = "${pkgs.systemd}/bin/systemctl try-restart sshd.service";
  };

  systemd.services."sshd" = {
    after = [ "tailscaled.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/tailscale 0700 root root"
  ];

  systemd.services."tailscale-regen-authkey" = {
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets.tailscale_oauth.path;
    };
    path = [
      pkgs.nodejs
    ];
    script = ''
      node ${./genkey.mjs} > ${authKeyFile}
      echo "TS_AUTHKEY=$(<${authKeyFile})" > /var/lib/tailscale/auth-key.env
    '';
    wantedBy = [
      "multi-user.target"
    ];
    before = [
      "multi-user.target"
    ];
    requiredBy = [
      "tailscaled.service"
    ];
  };

  systemd.timers."tailscale-regen-authkey" = {
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = [
      "timers.target"
    ];
  };
}
