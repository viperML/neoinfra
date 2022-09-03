{
  config,
  pkgs,
  self,
  ...
}: {
  system.stateVersion = "22.05";

  networking = rec {
    hostName = "kalypso";
    hostId = builtins.substring 0 8 (builtins.hashString "md5" hostName);
  };

  sops.age = {
    keyFile = "/var/lib/secrets/kalypso.age";
    sshKeyPaths = [];
  };
  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = "${self}/secrets/kalypso.yaml";


  services.tailscale.enable = true;
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [22];
  networking.firewall.checkReversePath = "loose";

  sops.secrets."tailscale_key" = {};

  # https://tailscale.com/blog/nixos-minecraft/
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey file:${config.sops.secrets."tailscale_key".path}
    '';
  };
}
