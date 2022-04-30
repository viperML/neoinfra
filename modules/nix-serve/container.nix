{...}: {
  networking.firewall.allowedTCPPorts = [80];

  services.nginx = {
    enable = true;
    virtualHosts."localhost".locations."~ /(.+)-(.+)" = {
      root = "/nix/store";
      extraConfig = ''
        autoindex on;
      '';
    };
  };
}
