{
  rootPath,
  pkgs,
  config,
  ...
}: {
  system.stateVersion = "22.05";

  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    createHome = true;
    password = "1234";
  };
  services.getty.autologinUser = "admin";
  security.sudo.wheelNeedsPassword = false;
  nix.trustedUsers = ["@wheel"];

  sops.age = {
    keyFile = "/var/lib/secrets/golden.age";
    sshKeyPaths = [];
  };

  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = rootPath + "/secrets/golden.yaml";

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
