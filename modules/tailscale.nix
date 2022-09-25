{
  config,
  rootPath,
  pkgs,
  ...
}:
{
  services.tailscale.enable = true;
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [22];
  networking.firewall.checkReversePath = "loose";

  sops.secrets."tailscale_key" = {
    sopsFile = rootPath + "/secrets/tailscale-server.yaml";
  };

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
