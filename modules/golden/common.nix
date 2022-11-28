{
  rootPath,
  pkgs,
  config,
  ...
}: {
  system.stateVersion = "22.05";
  networking.hostName = "golden";

  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    createHome = true;
    openssh.authorizedKeys.keyFiles = [./id_golden.pub];
  };
  services.getty.autologinUser = "admin";
  security.sudo.wheelNeedsPassword = false;
  nix.settings.trusted-users = ["@wheel"];

  sops.age = {
    keyFile = "/var/lib/secrets/golden.age";
    sshKeyPaths = [];
  };

  sops.gnupg.sshKeyPaths = [];
  sops.defaultSopsFile = rootPath + "/secrets/golden.yaml";

  services.tailscale.enable = true;
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [22];
  networking.firewall.checkReversePath = "loose";

  services.openssh = {
    enable = true;
    openFirewall = false;
    passwordAuthentication = true;
  };

  sops.secrets."tailscale_key" = {};

  systemd.services.tailscaled = {
    serviceConfig = {
      ExecStart = [
        ""
        "${pkgs.tailscale}/bin/tailscaled --state=mem: --socket=/run/tailscale/tailscaled.sock --port $PORT $FLAGS"
      ];
    };
  };

  # https://tailscale.com/blog/nixos-minecraft/
  systemd.services.tailscaled-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${pkgs.tailscale}/bin/tailscale up -authkey file:${config.sops.secrets."tailscale_key".path}
    '';
  };
}
